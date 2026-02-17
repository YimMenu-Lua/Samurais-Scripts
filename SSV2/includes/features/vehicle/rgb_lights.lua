-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")

---@class RGBLights : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_last_update_time milliseconds
---@field private m_is_active boolean
---@field private m_light_index integer
---@field private m_light_direction integer
---@field private m_brightness integer
---@overload fun(pv: PlayerVehicle): RGBLights
---@diagnostic disable-next-line
local RGBLights = setmetatable({}, FeatureBase)
RGBLights.__index = RGBLights

---@param pv PlayerVehicle
---@return RGBLights
function RGBLights.new(pv)
	local self = FeatureBase.new(pv)
	---@diagnostic disable-next-line
	return setmetatable(self, RGBLights)
end

function RGBLights:Init()
	self.m_is_active = false
	self.m_light_index = 0
	self.m_brightness = 1.0
	self.m_light_direction = -0.1
	self.m_last_update_time = 0
end

function RGBLights:ShouldRun()
	return (self.m_entity
		and self.m_entity:IsValid()
		and self.m_entity:IsLandVehicle()
		and self.m_entity:IsEngineOn()
		and GVars.features.vehicle.rgb_lights.enabled
		and not VEHICLE.GET_BOTH_VEHICLE_HEADLIGHTS_DAMAGED(self.m_entity:GetHandle())
	)
end

---@return boolean
function RGBLights:IsActive()
	return self.m_is_active
end

function RGBLights:Update()
	local PV = self.m_entity
	local handle = PV:GetHandle()
	local speed = GVars.features.vehicle.rgb_lights.speed

	if (not PV.m_default_xenon_lights.enabled) then
		VEHICLE.TOGGLE_VEHICLE_MOD(handle, 22, true)
	end

	if (Time.Millis() < self.m_last_update_time) then
		return
	end

	VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(handle, self.m_light_index)
	VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(handle, self.m_brightness)

	self.m_brightness = self.m_brightness + self.m_light_direction

	if (self.m_brightness <= 0.1 or self.m_brightness >= 1.0) then
		self.m_light_index = (self.m_light_index + 1) % 13
		self.m_light_direction = -self.m_light_direction
	end

	self.m_last_update_time = Time.Millis() + (100 / speed)
end

return RGBLights
