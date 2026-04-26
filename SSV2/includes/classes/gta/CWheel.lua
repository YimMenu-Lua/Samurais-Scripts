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
---@field m_y_rotation pointer<float>
---@field m_y_rotation_inv pointer<float>
---@field m_offset_from_body pointer<float>
---@field m_x_offset pointer<float> // same as offset from body?
---@field m_last_ground_pos pointer<vec3>
---@field m_wheel_transform array<pointer<fMatrix44>> // TODO: this is wrong; fix it // NOTE: these seem to be a bunch of vector3s, not a 4x4 matrix
---@field m_parallel_wheel_index pointer<int8_t>
---@field m_tyre_radius pointer<float> -- these now work but I had no patience to figure out how to reset them. wheel width/radius changes and sticks but the value in memory immediately reverses back to default
---@field m_rim_radius pointer<float> -- //
---@field m_unk_rim_radius pointer<float> -- // I have no idea what this is for. Its the exact same as 0x0114
---@field m_tyre_width pointer<float>
---@field m_handling_data pointer<CHandlingData>
---@field m_vehicle pointer<CVehicle>
---@field m_suspension_length pointer<float>
---@field m_max_suspension_travel pointer<float>
---@field m_rest_position pointer<float>
---@field m_rest_position_2 pointer<float>
---@field m_unk0140 pointer<float>
---@field m_accel_mass_mult pointer<float>
---@field m_unk_0148 pointer<float>
---@field m_suspension_raise pointer<float>
---@field m_unk_suspension_raise pointer<float>
---@field m_suspension_fwd_offset pointer<float> prefer this to raise/lower individual wheels
---@field m_hydraulic_state pointer<int32_t> some enum related to hydraulic state. can't find any refs online. where's Yimura when you need to skid from him? :(
---@field m_hydraulic_state_2 pointer<int32_t> -- ??
---@field m_suspension_compression pointer<float>
---@field m_suspension_compression_2 pointer<float>
---@field m_wheel_compression pointer<float>
---@field m_rotation_angle pointer -- radians?
---@field m_rotation_speed pointer -- velocity
---@field m_unk_0174 pointer -- ??
---@field m_tyre_temperature pointer<float> -- don't want to admit how long it took to figure out what this little shit is. are we playing Assetto Corsa now? it seems to only be relevant for F1 vehicles
---@field m_unk_0194 pointer -- ??
---@field m_tire_drag_coeff pointer<float>
---@field m_top_speed_mult pointer<float>
---@field m_steering_angle pointer<float>
---@field m_brake_force pointer<float>
---@field m_drive_force pointer<float>
---@field m_unk_01E4 pointer<float>
---@field m_suspension_health pointer<float> -- 100.0f: car gets slammed (old method of shooting your suspension to stance your car) // 0.0f: wheel should fall off but doesn't. Something else must be set to trigger wheel detachment
---@field m_tyre_health pointer<float> -- <= 500.0f: flat tyre // 0.0f: no tyre
---@field m_tyre_wear_mult pointer<float> -- 0.0f: tyres won't burst from long burnout
---@field m_tyre_wear_unk pointer<float> -- similar? // looks like a wear rate not current tyre wear
---@field m_wheel_dynamic_flags pointer<eWheelDynamicFlags>
---@field m_wheel_config_flags pointer<eWheelConfigFlags>
---@field m_tyre_is_burst pointer<bool>
---@field m_unk_020C pointer<byte>
---@field m_has_donk_hydraulics pointer<bool> -- true for cars with DONK mod
---@overload fun(addr: pointer): CWheel
local CWheel = CStructView("CWheel", 0x020E)

---@param ptr pointer
---@return CWheel
function CWheel.new(ptr)
	return setmetatable({
		m_ptr                      = ptr,
		m_y_rotation               = ptr:add(0x0008),
		m_y_rotation_inv           = ptr:add(0x0010),
		m_offset_from_body         = ptr:add(0x0020),
		m_x_offset                 = ptr:add(0x0030),
		m_last_ground_pos          = ptr:add(0x003C),
		m_wheel_transform          = { ptr:add(0x090), ptr:add(0x0A0), ptr:add(0x0B0), ptr:add(0x0C0) },
		m_parallel_wheel_index     = ptr:add(0x010F),
		m_tyre_radius              = ptr:add(0x0110),
		m_rim_radius               = ptr:add(0x0114),
		m_unk_rim_radius           = ptr:add(0x0118),
		m_tyre_width               = ptr:add(0x011C),
		m_handling_data            = ptr:add(0x0120),
		m_vehicle                  = ptr:add(0x0128),
		m_suspension_length        = ptr:add(0x0130),
		m_max_suspension_travel    = ptr:add(0x0134),
		m_rest_position            = ptr:add(0x0138),
		m_rest_position_2          = ptr:add(0x013C),
		m_unk_0140                 = ptr:add(0x0140),
		m_accel_mass_mult          = ptr:add(0x0144),
		m_unk_0148                 = ptr:add(0x0148),
		m_suspension_raise         = ptr:add(0x014C),
		m_unk_suspension_raise     = ptr:add(0x0150),
		m_suspension_fwd_offset    = ptr:add(0x0154),
		m_hydraulic_state          = ptr:add(0x0158),
		m_hydraulic_state_2        = ptr:add(0x015C),
		m_suspension_compression   = ptr:add(0x0160),
		m_suspension_compression_2 = ptr:add(0x0164),
		m_wheel_compression        = ptr:add(0x0168),
		m_rotation_angle           = ptr:add(0x016C),
		m_rotation_speed           = ptr:add(0x0170),
		m_unk_0174                 = ptr:add(0x0174),
		m_tyre_temperature         = ptr:add(0x0178),
		m_unk_0194                 = ptr:add(0x0194),
		m_tire_drag_coeff          = ptr:add(0x0198),
		m_top_speed_mult           = ptr:add(0x019C),
		m_steering_angle           = ptr:add(0x01CC),
		m_brake_force              = ptr:add(0x01DC),
		m_drive_force              = ptr:add(0x01E0),
		m_unk_01E4                 = ptr:add(0x01E4),
		m_suspension_health        = ptr:add(0x01E8),
		m_tyre_health              = ptr:add(0x01EC),
		m_tyre_wear_mult           = ptr:add(0x01F0),
		m_tyre_wear_unk            = ptr:add(0x01F4),
		m_unk_01F8                 = ptr:add(0x01F8),
		m_wheel_dynamic_flags      = ptr:add(0x0200),
		m_wheel_config_flags       = ptr:add(0x0204),
		m_tyre_is_burst            = ptr:add(0x020B),
		m_unk_020C                 = ptr:add(0x020C),
		m_has_donk_hydraulics      = ptr:add(0x020D),
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
		return Bit.IsBitSet(self.m_wheel_dynamic_flags:get_dword(), flag)
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
		local dwFlags = self.m_wheel_dynamic_flags:get_dword()
		local newBits = Bit.Toggle(dwFlags, flag, toggle)
		self.m_wheel_dynamic_flags:set_dword(newBits)
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
