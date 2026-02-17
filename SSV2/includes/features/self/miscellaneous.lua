-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")

---@class SelfMisc : FeatureBase
---@field private m_entity LocalPlayer
---@field private m_active boolean
---@field public m_phone_anims_enabled boolean
---@field public m_is_crouching boolean
---@field public m_is_playing_hands_up_anim boolean
local SelfMisc = setmetatable({}, FeatureBase)
SelfMisc.__index = SelfMisc
SelfMisc.m_cell_input = {
	Pair.new(172, 1),
	Pair.new(173, 2),
	Pair.new(174, 3),
	Pair.new(175, 4),
	Pair.new(176, 5),
	Pair.new(177, 5),
	Pair.new(178, 5),
	Pair.new(179, 5),
	Pair.new(180, 1),
	Pair.new(181, 2),
}

---@param ent LocalPlayer
---@return SelfMisc
function SelfMisc.new(ent)
	local self = FeatureBase.new(ent)
	---@diagnostic disable-next-line
	return setmetatable(self, SelfMisc)
end

function SelfMisc:Init()
	self.m_active = false
	self.m_phone_anims_enabled = false
	self.m_last_autoheal_update_time = 0
end

function SelfMisc:ShouldRun()
	return (LocalPlayer:IsAlive()
		and not Backend:IsPlayerSwitchInProgress()
		and not script.is_active("maintransition")
	)
end

function SelfMisc:Cleanup()
	self:ResetMpPhoneAnims()
	self:Uncrouch()
	self:HandsDown()
end

---@param flag_id ePedConfigFlags
---@param value boolean
function SelfMisc:TogglePedConfigFlag(flag_id, value)
	if (not LocalPlayer:GetConfigFlag(flag_id, value)) then
		LocalPlayer:SetConfigFlag(flag_id, value)
	end
end

function SelfMisc:Crouch()
	if (self.m_is_crouching) then
		return
	end

	local playerHandle = LocalPlayer:GetHandle()
	TaskWait(Game.RequestClipSet, "move_ped_crouched")

	self:HandsDown()
	PED.SET_PED_MOVEMENT_CLIPSET(playerHandle, "move_ped_crouched", 0.3)
	PED.SET_PED_STRAFE_CLIPSET(playerHandle, "move_aim_strafe_crouch_2h")
	PED.SET_PED_CAN_PLAY_AMBIENT_ANIMS(playerHandle, false)
	PED.SET_PED_CAN_PLAY_AMBIENT_BASE_ANIMS(playerHandle, false)
	TASK.SET_PED_CAN_PLAY_AMBIENT_IDLES(playerHandle, true, true)
	self.m_is_crouching = true
end

function SelfMisc:Uncrouch() -- is this even English?
	if (not self.m_is_crouching) then
		return
	end

	local playerHandle = LocalPlayer:GetHandle()
	PED.RESET_PED_MOVEMENT_CLIPSET(playerHandle, 0.35)
	PED.RESET_PED_STRAFE_CLIPSET(playerHandle)
	PED.SET_PED_CAN_PLAY_AMBIENT_ANIMS(playerHandle, true)
	PED.SET_PED_CAN_PLAY_AMBIENT_BASE_ANIMS(playerHandle, true)
	TASK.SET_PED_CAN_PLAY_AMBIENT_IDLES(playerHandle, false, true)
	self.m_is_crouching = false
end

function SelfMisc:UpdateCrouchAnim()
	if (not GVars.features.self.crouch) then
		return
	end

	Backend:RegisterDisabledControl(36)

	if (LocalPlayer:IsOnFoot() and LocalPlayer:CanCrouch() and PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 36)) then
		if (self.m_is_crouching) then
			self:Uncrouch()
		else
			self:Crouch()
		end
	end

	if (self.m_is_crouching and not (LocalPlayer:IsOnFoot() and LocalPlayer:IsAlive())) then
		self:Uncrouch()
	end
end

function SelfMisc:HandsDown()
	if (not self.m_is_playing_hands_up_anim) then
		return
	end

	LocalPlayer:ClearTasks()
	self.m_is_playing_hands_up_anim = false
end

function SelfMisc:HandsUp()
	if (self.m_is_playing_hands_up_anim) then
		LocalPlayer:ClearTasks()
		self.m_is_playing_hands_up_anim = false
		return
	end

	self:Uncrouch()
	TaskWait(Game.RequestAnimDict, "mp_missheist_countrybank@lift_hands")
	TASK.TASK_PLAY_ANIM(
		LocalPlayer:GetHandle(),
		"mp_missheist_countrybank@lift_hands",
		"lift_hands_in_air_outro",
		4.0,
		-4.0,
		-1,
		50,
		1.0,
		false,
		false,
		false
	)
	self.m_is_playing_hands_up_anim = true
end

function SelfMisc:UpdateHandsUpAnim()
	if (GVars.features.self.hands_up) then
		PAD.DISABLE_CONTROL_ACTION(0, 29, true)

		if (LocalPlayer:CanPutHandsUp() and PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 29)) then
			self:HandsUp()
		end

		if (self.m_is_playing_hands_up_anim and not (LocalPlayer:IsOnFoot() and LocalPlayer:IsAlive())) then
			self.m_is_playing_hands_up_anim = false
		end
	end
end

local phone_anim_dict     = "anim@scripted@freemode@ig19_mobile_phone@male@"
local phone_anim_name     = "base"
local phone_anim_boneMask = "BONEMASK_HEAD_NECK_AND_R_ARM"
function SelfMisc:UpdatePhoneGestures()
	if (not self.m_phone_anims_enabled) then
		return
	end

	local playerHandle = LocalPlayer:GetHandle()
	local is_browsing_email = script.is_active("APPMPEMAIL")
	if (AUDIO.IS_MOBILE_PHONE_CALL_ONGOING()) then
		TaskWait(Game.RequestAnimDict, phone_anim_dict)
		TASK.TASK_PLAY_PHONE_GESTURE_ANIMATION(
			playerHandle,
			phone_anim_dict,
			phone_anim_name,
			phone_anim_boneMask,
			0.25,
			0.25,
			true,
			false
		)
	elseif (TASK.IS_PLAYING_PHONE_GESTURE_ANIM(playerHandle)) then
		TASK.TASK_STOP_PHONE_GESTURE_ANIMATION(playerHandle, 0.25)
	end

	if (LocalPlayer:IsUsingPhone()) then
		MOBILE.CELL_HORIZONTAL_MODE_TOGGLE(is_browsing_email)
		for _, p in ipairs(self.m_cell_input) do
			if PAD.IS_CONTROL_JUST_PRESSED(0, p.first) then
				MOBILE.CELL_SET_INPUT(p.second)
			end
		end
	end
end

function SelfMisc:ResetMpPhoneAnims()
	if (not self.m_phone_anims_enabled) then
		return
	end

	LocalPlayer:ToggleMpPhoneAnims(false)
	local playerHandle = LocalPlayer:GetHandle()
	if (TASK.IS_PLAYING_PHONE_GESTURE_ANIM(playerHandle)) then
		TASK.TASK_STOP_PHONE_GESTURE_ANIMATION(playerHandle, 0.25)
	end
	self.m_phone_anims_enabled = false
end

function SelfMisc:UpdateMpPhoneAnims()
	if (not Game.IsOnline()) then
		return
	end

	if (not GVars.features.self.phone_anims or not LocalPlayer:CanUsePhoneAnims()) then
		self:ResetMpPhoneAnims()
		return
	end

	-- This looks like it should be inside the if statement below but it not really.
	--The game resets the config flags back on certain conditions.
	LocalPlayer:ToggleMpPhoneAnims(true)
	if (not self.m_phone_anims_enabled) then
		self.m_phone_anims_enabled = true
	end

	self:UpdatePhoneGestures()
end

function SelfMisc:UpdateFlagBasedFeatures()
	-- TODO: refactor these into periodic checks since the game likes to reset them whenever
	self:TogglePedConfigFlag(
		Enums.ePedConfigFlags.DontAllowToBeDraggedOutOfVehicle,
		GVars.features.self.no_carjacking
	)

	self:TogglePedConfigFlag(
		Enums.ePedConfigFlags.PedsJackingMeDontGetIn,
		GVars.features.self.no_carjacking
	)

	self:TogglePedConfigFlag(
		Enums.ePedConfigFlags.PlayersDontDragMeOutOfCar,
		GVars.features.self.no_carjacking
	)

	self:TogglePedConfigFlag(
		Enums.ePedConfigFlags.UseLockpickVehicleEntryAnimations,
		GVars.features.self.jacking_always_lockpick_anim
	)

	self:TogglePedConfigFlag(
		Enums.ePedConfigFlags.IgnoreInteriorCheckForSprinting,
		GVars.features.self.sprint_inside_interiors
	)

	if (Game.IsOnline()) then
		self:TogglePedConfigFlag(
			Enums.ePedConfigFlags.AllowBikeAlternateAnimations,
			GVars.features.self.mc_alt_bike_anims
		)
	end

	if (GVars.features.self.sprint_inside_interiors and not LocalPlayer:IsOutside()) then
		LocalPlayer:SetPedResetFlag(Enums.ePedResetFlags.DisablePlayerJumping, false)
		LocalPlayer:SetPedResetFlag(Enums.ePedResetFlags.DisablePlayerVaulting, false)
		LocalPlayer:SetPedResetFlag(Enums.ePedResetFlags.DisablePlayerAutoVaulting, false)
		LocalPlayer:SetPedResetFlag(Enums.ePedResetFlags.UseInteriorCapsuleSettings, false)
		PED.SET_PED_MAX_MOVE_BLEND_RATIO(LocalPlayer:GetHandle(), 3)
	end

	if (GVars.features.self.disable_action_mode) then
		LocalPlayer:SetPedResetFlag(Enums.ePedResetFlags.DisableActionMode, true)
	end

	if (GVars.features.self.allow_headprops_in_vehicles) then
		LocalPlayer:SetPedResetFlag(Enums.ePedResetFlags.AllowHeadPropInVehicle, true)
	end

	if (GVars.features.self.stand_on_veh_roof) then
		LocalPlayer:SetPedResetFlag(Enums.ePedResetFlags.BlockRagdollFromVehicleFallOff, true)
	end
end

function SelfMisc:Update()
	if (LocalPlayer:IsRagdoll()) then
		self:Cleanup()
		return
	end

	self:UpdateMpPhoneAnims()
	self:UpdateFlagBasedFeatures()
	self:UpdateCrouchAnim()
	self:UpdateHandsUpAnim()
end

return SelfMisc
