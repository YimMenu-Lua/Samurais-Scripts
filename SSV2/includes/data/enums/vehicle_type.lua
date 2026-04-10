-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@enum eVehicleType
local eVehicleType <const> = {
	VEHICLE_TYPE_NONE                  = 4294967295,
	VEHICLE_TYPE_CAR                   = 0,
	VEHICLE_TYPE_PLANE                 = 1,
	VEHICLE_TYPE_TRAILER               = 2,
	VEHICLE_TYPE_QUADBIKE              = 3,
	VEHICLE_TYPE_DRAFT                 = 4,
	VEHICLE_TYPE_SUBMARINECAR          = 5,
	VEHICLE_TYPE_AMPHIBIOUS_AUTOMOBILE = 6,
	VEHICLE_TYPE_AMPHIBIOUS_QUADBIKE   = 7,
	VEHICLE_TYPE_HELI                  = 8,
	VEHICLE_TYPE_BLIMP                 = 9,
	VEHICLE_TYPE_AUTOGYRO              = 10,
	VEHICLE_TYPE_BIKE                  = 11,
	VEHICLE_TYPE_BICYCLE               = 12,
	VEHICLE_TYPE_BOAT                  = 13,
	VEHICLE_TYPE_TRAIN                 = 14,
	VEHICLE_TYPE_SUBMARINE             = 15,
}

return eVehicleType
