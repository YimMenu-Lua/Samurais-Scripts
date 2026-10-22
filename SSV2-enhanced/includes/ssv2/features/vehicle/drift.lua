local Feature = require('includes.ssv2.core.feature')
return function(ctx)
    local root = 'features.vehicle.drift'
    local f = Feature.new(ctx, {
        id = 'drift',
        category = 'vehicle',
        scope = 'vehicle',
        path = root .. '.enabled',
        sliding = false,
        controls = {
            { kind = 'toggle', path = root .. '.enabled',          label = 'VEH_DRIFT_MODE' },
            { kind = 'combo',  path = root .. '.mode',             label = 'VEH_DRIFT_MODE',           options = { 'VEH_DRIFT_MODE_STRONG', 'VEH_DRIFT_MODE_SLIPPERY', 'VEH_DRIFT_MODE_MIXED' } },
            { kind = 'int',    path = root .. '.power',            label = 'VEH_POWER_GAIN',           min = 10,                                                                                max = 100 },
            { kind = 'int',    path = root .. '.intensity',        label = 'VEH_DRIFT_MODE_INTENSITY', tooltip = 'VEH_DRIFT_MODE_INTENSITY_TT',                                                 min = 0,  max = 3 },
            { kind = 'toggle', path = root .. '.smoke_fx.enabled', label = 'VEH_DRIFT_SMOKE',          tooltip = 'VEH_DRIFT_SMOKE_TT' },
            { kind = 'color3', path = root .. '.smoke_fx.color',   label = 'VEH_DRIFT_SMOKE_COL' },
        }
    })
    ctx.input:bind_held('drift_mode')
    f.controls[4].disabled = function() return ctx.settings:get(root .. '.mode') == 1 end
    f.controls[6].visible = function() return ctx.settings:get(root .. '.smoke_fx.enabled') end
    function f:ready(state)
        return state.alive and state.driving and state.land_vehicle and
            VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(state.vehicle_handle)
    end

    function f:enter(state)
        local ptr = memory.allocate(12)
        local ok, err = pcall(function()
            VEHICLE.GET_VEHICLE_TYRE_SMOKE_COLOR(state.vehicle_handle, ptr, ptr:add(4), ptr:add(8))
            self.smoke_color = { ptr:get_int(), ptr:add(4):get_int(), ptr:add(8):get_int() }
            self.smoke_enabled = VEHICLE.IS_TOGGLE_MOD_ON(state.vehicle_handle, 20)
        end)
        memory.free(ptr)
        if not ok then error(err) end
    end

    function f:release_slide()
        if self.sliding and ENTITY.DOES_ENTITY_EXIST(self.identity) then
            VEHICLE.SET_VEHICLE_REDUCE_GRIP(self.identity, false)
            VEHICLE.SET_DRIFT_TYRES(self.identity, false)
            VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(self.identity, 1)
        end
        self.sliding = false
    end

    function f:stop_smoke()
        ctx.particles:stop(self.smoke); self.smoke = nil
        if self.smoke_owned and ENTITY.DOES_ENTITY_EXIST(self.identity) then
            local color = self.smoke_color
            VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(self.identity, color[1], color[2], color[3])
            VEHICLE.TOGGLE_VEHICLE_MOD(self.identity, 20, self.smoke_enabled)
        end
        self.smoke_owned = false
    end

    function f:cleanup()
        self:release_slide(); self:stop_smoke()
    end

    function f:update(state)
        local mode = ctx.settings:get(root .. '.mode')
        if self.sliding and mode ~= self.mode then self:release_slide() end
        if ctx.input:is_held('drift_mode') then
            if not self.sliding then
                if mode == 0 or mode == 2 then
                    VEHICLE.SET_VEHICLE_REDUCE_GRIP(state.vehicle_handle, true)
                    VEHICLE.SET_VEHICLE_REDUCE_GRIP_LEVEL(state.vehicle_handle, ctx.settings:get(root .. '.intensity'))
                end
                if mode >= 1 then VEHICLE.SET_DRIFT_TYRES(state.vehicle_handle, true) end
            end
            VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(state.vehicle_handle, ctx.settings:get(root .. '.power'))
            self.sliding, self.mode = true, mode
        else
            self:release_slide()
        end
        if not state.car or not ctx.settings:get(root .. '.smoke_fx.enabled') then
            self:stop_smoke(); return
        end
        local velocity = ENTITY.GET_ENTITY_SPEED_VECTOR(state.vehicle_handle, true)
        local speed = ENTITY.GET_ENTITY_SPEED(state.vehicle_handle)
        local drifting = speed > 5 and math.abs(velocity.x) >= 6 and state.vehicle:get_gear() > 0
            and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(state.vehicle_handle)
        local burnout = speed <= 0.1 and state.vehicle:get_rev_ratio() >= 0.9 and
            VEHICLE.IS_VEHICLE_IN_BURNOUT(state.vehicle_handle)
        if not drifting and not burnout then
            self:stop_smoke(); return
        end
        if not self.smoke then
            local minimum, maximum = ctx.game.model_dimensions(state.vehicle:get_model())
            self.smoke = ctx.particles:start(state.vehicle_handle, 'scr_ba_bb', 'scr_ba_bb_plane_smoke_trail',
                { 'suspension_lr', 'suspension_rr' }, drifting and speed / 111 or 0.4,
                Vector3.new(1.2, 0, -(maximum.z - minimum.z) / 4), Vector3.new())
            if self.smoke then
                VEHICLE.TOGGLE_VEHICLE_MOD(state.vehicle_handle, 20, true); self.smoke_owned = true
            end
        end
        if self.smoke then
            local color = ctx.settings:get(root .. '.smoke_fx.color')
            for _, handle in ipairs(self.smoke.handles) do
                GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(handle, color[1],
                color[2], color[3], false)
            end
        end
    end

    return f
end
