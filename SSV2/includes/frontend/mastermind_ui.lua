-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Mastermind         = require("includes.features.Mastermind"):init()
local SGSL               = require("includes.services.SGSL")
local secondary_targets  = { "Cash", "Weed", "Coke", "Gold" }
local cayo_secondary_target_i, cayo_secondary_target_c

local heistNames <const> = { -- https://github.com/root-cause/v-labels/blob/master/labels.json
	CluckinBellFarmRaid   = "AWT_1026",
	KnoWayOut             = "DLCC_AVIM",
	DontFuckWithDre       = "AWT_973",
	OscarGuzmanFliesAgain = "HACK24_MFM_STR",
	FleecaJob             = "HTITLE_TUT",
	PrisonBreak           = "HTITLE_PRISON",
	HumaneLabsRaid        = "HTITLE_HUMANE",
	SeriesAFunding        = "HTITLE_NARC",
	PacificStandardJob    = "HTITLE_ORNATE",
	DataBreaches          = "HPSTRAND_IAAb",
	BogdanProblem         = "HPSTRAND_SUBb",
	DoomsdayScenario      = "HPSTRAND_MSILb",
}
local tabNames <const>   = { --
	"YH_BASIC_TAB",          -- Basic
	"ISLAND_TRAVEL_T",       -- Cayo Perico
	"FMMC_RSTAR_MHS2",       -- The Doomsday Heist
}

---@type HEIST_TYPES
local HEIST_TYPES        = {
	{
		get_name = function()
			return heistNames.CluckinBellFarmRaid
		end,
		get_coords = function()
			return vec3:new(-1093.15, -807.14, 19.28)
		end,
		stat = {
			name = "MPX_SALV23_INST_PROG",
			val = 31,
			cooldown_name = "MPX_SALV23_CFR_COOLDOWN",
			cooldown_gvar = "cfr_cd",
		},
	},
	{
		get_name = function()
			return heistNames.KnoWayOut
		end,
		get_coords = function()
			return Mastermind:GetAviLocation()
		end,
		stat = {
			name = "MPX_M25_AVI_MISSION_CURRENT",
			val = 4,
			cooldown_name = "MPX_M25_AVI_MISSION_CD",
			cooldown_gvar = "knoway_cd",
		},
	},
	{
		get_name = function()
			return heistNames.DontFuckWithDre
		end,
		get_coords = function()
			return Mastermind:GetAgencyLocation()
		end,
		stat = {
			name = "MPX_FIXER_STORY_BS",
			val = 4095,
			cooldown_name = "MPX_FIXER_STORY_COOLDOWN",
			cooldown_gvar = "dre_cd",
		}
	},
	{
		get_name = function()
			return heistNames.OscarGuzmanFliesAgain
		end,
		get_coords = function()
			return Mastermind:GetFieldHangarLocation()
		end,
		stat = {
			name = "MPX_HACKER24_INST_BS",
			val = 31,
			cooldown_name = "MPX_HACKER24_MFM_COOLDOWN",
			cooldown_gvar = "ogfa_cd",
		},
		opt_info = "Complete first mission on Hard first!"
	},
}

local function drawBasicTab()
	for i, heist in ipairs(HEIST_TYPES) do
		local heist_name = heist.get_name()
		local cooldown_time = stats.get_int(heist.stat.cooldown_name) -- POSIX
		local seconds_left = cooldown_time - Time.Epoch()
		local on_cooldown = cooldown_time > Time.Epoch()
		local is_done = stats.get_int(heist.stat.name) == heist.stat.val

		ImGui.PushID(i)
		GUI:HeaderText(heist_name, { separator = true, spacing = true })

		local location = heist.get_coords()
		ImGui.BeginDisabled(not location or on_cooldown)
		if (GUI:Button(_T("GENERIC_TELEPORT"))) then
			LocalPlayer:Teleport(location, false)
		end

		ImGui.SameLine()
		if (GUI:Button(_T("GENERIC_SET_WAYPOINT"))) then
			Game.SetWaypointCoords(location)
		end
		ImGui.EndDisabled()

		ImGui.BeginDisabled(is_done or on_cooldown)
		ImGui.SameLine()
		if GUI:Button(_T("SY_COMPLETE_PREPARATIONS")) then
			Mastermind:SkipPrep(heist.stat.name, heist.stat.val, heist_name)
		end
		if (heist.opt_info and not is_done) then
			GUI:Tooltip(heist.opt_info)
		elseif (on_cooldown) then
			GUI:Tooltip(_F(_T("CP_COOLDOWN_BYPASS_STATUS_FORMAT"), seconds_left / 60))
		end
		ImGui.EndDisabled()

		local key = heist.stat.cooldown_gvar
		GVars.features.yim_heists[key], _ = GUI:CustomToggle(
			_T("CP_HEIST_COOLDOWN_DISABLE"),
			GVars.features.yim_heists[key], {
				tooltip = _T("YH_COOLDOWN_BYPASS_TOOLTIP"),
				color   = Color("#AA0000"),
				onClick = function()
					YRV3:SetCooldownStateDirty(key, true)
				end
			})
		ImGui.PopID()

		ImGui.Spacing()
	end
end

local function drawCayoTab()
	local sub = Mastermind:GetSubmarine()
	if (not sub) then
		ImGui.Text(_T("YH_SUBMARINE_NOT_OWNED"))
		return
	end

	local request_kosatka = SGSL:Get(SGSL.data.request_services_global):AsGlobal():At(613)
	local sub_requested = request_kosatka:ReadInt() == 1

	ImGui.BeginDisabled(not sub.is_spawned)
	if (GUI:Button(_T("GENERIC_TELEPORT"))) then
		local forward_angle = math.rad(sub.heading + 90)
		local offset = vec3:new(math.cos(forward_angle), math.sin(forward_angle), 4) -- front of door
		LocalPlayer:Teleport(sub.coords + offset)
	end

	ImGui.SameLine()
	if (GUI:Button(_T("GENERIC_SET_WAYPOINT"))) then
		Game.SetWaypointCoords(sub.coords)
	end
	ImGui.EndDisabled()

	local btn_label = (sub_requested) and ImGui.TextSpinner() or _T("YH_CAYO_REQUEST_SUB")

	ImGui.BeginDisabled(sub_requested or sub.is_spawned)
	ImGui.SameLine()
	if (GUI:Button(btn_label)) then
		ThreadManager:Run(function()
			if (not LocalPlayer:IsOutside()) then
				Notifier:ShowError(Mastermind.__label, _T("GENERIC_TP_INTERIOR_ERR"))
				return
			end

			request_kosatka:WriteInt(1)
		end)
	end
	ImGui.EndDisabled()

	-- https://www.unknowncheats.me/forum/grand-theft-auto-v/695454-edit-cayo-perico-primary-target-stat-yimmenu-v2.html
	-- https://www.unknowncheats.me/forum/grand-theft-auto-v/431801-cayo-perico-heist-click.html
	local cayo_heist_primary         = stats.get_int("MPX_H4CNF_TARGET")
	local cayo_heist_difficulty      = stats.get_int("MPX_H4_PROGRESS")
	local cayo_heist_weapons         = stats.get_int("MPX_H4CNF_WEAPONS")
	local cayo_cooldown              = stats.get_int("MPX_H4_COOLDOWN")
	local cayo_cooldown_hard         = stats.get_int("MPX_H4_COOLDOWN_HARD")
	local posix_now                  = Time.Epoch()
	local cooldown_seconds_left      = cayo_cooldown - posix_now
	local cooldown_hard_seconds_left = cayo_cooldown_hard - posix_now
	local on_cooldown                = (cooldown_seconds_left > 0) or (cooldown_hard_seconds_left > 0)

	if (on_cooldown) then
		local minutes_left = (cooldown_seconds_left > 0 and cooldown_seconds_left or cooldown_hard_seconds_left) / 60
		GUI:HeaderText(_F(_T("CP_COOLDOWN_BYPASS_STATUS_FORMAT"), minutes_left),
			{ separator = false, spacing = true, color = Color("#AA0000") })
	end

	ImGui.BeginDisabled(on_cooldown)
	GUI:HeaderText(_T("CP_HEIST_SETUP"), { separator = true, spacing = true })

	local new_primary_target, primary_target_clicked = ImGui.Combo(
		_T("YH_CAYO_TARGET_PRIMARY"),
		cayo_heist_primary,
		{ "Tequila", "Ruby", "Bearer Bonds", "Pink Diamond", "Madrazo Files", "Panther Statue" },
		6
	)

	if (primary_target_clicked) then
		stats.set_int("MPX_H4CNF_TARGET", new_primary_target)
	end

	ImGui.Spacing()

	local secondary_target_click
	cayo_secondary_target_i, secondary_target_click = ImGui.Combo(
		_T "YH_CAYO_TARGET_SECONDARY_I",
		cayo_secondary_target_i,
		secondary_targets,
		4
	)

	if (secondary_target_click) then
		Mastermind:SetCayoSecTargets("I", cayo_secondary_target_i + 1)
	end

	cayo_secondary_target_c, secondary_target_click = ImGui.Combo(
		_T "YH_CAYO_TARGET_SECONDARY_C",
		cayo_secondary_target_c,
		secondary_targets,
		4
	)

	if (secondary_target_click) then
		Mastermind:SetCayoSecTargets("C", cayo_secondary_target_c + 1)
	end

	ImGui.Spacing()

	local new_weapons, weapons_clicked = ImGui.Combo(
		_T("YH_CAYO_WEAPONS"),
		cayo_heist_weapons,
		{ "Unselected", "Aggressor", "Conspirator", "Crackshot", "Saboteur", "Marksman" },
		6
	)

	if (weapons_clicked) then
		stats.set_int("MPX_H4CNF_WEAPONS", new_weapons)
	end

	GUI:HeaderText(_T("GENERIC_OPTIONS_LABEL"), { separator = true, spacing = true })

	local new_difficulty, difficulty_toggled = GUI:CustomToggle(
		_T("YH_CAYO_DIFFICULTY"),
		Bit.IsBitSet(cayo_heist_difficulty, 12)
	)

	if (difficulty_toggled) then
		-- Idk what bits 3 and 7 do
		if (new_difficulty) then
			stats.set_int("MPX_H4_PROGRESS", 131055) -- 126823 | 3 7 12
		else
			stats.set_int("MPX_H4_PROGRESS", 126823)
		end
	end

	-- https://www.unknowncheats.me/forum/3058973-post602.html
	if GUI:Button(_T("CP_HEIST_UNLOCK_ALL")) then
		stats.set_int("MPX_H4CNF_WEP_DISRP", 3)
		stats.set_int("MPX_H4CNF_ARM_DISRP", 3)
		stats.set_int("MPX_H4CNF_HEL_DISRP", 3)
		-- Also gotta figure out wtf these below actually do, currently they're just here to hopefully prevent bugs
		stats.set_int("MPX_H4CNF_BS_GEN", 131071)
		stats.set_int("MPX_H4CNF_BS_ENTR", 63)
		stats.set_int("MPX_H4CNF_BS_ABIL", 63)
		stats.set_int("MPX_H4_MISSIONS", 65535)
		stats.set_int("MPX_H4_PLAYTHROUGH_STATUS", 40000)
	end

	ImGui.EndDisabled() -- on_cooldown

	GVars.features.yim_heists.cayo_cd, _ = GUI:CustomToggle(
		_T("CP_HEIST_COOLDOWN_DISABLE"),
		GVars.features.yim_heists.cayo_cd, {
			tooltip = _T("YH_COOLDOWN_BYPASS_TOOLTIP"),
			color   = Color("#AA0000"),
			onClick = function()
				YRV3:SetCooldownStateDirty("cayo_cd", true)
			end
		})

	if (GVars.backend.debug_mode) then
		-- This button should only be used if something is severely wrong
		if GUI:Button(_T("YH_CAYO_RESET_ALL")) then
			stats.set_int("MPX_H4_MISSIONS", 0)
			stats.set_int("MPX_H4_PROGRESS", 0)
			stats.set_int("MPX_H4_PLAYTHROUGH_STATUS", 0)
			stats.set_int("MPX_H4CNF_APPROACH", 0)
			stats.set_int("MPX_H4CNF_BS_ENTR", 0)
			stats.set_int("MPX_H4CNF_BS_GEN", 0)
			stats.set_int("MPX_H4CNF_BS_ABIL", 0)
			Notifier:ShowSuccess(Mastermind.__label, "All Cayo progress has been reset!")
		end
	end
end

-- Help text and values copied from: https://www.unknowncheats.me/forum/grand-theft-auto-v/431801-cayo-perico-heist-click.html
local function drawDDayTab()
	local facility = Mastermind:GetFacilityProperty()
	if (not facility) then
		ImGui.Text(_T("YH_FACILITY_NOT_OWNED"))
		return
	end

	if (GUI:Button(_T("YH_TP_FACILITY"))) then
		LocalPlayer:Teleport(facility.coords)
	end

	ImGui.SameLine()
	if (GUI:Button(_T("GENERIC_SET_WAYPOINT"))) then
		Game.SetWaypointCoords(facility.coords)
	end

	local dday_status           = stats.get_int("MPX_GANGOPS_HEIST_STATUS")
	local dday_cooldown         = stats.get_int("MPX_GANGOPS_LAUNCH_TIME")
	local posix_now             = Time.Epoch()
	local cooldown_seconds_left = dday_cooldown - posix_now
	local on_cooldown           = cooldown_seconds_left > 0

	if (on_cooldown) then
		local minutes_left = cooldown_seconds_left / 60
		GUI:HeaderText(_F(_T("CP_COOLDOWN_BYPASS_STATUS_FORMAT"), minutes_left),
			{ separator = false, spacing = true, color = Color("#AA0000") })
	end

	ImGui.BeginDisabled(on_cooldown)
	GUI:HeaderText(_T("GENERIC_IMPORTANT"), { separator = true, spacing = true })
	ImGui.Text(_T("YH_DDAY_HELP1"))
	local button_label = _T("YH_DDAY_FORCE")
	if (GUI:Button(button_label)) then
		stats.set_int("MPX_GANGOPS_HEIST_STATUS", 9999)
	end
	ImGui.Text(_F(_T("YH_DDAY_HELP2_FMT"), button_label))

	GUI:HeaderText(_T("CP_HEIST_SETUP"), { separator = true, spacing = true })
	-- Final ACT 1
	ImGui.BeginDisabled(dday_status == 229383)
	if (GUI:Button(heistNames.DataBreaches)) then
		stats.set_int("MPX_GANGOPS_FLOW_MISSION_PROG", 503)
		stats.set_int("MPX_GANGOPS_HEIST_STATUS", 229383)
		stats.set_int("MPX_GANGOPS_FLOW_NOTIFICATIONS", 1557)
	end
	ImGui.EndDisabled()
	-- Final ACT 2
	ImGui.SameLine()
	ImGui.BeginDisabled(dday_status == 229378)
	if (GUI:Button(heistNames.BogdanProblem)) then
		stats.set_int("MPX_GANGOPS_FLOW_MISSION_PROG", 240)
		stats.set_int("MPX_GANGOPS_HEIST_STATUS", 229378)
		stats.set_int("MPX_GANGOPS_FLOW_NOTIFICATIONS", 1557)
	end
	ImGui.EndDisabled()
	-- Final ACT 3
	ImGui.BeginDisabled(dday_status == 229380)
	if (GUI:Button(heistNames.DoomsdayScenario)) then
		stats.set_int("MPX_GANGOPS_FLOW_MISSION_PROG", 16368)
		stats.set_int("MPX_GANGOPS_HEIST_STATUS", 229380)
		stats.set_int("MPX_GANGOPS_FLOW_NOTIFICATIONS", 1557)
	end
	ImGui.EndDisabled()
	ImGui.EndDisabled() -- on_cooldown

	GVars.features.yim_heists.dday_cd, _ = GUI:CustomToggle(_T("CP_HEIST_COOLDOWN_DISABLE"),
		GVars.features.yim_heists.dday_cd, {
			tooltip = _T("YH_COOLDOWN_BYPASS_TOOLTIP"),
			color   = Color("#AA0000"),
			onClick = function()
				YRV3:SetCooldownStateDirty("dday_cd", true)
			end
		})
end

-- Maybe port https://github.com/YimMenu/YimMenuV2/blob/enhanced/src/game/features/recovery/Heist/ApartmentHeist.cpp ?
-- Apartment heists actually seem complicated in that (I assume) since they're old they use a different method of storing progress as there isn't just 1 stat to check like all the others
-- Or if there is, there only *was* because no stats I've found seem to do anything today, like the stat from that link right there. Doesn't do anything here or in YimMenuV2, am I missing something?
local function drawAptTab()
end

local tabCallbacks <const> = {
	drawBasicTab,
	drawCayoTab,
	drawDDayTab,
}

local function HeistUI()
	if (not Game.IsOnline()) then
		ImGui.Text(_T("GENERIC_UNAVAILABLE_SP"))
		return
	end

	if (not Backend:IsUpToDate()) then
		ImGui.Text(_T("GENERIC_OUTDATED"))
		return
	end

	cayo_secondary_target_i, cayo_secondary_target_c = Mastermind:GetCayoSecTargets()

	if (ImGui.BeginTabBar("##mastermind")) then
		for i = 1, #tabNames do
			local name = tabNames[i]
			if ImGui.BeginTabItem(name) then
				tabCallbacks[i]()
				ImGui.EndTabItem()
			end
		end
		ImGui.EndTabBar()
	end
end

GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, Mastermind.__label, HeistUI)

ThreadManager:Run(function()
	Translator:TranslateGXTList(tabNames)
	Translator:TranslateGXTList(heistNames)
end)
