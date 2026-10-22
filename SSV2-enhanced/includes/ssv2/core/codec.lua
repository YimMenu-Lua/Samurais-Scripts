-- Original Samurai public XOR/Base64 format for shared creations and old profiles.
local Json = require('includes.ssv2.vendor.json')()
local Codec = {}
local registered = {}
local alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local key = string.char(0xA3, 0x4F, 0xD2, 0x9B, 0x7E, 0xC1, 0xE8, 0x36, 0x5D, 0x0A, 0xF7, 0xB4, 0x6C, 0x2D, 0x89, 0x50,
    0x1E, 0x73, 0xC9, 0xAF, 0x3B, 0x92, 0x58, 0xE0, 0x14, 0x7D, 0xA6, 0xCB, 0x81, 0x3F, 0xD5, 0x67)
local lookup = {}; for i = 1, #alphabet do lookup[alphabet:sub(i, i)] = i - 1 end
function Codec.xor(input, custom_key)
    local result = {}; local secret = custom_key or key
    assert(#secret > 0, 'Empty serialization key')
    for i = 1, #input do result[i] = string.char(bit.bxor(input:byte(i), secret:byte((i - 1) % #secret + 1))) end
    return table.concat(result)
end

function Codec.base64(input)
    local result = {}
    for i = 1, #input, 3 do
        local word = bit.bor(bit.lshift(input:byte(i), 16), bit.lshift(input:byte(i + 1) or 0, 8), input:byte(i + 2) or 0)
        for j = 18, 0, -6 do
            local index = bit.band(bit.rshift(word, j), 63) + 1
            result[#result + 1] = (j == 6 and i + 1 > #input or j == 0 and i + 2 > #input) and '=' or
                alphabet:sub(index, index)
        end
    end
    return table.concat(result)
end

function Codec.unbase64(input)
    local text = input:gsub('%s', '')
    assert(#text % 4 == 0 and not text:find('[^%w%+/=]') and not text:sub(1, -3):find('=', 1, true),
        'Invalid Base64 data')
    local result = {}
    for i = 1, #text, 4 do
        local a, b, c, d = text:sub(i, i), text:sub(i + 1, i + 1), text:sub(i + 2, i + 2), text:sub(i + 3, i + 3)
        assert(lookup[a] and lookup[b] and (lookup[c] or c == '=') and (lookup[d] or d == '=') and (c ~= '=' or d == '='),
            'Invalid Base64 block')
        local word = bit.bor(bit.lshift(lookup[a], 18), bit.lshift(lookup[b], 12), bit.lshift(lookup[c] or 0, 6),
            lookup[d] or 0)
        result[#result + 1] = string.char(bit.band(bit.rshift(word, 16), 255))
        if c ~= '=' then result[#result + 1] = string.char(bit.band(bit.rshift(word, 8), 255)) end
        if d ~= '=' then result[#result + 1] = string.char(bit.band(word, 255)) end
    end
    return table.concat(result)
end

function Codec.register(name, encode, decode)
    assert(type(name) == 'string' and type(encode) == 'function' and type(decode) == 'function',
        'Invalid serialized type')
    registered[name:lower()] = { encode = encode, decode = decode }
end

function Codec.pack(value, seen)
    local kind = type(value)
    if kind ~= 'table' and kind ~= 'userdata' then return value end
    seen = seen or {}; assert(not seen[value], 'Cannot serialize a cyclic value'); seen[value] = true
    local tag = value.__type
    local adapter = tag and registered[tostring(tag):lower()]
    local result
    if adapter then
        result = adapter.encode(value)
    elseif kind == 'userdata' then
        assert(type(value.x) == 'number' and type(value.y) == 'number' and type(value.z) == 'number',
            'Unsupported serialized userdata')
        result = { __type = 'vec3', x = value.x, y = value.y, z = value.z }
    else
        result = {}; for key, item in pairs(value) do result[key] = Codec.pack(item, seen) end
    end
    seen[value] = nil; return result
end

function Codec.unpack(value)
    if type(value) ~= 'table' then return value end
    local adapter = value.__type and registered[tostring(value.__type):lower()]
    if adapter then return adapter.decode(value) end
    for key, item in pairs(value) do value[key] = Codec.unpack(item) end
    return value
end

function Codec.encode(value, share)
    local text = Json:encode_pretty(Codec.pack(value))
    return share and Codec.base64(Codec.xor(text)) or text
end

function Codec.decode(input)
    assert(type(input) == 'string' and #input > 0, 'No serialized data')
    local text = input
    if not input:match('^%s*[%{%[]') then text = Codec.xor(Codec.unbase64(input)) end
    return Codec.unpack(Json:decode(text))
end

Codec.register('datetime', function(value) return { __type = 'datetime', epoch = value.epoch } end,
    function(value) return require('includes.ssv2.core.datetime').new(value.epoch) end)
return Codec
