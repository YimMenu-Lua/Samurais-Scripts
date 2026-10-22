local Feature = require('includes.ssv2.core.feature')
local Assets = require('includes.ssv2.core.assets')
local model = 1353720154
return function(ctx)
    local root = 'features.flatbed'
    local f = Feature.new(ctx,
        {
            id = 'flatbed',
            category = 'vehicle',
            scope = 'player',
            path = root .. '.enabled',
            assets = Assets.new(),
            controls = {
                { kind = 'toggle', path = root .. '.enabled',              label = 'FLTBD_MAIN_CB' },
                { kind = 'toggle', path = root .. '.tow_everything',       label = 'FLTBD_TOW_ALL_CB' },
                { kind = 'toggle', path = root .. '.show_towing_position', label = 'FLTBD_SHOW_TOWPOS_CB' },
                { kind = 'toggle', path = root .. '.show_esp',             label = 'FLTBD_SHOW_TOWBOX_CB' },
            }
        })
    ctx.input:bind('flatbed_tow', function() if f.active and f.truck and f.in_truck then f:toggle() end end)
    function f:ready(state) return state.alive end

    function f:valid(truck, generation)
        local state = ctx.state:read()
        return ctx.runtime.running and ctx.runtime.generation == generation and self:enabled() and state and state.alive
            and state.vehicle_handle == truck and self.truck == truck and ENTITY.DOES_ENTITY_EXIST(truck)
    end

    function f:release(move_behind)
        if self.towed and ENTITY.DOES_ENTITY_EXIST(self.towed.handle) and ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(self.towed.handle, self.truck) then
            ENTITY.DETACH_ENTITY(self.towed.handle, true, true)
            if move_behind and ENTITY.DOES_ENTITY_EXIST(self.truck) then
                local position = ENTITY.GET_ENTITY_COORDS(self.towed.handle, false)
                local forward = ENTITY.GET_ENTITY_FORWARD_VECTOR(self.truck)
                ENTITY.SET_ENTITY_COORDS(self.towed.handle, position.x - forward.x * 10, position.y - forward.y * 10,
                    position.z, false, false, false, false)
                VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(self.towed.handle, 5)
            end
        end
        self.towed = nil; self.attach_phase = nil
    end

    function f:cleanup()
        self:release(true); self.truck = nil; self.target = nil; self.spawn_pending = false; self.assets:reset()
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model)
    end

    function f:spawn()
        local state = ctx.state:read()
        assert(state and state.on_foot and ctx.game.outside(state.handle),
            'Leave your vehicle and go outside to spawn a flatbed')
        self.spawn_pending = true
    end

    function f:attach(physical)
        if self.busy or not self.target or not self.truck then return end
        self.busy = true
        local truck, target, generation = self.truck, self.target, ctx.runtime.generation
        local ok, err = pcall(function()
            if not ctx.game.control(target.handle, 350, function() return self:valid(truck, generation) end) then return end
            if not self:valid(truck, generation) then return end
            local minimum, maximum = ctx.game.model_dimensions(target.model)
            local offset = Vector3.new((minimum.x + maximum.x) / 2, (minimum.y - maximum.y) / 2 + 1,
                (minimum.z + maximum.z) / 2 + 0.69)
            local bone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(truck, 'chassis')
            if physical then
                script.yield(100)
                if not self:valid(truck, generation) or not ENTITY.DOES_ENTITY_EXIST(target.handle) then return end
            end
            ENTITY.SET_ENTITY_HEADING(target.handle, ENTITY.GET_ENTITY_HEADING(truck))
            ENTITY.SET_ENTITY_CANT_CAUSE_COLLISION_DAMAGED_ENTITY(target.handle, truck)
            self.towed = { handle = target.handle, name = target.name, offset = offset, bone = bone }
            if physical then
                ENTITY.ATTACH_ENTITY_TO_ENTITY_PHYSICALLY(target.handle, truck, -1, bone, offset.x, offset.y, offset.z,
                    offset.x, offset.y + 2, offset.z - 1.1, 0, 0, 0, 999.9, true, false, false, false, 2)
                offset.y = offset.y + 2; offset.z = offset.z - 1.1
            else
                ENTITY.ATTACH_ENTITY_TO_ENTITY(target.handle, truck, bone, offset.x, offset.y, offset.z, 0, 0, 0, false,
                    true, true, false, 1, true, 1)
                self.attach_phase = { next = util.time() + 50, tries = 0, z = offset.z, generation = generation }
            end
        end)
        self.busy = false
        if not ok then
            self:release(); error(err)
        end
    end

    function f:detach()
        local towed, truck, generation = self.towed, self.truck, ctx.runtime.generation
        if not towed or not truck then return end
        if not ctx.game.control(towed.handle, 350, function()
                return self:valid(truck, generation) and self.towed ==
                    towed
            end) then
            return
        end
        if not self:valid(truck, generation) or self.towed ~= towed then return end
        local position = ENTITY.GET_ENTITY_COORDS(towed.handle, false)
        local truck_position = ENTITY.GET_ENTITY_COORDS(truck, false)
        local forward = ENTITY.GET_ENTITY_FORWARD_VECTOR(truck)
        self:release()
        ENTITY.SET_ENTITY_COORDS(towed.handle, position.x - forward.x * 10, position.y - forward.y * 10, truck_position
            .z, false, false, false, false)
        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(towed.handle, 5)
    end

    function f:toggle() if self.towed then self:detach() else self:attach(false) end end

    function f:move(x, y, z)
        if not self.towed or not self.truck then return end
        local multiplier = ctx.input.held[16] and 10 or 1
        local offset = self.towed.offset
        offset.x = offset.x + x * multiplier; offset.y = offset.y + y * multiplier; offset.z = offset.z + z * multiplier
        ENTITY.ATTACH_ENTITY_TO_ENTITY(self.towed.handle, self.truck, self.towed.bone, offset.x, offset.y, offset.z,
            0, 0, 0, false, false, false, false, 2, true, 1)
    end

    function f:update(state)
        if self.spawn_pending then
            if not state.on_foot or not ctx.game.outside(state.handle) then
                self.spawn_pending = false
            elseif self.assets:model(model) then
                local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(state.handle, 0, 5, 0)
                local vehicle = VEHICLE.CREATE_VEHICLE(model, pos.x, pos.y, pos.z,
                    ENTITY.GET_ENTITY_HEADING(state.handle), network.is_session_started(), false, false)
                assert(vehicle ~= 0 and ENTITY.DOES_ENTITY_EXIST(vehicle), 'Flatbed spawn failed')
                PED.SET_PED_INTO_VEHICLE(state.handle, vehicle, -1)
                local ptr = memory.allocate(4); ptr:set_int(vehicle)
                local ok, err = pcall(function() ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(ptr) end)
                memory.free(ptr); if not ok then error(err) end
                STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model); self.spawn_pending = false
            end
        end
        self.in_truck = state.vehicle and state.vehicle:get_model() % 4294967296 == model or false
        if not self.in_truck then
            if self.truck and not ENTITY.DOES_ENTITY_EXIST(self.truck) then
                self:release(); self.truck = nil
            end
            return
        end
        if self.truck and self.truck ~= state.vehicle_handle then self:release(true) end
        self.truck = state.vehicle_handle
        if self.towed and not ENTITY.DOES_ENTITY_EXIST(self.towed.handle) then self:release() end
        if self.attach_phase and self.towed and util.time() >= self.attach_phase.next then
            local phase, offset = self.attach_phase, self.towed.offset
            if phase.generation ~= ctx.runtime.generation then
                self:release(); return
            end
            ENTITY.ATTACH_ENTITY_TO_ENTITY(self.towed.handle, self.truck, self.towed.bone, offset.x, offset.y, phase.z,
                0, 0, 0, false, true, true, false, 1, true, 1)
            if not ENTITY.IS_ENTITY_TOUCHING_ENTITY(self.truck, self.towed.handle) then
                offset.z = phase.z - 0.2; self:move(0, 0, 0); self.attach_phase = nil
            else
                phase.tries = phase.tries + 1; phase.z = phase.z + 0.05; phase.next = util.time() + 1
                if phase.tries > 60 then self.attach_phase = nil end
            end
        end
        local forward = ENTITY.GET_ENTITY_FORWARD_VECTOR(self.truck)
        local pos = ENTITY.GET_ENTITY_COORDS(self.truck, false)
        local search = Vector3.new(pos.x - forward.x * 10, pos.y - forward.y * 10, pos.z)
        local handle = ctx.game.closest_vehicle(search, 5, self.truck)
        self.target = nil
        if handle ~= 0 then
            local hash = ENTITY.GET_ENTITY_MODEL(handle) % 4294967296
            local allowed = ctx.settings:get(root .. '.tow_everything') or hash == 745926877
                or not VEHICLE.IS_THIS_MODEL_A_PLANE(hash) and not VEHICLE.IS_THIS_MODEL_A_HELI(hash)
            if hash ~= model and allowed then
                self.target = {
                    handle = handle,
                    model = hash,
                    name = Vehicle.new(handle)
                        :get_full_name()
                }
            end
        end
        if state.driving and not self.towed then
            if ctx.settings:get(root .. '.show_towing_position') then
                GRAPHICS.DRAW_MARKER_SPHERE(search.x, search.y,
                    search.z, 3, 180, 128, 0, 0.115)
            end
            if ctx.settings:get(root .. '.show_esp') and self.target then
                ctx.game.bounding_box(self.target.handle, 255,
                    255, 0, 255)
            end
        end
    end

    f.owns_controls = true
    function f:draw()
        local tr = ctx.translator; local Widgets = require('includes.ssv2.core.widgets')
        local value, changed = Widgets.toggle(ctx, tr:text('FLTBD_MAIN_CB'), self:enabled())
        if changed then ctx.settings:set(root .. '.enabled', value) end
        ImGui.Separator(); if not self:enabled() then return end
        ImGui.Spacing()
        if not self.in_truck then
            ImGui.TextWrapped(tr:text('FTLBD_GET_IN_MSG'))
            if Widgets.button(ctx, tr:text('GENERIC_SPAWN')) then
                ctx.runtime:run('flatbed spawn',
                    function() self:spawn() end)
            end
            return
        end
        ImGui.Dummy(1, 10)
        local text = self.towed and tr:text('FLTBD_TOWING_TXT') .. ' ' .. self.towed.name .. '.' or
            self.target and tr:text('FLTBD_NEARBY_VEH_TXT') .. ' ' .. self.target.name or tr:text('FLTBD_NO_VEH_TXT')
        ImGui.BulletText(text); ImGui.Dummy(1, 10)
        for _, item in ipairs({ { 'show_towing_position', 'FLTBD_SHOW_TOWPOS_CB', 'FLTBD_SHOW_TOWPOS_TT' }, { 'show_esp', 'FLTBD_SHOW_TOWBOX_CB', 'FLTBD_SHOW_TOWBOX_TT' }, { 'tow_everything', 'FLTBD_TOW_ALL_CB', 'FLTBD_TOW_ALL_TT' } }) do
            local value, changed = Widgets.toggle(ctx, tr:text(item[2]), ctx.settings:get(root .. '.' .. item[1])); if changed then
                ctx.settings:set(root .. '.' .. item[1], value)
            end
            Widgets.tooltip(ctx, tr:text(item[3]))
        end
        ImGui.Dummy(1, 10)
        if Widgets.button(ctx, tr:text(self.towed and 'GENERIC_DETACH' or 'FLTBD_TOW_BTN'), 80, 40) then
            ctx.runtime:run(
                'flatbed tow', function() self:toggle() end)
        end
        if self.towed then
            ImGui.Dummy(1, 5); ImGui.SeparatorText(tr:text('FLTBD_ADJUST_POS_TXT')); ImGui.SetWindowFontScale(0.8)
            ImGui.BulletText(tr:text('FLTBD_ADJUST_POS_TT')); ImGui.BulletText(tr:text('FLTBD_FAST_ADJUST_TXT')); ImGui
                .SetWindowFontScale(1); ImGui.Dummy(1, 10)
            ImGui.PushButtonRepeat(true); ImGui.InvisibleButton('##pad_up', 30, 30); ImGui.SameLine()
            for _, item in ipairs({ { '##Up', 2, 0, 0, 0.01 }, { '##Left', 0, 0, 0.01, 0 }, { '##Right', 1, 0, -0.01, 0 }, { '##Down', 3, 0, 0, -0.01 } }) do
                if item[1] == '##Right' then
                    ImGui.SameLine(); ImGui.InvisibleButton('##pad_mid', 30, 30); ImGui.SameLine()
                elseif item[1] == '##Down' then
                    ImGui.InvisibleButton('##pad_down', 30, 30); ImGui.SameLine()
                end
                if ImGui.ArrowButton(item[1], item[2]) then
                    ctx.runtime:run('flatbed adjustment',
                        function() self:move(item[3], item[4], item[5]) end)
                end
            end
            ImGui.PopButtonRepeat()
        end
    end

    return f
end
