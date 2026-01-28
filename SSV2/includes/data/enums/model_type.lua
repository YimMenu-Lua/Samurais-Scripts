-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@enum eModelType
local eModelType <const> = {
	Invalid      = 0,
	Object       = 1,
	MLO          = 2,
	Time         = 3,
	Weapon       = 4,
	Vehicle      = 5,
	Ped          = 6,
	Destructible = 7
}

return eModelType
