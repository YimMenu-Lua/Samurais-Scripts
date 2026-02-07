-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")

---@class IVStyleExit : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_triggered boolean
---@field private m_timer Timer
---@field private m_steering_timer Timer
---@field private m_pending_steering boolean
---@field private m_last_steer_angle float
local IVStyleExit = setmetatable({}, FeatureBase)
IVStyleExit.__index = IVStyleExit

---@param pv PlayerVehicle
---@return IVStyleExit
function IVStyleExit.new(pv)
	local self = FeatureBase.new(pv)
	---@diagnostic disable-next-line
	return setmetatable(self, IVStyleExit)
end

function IVStyleExit:Init()
	self.m_triggered        = false
	self.m_pending_steering = false
	self.m_last_steer_angle = 0.0
	self.m_steering_timer   = Timer.new(200)
	self.m_timer            = Timer.new(1000)
	self.m_timer:pause()
	self.m_steering_timer:pause()
end

function IVStyleExit:ShouldRun()
	return (self.m_entity
			and self.m_entity:IsValid()
			and self.m_entity:IsLandVehicle()
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

function IVStyleExit:ShouldReapplySteering()
	local fVal = math.abs(self.m_last_steer_angle)
	return fVal ~= 0 and fVal < 1 and fVal > 0.001
end

---@param keepEngineOn boolean
function IVStyleExit:LeaveVehicle(keepEngineOn)
	local vehHandle = self.m_entity:GetHandle()
	local enabled   = GVars.features.vehicle.no_wheel_recenter and self.m_entity:IsCar()
	Self:SetConfigFlag(Enums.ePedConfigFlags.LeaveEngineOnWhenExitingVehicles, keepEngineOn)

	if (enabled) then
		self.m_last_steer_angle = self.m_entity:Resolve().m_current_steering:get_float()
		if (not keepEngineOn) then
			VEHICLE.SET_VEHICLE_ENGINE_ON(self.m_entity:GetHandle(), false, true, false)
		end
	end

	TASK.TASK_LEAVE_VEHICLE(Self:GetHandle(), vehHandle, 0)

	if (self:ShouldReapplySteering()) then
		self.m_pending_steering = true
		self.m_steering_timer:reset()
		self.m_steering_timer:resume()
	end

	self:Cleanup()
end

function IVStyleExit:Update()
	PAD.DISABLE_CONTROL_ACTION(0, 75, true)

	if (PAD.IS_DISABLED_CONTROL_PRESSED(0, 75)) then
		if (self.m_entity:GetSpeed() > 15) then
			TASK.TASK_LEAVE_VEHICLE(Self:GetHandle(), self.m_entity:GetHandle(), 4160)
			self:Cleanup()
			return
		end

		if (not GVars.features.vehicle.iv_exit and not self.m_triggered) then
			self:LeaveVehicle(false)
		end

		self.m_triggered = true
		self.m_timer:resume()
	end

	if (self.m_triggered) then
		if (PAD.IS_DISABLED_CONTROL_RELEASED(0, 75) and not self.m_timer:is_done()) then
			self:LeaveVehicle(true)
		elseif (PAD.IS_DISABLED_CONTROL_PRESSED(0, 75) and self.m_timer:is_done()) then
			self:LeaveVehicle(false)
		end
	end

	if (self.m_pending_steering) then
		local veh = self.m_entity
		if (veh and veh:IsValid()) then
			local pSteering = veh:Resolve().m_current_steering
			pSteering:set_float(self.m_last_steer_angle)
		end

		if (self.m_steering_timer:is_done()) then
			self.m_pending_steering = false
			self.m_last_steer_angle = 0.0
		end
	end

	if (self.m_triggered and not Self:IsDriving()) then
		Self:SetConfigFlag(Enums.ePedConfigFlags.LeaveEngineOnWhenExitingVehicles, false)
		self:Cleanup()
		return
	end
end

return IVStyleExit
