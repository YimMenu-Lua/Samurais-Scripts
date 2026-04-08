-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView = require("includes.classes.gta.CStructView")


--------------------------------------
-- Class: CBaseSubHandlingData
--------------------------------------
---@generic T
---@class CBaseSubHandlingData : CStructBase<CBaseSubHandlingData>
---@field protected m_ptr pointer
---@field private m_handling_type pointer<int32_t> -- 0x00C8
---@field public GetHandlingType fun(self: CBaseSubHandlingData): eHandlingType
---@overload fun(ptr: pointer): CBaseSubHandlingData
local CBaseSubHandlingData = CStructView("CBaseSubHandlingData", 0x00CC)

---@param ptr pointer
---@return CBaseSubHandlingData
function CBaseSubHandlingData.new(ptr)
	return setmetatable({
		m_ptr           = ptr,
		m_handling_type = ptr:add(0x00C8)
		---@diagnostic disable-next-line: param-type-mismatch
	}, CBaseSubHandlingData)
end

---@return eHandlingType
function CBaseSubHandlingData:GetHandlingType()
	return self:__safecall(Enums.eHandlingType.INVALID, function()
		return self.m_handling_type:get_int()
	end)
end

return CBaseSubHandlingData
