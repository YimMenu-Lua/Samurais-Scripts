---@diagnostic disable: undefined-global, lowercase-global, param-type-mismatch

local TYPE_OBJECT  <const> = 0
local TYPE_VEHICLE <const> = 1
local TYPE_PED     <const> = 2

---@alias EntityType integer
---| 0 # TYPE_OBJECT
---| 1 # TYPE_VEHICLE
---| 2 # TYPE_PED


-----------------------------------------------------
-- SpawnedEntity Struct
-----------------------------------------------------
-- Represents an entity spawned with `EntityForge` (ped, vehicle, object).
---@class SpawnedEntity
---@field handle integer
---@field name string
---@field modelHash integer
---@field type EntityType
---@field properties table
---@field alpha number
---@field isAttached boolean
---@field isForged boolean
---@field isPlayer boolean
---@field isWorldEntity boolean
---@field parent table
---@field parent_bone number | string
---@field children SpawnedEntity[]
---@field position vec3
---@field rotation vec3
---@field target_pos vec3?
---@field last_pos vec3?
---@field attach_pos vec3
---@field attach_rot vec3
SpawnedEntity = {}
SpawnedEntity.__index = SpawnedEntity

---@param handle integer
---@param name string
---@param modelHash integer
---@param type EntityType
---@param alpha? number
---@param coords vec3
---@param rotation vec3
function SpawnedEntity:New(handle, name, modelHash, type, alpha, coords, rotation)
    local instance = setmetatable({}, SpawnedEntity)
    instance.handle = handle
    instance.name = name
    instance.modelHash = modelHash
    instance.type = type
    instance.properties = {}
    instance.alpha = alpha or 255
    instance.isAttached = false
    instance.isPlayer = false
    instance.parent = {}
    instance.children = {}
    instance.position = coords
    instance.rotation = rotation
    return instance
end

---@return boolean
function SpawnedEntity:IsParent()
    return self.children and next(self.children) ~= nil
end

function SpawnedEntity:AsTable()
    local childTables = {}
    for _, child in ipairs(self.children or {}) do
        table.insert(childTables, child:AsTable())
    end

    return {
        name = self.name,
        handle = self.handle,
        modelHash = self.modelHash,
        type = self.type,
        alpha = self.alpha,
        isAttached = self.isAttached,
        isPlayer = self.isPlayer,
        properties = self.properties,
        parent_bone = self.parent_bone,
        attach_pos = self.attach_pos,
        attach_rot = self.attach_rot,
        isForged = true,
        children = childTables,
    }
end

---@param data table
---@return SpawnedEntity
function SpawnedEntity:FromTable(data)
    local instance = SpawnedEntity:New(
        0,
        data.name,
        data.modelHash,
        data.type,
        data.alpha or 255,
        data.coordinates or vec3:zero(),
        data.rotation or vec3:zero()
    )

    instance.properties  = data.properties or {}
    instance.attach_pos  = data.attach_pos or vec3:zero()
    instance.attach_rot  = data.attach_rot or vec3:zero()
    instance.parent_bone = data.parent_bone
    instance.isPlayer    = data.isPlayer
    instance.isAttached  = data.isAttached
    instance.isForged    = true

    return instance
end


-----------------------------------------------------
-- EntityForge Class
-----------------------------------------------------
-- *Spawn, merge, create.*
---@class EntityForge
---@field PlayerEntity SpawnedEntity
---@field AllEntities SpawnedEntity[]
---@field EntityMap SpawnedEntity[]
---@field SpawnedObjects SpawnedEntity[]
---@field SpawnedVehicles SpawnedEntity[]
---@field SpawnedPeds SpawnedEntity[]
---@field WorldEntities SpawnedEntity[]
---@field childCandidates SpawnedEntity[]
---@field parentCandidates SpawnedEntity[]
---@field currentParent SpawnedEntity
---@field lastParent SpawnedEntity
---@field GrabbedEntity SpawnedEntity
---@field EntityGunEnabled boolean
---@field EntityGunDistance integer
---@field EntityGunRotMult integer EntityGun's rotation multiplier
EntityForge = {}
EntityForge.__index = EntityForge
EntityForge.PlayerEntity = nil
EntityForge.GrabbedEntity = nil
EntityForge.AllEntities = {}
EntityForge.EntityMap = {}
EntityForge.SpawnedObjects = {}
EntityForge.SpawnedVehicles = {}
EntityForge.SpawnedPeds = {}
EntityForge.WorldEntities = {}
EntityForge.childCandidates = {}
EntityForge.parentCandidates = {}
EntityForge.EntityGunEnabled = false
EntityForge.EntityGunDistance = 7


---@param entity integer
function EntityForge:RegisterEntity(entity)
    Decorator:RegisterEntity(entity, "EntityForge", true)
end

---@param entity integer
function EntityForge:UnregisterEntity(entity)
    Decorator:RemoveEntity(entity, "EntityForge")
end

---@return SpawnedEntity
function EntityForge:GetPlayerInstance()
    if not self.PlayerEntity then
        self.PlayerEntity = SpawnedEntity:New(
            Self.GetPedID(),
            "You",
            -1, TYPE_PED,
            255,
            Self.GetPos(),
            Self.GetRot()
        )
        self.PlayerEntity.isPlayer = true
    end

    self.PlayerEntity.handle = Self.GetPedID()
    return self.PlayerEntity
end

---@return boolean
function EntityForge:IsEmpty()
    return next(self.EntityMap) == nil
end

---@param handle integer
---@return SpawnedEntity | nil
function EntityForge:FindEntity(handle)
    return self.EntityMap[handle]
end

---@param entity SpawnedEntity
function EntityForge:GetCategoryFromType(entity)
    if entity.type == TYPE_OBJECT then
        return "objects"
    elseif entity.type == TYPE_PED then
        return "peds"
    elseif entity.type == TYPE_VEHICLE then
        return "vehicles"
    else
        return "Unknown"
    end
end

---@param entity SpawnedEntity
---@param isWorldEntity? boolean
function EntityForge:AddEntity(entity, isWorldEntity)
    if not self:FindEntity(entity.handle) then
        if (
            not entity.isForged and not
            entity.isPlayer and
            entity.handle ~= Self.GetPedID()
        ) then

            if entity.type == TYPE_OBJECT then
                table.insert(self.SpawnedObjects, entity)
            end

            if entity.type == TYPE_VEHICLE then
                table.insert(self.SpawnedVehicles, entity)
            end

            if entity.type == TYPE_PED then
                table.insert(self.SpawnedPeds, entity)
            end

            if isWorldEntity then
                table.insert(self.WorldEntities, entity)
                entity.isWorldEntity = true
            end
        end

        table.insert(self.AllEntities, entity)
        self.EntityMap[entity.handle] = entity
        self:RegisterEntity(entity)
        self:UpdateAttachmentCandidates()
    end
end

---@param handle SpawnedEntity
function EntityForge:RemoveEntityByHandle(handle)
    for _, list in pairs({self.AllEntities, self.SpawnedObjects, self.SpawnedVehicles, self.SpawnedPeds}) do
        for i = #list, 1, -1 do
            if (list[i].handle == handle) or (list[i].modelHash == -1) then
                table.remove(list, i)
            end
        end
    end

    if hanlde == Self.GetPlayerID() then
        self.PlayerEntity = nil
    end

    self:UnregisterEntity(entity)
    self:UpdateAttachmentCandidates()
    self.EntityMap[handle] = nil
end

---@param entity SpawnedEntity
---@param deltaTime integer
function EntityForge:MoveEntityWithGun(entity, deltaTime)
    local v_CamRot        = CAM.GET_GAMEPLAY_CAM_ROT(2)
    local v_CamPos        = CAM.GET_GAMEPLAY_CAM_COORD()
    local v_Direction     = Lua_fn.RotToDir(v_CamRot)
    local v_SelfPos       = Self.GetPos()
    local i_CamHeading    = CAM.GET_GAMEPLAY_CAM_ROT(2).z
    local i_EntityHeading = ENTITY.GET_ENTITY_HEADING(entity.handle)
    local i_HeadingDiff   = math.abs(i_CamHeading - i_EntityHeading)
    local i_MvmtSpeed     = 10
    local i_YawMultiplier = 1
    local i_Timedelta     = math.min(1, deltaTime * i_MvmtSpeed)

    local v_TargetPos = vec3:new(
        v_CamPos.x + v_Direction.x * self.EntityGunDistance,
        v_CamPos.y + v_Direction.y * self.EntityGunDistance,
        v_CamPos.z + v_Direction.z * self.EntityGunDistance
    )

    local _, f_GroundZ = MISC.GET_GROUND_Z_FOR_3D_COORD(
        v_SelfPos.x,
        v_SelfPos.y,
        v_SelfPos.z,
        f_GroundZ,
        false,
        false
    )

    if not entity.last_pos then
        entity.last_pos = Game.GetEntityCoords(entity.handle, false)
    end

    entity.last_pos = entity.last_pos:lerp(v_TargetPos, i_Timedelta)
    entity.position = entity.last_pos
    entity.target_pos = v_TargetPos
    self.EntityGunDistance = math.max(1.0, math.min(self.EntityGunDistance, 50.0))

    if entity.last_pos.z < f_GroundZ + 0.5 then
        entity.last_pos.z = f_GroundZ + 0.5
    end

    Game.SetEntityCoordsNoOffset(entity.handle, entity.last_pos)
    Game.World.MarkSelectedEntity(entity.handle, -0.1)

    if i_HeadingDiff > 180 then
        i_HeadingDiff = 360 - i_HeadingDiff
    end

    if i_HeadingDiff > 90 then
        i_YawMultiplier = -1
    end

    if SS.IsKeyPressed("PAGE_UP") then
        self.EntityGunDistance = self.EntityGunDistance + 0.1
    end

    if SS.IsKeyPressed("PAGE_DOWN") then
        self.EntityGunDistance = self.EntityGunDistance - 0.1
    end

    if SS.IsKeyJustPressed("VK_ADD") or SS.IsKeyJustPressed("MOUSE5") then
        self.EntityGunRotMult = self.EntityGunRotMult == 1 and 10 or self.EntityGunRotMult + 10
        YimToast:ShowMessage(
            "EntityForge",
            string.format(
                "Rotation multiplier set to %d",
                self.EntityGunRotMult
            )
        )
    end

    if SS.IsKeyJustPressed("VK_SUBTRACT") or SS.IsKeyJustPressed("MOUSE4") then
        self.EntityGunRotMult = self.EntityGunRotMult <= 10 and 1 or self.EntityGunRotMult - 10
        YimToast:ShowMessage(
            "EntityForge",
            string.format(
                "Rotation multiplier set to %d",
                self.EntityGunRotMult
            )
        )
    end

    if SS.IsKeyPressed("Numpad4") then
        self:RotateEntity(
            entity,
            0.0,
            -0.1 * i_YawMultiplier * self.EntityGunRotMult,
            0.0
        )
    end

    if SS.IsKeyPressed("Numpad6") then
        self:RotateEntity(
            entity,
            0.0,
            0.1 * i_YawMultiplier * self.EntityGunRotMult,
            0.0
        )
    end

    if SS.IsKeyPressed("Numpad8") then
        self:RotateEntity(entity, 0.1 * self.EntityGunRotMult, 0.0, 0.0)
    end

    if SS.IsKeyPressed("Numpad2") then
        self:RotateEntity(entity, -0.1 * self.EntityGunRotMult, 0.0, 0.0)
    end

    if SS.IsKeyPressed("Numpad1") then
        self:RotateEntity(entity, 0.0, 0.0, -0.1 * self.EntityGunRotMult)
    end

    if SS.IsKeyPressed("Numpad3") then
        self:RotateEntity(entity, 0.0, 0.0, 0.1 * self.EntityGunRotMult)
    end

end

-- Grabs and manipulates world entities.
function EntityForge:EntityGun()
    if PLAYER.IS_PLAYER_FREE_AIMING(Self.GetPlayerID()) then
        local i_AimedAtEntity = Self.GetEntityInCrosshairs(true)
        local existing_entity

        if ENTITY.IS_ENTITY_DEAD(i_AimedAtEntity, false) or SS.IsScriptEntity(i_AimedAtEntity) then
            i_AimedAtEntity = nil
        end

        if i_AimedAtEntity and ENTITY.DOES_ENTITY_EXIST(i_AimedAtEntity) and not SS.IsScriptEntity(i_AimedAtEntity) then
            existing_entity = EntityForge:FindEntity(i_AimedAtEntity)
        end

        if i_AimedAtEntity then
            SS.debug(tostring(SS.IsScriptEntity(i_AimedAtEntity)))
        end

        if self.GrabbedEntity and PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) then
            local v_SelfPos = Self.GetPos()
            local _, f_ScreenX, f_ScreenY = HUD.GET_HUD_SCREEN_POSITION_FROM_WORLD_POSITION(
                v_SelfPos.x,
                v_SelfPos.y,
                v_SelfPos.z,
                f_ScreenX,
                f_ScreenY
            )

            if self.GrabbedEntity.isWorldEntity and not self.GrabbedEntity.isForged then
                Game.DrawText(
                    vec2:new(f_ScreenX + 0.31, f_ScreenY - 0.23),
                    "- Press [E] to release the entity from the pool.",
                    Col(255, 255, 255, 220),
                    vec2:new(0.2, 0.38),
                    4
                )
            end

            Game.DrawText(
                vec2:new(f_ScreenX + 0.31, f_ScreenY - 0.2),
                "- Use [Numpad 1 - 3  |  4 - 6  |  2 - 8] to rotate.",
                Col(255, 255, 255, 220),
                vec2:new(0.2, 0.38),
                4
            )

            Game.DrawText(
                vec2:new(f_ScreenX + 0.31, f_ScreenY - 0.17),
                "- Use [Numpad +] and [Numpad -] to adjust rotation speed.",
                Col(255, 255, 255, 220),
                vec2:new(0.2, 0.38),
                4
            )

            Game.DrawText(
                vec2:new(f_ScreenX + 0.31, f_ScreenY - 0.14),
                "- Use [Page Up] and [Page Down] to adjust distance.",
                Col(255, 255, 255, 220),
                vec2:new(0.2, 0.38),
                4
            )

            Game.DrawText(
                vec2:new(f_ScreenX + 0.31, f_ScreenY - 0.11),
                "- Press [F] to save this entity's model to favorites.",
                Col(255, 255, 255, 220),
                vec2:new(0.2, 0.38),
                4
            )

            Game.DrawText(
                vec2:new(f_ScreenX + 0.31, f_ScreenY - 0.08),
                "- Press [Back Space] to delete this entity.",
                Col(255, 255, 255, 220),
                vec2:new(0.2, 0.38),
                4
            )

            EntityForge:MoveEntityWithGun(self.GrabbedEntity, Self.GetDeltaTime())
        end

        if self.GrabbedEntity then
            if self.GrabbedEntity.isWorldEntity and SS.IsKeyJustPressed("E") and not self.GrabbedEntity.isForged then
                YimToast:ShowMessage(
                    "EntityForge",
                    string.format(
                        "%s [%d] was removed from the entity pool.",
                        self.GrabbedEntity.name,
                        self.GrabbedEntity.handle
                    )
                )

                self:ReleaseWorldEntity(self.GrabbedEntity)
                self.GrabbedEntity = nil
            end

            if SS.IsKeyJustPressed("BACKSPACE")
            and not self.GrabbedEntity.isForged
            and not SS.IsScriptEntity(self.GrabbedEntity.handle) then
                self:DeleteEntity(self.GrabbedEntity)
                self.GrabbedEntity = nil
            end

            if SS.IsKeyJustPressed("F") then
                if self:IsModelInFavorites(self.GrabbedEntity.modelHash) then
                    YimToast:ShowError(
                        "EntityForge",
                        "This model is already saved. Please choose a different one!"
                    )
                else
                    table.insert(
                        favorite_entities,
                        {
                            name = string.format(
                                "%s [%s]",
                                self.GrabbedEntity.name,
                                self.GrabbedEntity.handle
                            ),
                            modelHash = self.GrabbedEntity.modelHash,
                            type = self.GrabbedEntity.type
                        }
                    )
                    CFG:SaveItem("favorite_entities", favorite_entities)
                    YimToast:ShowSuccess(
                        "EntityForge",
                        string.format(
                            "Added %s [%s] to favorites.",
                            self.GrabbedEntity.name,
                            self.GrabbedEntity.handle
                        )
                    )
                end
            end

            if PAD.IS_DISABLED_CONTROL_JUST_RELEASED(0, 24) then
                ENTITY.FREEZE_ENTITY_POSITION(self.GrabbedEntity.handle, false)
                ENTITY.SET_ENTITY_COLLISION(self.GrabbedEntity.handle, true, true)
                PHYSICS.ACTIVATE_PHYSICS(self.GrabbedEntity.handle)

                if self.GrabbedEntity.type == TYPE_OBJECT then
                    OBJECT.SET_ACTIVATE_OBJECT_PHYSICS_AS_SOON_AS_IT_IS_UNFROZEN(self.GrabbedEntity.handle, true)
                end

                self.GrabbedEntity = nil
            end
        end

        if existing_entity then
            if not existing_entity.isForged then
                if not PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) then
                    Game.ShowButtonPrompt(
                        "Hold ~INPUT_ATTACK~ to move the entity with your mouse."
                    )
                end

                if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 24) then
                    self.GrabbedEntity = existing_entity
                    local v_SelfPos = Self.GetPos()
                    local v_EntityPos = Game.GetEntityCoords(self.GrabbedEntity.handle, false)
                    self.EntityGunDistance = v_SelfPos:distance(v_EntityPos)
                    ENTITY.SET_ENTITY_COLLISION(self.GrabbedEntity.handle, false, true)

                    if self.GrabbedEntity and self.GrabbedEntity.last_pos then
                        self.GrabbedEntity.last_pos = nil -- prevent the entity from jumping back to the last position we dropped/released it from when we try to move it again
                    end
                end
            end
        else
            if i_AimedAtEntity and not self.GrabbedEntity then
                Game.ShowButtonPrompt("Press ~INPUT_PICKUP~ to add the entity to the forge pool.")
            end

            if SS.IsKeyJustPressed("E") then
                local i_EntityType = self:GetTypeFromGameType(i_AimedAtEntity)

                if i_EntityType then
                    local s_EntityName
                    local i_ModelHash = Game.GetEntityModel(i_AimedAtEntity)

                    if i_EntityType == TYPE_OBJECT then
                        s_EntityName = "World Object"
                    end

                    if i_EntityType == TYPE_PED then
                        s_EntityName = "World Ped"
                        TASK.CLEAR_PED_TASKS_IMMEDIATELY(i_AimedAtEntity)
                        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_AimedAtEntity, true)
                        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_AimedAtEntity, true)
                        PED.SET_PED_KEEP_TASK(i_AimedAtEntity, false)
                        TASK.TASK_STAND_STILL(i_AimedAtEntity, -1)
                    end

                    if i_EntityType == TYPE_VEHICLE then
                        s_EntityName = "World Vehicle (" .. vehicles.get_vehicle_display_name(i_ModelHash) .. ")"
                        local t_Occupants = Game.Vehicle.GetOccupants(i_AimedAtEntity)
                        if #t_Occupants > 0 then
                            for _, ped in ipairs(t_Occupants) do
                                if not PED.IS_PED_A_PLAYER(ped) then
                                    TASK.TASK_LEAVE_VEHICLE(ped, i_AimedAtEntity, 4160)
                                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
                                end
                            end
                        end
                    end

                    ENTITY.SET_ENTITY_INVINCIBLE(i_AimedAtEntity, true)

                    local world_entity = SpawnedEntity:New(
                        i_AimedAtEntity,
                        s_EntityName,
                        i_ModelHash,
                        i_EntityType,
                        ENTITY.GET_ENTITY_ALPHA(i_AimedAtEntity),
                        Game.GetEntityCoords(i_AimedAtEntity, false),
                        Game.GetEntityRotation(i_AimedAtEntity)
                    )

                    EntityForge:ResetEntityPosition(
                        world_entity,
                        ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
                            Self.GetPedID(),
                            0,
                            5,
                            0
                        )
                    )

                    EntityForge:AddEntity(world_entity, true)
                    YimToast:ShowMessage(
                        "EntityForge",
                        string.format(
                            "Added '%s' [%d] to the entity pool.",
                            s_EntityName,
                            i_AimedAtEntity
                        )
                    )
                end
            end
        end
    else
        if self.GrabbedEntity then
            ENTITY.SET_ENTITY_COLLISION(self.GrabbedEntity.handle, true, true)
        end
    end
end

---@param entity SpawnedEntity
function EntityForge:ReleaseWorldEntity(entity)
    if not entity then
        return
    end

    ENTITY.SET_ENTITY_COLLISION(entity.handle, true, true)
    ENTITY.SET_ENTITY_INVINCIBLE(entity.handle, false)
    PHYSICS.ACTIVATE_PHYSICS(entity.handle)

    if entity.type == TYPE_PED then
        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity.handle, false)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entity.handle, false)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(entity.handle)
        ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(entity.handle)
    end

    if entity.type == TYPE_OBJECT then
        OBJECT.SET_ACTIVATE_OBJECT_PHYSICS_AS_SOON_AS_IT_IS_UNFROZEN(entity.handle, true)
    end

    self:RemoveEntityByHandle(entity.handle)
end

---@param entity integer
function EntityForge:GetTypeFromGameType(entity)
    local game_type = Game.GetEntityType(entity)

    if not game_type or game_type == 0 then
        return
    end

    if game_type == 1 then
        return TYPE_PED
    end

    if game_type == 2 then
        return TYPE_VEHICLE
    end

    if game_type == 3 then
        return TYPE_OBJECT
    end
end

---@param i_ModelHash integer
---@param s_Name string
---@param i_EntityType EntityType
---@param v_Coords vec3
---@param i_PedType? integer
---@param i_Alpha? integer
---@param b_IsForged? boolean
---@return integer | nil
function EntityForge:CreateEntity(i_ModelHash, s_Name, i_EntityType, v_Coords, i_PedType, i_Alpha, b_IsForged)
    local i_Handle   = nil
    local _, groundZ = MISC.GET_GROUND_Z_EXCLUDING_OBJECTS_FOR_3D_COORD(v_Coords.x, v_Coords.y, v_Coords.z, groundZ, false, false)
    local v_SpawnPos = vec3:new(v_Coords.x, v_Coords.y, groundZ)

    if i_EntityType == TYPE_OBJECT then
        i_Handle = Game.CreateObject(
            i_ModelHash,
            v_SpawnPos,
            true,
            false,
            true,
            true,
            Self.GetHeading()
        )
    elseif i_EntityType == TYPE_VEHICLE then
        i_Handle = Game.CreateVehicle(
            i_ModelHash,
            v_SpawnPos,
            Self.GetHeading() - 90,
            true,
            false
        )
    elseif i_EntityType == TYPE_PED then
        i_Handle = Game.CreatePed(
            i_ModelHash,
            v_SpawnPos,
            Self.GetHeading() - 90,
            true,
            false
        )

        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_Handle, true)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_Handle, true)
        PED.SET_PED_KEEP_TASK(i_Handle, false)
        TASK.TASK_STAND_STILL(i_Handle, -1)
    end

    if not i_Handle or (i_Handle <= 0) or not ENTITY.DOES_ENTITY_EXIST(i_Handle) then
        YimToast:ShowError(
            "EntityForge",
            ("Failed to create entity:\n[%s]"):format(s_Name)
        )
        return
    end

    if i_Alpha then
        ENTITY.SET_ENTITY_ALPHA(i_Handle, i_Alpha, false)
    end

    if not b_IsForged then
        self:AddEntity(
            SpawnedEntity:New(
                i_Handle,
                s_Name,
                i_ModelHash,
                i_EntityType,
                i_Alpha,
                Game.GetEntityCoords(i_Handle, false),
                Game.GetEntityRotation(i_Handle, 2)
            )
        )
    end

    self:RegisterEntity(i_Handle)
    return i_Handle
end

---@param entity SpawnedEntity
function EntityForge:DeleteEntity(entity)
    if entity.children and #entity.children > 0 then
        for i = #entity.children, 1, -1 do
            self:DetachEntity(entity, entity.children[i])
            self:UnregisterEntity(entity.handle)
            table.remove(entity.children, i)
        end
    end

    if entity.parent and (entity.parent.modelHash == -1) then
        for i = #self.PlayerEntity.children, 1, -1 do
            if entity.handle == self.PlayerEntity.children[i].handle then
                self:UnregisterEntity(entity.handle)
                table.remove(self.PlayerEntity.children, i)
            end
        end
    end

    Game.DeleteEntity(entity.handle, self:GetCategoryFromType(entity))
    self:UnregisterEntity(entity.handle)
    self:RemoveEntityByHandle(entity.handle)

    if self.currentParent then
        if self.currentParent.handle ~= self.lastParent.handle then
            self.currentParent = self.lastParent
        elseif #self.currentParent.children == 0 then
            self.currentParent = nil
            self.lastParent = nil
        end
    end
end

---@param abomination table | SpawnedEntity
function EntityForge:SpawnSavedAbomination(abomination)
    script.run_in_fiber(function()
        local function recurse(entityData, parent)
            local entity

            if not entityData.isPlayer and entityData.modelHash ~= -1 then
                local handle = self:CreateEntity(
                    entityData.modelHash,
                    entityData.name,
                    entityData.type,
                    ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
                        Self.GetPedID(),
                        math.random(1, 30),
                        math.random(1, 30),
                        -50
                    ),
                    nil,
                    entityData.alpha,
                    true
                )

                if handle then
                    if entityData.properties then
                        if entityData.type == TYPE_VEHICLE then
                            Game.Vehicle.ApplyVehicleMods(handle, entityData.properties)
                        end

                        if entityData.type == TYPE_PED then
                            if entityData.properties.components then
                                Game.ApplyPedComponents(
                                    handle,
                                    entityData.properties.components
                                )
                            end

                            if entityData.properties.action then
                                if entityData.properties.action.scenario then
                                    while not PED.IS_PED_USING_ANY_SCENARIO(handle) do
                                        TASK.TASK_START_SCENARIO_IN_PLACE(
                                            handle,
                                            entityData.properties.action.scenario,
                                            -1,
                                            false
                                        )
                                        coroutine.yield()
                                    end
                                end
                            end
                        end
                    end

                    entity = SpawnedEntity:New(
                        handle,
                        entityData.name,
                        entityData.modelHash,
                        entityData.type,
                        entityData.alpha,
                        ENTITY.GET_ENTITY_COORDS(handle, false),
                        ENTITY.GET_ENTITY_ROTATION(handle, 2)
                    )

                    ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(handle)
                end
            else
                entity = self:GetPlayerInstance()
                entity.name = entityData.name
            end

            entity.properties = entityData.properties or {}
            entity.isForged = true

            if parent and not entity.isPlayer then
                self:AttachEntity(
                    entity,
                    parent,
                    entityData.parent_bone,
                    entityData.attach_pos,
                    entityData.attach_rot
                )
            end

            for _, childData in ipairs(entityData.children or {}) do
                recurse(childData, entity)
            end

            return entity
        end

        local rootEntity = recurse(abomination, nil)
        if not rootEntity.isPlayer then
            Game.SetEntityCoords(
                rootEntity.handle,
                ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(Self.GetPedID(), 1, 5, 0)
            )
        end

        table.insert(self.AllEntities, rootEntity)
        self.EntityMap[rootEntity.handle] = rootEntity
    end)
end

---@param abomination SpawnedEntity
function EntityForge:DeleteAbomination(abomination)
    if abomination.children then
        for _, child in ipairs(abomination.children) do
            Game.DeleteEntity(child.handle, self:GetCategoryFromType(child))
            self:RemoveEntityByHandle(child.handle)
        end
    end

    if self.currentParent and (self.currentParent.handle == abomination.handle) then
        if self.currentParent.handle ~= self.lastParent.handle then
            self.currentParent = self.lastParent
        else
            self.currentParent = nil
            self.lastParent = nil
        end
    end

    self:RemoveEntityByHandle(abomination.handle)
    Game.DeleteEntity(abomination.handle, self:GetCategoryFromType(abomination))
end

---@param selectedChild? any
function EntityForge:UpdateAttachmentCandidates(selectedChild)
    self.parentCandidates = {}
    self.childCandidates = {}

    if self:IsEmpty() then
        return
    end

    for _, entity in ipairs(self.AllEntities) do
        if not entity.isForged and not entity.isPlayer then
            local isParentless = not entity.parent or not entity.parent[1]

            if not entity.isAttached then
                table.insert(self.childCandidates, entity)
            end

            if isParentless and (entity ~= selectedChild) and not entity.isAttached then
                table.insert(self.parentCandidates, entity)
            end
        end
    end

    if selectedChild and (#self.parentCandidates > 0) then
        for i = #self.parentCandidates, 1, -1 do
            if self.parentCandidates[i].handle == selectedChild.handle then
                table.remove(self.parentCandidates, i)
            end
        end
    end
end


---@param parent SpawnedEntity
---@param child SpawnedEntity
---@param unk_bone string | number
---@param v_AttachPos vec3
---@param v_AttachRot vec3
function EntityForge:AttachEntity(child, parent, unk_bone, v_AttachPos, v_AttachRot)
    if (child.handle == parent.handle) or child.isPlayer then
        UI.WidgetSound("Error")
        return
    end

    if not ENTITY.DOES_ENTITY_EXIST(child.handle) then
        UI.WidgetSound("Error")
        YimToast:ShowError(
            "EntityForge",
            "This entity no longer exists in the game world and will be removed from the forge."
        )
        self:DeleteEntity(child)
        return
    end

    if not ENTITY.DOES_ENTITY_EXIST(parent.handle) then
        UI.WidgetSound("Error")
        YimToast:ShowError(
            "EntityForge",
            "The parent entity no longer exists in the game world and will be removed from the forge."
        )
        self:DeleteEntity(parent)
        return
    end

    UI.WidgetSound("Select")
    local i_BoneIndex = 0
    local parent_handle

    if parent.isPlayer then
        parent_handle = Self.GetPedID()
    else
        parent_handle = parent.handle
    end

    if parent.type == TYPE_OBJECT then
        i_BoneIndex = 0
    elseif parent.type == TYPE_VEHICLE and type(unk_bone) == "string" then
        i_BoneIndex = Game.GetEntityBoneIndexByName(parent_handle, unk_bone)
    elseif parent.type == TYPE_PED and type(unk_bone) == "number" then
        i_BoneIndex = Game.GetPedBoneIndex(parent_handle, unk_bone)
    end

    ENTITY.ATTACH_ENTITY_TO_ENTITY(
        child.handle,
        parent_handle,
        i_BoneIndex,
        v_AttachPos.x,
        v_AttachPos.y,
        v_AttachPos.z,
        v_AttachRot.x,
        v_AttachRot.y,
        v_AttachRot.z,
        false,
        true,
        false,
        ENTITY.IS_ENTITY_A_PED(child.handle),
        2,
        true,
        1
    )

    if child.type == TYPE_PED then
        ENTITY.SET_ENTITY_INVINCIBLE(child.handle, true)
        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(child.handle, true)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(child.handle, true)
        PED.SET_PED_KEEP_TASK(child.handle, false)
        TASK.TASK_STAND_STILL(child.handle, -1)
    end

    child.parent = parent
    child.parent_bone = unk_bone
    child.attach_pos = v_AttachPos
    child.attach_rot = v_AttachRot

    if not child.isAttached then
        child.isAttached = true
        table.insert(parent.children, child)
    end

    self.currentParent = parent

    if not self.lastParent then
        self.lastParent = parent
    end

    self:UpdateAttachmentCandidates(child)
end

---@param attachment? SpawnedEntity
---@param x float
---@param y float
---@param z float
function EntityForge:MoveAttachment(attachment, x, y ,z)
    if not attachment then
        return
    end

    if attachment.isAttached and attachment.parent then
        local parent_handle
        local i_BoneIndex = 0

        if attachment.parent.isPlayer then
            parent_handle = Self.GetPedID()
        else
            parent_handle = attachment.parent.handle
        end

        if attachment.parent.type == TYPE_OBJECT then
            i_BoneIndex = 0
        elseif attachment.parent.type == TYPE_VEHICLE and type(attachment.parent_bone) == "string" then
            i_BoneIndex = Game.GetEntityBoneIndexByName(parent_handle, attachment.parent_bone)
        elseif attachment.parent.type == TYPE_PED and type(attachment.parent_bone) == "number" then
            i_BoneIndex = Game.GetPedBoneIndex(parent_handle, attachment.parent_bone)
        end

        attachment.attach_pos.x = attachment.attach_pos.x + x
        attachment.attach_pos.y = attachment.attach_pos.y + y
        attachment.attach_pos.z = attachment.attach_pos.z + z

        ENTITY.ATTACH_ENTITY_TO_ENTITY(
            attachment.handle,
            parent_handle,
            i_BoneIndex,
            attachment.attach_pos.x,
            attachment.attach_pos.y,
            attachment.attach_pos.z,
            attachment.attach_rot.x,
            attachment.attach_rot.y,
            attachment.attach_rot.z,
            false,
            false,
            false,
            false,
            2,
            true,
            1
        )
    end
end

---@param attachment SpawnedEntity
---@param x float
---@param y float
---@param z float
function EntityForge:RotateAttachment(attachment, x, y ,z)
    if not attachment then
        return
    end

    if attachment.isAttached and attachment.parent then
        local parent_handle
        local i_BoneIndex = 0

        if attachment.parent.isPlayer then
            parent_handle = Self.GetPedID()
        else
            parent_handle = attachment.parent.handle
        end

        if attachment.parent.type == TYPE_OBJECT then
            i_BoneIndex = 0
        elseif attachment.parent.type == TYPE_VEHICLE and type(attachment.parent_bone) == "string" then
            i_BoneIndex = Game.GetEntityBoneIndexByName(parent_handle, attachment.parent_bone)
        elseif attachment.parent.type == TYPE_PED and type(attachment.parent_bone) == "number" then
            i_BoneIndex = Game.GetPedBoneIndex(parent_handle, attachment.parent_bone)
        end

        attachment.attach_rot.x = attachment.attach_rot.x + x
        attachment.attach_rot.y = attachment.attach_rot.y + y
        attachment.attach_rot.z = attachment.attach_rot.z + z

        ENTITY.ATTACH_ENTITY_TO_ENTITY(
            attachment.handle,
            parent_handle,
            i_BoneIndex,
            attachment.attach_pos.x,
            attachment.attach_pos.y,
            attachment.attach_pos.z,
            attachment.attach_rot.x,
            attachment.attach_rot.y,
            attachment.attach_rot.z,
            false,
            false,
            false,
            true,
            2,
            true,
            1
        )
    end
end

---@param entity SpawnedEntity
---@param x float
---@param y float
---@param z float
function EntityForge:MoveEntity(entity, x, y ,z)
    if not entity or ENTITY.IS_ENTITY_ATTACHED(entity.handle) then
        return
    end

    entity.position.x = entity.position.x + x
    entity.position.y = entity.position.y + y
    entity.position.z = entity.position.z + z

    Game.SetEntityCoords(entity.handle, entity.position)
end

---@param entity SpawnedEntity
---@param x float
---@param y float
---@param z float
function EntityForge:RotateEntity(entity, x, y, z)
    if not entity or ENTITY.IS_ENTITY_ATTACHED(entity.handle) then
        return
    end

    entity.rotation.x = (entity.rotation.x + x) % 360
    entity.rotation.y = math.max(-85.0, math.min(entity.rotation.y + y, 85.0)) -- fuck you. roll on deez nutts
    entity.rotation.z = (entity.rotation.z + z) % 360

    if entity.rotation.x < 0 then
        entity.rotation.x = entity.rotation.x + 360
    end

    if entity.rotation.z < 0 then
        entity.rotation.z = entity.rotation.z + 360
    end

    ENTITY.SET_ENTITY_ROTATION(
        entity.handle,
        entity.rotation.x,
        entity.rotation.y,
        entity.rotation.z,
        2,
        true
    )
end

---@param entity SpawnedEntity
---@param position? vec3
function EntityForge:ResetEntityPosition(entity, position)
    script.run_in_fiber(function()
        if not position then
            position = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity.handle, 1, 2, 0)
        end

        Game.SetEntityCoordsNoOffset(entity.handle, position)
        entity.position = position
        entity.rotation = ENTITY.GET_ENTITY_ROTATION(entity.handle, 2)

        if entity.type == TYPE_OBJECT then
            OBJECT.PLACE_OBJECT_ON_GROUND_OR_OBJECT_PROPERLY(entity.handle)
        elseif entity.type == TYPE_VEHICLE then
            VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(entity.handle, 5.0)
        end
    end)
end

---@param parent SpawnedEntity
---@param child SpawnedEntity
function EntityForge:DetachEntity(parent, child)
    script.run_in_fiber(function(detach)
        if ENTITY.DOES_ENTITY_EXIST(child.handle) and ENTITY.IS_ENTITY_ATTACHED(child.handle) then
            ENTITY.DETACH_ENTITY(child.handle, true, false)
            self:ResetEntityPosition(child)
            detach:sleep(200)
        end

        if child.type == TYPE_PED then
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(child.handle)
            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(child.handle, true)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(child.handle, true)
            PED.SET_PED_KEEP_TASK(child.handle, false)
            TASK.TASK_STAND_STILL(child.handle, -1)
        end

        for i, c in ipairs(parent.children or {}) do
            if c == child then
                table.remove(parent.children, i)
                break
            end
        end

        if not parent.children or #parent.children == 0 then
            parent.children = {}
            parent.isForged = false
        end

        child.isAttached = false
        child.attach_pos = nil
        child.attach_rot = nil
        child.parent = nil
        child.parent_bone = nil
        child.isForged = false
        self:AddEntity(child)

        if parent.handle ~= Self.GetPedID() and not parent.isPlayer then
            if self.currentParent ~= parent then
                parent.isForged = false
                self:AddEntity(parent)
            end
        end

        if self.currentParent and #self.currentParent.children == 0 then
            if parent.modelHash == -1 and (#parent.children == 0) then
                self:RemoveEntityByHandle(parent.handle)
                self.PlayerEntity = nil
            end
            self.currentParent = self.lastParent
        end

        self:UpdateAttachmentCandidates(child)
    end)
end

---@param parent? SpawnedEntity
function EntityForge:DetachAllEntities(parent)
    if not parent then
        if self.currentParent then
            parent = self.currentParent
        elseif self.lastParent then
            parent = self.lastParent
        else
            return
        end
    end

    script.run_in_fiber(function(detachall)
        if not parent.children or #parent.children == 0 then
            parent.children = {}
            parent.isForged = false
        else
            local f_InitialOffset = 2.0

            for i = #parent.children, 1, -1 do
                if ENTITY.IS_ENTITY_ATTACHED(parent.children[i].handle) then
                    ENTITY.DETACH_ENTITY(parent.children[i].handle, true, false)
                end

                detachall:sleep(50)
                self:ResetEntityPosition(
                    parent.children[i],
                    ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
                        parent.children[i].handle,
                        1,
                        f_InitialOffset,
                        0
                    )
                )
                f_InitialOffset = f_InitialOffset + 1.0

                parent.children[i].isAttached = false
                parent.children[i].attach_pos = nil
                parent.children[i].attach_rot = nil
                parent.children[i].parent = nil
                parent.children[i].parent_bone = nil
                parent.children[i].isForged = false

                self:AddEntity(parent.children[i])
                table.remove(parent.children, i)
            end
        end

        if parent.handle ~= Self.GetPedID() and not parent.isPlayer then
            if self.currentParent ~= parent then
                parent.isForged = false
                self:AddEntity(parent)
            end
        end

        if parent.modelHash == -1 and (#parent.children == 0) then
            self:RemoveEntityByHandle(parent.handle)
            self.PlayerEntity = nil
        end

        if self.currentParent then
            if self.currentParent.handle ~= self.lastParent.handle then
                self.currentParent = self.lastParent
            elseif #self.currentParent.children == 0 then
                self.currentParent = nil
                self.lastParent = nil
            end
        end

        self:UpdateAttachmentCandidates()
    end)
end

function EntityForge:Cleanup()
    if self:IsEmpty() then
        return
    end

    local to_remove = {}

    for _, entity in pairs(self.EntityMap) do
        if entity.isForged then
            self:DeleteAbomination(entity)
        else
            self:DeleteEntity(entity)
        end
        table.insert(to_remove, entity)
    end

    script.run_in_fiber(function(cleanup)
        cleanup:sleep(200)

        for _, entity in ipairs(to_remove) do
            self:RemoveEntityByHandle(entity.handle)
        end

        self:UpdateAttachmentCandidates()
    end)
end


---@param reference? table
function EntityForge:ForceCleanup(reference)
    if not reference then
        reference = self.EntityMap
    end

    if #self.WorldEntities > 0 then
        for _, entity in pairs(self.WorldEntities) do
            if ENTITY.IS_ENTITY_ATTACHED(entity.handle) then
                ENTITY.DETACH_ENTITY(entity.handle, true, false)
            end
            self:ReleaseWorldEntity(entity)
        end
    end

    for _, entity in pairs(reference) do
        if entity.handle and (entity.handle ~= Self.GetPedID()) and not entity.isPlayer then
            self:UnregisterEntity(entity.handle)
            ENTITY.DELETE_ENTITY(entity.handle)
        end

        if entity.children then
            self:ForceCleanup(entity.children)
        end
    end
    self.PlayerEntity = nil
end

---@param input string | number | table | SpawnedEntity
function EntityForge:IsModelInFavorites(input)
    if not input then
        return
    end

    if type(input) == "number" or type(input) == "string" then
        input = Game.EnsureModelHash(input)
    elseif type(input) == "table" or (getmetatable(input) == getmetatable(SpawnedEntity)) then
        input = Game.EnsureModelHash(input.modelHash)
    end

    for _, v in ipairs(favorite_entities) do
        if v.modelHash == input then
            return v.name
        end
    end
end

---@param input table
function EntityForge:RemoveFromFavorites(input)
    if not input or not favorite_entities or #favorite_entities == 0 then
        return
    end

    for i, v in ipairs(favorite_entities) do
        if v.name == input.name then
            table.remove(favorite_entities, i)
            break
        end
    end

    CFG:SaveItem("favorite_entities", favorite_entities)
end

function EntityForge:RemoveAllFavorites()
    favorite_entities = {}
    CFG:SaveItem("favorite_entities", favorite_entities)
end

function EntityForge:OverwriteSavedAbomination()
    for i, entity in ipairs(forged_entities) do
        if entity.name == EntityForge.currentParent.name then
            forged_entities[i] = EntityForge.currentParent:AsTable()
            break
        end
    end

    CFG:SaveItem("forged_entities", forged_entities)
    YimToast:ShowMessage("EntityForge", "Changes saved.")
end

---@param abomination SpawnedEntity
function EntityForge:RemoveSavedAbomination(abomination)
    if not abomination or not forged_entities or #forged_entities == 0 then
        return
    end

    for i, v in ipairs(forged_entities) do
        if v.name == abomination.name then
            table.remove(forged_entities, i)
            break
        end
    end
    CFG:SaveItem("forged_entities", forged_entities)
end

function EntityForge:RemoveAllSavedAbominations()
    forged_entities = {}
    CFG:SaveItem("forged_entities", forged_entities)
end

---@param data any
function EntityForge:ImportCreation(data)
    if not data or not CFG.is_base64(data) then
        YimToast:ShowError(
            "EntityForge",
            "Import Error: Incorrect data type!",
            true,
            5.0
        )
        return
    end

    local abomination = CFG:Decode(CFG:xor_(CFG:b64_decode(data)))
    if type(abomination) ~= "table" then
        YimToast:ShowError(
            "EntityForge",
            "Import Error: Incorrect data type!",
            true,
            5.0
        )
        return
    end

    return abomination
end
