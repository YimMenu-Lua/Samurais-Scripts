---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local FeatureBase = require("includes.modules.FeatureBase")

---@class SelfMisc : FeatureBase
---@field private m_entity Self
---@field private m_active boolean
---@field private m_last_autoheal_update_time milliseconds
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

---@param ent Self
---@return SelfMisc
function SelfMisc.new(ent)
	local self = FeatureBase.new(ent)
	return setmetatable(self, SelfMisc)
end

function SelfMisc:Init()
	self.m_active = false
	self.m_phone_anims_enabled = false
	self.m_last_autoheal_update_time = 0
end

function SelfMisc:ShouldRun()
	return (Self:IsAlive()
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
	if (not Self:GetConfigFlag(flag_id, value)) then
		Self:SetConfigFlag(flag_id, value)
	end
end

function SelfMisc:AutoHeal()
	if (not GVars.features.self.autoheal.enabled) then
		return
	end

	if (Time.millis() < self.m_last_autoheal_update_time) then
		return
	end

	local maxHp = Self:GetMaxHealth()
	local hp = Self:GetHealth()
	local maxArmr = Self:GetMaxArmour()
	local armor = Self:GetArmour()
	local handle = Self:GetHandle()

	if (hp < maxHp and hp > 0) then
		if (PED.IS_PED_IN_COVER(handle, false)) then
			ENTITY.SET_ENTITY_HEALTH(handle, hp + 10, 0, 0)
		else
			ENTITY.SET_ENTITY_HEALTH(handle, hp + 1, 0, 0)
		end
	end

	if (armor == nil) then
		PED.SET_PED_ARMOUR(handle, 10)
	end

	if (armor and armor < maxArmr) then
		PED.ADD_ARMOUR_TO_PED(handle, 0.5)
	end

	self.m_last_autoheal_update_time = Time.millis() + (1000 / GVars.features.self.autoheal.regen_speed)
end

function SelfMisc:Crouch()
	if (self.m_is_crouching) then
		return
	end

	local playerHandle = Self:GetHandle()
	Await(Game.RequestClipSet, "move_ped_crouched")

	self:HandsDown()
	PED.SET_PED_MOVEMENT_CLIPSET(playerHandle, "move_ped_crouched", 0.3)
	PED.SET_PED_STRAFE_CLIPSET(playerHandle, "move_aim_strafe_crouch_2h")
	self.m_is_crouching = true
end

function SelfMisc:Uncrouch() -- is this even English?
	if (not self.m_is_crouching) then
		return
	end

	local playerHandle = Self:GetHandle()
	PED.RESET_PED_MOVEMENT_CLIPSET(playerHandle, 0.35)
	PED.RESET_PED_STRAFE_CLIPSET(playerHandle)
	self.m_is_crouching = false
end

function SelfMisc:UpdateCrouchAnim()
	if (not GVars.features.self.crouch) then
		return
	end

	Backend:RegisterDisabledControl(36)

	if (Self:IsOnFoot() and Self:CanCrouch() and PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 36)) then
		if (self.m_is_crouching) then
			self:Uncrouch()
		else
			self:Crouch()
		end
	end

	if (self.m_is_crouching and not (Self:IsOnFoot() and Self:IsAlive())) then
		self:Uncrouch()
	end
end

function SelfMisc:HandsDown()
	if (not self.m_is_playing_hands_up_anim) then
		return
	end

	Self:ClearTasks()
	self.m_is_playing_hands_up_anim = false
end

function SelfMisc:HandsUp()
	if (self.m_is_playing_hands_up_anim) then
		Self:ClearTasks()
		self.m_is_playing_hands_up_anim = false
		return
	end

	self:Uncrouch()
	Await(Game.RequestAnimDict, "mp_missheist_countrybank@lift_hands")
	TASK.TASK_PLAY_ANIM(
		Self:GetHandle(),
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

		if (Self:CanPutHandsUp() and PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 29)) then
			self:HandsUp()
		end

		if (self.m_is_playing_hands_up_anim and not (Self:IsOnFoot() and Self:IsAlive())) then
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

	local playerHandle = Self:GetHandle()
	local is_browsing_email = script.is_active("APPMPEMAIL")
	if (AUDIO.IS_MOBILE_PHONE_CALL_ONGOING()) then
		Await(Game.RequestAnimDict, phone_anim_dict)
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

	if (Self:IsUsingPhone()) then
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

	Self:ToggleMpPhoneAnims(false)
	local playerHandle = Self:GetHandle()
	if (TASK.IS_PLAYING_PHONE_GESTURE_ANIM(playerHandle)) then
		TASK.TASK_STOP_PHONE_GESTURE_ANIMATION(playerHandle, 0.25)
	end
	self.m_phone_anims_enabled = false
end

function SelfMisc:UpdateMpPhoneAnims()
	if (not Game.IsOnline()) then
		return
	end

	if (not GVars.features.self.phone_anims or not Self:CanUsePhoneAnims()) then
		self:ResetMpPhoneAnims()
		return
	end

	-- This looks like it should be inside the if statement below but it not really.
	--The game resets the config flags back on certain conditions.
	Self:ToggleMpPhoneAnims(true)
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

	self:TogglePedConfigFlag(
		Enums.ePedConfigFlags.AllowBikeAlternateAnimations,
		GVars.features.self.mc_alt_bike_anims
	)

	if (GVars.features.self.sprint_inside_interiors and not Self:IsOutside()) then
		Self:SetPedResetFlag(Enums.ePedResetFlags.DisablePlayerJumping, false)
		Self:SetPedResetFlag(Enums.ePedResetFlags.DisablePlayerVaulting, false)
		Self:SetPedResetFlag(Enums.ePedResetFlags.DisablePlayerAutoVaulting, false)
		Self:SetPedResetFlag(Enums.ePedResetFlags.UseInteriorCapsuleSettings, false)
		PED.SET_PED_MAX_MOVE_BLEND_RATIO(Self:GetHandle(), 3)
	end

	if (GVars.features.self.disable_action_mode) then
		Self:SetPedResetFlag(Enums.ePedResetFlags.DisableActionMode, true)
	end

	if (GVars.features.self.allow_headprops_in_vehicles) then
		Self:SetPedResetFlag(Enums.ePedResetFlags.AllowHeadPropInVehicle, true)
	end

	if (GVars.features.self.stand_on_veh_roof) then
		Self:SetPedResetFlag(Enums.ePedResetFlags.BlockRagdollFromVehicleFallOff, true)
	end
end

function SelfMisc:Update()
	if (Self:IsRagdoll()) then
		self:Cleanup()
		return
	end

	self:AutoHeal()
	self:UpdateMpPhoneAnims()
	self:UpdateFlagBasedFeatures()
	self:UpdateCrouchAnim()
	self:UpdateHandsUpAnim()
end

return SelfMisc
