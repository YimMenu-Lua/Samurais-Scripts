local Pool = require('includes.ssv2.core.entity_pool')
local Appearance = require('includes.ssv2.core.appearance')
local Geometry = require('includes.ssv2.core.geometry')
local Forge = {}; Forge.__index = Forge
local type_ids = { ped = 1, vehicle = 2, object = 3 }
local type_names = { [1] = 'ped', [2] = 'vehicle', [3] = 'object' }
local function point(value) return { x = value and value.x or 0, y = value and value.y or 0, z = value and value.z or 0 } end
function Forge.new(ctx, feature)
    return setmetatable(
        { ctx = ctx, feature = feature, pool = Pool.new(ctx), entries = {}, order = {}, grabbed = nil, distance = 7, rotation_speed = 1 },
        Forge)
end

function Forge:exists(entry)
    return entry and ENTITY.DOES_ENTITY_EXIST(entry.handle) and
        memory.handle_to_ptr(entry.handle):get_address() == entry.pointer
end

function Forge:add(handle, name, kind, world)
    if self.entries[handle] then return self.entries[handle] end
    local entry = self.pool.owned[handle] or {
        handle = handle,
        kind = kind,
        model = ENTITY.GET_ENTITY_MODEL(handle),
        entity = Entity.new(handle),
        pointer = memory.handle_to_ptr(handle):get_address()
    }
    entry.kind, entry.name, entry.world = kind, name, world or false
    entry.player = handle == PLAYER.PLAYER_PED_ID(); entry.children = {}; entry.properties = {}
    entry.position = point(ENTITY.GET_ENTITY_COORDS(handle, false)); entry.rotation = point(ENTITY.GET_ENTITY_ROTATION(
        handle, 2))
    entry.alpha = ENTITY.GET_ENTITY_ALPHA(handle)
    self.entries[handle] = entry; self.order[#self.order + 1] = entry
    return entry
end

function Forge:player()
    return self:add(PLAYER.PLAYER_PED_ID(), 'You', 'ped', false)
end

function Forge:spawn(model, name, kind, position, alpha, valid)
    local ped = PLAYER.PLAYER_PED_ID()
    position = position or ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 1, 5, 0)
    local found, ground = self.ctx.game.ground_z(position, true)
    local pos = Vector3.new(position.x, position.y, found and ground or position.z)
    local created = self.pool:create(kind, model, pos, ENTITY.GET_ENTITY_HEADING(ped) - (kind == 'object' and 0 or 90),
        valid, true, true)
    if not created then return end
    local entry = self:add(created.handle, name, kind, false)
    entry.alpha = alpha or 255; ENTITY.SET_ENTITY_ALPHA(entry.handle, entry.alpha, false)
    if kind == 'object' then
        OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(entry.handle)
    elseif kind == 'vehicle' then
        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(entry.handle, 5)
    else
        self:stand(entry)
    end
    return entry
end

function Forge:stand(entry)
    TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entry.handle, true)
    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entry.handle, true); PED.SET_PED_KEEP_TASK(entry.handle, false)
    TASK.TASK_STAND_STILL(entry.handle, -1)
end

function Forge:adopt(handle, valid)
    assert(handle ~= PLAYER.PLAYER_PED_ID() and not self.ctx.owned_entities[handle], 'Select an unmanaged world entity')
    assert(not ENTITY.IS_ENTITY_DEAD(handle, false), 'Cannot add a dead entity')
    if ENTITY.IS_ENTITY_A_PED(handle) then assert(not PED.IS_PED_A_PLAYER(handle), 'Cannot add another player') end
    assert(self.ctx.game.control(handle, 350, valid), 'Could not obtain entity control')
    local kind = type_names[ENTITY.GET_ENTITY_TYPE(handle)]; assert(kind, 'Unknown entity type')
    local name = kind == 'object' and 'World Object' or kind == 'ped' and 'World Ped'
        or
        'World Vehicle (' ..
        HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(ENTITY.GET_ENTITY_MODEL(
            handle))) .. ')'
    local entry = self:add(handle, name, kind, true)
    ENTITY.SET_ENTITY_INVINCIBLE(handle, true); ENTITY.SET_ENTITY_COLLISION(handle, false, true)
    if kind == 'ped' then
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(handle); self:stand(entry)
    elseif kind == 'vehicle' then
        for seat = -1, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(handle) - 1 do
            local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(handle, seat, false)
            if ped ~= 0 and not PED.IS_PED_A_PLAYER(ped) then TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped) end
        end
    end
    return entry
end

function Forge:unlink(entry)
    local parent = entry.parent
    if parent then for i = #parent.children, 1, -1 do if parent.children[i] == entry then table.remove(parent.children, i) end end end
    entry.parent = nil
end

function Forge:detach(entry, place)
    if not self:exists(entry) then
        self:unlink(entry); return
    end
    ENTITY.DETACH_ENTITY(entry.handle, true, false); self:unlink(entry)
    entry.attach_pos, entry.attach_rot, entry.parent_bone = nil, nil, nil
    if place then
        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entry.handle, 1, 2, 0)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entry.handle, pos.x, pos.y, pos.z, false, false, false)
        if entry.kind == 'object' then
            OBJECT.PLACE_OBJECT_ON_GROUND_OR_OBJECT_PROPERLY(entry.handle)
        elseif entry.kind == 'vehicle' then
            VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(entry.handle, 5)
        end
    end
    if entry.kind == 'ped' and not entry.player then self:stand(entry) end
    entry.position = point(ENTITY.GET_ENTITY_COORDS(entry.handle, false)); entry.rotation = point(ENTITY
        .GET_ENTITY_ROTATION(entry.handle, 2))
end

function Forge:attach(child, parent, bone, position, rotation)
    assert(self:exists(child) and self:exists(parent), 'Attachment entity no longer exists')
    assert(child ~= parent and not child.player, 'The player can only be an attachment parent')
    local ancestor = parent
    while ancestor do
        assert(ancestor ~= child, 'Attachment would create a cycle'); ancestor = ancestor.parent
    end
    local index = 0
    if parent.kind == 'ped' then
        index = PED.GET_PED_BONE_INDEX(parent.handle, tonumber(bone) or 0)
    elseif parent.kind == 'vehicle' and type(bone) == 'string' and bone ~= '' and bone ~= '0' then
        index = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(parent.handle, bone)
    end
    assert(index ~= -1, 'Attachment bone was not found')
    self:unlink(child)
    child.parent = parent; parent.children[#parent.children + 1] = child
    child.parent_bone = bone; child.attach_pos = point(position); child.attach_rot = point(rotation)
    local pos, rot = child.attach_pos, child.attach_rot
    ENTITY.ATTACH_ENTITY_TO_ENTITY(child.handle, parent.handle, index, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, false,
        true, false, child.kind == 'ped', 2, true, 1)
    if child.kind == 'ped' then
        ENTITY.SET_ENTITY_INVINCIBLE(child.handle, true); self:stand(child)
    end
end

function Forge:transform(entry, position, rotation)
    assert(self:exists(entry), 'Entity no longer exists')
    if entry.parent then
        self:attach(entry, entry.parent, entry.parent_bone, position or entry.attach_pos, rotation or entry.attach_rot)
    else
        if position then
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entry.handle, position.x, position.y, position.z, false, false, false); entry.position =
                point(position)
        end
        if rotation then
            ENTITY.SET_ENTITY_ROTATION(entry.handle, rotation.x, rotation.y, rotation.z, 2, true); entry.rotation = point(
                rotation)
        end
    end
end

function Forge:move_attachment(entry, x, y, z)
    if not entry or not entry.parent then return end
    local pos = point(entry.attach_pos)
    pos.x, pos.y, pos.z = pos.x + x, pos.y + y, pos.z + z
    self:transform(entry, pos, nil)
end

function Forge:rotate_attachment(entry, x, y, z)
    if not entry or not entry.parent then return end
    local rot = point(entry.attach_rot)
    rot.x, rot.y, rot.z = rot.x + x, rot.y + y, rot.z + z
    self:transform(entry, nil, rot)
end

function Forge:remove(entry, recursive)
    if not entry then return end
    for i = #entry.children, 1, -1 do
        local child = entry.children[i]
        if recursive then self:remove(child, true) else self:detach(child, true) end
    end
    self:unlink(entry)
    if self:exists(entry) and not entry.player then
        if entry.world then entry.entity:delete() else self.pool:delete(entry.handle) end
    end
    self.entries[entry.handle] = nil
    for i = #self.order, 1, -1 do if self.order[i] == entry then table.remove(self.order, i) end end
    if self.grabbed == entry then self.grabbed = nil end
end

function Forge:release(entry)
    assert(entry.world, 'Only world entities can be released')
    for i = #entry.children, 1, -1 do self:detach(entry.children[i], true) end
    self:detach(entry, false)
    if self:exists(entry) then
        ENTITY.SET_ENTITY_COLLISION(entry.handle, true, true); ENTITY.SET_ENTITY_INVINCIBLE(entry.handle, false)
        ENTITY.FREEZE_ENTITY_POSITION(entry.handle, false); PHYSICS.ACTIVATE_PHYSICS(entry.handle)
        if entry.kind == 'ped' then
            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entry.handle, false)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entry.handle, false); TASK.CLEAR_PED_TASKS_IMMEDIATELY(entry.handle)
            local output = memory.allocate(4)
            assert(output and output:get_address() ~= 0, 'Cannot allocate released entity handle')
            local ok, err = pcall(function()
                output:set_int(entry.handle); ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(output)
            end)
            memory.free(output); if not ok then error(err) end
        elseif entry.kind == 'object' then
            OBJECT.SET_ACTIVATE_OBJECT_PHYSICS_AS_SOON_AS_IT_IS_UNFROZEN(entry.handle, true)
        end
    end
    self.entries[entry.handle] = nil
    for i = #self.order, 1, -1 do if self.order[i] == entry then table.remove(self.order, i) end end
    if self.grabbed == entry then self.grabbed = nil end
end

function Forge:serialize(entry)
    assert(self:exists(entry), 'Cannot save a missing entity')
    if entry.kind == 'vehicle' then
        entry.properties.mods = Appearance.vehicle(entry.handle)
    elseif entry.kind == 'ped' and not entry.player then
        entry.properties.components = Appearance.ped(entry.handle)
    end
    local result = {
        name = entry.name,
        modelHash = entry.player and -1 or entry.model,
        type = type_ids[entry.kind],
        alpha = entry.alpha,
        isPlayer = entry.player,
        isAttached = entry.parent ~= nil,
        isForged = true,
        properties = entry.properties,
        parent_bone = entry.parent_bone,
        attach_pos = point(entry.attach_pos),
        attach_rot = point(entry.attach_rot),
        children = {}
    }
    for _, child in ipairs(entry.children) do result.children[#result.children + 1] = self:serialize(child) end
    return result
end

function Forge:load(definition, valid)
    local created = {}
    local count = 0
    local function recurse(value, parent, depth)
        assert(type(value) == 'table' and depth <= 64, 'Invalid forge tree')
        count = count + 1; assert(count <= 512, 'Forge has too many entities')
        if not valid() then return end
        local kind = type_names[value.type] or value.kind
        assert(type_ids[kind], 'Invalid forge entity type')
        local entry
        if value.isPlayer or value.modelHash == -1 then
            assert(not parent, 'The player must be the forge root'); entry = self:player()
        else
            entry = self:spawn(value.modelHash, value.name or 'Saved entity', kind, nil, value.alpha, valid); if not entry then return end; created[#created + 1] =
                entry
        end
        entry.name = value.name or entry.name; entry.properties = value.properties or {}
        if kind == 'vehicle' and entry.properties.mods then
            if not Appearance.apply_vehicle(entry.handle, entry.properties.mods, valid) then return end
        elseif kind == 'ped' and not entry.player then
            Appearance.apply_ped(entry.handle, entry.properties.components)
            if entry.properties.action and entry.properties.action.scenario then
                local deadline = util.time() + 1200
                while valid() and not PED.IS_PED_USING_ANY_SCENARIO(entry.handle) and util.time() < deadline do
                    TASK.TASK_START_SCENARIO_IN_PLACE(entry.handle, entry.properties.action.scenario, -1, false)
                    script.yield(200)
                end
                if not valid() then return end
            end
        end
        if parent then self:attach(entry, parent, value.parent_bone, value.attach_pos, value.attach_rot) end
        for _, child in ipairs(value.children or {}) do if not recurse(child, entry, depth + 1) then return end end
        return entry
    end
    local ok, result = pcall(function() return recurse(definition, nil, 0) end)
    if not ok or not result or not valid() then
        for i = #created, 1, -1 do if self.entries[created[i].handle] then self:remove(created[i], true) end end
        if not ok then error(result) end
        return nil
    end
    result.forged = true; result.saved_name = definition.name
    return result
end

function Forge:drop()
    if self:exists(self.grabbed) then
        local entry = self.grabbed
        ENTITY.FREEZE_ENTITY_POSITION(entry.handle, false); ENTITY.SET_ENTITY_COLLISION(entry.handle, true, true)
        PHYSICS.ACTIVATE_PHYSICS(entry.handle)
        if entry.kind == 'object' then OBJECT.SET_ACTIVATE_OBJECT_PHYSICS_AS_SOON_AS_IT_IS_UNFROZEN(entry.handle, true) end
    end
    self.grabbed = nil
end

function Forge:gun(state)
    PLAYER.DISABLE_PLAYER_FIRING(state.player_id, true)
    if not PLAYER.IS_PLAYER_FREE_AIMING(state.player_id) then
        self:drop(); return
    end
    local aimed = self.ctx.game.aimed_entity(state.player_id, true)
    if aimed ~= 0 and not self.grabbed and not self.ctx.owned_entities[aimed] and not ENTITY.IS_ENTITY_DEAD(aimed, false) then
        self.ctx.game.help(self.entries[aimed] and 'Hold ~INPUT_ATTACK~ to move the entity with your mouse.'
            or 'Press ~INPUT_PICKUP~ to add the entity to the forge pool.')
    end
    local held = PAD.IS_DISABLED_CONTROL_PRESSED(0, 24)
    if not held then
        self:drop(); return
    end
    local entry = self.grabbed
    if not entry then
        local target = self.ctx.game.aimed_entity(state.player_id, true)
        entry = self.entries[target]
        if not entry or entry.forged then return end
        self.grabbed = entry; self.distance = math.min(50,
            math.max(1, Geometry.distance(ENTITY.GET_ENTITY_COORDS(entry.handle, false), state.ped:get_position())))
        entry.last_position = nil; ENTITY.SET_ENTITY_COLLISION(entry.handle, false, true)
    end
    if not self:exists(entry) then
        self.grabbed = nil; return
    end
    local hints = {
        { 0.08, '- Press [Back Space] to delete this entity.' },
        { 0.11, "- Press [F] to save this entity's model to favorites." },
        { 0.14, '- Use [Page Up] and [Page Down] to adjust distance.' },
        { 0.17, '- Use [Numpad +] and [Numpad -] to adjust rotation speed.' },
        { 0.20, '- Use [Numpad 1 - 3  |  4 - 6  |  2 - 8] to rotate.' },
    }
    if entry.world then hints[#hints + 1] = { 0.23, '- Press [E] to release the entity from the pool.' } end
    for _, hint in ipairs(hints) do self.ctx.game.text(0.61, 0.40 + hint[1], hint[2], 255, 255, 255, 220, 0.2, 0.38, 4) end
    local rotation = CAMERA.GET_GAMEPLAY_CAM_ROT(2); local camera = CAMERA.GET_GAMEPLAY_CAM_COORD()
    local direction = Geometry.direction(rotation)
    local target = Vector3.new(camera.x + direction.x * self.distance, camera.y + direction.y * self.distance,
        camera.z + direction.z * self.distance)
    entry.last_position = Geometry.lerp(entry.last_position or ENTITY.GET_ENTITY_COORDS(entry.handle, false), target,
        math.min(1, MISC.GET_FRAME_TIME() * 10))
    local found, height = self.ctx.game.ground_z(state.ped:get_position())
    if found then entry.last_position.z = math.max(entry.last_position.z, height + 0.5) end
    if entry.parent then
        local p = entry.last_position
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entry.handle, p.x, p.y, p.z, false, false, false)
        entry.position = point(p)
    else
        self:transform(entry, entry.last_position, nil)
    end
    if self.ctx.input.held[0x21] then self.distance = math.min(50, self.distance + 0.1) end
    if self.ctx.input.held[0x22] then self.distance = math.max(1, self.distance - 0.1) end
    local yaw = math.abs(rotation.z - ENTITY.GET_ENTITY_HEADING(entry.handle)) % 360
    if yaw > 180 then yaw = 360 - yaw end
    local multiplier = yaw > 90 and -1 or 1
    local rot = point(entry.rotation); local speed = 0.1 * self.rotation_speed
    for code, delta in pairs({ [0x64] = { 0, -speed * multiplier, 0 }, [0x66] = { 0, speed * multiplier, 0 }, [0x68] = { speed, 0, 0 },
        [0x62] = { -speed, 0, 0 }, [0x61] = { 0, 0, -speed }, [0x63] = { 0, 0, speed } }) do
        if self.ctx.input.held[code] then rot.x, rot.y, rot.z = rot.x + delta[1], rot.y + delta[2], rot.z + delta[3] end
    end
    self:transform(entry, nil, rot)
    self.feature:mark(entry, -0.1)
end

function Forge:clear()
    self:drop()
    for i = #self.order, 1, -1 do
        local entry = self.order[i]
        if entry and self.entries[entry.handle] then
            if entry.world then self:release(entry) else self:remove(entry, true) end
        end
    end
    self.pool:clear(); self.entries = {}; self.order = {}
end

return Forge
