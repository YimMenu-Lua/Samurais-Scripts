local Calendar = require('includes.ssv2.core.calendar')
local Date = {}
Date.__index = Date
Date.__type = 'datetime'
local function copy(value)
    local result = {}; for key, item in pairs(value) do result[key] = item end; return result
end
local function seconds(value)
    if type(value) == 'number' then return value end
    assert(getmetatable(value) == Date, 'Expected a date or seconds')
    return value.epoch
end
function Date.new(value)
    local epoch
    if type(value) == 'table' then
        epoch = Calendar.local_epoch(value)
    elseif type(value) == 'number' then
        epoch = value
    elseif value == nil then
        epoch = os.time()
    else
        error('Expected a date table, Unix seconds or nil')
    end
    assert(epoch, 'Current time is unavailable')
    return setmetatable({ epoch = epoch, fields = Calendar.local_fields(epoch) }, Date)
end

function Date:format(pattern) return Calendar.local_format(self.epoch, pattern) end

function Date:as_table() return copy(self.fields) end

function Date:to_milliseconds() return self.epoch * 1000 end

function Date:serialize() return { type = 'DateTime', epoch = self.epoch } end

function Date.__tostring(value) return value:format() end

function Date.__add(a, b) return Date.new(seconds(a) + seconds(b)) end

function Date.__sub(a, b)
    if getmetatable(a) == Date and getmetatable(b) == Date then return os.difftime(a.epoch, b.epoch) end
    return Date.new(seconds(a) - seconds(b))
end

function Date.__eq(a, b) return seconds(a) == seconds(b) end

function Date.__lt(a, b) return seconds(a) < seconds(b) end

function Date.__le(a, b) return seconds(a) <= seconds(b) end

return Date
