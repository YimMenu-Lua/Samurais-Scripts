---@class Decorator
Decorator = {}
Decorator.RegisteredEntities = {}

---@param entity integer
---@param key string
function Decorator:IsEntityRegistered(entity, key)
    return self.RegisteredEntities[entity]
    and self.RegisteredEntities[entity].key
    and self.RegisteredEntities[entity].key == key
end

---@param entity integer
---@param key string
---@param expectedValue any
function Decorator:ExistsOn(entity, key, expectedValue)
    if not self:IsEntityRegistered(entity, key) then
        return false
    end

    return self.RegisteredEntities[entity].value
    and self.RegisteredEntities[entity].value == expectedValue
end

---@param entity integer
---@param key string
---@param value any
function Decorator:RegisterEntity(entity, key, value)
    if self:IsEntityRegistered(entity, key) then
        return
    end

    self.RegisteredEntities[entity] = {
        handle = entity,
        key = key,
        value = value
    }
end

---@param entity integer
---@param key string
function Decorator:RemoveEntity(entity, key)
    if not self:IsEntityRegistered(entity, key) then
        return
    end

    self.RegisteredEntities[entity] = nil
end

---@param entity integer
-- only bool decorators for now
function Decorator:Validate(entity)
    return ENTITY.DOES_ENTITY_EXIST(entity) and (self.RegisteredEntities[entity] ~= nil)
end

---@param entity integer
function Decorator:DebugDump(entity)
    if next(self.RegisteredEntities) == nil then
        return
    end

    if not self.RegisteredEntities[entity] then
        SS.debug(string.format("[%s] is not registered.", entity))
        return
    end

    SS.debug(
        string.format(
            "[%s] is registered to %s as %s",
            entity,
            self.RegisteredEntities[entity].key,
            self.RegisteredEntities[entity].value
        )
    )
end
