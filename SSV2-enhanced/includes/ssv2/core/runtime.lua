local Runtime = {}
Runtime.__index = Runtime

local function traceback(err) return debug.traceback(tostring(err), 2) end

function Runtime.new(settings, state, build)
    return setmetatable({
        settings = settings,
        state = state,
        build = build,
        features = {},
        running = true,
        generation = 0,
        started = false,
        shutdown = {},
        services = {},
        service_names = {}
    }, Runtime)
end

function Runtime:run(label, callback)
    script.run_in_callback(function()
        if not self.running then return end
        local ok, err = xpcall(callback, traceback)
        if not ok then
            log.warn('Samurai ' .. label .. ': ' .. err)
            self:report(label .. ' failed; see the log')
        end
    end)
end

function Runtime:report(message)
    if self.notifier then
        self.notifier:error("Samurai's Scripts", message)
    else
        notify.error("Samurai's Scripts", message)
    end
end

function Runtime:add(feature)
    assert(not self.started, 'Register features before starting the runtime')
    self.features[#self.features + 1] = feature
end

function Runtime:loop(name, callback, cleanup)
    assert(not self.service_names[name], 'Duplicate service loop: ' .. name)
    local service = { id = name, service = true, callback = callback, cleanup = cleanup, created = util.time(), active = true }
    self.services[#self.services + 1] = service; self.service_names[name] = service
    self:run(name, function()
        service.started_at = util.time()
        while self.running and not service.debug_removed do
            if service.before_tick then service.before_tick() end
            if not service.paused and not service.auto_suspended and not service.debug_disabled then
                service.active = true
                local cpu_start, cycle_start = os.clock(), util.time()
                service.last_entry_at = cycle_start; service.stage = 'PRE_CALLBACK'
                local ok, err = xpcall(callback, traceback)
                service.stage = 'POST_CALLBACK'; service.last_exit_at = util.time()
                service.cpu_total = (service.cpu_total or 0) + (os.clock() - cpu_start)
                service.ticks = (service.ticks or 0) + 1
                local work_ms = util.time() - cycle_start
                service.cpu_average_ms = (service.cpu_average_ms or 0) * 0.9 + work_ms * 0.1
                if not ok then
                    service.error = err; service.debug_disabled = true
                    self:cleanup(service); log.warn('Samurai ' .. name .. ': ' .. err); self:report(name ..
                        ' stopped after an error')
                end
                service.cycle_start = cycle_start
            end
            service.stage = 'IDLE'
            script.yield(0)
            if service.cycle_start then
                service.cpu_average_cycle_ms = (service.cpu_average_cycle_ms or 0) * 0.9 +
                    (util.time() - service.cycle_start) * 0.1
                service.cycle_start = nil
            end
        end
        self:cleanup(service)
    end)
    return service
end

function Runtime:service_running(name)
    local service = self.service_names[name]
    return not service or
        not (service.paused or service.auto_suspended or service.debug_disabled or service.debug_removed)
end

function Runtime:internal_state(service)
    local now = util.time()
    if now - (service.last_entry_at or 0) > 5000 then return 'STALLED' end
    if now - (service.last_exit_at or 0) > 2000 then return 'STARVED' end
    if (service.cpu_average_cycle_ms or 0) < 0.02 then return 'TOO_FAST' end
    if (service.cpu_average_ms or 0) < 0.1 then return 'BURSTING' end
    return 'NORMAL'
end

function Runtime:load_average(service)
    local cycle = service.cpu_average_cycle_ms or 0
    return cycle == 0 and 0 or (service.cpu_average_ms or 0) / cycle
end

function Runtime:cleanup(feature)
    if feature.active then
        feature.active = false
        if feature.cleanup then
            local ok, err = xpcall(function() feature:cleanup() end, traceback)
            if not ok then log.warn('Samurai cleanup ' .. feature.id .. ': ' .. err) end
        end
    end
end

function Runtime:reset()
    self.generation = self.generation + 1
end

function Runtime:tick_feature(feature)
    local cpu_start = os.clock()
    local ok, err = xpcall(function()
        if feature.paused or feature.debug_removed then return end
        if feature.poll then feature:poll() end
        local state = self.state:read()
        if feature.uses_vehicle_controller and state then state = self.state:vehicle_state(state) end
        if not feature.debug_disabled and feature:enabled() and state and (not feature.requires_build or self.build.compatible) and feature:ready(state) then
            local identity = feature.scope == 'vehicle' and state.vehicle_handle or state.handle
            if feature.active and feature.identity ~= identity then self:cleanup(feature) end
            if not feature.active then
                feature.active, feature.identity, feature.error = true, identity, nil
                if feature.enter then feature:enter(state) end
            end
            feature:update(state)
        else
            self:cleanup(feature)
        end
    end, traceback)
    feature.cpu_total = (feature.cpu_total or 0) + (os.clock() - cpu_start)
    feature.ticks = (feature.ticks or 0) + 1
    feature.cpu_average_ms = feature.cpu_total * 1000 / feature.ticks
    if not ok then
        self:cleanup(feature); feature.error = err
        if feature.disable then feature:disable() end
        log.warn('Samurai ' .. feature.id .. ': ' .. err); self:report(feature.id .. ' disabled after an error')
    end
end

function Runtime:start()
    assert(not self.started, 'Runtime already started'); self.started = true
    local names = {}
    for name, ids in pairs(require('includes.ssv2.data.runtime_loops')) do
        for _, id in ipairs(ids) do
            assert(not names[id], 'Duplicate loop owner: ' .. id); names[id] = name
        end
    end
    local groups, ordered = {}, {}
    for _, feature in ipairs(self.features) do
        local name = assert(names[feature.id], 'Missing original loop owner: ' .. feature.id)
        if not groups[name] then
            groups[name] = {}; ordered[#ordered + 1] = name
        end
        groups[name][#groups[name] + 1] = feature
        feature.runtime_generation = self.generation; feature.started_at = util.time()
    end
    for _, name in ipairs(ordered) do
        local members = groups[name]
        local service = self:loop(name, function()
            for _, feature in ipairs(members) do self:tick_feature(feature) end
        end, function() for _, feature in ipairs(members) do self:cleanup(feature) end end)
        service.members = members
        local gates = {
            SS_FLARES = { 'features.vehicle.flares' },
            SS_VEH_CRASH = { 'features.vehicle.strong_crash' },
            SS_LAUNCH_CTRL = { 'features.vehicle.launch_control', 'features.vehicle.burble_tune' },
            SS_VEH_DRIFT_MINIGAME = { 'features.vehicle.drift_minigame.enabled' },
            SS_FLTBD_MAIN_CB = { 'features.flatbed.enabled' },
            SS_WRLD_HNS = { 'features.world.hide_n_seek' },
            SS_WRLD_CARPOOL = { 'features.world.carpool' }
        }
        if gates[name] then
            service.auto_suspended = not members[1]:enabled()
            for _, path in ipairs(gates[name]) do
                self.settings:on_change(path, function() service.auto_suspended = not members[1]:enabled() end)
            end
        end
        service.before_tick = function()
            for _, feature in ipairs(members) do
                if feature.runtime_generation ~= self.generation then
                    self:cleanup(feature); feature.runtime_generation = self.generation
                end
                if service.auto_suspended then self:cleanup(feature) end
            end
        end
        for _, feature in ipairs(members) do feature.loop = service end
    end
end

function Runtime:control(feature, mode)
    if mode == 'pause' then
        feature.paused = true; feature.started_at = 0
    elseif mode == 'resume' then
        feature.paused = false; feature.auto_suspended = false; feature.debug_disabled = false; feature.started_at = util
            .time(); feature.error = nil
    elseif mode == 'stop' then
        feature.paused = false; feature.debug_disabled = true; self:cleanup(feature)
    elseif mode == 'remove' then
        feature.paused = false; feature.debug_removed = true; feature.debug_disabled = true; self:cleanup(feature)
    else
        error('Unknown feature loop operation')
    end
end

function Runtime:stop()
    self.running = false
    for _, feature in ipairs(self.features) do self:cleanup(feature) end
    for _, service in ipairs(self.services) do self:cleanup(service) end
    for _, callback in ipairs(self.shutdown) do
        local ok, err = xpcall(callback, traceback)
        if not ok then log.warn('Samurai shutdown: ' .. err) end
    end
    self.settings:save()
end

return Runtime
