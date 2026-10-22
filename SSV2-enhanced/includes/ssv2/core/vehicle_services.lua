local Geometry = require('includes.ssv2.core.geometry')
local Vehicles = {}; Vehicles.__index = Vehicles
local pilot_model = 0xE75B4B1C
function Vehicles.new(ctx, service) return setmetatable({ ctx = ctx, service = service, active = {} }, Vehicles) end

function Vehicles:exists(entry)
    return entry and self.service.pool:exists(entry.vehicle) and self.service.pool:exists(entry.driver)
        and not ENTITY.IS_ENTITY_DEAD(entry.driver.handle, false)
end

function Vehicles:repair(entry, clean)
    local handle = entry.vehicle.handle
    assert(self.service.pool:exists(entry.vehicle), 'Vehicle no longer exists')
    VEHICLE.SET_VEHICLE_FIXED(handle); VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(handle)
    if clean then VEHICLE.SET_VEHICLE_DIRT_LEVEL(handle, 0) end
    self.ctx.build:require_supported()
    local flags = memory.handle_to_ptr(handle):add(0xD8)
    flags:set_dword(bit.band(flags:get_dword(), bit.bnot(1)) % 4294967296)
end

function Vehicles:performance(entry)
    local handle = entry.vehicle.handle
    VEHICLE.SET_VEHICLE_MOD_KIT(handle, 0)
    for _, kind in ipairs({ 16, 11, 12, 13, 15 }) do
        VEHICLE.SET_VEHICLE_MOD(handle, kind,
            VEHICLE.GET_NUM_VEHICLE_MODS(handle, kind) - 1, false)
    end
    VEHICLE.TOGGLE_VEHICLE_MOD(handle, 18, true); VEHICLE.TOGGLE_VEHICLE_MOD(handle, 22, true)
    self:repair(entry, true)
end

function Vehicles:paint(handle, preset)
    if not preset.color then return end
    for _, kind in ipairs({ 'primary', 'secondary' }) do
        local color = preset.color[kind]
        if color then
            local hex = color.hex; assert(type(hex) == 'string' and hex:match('^#%x%x%x%x%x%x$'), 'Invalid service paint')
            local r, g, b = tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
            if kind == 'primary' then
                VEHICLE.SET_VEHICLE_MOD_COLOR_1(handle, color.m and 3 or 1, 0, color.p or 0)
                VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(handle, r, g, b); VEHICLE.SET_VEHICLE_EXTRA_COLOURS(handle,
                    color.p or 0, 0)
            else
                VEHICLE.SET_VEHICLE_MOD_COLOR_2(handle, color.m and 3 or 1, 0); VEHICLE
                    .SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(handle, r, g, b)
            end
        end
    end
    if preset.color.interior ~= nil then VEHICLE.SET_VEHICLE_EXTRA_COLOUR_5(handle, preset.color.interior) end
    if preset.wheelColor ~= nil then
        VEHICLE.SET_VEHICLE_EXTRA_COLOURS(handle,
            preset.color.primary and preset.color.primary.p or 0, preset.wheelColor)
    end
end

function Vehicles:prepare_driver(driver, vehicle, seat, invincible)
    local handle = driver.handle
    ENTITY.SET_ENTITY_INVINCIBLE(handle, invincible)
    PED.SET_PED_INTO_VEHICLE(handle, vehicle.handle, seat)
    PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(handle, 1); PED.SET_PED_CAN_BE_SHOT_IN_VEHICLE(handle, false)
    PED.SET_PED_CAN_BE_DRAGGED_OUT(handle, false); PED.SET_PED_CAN_BE_TARGETTED(handle, false)
    PED.SET_PED_CONFIG_FLAG(handle, 251, true); PED.SET_PED_CONFIG_FLAG(handle, 255, true)
    PED.SET_PED_COMBAT_ATTRIBUTES(handle, 3, false); PED.SET_PED_COMBAT_ATTRIBUTES(handle, 17, false); PED
        .SET_PED_COMBAT_ATTRIBUTES(handle, 20, true)
    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(handle, true); self.service.guards.group:add(handle)
    PED.SET_PED_CAN_EVASIVE_DIVE(handle, true)
    if seat == 0 or VEHICLE.IS_THIS_MODEL_A_PLANE(vehicle.model) then PED.SET_PED_CONFIG_FLAG(handle, 177, true) end
end

function Vehicles:spawn(kind, model, preset, invincible, valid)
    assert(not self.active[kind], 'This private service is already active')
    local state = self.ctx.state:read(); assert(state, 'Player is unavailable')
    if kind == 'heli' then assert(self.ctx.game.outside(state.handle), 'Call your helicopter outside') end
    local position, heading
    if kind == 'jet' then
        position, heading = preset.hangar.pos, preset.hangar.heading
    elseif kind == 'heli' then
        position = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(state.handle, 0, 30, 50); heading = ENTITY
            .GET_ENTITY_HEADING(state.handle) - 90
    else
        position = self.ctx.game.spawn_point(state.ped:get_position(), ENTITY.GET_ENTITY_FORWARD_VECTOR(state.handle), 10)
        position = position or ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(state.handle, 0, 15, 0.1); heading = ENTITY
            .GET_ENTITY_HEADING(state.handle)
    end
    local pool = self.service.pool; local created = {}; local entry
    local ok, result = pcall(function()
        local vehicle = pool:create('vehicle', model, position, heading, valid, nil,
            kind == 'heli' and network.is_session_started())
        if not vehicle then return end; created[#created + 1] = vehicle
        if kind ~= 'limo' then ENTITY.FREEZE_ENTITY_POSITION(vehicle.handle, true) end
        local driver = pool:create('ped', pilot_model, Vector3.new(0, 0, 0), 0, valid)
        if not driver then return end; created[#created + 1] = driver
        entry = {
            kind = kind,
            vehicle = vehicle,
            driver = driver,
            task = 'idle',
            mode = 0,
            ready = false,
            token = 0,
            preset = preset,
            destination = nil,
            radio = 'RADIO_22_DLC_BATTLE_MIX1_RADIO',
            next_update = 0,
            driver_name = self.service:random_name(0)
        }
        entry.name = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(model))
        local protected = kind ~= 'heli' or invincible or false
        self:prepare_driver(driver, vehicle, -1, protected)
        if kind == 'jet' then
            local copilot = pool:create('ped', 0x864ED68E, Vector3.new(0, 0, 0), 0, valid)
            if not copilot then return end; created[#created + 1] = copilot; entry.copilot = copilot
            self:prepare_driver(copilot, vehicle, 0, true); entry.copilot_name = self.service:random_name(0); entry.departure =
                preset
            STREAMING.REQUEST_COLLISION_AT_COORD(position.x, position.y, position.z)
            ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(vehicle.handle, true, true)
        end
        local handle = vehicle.handle
        if kind == 'limo' then
            ENTITY.SET_ENTITY_PROOFS(handle, true, false, false, false, false, false, false, false)
            VEHICLE.SET_VEHICLE_CAN_BE_TARGETTED(handle, false); VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(handle, false)
            VEHICLE.SET_DONT_PROCESS_VEHICLE_GLASS(handle, true)
            VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(handle, 'OMW2FYB'); VEHICLE.SET_VEHICLE_WINDOW_TINT(handle,
                preset.window_tint or 1)
            for i = 0, VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(handle) - 1 do
                VEHICLE.SET_DOOR_ALLOWED_TO_BE_BROKEN_OFF(
                    handle, i, false)
            end
            self:performance(entry)
            if preset.wheelType ~= nil then VEHICLE.SET_VEHICLE_WHEEL_TYPE(handle, preset.wheelType) end
            for slot, value in pairs(preset.mods or {}) do VEHICLE.SET_VEHICLE_MOD(handle, slot - 1, value, false) end
            self:paint(handle, preset)
            VEHICLE.SET_VEHICLE_INDIVIDUAL_DOORS_LOCKED(handle, 1, 2)
        else
            ENTITY.SET_ENTITY_INVINCIBLE(handle, protected); VEHICLE.SET_ALLOW_VEHICLE_EXPLODES_ON_CONTACT(handle, false)
            VEHICLE.SET_VEHICLE_STRONG(handle, true); VEHICLE.SET_VEHICLE_OCCUPANTS_TAKE_EXPLOSIVE_DAMAGE(handle, false)
        end
        VEHICLE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(handle, false, false)
        VEHICLE.SET_VEHICLE_INDIVIDUAL_DOORS_LOCKED(handle, 0, 2); VEHICLE.SET_VEHICLE_ENGINE_ON(handle, true, true,
            false)
        VEHICLE.SET_VEHICLE_DIRT_LEVEL(handle, 0)
        if coroutine.running() then
            if kind == 'heli' then
                script.yield(500)
            else
                local deadline = kind == 'limo' and util.time() + 1000 or nil
                while valid() and not VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(handle) and (not deadline or util.time() < deadline) do
                    script.yield(0)
                end
                script.yield(1000)
            end
            if not valid() then return end
        end
        if kind ~= 'limo' then ENTITY.FREEZE_ENTITY_POSITION(handle, false) end
        if kind == 'heli' then
            VEHICLE.SET_HELI_BLADES_SPEED(handle, 1)
        else
            VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(
                handle, 5)
        end
        entry.blip = self.service.blips:add(handle,
            kind == 'limo' and 'Private Limousine' or kind == 'heli' and 'Private Heli' or 'Private Jet',
            kind == 'limo' and 724 or kind == 'heli' and 422 or 423, 1, false)
        AUDIO.SET_VEHICLE_RADIO_ENABLED(handle, true); AUDIO.SET_VEH_RADIO_STATION(handle, entry.radio); AUDIO
            .SET_VEHICLE_RADIO_LOUD(handle, true)
        if network.is_session_started() then
            for _, entity in ipairs(created) do
                NETWORK.NETWORK_FADE_IN_ENTITY(
                    entity.handle, true, 0)
            end
        end
        if kind == 'jet' then
            self:repair(entry, true); VEHICLE.SET_VEHICLE_DOOR_OPEN(handle, 0, false, false)
        end
        entry.ready = true; self.active[kind] = entry
        if kind == 'heli' and not ENTITY.IS_ENTITY_IN_WATER(state.handle)
            and not (state.vehicle and VEHICLE.IS_THIS_MODEL_A_BOAT(state.vehicle:get_model())) then
            self:land(entry)
        end
        return entry
    end)
    if not ok or not result or not valid() then
        if entry and entry.blip then self.service.blips:remove(entry.blip) end
        for i = #created, 1, -1 do pool:delete(created[i].handle) end
        if self.active[kind] == entry then self.active[kind] = nil end
        if not ok then error(result) end
        return nil
    end
    return result
end

function Vehicles:speak(entry, name, params)
    if self:exists(entry) then
        AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(entry.driver.handle, name or 'GENERIC_YES',
            params or 'SPEECH_PARAMS_FORCE_SHOUTED', 0)
    end
end

function Vehicles:cancel(entry, preserve_operation)
    if not self:exists(entry) or entry.remote then return end
    if not preserve_operation then
        entry.token = entry.token + 1; entry.busy = false
    end
    local cruising = entry.kind == 'jet' and entry.task == 'goto' and
        ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(entry.vehicle.handle) > 20
        and ENTITY.GET_ENTITY_SPEED(entry.vehicle.handle) > 20
    entry.task = cruising and 'wander' or 'idle'; entry.destination = nil
    TASK.CLEAR_PED_TASKS(entry.driver.handle); TASK.CLEAR_PED_SECONDARY_TASK(entry.driver.handle)
    TASK.CLEAR_PRIMARY_VEHICLE_TASK(entry.vehicle.handle)
    if entry.kind ~= 'jet' then TASK.TASK_VEHICLE_TEMP_ACTION(entry.driver.handle, entry.vehicle.handle, 1, 2000) end
end

function Vehicles:operation(entry, label, callback)
    if not self:exists(entry) or entry.busy then return end
    entry.token = entry.token + 1; entry.busy = true; local token = entry.token
    self.service:run(label, function(valid)
        local function current()
            return valid() and self.active[entry.kind] == entry and entry.token == token and
                self:exists(entry)
        end
        local ok, err = pcall(function() if current() then callback(current) end end)
        if entry.token == token then entry.busy = false end
        if entry.screen_fading then
            CAMERA.DO_SCREEN_FADE_IN(0); entry.screen_fading = false
        end
        if not ok then error(err) end
    end)
end

function Vehicles:warp(entry)
    assert(self:exists(entry), 'Private vehicle is unavailable')
    if entry.kind == 'heli' and VEHICLE.IS_ANY_PED_RAPPELLING_FROM_HELI(entry.vehicle.handle) then return end
    local seat = 2
    if not VEHICLE.IS_VEHICLE_SEAT_FREE(entry.vehicle.handle, seat, true) then seat = -2 end
    if entry.kind == 'jet' then
        local position = ENTITY.GET_ENTITY_COORDS(entry.vehicle.handle, false)
        STREAMING.REQUEST_COLLISION_AT_COORD(position.x, position.y, position.z)
        STREAMING.REQUEST_ADDITIONAL_COLLISION_AT_COORD(position.x, position.y, position.z)
    end
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.PLAYER_PED_ID()); TASK.TASK_WARP_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(),
        entry.vehicle.handle, seat)
    if entry.kind == 'jet' then
        ENTITY.SET_ENTITY_VISIBLE(entry.vehicle.handle, true, true); ENTITY.SET_ENTITY_ALPHA(entry.vehicle.handle, 255,
            false)
    end
end

function Vehicles:hover(entry)
    if not self:exists(entry) or VEHICLE.IS_ANY_PED_RAPPELLING_FROM_HELI(entry.vehicle.handle) then return end
    self:speak(entry, 'GENERIC_YES'); self:cancel(entry)
    entry.task = 'hover'
end

function Vehicles:shuffle(entry, direction)
    local state = self.ctx.state:read(); if not state or state.vehicle_handle ~= entry.vehicle.handle then return end
    local maximum = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(entry.vehicle.handle) - 1
    local seat = 1
    for i = -1, maximum do
        if VEHICLE.GET_PED_IN_VEHICLE_SEAT(entry.vehicle.handle, i, false) == state.handle then
            seat = i; break
        end
    end
    for _ = 1, maximum do
        seat = seat + direction; if seat > maximum then seat = 1 elseif seat < 1 then seat = maximum end
        if VEHICLE.IS_VEHICLE_SEAT_FREE(entry.vehicle.handle, seat, true) then
            PED.SET_PED_INTO_VEHICLE(state.handle, entry.vehicle.handle, seat); return
        end
    end
end

function Vehicles:drive(entry, position, wander)
    if not self:exists(entry) or entry.remote then return end
    self:cancel(entry)
    local flags, speed = entry.mode == 0 and 786603 or 2886204, entry.mode == 0 and 19 or 60
    if wander then
        TASK.TASK_VEHICLE_DRIVE_WANDER(entry.driver.handle, entry.vehicle.handle, speed, flags); entry.task = 'wander'
    else
        TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(entry.driver.handle, entry.vehicle.handle, position.x, position.y,
            position.z, speed, flags, 25)
        entry.destination = position; entry.task = 'goto'
    end
end

function Vehicles:park(entry)
    self:cancel(entry)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entry.vehicle.handle, 2, 10, 0)
    TASK.TASK_VEHICLE_PARK(entry.driver.handle, entry.vehicle.handle, pos.x, pos.y, pos.z,
        ENTITY.GET_ENTITY_HEADING(entry.vehicle.handle), 0, 100, true)
    entry.task = 'parking'
end

function Vehicles:land(entry, preserve_operation)
    self:cancel(entry, preserve_operation); self:speak(entry, 'GENERIC_YES')
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entry.vehicle.handle, 0, 0, -0.1)
    TASK.TASK_HELI_MISSION(entry.driver.handle, entry.vehicle.handle, 0, 0, pos.x, pos.y, pos.z, 19, 8, 1, 0, -1, 3, 10,
        32)
    entry.task = 'land'
end

function Vehicles:fly(entry, position, airport, land_on_arrival)
    if entry.kind == 'heli' then
        self:cancel(entry); self:speak(entry, 'CHAT_RESP')
        TASK.TASK_HELI_MISSION(entry.driver.handle, entry.vehicle.handle, 0, 0, position.x, position.y, position.z, 4, 50,
            4, -1, -1, 100, 100, land_on_arrival and 32 or 0)
        entry.destination = position; entry.task = 'goto'; return
    end
    assert(Geometry.distance(ENTITY.GET_ENTITY_COORDS(entry.vehicle.handle, false), position) > 500,
        'The jet destination is too close')
    self:operation(entry, 'jet_flight', function(valid)
        entry.arrival = airport
        if entry.departure then
            entry.task = 'takeoff'; local departure = entry.departure
            VEHICLE.SET_VEHICLE_DOORS_SHUT(entry.vehicle.handle, false)
            local p = departure.taxiPos
            TASK.TASK_VEHICLE_DRIVE_TO_COORD(entry.driver.handle, entry.vehicle.handle, p.x, p.y, p.z, 5, 0,
                entry.vehicle.model, 8388614, 10, 10)
            script.yield(6000); if not valid() then return end
            entry.screen_fading = true; CAMERA.DO_SCREEN_FADE_OUT(1000)
            script.yield(1000); if not valid() then return end
            local pos = departure.cutPos; ENTITY.SET_ENTITY_COORDS(entry.vehicle.handle, pos.x, pos.y, pos.z, true, true,
                true, true)
            VEHICLE.SET_VEHICLE_FORWARD_SPEED(entry.vehicle.handle, 100); VEHICLE.CONTROL_LANDING_GEAR(
                entry.vehicle.handle, 1)
            CAMERA.DO_SCREEN_FADE_IN(1000); entry.screen_fading = false; entry.departure = nil
        end
        if not valid() then return end
        local altitude = airport and 0 or 600
        TASK.TASK_PLANE_MISSION(entry.driver.handle, entry.vehicle.handle, 0, 0, position.x, position.y,
            position.z + altitude, 4, 100, 0, 90, 5000, 200, true)
        entry.destination = position; entry.task = 'goto'
    end)
end

function Vehicles:bring(entry)
    local state = self.ctx.state:read(); if not state then return end
    assert(self.ctx.game.outside(state.handle), 'Bring this service outside')
    if entry.kind == 'heli' and ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(entry.vehicle.handle) < 3
        and Geometry.distance(state.ped:get_position(), ENTITY.GET_ENTITY_COORDS(entry.vehicle.handle, false)) < 10 then
        self.ctx.notifier:warn('Private Heli', 'Your helicopter is already closeby.'); return
    end
    self:cancel(entry)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(state.handle, 0, entry.kind == 'heli' and 10 or 15,
        entry.kind == 'heli' and 20 or 0.1)
    ENTITY.SET_ENTITY_COORDS(entry.vehicle.handle, pos.x, pos.y, pos.z, true, true, true, true)
    ENTITY.SET_ENTITY_HEADING(entry.vehicle.handle,
        ENTITY.GET_ENTITY_HEADING(state.handle) - (entry.kind == 'heli' and 90 or 0))
    if entry.kind == 'heli' then
        if coroutine.running() then script.yield(100) end; self:land(entry)
    else
        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(entry.vehicle.handle, 5)
    end
end

function Vehicles:skip(entry)
    if not entry.destination or entry.kind == 'heli' and VEHICLE.IS_ANY_PED_RAPPELLING_FROM_HELI(entry.vehicle.handle) then return end
    if entry.kind == 'heli' and entry.task ~= 'goto' then return end
    local destination = entry.destination
    self:operation(entry, 'private_skip_trip', function(valid)
        if entry.kind == 'heli' then
            local handle = entry.vehicle.handle; local heading = ENTITY.GET_ENTITY_HEADING(handle)
            entry.screen_fading = true; CAMERA.DO_SCREEN_FADE_OUT(1000)
            script.yield(1000); if not valid() then return end
            VEHICLE.SET_VEHICLE_FORWARD_SPEED(handle, 0); script.yield(500); if not valid() then return end
            ENTITY.SET_ENTITY_COORDS(handle, destination.x, destination.y, destination.z + 8, true, true, true, true)
            MISC.CLEAR_AREA_OF_VEHICLES(destination.x, destination.y, destination.z, 5, false, false, false, false, false,
                false, 0)
            ENTITY.SET_ENTITY_HEADING(handle, heading); script.yield(50); if not valid() then return end
            self:land(entry, true); script.yield(1000); if not valid() then return end
            CAMERA.DO_SCREEN_FADE_IN(1000); entry.screen_fading = false; entry.task = 'idle'; entry.destination = nil
            return
        end
        entry.screen_fading = true; CAMERA.DO_SCREEN_FADE_OUT(1000)
        script.yield(1000); if not valid() then return end
        local altitude = entry.kind == 'jet' and (entry.arrival and 0 or 600) or entry.kind == 'heli' and 8 or 0
        ENTITY.SET_ENTITY_COORDS(entry.vehicle.handle, destination.x, destination.y, destination.z + altitude, true, true,
            true, true)
        if entry.kind == 'heli' then VEHICLE.SET_VEHICLE_FORWARD_SPEED(entry.vehicle.handle, 0) end
        script.yield(1000); if not valid() then return end
        CAMERA.DO_SCREEN_FADE_IN(1000); entry.screen_fading = false
        if entry.kind == 'heli' then
            self:land(entry)
        elseif entry.kind == 'limo' then
            self:park(entry)
        elseif not entry.arrival then
            entry.task =
            'wander'
        end
        entry.destination = nil
    end)
end

function Vehicles:finish_landing(entry)
    if not entry.arrival then return end
    local airport = entry.arrival
    self:operation(entry, 'jet_finish_landing', function(valid)
        local limo = self.active.limo
        if limo and self:exists(limo) then
            local point = airport.limoTeleport.pos
            MISC.CLEAR_AREA_OF_VEHICLES(point.x, point.y, point.z, 5, false, false, false, false, false, false, 0)
            ENTITY.SET_ENTITY_COORDS(limo.vehicle.handle, point.x, point.y, point.z, true, true, true, true)
            ENTITY.SET_ENTITY_HEADING(limo.vehicle.handle, airport.limoTeleport.heading)
            VEHICLE.SET_VEHICLE_DOOR_OPEN(limo.vehicle.handle, 2, false, true)
            self.ctx.notifier:info('Private Jet', 'Your limousine is waiting for you at ' .. airport.name .. '.')
        end
        entry.screen_fading = true; CAMERA.DO_SCREEN_FADE_OUT(1000)
        script.yield(1000); if not valid() then return end
        TASK.CLEAR_PED_TASKS(entry.driver.handle); TASK.CLEAR_PRIMARY_VEHICLE_TASK(entry.vehicle.handle)
        VEHICLE.CONTROL_LANDING_GEAR(entry.vehicle.handle, 0); VEHICLE.SET_VEHICLE_FORWARD_SPEED(entry.vehicle.handle, 0)
        script.yield(1000); if not valid() then return end
        local pos = airport.hangar.pos
        MISC.CLEAR_AREA_OF_VEHICLES(pos.x, pos.y, pos.z, 5, false, false, false, false, false, false, 0)
        ENTITY.SET_ENTITY_COORDS(entry.vehicle.handle, pos.x, pos.y, pos.z, true, true, true, true)
        ENTITY.SET_ENTITY_HEADING(entry.vehicle.handle, airport.hangar.heading)
        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(entry.vehicle.handle, 5)
        script.yield(200); if not valid() then return end
        CAMERA.DO_SCREEN_FADE_IN(1000); entry.screen_fading = false
        VEHICLE.SET_VEHICLE_ENGINE_ON(entry.vehicle.handle, false, false, false)
        script.yield(500); if not valid() then return end
        VEHICLE.SET_VEHICLE_DOOR_OPEN(entry.vehicle.handle, 0, false, false)
        self.ctx.notifier:info('Private Jet', 'Welcome to ' .. airport.name .. '. We hope you had a good time!')
        entry.departure = airport; entry.arrival = nil; entry.destination = nil; entry.task = 'idle'
    end)
end

function Vehicles:remove(entry)
    entry.token = entry.token + 1; entry.busy = false
    if entry.remote then require('includes.ssv2.core.limo_remote').release(self, entry, true) end
    if entry.screen_fading then
        CAMERA.DO_SCREEN_FADE_IN(0); entry.screen_fading = false
    end
    self.service.blips:remove(entry.blip)
    if entry.copilot then self.service.pool:delete(entry.copilot.handle) end
    self.service.pool:delete(entry.driver.handle); self.service.pool:delete(entry.vehicle.handle)
    if self.active[entry.kind] == entry then self.active[entry.kind] = nil end
end

function Vehicles:dismiss(entry)
    if entry.dismissed then return end
    if entry.remote then require('includes.ssv2.core.limo_remote').release(self, entry, true) end
    self:cancel(entry); entry.dismissed = true
    self:operation(entry, 'private_dismiss', function(valid)
        local handle = entry.vehicle.handle
        if entry.kind == 'heli' and ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(handle) > 5 and PED.IS_PED_IN_VEHICLE(PLAYER.PLAYER_PED_ID(), handle, false) then
            self:land(entry, true); local deadline = util.time() + 30000
            while valid() and ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(handle) > 3 and util.time() < deadline do
                script
                    .yield(100)
            end
        else
            VEHICLE.SET_VEHICLE_FORWARD_SPEED(handle, 0)
        end
        TASK.TASK_EVERYONE_LEAVE_VEHICLE(handle)
        local deadline = util.time() + 10000
        while valid() and PED.IS_PED_IN_VEHICLE(PLAYER.PLAYER_PED_ID(), handle, false) and util.time() < deadline do
            script.yield(100)
        end
        if not valid() then return end
        if entry.kind == 'limo' then
            TASK.TASK_VEHICLE_DRIVE_WANDER(entry.driver.handle, handle, 19, 786603)
        elseif entry.kind == 'heli' then
            local p = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(handle, math.random(-1000, 1000),
                math.random(-1000, 1000), 500)
            TASK.TASK_HELI_MISSION(entry.driver.handle, handle, 0, 0, p.x, p.y, p.z, 4, 50, 4, -1, -1, 100, 100, 0)
        end
        entry.task = 'going_home'; script.yield(9000); if not valid() then return end
        if network.is_session_started() then
            NETWORK.NETWORK_FADE_OUT_ENTITY(handle, true, true); NETWORK.NETWORK_FADE_OUT_ENTITY(entry.driver.handle,
                true, true)
        end
        script.yield(1000); if valid() then self:remove(entry) end
    end)
end

function Vehicles:update(entry, state, now)
    if not self:exists(entry) then
        self:remove(entry); return
    end
    if entry.remote then require('includes.ssv2.core.limo_remote').update(self, entry, state) end
    if now < (entry.next_update or 0) then return end
    entry.next_update = now + (entry.kind == 'limo' and 1000 or 2000)
    local handle = entry.vehicle.handle
    entry.in_vehicle = state.vehicle_handle == handle or entry.remote ~= nil
    entry.altitude = ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(handle); entry.speed = ENTITY.GET_ENTITY_SPEED(handle)
    entry.position = ENTITY.GET_ENTITY_COORDS(handle, false)
    local distance = Geometry.distance(entry.position, state.ped:get_position())
    entry.far_away = not entry.in_vehicle and distance > (entry.kind == 'jet' and 500 or 50)
    entry.can_warp = not entry.in_vehicle and distance > 500
    if entry.kind == 'heli' then entry.allows_rappel = VEHICLE.DOES_VEHICLE_ALLOW_RAPPEL(handle) end
    entry.radio = AUDIO.IS_VEHICLE_RADIO_ON(handle) and AUDIO.GET_PLAYER_RADIO_STATION_NAME() or 'OFF'
    self.service.blips:visible(entry.blip, not entry.in_vehicle)
    if entry.dismissed or entry.busy or entry.remote then return end
    if entry.kind == 'jet' and ENTITY.IS_ENTITY_IN_WATER(handle) then
        self:remove(entry); return
    end
    if not VEHICLE.IS_VEHICLE_DRIVEABLE(handle, false) or ENTITY.IS_ENTITY_IN_WATER(handle) then
        if ENTITY.IS_ENTITY_IN_WATER(handle) then
            local pos, heading = self.ctx.game.closest_road(state.ped:get_position(), 0)
            if pos then
                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(handle, pos.x, pos.y, pos.z, false, false, false); ENTITY
                    .SET_ENTITY_HEADING(handle, heading)
            end
        end
        self:repair(entry, true)
    end
    if entry.kind == 'limo' then
        if not entry.in_vehicle and entry.task ~= 'idle' then
            self:cancel(entry)
        elseif entry.task == 'goto' and entry.destination and Geometry.distance(entry.position, entry.destination) <= math.max(50, entry.speed * 2.5) then
            self.ctx.notifier:info("Samurai's Scripts", '[Private Limo]: You have reached your destination.'); self:park(
                entry)
        end
        if entry.in_vehicle and PED.IS_PED_STOPPED(state.handle) then
            for seat = 0, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(handle) - 1 do
                if VEHICLE.GET_PED_IN_VEHICLE_SEAT(handle, seat, false) == state.handle and VEHICLE.GET_IS_DOOR_VALID(handle, seat + 1)
                    and not VEHICLE.IS_VEHICLE_DOOR_DAMAGED(handle, seat + 1) and VEHICLE.GET_VEHICLE_DOOR_ANGLE_RATIO(handle, seat + 1) > 0 then
                    VEHICLE.SET_VEHICLE_DOOR_SHUT(handle, seat + 1, false)
                end
            end
        elseif PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(state.handle) == handle and PED.IS_PED_TRYING_TO_ENTER_A_LOCKED_VEHICLE(state.handle) then
            self:warp(entry)
        end
    elseif entry.kind == 'heli' then
        entry.rappelling = VEHICLE.DOES_VEHICLE_ALLOW_RAPPEL(handle) and entry.altitude > 3 and
            VEHICLE.IS_ANY_PED_RAPPELLING_FROM_HELI(handle)
        if entry.task ~= 'idle' and entry.altitude >= 5 and (PED.IS_PED_IN_PARACHUTE_FREE_FALL(state.handle) or PED.GET_PED_PARACHUTE_STATE(state.handle) > 0 or PED.IS_PED_FALLING(state.handle)) then
            self:speak(entry, 'GENERIC_SHOCKED_HIGH', 'SPEECH_PARAMS_FORCE_HELI'); self.ctx.notifier:info('Private Heli',
                'Ayo! Is bro okay?'); self:hover(entry)
        elseif entry.task == 'land' and entry.altitude <= 3 then
            entry.task = 'idle'
        elseif entry.task == 'goto' and entry.destination and Geometry.distance({ x = entry.position.x, y = entry.position.y, z = 0 }, { x = entry.destination.x, y = entry.destination.y, z = 0 }) <= 50 then
            self.ctx.notifier:info("Samurai's Scripts", '[Private Heli]: You have reached your destination.'); entry.task =
            'idle'
        end
    elseif entry.kind == 'jet' then
        if entry.task == 'goto' and entry.altitude > 20 and entry.speed > 20 and (PED.IS_PED_IN_PARACHUTE_FREE_FALL(state.handle) or PED.GET_PED_PARACHUTE_STATE(state.handle) > 0 or PED.IS_PED_FALLING(state.handle)) then
            self:speak(entry, 'GENERIC_SHOCKED_HIGH', 'SPEECH_PARAMS_FORCE_HELI'); self.ctx.notifier:info('Private Jet',
                "Since you've decided to go for a skydive, your jet have been dismissed.")
            self:remove(entry); return
        end
        if entry.task == 'goto' and entry.arrival then
            local approach = entry.arrival.landingApproach
            local distance = Geometry.distance(entry.position, approach.pos)
            if distance > 1000 then
                TASK.TASK_PLANE_MISSION(entry.driver.handle, handle, 0, 0, approach.pos.x, approach.pos.y, approach.pos
                    .z, 4, 100, 0, approach.heading, 2000, 300, true)
            elseif distance > 200 then
                local a, b = entry.arrival.runwayStart, entry.arrival.runwayEnd
                TASK.TASK_PLANE_LAND(entry.driver.handle, handle, a.x, a.y, a.z, b.x, b.y, b.z); entry.task = 'land'
            end
        elseif entry.task == 'land' and entry.speed <= 5 and entry.altitude <= 2 then
            self:finish_landing(entry)
        elseif entry.task == 'goto' and entry.destination and Geometry.distance({ x = entry.position.x, y = entry.position.y, z = 0 }, { x = entry.destination.x, y = entry.destination.y, z = 0 }) <= 50 then
            self.ctx.notifier:info("Samurai's Scripts", '[Private Jet]: You have reached your destination.'); self
                :cancel(entry)
        end
    end
end

function Vehicles:clear()
    for _, entry in pairs(self.active) do self:remove(entry) end; self.active = {}
end

return Vehicles
