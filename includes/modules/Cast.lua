-----------------------------------------
-- Cast Module
-----------------------------------------
-- Explicit integer type casting helpers
--
-- Usage example:
--
--```lua
--local c = Cast(65535)
--print(c:AsUint16_t()) --> 65535
--print(c:AsInt16_t()) --> -1
--```
-----------------------------------------
---@ignore
---@class Cast
---@field private m_value integer
---@overload fun(n: integer): Cast
local Cast = {}
Cast.__index = Cast
---@diagnostic disable-next-line: param-type-mismatch
setmetatable(Cast, {
    __call = function (_, n)
        return Cast.new(n)
    end
})

-- Constructor
---@param n integer
---@return Cast
function Cast.new(n)
    local _t = type(n)
    assert(_t == "number", _F("[Cast]: Invalid parameter! Number expected, got %s instead", _t))
    ---@diagnostic disable-next-line: param-type-mismatch
    return setmetatable({ m_value = n }, Cast)
end

---@return uint8_t
function Cast:AsUint8_t()
    return self.m_value & 0xFF
end

---@return int8_t
function Cast:AsInt8_t()
    local v = self.m_value & 0xFF

    if (v >= 0x80) then
        return v - 0x100
    end

    return v
end

---@return uint16_t
function Cast:AsUint16_t()
    return self.m_value & 0xFFFF
end

---@return int16_t
function Cast:AsInt16_t()
    local v = self.m_value & 0xFFFF

    if (v >= 0x8000) then
        return v - 0x10000
    end

    return v
end

---@return uint32_t
function Cast:AsUint32_t()
    return self.m_value & 0xFFFFFFFF
end

---@return int32_t
function Cast:AsInt32_t()
    local v = self.m_value & 0xFFFFFFFF

    if (v >= 0x80000000) then
        return v - 0x100000000
    end

    return v
end

---@return joaat_t
function Cast:AsJoaat_t()
    ---@diagnostic disable-next-line: return-type-mismatch
    return self:AsUint32_t()
end

-- **[NOTE]** Lua numbers are IEEE-754 doubles so this **will lose precision above 2^53**.
--
-- V1 does not have `bigint` or an `FFI` lib so this will have to do.
---@return uint64_t
function Cast:AsUint64_t()
    local lo = self.m_value & 0xFFFFFFFF
    local hi = math.floor(self.m_value / 0x100000000) & 0xFFFFFFFF

    return hi * 0x100000000 + lo
end

---@return int64_t
function Cast:AsInt64_t()
    local u = self:AsUint64_t()

    if (u >= 0x8000000000000000) then
        return u - 0x10000000000000000
    end

    return u
end

return Cast
