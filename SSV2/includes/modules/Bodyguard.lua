-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Weapons = require("includes.data.weapons")
require("includes.modules.Ped")

local ReservedTargetVehicles = {}
local ReservedVehicleSeats = {}

local eGuardTask <const> = {
	NONE          = -1,
	FOLLOW        = 0,
	VEH_FOLLOW    = 1,
	JACK_VEHICLE  = 2,
	ENTER_VEHICLE = 3,
	LEAVE_VEHICLE = 4,
	COMBAT        = 5,
	STAND_GUARD   = 6,
	WANDER        = 7,
	SIT_IN_VEH    = 8,
	GO_HOME       = 9,
	PRACHUTE      = 10,
	RAPPELL_DOWN  = 11,
	OVERRIDE      = 99,
}

local eGuardUninterruptibleTask <const> = {
	[eGuardTask.JACK_VEHICLE] = true,
	[eGuardTask.COMBAT]       = true,
	[eGuardTask.PRACHUTE]     = true,
	[eGuardTask.RAPPELL_DOWN] = true,
	[eGuardTask.GO_HOME]      = true,
	[eGuardTask.OVERRIDE]     = true,
}

local eGuardTaskToString = {
	[eGuardTask.NONE]          = "Idle.",
	[eGuardTask.FOLLOW]        = "Following player.",
	[eGuardTask.VEH_FOLLOW]    = "Escorting player's vehicle.",
	[eGuardTask.JACK_VEHICLE]  = "Jacking a vehicle.",
	[eGuardTask.ENTER_VEHICLE] = "Entering a vehicle.",
	[eGuardTask.LEAVE_VEHICLE] = "Leaving a vehicle.",
	[eGuardTask.COMBAT]        = "Engaging in combat.",
	[eGuardTask.STAND_GUARD]   = "Securing a perimeter.",
	[eGuardTask.WANDER]        = "Wandering.",
	[eGuardTask.SIT_IN_VEH]    = "Sitting in a vehicle.",
	[eGuardTask.GO_HOME]       = "Going home.",
	[eGuardTask.PRACHUTE]      = "Parachuting.",
	[eGuardTask.RAPPELL_DOWN]  = "Rappelling from helicopter.",
	[eGuardTask.OVERRIDE]      = nil,
}


-----------------------------------------------------
-- Bodyguard Class
-----------------------------------------------------
---@class Bodyguard : Ped
---@field tickOffset number
---@field m_handle integer
---@field m_modelhash integer
---@field gender ePedGender
---@field name string
---@field isArmed boolean
---@field weapon? integer|boolean
---@field hasAllWeapons boolean
---@field isInvincible boolean
---@field wasDismissed boolean
---@field task GuardTask
---@field lastTask table<GuardTask, function>
---@field role GuardRole
---@field overrideTaskData table -- Halts automatic behavior and tasks the ped with a new task.
---@field targetVehicleToJack integer -- Only for bodyguards when they can't get in the player's vehicle.
---@field vehicle EscortVehicle -- Escorts-only
---@field escortGroup EscortGroup -- Escorts-only
---@field seatIndex integer -- Special flag for escorts
---@field ConfigFlags table<integer, table<integer, integer>>
---@field CombatAttributes table<integer, table<integer, integer>>
---@field Create fun(_, modelHash: hash, entityType: eEntityType, pos?: vec3, heading?: number, isNetwork?: boolean, isScriptHostPed?: boolean): Bodyguard
local Bodyguard = Class("Bodyguard", Ped)
Bodyguard.TASKS = eGuardTask
Bodyguard.ROLES = {
	BODYGUARD = 0,
	ESCORT_DRIVER = 1,
	ESCORT_PASSENGER = 2
}
Bodyguard.ConfigFlags = {
	[1] = { 113, 118, 141, 179, 188, 193, 208, 251, 255, 261, 268, 286, 294, 301, 364, 398, 401, 443 } -- aggressive *(I don't think I'll provide a choice for behavior and will only use aggressive instead)*
}
Bodyguard.CombatAttributes = {
	[1] = { 1, 2, 3, 4, 5, 13, 20, 21, 22, 27, 28, 31, 34, 38, 41, 42, 46, 50, 54, 55, 58, 61, 68, 71 } -- aggressive //
}

---@param modelHash integer
---@param name? string
---@param spawnPos? vec3
---@param weapon? integer|boolean
---@param godmode? boolean
---@param noRagdoll? boolean
---@param behavior? integer
---@return Bodyguard?
function Bodyguard.new(modelHash, name, spawnPos, weapon, godmode, noRagdoll, behavior)
	if (not spawnPos) then
		spawnPos = Self:GetOffsetInWorldCoords(0, 2, 0.1)
	end

	behavior = behavior or 1

	local ped = Ped:Create(modelHash, Enums.eEntityType.Ped, spawnPos, Self:GetHeading(-180), Game.IsOnline(), false)
	local handle = ped:GetHandle()
	if (not Game.IsScriptHandle(handle)) then
		Backend:debug("failed to create ped.")
		return
	end

	if (Game.IsOnline()) then
		entities.take_control_of(handle, 500)
		Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(handle))
	end

	-- ENTITY.SET_ENTITY_LOD_DIST(handle, 0xFFFF) -- huh?
	ENTITY.SET_ENTITY_MAX_HEALTH(handle, 1000)
	ENTITY.SET_ENTITY_HEALTH(handle, 1000, 0, 0)
	ENTITY.SET_ENTITY_INVINCIBLE(handle, godmode or false)
	PED.SET_PED_RANDOM_COMPONENT_VARIATION(handle, 0)
	PED.SET_PED_KEEP_TASK(handle, true)
	PED.SET_PED_FIRING_PATTERN(handle, 0xC6EE6B4C)
	PED.SET_PED_SUFFERS_CRITICAL_HITS(handle, false)
	PED.SET_PED_ARMOUR(handle, 100)
	ENTITY.SET_ENTITY_MAX_HEALTH(handle, 1000)
	ENTITY.SET_ENTITY_HEALTH(handle, 1000, 0, 0)
	PED.SET_PED_CAN_EVASIVE_DIVE(handle, true)
	PED.SET_PED_CAN_BE_DRAGGED_OUT(handle, false)
	PED.SET_PED_CAN_BE_KNOCKED_OFF_VEHICLE(handle, 1)
	PED.SET_CAN_ATTACK_FRIENDLY(handle, false, false)

	if (noRagdoll) then
		for _, enum in pairs(Enums.eRagdollBlockingFlags) do
			PED.SET_RAGDOLL_BLOCKING_FLAGS(handle, enum)
		end
	end

	if (behavior == 1) then
		PED.SET_PED_ACCURACY(handle, 100)
		PED.SET_PED_HIGHLY_PERCEPTIVE(handle, true)
		PED.SET_PED_SEEING_RANGE(handle, 200)
		PED.SET_PED_HEARING_RANGE(handle, 200)
		PED.SET_PED_ID_RANGE(handle, 200)
		PED.SET_PED_SHOOT_RATE(handle, 1000)
		PED.SET_PED_COMBAT_ABILITY(handle, 2)
		PED.SET_DRIVER_AGGRESSIVENESS(handle, 1.0)
		PED.SET_PED_CONFIG_FLAG(handle, 360, false)
		PED.SET_PED_CONFIG_FLAG(handle, 431, false)
	end

	for _, flag in ipairs(Bodyguard.ConfigFlags[behavior]) do
		PED.SET_PED_CONFIG_FLAG(handle, flag, true)
	end

	for _, attr in ipairs(Bodyguard.CombatAttributes[behavior]) do
		PED.SET_PED_COMBAT_ATTRIBUTES(handle, attr, true)
	end

	Game.AddBlipForEntity(handle, 1.0, true, true, name)

	local guard = setmetatable({
		m_handle             = handle,
		m_modelhash          = modelHash,
		gender               = Game.GetPedGenderFromModel(modelHash),
		name                 = _F("%s [%s]", name, handle),
		isInvincible         = godmode or false,
		hasAllWeapons        = ((type(weapon) == "boolean") and (weapon == true)),
		weapon               = weapon,
		task                 = eGuardTask.NONE,
		wasDismissed         = false,
		combatSequenceTaskID = 0,
		taskQueue            = {},
	}, Bodyguard)

	guard:GiveWeapon(weapon)
	return guard
end

---@param weapon? integer|boolean
function Bodyguard:GiveWeapon(weapon)
	if (not weapon) then
		return
	end

	if (type(weapon) == "boolean") and (weapon == true) then
		self:GiveAllWeapons()
		return
	end

	weapon = (type(weapon) == "string") and joaat(weapon) or weapon
	if (weapon == 0) then
		weapon = joaat("WEAPON_TECPISTOL")
	end

	if (weapon == joaat("WEAPON_UNARMED")) then
		self.isArmed = self:IsArmed()
		return
	end

	if (type(weapon) == "number") then
		if (not WEAPON.HAS_PED_GOT_WEAPON(self.m_handle, weapon, false)) then
			WEAPON.GIVE_WEAPON_TO_PED(self.m_handle, weapon, 9999, false, false)
			WEAPON.SET_PED_INFINITE_AMMO(self.m_handle, true, weapon)
			self.isArmed = true
		end
	end
end

---@param weapon integer
function Bodyguard:RemoveWeapon(weapon)
	if WEAPON.HAS_PED_GOT_WEAPON(self.m_handle, weapon, false) then
		WEAPON.REMOVE_WEAPON_FROM_PED(self.m_handle, weapon)
	end

	self.isArmed = self:IsArmed()
end

function Bodyguard:GiveAllWeapons()
	for _, wpn in ipairs(Weapons.All) do
		if not WEAPON.HAS_PED_GOT_WEAPON(self.m_handle, wpn, false) then
			WEAPON.GIVE_DELAYED_WEAPON_TO_PED(self.m_handle, wpn, 9999, false)
		end
	end

	self.isArmed = true
end

function Bodyguard:RemoveAllWeapons()
	WEAPON.REMOVE_ALL_PED_WEAPONS(self.m_handle, true)
	self.isArmed = false
end

function Bodyguard:IsArmed()
	for _, weaponHash in ipairs(Weapons.All) do
		if WEAPON.HAS_PED_GOT_WEAPON(self.m_handle, weaponHash, false) then
			return true
		end
	end

	return false
end

function Bodyguard:Exists()
	return self.m_handle ~= 0 and Backend:IsScriptEntity(self.m_handle)
end

function Bodyguard:IsAlive()
	return not PED.IS_PED_DEAD_OR_DYING(self.m_handle, true)
end

function Bodyguard:IsControlled()
	return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(self.m_handle)
end

function Bodyguard:IsOutside()
	return INTERIOR.GET_INTERIOR_FROM_ENTITY(self.m_handle) == 0
end

function Bodyguard:IsOnFoot()
	return PED.IS_PED_ON_FOOT(self.m_handle)
end

function Bodyguard:IsDriving()
	local veh = self:GetVehicle()
	return veh and veh:IsValid()
		and (VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh:GetHandle(), -1, true) == self.m_handle)
end

function Bodyguard:IsInCombat()
	return PED.IS_PED_IN_COMBAT(self.m_handle, 0)
end

function Bodyguard:IsFarAwayFromBoss()
	local bossPos = Self:GetPos()
	local guardPos = self:GetPos()

	return guardPos:distance(bossPos) > 200
end

function Bodyguard:IsBodyguard()
	return self.role == Bodyguard.ROLES.BODYGUARD
end

function Bodyguard:IsEscort()
	return self.role == Bodyguard.ROLES.ESCORT_DRIVER
		or self.role == Bodyguard.ROLES.ESCORT_PASSENGER
end

function Bodyguard:IsEscortDriver()
	return self.role == Bodyguard.ROLES.ESCORT_DRIVER
end

function Bodyguard:IsEscortPassenger()
	return self.role == Bodyguard.ROLES.ESCORT_PASSENGER
end

---@param ped integer
function Bodyguard:IsPedFriendly(ped)
	return ped == Self:GetHandle()
		or (PED.GET_RELATIONSHIP_BETWEEN_PEDS(self.m_handle, ped) <= 2
			and PED.GET_RELATIONSHIP_BETWEEN_PEDS(ped, self.m_handle) <= 2
		)
end

function Bodyguard:IsInPrivateHeli()
	local bgVeh = self:GetVehicle()
	local heli = BillionaireServices.ActiveServices.heli

	if (not bgVeh or not bgVeh:IsValid() or not heli) then
		return false
	end

	return bgVeh:GetHandle() == heli.m_handle
end

---@param pos? vec3
---@param allowInside? boolean
function Bodyguard:Bring(pos, allowInside)
	if (not Self:IsOutside() and not allowInside) then
		return
	end

	if (PED.IS_PED_SITTING_IN_VEHICLE(self.m_handle, Self:GetVehicleNative())) then
		return
	end

	if (not pos) then
		local yOffset = Self:IsOnFoot() and math.random(2, 4) or math.random(6, 8)

		if (self:GetVehicle()) then
			yOffset = -yOffset
		end

		pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
			Self:GetHandle(),
			0,
			yOffset,
			0.1
		)
	end

	PED.SET_PED_COORDS_KEEP_VEHICLE(self.m_handle, pos.x, pos.y, pos.z)
end

function Bodyguard:WarpIntoPlayerVeh()
	local PV = Self:GetVehicleNative()
	if (PV == 0 or PED.IS_PED_SITTING_IN_VEHICLE(self.m_handle, PV)) then
		return
	end

	if (not VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(PV)) then
		Notifier:ShowError(
			"Samurai's Scripts",
			"There are no free seats to warp your bodyguard into!"
		)
		return
	end

	TASK.TASK_WARP_PED_INTO_VEHICLE(self.m_handle, PV, -2)
end

---@param allowInside? boolean
function Bodyguard:UpdatePosition(allowInside)
	if (not self:IsFarAwayFromBoss()) then
		return
	end

	if (PLAYER.IS_PLAYER_TELEPORT_ACTIVE() and not PLAYER.UPDATE_PLAYER_TELEPORT(Self:GetPlayerID())) then
		sleep(10)
		return
	end

	if (CAM.IS_SCREEN_FADING_OUT() or CAM.IS_SCREEN_FADED_OUT()) then
		sleep(10)
		return
	end

	local PV = Self:GetVehiclePlayerIsIn()
	if (self:IsBodyguard() and self:IsOnFoot() and PV and PV:IsValid()) then
		if (PV:IsAnySeatFree()) then
			PV:WarpPed(self.m_handle, -2)
			sleep(100)
			return
		end
	end

	local playerElevation = Self:GetHeightAboveGround()
	if (PV:IsValid()) then
		if (playerElevation >= 5 or playerElevation < 0) then
			if (not PV:IsLandVehicle() and not PV:IsPedInVehicle(self.m_handle)) then
				self.task = eGuardTask.NONE
				if (self:IsBodyguard()) then
					BillionaireServices:DismissBodyguard(self)
				else
					BillionaireServices:DismissEscortGroup(self.escortGroup.name)
				end

				Notifier:ShowMessage(
					"Samurai's Scripts",
					"Some of your bodyguards have been dismissed."
				)
				return
			end

			return
		end

		if (Self:IsInWater()) then
			self.task = eGuardTask.NONE

			if self:IsBodyguard() then
				BillionaireServices:DismissBodyguard(self)
			else
				BillionaireServices:DismissEscortGroup(self.escortGroup.name)
			end

			Notifier:ShowMessage(
				"Samurai's Scripts",
				"Some of your bodyguards have been dismissed."
			)
			return
		end
	end

	if (not Self:IsOutside()) then
		if (not allowInside or not self:IsOnFoot()) then
			return
		end
	end

	if (self.task == eGuardTask.JACK_VEHICLE) then
		return
	end

	if (self:IsEscortPassenger() and PED.IS_PED_SITTING_IN_ANY_VEHICLE(self.m_handle)) then
		return
	end

	local vehicle = self:GetVehicle()
	local handle = vehicle and vehicle:GetHandle() or 0
	local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
		Self:GetHandle(),
		(handle == 0) and math.random(-3, 3) or -math.random(-6, 6),
		(handle == 0) and -math.random(3, 6) or -math.random(6, 12),
		0.1
	)

	local entity
	if (not vehicle or not vehicle:IsValid()) then
		entity = self.m_handle
	else
		entity = handle
	end

	ENTITY.SET_ENTITY_HEADING(entity, Self:GetHeading())
	PED.SET_PED_COORDS_KEEP_VEHICLE(self.m_handle, pos.x, pos.y, pos.z)

	if (self.task == eGuardTask.VEH_FOLLOW and vehicle and vehicle:IsValid() and PV:IsValid()) then
		VEHICLE.SET_VEHICLE_FORWARD_SPEED(handle, PV:GetSpeed() + 0.5)
	end
end

function Bodyguard:ShouldJackVehicle()
	local PV = Self:GetVehiclePlayerIsIn()
	return self:IsOnFoot() and not Self:IsOnFoot()
		and (PV and not PV:IsAnySeatFree())
		and (self.task ~= eGuardTask.JACK_VEHICLE)
end

function Bodyguard:GrabNearestVehicle()
	if not self:ShouldJackVehicle() then
		return
	end

	local PV = Self:GetVehiclePlayerIsIn()
	if (PV and PV:IsValid() and Self:GetHeightAboveGround() >= 5) then
		Notifier:ShowMessage(
			"Samurai's Scripts",
			"Some of your bodyguards have been dismissed because you're flying."
		)

		self.task = eGuardTask.NONE
		BillionaireServices:DismissBodyguard(self)
		return
	end

	local function IsSuitableVehicle(veh)
		local cls = Vehicle(veh)
		return cls
			and cls:IsValid()
			and not cls:IsHeli()
			and not cls:IsPlane()
			and not BillionaireServices:GetEscortVehicleByHandle(veh)
			and not ReservedTargetVehicles[veh]
	end

	self:SetTask(eGuardTask.JACK_VEHICLE)

	script.run_in_fiber(function(s)
		if self.targetVehicleToJack then
			if Game.IsScriptHandle(self.targetVehicleToJack) then
				local pos = self:GetPos()
				local vehPos = Game.GetEntityCoords(self.targetVehicleToJack, false)

				TASK.TASK_WARP_PED_INTO_VEHICLE(self.m_handle, self.targetVehicleToJack, -1)
				if pos:distance(vehPos) > 150 then
					s:sleep(200)
					PED.SET_PED_COORDS_KEEP_VEHICLE(self.m_handle, pos.x, pos.y, pos.z)
				end
				return
			else
				self.targetVehicleToJack = nil
			end
		end

		local maxRetries = 5
		local retries = 0

		::search::
		local guardPos = self:GetPos()
		local potentialVehicle = Game.GetClosestVehicle(guardPos, 75, Self:GetVehicleNative(), true, 20.0)
		local closestVehicle = 0

		if IsSuitableVehicle(potentialVehicle) then
			closestVehicle = potentialVehicle
		else
			closestVehicle = 0
		end

		if (closestVehicle == 0) then
			local roadNode, heading = Game.GetClosestVehicleNodeWithHeading(guardPos, 0)
			if (roadNode:is_zero()) then
				Backend:debug("No road node found! Aborting.")
				self:ClearTasks()
				return
			end

			if roadNode:distance(guardPos) >= 150 then -- stop re-teleporting the damn ped! 😡
				self:ClearTasks()
				closestVehicle = self:SpawnTempBike()
			else
				TASK.TASK_GO_STRAIGHT_TO_COORD(self.m_handle, roadNode.x, roadNode.y, roadNode.z, 3.0, 10000, heading,
					0.5)

				repeat
					s:sleep(50)
				until roadNode:distance(self:GetPos()) <= 2.0

				while (retries < maxRetries) and (closestVehicle == 0) do
					closestVehicle = Game.GetClosestVehicle(self:GetPos(), 75, Self:GetVehicleNative(), true, 20.0)

					if (closestVehicle ~= 0) and IsSuitableVehicle(closestVehicle) then
						break
					else
						closestVehicle = 0
					end

					retries = retries + 1
					s:sleep(250)
				end

				if (closestVehicle == 0) then
					self:ClearTasks()
					closestVehicle = self:SpawnTempBike()
				end
			end
		end

		if IsSuitableVehicle(closestVehicle) then
			ReservedTargetVehicles[closestVehicle] = self.m_handle
			self.targetVehicleToJack = closestVehicle

			if not VEHICLE.IS_VEHICLE_STOPPED(closestVehicle) then
				VEHICLE.BRING_VEHICLE_TO_HALT(closestVehicle, 1.0, 1, false)
			end

			local passengers = Vehicle(closestVehicle):GetOccupants()
			for _, ped in ipairs(passengers) do
				if not Backend:IsScriptEntity(ped) then
					TASK.TASK_LEAVE_VEHICLE(ped, closestVehicle, 4160)
					s:sleep(100)
					TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
					TASK.TASK_SMART_FLEE_PED(ped, self.m_handle, 1000, -1, false, false)
				else
					TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.m_handle)
					s:sleep(250)
					goto search
				end
			end

			TASK.TASK_ENTER_VEHICLE(self.m_handle, closestVehicle, -1, -1, 2.0, 1, "")

			local timer = Timer.new(10000)
			repeat
				yield()
			until not self:IsOnFoot() or timer:is_done()

			if (PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(self.m_handle) == 0) or (self:IsOnFoot() and PED.IS_PED_STOPPED(self.m_handle)) then
				retries = retries + 1
				if (retries >= maxRetries) then
					if (closestVehicle ~= 0) then
						TASK.TASK_WARP_PED_INTO_VEHICLE(self.m_handle, closestVehicle, -2)
						return
					else
						TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.m_handle)
						s:sleep(250)
						goto search
					end
				end
			end

			self.task = eGuardTask.NONE
			self:QueueTask(eGuardTask.VEH_FOLLOW, self:TaskVehicleEscort(Self:GetVehicleNative()))
		end
	end)
end

function Bodyguard:ClearCombatTask()
	TASK.TASK_CLEAR_DEFENSIVE_AREA(self.m_handle)
	TASK.CLEAR_PED_TASKS(self.m_handle)
	TASK.CLEAR_PED_SECONDARY_TASK(self.m_handle)
	TASK.CLEAR_SEQUENCE_TASK(self.combatSequenceTaskID)
	self.combatSequenceTaskID = 0
	self.task = eGuardTask.NONE
end

---@param newTask GuardTask
function Bodyguard:SetTask(newTask)
	if self.task == newTask then
		return
	end

	if not self:CanInterruptTask() then
		return
	end

	if newTask ~= eGuardTask.VEH_FOLLOW then
		self.escortTarget = nil
	end

	self.task = newTask
end

---@param OnCall? function -- what to execute
---@param duration? number
---@param description? string
function Bodyguard:SetOverrideTask(OnCall, duration, description)
	description = description or "Running custom command."

	self.overrideTaskData = {
		func = OnCall,
		duration = (duration and duration ~= -1) and (Time.now() + duration) or -1,
		task = eGuardTask.OVERRIDE,
		desc = description,
		hasRun = false
	}

	eGuardTaskToString[eGuardTask.OVERRIDE] = description
	self.task = eGuardTask.OVERRIDE
end

function Bodyguard:ClearTasks()
	TASK.CLEAR_PED_TASKS(self.m_handle)
	self.task = eGuardTask.NONE
	self.escortTarget = nil
end

function Bodyguard:ClearOverrideTask()
	TASK.CLEAR_PED_TASKS(self.m_handle)
	self.overrideTaskData = nil
	self.task = eGuardTask.NONE
	eGuardTaskToString[eGuardTask.OVERRIDE] = nil
end

function Bodyguard:ClearQueue()
	self.taskQueue = {}
end

function Bodyguard:CanAcceptTask()
	return Game.IsScriptHandle(self:GetHandle())
		and self:IsAlive()
		and not self.overrideTaskData
end

function Bodyguard:CanInterruptTask()
	return not self.wasDismissed and not eGuardUninterruptibleTask[self.task]
end

---@param taskType GuardTask
---@param OnCall function
---@param highPriority? boolean
function Bodyguard:QueueTask(taskType, OnCall, highPriority)
	if (taskType == self.task) then
		return
	end

	local task = { type = taskType, data = OnCall }

	if (highPriority) then
		table.insert(self.taskQueue, 1, task)
	else
		table.insert(self.taskQueue, task)
	end

	self.lastTask = task
end

---@param taskType GuardTask
---@param OnCall function
function Bodyguard:ExecuteTask(taskType, OnCall)
	if not Game.IsScriptHandle(self:GetHandle()) then
		return
	end

	if (OnCall and type(OnCall) == "function") then
		self:SetTask(taskType)
		entities.take_control_of(self.m_handle, 300)
		OnCall()
	else
		Backend:debug(_F(
			"[Billionaire Services]: Bodyguard task execution failed! expected function, got %s instead",
			type(OnCall)
		))
	end
end

function Bodyguard:ProcessTaskQueue()
	if (#self.taskQueue > 0) then
		local next = table.remove(self.taskQueue, 1)
		self:ExecuteTask(next.type, next.data)
	end
end

function Bodyguard:UpdateTasks()
	local override = self.overrideTaskData

	if (override) then
		if (override.duration == -1 or Time.now() < override.duration) then
			if (not override.hasRun) then
				if (override.func and type(override.func) == "function") then
					override.func(self)
				end
				override.hasRun = true
			end
			return
		else
			self.overrideTaskData = nil
		end
	end

	if (self.task == eGuardTask.COMBAT) then
		if (not self:IsInCombat() or PED.IS_PED_IN_COMBAT(self.m_handle, Self:GetHandle())) then
			self:ClearCombatTask()

			if (self:IsEscort() and self.escortGroup) then
				self.escortGroup:GetInVehicle()
			end
		end
	elseif (self.task == eGuardTask.ENTER_VEHICLE or self.task == eGuardTask.JACK_VEHICLE) then
		if (PED.IS_PED_SITTING_IN_ANY_VEHICLE(self.m_handle) and PED.IS_PED_STOPPED(self.m_handle)) then
			if (self:IsBodyguard() and self.targetVehicleToJack) then
				ReservedTargetVehicles[self.targetVehicleToJack] = nil
			end
			self.task = eGuardTask.SIT_IN_VEH
		end
	elseif (self.task == eGuardTask.LEAVE_VEHICLE) then
		if (not PED.IS_PED_IN_ANY_VEHICLE(self.m_handle, false)) then
			print("not in a vehicle")
			self.task = eGuardTask.NONE
		end
	elseif (self.task == eGuardTask.FOLLOW) then
		if (PED.IS_PED_STOPPED(self.m_handle)) then
			self.task = eGuardTask.NONE
		end
	elseif (self.task == eGuardTask.VEH_FOLLOW) then
		if (self:IsOnFoot() or Self:IsOnFoot()) then
			self.task = eGuardTask.NONE
		end
	elseif (self.task ~= eGuardTask.PRACHUTE) or (self.task ~= eGuardTask.RAPPELL_DOWN) then
		if (self:GetHeightAboveGround() <= 2 or PED.IS_PED_STOPPED(self.m_handle)) then
			self.task = eGuardTask.NONE
		end
	end

	self:ProcessTaskQueue()
end

function Bodyguard:GetTaskAsString()
	return eGuardTaskToString[self.task] or "Running a custom task."
end

function Bodyguard:Reset()
	TASK.CLEAR_PED_TASKS(self.m_handle)
	self:ClearTasks()
	self:ClearQueue()
end

function Bodyguard:SpawnTempBike()
	local spawnPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(self.m_handle, 0, 3, 0.1)
	local handle = Game.CreateVehicle(
		0xF9300CC5,
		spawnPos,
		Game.GetHeading(self.m_handle) - 90,
		Game.IsOnline()
	)

	ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(handle)
	return handle
end

---@param speechName string
---@param speechParam? string
function Bodyguard:Speak(speechName, speechParam)
	script.run_in_fiber(function()
		if AUDIO.IS_AMBIENT_SPEECH_PLAYING(self.m_handle) then
			return
		end
		AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(
			self.m_handle,
			speechName or "GENERIC_HOWS_IT_GOING",
			speechParam or "SPEECH_PARAMS_STANDARD",
			0
		)
	end)
end

function Bodyguard:Dismiss(s)
	self.task = eGuardTask.GO_HOME
	self.wasDismissed = true

	if self:IsBodyguard() and PED.IS_PED_IN_ANY_VEHICLE(self.m_handle, true) then
		TASK.TASK_LEAVE_ANY_VEHICLE(self.m_handle, 0, 0)
		s:sleep(500)
	end

	TASK.TASK_WANDER_STANDARD(self.m_handle, 0, 0)
	Backend:RemoveBlip(self.m_handle)

	local dismissTimer = Timer.new(9000)
	repeat
		s:sleep(500)
	until dismissTimer:is_done()
	Game.FadeOutEntity(self.m_handle)
	s:sleep(1000)
	return true
end

function Bodyguard:StateEval()
	if self.overrideTaskData then
		return
	end

	if not self.evalTimer then
		if (self.task ~= eGuardTask.NONE) and (self.task ~= eGuardTask.STAND_GUARD) then
			self.evalTimer = Timer.new(10000)
			self.evalStartPos = self:GetPos()
			self.evalLastTask = self.task
		end
	else
		if (self.task == eGuardTask.NONE)
			or (self.task == eGuardTask.SIT_IN_VEH)
			or (self.task == eGuardTask.STAND_GUARD)
			or (self.task ~= self.evalLastTask) then
			self.evalTimer = nil
			self.evalStartPos = nil
			self.evalLastTask = nil
			return
		end

		if self.evalTimer:is_done() then
			local distMoved = self:GetPos():distance(self.evalStartPos or vec3:zero())

			if distMoved < 0.2
				and self:IsOnFoot()
				and TASK.IS_PED_STILL(self.m_handle)
				and not self:IsInCombat() then
				if self:CanInterruptTask() then
					Backend:debug(string.format(
						"%s: Appears to be stuck on task: %s. Attempting to reset...",
						self.name, self:GetTaskAsString()
					))
					self:Reset()
				end

				if self:IsEscort() and self.vehicle and self.vehicle:Exists() then
					TASK.TASK_WARP_PED_INTO_VEHICLE(self.m_handle, self.vehicle.handle, self.seatIndex)
				end
			end

			if (self.task == eGuardTask.JACK_VEHICLE)
				and PED.IS_PED_SITTING_IN_ANY_VEHICLE(self.m_handle)
				and distMoved < 0.2 then
				local veh = self:GetVehicle()

				if (veh and VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh:GetHandle(), -1, true) == self.m_handle) then
					self:ClearTasks()
					if Self:IsDriving() then
						self.escortTarget = Self:GetVehicleNative()
						self.task = eGuardTask.VEH_FOLLOW
					end
				end
			end

			if (self.task == eGuardTask.VEH_FOLLOW) then
				local bgVeh = self:GetVehicle()
				local PV = Self:GetVehiclePlayerIsIn()
				if (not bgVeh or not bgVeh:IsValid()) then
					self:Reset()
				end

				if (bgVeh and bgVeh:IsValid())
					and (PV and PV:GetSpeed() >= 10)
					and self:GetPos():distance(Self:GetPos()) >= 69
					and ENTITY.GET_ENTITY_SPEED(bgVeh:GetHandle()) <= 3 then
					Backend:debug(_F(
						"%s's vehicle appears to be stuck. Attempting to reset...",
						self.name
					))

					local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
						Self:GetHandle(),
						0,
						-10,
						0
					)

					ENTITY.SET_ENTITY_HEADING(bgVeh:GetHandle(), Self:GetHeading())
					PED.SET_PED_COORDS_KEEP_VEHICLE(self.m_handle, pos.x, pos.y, pos.z)

					local pvSpeed = PV:GetSpeed()
					if (Self:IsDriving() and pvSpeed > 5) then
						VEHICLE.SET_VEHICLE_FORWARD_SPEED(bgVeh:GetHandle(), (pvSpeed - 5))
					end
				end
			end

			if self:IsEscort()
				and ((self:GetVehicle():GetHandle() == 0) or self:IsOnFoot())
				and not Self:IsOnFoot() then
				Backend:debug("Escorts were glitching out of their vehicle. Attempting to reset...")
				self:Reset()
				TASK.TASK_WARP_PED_INTO_VEHICLE(self.m_handle, self.vehicle.handle, self.seatIndex)
			end

			if PED.IS_PED_IN_PARACHUTE_FREE_FALL(self.m_handle) then
				PED.FORCE_PED_TO_OPEN_PARACHUTE(self.m_handle)
				self.task = eGuardTask.PRACHUTE
				return
			end

			self.evalTimer = nil
			self.evalStartPos = nil
			self.evalLastTask = nil
		end
	end
end

--------------------------------------------
--- General Tasks
--------------------------------------------
---@param entity? integer
function Bodyguard:TaskGoToEntity(entity)
	return function()
		if not self:CanAcceptTask() or not self:CanInterruptTask() then
			return
		end

		entity = entity or Self:GetHandle()

		if not Game.IsScriptHandle(entity) then
			self:ClearTasks()
			return
		end

		TASK.TASK_GO_TO_ENTITY(
			self.m_handle,
			entity,
			-1,
			5.0,
			3.0,
			1073741824,
			0
		)
	end
end

---@param vehicle integer
---@param timeout? integer
---@param seatIndex? integer
function Bodyguard:TaskEnterVehicle(vehicle, timeout, seatIndex)
	return function()
		if (not self:CanAcceptTask() or not self:CanInterruptTask()) then
			return
		end

		if (not Game.IsScriptHandle(vehicle)) then
			self:ClearTasks()
			return
		end

		self.escortTarget = nil
		script.run_in_fiber(function(s)
			if PED.IS_PED_SITTING_IN_ANY_VEHICLE(self.m_handle) then
				return
			end

			s:sleep(math.random(5, 50))
			ReservedVehicleSeats[vehicle] = ReservedVehicleSeats[vehicle] or {}

			if self:IsBodyguard() or not seatIndex then
				for i = 0, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle) do
					if VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, i, true) and not ReservedVehicleSeats[vehicle][i] then
						ReservedVehicleSeats[vehicle][i] = self.m_handle
						seatIndex = i
						break
					end
				end
			end

			if not seatIndex then
				self:GrabNearestVehicle()
				return
			end

			TASK.CLEAR_PED_TASKS(self.m_handle)
			TASK.CLEAR_PED_SECONDARY_TASK(self.m_handle)

			if self:GetPos():distance(Game.GetEntityCoords(vehicle, false)) >= 150 then
				TASK.TASK_WARP_PED_INTO_VEHICLE(self.m_handle, vehicle, seatIndex)
				self.task = eGuardTask.SIT_IN_VEH
				s:sleep(1)

				if PED.IS_PED_SITTING_IN_VEHICLE(self.m_handle, vehicle) then
					ReservedVehicleSeats[vehicle][seatIndex] = nil
				end

				return
			end

			TASK.TASK_ENTER_VEHICLE(
				self.m_handle,
				vehicle,
				timeout or 20000,
				seatIndex,
				2.0,
				1,
				""
			)

			local timer = Timer.new(5000)
			while not timer:is_done() do
				if not seatIndex or PED.IS_PED_SITTING_IN_VEHICLE(self.m_handle, vehicle) then
					break
				end
				yield()
			end

			if seatIndex
				and VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, seatIndex, true)
				and not PED.IS_PED_SITTING_IN_VEHICLE(self.m_handle, vehicle)
				and not PED.IS_PED_TRYING_TO_ENTER_A_LOCKED_VEHICLE(self.m_handle) then
				TASK.TASK_WARP_PED_INTO_VEHICLE(self.m_handle, vehicle, seatIndex)
			end

			self.task = eGuardTask.SIT_IN_VEH

			s:sleep(1)

			if PED.IS_PED_SITTING_IN_VEHICLE(self.m_handle, vehicle) then
				ReservedVehicleSeats[vehicle][seatIndex] = nil
			end
		end)
	end
end

function Bodyguard:TaskLeaveVehicle()
	return function()
		if (not self:CanAcceptTask()) then
			return
		end

		if (self:IsOnFoot()) then
			self:ClearTasks()
			return
		end

		local currentSeat = self:GetVehicleSeat()
		local handle = self:GetVehicle():GetHandle()
		if (currentSeat and handle ~= 0) then
			if (ReservedVehicleSeats[handle] and ReservedVehicleSeats[handle][currentSeat]) then
				ReservedVehicleSeats[handle][currentSeat] = nil
			end
		end

		if (self:IsInPrivateHeli()) then
			local heli = BillionaireServices.ActiveServices.heli
			if (heli.isPlayerRappelling and currentSeat and currentSeat > 0) then
				self:ClearTasks()
				TASK.TASK_RAPPEL_FROM_HELI(self.m_handle, 10.0)
				self.task = eGuardTask.RAPPELL_DOWN
				return
			end
		end

		TASK.TASK_LEAVE_ANY_VEHICLE(self.m_handle, 0, 0)
		self.escortTarget = nil
	end
end

function Bodyguard:TaskStandGuard(pos, heading)
	return function()
		TASK.TASK_STAND_GUARD(
			self.m_handle,
			pos.x,
			pos.y,
			pos.z,
			heading,
			"WORLD_HUMAN_GUARD_STAND"
		)
	end
end

---@param target integer
function Bodyguard:TaskCombatEngage(target)
	if not self:CanAcceptTask() then
		return
	end

	if not target
		or not Game.IsScriptHandle(target)
		or ENTITY.IS_ENTITY_DEAD(target, false)
		or self:IsPedFriendly(target) then
		return
	end

	if PED.IS_PED_DEAD_OR_DYING(self.m_handle, true) then
		return
	end

	local currentTarget = PED.GET_PED_TARGET_FROM_COMBAT_PED(self.m_handle)
	if (currentTarget == target) and PED.IS_PED_IN_COMBAT(self.m_handle, target) then
		return
	end

	if self:IsPedFriendly(currentTarget) then
		Backend:debug(
			string.format(
				"%s went rogue and is attacking friendlies. We should consider nuking them!",
				self.name
			)
		)
		TASK.CLEAR_PED_TASKS(self.m_handle)
		return
	end

	local playerPos = Self:GetPos()
	TASK.TASK_SET_SPHERE_DEFENSIVE_AREA(self.m_handle, playerPos.x, playerPos.y, playerPos.z, 10)
	TASK.OPEN_SEQUENCE_TASK(self.combatSequenceTaskID)
	TASK.TASK_COMBAT_PED(self.m_handle, target, 0, 16)
	TASK.SET_SEQUENCE_TO_REPEAT(self.combatSequenceTaskID, true)
	TASK.CLOSE_SEQUENCE_TASK(self.combatSequenceTaskID)
	TASK.TASK_PERFORM_SEQUENCE(self.m_handle, self.combatSequenceTaskID)
end

function Bodyguard:TickCombat()
	if not Self:IsInCombat() then
		return
	end

	local target = PED.GET_MELEE_TARGET_FOR_PED(Self:GetHandle())
	if not target or not ENTITY.DOES_ENTITY_EXIST(target) then
		target = PED.GET_PED_TARGET_FROM_COMBAT_PED(Self:GetHandle())
	end

	self:TaskCombatEngage(target)
	self.task = eGuardTask.COMBAT
end

---@param targetVehicle? integer
function Bodyguard:TaskVehicleEscort(targetVehicle)
	return function()
		self.escortTarget = targetVehicle or Self:GetVehicleNative()
		self:SetTask(eGuardTask.VEH_FOLLOW)
	end
end

---@param s script_util
function Bodyguard:TickVehicleEscort(s)
	local PV = Self:GetVehiclePlayerIsIn()
	if (self.task == eGuardTask.VEH_FOLLOW) then
		if (Self:IsOnFoot()) then
			self.escortGroup:StopTheVehicle()
			return
		end

		if (self.escortTarget and PV and self.escortTarget == PV:GetHandle()) then
			if (not PV:IsLandVehicle()) then
				self.escortTarget = nil
				self.task = eGuardTask.NONE
				if self:IsBodyguard() then
					BillionaireServices:DismissBodyguard(self)
				else
					BillionaireServices:DismissEscortGroup(self.escortGroup.name)
				end
				return
			end

			local bgVeh = self:GetVehicle()
			if (bgVeh and bgVeh:IsValid())
				and PED.IS_PED_IN_VEHICLE(self.m_handle, bgVeh:GetHandle(), false)
				and (VEHICLE.GET_PED_IN_VEHICLE_SEAT(bgVeh:GetHandle(), -1, false) == self.m_handle) then
				if self:IsEscort() then
					for _, member in ipairs(self.escortGroup.members) do
						if not PED.IS_PED_SITTING_IN_VEHICLE(member.m_handle, self.vehicle.handle) then
							local timer = Timer.new(5000)
							repeat
								s:sleep(100)
							until PED.IS_PED_SITTING_IN_VEHICLE(member.m_handle, self.vehicle.handle) or timer:is_done()
						end
					end
				end

				TASK.TASK_VEHICLE_ESCORT(
					self.m_handle,
					bgVeh:GetHandle(),
					self.escortTarget,
					-1,
					60.0,
					24904187,
					5.0,
					5.0,
					5.0
				)
			end
		end
	end
end

---------------------------------------------

function Bodyguard:HandleVehicleTransitions()
	if (not self:IsBodyguard() or not self:CanAcceptTask()) then
		return
	end

	local guardInVehicle = PED.IS_PED_SITTING_IN_ANY_VEHICLE(self.m_handle)
	local playerInVehicle = not Self:IsOnFoot()
	local PV = Self:GetVehicle()
	if (not guardInVehicle) then
		if (playerInVehicle and PV and PV:IsValid() and self.task ~= eGuardTask.ENTER_VEHICLE) then
			if (PV:IsAnySeatFree()) then
				self:QueueTask(eGuardTask.ENTER_VEHICLE, self:TaskEnterVehicle(PV:GetHandle()), true)
			else
				self:GrabNearestVehicle()
			end
		end
	else
		local gv = self:GetVehicle()
		if (gv and gv:GetHandle() ~= Self:GetVehicleNative()) then
			if (playerInVehicle) then
				if (not PV:IsLandVehicle()) then
					return
				end

				self:QueueTask(eGuardTask.VEH_FOLLOW, self:TaskVehicleEscort(PV:GetHandle()), true)
			else
				self:QueueTask(eGuardTask.LEAVE_VEHICLE, self:TaskLeaveVehicle(), true)

				if (self.task ~= eGuardTask.PRACHUTE and self.task ~= eGuardTask.RAPPELL_DOWN) then
					self:QueueTask(eGuardTask.FOLLOW, self:TaskGoToEntity())
				end
			end
		end
	end
end

-----------------------------------------------------
-- Escort Vehicle Struct
-----------------------------------------------------
---@class EscortVehicle
local EscortVehicle = {}
EscortVehicle.__index = EscortVehicle
EscortVehicle.model = 0
EscortVehicle.handle = 0
EscortVehicle.name = ""
EscortVehicle.blip = nil

---@param modelHash integer
---@param groupName string
---@param godMode? boolean
function EscortVehicle.new(modelHash, groupName, godMode)
	TaskWait(Game.RequestModel, modelHash)

	local handle = Game.CreateVehicle(modelHash, vec3:zero())
	if not TaskWait(Game.IsScriptHandle, handle) then
		return
	end

	local wrapper    = Vehicle(handle)
	local vehName    = wrapper:GetName()
	local blip       = Game.AddBlipForEntity(handle, 1.14, true)
	local blipName   = groupName or string.format("Escort Vehicle (%s)", vehName)
	local r, g, b, _ = Color("#000100"):AsRGBA() -- Vantablack

	entities.take_control_of(handle, 300)
	Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(handle))
	Game.SetBlipSprite(blip, 229)
	Game.SetBlipName(blip, blipName)

	ENTITY.SET_ENTITY_INVINCIBLE(handle, godMode or false)
	VEHICLE.SET_VEHICLE_MOD_KIT(handle, 0)
	VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(handle, r, g, b)
	VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(handle, r, g, b)
	VEHICLE.SET_VEHICLE_EXTRA_COLOURS(handle, 0, 0)
	VEHICLE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(handle, false, false)
	VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(handle, false)
	VEHICLE.SET_VEHICLE_STRONG(handle, true)
	VEHICLE.SET_VEHICLE_DIRT_LEVEL(handle, 0)
	VEHICLE.SET_VEHICLE_WINDOW_TINT(handle, 1)
	VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(handle, "MRDR INC")
	wrapper:MaxPerformance()

	return setmetatable(
		{
			model = modelHash,
			handle = handle,
			name = vehName,
			blip = {
				handle = blip,
				alpha = 255
			}
		},
		EscortVehicle
	)
end

function EscortVehicle:Exists()
	return self.handle ~= 0 and Backend:IsScriptEntity(self.handle)
end

function EscortVehicle:IsDriveable()
	return VEHICLE.IS_VEHICLE_DRIVEABLE(self.handle, true)
end

function EscortVehicle:IsStuck()
	if not self:Exists() or not self:IsDriveable() then
		return false
	end

	return VEHICLE.IS_VEHICLE_STUCK_ON_ROOF(self.handle)
end

function EscortVehicle:IsPlayerInEscortVehicle()
	local playerVeh = Self:GetVehicleNative()
	return (playerVeh ~= 0 and self.handle == playerVeh)
end

function EscortVehicle:GetPos()
	if self:Exists() then
		return Game.GetEntityCoords(self.handle, false)
	end

	return vec3:zero()
end

function EscortVehicle:GetDriver()
	return VEHICLE.GET_PED_IN_VEHICLE_SEAT(self.handle, -1, true)
end

---@param toggle boolean
function EscortVehicle:ToggleBlip(toggle)
	if not self.blip or not self.blip.handle then
		return
	end

	local targetAlpha = toggle and 255 or 0
	local cond = toggle and self.blip.alpha < targetAlpha or self.blip.alpha > targetAlpha

	if cond then
		self.blip.alpha = targetAlpha
		if HUD.DOES_BLIP_EXIST(self.blip.handle) then
			HUD.SET_BLIP_ALPHA(self.blip.handle, targetAlpha)
		end
	end
end

---@param lastCoords? vec3
---@param passengers Bodyguard[]
---@param lastHeading? integer
---@param groupName? string
function EscortVehicle:Recover(lastCoords, passengers, lastHeading, groupName)
	if self:Exists() then
		Game.DeleteEntity(self.handle)
		Decorator:RemoveEntity(self.handle)
	end

	if not lastCoords then
		lastCoords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
			Self:GetHandle(),
			0,
			-10,
			1.0
		)
	end

	self.handle = Game.CreateVehicle(self.model, vec3:zero())
	Decorator:Register(self.handle, "BillionaireServices")
	ENTITY.FREEZE_ENTITY_POSITION(self.handle, true)

	local r, g, b, _ = Color("#000100"):AsRGBA()
	local wrapper = Vehicle(self.handle)
	VEHICLE.SET_VEHICLE_MOD_KIT(self.handle, 0)
	VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(self.handle, r, g, b)
	VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(self.handle, r, g, b)
	VEHICLE.SET_VEHICLE_EXTRA_COLOURS(self.handle, 0, 0)
	VEHICLE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(self.handle, false, false)
	VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(self.handle, false)
	VEHICLE.SET_VEHICLE_STRONG(self.handle, true)
	VEHICLE.SET_VEHICLE_DIRT_LEVEL(self.handle, 0)
	VEHICLE.SET_VEHICLE_WINDOW_TINT(self.handle, 1)
	VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(self.handle, "MRDR INC")
	wrapper:MaxPerformance()

	for i = 1, #passengers do
		local guard = passengers[i]

		if (guard:GetHandle() ~= Self:GetHandle()) and not PED.IS_PED_A_PLAYER(guard:GetHandle()) then
			PED.CLEAR_ALL_PED_VEHICLE_FORCED_SEAT_USAGE(guard:GetHandle())
			PED.SET_PED_VEHICLE_FORCED_SEAT_USAGE(
				guard:GetHandle(),
				self.handle,
				guard:IsEscortDriver() and -1 or guard.seatIndex,
				0,
				0
			)

			if not guard:IsInCombat() then
				TASK.TASK_WARP_PED_INTO_VEHICLE(
					guard:GetHandle(),
					self.handle,
					guard:IsEscortDriver() and -1 or guard.seatIndex
				)
			end
		end
	end

	local vehName = wrapper:GetName()
	local blip = Game.AddBlipForEntity(self.handle, 1.14, true)
	local blipName = groupName or string.format("Escort Vehicle (%s)", vehName)

	Game.SetBlipSprite(blip, 229)
	Game.SetBlipName(blip, blipName)
	Game.SetEntityCoordsNoOffset(self.handle, lastCoords)

	ENTITY.SET_ENTITY_HEADING(self.handle, lastHeading or Self:GetHeading())
	ENTITY.FREEZE_ENTITY_POSITION(self.handle, false)
	VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(self.handle, 5.0)
	VEHICLE.SET_VEHICLE_ENGINE_ON(self.handle, true, true, false)
end

-----------------------------------------------------
-- Escort Group Struct
-----------------------------------------------------
---@class EscortGroup
---@field members Bodyguard[]
---@field vehicle EscortVehicle
---@field wasDismissed boolean
---@field lastDriverCheckTime integer
---@field task number
---@field lastTask number
---@field lastTaskCoords vec3
local EscortGroup = {}
EscortGroup.__index = EscortGroup
EscortGroup.name = ""
EscortGroup.members = {}
EscortGroup.wasDismissed = false
EscortGroup.lastDriverCheckTime = 0
EscortGroup.currentDrivingMode = 1
EscortGroup.task = Enums.eVehicleTask.NONE
EscortGroup.drivingModes = {
	{ drivingFlags = 786603, speed = 19 },
	{ drivingFlags = 527164, speed = 60 }
}

---@param groupName string
---@param members Bodyguard[]
---@param vehicle EscortVehicle
function EscortGroup.new(groupName, members, vehicle)
	return setmetatable(
		{
			name = string.format(
				"%s [%d]",
				string.gsub(groupName, " %[%d+%]", ""),
				vehicle.handle
			),
			members = members,
			vehicle = vehicle
		},
		EscortGroup
	)
end

function EscortGroup:ToTable()
	return {
		name = self.name,
		vehicleModel = self.vehicle.model,
		members = (function()
			local t = {}
			for _, member in pairs(self.members) do
				table.insert(
					t,
					{
						modelHash = member.m_modelhash,
						name = member.name,
						weapon = member.weapon or 350597077
					}
				)
			end
			return t
		end)()
	}
end

---@param t_Data table
---@param godMode? boolean
---@param noRagdoll? boolean
---@param spawnPos? vec3
function EscortGroup:Spawn(t_Data, godMode, noRagdoll, spawnPos)
	if not t_Data or not t_Data.members then
		Backend:debug("Failed to summon an escort group! Invalid data.")
		return
	end

	if not spawnPos then
		spawnPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
			Self:GetHandle(),
			0,
			-10,
			1.0
		)
	end

	local createdMembers = {}
	local escortVehicle = EscortVehicle.new(t_Data.vehicleModel, t_Data.name, godMode)

	if not escortVehicle or not TaskWait(Game.IsScriptHandle, escortVehicle.handle) then
		Notifier:ShowError(
			"Samurai's Scripts",
			"Failed to summon an escort group."
		)
		return
	end

	ENTITY.FREEZE_ENTITY_POSITION(escortVehicle.handle, true)

	for i = 1, 3 do
		local member = t_Data.members[i]

		if not member.modelHash then
			Notifier:ShowError(
				"Samurai's Scripts",
				"Failed to create an escort group! Wrong member list."
			)
			return
		end

		local guard = Bodyguard.new(
			member.modelHash,
			member.name,
			vec3:zero(),
			member.weapon or 0x1B06D571,
			godMode or false,
			noRagdoll or false,
			1
		)

		if not guard or not TaskWait(Game.IsScriptHandle, guard:GetHandle()) then
			return
		end

		guard.vehicle = escortVehicle
		guard:GiveAllWeapons()

		if (i == 1) then
			guard.role = Bodyguard.ROLES.ESCORT_DRIVER
			guard.seatIndex = -1
			PED.SET_PED_VEHICLE_FORCED_SEAT_USAGE(guard:GetHandle(), escortVehicle.handle, -1, 0, 0)
			TASK.TASK_WARP_PED_INTO_VEHICLE(guard:GetHandle(), escortVehicle.handle, -1)
		else
			guard.role = Bodyguard.ROLES.ESCORT_PASSENGER
			guard.seatIndex = i - 2
			PED.SET_PED_VEHICLE_FORCED_SEAT_USAGE(guard:GetHandle(), escortVehicle.handle, i - 2, 0, 0)
			TASK.TASK_WARP_PED_INTO_VEHICLE(guard:GetHandle(), escortVehicle.handle, i - 2)
		end

		table.insert(createdMembers, guard)
	end

	if #t_Data.members > 3 then
		Notifier:ShowWarning(
			"Samurai's Scripts",
			"Escort groups can only hold up to 3 members. Excess members in this list have been dismissed."
		)
	end

	ENTITY.FREEZE_ENTITY_POSITION(escortVehicle.handle, false)
	ENTITY.SET_ENTITY_HEADING(escortVehicle.handle, Self:GetHeading())
	Game.SetEntityCoordsNoOffset(escortVehicle.handle, spawnPos)
	VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(escortVehicle.handle, 5.0)
	VEHICLE.SET_VEHICLE_ENGINE_ON(escortVehicle.handle, true, true, false)
	Game.FadeInEntity(escortVehicle.handle)

	local group = self.new(
		t_Data.name,
		createdMembers,
		escortVehicle
	)

	for _, escort in ipairs(group.members) do
		escort.escortGroup = group
	end

	return group
end

---@param member Bodyguard
function EscortGroup:RemoveMember(member)
	if not member then
		return
	end

	Backend:debug(string.format("member [%s] was removed", member.name))

	local newMembers = {}
	for _, escort in ipairs(self.members) do
		if escort and escort.m_handle ~= member.m_handle then
			table.insert(newMembers, escort)
		end
	end

	self.members = newMembers
	self:SanityCheck()
end

-- Returns the current escort group driver if they exist
-- otherwise, assigns a new driver and returns them.
function EscortGroup:GetDriver()
	for _, member in ipairs(self.members) do
		if (member:Exists() and member:IsAlive() and member:IsEscortDriver()) then
			return member
		end
	end

	---@type Bodyguard[]
	local eligibleMembers = {}

	for _, member in ipairs(self.members) do
		if (member:Exists() and member:IsAlive()) then
			table.insert(eligibleMembers, member)
		end
	end

	if (#eligibleMembers == 0) then
		return
	end

	table.sort(eligibleMembers, function(a, b)
		return a.seatIndex < b.seatIndex
	end)

	local seatOrder = { -1, 0, 1 }
	local driver = nil

	for i, member in ipairs(eligibleMembers) do
		local newSeat = seatOrder[i]

		if newSeat then
			member.seatIndex = newSeat
			PED.CLEAR_ALL_PED_VEHICLE_FORCED_SEAT_USAGE(member.m_handle)
			PED.SET_PED_VEHICLE_FORCED_SEAT_USAGE(member.m_handle, self.vehicle.handle, newSeat, 0, 0)

			if not member:IsInCombat() then
				if PED.IS_PED_IN_ANY_VEHICLE(member.m_handle, true) then
					TASK.CLEAR_PED_TASKS_IMMEDIATELY(member.m_handle)
				end

				TASK.TASK_WARP_PED_INTO_VEHICLE(member.m_handle, self.vehicle.handle, newSeat)
			end

			if (newSeat == -1) then
				member.role = member.ROLES.ESCORT_DRIVER
				Backend:debug("Escort driver reassigned to " .. member.name)
				driver = member
			else
				member.role = member.ROLES.ESCORT_PASSENGER
			end
		end
	end

	return driver
end

function EscortGroup:Bring()
	if not Self:IsOutside() then
		Notifier:ShowError(
			"Samurai's Scripts",
			"You can not bring escort groups inside interiors."
		)
		return
	end

	script.run_in_fiber(function()
		if not self:GetInTheFuckingCar() then
			Notifier:ShowError(
				"Samurai's Scripts",
				"[Escort Group] Something went wrong!"
			)
			return
		end

		local pos = Self:GetOffsetInWorldCoords(
			math.random(-2, 2),
			math.random(-12, -8),
			0.1
		)

		Game.SetEntityCoordsNoOffset(self.vehicle.handle, pos)
	end)
end

function EscortGroup:BringPlayer()
	script.run_in_fiber(function()
		if not Self:IsOutside() or not Self:IsOnFoot() then
			Notifier:ShowError(
				"Samurai's Scripts",
				"You must be outside and standing on foot to teleport to your escort group."
			)
			return
		end
		local veh = self.vehicle

		if not veh:Exists() then
			Notifier:ShowError(
				"Samurai's Scripts",
				"The escort vehicle seems to no longer exist."
			)
			return
		end

		local vmin, vmax = Game.GetModelDimensions(Game.GetEntityModel(veh.handle))
		local height = vmax.z - vmin.z
		local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
			veh.handle,
			0.0,
			0.0,
			height + 0.1
		)

		Game.SetEntityCoordsNoOffset(Self:GetHandle(), pos)
	end)
end

function EscortGroup:RepairGroupVehicle()
	if not self.vehicle:Exists() then
		return
	end

	Vehicle(self.vehicle.handle):Repair(true)
end

function EscortGroup:AreAllMembersInTheVehicle()
	for _, member in ipairs(self.members) do
		if not member or member:IsOnFoot() then
			return false
		end
	end

	return true
end

---@param i_DrivingStyle number
function EscortGroup:SetDrivingStyle(i_DrivingStyle)
	if type(i_DrivingStyle) ~= "number" or i_DrivingStyle > 2 then
		return
	end

	self.currentDrivingMode = i_DrivingStyle

	script.run_in_fiber(function(s)
		if (self.task == Enums.eVehicleTask.GOTO and self.lastTaskCoords) then
			local driver = self:GetDriver()
			if (not driver) then
				return
			end

			driver:Speak("GENERIC_YES")
			TASK.CLEAR_PED_TASKS(driver.m_handle)
			TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(
				driver.m_handle,
				self.vehicle.handle,
				self.lastTaskCoords.x,
				self.lastTaskCoords.y,
				self.lastTaskCoords.z,
				self:GetDrivingStyle().speed,
				self:GetDrivingStyle().drivingFlags,
				30
			)
		elseif (self.task == Enums.eVehicleTask.WANDER) then
			self:CancelGroupTask()
			s:sleep(500)
			self:Wander()
		end
	end)
end

function EscortGroup:GetDrivingStyle()
	return {
		speed = self.drivingModes[self.currentDrivingMode].speed or 20,
		drivingFlags = self.drivingModes[self.currentDrivingMode].drivingFlags or 786603
	}
end

function EscortGroup:CanGroupAcceptTask()
	for _, member in ipairs(self.members) do
		if not (member or member:CanAcceptTask()) then
			return false
		end
	end

	return true
end

function EscortGroup:IsIdle()
	return (self.task == Enums.eVehicleTask.NONE)
end

function EscortGroup:GetTaskAsString()
	return BillionaireServices.VehicleTaskToString[self.task or -1]
end

function EscortGroup:PrepareForGroupTask()
	if (not self:SanityCheck()) then
		return
	end

	if (not self.vehicle:IsPlayerInEscortVehicle()) then
		return
	end

	if not self:CanGroupAcceptTask() then
		return
	end

	local driver = self:GetDriver()

	if not driver then
		return
	end

	if not driver:CanAcceptTask() then
		return
	end

	if not self:AreAllMembersInTheVehicle() then
		self:GetInVehicle()

		repeat
			yield()
		until self:AreAllMembersInTheVehicle()
	end

	return driver
end

---@param coords vec3
function EscortGroup:GoTo(coords)
	local driver = self:PrepareForGroupTask()

	if not driver then
		return
	end

	driver:Speak("GENERIC_YES")
	driver:SetOverrideTask(nil, -1, "Driving to coordinates")

	TASK.CLEAR_PED_TASKS(driver.m_handle)
	TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(
		driver.m_handle,
		self.vehicle.handle,
		coords.x,
		coords.y,
		coords.z,
		self:GetDrivingStyle().speed,
		self:GetDrivingStyle().drivingFlags,
		30
	)

	self.lastTaskCoords = coords
	self.task = Enums.eVehicleTask.GOTO
end

function EscortGroup:Wander()
	local driver = self:PrepareForGroupTask()

	if not driver then
		return
	end

	driver:Speak("GENERIC_YES")
	driver:SetOverrideTask(nil, -1, "Cuising around")

	TASK.CLEAR_PED_TASKS(driver.m_handle)
	TASK.TASK_VEHICLE_DRIVE_WANDER(
		driver.m_handle,
		self.vehicle.handle,
		self:GetDrivingStyle().speed,
		self:GetDrivingStyle().drivingFlags
	)

	self.lastTaskCoords = nil
	self.task = Enums.eVehicleTask.WANDER
end

function EscortGroup:CancelGroupTask()
	if not self:SanityCheck() then
		return
	end

	local driver = self:GetDriver()

	if not driver then
		return
	end

	TASK.CLEAR_PED_TASKS(driver.m_handle)
	TASK.CLEAR_PED_SECONDARY_TASK(driver.m_handle)
	TASK.CLEAR_PRIMARY_VEHICLE_TASK(self.vehicle.handle)
	TASK.TASK_VEHICLE_TEMP_ACTION(driver.m_handle, self.vehicle.handle, 1, 2000)

	driver:ClearOverrideTask()
	self.task = Enums.eVehicleTask.NONE
	self.lastTaskCoords = nil
end

function EscortGroup:StopTheVehicle()
	if not self:SanityCheck() then
		return
	end

	local driver = self:GetDriver()

	if not driver then
		return
	end

	self:CancelGroupTask()
	TASK.TASK_VEHICLE_TEMP_ACTION(driver.m_handle, self.vehicle.handle, 1, -1)
end

function EscortGroup:ParkTheVehicle()
	if not self:SanityCheck() then
		return
	end

	local driver = self:GetDriver()

	if not driver then
		return
	end

	local area = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
		self.vehicle.handle,
		2,
		10,
		0
	)

	self:CancelGroupTask()
	TASK.TASK_VEHICLE_PARK(
		driver.m_handle,
		self.vehicle.handle,
		area.x,
		area.y,
		area.z,
		Game.GetHeading(self.vehicle.handle),
		0,
		100,
		true
	)
end

function EscortGroup:SanityCheck()
	local driver = self:GetDriver()

	if driver and driver:IsAlive() then
		if self.vehicle:Exists() then
			self.vehicle:ToggleBlip(not self.vehicle:IsPlayerInEscortVehicle())
			return true
		else
			local lastCoords = Game.GetEntityCoords(driver.m_handle, true)

			if ENTITY.IS_ENTITY_IN_WATER(driver.m_handle) then
				lastCoords, _ = Game.GetClosestVehicleNodeWithHeading(lastCoords, 0)
			end

			self.vehicle:Recover(lastCoords, self.members, nil, self.name)
			return true
		end
	end

	if not self:GetDriver() or not self.vehicle:Exists() then
		Backend:debug("Sanity check failed! Escort driver and/or vehicle no longer valid.")
		BillionaireServices:RemoveEscortGroup(self.name)
		return false
	end

	if not self.members or (table.getlen(self.members) == 0) then
		Backend:debug("Sanity check failed! No group members found.")
		BillionaireServices:RemoveEscortGroup(self.name)
		return false
	end
end

function EscortGroup:CheckDriver()
	if Time.millis() >= self.lastDriverCheckTime then
		EscortGroup:GetDriver()
		self.lastDriverCheckTime = Time.millis() + 1e4
	end
end

function EscortGroup:GetInVehicle()
	if not self:SanityCheck() then
		return
	end

	for _, member in ipairs(self.members) do
		if member:IsAlive() and Game.IsScriptHandle(member.m_handle) then
			if not PED.IS_PED_SITTING_IN_VEHICLE(member.m_handle, self.vehicle.handle) then
				TASK.CLEAR_PED_TASKS(member.m_handle)
				TASK.CLEAR_PED_SECONDARY_TASK(member.m_handle)
				TASK.CLEAR_PRIMARY_VEHICLE_TASK(self.vehicle.handle)
				member:TaskEnterVehicle(self.vehicle.handle, 1e4, member.seatIndex or -2)()
			end
		end
	end
end

function EscortGroup:GetInTheFuckingCar()
	if not self:SanityCheck() then
		return false
	end

	for _, member in ipairs(self.members) do
		if member:IsAlive() and Game.IsScriptHandle(member.m_handle) then
			local seat = member.seatIndex or -2
			local ped = member.m_handle

			if not PED.IS_PED_SITTING_IN_VEHICLE(ped, self.vehicle.handle) then
				Backend:debug(
					string.format(
						"Forcing %s into seat %d",
						member.name,
						seat
					)
				)
				TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
				PED.SET_PED_INTO_VEHICLE(ped, self.vehicle.handle, seat)

				if member:IsEscortPassenger() then
					member.task = member.TASKS.SIT_IN_VEH
				end
			end
		end
	end

	return true
end

function EscortGroup:Dismiss(s)
	self.wasDismissed = true
	self:GetInVehicle()
	local driver = self:GetDriver()
	local veh = driver and driver:GetVehicle()
	if (driver
			and driver:IsAlive()
			and (self.vehicle and Game.IsScriptHandle(self.vehicle.handle))
			and (veh and veh:GetHandle() == self.vehicle.handle)
		) then
		if (self.vehicle:IsPlayerInEscortVehicle()) then
			driver:ClearTasks()
			TASK.TASK_VEHICLE_TEMP_ACTION(driver.m_handle, self.vehicle.handle, 1, -1)
			while not VEHICLE.IS_VEHICLE_STOPPED(self.vehicle.handle) do
				if not self.vehicle:IsPlayerInEscortVehicle() then
					break
				end
				yield()
			end

			TASK.TASK_LEAVE_VEHICLE(Self:GetHandle(), self.vehicle.handle, 0)
			repeat
				s:sleep(100)
			until not PED.IS_PED_IN_VEHICLE(Self:GetHandle(), self.vehicle.handle, false)
			s:sleep(2000)
		end

		driver.task = driver.TASKS.GO_HOME
		self.task = Enums.eVehicleTask.GO_HOME
		driver:Speak("GENERIC_BYE", "SPEECH_PARAMS_FORCE_SHOUTED")
		TASK.TASK_VEHICLE_DRIVE_WANDER(driver.m_handle, self.vehicle.handle, 20, 803243)

		local dismissTimer = Timer.new(9000)
		repeat
			s:sleep(500)
		until dismissTimer:is_done()
		Game.FadeOutEntity(self.vehicle.handle)
	else
		for _, escort in ipairs(self.members) do
			if escort and escort.m_handle then
				if PED.IS_PED_IN_ANY_VEHICLE(escort.m_handle, false) then
					TASK.TASK_LEAVE_ANY_VEHICLE(escort.m_handle, 0, 0)
					s:sleep(250)
				end

				escort.task = escort.TASKS.GO_HOME
				escort.wasDismissed = true
				TASK.TASK_WANDER_STANDARD(escort.m_handle, 0, 0)
			end
		end
	end

	for _, escort in ipairs(self.members) do
		if escort and escort.m_handle and (not driver or escort.m_handle ~= driver.m_handle) then
			Game.FadeOutEntity(escort.m_handle)
		end
	end
	s:sleep(1000)
	return true
end

---@param s script_util
---@param globalTick number
function EscortGroup:BackgroundWorker(s, globalTick)
	if not self:SanityCheck() then
		return
	end

	local playerInVehicle = PED.IS_PED_SITTING_IN_ANY_VEHICLE(Self:GetHandle())

	if (not self:IsIdle()) then
		if (self.task == Enums.eVehicleTask.GOTO and self.lastTaskCoords) then
			if (not self.vehicle:IsPlayerInEscortVehicle()) then
				self:StopTheVehicle()
				return
			end

			local speed = ENTITY.GET_ENTITY_SPEED(self.vehicle.handle)
			local threshold = math.max(40, speed * 2)
			if (self.vehicle:GetPos():distance(self.lastTaskCoords) <= threshold) then
				Notifier:ShowMessage(
					"Samurai's Scripts",
					"[Private Escort]: You have reached your destination."
				)
				self:StopTheVehicle()
			end
		end
	end

	for _, escort in ipairs(self.members) do
		if not escort:Exists() or not escort:IsAlive() then
			self:RemoveMember(escort)
			s:sleep(5)
			return
		end

		if (not escort or not escort.tickOffset or (globalTick % 4 ~= escort.tickOffset)) then
			goto continue
		end

		if (escort:CanAcceptTask()) then
			local escortInVehicle = PED.IS_PED_SITTING_IN_ANY_VEHICLE(escort.m_handle)
			if (playerInVehicle and not escort:IsInCombat()) then
				if (not escortInVehicle) then
					if (not PED.IS_PED_IN_VEHICLE(escort.m_handle, self.vehicle.handle, true)) then
						escort:QueueTask(
							escort.TASKS.ENTER_VEHICLE,
							escort:TaskEnterVehicle(
								self.vehicle.handle,
								2e4,
								escort.seatIndex or -2
							)
						)
					end
				elseif (playerInVehicle) then
					local veh = Self:GetVehicleNative()
					if (escort:IsEscortDriver() and veh ~= self.vehicle.handle) then
						escort:QueueTask(
							escort.TASKS.VEH_FOLLOW,
							escort:TaskVehicleEscort(veh),
							true
						)
					end
				end
			end
		end

		escort:TickCombat()
		escort:TickVehicleEscort(s)
		escort:UpdateTasks()
		escort:UpdatePosition(false)
		escort:StateEval()
		s:sleep(1)

		::continue::
	end
end

return { bg = Bodyguard, eg = EscortGroup }
