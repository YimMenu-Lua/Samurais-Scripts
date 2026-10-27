-- Calendar arithmetic for the V2 port. All epoch arguments use seconds.
local Calendar = {}
local floor = math.floor
local months = { 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December' }
local days = { 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' }

local function civil_days(year, month, day)
    year = year - (month <= 2 and 1 or 0)
    local era = floor(year / 400)
    local yoe = year - era * 400
    local mp = month + (month > 2 and -3 or 9)
    local doy = floor((153 * mp + 2) / 5) + day - 1
    return era * 146097 + yoe * 365 + floor(yoe / 4) - floor(yoe / 100) + doy - 719468
end

function Calendar.to_epoch(fields, offset_seconds)
    assert(type(fields.year) == 'number' and type(fields.month) == 'number'
        and type(fields.day) == 'number', 'A calendar date is required')
    local year = fields.year + floor((fields.month - 1) / 12)
    local month = (fields.month - 1) % 12 + 1
    return civil_days(year, month, fields.day) * 86400
        + (fields.hour or 12) * 3600 + (fields.min or 0) * 60 + (fields.sec or 0)
        - (offset_seconds or 0)
end

function Calendar.from_epoch(epoch, offset_seconds)
    epoch = floor(epoch + (offset_seconds or 0))
    local day_count = floor(epoch / 86400)
    local seconds = epoch - day_count * 86400
    local z = day_count + 719468
    local era = floor(z / 146097)
    local doe = z - era * 146097
    local yoe = floor((doe - floor(doe / 1460) + floor(doe / 36524) - floor(doe / 146096)) / 365)
    local year = yoe + era * 400
    local doy = doe - (365 * yoe + floor(yoe / 4) - floor(yoe / 100))
    local mp = floor((5 * doy + 2) / 153)
    local day = doy - floor((153 * mp + 2) / 5) + 1
    local month = mp + (mp < 10 and 3 or -9)
    year = year + (month <= 2 and 1 or 0)
    return {
        year = year,
        month = month,
        day = day,
        hour = floor(seconds / 3600),
        min = floor(seconds / 60) % 60,
        sec = seconds % 60,
        wday = (day_count + 4) % 7 + 1,
        yday = day_count - civil_days(year, 1, 1) + 1
    }
end

function Calendar.format(epoch, pattern, offset_seconds)
    local f = Calendar.from_epoch(epoch, offset_seconds)
    local function pad(n, size) return string.format('%0' .. (size or 2) .. 'd', n) end
    local offset = offset_seconds or 0
    local values = {
        Y = pad(f.year, 4),
        y = pad(f.year % 100),
        m = pad(f.month),
        d = pad(f.day),
        H = pad(f.hour),
        M = pad(f.min),
        S = pad(f.sec),
        b = months[f.month]:sub(1, 3),
        B = months[f.month],
        a = days[f.wday]:sub(1, 3),
        A = days[f.wday],
        j = pad(f.yday, 3),
        w = tostring(f.wday - 1),
        u = tostring((f.wday + 5) % 7 + 1),
        I = pad((f.hour + 11) % 12 + 1),
        p = f.hour < 12 and 'AM' or 'PM',
        ['%'] = '%',
        z = (offset < 0 and '-' or '+') .. pad(floor(math.abs(offset) / 3600))
            .. pad(floor(math.abs(offset) / 60) % 60)
    }
    values.F, values.T, values.R = values.Y .. '-' .. values.m .. '-' .. values.d,
        values.H .. ':' .. values.M .. ':' .. values.S, values.H .. ':' .. values.M
    local text = (pattern or '%Y-%m-%d %H:%M:%S'):gsub('%%(.)', function(code)
        assert(values[code], 'Unsupported calendar format: %' .. code)
        return values[code]
    end)
    return text
end

-- Local calendar operations deliberately use the host's standard LuaJIT library.
-- An offset measured today cannot determine another timestamp's DST rules.
function Calendar.local_fields(epoch)
    local fields = os.date('*t', epoch)
    assert(fields, 'Local date is outside the supported platform range')
    return fields
end

function Calendar.local_epoch(fields)
    local input = {}
    for key, value in pairs(fields) do input[key] = value end
    local epoch = os.time(input)
    assert(epoch, 'Local date is outside the supported platform range')
    return epoch
end

function Calendar.local_format(epoch, pattern)
    assert(pattern ~= '*t' and pattern ~= '!*t', 'Date formatting requires a string format')
    local result = os.date(pattern or '%Y-%m-%d %H:%M:%S', epoch)
    assert(result, 'Local date is outside the supported platform range')
    return result
end

function Calendar.current_local()
    return Calendar.local_fields(os.time())
end

return Calendar
