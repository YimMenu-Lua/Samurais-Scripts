-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


--------------------------------------
-- Class: Rect
--------------------------------------
---@class Rect
---@field min vec2
---@field max vec2
---@overload fun(min: vec2, max: vec2) : Rect
Rect = {}
Rect.__index = Rect
---@diagnostic disable-next-line
setmetatable(Rect, {
	__call = function(_, ...)
		return Rect.new(...)
	end
})

---@param min vec2
---@param max vec2
---@return Rect
function Rect.new(min, max)
	---@diagnostic disable-next-line
	return setmetatable({ min = min, max = max }, Rect)
end

---@return float
function Rect:GetWidth()
	return self.max.x - self.min.x
end

---@return float
function Rect:GetHeight()
	return self.max.y - self.min.y
end

---@return vec2
function Rect:GetSize()
	return vec2:new(
		self.max.x - self.min.x,
		self.max.y - self.min.y
	)
end

---@return float
function Rect:GetArea()
	return (self.max.x - self.min.x) * (self.max.y - self.min.y)
end

---@return vec2
function Rect:GetCenter()
	return vec2:new(
		(self.min.x + self.max.x) * 0.5,
		(self.min.y + self.max.y) * 0.5
	)
end

---@param point vec2
---@return boolean
function Rect:Contains(point)
	return
		point.x >= self.min.x and
		point.x <= self.max.x and
		point.y >= self.min.y and
		point.y <= self.max.y
end

---@param point vec2
---@return Rect
function Rect:AddPoint(point)
	local min = vec2:new(math.min(self.min.x, point.x), math.min(self.min.y, point.y))
	local max = vec2:new(math.max(self.max.x, point.x), math.max(self.max.y, point.y))
	return Rect(min, max)
end

---@param other_rect Rect
---@return Rect
function Rect:Add(other_rect)
	local min = vec2:new(math.min(self.min.x, other_rect.min.x), math.min(self.min.y, other_rect.min.y))
	local max = vec2:new(math.max(self.max.x, other_rect.max.x), math.max(self.max.y, other_rect.max.y))
	return Rect(min, max)
end

---@param other Rect
---@return Rect
function Rect:__add(other)
	return self:Add(other)
end
