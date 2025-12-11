---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local VehicleFeatureBase = require("VehicleFeatureBase")

---@class DriftMode : VehicleFeatureBase
---@field private m_pv PlayerVehicle -- Reference to PlayerVehicle
---@field private m_smoke_fx_l array<handle>|nil
---@field private m_smoke_fx_r array<handle>|nil
---@field private m_is_active boolean
---@overload fun(pv: PlayerVehicle): DriftMode
local DriftMode = setmetatable({}, VehicleFeatureBase)
DriftMode.__index = DriftMode

---@param pv PlayerVehicle
---@return DriftMode
function DriftMode.new(pv)
    local self = VehicleFeatureBase.new(pv)
    return setmetatable(self, DriftMode)
end

function DriftMode:Init()
    self.m_is_active = false
end

function DriftMode:ShouldRun()
    return (self.m_pv
    and self.m_pv:IsValid()
    and self.m_pv:IsLandVehicle()
    and self.m_pv:IsEngineOn()
    and Self:IsDriving()
    and GVars.features.vehicle.drift.enabled)
end

---@return boolean
function DriftMode:IsActive()
    return self.m_is_active
end

-- function DriftMode:UpdateFX()
-- -- TODO
-- end

function DriftMode:Update()
    local PV = self.m_pv
    local handle = PV:GetHandle()

    if (PV:IsDriftButtonPressed()) then
        local mode = GVars.features.vehicle.drift.mode
        local intensty = GVars.features.vehicle.drift.intensity
        local powerIncrease = GVars.features.vehicle.drift.power

        if (not self.m_active) then
            if (mode == 1) then
                VEHICLE.SET_VEHICLE_REDUCE_GRIP(handle, true)
                VEHICLE.SET_VEHICLE_REDUCE_GRIP_LEVEL(handle, intensty)
            else
                VEHICLE.SET_DRIFT_TYRES(handle, true)
            end
        end

        VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(handle, powerIncrease)
        self.m_active = true
    elseif (self.m_active) then
        VEHICLE.SET_VEHICLE_REDUCE_GRIP(handle, false)
        VEHICLE.SET_DRIFT_TYRES(handle, false)
        VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(handle, 1.0)
        self.m_active = false
    end
end

return DriftMode
