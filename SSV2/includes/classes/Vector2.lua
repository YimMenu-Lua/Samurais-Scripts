-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@diagnostic disable: unknown-operator

--------------------------------------
-- Class: vec2
--------------------------------------
-- A 2D vector utility class with arithmetic, geometric, and serialization helpers.
---@class vec2
---@field private assert function
---@field public x float
---@field public y float
---@operator add(vec2|number): vec2
---@operator sub(vec2|number): vec2
---@operator mul(vec2|number): vec2
---@operator div(vec2|number): vec2
---@operator unm: vec2
---@operator eq(vec2): boolean
---@operator le(vec2): boolean
---@operator lt(vec2): boolean
vec2 = {}
vec2.__index = vec2
vec2.__type = "vec2"


--------------------------------------
-- Constructors & Utils
--------------------------------------

-- Creates a new vec2 instance.
---@param x float
---@param y float
---@return vec2
function vec2:new(x, y)
	return setmetatable(
		{
			x = x or 0,
			y = y or 0
		},
		vec2
	)
end

-- Checks if the given argument is a valid vec2, raises on failure.
---@param arg any
---@return boolean
function vec2:assert(arg)
	if (type(arg) == "table" or type(arg) == "userdata") and type(arg.x) == "number" and type(arg.y) == "number" then
		return true
	else
		error(
			_F("Invalid argument! Expected 2D vector, got %s instead", type(arg))
		)
	end
end

-- Returns a copy of this vector.
---@return vec2
function vec2:copy()
	return vec2:new(self.x, self.y)
end

-- Unpacks the components of the vector.
---@return float x, float y
function vec2:unpack()
	return self.x, self.y
end

-- Returns a zero vector (0, 0).
---@return vec2
function vec2:zero()
	return vec2:new(0, 0)
end

-- Returns true if all components are zero.
---@return boolean
function vec2:is_zero()
	return (self.x == 0) and (self.y == 0)
end

-- Returns the string representation of the vector
function vec2:__tostring()
	return _F(
		"(%.3f, %.3f)",
		self.x,
		self.y
	)
end

--------------------------------------
-- Arithmetic Metamethods
--------------------------------------

-- Addition between vectors or vector + number.
---@param b number|vec2
---@return vec2
function vec2:__add(b)
	if type(b) == "number" then
		return vec2:new(self.x + b, self.y + b)
	end

	self:assert(b)
	return vec2:new(self.x + b.x, self.y + b.y)
end

-- Subtraction between vectors or vector - number.
---@param b number|vec2
---@return vec2
function vec2:__sub(b)
	if type(b) == "number" then
		return vec2:new(self.x - b, self.y - b)
	end

	self:assert(b)
	return vec2:new(self.x - b.x, self.y - b.y)
end

-- Multiplication between vectors or vector * number.
---@param b number|vec2
---@return vec2
function vec2:__mul(b)
	if type(b) == "number" then
		return vec2:new(self.x * b, self.y * b)
	end

	self:assert(b)
	return vec2:new(self.x * b.x, self.y * b.y)
end

-- Division between vectors or vector / number.
---@param b number|vec2
---@return vec2
function vec2:__div(b)
	if type(b) == "number" then
		return vec2:new(self.x / b, self.y / b)
	end

	self:assert(b)
	return vec2:new(self.x / b.x, self.y / b.y)
end

-- Equality check between two vectors.
---@param b number|vec2
---@return boolean
function vec2:__eq(b)
	self:assert(b)
	return self.x == b.x and self.y == b.y
end

-- Less-than check between two vectors.
---@param b number|vec2
---@return boolean
function vec2:__lt(b)
	self:assert(b)
	return self.x < b.x and self.y < b.y
end

-- Less-or-equal check between two vectors.
---@param b number|vec2
---@return boolean
function vec2:__le(b)
	self:assert(b)
	return self.x <= b.x and self.y <= b.y
end

-- Unary negation (returns the inverse vector).
---@return vec2
function vec2:__unm()
	return vec2:new(-self.x, -self.y)
end

--------------------------------------
-- Vector Operations
--------------------------------------

-- Returns the magnitude (length) of the vector.
---@return number
function vec2:length()
	return math.sqrt(self.x ^ 2 + self.y ^ 2)
end

-- Returns the distance between this vector and another.
---@param b vec2
---@return number
function vec2:distance(b)
	self:assert(b)

	local dist_x = (self.x - b.x) ^ 2
	local dist_y = (self.y - b.y) ^ 2

	return math.sqrt(dist_x + dist_y)
end

-- Returns a normalized version of the vector.
---@return vec2
function vec2:normalize()
	local len = self:length()

	if len < 1e-8 then
		return vec2:new(0, 0)
	end

	return self / len
end

-- Cross product of this vector and another.
---@return number
function vec2:cross_product(b)
	self:assert(b)
	return self.x * b.y - self.y * b.x
end

-- Dot product of this vector and another.
---@return number
function vec2:dot_product(b)
	self:assert(b)
	return self.x * b.x + self.y * b.y
end

-- Linearly interpolates between this vector and another.
---@param b vec2
---@param dt number Delta time
---@return vec2
function vec2:lerp(b, dt)
	return vec2:new(
		self.x + (b.x - self.x) * dt,
		self.y + (b.y - self.y) * dt
	)
end

-- Returns the inverse (negated) vector.
---@return vec2
function vec2:inverse()
	return self:__unm()
end

-- Returns a vec2 perpendicular to this.
---@return vec2
function vec2:perpendicular()
	return vec2:new(-self.y, self.x)
end

-- Returns the arc tangent of y/x in radians.
---@return number
function vec2:angle()
	return math.atan(self.y, self.x)
end

-- Rotates the vector.
---@param n number
---@return vec2
function vec2:rotate(n)
	local a, b = math.cos(n), math.sin(n)

	return vec2:new(
		a * self.x - b * self.y,
		b * self.x + a * self.y
	)
end

-- Trims the vector to a maximum length.
---@param atLength number
---@return vec2
function vec2:trim(atLength)
	local len = self:length()

	if (len == 0) then
		return vec2:zero()
	end

	local s = atLength / len

	s = (s > 1) and 1 or s
	return self * s
end

--------------------------------------
-- Conversions
--------------------------------------

-- Returns the angle and radius of the vector.
---@return number angle, number radius
function vec2:to_polar()
	return math.atan(self.y, self.x), self:length()
end

-- Creates a new vec2 from angle and radius.
---@param angle number
---@param radius? number
---@return vec2
function vec2:from_polar(angle, radius)
	radius = radius or 1
	return vec2:new(math.cos(angle) * radius, math.sin(angle) * radius)
end

-- Converts the vector into a plain table (for serialization).
---@return table
function vec2:serialize()
	return {
		__type = self.__type,
		x = self.x or 0,
		y = self.y or 0
	}
end

-- Deserializes a table into a vec3 **(static method)**.
---@param t { x: float, y: float }
function vec2.deserialize(t)
	if (type(t) ~= "table" or not (t.x and t.y)) then
		return vec2:zero()
	end

	return vec2:new(t.x, t.y)
end

--------------------------------------
-- Conversion Helpers (Optional)
--------------------------------------

if Serializer and not Serializer.class_types["vec2"] then
	Serializer:RegisterNewType("vec2", vec2.serialize, vec2.deserialize)
end

vec2.magnitude = vec2.length
vec2.magn = vec2.length
