-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


--------------------------------------
-- Class: Decorator
--------------------------------------
-- **Global Singleton.**
--
-- Custom decorator to mark entities owned by this script.
---@class Decorator
---@field private m_registry table<handle, table<string, any>>
---@field private m_last_gc seconds
local Decorator   = {
	m_last_gc  = 0,
	m_registry = {}
}; Decorator.__index = Decorator ---@private

---@param entity integer
function Decorator:IsEntityRegistered(entity)
	return self.m_registry[entity] ~= nil
end

---@param entity integer
---@param key string
---@return boolean
function Decorator:ExistsOn(entity, key)
	if (not self:IsEntityRegistered(entity)) then
		return false
	end

	local data = self.m_registry[entity]
	return data ~= nil and data[key] ~= nil
end

---@param entity handle
---@param key string
---@return any
function Decorator:GetDecor(entity, key)
	local data = self.m_registry[entity]
	return data and data[key] or nil
end

-- If a decor doesn't exist for the entity, this will register it nonetheless.
--
-- The only requirement is that the entity itself is registered.
---@param entity handle
---@param key string
---@param new_value any
---@return any
function Decorator:UpdateDecor(entity, key, new_value)
	if (not self:IsEntityRegistered(entity)) then
		return
	end

	self.m_registry[entity][key] = new_value
end

---@param entity integer
---@param key string
---@param value any
function Decorator:Register(entity, key, value)
	local registered = self.m_registry[entity]
	if (not registered) then
		self.m_registry[entity] = { [key] = value }
		return
	end

	if (registered[key]) then
		return
	end

	registered[key] = value
end

---@param entity integer
function Decorator:RemoveEntity(entity)
	if (not self:IsEntityRegistered(entity)) then
		return
	end

	self.m_registry[entity] = nil
end

---@param entity integer
function Decorator:Validate(entity)
	return self:IsEntityRegistered(entity) and ENTITY.DOES_ENTITY_EXIST(entity)
end

function Decorator:CollectGarbage()
	local now = Time.Now()
	if (now - self.m_last_gc < 5) then
		return
	end

	for handle in pairs(self.m_registry) do
		if (not ENTITY.DOES_ENTITY_EXIST(handle)) then
			self.m_registry[handle] = nil
		end
	end

	self.m_last_gc = now
end

---@param entity integer
function Decorator:DebugDump(entity)
	local reg = self.m_registry
	if (next(reg) == nil) then
		return
	end

	local data = reg[entity]
	if (not data) then
		Backend:debug("[Decorator] [%s]: not registered.", entity)
		return
	end

	Backend:debug("[Decorator] [%s]: registered with %s", entity, data)
end

return Decorator
