local Settings = require('includes.ssv2.core.settings')
local Calendar = require('includes.ssv2.core.calendar')
local Dates = require('includes.ssv2.core.stat_dates')
local defaults = require('includes.ssv2.data.stat_definitions')
local types = { 'int', 'float', 'money', 'bool', 'string', 'posix', 'time', 'date', 'bitset' }
local supported = {}; for _, kind in ipairs(types) do supported[kind] = true end
local function copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}; for key, item in pairs(value) do result[key] = copy(item) end; return result
end
return function(ctx)
    local f = {
        id = 'stat_controller',
        category = 'online',
        controls = {},
        next_read = 0,
        values = {},
        buffers = {},
        search = '',
        filter = 0,
        selected = '',
        new_name = '',
        new_type = 0,
        bit_view = 0
    }
    f.store = Settings.new({ definitions = defaults }, 'ssv2/mp_stats.json')
    function f:enabled() return true end

    function f:ready() return network.is_session_started() end

    function f:definitions() return self.store:get('definitions') end

    function f:get(name, kind)
        if kind == 'date' then return Dates.get(name) end
        local getter = kind == 'bool' and stats.get_bool or kind == 'float' and stats.get_float
            or kind == 'string' and stats.get_string or stats.get_int
        return getter(name)
    end

    function f:set(name, value)
        assert(network.is_session_started(), 'Stat editing requires an online session')
        local definition = self:definitions()[name]
        assert(definition and supported[definition.type], 'Unsupported stat type')
        local kind = definition.type
        if kind == 'date' then
            assert(Dates.set(name, value), 'Date stat write failed')
        else
            local setter = kind == 'bool' and stats.set_bool or kind == 'float' and stats.set_float
                or kind == 'string' and stats.set_string or stats.set_int
            if kind == 'time' or kind == 'posix' then value = math.max(0, value) end
            setter(name, value)
        end
        self.values[name] = copy(value)
    end

    function f:lock(name, enabled)
        if not network.is_session_started() then return end
        local definitions = copy(self:definitions())
        local definition = assert(definitions[name], 'Unknown stat')
        definition.autolock = enabled
        definition.lock_val = copy(self:get(name, definition.type))
        self.store:set('definitions', definitions); self.store:save()
    end

    function f:add(name, kind)
        assert(name:match('^[%w_]+$') and supported[kind], 'Invalid stat name or type')
        name = name:upper()
        local definitions = copy(self:definitions())
        if definitions[name] then
            ctx.notifier:warn("Samurai's Scripts", 'This stat already exists.'); return
        end
        definitions[name] = { type = kind, autolock = false }
        self.store:set('definitions', definitions); self.store:save(); self.next_read = 0
    end

    function f:update()
        self.store:update()
        if util.time() < self.next_read then return end
        for name, definition in pairs(self:definitions()) do
            assert(supported[definition.type], 'Unsupported saved stat type: ' .. tostring(definition.type))
            local value = self:get(name, definition.type)
            self.values[name] = value
            if self.buffers[name] == nil and value ~= nil then self.buffers[name] = copy(value) end
            if definition.autolock and value ~= nil then
                if definition.lock_val == nil then
                    local definitions = copy(self:definitions())
                    definitions[name].lock_val = copy(value); self.store:set('definitions', definitions)
                elseif (definition.type == 'date' and not Dates.equal(value, definition.lock_val))
                    or (definition.type ~= 'date' and value ~= definition.lock_val) then
                    self:set(name, definition.lock_val)
                end
            end
        end
        self.next_read = util.time() + 3000
    end

    function f:cleanup()
        self.values, self.buffers, self.next_read = {}, {}, 0; self.store:save()
    end

    function f:format(name, kind)
        local value = self.values[name]
        if value == nil then return 'Unavailable' end
        if kind == 'date' then return Dates.format(value) end
        if kind == 'posix' then return Calendar.local_format(math.max(0, value), '%Y-%m-%d %H:%M:%S') end
        if kind == 'time' then
            local seconds = math.floor(math.max(0, value) / 1000)
            return string.format('%02d:%02d:%02d', math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds %
                60)
        end
        if kind == 'money' then
            local text = string.format('%.0f', math.abs(value)):reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
            return (value < 0 and '-$' or '$') .. text
        end
        if kind == 'bitset' then
            if self.bit_view == 0 then return string.format('0x%08X', value % 4294967296) end
            if self.bit_view == 2 then return tostring(value) end
            local bits = {}; for i = 31, 0, -1 do bits[#bits + 1] = bit.band(value, bit.lshift(1, i)) ~= 0 and '1' or '0' end
            return table.concat(bits)
        end
        return tostring(value)
    end

    f.frontend = require('includes.ssv2.core.stat_view').new(ctx, f)
    f.owns_controls = true
    function f:draw_editor(name, definition) self.frontend:editor(name, definition) end

    function f:draw() self.frontend:draw() end

    return f
end
