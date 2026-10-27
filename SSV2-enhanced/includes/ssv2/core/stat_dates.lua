local Date = require('includes.ssv2.core.datetime')
local Dates = {}
local fields = { 'year', 'month', 'day', 'hour', 'min', 'sec' }
function Dates.prefix(name)
    if name:sub(1, 3):upper() ~= 'MPX' then return name end
    local index = require('includes.ssv2.core.game').character_index()
    assert(index ~= nil, 'Multiplayer character is unavailable')
    return 'MP' .. index .. name:sub(4)
end

function Dates.get(name)
    local ptr = memory.allocate(56)
    local ok, result = pcall(function()
        if not STATS.STAT_GET_DATE(util.joaat(Dates.prefix(name)), ptr, 7, -1) then return nil end
        local value = {}
        for i, key in ipairs(fields) do value[key] = ptr:add((i - 1) * 8):get_qword() end
        if value.year < 1970 or value.year > 9999 or value.month < 1 or value.month > 12
            or value.day < 1 or value.day > 31 or value.hour < 0 or value.hour > 23
            or value.min < 0 or value.min > 59 or value.sec < 0 or value.sec > 59 then
            return nil
        end
        return value
    end)
    memory.free(ptr)
    if not ok then error(result) end
    return result
end

function Dates.set(name, value)
    local normalized = Date.new(value):as_table()
    local ptr = memory.allocate(56)
    local ok, result = pcall(function()
        for i, key in ipairs(fields) do ptr:add((i - 1) * 8):set_qword(normalized[key]) end
        ptr:add(48):set_qword(0)
        return STATS.STAT_SET_DATE(util.joaat(Dates.prefix(name)), ptr, 7, true)
    end)
    memory.free(ptr)
    if not ok then error(result) end
    return result
end

function Dates.equal(a, b)
    if not a or not b then return a == b end
    for _, key in ipairs(fields) do if a[key] ~= b[key] then return false end end
    return true
end

function Dates.format(value)
    if not value then return 'Unavailable' end
    return Date.new(value):format('%d/%m/%Y %H:%M:%S')
end

return Dates
