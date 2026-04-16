-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-----------------------------------------------------
-- FXManager Subclass
-----------------------------------------------------
-- Handles sound and visual effects.
---@class FXManager
---@field private m_sfx_timers table<handle, Timer>
---@field private m_effects table<handle, array<handle>>
---@field protected m_owner_ref YimActions
local FXManager <const> = { m_effects = {}, m_sfx_timers = {} }
FXManager.__index = FXManager

---@param yimactions YimActions
---@return FXManager
function FXManager.new(yimactions)
	return setmetatable({ m_owner_ref = yimactions }, FXManager)
end

---@return table<handle, array<handle>>
function FXManager:GetFX()
	return self.m_effects
end

---@return array<handle>?
function FXManager:GetFXForPed(ped)
	return self.m_effects[ped]
end

---@param parent handle
---@param ptfxData AnimPTFX|AnimSFX
function FXManager:StartPTFX(parent, ptfxData)
	if (not Game.IsScriptHandle(parent)
			or not ENTITY.DOES_ENTITY_EXIST(parent)
			or not ptfxData
			or not ptfxData.dict
		) then
		return
	end

	local loaded, e = pcall(TaskWait, Game.RequestNamedPtfxAsset, ptfxData.dict)
	if (not loaded) then
		log.fwarning("[YimActions]: Failed to load partice effect: %s", e)
		return
	end

	if (ptfxData.delay) then
		sleep(ptfxData.delay)
	end

	GRAPHICS.USE_PARTICLE_FX_ASSET(ptfxData.dict)

	local handle
	if (ENTITY.IS_ENTITY_A_PED(parent)) then
		handle = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE(
			ptfxData.name,
			parent,
			ptfxData.pos.x,
			ptfxData.pos.y,
			ptfxData.pos.z,
			ptfxData.rot.x,
			ptfxData.rot.y,
			ptfxData.rot.z,
			ptfxData.bone or 0,
			ptfxData.scale or 1.0,
			false,
			false,
			false,
			0,
			0,
			0,
			255
		)
	else
		handle = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY(
			ptfxData.name,
			parent,
			ptfxData.pos.x,
			ptfxData.pos.y,
			ptfxData.pos.z,
			ptfxData.rot.x,
			ptfxData.rot.y,
			ptfxData.rot.z,
			ptfxData.scale or 1.0,
			false,
			false,
			false,
			0,
			0,
			0,
			255
		)
	end

	self.m_effects[parent] = self.m_effects[parent] or {}
	table.insert(self.m_effects[parent], handle)
end

---@param ped handle
function FXManager:StopPTFX(ped)
	ped = self.m_owner_ref:GetPed(ped)
	local array = self.m_effects[ped]
	if (not array or #array == 0) then
		return
	end

	for _, fx in ipairs(self.m_effects[ped]) do
		GRAPHICS.STOP_PARTICLE_FX_LOOPED(fx, false)
		GRAPHICS.REMOVE_PARTICLE_FX(fx, false)
	end

	self.m_effects[ped] = nil
end

function FXManager:StartSFX(ped)
	local YAV3    = self.m_owner_ref
	local propMgr = YAV3:GetPropManager()
	ped           = YAV3:GetPed(ped)
	local current = YAV3.CurrentlyPlaying[ped]

	if not (current and current.data and current.data.sfx and current.data.sfx.speechName) then
		return
	end

	local pedProps = propMgr:GetPropsForPed(ped)
	if (not pedProps) then
		return
	end

	self.m_sfx_timers[ped] = self.m_sfx_timers[ped] or Timer.new(0)
	local timer            = self.m_sfx_timers[ped]

	if (not timer:IsDone()) then
		return
	end

	for _, propHandle in ipairs(pedProps) do
		if (ENTITY.IS_ENTITY_A_PED(propHandle) and not AUDIO.IS_AMBIENT_SPEECH_PLAYING(propHandle)) then
			AUDIO.PLAY_PED_AMBIENT_SPEECH_WITH_VOICE_NATIVE(
				propHandle,
				current.data.sfx.speechName,
				current.data.sfx.voiceName,
				current.data.sfx.speechParam or "SPEECH_PARAMS_FORCE",
				false
			)
			break
		end
	end

	timer:Reset(2500)
end

function FXManager:Wipe()
	if (next(self.m_effects) == nil) then return end

	for _, array in pairs(self.m_effects) do
		for _, fxHandle in ipairs(array) do
			GRAPHICS.STOP_PARTICLE_FX_LOOPED(fxHandle, false)
			GRAPHICS.REMOVE_PARTICLE_FX(fxHandle, false)
		end
	end

	self.m_effects = {}
end

return FXManager
