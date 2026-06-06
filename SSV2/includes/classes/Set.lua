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
---@class Set<T> : { [T]: true }
---@field protected m_data table<T, true>
---@field protected m_data_type string
---@field new fun(...: T): Set<T>
---@overload fun(...: T): Set<T>
local Set = Callable("Set", {
	ctor = function(t, ...)
		return t:new(...)
	end
})

function Set:new(...)
	local instance = setmetatable({ m_data = {} }, self)
	local args     = { ... }

	if (#args > 0) then
		instance.m_data_type = type(args[1])
		for _, arg in ipairs(args) do
			instance:Push(arg)
		end
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
		error(_F(
			"[Set]: Data type mismatch! A set can only contain unique same-type objects. %s expected, got %s instead.",
			self.m_data_type,
			__type
		))
	end

	self.m_data[element] = true
end

---@param element T
function Set:Pop(element)
	self.m_data[element] = nil
end

function Set:Clear()
	self.m_data = {}
end

---@param element any
---@return boolean
function Set:Contains(element)
	return self.m_data[element] == true
end

---@return boolean
function Set:IsEmpty()
	return (next(self.m_data) == nil)
end

---@return number
function Set:Size()
	return table.getlen(self.m_data)
end

---@return fun(t: table<T, true>, index?: T): T, true
---@return table<T, true>
function Set:Iter()
	return pairs(self.m_data)
end

---@return fun(t: table<T, true>, index?: T): T, true
---@return table<T, true>
function Set:__pairs()
	return pairs(self.m_data)
end

return Set
