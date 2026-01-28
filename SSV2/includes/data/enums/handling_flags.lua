-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@enum eVehicleHandlingFlags
-- https://forge.plebmasters.de/vehicleflags?category=DrivingStyleFlags
local eVehicleHandlingFlags <const> = {
	SMOOTHED_COMPRESSION                      = 0, -- Makes the suspension compression smoother.
	REDUCED_MOD_MASS                          = 1, -- Reduces the mass that is added with modification parts.
	HAS_KERS                                  = 2, -- Partially enables KERS on the vehicle; disables horn and shows the recharge bar below the minimap. KERS boost itself still needs to be enabled by the SET_VEHICLE_KERS_ALLOWED native.
	HAS_RALLY_TYRES                           = 3, -- Inverts the way grip works on the vehicle (less grip on asphalt, more on dirt roads).
	NO_HANDBRAKE                              = 4, -- Disables handbrake control.
	STEER_REARWHEELS                          = 5, -- Rear wheels will steer instead of the front. Changes do take effect immediately but you have to respawn the vehicle in order to actually see the rear wheels turn.
	HANDBRAKE_REARWHEELSTEER                  = 6, -- Allows to use the handbrake to steer the vehicle with rear wheels, in addition to the front wheels. // Same visual behavior as above.
	STEER_ALL_WHEELS                          = 7, -- Front and rear wheels will steer. // Same visual behavior as above.
	FREEWHEEL_NO_GAS                          = 8, -- Disables auto-braking when coasting. **I HATE THE FACT THAT THIS IS SET BY DEFAULT.**
	NO_REVERSE                                = 9, -- Disables reverse control.
	REDUCED_RIGHTING_FORCE                    = 10, -- Reduces the speed at which the vehicle rotates back onto its wheels.
	STEER_NO_WHEELS                           = 11, -- Stops the wheels from turning. Visual only. Used for vehicles with tracks instead of wheels.
	CVT                                       = 12, -- Enables electric vehicle physics (leg shavers)
	ALT_EXT_WHEEL_BOUNDS_BEH                  = 13,
	DONT_RAISE_BOUNDS_AT_SPEED                = 14,
	EXT_WHEEL_BOUNDS_COL                      = 15,
	LESS_SNOW_SINK                            = 16, -- The vehicle will sink less when driving over snow.
	TYRES_CAN_CLIP                            = 17, -- Allows the tires to clip into the ground based on the tire sidewall, letting the vehicle handle bumps much easier.
	REDUCED_DRIVE_OVER_DAMAGE                 = 18, -- Reduces the damage the vehicle takes when colliding with pedestrians.
	ALT_EXT_WHEEL_BOUNDS_SHRINK               = 19,
	OFFROAD_ABILITIES                         = 20, -- Sets the vehicle's gravity multiplier to 1.1.
	OFFROAD_ABILITIES_X2                      = 21, -- Sets the vehicle's gravity multiplier to 1.2, makes it immune to large foliage collisions, and the vehicle will continually attempt to self-level while in mid-air.
	TYRES_RAISE_SIDE_IMPACT_THRESHOLD         = 22,
	OFFROAD_INCREASED_GRAVITY_NO_FOLIAGE_DRAG = 23, -- Same effects as HF_OFFROAD_ABILITIES_X2, except that the vehicle will not attempt to self-level while in mid-air.
	ENABLE_LEAN                               = 24, -- Prevents rolling in mid air. Used for ATVs.
	FORCE_NO_TC_OR_SC                         = 25, -- Disables traction control for motorcycles. **I ALSO HATE THE FACT THAT THIS IS SET BY DEFAULT.**
	HEAVYARMOUR                               = 26,
	ARMOURED                                  = 27, -- Prevents vehicle doors from breaking open in collisions.
	SELF_RIGHTING_IN_WATER                    = 28,
	IMPROVED_RIGHTING_FORCE                   = 29, -- Adds extra force when trying to flip the vehicle back on its wheels.
	LOW_SPEED_WHEELIES                        = 30, -- Allows bikes to do wheelies at lower speeds
}

return eVehicleHandlingFlags
