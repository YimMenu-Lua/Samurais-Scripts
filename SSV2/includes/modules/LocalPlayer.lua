-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Refs         = require("includes.data.refs")
local Autoheal     = require("includes.features.self.autoheal")
local Ragdoll      = require("includes.features.self.ragdoll")
local MagicBullet  = require("includes.features.self.magic_bullet")
local LaserSights  = require("includes.features.self.laser_sights")
local Katana       = require("includes.features.self.katana")
local miscFeatures = require("includes.features.self.miscellaneous")
local CPed         = require("includes.classes.gta.CPed")
local YimActions   = require("includes.features.extra.yim_actions.YimActionsV3")
local YRV3         = require("includes.features.online.yim_resupplier.YimResupplierV3")
local SGSL         = require("includes.services.SGSL")


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
---@field private m_money_controller PlayerMoneyController
---@field private m_clipsets { movement?: string, strafe?: string, weapon?: string }
---@field protected m_internal CPed
---@field SetAsNoLongerNeeded nil
LocalPlayer = Class("LocalPlayer", { parent = Player })


LocalPlayer.new                 = nil
LocalPlayer.Create              = nil
LocalPlayer.Delete              = nil
LocalPlayer.SetAsNoLongerNeeded = nil

LocalPlayer.m_clipsets          = {}
LocalPlayer.m_vehicle           = require("includes.modules.PlayerVehicle")
LocalPlayer.m_money_controller  = require("includes.services.PlayerMoneyController").new()
LocalPlayer.m_feat_mgr          = require("includes.services.FeatureManager").new(LocalPlayer)

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
	if (not self.m_internal) then
		self.m_internal = CPed(self:GetHandle())
	end

	return self.m_internal
end

-- Returns the current local player's script handle.
---@override
---@return handle
function LocalPlayer:GetHandle()
	return _G.self.get_ped()
end

-- Returns the current local player's ID.
---@return number
function LocalPlayer:GetID()
	return _G.self.get_id()
end

-- Returns the current local player's model hash.
---@return hash
function LocalPlayer:GetModelHash()
	return ENTITY.GET_ENTITY_MODEL(self:GetHandle())
end

---@return vec3
function LocalPlayer:GetPos(_)
	return _G.self.get_pos()
end

-- Returns the vehicle you're driving, not just sitting in.
---@override
---@return PlayerVehicle
function LocalPlayer:GetVehicle()
	return self.m_vehicle
end

---@return handle
function LocalPlayer:GetVehicleNative()
	return _G.self.get_veh()
end

-- Returns the vehicle you're currently sitting in whether you're driving or not.
---@return Vehicle?
function LocalPlayer:GetVehiclePlayerIsIn()
	local handle = self:GetVehicleNative()
	if (handle == 0) then return end
	return Vehicle(handle)
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
	if (not Game.IsOnline()) then
		return 0
	end

	return self.m_money_controller:GetWalletBalance()
end

---@return string
function LocalPlayer:GetWalletBalanceFmt()
	if (not Game.IsOnline()) then return "$0" end
	return self.m_money_controller:GetWalletBalanceFmt()
end

---@return integer
function LocalPlayer:GetBankBalance()
	if (not Game.IsOnline()) then
		return 0
	end

	return self.m_money_controller:GetBankBalance()
end

---@return string
function LocalPlayer:GetBankBalanceFmt()
	if (not Game.IsOnline()) then return "$0" end
	return self.m_money_controller:GetBankBalanceFmt()
end

---@return integer
function LocalPlayer:GetTotalBalance()
	if (not Game.IsOnline()) then
		return stats.get_int(stats.prefix("SPX_TOTAL_CASH"))
	end

	return self.m_money_controller:GetTotalBalance()
end

---@return string
function LocalPlayer:GetTotalBalanceFmt()
	if (not Game.IsOnline()) then
		return string.formatmoney(stats.get_int(stats.prefix("SPX_TOTAL_CASH")))
	end

	return self.m_money_controller:GetTotalBalanceFmt()
end

---@return PlayerMoneyController
function LocalPlayer:GetMoneyController()
	return self.m_money_controller
end

function LocalPlayer:GetCharacterName()
	return Game.GetCharacterName()
end

function LocalPlayer:OnVehicleSwitch()
	local veh = self.m_vehicle
	if (veh:IsValid()) then
		veh:RestoreHeadlights()
		self.m_last_vehicle = Vehicle(veh:GetHandle())
	end

	veh:Reset()
	sleep(500)
	local nativeVeh = self:GetVehicleNative()
	if (ENTITY.DOES_ENTITY_EXIST(nativeVeh)) then
		veh:Set(nativeVeh)
	end
end

function LocalPlayer:OnVehicleExit()
	local veh = self.m_vehicle
	if (not veh:IsValid()) then
		veh:Cleanup()
		return
	end

	local prevHandle = veh:GetHandle()
	local lastVeh    = self.m_last_vehicle
	if (prevHandle ~= 0 and (not lastVeh or lastVeh:GetHandle() ~= prevHandle)) then
		self.m_last_vehicle = Vehicle(prevHandle)
	end
end

-- Returns the entity local player is aiming at.
---@param skip_players? boolean -- Ignore network players.
---@return handle | nil
function LocalPlayer:GetEntityInCrosshairs(skip_players)
	local is_aiming, entity, pid = false, 0, self:GetID()

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
	if (not veh or not veh:IsValid() or not veh:IsWeaponized()) then
		return false, 0
	end

	local cpedweaponmgr = self:Resolve():GetWeaponManager()
	if (not cpedweaponmgr or not cpedweaponmgr:IsValid()) then
		return false, 0
	end

	local cvehicleweaponinfo = cpedweaponmgr:GetVehicleWeaponInfo()
	if (not cvehicleweaponinfo or not cvehicleweaponinfo:IsValid()) then
		return false, 0
	end

	local weaponHash  = cvehicleweaponinfo.m_name_hash:get_dword()
	local effectGroup = cvehicleweaponinfo.m_effect_group:get_int()

	-- we specifically want to return zero for the weapon hash if false
	if (weaponHash == 0 or effectGroup ~= Enums.eWeaponEffectGroup.VehicleMG) then
		return false, 0
	end

	return true, weaponHash
end

-- Returns whether local player is using an aircraft's machine gun.
--
-- If true, returns `true` and the `weapon hash`; else returns `false` and `0`.
---@return boolean, hash
function LocalPlayer:IsUsingAircraftMG()
	local veh = self:GetVehiclePlayerIsIn()
	if (not veh or not veh:IsAircraft()) then
		return false, 0
	end

	return self:IsUsingVehicleMG()
end

---@return boolean
function LocalPlayer:IsBeingArrested()
	return PLAYER.IS_PLAYER_BEING_ARRESTED(self:GetID(), true)
end

-- Teleports local player to the provided coordinates.
---@param where (integer|vec3)? -- [blip ID](https://wiki.rage.mp/wiki/Blips) or vector3 coordinates
---@param keepVehicle? boolean
---@param loadGround? boolean
function LocalPlayer:Teleport(where, keepVehicle, loadGround)
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

		if (not keepVehicle and not LocalPlayer:IsOnFoot()) then
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

---@param data MovementClipsetData
---@param isJson boolean
function LocalPlayer:SetMovementClipset(data, isJson)
	ThreadManager:Run(function(s)
		self:ResetMovementClipsets()
		s:sleep(100)

		local clipsets    = self.m_clipsets
		local handle      = self:GetHandle()
		local clipsetName = isJson and data.Name or data.mvmt
		if (clipsetName) then
			local loaded = pcall(TaskWait, Game.RequestClipSet, clipsetName)
			if (loaded) then
				PED.SET_PED_MOVEMENT_CLIPSET(handle, clipsetName, 1.0)
				PED.SET_PED_ALTERNATE_MOVEMENT_ANIM(handle, 0, "move_clown@generic", "idle", 1090519040, true)
				TASK.SET_PED_CAN_PLAY_AMBIENT_IDLES(handle, true, true)
				clipsets.movement = clipsetName
			end
		end

		if (data.wmvmt) then
			PED.SET_PED_WEAPON_MOVEMENT_CLIPSET(handle, data.wmvmt)
			clipsets.weapon = data.wmvmt
		end

		if (data.strf) then
			local loaded = pcall(TaskWait, Game.RequestClipSet, data.strf)
			if (loaded) then
				PED.SET_PED_STRAFE_CLIPSET(handle, data.strf)
				clipsets.strafe = data.strf
			end
		end

		if (data.wanim) then
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
	self.m_clipsets = {}
end

function LocalPlayer:Cleanup()
	self:ResetMovementClipsets()
	self.m_feat_mgr:Cleanup()
end

function LocalPlayer:Reset()
	self:Cleanup()
	self.m_vehicle:Reset()
	self.m_money_controller:Reset()
	self.m_last_vehicle = nil
	self:Destroy()
end

function LocalPlayer.ForceCloudSave()
	STATS.STAT_SAVE(0, false, 3, false)
end

---@param bossType int8_t -- -1 = retire | 0 = CEO | 1 = MC
function LocalPlayer:RegisterAsBoss(bossType)
	if (not Game.IsOnline()) then return end

	if (not math.is_inrange(bossType, -1, 1)) then
		return
	end

	if (bossType == -1) then
		self:Retire()
		return
	end

	ThreadManager:Run(function()
        scr_function.call_script_function("freemode", "GB_REGISTER", "2D 03 14 00 00 72", "void", {
		    { "bool", true },
		    { "int", bossType },
		    { "int", 208508824 }
		})
	end)
end

function LocalPlayer:Retire()
	if not (Game.IsOnline() and self:IsBoss()) then return end

	ThreadManager:Run(function()
        scr_function.call_script_function("freemode", "GB_RETIRE", "2D 01 03 00 00 38 00 56 ? ? 25 5B", "void", {
		    { "bool", true }
		})
	end)
end

Backend:RegisterEventCallbackAll(function()
	LocalPlayer:Reset()
end)

local function self_thread()
	LocalPlayer.m_feat_mgr:Update()
	LocalPlayer.m_money_controller:Update()
end

local function player_vehicle_thread()
	yield()

	if (LocalPlayer:GetRoomHash() ~= 0) then
		return
	end

	local PV        = LocalPlayer.m_vehicle
	local handle    = PV:GetHandle()
	local nativeVeh = LocalPlayer:GetVehicleNative()
	if (not ENTITY.DOES_ENTITY_EXIST(nativeVeh)) then
		return
	end

	if (VEHICLE.IS_VEHICLE_BEING_BROUGHT_TO_HALT(nativeVeh)) then
		return
	end

	if (CAM.IS_SCREEN_FADING_OUT() or CAM.IS_SCREEN_FADED_OUT()) then
		return
	end

	if (PV:IsValid()) then
		if (LocalPlayer:IsOnFoot()) then
			LocalPlayer:OnVehicleExit()
		elseif (LocalPlayer:IsDriving() and handle ~= nativeVeh) then
			LocalPlayer:OnVehicleSwitch()
			return
		end
	else
		if (handle ~= 0) then
			PV:Cleanup()
			return
		end

		if (LocalPlayer:IsDriving() and ENTITY.IS_ENTITY_A_VEHICLE(nativeVeh)) then
			PV:Set(nativeVeh)
		end
	end
end

ThreadManager:RegisterLooped("SS_SELF", self_thread, {
	exception_handler = function()
		LocalPlayer:Reset()
	end
})

ThreadManager:RegisterLooped("SS_VEHICLE_CONTROLLER", player_vehicle_thread, {
	exception_handler = function()
		LocalPlayer:GetVehicle():Cleanup()
	end
})
