-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BS            = BillionaireServices
local limoModels    = require("includes.data.bsv2_data").DefaultLimousines
local bRequested    = false
local selectedLimo  = nil
local currentTab    = ""
local currentFooter = nil
local buttonSize    = vec2:new(100, 35)
local ctrlBtnSize   = vec2:new(180, 35)
local drivingStyle  = {
	index      = 1,
	normal     = false,
	aggressive = false
}

local function drawSpawner()
	ImGui.SeparatorText(_T("BSV2_LIMO_MODELS_AVAIL"))
	ImGui.Spacing()

	if (ImGui.BeginListBox("##limosList", -1, 0)) then
		for name, data in pairs(limoModels) do
			local is_selected = (selectedLimo == data)

			if (ImGui.Selectable(name, is_selected)) then
				selectedLimo = data
			end

			if (data.description) then
				GUI:Tooltip(data.description)
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

	ImGui.BeginDisabled(not selectedLimo or bRequested)
	if GUI:Button("Dispatch", { size = vec2:new(100, 35) }) then
		if (not selectedLimo) then return end
		BS:CallPrivateLimo(selectedLimo)
		bRequested = true
	end
	ImGui.EndDisabled()
end

---@param limo PrivateLimo
local function drawSpawnedLimo(limo)
	ImGui.Dummy(1, 5)

	local isPlayerInLimo = limo:IsPlayerInLimo()
	if (not isPlayerInLimo and not limo.isRemoteControlled) then
		if (GUI:Button(_T("GENERIC_WARP_INTO_VEH"), { size = ctrlBtnSize })) then
			limo:WarpPlayer()
		end

		ImGui.Text(_T("BSV2_LIMO_MORE_OPTS_TT"))
	end

	if (isPlayerInLimo or limo.isRemoteControlled) then
		ImGui.BeginDisabled(limo.isRemoteControlled)
		ImGui.Spacing()
		ImGui.SeparatorText("Driving Style")
		ImGui.Spacing()

		drivingStyle.index, drivingStyle.normal = ImGui.RadioButton(_T("GENERIC_DRIVING_STYLE_NORMAL"), drivingStyle.index, 1)

		ImGui.SameLine()

		drivingStyle.index, drivingStyle.aggressive = ImGui.RadioButton(_T("GENERIC_DRIVING_STYLE_AGGRO"), drivingStyle.index, 2)

		if (drivingStyle.normal or drivingStyle.aggressive) then
			GUI:PlaySound("Nav")
			limo:SetDrivingStyle(drivingStyle.index)
		end

		ImGui.Spacing()
		ImGui.SeparatorText(_T("GENERIC_COMMANDS"))
		ImGui.Spacing()

		local PV = LocalPlayer:GetVehiclePlayerIsIn()
		ImGui.BeginDisabled(PV ~= nil and PV:GetSpeed() <= 0.1 and limo:IsIdle())
		if (GUI:Button(_T("GENERIC_STOP"), { size = ctrlBtnSize })) then
			ThreadManager:Run(function() limo:Stop() end)
		end

		ImGui.SameLine()
		if (GUI:Button(_T("GENERIC_EMERGENCY_STOP"), { size = ctrlBtnSize })) then
			ThreadManager:Run(function() limo:EmergencyStop() end)
		end
		ImGui.EndDisabled()

		if (GUI:Button(_T("BSV2_ES_DRIVE_WP"), { size = ctrlBtnSize })) then
			ThreadManager:Run(function(s)
				local v_Pos = Game.GetWaypointCoords()
				if (not v_Pos) then
					Notifier:ShowError("Billionaire Services", _T("GENERIC_TP_INVALID_COORDS_ERR"))
					return
				end

				limo:GoTo(v_Pos, s)
			end)
		end

		ImGui.SameLine()

		if (GUI:Button(_T("BSV2_ES_DRIVE_OBJ"), { size = ctrlBtnSize })) then
			ThreadManager:Run(function(s)
				local b_Found, v_Pos = Game.GetObjectiveBlipCoords()
				if (not b_Found) then
					Notifier:ShowError("Billionaire Services", _T("GENERIC_TP_INVALID_COORDS_ERR"))
					return
				end

				limo:GoTo(v_Pos, s)
			end)
		end

		if (GUI:Button(_T("GENERIC_WANDER"), { size = ctrlBtnSize })) then
			ThreadManager:Run(function(s) limo:Wander(s) end)
		end
		ImGui.EndDisabled()

		local isControlled = limo.isRemoteControlled
		local btnLabel     = isControlled and "BSV2_LIMO_GIVE_CTRL" or "BSV2_LIMO_TAKE_CTRL"
		local callback     = isControlled and limo.ReleaseControl or limo.TakeControl
		local tooltip      = isControlled and "BSV2_LIMO_GIVE_CTRL_TT" or "BSV2_LIMO_TAKE_CTRL_TT"

		ImGui.SameLine()
		if (GUI:Button(_T(btnLabel), { size = ctrlBtnSize })) then
			callback(limo)
		end
		GUI:Tooltip(_T(tooltip))

		ImGui.BeginDisabled(limo.isRemoteControlled)
		ImGui.Spacing()
		ImGui.SeparatorText(_T("BSV2_SEAT_CTRL"))
		ImGui.Spacing()

		if (GUI:Button(_F("< %s", _T("BSV2_SEAT_CTRL_PREV")), { size = ctrlBtnSize })) then
			limo:ShuffleSeats(-1)
		end

		ImGui.SameLine()

		if (GUI:Button(_F("%s >", _T("BSV2_SEAT_CTRL_NEXT")), { size = ctrlBtnSize })) then
			limo:ShuffleSeats(1)
		end

		ImGui.Spacing()
		ImGui.SeparatorText(_T("BSV2_RADIO_CTRL"))
		ImGui.Spacing()

		local radioBtnLabel = limo.radio.isOn and "GENERIC_TURN_OFF" or "GENERIC_TURN_ON"
		if (GUI:Button(_T(radioBtnLabel))) then
			ThreadManager:Run(function()
				AUDIO.SET_VEH_RADIO_STATION(
					limo:GetHandle(),
					limo.radio.isOn and "OFF" or "RADIO_22_DLC_BATTLE_MIX1_RADIO"
				)
			end)
		end

		if (limo.radio.isOn) then
			ImGui.SameLine()
			GUI:VehicleRadioCombo(limo:GetHandle(), "limoRadioStations", limo.radio.stationName)
		end
		ImGui.EndDisabled()
	end
end

local function drawSpawnedFooter()
	local limo = BS.ActiveServices.limo
	if (not limo) then return end

	ImGui.SetWindowFontScale(1.12)
	ImGui.SeparatorText(limo.name)
	ImGui.SetWindowFontScale(1.0)
	ImGui.Spacing()

	ImGui.BulletText(_F("Driver: %s", limo.driverName))
	ImGui.BulletText(_F("Status: %s", limo:GetTaskAsString()))
	ImGui.Dummy(1, 5)

	if Backend.debug_mode then
		if ImGui.Button("Parse Vehicle Mods") then
			ThreadManager:Run(function()
				local t = limo:GetMods()
				local toPrint = {}

				for i, v in ipairs(t) do
					if v ~= -1 then
						toPrint[i] = v
					end
				end

				local wheeltype, _ = limo:GetCustomWheels()
				Backend:debug(_F("\nMods = %s\nWheel Type = %s", table.serialize(toPrint, 2), wheeltype))
			end)
		end
		ImGui.SameLine()
		if ImGui.Button("Cleanup") then
			BS:RemoveLimo()
			bRequested = false
		end
	end

	if (GUI:Button(_T("GENERIC_REPAIR"), buttonSize)) then
		ThreadManager:Run(function()
			limo:Repair()
		end)
	end

	ImGui.SameLine()

	if (GUI:Button(_T("GENERIC_DISMISS"), buttonSize)) then
		BS:Dismiss(BS.SERVICE_TYPE.LIMO)
		bRequested = false
	end
end

---@return string tabName, function? footer
return function()
	local limo = BS.ActiveServices.limo
	if (not limo) then
		currentTab    = "LIMO_SPAWNER"
		currentFooter = nil
		drawSpawner()
	else
		currentTab    = "SPAWNED_LIMO"
		currentFooter = drawSpawnedFooter
		drawSpawnedLimo(limo)
	end

	return currentTab, currentFooter
end
