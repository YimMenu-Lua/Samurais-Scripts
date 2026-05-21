-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Refs                 = require("includes.data.refs")
local default_cfg          = require("includes.data.config")
local driftMG              = require("includes.features.vehicle.drift_minigame")
local customPaintsUI       = require("includes.frontend.vehicle.custom_paints_ui")
local engine_swap_index    = 1
local vehicleTab           = GUI:RegisterNewTab(Enums.eTabID.TAB_VEHICLE, "SUBTAB_CARS", nil, nil, true)
local optionPopup          = {
	flags       = ImGuiWindowFlags.NoResize | ImGuiWindowFlags.AlwaysAutoResize,
	label       = "##optionsPopup",
	should_draw = false,
	---@type function?
	callback    = nil
}
DriftMinigame              = LocalPlayer:GetVehicle():AddFeature(driftMG)

local vehicleRadioStations = { { station = "OFF", name = "Off" } }
for _, v in ipairs(Audio.RadioStations) do
	local station = v.station
	if (station:startswith("HIDDEN") or station == "RADIO_30_DLC_HEI4_MIX1_REVERB") then
		goto continue
	end

	table.insert(vehicleRadioStations, v)
	::continue::
end

local function speedoOptions()
	local resolution = Game.GetScreenResolution()
	local cfg        = GVars.features.speedometer
	ImGui.Text(_T("VEH_SPEED_UNIT"))
	ImGui.Separator()

	cfg.speed_unit = ImGui.RadioButton("M/s", cfg.speed_unit, 0)
	ImGui.SameLine()
	cfg.speed_unit = ImGui.RadioButton("Km/h", cfg.speed_unit, 1)
	ImGui.SameLine()
	cfg.speed_unit = ImGui.RadioButton("Mi/h", cfg.speed_unit, 2)

	ImGui.Spacing()
	ImGui.Text(_T("GENERIC_POSITION_LABEL"))
	ImGui.Separator()

	cfg.pos.x = ImGui.SliderFloat(_T("GENERIC_LEFT_RIGHT_LABEL"), cfg.pos.x, 0.0, resolution.x - (cfg.radius * 2.2))
	cfg.pos.y = ImGui.SliderFloat(_T("GENERIC_UP_DOWN_LABEL"), cfg.pos.y, 0.0, resolution.y - (cfg.radius * 2))

	ImGui.Spacing()
	ImGui.Text(_T("GENERIC_COLORS_LABEL"))
	ImGui.Separator()

	cfg.colors.circle      = ImGui.ColorEditU32(_T("VEH_SPEED_CIRCLE"), cfg.colors.circle)
	cfg.colors.circle_bg   = ImGui.ColorEditU32(_T("VEH_SPEED_BG"), cfg.colors.circle_bg)
	cfg.colors.text        = ImGui.ColorEditU32(_T("VEH_SPEED_TEXT"), cfg.colors.text)
	cfg.colors.markings    = ImGui.ColorEditU32(_T("VEH_SPEED_MARK"), cfg.colors.markings)
	cfg.colors.needle      = ImGui.ColorEditU32(_T("VEH_SPEED_NEEDLE"), cfg.colors.needle)
	cfg.colors.needle_base = ImGui.ColorEditU32(_T("VEH_SPEED_NEEDLE_BASE"), cfg.colors.needle_base)

	if (GUI:Button(_T("GENERIC_RESET"))) then
		cfg.colors = table.copy(default_cfg.features.speedometer.colors)
	end
end

local function driftOptions()
	local cfg = GVars.features.vehicle.drift
	cfg.mode  = ImGui.Combo(_T("VEH_DRIFT_MODE"), cfg.mode, { _T("VEH_DRIFT_MODE_STRONG"), _T("VEH_DRIFT_MODE_SLIPPERY"), _T("VEH_DRIFT_MODE_MIXED") }, 3)
	cfg.power = ImGui.SliderInt(_T("VEH_POWER_GAIN"), cfg.power, 10, 100)

	ImGui.BeginDisabled(cfg.mode == 1)
	cfg.intensity = ImGui.SliderInt(_T("VEH_DRIFT_MODE_INTENSITY"), cfg.intensity, 0, 3)
	ImGui.EndDisabled()
	GUI:HelpMarker(_T("VEH_DRIFT_MODE_INTENSITY_TT"))

	cfg.smoke_fx.enabled = GUI:CustomToggle(_T("VEH_DRIFT_SMOKE"), cfg.smoke_fx.enabled,
		{
			tooltip = _T("VEH_DRIFT_SMOKE_TT"),
			onClick = function()
				if (not GVars.features.vehicle.drift.smoke_fx.enabled) then
					ThreadManager:Run(function()
						LocalPlayer:GetVehicle():RestoreTireSmoke()
					end)
				end
			end
		}
	)

	if (cfg.smoke_fx.enabled) then
		ImGui.ColorEditVec3(_T("VEH_DRIFT_SMOKE_COL"), cfg.smoke_fx.color)
	end
end

local function driftMinigameOptions()
	local cfg = GVars.features.vehicle.drift_minigame
	cfg.score_sound = GUI:CustomToggle(_T("VEH_DRIFT_MINIGAME_SOUND_OPT"), cfg.score_sound,
		{ tooltip = _T("VEH_DRIFT_MINIGAME_SOUND_OPT_TT") }
	)

	ImGui.Spacing()
	ImGui.BulletText(_T("VEH_DRIFT_MINIGAME_PB_LABEL", string.formatint(cfg.player_best)))
end

local function nosOptions()
	local cfg             = GVars.features.vehicle.nos
	cfg.power             = ImGui.SliderInt(_T("VEH_POWER_GAIN"), cfg.power, 10, 100)
	cfg.screen_effect     = GUI:CustomToggle(_T("VEH_NOS_SCREEN_FX"), cfg.screen_effect)
	cfg.sound_effect      = GUI:CustomToggle(_T("VEH_NOS_SOUND_FX"), cfg.sound_effect)
	cfg.can_damage_engine = GUI:CustomToggle(_T("VEH_NOS_DAMAGE_CB"), cfg.can_damage_engine, { tooltip = _T("VEH_NOS_DAMAGE_TT") })
end

local function minesOptions()
	local cfg = GVars.features.vehicle.mines
	if (ImGui.BeginCombo(_T("GENERIC_TYPE"), cfg.name or _T("GENERIC_NONE"))) then
		for _, pair in pairs(LocalPlayer:GetVehicle().mines) do
			local selected = cfg.selected_type_hash == pair.second
			if (ImGui.Selectable(pair.first, selected)) then
				cfg.selected_type_hash = pair.second
				cfg.name               = pair.first
			end
		end

		ImGui.EndCombo()
	end
end

local function defaultStationOptions()
	ImGui.Spacing()
	local cfg = GVars.features.vehicle.default_station
	if (ImGui.BeginCombo("##defaultRadio", cfg.display_name)) then
		for _, v in ipairs(vehicleRadioStations) do
			local station  = v.station
			local name     = v.name
			local selected = cfg.station_name == station
			if (ImGui.Selectable(name, selected)) then
				cfg.station_name = station
				cfg.display_name = name
				ThreadManager:Run(function()
					if (not LocalPlayer:IsDriving()) then return end
					LocalPlayer:GetVehicle():SetRadioStation(station)
				end)
			end
		end

		ImGui.EndCombo()
	end
end

local function gearboxOptions()
	ImGui.Spacing()
	local cfg = GVars.features.vehicle.manual_gearbox
	cfg.mode  = ImGui.Combo("##gboxManual", cfg.mode, { _T("VEH_GEARBOX_MAN_WCLUTCH"), _T("VEH_GEARBOX_SEQUENTIAL") }, 2)
end

local function popsOptions()
	local cfg = GVars.features.vehicle
	cfg.bangs_rpm_min = ImGui.SliderFloat("Pops & Bangs RPM Min",
		cfg.bangs_rpm_min,
		2000.0,
		cfg.bangs_rpm_max - 1000.0,
		"%.0f RPM", cfg.bangs_rpm_min
	)

	cfg.bangs_rpm_max = ImGui.SliderFloat("Pops & Bangs RPM Max",
		cfg.bangs_rpm_max,
		cfg.bangs_rpm_min + 1000.0,
		9000.0,
		"%.0f RPM", cfg.bangs_rpm_max
	)
end

local function ToggleSubwoofer(toggle)
	ThreadManager:Run(function()
		if (not LocalPlayer:IsDriving()) then
			return
		end

		LocalPlayer:GetVehicle():ToggleSubwoofer(toggle)
	end)
end

local function CloseDoors()
	ThreadManager:Run(function(s)
		s:sleep(100)
		LocalPlayer:GetVehicle():CloseDoors()
	end)
end

local function RestoreExhaustPops()
	ThreadManager:Run(function()
		LocalPlayer:GetVehicle():RestoreExhaustPops()
	end)
end

vehicleTab:AddBoolCommand("VEH_SPEEDOMETER",
	{
		gvar_key        = "features.speedometer.enabled",
		translate_label = true,
		options_data    = {
			condition = function()
				return GVars.features.speedometer.enabled
			end,
			callback = function()
				optionPopup.callback    = speedoOptions
				optionPopup.label       = _T("VEH_SPEEDOMETER")
				optionPopup.should_draw = true
			end
		}
	}
)
vehicleTab:AddBoolCommand("VEH_ABS_LIGHTS",
	{
		gvar_key        = "features.vehicle.abs_lights",
		meta            = { description = "VEH_ABS_LIGHTS_TT" },
		translate_label = true
	}
)
vehicleTab:AddBoolCommand("VEH_FAST_AF",
	{
		gvar_key        = "features.vehicle.fast_vehicles",
		meta            = { description = "VEH_FAST_AF_TT" },
		translate_label = true
	}
)
vehicleTab:AddBoolCommand("VEH_NOS",
	{
		gvar_key        = "features.vehicle.nos.enabled",
		translate_label = true,
		options_data    = {
			condition = function()
				return GVars.features.vehicle.nos.enabled
			end,
			callback = function()
				optionPopup.callback    = nosOptions
				optionPopup.label       = _T("VEH_NOS")
				optionPopup.should_draw = true
			end
		}
	}
)
vehicleTab:AddBoolCommand("VEH_NOS_PURGE",
	{
		gvar_key        = "features.vehicle.nos.purge",
		meta            = { description = "VEH_NOS_PURGE_TT" },
		translate_label = true
	}
)
vehicleTab:AddBoolCommand("VEH_POPS_N_BANGS",
	{
		gvar_key         = "features.vehicle.burble_tune",
		meta             = { description = "VEH_POPS_N_BANGS_TT", alias = { "vehpops" }, isTranslatorLabel = true },
		translate_label  = true,
		on_disable       = RestoreExhaustPops,
		register_command = true,
		options_data     = {
			condition = function()
				return GVars.features.vehicle.burble_tune
			end,
			callback = function()
				optionPopup.callback    = popsOptions
				optionPopup.label       = _T("VEH_POPS_N_BANGS")
				optionPopup.should_draw = true
			end
		}
	}
)
vehicleTab:AddBoolCommand("VEH_DRIFT_MODE",
	{
		gvar_key        = "features.vehicle.drift.enabled",
		translate_label = true,
		options_data    = {
			condition = function()
				return GVars.features.vehicle.drift.enabled
			end,
			callback = function()
				optionPopup.callback    = driftOptions
				optionPopup.label       = _T("VEH_DRIFT_MODE")
				optionPopup.should_draw = true
			end
		}
	}
)
vehicleTab:AddLoopedCommand("VEH_DRIFT_MINIGAME",
	{
		gvar_key        = "features.vehicle.drift_minigame.enabled",
		meta            = { description = "VEH_DRIFT_MINIGAME_TT" },
		translate_label = true,
		callback        = function() DriftMinigame:OnTick() end,
		options_data    = {
			condition = function()
				return GVars.features.vehicle.drift_minigame.enabled
			end,
			callback = function()
				optionPopup.callback    = driftMinigameOptions
				optionPopup.label       = _T("VEH_DRIFT_MINIGAME")
				optionPopup.should_draw = true
			end
		}
	}
)
vehicleTab:AddBoolCommand("VEH_SUBWOOFER",
	{
		gvar_key        = "features.vehicle.subwoofer",
		meta            = { description = "VEH_SUBWOOFER_TT" },
		translate_label = true,
		on_disable      = function() ToggleSubwoofer(false) end,
	}
)
vehicleTab:AddBoolCommand("VEH_HIGH_BEAMS",
	{
		gvar_key        = "features.vehicle.horn_beams",
		meta            = { description = "VEH_HIGH_BEAMS_TT" },
		translate_label = true,
	}
)
vehicleTab:AddBoolCommand("VEH_AUTO_BRAKE_LIGHTS",
	{
		gvar_key        = "features.vehicle.auto_brake_lights",
		meta            = { description = "VEH_AUTO_BRAKE_LIGHTS_TT" },
		translate_label = true,
	}
)
vehicleTab:AddBoolCommand("VEH_STRONG_WINDOWS",
	{
		gvar_key        = "features.vehicle.unbreakable_windows",
		meta            = { description = "VEH_STRONG_WINDOWS_TT" },
		translate_label = true,
		on_disable      = function()
			ThreadManager:Run(function()
				local PV = LocalPlayer:GetVehicle()
				if (not PV:IsValid()) then return end
				VEHICLE.SET_DONT_PROCESS_VEHICLE_GLASS(PV:GetHandle(), false)
			end)
		end,
	}
)
vehicleTab:AddBoolCommand("VEH_STRONG_CRASH",
	{
		gvar_key        = "features.vehicle.strong_crash",
		meta            = { description = "VEH_STRONG_CRASH_TT" },
		translate_label = true,
		on_disable      = function()
			local PV = LocalPlayer:GetVehicle()
			PV:RestorePatch(PV.MemoryPatches.DeformMult)
		end,
	}
)
vehicleTab:AddBoolCommand("VEH_RGB_LIGHTS",
	{
		gvar_key        = "features.vehicle.rgb_lights.enabled",
		meta            = { description = "VEH_RGB_LIGHTS_TT" },
		translate_label = true,
		on_disable      = function()
			ThreadManager:Run(function()
				LocalPlayer:GetVehicle():RestoreHeadlights()
			end)
		end,
		options_data    = {
			condition = function()
				return GVars.features.vehicle.rgb_lights.enabled
			end,
			callback = function()
				optionPopup.label = _T("VEH_RGB_LIGHTS")
				optionPopup.callback = function()
					GVars.features.vehicle.rgb_lights.speed = ImGui.SliderInt("RGB Lights Speed",
						GVars.features.vehicle.rgb_lights.speed,
						1,
						5
					)
				end
				optionPopup.should_draw = true
			end
		}
	}
)
vehicleTab:AddBoolCommand("VEH_FLAPPY_DOORS",
	{
		gvar_key        = "features.vehicle.flappy_doors",
		meta            = { description = "VEH_FLAPPY_DOORS_TT" },
		translate_label = true,
		on_disable      = CloseDoors
	}
)
vehicleTab:AddBoolCommand("VEH_AUTO_LOCK",
	{
		gvar_key        = "features.vehicle.auto_lock_doors",
		meta            = { description = "VEH_AUTO_LOCK_TT" },
		translate_label = true,
		on_disable      = function()
			LocalPlayer:GetVehicle():ResetGenericToggleable("autolockdoors")
		end
	}
)
vehicleTab:AddBoolCommand("VEH_LAUNCH_CTRL",
	{
		gvar_key        = "features.vehicle.launch_control",
		meta            = { description = "VEH_LAUNCH_CTRL_TT" },
		translate_label = true,
		options_data    = {
			condition = function()
				return GVars.features.vehicle.launch_control
			end,
			callback = function()
				optionPopup.label       = _T("VEH_LAUNCH_CTRL_MODE")
				optionPopup.should_draw = true
				optionPopup.callback    = function()
					GVars.features.vehicle.launch_control_mode = ImGui.Combo("##launchCtrlMode",
						GVars.features.vehicle.launch_control_mode,
						_F("%s\0%s\0", _T("VEH_LAUNCH_CTRL_REALISTIC"), _T("VEH_LAUNCH_CTRL_RIDICULOUS"))
					)
				end
			end
		}
	}
)
vehicleTab:AddBoolCommand("VEH_IV_EXIT",
	{
		gvar_key        = "features.vehicle.iv_exit",
		meta            = { description = "VEH_IV_EXIT_TT" },
		translate_label = true,
		on_disable      = function()
			ThreadManager:Run(function()
				LocalPlayer:SetConfigFlag(Enums.ePedConfigFlags.LeaveEngineOnWhenExitingVehicles, false)
			end)
		end
	}
)
vehicleTab:AddBoolCommand("VEH_KEEP_WHEELS_TURNED",
	{
		gvar_key        = "features.vehicle.no_wheel_recenter",
		meta            = { description = "VEH_KEEP_WHEELS_TURNED_TT" },
		translate_label = true,
	}
)
vehicleTab:AddBoolCommand("VEH_MINES",
	{
		gvar_key        = "features.vehicle.mines.enabled",
		meta            = { description = "VEH_MINES_TT" },
		translate_label = true,
		options_data    = {
			condition = function()
				return GVars.features.vehicle.mines.enabled
			end,
			callback = function()
				optionPopup.callback    = minesOptions
				optionPopup.label       = _T("VEH_MINES")
				optionPopup.should_draw = true
			end
		}
	}
)
vehicleTab:AddBoolCommand("VEH_DEFAULT_RADIO",
	{
		gvar_key        = "features.vehicle.default_station.enabled",
		meta            = { description = "VEH_DEFAULT_RADIO_TT" },
		translate_label = true,
		options_data    = {
			condition = function()
				return GVars.features.vehicle.default_station.enabled
			end,
			callback = function()
				optionPopup.callback    = defaultStationOptions
				optionPopup.label       = _T("VEH_DEFAULT_RADIO")
				optionPopup.should_draw = true
			end
		}
	}
)
vehicleTab:AddBoolCommand("VEH_MANUAL_GEARBOX",
	{
		gvar_key        = "features.vehicle.manual_gearbox.enabled",
		meta            = { description = "VEH_MANUAL_GEARBOX_TT" },
		translate_label = true,
		on_enable       = function()
			local PV = LocalPlayer:GetVehicle()
			if (not PV:IsValid()) then return end
			PV.m_manual_gearbox:OnNewVehicle()
		end,
		on_disable      = function()
			local PV = LocalPlayer:GetVehicle()
			if (not PV:IsValid()) then return end
			PV.m_manual_gearbox:Reset()
		end,
		options_data    = {
			condition = function()
				return GVars.features.vehicle.manual_gearbox.enabled
			end,
			callback = function()
				optionPopup.callback    = gearboxOptions
				optionPopup.label       = _T("VEH_MANUAL_GEARBOX_TYPE")
				optionPopup.should_draw = true
			end
		}
	}
)

vehicleTab:RegisterGUI(function()
	vehicleTab:GetGridRenderer():Draw()

	ImGui.Spacing()
	ImGui.SeparatorText("Settings")

	GVars.features.vehicle.performance_only, _ = GUI:CustomToggle("Performance Cars Only",
		GVars.features.vehicle.performance_only,
		{ tooltip = "Limits some features to performance cars only (Launch Control, Pops & Bangs, etc.)" }
	)

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

--#region Handling Editor
vehicleTab:RegisterSubtab("SUBTAB_HANDLING_EDITOR", require("includes.frontend.vehicle.handling_editor_ui"), nil, true)
--#endregion

--#region stancer
vehicleTab:RegisterSubtab("SUBTAB_STANCER", require("includes.frontend.vehicle.stancer_ui"), nil, true)
--#endregion

local swap_btn_size = vec2:new(140, 35)
local swap_wnd_height = 260
vehicleTab:RegisterSubtab("VEH_ENGINE_SWAP", function()
	if (self.get_veh() == 0) then
		ImGui.Text(_T("GENERIC_NOT_IN_VEH"))
		return
	end

	if (not LocalPlayer:GetVehicle().m_engine_swap_compatible) then
		ImGui.Text(_T("GENERIC_CARS_ONLY"))
		return
	end

	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##engines_c", ImGui.GetContentRegionAvail() - 180, swap_wnd_height)
	if (ImGui.BeginListBox("##engines", ImGui.GetContentRegionAvail() - 1, -1)) then
		for i, v in ipairs(Refs.engineSwaps) do
			local is_selected = engine_swap_index == i
			if (ImGui.Selectable(v.name, is_selected)) then
				engine_swap_index = i
			end
		end
		ImGui.EndListBox()
	end
	ImGui.EndChild()

	ImGui.SameLine()
	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##engine_s_btns", 0, swap_wnd_height)
	if (GUI:Button(_T("GENERIC_CONFIRM"), { size = swap_btn_size })) then
		ThreadManager:Run(function()
			local PV = LocalPlayer:GetVehicle()
			if (PV:GetModelHash() == _J(Refs.engineSwaps[engine_swap_index].audioname)) then
				Notifier:ShowError(_T("VEH_ENGINE_SWAP"), _T("VEH_ENGINE_SWAP_SAME_ERR"), false, 5)
				return
			end
			PV:ResetGenericToggleable("engine_swap")
			sleep(20)

			PV:AddGenericToggleable("engine_swap", function()
				AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(PV:GetHandle(),
					Refs.engineSwaps[engine_swap_index].audioname
				)

				PV:AddMemoryPatch({
					name = PV.MemoryPatches.Acceleration,
					onEnable = function(patch)
						local cvehicle = PV:Resolve()
						if (not cvehicle) then return end

						local fAccelMult = cvehicle.m_handling_data.m_acceleration
						patch.m_state    = {
							ptr = fAccelMult,
							default_value = fAccelMult:get_float()
						}

						if (fAccelMult:is_valid()) then
							fAccelMult:set_float(Refs.engineSwaps[engine_swap_index].acc_mult)
						end
					end,
					onDisable = function(patch)
						if (not patch.m_state or patch.m_state.default_value == nil) then
							return
						end

						local ptr = patch.m_state.ptr
						if (not ptr or ptr:is_null()) then return end
						ptr:set_float(patch.m_state.default_value)
					end
				}, true)
				sleep(150)
				if (PV:IsRadioOn()) then
					AUDIO.SET_VEH_RADIO_STATION(PV:GetHandle(), "OFF")
				end
			end, function()
				local PV = LocalPlayer:GetVehicle()
				PV:RestorePatch(PV.MemoryPatches.Acceleration)
				AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(PV:GetHandle(),
					Game.GetVehicleDisplayName(PV:GetModelHash())
				)
			end)
		end)
	end

	if (GUI:Button(_T("GENERIC_RESET"), { size = swap_btn_size })) then
		ThreadManager:Run(function()
			local PV = LocalPlayer:GetVehicle()
			PV:ResetGenericToggleable("engine_swap")
		end)
	end
	ImGui.EndChild()

	ImGui.Spacing()
	ImGui.SetWindowFontScale(0.9)
	ImGui.BulletText(Refs.engineSwaps[engine_swap_index].tt)
	ImGui.SetWindowFontScale(1)
end, nil, true)

vehicleTab:RegisterSubtab("SUBTAB_PAINTS", function()
	if (LocalPlayer:GetVehicle():GetHandle() == 0) then
		ImGui.Text(_T("GENERIC_NOT_IN_VEH"))
		return
	end

	customPaintsUI()
end, nil, true)

require("includes.frontend.vehicle.flatbed_ui")
require("includes.frontend.vehicle.aircraft_ui")
