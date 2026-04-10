-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BS                         = BillionaireServices
local BSdata <const>             = require("includes.data.bsv2_data")
local HeliModels <const>         = BSdata.DefaultHeliModels
local PresetDestinations <const> = BSdata.HeliPresetDestinations
local selectedHeli               = HeliModels[1]
local selectedDestination        = PresetDestinations[1]
local buttonSize                 = vec2:new(100, 35)
local ctrlBtnSize                = vec2:new(180, 35)
local godMode                    = false
local currentTab                 = ""
local currentFooter              = nil

local function drawHeliControls(heli)
	ImGui.Dummy(1, 5)

	if (not heli:IsPlayerInHeli()) then
		ImGui.BeginDisabled(heli.isPlayerRappelling or not heli.isReady)
		if (GUI:Button(_T("GENERIC_WARP_INTO_VEH"), { size = ctrlBtnSize })) then
			heli:WarpPlayer()
		end

		ImGui.SameLine()

		ImGui.BeginDisabled(not heli.isFarAway)
		if (GUI:Button(_T("GENERIC_BRING"), { size = ctrlBtnSize })) then
			ThreadManager:Run(function(s) heli:Bring(s) end)
		end
		ImGui.EndDisabled()
		ImGui.EndDisabled()

		if (heli.isPlayerRappelling or not heli.isReady) then
			ImGui.Text(ImGui.TextSpinner(_T("GENERIC_WAIT_LABEL")))
		else
			ImGui.Text(_T("BSV2_HELI_MORE_OPTS_TT"))
		end
	else
		ImGui.BeginDisabled(heli.isPlayerRappelling)
		ImGui.Spacing()
		ImGui.SeparatorText(_T("GENERIC_COMMANDS"))
		ImGui.Spacing()

		ImGui.BeginDisabled((heli.task == Enums.eVehicleTask.HOVER_IN_PLACE) or heli.altitude <= 3)
		if (GUI:Button(_T("BSV2_HELI_HOVER_HERE"), { size = ctrlBtnSize })) then
			ThreadManager:Run(function() heli:HoverInPlace() end)
		end
		ImGui.EndDisabled()

		ImGui.SameLine()

		ImGui.BeginDisabled(heli.altitude <= 3)
		if (GUI:Button(_T("BSV2_HELI_LAND_HERE"), { size = ctrlBtnSize })) then
			ThreadManager:Run(function() heli:LandHere() end)
		end
		ImGui.EndDisabled()

		if (GUI:Button(_T("BSV2_FLY_WP"), { size = ctrlBtnSize })) then
			ThreadManager:Run(function()
				local v_Pos = Game.GetWaypointCoords()
				if (not v_Pos) then
					Notifier:ShowError("Billionaire Services", _T("GENERIC_TP_INVALID_COORDS_ERR"))
					return
				end
				heli:FlyTo(v_Pos)
			end)
		end

		ImGui.SameLine()

		if (GUI:Button(_T("BSV2_FLY_OBJ"), { size = ctrlBtnSize })) then
			ThreadManager:Run(function()
				local b_Found, v_Pos = Game.GetObjectiveBlipCoords()
				if (not b_Found) then
					Notifier:ShowError("Billionaire Services", _T("GENERIC_TP_INVALID_COORDS_ERR"))
					return
				end
				heli:FlyTo(v_Pos)
			end)
		end

		ImGui.BeginDisabled(heli.task ~= Enums.eVehicleTask.GOTO)
		if (GUI:Button(_T("BSV2_FLY_SKIP"), { size = ctrlBtnSize })) then
			ThreadManager:Run(function(s) heli:SkipTrip(s) end)
		end
		ImGui.EndDisabled()

		ImGui.SameLine()
		if (heli.allowsRappelling) then
			ImGui.SameLine()
			ImGui.BeginDisabled((heli.task ~= Enums.eVehicleTask.HOVER_IN_PLACE)
				or (heli.altitude < 5)
				or heli.isPlayerRappelling
			)
			if (GUI:Button(_T("BSV2_HELI_RAPPELL"), { size = ctrlBtnSize })) then
				ThreadManager:Run(function()
					if (LocalPlayer:GetVehicleSeat() < 1) then
						Notifier:ShowError("Private Heli", _T("BSV2_HELI_RAPPELL_SEAT_ERR"))
						return
					end
					TASK.TASK_RAPPEL_FROM_HELI(LocalPlayer:GetHandle(), 5.0)
				end)
			end
			ImGui.EndDisabled()
		end

		ImGui.Spacing()
		ImGui.SeparatorText(_T("BSV2_HELI_PRESETS"))
		ImGui.Spacing()

		if (ImGui.BeginCombo("##heliPresetDestinations", selectedDestination.first)) then
			for i, pair in ipairs(PresetDestinations) do
				if (ImGui.Selectable(pair.first, pair == selectedDestination)) then
					selectedDestination = pair
				end

				if (GUI:IsItemClicked(0)) then
					GUI:PlaySound("Nav")
				end
			end
			ImGui.EndCombo()
		end

		ImGui.SameLine()

		ImGui.BeginDisabled(not selectedDestination.second)
		if (GUI:Button(_T("GENERIC_GO"))) then
			ThreadManager:Run(function()
				heli:FlyTo(selectedDestination.second, true)
			end)
		end
		ImGui.EndDisabled()

		ImGui.Spacing()
		ImGui.SeparatorText(_T("BSV2_SEAT_CTRL"))
		ImGui.Spacing()

		if (GUI:Button(_F("< %s", _T("BSV2_SEAT_CTRL_PREV")), { size = ctrlBtnSize })) then
			heli:ShuffleSeats(-1)
		end

		ImGui.SameLine()

		if (GUI:Button(_F("%s >", _T("BSV2_SEAT_CTRL_NEXT")), { size = ctrlBtnSize })) then
			heli:ShuffleSeats(1)
		end

		ImGui.Spacing()
		ImGui.SeparatorText(_T("BSV2_RADIO_CTRL"))
		ImGui.Spacing()

		local radioBtnLabel = heli.radio.isOn and "GENERIC_TURN_OFF" or "GENERIC_TURN_ON"
		if (GUI:Button(_T(radioBtnLabel))) then
			ThreadManager:Run(function()
				AUDIO.SET_VEH_RADIO_STATION(
					heli:GetHandle(),
					heli.radio.isOn
					and "OFF"
					or "RADIO_22_DLC_BATTLE_MIX1_RADIO"
				)
				heli.radio.isOn        = AUDIO.IS_VEHICLE_RADIO_ON(heli:GetHandle())
				heli.radio.stationName = Game.GetGXTLabel(AUDIO.GET_PLAYER_RADIO_STATION_NAME())
			end)
		end

		if (heli.radio.isOn) then
			ImGui.SameLine()
			GUI:VehicleRadioCombo(heli:GetHandle(), "heliRadioStations", heli.radio.stationName)
		end
		ImGui.EndDisabled()
	end
end

local function drawSpawner()
	ImGui.SeparatorText(_T("BSV2_HELI_MODELS_AVAIL"))
	ImGui.Spacing()

	if (ImGui.BeginListBox("##heliList", -1, 0)) then
		for _, pair in pairs(HeliModels) do
			local is_selected = (selectedHeli == pair)

			if (ImGui.Selectable(pair.first, is_selected)) then
				selectedHeli = pair
			end

			if (GUI:IsItemClicked(0)) then
				GUI:PlaySound("Nav")
			end
		end
		ImGui.EndListBox()
	end

	ImGui.Dummy(1, 5)
	ImGui.Separator()
	ImGui.Dummy(1, 5)

	godMode = GUI:CustomToggle(_T("GENERIC_INVINCIBLE"), godMode)

	ImGui.Spacing()

	ImGui.BeginDisabled(not selectedHeli)
	if (GUI:Button(_T("BSV2_DISPATCH"), { size = vec2:new(100, 40) })) then
		BS:CallPrivateHeli(selectedHeli.second, godMode)
	end
	ImGui.EndDisabled()
end

local function drawSpawnedFooter()
	local heli = BS.ActiveServices.heli
	if (not heli) then return end

	ImGui.SetWindowFontScale(1.12)
	ImGui.SeparatorText(heli.name)
	ImGui.SetWindowFontScale(1)
	ImGui.Spacing()

	ImGui.BulletText(_F("Pilot: %s", heli.pilotName))
	ImGui.BulletText(_F("Status: %s", heli:GetTaskAsString()))
	ImGui.Dummy(1, 5)

	ImGui.BeginDisabled(not heli.isReady)
	if (GUI:Button(_T("GENERIC_REPAIR"), { size = buttonSize })) then
		heli:Repair()
	end

	ImGui.SameLine()

	if (GUI:Button(_T("GENERIC_DISMISS"), { size = buttonSize })) then
		BS:Dismiss(BS.SERVICE_TYPE.HELI)
	end
	ImGui.EndDisabled()
end

---@return string tabName, function? footer
return function()
	local heli = BS.ActiveServices.heli
	if (not heli) then
		currentTab    = "HELI_SPAWNER"
		currentFooter = nil
		drawSpawner()
	else
		currentTab    = "SPAWNED_HELI"
		currentFooter = drawSpawnedFooter
		drawHeliControls()
	end

	return currentTab, currentFooter
end
