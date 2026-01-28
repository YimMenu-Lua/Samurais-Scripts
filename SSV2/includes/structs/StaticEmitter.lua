-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class StaticEmitter
---@field private m_name string
---@field private m_default_station string
---@field private m_current_station string
---@field private m_owner handle
---@field private m_enabled boolean
local StaticEmitter <const> = {}
StaticEmitter.__index = StaticEmitter

---@param name string
---@param defaultStation string
---@return StaticEmitter
function StaticEmitter.new(name, defaultStation)
	return setmetatable({
		m_name            = name,
		m_default_station = defaultStation,
		m_current_station = defaultStation,
		m_enabled         = false,
		m_owner           = 0,
	}, StaticEmitter)
end

---@param station? string
---@param entity? handle
function StaticEmitter:Enable(station, entity)
	AUDIO.SET_STATIC_EMITTER_ENABLED(self.m_name, true)
	self:SetCurrentStation(station or self.m_default_station)
	self.m_enabled = true

	if (entity) then
		self:LinkToEntity(entity)
	end
end

function StaticEmitter:Disable()
	AUDIO.SET_EMITTER_RADIO_STATION(self.m_name, self.m_default_station)
	AUDIO.SET_STATIC_EMITTER_ENABLED(self.m_name, false)
	self.m_enabled = false
end

---@param station string
function StaticEmitter:SetCurrentStation(station)
	self.m_current_station = station
	AUDIO.SET_EMITTER_RADIO_STATION(self.m_name, station)
end

function StaticEmitter:LinkToEntity(entity)
	if (not Game.IsScriptHandle(entity)) then
		return
	end

	self.m_owner = entity
	AUDIO.LINK_STATIC_EMITTER_TO_ENTITY(self.m_name, entity)
end

---@return boolean
function StaticEmitter:IsEnabled()
	return self.m_enabled
end

---@return boolean
function StaticEmitter:IsLinked()
	return Game.IsScriptHandle(self.m_owner)
end

---@return string
function StaticEmitter:GetName()
	return self.m_name
end

---@return string
function StaticEmitter:GetCurrentStation()
	return self.m_current_station
end

---@return handle
function StaticEmitter:GetOwner()
	return self.m_owner
end

return StaticEmitter
