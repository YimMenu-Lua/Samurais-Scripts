---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local FeatureBase = require("includes.modules.FeatureBase")
local drivingModes <const> = {
	{ drivingFlags = 786603,  speed = 20 },
	{ drivingFlags = 2886204, speed = 60 }
}

---@class Carpool : FeatureBase
---@field private m_entity any
---@field private m_active boolean
---@field private m_task eVehicleTask
---@field private m_driver handle
---@field private m_last_task_coords vec3
---@field private m_current_drive_mode integer
---@field private m_last_search_pos vec3
---@field private m_vehicle Vehicle
---@field protected m_thread Thread
local Carpool = setmetatable({}, FeatureBase)
Carpool.__index = Carpool

---@param owner any
---@return Carpool
function Carpool.new(owner)
	local self     = FeatureBase.new(owner)
	local instance = setmetatable(self, Carpool)
	instance:Init()
	return instance
end

function Carpool:Init()
	self.m_active             = false
	self.m_last_check_time    = 0
	self.m_current_drive_mode = 1
	self.m_driver             = 0
	self.m_task               = Enums.eVehicleTask.NONE
	self.m_last_search_pos    = vec3:zero()
	self.cachedVehicleData    = {
		isConvertible = false,
		speed = 0,
		roofState = Enums.eConvertibleRoofState.INVALID,
		maxSeats = 0,
		occupants = {},
		pedConfigApplied = false,
		radio = {
			isOn = false,
			station = "Off"
		}
	}
end

function Carpool:ResetCachedData()
	self.cachedVehicleData = {
		isConvertible = false,
		speed = 0,
		roofState = Enums.eConvertibleRoofState.INVALID,
		maxSeats = 0,
		occupants = {},
		pedConfigApplied = false,
		radio = {
			isOn = false,
			station = "Off"
		}
	}
end

function Carpool:ShouldRun()
	return (GVars.features.world.carpool and Self:IsOutside())
end

function Carpool:OnDisable()
	self:TogglePedConfig(false)
	self.m_vehicle = nil
end

function Carpool:IsActive()
	return self.m_active
end

function Carpool:GetDriver()
	return self.m_driver
end

function Carpool:GetVehicle()
	return self.m_vehicle
end

---@return eVehicleTask
function Carpool:GetCurrentTask()
	return self.m_task
end

function Carpool:GetDrivingStyle()
	return {
		speed = drivingModes[self.m_current_drive_mode].speed or 20,
		drivingFlags = drivingModes[self.m_current_drive_mode].drivingFlags or 786603
	}
end

---@param step integer
function Carpool:ShuffleSeats(step)
	if (not self.m_vehicle:IsValid()) then
		return
	end

	self.m_vehicle:ShuffleSeats(step)
end

---@param styleIndex number 1 | 2
function Carpool:SetDrivingStyle(styleIndex)
	if (type(styleIndex) ~= "number" or styleIndex < 1 or styleIndex > 2) then
		return
	end

	if (styleIndex == self.m_current_drive_mode) then
		return
	end

	self.m_current_drive_mode = styleIndex
	ThreadManager:Run(function()
		self:CancelAllTasks()
		if (self.m_task == Enums.eVehicleTask.GOTO and self.m_last_task_coords) then
			self:GoTo(self.m_last_task_coords)
		else
			self:Wander()
		end
	end)
end

---@param toggle boolean
function Carpool:TogglePedConfig(toggle)
	if (not self.m_vehicle or not self.m_vehicle:IsValid()) then
		return
	end

	if (self.cachedVehicleData.pedConfigApplied == toggle) then
		return
	end

	if (#self.cachedVehicleData.occupants == 0) then
		self.cachedVehicleData.occupants = self.m_vehicle:GetOccupants()
	end

	for _, occupant in ipairs(self.cachedVehicleData.occupants) do
		if (occupant
				and entities.take_control_of(occupant, 200)
				and ENTITY.IS_ENTITY_A_PED(occupant)
				and not PED.IS_PED_A_PLAYER(occupant)
				and not PED.IS_PED_GROUP_MEMBER(occupant, Self:GetGroupIndex())
				and not Backend:IsScriptEntity(occupant)
			) then
			if (toggle) then
				TASK.CLEAR_PED_TASKS(occupant)
			end

			PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(occupant, toggle)
			PED.SET_PED_CONFIG_FLAG(occupant, Enums.ePedConfigFlags.PreventPedFromReactingToBeingJacked, toggle)
			PED.SET_PED_CONFIG_FLAG(occupant, Enums.ePedConfigFlags.DisablePanicInVehicle, toggle)
			PED.SET_PED_CONFIG_FLAG(occupant, Enums.ePedConfigFlags.AICanDrivePlayerAsRearPassenger, toggle)
			PED.SET_PED_CONFIG_FLAG(occupant, Enums.ePedConfigFlags.AIDriverAllowFriendlyPassengerSeatEntry, toggle)
		end
	end

	self.cachedVehicleData.pedConfigApplied = toggle
end

function Carpool:FindVehicle()
	if (self.m_vehicle and self.m_vehicle:IsValid()) then
		if (Self:GetPos():distance(self.m_vehicle:GetPos()) >= 20) then -- in case vehicle drove away
			self:TogglePedConfig(false)
			self:ResetCachedData()
			self.m_vehicle = nil
			return
		end
		return
	end

	if (Self:IsDriving()) then
		self:ResetCachedData()
		self.m_vehicle = nil
		return
	end

	local now = Game.GetGameTimer()
	if (now - self.m_last_check_time < 1000) then
		return
	end
	self.m_last_check_time = now

	local handle = Game.GetClosestVehicle(Self:GetHandle(), 15, Self:GetVehicleNative(), true, 3)
	if (not ENTITY.IS_ENTITY_A_VEHICLE(handle)) then
		self:ResetCachedData()
		self.m_vehicle = nil
		return
	end

	if (VEHICLE.GET_PED_IN_VEHICLE_SEAT(handle, -1, true) == 0) then
		self:ResetCachedData()
		self.m_vehicle = nil
		return
	end

	if (Backend:IsScriptEntity(handle)) then
		self:TogglePedConfig(false)
		self:ResetCachedData()
		self.m_vehicle = nil
		return
	end

	if (VEHICLE.IS_VEHICLE_SEAT_FREE(handle, -1, false) or not VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(handle)) then
		self:TogglePedConfig(false)
		self:ResetCachedData()
		self.m_vehicle = nil
		return
	end

	self.m_vehicle = Vehicle(handle)
	self:TogglePedConfig(true)
end

function Carpool:OnExit()
	if (not self.m_active or not self.m_vehicle or not self.m_vehicle:IsValid()) then
		self:TogglePedConfig(false)
		self:ResetCachedData()
		self.m_active = false
		self.m_driver = 0
		return
	end

	if (not self.m_vehicle:IsPedInVehicle(Self:GetHandle()) or not self.m_vehicle:IsPedInVehicle(self.m_driver)) then
		self:EmergencyStop()
		self:TogglePedConfig(false)

		self:ResetCachedData()
		self.m_active  = false
		self.m_vehicle = nil
		self.m_driver  = 0
	end
end

function Carpool:CancelAllTasks()
	if (not self.m_vehicle:IsValid() or not Game.IsScriptHandle(self.m_driver)) then
		return
	end

	entities.take_control_of(self.m_driver, 250)
	TASK.CLEAR_PED_TASKS(self.m_driver)
	TASK.CLEAR_PED_SECONDARY_TASK(self.m_driver)
	TASK.CLEAR_PRIMARY_VEHICLE_TASK(self.m_vehicle)
	TASK.TASK_VEHICLE_TEMP_ACTION(self.m_driver, self.m_vehicle, 1, 2000)

	self.m_task = Enums.eVehicleTask.NONE
	self.m_last_task_coords = nil
end

---@param coords vec3
function Carpool:GoTo(coords)
	if (not self.m_vehicle:IsValid() or not Game.IsScriptHandle(self.m_driver)) then
		return
	end

	self:CancelAllTasks()
	local drivingStyle = self:GetDrivingStyle()
	self.m_vehicle:GoTo(coords, { speed = drivingStyle.speed, drivingFlags = drivingStyle.drivingFlags })
	self.m_last_task_coords = coords
	self.m_task = Enums.eVehicleTask.GOTO
end

function Carpool:Wander()
	if (not self.m_vehicle:IsValid() or not Game.IsScriptHandle(self.m_driver)) then
		return
	end

	self:CancelAllTasks()
	local drivingStyle = self:GetDrivingStyle()
	self.m_vehicle:Wander({ speed = drivingStyle.speed, drivingFlags = drivingStyle.drivingFlags })
	self.m_task = Enums.eVehicleTask.WANDER
	self.m_last_task_coords = nil
end

function Carpool:Stop()
	if (not self.m_vehicle:IsValid() or not Game.IsScriptHandle(self.m_driver)) then
		return
	end

	self:CancelAllTasks()
	self.m_task = Enums.eVehicleTask.OVERRIDE
end

function Carpool:EmergencyStop()
	if (not self.m_vehicle:IsValid() or not Game.IsScriptHandle(self.m_driver)) then
		return
	end

	self:CancelAllTasks()
	self.m_task = Enums.eVehicleTask.OVERRIDE
	VEHICLE.SET_VEHICLE_FORWARD_SPEED(self.m_vehicle, 0)
end

function Carpool:Resume()
	if (not self.m_vehicle:IsValid() or not Game.IsScriptHandle(self.m_driver)) then
		return
	end

	if (self.m_task ~= Enums.eVehicleTask.OVERRIDE) then
		return
	end

	if (self.m_last_task_coords) then
		self:GoTo(self.m_last_task_coords)
	else
		self.m_task = Enums.eVehicleTask.NONE
	end
end

function Carpool:Update()
	if (Self:IsOnFoot()) then
		if (not self.m_active or not self.m_vehicle or not self.m_vehicle:IsValid()) then
			self:FindVehicle()
		else
			self:OnExit()
		end

		return
	end

	if (self.m_vehicle and self.m_vehicle:IsPedInVehicle(Self:GetHandle()) and not Self:IsDriving()) then
		self.m_active = true
		self.m_driver = self.m_vehicle:GetPedInSeat(-1, true)
		self.cachedVehicleData.isConvertible = self.m_vehicle:IsConvertible()
		self.cachedVehicleData.speed = self.m_vehicle:GetSpeed()
		self.cachedVehicleData.radio.isOn = self.m_vehicle:IsRadioOn()
		self.cachedVehicleData.radio.station = self.m_vehicle:GetRadioStationName()

		if (self.cachedVehicleData.isConvertible) then
			self.cachedVehicleData.roofState = self.m_vehicle:GetConvertibleRoofState()
		end
	end

	yield()
end

function Carpool:OnTick()
	if (not self:ShouldRun()) then
		yield()
		return
	end

	self:Update()

	if (self.m_active) then
		if (not self.m_vehicle:IsValid()
				or not ENTITY.DOES_ENTITY_EXIST(self.m_driver)
				or (self.m_vehicle:GetPedInSeat(-1, true) ~= self.m_driver)
				or not self.m_vehicle:IsPedInVehicle(Self:GetHandle())
			) then
			self:OnExit()
			return
		end

		if (PAD.IS_CONTROL_PRESSED(0, 75)) then
			self:EmergencyStop()
		end

		if (self.m_task == Enums.eVehicleTask.OVERRIDE) then
			while (not self.m_vehicle:IsStopped()) do
				if (not self.m_vehicle:IsValid() or not self.m_vehicle:IsDriveable()) then
					break
				end

				if (not self.m_vehicle:IsPedInVehicle(self.m_driver)) then
					break
				end

				if (not self.m_vehicle:IsPedInVehicle(Self:GetHandle())) then
					break
				end

				TASK.TASK_VEHICLE_TEMP_ACTION(self.m_driver, self.m_vehicle:GetHandle(), 1, 1) -- no yield, otherwise the NPC will resume driving
			end
		end
	end

	if (self.m_task ~= Enums.eVehicleTask.OVERRIDE) then
		yield()
	end
end

return Carpool
