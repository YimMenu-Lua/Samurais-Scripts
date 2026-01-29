-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")

---@class BFD : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_is_toggled boolean
---@field private m_last_update_time milliseconds
local BFD = setmetatable({}, FeatureBase)
BFD.__index = BFD

---@param pv PlayerVehicle
---@return BFD
function BFD.new(pv)
	local self = FeatureBase.new(pv)
	---@diagnostic disable-next-line
	return setmetatable(self, BFD)
end

function BFD:Init()
	self.m_is_toggled = false
	self.m_last_update_time = 0
end

function BFD:ShouldRun()
	return (self.m_entity
		and self.m_entity:IsValid()
		and self.m_entity:IsCar()
		and self.m_entity:HasABS()
		and GVars.features.vehicle.abs_lights
	)
end

function BFD:IsToggled()
	return self:IsActive() and self.m_is_toggled
end

function BFD:Toggle()
	local PV = self.m_entity
	if (Time.millis() < self.m_last_update_time) then
		return
	end

	if VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(PV:GetHandle())
		and PAD.IS_CONTROL_PRESSED(0, 72)
		and (PV:GetSpeed() >= 19.44)
		and (PV:GetCurrentGear() > 0) then
		self.m_is_toggled = not self.m_is_toggled
	else
		self.m_is_toggled = false
	end

	self.m_last_update_time = Time.millis() + 100
end

function BFD:Update()
	self:Toggle()
	if (self.m_is_toggled) then
		if (not GVars.features.vehicle.performance_only or self.m_entity:IsPerformanceCar()) then
			VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(self.m_entity:GetHandle(), false)
		end
	end
end

return BFD
