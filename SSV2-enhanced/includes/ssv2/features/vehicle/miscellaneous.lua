local Geometry = require('includes.ssv2.core.geometry')
local stations = { { station = 'OFF', name = 'Off' } }
for _, station in ipairs(require('includes.ssv2.data.radio_stations')) do
    if not station.station:match('^HIDDEN') and station.station ~= 'RADIO_30_DLC_HEI4_MIX1_REVERB' then
        stations[#stations + 1] =
            station
    end
end
return function(ctx)
    local f = { id = 'vehicle_misc', category = 'vehicle', scope = 'player', controls = {} }
    local opts = {
        fast_vehicles = 'VEH_FAST_AF',
        subwoofer = 'VEH_SUBWOOFER',
        unbreakable_windows = 'VEH_STRONG_WINDOWS',
        auto_brake_lights = 'VEH_AUTO_BRAKE_LIGHTS',
        auto_lock_doors = 'VEH_AUTO_LOCK'
    }
    local function cfg(key) return ctx.settings:get('features.vehicle.' .. key) end
    for key, label in pairs(opts) do
        f.controls[#f.controls + 1] = {
            kind = 'toggle',
            path = 'features.vehicle.' .. key,
            label =
                label
        }
    end
    f.controls[#f.controls + 1] = { kind = 'float', path = 'features.vehicle.fast_vehicles_speed', label = '##speed', min = 10, max = 100 }
    f.controls[#f.controls + 1] = {
        kind = 'toggle',
        path = 'features.vehicle.default_station.enabled',
        label =
        'VEH_DEFAULT_RADIO'
    }
    function f:enabled()
        for key in pairs(opts) do if cfg(key) then return true end end
        return cfg('default_station.enabled')
    end

    function f:disable()
        for key in pairs(opts) do ctx.settings:set('features.vehicle.' .. key, false) end
        ctx.settings:set('features.vehicle.default_station.enabled', false)
    end

    function f:ready(state) return state.alive end

    function f:restore()
        if self.vehicle and ENTITY.DOES_ENTITY_EXIST(self.vehicle) then
            ctx.game.clear_lock_feedback(ctx, self.vehicle)
            if self.fast then VEHICLE.MODIFY_VEHICLE_TOP_SPEED(self.vehicle, -1) end
            if self.loud then AUDIO.SET_VEHICLE_RADIO_LOUD(self.vehicle, false) end
            if self.glass then VEHICLE.SET_DONT_PROCESS_VEHICLE_GLASS(self.vehicle, false) end
            if self.locked then VEHICLE.SET_VEHICLE_DOORS_LOCKED(self.vehicle, self.original_lock) end
            if self.brake then VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(self.vehicle, false) end
        end
        self.vehicle, self.fast, self.loud, self.glass, self.locked, self.brake, self.station = nil, false, false, false,
            false, false, nil
    end

    function f:cleanup() self:restore() end

    function f:update(state)
        local current = state.vehicle_handle
        if state.native_vehicle_handle ~= nil and current == 0 then
            self:restore(); return
        end
        if current ~= 0 and current ~= self.vehicle then
            self:restore(); self.vehicle = current; self.original_lock = VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(current)
        end
        current = state.native_vehicle_handle or current
        local handle = self.vehicle
        if not handle or not ENTITY.DOES_ENTITY_EXIST(handle) then
            self:restore(); return
        end
        if cfg('fast_vehicles') then
            VEHICLE.MODIFY_VEHICLE_TOP_SPEED(handle, cfg('fast_vehicles_speed')); self.fast = true
        elseif self.fast then
            VEHICLE.MODIFY_VEHICLE_TOP_SPEED(handle, -1); self.fast = false
        end
        local loud, glass = cfg('subwoofer'), cfg('unbreakable_windows')
        if loud ~= self.loud then
            AUDIO.SET_VEHICLE_RADIO_LOUD(handle, loud); self.loud = loud
        end
        if glass ~= self.glass then
            VEHICLE.SET_DONT_PROCESS_VEHICLE_GLASS(handle, glass); self.glass = glass
        end
        local brake = cfg('auto_brake_lights') and state.driving and state.vehicle_handle == handle
            and VEHICLE.IS_VEHICLE_DRIVEABLE(handle, false) and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(handle)
            and ENTITY.GET_ENTITY_SPEED(handle) <= 0.1 and not PAD.IS_CONTROL_PRESSED(0, 72)
        if brake then
            VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(handle, true); self.brake = true
        elseif self.brake then
            VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(handle, false); self.brake = false
        end
        local attempting = PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(state.handle) == handle
        local generation, pointer = ctx.runtime.generation, memory.handle_to_ptr(handle):get_address()
        local function valid_lock()
            return ctx.runtime.running and ctx.runtime.generation == generation and self.vehicle == handle
                and ENTITY.DOES_ENTITY_EXIST(handle) and memory.handle_to_ptr(handle):get_address() == pointer
        end
        if self.locked and (not cfg('auto_lock_doors') or attempting or current == handle) then
            self.locked = false
            if not ctx.game.lock_vehicle(ctx, handle, self.original_lock > 1, valid_lock) then return end
        elseif cfg('auto_lock_doors') and current ~= handle and not attempting and not self.locked
            and ctx.game.outside(state.handle) and Geometry.distance(ENTITY.GET_ENTITY_COORDS(handle, true), state.ped:get_position()) > 18 then
            self.original_lock = VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(handle)
            self.locked = true
            if not ctx.game.lock_vehicle(ctx, handle, true, valid_lock) then
                self.locked = false; return
            end
        end
        if current == handle and cfg('default_station.enabled') then
            local station = cfg('default_station.station_name')
            if self.station ~= station then
                AUDIO.SET_VEH_RADIO_STATION(handle, station); self.station = station
            end
        else
            self.station = nil
        end
    end

    function f:set_radio(station)
        local state = ctx.state:read()
        if state and state.vehicle and state.driving and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(state.vehicle_handle) then
            AUDIO.SET_VEH_RADIO_STATION(state.vehicle_handle, station); self.station = station
        end
    end

    function f:draw()
        ImGui.Spacing()
        if ImGui.Button('Online Favorite') then
            ctx.runtime:run('favorite_radio', function()
                local index = stats.get_int('MPPLY_MOST_FAVORITE_STATION')
                local station = index >= 0 and index < AUDIO.GET_NUM_UNLOCKED_RADIO_STATIONS() and
                    AUDIO.GET_RADIO_STATION_NAME(index) or 'OFF'
                ctx.settings:set('features.vehicle.default_station.station_name', station)
                ctx.settings:set('features.vehicle.default_station.display_name',
                    station == 'OFF' and 'Off' or HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(station))
                self:set_radio(station)
            end)
        end
        if ImGui.BeginCombo('##defaultRadio', cfg('default_station.display_name')) then
            for _, station in ipairs(stations) do
                ImGui.Selectable(station.name, cfg('default_station.station_name') == station.station)
                if ImGui.IsItemClicked(0) then
                    ctx.settings:set('features.vehicle.default_station.station_name', station.station)
                    ctx.settings:set('features.vehicle.default_station.display_name', station.name)
                    local name = station.station; ctx.runtime:run('set vehicle radio',
                        function() self:set_radio(name) end)
                end
            end
            ImGui.EndCombo()
        end
    end

    return f
end
