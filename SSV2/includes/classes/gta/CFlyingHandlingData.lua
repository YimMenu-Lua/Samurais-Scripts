-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView = require("includes.classes.gta.CStructView")


--------------------------------------
-- Class: CFlyingHandlingData
--------------------------------------
---@class CFlyingHandlingData : CStructBase<CFlyingHandlingData>
---@field m_thrust pointer<float> -- 0x0008
---@field m_thrust_falloff pointer<float> -- 0x000C
---@field m_thrust_vectoring pointer<float> -- 0x0010
---@field m_initial_thrust pointer<float> -- 0x0014
---@field m_initial_thrust_falloff pointer<float> -- 0x0018
---@field m_yaw_mult pointer<float> -- 0x001C
---@field m_yaw_stability_mult pointer<float> -- 0x0020
---@field m_side_slip_mult pointer<float> -- 0x0024
---@field m_initial_yaw_mult pointer<float> -- 0x0028
---@field m_roll_mult pointer<float> -- 0x002C
---@field m_roll_stability_mult pointer<float> -- 0x0030
---@field m_initial_roll_mult pointer<float> -- 0x0034
---@field m_pitch_mult pointer<float> -- 0x0038
---@field m_pitch_stability_mult pointer<float> -- 0x003C
---@field m_initial_pitch_mult pointer<float> -- 0x0040
---@field m_lift_mult pointer<float> -- 0x0044
---@field m_unk_0048 pointer<float> -- 0x0048
---@field m_dive_mult pointer<float> -- 0x004C
---@field m_gear_down_drag_mult pointer<float> -- 0x0050
---@field m_gear_down_lift_mult pointer<float> -- 0x0054
---@field m_wind_force_mult pointer<float> -- 0x0058
---@field m_move_resistance pointer<float> -- 0x005C
---@field m_turn_resistance pointer<vec3> -- 0x0060
---@field m_speed_resistance pointer<vec3> -- 0x0070
---@field m_gear_door_front_state pointer<float> -- 0x0080
---@field m_gear_door_rl_state pointer<float> -- 0x0084
---@field m_gear_door_rr_state pointer<float> -- 0x0088
---@field m_gear_door_rm_state pointer<float> -- 0x008C
---@field m_turbulence_mag_max pointer<float> -- 0x0090
---@field m_turbulence_force_mult pointer<float> -- 0x0094
---@field m_turbulence_roll_torque_mult pointer<float> -- 0x0098
---@field m_turbulence_pitch_torque_mult pointer<float> -- 0x009C
---@field m_body_damage_control_effect_mult pointer<float> -- 0x00A0
---@field m_unk_00A4 pointer<float> -- 0x00A4
---@field m_ground_yaw_speed_max pointer<float> -- 0x00A8
---@field m_ground_yaw_speed_cap pointer<float> -- 0x00AC
---@field m_glide_mult pointer<float> -- 0x00B0
---@field m_afterburner_effect_radius pointer<float> -- 0x00B4
---@field m_afterburner_effect_dist pointer<float> -- 0x00B8
---@field m_afterburner_effect_force_mult pointer<float> -- 0x00BC
---@field m_submerge_level pointer<float> -- 0x00C0
---@field m_unk_lift_00C4 pointer<float> -- 0x00C4
---@overload fun(ptr: pointer): CFlyingHandlingData
local CFlyingHandlingData = CStructView("CFlyingHandlingData", 0x00C8)

---@param ptr pointer
---@return CFlyingHandlingData
function CFlyingHandlingData.new(ptr)
	return setmetatable({
		m_ptr                             = ptr,
		m_thrust                          = ptr:add(0x0008),
		m_thrust_falloff                  = ptr:add(0x000C),
		m_thrust_vectoring                = ptr:add(0x0010),
		m_initial_thrust                  = ptr:add(0x0014),
		m_initial_thrust_falloff          = ptr:add(0x0018),
		m_yaw_mult                        = ptr:add(0x001C),
		m_yaw_stability_mult              = ptr:add(0x0020),
		m_side_slip_mult                  = ptr:add(0x0024),
		m_initial_yaw_mult                = ptr:add(0x0028),
		m_roll_mult                       = ptr:add(0x002C),
		m_roll_stability_mult             = ptr:add(0x0030),
		m_initial_roll_mult               = ptr:add(0x0034),
		m_pitch_mult                      = ptr:add(0x0038),
		m_pitch_stability_mult            = ptr:add(0x003C),
		m_initial_pitch_mult              = ptr:add(0x0040),
		m_lift_mult                       = ptr:add(0x0044),
		m_unk_0048                        = ptr:add(0x0048),
		m_dive_mult                       = ptr:add(0x004C),
		m_gear_down_drag_mult             = ptr:add(0x0050),
		m_gear_down_lift_mult             = ptr:add(0x0054),
		m_wind_force_mult                 = ptr:add(0x0058),
		m_move_resistance                 = ptr:add(0x005C),
		m_turn_resistance                 = ptr:add(0x0060),
		m_speed_resistance                = ptr:add(0x0070),
		m_gear_door_front_state           = ptr:add(0x0080),
		m_gear_door_rl_state              = ptr:add(0x0084),
		m_gear_door_rr_state              = ptr:add(0x0088),
		m_gear_door_rm_state              = ptr:add(0x008C),
		m_turbulence_mag_max              = ptr:add(0x0090),
		m_turbulence_force_mult           = ptr:add(0x0094),
		m_turbulence_roll_torque_mult     = ptr:add(0x0098),
		m_turbulence_pitch_torque_mult    = ptr:add(0x009C),
		m_body_damage_control_effect_mult = ptr:add(0x00A0),
		m_unk_00A4                        = ptr:add(0x00A4),
		m_ground_yaw_speed_max            = ptr:add(0x00A8),
		m_ground_yaw_speed_cap            = ptr:add(0x00AC),
		m_glide_mult                      = ptr:add(0x00B0),
		m_afterburner_effect_radius       = ptr:add(0x00B4),
		m_afterburner_effect_dist         = ptr:add(0x00B8),
		m_afterburner_effect_force_mult   = ptr:add(0x00BC),
		m_submerge_level                  = ptr:add(0x00C0),
		m_unk_lift_00C4                   = ptr:add(0x00C4),
		---@diagnostic disable-next-line: param-type-mismatch
	}, CFlyingHandlingData)
end

return CFlyingHandlingData
