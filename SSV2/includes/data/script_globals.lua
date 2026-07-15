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
-- Script globals stored and exposed globally. Can be used for caching as well *(though [SGSL](lua://SGSL) already does that)*
---@class GGlobals
---@field public GPBD ScriptGlobal
---@field public GPBD_FM_3 ScriptGlobal
---@field public MP_BUSINESS_STUFF ScriptGlobal
---@field public FM_SERVICES ScriptGlobal
local GGlobals   = {}
GGlobals.__index = GGlobals

-- Register globals here. Functions will be executed when GGlobals:init is called.
---@type array<function>
local func_array = {
	function()
		GGlobals.GPBD_FM_3 = SGSL:Get(SGSL.data.gpbd_fm_3):AsGlobal()
	end,
	function()
		GGlobals.MP_BUSINESS_STUFF = SGSL:Get(SGSL.data.mp_business_stuff):AsGlobal()
	end,
	function()
		GGlobals.FM_SERVICES = SGSL:Get(SGSL.data.request_services_global):AsGlobal()
	end,
}

function GGlobals:Init()
	for _, func in ipairs(func_array) do
		pcall(func)
	end
end

return GGlobals
