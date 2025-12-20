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
