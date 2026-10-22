local Memory = require('includes.ssv2.core.vehicle_memory')
local Wheels = {}
function Wheels.count(handle) return Memory.base(handle):add(0xC38):get_int() end

function Wheels.pointer(handle, index)
    local base = Memory.base(handle)
    local count = base:add(0xC38):get_int()
    assert(count > 0 and count <= 32 and index >= 1 and index <= count, 'Invalid wheel array/index')
    local array = base:add(0xC30):deref()
    assert(not array:is_null(), 'Wheel array is unavailable')
    local wheel = array:add((index - 1) * 8):deref()
    assert(not wheel:is_null(), 'Wheel pointer is unavailable')
    return wheel
end

function Wheels.draw(handle)
    local draw = Memory.base(handle):add(0x48):deref()
    if draw:is_null() then return nil end
    -- Enhanced 1158.16 moves the wheel draw-data pointer from Legacy's +0x370.
    local wheel = draw:add(0x4B0):deref()
    return not wheel:is_null() and wheel or nil
end

function Wheels.ride_height(handle)
    local array = Memory.base(handle):add(0xC30):deref()
    assert(not array:is_null(), 'Wheel array is unavailable')
    return array:add(0x7C)
end

return Wheels
