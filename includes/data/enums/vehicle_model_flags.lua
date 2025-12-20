-- `CVehicle::ModelFlags`
---@enum eVehicleModelFlags
-- https://gtamods.com/wiki/Handling.meta
local eVehicleModelFlags <const> = {
	IS_VAN                    = 0, -- Allows the vehicle to use door_dside_r and door_pside_r bones as double rear doors.
	IS_BUS                    = 1, -- Makes the AI take wider turns when driving around corners.
	IS_LOW                    = 2,
	IS_BIG                    = 3,
	ABS_STD                   = 4, -- abs standard
	ABS_OPTION                = 5, -- abs when upgraded
	ABS_ALT_STD               = 6, -- alternate abs standard
	ABS_ALT_OPTION            = 7, -- alternate abs when upgraded
	NO_DOORS                  = 8, -- Used for vehicles that have no door bones (ex: Bifta)
	TANDEM_SEATING            = 9,
	SIT_IN_BOAT               = 10, -- Uses seated animations when controlling a boat.
	HAS_TRACKS                = 11, -- Changes the tire mark texture to tank tracks and permanently applies it to the road, and makes misc_a, misc_b, misc_c, and misc_d bones act as wheels.
	NO_EXHAUST                = 12, -- The vehicle won't render exhaust particle effects.
	DOUBLE_EXHAUST            = 13, -- Creates a mirrored copy of the exhaust particle effect on the car. Technically redundant, as the game supports up to 32 individual exhaust bones.
	NO_1STPERSON_LOOKBEHIND   = 14, -- Does not allow the player to use the "look behind" button while in first person view - it will instead enter third person mode and then look behind.
	CAN_ENTER_IF_NO_DOOR      = 15, -- Allows entry into the vehicle even if the vehicle has no accessible door.
	AXLE_F_TORSION            = 16,
	AXLE_F_SOLID              = 17,
	AXLE_F_MCPHERSON          = 18,
	ATTACH_PED_TO_BODYSHELL   = 19,
	AXLE_R_TORSION            = 20,
	AXLE_R_SOLID              = 21,
	AXLE_R_MCPHERSON          = 22,
	DONT_FORCE_GRND_CLEARANCE = 23,
	DONT_RENDER_STEER         = 24, -- Will not turn the vehicle's wheels when steering - visual effect only.
	NO_WHEEL_BURST            = 25, -- Prevents the wheels from being burst in any way - essentially a default "Bulletproof Tires" option.
	INDESTRUCTIBLE            = 26, -- Makes the vehicle indestructible.
	DOUBLE_FRONT_WHEELS       = 27,
	IS_RC                     = 28, -- Hides the player model when they enter the vehicle.
	DOUBLE_REAR_WHEELS        = 29,
	NO_WHEEL_BREAK            = 30, -- Prevents the vehicle's wheels from getting detached on damage
	EXTRA_CAMBER              = 31,
}

return eVehicleModelFlags
