-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@type Action?
local selectedAction
local sharedDrawFuncs     = require("includes.frontend.yim_actions.shared_draw_funcs")
local selectedSidebarItem = 1


local t_ActionsSidebarItems <const> = {
	{
		label    = "Animations",
		callback = sharedDrawFuncs.DrawAnims,
	},
	{
		label    = "Scenarios",
		callback = sharedDrawFuncs.DrawScenarios,
	},
	-- {
	--     label = "Scenes",
	--     callback = sharedDrawFuncs.DrawScenes
	-- },
	{
		label    = "Favorites",
		callback = sharedDrawFuncs.DrawFavorites
	},
	{
		label    = "History",
		callback = sharedDrawFuncs.DrawHistory
	},
}

local function DrawSidebarItems()
	local selectedTab = t_ActionsSidebarItems[selectedSidebarItem]
	if (selectedTab and selectedTab.callback) then
		selectedAction = selectedTab.callback()
	end
end

local function DrawActionsSidebar()
	ImGui.SetNextWindowBgAlpha(0.0)
	ImGui.BeginChild("##actios_sidebar", 160, GVars.ui.window_size.y * 0.7)
	ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 20)
	ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 40)
	ImGui.Dummy(1, 100)

	for i, tab in ipairs(t_ActionsSidebarItems) do
		local is_selected = (selectedSidebarItem == i)
		if (is_selected) then
			local r, g, b, a = ImGui.GetStyleColorVec4(ImGuiCol.ButtonActive)
			ImGui.PushStyleColor(ImGuiCol.Button, r, g, b, a)
		end

		if (ImGui.Button(tab.label, is_selected and 150 or 128, 35)) then
			GUI:PlaySound("Nav")
			if (selectedSidebarItem ~= i) then
				selectedAction = nil
			end
			selectedSidebarItem = i
		end

		if (is_selected) then
			ImGui.PopStyleColor()
		end
	end

	ImGui.PopStyleVar(2)
	ImGui.SetWindowFontScale(0.75)
	local region        = vec2:new(ImGui.GetContentRegionAvail())
	local s_SidebarTip  = _F(_T("YAV3_STOP_BTN_HINT"), GVars.keyboard_keybinds.stop_anim)
	local _, textHeight = ImGui.CalcTextSize(s_SidebarTip, false, region.x)
	ImGui.SetCursorPos(0.0, ImGui.GetCursorPosY() + region.y - textHeight - 10)
	ImGui.TextWrapped(s_SidebarTip)
	ImGui.SetWindowFontScale(1.0)
	ImGui.EndChild()
end

return function()
	ImGui.BeginGroup()
	DrawActionsSidebar()

	ImGui.SameLine()
	ImGui.BeginChildEx("##main_player",
		vec2:new(0, GVars.ui.window_size.y * 0.7),
		ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding
	)

	DrawSidebarItems()
	ImGui.EndChild()
	ImGui.EndGroup()

	sharedDrawFuncs.DrawPlayerFooter(selectedAction)
	return selectedAction
end
