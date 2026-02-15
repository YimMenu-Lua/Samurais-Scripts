-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local YHV1               = require("includes.features.YimHeistsV1"):init()
local setTranslations    = require("SSV2.includes.frontend.helpers.set_translations")
local heistNames <const> = {
	"AWT_1026",    -- The Cluckin' Bell Farm Raid
	"AWT_1109",    -- No Way KnoWay
	"AWT_973",     -- Don't Fuck With Dre
	"HACK24_MFM_STR", -- Oscar Guzman Flies Again
}
local tabNames <const>   = {
	"YH_BASIC_TAB", -- Basic
	"ISLAND_TRAVEL_T", -- Cayo Perico
}

---@type HEIST_TYPES
local HEIST_TYPES        = {
	{ -- Cluckin Bell
		get_name = function()
			return heistNames[1]
		end,
		get_coords = function()
			return vec3:new(-1093.15, -807.14, 19.28)
		end,
		stat = {
			name = "MPX_SALV23_INST_PROG",
			val = 31,
		}
	},
	{ -- KnoWay
		get_name = function()
			return heistNames[2]
		end,
		get_coords = function()
			return vec3:new(42.82, -1599.19, 29.60)
		end,
		stat = {
			name = "MPX_M25_AVI_MISSION_CURRENT",
			val = 4,
		},
	},
	{ -- Dr Dre
		get_name = function()
			return heistNames[3]
		end,
		get_coords = function()
			return YHV1:GetAgencyLocation()
		end,
		stat = {
			name = "MPX_FIXER_STORY_BS",
			val = 4095,
		}
	},
	{ -- Oscar Guzman
		get_name = function()
			return heistNames[4]
		end,
		get_coords = function()
			return YHV1:GetFieldHangarLocation()
		end,
		stat = {
			name = "MPX_HACKER24_INST_BS",
			val = 31,
		},
		optInfo = "Complete first mission on Hard first!"
	},
}

local function drawBasicTab()
	for i, heist in ipairs(HEIST_TYPES) do
		ImGui.PushID(i)
		local heist_name = heist.get_name()
		ImGui.BulletText(heist_name)

		local location = heist.get_coords() or vec3:zero()
		ImGui.BeginDisabled(not location)
		if (GUI:Button(_T("GENERIC_TELEPORT"))) then
			LocalPlayer:Teleport(location, false)
		end

		ImGui.SameLine()
		if (GUI:Button(_T("GENERIC_SET_WAYPOINT"))) then
			Game.SetWaypointCoords(location)
		end
		ImGui.EndDisabled()

		ImGui.SameLine()

		local isDone = stats.get_int(heist.stat.name) == heist.stat.val
		ImGui.BeginDisabled(isDone)
		if GUI:Button(_T("SY_COMPLETE_PREPARATIONS")) then
			YHV1:SkipPrep(heist.stat.name, heist.stat.val, heist_name)
		end
		if (heist.optInfo and not isDone) then
			GUI:Tooltip(heist.optInfo)
		end
		ImGui.EndDisabled()
		ImGui.PopID()
	end
end

local cayo_secondary_target_i = 2
local cayo_secondary_target_c = 3

local function drawCayoTab()
	local sub = YHV1:HasSubmarine()
	if (not sub) then
		ImGui.Text(_T("YH_SUBMARINE_NOT_OWNED"))
		return
	end

	ImGui.BeginDisabled(sub.coords:is_zero())
	if (GUI:Button(_T("GENERIC_TELEPORT"))) then
		LocalPlayer:Teleport(sub.coords)
	end

	ImGui.SameLine()

	if (GUI:Button(_T("GENERIC_SET_WAYPOINT"))) then
		Game.SetWaypointCoords(sub.coords)
	end
	ImGui.EndDisabled()

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
		stats.set_int("MPX_H4LOOT_CASH_I_SCOPED", targets_i[0])
		stats.set_int("MPX_H4LOOT_WEED_I", targets_i[1])
		stats.set_int("MPX_H4LOOT_WEED_I_SCOPED", targets_i[1])
		stats.set_int("MPX_H4LOOT_COKE_I", targets_i[2])
		stats.set_int("MPX_H4LOOT_COKE_I_SCOPED", targets_i[2])
		stats.set_int("MPX_H4LOOT_GOLD_I", targets_i[3])
		stats.set_int("MPX_H4LOOT_GOLD_I_SCOPED", targets_i[3])
		stats.set_int("MPX_H4LOOT_CASH_C", targets_c[0])
		stats.set_int("MPX_H4LOOT_WEED_C", targets_c[1])
		stats.set_int("MPX_H4LOOT_COKE_C", targets_c[2])
		stats.set_int("MPX_H4LOOT_GOLD_C", targets_c[3])
		stats.set_int("MPX_H4LOOT_PAINT", -1) -- Not really any reason to have an option for paintings
		stats.set_int("MPX_H4LOOT_PAINT_SCOPED", -1)
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

	-- https://www.unknowncheats.me/forum/3058973-post602.html
	if GUI:Button(_T "CP_HEIST_UNLOCK_ALL") then
		stats.set_int("MPX_H4CNF_BS_GEN", 131071)
		stats.set_int("MPX_H4CNF_BS_ENTR", 63)
		stats.set_int("MPX_H4CNF_BS_ABIL", 63)
		stats.set_int("MPX_H4CNF_WEP_DISRP", 3)
		stats.set_int("MPX_H4CNF_ARM_DISRP", 3)
		stats.set_int("MPX_H4CNF_HEL_DISRP", 3)
		stats.set_int("MPX_H4_MISSIONS", 65535)
		if (stats.get_int("MPX_H4_PLAYTHROUGH_STATUS") == 0) then
			stats.set_int("MPX_H4_PLAYTHROUGH_STATUS", 40000)
		end
		Notifier:ShowSuccess("YHV1", "Heist ready")
	end

	if GUI:Button(_T "YH_CAYO_RESET_ALL") then
		stats.set_int("MPX_H4_MISSIONS", 0)
		stats.set_int("MPX_H4_PROGRESS", 0)
		stats.set_int("MPX_H4_PLAYTHROUGH_STATUS", 0)
		stats.set_int("MPX_H4CNF_APPROACH", 0)
		stats.set_int("MPX_H4CNF_BS_ENTR", 0)
		stats.set_int("MPX_H4CNF_BS_GEN", 0)
		stats.set_int("MPX_H4CNF_BS_ABIL", 0)
		Notifier:ShowSuccess("YHV1", "All progress has been reset!")
	end
end

local tabCallbacks <const> = {
	drawBasicTab,
	drawCayoTab,
}

local function HeistUI()
	if (not Game.IsOnline() or not Backend:IsUpToDate()) then
		ImGui.Text(_T("GENERIC_UNAVAILABLE_SP"))
		return
	end

	if (ImGui.BeginTabBar("##funkBar")) then
		ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 10, 10)

		for i = 1, #tabNames do
			local name = tabNames[i]
			if ImGui.BeginTabItem(name) then
				tabCallbacks[i]()
				ImGui.EndTabItem()
			end
		end

		ImGui.PopStyleVar()
		ImGui.EndTabBar()
	end
end

GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, "YimHeists", HeistUI)

ThreadManager:Run(function()
	setTranslations(tabNames)
	setTranslations(heistNames)
end)
