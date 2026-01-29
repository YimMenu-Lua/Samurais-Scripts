-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


--------------------------------------
-- Class: Mutex
--------------------------------------
-- Simple mutual exclusion.
---@class Mutex
---@field protected m_locked boolean
---@overload fun(): Mutex
local Mutex = {}
Mutex.__index = Mutex
---@diagnostic disable-next-line
setmetatable(Mutex, {
	__call = function(_)
		return Mutex.new()
	end
})

---@return Mutex
function Mutex.new()
	---@diagnostic disable-next-line
	return setmetatable({ m_locked = false }, Mutex)
end

function Mutex:Acquire()
	while (self.m_locked) do
		yield()
	end

	self.m_locked = true
end

function Mutex:Release()
	self.m_locked = false
end

-- Scoped lock.
---@param func function
---@param ... any
---@return ...
function Mutex:WithLock(func, ...)
	self:Acquire()
	local ret = { xpcall(func, function(msg)
		self:Release()
		error(msg)
	end, ...) }
	self:Release()
	return table.unpack(ret)
end

return Mutex
