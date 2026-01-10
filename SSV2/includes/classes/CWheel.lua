---@diagnostic disable: param-type-mismatch

---@enum eWheelFlags
Enums.eWheelFlags = {
	HIT                       = 0,
	HIT_PREV                  = 1,
	ON_GAS                    = 2,
	ON_FIRE                   = 3,
	CHEAT_TC                  = 4,
	CHEAT_SC                  = 5,
	CHEAT_GRIP1               = 6,
	CHEAT_GRIP2               = 7,
	BURNOUT                   = 8,
	BURNOUT_NON_DRIVEN_WHEEL  = 9,
	INSHALLOWWATER            = 10,
	INDEEPWATER               = 11,
	TYRES_HEAT_UP             = 12,
	ABS_ACTIVE                = 13,
	ABS                       = 14,
	ABS_ALT                   = 15,
	SQUASHING_PED             = 16,
	REDUCE_GRIP               = 17,
	TELEPORTED_NO_VFX         = 18,
	RESET                     = 19,
	BROKEN_OFF                = 20,
	FULL_THROTTLE             = 21,
	SIDE_IMPACT               = 22,
	DUMMY_TRANSITION          = 23,
	DUMMY_TRANSITION_PREV     = 24,
	NO_LATERAL_SPRING         = 25,
	WITHIN_DAMAGE_REGION      = 26,
	WITHIN_HEAVYDAMAGE_REGION = 27,
	TOUCHING_PAVEMENT         = 28,
	DUMMY                     = 29,
	FORCE_NO_SLEEP            = 30,
	SLEEPING_ON_DEBRIS        = 31
}

---@enum eWheelConfigFlags
Enums.eWheelConfigFlags = {
	BIKE_WHEEL                   = 0,
	LEFTWHEEL                    = 1,
	REARWHEEL                    = 2,
	STEER                        = 3,
	POWERED                      = 4,
	TILT_INDEP                   = 5,
	TILT_SOLID                   = 6,
	BIKE_CONSTRAINED_COLLIDER    = 7,
	BIKE_FALLEN_COLLIDER         = 8,
	INSTANCED                    = 9,
	DONT_RENDER_STEER            = 10,
	UPDATE_SUSPENSION            = 11,
	QUAD_WHEEL                   = 12,
	HIGH_FRICTION_WHEEL          = 13,
	DONT_REDUCE_GRIP_ON_BURNOUT  = 14,
	IS_PHYSICAL                  = 15,
	BICYCLE_WHEEL                = 16,
	TRACKED_WHEEL                = 17,
	PLANE_WHEEL                  = 18,
	DONT_RENDER_HUB              = 19,
	SPOILER                      = 20, -- vehicle has a spoiler mod (increased grip)
	ROTATE_BOUNDS                = 21,
	EXTEND_ON_UPDATE_SUSPENSION  = 22, -- force wheels to extend on suspension update
	CENTRE_WHEEL                 = 23, -- for three wheeled cars
	AMPHIBIOUS_WHEEL             = 24,
	RENDER_WITH_ZERO_COMPRESSION = 25
}

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
---@field m_suspension_compression pointer<float> // 0x164 `radians`
---@field m_suspension_compression_2 pointer<float> // 0x168 `radians`
---@field m_wheel_compression pointer<float> // 0x16C
---@field m_rotation_speed pointer // 0x170
---@field m_unk0190 pointer // ?? 0x190
---@field m_unk0194 pointer // ?? 0x194
---@field m_tire_drag_coeff pointer<float> // 0x198
---@field m_top_speed_mult pointer<float> // 0x19C
---@field m_steering_angle pointer<float> // 0x1CC `radians`
---@field m_brake_force pointer<float> // 0x1D0
---@field m_drive_force pointer<float> // 0x1D4
---@field m_suspension_health pointer<float> // 0x1E8 // 100.0f: car gets slammed (old method of shooting your suspension to stance your car) // 0.0f: wheel should fall off but doesn't. Something else must be set to trigger wheel detachment
---@field m_tyre_health pointer<float> // 0x1EC // <= 500.0f: flat tyre // 0.0f: no tyre
---@field m_tyre_wear_mult pointer<float> // 0x1F0 // 0.0f: tyres won't burst from long burnout
---@field m_tyre_wear_unk pointer<float> // 0x1F8 // similar?
---@field m_wheel_flags pointer<eWheelFlags> // 0x200
---@field m_wheel_config_flags pointer<eWheelConfigFlags> // 0x204
---@field m_unk_u16 pointer<uint16_t> // 0x208
---@field m_unk_u8 pointer<uint8_t> // 0x20A
---@field m_tyre_is_burst pointer<bool> // 0x20B
---@field m_unk_byte pointer<byte> // 0x20C
---@field m_has_hydraulics pointer<bool> // 0x20D // true for cars with DUNK mod
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

	local instance                       = setmetatable({}, CWheel)
	instance.m_ptr                       = addr
	instance.m_y_rotation                = addr:add(0x008)
	instance.m_y_rotation_inv            = addr:add(0x010)
	instance.m_offset_from_body          = addr:add(0x020)
	instance.m_x_offset                  = addr:add(0x030)
	instance.m_last_ground_pos           = addr:add(0x03C)
	instance.m_wheel_transform           = { addr:add(0x090), addr:add(0x0A0), addr:add(0x0B0), addr:add(0x0C0) }
	instance.m_unk_flags                 = addr:add(0x0C8)
	instance.m_tyre_radius               = addr:add(0x0F4)
	instance.m_rim_radius                = addr:add(0x0F6)
	instance.m_old_rim_radius            = addr:add(0x0FA)
	instance.m_tyre_width                = addr:add(0x0FE)
	instance.m_handling_data             = addr:add(0x102)
	instance.m_vehicle                   = addr:add(0x106)
	instance.m_suspension_length         = addr:add(0x110)
	instance.m_max_suspension_travel     = addr:add(0x114)
	instance.m_suspension_forward_offset = addr:add(0x13C)
	instance.m_suspension_compression_2  = addr:add(0x168)
	instance.m_wheel_compression         = addr:add(0x16C)
	instance.m_rotation_speed            = addr:add(0x170)
	instance.m_unk0190                   = addr:add(0x190)
	instance.m_unk0194                   = addr:add(0x194)
	instance.m_tire_drag_coeff           = addr:add(0x198)
	instance.m_top_speed_mult            = addr:add(0x19C)
	instance.m_steering_angle            = addr:add(0x1CC)
	instance.m_brake_force               = addr:add(0x1D0)
	instance.m_drive_force               = addr:add(0x1D4)
	instance.m_suspension_health         = addr:add(0x1E8)
	instance.m_tyre_health               = addr:add(0x1EC)
	instance.m_tyre_wear_mult            = addr:add(0x1F0)
	instance.m_tyre_wear_unk             = addr:add(0x1F8)
	instance.m_wheel_flags               = addr:add(0x200)
	instance.m_wheel_config_flags        = addr:add(0x204)
	instance.m_unk_u16                   = addr:add(0x208)
	instance.m_unk_u8                    = addr:add(0x20A)
	instance.m_tyre_is_burst             = addr:add(0x20B)
	instance.m_unk_byte                  = addr:add(0x20C)
	instance.m_has_hydraulics            = addr:add(0x20D)

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

---@param flag eWheelFlags
---@return boolean
function CWheel:GetWheelFlag(flag)
	if (not self:IsValid()) then
		return false
	end

	return Bit.is_set(self.m_wheel_flags:get_dword(), flag)
end

---@param flag eWheelConfigFlags
---@return boolean
function CWheel:GetConfigFlag(flag)
	if (not self:IsValid()) then
		return false
	end

	return Bit.is_set(self.m_wheel_config_flags:get_dword(), flag)
end

---@param flag eWheelFlags
---@param toggle boolean
function CWheel:SetWheelFlag(flag, toggle)
	if (not self:IsValid()) then
		return
	end

	local dwFlags = self.m_wheel_flags:get_dword()
	local bitFunc = toggle and Bit.set or Bit.clear
	self.m_wheel_flags:set_dword(bitFunc(dwFlags, flag))
end

---@param flag eWheelConfigFlags
---@param toggle boolean
function CWheel:SetConfigFlag(flag, toggle)
	if (not self:IsValid()) then
		return
	end

	local dwFlags = self.m_wheel_config_flags:get_dword()
	local bitFunc = toggle and Bit.set or Bit.clear
	self.m_wheel_config_flags:set_dword(bitFunc(dwFlags, flag))
end

return CWheel
