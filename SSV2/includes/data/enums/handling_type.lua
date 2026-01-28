-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@enum eHandlingType
local eHandlingType <const> = {
	INVALID         = -1,
	BIKE            = 0,
	FLYING          = 1,
	VERTICAL_FLYING = 2,
	BOAT            = 3,
	SEAPLANE        = 4,
	SUBMARINE       = 5,
	TRAIN           = 6,
	TRAILER         = 7,
	CAR             = 8,
	WEAPON          = 9,
	SPECIAL_FLIGHT  = 10,
}

return eHandlingType
