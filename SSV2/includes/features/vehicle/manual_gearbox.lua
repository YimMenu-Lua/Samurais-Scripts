-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")
local FlagPreset  = require("includes.structs.VehicleFlagPreset")


---@enum eManualGearboxType
local eManualGearboxType <const> = {
	H_PATTERN  = 0,
	SEQUENTIAL = 1,
	AUTO       = 2,
}

---@enum eGearDriveState
local eGearDriveState <const>    = {
	INVALID = -1,
	NEUTRAL = 0,
	REVERSE = 1,
	DRIVE   = 2
}

---@enum eGearInputLast
local eGearInputLast <const>     = {
	NONE      = 0,
	UPSHIFT   = 1,
	DOWNSHIFT = 2,
}

---@return boolean
local function is_control_pressed_2(action)
	return (PAD.IS_CONTROL_PRESSED(0, action) or PAD.IS_DISABLED_CONTROL_PRESSED(0, action))
end

---@class GearSelectState
---@field m_current uint8_t
---@field m_previous uint8_t
---@field m_selected uint8_t
---@field m_mutated boolean
---@field m_is_clutch_pressed boolean
---@field m_is_in_reverse boolean
---@field m_has_stalled boolean


---@class ManualGearbox : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_cvehicle CVehicle
---@field private m_gear_state GearSelectState
---@field private m_drive_state eGearDriveState
---@field private m_last_input eGearInputLast -- TODO: use this for downshift protection (sequential) and money shifts (manual)
---@field private m_flag_preset VehicleFlagPreset
---@field private m_clutch_kick { enabled: boolean, rpm: float, timer: Timer }
---@field private m_kick_start { enabled: boolean, timer: Timer }
---@field private m_clutch_kick_duration integer
---@field private m_force_sequential boolean
---@field private m_force_neutral boolean
---@field private m_is_single_gear boolean
local ManualGearbox   = setmetatable({}, FeatureBase)
ManualGearbox.__index = ManualGearbox

---@param pv PlayerVehicle
---@return ManualGearbox
function ManualGearbox.new(pv)
	local base = FeatureBase.new(pv)
	---@diagnostic disable-next-line
	return setmetatable(base, ManualGearbox)
end

---@return boolean
function ManualGearbox:ShouldRun()
	local veh = self.m_entity
	return self:GetConfig().enabled
		and LocalPlayer:IsAlive()
		and LocalPlayer:IsDriving()
		and veh:IsValid()
		and veh:IsDriveable()
		and veh:IsLandVehicle()
end

---@return boolean
function ManualGearbox:IsInReverse()
	return self.m_gear_state.m_is_in_reverse
end

---@return boolean
function ManualGearbox:IsSingleGear()
	return self.m_is_single_gear
end

---@return boolean
function ManualGearbox:IsActive()
	local cfg     = self:GetConfig()
	local is_auto = cfg.mode == eManualGearboxType.AUTO
	return cfg.enabled and not is_auto and not self.m_is_single_gear
end

function ManualGearbox:Init()
	local clutch_kick_duration  = 400
	self.m_drive_state          = eGearDriveState.INVALID
	self.m_last_input           = eGearInputLast.NONE
	self.m_clutch_kick_duration = clutch_kick_duration
	self.m_force_sequential     = false
	self.m_force_neutral        = false
	self.m_is_single_gear       = false

	self.m_kick_start           = {
		enabled = false,
		timer   = Timer(266, true)
	}

	self.m_clutch_kick          = {
		enabled = false,
		rpm     = 0.0,
		timer   = Timer(clutch_kick_duration, true),
	}

	self.m_gear_state           = {
		m_current           = 0,
		m_previous          = 0,
		m_selected          = 0,
		m_mutated           = false,
		m_is_clutch_pressed = false,
		m_is_in_reverse     = false,
		m_has_stalled       = false,
	}

	self.m_flag_preset          = FlagPreset({
		name           = "Manual Gearbox",
		deltas         = {
			[Enums.eHandlingEditorTypes.TYPE_AF] = {
				["GEARBOX_MANUAL"]       = true,
				["GEARBOX_DIRECT_SHIFT"] = false,
				["GEARBOX_FULL_AUTO"]    = false,
				["GEARBOX_ELECTRIC"]     = false,
			},
			[Enums.eHandlingEditorTypes.TYPE_HF] = {
				["NO_REVERSE"] = true,
			},
		},
		vehicle_bitset = 1 << Enums.eVehicleType.VEHICLE_TYPE_CAR | 1 << Enums.eVehicleType.VEHICLE_TYPE_BIKE
	})
end

function ManualGearbox:Reset()
	self.m_gear_state          = {
		m_current           = 0,
		m_previous          = 0,
		m_selected          = 0,
		m_mutated           = false,
		m_is_clutch_pressed = false,
		m_is_in_reverse     = false,
		m_has_stalled       = false,
	}

	self.m_kick_start          = {
		enabled = false,
		timer   = Timer(266, true)
	}

	self.m_drive_state         = eGearDriveState.INVALID
	self.m_last_input          = eGearInputLast.NONE
	self.m_force_sequential    = false
	self.m_force_neutral       = false
	self.m_is_single_gear      = false
	self.m_clutch_kick.enabled = false
	self.m_clutch_kick.rpm     = 0.0
	self.m_clutch_kick.timer:Reset()
	self.m_entity.m_flag_controller:TogglePreset(self.m_flag_preset, false)

	local cvehicle = self.m_cvehicle
	if (not cvehicle) then return end

	local pCurrentGear = cvehicle.m_transmission.m_current_gear
	if (pCurrentGear:is_valid() and pCurrentGear:get_byte() > 10) then
		self:SetGear(0)
	end
end

---@return { enabled: boolean, mode: eManualGearboxType, disable_stalling: boolean}
function ManualGearbox:GetConfig()
	return GVars.features.vehicle.manual_gearbox
end

---@param toggle? boolean
function ManualGearbox:SetEngineAutoStart(toggle)
	local veh = self.m_entity
	if (not veh:IsValid()) then return end

	local cfg = self:GetConfig()
	if (toggle == nil) then
		toggle = not cfg.disable_stalling
	end

	VEHICLE.SET_VEHICLE_ENGINE_ON(veh:GetHandle(), veh:IsEngineOn(), true, toggle)
end

function ManualGearbox:OnNewVehicle()
	local veh = self.m_entity
	local cfg = self:GetConfig()
	if not (cfg.enabled and veh:IsValid()) then
		return
	end

	local cvehicle = veh:Resolve()
	if (not cvehicle or not cvehicle:IsValid()) then
		return
	end

	local transmission    = cvehicle.m_transmission
	self.m_is_single_gear = veh:IsElectric() or transmission.m_top_gear:get_byte() == 1
	self.m_cvehicle       = cvehicle
	if (self.m_is_single_gear) then
		return
	end

	local pCurrentGear = transmission.m_current_gear
	local pPrevGear    = transmission.m_previous_gear
	if (veh:IsStopped()) then
		pCurrentGear:set_byte(0)
		pPrevGear:set_byte(0)
	end

	local current_gear           = pCurrentGear:get_byte()
	self.m_gear_state.m_current  = current_gear
	self.m_gear_state.m_selected = current_gear
	self.m_gear_state.m_previous = pPrevGear:get_byte()
	self.m_force_neutral         = false
	self.m_kick_start            = {
		enabled = false,
		timer   = Timer(266, true)
	}

	self:SetEngineAutoStart()
	veh.m_flag_controller:TogglePreset(self.m_flag_preset, cfg.mode ~= eManualGearboxType.AUTO)
end

---@return boolean
function ManualGearbox:WantsNeutral()
	return not self.m_entity:IsReversing() and self.m_gear_state.m_selected <= 0 or self.m_force_neutral
end

---@return uint8_t
function ManualGearbox:GetSelectedGear()
	return self.m_gear_state.m_selected
end

---@return eGearDriveState
function ManualGearbox:GetDriveState()
	return self.m_drive_state
end

---@param gear byte
function ManualGearbox:SetGear(gear)
	local cvehicle = self.m_cvehicle
	if (not cvehicle:IsValid()) then return end
	cvehicle.m_transmission.m_current_gear:set_byte(gear)
	cvehicle.m_transmission.m_previous_gear:set_byte(gear)
end

---@param gear_state GearSelectState
function ManualGearbox:ShiftGears(gear_state)
	if (self:WantsNeutral() or gear_state.m_is_clutch_pressed) then return end
	self:SetGear(gear_state.m_selected)
end

---@param gear_state GearSelectState
---@param cvehicle CVehicle
function ManualGearbox:OnClutchPress(gear_state, cvehicle)
	if (not gear_state.m_mutated) then
		local current_gear             = cvehicle.m_transmission.m_current_gear:get_byte()
		gear_state.m_current           = current_gear
		gear_state.m_previous          = cvehicle.m_transmission.m_previous_gear:get_byte()
		gear_state.m_mutated           = true
		gear_state.m_is_clutch_pressed = true
	end
end

---@param gear_state GearSelectState
---@param cvehicle CVehicle
function ManualGearbox:OnClutchRelease(gear_state, cvehicle)
	if (gear_state.m_mutated) then
		gear_state.m_mutated           = false
		gear_state.m_is_clutch_pressed = false
	end

	local rpm = cvehicle.m_transmission.m_rpm:get_float()
	if (not self.m_clutch_kick.enabled and math.is_inrange(rpm, 0.5, 1.0)) then
		self.m_clutch_kick.enabled = true
		self.m_clutch_kick.rpm     = rpm
		self.m_clutch_kick.timer:Reset()
	end
end

function ManualGearbox:HandleEngineStalling()
	local cfg               = self:GetConfig()
	local veh               = self.m_entity
	local handle            = veh:GetHandle()
	local is_auto           = cfg.mode == eManualGearboxType.AUTO
	local no_clutch         = cfg.mode == eManualGearboxType.SEQUENTIAL or is_auto or self.m_force_sequential
	local is_engine_on      = veh:IsEngineOn()
	local is_in_neutral     = self:WantsNeutral()
	local is_clutch_pressed = self.m_gear_state.m_is_clutch_pressed or no_clutch
	local speed             = veh:GetSpeed()

	if (KeyManager:IsKeybindJustPressed("engine_start_stop")) then
		if (not is_engine_on and not is_in_neutral and not is_clutch_pressed) then
			Notifier:ShowError("ManualGearbox", _T("VEH_GEARBOX_ENGINE_START_ERR"))
			return
		end
		VEHICLE.SET_VEHICLE_ENGINE_ON(handle, not is_engine_on, false, true)
	end

	if (is_auto) then return end

	if (is_engine_on) then
		if (cfg.disable_stalling or no_clutch or (veh:IsBike() and self:IsInReverse())) then
			return
		end

		local rpm = self.m_cvehicle.m_transmission.m_rpm:get_float()
		if (speed < 2 and not is_in_neutral and not is_clutch_pressed and rpm < 0.333) then
			VEHICLE.SET_VEHICLE_ENGINE_ON(handle, false, false, true)
			return
		end
	elseif (speed >= 3.9 and not is_clutch_pressed and not is_in_neutral) then -- auto kick-start from ~14km/h and up
		if (not self.m_kick_start.enabled) then
			self.m_kick_start.enabled = true
			self.m_kick_start.timer:Reset()
			VEHICLE.SET_VEHICLE_HANDBRAKE(handle, true)
		end
	end
end

function ManualGearbox:HandleClutchKick()
	local _t = self.m_clutch_kick
	if (not _t.enabled) then return end

	local timer = _t.timer
	if (timer:IsDone()) then
		_t.enabled = false
		_t.rpm     = 0.0
		return
	end

	local duration = self.m_clutch_kick_duration
	local elapsed  = timer:Elapsed()
	local rpm      = _t.rpm
	local delta    = math.ratio(elapsed, 0, duration)
	local power    = math.lerp(10.0, 1.0, delta ^ 2) * rpm
	VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(self.m_entity:GetHandle(), power)
end

function ManualGearbox:HandleKickStart()
	if (not self.m_kick_start.enabled) then
		return
	end

	local timer = self.m_kick_start.timer
	if (timer:IsDone()) then
		local handle = self.m_entity:GetHandle()
		VEHICLE.SET_VEHICLE_HANDBRAKE(handle, false)
		VEHICLE.SET_VEHICLE_ENGINE_ON(handle, true, true, true)
		timer:Reset()
		self.m_kick_start.enabled = false
	end
end

---@param gear_state GearSelectState
---@param cvehicle CVehicle
function ManualGearbox:WhileClutchEngaged(gear_state, cvehicle)
	local transmission = cvehicle.m_transmission
	transmission.m_clutch:set_float(0.0)

	local accel_button = gear_state.m_is_in_reverse and 72 or 71
	if (self.m_entity:IsEngineOn()) then
		PAD.DISABLE_CONTROL_ACTION(0, accel_button, true)
	end

	if (is_control_pressed_2(accel_button)) then
		if (transmission.m_current_gear:get_byte() == 0) then
			self:SetGear(1)
		end

		local rpm        = transmission.m_rpm:get_float()
		local delta      = Game.GetFrameTime()
		local input_norm = PAD.GET_DISABLED_CONTROL_NORMAL(0, accel_button)
		local target     = 1.05 * input_norm
		rpm              = math.min(1.0, math.lerp(rpm, target, 30.0 * delta))
		transmission.m_rpm:set_float(rpm)
		transmission.m_throttle:set_float(rpm)
		transmission.m_throttle_input:set_float(rpm)
	end
end

---@param gear_state GearSelectState
---@param cvehicle CVehicle
function ManualGearbox:WhileDriving(gear_state, cvehicle)
	local cfg = self:GetConfig()
	if (gear_state.m_is_clutch_pressed or cfg.mode == eManualGearboxType.AUTO) then
		self.m_force_neutral = false
		return
	end

	local vehicle = self.m_entity
	if (vehicle:IsStopped()) then
		self.m_force_neutral = false
		return
	end

	local transmission = cvehicle.m_transmission
	local current_gear = transmission.m_current_gear:get_byte()
	local top_gear     = transmission.m_top_gear:get_byte()
	if (current_gear == 0 or current_gear == top_gear) then
		self.m_force_neutral = false
		return
	end

	local velocity          = vehicle:GetSpeed()
	local gear_max_velocity = transmission:GetMaxSpeedForGear(current_gear)
	self.m_force_neutral    = (PAD.IS_CONTROL_PRESSED(0, 71) and velocity >= gear_max_velocity)
end

---@param gear_state GearSelectState
function ManualGearbox:UpdateDriveState(gear_state)
	local selected = gear_state.m_selected
	if (math.is_inrange(selected, 1, 10)) then
		self.m_drive_state = eGearDriveState.DRIVE
	else
		self.m_drive_state = self:IsInReverse() and eGearDriveState.REVERSE or eGearDriveState.NEUTRAL
	end
end

---@param gear_state GearSelectState
---@param cvehicle CVehicle
function ManualGearbox:HandleGears(gear_state, cvehicle)
	local gearbox_type = self:GetConfig().mode
	if (gearbox_type == eManualGearboxType.AUTO) then
		return
	end

	self:ShiftGears(gear_state)

	local is_sequential     = gearbox_type == eManualGearboxType.SEQUENTIAL or self.m_force_sequential
	local allow_gear_select = is_sequential and true or gear_state.m_is_clutch_pressed
	if (not allow_gear_select) then return end

	if (KeyManager:IsKeybindJustPressed("shift_up")) then
		local next_gear
		if (self:IsInReverse()) then
			next_gear         = 0 -- back to neutral
			self.m_last_input = eGearInputLast.NONE
			cvehicle:SetHandlingFlag(Enums.eVehicleHandlingFlags.NO_REVERSE, true)
		else
			local max_gears   = cvehicle.m_transmission.m_top_gear:get_byte()
			next_gear         = math.min(max_gears, gear_state.m_selected + 1)
			self.m_last_input = eGearInputLast.UPSHIFT
		end

		gear_state.m_selected      = next_gear
		gear_state.m_is_in_reverse = false
		self.m_force_neutral       = false
	end

	if (KeyManager:IsKeybindJustPressed("shift_down")) then
		if (gear_state.m_selected == 0 and self.m_entity:GetSpeedVector().y < 3) then
			gear_state.m_is_in_reverse = true
			cvehicle:SetHandlingFlag(Enums.eVehicleHandlingFlags.NO_REVERSE, false)
		end

		gear_state.m_selected = math.max(0, gear_state.m_selected - 1)
		self.m_force_neutral  = false
		self.m_last_input     = eGearInputLast.DOWNSHIFT
	end
end

---@param gear_state GearSelectState
function ManualGearbox:HandleFwdReverse(gear_state)
	local veh           = self.m_entity
	local is_in_reverse = gear_state.m_is_in_reverse
	local brake_btn     = is_in_reverse and 71 or 72
	local handle        = veh:GetHandle()
	local speed_vec     = veh:GetSpeedVector().y

	if (math.abs(speed_vec) < 1) then
		PAD.DISABLE_CONTROL_ACTION(0, brake_btn, true)
		VEHICLE.SET_VEHICLE_BURNOUT(handle, (is_control_pressed_2(71) and is_control_pressed_2(72)))
	end

	if (PAD.IS_DISABLED_CONTROL_PRESSED(0, brake_btn)) then
		VEHICLE.SET_VEHICLE_BRAKE(handle, true)
	end

	if (is_in_reverse) then
		VEHICLE.SET_VEHICLE_TAIL_LIGHTS(handle, true)
	end
end

function ManualGearbox:Update()
	self:HandleEngineStalling()

	if (self.m_is_single_gear or not self.m_entity:IsValid() or self:GetConfig().mode == eManualGearboxType.AUTO) then
		return
	end

	local gear_state, cvehicle = self.m_gear_state, self.m_cvehicle

	if (KeyManager:IsKeybindPressed("clutch")) then
		self:OnClutchPress(gear_state, cvehicle)
	elseif (KeyManager:IsKeybindJustReleased("clutch")) then
		self:OnClutchRelease(gear_state, cvehicle)
	end

	if (gear_state.m_is_clutch_pressed or self:WantsNeutral()) then
		self:WhileClutchEngaged(gear_state, cvehicle)
	end

	self:WhileDriving(gear_state, cvehicle)
	self:HandleGears(gear_state, cvehicle)
	self:UpdateDriveState(gear_state)
	self:HandleFwdReverse(gear_state)
	self:HandleClutchKick()
	self:HandleKickStart()
end

return ManualGearbox
