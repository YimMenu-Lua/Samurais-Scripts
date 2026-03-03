-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView = require("includes.classes.gta.CStructView")

---@class CBikeHandlingData : CBaseSubHandlingData
---@field protected m_ptr pointer
---@field m_lean_fwd_com_mult pointer<float> -- 0x0008
---@field m_lean_fwd_force_mult pointer<float> -- 0x000C
---@field m_lean_back_com_mult pointer<float> -- 0x0010
---@field m_lean_back_force_mult pointer<float> -- 0x0014
---@field m_max_bank_angle pointer<float> -- 0x0018
---@field m_anim_angle pointer<float> -- 0x001C
---@field m_anim_angle_inv pointer<float> -- 0x0020
---@field m_unk_0024 pointer<float> -- 0x0024
---@field m_lean_mult pointer<float> -- 0x0028
---@field m_brake_force_mult pointer<float> -- 0x002C
---@field m_air_steer_mult pointer<float> -- 0x0030
---@field m_wheelie_balance_point pointer<float> -- 0x0034
---@field m_stoppie_balance_mult pointer<float> -- 0x0038
---@field m_wheelie_steer_mult pointer<float> -- 0x003C
---@field m_rear_balance_mult pointer<float> -- 0x0040
---@field m_front_balance_mult pointer<float> -- 0x0044
---@field m_ground_side_friction_mult pointer<float> -- 0x0048
---@field m_wheel_ground_side_friction_mult pointer<float> -- 0x004C
---@field m_unk_angle_0050 pointer<float> -- 0x0050
---@field m_unk_angle_0054 pointer<float> -- 0x0054
---@field m_jump_force_mult pointer<float> -- 0x0058
---@overload fun(addr: pointer): CBikeHandlingData
local CBikeHandlingData = CStructView("CBikeHandlingData", {
	{ "m_lean_fwd_com_mult",               0x0008 },
	{ "m_lean_fwd_force_mult",             0x000C },
	{ "m_lean_back_com_mult",              0x0010 },
	{ "m_lean_back_force_mult",            0x0014 },
	{ "m_max_bank_angle",                  0x0018 },
	{ "m_anim_angle",                      0x001C },
	{ "m_anim_angle_inv",                  0x0020 },
	{ "m_unk_0024",                        0x0024 },
	{ "m_lean_mult",                       0x0028 },
	{ "m_brake_force_mult",                0x002C },
	{ "m_air_steer_mult",                  0x0030 },
	{ "m_wheelie_balance_point",           0x0034 },
	{ "m_stoppie_balance_mult",            0x0038 },
	{ "m_wheelie_steer_mult",              0x003C },
	{ "m_rear_balance_mult",               0x0040 },
	{ "m_front_balance_mult",              0x0044 },
	{ "m_ground_side_friction_mult",       0x0048 },
	{ "m_wheel_ground_side_friction_mult", 0x004C },
	{ "m_unk_angle_0050",                  0x0050 },
	{ "m_unk_angle_0054",                  0x0054 },
	{ "m_jump_force_mult",                 0x0058 },
}, 0x005C)

return CBikeHandlingData
