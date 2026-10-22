local Feature = require('includes.ssv2.core.feature')
return function(ctx)
    local f = Feature.new(ctx, {
        id = 'high_beams',
        category = 'vehicle',
        scope = 'vehicle',
        path = 'features.vehicle.horn_beams',
        handle = 0,
        horn = false,
        controls = { {
            kind = 'toggle',
            path = 'features.vehicle.horn_beams',
            label = 'VEH_HIGH_BEAMS',
            tooltip = 'VEH_HIGH_BEAMS_TT'
        } }
    })
    function f:ready(state)
        return state.driving and state.land_vehicle
            and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(state.vehicle_handle)
            and not VEHICLE.GET_BOTH_VEHICLE_HEADLIGHTS_DAMAGED(state.vehicle_handle)
    end

    function f:enter(state) self.handle, self.horn = state.vehicle_handle, false end

    function f:update(state)
        local pressed = PAD.IS_CONTROL_PRESSED(0, 86)
        if pressed ~= self.horn then
            self.horn = pressed
            VEHICLE.SET_VEHICLE_FULLBEAM(self.handle, pressed)
            VEHICLE.SET_VEHICLE_LIGHTS(self.handle, pressed and 2 or 0)
        end
    end

    function f:cleanup()
        if self.horn and ENTITY.DOES_ENTITY_EXIST(self.handle) then
            VEHICLE.SET_VEHICLE_FULLBEAM(self.handle, false)
            VEHICLE.SET_VEHICLE_LIGHTS(self.handle, 0)
        end
        self.handle, self.horn = 0, false
    end

    return f
end
