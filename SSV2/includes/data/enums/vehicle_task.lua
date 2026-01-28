-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@enum eVehicleTask
local eVehicleTask <const> = {
	NONE           = -1,
	GOTO           = 0,
	WANDER         = 1,
	PLANE_TAXI     = 2, -- jets only
	TAKE_OFF       = 3, -- aircraft only
	LAND           = 4, -- aircraft only
	HOVER_IN_PLACE = 5, -- helicopters onyl
	GO_HOME        = 6,
	OVERRIDE       = 99,
}

return eVehicleTask
