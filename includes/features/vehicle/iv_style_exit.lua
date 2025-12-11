---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local VehicleFeatureBase = require("VehicleFeatureBase")

---@class IVStyleExit : VehicleFeatureBase
---@field private m_pv PlayerVehicle -- Reference to PlayerVehicle
---@field private m_triggered boolean
---@field private m_timer Time.Timer
local IVStyleExit = setmetatable({}, VehicleFeatureBase)
IVStyleExit.__index = IVStyleExit

---@param pv PlayerVehicle
---@return IVStyleExit
function IVStyleExit.new(pv)
    local self = VehicleFeatureBase.new(pv)
    return setmetatable(self, IVStyleExit)
end

function IVStyleExit:Init()
    self.m_triggered = false
    self.m_timer = Timer.new(1000)
    self.m_timer:pause()
end

function IVStyleExit:ShouldRun()
    return (self.m_pv
    and self.m_pv:IsValid()
    and Self:IsDriving()
    and Self:IsOutside()
    and (GVars.features.vehicle.iv_exit or GVars.features.vehicle.no_wheel_recenter))
    and not Backend:AreControlsDisabled()
    and not HUD.IS_MP_TEXT_CHAT_TYPING()
end

---@param toggle boolean
function IVStyleExit:TogglePedFlag(toggle)
    PED.SET_PED_CONFIG_FLAG(Self:GetHandle(), 241, toggle)
end

function IVStyleExit:Cleanup()
    self.m_triggered = false
    self.m_timer:reset()
    self.m_timer:pause()
end

function IVStyleExit:LeaveVehicle(keepEngineOn)
    PED.SET_PED_CONFIG_FLAG(Self:GetHandle(), 241, keepEngineOn or false)
    local leftPressed = PAD.IS_CONTROL_PRESSED(0, 34)
    local rightPressed = PAD.IS_CONTROL_PRESSED(0, 35)
    local enabled = GVars.features.vehicle.no_wheel_recenter and (leftPressed or rightPressed)
    local vehHandle = self.m_pv:GetHandle()
    VEHICLE.SET_VEHICLE_ENGINE_ON(vehHandle, keepEngineOn or false, false, false)
    TASK.TASK_LEAVE_VEHICLE(Self:GetHandle(), vehHandle, enabled and 16 or 0) -- 16=tp outside. goofy because I don't feel like patching memory 🤷‍♂️
    self:Cleanup()
end

function IVStyleExit:Update()
    Backend:RegisterDisabledControl(75)

    local exitPressed = PAD.IS_DISABLED_CONTROL_PRESSED(0, 75)
    if (exitPressed) then
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
        PED.SET_PED_CONFIG_FLAG(Self:GetHandle(), 241, false)
        self:Cleanup()
        return
    end
end

return IVStyleExit
