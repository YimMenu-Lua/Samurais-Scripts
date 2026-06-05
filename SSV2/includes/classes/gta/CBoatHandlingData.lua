-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CBaseSubHandlingData = require("includes.classes.gta.CBaseSubHandlingData")


--------------------------------------
-- Class: CBoatHandlingData
--------------------------------------
---@class CBoatHandlingData : CBaseSubHandlingData
---@overload fun(ptr: pointer): CBoatHandlingData
local CBoatHandlingData = Class("CBoatHandlingData", { parent = CBaseSubHandlingData, pointer_ctor = true })

---@param ptr pointer
function CBoatHandlingData.new(ptr)
	---@diagnostic disable-next-line: param-type-mismatch
	return setmetatable({ m_ptr = ptr }, CBoatHandlingData)
end

return CBoatHandlingData
