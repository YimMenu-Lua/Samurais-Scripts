---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local FeatureBase = require("includes.modules.FeatureBase")

---@class IVStyleExit : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_triggered boolean
---@field private m_timer Time.Timer
local IVStyleExit = setmetatable({}, FeatureBase)
IVStyleExit.__index = IVStyleExit

---@param pv PlayerVehicle
---@return IVStyleExit
function IVStyleExit.new(pv)
	local self = FeatureBase.new(pv)
	return setmetatable(self, IVStyleExit)
end

function IVStyleExit:Init()
	self.m_triggered = false
	self.m_timer = Timer.new(1000)
	self.m_timer:pause()
end

function IVStyleExit:ShouldRun()
	return (self.m_entity
			and self.m_entity:IsValid()
			and Self:IsDriving()
			and Self:IsOutside()
			and (GVars.features.vehicle.iv_exit or GVars.features.vehicle.no_wheel_recenter))
		and not Backend:AreControlsDisabled()
		and not HUD.IS_MP_TEXT_CHAT_TYPING()
end

function IVStyleExit:Cleanup()
	self.m_triggered = false
	self.m_timer:reset()
	self.m_timer:pause()
end

---@param keepEngineOn boolean
function IVStyleExit:LeaveVehicle(keepEngineOn)
	local vehHandle = self.m_entity:GetHandle()
	local leftPressed = PAD.IS_CONTROL_PRESSED(0, 34)
	local rightPressed = PAD.IS_CONTROL_PRESSED(0, 35)
	local enabled = GVars.features.vehicle.no_wheel_recenter and (leftPressed or rightPressed)
	Self:SetConfigFlag(Enums.ePedConfigFlags.LeaveEngineOnWhenExitingVehicles, keepEngineOn)
	TASK.TASK_LEAVE_VEHICLE(Self:GetHandle(), vehHandle, enabled and 16 or 0) -- 16=tp outside. goofy because I don't feel like patching memory 🤷‍♂️
	self:Cleanup()
end

function IVStyleExit:Update()
	PAD.DISABLE_CONTROL_ACTION(0, 75, true)

	local exitPressed = PAD.IS_DISABLED_CONTROL_PRESSED(0, 75)
	if (exitPressed) then
		if (self.m_entity:GetSpeed() > 15) then
			TASK.TASK_LEAVE_VEHICLE(Self:GetHandle(), self.m_entity:GetHandle(), 4160)
			self:Cleanup()
			return
		end

		if (not GVars.features.vehicle.iv_exit) then
			self:LeaveVehicle(false)
			return
		end

		self.m_timer:resume()
		self.m_triggered = true
	end

	if (self.m_triggered) then
		if (PAD.IS_DISABLED_CONTROL_RELEASED(0, 75) and not self.m_timer:is_done()) then
			self:LeaveVehicle(true)
			return
		elseif (PAD.IS_DISABLED_CONTROL_PRESSED(0, 75) and self.m_timer:is_done()) then
			self:LeaveVehicle(false)
			return
		end
	end

	if (self.m_triggered and not Self:IsDriving()) then
		PED.SET_PED_CONFIG_FLAG(Self:GetHandle(), Enums.ePedConfigFlags.LeaveEngineOnWhenExitingVehicles, false)
		self:Cleanup()
		return
	end
end

return IVStyleExit
