local rules = require('includes.ssv2.data.minigame_rules')
local bits = require('includes.ssv2.data.minigame_bits')
return function(ctx)
    local data = ctx.script_data
    local f = { id = 'minigame_hack', category = 'online', scope = 'player', busy = false, quarantine = {}, controls = {} }
    function f:enabled() return true end

    function f:disable() end

    function f:ready() return network.is_session_started() end

    function f:update() end

    function f:cleanup() self.cancelled = true end

    function f:apply(name, rule, valid)
        local function resolve(offsets) return data:local_value(rule.key, offsets, name) end
        local value = resolve(rule.offsets); if not value then return end
        if rule.kind == 'int' then
            value:set_int(rule.value)
        elseif rule.kind == 'float' then
            value:set_float(rule.value)
        elseif rule.kind == 'copy_state' then
            value:set_int(value:at(1):get_int()); value:at(2):set_int(3)
        elseif rule.kind == 'password' then
            if value:get_int() ~= 3 then return end
            local password = value:at(1); password:set_int(2)
            for _, pair in ipairs({ { 2, 3 }, { 4, 5 }, { 6, 7 } }) do
                password:at(pair[1]):set_int(password:at(pair[2])
                    :get_int())
            end
            PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 237, 1)
        elseif rule.kind == 'eight_flags' then
            for i = 0, 7 do resolve({ { i, 4 } }):set_int(1) end
        elseif rule.kind == 'combination' then
            for i = 0, 2 do
                if not valid() then return end
                -- Resolve again after every wait; a ScriptLocal borrows the running thread's stack.
                local current = resolve(rule.offsets):at(i, 2)
                current:set_int(1); current:at(1):set_int(1)
                script.yield(300)
                if not valid() then return end
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 237, 1)
            end
        end
    end

    function f:run()
        if self.busy or not self.active or not ctx.build.compatible then return end
        self.busy, self.cancelled = true, false
        local generation = ctx.runtime.generation
        local found = false
        local ok, err = xpcall(function()
            for name, group in pairs(rules) do
                if scripts.is_active(name) then
                    found = true
                    local first = data:local_value(group[1].key, nil, name)
                    local address = first and first:get_pointer():get_address()
                    local function valid()
                        if self.cancelled or not ctx.runtime.running or ctx.runtime.generation ~= generation or not network.is_session_started()
                            or not scripts.is_active(name) or not ctx.build.compatible then
                            return false
                        end
                        local current = data:local_value(group[1].key, nil, name)
                        return current and current:get_pointer():get_address() == address
                    end
                    for _, rule in ipairs(group) do
                        if not valid() then return end
                        local key = name .. ':' .. rule.key
                        if not self.quarantine[key] then
                            local good, failure = pcall(function() self:apply(name, rule, valid) end)
                            if not good then
                                self.quarantine[key] = tostring(failure); log.warn('Samurai minigame ' ..
                                    key .. ': ' .. tostring(failure))
                            end
                        end
                    end
                end
            end
            if generation ~= ctx.runtime.generation or self.cancelled then return end
            for name, group in pairs(bits) do
                if scripts.is_active(name) then
                    found = true
                    for _, rule in ipairs(group) do
                        data:write_local_bits(rule.sgsl_entry, rule.bits, true, rule.offsets,
                            name)
                    end
                end
            end
            local global = data:global('mgh_tmp_v2_global')
            if global then global:set_int(bit.bor(global:get_int(), bit.lshift(1, 9), bit.lshift(1, 18), bit.lshift(1, 26))) end
            if not found then ctx.notifier:warn('MiniGameHack', ctx.translator:text('YH_MGH_NONE_FOUND_WARN')) end
        end, debug.traceback)
        self.busy = false
        if not ok then error(err) end
    end

    ctx.input:bind('minigamehack', function() f:run() end)
    function f:draw()
        ImGui.BeginDisabled(not self.active or self.busy or not ctx.build.compatible)
        if ImGui.Button('MiniGameHack (DEL)') then ctx.runtime:run('minigame_hack', function() self:run() end) end
        ImGui.EndDisabled()
        if next(self.quarantine) and ImGui.Button('Retry failed minigame rules') then self.quarantine = {} end
    end

    return f
end
