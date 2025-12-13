---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local VehicleFeatureBase = require("VehicleFeatureBase")

---@enum eLaunchControlState
local eLaunchControlState <const> = {
	NONE     = 1,
	LOADING  = 2,
	READY    = 3,
	RUNNING  = 4,
	CANCELED = 5
}

---@class LaunchControlMgr
---@field private m_pv PlayerVehicle -- Reference to PlayerVehicle
---@field private m_is_active boolean
---@field private m_thread Thread
---@field private m_state eLaunchControlState
---@field private m_timer Time.Timer
---@field private m_last_pop_time milliseconds
---@field private m_default_pops_off boolean
---@field private m_shocking_event_handle? handle
---@overload fun(pv: PlayerVehicle): LaunchControlMgr
local LaunchControl = setmetatable({}, VehicleFeatureBase)
LaunchControl.__index = LaunchControl

---@param pv PlayerVehicle
function LaunchControl.new(pv)
	local self = VehicleFeatureBase.new(pv)
	return setmetatable(self, LaunchControl)
end

function LaunchControl:Init()
	self.m_state = eLaunchControlState.NONE
	self.m_timer = Timer.new(3000)
	self.m_timer:pause()
	self.m_last_pop_time = 0
	self.m_thread = ThreadManager:CreateNewThread("SS_LAUNCH_CTRL", function()
		self:Mainthread()
	end)
end

function LaunchControl:ShouldRun()
	return self.m_pv
		and self.m_pv:IsValid()
		and self.m_pv:IsCar()
		and (not GVars.features.vehicle.performance_only or self.m_pv:IsPerformanceCar())
		and GVars.features.vehicle.launch_control
		and GVars.features.vehicle.burble_tune
		and not self.m_pv:IsElectric()
end

function LaunchControl:OnEnterVehicle()
	if (self.m_thread and not self.m_thread:IsRunning()) then
		self.m_thread:Resume()
	end
end

function LaunchControl:OnLeaveVehicle()
	if (self.m_thread and self.m_thread:IsRunning()) then
		self.m_thread:Suspend()
	end
end

function LaunchControl:Update()
	local PV = self.m_pv
	local handle = PV:GetHandle()
	local rpmThreshold

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
		Audio.PlayExhaustPop(handle, false)
	else
		if (not self.m_default_pops_off) then
			AUDIO.ENABLE_VEHICLE_EXHAUST_POPS(handle, false)
			self.m_default_pops_off = true
		end

		if (not PV:IsMoving()) then
			rpmThreshold = 0.45
		elseif (not PV:GetHandlingFlag(eVehicleHandlingFlags.FREEWHEEL_NO_GAS)) then
			rpmThreshold = 0.80
		else
			rpmThreshold = 0.69
		end

		local rpm = PV:GetRPM()
		local gear = PV:GetCurrentGear()

		if (PAD.IS_CONTROL_RELEASED(0, 71) and (rpm < 1.0) and (rpm > rpmThreshold) and (gear ~= 0)) then
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

			Audio.PlayExhaustPop(handle, true)

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
	local PV = self.m_pv
	if (not self.m_default_pops_off or not PV or not PV:IsValid()) then
		return
	end

	AUDIO.ENABLE_VEHICLE_EXHAUST_POPS(PV:GetHandle(), true)
end

function LaunchControl:Mainthread()
	local PV = self.m_pv
	if (not PV or not PV:IsValid() or not GVars.features.vehicle.launch_control) then
		sleep(250)
		return
	end

	if (not Self:IsDriving()
			or not PV:IsCar()
			or not PV:IsPerformanceCar()
			or PV:IsElectric()
		) then
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
		self.m_timer = Timer.new(3000)
		self.m_timer:pause()
	end

	if (not PV:IsMoving() and PV:IsEngineOn()) then
		if (PAD.IS_CONTROL_PRESSED(0, 71) and PAD.IS_CONTROL_PRESSED(0, 72) and not PV:IsDriftButtonPressed()) then
			if (PV:GetEngineHealth() <= 400) then
				Toast:ShowWarning("Samurai's Scripts",
					"Launch control is unavailable at the moment. Your engine is damaged.", false, 5)
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
				"Launch Control",
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
				math.min(1, math.max(0, self.m_timer:elapsed() / 3000))
			)

			if (self.m_timer:is_done() and self.m_state == eLaunchControlState.LOADING) then
				self.m_state = eLaunchControlState.READY
				self.m_timer:pause()
			end
		elseif (self.m_state ~= eLaunchControlState.NONE and self.m_state ~= eLaunchControlState.READY) then
			if (PAD.IS_CONTROL_RELEASED(0, 71) or PAD.IS_CONTROL_RELEASED(0, 72)) then
				r, g, b, a = 255, 255, 255, 255
				PV:Unfreeze()
				self.m_timer:reset()
				self.m_timer:pause()
				self.m_state = eLaunchControlState.CANCELED
			end
		end
	end

	if (self.m_state == eLaunchControlState.READY) then
		if PAD.IS_CONTROL_PRESSED(0, 71) and PAD.IS_CONTROL_RELEASED(0, 72) then
			PHYSICS.SET_IN_ARENA_MODE(true)
			VEHICLE.SET_VEHICLE_MAX_LAUNCH_ENGINE_REVS_(handle, -1)
			PV:Unfreeze()
			for i = 5, 0.1, -1 do
				VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(handle, 10)
				VEHICLE.MODIFY_VEHICLE_TOP_SPEED(handle, 100)
				VEHICLE.SET_VEHICLE_FORWARD_SPEED(handle, PV:GetSpeed() + i)
			end
			self.m_state = eLaunchControlState.RUNNING
			sleep(4269)
			VEHICLE.MODIFY_VEHICLE_TOP_SPEED(handle, -1)
			VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(handle, 1.0)
			VEHICLE.SET_VEHICLE_MAX_LAUNCH_ENGINE_REVS_(handle, 1.0)
			PHYSICS.SET_IN_ARENA_MODE(false)
			self.m_state = eLaunchControlState.NONE
			self.m_timer:reset()
			self.m_timer:pause()
		end
	end
end

return LaunchControl
