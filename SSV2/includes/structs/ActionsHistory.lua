-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Mutex = require("includes.classes.Mutex")

---@alias ActionHistorySortMode
---| 0 Timestamp
---| 1 Type
---| 2 Label

---@class ActionsHistoryEntry
---@field action Action
---@field timestamp seconds
---@field type eActionType
---@field fmt string


---@class ActionsHistory
---@field private m_count integer
---@field private m_sort_mode ActionHistorySortMode
---@field private m_data array<ActionsHistoryEntry>
---@field protected m_lookup_set set<string>
---@field protected m_mutex Mutex
local ActionsHistory <const> = {}
ActionsHistory.__index = ActionsHistory

---@return ActionsHistory
function ActionsHistory.new()
	return setmetatable({
		m_count      = 0,
		m_sort_mode  = 0,
		m_data       = {},
		m_lookup_set = {},
		m_mutex      = Mutex.new(),
	}, ActionsHistory)
end

---@return boolean
function ActionsHistory:IsLocked()
	return self.m_mutex:IsLocked()
end

---@return array<ActionsHistoryEntry>
function ActionsHistory:GetData()
	return self.m_data
end

---@return integer
function ActionsHistory:GetCount()
	return self.m_count
end

---@return ActionHistorySortMode
function ActionsHistory:GetSortMode()
	return self.m_sort_mode
end

---@param action Action
function ActionsHistory:Push(action)
	local label = action.data.label
	local set   = self.m_lookup_set
	if (set[label]) then return end

	table.insert(self.m_data, {
		action    = action,
		timestamp = DateTime:Now():Epoch(),
		type      = action.action_type,
		fmt       = _F("[%s]  %s", action:TypeAsString(), label),
	})

	set[label]   = true
	self.m_count = #self.m_data
	self:Sort()
end

---@param index integer
function ActionsHistory:Pop(index)
	local count = self.m_count
	if (count == 0 or index > count) then
		return
	end

	if (count == 1) then
		self.m_data       = {}
		self.m_lookup_set = {}
		self.m_count      = 0
		return
	end

	---@type ActionsHistoryEntry?
	local entry = table.remove(self.m_data, index)
	if (entry) then
		self.m_lookup_set[entry.action.data.label] = nil
	end
	self.m_count = math.max(0, count - 1)
end

function ActionsHistory:Clear()
	if (self:IsLocked()) then return end

	local count = self.m_count
	if (count == 0) then return end

	ThreadManager:Run(function()
		self.m_mutex:WithLock(function()
			local array         = self.m_data
			local totalDuration = 200
			local remaining     = count
			for i = count, 1, -1 do
				table.remove(array, i)

				local delta = remaining / count
				local delay = math.max(1, math.floor(totalDuration * (delta * delta) / count))
				yield(delay)
				remaining = remaining - 1
			end
			self.m_count      = 0
			self.m_lookup_set = {}
		end)
	end)
end

---@param mode ActionHistorySortMode?
function ActionsHistory:Sort(mode)
	if (self:IsLocked()) then return end
	if (mode and mode == self.m_sort_mode) then return end

	mode = mode or self.m_sort_mode
	table.sort(self.m_data, function(a, b)
		if (mode == 0) then
			return a.timestamp > b.timestamp
		elseif (mode == 1) then
			return a.type < b.type
		end

		return a.action.data.label < b.action.data.label
	end)
	self.m_sort_mode = mode
end

---@return fun(data: array<ActionsHistoryEntry>, i?: integer): integer, ActionsHistoryEntry Iterator
---@return array<ActionsHistoryEntry> data
---@return integer index
function ActionsHistory:Iter()
	return ipairs(self.m_data)
end

return ActionsHistory
