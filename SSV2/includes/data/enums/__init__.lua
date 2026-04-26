-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- ### Enums Namespace.
--
-- All enums are stored here to avoid polluting the global namespace.
local Enums <const> = {
	eActionType            = require("action_type"),
	eAnimFlags             = require("anim_flags"),
	eDrivingFlags          = require("driving_flags"),
	eGameState             = require("game_state"),
	eGameLanguage          = require("game_language"),
	eHandlingType          = require("handling_type"),
	eLandingGearState      = require("landing_gear_state"),
	eModelType             = require("model_type"),
	ePedCombatAttributes   = require("ped_combat_attributes"),
	ePedComponents         = require("ped_components"),
	ePedConfigFlags        = require("ped_config_flags"),
	ePedGender             = require("ped_gender"),
	ePedResetFlags         = require("ped_reset_flags"),
	ePedTaskIndex          = require("ped_task_index"),
	ePedType               = require("ped_type"),
	eRagdollBlockingFlags  = require("ragdoll_blocking_flags"),
	eVehicleAdvancedFlags  = require("vehicle_advanced_flags"),
	eVehicleClass          = require("vehicle_classes"),
	eVehicleHandlingFlags  = require("vehicle_handling_flags"),
	eVehicleModelFlags     = require("vehicle_model_flags"),
	eVehicleModelInfoFlags = require("vehicle_model_info_flags"),
	eVehicleTask           = require("vehicle_task"),
	eVehicleType           = require("vehicle_type"),
	eWheelConfigFlags      = require("cwheel_config_flags"),
	eWheelDynamicFlags     = require("cwheel_dynamic_flags"),
}

return Enums
