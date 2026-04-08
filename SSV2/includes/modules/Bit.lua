-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-----------------------------------------
-- Bit (Static)
-----------------------------------------
-- Primitive bitwise wrapper.
---@ignore [Unfinished]
---@class Bit
local Bit = {}
Bit.__index = Bit

---@param n integer
---@param pos integer
function Bit.Get(n, pos)
	return (n >> pos) & 1
end

---@param n integer
---@param pos integer
---@return integer
function Bit.Set(n, pos)
	return n | (1 << pos)
end

---@param n integer
---@param pos integer
---@return integer
function Bit.Clear(n, pos)
	return n & ~(1 << pos)
end

---@param n integer
---@param pos integer
---@param toggle boolean
---@return integer
function Bit.Toggle(n, pos, toggle)
	local f = toggle and Bit.Set or Bit.Clear
	return f(n, pos)
end

---@param n integer
---@param pos integer
---@return boolean
function Bit.IsBitSet(n, pos)
	return (n & (1 << pos)) ~= 0
end

---@param n integer
---@param s integer
---@return integer
function Bit.LeftShift(n, s)
	return n << s
end

---@param n integer
---@param s integer
---@return integer
function Bit.RightShift(n, s)
	return n >> s
end

---@param n integer
---@param bits integer
---@return integer
function Bit.LeftRotate(n, bits)
	return ((n << bits) | (n >> (32 - bits))) & 0xFFFFFFFF
end

---@param n integer
---@param bits integer
---@return integer
function Bit.RightRotate(n, bits)
	return ((n >> bits) | (n << (32 - bits))) & 0xFFFFFFFF
end

return Bit
