---@generic T
---@class Set<T> : { [T]: true }
---@field private m_data table<anyval, true>
---@field private m_data_type string
Set = {}
Set.__index = Set

---@generic T
---@param ... T
---@return Set<T>
function Set.new(...)
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

function Set:Push(element)
	if (element == nil) then
		return
	end

	local __type = type(element)
	if (not self.m_data_type) then
		self.m_data_type = __type
	elseif (__type ~= self.m_data_type) then
		error(_F(
			"[Set]: Data type mismatch! A set can only be created with same-type objects. %s expected, got %s instead.",
			self.m_data_type,
			__type
		))
	end

	self.m_data[element] = true
end

function Set:Pop(element)
	if (type(element) ~= self.m_data_type) then
		return
	end

	self.m_data[element] = nil
end

function Set:Clear()
	self.m_data = {}
end

---@return boolean
function Set:Contains(element)
	return self.m_data[element] == true
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
