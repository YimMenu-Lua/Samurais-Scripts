-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class CBikeHandlingData : CBaseSubHandlingData
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
---@field m_wheelie_walance_point pointer<float> -- 0x0034
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
local CBikeHandlingData = { m_size = 0x005C }
CBikeHandlingData.__index = CBikeHandlingData
---@diagnostic disable-next-line: param-type-mismatch
setmetatable(CBikeHandlingData, {
	__call = function(cls, ...)
		return cls.new(...)
	end,
})

---@param ptr pointer
---@return CBikeHandlingData|nil
function CBikeHandlingData.new(ptr)
	if (not ptr or ptr:is_null()) then
		return
	end

	---@diagnostic disable-next-line: param-type-mismatch
	local instance                             = setmetatable({}, CBikeHandlingData)
	instance.m_ptr                             = ptr
	instance.m_lean_fwd_com_mult               = ptr:add(0x0008)
	instance.m_lean_fwd_force_mult             = ptr:add(0x000C)
	instance.m_lean_back_com_mult              = ptr:add(0x0010)
	instance.m_lean_back_force_mult            = ptr:add(0x0014)
	instance.m_max_bank_angle                  = ptr:add(0x0018)
	instance.m_anim_angle                      = ptr:add(0x001C)
	instance.m_anim_angle_inv                  = ptr:add(0x0020)
	instance.m_unk_0024                        = ptr:add(0x0024)
	instance.m_lean_mult                       = ptr:add(0x0028)
	instance.m_brake_force_mult                = ptr:add(0x002C)
	instance.m_air_steer_mult                  = ptr:add(0x0030)
	instance.m_wheelie_walance_point           = ptr:add(0x0034)
	instance.m_stoppie_balance_mult            = ptr:add(0x0038)
	instance.m_wheelie_steer_mult              = ptr:add(0x003C)
	instance.m_rear_balance_mult               = ptr:add(0x0040)
	instance.m_front_balance_mult              = ptr:add(0x0044)
	instance.m_ground_side_friction_mult       = ptr:add(0x0048)
	instance.m_wheel_ground_side_friction_mult = ptr:add(0x004C)
	instance.m_unk_angle_0050                  = ptr:add(0x0050)
	instance.m_unk_angle_0054                  = ptr:add(0x0054)
	instance.m_jump_force_mult                 = ptr:add(0x0058)

	return instance
end

return CBikeHandlingData
