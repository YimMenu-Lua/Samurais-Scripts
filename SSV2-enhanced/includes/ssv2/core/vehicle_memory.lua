-- Field locations from the original CEntity/CVehicleModelInfo views.
-- Resolve game-owned pointers for each read; never retain them across a yield.
local VehicleMemory = {}
local floats = {
    steering = 0x9DC,
    throttle = 0x8D8,
    throttle_input = 0x8E0,
    rpm = 0x8C8,
    rpm_secondary = 0x8CC,
    clutch = 0x8D4,
    drive_max_velocity = 0x8C0
}
local bytes = { top_gear = 0x886 }
function VehicleMemory.base(handle)
    assert(ENTITY.DOES_ENTITY_EXIST(handle), 'Vehicle no longer exists')
    local base = memory.handle_to_ptr(handle)
    assert(not base:is_null(), 'Vehicle pointer is unavailable')
    return base
end

function VehicleMemory.identity(handle) return VehicleMemory.base(handle):get_address() end

-- Enhanced's current-gear native sign-extends the 16-bit field at +0x880.
function VehicleMemory.get_current_gear(handle)
    local value = VehicleMemory.base(handle):add(0x880):get_word()
    return value >= 0x8000 and value - 0x10000 or value
end

function VehicleMemory.set_current_gear(handle, value)
    assert(value >= -0x8000 and value <= 0x7FFF and value == math.floor(value), 'Expected a signed transmission word')
    VehicleMemory.base(handle):add(0x880):set_word(value % 0x10000)
end

-- The game's transmission update copies the complete current word into +0x882.
function VehicleMemory.get_previous_gear(handle)
    local value = VehicleMemory.base(handle):add(0x882):get_word()
    return value >= 0x8000 and value - 0x10000 or value
end

function VehicleMemory.set_previous_gear(handle, value)
    assert(value >= -0x8000 and value <= 0x7FFF and value == math.floor(value), 'Expected a signed transmission word')
    VehicleMemory.base(handle):add(0x882):set_word(value % 0x10000)
end

function VehicleMemory.get_byte(handle, field)
    return VehicleMemory.base(handle):add(assert(bytes[field], 'Unknown transmission field')):get_byte()
end

function VehicleMemory.set_byte(handle, field, value)
    assert(value >= 0 and value <= 255 and value == math.floor(value), 'Expected a transmission byte')
    VehicleMemory.base(handle):add(assert(bytes[field], 'Unknown transmission field')):set_byte(value)
end

function VehicleMemory.gear_max_speed(handle, gear)
    assert(gear >= 0 and gear <= 10 and gear == math.floor(gear), 'Invalid gear index')
    local base = VehicleMemory.base(handle)
    -- Drivetrain simulation indexes the current gear from transmission +0xC.
    local ratio = math.abs(base:add(0x88C + gear * 4):get_float())
    return ratio == 0 and 0 or base:add(0x8C0):get_float() / ratio
end

function VehicleMemory.subhandling(handle)
    local handling = VehicleMemory.base(handle):add(0x960):deref()
    assert(not handling:is_null(), 'Vehicle handling data is unavailable')
    local array = handling:add(0x158)
    assert(array:add(8):get_word() > 0, 'Vehicle has no subhandling data')
    local data = array:deref(); assert(not data:is_null(), 'Subhandling array is unavailable')
    local sub = data:deref(); assert(not sub:is_null(), 'Subhandling data is unavailable')
    return sub
end

function VehicleMemory.float_lease(handle, resolve, value)
    local field = resolve(handle)
    local lease = {
        handle = handle,
        base = VehicleMemory.identity(handle),
        address = field:get_address(),
        original =
            field:get_float()
    }
    function lease:restore()
        if ENTITY.DOES_ENTITY_EXIST(self.handle) and VehicleMemory.identity(self.handle) == self.base then
            local current = resolve(self.handle)
            if current:get_address() == self.address then current:set_float(self.original) end
        end
    end

    field:set_float(value); return lease
end

function VehicleMemory.flag_pointer(handle, category, index)
    local base = VehicleMemory.base(handle)
    if category == 'model_info' then
        local model = base:add(0x20):deref()
        assert(not model:is_null(), 'Vehicle model info is unavailable')
        return model:add(0x57C + math.floor(index / 32) * 4)
    end
    local handling = base:add(0x960):deref()
    assert(not handling:is_null(), 'Vehicle handling data is unavailable')
    if category == 'advanced' then
        local model = base:add(0x20):deref()
        assert(not model:is_null(), 'Vehicle model info is unavailable')
        if model:add(0x340):get_dword() ~= 0 then return nil end -- CCarHandlingData only
        local array = handling:add(0x158)
        assert(array:add(8):get_word() > 0, 'Vehicle has no subhandling data')
        local data = array:deref()
        assert(not data:is_null(), 'Subhandling array is unavailable')
        local sub = data:deref()
        assert(not sub:is_null(), 'Car subhandling data is unavailable')
        return sub:add(0x3C)
    end
    return handling:add(assert(({ handling = 0x128, model = 0x124 })[category], 'Unknown flag category'))
end

function VehicleMemory.get_float(handle, field)
    return VehicleMemory.base(handle):add(assert(floats[field], 'Unknown vehicle field')):get_float()
end

function VehicleMemory.set_float(handle, field, value)
    assert(type(value) == 'number' and value == value and math.abs(value) < math.huge, 'Expected a finite vehicle value')
    VehicleMemory.base(handle):add(assert(floats[field], 'Unknown vehicle field')):set_float(value)
end

function VehicleMemory.handling_flag(handle, index)
    local handling = VehicleMemory.base(handle):add(0x960):deref()
    assert(not handling:is_null(), 'Vehicle handling data is unavailable')
    return bit.band(handling:add(0x128):get_dword(), bit.lshift(1, index)) ~= 0
end

function VehicleMemory.model_type(handle)
    local model = VehicleMemory.base(handle):add(0x20):deref()
    assert(not model:is_null(), 'Entity model info is unavailable')
    return model:add(0x9D):get_byte()
end

function VehicleMemory.handling_model_flag(handle, index)
    local handling = VehicleMemory.base(handle):add(0x960):deref()
    assert(not handling:is_null(), 'Vehicle handling data is unavailable')
    return bit.band(handling:add(0x124):get_dword(), bit.lshift(1, index)) ~= 0
end

function VehicleMemory.deformation_lease(handle, value)
    local base = VehicleMemory.base(handle)
    local handling = base:add(0x960):deref()
    assert(not handling:is_null(), 'Vehicle handling data is unavailable')
    local field = handling:add(0xF8)
    local lease = {
        handle = handle,
        base = base:get_address(),
        address = field:get_address(),
        original = field
            :get_float()
    }
    function lease:restore()
        if not ENTITY.DOES_ENTITY_EXIST(self.handle) then return end
        local current = VehicleMemory.base(self.handle)
        if current:get_address() ~= self.base then return end
        local current_handling = current:add(0x960):deref()
        if current_handling:is_null() then return end
        local current_field = current_handling:add(0xF8)
        if current_field:get_address() == self.address then current_field:set_float(self.original) end
    end

    field:set_float(value)
    return lease
end

function VehicleMemory.model_flag(handle, index)
    local base = VehicleMemory.base(handle)
    local model = base:add(0x20):deref()
    assert(not model:is_null(), 'Vehicle model info is unavailable')
    local word = model:add(0x57C + math.floor(index / 32) * 4):get_dword()
    return bit.band(word, bit.lshift(1, index % 32)) ~= 0
end

return VehicleMemory
