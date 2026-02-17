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
---@field RegisteredEntities table<integer, table<string, any>>
---@field private m_last_gc seconds
Decorator = { m_last_gc = 0 }
Decorator.RegisteredEntities = {}

---@param entity integer
function Decorator:IsEntityRegistered(entity)
	return self.RegisteredEntities[entity] ~= nil
end

---@param entity integer
---@param key string
---@return boolean
function Decorator:ExistsOn(entity, key)
	if (not self:IsEntityRegistered(entity)) then
		return false
	end

	return self.RegisteredEntities[entity][key] and self.RegisteredEntities[entity][key] ~= nil
end

---@param entity handle
---@param key string
---@return any
function Decorator:GetDecor(entity, key)
	if (not self:ExistsOn(entity, key)) then
		return
	end

	return self.RegisteredEntities[entity][key]
end

-- If a decor doesn't exist for the entity, this will register it nonetheless.
--
-- The only requirement is that the entity itself is registered.
---@param entity handle
---@param key string
---@param new_value anyval
---@return any
function Decorator:UpdateDecor(entity, key, new_value)
	if (not self:IsEntityRegistered(entity)) then
		return
	end

	self.RegisteredEntities[entity][key] = new_value
end

---@param entity integer
---@param key string
---@param value any
function Decorator:Register(entity, key, value)
	local existing = self.RegisteredEntities[entity]
	if (existing) then
		if (existing[key]) then
			return
		end

		existing[key] = value
	else
		self.RegisteredEntities[entity] = { [key] = value }
	end
end

---@param entity integer
function Decorator:RemoveEntity(entity)
	if not self:IsEntityRegistered(entity) then
		return
	end

	self.RegisteredEntities[entity] = nil
end

---@param entity integer
function Decorator:Validate(entity)
	return self:IsEntityRegistered(entity) and ENTITY.DOES_ENTITY_EXIST(entity)
end

function Decorator:CollectGarbage()
	if (Time.Now() - self.m_last_gc < 5) then
		return
	end

	for handle, _ in pairs(self.RegisteredEntities) do
		if (not ENTITY.DOES_ENTITY_EXIST(handle)) then
			self.RegisteredEntities[handle] = nil
		end
	end

	self.m_last_gc = Time.Now()
end

---@param entity integer
function Decorator:DebugDump(entity)
	if next(self.RegisteredEntities) == nil then
		return
	end

	if not self.RegisteredEntities[entity] then
		Backend:debug(_F("[%s] is not registered.", entity))
		return
	end

	Backend:debug(
		_F(
			"[%s] is registered with: %s",
			entity,
			self.RegisteredEntities[entity]
		)
	)
end
