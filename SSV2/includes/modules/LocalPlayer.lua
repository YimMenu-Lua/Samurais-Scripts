-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Refs         = require("includes.data.refs")
local FeatureMgr   = require("includes.services.FeatureManager")
local Autoheal     = require("includes.features.self.autoheal")
local Ragdoll      = require("includes.features.self.ragdoll")
local MagicBullet  = require("includes.features.self.magic_bullet")
local LaserSights  = require("includes.features.self.laser_sights")
local Katana       = require("includes.features.self.katana")
local miscFeatures = require("includes.features.self.miscellaneous")
local CPed         = require("includes.classes.gta.CPed")
local YimActions   = require("includes.features.YimActionsV3")


--------------------------------------
-- Class: LocalPlayer
--------------------------------------
--
-- **Parent:** `Player`.
--
-- A global singleton that always resolves to the current local player.
---@class LocalPlayer: Player
---@field private m_vehicle PlayerVehicle
---@field private m_last_vehicle? Vehicle
---@field private m_feat_mgr FeatureManager
---@field public CurrentMovementClipset? string
---@field public CurrentStrafeClipset? string
---@field public CurrentWeaponMovementClipset? string
LocalPlayer = Class("LocalPlayer", Player)


---@override
LocalPlayer.new        = nil
LocalPlayer.m_vehicle  = require("includes.modules.PlayerVehicle")
LocalPlayer.m_feat_mgr = FeatureMgr.new(LocalPlayer)

---@diagnostic disable
LocalPlayer.m_feat_mgr:Add(Autoheal.new(LocalPlayer))
LocalPlayer.m_feat_mgr:Add(Ragdoll.new(LocalPlayer))
LocalPlayer.m_feat_mgr:Add(MagicBullet.new(LocalPlayer))
LocalPlayer.m_feat_mgr:Add(LaserSights.new(LocalPlayer))
LocalPlayer.m_feat_mgr:Add(Katana.new(LocalPlayer))
LocalPlayer.m_feat_mgr:Add(miscFeatures.new(LocalPlayer))
---@diagnostic enable

---@return CPed
function LocalPlayer:Resolve()
	return CPed(self:GetHandle())
end

-- Returns the current local player's script handle.
---@override
---@return handle
function LocalPlayer:GetHandle()
	return PLAYER.PLAYER_PED_ID()
end

-- Returns the current local player's ID.
---@return number
function LocalPlayer:GetPlayerID()
	return PLAYER.PLAYER_ID()
end

-- Returns the current local player's model hash.
---@return hash
function LocalPlayer:GetModelHash()
	return ENTITY.GET_ENTITY_MODEL(self:GetHandle())
end

-- Returns the vehicle you're driving, not just sitting in.
---@override
---@return PlayerVehicle
function LocalPlayer:GetVehicle()
	return self.m_vehicle
end

-- Returns the vehicle you're currently sitting in whether you're driving or not.
---@return Vehicle
function LocalPlayer:GetVehiclePlayerIsIn()
	return Vehicle(self:GetVehicleNative())
end

function LocalPlayer:GetMaxArmour()
	return PLAYER.GET_PLAYER_MAX_ARMOUR(PLAYER.PLAYER_ID())
end

---@return Vehicle|nil
function LocalPlayer:GetLastVehicle()
	return self.m_last_vehicle
end

---@return integer
function LocalPlayer:GetWalletBalance()
	return MONEY.NETWORK_GET_VC_WALLET_BALANCE(stats.get_character_index())
end

---@return integer
function LocalPlayer:GetBankBalance()
	return MONEY.NETWORK_GET_VC_BANK_BALANCE()
end

---@return integer
function LocalPlayer:GetTotalBalance()
	return self:GetWalletBalance() + self:GetBankBalance()
end

function LocalPlayer:GetName()
	return Game.GetCharacterName()
end

function LocalPlayer:OnVehicleSwitch()
	if (self.m_vehicle:IsValid()) then
		self.m_vehicle:RestoreHeadlights()

		self.m_last_vehicle = Vehicle(self.m_vehicle:GetHandle())
	end

	self.m_vehicle:Reset()
	sleep(500)
	self.m_vehicle:Set(self:GetVehicleNative())
end

function LocalPlayer:OnVehicleExit()
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
function LocalPlayer:GetEntityInCrosshairs(skip_players)
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

-- Returns whether local player is using any vehicle's machine gun.
--
-- If true, returns `true` and the `weapon hash`; else returns `false` and `0`.
---@return boolean, hash
function LocalPlayer:IsUsingVehicleMG()
	local veh = self:GetVehiclePlayerIsIn()
	if (not veh or not veh:IsValid()) then
		return false, 0
	end

	if (not veh:IsWeaponized()) then
		return false, 0
	end

	local cpedweaponmgr = self:Resolve().m_ped_weapon_mgr
	if (not cpedweaponmgr or not cpedweaponmgr:IsValid()) then
		return false, 0
	end

	local cvehicleweaponinfo = cpedweaponmgr.m_vehicle_weapon_info
	if (not cvehicleweaponinfo or not cvehicleweaponinfo:IsValid()) then
		return false, 0
	end

	local effectGroup = cvehicleweaponinfo.m_effect_group:get_int()
	local weaponHash  = cvehicleweaponinfo.m_name_hash:get_dword()

	-- we specifically want to return zero for the weapon hash if false
	if (effectGroup ~= Enums.eWeaponEffectGroup.VehicleMG or weaponHash == 0) then
		return false, 0
	end

	return true, weaponHash
end

-- Returns whether local player is using an aircraft's machine gun.
--
-- If true, returns `true` and the `weapon hash`; else returns `false` and `0`.
---@return boolean, hash
function LocalPlayer:IsUsingAirctaftMG()
	local veh = self:GetVehiclePlayerIsIn()
	if (not veh or not veh:IsPlane() or not veh:IsHeli()) then
		return false, 0
	end

	return self:IsUsingVehicleMG()
end

function LocalPlayer:IsBeingArrested()
	return PLAYER.IS_PLAYER_BEING_ARRESTED(self:GetPlayerID(), true)
end

-- Teleports local player to the provided coordinates.
---@param where (integer|vec3)? -- [blip ID](https://wiki.rage.mp/wiki/Blips) or vector3 coordinates
---@param keep_vehicle? boolean
---@param loadGround? boolean
function LocalPlayer:Teleport(where, keep_vehicle, loadGround)
	ThreadManager:Run(function()
		if (not self:IsOutside()) then
			Notifier:ShowError(_T("GENERIC_TELEPORT"), _T("GENERIC_TP_INTERIOR_ERR"))
			return
		end

		local coords = Game.Ensure3DCoords(where)
		if (not coords or coords:is_zero()) then
			Notifier:ShowError(_T("GENERIC_TELEPORT"), _T("GENERIC_TP_INVALID_COORDS_ERR"))
			return
		end

		if (not keep_vehicle and not LocalPlayer:IsOnFoot()) then
			TASK.CLEAR_PED_TASKS_IMMEDIATELY(LocalPlayer:GetHandle())
			sleep(50)
		end

		if (loadGround) then
			TaskWait(Game.LoadGroundAtCoord, { coords }, 500)
		end

		local dir     = LocalPlayer:GetPos() - coords
		local heading = MISC.GET_HEADING_FROM_VECTOR_2D(dir.x, dir.y)
		LocalPlayer:SetHeading(heading)
		LocalPlayer:SetCoordsKeepVehicle(coords)
	end)
end

---@param scriptName string
---@return boolean
function LocalPlayer:IsHostOfScript(scriptName)
	local pid = self:GetPlayerID()
	return (NETWORK.NETWORK_GET_HOST_OF_SCRIPT(scriptName, -1, 0) == pid)
		or (NETWORK.NETWORK_GET_HOST_OF_SCRIPT(scriptName, 0, 0) == pid)
		or (NETWORK.NETWORK_GET_HOST_OF_SCRIPT(scriptName, 1, 0) == pid)
		or (NETWORK.NETWORK_GET_HOST_OF_SCRIPT(scriptName, 2, 0) == pid)
		or (NETWORK.NETWORK_GET_HOST_OF_SCRIPT(scriptName, 3, 0) == pid)
end

-- Returns whether the player is currently using any mobile or computer app.
---@return boolean
function LocalPlayer:IsBrowsingApps()
	for _, v in ipairs(Refs.appScriptNames) do
		if script.is_active(v) then
			return true
		end
	end

	return false
end

-- Returns whether the player is inside a modshop.
---@return boolean
function LocalPlayer:IsInCarModShop()
	if (self:IsOnFoot() or self:IsOutside()) then
		return false
	end

	for _, v in ipairs(Refs.modshopScriptNames) do
		if script.is_active(v) then
			return true
		end
	end

	return false
end

function LocalPlayer:IsUsingPhone()
	return script.is_active("CELLPHONE_FLASHHAND")
end

function LocalPlayer:IsPlayingHandsUpAnim()
	return ENTITY.IS_ENTITY_PLAYING_ANIM(
		self:GetHandle(),
		"mp_missheist_countrybank@lift_hands",
		"lift_hands_in_air_outro",
		3
	)
end

function LocalPlayer:CanUsePhoneAnims()
	return
		not ENTITY.IS_ENTITY_DEAD(self:GetHandle(), false)
		and not YimActions:IsPedPlaying()
		and (PED.COUNT_PEDS_IN_COMBAT_WITH_TARGET(self:GetHandle()) == 0)
end

function LocalPlayer:CanCrouch()
	return
		self:IsOnFoot()
		and not gui.is_open()
		and not GUI:IsOpen()
		and not HUD.IS_PAUSE_MENU_ACTIVE()
		and not YimActions:IsPedPlaying()
		and not YimActions:IsPlayerBusy()
		and not Backend:AreControlsDisabled()
end

function LocalPlayer:CanPutHandsUp()
	return
		(self:IsOnFoot() or self:GetVehicle():IsCar())
		and not gui.is_open()
		and not GUI:IsOpen()
		and not YimActions:IsPedPlaying()
		and not YimActions:IsPlayerBusy()
		and not Backend:AreControlsDisabled()
		and not HUD.IS_PAUSE_MENU_ACTIVE()
		and not HUD.IS_MP_TEXT_CHAT_TYPING()
end

-- Enables or disables physical phone interactions in GTA Online.
--
-- Internally, these flags **DISABLE** animations when set to true,
--
-- so we invert the value to preserve sane semantics at the API level.
---@param value boolean
function LocalPlayer:ToggleMpPhoneAnims(value)
	-- ePedConfigFlags (see includes/data/enums.lua)
	-- 242 = PhoneDisableTextingAnimations
	-- 243 = PhoneDisableTalkingAnimations
	-- 244 = PhoneDisableCameraAnimations
	for i = 242, 244 do
		if (self:GetConfigFlag(i, value) == value) then
			self:SetConfigFlag(i, not value)
		end
	end
end

function LocalPlayer:PlayKeyfobAnim()
	if (self:IsDead()
			or self:IsSwimming()
			or not self:IsOnFoot()
			or YimActions:IsPedPlaying()
			or YimActions:IsPlayerBusy()
		) then
		return
	end

	TaskWait(Game.RequestAnimDict, "anim@mp_player_intmenu@key_fob@")
	TASK.TASK_PLAY_ANIM(
		self:GetHandle(),
		"anim@mp_player_intmenu@key_fob@",
		"fob_click",
		4.0,
		-8.0,
		800.0,
		48,
		0.0,
		false,
		false,
		false
	)
end

-- A helper method to quickly remove player attachments
---@param lookup_table? table
function LocalPlayer:RemoveAttachments(lookup_table)
	ThreadManager:Run(function()
		local had_attachments = false

		local function _detach(entity)
			if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(entity, self:GetHandle()) then
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
			Notifier:ShowMessage(
				"Samurai's Scripts",
				_T("INF_ATTACHMENT_NONE")
			)
		else
			Notifier:ShowSuccess(
				"Samurai's Scripts",
				_T("INF_ATTACHMENT_DROP")
			)
		end
	end)
end

---@param data table
---@param isJson boolean
function LocalPlayer:SetMovementClipset(data, isJson)
	local mvmtclipset = isJson and data.Name or data.mvmt

	script.run_in_fiber(function(s)
		self:ResetMovementClipsets()
		s:sleep(100)

		local handle = self:GetHandle()
		if mvmtclipset then
			TaskWait(Game.RequestClipSet, mvmtclipset)
			PED.SET_PED_MOVEMENT_CLIPSET(handle, mvmtclipset, 1.0)
			PED.SET_PED_ALTERNATE_MOVEMENT_ANIM(handle, 0, "move_clown@generic", "idle", 1090519040, true)
			TASK.SET_PED_CAN_PLAY_AMBIENT_IDLES(handle, true, true)
			self.CurrentMovementClipset = mvmtclipset
		end

		if data.wmvmt then
			PED.SET_PED_WEAPON_MOVEMENT_CLIPSET(handle, data.wmvmt)
			self.CurrentWeaponMovementClipset = data.wmvmt
		end

		if data.strf then
			while not STREAMING.HAS_CLIP_SET_LOADED(data.strf) do
				STREAMING.REQUEST_CLIP_SET(data.strf)
				coroutine.yield()
			end
			PED.SET_PED_STRAFE_CLIPSET(handle, data.strf)
			self.CurrentStrafeClipset = data.strf
		end

		if data.wanim then
			WEAPON.SET_WEAPON_ANIMATION_OVERRIDE(handle, _J(data.wanim))
		end
	end)
end

function LocalPlayer:ResetMovementClipsets()
	local handle = self:GetHandle()

	PED.RESET_PED_MOVEMENT_CLIPSET(handle, 0.3)
	PED.RESET_PED_STRAFE_CLIPSET(handle)
	PED.RESET_PED_WEAPON_MOVEMENT_CLIPSET(handle)
	PED.CLEAR_PED_ALTERNATE_MOVEMENT_ANIM(handle, 0, -8.0)
	WEAPON.SET_WEAPON_ANIMATION_OVERRIDE(handle, 3839837909) -- default

	self.CurrentMovementClipset       = nil
	self.CurrentStrafeClipset         = nil
	self.CurrentWeaponMovementClipset = nil
end

function LocalPlayer:Cleanup()
	self:ResetMovementClipsets()
	self.m_feat_mgr:Cleanup()
end

function LocalPlayer:Reset()
	self:Cleanup()
	self.m_vehicle:Reset()
	self.m_last_vehicle = nil
	self:Destroy()
end

Backend:RegisterEventCallbackAll(function()
	LocalPlayer:Reset()
end)

ThreadManager:RegisterLooped("SS_PV_HANDLER", function()
	if (LocalPlayer.m_vehicle and LocalPlayer.m_vehicle:IsValid()) then
		if (LocalPlayer:IsOnFoot()) then
			LocalPlayer:OnVehicleExit()
		elseif (LocalPlayer:IsDriving() and LocalPlayer.m_vehicle:GetHandle() ~= LocalPlayer:GetVehicleNative()) then
			LocalPlayer:OnVehicleSwitch()
		end
	elseif (LocalPlayer:IsDriving()) then
		LocalPlayer.m_vehicle:Set(LocalPlayer:GetVehicleNative())
	end

	if (LocalPlayer.m_vehicle:GetHandle() ~= 0 and not LocalPlayer.m_vehicle:IsValid()) then
		LocalPlayer.m_vehicle:Reset()
		sleep(1000)
	end
end)

ThreadManager:RegisterLooped("SS_SELF", function()
	LocalPlayer.m_feat_mgr:Update()
end)
