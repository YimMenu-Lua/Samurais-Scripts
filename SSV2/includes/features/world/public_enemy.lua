-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase                  = require("includes.modules.FeatureBase")

---@class PublicEnemy : FeatureBase
---@field private m_last_scan_time TimePoint
---@field private m_last_task_time TimePoint
---@field private m_hostile_peds Set<handle>
---@field private m_hostile_count number
---@field private m_last_hostile_count number
---@field private m_max_count number
---@field public m_enabled boolean -- We're not serializing this so we won't be using GVars
local PublicEnemy                  = setmetatable({}, FeatureBase)
PublicEnemy.__index                = PublicEnemy

local t_PEcombatAttributes <const> = {
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

local t_PEconfigFlags <const>      = {
	{ flag = 128, val = true },
	{ flag = 140, val = true },
	{ flag = 141, val = true },
	{ flag = 208, val = true },
	{ flag = 229, val = true },
	{ flag = 294, val = true },
	{ flag = 435, val = true },
}

---@param entity any
---@return PublicEnemy
function PublicEnemy.new(entity)
	local self = FeatureBase.new(entity)
	---@diagnostic disable-next-line
	return setmetatable(self, PublicEnemy)
end

function PublicEnemy:Init()
	self.m_enabled            = false
	self.m_hostile_peds       = Set.new()
	self.m_last_scan_time     = TimePoint.new()
	self.m_last_task_time     = TimePoint.new()
	self.m_hostile_count      = 0
	self.m_last_hostile_count = 0
	self.m_max_count          = 50
end

function PublicEnemy:ShouldRun()
	return self.m_enabled
		and Self:IsOutside()
		and not NETWORK.NETWORK_IS_ACTIVITY_SESSION()
end

function PublicEnemy:Cleanup()
	if (self.m_hostile_peds:IsEmpty()) then
		return
	end

	for ped in self.m_hostile_peds:Iter() do
		self:TogglePedConfig(ped, false)
	end
end

---@param ped handle
---@param toggle boolean
function PublicEnemy:TogglePedConfig(ped, toggle)
	for _, attr in ipairs(t_PEcombatAttributes) do
		PED.SET_PED_COMBAT_ATTRIBUTES(ped, attr.flag, toggle and attr.val or not attr.val)
	end

	for _, cflag in ipairs(t_PEconfigFlags) do
		PED.SET_PED_CONFIG_FLAG(ped, cflag.flag, toggle and cflag.val or not cflag.val)
	end

	PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, toggle)
	TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, toggle)

	if (not toggle) then
		TASK.CLEAR_PED_TASKS(ped)
	end
end

function PublicEnemy:UpdateHostileSet()
	if (not self.m_last_scan_time:has_elapsed(3000)) then
		return
	end

	if (self.m_hostile_count >= self.m_max_count) then
		return
	end

	local playerHandle = Self:GetHandle()
	for _, ped in pairs(entities.get_all_peds_as_handles()) do
		if (ped ~= playerHandle
				and not PED.IS_PED_A_PLAYER(ped)
				and not PED.IS_PED_GROUP_MEMBER(ped, Self:GetGroupIndex())
				and not Backend:IsScriptEntity(ped)
				and not self.m_hostile_peds:Contains(ped)
			) then
			self:TogglePedConfig(ped, true)
			self.m_hostile_peds:Push(ped)
		end

		yield()
	end

	self.m_last_scan_time:reset()
	self.m_hostile_count = self.m_hostile_peds:Size()
end

function PublicEnemy:TaskCombat()
	if (not self.m_last_task_time:has_elapsed(1000)) then
		return
	end

	if (self.m_hostile_peds:IsEmpty()) then
		return
	end

	if (self.m_last_hostile_count == self.m_hostile_count) then
		return
	end

	local trash = {}
	local playerHandle = Self:GetHandle()
	for ped in self.m_hostile_peds:Iter() do
		local pedPos = Game.GetEntityCoords(ped, true)
		if (not ENTITY.DOES_ENTITY_EXIST(ped) or ENTITY.IS_ENTITY_DEAD(ped, true) or Self:GetPos():distance(pedPos) > 200) then
			table.insert(trash, ped)
		end

		if (WEAPON.IS_PED_ARMED(ped, 7)) then
			WEAPON.SET_PED_DROPS_WEAPON(ped)
		end

		if (not PED.IS_PED_IN_COMBAT(ped, playerHandle)) then
			TASK.TASK_COMBAT_PED(ped, playerHandle, 0, 16)
		end
	end

	for _, ped in ipairs(trash) do
		if self.m_hostile_peds:Contains(ped) then
			self.m_hostile_peds:Pop(ped)
		end
	end

	self.m_hostile_count      = self.m_hostile_peds:Size()
	self.m_last_hostile_count = self.m_hostile_count
	self.m_last_task_time:reset()
end

function PublicEnemy:Update()
	self:UpdateHostileSet()
	self:TaskCombat()

	if (self.m_hostile_peds:IsEmpty()) then
		return
	end

	for ped in self.m_hostile_peds:Iter() do
		PED.SET_PED_RESET_FLAG(ped, Enums.ePedResetFlags.IgnoreCombatManager, true) -- so they can all gang up on you and beat your ass without waiting for their turns
	end
end

return PublicEnemy
