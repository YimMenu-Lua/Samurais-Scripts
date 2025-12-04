---@diagnostic disable: param-type-mismatch

---@class CPedIntelligence
---@class CPedInventory
---@class CPedWeaponManager

--------------------------------------
-- Class: CPed
--------------------------------------
---@ignore
---@class CPed : CEntity
---@field private m_ptr pointer
---@field m_ped_intelligence pointer<CPedIntelligence>
---@field m_ped_inventory pointer<CPedInventory>
---@field m_ped_weapon_mgr pointer<CPedWeaponManager>
---@field m_player_info? CPlayerInfo
---@field m_velocity pointer<vec3>
---@field m_ped_type pointer<uint8_t>
---@field m_ped_task_flag pointer<uint8_t>
---@field m_seatbelt pointer<uint8_t>
---@field m_armor pointer<float>
---@field m_cash pointer<uint16_t> // 0x1614
---@overload fun(ped: handle): CPed
CPed = Class("CPed", CEntity, 0x161C)

---@param ped handle
---@return CPed
function CPed:init(ped)
    if not ENTITY.DOES_ENTITY_EXIST(ped) or not ENTITY.IS_ENTITY_A_PED(ped) then
        error("Invalid entity!")
    end

    self:super().init(self, ped)
    local ptr = memory.handle_to_ptr(ped)

    ---@type CPed
    local instance = setmetatable({}, CPed)
    instance.m_ptr = ptr
    instance.m_ped_intelligence = ptr:add(0x10A0)
    instance.m_ped_inventory = ptr:add(0x10B0)
    instance.m_ped_weapon_mgr = ptr:add(0x10B8)
    instance.m_velocity = ptr:add(0x0300)
    instance.m_ped_type = ptr:add(0x1098)
    instance.m_ped_task_flag = ptr:add(0x144B)
    instance.m_seatbelt = ptr:add(0x143C)
    instance.m_armor = ptr:add(0x150C)
    instance.m_cash = ptr:add(0x1614)

    if (PED.IS_PED_A_PLAYER(ped)) then
        instance.m_player_info = CPlayerInfo(ptr:add(0x10A8):deref())
    end

    return instance
end

---@return boolean
function CPed:CanRagdoll()
    if not self:IsValid() then
        return false
    end

    return (self.m_ped_type & 0x20) ~= 0
end

---@return boolean
function CPed:HasSeatbelt()
    if not self:IsValid() then
        return false
    end

    return (self.m_seatbelt & 0x3) ~= 0
end

---@return float
function CPed:GetSpeed()
    if not self:IsValid() then
        return 0.0
    end

    local speed_vec = self.m_velocity:get_vec3()
    return speed_vec:mag()
end

---@return ePedType
function CPed:GetPedType()
   return (self.m_ped_type:get_word() << 11 >> 25)
end
