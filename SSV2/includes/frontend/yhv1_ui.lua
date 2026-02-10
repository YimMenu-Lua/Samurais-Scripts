-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local YHV1 = require("includes.features.YimHeistsV1"):init()

---@class HeistInfo
---@field name string
---@field location vec3|nil
---@field blip integer BlipID
---@field stat string
---@field val integer
---@field optInfo? string

---@alias HEIST_TYPES table<integer, HeistInfo>

---@type HEIST_TYPES
local HEIST_TYPES = {
	{
		name = "Cluckin Bell",
		location = vec3:new(-1093.15, -807.14, 19.28),
		blip = 871,
		stat = "MPX_SALV23_INST_PROG",
		val = 31
	},
	{
		name = "KnoWay",
		location = vec3:new(42.82, -1599.19, 29.60),
		blip = 76,
		stat = "MPX_M25_AVI_MISSION_CURRENT",
		val = 4
	},
	{
		name = "Dr. Dre",
		location = YHV1:GetAgencyLocation(),
		blip = 826,
		stat = "MPX_FIXER_STORY_BS",
		val = 4095
	},
	{
		name = "Oscar Guzman",
		location = vec3:new(2150.65, 4796.60, 41.17),
		blip = 903,
		stat = "MPX_HACKER24_INST_BS",
		val = 31,
		optInfo = "Complete first mission on Hard first!"
	},
}

---@param where integer|vec3
---@param keepVehicle? boolean
function YHV1:Teleport(where, keepVehicle)
	if not Self:IsOutside() then
		Notifier:ShowError("YHV1", "Please go outside first!")
		return
	end

	Self:Teleport(where, keepVehicle)
end

-- This is all a pretty asinine way of handling this and has some UI/UX inconsistencies but it's quick and it works good enuff for now
-- TODO: Make this better
local function drawBasicTab()
	for i, heist in ipairs(HEIST_TYPES) do
		ImGui.BeginDisabled(not heist.location or not Game.IsValidCoords(heist.blip))
		ImGui.PushID(i)
		ImGui.BulletText(heist.name)

		if (GUI:Button(_T("GENERIC_TELEPORT"))) then
			YHV1:Teleport(heist.location, false)
		end

		ImGui.SameLine()
		if (GUI:Button(_T("GENERIC_SET_WAYPOINT"))) then
			Game.SetWaypointCoords(heist.blip)
		end

		ImGui.SameLine()

		ImGui.BeginDisabled(stats.get_int(heist.stat) == heist.val)
		if GUI:Button(_T "SY_COMPLETE_PREPARATIONS") then
			YHV1:SkipPrep(heist.stat, heist.val, heist.name)
		end
		if (heist.optInfo) then
			GUI:Tooltip(heist.optInfo)
		end
		ImGui.EndDisabled()
		ImGui.EndDisabled()
		ImGui.PopID()
	end
end

local cayo_secondary_target_i = 2
local cayo_secondary_target_c = 3

local function drawCayoTab()
	-- https://www.unknowncheats.me/forum/grand-theft-auto-v/695454-edit-cayo-perico-primary-target-stat-yimmenu-v2.html
	-- https://www.unknowncheats.me/forum/grand-theft-auto-v/431801-cayo-perico-heist-click.html
	local cayo_heist_primary    = stats.get_int("MPX_H4CNF_TARGET")
	local cayo_heist_difficulty = stats.get_int("MPX_H4_PROGRESS")
	local cayo_heist_weapons    = stats.get_int("MPX_H4CNF_WEAPONS")

	ImGui.SeparatorText("Targets")

	local new_primary_target, primary_target_clicked = ImGui.Combo(
		_T "YH_CAYO_TARGET_PRIMARY",
		cayo_heist_primary,
		{ "Tequila", "Ruby", "Bearer Bonds", "Pink Diamond", "Madrazo Files", "Panther Statue" },
		6
	)

	if (primary_target_clicked) then
		stats.set_int("MPX_H4CNF_TARGET", new_primary_target)
	end

	ImGui.Spacing()

	local secondary_targets = { "Cash", "Weed", "Coke", "Gold" }
	local new_secondary_target_i, secondary_target_i_click = ImGui.Combo(
		_T "YH_CAYO_TARGET_SECONDARY_I",
		cayo_secondary_target_i,
		secondary_targets,
		4
	)

	if (secondary_target_i_click) then
		cayo_secondary_target_i = new_secondary_target_i
	end

	local new_secondary_target_c, secondary_target_c_click = ImGui.Combo(
		_T "YH_CAYO_TARGET_SECONDARY_C",
		cayo_secondary_target_c,
		secondary_targets,
		4
	)

	if (secondary_target_c_click) then
		cayo_secondary_target_c = new_secondary_target_c
	end

	-- https://www.unknowncheats.me/forum/4489469-post16.html
	if GUI:Button("Set All Secondary Targets") then
		local targets_i = { 0, 0, 0, 0 }
		local targets_c = { 0, 0, 0, 0 }
		targets_i[new_secondary_target_i + 1] = -1
		targets_c[new_secondary_target_c + 1] = -1

		stats.set_int("MPX_H4LOOT_CASH_I", targets_i[0])
		stats.set_int("MPX_H4LOOT_WEED_I", targets_i[1])
		stats.set_int("MPX_H4LOOT_COKE_I", targets_i[2])
		stats.set_int("MPX_H4LOOT_GOLD_I", targets_i[3])
		stats.set_int("MPX_H4LOOT_CASH_C", targets_c[0])
		stats.set_int("MPX_H4LOOT_WEED_C", targets_c[1])
		stats.set_int("MPX_H4LOOT_COKE_C", targets_c[2])
		stats.set_int("MPX_H4LOOT_GOLD_C", targets_c[3])
	end

	ImGui.SeparatorText(_T "GENERIC_SETTINGS_LABEL")

	local new_difficulty, difficulty_toggled = GUI:CustomToggle(_T("YH_CAYO_DIFFICULTY"),
		cayo_heist_difficulty > 130000
	)

	if (difficulty_toggled) then
		if (new_difficulty) then
			stats.set_int("MPX_H4_PROGRESS", 131055)
		else
			stats.set_int("MPX_H4_PROGRESS", 126823)
		end
	end

	local new_weapons, weapons_clicked = ImGui.Combo(
		_T "YH_CAYO_WEAPONS",
		cayo_heist_weapons,
		{ "Unselected", "Aggressor", "Conspirator", "Crackshot", "Saboteur", "Marksman" },
		6
	)

	if (weapons_clicked) then
		stats.set_int("MPX_H4CNF_WEAPONS", new_weapons)
	end

	if GUI:Button(_T "CP_HEIST_UNLOCK_ALL") then
		stats.set_int("MPX_H4CNF_WEP_DISRP", 3)
		stats.set_int("MPX_H4CNF_ARM_DISRP", 3)
		stats.set_int("MPX_H4CNF_HEL_DISRP", 3)
		stats.set_int("MPX_H4_MISSIONS", 65535)
		Notifier:ShowSuccess("YHV1", "Heist ready")
	end

	if GUI:Button(_T "YH_CAYO_RESET_ALL") then
		stats.set_int("MPX_H4_MISSIONS", 0)
		stats.set_int("MPX_H4_PROGRESS", 0)
		stats.set_int("MPX_H4_PLAYTHROUGH_STATUS", 0)
		stats.set_int("MPX_H4CNF_APPROACH", 0)
		stats.set_int("MPX_H4CNF_BS_ENTR", 0)
		stats.set_int("MPX_H4CNF_BS_GEN", 0)
		Notifier:ShowSuccess("YHV1", "Cayo Perico has been reset!")
	end
end

local function HeistUI()
	if (not Game.IsOnline() or not Backend:IsUpToDate()) then
		ImGui.Text(_T("GENERIC_UNAVAILABLE_SP"))
		return
	end

	if (ImGui.BeginTabBar("##dunkBar")) then
		ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 10, 10)

		if ImGui.BeginTabItem(_T("GENERIC_GENERAL_LABEL")) then
			drawBasicTab()
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem(_T("YH_CAYO_TAB")) then
			drawCayoTab()
			ImGui.EndTabItem()
		end

		-- if ImGui.BeginTabItem(_T("YH_DDAY_TAB")) then
		-- 	drawDDayTab()
		-- 	ImGui.EndTabItem()
		-- end

		ImGui.PopStyleVar()
		ImGui.EndTabBar()
	end
end

YHV1.m_tab:RegisterGUI(HeistUI)
