-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")


local COL_FG <const>      = Color.WHITE
local COL_BG <const>      = Color(0, 0, 0, 158)
local COL_GREEN <const>   = Color(111, 194, 118, 255)
local eLaunchMode <const> = {
	REALISTIC = 0,
	RIDICULOUS = 1
}


---@enum eLaunchControlState
local eLaunchControlState <const> = {
	NONE     = 1,
	LOADING  = 2,
	READY    = 3,
	RUNNING  = 4,
	CANCELED = 5
}

---@return boolean
local function is_control_released_2(action)
	return (PAD.IS_CONTROL_RELEASED(0, action) or PAD.IS_DISABLED_CONTROL_RELEASED(0, action))
end

---@class LaunchControl
---@field private m_entity PlayerVehicle
---@field private m_is_active boolean
---@field private m_thread? Thread
---@field private m_state eLaunchControlState
---@field private m_timer Timer
---@field private m_last_pop_time milliseconds
---@field private m_default_pops_off boolean
---@field private m_shocking_event_handle? handle
---@field private m_rolling_speed_lock integer?
---@field private m_from_roll boolean
---@overload fun(pv: PlayerVehicle): LaunchControl
---@diagnostic disable-next-line
local LaunchControl = setmetatable({}, FeatureBase)
LaunchControl.__index = LaunchControl

---@param pv PlayerVehicle
function LaunchControl.new(pv)
	local self = FeatureBase.new(pv)
	---@diagnostic disable-next-line
	return setmetatable(self, LaunchControl)
end

function LaunchControl:Init()
	self.m_state = eLaunchControlState.NONE
	self.m_timer = Timer.new(2000)
	self.m_timer:Pause()
	self.m_last_pop_time = 0
	self.m_thread = ThreadManager:RegisterLooped("SS_LAUNCH_CTRL", function()
		self:OnTick()
	end)
end

function LaunchControl:ShouldRun()
	return self.m_entity
		and self.m_entity:IsValid()
		and self.m_entity:IsLandVehicle()
		and LocalPlayer:IsAlive()
		and LocalPlayer:IsDriving()
		and (not GVars.features.vehicle.performance_only or self.m_entity:IsPerformanceCar())
		and (GVars.features.vehicle.launch_control or GVars.features.vehicle.burble_tune)
end

-- function LaunchControl:OnEnable()
-- 	if (self.m_thread and not self.m_thread:IsRunning()) then
-- 		self.m_thread:Resume()
-- 	end
-- end

-- function LaunchControl:OnDisable()
-- 	if (self.m_thread and self.m_thread:IsRunning()) then
-- 		self.m_thread:Suspend()
-- 	end
-- end

function LaunchControl:Update()
	local PV = self.m_entity
	if (PV:IsElectric()) then return end

	local handle       = PV:GetHandle()
	local rpmThreshold = {
		min = GVars.features.vehicle.bangs_rpm_min / 1e4,
		max = GVars.features.vehicle.bangs_rpm_max / 1e4
	}

	if (self.m_state == eLaunchControlState.LOADING or self.m_state == eLaunchControlState.READY) then
		local bones = PV:GetExhaustBones()
		if (Time.Millis() < self.m_last_pop_time) then
			return
		end
		Game.StartSyncedPtfxNonLoopedOnEntityBone(
			handle,
			"core",
			"veh_backfire",
			bones,
			vec3:zero(),
			vec3:zero(),
			0.69420
		)

		self.m_last_pop_time = Time.Millis() + math.random(60, 120)
		Audio:PlayExhaustPop(handle, false)
	else
		if (not GVars.features.vehicle.burble_tune) then
			return
		end

		if (not self.m_default_pops_off) then
			AUDIO.ENABLE_VEHICLE_EXHAUST_POPS(handle, false)
			self.m_default_pops_off = true
		end

		if (not PV:IsMoving()) then
			rpmThreshold.min = rpmThreshold.min - 0.15
		elseif (PV:GetHandlingFlag(Enums.eVehicleHandlingFlags.FREEWHEEL_NO_GAS)) then
			rpmThreshold.min = rpmThreshold.min + 0.2
		end

		local rpm      = PV:GetRPM()
		local released = is_control_released_2(71)
		if (released and (rpm < 1.0) and math.is_inrange(rpm, rpmThreshold.min, rpmThreshold.max) and not PV:IsReversing()) then
			if (Time.Millis() < self.m_last_pop_time) then
				return
			end
			local bones = PV:GetExhaustBones()
			local pos   = PV:GetPos()

			entities.take_control_of(handle, 300)
			Game.StartSyncedPtfxNonLoopedOnEntityBone(
				handle,
				"core",
				"veh_backfire",
				bones,
				vec3:zero(),
				vec3:zero(),
				1.4
			)

			Audio:PlayExhaustPop(handle, true)

			if (not self.m_shocking_event_handle and not EVENT.IS_SHOCKING_EVENT_IN_SPHERE(79, pos.x, pos.y, pos.z, 50)) then
				self.m_shocking_event_handle = EVENT.ADD_SHOCKING_EVENT_FOR_ENTITY(79, handle, 10)
			end

			self.m_last_pop_time = Time.Millis() + math.random(60, 180)
		else
			if (self.m_shocking_event_handle) then
				EVENT.REMOVE_SHOCKING_EVENT(self.m_shocking_event_handle)
				self.m_shocking_event_handle = nil
			end
		end
	end
end

function LaunchControl:RestoreExhaustPops()
	local PV = self.m_entity
	if (not self.m_default_pops_off or not PV or not PV:IsValid()) then
		return
	end

	AUDIO.ENABLE_VEHICLE_EXHAUST_POPS(PV:GetHandle(), true)
end

---@param veh PlayerVehicle
---@param rolling boolean
function LaunchControl:Charge(veh, rolling)
	local main_color = self.m_timer:IsDone() and COL_GREEN or COL_FG
	local isMoving   = veh:IsMoving()
	local cond2      = rolling and KeyManager:IsKeybindPressed("rolling_launch") or (isMoving == false and PAD.IS_CONTROL_PRESSED(0, 72))
	if (PAD.IS_CONTROL_PRESSED(0, 71) and cond2 and not veh:IsDriftButtonPressed()) then
		if (veh:GetEngineHealth() <= 400) then
			Notifier:ShowWarning("Samurai's Scripts", _T("VEH_LAUNCH_CTRL_ERR"), false, 5)
			sleep(5000)
			return
		end

		self.m_timer:Resume()
		self.m_state = eLaunchControlState.LOADING
		if (not rolling) then
			veh:Freeze()
		else
			if (not self.m_rolling_speed_lock) then
				self.m_rolling_speed_lock = veh:GetSpeed()
			else
				local transmission = veh:Resolve().m_transmission
				VEHICLE.SET_VEHICLE_MAX_SPEED(veh:GetHandle(), self.m_rolling_speed_lock)
				transmission.m_throttle:set_float(0.45)
				transmission.m_throttle_input:set_float(0.45)
				transmission.m_rpm:set_float(0.45)
				transmission.m_rpm_2:set_float(0.45)
			end
		end

		local text = rolling and "Anti Lag" or "Launch Control"
		Game.DrawText(
			vec2:new(0.5, 0.9105),
			text,
			main_color,
			vec2:new(0, 0.35),
			2,
			true
		)

		Game.DrawProgressBar(
			vec2:new(0.5, 0.9501),
			0.1,
			0.01,
			main_color,
			COL_BG,
			math.min(1, math.max(0, self.m_timer:Elapsed() / 2000))
		)

		if (self.m_timer:IsDone() and self.m_state == eLaunchControlState.LOADING) then
			self.m_state     = eLaunchControlState.READY
			self.m_from_roll = self.m_from_roll or rolling
			self.m_timer:Pause()
		end
	elseif (self.m_state ~= eLaunchControlState.NONE and self.m_state ~= eLaunchControlState.READY) then
		if (PAD.IS_CONTROL_RELEASED(0, 71) or not cond2 or not self:ShouldRun()) then
			main_color = COL_FG
			if (not rolling) then
				veh:Unfreeze()
			else
				self.m_rolling_speed_lock = nil
				VEHICLE.SET_VEHICLE_MAX_SPEED(veh:GetHandle(), -1)
			end
			self.m_timer:Reset()
			self.m_timer:Pause()
			self.m_from_roll = false
			self.m_state     = eLaunchControlState.CANCELED
		end
	end
end

function LaunchControl:OnTick()
	local PV = self.m_entity
	if (not PV or not PV:IsValid() or not GVars.features.vehicle.launch_control) then
		yield()
		return
	end

	if (GVars.features.vehicle.performance_only and not self.m_entity:IsPerformanceCar()) then
		yield()
		return
	end

	if (not LocalPlayer:IsDriving()) then
		yield()
		return
	end

	if (self.m_state == eLaunchControlState.NONE) then
		yield()
	end

	if (self.m_state == eLaunchControlState.CANCELED) then
		sleep(2000)
		self.m_state = eLaunchControlState.NONE
	end

	local handle = PV:GetHandle()
	if (not self.m_timer) then
		self.m_timer = Timer.new(2000, true)
	end

	local fwd_speed = PV:GetSpeedVector().y
	local rolling   = PV:IsCar() and math.is_inrange(fwd_speed, 8, PV:GetMaxSpeed())
	if (PV:IsEngineOn()) then
		self:Charge(PV, rolling)
	end

	if (self.m_state == eLaunchControlState.READY) then
		if (PAD.IS_CONTROL_PRESSED(0, 71) and PAD.IS_CONTROL_RELEASED(0, 72) and not KeyManager:IsKeyPressed(eVirtualKeyCodes.N)) then
			local realistic  = GVars.features.vehicle.launch_control_mode == eLaunchMode.REALISTIC
			local max_speed  = realistic and PV:GetDefaultMaxSpeed() - 1 or PV:GetMaxSpeed() - 1
			local max_force  = realistic and 2000 or 5000
			local max_push   = realistic and max_speed * 0.55 or max_speed
			local start_time = Game.GetGameTimer()
			local end_time   = start_time + 1200

			if (self.m_from_roll) then
				max_push = math.min(PV:GetMaxSpeed(), PV:GetSpeed() + 15)
			end

			PHYSICS.SET_IN_ARENA_MODE(true)
			VEHICLE.SET_VEHICLE_MAX_LAUNCH_ENGINE_REVS_(handle, 0)
			PV:Unfreeze()
			self.m_rolling_speed_lock = nil
			VEHICLE.SET_VEHICLE_MAX_SPEED(handle, -1)
			self.m_state = eLaunchControlState.RUNNING

			while (PAD.IS_CONTROL_PRESSED(0, 71) and PV:GetSpeed() < max_push) do
				if (not self.m_from_roll) then
					local now   = Game.GetGameTimer()
					local t     = math.min(1.0, (now - start_time) / (end_time - start_time))
					local power = math.lerp(0.0, max_force, t)
					ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(
						handle,
						1,
						0.0,
						power,
						0.0,
						false,
						true,
						false,
						false
					)
				else
					VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(handle, 10)
				end

				yield()
			end

			VEHICLE.SET_VEHICLE_MAX_LAUNCH_ENGINE_REVS_(handle, 1.0)
			PHYSICS.SET_IN_ARENA_MODE(false)
			self.m_state     = eLaunchControlState.NONE
			self.m_from_roll = false
			self.m_timer:Reset()
			self.m_timer:Pause()
		end
	end
end

return LaunchControl
