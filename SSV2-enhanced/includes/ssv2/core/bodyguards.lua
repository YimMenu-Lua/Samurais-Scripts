local Geometry = require('includes.ssv2.core.geometry')
local Group = require('includes.ssv2.core.group')
local weapons = require('includes.ssv2.data.weapon_data')
local WeaponBrowser = require('includes.ssv2.core.weapon_browser')
local Guards = {}; Guards.__index = Guards
local config = { 113, 118, 141, 179, 188, 193, 208, 251, 255, 261, 268, 286, 294, 301, 364, 398, 401, 443 }
local combat = { 1, 2, 3, 4, 5, 13, 20, 21, 22, 27, 28, 31, 34, 38, 41, 42, 46, 50, 54, 55, 58, 61, 68, 71 }
local locked = { enter_vehicle = true, leave_vehicle = true, parachute = true, rappel = true, dismissed = true, override = true }
function Guards.new(ctx, service)
    return setmetatable({ ctx = ctx, service = service, group = Group.new(ctx), members = {}, seats = {}, targets = {} },
        Guards)
end

function Guards:spawn(model, name, position, weapon, invincible, no_ragdoll, valid)
    local state = self.ctx.state:read(); assert(state, 'Player is unavailable')
    position = position or ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(state.handle, 0, 2, 0.1)
    local entry = self.service.pool:create('ped', model, position, ENTITY.GET_ENTITY_HEADING(state.handle) - 180, valid,
        nil, network.is_session_started())
    if not entry then return end
    entry.name = type(name) == 'string' and name ~= '' and name or tostring(model)
    entry.display_name = entry.name .. ' [' .. entry.handle .. ']'; entry.task = 'none'; entry.queue = {}; entry.token = 0
    entry.invincible = invincible or false; entry.no_ragdoll = no_ragdoll or false; entry.role = 'bodyguard'
    entry.next_update = 0; entry.evaluation_at = util.time() + 10000; entry.last_position = position
    local handle = entry.handle
    self.group:add(handle)
    ENTITY.SET_ENTITY_MAX_HEALTH(handle, 1000); ENTITY.SET_ENTITY_HEALTH(handle, 1000, 0, 0)
    ENTITY.SET_ENTITY_INVINCIBLE(handle, entry.invincible, false); PED.SET_PED_RANDOM_COMPONENT_VARIATION(handle, 0)
    PED.SET_PED_KEEP_TASK(handle, true); PED.SET_PED_FIRING_PATTERN(handle, 0xC6EE6B4C)
    PED.SET_PED_SUFFERS_CRITICAL_HITS(handle, false); PED.SET_PED_ARMOUR(handle, 100)
    PED.SET_PED_CAN_EVASIVE_DIVE(handle, true); PED.SET_PED_CAN_BE_DRAGGED_OUT(handle, false)
    PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(handle, 1); PED.SET_CAN_ATTACK_FRIENDLY(handle, false, false)
    if no_ragdoll then for i = 0, 17 do PED.SET_RAGDOLL_BLOCKING_FLAGS(handle, i) end end
    PED.SET_PED_ACCURACY(handle, 100); PED.SET_PED_HIGHLY_PERCEPTIVE(handle, true)
    PED.SET_PED_SEEING_RANGE(handle, 200); PED.SET_PED_HEARING_RANGE(handle, 200); PED.SET_PED_ID_RANGE(handle, 200)
    PED.SET_PED_SHOOT_RATE(handle, 1000); PED.SET_PED_COMBAT_ABILITY(handle, 2); PED.SET_DRIVER_AGGRESSIVENESS(handle, 1)
    PED.SET_PED_CONFIG_FLAG(handle, 360, false); PED.SET_PED_CONFIG_FLAG(handle, 431, false)
    for _, flag in ipairs(config) do PED.SET_PED_CONFIG_FLAG(handle, flag, true) end
    for _, flag in ipairs(combat) do PED.SET_PED_COMBAT_ATTRIBUTES(handle, flag, true) end
    entry.blip = self.service.blips:add(handle, entry.name)
    self.members[handle] = entry
    self:give_weapon(entry, weapon == nil and 350597077 or weapon)
    return entry
end

function Guards:give_weapon(entry, weapon)
    if weapon == false then return end
    if weapon == true then
        for hash, metadata in pairs(weapons) do
            if WeaponBrowser.supports(metadata) and WEAPON.IS_WEAPON_VALID(hash) and not WEAPON.HAS_PED_GOT_WEAPON(entry.handle, hash, false) then
                WEAPON.GIVE_DELAYED_WEAPON_TO_PED(entry.handle, hash, 9999, false)
            end
        end
        entry.all_weapons = true; entry.armed = true; if entry.weapon == nil then entry.weapon = true end; return
    end
    weapon = type(weapon) == 'string' and util.joaat(weapon) or weapon
    if not weapon or weapon == 0 then weapon = 350597077 end
    if weapon % 4294967296 == 2725352035 then return end
    assert(WEAPON.IS_WEAPON_VALID(weapon), 'Invalid bodyguard weapon')
    WEAPON.GIVE_WEAPON_TO_PED(entry.handle, weapon, 9999, false, false)
    WEAPON.SET_PED_INFINITE_AMMO(entry.handle, true, weapon)
    entry.armed = true; entry.weapon = weapon
end

function Guards:alive(entry)
    return self.service.pool:exists(entry) and not PED.IS_PED_DEAD_OR_DYING(entry.handle, true)
end

function Guards:speak(entry, name, params)
    if self:alive(entry) and not AUDIO.IS_AMBIENT_SPEECH_PLAYING(entry.handle) then
        AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(entry.handle, name or 'GENERIC_HOWS_IT_GOING',
            params or 'SPEECH_PARAMS_STANDARD', 0)
    end
end

function Guards:clear_task(entry)
    entry.token = entry.token + 1; entry.queue = {}; entry.task = 'none'; entry.busy = false; entry.override = nil
    if self.service.pool:exists(entry) then
        TASK.CLEAR_PED_TASKS(entry.handle); TASK.CLEAR_PED_SECONDARY_TASK(entry.handle); TASK.TASK_CLEAR_DEFENSIVE_AREA(
            entry.handle)
    end
    if entry.sequence then
        local output = memory.allocate(4)
        assert(output and output:get_address() ~= 0, 'Cannot allocate combat sequence handle')
        local ok, err = pcall(function()
            output:set_int(entry.sequence); TASK.CLEAR_SEQUENCE_TASK(output)
        end)
        memory.free(output); entry.sequence = nil; if not ok then error(err) end
    end
    for vehicle, slots in pairs(self.seats) do for seat, handle in pairs(slots) do if handle == entry.handle then slots[seat] = nil end end end
    for vehicle, handle in pairs(self.targets) do if handle == entry.handle then self.targets[vehicle] = nil end end
end

function Guards:remove(entry)
    self:clear_task(entry); self.service.blips:remove(entry.blip); self.members[entry.handle] = nil
    if entry.temp_vehicle then self.service.pool:delete(entry.temp_vehicle.handle) end
    self.service.pool:delete(entry.handle)
end

function Guards:bring(entry, allow_inside)
    local state = self.ctx.state:read(); if not state or not self:alive(entry) then return end
    if not allow_inside and not self.ctx.game.outside(state.handle) then return end
    if state.vehicle and PED.IS_PED_IN_VEHICLE(entry.handle, state.vehicle_handle, false) then return end
    local offset = state.on_foot and math.random(2, 4) or math.random(6, 8)
    if PED.IS_PED_IN_ANY_VEHICLE(entry.handle, false) then offset = -offset end
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(state.handle, 0, offset, 0.1)
    PED.SET_PED_COORDS_KEEP_VEHICLE(entry.handle, pos.x, pos.y, pos.z)
end

function Guards:queue(entry, task, callback, priority)
    if entry.dismissed or entry.override or entry.task == task or entry.busy then return end
    for _, pending in ipairs(entry.queue) do if pending.task == task then return end end
    local request = { task = task, callback = callback }
    table.insert(entry.queue, priority and 1 or #entry.queue + 1, request)
end

function Guards:operation(entry, task, callback)
    if not self:alive(entry) or entry.busy then return end
    entry.token = entry.token + 1; entry.task = task; entry.busy = true
    local token = entry.token
    self.service:run('guard_' .. task, function(valid)
        local function current()
            return valid() and self:alive(entry) and self.members[entry.handle] == entry and
                entry.token == token
        end
        local ok, err = pcall(function() if current() then callback(current) end end)
        if entry.token == token then entry.busy = false end
        if not ok then error(err) end
    end)
end

function Guards:enter(entry, vehicle, seat, valid)
    self.seats[vehicle] = self.seats[vehicle] or {}
    if seat == nil then
        for i = 0, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle) - 1 do
            if VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, i, true) and not self.seats[vehicle][i] then
                seat = i; break
            end
        end
    end
    if seat == nil then return self:acquire_vehicle(entry, valid) end
    self.seats[vehicle][seat] = entry.handle
    TASK.CLEAR_PED_TASKS(entry.handle); TASK.CLEAR_PED_SECONDARY_TASK(entry.handle)
    if Geometry.distance(ENTITY.GET_ENTITY_COORDS(entry.handle, false), ENTITY.GET_ENTITY_COORDS(vehicle, false)) >= 150 then
        TASK.TASK_WARP_PED_INTO_VEHICLE(entry.handle, vehicle, seat)
    else
        TASK.TASK_ENTER_VEHICLE(entry.handle, vehicle, 20000, seat, 2, 1, '')
    end
    local deadline = util.time() + 5000
    while valid() and ENTITY.DOES_ENTITY_EXIST(vehicle) and not PED.IS_PED_IN_VEHICLE(entry.handle, vehicle, false) and util.time() < deadline do
        script.yield(0)
    end
    if valid() and ENTITY.DOES_ENTITY_EXIST(vehicle) then
        if not PED.IS_PED_IN_VEHICLE(entry.handle, vehicle, false) and VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, seat, true)
            and not PED.IS_PED_TRYING_TO_ENTER_A_LOCKED_VEHICLE(entry.handle) then
            TASK.TASK_WARP_PED_INTO_VEHICLE(entry.handle, vehicle, seat)
        end
        entry.task = 'sitting'; entry.entered_vehicle = vehicle
    end
    if self.seats[vehicle] and self.seats[vehicle][seat] == entry.handle then self.seats[vehicle][seat] = nil end
end

function Guards:acquire_vehicle(entry, valid)
    local state = self.ctx.state:read(); if not state then return end
    if state.vehicle and ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(state.handle) >= 5 then
        self.ctx.notifier:info("Samurai's Scripts", "Some of your bodyguards have been dismissed because you're flying.")
        self:dismiss(entry); return
    end
    local function suitable(handle)
        if handle == 0 or not ENTITY.DOES_ENTITY_EXIST(handle) or self.targets[handle] or self.ctx.owned_entities[handle] then return false end
        local model = ENTITY.GET_ENTITY_MODEL(handle)
        return not VEHICLE.IS_THIS_MODEL_A_HELI(model) and not VEHICLE.IS_THIS_MODEL_A_PLANE(model)
    end
    local position = ENTITY.GET_ENTITY_COORDS(entry.handle, false)
    if entry.target_vehicle and ENTITY.DOES_ENTITY_EXIST(entry.target_vehicle) then
        local distance = Geometry.distance(position, ENTITY.GET_ENTITY_COORDS(entry.target_vehicle, false))
        TASK.TASK_WARP_PED_INTO_VEHICLE(entry.handle, entry.target_vehicle, -1)
        if distance > 150 then
            script.yield(200); if not valid() then return end; PED.SET_PED_COORDS_KEEP_VEHICLE(entry.handle, position.x,
                position.y, position.z)
        end
        entry.task = 'vehicle_follow'; return
    end
    entry.target_vehicle = nil
    local target = self.ctx.game.closest_vehicle(position, 75, state.vehicle_handle, true, 20)
    if not suitable(target) then target = 0 end
    if target == 0 then
        local road, heading = self.ctx.game.closest_road(position, 0)
        if not road then
            self:clear_task(entry); return
        end
        if road and Geometry.distance(road, position) < 150 then
            TASK.TASK_GO_STRAIGHT_TO_COORD(entry.handle, road.x, road.y, road.z, 3, 10000, heading, 0.5)
            while valid() and Geometry.distance(ENTITY.GET_ENTITY_COORDS(entry.handle, false), road) > 2 do script.yield(50) end
            for _ = 1, 5 do
                if not valid() then return end
                target = self.ctx.game.closest_vehicle(ENTITY.GET_ENTITY_COORDS(entry.handle, false), 75,
                    state.vehicle_handle, true, 20)
                if suitable(target) then break end
                target = 0; script.yield(250)
            end
        end
        if target == 0 and valid() then
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entry.handle, 0, 3, 0.1)
            entry.temp_vehicle = self.service.pool:create('vehicle', 0xF9300CC5, pos,
                ENTITY.GET_ENTITY_HEADING(entry.handle) - 90, valid)
            target = entry.temp_vehicle and entry.temp_vehicle.handle or 0
        end
    end
    if target == 0 or not valid() then return end
    if not self.ctx.game.control(target, 350, valid) then return end
    self.targets[target] = entry.handle; entry.target_vehicle = target
    if not VEHICLE.IS_VEHICLE_STOPPED(target) then VEHICLE.BRING_VEHICLE_TO_HALT(target, 1, 1, false) end
    for seat = -1, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(target) - 1 do
        local occupant = VEHICLE.GET_PED_IN_VEHICLE_SEAT(target, seat, false)
        if occupant ~= 0 then
            if PED.IS_PED_A_PLAYER(occupant) or self.ctx.owned_entities[occupant] then
                self.targets[target] = nil; return
            end
            TASK.TASK_LEAVE_VEHICLE(occupant, target, 4160); script.yield(100); if not valid() then return end
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(occupant); TASK.TASK_SMART_FLEE_PED(occupant, entry.handle, 1000, -1, false,
                false)
        end
    end
    TASK.TASK_ENTER_VEHICLE(entry.handle, target, -1, -1, 2, 1, '')
    local deadline = util.time() + 10000
    while valid() and PED.IS_PED_ON_FOOT(entry.handle) and util.time() < deadline do script.yield(0) end
    if not valid() then return end
    if PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(entry.handle) == 0 or PED.IS_PED_ON_FOOT(entry.handle) and PED.IS_PED_STOPPED(entry.handle) then
        entry.jack_retries = (entry.jack_retries or 0) + 1
        if entry.jack_retries >= 5 then TASK.TASK_WARP_PED_INTO_VEHICLE(entry.handle, target, -2) end
    end
    self.targets[target] = nil; entry.task = 'vehicle_follow'
end

function Guards:engage(entry, target, state)
    if target == 0 or not ENTITY.DOES_ENTITY_EXIST(target) or ENTITY.IS_ENTITY_DEAD(target, false) or self.ctx.owned_entities[target] or target == state.handle
        or PED.GET_RELATIONSHIP_BETWEEN_PEDS(entry.handle, target) <= 2 and PED.GET_RELATIONSHIP_BETWEEN_PEDS(target, entry.handle) <= 2 then
        return
    end
    local previous = PED.GET_PED_TARGET_FROM_COMBAT_PED(entry.handle)
    if previous ~= 0 and (previous == state.handle or PED.GET_RELATIONSHIP_BETWEEN_PEDS(entry.handle, previous) <= 2
            and PED.GET_RELATIONSHIP_BETWEEN_PEDS(previous, entry.handle) <= 2) then
        self:clear_task(entry); return
    end
    if entry.task == 'combat' and entry.combat_target == target and PED.IS_PED_IN_COMBAT(entry.handle, target) then return end
    self:clear_task(entry); entry.task = 'combat'; entry.combat_target = target
    local p = state.ped:get_position(); TASK.TASK_SET_SPHERE_DEFENSIVE_AREA(entry.handle, p.x, p.y, p.z, 10)
    local output = memory.allocate(4)
    assert(output and output:get_address() ~= 0, 'Cannot allocate combat sequence output')
    local ok, err = pcall(function()
        TASK.OPEN_SEQUENCE_TASK(output); entry.sequence = output:get_int()
        TASK.TASK_COMBAT_PED(0, target, 0, 16); TASK.SET_SEQUENCE_TO_REPEAT(entry.sequence, true)
        TASK.CLOSE_SEQUENCE_TASK(entry.sequence); TASK.TASK_PERFORM_SEQUENCE(entry.handle, entry.sequence)
    end)
    memory.free(output); if not ok then error(err) end
end

function Guards:override(entry, callback, duration, description)
    self:clear_task(entry); entry.task = 'override'
    entry.override = {
        callback = callback,
        deadline = duration and duration >= 0 and util.time() + duration * 1000 or
            nil,
        description = description or 'Custom command',
        ran = false
    }
end

function Guards:dismiss(entry)
    self:clear_task(entry); entry.dismissed = true; entry.task = 'dismissed'
    self.service:run('guard_dismiss', function(valid)
        if PED.IS_PED_IN_ANY_VEHICLE(entry.handle, true) then
            TASK.TASK_LEAVE_ANY_VEHICLE(entry.handle, 0, 0); script.yield(500); if not valid() then return end
        end
        TASK.TASK_WANDER_STANDARD(entry.handle, 0, 0); self.service.blips:remove(entry.blip)
        script.yield(9000)
        if not valid() or not self.service.pool:exists(entry) then return end
        if network.is_session_started() then NETWORK.NETWORK_FADE_OUT_ENTITY(entry.handle, true, true) end
        script.yield(1000); if valid() then self:remove(entry) end
    end)
end

function Guards:evaluate(entry, state, position, now)
    if entry.task == 'none' or entry.task == 'sitting' or entry.task == 'stand_guard' then
        entry.evaluation_task = nil; entry.last_position = nil; return
    end
    if entry.evaluation_task ~= entry.task then
        entry.evaluation_task = entry.task; entry.evaluation_at = now + 10000; entry.last_position = position; return
    end
    if now < entry.evaluation_at then return end
    local moved = Geometry.distance(position, entry.last_position)
    local on_foot = PED.IS_PED_ON_FOOT(entry.handle)
    if not locked[entry.task] and moved < 0.2 and on_foot and TASK.IS_PED_STILL(entry.handle) and not PED.IS_PED_IN_COMBAT(entry.handle, 0) then
        self:clear_task(entry)
        local group = entry.escort
        if group and self.service.pool:exists(group.vehicle) then
            TASK.TASK_WARP_PED_INTO_VEHICLE(entry.handle,
                group.vehicle.handle, entry.seat)
        end
    end
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(entry.handle, false)
    if entry.task == 'vehicle_follow' then
        if vehicle == 0 or not ENTITY.DOES_ENTITY_EXIST(vehicle) then
            self:clear_task(entry)
        elseif state.vehicle and ENTITY.GET_ENTITY_SPEED(state.vehicle_handle) >= 10
            and Geometry.distance(position, state.ped:get_position()) >= 69 and ENTITY.GET_ENTITY_SPEED(vehicle) <= 3 then
            local destination = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(state.handle, 0, -10, 0)
            ENTITY.SET_ENTITY_HEADING(vehicle, ENTITY.GET_ENTITY_HEADING(state.handle))
            PED.SET_PED_COORDS_KEEP_VEHICLE(entry.handle, destination.x, destination.y, destination.z)
            local speed = ENTITY.GET_ENTITY_SPEED(state.vehicle_handle)
            if state.driving and speed > 5 then VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, speed - 5) end
        end
    end
    local group = entry.escort
    if group and self.service.pool:exists(group.vehicle) and (vehicle == 0 or on_foot) and not state.on_foot then
        self:clear_task(entry); TASK.TASK_WARP_PED_INTO_VEHICLE(entry.handle, group.vehicle.handle, entry.seat)
    end
    if PED.IS_PED_IN_PARACHUTE_FREE_FALL(entry.handle) then
        PED.FORCE_PED_TO_OPEN_PARACHUTE(entry.handle); entry.task = 'parachute'
    end
    entry.evaluation_task = nil; entry.last_position = nil
end

function Guards:update(entry, state, now)
    if not self:alive(entry) then
        self:remove(entry); return
    end
    self.service.blips:visible(entry.blip, not PED.IS_PED_IN_ANY_VEHICLE(entry.handle, true))
    if now < entry.next_update or entry.dismissed then return end
    entry.next_update = now + 1000
    if entry.override then
        if entry.override.deadline and now >= entry.override.deadline then
            self:clear_task(entry)
        elseif not entry.override.ran then
            entry.override.ran = true; if entry.override.callback then entry.override.callback(entry) end
        end
        return
    end
    local position = ENTITY.GET_ENTITY_COORDS(entry.handle, false)
    local distance = Geometry.distance(position, state.ped:get_position())
    if entry.role == 'bodyguard' and distance > 200 and not entry.busy and not CAMERA.IS_SCREEN_FADING_OUT() and not CAMERA.IS_SCREEN_FADED_OUT()
        and not (PLAYER.IS_PLAYER_TELEPORT_ACTIVE() and not PLAYER.UPDATE_PLAYER_TELEPORT(state.player_id)) then
        if state.vehicle and PED.IS_PED_ON_FOOT(entry.handle) and VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(state.vehicle_handle) then
            TASK.TASK_WARP_PED_INTO_VEHICLE(entry.handle, state.vehicle_handle, -2)
        elseif state.vehicle and (state.aircraft and ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(state.handle) >= 5 or ENTITY.IS_ENTITY_IN_WATER(state.handle)) then
            self:dismiss(entry); self.ctx.notifier:info("Samurai's Scripts",
                'Some of your bodyguards have been dismissed.'); return
        elseif self.ctx.game.outside(state.handle) then
            local in_vehicle = PED.IS_PED_IN_ANY_VEHICLE(entry.handle, false)
            local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(state.handle,
                in_vehicle and -math.random(-6, 6) or math.random(-3, 3),
                in_vehicle and -math.random(6, 12) or -math.random(3, 6), 0.1)
            local vehicle = PED.GET_VEHICLE_PED_IS_IN(entry.handle, false)
            ENTITY.SET_ENTITY_HEADING(vehicle ~= 0 and vehicle or entry.handle, ENTITY.GET_ENTITY_HEADING(state.handle))
            PED.SET_PED_COORDS_KEEP_VEHICLE(entry.handle, pos.x, pos.y, pos.z)
            if entry.task == 'vehicle_follow' and vehicle ~= 0 and state.vehicle then
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(
                    vehicle, ENTITY.GET_ENTITY_SPEED(state.vehicle_handle) + 0.5)
            end
        end
    end
    if PED.IS_PED_IN_COMBAT(state.handle, 0) then
        local target = PED.GET_MELEE_TARGET_FOR_PED(state.handle)
        if target == 0 then target = PED.GET_PED_TARGET_FROM_COMBAT_PED(state.handle) end
        if target ~= 0 then
            self:engage(entry, target, state); return
        end
    end
    if entry.task == 'combat' and (not PED.IS_PED_IN_COMBAT(entry.handle, 0) or PED.IS_PED_IN_COMBAT(entry.handle, state.handle)) then
        self:clear_task(entry)
    end
    if not entry.busy and entry.role == 'bodyguard' then
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(entry.handle, false)
        if state.vehicle and vehicle == 0 then
            self:queue(entry, 'enter_vehicle', function(valid) self:enter(entry, state.vehicle_handle, nil, valid) end,
                true)
        elseif state.vehicle and vehicle ~= state.vehicle_handle and VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1, false) == entry.handle then
            if state.land_vehicle then
                TASK.TASK_VEHICLE_ESCORT(entry.handle, vehicle, state.vehicle_handle, -1, 60, 24904187, 5, 5, 5); entry.task =
                'vehicle_follow'
            end
        elseif state.on_foot and vehicle ~= 0 then
            self:queue(entry, 'leave_vehicle', function(valid)
                local heli = self.service.vehicles.active.heli
                local seat
                for index = 0, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle) - 1 do
                    if VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, index, false) == entry.handle then
                        seat = index; break
                    end
                end
                if heli and heli.vehicle.handle == vehicle and heli.rappelling and seat and seat > 0 then
                    TASK.TASK_RAPPEL_FROM_HELI(entry.handle, 10); entry.task = 'rappel'
                else
                    TASK.TASK_LEAVE_ANY_VEHICLE(entry.handle, 0, 0); local deadline = util.time() + 5000
                    while valid() and PED.IS_PED_IN_ANY_VEHICLE(entry.handle, false) and util.time() < deadline do
                        script
                            .yield(50)
                    end
                    entry.task = 'none'
                end
            end, true)
        elseif state.on_foot and distance > 3 and entry.task ~= 'follow' then
            TASK.TASK_GO_TO_ENTITY(entry.handle, state.handle, -1, 5, 3, 1073741824, 0); entry.task = 'follow'
        elseif state.on_foot and entry.task == 'follow' and PED.IS_PED_STOPPED(entry.handle) then
            entry.task = 'none'
        end
    end
    if not entry.busy and #entry.queue > 0 then
        local task = table.remove(entry.queue, 1); self:operation(entry, task.task, task.callback)
    end
    self:evaluate(entry, state, position, now)
end

function Guards:clear()
    for _, entry in pairs(self.members) do self:remove(entry) end
    self.members = {}; self.seats = {}; self.targets = {}
end

return Guards
