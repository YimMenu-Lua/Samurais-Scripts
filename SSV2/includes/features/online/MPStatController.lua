-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local DATA <const>            = require("includes.data.stat_controller_data")
local PStats <const>          = DATA.MPStats
local StatFuncsByType <const> = DATA.Resolvers

---@alias MPStatCtorData { type: string, autolock?: boolean, lock_val?: anyval }


---@class MPStat
---@field private m_get fun(statName: string): anyval
---@field private m_set fun(statName: string, v: anyval)
---@field private m_fmt fun(v: anyval): string
---@field private m_value anyval
---@field public m_lock_val anyval
---@field public m_name string
---@field public m_type string
---@field public value_buffer anyval
---@field public autolock boolean
local MPStat <const> = {}
MPStat.__index       = MPStat

---@param name string
---@param data MPStatCtorData
function MPStat.new(name, data)
	local _type   = data.type
	local funcs_t = StatFuncsByType[_type] or StatFuncsByType.default
	return setmetatable({
		m_name     = name,
		m_type     = _type,
		m_get      = funcs_t.get,
		m_set      = funcs_t.set,
		m_fmt      = funcs_t.fmt,
		m_lock_val = data.lock_val,
		autolock   = data.autolock or false,
	}, MPStat)
end

---@param refresh? boolean
function MPStat:Get(refresh)
	if (refresh) then
		self.m_value = self.m_get(self.m_name)
	elseif (self.m_value == nil) then
		self.m_value = self.m_get(self.m_name)
	end

	return self.m_value
end

function MPStat:Set(v)
	self.m_set(self.m_name, v)
	self.m_value = v
end

function MPStat:LockValue()
	local value   = self.m_lock_val
	local current = self:Get(true)
	if (value == nil) then
		self.m_lock_val = current
		return
	end

	if (current == value) then
		return
	end

	self:Set(value)
end

---@return { name: string, type: string, autolock?: boolean, lock_val?: anyval }
function MPStat:Serialize()
	return {
		name     = self.m_name,
		type     = self.m_type,
		autolock = self.autolock,
		lock_val = self.m_lock_val
	}
end

function MPStat:Format()
	return self.m_fmt(self:Get())
end

---@class MPStatController
---@field private m_stats dict<MPStat>
---@field private m_stat_order array<string>
---@field private m_filename "mp_stats.json"
---@field private m_last_tick TimePoint
---@field protected m_initialized boolean
local MPStatController <const> = {
	m_stats      = {},
	m_stat_order = {},
	m_filename   = "mp_stats.json"
}; MPStatController.__index = MPStatController

---@return MPStatController
function MPStatController:init()
	if (self.m_initialized) then return self end

	self.m_last_tick = TimePoint()
	local fname      = self.m_filename
	if (not io.exists(fname)) then
		Serializer:WriteToFile(fname, PStats)
	end

	self:FetchStats()
	ThreadManager:RegisterLooped("SS_MP_STAT_CONTROLLER", function()
		self:OnTick()
	end)

	self.m_initialized = true
	return self
end

function MPStatController:FetchStats()
	for name, data in pairs(PStats) do
		self.m_stats[name] = MPStat.new(name, data)
		table.insert(self.m_stat_order, name)
	end

	local jsondata = Serializer:ReadFromFile(self.m_filename)
	if (type(jsondata) ~= "table") then return end ---@cast jsondata dict<MPStatCtorData>

	for name, data in pairs(jsondata) do
		local existing = self.m_stats[name]
		if (existing) then
			existing.autolock = data.autolock or false
			if (data.lock_val ~= nil) then
				existing.m_lock_val = data.lock_val
			end
		else
			self.m_stats[name] = MPStat.new(name, data)
			table.insert(self.m_stat_order, name)
		end
	end
end

---@return dict<MPStat>
function MPStatController:GetStats()
	return self.m_stats
end

---@return array<string>
function MPStatController:GetStatsOrder()
	return self.m_stat_order
end

function MPStatController:SaveStats()
	local buff = {}
	for name, mpStat in pairs(self.m_stats) do
		buff[name] = mpStat:Serialize()
	end

	Serializer:WriteToFile(self.m_filename, buff)
end

---@param data { name: string, type: string, autolock?: boolean, lock_val?: anyval }
function MPStatController:Add(data)
	local statName = data.name
	local list     = self.m_stats
	if (list[statName]) then
		log.fwarning("[MPStatController]: A multiplayer stat with the name '%s' already exists! Use the search bar in the StatController UI to find it.", statName)
		return
	end

	list[statName] = MPStat.new(statName, data)
	table.insert(self.m_stat_order, statName)
	self:SaveStats()
end

function MPStatController:OnTick()
	yield()

	if (not Game.IsOnline()) then
		return
	end

	if (not self.m_last_tick:HasElapsed(3000)) then
		return
	end

	for _, mpStat in pairs(self.m_stats) do
		local value = mpStat:Get(true)
		if (mpStat.value_buffer == nil) then
			mpStat.value_buffer = value
		end

		if (mpStat.autolock) then
			mpStat:LockValue()
		end
	end

	self.m_last_tick:Reset()
end

return MPStatController:init()
