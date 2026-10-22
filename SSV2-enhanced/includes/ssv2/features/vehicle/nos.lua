local Memory = require('includes.ssv2.core.vehicle_memory')
return function(ctx)
    local root = 'features.vehicle.nos'
    local f = { id = 'nos', category = 'vehicle', scope = 'vehicle', boosting = false, danger = 0, controls = {} }
    local function cfg(key) return ctx.settings:get(root .. '.' .. key) end
    for _, option in ipairs({ { 'enabled', 'VEH_NOS' }, { 'purge', 'VEH_NOS_PURGE' }, { 'screen_effect', 'VEH_NOS_SCREEN_FX' },
        { 'sound_effect', 'VEH_NOS_SOUND_FX' }, { 'can_damage_engine', 'VEH_NOS_DAMAGE_CB' } }) do
        f.controls[#f.controls + 1] = {
            kind = 'toggle',
            path = root .. '.' .. option[1],
            label = option[2],
            tooltip =
                option[1] == 'can_damage_engine' and 'VEH_NOS_DAMAGE_TT' or nil
        }
    end
    f.controls[#f.controls + 1] = { kind = 'int', path = root .. '.power', label = 'VEH_POWER_GAIN', min = 10, max = 100 }
    -- Held actions use the same editor as edge-triggered actions.
    ctx.input:bind_held('nos')
    ctx.input:bind_held('nos_purge')
    function f:enabled() return cfg('enabled') or cfg('purge') end

    function f:disable()
        ctx.settings:set(root .. '.enabled', false); ctx.settings:set(root .. '.purge', false)
    end

    function f:ready(state)
        return state.alive and state.driving and state.land_vehicle and not Memory.model_flag(state.vehicle_handle, 43)
    end

    function f:stop_boost()
        if self.boosting and self.identity and ENTITY.DOES_ENTITY_EXIST(self.identity) then
            VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(self.identity, 1)
            VEHICLE.MODIFY_VEHICLE_TOP_SPEED(self.identity, -1)
            AUDIO.SET_VEHICLE_BOOST_ACTIVE(self.identity, false)
            if cfg('screen_effect') then GRAPHICS.ANIMPOSTFX_PLAY('DragRaceNitrousOut', 0, false) end
        end
        if self.boosting or self.screen_active then
            GRAPHICS.ANIMPOSTFX_STOP('DragRaceNitrous'); GRAPHICS.ANIMPOSTFX_STOP('DragRaceNitrousOut')
        end
        self.boosting, self.screen_active, self.danger = false, false, 0
        ctx.particles:stop(self.nos_fx); self.nos_fx = nil
    end

    function f:cleanup()
        self:stop_boost()
        ctx.particles:stop(self.purge_left); ctx.particles:stop(self.purge_right)
        self.purge_left, self.purge_right = nil, nil
    end

    function f:update(state)
        local handle = state.vehicle_handle
        local engine_on = VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(handle)
        local health = VEHICLE.GET_VEHICLE_ENGINE_HEALTH(handle)
        local held = cfg('enabled') and ctx.input:is_held('nos') and health > 300
        if not self.boosting then self.max_speed = VEHICLE.GET_VEHICLE_ESTIMATED_MAX_SPEED(handle) end
        if held and engine_on and PAD.IS_CONTROL_PRESSED(0, 71) and health > 50 then
            local power = cfg('power')
            VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(handle, math.max(1, math.min(5, power / 10)))
            VEHICLE.MODIFY_VEHICLE_TOP_SPEED(handle, power)
            AUDIO.SET_VEHICLE_BOOST_ACTIVE(handle, cfg('sound_effect'))
            if cfg('screen_effect') then
                GRAPHICS.ANIMPOSTFX_PLAY('DragRaceNitrous', 0, false); self.screen_active = true
            end
            self.boosting = true
        elseif self.boosting and (not held or not engine_on) then
            self:stop_boost()
        end
        if self.boosting and engine_on then
            if not self.nos_fx then
                local bones = {}
                for _, name in ipairs(require('includes.ssv2.data.plane_bones')) do
                    if name:match('^exhaust') then bones[#bones + 1] = name end
                end
                self.nos_fx = ctx.particles:start(handle, 'veh_xs_vehicle_mods', 'veh_nitrous', bones, 1, Vector3.new(),
                    Vector3.new())
            end
            if cfg('can_damage_engine') and health > 50 then
                local threshold = self.max_speed * 1.7
                self.danger = threshold > 0 and math.max(0, math.min(1, ENTITY.GET_ENTITY_SPEED(handle) / threshold)) or
                    0
                if threshold > 0 and ENTITY.GET_ENTITY_SPEED(handle) >= threshold then
                    VEHICLE.SET_VEHICLE_ENGINE_HEALTH(handle, 50)
                    AUDIO.PLAY_SOUND_FROM_ENTITY(-1, 'DRILL_PIN_BREAK', handle, 'DLC_HEIST_FLEECA_SOUNDSET', true, 0)
                end
            else
                self.danger = 0
            end
        end
        if self.screen_active and not cfg('screen_effect') then
            GRAPHICS.ANIMPOSTFX_STOP('DragRaceNitrous'); self.screen_active = false
        end
        if cfg('purge') and engine_on and health > 300 and ctx.input:is_held('nos_purge') then
            if not self.purge_left then
                self.purge_left = ctx.particles:start(handle, 'core', 'weap_extinguisher', 'suspension_lf', 0.35,
                    Vector3.new(-0.3, -0.33, 0.2), Vector3.new(0, -17.5, -180))
            end
            if not self.purge_right then
                self.purge_right = ctx.particles:start(handle, 'core', 'weap_extinguisher', 'suspension_rf', 0.35,
                    Vector3.new(0, -0.33, 0.2), Vector3.new(0, -17.5, 0))
            end
        else
            ctx.particles:stop(self.purge_left); ctx.particles:stop(self.purge_right)
            self.purge_left, self.purge_right = nil, nil
        end
    end

    return f
end
