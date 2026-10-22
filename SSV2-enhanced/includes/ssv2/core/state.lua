local State = {}
State.__index = State

function State.new() return setmetatable({ vehicle_control = {} }, State) end

function State:tracked_vehicle()
    local entry = self.vehicle_control
    if entry.handle and ENTITY.DOES_ENTITY_EXIST(entry.handle) and ENTITY.IS_ENTITY_A_VEHICLE(entry.handle)
        and memory.handle_to_ptr(entry.handle):get_address() == entry.pointer then
        return entry.handle
    end
end

function State:update_vehicle(runtime)
    local state = self:read(); if not state then return end
    if INTERIOR.GET_ROOM_KEY_FROM_ENTITY(state.handle) ~= 0 or CAMERA.IS_SCREEN_FADING_OUT() or CAMERA.IS_SCREEN_FADED_OUT() then return end
    local tracked = self:tracked_vehicle()
    if not tracked then self.vehicle_control = {} end
    if not state.driving or state.vehicle_handle == tracked or VEHICLE.IS_VEHICLE_BEING_BROUGHT_TO_HALT(state.vehicle_handle) then return end
    local generation = runtime.generation
    if tracked then
        self.vehicle_control = { pending = true }; script.yield(500)
        if not runtime.running or runtime.generation ~= generation then return end
        state = self:read(); if not state or not state.driving then
            self.vehicle_control = {}; return
        end
    end
    self.vehicle_control = {
        handle = state.vehicle_handle,
        pointer = memory.handle_to_ptr(state.vehicle_handle)
            :get_address()
    }
end

function State:vehicle_state(state)
    state = state or self:read()
    if not state then return end
    local current = state.vehicle_handle
    local handle = self:tracked_vehicle() or 0
    if state.driving and current ~= 0 and current ~= handle then handle = 0 end
    local vehicle = handle ~= 0 and Vehicle.new(handle) or nil
    local model = vehicle and vehicle:get_model() or 0
    state.native_vehicle_handle = current
    state.vehicle_handle, state.vehicle = handle, vehicle
    state.driving = state.driving and current == handle and handle ~= 0
    state.car = vehicle and VEHICLE.IS_THIS_MODEL_A_CAR(model) or false
    state.land_vehicle = vehicle and (state.car or VEHICLE.IS_THIS_MODEL_A_QUADBIKE(model)
        or VEHICLE.IS_THIS_MODEL_AN_AMPHIBIOUS_QUADBIKE(model) or VEHICLE.IS_THIS_MODEL_A_BIKE(model)) or false
    state.plane = vehicle and VEHICLE.IS_THIS_MODEL_A_PLANE(model) or false
    state.aircraft = vehicle and (state.plane or VEHICLE.IS_THIS_MODEL_A_HELI(model)) or false
    state.bike = vehicle and (VEHICLE.IS_THIS_MODEL_A_BIKE(model) or VEHICLE.IS_THIS_MODEL_A_BICYCLE(model)) or false
    return state
end

function State:read()
    if scripts.is_active('maintransition') or STREAMING.IS_PLAYER_SWITCH_IN_PROGRESS() then return nil end
    local handle = PLAYER.PLAYER_PED_ID()
    if handle == 0 or not ENTITY.DOES_ENTITY_EXIST(handle) then return nil end
    local ped = Ped.new(handle)
    local vehicle_handle = PED.GET_VEHICLE_PED_IS_IN(handle, false)
    if vehicle_handle ~= 0 and not ENTITY.DOES_ENTITY_EXIST(vehicle_handle) then vehicle_handle = 0 end
    local vehicle = vehicle_handle ~= 0 and Vehicle.new(vehicle_handle) or nil
    local model = vehicle and vehicle:get_model() or 0
    return {
        ped = ped,
        handle = handle,
        player_id = PLAYER.PLAYER_ID(),
        alive = not ped:is_dead(),
        on_foot = PED.IS_PED_ON_FOOT(handle),
        vehicle = vehicle,
        vehicle_handle = vehicle_handle,
        driving = vehicle and VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle_handle, -1, false) == handle or false,
        land_vehicle = vehicle and (VEHICLE.IS_THIS_MODEL_A_CAR(model)
            or VEHICLE.IS_THIS_MODEL_A_QUADBIKE(model)
            or VEHICLE.IS_THIS_MODEL_AN_AMPHIBIOUS_QUADBIKE(model)
            or VEHICLE.IS_THIS_MODEL_A_BIKE(model)) or false,
        car = vehicle and VEHICLE.IS_THIS_MODEL_A_CAR(model) or false,
        aircraft = vehicle and (VEHICLE.IS_THIS_MODEL_A_PLANE(model) or VEHICLE.IS_THIS_MODEL_A_HELI(model)) or false,
        plane = vehicle and VEHICLE.IS_THIS_MODEL_A_PLANE(model) or false,
        bike = vehicle and (VEHICLE.IS_THIS_MODEL_A_BIKE(model) or VEHICLE.IS_THIS_MODEL_A_BICYCLE(model)) or false
    }
end

return State
