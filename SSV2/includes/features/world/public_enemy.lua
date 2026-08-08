-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")
local Set         = require("includes.classes.Set")


local pedCombatAttr <const>  = {
	{ flag = 5,  val = true },
	{ flag = 13, val = true },
	{ flag = 21, val = true },
	{ flag = 28, val = true },
	{ flag = 31, val = true },
	{ flag = 38, val = true },
	{ flag = 42, val = true },
	{ flag = 46, val = true },
	{ flag = 58, val = true },
	{ flag = 71, val = true },
	{ flag = 17, val = false },

	-- BF_FleesFromInvincibleOpponents: for some reason touching this flag in any way
	-- always makes the npcs run from you when you're in god mode
	-- { flag = 63, val = false },
}
local pedConfigFlags <const> = {
	{ flag = 128, val = true },
	{ flag = 140, val = true },
	{ flag = 141, val = true },
	{ flag = 208, val = true },
	{ flag = 229, val = true },
	{ flag = 294, val = true },
	{ flag = 435, val = true },
}


---@class PublicEnemy : FeatureBase
---@field private m_last_scan_time TimePoint
---@field private m_last_task_time TimePoint
---@field private m_hostile_peds Set<handle>
---@field private m_hostile_count number
---@field private m_tasked_ped_count number
---@field private m_max_count number
---@field private m_is_ignored_by_popo boolean
---@field public m_enabled boolean -- We're not serializing this so we won't be using GVars
local PublicEnemy   = setmetatable({}, FeatureBase)
PublicEnemy.__index = PublicEnemy

---@param entity any
---@return PublicEnemy
function PublicEnemy.new(entity)
	local self = FeatureBase.new(entity)
	---@diagnostic disable-next-line
	return setmetatable(self, PublicEnemy)
end

function PublicEnemy:Init()
	self.m_enabled            = false
	self.m_is_ignored_by_popo = false
	self.m_hostile_peds       = Set()
	self.m_last_scan_time     = TimePoint()
	self.m_last_task_time     = TimePoint()
	self.m_hostile_count      = 0
	self.m_tasked_ped_count   = 0
	self.m_max_count          = 50
end

function PublicEnemy:ShouldRun()
	return self.m_enabled
		and LocalPlayer:IsOutside()
		and LocalPlayer:IsAlive()
		and not NETWORK.NETWORK_IS_ACTIVITY_SESSION()
end

function PublicEnemy:Cleanup()
	for ped in self.m_hostile_peds:Iter() do
		self:TogglePedConfig(ped, false)
	end

	self.m_hostile_peds:Clear()
	self.m_is_ignored_by_popo = false
	PLAYER.SET_POLICE_IGNORE_PLAYER(LocalPlayer:GetID(), false)
end

---@param ped handle
---@param toggle boolean
function PublicEnemy:TogglePedConfig(ped, toggle)
	for _, attr in ipairs(pedCombatAttr) do
		PED.SET_PED_COMBAT_ATTRIBUTES(ped, attr.flag, toggle and attr.val or not attr.val)
	end

	for _, cflag in ipairs(pedConfigFlags) do
		PED.SET_PED_CONFIG_FLAG(ped, cflag.flag, toggle and cflag.val or not cflag.val)
	end

	-- these sound like they are the same but they're not. they behave differently based on multiple test scenarios
	PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, toggle)
	TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, toggle)

	if (not toggle) then
		TASK.CLEAR_PED_TASKS(ped)
	end
end

function PublicEnemy:UpdateHostilePeds()
	if (not self.m_last_scan_time:HasElapsed(3000)) then
		return
	end

	if (self.m_hostile_count >= self.m_max_count) then
		return
	end

	local hostiles     = self.m_hostile_peds
	local playerHandle = LocalPlayer:GetHandle()
	for _, ped in ipairs(entities.get_all_peds_as_handles()) do
		if (ped ~= playerHandle
				and not PED.IS_PED_A_PLAYER(ped)
				and not PED.IS_PED_GROUP_MEMBER(ped, LocalPlayer:GetGroupIndex())
				and not Backend:IsScriptEntity(ped)
				and not hostiles:Contains(ped)
			) then
			self:TogglePedConfig(ped, true)
			hostiles:Push(ped)
		end
		yield()
	end

	self.m_last_scan_time:Reset()
	self.m_hostile_count = hostiles:Size()
end

function PublicEnemy:TaskCombat()
	if (not self.m_last_task_time:HasElapsed(1000)) then
		return
	end

	if (self.m_tasked_ped_count == self.m_hostile_count) then
		return
	end

	local trash        = {}
	local hostiles     = self.m_hostile_peds
	local playerHandle = LocalPlayer:GetHandle()
	local playerPos    = LocalPlayer:GetPos()

	for ped in hostiles:Iter() do
		if (not ENTITY.DOES_ENTITY_EXIST(ped) or ENTITY.IS_ENTITY_DEAD(ped, true)) then
			table.insert(trash, ped)
			goto continue
		end

		local pedPos = Game.GetEntityCoords(ped, true)
		if (playerPos:distance(pedPos) > 200) then
			table.insert(trash, ped)
			goto continue
		end

		if (WEAPON.IS_PED_ARMED(ped, 7)) then
			WEAPON.SET_PED_DROPS_WEAPON(ped)
		end

		if (not PED.IS_PED_IN_COMBAT(ped, playerHandle)) then
			TASK.TASK_COMBAT_PED(ped, playerHandle, 0, 16)
		end

		::continue::
	end

	for _, ped in ipairs(trash) do
		if (hostiles:Contains(ped)) then
			hostiles:Pop(ped)
		end
	end

	self.m_hostile_count    = hostiles:Size()
	self.m_tasked_ped_count = self.m_hostile_count
	self.m_last_task_time:Reset()
end

function PublicEnemy:Update()
	if (Game.IsPlayerSwitchInProgress()) then
		self:Cleanup()
		return
	end

	self:UpdateHostilePeds()

	local hostiles = self.m_hostile_peds
	if (hostiles:IsEmpty()) then
		return
	end

	if (not self.m_is_ignored_by_popo) then
		PLAYER.SET_POLICE_IGNORE_PLAYER(LocalPlayer:GetID(), true)
		self.m_is_ignored_by_popo = true
	end

	self:TaskCombat()

	for ped in hostiles:Iter() do
		PED.SET_PED_RESET_FLAG(
			ped,
			Enums.ePedResetFlags.IgnoreCombatManager, -- so they can all gang up on you and beat your ass without waiting for their turns
			true
		)
	end
end

return PublicEnemy
