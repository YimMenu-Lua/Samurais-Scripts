local Feature = require('includes.ssv2.core.feature')
local Memory = require('includes.ssv2.core.vehicle_memory')
return function(ctx)
    local f = Feature.new(ctx,
        {
            id = 'abs_lights',
            category = 'vehicle',
            scope = 'vehicle',
            path = 'features.vehicle.abs_lights',
            off = false,
            next_switch = 0,
            controls = { { kind = 'toggle', path = 'features.vehicle.abs_lights', label = 'VEH_ABS_LIGHTS', tooltip = 'VEH_ABS_LIGHTS_TT' } }
        })
    function f:ready(state)
        if not state.car or not Memory.handling_model_flag(state.vehicle_handle, 4) then return false end
        if ctx.settings:get('features.vehicle.performance_only') then
            local class = VEHICLE.GET_VEHICLE_CLASS(state.vehicle_handle)
            return class == 6 or class == 7
        end
        return true
    end

    function f:cleanup()
        if self.off and self.identity and ENTITY.DOES_ENTITY_EXIST(self.identity) then
            VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(
            self.identity, true)
        end
        self.off, self.next_switch = false, 0
    end

    function f:update(state)
        local now = ctx.clock:elapsed_ms()
        if now >= self.next_switch then
            if VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(state.vehicle_handle) and PAD.IS_CONTROL_PRESSED(0, 72)
                and ENTITY.GET_ENTITY_SPEED(state.vehicle_handle) >= 19.44 and state.vehicle:get_gear() > 0 then
                self.off = not self.off
            else
                self.off = false
            end
            self.next_switch = now + 100
        end
        if self.off then VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(state.vehicle_handle, false) end
    end

    return f
end
