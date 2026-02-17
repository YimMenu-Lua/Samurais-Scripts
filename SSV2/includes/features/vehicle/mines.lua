-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")

---@class VehMines : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_is_active boolean
---@field private m_last_deployed seconds
local VehMines = setmetatable({}, FeatureBase)
VehMines.__index = VehMines

---@param pv PlayerVehicle
---@return VehMines
function VehMines.new(pv)
	local self = FeatureBase.new(pv)
	---@diagnostic disable-next-line
	return setmetatable(self, VehMines)
end

function VehMines:Init()
	self.m_is_active = false
	self.m_last_deployed = 0
end

function VehMines:ShouldRun()
	return (self.m_entity
		and self.m_entity:IsValid()
		and self.m_entity:IsLandVehicle()
		and LocalPlayer:IsDriving()
		and GVars.features.vehicle.mines.enabled
	)
end

function VehMines:Update()
	if (Time.Now() < self.m_last_deployed) then
		return
	end

	if (KeyManager:IsKeybindJustPressed("veh_mine")) then
		local bone_idx = self.m_entity:GetBoneIndexByName("chassis_dummy")
		if (bone_idx == -1) then
			return
		end

		local groundZ    = 0
		local bone_pos   = self.m_entity:GetBonePosition(bone_idx)
		local veh_pos    = self.m_entity:GetPos(true)
		local veh_fwd    = self.m_entity:GetForwardVector()
		local vmin, vmax = self.m_entity:GetModelDimensions()
		local veh_len    = vmax.y - vmin.y
		local x_offset   = veh_fwd.x * (veh_len / 1.6)
		local y_offset   = veh_fwd.y * (veh_len / 1.6)
		local mine_hash  = GVars.features.vehicle.mines.selected_type_hash

		TaskWait(Game.RequestWeaponAsset, mine_hash)
		_, groundZ = MISC.GET_GROUND_Z_FOR_3D_COORD(
			veh_pos.x,
			veh_pos.y,
			veh_pos.z,
			groundZ,
			false,
			false
		)
		MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
			bone_pos.x - x_offset,
			bone_pos.y - y_offset,
			bone_pos.z,
			bone_pos.x - x_offset,
			bone_pos.y - y_offset,
			groundZ,
			0.0,
			false,
			mine_hash,
			LocalPlayer:GetHandle(),
			true,
			false,
			0.01
		)

		self.m_last_deployed = Time.Now() + 5
	end
end

return VehMines
