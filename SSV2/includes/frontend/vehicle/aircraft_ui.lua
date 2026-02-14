-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local flrs                    = require("includes.features.vehicle.flares")
local autopilot_state_idx     = 0
local autopilot_index_changed = false
local autopilot_labels
local planes_tab              = GUI:RegisterNewTab(Enums.eTabID.TAB_VEHICLE, "SUBTAB_AIRCRAFT", nil, nil, true)
Flares                        = LocalPlayer:GetVehicle():AddFeature(flrs)

planes_tab:AddBoolCommand(
	"VEH_FAST_JETS",
	"features.vehicle.fast_jets",
	nil,
	nil,
	{ description = "VEH_FAST_JETS_TT", isTranslatorLabel = true },
	false,
	true
)

planes_tab:AddBoolCommand(
	"VEH_NO_JET_STALL",
	"features.vehicle.no_jet_stall",
	nil,
	nil,
	{ description = "VEH_NO_JET_STALL_TT", isTranslatorLabel = true },
	false,
	true
)

planes_tab:AddBoolCommand(
	"VEH_NO_TURBULENCE",
	"features.vehicle.no_turbulence",
	nil,
	function()
		ThreadManager:Run(function()
			local PV = LocalPlayer:GetVehicle()
			PV:RestorePatch(PV.MemoryPatches.Turbulence)
			PV:RestorePatch(PV.MemoryPatches.WindMult)
		end)
	end,
	nil,
	false,
	true
)

planes_tab:AddBoolCommand(
	"VEH_FLARES",
	"features.vehicle.flares",
	function()
		Flares:OnEnable()
	end,
	function()
		Flares:OnDisable()
	end,
	{ description = "VEH_FLARES_TT" },
	true,
	true
)

planes_tab:AddBoolCommand(
	"VEH_MG_TRIGGERBOT",
	"features.vehicle.aircraft_mg.triggerbot",
	nil,
	nil,
	{ description = "VEH_MG_TRIGGERBOT_TT" },
	true,
	true
)

planes_tab:AddBoolCommand(
	"VEH_MG_MANUAL_AIM",
	"features.vehicle.aircraft_mg.manual_aim",
	nil,
	nil,
	{ description = "VEH_MG_MANUAL_AIM_TT" },
	true,
	true
)

planes_tab:AddBoolCommand(
	"VEH_COBRA_MANEUVER",
	"features.vehicle.cobra_maneuver",
	nil,
	nil,
	{ description = "VEH_COBRA_MANEUVER_TT" },
	true,
	true
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

	ImGui.Spacing()
	ImGui.SeparatorText(_T("GENERIC_SETTINGS_LABEL"))
	if (GVars.features.vehicle.aircraft_mg.triggerbot) then
		GVars.features.vehicle.aircraft_mg.enemies_only, _ = GUI:CustomToggle(_T("VEH_MG_TRIGGERBOT_ENEMY"),
			GVars.features.vehicle.aircraft_mg.enemies_only,
			{ tooltip = _T("VEH_MG_TRIGGERBOT_ENEMY_TT") }
		)

		GVars.features.vehicle.aircraft_mg.tiggerbot_range, _ = ImGui.SliderFloat(_T("VEH_MG_TRIGGERBOT_RANGE"),
			GVars.features.vehicle.aircraft_mg.tiggerbot_range,
			100.0,
			1000.0,
			"%.0f"
		)
	end

	if (GVars.features.vehicle.aircraft_mg.manual_aim) then
		GVars.features.vehicle.aircraft_mg.marker_size, _ = ImGui.SliderFloat(_T("VEH_MG_MARKER_SIZE"),
			GVars.features.vehicle.aircraft_mg.marker_size,
			1.0,
			10.0
		)

		ImGui.ColorEditVec4(_T("VEH_MG_MARKER_COL"), GVars.features.vehicle.aircraft_mg.marker_color)
	end
end)
