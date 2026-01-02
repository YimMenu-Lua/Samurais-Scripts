---@diagnostic disable: param-type-mismatch

--------------------------------------
-- Class: CWheel
--------------------------------------
---@ignore
---@class CWheel
---@field private m_ptr pointer
---@field private m_size uint16_t
---@field m_y_rotation pointer<float> //0x008
---@field m_y_rotation_inv pointer<float> //0x010
---@field m_offset_from_body pointer<float> //0x020
---@field m_x_offset pointer<float> // 0x030 same as offset from body?
---@field m_last_ground_pos pointer<vec3> // 0x03C
---@field m_wheel_transform array<pointer<fMatrix44>> // 0x090 - 0x0BC `rage::fMatrix44`
---@field m_unk_flags pointer<uint32_t> //0x0C8
---@field m_tire_radius pointer<float> //0x110
---@field m_tire_width pointer<float> //0x118
---@field m_suspension_compression pointer<float> // 0x168 `radians`
---@field m_traction_loss pointer<float> // 0x16C
---@field m_rotation_speed pointer // 0x170
---@field m_unk0190 pointer // ?? 0x190
---@field m_unk0194 pointer // ?? 0x194
---@field m_tire_drag_coeff pointer<float> // 0x198
---@field m_top_speed_mult pointer<float> // 0x19C
---@field m_steering_angle pointer<float> // 0x1CC `radians`
---@field m_brake_pressure pointer<float> // 0x1D0
---@field m_power pointer<float> // 0x1D4
---@field m_health pointer<float> // 0x1E8
---@field m_surface_id pointer<uint16_t> // 0x1EC
---@field unk_flags_1F0 pointer<uint32_t> // 0x1F0
---@overload fun(addr: pointer): CWheel|nil
local CWheel = { m_size = 0x1FC }
CWheel.__index = CWheel
CWheel.__type = "CWheel"
setmetatable(CWheel, {
	__call = function(cls, addr)
		return cls.new(addr)
	end,
})

---@return CWheel|nil
function CWheel.new(addr)
	if not addr or addr:is_null() then
		return nil
	end

	local instance                    = setmetatable({}, CWheel)
	instance.m_ptr                    = addr
	instance.m_y_rotation             = addr:add(0x008)
	instance.m_y_rotation_inv         = addr:add(0x010)
	instance.m_offset_from_body       = addr:add(0x020)
	instance.m_x_offset               = addr:add(0x030)
	instance.m_last_ground_pos        = addr:add(0x03C)
	instance.m_wheel_transform        = { addr:add(0x090), addr:add(0x0A0), addr:add(0x0B0), addr:add(0x0C0) }
	instance.m_unk_flags              = addr:add(0x0C8)
	instance.m_tire_radius            = addr:add(0x110)
	instance.m_tire_width             = addr:add(0x118)
	instance.m_suspension_compression = addr:add(0x168)
	instance.m_traction_loss          = addr:add(0x16C)
	instance.m_rotation_speed         = addr:add(0x170)
	instance.m_unk0190                = addr:add(0x190)
	instance.m_unk0194                = addr:add(0x194)
	instance.m_tire_drag_coeff        = addr:add(0x198)
	instance.m_top_speed_mult         = addr:add(0x19C)
	instance.m_steering_angle         = addr:add(0x1CC)
	instance.m_brake_pressure         = addr:add(0x1D0)
	instance.m_power                  = addr:add(0x1D4)
	instance.m_health                 = addr:add(0x1E8)
	instance.m_surface_id             = addr:add(0x1EC)
	instance.unk_flags_1F0            = addr:add(0x1F0)

	return instance
end

---@return boolean
function CWheel:IsValid()
	return self.m_ptr and self.m_ptr:is_valid()
end

---@return integer
function CWheel:GetAddress()
	return self:IsValid() and self.m_ptr:get_address() or 0x0
end

---@return vec3 -- The world position of the wheel or a zero vector if the wheel is invalid.
function CWheel:GetWorldPosition()
	if not self:IsValid() then
		return vec3:zero()
	end

	return self.m_last_ground_pos:get_vec3()
end

-- test
---@return vec3
function CWheel:GetTransformRight()
	return self.m_wheel_transform[1]:get_vec3()
end

-- test
---@return vec3
function CWheel:GetTransformFwd()
	return self.m_wheel_transform[2]:get_vec3()
end

-- test
---@return vec3
function CWheel:GetTransformUp()
	return self.m_wheel_transform[3]:get_vec3()
end

-- test
---@return vec3
function CWheel:GetTransformPos()
	return self.m_wheel_transform[4]:get_vec3()
end

-- test
---@return float
function CWheel:GetTiltAngle()
	if not self:IsValid() then
		return 0.0
	end

	local up = self:GetTransformUp()
	local world_up = vec3:new(0, 0, 1)

	local dot = up:dot_product(world_up)
	local mag = up:length()

	if (mag == 0) then
		return 0.0
	end

	return math.deg(math.acos(dot / mag))
end

return CWheel
