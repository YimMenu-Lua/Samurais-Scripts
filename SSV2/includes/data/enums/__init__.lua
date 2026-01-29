-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Enums <const> = {
	eGameState             = require("includes.data.enums.game_state"),
	eModelType             = require("includes.data.enums.model_type"),
	eRagdollBlockingFlags  = require("includes.data.enums.ragdoll_blocking_flags"),
	eVehicleClasses        = require("includes.data.enums.vehicle_classes"),
	eHandlingType          = require("includes.data.enums.handling_type"),
	eDrivingFlags          = require("includes.data.enums.driving_flags"),
	eVehicleHandlingFlags  = require("includes.data.enums.handling_flags"),
	eVehicleModelFlags     = require("includes.data.enums.vehicle_model_flags"),
	eVehicleModelInfoFlags = require("includes.data.enums.vehicle_model_info_flags"),
	eVehicleAdvancedFlags  = require("includes.data.enums.vehicle_advanced_flags"),
	ePedType               = require("includes.data.enums.ped_type"),
	ePedGender             = require("includes.data.enums.ped_gender"),
	ePedComponents         = require("includes.data.enums.ped_components"),
	ePedConfigFlags        = require("includes.data.enums.ped_config_flags"),
	ePedResetFlags         = require("includes.data.enums.ped_reset_flags"),
	ePedCombatAttributes   = require("includes.data.enums.ped_combat_attributes"),
	ePedTaskIndex          = require("includes.data.enums.ped_task_index"),
	eAnimFlags             = require("includes.data.enums.anim_flags"),
	eActionType            = require("includes.data.enums.action_type"),
	eVehicleTask           = require("includes.data.enums.vehicle_task"),
	eLandingGearState      = require("includes.data.enums.landing_gear_state"),
}

return Enums
