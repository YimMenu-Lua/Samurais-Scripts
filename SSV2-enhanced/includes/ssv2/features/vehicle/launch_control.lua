local Memory = require('includes.ssv2.core.vehicle_memory')
local exhaust = {}
for _, name in ipairs(require('includes.ssv2.data.plane_bones')) do
    if name:match('^exhaust') then
        exhaust[#exhaust + 1] =
            name
    end
end
return function(ctx)
    local f = {
        id = 'launch_control',
        category = 'vehicle',
        scope = 'vehicle',
        phase = 'idle',
        next_pop = 0,
        controls = {
            { kind = 'toggle', path = 'features.vehicle.launch_control',      label = 'VEH_LAUNCH_CTRL',      tooltip = 'VEH_LAUNCH_CTRL_TT' },
            { kind = 'combo',  path = 'features.vehicle.launch_control_mode', label = 'VEH_LAUNCH_CTRL',      options = { 'VEH_LAUNCH_CTRL_REALISTIC', 'VEH_LAUNCH_CTRL_RIDICULOUS' } },
            { kind = 'toggle', path = 'features.vehicle.burble_tune',         label = 'VEH_POPS_N_BANGS',     tooltip = 'VEH_POPS_N_BANGS_TT' },
            { kind = 'float',  path = 'features.vehicle.bangs_rpm_min',       label = 'Pops & Bangs RPM Min', min = 2000,                                                             max = 8000 },
            { kind = 'float',  path = 'features.vehicle.bangs_rpm_max',       label = 'Pops & Bangs RPM Max', min = 3000,                                                             max = 9000 },
            { kind = 'toggle', path = 'features.vehicle.performance_only',    label = 'VEH_PERF_ONLY',        tooltip = 'VEH_PERF_ONLY_TT' },
        }
    }
    local function cfg(key) return ctx.settings:get('features.vehicle.' .. key) end
    f.controls[4].bounds = function() return 2000, cfg('bangs_rpm_max') - 1000 end
    f.controls[5].bounds = function() return cfg('bangs_rpm_min') + 1000, 9000 end
    f.controls[4].format = '%.0f RPM'; f.controls[5].format = '%.0f RPM'
    ctx.input:bind_held('rolling_launch')
    function f:enabled() return cfg('launch_control') or cfg('burble_tune') end

    function f:disable()
        ctx.settings:set('features.vehicle.launch_control', false); ctx.settings:set('features.vehicle.burble_tune',
            false)
    end

    function f:ready(state)
        if not state.alive or not state.driving or not state.land_vehicle then return false end
        if cfg('performance_only') then
            local class = VEHICLE.GET_VEHICLE_CLASS(state.vehicle_handle)
            if not state.car or class ~= 6 and class ~= 7 then return false end
        end
        return not Memory.model_flag(state.vehicle_handle, 43)
    end

    function f:enter(state)
        self.default_speed = VEHICLE.GET_VEHICLE_MODEL_ESTIMATED_MAX_SPEED(state.vehicle:get_model())
    end

    function f:restore_charge()
        if self.identity and ENTITY.DOES_ENTITY_EXIST(self.identity) then
            if self.frozen then ENTITY.FREEZE_ENTITY_POSITION(self.identity, false) end
            if self.speed_locked then VEHICLE.SET_VEHICLE_MAX_SPEED(self.identity, -1) end
            if self.transmission_saved then
                for name, value in pairs(self.transmission_saved) do Memory.set_float(self.identity, name, value) end
            end
        end
        self.frozen, self.speed_locked, self.transmission_saved = false, nil, nil
    end

    function f:stop_launch()
        self:restore_charge()
        if self.arena then
            if self.identity and ENTITY.DOES_ENTITY_EXIST(self.identity) then
                VEHICLE._SET_VEHICLE_MAX_LAUNCH_ENGINE_REVS(self.identity, 1)
                if self.rolling then VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(self.identity, 1) end
            end
            PHYSICS.SET_IN_ARENA_MODE(false)
        end
        self.arena, self.phase, self.started, self.rolling = false, 'idle', nil, false
    end

    function f:cleanup()
        self:stop_launch()
        if self.pops_disabled and self.identity and ENTITY.DOES_ENTITY_EXIST(self.identity) then
            AUDIO
                .ENABLE_VEHICLE_EXHAUST_POPS(self.identity, true)
        end
        if self.shocking then EVENT.REMOVE_SHOCKING_EVENT(self.shocking) end
        self.pops_disabled, self.shocking, self.next_pop = false, nil, 0
    end

    function f:progress(now)
        local done = self.phase == 'ready'
        local r, g, b = done and 111 or 255, done and 194 or 255, done and 118 or 255
        HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT('STRING')
        HUD.SET_TEXT_COLOUR(r, g, b, 255); HUD.SET_TEXT_SCALE(0, 0.35); HUD.SET_TEXT_OUTLINE()
        HUD.SET_TEXT_FONT(2); HUD.SET_TEXT_CENTRE(true)
        HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(self.rolling and 'Anti Lag' or 'Launch Control')
        HUD.END_TEXT_COMMAND_DISPLAY_TEXT(0.5, 0.9105, 0)
        local fraction = done and 1 or math.min(1, math.max(0, (now - self.started) / 2000))
        GRAPHICS.DRAW_RECT(0.5, 0.9501, 0.105, 0.02, 0, 0, 0, 158, false)
        GRAPHICS.DRAW_RECT(0.45 + fraction * 0.05, 0.9501, 0.1 * fraction, 0.01, r, g, b, 255, false)
    end

    function f:pop(state, loud, scale, now)
        if now < self.next_pop then return end
        if not ctx.particles:burst(state.vehicle_handle, 'core', 'veh_backfire', exhaust, scale, Vector3.new(), Vector3.new()) then return end
        AUDIO.PLAY_SOUND_FROM_ENTITY(-1, loud and 'SNIPER_FIRE' or 'BOOT_POP', state.vehicle_handle,
            loud and 'DLC_BIKER_RESUPPLY_MEET_CONTACT_SOUNDS' or 'DLC_VW_BODY_DISPOSAL_SOUNDS', true, 0)
        self.next_pop = now + math.random(60, loud and 180 or 120)
    end

    function f:update(state)
        local now, handle = ctx.clock:elapsed_ms(), state.vehicle_handle
        local engine = VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(handle)
        local accelerator = PAD.IS_CONTROL_PRESSED(0, 71)
        local brake = PAD.IS_CONTROL_PRESSED(0, 72)
        local rolling_key = ctx.input:is_held('rolling_launch')
        local speed = ENTITY.GET_ENTITY_SPEED(handle)
        local max_speed = VEHICLE.GET_VEHICLE_ESTIMATED_MAX_SPEED(handle)
        if self.phase == 'cooldown' then
            if now < self.cooldown_until then return end
            self.phase = 'idle'
        end
        if self.phase == 'running' then
            local target = self.rolling and math.min(max_speed, self.launch_speed + 15)
                or (cfg('launch_control_mode') == 0 and (self.default_speed - 1) * 0.55 or max_speed - 1)
            if not cfg('launch_control') or not engine or not accelerator or speed >= target or ctx.input.blocked() then
                self:stop_launch()
            elseif self.rolling then
                VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(handle, 10)
            else
                local force = (cfg('launch_control_mode') == 0 and 2000 or 5000) *
                    math.min(1, (now - self.launch_started) / 1200)
                ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(handle, 1, 0, force, 0, false, true, false, false)
            end
            return
        end
        local forward = ENTITY.GET_ENTITY_SPEED_VECTOR(handle, true).y
        local rolling = state.car and forward >= 8 and forward <= max_speed
        local gearbox = ctx.features.manual_gearbox
        local manual = gearbox and gearbox.active and gearbox.mode ~= 2 and not gearbox.single
        local condition = rolling and rolling_key or not rolling and not manual and speed <= 0.1 and brake
        local charge = cfg('launch_control') and engine and accelerator and condition
            and not ctx.input:is_held('drift_mode') and not ctx.input.blocked()
        if self.phase == 'ready' then
            self:progress(now); self:pop(state, false, 0.69420, now)
            if not cfg('launch_control') or not engine or not accelerator then
                self:stop_launch()
            elseif not brake and not rolling_key then
                self.launch_speed = speed; self:restore_charge()
                PHYSICS.SET_IN_ARENA_MODE(true); self.arena = true
                VEHICLE._SET_VEHICLE_MAX_LAUNCH_ENGINE_REVS(handle, 0)
                self.phase, self.launch_started = 'running', now
            end
            return
        end
        if charge then
            if VEHICLE.GET_VEHICLE_ENGINE_HEALTH(handle) <= 400 then
                ctx.notifier:warn("Samurai's Scripts", ctx.translator:text('VEH_LAUNCH_CTRL_ERR'))
                self:stop_launch(); self.phase, self.cooldown_until = 'cooldown', now + 5000; return
            end
            if self.phase ~= 'charging' then self.started, self.rolling, self.phase = now, rolling, 'charging' end
            if self.rolling then
                self.speed_locked = self.speed_locked or speed
                if not self.transmission_saved then
                    self.transmission_saved = {}
                    for _, field in ipairs({ 'throttle', 'throttle_input', 'rpm', 'rpm_secondary' }) do
                        self.transmission_saved[field] =
                            Memory.get_float(handle, field)
                    end
                end
                VEHICLE.SET_VEHICLE_MAX_SPEED(handle, self.speed_locked)
                for name in pairs(self.transmission_saved) do Memory.set_float(handle, name, 0.45) end
            else
                ENTITY.FREEZE_ENTITY_POSITION(handle, true); self.frozen = true
            end
            self:progress(now); self:pop(state, false, 0.69420, now)
            if now - self.started >= 2000 then self.phase = 'ready' end
            return
        elseif self.phase == 'charging' then
            self:stop_launch(); self.phase, self.cooldown_until = 'cooldown', now + 2000; return
        end
        if cfg('burble_tune') and engine then
            if not self.pops_disabled then
                AUDIO.ENABLE_VEHICLE_EXHAUST_POPS(handle, false); self.pops_disabled = true
            end
            local minimum = cfg('bangs_rpm_min') / 10000
            if speed <= 0.1 then
                minimum = minimum - 0.15
            elseif Memory.handling_flag(handle, 8) then
                minimum = minimum +
                    0.2
            end
            local rpm = state.vehicle:get_rev_ratio()
            local released = PAD.IS_CONTROL_RELEASED(0, 71) or PAD.IS_DISABLED_CONTROL_RELEASED(0, 71)
            if released and rpm < 1 and rpm >= minimum and rpm <= cfg('bangs_rpm_max') / 10000 and forward >= 0 then
                self:pop(state, true, 1.4, now)
                local pos = state.vehicle:get_position()
                if not self.shocking and not EVENT.IS_SHOCKING_EVENT_IN_SPHERE(79, pos.x, pos.y, pos.z, 50) then
                    self.shocking =
                        EVENT.ADD_SHOCKING_EVENT_FOR_ENTITY(79, handle, 10)
                end
            elseif self.shocking then
                EVENT.REMOVE_SHOCKING_EVENT(self.shocking); self.shocking = nil
            end
        elseif self.pops_disabled then
            AUDIO.ENABLE_VEHICLE_EXHAUST_POPS(handle, true); self.pops_disabled = false
            if self.shocking then
                EVENT.REMOVE_SHOCKING_EVENT(self.shocking); self.shocking = nil
            end
        end
    end

    return f
end
