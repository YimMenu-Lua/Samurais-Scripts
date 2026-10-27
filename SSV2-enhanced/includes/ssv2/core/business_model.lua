local Model = {}; Model.__index = Model
local function global(record, offsets)
    local data = record.ctx.script_data
    local path = { { PLAYER.PLAYER_ID(), data:offset('mp_business_stuff', 1) }, data:offset('mp_business_stuff', 2) }
    for _, offset in ipairs(offsets or {}) do path[#path + 1] = offset end
    return data:global('mp_business_stuff', path)
end
function Model.new(ctx, definition)
    definition.ctx = ctx; definition.auto = false; definition.loop = false; definition.next_update = 0
    return setmetatable(definition, Model)
end

function Model:capacity()
    if self.capacity_tunable then
        local name = self.upgrade_stat and stats.get_int(self.upgrade_stat) == 1 and self.upgrade_tunable or
            self.capacity_tunable
        return tunables.get_int(name)
    end
    return self.max or 0
end

function Model:count()
    return self.count_stat and stats.get_int(self.count_stat) or 0
end

function Model:setup() return not self.setup_stat or stats.get_int(self.setup_stat) == 1 end

function Model:full() return self:count() >= self:capacity() end

function Model:supplies() return self.supply_stat and stats.get_int(self.supply_stat) or 0 end

function Model:value()
    local count = self:count()
    if self.kind == 'cargo' then
        local thresholds = { 3, 5, 7, 9, 14, 19, 24, 29, 34, 39, 44, 49, 59, 69, 79, 89, 99, 110, 111 }
        local index = count <= 3 and count or nil
        if not index then
            for i = 2, #thresholds do
                if count <= thresholds[i] then
                    index = i + 2; break
                end
            end
        end
        return count > 0 and tunables.get_int('EXEC_CONTRABAND_SALE_VALUE_THRESHOLD' .. (index or 21)) * count or 0
    elseif self.kind == 'safe' or self.kind == 'duffle' then
        return count
    end
    return math.floor(count * (self.vpu or 0))
end

function Model:restock()
    if self:full() and self.kind ~= 'factory' then return false end
    if self.kind == 'hangar' then
        stats.set_masked_bool('MPX_DLC22022PSTAT_BOOL3', 9, true)
    elseif self.kind == 'cargo' then
        stats.set_masked_bool('MPX_FIXERPSTAT_BOOL1', self.index + 12, true)
    elseif self.kind == 'factory' and self:setup() and self:supplies() < 100 then
        local value = self.ctx.script_data:global('freemode_business_global', { self.index + 1 })
        if not value then return false end
        value:set_int(1)
    else
        return false
    end
    return true
end

function Model:technician()
    for tech = 0, 4 do
        local offset, position = tech < 4 and 2 or 3, tech < 4 and tech * 7 + self.index or self.index
        local value = global(self, { 321, offset })
        if value and bit.band(value:get_int(), bit.lshift(1, position)) ~= 0 then return tech end
    end
    return -1
end

function Model:assign(tech)
    assert(self.kind == 'hub' and tech >= -1 and tech <= 4, 'Invalid technician')
    local current = self:technician()
    if current == tech then return true end
    if current >= 0 then
        local offset, position = current < 4 and 2 or 3, current < 4 and current * 7 + self.index or self.index
        local value = global(self, { 321, offset }); value:set_int(bit.band(value:get_int(),
            bit.bnot(bit.lshift(1, position))))
        local timer = self.ctx.script_data:global_index(self.ctx.script_data:value('bhub_prod_time_global') - 19):at(
            current, 2)
        timer:set_int(0)
    end
    if tech >= 0 then
        local offset, position = tech < 4 and 2 or 3, tech < 4 and tech * 7 + self.index or self.index
        local value = global(self, { 321, offset }); value:set_int(bit.bor(value:get_int(), bit.lshift(1, position)))
    end
    return true
end

function Model:production_time()
    if self.kind == 'factory' then
        return global(self, { 205, { self.index, 13 }, 9 })
    elseif self.kind == 'hub' then
        return self.ctx.script_data:global('bhub_prod_time_global', { self.index + 1 })
    end
end

function Model:produce(count)
    if not self:setup() or self:full() then return false end
    local timer = self:production_time()
    if not timer or timer:get_int() < 1000 then return false end
    if self.kind == 'factory' then
        timer:set_int(100)
    elseif self.kind == 'hub' then
        local tech = self:technician(); if tech < 0 then return false end
        local next_count = math.min(count or self:count() + 1, self:capacity())
        if next_count < self:capacity() then
            global(self, { 321, 8, self.index + 1 }):set_int(next_count); stats.set_int(self.count_stat, next_count)
        else
            self.ctx.script_data:global_index(self.ctx.script_data:value('bhub_prod_time_global') - 19):at(tech, 2)
                :set_int(0)
            timer:set_int(0); self.ctx.script_data:global('bhub_prod_bool_global'):set_int(1)
        end
    else
        return false
    end
    return true
end

function Model:nearby(ped)
    return self.room_hash and INTERIOR.GET_ROOM_KEY_FROM_ENTITY(ped) % 4294967296 == self.room_hash % 4294967296 or false
end

function Model:fill_safe()
    if self.kind ~= 'safe' or self:count() == self:capacity() then return false end
    local value
    if self.car_wash then
        local data = self.ctx.script_data
        value = data:global('car_wash_safe_global',
            { { PLAYER.PLAYER_ID(), data:offset('car_wash_safe_global', 1) }, data:offset('car_wash_safe_global', 2), 27, 2 })
    elseif self.global_offset then
        value = global(self, { self.global_offset })
    end
    if not value then return false end
    local capacity = self:capacity()
    if capacity < 0 then return false end
    stats.set_int(self.count_stat, capacity); value:set_int(capacity)
    if self.paytime_stat then stats.set_int(self.paytime_stat, 100) end
    return true
end

function Model:refresh()
    self.snapshot = {
        count = self:count(),
        capacity = self:capacity(),
        value = self:value(),
        supplies = self:supplies(),
        setup =
            self:setup()
    }
    if self.kind == 'hub' then self.snapshot.technician = self:technician() end
    if self.kind == 'factory' or self.kind == 'hub' then
        local timer = self:production_time(); self.snapshot.timer = timer and timer:get_int() or nil
    end
    if self.heat then self.snapshot.heat = stats.get_packed_int(self.heat) end
    if self.kind == 'duffle' then
        self.snapshot.pending = stats.get_int('MPX_CAR_WASH_DUFFEL_PENDING')
        self.snapshot.dirty_until = stats.get_int('MPX_CAR_WASH_DUFFEL_POSIX')
        self.snapshot.clean = self.snapshot.count - (os.time() < self.snapshot.dirty_until and self.snapshot.pending or 0)
    end
end

function Model:update(state, now)
    if now < self.next_update then return end
    if self.auto then
        if self:full() then
            self.auto = false
        elseif self.kind == 'factory' or self.kind == 'hub' then
            if not self.ctx.settings:get('features.unsafe_feats_enabled') then
                self.auto = false
            else
                if self.kind == 'factory' and self:supplies() <= 25 then self:restock() end; self:produce()
            end
        else
            self:restock()
        end
    end
    if self.loop then
        if self:count() > self:capacity() then self:fill_safe() end
        if not self.ctx.settings:get('features.unsafe_feats_enabled') or not self.paytime_stat or self:full() and not self:nearby(state.handle) then
            self.loop = false
        elseif self.paytime_stat and not self:full() and stats.get_int(self.paytime_stat) > 100 and now >= (self.collected_until or 0) then
            stats.set_int(self.paytime_stat, 100)
        end
        local character = self.ctx.game.character_index()
        local balance = character and
            tonumber(MONEY.NETWORK_GET_STRING_BANK_BALANCE()) + tonumber(MONEY.NETWORK_GET_STRING_WALLET_BALANCE(character)) or
            self.balance
        if not balance then
            self:refresh(); return
        end
        self.balance = self.balance or balance
        if balance - self.balance >= self:capacity() then
            self.collected_until = now + 5000; self.balance = balance
        end
    end
    self:refresh()
    self.next_update = now +
        ((self.kind == 'cargo' or self.kind == 'hangar') and self.ctx.settings:get('features.yrv3.autofill_delay') or 250)
end

return Model
