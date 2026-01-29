-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local SGSL = require("includes.services.SGSL")

-- A table pretending to be an object
---@class CashSafe
---@field is_owned fun(): bool
---@field cash_value fun(): integer
---@field max_cash integer
---@field blip integer
---@field get_special_val? fun(): integer
---@field set_special_val? fun()

-- A table pretending to be an object
---@class MoneyFrontsBusiness : CashSafe
---@field cash_value? fun(): integer
---@field duffel_total? fun(): integer
---@field dirty_cash? fun(): integer
---@field blip? integer
---@field max_cash? integer
---@field max_heat integer
---@field gvar_key_1 string
---@field gvar_key_2 string
---@field cb1_clicked boolean
---@field cb2_clicked boolean
---@field on_cb1_click fun(this: YRV3, newVal: boolean)
---@field on_cb2_click fun(this: YRV3, newVal: boolean)
---@field coords vec3

---@class RawBusinessData
local RawBusinessData <const> = {
	---@type dict<CashSafe>
	BS_Default = {
		["Arcade"] = {
			is_owned = function()
				return stats.get_int("MPX_ARCADE_OWNED") ~= 0
			end,
			cash_value = function()
				return stats.get_int("MPX_ARCADE_SAFE_CASH_VALUE")
			end,
			max_cash = 1e5,
			blip = 740,
		},
		["Agency"] = {
			is_owned = function()
				return stats.get_int("MPX_FIXER_HQ_OWNED") ~= 0
			end,
			cash_value = function()
				return stats.get_int("MPX_FIXER_SAFE_CASH_VALUE")
			end,
			max_cash = 25e4,
			blip = 826,
		},
		["MC Clubhouse"] = {
			is_owned = function()
				return stats.get_int("MPX_PROP_CLUBHOUSE") ~= 0
			end,
			cash_value = function()
				return stats.get_int("MPX_BIKER_BAR_RESUPPLY_CASH")
			end,
			max_cash = 1e5,
			blip = 492,
		},
		["Bail Office"] = {
			is_owned = function()
				return stats.get_int("MPX_BAIL_OFFICE_OWNED") ~= 0
			end,
			cash_value = function()
				return stats.get_int("MPX_BAIL_SAFE_CASH_VALUE")
			end,
			max_cash = 1e5,
			blip = 893,
		},
		["Salvage Yard"] = {
			is_owned = function()
				return stats.get_int("MPX_SALVAGE_YARD_OWNED") ~= 0
			end,
			cash_value = function()
				return stats.get_int("MPX_SALVAGE_SAFE_CASH_VALUE")
			end,
			max_cash = 25e4,
			blip = 867,
		},
		["Garment Factory"] = {
			is_owned = function()
				return stats.get_int("MPX_HACKER_DEN_OWNED") ~= 0
			end,
			cash_value = function()
				return stats.get_int("MPX_HDEN24_SAFE_CASH_VALUE")
			end,
			max_cash = 1e5,
			blip = 900,
		},
	},
	---@type dict<MoneyFrontsBusiness>
	MF_Default = {
		["YRV3_CWASH_LABEL"] = {
			is_owned = function()
				return stats.get_int("MPX_SB_CAR_WASH_OWNED") ~= 0
			end,
			cash_value = function()
				return stats.get_int("MPX_CWASH_SAFE_CASH_VALUE")
			end,
			duffel_total = function()
				return stats.get_int("MPX_CAR_WASH_DUFFEL_VALUE")
			end,
			dirty_cash = function()
				local posix = stats.get_int("MPX_CAR_WASH_DUFFEL_POSIX")
				local pending_cash = stats.get_int("MPX_CAR_WASH_DUFFEL_PENDING") -- why is this always 35k even after it gets cleaned?
				return Time.epoch() < posix and pending_cash or 0
			end,
			get_special_val = function()
				return stats.get_packed_stat_int(24924)
			end,
			set_special_val = function()
				if (stats.get_packed_stat_int(24924) == 0) then
					return
				end

				stats.set_packed_stat_int(24924, 0)
			end,
			max_cash = 1e5,
			max_heat = 100,
			blip = 931,
			gvar_key_1 = "features.yrv3.cwash_legal_work_cd",
			gvar_key_2 = "features.yrv3.cwash_illegal_work_cd",
			cb1_clicked = false,
			cb2_clicked = false,
			on_cb1_click = function(yrv3, newVal)
				table.set_nested_key(GVars, "features.yrv3.cwash_legal_work_cd", newVal)
				yrv3:SetCooldownStateDirty("cwash_legal_work_cd", true)
			end,
			on_cb2_click = function(yrv3, newVal)
				table.set_nested_key(GVars, "features.yrv3.cwash_illegal_work_cd", newVal)
				yrv3:SetCooldownStateDirty("cwash_illegal_work_cd", true)
			end,
			coords = vec3:new(25.645266, -1412.290649, 29.362230)
		},
		["YRV3_WEED_SHOP_LABEL"] = {
			is_owned = function()
				return stats.get_int("MPX_SB_WEED_SHOP_OWNED") ~= 0
			end,
			get_special_val = function()
				return stats.get_packed_stat_int(24925)
			end,
			set_special_val = function()
				if (stats.get_packed_stat_int(24925) == 0) then
					return
				end

				stats.set_packed_stat_int(24925, 0)
			end,
			max_heat = 100,
			gvar_key_1 = "features.yrv3.weedshop_legal_work_cd",
			gvar_key_2 = "features.yrv3.weedshop_illegal_work_cd",
			cb1_clicked = false,
			cb2_clicked = false,
			---@param yrv3 YRV3
			on_cb1_click = function(yrv3, newVal)
				table.set_nested_key(GVars, "features.yrv3.weedshop_legal_work_cd", newVal)
				yrv3:SetCooldownStateDirty("weedshop_legal_work_cd", true)
			end,
			on_cb2_click = function(yrv3, newVal)
				table.set_nested_key(GVars, "features.yrv3.weedshop_illegal_work_cd", newVal)
				yrv3:SetCooldownStateDirty("weedshop_illegal_work_cd", true)
			end,
			coords = vec3:new(-1162.051147, -1564.757202, 4.410227)
		},
		["YRV3_HELITOURS_LABEL"] = {
			is_owned = function()
				return stats.get_int("MPX_SB_HELI_TOURS_OWNED") ~= 0
			end,
			get_special_val = function()
				return stats.get_packed_stat_int(24926)
			end,
			set_special_val = function()
				if (stats.get_packed_stat_int(24926) == 0) then
					return
				end

				stats.set_packed_stat_int(24926, 0)
			end,
			max_heat = 100,
			gvar_key_1 = "features.yrv3.helitours_legal_work_cd",
			gvar_key_2 = "features.yrv3.helitours_illegal_work_cd",
			cb1_clicked = false,
			cb2_clicked = false,
			---@param yrv3 YRV3
			on_cb1_click = function(yrv3, newVal)
				table.set_nested_key(GVars, "features.yrv3.helitours_legal_work_cd", newVal)
				yrv3:SetCooldownStateDirty("helitours_legal_work_cd", true)
			end,
			on_cb2_click = function(yrv3, newVal)
				table.set_nested_key(GVars, "features.yrv3.helitours_illegal_work_cd", newVal)
				yrv3:SetCooldownStateDirty("helitours_illegal_work_cd", true)
			end,
			coords = vec3:new(-753.524841, -1511.244751, 5.015130)
		},
	},
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
		{ name = "", coords = vec3:new(-1148.908447, -3406.064697, 13.945053) },
		{ name = "", coords = vec3:new(-1393.322021, -3262.968262, 13.944828) },
		{ name = "", coords = vec3:new(-2022.336304, 3154.936768, 32.810272) },
		{ name = "", coords = vec3:new(-1879.105957, 3106.792969, 32.810234) },
		{ name = "", coords = vec3:new(-2470.278076, 3274.427734, 32.835461) },
	},
	Bunkers = {
		[21] = { name = "", coords = vec3:new(494.680878, 3015.895996, 41.041725) },
		[22] = { name = "", coords = vec3:new(849.619812, 3024.425781, 41.266800) },
		[23] = { name = "", coords = vec3:new(40.422565, 2929.004395, 55.746357) },
		[24] = { name = "", coords = vec3:new(1571.949341, 2224.597168, 78.350952) },
		[25] = { name = "", coords = vec3:new(2107.135254, 3324.630615, 45.371754) },
		[26] = { name = "", coords = vec3:new(2488.706055, 3164.616699, 49.080124) },
		[27] = { name = "", coords = vec3:new(1798.502930, 4704.956543, 39.995476) },
		[28] = { name = "", coords = vec3:new(-754.225769, 5944.171875, 19.836382) },
		[29] = { name = "", coords = vec3:new(-388.333160, 4338.322754, 56.103130) },
		[30] = { name = "", coords = vec3:new(-3030.341797, 3334.570068, 10.105902) },
		[31] = { name = "", coords = vec3:new(-3156.140625, 1376.710693, 17.073570) },
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
}

return RawBusinessData
