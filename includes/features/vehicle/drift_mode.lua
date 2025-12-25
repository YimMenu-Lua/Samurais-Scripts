---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local FeatureBase = require("includes.modules.FeatureBase")

---@class DriftMode : FeatureBase
---@field private m_entity PlayerVehicle -- Reference to PlayerVehicle
---@field private m_smoke_fx array<handle>|nil
---@field private m_is_active boolean
---@overload fun(pv: PlayerVehicle): DriftMode
local DriftMode = setmetatable({}, FeatureBase)
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
	if (not GVars.features.vehicle.drift.smoke_fx.enabled) then
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
		elseif self.m_smoke_fx then
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
			GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(fx, col.x, col.y, col.z, false)
		end
	end
end

function DriftMode:Update()
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

	self:UpdateFX()
end

return DriftMode
