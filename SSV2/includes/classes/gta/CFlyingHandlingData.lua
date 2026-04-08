-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView          = require("includes.classes.gta.CStructView")
local CBaseSubHandlingData = require("includes.classes.gta.CBaseSubHandlingData")


--------------------------------------
-- Class: CFlyingHandlingData
--------------------------------------
---@class CFlyingHandlingData : CBaseSubHandlingData
---@field protected m_ptr pointer
---@field public m_thrust pointer<float> -- 0x0008
---@field public m_thrust_falloff pointer<float> -- 0x000C
---@field public m_thrust_vectoring pointer<float> -- 0x0010
---@field public m_initial_thrust pointer<float> -- 0x0014
---@field public m_initial_thrust_falloff pointer<float> -- 0x0018
---@field public m_yaw_mult pointer<float> -- 0x001C
---@field public m_yaw_stability_mult pointer<float> -- 0x0020
---@field public m_side_slip_mult pointer<float> -- 0x0024
---@field public m_initial_yaw_mult pointer<float> -- 0x0028
---@field public m_roll_mult pointer<float> -- 0x002C
---@field public m_roll_stability_mult pointer<float> -- 0x0030
---@field public m_initial_roll_mult pointer<float> -- 0x0034
---@field public m_pitch_mult pointer<float> -- 0x0038
---@field public m_pitch_stability_mult pointer<float> -- 0x003C
---@field public m_initial_pitch_mult pointer<float> -- 0x0040
---@field public m_lift_mult pointer<float> -- 0x0044
---@field public m_unk_0048 pointer<float> -- 0x0048
---@field public m_dive_mult pointer<float> -- 0x004C
---@field public m_gear_down_drag_mult pointer<float> -- 0x0050
---@field public m_gear_down_lift_mult pointer<float> -- 0x0054
---@field public m_wind_force_mult pointer<float> -- 0x0058
---@field public m_move_resistance pointer<float> -- 0x005C
---@field public m_turn_resistance pointer<vec3> -- 0x0060
---@field public m_speed_resistance pointer<vec3> -- 0x0070
---@field public m_gear_door_front_state pointer<float> -- 0x0080
---@field public m_gear_door_rl_state pointer<float> -- 0x0084
---@field public m_gear_door_rr_state pointer<float> -- 0x0088
---@field public m_gear_door_rm_state pointer<float> -- 0x008C
---@field public m_turbulence_mag_max pointer<float> -- 0x0090
---@field public m_turbulence_force_mult pointer<float> -- 0x0094
---@field public m_turbulence_roll_torque_mult pointer<float> -- 0x0098
---@field public m_turbulence_pitch_torque_mult pointer<float> -- 0x009C
---@field public m_body_damage_control_effect_mult pointer<float> -- 0x00A0
---@field public m_unk_00A4 pointer<float> -- 0x00A4
---@field public m_ground_yaw_speed_max pointer<float> -- 0x00A8
---@field public m_ground_yaw_speed_cap pointer<float> -- 0x00AC
---@field public m_glide_mult pointer<float> -- 0x00B0
---@field public m_afterburner_effect_radius pointer<float> -- 0x00B4
---@field public m_afterburner_effect_dist pointer<float> -- 0x00B8
---@field public m_afterburner_effect_force_mult pointer<float> -- 0x00BC
---@field public m_submerge_level pointer<float> -- 0x00C0
---@field public m_unk_lift_00C4 pointer<float> -- 0x00C4
---@overload fun(ptr: pointer): CFlyingHandlingData
local CFlyingHandlingData = Class("CFlyingHandlingData", { parent = CBaseSubHandlingData, pointer_ctor = true })

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
