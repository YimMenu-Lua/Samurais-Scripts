-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Bodyguard     = require("Bodyguard")
local EscortVehicle = require("EscortVehicle")


-----------------------------------------------------
-- Module: Escort Group
-----------------------------------------------------
---@class EscortGroup
---@field protected m_owner_ref BillionaireServices
---@field name string
---@field members Bodyguard[]
---@field vehicle EscortVehicle
---@field wasDismissed boolean
---@field lastDriverCheckTime integer
---@field currentDrivingMode integer
---@field task eVehicleTask
---@field lastTask eVehicleTask
---@field lastTaskCoords vec3
---@field drivingModes { drivingFlags: integer, speed: float }
local EscortGroup = {
	drivingModes = {
		{ drivingFlags = 786603, speed = 19 },
		{ drivingFlags = 527164, speed = 60 }
	}
}
EscortGroup.__index = EscortGroup

---@param ref BillionaireServices
---@param groupName string
---@param members Bodyguard[]
---@param vehicle EscortVehicle
function EscortGroup.new(ref, groupName, members, vehicle)
	return setmetatable(
		{
			m_owner_ref         = ref,
			name                = _F("%s [%d]", groupName:gsub(" %[%d+%]", ""), vehicle.handle),
			members             = members,
			vehicle             = vehicle,
			task                = Enums.eVehicleTask.NONE,
			wasDismissed        = false,
			lastDriverCheckTime = 0,
			currentDrivingMode  = 1,
		},
		EscortGroup
	)
end

function EscortGroup:ToTable()
	return {
		name         = self.name,
		vehicleModel = self.vehicle.model,
		members      = (function()
			local t = {}
			for _, member in pairs(self.members) do
				table.insert(t, {
					modelHash = member.m_modelhash,
					name      = member.name,
					weapon    = member.weapon or 350597077
				})
			end
			return t
		end)()
	}
end

---@param ref BillionaireServices
---@param t_Data table
---@param godMode? boolean
---@param noRagdoll? boolean
---@param spawnPos? vec3
function EscortGroup:Spawn(ref, t_Data, godMode, noRagdoll, spawnPos)
	if (not t_Data or not t_Data.members) then
		Backend:debug("Failed to summon an escort group! Invalid data.")
		return
	end

	if not spawnPos then
		spawnPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
			LocalPlayer:GetHandle(),
			0,
			-10,
			1.0
		)
	end

	local createdMembers = {}
	local escortVehicle  = EscortVehicle.new(t_Data.vehicleModel, t_Data.name, godMode)

	if (not escortVehicle or not Game.IsScriptHandle(escortVehicle.handle)) then
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
			ref,
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
	ENTITY.SET_ENTITY_HEADING(escortVehicle.handle, LocalPlayer:GetHeading())
	Game.SetEntityCoordsNoOffset(escortVehicle.handle, spawnPos)
	VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(escortVehicle.handle, 5.0)
	VEHICLE.SET_VEHICLE_ENGINE_ON(escortVehicle.handle, true, true, false)
	Game.FadeInEntity(escortVehicle.handle)

	local group = self.new(
		ref,
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
	if not member then return end

	Backend:debug(_F("member [%s] was removed", member.name))

	local newMembers = {}
	for _, escort in ipairs(self.members) do
		if escort and escort.m_handle ~= member.m_handle then
			table.insert(newMembers, escort)
		end
	end

	table.overwrite(self.members, newMembers)
	self:SanityCheck()
end

-- Returns the current escort group driver if they exist
-- otherwise, assigns a new driver and returns them.
---@return Bodyguard?
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
	local driver    = nil

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
	ThreadManager:Run(function()
		if (not LocalPlayer:IsOutside()) then
			Notifier:ShowError("Billionaire Services", _T("BSV2_ES_BRING_INTERIOR_ERR"))
			return
		end

		if (not self:GetInTheFuckingCar()) then
			Notifier:ShowError("Billionaire Services", _T("BSV2_ES_GENERIC_CAR_ERR"))
			return
		end

		local pos = LocalPlayer:GetOffsetInWorldCoords(
			math.random(-2, 2),
			math.random(-12, -8),
			0.1
		)

		Game.SetEntityCoordsNoOffset(self.vehicle.handle, pos)
	end)
end

function EscortGroup:BringPlayer()
	ThreadManager:Run(function()
		if not (LocalPlayer:IsOutside() and LocalPlayer:IsOnFoot()) then
			Notifier:ShowError("Billionaire Services", _T("BSV2_ES_TP_ERR"))
			return
		end

		local veh = self.vehicle
		if (not veh:Exists()) then
			Notifier:ShowError("Billionaire Services", _T("BSV2_ES_VEH_INVALID_ERR"))
			return
		end

		local vmin, vmax = Game.GetModelDimensions(Game.GetEntityModel(veh.handle))
		local height     = vmax.z - vmin.z
		local pos        = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
			veh.handle,
			0.0,
			0.0,
			height + 0.1
		)

		Game.SetEntityCoordsNoOffset(LocalPlayer:GetHandle(), pos)
	end)
end

function EscortGroup:RepairGroupVehicle()
	if not self.vehicle:Exists() then
		return
	end

	Vehicle(self.vehicle.handle):Repair(true)
end

---@return boolean
function EscortGroup:AreAllMembersInTheVehicle()
	for _, member in ipairs(self.members) do
		if not member or member:IsOnFoot() then
			return false
		end
	end

	return true
end

---@param index 1|2
function EscortGroup:SetDrivingStyle(index)
	if (type(index) ~= "number" or index > 2) then
		return
	end

	self.currentDrivingMode = index

	ThreadManager:Run(function(s)
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

---@return { speed: float, drivingFlags: integer }
function EscortGroup:GetDrivingStyle()
	return {
		speed        = self.drivingModes[self.currentDrivingMode].speed or 20,
		drivingFlags = self.drivingModes[self.currentDrivingMode].drivingFlags or 786603
	}
end

---@return boolean
function EscortGroup:CanGroupAcceptTask()
	for _, member in ipairs(self.members) do
		if not (member or member:CanAcceptTask()) then
			return false
		end
	end

	return true
end

---@return boolean
function EscortGroup:IsIdle()
	return (self.task == Enums.eVehicleTask.NONE)
end

---@return string
function EscortGroup:GetTaskAsString()
	return self.m_owner_ref.VehicleTaskToString[self.task or -1]
end

function EscortGroup:PrepareForGroupTask()
	if (not self:SanityCheck()) then return end

	if (not self.vehicle:IsPlayerInEscortVehicle()) then return end

	if (not self:CanGroupAcceptTask()) then return end

	local driver = self:GetDriver()

	if not (driver and driver:CanAcceptTask()) then return end

	if (not self:AreAllMembersInTheVehicle()) then
		self:GetInVehicle()

		repeat
			yield()
		until self:AreAllMembersInTheVehicle()
	end

	return driver
end

---@param coords vec3
function EscortGroup:GoTo(coords)
	local driver = self:GetDriver()
	if (not driver) then return end

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
	self.task           = Enums.eVehicleTask.GOTO
end

function EscortGroup:Wander()
	local driver = self:GetDriver()
	if (not driver) then return end

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
	self.task           = Enums.eVehicleTask.WANDER
end

function EscortGroup:CancelGroupTask()
	if (not self:SanityCheck()) then return end

	local driver = self:GetDriver()
	if (not driver) then return end

	TASK.CLEAR_PED_TASKS(driver.m_handle)
	TASK.CLEAR_PED_SECONDARY_TASK(driver.m_handle)
	TASK.CLEAR_PRIMARY_VEHICLE_TASK(self.vehicle.handle)
	TASK.TASK_VEHICLE_TEMP_ACTION(driver.m_handle, self.vehicle.handle, 1, 2000)

	driver:ClearOverrideTask()
	self.task = Enums.eVehicleTask.NONE
	self.lastTaskCoords = nil
end

function EscortGroup:StopTheVehicle()
	if (not self:SanityCheck()) then return end

	local driver = self:GetDriver()
	if (not driver) then return end

	self:CancelGroupTask()
	TASK.TASK_VEHICLE_TEMP_ACTION(driver.m_handle, self.vehicle.handle, 1, -1)
end

function EscortGroup:ParkTheVehicle()
	if (not self:SanityCheck()) then return end

	local driver = self:GetDriver()
	if (not driver) then return end

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

---@return boolean
function EscortGroup:SanityCheck()
	local BSV2 = self.m_owner_ref
	local members = self.members
	if (not members or (next(members) == nil)) then
		Backend:debug("Sanity check failed! No group members found.")
		BSV2:RemoveEscortGroup(self.name)
		return false
	end

	local driver = self:GetDriver()
	if (not driver or not self.vehicle:Exists()) then
		Backend:debug("Sanity check failed! Escort driver and/or vehicle no longer valid.")
		BSV2:RemoveEscortGroup(self.name)
		return false
	end

	if (driver:IsAlive()) then
		if (self.vehicle:Exists()) then
			self.vehicle:ToggleBlip(not self.vehicle:IsPlayerInEscortVehicle())
			return true
		else
			local lastCoords = Game.GetEntityCoords(driver.m_handle, true)
			if (ENTITY.IS_ENTITY_IN_WATER(driver.m_handle)) then
				lastCoords, _ = Game.GetClosestVehicleNodeWithHeading(lastCoords, 0)
			end

			self.vehicle:Recover(lastCoords, self.members, nil, self.name)
			return true
		end
	end

	return false
end

function EscortGroup:CheckDriver()
	if (Time.Millis() >= self.lastDriverCheckTime) then
		self:GetDriver()
		self.lastDriverCheckTime = Time.Millis() + 1e4
	end
end

function EscortGroup:GetInVehicle()
	if (not self:SanityCheck()) then return end

	for _, member in ipairs(self.members) do
		if (member:IsValid() and member:IsAlive()) then
			if (not PED.IS_PED_SITTING_IN_VEHICLE(member.m_handle, self.vehicle.handle)) then
				TASK.CLEAR_PED_TASKS(member.m_handle)
				TASK.CLEAR_PED_SECONDARY_TASK(member.m_handle)
				TASK.CLEAR_PRIMARY_VEHICLE_TASK(self.vehicle.handle)
				member:TaskEnterVehicle(self.vehicle.handle, 1e4, member.seatIndex or -2)()
			end
		end
	end
end

---@return boolean
function EscortGroup:GetInTheFuckingCar()
	if (not self:SanityCheck()) then return false end

	for _, member in ipairs(self.members) do
		if (member:IsValid() and member:IsAlive()) then
			local seat = member.seatIndex or -2
			local ped  = member.m_handle

			if (not PED.IS_PED_SITTING_IN_VEHICLE(ped, self.vehicle.handle)) then
				Backend:debug(_F("Forcing %s into seat %d", member.name, seat))
				TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
				sleep(1)
				PED.SET_PED_INTO_VEHICLE(ped, self.vehicle.handle, seat)

				if (member:IsEscortPassenger()) then
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

			TASK.TASK_LEAVE_VEHICLE(LocalPlayer:GetHandle(), self.vehicle.handle, 0)
			repeat
				s:sleep(100)
			until not PED.IS_PED_IN_VEHICLE(LocalPlayer:GetHandle(), self.vehicle.handle, false)
			s:sleep(2000)
		end

		driver.task = driver.TASKS.GO_HOME
		self.task = Enums.eVehicleTask.GO_HOME
		driver:Speak("GENERIC_BYE", "SPEECH_PARAMS_FORCE_SHOUTED")
		TASK.TASK_VEHICLE_DRIVE_WANDER(driver.m_handle, self.vehicle.handle, 20, 803243)

		local dismissTimer = Timer.new(9000)
		repeat
			s:sleep(500)
		until dismissTimer:IsDone()
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

	local playerInVehicle = PED.IS_PED_SITTING_IN_ANY_VEHICLE(LocalPlayer:GetHandle())

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
			goto continue
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
					local veh = LocalPlayer:GetVehicleNative()
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

return EscortGroup
