-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@enum eLandingGearState
local eLandingGearState <const> = {
	DEPLOYED   = 0,
	RETRACTING = 1,
	UNK        = 2,
	DEPLOYING  = 3,
	RETRACTED  = 4
}

return eLandingGearState
