local Geometry = require('includes.ssv2.core.geometry')
local Escorts = {}; Escorts.__index = Escorts
function Escorts.new(ctx, service) return setmetatable({ ctx = ctx, service = service, groups = {} }, Escorts) end

function Escorts:vehicle(group, model, position, godmode, valid)
    local vehicle = self.service.pool:create('vehicle', model, position,
        ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID()), valid)
    if not vehicle then return end
    local handle = vehicle.handle
    ENTITY.SET_ENTITY_INVINCIBLE(handle, godmode or false)
    VEHICLE.SET_VEHICLE_MOD_KIT(handle, 0); VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(handle, 0, 1, 0)
    VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(handle, 0, 1, 0); VEHICLE.SET_VEHICLE_EXTRA_COLOURS(handle, 0, 0)
    VEHICLE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(handle, false, false); VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(handle,
        false)
    VEHICLE.SET_VEHICLE_STRONG(handle, true); VEHICLE.SET_VEHICLE_DIRT_LEVEL(handle, 0)
    VEHICLE.SET_VEHICLE_WINDOW_TINT(handle, 1); VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(handle, 'MRDR INC')
    group.vehicle = vehicle; self.service.vehicles:performance(group)
    group.blip = self.service.blips:add(handle, group.name, 229, 1.14, false)
    VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(handle, 5); VEHICLE.SET_VEHICLE_ENGINE_ON(handle, true, true, false)
    return vehicle
end

function Escorts:spawn(definition, godmode, no_ragdoll, valid, spawn_position)
    assert(type(definition) == 'table' and type(definition.members) == 'table' and #definition.members == 3,
        'An escort group requires three members')
    local state = self.ctx.state:read(); assert(state, 'Player is unavailable')
    local group = {
        name = definition.name or 'Escort Group',
        members = {},
        task = 'idle',
        mode = 0,
        godmode = godmode or
            false,
        no_ragdoll = no_ragdoll or false,
        next_update = 0
    }
    local created = {}
    local ok, result = pcall(function()
        local position = spawn_position or ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(state.handle, 0, -10, 1)
        local vehicle = self:vehicle(group, definition.vehicleModel, position, godmode, valid)
        if not vehicle then return end
        assert(VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle.handle) >= 2,
            'Escort vehicle needs room for all three members')
        for i, item in ipairs(definition.members) do
            if not valid() then return end
            local guard = self.service.guards:spawn(item.modelHash, item.name or 'Escort', Vector3.new(),
                item.weapon or 453432689, godmode, no_ragdoll, valid)
            if not guard then return end
            created[#created + 1] = guard; group.members[i] = guard
            guard.role = i == 1 and 'escort_driver' or 'escort_passenger'; guard.seat = i == 1 and -1 or i - 2
            guard.escort = group; self.service.guards:give_weapon(guard, true)
            PED.SET_PED_VEHICLE_FORCED_SEAT_USAGE(guard.handle, vehicle.handle, guard.seat, 0, 0)
            PED.SET_PED_INTO_VEHICLE(guard.handle, vehicle.handle, guard.seat)
        end
        group.name = group.name .. ' [' .. vehicle.handle .. ']'
        self.groups[#self.groups + 1] = group; return group
    end)
    if not ok or not result or not valid() then
        for i = #created, 1, -1 do self.service.guards:remove(created[i]) end
        if group.blip then self.service.blips:remove(group.blip) end
        if group.vehicle then self.service.pool:delete(group.vehicle.handle) end
        if not ok then error(result) end
        return nil
    end
    return result
end

function Escorts:driver(group)
    for _, member in ipairs(group.members) do
        if member.role == 'escort_driver' and self.service.guards:alive(member) then
            return
                member
        end
    end
    local eligible = {}
    for _, member in ipairs(group.members) do if self.service.guards:alive(member) then eligible[#eligible + 1] = member end end
    table.sort(eligible, function(a, b) return a.seat < b.seat end)
    for index, member in ipairs(eligible) do
        local seat = ({ -1, 0, 1 })[index]
        member.role = index == 1 and 'escort_driver' or 'escort_passenger'; member.seat = seat
        if self.service.pool:exists(group.vehicle) then
            PED.CLEAR_ALL_PED_VEHICLE_FORCED_SEAT_USAGE(member.handle)
            PED.SET_PED_VEHICLE_FORCED_SEAT_USAGE(member.handle, group.vehicle.handle, seat, 0, 0)
            if not PED.IS_PED_IN_COMBAT(member.handle, 0) then
                TASK.TASK_WARP_PED_INTO_VEHICLE(member.handle,
                    group.vehicle.handle, seat)
            end
        end
    end
    return eligible[1]
end

function Escorts:board(group, warp)
    if not self.service.pool:exists(group.vehicle) then return end
    for _, member in ipairs(group.members) do
        if self.service.guards:alive(member) and not PED.IS_PED_IN_VEHICLE(member.handle, group.vehicle.handle, false) then
            if warp then
                TASK.TASK_WARP_PED_INTO_VEHICLE(member.handle, group.vehicle.handle, member.seat)
            else
                self.service.guards:queue(member, 'enter_vehicle',
                    function(valid) self.service.guards:enter(member, group.vehicle.handle, member.seat, valid) end, true)
            end
        end
    end
end

function Escorts:cancel(group)
    group.task = 'idle'; group.destination = nil
    local driver = self:driver(group)
    if driver then
        self.service.guards:clear_task(driver)
        TASK.CLEAR_PRIMARY_VEHICLE_TASK(group.vehicle.handle)
        TASK.TASK_VEHICLE_TEMP_ACTION(driver.handle, group.vehicle.handle, 1, 2000)
    end
end

function Escorts:drive(group, position, wander)
    local driver = self:driver(group); assert(driver and self.service.pool:exists(group.vehicle),
        'Escort driver or vehicle is unavailable')
    self:cancel(group); self:board(group, true)
    self.service.guards:speak(driver, 'GENERIC_YES')
    self.service.guards:override(driver, nil, -1, wander and 'Cuising around' or 'Driving to coordinates')
    local flags, speed = group.mode == 0 and 786603 or 527164, group.mode == 0 and 19 or 60
    if wander then
        TASK.TASK_VEHICLE_DRIVE_WANDER(driver.handle, group.vehicle.handle, speed, flags); group.task = 'wander'
    else
        TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(driver.handle, group.vehicle.handle, position.x, position.y,
            position.z, speed, flags, 30)
        group.destination = position; group.task = 'goto'
    end
end

function Escorts:park(group)
    local driver = self:driver(group); if not driver then return end
    self:cancel(group); self:board(group, true)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(group.vehicle.handle, 2, 10, 0)
    TASK.TASK_VEHICLE_PARK(driver.handle, group.vehicle.handle, pos.x, pos.y, pos.z,
        ENTITY.GET_ENTITY_HEADING(group.vehicle.handle), 0, 100, true)
    group.task = 'idle'
end

function Escorts:bring(group)
    if not self.service.pool:exists(group.vehicle) then return end
    if not self.ctx.game.outside(PLAYER.PLAYER_PED_ID()) then
        self.ctx.notifier:error('Billionaire Services', self.ctx.translator:text('BSV2_ES_BRING_INTERIOR_ERR')); return
    end
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), math.random(-2, 2),
        math.random(-12, -8), 0.1)
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(group.vehicle.handle, pos.x, pos.y, pos.z, false, false, false)
    ENTITY.SET_ENTITY_HEADING(group.vehicle.handle, ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID()))
    VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(group.vehicle.handle, 5)
    self:board(group, true); group.task = 'idle'
end

function Escorts:bring_player(group)
    local state = self.ctx.state:read()
    if not state or not state.on_foot or not self.ctx.game.outside(state.handle) then
        self.ctx.notifier:error('Billionaire Services', self.ctx.translator:text('BSV2_ES_TP_ERR')); return
    end
    if not self.service.pool:exists(group.vehicle) then
        self.ctx.notifier:error('Billionaire Services', self.ctx.translator:text('BSV2_ES_VEH_INVALID_ERR')); return
    end
    local minimum, maximum = self.ctx.game.model_dimensions(group.vehicle.model)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(group.vehicle.handle, 0, 0, maximum.z - minimum.z + 0.1)
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(state.handle, pos.x, pos.y, pos.z, false, false, false)
end

function Escorts:recover(group, valid)
    local driver = self:driver(group); if not driver then
        self:remove(group); return
    end
    local position = ENTITY.GET_ENTITY_COORDS(driver.handle, false)
    if ENTITY.IS_ENTITY_IN_WATER(driver.handle) then position = self.ctx.game.closest_road(position, 0) or position end
    local model = group.vehicle.model
    self.service.blips:remove(group.blip); self.service.pool:delete(group.vehicle.handle)
    if self:vehicle(group, model, position, group.godmode, valid) then
        for _, member in ipairs(group.members) do
            if self.service.guards:alive(member) then
                PED.CLEAR_ALL_PED_VEHICLE_FORCED_SEAT_USAGE(member.handle)
                PED.SET_PED_VEHICLE_FORCED_SEAT_USAGE(member.handle, group.vehicle.handle, member.seat, 0, 0)
            end
        end
        self:board(group, true)
    end
end

function Escorts:serialize(group)
    local result = { name = group.name:gsub(' %[%d+%]$', ''), vehicleModel = group.vehicle.model, members = {} }
    for _, member in ipairs(group.members) do
        result.members[#result.members + 1] = {
            modelHash = member.model,
            name =
                member.name,
            weapon = member.weapon
        }
    end
    return result
end

function Escorts:remove(group)
    group.removed = true
    for _, member in ipairs(group.members) do
        if self.service.guards.members[member.handle] then
            PED.CLEAR_ALL_PED_VEHICLE_FORCED_SEAT_USAGE(member.handle); self.service.guards:remove(member)
        end
    end
    self.service.blips:remove(group.blip); self.service.pool:delete(group.vehicle.handle)
    for i = #self.groups, 1, -1 do if self.groups[i] == group then table.remove(self.groups, i) end end
end

function Escorts:dismiss(group)
    if group.dismissed then return end
    group.dismissed = true; self:cancel(group); self:board(group, true)
    self.service:run('escort_dismiss', function(valid)
        local driver = self:driver(group); if not driver then
            self:remove(group); return
        end
        local handle = group.vehicle.handle
        if PED.IS_PED_IN_VEHICLE(PLAYER.PLAYER_PED_ID(), handle, false) then
            TASK.TASK_VEHICLE_TEMP_ACTION(driver.handle, handle, 1, -1)
            while valid() and not VEHICLE.IS_VEHICLE_STOPPED(handle) and PED.IS_PED_IN_VEHICLE(PLAYER.PLAYER_PED_ID(), handle, false) do
                script.yield(0)
            end
            if not valid() then return end
            TASK.TASK_LEAVE_VEHICLE(PLAYER.PLAYER_PED_ID(), handle, 0)
            while valid() and PED.IS_PED_IN_VEHICLE(PLAYER.PLAYER_PED_ID(), handle, false) do script.yield(100) end
            script.yield(2000); if not valid() then return end
        end
        driver.task = 'dismissed'; self.service.guards:speak(driver, 'GENERIC_BYE', 'SPEECH_PARAMS_FORCE_SHOUTED')
        TASK.TASK_VEHICLE_DRIVE_WANDER(driver.handle, handle, 20, 803243); group.task = 'going_home'
        script.yield(9000); if not valid() or group.removed then return end
        if network.is_session_started() then
            NETWORK.NETWORK_FADE_OUT_ENTITY(handle, true, true)
            for _, member in ipairs(group.members) do NETWORK.NETWORK_FADE_OUT_ENTITY(member.handle, true, true) end
        end
        script.yield(1000); if valid() and not group.removed then self:remove(group) end
    end)
end

function Escorts:update(group, state, now)
    if group.removed or now < group.next_update then return end
    group.next_update = now + 1000
    for index = #group.members, 1, -1 do
        local member = group.members[index]
        if not self.service.guards:alive(member) then
            if self.service.guards.members[member.handle] then self.service.guards:remove(member) end
            table.remove(group.members, index)
        end
    end
    local driver = self:driver(group); if not driver then
        self:remove(group); return
    end
    if not self.service.pool:exists(group.vehicle) then
        if not group.recovering then
            group.recovering = true; self.service:run('escort_recover', function(valid)
                local ok, err = pcall(function() if not group.removed then self:recover(group, valid) end end)
                group.recovering = false; if not ok then error(err) end
            end)
        end
        return
    end
    local handle = group.vehicle.handle
    group.in_vehicle = state.vehicle_handle == handle
    group.vehicle_name = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(group
        .vehicle.model))
    self.service.blips:visible(group.blip, state.vehicle_handle ~= handle)
    if not VEHICLE.IS_VEHICLE_DRIVEABLE(handle, false) or VEHICLE.IS_VEHICLE_STUCK_ON_ROOF(handle) then
        self.service.vehicles:repair(group, true)
        if VEHICLE.IS_VEHICLE_STUCK_ON_ROOF(handle) then self:bring(group) end
    end
    if group.dismissed then return end
    local position = ENTITY.GET_ENTITY_COORDS(handle, false)
    if Geometry.distance(position, state.ped:get_position()) > 200 and self.ctx.game.outside(state.handle) then
        if state.aircraft or ENTITY.IS_ENTITY_IN_WATER(state.handle) then
            self:dismiss(group); return
        end
        self:bring(group)
        if state.vehicle then
            VEHICLE.SET_VEHICLE_FORWARD_SPEED(handle,
                math.max(0, ENTITY.GET_ENTITY_SPEED(state.vehicle_handle) - 5))
        end
    end
    if group.task == 'goto' and group.destination then
        if not group.in_vehicle or Geometry.distance(position, group.destination) <= math.max(40, ENTITY.GET_ENTITY_SPEED(handle) * 2) then
            if group.in_vehicle then
                self.ctx.notifier:info("Samurai's Scripts",
                    '[Private Escort]: You have reached your destination.')
            end
            self:cancel(group); TASK.TASK_VEHICLE_TEMP_ACTION(driver.handle, handle, 1, -1); return
        end
    end
    if group.task == 'goto' or group.task == 'wander' or group.task == 'parking' then return end
    if state.land_vehicle and state.vehicle_handle ~= handle then
        self:board(group, false)
        TASK.TASK_VEHICLE_ESCORT(driver.handle, handle, state.vehicle_handle, -1, 60, 24904187, 5, 5, 5); group.task =
        'escort'
    elseif state.on_foot and group.task == 'escort' then
        self:cancel(group); TASK.TASK_VEHICLE_TEMP_ACTION(driver.handle, handle, 1, -1)
    elseif state.vehicle_handle == handle then
        self:board(group, false)
    end
end

function Escorts:clear()
    for i = #self.groups, 1, -1 do self:remove(self.groups[i]) end; self.groups = {}
end

return Escorts
