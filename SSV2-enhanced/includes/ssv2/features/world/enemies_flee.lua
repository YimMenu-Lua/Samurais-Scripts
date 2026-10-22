return function(ctx)
    local action = { busy = false, last_triggered = 0 }
    ctx.input:bind('enemies_flee', function() action:run() end)
    function action:run()
        if self.busy or ctx.clock:elapsed_ms() - self.last_triggered < 500 then return end
        local state = ctx.state:read()
        if not state or not state.alive then return end
        if not PED.IS_PED_IN_COMBAT(state.handle, 0) then
            ctx.notifier:warn("Samurai's Scripts", ctx.translator:text('GENERIC_NOT_IN_COMBAT')); return
        end
        self.busy = true
        local generation, player, tracked = ctx.runtime.generation, state.handle, {}
        local function valid()
            if not ctx.runtime.running or ctx.runtime.generation ~= generation then return false end
            local current = ctx.state:read()
            return current and current.alive and current.handle == player
        end
        local ok, err = pcall(function()
            ctx.notifier:success("Samurai's Scripts", ctx.translator:text('WRLD_FLEE_ALL_NOTIF'))
            local finish = ctx.clock:elapsed_ms() + 10000
            while valid() and ctx.clock:elapsed_ms() < finish do
                for _, ped in ipairs(entities.get_all_peds_as_handles()) do
                    if not valid() then return end
                    if ENTITY.DOES_ENTITY_EXIST(ped) and not ENTITY.IS_ENTITY_DEAD(ped, false)
                        and not tracked[ped] and ctx.game.is_enemy(player, ped) then
                        TASK.CLEAR_PED_TASKS(ped); TASK.CLEAR_PED_SECONDARY_TASK(ped)
                        for _, flag in ipairs({ 5, 13, 31, 50, 58 }) do PED.SET_PED_COMBAT_ATTRIBUTES(ped, flag, false) end
                        for _, flag in ipairs({ 17, 77 }) do PED.SET_PED_COMBAT_ATTRIBUTES(ped, flag, true) end
                        if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then TASK.TASK_LEAVE_ANY_VEHICLE(ped, 0, 4160) end
                        PED.SET_PED_KEEP_TASK(ped, true)
                        TASK.TASK_SMART_FLEE_PED(ped, player, 300, 10000, false, true)
                        tracked[ped] = true
                    end
                    script.yield(0)
                end
                script.yield(1000)
                if not valid() then return end
                for ped in pairs(tracked) do
                    if not ENTITY.DOES_ENTITY_EXIST(ped) or ENTITY.IS_ENTITY_DEAD(ped, false) then
                        tracked[ped] = nil
                    elseif not TASK.GET_IS_TASK_ACTIVE(ped, 218) then
                        TASK.TASK_SMART_FLEE_PED(ped, player, 300, -1, false, true)
                    else
                        tracked[ped] = nil
                    end
                end
            end
        end)
        self.busy, self.last_triggered = false, ctx.clock:elapsed_ms()
        if not ok then error(err) end
    end

    return action
end
