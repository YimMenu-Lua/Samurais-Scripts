local Settings = require('includes.ssv2.core.settings')
local Pool = require('includes.ssv2.core.entity_pool')
local data = require('includes.ssv2.data.billionaire_definitions')
local ped_names = require('includes.ssv2.data.ped_names')
local properties = require('includes.ssv2.data.mp_properties')
local function copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}; for key, item in pairs(value) do result[key] = copy(item) end; return result
end
local function names_from(map)
    local names = {}; for name in pairs(map) do names[#names + 1] = name end; table.sort(names); return names
end
return function(ctx)
    local f = {
        id = 'billionaire_services',
        category = 'extra',
        scope = 'player',
        guard_model = 's_m_y_blackops_01',
        guard_name = '',
        weapon = '350597077',
        guard_godmode = false,
        guard_no_ragdoll = false,
        guard_all_weapons = false,
        limo_index = 0,
        heli_index = 0,
        jet_index = 0,
        departure_index = 0,
        arrival_index = 0,
        heli_destination = 0,
        escort_index = 0,
        new_group_name = '',
        new_group_vehicle = '2370534026',
        new_group_members = {
            { name = '', model = 's_m_y_blackops_01', weapon = '350597077' }, { name = '', model = 's_m_y_blackops_01', weapon = '350597077' },
            { name = '', model = 's_m_y_blackops_01', weapon = '350597077' } },
        controls = {
            { kind = 'toggle', path = 'ui.show_billionaire', label = 'Billionaire Services' },
        }
    }
    f.store = Settings.new({ groups = {} }, 'ssv2/saved_escort_groups.json')
    f.model_browser = require('includes.ssv2.core.model_browser').new(ctx,
        { fixed_kind = 1, humans_only = true, max_entries = 250 })
    f.weapon_search = ''; f.weapon_group = ''
    function f:enabled() return not self.failed end

    function f:disable() self.failed = true end

    function f:ready(state) return state.alive end

    function f:random_name(gender)
        local names = ped_names[gender]
        return names and names[math.random(1, #names)] or 'Bodyguard'
    end

    function f:enter()
        self.serial = (self.serial or 0) + 1; self.pool = Pool.new(ctx); self.blips = require('includes.ssv2.core.blips')
            .new()
        self.guards = require('includes.ssv2.core.bodyguards').new(ctx, self)
        self.vehicles = require('includes.ssv2.core.vehicle_services').new(ctx, self)
        self.escorts = require('includes.ssv2.core.escort_groups').new(ctx, self)
        self.pending = {}
    end

    function f:valid(serial, generation)
        return self.active and ctx.runtime.running and self.serial == serial and ctx.runtime.generation == generation
    end

    function f:run(label, callback)
        local serial, generation = self.serial, ctx.runtime.generation
        ctx.runtime:run(label,
            function() if self:valid(serial, generation) then callback(function() return self:valid(serial, generation) end) end end)
    end

    function f:cleanup()
        self.serial = (self.serial or 0) + 1
        if self.vehicles then self.vehicles:clear() end
        if self.escorts then self.escorts:clear() end
        if self.guards then self.guards:clear() end
        if self.blips then self.blips:clear() end
        if self.pool then self.pool:clear() end
        self.store:save()
    end

    function f:call(kind, model, preset, godmode)
        assert(not self.pending[kind] and not self.vehicles.active[kind],
            'Private service is already active or being prepared')
        local ticket = {}; self.pending[kind] = ticket
        self:run('call_' .. kind, function(valid)
            local ok, result = pcall(function()
                local state = ctx.state:read(); if not state then return end
                if (kind == 'limo' or kind == 'heli') and not ctx.game.outside(state.handle) then
                    ctx.notifier:error('Billionaire Services', ctx.translator:text('GENERIC_INTERIOR_ACTION_ERR')); return
                end
                if kind == 'limo' and ENTITY.IS_ENTITY_IN_WATER(state.handle) then
                    ctx.notifier:error('Billionaire Services', ctx.translator:text('GENERIC_LOCATION_ACTION_ERR')); return
                end
                local entry = self.vehicles:spawn(kind, model, preset, godmode, valid)
                if entry and kind == 'heli' then
                    entry.ready = false
                    local water = state.on_foot and ENTITY.IS_ENTITY_IN_WATER(state.handle) or
                        state.vehicle and VEHICLE.IS_THIS_MODEL_A_BOAT(state.vehicle:get_model())
                    if not water then
                        local deadline = util.time() + 30000
                        repeat
                            script.yield(1000)
                            if not valid() or not self.vehicles:exists(entry) then return end
                        until ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(entry.vehicle.handle) <= 3 or util.time() >= deadline
                    else
                        ctx.notifier:info('Billionaire Services', ctx.translator:text('BSV2_HELI_LAND_WATER_ERR'))
                    end
                    self.vehicles:speak(entry, 'GENERIC_HOWS_IT_GOING', 'SPEECH_PARAMS_FORCE_HELI'); entry.ready = true; entry.task =
                    'idle'
                end
                return entry
            end)
            if self.pending[kind] == ticket then self.pending[kind] = nil end
            if not ok then error(result) end
        end)
    end

    function f:save_group(group, name)
        local definition = self.escorts:serialize(group); definition.name = name or definition.name
        local groups = copy(self.store.data.groups)
        assert(definition.name:find('%S'), 'Enter an escort group name')
        groups[definition.name] = definition; self.store:set('groups', groups); self.store:save()
    end

    function f:update(state)
        self.store:update()
        local now = util.time()
        for _, guard in pairs(self.guards.members) do self.guards:update(guard, state, now) end
        for i = #self.escorts.groups, 1, -1 do
            local group = self.escorts.groups[i]; if group then self.escorts:update(group, state, now) end
        end
        for _, vehicle in pairs(self.vehicles.active) do self.vehicles:update(vehicle, state, now) end
        self.frontend:update(state)
    end

    f.frontend = require('includes.ssv2.core.billionaire_view').new(ctx, f)
    f.owns_controls = true
    function f:draw() self.frontend:draw() end

    return f
end
