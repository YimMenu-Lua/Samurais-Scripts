-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.
--
-- Converted from Yimura's C++ GTA V Classes: https://github.com/Yimura/GTAV-Classes (forked here: https://github.com/Mr-X-GTA/GTAV-Classes-1)


local atArray                    = require("includes.classes.gta.atArray")
local CBikeHandlingData          = require("includes.classes.gta.CBikeHandlingData")
local CCarHandlingData           = require("includes.classes.gta.CCarHandlingData")
local CFlyingHandlingData        = require("includes.classes.gta.CFlyingHandlingData")
local CStructView                = require("includes.classes.gta.CStructView")

local SubHandlingCtorMap <const> = {
	[Enums.eVehicleType.VEHICLE_TYPE_CAR]   = function(ptr) return CCarHandlingData.new(ptr) end,
	[Enums.eVehicleType.VEHICLE_TYPE_BIKE]  = function(ptr) return CBikeHandlingData.new(ptr) end,
	[Enums.eVehicleType.VEHICLE_TYPE_PLANE] = function(ptr) return CFlyingHandlingData.new(ptr) end,
}


--------------------------------------
-- Class: CHandlingData
--------------------------------------
---@class CHandlingData : CStructBase<CHandlingData>
---@field protected m_ptr pointer
---@field m_sub_handling_data atArray<CBaseSubHandlingData>
---@field m_mass pointer<float> -- 0x000C
---@field m_initial_drag_coeff pointer<float>
---@field m_drive_bias_rear pointer<float>
---@field m_drive_bias_front pointer<float>
---@field m_acceleration pointer<float>
---@field m_initial_drive_gears pointer<uint8_t>
---@field m_initial_drive_force pointer<float>
---@field m_drive_max_flat_velocity pointer<float>
---@field m_initial_drive_max_flat_vel pointer<float>
---@field m_steering_lock pointer<float>
---@field m_steering_lock_ratio pointer<float>
---@field m_traction_curve_max pointer<float>
---@field m_low_speed_traction_loss_mult pointer<float>
---@field m_traction_loss_mult pointer<float>
---@field m_deform_mult pointer<float>
---@field m_monetary_value pointer<uint32_t>
---@field m_model_flags pointer<eVehicleModelFlags>
---@field m_handling_flags pointer<eVehicleHandlingFlags>
---@field m_damage_flags pointer<uint32_t>
---@field protected m_subhandling_data_instance CCarHandlingData|CBikeHandlingData|CCarHandlingData|CFlyingHandlingData
---@overload fun(ptr: pointer, vehicleType: eVehicleType): CHandlingData
local CHandlingData = CStructView("CHandlingData", 0x0048)

---@param ptr pointer
---@param vehicleType eVehicleType
---@return CHandlingData
function CHandlingData.new(ptr, vehicleType)
	local instance = setmetatable({
		m_ptr                          = ptr,
		m_mass                         = ptr:add(0x000C),
		m_initial_drag_coeff           = ptr:add(0x0010),
		m_drive_bias_rear              = ptr:add(0x0044),
		m_drive_bias_front             = ptr:add(0x0048),
		m_acceleration                 = ptr:add(0x004C),
		m_initial_drive_gears          = ptr:add(0x0050),
		m_initial_drive_force          = ptr:add(0x0060),
		m_drive_max_flat_velocity      = ptr:add(0x0064),
		m_initial_drive_max_flat_vel   = ptr:add(0x0068),
		m_steering_lock                = ptr:add(0x0080),
		m_steering_lock_ratio          = ptr:add(0x0084),
		m_traction_curve_max           = ptr:add(0x0088),
		m_low_speed_traction_loss_mult = ptr:add(0x00A8),
		m_traction_loss_mult           = ptr:add(0x00B8),
		m_deform_mult                  = ptr:add(0x00F8),
		m_monetary_value               = ptr:add(0x0118),
		m_model_flags                  = ptr:add(0x0124),
		m_handling_flags               = ptr:add(0x0128),
		m_damage_flags                 = ptr:add(0x012C),
		m_sub_handling_data            = atArray(ptr:add(0x0158)),
		---@diagnostic disable-next-line: param-type-mismatch
	}, CHandlingData)

	local subCtor = SubHandlingCtorMap[vehicleType]
	if (subCtor) then
		instance.m_subhandling_data_instance = subCtor(instance.m_sub_handling_data[1]:deref())
	end

	return instance
end

---@return float
function CHandlingData:GetAcceleration()
	return self:__safecall(0.0, function()
		return self.m_acceleration:get_float()
	end)
end

---@return float
function CHandlingData:GetDeformMultiplier()
	return self:__safecall(0.0, function()
		return self.m_deform_mult:get_float()
	end)
end

---@return uint32_t
function CHandlingData:GetHandlingFlags()
	return self:__safecall(0, function()
		return self.m_handling_flags:get_dword()
	end)
end

---@param flag eVehicleHandlingFlags
---@return boolean
function CHandlingData:GetHandlingFlag(flag)
	return self:__safecall(false, function()
		return Bit.IsBitSet(self.m_handling_flags:get_dword(), flag)
	end)
end

---@return uint32_t
function CHandlingData:GetModelFlags()
	return self:__safecall(0, function()
		return self.m_model_flags:get_dword()
	end)
end

---@param flag eVehicleModelFlags
---@return boolean
function CHandlingData:GetModelFlag(flag)
	return self:__safecall(false, function()
		return Bit.IsBitSet(self.m_model_flags:get_dword(), flag)
	end)
end

---@return (CCarHandlingData|CBikeHandlingData|CFlyingHandlingData|)?
function CHandlingData:GetSubHandlingData()
	return self.m_subhandling_data_instance
end

---@param value float
---@return boolean
function CHandlingData:SetAcceleration(value)
	return self:__safecall(false, function()
		self.m_acceleration:set_float(value)
		return self.m_acceleration:get_float() == value
	end)
end

---@param value float
---@return boolean
function CHandlingData:SetDeformMultiplier(value)
	return self:__safecall(false, function()
		self.m_deform_mult:set_float(value)
		return self.m_deform_mult:get_float() == value
	end)
end

---@param flags uint32_t
---@return boolean
function CHandlingData:SetHandlingFlags(flags)
	return self:__safecall(false, function()
		if (self.m_handling_flags:is_null()) then return false end
		self.m_handling_flags:set_dword(flags)
		return true
	end)
end

---@param flag eVehicleHandlingFlags
---@param toggle boolean
---@return boolean
function CHandlingData:SetHandlingFlag(flag, toggle)
	if (type(flag) ~= "number" or type(toggle) ~= "boolean") then
		return false
	end

	return self:__safecall(false, function()
		if (self.m_handling_flags:is_null()) then return false end
		local dword_flags = self.m_handling_flags:get_dword()
		self.m_handling_flags:set_dword(Bit.Toggle(dword_flags, flag, toggle))
		return true
	end)
end

---@param flags uint32_t
---@return boolean
function CHandlingData:SetModelFlags(flags)
	return self:__safecall(false, function()
		if (self.m_model_flags:is_null()) then return false end
		self.m_model_flags:set_dword(flags)
		return true
	end)
end

---@param flag eVehicleModelFlags
---@param toggle boolean
---@return boolean
function CHandlingData:SetModelFlag(flag, toggle)
	if (type(flag) ~= "number" or type(toggle) ~= "boolean") then
		return false
	end

	return self:__safecall(false, function()
		if (self.m_model_flags:is_null()) then return false end
		local dword_flags = self.m_model_flags:get_dword()
		self.m_model_flags:set_dword(Bit.Toggle(dword_flags, flag, toggle))
		return true
	end)
end

return CHandlingData
