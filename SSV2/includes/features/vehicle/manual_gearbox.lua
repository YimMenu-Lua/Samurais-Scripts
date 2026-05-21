-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase    = require("includes.modules.FeatureBase")
local HandlingPreset = require("includes.structs.HandlingPreset")


local eGearboxType <const> = {
	H_PATTERN  = 0,
	SEQUENTIAL = 1
}

---@return boolean
local function is_control_pressed_2(action)
	return (PAD.IS_CONTROL_PRESSED(0, action) or PAD.IS_DISABLED_CONTROL_PRESSED(0, action))
end

---@class GearState
---@field m_current uint8_t
---@field m_next uint8_t
---@field m_selected uint8_t
---@field m_mutated boolean
---@field m_is_clutch_pressed boolean
---@field m_is_in_reverse boolean

---@class ManualGearBox : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_cvehicle CVehicle
---@field private m_state GearState
---@field private m_flag_preset HandlingPreset
---@field private m_clutch_kick { enabled: boolean, rpm: float, timer: Timer }
---@field private m_clutch_kick_duration integer
local ManualGearBox = setmetatable({}, FeatureBase)
ManualGearBox.__index = ManualGearBox

---@param pv PlayerVehicle
---@return ManualGearBox
function ManualGearBox.new(pv)
	local base = FeatureBase.new(pv)
	---@diagnostic disable-next-line
	return setmetatable(base, ManualGearBox)
end

---@return boolean
function ManualGearBox:ShouldRun()
	local veh = self.m_entity
	return GVars.features.vehicle.manual_gearbox.enabled
		and LocalPlayer:IsDriving()
		and veh:IsValid()
		and veh:IsLandVehicle()
		and not veh:IsElectric()
end

function ManualGearBox:Init()
	local clutch_kick_duration  = 400
	self.m_clutch_kick_duration = clutch_kick_duration
	self.m_clutch_kick          = {
		enabled = false,
		rpm     = 0.0,
		timer   = Timer.new(clutch_kick_duration, true),
	}
	self.m_state                = {
		m_current           = 0,
		m_next              = 0,
		m_selected          = 0,
		m_mutated           = false,
		m_is_clutch_pressed = false,
		m_is_in_reverse     = false
	}

	self.m_flag_preset          = HandlingPreset.new({
		name = "Manual Gearbox",
		deltas = {
			[Enums.eHandlingEditorTypes.TYPE_AF] = {
				["GEARBOX_MANUAL"]       = true,
				["GEARBOX_DIRECT_SHIFT"] = false,
				["GEARBOX_FULL_AUTO"]    = false,
				["GEARBOX_ELECTRIC"]     = false,
			},
		},
		vehicle_bitset = 1 << Enums.eVehicleType.VEHICLE_TYPE_CAR | 1 << Enums.eVehicleType.VEHICLE_TYPE_BIKE
	})
end

function ManualGearBox:Reset()
	self.m_state = {
		m_current           = 0,
		m_next              = 0,
		m_selected          = 0,
		m_mutated           = false,
		m_is_clutch_pressed = false,
		m_is_in_reverse     = false,
	}

	self.m_entity.m_flag_controller:TogglePreset(self.m_flag_preset, false)
	local cvehicle = self.m_cvehicle
	if (not cvehicle) then return end

	local pCurrentGear = cvehicle.m_current_gear
	if (pCurrentGear:is_valid() and pCurrentGear:get_byte() > 10) then
		cvehicle.m_current_gear:set_byte(0)
		cvehicle.m_next_gear:set_byte(0)
	end
end

function ManualGearBox:OnNewVehicle()
	if (not self.m_entity:IsValid()) then
		return
	end

	local cvehicle          = self.m_entity:Resolve()
	self.m_cvehicle         = cvehicle
	local current_gear      = cvehicle.m_current_gear:get_byte()
	self.m_state.m_current  = current_gear
	self.m_state.m_selected = current_gear
	self.m_state.m_next     = cvehicle.m_next_gear:get_byte()
	self.m_entity.m_flag_controller:TogglePreset(self.m_flag_preset, true)
end

---@return boolean
function ManualGearBox:IsInReverse()
	return self.m_state.m_is_in_reverse
end

---@return uint8_t
function ManualGearBox:GetCurrentGear()
	return self.m_state.m_selected
end

---@param state GearState
---@param cvehicle CVehicle
function ManualGearBox:ShiftGears(state, cvehicle)
	local gear = state.m_selected
	cvehicle.m_current_gear:set_byte(gear)
	cvehicle.m_next_gear:set_byte(gear)
end

---@param state GearState
---@param cvehicle CVehicle
function ManualGearBox:OnClutchPress(state, cvehicle)
	if (not state.m_mutated) then
		local current_gear        = cvehicle.m_current_gear:get_byte()
		state.m_current           = current_gear
		state.m_next              = cvehicle.m_next_gear:get_byte()
		state.m_mutated           = true
		state.m_is_clutch_pressed = true
	end
end

---@param state GearState
---@param cvehicle CVehicle
function ManualGearBox:OnClutchRelease(state, cvehicle)
	local changed_gears = state.m_mutated
	if (state.m_mutated) then
		state.m_mutated           = false
		state.m_is_clutch_pressed = false
	end

	self:ShiftGears(state, cvehicle)

	if (PAD.IS_CONTROL_PRESSED(0, 71) or PAD.IS_CONTROL_PRESSED(0, 72)) then
		if (self.m_clutch_kick.enabled) then return end

		self.m_clutch_kick.enabled = true
		self.m_clutch_kick.rpm     = cvehicle.m_rpm:get_float()
		self.m_clutch_kick.timer:Reset()
	end
end

function ManualGearBox:HandleClutchKick()
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

---@param state GearState
---@param cvehicle CVehicle
function ManualGearBox:WhileClutchEngaged(state, cvehicle)
	cvehicle.m_current_gear:set_byte(-1) -- underflow to uint8_max, otherwise the vehicle will still move slowly if these are set to 0 (also it will just drive normally in reverse)
	cvehicle.m_next_gear:set_byte(-1) -- //
	cvehicle.m_clutch:set_float(0.0)  -- 0.f: engaged | 1.f: disengaged

	if (PAD.IS_CONTROL_PRESSED(0, 71) or PAD.IS_CONTROL_PRESSED(0, 72)) then
		local rpm = math.lerp(cvehicle.m_rpm:get_float(), 1.0, 0.12)
		cvehicle.m_rpm:set_float(rpm)
		cvehicle.m_throttle:set_float(rpm)
		cvehicle.m_throttle_input:set_float(rpm)
	end
end

---@param state GearState
---@param cvehicle CVehicle
function ManualGearBox:HandleGears(state, cvehicle)
	local gearbox_type      = GVars.features.vehicle.manual_gearbox.mode
	local is_sequential     = gearbox_type == eGearboxType.SEQUENTIAL
	local allow_gear_select = is_sequential and true or state.m_is_clutch_pressed
	if (not allow_gear_select) then return end

	if (KeyManager:IsKeybindJustPressed("shift_up")) then
		local next_gear
		if (self:IsInReverse()) then
			next_gear = -1
		elseif (state.m_selected == -1) then
			next_gear = 1
		else
			local max_gears = cvehicle.m_top_gear:get_byte()
			next_gear = math.min(max_gears, state.m_selected + 1)
		end

		state.m_selected      = next_gear
		state.m_is_in_reverse = false

		if (is_sequential) then
			self:ShiftGears(state, cvehicle)
		end
	end

	if (KeyManager:IsKeybindJustPressed("shift_down")) then
		state.m_selected = math.max(-1, state.m_selected - 1)

		if (state.m_selected == -1 and self.m_entity:IsStopped()) then
			state.m_is_in_reverse = true
			state.m_selected      = 0
		end

		if (is_sequential) then
			self:ShiftGears(state, cvehicle)
		end
	end
end

function ManualGearBox:HandleFwdReverse()
	local veh    = self.m_entity
	local ctrl   = self.m_state.m_is_in_reverse and 71 or 72
	local handle = veh:GetHandle()

	if (veh:GetSpeed() < 1) then
		PAD.DISABLE_CONTROL_ACTION(0, ctrl, true)
		VEHICLE.SET_VEHICLE_BURNOUT(handle, (is_control_pressed_2(71) and is_control_pressed_2(72)))
	end

	if (PAD.IS_DISABLED_CONTROL_PRESSED(0, ctrl)) then
		VEHICLE.SET_VEHICLE_BRAKE(handle, true)
	end
end

---@return boolean
function ManualGearBox:WantsNeutral()
	return not self.m_entity:IsReversing() and self.m_state.m_selected <= 0 or false
end

function ManualGearBox:Update()
	if (not self.m_entity:IsValid()) then return end

	local state, cvehicle = self.m_state, self.m_cvehicle
	if (KeyManager:IsKeybindPressed("clutch")) then
		self:OnClutchPress(state, cvehicle)
	elseif (KeyManager:IsKeybindJustReleased("clutch")) then
		self:OnClutchRelease(state, cvehicle)
	end

	if (state.m_is_clutch_pressed or self:WantsNeutral()) then
		self:WhileClutchEngaged(state, cvehicle)
	end

	self:HandleGears(state, cvehicle)
	self:HandleFwdReverse()
	self:HandleClutchKick()
end

return ManualGearBox
