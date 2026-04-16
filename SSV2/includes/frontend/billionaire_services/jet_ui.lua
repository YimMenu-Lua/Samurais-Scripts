-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BSV2              = require("includes.features.extra.billionaire_services.BillionaireServicesV2")
local BSdata <const>    = require("includes.data.bsv2_data")
local JetModels <const> = BSdata.DefaultJetModels
local Airports <const>  = BSdata.Airports
local selectedJet       = JetModels[1]
local selectedAirport   = Airports[1]
local buttonSize        = vec2:new(100, 35)
local ctrlBtnSize       = vec2:new(180, 35)
local currentTab        = ""
local currentFooter     = nil

local function DrawAirportCombo()
	if ImGui.BeginCombo("##airportCombo", selectedAirport.name) then
		for i, aiportData in ipairs(Airports) do
			local is_selected = (aiportData == selectedAirport)

			if (ImGui.Selectable(aiportData.name, is_selected)) then
				selectedAirport = aiportData
			end

			if (GUI:IsItemClicked(0)) then
				GUI:PlaySound("Nav")
			end
		end
		ImGui.EndCombo()
	end
end

local function drawSpawner()
	ImGui.SeparatorText(_T("BSV2_JET_MODELS_AVAIL"))
	ImGui.Spacing()

	if (ImGui.BeginListBox("##jetList", -1, 0)) then
		for i, data in pairs(JetModels) do
			local is_selected = (data == selectedJet)

			if (ImGui.Selectable(data.name, is_selected)) then
				selectedJet = data
			end
			GUI:Tooltip(data.description)

			if (GUI:IsItemClicked(0)) then
				GUI:PlaySound("Nav")
			end
		end
		ImGui.EndListBox()
	end

	ImGui.Spacing()
	ImGui.SeparatorText(_T("BSV2_AIRPORTS"))
	ImGui.Spacing()

	DrawAirportCombo()

	ImGui.Dummy(1, 5)
	ImGui.Separator()
	ImGui.Dummy(1, 5)

	ImGui.BeginDisabled(not selectedJet or not selectedAirport)
	if (GUI:Button(_T("BSV2_DISPATCH"), { size = vec2:new(100, 40) })) then
		BSV2:CallPrivateJet(selectedJet.model, selectedAirport)
	end
	ImGui.EndDisabled()
	GUI:HelpMarker(_T("BSV2_JET_TOO_FAR_WARN"))
end

local function drawSpawnedJet(jet)
	ImGui.Dummy(1, 5)
	if not jet:IsPlayerInJet() then
		ImGui.BeginDisabled(not jet.canWarpPlayer)
		if (GUI:Button(_T("GENERIC_WARP_INTO_VEH"), { size = ctrlBtnSize })) then
			jet:WarpPlayer()
		end
		ImGui.EndDisabled()

		ImGui.Spacing()
		ImGui.Text(_T("BSV2_JET_MORE_OPTS_TT"))
	else
		ImGui.Spacing()
		ImGui.SeparatorText(_T("GENERIC_COMMANDS"))
		ImGui.Spacing()

		ImGui.BeginDisabled(jet.task == Enums.eVehicleTask.TAKE_OFF)
		if (GUI:Button(_T("BSV2_FLY_WP"), { size = ctrlBtnSize })) then
			ThreadManager:Run(function(s)
				local v_Pos = Game.GetWaypointCoords()
				if not v_Pos then
					Notifier:ShowError("Billionaire Services", _T("GENERIC_TP_INVALID_COORDS_ERR"))
					return
				end
				jet:FlyTo(v_Pos, s)
			end)
		end

		ImGui.SameLine()

		if (GUI:Button(_T("BSV2_FLY_OBJ"), { size = ctrlBtnSize })) then
			ThreadManager:Run(function(s)
				local b_Found, v_Pos = Game.GetObjectiveBlipCoords()
				if (not b_Found) then
					Notifier:ShowError("Billionaire Services", _T("GENERIC_TP_INVALID_COORDS_ERR"))
					return
				end

				jet:FlyTo(v_Pos, s)
			end)
		end
		ImGui.EndDisabled()

		ImGui.BeginDisabled(jet.task ~= Enums.eVehicleTask.GOTO)
		if (GUI:Button(_T("BSV2_FLY_SKIP"), { size = ctrlBtnSize })) then
			ThreadManager:Run(function() jet:SkipTrip() end)
		end
		ImGui.EndDisabled()

		ImGui.SameLine()

		ImGui.BeginDisabled(jet.task ~= Enums.eVehicleTask.LAND)
		if (GUI:Button(_T("BSV2_JET_SKIP_LANDING"), { size = ctrlBtnSize })) then
			ThreadManager:Run(function() jet:FinishLanding() end)
		end
		ImGui.EndDisabled()

		ImGui.Spacing()
		ImGui.SeparatorText(_T("BSV2_JET_LANDING_DEST"))
		ImGui.Spacing()

		DrawAirportCombo()

		ImGui.SameLine()

		ImGui.BeginDisabled(not selectedAirport or not selectedAirport.landingApproach)
		if (GUI:Button(_T("GENERIC_GO"))) then
			ThreadManager:Run(function(s)
				if (jet.departureAirport and (jet.departureAirport.name == selectedAirport.name)) then
					Notifier:ShowError("Private Jet", _F(_T("BSV2_JET_LANDING_SAME_AP_ERR"), selectedAirport.name))
					return
				end

				jet.arrivalAirport = selectedAirport
				Notifier:ShowMessage("Private Jet", _F(_T("BSV2_JET_FLY_CONFIRM"), selectedAirport.name))
				jet:FlyTo(selectedAirport.landingApproach.pos, s)
			end)
		end
		ImGui.EndDisabled()

		ImGui.Spacing()
		ImGui.SeparatorText(_T("BSV2_SEAT_CTRL"))
		ImGui.Spacing()

		if (GUI:Button(_F("< %s", _T("BSV2_SEAT_CTRL_PREV")), { size = ctrlBtnSize })) then
			jet:ShuffleSeats(-1)
		end

		ImGui.SameLine()

		if (GUI:Button(_F("%s >", _T("BSV2_SEAT_CTRL_NEXT")), { size = ctrlBtnSize })) then
			jet:ShuffleSeats(1)
		end

		ImGui.Spacing()
		ImGui.SeparatorText(_T("BSV2_RADIO_CTRL"))
		ImGui.Spacing()

		local radioBtnLabel = jet.radio.isOn and "GENERIC_TURN_OFF" or "GENERIC_TURN_ON"
		if (GUI:Button(_T(radioBtnLabel))) then
			ThreadManager:Run(function()
				AUDIO.SET_VEH_RADIO_STATION(
					jet:GetHandle(),
					jet.radio.isOn
					and "OFF"
					or "RADIO_22_DLC_BATTLE_MIX1_RADIO"
				)
				jet.radio.isOn        = AUDIO.IS_VEHICLE_RADIO_ON(jet:GetHandle())
				jet.radio.stationName = Game.GetGXTLabel(AUDIO.GET_PLAYER_RADIO_STATION_NAME())
			end)
		end

		if (jet.radio.isOn) then
			ImGui.SameLine()
			GUI:VehicleRadioCombo(jet:GetHandle(), "jetRadioStations", jet.radio.stationName)
		end
	end
end

local function SpawnedJetFooter()
	local jet = BSV2.ActiveServices.jet
	if (not jet) then return end

	ImGui.SetWindowFontScale(1.12)
	ImGui.SeparatorText(jet.name)
	ImGui.SetWindowFontScale(1)
	ImGui.Spacing()

	ImGui.BulletText(_F("Pilot: %s", jet.pilotName))
	ImGui.BulletText(_F("Co-Pilot: %s", jet.copilotName))
	ImGui.BulletText(_F("Status: %s", jet:GetTaskAsString()))
	ImGui.Dummy(1, 5)

	if (GUI:Button(_T("GENERIC_REPAIR"), buttonSize)) then
		jet:Repair()
	end

	ImGui.SameLine()

	if (GUI:Button(_T("GENERIC_DISMISS"), buttonSize)) then
		BSV2:Dismiss(BSV2.SERVICE_TYPE.JET)
	end
end

---@return string tabName, function? footer
return function()
	local jet = BSV2.ActiveServices.jet
	if (not jet) then
		drawSpawner()
		currentTab    = "JET_SPAWNER"
		currentFooter = nil
	else
		drawSpawnedJet(jet)
		currentTab    = "SPAWNED_JET"
		currentFooter = SpawnedJetFooter
	end

	return currentTab, currentFooter
end
