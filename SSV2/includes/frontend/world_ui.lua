-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Audio                         = require("includes.modules.Audio")
local World                         = require("includes.modules.World")
local HideNSeek                     = require("includes.features.world.HideNSeek").new()
local Carpool                       = require("includes.features.world.carpool").new()
local EnemiesFlee                   = require("includes.features.world.EnemiesFlee")
local KillAll                       = require("includes.features.world.KillAllEnemies")
local measureTextWidth              = require("includes.frontend.helpers.measure_text_width")
local carpoolDrivingStyleSwitch     = 1
local drivingStyle1Clicked          = false
local drivingStyle2Clicked          = false
local buttonWidthCache              = {}
local buttonSize                    = vec2:new(0, 36)
local carpoolRoofStateCases <const> = {
	[Enums.eConvertibleRoofState.RAISED]   = "Lower",
	[Enums.eConvertibleRoofState.LOWERING] = "Lowering",
	[Enums.eConvertibleRoofState.LOWERED]  = "Raise",
	[Enums.eConvertibleRoofState.RAISING]  = "Raising",
	default                                = ""
}


local worldTab = GUI:RegisterNewTab(Enums.eTabID.TAB_WORLD, "TAB_WORLD", nil, nil, true)

worldTab:AddBoolCommand("WRLD_DISABLE_WAVES",
	{
		gvar_key        = "features.world.disable_ocean_waves",
		translate_label = true,
		on_disable      = function()
			ThreadManager:Run(function()
				World:ResetOceanWaves()
			end)
		end,
	}
)
worldTab:AddBoolCommand("WRLD_EXTEND_BOUNDS",
	{
		gvar_key         = "features.world.extend_bounds",
		translate_label  = true,
		meta             = { description = "WRLD_EXTEND_BOUNDS_TT", isTranslatorLabel = true },
		register_command = true,
		on_disable       = function()
			ThreadManager:Run(function()
				World:ResetBounds()
			end)
		end,
	}
)
worldTab:AddBoolCommand("WRLD_FLIGHT_MUSIC",
	{
		gvar_key         = "features.world.disable_flight_music",
		translate_label  = true,
		register_command = true,
		on_disable       = function()
			ThreadManager:Run(function()
				AUDIO.SET_AUDIO_FLAG("DisableFlightMusic", false)
			end)
		end,
	}
)
worldTab:AddBoolCommand("WRLD_WANTED_MUSIC",
	{
		gvar_key         = "features.world.disable_wanted_music",
		translate_label  = true,
		register_command = true,
		on_disable       = function()
			ThreadManager:Run(function()
				AUDIO.SET_AUDIO_FLAG("WantedMusicDisabled", false)
			end)
		end,
	}
)
worldTab:AddLoopedCommand("WRLD_HNS",
	{
		gvar_key         = "features.world.hide_n_seek",
		translate_label  = true,
		meta             = { description = "WRLD_HNS_TT", alias = { "hidenseek", "trashboy" }, isTranslatorLabel = true },
		register_command = true,
		callback         = function() HideNSeek:OnTick() end,
		on_disable       = function()
			ThreadManager:Run(function()
				HideNSeek:OnDisable()
			end)
		end,
	}
)
worldTab:AddLoopedCommand("WRLD_CARPOOL",
	{
		gvar_key         = "features.world.carpool",
		translate_label  = true,
		meta             = { description = "WRLD_CARPOOL_TT", alias = { "carpool" }, isTranslatorLabel = true },
		register_command = true,
		callback         = function() Carpool:OnTick() end,
		on_disable       = function()
			ThreadManager:Run(function()
				Carpool:OnDisable()
			end)
		end,
	}
)

local function ShowCarpoolControls()
	if (not GVars.features.world.carpool or not Carpool:IsActive()) then
		return
	end

	ImGui.SetWindowFontScale(1.1)
	ImGui.Text(_F("%s %s", _T("WRLD_CARPOOL"), _T("GENERIC_OPTIONS_LABEL")))
	ImGui.SetWindowFontScale(1)
	ImGui.Separator()

	ImGui.Spacing()
	ImGui.SeparatorText(_T("GENERIC_DRIVING_COMMANDS"))

	ImGui.BulletText(_T("GENERIC_DRIVING_STYLE"))
	ImGui.SameLine()
	carpoolDrivingStyleSwitch, drivingStyle1Clicked = ImGui.RadioButton(_T("GENERIC_DRIVING_STYLE_NORMAL"), carpoolDrivingStyleSwitch, 1)

	ImGui.SameLine()

	carpoolDrivingStyleSwitch, drivingStyle2Clicked = ImGui.RadioButton(_T("GENERIC_DRIVING_STYLE_AGGRO"), carpoolDrivingStyleSwitch, 2)

	if (drivingStyle1Clicked or drivingStyle2Clicked) then
		Carpool:SetDrivingStyle(carpoolDrivingStyleSwitch)
	end

	local currentTask = Carpool:GetCurrentTask()
	if (GUI:Button(currentTask ~= 99 and _T("GENERIC_STOP") or _T("GENERIC_RESUME"))) then
		ThreadManager:Run(function()
			if (currentTask == 99) then
				Carpool:Resume()
			else
				Carpool:Stop()
			end
		end)
	end

	ImGui.SameLine()

	if (GUI:Button(_T("GENERIC_WANDER"))) then
		ThreadManager:Run(function() Carpool:Wander() end)
	end

	if (GUI:Button(_T("BSV2_ES_DRIVE_WP"))) then
		ThreadManager:Run(function()
			local wp = Game.GetWaypointCoords()
			if (not wp or wp:is_zero()) then
				Notifier:ShowError("Carpool", "Please set a waypoint on the map first!")
				return
			end

			Carpool:GoTo(wp)
		end)
	end

	ImGui.SameLine()

	if (GUI:Button(_T("BSV2_ES_DRIVE_OBJ"))) then
		ThreadManager:Run(function()
			local found, coords = Game.GetObjectiveBlipCoords()
			if (not found) then
				Notifier:ShowError("Carpool", "No objective found!")
				return
			end

			Carpool:GoTo(coords)
		end)
	end

	local vehicleData = Carpool.cachedVehicleData
	if (vehicleData.maxSeats > 1) then
		ImGui.Spacing()
		ImGui.SeparatorText(_T("BSV2_SEAT_CTRL"))
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
	ImGui.SeparatorText(_T("BSV2_RADIO_CTRL"))

	if (GUI:Button(_T(vehicleData.radio.isOn and "GENERIC_TURN_OFF" or "GENERIC_TURN_ON"))) then
		ThreadManager:Run(function()
			AUDIO.SET_VEH_RADIO_STATION(
				Carpool:GetVehicle():GetHandle(),
				vehicleData.radio.isOn
				and "OFF"
				or Audio.RadioStations[math.random(1, (#Audio.RadioStations - 1))].station
			)
		end)
	end

	ImGui.SameLine()
	GUI:VehicleRadioCombo(
		Carpool:GetVehicle():GetHandle(),
		"##carpoolradio",
		vehicleData.radio.station or "OFF"
	)

	if (vehicleData.isConvertible) then
		ImGui.Spacing()
		ImGui.SeparatorText("Convertible Roof:")
		ImGui.Spacing()

		local roofState       = vehicleData.roofState
		local roofButtonLabel = Match(roofState, carpoolRoofStateCases)
		ImGui.BeginDisabled(roofState == 1 or roofState == 3)

		if (GUI:Button(roofButtonLabel)) then
			if (vehicleData.speed > 6.66) then
				Notifier:ShowError("Samurai's Scripts", "You can not operate the convertible roof at this speed.")
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

local public_enemy_clicked = false
local function WorldUI()
	worldTab:GetGridRenderer():Draw()
	ImGui.Spacing()

	World.m_public_enemy.m_enabled, public_enemy_clicked = GUI:CustomToggle(_T("WRLD_PUBLIC_ENEMY"),
		World.m_public_enemy.m_enabled,
		{ tooltip = _T("WRLD_PUBLIC_ENEMY_TT") }
	)

	if (public_enemy_clicked and not World.m_public_enemy.m_enabled) then
		ThreadManager:Run(function()
			World.m_public_enemy:Cleanup()
		end)
	end

	ImGui.Spacing()

	local lang_idx = GVars.backend.language_index
	local buttonWidth = buttonWidthCache[lang_idx]
	if (not buttonWidth) then
		buttonWidth = measureTextWidth({
			_T("WRLD_KILL_ALL"),
			_T("WRLD_FLEE_ALL")
		}, 20.0)
		buttonWidthCache[lang_idx] = buttonWidth
		buttonSize.x = buttonWidth
	end

	ImGui.Spacing()

	if (GUI:Button(_T("WRLD_KILL_ALL"), { size = buttonSize, tooltip = _T("WRLD_KILL_ALL_TT") })) then
		KillAll:OnClick()
	end

	if (GUI:Button(_T("WRLD_FLEE_ALL"), { size = buttonSize, tooltip = _T("WRLD_FLEE_ALL_TT") })) then
		EnemiesFlee:OnClick()
	end

	ShowCarpoolControls()

	ImGui.Spacing()
	ImGui.Separator()
	ImGui.TextDisabled("The world is simple. For now.")
end

worldTab:RegisterGUI(WorldUI)
