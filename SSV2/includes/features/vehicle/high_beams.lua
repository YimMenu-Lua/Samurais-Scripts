-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")

---@class HighBeams : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_is_active boolean
local HighBeams = setmetatable({}, FeatureBase)
HighBeams.__index = HighBeams

---@param pv PlayerVehicle
---@return HighBeams
function HighBeams.new(pv)
	local self = FeatureBase.new(pv)
	---@diagnostic disable-next-line
	return setmetatable(self, HighBeams)
end

function HighBeams:Init()
	self.m_is_active = false
end

function HighBeams:ShouldRun()
	return (self.m_entity
		and self.m_entity:IsValid()
		and self.m_entity:IsLandVehicle()
		and self.m_entity:IsEngineOn()
		and Self:IsDriving()
		and GVars.features.vehicle.horn_beams
		and not VEHICLE.GET_BOTH_VEHICLE_HEADLIGHTS_DAMAGED(self.m_entity:GetHandle()))
end

function HighBeams:Update()
	local handle = self.m_entity:GetHandle()
	local pressed = PAD.IS_CONTROL_PRESSED(0, 86)
	if (pressed ~= self.m_is_active) then
		self.m_is_active = pressed
		VEHICLE.SET_VEHICLE_FULLBEAM(handle, pressed)
		VEHICLE.SET_VEHICLE_LIGHTS(handle, pressed and 2 or 0)
	end
end

return HighBeams
