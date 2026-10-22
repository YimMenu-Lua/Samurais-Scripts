-- Original Samurai business metadata; V2 data definitions. GPL-3.0-or-later.
return {
	ScriptDisplayNames  = {
		fm_content_smuggler_sell = 'Hangar (Land. Not supported.)',
		gb_smuggler = 'Hangar (Air)',
		gb_contraband_sell = 'CEO',
		gb_gunrunning = 'Bunker',
		gb_biker_contraband_sell = 'Biker Business',
		business_battles_sell = 'Nightclub',
		fm_content_acid_lab_sell = 'Acid Lab',
	},
	NightclubNames      = {
		"Maisonette Los Santos",
		"Studio Los Santos",
		"GALAXY",
		"Gefangnis",
		"Omega",
		"Technologie",
		"Paradise",
		"The Palace",
		"Tony's Fun House",
	},
	SellMissionTunables = {
		["Biker"] = {
			type = "bool",
			tuneables = {
				"BIKER_DISABLE_SELL_CONVOY",
				"BIKER_DISABLE_SELL_PROVEN",
				"BIKER_DISABLE_SELL_FRIENDS_IN_NEED",
				"BIKER_DISABLE_SELL_BORDER_PATROL",
				"BIKER_DISABLE_SELL_HELICOPTER_DROP",
				"BIKER_DISABLE_SELL_POSTMAN",
				"BIKER_DISABLE_SELL_AIR_DROP_AT_SEA",
				"BIKER_DISABLE_SELL_STING_OP",
			}
		},
		["Bunker"] = {
			type = "float",
			tuneables = {
				"GR_AMBUSHED_AMBUSHED_WEIGHTING",
				"GR_HILL_CLIMB_HILL_CLIMB_WEIGHTING",
				"GR_ROUGH_TERRAIN_ROUGH_TERRAIN_WEIGHTING",
			},
		},
		["CEO"] = {
			type = "bool",
			tuneables = {
				"EXEC_DISABLE_SELL_AIRATTACKED",
				"EXEC_DISABLE_SELL_AIRDROP",
				"EXEC_DISABLE_SELL_AIRFLYLOW",
				"EXEC_DISABLE_SELL_AIRRESTRICTED",
				"EXEC_DISABLE_SELL_ATTACKED",
				"EXEC_DISABLE_SELL_DEFEND",
				"EXEC_DISABLE_SELL_NODAMAGE",
				"EXEC_DISABLE_SELL_SEAATTACKED",
				"EXEC_DISABLE_SELL_SEADEFEND",
				"EXEC_DISABLE_SELL_STING",
				"EXEC_DISABLE_SELL_STING_1",
				"EXEC_DISABLE_SELL_STING_2",
				"EXEC_DISABLE_SELL_STING_3",
				"EXEC_DISABLE_SELL_STING_4",
				"EXEC_DISABLE_SELL_STING_5",
				"EXEC_DISABLE_SELL_TRACKIFY"
			}
		},
		["Hangar"] = {
			type = "float",
			tuneables = {
				"SMUG_SELL_HEAVY_LIFTING_WEIGHTING",
				"SMUG_SELL_CONTESTED_WEIGHTING",
				"SMUG_SELL_AGILE_DELIVERY_WEIGHTING",
				"SMUG_SELL_FLYING_FORTRESS_WEIGHTING",
				"SMUG_SELL_AIR_DELIVERY_WEIGHTING",
				"SMUG_SELL_AIR_POLICE_WEIGHTING",
				"SMUG_SELL_UNDER_THE_RADAR_WEIGHTING"
			},
		},
		["Nightclub"] = {
			type = "float",
			tuneables = {
				"BB_SELL_MISSIONS_WEIGHTING_MULTI_DROP",
				"BB_SELL_MISSIONS_WEIGHTING_HACK_DROP",
				"BB_SELL_MISSIONS_WEIGHTING_ROADBLOCK",
				"BB_SELL_MISSIONS_WEIGHTING_PROTECT_BUYER",
				"BB_SELL_MISSIONS_WEIGHTING_UNDERCOVER_COPS",
				"BB_SELL_MISSIONS_WEIGHTING_OFFSHORE_TRANSFER",
				"BB_SELL_MISSIONS_WEIGHTING_NOT_A_SCRATCH",
				"BB_SELL_MISSIONS_WEIGHTING_FOLLOW_HELI",
				"BB_SELL_MISSIONS_WEIGHTING_FIND_BUYER"
			},
		},
	},
	BikerTunables       = {
		[0] = { max_units = 60, vpu = "BIKER_FAKEIDS_PRODUCT_VALUE", mult_1 = "BIKER_FAKEIDS_PRODUCT_VALUE_EQUIPMENT_UPGRADE", mult_2 = "BIKER_FAKEIDS_PRODUCT_VALUE_STAFF_UPGRADE" },
		[1] = { max_units = 80, vpu = "BIKER_WEED_PRODUCT_VALUE", mult_1 = "BIKER_WEED_PRODUCT_VALUE_EQUIPMENT_UPGRADE", mult_2 = "BIKER_WEED_PRODUCT_VALUE_STAFF_UPGRADE" },
		[2] = { max_units = 40, vpu = "BIKER_COUNTERCASH_PRODUCT_VALUE", mult_1 = "BIKER_COUNTERCASH_PRODUCT_VALUE_EQUIPMENT_UPGRADE", mult_2 = "BIKER_COUNTERCASH_PRODUCT_VALUE_STAFF_UPGRADE" },
		[3] = { max_units = 20, vpu = "BIKER_METH_PRODUCT_VALUE", mult_1 = "BIKER_METH_PRODUCT_VALUE_EQUIPMENT_UPGRADE", mult_2 = "BIKER_METH_PRODUCT_VALUE_STAFF_UPGRADE" },
		[4] = { max_units = 10, vpu = "BIKER_CRACK_PRODUCT_VALUE", mult_1 = "BIKER_CRACK_PRODUCT_VALUE_EQUIPMENT_UPGRADE", mult_2 = "BIKER_CRACK_PRODUCT_VALUE_STAFF_UPGRADE" },
	},
	---@alias BusinessHubs array<{ name: string, vpu_tunable: string, max_units_tunable: string, prod_time_tunable: string }>,
	BusinessHubs        = {
		{ vpu_tunable = "BB_BUSINESS_VALUE_CARGO",            max_units_tunable = "BB_BUSINESS_TOTAL_MAX_UNITS_CARGO",            prod_time_tunable = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_CARGO" },
		{ vpu_tunable = "BB_BUSINESS_VALUE_WEAPONS",          max_units_tunable = "BB_BUSINESS_TOTAL_MAX_UNITS_WEAPONS",          prod_time_tunable = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_WEAPONS" },
		{ vpu_tunable = "BB_BUSINESS_VALUE_COKE",             max_units_tunable = "BB_BUSINESS_TOTAL_MAX_UNITS_COKE",             prod_time_tunable = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_COKE" },
		{ vpu_tunable = "BB_BUSINESS_VALUE_METH",             max_units_tunable = "BB_BUSINESS_TOTAL_MAX_UNITS_METH",             prod_time_tunable = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_METH" },
		{ vpu_tunable = "BB_BUSINESS_VALUE_WEED",             max_units_tunable = "BB_BUSINESS_TOTAL_MAX_UNITS_WEED",             prod_time_tunable = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_WEED" },
		{ vpu_tunable = "BB_BUSINESS_VALUE_FORGED_DOCUMENTS", max_units_tunable = "BB_BUSINESS_TOTAL_MAX_UNITS_FORGED_DOCUMENTS", prod_time_tunable = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_FORGED_DOCUMENTS" },
		{ vpu_tunable = "BB_BUSINESS_VALUE_COUNTERFEIT_CASH", max_units_tunable = "BB_BUSINESS_TOTAL_MAX_UNITS_COUNTERFEIT_CASH", prod_time_tunable = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_COUNTERFEIT_CASH" },
	},
	CashSafes           = {
		regular = {
			{
				property_stat    = "MPX_ARCADE_OWNED",
				cash_value_stat  = "MPX_ARCADE_SAFE_CASH_VALUE",
				paytime_stat     = "MPX_ARCADE_PAY_TIME_LEFT",
				interior_id      = 278273,
				room_hash        = 3710124102, -- MAINW_RM
				property_key     = "Arcades",
				capacity_tunable = "MAXARCADESAFESTORAGE",
				global_offset    = 439 + 5
			},
			{
				property_stat    = "MPX_FIXER_HQ_OWNED",
				cash_value_stat  = "MPX_FIXER_SAFE_CASH_VALUE",
				paytime_stat     = "MPX_FIXER_PASSIVE_PAY_TIME_LEFT",
				interior_id      = 288257,
				room_hash        = 767622941, -- ROOM_MAIN
				property_key     = "Agencies",
				capacity_tunable = "MAXFIXERHQSAFESTORAGE",
				global_offset    = 519 + 2
			},
			{
				property_stat    = "MPX_BAIL_OFFICE_OWNED",
				cash_value_stat  = "MPX_BAIL_SAFE_CASH_VALUE",
				property_key     = "BailOffices",
				interior_id      = 295425,
				room_hash        = 2990789022, -- ROOM_OFFICE
				capacity_tunable = -1736487760,
				global_offset    = 534
				-- no paytime_stat; this functions somewhat similar to the clubhouse duffle
			},
			{
				property_stat    = "MPX_HACKER_DEN_OWNED",
				cash_value_stat  = "MPX_HDEN24_SAFE_CASH_VALUE",
				paytime_stat     = "MPX_HDEN24_PAY_TIME_LEFT",
				property_key     = "HackerDen",
				interior_id      = 297729,
				room_hash        = 1055494658, -- ROOM_WORKSHOP
				capacity_tunable = -792265290,
				global_offset    = 546
			},
		},
		fronts = {
			salvage_yard = {
				cash_value_stat = "MPX_SALVAGE_SAFE_CASH_VALUE",
				paytime_stat = "MPX_SALVAGE_PAY_TIME_LEFT",
				interior_id = 293377,
				room_hash = 1287104603, -- SHOP_OFFICE
				capacity_tunable = 1839510301,
				upgrade_stat = 'MPX_SALVAGE_YARD_WALL_SAFE',
				upgrade_tunable = 594814186,
				global_offset = 504 + 6
			},
			clubhouse = {
				cash_value_stat  = "MPX_BIKER_BAR_RESUPPLY_CASH",
				interior_id      = 246273,
				room_hash        = 405984664, -- BIKERDLC_INT01_OFFRM
				capacity_tunable = "BIKER_PASSIVE_INCOME_BAG_LIMIT",
				-- there's no paytime stat; naturally there's still a timer
				-- but this uses a packed stat int and a bool global as well.
				-- Im not even gonna bother.
				-- hint: 36620
				global_offset    = 394
			},
			nightclub = {
				cash_value_stat  = "MPX_CLUB_SAFE_CASH_VALUE",
				paytime_stat     = "MPX_CLUB_PAY_TIME_LEFT",
				interior_id      = 271617,
				room_hash        = 3920029441, -- "INT_01_ORIFICE"
				capacity_tunable = "NIGHTCLUBMAXSAFEVALUE",
				global_offset    = 364 + 6
			},
		},
	}
}
