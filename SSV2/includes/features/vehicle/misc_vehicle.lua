-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")
local World = require("includes.modules.World")

---@class MiscVehicle : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_is_active boolean
local MiscVehicle = setmetatable({}, FeatureBase)
MiscVehicle.__index = MiscVehicle

---@param pv PlayerVehicle
---@return MiscVehicle
function MiscVehicle.new(pv)
	local self = FeatureBase.new(pv)
	---@diagnostic disable-next-line
	return setmetatable(self, MiscVehicle)
end

function MiscVehicle:Init()
	self.m_is_active = false
	self.m_entity:AddMemoryPatch({
		name = self.m_entity.MemoryPatches.Turbulence,
		onEnable = function(patch)
			if (not self.m_entity:IsPlane()) then
				error("Invalid vehicle type!")
				return
			end

			---@type CFlyingHandlingData
			local handingdata = self.m_entity:GetHandlingData()
			if (not handingdata) then
				error("Handling data is null!")
			end

			local fturbulence = handingdata.m_turbulence_force_mult
			if (fturbulence:is_null()) then
				error("Pointer is null!")
			end

			patch.m_state = {
				ptr = fturbulence,
				default_value = fturbulence:get_float()
			}

			fturbulence:set_float(0.0)
		end,
		onDisable = function(patch)
			if (not patch.m_state or patch.m_state.default_value == nil) then
				return
			end

			local ptr = patch.m_state.ptr
			if (not ptr or ptr:is_null()) then
				error("Pointer is null")
			end

			ptr:set_float(patch.m_state.default_value)
		end
	})

	self.m_entity:AddMemoryPatch({
		name = self.m_entity.MemoryPatches.WindMult,
		onEnable = function(patch)
			if (not self.m_entity:IsPlane()) then
				error("Invalid vehicle type!")
				return
			end

			---@type CFlyingHandlingData
			local handingdata = self.m_entity:GetHandlingData()
			if (not handingdata) then
				error("Handling data is null!")
			end

			local fwindForce = handingdata.m_wind_force_mult
			if (fwindForce:is_null()) then
				error("Pointer is null!")
			end

			patch.m_state = {
				ptr = fwindForce,
				default_value = fwindForce:get_float()
			}

			fwindForce:set_float(0.0)
		end,
		onDisable = function(patch)
			if (not patch.m_state or patch.m_state.default_value == nil) then
				return
			end

			local ptr = patch.m_state.ptr
			if (not ptr or ptr:is_null()) then
				error("Pointer is null")
			end

			ptr:set_float(patch.m_state.default_value)
		end
	})
end

function MiscVehicle:ShouldRun()
	return (self.m_entity
		and self.m_entity:IsValid()
		and self.m_entity:IsAircraft()
		and LocalPlayer:IsDriving()
	)
end

---@param enemiesOnly boolean
---@param targetEntity handle
---@param startPos vec3
---@param endPos vec3
---@param damage? float
function MiscVehicle:ShootExplosiveMG(enemiesOnly, targetEntity, startPos, endPos, damage)
	damage = damage or 1000.0
	self.m_entity:ShootAtTarget(targetEntity, enemiesOnly)
	Game.ShootBulletBetweenCoords(3800181289, startPos, endPos, damage, LocalPlayer:GetHandle(), 300)
end

function MiscVehicle:UpdateMachineGuns()
	if (not GVars.features.vehicle.aircraft_mg.triggerbot
			and not GVars.features.vehicle.aircraft_mg.manual_aim) then
		return
	end

	if (not LocalPlayer:IsUsingAirctaftMG()) then
		return
	end

	local PV                        = self.m_entity
	local handle                    = PV:GetHandle()
	local manualAim                 = GVars.features.vehicle.aircraft_mg.manual_aim
	local triggerbotRange           = GVars.features.vehicle.aircraft_mg.tiggerbot_range
	local playerPos                 = LocalPlayer:GetPos()
	local rotation                  = manualAim and CAM.GET_GAMEPLAY_CAM_ROT(2) or PV:GetRotation(2)
	local direction                 = rotation:to_direction()
	local multiplier                = manualAim and 200 or triggerbotRange
	local destination               = playerPos + direction * multiplier
	local hit, endCoords, entityHit = World:RayCast(playerPos, destination, -1, handle)

	if (hit and GVars.features.vehicle.aircraft_mg.triggerbot and (ENTITY.IS_ENTITY_A_PED(entityHit) or ENTITY.IS_ENTITY_A_VEHICLE(entityHit))) then
		local enemiesOnly = GVars.features.vehicle.aircraft_mg.enemies_only
		local ped         = Game.GetClosestPed(endCoords, 50, true)
		local veh         = Game.GetClosestVehicle(endCoords, 50, handle)

		if (ped ~= 0) then
			self:ShootExplosiveMG(enemiesOnly, ped, playerPos, Game.GetEntityCoords(ped, true))
		end

		if (veh ~= 0) then
			self:ShootExplosiveMG(enemiesOnly, veh, playerPos, Game.GetEntityCoords(veh, true))
		end
	end

	if (manualAim) then
		local endPos = hit and endCoords or playerPos + direction * 1000

		if (PAD.IS_CONTROL_PRESSED(0, 70)) then
			self:ShootExplosiveMG(false, 0, playerPos, endPos)
		end

		local color = GVars.features.vehicle.aircraft_mg.marker_color
		local markerSize = GVars.features.vehicle.aircraft_mg.marker_size
		local markerDest = hit and endCoords or vec3:new(
			playerPos.x + direction.x * 50,
			playerPos.y + direction.y * 50,
			(playerPos.z + direction.z * 50) + 1
		)

		GRAPHICS.DRAW_MARKER_EX(
			3,
			markerDest.x,
			markerDest.y,
			markerDest.z,
			0,
			0,
			0,
			0,
			0,
			0,
			markerSize,
			markerSize,
			markerSize,
			math.min(color.x * 255, 255),
			math.min(color.y * 255, 255),
			math.min(color.z * 255, 255),
			math.min(color.w * 255, 255),
			---@diagnostic disable-next-line: param-type-mismatch
			false, true, 1, false, nil, nil, true, true, false
		)

		-- if (PV:IsHeli()) then -- I don't like this
		-- 	local camHeading = CAM.GET_GAMEPLAY_CAM_RELATIVE_HEADING()
		-- 	if (camHeading > 15 or camHeading < -15) then
		-- 		if (ENTITY.GET_ENTITY_ALPHA(handle) > 150) then
		-- 			ENTITY.SET_ENTITY_ALPHA(handle, 150, false)
		-- 		end
		-- 	else
		-- 		if ENTITY.GET_ENTITY_ALPHA(handle) < 255 then
		-- 			ENTITY.RESET_ENTITY_ALPHA(handle)
		-- 		end
		-- 	end
		-- end
	end
end

function MiscVehicle:DisableAirTurbulence()
	local PV = self.m_entity
	if (not PV:IsPlane()) then
		return
	end

	PV:ApplyPatch(PV.MemoryPatches.DeformMult)
	PV:ApplyPatch(PV.MemoryPatches.WindMult)
end

function MiscVehicle:Update()
	local PV = self.m_entity
	local handle = PV:GetHandle()

	if (GVars.features.vehicle.fast_jets and PV:IsPlane() and (VEHICLE.GET_VEHICLE_FLIGHT_NOZZLE_POSITION(handle) ~= 1.0)) then
		local speed      = PV:GetSpeed()
		local gearState  = PV:GetLandingGearState()
		local rot        = PV:GetRotation(2)
		local pitch      = rot.x
		local baseThrust = 2e4
		local minThrust  = 5e3
		local maxSpeed   = 164.0
		local thrustMult = 1.0

		if (pitch >= 60) then
			thrustMult = 2.0
		elseif (pitch >= 30) then
			thrustMult = 1.4
		end

		if speed >= 72 and speed < maxSpeed
			and PAD.IS_CONTROL_PRESSED(0, 87)
			and gearState == Enums.eLandingGearState.RETRACTED
		then
			local lerp   = math.min(1.0, (speed) / (maxSpeed))
			local thrust = math.min(minThrust, baseThrust * thrustMult * (1.0 - lerp))
			ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(
				handle,
				1,
				0.0,
				thrust,
				0.0,
				false,
				true,
				false,
				false
			)
		end
	end

	if (GVars.features.vehicle.no_jet_stall) then
		if (PV:IsDriveable() and PV:GetEngineHealth() > 350 and PV:GetHeightAboveGround() > 5.0 and not PV:IsEngineOn()) then
			VEHICLE.SET_VEHICLE_ENGINE_ON(handle, true, true, false)
		end
	end

	if (GVars.features.vehicle.no_turbulence) then
		self:DisableAirTurbulence()
	end

	self:UpdateMachineGuns()
end

return MiscVehicle
