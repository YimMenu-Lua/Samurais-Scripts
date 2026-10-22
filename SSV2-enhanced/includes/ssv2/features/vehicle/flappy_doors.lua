local Feature = require('includes.ssv2.core.feature')
return function(ctx)
    local f = Feature.new(ctx, {
        id = 'flappy_doors',
        category = 'vehicle',
        scope = 'vehicle',
        path = 'features.vehicle.flappy_doors',
        open = false,
        next_update = 0,
        controls = { {
            kind = 'toggle',
            path = 'features.vehicle.flappy_doors',
            label = 'VEH_FLAPPY_DOORS',
            tooltip = 'VEH_FLAPPY_DOORS_TT'
        } }
    })
    function f:ready(state) return state.car end

    function f:enter() self.open, self.next_update = false, ctx.clock:elapsed_ms() + 600 end

    function f:update(state)
        local now = ctx.clock:elapsed_ms()
        if now >= self.next_update then self.open, self.next_update = not self.open, now + 600 end
        for door = 0, VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(state.vehicle_handle) + 1 do
            if VEHICLE.GET_IS_DOOR_VALID(state.vehicle_handle, door) then
                local angle = VEHICLE.GET_VEHICLE_DOOR_ANGLE_RATIO(state.vehicle_handle, door)
                if self.open and angle < 1 then
                    VEHICLE.SET_VEHICLE_DOOR_OPEN(state.vehicle_handle, door, false, false)
                elseif not self.open and angle > 0 then
                    VEHICLE.SET_VEHICLE_DOOR_SHUT(state.vehicle_handle, door, false)
                end
            end
        end
    end

    function f:cleanup()
        if self.identity and ENTITY.DOES_ENTITY_EXIST(self.identity) then
            for door = 0, VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(self.identity) + 1 do
                if VEHICLE.GET_IS_DOOR_VALID(self.identity, door) then
                    VEHICLE.SET_VEHICLE_DOOR_SHUT(self.identity, door,
                    true)
                end
            end
        end
        self.open, self.next_update = false, 0
    end

    return f
end
