---@diagnostic disable: param-type-mismatch

local PlayerVehicle = require("includes.modules.PlayerVehicle")
local FeatureMgr = require("includes.services.FeatureManager")
local autoHeal = require("includes.features.self.autoheal")

--------------------------------------
-- Class: Self
--------------------------------------
--
-- **Parent:** `Player`.
--
-- A global singleton that always resolves to the current local player.
---@class Self: Player
---@field private m_internal CPed
---@field private m_vehicle PlayerVehicle
---@field private m_last_vehicle? Vehicle
---@field private m_feat_mgr FeatureManager
---@field Resolve fun(self: Self) : CPed
---@overload fun(): Self
Self = Class("Self", Player)
Self.m_vehicle = PlayerVehicle:init(0)
Self.m_feat_mgr = FeatureMgr.new(Self)
Self.m_feat_mgr:Add(autoHeal.new(Self))

---@override
Self.new = nil

-- Returns the current local player's script handle.
---@override
---@return handle
function Self:GetHandle()
	return PLAYER.PLAYER_PED_ID()
end

-- Returns the current local player's ID.
---@return number
function Self:GetPlayerID()
	return PLAYER.PLAYER_ID()
end

-- Returns the current local player's model hash.
---@return hash
function Self:GetModelHash()
	return ENTITY.GET_ENTITY_MODEL(self:GetHandle())
end

---@override
---@return PlayerVehicle
function Self:GetVehicle()
	return self.m_vehicle
end

function Self:GetMaxArmour()
	return PLAYER.GET_PLAYER_MAX_ARMOUR(PLAYER.PLAYER_ID())
end

---@return Vehicle|nil
function Self:GetLastVehicle()
	return self.m_last_vehicle
end

function Self:OnVehicleSwitch()
	if (self.m_vehicle:IsValid()) then
		self.m_vehicle:ToggleSubwoofer(false)
		self.m_vehicle:RestoreHeadlights()

		if (self.m_vehicle:IsLocked()) then
			self.m_vehicle:LockDoors(false)
		end

		self.m_last_vehicle = Vehicle(self.m_vehicle:GetHandle())
	end

	self.m_vehicle:Reset()
	sleep(500)
	self.m_vehicle:Set(self:GetVehicleNative())
end

function Self:OnVehicleExit()
	if (not self.m_last_vehicle or self.m_last_vehicle:GetHandle() ~= self.m_vehicle:GetHandle()) then
		self.m_last_vehicle = Vehicle(self.m_vehicle:GetHandle())
	end

	if (not self.m_vehicle:IsValid()) then
		self.m_vehicle:Reset()
	end
end

-- Returns the entity local player is aiming at.
---@param skip_players? boolean -- Ignore network players.
---@return handle | nil
function Self:GetEntityInCrosshairs(skip_players)
	local is_aiming, entity, pid = false, 0, self:GetPlayerID()

	if not PLAYER.IS_PLAYER_FREE_AIMING(pid) then
		return 0
	end

	is_aiming, entity = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(pid, entity)
	if is_aiming and ENTITY.DOES_ENTITY_EXIST(entity) then
		if ENTITY.IS_ENTITY_A_PED(entity) then
			if PED.IS_PED_A_PLAYER(entity) and skip_players then
				return 0
			end

			if PED.IS_PED_IN_ANY_VEHICLE(entity, false) then -- aiming at an occupied vehicle returns the driver ped instead of the vehicle.
				return PED.GET_VEHICLE_PED_IS_IN(entity, false) -- force return the vehicle.
			end
		end
	end

	return is_aiming and entity or 0
end

-- This is a leftover from [Samurai's Scripts](https://github.com/YimMenu-Lua/Samurais-Scripts).
--
-- Returns whether local player is using an aircraft's machine gun.
--
-- If true, returns `true` and the `weapon hash` resolved and cast to unsigned 32bit integer, else returns `false` and `0`.
---@return boolean, hash
function Self:IsUsingAirctaftMG()
	local veh = self:GetVehicle()
	if (not veh) then
		return false, 0
	end

	if (not veh:IsWeaponized()) then
		return false, 0
	end

	if not (veh:IsPlane() or veh:IsHeli()) then
		return false, 0
	end

	local weapon = self:GetVehicleWeapon()
	if (weapon == 0) then
		return false, 0
	end

	weapon = Cast(weapon):AsUint32_t()
	for _, v in ipairs(t_AircraftMGs) do
		if weapon == joaat(v) then
			return true, weapon
		end
	end

	return false, 0
end

-- Teleports local player to the provided coordinates.
---@param where integer|vec3 -- [blip ID](https://wiki.rage.mp/wiki/Blips) or vector3 coordinates
---@param keep_vehicle? boolean
function Self:Teleport(where, keep_vehicle)
	ThreadManager:RunInFiber(function()
		local coords -- fwd decl

		if (not keep_vehicle and not Self:IsOnFoot()) then
			TASK.CLEAR_PED_TASKS_IMMEDIATELY(Self:GetHandle())
			sleep(50)
		end

		if (IsInstance(where, "number")) then
			local blip = HUD.GET_FIRST_BLIP_INFO_ID(where)

			if not HUD.DOES_BLIP_EXIST(blip) then
				Toast:ShowError(
					Backend.script_name,
					"Invalid teleport coordinates!"
				)
				return
			end

			coords = HUD.GET_BLIP_COORDS(blip)
		elseif (IsInstance(where, vec3)) then
			coords = where
		else
			Toast:ShowError(
				Backend.script_name,
				"Invalid teleport coordinates!"
			)
			return
		end

		Await(Game.LoadGroundAtCoord, coords, 500)
		PED.SET_PED_COORDS_KEEP_VEHICLE(self:GetHandle(), coords.x, coords.y, coords.z)
	end)
end

-- Returns whether the player is currently using any mobile or computer app.
---@return boolean
function Self:IsBrowsingApps()
	for _, v in ipairs(t_AppScriptNames) do
		if script.is_active(v) then
			return true
		end
	end

	return false
end

-- Returns whether the player is inside a modshop.
---@return boolean
function Self:IsInCarModShop()
	if (self:IsOnFoot() or self:IsOutside()) then
		return false
	end

	for _, v in ipairs(t_ModshopScriptNames) do
		if script.is_active(v) then
			return true
		end
	end

	return false
end

---@param pedHandle handle
---@return boolean
function Self:IsPedMyEnemy(pedHandle)
	local ped = Ped(pedHandle)

	if not ped:IsValid() then
		return false
	end

	return ped:IsEnemy()
end

function Self:IsUsingPhone()
	return script.is_active("CELLPHONE_FLASHHAND")
end

-- A helper method to quickly remove player attachments
---@param lookup_table? table
function Self:RemoveAttachments(lookup_table)
	ThreadManager:RunInFiber(function()
		local had_attachments = false

		local function _detach(entity)
			if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(entity, Self:GetHandle()) then
				had_attachments = true
				ENTITY.DETACH_ENTITY(entity, true, true)
				ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(entity)
			end
		end

		if lookup_table then
			for i = table.getlen(lookup_table), 1, -1 do
				_detach(lookup_table[i])
				table.remove(lookup_table, i)
				yield()
			end

			return
		end

		local mass_lookup = {
			entities.get_all_objects_as_handles(),
			entities.get_all_peds_as_handles(),
			entities.get_all_vehicles_as_handles()
		}

		for _, group in ipairs(mass_lookup) do
			for _, entity in ipairs(group) do
				_detach(entity)
				yield()
			end
		end

		if not had_attachments then
			Toast:ShowMessage(
				"Samurai's Scripts",
				_T("INF_ATTACHMENT_NONE")
			)
		else
			Toast:ShowSuccess(
				"Samurai's Scripts",
				_T("INF_ATTACHMENT_DROP")
			)
		end
	end)
end

function Self:Destroy()
	self.m_vehicle:Reset()
	self.m_last_vehicle = nil
	---@diagnostic disable-next-line
	self:super():Destroy()
end

Backend:RegisterEventCallback(eBackendEvent.PLAYER_SWITCH, function()
	Self:Destroy()
end)

Backend:RegisterEventCallback(eBackendEvent.SESSION_SWITCH, function()
	Self:Destroy()
end)


ThreadManager:CreateNewThread("SS_PV_HANDLER", function()
	if (Self.m_vehicle and Self.m_vehicle:IsValid()) then
		if (Self:IsOnFoot()) then
			Self:OnVehicleExit()
		elseif (Self.m_vehicle:GetHandle() ~= Self:GetVehicleNative()) then
			Self:OnVehicleSwitch()
		end
	elseif (not Self:IsOnFoot()) then
		Self.m_vehicle:Set(Self:GetVehicleNative())
	end

	if (Self.m_vehicle:GetHandle() ~= 0 and Self.m_vehicle:IsAnyThreadRunning() and not Self.m_vehicle:IsValid()) then
		Self.m_vehicle:Reset()
		sleep(1000)
	end
end)

ThreadManager:CreateNewThread("SS_SELF", function()
	Self.m_feat_mgr:Update()
end)
