---@diagnostic disable: param-type-mismatch

---@enum eColorType
local eColorType <const> = {
    UNK   = 0,
    FLOAT = 1,
    RGBA  = 2,
    HEX   = 3,
    U32   = 4,
    NAME  = 5
}

local NamedColors = {
    black  = { 0.0, 0.0, 0.0, 1.0 },
    white  = { 1.0, 1.0, 1.0, 1.0 },
    red    = { 1.0, 0.0, 0.0, 1.0 },
    green  = { 0.0, 1.0, 0.0, 1.0 },
    blue   = { 0.0, 0.0, 1.0, 1.0 },
    yellow = { 1.0, 1.0, 0.0, 1.0 },
    orange = { 1.0, 0.5, 0.0, 1.0 },
    pink   = { 1.0, 0.0, 0.5, 1.0 },
    purple = { 1.0, 0.0, 1.0, 1.0 },
}

--------------------------------------
-- Class: Color
--------------------------------------
-- Color instances can be created using color names defined in `Color.string_colors`,
-- self-regsitered color names (using the `RegisterNamedColor` method),
-- hex strings, ABGR uint32, RGBA [0 - 255], and normalized RGBA [0 - 1].
---@class Color
---@field private m_type eColorType
---@field private m_source table
---@field r float
---@field g float
---@field b float
---@field a float
Color = Class("Color")
Color.m_string_colors = NamedColors

local function clamp_byte(n)
    return math.max(0, math.min(255, n))
end

local function parse_hex(str)
    str = str:gsub("#", "")
    if #str == 6 then str = str .. "FF" end
    if #str ~= 8 then return nil end
    return
        tonumber(str:sub(1,2),16),
        tonumber(str:sub(3,4),16),
        tonumber(str:sub(5,6),16),
        tonumber(str:sub(7,8),16)
end

local function parse_u32(u)
    return
        (u      ) & 0xFF,
        (u >>  8) & 0xFF,
        (u >> 16) & 0xFF,
        (u >> 24) & 0xFF
end

-- Constructor
--
-- Returns a new `Color` instance.
---@param ... any
---@return Color
function Color.new(...)
    local args = { ... }
    local self = setmetatable({}, Color)

    self.m_type = eColorType.UNK
    self.m_source = args

    if (#args == 1 and type(args[1]) == "string") then
        local key = args[1]:lower()

        if (key:match("^#?%x%x%x%x%x%x$") or key:match("^#?%x%x%x%x%x%x%x%x$")) then
            local r, g, b, a = parse_hex(key)
            if (r) then
                self.r, self.g, self.b, self.a = r/255, g/255, b/255, a/255
                self.m_type = eColorType.HEX
                return self
            end
        end

        local named = Color.m_string_colors[key]
        if (named) then
            self.r, self.g, self.b, self.a = named[1], named[2], named[3], named[4]
            self.m_type = eColorType.NAME
            return self
        end

        error("[Color]: invalid string color '" .. args[1] .. "'")
    end

    if (#args == 1 and type(args[1]) == "number") then
        local r,g,b,a = parse_u32(args[1])
        self.r, self.g, self.b, self.a = r/255, g/255, b/255, a/255
        self.m_type = eColorType.U32
        return self
    end

    if (#args >= 3
       and type(args[1]) == "number"
       and type(args[2]) == "number"
       and type(args[3]) == "number"
    ) then
        local r, g, b = args[1], args[2], args[3]
        local a = args[4] or ((math.type(r)=="float") and 1.0 or 255)

        if r <= 1 and g <= 1 and b <= 1 then
            self.r, self.g, self.b, self.a = r, g, b, a
            self.m_type = eColorType.FLOAT
        else
            self.r, self.g, self.b, self.a = r/255, g/255, b/255, a/255
            self.m_type = eColorType.RGBA
        end
        return self
    end

    error("[Color]: unsupported arguments")
end

-- Allows you to register new named colors in the Color class itself
-- that you can call later using `Color("your_custom_color_name")`
--
-- Example usage:
--
-- ```lua
-- Color:RegisterNamedColor("Magenta", "#FF00FF")
-- local r, g, b, a = Color("Magenta"):AsRGBA()
-- ```
---@param name string
---@param ... any
function Color:RegisterNamedColor(name, ...)
    name = name:lower()

    if (Color.m_string_colors[name]) then
        log.fwarning("[Color]: '%s' already exists.", name)
        return
    end

    local c = Color.new(...)
    Color.m_string_colors[name] = { c.r, c.g, c.b, c.a }
end


-- Returns the color in **RGBA** format [0 - 255].
---@return number, number, number, number
function Color:AsRGBA()
    return
        clamp_byte(self.r * 255),
        clamp_byte(self.g * 255),
        clamp_byte(self.b * 255),
        clamp_byte(self.a * 255)
end


-- Returns the color in **normalized RGBA** format [0 - 1].
---@return float, float, float, float
function Color:AsFloat()
    return self.r, self.g, self.b, self.a
end


-- Returns an unsigned 32bit int representing the color in **ABGR** format.
---@return uint32_t
function Color:AsU32()
    local r, g, b, a = self:AsRGBA()
    return (a << 24) | (b << 16) | (g << 8) | r
end

-- Returns the color as a hexadecimal string.
---@return string
function Color:AsHex()
    local r,g,b,a = self:AsRGBA()
    return string.format("#%02X%02X%02X%02X", r,g,b,a)
end

---@param right Color
---@return boolean
function Color:__eq(right)
    local r1, g1, b1, a1 = self:AsRGBA()
    local r2, g2, b2, a2 = right:AsRGBA()
    return r1 == r2 and g1 == g2 and b1 == b2 and a1 == a2
end

---@param right Color
---@return Color
function Color:__add(right)
    local lf = {self:AsFloat()}
    local rf = {right:AsFloat()}
    return Color.new(
        math.min(lf[1] + rf[1], 1),
        math.min(lf[2] + rf[2], 1),
        math.min(lf[3] + rf[3], 1),
        math.min(lf[4] + rf[4], 1)
    )
end

---@param right Color
---@return Color
function Color:__sub(right)
    local lf = {self:AsFloat()}
    local rf = {right:AsFloat()}
    return Color.new(
        math.max(lf[1] - rf[1], 0),
        math.max(lf[2] - rf[2], 0),
        math.max(lf[3] - rf[3], 0),
        math.max(lf[4] - rf[4], 0)
    )
end

---@param right Color
---@return Color
function Color:__mul(right)
    local lf = {self:AsFloat()}
    local rf = {right:AsFloat()}
    return Color.new(
        math.min(lf[1] * rf[1], 1),
        math.min(lf[2] * rf[2], 1),
        math.min(lf[3] * rf[3], 1),
        math.min(lf[4] * rf[4], 1)
    )
end

---@param right Color
---@return Color
function Color:__div(right)
    local lf = {self:AsFloat()}
    local rf = {right:AsFloat()}
    return Color.new(
        rf[1] == 0 and 0 or lf[1] / rf[1],
        rf[2] == 0 and 0 or lf[2] / rf[2],
        rf[3] == 0 and 0 or lf[3] / rf[3],
        rf[4] == 0 and 0 or lf[4] / rf[4]
    )
end

function Color:__tostring()
    local r,g,b,a = self:AsRGBA()
    return string.format(
        "<Color> Float: %.3f %.3f %.3f %.3f | RGBA: %d %d %d %d | Hex: %s | U32 0x%X",
        self.r, self.g, self.b, self.a,
        r, g, b, a,
        self:AsHex(),
        self:AsU32()
    )
end


------------------------------------------------------------------------------------------
-- Helpers for `Serializer` to seamlessly parse a color object to JSON and reconstruct it.

function Color:serialize()
    return { __type = "color", arg = self.m_source }
end

---@param t table
function Color.deserialize(t)
    if (type(t) ~= "table" or not t.arg) then
        log.warning("[Color]: Deserialization failed: invalid data!")
        return Color.new("black")
    end

    return Color.new(t.arg)
end

if (Serializer and not Serializer.class_types["color"]) then
    Serializer:RegisterNewType("color", Color.serialize, Color.deserialize)
end
------------------------------------------------------------------------------------------
