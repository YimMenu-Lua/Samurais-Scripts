-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")

---@class Ragdoll : FeatureBase
---@field private m_entity LocalPlayer
---@field private m_is_active boolean
---@field private m_last_audio_queue_time seconds
---@field private m_last_ragdoll_check_time seconds
local Ragdoll = setmetatable({}, FeatureBase)
Ragdoll.__index = Ragdoll

---@param entity LocalPlayer
---@return Ragdoll
function Ragdoll.new(entity)
	local self = FeatureBase.new(entity)
	---@diagnostic disable-next-line
	return setmetatable(self, Ragdoll)
end

function Ragdoll:Init()
	self.m_is_active = false
	self.m_last_audio_queue_time = 0
	self.m_last_ragdoll_check_time = 0
end

function Ragdoll:ShouldRun()
	return (GVars.features.self.rod or GVars.features.self.clumsy)
		and LocalPlayer:IsAlive()
		and (LocalPlayer:IsOnFoot() or LocalPlayer:GetVehicle():IsBike() or LocalPlayer:GetVehicle():IsBicycle())
		and not LocalPlayer:IsSwimming()
		and not HUD.IS_PAUSE_MENU_ACTIVE()
		and not NETWORK.NETWORK_IS_IN_MP_CUTSCENE()
end

function Ragdoll:Update()
	if (GVars.features.self.clumsy) then
		if (LocalPlayer:IsRagdoll() and Time.Now() > self.m_last_ragdoll_check_time) then
			self.m_last_ragdoll_check_time = Time.Now() + 3.5
		end

		if (Time.Now() > self.m_last_ragdoll_check_time) then
			PED.SET_PED_RAGDOLL_ON_COLLISION(LocalPlayer:GetHandle(), true)
		end
	elseif (GVars.features.self.rod and KeyManager:IsKeybindPressed("rod")) then
		if (LocalPlayer:IsBrowsingApps()) then
			return
		end

		PED.SET_PED_TO_RAGDOLL(LocalPlayer:GetHandle(), 1500, 0, 0, false, false, false)
	end

	if (GVars.features.self.ragdoll_sound and Game.IsOnline() and LocalPlayer:IsRagdoll()) then
		if (Time.Now() < self.m_last_audio_queue_time) then
			return
		end

		local voiceName = LocalPlayer:IsMale() and "WAVELOAD_PAIN_MALE" or "WAVELOAD_PAIN_FEMALE"
		Audio:PlaySpeechFromPosition("SCREAM_PANIC_SHORT", voiceName, LocalPlayer:GetPos(), "SPEECH_PARAMS_FORCE_SHOUTED")
		self.m_last_audio_queue_time = Time.Now() + 3
	end
end

return Ragdoll
