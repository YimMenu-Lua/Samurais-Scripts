return function(ctx)
    local action = { last_trigger = -500, busy = false }
    function action:run()
        local now = ctx.clock:elapsed_ms()
        if self.busy or now - self.last_trigger < 500 then return end
        local state = ctx.state:read()
        if not state or not state.alive then return end
        self.busy = true
        local count = 0
        local ok, err = pcall(function()
            for _, ped in ipairs(entities.get_all_peds_as_handles()) do
                if not ctx.runtime.running then break end
                if ENTITY.DOES_ENTITY_EXIST(ped) and ctx.game.is_enemy(state.handle, ped) then
                    local vehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                    if vehicle ~= 0 then VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, -4000) end
                    PED.APPLY_DAMAGE_TO_PED(ped, 10000, true, 0, 0x7FD62962)
                    count = count + 1
                    script.yield(0)
                end
            end
        end)
        self.busy, self.last_trigger = false, ctx.clock:elapsed_ms()
        if not ok then error(err) end
        if not ctx.runtime.running then return end
        if count == 0 then
            ctx.notifier:error("Samurai's Scripts", ctx.translator:text('GENERIC_NOT_IN_COMBAT'))
        else
            ctx.notifier:success("Samurai's Scripts", ctx.translator:text('WRLD_KILL_ALL_NOTIF'))
        end
    end

    ctx.input:bind('kill_all_enemies', function() action:run() end)
    return action
end
