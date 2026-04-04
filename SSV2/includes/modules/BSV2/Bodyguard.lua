-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Weapons = require("includes.data.weapons")
require("includes.modules.Ped")

local ReservedTargetVehicles            = {}
local ReservedVehicleSeats              = {}
local eGuardTask <const>                = {
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

local eGuardTaskToString                = {
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
local Bodyguard = Class("Bodyguard", { parent = Ped })
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
		spawnPos = LocalPlayer:GetOffsetInWorldCoords(0, 2, 0.1)
	end

	behavior = behavior or 1
	if (weapon == nil or weapon == 0) then
		weapon = _J("WEAPON_TECPISTOL")
	end

	local ok, handle = pcall(Game.CreatePed,
		modelHash,
		spawnPos,
		LocalPlayer:GetHeading(-180),
		Game.IsOnline(),
		false
	)
	if (not ok or not Game.IsScriptHandle(handle)) then
		Notifier:ShowWarning("Billionaire Services", "Failed to create entity! Please try again later", true, 5)
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
		for _, flag in pairs(Enums.eRagdollBlockingFlags) do
			PED.SET_RAGDOLL_BLOCKING_FLAGS(handle, flag)
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

	weapon = (type(weapon) == "string") and _J(weapon) or weapon
	if (weapon == 0) then
		weapon = _J("WEAPON_TECPISTOL")
	end

	if (weapon == _J("WEAPON_UNARMED")) then
		self.isArmed = self:IsArmed()
		return
	end

	if (type(weapon) == "number") then
		if (WEAPON.IS_WEAPON_VALID(weapon) and not WEAPON.HAS_PED_GOT_WEAPON(self.m_handle, weapon, false)) then
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
	local bossPos = LocalPlayer:GetPos()
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
	return ped == LocalPlayer:GetHandle()
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
	if (not LocalPlayer:IsOutside() and not allowInside) then
		return
	end

	if (PED.IS_PED_SITTING_IN_VEHICLE(self.m_handle, LocalPlayer:GetVehicleNative())) then
		return
	end

	if (not pos) then
		local yOffset = LocalPlayer:IsOnFoot() and math.random(2, 4) or math.random(6, 8)

		if (self:GetVehicle()) then
			yOffset = -yOffset
		end

		pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
			LocalPlayer:GetHandle(),
			0,
			yOffset,
			0.1
		)
	end

	PED.SET_PED_COORDS_KEEP_VEHICLE(self.m_handle, pos.x, pos.y, pos.z)
end

function Bodyguard:WarpIntoPlayerVeh()
	local PV = LocalPlayer:GetVehicleNative()
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

	if (PLAYER.IS_PLAYER_TELEPORT_ACTIVE() and not PLAYER.UPDATE_PLAYER_TELEPORT(LocalPlayer:GetPlayerID())) then
		sleep(10)
		return
	end

	if (CAM.IS_SCREEN_FADING_OUT() or CAM.IS_SCREEN_FADED_OUT()) then
		sleep(10)
		return
	end

	local PV = LocalPlayer:GetVehiclePlayerIsIn()
	if (self:IsBodyguard() and self:IsOnFoot() and PV and PV:IsValid()) then
		if (PV:IsAnySeatFree()) then
			PV:WarpPed(self.m_handle, -2)
			sleep(100)
			return
		end
	end

	local playerElevation = LocalPlayer:GetHeightAboveGround()
	if (PV and PV:IsValid()) then
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

		if (LocalPlayer:IsInWater()) then
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

	if (not LocalPlayer:IsOutside()) then
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
		LocalPlayer:GetHandle(),
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

	ENTITY.SET_ENTITY_HEADING(entity, LocalPlayer:GetHeading())
	PED.SET_PED_COORDS_KEEP_VEHICLE(self.m_handle, pos.x, pos.y, pos.z)

	if (self.task == eGuardTask.VEH_FOLLOW and vehicle and vehicle:IsValid() and PV and PV:IsValid()) then
		VEHICLE.SET_VEHICLE_FORWARD_SPEED(handle, PV:GetSpeed() + 0.5)
	end
end

function Bodyguard:ShouldJackVehicle()
	local PV = LocalPlayer:GetVehiclePlayerIsIn()
	return self:IsOnFoot() and not LocalPlayer:IsOnFoot()
		and (PV and not PV:IsAnySeatFree())
		and (self.task ~= eGuardTask.JACK_VEHICLE)
end

function Bodyguard:GrabNearestVehicle()
	if not self:ShouldJackVehicle() then
		return
	end

	local PV = LocalPlayer:GetVehiclePlayerIsIn()
	if (PV and PV:IsValid() and LocalPlayer:GetHeightAboveGround() >= 5) then
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

	ThreadManager:Run(function(s)
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
		local potentialVehicle = Game.GetClosestVehicle(guardPos, 75, LocalPlayer:GetVehicleNative(), true, 20.0)
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
					closestVehicle = Game.GetClosestVehicle(self:GetPos(), 75, LocalPlayer:GetVehicleNative(), true, 20.0)

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
			until not self:IsOnFoot() or timer:IsDone()

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
			self:QueueTask(eGuardTask.VEH_FOLLOW, self:TaskVehicleEscort(LocalPlayer:GetVehicleNative()))
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
		duration = (duration and duration ~= -1) and (Time.Now() + duration) or -1,
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
		if (override.duration == -1 or Time.Now() < override.duration) then
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
		if (not self:IsInCombat() or PED.IS_PED_IN_COMBAT(self.m_handle, LocalPlayer:GetHandle())) then
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
			self.task = eGuardTask.NONE
		end
	elseif (self.task == eGuardTask.FOLLOW) then
		if (PED.IS_PED_STOPPED(self.m_handle)) then
			self.task = eGuardTask.NONE
		end
	elseif (self.task == eGuardTask.VEH_FOLLOW) then
		if (self:IsOnFoot() or LocalPlayer:IsOnFoot()) then
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
	ThreadManager:Run(function()
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
	until dismissTimer:IsDone()
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

		if self.evalTimer:IsDone() then
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
					if LocalPlayer:IsDriving() then
						self.escortTarget = LocalPlayer:GetVehicleNative()
						self.task = eGuardTask.VEH_FOLLOW
					end
				end
			end

			if (self.task == eGuardTask.VEH_FOLLOW) then
				local bgVeh = self:GetVehicle()
				local PV = LocalPlayer:GetVehiclePlayerIsIn()
				if (not bgVeh or not bgVeh:IsValid()) then
					self:Reset()
				end

				if (bgVeh and bgVeh:IsValid())
					and (PV and PV:GetSpeed() >= 10)
					and self:GetPos():distance(LocalPlayer:GetPos()) >= 69
					and ENTITY.GET_ENTITY_SPEED(bgVeh:GetHandle()) <= 3 then
					Backend:debug(_F(
						"%s's vehicle appears to be stuck. Attempting to reset...",
						self.name
					))

					local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
						LocalPlayer:GetHandle(),
						0,
						-10,
						0
					)

					ENTITY.SET_ENTITY_HEADING(bgVeh:GetHandle(), LocalPlayer:GetHeading())
					PED.SET_PED_COORDS_KEEP_VEHICLE(self.m_handle, pos.x, pos.y, pos.z)

					local pvSpeed = PV:GetSpeed()
					if (LocalPlayer:IsDriving() and pvSpeed > 5) then
						VEHICLE.SET_VEHICLE_FORWARD_SPEED(bgVeh:GetHandle(), (pvSpeed - 5))
					end
				end
			end

			if self:IsEscort()
				and ((self:GetVehicle():GetHandle() == 0) or self:IsOnFoot())
				and not LocalPlayer:IsOnFoot() then
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

		entity = entity or LocalPlayer:GetHandle()

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
		ThreadManager:Run(function(s)
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
			while not timer:IsDone() do
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

	local playerPos = LocalPlayer:GetPos()
	TASK.TASK_SET_SPHERE_DEFENSIVE_AREA(self.m_handle, playerPos.x, playerPos.y, playerPos.z, 10)
	TASK.OPEN_SEQUENCE_TASK(self.combatSequenceTaskID)
	TASK.TASK_COMBAT_PED(self.m_handle, target, 0, 16)
	TASK.SET_SEQUENCE_TO_REPEAT(self.combatSequenceTaskID, true)
	TASK.CLOSE_SEQUENCE_TASK(self.combatSequenceTaskID)
	TASK.TASK_PERFORM_SEQUENCE(self.m_handle, self.combatSequenceTaskID)
end

function Bodyguard:TickCombat()
	if not LocalPlayer:IsInCombat() then
		return
	end

	local target = PED.GET_MELEE_TARGET_FOR_PED(LocalPlayer:GetHandle())
	if not target or not ENTITY.DOES_ENTITY_EXIST(target) then
		target = PED.GET_PED_TARGET_FROM_COMBAT_PED(LocalPlayer:GetHandle())
	end

	self:TaskCombatEngage(target)
	self.task = eGuardTask.COMBAT
end

---@param targetVehicle? integer
function Bodyguard:TaskVehicleEscort(targetVehicle)
	return function()
		self.escortTarget = targetVehicle or LocalPlayer:GetVehicleNative()
		self:SetTask(eGuardTask.VEH_FOLLOW)
	end
end

---@param s script_util
function Bodyguard:TickVehicleEscort(s)
	if (self.task == eGuardTask.VEH_FOLLOW) then
		if (LocalPlayer:IsOnFoot()) then
			self.escortGroup:StopTheVehicle()
			return
		end

		local PV = LocalPlayer:GetVehiclePlayerIsIn()
		if (PV and self.escortTarget and self.escortTarget == PV:GetHandle()) then
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
							until PED.IS_PED_SITTING_IN_VEHICLE(member.m_handle, self.vehicle.handle) or timer:IsDone()
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

	local guardInVehicle  = PED.IS_PED_SITTING_IN_ANY_VEHICLE(self.m_handle)
	local playerInVehicle = not LocalPlayer:IsOnFoot()
	local PV              = playerInVehicle and LocalPlayer:GetVehiclePlayerIsIn() or nil
	if (not guardInVehicle) then
		if (PV and PV:IsValid() and self.task ~= eGuardTask.ENTER_VEHICLE) then
			if (PV:IsAnySeatFree()) then
				self:QueueTask(eGuardTask.ENTER_VEHICLE, self:TaskEnterVehicle(PV:GetHandle()), true)
			else
				self:GrabNearestVehicle()
			end
		end
	else
		local gv = self:GetVehicle()
		if (gv and gv:GetHandle() ~= LocalPlayer:GetVehicleNative()) then
			if (playerInVehicle and PV) then
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

return Bodyguard
