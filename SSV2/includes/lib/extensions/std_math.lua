-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Cast      = require("includes.modules.Cast")
local fmt       = string.format
local std_abs   = math.abs
local std_floor = math.floor
local std_ceil  = math.ceil
local std_cos   = math.cos
local std_max   = math.max
local std_min   = math.min
local std_sin   = math.sin
local std_sqrt  = math.sqrt

---@param n float
---@param x integer number of decimal points
---@return number
function math.round(n, x)
	return tonumber(fmt("%." .. (x or 0) .. "f", n)) or 0
end

---@param ... any Varargs or array of numbers.
---@return number
function math.sum(...)
	local result = 0
	local args   = type(...) == "table" and ... or { ... }
	local __len  = #args
	if (__len == 0) then return 0 end

	for i = 1, __len do
		if (type(args[i]) == "number") then
			result = result + args[i]
		end
	end

	return result
end

---@param n number|nil
---@return boolean
function math.is_null(n)
	return type(n) ~= "number" or n == 0
end

---@param n number
---@param min number
---@param max number
---@return boolean
function math.is_inrange(n, min, max)
	return n >= min and n <= max
end

-- This ignores floating point precision.
--
-- For normal numbers, use regular equality comparison.
--
-- https://www.lua.org/pil/2.3.html
---@param a float
---@param b float
---@param e? float Optional epsilon (threshold)
---@return boolean
function math.is_equal(a, b, e)
	e = e or 1e-6
	return a == b or std_abs(a - b) < e
end

local INT_SIZES <const>     = {
	int8_t   = 0x1,
	int16_t  = 0x2,
	int32_t  = 0x4,
	int64_t  = 0x8,
	uint8_t  = 0x1,
	uint16_t = 0x2,
	uint32_t = 0x4,
	uint64_t = 0x8,
}
local INT_INFERENCE <const> = {
	["unsigned"] = {
		{ Cast.AsUint8,  "uint8_t" },
		{ Cast.AsUint16, "uint16_t" },
		{ Cast.AsUint32, "uint32_t" },
		{ Cast.AsUint64, "uint64_t" },
	},
	["signed"] = {
		{ Cast.AsInt8,  "int8_t" },
		{ Cast.AsInt16, "int16_t" },
		{ Cast.AsInt32, "int32_t" },
		{ Cast.AsInt64, "int64_t" },
	}
}

-- Returns the symbolic size of the number, not actual size in memory.
---@param n integer
function math.sizeof(n)
	local t_n = type(n)
	assert(t_n == "number",
		_F("Attempt to call math.sizeof on an invalid value. Number expected, got %s instead!", t_n)
	)

	if (n == 0 or math.type(n) == "float") then
		return 0x4
	end

	local c   = Cast(n)
	local key = n < 0 and "signed" or "unsigned"
	local _t  = INT_INFERENCE[key]
	for i = 1, #_t do
		local method, size_key = _t[i][1], _t[i][2]
		local value            = method(c)
		if (math.is_equal(n, value, 1e-9)) then
			return INT_SIZES[size_key]
		end
	end
	return 0x4
end

---@param v number
---@param min number
---@param max number
---@return number
function math.clamp(v, min, max)
	return std_max(min, std_min(max, v))
end

-- Returns a value between 0.0 and 1.0 representing the min/max normalization of `v`
---@param v number
---@param min number minimum value
---@param max number maximum value
function math.ratio(v, min, max)
	return (v - min) / (max - min)
end; math.normalize = math.ratio

---@param a number
---@param b number
---@param delta float `0.0 .. 1.0`
---@return float
function math.lerp(a, b, delta)
	delta = math.clamp(delta, 0, 1)
	return a + (b - a) * delta
end

-- https://easings.net
---@param delta float `0.0 .. 1.0`
---@return float
function math.ease_in_quad(delta)
	delta = math.clamp(delta, 0, 1)
	return delta * delta
end

-- https://easings.net
---@param delta float `0.0 .. 1.0`
---@return float
function math.ease_out_quad(delta)
	delta = math.clamp(delta, 0, 1)
	return 1 - (1 - delta) * (1 - delta)
end

-- https://easings.net
---@param delta float `0.0 .. 1.0`
---@return float
function math.ease_in_out_quad(delta)
	delta = math.clamp(delta, 0, 1)
	if (delta > 0.5) then
		return ((-2 * delta + 2) ^ 2) / 2
	end

	return 2 * delta * delta
end

-- Generates a triangular wave oscillating between -1 and 1
---@param t number
---@return number
function math.tent(t)
	return 2 * std_abs(2 * (t - std_floor(t + 0.5))) - 1
end

-- 3x² - 2x²
---@param x number
---@return number
function math.smooth_step(x)
	return x * x * (3 - 2 * x)
end

---@return -2147483648
function math.int32_min()
	return -2147483648
end

---@return 2147483647
function math.int32_max()
	return 2147483647
end

---@return 0
function math.uint32_min()
	return 0
end

---@return 4294967295
function math.uint32_max()
	return 4294967295
end
