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
-- Simple mutual exclusivity.
---@class Mutex
---@field protected m_locked boolean
---@overload fun(): Mutex
local Mutex = Callable("Mutex")

---@return Mutex
function Mutex.new()
	return MakeInstance({ m_locked = false }, Mutex)
end

---@return boolean
function Mutex:IsLocked()
	return self.m_locked
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
---@generic R1, R2, R3, R4, R5
---@param func fun(...?: any): R1?, R2?, R3?, R4?, R5?, ...?
---@param ... any
---@return boolean success, R1?, R2?, R3?, R4?, R5?, ...?
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
