---@diagnostic disable

---@class vec2
---@field x float
---@field y float
vec2 = {}
vec2.__index = vec2

setmetatable(vec2, {
    __call = function(_, arg)
        return vec2:new(arg.x, arg.y)
    end
})

---@param x float
---@param y float
---@return vec2
function vec2:new(x, y)
    return setmetatable(
        {
            x = x or 0,
            y = y or 0
        },
        self
    )
end

---@return vec2
function vec2:zero()
    return vec2:new(0, 0)
end

function vec2:__tostring()
    return string.format(
        "(%.3f, %.3f)",
        self.x,
        self.y
    )
end

---@param b number|vec3
---@return vec2
function vec2:__add(b)
    if type(b) == "number" then
        return vec2:new(self.x + b, self.y + b)
    end

    b = toVec2(b)
    return vec2:new(self.x + b.x, self.y + b.y)
end

---@param b number|vec3
---@return vec2
function vec2:__sub(b)
    if type(b) == "number" then
        return vec2:new(self.x - b, self.y - b)
    end

    b = toVec2(b)
    return vec2:new(self.x - b.x, self.y - b.y)
end

---@param b number|vec3
---@return vec2
function vec2:__mul(b)
    if type(b) == "number" then
        return vec2:new(self.x * b, self.y * b)
    end

    b = toVec2(b)
    return vec2:new(self.x * b.x, self.y * b.y)
end

---@param b number|vec3
---@return vec2
function vec2:__div(b)
    if type(b) == "number" then
        return vec2:new(self.x / b, self.y / b)
    end

    b = toVec2(b)
    return vec2:new(self.x / b.x, self.y / b.y)
end

---@param b number|vec3
---@return vec2
function vec2:__eq(b)
    b = toVec2(b)
    return self.x == b.x and self.y == b.y
end

---@param b number|vec3
---@return vec2
function vec2:__lt(b)
    b = toVec2(b)
    return self.x < b.x and self.y < b.y
end

---@param b number|vec3
---@return vec2
function vec2:__le(b)
    b = toVec2(b)
    return self.x <= b.x and self.y <= b.y
end

---@return number
function vec2:length()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

---@return number
function vec2:dot(b)
    b = toVec2(b)
    return self.x * b.x + self.y * b.y
end

---@return vec2
function vec2:normalize()
    local len = self:length()

    if len < 1e-8 then
        return vec2:new(0, 0)
    end

    return self / len
end

---@return vec2
function vec2:inverse()
    return ve2:new(-self.x, -self.y)
end

---@return vec2
function vec2:clone()
    return vec2:new(self.x, self.y)
end

---@return boolean
function vec2:is_zero()
    return self.x == 0 and self.y == 0
end

---@return vec2
function toVec2(arg)
    if (type(arg) == "table" or type(arg) == "userdata") and arg.x and arg.y then
        return vec2:new(arg.x, arg.y)
    else
        error(
            string.format("Invalid argument. Expected 2D vector, got %s instead", type(arg))
        )
    end
end
