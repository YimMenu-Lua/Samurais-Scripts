-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView = require("includes.classes.gta.CStructView")

---@class CCarHandlingData : CBaseSubHandlingData
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
local CCarHandlingData = CStructView("CCarHandlingData", {
	{ "m_back_end_popup_car_impulse_mult",      0x0008 },
	{ "m_back_end_popup_building_impulse_mult", 0x000C },
	{ "m_back_end_popup_max_delta_speed",       0x0010 },
	{ "m_toe_front",                            0x0014 },
	{ "m_toe_rear",                             0x0018 },
	{ "m_camber_front",                         0x001C },
	{ "m_camber_rear",                          0x0020 },
	{ "m_castor",                               0x0024 },
	{ "m_engine_resistance",                    0x0028 },
	{ "m_max_drive_bias_transfer",              0x002C },
	{ "m_jumpforce_scale",                      0x0030 },
	{ "m_advanced_flags",                       0x003C },
	{ "m_advanced_data",                        0x0040, atArray },
}, 0x0048)

return CCarHandlingData
