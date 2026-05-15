-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local SGSL = require("includes.services.SGSL")


-- No this is not a typo. Double G's my G!
--
-- Script globals stored and exposed globally. Can be used for caching as well *(though SGSL already does that)*
---@class GGlobals
---@field GPBD_FM_3 ScriptGlobal
---@field MP_BUSINESS_STUFF ScriptGlobal
---@field FREEMODE_GLOBAL ScriptGlobal
local GGlobals                = {}
GGlobals.__index              = GGlobals

-- Register globals here. Functions will be executed when GGlobals:init is called.
---@type array<function>
local GlobalsRegistry <const> = {
	function()
		GGlobals.GPBD_FM_3 = SGSL:Get(SGSL.data.gpbd_fm_3):AsGlobal()
	end,
	function()
		GGlobals.MP_BUSINESS_STUFF = SGSL:Get(SGSL.data.mp_business_stuff):AsGlobal()
	end,
	function()
		GGlobals.FREEMODE_GLOBAL = SGSL:Get(SGSL.data.freemode_boss_stuff):AsGlobal()
	end,
}

function GGlobals:Init()
	for _, func in ipairs(GlobalsRegistry) do
		pcall(func)
	end
end

return GGlobals
