---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local FeatureBase = require("includes.modules.FeatureBase")

---@class MagicBullet : FeatureBase
---@field private m_entity Self
---@field private m_is_active boolean
---@field private m_last_aim_target handle
---@field private m_last_fired milliseconds
local MagicBullet = setmetatable({}, FeatureBase)
MagicBullet.__index = MagicBullet

---@param entity Self
---@return MagicBullet
function MagicBullet.new(entity)
	local self = FeatureBase.new(entity)
	return setmetatable(self, MagicBullet)
end

function MagicBullet:Init()
	self.m_is_active = false
	self.m_last_aim_target = 0
	self.m_last_fired = 0
end

function MagicBullet:ShouldRun()
	return GVars.features.weapon.magic_bullet
		and Self:IsAlive()
		and WEAPON.IS_PED_ARMED(Self:GetHandle(), 4)
end

function MagicBullet:Update()
	if (Time.millis() - self.m_last_fired < 150) then
		return
	end

	if PLAYER.IS_PLAYER_FREE_AIMING(Self:GetPlayerID()) then
		local entity = Self:GetEntityInCrosshairs(false)
		if (ENTITY.IS_ENTITY_A_PED(entity) and PED.IS_PED_HUMAN(entity)) then
			if (entity ~= 0) then
				self.m_last_aim_target = entity
			end

			-- local pedPos = Game.GetEntityCoords(entity, true)
			-- if (not PED.HAS_PED_CLEAR_LOS_TO_ENTITY_(Self:GetHandle(), self.m_last_aim_target, pedPos.x, pedPos.y, pedPos.z, 0, false, false)) then -- uses expensive LOS test
			-- 	self.m_last_aim_target = 0
			-- end
		end
	elseif (self.m_last_aim_target ~= 0) then
		self.m_last_aim_target = 0
	end

	if self.m_last_aim_target ~= 0 and not ENTITY.IS_ENTITY_DEAD(self.m_last_aim_target, false) then
		local wpn_hash = Self:GetCurrentWeaponHash()
		if Game.RequestWeaponAsset(wpn_hash) and PAD.IS_CONTROL_PRESSED(0, 24) and not PED.IS_PED_RELOADING(Self:GetHandle()) then
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
				Self:GetHandle(),
				true,
				false,
				-1082130432
			)

			self.m_last_fired = Time.millis() + 150
		end
	end
end

return MagicBullet
