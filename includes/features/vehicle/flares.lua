---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local Refs        = require("includes.data.refs")
local FeatureBase = require("includes.modules.FeatureBase")

---@class Flares : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_is_active boolean
---@field private m_shots table
---@field private m_next_shot_time seconds
---@field protected m_thread Thread
local Flares      = setmetatable({}, FeatureBase)
Flares.__index    = Flares

---@param pv PlayerVehicle
---@return Flares
function Flares.new(pv)
	local self = FeatureBase.new(pv)
	return setmetatable(self, Flares)
end

function Flares:Init()
	self.m_is_active = false
	self.m_shots = {}
	self.m_next_shot_time = 0
	self.m_thread = ThreadManager:RegisterLooped("SS_FLARES", function()
		self:OnTick()
	end, not GVars.features.vehicle.flares)
end

function Flares:ShouldRun()
	return (self.m_entity
		and self.m_entity:IsValid()
		and self.m_entity:IsAircraft()
		and Self:IsDriving()
		and GVars.features.vehicle.flares
	)
end

function Flares:OnEnable()
	self.m_thread:Resume()
end

function Flares:OnDisable()
	self.m_shots = {}
	self.m_next_shot_time = 0
	self.m_is_active = false
	self.m_thread:Suspend()
end

function Flares:Deploy()
	if (self.m_is_active) then
		return
	end

	local handle = Self:GetVehicle():GetHandle()
	local firstDelay = 200

	self.m_is_active = true
	self.m_shots = {}
	self.m_next_shot_time = MISC.GET_GAME_TIMER() + firstDelay

	for _, bone in pairs(Refs.planeBones) do
		local bone_idx = Game.GetEntityBoneIndexByName(handle, bone)
		if (bone_idx ~= -1) then
			for i = 1, 2 do
				table.insert(self.m_shots, {
					bone_idx = bone_idx,
					offset = (i == 2) and vec3:new(-10, -10, -10) or vec3:zero()
				})
			end
		end
	end
end

function Flares:Update()
	if (not self.m_is_active) then
		yield()
		return
	end

	local now = MISC.GET_GAME_TIMER()
	local handle = Self:GetVehicle():GetHandle()
	self.m_entity.m_is_shooting_flares = true

	while now >= self.m_next_shot_time and #self.m_shots > 0 do
		local shot = table.remove(self.m_shots, 1)
		local distance = math.random(10, 50)
		local bone_pos = Game.GetEntityBonePos(handle, self.m_shots.bone_idx)
		local vehPos = Game.GetEntityCoords(handle, false)
		local backwardOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(handle, 0.0, -1.0, 0.0)
		local rightOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(handle, 1.0, 0.0, 0.0)
		local upOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(handle, 0.0, 0.0, 1.0)
		local spreadStrengthRight = (math.random() - 0.5) * 2
		local spreadStrengthUp = (math.random() - 0.5) * 2

		local backward = vec3:new(
			backwardOffset.x - vehPos.x,
			backwardOffset.y - vehPos.y,
			backwardOffset.z - vehPos.z
		):normalize()

		local right = vec3:new(
			rightOffset.x - vehPos.x,
			rightOffset.y - vehPos.y,
			rightOffset.z - vehPos.z
		):normalize()

		local up = vec3:new(
			upOffset.x - vehPos.x,
			upOffset.y - vehPos.y,
			upOffset.z - vehPos.z
		):normalize()

		local direction = vec3:new(
			backward.x + (right.x * spreadStrengthRight) + (up.x * spreadStrengthUp),
			backward.y + (right.y * spreadStrengthRight) + (up.y * spreadStrengthUp),
			backward.z + (right.z * spreadStrengthRight) + (up.z * spreadStrengthUp)
		):normalize()

		local end_pos = vec3:new(
			bone_pos.x + shot.offset.x + direction.x * distance,
			bone_pos.y + shot.offset.y + direction.y * distance,
			bone_pos.z + shot.offset.z + direction.z * distance
		)

		Game.ShootBulletBetweenCoords(
			0x47757124,
			bone_pos + shot.offset,
			end_pos,
			1.0,
			Self:GetHandle(),
			100.0
		)

		AUDIO.PLAY_SOUND_FRONTEND(-1, "HIT_OUT", "PLAYER_SWITCH_CUSTOM_SOUNDSET", true)
		self.m_next_shot_time = self.m_next_shot_time + 200
	end

	if (#self.m_shots == 0) then
		self.m_is_active = false
		self.m_entity.m_is_shooting_flares = false
	end
end

function Flares:OnTick()
	if (not self:ShouldRun()) then
		yield()
		return
	end

	if (PAD.IS_CONTROL_JUST_PRESSED(0, 51)) then
		self:Deploy()
	end

	self:Update()
end

return Flares
