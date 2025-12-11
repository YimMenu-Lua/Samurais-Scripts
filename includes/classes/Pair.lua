---@class Pair<K, V> : { first: K, second: V }
Pair = {}
Pair.__index = Pair

local _mt = {}
_mt.__index = function(self, k)
    if (k == "first")  then
        return self._raw[1]
    end

    if (k == "second") then
        return self._raw[2]
    end

    return _mt[k]
end

_mt.__newindex = function(self, k, v)
    if (type(k) == "number") then -- table.insert won't work without this
        if (k == 1) then
            self._raw[1] = v
            return
        elseif (k == 2) then
            self._raw[2] = v
            return
        else
            error("Pair index out of bounds!")
        end
    end

    if (k == "first")  then
        self._raw[1] = v
        return
    end

    if (k == "second") then
        self._raw[2] = v
        return
    end

    error("Pair only supports 'first' and 'second' keys")
end

function _mt:__len()
    return 2
end

function _mt:__ipairs()
    return ipairs(self._raw)
end

function _mt:__pairs()
    return pairs(self._raw)
end

---@generic K, V
---@param a K
---@param b V
---@return Pair<K, V>
function Pair:new(a, b)
    local obj = { _raw = { a, b } }
    return setmetatable(obj, _mt)
end
