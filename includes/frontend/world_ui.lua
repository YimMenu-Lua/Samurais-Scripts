local World     = require("includes.modules.World")
local HideNSeek = require("includes.features.world.HideNSeek").new()
local Carpool   = require("includes.features.world.carpool").new()
local world_tab = GUI:RegisterNewTab(eTabID.TAB_WORLD, "World")

world_tab:AddBoolCommand("WRLD_DISABLE_WAVES",
	"features.world.disable_ocean_waves",
	nil,
	function()
		ThreadManager:Run(function()
			World:ResetOceanWaves()
		end)
	end,
	nil,
	true,
	true
)

world_tab:AddBoolCommand("WRLD_EXTEND_BOUNDS",
	"features.world.extend_bounds",
	nil,
	function()
		ThreadManager:Run(function()
			World:ResetBounds()
		end)
	end,
	{ description = "WRLD_EXTEND_BOUNDS_TT" },
	false,
	true
)

world_tab:AddBoolCommand("WRLD_FLIGHT_MUSIC",
	"features.world.disable_flight_music",
	nil,
	function()
		ThreadManager:Run(function()
			AUDIO.SET_AUDIO_FLAG("DisableFlightMusic", false)
		end)
	end,
	nil,
	true,
	true
)

world_tab:AddBoolCommand("WRLD_WANTED_MUSIC",
	"features.world.disable_wanted_music",
	nil,
	function()
		ThreadManager:Run(function()
			AUDIO.SET_AUDIO_FLAG("WantedMusicDisabled", false)
		end)
	end,
	nil,
	true,
	true
)

world_tab:AddLoopedCommand("WRLD_HNS",
	"features.world.hide_n_seek",
	function()
		HideNSeek:Main()
	end,
	function()
		ThreadManager:Run(function()
			HideNSeek:OnDisable()
		end)
	end,
	{ description = "WRLD_HNS_TT" },
	true,
	true
)

world_tab:AddLoopedCommand("WRLD_CARPOOL",
	"features.world.carpool",
	function()
		Carpool:Main()
	end,
	function()
		ThreadManager:Run(function()
			Carpool:OnDisable()
		end)
	end,
	{ description = "WRLD_CARPOOL_TT" },
	true,
	true
)

local carpoolDrivingStyleSwitch = 1
local drivingStyleClicked = false
local carpoolRoofStateCases <const> = {
	[Enums.eConvertibleRoofState.RAISED]   = "Lower",
	[Enums.eConvertibleRoofState.LOWERING] = "Lowering",
	[Enums.eConvertibleRoofState.LOWERED]  = "Raise",
	[Enums.eConvertibleRoofState.RAISING]  = "Raising",
	default                                = ""
}

local function ShowCarpoolControls()
	if (not GVars.features.world.carpool or not Carpool:IsActive()) then
		return
	end

	ImGui.SetWindowFontScale(1.1)
	ImGui.Text(_F("%s %s", _T("WRLD_CARPOOL"), _T("GENERIC_OPTIONS_LABEL")))
	ImGui.SetWindowFontScale(1)
	ImGui.Separator()

	ImGui.Spacing()
	ImGui.SeparatorText("Driving Commands:")

	ImGui.BulletText("Driving Style:")
	ImGui.SameLine()
	carpoolDrivingStyleSwitch, drivingStyleClicked = ImGui.RadioButton("Chill", carpoolDrivingStyleSwitch, 1)

	ImGui.SameLine()

	carpoolDrivingStyleSwitch, drivingStyleClicked = ImGui.RadioButton("Aggressive", carpoolDrivingStyleSwitch, 2)

	if (drivingStyleClicked) then
		Carpool:SetDrivingStyle(carpoolDrivingStyleSwitch)
	end

	local tsk = Carpool:GetCurrentTask()
	if GUI:Button(tsk ~= 99 and "Stop The Vehicle" or "Keep Driving") then
		ThreadManager:Run(function()
			if (tsk == 99) then
				Carpool:Resume()
			else
				Carpool:Stop()
			end
		end)
	end

	ImGui.SameLine()

	if GUI:Button("Cruise Around") then
		ThreadManager:Run(function()
			Carpool:Wander()
		end)
	end

	if GUI:Button("Drive To Waypoint") then
		ThreadManager:Run(function()
			local wp = Game.GetWaypointCoords()

			if (not wp or wp:is_zero()) then
				Toast:ShowError(
					"Samurai's Scripts",
					"Please set a waypoint on the map first!"
				)
				return
			end

			Carpool:GoTo(wp)
			Toast:ShowMessage(
				"Samurai's Scripts",
				"Driving to waypoint..."
			)
		end)
	end

	ImGui.SameLine()

	if GUI:Button("Drive To Objective") then
		ThreadManager:Run(function(s)
			local objective_found, objective_coords = Game.GetObjectiveBlipCoords()
			if (not objective_found) then
				Toast:ShowError(
					"Samurai's Scripts",
					"No objective found!"
				)
				return
			end

			Carpool:GoTo(objective_coords)
			Toast:ShowMessage("Samurai's Scripts", "Driving to objective...")
		end)
	end

	if Carpool.cachedVehicleData.maxSeats > 1 then
		ImGui.Spacing()
		ImGui.SeparatorText("Seats:")
		ImGui.Spacing()

		if GUI:Button(_F("< %s", _T("VEH_SEAT_PREV"))) then
			Carpool:ShuffleSeats(-1)
		end

		ImGui.SameLine()
		if GUI:Button(_F("%s >", _T("VEH_SEAT_NEXT"))) then
			Carpool:ShuffleSeats(1)
		end
	end

	if (Carpool:GetDriver() == 0) then
		return
	end

	ImGui.Spacing()
	ImGui.SeparatorText("Radio:")

	if GUI:Button(Carpool.cachedVehicleData.radio.isOn and "Turn Off" or "Turn On") then
		ThreadManager:Run(function()
			AUDIO.SET_VEH_RADIO_STATION(
				Carpool:GetVehicle():GetHandle(),
				Carpool.cachedVehicleData.radio.isOn
				and "OFF"
				or Audio.RadioStations[math.random(1, (#Audio.RadioStations - 1))].station
			)
		end)
	end

	ImGui.SameLine()

	GUI:VehicleRadioCombo(
		Carpool:GetVehicle():GetHandle(),
		"##carpoolradio",
		tostring(Carpool.cachedVehicleData.radio.station)
	)

	if Carpool.cachedVehicleData.isConvertible then
		ImGui.Spacing()
		ImGui.SeparatorText("Convertible Roof:")
		ImGui.Spacing()

		local roofState = Carpool.cachedVehicleData.roofState
		local roofButtonLabel = Match(roofState, carpoolRoofStateCases)
		ImGui.BeginDisabled(roofState == 1 or roofState == 3)

		if GUI:Button(roofButtonLabel) then
			if Carpool.cachedVehicleData.speed > 6.66 then
				Toast:ShowError(
					"Samurai's Scripts",
					"You can not operate the convertible roof at this speed."
				)
				return
			end

			ThreadManager:Run(function()
				if (roofState == Enums.eConvertibleRoofState.RAISED) then
					VEHICLE.LOWER_CONVERTIBLE_ROOF(Carpool:GetVehicle():GetHandle(), false)
				elseif (roofState == Enums.eConvertibleRoofState.LOWERED) then
					VEHICLE.RAISE_CONVERTIBLE_ROOF(Carpool:GetVehicle():GetHandle(), false)
				end
			end)
		end
		ImGui.EndDisabled()
	end
end

local function WorldUI()
	world_tab:GetGridRenderer():Draw()
	ShowCarpoolControls()
	ImGui.Spacing()
	ImGui.TextDisabled("The world is simple. For now.")
end

world_tab:RegisterGUI(WorldUI)
