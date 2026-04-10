-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.

local CStructView = require("includes.classes.gta.CStructView")


---@class CVehicleModelInfoLayout

--------------------------------------
-- Class: CVehicleModelInfo
--------------------------------------
---@class CVehicleModelInfo : CStructBase<CVehicleModelInfo>
---@field protected m_ptr pointer
---@field m_vehicle_layout pointer_ref<CVehicleModelInfoLayout>
---@field m_vehicle_type pointer<eVehicleType>
---@field m_model_info_flags pointer<uint32_t>
---@field m_wheel_scale pointer<float>
---@field m_wheel_scale_rear pointer<float>
---@field m_throttle_position pointer<float>
---@overload fun(ptr: pointer): CVehicleModelInfo
local CVehicleModelInfo = CStructView("CVehicleModelInfo", 0x08DC)

---@param ptr pointer
---@return CVehicleModelInfo
function CVehicleModelInfo.new(ptr)
	return setmetatable({
		m_ptr               = ptr,
		m_vehicle_layout    = ptr:add(0x00B0),
		m_vehicle_type      = ptr:add(0x0340),
		m_wheel_scale       = ptr:add(0x048C),
		m_wheel_scale_rear  = ptr:add(0x0490),
		m_model_info_flags  = ptr:add(0x057C),
		m_throttle_position = ptr:add(0x08D8),
		---@diagnostic disable-next-line: param-type-mismatch
	}, CVehicleModelInfo)
end

---@return eVehicleType
function CVehicleModelInfo:GetVehicleType()
	return self:__safecall(Enums.eVehicleType.VEHICLE_TYPE_NONE, function()
		return self.m_vehicle_type:get_dword()
	end)
end

---@param flag eVehicleModelInfoFlags
---@return boolean
function CVehicleModelInfo:GetModelInfoFlag(flag)
	return self:__safecall(false, function()
		if (not self.m_model_info_flags:is_valid()) then
			return false
		end

		local index    = math.floor(flag / 32)
		local bit_pos  = flag % 32
		local flag_ptr = self.m_model_info_flags:add(index * 4)
		if (flag_ptr:is_null()) then
			return false
		end

		local flag_bits = flag_ptr:get_dword()
		return Bit.IsBitSet(flag_bits, bit_pos)
	end)
end

---@param flag eVehicleModelInfoFlags
---@param toggle boolean
function CVehicleModelInfo:SetModelInfoFlag(flag, toggle)
	if (not self:IsValid()) then
		return
	end

	local index    = math.floor(flag / 32)
	local bit_pos  = flag % 32
	local flag_ptr = self.m_model_info_flags:add(index * 4)
	if (flag_ptr:is_null()) then
		return
	end

	local flag_bits = flag_ptr:get_dword()
	local new_bits  = Bit.Toggle(flag_bits, bit_pos, toggle)
	flag_ptr:set_dword(new_bits)
end

return CVehicleModelInfo
