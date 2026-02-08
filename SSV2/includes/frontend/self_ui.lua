-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local self_tab = GUI:RegisterNewTab(Enums.eTabID.TAB_SELF, "Self")
local katana_replace_weapons <const> = {
	2508868239,
	1141786504,
	3713923289,
	2484171525,
}

local function CheckIfRagdollBlocked()
	ThreadManager:Run(function()
		if (Self:IsOnFoot() and not PED.CAN_PED_RAGDOLL(Self:GetHandle())) then
			Notifier:ShowWarning(
				"Samurais Scripts",
				_T("SELF_RAGDOLL_BLOCK_INFO")
			)
		end
	end)
end

self_tab:AddBoolCommand("SELF_AUTOHEAL",
	"features.self.autoheal.enabled",
	nil,
	nil,
	{ description = "SELF_AUTOHEAL_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_PHONE_ANIMS",
	"features.self.phone_anims",
	nil,
	nil,
	{ description = "SELF_PHONE_ANIMS_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_MC_BIKE_ANIMS",
	"features.self.mc_alt_bike_anims",
	nil,
	nil,
	{ description = "SELF_MC_BIKE_ANIMS_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_ACTION_MODE",
	"features.self.disable_action_mode",
	nil,
	nil,
	{ description = "SELF_ACTION_MODE_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_HEADPROPS",
	"features.self.allow_headprops_in_vehicles",
	nil,
	nil,
	{ description = "SELF_HEADPROPS_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_STAND_ON_VEHS",
	"features.self.stand_on_veh_roof",
	nil,
	nil,
	{ description = "SELF_STAND_ON_VEHS_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_NO_CARJACKING",
	"features.self.no_carjacking",
	nil,
	nil,
	{ description = "SELF_NO_CARJACKING_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_CROUCH",
	"features.self.crouch",
	nil,
	function()
		Backend:RemoveDisabledControl(36)
	end,
	{ description = "SELF_CROUCH_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_HANDS_UP",
	"features.self.hands_up",
	nil,
	function()
		Backend:RemoveDisabledControl(29)
	end,
	{ description = "SELF_HANDS_UP_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_SPRINT_INSIDE",
	"features.self.sprint_inside_interiors",
	nil,
	nil,
	{ description = "SELF_SPRINT_INSIDE_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_LOCKPICK_ANIM",
	"features.self.jacking_always_lockpick_anim",
	nil,
	nil,
	{ description = "SELF_LOCKPICK_ANIM_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_ROD",
	"features.self.rod",
	function()
		GVars.features.self.clumsy = false
		CheckIfRagdollBlocked()
	end,
	nil,
	{ description = "SELF_ROD_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_CLUMSY",
	"features.self.clumsy",
	function()
		GVars.features.self.rod = false
		CheckIfRagdollBlocked()
	end,
	nil,
	{ description = "SELF_CLUMSY_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_MAGIC_BULLET",
	"features.weapon.magic_bullet",
	nil,
	nil,
	{ description = "SELF_MAGIC_BULLET_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_LASER_SIGHTS",
	"features.weapon.laser_sights.enabled",
	nil,
	nil,
	{ description = "SELF_LASER_SIGHTS_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_KATANA",
	"features.weapon.katana.enabled",
	nil,
	nil,
	{ description = "SELF_KATANA_TT" },
	true,
	true
)

local function SelfUI()
	self_tab:GetGridRenderer():Draw()

	ImGui.Spacing()
	ImGui.SeparatorText(_T("GENERIC_SETTINGS_LABEL"))

	if (GVars.features.self.autoheal.enabled) then
		ImGui.SetNextItemWidth(240)
		GVars.features.self.autoheal.regen_speed, _ = ImGui.SliderInt(
			_T("SELF_REGEN_SPEED"),
			GVars.features.self.autoheal.regen_speed,
			1, 100
		)
	end

	if (GVars.features.self.rod or GVars.features.self.clumsy) then
		GVars.features.self.ragdoll_sound, _ = GUI:CustomToggle(_T("SELF_RAGDOLL_SOUND"),
			GVars.features.self.ragdoll_sound,
			{ tooltip = _T("SELF_RAGDOLL_SOUND_TT") }
		)
	end

	if (GVars.features.weapon.laser_sights.enabled) then
		ImGui.ColorEditVec4(_T("SELF_LASER_SIGHTS_COL"), GVars.features.weapon.laser_sights.color)

		GVars.features.weapon.laser_sights.ray_length, _ = ImGui.SliderInt(_T("SELF_LASER_SIGHTS_LENGTH"),
			GVars.features.weapon.laser_sights.ray_length,
			100,
			1000
		)
	end

	if (GVars.features.weapon.katana.enabled) then
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
						if not (Self:IsOnFoot() and Self:IsOutside()) then
							return
						end

						local handle = Self:GetHandle()
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
end

self_tab:RegisterGUI(SelfUI)
