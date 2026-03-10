-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView = require("includes.classes.gta.CStructView")


--------------------------------------
-- Class: CBoatHandlingData
--------------------------------------
---@class CBoatHandlingData : CStructBase<CBoatHandlingData>
---@overload fun(ptr: pointer): CBoatHandlingData
local CBoatHandlingData = CStructView("CBoatHandlingData")

return CBoatHandlingData
