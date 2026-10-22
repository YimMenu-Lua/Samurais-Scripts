local combat_true = { 5, 13, 21, 28, 31, 38, 42, 46, 58, 71 }
local config_flags = { 128, 140, 141, 208, 229, 294, 435 }
return function(ctx)
    local f = {
        id = 'public_enemy',
        category = 'world',
        switched = false,
        hostiles = {},
        next_scan = 0,
        next_task = 0,
        player = 0,
        count = 0
    }
    f.controls = { {
        kind = 'toggle',
        path = 'session.public_enemy',
        label = 'WRLD_PUBLIC_ENEMY',
        tooltip = 'WRLD_PUBLIC_ENEMY_TT',
        get = function() return f.switched end,
        set = function(value) f.switched = value end
    } }
    function f:enabled() return self.switched end

    function f:disable() self.switched = false end

    function f:ready(state)
        return state.alive and ctx.game.outside(state.handle) and not NETWORK.NETWORK_IS_ACTIVITY_SESSION()
    end

    function f:enter(state)
        self.player = state.player_id
        self.next_scan, self.next_task = ctx.clock:elapsed_ms() + 3000, ctx.clock:elapsed_ms() + 1000
    end

    function f:configure(ped, value)
        if not ENTITY.DOES_ENTITY_EXIST(ped) then return end
        for _, flag in ipairs(combat_true) do PED.SET_PED_COMBAT_ATTRIBUTES(ped, flag, value) end
        PED.SET_PED_COMBAT_ATTRIBUTES(ped, 17, not value)
        for _, flag in ipairs(config_flags) do
            local saved = self.hostiles[ped]
            if value then
                if saved[flag] == nil then saved[flag] = PED.GET_PED_CONFIG_FLAG(ped, flag, true) end
                PED.SET_PED_CONFIG_FLAG(ped, flag, true)
            else
                PED.SET_PED_CONFIG_FLAG(ped, flag, saved[flag])
            end
        end
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, value)
        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, value)
        if not value then TASK.CLEAR_PED_TASKS(ped) end
    end

    function f:cleanup()
        for ped in pairs(self.hostiles) do self:configure(ped, false) end
        self.hostiles, self.count = {}, 0
        if self.ignored_police then PLAYER.SET_POLICE_IGNORE_PLAYER(self.player, false) end
        self.ignored_police = false
    end

    function f:update(state)
        local now, group = ctx.clock:elapsed_ms(), PED.GET_PED_GROUP_INDEX(state.handle)
        if now >= self.next_scan and self.count < 50 then
            local generation = ctx.runtime.generation
            for _, ped in ipairs(entities.get_all_peds_as_handles()) do
                if self.count >= 50 then break end
                if ped ~= state.handle and ENTITY.DOES_ENTITY_EXIST(ped) and not ENTITY.IS_ENTITY_DEAD(ped, false)
                    and not PED.IS_PED_A_PLAYER(ped) and not PED.IS_PED_GROUP_MEMBER(ped, group)
                    and not ctx.owned_entities[ped] and not self.hostiles[ped] then
                    self.hostiles[ped] = {}; self.count = self.count + 1
                    self:configure(ped, true)
                end
                -- The original scan yields after every pool entry, including exclusions.
                script.yield(0)
                if not ctx.runtime.running or generation ~= ctx.runtime.generation or not self:enabled()
                    or PLAYER.PLAYER_PED_ID() ~= state.handle then
                    return
                end
            end
            now = ctx.clock:elapsed_ms()
            self.next_scan = now + 3000
        end
        if self.count == 0 then return end
        if not self.ignored_police then
            PLAYER.SET_POLICE_IGNORE_PLAYER(state.player_id, true); self.ignored_police = true
        end
        if now >= self.next_task then
            local position = state.ped:get_position()
            for ped in pairs(self.hostiles) do
                local alive = ENTITY.DOES_ENTITY_EXIST(ped) and not ENTITY.IS_ENTITY_DEAD(ped, true)
                local pos = alive and ENTITY.GET_ENTITY_COORDS(ped, true) or nil
                local distance = pos and math.sqrt((pos.x - position.x) ^ 2 + (pos.y - position.y) ^ 2 +
                    (pos.z - position.z) ^ 2) or math.huge
                if not alive or distance > 200 then
                    self:configure(ped, false); self.hostiles[ped] = nil; self.count = self.count - 1
                else
                    if WEAPON.IS_PED_ARMED(ped, 7) then WEAPON.SET_PED_DROPS_WEAPON(ped) end
                    if not PED.IS_PED_IN_COMBAT(ped, state.handle) then TASK.TASK_COMBAT_PED(ped, state.handle, 0, 16) end
                end
            end
            self.next_task = now + 1000
        end
        for ped in pairs(self.hostiles) do PED.SET_PED_RESET_FLAG(ped, 440, true) end
    end

    return f
end
