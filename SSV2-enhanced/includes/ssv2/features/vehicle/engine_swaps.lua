local Memory = require('includes.ssv2.core.vehicle_memory')
local engines = require('includes.ssv2.data.engine_swaps')
local model_names = require('includes.ssv2.data.vehicle_hashmap')
local Widgets = require('includes.ssv2.core.widgets')
return function(ctx)
    local f = {
        id = 'engine_swaps',
        category = 'vehicle',
        scope = 'vehicle',
        selected = 0,
        controls = {
            { kind = 'toggle', path = 'ui.show_engine_swaps', label = 'VEH_ENGINE_SWAP' },
        },
        next_ram = 0
    }
    function f:enabled() return not self.failed end

    function f:disable() self.failed = true end

    function f:ready(state) return state.alive and state.car end

    function f:restore()
        if self.lease then
            self.lease:restore(); self.lease = nil
        end
        if self.audio and self.identity and ENTITY.DOES_ENTITY_EXIST(self.identity) and Memory.identity(self.identity) == self.base then
            AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(self.identity, self.original_audio)
        end
        self.audio = false; self.radio_at = nil
    end

    function f:cleanup() self:restore() end

    function f:enter(state)
        self.base = Memory.identity(self.identity)
        local hash = state.vehicle:get_model() % 4294967296
        self.original_audio = model_names[hash] or VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(hash)
    end

    function f:swap(index)
        if not self.active then return end
        local engine = assert(engines[index], 'Invalid engine choice')
        if ENTITY.GET_ENTITY_MODEL(self.identity) % 4294967296 == util.joaat(engine.audioname) % 4294967296 then
            ctx.notifier:error('Engine Swap', ctx.translator:text('VEH_ENGINE_SWAP_SAME_ERR')); return
        end
        self:restore()
        self.lease = Memory.float_lease(self.identity, function(handle)
            local handling = Memory.base(handle):add(0x960):deref()
            assert(not handling:is_null(), 'Vehicle handling data is unavailable'); return handling:add(0x4C)
        end, engine.acc_mult)
        self.audio = true; AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(self.identity, engine.audioname)
        self.radio_at = util.time() + 150
    end

    function f:update()
        if self.radio_at and util.time() >= self.radio_at then
            if AUDIO.IS_VEHICLE_RADIO_ON(self.identity) then AUDIO.SET_VEH_RADIO_STATION(self.identity, 'OFF') end
            self.radio_at = nil
        end
    end

    function f:ram(direction)
        local state = ctx.state:vehicle_state()
        if not state or not state.car or not state.driving or not VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(state.vehicle_handle)
            or util.time() < self.next_ram then
            return
        end
        local force = math.min(100000, ENTITY.GET_ENTITY_SPEED(state.vehicle_handle) * 3000)
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(state.vehicle_handle, 1, direction == 0 and 0 or direction * force,
            direction == 0 and force or 0, 0, false, true, false, false)
        self.next_ram = util.time() + 3000
    end

    for id, direction in pairs({ veh_ram_fwd = 0, veh_ram_left = -1, veh_ram_right = 1 }) do
        local value = direction; ctx.input:bind(id, function() f:ram(value) end)
    end
    f.owns_controls = true
    function f:draw()
        local tr = ctx.translator
        if not self.active then
            ImGui.Text(tr:text('GENERIC_CARS_ONLY')); return
        end
        ImGui.SetNextWindowBgAlpha(0)
        if ImGui.BeginChild('##engines_c', ImGui.GetContentRegionAvail() - 180, 260, false) then
            if ImGui.BeginListBox('##engines', ImGui.GetContentRegionAvail() - 1, -1) then
                for index, engine in ipairs(engines) do
                    ImGui.Selectable(engine.name, self.selected == index - 1); if ImGui.IsItemClicked() then
                        self.selected =
                            index - 1
                    end
                end
                ImGui.EndListBox()
            end
        end
        ImGui.EndChild(); ImGui.SameLine(); ImGui.SetNextWindowBgAlpha(0)
        if ImGui.BeginChild('##engine_s_btns', 0, 260, false) then
            if Widgets.button(ctx, tr:text('GENERIC_CONFIRM'), 140, 35) then
                local index = self.selected + 1; ctx.runtime:run('engine swap',
                    function() if self.active then self:swap(index) end end)
            end
            if Widgets.button(ctx, tr:text('GENERIC_RESET'), 140, 35) then
                ctx.runtime:run('engine reset',
                    function() self:restore() end)
            end
        end
        ImGui.EndChild(); ImGui.Spacing(); ImGui.SetWindowFontScale(0.9); ImGui.BulletText(engines[self.selected + 1].tt); ImGui
            .SetWindowFontScale(1)
    end

    return f
end
