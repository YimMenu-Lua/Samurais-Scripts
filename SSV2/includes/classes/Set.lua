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
---@generic T
---@class Set<T> : { [T]: true }
---@field protected m_data table<anyval, true>
---@field protected m_data_type string
---@overload fun(...): Set<...>
Set = {}
Set.__index = Set
Set.__type = "Set"
---@diagnostic disable-next-line: param-type-mismatch
setmetatable(Set, {
	__call = function(_, ...)
		return Set.new(...)
	end
})

---@generic T
---@param ... T
---@return Set<T>
function Set.new(...)
	---@diagnostic disable-next-line: param-type-mismatch
	local instance = setmetatable({ m_data = {} }, Set)
	local args = { ... }

	if (#args > 0) then
		instance.m_data_type = type(args[1])
		for _, arg in ipairs(args) do
			instance:Push(arg)
		end
	end

	return instance
end

---@param element anyval
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

---@param element anyval
function Set:Pop(element)
	if (type(element) ~= self.m_data_type) then
		return
	end

	self.m_data[element] = nil
end

function Set:Clear()
	self.m_data = {}
end

---@param element anyval
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

function Set:Iter()
	return pairs(self.m_data)
end

function Set:__pairs()
	return pairs(self.m_data)
end

-- This is probably bad. Set:Contains() should be the only source of truth.
-- function Set:__index(key)
-- 	return Set[key] or (self.m_data[key] == true)
-- end
