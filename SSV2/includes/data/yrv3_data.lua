-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local SGSL = require("includes.services.SGSL")

---@class RawBusinessData
local RawBusinessData <const> = {
	Cooldowns = {
		["mc_work_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.mc_work_cd
			end,
			onEnable = function()
				if (tunables.get_int("BIKER_CLUB_WORK_COOLDOWN_GLOBAL") > 0) then
					tunables.set_int("BIKER_CLUB_WORK_COOLDOWN_GLOBAL", 0)
				end
			end
		},
		["hangar_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.hangar_cd
			end,
			onEnable = function()
				local t = {
					"SMUG_STEAL_EASY_COOLDOWN_TIMER",
					"SMUG_STEAL_MED_COOLDOWN_TIMER",
					"SMUG_STEAL_HARD_COOLDOWN_TIMER",
				}
				for _, str in ipairs(t) do
					if (tunables.get_int(str) > 0) then
						tunables.set_int(str, 0)
					end
				end
			end
		},
		["nc_management_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.nc_management_cd
			end,
			onEnable = function()
				if (tunables.get_int("BB_CLUB_MANAGEMENT_CLUB_MANAGEMENT_MISSION_COOLDOWN") > 0) then
					tunables.set_int("BB_CLUB_MANAGEMENT_CLUB_MANAGEMENT_MISSION_COOLDOWN", 0)
				end
			end
		},
		["nc_vip_mission_chance"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.nc_vip_mission_chance
			end,
			onEnable = function()
				if (tunables.get_int("NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT") > 0) then
					tunables.set_int("NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT", 0)
				end
			end,
			onDisable = function()
				if (tunables.get_int("NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT") == 0) then
					tunables.set_int("NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT", 50)
				end
			end
		},
		["security_missions_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.security_missions_cd
			end,
			onEnable = function()
				if (tunables.get_int("FIXER_SECURITY_CONTRACT_COOLDOWN_TIME") > 0) then
					tunables.set_int("FIXER_SECURITY_CONTRACT_COOLDOWN_TIME", 0)
				end
			end
		},
		["ie_vehicle_steal_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.ie_vehicle_steal_cd
			end,
			onEnable = function()
				if (tunables.get_int("IMPEXP_STEAL_COOLDOWN") > 0) then
					tunables.set_int("IMPEXP_STEAL_COOLDOWN", 0)
				end
			end
		},
		["ie_vehicle_sell_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.ie_vehicle_sell_cd
			end,
			onEnable = function()
				if (tunables.get_int("IMPEXP_SELL_COOLDOWN") > 0) then
					tunables.set_int("IMPEXP_SELL_COOLDOWN", 0)
				end
				for i = 1, 4, 1 do
					local __t = _F("IMPEXP_SELL_%d_CAR_COOLDOWN", i)
					if (tunables.get_int(__t) > 0) then
						tunables.set_int(__t, 0)
					end
				end
			end
		},
		["ceo_crate_buy_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.ceo_crate_buy_cd
			end,
			onEnable = function()
				if (tunables.get_int("EXEC_BUY_COOLDOWN") > 0) then
					tunables.set_int("EXEC_BUY_COOLDOWN", 0)
				end
				if (tunables.get_int("EXEC_BUY_FAIL_COOLDOWN") > 0) then
					tunables.set_int("EXEC_BUY_FAIL_COOLDOWN", 0)
				end
			end
		},
		["ceo_crate_sell_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.ceo_crate_sell_cd
			end,
			onEnable = function()
				if (tunables.get_int("EXEC_SELL_COOLDOWN") > 0) then
					tunables.set_int("EXEC_SELL_COOLDOWN", 0)
				end
				if tunables.get_int("EXEC_SELL_FAIL_COOLDOWN") > 0 then
					tunables.set_int("EXEC_SELL_FAIL_COOLDOWN", 0)
				end
			end
		},
		["dax_work_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.dax_work_cd
			end,
			onEnable = function()
				if (stats.get_int("MPX_XM22JUGGALOWORKCDTIMER") > 0) then
					stats.set_int("MPX_XM22JUGGALOWORKCDTIMER", 0)
				end
			end
		},
		["garment_rob_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.garment_rob_cd
			end,
			onEnable = function()
				if (stats.get_int("MPX_HACKER24_ROBBERY_CD") > 0) then
					stats.set_int("MPX_HACKER24_ROBBERY_CD", 0)
				end
			end
		},
		["cfr_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.cfr_cd
			end,
			onEnable = function()
				if (stats.get_int("SALV23_CFR_COOLDOWN") > 0) then
					stats.set_int("SALV23_CFR_COOLDOWN", 0)
				end
			end
		},
		["cwash_legal_work_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.cwash_legal_work_cd
			end,
			onEnable = function()
				if (stats.get_int("T25_CW_LEG_CD") > 0) then
					stats.set_int("T25_CW_LEG_CD", 0)
				end
			end
		},
		["cwash_illegal_work_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.cwash_illegal_work_cd
			end,
			onEnable = function()
				if (stats.get_int("T25_CW_ILEG_CD") > 0) then
					stats.set_int("T25_CW_ILEG_CD", 0)
				end
			end
		},
		["weedshop_legal_work_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.weedshop_legal_work_cd
			end,
			onEnable = function()
				if (stats.get_int("T25_WS_LEG_CD") > 0) then
					stats.set_int("T25_WS_LEG_CD", 0)
				end
			end
		},
		["weedshop_illegal_work_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.weedshop_illegal_work_cd
			end,
			onEnable = function()
				if (stats.get_int("T25_WS_ILEG_CD") > 0) then
					stats.set_int("T25_WS_ILEG_CD", 0)
				end
			end
		},
		["helitours_legal_work_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.helitours_legal_work_cd
			end,
			onEnable = function()
				if (stats.get_int("T25_WS_LEG_CD") > 0) then
					stats.set_int("T25_WS_LEG_CD", 0)
				end
			end
		},
		["helitours_illegal_work_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.helitours_illegal_work_cd
			end,
			onEnable = function()
				if (stats.get_int("T25_HT_ILEG_CD") > 0) then
					stats.set_int("T25_HT_ILEG_CD", 0)
				end
			end
		},
		["sy_disable_rob_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.sy_disable_rob_cd
			end,
			onEnable = function()
				if (stats.get_int("MPX_SALV23_VEHROB_CD") > 0) then
					stats.set_int("MPX_SALV23_VEHROB_CD", 0)
				end
			end
		},
		["sy_disable_rob_weekly_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.sy_disable_rob_weekly_cd
			end,
			onEnable = function()
				local week_sync = stats.get_int("MPX_SALV23_WEEK_SYNC")
				if (tunables.get_int("SALV23_VEH_ROBBERY_WEEK_ID") == stats.get_int("MPX_SALV23_WEEK_SYNC")) then
					tunables.set_int("SALV23_VEH_ROBBERY_WEEK_ID", week_sync + 1)
				end
			end
		},
		["sy_disable_tow_cd"] = {
			dirty = false,
			gstate = function()
				return GVars.features.yrv3.sy_disable_tow_cd
			end,
			onEnable = function()
				if (tunables.get_int(1521767918) > 0) then -- 120000ms
					tunables.set_int(1521767918, 0)
				end
			end
		},
	},
	SellScripts = {
		["gb_smuggler"] = { -- air
			{
				l = (function() return SGSL:Get(SGSL.data.gb_smuggler_sell_air_local_1):GetValue() end)(),
				o = (function() return SGSL:Get(SGSL.data.gb_smuggler_sell_air_local_1):GetOffset(1) end)(),
				v = 0
			},
			{
				l = (function() return SGSL:Get(SGSL.data.gb_smuggler_sell_air_local_2):GetValue() end)(),
				o = (function() return SGSL:Get(SGSL.data.gb_smuggler_sell_air_local_2):GetOffset(1) end)(),
				v = 1
			},
		},
		["gb_gunrunning"] = {
			{
				l = (function() return SGSL:Get(SGSL.data.gb_gunrunning_sell_local_1):GetValue() end)(),
				o = (function() return SGSL:Get(SGSL.data.gb_gunrunning_sell_local_1):GetOffset(1) end)(),
				v = 1 -- this is always 1 anyway // observed using Arthur's scrDbg
			},
			{
				l = (function() return SGSL:Get(SGSL.data.gb_gunrunning_sell_local_1):GetValue() end)(),
				o = (function() return SGSL:Get(SGSL.data.gb_gunrunning_sell_local_2):GetOffset(1) end)(),
				v = 1 -- amount delivered
			},
			{
				l = (function() return SGSL:Get(SGSL.data.gb_gunrunning_sell_local_1):GetValue() end)(),
				o = (function() return SGSL:Get(SGSL.data.gb_gunrunning_sell_local_3):GetOffset(1) end)(),
				v = 0 -- number of delivery vehicles
			},
			-- Local_1266.f_573 cancels the mission if set to 3
		},
		["gb_contraband_sell"] = {
			{
				l = (function() return SGSL:Get(SGSL.data.gb_contraband_sell_local):GetValue() end)(),
				o = 1,
				v = 99999
			},
		},
		["gb_biker_contraband_sell"] = {
			{
				l = (function() return SGSL:Get(SGSL.data.gb_biker_contraband_sell_local):GetValue() end)(),
				o = (function() return SGSL:Get(SGSL.data.gb_biker_contraband_sell_local):GetOffset(1) end)(),
				v = 15
			},
		},
		["fm_content_acid_lab_sell"] = {
			b = (function() return SGSL:Get(SGSL.data.acid_lab_sell_bitset):GetValue() end)(),
			l = (function() return SGSL:Get(SGSL.data.acid_lab_sell_local):GetValue() end)(),
			o = (function() return SGSL:Get(SGSL.data.acid_lab_sell_local):GetOffset(1) end)(),
		},
	},
	SellMissionTunables = {
		["CEO"] = {
			type = "bool",
			tuneable = {
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
		["Biker"] = {
			type = "bool",
			tuneable = {
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
		["Nightclub"] = {
			type = "float",
			tuneable = {
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
		["Hangar"] = {
			type = "float",
			tuneable = {
				"SMUG_SELL_HEAVY_LIFTING_WEIGHTING",
				"SMUG_SELL_CONTESTED_WEIGHTING",
				"SMUG_SELL_AGILE_DELIVERY_WEIGHTING",
				"SMUG_SELL_FLYING_FORTRESS_WEIGHTING",
				"SMUG_SELL_AIR_DELIVERY_WEIGHTING",
				"SMUG_SELL_AIR_POLICE_WEIGHTING",
				"SMUG_SELL_UNDER_THE_RADAR_WEIGHTING"
			},
		},
	},
	CEOWarehouses = {
		{ size = 0, max = 16,  coords = vec3:new(51.311188, -2568.470947, 6.004591) },
		{ size = 0, max = 16,  coords = vec3:new(-1081.083740, -1261.013184, 5.648909) },
		{ size = 0, max = 16,  coords = vec3:new(898.484314, -1031.882446, 34.966454) },
		{ size = 0, max = 16,  coords = vec3:new(249.246918, -1955.651978, 23.161957) },
		{ size = 0, max = 16,  coords = vec3:new(-424.773499, 184.146530, 80.752899) },
		{ size = 2, max = 111, coords = vec3:new(-1045.004395, -2023.150146, 13.161570) },
		{ size = 1, max = 42,  coords = vec3:new(-1269.286133, -813.215820, 17.107399) },
		{ size = 2, max = 111, coords = vec3:new(-876.108032, -2734.502930, 13.844264) },
		{ size = 0, max = 16,  coords = vec3:new(272.409424, -3015.267090, 5.707359) },
		{ size = 1, max = 42,  coords = vec3:new(1563.832031, -2135.110840, 77.616447) },
		{ size = 1, max = 42,  coords = vec3:new(-308.772247, -2698.393799, 6.000292) },
		{ size = 1, max = 42,  coords = vec3:new(503.738037, -653.082642, 24.751144) },
		{ size = 1, max = 42,  coords = vec3:new(-528.074585, -1782.701904, 21.483055) },
		{ size = 1, max = 42,  coords = vec3:new(-328.013458, -1354.755371, 31.296524) },
		{ size = 1, max = 42,  coords = vec3:new(349.901184, 327.976440, 104.303856) },
		{ size = 2, max = 111, coords = vec3:new(922.555481, -1560.048950, 30.756647) },
		{ size = 2, max = 111, coords = vec3:new(762.672363, -909.193054, 25.250854) },
		{ size = 2, max = 111, coords = vec3:new(1041.059814, -2172.653076, 31.488876) },
		{ size = 2, max = 111, coords = vec3:new(1015.361633, -2510.986572, 28.302608) },
		{ size = 2, max = 111, coords = vec3:new(-245.651718, 202.504669, 83.792648) },
		{ size = 1, max = 42,  coords = vec3:new(541.587646, -1944.362793, 24.985096) },
		{ size = 2, max = 111, coords = vec3:new(93.278641, -2216.144775, 6.033320) },
	},
	BikerBusinesses = {
		{ gxt = "MP_BWH_METH_1",   id = 3, coords = vec3:new(52.903, 6338.585, 31.35), },
		{ gxt = "MP_BWH_WEED_1",   id = 1, coords = vec3:new(416.7524, 6520.753, 27.7121), },
		{ gxt = "MP_BWH_CRACK_1",  id = 4, coords = vec3:new(51.7653, 6486.163, 31.428), },
		{ gxt = "MP_BWH_CASH_1",   id = 2, coords = vec3:new(-413.6606, 6171.938, 31.4782), },
		{ gxt = "MP_BWH_FAKEID_1", id = 0, coords = vec3:new(-163.6828, 6334.845, 31.5808), },
		{ gxt = "MP_BWH_METH_2",   id = 3, coords = vec3:new(1454.671, -1651.986, 67), },
		{ gxt = "MP_BWH_WEED_2",   id = 1, coords = vec3:new(102.14, 175.26, 104.56), },
		{ gxt = "MP_BWH_CRACK_2",  id = 4, coords = vec3:new(-1462.622, -381.826, 38.802), },
		{ gxt = "MP_BWH_CASH_2",   id = 2, coords = vec3:new(-1171.005, -1380.922, 4.937), },
		{ gxt = "MP_BWH_FAKEID_2", id = 0, coords = vec3:new(299.071, -759.072, 29.333), },
		{ gxt = "MP_BWH_METH_3",   id = 3, coords = vec3:new(201.8909, 2461.782, 55.6885), },
		{ gxt = "MP_BWH_WEED_3",   id = 1, coords = vec3:new(2848.369, 4450.147, 48.5139), },
		{ gxt = "MP_BWH_CRACK_3",  id = 4, coords = vec3:new(387.5332, 3585.042, 33.2922), },
		{ gxt = "MP_BWH_CASH_3",   id = 2, coords = vec3:new(636.6344, 2785.126, 42.0111), },
		{ gxt = "MP_BWH_FAKEID_3", id = 0, coords = vec3:new(1657.066, 4851.732, 41.9882), },
		{ gxt = "MP_BWH_METH_4",   id = 3, coords = vec3:new(1181.44, -3113.82, 6.03), },
		{ gxt = "MP_BWH_WEED_4",   id = 1, coords = vec3:new(136.973, -2472.795, 5.98), },
		{ gxt = "MP_BWH_CRACK_4",  id = 4, coords = vec3:new(-253.31, -2591.15, 5.97), },
		{ gxt = "MP_BWH_CASH_4",   id = 2, coords = vec3:new(671.451, -2667.502, 6.0812), },
		{ gxt = "MP_BWH_FAKEID_4", id = 0, coords = vec3:new(-331.52, -2778.97, 5.12), },
	},
	BikerTunables = {
		[0] = { max_units = 60, vpu = "BIKER_FAKEIDS_PRODUCT_VALUE", mult_1 = "BIKER_FAKEIDS_PRODUCT_VALUE_EQUIPMENT_UPGRADE", mult_2 = "BIKER_FAKEIDS_PRODUCT_VALUE_STAFF_UPGRADE" },
		[1] = { max_units = 80, vpu = "BIKER_WEED_PRODUCT_VALUE", mult_1 = "BIKER_WEED_PRODUCT_VALUE_EQUIPMENT_UPGRADE", mult_2 = "BIKER_WEED_PRODUCT_VALUE_STAFF_UPGRADE" },
		[2] = { max_units = 40, vpu = "BIKER_COUNTERCASH_PRODUCT_VALUE", mult_1 = "BIKER_COUNTERCASH_PRODUCT_VALUE_EQUIPMENT_UPGRADE", mult_2 = "BIKER_COUNTERCASH_PRODUCT_VALUE_STAFF_UPGRADE" },
		[3] = { max_units = 20, vpu = "BIKER_METH_PRODUCT_VALUE", mult_1 = "BIKER_METH_PRODUCT_VALUE_EQUIPMENT_UPGRADE", mult_2 = "BIKER_METH_PRODUCT_VALUE_STAFF_UPGRADE" },
		[4] = { max_units = 10, vpu = "BIKER_CRACK_PRODUCT_VALUE", mult_1 = "BIKER_CRACK_PRODUCT_VALUE_EQUIPMENT_UPGRADE", mult_2 = "BIKER_CRACK_PRODUCT_VALUE_STAFF_UPGRADE" },
	},
	Hangars = {
		{ coords = vec3:new(-1148.908447, -3406.064697, 13.945053) },
		{ coords = vec3:new(-1393.322021, -3262.968262, 13.944828) },
		{ coords = vec3:new(-2022.336304, 3154.936768, 32.810272) },
		{ coords = vec3:new(-1879.105957, 3106.792969, 32.810234) },
		{ coords = vec3:new(-2470.278076, 3274.427734, 32.835461) },
	},
	Bunkers = {
		[21] = { coords = vec3:new(494.680878, 3015.895996, 41.041725) },
		[22] = { coords = vec3:new(849.619812, 3024.425781, 41.266800) },
		[23] = { coords = vec3:new(40.422565, 2929.004395, 55.746357) },
		[24] = { coords = vec3:new(1571.949341, 2224.597168, 78.350952) },
		[25] = { coords = vec3:new(2107.135254, 3324.630615, 45.371754) },
		[26] = { coords = vec3:new(2488.706055, 3164.616699, 49.080124) },
		[27] = { coords = vec3:new(1798.502930, 4704.956543, 39.995476) },
		[28] = { coords = vec3:new(-754.225769, 5944.171875, 19.836382) },
		[29] = { coords = vec3:new(-388.333160, 4338.322754, 56.103130) },
		[30] = { coords = vec3:new(-3030.341797, 3334.570068, 10.105902) },
		[31] = { coords = vec3:new(-3156.140625, 1376.710693, 17.073570) },
	},
	Nightclubs = {
		{ name = "", coords = vec3:new(757.009, -1332.32, 26.1802) }, -- am_mp_nightclub.c func_5118 // case 102: *uParam5 is main entrance corona coords
		{ name = "", coords = vec3:new(345.7519, -978.8848, 28.2681) },
		{ name = "", coords = vec3:new(-120.906, -1260.49, 28.2088) },
		{ name = "", coords = vec3:new(5.53709, 221.35, 106.6566) },
		{ name = "", coords = vec3:new(871.47, -2099.57, 29.3768) },
		{ name = "", coords = vec3:new(-675.225, -2459.15, 12.8444) },
		{ name = "", coords = vec3:new(195.534, -3168.88, 4.7903) },
		{ name = "", coords = vec3:new(373.05, 252.13, 101.9097) },
		{ name = "", coords = vec3:new(-1283.38, -649.916, 25.5198) },
		{ name = "", coords = vec3:new(-1174.85, -1152.3, 4.56128) },
	},
	---@alias BusinessHubs array<{ name: string, vpu_tunable: string, max_units_tunable: string, prod_time_tunable: string }>
	BusinessHubs = {
		-- names are shortened and not localized because GXTs are too wide for our current UI
		{ name = "Cargo",   vpu_tunable = "BB_BUSINESS_VALUE_CARGO",            max_units_tunable = "BB_BUSINESS_TOTAL_MAX_UNITS_CARGO",            prod_time_tunable = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_CARGO" },
		{ name = "Weapons", vpu_tunable = "BB_BUSINESS_VALUE_WEAPONS",          max_units_tunable = "BB_BUSINESS_TOTAL_MAX_UNITS_WEAPONS",          prod_time_tunable = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_WEAPONS" },
		{ name = "Cocaine", vpu_tunable = "BB_BUSINESS_VALUE_COKE",             max_units_tunable = "BB_BUSINESS_TOTAL_MAX_UNITS_COKE",             prod_time_tunable = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_COKE" },
		{ name = "Meth",    vpu_tunable = "BB_BUSINESS_VALUE_METH",             max_units_tunable = "BB_BUSINESS_TOTAL_MAX_UNITS_METH",             prod_time_tunable = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_METH" },
		{ name = "Weed",    vpu_tunable = "BB_BUSINESS_VALUE_WEED",             max_units_tunable = "BB_BUSINESS_TOTAL_MAX_UNITS_WEED",             prod_time_tunable = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_WEED" },
		{ name = "Fake ID", vpu_tunable = "BB_BUSINESS_VALUE_FORGED_DOCUMENTS", max_units_tunable = "BB_BUSINESS_TOTAL_MAX_UNITS_FORGED_DOCUMENTS", prod_time_tunable = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_FORGED_DOCUMENTS" },
		{ name = "Cash",    vpu_tunable = "BB_BUSINESS_VALUE_COUNTERFEIT_CASH", max_units_tunable = "BB_BUSINESS_TOTAL_MAX_UNITS_COUNTERFEIT_CASH", prod_time_tunable = "BB_BUSINESS_DEFAULT_ACCRUE_TIME_COUNTERFEIT_CASH" },
	},
	-- index + 90
	Clubhouses = {
		{ gxt = "MP_PROP_CLUBH1",  coords = vec3:new(246.5035, -1798.7494, 26.1131) }, -- case 91:
		{ gxt = "MP_PROP_CLUBH2",  coords = vec3:new(-1464.5, -927.9, 9.0) },
		{ gxt = "MP_PROP_CLUBH3",  coords = vec3:new(30.0784, -1024.1604, 28.4469) },
		{ gxt = "MP_PROP_CLUBH4",  coords = vec3:new(45.0033, 2784.3918, 56.8782) },
		{ gxt = "MP_PROP_CLUBH5",  coords = vec3:new(-332.5679, 6069.1445, 30.2175) },
		{ gxt = "MP_PROP_CLUBH6",  coords = vec3:new(1738.4215, 3716.7786, 33.0787) },
		{ gxt = "MP_PROP_CLUBH7",  coords = vec3:new(947.9371, -1452.7367, 30.143) },
		{ gxt = "MP_PROP_CLUBH8",  coords = vec3:new(186.6051, 306.8702, 104.389) },
		{ gxt = "MP_PROP_CLUBH9",  coords = vec3:new(-31.2801, -200.3394, 51.3551) },
		{ gxt = "MP_PROP_CLUBH10", coords = vec3:new(2478.5203, 4082.1372, 36.8208) },
		{ gxt = "MP_PROP_CLUBH11", coords = vec3:new(-32.1085, 6407.398, 30.4903) },
		{ gxt = "MP_PROP_CLUBH12", coords = vec3:new(-1138.0574, -1572.1804, 3.4157) },
	},
	SalvageYards = {
		{ gxt = "CELL_SLVG_YRD", coords = vec3:new(-195.0317, 6269.1601, 31.4892) }, -- func_3737 // case 162:
		{ gxt = "CELL_SLVG_YRD", coords = vec3:new(2508.7229, 4110.6401, 38.3481) },
		{ gxt = "CELL_SLVG_YRD", coords = vec3:new(-509.6919, -1735.85, 19.1262) },
		{ gxt = "CELL_SLVG_YRD", coords = vec3:new(-15.3909, -1307.951, 29.2440) },
		{ gxt = "CELL_SLVG_YRD", coords = vec3:new(1194.7052, -1263.8588, 35.2128) },
	},
	-- index + 127
	Arcades = {
		{ gxt = "CELL_ARCADE", coords = vec3:new(-238.9248, 6230.4282, 31.5033) }, -- func_5639 // case 128:
		{ gxt = "CELL_ARCADE", coords = vec3:new(1710.6895, 4758.3442, 41.9292) },
		{ gxt = "CELL_ARCADE", coords = vec3:new(-103.9111, -1776.6021, 29.5181) },
		{ gxt = "CELL_ARCADE", coords = vec3:new(-618.2486, 283.322, 81.6805) },
		{ gxt = "CELL_ARCADE", coords = vec3:new(-1287.7996, -275.9392, 38.7089) },
		{ gxt = "CELL_ARCADE", coords = vec3:new(723.8805, -822.3783, 24.7562) },
	},
	-- index + 154
	Agencies = {
		{ gxt = "FHQ_E_O_3", coords = vec3:new(390.7725, -78.3233, 68.1805) }, -- func_4471 // case 155: uParam1->f_3
		{ gxt = "FHQ_E_O_3", coords = vec3:new(-1018.2380, -411.9423, 39.6161) },
		{ gxt = "FHQ_E_O_3", coords = vec3:new(-590.1196, -705.2702, 36.2811) },
		{ gxt = "FHQ_E_O_3", coords = vec3:new(-1040.2611, -760.1538, 19.8387) },
	},
	-- index + 166
	BailOffices = {
		{ gxt = "PIM_S_BAOF", coords = vec3:new(485.114, -943.441, 26.161) }, -- func_3540 // case 167: case 0: *uParam2
		{ gxt = "PIM_S_BAOF", coords = vec3:new(123.352, 13.748, 67.315) },
		{ gxt = "PIM_S_BAOF", coords = vec3:new(-1412.704, -654.563, 27.673) },
		{ gxt = "PIM_S_BAOF", coords = vec3:new(127.30589, -1709.8208, 28.28193) },
		{ gxt = "PIM_S_BAOF", coords = vec3:new(-66.372, 6506.075, 30.536) },
	},
	HackerDen = {
		{ gxt = "HD_GARNAME", coords = vec3:new(719.3386, -983.1850, 24.1402) },
	},
	CashSafes = {
		regular = {
			{
				property_stat   = "MPX_ARCADE_OWNED",
				cash_value_stat = "MPX_ARCADE_SAFE_CASH_VALUE",
				paytime_stat    = "MPX_ARCADE_PAY_TIME_LEFT",
				interior_id     = 278273,
				room_hash       = 3710124102, -- MAINW_RM
				raw_data_entry  = "Arcades",
				get_max_cash    = function()
					return tunables.get_int("MAXARCADESAFESTORAGE")
				end,
			},
			{
				property_stat   = "MPX_FIXER_HQ_OWNED",
				cash_value_stat = "MPX_FIXER_SAFE_CASH_VALUE",
				paytime_stat    = "MPX_FIXER_PASSIVE_PAY_TIME_LEFT",
				interior_id     = 288257,
				room_hash       = 767622941, -- ROOM_MAIN
				raw_data_entry  = "Agencies",
				get_max_cash    = function()
					return tunables.get_int("MAXFIXERHQSAFESTORAGE")
				end,
			},
			{
				property_stat   = "MPX_BAIL_OFFICE_OWNED",
				cash_value_stat = "MPX_BAIL_SAFE_CASH_VALUE",
				raw_data_entry  = "BailOffices",
				interior_id     = 295425,
				room_hash       = 2990789022, -- ROOM_OFFICE
				get_max_cash    = function()
					return tunables.get_int(-1736487760)
				end,
				-- no paytime_stat; this functions somewhat similar to the clubhouse duffle
			},
			{
				property_stat   = "MPX_HACKER_DEN_OWNED",
				cash_value_stat = "MPX_HDEN24_SAFE_CASH_VALUE",
				paytime_stat    = "MPX_HDEN24_PAY_TIME_LEFT",
				raw_data_entry  = "HackerDen",
				interior_id     = 297729,
				room_hash       = 1055494658, -- ROOM_WORKSHOP
				get_max_cash    = function()
					return tunables.get_int(-792265290)
				end,
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
			},
			clubhouse = {
				cash_value_stat = "MPX_BIKER_BAR_RESUPPLY_CASH",
				interior_id     = 246273,
				room_hash       = 405984664, -- BIKERDLC_INT01_OFFRM
				get_max_cash    = function()
					return tunables.get_int("BIKER_PASSIVE_INCOME_BAG_LIMIT")
				end,
				-- there's no paytime stat; naturally there's still a timer
				-- but this uses a packed stat int and a bool global as well.
				-- Im not even gonna bother.
				-- hint: 36620
			},
			nightclub = {
				cash_value_stat = "MPX_CLUB_SAFE_CASH_VALUE",
				paytime_stat    = "MPX_CLUB_PAY_TIME_LEFT",
				interior_id     = 271617,
				room_hash       = 3920029441, -- "INT_01_ORIFICE"
				get_max_cash    = function()
					return tunables.get_int("NIGHTCLUBMAXSAFEVALUE")
				end,
			},
		},
	}
}

return RawBusinessData
