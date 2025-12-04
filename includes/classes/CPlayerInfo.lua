---@diagnostic disable: param-type-mismatch

--------------------------------------
-- Class: CPlayerInfo
--------------------------------------
---@ignore
---@class CPlayerInfo
---@field private m_ptr pointer
---@field m_swim_speed pointer<float>
---@field m_game_state pointer<uint32_t>
---@field m_is_wanted pointer<byte> bool
---@field m_wanted_level pointer<uint32_t>
---@field m_wanted_level_display pointer<uint32_t>
---@field m_run_speed pointer<float>
---@field m_stamina pointer<float>
---@field m_stamina_regen pointer<float>
---@field m_weapon_damage_mult pointer<float>
---@field m_weapon_defence_mult pointer<float> // 0x0D70
---@overload fun(ptr: pointer): CPlayerInfo|nil
CPlayerInfo = { m_size = 0x0D78 }
CPlayerInfo.__index = CPlayerInfo
setmetatable(CPlayerInfo, {
    __call = function(cls, ptr)
        return cls.new(ptr)
    end,
})

---@param ptr pointer
---@return CPlayerInfo
function CPlayerInfo.new(ptr)
    if not ptr or ptr:is_null() then
        error("Invalid ped pointer!")
    end

    local instance = setmetatable({}, CPlayerInfo)

    instance.m_ptr = ptr
    instance.m_swim_speed = ptr:add(0x01C8)
    instance.m_game_state = ptr:add(0x0230)
    instance.m_is_wanted = ptr:add(0x08E0)
    instance.m_wanted_level = ptr:add(0x08E8)
    instance.m_wanted_level_display = ptr:add(0x08EC)
    instance.m_run_speed = ptr:add(0x0D50)
    instance.m_stamina = ptr:add(0x0D54)
    instance.m_stamina_regen = ptr:add(0x0D58)
    instance.m_weapon_damage_mult = ptr:add(0x0D6C)
    instance.m_weapon_defence_mult = ptr:add(0x0D70)

    return instance
end

---@return boolean
function CPlayerInfo:IsValid()
    return self.m_ptr and self.m_ptr:is_valid()
end

---@return eGameState
function CPlayerInfo:GetGameState()
    return self.m_game_state:get_int()
end
