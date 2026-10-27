local Feature = require('includes.ssv2.core.feature')
local Geometry = require('includes.ssv2.core.geometry')
return function(ctx)
    local f = Feature.new(ctx, {
        id = 'cobra_maneuver',
        category = 'vehicle',
        scope = 'vehicle',
        path = 'features.vehicle.cobra_maneuver',
        requested = false,
        controls = { { kind = 'toggle', path = 'features.vehicle.cobra_maneuver', label = 'VEH_COBRA_MANEUVER', tooltip = 'VEH_COBRA_MANEUVER_TT' } }
    })
    ctx.input:bind('cobra_maneuver', function() if f:enabled() then f.requested = true end end)
    ctx.input:bind('cobra_cancel', function()
        if f.phase then
            f:cleanup()
            ctx.notifier:warn("Samurai's Scripts", ctx.translator:text('VEH_COBRA_MANEUVER_INTERRUPT'))
        end
    end, false, true)
    function f:ready(state) return state.alive and state.driving and state.plane end

    function f:cleanup() self.phase, self.requested, self.step = nil, false, 0 end

    function f:begin(state, now)
        local error_key
        if ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(state.vehicle_handle) < 500 then
            error_key = 'VEH_COBRA_MANEUVER_TOO_lOW'
        elseif ENTITY.GET_ENTITY_SPEED(state.vehicle_handle) < 50 then
            error_key = 'VEH_COBRA_MANEUVER_TOO_SlOW'
        end
        if error_key then
            ctx.notifier:error("Samurai's Scripts", ctx.translator:text(error_key)); return
        end
        local rotation = ENTITY.GET_ENTITY_ROTATION(state.vehicle_handle, 2)
        if rotation.x <= -6 or rotation.y <= -20 or rotation.y >= 20 then
            ctx.notifier:error("Samurai's Scripts", ctx.translator:text('VEH_COBRA_MANEUVER_NOT_LEVEL')); return
        end
        self.start_rotation = rotation
        self.target_rotation = Vector3.new(rotation.x > 10 and math.min(rotation.x + 50, 85) or 85, rotation.y,
            rotation.z)
        self.step, self.phase, self.next_step = 0, 'pull_up', now
        ctx.notifier:warn("Samurai's Scripts", ctx.translator:text('VEH_COBRA_MANEUVER_CANCEL'))
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 51, 1)
    end

    function f:update(state)
        local now, handle = ctx.clock:elapsed_ms(), state.vehicle_handle
        if self.requested then
            self.requested = false
            if not self.phase then self:begin(state, now) end
        end
        if not self.phase or now < self.next_step then return end
        if self.phase == 'pull_up' then
            self.step = self.step + 1
            -- Retain the original interpolation and impulse timing.
            local rotation = Geometry.lerp(self.start_rotation, self.target_rotation, self.step / 500 * 5)
            if ctx.settings:get('features.vehicle.flares') then PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 88, 1) end
            ENTITY.SET_ENTITY_ROTATION(handle, rotation.x, rotation.y, rotation.z, 2, true)
            local velocity = ENTITY.GET_ENTITY_VELOCITY(handle)
            if self.step == 10 then
                ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(handle, 1, -velocity.x * 1.5, -velocity.y * 1.5, 0, true,
                    true, true, true)
                ENTITY.SET_ENTITY_VELOCITY(handle, velocity.x * 0.2, velocity.y * 0.2, velocity.z * 0.2)
            end
            if rotation.x >= self.target_rotation.x - 0.1 and velocity.y <= 10 then
                self.phase, self.step, self.next_step = 'recover', 0, now + 500
            elseif self.step >= 500 then
                self.phase, self.step, self.next_step = 'recover', 0, now
            else
                self.next_step = now + 10
            end
        elseif self.phase == 'recover' then
            PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 87, 1)
            PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 110, -1)
            self.step = self.step + 1
            if self.step >= 100 then self.phase = nil end
        end
    end

    return f
end
