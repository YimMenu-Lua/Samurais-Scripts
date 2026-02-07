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
---@field private m_address pointer
---@field private m_data_ptr pointer
---@field private m_size uint16_t
---@field private m_count uint16_t
---@field private m_data array<pointer>
---@field private m_data_type any
---@field private m_last_update_time TimePoint
---@overload fun(address: pointer, data_type?: any): atArray
atArray = {}
atArray.__index = atArray
atArray.__type = "atArray"
---@diagnostic disable-next-line
setmetatable(atArray, {
	__call = function(cls, ...)
		return cls.new(...)
	end,
})

---@generic T
---@param address pointer
---@param data_type optional<T>
---@return atArray<T>
function atArray.new(address, data_type)
	local instance = setmetatable({
		m_address = nullptr,
		m_data_ptr = nullptr,
		m_size = 0x0,
		m_count = 0x0,
		m_data = {},
		m_data_type = nil
		---@diagnostic disable-next-line
	}, atArray)

	if not (IsInstance(address, "pointer") and address:is_valid()) then
		return instance
	end

	local array_size = address:add(0x8):get_word()
	if (array_size == 0) then
		return instance
	end

	instance.m_address = address
	instance.m_data_ptr = address:deref()
	instance.m_size = array_size
	instance.m_count = address:add(0xA):get_word()
	instance.m_data_type = data_type
	instance.m_last_update_time = TimePoint:new()

	for i = 0, array_size - 1 do
		instance.m_data[i + 1] = instance.m_data_ptr:add(i * 0x8):deref()
	end

	return instance
end

---@return boolean
function atArray:IsValid()
	return self.m_address:is_valid() and self.m_data_ptr:is_valid()
end

---@return boolean
function atArray:IsNull()
	return not self:IsValid()
end

---@return boolean
function atArray:IsEmpty()
	self:Update()
	return self.m_size == 0
end

function atArray:Clear()
	self.m_address = nullptr
	self.m_data_ptr = nullptr
	self.m_data = {}
	self.m_size = 0x0
	self.m_count = 0x0
	self.m_data_type = nil
	self.m_last_update_time:reset()
end

function atArray:Update()
	if not self:IsValid() then
		return
	end

	if not self.m_last_update_time:has_elapsed(250) then
		return
	end

	self.m_size = self.m_address:add(0x8):get_word()
	self.m_count = self.m_address:add(0xA):get_word()
	if (self.m_size == 0) then
		self.m_data = {}
		self.m_last_update_time:reset()
		return
	end

	for i = 0, self.m_size - 1 do
		self.m_data[i + 1] = self.m_data_ptr:add(i * 0x8):deref()
	end

	self.m_last_update_time:reset()
end

---@return pointer|nil
function atArray:GetPointer()
	if not self:IsValid() then
		return
	end

	return self.m_address
end

---@return pointer|nil
function atArray:GetDataPointer()
	if not self:IsValid() then
		return
	end

	return self.m_data_ptr
end

---@return uint64_t
function atArray:GetAddress()
	return self:IsValid() and self.m_address:get_address() or 0x0
end

---@return uint64_t
function atArray:GetDataAddress()
	return self:IsValid() and self.m_data_ptr:get_address() or 0x0
end

---@return uint16_t
function atArray:Size()
	self:Update()
	return self.m_size
end

---@return uint16_t
function atArray:Count()
	self:Update()
	return self.m_count
end

---@return uint16_t
function atArray:DataSize()
	return SizeOf(self.m_data)
end

---@return string
function atArray:DataType()
	local _t = "unknonwn"
	if (self.m_data_type and IsInstance(self.m_data_type.__type, "string")) then
		_t = self.m_data_type.__type
	end

	return _F("pointer<%s>", _t)
end

---@param i number
---@return pointer
function atArray:Get(i)
	self:Update()
	assert(math.is_inrange(i, 1, self.m_size), "[atArray]: Index out of bounds!")
	return self.m_data[i]
end

---@param i number
---@param v pointer
function atArray:Set(i, v)
	self:Update()
	assert(math.is_inrange(i, 1, self.m_size), "[atArray]: Index out of bounds!")
	assert(IsInstance(v, "pointer"), "[atArray]: Attempt to set array value to non-pointer value!")

	self.m_data[i] = v
end

---@return fun(): integer, pointer Iterator
function atArray:Iter()
	self:Update()
	local i = 0

	return function()
		i = i + 1
		if i <= self.m_size then
			return i, self.m_data[i]
			---@diagnostic disable-next-line: missing-return
		end
	end
end

function atArray:__pairs()
	log.warning("[atArray]: Use of pairs! Please use atArray:Iter() instead.")
	return self:Iter()
end

---@return integer
function atArray:__len()
	self:Update()
	return self.m_size
end

---@return string
function atArray:__tostring()
	self:Update()
	local buffer = ""
	local data_type = self:DataType()

	for i, data in self:Iter() do
		buffer = buffer .. _F("\n[%d] %s @ 0x%X>", i, data_type, data:get_address())
	end

	return buffer
end
