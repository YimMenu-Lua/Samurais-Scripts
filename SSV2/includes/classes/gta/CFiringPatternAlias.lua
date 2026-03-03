-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView = require("includes.classes.gta.CStructView")

---@class CFiringPatternAlias
---@field protected m_ptr pointer
---@field m_firing_pattern_hash pointer<joaat_t> // 0x0
---@field m_alias_hash pointer<joaat_t> // 0x4
---@overload fun(ptr: pointer): CFiringPatternAlias
local CFiringPatternAlias = CStructView("CFiringPatternAlias", {
	{ "m_firing_pattern_hash", 0x0 },
	{ "m_alias_hash",          0x4 },
})

return CFiringPatternAlias
