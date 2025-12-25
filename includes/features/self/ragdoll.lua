---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local FeatureBase = require("includes.modules.FeatureBase")

---@class Ragdoll : FeatureBase
---@field private m_entity Self
---@field private m_is_active boolean
---@field private m_last_audio_queue_time seconds
---@field private m_last_ragdoll_check_time seconds
local Ragdoll = setmetatable({}, FeatureBase)
Ragdoll.__index = Ragdoll

---@param entity Self
---@return Ragdoll
function Ragdoll.new(entity)
	local self = FeatureBase.new(entity)
	return setmetatable(self, Ragdoll)
end

function Ragdoll:Init()
	self.m_is_active = false
	self.m_last_audio_queue_time = 0
	self.m_last_ragdoll_check_time = 0
end

function Ragdoll:ShouldRun()
	return (GVars.features.self.rod or GVars.features.self.clumsy)
		and Self:IsAlive()
		and (Self:IsOnFoot() or Self:GetVehicle():IsBike() or Self:GetVehicle():IsBicycle())
		and not Self:IsSwimming()
		and not HUD.IS_PAUSE_MENU_ACTIVE()
		and not NETWORK.NETWORK_IS_IN_MP_CUTSCENE()
end

function Ragdoll:Update()
	if (GVars.features.self.clumsy) then
		if (Self:IsRagdoll() and Time.now() > self.m_last_ragdoll_check_time) then
			self.m_last_ragdoll_check_time = Time.now() + 3.5
		end

		if (Time.now() > self.m_last_ragdoll_check_time) then
			PED.SET_PED_RAGDOLL_ON_COLLISION(Self:GetHandle(), true)
		end
	elseif (GVars.features.self.rod and KeyManager:IsKeybindPressed("rod")) then
		if (Self:IsBrowsingApps()) then
			return
		end

		PED.SET_PED_TO_RAGDOLL(Self:GetHandle(), 1500, 0, 0, false, false, false)
	end

	if (GVars.features.self.ragdoll_sound and Game.IsOnline() and Self:IsRagdoll()) then
		if (Time.now() < self.m_last_audio_queue_time) then
			return
		end

		local voiceName = Self:IsMale() and "WAVELOAD_PAIN_MALE" or "WAVELOAD_PAIN_FEMALE"
		Audio:PlaySpeechFromPosition("SCREAM_PANIC_SHORT", voiceName, Self:GetPos(), "SPEECH_PARAMS_FORCE_SHOUTED")
		self.m_last_audio_queue_time = Time.now() + 3
	end
end

return Ragdoll
