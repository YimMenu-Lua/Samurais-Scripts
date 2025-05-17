---@diagnostic disable

---@class vec3
---@field x float
---@field y float
---@field z float
vec3 = {}
vec3.__index = vec3

setmetatable(vec3, {
    __call = function(_, arg)
        return vec3:new(arg.x, arg.y, arg.z)
    end
})

---@param x float
---@param y float
---@param z float
function vec3:new(x, y, z)
    return setmetatable(
        {
            x = x or 0,
            y = y or 0,
            z = z or 0
        },
        self
    )
end

function vec3:zero()
    return vec3:new(0, 0, 0)
end

function vec3:__tostring()
    return string.format(
        "(%.3f, %.3f, %.3f)",
        self.x,
        self.y,
        self.z
    )
end

---@param b number|vec3
---@return vec3
function vec3:__add(b)
    if type(b) == "number" then
        return vec3:new(self.x + b, self.y + b, self.z + b)
    end

    b = toVec3(b)
    return vec3:new(self.x + b.x, self.y + b.y, self.z + b.z)
end

---@param b number|vec3
---@return vec3
function vec3:__sub(b)
    if type(b) == "number" then
        return vec3:new(self.x - b, self.y - b, self.z - b)
    end

    b = toVec3(b)
    return vec3:new(self.x - b.x, self.y - b.y, self.z - b.z)
end

---@param b number|vec3
---@return vec3
function vec3:__mul(b)
    if type(b) == "number" then
        return vec3:new(self.x * b, self.y * b, self.z * b)
    end

    b = toVec3(b)
    return vec3:new(self.x * b.x, self.y * b.y, self.z * b.z)
end

---@param b number|vec3
---@return vec3
function vec3:__div(b)
    if type(b) == "number" then
        return vec3:new(self.x / b, self.y / b, self.z / b)
    end

    b = toVec3(b)
    return vec3:new(self.x / b.x, self.y / b.y, self.z / b.z)
end

---@param b number|vec3
---@return vec3
function vec3:__eq(b)
    b = toVec3(b)
    return self.x == b.x and self.y == b.y and self.z == b.z
end

---@param b number|vec3
---@return vec3
function vec3:__lt(b)
    b = toVec3(b)
    return self.x < b.x and self.y < b.y and self.z < b.z
end

---@param b number|vec3
---@return vec3
function vec3:__le(b)
    b = toVec3(b)
    return self.x <= b.x and self.y <= b.y and self.z <= b.z
end

---@return number
function vec3:length()
    return math.sqrt(self.x^2 + self.y^2 + self.z^2)
end

---@param b vec3
---@return number
function vec3:dot(b)
    b = toVec3(b)

    return self.x * b.x + self.y * b.y + self.z * b.z
end

---@param to vec3
---@return number
function vec3:distance(to)
    to = toVec3(to)

    local dist_x = (self.x - to.x)^2
    local dist_y = (self.y - to.y)^2
    local dist_z = (self.z - to.z)^2

    return math.sqrt(dist_x + dist_y + dist_z)
end

---@return vec3
function vec3:normalize()
    local len = self:length()

    if len < 1e-8 then
        return vec3:zero()
    end

    return self / len
end

---@param b vec3
---@return vec3
function vec3:cross(b)
    b = toVec3(b)

    return vec3:new(
        self.y * b.z - self.z * b.y,
        self.z * b.x - self.x * b.z,
        self.x * b.y - self.y * b.x
    )
end

---@param to vec3
---@param alpha number
---@return vec3
function vec3:lerp(to, alpha)
    return vec3:new(
        self.x + (to.x - self.x) * alpha,
        self.y + (to.y - self.y) * alpha,
        self.z + (to.z - self.z) * alpha
    )
end

---@param includeZ? boolean
---@return vec3
function vec3:inverse(includeZ)
    return vec3:new(-self.x, -self.y, includeZ and -self.z or self.z)
end

---@return vec3
function vec3:copy()
    return vec3:new(self.x, self.y, self.z)
end

---@return boolean
function vec3:is_zero()
    return self.x == 0 and self.y == 0 and self.z == 0
end

---@return vec2
function vec3:as_vec2()
    return vec2:new(self.x, self.y)
end

---@param arg vec3|table|userdata
---@return vec3
function toVec3(arg)
    if (type(arg) == "table") or (type(arg) == "userdata") and arg.x and arg.y and arg.z then
        return vec3:new(arg.x, arg.y, arg.z)
    else
        error(
            string.format("Invalid argument. Expected 3D vector, got %s instead", type(arg))
        )
    end
end
