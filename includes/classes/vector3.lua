---@diagnostic disable

-- Class representing a 3D vector.
---@class vec3
---@field x float x component of the vector.
---@field y float y component of the vector.
---@field z float z component of the vector.
vec3 = {}
vec3.__index = vec3

vec3.__tostring = function(self)
    return string.format(
        "(%s, %s, %s)",
        Lua_fn.floatPrecision(self.x),
        Lua_fn.floatPrecision(self.y),
        Lua_fn.floatPrecision(self.z)
    )
end

---@param arg vec3 | number
---@return vec3
vec3.__add = function(self, arg)
    if isVector3Type(arg) then
        if not getmetatable(arg) == vec3 then
            arg = toVec3(arg)
        end

        return vec3:new(self.x + arg.x, self.y + arg.y, self.z + arg.z)
    elseif type(arg) == 'number' then
        return vec3:new(self.x + arg, self.y + arg, self.z + arg)
    else
        error(string.format("Attempt to perform arithmetic on a %s value", type(arg)))
    end
end

---@param arg vec3 | number
---@return vec3
vec3.__sub = function(self, arg)
    if isVector3Type(arg) then
        if not getmetatable(arg) == vec3 then
            arg = toVec3(arg)
        end

        return vec3:new(self.x - arg.x, self.y - arg.y, self.z - arg.z)
    elseif type(arg) == 'number' then
        return vec3:new(self.x - arg, self.y - arg, self.z - arg)
    else
        error(string.format("Attempt to perform arithmetic on a %s value", type(arg)))
    end
end

---@param arg vec3 | number
---@return vec3
vec3.__mul = function(self, arg)
    if isVector3Type(arg) then
        if not getmetatable(arg) == vec3 then
            arg = toVec3(arg)
        end

        return vec3:new(self.x * arg.x, self.y * arg.y, self.z * arg.z)
    elseif type(arg) == 'number' then
        return vec3:new(self.x * arg, self.y * arg, self.z * arg)
    else
        error(string.format("Attempt to perform arithmetic on a %s value", type(arg)))
    end
end

---@param arg vec3 | number
---@return vec3
vec3.__div = function(self, arg)
    if isVector3Type(arg) then
        if not getmetatable(arg) == vec3 then
            arg = toVec3(arg)
        end

        return vec3:new(self.x / arg.x, self.y / arg.y, self.z / arg.z)
    elseif type(arg) == 'number' then
        return vec3:new(self.x / arg, self.y / arg, self.z / arg)
    else
        error(string.format("Attempt to perform arithmetic on a %s value", type(arg)))
    end
end

---@param arg vec3
---@return boolean
vec3.__eq = function(self, arg)
    if isVector3Type(arg) then
        if not getmetatable(arg) == vec3 then
            arg = toVec3(arg)
        end

        return
            (self.x <= arg.x and (arg.x <= self.x)) and
            (self.y <= arg.y and (arg.y <= self.y)) and
            (self.z <= arg.z and (arg.z <= self.z))
    else
        error(string.format("Attempt to compare 3D vector with %s value", type(arg)))
    end

    return false
end

---@param arg vec3
---@return boolean
vec3.__le = function(self, arg)
    if isVector3Type(arg) then
        if not getmetatable(arg) == vec3 then
            arg = toVec3(arg)
        end

        return
            (self.x <= arg.x) and
            (self.y <= arg.y) and
            (self.z <= arg.z)
    else
        error(string.format("Attempt to compare 3D vector with %s value", type(arg)))
    end

    return false
end

---@param arg vec3
---@return boolean
vec3.__lt = function(self, arg)
    if isVector3Type(arg) then
        if not getmetatable(arg) == vec3 then
            arg = toVec3(arg)
        end

        return
            (self.x <= arg.x and not (arg.x <= self.x)) and
            (self.y <= arg.y and not (arg.y <= self.y)) and
            (self.z <= arg.z and not (arg.z <= self.z))
    else
        error(string.format("Attempt to compare 3D vector with %s value", type(arg)))
    end

    return false
end

-- Constructor

-- Returns: `vec3`: a vector containing x, y, and z values.
---**Example Usage:**
---```lua
---myInstance = vec3:new(x, y, z)
---```
---@param x float x component of the vector.
---@param y float y component of the vector.
---@param z float z component of the vector.
---@return vec3
function vec3:new(x, y, z)
    local instance = setmetatable({}, vec3)
    instance.x = x or 0
    instance.y = y or 0
    instance.z = z or 0

    return instance
end

-- Returns a zero vector.
function vec3:zero()
    return vec3:new(0, 0, 0)
end

---@param includeZ? boolean
function vec3:inverse(includeZ)
    return vec3:new(-self.x, -self.y, includeZ and -self.z or self.z)
end

-- Calculates the distance between two 3D vectors
---@param from vec3
---@param to vec3
function vec3:distance(from, to)
    local dist_x = (to.x - from.x) ^ 2
    local dist_y = (to.y - from.y) ^ 2
    local dist_z = (to.z - from.z) ^ 2

    return math.sqrt(dist_x + dist_y + dist_z)
end

-- Performs linear interpolation between source and destination vectors
---@param dest vec3
---@param deltaTime integer
function vec3:lerp(src, dest, deltaTime)
    return vec3:new(
        src.x + (dest.x - src.x) * deltaTime,
        src.y + (dest.y - src.y) * deltaTime,
        src.z + (dest.z - src.z) * deltaTime
    )
end

-- Returns a 2D vector from a 3D vector.
---@return vec2
function vec3:as_vec2()
    return vec2:new(self.x, self.y)
end

--
--#region
-- helpers
--

-- Allows arithmetic and relational operations
--
-- between 3D vectors.
--
---@param arg table | userdata
function toVec3(arg)
    if not getmetatable(arg) and type(arg) ~= 'table' then
        error(string.format("Expected sol.rage::scrVector or table value, got %s instead.", type(arg)), 2)
    end

    if (type(arg.x) ~= 'number' and type(arg.y) ~= 'number' and type(arg.z) ~= 'number') then
        error("Argument is not a 3D vector.")
    end

    return vec3:new(arg.x, arg.y, arg.z)
end

function isVector3Type(arg)
    return (type(arg) == 'table' or type(arg) == 'userdata') and
        (type(arg.x) == 'number' and type(arg.y) == 'number' and type(arg.z) == 'number')
end

--
--#endregion
--
