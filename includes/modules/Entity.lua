---@diagnostic disable: param-type-mismatch

--------------------------------------
-- Class: Entity
--------------------------------------
-- Class representing a GTA V entity.
---@class Entity : ClassMeta<Entity>
---@field private m_handle handle
---@field private m_modelhash joaat_t
---@field private m_ptr pointer
---@field private m_internal CEntity
---@overload fun(handle: integer): Entity
Entity = Class("Entity")

function Entity:__eq(right)
    local hndl = self:GetHandle()

    if IsInstance(right, Entity) then
        return (hndl == right:GetHandle())
    elseif(IsInstance(right, "number") and Game.IsScriptHandle(right)) then
        return (hndl == right)
    end

    return false
end

---@param handle number
---@return Entity|nil
function Entity.new(handle)
    if not Game.IsScriptHandle(handle) then
        return
    end

    ---@type Entity
    local instance = setmetatable({}, Entity)
    instance.m_handle = handle
    instance.m_modelhash = Game.GetEntityModel(handle)
    instance.m_ptr = memory.handle_to_ptr(handle)
    instance.m_internal = instance:Resolve()

    return instance
end

-- Resolves this entity to its corresponding internal game class (`CEntity`, `CPed`, or `CVehicle`).
--
-- If already resolved, returns the cached instance.
--
-- > **[Note]**: Inheritance chains are simplified. There are no `fwEntity`, `fwArchetype`, `CPhysical`, etc...
--
-- > Instead, the base class is `CEntity` and the others inherit from it.
--
-- Usage Example:
--
--```Lua
-- print(Self:Resolve().m_max_health:get_float()) -- -> 200.0 (Single Player Michael)
--
-- local veh = Self:GetVehicle()
-- if veh then
--      local cvehicle = veh:Resolve()
--      print(cvehicle.m_max_health:get_float()) -- -> 1000.0
--      print(cvehicle.m_handling_flags:get_dword()) -- -> dword flags (depends on the vehicle)
-- end
--```
---@generic T : CEntity
---@return T
function Entity:Resolve()
    if (self.m_internal and self.m_internal:IsValid()) then
        return self.m_internal
    end

    -- **DO NOT REMOVE. THIS IS NOT USELESS CODE.**
    -- We have to do this because `Self` inherits from `Entity` but doesn't have a constructor
    -- and doesn't store handles as members (because they can change).

    local hndl = self:GetHandle() -- This is overridden in `Self` to always invoke `PLAYER.PLAYER_PED_ID()`
    local ent_type = Game.GetEntityType(hndl)

    if (ent_type == eEntityType.Ped) then
        return CPed(hndl)
    elseif (ent_type == eEntityType.Vehicle) then
        return CVehicle(hndl)
    end

    return CEntity(hndl)
end

function Entity:Destroy()
    self.m_handle    = nil
    self.m_modelhash = nil
    self.m_internal  = nil
    self.m_ptr       = nil

    return nil
end

---@param modelHash hash
---@param entityType eEntityType
---@param pos? vec3
---@param heading? number
---@param isNetwork? boolean
---@param isScriptHostPed? boolean
function Entity:Create(modelHash, entityType, pos, heading, isNetwork, isScriptHostPed)
    modelHash = Game.EnsureModelHash(modelHash)
    if (not Game.IsModelHash(modelHash)) then
        return
    end

    pos = pos or self:GetSpawnPosInFront()

    if (entityType == eEntityType.Ped) then
        local handle = Game.CreatePed(modelHash, pos, heading, isNetwork, isScriptHostPed)
        return Ped(handle)
    elseif (entityType == eEntityType.Vehicle) then
        local handle = Game.CreateVehicle(modelHash, pos, heading, isNetwork, isScriptHostPed)
        return Vehicle(handle)
    else
        local handle = Game.CreateObject(modelHash, pos, isNetwork, isScriptHostPed)
        return Object(handle)
    end
end

function Entity:Delete()
    if self:Exists() then
        Game.DeleteEntity(self:GetHandle())
    end

    self:Destroy()
end

---@return boolean
function Entity:Exists()
    return (self:GetHandle() and Game.IsScriptHandle(self:GetHandle()))
end

---@return handle
function Entity:GetHandle()
    return self.m_handle
end

---@return joaat_t
function Entity:GetModelHash()
    return self.m_modelhash
end

---@return pointer|nil
function Entity:GetPointer()
    if not self.m_ptr then
        local handle = self:GetHandle()
        local ptr = memory.handle_to_ptr(handle)

        if not ptr:is_valid() then
            log.fwarning("Failed to get pointer for entity with handle %d", handle)
            return
        end

        self.m_ptr = ptr
    end

    return self.m_ptr
end

---@param bIsAlive? boolean
---@return vec3
function Entity:GetPos(bIsAlive)
    if bIsAlive == nil then bIsAlive = false end
    return self:Exists() and ENTITY.GET_ENTITY_COORDS(self:GetHandle(), bIsAlive) or vec3:zero()
end

---@param rotationOrder? integer
---@return vec3
function Entity:GetRot(rotationOrder)
    return self:Exists() and ENTITY.GET_ENTITY_ROTATION(self:GetHandle(), rotationOrder or 2) or vec3:zero()
end

---@return vec3
function Entity:GetForwardVector()
    return self:Exists() and ENTITY.GET_ENTITY_FORWARD_VECTOR(self:GetHandle()) or vec3:zero()
end

---@return number
function Entity:GetForwardX()
    return self:Exists() and ENTITY.GET_ENTITY_FORWARD_X(self:GetHandle()) or 0
end

---@return number
function Entity:GetForwardY()
    return self:Exists() and ENTITY.GET_ENTITY_FORWARD_Y(self:GetHandle()) or 0
end

---@return number
function Entity:GetForwardZ()
    return self:Exists() and self:GetForwardVector().z or 0
end

---@return integer
function Entity:GetMaxHealth()
    return self:Exists() and ENTITY.GET_ENTITY_MAX_HEALTH(self:GetHandle()) or 0
end

---@return integer
function Entity:GetHealth()
    return self:Exists() and ENTITY.GET_ENTITY_HEALTH(self:GetHandle()) or 0
end

---@param offset? number
---@return number
function Entity:GetHeading(offset)
    offset = offset or 0
    return self:Exists() and (ENTITY.GET_ENTITY_HEADING(self:GetHandle()) + offset) or 0
end

---@return number
function Entity:GetSpeed()
    return self:Exists() and ENTITY.GET_ENTITY_SPEED(self:GetHandle()) or 0
end

---@return vec3
function Entity:GetVelocity()
    return self:Exists() and ENTITY.GET_ENTITY_VELOCITY(self:GetHandle()) or vec3:zero()
end

---@return number
function Entity:GetHeightAboveGround()
    return self:Exists() and ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(self:GetHandle()) or 0
end

---@param offset_x number
---@param offset_y number
---@param offset_z number
---@return vec3
function Entity:GetOffsetInWorldCoords(offset_x, offset_y, offset_z)
    if not self:Exists() then
        return vec3:zero()
    end

    return ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
        self:GetHandle(),
        offset_x,
        offset_y,
        offset_z
    )
end

---@param offset_x number
---@param offset_y number
---@param offset_z number
---@return vec3
function Entity:GetOffsetGivenWorldCoords(offset_x, offset_y, offset_z)
    if not self:Exists() then
        return vec3:zero()
    end

    return ENTITY.GET_OFFSET_FROM_ENTITY_GIVEN_WORLD_COORDS(
        self:GetHandle(),
        offset_x,
        offset_y,
        offset_z
    )
end

function Entity:GetBoneCount()
    if not self:Exists() then
        return 0
    end
    return Game.GetEntityBoneCount(self:GetHandle())
end

---@param boneName string
function Entity:GetBoneIndexByName(boneName)
    if not self:Exists() then
        return 0
    end
    return Game.GetEntityBoneIndexByName(self:GetHandle(), boneName)
end

---@param bone string|number
function Entity:GetBonePosition(bone)
    if not self:Exists() then
        return vec3:zero()
    end
    return Game.GetEntityBonePos(self:GetHandle(), bone)
end

---@param bone string|number
function Entity:GetBoneRotation(bone)
    if not self:Exists() then
        return vec3:zero()
    end
    return Game.GetEntityBoneRot(self:GetHandle(), bone)
end

---@param bone string|number
function Entity:GetWorldPositionOfBone(bone)
    if not self:Exists() then
        return vec3:zero()
    end
    return Game.GetEntityBonePos(self:GetHandle(), bone)
end

---@param coords vec3
---@param xAxis? boolean
---@param yAxis? boolean
---@param zAxis? boolean
---@param clearArea? boolean
function Entity:SetCoords(coords, xAxis, yAxis, zAxis, clearArea)
    if not self:Exists() then
        return
    end

    Game.SetEntityCoords(self:GetHandle(), coords, xAxis, yAxis, zAxis, clearArea)
end

---@param coords vec3
---@param xAxis? boolean
---@param yAxis? boolean
---@param zAxis? boolean
function Entity:SetCoordsNoOffset(coords, xAxis, yAxis, zAxis)
    if not self:Exists() then
        return
    end

    Game.SetEntityCoordsNoOffset(self:GetHandle(), coords, xAxis, yAxis, zAxis)
end

function Entity:Kill()
    if not self:Exists() then
        return
    end

    ENTITY.SET_ENTITY_HEALTH(self:GetHandle(), 0, 0, 0)
end

function Entity:SetAsNoLongerNeeded()
    ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(self:GetHandle())
end

function Entity:SetModelAsNoLongerNeeded()
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(self:GetModelHash())
end

function Entity:GetModelDimensions()
    if not self:Exists() then
        return vec3:zero(), vec3:zero()
    end

    return Game.GetModelDimensions(self:GetModelHash())
end

-- Will be improved later.
function Entity:GetSpawnPosInFront()
    if not self:Exists() then
        return Self and Self:GetOffsetInWorldCoords(0, 5, 0.1) or vec3:zero()
    end

    local min, max = self:GetModelDimensions()
    local length = max.y - min.y
    return self:GetOffsetInWorldCoords(0, length, 0.1)
end

---@param keep_physics? boolean
function Entity:EnableCollision(keep_physics)
    if not self:Exists() then
        return
    end

    if (type(keep_physics) ~= "boolean") then
        keep_physics = true
    end

    ENTITY.SET_ENTITY_COLLISION(self:GetHandle(), true, keep_physics)
end

---@param keep_physics? boolean
function Entity:DisableCollision(keep_physics)
    if not self:Exists() then
        return
    end

    if (type(keep_physics) ~= "boolean") then
        keep_physics = false
    end

    ENTITY.SET_ENTITY_COLLISION(self:GetHandle(), false, keep_physics)
end

---@param toggle boolean
function Entity:ToggleInvincibility(toggle)
    if not self:Exists() then
        return
    end

    ENTITY.SET_ENTITY_INVINCIBLE(self:GetHandle(), toggle)
end

function Entity:Freeze()
    if not self:Exists() then
        return
    end

    ENTITY.FREEZE_ENTITY_POSITION(self:GetHandle(), true)
end

function Entity:Unfreeze()
    if not self:Exists() then
        return
    end

    ENTITY.FREEZE_ENTITY_POSITION(self:GetHandle(), false)
end

function Entity:GetBoxCorners()
    if not self:Exists() then
        return {}
    end

    local corners = {}
    local vmin, vmax = self:GetModelDimensions()

    for x = 0, 1 do
        for y = 0, 1 do
            for z = 0, 1 do
                local offset_vector = vec3:new(
                    x == 0 and vmin.x or vmax.x,
                    y == 0 and vmin.y or vmax.y,
                    z == 0 and vmin.z or vmax.z
                )

                local world_pos = self:GetOffsetInWorldCoords(
                    offset_vector.x,
                    offset_vector.y,
                    offset_vector.z
                )
                table.insert(corners, world_pos)
            end
        end
    end

    return corners
end

---@param color Color
function Entity:DrawBoundingBox(color)
    local r, g, b, a = color:AsRGBA()
    local corners = self:GetBoxCorners()
    local connections = {
        {1,2}, {2,4}, {4,3}, {3,1},
        {5,6}, {6,8}, {8,7}, {7,5},
        {1,5}, {2,6}, {3,7}, {4,8},
    }

    for _, pair in ipairs(connections) do
        local corner_a = corners[pair[1]]
        local corner_b = corners[pair[2]]

        GRAPHICS.DRAW_LINE(
            corner_a.x,
            corner_a.y,
            corner_a.z,
            corner_b.x,
            corner_b.y,
            corner_b.z,
            r,
            g,
            b,
            a or 255
        )
    end
end
