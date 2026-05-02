-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local IManagedValueEntry = require("includes.structs.IManagedValueEntry")


-----------------------------------------------------
-- IManagedValueController
-----------------------------------------------------
-- Registers and monitors `Tuneable` objects.
---@class IManagedValueController
---@field private m_items dict<IManagedValueEntry>
---@field private m_count integer
---@field private m_running boolean
---@field private m_force_next_call boolean
---@field private m_initialized boolean
local IManagedValueController <const> = {}
IManagedValueController.__index       = IManagedValueController

---@param items? dict<IManagedValueCtorData>
---@return IManagedValueController
function IManagedValueController.new(items)
	local hasItems = items ~= nil and next(items) ~= nil
	local instance = setmetatable({
		m_items           = {},
		m_count           = 0,
		m_running         = false,
		m_force_next_call = false,
		m_initialized     = not hasItems
	}, IManagedValueController)

	if (hasItems) then
		ThreadManager:Run(function()
			for name, data in pairs(items or {}) do
				instance:Append(name, data)
			end
			---@diagnostic disable-next-line: invisible
			instance.m_initialized = true
		end)
	end

	return instance
end

---@return integer
function IManagedValueController:GetItemCount()
	return self.m_count
end

---@param name string
---@return IManagedValueEntry?
function IManagedValueController:GetEntry(name)
	return self.m_items[name]
end

---@param name string
---@param data_t IManagedValueCtorData
---@return boolean success
function IManagedValueController:Append(name, data_t)
	if (self.m_items[name]) then
		log.fwarning("A ManagedValue with the name %s is alreayd registered!", name)
		return false
	end

	self.m_items[name] = IManagedValueEntry.new(name, data_t)
	self.m_count       = self.m_count + 1
	return true
end

---@param name string
---@param state boolean
function IManagedValueController:SetDirty(name, state)
	local entry = self.m_items[name]
	if (not entry) then return end
	entry:SetDirty(state)
end

---@param state boolean
function IManagedValueController:SetNextCallForced(state)
	self.m_force_next_call = state
end

---@param name string
function IManagedValueController:Remove(name)
	self.m_items[name] = nil
	self.m_count       = math.max(0, self.m_count - 1)
end

---@param func fun(entry: IManagedValueEntry): any
function IManagedValueController:ForEach(func)
	if (self.m_count == 0) then return end

	self.m_running = true
	for _, entry in pairs(self.m_items) do
		func(entry)
	end
	self.m_running = false
end

function IManagedValueController:Reset()
	self:ForEach(function(entry) entry:Reset() end)
end

function IManagedValueController:OnCall()
	if (self.m_running or not self.m_initialized) then return end
	self:ForEach(function(entry) entry:OnCall(self.m_force_next_call) end)
	self.m_force_next_call = false
end

-- We should probably make this a single shared instance so that other modules can use the same object, not just YRV3
return IManagedValueController
