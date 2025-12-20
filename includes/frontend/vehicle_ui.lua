local selected_mine_name
local autopilot_labels

local default_cfg             = require("includes.data.config")
local Flares                  = require("includes.features.vehicle.flares").new(Self:GetVehicle())
local Flatbed                 = require("includes.features.vehicle.flatbed")
local autopilot_state_idx     = 0
local autopilot_index_changed = false
local flare_cb_clicked        = false
local turb_cb_clicked         = false


--#region cars
local vehicleTab = GUI:RegisterNewTab(eTabID.TAB_VEHICLE, "Cars")

---@type WindowRequest
local speedometerOptionsWindow

---@type WindowRequest
local nosOptionsWindow

---@type WindowRequest
local driftOptionsWindow

local function speedoOptions()
	local resolution = Game.GetScreenResolution()
	ImGui.Text(_T("VEH_SPEED_UNIT"))
	ImGui.Separator()
	GVars.features.speedometer.speed_unit, _ = ImGui.RadioButton("M/s", GVars.features.speedometer.speed_unit, 0)
	ImGui.SameLine()
	GVars.features.speedometer.speed_unit, _ = ImGui.RadioButton("Km/h", GVars.features.speedometer.speed_unit, 1)
	ImGui.SameLine()
	GVars.features.speedometer.speed_unit, _ = ImGui.RadioButton("Mi/h", GVars.features.speedometer.speed_unit, 2)

	ImGui.Spacing()
	ImGui.Text(_T("GENERIC_POSITION_LABEL"))
	ImGui.Separator()
	GVars.features.speedometer.pos.x, _ = ImGui.SliderFloat(
		_T("GENERIC_LEFT_RIGHT_LABEL"),
		GVars.features.speedometer.pos.x,
		0.0,
		resolution.x - (GVars.features.speedometer.radius * 2.2)
	)
	GVars.features.speedometer.pos.y, _ = ImGui.SliderFloat(
		_T("GENERIC_UP_DOWN_LABEL"),
		GVars.features.speedometer.pos.y, 0.0,
		resolution.y - (GVars.features.speedometer.radius * 2)
	)

	ImGui.Spacing()
	ImGui.Text(_T("GENERIC_COLORS_LABEL"))
	ImGui.Separator()
	GVars.features.speedometer.colors.circle, _ = ImGui.ColorEditU32(_T("VEH_SPEED_CIRCLE"),
		GVars.features.speedometer.colors.circle)
	GVars.features.speedometer.colors.circle_bg, _ = ImGui.ColorEditU32(_T("VEH_SPEED_BG"),
		GVars.features.speedometer.colors.circle_bg)
	GVars.features.speedometer.colors.text, _ = ImGui.ColorEditU32(_T("VEH_SPEED_TEXT"),
		GVars.features.speedometer.colors.text)
	GVars.features.speedometer.colors.markings, _ = ImGui.ColorEditU32(_T("VEH_SPEED_MARK"),
		GVars.features.speedometer.colors.markings)
	GVars.features.speedometer.colors.needle, _ = ImGui.ColorEditU32(_T("VEH_SPEED_NEEDLE"),
		GVars.features.speedometer.colors.needle)
	GVars.features.speedometer.colors.needle_base, _ = ImGui.ColorEditU32(_T("VEH_SPEED_NEEDLE_BASE"),
		GVars.features.speedometer.colors.needle_base)

	if GUI:Button(_T("GENERIC_RESET")) then
		GVars.features.speedometer.colors = default_cfg.features.speedometer.colors
	end
end

local function driftOptions()
	GVars.features.vehicle.drift.mode, _ = ImGui.Combo(_T("VEH_DRIFT_MODE"),
		GVars.features.vehicle.drift.mode,
		_F("%s\0%s\0%s\0", _T("VEH_DRIFT_MODE_STRONG"), _T("VEH_DRIFT_MODE_SLIPPERY"), _T("VEH_DRIFT_MODE_MIXED"))
	)

	GVars.features.vehicle.drift.power, _ = ImGui.SliderInt(_T("VEH_POWER_GAIN"),
		GVars.features.vehicle.drift.power,
		10,
		100
	)

	ImGui.BeginDisabled(GVars.features.vehicle.drift.mode == 1)
	GVars.features.vehicle.drift.intensity, _ = ImGui.SliderInt(_T("VEH_DRIFT_MODE_INTENSITY"),
		GVars.features.vehicle.drift.intensity,
		0,
		3
	)
	ImGui.EndDisabled()
	GUI:HelpMarker(_T("VEH_DRIFT_MODE_INTENSITY_TT"))

	GVars.features.vehicle.drift.smoke_fx.enabled = GUI:Checkbox(_T("VEH_DRIFT_SMOKE"),
		GVars.features.vehicle.drift.smoke_fx.enabled,
		{
			tooltip = _T("VEH_DRIFT_SMOKE_TT"),
			onClick = function()
				if (not GVars.features.vehicle.drift.smoke_fx.enabled) then
					ThreadManager:Run(function()
						Self:GetVehicle():RestoreTireSmoke()
					end)
				end
			end
		}
	)

	ImGui.ColorEditVec3(_T("VEH_DRIFT_SMOKE_COL"), GVars.features.vehicle.drift.smoke_fx.color)
end

local function nosOptions()
	GVars.features.vehicle.nos.power, _ = ImGui.SliderInt(_T("VEH_POWER_GAIN"), GVars.features.vehicle.nos.power, 10, 100)

	GVars.features.vehicle.nos.screen_effect, _ = GUI:Checkbox(_T("VEH_NOS_SCREEN_FX"),
		GVars.features.vehicle.nos.screen_effect
	)

	GVars.features.vehicle.nos.sound_effect, _ = GUI:Checkbox(_T("VEH_NOS_SOUND_FX"),
		GVars.features.vehicle.nos.sound_effect
	)

	GVars.features.vehicle.nos.can_damage_engine, _ = GUI:Checkbox(_T("VEH_NOS_DAMAGE_CB"),
		GVars.features.vehicle.nos.can_damage_engine,
		{ tooltip = _T("VEH_NOS_DAMAGE_TT") }
	)
end

local function ToggleSubwoofer(toggle)
	ThreadManager:Run(function()
		if (not Self:IsDriving()) then
			return
		end

		Self:GetVehicle():ToggleSubwoofer(toggle)
	end)
end

local function CloseDoors()
	ThreadManager:Run(function(s)
		s:sleep(100)
		Self:GetVehicle():CloseDoors()
	end)
end

local function RestoreExhaustPops()
	ThreadManager:Run(function()
		Self:GetVehicle():RestoreExhaustPops()
	end)
end

vehicleTab:AddBoolCommand("VEH_SPEEDOMETER",
	"features.speedometer.enabled", -- GVars index key
	nil,                         -- onEnable callback
	nil,                         -- onDisable callback
	nil,                         -- CommandMeta
	true,                        -- optional flag to decide whether to register a command with CommandExecutor or not
	true
)

vehicleTab:AddBoolCommand("VEH_ABS_LIGHTS",
	"features.vehicle.abs_lights",
	nil,
	nil,
	{ description = "VEH_ABS_LIGHTS_TT" },
	true,
	true
)

vehicleTab:AddBoolCommand("VEH_FAST_AF",
	"features.vehicle.fast_vehicles",
	nil,
	nil,
	{ description = "VEH_FAST_AF_TT" },
	true,
	true
)

vehicleTab:AddBoolCommand("VEH_NOS",
	"features.vehicle.nos.enabled",
	nil,
	nil,
	nil,
	true,
	true
)

vehicleTab:AddBoolCommand("VEH_NOS_PURGE",
	"features.vehicle.nos.purge",
	nil,
	nil,
	{ description = "VEH_NOS_PURGE_TT" },
	true,
	true
)

vehicleTab:AddBoolCommand("VEH_POPS_N_BANGS",
	"features.vehicle.burble_tune",
	nil,
	RestoreExhaustPops,
	{
		description = "VEH_POPS_N_BANGS_TT",
		alias = { "pops" }
	},
	true,
	true
)

vehicleTab:AddBoolCommand("VEH_DRIFT_MODE",
	"features.vehicle.drift.enabled",
	nil,
	nil,
	nil,
	true,
	true
)

vehicleTab:AddBoolCommand("VEH_SUBWOOFER",
	"features.vehicle.subwoofer",
	nil,
	ToggleSubwoofer(false),
	{ description = "VEH_SUBWOOFER_TT" },
	true,
	true
)

vehicleTab:AddBoolCommand("VEH_HIGH_BEAMS",
	"features.vehicle.horn_beams",
	nil,
	nil,
	{ description = "VEH_HIGH_BEAMS_TT" },
	true,
	true
)

vehicleTab:AddBoolCommand("VEH_AUTO_BRAKE_LIGHTS",
	"features.vehicle.auto_brake_lights",
	nil,
	nil,
	{ description = "VEH_AUTO_BRAKE_LIGHTS_TT" },
	true,
	true
)

vehicleTab:AddBoolCommand("VEH_STRONG_WINDOWS",
	"features.vehicle.unbreakable_windows",
	nil,
	function()
		ThreadManager:Run(function()
			local PV = Self:GetVehicle()
			if (not PV:IsValid()) then
				return
			end

			VEHICLE.SET_DONT_PROCESS_VEHICLE_GLASS(PV:GetHandle(), false)
		end)
	end,
	{ description = "VEH_STRONG_WINDOWS_TT" },
	true,
	true
)

vehicleTab:AddBoolCommand("VEH_STRONG_CRASH",
	"features.vehicle.strong_crash",
	nil,
	function()
		local PV = Self:GetVehicle()
		PV:RestorePatch(PV.MemoryPatches.DeformMult)
	end,
	{ description = "VEH_STRONG_CRASH_TT" },
	true,
	true
)

vehicleTab:AddBoolCommand("VEH_RGB_LIGHTS",
	"features.vehicle.rgb_lights.enabled",
	nil,
	function()
		ThreadManager:Run(function()
			Self:GetVehicle():RestoreHeadlights()
		end)
	end,
	{ description = "VEH_RGB_LIGHTS_TT" },
	true,
	true
)

vehicleTab:AddBoolCommand("VEH_FLAPPY_DOORS",
	"features.vehicle.flappy_doors",
	nil,
	CloseDoors,
	{ description = "VEH_FLAPPY_DOORS_TT" },
	true,
	true
)

vehicleTab:AddBoolCommand("VEH_AUTO_LOCK",
	"features.vehicle.auto_lock_doors",
	nil,
	function()
		Self:GetVehicle():ResetGenericToggleable("autolockdoors")
	end,
	{ description = "VEH_AUTO_LOCK_TT" },
	true,
	true
)

vehicleTab:AddBoolCommand("VEH_LAUNCH_CTRL",
	"features.vehicle.launch_control",
	nil,
	nil,
	{ description = "VEH_LAUNCH_CTRL_TT" },
	true,
	true
)

vehicleTab:AddBoolCommand("VEH_IV_EXIT",
	"features.vehicle.iv_exit",
	nil,
	function()
		ThreadManager:Run(function()
			Self:SetConfigFlag(Enums.ePedConfigFlags.LeaveEngineOnWhenExitingVehicles, false)
			if (not GVars.features.vehicle.no_wheel_recenter) then
				Backend:RemoveDisabledControl(75)
			end
		end)
	end,
	{ description = "VEH_IV_EXIT_TT" },
	true,
	true
)

vehicleTab:AddBoolCommand("VEH_KEEP_WHEELS_TURNED",
	"features.vehicle.no_wheel_recenter",
	nil,
	nil,
	{ description = "VEH_KEEP_WHEELS_TURNED_TT" },
	true,
	true
)

vehicleTab:AddBoolCommand("VEH_MINES",
	"features.vehicle.mines.enabled",
	nil,
	nil,
	{ description = "VEH_MINES_TT" },
	true,
	true
)

speedometerOptionsWindow = {
	m_label = "##speedometerOptionsWindow",
	m_callback = function()
		GUI:QuickConfigWindow("Speedometer Options", speedoOptions, function()
			GUI:SetRequestedWindowDraw("##speedometerOptionsWindow", false)
		end)
	end,
	m_flags = ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.AlwaysAutoResize,
	m_should_draw = false,
}

driftOptionsWindow = {
	m_label = "##driftOptionsWindow",
	m_callback = function()
		GUI:QuickConfigWindow("Drift Options", driftOptions, function()
			GUI:SetRequestedWindowDraw("##driftOptionsWindow", false)
		end)
	end,
	m_flags = ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.AlwaysAutoResize,
	m_should_draw = false,
}

nosOptionsWindow = {
	m_label = "##nosOptionsWindow",
	m_callback = function()
		GUI:QuickConfigWindow("NOS Options", nosOptions, function()
			GUI:SetRequestedWindowDraw("##nosOptionsWindow", false)
		end)
	end,
	m_flags = ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.AlwaysAutoResize,
	m_should_draw = false,
}

GUI:RequestWindow(speedometerOptionsWindow)
GUI:RequestWindow(driftOptionsWindow)
GUI:RequestWindow(nosOptionsWindow)

vehicleTab:RegisterGUI(function()
	vehicleTab:GetGridRenderer():Draw()

	ImGui.Spacing()
	ImGui.SeparatorText("Settings")

	GVars.features.vehicle.performance_only, _ = GUI:Checkbox("Performance Cars Only",
		GVars.features.vehicle.performance_only,
		{ tooltip = "Limits some features to performance cars only (Launch Control, Pops & Bangs, etc.)" }
	)

	if (GVars.features.vehicle.rgb_lights.enabled) then
		GVars.features.vehicle.rgb_lights.speed, _ = ImGui.SliderInt("RGB Lights Speed",
			GVars.features.vehicle.rgb_lights.speed,
			1,
			5
		)
	end

	if (GVars.features.vehicle.mines.enabled) then
		if (ImGui.BeginCombo("Vehicle Mine Type", selected_mine_name or "Unselected")) then
			for _, pair in pairs(Self:GetVehicle().mines) do
				local selected = GVars.features.vehicle.mines.selected_type_hash == pair.second
				if (ImGui.Selectable(pair.first, selected)) then
					GVars.features.vehicle.mines.selected_type_hash = pair.second
					selected_mine_name = pair.first
				end
			end

			ImGui.EndCombo()
		end
	end

	if (GVars.features.speedometer.enabled) then
		if (GUI:Button("Speedometer##settings")) then
			speedometerOptionsWindow.m_should_draw = true
		end
		ImGui.SameLine()
	end

	if (GVars.features.vehicle.drift.enabled) then
		if (GUI:Button("Drift Mode##settings")) then
			driftOptionsWindow.m_should_draw = true
		end
		ImGui.SameLine()
	end

	if (GVars.features.vehicle.nos.enabled) then
		if (GUI:Button("NOS##settings")) then
			nosOptionsWindow.m_should_draw = true
		end
	end
end)
--#endregion


--#region planes
Flares:Init()

GUI:RegisterNewTab(eTabID.TAB_VEHICLE, "Planes", function()
	GVars.features.vehicle.fast_jets, _ = GUI:Checkbox(_T("VEH_FAST_JETS"),
		GVars.features.vehicle.fast_jets,
		{ tooltip = _T("VEH_FAST_JETS_TT") }
	)

	GVars.features.vehicle.no_jet_stall, _ = GUI:Checkbox(_T("VEH_NO_JET_STALL"),
		GVars.features.vehicle.no_jet_stall,
		{ tooltip = _T("VEH_NO_JET_STALL_TT") }
	)

	GVars.features.vehicle.no_turbulence, turb_cb_clicked = GUI:Checkbox(_T("VEH_NO_TURBULENCE"),
		GVars.features.vehicle.no_turbulence
	)

	if (turb_cb_clicked and not GVars.features.vehicle.no_turbulence) then
		local PV = Self:GetVehicle()
		PV:RestorePatch(PV.MemoryPatches.Turbulence)
		PV:RestorePatch(PV.MemoryPatches.WindMult)
	end

	GVars.features.vehicle.flares, flare_cb_clicked = GUI:Checkbox(_T("VEH_FLARES"),
		GVars.features.vehicle.flares,
		{ tooltip = _T("VEH_FLARES_TT") }
	)

	if (flare_cb_clicked) then
		if (GVars.features.vehicle.flares) then
			Flares:OnEnable()
		else
			Flares:OnDisable()
		end
	end

	GVars.features.vehicle.aircraft_mg.triggerbot, _ = GUI:Checkbox(_T("VEH_MG_TRIGGERBOT"),
		GVars.features.vehicle.aircraft_mg.triggerbot,
		{ tooltip = _T("VEH_MG_TRIGGERBOT_TT") }
	)

	if (GVars.features.vehicle.aircraft_mg.triggerbot) then
		GVars.features.vehicle.aircraft_mg.enemies_only, _ = GUI:Checkbox(_T("VEH_MG_TRIGGERBOT_ENEMY"),
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

	GVars.features.vehicle.aircraft_mg.manual_aim, _ = GUI:Checkbox(_T("VEH_MG_MANUAL_AIM"),
		GVars.features.vehicle.aircraft_mg.manual_aim,
		{ tooltip = _T("VEH_MG_MANUAL_AIM_TT") }
	)

	if (GVars.features.vehicle.aircraft_mg.manual_aim) then
		GVars.features.vehicle.aircraft_mg.marker_size, _ = ImGui.SliderFloat(_T("VEH_MG_MARKER_SIZE"),
			GVars.features.vehicle.aircraft_mg.marker_size,
			1.0,
			10.0
		)

		ImGui.ColorEditVec4(_T("VEH_MG_MARKER_COL"), GVars.features.vehicle.aircraft_mg.marker_color)
	end

	ImGui.SeparatorText(_T("VEH_AUTOPILOT"))
	ImGui.BeginDisabled(not Self:GetVehicle().m_autopilot.eligible)
	if (not autopilot_labels) then
		autopilot_labels = {
			_T("GENERIC_NONE"),
			_T("GENERIC_WAYPOINT"),
			_T("GENERIC_OBJECTIVE"),
			_T("GENERIC_RANDOM")
		}
	else
		autopilot_state_idx, autopilot_index_changed = ImGui.Combo(
			"##autopilotdest",
			autopilot_state_idx,
			autopilot_labels,
			4
		)

		if (autopilot_index_changed) then
			ThreadManager:Run(function()
				Self:GetVehicle():UpdateAutopilotState(autopilot_state_idx)
			end)
		end

		autopilot_state_idx = Self:GetVehicle().m_autopilot.state
	end
	ImGui.EndDisabled()
end)
--#endregion

--#region Flatbed
local function FlatbedUI()
	if (not GVars.features.flatbed.enabled) then
		return
	end

	local window_size_x, _ = ImGui.GetContentRegionAvail()

	if (not Self:GetVehicle().m_is_flatbed) then
		ImGui.TextWrapped(_T("FTLBD_GET_IN_MSG"))

		if GUI:Button(_T("GENERIC_SPAWN")) then
			Flatbed:Spawn()
		end

		return
	end
	ImGui.Dummy(1, 10)
	ImGui.BulletText(Flatbed.displayText)
	ImGui.Dummy(1, 10)

	GVars.features.flatbed.show_towing_position, _ = GUI:Checkbox(_T("FLTBD_SHOW_TOWPOS_CB"),
		GVars.features.flatbed.show_towing_position
	)
	GUI:HelpMarker(_T("FLTBD_SHOW_TOWPOS_TT"))

	GVars.features.flatbed.show_esp, _ = GUI:Checkbox(_T("FLTBD_SHOW_TOWBOX_CB"), GVars.features.flatbed.show_esp)
	GUI:HelpMarker(_T("FLTBD_SHOW_TOWBOX_TT"))

	GVars.features.flatbed.tow_everything, _ = GUI:Checkbox(_T("FLTBD_TOW_ALL_CB"),
		GVars.features.flatbed.tow_everything
	)
	GUI:HelpMarker(_T("FLTBD_TOW_ALL_TT"))

	ImGui.Dummy(1, 10)
	ImGui.Dummy((window_size_x / 2) - 60, 1)
	ImGui.SameLine()

	if GUI:Button(not Flatbed.m_towed_vehicle and _T("FLTBD_TOW_BTN") or _T("GENERIC_DETACH"), { size = vec2:new(80, 40) }) then
		ThreadManager:Run(function()
			Flatbed:OnKeyPress()
		end)
	end

	if (Flatbed.m_towed_vehicle) then
		ImGui.Dummy(1, 5)
		ImGui.SeparatorText(_T("FLTBD_ADJUST_POS_TXT"))
		GUI:Tooltip(_T("FLTBD_ADJUST_POS_TT"))
		ImGui.SetWindowFontScale(0.8)
		ImGui.BulletText(_T("FLTBD_FAST_ADJUST_TXT"))
		ImGui.SetWindowFontScale(1.0)
		ImGui.Dummy((window_size_x / 2) - 40, 1)
		ImGui.SameLine()

		ImGui.PushButtonRepeat(true)
		if ImGui.ArrowButton("##Up", 2) then
			Flatbed:MoveAttachment(0.0, 0.0, 0.01)
		end

		ImGui.Dummy((window_size_x / 2) - 80, 1)
		ImGui.SameLine()
		if ImGui.ArrowButton("##Left", 0) then
			Flatbed:MoveAttachment(0.0, 0.01, 0.0)
		end

		ImGui.SameLine()
		ImGui.Dummy(1, 1)
		ImGui.SameLine()
		if ImGui.ArrowButton("##Right", 1) then
			Flatbed:MoveAttachment(0.0, -0.01, 0.0)
		end

		ImGui.Dummy((window_size_x / 2) - 40, 1)
		ImGui.SameLine()
		if ImGui.ArrowButton("##Down", 3) then
			Flatbed:MoveAttachment(0.0, 0.0, -0.01)
		end
		ImGui.PopButtonRepeat()
	end
end

local flatbed_tab = GUI:RegisterNewTab(eTabID.TAB_VEHICLE, "Flatbed")
flatbed_tab:AddLoopedCommand("FLTBD_MAIN_CB",
	"features.flatbed.enabled",
	function()
		Flatbed:Main()
	end,
	function()
		Flatbed:Reset()
	end,
	nil,
	true,
	true
)

flatbed_tab:RegisterGUI(FlatbedUI)
--#endregion
