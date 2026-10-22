-- Persist game appearance values using scalar output pointers from the V2 API.
local Appearance = {}
local function outputs(count, callback)
    local buffer = memory.allocate(count * 4)
    assert(buffer and buffer:get_address() ~= 0, 'Cannot allocate appearance outputs')
    local pointers = {}; for i = 1, count do
        pointers[i] = buffer:add((i - 1) * 4); pointers[i]:set_int(0)
    end
    local ok, err = pcall(callback, unpack(pointers))
    local values = {}; if ok then for i, pointer in ipairs(pointers) do values[i] = pointer:get_int() end end
    memory.free(buffer); if not ok then error(err) end
    return unpack(values)
end
local function color(handle, getter)
    local r, g, b = outputs(3, function(a, c, d) getter(handle, a, c, d) end)
    return { r = r, g = g, b = b }
end
function Appearance.ped(handle)
    local components = {}
    for index = 0, 11 do
        local drawable = PED.GET_PED_DRAWABLE_VARIATION(handle, index)
        components[index + 1] = {
            component = index,
            drawable = drawable,
            texture = PED.GET_PED_TEXTURE_VARIATION(handle, index),
            palette = PED.GET_PED_PALETTE_VARIATION(handle, index),
            max_drawables = PED.GET_NUMBER_OF_PED_DRAWABLE_VARIATIONS(handle, index),
            max_textures = PED.GET_NUMBER_OF_PED_TEXTURE_VARIATIONS(handle, index, drawable)
        }
    end
    return components
end

function Appearance.apply_ped(handle, components)
    for _, item in ipairs(components or {}) do
        if PED.IS_PED_COMPONENT_VARIATION_VALID(handle, item.component, item.drawable, item.texture) then
            PED.SET_PED_COMPONENT_VARIATION(handle, item.component, item.drawable, item.texture, item.palette or 0)
        end
    end
end

function Appearance.vehicle(handle)
    local result = { mods = {}, toggle_mods = {}, window_states = {}, neon = { enabled = {} } }
    for i = 0, 49 do result.mods[i + 1] = VEHICLE.GET_VEHICLE_MOD(handle, i) end
    for i = 17, 22 do result.toggle_mods[tostring(i)] = VEHICLE.IS_TOGGLE_MOD_ON(handle, i) end
    for i = 0, 3 do
        result.window_states[i + 1] = VEHICLE.IS_VEHICLE_WINDOW_INTACT(handle, i); result.neon.enabled[i + 1] = VEHICLE
            .GET_VEHICLE_NEON_ENABLED(handle, i)
    end
    result.primary_color = color(handle,
        VEHICLE.GET_IS_VEHICLE_PRIMARY_COLOUR_CUSTOM(handle) and VEHICLE.GET_VEHICLE_CUSTOM_PRIMARY_COLOUR or
        VEHICLE.GET_VEHICLE_COLOR)
    result.secondary_color = color(handle,
        VEHICLE.GET_IS_VEHICLE_SECONDARY_COLOUR_CUSTOM(handle) and VEHICLE.GET_VEHICLE_CUSTOM_SECONDARY_COLOUR or
        VEHICLE.GET_VEHICLE_COLOR)
    result.wheels = {
        type = VEHICLE.GET_VEHICLE_WHEEL_TYPE(handle),
        index = VEHICLE.GET_VEHICLE_MOD(handle, 23),
        var =
            VEHICLE.GET_VEHICLE_MOD_VARIATION(handle, 23)
    }
    result.window_tint = VEHICLE.GET_VEHICLE_WINDOW_TINT(handle); result.plate_text = VEHICLE
        .GET_VEHICLE_NUMBER_PLATE_TEXT(handle)
    result.neon.color = color(handle, VEHICLE.GET_VEHICLE_NEON_COLOUR)
    if result.toggle_mods['20'] then result.tyre_smoke_color = color(handle, VEHICLE.GET_VEHICLE_TYRE_SMOKE_COLOR) end
    if result.toggle_mods['22'] then result.xenon_color = VEHICLE.GET_VEHICLE_XENON_LIGHT_COLOR_INDEX(handle) end
    if VEHICLE.GET_VEHICLE_LIVERY_COUNT(handle) > 0 then result.livery = VEHICLE.GET_VEHICLE_LIVERY(handle) end
    if VEHICLE.GET_VEHICLE_LIVERY2_COUNT(handle) > 0 then result.livery2 = VEHICLE.GET_VEHICLE_LIVERY2(handle) end
    result.pearlescent_color, result.wheel_color = outputs(2,
        function(a, b) VEHICLE.GET_VEHICLE_EXTRA_COLOURS(handle, a, b) end)
    result.interior_color = outputs(1, function(a) VEHICLE.GET_VEHICLE_EXTRA_COLOUR_5(handle, a) end)
    result.dashboard_color = outputs(1, function(a) VEHICLE.GET_VEHICLE_EXTRA_COLOUR_6(handle, a) end)
    return result
end

function Appearance.apply_vehicle(handle, value, valid)
    VEHICLE.SET_VEHICLE_MOD_KIT(handle, 0)
    local function apply_color(key, setter)
        local col = value[key]; if col then setter(handle, col.r, col.g, col.b) end
    end
    for index, mod in ipairs(value.mods or {}) do
        if not valid() then return false end
        if mod ~= -1 then
            VEHICLE.PRELOAD_VEHICLE_MOD(handle, index - 1, mod)
            while not VEHICLE.HAS_PRELOAD_MODS_FINISHED(handle) do
                script.yield(0); if not valid() then return false end
            end
            VEHICLE.SET_VEHICLE_MOD(handle, index - 1, mod, true)
        end
    end
    VEHICLE.RELEASE_PRELOAD_MODS(handle)
    apply_color('primary_color', VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR)
    apply_color('secondary_color', VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR)
    apply_color('tyre_smoke_color', VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR)
    if value.window_tint ~= nil then VEHICLE.SET_VEHICLE_WINDOW_TINT(handle, value.window_tint) end
    if value.plate_text and #value.plate_text > 0 then VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(handle, value.plate_text) end
    for i = 17, 22 do
        local enabled = value.toggle_mods and value.toggle_mods[tostring(i)]
        if enabled == nil and value.toggle_mods then enabled = value.toggle_mods[i] end
        if enabled ~= nil then VEHICLE.TOGGLE_VEHICLE_MOD(handle, i, enabled) end
    end
    if value.xenon_color ~= nil then VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(handle, value.xenon_color) end
    for i, closed in ipairs(value.window_states or {}) do
        (closed and VEHICLE.ROLL_UP_WINDOW or VEHICLE.ROLL_DOWN_WINDOW)(
                handle, i - 1)
    end
    if value.livery ~= nil then VEHICLE.SET_VEHICLE_LIVERY(handle, value.livery) end
    if value.livery2 ~= nil then VEHICLE.SET_VEHICLE_LIVERY2(handle, value.livery2) end
    if value.wheels then
        if value.wheels.type ~= nil then VEHICLE.SET_VEHICLE_WHEEL_TYPE(handle, value.wheels.type) end
        if value.wheels.index ~= nil then
            VEHICLE.SET_VEHICLE_MOD(handle, 23, value.wheels.index,
                value.wheels.var == true or value.wheels.var == 1)
        end
    end
    if value.pearlescent_color ~= nil and value.wheel_color ~= nil then
        VEHICLE.SET_VEHICLE_EXTRA_COLOURS(handle,
            value.pearlescent_color, value.wheel_color)
    end
    if value.interior_color ~= nil then VEHICLE.SET_VEHICLE_EXTRA_COLOUR_5(handle, value.interior_color) end
    if value.dashboard_color ~= nil then VEHICLE.SET_VEHICLE_EXTRA_COLOUR_6(handle, value.dashboard_color) end
    if value.neon then
        for i, enabled in ipairs(value.neon.enabled or {}) do VEHICLE.SET_VEHICLE_NEON_ENABLED(handle, i - 1, enabled) end
        local col = value.neon.color; if col then VEHICLE.SET_VEHICLE_NEON_COLOUR(handle, col.r, col.g, col.b) end
    end
    return valid()
end

return Appearance
