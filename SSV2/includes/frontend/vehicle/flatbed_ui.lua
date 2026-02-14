-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Flatbed     = require("includes.features.vehicle.flatbed")
local flatbed_tab = GUI:RegisterNewTab(Enums.eTabID.TAB_VEHICLE, "SUBTAB_FLATBED", nil, nil, true)

flatbed_tab:AddLoopedCommand("FLTBD_MAIN_CB",
	"features.flatbed.enabled",
	function()
		Flatbed:OnTick()
	end,
	function()
		Flatbed:Reset()
	end,
	nil,
	true,
	true
)

flatbed_tab:RegisterGUI(function()
	flatbed_tab:GetGridRenderer():Draw()
	ImGui.Separator()

	if (not GVars.features.flatbed.enabled) then
		return
	end

	ImGui.Spacing()
	if (not LocalPlayer:GetVehicle().m_is_flatbed) then
		ImGui.TextWrapped(_T("FTLBD_GET_IN_MSG"))
		if (GUI:Button(_T("GENERIC_SPAWN"))) then
			Flatbed:Spawn()
		end
		return
	end
	ImGui.Dummy(1, 10)
	ImGui.BulletText(Flatbed.displayText)
	ImGui.Dummy(1, 10)

	GVars.features.flatbed.show_towing_position, _ = GUI:CustomToggle(_T("FLTBD_SHOW_TOWPOS_CB"),
		GVars.features.flatbed.show_towing_position
	)
	GUI:HelpMarker(_T("FLTBD_SHOW_TOWPOS_TT"))

	GVars.features.flatbed.show_esp, _ = GUI:CustomToggle(_T("FLTBD_SHOW_TOWBOX_CB"), GVars.features.flatbed.show_esp)
	GUI:HelpMarker(_T("FLTBD_SHOW_TOWBOX_TT"))

	GVars.features.flatbed.tow_everything, _ = GUI:CustomToggle(_T("FLTBD_TOW_ALL_CB"),
		GVars.features.flatbed.tow_everything
	)
	GUI:HelpMarker(_T("FLTBD_TOW_ALL_TT"))

	ImGui.Dummy(1, 10)

	if (GUI:Button(not Flatbed.m_towed_vehicle and _T("FLTBD_TOW_BTN") or _T("GENERIC_DETACH"), { size = vec2:new(80, 40) })) then
		ThreadManager:Run(function()
			Flatbed:OnKeyPress()
		end)
	end

	if (Flatbed.m_towed_vehicle) then
		ImGui.Dummy(1, 5)
		ImGui.SeparatorText(_T("FLTBD_ADJUST_POS_TXT"))
		ImGui.SetWindowFontScale(0.8)
		ImGui.BulletText(_T("FLTBD_ADJUST_POS_TT"))
		ImGui.BulletText(_T("FLTBD_FAST_ADJUST_TXT"))
		ImGui.SetWindowFontScale(1.0)
		ImGui.Dummy(1, 10)

		ImGui.PushButtonRepeat(true)
		ImGui.InvisibleButton("##pad_up", 30, 30)
		ImGui.SameLine()

		if ImGui.ArrowButton("##Up", 2) then
			Flatbed:MoveAttachment(0.0, 0.0, 0.01)
		end

		if ImGui.ArrowButton("##Left", 0) then
			Flatbed:MoveAttachment(0.0, 0.01, 0.0)
		end

		ImGui.SameLine()
		ImGui.InvisibleButton("##pad_mid", 30, 30)
		ImGui.SameLine()

		if ImGui.ArrowButton("##Right", 1) then
			Flatbed:MoveAttachment(0.0, -0.01, 0.0)
		end

		ImGui.InvisibleButton("##pad_up", 30, 30)
		ImGui.SameLine()
		if ImGui.ArrowButton("##Down", 3) then
			Flatbed:MoveAttachment(0.0, 0.0, -0.01)
		end
		ImGui.PopButtonRepeat()
	end
end)
