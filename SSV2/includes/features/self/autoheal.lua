-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")

---@class AutoHeal : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_active boolean
---@field private m_last_update_time milliseconds
local AutoHeal = setmetatable({}, FeatureBase)
AutoHeal.__index = AutoHeal

---@param ent LocalPlayer
---@return AutoHeal
function AutoHeal.new(ent)
	local self = FeatureBase.new(ent)
	---@diagnostic disable-next-line
	return setmetatable(self, AutoHeal)
end

function AutoHeal:Init()
	self.m_active = false
	self.m_last_update_time = 0
end

function AutoHeal:ShouldRun()
	return (GVars.features.self.autoheal.enabled
		and LocalPlayer:IsAlive()
		and not Backend:IsPlayerSwitchInProgress()
		and not script.is_active("maintransition")
	)
end

function AutoHeal:Update()
	if (Time.millis() < self.m_last_update_time) then
		return
	end

	local maxHp = LocalPlayer:GetMaxHealth()
	local hp = LocalPlayer:GetHealth()
	local maxArmr = LocalPlayer:GetMaxArmour()
	local armor = LocalPlayer:GetArmour()
	local handle = LocalPlayer:GetHandle()

	if (hp < maxHp and hp > 0) then
		if (PED.IS_PED_IN_COVER(handle, false)) then
			ENTITY.SET_ENTITY_HEALTH(handle, hp + 10, 0, 0)
		else
			ENTITY.SET_ENTITY_HEALTH(handle, hp + 1, 0, 0)
		end
	end

	if (armor == nil) then
		PED.SET_PED_ARMOUR(handle, 10)
	end

	if (armor and armor < maxArmr) then
		PED.ADD_ARMOUR_TO_PED(handle, 0.5)
	end

	self.m_last_update_time = Time.millis() + (1000 / GVars.features.self.autoheal.regen_speed)
end

return AutoHeal
