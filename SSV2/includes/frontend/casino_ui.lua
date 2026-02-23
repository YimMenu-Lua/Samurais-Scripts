-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CasinoPacino = require("includes.features.CasinoPacino"):init()
local SGSL         = require("includes.services.SGSL")
local casino_pos   = vec3:new(924.6380, 46.6918, 81.1063)

local function drawGamblingTab()
	if (GUI:Button(_T("CP_TP_CASINO"))) then
		LocalPlayer:Teleport(casino_pos)
	end

	ImGui.SameLine()

	if (GUI:Button(_T("GENERIC_SET_WAYPOINT"))) then
		Game.SetWaypointCoords(casino_pos)
	end

	GUI:HeaderText(_T("CP_COOLDOWN_BYPASS"), { separator = true, spacing = true })
	GVars.features.dunk.bypass_casino_bans, _ = GUI:CustomToggle(_T("CP_COOLDOWN_BYPASS_ENABLE"),
		GVars.features.dunk.bypass_casino_bans, {
			tooltip = _T("CP_COOLDOWN_BYPASS_TOOLTIP"),
			color   = Color("#AA0000")
		})

	ImGui.BulletText(_T("CP_COOLDOWN_BYPASS_STATUS"))
	ImGui.SameLine()
	ImGui.Text(CasinoPacino:GetCooldownString())

	GUI:HeaderText(_T("CP_POKER_SETTINGS"), { separator = true, spacing = true })
	GVars.features.dunk.force_poker_cards, _ = GUI:CustomToggle(_T("CP_POKER_FORCE_ROYAL_FLUSH"),
		GVars.features.dunk.force_poker_cards
	)

	GVars.features.dunk.set_dealers_poker_cards, _ = GUI:CustomToggle(_T("CP_POKER_FORCE_BAD_BEAT"),
		GVars.features.dunk.set_dealers_poker_cards
	)

	GUI:HeaderText(_T("CP_BLACKJACK_SETTINGS"), { separator = true, spacing = true })
	ImGui.BulletText(_T("CP_BLACKJACK_DEALER_FACE_DOWN_CARD"))
	ImGui.SameLine()
	ImGui.Text(CasinoPacino:GetBJDealerCard())
	if GUI:Button(_T("CP_BLACKJACK_FORCE_DEALER_BUST")) then
		CasinoPacino:ForceDealerBust()
	end

	GUI:HeaderText(_T("CP_ROULETTE_SETTINGS"), { separator = true, spacing = true })
	GVars.features.dunk.force_roulette_wheel, _ = GUI:CustomToggle(_T("CP_ROULETTE_FORCE_RED_18"),
		GVars.features.dunk.force_roulette_wheel
	)

	GUI:HeaderText(_T("CP_SLOT_MACHINES_SETTINGS"), { separator = true, spacing = true })
	GVars.features.dunk.rig_slot_machine, _ = GUI:CustomToggle(_T("CP_SLOT_MACHINES_RIG"),
		GVars.features.dunk.rig_slot_machine
	)

	GVars.features.dunk.autoplay_slots, _ = GUI:CustomToggle(_T("CP_SLOT_MACHINES_AUTOPLAY"),
		GVars.features.dunk.autoplay_slots
	)

	if (GVars.features.dunk.autoplay_slots) then
		GVars.features.dunk.cap_slot_machine_chips, _ = GUI:CustomToggle(_T("CP_SLOT_MACHINES_CAP_CHIPS"),
			GVars.features.dunk.cap_slot_machine_chips
		)

		if (GVars.features.dunk.cap_slot_machine_chips) then
			ImGui.SameLine()
			ImGui.PushItemWidth(200)
			GVars.features.dunk.slot_machine_cap, _ = ImGui.SliderInt("##chips_cap",
				GVars.features.dunk.slot_machine_cap,
				1e3,
				1e5
			)
			ImGui.PopItemWidth()
		end

		ImGui.Text(_T("CP_AUTOPLAY_SLOTS_TIME_DELAY"))
		ImGui.SameLine()
		if (not GVars.features.dunk.autoplay_slots_delay_random) then
			ImGui.PushItemWidth(200)
			GVars.features.dunk.autoplay_slots_delay, _ = ImGui.SliderInt("##delay_time",
				GVars.features.dunk.autoplay_slots_delay,
				500,
				1e4,
				"%d ms"
			)
			ImGui.SameLine()
		end

		GVars.features.dunk.autoplay_slots_delay_random, _ = GUI:CustomToggle(_T("GENERIC_RANDOM"),
			GVars.features.dunk.autoplay_slots_delay_random
		)
	end

	GUI:HeaderText(_T("CP_LUCKY_WHEEL_SETTINGS"), { separator = true, spacing = true })

	---@type dict<eCasinoPrize>
	local labels = {
		[_T("CP_LUCKY_WHEEL_GIVE_VEHICLE")]  = Enums.eCasinoPrize.VEHICLE,
		[_T("CP_LUCKY_WHEEL_GIVE_MYSTERY")]  = Enums.eCasinoPrize.MYSTERY,
		[_T("CP_LUCKY_WHEEL_GIVE_CASH")]     = Enums.eCasinoPrize.CASH,
		[_T("CP_LUCKY_WHEEL_GIVE_CHIPS")]    = Enums.eCasinoPrize.CHIPS,
		[_T("CP_LUCKY_WHEEL_GIVE_RP")]       = Enums.eCasinoPrize.RP,
		[_T("CP_LUCKY_WHEEL_GIVE_DISCOUNT")] = Enums.eCasinoPrize.DISCOUNT,
		[_T("CP_LUCKY_WHEEL_GIVE_CLOTHING")] = Enums.eCasinoPrize.CLOTHING,
		[_T("CP_LUCKY_WHEEL_GIVE_SURPRISE")] = Enums.eCasinoPrize.RANDOM,
	}

	local maxwidth = 0
	local padding = ImGui.GetStyle().FramePadding.x * 4 -- double padding
	for label in pairs(labels) do
		local width = ImGui.CalcTextSize(label) + padding
		if (width > maxwidth) then
			maxwidth = width
		end
	end

	local btnIdx = 1
	for label, prizeID in pairs(labels) do
		if (GUI:Button(label, { size = vec2:new(maxwidth, 32) })) then
			CasinoPacino:GiveWheelPrize(prizeID)
		end
		if (btnIdx % 2 ~= 0) then
			ImGui.SameLine()
		end
		btnIdx = btnIdx + 1
	end
end

local function drawHeistTab()
	local arcade = CasinoPacino:GetOwnedArcade()
	if (not arcade) then
		ImGui.Text(_T("CP_ARCADE_NOT_OWNED"))
		return
	end

	if (GUI:Button(_T("CP_TP_ARCADE"))) then
		LocalPlayer:Teleport(arcade.coords)
	end

	ImGui.SameLine()

	if (GUI:Button(_T("GENERIC_SET_WAYPOINT"))) then
		Game.SetWaypointCoords(arcade.coords)
	end

	local casino_heist_approach      = stats.get_int("MPX_H3OPT_APPROACH")
	local casino_heist_target        = stats.get_int("MPX_H3OPT_TARGET")
	local casino_heist_last_approach = stats.get_int("MPX_H3_LAST_APPROACH")
	local casino_heist_hard          = stats.get_int("MPX_H3_HARD_APPROACH")
	local casino_heist_gunman        = stats.get_int("MPX_H3OPT_CREWWEAP")
	local casino_heist_driver        = stats.get_int("MPX_H3OPT_CREWDRIVER")
	local casino_heist_hacker        = stats.get_int("MPX_H3OPT_CREWHACKER")
	local casino_heist_weapons       = stats.get_int("MPX_H3OPT_WEAPS")
	local casino_heist_cars          = stats.get_int("MPX_H3OPT_VEHS")
	local casino_heist_masks         = stats.get_int("MPX_H3OPT_MASKS")

	GUI:HeaderText(_T("CP_HEIST_SETUP"), { separator = true, spacing = true })
	ImGui.PushItemWidth(200)

	local new_approach, approach_clicked = ImGui.Combo(_T("CP_HEIST_APPROACH"),
		casino_heist_approach,
		{ "Unselected", "Silent & Sneaky", "The Big Con", "Aggressive" },
		4
	)

	if (approach_clicked) then
		stats.set_int("MPX_H3OPT_APPROACH", new_approach)
	end

	local new_last_approach, last_approach_clicked = ImGui.Combo(
		_T("CP_HEIST_LAST_APPROACH"),
		casino_heist_last_approach,
		{ "Unselected", "Silent & Sneaky", "The Big Con", "Aggressive" },
		4
	)

	if (last_approach_clicked) then
		stats.set_int("MPX_H3_LAST_APPROACH", new_last_approach)
	end

	local new_hard_approach, hard_approach_clicked = ImGui.Combo(
		_T("CP_HEIST_HARD_APPROACH"),
		casino_heist_hard,
		{ "Unselected", "Silent & Sneaky", "The Big Con", "Aggressive" },
		4
	)

	if (hard_approach_clicked) then
		stats.set_int("MPX_H3_HARD_APPROACH", new_hard_approach)
	end

	local new_target, target_clicked = ImGui.Combo(
		_T("CP_HEIST_TARGET"),
		casino_heist_target,
		{ "Money", "Gold", "Art", "Diamonds" },
		4
	)

	if (target_clicked) then
		stats.set_int("MPX_H3OPT_TARGET", new_target)
	end

	local new_gunman, gunman_clicked = ImGui.Combo(
		_T("CP_HEIST_GUNMAN"),
		casino_heist_gunman,
		{ "Unselected", "Karl Abolaji", "Gustavo Mota", "Charlie Reed", "Chester McCoy", "Patrick McReary" },
		6
	)

	if (gunman_clicked) then
		stats.set_int("MPX_H3OPT_CREWWEAP", new_gunman)
	end

	if (new_gunman > 0) then
		local gunList = {
			[1] = { --Karl Abolaji
				{ '##1", "##2' },
				{ "Micro SMG Loadout", "Machine Pistol Loadout" },
				{ "Micro SMG Loadout", "Shotgun Loadout" },
				{ "Shotgun Loadout",   "Revolver Loadout" }
			},
			[2] = { --Gustavo Fring
				{ '##1", "##2' },
				{ "Rifle Loadout", "Shotgun Loadout" },
				{ "Rifle Loadout", "Shotgun Loadout" },
				{ "Rifle Loadout", "Shotgun Loadout" },
			},
			[3] = { --Charlie Reed
				{ '##1", "##2' },
				{ "SMG Loadout",            "Shotgun Loadout" },
				{ "Machine Pistol Loadout", "Shotgun Loadout" },
				{ "SMG Loadout",            "Shotgun Loadout" }
			},
			[4] = { --Chester McCoy
				{ '##1", "##2' },
				{ "MK II Shotgun Loadout", "MK II Rifle Loadout" },
				{ "MK II SMG Loadout",     "MK II Rifle Loadout" },
				{ "MK II Shotgun Loadout", "MK II Rifle Loadout" }
			},
			[5] = { --Laddie Paddie Sadie Enweird
				{ '##1", "##2' },
				{ "Combat PDW Loadout", "Rifle Loadout" },
				{ "Shotgun Loadout",    "Rifle Loadout" },
				{ "Shotgun Loadout",    "Combat MG Loadout" }
			}

		}

		local new_weapons, weapons_clicked = ImGui.Combo(
			_T("CP_HEIST_WEAPONS"),
			casino_heist_weapons,
			gunList[new_gunman][casino_heist_approach + 1],
			2
		)
		if (weapons_clicked) then
			stats.set_int("MPX_H3OPT_WEAPS", new_weapons)
		end
	end

	local new_driver, driver_clicked = ImGui.Combo(
		_T("CP_HEIST_DRIVER"),
		casino_heist_driver,
		{
			"Unselected",
			"Karim Deniz",
			"Taliana Martinez",
			"Eddie Toh",
			"Zach Nelson",
			"Chester McCoy"
		},
		6
	)
	if (driver_clicked) then
		stats.set_int("MPX_H3OPT_CREWDRIVER", new_driver)
	end

	if (new_driver > 0) then
		local carList = {
			[1] = { --Karim Deniz
				"Issi Classic", "Asbo", "Kanjo", "Sentinel Classic"
			},
			[2] = { --Taliana Martinez
				"Retinue MK II", "Drift Yosemite", "Sugoi", "Jugular"
			},
			[3] = { --Eddie Toh
				"Sultan Classic", "Guantlet Classic", "Ellie", "Komoda"
			},
			[4] = { --Zach Nelson
				"Manchez", "Stryder", "Defiler", "Lectro"
			},
			[5] = { --Chester McCoy
				"Zhaba", "Vagrant", "Outlaw", "Everon"
			},
		}
		local new_car, car_clicked = ImGui.Combo(
			_T("CP_HEIST_GETAWAY_VEHS"),
			casino_heist_cars,
			carList[new_driver],
			4
		)
		if (car_clicked) then
			stats.set_int("MPX_H3OPT_VEHS", new_car)
		end
	end

	local new_hacker, hacker_clicked = ImGui.Combo(
		_T("CP_HEIST_HACKER"),
		casino_heist_hacker,
		{ "Unselected", "Rickie Lukens", "Christian Feltz", "Yohan Blair", "Avi Schwartzman", "Page Harris" },
		6
	)
	if (hacker_clicked) then
		stats.set_int("MPX_H3OPT_CREWHACKER", new_hacker)
	end

	local new_masks, masks_clicked = ImGui.Combo(
		_T("CP_HEIST_MASKS"),
		casino_heist_masks,
		{
			"Unselected",
			"Geometric Set",
			"Hunter Set",
			"Oni Half Mask Set",
			"Emoji Set",
			"Ornate Skull Set",
			"Lucky Fruit Set",
			"Gurilla Set",
			"Clown Set",
			"Animal Set",
			"Riot Set",
			"Oni Set",
			"Hockey Set"
		},
		13
	)
	if (masks_clicked) then
		stats.set_int("MPX_H3OPT_MASKS", new_masks)
	end

	ImGui.PopItemWidth()
	GUI:HeaderText(_T("GENERIC_OPTIONS_LABEL"), { separator = true, spacing = true })
	GVars.features.dunk.ch_cart_autograb, _ = GUI:CustomToggle(
		_T("CP_HEIST_AUTOGRAB"),
		GVars.features.dunk.ch_cart_autograb
	) -- this was disabled for no reason

	-- this serves as a "cooldown disabler" as well because you need to reset it anyway to be able to replay
	-- so we don't need a separate cooldown button or checkbox
	if (GUI:Button(_T("CP_HEIST_UNLOCK_ALL"))) then
		stats.set_int("MPX_H3OPT_ACCESSPOINTS", -1)
		stats.set_int("MPX_H3OPT_POI", -1)
		stats.set_int("MPX_H3OPT_BITSET0", -1)
		stats.set_int("MPX_H3OPT_BITSET1", -1)
		stats.set_int("MPX_H3OPT_BODYARMORLVL", 3)
		stats.set_int("MPX_H3OPT_DISRUPTSHIP", 3)
		stats.set_int("MPX_H3OPT_KEYLEVELS", 2)
		stats.set_int("MPX_H3_COMPLETEDPOSIX", 0)
		stats.set_int("MPX_CAS_HEIST_FLOW", -1)
		stats.set_int("MPPLY_H3_COOLDOWN", 0)
		stats.set_packed_stat_bool(26969, true) --Unlock High Roller
	end

	if (GUI:Button(_T("CP_HEIST_ZERO_AI_CUTS"))) then
		tunables.set_int("CH_LESTER_CUT", 0)
		tunables.set_int("HEIST3_PREPBOARD_GUNMEN_KARL_CUT", 0)
		tunables.set_int("HEIST3_PREPBOARD_GUNMEN_GUSTAVO_CUT", 0)
		tunables.set_int("HEIST3_PREPBOARD_GUNMEN_CHARLIE_CUT", 0)
		tunables.set_int("HEIST3_PREPBOARD_GUNMEN_CHESTER_CUT", 0)
		tunables.set_int("HEIST3_PREPBOARD_GUNMEN_PATRICK_CUT", 0)
		tunables.set_int("HEIST3_DRIVERS_KARIM_CUT", 0)
		tunables.set_int("HEIST3_DRIVERS_TALIANA_CUT", 0)
		tunables.set_int("HEIST3_DRIVERS_EDDIE_CUT", 0)
		tunables.set_int("HEIST3_DRIVERS_ZACH_CUT", 0)
		tunables.set_int("HEIST3_DRIVERS_CHESTER_CUT", 0)
		tunables.set_int("HEIST3_HACKERS_CHRISTIAN_CUT", 0)
		tunables.set_int("HEIST3_HACKERS_YOHAN_CUT", 0)
		tunables.set_int("HEIST3_HACKERS_AVI_CUT", 0)
		tunables.set_int("HEIST3_HACKERS_RICKIE_CUT", 0)
		tunables.set_int("HEIST3_HACKERS_PAIGE_CUT", 0)
		tunables.set_int("HEIST3_FINALE_CLEAN_VEHICLE", 0)
		tunables.set_int("HEIST3_FINALE_DECOY_GUNMAN", 0)
	end

	if (GUI:Button(_T("CP_HEIST_MAX_PLAYER_CUTS"))) then
		local bgchpco = SGSL:Get(SGSL.data.gb_casino_heist_planning_cut_offset):GetValue()
		local gbchp = SGSL:Get(SGSL.data.gb_casino_heist_planning):AsGlobal():At(bgchpco)
		for i = 1, 4, 1 do
			gbchp:At(i):WriteInt(100)
		end
	end
end

local function DrawDunk()
	if (not Game.IsOnline() or not Backend:IsUpToDate()) then
		ImGui.Text(_T("GENERIC_OFFLINE_OR_OUTDATED"))
		return
	end

	if (ImGui.BeginTabBar("##dunkBar")) then
		if ImGui.BeginTabItem(_T("CASINO_GAMBLING_TAB")) then
			drawGamblingTab()
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem(_T("CP_CASINO_HEIST_TAB")) then
			drawHeistTab()
			ImGui.EndTabItem()
		end
		ImGui.EndTabBar()
	end
end

GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, "Casino Pacino", DrawDunk)
