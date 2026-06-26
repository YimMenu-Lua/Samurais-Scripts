-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


--#region locals

local DEBUG_TRACK_SOURCE <const> = false
local INSTANCE_CACHE <const> = setmetatable({}, { __mode = "v" --[[weak]] }) ---@type table<uint32_t, Color>

---@enum eColorType
local eColorType <const> = {
	UNK   = 0,
	FLOAT = 1,
	RGBA  = 2,
	HEX   = 3,
	U32   = 4,
	NAMED = 5
}

---@class Float4
---@field [1] float
---@field [2] float
---@field [3] float
---@field [4] float

---@class UByte4
---@field [1] uint8_t
---@field [2] uint8_t
---@field [3] uint8_t
---@field [4] uint8_t

-- Just for LuaLS autocomplete so we don't have to memorize every field in NamedColors.
---@alias NamedColor
---| "yellow" 		 # 1.000, 1.000, 0.000, 1.000
---| "orange" 		 # 1.000, 0.500, 0.000, 1.000
---| "pink" 		 # 1.000, 0.000, 0.500, 1.000
---| "purple" 		 # 1.000, 0.000, 1.000, 1.000
---| "safety_yellow" # 0.941, 0.745, 0.007, 1.000

local NamedColors <const> = {
	yellow        = { 1.000, 1.000, 0.000, 1.000 },
	orange        = { 1.000, 0.500, 0.000, 1.000 },
	pink          = { 1.000, 0.000, 0.500, 1.000 },
	purple        = { 1.000, 0.000, 1.000, 1.000 },
	safety_yellow = { 0.941, 0.745, 0.007, 1.000 },
}

---@param n number
---@return uint8_t
local function clamp_byte(n)
	return math.floor(math.clamp(n, 0, 255))
end

-- float to ubyte
---@param n float
---@return uint8_t
local function f2i(n)
	if (n > 1) then
		return math.max(n, 255)
	end

	return clamp_byte(n * 255)
end

-- ubyte to float
---@param n uint8_t
---@return float
local function i2f(n)
	if (n <= 1.0) then
		return math.max(n, 0.0)
	end

	return math.clamp(n / 255, 0.0, 1.0)
end

---@param r uint8_t
---@param g uint8_t
---@param b uint8_t
---@param a uint8_t
---@return uint32_t
local function pack4(r, g, b, a)
	a = a or 255
	return (a << 24) | (b << 16) | (g << 8) | r
end

---@param str string
---@return uint8_t, uint8_t, uint8_t, uint8_t
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
---@return uint8_t, uint8_t, uint8_t, uint8_t
local function parse_u32(n)
	assert(type(n) == "number" and (n > 0), _F("Invalid packed color parameter. Expected an unsigned 32bit integer, got '%s' instead.", n))
	return
		n & 0xFF,
		(n >> 8) & 0xFF,
		(n >> 16) & 0xFF,
		(n >> 24) & 0xFF
end

---@param t vec4|UByte4|Float4
---@return float, float, float, float
local function parse_table(t)
	local out = t
	if (t.__type == "vec4") then ---@cast t vec4
		out = { t.x, t.y, t.z, t.w }
	end; out[4] = out[4] or 1

	for i = 1, 4 do
		local v = out[i]
		if (type(v) ~= "number" or v < 0) then
			error("Invalid color parameter. Expected vec4 or array of 4 numbers (ubyte|float).")
		end

		if (v > 1) then
			out[i] = v / 255
		end
	end

	return out[1], out[2], out[3], out[4]
end

-- TODO: refactor this
---@return float, float, float, float, uint32_t, eColorType
local function process_params(...)
	local count = select("#", ...)

	if (count == 1) then
		local v = ...
		local t = type(v)
		if (t == "number") then
			local r, g, b, a = parse_u32(v)
			return r / 255, g / 255, b / 255, a / 255, v, eColorType.U32
		elseif (t == "string") then
			local key   = v:lower()
			local named = NamedColors[key]
			if (named) then
				local r, g, b, a = named[1], named[2], named[3], named[4]
				local u32 = pack4(f2i(r), f2i(g), f2i(b), f2i(a))
				return r, g, b, a, u32, eColorType.NAMED
			end

			local r, g, b, a = parse_hex(key)
			return r / 255, g / 255, b / 255, a / 255, pack4(r, g, b, a), eColorType.HEX
		elseif (t == "table") then
			local r, g, b, a = parse_table(v)
			local u32 = pack4(f2i(r), f2i(g), f2i(b), f2i(a))
			return r, g, b, a, u32, eColorType.FLOAT
		end
	end

	if (count >= 3) then
		local r, g, b, a = ...
		if (r <= 1 and g <= 1 and b <= 1) then
			a = a or 1
			local u32 = pack4(f2i(r), f2i(g), f2i(b), f2i(a))
			return r, g, b, a, u32, eColorType.FLOAT
		else
			a = a or 255
			local u32 = pack4(r, g, b, a)
			return r / 255, g / 255, b / 255, (a or 255) / 255, u32, eColorType.RGBA
		end
	end

	error("[Color]: Invalid argument(s)!")
end

--#endregion


--------------------------------------
-- Class: Color
--------------------------------------
-- Color instances can be created using color name strings either defined in `NamedColors` (ex: `Color("purple")`) or
--
-- self-regsitered (after using the `RegisterNamedColor` method), hex strings, ABGR integers (`uint32`),
--
-- RGBA (`[0 .. 255]`), or normalized RGBA (`[0.0f .. 1.0f]`).
---@class Color : Callable<Color>
---@field private m_type eColorType
---@field private m_source table?
---@field private __raw_ctor fun(r: float, g: float, b: float, a: float, u32?: uint32_t, t?: eColorType): Color
---@field private m_cached_u32 uint32_t
---@field private m_cached_rgba UByte4
---@field private m_cached_hex_fmt string
---@field private m_cached_fmt string
---@field private r float
---@field private g float
---@field private b float
---@field private a float
---@field public BLACK Color
---@field public WHITE Color
---@field public RED Color
---@field public GREEN Color
---@field public BLUE Color
---@overload fun(p0: string|NamedColor): Color
---@overload fun(p0: uint32_t): Color
---@overload fun(p0: vec4<float>): Color
---@overload fun(p0: vec4<uint8_t>): Color
---@overload fun(p0: Float4): Color
---@overload fun(p0: UByte4): Color
---@overload fun(r: uint8_t, g: uint8_t, b: uint8_t, a: uint8_t): Color
---@overload fun(r: float, g: float, b: float, a: float): Color
local Color = Callable("Color", {
	ctor = function(t, ...)
		return t.new(...)
	end
})

---@private
---@param r float
---@param g float
---@param b float
---@param a float
---@param u32? uint32_t
---@param t? eColorType
---@return Color
function Color.__raw_ctor(r, g, b, a, u32, t)
	a            = a or 1.0
	u32          = u32 or pack4(f2i(r), f2i(g), f2i(b), f2i(a))
	local cached = INSTANCE_CACHE[u32]
	if (cached) then
		return cached
	end

	local instance = setmetatable({
		r            = r,
		g            = g,
		b            = b,
		a            = a,
		m_cached_u32 = u32,
		m_type       = t or eColorType.FLOAT,
		---@diagnostic disable-next-line
	}, Color)

	INSTANCE_CACHE[u32] = instance
	return instance
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
---@overload fun(p0: string|NamedColor): Color
---@overload fun(p0: uint32_t): Color
---@overload fun(p0: vec4<float>): Color
---@overload fun(p0: vec4<uint8_t>): Color
---@overload fun(p0: Float4): Color
---@overload fun(p0: UByte4): Color
---@overload fun(r: uint8_t, g: uint8_t, b: uint8_t, a: uint8_t): Color
---@overload fun(r: float, g: float, b: float, a: float): Color
---@param ... any
---@return Color
function Color.new(...)
	if (type(...) == "number") then
		local cached = INSTANCE_CACHE[...]
		if (cached) then
			return cached
		end
	end

	local instance = Color.__raw_ctor(process_params(...))

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

	if (NamedColors[name]) then
		log.fwarning("[Color]: A color with the name '%s' already exists.", name)
		return
	end

	local ok, r, g, b, a = pcall(process_params, ...)
	if (not ok) then
		log.fwarning("[Color]: Failed to register color with name '%s'. Invalid argument(s)", name)
		return
	end

	NamedColors[name] = { r, g, b, a }
end

-- Returns the color in **RGBA** format [0 - 255].
---@return uint8_t, uint8_t, uint8_t, uint8_t
function Color:AsRGBA()
	local cache = self.m_cached_rgba
	if (not cache) then
		cache = {
			f2i(self.r),
			f2i(self.g),
			f2i(self.b),
			f2i(self.a)
		}
		self.m_cached_rgba = cache
	end

	return cache[1], cache[2], cache[3], cache[4]
end

-- Returns the color in **normalized RGBA** format [0 - 1].
---@return float, float, float, float
function Color:AsFloat()
	return self.r, self.g, self.b, self.a
end

-- Returns an unsigned 32bit int representing the color in **ABGR** format.
---@return uint32_t
function Color:AsU32()
	if (not self.m_cached_u32) then
		self.m_cached_u32 = pack4(self:AsRGBA())
	end

	return self.m_cached_u32
end

-- Returns the color as a hexadecimal string.
--
-- Hex strings are **ALWAYS** `RRGGBBAA`.
---@return string
function Color:AsHex()
	if (not self.m_cached_hex_fmt) then
		local r, g, b, a = self:AsRGBA()
		self.m_cached_hex_fmt = _F("#%02X%02X%02X%02X", r, g, b, a)
	end

	return self.m_cached_hex_fmt
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
	return Color.__raw_ctor(
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

	return Color.__raw_ctor(r, g, b, a)
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

	return Color.__raw_ctor(r, g, b, a)
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
	local _gc = Color.GetChannel
	return (0.299 * _gc(r)) + (0.587 * _gc(g)) + (0.114 * _gc(b))
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

	return Color.__raw_ctor(r + m, g + m, b + m, a)
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
	return Color.__raw_ctor(
		math.min(self.r + right.r, 1),
		math.min(self.g + right.g, 1),
		math.min(self.b + right.b, 1),
		math.min(self.a + right.a, 1)
	)
end

---@param right Color
---@return Color
function Color:__sub(right)
	return Color.__raw_ctor(
		math.max(self.r - right.r, 0),
		math.max(self.g - right.g, 0),
		math.max(self.b - right.b, 0),
		math.max(self.a - right.a, 0)
	)
end

---@param right Color
---@return Color
function Color:__mul(right)
	return Color.__raw_ctor(
		math.min(self.r * right.r, 1),
		math.min(self.g * right.g, 1),
		math.min(self.b * right.b, 1),
		math.min(self.a * right.a, 1)
	)
end

---@param right Color
---@return Color
function Color:__div(right)
	return Color.__raw_ctor(
		right.r == 0 and 0 or self.r / right.r,
		right.g == 0 and 0 or self.g / right.g,
		right.b == 0 and 0 or self.b / right.b,
		right.a == 0 and 0 or self.a / right.a

	)
end

---@return string
function Color:__tostring()
	if (not self.m_cached_fmt) then
		local r, g, b, a = self:AsRGBA()
		self.m_cached_fmt = _F(
			"[Color] Float: %.3f %.3f %.3f %.3f | RGBA: %d %d %d %d | Hex: %s | U32: 0x%08X",
			self.r, self.g, self.b, self.a,
			r, g, b, a,
			self:AsHex(),
			self:AsU32()
		)
	end
	return self.m_cached_fmt
end

------------------------------------------------------------------------------------------
-- Helpers for `Serializer` to seamlessly parse a color object to JSON and reconstruct it.

---@return { __type: "color", r: float, g: float, b: float, a: float, u32?: uint32_t }
function Color:serialize()
	return { __type = "color", r = self.r, g = self.g, b = self.b, a = self.a, u32 = self.m_cached_u32 }
end

---@param t { __type: "color", r: float, g: float, b: float, a: float, u32?: uint32_t }
function Color.deserialize(t)
	if (type(t) ~= "table" or t.__type ~= "color") then
		log.warning("[Color]: Deserialization failed: invalid data!")
		return Color.__raw_ctor(0, 0, 0, 0)
	end

	return Color.__raw_ctor(t.r, t.g, t.b, t.a, t.u32)
end

if (Serializer) then
	Serializer:RegisterNewType("color", Color.serialize, Color.deserialize)
end
------------------------------------------------------------------------------------------

_G.Color = Color
return Color
