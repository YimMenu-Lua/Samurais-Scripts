-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@enum eWheelDynamicFlags
local eWheelDynamicFlags <const> = {
	HIT                        = 0,
	HIT_LAST                   = 1,
	ON_GAS                     = 2,
	ON_FIRE                    = 3,
	CHEAT_TC                   = 4,
	CHEAT_SC                   = 5,
	CHEAT_GRIP_1               = 6,
	CHEAT_GRIP_2               = 7,
	BURNOUT                    = 8,
	BURNOUT_NON_DRIVEN_WHEEL   = 9,
	IN_SHALLOW_WATER           = 10,
	IN_DEEP_WATER              = 11,
	TYRES_HEAT_UP              = 12,
	ABS_ACTIVE                 = 13,
	ABS_UNK                    = 14,
	ABS_ALT                    = 15,
	CRUSHING_PED               = 16,
	REDUCE_GRIP                = 17,
	TELEPORTED                 = 18,
	RESET                      = 19,
	BROKEN_OFF                 = 20,
	FULL_THROTTLE              = 21,
	SIDE_IMPACT                = 22,
	DUMMY_TRANSITION           = 23,
	DUMMY_TRANSITION_LAST      = 24,
	NO_LATERAL_SPRING          = 25,
	WITHIN_DAMAGE_REGION       = 26,
	WITHIN_HEAVY_DAMAGE_REGION = 27,
	ON_PAVEMENT                = 28,
	UNK_29                     = 29,
	FORCE_NO_SLEEP             = 30,
	SLEEPING_ON_DEBRIS         = 31
}

return eWheelDynamicFlags
