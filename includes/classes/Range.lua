---@diagnostic disable: param-type-mismatch

--------------------------------------
-- Class: Range
--------------------------------------
-- A simple `Range` utiliy.
---@ignore -- manual docs
---@class Range
---@field private m_min number
---@field private m_max number
---@field private m_step number
---@overload fun(from: number, to: number, step?: number): Range
Range = {}
Range.__index = Range
setmetatable(Range, {
    __call = function(_, from, to, step)
        return Range.new(from, to, step)
    end
})

---@param from number
---@param to number
---@param step? number
---@return Range
function Range.new(from, to, step)
    step = step or 1
    assert(type(from) == "number" and type(to) == "number", "Range requires numeric from/to")
    assert(step ~= 0, "Step cannot be 0")

    return setmetatable({
        m_min = from,
        m_max = to,
        m_step = step,
    }, Range)
end

---@param value number
---@return boolean
function Range:Contains(value)
    if (self.m_step > 0) then
        return value >= self.m_min and value <= self.m_max -- or math.inrange(value, self.m_min, self.m_max)
    else
        return value <= self.m_min and value >= self.m_max
    end
end

---@return fun(): number Iterator
function Range:Iter()
    local current = self.m_min - self.m_step
    return function()
        current = current + self.m_step
        if (self.m_step > 0 and current <= self.m_max)
        or (self.m_step < 0 and current >= self.m_max) then
            return current
        ---@diagnostic disable-next-line
        end
    end
end

-- Lua-style sugar: `for i in range() do ... end`
---@return fun(): number Iterator
function Range:__call()
    return self:Iter()
end

function Range:__tostring()
    return ("Range(%d, %d, %d)"):format(self.m_min, self.m_max, self.m_step)
end

function Range:__contains(value)
    return self:Contains(value)
end

return Range
