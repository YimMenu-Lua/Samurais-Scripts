-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@param contextCallback GuiCallback
local function drawContextMenu(contextCallback)
	local pos_y = ImGui.GetCursorPosY()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - 30)
	ImGui.SetWindowFontScale(0.78)
	if (ImGui.SmallButton(" . . . ")) then
		ImGui.OpenPopup("##nameplate_context_menu")
	end
	ImGui.SetWindowFontScale(1.0)
	GUI:Tooltip(_T("GENERIC_OPTIONS_LABEL"))

	if (ImGui.BeginPopup("##nameplate_context_menu")) then
		pcall(contextCallback)
		ImGui.EndPopup()
	end
	ImGui.SetCursorPosY(pos_y)
end


---@param business BusinessFront
---@param args? { customName?: string, bgColor: Color, tpKeepVeh?: boolean, contextMenuCallback?: GuiCallback }
return function(business, args)
	args = args or {}
	if (not args.customName) then
		local GetCustomName = business.GetCustomName
		args.customName = (GetCustomName ~= nil) and GetCustomName(business) or business:GetName() or "NULL"
	end

	local custom_name = args.customName ---@type string
	ImGui.BeginChildEx("##nameplate",
		vec2:new(0, 130),
		ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding,
		ImGuiWindowFlags.NoScrollbar
	)

	local contextCallback = args.contextMenuCallback
	if (contextCallback) then
		drawContextMenu(contextCallback)
	end

	ImGui.SetWindowFontScale(1.18)
	local custom_name_width = ImGui.CalcTextSize(custom_name)
	local bg                = args.bgColor
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
	ImGui.SetWindowFontScale(1.0)

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
			LocalPlayer:Teleport(coords, args.tpKeepVeh)
		end

		ImGui.SameLine()
		if (GUI:Button(_T("GENERIC_SET_WAYPOINT"))) then
			Game.SetWaypointCoords(coords)
		end
	end
	ImGui.EndChild()
end
