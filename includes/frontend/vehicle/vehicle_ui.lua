local selected_mine_name
local Refs              = require("includes.data.refs")
local default_cfg       = require("includes.data.config")
local customPaintsUI    = require("includes.frontend.vehicle.custom_paints_ui")
local engine_swap_index = 1

local vehicleTab        = GUI:RegisterNewTab(Enums.eTabID.TAB_VEHICLE, "SUBTAB_CARS", nil, nil, true)

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

	GVars.features.vehicle.bangs_rpm_min, _ = ImGui.SliderFloat("Pops & Bangs RPM Min",
		GVars.features.vehicle.bangs_rpm,
		2000.0,
		GVars.features.vehicle.bangs_rpm_max - 1000.0,
		"%.0f RPM", GVars.features.vehicle.bangs_rpm_min
	)

	GVars.features.vehicle.bangs_rpm_max, _ = ImGui.SliderFloat("Pops & Bangs RPM Max",
		GVars.features.vehicle.bangs_rpm_max,
		GVars.features.vehicle.bangs_rpm_min + 1000.0,
		9000.0,
		"%.0f RPM", GVars.features.vehicle.bangs_rpm_max
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

local swap_btn_size = vec2:new(140, 35)
local swap_wnd_height = 260
vehicleTab:RegisterSubtab("VEH_ENGINE_SWAP", function()
	if (Self:GetVehicle():GetHandle() == 0) then
		ImGui.Text(_T("GENERIC_NOT_IN_VEH"))
		return
	end

	if (not Self:GetVehicle().m_engine_swap_compatible) then
		ImGui.Text(_T("VEH_ENGINE_SWAP_INCOMPATIBE"))
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
			local PV = Self:GetVehicle()
			if (PV:GetModelHash() == joaat(Refs.engineSwaps[engine_swap_index].audioname)) then
				Toast:ShowError(_T("VEH_ENGINE_SWAP"), _T("VEH_ENGINE_SWAP_SAME_ERR"), false, 5)
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
						if (not cvehicle) then
							error("Handling data is null!")
						end

						local fAccelMult = cvehicle.m_acceleration
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
						if (not ptr or ptr:is_null()) then
							error("pointer is null")
						end

						ptr:set_float(patch.m_state.default_value)
					end
				}, true)
				sleep(150)
				if (PV:IsRadioOn()) then
					AUDIO.SET_VEH_RADIO_STATION(PV:GetHandle(), "OFF")
				end
			end, function()
				local PV = Self:GetVehicle()
				PV:RestorePatch(PV.MemoryPatches.Acceleration)
				AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(PV:GetHandle(),
					vehicles.get_vehicle_display_name(PV:GetModelHash())
				)
			end)
		end)
	end

	if (GUI:Button(_T("GENERIC_RESET"), { size = swap_btn_size })) then
		ThreadManager:Run(function()
			local PV = Self:GetVehicle()
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
	if (Self:GetVehicle():GetHandle() == 0) then
		ImGui.Text(_T("GENERIC_NOT_IN_VEH"))
		return
	end

	customPaintsUI()
end, nil, true)

require("includes.frontend.vehicle.flatbed_ui")
require("includes.frontend.vehicle.aircraft_ui")
