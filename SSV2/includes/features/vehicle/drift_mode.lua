---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local FeatureBase = require("includes.modules.FeatureBase")
local CWheel      = require("includes.classes.CWheel")

---@class DriftMode : FeatureBase
---@field private m_entity PlayerVehicle -- Reference to PlayerVehicle
---@field private m_smoke_fx array<handle>|nil
---@field private m_is_active boolean
---@overload fun(pv: PlayerVehicle): DriftMode
local DriftMode   = setmetatable({}, FeatureBase)
DriftMode.__index = DriftMode
DriftMode.fxBones = { "suspension_lr", "suspension_rr" }

---@param pv PlayerVehicle
---@return DriftMode
function DriftMode.new(pv)
	local self = FeatureBase.new(pv)
	return setmetatable(self, DriftMode)
end

function DriftMode:Init()
	self.m_is_active = false
end

function DriftMode:ShouldRun()
	return (self.m_entity
		and self.m_entity:IsValid()
		and self.m_entity:IsLandVehicle()
		and self.m_entity:IsEngineOn()
		and Self:IsDriving()
		and GVars.features.vehicle.drift.enabled)
end

---@return boolean
function DriftMode:IsActive()
	return self.m_is_active
end

function DriftMode:UpdateFX()
	if (not GVars.features.vehicle.drift.smoke_fx.enabled or not self.m_entity:IsCar()) then
		return
	end

	local PV          = self.m_entity
	local vmin, vmax  = PV:GetModelDimensions()
	local height      = vmax.z - vmin.z
	local boneZoffset = height / 4
	local handle      = PV:GetHandle()
	local col         = GVars.features.vehicle.drift.smoke_fx.color
	local r           = math.min(col.x * 255, 255)
	local g           = math.min(col.y * 255, 255)
	local b           = math.min(col.z * 255, 255)

	if (PV:IsMoving()) then
		local speed = PV:GetSpeed()
		if (PV:IsDrifting() and PV:GetCurrentGear() > 0 and speed > 5) then
			local fxScale = speed / 111

			if (not self.m_entity.m_default_tire_smoke.enabled) then
				VEHICLE.TOGGLE_VEHICLE_MOD(handle, 20, true)
			end

			if (not self.m_smoke_fx and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(handle)) then
				self.m_smoke_fx = Game.StartSyncedPtfxLoopedOnEntityBone(
					handle,
					"scr_ba_bb",
					"scr_ba_bb_plane_smoke_trail",
					self.fxBones,
					fxScale,
					vec3:new(1.2, 0.0, -boneZoffset),
					vec3:zero(),
					Color(r, g, b)
				)
			end
		elseif (self.m_smoke_fx) then
			Game.StopParticleEffects(self.m_smoke_fx, "scr_ba_bb")
			self.m_smoke_fx = nil
		end
	elseif (PV:GetRPM() >= 0.9) then
		if (VEHICLE.IS_VEHICLE_IN_BURNOUT(handle)) then
			if (not self.m_entity.m_default_tire_smoke.enabled) then
				VEHICLE.TOGGLE_VEHICLE_MOD(handle, 20, true)
			end

			if not self.m_smoke_fx then
				self.m_smoke_fx = Game.StartSyncedPtfxLoopedOnEntityBone(
					handle,
					"scr_ba_bb",
					"scr_ba_bb_plane_smoke_trail",
					self.fxBones,
					0.4,
					vec3:new(1.2, 0.0, -boneZoffset),
					vec3:zero(),
					Color(r, g, b)
				)
			end
		elseif self.m_smoke_fx then
			Game.StopParticleEffects(self.m_smoke_fx, "scr_ba_bb")
			self.m_smoke_fx = nil
		end
	end

	if (self.m_smoke_fx and #self.m_smoke_fx > 0) then
		for _, fx in ipairs(self.m_smoke_fx) do
			GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(fx, r, g, b, false)
		end
	end
end

-- local debug_txt_scale = vec2:new(0.3, 0.3)
-- local debug_white = Color(225, 225, 225, 255)
-- function DriftMode:DrawDebugHUD()
-- 	local PV = self.m_entity
-- 	if (not PV:IsValid()) then
-- 		return
-- 	end

-- 	local speed_vec   = PV:GetSpeedVector()
-- 	local lateral_vel = speed_vec.x
-- 	local forward_vel = speed_vec.y
-- 	local absolute_x  = math.abs(lateral_vel)
-- 	local absolute_y  = math.abs(speed_vec.y)
-- 	local delta_x     = 0 + absolute_x
-- 	local delta_y     = 0 + absolute_y
-- 	local angle_rad   = math.atan(delta_y, delta_x)
-- 	local angle_deg   = math.deg(angle_rad)
-- 	local wheels      = PV:Resolve().m_wheels

-- 	Game.DrawText(
-- 		vec2:new(0.8, 0.35),
-- 		_F("Raw Lateral Velocity: %.3f", lateral_vel),
-- 		debug_white,
-- 		debug_txt_scale,
-- 		4
-- 	)
-- 	Game.DrawText(
-- 		vec2:new(0.8, 0.37),
-- 		_F("Angle: %.0f°", angle_deg),
-- 		debug_white,
-- 		debug_txt_scale,
-- 		4
-- 	)

-- 	Game.DrawText(
-- 		vec2:new(0.8, 0.39),
-- 		_F("Forward Velocity: %.3f", forward_vel),
-- 		debug_white,
-- 		debug_txt_scale,
-- 		4
-- 	)

-- 	for i, wheel in wheels:Iter() do
-- 		local cwheel = CWheel(wheel)
-- 		if (not cwheel) then
-- 			goto continue
-- 		end

-- 		local wheel_pwr       = cwheel.m_drive_force:get_float()
-- 		local brk_pwr         = cwheel.m_brake_force:get_float()
-- 		local drag_co         = cwheel.m_tire_drag_coeff:get_float()
-- 		local rot_spd         = cwheel.m_rotation_speed:get_float()
-- 		local top_spd_mult    = cwheel.m_top_speed_mult:get_float()
-- 		local is_full_thottle = cwheel:GetWheelFlag(Enums.eWheelFlags.FULL_THROTTLE)
-- 		local is_cheat_tc     = cwheel:GetWheelFlag(Enums.eWheelFlags.CHEAT_TC)
-- 		local is_cheat_sc     = cwheel:GetWheelFlag(Enums.eWheelFlags.CHEAT_SC)
-- 		local is_driven       = cwheel:GetConfigFlag(Enums.eWheelConfigFlags.POWERED)
-- 		local wheel_txt       = _F(
-- 			"- %d: Power: %.3f | Brake: %.3f | Drag: %.3f | Rotation: %.3f | Speed Mult: %.3f",
-- 			i,
-- 			wheel_pwr,
-- 			brk_pwr,
-- 			drag_co,
-- 			rot_spd,
-- 			top_spd_mult
-- 		)

-- 		Game.DrawText(
-- 			vec2:new(0.7, 0.4 + (i * 0.02)),
-- 			wheel_txt,
-- 			debug_white,
-- 			debug_txt_scale,
-- 			4
-- 		)

-- 		::continue::
-- 	end

-- 	if (angle_deg <= 88 and PAD.IS_CONTROL_PRESSED(0, 71)) then
-- 		VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(PV:GetHandle(), 10.0)
-- 	end
-- end

function DriftMode:UpdateArcadeStyle()
	local PV = self.m_entity
	local handle = PV:GetHandle()

	if (PV:IsDriftButtonPressed()) then
		local mode = GVars.features.vehicle.drift.mode
		local intensty = GVars.features.vehicle.drift.intensity
		local powerIncrease = GVars.features.vehicle.drift.power

		if (not self.m_is_active) then
			if (mode == 0 or mode == 2) then
				VEHICLE.SET_VEHICLE_REDUCE_GRIP(handle, true)
				VEHICLE.SET_VEHICLE_REDUCE_GRIP_LEVEL(handle, intensty)
			end

			if (mode >= 1) then
				VEHICLE.SET_DRIFT_TYRES(handle, true)
			end
		end

		VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(handle, powerIncrease)
		self.m_is_active = true
	elseif (self.m_is_active) then
		VEHICLE.SET_VEHICLE_REDUCE_GRIP(handle, false)
		VEHICLE.SET_DRIFT_TYRES(handle, false)
		VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(handle, 1.0)
		self.m_is_active = false
	end
end

function DriftMode:Update()
	if (GVars.features.vehicle.drift.mode < 3) then
		self:UpdateArcadeStyle()
	end

	self:UpdateFX()

	-- if (Backend.debug_mode) then
	-- 	self:DrawDebugHUD()
	-- end
end

return DriftMode
