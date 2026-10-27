local Feature = require('includes.ssv2.core.feature')
local Geometry = require('includes.ssv2.core.geometry')
local radios = require('includes.ssv2.data.radio_stations')
local Widgets = require('includes.ssv2.core.widgets')
local driving = { { speed = 20, flags = 786603 }, { speed = 60, flags = 2886204 } }
local flags = { 134, 229, 251, 255 }
return function(ctx)
    local f = Feature.new(ctx, {
        id = 'carpool',
        category = 'world',
        path = 'features.world.carpool',
        vehicle = 0,
        driver = 0,
        prepared = {},
        mode = 1,
        task = -1,
        next_scan = 0,
        snapshot = {},
        controls = { { kind = 'toggle', path = 'features.world.carpool', label = 'WRLD_CARPOOL', tooltip = 'WRLD_CARPOOL_TT' } }
    })
    function f:ready(state) return state.alive and ctx.game.outside(state.handle) end

    function f:eligible(ped, group)
        return ped ~= 0 and ENTITY.DOES_ENTITY_EXIST(ped) and not PED.IS_PED_A_PLAYER(ped)
            and not PED.IS_PED_GROUP_MEMBER(ped, group) and not ctx.owned_entities[ped]
    end

    function f:release()
        for ped, saved in pairs(self.prepared) do
            if ENTITY.DOES_ENTITY_EXIST(ped) then
                local entity = Entity.new(ped)
                if not entity:has_control() then entity:force_control() end
                if entity:has_control() then
                    for _, id in ipairs(flags) do PED.SET_PED_CONFIG_FLAG(ped, id, saved[id]) end
                    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, saved.blocked)
                else
                    log.warn('Samurai Carpool: could not restore NPC ' .. ped)
                end
            end
        end
        self.prepared = {}
    end

    function f:cleanup()
        if self.riding and self:driver_valid() then
            TASK.TASK_VEHICLE_TEMP_ACTION(self.driver, self.vehicle, 1, 2000)
        end
        self:release()
        self.vehicle, self.driver, self.riding, self.task, self.destination = 0, 0, false, -1, nil
        self.snapshot = {}
    end

    function f:prepare(state, vehicle)
        local generation, group = ctx.runtime.generation, PED.GET_PED_GROUP_INDEX(state.handle)
        local count = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(vehicle))
        for seat = -1, count - 2 do
            local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, seat, false)
            if self:eligible(ped, group) and not self.prepared[ped] then
                local entity = Entity.new(ped)
                if not entity:has_control() then entity:request_control(200) end
                if not ctx.runtime.running or generation ~= ctx.runtime.generation or self.vehicle ~= vehicle then return end
                if ENTITY.DOES_ENTITY_EXIST(ped) and entity:has_control() and self:eligible(ped, group)
                    and PED.GET_VEHICLE_PED_IS_IN(ped, false) == vehicle then
                    local saved = { blocked = PED.GET_PED_CONFIG_FLAG(ped, 17, true) }
                    for _, id in ipairs(flags) do saved[id] = PED.GET_PED_CONFIG_FLAG(ped, id, true) end
                    self.prepared[ped] = saved
                    TASK.CLEAR_PED_TASKS(ped)
                    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                    for _, id in ipairs(flags) do PED.SET_PED_CONFIG_FLAG(ped, id, true) end
                end
            end
        end
    end

    function f:driver_valid()
        return self.vehicle ~= 0 and ENTITY.DOES_ENTITY_EXIST(self.vehicle) and self.driver ~= 0
            and ENTITY.DOES_ENTITY_EXIST(self.driver) and not PED.IS_PED_A_PLAYER(self.driver)
            and VEHICLE.GET_PED_IN_VEHICLE_SEAT(self.vehicle, -1, false) == self.driver
    end

    function f:command_valid()
        local state = ctx.state:read()
        return self.active and self:enabled() and ctx.runtime.running and self:driver_valid()
            and state and state.vehicle_handle == self.vehicle and not state.driving
    end

    function f:cancel_tasks()
        TASK.CLEAR_PED_TASKS(self.driver); TASK.CLEAR_PED_SECONDARY_TASK(self.driver)
        TASK.CLEAR_PRIMARY_VEHICLE_TASK(self.vehicle)
        TASK.TASK_VEHICLE_TEMP_ACTION(self.driver, self.vehicle, 1, 2000)
    end

    function f:go_to(destination)
        if not self:command_valid() then return end
        self:cancel_tasks()
        local mode = driving[self.mode]
        local model = ENTITY.GET_ENTITY_MODEL(self.vehicle)
        if VEHICLE.IS_THIS_MODEL_A_PLANE(model) then
            TASK.TASK_PLANE_MISSION(self.driver, self.vehicle, 0, 0, destination.x, destination.y, destination.z + 800,
                4, 100, 0, 90, 5000, 200, true)
        elseif VEHICLE.IS_THIS_MODEL_A_HELI(model) then
            TASK.TASK_HELI_MISSION(self.driver, self.vehicle, 0, 0, destination.x, destination.y, destination.z,
                4, VEHICLE.GET_VEHICLE_ESTIMATED_MAX_SPEED(self.vehicle), 4, -1, -1, 100, 100, 0)
        elseif VEHICLE.IS_THIS_MODEL_A_BOAT(model) then
            return
        else
            TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(self.driver, self.vehicle,
                destination.x, destination.y, destination.z, mode.speed, mode.flags, 25)
        end
        self.destination, self.task = destination, 0
    end

    function f:wander()
        if not self:command_valid() then return end
        local model = ENTITY.GET_ENTITY_MODEL(self.vehicle)
        if VEHICLE.IS_THIS_MODEL_A_PLANE(model) or VEHICLE.IS_THIS_MODEL_A_HELI(model)
            or VEHICLE.IS_THIS_MODEL_A_BOAT(model) then
            return
        end
        self:cancel_tasks()
        local mode = driving[self.mode]
        TASK.TASK_VEHICLE_DRIVE_WANDER(self.driver, self.vehicle, mode.speed, mode.flags)
        self.destination, self.task = nil, 1
    end

    function f:stop()
        if not self:command_valid() then return end
        self:cancel_tasks(); self.task = 99
    end

    function f:resume()
        if not self:command_valid() then return end
        if self.destination then self:go_to(self.destination) else self:wander() end
    end

    function f:shuffle(step)
        if not self:command_valid() then return end
        local state = ctx.state:read()
        local seats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(self.vehicle)) - 1
        if seats < 2 then return end
        local current = 0
        for seat = 0, seats - 1 do
            if VEHICLE.GET_PED_IN_VEHICLE_SEAT(self.vehicle, seat, false) == state.handle then
                current = seat; break
            end
        end
        for offset = 1, seats do
            local seat = (current + step * offset) % seats
            if VEHICLE.IS_VEHICLE_SEAT_FREE(self.vehicle, seat, false) then
                PED.SET_PED_INTO_VEHICLE(state.handle, self.vehicle, seat); return
            end
        end
    end

    function f:update(state)
        local now = ctx.clock:elapsed_ms()
        if self.vehicle ~= 0 and (not ENTITY.DOES_ENTITY_EXIST(self.vehicle)
                or Geometry.distance(state.ped:get_position(), ENTITY.GET_ENTITY_COORDS(self.vehicle, false)) >= 20
                or (self.riding and (state.vehicle_handle ~= self.vehicle or state.driving or not self:driver_valid()))) then
            self:cleanup()
        end
        if self.vehicle == 0 then
            if state.driving or now < self.next_scan then return end
            self.next_scan = now + 1000
            local vehicle = ctx.game.closest_vehicle(state.ped:get_position(), 15, state.vehicle_handle, true, 3)
            if vehicle == 0 or ctx.owned_entities[vehicle] or not VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(vehicle) then return end
            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1, false)
            if not self:eligible(driver, PED.GET_PED_GROUP_INDEX(state.handle)) then return end
            self.vehicle, self.driver = vehicle, driver
            self:prepare(state, vehicle)
        end
        if self.vehicle == 0 or not ENTITY.DOES_ENTITY_EXIST(self.vehicle) then return end
        self.riding = state.vehicle_handle == self.vehicle and not state.driving
        if not self.riding then return end
        self.driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(self.vehicle, -1, false)
        if not self:driver_valid() then
            self:cleanup(); return
        end
        self.snapshot = {
            speed = ENTITY.GET_ENTITY_SPEED(self.vehicle),
            max_seats = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(self.vehicle),
            radio_on = AUDIO.IS_VEHICLE_RADIO_ON(self.vehicle),
            station = AUDIO.GET_PLAYER_RADIO_STATION_NAME(),
            convertible = VEHICLE.IS_VEHICLE_A_CONVERTIBLE(self.vehicle, false),
            roof = VEHICLE.GET_CONVERTIBLE_ROOF_STATE(self.vehicle)
        }
        if PAD.IS_CONTROL_PRESSED(0, 75) then self:stop() end
        if self.task == 99 then TASK.TASK_VEHICLE_TEMP_ACTION(self.driver, self.vehicle, 1, 1) end
    end

    function f:draw()
        if not self.riding then return end
        local tr = ctx.translator
        ImGui.SetWindowFontScale(1.1); ImGui.Text(tr:text('WRLD_CARPOOL') .. ' ' .. tr:text('GENERIC_OPTIONS_LABEL')); ImGui
            .SetWindowFontScale(1); ImGui.Separator()
        ImGui.Spacing(); ImGui.SeparatorText(tr:text('GENERIC_DRIVING_COMMANDS')); ImGui.BulletText(tr:text(
            'GENERIC_DRIVING_STYLE')); ImGui.SameLine()
        local mode, changed = ImGui.RadioButton(tr:text('GENERIC_DRIVING_STYLE_NORMAL'), self.mode, 1)
        ImGui.SameLine(); local next_mode, second_changed = ImGui.RadioButton(tr:text('GENERIC_DRIVING_STYLE_AGGRO'),
            mode, 2)
        if changed or second_changed then
            self.mode = next_mode
            ctx.runtime:run('carpool driving mode', function()
                if self.destination then self:go_to(self.destination) else self:wander() end
            end)
        end
        local function button(label, callback)
            if Widgets.button(ctx, tr:text(label)) then ctx.runtime:run('carpool ' .. label, callback) end
        end
        button(self.task == 99 and 'GENERIC_RESUME' or 'GENERIC_STOP', function()
            if self.task == 99 then self:resume() else self:stop() end
        end)
        ImGui.SameLine(); button('GENERIC_WANDER', function() self:wander() end)
        button('BSV2_ES_DRIVE_WP', function()
            local pos = ctx.game.waypoint()
            if pos then self:go_to(pos) else ctx.notifier:error('Carpool', 'Please set a waypoint on the map first!') end
        end)
        ImGui.SameLine(); button('BSV2_ES_DRIVE_OBJ', function()
            local pos = ctx.game.objective()
            if pos then self:go_to(pos) else ctx.notifier:error('Carpool', 'No objective found!') end
        end)
        if (self.snapshot.max_seats or 0) > 1 then
            ImGui.Spacing(); ImGui.SeparatorText(tr:text('BSV2_SEAT_CTRL')); ImGui.Spacing()
            button('< ' .. tr:text('VEH_SEAT_PREV'), function() self:shuffle(-1) end)
            ImGui.SameLine(); button(tr:text('VEH_SEAT_NEXT') .. ' >', function() self:shuffle(1) end)
        end
        if not self.driver or self.driver == 0 then return end
        ImGui.Spacing(); ImGui.SeparatorText(tr:text('BSV2_RADIO_CTRL'))
        button(self.snapshot.radio_on and 'GENERIC_TURN_OFF' or 'GENERIC_TURN_ON', function()
            if not self:command_valid() then return end
            AUDIO.SET_VEH_RADIO_STATION(self.vehicle,
                self.snapshot.radio_on and 'OFF' or radios[math.random(#radios)].station)
        end)
        ImGui.SameLine()
        self.radio_index = self.radio_index or 1
        if ImGui.BeginCombo('####carpoolradio', radios[self.radio_index].name) then
            for index, radio in ipairs(radios) do
                ImGui.Selectable(radio.name, self.radio_index == index)
                if ImGui.IsItemClicked(0) then
                    self.radio_index = index; ctx.view:play_sound('Click')
                    ctx.runtime:run('carpool radio',
                        function() if self:command_valid() then AUDIO.SET_VEH_RADIO_STATION(self.vehicle, radio.station) end end)
                end
            end
            ImGui.EndCombo()
        end
        ImGui.SetWindowFontScale(0.8); ImGui.BulletText('Now Playing: ' .. (self.snapshot.station or 'Unknown station.')); ImGui
            .SetWindowFontScale(1)
        if self.snapshot.convertible then
            ImGui.Spacing(); ImGui.SeparatorText('Convertible Roof:'); ImGui.Spacing()
            local roof = self.snapshot.roof
            ImGui.BeginDisabled(roof == 1 or roof == 3)
            if Widgets.button(ctx, ({ [0] = 'Lower', [1] = 'Lowering', [2] = 'Raise', [3] = 'Raising' })[roof] or '') then
                ctx.runtime:run('carpool roof', function()
                    if not self:command_valid() then return end
                    if ENTITY.GET_ENTITY_SPEED(self.vehicle) > 6.66 then
                        ctx.notifier:error('Carpool', 'You can not operate the convertible roof at this speed.'); return
                    end
                    local current = VEHICLE.GET_CONVERTIBLE_ROOF_STATE(self.vehicle)
                    if current == 0 then
                        VEHICLE.LOWER_CONVERTIBLE_ROOF(self.vehicle, false)
                    elseif current == 2 then
                        VEHICLE.RAISE_CONVERTIBLE_ROOF(self.vehicle, false)
                    end
                end)
            end
            ImGui.EndDisabled()
        end
    end

    return f
end
