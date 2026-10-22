local Managed = require('includes.ssv2.core.managed_value')
local definitions = require('includes.ssv2.data.cooldowns')
local setup_costs = { 'HEIST_SETUP_COST_FLEECA', 'HEIST_SETUP_COST_HUMANE_LABS', 'HEIST_SETUP_COST_PRISON_BREAK',
    'HEIST_SETUP_COST_SERIES_A', 'HEIST_SETUP_COST_PACIFIC_STANDARD', 'H2_COST_IAA_JOB', 'H2_COST_SUB_JOB',
    'H2_COST_SILO_OPERATION', 'HEIST3_SETUP_COST', 'H4_REPLAY_COST', 2091994868 }
return function(ctx)
    local f = { id = 'cooldowns', category = 'online', scope = 'player', entries = {}, next_check = 0, controls = {} }
    local keys = {}; for key in pairs(definitions) do keys[#keys + 1] = key end; table.sort(keys)
    for _, key in ipairs(keys) do
        local definition = definitions[key]
        if ctx.settings:get(definition.path) == nil then ctx.settings:set(definition.path, false) end
        local entry = { path = definition.path, values = {}, applied = false }
        for _, value in ipairs(definition.defs) do entry.values[#entry.values + 1] = Managed.new(ctx, value) end
        f.entries[#f.entries + 1] = entry
        f.controls[#f.controls + 1] = { kind = 'toggle', path = entry.path, label = key:gsub('_', ' ') }
    end
    local cost_entry = { path = 'features.yim_heists.sixty_nine', values = {}, applied = false }
    for _, name in ipairs(setup_costs) do
        cost_entry.values[#cost_entry.values + 1] = Managed.new(ctx,
        { t = name, kind = 'tunable', type = 'int', v = 69 })
    end
    f.entries[#f.entries + 1] = cost_entry
    f.controls[#f.controls + 1] = { kind = 'toggle', path = cost_entry.path, label = '$69 heist setup costs' }
    function f:enabled() return not self.failed end

    function f:disable() self.failed = true end

    function f:ready() return network.is_session_started() and not NETWORK.NETWORK_IS_ACTIVITY_SESSION() end

    function f:enter()
        self.next_check = 0
        for _, entry in ipairs(self.entries) do for _, value in ipairs(entry.values) do value:capture() end end
    end

    function f:cleanup()
        for _, entry in ipairs(self.entries) do
            for _, value in ipairs(entry.values) do value:clear() end
            entry.applied = false
        end
    end

    function f:update()
        local periodic = util.time() >= self.next_check
        for _, entry in ipairs(self.entries) do
            local enabled = ctx.settings:get(entry.path) == true
            if enabled and (periodic or not entry.applied) then
                local success = true
                for _, value in ipairs(entry.values) do if not value:apply() then success = false end end
                entry.applied = success
            elseif not enabled and entry.applied then
                for _, value in ipairs(entry.values) do value:reset() end
                entry.applied = false
            end
        end
        if periodic then self.next_check = util.time() + 2000 end
    end

    function f:draw()
        if self.failed and ImGui.Button('Retry cooldown controls') then self.failed = false end
    end

    return f
end
