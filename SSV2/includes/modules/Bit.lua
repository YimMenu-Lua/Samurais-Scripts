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
---@ignore [Unfinished]
---@class Bit
local Bit = {}
Bit.__index = Bit

---@param n integer
---@param pos integer
Bit.Get = function(n, pos)
	return (n >> pos) & 1
end

---@param n integer
---@param pos integer
---@return integer
Bit.Set = function(n, pos)
	return n | (1 << pos)
end

---@param n integer
---@param pos integer
---@return integer
Bit.Clear = function(n, pos)
	return n & ~(1 << pos)
end

---@param n integer
---@param pos integer
---@return boolean
Bit.IsBitSet = function(n, pos)
	return (n & (1 << pos)) ~= 0
end

---@param n integer
---@param s integer
---@return integer
Bit.LeftShift = function(n, s)
	return n << s
end

---@param n integer
---@param s integer
---@return integer
Bit.RightShift = function(n, s)
	return n >> s
end

---@param n integer
---@param bits integer
---@return integer
Bit.RotateLeft = function(n, bits)
	return ((n << bits) | (n >> (32 - bits))) & 0xFFFFFFFF
end

---@param n integer
---@param bits integer
---@return integer
Bit.RotateRight = function(n, bits)
	return ((n >> bits) | (n << (32 - bits))) & 0xFFFFFFFF
end

return Bit
