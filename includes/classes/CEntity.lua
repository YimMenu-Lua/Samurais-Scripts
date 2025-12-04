---@diagnostic disable: param-type-mismatch

---@ignore
---@class CBaseModelInfo : GenericClass
local CBaseModelInfo = GenericClass

---@ignore
---@class CAttackers : GenericClass
local CAttackers = GenericClass

--------------------------------------
-- Class: CEntity
--------------------------------------
---@ignore
---@class CEntity: ClassMeta<CEntity>
---@field private m_ptr pointer
---@field m_model_info pointer<CBaseModelInfo> // 0x0020
---@field m_entity_type uint8_t // 0x0028
---@field m_model_type pointer<uint8_t> // CBaseModelInfo + 0x009D
---@field m_flags pointer<uint32_t> // 0x002D
---@field m_transform_matrix pointer<fMatrix44> // 0x0060
---@field m_render_focus_distance pointer<uint32_t> // 0x00A8
---@field m_shadow_flags pointer<uint32_t> // 0x00B0
---@field m_damage_bits pointer<uint32_t> // 0x0188
---@field m_hostility pointer<uint8_t> // 0x018C
---@field m_health pointer<float> // 0x0280
---@field m_max_health pointer<float> // 0x0284
---@field m_max_attackers pointer<CAttackers> // 0x0288
---@overload fun(entity: handle): CEntity
CEntity = Class("CEntity", nil, 0x290)

---@param entity handle
---@return CEntity
function CEntity:init(entity)
    if not ENTITY.DOES_ENTITY_EXIST(entity) then
        error("Invalid entity!")
    end

    local ptr = memory.handle_to_ptr(entity)

    ---@type CEntity
    local instance = setmetatable({}, CEntity)

    instance.m_ptr = ptr
    instance.m_model_info = ptr:add(0x0020):deref()
    instance.m_model_type = instance.m_model_info:add(0x009D)
    instance.m_flags = ptr:add(0x002D)
    instance.m_transform_matrix = ptr:add(0x0060)
    instance.m_render_focus_distance = ptr:add(0x00A8)
    instance.m_shadow_flags = ptr:add(0x00B0)
    instance.m_hostility = ptr:add(0x018C)
    instance.m_health = ptr:add(0x0280)
    instance.m_max_health = ptr:add(0x0284)
    instance.m_max_attackers = ptr:add(0x0288)

    return instance
end

---@return boolean
function CEntity:IsValid()
    return self.m_ptr and self.m_ptr:is_valid()
end

---@return eModelType
function CEntity:GetModelType()
    if not self:IsValid() then
        return eModelType.Invalid
    end

    return (self.m_model_type:get_word() & 0x1F)
end
