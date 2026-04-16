-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Bodyguard      = require("Bodyguard")
local EscortGroup    = require("EscortGroup")
local PrivateHeli    = require("PrivateHeli")
local PrivateJet     = require("PrivateJet")
local PrivateLimo    = require("PrivateLimo")

local BSV2Data       = require("includes.data.bsv2_data")
local GroupManager   = require("includes.services.GroupManager")
local RandomPedNames = require("includes.data.ped_names")

---@alias ServiceType integer
---| -1 # ALL
---| 0 # Bodyguard Service
---| 1 # Escort Service
---| 2 # Limo Service
---| 3 # Helicoper Service
---| 4 # Private Jet Service


---@alias GuardTask integer
---| -1 # NONE
---| 0  # FOLLOW
---| 1  # VEH_FOLLOW
---| 2  # JACK_VEHICLE
---| 3  # ENTER_VEHICLE
---| 4  # LEAVE_VEHICLE
---| 5  # COMBAT
---| 6  # STAND_GUARD
---| 7  # WANDER
---| 8  # SIT_IN_VEH
---| 9  # GO_HOME
---| 10 # PRACHUTE
---| 11 # RAPPELL_DOWN
---| ...
---| 99 # OVERRIDE


---@alias GuardRole integer
---| 0 # BODYGUARD
---| 1 # ESCORT_DRIVER
---| 2 # ESCORT_PASSENGER


---@alias VehicleTask integer
---| -1 # NONE
---| 0  # GOTO
---| 1  # WANDER
---| 2  # PLANE_TAXI
---| 3  # TAKE_OFF
---| 4  # LAND
---| 5  # HOVER_IN_PLACE
---| 6  # GO_HOME
---| 99  # OVERRIDE


---@class BillionaireServices
---@field Bodyguards table<integer, Bodyguard>
---@field EscortGroups table<string, EscortGroup>
---@field EscortVehicles table<integer, EscortVehicle>
---@field protected m_initialized boolean
local BillionaireServices               = {}
BillionaireServices.__index             = BillionaireServices
BillionaireServices.Bodyguards          = {}
BillionaireServices.EscortGroups        = {}
BillionaireServices.EscortVehicles      = {}
BillionaireServices.groups_file_name    = "escort_groups.json"
BillionaireServices.EscortGroupsData    = BSV2Data.DefaultEscortGroups
BillionaireServices.SERVICE_TYPE        = {
	ALL       = -1,
	BODYGUARD = 0,
	ESCORT    = 1,
	LIMO      = 2,
	HELI      = 3,
	JET       = 4,
}
BillionaireServices.ActiveServices      = {
	---@type PrivateLimo
	limo = nil,
	---@type PrivateHeli
	heli = nil,
	---@type PrivateJet
	jet = nil,
}

BillionaireServices.VehicleTaskToString = {
	[Enums.eVehicleTask.NONE]           = "Idle.",
	[Enums.eVehicleTask.GOTO]           = "Going to destination.",
	[Enums.eVehicleTask.WANDER]         = "Cruising around.",
	[Enums.eVehicleTask.TAKE_OFF]       = "Taking off.",
	[Enums.eVehicleTask.LAND]           = "Landing at destination.",
	[Enums.eVehicleTask.HOVER_IN_PLACE] = "Hovering.",
	[Enums.eVehicleTask.GO_HOME]        = "Going home.",
}

---@return BillionaireServices
function BillionaireServices:init()
	if (not self.m_initialized) then
		self:ParseEscortGroups()
		self.GroupManager            = GroupManager:init(BillionaireServices)
		self.GroupManager.globalTick = GroupManager.globalTick or 0
		self.m_initialized           = true

		Backend:RegisterEventCallbackAll(function() self:ForceCleanup() end)
		Backend:RegisterFeatureEntityHandler("BillionaireServices", function(handle)
			self:RemoveEntityByHandle(handle)
		end)
	end

	return self
end

---@param entity integer
function BillionaireServices:RegisterEntity(entity)
	Decorator:Register(entity, "BillionaireServices", true)
end

---@param entity integer
function BillionaireServices:UnregisterEntity(entity)
	Decorator:RemoveEntity(entity)
end

function BillionaireServices:ParseEscortGroups()
	if (not io.exists(self.groups_file_name)) then
		Serializer:WriteToFile(self.groups_file_name, {})
		return
	end

	---@type dict<RawEscortGroupData>?
	local saved = Serializer:ReadFromFile(self.groups_file_name)
	if (not saved or next(saved) == nil) then return end

	local loaded = self.EscortGroupsData
	for name, data in pairs(saved) do
		if (not loaded[name]) then
			data.JSON    = data.JSON or true
			loaded[name] = data
		end
	end
end

---@return dict<RawEscortGroupData>
function BillionaireServices:GetEscortGroupList()
	return self.EscortGroupsData
end

---@param group RawEscortGroupData
function BillionaireServices:AddNewEscortGroup(group)
	if (type(group.vehicleModel) ~= "number") then
		Notifier:ShowError("Billionaire Services", "Invalid group vehicle model!")
		return
	end

	local name = group.name
	if (not string.isvalid(name)) then
		Notifier:ShowError("Billionaire Services", "Invalid group name!")
		return
	end

	if (self.EscortGroupsData[name]) then
		Notifier:ShowError("Billionaire Services", _F("An escort group with the name %s already exists.", name))
		return
	end

	local members = group.members
	if (type(members) ~= "table" or #members ~= 3) then
		Notifier:ShowError("Billionaire Services", "A group must have exactly 3 members.")
		return
	end

	for _, member in ipairs(members) do
		if (not member.modelHash) then
			Notifier:ShowError("Billionaire Services", "Missing entity model hash for one or more group members.")
			return
		end

		if (not string.isvalid(member.name)) then
			member.name = self:GetRandomPedName(Game.GetPedGenderFromModel(member.modelHash))
		end

		if (math.is_null(member.weapon)) then
			member.weapon = _J("WEAPON_TECPISTOL")
		end
	end

	group.JSON                  = true
	self.EscortGroupsData[name] = group
	Serializer:WriteToFile(self.groups_file_name, self.EscortGroupsData)
	Notifier:ShowSuccess("Billionaire Services", _T("BSV2_ES_NEW_GROUP_SUCCESS"))
end

---@param groupName string
function BillionaireServices:RemoveSavedEscortGroup(groupName)
	local group = self.EscortGroupsData[groupName]
	if (not group or not group.JSON) then
		return
	end

	self.EscortGroupsData[groupName] = nil
	Serializer:WriteToFile(self.groups_file_name, self.EscortGroupsData)
end

---@return integer
function BillionaireServices:GetServiceCount()
	local count = 0

	if next(self.Bodyguards) ~= nil then
		count = count + 1
	end

	if next(self.EscortGroups) ~= nil then
		count = count + 1
	end

	for _, service in pairs(self.ActiveServices) do
		if service then
			count = count + 1
		end
	end

	return count
end

---@param gender ePedGender
---@return string
function BillionaireServices:GetRandomPedName(gender)
	math.randomseed(math.floor(os.clock() * 1e6))
	local randomNames = RandomPedNames[gender]
	return randomNames[math.random(1, #randomNames)] or "NULL"
end

---@param modelHash integer
---@param name? string
---@param spawnPos? vec3
---@param weapon? integer|boolean
---@param godmode? boolean
---@param disableRagdoll? boolean
---@param behavior? integer
function BillionaireServices:SpawnBodyguard(modelHash, name, spawnPos, weapon, godmode, disableRagdoll, behavior)
	ThreadManager:Run(function()
		local count = table.getlen(self.Bodyguards)
		if count > 1 and (count % 10 == 0) then
			Notifier:ShowWarning(
				"Samurai's Scripts",
				"[Warning] You're spawning too many bodyguards!"
			)
		end

		local ok, guard = pcall(Bodyguard.new,
			self,
			modelHash,
			name,
			spawnPos,
			weapon,
			godmode,
			disableRagdoll,
			behavior
		)

		if (not ok or not guard) then
			Notifier:ShowWarning("Billionaire Services", "Failed to create entity! Please try again later", true, 5)
			return
		end

		guard.role = guard.ROLES.BODYGUARD
		self:RegisterEntity(guard.m_handle)
		self.GroupManager:AddBodyguard(guard)
		self.Bodyguards[guard.m_handle] = guard
	end)
end

---@param handle integer
function BillionaireServices:GetBodyguardByHandle(handle)
	return self.Bodyguards[handle]
end

---@param bodyguard Bodyguard
function BillionaireServices:DismissBodyguard(bodyguard)
	ThreadManager:Run(function(s)
		self.GroupManager:RemoveBodyguard(bodyguard.m_handle)

		if table.getlen(self.Bodyguards) == 1 then
			bodyguard:Speak("GENERIC_BYE", "SPEECH_PARAMS_FORCE_SHOUTED")
		end

		if bodyguard:Dismiss(s) then
			self:RemoveBodyguard(bodyguard)
		end
	end)
end

function BillionaireServices:DismissAllBodyguards()
	local closest_bodyguard = self:GetClosestBodyguard()

	if closest_bodyguard and closest_bodyguard:IsAlive() then
		closest_bodyguard:Speak("GENERIC_BYE", "SPEECH_PARAMS_FORCE_SHOUTED")
	end

	for _, bodyguard in pairs(self.Bodyguards) do
		self:DismissBodyguard(bodyguard)
	end
end

---@param bodyguard Bodyguard
function BillionaireServices:RemoveBodyguard(bodyguard)
	bodyguard:ClearCombatTask()
	Game.DeleteEntity(bodyguard.m_handle)

	self:UnregisterEntity(bodyguard.m_handle)
	self.GroupManager:RemoveBodyguard(bodyguard.m_handle)
	self.Bodyguards[bodyguard.m_handle] = nil
end

---@return Bodyguard|nil
function BillionaireServices:GetClosestBodyguard()
	if next(self.Bodyguards) == nil then
		return
	end

	local allGuardDist = {}

	for _, guard in pairs(self.Bodyguards) do
		if guard:IsAlive() then
			local guardPos = guard:GetPos()

			table.insert(
				allGuardDist,
				{
					guard = guard,
					distance = guardPos:distance(LocalPlayer:GetPos())
				}
			)
		end
	end

	table.sort(allGuardDist, function(a, b)
		return a.distance < b.distance
	end)

	return allGuardDist[1].guard
end

---@param t_Data table
---@param godMode? boolean
---@param noRagdoll? boolean
---@param spawnPos? vec3
function BillionaireServices:SpawnEscortGroup(t_Data, godMode, noRagdoll, spawnPos)
	ThreadManager:Run(function()
		if (not LocalPlayer:IsOutside()) then
			Notifier:ShowError("Billionaire Services", _T("GENERIC_INTERIOR_ACTION_ERR"))
			return
		end

		if (LocalPlayer:IsInWater()) then
			Notifier:ShowError("Billionaire Services", _T("GENERIC_LOCATION_ACTION_ERR"))
			return
		end

		local count = table.getlen(self.EscortGroups)
		if (count > 1 and (count % 4 == 0)) then
			Notifier:ShowWarning("Billionaire Services", _T("BSV2_TOO_MANY_GROUPS_WARN"))
		end

		local ok, group = pcall(EscortGroup.Spawn,
			EscortGroup,
			self,
			t_Data,
			godMode,
			noRagdoll,
			spawnPos
		)

		if (not ok or not group) then
			Notifier:ShowError("Billionaire Services", _T("GENERIC_ENTITY_SPAWN_FAIL"))
			return
		end

		for _, member in ipairs(group.members) do
			self:RegisterEntity(member.m_handle)
		end

		self:RegisterEntity(group.vehicle.handle)
		self.GroupManager:AddEscortGroup(group)
		self.EscortGroups[group.name] = group
		self.EscortVehicles[group.vehicle.handle] = group.vehicle
	end)
end

---@param group EscortGroup
---@param godMode? boolean
---@param noRagdoll? boolean
function BillionaireServices:RespawnEscortGroup(group, godMode, noRagdoll)
	if not group.members or (table.getlen(group.members) == 0) then
		return
	end

	if not LocalPlayer:IsOutside() then
		Notifier:ShowError(
			"Samurai's Scripts",
			"Please go outside!"
		)
		return
	end

	ThreadManager:Run(function(s)
		local t_Data = group:ToTable()
		local spawnPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
			LocalPlayer:GetHandle(),
			math.random(-2, 2),
			-10,
			0.1
		)

		self:RemoveEscortGroup(group.name)
		s:sleep(250)
		self:SpawnEscortGroup(
			t_Data,
			godMode or false,
			noRagdoll or false,
			spawnPos
		)
	end)
end

---@param vehicleHandle integer
function BillionaireServices:GetEscortVehicleByHandle(vehicleHandle)
	return self.EscortVehicles[vehicleHandle] ~= nil
end

function BillionaireServices:IsPlayerInEscortVehicle()
	local PV = LocalPlayer:GetVehicle()
	return (PV:IsValid() and self:GetEscortVehicleByHandle(PV:GetHandle()))
end

---@param groupName string
function BillionaireServices:DismissEscortGroup(groupName)
	ThreadManager:Run(function(s)
		local group = self.EscortGroups[groupName]

		if group then
			self.GroupManager.Escorts[group.name].group = nil
			s:sleep(250)
			group:Dismiss(s)
		end

		self:RemoveEscortGroup(groupName)
	end)
end

function BillionaireServices:RemoveEscortGroup(groupName)
	local group = self.EscortGroups[groupName]

	if not group then
		return
	end

	for _, guard in ipairs(group.members) do
		Game.DeleteEntity(guard.m_handle)
	end

	Game.DeleteEntity(group.vehicle.handle)
	self.GroupManager.Escorts[group.name] = nil
	self.EscortGroups[groupName] = nil
	self.EscortVehicles[group.vehicle.handle] = nil
end

function BillionaireServices:DismissAllEscortGroups()
	for _, group in pairs(self.EscortGroups) do
		self:DismissEscortGroup(group.name)
	end
end

---@param t_Data table
---@param spawnPos? vec3
function BillionaireServices:CallPrivateLimo(t_Data, spawnPos)
	ThreadManager:Run(function()
		if (not LocalPlayer:IsOutside()) then
			Notifier:ShowError("Billionaire Services", _T("GENERIC_INTERIOR_ACTION_ERR"))
			return
		end

		if (LocalPlayer:IsInWater()) then
			Notifier:ShowError("Billionaire Services", _T("GENERIC_LOCATION_ACTION_ERR"))
			return
		end

		local ok, limo = pcall(PrivateLimo.Spawn, PrivateLimo, self, t_Data, spawnPos)
		if (not ok or not limo) then
			Notifier:ShowWarning("Billionaire Services", _T("GENERIC_ENTITY_SPAWN_FAIL"))
			return
		end

		self.ActiveServices.limo = limo
		self.GroupManager:AddPedToGroup(limo.driver)
		self:RegisterEntity(limo:GetHandle())
		self:RegisterEntity(limo.driver)
	end)
end

function BillionaireServices:PrepareLimoForCleanup()
	if not self.ActiveServices.limo then
		return
	end

	local limo = self.ActiveServices.limo
	self:UnregisterEntity(limo:GetHandle())
	self:UnregisterEntity(limo.driver)
end

function BillionaireServices:DismissLimo()
	if not self.ActiveServices.limo then
		return
	end

	self:PrepareLimoForCleanup()
	self.ActiveServices.limo:Dismiss()
	self.ActiveServices.limo = nil
end

function BillionaireServices:RemoveLimo()
	if not self.ActiveServices.limo then
		return
	end

	self:PrepareLimoForCleanup()
	self.ActiveServices.limo:Cleanup()
	self.ActiveServices.limo = nil
end

---@param model integer
---@param godmode? boolean
function BillionaireServices:CallPrivateHeli(model, godmode)
	ThreadManager:Run(function(s)
		if (not LocalPlayer:IsOutside()) then
			Notifier:ShowError("Billionaire Services", _T("GENERIC_INTERIOR_ACTION_ERR"))
			return
		end

		local isInWater = LocalPlayer:IsOnFoot() and LocalPlayer:IsInWater() or LocalPlayer:GetVehicle():IsBoat()
		local spawnPos  = LocalPlayer:GetOffsetInWorldCoords(0.0, 30.0, 50.0)
		local ok, heli  = pcall(PrivateHeli.spawn, self, model, spawnPos, godmode)

		if (not ok or not heli) then
			Notifier:ShowWarning("Billionaire Services", _T("GENERIC_ENTITY_SPAWN_FAIL"))
			return
		end

		self.ActiveServices.heli = heli
		self.GroupManager:AddPedToGroup(heli.pilot)
		self:RegisterEntity(heli.m_handle)
		self:RegisterEntity(heli.pilot)

		if (not isInWater) then
			local timer = Timer.new(3e4)
			TASK.TASK_HELI_MISSION(
				heli.pilot,
				heli.m_handle,
				0,
				0,
				spawnPos.x,
				spawnPos.y,
				spawnPos.z,
				19,
				8,
				1.0,
				0,
				-1,
				3,
				10.0,
				32
			)

			repeat
				s:sleep(1000)
			until ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(heli.m_handle) <= 3 or timer:IsDone()
		else
			Notifier:ShowMessage("Billionaire Services", _T("BSV2_HELI_LAND_WATER_ERR"))
		end

		AUDIO.PLAY_PED_AMBIENT_SPEECH_NATIVE(
			heli.pilot,
			"GENERIC_HOWS_IT_GOING",
			"SPEECH_PARAMS_FORCE_HELI",
			0
		)
		heli.isReady = true
	end)
end

function BillionaireServices:PrepareHeliForCleanup()
	if not self.ActiveServices.heli then
		return
	end

	local heli = self.ActiveServices.heli
	self:UnregisterEntity(heli.m_handle)
	self:UnregisterEntity(heli.pilot)
end

function BillionaireServices:DismissHeli()
	if not self.ActiveServices.heli then
		return
	end

	self:PrepareHeliForCleanup()
	self.ActiveServices.heli:Dismiss()
	self.ActiveServices.heli = nil
end

function BillionaireServices:RemoveHeli()
	if not self.ActiveServices.heli then
		return
	end

	self:PrepareHeliForCleanup()
	self.ActiveServices.heli:Cleanup()
	self.ActiveServices.heli = nil
end

---@param model integer
---@param airportData table
function BillionaireServices:CallPrivateJet(model, airportData)
	ThreadManager:Run(function()
		if not airportData or not airportData.hangar then
			Notifier:ShowError("Billionaire Services", _T("BSV2_JET_SPAWN_AIRPORT_ERR"))
			return
		end

		local ok, jet = pcall(PrivateJet.spawn, self, model, airportData)
		if (not ok or not jet) then
			Notifier:ShowWarning("Billionaire Services", _T("GENERIC_ENTITY_SPAWN_FAIL"))
			return
		end

		jet.departureAirport    = airportData
		self.ActiveServices.jet = jet
		self.GroupManager:AddPedToGroup(jet.pilot)
		self.GroupManager:AddPedToGroup(jet.copilot)
		self:RegisterEntity(jet:GetHandle())
		self:RegisterEntity(jet.pilot)
		self:RegisterEntity(jet.copilot)

		Notifier:ShowMessage("Billionaire Services",
			_F(_T("BSV2_JET_SPAWN_SUCCESS"), jet.name, airportData.name)
		)
	end)
end

function BillionaireServices:PrepareJetForCleanup()
	if not self.ActiveServices.jet then
		return
	end

	local jet = self.ActiveServices.jet
	self:UnregisterEntity(jet:GetHandle())
	self:UnregisterEntity(jet.pilot)
	self:UnregisterEntity(jet.copilot)
end

function BillionaireServices:DismissJet()
	if not self.ActiveServices.jet then
		return
	end

	if self.ActiveServices.jet:IsCruising() then
		if self.ActiveServices.jet:IsPlayerInJet() then
			Notifier:ShowError("Billionaire Services", _T("BSV2_JET_DISMISS_ERR"))
			return
		end

		self:RemoveJet()
		return
	end

	self:PrepareJetForCleanup()
	self.ActiveServices.jet:Dismiss()
	self.ActiveServices.jet = nil
end

function BillionaireServices:RemoveJet()
	if not self.ActiveServices.jet then
		return
	end

	self:PrepareJetForCleanup()
	self.ActiveServices.jet:Cleanup()
	self.ActiveServices.jet = nil
end

---@param serviceType ServiceType
function BillionaireServices:Dismiss(serviceType)
	if serviceType == self.SERVICE_TYPE.ALL then
		self:DismissAllBodyguards()
		self:DismissAllEscortGroups()
		self:DismissLimo()
		self:DismissHeli()
		self:DismissJet()
		return
	end

	if (serviceType == self.SERVICE_TYPE.BODYGUARD) then
		self:DismissAllBodyguards()
		return
	end

	if (serviceType == self.SERVICE_TYPE.ESCORT) then
		self:DismissAllEscortGroups()
		return
	end

	if (serviceType == self.SERVICE_TYPE.LIMO) then
		self:DismissLimo()
		return
	end

	if (serviceType == self.SERVICE_TYPE.HELI) then
		self:DismissHeli()
		return
	end

	if (serviceType == self.SERVICE_TYPE.JET) then
		self:DismissJet()
		return
	end
end

function BillionaireServices:RemoveEntityByHandle(handle)
	if next(self.Bodyguards) ~= nil then
		for _, guard in pairs(self.Bodyguards) do
			if (handle == guard.m_handle) then
				self:RemoveBodyguard(guard)
				return
			end
		end
	end

	if next(self.EscortGroups) ~= nil then
		for _, group in pairs(self.EscortGroups) do
			if (handle == group.vehicle.handle) then
				self:UnregisterEntity(group.vehicle.handle)
				Game.DeleteEntity(group.vehicle.handle)
			end

			for _, escort in pairs(group.members) do
				if (handle == escort.m_handle) then
					escort:ClearCombatTask()
					self:UnregisterEntity(escort.m_handle)
					Game.DeleteEntity(escort.m_handle)
				end
			end
		end
	end

	if self.ActiveServices.limo then
		if (handle == self.ActiveServices.limo:GetHandle())
			or (handle == self.ActiveServices.limo.driver) then
			self:RemoveLimo()
		end
	end
end

function BillionaireServices:Cleanup()
	self.GroupManager:Cleanup()
	self:RemoveLimo()

	if next(self.Bodyguards) ~= nil then
		for handle, guard in pairs(self.Bodyguards) do
			guard:ClearCombatTask()
			Game.DeleteEntity(handle)
		end
	end

	if next(self.EscortGroups) ~= nil then
		for _, group in pairs(self.EscortGroups) do
			for _, escort in pairs(group.members) do
				escort:ClearCombatTask()
				Game.DeleteEntity(escort.m_handle)
			end
		end
	end

	if next(self.EscortVehicles) ~= nil then
		for handle, _ in pairs(self.EscortVehicles) do
			Game.DeleteEntity(handle)
		end
	end

	self.Bodyguards     = {}
	self.EscortGroups   = {}
	self.EscortVehicles = {}
end

function BillionaireServices:ForceCleanup()
	self.GroupManager:Cleanup()

	if self.ActiveServices.limo then
		self.ActiveServices.limo:ForceCleanup()
	end

	if self.ActiveServices.heli then
		self.ActiveServices.heli:ForceCleanup()
	end

	if next(self.Bodyguards) ~= nil then
		for handle, guard in pairs(self.Bodyguards) do
			guard:ClearCombatTask()
			ENTITY.DELETE_ENTITY(handle)
		end
	end

	if next(self.EscortVehicles) ~= nil then
		for handle, _ in pairs(self.EscortVehicles) do
			ENTITY.DELETE_ENTITY(handle)
		end
	end

	if next(self.EscortGroups) ~= nil then
		for _, group in pairs(self.EscortGroups) do
			for _, escort in pairs(group.members) do
				escort:ClearCombatTask()
				ENTITY.DELETE_ENTITY(escort.m_handle)
			end
		end
	end

	self.Bodyguards     = {}
	self.EscortGroups   = {}
	self.EscortVehicles = {}
end

return BillionaireServices:init()
