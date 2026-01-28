-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class CBaseSubHandlingData
---@field protected m_ptr pointer
---@field protected m_handling_type pointer<int32_t> -- 0x00C8
local CBaseSubHandlingData = {}
CBaseSubHandlingData.__index = CBaseSubHandlingData

---@param ptr pointer
---@return CBaseSubHandlingData?
function CBaseSubHandlingData.new(ptr)
	if not ptr or ptr:is_null() then
		return
	end

	local instance = setmetatable({}, CBaseSubHandlingData)
	instance.m_ptr = ptr
	instance.m_handling_type = ptr:add(0x00C8)

	return instance
end

---@return eHandlingType
function CBaseSubHandlingData:GetHandlingType()
	return self.m_handling_type:get_int()
end

return CBaseSubHandlingData
