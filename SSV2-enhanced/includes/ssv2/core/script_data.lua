local definitions = require('includes.ssv2.data.globals_locals')
local Data = {}; Data.__index = Data
function Data.new(build) return setmetatable({ build = build }, Data) end

function Data:entry(key)
    local definition = assert(definitions[key], 'Unknown game field: ' .. tostring(key))
    local entry = assert(definition.ENHANCED, 'Game field has no Enhanced definition: ' .. key)
    assert(type(entry.value) == 'number', 'Game field has no index: ' .. key)
    return entry, definition.file:gsub('%.c$', ''):match('^%s*(.-)%s*$')
end

function Data:value(key)
    local entry = self:entry(key); return entry.value
end

function Data:offset(key, index)
    local entry = self:entry(key)
    local offset = entry.offsets and entry.offsets[index]
    assert(offset and type(offset.value) == 'number', 'Game field has no offset ' .. key .. ':' .. tostring(index))
    return offset.value
end

local function add_offsets(index, offsets)
    for _, offset in ipairs(offsets or {}) do
        if type(offset) == 'table' then
            index = index + 1 + offset[1] * offset[2]
        else
            index = index + offset
        end
    end
    return index
end
function Data:global(key, offsets)
    self.build:require_supported()
    local global = ScriptGlobal.new(add_offsets(self:value(key), offsets))
    return global:can_access() and global or nil
end

function Data:local_value(key, offsets, name)
    self.build:require_supported()
    local entry, script_name = self:entry(key)
    return ScriptLocal.new(name or script_name, add_offsets(entry.value, offsets))
end

function Data:local_index(script_name, index)
    self.build:require_supported(); return ScriptLocal.new(script_name, index)
end

function Data:global_index(index)
    self.build:require_supported()
    local value = ScriptGlobal.new(index); return value:can_access() and value or nil
end

function Data:read_local(key, offsets, name)
    local local_value = self:local_value(key, offsets, name)
    if not local_value then return nil end
    return local_value:get_int()
end

function Data:write_local(key, value, offsets, name)
    local local_value = self:local_value(key, offsets, name)
    if not local_value then return false end
    local_value:set_int(value); return true
end

function Data:write_local_bits(key, indices, enabled, offsets, name)
    local local_value = self:local_value(key, offsets, name)
    if not local_value then return false end
    local value = local_value:get_int()
    for _, index in ipairs(indices) do
        assert(index >= 0 and index <= 31, 'Expected a 32-bit flag index')
        local mask = bit.lshift(1, index)
        value = enabled and bit.bor(value, mask) or bit.band(value, bit.bnot(mask))
    end
    local_value:set_int(value); return true
end

function Data:host(script_name)
    local id = PLAYER.PLAYER_ID()
    for instance = -1, 3 do if NETWORK.NETWORK_GET_HOST_OF_SCRIPT(script_name, instance, 0) == id then return true end end
    return false
end

function Data:request_host(script_name, timeout, valid)
    local deadline = util.time() + (timeout or 10000)
    repeat
        if not scripts.is_active(script_name) or valid and not valid() then return false end
        if self:host(script_name) then return true end
        network.force_script_host(script_name)
        script.yield(0)
    until util.time() >= deadline
    return scripts.is_active(script_name) and (not valid or valid()) and self:host(script_name) or false
end

return Data
