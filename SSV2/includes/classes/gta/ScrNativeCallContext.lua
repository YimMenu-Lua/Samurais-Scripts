-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView = require("includes.classes.gta.CStructView")


--------------------------------------
-- Class: ScrNativeCallContext
--------------------------------------
---@class ScrNativeCallContext : CStructBase<ScrNativeCallContext>
---@field m_return_value pointer_ref
---@field m_arg_count pointer<uint32_t>
---@field m_args pointer_ref
---@field m_data_count pointer<int32_t>
---@field m_orig pointer
---@field m_buffer pointer
---@overload fun(ptr: pointer): ScrNativeCallContext
local ScrNativeCallContext = CStructView("ScrNativeCallContext", 0x80)

---@param ptr pointer
---@return ScrNativeCallContext
function ScrNativeCallContext.new(ptr)
	return MakeInstance({
		m_ptr          = ptr,
		m_return_value = ptr,
		m_arg_count    = ptr:add(0x08),
		m_args         = ptr:add(0x10),
		m_data_count   = ptr:add(0x18),
		m_orig         = ptr:add(0x20),
		m_buffer       = ptr:add(0x40),
	}, ScrNativeCallContext)
end

---@param index integer
---@return pointer
function ScrNativeCallContext:GetArgSlot(index)
	assert(self:IsValid(), "Native context is null")
	local count = self.m_arg_count:get_dword()
	assert(math.type(index) == "integer" and index >= 0 and index < count, "Native argument index out of bounds")
	local args = self.m_args:deref()
	assert(args:is_valid(), "Native argument storage is null")
	return args:add(index * 0x8)
end

---@param index integer
---@return pointer
function ScrNativeCallContext:GetArgPointer(index)
	return self:GetArgSlot(index):deref()
end

---@param index integer
---@return int32_t
function ScrNativeCallContext:GetArgInt(index)
	return self:GetArgSlot(index):get_int()
end

---@param index integer
---@return joaat_t
function ScrNativeCallContext:GetArgHash(index)
	return self:GetArgSlot(index):get_dword()
end

---@return int32_t
function ScrNativeCallContext:GetReturnInt()
	local ptr = self.m_return_value:deref()
	assert(ptr:is_valid(), "Native return storage is null")
	return ptr:get_int()
end

---@param value int32_t
function ScrNativeCallContext:SetReturnInt(value)
	local ptr = self.m_return_value:deref()
	assert(ptr:is_valid(), "Native return storage is null")
	ptr:set_int(value)
end

return ScrNativeCallContext
