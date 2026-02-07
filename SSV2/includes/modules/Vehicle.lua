-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


require("includes.modules.Entity")

---@enum eConvertibleRoofState
Enums.eConvertibleRoofState = {
	INVALID  = -1,
	RAISED   = 0,
	LOWERING = 1,
	LOWERED  = 2,
	RAISING  = 3
}

local collisionInvalidModels = Set.new(
	3008087081,
	415536433,
	874602658,
	693843550,
	4189527861,
	1152297372,
	3907562202,
	2954040756,
	1198649884,
	1067874014
)

local towTruckModels <const> = Set.new(
	joaat("towtruck"),
	joaat("towtruck2"),
	joaat("towtruck3"),
	joaat("towtruck4")
)

--------------------------------------
-- Class: Vehicle
--------------------------------------
-- Class representing a GTA V vehicle.
---@class Vehicle : Entity
---@field private m_internal CVehicle
---@field private m_class_id number
---@field private m_num_seats number
---@field private m_max_passengers number
---@field private m_has_loud_radio boolean
---@field private m_last_ram_time seconds
---@field Resolve fun() : CVehicle
---@field Create fun(_, modelHash: joaat_t, entityType: eEntityType, pos?: vec3, heading?: number, isNetwork?: boolean, isScriptHostPed?: boolean): Vehicle
---@overload fun(handle: handle): Vehicle
Vehicle = Class("Vehicle", Entity)

---@return boolean
function Vehicle:IsValid()
	return ENTITY.DOES_ENTITY_EXIST(self:GetHandle()) and ENTITY.IS_ENTITY_A_VEHICLE(self:GetHandle())
end

---@return string
function Vehicle:GetName()
	if not self:IsValid() then
		return ""
	end

	return vehicles.get_vehicle_display_name(self:GetModelHash())
end

---@return string
function Vehicle:GetManufacturerName()
	if not self:IsValid() then
		return ""
	end

	return Game.GetGXTLabel(VEHICLE.GET_MAKE_NAME_FROM_VEHICLE_MODEL(self:GetModelHash()))
end

---@return number
function Vehicle:GetClassID()
	if not self:IsValid() then
		return -1
	end

	return VEHICLE.GET_VEHICLE_CLASS(self:GetHandle())
end

---@return string
function Vehicle:GetClassName()
	local clsid = self:GetClassID()
	if not clsid then
		return "Unknown"
	end

	return EnumToString(Enums.eVehicleClasses, clsid)
end

function Vehicle:GetEngineHealth()
	return VEHICLE.GET_VEHICLE_ENGINE_HEALTH(self:GetHandle())
end

---@return array<handle>
function Vehicle:GetOccupants()
	if not self:IsValid() then
		return {}
	end

	---@type array<handle>
	local passengers = {}
	local handle     = self:GetHandle()
	local max_seats  = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(self:GetModelHash())

	for i = -1, max_seats do
		if not VEHICLE.IS_VEHICLE_SEAT_FREE(handle, i, true) then
			local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(handle, i, false)
			if (ped and ped ~= 0) then
				table.insert(passengers, ped)
			end
		end
	end

	return passengers
end

---@return number
function Vehicle:GetNumberOfPassengers()
	if not self:IsValid() then
		return 0
	end

	if not self.m_max_passengers then
		self.m_max_passengers = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(self:GetHandle())
	end

	return self.m_max_passengers
end

---@return number
function Vehicle:GetNumberOfSeats()
	if not self:IsValid() then
		return 0
	end

	if not self.m_num_seats then
		self.m_num_seats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(self:GetModelHash())
	end

	return self.m_num_seats
end

---@return eLandingGearState
function Vehicle:GetLandingGearState()
	if not (self:IsAircraft() and self:HasLandingGear()) then
		return Enums.eLandingGearState.RETRACTED
	end

	return VEHICLE.GET_LANDING_GEAR_STATE(self:GetHandle())
end

---@return eConvertibleRoofState
function Vehicle:GetConvertibleRoofState()
	if (not self:IsConvertible()) then
		return Enums.eConvertibleRoofState.INVALID
	end

	return VEHICLE.GET_CONVERTIBLE_ROOF_STATE(self:GetHandle())
end

---@return string
function Vehicle:GetRadioStationName()
	if (not self:IsRadioOn()) then
		return "OFF"
	end

	return Game.GetGXTLabel(AUDIO.GET_PLAYER_RADIO_STATION_NAME())
end

---@return boolean
function Vehicle:IsRadioOn()
	return AUDIO.IS_VEHICLE_RADIO_ON(self:GetHandle())
end

---@return boolean
function Vehicle:IsConvertible()
	if (not self:IsCar()) then
		return false
	end

	return VEHICLE.IS_VEHICLE_A_CONVERTIBLE(self:GetHandle(), false)
end

---@param seatIndex number
---@param isTaskRunning? boolean
function Vehicle:IsSeatFree(seatIndex, isTaskRunning)
	if not self:IsValid() then
		return false
	end

	if (isTaskRunning == nil) then
		isTaskRunning = true
	end

	return VEHICLE.IS_VEHICLE_SEAT_FREE(self:GetHandle(), seatIndex, isTaskRunning)
end

---@return boolean
function Vehicle:IsAnySeatFree()
	if not self:IsValid() then
		return false
	end

	return VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(self:GetHandle())
end

---@return boolean
function Vehicle:IsEmpty()
	if not self:IsValid() then
		return false -- ??
	end

	local seats = self:GetNumberOfSeats()

	for i = -1, seats do
		if self:IsSeatFree(i) then
			return false
		end
	end

	return true
end

---@return boolean
function Vehicle:IsLocalPlayerInVehicle()
	return PED.IS_PED_SITTING_IN_VEHICLE(Self:GetHandle(), self:GetHandle())
end

---@return boolean
function Vehicle:IsEnemyVehicle()
	if (not self:IsValid() or self:IsEmpty()) then
		return false
	end

	local occupants = self:GetOccupants()
	for _, passenger in ipairs(occupants) do
		if not ENTITY.IS_ENTITY_DEAD(passenger, false) and Self:IsPedMyEnemy(passenger) then
			return true
		end
	end

	return false
end

---@return boolean
function Vehicle:IsWeaponized()
	return VEHICLE.DOES_VEHICLE_HAVE_WEAPONS(self:GetHandle())
end

---@return boolean
function Vehicle:IsCar()
	if not self:IsValid() then
		return false
	end

	return VEHICLE.IS_THIS_MODEL_A_CAR(self:GetModelHash())
end

---@return boolean
function Vehicle:IsBike()
	if not self:IsValid() then
		return false
	end

	return VEHICLE.IS_THIS_MODEL_A_BIKE(self:GetModelHash())
end

---@return boolean
function Vehicle:IsQuad()
	if not self:IsValid() then
		return false
	end

	local model = self:GetModelHash()

	return (
		VEHICLE.IS_THIS_MODEL_A_QUADBIKE(model) or
		VEHICLE.IS_THIS_MODEL_AN_AMPHIBIOUS_QUADBIKE(model)
	)
end

---@return boolean
function Vehicle:IsPlane()
	if not self:IsValid() then
		return false
	end

	return VEHICLE.IS_THIS_MODEL_A_PLANE(self:GetModelHash())
end

---@return boolean
function Vehicle:IsHeli()
	if not self:IsValid() then
		return false
	end

	return VEHICLE.IS_THIS_MODEL_A_HELI(self:GetModelHash())
end

---@return boolean
function Vehicle:IsBoat()
	if not self:IsValid() then
		return false
	end

	local model = self:GetModelHash()
	return VEHICLE.IS_THIS_MODEL_A_BOAT(model) or VEHICLE.IS_THIS_MODEL_A_JETSKI(model)
end

---@return boolean
function Vehicle:IsSubmersible()
	if not self:IsValid() then
		return false
	end

	return VEHICLE.IS_THIS_MODEL_AN_AMPHIBIOUS_CAR(self:GetModelHash())
end

---@return boolean
function Vehicle:IsBicycle()
	if not self:IsValid() then
		return false
	end

	return VEHICLE.IS_THIS_MODEL_A_BICYCLE(self:GetModelHash())
end

---@return boolean
function Vehicle:IsLandVehicle()
	return self:IsCar() or self:IsQuad() or self:IsBike()
end

---@return boolean
function Vehicle:IsAircraft()
	return self:IsPlane() or self:IsHeli()
end

---@return boolean
function Vehicle:IsDriveable()
	return VEHICLE.IS_VEHICLE_DRIVEABLE(self:GetHandle(), false)
end

---@return boolean
function Vehicle:IsEngineOn()
	return VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(self:GetHandle())
end

---@return boolean
function Vehicle:IsStopped()
	return VEHICLE.IS_VEHICLE_STOPPED(self:GetHandle())
end

---@return boolean
function Vehicle:IsMoving()
	return not self:IsStopped()
end

---@param ped handle
---@return boolean
function Vehicle:IsPedInVehicle(ped)
	return PED.IS_PED_SITTING_IN_VEHICLE(ped, self:GetHandle())
end

---@return boolean
function Vehicle:HasABS()
	return self:GetModelFlag(Enums.eVehicleModelFlags.ABS_STD)
end

---@return boolean
function Vehicle:HasLandingGear()
	return VEHICLE.GET_VEHICLE_HAS_LANDING_GEAR(self:GetHandle())
end

---@return boolean
function Vehicle:HasCustomTyres()
	if (not self:IsValid()) then
		return false
	end

	return VEHICLE.GET_VEHICLE_MOD_VARIATION(self:GetHandle(), 23) ~= 0
end

---@return boolean
function Vehicle:HasWheelDrawData()
	if (not self:IsValid()) then
		return false
	end

	return self:Resolve():HasWheelDrawData()
end

function Vehicle:HasCrashed()
	if (not self:HasCollidedWithAnything()) then
		return false, ""
	end

	local handle = self:GetHandle()
	local last = ENTITY.GET_LAST_ENTITY_HIT_BY_ENTITY_(handle)

	if (not last or (last == 0) or not ENTITY.DOES_ENTITY_EXIST(last)) then
		return false, ""
	end

	if (not ENTITY.IS_ENTITY_A_PED(last)
			and not ENTITY.IS_ENTITY_A_VEHICLE(last)
			and not ENTITY.IS_ENTITY_AN_OBJECT(last)
		) then
		return true, "Samir, you're breaking the car!"
	end

	local entity_type = Memory:GetEntityModelType(last)

	if (entity_type == Enums.eModelType.Invalid) then
		return false, ""
	elseif (entity_type == Enums.eModelType.Ped) then
		return false, "Hit and run"
	elseif (entity_type == Enums.eModelType.Vehicle) then
		return true, "Samir, you're breaking the car!"
	elseif (entity_type == Enums.eModelType.Object or entity_type == Enums.eModelType.Destructible) then
		if (ENTITY.DOES_ENTITY_HAVE_PHYSICS(last)) then
			local model = ENTITY.GET_ENTITY_MODEL(last)
			if collisionInvalidModels:Contains(model) then
				return true, "Samir, you're breaking the car!"
			end
			return false, "Wrecking ball"
		else
			return true, "Samir, you're breaking the car!"
		end
	else
		return false, ""
	end
end

---@return boolean
function Vehicle:IsSports()
	return self:GetModelInfoFlag(Enums.eVehicleModelInfoFlags.SPORTS)
end

---@return boolean
function Vehicle:IsSportsOrSuper()
	if not self:IsValid() then
		return false
	end

	local handle = self:GetHandle()
	return (
		VEHICLE.GET_VEHICLE_CLASS(handle) == 4 or
		VEHICLE.GET_VEHICLE_CLASS(handle) == 6 or
		VEHICLE.GET_VEHICLE_CLASS(handle) == 7 or
		VEHICLE.GET_VEHICLE_CLASS(handle) == 22
	)
end

-- ## TODO: fix this
---@return boolean
function Vehicle:IsPerformanceCar()
	if (not self:IsCar()) then
		return false
	end

	local cls = self:GetClassID()
	if (cls == Enums.eVehicleClasses.Sports or cls == Enums.eVehicleClasses.Super) then
		return true
	end

	-- local allowedClasses <const> = {
	-- 	eVehicleClasses.Sedans,
	-- 	eVehicleClasses.SUVs,
	-- 	eVehicleClasses.Coupes,
	-- 	eVehicleClasses.Muscle,
	-- 	eVehicleClasses.OpenWheel,
	-- }

	-- if (not allowedClasses[cls]) then
	-- 	return false
	-- end

	-- local cvehicle = self:Resolve()
	-- if (not cvehicle) then
	-- 	return false
	-- end

	-- local drive_force = cvehicle.m_initial_drive_force:get_float()
	-- local flat_velocity = cvehicle.m_drive_max_flat_velocity:get_float()
	-- local dummyHP = drive_force * flat_velocity
	-- -- local p2w = (drive_force * 1000) / cvehicle.m_mass:get_float()
	-- -- if (p2w < 0.1) then
	-- --     return false
	-- -- end
	-- -- print(dummyHP)
	-- if (dummyHP < 10) then
	-- 	return false
	-- end

	-- local perf = (drive_force * 100)
	-- 	+ (cvehicle.m_initial_drive_max_flat_vel:get_float() * 0.5)
	-- 	+ (cvehicle.m_traction_curve_max:get_float() * 14)
	-- 	- (cvehicle.m_initial_drag_coeff:get_float() * 10)
	-- 	- (cvehicle.m_mass:get_float() * 0.005)

	-- return perf >= 70.0
	return false
end

---@return boolean
function Vehicle:IsFlatbedTruck()
	return self:GetModelHash() == 1353720154
end

---@return boolean
function Vehicle:IsTowTruck()
	return towTruckModels:Contains(self:GetModelHash())
end

-- Returns whether the vehicle is a pubic hair shaver.
---@return boolean
function Vehicle:IsElectric()
	return self:GetModelInfoFlag(Enums.eVehicleModelInfoFlags.IS_ELECTRIC)
end

-- Returns whether the vehicle is an F1 race car.
---@return boolean
function Vehicle:IsFormulaOne()
	return self:GetModelInfoFlag(Enums.eVehicleModelInfoFlags.IS_FORMULA_VEHICLE)
		or (self:GetClassID() == Enums.eVehicleClasses.OpenWheel)
end

-- Returns whether the vehicle is a lowrider equipped with hydraulic suspension.
---@return boolean
function Vehicle:IsLowrider()
	return self:GetModelInfoFlag(Enums.eVehicleModelInfoFlags.HAS_LOWRIDER_HYDRAULICS)
		or self:GetModelInfoFlag(Enums.eVehicleModelInfoFlags.HAS_LOWRIDER_DONK_HYDRAULICS)
end

---@return boolean
function Vehicle:IsLocked()
	return VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(self:GetHandle()) > 1
end

---@param wheelIndex integer
---@return boolean
function Vehicle:IsWheelBrokenOff(wheelIndex)
	if (not self:IsValid() or type(wheelIndex) ~= "number") then
		return false
	end

	return self:Resolve():IsWheelBrokenOff(wheelIndex)
end

---@param refresh? boolean
---@return CWheelDrawData
function Vehicle:GetWheelDrawData(refresh)
	return self:Resolve():GetWheelDrawData(refresh)
end

---@return float -- Wheel width or 0.f if invalid
function Vehicle:GetVisualWheelWidth()
	return self:Resolve():GetWheelWidth()
end

---@return float -- Wheel size or 0.f if invalid
function Vehicle:GetVisualWheelSize()
	return self:Resolve():GetWheelSize()
end

---@param fValue float
function Vehicle:SetVisualWheelWidth(fValue)
	if (not self:HasWheelDrawData()) then
		return
	end

	self:Resolve():SetWheelWidth(fValue)
end

---@param fValue float
function Vehicle:SetVisualWheelSize(fValue)
	if (not self:HasWheelDrawData()) then
		return
	end

	self:Resolve():SetWheelSize(fValue)
end

function Vehicle:ClearPrimaryTask()
	TASK.CLEAR_PRIMARY_VEHICLE_TASK(self:GetHandle())
end

function Vehicle:Clean()
	if not self:IsValid() then
		return
	end

	VEHICLE.SET_VEHICLE_DIRT_LEVEL(self:GetHandle(), 0.0)
end

---@param reset_dirt? bool
function Vehicle:Repair(reset_dirt)
	if not self:IsValid() then
		return
	end

	local handle = self:GetHandle()
	VEHICLE.SET_VEHICLE_FIXED(handle)
	VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(handle)

	if (reset_dirt) then
		self:Clean()
	end

	local pWaterDamage = self:Resolve().m_water_damage
	if pWaterDamage:is_null() then
		return
	end

	local damage_bits = pWaterDamage:get_int()
	if (type(damage_bits) == "number") then
		pWaterDamage:set_int(Bit.clear(damage_bits, 0))
	end
end

-- Maximizes the vehicle's performance mods, repairs and cleans it.
function Vehicle:MaxPerformance()
	local handle = self:GetHandle()

	if not self:IsValid()
		or not VEHICLE.IS_VEHICLE_DRIVEABLE(handle, false)
		or not ENTITY.IS_ENTITY_A_VEHICLE(handle) then
		return
	end

	local function SetPlatformAppropriateMod(modType, modIndex)
		if (Backend:GetAPIVersion() == Enums.eAPIVersion.V1) then
			while VEHICLE.IS_VEHICLE_MOD_GEN9_EXCLUSIVE(handle, modType, modIndex) do
				modIndex = modIndex - 1
				yield()
			end
		end

		VEHICLE.SET_VEHICLE_MOD(handle, modType, modIndex, false)
	end

	local maxArmor = VEHICLE.GET_NUM_VEHICLE_MODS(handle, 16) - 1
	SetPlatformAppropriateMod(16, maxArmor)

	local maxEngine = VEHICLE.GET_NUM_VEHICLE_MODS(handle, 11) - 1
	SetPlatformAppropriateMod(11, maxEngine)

	local maxBrakes = VEHICLE.GET_NUM_VEHICLE_MODS(handle, 12) - 1
	SetPlatformAppropriateMod(12, maxBrakes)

	local maxTrans = VEHICLE.GET_NUM_VEHICLE_MODS(handle, 13) - 1
	SetPlatformAppropriateMod(13, maxTrans)

	local maxSusp = VEHICLE.GET_NUM_VEHICLE_MODS(handle, 15) - 1
	SetPlatformAppropriateMod(15, maxSusp)

	VEHICLE.TOGGLE_VEHICLE_MOD(handle, 18, true)
	VEHICLE.TOGGLE_VEHICLE_MOD(handle, 22, true)
	self:Repair(true)
end

---@param toggle boolean
function Vehicle:LockDoors(toggle)
	if (not self:IsValid()) then
		return
	end

	local handle = self:GetHandle()
	if (not self:IsCar() or not entities.take_control_of(handle, 300)) then
		return
	end

	if (toggle) then
		for i = 0, (VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(handle) + 1) do
			if VEHICLE.GET_VEHICLE_DOOR_ANGLE_RATIO(handle, i) > 0.0 then
				VEHICLE.SET_VEHICLE_DOORS_SHUT(handle, false)
				break
			end
		end

		if (self:IsConvertible() and self:GetConvertibleRoofState() ~= 0) then
			VEHICLE.RAISE_CONVERTIBLE_ROOF(handle, false)
		else
			for i = 0, 7 do
				VEHICLE.ROLL_UP_WINDOW(handle, i)
			end
		end
	end

	VEHICLE.SET_VEHICLE_DOORS_LOCKED(handle, toggle and 2 or 1)
	if (self:IsLocalPlayerInVehicle()) then
		return
	end

	local engineWasRunning = VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(handle)
	if (not engineWasRunning) then
		VEHICLE.SET_VEHICLE_ENGINE_ON(handle, true, true, false)
	end
	VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(handle, 0, true)
	VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(handle, 1, true)
	sleep(150)
	if (not engineWasRunning) then
		VEHICLE.SET_VEHICLE_ENGINE_ON(handle, false, true, false)
	end

	AUDIO.SET_HORN_PERMANENTLY_ON_TIME(handle, 1000)
	AUDIO.SET_HORN_PERMANENTLY_ON(handle)
	VEHICLE.SET_VEHICLE_ALARM(handle, toggle)
	sleep(696)
	VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(handle, 0, false)
	VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(handle, 1, false)
end

function Vehicle:CloseDoors()
	if (not self:IsValid()) then
		return
	end

	local handle = self:GetHandle()
	for i = 0, VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(handle) + 1 do
		if (VEHICLE.GET_IS_DOOR_VALID(handle, i) and VEHICLE.GET_VEHICLE_DOOR_ANGLE_RATIO(handle, i) > 0) then
			VEHICLE.SET_VEHICLE_DOOR_SHUT(handle, i, false)
		end
	end
end

---@return number
function Vehicle:GetMaxSpeed()
	if not self:IsValid() then
		return 0
	end
	return VEHICLE.GET_VEHICLE_ESTIMATED_MAX_SPEED(self:GetHandle())
end

-- Gets the vehicle's acceleration multiplier.
---@return float
function Vehicle:GetAcceleration()
	if not self:IsValid() then
		return 0.0
	end

	return self:Resolve():GetAcceleration()
end

-- Sets the vehicle's acceleration multiplier.
---@param multiplier float
function Vehicle:SetAcceleration(multiplier)
	if not (self:IsValid() and (type(multiplier) == "number")) then
		return
	end

	self:Resolve():SetAcceleration(multiplier)
end

-- Gets the vehicle's deformation multiplier.
---@return float|nil
function Vehicle:GetDeformation()
	if not self:IsValid() then
		return
	end

	return self:Resolve():GetDeformMultiplier()
end

-- Sets the vehicle's deformation multiplier.
---@param multiplier float
function Vehicle:SetDeformation(multiplier)
	if not (self:IsValid() and type(multiplier) == "number") then
		return
	end

	self:Resolve():SetDeformMultiplier(multiplier)
end

---@return table
function Vehicle:GetExhaustBones()
	local handle = self:GetHandle()

	if not self:IsValid() then
		return {}
	end

	local bones   = {}
	local count   = VEHICLE.GET_VEHICLE_MAX_EXHAUST_BONE_COUNT_() -
		1 -- all vehicles have an additional exhaust bone sticking out of the top of the engine.
	local bParam  = false
	local boneIdx = -1

	for i = 0, count do
		bParam, boneIdx = VEHICLE.GET_VEHICLE_EXHAUST_BONE_(handle, i, boneIdx, bParam)
		if bParam then
			table.insert(bones, boneIdx)
		end
	end

	return bones
end

function Vehicle:GetColors()
	local handle = self:GetHandle()
	local col1 = { r = 0, g = 0, b = 0 }
	local col2 = { r = 0, g = 0, b = 0 }

	if not self:IsValid() then
		return col1, col2
	end

	if VEHICLE.GET_IS_VEHICLE_PRIMARY_COLOUR_CUSTOM(handle) then
		col1.r, col1.g, col1.b = VEHICLE.GET_VEHICLE_CUSTOM_PRIMARY_COLOUR(
			handle,
			col1.r,
			col1.g,
			col1.b
		)
	else
		col1.r, col1.g, col1.b = VEHICLE.GET_VEHICLE_COLOR(
			handle,
			col1.r,
			col1.g,
			col1.b
		)
	end

	if VEHICLE.GET_IS_VEHICLE_SECONDARY_COLOUR_CUSTOM(handle) then
		col2.r, col2.g, col2.b = VEHICLE.GET_VEHICLE_CUSTOM_SECONDARY_COLOUR(
			handle,
			col2.r,
			col2.g,
			col2.b
		)
	else
		col2.r, col2.g, col2.b = VEHICLE.GET_VEHICLE_COLOR(
			handle,
			col2.r,
			col2.g,
			col2.b
		)
	end

	return col1, col2
end

---@return { type: integer, index: integer, var: integer }
function Vehicle:GetCustomWheels()
	if not self:IsValid() then
		return {}
	end

	local handle = self:GetHandle()
	local wheels = {}
	wheels.type  = VEHICLE.GET_VEHICLE_WHEEL_TYPE(handle)
	wheels.index = VEHICLE.GET_VEHICLE_MOD(handle, 23)
	wheels.var   = VEHICLE.GET_VEHICLE_MOD_VARIATION(handle, 23)

	return wheels
end

function Vehicle:SetCustomWheels(tWheelData)
	if not self:IsValid() or not tWheelData then
		return
	end

	local handle = self:GetHandle()

	if tWheelData.type then
		VEHICLE.SET_VEHICLE_WHEEL_TYPE(handle, tWheelData.type)
	end

	if tWheelData.index then
		VEHICLE.SET_VEHICLE_MOD(handle, 23, tWheelData.index, (tWheelData.var and tWheelData.var == 1))
	end
end

---@return table
function Vehicle:GetWindowStates()
	local t = {}

	for i = 1, 4 do
		t[i] = VEHICLE.IS_VEHICLE_WINDOW_INTACT(self:GetHandle(), i - 1)
	end

	return t
end

---@return table
function Vehicle:GetToggleMods()
	local t = {}

	for i = 17, 22 do
		t[i] = VEHICLE.IS_TOGGLE_MOD_ON(self:GetHandle(), i)
	end

	return t
end

---@return table
function Vehicle:GetNeonLights()
	local handle = self:GetHandle()
	local bHasNeonLights = false
	local neon = {
		enabled = {},
		color = { r = 0, g = 0, b = 0 }
	}

	for i = 1, 4 do
		local isEnabled = VEHICLE.GET_VEHICLE_NEON_ENABLED(handle, i - 1)
		neon.enabled[i] = isEnabled
		if isEnabled then
			bHasNeonLights = true
		end
	end

	if bHasNeonLights then
		neon.color.r,
		neon.color.g,
		neon.color.b = VEHICLE.GET_VEHICLE_NEON_COLOUR(
			handle,
			neon.color.r,
			neon.color.g,
			neon.color.b
		)
	end

	return neon
end

---@param tNeonData table
function Vehicle:SetNeonLights(tNeonData)
	if not tNeonData then
		return
	end

	local handle = self:GetHandle()
	for i = 0, 3 do
		VEHICLE.SET_VEHICLE_NEON_ENABLED(handle, i, tNeonData.enabled[i])
	end

	VEHICLE.SET_VEHICLE_NEON_COLOUR(
		handle,
		tNeonData.color.r,
		tNeonData.color.g,
		tNeonData.color.b
	)
end

---@return VehicleMods
function Vehicle:GetMods()
	local handle = self:GetHandle()

	if not self:IsValid() then
		return {}
	end

	local _mods = {}
	for i = 0, 49 do
		table.insert(_mods, VEHICLE.GET_VEHICLE_MOD(handle, i))
	end

	local window_tint = VEHICLE.GET_VEHICLE_WINDOW_TINT(handle)
	local plate_text = VEHICLE.GET_VEHICLE_NUMBER_PLATE_TEXT(handle)
	local col1, col2 = self:GetColors()
	local wheels = self:GetCustomWheels()

	local struct = VehicleMods.create(
		_mods,
		col1,
		col2,
		wheels,
		window_tint,
		plate_text
	)

	struct.window_states = self:GetWindowStates()
	struct.toggle_mods = self:GetToggleMods()
	struct.neon = self:GetNeonLights()

	if struct.toggle_mods[20] then
		local r, g, b = 0, 0, 0
		r, g, b = VEHICLE.GET_VEHICLE_TYRE_SMOKE_COLOR(handle, r, g, b)
		struct.tyre_smoke_color = { r = r, g = g, b = b }
	end

	if struct.toggle_mods[22] then
		struct.xenon_color = VEHICLE.GET_VEHICLE_XENON_LIGHT_COLOR_INDEX(handle)
	end

	if VEHICLE.GET_VEHICLE_LIVERY_COUNT(handle) > 0 then
		struct.livery = VEHICLE.GET_VEHICLE_LIVERY(handle)
	end

	if VEHICLE.GET_VEHICLE_LIVERY2_COUNT(handle) > 0 then
		struct.livery2 = VEHICLE.GET_VEHICLE_LIVERY2(handle)
	end

	local pInt1, pInt2, pInt3, pInt4 = 0, 0, 0, 0
	struct.pearlescent_color, struct.wheel_color = VEHICLE.GET_VEHICLE_EXTRA_COLOURS(handle, pInt1, pInt2)

	VEHICLE.GET_VEHICLE_EXTRA_COLOUR_5(handle, pInt3)
	VEHICLE.GET_VEHICLE_EXTRA_COLOUR_6(handle, pInt4)
	struct.interior_color = pInt3
	struct.dashboard_color = pInt4

	return struct
end

---@param modType number
---@param index number
---@return boolean
function Vehicle:PreloadMod(modType, index)
	local handle = self:GetHandle()
	if not self:IsValid() then
		return false
	end

	VEHICLE.PRELOAD_VEHICLE_MOD(handle, modType, index)
	while not VEHICLE.HAS_PRELOAD_MODS_FINISHED(handle) do
		yield()
	end
	return VEHICLE.HAS_PRELOAD_MODS_FINISHED(handle)
end

---@param tModData VehicleMods
function Vehicle:ApplyMods(tModData)
	local handle = self:GetHandle()
	if not self:IsValid() then
		return
	end

	ThreadManager:Run(function()
		VEHICLE.SET_VEHICLE_MOD_KIT(handle, 0)

		if tModData.mods then
			for slot, mod in ipairs(tModData.mods) do
				if (mod ~= -1 and self:PreloadMod((slot - 1), mod)) then
					VEHICLE.SET_VEHICLE_MOD(handle, (slot - 1), mod, true)
				end
			end
			VEHICLE.RELEASE_PRELOAD_MODS(handle)
		end

		if tModData.primary_color then
			VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(
				handle,
				tModData.primary_color.r,
				tModData.primary_color.g,
				tModData.primary_color.b
			)
		end

		if tModData.secondary_color then
			VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(
				handle,
				tModData.secondary_color.r,
				tModData.secondary_color.g,
				tModData.secondary_color.b
			)
		end

		if tModData.window_tint then
			VEHICLE.SET_VEHICLE_WINDOW_TINT(handle, tModData.window_tint)
		end

		if tModData.toggle_mods then
			for i = 17, 22 do
				VEHICLE.TOGGLE_VEHICLE_MOD(handle, i, tModData.toggle_mods[i])
			end

			if tModData.toggle_mods[20] then
				local col = tModData.tyre_smoke_color
				if col and col.r and col.g and col.b then
					VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(handle, col.r, col.g, col.b)
				end
			end

			if tModData.toggle_mods[22] and tModData.xenon_color then
				VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(handle, tModData.xenon_color)
			end
		end

		if tModData.window_states then
			for i = 1, #tModData.window_states do
				local callback = tModData.window_states[i] and VEHICLE.ROLL_UP_WINDOW or VEHICLE.ROLL_DOWN_WINDOW
				callback(handle, i - 1)
			end
		end

		if tModData.plate_text and type(tModData.plate_text) == "string" and #tModData.plate_text > 0 then
			VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(handle, tModData.plate_text)
		end

		if tModData.livery then
			VEHICLE.SET_VEHICLE_LIVERY(handle, tModData.livery)
		end

		if tModData.livery2 then
			VEHICLE.SET_VEHICLE_LIVERY2(handle, tModData.livery2)
		end

		if tModData.wheels then
			self:SetCustomWheels(tModData.wheels)
		end

		if tModData.pearlescent_color and tModData.wheel_color then
			VEHICLE.SET_VEHICLE_EXTRA_COLOURS(handle, tModData.pearlescent_color, tModData.wheel_color)
		end

		if tModData.interior_color then
			VEHICLE.SET_VEHICLE_EXTRA_COLOUR_5(handle, tModData.interior_color)
		end

		if tModData.dashboard_color then
			VEHICLE.SET_VEHICLE_EXTRA_COLOUR_6(handle, tModData.dashboard_color)
		end

		if tModData.neon then
			self:SetNeonLights(tModData.neon)
		end
	end)
end

---@param opts? { spawn_pos?: vec3, warp_into?: boolean }
function Vehicle:Clone(opts)
	if not self:IsValid() then
		return
	end

	opts = opts or {}
	local pos = opts.spawn_pos or self:GetSpawnPosInFront()
	local clone = Vehicle:Create(self:GetModelHash(), Enums.eEntityType.Vehicle, pos)
	local tModData = self:GetMods()

	if clone:IsValid() then
		if next(tModData) ~= nil then
			clone:ApplyMods(tModData)
		end

		clone:SetAsNoLongerNeeded()
		if (opts.warp_into == true) then -- Some idiot passed a vector3 and kept wondering why they were being teleported into the vehicle. Don't ask who the idiot is.
			clone:WarpPed(Self:GetHandle(), -1)
		end
	end

	return clone
end

---@param ped_handle number
---@param seatIndex? number
function Vehicle:WarpPed(ped_handle, seatIndex)
	if not (self:IsValid() or ENTITY.DOES_ENTITY_EXIST(ped_handle)) then
		return
	end

	seatIndex = seatIndex or -1
	if not self:IsSeatFree(seatIndex, true) then
		seatIndex = -2
	end

	PED.SET_PED_INTO_VEHICLE(ped_handle, self:GetHandle(), seatIndex)
end

---@param step integer 1 next seat|-1 previous seat
function Vehicle:ShuffleSeats(step)
	ThreadManager:Run(function()
		if not self:IsLocalPlayerInVehicle() then
			return
		end

		if not self:IsAnySeatFree() then
			return
		end

		local maxSeats = self:GetNumberOfPassengers()
		local currentSeat = Self:GetVehicleSeat()

		if (not currentSeat or maxSeats == 0) then
			return
		end

		local attempts  = 0
		local seatIndex = currentSeat

		while attempts < maxSeats do
			seatIndex = seatIndex + step

			if seatIndex > maxSeats then
				seatIndex = 1
			elseif seatIndex < 1 then
				seatIndex = maxSeats
			end

			if self:IsSeatFree(seatIndex) then
				PED.SET_PED_INTO_VEHICLE(Self:GetHandle(), self:GetHandle(), seatIndex)
				return
			end

			attempts = attempts + 1
			yield()
		end
	end)
end

-- Must be called on tick. If you want a one-shot thing, use `Vehicle:SetAcceleration` instead.
---@param value number speed modifier
function Vehicle:ModifyTopSpeed(value)
	if not Self:IsValid() then
		return
	end

	VEHICLE.MODIFY_VEHICLE_TOP_SPEED(self:GetHandle(), value)
end

-- Returns whether a handling flag is enabled.
---@param flag eVehicleHandlingFlags
---@return boolean
function Vehicle:GetHandlingFlag(flag)
	if not self:IsValid() then
		return false
	end

	return self:Resolve():GetHandlingFlag(flag)
end

-- Enables/disables a vehicle's handling flag.
---@param flag eVehicleHandlingFlags
---@param toggle boolean
function Vehicle:SetHandlingFlag(flag, toggle)
	if not self:IsValid() then
		return
	end

	self:Resolve():SetHandlingFlag(flag, toggle)
end

-- Returns whether a model flag is enabled.
---@param flag eVehicleModelFlags
function Vehicle:GetModelFlag(flag)
	if not self:IsValid() then
		return false
	end

	return self:Resolve():GetModelFlag(flag)
end

-- Returns whether a model info flag is enabled **(not the same as model flags)**.
---@param flag eVehicleModelInfoFlags
---@return boolean
function Vehicle:GetModelInfoFlag(flag)
	if not self:IsValid() then
		return false
	end

	return self:Resolve():GetModelInfoFlag(flag)
end

-- Enables/disables a vehicle's model info flag.
---@param flag eVehicleModelInfoFlags
---@param toggle boolean
function Vehicle:SetModelInfoFlag(flag, toggle)
	if not self:IsValid() then
		return
	end

	self:Resolve():SetModelInfoFlag(flag, toggle)
end

-- Returns whether an advanced flag is enabled.
---@param flag eVehicleAdvancedFlags
---@return boolean
function Vehicle:GetAdvancedFlag(flag)
	if (not self:IsValid() or not self:IsCar()) then
		return false
	end

	return self:Resolve():GetAdvancedFlag(flag)
end

-- Enables/disables a vehicle's advanced flag.
---@param flag eVehicleAdvancedFlags
---@param toggle boolean
function Vehicle:SetAdvancedFlag(flag, toggle)
	if (not self:IsValid() or not self:IsCar()) then
		return
	end

	self:Resolve():SetAdvancedFlag(flag, toggle)
end

---@param fHeight float positive = lower, negative = higher. should use values between `-0.1` and `0.1`
function Vehicle:SetRideHeight(fHeight)
	if (not self:IsValid()) then
		return
	end

	-- should probably start sanitizing values before writing to memory
	self:Resolve():SetRideHeight(fHeight)
end

---@param bone_index number
---@return fMatrix44
function Vehicle:GetBoneMatrix(bone_index)
	if not self:IsValid() then
		return fMatrix44:zero()
	end

	return self:Resolve():GetBoneMatrix(bone_index)
end

---@param bone_index number
---@param matrix fMatrix44
function Vehicle:SetBoneMatrix(bone_index, matrix)
	if not self:IsValid() then
		return
	end

	self:Resolve():SetBoneMatrix(bone_index, matrix)
end

---@return CBaseSubHandlingData|any
function Vehicle:GetHandlingData()
	if (not self:IsValid()) then
		return nil
	end
	local handlingType = Enums.eHandlingType.CAR

	-- this is bad but whatever
	if (self:IsBike()) then
		handlingType = Enums.eHandlingType.BIKE
	elseif self:IsPlane() or self:IsHeli() then
		handlingType = Enums.eHandlingType.FLYING
	end

	return self:Resolve():GetSubHandlingData(handlingType)
end

---@return integer
function Vehicle:GetMaxPassengers()
	return VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(self:GetHandle())
end

---@return integer
function Vehicle:GetNumberOfWheels()
	if (not self:IsValid()) then
		return 0
	end

	return self:Resolve().m_num_wheels
end

---@param atIndex integer
---@return CWheel?
function Vehicle:GetWheel(atIndex)
	if (not self:IsValid()) then
		return
	end

	return self:Resolve():GetWheel(atIndex)
end

---@param seatIndex integer
---@param atGetIn? boolean
---@return handle
function Vehicle:GetPedInSeat(seatIndex, atGetIn)
	if (seatIndex > self:GetMaxPassengers()) then
		log.warning("[Vehicle]: Seat index out of bounds.")
		return 0
	end

	return VEHICLE.GET_PED_IN_VEHICLE_SEAT(self:GetHandle(), seatIndex, atGetIn or false)
end

-- Applies a custom paint job to the vehicle
---@param hex string Hexadecimal color string
---@param p integer Pearlescent index
---@param m boolean Matte color
---@param is_primary boolean
---@param is_secondary boolean
function Vehicle:SetCustomPaint(hex, p, m, is_primary, is_secondary)
	script.run_in_fiber(function()
		if (not self:Exists()) then
			return
		end

		local pt = m and 3 or 1
		local r, g, b, _ = Color(hex):AsRGBA()
		local handle = self:GetHandle()
		VEHICLE.SET_VEHICLE_MOD_KIT(handle, 0)

		if (is_primary) then
			VEHICLE.SET_VEHICLE_MOD_COLOR_1(handle, pt, 0, p)
			VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(handle, r, g, b)
			VEHICLE.SET_VEHICLE_EXTRA_COLOURS(handle, p, 0)
		end

		if is_secondary then
			VEHICLE.SET_VEHICLE_MOD_COLOR_2(handle, pt, 0)
			VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(handle, r, g, b)
		end
	end)
end

---@param targetEntity integer
---@param enemiesOnly? boolean
function Vehicle:ShootAtTarget(targetEntity, enemiesOnly)
	if (not self:IsWeaponized()) then
		return
	end

	if (not ENTITY.DOES_ENTITY_EXIST(targetEntity)
			or ENTITY.IS_ENTITY_DEAD(targetEntity, false)
			or ENTITY.IS_ENTITY_AN_OBJECT(targetEntity)) then
		return
	end

	local targetCoords = ENTITY.GET_ENTITY_COORDS(targetEntity, true)
	local playerHandle = Self:GetHandle()
	local isEnemy = (ENTITY.IS_ENTITY_A_PED(targetEntity) and Self:IsPedMyEnemy(targetEntity))
		or (ENTITY.IS_ENTITY_A_VEHICLE(targetEntity) and Vehicle(targetEntity):IsEnemyVehicle())

	if (enemiesOnly and not isEnemy) then
		return
	end

	VEHICLE.SET_VEHICLE_SHOOT_AT_TARGET(
		playerHandle,
		targetEntity,
		targetCoords.x,
		targetCoords.y,
		targetCoords.z
	)
end

---@param coords vec3
---@param opts? { speed?: number, drivingFlags?: eDrivingFlags, cruiseAltitude?: number, landAtDestination: boolean } optional parameters
function Vehicle:GoTo(coords, opts)
	if (not self:IsValid()) then
		return
	end

	if (self:IsBoat()) then
		-- requires PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS so Im skipping it for now
		return
	end

	opts = opts or {}
	local driver = self:GetPedInSeat(-1)
	if (not Game.IsScriptHandle(driver)) then
		return
	end

	self:ClearPrimaryTask()
	TASK.CLEAR_PED_TASKS(driver)
	TASK.CLEAR_PED_SECONDARY_TASK(driver)

	if (self:IsLandVehicle()) then
		local speed = opts.speed or 25
		local flags = opts.drivingFlags or 786603
		TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(
			driver,
			self:GetHandle(),
			coords.x,
			coords.y,
			coords.z,
			speed,
			flags,
			25
		)
	elseif (self:IsPlane()) then
		local cruiseAltitude = opts.cruiseAltitude or 800
		TASK.TASK_PLANE_MISSION(
			driver,
			self:GetHandle(),
			0,
			0,
			coords.x,
			coords.y,
			coords.z + cruiseAltitude,
			4,
			100.0,
			0.0,
			90.0,
			5000,
			200.0,
			true
		)
	elseif (self:IsHeli()) then
		local landOnArrival = opts.landAtDestination or false
		TASK.TASK_HELI_MISSION(
			driver,
			self:GetHandle(),
			0,
			0,
			coords.x,
			coords.y,
			coords.z,
			4,
			self:GetMaxSpeed(),
			4.0,
			-1,
			-1,
			100,
			100.0,
			landOnArrival and 32 or 0
		)
	end
end

---@param opts? { speed?: number, drivingFlags?: eDrivingFlags } optional parameters
function Vehicle:Wander(opts)
	if (not self:IsValid() or not self:IsLandVehicle()) then
		return
	end

	opts = opts or {}
	local driver = self:GetPedInSeat(-1)
	if (not Game.IsScriptHandle(driver)) then
		return
	end

	TASK.TASK_VEHICLE_DRIVE_WANDER(
		driver,
		self:GetHandle(),
		opts.speed or 20,
		opts.drivingFlags or 786603
	)
end

function Vehicle:RamForward()
	if (not self:IsValid()
			or not self:IsCar()
			or not VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(self:GetHandle())
		) then
		return
	end

	self.m_last_ram_time = self.m_last_ram_time or 0
	if (Time.now() - self.m_last_ram_time < 3) then
		return
	end

	ThreadManager:Run(function()
		ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(
			self:GetHandle(),
			1,
			0.0,
			math.min(1e5, self:GetSpeed() * 3e3),
			0.0,
			false,
			true,
			false,
			false
		)

		self.m_last_ram_time = Time.now()
	end)
end

function Vehicle:RamLeft()
	if not self:IsValid()
		or not self:IsCar()
		or not VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(self:GetHandle())
	then
		return
	end

	self.m_last_ram_time = self.m_last_ram_time or 0
	if (Time.now() - self.m_last_ram_time < 3) then
		return
	end

	ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(
		self:GetHandle(),
		1,
		-math.min(1e5, self:GetSpeed() * 3e3),
		0.0,
		0.0,
		false,
		true,
		false,
		false
	)

	self.m_last_ram_time = Time.now()
end

function Vehicle:RamRight()
	if not self:IsValid()
		or not self:IsCar()
		or not VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(self:GetHandle())
	then
		return
	end

	self.m_last_ram_time = self.m_last_ram_time or 0
	if (Time.now() - self.m_last_ram_time < 3) then
		return
	end

	ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(
		self:GetHandle(),
		1,
		math.min(1e5, self:GetSpeed() * 3e3),
		0.0,
		0.0,
		false,
		true,
		false,
		false
	)

	self.m_last_ram_time = Time.now()
end

-- Serializes a vehicle to JSON.
--
-- If a file name isn't provided, the vehicle's name will be used.
---@param name? string
function Vehicle:SaveToJSON(name)
	if not self:IsValid() then
		return
	end

	if (not name or name:isempty() or name:iswhitespace()) then
		name = self:GetName()
	end

	name = name:gsub("%.[^%.]+$", "")
	local filename = GenerateUniqueFilename(name, ".json")
	local modelhash = self:GetModelHash()
	local mods = self:GetMods()
	local t = {
		model_hash = modelhash,
		mods = mods
	}

	Serializer:WriteToFile(t, filename)
	self:notify("Saved vehicle to '%s'", filename)
end

-- Static Method.
--
-- Spawns a vehicle from JSON and returns a new `Vehicle` instance.
---@param filename string
---@param warp_into? boolean
function Vehicle.CreateFromJSON(filename, warp_into)
	if (type(filename) ~= "string") then
		Notifier:ShowError("Vehicle", "Failed to read vehicle data from JSON: Invalid filename.", true)
		return
	end

	if not filename:endswith(".json") then
		filename = filename .. ".json"
	end

	local data = Serializer:ReadFromFile(filename)
	if (type(data) ~= "table") then
		Notifier:ShowError("Vehicle", "Failed to read vehicle data from JSON. Unable to read file", true)
		return
	end

	local modelhash = data.model_hash
	if not Game.EnsureModelHash(modelhash) then
		Notifier:ShowError("Vehicle", "Failed to create vehicle from JSON: Invalid model hash.", true)
		return
	end

	local entity   = Self:GetVehicle() ~= nil and Self:GetVehicle() or Self
	local spawnpos = entity:GetSpawnPosInFront()
	local new_veh  = Vehicle:Create(modelhash, Enums.eEntityType.Vehicle, spawnpos, Self:GetHeading())
	if (new_veh:IsValid() and type(data.mods) == "table") then
		new_veh:ApplyMods(data.mods)
	end

	if (warp_into == true) then
		new_veh:WarpPed(Self:GetHandle())
	end

	return new_veh
end

function Vehicle:Destroy()
	self.m_handle    = nil
	self.m_modelhash = nil
	self.m_internal  = nil
	self.m_ptr       = nil
	return nil
end

-------------------------
-- Struct: VehicleMods
-------------------------
---@ignore
---@class VehicleMods
---@field mods table<integer, integer>
---@field toggle_mods table<integer, boolean>
---@field primary_color table<string, integer>
---@field secondary_color table<string, integer>
---@field window_tint number
---@field plate_text string
---@field window_states table<integer, boolean>
---@field wheels { index: integer, type: integer, var?: integer }
---@field xenon_color? number
---@field livery? number
---@field livery2? number
---@field pearlescent_color? number
---@field wheel_color? number
---@field interior_color? number
---@field dashboard_color? number
---@field tyre_smoke_color? { r: number, g: number, b: number }
---@field neon? { enabled: table<integer, boolean>, color: { r: number, g: number, b: number } }
VehicleMods = {}

---@param mods table
---@param primary_color table
---@param secondary_color table
---@param wheels table
---@param window_tint number
---@param plate_text? string
function VehicleMods.create(mods, primary_color, secondary_color, wheels, window_tint, plate_text)
	return {
		mods = mods,
		primary_color = primary_color,
		secondary_color = secondary_color,
		wheels = wheels,
		window_tint = window_tint,
		plate_text = plate_text or "SSV2"
	}
end
