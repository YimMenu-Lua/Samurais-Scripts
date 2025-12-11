---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local VehicleFeatureBase = require("VehicleFeatureBase")

---@class HighBeams : VehicleFeatureBase
---@field private m_pv PlayerVehicle -- Reference to PlayerVehicle
---@field private m_is_active boolean
local HighBeams = setmetatable({}, VehicleFeatureBase)
HighBeams.__index = HighBeams

---@param pv PlayerVehicle
---@return HighBeams
function HighBeams.new(pv)
    local self = VehicleFeatureBase.new(pv)
    return setmetatable(self, HighBeams)
end

function HighBeams:Init()
    self.m_is_active = false
end

function HighBeams:ShouldRun()
    return (self.m_pv
    and self.m_pv:IsValid()
    and self.m_pv:IsLandVehicle()
    and self.m_pv:IsEngineOn()
    and Self:IsDriving()
    and GVars.features.vehicle.horn_beams
    and not VEHICLE.GET_BOTH_VEHICLE_HEADLIGHTS_DAMAGED(self.m_pv:GetHandle()))
end

function HighBeams:Update()
    local handle = self.m_pv:GetHandle()
    local pressed = PAD.IS_CONTROL_PRESSED(0, 86)
    if (pressed ~= self.m_is_active) then
        self.m_is_active = pressed
        VEHICLE.SET_VEHICLE_FULLBEAM(handle, pressed)
        VEHICLE.SET_VEHICLE_LIGHTS(handle, pressed and 2 or 0)
    end
end

return HighBeams
