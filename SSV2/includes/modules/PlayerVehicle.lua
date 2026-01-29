-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local StateMachine     = require("includes.structs.StateMachine")
local HandlingEditor   = require("includes.modules.HandlingEditor")
local Speedometer      = require("includes.features.Speedometer")
local FeatureMgr       = require("includes.services.FeatureManager")
local NosMgr           = require("includes.features.vehicle.nos")
local FlappyDoors      = require("includes.features.vehicle.flappy_doors")
local BFD              = require("includes.features.vehicle.brake_force_display")
local LaunchControlMgr = require("includes.features.vehicle.launch_control")
local DriftMode        = require("includes.features.vehicle.drift_mode")
local HighBeams        = require("includes.features.vehicle.high_beams")
local IVExit           = require("includes.features.vehicle.iv_style_exit")
local RGBLights        = require("includes.features.vehicle.rgb_lights")
local CarCrash         = require("includes.features.vehicle.car_crashes")
local VehMines         = require("includes.features.vehicle.mines")
local MiscVehicle      = require("includes.features.vehicle.misc_vehicle")
local CobraManeuver    = require("includes.features.vehicle.cobra_maneuver")
local Stancer          = require("includes.features.vehicle.stancer")

---@class GenericToggleable
---@field is_toggled boolean
---@field onDisable fun(...): any
---@field args? table


-----------------------------------------
-- PlayerVehicle Module
-----------------------------------------
-- Singleton controller for our current vehicle.
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
---@field private m_default_max_speed float
---@field private m_has_loud_radio boolean
---@field private m_generic_toggleables table<string, GenericToggleable>
---@field private m_handling_editor HandlingEditor
---@field public m_default_xenon_lights { enabled: boolean, index: integer }
---@field public m_default_tire_smoke { enabled: boolean, color: vec3 }
---@field public m_autopilot { eligible: boolean, state: eAutoPilotState, initial_nozzle_pos: integer, last_interrupted?: seconds }
---@field public m_engine_swap_compatible boolean
---@field public m_is_shooting_flares boolean
---@field public m_is_flatbed boolean cache it so we don't have to call natives in UI threads
---@field public m_stance_mgr Stancer
---@overload fun(handle: handle): PlayerVehicle
local PlayerVehicle = Class("PlayerVehicle", Vehicle)

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

---@generic T : FeatureBase
---@param feat FeatureBase
---@return T
function PlayerVehicle:AddFeature(feat)
	return self.m_feat_mgr:Add(feat.new(self))
end

function PlayerVehicle:InitFeatures()
	self.m_feat_mgr   = FeatureMgr.new(self)
	---@diagnostic disable-next-line
	self.m_lctrl_mgr  = self.m_feat_mgr:Add(LaunchControlMgr.new(self))
	self.m_nos_mgr    = self.m_feat_mgr:Add(NosMgr.new(self))
	self.m_abs_mgr    = self.m_feat_mgr:Add(BFD.new(self))
	self.m_stance_mgr = self.m_feat_mgr:Add(Stancer.new(self))

	self.m_feat_mgr:Add(FlappyDoors.new(self))
	self.m_feat_mgr:Add(DriftMode.new(self))
	self.m_feat_mgr:Add(HighBeams.new(self))
	self.m_feat_mgr:Add(IVExit.new(self))
	self.m_feat_mgr:Add(RGBLights.new(self))
	self.m_feat_mgr:Add(CarCrash.new(self))
	self.m_feat_mgr:Add(VehMines.new(self))
	self.m_feat_mgr:Add(MiscVehicle.new(self))
	self.m_feat_mgr:Add(CobraManeuver.new(self))
end

function PlayerVehicle:InitHandlingEditor()
	self.m_handling_editor = HandlingEditor:init(self)
	for key, data in pairs(self.m_flag_registry) do
		self.m_handling_editor:PushFlag(
			key,
			data.flag,
			data.flagType,
			data.pred,
			data.on_enable,
			data.on_disable
		)
	end
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
		m_autopilot = {
			eligible = false,
			state = PlayerVehicle.eAutoPilotState.NONE,
			initial_nozzle_pos = 1,
		},
		m_default_max_speed = 0,
		---@diagnostic disable-next-line
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
	instance:InitHandlingEditor()

	local main_thread = ThreadManager:RegisterLooped("SS_VEHICLE", function()
		instance:Main()
	end)

	Backend:RegisterEventCallbackAll(function()
		---@diagnostic disable-next-line: invisible
		instance.m_feat_mgr:Cleanup()
	end)

	table.insert(instance.m_threads, main_thread)
	return instance
end

---@param handle handle
function PlayerVehicle:Set(handle)
	if (handle == self.m_handle) then
		return
	end

	local new_model                     = ENTITY.GET_ENTITY_MODEL(handle)

	self.m_default_max_speed            = VEHICLE.GET_VEHICLE_MODEL_ESTIMATED_MAX_SPEED(new_model)
	self.m_last_model                   = new_model
	self.m_handle                       = handle
	---@diagnostic disable-next-line

	local temp                          = vec3:zero()
	self.m_default_tire_smoke.color     = vec3:new(VEHICLE.GET_VEHICLE_TYRE_SMOKE_COLOR(handle, temp.x, temp.y, temp.z))
	self.m_default_xenon_lights.enabled = VEHICLE.IS_TOGGLE_MOD_ON(handle, 22)
	self.m_default_xenon_lights.index   = VEHICLE.GET_VEHICLE_XENON_LIGHT_COLOR_INDEX(handle)
	self.m_default_tire_smoke.enabled   = VEHICLE.IS_TOGGLE_MOD_ON(handle, 20)
	self.m_autopilot.eligible           = self:IsAircraft()

	self.m_handling_editor:Apply()
	if (GVars.features.vehicle.no_turbulence and VEHICLE.IS_THIS_MODEL_A_PLANE(new_model)) then
		VEHICLE.SET_PLANE_TURBULENCE_MULTIPLIER(handle, 0.0)
	end

	self.m_stance_mgr:OnNewVehicle()
	-- self:ResumeThreads()
	-- self.m_feat_mgr:OnEnable()
end

function PlayerVehicle:Reset()
	-- self:SuspendThreads()
	if (self:IsValid() and self:IsLocked()) then
		VEHICLE.SET_VEHICLE_DOORS_LOCKED(self:GetHandle(), 1)
		self.m_generic_toggleables["autolockdoors"] = nil
		self.m_last_model = self:GetModelHash()
	end

	self:RestoreHeadlights()
	self:RestoreTireSmoke()
	self:RestoreExhaustPops()
	self:RestoreAllPatches()
	self:ResetAllGenericToggleables()
	self.m_handling_editor:Reset()

	self.m_autopilot = {
		eligible = false,
		state = self.eAutoPilotState.NONE,
		initial_nozzle_pos = 1,
	}

	self:Destroy()
	self.m_handle = 0

	-- called late so it only resets deltas and keeps the vehicle untouched.
	self.m_stance_mgr:Reset()
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

---@param name string
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

	for _, generic in pairs(self.m_generic_toggleables) do
		local toggled = generic.is_toggled
		local func = generic.onDisable
		local args = generic.args
		if (toggled and type(generic.onDisable) == "function" and self:IsValid()) then
			---@diagnostic disable-next-line
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
	local lateral = math.abs(self:GetSpeedVector().x)
	if (lateral == 0) then
		return false
	end

	return VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(handle) and lateral >= 6
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

function PlayerVehicle:AutoLock()
	if (GVars.features.vehicle.auto_lock_doors) then
		local playerPos = Self:GetPos()
		local vehPos    = self:GetPos()
		local distance  = playerPos:distance(vehPos)

		if (not self:IsLocked()
				and distance > 18
				and Self:IsOutside()
				and Self:GetVehicleTryingToEnter() ~= self:GetHandle()
			) then
			self:AddGenericToggleable("autolockdoors", function()
				self:LockDoors(true)
			end, self.LockDoors, { self, false })
		end
	end

	if (self:IsLocked() and Self:GetVehicleTryingToEnter() == self:GetHandle()) then
		if (not self.m_generic_toggleables["autolockdoors"]) then
			self:LockDoors(false)
			return
		end

		self:ResetGenericToggleable("autolockdoors")
	end
end

---@param gvarKey string
---@param toggle boolean
---@param reset? boolean
function PlayerVehicle:SetVehicleFlag(gvarKey, toggle, reset)
	local obj = self.m_handling_editor:GetFlagObject(gvarKey)
	if (not obj) then
		return
	end

	self.m_handling_editor:SetFlag(obj, toggle, reset)
	table.set_nested_key(GVars, gvarKey, toggle)
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
		Notifier:ShowError("Autopilot", "You are not in an aircraft.")
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
		_, destination = Game.GetObjectiveBlipCoords()
	end

	if (not destination or destination:is_zero()) then
		Notifier:ShowError("Autopilot", "Failed to get autopilot coordinates!")
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
			self.m_autopilot.last_interrupted = Time.now() + 5
			Notifier:ShowMessage(
				"Samurai's Scripts",
				"Autopilot interrupted! Giving back control to the player.",
				false,
				4
			)
			self:ResetAutopilot()
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

	if (self.m_autopilot.last_interrupted and Time.now() > self.m_autopilot.last_interrupted) then
		self.m_autopilot.last_interrupted = nil
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

	if (GVars.features.vehicle.auto_brake_lights and Self:IsDriving()) then
		if (self:IsDriveable() and self:IsEngineOn() and not self:IsMoving() and not PAD.IS_CONTROL_PRESSED(0, 72)) then
			VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(handle, true)
		end
	end

	self.m_is_flatbed = self:IsFlatbedTruck()
	self.m_engine_swap_compatible = self:IsCar()
	self.m_feat_mgr:Update()
	self:UpdateESC()
	self:AutoLock()
	self:HandleAutopilot()
	Speedometer:UpdateState()
end

-- Just for convenience so we don't have to remember patch names.
--
-- If we want auto-complete, we have to first define the patch name here.
PlayerVehicle.MemoryPatches = {
	DeformMult   = "DeformMult",
	Turbulence   = "Turbulence",
	WindMult     = "WindMult",
	Acceleration = "Acceleration",
}

PlayerVehicle.m_flag_registry = {
	["features.vehicle.no_engine_brake"]     = {
		flag = Enums.eVehicleHandlingFlags.FREEWHEEL_NO_GAS,
		flagType = Enums.eHandlingEditorTypes.TYPE_HF,
		pred = function(_, pv)
			return pv:IsLandVehicle()
		end,
		-- Checkbox mass register
		cb_label = "VEH_NO_ENGINE_BRAKE",
		cb_tt = "VEH_NO_ENGINE_BRAKE_TT",
		on_cb_enable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.no_engine_brake", true)
		end,
		on_cb_disable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.no_engine_brake", false, true)
		end,
	},
	["features.vehicle.kers_boost"]          = {
		flag = Enums.eVehicleHandlingFlags.HAS_KERS,
		flagType = Enums.eHandlingEditorTypes.TYPE_HF,
		pred = function(_, pv)
			return pv:IsLandVehicle()
		end,
		on_enable = function()
			local PV = Self:GetVehicle()
			if (not PV:IsValid()) then
				return
			end
			VEHICLE.SET_VEHICLE_KERS_ALLOWED(PV:GetHandle(), true)
		end,
		on_disable = function()
			local PV = Self:GetVehicle()
			if (not PV:IsValid()) then
				return
			end
			VEHICLE.SET_VEHICLE_KERS_ALLOWED(PV:GetHandle(), false) -- this is fine, HandlingEditor won't execute this if the vehicle had the handling flag enabled by default
		end,
		cb_label = "VEH_KERS_BOOST",
		cb_tt = "VEH_KERS_BOOST_TT",
		on_cb_enable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.kers_boost", true)
		end,
		on_cb_disable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.kers_boost", false, true)
		end,
	},
	["features.vehicle.offroad_abilities"]   = {
		flag = Enums.eVehicleHandlingFlags.OFFROAD_ABILITIES_X2,
		flagType = Enums.eHandlingEditorTypes.TYPE_HF,
		cb_label = "VEH_OFFROAD_ABILITIES",
		cb_tt = "VEH_OFFROAD_ABILITIES_TT",
		pred = function(_, pv)
			return pv:IsLandVehicle()
		end,
		on_cb_enable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.offroad_abilities", true)
		end,
		on_cb_disable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.offroad_abilities", false, true)
		end,
	},
	["features.vehicle.rallye_tyres"]        = {
		flag = Enums.eVehicleHandlingFlags.HAS_RALLY_TYRES,
		flagType = Enums.eHandlingEditorTypes.TYPE_HF,
		cb_label = "VEH_RALLY_TYRES",
		cb_tt = "VEH_RALLY_TYRES_TT",
		pred = function(_, pv)
			return pv:IsLandVehicle()
		end,
		on_cb_enable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.rallye_tyres", true)
		end,
		on_cb_disable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.rallye_tyres", false)
		end,
	},
	["features.vehicle.no_traction_control"] = {
		flag = Enums.eVehicleHandlingFlags.FORCE_NO_TC_OR_SC,
		flagType = Enums.eHandlingEditorTypes.TYPE_HF,
		pred = function(_, pv)
			return pv:IsBike()
		end,
		cb_label = "VEH_FORCE_NO_TC",
		cb_tt = "VEH_FORCE_NO_TC_TT",
		on_cb_enable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.no_traction_control", true)
		end,
		on_cb_disable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.no_traction_control", false, true)
		end,
	},
	["features.vehicle.low_speed_wheelies"]  = {
		flag = Enums.eVehicleHandlingFlags.LOW_SPEED_WHEELIES,
		flagType = Enums.eHandlingEditorTypes.TYPE_HF,
		pred = function(_, pv)
			return pv:IsBike()
		end,
		cb_label = "VEH_LOW_SPEED_WHEELIE",
		cb_tt = "VEH_LOW_SPEED_WHEELIE_TT",
		on_cb_enable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.low_speed_wheelies", true)
		end,
		on_cb_disable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.low_speed_wheelies", false, true)
		end,
	},
	["features.vehicle.rocket_boost"]        = {
		flag = Enums.eVehicleModelInfoFlags.HAS_ROCKET_BOOST,
		flagType = Enums.eHandlingEditorTypes.TYPE_MIF,
		pred = function(_, pv)
			return pv:IsLandVehicle()
		end,
		on_enable = function()
			Game.RequestNamedPtfxAsset("VEH_IMPEXP_ROCKET") -- will introduce a short yield but it's fine
		end,
		on_disable = function()
			STREAMING.REMOVE_NAMED_PTFX_ASSET("VEH_IMPEXP_ROCKET")
		end,
		on_cb_enable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.rocket_boost", true)
		end,
		on_cb_disable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.rocket_boost", false, true)
		end,
		cb_label = "VEH_ROCKET_BOOST",
		cb_tt = "VEH_ROCKET_BOOST_TT",
	},
	["features.vehicle.jump_capability"]     = {
		flag = Enums.eVehicleModelInfoFlags.JUMPING_CAR,
		flagType = Enums.eHandlingEditorTypes.TYPE_MIF,
		pred = function(_, pv)
			return pv:IsLandVehicle()
		end,
		on_enable = function()
			local PV = Self:GetVehicle()
			if (not PV:IsValid()) then
				return
			end
			VEHICLE.SET_USE_HIGHER_CAR_JUMP(PV:GetHandle(), true)
		end,
		on_disable = function()
			local PV = Self:GetVehicle()
			if (not PV:IsValid()) then
				return
			end
			VEHICLE.SET_USE_HIGHER_CAR_JUMP(PV:GetHandle(), false)
		end,
		on_cb_enable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.jump_capability", true)
		end,
		on_cb_disable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.jump_capability", false, true)
		end,
		cb_label = "VEH_JUMP",
		cb_tt = "VEH_JUMP_TT",
	},
	["features.vehicle.parachute"]           = {
		flag = Enums.eVehicleModelInfoFlags.HAS_PARACHUTE,
		flagType = Enums.eHandlingEditorTypes.TYPE_MIF,
		pred = function(_, pv)
			return pv:IsCar() and GVars.features.vehicle.jump_capability
		end,
		on_cb_enable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.parachute", true)
		end,
		on_cb_disable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.parachute", false, true)
		end,
		cb_label = "VEH_PARACHUTE",
		cb_tt = "VEH_PARACHUTE_TT",
	},
	["features.vehicle.steer_rear_wheels"]   = {
		flag = Enums.eVehicleHandlingFlags.STEER_REARWHEELS,
		flagType = Enums.eHandlingEditorTypes.TYPE_HF,
		pred = function(_, pv)
			return pv:IsCar()
		end,
		on_cb_enable = function()
			local PV = Self:GetVehicle()
			PV:SetVehicleFlag("features.vehicle.steer_rear_wheels", true)
			PV:SetVehicleFlag("features.vehicle.steer_all_wheels", false, true)
			PV:SetVehicleFlag("features.vehicle.steer_handbrake", false, true)
		end,
		on_cb_disable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.steer_rear_wheels", false, true)
		end,
		cb_label = "VEH_STEER_REAR_WHEELS",
	},
	["features.vehicle.steer_all_wheels"]    = {
		flag = Enums.eVehicleHandlingFlags.STEER_ALL_WHEELS,
		flagType = Enums.eHandlingEditorTypes.TYPE_HF,
		pred = function(_, pv)
			return pv:IsCar()
		end,
		on_cb_enable = function()
			local PV = Self:GetVehicle()
			PV:SetVehicleFlag("features.vehicle.steer_all_wheels", true)
			PV:SetVehicleFlag("features.vehicle.steer_rear_wheels", false, true)
			PV:SetVehicleFlag("features.vehicle.steer_handbrake", false, true)
		end,
		on_cb_disable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.steer_all_wheels", false, true)
		end,
		cb_label = "VEH_STEER_ALL_WHEELS",
	},
	["features.vehicle.steer_handbrake"]     = {
		flag = Enums.eVehicleHandlingFlags.HANDBRAKE_REARWHEELSTEER,
		flagType = Enums.eHandlingEditorTypes.TYPE_HF,
		pred = function(_, pv)
			return pv:IsCar()
		end,
		on_cb_enable = function()
			local PV = Self:GetVehicle()
			PV:SetVehicleFlag("features.vehicle.steer_handbrake", true)
			PV:SetVehicleFlag("features.vehicle.steer_rear_wheels", false, true)
			PV:SetVehicleFlag("features.vehicle.steer_all_wheels", false, true)
		end,
		on_cb_disable = function()
			Self:GetVehicle():SetVehicleFlag("features.vehicle.steer_handbrake", false, true)
		end,
		cb_label = "VEH_STEER_HANDBRAKE",
		cb_tt = "VEH_STEER_HANDBRAKE_TT",
	},
}

return PlayerVehicle.new(0)
