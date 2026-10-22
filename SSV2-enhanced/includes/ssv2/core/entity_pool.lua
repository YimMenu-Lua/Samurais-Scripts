-- Own only entities created by this service; recycled handles are never deleted.
local Assets = require('includes.ssv2.core.assets')
local Pool = {}; Pool.__index = Pool
local ped_types = {}
for _, model in pairs(require('includes.ssv2.data.peds')) do ped_types[model.model_hash] = model.ped_type end
function Pool.new(ctx) return setmetatable({ ctx = ctx, assets = Assets.new(), owned = {} }, Pool) end

function Pool:wait(kind, name, valid)
    repeat
        if valid and not valid() then return false end
        if self.assets[kind](self.assets, name) then return true end
        script.yield(0)
    until not self.ctx.runtime.running
    return false
end

function Pool:create(kind, model, position, heading, valid, dynamic, networked)
    model = type(model) == 'string' and util.joaat(model) or model
    assert(type(model) == 'number', 'Model must be a name or hash')
    if not self:wait('model', model, valid) then return nil end
    local limits = self.ctx.entity_limits or { ped = 25, vehicle = 15, object = 35 }
    local count, oldest, oldest_record = 0, nil, nil
    for handle, record in pairs(self.ctx.owned_entities or {}) do
        if ENTITY.DOES_ENTITY_EXIST(handle) then
            local owned_kind = type(record) == 'table' and record.kind or
                ({ [1] = 'ped', [2] = 'vehicle', [3] = 'object' })[ENTITY.GET_ENTITY_TYPE(handle)]
            if owned_kind == kind then
                count = count + 1
                if not oldest_record or (type(record) == 'table' and record.created or 0) < (type(oldest_record) == 'table' and oldest_record.created or 0) then
                    oldest, oldest_record =
                        handle, record
                end
            end
        end
    end
    if count >= (limits[kind] or 0) then
        assert(self.ctx.settings and self.ctx.settings:get('backend.auto_cleanup_entities') and oldest,
            'Script entity limit reached for ' .. kind)
        if type(oldest_record) == 'table' and oldest_record.pool then
            oldest_record.pool:delete(oldest)
        else
            Entity.new(oldest):delete(); self.ctx.owned_entities[oldest] = nil
        end
    end
    local online = networked or false
    local handle
    if kind == 'ped' then
        assert(STREAMING.IS_MODEL_A_PED(model), 'Model is not a ped')
        handle = PED.CREATE_PED(ped_types[model % 4294967296] or 4, model, position.x, position.y, position.z,
            heading or 0, online, false)
    elseif kind == 'vehicle' then
        assert(STREAMING.IS_MODEL_A_VEHICLE(model), 'Model is not a vehicle')
        handle = VEHICLE.CREATE_VEHICLE(model, position.x, position.y, position.z, heading or 0, online, false, false)
    else
        handle = OBJECT.CREATE_OBJECT(model, position.x, position.y, position.z, online, false, dynamic ~= false)
        if handle ~= 0 then ENTITY.SET_ENTITY_HEADING(handle, heading or 0) end
    end
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model)
    assert(handle ~= 0 and ENTITY.DOES_ENTITY_EXIST(handle), 'Entity creation failed')
    if kind == 'vehicle' then
        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(handle, 5)
        VEHICLE.SET_VEHICLE_IS_STOLEN(handle, false)
        if network.is_session_started() then DECORATOR.DECOR_SET_INT(handle, 'MPBitset', 0) end
    end
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(handle, true, true)
    local entry = {
        handle = handle,
        kind = kind,
        model = model,
        entity = Entity.new(handle),
        pointer = memory
            .handle_to_ptr(handle):get_address(),
        pool = self,
        created = util.time()
    }
    self.owned[handle] = entry
    if self.ctx.owned_entities then self.ctx.owned_entities[handle] = entry end
    if valid and not valid() then
        self:delete(handle); return nil
    end
    return entry
end

function Pool:exists(entry)
    return entry and ENTITY.DOES_ENTITY_EXIST(entry.handle) and
        memory.handle_to_ptr(entry.handle):get_address() == entry.pointer
end

function Pool:delete(handle)
    local entry = self.owned[handle]
    if not entry then return end
    if self:exists(entry) then entry.entity:delete() end
    self.owned[handle] = nil
    if self.ctx.owned_entities and self.ctx.owned_entities[handle] == entry then self.ctx.owned_entities[handle] = nil end
end

function Pool:release(handle, keep_tracking)
    local entry = self.owned[handle]
    if not entry then return end
    if self:exists(entry) then
        local pointer = memory.allocate(4)
        assert(pointer and pointer:get_address() ~= 0, 'Cannot allocate entity handle')
        local ok, err = pcall(function()
            pointer:set_int(handle); ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(pointer)
        end)
        memory.free(pointer); if not ok then error(err) end
    end
    if keep_tracking then return end
    self.owned[handle] = nil
    if self.ctx.owned_entities and self.ctx.owned_entities[handle] == entry then self.ctx.owned_entities[handle] = nil end
end

function Pool:clear()
    for handle in pairs(self.owned) do self:delete(handle) end
    self.assets:reset()
end

return Pool
