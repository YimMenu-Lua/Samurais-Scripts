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


local CARS_BIT <const>  = Enums.eVehicleType.VEHICLE_TYPE_CAR
local BIKES_BIT <const> = Enums.eVehicleType.VEHICLE_TYPE_BIKE

---@type array<HandlingPresetData>
return {
	{
		name                  = "VEH_NO_ENGINE_BRAKE",
		description           = "VEH_NO_ENGINE_BRAKE_TT",
		is_translator_name    = true,
		auto_apply            = true,
		deltas                = { [Enums.eHandlingEditorTypes.TYPE_HF] = { ["FREEWHEEL_NO_GAS"] = true } },
		allowed_vehicle_types = 1 << CARS_BIT | 1 << BIKES_BIT,
	},
	{
		name                  = "VEH_WHEELIE",
		description           = "VEH_WHEELIE_TT",
		is_translator_name    = true,
		auto_apply            = false,
		deltas                = { [Enums.eHandlingEditorTypes.TYPE_AF] = { ["CAN_WHEELIE"] = true } },
		allowed_vehicle_types = 1 << CARS_BIT,
	},
	{
		name                  = "VEH_KERS_BOOST",
		description           = "VEH_KERS_BOOST_TT",
		is_translator_name    = true,
		auto_apply            = false,
		deltas                = { [Enums.eHandlingEditorTypes.TYPE_HF] = { ["HAS_KERS"] = true } },
		allowed_vehicle_types = 1 << CARS_BIT
	},
	{
		name                  = "VEH_ROCKET_BOOST",
		description           = "VEH_ROCKET_BOOST_TT",
		is_translator_name    = true,
		auto_apply            = false,
		deltas                = { [Enums.eHandlingEditorTypes.TYPE_MIF] = { ["HAS_ROCKET_BOOST"] = true } },
		allowed_vehicle_types = 1 << CARS_BIT | 1 << BIKES_BIT
	},
	{
		name                  = "VEH_JUMP",
		description           = "VEH_JUMP_TT",
		is_translator_name    = true,
		auto_apply            = false,
		deltas                = { [Enums.eHandlingEditorTypes.TYPE_MIF] = { ["JUMPING_CAR"] = true, ["HAS_PARACHUTE"] = true, } },
		allowed_vehicle_types = 1 << CARS_BIT
	},
	{
		name                  = "VEH_OFFROAD_ABILITIES",
		description           = "VEH_OFFROAD_ABILITIES_TT",
		is_translator_name    = true,
		auto_apply            = false,
		deltas                = {
			[Enums.eHandlingEditorTypes.TYPE_HF] = {
				["OFFROAD_ABILITIES"]                         = true,
				["OFFROAD_ABILITIES_X2"]                      = true,
				["HAS_RALLY_TYRES"]                           = true,
				["OFFROAD_INCREASED_GRAVITY_NO_FOLIAGE_DRAG"] = true,
				["LESS_SNOW_SINK"]                            = true,
			},
			[Enums.eHandlingEditorTypes.TYPE_AF] = {
				["DIFF_LOCKING_FRONT"]       = true,
				["DIFF_LOCKING_REAR"]        = true,
				["FORCE_SMOOTH_RPM"]         = true,
				["HOLD_GEAR_WITH_WHEELSPIN"] = false,
				["ASSIST_TRACTION_CONTROL"]  = false,
				["ASSIST_STABILITY_CONTROL"] = false,
			},
			[Enums.eHandlingEditorTypes.TYPE_MIF] = { ["INCREASE_LOW_SPEED_TORQUE"] = true, },
		},
		allowed_vehicle_types = 1 << CARS_BIT
	},
	{
		name                  = "VEH_FORCE_NO_TC",
		description           = "VEH_FORCE_NO_TC_TT",
		is_translator_name    = true,
		auto_apply            = false,
		deltas                = {
			[Enums.eHandlingEditorTypes.TYPE_HF] = { ["FORCE_NO_TC_OR_SC"] = true },
			[Enums.eHandlingEditorTypes.TYPE_AF] = {
				["HOLD_GEAR_WITH_WHEELSPIN"] = true,
				["HARD_REV_LIMIT"]           = true,
				["FORCE_SMOOTH_RPM"]         = false,
				["ASSIST_TRACTION_CONTROL"]  = false,
				["ASSIST_STABILITY_CONTROL"] = false,
			},
			[Enums.eHandlingEditorTypes.TYPE_MIF] = {
				["INCREASE_LOW_SPEED_TORQUE"]                  = true,
				["DONT_HOLD_LOW_GEARS_WHEN_ENGINE_UNDER_LOAD"] = false,
			},
		},
		allowed_vehicle_types = 1 << CARS_BIT | 1 << BIKES_BIT
	},
	{
		name                  = "VEH_LOW_SPEED_WHEELIE",
		description           = "VEH_LOW_SPEED_WHEELIE_TT",
		is_translator_name    = true,
		auto_apply            = false,
		deltas                = {
			[Enums.eHandlingEditorTypes.TYPE_HF] = { ["LOW_SPEED_WHEELIES"] = true } },
		allowed_vehicle_types = 1 << BIKES_BIT
	},
	{
		name                  = "VEH_RAMP",
		description           = "VEH_RAMP_TT",
		is_translator_name    = true,
		auto_apply            = false,
		deltas                = {
			[Enums.eHandlingEditorTypes.TYPE_MIF] = {
				["CRUSHES_OTHER_VEHICLES"]                      = true,
				["HAS_INCREASED_RAMMING_FORCE"]                 = true,
				["HAS_INCREASED_RAMMING_FORCE_VS_ALL_VEHICLES"] = true,
				["RAMMING_SCOOP"]                               = true,
				["HAS_RAMMING_SCOOP_MOD"]                       = true,
				["HAS_RAMP"]                                    = true,
				["RAMP_MOD"]                                    = true,
			},
		},
		allowed_vehicle_types = 1 << CARS_BIT
	},
}
