---@enum eGameState
local eGameState <const> = {
	Invalid       = -1,
	Playing       = 0,
	Died          = 1,
	Arrested      = 2,
	FailedMission = 3,
	LeftGame      = 4,
	Respawn       = 5,
	InMPCutscene  = 6,
}

return eGameState
