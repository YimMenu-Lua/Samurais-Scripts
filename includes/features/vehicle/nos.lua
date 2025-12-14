---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local FeatureBase = require("includes.modules.FeatureBase")

---@class NosMgr : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_nos_fx array<handle>|nil
---@field private m_purge_fx_l array<handle>|nil
---@field private m_purge_fx_r array<handle>|nil
---@field private m_is_active boolean
local NosMgr = setmetatable({}, FeatureBase)
NosMgr.__index = NosMgr

---@param pv PlayerVehicle
---@return NosMgr
function NosMgr.new(pv)
	local self = FeatureBase.new(pv)
	return setmetatable(self, NosMgr)
end

function NosMgr:Init()
	self.m_is_active = false
end

function NosMgr:Cleanup()
	if (self.m_nos_fx) then
		Game.StopParticleEffects(self.m_nos_fx, "veh_xs_vehicle_mods")
		self.m_nos_fx = nil
	end

	if (self.m_purge_fx_l) then
		Game.StopParticleEffects(self.m_purge_fx_l)
		self.m_purge_fx_l = nil
	end

	if (self.m_purge_fx_r) then
		Game.StopParticleEffects(self.m_purge_fx_r)
		self.m_purge_fx_r = nil
	end
end

function NosMgr:ShouldRun()
	return (self.m_entity
		and self.m_entity:IsValid()
		and self.m_entity:IsLandVehicle()
		and self.m_entity:IsEngineOn()
		and Self:IsDriving()
		and not self.m_entity:IsElectric())
end

---@return boolean
function NosMgr:IsActive()
	return self.m_is_active
end

---@return boolean
function NosMgr:IsNOSButtonPressed()
	return KeyManager:IsFeatureButtonPressed(
		GVars.keyboard_keybinds.nos,
		GVars.gamepad_keybinds.nos
	)
end

---@return boolean
function NosMgr:IsPurgeButtonPressed()
	return KeyManager:IsFeatureButtonPressed(
		GVars.keyboard_keybinds.nos_purge,
		GVars.gamepad_keybinds.nos_purge
	)
end

function NosMgr:UpdateFX()
	local PV = self.m_entity
	if (PV:IsElectric()) then
		return
	end

	if (self.m_is_active and PV:IsEngineOn()) then
		if (not self.m_nos_fx) then
			local bones = PV:GetExhaustBones()
			self.m_nos_fx = Game.StartSyncedPtfxLoopedOnEntityBone(
				PV:GetHandle(),
				"veh_xs_vehicle_mods",
				"veh_nitrous",
				bones,
				1.0,
				vec3:zero(),
				vec3:zero()
			)
		end
	elseif (self.m_nos_fx) then
		Game.StopParticleEffects(self.m_nos_fx, "veh_xs_vehicle_mods")
		self.m_nos_fx = nil
	end
end

function NosMgr:UpdatePurgeFX()
	local PV = self.m_entity
	if (PV:IsBoat() or PV:IsElectric()) then
		return
	end

	local handle = PV:GetHandle()
	if (self:IsPurgeButtonPressed() and PV:IsEngineOn()) then
		if (not self.m_purge_fx_l) then
			self.m_purge_fx_l = Game.StartSyncedPtfxLoopedOnEntityBone(
				handle,
				"core",
				"weap_extinguisher",
				"suspension_lf",
				0.35,
				vec3:new(-0.3, -0.33, 0.2),
				vec3:new(0.0, -17.5, -180.0)
			)
		end

		if (not self.m_purge_fx_r) then
			self.m_purge_fx_r = Game.StartSyncedPtfxLoopedOnEntityBone(
				handle,
				"core",
				"weap_extinguisher",
				"suspension_rf",
				0.35,
				vec3:new(0.0, -0.33, 0.2),
				vec3:new(0.0, -17.5, 0.0)
			)
		end
	else
		if (self.m_purge_fx_l) then
			Game.StopParticleEffects(self.m_purge_fx_l)
			self.m_purge_fx_l = nil
		end

		if (self.m_purge_fx_r) then
			Game.StopParticleEffects(self.m_purge_fx_r)
			self.m_purge_fx_r = nil
		end
	end
end

function NosMgr:Update()
	local PV = self.m_entity
	if (GVars.features.vehicle.nos.enabled) then
		local handle = PV:GetHandle()
		local buttonPressed = self:IsNOSButtonPressed()

		if (buttonPressed and PAD.IS_CONTROL_PRESSED(0, 71)) then
			VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(handle, GVars.features.vehicle.nos.power / 5)
			VEHICLE.MODIFY_VEHICLE_TOP_SPEED(handle, GVars.features.vehicle.nos.power)
			if (GVars.features.vehicle.nos.sound_effect) then
				AUDIO.SET_VEHICLE_BOOST_ACTIVE(handle, true)
			end

			if (GVars.features.vehicle.nos.screen_effect) then
				GRAPHICS.ANIMPOSTFX_PLAY("DragRaceNitrous", 0, false)
			end

			self.m_is_active = true
		end

		if (self.m_is_active and not buttonPressed) then
			VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(handle, 1.0)
			VEHICLE.MODIFY_VEHICLE_TOP_SPEED(handle, -1)
			AUDIO.SET_VEHICLE_BOOST_ACTIVE(handle, false)

			if (GVars.features.vehicle.nos.screen_effect) then
				GRAPHICS.ANIMPOSTFX_PLAY("DragRaceNitrousOut", 0, false)
			end

			if (GRAPHICS.ANIMPOSTFX_IS_RUNNING("DragRaceNitrous")) then
				GRAPHICS.ANIMPOSTFX_STOP("DragRaceNitrous")
			end

			if (GRAPHICS.ANIMPOSTFX_IS_RUNNING("DragRaceNitrousOut")) then
				GRAPHICS.ANIMPOSTFX_STOP("DragRaceNitrousOut")
			end

			self.m_is_active = false
		end

		self:UpdateFX()
	end

	if (GVars.features.vehicle.nos.purge) then
		self:UpdatePurgeFX()
	end
end

return NosMgr
