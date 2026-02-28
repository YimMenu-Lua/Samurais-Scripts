-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local SGSL              = require("includes.services.SGSL")
local secondary_targets = { "CASH", "WEED", "COKE", "GOLD" }

---@class HeistStat
---@field public name string
---@field public val integer
---@field public cooldown_name string
---@field public cooldown_gvar string GVar path name

---@class HeistInfo
---@field public get_name fun(): string
---@field public get_coords fun(): vec3?
---@field public stat HeistStat
---@field public opt_info? string Optional info to provide to a tooltip, typically a starting requirement that needs to be done manually

---@class GenericProperty
---@field public name string
---@field public coords vec3

---@class AgencyProperty : GenericProperty
---@class FacilityProperty : GenericProperty
---@class FieldHangarProperty : GenericProperty
---@class SubmarineProperty : GenericProperty
---@field public heading float
---@field public is_spawned boolean

---@alias HEIST_TYPES table<integer, HeistInfo>

---@class Mastermind
---@field private m_raw_data RawBusinessData
---@field private m_properties { agency: AgencyProperty, hangar: FieldHangarProperty, facility: FacilityProperty, submarine: SubmarineProperty }
---@field m_tab Tab
local Mastermind        = { m_raw_data = require("includes.data.yrv3_data") }
Mastermind.__index      = Mastermind
Mastermind.__label      = "Mastermind"

---@return Mastermind
function Mastermind:init()
	local instance = setmetatable({
		m_properties = {}
	}, self)

	if (Game.IsOnline()) then
		instance:ReadPropertyData()
	end

	Backend:RegisterEventCallback(Enums.eBackendEvent.SESSION_SWITCH, function()
		instance:ReadPropertyData()
	end)

	return instance
end

---@param statName string
---@param statVal integer
---@param notifTitle string
function Mastermind:SkipPrep(statName, statVal, notifTitle)
	stats.set_int(statName, statVal)
	Notifier:ShowSuccess(notifTitle, _T("YH_PREP_SKIP_NOTIF"))
end

-- https://www.unknowncheats.me/forum/4489469-post16.html
---@param type string
---@param index integer
function Mastermind:SetCayoSecTargets(type, index)
	local targets = { 0, 0, 0, 0 }
	targets[index] = -1

	for st = 1, 4 do
		local stat_name = _F("MPX_H4LOOT_%s_%s", secondary_targets[st], type)
		stats.set_int(stat_name, targets[st])
		stats.set_int(_F("%s_SCOPED", stat_name), targets[st])
	end

	stats.set_int("MPX_H4LOOT_PAINT", -1) -- Not really any reason to have an option for paintings
	stats.set_int("MPX_H4LOOT_PAINT_SCOPED", -1)
end

---@return integer, integer
function Mastermind:GetCayoSecTargets()
	local loot_i, loot_c

	for st = 1, 4 do
		local stat_name = _F("MPX_H4LOOT_%s", secondary_targets[st])
		if (stats.get_int(_F("%s_I", stat_name)) == -1) then
			loot_i = st - 1 -- ImGui indexes by 0
		end
		if (stats.get_int(_F("%s_C", stat_name)) == -1) then
			loot_c = st - 1
		end
	end

	return loot_i or -1, loot_c or -1
end

--- Returns the coords and heading to either the Kosatka/Terrorbyte/MOC, whichever is called in.
---@return vec3, float
local function getServiceVehicleCoords()
	local ser_veh_global = SGSL:Get(SGSL.data.service_vehicles_global)
	local pid_size = ser_veh_global:GetOffset(1)
	local offset2 = ser_veh_global:GetOffset(2)
	local vec_offset = 13

	local final = ser_veh_global:AsGlobal()
		:At(LocalPlayer:GetPlayerID(), pid_size)
		:At(offset2)
		:At(vec_offset)

	return final:ReadVec3(), final:At(3):ReadFloat()
end

---@return boolean
local function isSubmarineSpawned()
	local sub_global = SGSL:Get(SGSL.data.service_vehicles_global)
	local pid_size = sub_global:GetOffset(1)
	local offset2 = sub_global:GetOffset(2)
	local sub_offset = 4
	local sub_status = sub_global:AsGlobal()
		:At(LocalPlayer:GetPlayerID(), pid_size)
		:At(offset2)
		:At(sub_offset)
		:ReadInt()
	return Bit.IsBitSet(sub_status, 31)
end

function Mastermind:ReadPropertyData()
	ThreadManager:Run(function()
		while (Game.IsInNetworkTransition()) do
			yield()
		end

		if (not network.is_session_started()) then
			-- player left online; bail out
			return
		end

		local agency_idx = stats.get_int("MPX_FIXER_HQ_OWNED")
		local agency_ref = self.m_raw_data.Agencies[agency_idx]
		if (agency_ref) then
			self.m_properties.agency = {
				name   = Game.GetGXTLabel(agency_ref.gxt),
				coords = agency_ref.coords
			}
		end

		local hangar_idx = stats.get_int("MPX_MCKENZIE_HANGAR_OWNED")
		local hangar_ref = self.m_raw_data.FieldHangar[hangar_idx]
		if (hangar_ref) then
			self.m_properties.hangar = {
				name   = Game.GetGXTLabel(hangar_ref.gxt),
				coords = hangar_ref.coords
			}
		end

		local facility_idx = stats.get_int("MPX_DBASE_OWNED")
		local facility_ref = self.m_raw_data.Facilities[facility_idx]
		if (facility_ref) then
			self.m_properties.facility = {
				name   = Game.GetGXTLabel(facility_ref.gxt),
				coords = facility_ref.coords
			}
		end

		local sub_hash = stats.get_int("MPX_IH_SUB_OWNED")
		if (sub_hash == _J("kosatka")) then
			self.m_properties.submarine = {
				name    = Game.GetGXTLabel("CELL_SUBMARINE"),
				coords  = vec3:zero(),
				heading = 0.0,
				is_spawned = isSubmarineSpawned()
			}
		end
	end)
end

---@return vec3
function Mastermind:GetAviLocation()
	local stat = stats.get_int("MPX_M25_AVI_MISSION_CURRENT")
	local blip = HUD.GET_FIRST_BLIP_INFO_ID(76)
	if (blip and stat ~= 4) then
		local blip_coords = HUD.GET_BLIP_INFO_ID_COORD(blip)
		local forward_angle = math.rad(HUD.GET_BLIP_ROTATION(blip) + 90)
		local offset = vec3:new(math.cos(forward_angle), math.sin(forward_angle), 0) -- front of payphone
		return blip_coords + offset
	end

	return vec3:new(42.82, -1599.19, 29.60) -- final payphone
end

---@return AgencyProperty?
function Mastermind:GetAgencyProperty()
	return self.m_properties.agency
end

---@return vec3?
function Mastermind:GetAgencyLocation()
	local agency = self:GetAgencyProperty()
	if (not agency) then
		return
	end

	return agency.coords
end

---@return FieldHangarProperty?
function Mastermind:GetFieldHangarProperty()
	return self.m_properties.hangar
end

---@return vec3?
function Mastermind:GetFieldHangarLocation()
	local hangar = self:GetFieldHangarProperty()
	if (not hangar) then
		return
	end

	return hangar.coords
end

---@return FacilityProperty?
function Mastermind:GetFacilityProperty()
	return self.m_properties.facility
end

---@return vec3?
function Mastermind:GetFacilityLocation()
	local facility = self:GetFacilityProperty()
	if (not facility) then
		return
	end

	return facility.coords
end

---@return SubmarineProperty?
function Mastermind:GetSubmarine()
	local sub = self.m_properties.submarine
	if (not sub) then
		return
	end

	sub.is_spawned = isSubmarineSpawned()
	if (sub.is_spawned) then
		sub.coords, sub.heading = getServiceVehicleCoords()
	end
	return sub
end

return Mastermind
