-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView       = require("includes.classes.gta.CStructView")
local VEC3_ZERO <const> = vec3:zero()


--------------------------------------
-- Class: CWheel
--------------------------------------
---@ignore
---@class CWheel : CStructBase<CWheel>
---@field protected m_ptr pointer
---@field private m_size uint16_t
---@field m_y_rotation pointer<float> //0x008
---@field m_y_rotation_inv pointer<float> //0x010
---@field m_offset_from_body pointer<float> //0x020
---@field m_x_offset pointer<float> // 0x030 same as offset from body?
---@field m_last_ground_pos pointer<vec3> // 0x03C
---@field m_wheel_transform array<pointer<fMatrix44>> // 0x090 - 0x0BC `rage::fMatrix44` -- TODO: this is wrong; fix it
---@field m_unk_flags pointer<uint32_t> //0x0C8
---@field m_tyre_radius pointer<float> //0xF4
---@field m_rim_radius pointer<float> //0xF6
---@field m_old_rim_radius pointer<float> //0xFA
---@field m_tyre_width pointer<float> //0xFE
---@field m_handling_data pointer<CHandlingData> //0x102
---@field m_vehicle pointer<CVehicle> //0x106
---@field m_suspension_length pointer<float> //0x110
---@field m_max_suspension_travel pointer<float> //0x114
---@field m_suspension_forward_offset pointer<float> //0x13C // prefer this to raise/lower individual wheels
---@field m_suspension_compression pointer<float> // 0x164
---@field m_suspension_compression_2 pointer<float> // 0x168
---@field m_wheel_compression pointer<float> // 0x16C
---@field m_rotation_speed pointer // 0x170
---@field m_unk0190 pointer // ?? 0x190
---@field m_unk0194 pointer // ?? 0x194
---@field m_tire_drag_coeff pointer<float> // 0x198
---@field m_top_speed_mult pointer<float> // 0x19C
---@field m_steering_angle pointer<float> // 0x1CC
---@field m_brake_force pointer<float> // 0x1D0
---@field m_drive_force pointer<float> // 0x1D4
---@field m_suspension_health pointer<float> // 0x1E8 // 100.0f: car gets slammed (old method of shooting your suspension to stance your car) // 0.0f: wheel should fall off but doesn't. Something else must be set to trigger wheel detachment
---@field m_tyre_health pointer<float> // 0x1EC // <= 500.0f: flat tyre // 0.0f: no tyre
---@field m_tyre_wear_mult pointer<float> // 0x1F0 // 0.0f: tyres won't burst from long burnout
---@field m_tyre_wear_unk pointer<float> // 0x1F8 // similar?
---@field m_wheel_flags pointer<eWheelDynamicFlags> // 0x200
---@field m_wheel_config_flags pointer<eWheelConfigFlags> // 0x204
---@field m_unk_u16 pointer<uint16_t> // 0x208
---@field m_unk_u8 pointer<uint8_t> // 0x20A
---@field m_tyre_is_burst pointer<bool> // 0x20B
---@field m_unk_byte pointer<byte> // 0x20C
---@field m_has_hydraulics pointer<bool> // 0x20D // true for cars with DONK mod
---@overload fun(addr: pointer): CWheel|nil
local CWheel = CStructView("CWheel", 0x020E)

---@param ptr pointer
---@return CWheel
function CWheel.new(ptr)
	return setmetatable({
		m_ptr                       = ptr,
		m_y_rotation                = ptr:add(0x008),
		m_y_rotation_inv            = ptr:add(0x010),
		m_offset_from_body          = ptr:add(0x020),
		m_x_offset                  = ptr:add(0x030),
		m_last_ground_pos           = ptr:add(0x03C),
		m_wheel_transform           = { ptr:add(0x090), ptr:add(0x0A0), ptr:add(0x0B0), ptr:add(0x0C0) },
		m_unk_flags                 = ptr:add(0x0C8),
		m_tyre_radius               = ptr:add(0x0F4),
		m_rim_radius                = ptr:add(0x0F6),
		m_old_rim_radius            = ptr:add(0x0FA),
		m_tyre_width                = ptr:add(0x0FE),
		m_handling_data             = ptr:add(0x102),
		m_vehicle                   = ptr:add(0x106),
		m_suspension_length         = ptr:add(0x110),
		m_max_suspension_travel     = ptr:add(0x114),
		m_suspension_forward_offset = ptr:add(0x13C),
		m_suspension_compression_2  = ptr:add(0x168),
		m_wheel_compression         = ptr:add(0x16C),
		m_rotation_speed            = ptr:add(0x170),
		m_unk0190                   = ptr:add(0x190),
		m_unk0194                   = ptr:add(0x194),
		m_tire_drag_coeff           = ptr:add(0x198),
		m_top_speed_mult            = ptr:add(0x19C),
		m_steering_angle            = ptr:add(0x1CC),
		m_brake_force               = ptr:add(0x1D0),
		m_drive_force               = ptr:add(0x1D4),
		m_suspension_health         = ptr:add(0x1E8),
		m_tyre_health               = ptr:add(0x1EC),
		m_tyre_wear_mult            = ptr:add(0x1F0),
		m_tyre_wear_unk             = ptr:add(0x1F8),
		m_wheel_flags               = ptr:add(0x200),
		m_wheel_config_flags        = ptr:add(0x204),
		m_unk_u16                   = ptr:add(0x208),
		m_unk_u8                    = ptr:add(0x20A),
		m_tyre_is_burst             = ptr:add(0x20B),
		m_unk_byte                  = ptr:add(0x20C),
		m_has_hydraulics            = ptr:add(0x20D),
		---@diagnostic disable-next-line: param-type-mismatch
	}, CWheel)
end

---@return vec3 -- The world position of the wheel or a zero vector if the wheel is invalid.
function CWheel:GetWorldPosition()
	return self:__safecall(VEC3_ZERO, function()
		return self.m_last_ground_pos:get_vec3()
	end)
end

-- test
---@return vec3
function CWheel:GetTransformRight()
	return self:__safecall(VEC3_ZERO, function()
		return self.m_wheel_transform[1]:get_vec3()
	end)
end

-- test
---@return vec3
function CWheel:GetTransformFwd()
	return self:__safecall(VEC3_ZERO, function()
		return self.m_wheel_transform[2]:get_vec3()
	end)
end

-- test
---@return vec3
function CWheel:GetTransformUp()
	return self:__safecall(VEC3_ZERO, function()
		return self.m_wheel_transform[3]:get_vec3()
	end)
end

-- test
---@return vec3
function CWheel:GetTransformPos()
	return self:__safecall(VEC3_ZERO, function()
		return self.m_wheel_transform[4]:get_vec3()
	end)
end

-- test
---@return float
function CWheel:GetTiltAngle()
	return self:__safecall(0.0, function()
		local up       = self:GetTransformUp()
		local world_up = vec3:new(0, 0, 1)
		local dot      = up:dot_product(world_up)
		local mag      = up:length()
		if (mag == 0) then
			return 0.0
		end

		return math.deg(math.acos(dot / mag))
	end)
end

---@param flag eWheelDynamicFlags
---@return boolean
function CWheel:GetDynamicFlag(flag)
	return self:__safecall(false, function()
		return Bit.IsBitSet(self.m_wheel_flags:get_dword(), flag)
	end)
end

---@param flag eWheelConfigFlags
---@return boolean
function CWheel:GetConfigFlag(flag)
	return self:__safecall(false, function()
		return Bit.IsBitSet(self.m_wheel_config_flags:get_dword(), flag)
	end)
end

---@param flag eWheelDynamicFlags
---@param toggle boolean
---@return boolean
function CWheel:SetDynamicFlag(flag, toggle)
	return self:__safecall(false, function()
		local dwFlags = self.m_wheel_flags:get_dword()
		local newBits = Bit.Toggle(dwFlags, flag, toggle)
		self.m_wheel_flags:set_dword(newBits)
		return true
	end)
end

---@param flag eWheelConfigFlags
---@param toggle boolean
---@return boolean
function CWheel:SetConfigFlag(flag, toggle)
	return self:__safecall(false, function()
		local dwFlags = self.m_wheel_config_flags:get_dword()
		local newBits = Bit.Toggle(dwFlags, flag, toggle)
		self.m_wheel_config_flags:set_dword(newBits)
		return true
	end)
end

---@return boolean
function CWheel:IsLeftWheel()
	return self:GetConfigFlag(Enums.eWheelConfigFlags.LEFT_WHEEL)
end

---@return boolean
function CWheel:IsRearWheel()
	return self:GetConfigFlag(Enums.eWheelConfigFlags.REAR_WHEEL)
end

return CWheel
