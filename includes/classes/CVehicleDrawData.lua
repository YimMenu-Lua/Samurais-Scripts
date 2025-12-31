local fwDrawData = require("includes.classes.fwDrawData")

---@class CVehicleDrawData : fwDrawData
---@field m_stream_render_gfx pointer
---@field m_stream_wheel_size pointer<float>
---@field m_stream_wheel_width pointer<float>
local CVehicleDrawData = Class("CVehicleDrawData", fwDrawData)

function CVehicleDrawData:init(ptr)
	self.m_ptr = ptr
	self.m_stream_render_gfx = ptr:add(0x370)
	self.m_stream_wheel_size = self.m_stream_render_gfx:add(0x008)
	self.m_stream_wheel_width = self.m_stream_render_gfx:add(0xBA0)
	return self
end

return CVehicleDrawData
