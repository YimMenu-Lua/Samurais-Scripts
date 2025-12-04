--------------------------------------
-- Class: Vehicle
--------------------------------------
-- Class representing a GTA V vehicle.
---@class Vehicle : Entity
---@field private m_internal CVehicle
---@field private m_class_id number
---@field private m_num_seats number
---@field private m_max_passengers number
---@field Resolve fun() : CVehicle
---@field Create fun(_, modelHash: joaat_t, entityType: eEntityType, pos?: vec3, heading?: number, isNetwork?: boolean, isScriptHostPed?: boolean): Vehicle
---@overload fun(handle: handle): Vehicle
Vehicle = Class("Vehicle", Entity)

---@return boolean
function Vehicle:IsValid()
    return ENTITY.DOES_ENTITY_EXIST(self:GetHandle()) and ENTITY.IS_ENTITY_A_VEHICLE(self:GetHandle())
end

---@return string
function Vehicle:GetName()
    if not self:IsValid() then
        return ""
    end

    return vehicles.get_vehicle_display_name(self:GetModelHash())
end

---@return string
function Vehicle:GetManufacturer()
    if not self:IsValid() then
        return ""
    end

    local mfr = VEHICLE.GET_MAKE_NAME_FROM_VEHICLE_MODEL(self:GetModelHash())
    return mfr:capitalize()
end

---@return number|nil
function Vehicle:GetClassID()
    if not self:IsValid() then
        return
    end

    if not self.m_class_id then
        self.m_class_id = VEHICLE.GET_VEHICLE_CLASS(self:GetHandle())
    end

    return self.m_class_id
end

---@return string
function Vehicle:GetClassName()
    local clsid = self:GetClassID()
    if not clsid then
        return "Unknown"
    end

    return EnumTostring(eVehicleClasses, clsid)
end

---@return array<handle>
function Vehicle:GetOccupants()
    if not self:IsValid() then
        return {}
    end

    ---@type array<handle>
    local passengers = {}
    local handle     = self:GetHandle()
    local max_seats  = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(self:GetModelHash())

    for i = -1, max_seats do
        if not VEHICLE.IS_VEHICLE_SEAT_FREE(handle, i, true) then
            local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(handle, i, false)
            if (ped and ped ~= 0) then
                table.insert(passengers, ped)
            end
        end
    end

    return passengers
end

---@return number
function Vehicle:GetNumberOfPassengers()
    if not self:IsValid() then
        return 0
    end

    if not self.m_max_passengers then
        self.m_max_passengers = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(self:GetHandle())
    end

    return self.m_max_passengers
end

---@return number
function Vehicle:GetNumberOfSeats()
    if not self:IsValid() then
        return 0
    end

    if not self.m_num_seats then
        self.m_num_seats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(self:GetModelHash())
    end

    return self.m_num_seats
end

---@param seatIndex number
---@param isTaskRunning? boolean
function Vehicle:IsSeatFree(seatIndex, isTaskRunning)
    if not self:IsValid() then
        return false
    end

    if (isTaskRunning == nil) then
        isTaskRunning = true
    end

    return VEHICLE.IS_VEHICLE_SEAT_FREE(self:GetHandle(), seatIndex, isTaskRunning)
end

---@return boolean
function Vehicle:IsAnySeatFree()
    if not self:IsValid() then
        return false
    end

    return VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(self:GetHandle())
end

---@return boolean
function Vehicle:IsEmpty()
    if not self:IsValid() then
        return false -- ??
    end

    local seats = self:GetNumberOfSeats()

    for i = -1, seats do
        if self:IsSeatFree(i) then
            return false
        end
    end

    return true
end

---@return boolean
function Vehicle:IsLocalPlayerInVehicle()
    local PV = Self:GetVehicle()
    if not (PV and PV:IsValid() and self:IsValid()) then
        return false
    end

    return self:GetHandle() == PV:GetHandle()
end

---@return boolean
function Vehicle:IsEnemyVehicle()
    if (not self:IsValid() or self:IsEmpty()) then
        return false
    end

    local occupants = self:GetOccupants()
    for _, passenger in ipairs(occupants) do
        if not ENTITY.IS_ENTITY_DEAD(passenger, false) and Self:IsPedMyEnemy(passenger) then
            return true
        end
    end

    return false
end

---@return boolean
function Vehicle:IsWeaponized()
    return VEHICLE.DOES_VEHICLE_HAVE_WEAPONS(self:GetHandle())
end

---@return boolean
function Vehicle:IsCar()
    if not self:IsValid() then
        return false
    end

    return VEHICLE.IS_THIS_MODEL_A_CAR(self:GetModelHash())
end

---@return boolean
function Vehicle:IsBike()
    if not self:IsValid() then
        return false
    end

    return VEHICLE.IS_THIS_MODEL_A_BIKE(self:GetModelHash())
end

---@return boolean
function Vehicle:IsQuad()
    if not self:IsValid() then
        return false
    end

    local model = self:GetModelHash()

    return (
        VEHICLE.IS_THIS_MODEL_A_QUADBIKE(model) or
        VEHICLE.IS_THIS_MODEL_AN_AMPHIBIOUS_QUADBIKE(model)
    )
end

---@return boolean
function Vehicle:IsPlane()
    if not self:IsValid() then
        return false
    end

    return VEHICLE.IS_THIS_MODEL_A_PLANE(self:GetModelHash())
end

---@return boolean
function Vehicle:IsHeli()
    if not self:IsValid() then
        return false
    end

    return VEHICLE.IS_THIS_MODEL_A_HELI(self:GetModelHash())
end

---@return boolean
function Vehicle:IsSubmersible()
    if not self:IsValid() then
        return false
    end

    return VEHICLE.IS_THIS_MODEL_AN_AMPHIBIOUS_CAR(self:GetModelHash())
end

---@return boolean
function Vehicle:IsBicycle()
    if not self:IsValid() then
        return false
    end

    return VEHICLE.IS_THIS_MODEL_A_BICYCLE(self:GetModelHash())
end

---@return boolean
function Vehicle:HasABS()
    return self:GetModelFlag(eVehicleModelFlags.ABS_STD)
end

---@return boolean
function Vehicle:IsSports()
    return self:GetModelInfoFlag(eVehicleModelInfoFlags.SPORTS)
end

---@return boolean
function Vehicle:IsSportsOrSuper()
    if not self:IsValid() then
        return false
    end

    local handle = self:GetHandle()
    return (
        VEHICLE.GET_VEHICLE_CLASS(handle) == 4 or
        VEHICLE.GET_VEHICLE_CLASS(handle) == 6 or
        VEHICLE.GET_VEHICLE_CLASS(handle) == 7 or
        VEHICLE.GET_VEHICLE_CLASS(handle) == 22
    )
end

-- Returns whether the vehicle is a pubic hair shaver.
---@return boolean
function Vehicle:IsElectric()
    return self:GetModelInfoFlag(eVehicleModelInfoFlags.IS_ELECTRIC)
end

-- Returns whether the vehicle is an F1 race car.
function Vehicle:IsFormulaOne()
    return self:GetModelInfoFlag(eVehicleModelInfoFlags.IS_FORMULA_VEHICLE)
        or (self:GetClassID() == eVehicleClasses.OpenWheel)
end

-- Returns whether the vehicle is a lowrider equipped with hydraulic suspension.
function Vehicle:IsLowrider()
    return self:GetModelInfoFlag(eVehicleModelInfoFlags.HAS_LOWRIDER_HYDRAULICS)
        or self:GetModelInfoFlag(eVehicleModelInfoFlags.HAS_LOWRIDER_DONK_HYDRAULICS)
end

function Vehicle:Clean()
    if not self:IsValid() then
        return
    end

    VEHICLE.SET_VEHICLE_DIRT_LEVEL(self:GetHandle(), 0.0)
end

---@param reset_dirt? bool
function Vehicle:Repair(reset_dirt)
    if not self:IsValid() then
        return
    end

    local handle = self:GetHandle()
    VEHICLE.SET_VEHICLE_FIXED(handle)
    VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(handle)

    if (reset_dirt) then
        self:Clean()
    end

    local pWaterDamage = self:Resolve().m_water_damage
    if pWaterDamage:is_null() then
        return
    end

    local damage_bits = pWaterDamage:get_int()
    if (type(damage_bits) == "number") then
        pWaterDamage:set_int(Bit.clear(damage_bits, 0))
    end
end

-- Maximizes the vehicle's performance mods, repairs and cleans it.
function Vehicle:MaxPerformance()
    local handle = self:GetHandle()

    if not self:IsValid()
        or not VEHICLE.IS_VEHICLE_DRIVEABLE(handle, false)
        or not ENTITY.IS_ENTITY_A_VEHICLE(handle) then
        return
    end

    local function SetPlatformAppropriateMod(modType, modIndex)
        if (Backend:GetAPIVersion() == eAPIVersion.V1) then
            while VEHICLE.IS_VEHICLE_MOD_GEN9_EXCLUSIVE(handle, modType, modIndex) do
                modIndex = modIndex - 1
                yield()
            end
        end

        VEHICLE.SET_VEHICLE_MOD(handle, modType, modIndex, false)
    end

    local maxArmor = VEHICLE.GET_NUM_VEHICLE_MODS(handle, 16) - 1
    SetPlatformAppropriateMod(16, maxArmor)

    local maxEngine = VEHICLE.GET_NUM_VEHICLE_MODS(handle, 11) - 1
    SetPlatformAppropriateMod(11, maxEngine)

    local maxBrakes = VEHICLE.GET_NUM_VEHICLE_MODS(handle, 12) - 1
    SetPlatformAppropriateMod(12, maxBrakes)

    local maxTrans = VEHICLE.GET_NUM_VEHICLE_MODS(handle, 13) - 1
    SetPlatformAppropriateMod(13, maxTrans)

    local maxSusp = VEHICLE.GET_NUM_VEHICLE_MODS(handle, 15) - 1
    SetPlatformAppropriateMod(15, maxSusp)

    VEHICLE.TOGGLE_VEHICLE_MOD(handle, 18, true)
    VEHICLE.TOGGLE_VEHICLE_MOD(handle, 22, true)
    self:Repair(true)
end

---@param toggle boolean
function Vehicle:LockDoors(toggle)
    local handle = self:GetHandle()

    if self:IsCar() and entities.take_control_of(handle, 300) then
        if toggle then
            for i = 0, (VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(handle) + 1) do
                if VEHICLE.GET_VEHICLE_DOOR_ANGLE_RATIO(handle, i) > 0.0 then
                    VEHICLE.SET_VEHICLE_DOORS_SHUT(handle, false)
                    break
                end
            end

            if VEHICLE.IS_VEHICLE_A_CONVERTIBLE(handle, false) and VEHICLE.GET_CONVERTIBLE_ROOF_STATE(handle) ~= 0 then
                VEHICLE.RAISE_CONVERTIBLE_ROOF(handle, false)
            else
                for i = 0, 7 do
                    VEHICLE.ROLL_UP_WINDOW(handle, i)
                end
            end
        end

        -- these won't do anything if the engine is off --
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(handle, 0, true)
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(handle, 1, true)
        --------------------------------------------------

        AUDIO.SET_HORN_PERMANENTLY_ON_TIME(handle, 1000)
        AUDIO.SET_HORN_PERMANENTLY_ON(handle)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED(handle, toggle and 2 or 1)
        VEHICLE.SET_VEHICLE_ALARM(handle, toggle)
        sleep(696)
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(handle, 0, false)
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(handle, 1, false)
    end
end

-- Gets the vehicle's acceleration multiplier.
---@return float
function Vehicle:GetAcceleration(multiplier)
    if not self:IsValid() then
        return 0.0
    end

    return self:Resolve():GetAcceleration()
end

-- Sets the vehicle's acceleration multiplier.
---@param multiplier float
function Vehicle:SetAcceleration(multiplier)
    if not (self:IsValid() and (type(multiplier) == "number")) then
        return
    end

    self:Resolve():SetAcceleration(multiplier)
end

-- Gets the vehicle's deformation multiplier.
---@return float|nil
function Vehicle:GetDeformation()
    if not self:IsValid() then
        return
    end

    return self:Resolve():GetDeformMultiplier()
end

-- Sets the vehicle's deformation multiplier.
---@param multiplier float
function Vehicle:SetDeformation(multiplier)
    if not (self:IsValid() and type(multiplier) == "number") then
        return
    end

    self:Resolve():SetDeformMultiplier(multiplier)
end

---@return table
function Vehicle:GetExhaustBones()
    local handle = self:GetHandle()

    if not self:IsValid() then
        return {}
    end

    local bones   = {}
    local count   = VEHICLE.GET_VEHICLE_MAX_EXHAUST_BONE_COUNT_() - 1 -- all vehicles have an additional exhaust bone sticking out of the top of the engine.
    local bParam  = false
    local boneIdx = -1

    for i = 0, count do
        bParam, boneIdx = VEHICLE.GET_VEHICLE_EXHAUST_BONE_(handle, i, boneIdx, bParam)
        if bParam then
            table.insert(bones, boneIdx)
        end
    end

    return bones
end

function Vehicle:GetColors()
    local handle = self:GetHandle()
    local col1 = { r = 0, g = 0, b = 0 }
    local col2 = { r = 0, g = 0, b = 0 }

    if not self:IsValid() then
        return col1, col2
    end

    if VEHICLE.GET_IS_VEHICLE_PRIMARY_COLOUR_CUSTOM(handle) then
        col1.r, col1.g, col1.b = VEHICLE.GET_VEHICLE_CUSTOM_PRIMARY_COLOUR(
            handle,
            col1.r,
            col1.g,
            col1.b
        )
    else
        col1.r, col1.g, col1.b = VEHICLE.GET_VEHICLE_COLOR(
            handle,
            col1.r,
            col1.g,
            col1.b
        )
    end

    if VEHICLE.GET_IS_VEHICLE_SECONDARY_COLOUR_CUSTOM(handle) then
        col2.r, col2.g, col2.b = VEHICLE.GET_VEHICLE_CUSTOM_SECONDARY_COLOUR(
            handle,
            col2.r,
            col2.g,
            col2.b
        )
    else
        col2.r, col2.g, col2.b = VEHICLE.GET_VEHICLE_COLOR(
            handle,
            col2.r,
            col2.g,
            col2.b
        )
    end

    return col1, col2
end

---@return table
function Vehicle:GetCustomWheels()
    if not self:IsValid() then
        return {}
    end

    local handle = self:GetHandle()
    local wheels = {}
    wheels.type  = VEHICLE.GET_VEHICLE_WHEEL_TYPE(handle)
    wheels.index = VEHICLE.GET_VEHICLE_MOD(handle, 23)
    wheels.var   = VEHICLE.GET_VEHICLE_MOD_VARIATION(handle, 23)

    return wheels
end

function Vehicle:SetCustomWheels(tWheelData)
    if not self:IsValid() or not tWheelData then
        return
    end

    local handle = self:GetHandle()

    if tWheelData.type then
        VEHICLE.SET_VEHICLE_WHEEL_TYPE(handle, tWheelData.type)
    end

    if tWheelData.index then
        VEHICLE.SET_VEHICLE_MOD(handle, 23, tWheelData.index, (tWheelData.var and tWheelData.var == 1))
    end
end

---@return table
function Vehicle:GetWindowStates()
    local t = {}

    for i = 1, 4 do
        t[i] = VEHICLE.IS_VEHICLE_WINDOW_INTACT(self:GetHandle(), i - 1)
    end

    return t
end

---@return table
function Vehicle:GetToggleMods()
    local t = {}

    for i = 17, 22 do
        t[i] = VEHICLE.IS_TOGGLE_MOD_ON(self:GetHandle(), i)
    end

    return t
end

---@return table
function Vehicle:GetNeonLights()
    local handle = self:GetHandle()
    local bHasNeonLights = false
    local neon = {
        enabled = {},
        color = { r = 0, g = 0, b = 0 }
    }

    for i = 1, 4 do
        local isEnabled = VEHICLE.GET_VEHICLE_NEON_ENABLED(handle, i - 1)
        neon.enabled[i] = isEnabled
        if isEnabled then
            bHasNeonLights = true
        end
    end

    if bHasNeonLights then
        neon.color.r,
        neon.color.g,
        neon.color.b = VEHICLE.GET_VEHICLE_NEON_COLOUR(
            handle,
            neon.color.r,
            neon.color.g,
            neon.color.b
        )
    end

    return neon
end

---@param tNeonData table
function Vehicle:SetNeonLights(tNeonData)
    if not tNeonData then
        return
    end

    local handle = self:GetHandle()
    for i = 0, 3 do
        VEHICLE.SET_VEHICLE_NEON_ENABLED(handle, i, tNeonData.enabled[i])
    end

    VEHICLE.SET_VEHICLE_NEON_COLOUR(
        handle,
        tNeonData.color.r,
        tNeonData.color.g,
        tNeonData.color.b
    )
end

---@return VehicleMods
function Vehicle:GetMods()
    local handle = self:GetHandle()

    if not self:IsValid() then
        return {}
    end

    local _mods = {}
    for i = 0, 49 do
        table.insert(_mods, VEHICLE.GET_VEHICLE_MOD(handle, i))
    end

    local window_tint = VEHICLE.GET_VEHICLE_WINDOW_TINT(handle)
    local plate_text = VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT(handle)
    local col1, col2 = self:GetColors()
    local wheels = self:GetCustomWheels()

    local struct = VehicleMods.create(
        _mods,
        col1,
        col2,
        wheels,
        window_tint,
        plate_text
    )

    struct.window_states = self:GetWindowStates()
    struct.toggle_mods = self:GetToggleMods()
    struct.neon = self:GetNeonLights()

    if struct.toggle_mods[20] then
        local r, g, b = 0, 0, 0
        r, g, b = VEHICLE.GET_VEHICLE_TYRE_SMOKE_COLOR(handle, r, g, b)
        struct.tyre_smoke_color = { r = r, g = g, b = b }
    end

    if struct.toggle_mods[22] then
        struct.xenon_color = VEHICLE.GET_VEHICLE_XENON_LIGHT_COLOR_INDEX(handle)
    end

    if VEHICLE.GET_VEHICLE_LIVERY_COUNT(handle) > 0 then
        struct.livery = VEHICLE.GET_VEHICLE_LIVERY(handle)
    end

    if VEHICLE.GET_VEHICLE_LIVERY2_COUNT(handle) > 0 then
        struct.livery2 = VEHICLE.GET_VEHICLE_LIVERY2(handle)
    end

    local pInt1, pInt2, pInt3, pInt4 = 0, 0, 0, 0
    struct.pearlescent_color, struct.wheel_color = VEHICLE.GET_VEHICLE_EXTRA_COLOURS(handle, pInt1, pInt2)

    VEHICLE.GET_VEHICLE_EXTRA_COLOUR_5(handle, pInt3)
    VEHICLE.GET_VEHICLE_EXTRA_COLOUR_6(handle, pInt4)
    struct.interior_color = pInt3
    struct.dashboard_color = pInt4

    return struct
end

---@param modType number
---@param index number
---@return boolean
function Vehicle:PreloadMod(modType, index)
    local handle = self:GetHandle()
    if not self:IsValid() then
        return false
    end

    VEHICLE.PRELOAD_VEHICLE_MOD(handle, modType, index)
    while not VEHICLE.HAS_PRELOAD_MODS_FINISHED(handle) do
        yield()
    end
    return VEHICLE.HAS_PRELOAD_MODS_FINISHED(handle)
end

---@param tModData VehicleMods
function Vehicle:ApplyMods(tModData)
    local handle = self:GetHandle()
    if not self:IsValid() then
        print("invalid")
        return
    end

    ThreadManager:RunInFiber(function()
        VEHICLE.SET_VEHICLE_MOD_KIT(handle, 0)

        if tModData.mods then
            for slot, mod in ipairs(tModData.mods) do
                if (mod ~= -1 and self:PreloadMod((slot - 1), mod)) then
                    VEHICLE.SET_VEHICLE_MOD(handle, (slot - 1), mod, true)
                end
            end
            VEHICLE.RELEASE_PRELOAD_MODS(handle)
        end

        if tModData.primary_color then
            VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(
                handle,
                tModData.primary_color.r,
                tModData.primary_color.g,
                tModData.primary_color.b
            )
        end

        if tModData.secondary_color then
            VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(
                handle,
                tModData.secondary_color.r,
                tModData.secondary_color.g,
                tModData.secondary_color.b
            )
        end

        if tModData.window_tint then
            VEHICLE.SET_VEHICLE_WINDOW_TINT(handle, tModData.window_tint)
        end

        if tModData.toggle_mods then
            for i = 17, 22 do
                VEHICLE.TOGGLE_VEHICLE_MOD(handle, i, tModData.toggle_mods[i])
            end

            if tModData.toggle_mods[20] then
                local col = tModData.tyre_smoke_color
                if col and col.r and col.g and col.b then
                    VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(handle, col.r, col.g, col.b)
                end
            end

            if tModData.toggle_mods[22] and tModData.xenon_color then
                VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(handle, tModData.xenon_color)
            end
        end

        if tModData.window_states then
            for i = 1, #tModData.window_states do
                local callback = tModData.window_states[i] and VEHICLE.ROLL_UP_WINDOW or VEHICLE.ROLL_DOWN_WINDOW
                callback(handle, i - 1)
            end
        end

        if tModData.plate_text and type(tModData.plate_text) == "string" and #tModData.plate_text > 0 then
            VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(handle, tModData.plate_text)
        end

        if tModData.livery then
            VEHICLE.SET_VEHICLE_LIVERY(handle, tModData.livery)
        end

        if tModData.livery2 then
            VEHICLE.SET_VEHICLE_LIVERY2(handle, tModData.livery2)
        end

        if tModData.wheels then
            self:SetCustomWheels(tModData.wheels)
        end

        if tModData.pearlescent_color and tModData.wheel_color then
            VEHICLE.SET_VEHICLE_EXTRA_COLOURS(handle, tModData.pearlescent_color, tModData.wheel_color)
        end

        if tModData.interior_color then
            VEHICLE.SET_VEHICLE_EXTRA_COLOUR_5(handle, tModData.interior_color)
        end

        if tModData.dashboard_color then
            VEHICLE.SET_VEHICLE_EXTRA_COLOUR_6(handle, tModData.dashboard_color)
        end

        if tModData.neon then
            self:SetNeonLights(tModData.neon)
        end
    end)
end

---@param opts? { spawn_pos?: vec3, warp_into?: boolean }
function Vehicle:Clone(opts)
    if not self:IsValid() then
        return
    end

    opts = opts or {}
    local pos = opts.spawn_pos or self:GetSpawnPosInFront()
    local clone = Vehicle:Create(self:GetModelHash(), eEntityType.Vehicle, pos)
    local tModData = self:GetMods()

    if clone:IsValid() then
        if next(tModData) ~= nil then
            clone:ApplyMods(tModData)
        end

        clone:SetAsNoLongerNeeded()
        if (opts.warp_into == true) then -- Some idiot passed a vector3 and kept wondering why they were being teleported into the vehicle. Don't ask who the idiot is.
            clone:WarpPed(Self:GetHandle(), -1)
        end
    end

    return clone
end

---@param ped_handle number
---@param seatIndex? number
function Vehicle:WarpPed(ped_handle, seatIndex)
    if not (self:IsValid() or ENTITY.DOES_ENTITY_EXIST(ped_handle)) then
        return
    end

    seatIndex = seatIndex or -1
    if not self:IsSeatFree(seatIndex, true) then
        seatIndex = -2
    end

    PED.SET_PED_INTO_VEHICLE(ped_handle, self:GetHandle(), seatIndex)
end

---@param step integer 1 next seat|-1 previous seat
function Vehicle:ShuffleSeats(step)
    ThreadManager:RunInFiber(function()
        if not self:IsLocalPlayerInVehicle() then
            return
        end

        if not self:IsAnySeatFree() then
            return
        end

        local maxSeats = self:GetNumberOfPassengers()
        local currentSeat = Self:GetVehicleSeat()

        if (not currentSeat or maxSeats == 0) then
            return
        end

        local attempts  = 0
        local seatIndex = currentSeat

        while attempts < maxSeats do
            seatIndex = seatIndex + step

            if seatIndex > maxSeats then
                seatIndex = 1
            elseif seatIndex < 1 then
                seatIndex = maxSeats
            end

            if self:IsSeatFree(seatIndex) then
                PED.SET_PED_INTO_VEHICLE(Self:GetHandle(), self:GetHandle(), seatIndex)
                return
            end

            attempts = attempts + 1
            yield()
        end
    end)
end

-- Must be called on tick. If you want a one-shot thing, use `Vehicle:SetAcceleration` instead.
---@param value number speed modifier
function Vehicle:ModifyTopSpeed(value)
    if not Self:IsValid() then
        return
    end

    VEHICLE.MODIFY_VEHICLE_TOP_SPEED(self:GetHandle(), value)
end

-- Returns whether a handling flag is enabled.
---@param flag eVehicleHandlingFlags
---@return boolean
function Vehicle:GetHandlingFlag(flag)
    if not self:IsValid() then
        return false
    end

    return self:Resolve():GetHandlingFlag(flag)
end

-- Enables/disables a vehicle's handling flag.
---@param flag eVehicleHandlingFlags
---@param toggle boolean
function Vehicle:SetHandlingFlag(flag, toggle)
    if not self:IsValid() then
        return
    end

    self:Resolve():SetHandlingFlag(flag, toggle)
end

-- Returns whether a model flag is enabled.
---@param flag eVehicleModelFlags
function Vehicle:GetModelFlag(flag)
    if not self:IsValid() then
        return false
    end

    return self:Resolve():GetModelFlag(flag)
end

-- Returns whether a model info flag is enabled **(not the same as model flags)**.
---@param flag eVehicleModelInfoFlags
---@return boolean
function Vehicle:GetModelInfoFlag(flag)
    if not self:IsValid() then
        return false
    end

    return self:Resolve():GetModelInfoFlag(flag)
end

-- Enables/disables a vehicle's model info flag.
---@param flag eVehicleModelInfoFlags
---@param toggle boolean
function Vehicle:SetModelInfoFlag(flag, toggle)
    if not self:IsValid() then
        return
    end

    self:Resolve():SetModelInfoFlag(flag, toggle)
end

-- Returns whether an advanced flag is enabled.
---@param flag eVehicleAdvancedFlags
---@return boolean
function Vehicle:GetAdvancedFlag(flag)
    if not self:IsValid() then
        return false
    end

    return self:Resolve():GetAdvancedFlag(flag)
end

-- Enables/disables a vehicle's advanced flag.
---@param flag eVehicleAdvancedFlags
---@param toggle boolean
function Vehicle:SetAdvancedFlag(flag, toggle)
    if not self:IsValid() then
        return
    end

    self:Resolve():SetAdvancedFlag(flag, toggle)
end

---@param bone_index number
---@return fMatrix44
function Vehicle:GetBoneMatrix(bone_index)
    if not self:IsValid() then
        return fMatrix44:zero()
    end

    return self:Resolve():GetBoneMatrix(bone_index)
end

---@param bone_index number
---@param matrix fMatrix44
function Vehicle:SetBoneMatrix(bone_index, matrix)
    if not self:IsValid() then
        return
    end

    self:Resolve():SetBoneMatrix(bone_index, matrix)
end

---@return CCarHandlingData|nil
function Vehicle:GetHandlingData()
    if not (self:IsValid() and self:IsCar()) then
        return
    end

    return self:Resolve():GetCarHandlingData()
end

-- Serializes a vehicle to JSON.
--
-- If a file name isn't provided, the vehicle's name will be used.
---@param name? string
function Vehicle:SaveToJSON(name)
    if not self:IsValid() then
        return
    end

    if (not name or string.isnullorwhitespace(name)) then
        name = self:GetName()
    end

    name = name:gsub("%.[^%.]+$", "")
    local filename = GenerateUniqueFilename(name, ".json")
    local modelhash = self:GetModelHash()
    local mods = self:GetMods()
    local t = {
        model_hash = modelhash,
        mods = mods
    }

    Serializer:WriteToFile(t, filename)
    self:notify("Saved vehicle to '%s'", filename)
end

-- Static Method.
--
-- Spawns a vehicle from JSON and returns a new `Vehicle` instance.
---@param filename string
---@param warp_into? boolean
function Vehicle.CreateFromJSON(filename, warp_into)
    if (type(filename) ~= "string") then
        Toast:ShowError("Vehicle", "Failed to read vehicle data from JSON: Invalid filename.", true)
        return
    end

    if not filename:endswith(".json") then
        filename = filename .. ".json"
    end

    local data = Serializer:ReadFromFile(filename)
    if (type(data) ~= "table") then
        Toast:ShowError("Vehicle", "Failed to read vehicle data from JSON. Unable to read file", true)
        return
    end

    local modelhash = data.model_hash
    if not Game.EnsureModelHash(modelhash) then
        Toast:ShowError("Vehicle", "Failed to create vehicle from JSON: Invalid model hash.", true)
        return
    end

    local entity   = Self:GetVehicle() ~= nil and Self:GetVehicle() or Self
    local spawnpos = entity:GetSpawnPosInFront()
    local new_veh  = Vehicle:Create(modelhash, eEntityType.Vehicle, spawnpos, Self:GetHeading())
    if (new_veh:IsValid() and type(data.mods) == "table") then
        new_veh:ApplyMods(data.mods)
    end

    if (warp_into == true) then
        new_veh:WarpPed(Self:GetHandle())
    end

    return new_veh
end

-------------------------
-- Struct: VehicleMods 
-------------------------
---@ignore
---@class VehicleMods
---@field mods table<integer, integer>
---@field toggle_mods table<integer, boolean>
---@field primary_color table<string, integer>
---@field secondary_color table<string, integer>
---@field window_tint number
---@field plate_text string
---@field window_states table<integer, boolean>
---@field wheels { index: integer, type: integer, var?: integer }
---@field xenon_color? number
---@field livery? number
---@field livery2? number
---@field pearlescent_color? number
---@field wheel_color? number
---@field interior_color? number
---@field dashboard_color? number
---@field tyre_smoke_color? { r: number, g: number, b: number }
---@field neon? { enabled: table<integer, boolean>, color: { r: number, g: number, b: number } }
VehicleMods = {}

---@param mods table
---@param primary_color table
---@param secondary_color table
---@param wheels table
---@param window_tint number
---@param plate_text? string
function VehicleMods.create(mods, primary_color, secondary_color, wheels, window_tint, plate_text)
    return {
        mods = mods,
        primary_color = primary_color,
        secondary_color = secondary_color,
        wheels = wheels,
        window_tint = window_tint,
        plate_text = plate_text or "SSV2"
    }
end
