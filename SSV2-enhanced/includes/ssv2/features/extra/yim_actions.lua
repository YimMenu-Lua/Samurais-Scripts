local Settings = require('includes.ssv2.core.settings')
local Props = require('includes.ssv2.core.action_props')
local Scenes = require('includes.ssv2.core.action_scenes')
local ped_names = {}
for name, definition in pairs(require('includes.ssv2.data.peds')) do ped_names[definition.model_hash % 4294967296] = name end
local categories = { 'anims', 'scenarios', 'clipsets', 'scenes' }
local copy
copy = function(value)
    if type(value) ~= 'table' then return value end
    local result = {}; for key, item in pairs(value) do result[key] = copy(item) end; return result
end
return function(ctx)
    local f = {
        id = 'yim_actions',
        category = 'extra',
        scope = 'player',
        owns_controls = true,
        playing = {},
        history = {},
        history_set = {},
        selected_kind = 0,
        browser_mode = 0,
        search = '',
        anim_category = 0,
        anim_filter = 0,
        command_name = '',
        companion_model = 'a_m_y_business_01',
        companion_name = '',
        controls = { { kind = 'toggle', path = 'ui.show_actions',       label = 'Yim Actions' },
            { kind = 'toggle', path = 'features.yim_actions.disable_props', label = 'Disable action props' },
            { kind = 'toggle', path = 'features.yim_actions.disable_ptfx',  label = 'Disable action particle effects' },
            { kind = 'toggle', path = 'features.yim_actions.disable_sfx',   label = 'Disable action speech' } },
        datasets = {}
    }
    f.favorites = Settings.new({ anims = {}, scenarios = {}, clipsets = {}, scenes = {} }, 'ssv2/saved_actions.json')
    f.commands = Settings.new({ aliases = {} }, 'ssv2/action_commands.json')
    for _, kind in ipairs(categories) do
        local filename = kind == 'anims' and 'animations' or kind == 'clipsets' and 'movement_clipsets' or
            kind == 'scenes' and 'synchronized_scenes' or kind
        f.datasets[kind] = require('includes.ssv2.data.actions.' .. filename)
    end
    function f:enabled() return not self.failed end

    function f:disable() self.failed = true end

    function f:ready(state) return state.alive and not PLAYER.IS_PLAYER_BEING_ARRESTED(state.player_id, true) end

    function f:enter()
        self.props = Props.new(ctx); self.scenes = Scenes.new(ctx)
        self.companions = require('includes.ssv2.core.action_companions').new(ctx, self)
        self.wompus = self.wompus or require('includes.ssv2.core.wompus').new(ctx, self)
        self.playing = {}; self.stopping = {}; self.tokens = {}; self.movements = {}; self.serial = (self.serial or 0) +
            1
    end

    function f:valid(serial, generation)
        return self.active and ctx.runtime.running and self.serial == serial and ctx.runtime.generation == generation
    end

    function f:run(label, callback)
        local serial, generation = self.serial, ctx.runtime.generation
        ctx.runtime:run(label,
            function() if self:valid(serial, generation) then callback(function() return self:valid(serial, generation) end) end end)
    end

    function f:busy(ped)
        if ped == PLAYER.PLAYER_PED_ID() then
            for _, name in ipairs(require('includes.ssv2.data.app_scripts')) do if scripts.is_active(name) then return true end end
        end
        return ped == PLAYER.PLAYER_PED_ID() and (CUTSCENE.IS_CUTSCENE_ACTIVE() or CUTSCENE.IS_CUTSCENE_PLAYING()
            or NETWORK.NETWORK_IS_IN_MP_CUTSCENE() or HUD.IS_MP_TEXT_CHAT_TYPING() or ENTITY.IS_ENTITY_IN_WATER(ped)
            or PED.IS_PED_RAGDOLL(ped) or scripts.is_active('maintransition') or STREAMING.IS_PLAYER_SWITCH_IN_PROGRESS()
            or ctx.activity:busy() and not self.playing[ped])
    end

    function f:reset_movement(ped)
        if not self.movements[ped] then return end
        self.movements[ped] = nil
        if ENTITY.DOES_ENTITY_EXIST(ped) then
            PED.RESET_PED_MOVEMENT_CLIPSET(ped, 0.3); PED.RESET_PED_STRAFE_CLIPSET(ped)
            PED.RESET_PED_WEAPON_MOVEMENT_CLIPSET(ped); PED.CLEAR_PED_ALTERNATE_MOVEMENT_ANIM(ped, 0, -8)
            WEAPON.SET_WEAPON_ANIMATION_OVERRIDE(ped, 3839837909)
        end
    end

    function f:movement(definition, ped)
        self:reset_movement(ped)
        local entry = { data = copy(definition) }; self.movements[ped] = entry
        local serial, generation = self.serial, ctx.runtime.generation
        local function valid()
            return self:valid(serial, generation) and self.movements[ped] == entry and
                ENTITY.DOES_ENTITY_EXIST(ped)
        end
        local ok, result = pcall(function()
            for field, method in pairs({ mvmt = PED.SET_PED_MOVEMENT_CLIPSET, wmvmt = PED.SET_PED_WEAPON_MOVEMENT_CLIPSET, strf = PED.SET_PED_STRAFE_CLIPSET }) do
                if definition[field] then
                    if not self.props.pool:wait('clipset', definition[field], valid) then return false end
                    if field == 'mvmt' then
                        method(ped, definition[field], 1)
                        PED.SET_PED_ALTERNATE_MOVEMENT_ANIM(ped, 0, 'move_clown@generic', 'idle', 1090519040, true)
                        TASK.SET_PED_CAN_PLAY_AMBIENT_IDLES(ped, true, true)
                    else
                        method(ped, definition[field])
                    end
                end
            end
            if definition.wanim then WEAPON.SET_WEAPON_ANIMATION_OVERRIDE(ped, util.joaat(definition.wanim)) end
            return valid()
        end)
        if not ok or not result then
            if self.movements[ped] == entry then self:reset_movement(ped) end
            if not ok then error(result) end; return false
        end
        self:remember('clipsets', definition); return true
    end

    function f:stop(ped, force)
        local current = self.playing[ped]
        self.tokens[ped] = (self.tokens[ped] or 0) + 1; self.playing[ped] = nil
        self:reset_movement(ped)
        if not current then return end
        local pending = { serial = self.serial, generation = ctx.runtime.generation, current = current }
        self.stopping[ped] = pending
        local function valid()
            return self.stopping[ped] == pending and self:valid(pending.serial, pending.generation)
                and ENTITY.DOES_ENTITY_EXIST(ped)
        end
        self.props:clear(ped)
        if current.kind == 'scenes' then self.scenes:clear() end
        -- The original releases props before clearing tasks, then waits for a
        -- local scenario's exit animation. Unload cleanup cannot yield.
        if not force and coroutine.running() then
            script.yield(16)
            if not valid() then return end
        end
        if ENTITY.DOES_ENTITY_EXIST(ped) then
            TASK.CLEAR_PED_TASKS(ped)
            if current.weapon_lock then PED.SET_PED_CAN_SWITCH_WEAPON(ped, true) end
        end
        if current.kind == 'anims' then STREAMING.REMOVE_ANIM_DICT(current.data.dict) end
        if not force and ped == self.identity and PED.IS_PED_USING_ANY_SCENARIO(ped) then
            HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON('STRING')
            HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(ctx.translator:text('YAV3_SCN_STOP_SPINNER'))
            HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(3)
            self.scenario_spinner = true
            while valid() and PED.IS_PED_USING_ANY_SCENARIO(ped) do script.yield(0) end
            if self.scenario_spinner then
                HUD.BUSYSPINNER_OFF(); self.scenario_spinner = false
            end
        end
        if self.stopping[ped] ~= pending then return end
        self.stopping[ped] = nil
        if ped == self.identity then ctx.activity:release(self) end
    end

    function f:cleanup()
        self.serial = (self.serial or 0) + 1
        self.debug_actors = {}
        for ped in pairs(self.playing) do self:stop(ped, true) end
        for ped, pending in pairs(self.stopping) do
            if ENTITY.DOES_ENTITY_EXIST(ped) then
                TASK.CLEAR_PED_TASKS(ped)
                if pending.current.weapon_lock then PED.SET_PED_CAN_SWITCH_WEAPON(ped, true) end
            end
        end
        self.stopping = {}
        if self.scenario_spinner then
            HUD.BUSYSPINNER_OFF(); self.scenario_spinner = false
        end
        for ped in pairs(self.movements or {}) do self:reset_movement(ped) end
        if self.scenes then self.scenes:clear() end
        if self.props then self.props:clear_all() end
        if self.companions then self.companions:clear() end
        if self.wompus then self.wompus:clear() end
        ctx.activity:release(self)
        self.favorites:save(); self.commands:save()
    end

    function f:remember(kind, definition)
        local label = definition.label or definition.Name
        if self.history_set[label] then return end
        self.history_set[label] = true
        if self.history_locked then
            self.history_deferred = self.history_deferred or {}
            self.history_deferred[#self.history_deferred + 1] = {
                kind = kind,
                data = copy(definition),
                timestamp = os
                    .time()
            }
            return
        end
        self.history[#self.history + 1] = { kind = kind, data = copy(definition), timestamp = os.time() }
    end

    function f:clear_history()
        if self.history_locked or #self.history == 0 then return end
        self.history_locked = true; self.history_clear_count = #self.history
        ctx.runtime:run('clear action history', function()
            local count = self.history_clear_count
            for index = count, 1, -1 do
                if not ctx.runtime.running then break end
                table.remove(self.history, index)
                local ratio = index / count
                script.yield(math.max(1, math.floor(200 * ratio * ratio / count)))
            end
            self.history = {}; self.history_set = {}
            for _, entry in ipairs(self.history_deferred or {}) do
                self.history[#self.history + 1] = entry; self.history_set[entry.data.label or entry.data.Name] = true
            end
            self.history_deferred = nil; self.history_clear_count = nil; self.history_locked = false
        end)
    end

    function f:sort_history(mode)
        if self.history_locked or mode == (self.history_sort or 0) then return end
        local order = { anims = 1, scenarios = 2, scenes = 3, clipsets = 4 }
        table.sort(self.history, function(a, b)
            if mode == 0 then
                return a.timestamp > b.timestamp
            elseif mode == 1 then
                return order[a.kind] < order[b.kind]
            else
                return (a.data.label or a.data.Name) < (b.data.label or b.data.Name)
            end
        end)
        self.history_sort = mode
    end

    function f:play(kind, definition, ped)
        ped = ped or PLAYER.PLAYER_PED_ID()
        assert(ENTITY.DOES_ENTITY_EXIST(ped), 'Action actor no longer exists')
        local initial_serial, initial_generation = self.serial, ctx.runtime.generation
        while self.stopping[ped] do
            script.yield(0)
            if not self:valid(initial_serial, initial_generation) then return false end
        end
        if self:busy(ped) then
            ctx.notifier:info('Yim Actions', 'Player is unavailable for this action'); return false
        end
        if kind == 'clipsets' then return self:movement(definition, ped) end
        self:stop(ped)
        if not self:valid(initial_serial, initial_generation) then return false end
        local current = { kind = kind, data = definition, started = util.time(), starting = true }
        local serial, generation, token = self.serial, ctx.runtime.generation, self.tokens[ped] or 0
        self.playing[ped] = current
        local function valid()
            return self:valid(serial, generation) and self.playing[ped] == current and
                self.tokens[ped] == token and ENTITY.DOES_ENTITY_EXIST(ped)
        end
        local ok, result = pcall(function()
            if kind == 'anims' then
                if definition.category == 'In-Vehicle' then
                    assert(not PED.IS_PED_ON_FOOT(ped), 'This animation requires a vehicle')
                    local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                    local seat
                    for i = -1, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle) - 1 do
                        if VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, i, false) == ped then
                            seat = i; break
                        end
                    end
                    if seat and seat <= 2 then
                        if definition.label:find('Race Taunt', 1, true) and seat == -1 then
                            VEHICLE.ROLL_DOWN_WINDOW(vehicle, 0)
                        elseif definition.label:match('Lean.+%(in%-car%)') then
                            VEHICLE.ROLL_DOWN_WINDOW(vehicle, seat + 1)
                        end
                    end
                end
                if not self.props.pool:wait('animation', definition.dict, valid) then return false end
                TASK.TASK_PLAY_ANIM(ped, definition.dict, definition.name, definition.blendInSpeed or 4,
                    definition.blendOutSpeed or -4,
                    definition.playTime or -1, definition.flags or 0, 0, false, false, false)
                if not ctx.settings:get('features.yim_actions.disable_props') then
                    self.props:attach(ped, definition.props, false, valid); self.props:attach(ped, definition.propPeds,
                        true, valid)
                end
                if not ctx.settings:get('features.yim_actions.disable_ptfx') then
                    self.props:effect(ped, definition.ptfx,
                        valid)
                end
            elseif kind == 'scenarios' then
                if definition.label == 'Cook On BBQ' then
                    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0, 1, 0)
                    local bbq = self.props:spawn(ped, { model = 286252949 }, false, valid, pos, true)
                    if bbq then
                        ENTITY.SET_ENTITY_HEADING(bbq.handle, ENTITY.GET_ENTITY_HEADING(ped) - 180); OBJECT
                            .PLACE_OBJECT_ON_GROUND_PROPERLY(bbq.handle)
                    end
                end
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
                TASK.TASK_START_SCENARIO_IN_PLACE(ped, definition.scenario, -1, true)
            elseif kind == 'scenes' then
                return self.scenes:play(definition, valid)
            else
                error('Unknown action kind: ' .. tostring(kind))
            end
            return valid()
        end)
        if not ok or not result then
            if self.playing[ped] == current then self:stop(ped) end
            if not ok then error(result) end; return false
        end
        current.starting = false; current.started = util.time()
        self:remember(kind, definition)
        if ped == PLAYER.PLAYER_PED_ID() and kind ~= 'clipsets' then ctx.activity:acquire(self, 'playing') end
        return true
    end

    function f:execute(name)
        local alias = self.commands.data.aliases[name]
        assert(alias, 'Unknown action command')
        local definition
        for _, item in ipairs(self.datasets[alias.kind] or {}) do
            if (item.label or item.Name) == alias.label then
                definition = item; break
            end
        end
        if not definition then
            definition = self.favorites.data[alias.kind] and
                self.favorites.data[alias.kind][alias.label] or alias.data
        end
        assert(definition, 'The saved action is unavailable'); return self:play(alias.kind, definition)
    end

    function f:pistol_scene(ped, current)
        if current.shooting or current.data.dict ~= 'mp_suicide' or current.data.name ~= 'pistol'
            or ENTITY.GET_ENTITY_ANIM_CURRENT_TIME(ped, 'mp_suicide', 'pistol') > 0.299 then
            return
        end
        current.shooting = true
        self:run('pistol_action', function(valid)
            local pistol
            local weapon = ctx.game.current_weapon(ped)
            if weapon and WEAPON.GET_WEAPONTYPE_GROUP(weapon) % 4294967296 == util.joaat('GROUP_PISTOL') % 4294967296 then
                pistol = weapon
            else
                for hash, definition in pairs(require('includes.ssv2.data.weapon_data')) do
                    if definition.group == 'GROUP_PISTOL' and WEAPON.HAS_PED_GOT_WEAPON(ped, hash, false) then
                        pistol = hash; break
                    end
                end
            end
            if not pistol then return end
            WEAPON.SET_CURRENT_PED_WEAPON(ped, pistol, true)
            current.weapon_lock = true; PED.SET_PED_CAN_SWITCH_WEAPON(ped, false)
            while valid() and self.playing[ped] == current and ENTITY.GET_ENTITY_ANIM_CURRENT_TIME(ped, 'mp_suicide', 'pistol') < 0.299 do
                script.yield(0)
            end
            if valid() and self.playing[ped] == current then
                PED.SET_PED_SHOOTS_AT_COORD(ped, 0, 0, 0, false)
                PED.SET_PED_CAN_SWITCH_WEAPON(ped, true); current.weapon_lock = false
            end
        end)
    end

    function f:update(state)
        self.favorites:update(); self.commands:update(); self.companions:update()
        self.player_busy = self:busy(state.handle)
        local now = util.time()
        for ped, current in pairs(self.playing) do
            if not current.starting then
                local definition = current.data
                if not ENTITY.DOES_ENTITY_EXIST(ped) or ENTITY.IS_ENTITY_DEAD(ped, false) then
                    self:stop(ped)
                elseif current.kind == 'anims' then
                    local flags = definition.flags or 0
                    local persistent = bit.band(flags, 3) ~= 0
                    local running = ENTITY.IS_ENTITY_PLAYING_ANIM(ped, definition.dict, definition.name, 3)
                    if persistent and not running then
                        if PED.IS_PED_FALLING(ped) or PED.IS_PED_RAGDOLL(ped) then
                            current.recovering = true
                        elseif current.recovering then
                            current.recovering = false; current.retry_at = now + 1000
                        end
                    end
                    if definition.category == 'In-Vehicle' and (PED.IS_PED_ON_FOOT(ped) or PAD.IS_CONTROL_PRESSED(0, 75) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 75)) then
                        self:stop(ped)
                    elseif not persistent and (now - current.started > 200 and not running or ENTITY.GET_ENTITY_ANIM_CURRENT_TIME(ped, definition.dict, definition.name) >= 0.99
                            or definition.playTime and definition.playTime >= 0 and now - current.started >= definition.playTime) then
                        self:stop(ped)
                    elseif persistent and not running and not current.replaying and now >= (current.retry_at or 0)
                        and not PED.IS_PED_FALLING(ped) and not PED.IS_PED_RAGDOLL(ped) then
                        if ctx.game.swimming(ped) then
                            self:stop(ped)
                        else
                            current.replaying = true
                            self:run('action_resume',
                                function() if self.playing[ped] == current then self:play('anims', definition, ped) end end)
                        end
                    end
                    if self.playing[ped] == current then
                        self:pistol_scene(ped, current)
                        if not ctx.settings:get('features.yim_actions.disable_ptfx') and not ctx.settings:get('features.yim_actions.disable_props')
                            and definition.label:lower():find('police torch', 1, true) then
                            self.props:torch(ped)
                        end
                        if not ctx.settings:get('features.yim_actions.disable_sfx') then
                            self.props:speech(ped,
                                definition.sfx, now)
                        end
                    end
                elseif current.kind == 'scenarios' and now - current.started > 1000 and not PED.IS_PED_USING_ANY_SCENARIO(ped) then
                    if PED.IS_PED_RAGDOLL(ped) or PED.IS_PED_FALLING(ped) then
                        current.recovering = true
                    else
                        if current.recovering then
                            current.recovering = false; current.retry_at = now + 1000
                        end
                        if ctx.game.swimming(ped) then
                            self:stop(ped)
                        elseif now >= (current.retry_at or 0) then
                            self:run('scenario_resume',
                                function() if self.playing[ped] == current then self:play('scenarios', definition, ped) end end)
                            current.starting = true
                        end
                    end
                elseif current.kind == 'scenes' and not self.scenes:running() then
                    self:stop(ped)
                end
            end
        end
        self.snapshot = { actors = 0, props = 0, effects = 0 }
        if ctx.settings:get('backend.debug_mode') then
            self.debug_actors = {}
            for ped in pairs(self.playing) do
                local model = ENTITY.GET_ENTITY_MODEL(ped) % 4294967296; local name = ped_names[model] or tostring(model)
                self.debug_actors[ped] = { name = name, player = ped == state.handle }
            end
        end
        for _ in pairs(self.playing) do self.snapshot.actors = self.snapshot.actors + 1 end
        for _, owner in pairs(self.props.owners) do
            self.snapshot.props = self.snapshot.props + #owner.entities; self.snapshot.effects = self.snapshot.effects +
                #owner.effects
        end
    end

    ctx.input:bind('stop_anim', function()
        if not f.active then return end
        local serial, generation = f.serial, ctx.runtime.generation; local start = util.time()
        while ctx.input:is_held('stop_anim') and f:valid(serial, generation) do
            if util.time() - start >= 1000 then
                for ped in pairs(f.playing) do f:stop(ped) end
                f.props:clear_all(); f.companions:clear(); return
            end
            script.yield(0)
        end
        if f:valid(serial, generation) then f:stop(PLAYER.PLAYER_PED_ID()) end
    end)
    f.draw = require('includes.ssv2.core.actions_view')(ctx, f)
    return f
end
