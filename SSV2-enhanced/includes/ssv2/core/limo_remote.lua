local Appearance = require('includes.ssv2.core.appearance')
local Remote = {}
function Remote.take(manager, entry)
    local ctx = manager.ctx
    local state = ctx.state:read()
    assert(state and state.vehicle_handle == entry.vehicle.handle, 'Enter the limousine before taking remote control')
    if entry.remote then return end
    manager:cancel(entry)
    local player, handle = state.handle, entry.vehicle.handle
    local seat = 2
    for i = -1, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(handle) - 1 do
        if VEHICLE.GET_PED_IN_VEHICLE_SEAT(handle, i, false) == player then
            seat = i; break
        end
    end
    local saved = {
        pool = manager.service.pool,
        player = player,
        player_pointer = memory.handle_to_ptr(player):get_address(),
        seat = seat,
        ready = false,
        player_visible = state.ped:is_visible(),
        player_alpha = ENTITY.GET_ENTITY_ALPHA(player),
        vehicle_visible = entry.vehicle.entity:is_visible(),
        vehicle_alpha = ENTITY.GET_ENTITY_ALPHA(handle),
        speed = ENTITY.GET_ENTITY_SPEED(handle)
    }
    entry.remote = saved
    manager:operation(entry, 'limo_remote_take', function(valid)
        local ok, err = pcall(function()
            local pool = manager.service.pool
            local vehicle = pool:create('vehicle', entry.vehicle.model, Vector3.new(), 0, valid)
            if not vehicle then return end; saved.vehicle = vehicle
            local ped = pool:create('ped', ENTITY.GET_ENTITY_MODEL(player), Vector3.new(), 0, valid)
            if not ped then return end; saved.ped = ped
            if not Appearance.apply_vehicle(vehicle.handle, Appearance.vehicle(handle), valid) then return end
            ENTITY.SET_ENTITY_COLLISION(vehicle.handle, false, false); ENTITY.FREEZE_ENTITY_POSITION(vehicle.handle, true)
            ENTITY.FREEZE_ENTITY_POSITION(ped.handle, true); ENTITY.FREEZE_ENTITY_POSITION(handle, true)
            ENTITY.SET_ENTITY_INVINCIBLE(vehicle.handle, true); ENTITY.SET_ENTITY_INVINCIBLE(ped.handle, true)
            PED.SET_PED_CAN_BE_DRAGGED_OUT(ped.handle, false); PED.SET_PED_CAN_BE_TARGETTED(ped.handle, false)
            PED.CLONE_PED_TO_TARGET(player, ped.handle)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped.handle, true); TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(
                ped.handle, true)
            local pos = ENTITY.GET_ENTITY_COORDS(handle, false)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(vehicle.handle, pos.x, pos.y, pos.z, false, false, false)
            ENTITY.SET_ENTITY_HEADING(vehicle.handle, ENTITY.GET_ENTITY_HEADING(handle))
            TASK.TASK_WARP_PED_INTO_VEHICLE(player, vehicle.handle, -1)
            VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle.handle, true, true, false); VEHICLE.SET_VEHICLE_DOORS_LOCKED(
                vehicle.handle, 2)
            VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle.handle, VEHICLE.GET_VEHICLE_DIRT_LEVEL(handle))
            AUDIO.SET_VEH_RADIO_STATION(vehicle.handle, entry.radio)
            script.yield(10); if not valid() then return end
            ENTITY.FREEZE_ENTITY_POSITION(ped.handle, false); TASK.TASK_WARP_PED_INTO_VEHICLE(ped.handle, handle, seat)
            ENTITY.SET_ENTITY_VISIBLE(handle, false, false); ENTITY.SET_ENTITY_ALPHA(handle, 10, false)
            ENTITY.SET_ENTITY_VISIBLE(player, false, false); ENTITY.SET_ENTITY_ALPHA(player, 0, false)
            ENTITY.ATTACH_ENTITY_TO_ENTITY(handle, vehicle.handle, 0, 0, 0, 0, 0, 0, 0, false, true, false, false, 2,
                true, 1)
            ENTITY.FREEZE_ENTITY_POSITION(handle, false); ENTITY.FREEZE_ENTITY_POSITION(vehicle.handle, false)
            VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle.handle, saved.speed)
            ENTITY.SET_ENTITY_VISIBLE(entry.driver.handle, true, true); ENTITY.SET_ENTITY_ALPHA(entry.driver.handle, 255,
                false)
            saved.ready = true; entry.task = 'remote_control'
        end)
        if not ok or not saved.ready then Remote.release(manager, entry, true) end
        if not ok then error(err) end
    end)
end

function Remote.release(manager, entry, immediate)
    local saved = entry.remote
    if not saved or saved.releasing then return end
    saved.releasing = true; saved.ready = false
    local pool = saved.pool; local handle = entry.vehicle.handle
    if pool:exists(entry.vehicle) then
        ENTITY.DETACH_ENTITY(handle, false, false)
        ENTITY.SET_ENTITY_VISIBLE(handle, saved.vehicle_visible, true); ENTITY.SET_ENTITY_ALPHA(handle,
            saved.vehicle_alpha, false)
        ENTITY.FREEZE_ENTITY_POSITION(handle, false); ENTITY.SET_ENTITY_COLLISION(handle, true, true)
        if saved.vehicle and pool:exists(saved.vehicle) then
            local speed = ENTITY.GET_ENTITY_SPEED(saved.vehicle.handle)
            local pos = ENTITY.GET_ENTITY_COORDS(saved.vehicle.handle, false)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(handle, pos.x, pos.y, pos.z, false, false, false)
            ENTITY.SET_ENTITY_HEADING(handle, ENTITY.GET_ENTITY_HEADING(saved.vehicle.handle))
            VEHICLE.SET_VEHICLE_FORWARD_SPEED(handle, speed)
        end
    end
    if saved.ped then pool:delete(saved.ped.handle) end
    local player_exists = ENTITY.DOES_ENTITY_EXIST(saved.player) and
        memory.handle_to_ptr(saved.player):get_address() == saved.player_pointer
    if player_exists then
        ENTITY.SET_ENTITY_VISIBLE(saved.player, saved.player_visible, true); ENTITY.SET_ENTITY_ALPHA(saved.player,
            saved.player_alpha, false)
        if pool:exists(entry.vehicle) then TASK.TASK_WARP_PED_INTO_VEHICLE(saved.player, handle, saved.seat) end
    end
    if saved.vehicle then pool:delete(saved.vehicle.handle) end
    entry.remote = nil; entry.task = 'idle'
end

function Remote.update(manager, entry, state)
    local saved = entry.remote
    if not saved or not saved.ready then return end
    if not manager.service.pool:exists(saved.vehicle) or not manager.service.pool:exists(saved.ped)
        or state.vehicle_handle ~= saved.vehicle.handle then
        Remote.release(manager, entry, true)
        if state.vehicle_handle ~= entry.vehicle.handle and manager:exists(entry) then
            TASK.TASK_LEAVE_VEHICLE(
                state.handle, entry.vehicle.handle, 0)
        end
    end
end

return Remote
