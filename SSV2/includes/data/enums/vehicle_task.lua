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
