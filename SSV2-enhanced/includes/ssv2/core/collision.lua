local Memory = require('includes.ssv2.core.vehicle_memory')
local rigid = {}
for _, hash in ipairs({ 3008087081, 415536433, 874602658, 693843550, 4189527861, 1152297372, 3907562202, 2954040756, 1198649884, 1067874014 }) do rigid[hash] = true end
return function(vehicle)
    if not ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(vehicle) then return false, '' end
    local target = ENTITY._GET_LAST_ENTITY_HIT_BY_ENTITY(vehicle)
    if target == 0 or not ENTITY.DOES_ENTITY_EXIST(target) then return false, '' end
    if not ENTITY.IS_ENTITY_A_PED(target) and not ENTITY.IS_ENTITY_A_VEHICLE(target) and not ENTITY.IS_ENTITY_AN_OBJECT(target) then
        return
            true, "Samir, you're breaking the car!"
    end
    local kind = Memory.model_type(target)
    if kind == 0 then return false, '' end
    if kind == 6 then return false, 'Hit and run' end
    if kind == 5 then return true, "Samir, you're breaking the car!" end
    if kind == 1 or kind == 7 then
        local crashed = not ENTITY.DOES_ENTITY_HAVE_PHYSICS(target) or
            rigid[ENTITY.GET_ENTITY_MODEL(target) % 4294967296] == true
        return crashed, crashed and "Samir, you're breaking the car!" or 'Wrecking ball'
    end
    return false, ''
end
