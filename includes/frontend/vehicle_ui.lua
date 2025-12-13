local default_cfg = require("includes.data.config")

---@type WindowRequest
local speedometerOptionsWindow

---@type WindowRequest
local nosOptionsWindow

---@type WindowRequest
local driftOptionsWindow

---@param label string
---@param callback GuiCallback
---@param onClose function
local function QuickConfigWindow(label, callback, onClose)
	local size = vec2:new(ImGui.GetWindowSize())
	local _, center = GUI:GetNewWindowSizeAndCenterPos(0.5, 0.5, size)
	ImGui.SetWindowPos(center.x, center.y,
		ImGuiCond.Once | ImGuiWindowFlags.NoSavedSettings | ImGuiWindowFlags.NoCollapse)

	ImGui.SeparatorText(label)
	if (GUI:Button("Close")) then
		onClose()
		return
	end

	if (type(callback) ~= "function") then
		return
	end

	ImGui.Separator()
	ImGui.Dummy(0, 10)
	callback()
end

--#region cars
local function speedoOptions()
	local resolution = Game.GetScreenResolution()
	ImGui.Text("Speed Unit")
	ImGui.Separator()
	GVars.features.speedometer.speed_unit, _ = ImGui.RadioButton("M/s", GVars.features.speedometer.speed_unit, 0)
	ImGui.SameLine()
	GVars.features.speedometer.speed_unit, _ = ImGui.RadioButton("Km/h", GVars.features.speedometer.speed_unit, 1)
	ImGui.SameLine()
	GVars.features.speedometer.speed_unit, _ = ImGui.RadioButton("Mi/h", GVars.features.speedometer.speed_unit, 2)

	ImGui.Spacing()
	ImGui.Text("Position")
	ImGui.Separator()
	GVars.features.speedometer.pos.x, _ = ImGui.SliderFloat(
		"Left/Right",
		GVars.features.speedometer.pos.x,
		0.0,
		resolution.x - (GVars.features.speedometer.radius * 2.2)
	)
	GVars.features.speedometer.pos.y, _ = ImGui.SliderFloat(
		"Up/Down",
		GVars.features.speedometer.pos.y, 0.0,
		resolution.y - (GVars.features.speedometer.radius * 2)
	)

	ImGui.Spacing()
	ImGui.Text("Colors")
	ImGui.Separator()
	GVars.features.speedometer.colors.circle, _ = ImGui.ColorEditU32("Circle Color",
		GVars.features.speedometer.colors.circle)
	GVars.features.speedometer.colors.circle_bg, _ = ImGui.ColorEditU32("Circle Background Color",
		GVars.features.speedometer.colors.circle_bg)
	GVars.features.speedometer.colors.text, _ = ImGui.ColorEditU32("Text Color", GVars.features.speedometer.colors.text)
	GVars.features.speedometer.colors.markings, _ = ImGui.ColorEditU32("Markings Color",
		GVars.features.speedometer.colors.markings)
	GVars.features.speedometer.colors.needle, _ = ImGui.ColorEditU32("Needle Color",
		GVars.features.speedometer.colors.needle)
	GVars.features.speedometer.colors.needle_base, _ = ImGui.ColorEditU32("Needle Base Color",
		GVars.features.speedometer.colors.needle_base)

	if GUI:Button("Reset Colors") then
		GVars.features.speedometer.colors = default_cfg.features.speedometer.colors
	end
end

local function driftOptions()
	GVars.features.vehicle.drift.mode, _ = ImGui.Combo("Mode", GVars.features.vehicle.drift.mode, "Strong\0Slippery\0")
	GVars.features.vehicle.drift.power, _ = ImGui.SliderInt("Torque Increase", GVars.features.vehicle.drift.power, 10,
		100)

	ImGui.BeginDisabled(GVars.features.vehicle.drift.mode ~= 1)
	GVars.features.vehicle.drift.intensity, _ = ImGui.SliderInt("Strong Mode Intensity",
		GVars.features.vehicle.drift.intensity, 1, 3)
	ImGui.EndDisabled()
end

local function nosOptions()
	GVars.features.vehicle.nos.power, _ = ImGui.SliderInt("Power Gain", GVars.features.vehicle.nos.power, 10, 100)
	GVars.features.vehicle.nos.screen_effect, _ = GUI:Checkbox("Screen Effect", GVars.features.vehicle.nos.screen_effect)
	GVars.features.vehicle.nos.sound_effect, _ = GUI:Checkbox("Sound Effect", GVars.features.vehicle.nos.sound_effect)
	GVars.features.vehicle.nos.can_damage_engine, _ = GUI:Checkbox("Can Damage Engine",
		GVars.features.vehicle.nos.can_damage_engine,
		{ tooltip = "Damages your engine if you push it too hard." }
	)
end

local function ToggleSubwoofer(toggle)
	script.run_in_fiber(function()
		if (not Self:IsDriving()) then
			return
		end

		Self:GetVehicle():ToggleSubwoofer(toggle)
	end)
end

local function CloseDoors()
	script.run_in_fiber(function(s)
		s:sleep(100)
		Self:GetVehicle():CloseDoors()
	end)
end

local function RestoreExhaustPops()
	script.run_in_fiber(function()
		Self:GetVehicle():RestoreExhaustPops()
	end)
end

local vehicleTab = GUI:RegisterNewTab(eTabID.TAB_VEHICLE, "Cars")

vehicleTab:AddBoolCommand("Brake Force Display", "features.vehicle.abs_lights",
	nil, nil,
	{ description = "Flashes your brake lights when braking from high speed. Only for vehicles equipped with ABS." },
	true -- last param means don't register a command with CommandExecutor
)

vehicleTab:AddBoolCommand("Fast Vehicles",
	"features.vehicle.fast_vehicles",
	nil, nil,
	{ description = "Increases the top speed of any land vehicle you drive." }
)

vehicleTab:AddBoolCommand("Speedometer", "features.speedometer.enabled", nil, nil, nil, true)
vehicleTab:AddBoolCommand("NOS", "features.vehicle.nos.enabled", nil, nil, nil, true)
vehicleTab:AddBoolCommand("NOS Purge", "features.vehicle.nos.purge", nil, nil, { description = "placeholder" }, true) -- description is used for both the UI tooltip and the command description in the CommandExecutor window
vehicleTab:AddBoolCommand("Pops & Bangs", "features.vehicle.burble_tune", nil, RestoreExhaustPops,
	{ description = "placeholder", alias = { "pops" } })
vehicleTab:AddBoolCommand("Drift Mode", "features.vehicle.drift.enabled", nil, nil, { description = "placeholder" }, true)
vehicleTab:AddBoolCommand("Big Subwoofer", "features.vehicle.subwoofer", nil, ToggleSubwoofer(false),
	{ description = "placeholder" }, true)
vehicleTab:AddBoolCommand("High Beams on Horn", "features.vehicle.horn_beams", nil, nil, { description = "placeholder" },
	true)
vehicleTab:AddBoolCommand("Auto Brake Lights", "features.vehicle.auto_brake_lights", nil, nil,
	{ description = "placeholder" }, true)
-- vehicleTab:AddBoolCommand("Can't Touch This!", "features.vehicle.no_carjacking", nil, nil, { description = "placeholder" }, true) -- most NPC's can't car jack you unless scripted to ignore ped flags
-- vehicleTab:AddBoolCommand("Unbreakable Windows", "features.vehicle.unbreakable_windows", nil, nil, { description = "placeholder" }, true)
-- vehicleTab:AddBoolCommand("Vehicle Mines", "features.vehicle.mines", nil, nil, { description = "placeholder" }, true)
-- vehicleTab:AddBoolCommand("Stronger Crashes", "features.vehicle.strong_crash", nil, nil, { description = "placeholder" }, true) -- makes car crashes actually scary
-- vehicleTab:AddBoolCommand("RGB Headlights", "features.vehicle.rgb_lights", nil, nil, { description = "placeholder" }, true)
vehicleTab:AddBoolCommand("Flappy Doors", "features.vehicle.flappy_doors", nil, CloseDoors,
	{ description = "placeholder" })
vehicleTab:AddBoolCommand("Auto Lock Doors", "features.vehicle.auto_lock_doors", nil, nil,
	{ description = "placeholder" }, true)
vehicleTab:AddBoolCommand("Launch Control", "features.vehicle.launch_control", nil, nil,
	{ description = "Simulates launch control. Only available for performance cars." }, true)

vehicleTab:AddBoolCommand("IV-Style Exit", "features.vehicle.iv_exit", nil, function()
		script.run_in_fiber(function()
			PED.SET_PED_CONFIG_FLAG(Self:GetHandle(), 241, false)
			if (not GVars.features.vehicle.no_wheel_recenter) then
				Backend:RemoveDisabledControl(75)
			end
		end)
	end,
	{
		description =
		"Imitates GTA IV's vehicle exit style: Hold [F] for one second to turn off the engine or normal press to leave it running."
	},
	true)

vehicleTab:AddBoolCommand("Keep Wheels Turned", "features.vehicle.no_wheel_recenter", nil, function()
	if (not GVars.features.vehicle.iv_exit) then
		Backend:RemoveDisabledControl(75)
	end
end, { description = "placeholder" }, true)

speedometerOptionsWindow = {
	m_label = "##speedometerOptionsWindow",
	m_callback = function()
		QuickConfigWindow("Speedometer Options", speedoOptions, function()
			GUI:SetRequestedWindowDraw("##speedometerOptionsWindow", false)
		end)
	end,
	m_flags = ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.AlwaysAutoResize,
	m_should_draw = false,
}

driftOptionsWindow = {
	m_label = "##driftOptionsWindow",
	m_callback = function()
		QuickConfigWindow("Drift Options", driftOptions, function()
			GUI:SetRequestedWindowDraw("##driftOptionsWindow", false)
		end)
	end,
	m_flags = ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.AlwaysAutoResize,
	m_should_draw = false,
}

nosOptionsWindow = {
	m_label = "##nosOptionsWindow",
	m_callback = function()
		QuickConfigWindow("NOS Options", nosOptions, function()
			GUI:SetRequestedWindowDraw("##nosOptionsWindow", false)
		end)
	end,
	m_flags = ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.AlwaysAutoResize,
	m_should_draw = false,
}

GUI:RequestWindow(speedometerOptionsWindow) -- since we're drawing everything inside a main independent window, we can't call ImGui.Begin(...)
GUI:RequestWindow(driftOptionsWindow)       -- so we only register then flip a flag and let GUI handle drawing our external windows
GUI:RequestWindow(nosOptionsWindow)

vehicleTab:RegisterGUI(function()
	vehicleTab:GetGridRenderer():Draw()

	ImGui.Spacing()
	ImGui.SeparatorText("Settings")

	GVars.features.vehicle.performance_only, _ = GUI:Checkbox("Performance Cars Only",
		GVars.features.vehicle.performance_only,
		{ tooltip = "Limits some features to performance cars only (Launch Control, Pops & Bangs, etc.)" }
	)
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
-- local planesTab = vehicleTab:RegisterSubtab("Planes", function()
--     ImGui.Text("TODO")
-- end)
--#endregion
