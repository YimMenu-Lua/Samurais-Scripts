---@class Memory
Memory = {}
Memory.__index = Memory

---@param ptr pointer
---@param size integer
Memory.Dump = function(ptr, size)
    size = size or 4
    local result = {}

    for i = 0, size - 1 do
        local byte = ptr:add(i):get_byte()
        table.insert(result, string.format("%02X", byte))
    end

    log.debug("Memory Dump: " .. table.concat(result, " "))
end

---@param ptr pointer
---@return vec3
Memory.GetVec3 = function(ptr)
    if ptr:is_null() then
        return vec3:zero()
    end

    return vec3:new(
        ptr:get_float(),
        ptr:add(0x4):get_float(),
        ptr:add(0x8):get_float()
    )
end

---@return table
Memory.GetGameVersion = function()
    local pGameVersion = memory.scan_pattern("8B C3 33 D2 C6 44 24 20")
    if pGameVersion:is_null() then
        log.warning("Failed to find pattern (Game Version)")
        return {_build = "nil", _online = "nil"}
    end

    local pGameBuild = pGameVersion:add(0x24):rip()
    local pOnlineVersion = pGameBuild:add(0x20)
    return {
        _build  = pGameBuild:get_string(),
        _online = pOnlineVersion:get_string()
    }
end


---@return vec2
Memory.GetScreenResolution = function()
    local pScreenResolution = memory.scan_pattern("66 0F 6E 0D ? ? ? ? 0F B7 3D")

    if pScreenResolution:is_null() then
        log.warning("Failed to find pattern (Screen Resolution)")
        return vec2:new(0, 0)
    end

    return vec2:new(
        pScreenResolution:sub(0x4):rip():get_word(),
        pScreenResolution:add(0x4):rip():get_word()
    )
end

-- Reads localPlayer's vehicle information from memory.
---@return CVehicle | nil
Memory.GetVehicleInfo = function(vehicle)
    if (
        not ENTITY.DOES_ENTITY_EXIST(vehicle) or
        not ENTITY.IS_ENTITY_A_VEHICLE(vehicle)
    ) then
        return
    end

    ---@class CVehicle
    local CVehicle = {}
    CVehicle.__index = CVehicle

    local pEntity = memory.handle_to_ptr(vehicle)
    if pEntity:is_valid() then
        CVehicle.CHandlingData           = pEntity:add(0x0960):deref() -- `class`
        CVehicle.CVehicleModelInfo       = pEntity:add(0x20):deref() -- `class`
        CVehicle.CVehicleDamage          = pEntity:add(0x0420) -- `class`
        CVehicle.CBaseSubHandlingData    = CVehicle.CHandlingData:add(0x158):deref() -- `rage::atArray`
        CVehicle.CVehicleModelInfoLayout = CVehicle.CVehicleModelInfo:add(0x00B0):deref() -- `class`

        CVehicle.m_vehicle_model_flags        = CVehicle.CVehicleModelInfo:add(0x057C)
        CVehicle.m_initial_drag_coeff         = CVehicle.CHandlingData:add(0x0010) -- `float`
        CVehicle.m_drive_bias_rear            = CVehicle.CHandlingData:add(0x0044) -- `float`
        CVehicle.m_drive_bias_front           = CVehicle.CHandlingData:add(0x0048) -- `float`
        CVehicle.m_acceleration               = CVehicle.CHandlingData:add(0x004C) -- `float`
        CVehicle.m_initial_drive_gears        = CVehicle.CHandlingData:add(0x0050) -- `uint8_t`
        CVehicle.m_initial_drive_force        = CVehicle.CHandlingData:add(0x0060) -- `float`
        CVehicle.m_drive_max_flat_velocity    = CVehicle.CHandlingData:add(0x0064) -- `float`
        CVehicle.m_initial_drive_max_flat_vel = CVehicle.CHandlingData:add(0x0068) -- `float`
        CVehicle.m_monetary_value             = CVehicle.CHandlingData:add(0x0118) -- `uint32_t`
        CVehicle.m_model_flags                = CVehicle.CHandlingData:add(0x0124) -- `uint32_t`
        CVehicle.m_handling_flags             = CVehicle.CHandlingData:add(0x0128) -- `uint32_t`
        CVehicle.m_damage_flags               = CVehicle.CHandlingData:add(0x012C) -- `uint32_t`
        CVehicle.m_deformation_mult           = CVehicle.CHandlingData:add(0x00F8) -- `float`
        CVehicle.m_deform_god                 = pEntity:add(0x096C)
    end
    return CVehicle
end

-- Checks if a vehicle's handling flag is set.
---@param vehicle number
---@param flag number
---@return boolean | nil
Memory.GetVehicleHandlingFlag = function(vehicle, flag)
    if (
        not ENTITY.DOES_ENTITY_EXIST(vehicle) or not
        ENTITY.IS_ENTITY_A_VEHICLE(vehicle)
    ) then
        return
    end

    local m_handling_flags = Memory.GetVehicleInfo(vehicle).m_handling_flags
    if m_handling_flags:is_valid() then
        return Lua_fn.has_bit(m_handling_flags:get_dword(), flag)
    end
end

---@param vehicle integer
---@param flag integer
---@return boolean | nil
Memory.GetVehicleModelFlag = function(vehicle, flag)
    if (
        not ENTITY.DOES_ENTITY_EXIST(vehicle) or not
        ENTITY.IS_ENTITY_A_VEHICLE(vehicle)
    ) then
        return
    end

    -- array of 7 uint32_t (7 * 32 = 224 flags total).
    --
    -- Outdated ref: https://gtamods.com/wiki/Vehicles.meta
    local base_ptr = Memory.GetVehicleInfo(vehicle).m_vehicle_model_flags
    if base_ptr:is_valid() then
        local index    = math.floor(flag / 32)
        local bitPos   = flag % 32
        local flag_ptr = base_ptr:add(index * 4)
        local dword    = flag_ptr:get_dword()
        return Lua_fn.has_bit(dword, bitPos)
    end
end

-- ### Unsafe for non-scripted entities.
--______________________________________
--
-- Returns the model type of an entity (ped, object, vehicle, MLO, time, etc...)
---@param entity integer
---@return number
Memory.GetEntityType = function(entity)
    if not ENTITY.DOES_ENTITY_EXIST(entity) then
        return 0
    end

    local b_IsMemSafe, i_EntityType = pcall(function()
        local pEntity = memory.handle_to_ptr(entity)

        if pEntity:is_valid() then
            local m_model_info = pEntity:add(0x0020):deref()
            local m_model_type = m_model_info:add(0x009D)

            return m_model_type:get_word()
        end
        return 0
    end)

    return b_IsMemSafe and i_EntityType or 0
end

-- Reads information about the player from memory.
---@param ped integer A Ped ID, not a Player ID.
---@return CPed | nil
Memory.GetPlayerInfo = function(ped)
    if not ped or not ENTITY.IS_ENTITY_A_PED(ped) then
        return
    end

    local pEntity = memory.handle_to_ptr(ped)
    if pEntity:is_valid() then
        ---@class CPed
        local CPed = {}
        CPed.__index = CPed

        CPed.CPedIntelligence  = pEntity:add(0x10A0):deref() -- `class`
        CPed.CPlayerInfo       = pEntity:add(0x10A8):deref() -- `class`
        CPed.CPedInventory     = pEntity:add(0x10B0):deref() -- `class`
        CPed.CPedWeaponManager = pEntity:add(0x10B0):deref() -- `class`

        CPed.m_velocity        = pEntity:add(0x0300) -- `rage::fvector3`
        CPed.m_ped_type        = pEntity:add(0x1098) -- `uint32_t`
        CPed.m_ped_task_flag   = pEntity:add(0x144B) -- `uint8_t`
        CPed.m_seatbelt        = pEntity:add(0x143C) -- `uint8_t`
        CPed.m_armor           = pEntity:add(0x150C) -- `float`

        CPed.m_swim_speed           = CPed.CPlayerInfo:add(0x01C8) -- `float`
        CPed.m_is_wanted            = CPed.CPlayerInfo:add(0x08E0) -- `boolean`
        CPed.m_wanted_level         = CPed.CPlayerInfo:add(0x08E8) -- `uint32_t`
        CPed.m_wanted_level_display = CPed.CPlayerInfo:add(0x08EC) -- `uint32_t`
        CPed.m_run_speed            = CPed.CPlayerInfo:add(0x0D50) -- `float`
        CPed.m_stamina              = CPed.CPlayerInfo:add(0x0D54) -- `float`
        CPed.m_stamina_regen        = CPed.CPlayerInfo:add(0x0D58) -- `float`
        CPed.m_weapon_damage_mult   = CPed.CPlayerInfo:add(0x0D6C) -- `float`
        CPed.m_weapon_defence_mult  = CPed.CPlayerInfo:add(0x0D70) -- `float`

        ---@return boolean
        CPed.CanPedRagdoll    = function()
            return (CPed.m_ped_type:get_dword() & 0x20) ~= 0
        end;

        ---@return boolean
        CPed.HasSeatbelt      = function()
            return (CPed.m_seatbelt:get_word() & 0x3) ~= 0
        end;

        ---@return string
        CPed.GetGameState     = function()
            local m_game_state = CPed.CPlayerInfo:add(0x0230):get_dword()
            return eGameState[m_game_state + 2]
        end;

        return CPed
    end
end

-- Enables or disables a vehicle's handling flag.
---@param vehicle number
---@param flag number
---@param toggle boolean
Memory.SetVehicleHandlingFlag = function(vehicle, flag, toggle)
    if (
        not VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(vehicle)) and not
        VEHICLE.IS_THIS_MODEL_A_BIKE(ENTITY.GET_ENTITY_MODEL(vehicle)) and not
        VEHICLE.IS_THIS_MODEL_A_QUADBIKE(ENTITY.GET_ENTITY_MODEL(vehicle))
    ) then
        return
    end

    local m_handling_flags = Memory.GetVehicleInfo(vehicle).m_handling_flags
    if m_handling_flags:is_valid() then
        local handling_flags = m_handling_flags:get_dword()
        local bitwiseOp      = toggle and Lua_fn.set_bit or Lua_fn.clear_bit
        local new_flag       = bitwiseOp(handling_flags, flag)
        m_handling_flags:set_dword(new_flag)
    end
end

-- Enables or disables a vehicle's model flag.
---@param vehicle integer
---@param flag integer
---@param toggle boolean
Memory.SetVehicleModelFlag = function(vehicle, flag, toggle)
    if (
        not ENTITY.DOES_ENTITY_EXIST(vehicle) or not
        ENTITY.IS_ENTITY_A_VEHICLE(vehicle)
    ) then
        return
    end
    local base_ptr  = Memory.GetVehicleInfo(vehicle).m_vehicle_model_flags
    if base_ptr:is_valid() then
        local index    = math.floor(flag / 32)
        local bitPos   = flag % 32
        local flag_ptr = base_ptr:add(index * 4)
        if flag_ptr:is_valid() then
            local dword     = flag_ptr:get_dword()
            local bitwiseOp = toggle and Lua_fn.set_bit or Lua_fn.clear_bit
            local new_flag  = bitwiseOp(dword, bitPos)
            flag_ptr:set_dword(new_flag)
        end
    end
end


---@param value number
Memory.ModifyVehicleTopSpeed = function(value)
    if self.get_veh() == 0 then
        return
    end

    if not Self.Vehicle.DefaultHandling then
        local CVehicle = Memory.GetVehicleInfo(self.get_veh())

        if CVehicle then
            Self.Vehicle.DefaultHandling = {
                f_AccelerationMultiplier = CVehicle.m_acceleration:get_float(),
                f_InitialDragCoeff       = CVehicle.m_initial_drag_coeff:get_float(),
                f_InitialDriveForce      = CVehicle.m_initial_drive_force:get_float(),
                f_DriveMaxFlatVel        = CVehicle.m_drive_max_flat_velocity:get_float(),
                f_InitialDriveMaxFlatVel = CVehicle.m_initial_drive_max_flat_vel:get_float()
            }

            local _origin = Self.Vehicle.DefaultHandling
            local modifier = (value + 100) * 0.01
            CVehicle.m_acceleration:set_float(modifier)

            local f_InitialDragCoeff = _origin.f_InitialDragCoeff
            f_InitialDragCoeff = f_InitialDragCoeff / modifier

            if f_InitialDragCoeff and f_InitialDragCoeff > 0.0 then
                CVehicle.m_initial_drag_coeff:set_float(f_InitialDragCoeff)
            end

            local f_InitialDriveForce = _origin.f_InitialDriveForce
            f_InitialDriveForce = f_InitialDriveForce * modifier

            if f_InitialDriveForce and f_InitialDriveForce > 0.0 then
                CVehicle.m_initial_drive_force:set_float(f_InitialDriveForce)
            end

            local f_DriveMaxFlatVel = _origin.f_DriveMaxFlatVel
            f_DriveMaxFlatVel = f_DriveMaxFlatVel * modifier

            if f_DriveMaxFlatVel and f_DriveMaxFlatVel > 0.0 then
                CVehicle.m_drive_max_flat_velocity:set_float(f_DriveMaxFlatVel)
            end

            local f_InitialDriveMaxFlatVel =  _origin.f_InitialDriveMaxFlatVel
            f_InitialDriveMaxFlatVel = f_InitialDriveMaxFlatVel * modifier

            if f_InitialDriveMaxFlatVel and f_InitialDriveMaxFlatVel > 0.0 then
                CVehicle.m_initial_drive_max_flat_vel:set_float(f_DriveMaxFlatVel)
            end
        end
    end
end

--[[
---@unused
---@param dword integer
Memory.SetWeaponEffectGroup = function(dword)
    local pedPtr = memory.handle_to_ptr(self.get_ped())
    if pedPtr:is_valid() then
        local CPedWeaponManager = pedPtr:add(0x10B8):deref()
        local CWeaponInfo       = CPedWeaponManager:add(0x0020):deref()
        local sWeaponFx         = CWeaponInfo:add(0x0170)
        local eEffectGroup      = sWeaponFx:add(0x00) -- int32_t
        eEffectGroup:set_dword(dword)
    end
end
--]]
