---@diagnostic disable: unknown-operator

--------------------------------------
-- Class: vec4
--------------------------------------
-- A 4D vector utility class with arithmetic, geometric, and serialization helpers.
---@class vec4
---@field private assert function
---@field public x number
---@field public y number
---@field public z number
---@field public w number
---@operator add(vec4|number): vec4
---@operator sub(vec4|number): vec4
---@operator mul(vec4|number): vec4
---@operator div(vec4|number): vec4
---@operator unm: vec4
---@operator eq(vec4): boolean
---@operator le(vec4): boolean
---@operator lt(vec4): boolean
vec4 = {}
vec4.__index = vec4
vec4.__type = "vec4"


--------------------------------------
-- Constructors & Utils
--------------------------------------

-- Creates a new vec4 instance.
---@param x number?
---@param y number?
---@param z number?
---@param w number?
---@return vec4
function vec4:new(x, y, z, w)
    local instance = setmetatable({}, vec4)
    instance.x = x or 0
    instance.y = y or 0
    instance.z = z or 0
    instance.w = w or 0
    return instance
end

-- Checks if the given argument is a valid vec4, raises on failure.
---@param arg any
---@return boolean
function vec4:assert(arg)
    if (
        (type(arg) == "table" or type(arg) == "userdata")
        and type(arg.x) == "number"
        and type(arg.y) == "number"
        and type(arg.z) == "number"
        and type(arg.w) == "number"
    ) then
        return true
    else
        error(
            _F("Invalid argument! Expected 4D vector, got %s instead", type(arg))
        )
    end
end

-- Returns a copy of this vector.
---@return vec4
function vec4:copy()
    return vec4:new(self.x, self.y, self.z, self.w)
end

-- Unpacks the components of the vector.
---@return float x, float y, float z, float w
function vec4:unpack()
    return self.x, self.y, self.z, self.w
end

-- Returns a zero vector (0, 0, 0, 0).
---@return vec4
function vec4:zero()
    return vec4:new(0, 0, 0, 0)
end

-- Returns true if all components are zero.
---@return boolean
function vec4:is_zero()
    return (self.x == 0) and (self.y == 0) and (self.z == 0) and (self.w == 0)
end

-- Returns the string representation of the vector
function vec4:__tostring()
    return _F(
        "(%.3f, %.3f, %.3f, %.3f)",
        self.x,
        self.y,
        self.z,
        self.w
    )
end


--------------------------------------
-- Arithmetic Metamethods
--------------------------------------

-- Addition between vectors or vector + number.
---@param b number|vec4
---@return vec4
function vec4:__add(b)
    if type(b) == "number" then
        return vec4:new(self.x + b, self.y + b, self.z + b, self.w + b)
    end

    self:assert(b)
    return vec4:new(self.x + b.x, self.y + b.y, self.z + b.z, self.w + b.w)
end

-- Subtraction between vectors or vector - number.
---@param b number|vec4
---@return vec4
function vec4:__sub(b)
    if type(b) == "number" then
        return vec4:new(self.x - b, self.y - b, self.z - b, self.w - b)
    end

    self:assert(b)
    return vec4:new(self.x - b.x, self.y - b.y, self.z - b.z, self.w - b.w)
end

-- Multiplication between vectors or vector * number.
---@param b number|vec4
---@return vec4
function vec4:__mul(b)
    if type(b) == "number" then
        return vec4:new(self.x * b, self.y * b, self.z * b, self.w * b)
    end

    self:assert(b)
    return vec4:new(self.x * b.x, self.y * b.y, self.z * b.z, self.w * b.w)
end

-- Division between vectors or vector / number.
---@param b number|vec4
---@return vec4
function vec4:__div(b)
    if type(b) == "number" then
        return vec4:new(self.x / b, self.y / b, self.z / b, self.w / b)
    end

    self:assert(b)
    return vec4:new(self.x / b.x, self.y / b.y, self.z / b.z, self.w / b.w)
end

-- Equality check between two vectors.
---@param b vec4
---@return boolean
function vec4:__eq(b)
    self:assert(b)
    return self.x == b.x and self.y == b.y and self.z == b.z and self.w == b.w
end

-- Less-than check between two vectors.
---@param b vec4
---@return boolean
function vec4:__lt(b)
    self:assert(b)
    return self.x < b.x and self.y < b.y and self.z < b.z and self.w < b.w
end

-- Less-or-equal check between two vectors.
---@param b vec4
---@return boolean
function vec4:__le(b)
    self:assert(b)
    return self.x <= b.x and self.y <= b.y and self.z <= b.z and self.w <= b.w
end

-- Unary negation (returns the inverse vector).
---@return vec4
function vec4:__unm()
    return vec4:new(-self.x, -self.y, -self.z, -self.w)
end


--------------------------------------
-- Vector Operations
--------------------------------------

-- Returns the magnitude (length) of the vector.
---@return number
function vec4:length()
    return math.sqrt(self.x ^ 2 + self.y ^ 2 + self.z ^ 2 + self.w ^ 2)
end

-- Returns the distance between this vector and another.
---@param b vec4
---@return number
function vec4:distance(b)
    self:assert(b)
    local dist_x = (self.x - b.x) ^ 2
    local dist_y = (self.y - b.y) ^ 2
    local dist_z = (self.z - b.z) ^ 2
    local dist_w = (self.w - b.w) ^ 2

    return math.sqrt(dist_x + dist_y + dist_z + dist_w)
end

-- Returns a normalized version of the vector.
---@return vec4
function vec4:normalize()
    local len = self:length()

    if len < 1e-8 then
        return vec4:zero()
    end

    return self / len
end

-- Cross product of this vector and another (XYZ components only).
---@param b vec4
---@return vec4
function vec4:cross_product_xyz(b)
    self:assert(b)

    return vec4:new(
        self.y * b.z - self.z * b.y,
        self.z * b.x - self.x * b.z,
        self.x * b.y - self.y * b.x
    )
end

-- Dot product of this vector and another.
---@param b vec4
---@return number
function vec4:dot_product(b)
    self:assert(b)
    return self.x * b.x + self.y * b.y + self.z * b.z + self.w * b.w
end

-- Linearly interpolates between this vector and another.
---@param to vec4
---@param dt number Interpolation factor *(progress/delta time/...)*
---@return vec4
function vec4:lerp(to, dt)
    return vec4:new(
        self.x + (to.x - self.x) * dt,
        self.y + (to.y - self.y) * dt,
        self.z + (to.z - self.z) * dt,
        self.w + (to.w - self.w) * dt
    )
end

-- Returns the inverse (negated) vector.
---@return vec4
function vec4:inverse()
    return vec4:__unm()
end

-- Trims the vector to a maximum length.
---@param atLength number
---@return vec4
function vec4:trim(atLength)
    local len = self:length()
    if len == 0 then
        return vec4:zero()
    end

    local s = atLength / len
    s = (s > 1) and 1 or s
    return self * s
end


--------------------------------------
-- Conversions
--------------------------------------

-- Returns the heading angle (XY plane).
---@return number
function vec4:heading()
    return math.atan(self.y, self.x)
end

-- Returns a new vec4 with the z component replaced.
---@param z number
---@return vec4
function vec4:with_z(z)
    return vec4:new(self.x, self.y, z, self.w)
end

-- Returns a new vec4 with the w component replaced.
---@param w number
---@return vec4
function vec4:with_w(w)
    return vec4:new(self.x, self.y, self.w, w)
end

-- Converts the vector into a plain table (for serialization).
---@return table
function vec4:serialize()
    return {
        __type = self.__type,
        x = self.x or 0,
        y = self.y or 0,
        z = self.z or 0,
        w = self.w or 0
    }
end

-- Deserializes a table into a vec4 **(static method)**.
---@param t { __type: string, x: float, y: float, z: float, w: float }
---@return vec4
function vec4.deserialize(t)
    if (type(t) ~= "table" or not (t.x and t.y and t.z and t.w)) then
        return vec4:zero()
    end

    return vec4:new(t.x, t.y, t.z, t.w)
end


--------------------------------------
-- Conversion Helpers (Optional)
--------------------------------------

if Serializer and not Serializer.class_types["vec4"] then
    Serializer:RegisterNewType("vec4", vec4.serialize, vec4.deserialize)
end

if vec2 then
    ---@return vec2
    function vec4:as_vec2()
        return vec2:new(self.x, self.y)
    end
end

if vec3 then
    ---@return vec3
    function vec4:as_vec3()
        return vec3:new(self.x, self.y, self.z)
    end
end

vec4.magnitude = vec4.length
vec4.mag = vec4.length
