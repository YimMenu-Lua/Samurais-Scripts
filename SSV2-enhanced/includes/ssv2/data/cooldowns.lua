-- Original Samurai cooldown definitions, expressed as V2 data. GPL-3.0-or-later.
return {
	["mc_work_cd"] = {
		path = 'features.yrv3.mc_work_cd',
		defs = { { t = "BIKER_CLUB_WORK_COOLDOWN_GLOBAL", v = 0, kind = 'tunable', type = 'int' } },
	},
	["hangar_cd"] = {
		path = 'features.yrv3.hangar_cd',
		defs = {
			{ t = "SMUG_STEAL_EASY_COOLDOWN_TIMER", v = 0, kind = 'tunable', type = 'int' },
			{ t = "SMUG_STEAL_MED_COOLDOWN_TIMER",  v = 0, kind = 'tunable', type = 'int' },
			{ t = "SMUG_STEAL_HARD_COOLDOWN_TIMER", v = 0, kind = 'tunable', type = 'int' },
		},
	},
	["nc_management_cd"] = {
		path = 'features.yrv3.nc_management_cd',
		defs = { { t = "BB_CLUB_MANAGEMENT_CLUB_MANAGEMENT_MISSION_COOLDOWN", v = 0, kind = 'tunable', type = 'int' } },
	},
	["nc_vip_mission_chance"] = {
		path = 'features.yrv3.nc_vip_mission_chance',
		defs = { { t = "NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT", v = 0, kind = 'tunable', type = 'int' } },
	},
	["security_missions_cd"] = {
		path = 'features.yrv3.security_missions_cd',
		defs = { { t = "FIXER_SECURITY_CONTRACT_COOLDOWN_TIME", v = 0, kind = 'tunable', type = 'int' } },
	},
	["ie_vehicle_steal_cd"] = {
		path = 'features.yrv3.ie_vehicle_steal_cd',
		defs = { { t = "IMPEXP_STEAL_COOLDOWN", v = 0, kind = 'tunable', type = 'int' } },
	},
	["ie_vehicle_sell_cd"] = {
		path = 'features.yrv3.ie_vehicle_sell_cd',
		defs = {
			{ t = "IMPEXP_SELL_COOLDOWN",       v = 0, kind = 'tunable', type = 'int' },
			{ t = "IMPEXP_SELL_1_CAR_COOLDOWN", v = 0, kind = 'tunable', type = 'int' },
			{ t = "IMPEXP_SELL_2_CAR_COOLDOWN", v = 0, kind = 'tunable', type = 'int' },
			{ t = "IMPEXP_SELL_3_CAR_COOLDOWN", v = 0, kind = 'tunable', type = 'int' },
			{ t = "IMPEXP_SELL_4_CAR_COOLDOWN", v = 0, kind = 'tunable', type = 'int' },
		},
	},
	["ceo_crate_buy_cd"] = {
		path = 'features.yrv3.ceo_crate_buy_cd',
		defs = {
			{ t = "EXEC_BUY_COOLDOWN",      v = 0, kind = 'tunable', type = 'int' },
			{ t = "EXEC_BUY_FAIL_COOLDOWN", v = 0, kind = 'tunable', type = 'int' },
		},
	},
	["ceo_crate_sell_cd"] = {
		path = 'features.yrv3.ceo_crate_sell_cd',
		defs = {
			{ t = "EXEC_SELL_COOLDOWN",      v = 0, kind = 'tunable', type = 'int' },
			{ t = "EXEC_SELL_FAIL_COOLDOWN", v = 0, kind = 'tunable', type = 'int' },
		},
	},
	["dax_work_cd"] = {
		path = 'features.yrv3.dax_work_cd',
		defs = { { t = "MPX_XM22JUGGALOWORKCDTIMER", v = 0, kind = 'stat', type = 'int' } },
	},
	["garment_rob_cd"] = {
		path = 'features.yrv3.garment_rob_cd',
		defs = { { t = "MPX_HACKER24_ROBBERY_CD", v = 0, kind = 'stat', type = 'int' } },
	},
	["cwash_legal_work_cd"] = {
		path = 'features.yrv3.cwash_legal_work_cd',
		defs = { { t = "MPX_T25_CW_LEG_CD", v = 0, kind = 'stat', type = 'int' } },
	},
	["cwash_illegal_work_cd"] = {
		path = 'features.yrv3.cwash_illegal_work_cd',
		defs = { { t = "MPX_T25_CW_ILEG_CD", v = 0, kind = 'stat', type = 'int' } },
	},
	["weedshop_legal_work_cd"] = {
		path = 'features.yrv3.weedshop_legal_work_cd',
		defs = { { t = "MPX_T25_WS_LEG_CD", v = 0, kind = 'stat', type = 'int' } },
	},
	["weedshop_illegal_work_cd"] = {
		path = 'features.yrv3.weedshop_illegal_work_cd',
		defs = { { t = "MPX_T25_WS_ILEG_CD", v = 0, kind = 'stat', type = 'int' } },
	},
	["helitours_legal_work_cd"] = {
		path = 'features.yrv3.helitours_legal_work_cd',
		defs = { { t = "MPX_T25_WS_LEG_CD", v = 0, kind = 'stat', type = 'int' } },
	},
	["helitours_illegal_work_cd"] = {
		path = 'features.yrv3.helitours_illegal_work_cd',
		defs = { { t = "MPX_T25_HT_ILEG_CD", v = 0, kind = 'stat', type = 'int' } },
	},
	["sy_disable_rob_cd"] = {
		path = 'features.yrv3.sy_disable_rob_cd',
		defs = { { t = "MPX_SALV23_VEHROB_CD", v = 0, kind = 'stat', type = 'int' } },
	},
	["sy_disable_tow_cd"] = {
		path = 'features.yrv3.sy_disable_tow_cd',
		defs = { { t = 1521767918, v = 0, kind = 'tunable', type = 'int' } },
	},
	["cfr_cd"] = {
		path = 'features.yim_heists.cfr_cd',
		defs = { { t = "MPX_SALV23_CFR_COOLDOWN", v = 0, kind = 'stat', type = 'int' } },
	},
	["knoway_cd"] = {
		path = 'features.yim_heists.knoway_cd',
		defs = { { t = "MPX_M25_AVI_MISSION_CD", v = 0, kind = 'stat', type = 'int' } },
	},
	["dre_cd"] = {
		path = 'features.yim_heists.dre_cd',
		defs = { { t = "MPX_FIXER_STORY_COOLDOWN", v = 0, kind = 'stat', type = 'int' } },
	},
	["ogfa_cd"] = {
		path = 'features.yim_heists.ogfa_cd',
		defs = { { t = "MPX_HACKER24_MFM_COOLDOWN", v = 0, kind = 'stat', type = 'int' } },
	},
}
