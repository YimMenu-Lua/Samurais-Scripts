---@class fwDrawData
---@field private m_ptr pointer
---@field m_stream_render_gfx pointer
---@overload fun(ptr: pointer): fwDrawData
local fwDrawData = Class("fwDrawData")

---@param ptr pointer
---@return fwDrawData
function fwDrawData:init(ptr)
	return setmetatable({
		m_ptr = ptr,
		m_stream_render_gfx = ptr:add(0x370)
		---@diagnostic disable-next-line
	}, fwDrawData)
end

return fwDrawData
