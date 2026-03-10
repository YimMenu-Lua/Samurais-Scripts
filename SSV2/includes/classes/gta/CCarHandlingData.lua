-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local atArray     = require("includes.classes.gta.atArray")
local CStructView = require("includes.classes.gta.CStructView")


--------------------------------------
-- Class: CCarHandlingData
--------------------------------------
---@class CCarHandlingData : CStructBase<CCarHandlingData>
---@field protected m_ptr pointer
---@field private m_size uint16_t
---@field public m_back_end_popup_car_impulse_mult pointer<float> -- 0x0008
---@field public m_back_end_popup_building_impulse_mult pointer<float> -- 0x000C
---@field public m_back_end_popup_max_delta_speed pointer<float> -- 0x0010
---@field public m_toe_front pointer<float> -- 0x0014
---@field public m_toe_rear pointer<float> -- 0x0018
---@field public m_camber_front pointer<float>  -- 0x001C
---@field public m_camber_rear pointer<float> -- 0x0020
---@field public m_castor pointer<float> -- 0x0024
---@field public m_engine_resistance pointer<float> -- 0x0028
---@field public m_max_drive_bias_transfer pointer<float> -- 0x002C
---@field public m_jumpforce_scale pointer<float> -- 0x0030
---@field public m_advanced_flags pointer<uint32_t> -- 0x003C
---@field public m_advanced_data atArray<CAdvancedData>   -- 0x0040
---@overload fun(ptr: pointer): CCarHandlingData
local CCarHandlingData = CStructView("CCarHandlingData", 0x0048)

---@param ptr pointer
---@return CCarHandlingData
function CCarHandlingData.new(ptr)
	return setmetatable({
		m_ptr                                  = ptr,
		m_back_end_popup_car_impulse_mult      = ptr:add(0x0008),
		m_back_end_popup_building_impulse_mult = ptr:add(0x000C),
		m_back_end_popup_max_delta_speed       = ptr:add(0x0010),
		m_toe_front                            = ptr:add(0x0014),
		m_toe_rear                             = ptr:add(0x0018),
		m_camber_front                         = ptr:add(0x001C),
		m_camber_rear                          = ptr:add(0x0020),
		m_castor                               = ptr:add(0x0024),
		m_engine_resistance                    = ptr:add(0x0028),
		m_max_drive_bias_transfer              = ptr:add(0x002C),
		m_jumpforce_scale                      = ptr:add(0x0030),
		m_advanced_flags                       = ptr:add(0x003C),
		m_advanced_data                        = atArray(ptr:add(0x0040))
		---@diagnostic disable-next-line: param-type-mismatch
	}, CCarHandlingData)
end

return CCarHandlingData
