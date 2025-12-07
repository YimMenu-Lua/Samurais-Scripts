---@diagnostic disable: param-type-mismatch

-- Singleton
---@class PlayerVehicle : Vehicle
---@field private m_handle handle
---@field private m_abs_state StateMachine
---@field private m_esc_state StateMachine
---@field private m_is_nos_active boolean
---@overload fun(handle: handle): PlayerVehicle
local PlayerVehicle = Class("PlayerVehicle", Vehicle)

---@return PlayerVehicle
function PlayerVehicle:init(handle)
    ---@type PlayerVehicle
    local instance = setmetatable({
        m_is_nos_active = false,
        m_handle = handle,
    }, PlayerVehicle)

    instance.m_abs_state = StateMachine({
        predicate = function(_, veh)
            return Self:IsDriving()
                and veh:IsCar()
                and veh:HasABS()
                and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(veh:GetHandle())
                and PAD.IS_CONTROL_PRESSED(0, 72)
                and ((veh:GetSpeed() * 3.6) >= 100)
        end,
        interval = 0.1,
        callback = function(_, veh)
            VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(
                veh:GetHandle(),
                false
            )
        end
    })

    instance.m_esc_state = StateMachine({
        predicate = function(_, veh)
            return Self:IsDriving()
                and veh:IsCar()
                and veh:IsDrifting()
                and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(veh:GetHandle())
        end,
        interval = 0.1
    })

    ThreadManager:CreateNewThread("SS_VEHICLE", function()
        instance:Main()
    end)

    return instance
end

function PlayerVehicle:GetModelHash()
    return ENTITY.GET_ENTITY_MODEL(self:GetHandle())
end

---@param handle handle
function PlayerVehicle:Set(handle)
    self.m_handle = handle
end

function PlayerVehicle:Reset()
    self.m_handle = 0
end

---@return boolean
function PlayerVehicle:IsDrivable()
    return VEHICLE.IS_VEHICLE_DRIVEABLE(self:GetHandle(), false)
end

function PlayerVehicle:IsLandVehicle()
    return self:IsCar() or self:IsQuad() or self:IsBike()
end

function PlayerVehicle:IsEngineOn()
    return VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(self:GetHandle())
end

function PlayerVehicle:IsDrifting()
    if (not self:IsCar()) then
        return false
    end

    local handle = self:GetHandle()
    local speed_vector = ENTITY.GET_ENTITY_SPEED_VECTOR(handle, true)
    if (speed_vector.x == 0) then
        return false
    end

    return VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(handle) and (speed_vector.x <= -6 or speed_vector.x >= 6)
end

function PlayerVehicle:IsABSEngaged()
    return self.m_abs_state:IsToggled()
end

function PlayerVehicle:IsESCEngaged()
    return self.m_esc_state:IsToggled()
end

function PlayerVehicle:IsNOSActive()
    return self.m_is_nos_active
end

function PlayerVehicle:GetRPM()
    return VEHICLE.GET_VEHICLE_CURRENT_REV_RATIO_(self:GetHandle())
end

function PlayerVehicle:GetThrottle()
    return 0 -- TODO: jet throttle
end

function PlayerVehicle:GetCurrentGear()
    return VEHICLE.GET_VEHICLE_CURRENT_DRIVE_GEAR_(self:GetHandle())
end

function PlayerVehicle:UpdateABS()
    if (not GVars.features.vehicle.abs_lights) then
        return
    end

    self.m_abs_state:Update(self)
end

function PlayerVehicle:UpdateESC()
    if (not GVars.features.speedometer.enabled) then
        return
    end

    self.m_esc_state:Update(self)
end

function PlayerVehicle:Main()
    if (not self:IsValid()) then
        return
    end

    if (GVars.features.vehicle.fast_vehicles) then
        VEHICLE.MODIFY_VEHICLE_TOP_SPEED(self:GetHandle(), 100)
    end

    self:UpdateABS()
    self:UpdateESC()
end

return PlayerVehicle
