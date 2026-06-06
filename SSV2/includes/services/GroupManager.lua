-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Set = require("includes.classes.Set")


--------------------------------------
-- Class: Key
--------------------------------------
---@class GroupManager : Callable<GroupManager>
---@field private m_owner_ref BillionaireServices
---@field private m_initialized boolean
---@field private m_relationship_group integer
---@field public globalTick number
---@field public Bodyguards table<handle, { member: Bodyguard, lastTaskTime: seconds }>
---@field public Escorts table<string, { group: EscortGroup, lastTaskTime: seconds }>
---@overload fun(bsv2: BillionaireServices) : GroupManager
local GroupManager = Callable("GroupManager")

---@param bsv2 BillionaireServices
function GroupManager:init(bsv2)
	if (self.m_initialized) then return self end
	if (_G.GroupManager) then return _G.GroupManager end

	self.m_owner_ref   = bsv2
	self.globalTick    = 0
	self.Bodyguards    = {}
	self.Escorts       = {}
	self.m_initialized = true

	ThreadManager:RegisterLooped("SS_GROUPMGR", function(s)
		self:OnTick(s)
		yield()
	end, {
		exception_handler = function()
			self:Cleanup()
		end
	})

	_G.GroupManager = self
	return self
end

function GroupManager:Setup()
	if (self.m_relationship_group) then
		return
	end

	if (PED.DOES_RELATIONSHIP_GROUP_EXIST(_J("WOMPUS_SPECIAL"))) then
		self.m_relationship_group = _J("WOMPUS_SPECIAL")
	else
		_, self.m_relationship_group = PED.ADD_RELATIONSHIP_GROUP("WOMPUS_SPECIAL", _J("WOMPUS_SPECIAL"))
	end

	PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, self.m_relationship_group, LocalPlayer:GetRelationshipGroupHash())
	PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, LocalPlayer:GetRelationshipGroupHash(), self.m_relationship_group)
	PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, self.m_relationship_group, self.m_relationship_group)
end

---@param handle integer
function GroupManager:AddPedToGroup(handle)
	if (not self.m_relationship_group) then
		self:Setup()
	end

	if (ENTITY.DOES_ENTITY_EXIST(handle) and ENTITY.IS_ENTITY_A_PED(handle)) then
		PED.SET_PED_RELATIONSHIP_GROUP_HASH(handle, self.m_relationship_group)
		ENTITY.SET_ENTITY_CAN_BE_DAMAGED_BY_RELATIONSHIP_GROUP(handle, false, self.m_relationship_group)
	end
end

---@param bodyguard Bodyguard
function GroupManager:AddBodyguard(bodyguard)
	if (not self.m_relationship_group) then
		self:Setup()
	end

	if not (ENTITY.DOES_ENTITY_EXIST(bodyguard.m_handle) and ENTITY.IS_ENTITY_A_PED(bodyguard.m_handle)) then
		return
	end

	PED.SET_PED_RELATIONSHIP_GROUP_HASH(bodyguard.m_handle, self.m_relationship_group)
	ENTITY.SET_ENTITY_CAN_BE_DAMAGED_BY_RELATIONSHIP_GROUP(bodyguard.m_handle, false, self.m_relationship_group)

	bodyguard.tickOffset = (table.getlen(self.Bodyguards) % 4)
	self.Bodyguards[bodyguard.m_handle] = {
		member       = bodyguard,
		lastTaskTime = Time.Now()
	}
end

---@param group EscortGroup
function GroupManager:AddEscortGroup(group)
	if (not self.m_relationship_group) then
		self:Setup()
	end

	local count = table.getlen(self.Escorts)
	for _, member in pairs(group.members) do
		if (ENTITY.DOES_ENTITY_EXIST(member.m_handle) and ENTITY.IS_ENTITY_A_PED(member.m_handle)) then
			PED.SET_PED_RELATIONSHIP_GROUP_HASH(member.m_handle, self.m_relationship_group)
			ENTITY.SET_ENTITY_CAN_BE_DAMAGED_BY_RELATIONSHIP_GROUP(member.m_handle, false, self.m_relationship_group)
			member.tickOffset = (count % 4)
		end
	end

	self.Escorts[group.name] = {
		group        = group,
		lastTaskTime = Time.Now()
	}
end

---@param pedHandle integer
function GroupManager:GetBodyguardByHandle(pedHandle)
	return self.Bodyguards[pedHandle] ~= nil
end

---@param pedHandle integer
function GroupManager:RemoveBodyguard(pedHandle)
	self.Bodyguards[pedHandle] = nil
end

function GroupManager:Cleanup()
	self.Bodyguards = {}
	self.Escorts    = {}
end

---@param s script_util
function GroupManager:HandleBodyuards(s)
	if (next(self.Bodyguards) == nil) then
		return
	end

	local trash        = Set() ---@type Set<handle>
	local globalTick   = self.globalTick
	local playerCoords = LocalPlayer:GetPos()
	for ped, data in pairs(self.Bodyguards) do
		if (not Backend:IsScriptEntity(ped)) then
			trash:Push(ped)
			goto continue
		end

		local guard = data.member
		if (guard and guard.tickOffset and (globalTick % 4 == guard.tickOffset)) then
			local now = Time.Now()
			if (now - data.lastTaskTime < 1) then
				goto continue
			end

			local guardPos = guard:GetPos()
			local distance = guardPos:distance(playerCoords)
			if (guard:IsOnFoot() and LocalPlayer:IsOnFoot() and distance > 3) then
				guard:QueueTask(guard.TASKS.FOLLOW, guard:TaskGoToEntity())
			end

			guard:UpdateTasks()
			guard:UpdatePosition(false)
			guard:HandleVehicleTransitions()
			guard:TickCombat()
			guard:TickVehicleEscort(s)
			guard:StateEval()

			data.lastTaskTime = now
		end

		::continue::
	end

	for handle in trash:Iter() do
		self.Bodyguards[handle] = nil
	end
	trash:Clear()
end

---@param s script_util
function GroupManager:HandleEscorts(s)
	if (next(self.Escorts) == nil) then
		return
	end

	local trash      = Set() ---@type Set<string>
	local globalTick = self.globalTick
	for name, data in pairs(self.Escorts) do
		local group = data.group
		if (not group) then
			trash:Push(name)
			goto continue
		end

		local now = Time.Now()
		if (now - data.lastTaskTime < 1) then
			goto continue
		end

		group:BackgroundWorker(s, globalTick)
		data.lastTaskTime = now

		::continue::
	end

	for name in trash:Iter() do
		self.Escorts[name] = nil
	end
	trash:Clear()
end

---@param s script_util
function GroupManager:OnTick(s)
	local BSV2 = self.m_owner_ref
	self.globalTick = (self.globalTick + 1) % 1e6
	self:HandleBodyuards(s)
	self:HandleEscorts(s)

	if (BSV2.ActiveServices.limo) then
		BSV2.ActiveServices.limo:StateEval()
	end

	if (BSV2.ActiveServices.heli) then
		BSV2.ActiveServices.heli:StateEval()
	end

	if (BSV2.ActiveServices.jet) then
		BSV2.ActiveServices.jet:StateEval()
	end
end

return GroupManager
