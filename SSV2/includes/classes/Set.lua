-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


--------------------------------------
-- Class: Set
--------------------------------------
-- Stores unique items of the same type.
--___
-- The set's runtime type is determined by the first item inserted. Once a type
--
-- has been determined, attempting to push a value of a different type will
--
-- raise an error.
--
-- For best LuaLS type inference, consider constructing sets with at least one item:
--
--```Lua
-- local strings = Set("abc") -- Set<string>
-- strings:Push(69) -- <- Produces a LuaLS type-mismatch warning
--```
--
-- Creating an empty set does not provide LuaLS enough information to infer the
--
-- generic type:
--
--```Lua
-- local unk = Set() -- Set<T>
-- unk:Push("abc") -- No LuaLS warnings
-- unk:Push(123) -- <- Still no LuaLS warning but this will throw at runtime because the previous Push assigned a string type.
--```
--
-- Subsequent calls to Push do not update the inferred generic parameter, though
-- runtime type checking still works as expected.
---@class Set<T>
---@field protected m_data { [T]: true }
---@field private m_data_type string
---@field private m_count integer
---@overload fun(...: T): Set<T>
local Set = Callable("Set", { ctor = function(t, ...) return t:new(...) end })

---@param ... T
---@return Set<T>
function Set:new(...)
	local instance = setmetatable({
		m_data  = {},
		m_count = 0
	}, self)

	for _, v in ipairs({ ... }) do
		instance:Push(v)
	end

	return instance
end

---@param element T
function Set:Push(element)
	if (element == nil) then
		return
	end

	if (self.m_data[element] == true) then
		return
	end

	local __type = type(element)
	if (not self.m_data_type) then
		self.m_data_type = __type
	elseif (__type ~= self.m_data_type) then
		error(_F("[Set]: Type mismatch! A set can only contain unique same-type objects. Expected '%s', got '%s' instead.",
			self.m_data_type,
			__type
		))
	end

	self.m_data[element] = true
	self.m_count         = self.m_count + 1
end

---@param element T
function Set:Pop(element)
	if (self.m_data[element] == nil) then
		return
	end

	self.m_data[element] = nil
	self.m_count         = self.m_count - 1

	if (self.m_count == 0) then
		self.m_data_type = nil
	end
end

function Set:Clear()
	self.m_data      = {}
	self.m_count     = 0
	self.m_data_type = nil
end

---@param element any
---@return boolean
function Set:Contains(element)
	return self.m_data[element] == true
end

---@return boolean
function Set:IsEmpty()
	return self.m_count == 0
end

---@return integer
function Set:Size()
	return self.m_count
end

---@return fun(t: table<T, true>, index?: T): T, true Iterator
---@return table<T, true> data
function Set:Iter()
	return pairs(self.m_data)
end

---@return fun(t: table<T, true>, index?: T): T, true
---@return table<T, true>
function Set:__pairs()
	return pairs(self.m_data)
end

---@return integer
function Set:__len()
	return self.m_count
end

return Set
