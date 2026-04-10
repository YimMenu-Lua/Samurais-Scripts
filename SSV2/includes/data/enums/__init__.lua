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
	eActionType            = require("includes.data.enums.action_type"),
	eAnimFlags             = require("includes.data.enums.anim_flags"),
	eDrivingFlags          = require("includes.data.enums.driving_flags"),
	eGameState             = require("includes.data.enums.game_state"),
	eGameLanguage          = require("includes.data.enums.game_language"),
	eHandlingType          = require("includes.data.enums.handling_type"),
	eLandingGearState      = require("includes.data.enums.landing_gear_state"),
	eModelType             = require("includes.data.enums.model_type"),
	ePedCombatAttributes   = require("includes.data.enums.ped_combat_attributes"),
	ePedComponents         = require("includes.data.enums.ped_components"),
	ePedConfigFlags        = require("includes.data.enums.ped_config_flags"),
	ePedGender             = require("includes.data.enums.ped_gender"),
	ePedResetFlags         = require("includes.data.enums.ped_reset_flags"),
	ePedTaskIndex          = require("includes.data.enums.ped_task_index"),
	ePedType               = require("includes.data.enums.ped_type"),
	eRagdollBlockingFlags  = require("includes.data.enums.ragdoll_blocking_flags"),
	eVehicleAdvancedFlags  = require("includes.data.enums.vehicle_advanced_flags"),
	eVehicleClass          = require("includes.data.enums.vehicle_classes"),
	eVehicleHandlingFlags  = require("includes.data.enums.vehicle_handling_flags"),
	eVehicleModelFlags     = require("includes.data.enums.vehicle_model_flags"),
	eVehicleModelInfoFlags = require("includes.data.enums.vehicle_model_info_flags"),
	eVehicleTask           = require("includes.data.enums.vehicle_task"),
	eVehicleType           = require("includes.data.enums.vehicle_type"),
	eWheelConfigFlags      = require("includes.data.enums.wheel_config_flags"),
	eWheelDynamicFlags     = require("includes.data.enums.wheel_dynamic_flags"),
}

return Enums
