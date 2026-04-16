-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@param business BusinessFront
---@param custom_name string
---@param bg? Color
---@param tpKeepVeh? boolean
return function(business, custom_name, bg, tpKeepVeh)
	ImGui.BeginChildEx("##nameplate",
		vec2:new(0, 130),
		ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding,
		ImGuiWindowFlags.NoScrollbar
	)

	ImGui.SetWindowFontScale(1.18)
	local custom_name_width = ImGui.CalcTextSize(custom_name)
	ImGui.SetCursorPosX((ImGui.GetContentRegionAvail() - custom_name_width) * 0.5)
	if (bg) then
		ImGui.TextColored(bg.r, bg.g, bg.b, bg.a, custom_name)
	else
		ImGui.Text(custom_name)
	end

	ImGui.Spacing()
	ImGui.SetWindowFontScale(0.8)
	local prop_name = business:GetName()
	if (prop_name == custom_name) then
		ImGui.Text("")
	else
		local prop_name_width = ImGui.CalcTextSize(prop_name)
		ImGui.SetCursorPosX((ImGui.GetContentRegionAvail() - prop_name_width) * 0.5)
		ImGui.Text(prop_name)
	end
	ImGui.SetWindowFontScale(1)

	local coords = business:GetCoords()
	local style  = ImGui.GetStyle()
	if (coords) then
		local tp_label       = _T("GENERIC_TELEPORT")
		local wp_label       = _T("GENERIC_SET_WAYPOINT")
		local tp_label_width = ImGui.CalcTextSize(tp_label)
			+ ImGui.CalcTextSize(wp_label)
			+ style.ItemSpacing.x
			+ (style.FramePadding.x * 4)

		ImGui.SetCursorPosX((ImGui.GetContentRegionAvail() - tp_label_width) * 0.5)
		if (GUI:Button(_T("GENERIC_TELEPORT"))) then
			LocalPlayer:Teleport(coords, tpKeepVeh)
		end

		ImGui.SameLine()
		if (GUI:Button(_T("GENERIC_SET_WAYPOINT"))) then
			Game.SetWaypointCoords(coords)
		end
	end
	ImGui.EndChild()
end
