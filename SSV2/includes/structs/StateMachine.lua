-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class StateMachineParams
---@field predicate? Predicate<StateMachine, table|metatable|userdata|lightuserdata>
---@field interval? seconds
---@field callback? fun(self: StateMachine, context: table|metatable|userdata|lightuserdata)
local StateMachineParams = {}

---@class StateMachine
---@field private m_is_active boolean
---@field private m_is_toggled boolean state flip
---@field private m_callback Callback<StateMachine, table|metatable|userdata|lightuserdata>
---@field private m_predicate Predicate<StateMachine, table|metatable|userdata|lightuserdata>
---@field private m_interval seconds
---@field private m_next_update seconds
---@overload fun(opts?: StateMachineParams) : StateMachine
local StateMachine = {}
StateMachine.__index = StateMachine
---@diagnostic disable-next-line
setmetatable(StateMachine, {
	__call = function(_, ...)
		return StateMachine:new(...)
	end
})

---@param opts StateMachineParams
function StateMachine:new(opts)
	return setmetatable({
		m_predicate = opts.predicate,
		m_interval = opts.interval or 0,
		m_callback = opts.callback,
		m_is_active = false,
		m_is_toggled = false,
		m_next_update = 0
		---@diagnostic disable-next-line
	}, StateMachine)
end

---@param context table|metatable|userdata|lightuserdata
function StateMachine:Update(context)
	local should_be_active = not self.m_predicate or self:m_predicate(context)

	if (not should_be_active) then
		self.m_is_active = false
		self.m_is_toggled = false
		return
	end

	if (not self.m_is_active) then
		self.m_is_active = true
		self.m_is_toggled = false
		self.m_next_update = Time.now() + self.m_interval
	end

	if (Time.now() >= self.m_next_update) then
		self.m_is_toggled = not self.m_is_toggled
		self.m_next_update = Time.now() + self.m_interval
	end

	if (self.m_is_toggled and self.m_callback) then
		self.m_callback(self, context)
	end
end

-- Manual

function StateMachine:Activate()
	self.m_is_active = true
	self.m_next_update = Time.now()
end

function StateMachine:Reset()
	self.m_is_toggled = false
	self.m_next_update = 0
end

---@param t seconds
function StateMachine:UpdateInterval(t)
	self.m_interval = t
end

---@param t seconds
function StateMachine:SetNextUpdateTime(t)
	self.m_next_update = t
end

---@return seconds
function StateMachine:GetNextUpdate()
	return self.m_next_update
end

function StateMachine:Toggle()
	self.m_is_toggled = not self.m_is_toggled
end

---@return boolean
function StateMachine:IsActive()
	return self.m_is_active
end

---@return boolean
function StateMachine:IsToggled()
	return self.m_is_toggled
end

return StateMachine
