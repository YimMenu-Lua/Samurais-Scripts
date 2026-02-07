-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")

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

---@class LaunchControlMgr
---@field private m_entity PlayerVehicle
---@field private m_is_active boolean
---@field private m_thread? Thread
---@field private m_state eLaunchControlState
---@field private m_timer Timer
---@field private m_last_pop_time milliseconds
---@field private m_default_pops_off boolean
---@field private m_shocking_event_handle? handle
---@overload fun(pv: PlayerVehicle): LaunchControlMgr
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
	self.m_timer:pause()
	self.m_last_pop_time = 0
	self.m_thread = ThreadManager:RegisterLooped("SS_LAUNCH_CTRL", function()
		self:OnTick()
	end)
end

function LaunchControl:ShouldRun()
	return self.m_entity
		and self.m_entity:IsValid()
		and self.m_entity:IsCar()
		and Self:IsAlive()
		and Self:IsDriving()
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
	if (PV:IsElectric()) then
		return
	end

	local handle = PV:GetHandle()
	local rpmThreshold = {
		min = GVars.features.vehicle.bangs_rpm_min / 1e4,
		max = GVars.features.vehicle.bangs_rpm_max / 1e4
	}

	if (self.m_state == eLaunchControlState.LOADING or self.m_state == eLaunchControlState.READY) then
		local bones = PV:GetExhaustBones()
		if (Time.millis() < self.m_last_pop_time) then
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

		self.m_last_pop_time = Time.millis() + math.random(60, 120)
		Audio:PlayExhaustPop(handle, false)
	else
		if (not GVars.features.vehicle.burble_tune) then
			return
		end

		if (not self.m_default_pops_off) then
			AUDIO.ENABLE_VEHICLE_EXHAUST_POPS(handle, false)
			self.m_default_pops_off = true
		end

		local gear = PV:GetCurrentGear()
		if (gear == 0) then
			return
		end

		if (not PV:IsMoving()) then
			rpmThreshold.min = rpmThreshold.min - 0.15
		elseif (PV:GetHandlingFlag(Enums.eVehicleHandlingFlags.FREEWHEEL_NO_GAS)) then
			rpmThreshold.min = rpmThreshold.min + 0.2
		end

		local rpm = PV:GetRPM()

		if (PAD.IS_CONTROL_RELEASED(0, 71) and (rpm < 1.0) and math.is_inrange(rpm, rpmThreshold.min, rpmThreshold.max) and (gear ~= 0)) then
			if (Time.millis() < self.m_last_pop_time) then
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

			self.m_last_pop_time = Time.millis() + math.random(60, 180)
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

function LaunchControl:OnTick()
	local PV = self.m_entity
	if (not PV or not PV:IsValid() or not GVars.features.vehicle.launch_control) then
		sleep(250)
		return
	end

	if (GVars.features.vehicle.performance_only and not self.m_entity:IsPerformanceCar()) then
		sleep(250)
		return
	end

	if (not Self:IsDriving()) then
		sleep(250)
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
	local r, g, b, a = 255, 255, 255, 255

	if (not self.m_timer) then
		self.m_timer = Timer.new(2000)
		self.m_timer:pause()
	end

	if (not PV:IsMoving() and PV:IsEngineOn()) then
		if (PAD.IS_CONTROL_PRESSED(0, 71) and PAD.IS_CONTROL_PRESSED(0, 72) and not PV:IsDriftButtonPressed()) then
			if (PV:GetEngineHealth() <= 400) then
				Notifier:ShowWarning("Samurai's Scripts", _T("VEH_LAUNCH_CTRL_ERR"), false, 5)
				sleep(5000)
				return
			end

			self.m_timer:resume()
			self.m_state = eLaunchControlState.LOADING
			PV:Freeze()

			if (self.m_timer:is_done()) then
				r, g, b, a = 111, 194, 118, 255
			end

			Game.DrawText(
				vec2:new(0.42, 0.936),
				_T("VEH_LAUNCH_CTRL"),
				Color(r, g, b, a),
				vec2:new(0, 0.35),
				2
			)

			Game.DrawProgressBar(
				vec2:new(0.53, 0.95),
				0.1,
				0.01,
				Color(r, g, b, a),
				Color(0, 0, 0, 150),
				math.min(1, math.max(0, self.m_timer:elapsed() / 2000))
			)

			if (self.m_timer:is_done() and self.m_state == eLaunchControlState.LOADING) then
				self.m_state = eLaunchControlState.READY
				self.m_timer:pause()
			end
		elseif (self.m_state ~= eLaunchControlState.NONE and self.m_state ~= eLaunchControlState.READY) then
			if (PAD.IS_CONTROL_RELEASED(0, 71) or PAD.IS_CONTROL_RELEASED(0, 72) or not self:ShouldRun()) then
				r, g, b, a = 255, 255, 255, 255
				PV:Unfreeze()
				self.m_timer:reset()
				self.m_timer:pause()
				self.m_state = eLaunchControlState.CANCELED
			end
		end
	end

	if (self.m_state == eLaunchControlState.READY) then
		if (PAD.IS_CONTROL_PRESSED(0, 71) and PAD.IS_CONTROL_RELEASED(0, 72)) then
			local realistic  = GVars.features.vehicle.launch_control_mode == eLaunchMode.REALISTIC
			local max_speed  = realistic and PV:GetDefaultMaxSpeed() - 1 or PV:GetMaxSpeed() - 1
			local max_force  = realistic and 2000 or 5000
			local max_push   = realistic and max_speed * 0.55 or max_speed
			local start_time = Game.GetGameTimer()
			local end_time   = start_time + 1200

			PHYSICS.SET_IN_ARENA_MODE(true)
			VEHICLE.SET_VEHICLE_MAX_LAUNCH_ENGINE_REVS_(handle, 0)
			PV:Unfreeze()
			self.m_state = eLaunchControlState.RUNNING

			while (PAD.IS_CONTROL_PRESSED(0, 71) and PV:GetSpeed() < max_push) do
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

				yield()
			end

			VEHICLE.SET_VEHICLE_MAX_LAUNCH_ENGINE_REVS_(handle, 1.0)
			PHYSICS.SET_IN_ARENA_MODE(false)
			self.m_state = eLaunchControlState.NONE
			self.m_timer:reset()
			self.m_timer:pause()
		end
	end
end

return LaunchControl
