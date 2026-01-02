---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local FeatureBase            = require("includes.modules.FeatureBase")
local World                  = require("includes.modules.World")

---@class LaserSights : FeatureBase
---@field private m_entity Self
---@field private m_is_active boolean
---@field private m_color Color
local LaserSights            = setmetatable({}, FeatureBase)
LaserSights.__index          = LaserSights

LaserSights.WeaponExclusions = Set.new(
	0x34A67B97,
	0xBA536372,
	0x184140A1,
	0x060EC506
)

LaserSights.WeaponBoneNames  = {
	"WAPLasr",
	"WAPLasr_2",
	"WAPFlshLasr",
	"WAPFlshLasr_2",
	"WAPFlsh",
	"WAPFlsh_2",
	"gun_barrels",
	"gun_muzzle"
}

---@param entity Self
---@return LaserSights
function LaserSights.new(entity)
	local self = FeatureBase.new(entity)
	return setmetatable(self, LaserSights)
end

function LaserSights:Init()
	self.m_is_active = false
	KeyManager:RegisterKeybind(
		GVars.features.weapon.laser_sights.keybind,
		function()
			ThreadManager:Run(function()
				if (not PLAYER.IS_PLAYER_FREE_AIMING(Self:GetPlayerID())) then
					return
				end

				GVars.features.weapon.laser_sights.enabled = not GVars.features.weapon.laser_sights.enabled
				AUDIO.PLAY_SOUND_FRONTEND(
					-1,
					"TARGET_COUNTER_TICK",
					"DLC_SM_GENERIC_MISSION_SOUNDS",
					false
				)
			end)
		end,
		false
	)
end

function LaserSights:ShouldRun()
	return GVars.features.weapon.laser_sights.enabled
		and Self:IsAlive()
		and Self:IsOnFoot()
		and WEAPON.IS_PED_ARMED(Self:GetHandle(), 4)
		and PLAYER.IS_PLAYER_FREE_AIMING(Self:GetPlayerID())
end

---@param startPos vec3
---@param endPos vec3
---@param r number
---@param g number
---@param b number
---@param a number
function LaserSights:DrawLaserBeam(startPos, endPos, r, g, b, a)
	local multiplier = 0.0001
	GRAPHICS.DRAW_LINE(
		startPos.x,
		startPos.y,
		startPos.z,
		endPos.x,
		endPos.y,
		endPos.z,
		r, g, b, a
	)

	for i = 1, 18, 1 do
		local offset = i % 9 == 0 and i * multiplier or i * -multiplier
		GRAPHICS.DRAW_LINE(
			startPos.x + offset,
			startPos.y,
			startPos.z,
			endPos.x,
			endPos.y,
			endPos.z,
			r, g, b, a
		)
	end
end

function LaserSights:Update()
	local wpn_hash = Self:GetCurrentWeaponHash()
	if (self.WeaponExclusions:Contains(wpn_hash)) then
		return
	end

	local wpn_idx = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(Self:GetHandle(), 0)
	local wpn_bone = 0
	for _, bone in ipairs(self.WeaponBoneNames) do
		local boneIndex = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(wpn_idx, bone)
		if (boneIndex ~= -1) then
			wpn_bone = boneIndex
			break
		end
	end

	local color = GVars.features.weapon.laser_sights.color
	local bone_pos = ENTITY.GET_ENTITY_BONE_POSTION(wpn_idx, wpn_bone)
	local camRotation = CAM.GET_GAMEPLAY_CAM_ROT(0)
	local direction = camRotation:to_direction()
	local destination = vec3:new(
		bone_pos.x + direction.x * GVars.features.weapon.laser_sights.ray_length,
		bone_pos.y + direction.y * GVars.features.weapon.laser_sights.ray_length,
		bone_pos.z + direction.z * GVars.features.weapon.laser_sights.ray_length
	)

	local hit, endCoords, _ = World:RayCast(bone_pos, destination, -1, Self:GetHandle())
	local r, g, b, a = math.min(255, color.x * 255),
		math.min(255, color.y * 255),
		math.min(255, color.z * 255),
		math.min(255, color.w * 255)

	self:DrawLaserBeam(bone_pos, hit and endCoords or destination, r, g, b, a)
	if (hit) then
		GRAPHICS.DRAW_MARKER(
			28,
			endCoords.x,
			endCoords.y,
			endCoords.z,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.01,
			0.01,
			0.01,
			r, g, b, a,
			---@diagnostic disable-next-line
			false, false, 2, false, 0, 0, false
		)
	end
end

return LaserSights
