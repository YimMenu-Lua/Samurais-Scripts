-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local DEBUG_TRACK_SOURCE <const> = false

---@enum eColorType
local eColorType <const> = {
	UNK   = 0,
	FLOAT = 1,
	RGBA  = 2,
	HEX   = 3,
	U32   = 4,
	NAMED = 5
}

local NamedColors = {
	yellow = { 1.0, 1.0, 0.0, 1.0 },
	orange = { 1.0, 0.5, 0.0, 1.0 },
	pink   = { 1.0, 0.0, 0.5, 1.0 },
	purple = { 1.0, 0.0, 1.0, 1.0 },
}

---@param n number
---@return integer
local function clamp_byte(n)
	return math.floor(math.clamp(n, 0, 255))
end

---@return integer, integer, integer, integer
local function parse_hex(str)
	str = str:gsub("#", "")
	if (#str) == 3 then
		str = string.rep(str:sub(1), 2)
			.. string.rep(str:sub(2), 2)
			.. string.rep(str:sub(3), 2)
	end

	if (#str == 6) then str = str .. "FF" end
	if (#str ~= 8) then return 0, 0, 0, 0 end

	return
		tonumber(str:sub(1, 2), 16),
		tonumber(str:sub(3, 4), 16),
		tonumber(str:sub(5, 6), 16),
		tonumber(str:sub(7, 8), 16)
end

---@param n uint32_t
---@return integer, integer, integer, integer
local function parse_u32(n)
	return
		n & 0xFF,
		(n >> 8) & 0xFF,
		(n >> 16) & 0xFF,
		(n >> 24) & 0xFF
end

---@return float, float, float, float, eColorType
local function process_params(...)
	local count = select("#", ...)

	if (count == 1) then
		local v = ...
		local t = type(v)
		if (t == "number") then
			local r, g, b, a = parse_u32(v)
			return r / 255, g / 255, b / 255, a / 255, eColorType.U32
		elseif (t == "string") then
			local key   = v:lower()
			local named = Color.m_named_colors[key]
			if (named) then
				return named[1], named[2], named[3], named[4], eColorType.NAMED
			end

			local r, g, b, a = parse_hex(key)
			return r / 255, g / 255, b / 255, a / 255, eColorType.HEX
		elseif (t == "table" and v.__type == "vec4") then
			return v.x, v.y, v.z, v.w, eColorType.FLOAT
		end
	end

	if (count >= 3) then
		local r, g, b, a = ...
		if (r <= 1 and g <= 1 and b <= 1) then
			return r, g, b, a or 1, eColorType.FLOAT
		else
			return r / 255, g / 255, b / 255, (a or 255) / 255, eColorType.RGBA
		end
	end

	error("[Color]: unsupported arguments")
end


--------------------------------------
-- Class: Color
--------------------------------------
-- Color instances can be created using color name strings either defined in `NamedColors` (ex: `Color("purple")`) or
--
-- self-regsitered (after using the `RegisterNamedColor` method), hex strings, ABGR integers (`uint32`),
--
-- RGBA (`[0 .. 255]`), or normalized RGBA (`[0.0f .. 1.0f]`).
---@class Color
---@field private m_type eColorType
---@field private m_source table?
---@field private m_named_colors dict<{ [1]: float, [2]: float, [3]: float, [4]: float }>
---@field private __raw_ctor fun(r: float, g: float, b: float, a: float): Color
---@field public r float
---@field public g float
---@field public b float
---@field public a float
---@field public BLACK Color
---@field public WHITE Color
---@field public RED Color
---@field public GREEN Color
---@field public BLUE Color
---@overload fun(p0: string): Color
---@overload fun(p0: uint32_t): Color
---@overload fun(p0: vec4): Color
---@overload fun(r: integer, g: integer, b: integer, a: integer): Color
---@overload fun(r: float, g: float, b: float, a: float): Color
Color = Class("Color")
Color.m_named_colors = NamedColors

---@private
---@param r float
---@param g float
---@param b float
---@param a float
---@return Color
function Color.__raw_ctor(r, g, b, a)
	return setmetatable({
		r = r,
		g = g,
		b = b,
		a = a,
		m_type = eColorType.FLOAT
		---@diagnostic disable-next-line: param-type-mismatch
	}, Color)
end

-- Constant basic colors for easy access.

Color.BLACK = Color.__raw_ctor(0, 0, 0, 1)
Color.WHITE = Color.__raw_ctor(1, 1, 1, 1)
Color.RED   = Color.__raw_ctor(1, 0, 0, 1)
Color.GREEN = Color.__raw_ctor(0, 1, 0, 1)
Color.BLUE  = Color.__raw_ctor(0, 0, 1, 1)

-------------------------------------------

-- Returns a new `Color` instance.
--
-- **NOTE:** Hex strings must be either `RGB` *(shorthand)* or `RRGGBB` or `RRGGBBAA`. No weird CSS formats.
---@overload fun(p0: string): Color
---@overload fun(p0: uint32_t): Color
---@overload fun(p0: vec4): Color
---@overload fun(r: integer, g: integer, b: integer, a: integer): Color
---@overload fun(r: float, g: float, b: float, a: float): Color
---@param ... any
---@return Color
function Color.new(...)
	local r, g, b, a, t = process_params(...)
	local instance      = Color.__raw_ctor(r, g, b, a)
	instance.m_type     = t

	if (DEBUG_TRACK_SOURCE) then
		instance.m_source = { ... }
	end

	return instance
end

-- Registers new named colors in the class itself.
--
-- **Example:**
--
-- ```lua
-- -- We call this anywhere once.
-- Color:RegisterNamedColor("MAGENTA", "#FF00FF")
--
-- -- Now "Magenta" can be used anywhere any time (case-insensitive).
-- local r, g, b, a = Color("magenta"):AsRGBA()
-- ```
---@param name string
---@param ... any
function Color:RegisterNamedColor(name, ...)
	name = name:lower()

	if (Color.m_named_colors[name]) then
		log.fwarning("[Color]: '%s' already exists.", name)
		return
	end

	local ok, r, g, b, a = pcall(process_params, ...)
	if (not ok) then
		log.fwarning("[Color]: Failed to register named color '%s'. Invalid color argument(s)", name)
		return
	end

	Color.m_named_colors[name] = { r, g, b, a }
end

-- Returns the color in **RGBA** format [0 - 255].
---@return integer, integer, integer, integer
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
--
-- Hex strings are **ALWAYS** `RRGGBBAA`.
---@return string
function Color:AsHex()
	local r, g, b, a = self:AsRGBA()
	return string.format("#%02X%02X%02X%02X", r, g, b, a)
end

---@param normalize? boolean Normalize to `[0 .. 1]`
---@return vec4
function Color:AsVec4(normalize)
	if (normalize) then
		return vec4:new(self:AsFloat())
	end

	return vec4:new(self:AsRGBA())
end

-- Mixes two colors by factor `f`.
--
-- Note: This does not mutate. It returns a new `Color` instanec.
---@param c Color color to mix with
---@param f float factor
function Color:Mix(c, f)
	return self.__raw_ctor(
		self.r + (c.r - self.r) * f,
		self.g + (c.g - self.g) * f,
		self.b + (c.b - self.b) * f,
		self.a
	)
end

-- Returns a new instance. Does not mutate.
---@param f float -- factor
---@param includeAlpha? boolean
---@return Color
function Color:Darken(f, includeAlpha)
	local r = math.clamp(self.r - f, 0, 1)
	local g = math.clamp(self.g - f, 0, 1)
	local b = math.clamp(self.b - f, 0, 1)
	local a = self.a
	if (includeAlpha) then
		a = math.clamp(a - f, 0, 1)
	end

	return self.__raw_ctor(r, g, b, a)
end

-- Returns a new instance. Does not mutate.
---@param f float -- factor
---@param includeAlpha? boolean
---@return Color
function Color:Brighten(f, includeAlpha)
	local r = math.clamp(self.r + f, 0, 1)
	local g = math.clamp(self.g + f, 0, 1)
	local b = math.clamp(self.b + f, 0, 1)
	local a = self.a
	if (includeAlpha) then
		a = math.clamp(a + f, 0, 1)
	end

	return self.__raw_ctor(r, g, b, a)
end

-- Returns the luminance of the color *(brightness)*.
--
-- https://www.w3.org/TR/AERT/#color-contrast
---@return float
function Color:GetBrightness()
	return (0.299 * self.r) + (0.587 * self.g) + (0.114 * self.b)
end

-- https://stackoverflow.com/a/56678483
---@return float
function Color:GetRelativeLuminance()
	local r = self.GetChannel(self.r)
	local g = self.GetChannel(self.g)
	local b = self.GetChannel(self.b)

	return (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
end

-- Returns the contrast ratio between two colors.
---@param other Color
---@return float
function Color:GetContrastRatio(other)
	local L1 = self:GetRelativeLuminance()
	local L2 = other:GetRelativeLuminance()
	if (L1 < L2) then
		L1, L2 = L2, L1
	end

	return (L1 + 0.05) / (L2 + 0.05)
end

---@return boolean
function Color:IsBright()
	return self:GetBrightness() > 0.5
end

---@return boolean
function Color:IsDark()
	return not self:IsBright()
end

---------------------------------------------------------------------------------
-- Static Methods/Helpers
---------------------------------------------------------------------------------

-- Calculates the brightness of any given color in normalized RGB format
--
-- https://www.w3.org/TR/AERT/#color-contrast
---@param r float
---@param g float
---@param b float
---@return float
function Color.CalculateBrightness(r, g, b, _)
	return (0.299 * r) + (0.587 * g) + (0.114 * b)
end

-- https://stackoverflow.com/a/56678483
---@param v float
---@return float
function Color.GetChannel(v)
	if (v <= 0.03928) then
		return v / 12.92
	end

	return ((v + 0.055) / 1.055) ^ 2.4
end

-- Returns a `Color` instance from HSV
---@param h number
---@param s number
---@param v number
---@param a? number
---@return Color
function Color.FromHSV(h, s, v, a)
	a = a or 1
	if (a > 1) then
		a = math.clamp(a / 255, 0, 1)
	end

	if (s <= 0) then
		return Color(v, v, v, a)
	end

	h = h * 6
	local c = v * s
	local x = (1 - math.abs((h % 2) - 1)) * c
	local m = v - c
	local r, g, b = 0, 0, 0

	if (h < 1) then
		r, g, b = c, x, 0
	elseif h < 2 then
		r, g, b = x, c, 0
	elseif h < 3 then
		r, g, b = 0, c, x
	elseif h < 4 then
		r, g, b = 0, x, c
	elseif h < 5 then
		r, g, b = x, 0, c
	else
		r, g, b = c, 0, x
	end

	return Color(r + m, g + m, b + m, a)
end

---------------------------------------------------------------------------------
-- Math Operators
---------------------------------------------------------------------------------

---@param right Color
---@return boolean
function Color:__eq(right)
	return self:AsU32() == right:AsU32()
end

---@param right Color
---@return Color
function Color:__add(right)
	return self.__raw_ctor(
		math.min(self.r + right.r, 1),
		math.min(self.g + right.g, 1),
		math.min(self.b + right.b, 1),
		math.min(self.a + right.a, 1)
	)
end

---@param right Color
---@return Color
function Color:__sub(right)
	return self.__raw_ctor(
		math.max(self.r - right.r, 0),
		math.max(self.g - right.g, 0),
		math.max(self.b - right.b, 0),
		math.max(self.a - right.a, 0)
	)
end

---@param right Color
---@return Color
function Color:__mul(right)
	return self.__raw_ctor(
		math.min(self.r * right.r, 1),
		math.min(self.g * right.g, 1),
		math.min(self.b * right.b, 1),
		math.min(self.a * right.a, 1)
	)
end

---@param right Color
---@return Color
function Color:__div(right)
	return self.__raw_ctor(
		right.r == 0 and 0 or self.r / right.r,
		right.g == 0 and 0 or self.g / right.g,
		right.b == 0 and 0 or self.b / right.b,
		right.a == 0 and 0 or self.a / right.a

	)
end

function Color:__tostring()
	local r, g, b, a = self:AsRGBA()
	return string.format(
		"[Color] Float: %.3f %.3f %.3f %.3f | RGBA: %d %d %d %d | Hex: %s | U32: 0x%X",
		self.r, self.g, self.b, self.a,
		r, g, b, a,
		self:AsHex(),
		self:AsU32()
	)
end

------------------------------------------------------------------------------------------
-- Helpers for `Serializer` to seamlessly parse a color object to JSON and reconstruct it.

function Color:serialize()
	return { __type = "color", r = self.r, g = self.g, b = self.b, a = self.a }
end

---@param t { __type: "color", r: float, g: float, b: float, a: float }
function Color.deserialize(t)
	if (type(t) ~= "table" or t.__type ~= "color") then
		log.warning("[Color]: Deserialization failed: invalid data!")
		return Color.__raw_ctor(0, 0, 0, 0)
	end

	return Color.__raw_ctor(t.r, t.g, t.b, t.a)
end

if (Serializer) then
	Serializer:RegisterNewType("color", Color.serialize, Color.deserialize)
end
------------------------------------------------------------------------------------------
