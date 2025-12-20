---@class CFlyingHandlingData : CBaseSubHandlingData
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
---@overload fun(addr: pointer): CFlyingHandlingData
local CFlyingHandlingData = { m_size = 0x00C8 }
CFlyingHandlingData.__index = CFlyingHandlingData
---@diagnostic disable-next-line: param-type-mismatch
setmetatable(CFlyingHandlingData, {
	__call = function(cls, ...)
		return cls.new(...)
	end,
})

---@param ptr pointer
---@return CFlyingHandlingData|nil
function CFlyingHandlingData.new(ptr)
	if not ptr or ptr:is_null() then return end

	---@diagnostic disable-next-line: param-type-mismatch
	local instance                             = setmetatable({}, CFlyingHandlingData)
	instance.m_ptr                             = ptr
	instance.m_thrust                          = ptr:add(0x0008)
	instance.m_thrust_falloff                  = ptr:add(0x000C)
	instance.m_thrust_vectoring                = ptr:add(0x0010)
	instance.m_initial_thrust                  = ptr:add(0x0014)
	instance.m_initial_thrust_falloff          = ptr:add(0x0018)
	instance.m_yaw_mult                        = ptr:add(0x001C)
	instance.m_yaw_stability_mult              = ptr:add(0x0020)
	instance.m_side_slip_mult                  = ptr:add(0x0024)
	instance.m_initial_yaw_mult                = ptr:add(0x0028)
	instance.m_roll_mult                       = ptr:add(0x002C)
	instance.m_roll_stability_mult             = ptr:add(0x0030)
	instance.m_initial_roll_mult               = ptr:add(0x0034)
	instance.m_pitch_mult                      = ptr:add(0x0038)
	instance.m_pitch_stability_mult            = ptr:add(0x003C)
	instance.m_initial_pitch_mult              = ptr:add(0x0040)
	instance.m_lift_mult                       = ptr:add(0x0044)
	instance.m_unk_0048                        = ptr:add(0x0048)
	instance.m_dive_mult                       = ptr:add(0x004C)
	instance.m_gear_down_drag_mult             = ptr:add(0x0050)
	instance.m_gear_down_lift_mult             = ptr:add(0x0054)
	instance.m_wind_force_mult                 = ptr:add(0x0058)
	instance.m_move_resistance                 = ptr:add(0x005C)
	instance.m_turn_resistance                 = ptr:add(0x0060)
	instance.m_speed_resistance                = ptr:add(0x0070)
	instance.m_gear_door_front_state           = ptr:add(0x0080)
	instance.m_gear_door_rl_state              = ptr:add(0x0084)
	instance.m_gear_door_rr_state              = ptr:add(0x0088)
	instance.m_gear_door_rm_state              = ptr:add(0x008C)
	instance.m_turbulence_mag_max              = ptr:add(0x0090)
	instance.m_turbulence_force_mult           = ptr:add(0x0094)
	instance.m_turbulence_roll_torque_mult     = ptr:add(0x0098)
	instance.m_turbulence_pitch_torque_mult    = ptr:add(0x009C)
	instance.m_body_damage_control_effect_mult = ptr:add(0x00A0)
	instance.m_unk_00A4                        = ptr:add(0x00A4)
	instance.m_ground_yaw_speed_max            = ptr:add(0x00A8)
	instance.m_ground_yaw_speed_cap            = ptr:add(0x00AC)
	instance.m_glide_mult                      = ptr:add(0x00B0)
	instance.m_afterburner_effect_radius       = ptr:add(0x00B4)
	instance.m_afterburner_effect_dist         = ptr:add(0x00B8)
	instance.m_afterburner_effect_force_mult   = ptr:add(0x00BC)
	instance.m_submerge_level                  = ptr:add(0x00C0)
	instance.m_unk_lift_00C4                   = ptr:add(0x00C4)

	return instance
end

return CFlyingHandlingData
