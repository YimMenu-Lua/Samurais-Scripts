-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local COL_VANTABLACK <const> = Color("#000100")


-----------------------------------------------------
-- Module: Escort Vehicle
-----------------------------------------------------
---@class EscortVehicle
---@field model hash
---@field handle handle
---@field name string
---@field blip BlipData
local EscortVehicle   = {}
EscortVehicle.__index = EscortVehicle

---@param modelHash integer
---@param groupName string
---@param godMode? boolean
function EscortVehicle.new(modelHash, groupName, godMode)
	local veh = Game.CreateVehicle(modelHash, vec3:zero())
	if not Game.IsScriptHandle(veh) then
		return
	end

	local wrapper    = Vehicle(veh)
	local vehName    = wrapper:GetName()
	local blip       = Game.AddBlipForEntity(veh, 1.14, true)
	local blipName   = groupName or _F("Escort Vehicle (%s)", vehName)
	local r, g, b, _ = COL_VANTABLACK:AsRGBA() -- Vantablack

	if (Game.IsOnline()) then
		entities.take_control_of(veh, 300)
	end

	Game.SetBlipSprite(blip, 229)
	Game.SetBlipName(blip, blipName)

	ENTITY.SET_ENTITY_INVINCIBLE(veh, godMode or false)
	VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
	VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(veh, r, g, b)
	VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(veh, r, g, b)
	VEHICLE.SET_VEHICLE_EXTRA_COLOURS(veh, 0, 0)
	VEHICLE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(veh, false, false)
	VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(veh, false)
	VEHICLE.SET_VEHICLE_STRONG(veh, true)
	VEHICLE.SET_VEHICLE_DIRT_LEVEL(veh, 0)
	VEHICLE.SET_VEHICLE_WINDOW_TINT(veh, 1)
	VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(veh, "MRDR INC")
	wrapper:MaxPerformance()

	return setmetatable({
		model  = modelHash,
		handle = veh,
		name   = vehName,
		blip   = {
			owner  = veh,
			handle = blip,
			alpha  = 255,
		}
	}, EscortVehicle)
end

---@return boolean
function EscortVehicle:Exists()
	return self.handle ~= 0 and Backend:IsScriptEntity(self.handle)
end

---@return boolean
function EscortVehicle:IsDriveable()
	return VEHICLE.IS_VEHICLE_DRIVEABLE(self.handle, true)
end

---@return boolean
function EscortVehicle:IsStuck()
	if not self:Exists() or not self:IsDriveable() then
		return false
	end

	return VEHICLE.IS_VEHICLE_STUCK_ON_ROOF(self.handle)
end

function EscortVehicle:IsPlayerInEscortVehicle()
	local playerVeh = LocalPlayer:GetVehicleNative()
	return (playerVeh ~= 0 and self.handle == playerVeh)
end

function EscortVehicle:GetPos()
	if self:Exists() then
		return Game.GetEntityCoords(self.handle, false)
	end

	return vec3:zero()
end

function EscortVehicle:GetDriver()
	return VEHICLE.GET_PED_IN_VEHICLE_SEAT(self.handle, -1, true)
end

---@param toggle boolean
function EscortVehicle:ToggleBlip(toggle)
	if not self.blip or not self.blip.handle then
		return
	end

	local targetAlpha = toggle and 255 or 0
	local cond = toggle and self.blip.alpha < targetAlpha or self.blip.alpha > targetAlpha

	if cond then
		self.blip.alpha = targetAlpha
		if HUD.DOES_BLIP_EXIST(self.blip.handle) then
			HUD.SET_BLIP_ALPHA(self.blip.handle, targetAlpha)
		end
	end
end

---@param lastCoords? vec3
---@param passengers Bodyguard[]
---@param lastHeading? integer
---@param groupName? string
function EscortVehicle:Recover(lastCoords, passengers, lastHeading, groupName)
	if self:Exists() then
		Game.DeleteEntity(self.handle)
		Decorator:RemoveEntity(self.handle)
	end

	if not lastCoords then
		lastCoords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
			LocalPlayer:GetHandle(),
			0,
			-10,
			1.0
		)
	end

	self.handle = Game.CreateVehicle(self.model, vec3:zero())
	Decorator:Register(self.handle, "BillionaireServices")
	ENTITY.FREEZE_ENTITY_POSITION(self.handle, true)

	local r, g, b, _ = COL_VANTABLACK:AsRGBA()
	local wrapper = Vehicle(self.handle)
	VEHICLE.SET_VEHICLE_MOD_KIT(self.handle, 0)
	VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(self.handle, r, g, b)
	VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(self.handle, r, g, b)
	VEHICLE.SET_VEHICLE_EXTRA_COLOURS(self.handle, 0, 0)
	VEHICLE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(self.handle, false, false)
	VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(self.handle, false)
	VEHICLE.SET_VEHICLE_STRONG(self.handle, true)
	VEHICLE.SET_VEHICLE_DIRT_LEVEL(self.handle, 0)
	VEHICLE.SET_VEHICLE_WINDOW_TINT(self.handle, 1)
	VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(self.handle, "MRDR INC")
	wrapper:MaxPerformance()

	for i = 1, #passengers do
		local guard = passengers[i]

		if (guard:GetHandle() ~= LocalPlayer:GetHandle()) and not PED.IS_PED_A_PLAYER(guard:GetHandle()) then
			PED.CLEAR_ALL_PED_VEHICLE_FORCED_SEAT_USAGE(guard:GetHandle())
			PED.SET_PED_VEHICLE_FORCED_SEAT_USAGE(
				guard:GetHandle(),
				self.handle,
				guard:IsEscortDriver() and -1 or guard.seatIndex,
				0,
				0
			)

			if not guard:IsInCombat() then
				TASK.TASK_WARP_PED_INTO_VEHICLE(
					guard:GetHandle(),
					self.handle,
					guard:IsEscortDriver() and -1 or guard.seatIndex
				)
			end
		end
	end

	local vehName  = wrapper:GetName()
	local blip     = Game.AddBlipForEntity(self.handle, 1.14, true)
	local blipName = groupName or _F("Escort Vehicle (%s)", vehName)

	Game.SetBlipSprite(blip, 229)
	Game.SetBlipName(blip, blipName)
	Game.SetEntityCoordsNoOffset(self.handle, lastCoords)

	ENTITY.SET_ENTITY_HEADING(self.handle, lastHeading or LocalPlayer:GetHeading())
	ENTITY.FREEZE_ENTITY_POSITION(self.handle, false)
	VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(self.handle, 5.0)
	VEHICLE.SET_VEHICLE_ENGINE_ON(self.handle, true, true, false)
end

return EscortVehicle
