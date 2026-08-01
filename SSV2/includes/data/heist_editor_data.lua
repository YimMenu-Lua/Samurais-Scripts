-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local eDataType          = Enums.eManagedValueDataType
local Pair               = require("includes.classes.Pair")
local newManagedTuneable = require("includes.structs.IManagedTuneable").new

-- TODO: Add a simple property manager service
---@class GenericProperty
---@field name string
---@field coords vec3

-- ---@enum eHeistCategory
-- local eHeistCategory          = {
-- 	Apartment   = 1,
-- 	Facility    = 2,
-- 	Arcade      = 3,
-- 	Agency      = 4,
-- 	Kosatka     = 5,
-- 	AutoShop    = 6,
-- 	HackerDen   = 7,
-- 	FieldHangar = 8,
-- 	Mansion     = 9,
-- }; Enums.eHeistCategory       = eHeistCategory


return {
	BoostableHeistNames      = {
		"HTITLE_TUT",
		"HTITLE_HUMANE",
		"HTITLE_PRISON",
		"HTITLE_NARC",
		"HTITLE_ORNATE",
		"ACH_ACHGO2_NAME",
		"ACH_ACHGO3_NAME",
		"ACH_ACHGO4_NAME",
		"CH_END_NAME",
		"DLCC_CONTR",
		"AWT_1026",
		"DLCC_FHAN",
		"DLCC_AVIM",
		"DLCC_KORTZ",
	},
	MansionPlanningRoomStats = {
		"MPX_MANSION_TH_PLANNING_ROOM",
		"MPX_MANSION_AJ_PLANNING_ROOM",
		"MPX_MANSION_MD_PLANNING_ROOM",
	},
	MansionStats             = {
		"MPX_MANSION_TH_OWNED",
		"MPX_MANSION_AJ_OWNED",
		"MPX_MANSION_MD_OWNED",
	},
	CostTunables             = {
		newManagedTuneable("SETUP_COST_FLEECA", "HEIST_SETUP_COST_FLEECA", eDataType.INT, 69),
		newManagedTuneable("SETUP_COST_HUMANE_LABS", "HEIST_SETUP_COST_HUMANE_LABS", eDataType.INT, 69),
		newManagedTuneable("SETUP_COST_PRISON_BREAK", "HEIST_SETUP_COST_PRISON_BREAK", eDataType.INT, 69),
		newManagedTuneable("SETUP_COST_SERIES_A", "HEIST_SETUP_COST_SERIES_A", eDataType.INT, 69),
		newManagedTuneable("SETUP_COST_PACIFIC_STANDARD", "HEIST_SETUP_COST_PACIFIC_STANDARD", eDataType.INT, 69),
		newManagedTuneable("HEIST3_SETUP_COST", "HEIST3_SETUP_COST", eDataType.INT, 69),
		newManagedTuneable("H2_COST_IAA_JOB", "H2_COST_IAA_JOB", eDataType.INT, 69),
		newManagedTuneable("H2_COST_SUB_JOB", "H2_COST_SUB_JOB", eDataType.INT, 69),
		newManagedTuneable("H2_COST_SILO_OPERATION", "H2_COST_SILO_OPERATION", eDataType.INT, 69),
		newManagedTuneable("H4_REPLAY_COST", "H4_REPLAY_COST", eDataType.INT, 69),
	},
	CasinoHeistData          = {
		approaches           = { "Unselected", "Silent & Sneaky", "The Big Con", "Aggressive" },
		targets              = { "Money", "Gold", "Art", "Diamonds" },
		gunmen               = { "Unselected", "Karl Abolaji", "Gustavo Mota", "Charlie Reed", "Chester McCoy", "Patrick McReary" },
		drivers              = { "Unselected", "Karim Deniz", "Taliana Martinez", "Eddie Toh", "Zach Nelson", "Chester McCoy" },
		hackers              = { "Unselected", "Rickie Lukens", "Christian Feltz", "Yohan Blair", "Avi Schwartzman", "Page Harris" },
		guns                 = {
			{ --Karl Abolaji
				{ '##1", "##2' },
				{ "Micro SMG Loadout", "Machine Pistol Loadout" },
				{ "Micro SMG Loadout", "Shotgun Loadout" },
				{ "Shotgun Loadout",   "Revolver Loadout" }
			},
			{ --Gustavo Fring
				{ '##1", "##2' },
				{ "Rifle Loadout", "Shotgun Loadout" },
				{ "Rifle Loadout", "Shotgun Loadout" },
				{ "Rifle Loadout", "Shotgun Loadout" },
			},
			{ --Charlie Reed
				{ '##1", "##2' },
				{ "SMG Loadout",            "Shotgun Loadout" },
				{ "Machine Pistol Loadout", "Shotgun Loadout" },
				{ "SMG Loadout",            "Shotgun Loadout" }
			},
			{ --Chester McCoy
				{ '##1", "##2' },
				{ "MK II Shotgun Loadout", "MK II Rifle Loadout" },
				{ "MK II SMG Loadout",     "MK II Rifle Loadout" },
				{ "MK II Shotgun Loadout", "MK II Rifle Loadout" }
			},
			{ --Laddie Paddie Sadie Enweird
				{ '##1", "##2' },
				{ "Combat PDW Loadout", "Rifle Loadout" },
				{ "Shotgun Loadout",    "Rifle Loadout" },
				{ "Shotgun Loadout",    "Combat MG Loadout" }
			}
		},
		cars                 = {
			{ "Issi Classic",   "Asbo",             "Kanjo",   "Sentinel Classic" }, --Karim Deniz
			{ "Retinue MK II",  "Drift Yosemite",   "Sugoi",   "Jugular" }, --Taliana Martinez
			{ "Sultan Classic", "Guantlet Classic", "Ellie",   "Komoda" },  --Eddie Toh
			{ "Manchez",        "Stryder",          "Defiler", "Lectro" },  --Zach Nelson
			{ "Zhaba",          "Vagrant",          "Outlaw",  "Everon" },  --Chester McCoy
		},
		masks                = {
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
		secondary_objectives = {
			Pair("MPX_H3OPT_BITSET0", -1),
			Pair("MPX_H3OPT_BITSET1", -1),
			Pair("MPX_H3OPT_ACCESSPOINTS", -1),
			Pair("MPX_H3OPT_POI", -1),
			Pair("MPX_H3OPT_BODYARMORLVL", 3),
			Pair("MPX_H3OPT_DISRUPTSHIP", 3),
			Pair("MPX_H3OPT_KEYLEVELS", 2),
			Pair("MPX_CAS_HEIST_FLOW", -1),
		},
		ai_cuts_tunables     = {
			"CH_LESTER_CUT",
			"HEIST3_PREPBOARD_GUNMEN_KARL_CUT",
			"HEIST3_PREPBOARD_GUNMEN_GUSTAVO_CUT",
			"HEIST3_PREPBOARD_GUNMEN_CHARLIE_CUT",
			"HEIST3_PREPBOARD_GUNMEN_CHESTER_CUT",
			"HEIST3_PREPBOARD_GUNMEN_PATRICK_CUT",
			"HEIST3_DRIVERS_KARIM_CUT",
			"HEIST3_DRIVERS_TALIANA_CUT",
			"HEIST3_DRIVERS_EDDIE_CUT",
			"HEIST3_DRIVERS_ZACH_CUT",
			"HEIST3_DRIVERS_CHESTER_CUT",
			"HEIST3_HACKERS_CHRISTIAN_CUT",
			"HEIST3_HACKERS_YOHAN_CUT",
			"HEIST3_HACKERS_AVI_CUT",
			"HEIST3_HACKERS_RICKIE_CUT",
			"HEIST3_HACKERS_PAIGE_CUT",
			"HEIST3_FINALE_CLEAN_VEHICLE",
			"HEIST3_FINALE_DECOY_GUNMAN",
		},
		setup_data           = {
			["approach"]      = { label = "CP_HEIST_APPROACH", stat = "MPX_H3OPT_APPROACH", combo_data_key = "approaches", data_size = 4 },
			["last_approach"] = { label = "CP_HEIST_LAST_APPROACH", stat = "MPX_H3_LAST_APPROACH", combo_data_key = "approaches", data_size = 4 },
			["hard_approach"] = { label = "CP_HEIST_HARD_APPROACH", stat = "MPX_H3_HARD_APPROACH", combo_data_key = "approaches", data_size = 4 },
			["target"]        = { label = "CP_HEIST_TARGET", stat = "MPX_H3OPT_TARGET", combo_data_key = "targets", data_size = 4 },
			["hacker"]        = { label = "CP_HEIST_HACKER", stat = "MPX_H3OPT_CREWHACKER", combo_data_key = "hackers", data_size = 6 },
			["masks"]         = { label = "CP_HEIST_MASKS", stat = "MPX_H3OPT_MASKS", combo_data_key = "masks", data_size = 13 },
			["gunman"]        = { label = "CP_HEIST_GUNMAN", stat = "MPX_H3OPT_CREWWEAP", combo_data_key = "gunmen", data_size = 6 },
			["driver"]        = { label = "CP_HEIST_DRIVER", stat = "MPX_H3OPT_CREWDRIVER", combo_data_key = "drivers", data_size = 6 },
			["weapons"]       = { label = "CP_HEIST_WEAPONS", stat = "MPX_H3OPT_WEAPS", combo_data_key = "guns", data_size = 5 },
			["cars"]          = { label = "CP_HEIST_GETAWAY_VEHS", stat = "MPX_H3OPT_VEHS", combo_data_key = "cars", data_size = 5 },
		},
		teleports            = {
			--[[ case 208:
			unk = { 2554f, -281.4f, -64.7f };
			unk.f_3 = "ch_DLC_Casino_Loading"; ]]
			{ label = "YH_TP_CH_LOADING_BAY", coords = vec3:new(2554, -281.4, -64.7) },
			{ label = "YH_TP_CH_UTIL_RM",     coords = vec3:new(2519.9, -255.3, -24.1) },
			{ label = "YH_TP_CH_ELEV_SHAFT",  coords = vec3:new(2572.9, -253.4, -64.7) },
			{ label = "YH_TP_CH_CASH_ROOM",   coords = vec3:new(2520.800293, -286.952271, -58.723015) },
			{ label = "YH_TP_CH_BASEMENT",    coords = vec3:new(2514.624756, -278.059235, -70.722969) },
			{ label = "YH_TP_CH_MANTRAP",     coords = vec3:new(2434.303711, -240.453247, -70.806534) },
			{ label = "YH_TP_CH_VAULT",       coords = vec3:new(2488.3, -267.4, -70.6) },
		}
	},
	CayoPericoData           = {
		primary_target         = { "Tequila", "Ruby Necklace", "Bearer Bonds", "Pink Diamond", "Madrazo Files", "Panther Statue" },
		weapons                = { "Unselected", "Aggressor", "Conspirator", "Crackshot", "Saboteur", "Marksman" },
		supply_truck_locations = { "Unselected", "Airport", "North Dock", "Main Dock East", "Main Dock West", "Compound" },
		setup_data             = {
			["primary_target"]   = { label = "YH_CAYO_TARGET_PRIMARY", stat = "MPX_H4CNF_TARGET", combo_data_key = "primary_target", data_size = 6 },
			["weapons"]          = { label = "YH_CAYO_WEAPONS", stat = "MPX_H4CNF_WEAPONS", combo_data_key = "weapons", data_size = 6 },
			["supply_truck_loc"] = { label = "YH_CAYO_TROJAN", stat = "MPX_H4CNF_TROJAN", combo_data_key = "supply_truck_locations", data_size = 6 },
		},
		secondary_objectives   = {
			Pair("MPX_H4LOOT_CASH_I", 16711680),
			Pair("MPX_H4LOOT_CASH_I_SCOPED", 16711680),
			Pair("MPX_H4LOOT_CASH_C", 0),
			Pair("MPX_H4LOOT_CASH_C_SCOPED", 0),
			Pair("MPX_H4LOOT_COKE_I", 255),
			Pair("MPX_H4LOOT_COKE_I_SCOPED", 255),
			Pair("MPX_H4LOOT_COKE_C", 0),
			Pair("MPX_H4LOOT_COKE_C_SCOPED", 0),
			Pair("MPX_H4LOOT_GOLD_I", 0),
			Pair("MPX_H4LOOT_GOLD_I_SCOPED", 0),
			Pair("MPX_H4LOOT_GOLD_C", 255),
			Pair("MPX_H4LOOT_GOLD_C_SCOPED", 255),
			Pair("MPX_H4LOOT_WEED_I", 65280),
			Pair("MPX_H4LOOT_WEED_I_SCOPED", 65280),
			Pair("MPX_H4LOOT_WEED_C", 0),
			Pair("MPX_H4LOOT_WEED_C_SCOPED", 0),
			Pair("MPX_H4LOOT_PAINT", 127),
			Pair("MPX_H4LOOT_PAINT_SCOPED", 127),
			Pair("MPX_H4LOOT_CASH_V", 83250),
			Pair("MPX_H4LOOT_COKE_V", 202500),
			Pair("MPX_H4LOOT_GOLD_V", 333333),
			Pair("MPX_H4LOOT_WEED_V", 135000),
			Pair("MPX_H4LOOT_PAINT_V", 180000),
			Pair("MPX_H4CNF_BS_GEN", 262143),
			Pair("MPX_H4CNF_BS_ENTR", 63),
			Pair("MPX_H4CNF_BS_ABIL", 63),
			Pair("MPX_H4CNF_WEP_DISRP", 3),
			Pair("MPX_H4CNF_ARM_DISRP", 3),
			Pair("MPX_H4CNF_HEL_DISRP", 3),
			Pair("MPX_H4CNF_APPROACH", -1),
			Pair("MPX_H4CNF_BOLTCUT", 4424),
			Pair("MPX_H4CNF_UNIFORM", 5256),
			Pair("MPX_H4CNF_GRAPPEL", 5156),
			Pair("MPX_H4_MISSIONS", -1),
			Pair("MPX_H4_PLAYTHROUGH_STATUS", 100),
		},
		teleports              = {
			{ label = "YH_TP_IH_ENTRANCE", coords = 5048.157, -5821.616, -12.726 },
		}
	},
}
