---@diagnostic disable: param-type-mismatch

local StateMachine = require("includes.structs.StateMachine")
local Speedometer = require("includes.features.Speedometer")
local FeatureMgr = require("includes.services.FeatureManager")
local NosMgr = require("includes.features.vehicle.nos")
local FlappyDoors = require("includes.features.vehicle.flappy_doors")
local BFD = require("includes.features.vehicle.brake_force_display")
local LaunchControlMgr = require("includes.features.vehicle.launch_control")
local DriftMode = require("includes.features.vehicle.drift_mode")
local HighBeams = require("includes.features.vehicle.high_beams")
local IVExit = require("includes.features.vehicle.iv_style_exit")
local RGBLights = require("includes.features.vehicle.rgb_lights")
local CarCrash = require("includes.features.vehicle.car_crashes")
local VehMines = require("includes.features.vehicle.mines")
local MiscVehicle = require("includes.features.vehicle.misc_vehicle")

---@class GenericToggleable
---@field is_toggled boolean
---@field onDisable fun(...): any
---@field args? table


-----------------------------------------
-- PlayerVehicle Module
-----------------------------------------
-- Singleton controller for the player’s vehicle that manages features, state machines, threads, and ensures
--
-- all temporary modifications (handling flags, memory writes, toggles, visuals, audio, etc.) are safely restored
--
-- when the vehicle changes or resets.
---@class PlayerVehicle : Vehicle
---@field private m_handle handle
---@field private m_last_model hash
---@field private m_esc_sm StateMachine
---@field private m_feat_mgr FeatureManager
---@field private m_nos_mgr NosMgr
---@field private m_abs_mgr BFD
---@field private m_lctrl_mgr LaunchControlMgr
---@field private m_threads array<Thread>
---@field private m_default_handling_flags table<eVehicleHandlingFlags, boolean>
---@field private m_handling_flags_to_change table<string, { flag : eVehicleHandlingFlags, bikes_only : boolean }>
---@field private m_default_max_speed float
---@field private m_has_loud_radio boolean
---@field private m_generic_toggleables table<string, GenericToggleable>
---@field public m_default_xenon_lights { enabled: boolean, index: integer }
---@field public m_default_tire_smoke { enabled: boolean, color: vec3 }
---@field public m_autopilot { eligible: boolean, state: eAutoPilotState, initial_nozzle_pos: integer }
---@field public m_engine_swap_compatible boolean
---@field public m_is_shooting_flares boolean
---@field public m_is_flatbed boolean cache it so we don't have to call natives in UI threads
---@overload fun(handle: handle): PlayerVehicle
local PlayerVehicle = Class("PlayerVehicle", Vehicle)
PlayerVehicle.m_handling_flags_to_change = {
	["features.vehicle.no_engine_brake"] = { flag = Enums.eVehicleHandlingFlags.FREEWHEEL_NO_GAS, bikes_only = false },
	["features.vehicle.kers_boost"] = { flag = Enums.eVehicleHandlingFlags.HAS_KERS, bikes_only = false },
	["features.vehicle.offroad_abilities"] = { flag = Enums.eVehicleHandlingFlags.OFFROAD_ABILITIES_X2, bikes_only = false },
	["features.vehicle.rallye_tyres"] = { flag = Enums.eVehicleHandlingFlags.HAS_RALLY_TYRES, bikes_only = false },
	["features.vehicle.no_traction_control"] = { flag = Enums.eVehicleHandlingFlags.FORCE_NO_TC_OR_SC, bikes_only = true },
	["features.vehicle.low_speed_wheelies"] = { flag = Enums.eVehicleHandlingFlags.LOW_SPEED_WHEELIES, bikes_only = true },
}
PlayerVehicle.mines = {
	Pair.new("Spikes", -647126932),
	Pair.new("Slick", 1459276487),
	Pair.new("Explosive", 1508567460),
	Pair.new("EMP", 1776356704),
	Pair.new("Kinetic", 1007245390),
}
---@enum eAutoPilotState
PlayerVehicle.eAutoPilotState = {
	NONE      = 0,
	WAYPOINT  = 1,
	OBJECTIVE = 2,
	RANDOM    = 3
}
PlayerVehicle.FlightControls = {
	72,
	75,
	87,
	88,
	89,
	90,
	106,
	107,
	108,
	109,
	110,
	111,
	112,
}

function PlayerVehicle:InitFeatures()
	self.m_feat_mgr  = FeatureMgr.new(self)
	self.m_lctrl_mgr = self.m_feat_mgr:Add(LaunchControlMgr.new(self))
	self.m_nos_mgr   = self.m_feat_mgr:Add(NosMgr.new(self))
	self.m_abs_mgr   = self.m_feat_mgr:Add(BFD.new(self))

	self.m_feat_mgr:Add(FlappyDoors.new(self))
	self.m_feat_mgr:Add(DriftMode.new(self))
	self.m_feat_mgr:Add(HighBeams.new(self))
	self.m_feat_mgr:Add(IVExit.new(self))
	self.m_feat_mgr:Add(RGBLights.new(self))
	self.m_feat_mgr:Add(CarCrash.new(self))
	self.m_feat_mgr:Add(VehMines.new(self))
	self.m_feat_mgr:Add(MiscVehicle.new(self))
end

---@return PlayerVehicle
function PlayerVehicle.new(handle)
	---@type PlayerVehicle
	local instance = setmetatable({
		m_is_nos_active = false,
		m_handle = handle,
		m_threads = {},
		m_default_handling_flags = {},
		m_generic_toggleables = {},
		m_default_xenon_lights = { enabled = false, index = 0 },
		m_default_tire_smoke = { enabled = false, color = vec3:zero() },
		m_autopilot = { eligible = false, state = PlayerVehicle.eAutoPilotState.NONE, initial_nozzle_pos = 1 },
		m_default_max_speed = 0,
	}, PlayerVehicle)

	instance.m_esc_sm = StateMachine({
		predicate = function(_, veh)
			return Self:IsDriving()
				and veh:IsCar()
				and veh:IsDrifting()
				and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(veh:GetHandle())
		end,
		interval = 0.1
	})

	instance:InitFeatures()

	local main_thread = ThreadManager:RegisterLooped("SS_VEHICLE", function()
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

	local temp                          = vec3:zero()
	self.m_default_xenon_lights.enabled = VEHICLE.IS_TOGGLE_MOD_ON(handle, 22)
	self.m_default_xenon_lights.index   = VEHICLE.GET_VEHICLE_XENON_LIGHT_COLOR_INDEX(handle)
	self.m_default_tire_smoke.enabled   = VEHICLE.IS_TOGGLE_MOD_ON(handle, 20)
	self.m_default_tire_smoke.color     = vec3:new(VEHICLE.GET_VEHICLE_TYRE_SMOKE_COLOR(handle, temp.x, temp.y, temp.z))
	self.m_autopilot.eligible           = self:IsAircraft()
	-- self:ResumeThreads()
	-- self.m_feat_mgr:OnEnable()
end

function PlayerVehicle:Reset()
	-- self.m_feat_mgr:OnDisable()
	-- self:SuspendThreads()
	if (self:IsLocked()) then
		VEHICLE.SET_VEHICLE_DOORS_LOCKED(self:GetHandle(), 1)
		self.m_generic_toggleables["autolockdoors"] = nil
	end

	self:RestoreHeadlights()
	self:RestoreTireSmoke()
	self:RestoreExhaustPops()
	self:ResetHandlingFlags()
	self:RestoreAllPatches()
	self:ResetAllGenericToggleables()

	self.m_autopilot = { eligible = false, state = self.eAutoPilotState.NONE, initial_nozzle_pos = 1 }
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

-- Patches your current vehicle's memory once and automatically resets it on cleanup.
---@param data PatchData
---@param apply? boolean
function PlayerVehicle:AddMemoryPatch(data, apply)
	Memory:AddPatch(self, data, apply or false)
end

---@param patchName string
function PlayerVehicle:ApplyPatch(patchName)
	Memory:ApplyPatch(self, patchName)
end

---@param patchName string
function PlayerVehicle:RestorePatch(patchName)
	Memory:RestorePatch(self, patchName)
end

function PlayerVehicle:RestoreAllPatches()
	Memory:RestoreAllPatchesByRef(self)
end

---@param name string
---@param onEnable? function
---@param onDisable fun(...)
---@param args? table
function PlayerVehicle:AddGenericToggleable(name, onEnable, onDisable, args)
	if (self.m_generic_toggleables[name]) then
		return
	end

	args = args or {}
	if (type(onEnable) == "function") then
		ThreadManager:Run(function()
			onEnable()
		end)
	end

	self.m_generic_toggleables[name] = {
		is_toggled = true,
		onDisable = onDisable,
		args = args
	}
end

function PlayerVehicle:ResetGenericToggleable(name)
	local generic = self.m_generic_toggleables[name]
	if (not generic or type(generic.onDisable) ~= "function") then
		return
	end

	ThreadManager:Run(function()
		generic.onDisable(table.unpack(generic.args))
		self.m_generic_toggleables[name] = nil
	end)
end

function PlayerVehicle:ResetAllGenericToggleables()
	if (next(self.m_generic_toggleables) == nil) then
		return
	end

	for name, generic in pairs(self.m_generic_toggleables) do
		local toggled = generic.is_toggled
		local func = generic.onDisable
		local args = generic.args
		if (toggled and type(generic.onDisable) == "function") then
			func(table.unpack(args))
		end
	end

	self.m_generic_toggleables = {}
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
function PlayerVehicle:IsDriftButtonPressed()
	return KeyManager:IsKeybindPressed("drift_mode")
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
	return self.m_abs_mgr:IsToggled()
end

---@return boolean
function PlayerVehicle:IsESCEngaged()
	return self.m_esc_sm:IsToggled()
end

---@return boolean
function PlayerVehicle:IsNOSActive()
	return self.m_nos_mgr:IsActive()
end

---@return float
function PlayerVehicle:GetNOSDangerRatio()
	return self.m_nos_mgr:GetDangerRatio()
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

function PlayerVehicle:RestoreTireSmoke()
	if (not self:IsValid()) then
		return
	end

	local handle = self:GetHandle()
	local col = self.m_default_tire_smoke.color
	VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(handle, col.x, col.y, col.z)
	VEHICLE.TOGGLE_VEHICLE_MOD(handle, 20, self.m_default_tire_smoke.enabled)
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

function PlayerVehicle:AutolockDoors()
	if (not GVars.features.vehicle.auto_lock_doors) then
		return
	end

	local handle   = self:GetHandle()
	local vehPos   = self:GetPos()
	local distance = vehPos:distance(Self:GetPos())
	local isLocked = VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(handle) > 1

	if (not isLocked
			and distance > 20
			and Self:IsOutside()
			and PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(Self:GetHandle()) ~= handle
		) then
		self:AddGenericToggleable("autolockdoors", function()
			self:LockDoors(true)
		end, self.LockDoors, { self, false })
	end

	if (isLocked and PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(Self:GetHandle()) == handle) then
		self:ResetGenericToggleable("autolockdoors")
	end
end

function PlayerVehicle:GetDefaultHandlingFlags()
	for _, value in pairs(Enums.eVehicleHandlingFlags) do
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

function PlayerVehicle:ResetAutopilot()
	self.m_autopilot.state = self.eAutoPilotState.NONE
	self:ClearPrimaryTask()
	Self:ClearTasks()
	Self:ClearSecondaryTask()
end

---@param newState eAutoPilotState
function PlayerVehicle:UpdateAutopilotState(newState)
	if (newState == self.m_autopilot.state) then
		return
	end

	if (not Self:IsDriving()) then
		Toast:ShowError("Autopilot", "You are not in an aircraft.")
		return
	end

	self.m_autopilot.state = newState
	if (newState == self.eAutoPilotState.NONE) then
		self:ResetAutopilot()
		return
	end

	local destination
	if (newState == self.eAutoPilotState.RANDOM) then
		destination = Game.GetRandomCoordsInRange(vec3:new(-2000, -3000, 0), vec3:new(2000, 3500, 100))
	elseif (newState == self.eAutoPilotState.WAYPOINT) then
		destination = Game.GetWaypointCoords()
	elseif (newState == self.eAutoPilotState.OBJECTIVE) then
		destination = Game.GetObjectiveBlipCoords()
	end

	if (not destination or destination:is_zero()) then
		Toast:ShowError("Autopilot", "Failed to get autopilot coordinates!")
		self:ResetAutopilot()
		return
	end

	self.m_autopilot.initial_nozzle_pos = VEHICLE.GET_VEHICLE_FLIGHT_NOZZLE_POSITION(self:GetHandle())
	self:GoTo(destination)
end

function PlayerVehicle:HandleAutopilot()
	if (self.m_autopilot.state == self.eAutoPilotState.NONE) then
		return
	end

	if (not Self:IsDriving() or not Self:IsAlive()) then
		self:ResetAutopilot()
		return
	end

	for _, ctrl in ipairs(self.FlightControls) do
		if (PAD.IS_CONTROL_PRESSED(0, ctrl)) then
			self:ResetAutopilot()
			Toast:ShowMessage(
				"Samurai's Scripts",
				"Autopilot interrupted! Giving back control to the player.",
				false,
				4
			)
			break
		end
	end

	if (self:GetHeightAboveGround() > 15) then
		local gs = self:GetLandingGearState()
		if (gs ~= Enums.eLandingGearState.RETRACTED and gs ~= Enums.eLandingGearState.RETRACTING) then
			VEHICLE.CONTROL_LANDING_GEAR(self:GetHandle(), Enums.eLandingGearState.RETRACTING)
		end

		if (VEHICLE.GET_VEHICLE_FLIGHT_NOZZLE_POSITION(self:GetHandle()) ~= self.m_autopilot.initial_nozzle_pos) then
			VEHICLE.SET_VEHICLE_FLIGHT_NOZZLE_POSITION(self:GetHandle(), self.m_autopilot.initial_nozzle_pos)
		end
	end
end

function PlayerVehicle:Main()
	if (not self:IsValid()) then
		sleep(500)
		return
	end

	local handle = self:GetHandle()

	if (GVars.features.vehicle.fast_vehicles) then
		if (self:GetMaxSpeed() <= 80) then
			VEHICLE.MODIFY_VEHICLE_TOP_SPEED(handle, 100)
		end
	elseif (self:GetMaxSpeed() >= 80) then
		VEHICLE.MODIFY_VEHICLE_TOP_SPEED(handle, -1)
	end

	if (GVars.features.vehicle.subwoofer and (not self:HasLoudRadio() or not self.m_generic_toggleables["subwoofer"])) then
		self:AddGenericToggleable("subwoofer", function()
			self:ToggleSubwoofer(true)
		end, self.ToggleSubwoofer, { self, false })
	end

	if (GVars.features.vehicle.unbreakable_windows) then
		local native = VEHICLE.SET_DONT_PROCESS_VEHICLE_GLASS
		self:AddGenericToggleable("strongwindows", function()
			native(handle, true)
		end, native, { handle, false })
	end

	if (GVars.features.vehicle.auto_brake_lights) then
		if (self:IsDriveable() and self:IsEngineOn() and not self:IsMoving() and not PAD.IS_CONTROL_PRESSED(0, 72)) then
			VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(handle, true)
		end
	end

	self.m_is_flatbed = self:IsFlatbedTruck()
	self.m_engine_swap_compatible = self:IsCar()
	self.m_feat_mgr:Update()
	self:UpdateESC()
	self:AutolockDoors()
	self:HandleAutopilot()
	Speedometer:UpdateState()
end

-- Just for convenience so we don't have to remember patch names.
--
-- If we want auto-complete, we have to first define the patch name here.
--
-- We can still ignore this and memorize patch names and directly use them to apply/restore.
PlayerVehicle.MemoryPatches = {
	DeformMult   = "DeformMult",
	Turbulence   = "Turbulence",
	WindMult     = "WindMult",
	Acceleration = "Acceleration",
}

return PlayerVehicle.new(0)
