-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class GroupManager
---@field relationshipGroup integer
---@field globalTick number
---@field Bodyguards table<handle, { member: Bodyguard, lastTaskTime: seconds }>
local GroupManager = { globalTick = 0 }
GroupManager.__index = GroupManager
GroupManager.Bodyguards = {}
GroupManager.Escorts = {}

function GroupManager:Init()
	if not self.relationshipGroup then
		if (PED.DOES_RELATIONSHIP_GROUP_EXIST(joaat("WOMPUS_SPECIAL"))) then
			self.relationshipGroup = joaat("WOMPUS_SPECIAL")
		else
			_, self.relationshipGroup = PED.ADD_RELATIONSHIP_GROUP("WOMPUS_SPECIAL", joaat("WOMPUS_SPECIAL"))
		end

		PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, self.relationshipGroup, LocalPlayer:GetRelationshipGroupHash())
		PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, LocalPlayer:GetRelationshipGroupHash(), self.relationshipGroup)
		PED.SET_RELATIONSHIP_BETWEEN_GROUPS(0, self.relationshipGroup, self.relationshipGroup)
	end
end

---@param handle integer
function GroupManager:AddPedToGroup(handle)
	if (not self.relationshipGroup) then
		self:Init()
	end

	if ENTITY.DOES_ENTITY_EXIST(handle) and ENTITY.IS_ENTITY_A_PED(handle) then
		PED.SET_PED_RELATIONSHIP_GROUP_HASH(handle, self.relationshipGroup)
		ENTITY.SET_ENTITY_CAN_BE_DAMAGED_BY_RELATIONSHIP_GROUP(handle, false, self.relationshipGroup)
	end
end

---@param bodyguard Bodyguard
function GroupManager:AddBodyguard(bodyguard)
	if (not self.relationshipGroup) then
		self:Init()
	end

	if (ENTITY.DOES_ENTITY_EXIST(bodyguard.m_handle) and ENTITY.IS_ENTITY_A_PED(bodyguard.m_handle)) then
		PED.SET_PED_RELATIONSHIP_GROUP_HASH(bodyguard.m_handle, self.relationshipGroup)
		ENTITY.SET_ENTITY_CAN_BE_DAMAGED_BY_RELATIONSHIP_GROUP(bodyguard.m_handle, false, self.relationshipGroup)

		bodyguard.tickOffset = (#self.Bodyguards % 4)
		self.Bodyguards[bodyguard.m_handle] = {
			member = bodyguard,
			lastTaskTime = Time.now()
		}
	end
end

---@param group EscortGroup
function GroupManager:AddEscortGroup(group)
	if not self.relationshipGroup then
		self:Init()
	end

	for _, member in pairs(group.members) do
		if ENTITY.DOES_ENTITY_EXIST(member.m_handle) and ENTITY.IS_ENTITY_A_PED(member.m_handle) then
			PED.SET_PED_RELATIONSHIP_GROUP_HASH(member.m_handle, self.relationshipGroup)
			ENTITY.SET_ENTITY_CAN_BE_DAMAGED_BY_RELATIONSHIP_GROUP(member.m_handle, false, self.relationshipGroup)

			member.tickOffset = (#self.Escorts % 4)
		end
	end

	self.Escorts[group.name] = {
		group = group,
		lastTaskTime = Time.now()
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
	self.Escorts = {}
end

---@param s script_util
function GroupManager:HandleBodyuards(s)
	if next(self.Bodyguards) == nil then
		return
	end

	local playerCoords = LocalPlayer:GetPos()
	for ped, data in pairs(self.Bodyguards) do
		if data and ped and Backend:IsScriptEntity(ped) then
			---@type Bodyguard
			local guard = data.member

			if guard and guard.tickOffset and (self.globalTick % 4 == guard.tickOffset) then
				if (data.lastTaskTime < Time.now()) then
					local guardPos = guard:GetPos()
					local distance = guardPos:distance(playerCoords)

					if guard:IsOnFoot() and LocalPlayer:IsOnFoot() and distance > 5 then
						guard:QueueTask(guard.TASKS.FOLLOW, guard:TaskGoToEntity())
					end

					guard:UpdateTasks()
					guard:UpdatePosition(false)
					guard:HandleVehicleTransitions()
					guard:TickCombat()
					guard:TickVehicleEscort(s)
					guard:StateEval()

					data.lastTaskTime = Time.now() + 1
				end
			end
		else
			self.Bodyguards[ped] = nil
		end
	end
end

---@param s script_util
function GroupManager:HandleEscorts(s)
	if next(self.Escorts) == nil then
		return
	end

	for _, data in pairs(self.Escorts) do
		if data and (data.lastTaskTime < Time.now()) then
			---@type EscortGroup
			local group = data.group
			if group then
				group:BackgroundWorker(s, self.globalTick)
			end
			data.lastTaskTime = Time.now() + 1
		end
	end
	s:sleep(1)
end

---@param s script_util
function GroupManager:OnTick(s)
	self.globalTick = (self.globalTick + 1) % 1e6
	self:HandleBodyuards(s)
	self:HandleEscorts(s)

	if BillionaireServices.ActiveServices.limo then
		BillionaireServices.ActiveServices.limo:StateEval()
	end

	if BillionaireServices.ActiveServices.heli then
		BillionaireServices.ActiveServices.heli:StateEval()
	end

	if BillionaireServices.ActiveServices.jet then
		BillionaireServices.ActiveServices.jet:StateEval()
	end
end

ThreadManager:RegisterLooped("SS_GROUPMGR", function(s)
	GroupManager:OnTick(s)
	yield()
end)

return GroupManager
