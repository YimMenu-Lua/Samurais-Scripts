-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- [[Summary]]
--
-- A combination of handling data presets that form a vehicle feature. Extensible with user-generated presets.
-- The decision to use flag names instead of numbers is mainly because the 3rd-party JSON module we're using
-- shits itself when it sees a sparse array. On the down side, the editor will suffer a small performance hit.
-- On the up side, the raw data will be much more readavle.


local ALLOW_CARS  = 1
local ALLOW_BIKES = 2048
local ALLOW_BOTH  = bit.bor(ALLOW_CARS, ALLOW_BIKES)

---@type array<VehicleFlagPresetData>
return {
	{
		name               = "VEH_NO_ENGINE_BRAKE",
		description        = "VEH_NO_ENGINE_BRAKE_TT",
		is_translator_name = true,
		auto_apply         = true,
		deltas             = { [1] = { ["FREEWHEEL_NO_GAS"] = true } },
		vehicle_bitset     = ALLOW_BOTH,
	},
	{
		name               = "VEH_WHEELIE",
		description        = "VEH_WHEELIE_TT",
		is_translator_name = true,
		auto_apply         = false,
		deltas             = { [0] = { ["CAN_WHEELIE"] = true } },
		vehicle_bitset     = ALLOW_CARS,
	},
	{
		name               = "VEH_KERS_BOOST",
		description        = "VEH_KERS_BOOST_TT",
		is_translator_name = true,
		auto_apply         = false,
		deltas             = { [1] = { ["HAS_KERS"] = true } },
		vehicle_bitset     = ALLOW_CARS
	},
	{
		name               = "VEH_ROCKET_BOOST",
		description        = "VEH_ROCKET_BOOST_TT",
		is_translator_name = true,
		auto_apply         = false,
		deltas             = { [3] = { ["HAS_ROCKET_BOOST"] = true } },
		vehicle_bitset     = ALLOW_BOTH
	},
	{
		name               = "VEH_JUMP",
		description        = "VEH_JUMP_TT",
		is_translator_name = true,
		auto_apply         = false,
		deltas             = { [3] = { ["JUMPING_CAR"] = true, ["HAS_PARACHUTE"] = true, } },
		vehicle_bitset     = ALLOW_CARS
	},
	{
		name               = "VEH_OFFROAD_ABILITIES",
		description        = "VEH_OFFROAD_ABILITIES_TT",
		is_translator_name = true,
		auto_apply         = false,
		deltas             = {
			[1] = {
				["SMOOTHED_COMPRESSION"]                      = true,
				["OFFROAD_ABILITIES"]                         = true,
				["OFFROAD_ABILITIES_X2"]                      = true,
				["HAS_RALLY_TYRES"]                           = true,
				["OFFROAD_INCREASED_GRAVITY_NO_FOLIAGE_DRAG"] = true,
				["LESS_SNOW_SINK"]                            = true,
			},
			[0] = {
				["DIFF_LOCKING_FRONT"]        = true,
				["DIFF_LOCKING_REAR"]         = true,
				["FORCE_SMOOTH_RPM"]          = true,
				["HOLD_GEAR_WITH_WHEELSPIN"]  = false,
				["DISABLE_TRACTION_CONTROL"]  = false,
				["DISABLE_STABILITY_CONTROL"] = false,
			},
			[3] = { ["INCREASE_LOW_SPEED_TORQUE"] = true, },
		},
		vehicle_bitset     = ALLOW_CARS
	},
	{
		name               = "VEH_FORCE_NO_TC",
		description        = "VEH_FORCE_NO_TC_TT",
		is_translator_name = true,
		auto_apply         = false,
		deltas             = {
			[1] = { ["FORCE_NO_TC_OR_SC"] = true },
			[0] = {
				["HOLD_GEAR_WITH_WHEELSPIN"]  = true,
				["HARD_REV_LIMIT"]            = true,
				["FORCE_SMOOTH_RPM"]          = false,
				["DISABLE_TRACTION_CONTROL"]  = true,
				["DISABLE_STABILITY_CONTROL"] = true,
			},
			[3] = {
				["INCREASE_LOW_SPEED_TORQUE"]                  = true,
				["DONT_HOLD_LOW_GEARS_WHEN_ENGINE_UNDER_LOAD"] = false,
			},
		},
		vehicle_bitset     = ALLOW_BOTH
	},
	{
		name               = "VEH_LOW_SPEED_WHEELIE",
		description        = "VEH_LOW_SPEED_WHEELIE_TT",
		is_translator_name = true,
		auto_apply         = false,
		deltas             = {
			[1] = { ["LOW_SPEED_WHEELIES"] = true } },
		vehicle_bitset     = ALLOW_BIKES
	},
	{
		name               = "VEH_RAMP",
		description        = "VEH_RAMP_TT",
		is_translator_name = true,
		auto_apply         = false,
		deltas             = {
			[3] = {
				["CRUSHES_OTHER_VEHICLES"]                      = true,
				["HAS_INCREASED_RAMMING_FORCE"]                 = true,
				["HAS_INCREASED_RAMMING_FORCE_VS_ALL_VEHICLES"] = true,
				["RAMMING_SCOOP"]                               = true,
				["HAS_RAMMING_SCOOP_MOD"]                       = true,
				["HAS_RAMP"]                                    = true,
				["RAMP_MOD"]                                    = true,
			},
		},
		vehicle_bitset     = ALLOW_CARS
	},
}
