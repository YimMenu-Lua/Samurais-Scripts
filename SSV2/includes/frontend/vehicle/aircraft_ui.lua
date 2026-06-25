-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local flrs                    = require("includes.features.vehicle.flares")
Flares                        = LocalPlayer:GetVehicle():AddFeature(flrs)
local autopilot_state_idx     = 0
local autopilot_index_changed = false
local autopilot_labels
local planes_tab              = GUI:RegisterNewTab(Enums.eTabID.TAB_VEHICLE, "SUBTAB_AIRCRAFT", nil, nil, true)
local optionPopup             = {
	flags       = ImGuiWindowFlags.NoResize | ImGuiWindowFlags.AlwaysAutoResize,
	label       = "##optionsPopup",
	should_draw = false,
	---@type function?
	callback    = nil
}

local function triggerbotSettings()
	GVars.features.vehicle.aircraft_mg.enemies_only = GUI:CustomToggle(_T("VEH_MG_TRIGGERBOT_ENEMY"),
		GVars.features.vehicle.aircraft_mg.enemies_only,
		{ tooltip = _T("VEH_MG_TRIGGERBOT_ENEMY_TT") }
	)

	GVars.features.vehicle.aircraft_mg.tiggerbot_range = ImGui.SliderFloat(_T("VEH_MG_TRIGGERBOT_RANGE"),
		GVars.features.vehicle.aircraft_mg.tiggerbot_range,
		100.0,
		1000.0,
		"%.0f"
	)
end

local function manualAimSettings()
	GVars.features.vehicle.aircraft_mg.marker_size = ImGui.SliderFloat(_T("VEH_MG_MARKER_SIZE"),
		GVars.features.vehicle.aircraft_mg.marker_size,
		1.0,
		10.0
	)

	ImGui.ColorEditVec4(_T("VEH_MG_MARKER_COL"), GVars.features.vehicle.aircraft_mg.marker_color)
end

planes_tab:AddBoolCommand("VEH_FAST_JETS",
	{
		gvar_key         = "features.vehicle.fast_jets",
		translate_label  = true,
		meta             = { description = "VEH_FAST_JETS_TT", isTranslatorLabel = true },
		register_command = true,
		options_data     = {
			condition = function() return GVars.features.vehicle.fast_jets end,
			callback  = function()
				optionPopup.callback    = function()
					local cfg           = GVars.features.vehicle
					cfg.fast_jets_speed = ImGui.SliderFloat("##speed", cfg.fast_jets_speed, 100.0, 300.0)
				end
				optionPopup.label       = _T("VEH_FAST_JETS")
				optionPopup.should_draw = true
			end
		}
	}
)
planes_tab:AddBoolCommand("VEH_NO_JET_STALL",
	{
		gvar_key         = "features.vehicle.no_jet_stall",
		translate_label  = true,
		meta             = { description = "VEH_NO_JET_STALL_TT", isTranslatorLabel = true },
		register_command = true
	}
)
planes_tab:AddBoolCommand("VEH_NO_TURBULENCE",
	{
		gvar_key        = "features.vehicle.no_turbulence",
		translate_label = true,
		on_disable      = function()
			ThreadManager:Run(function()
				local PV = LocalPlayer:GetVehicle()
				PV:RestorePatch(PV.MemoryPatches.Turbulence)
				PV:RestorePatch(PV.MemoryPatches.WindMult)
			end)
		end,
	}
)
planes_tab:AddBoolCommand("VEH_FLARES",
	{
		gvar_key        = "features.vehicle.flares",
		translate_label = true,
		meta            = { description = "VEH_FLARES_TT" },
		on_enable       = function() Flares:OnEnable() end,
		on_disable      = function() Flares:OnDisable() end,
	}
)
planes_tab:AddBoolCommand("VEH_MG_TRIGGERBOT",
	{
		gvar_key        = "features.vehicle.aircraft_mg.triggerbot",
		translate_label = true,
		meta            = { description = "VEH_MG_TRIGGERBOT_TT" },
		options_data    = {
			condition = function()
				return GVars.features.vehicle.aircraft_mg.triggerbot
			end,
			callback = function()
				optionPopup.callback    = triggerbotSettings
				optionPopup.label       = _T("VEH_MG_TRIGGERBOT")
				optionPopup.should_draw = true
			end
		}
	}
)
planes_tab:AddBoolCommand("VEH_MG_MANUAL_AIM",
	{
		gvar_key        = "features.vehicle.aircraft_mg.manual_aim",
		translate_label = true,
		meta            = { description = "VEH_MG_MANUAL_AIM_TT" },
		options_data    = {
			condition = function()
				return GVars.features.vehicle.aircraft_mg.manual_aim
			end,
			callback = function()
				optionPopup.callback    = manualAimSettings
				optionPopup.label       = _T("VEH_MG_MANUAL_AIM")
				optionPopup.should_draw = true
			end
		}
	}
)
planes_tab:AddBoolCommand("VEH_COBRA_MANEUVER",
	{
		gvar_key        = "features.vehicle.cobra_maneuver",
		translate_label = true,
		meta            = { description = "VEH_COBRA_MANEUVER_TT" },
	}
)

planes_tab:RegisterGUI(function()
	planes_tab:GetGridRenderer():Draw()

	ImGui.Spacing()
	ImGui.SeparatorText(_T("VEH_AUTOPILOT"))
	local eligible = LocalPlayer:GetVehicle().m_autopilot.eligible
	ImGui.BeginDisabled(not eligible)
	if (not autopilot_labels) then
		autopilot_labels = {
			_T("GENERIC_NONE"),
			_T("GENERIC_WAYPOINT"),
			_T("GENERIC_OBJECTIVE"),
			_T("GENERIC_RANDOM")
		}
	else
		autopilot_state_idx, autopilot_index_changed = ImGui.Combo(
			eligible and "##autopilotdest" or _T("GENERIC_NOT_IN_PLANE"),
			autopilot_state_idx,
			autopilot_labels,
			4
		)

		if (autopilot_index_changed) then
			ThreadManager:Run(function()
				LocalPlayer:GetVehicle():UpdateAutopilotState(autopilot_state_idx)
			end)
		end

		if (LocalPlayer:GetVehicle().m_autopilot.last_interrupted) then
			autopilot_state_idx = 0
		end
	end
	ImGui.EndDisabled()

	if (optionPopup.should_draw) then
		ImGui.OpenPopup(optionPopup.label)
		optionPopup.should_draw = false
	end

	ImGui.SetNextWindowSizeConstraints(300, 140, 600, 800)
	if (optionPopup.callback and ImGui.BeginPopupModal(optionPopup.label, true, optionPopup.flags)) then
		optionPopup.callback()
		ImGui.EndPopup()
	end
end)
