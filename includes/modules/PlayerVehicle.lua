---@diagnostic disable: param-type-mismatch

local FeatureMgr = require("includes.services.FeatureManager")
local NosMgr = require("includes.features.vehicle.nos")
local LaunchControlMgr = require("includes.features.vehicle.launch_control")
local DriftMode = require("includes.features.vehicle.drift_mode")
local HighBeams = require("includes.features.vehicle.high_beams")
local IVExit = require("includes.features.vehicle.iv_style_exit")
local RGBLights = require("includes.features.vehicle.rgb_lights")
local CarCrash = require("includes.features.vehicle.car_crashes")

-- Singleton
---@class PlayerVehicle : Vehicle
---@field private m_handle handle
---@field private m_last_model hash
---@field private m_abs_sm StateMachine
---@field private m_esc_sm StateMachine
---@field private m_flappy_doors_sm StateMachine
---@field private m_feat_mgr FeatureManager
---@field private m_nos_mgr NosMgr
---@field private m_lctrl_mgr LaunchControlMgr
---@field private m_door_lock_state integer
---@field private m_threads array<Thread>
---@field private m_default_handling_flags table<eVehicleHandlingFlags, boolean>
---@field private m_handling_flags_to_change table<string, { flag : eVehicleHandlingFlags, bikes_only : boolean }>
---@field private m_default_max_speed float
---@field private m_has_loud_radio boolean
---@field private m_default_pointers table<pointer, { set_func: fun(self: pointer, v: anyval), default_value: anyval }>
---@field public m_default_xenon_lights { enabled: boolean, index: integer }
---@overload fun(handle: handle): PlayerVehicle
local PlayerVehicle = Class("PlayerVehicle", Vehicle)
PlayerVehicle.m_handling_flags_to_change = {
	["features.vehicle.no_engine_brake"] = { flag = eVehicleHandlingFlags.FREEWHEEL_NO_GAS, bikes_only = false },
	["features.vehicle.kers_boost"] = { flag = eVehicleHandlingFlags.HAS_KERS, bikes_only = false },
	["features.vehicle.offroad_abilities"] = { flag = eVehicleHandlingFlags.OFFROAD_ABILITIES_X2, bikes_only = false },
	["features.vehicle.rallye_tyres"] = { flag = eVehicleHandlingFlags.HAS_RALLY_TYRES, bikes_only = false },
	["features.vehicle.no_traction_control"] = { flag = eVehicleHandlingFlags.FORCE_NO_TC_OR_SC, bikes_only = true },
	["features.vehicle.low_speed_wheelies"] = { flag = eVehicleHandlingFlags.LOW_SPEED_WHEELIES, bikes_only = true },
}

---@return LaunchControlMgr
function PlayerVehicle:GetLaunchControlMgr()
	return self.m_lctrl_mgr
end

function PlayerVehicle:InitFeatures()
	self.m_feat_mgr  = FeatureMgr.new(self)
	self.m_lctrl_mgr = self.m_feat_mgr:Add(LaunchControlMgr.new(self))
	self.m_nos_mgr   = self.m_feat_mgr:Add(NosMgr.new(self))

	self.m_feat_mgr:Add(DriftMode.new(self))
	self.m_feat_mgr:Add(HighBeams.new(self))
	self.m_feat_mgr:Add(IVExit.new(self))
	self.m_feat_mgr:Add(RGBLights.new(self))
	self.m_feat_mgr:Add(CarCrash.new(self))
end

---@return PlayerVehicle
function PlayerVehicle:init(handle)
	---@type PlayerVehicle
	local instance = setmetatable({
		m_is_nos_active = false,
		m_handle = handle,
		m_threads = {},
		m_default_handling_flags = {},
		m_default_pointers = {},
		m_default_xenon_lights = { enabled = false, index = 0 },
		m_default_max_speed = 0,
	}, PlayerVehicle)

	instance.m_abs_sm = StateMachine({
		predicate = function(_, veh)
			return Self:IsDriving()
				and veh:IsCar()
				and veh:HasABS()
				and (not GVars.features.vehicle.performance_only or veh:IsPerformanceCar())
				and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(veh:GetHandle())
				and PAD.IS_CONTROL_PRESSED(0, 72)
				and ((veh:GetSpeed() * 3.6) >= 70)
		end,
		interval = 0.1,
		callback = function(_, veh)
			VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(
				veh:GetHandle(),
				false
			)
		end
	})

	instance.m_esc_sm = StateMachine({
		predicate = function(_, veh)
			return Self:IsDriving()
				and veh:IsCar()
				and veh:IsDrifting()
				and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(veh:GetHandle())
		end,
		interval = 0.1
	})

	instance.m_flappy_doors_sm = StateMachine({
		predicate = function(_, veh)
			return Self:IsDriving() and veh:IsCar()
		end,
		interval = 0.6,
	})

	instance:InitFeatures()

	local main_thread = ThreadManager:CreateNewThread("SS_VEHICLE", function()
		instance:Main()
	end)

	table.insert(instance.m_threads, main_thread)
	instance:GetDefaultHandlingFlags()

	return instance
end

---@param handle handle
function PlayerVehicle:Set(handle)
	if (handle == self.m_handle) then
		return
	end

	local shouldReadFlags = false
	local new_model = ENTITY.GET_ENTITY_MODEL(handle)
	shouldReadFlags = self.m_last_model ~= new_model

	self.m_default_max_speed = VEHICLE.GET_VEHICLE_MODEL_ESTIMATED_MAX_SPEED(new_model)
	self.m_last_model = new_model
	self.m_handle = handle
	---@diagnostic disable-next-line

	if (shouldReadFlags) then
		self:GetDefaultHandlingFlags()
	end

	self.m_default_xenon_lights.enabled = VEHICLE.IS_TOGGLE_MOD_ON(handle, 22)
	self.m_default_xenon_lights.index = VEHICLE.GET_VEHICLE_XENON_LIGHT_COLOR_INDEX(handle)
	-- self:ResumeThreads()
	-- self.m_feat_mgr:OnEnable()
end

function PlayerVehicle:Reset()
	-- self.m_feat_mgr:OnDisable()
	-- self:SuspendThreads()
	self:RestoreHeadlights()
	self:RestoreExhaustPops()
	self:ResetHandlingFlags()
	self:ResetPointers()

	self.m_last_model = self:GetModelHash()
	self:Destroy()
	self.m_handle = 0
end

---@return hash
function PlayerVehicle:GetModelHash()
	return ENTITY.GET_ENTITY_MODEL(self:GetHandle())
end

function PlayerVehicle:GetDefaultMaxSpeed()
	return self.m_default_max_speed
end

---@param ptr pointer
---@param getFunc fun(self: pointer): anyval
---@param setFunc fun(self: pointer, v: anyval)
---@param value anyval
function PlayerVehicle:WriteMemory(ptr, getFunc, setFunc, value)
	if (ptr:is_null()) then
		return
	end

	if (not self.m_default_pointers[ptr]) then
		self.m_default_pointers[ptr] = { set_func = setFunc, default_value = getFunc(ptr) }
	end

	setFunc(ptr, value)
end

---@param ptr pointer
function PlayerVehicle:RestorePointer(ptr)
	local data = self.m_default_pointers[ptr]
	if (ptr:is_null() or not data) then
		return
	end

	data.set_func(ptr, data.default_value)
	self.m_default_pointers[ptr] = nil
end

function PlayerVehicle:ResetPointers()
	if (next(self.m_default_pointers) == nil) then
		return
	end

	for ptr, data in pairs(self.m_default_pointers) do
		if (ptr:is_valid() and data.default_value ~= nil and type(data.set_func) == "function") then
			data.set_func(ptr, data.default_value)
		end
	end

	self.m_default_pointers = {}
end

---@return boolean
function PlayerVehicle:IsAnyThreadRunning()
	for _, thread in ipairs(self.m_threads) do
		if (thread:IsRunning()) then
			return true
		end
	end

	return false
end

function PlayerVehicle:SuspendThreads()
	for _, thread in ipairs(self.m_threads) do
		if (thread:IsRunning()) then
			thread:Suspend()
		end
	end
end

function PlayerVehicle:ResumeThreads()
	for _, thread in ipairs(self.m_threads) do
		if (not thread:IsRunning()) then
			thread:Resume()
		end
	end
end

---@return boolean
function PlayerVehicle:IsDrivable()
	return VEHICLE.IS_VEHICLE_DRIVEABLE(self:GetHandle(), false)
end

---@return boolean
function PlayerVehicle:IsLandVehicle()
	return self:IsCar() or self:IsQuad() or self:IsBike()
end

---@return boolean
function PlayerVehicle:IsEngineOn()
	return VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(self:GetHandle())
end

---@return boolean
function PlayerVehicle:IsMoving()
	return not VEHICLE.IS_VEHICLE_STOPPED(self:GetHandle())
end

---@return boolean
function PlayerVehicle:IsDriftButtonPressed()
	return KeyManager:IsFeatureButtonPressed(
		GVars.keyboard_keybinds.drift_mode,
		GVars.gamepad_keybinds.drift_mode
	)
end

---@return boolean
function PlayerVehicle:IsDrifting()
	if (not self:IsCar()) then
		return false
	end

	local handle = self:GetHandle()
	local speed_vector = ENTITY.GET_ENTITY_SPEED_VECTOR(handle, true)
	if (speed_vector.x == 0) then
		return false
	end

	return VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(handle) and (speed_vector.x <= -6 or speed_vector.x >= 6)
end

---@return boolean
function PlayerVehicle:IsABSEngaged()
	return self.m_abs_sm:IsActive()
end

---@return boolean
function PlayerVehicle:IsESCEngaged()
	return self.m_esc_sm:IsToggled()
end

---@return boolean
function PlayerVehicle:IsNOSActive()
	return self.m_nos_mgr:IsActive()
end

---@return number
function PlayerVehicle:GetRPM()
	return VEHICLE.GET_VEHICLE_CURRENT_REV_RATIO_(self:GetHandle())
end

---@return number
function PlayerVehicle:GetThrottle()
	return VEHICLE.GET_VEHICLE_THROTTLE_(self:GetHandle())
end

---@return number
function PlayerVehicle:GetCurrentGear()
	return VEHICLE.GET_VEHICLE_CURRENT_DRIVE_GEAR_(self:GetHandle())
end

function PlayerVehicle:UpdateABS()
	if (not GVars.features.vehicle.abs_lights) then
		return
	end

	self.m_abs_sm:Update(self)
end

---@param toggle boolean
function PlayerVehicle:ToggleSubwoofer(toggle)
	AUDIO.SET_VEHICLE_RADIO_LOUD(self:GetHandle(), toggle)
	self.m_has_loud_radio = toggle
end

function PlayerVehicle:RestoreHeadlights()
	if (not self:IsValid()) then
		return
	end

	local handle = self:GetHandle()
	VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(handle, self.m_default_xenon_lights.index)
	VEHICLE.TOGGLE_VEHICLE_MOD(handle, 22, self.m_default_xenon_lights.enabled)
	VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(handle, 1.0)
end

---@return boolean
function PlayerVehicle:HasLoudRadio()
	return self.m_has_loud_radio
end

function PlayerVehicle:UpdateESC()
	if (not GVars.features.speedometer.enabled) then
		return
	end

	self.m_esc_sm:Update(self)
end

function PlayerVehicle:UpdateFlappyDoors()
	if (not GVars.features.vehicle.flappy_doors) then
		return
	end

	local handle = self:GetHandle()
	self.m_flappy_doors_sm:Update(self)
	if (not self.m_flappy_doors_sm:IsActive()) then
		return
	end

	for i = 0, VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(handle) + 1 do
		if (not VEHICLE.GET_IS_DOOR_VALID(handle, i)) then
			goto continue
		end

		local angle = VEHICLE.GET_VEHICLE_DOOR_ANGLE_RATIO(handle, i)
		if (self.m_flappy_doors_sm:IsToggled()) then
			if (angle < 1) then
				VEHICLE.SET_VEHICLE_DOOR_OPEN(handle, i, false, false)
			end
		else
			if (angle > 0) then
				VEHICLE.SET_VEHICLE_DOOR_SHUT(handle, i, false)
			end
		end

		::continue::
	end
end

function PlayerVehicle:AutolockDoors()
	if (not GVars.features.vehicle.auto_lock_doors) then
		return
	end

	local handle   = self:GetHandle()
	local vehPos   = self:GetPos()
	local distance = vehPos:distance(Self:GetPos())
	local isLocked = VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(handle) > 1

	if (not isLocked and distance > 20) then
		self:LockDoors(true)
	end

	if (isLocked and PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(Self:GetHandle()) == handle) then
		self:LockDoors(false)
	end
	self.m_door_lock_state = isLocked and 2 or 1
end

function PlayerVehicle:GetDefaultHandlingFlags()
	for _, value in pairs(eVehicleHandlingFlags) do
		self.m_default_handling_flags[value] = self:GetHandlingFlag(value)
	end
end

function PlayerVehicle:SetHandlingFlags()
	if not (self:IsCar() or self:IsBike() or self:IsQuad()) then
		return
	end

	for key, flagData in pairs(self.m_handling_flags_to_change) do
		if (flagData.bikes_only and not self:IsBike() and not self:IsQuad()) then
			goto continue
		end

		---@type boolean
		local gvar = table.get_nested_key(GVars, key)
		local current = self:GetHandlingFlag(flagData.flag)
		if (current ~= gvar) then
			self:SetHandlingFlag(flagData.flag, gvar)
		end
		::continue::
	end
end

function PlayerVehicle:ResetHandlingFlags()
	for enum, bool in pairs(self.m_default_handling_flags) do
		self:SetHandlingFlag(enum, bool)
	end
end

function PlayerVehicle:RestoreExhaustPops()
	self.m_lctrl_mgr:RestoreExhaustPops()
end

function PlayerVehicle:Main()
	if (not self:IsValid()) then
		sleep(500)
		return
	end

	local handle = self:GetHandle()

	if (GVars.features.vehicle.fast_vehicles) then
		if (self:GetMaxSpeed() <= 50) then
			VEHICLE.MODIFY_VEHICLE_TOP_SPEED(handle, 100)
		end
	elseif (self:GetMaxSpeed() >= 50) then
		VEHICLE.MODIFY_VEHICLE_TOP_SPEED(handle, -1)
	end

	if (GVars.features.vehicle.subwoofer and not self:HasLoudRadio()) then
		self:ToggleSubwoofer(true)
	end

	if (GVars.features.vehicle.auto_brake_lights) then
		if (self:IsDrivable() and self:IsEngineOn() and not self:IsMoving() and not PAD.IS_CONTROL_PRESSED(0, 72)) then
			VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(handle, true)
		end
	end

	self.m_feat_mgr:Update()
	self:UpdateABS()
	self:UpdateESC()
	self:UpdateFlappyDoors()
	self:AutolockDoors()
end

return PlayerVehicle
