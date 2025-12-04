-- Minimal JS-like enum class with metamethods.
--
-- **[NOTE]**: If you care about performance, or don't care about constants, consider using a simple table instead
--
-- *(SB already uses tables annotated as enums)*. A simple hash lookup is slightly faster.
--
-- This implementation is more about usability and type-safety.
--
-- **Usage Example:**
--
--```Lua
-- -- Array-style quick definition (preserves key order, no type hints):
-- local eTestEnum = Enum {
--     "FIRST",          -- auto assigned to 0
--     "SECOND",         -- auto assigned to 1
--     "THIRD",          -- auto assigned to 2
-- }
--
-- -- Explicit values (no key order, with type hints):
-- local eExplicitEnum = Enum {
--     ZERO = 0,
--     ONE = 1,
--     TWO = 2,       -- etc.
-- }
--
-- -- Array-style mixed values (preserves key order, no type hints):
-- local eMixedEnum = Enum {
--     { "INVALID", -1 },
--     "ZERO",        -- auto assigned to 0
--     "ONE",         -- auto assigned to 1
--     "TWO",         -- auto assigned to 2
--     { "UNK", 99 },
--     "HUNNID",      -- auto assigned to 100.
-- }
--```
--___
-- **[NOTE]**: The only way to preserve key order is to use array-style definitions, at the cost of type hints *(which defeats the purpose of using Enum in the first place)*;
-- and the only way to have type hints is to use hash-style definitions *(see Explicit values example)*, but you will lose key order.
--
-- **Do not mix the two styles or you will get unpredictable results.**
--
-- Param `data_type` is optional and is only used for size calculations via `SizeOf(enum)`.
---@generic T: Enum
---@param t T
---@param data_type? "int8_t" | "int16_t" | "int32_t" | "int64_t" | "uint8_t" | "uint16_t" | "uint32_t"| "uint64_t" | "joaat_t" | "float" | "byte"
---@return T|Enum
---@generic T: Enum
function Enum(t, data_type)
    assert(type(t) == "table", "Enum expects a table!")
    data_type = data_type or "int32_t"

    local fixed, reverse, ordered = {}, {}, {}
    local next_auto = 0

    for i = 1, #t do
        local v = t[i]
        if (type(v) == "table") then
            local k, val = v[1], v[2]
            assert(type(k) == "string", "Enum key must be a string")
            assert(type(val) == "number", "Enum value must be a number")
            fixed[k] = val
            reverse[val] = k
            table.insert(ordered, k)
            next_auto = math.max(next_auto, val + 1)
        elseif (type(v) == "string") then
            fixed[v] = next_auto
            reverse[next_auto] = v
            table.insert(ordered, v)
            next_auto = next_auto + 1
        else
            error(_F("Invalid enum element #%d: expected string or { key, value }", i))
        end
    end

    for k, v in pairs(t) do
        if (type(k) == "string" and fixed[k] == nil) then
            fixed[k] = v
            reverse[v] = k
            table.insert(ordered, k)
        end
    end

    local meta = {}

    ---@return number
    function meta:First()
        local firstKey = ordered[1]
        return firstKey and fixed[firstKey]
    end

    ---@return string[]
    function meta:Keys()
        return table.move(ordered, 1, #ordered, 1, {})
    end

    ---@return integer[]
    function meta:Values()
        local vals = {}
        for _, k in ipairs(ordered) do
            table.insert(vals, fixed[k])
        end
        return vals
    end

    ---@param value integer
    ---@return string
    function meta:NameOf(value)
        return reverse[value] or "nil"
    end

    ---@param value integer
    ---@return boolean
    function meta:Has(value)
        return reverse[value] ~= nil
    end

    local proxy = setmetatable({}, {
        __index = function(_, k)
            return fixed[k] or meta[k]
        end,

        __newindex = function(_, key)
            error(_F("Attempt to modify read-only enum: '%s'", key))
        end,

        __call = function(_, key)
            if type(key) == "string" then
                return fixed[key]
            elseif type(key) == "number" then
                return reverse[key]
            end
        end,

        __tostring = function()
            local parts = {}
            for _, k in ipairs(ordered) do
                table.insert(parts, ("%s=%s"):format(k, fixed[k]))
            end
            return "Enum{" .. table.concat(parts, ", ") .. "}"
        end,

        __metatable = false,
    })

    rawset(proxy, "__enum", true)
    rawset(proxy, "__data_type", data_type)

    function meta:__sizeof()
        local ext_sizes = { byte = 0x1, float = 0x4, joaat_t = 0x4 }
        return ext_sizes[data_type]
            or (INT_SIZES and INT_SIZES[data_type])
            or math.sizeof(proxy:First())
    end

    return proxy
end
