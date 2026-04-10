-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView = require("includes.classes.gta.CStructView")
local CBaseSubHandlingData = require("includes.classes.gta.CBaseSubHandlingData")


--------------------------------------
-- Class: CBoatHandlingData
--------------------------------------
---@class CBoatHandlingData : CBaseSubHandlingData
---@overload fun(ptr: pointer): CBoatHandlingData
local CBoatHandlingData = Class("CBoatHandlingData", { parent = CBaseSubHandlingData, pointer_ctor = true })

return CBoatHandlingData
