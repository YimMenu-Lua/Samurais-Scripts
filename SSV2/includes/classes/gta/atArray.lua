-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


--------------------------------------
-- Class: atArray
--------------------------------------
---@ignore
---@generic T
---@class atArray<T>
---@field protected m_ptr pointer
---@field private m_data_ptr pointer
---@field private m_data array<pointer_ref<T>>
---@field private m_size uint16_t
---@field private m_capacity uint16_t
---@field private m_data_type any
---@overload fun(address: pointer, data_type?: any): atArray
local atArray = {
	__type     = "atArray",
	__ptr_ctor = true
}
atArray.__index = atArray

---@diagnostic disable-next-line
setmetatable(atArray, {
	__call = function(cls, ...)
		return cls.new(...)
	end,
})

---@generic T
---@param ptr pointer
---@param data_type optional<T>
---@return atArray<T>
function atArray.new(ptr, data_type)
	local instance = setmetatable({
		m_ptr       = ptr,
		m_data_ptr  = nullptr,
		m_size      = 0,
		m_capacity  = 0,
		m_data      = {},
		m_data_type = nil
		---@diagnostic disable-next-line: param-type-mismatch
	}, atArray)

	if (ptr:is_null()) then
		return instance
	end

	local array_size = ptr:add(0x8):get_word()
	if (array_size == 0) then
		return instance
	end

	instance.m_data_ptr  = ptr:deref()
	instance.m_size      = array_size
	instance.m_capacity  = ptr:add(0x10):get_word()
	instance.m_data_type = data_type

	for i = 0, array_size - 1 do
		instance.m_data[i + 1] = instance.m_data_ptr:add(i * 0x8)
	end

	return instance
end

---@return boolean
function atArray:IsValid()
	return self.m_ptr:is_valid() and self.m_data_ptr:is_valid()
end

---@return boolean
function atArray:IsNull()
	return not self:IsValid()
end

---@return boolean
function atArray:IsEmpty()
	return self.m_size == 0
end

function atArray:Clear()
	self.m_ptr       = nullptr
	self.m_data_ptr  = nullptr
	self.m_size      = 0
	self.m_capacity  = 0
	self.m_data      = {}
	self.m_data_type = nil
end

---@return pointer|nil
function atArray:GetPointer()
	if (not self:IsValid()) then
		return
	end

	return self.m_ptr
end

---@return pointer|nil
function atArray:GetDataPointer()
	if (not self:IsValid()) then
		return
	end

	return self.m_data_ptr
end

---@return uint64_t
function atArray:GetAddress()
	return self:IsValid() and self.m_ptr:get_address() or 0x0
end

---@return uint64_t
function atArray:GetDataAddress()
	return self:IsValid() and self.m_data_ptr:get_address() or 0x0
end

---@return string
function atArray:GetDataType()
	local _t = "unknonwn"
	if (type(self.m_data_type) == "table" and self.m_data_type.__type) then
		_t = self.m_data_type.__type
	end

	return _F("pointer<%s>", _t)
end

---@param i integer
---@return pointer<T>
function atArray:At(i)
	assert(math.is_inrange(i, 1, self.m_size), "[atArray]: Index out of bounds!")
	return self.m_data[i]:deref()
end

---@return uint16_t
function atArray:Size()
	return self.m_size
end

---@return uint16_t
function atArray:Capacity()
	return self.m_capacity
end

-- NOTE: As opposed to the `At` method, you must dereference the pointers returned by this iterator.
---@return fun(): integer, pointer_ref<T> Iterator
function atArray:Iter()
	local i = 0
	return function()
		i = i + 1
		if (i <= self.m_size) then
			return i, self.m_data[i]
			---@diagnostic disable-next-line: missing-return
		end
	end
end

---@return fun(): integer, pointer<T> Iterator
function atArray:__pairs()
	log.warning("[atArray]: Use of pairs! Please use atArray:Iter() instead.")
	return self:Iter()
end

---@return integer
function atArray:__len()
	return self.m_size
end

---@return string
function atArray:__tostring()
	local buffer = ""
	local __type = self:GetDataType()
	for i, data in self:Iter() do
		buffer = buffer .. _F("\n[%d] %s* @ 0x%X>", i, __type, data:get_address())
	end
	return buffer
end

return atArray
