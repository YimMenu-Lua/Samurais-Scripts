-- Saved-default state belongs to the script, as in V1's IManagedValue.
local Managed = {}; Managed.__index = Managed
local readers = {
    tunable = { int = tunables.get_int, float = tunables.get_float, bool = tunables.get_bool },
    stat = { int = stats.get_int, float = stats.get_float, bool = stats.get_bool },
    packed = { int = stats.get_packed_int, bool = stats.get_packed_bool }
}
local writers = {
    tunable = { int = tunables.set_int, float = tunables.set_float, bool = tunables.set_bool },
    stat = { int = stats.set_int, float = stats.set_float, bool = stats.set_bool },
    packed = { int = stats.set_packed_int, bool = stats.set_packed_bool }
}
function Managed.new(ctx, definition)
    local kind = definition.kind or 'tunable'
    local datatype = definition.type or (type(definition.v) == 'boolean' and 'bool'
        or definition.v == math.floor(definition.v) and 'int' or 'float')
    assert(readers[kind] and (datatype == 'masked_bool' and kind == 'stat' or readers[kind][datatype]),
        'Unsupported managed value type')
    return setmetatable({
        ctx = ctx,
        kind = kind,
        datatype = datatype,
        id = definition.t,
        desired = definition.v,
        bit_index = definition.bit_index,
        captured = false,
        modified = false
    }, Managed)
end

function Managed:resolve_id()
    if self.kind == 'stat' and type(self.id) == 'string' and self.id:sub(1, 4) == 'MPX_' then
        local index = self.ctx.game.character_index()
        if index == nil then return nil end
        return 'MP' .. index .. self.id:sub(4)
    end
    return self.id
end

function Managed:get(identifier)
    local id = identifier or self.resolved or self:resolve_id()
    if id == nil then return nil end
    if self.datatype == 'masked_bool' then return stats.get_masked_bool(id, self.bit_index) end
    return readers[self.kind][self.datatype](id)
end

function Managed:set(value, identifier)
    local id = identifier or self.resolved
    assert(id ~= nil, 'Managed identifier has not been resolved')
    if self.datatype == 'masked_bool' then
        stats.set_masked_bool(id, self.bit_index, value)
    else
        writers[self.kind][self.datatype](id, value)
    end
end

function Managed:capture()
    if self.captured then return true end
    if not network.is_session_started() then return false end
    local id = self:resolve_id()
    if id == nil then return false end
    local original = self:get(id)
    if original == nil then return false end
    self.resolved, self.original, self.captured = id, original, true
    return true
end

function Managed:is_ready() return self.captured end

function Managed:apply()
    if not self:capture() then return false end
    if self:get() ~= self.desired then
        self:set(self.desired); self.modified = true
    end
    return true
end

function Managed:reset()
    if self.captured and self.modified then
        self:set(self.original); self.modified = false
    end
end

function Managed:clear()
    self:reset(); self.resolved, self.original, self.captured = nil, nil, false
end

function Managed:set_desired(value) self.desired = value end

return Managed
