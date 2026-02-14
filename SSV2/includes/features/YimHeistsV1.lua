-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class HeistInfo
---@field public get_name fun(): string
---@field public get_coords fun(): vec3?
---@field public stat { name: string, val: integer}
---@field public optInfo? string

---@class GenericProperty
---@field public name string
---@field public coords vec3

---@class AgencyProperty : GenericProperty
---@class FieldHangarProperty : GenericProperty
---@class SubmarineProperty : GenericProperty

---@alias HEIST_TYPES table<integer, HeistInfo>

---@class YimHeists
---@field private m_raw_data RawBusinessData
---@field private m_properties { agency: AgencyProperty, hangar: FieldHangarProperty, submarine: SubmarineProperty }
---@field m_tab Tab
local YimHeists = { m_raw_data = require("includes.data.yrv3_data") }
YimHeists.__index = YimHeists

---@return YimHeists
function YimHeists:init()
	local instance = setmetatable({
		m_properties = {}
	}, self)

	if (Game.IsOnline()) then
		ThreadManager:Run(function()
			instance:ReadPropertyData()
		end)
	end

	Backend:RegisterEventCallback(Enums.eBackendEvent.SESSION_SWITCH, function()
		instance:ReadPropertyData()
	end)

	return instance
end

---@param statName string
---@param statVal integer
---@param notifTitle string
function YimHeists:SkipPrep(statName, statVal, notifTitle)
	stats.set_int(statName, statVal)
	Notifier:ShowSuccess(notifTitle, _T("YH_PREP_SKIP_NOTIF"))
end

function YimHeists:ReadPropertyData()
	-- We can extend this with other required properties
	-- like high-end apartments, etc.

	local agency_idx = stats.get_int("MPX_FIXER_HQ_OWNED")
	if (YRV3:IsPropertyIndexValid(agency_idx)) then
		local ref = self.m_raw_data.Agencies[agency_idx]
		self.m_properties.agency = {
			name   = Game.GetGXTLabel(ref.gxt),
			coords = ref.coords
		}
	end

	local hangar_own = stats.get_int("MPX_MCKENZIE_HANGAR_OWNED")
	if (hangar_own) then
		local ref = self.m_raw_data.FieldHangar[1]
		self.m_properties.hangar = {
			name   = Game.GetGXTLabel(ref.gxt),
			coords = ref.coords
		}
	end

	local sub_own = stats.get_int("MPX_IH_SUB_OWNED")
	if (sub_own == joaat("kosatka")) then
		self.m_properties.submarine = {
			name   = Game.GetGXTLabel("CELL_SUBMARINE"),
			-- TODO: I have no idea how to properly get the location of player Kosatka
			coords = Game.Ensure3DCoords(760) or vec3:zero()
		}
	end
end

---@return AgencyProperty?
function YimHeists:GetAgencyProperty()
	return self.m_properties.agency
end

---@return vec3?
function YimHeists:GetAgencyLocation()
	local agency = self:GetAgencyProperty()
	if (not agency) then
		return
	end

	return agency.coords
end

---@return FieldHangarProperty?
function YimHeists:GetFieldHangarProperty()
	return self.m_properties.hangar
end

---@return vec3?
function YimHeists:GetFieldHangarLocation()
	local hangar = self:GetFieldHangarProperty()
	if (not hangar) then
		return
	end

	return hangar.coords
end

---@return SubmarineProperty?
function YimHeists:HasSubmarine()
	return self.m_properties.submarine
end

return YimHeists
