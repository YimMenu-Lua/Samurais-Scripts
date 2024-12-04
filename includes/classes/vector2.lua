---@diagnostic disable
---@meta
---Class representing a 2D vector.
---@class vec2
---@field x float x component of the vector.
---@field y float y component of the vector.
vec2 = {}
vec2.__index = vec2
vec2.__tostring = function(self)
  return string.format(
    "(%s, %s)",
    Lua_fn.floatPrecision(self.x),
    Lua_fn.floatPrecision(self.y)
  )
end

---@param arg vec2 | number
---@return vec2
vec2.__add = function(self, arg)
  if isVector2Type(arg) then
    if not getmetatable(arg) == vec2 then
      arg = toVec2(arg)
    end

    return vec2:new(self.x + arg.x, self.y + arg.y)

  elseif type(arg) == 'number' then
    return vec2:new(self.x + arg, self.y + arg)

  else
    error(string.format("Attempt to perform arithmetic on a %s value", type(arg)))
  end
end

---@param arg vec2 | number
---@return vec2
vec2.__sub = function(self, arg)
  if isVector2Type(arg) then
    if not getmetatable(arg) == vec2 then
      arg = toVec2(arg)
    end

    return vec2:new(self.x - arg.x, self.y - arg.y)

  elseif type(arg) == 'number' then

    return vec2:new(self.x - arg, self.y - arg)

  else
    error(string.format("Attempt to perform arithmetic on a %s value", type(arg)))
  end
end

---@param arg vec2 | number
---@return vec2
vec2.__mul = function(self, arg)
  if isVector2Type(arg) then
    if not getmetatable(arg) == vec2 then
      arg = toVec2(arg)
    end

    return vec2:new(self.x * arg.x, self.y * arg.y)

  elseif type(arg) == 'number' then

    return vec2:new(self.x * arg, self.y * arg)

  else
    error(string.format("Attempt to perform arithmetic on a %s value", type(arg)))
  end
end

---@param arg vec2 | number
---@return vec2
vec2.__div = function(self, arg)
  if isVector2Type(arg) then
    if not getmetatable(arg) == vec2 then
      arg = toVec2(arg)
    end

    return vec2:new(self.x / arg.x, self.y / arg.y)

  elseif type(arg) == 'number' then

    return vec2:new(self.x / arg, self.y / arg)

  else
    error(string.format("Attempt to perform arithmetic on a %s value", type(arg)))
  end
end

---@param arg vec2
---@return boolean
vec2.__eq = function(self, arg)
  if isVector2Type(arg) then
    if not getmetatable(arg) == vec2 then
      arg = toVec2(arg)
    end

    return getmetatable(arg) == vec2 and
    (self.x <= arg.x and (arg.x <= self.x)) and
    (self.y <= arg.y and (arg.y <= self.y))

  else
    error(string.format("Attempt to compare 2D vector with %s value", type(arg)))
  end

  return false
end

---@param arg vec2
---@return boolean
vec2.__le = function(self, arg)
  if isVector2Type(arg) then
    if not getmetatable(arg) == vec2 then
      arg = toVec2(arg)
    end

    return getmetatable(arg) == vec2 and
    (self.x <= arg.x) and
    (self.y <= arg.y)

  else
    error(string.format("Attempt to compare 2D vector with %s value", type(arg)))
  end

  return false
end

---@param arg vec2
---@return boolean
vec2.__lt = function(self, arg)
  if isVector2Type(arg) then
    if not getmetatable(arg) == vec2 then
      arg = toVec2(arg)
    end

    return getmetatable(arg) == vec2 and
    (self.x <= arg.x and not (arg.x <= self.x)) and
    (self.y <= arg.y and not (arg.y <= self.y))

  else
    error(string.format("Attempt to compare 2D vector with %s value", type(arg)))
  end

  return false
end

-- Constructor
--
-- Returns `vec2`: A 2D vector containing x and y values.
--
-- **Example Usage:**
-- ```lua
-- myInstance = vec2:new(x, y)
-- ```
---@param x float x component of the vector.
---@param y float y component of the vector.
---@return vec2
function vec2:new(x, y)
  local instance = setmetatable({}, vec2)
  instance.x = x or 0
  instance.y = y or 0

  return instance
end

function vec2:inverse()

  return vec2:new(-self.x, -self.y)
end

--
--#region
-- helpers
--

-- Converts vector2 objects to a custom vec2 class.
--
-- You can perform arithmetic and relational operations
--
-- directly on vector2 tables or vector2 returns from
--
-- GTA native calls.
-- 
---@param arg table | userdata
function toVec2(arg)
  if not getmetatable(arg) and type(arg) ~= 'table' then
    error(string.format("Expected sol.rage::scrVector or table value, got %s instead.", type(arg)), 2)
  end

  if (type(arg.x) ~= 'number' and type(arg.y) ~= 'number') then
    error("Argument is not a 2D vector.")
  end

  return vec2:new(arg.x, arg.y)
end


function isVector2Type(arg)
  return
  (type(arg) == 'table' or type(arg) == 'userdata') and
  (type(arg.x) == 'number' and type(arg.y) == 'number')
end

--
--#endregion
--
