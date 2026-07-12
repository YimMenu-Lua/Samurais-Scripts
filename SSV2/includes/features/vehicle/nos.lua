-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")

---@class NosMgr : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_nos_fx array<handle>|nil
---@field private m_purge_fx_l array<handle>|nil
---@field private m_purge_fx_r array<handle>|nil
---@field private m_engine_danger_ratio float
---@field private m_cached_max_speed float
---@field private m_is_active boolean
local NosMgr = setmetatable({}, FeatureBase)
NosMgr.__index = NosMgr

---@param pv PlayerVehicle
---@return NosMgr
function NosMgr.new(pv)
	local self = FeatureBase.new(pv)
	---@diagnostic disable-next-line
	return setmetatable(self, NosMgr)
end

function NosMgr:Init()
	self.m_is_active           = false
	self.m_engine_danger_ratio = 0.0
	self.m_cached_max_speed    = 0.0
end

function NosMgr:Cleanup()
	if (self.m_nos_fx) then
		Game.StopParticleEffects(self.m_nos_fx, "veh_xs_vehicle_mods")
		self.m_nos_fx = nil
	end

	if (self.m_purge_fx_l) then
		Game.StopParticleEffects(self.m_purge_fx_l)
		self.m_purge_fx_l = nil
	end

	if (self.m_purge_fx_r) then
		Game.StopParticleEffects(self.m_purge_fx_r)
		self.m_purge_fx_r = nil
	end
end

function NosMgr:ShouldRun()
	local veh = self.m_entity
	return (veh
		and veh:IsValid()
		and veh:IsLandVehicle()
		and LocalPlayer:IsDriving()
		and not veh:IsElectric())
end

---@return boolean
function NosMgr:IsActive()
	return self.m_is_active
end

function NosMgr:GetDangerRatio()
	if (not GVars.features.vehicle.nos.can_damage_engine) then
		return 0.0
	end

	return self.m_engine_danger_ratio
end

---@return boolean
function NosMgr:IsNOSButtonPressed()
	return KeyManager:IsKeybindPressed("nos") and self.m_entity:GetEngineHealth() > 300
end

---@return boolean
function NosMgr:IsPurgeButtonPressed()
	return KeyManager:IsKeybindPressed("nos_purge") and self.m_entity:GetEngineHealth() > 300
end

function NosMgr:UpdateFX()
	local PV = self.m_entity
	if (PV:IsElectric()) then
		return
	end

	if (self.m_is_active and PV:IsEngineOn()) then
		if (not self.m_nos_fx) then
			local bones = PV:GetExhaustBones()
			self.m_nos_fx = Game.StartSyncedPtfxLoopedOnEntityBone(
				PV:GetHandle(),
				"veh_xs_vehicle_mods",
				"veh_nitrous",
				bones,
				1.0,
				vec3:zero(),
				vec3:zero()
			)
		end
	elseif (self.m_nos_fx) then
		Game.StopParticleEffects(self.m_nos_fx, "veh_xs_vehicle_mods")
		self.m_nos_fx = nil
	end
end

function NosMgr:UpdatePurgeFX()
	local PV = self.m_entity
	if (PV:IsBoat() or PV:IsElectric()) then
		return
	end

	local handle = PV:GetHandle()
	if (self:IsPurgeButtonPressed() and PV:IsEngineOn()) then
		if (not self.m_purge_fx_l) then
			self.m_purge_fx_l = Game.StartSyncedPtfxLoopedOnEntityBone(
				handle,
				"core",
				"weap_extinguisher",
				"suspension_lf",
				0.35,
				vec3:new(-0.3, -0.33, 0.2),
				vec3:new(0.0, -17.5, -180.0)
			)
		end

		if (not self.m_purge_fx_r) then
			self.m_purge_fx_r = Game.StartSyncedPtfxLoopedOnEntityBone(
				handle,
				"core",
				"weap_extinguisher",
				"suspension_rf",
				0.35,
				vec3:new(0.0, -0.33, 0.2),
				vec3:new(0.0, -17.5, 0.0)
			)
		end
	else
		if (self.m_purge_fx_l) then
			Game.StopParticleEffects(self.m_purge_fx_l)
			self.m_purge_fx_l = nil
		end

		if (self.m_purge_fx_r) then
			Game.StopParticleEffects(self.m_purge_fx_r)
			self.m_purge_fx_r = nil
		end
	end
end

function NosMgr:UpdateEngineDamage()
	local PV = self.m_entity
	if (PV:GetEngineHealth() <= 50 or not self.m_is_active) then
		self.m_engine_danger_ratio = 0.0
		return
	end

	local current_speed = PV:GetSpeed()
	local threshold = self.m_cached_max_speed * 1.7
	self.m_engine_danger_ratio = math.clamp(current_speed / threshold, 0, 1)

	if (current_speed >= threshold) then
		local handle = PV:GetHandle()
		VEHICLE.SET_VEHICLE_ENGINE_HEALTH(handle, 50)
		AUDIO.PLAY_SOUND_FROM_ENTITY(
			-1,
			"DRILL_PIN_BREAK",
			handle,
			"DLC_HEIST_FLEECA_SOUNDSET",
			true,
			0
		)
		return
	end
end

function NosMgr:Update()
	local PV  = self.m_entity
	local cfg = GVars.features.vehicle.nos

	if (not self.m_is_active) then
		self.m_cached_max_speed = PV:GetMaxSpeed()
	end

	if (cfg.enabled) then
		self:UpdateFX()

		if (PV:IsEngineOn()) then
			local handle  = PV:GetHandle()
			local pressed = self:IsNOSButtonPressed()
			local power   = cfg.power

			if (pressed and PAD.IS_CONTROL_PRESSED(0, 71) and PV:GetEngineHealth() > 50) then
				VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(handle, math.clamp(power / 10, 1.0, 5.0))
				VEHICLE.MODIFY_VEHICLE_TOP_SPEED(handle, power)
				if (cfg.sound_effect) then
					AUDIO.SET_VEHICLE_BOOST_ACTIVE(handle, true)
				end

				if (cfg.screen_effect) then
					GRAPHICS.ANIMPOSTFX_PLAY("DragRaceNitrous", 0, false)
				end

				self.m_is_active = true
			end

			if (self.m_is_active and not pressed) then
				VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(handle, 1.0)
				VEHICLE.MODIFY_VEHICLE_TOP_SPEED(handle, -1)
				AUDIO.SET_VEHICLE_BOOST_ACTIVE(handle, false)

				if (cfg.screen_effect) then
					GRAPHICS.ANIMPOSTFX_PLAY("DragRaceNitrousOut", 0, false)
				end

				if (GRAPHICS.ANIMPOSTFX_IS_RUNNING("DragRaceNitrous")) then
					GRAPHICS.ANIMPOSTFX_STOP("DragRaceNitrous")
				end

				if (GRAPHICS.ANIMPOSTFX_IS_RUNNING("DragRaceNitrousOut")) then
					GRAPHICS.ANIMPOSTFX_STOP("DragRaceNitrousOut")
				end

				self.m_is_active = false
			end
		end

		if (cfg.can_damage_engine) then
			self:UpdateEngineDamage()
		end
	end

	if (cfg.purge) then
		self:UpdatePurgeFX()
	end
end

return NosMgr
