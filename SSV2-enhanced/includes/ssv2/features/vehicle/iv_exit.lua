local Memory = require('includes.ssv2.core.vehicle_memory')
return function(ctx)
    local f = {
        id = 'iv_exit',
        category = 'vehicle',
        controls = {
            { kind = 'toggle', path = 'features.vehicle.iv_exit',           label = 'VEH_IV_EXIT',            tooltip = 'VEH_IV_EXIT_TT' },
            { kind = 'toggle', path = 'features.vehicle.no_wheel_recenter', label = 'VEH_KEEP_WHEELS_TURNED', tooltip = 'VEH_KEEP_WHEELS_TURNED_TT' },
        }
    }
    function f:enabled()
        return ctx.settings:get('features.vehicle.iv_exit') or ctx.settings:get('features.vehicle.no_wheel_recenter')
    end

    function f:disable()
        ctx.settings:set('features.vehicle.iv_exit', false); ctx.settings:set('features.vehicle.no_wheel_recenter', false)
    end

    function f:ready(state) return state.alive and ctx.game.outside(state.handle) end

    function f:restore_flag()
        if self.flag_saved ~= nil and ENTITY.DOES_ENTITY_EXIST(self.identity) then
            PED.SET_PED_CONFIG_FLAG(self.identity, 241, self.flag_saved)
        end
        self.flag_saved = nil
    end

    function f:cleanup()
        self:restore_flag()
        self.vehicle, self.pending, self.started, self.leaving, self.sample = nil, nil, nil, false, nil
    end

    function f:capture_steering(state)
        if not state.car or not ctx.settings:get('features.vehicle.no_wheel_recenter') then return nil end
        local angle = Memory.get_float(state.vehicle_handle, 'steering')
        if math.abs(angle) < 0.01 or math.abs(angle) > 1 then return nil end
        return { vehicle = state.vehicle_handle, address = Memory.identity(state.vehicle_handle), angle = angle }
    end

    function f:leave(state, keep_engine, flags, now)
        if self.flag_saved == nil then self.flag_saved = PED.GET_PED_CONFIG_FLAG(state.handle, 241, true) end
        PED.SET_PED_CONFIG_FLAG(state.handle, 241, keep_engine)
        self.pending = self:capture_steering(state)
        if self.pending then self.pending.until_time = now + 200 end
        if not keep_engine and state.car and ctx.settings:get('features.vehicle.no_wheel_recenter') then
            VEHICLE.SET_VEHICLE_ENGINE_ON(state.vehicle_handle, false, true, false)
        end
        TASK.TASK_LEAVE_VEHICLE(state.handle, state.vehicle_handle, flags)
        self.started, self.leaving = nil, true
    end

    function f:update(state)
        local now = ctx.clock:elapsed_ms()
        if self.pending then
            local pending = self.pending
            if now > pending.until_time or not ctx.settings:get('features.vehicle.no_wheel_recenter')
                or not ENTITY.DOES_ENTITY_EXIST(pending.vehicle)
                or Memory.identity(pending.vehicle) ~= pending.address then
                self.pending = nil
            else
                Memory.set_float(pending.vehicle, 'steering', pending.angle)
            end
        end
        if not state.driving or not state.land_vehicle then
            if self.sample and not self.pending and ctx.settings:get('features.vehicle.no_wheel_recenter') then
                self.pending = self.sample; self.pending.until_time = now + 200
            end
            self.sample = nil; self:restore_flag(); self.started, self.leaving = nil, false
            return
        end
        if self.vehicle and self.vehicle ~= state.vehicle_handle then
            self:restore_flag(); self.started, self.leaving, self.sample = nil, false, nil
        end
        self.vehicle = state.vehicle_handle
        if not self.leaving then self.sample = self:capture_steering(state) end
        if not ctx.settings:get('features.vehicle.iv_exit') or ctx.input.blocked()
            or HUD.IS_MP_TEXT_CHAT_TYPING() then
            self.started = nil; return
        end
        PAD.DISABLE_CONTROL_ACTION(0, 75, true)
        if self.leaving then return end
        local pressed = PAD.IS_DISABLED_CONTROL_PRESSED(0, 75)
        if pressed then
            if ENTITY.GET_ENTITY_SPEED(state.vehicle_handle) >= 15 then
                self:leave(state, false, 4160, now); return
            end
            self.started = self.started or now
            if now - self.started >= 1000 then self:leave(state, false, 0, now) end
        elseif self.started then
            self:leave(state, true, 0, now)
        end
    end

    return f
end
