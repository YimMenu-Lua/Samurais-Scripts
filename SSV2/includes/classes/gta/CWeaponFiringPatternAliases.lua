-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView = require("includes.classes.gta.CStructView")
local atArray     = require("includes.classes.gta.atArray")


--------------------------------------
-- Class: CWeaponFiringPatternAliases
--------------------------------------
---@class CWeaponFiringPatternAliases : CStructBase<CWeaponFiringPatternAliases>
---@field protected m_ptr pointer
---@field m_name_hash pointer<joaat_t> // 0x0
---@field m_aliases atArray<CFiringPatternAlias> // 0x8
---@overload fun(ptr: pointer): CWeaponFiringPatternAliases
local CWeaponFiringPatternAliases = CStructView("CWeaponFiringPatternAliases", {
	{ "m_name_hash", 0x0 },
	{ "m_aliases",   0x8, atArray },
}, 0x10)

return CWeaponFiringPatternAliases
