-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local SGSL = require("includes.services.SGSL")


---@class IManagedValueCtorData
---@field defs array<{ t: string|joaat_t, v: integer|float|boolean, bit_index?: integer, obj_type: eManagedValueType, data_type?: eManagedValueDataType }>
---@field get_state fun(): boolean

local eDataType <const>  = Enums.eManagedValueDataType
local eValueType <const> = Enums.eManagedValueType


---@class RawBusinessData
local RawBusinessData <const> = {
	---@type dict<IManagedValueCtorData>
	Cooldowns           = {
		["mc_work_cd"] = {
			get_state = function() return GVars.features.yrv3.mc_work_cd end,
			defs      = { { t = "BIKER_CLUB_WORK_COOLDOWN_GLOBAL", v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT } },
		},
		["hangar_cd"] = {
			get_state = function() return GVars.features.yrv3.hangar_cd end,
			defs      = {
				{ t = "SMUG_STEAL_EASY_COOLDOWN_TIMER", v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT },
				{ t = "SMUG_STEAL_MED_COOLDOWN_TIMER",  v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT },
				{ t = "SMUG_STEAL_HARD_COOLDOWN_TIMER", v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT },
			},
		},
		["nc_management_cd"] = {
			get_state = function() return GVars.features.yrv3.nc_management_cd end,
			defs      = { { t = "BB_CLUB_MANAGEMENT_CLUB_MANAGEMENT_MISSION_COOLDOWN", v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT } },
		},
		["nc_vip_mission_chance"] = {
			get_state = function() return GVars.features.yrv3.nc_vip_mission_chance end,
			defs      = { { t = "NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT", v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT } },
		},
		["security_missions_cd"] = {
			get_state = function() return GVars.features.yrv3.security_missions_cd end,
			defs      = { { t = "FIXER_SECURITY_CONTRACT_COOLDOWN_TIME", v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT } },
		},
		["ie_vehicle_steal_cd"] = {
			get_state = function() return GVars.features.yrv3.ie_vehicle_steal_cd end,
			defs      = { { t = "IMPEXP_STEAL_COOLDOWN", v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT } },
		},
		["ie_vehicle_sell_cd"] = {
			get_state = function() return GVars.features.yrv3.ie_vehicle_sell_cd end,
			defs      = {
				{ t = "IMPEXP_SELL_COOLDOWN",       v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT },
				{ t = "IMPEXP_SELL_1_CAR_COOLDOWN", v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT },
				{ t = "IMPEXP_SELL_2_CAR_COOLDOWN", v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT },
				{ t = "IMPEXP_SELL_3_CAR_COOLDOWN", v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT },
				{ t = "IMPEXP_SELL_4_CAR_COOLDOWN", v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT },
			},
		},
		["ceo_crate_buy_cd"] = {
			get_state = function() return GVars.features.yrv3.ceo_crate_buy_cd end,
			defs      = {
				{ t = "EXEC_BUY_COOLDOWN",      v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT },
				{ t = "EXEC_BUY_FAIL_COOLDOWN", v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT },
			},
		},
		["ceo_crate_sell_cd"] = {
			get_state = function() return GVars.features.yrv3.ceo_crate_sell_cd end,
			defs      = {
				{ t = "EXEC_SELL_COOLDOWN",      v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT },
				{ t = "EXEC_SELL_FAIL_COOLDOWN", v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT },
			},
		},
		["dax_work_cd"] = {
			get_state = function() return GVars.features.yrv3.dax_work_cd end,
			defs      = { { t = "MPX_XM22JUGGALOWORKCDTIMER", v = 0, obj_type = eValueType.STAT, data_type = eDataType.INT } },
		},
		["garment_rob_cd"] = {
			get_state = function() return GVars.features.yrv3.garment_rob_cd end,
			defs      = { { t = "MPX_HACKER24_ROBBERY_CD", v = 0, obj_type = eValueType.STAT, data_type = eDataType.INT } },
		},
		["cwash_legal_work_cd"] = {
			get_state = function() return GVars.features.yrv3.cwash_legal_work_cd end,
			defs      = { { t = "MPX_T25_CW_LEG_CD", v = 0, obj_type = eValueType.STAT, data_type = eDataType.INT } },
		},
		["cwash_illegal_work_cd"] = {
			get_state = function() return GVars.features.yrv3.cwash_illegal_work_cd end,
			defs      = { { t = "MPX_T25_CW_ILEG_CD", v = 0, obj_type = eValueType.STAT, data_type = eDataType.INT } },
		},
		["weedshop_legal_work_cd"] = {
			get_state = function() return GVars.features.yrv3.weedshop_legal_work_cd end,
			defs      = { { t = "MPX_T25_WS_LEG_CD", v = 0, obj_type = eValueType.STAT, data_type = eDataType.INT } },
		},
		["weedshop_illegal_work_cd"] = {
			get_state = function() return GVars.features.yrv3.weedshop_illegal_work_cd end,
			defs      = { { t = "MPX_T25_WS_ILEG_CD", v = 0, obj_type = eValueType.STAT, data_type = eDataType.INT } },
		},
		["helitours_legal_work_cd"] = {
			get_state = function() return GVars.features.yrv3.helitours_legal_work_cd end,
			defs      = { { t = "MPX_T25_WS_LEG_CD", v = 0, obj_type = eValueType.STAT, data_type = eDataType.INT } },
		},
		["helitours_illegal_work_cd"] = {
			get_state = function() return GVars.features.yrv3.helitours_illegal_work_cd end,
			defs      = { { t = "MPX_T25_HT_ILEG_CD", v = 0, obj_type = eValueType.STAT, data_type = eDataType.INT } },
		},
		["sy_disable_rob_cd"] = {
			get_state = function() return GVars.features.yrv3.sy_disable_rob_cd end,
			defs      = { { t = "MPX_SALV23_VEHROB_CD", v = 0, obj_type = eValueType.STAT, data_type = eDataType.INT } },
		},
		["sy_disable_tow_cd"] = {
			get_state = function() return GVars.features.yrv3.sy_disable_tow_cd end,
			defs      = { { t = 1521767918, v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT } },
		},
		["cfr_cd"] = {
			get_state = function() return GVars.features.yim_heists.cfr_cd end,
			defs      = { { t = "MPX_SALV23_CFR_COOLDOWN", v = 0, obj_type = eValueType.STAT, data_type = eDataType.INT } },
		},
		["knoway_cd"] = {
			get_state = function() return GVars.features.yim_heists.knoway_cd end,
			defs      = { { t = "MPX_M25_AVI_MISSION_CD", v = 0, obj_type = eValueType.STAT, data_type = eDataType.INT } },
		},
		["dre_cd"] = {
			get_state = function() return GVars.features.yim_heists.dre_cd end,
			defs      = { { t = "MPX_FIXER_STORY_COOLDOWN", v = 0, obj_type = eValueType.STAT, data_type = eDataType.INT } },
		},
		["ogfa_cd"] = {
			get_state = function() return GVars.features.yim_heists.ogfa_cd end,
			defs      = { { t = "MPX_HACKER24_MFM_COOLDOWN", v = 0, obj_type = eValueType.STAT, data_type = eDataType.INT } },
		},
	},
	ScriptDisplayNames  = {
		["fm_content_smuggler_sell"] = "Hangar (Land. Not supported.)",
		["gb_smuggler"]              = "Hangar (Air)",
		["gb_contraband_sell"]       = "CEO",
		["gb_gunrunning"]            = "Bunker",
		["gb_biker_contraband_sell"] = "Biker Business",
		["business_battles_sell"]    = "Nightclub",
		["fm_content_acid_lab_sell"] = "Acid Lab",
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
	ScriptsToTerminate  = {
		"appArcadeBusinessHub",
		"appsmuggler",
		"appbikerbusiness",
		"appbunkerbusiness",
		"appbusinesshub"
	},
	SellScripts         = {
		["gb_smuggler"] = function()
			local GBSMUG_OBJ   = SGSL:Get(SGSL.data.gb_smuggler_sell_air_local_1)
			local GBSMUG_LOCAL = GBSMUG_OBJ:AsLocal()
			local offset1      = GBSMUG_OBJ:GetOffset(1)
			local offset2      = SGSL:Get(SGSL.data.gb_smuggler_sell_air_local_2):GetOffset(1)
			GBSMUG_LOCAL:At(offset1):WriteInt(0)
			GBSMUG_LOCAL:At(offset2):WriteInt(1)
		end,
		["gb_gunrunning"] = function()
			-- TODO: fix this. this is bad. seccess depends on mission type (iLocal_1266.f_1)
			-- this just forces mission failure by setting the number of delivery vehicles to 0 (it only succeeds on type 16)
			-- but since we set the amount delivered to non-zero, you get paid nonetheless.
			-- there's also a side effect that could be used as an exploit but will be almost 100% bannable:
			-- 		we can force mission subtype to 16 and always set delivered amount to num_vehs * 5. This would
			-- 		guarantee a mission success everytime but the payment would end up being something nonsensical
			-- 		like $10.5M on subtype 18 (the two semi-trucks mission) you get paid x10 what you should lol
			--
			-- Local_1266.f_573 cancels the mission if set to 3
			local GBGR_LOCAL = SGSL:Get(SGSL.data.gb_gunrunning_sell_local):AsLocal()
			local offset2    = SGSL:Get(SGSL.data.bunker_sell_amt_delivered):GetOffset(1)
			local offset3    = SGSL:Get(SGSL.data.bunker_sell_num_vehs):GetOffset(1)
			-- local vehicles   = GBGR_LOCAL:At(offset3):ReadInt()
			-- local mission    = GBGR_LOCAL:At(1):ReadInt()
			-- local num        = (mission == 16 or mission == 14) and 5 or 1 -- func_148()
			GBGR_LOCAL:At(offset2):WriteInt(1)
			GBGR_LOCAL:At(offset3):WriteInt(0)
		end,
		["gb_contraband_sell"] = function()
			SGSL:Get(SGSL.data.gb_contraband_sell_local)
				:AsLocal()
				:At(1)
				:WriteInt(99999)
		end,
		["gb_biker_contraband_sell"] = function()
			local GBBKR_OBJ   = SGSL:Get(SGSL.data.biker_deliveries_local)
			local GBBKR_LOCAL = GBBKR_OBJ:AsLocal()
			local deliveries  = GBBKR_OBJ:GetOffset(1)
			local target      = SGSL:Get(SGSL.data.biker_required_deliveries_local):GetOffset(1)
			local value       = GBBKR_LOCAL:At(target):ReadInt()
			GBBKR_LOCAL:At(deliveries):WriteInt(value)
		end,
		["business_battles_sell"] = function()
			local Obj              = SGSL:Get(SGSL.data.bb_sell_local)
			local missionState     = SGSL:Get(SGSL.data.bb_sell_mission_state_offset):GetValue()
			local vehicleArray     = SGSL:Get(SGSL.data.bb_sell_vehicle_array_offset):GetValue()
			local BB_SELL          = Obj:AsLocal()
			local delivReq         = Obj:GetOffset(1)
			local delivMade        = Obj:GetOffset(2)
			local deliveryVehLocal = BB_SELL:At(vehicleArray):At(0, 42)

			BB_SELL:At(delivMade):WriteInt(BB_SELL:At(delivReq):ReadInt())
			deliveryVehLocal:At(29):WriteInt(deliveryVehLocal:At(30):ReadInt())
			BB_SELL:At(missionState):At(1):WriteInt(4)
			BB_SELL:At(missionState):WriteInt(30)
		end,
		-- ["fm_content_acid_lab_sell"] = function()
		-- 	local deliveriesObj    = SGSL:Get(SGSL.data.acid_lab_sell_deliveries_local)
		-- 	local missionStateObj  = SGSL:Get(SGSL.data.acid_lab_sell_mission_state_local)
		-- 	local genericBitset    = SGSL:Get(SGSL.data.acid_lab_sell_gen_bs):AsLocal()
		-- 	local deliveriesOffset = deliveriesObj:GetOffset(1)
		-- 	local deliveriesLocal  = deliveriesObj:AsLocal():At(deliveriesOffset)

		-- 	deliveriesLocal:At(1):WriteInt(deliveriesLocal:ReadInt())
		-- 	genericBitset:At(1):SetBit(11) -- func_594(11)
		-- 	missionStateObj:AsLocal():At(missionStateObj:GetOffset(1)):WriteInt(4)
		-- end
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
	---@alias BusinessHubs array<{ name: string, vpu_tunable: string, max_units_tunable: string, prod_time_tunable: string }>
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
				property_stat   = "MPX_ARCADE_OWNED",
				cash_value_stat = "MPX_ARCADE_SAFE_CASH_VALUE",
				paytime_stat    = "MPX_ARCADE_PAY_TIME_LEFT",
				interior_id     = 278273,
				room_hash       = 3710124102, -- MAINW_RM
				property_key    = "Arcades",
				get_max_cash    = function() return tunables.get_int("MAXARCADESAFESTORAGE") end,
				global_offset   = function() return 439 + 5 end
			},
			{
				property_stat   = "MPX_FIXER_HQ_OWNED",
				cash_value_stat = "MPX_FIXER_SAFE_CASH_VALUE",
				paytime_stat    = "MPX_FIXER_PASSIVE_PAY_TIME_LEFT",
				interior_id     = 288257,
				room_hash       = 767622941, -- ROOM_MAIN
				property_key    = "Agencies",
				get_max_cash    = function() return tunables.get_int("MAXFIXERHQSAFESTORAGE") end,
				global_offset   = function() return 519 + 2 end
			},
			{
				property_stat   = "MPX_BAIL_OFFICE_OWNED",
				cash_value_stat = "MPX_BAIL_SAFE_CASH_VALUE",
				property_key    = "BailOffices",
				interior_id     = 295425,
				room_hash       = 2990789022, -- ROOM_OFFICE
				get_max_cash    = function() return tunables.get_int(-1736487760) end,
				global_offset   = function()
					local offset = Game.IsEnhanced() and 532 or 531 -- /\*88\d{1}\*/\]\.f_260\.f_53\d{1}\.f_2 = \w+;
					return offset + 2
				end
				-- no paytime_stat; this functions somewhat similar to the clubhouse duffle
			},
			{
				property_stat   = "MPX_HACKER_DEN_OWNED",
				cash_value_stat = "MPX_HDEN24_SAFE_CASH_VALUE",
				paytime_stat    = "MPX_HDEN24_PAY_TIME_LEFT",
				property_key    = "HackerDen",
				interior_id     = 297729,
				room_hash       = 1055494658, -- ROOM_WORKSHOP
				get_max_cash    = function() return tunables.get_int(-792265290) end,
				global_offset   = function()
					local offset = Game.IsEnhanced() and 544 or 543
					return offset + 2
				end
			},
		},
		fronts = {
			salvage_yard = {
				cash_value_stat = "MPX_SALVAGE_SAFE_CASH_VALUE",
				paytime_stat    = "MPX_SALVAGE_PAY_TIME_LEFT",
				interior_id     = 293377,
				room_hash       = 1287104603, -- SHOP_OFFICE
				get_max_cash    = function()
					if (stats.get_int("MPX_SALVAGE_YARD_WALL_SAFE") == 1) then
						return tunables.get_int(594814186)
					end
					return tunables.get_int(1839510301)
				end,
				global_offset   = function() return 504 + 6 end
			},
			clubhouse = {
				cash_value_stat = "MPX_BIKER_BAR_RESUPPLY_CASH",
				interior_id     = 246273,
				room_hash       = 405984664, -- BIKERDLC_INT01_OFFRM
				get_max_cash    = function() return tunables.get_int("BIKER_PASSIVE_INCOME_BAG_LIMIT") end,
				-- there's no paytime stat; naturally there's still a timer
				-- but this uses a packed stat int and a bool global as well.
				-- Im not even gonna bother.
				-- hint: 36620
				global_offset   = function() return 394 end
			},
			nightclub = {
				cash_value_stat = "MPX_CLUB_SAFE_CASH_VALUE",
				paytime_stat    = "MPX_CLUB_PAY_TIME_LEFT",
				interior_id     = 271617,
				room_hash       = 3920029441, -- "INT_01_ORIFICE"
				get_max_cash    = function() return tunables.get_int("NIGHTCLUBMAXSAFEVALUE") end,
				global_offset   = function() return 364 + 6 end
			},
		},
	}
}

return RawBusinessData
