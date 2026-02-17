-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")

---@class MagicBullet : FeatureBase
---@field private m_entity LocalPlayer
---@field private m_is_active boolean
---@field private m_last_aim_target handle
---@field private m_last_fired milliseconds
local MagicBullet = setmetatable({}, FeatureBase)
MagicBullet.__index = MagicBullet

---@param entity LocalPlayer
---@return MagicBullet
function MagicBullet.new(entity)
	local self = FeatureBase.new(entity)
	---@diagnostic disable-next-line
	return setmetatable(self, MagicBullet)
end

function MagicBullet:Init()
	self.m_is_active = false
	self.m_last_aim_target = 0
	self.m_last_fired = 0
end

function MagicBullet:ShouldRun()
	return GVars.features.weapon.magic_bullet
		and LocalPlayer:IsAlive()
		and WEAPON.IS_PED_ARMED(LocalPlayer:GetHandle(), 4)
end

function MagicBullet:Update()
	if (Time.Millis() - self.m_last_fired < 150) then
		return
	end

	if PLAYER.IS_PLAYER_FREE_AIMING(LocalPlayer:GetPlayerID()) then
		local entity = LocalPlayer:GetEntityInCrosshairs(false)
		if (entity and ENTITY.IS_ENTITY_A_PED(entity) and PED.IS_PED_HUMAN(entity)) then
			if (entity ~= 0) then
				self.m_last_aim_target = entity
			end

			-- local pedPos = Game.GetEntityCoords(entity, true)
			-- if (not PED.HAS_PED_CLEAR_LOS_TO_ENTITY_(LocalPlayer:GetHandle(), self.m_last_aim_target, pedPos.x, pedPos.y, pedPos.z, 0, false, false)) then -- uses expensive LOS test
			-- 	self.m_last_aim_target = 0
			-- end
		end
	elseif (self.m_last_aim_target ~= 0) then
		self.m_last_aim_target = 0
	end

	if self.m_last_aim_target ~= 0 and not ENTITY.IS_ENTITY_DEAD(self.m_last_aim_target, false) then
		local wpn_hash = LocalPlayer:GetCurrentWeaponHash()
		if Game.RequestWeaponAsset(wpn_hash) and PAD.IS_CONTROL_PRESSED(0, 24) and not PED.IS_PED_RELOADING(LocalPlayer:GetHandle()) then
			local pedBonePos = PED.GET_PED_BONE_COORDS(self.m_last_aim_target, 0x796E, 0, 0, 0)
			MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
				pedBonePos.x - 1.0,
				pedBonePos.y - 1.0,
				pedBonePos.z,
				pedBonePos.x + 1.0,
				pedBonePos.y + 1.0,
				pedBonePos.z,
				300,
				false,
				wpn_hash,
				LocalPlayer:GetHandle(),
				true,
				false,
				-1082130432
			)

			self.m_last_fired = Time.Millis() + 150
		end
	end
end

return MagicBullet
