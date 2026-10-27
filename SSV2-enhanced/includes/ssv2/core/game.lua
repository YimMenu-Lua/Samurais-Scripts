local weapon_data = require('includes.ssv2.data.weapon_data')
local Game = {}

-- Keep every scalar output alive until its native has completed.
function Game.current_weapon(ped)
    local ptr = memory.allocate(4)
    local ok, hash = pcall(function()
        return WEAPON.GET_CURRENT_PED_WEAPON(ped, ptr, false) and ptr:get_int() % 4294967296 or 0
    end)
    memory.free(ptr)
    if not ok then error(hash) end
    return hash
end

function Game.aimed_entity(player, skip_players)
    if not PLAYER.IS_PLAYER_FREE_AIMING(player) then return 0 end
    local ptr = memory.allocate(4)
    local ok, entity = pcall(function()
        return PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(player, ptr) and ptr:get_int() or 0
    end)
    memory.free(ptr)
    if not ok then error(entity) end
    if entity == 0 or not ENTITY.DOES_ENTITY_EXIST(entity) then return 0 end
    if ENTITY.IS_ENTITY_A_PED(entity) then
        if skip_players and PED.IS_PED_A_PLAYER(entity) then return 0 end
        if PED.IS_PED_IN_ANY_VEHICLE(entity, false) then return PED.GET_VEHICLE_PED_IS_IN(entity, false) end
    end
    return entity
end

function Game.outside(entity)
    local interior = INTERIOR.GET_INTERIOR_FROM_ENTITY(entity)
    return interior == 0 or INTERIOR.GET_INTERIOR_GROUP_ID(interior) > 0
end

function Game.load_ground(position, valid)
    local found, height = false, position.z
    for attempt = 0, 299 do
        if not valid() then return false end
        found, height = Game.ground_z({ x = position.x, y = position.y, z = 1000 })
        STREAMING.REQUEST_COLLISION_AT_COORD(position.x, position.y, position.z)
        if attempt % 10 == 0 then position.z = position.z + 25 end
        script.yield(0)
        if not valid() then return false end
        if found then break end
    end
    if not found then return false end
    local pointer = memory.allocate(4)
    local ok, water, level = pcall(function()
        local water = WATER.GET_WATER_HEIGHT(position.x, position.y, position.z, pointer)
        return water, pointer:get_float()
    end)
    memory.free(pointer); if not ok then error(water) end
    position.z = water and level or height + 1
    return true
end

function Game.teleport(ctx, position, keep_vehicle, load_ground, valid)
    if not position or position.x == 0 and position.y == 0 and position.z == 0 then
        ctx.notifier:error(ctx.translator:text('GENERIC_TELEPORT'), ctx.translator:text('GENERIC_TP_INVALID_COORDS_ERR'))
        return false
    end
    local state = ctx.state:read()
    if not state then return false end
    local generation = ctx.runtime.generation
    local function current()
        return ctx.runtime.running and ctx.runtime.generation == generation and
            (not valid or valid())
    end
    position = { x = position.x, y = position.y, z = position.z }
    if not keep_vehicle and not state.on_foot then
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(state.handle)
        script.yield(50)
        if not current() then return false end
        state = ctx.state:read()
        if not state then return false end
    end
    if load_ground then
        local start = util.time()
        while not Game.load_ground(position, current) do
            if not current() then return false end
            assert(util.time() - start <= 500, 'Ground lookup timed out')
            script.yield(0)
        end
        state = ctx.state:read(); if not state or not current() then return false end
    end
    local previous = state.ped:get_position()
    ENTITY.SET_ENTITY_HEADING(state.handle,
        MISC.GET_HEADING_FROM_VECTOR_2D(previous.x - position.x, previous.y - position.y))
    PED.SET_PED_COORDS_KEEP_VEHICLE(state.handle, position.x, position.y, position.z)
    return true
end

function Game.raycast(src, dest, flags, exclude)
    local ptr = memory.allocate(8)
    local endpoint, normal = Vector3.new(), Vector3.new()
    local ok, hit, entity = pcall(function()
        local ray = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
            src.x, src.y, src.z, dest.x, dest.y, dest.z, flags, exclude, 7)
        local result = SHAPETEST.GET_SHAPE_TEST_RESULT(ray, ptr, endpoint, normal, ptr:add(4))
        assert(result == 2, 'Synchronous raycast did not complete')
        return ptr:get_int() ~= 0, ptr:add(4):get_int()
    end)
    memory.free(ptr)
    if not ok then error(hit) end
    return hit, endpoint, entity
end

function Game.model_dimensions(model)
    local minimum, maximum = Vector3.new(), Vector3.new()
    MISC.GET_MODEL_DIMENSIONS(model, minimum, maximum)
    return minimum, maximum
end

function Game.ground_z(pos, exclude_objects)
    local ptr = memory.allocate(4)
    local ok, found, height = pcall(function()
        local getter = exclude_objects and MISC.GET_GROUND_Z_EXCLUDING_OBJECTS_FOR_3D_COORD or
            MISC.GET_GROUND_Z_FOR_3D_COORD
        local found = getter(pos.x, pos.y, pos.z, ptr, false, false)
        return found, ptr:get_float()
    end)
    memory.free(ptr)
    if not ok then error(found) end
    return found, height
end

function Game.closest_vehicle(position, radius, exclude, nonplayer, max_speed)
    local result, distance = 0, radius
    for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
        if vehicle ~= exclude and ENTITY.DOES_ENTITY_EXIST(vehicle) and VEHICLE.GET_VEHICLE_BODY_HEALTH(vehicle) > 0
            and (not max_speed or ENTITY.GET_ENTITY_SPEED(vehicle) <= max_speed) then
            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1, false)
            if not nonplayer or not PED.IS_PED_A_PLAYER(driver) then
                local pos = ENTITY.GET_ENTITY_COORDS(vehicle, true)
                local value = math.sqrt((pos.x - position.x) ^ 2 + (pos.y - position.y) ^ 2 + (pos.z - position.z) ^ 2)
                if value <= distance then result, distance = vehicle, value end
            end
        end
    end
    return result
end

function Game.waypoint()
    local blip = HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_WAYPOINT_BLIP_ENUM_ID())
    return HUD.DOES_BLIP_EXIST(blip) and HUD.GET_BLIP_COORDS(blip) or nil
end

function Game.objective()
    for _, sprite in ipairs({ 1, 9, 143, 144, 145, 146, 306, 535, 536, 537, 538, 539, 540, 541, 542 }) do
        local blip = HUD.GET_FIRST_BLIP_INFO_ID(sprite)
        if HUD.DOES_BLIP_EXIST(blip) then return HUD.GET_BLIP_INFO_ID_COORD(blip) end
    end
    local blip = HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_STANDARD_BLIP_ENUM_ID())
    return HUD.DOES_BLIP_EXIST(blip) and HUD.GET_BLIP_INFO_ID_COORD(blip) or nil
end

function Game.character_index()
    local ptr = memory.allocate(4)
    local ok, value = pcall(function()
        if not STATS.STAT_GET_INT(util.joaat('MPPLY_LAST_MP_CHAR'), ptr, -1) then return nil end
        return ptr:get_int()
    end)
    memory.free(ptr)
    if not ok then error(value) end
    return (value == 0 or value == 1) and value or nil
end

function Game.closest_road(pos, node_type)
    local position = Vector3.new(); local heading = memory.allocate(4)
    assert(heading and heading:get_address() ~= 0, 'Cannot allocate road heading output')
    local ok, found, value = pcall(function()
        local found = PATH.GET_CLOSEST_VEHICLE_NODE_WITH_HEADING(pos.x, pos.y, pos.z, position, heading, node_type or 0,
            3, 0)
        return found, heading:get_float()
    end)
    memory.free(heading); if not ok then error(found) end
    return found and position or nil, value
end

function Game.spawn_point(position, direction, distance)
    local output = Vector3.new()
    if MISC.FIND_SPAWN_POINT_IN_DIRECTION(position.x, position.y, position.z, direction.x, direction.y, direction.z, distance, output) then
        return
            output
    end
end

function Game.spawn_in_front(entity)
    local minimum, maximum = Game.model_dimensions(ENTITY.GET_ENTITY_MODEL(entity))
    return ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, 0, maximum.y - minimum.y, 0.1)
end

function Game.weapon_name(weapon)
    local hash = type(weapon) == 'string' and util.joaat(weapon) or weapon
    local data = weapon_data[hash % 4294967296]
    local label = data and HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(data.gxt) or ''
    return label ~= '' and label or 'NULL'
end

function Game.swimming(handle)
    return PED.IS_PED_SWIMMING(handle) or PED.IS_PED_SWIMMING_UNDER_WATER(handle)
end

function Game.is_enemy(local_ped, other)
    if local_ped == other or PED.IS_PED_A_PLAYER(other) then return false end
    local a = PED.GET_RELATIONSHIP_BETWEEN_PEDS(local_ped, other)
    local b = PED.GET_RELATIONSHIP_BETWEEN_PEDS(other, local_ped)
    local pos = ENTITY.GET_ENTITY_COORDS(other, true)
    return PED.IS_PED_IN_COMBAT(other, local_ped) or PED.IS_PED_IN_COMBAT(local_ped, other)
        or (a >= 3 and a <= 5) or (b >= 3 and b <= 5)
        or PED.IS_ANY_HOSTILE_PED_NEAR_POINT(other, pos.x, pos.y, pos.z, 1)
end

function Game.control(handle, attempts, valid)
    local entity = Entity.new(handle)
    for _ = 1, attempts or 300 do
        if not ENTITY.DOES_ENTITY_EXIST(handle) or valid and not valid() then return false end
        if entity:has_control() then return true end
        entity:request_control(0)
        if not ENTITY.DOES_ENTITY_EXIST(handle) or valid and not valid() then return false end
        if entity:has_control() then return true end
        script.yield(0)
    end
    return ENTITY.DOES_ENTITY_EXIST(handle) and (not valid or valid()) and entity:has_control()
end

function Game.clear_lock_feedback(ctx, handle)
    local records = ctx.lock_feedback or {}
    for entity, record in pairs(records) do
        if not handle or entity == handle then
            if ENTITY.DOES_ENTITY_EXIST(entity) and memory.handle_to_ptr(entity):get_address() == record.pointer then
                if record.engine_started then VEHICLE.SET_VEHICLE_ENGINE_ON(entity, false, true, false) end
                VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(entity, 0, false)
                VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(entity, 1, false)
            end
            records[entity] = nil
        end
    end
end

function Game.lock_vehicle(ctx, handle, locked, valid)
    if not VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(handle)) or not Game.control(handle, 300, valid) then return false end
    if locked then
        for door = 0, VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(handle) + 1 do
            if VEHICLE.GET_VEHICLE_DOOR_ANGLE_RATIO(handle, door) > 0 then
                VEHICLE.SET_VEHICLE_DOORS_SHUT(handle, false); break
            end
        end
        if VEHICLE.IS_VEHICLE_A_CONVERTIBLE(handle, false) and VEHICLE.GET_CONVERTIBLE_ROOF_STATE(handle) ~= 0 then
            VEHICLE.RAISE_CONVERTIBLE_ROOF(handle, false)
        else
            for window = 0, 7 do VEHICLE.ROLL_UP_WINDOW(handle, window) end
        end
    end
    VEHICLE.SET_VEHICLE_DOORS_LOCKED(handle, locked and 2 or 1)
    if PED.IS_PED_SITTING_IN_VEHICLE(PLAYER.PLAYER_PED_ID(), handle) then return true end
    Game.clear_lock_feedback(ctx, handle)
    local feedback = {
        pointer = memory.handle_to_ptr(handle):get_address(),
        engine_started = not VEHICLE
            .GET_IS_VEHICLE_ENGINE_RUNNING(handle)
    }
    ctx.lock_feedback = ctx.lock_feedback or {}; ctx.lock_feedback[handle] = feedback
    if feedback.engine_started then VEHICLE.SET_VEHICLE_ENGINE_ON(handle, true, true, false) end
    VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(handle, 0, true); VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(handle, 1, true)
    script.yield(150)
    if ctx.lock_feedback[handle] ~= feedback then return true end
    if not valid() or not ENTITY.DOES_ENTITY_EXIST(handle) or memory.handle_to_ptr(handle):get_address() ~= feedback.pointer then
        Game.clear_lock_feedback(ctx, handle); return false
    end
    if feedback.engine_started then
        VEHICLE.SET_VEHICLE_ENGINE_ON(handle, false, true, false); feedback.engine_started = false
    end
    AUDIO.SET_HORN_PERMANENTLY_ON_TIME(handle, 1000); AUDIO.SET_HORN_PERMANENTLY_ON(handle)
    VEHICLE.SET_VEHICLE_ALARM(handle, locked)
    script.yield(696)
    if ctx.lock_feedback[handle] == feedback then Game.clear_lock_feedback(ctx, handle) end
    return valid()
end

function Game.help(text)
    if not HUD.IS_HELP_MESSAGE_ON_SCREEN() then
        HUD.BEGIN_TEXT_COMMAND_DISPLAY_HELP('STRING'); HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
        HUD.END_TEXT_COMMAND_DISPLAY_HELP(0, false, true, -1)
    end
end

function Game.text(x, y, text, r, g, b, a, sx, sy, font)
    HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT('STRING'); HUD.SET_TEXT_COLOUR(r, g, b, a)
    HUD.SET_TEXT_SCALE(sx, sy); HUD.SET_TEXT_OUTLINE(); HUD.SET_TEXT_FONT(font); HUD.SET_TEXT_JUSTIFICATION(1)
    HUD.SET_TEXT_DROP_SHADOW(); HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text); HUD.END_TEXT_COMMAND_DISPLAY_TEXT(x,
        y, 0)
end

function Game.bounding_box(entity, r, g, b, a)
    local minimum, maximum = Game.model_dimensions(ENTITY.GET_ENTITY_MODEL(entity))
    local corners = {}
    for x = 0, 1 do
        for y = 0, 1 do
            for z = 0, 1 do
                corners[#corners + 1] = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity,
                    x == 0 and minimum.x or maximum.x,
                    y == 0 and minimum.y or maximum.y, z == 0 and minimum.z or maximum.z)
            end
        end
    end
    for _, edge in ipairs({ { 1, 2 }, { 2, 4 }, { 4, 3 }, { 3, 1 }, { 5, 6 }, { 6, 8 }, { 8, 7 }, { 7, 5 }, { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 } }) do
        local first, last = corners[edge[1]], corners[edge[2]]
        GRAPHICS.DRAW_LINE(first.x, first.y, first.z, last.x, last.y, last.z, r, g, b, a or 255)
    end
end

return Game
