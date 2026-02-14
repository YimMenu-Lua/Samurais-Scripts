-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class HeistInfo
---@field name string
---@field coords vec3|nil
---@field blip integer BlipID
---@field stat { name: string, val: integer}
---@field optInfo? string

---@alias HEIST_TYPES table<integer, HeistInfo>

---@class YimHeists
---@field private m_raw_data RawBusinessData
---@field m_tab Tab
local YimHeists = { m_raw_data = require("includes.data.yrv3_data") }
YimHeists.__index = YimHeists

---@return YimHeists
function YimHeists:init()
	local instance = setmetatable({
		m_tab = GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, "YimHeists")
	}, self)

	return instance
end

---@param statName string
---@param statVal integer
---@param notifTitle string
function YimHeists:SkipPrep(statName, statVal, notifTitle)
	stats.set_int(statName, statVal)
	Notifier:ShowSuccess(notifTitle, _T("YH_PREP_SKIP_NOTIF"))
end

---@return vec3
function YimHeists:GetAgencyLocation()
	local property_index = stats.get_int("MPX_FIXER_HQ_OWNED")
	if (not YRV3:IsPropertyIndexValid(property_index)) then
		return
	end

	local ref = self.m_raw_data.Agencies[property_index]
	return ref.coords
end

---@param where integer|vec3
---@param keepVehicle? boolean
function YimHeists:Teleport(where, keepVehicle)
	if not Self:IsOutside() then
		Notifier:ShowError("YHV1", "Please go outside first!")
		return
	end

	Self:Teleport(where, keepVehicle)
end

return YimHeists
