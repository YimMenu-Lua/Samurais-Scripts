local Feature = require('includes.ssv2.core.feature')
local Memory = require('includes.ssv2.core.vehicle_memory')
local Widgets = require('includes.ssv2.core.widgets')
local function pressed(code) return PAD.IS_CONTROL_PRESSED(0, code) or PAD.IS_DISABLED_CONTROL_PRESSED(0, code) end
return function(ctx)
    local root = 'features.vehicle.manual_gearbox'
    local f = Feature.new(ctx, {
        id = 'manual_gearbox',
        category = 'vehicle',
        scope = 'vehicle',
        path = root .. '.enabled',
        controls = {
            { kind = 'toggle', path = root .. '.enabled',          label = 'VEH_MANUAL_GEARBOX' },
            { kind = 'combo',  path = root .. '.mode',             label = 'VEH_MANUAL_GEARBOX_TYPE',   options = { 'VEH_GEARBOX_MAN_WCLUTCH', 'VEH_GEARBOX_SEQUENTIAL', 'VEH_GEARBOX_AUTO' } },
            { kind = 'toggle', path = root .. '.disable_stalling', label = 'VEH_GEARBOX_CLUTCH_ASSIST', tooltip = 'VEH_GEARBOX_CLUTCH_ASSIST_TT' },
        }
    })
    ctx.input:bind_held('clutch')
    for _, id in ipairs({ 'shift_up', 'shift_down', 'engine_start_stop' }) do
        local key = id
        ctx.input:bind(key, function() if f.active then f.inputs[key] = true end end)
    end
    function f:ready(state)
        return state.alive and state.driving and state.land_vehicle and
            VEHICLE.IS_VEHICLE_DRIVEABLE(state.vehicle_handle, false)
    end

    function f:valid()
        return self.identity and ENTITY.DOES_ENTITY_EXIST(self.identity) and
            Memory.identity(self.identity) == self.base
    end

    function f:set_gear(gear)
        Memory.set_current_gear(self.identity, gear); Memory.set_previous_gear(self.identity, gear)
    end

    function f:neutral() return not self.reverse and self.selected <= 0 or self.force_neutral end

    function f:configure(state)
        ctx.vehicle_flags:release(self)
        self.mode = ctx.settings:get(root .. '.mode')
        self.single = Memory.model_flag(self.identity, 43) or Memory.get_byte(self.identity, 'top_gear') == 1
        self.inputs = {}; self.selected = 0; self.reverse = false; self.clutch = false; self.force_neutral = false
        self.kick_until = nil; self.start_until = nil; self.drive_state = -1
        if self.single then return end
        if ENTITY.GET_ENTITY_SPEED(self.identity) <= 0.1 then self:set_gear(0) end
        self.selected = Memory.get_current_gear(self.identity)
        VEHICLE.SET_VEHICLE_ENGINE_ON(self.identity, VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(self.identity), true,
            not ctx.settings:get(root .. '.disable_stalling'))
        if self.mode ~= 2 then
            for index, value in pairs({ [10] = true, [11] = false, [9] = false, [12] = false }) do
                ctx.vehicle_flags:set(self, self.identity, 'advanced', index, value)
            end
            ctx.vehicle_flags:set(self, self.identity, 'handling', 9, true)
        end
    end

    function f:enter(state)
        self.base = Memory.identity(self.identity); self.original_clutch = Memory.get_float(self.identity, 'clutch')
        self:configure(state)
    end

    function f:cleanup()
        ctx.vehicle_flags:release(self)
        if self:valid() then
            if self.start_until then VEHICLE.SET_VEHICLE_HANDBRAKE(self.identity, false) end
            if self.kick_until then VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(self.identity, 1) end
            if self.clutch_owned then Memory.set_float(self.identity, 'clutch', self.original_clutch) end
            if Memory.get_current_gear(self.identity) > 10 then self:set_gear(0) end
            if not self.single then
                VEHICLE.SET_VEHICLE_ENGINE_ON(self.identity,
                    VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(self.identity), true, false)
            end
            if self.reverse then VEHICLE.SET_VEHICLE_TAIL_LIGHTS(self.identity, false) end
            if self.burnout then VEHICLE.SET_VEHICLE_BURNOUT(self.identity, false) end
        end
        self.inputs = {}; self.kick_until = nil; self.start_until = nil; self.clutch_owned = false; self.burnout = false
    end

    function f:update(state)
        if not self:valid() then error('Vehicle memory changed while gearbox was active') end
        if self.mode ~= ctx.settings:get(root .. '.mode') then
            self:cleanup(); self:configure(state)
        end
        local handle, now = self.identity, util.time()
        local speed = ENTITY.GET_ENTITY_SPEED(handle)
        local no_clutch = self.mode ~= 0
        local engine = VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(handle)
        local held = ctx.input:is_held('clutch') and self.mode ~= 2 and not self.single
        if held and not self.clutch then
            self.clutch = true
        elseif self.clutch and not held then
            self.clutch = false
            local rpm = Memory.get_float(handle, 'rpm')
            if not self.kick_until and rpm >= 0.5 and rpm <= 1 then
                self.kick_rpm = rpm; self.kick_until = now + 400
            end
        end
        if self.inputs.engine_start_stop then
            if not engine and not self:neutral() and not (self.clutch or no_clutch) then
                ctx.notifier:error('Manual Gearbox', ctx.translator:text('VEH_GEARBOX_ENGINE_START_ERR'))
            else
                VEHICLE.SET_VEHICLE_ENGINE_ON(handle, not engine, false, true)
            end
        end
        if self.mode ~= 2 and not self.single then
            if engine then
                if not ctx.settings:get(root .. '.disable_stalling') and not no_clutch and not (state.bike and self.reverse)
                    and speed < 2 and not self:neutral() and not self.clutch and Memory.get_float(handle, 'rpm') < 0.333 then
                    VEHICLE.SET_VEHICLE_ENGINE_ON(handle, false, false, true)
                end
            elseif speed >= 3.9 and not no_clutch and not self.clutch and not self:neutral() and not self.start_until then
                self.start_until = now + 266; VEHICLE.SET_VEHICLE_HANDBRAKE(handle, true)
            end
            if self.clutch or self:neutral() then
                Memory.set_float(handle, 'clutch', 0); self.clutch_owned = true
                local accel = self.reverse and 72 or 71
                if engine then PAD.DISABLE_CONTROL_ACTION(0, accel, true) end
                if pressed(accel) then
                    if Memory.get_current_gear(handle) == 0 then self:set_gear(1) end
                    local rpm = Memory.get_float(handle, 'rpm')
                    local target = 1.05 * PAD.GET_DISABLED_CONTROL_NORMAL(0, accel)
                    local value = math.min(1, rpm + (target - rpm) * 30 * MISC.GET_FRAME_TIME())
                    Memory.set_float(handle, 'rpm', value); Memory.set_float(handle, 'throttle', value)
                    Memory.set_float(handle, 'throttle_input', value)
                end
            elseif self.clutch_owned then
                Memory.set_float(handle, 'clutch', self.original_clutch); self.clutch_owned = false
            end
            local gear = Memory.get_current_gear(handle)
            local top = Memory.get_byte(handle, 'top_gear')
            self.force_neutral = not self.clutch and speed > 0.1 and gear ~= 0 and gear ~= top
                and PAD.IS_CONTROL_PRESSED(0, 71) and speed >= Memory.gear_max_speed(handle, gear) or false
            if not self:neutral() and not self.clutch then self:set_gear(self.selected) end
            if no_clutch or self.clutch then
                if self.inputs.shift_up then
                    self.selected = self.reverse and 0 or math.min(top, self.selected + 1)
                    self.reverse = false; self.force_neutral = false
                    ctx.vehicle_flags:set(self, handle, 'handling', 9, true)
                end
                if self.inputs.shift_down then
                    if self.selected == 0 and ENTITY.GET_ENTITY_SPEED_VECTOR(handle, true).y < 3 then
                        self.reverse = true; ctx.vehicle_flags:set(self, handle, 'handling', 9, false)
                    end
                    self.selected = math.max(0, self.selected - 1); self.force_neutral = false
                end
            end
            self.drive_state = self.selected >= 1 and self.selected <= 10 and 2 or self.reverse and 1 or 0
            local brake = self.reverse and 71 or 72
            if math.abs(ENTITY.GET_ENTITY_SPEED_VECTOR(handle, true).y) < 1 then
                PAD.DISABLE_CONTROL_ACTION(0, brake, true)
                self.burnout = pressed(71) and pressed(72); VEHICLE.SET_VEHICLE_BURNOUT(handle, self.burnout)
            elseif self.burnout then
                VEHICLE.SET_VEHICLE_BURNOUT(handle, false); self.burnout = false
            end
            if PAD.IS_DISABLED_CONTROL_PRESSED(0, brake) then VEHICLE.SET_VEHICLE_BRAKE(handle, true) end
            if self.reverse then VEHICLE.SET_VEHICLE_TAIL_LIGHTS(handle, true) end
            if self.kick_until then
                if now >= self.kick_until then
                    self.kick_until = nil; VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(handle, 1)
                else
                    local fraction = 1 - (self.kick_until - now) / 400
                    VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(handle, (10 - 9 * fraction * fraction) * self.kick_rpm)
                end
            end
            if self.start_until and now >= self.start_until then
                VEHICLE.SET_VEHICLE_HANDBRAKE(handle, false); VEHICLE.SET_VEHICLE_ENGINE_ON(handle, true, true, true); self.start_until = nil
            end
        end
        self.inputs = {}
    end

    function f:draw()
        local tr = ctx.translator
        ImGui.Spacing()
        local labels = { tr:text('VEH_GEARBOX_MAN_WCLUTCH'), tr:text('VEH_GEARBOX_SEQUENTIAL'), tr:text(
            'VEH_GEARBOX_AUTO') }
        local mode, changed = ImGui.Combo(tr:text('VEH_MANUAL_GEARBOX_TYPE'), ctx.settings:get(root .. '.mode'), labels,
            #labels)
        if changed then ctx.settings:set(root .. '.mode', mode) end
        if mode == 0 then
            local assist, changed = Widgets.checkbox(ctx, tr:text('VEH_GEARBOX_CLUTCH_ASSIST'),
                ctx.settings:get(root .. '.disable_stalling'))
            if changed then
                ctx.settings:set(root .. '.disable_stalling', assist)
                ctx.runtime:run('gearbox clutch assist', function()
                    if self.active then
                        VEHICLE.SET_VEHICLE_ENGINE_ON(self.identity,
                            VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(self.identity), true, not assist)
                    end
                end)
            end
            Widgets.tooltip(ctx, tr:text('VEH_GEARBOX_CLUTCH_ASSIST_TT'))
        end
        ImGui.Spacing(); ImGui.SeparatorText(tr:text('SETTINGS_KEYBINDS'))
        ctx.view.keybinds_view = ctx.view.keybinds_view or require('includes.ssv2.core.keybinds_view').new(ctx)
        if ImGui.BeginTabBar('##gearboxKeybinds') then
            for _, source in ipairs({ 'keyboard', 'controller' }) do
                if ImGui.BeginTabItem(tr:text(source == 'keyboard' and 'SETTINGS_KEYBINDS_KEYBOARD' or 'SETTINGS_KEYBINDS_CONTROLLER')) then
                    for _, id in ipairs({ 'shift_up', 'shift_down', 'clutch', 'engine_start_stop' }) do
                        for _, binding in ipairs(ctx.input.bindings) do
                            if binding.id == id then
                                ctx.view.keybinds_view:row(binding, source, false); break
                            end
                        end
                    end
                    ImGui.EndTabItem()
                end
            end
            ImGui.EndTabBar()
        end
    end

    return f
end
