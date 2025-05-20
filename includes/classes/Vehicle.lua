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

---@param vehicle integer
Game.Vehicle.IsAnySeatFree = function(vehicle)
    if not vehicle or not ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then
        return false
    end

    return VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(vehicle)
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
---@return boolean
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
---@return boolean
Game.Vehicle.IsWeaponized = function(vehicle)
    return VEHICLE.DOES_VEHICLE_HAVE_WEAPONS(vehicle)
end

---@param vehicle integer
---@return boolean
Game.Vehicle.IsCar = function(vehicle)
    if not vehicle or vehicle == 0 then
        return false
    end

    return VEHICLE.IS_THIS_MODEL_A_CAR(Game.EnsureModelHash(vehicle))
end

---@param vehicle integer
---@return boolean
Game.Vehicle.IsBike = function(vehicle)
    if not vehicle or vehicle == 0 then
        return false
    end

    return VEHICLE.IS_THIS_MODEL_A_BIKE(Game.EnsureModelHash(vehicle))
end

---@param vehicle integer
---@return boolean
Game.Vehicle.IsQuad = function(vehicle)
    if not vehicle or vehicle == 0 then
        return false
    end

    return (
        VEHICLE.IS_THIS_MODEL_A_QUADBIKE(Game.EnsureModelHash(vehicle)) or
        VEHICLE.IS_THIS_MODEL_AN_AMPHIBIOUS_QUADBIKE(Game.EnsureModelHash(vehicle))
    )
end

---@param vehicle integer
---@return boolean
Game.Vehicle.IsPlane = function(vehicle)
    if not vehicle or vehicle == 0 then
        return false
    end

    return VEHICLE.IS_THIS_MODEL_A_PLANE(Game.EnsureModelHash(vehicle))
end

---@param vehicle integer
---@return boolean
Game.Vehicle.IsHeli = function(vehicle)
    if not vehicle or vehicle == 0 then
        return false
    end

    return VEHICLE.IS_THIS_MODEL_A_HELI(Game.EnsureModelHash(vehicle))
end

---@param vehicle integer
---@return boolean
Game.Vehicle.IsSubmersible = function(vehicle)
    if not vehicle or vehicle == 0 then
        return false
    end

    return VEHICLE.IS_THIS_MODEL_AN_AMPHIBIOUS_CAR(Game.EnsureModelHash(vehicle))
end


---@param vehicle integer
---@return boolean
Game.Vehicle.IsBicycle = function(vehicle)
    if not vehicle or vehicle == 0 then
        return false
    end

    return VEHICLE.IS_THIS_MODEL_A_BICYCLE(Game.EnsureModelHash(vehicle))
end

-- Returns whether the vehicle has ABS as standard.
Game.Vehicle.HasABS = function(vehicle)
    if Self.IsDriving() and Self.Vehicle.IsCar then
        local pModelFlags = Memory.GetVehicleInfo(vehicle).m_model_flags
        if pModelFlags:is_valid() then
            local iModelFlags = pModelFlags:get_dword()
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

---@param vehicle integer
Game.Vehicle.MaxPerformance = function(vehicle)
    if not vehicle
    or not VEHICLE.IS_VEHICLE_DRIVEABLE(vehicle, false)
    or not ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then
        return
    end

    local maxArmor = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, 16) - 1
    while VEHICLE.IS_VEHICLE_MOD_GEN9_EXCLUSIVE(vehicle, 16, maxArmor) do
        maxArmor = maxArmor - 1
        yield()
    end
    VEHICLE.SET_VEHICLE_MOD(vehicle, 16, maxArmor, false)

    local maxEngine = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, 11) - 1
    while VEHICLE.IS_VEHICLE_MOD_GEN9_EXCLUSIVE(vehicle, 11, maxEngine) do
        maxEngine = maxEngine - 1
        yield()
    end
    VEHICLE.SET_VEHICLE_MOD(vehicle, 11, maxEngine, false)

    local maxBrakes = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, 12) - 1
    while VEHICLE.IS_VEHICLE_MOD_GEN9_EXCLUSIVE(vehicle, 12, maxBrakes) do
        maxBrakes = maxBrakes - 1
        yield()
    end
    VEHICLE.SET_VEHICLE_MOD(vehicle, 12, maxBrakes, false)

    local maxTrans = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, 13) - 1
    while VEHICLE.IS_VEHICLE_MOD_GEN9_EXCLUSIVE(vehicle, 13, maxTrans) do
        maxTrans = maxTrans - 1
        yield()
    end
    VEHICLE.SET_VEHICLE_MOD(vehicle, 13, maxTrans, false)

    local maxSusp = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, 15) - 1
    while VEHICLE.IS_VEHICLE_MOD_GEN9_EXCLUSIVE(vehicle, 15, maxSusp) do
        maxSusp = maxSusp - 1
        yield()
    end
    VEHICLE.SET_VEHICLE_MOD(vehicle, 15, maxSusp, false)

    VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 18, true)
    VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 22, true)
    VEHICLE.SET_VEHICLE_FIXED(vehicle)
    VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(vehicle)
    VEHICLE.SET_VEHICLE_BODY_HEALTH(vehicle, 1000)
    VEHICLE.SET_VEHICLE_STRONG(vehicle, true)
end

-- Applies a custom paint job to the vehicle
---@param vehicle integer
---@param hex string
---@param p integer
---@param m boolean
---@param is_primary boolean
---@param is_secondary boolean
Game.Vehicle.SetCustomPaint = function(vehicle, hex, p, m, is_primary, is_secondary)
    script.run_in_fiber(function()
        if ENTITY.DOES_ENTITY_EXIST(vehicle) then
            local pt = m and 3 or 1
            local r, g, b, _ = Col(hex):AsRGBA()
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
    end)
end

---@param vehicle integer
Game.Vehicle.RepairVehicle = function(vehicle)
    if not Game.IsScriptHandle(vehicle) then
        return
    end

    VEHICLE.SET_VEHICLE_FIXED(vehicle)
    VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(vehicle)
    VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0)

    local pCVehicle = memory.handle_to_ptr(vehicle)

    if pCVehicle:is_null() then
        return
    end

    local m_water_damage = pCVehicle:add(0xD8)
    local value = m_water_damage:get_int()

    if value and type(value) == "number" then
        m_water_damage:set_int(Lua_fn.clear_bit(value, 0))
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

    local pAcceleration = Memory.GetVehicleInfo(vehicle).m_acceleration
    if pAcceleration:is_valid() then
        pAcceleration:set_float(multiplier)
    end
end

---@param vehicle integer
---@return float|nil
Game.Vehicle.GetDeformation = function(vehicle)
    if not ENTITY.DOES_ENTITY_EXIST(vehicle) or not ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then
        return nil
    end

    local pDeformMult = Memory.GetVehicleInfo(vehicle).m_deformation_mult
    if pDeformMult:is_valid() then
        return pDeformMult:get_float()
    end

    return nil
end

---@param vehicle integer
---@param multiplier float
Game.Vehicle.SetDeformation = function(vehicle, multiplier)
    if not ENTITY.DOES_ENTITY_EXIST(vehicle) or not ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then
        return
    end

    local pDeformMult = Memory.GetVehicleInfo(vehicle).m_deformation_mult
    if pDeformMult:is_valid() then
        pDeformMult:set_float(multiplier)
    end
end

---@param vehicle integer
---@return table
Game.Vehicle.GetVehicleExhaustBones = function(vehicle)
    local bones = {}
    local bParam = false
    local count = VEHICLE.GET_VEHICLE_MAX_EXHAUST_BONE_COUNT_() - 1
    local boneIndex

    for i = 0, count do
        bParam, boneIndex = VEHICLE.GET_VEHICLE_EXHAUST_BONE_(vehicle, i, boneIndex, bParam)
        if bParam then
            table.insert(bones, boneIndex)
        end
    end

    return bones
end

---@param vehicle integer
Game.Vehicle.GetVehicleMods = function(vehicle)
    local t = {}

    for i = 0, 49 do
        table.insert(t, VEHICLE.GET_VEHICLE_MOD(vehicle, i))
    end

    return t
end

---@param vehicle integer
Game.Vehicle.GetVehicleColors = function(vehicle)
    local col1 = {r = 0, g = 0, b = 0}
    local col2 = {r = 0, g = 0, b = 0}

    if VEHICLE.GET_IS_VEHICLE_PRIMARY_COLOUR_CUSTOM(vehicle) then
        col1.r, col1.g, col1.b = VEHICLE.GET_VEHICLE_CUSTOM_PRIMARY_COLOUR(
            vehicle,
            col1.r,
            col1.g,
            col1.b
        )
    else
        col1.r, col1.g, col1.b = VEHICLE.GET_VEHICLE_COLOR(
            vehicle,
            col1.r,
            col1.g,
            col1.b
        )
    end

    if VEHICLE.GET_IS_VEHICLE_SECONDARY_COLOUR_CUSTOM(vehicle) then
        col2.r, col2.g, col2.b = VEHICLE.GET_VEHICLE_CUSTOM_PRIMARY_COLOUR(
            vehicle,
            col2.r,
            col2.g,
            col2.b
        )
    else
        col2.r, col2.g, col2.b = VEHICLE.GET_VEHICLE_COLOR(
            vehicle,
            col2.r,
            col2.g,
            col2.b
        )
    end

    return col1, col2
end

Game.Vehicle.GetCustomWheels = function(vehicle)
    local wheel_type = VEHICLE.GET_VEHICLE_WHEEL_TYPE(vehicle)
    local wheel_index = VEHICLE.GET_VEHICLE_MOD_VARIATION(vehicle, 23)

    return wheel_type, wheel_index
end

Game.Vehicle.PreloadMod = function(vehicle, type, index)
    VEHICLE.PRELOAD_VEHICLE_MOD(vehicle, type, index)

    while not VEHICLE.HAS_PRELOAD_MODS_FINISHED(vehicle) do
        VEHICLE.PRELOAD_VEHICLE_MOD(vehicle, type, index)
        coroutine.yield()
    end

    return VEHICLE.HAS_PRELOAD_MODS_FINISHED(vehicle)
end

---@param vehicle integer
---@param t table
Game.Vehicle.ApplyVehicleMods = function(vehicle, t)
    script.run_in_fiber(function()
        VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)

        if t.mods then
            for slot, mod in ipairs(t.mods) do
                if mod ~= -1 then
                    if Game.Vehicle.PreloadMod(vehicle, (slot - 1), mod) then
                        VEHICLE.SET_VEHICLE_MOD(vehicle, (slot - 1), mod, true)
                    end
                end
            end
            VEHICLE.RELEASE_PRELOAD_MODS(vehicle)
        end

        if t.primary_color then
            VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(
                vehicle,
                t.primary_color.r,
                t.primary_color.g,
                t.primary_color.b
            )
        end

        if t.secondary_color then
            VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(
                vehicle,
                t.secondary_color.r,
                t.secondary_color.g,
                t.secondary_color.b
            )
        end

        if t.window_tint then
            VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, t.window_tint)
        end

        if t.window_states then
            for i = 1, #t.window_states do
                if not t.window_states[i] then
                    VEHICLE.ROLL_DOWN_WINDOW(vehicle, i - 1)
                end
            end
        end

        if t.plate_text and type(t.plate_text) == "string" then
            VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, t.plate_text)
        end
    end)
end

Game.Vehicle.Clone = function(vehicle, cloneSpawnPos)
    local prevMods = Game.Vehicle.GetVehicleMods(vehicle)
    local col1, col2 = Game.Vehicle.GetVehicleColors(vehicle)
    local licensePlate = VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT(vehicle)
    local clone = Game.CreateVehicle(Game.GetEntityModel(vehicle), cloneSpawnPos)

    Game.Vehicle.ApplyVehicleMods(
        clone,
        {
            mods = prevMods,
            primary_color = col1,
            secondary_color = col2,
            window_tint = VEHICLE.GET_VEHICLE_WINDOW_TINT(vehicle),
            plate_text =  licensePlate or "clone"
        }
    )

    return clone
end

Game.Vehicle.HasCrashed = function()
    if not ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(Self.Vehicle.Current) then
        return false, ""
    end

    local entity = ENTITY.GET_LAST_ENTITY_HIT_BY_ENTITY_(Self.Vehicle.Current)

    if not entity or (entity == 0) or not ENTITY.DOES_ENTITY_EXIST(entity) then
        return false, ""
    end

    if (not ENTITY.IS_ENTITY_A_PED(entity) and
        not ENTITY.IS_ENTITY_A_VEHICLE(entity) and
        not ENTITY.IS_ENTITY_AN_OBJECT(entity)
    ) then
        return true, "Samir, you're breaking the car!"
    end

    local entity_type = Memory.GetEntityType(entity)

    if entity_type == 0 then
        return false, ""
    elseif entity_type == 6 then
        return false, "Hit and run"
    elseif (entity_type == 5) or (entity_type == 157) then
        return true, "Samir, you're breaking the car!"
    elseif (entity_type == 1) or (entity_type == 33) or (entity_type == 7) then
        if ENTITY.DOES_ENTITY_HAVE_PHYSICS(entity) then
            local model = ENTITY.GET_ENTITY_MODEL(entity)
            for _, m in ipairs(eCollisionInvalidModels) do
                if model == m then
                    return true, "Samir, you're breaking the car!"
                end
            end
            return false, "Wrecking ball"
        else
            return true, "Samir, you're breaking the car!"
        end
    else
        return false, ""
    end
end
