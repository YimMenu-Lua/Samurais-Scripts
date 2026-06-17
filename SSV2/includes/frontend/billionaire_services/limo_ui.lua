-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BSV2                 = require("includes.features.extra.billionaire_services.BillionaireServicesV2")
local limoModels           = require("includes.data.bsv2_data").DefaultLimousines
local measureTextWidth     = require("includes.frontend.helpers.measure_text_width")
local propertyDestSelector = require("includes.frontend.billionaire_services.prop_destinations_ui")
local bRequested           = false
local currentTab           = ""
local currentFooter        = nil
local childWidth           = nil
local buttonSize           = vec2:new(180, 35)
local limoNameMaxWidth     = 0
local labelWidths          = {}
local drivingStyle         = {
	index      = 1,
	normal     = false,
	aggressive = false
}

local function calcLimoNameWidths()
	if (limoNameMaxWidth > 0) then
		return
	end

	for name in pairs(limoModels) do
		limoNameMaxWidth = math.max(limoNameMaxWidth, ImGui.CalcTextSize(name))
	end
end

local function drawSpawner()
	calcLimoNameWidths()
	ImGui.SeparatorText(_T("BSV2_LIMO_MODELS_AVAIL"))
	ImGui.Spacing()

	childWidth = childWidth or math.min(limoNameMaxWidth * 1.8, ImGui.GetContentRegionAvail() * 0.47)
	ImGui.BeginDisabled(bRequested)
	for name, data in pairs(limoModels) do
		ImGui.PushID(name)
		ImGui.BeginChildEx(name, vec2:new(childWidth, 200), ImGuiChildFlags.Borders, ImGuiWindowFlags.NoScrollbar)
		ImGui.SeparatorText(name)

		if (data.description) then
			ImGui.BeginChild("scrollRegion", 0, 97)
			ImGui.SetWindowFontScale(0.84)
			ImGui.TextWrapped(data.description)
			ImGui.SetWindowFontScale(1.0)
			ImGui.EndChild()
		end

		if (GUI:Button(_T("BSV2_DISPATCH"), { size = vec2:new(-1, 36) })) then
			BSV2:CallPrivateLimo(data)
			bRequested = true
		end
		ImGui.EndChild()
		ImGui.SameLineIfAvail(childWidth)
	end
	ImGui.EndDisabled()
end

---@param limo PrivateLimo
local function drawSpawnedLimo(limo)
	buttonSize.x         = math.max(buttonSize.x, ImGui.GetContentRegionAvail() * 0.45)
	local isPlayerInLimo = limo:IsPlayerInLimo()
	if (not isPlayerInLimo and not limo.isRemoteControlled) then
		if (GUI:Button(_T("GENERIC_WARP_INTO_VEH"), { size = buttonSize })) then
			limo:WarpPlayer()
		end

		ImGui.Text(_T("BSV2_LIMO_MORE_OPTS_TT"))
		return
	end

	local lang_idx = GVars.backend.language_index
	local maxwidth = labelWidths[lang_idx]
	if (not maxwidth) then
		maxwidth = measureTextWidth({
			_T("BSV2_LIMO_TAKE_CTRL"),
			_T("BSV2_LIMO_GIVE_CTRL"),
			_T("GENERIC_STOP"),
			_T("GENERIC_EMERGENCY_STOP"),
			_T("BSV2_ES_DRIVE_WP"),
			_T("BSV2_ES_DRIVE_OBJ"),
			_T("BSV2_ES_DRIVE_PROPERTY"),
			_T("BSV2_SEAT_CTRL_PREV"),
			_T("BSV2_SEAT_CTRL_NEXT"),
			_T("GENERIC_REPAIR"),
			_T("GENERIC_DISMISS"),
		}, 20)
		labelWidths[lang_idx] = maxwidth
	end

	if (maxwidth > buttonSize.x) then
		buttonSize.x = maxwidth
	end

	ImGui.BeginDisabled(limo.isRemoteControlled)
	ImGui.Spacing()

	ImGui.SeparatorText(_T("GENERIC_DRIVING_STYLE"))
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

	local isControlled = limo.isRemoteControlled
	local btnLabel     = isControlled and "BSV2_LIMO_GIVE_CTRL" or "BSV2_LIMO_TAKE_CTRL"
	local callback     = isControlled and limo.ReleaseControl or limo.TakeControl
	local tooltip      = isControlled and "BSV2_LIMO_GIVE_CTRL_TT" or "BSV2_LIMO_TAKE_CTRL_TT"

	if (GUI:Button(_T(btnLabel), { size = vec2:new((buttonSize.x * 2) + ImGui.GetStyle().ItemSpacing.x, buttonSize.y) })) then
		callback(limo)
	end
	GUI:Tooltip(_T(tooltip))

	local PV = LocalPlayer:GetVehiclePlayerIsIn()
	ImGui.BeginDisabled(PV ~= nil and PV:GetSpeed() <= 0.1 and limo:IsIdle())
	if (GUI:Button(_T("GENERIC_STOP"), { size = buttonSize })) then
		ThreadManager:Run(function() limo:Stop() end)
	end

	ImGui.SameLineIfAvail(maxwidth)
	if (GUI:Button(_T("GENERIC_EMERGENCY_STOP"), { size = buttonSize })) then
		ThreadManager:Run(function() limo:EmergencyStop() end)
	end
	ImGui.EndDisabled()

	if (GUI:Button(_T("BSV2_ES_DRIVE_WP"), { size = buttonSize })) then
		ThreadManager:Run(function(s)
			local v_Pos = Game.GetWaypointCoords()
			if (not v_Pos) then
				Notifier:ShowError("Billionaire Services", _T("GENERIC_TP_INVALID_COORDS_ERR"))
				return
			end

			limo:GoTo(v_Pos, s)
		end)
	end

	ImGui.SameLineIfAvail(maxwidth)
	if (GUI:Button(_T("BSV2_ES_DRIVE_OBJ"), { size = buttonSize })) then
		ThreadManager:Run(function(s)
			local b_Found, v_Pos = Game.GetObjectiveBlipCoords()
			if (not b_Found) then
				Notifier:ShowError("Billionaire Services", _T("GENERIC_TP_INVALID_COORDS_ERR"))
				return
			end

			limo:GoTo(v_Pos, s)
		end)
	end

	if (GUI:Button(_T("GENERIC_WANDER"), { size = buttonSize })) then
		ThreadManager:Run(function(s) limo:Wander(s) end)
	end

	ImGui.SameLineIfAvail(maxwidth)
	if (GUI:Button(_T("BSV2_ES_DRIVE_PROPERTY"), { size = buttonSize })) then
		ImGui.OpenPopup("##propertyCoords")
	end

	ImGui.EndDisabled()

	if (ImGui.BeginPopupModal("##propertyCoords", true, ImGuiWindowFlags.AlwaysAutoResize)) then
		local selected, pos = propertyDestSelector()
		if (selected and pos ~= nil) then
			Game.SetWaypointCoords(pos)
			ThreadManager:Run(function(s) limo:GoTo(pos, s) end)
			ImGui.CloseCurrentPopup()
		end

		ImGui.Separator()
		ImGui.Spacing()
		ImGui.TextWrapped(_T("BSV2_ES_DRIVE_PROPERTY_TEXT"))
		ImGui.EndPopup()
	end

	ImGui.BeginDisabled(limo.isRemoteControlled)
	ImGui.Spacing()
	ImGui.SeparatorText(_T("BSV2_SEAT_CTRL"))
	ImGui.Spacing()

	if (GUI:Button(_F("< %s", _T("BSV2_SEAT_CTRL_PREV")), { size = buttonSize })) then
		limo:ShuffleSeats(-1)
	end

	ImGui.SameLineIfAvail(maxwidth)

	if (GUI:Button(_F("%s >", _T("BSV2_SEAT_CTRL_NEXT")), { size = buttonSize })) then
		limo:ShuffleSeats(1)
	end

	ImGui.Spacing()
	ImGui.SeparatorText(_T("BSV2_RADIO_CTRL"))
	ImGui.Spacing()

	local radioBtnLabel = limo.radio.isOn and "GENERIC_TURN_OFF" or "GENERIC_TURN_ON"
	local handle        = limo:GetHandle()
	if (GUI:Button(_T(radioBtnLabel))) then
		ThreadManager:Run(function()
			AUDIO.SET_VEH_RADIO_STATION(handle, limo.radio.isOn and "OFF" or "RADIO_22_DLC_BATTLE_MIX1_RADIO")
		end)
	end

	if (limo.radio.isOn) then
		ImGui.SameLine()
		GUI:VehicleRadioCombo(handle, "limoRadioStations", limo.radio.stationName)
	end
	ImGui.EndDisabled()
end

local function drawSpawnedFooter()
	local limo = BSV2.ActiveServices.limo
	if (not limo) then return end

	ImGui.SetWindowFontScale(1.12)
	ImGui.SeparatorText(limo.name)
	ImGui.SetWindowFontScale(1.0)
	ImGui.Spacing()

	ImGui.BulletText(_F("Driver: %s", limo.driverName))
	ImGui.BulletText(_F("Status: %s", limo:GetTaskAsString()))
	ImGui.Separator()
	ImGui.Spacing()

	if (GUI:Button(_T("GENERIC_REPAIR"), { size = buttonSize })) then
		ThreadManager:Run(function()
			limo:Repair()
		end)
	end

	ImGui.SameLineIfAvail(buttonSize.x)

	if (GUI:Button(_T("GENERIC_DISMISS"), { size = buttonSize })) then
		BSV2:Dismiss(BSV2.SERVICE_TYPE.LIMO)
		bRequested = false
	end
end

---@return string tabName, function? footer
return function()
	local limo = BSV2.ActiveServices.limo
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
