local app_scripts = require('includes.ssv2.data.app_scripts')
return function(ctx)
    local f = {
        id = 'ragdoll',
        category = 'self',
        requested = false,
        collision_handle = 0,
        next_collision = 0,
        next_speech = 0,
        controls = {
            { kind = 'toggle', path = 'features.self.rod',           label = 'SELF_ROD',           tooltip = 'SELF_ROD_TT' },
            { kind = 'toggle', path = 'features.self.clumsy',        label = 'SELF_CLUMSY',        tooltip = 'SELF_CLUMSY_TT' },
            { kind = 'toggle', path = 'features.self.ragdoll_sound', label = 'SELF_RAGDOLL_SOUND', tooltip = 'SELF_RAGDOLL_SOUND_TT' },
        }
    }
    ctx.input:bind('rod', function()
        if ctx.settings:get('features.self.rod') then f.requested = true end
    end)
    for _, entry in ipairs({ { 'rod', 'clumsy' }, { 'clumsy', 'rod' } }) do
        ctx.settings:on_change('features.self.' .. entry[1], function(enabled)
            if not enabled then return end
            ctx.settings:set('features.self.' .. entry[2], false)
            ctx.runtime:run('ragdoll enable', function()
                local state = ctx.state:read()
                if state and state.on_foot and not PED.CAN_PED_RAGDOLL(state.handle) then
                    ctx.notifier:warn("Samurai's Scripts", ctx.translator:text('SELF_RAGDOLL_BLOCK_INFO'))
                end
            end)
        end)
    end
    function f:enabled()
        return ctx.settings:get('features.self.rod') or ctx.settings:get('features.self.clumsy')
    end

    function f:disable()
        ctx.settings:set('features.self.rod', false)
        ctx.settings:set('features.self.clumsy', false)
    end

    function f:enter(state)
        if state.on_foot and not PED.IS_PED_RAGDOLL(state.handle) and not PED.CAN_PED_RAGDOLL(state.handle) then
            ctx.notifier:warn("Samurai's Scripts", ctx.translator:text('SELF_RAGDOLL_BLOCK_INFO'))
        end
    end

    function f:ready(state)
        return state.alive and (state.on_foot or state.bike)
            and not ctx.game.swimming(state.handle) and not HUD.IS_PAUSE_MENU_ACTIVE()
            and not NETWORK.NETWORK_IS_IN_MP_CUTSCENE()
    end

    function f:update(state)
        local now = ctx.clock:elapsed_ms()
        local ragdoll = PED.IS_PED_RAGDOLL(state.handle)
        if ctx.settings:get('features.self.clumsy') then
            if ragdoll and now > self.next_collision then self.next_collision = now + 3500 end
            if now > self.next_collision then
                PED.SET_PED_RAGDOLL_ON_COLLISION(state.handle, true)
                self.collision_handle = state.handle
            end
        else
            if self.collision_handle ~= 0 then
                PED.SET_PED_RAGDOLL_ON_COLLISION(self.collision_handle, false)
                self.collision_handle = 0
            end
            if self.requested or ctx.input:is_held('rod') then
                local browsing = false
                for _, name in ipairs(app_scripts) do
                    if scripts.is_active(name) then
                        browsing = true; break
                    end
                end
                if not browsing then
                    PED.SET_PED_TO_RAGDOLL(state.handle, 1500, 0, 0, false, false, false)
                end
            end
        end
        self.requested = false
        if ctx.settings:get('features.self.ragdoll_sound') and network.is_session_started()
            and ragdoll and now >= self.next_speech then
            local pos = state.ped:get_position()
            local voice = PED.IS_PED_MALE(state.handle) and 'WAVELOAD_PAIN_MALE' or 'WAVELOAD_PAIN_FEMALE'
            AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE('SCREAM_PANIC_SHORT', voice,
                pos.x, pos.y, pos.z, 'SPEECH_PARAMS_FORCE_SHOUTED')
            self.next_speech = now + 3000
        end
    end

    function f:cleanup()
        if self.collision_handle ~= 0 and ENTITY.DOES_ENTITY_EXIST(self.collision_handle) then
            PED.SET_PED_RAGDOLL_ON_COLLISION(self.collision_handle, false)
        end
        self.collision_handle, self.requested = 0, false
    end

    return f
end
