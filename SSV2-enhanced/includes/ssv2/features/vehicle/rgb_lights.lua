local Feature = require('includes.ssv2.core.feature')
return function(ctx)
    local f = Feature.new(ctx, {
        id = 'rgb_lights',
        category = 'vehicle',
        scope = 'vehicle',
        path = 'features.vehicle.rgb_lights.enabled',
        controls = {
            { kind = 'toggle', path = 'features.vehicle.rgb_lights.enabled', label = 'VEH_RGB_LIGHTS',   tooltip = 'VEH_RGB_LIGHTS_TT' },
            { kind = 'int',    path = 'features.vehicle.rgb_lights.speed',   label = 'RGB Lights Speed', min = 1,                      max = 5 },
        }
    })
    function f:ready(state)
        return state.land_vehicle
            and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(state.vehicle_handle)
            and not VEHICLE.GET_BOTH_VEHICLE_HEADLIGHTS_DAMAGED(state.vehicle_handle)
    end

    function f:enter(state)
        self.handle = state.vehicle_handle
        self.original_enabled = VEHICLE.IS_TOGGLE_MOD_ON(self.handle, 22)
        self.original_color = VEHICLE.GET_VEHICLE_XENON_LIGHT_COLOR_INDEX(self.handle)
        self.index, self.brightness, self.direction, self.next_update = 0, 1, -0.1, 0
    end

    function f:update()
        if not VEHICLE.IS_TOGGLE_MOD_ON(self.handle, 22) then
            VEHICLE.TOGGLE_VEHICLE_MOD(self.handle, 22, true)
        end
        local now = ctx.clock:elapsed_ms()
        if now < self.next_update then return end
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(self.handle, self.brightness)
        self.brightness = self.brightness + self.direction
        if self.brightness <= 0.1 or self.brightness >= 1 then
            self.index, self.direction = (self.index + 1) % 13, -self.direction
        end
        if self.brightness <= 0.05 then VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(self.handle, self.index) end
        local speed = math.max(1, math.min(5, ctx.settings:get('features.vehicle.rgb_lights.speed')))
        self.next_update = now + 100 / speed
    end

    function f:cleanup()
        if self.handle and ENTITY.DOES_ENTITY_EXIST(self.handle) then
            VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(self.handle, self.original_color)
            VEHICLE.TOGGLE_VEHICLE_MOD(self.handle, 22, self.original_enabled)
            VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(self.handle, 1)
        end
        self.handle = nil
    end

    return f
end
