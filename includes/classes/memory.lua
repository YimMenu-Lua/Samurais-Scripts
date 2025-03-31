---@class Memory
Memory = {}
Memory.__index = Memory

Memory.GetGameVersion = function()
    local pVers = memory.scan_pattern("8B C3 33 D2 C6 44 24 20")
    local pBnum = pVers:add(0x24):rip()
    local pOver = pBnum:add(0x20)
    local ret = {
        _build  = pBnum:get_string(),
        _online = pOver:get_string()
    }
    return ret
end

Memory.GetScreenResolution = function()
    local SR = vec2:new(0, 0)
    local pScreenResolution = memory.scan_pattern("66 0F 6E 0D ? ? ? ? 0F B7 3D")

    if pScreenResolution:is_valid() then
        SR.x = pScreenResolution:sub(0x4):rip():get_word()
        SR.y = pScreenResolution:add(0x4):rip():get_word()
    end
    return SR
end

-- Reads localPlayer's vehicle information from memory.
Memory.GetVehicleInfo = function(vehicle)
    if (
        not ENTITY.DOES_ENTITY_EXIST(vehicle) or
        not ENTITY.IS_ENTITY_A_VEHICLE(vehicle) or
        not entities.take_control_of(vehicle, 500)
    ) then
        return
    end

    local vehPtr = memory.handle_to_ptr(vehicle)
    ---@class CVehicle
    local CVehicle = setmetatable({}, {})
    CVehicle.__index = CVehicle
    if vehPtr:is_valid() then
        local CHandlingData          = vehPtr:add(0x0960):deref()
        local CVehicleModelInfo      = vehPtr:add(0x20):deref()
        local CVehicleDamage         = vehPtr:add(0x0420)
        local CDeformation           = CVehicleDamage:add(0x0010)
        CVehicle.m_model_info_flags  = CVehicleModelInfo:add(0x057C)
        CVehicle.m_acceleration      = CHandlingData:add(0x004C)
        CVehicle.m_model_flags       = CHandlingData:add(0x0124)
        CVehicle.m_handling_flags    = CHandlingData:add(0x0128)
        CVehicle.m_deformation_mult  = CHandlingData:add(0x00F8)
        CVehicle.m_sub_handling_data = CHandlingData:add(0x158):deref()
        CVehicle.m_deformation       = CDeformation:add(0x0000)
        CVehicle.m_deform_god        = vehPtr:add(0x096C)
    end
    return CVehicle
end

-- Checks if a vehicle's handling flag is set.
---@param vehicle number
---@param flag number
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

---@param vehicle integer
---@param flag integer
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
    local base_ptr = Memory.GetVehicleInfo(vehicle).m_model_info_flags
    if base_ptr:is_valid() then
        local index    = math.floor(flag / 32)
        local bitPos   = flag % 32
        local flag_ptr = base_ptr:add(index * 4)
        local dword    = flag_ptr:get_dword()
        return Lua_fn.has_bit(dword, bitPos)
    end
end

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
    local base_ptr  = Memory.GetVehicleInfo(vehicle).m_model_info_flags
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

---@unused
---@param dword integer
Memory.SetWeaponEffectGroup = function(dword)
    local pedPtr = memory.handle_to_ptr(Self.GetPedID())
    if pedPtr:is_valid() then
        local CPedWeaponManager = pedPtr:add(0x10B8):deref()
        local CWeaponInfo       = CPedWeaponManager:add(0x0020):deref()
        local sWeaponFx         = CWeaponInfo:add(0x0170)
        local eEffectGroup      = sWeaponFx:add(0x00) -- int32_t
        eEffectGroup:set_dword(dword)
    end
end

-- Returns the model type of an entity (ped, object, vehicle, MLO, time, etc...)
---@param entity integer
Memory.GetEntityType = function(entity)
    if ENTITY.DOES_ENTITY_EXIST(entity) then
        local entPtr = memory.handle_to_ptr(entity)
        if entPtr:is_valid() then
            local m_model_info = entPtr:add(0x0020):deref()
            local m_model_type = m_model_info:add(0x009D)
            return m_model_type:get_word()
        end
    end
    return 0
end

-- Reads information about the player from memory.
--
-- **Note:** param `ped` is a Ped ID, not a Player ID.
---@param ped integer
Memory.GetPlayerInfo = function(ped)
    local pedPtr = memory.handle_to_ptr(ped)
    if pedPtr:is_valid() then
        ---@class CPed
        local CPed            = setmetatable({}, {})
        CPed.__index          = CPed
        local CPlayerInfo     = pedPtr:add(0x10A8):deref()
        local m_ped_type      = pedPtr:add(0x1098)            -- uint32_t
        local m_ped_task_flag = pedPtr:add(0x144B)            -- uint8_t
        local m_seatbelt      = pedPtr:add(0x143C):get_word() -- uint8_t

        CPed.ped_type         = m_ped_type:get_dword()
        CPed.task_flag        = m_ped_task_flag:get_word()
        CPed.swim_speed_ptr   = CPlayerInfo:add(0x01C8)
        CPed.run_speed_ptr    = CPlayerInfo:add(0x0D50)
        CPed.velocity_ptr     = CPlayerInfo:add(0x0300) -- rage::fvector3

        CPed.canPedRagdoll    = function()
            return (CPed.ped_type & 0x20) ~= 0
        end;

        CPed.hasSeatbelt      = function()
            return (m_seatbelt & 0x3) ~= 0
        end;

        CPed.getGameState     = function()
            local m_game_state = CPlayerInfo:add(0x0230):get_dword()
            return eGameState[m_game_state + 2]
        end;

        return CPed
    end
end
