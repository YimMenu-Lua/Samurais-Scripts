-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


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
