-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.
--
-- Converted from Yimura's C++ GTA V Classes: https://github.com/Yimura/GTAV-Classes (forked here: https://github.com/Mr-X-GTA/GTAV-Classes-1)


local fwDrawData = require("includes.classes.gta.fwDrawData")

---@class CBaseModelInfo
---@class CAttackers

---@enum eEntityFlags1
Enums.eEntityFlags1 = { -- uint8? // TODO
	FROZEN        = 0x0,
	HAS_COLLISION = 0x1,
}

---@enum eEntityFlags2
Enums.eEntityFlags2 = { -- uint32
	INVISIBLE = 0x0,
	DYNAMIC   = 0x10,   -- peds, vehicles, destructibles, etc. (CDynamicEntity)
	FIXED     = 0x11,   -- solid immovable objects. we can use these for vehicle crash severity (DYNAMIC? 'tis but a scratch! FIXED?: straight to the grave)
}


--------------------------------------
-- Class: CEntity
--------------------------------------
---@ignore
---@class CEntity: ClassMeta<CEntity>
---@field protected m_ptr pointer
---@field m_model_info pointer<CBaseModelInfo> -- 0x0020
---@field m_model_type pointer<eModelType> CBaseModelInfo + 0x009D
---@field m_type pointer<uint8_t> -- 0: Ped | 3: Vehicle
---@field m_flags_unk pointer<eEntityFlags1> -- uint8
---@field m_entity_flags pointer<eEntityFlags2>
---@field m_draw_data fwDrawData
---@field m_transform_matrix pointer<fMatrix44>
---@field m_render_focus_distance pointer<uint32_t>
---@field m_shadow_flags pointer<uint32_t>
---@field m_damage_bits pointer<uint32_t>
---@field m_hostility pointer<uint8_t>
---@field m_health pointer<float>
---@field m_max_health pointer<float>
---@field m_attackers pointer_ref<CAttackers> -- 0x0288
---@overload fun(entity: handle): CEntity
local CEntity = Class("CEntity", { symbolic_size = 0x028C })

---@param entity handle
---@return CEntity
function CEntity:init(entity)
	if (not ENTITY.DOES_ENTITY_EXIST(entity)) then
		error("Invalid entity!")
	end

	local ptr                          = memory.handle_to_ptr(entity)
	local instance --[[@type CEntity]] = setmetatable({ m_ptr = ptr }, self)
	local model_info                   = ptr:add(0x0020):deref()
	instance.m_model_info              = model_info
	instance.m_model_type              = model_info:add(0x009D)
	instance.m_type                    = ptr:add(0x0028)
	instance.m_flags_unk               = ptr:add(0x0029)
	instance.m_entity_flags            = ptr:add(0x002C)
	instance.m_draw_data               = fwDrawData(ptr:add(0x0048):deref())
	instance.m_transform_matrix        = ptr:add(0x0060)
	instance.m_render_focus_distance   = ptr:add(0x00A8)
	instance.m_shadow_flags            = ptr:add(0x00B0)
	instance.m_damage_bits             = ptr:add(0x0188)
	instance.m_hostility               = ptr:add(0x018C)
	instance.m_health                  = ptr:add(0x0280)
	instance.m_max_health              = ptr:add(0x0284)
	instance.m_attackers               = ptr:add(0x0288) -- CAttackers*
	return instance
end

---@generic R1, R2, R3, R4, R5
---@param default any
---@param func fun(...?): R1, R2?, R3?, R4?, R5?, ...?
---@param ... any
---@return R1, R2?, R3?, R4?, R5?, ...?
function CEntity:__safecall(default, func, ...)
	if (not self:IsValid()) then
		return default
	end

	return func(...)
end

---@return boolean
function CEntity:IsValid()
	return self.m_ptr and self.m_ptr:is_valid()
end

---@return boolean
function CEntity:IsInvisible()
	return Bit.IsBitSet(self.m_entity_flags:get_dword(), Enums.eEntityFlags2.INVISIBLE)
end

---@return boolean
function CEntity:IsDynamicEntity()
	return Bit.IsBitSet(self.m_entity_flags:get_dword(), Enums.eEntityFlags2.DYNAMIC)
end

---@return pointer
function CEntity:GetPointer()
	return self.m_ptr
end

---@return uint64_t
function CEntity:GetAddress()
	return self.m_ptr:get_address()
end

---@return eModelType
function CEntity:GetModelType()
	return self:__safecall(Enums.eModelType.Invalid, function()
		return self.m_model_type:get_word() & 0x1F
	end)
end

---@param toggle boolean
function CEntity:ToggleVisibility(toggle)
	local pFlags = self.m_entity_flags
	pFlags:set_dword(Bit.Toggle(pFlags:get_dword(), Enums.eEntityFlags2.INVISIBLE, toggle))
end

return CEntity
