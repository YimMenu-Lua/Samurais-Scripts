-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@diagnostic disable: unknown-operator

--------------------------------------
-- Class: vec3
--------------------------------------
-- A 3D vector utility class with arithmetic, geometric, and serialization helpers.
---@class vec3
---@field private assert function
---@operator add(vec3|number): vec3
---@operator sub(vec3|number): vec3
---@operator mul(vec3|number): vec3
---@operator div(vec3|number): vec3
---@operator unm: vec3
---@operator eq(vec3): boolean
---@operator le(vec3): boolean
---@operator lt(vec3): boolean

vec3.__type = "vec3"

--------------------------------------
-- Constructors & Utils
--------------------------------------
-- ctor and __tostring are defined in YimMenu, hence their absence here.

-- Checks if the given argument is a valid vec3, raises on failure.
---@param arg any
---@return boolean
function vec3:assert(arg)
	if (type(arg) == "table") or (type(arg) == "userdata") and type(arg.x) == "number" and type(arg.y) == "number" and type(arg.z) == "number" then
		return true
	else
		error(
			_F("Invalid argument. Expected 3D vector, got %s instead", type(arg))
		)
	end
end

-- Returns a copy of this vector.
---@return vec3
function vec3:copy()
	return vec3:new(self.x, self.y, self.z)
end

-- Unpacks the components of the vector.
---@return float x, float y, float z
function vec3:unpack()
	return self.x, self.y, self.z
end

-- Returns a zero vector (0, 0, 0).
---@return vec3
function vec3:zero()
	return vec3:new(0, 0, 0)
end

-- Returns true if all components are zero.
---@return boolean
function vec3:is_zero()
	return (self.x == 0) and (self.y == 0) and (self.z == 0)
end

--------------------------------------
-- Arithmetic Metamethods
--------------------------------------

-- Addition between vectors or vector + number.
---@param b number|vec3
---@return vec3
function vec3:__add(b)
	if type(b) == "number" then
		return vec3:new(self.x + b, self.y + b, self.z + b)
	end

	self:assert(b)
	return vec3:new(self.x + b.x, self.y + b.y, self.z + b.z)
end

-- Subtraction between vectors or vector - number.
---@param b number|vec3
---@return vec3
function vec3:__sub(b)
	if type(b) == "number" then
		return vec3:new(self.x - b, self.y - b, self.z - b)
	end

	self:assert(b)
	return vec3:new(self.x - b.x, self.y - b.y, self.z - b.z)
end

-- Multiplication between vectors or vector * number.
---@param b number|vec3
---@return vec3
function vec3:__mul(b)
	if type(b) == "number" then
		return vec3:new(self.x * b, self.y * b, self.z * b)
	end

	self:assert(b)
	return vec3:new(self.x * b.x, self.y * b.y, self.z * b.z)
end

-- Division between vectors or vector / number.
---@param b number|vec3
---@return vec3
function vec3:__div(b)
	if type(b) == "number" then
		return vec3:new(self.x / b, self.y / b, self.z / b)
	end

	self:assert(b)
	return vec3:new(self.x / b.x, self.y / b.y, self.z / b.z)
end

-- Equality check between two vectors.
---@param b number|vec3
---@return boolean
function vec3:__eq(b)
	self:assert(b)
	return self.x == b.x and self.y == b.y and self.z == b.z
end

-- Less-than check between two vectors.
---@param b number|vec3
---@return boolean
function vec3:__lt(b)
	self:assert(b)
	return self.x < b.x and self.y < b.y and self.z < b.z
end

-- Less-or-equal check between two vectors.
---@param b number|vec3
---@return boolean
function vec3:__le(b)
	self:assert(b)
	return self.x <= b.x and self.y <= b.y and self.z <= b.z
end

-- Unary negation (returns the inverse vector).
---@return vec3
function vec3:__unm()
	return vec3:new(-self.x, -self.y, -self.z)
end

--------------------------------------
-- Vector Operations
--------------------------------------

-- Returns the magnitude (length) of the vector.
---@return float
function vec3:length()
	return math.sqrt(self.x ^ 2 + self.y ^ 2 + self.z ^ 2)
end

-- Returns the distance between this vector and another.
---@param b vec3
---@return float
function vec3:distance(b)
	self:assert(b)
	local dist_x = (self.x - b.x) ^ 2
	local dist_y = (self.y - b.y) ^ 2
	local dist_z = (self.z - b.z) ^ 2

	return math.sqrt(dist_x + dist_y + dist_z)
end

-- Returns a normalized version of the vector.
---@return vec3
function vec3:normalize()
	local len = self:length()

	if len < 1e-8 then
		return vec3:zero()
	end

	return self / len
end

-- Cross product of this vector and another.
---@param b vec3
---@return vec3
function vec3:cross_product(b)
	self:assert(b)

	return vec3:new(
		self.y * b.z - self.z * b.y,
		self.z * b.x - self.x * b.z,
		self.x * b.y - self.y * b.x
	)
end

-- Dot product of this vector and another.
---@param b vec3
---@return number
function vec3:dot_product(b)
	self:assert(b)
	return self.x * b.x + self.y * b.y + self.z * b.z
end

-- Linearly interpolates between this vector and another.
---@param to vec3
---@param dt number Delta time
---@return vec3
function vec3:lerp(to, dt)
	return vec3:new(
		self.x + (to.x - self.x) * dt,
		self.y + (to.y - self.y) * dt,
		self.z + (to.z - self.z) * dt
	)
end

-- Returns the inverse (negated) vector.
---@param includeZ? boolean Whether to also negate the z component
---@return vec3
function vec3:inverse(includeZ)
	return vec3:new(-self.x, -self.y, includeZ and -self.z or self.z)
end

-- Trims the vector to a maximum length.
---@return vec3
function vec3:trim(atLength)
	local len = self:length()
	if len == 0 then
		return vec3:zero()
	end

	local s = atLength / len
	s = (s > 1) and 1 or s
	return self * s
end

--------------------------------------
-- Conversions
--------------------------------------

-- Returns the compass heading (0 - 360).
--
-- Heading is measured from +Y (forward) around the Z axis.
--
-- This differs from vec2:angle(), which measures from +X using
--
-- the standard math convention.
---@return float
function vec3:heading()
	return (math.deg(math.atan(self.x, self.y)) + 360) % 360
end

-- Returns a new vec3 with the z component replaced.
---@param z float
---@return vec3
function vec3:with_z(z)
	return vec3:new(self.x, self.y, z)
end

-- Converts a rotation vector to direction
---@return vec3
function vec3:to_direction()
	local radians = self * (math.pi / 180)
	return vec3:new(
		-math.sin(radians.z) * math.abs(math.cos(radians.x)),
		math.cos(radians.z) * math.abs(math.cos(radians.x)),
		math.sin(radians.x)
	)
end

-- Converts the vector into a plain table (for serialization).
---@return table
function vec3:serialize()
	return {
		__type = self.__type,
		x = self.x or 0,
		y = self.y or 0,
		z = self.z or 0
	}
end

-- Deserializes a table into a vec3 **(static method)**.
---@param t { __type: string, x: float, y: float, z: float }
---@return vec3
function vec3.deserialize(t)
	if (type(t) ~= "table" or not (t.x and t.y and t.z)) then
		return vec3:zero()
	end

	return vec3:new(t.x, t.y, t.z)
end

--------------------------------------
-- Conversion Helpers (Optional)
--------------------------------------

if Serializer and not Serializer.class_types["vec3"] then
	Serializer:RegisterNewType("vec3", vec3.serialize, vec3.deserialize)
end

if vec2 then
	---@return vec2
	function vec3:as_vec2()
		return vec2:new(self.x, self.y)
	end
end

vec3.magnitude = vec3.length
vec3.mag = vec3.length
