---@class Game.Vehicle
Game.Vehicle = {}
Game.Vehicle.__index = Game.Vehicle

-- Returns the name of the specified vehicle.
---@param vehicle number
Game.Vehicle.Name = function(vehicle)
    if ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then
        return vehicles.get_vehicle_display_name(Game.GetEntityModel(vehicle))
    end
    return ""
end

-- Returns the manufacturer's name of the specified vehicle.
---@param vehicle number
Game.Vehicle.Manufacturer = function(vehicle)
    if ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then
        local mfr = VEHICLE.GET_MAKE_NAME_FROM_VEHICLE_MODEL(Game.GetEntityModel(vehicle))
        return (mfr:lower():gsub("^%l", string.upper))
    end

    return ""
end

-- Returns the class of the specified vehicle.
Game.Vehicle.Class = function(vehicle)
    return eVehicleClasses[VEHICLE.GET_VEHICLE_CLASS(vehicle) + 1] or "Unknown"
end

-- Returns a table containing all occupants of a vehicle.
---@param vehicle integer
Game.Vehicle.GetOccupants = function(vehicle)
    local passengers = {}
    if ENTITY.DOES_ENTITY_EXIST(vehicle) and ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then
        local maxPassengers = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(vehicle))
        for i = -1, maxPassengers do
            if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, i, true) then
                local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, i, false)
                if ped ~= 0 then
                    table.insert(passengers, ped)
                end
            end
        end
        return passengers
    end
end

---@param vehicle integer
Game.Vehicle.IsEnemyVehicle = function(vehicle)
    if ENTITY.DOES_ENTITY_EXIST(vehicle) and ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then
        local occupants = Game.Vehicle.GetOccupants(vehicle)
        if #occupants > 0 then
            for _, p in ipairs(occupants) do
                if not ENTITY.IS_ENTITY_DEAD(p, false) and Self.IsPedMyEnemy(p) then
                    return true
                end
            end
        end
    end
    return false
end

-- Returns whether a vehicle is weaponized.
---@param vehicle integer
Game.Vehicle.IsWeaponized = function(vehicle)
    return VEHICLE.DOES_VEHICLE_HAVE_WEAPONS(vehicle)
end

-- Returns whether the vehicle has ABS as standard.
Game.Vehicle.HasABS = function(vehicle)
    if Self.IsDriving() and Self.Vehicle.IsCar then
        local m_model_flags = Memory.GetVehicleInfo(vehicle).m_model_flags
        if m_model_flags ~= nil then
            local iModelFlags = m_model_flags:get_dword()
            return Lua_fn.has_bit(iModelFlags, MF._ABS_STD)
        end
    end
    return false
end

-- Returns whether the vehicle is in the sports or super class.
--
-- *(different from the Sports class)*.
---@param vehicle integer
Game.Vehicle.IsSportsOrSuper = function(vehicle)
    return (
        VEHICLE.GET_VEHICLE_CLASS(vehicle) == 4 or
        VEHICLE.GET_VEHICLE_CLASS(vehicle) == 6 or
        VEHICLE.GET_VEHICLE_CLASS(vehicle) == 7 or
        VEHICLE.GET_VEHICLE_CLASS(vehicle) == 22
    )
end

-- Returns whether the vehicle is a sports car.
--
-- *(different from the Sports class)*.
---@param vehicle integer
Game.Vehicle.IsSportsCar = function(vehicle)
    return Memory.GetVehicleModelFlag(vehicle, VMF._SPORTS)
end

-- Returns whether the vehicle is a pussy shaver.
---@param vehicle integer
Game.Vehicle.IsElectric = function(vehicle)
    return Memory.GetVehicleModelFlag(vehicle, VMF._IS_ELECTRIC)
end

-- Returns whether the vehicle is an F1 race car.
---@param vehicle integer
Game.Vehicle.IsFormulaOne = function(vehicle)
    return Memory.GetVehicleModelFlag(vehicle, VMF._IS_FORMULA_VEHICLE) or
        Game.Vehicle.Class(vehicle) == "Open Wheel"
end

-- Returns whether the vehicle is a lowrider
--
-- equipped with hydraulic suspension.
---@param vehicle integer
Game.Vehicle.IsLowrider = function(vehicle)
    return Memory.GetVehicleModelFlag(vehicle, VMF._HAS_LOWRIDER_HYDRAULICS) or
        Memory.GetVehicleModelFlag(vehicle, VMF._HAS_LOWRIDER_DONK_HYDRAULICS)
end

-- Applies a custom paint job to the vehicle
---@param vehicle integer
---@param hex string
---@param p integer
---@param m boolean
---@param is_primary boolean
---@param is_secondary boolean
Game.Vehicle.SetCustomPaint = function(vehicle, hex, p, m, is_primary, is_secondary)
    if ENTITY.DOES_ENTITY_EXIST(vehicle) then
        local pt = m and 3 or 1
        local r, g, b = Lua_fn.HexToRGB(hex)
        VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
        if is_primary then
            VEHICLE.SET_VEHICLE_MOD_COLOR_1(vehicle, pt, 0, p)
            VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, r, g, b)
            VEHICLE.SET_VEHICLE_EXTRA_COLOURS(vehicle, p, 0)
        end
        if is_secondary then
            VEHICLE.SET_VEHICLE_MOD_COLOR_2(vehicle, pt, 0)
            VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle, r, g, b)
        end
    end
end

---@param vehicle integer
---@param toggle boolean
---@param s script_util
Game.Vehicle.LockDoors = function(vehicle, toggle, s)
    if (
        VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(vehicle)) and
        entities.take_control_of(vehicle, 300)
    ) then
        if toggle then
            for i = 0, (VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(vehicle) + 1) do
                if VEHICLE.GET_VEHICLE_DOOR_ANGLE_RATIO(vehicle, i) > 0.0 then
                    VEHICLE.SET_VEHICLE_DOORS_SHUT(vehicle, false)
                    break
                end
            end
            if VEHICLE.IS_VEHICLE_A_CONVERTIBLE(vehicle, false) and autoraiseroof and
                VEHICLE.GET_CONVERTIBLE_ROOF_STATE(vehicle) ~= 0 then
                VEHICLE.RAISE_CONVERTIBLE_ROOF(vehicle, false)
            else
                for i = 0, 7 do
                    -- VEHICLE.FIX_VEHICLE_WINDOW(vehicle, i) -- Unnecessary. Locking your car doesn't magically fix its broken windows. *realism intensifies*
                    VEHICLE.ROLL_UP_WINDOW(vehicle, i)
                end
            end
        end

        -- these won't do anything if the engine is off --
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 0, true)
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 1, true)
        --------------------------------------------------

        AUDIO.SET_HORN_PERMANENTLY_ON_TIME(vehicle, 1000)
        AUDIO.SET_HORN_PERMANENTLY_ON(vehicle)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED(vehicle, toggle and 2 or 1)
        VEHICLE.SET_VEHICLE_ALARM(vehicle, toggle)
        YimToast:ShowMessage("Samurai's Scripts", ("Vehicle %s"):format(toggle and "locked." or "unlocked."))
        s:sleep(696)
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 0, false)
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(vehicle, 1, false)
    end
end

---@param vehicle integer
---@param multiplier float
Game.Vehicle.SetAcceleration = function(vehicle, multiplier)
    if (
        not ENTITY.DOES_ENTITY_EXIST(vehicle) or not
        ENTITY.IS_ENTITY_A_VEHICLE(vehicle) or
        (math.type(multiplier) ~= "float")
    ) then
        return
    end

    local acc_ptr = Memory.GetVehicleInfo(vehicle).m_acceleration
    if acc_ptr:is_valid() then
        acc_ptr:set_float(multiplier)
    end
end
