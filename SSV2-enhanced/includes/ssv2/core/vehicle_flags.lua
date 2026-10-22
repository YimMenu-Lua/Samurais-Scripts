local Memory = require('includes.ssv2.core.vehicle_memory')
local Flags = {}; Flags.__index = Flags
function Flags.new() return setmetatable({ entries = {}, serial = 0 }, Flags) end

local function read(field, index) return bit.band(field:get_dword(), bit.lshift(1, index % 32)) ~= 0 end
local function write(field, index, value)
    local mask = bit.lshift(1, index % 32)
    local bits = value and bit.bor(field:get_dword(), mask) or bit.band(field:get_dword(), bit.bnot(mask))
    field:set_dword(bits % 4294967296)
end
function Flags:set(owner, handle, category, index, value)
    assert(type(value) == 'boolean', 'Flag value must be boolean')
    local field = Memory.flag_pointer(handle, category, index)
    if not field then return false end
    local key = tostring(field:get_address()) .. ':' .. index % 32
    local entry = self.entries[key]
    if not entry then
        entry = {
            handle = handle,
            base = Memory.identity(handle),
            category = category,
            index = index,
            address = field:get_address(),
            original = read(field, index),
            owners = {}
        }
        self.entries[key] = entry
    end
    local owned = entry.owners[owner]
    if not owned then
        self.serial = self.serial + 1; owned = { order = self.serial }; entry.owners[owner] = owned
    end
    owned.value, owned.handle, owned.base = value, handle, Memory.identity(handle)
    local latest = owned
    for _, other in pairs(entry.owners) do if other.order > latest.order then latest = other end end
    write(field, index, latest.value)
    return true
end

function Flags:release(owner)
    for key, entry in pairs(self.entries) do
        if entry.owners[owner] then
            local removed = entry.owners[owner]
            entry.owners[owner] = nil
            local latest
            for _, other in pairs(entry.owners) do if not latest or other.order > latest.order then latest = other end end
            local reference = latest or removed
            if ENTITY.DOES_ENTITY_EXIST(reference.handle) and Memory.identity(reference.handle) == reference.base then
                local field = Memory.flag_pointer(reference.handle, entry.category, entry.index)
                if field and field:get_address() == entry.address then
                    local value = entry.original
                    if latest then value = latest.value end
                    write(field, entry.index, value)
                end
            end
            if not latest then self.entries[key] = nil end
        end
    end
end

return Flags
