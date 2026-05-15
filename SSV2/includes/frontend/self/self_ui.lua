-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local self_tab                       = GUI:RegisterNewTab(Enums.eTabID.TAB_SELF, "Self")
local drawPlayerAbilities            = require("includes.frontend.self.player_abilities")
local showAbilities                  = false
local katana_replace_weapons <const> = {
	2508868239,
	1141786504,
	3713923289,
	2484171525,
}

local optionPopup                    = {
	flags       = ImGuiWindowFlags.NoResize | ImGuiWindowFlags.AlwaysAutoResize,
	label       = "##optionsPopup",
	should_draw = false,
	---@type function?
	callback    = nil
}

local function laserOptions()
	ImGui.ColorEditVec4(_T("SELF_LASER_SIGHTS_COL"), GVars.features.weapon.laser_sights.color)

	GVars.features.weapon.laser_sights.ray_length = ImGui.SliderInt(_T("SELF_LASER_SIGHTS_LENGTH"),
		GVars.features.weapon.laser_sights.ray_length,
		100,
		1000
	)
end

local function ragdollOptions()
	GVars.features.self.ragdoll_sound = GUI:CustomToggle(_T("SELF_RAGDOLL_SOUND"),
		GVars.features.self.ragdoll_sound,
		{ tooltip = _T("SELF_RAGDOLL_SOUND_TT") }
	)
end

local function katanaOptions()
	if (ImGui.BeginCombo(_T("SELF_KATANA_REPLACE_MODEL"), GVars.features.weapon.katana.name)) then
		for _, hash in ipairs(katana_replace_weapons) do
			local is_selected = GVars.features.weapon.katana.model == hash
			local name = Game.GetWeaponDisplayName(hash)
			if (ImGui.Selectable(name, is_selected)) then
				GVars.features.weapon.katana.name = name
				GVars.features.weapon.katana.model = hash
			end

			if (ImGui.IsItemClicked(0)) then
				ThreadManager:Run(function()
					if not (LocalPlayer:IsOnFoot() and LocalPlayer:IsOutside()) then
						return
					end

					local handle = LocalPlayer:GetHandle()
					if (WEAPON.IS_PED_ARMED(handle, 7)) then
						WEAPON.SET_CURRENT_PED_WEAPON(handle, 0xA2719263, true)
					end

					if (WEAPON.HAS_PED_GOT_WEAPON(handle, hash, false)) then
						sleep(300)
						WEAPON.SET_CURRENT_PED_WEAPON(handle, hash, true)
					end
				end)
			end
		end
		ImGui.EndCombo()
	end
end

local function CheckIfRagdollBlocked()
	ThreadManager:Run(function()
		if (LocalPlayer:IsOnFoot() and not LocalPlayer:IsRagdoll() and not LocalPlayer:CanRagdoll()) then
			Notifier:ShowWarning("Samurais Scripts", _T("SELF_RAGDOLL_BLOCK_INFO"))
		end
	end)
end

self_tab:AddBoolCommand("SELF_AUTOHEAL",
	{
		gvar_key          = "features.self.autoheal.enabled",
		isTranslatorLabel = true,
		meta              = { description = "SELF_AUTOHEAL_TT" },
		fineTuning        = {
			condition = function()
				return GVars.features.self.autoheal.enabled
			end,
			callback = function()
				optionPopup.callback    = function()
					GVars.features.self.autoheal.regen_speed = ImGui.SliderInt(
						_T("SELF_REGEN_SPEED"),
						GVars.features.self.autoheal.regen_speed,
						1, 100
					)
				end
				optionPopup.label       = _T("SELF_AUTOHEAL")
				optionPopup.should_draw = true
			end
		}
	}
)
self_tab:AddBoolCommand("SELF_PHONE_ANIMS",
	{
		gvar_key          = "features.self.phone_anims",
		isTranslatorLabel = true,
		meta              = { description = "SELF_PHONE_ANIMS_TT" },
	}
)
self_tab:AddBoolCommand("SELF_MC_BIKE_ANIMS",
	{
		gvar_key          = "features.self.mc_alt_bike_anims",
		isTranslatorLabel = true,
		meta              = { description = "SELF_MC_BIKE_ANIMS_TT" },
	}
)
self_tab:AddBoolCommand("SELF_ACTION_MODE",
	{
		gvar_key          = "features.self.disable_action_mode",
		isTranslatorLabel = true,
		meta              = { description = "SELF_ACTION_MODE_TT" },
	}
)
self_tab:AddBoolCommand("SELF_HEADPROPS",
	{
		gvar_key          = "features.self.allow_headprops_in_vehicles",
		isTranslatorLabel = true,
		meta              = { description = "SELF_HEADPROPS_TT" },
	}
)
self_tab:AddBoolCommand("SELF_STAND_ON_VEHS",
	{
		gvar_key          = "features.self.stand_on_veh_roof",
		isTranslatorLabel = true,
		meta              = { description = "SELF_STAND_ON_VEHS_TT" },
	}
)
self_tab:AddBoolCommand("SELF_NO_CARJACKING",
	{
		gvar_key          = "features.self.no_carjacking",
		isTranslatorLabel = true,
		meta              = { description = "SELF_NO_CARJACKING_TT" },
	}
)
self_tab:AddBoolCommand("SELF_CROUCH",
	{
		gvar_key          = "features.self.crouch",
		isTranslatorLabel = true,
		meta              = { description = "SELF_CROUCH_TT" },
		on_disable        = function() Backend:RemoveDisabledControl(36) end,
	}
)
self_tab:AddBoolCommand("SELF_HANDS_UP",
	{
		gvar_key          = "features.self.hands_up",
		isTranslatorLabel = true,
		meta              = { description = "SELF_HANDS_UP_TT" },
		on_disable        = function() Backend:RemoveDisabledControl(29) end,
	}
)
self_tab:AddBoolCommand("SELF_SPRINT_INSIDE",
	{
		gvar_key          = "features.self.sprint_inside_interiors",
		isTranslatorLabel = true,
		meta              = { description = "SELF_SPRINT_INSIDE_TT" },
	}
)
self_tab:AddBoolCommand("SELF_LOCKPICK_ANIM",
	{
		gvar_key          = "features.self.jacking_always_lockpick_anim",
		isTranslatorLabel = true,
		meta              = { description = "SELF_LOCKPICK_ANIM_TT" },
	}
)
self_tab:AddBoolCommand("SELF_ROD",
	{
		gvar_key          = "features.self.rod",
		isTranslatorLabel = true,
		meta              = { description = "SELF_ROD_TT" },
		on_enable         = function()
			GVars.features.self.clumsy = false
			CheckIfRagdollBlocked()
		end,
		fineTuning        = {
			condition = function()
				return GVars.features.self.rod
			end,
			callback = function()
				optionPopup.callback    = ragdollOptions
				optionPopup.label       = _T("SELF_ROD")
				optionPopup.should_draw = true
			end
		}
	}
)
self_tab:AddBoolCommand("SELF_CLUMSY",
	{
		gvar_key          = "features.self.clumsy",
		isTranslatorLabel = true,
		meta              = { description = "SELF_CLUMSY_TT" },
		on_enable         = function()
			GVars.features.self.rod = false
			CheckIfRagdollBlocked()
		end,
		fineTuning        = {
			condition = function()
				return GVars.features.self.clumsy
			end,
			callback = function()
				optionPopup.callback    = ragdollOptions
				optionPopup.label       = _T("SELF_CLUMSY")
				optionPopup.should_draw = true
			end
		}
	}
)
self_tab:AddBoolCommand("SELF_MAGIC_BULLET",
	{
		gvar_key          = "features.weapon.magic_bullet",
		isTranslatorLabel = true,
		meta              = { description = "SELF_MAGIC_BULLET_TT" },
	}
)
self_tab:AddBoolCommand("SELF_LASER_SIGHTS",
	{
		gvar_key          = "features.weapon.laser_sights.enabled",
		isTranslatorLabel = true,
		meta              = { description = "SELF_LASER_SIGHTS_TT" },
		fineTuning        = {
			condition = function()
				return GVars.features.weapon.laser_sights.enabled
			end,
			callback = function()
				optionPopup.callback    = laserOptions
				optionPopup.label       = _T("SELF_LASER_SIGHTS")
				optionPopup.should_draw = true
			end
		}
	}
)
self_tab:AddBoolCommand("SELF_KATANA",
	{
		gvar_key          = "features.weapon.katana.enabled",
		isTranslatorLabel = true,
		meta              = { description = "SELF_KATANA_TT" },
		fineTuning        = {
			condition = function()
				return GVars.features.weapon.katana.enabled
			end,
			callback = function()
				optionPopup.callback    = katanaOptions
				optionPopup.label       = _T("SELF_KATANA")
				optionPopup.should_draw = true
			end
		}
	}
)

local function SelfUI()
	ImGui.SeparatorText(_T("GENERIC_GENERAL_LABEL"))
	self_tab:GetGridRenderer():Draw()

	if (Game.IsOnline()) then
		ImGui.Spacing()
		ImGui.SeparatorText(_T("SELF_ABILITY_EDITOR"))
		showAbilities = GUI:CustomToggle(_T("GENERIC_ENABLE"), showAbilities)

		if (showAbilities) then
			ImGui.Spacing()
			drawPlayerAbilities()
		end
	end

	if (optionPopup.should_draw) then
		ImGui.OpenPopup(optionPopup.label)
		optionPopup.should_draw = false
	end

	ImGui.SetNextWindowSizeConstraints(300, 140, 600, 800)
	if (optionPopup.callback and ImGui.BeginPopupModal(optionPopup.label, true, optionPopup.flags)) then
		optionPopup.callback()
		ImGui.EndPopup()
	end
end

self_tab:RegisterGUI(SelfUI)
