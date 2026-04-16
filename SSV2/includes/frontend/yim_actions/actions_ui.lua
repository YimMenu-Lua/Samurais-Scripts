-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@type Action?
local selectedAction
local sharedDrawFuncs  = require("includes.frontend.yim_actions.shared_draw_funcs")
local sidebarItemIndex = 1
local sidebarTipIndex  = 1


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

---@type array<fun(): string>
local SideBarTips <const> = {
	function() return _F(_T("YAV3_STOP_BTN_HINT"), GVars.keyboard_keybinds.stop_anim) end,
	function() return _F(_T("YAV3_SYMBOL_DEFS_HINT"), "[*]", "[C]", "[U]") end,
	function() return _T("YAV3_LIST_VIEW_HINT") end,
	function() return _T("YAV3_VEH_ANIM_HINT") end,
}; local tipsCount = #SideBarTips

local function DrawTipsIndicator(currentIndex)
	ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 1, 1)
	for i = 1, tipsCount do
		ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 10)
		ImGui.BeginDisabled(i ~= currentIndex)
		ImGui.Text(".")
		ImGui.EndDisabled()

		if (i < tipsCount) then
			ImGui.SameLine()
		end
	end
	ImGui.PopStyleVar()
end

local function DrawSidebarItems()
	local selectedTab = t_ActionsSidebarItems[sidebarItemIndex]
	if (selectedTab and selectedTab.callback) then
		selectedAction = selectedTab.callback(selectedTab.label)
	end
end

local function DrawSidebar()
	ImGui.SetNextWindowBgAlpha(0.0)
	ImGui.BeginChild("##actions_sidebar", 160, GVars.ui.window_size.y * 0.7)
	ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 20)
	ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 40)
	ImGui.Dummy(1, 100)

	for i, tab in ipairs(t_ActionsSidebarItems) do
		local is_selected = (sidebarItemIndex == i)
		if (is_selected) then
			local r, g, b, a = ImGui.GetStyleColorVec4(ImGuiCol.ButtonActive)
			ImGui.PushStyleColor(ImGuiCol.Button, r, g, b, a)
		end

		if (ImGui.Button(tab.label, is_selected and 150 or 128, 35)) then
			GUI:PlaySound("Nav")
			if (sidebarItemIndex ~= i) then
				selectedAction = nil
			end
			sidebarItemIndex = i
		end

		if (is_selected) then
			ImGui.PopStyleColor()
		end
	end
	ImGui.PopStyleVar(2)

	local region     = vec2:new(ImGui.GetContentRegionAvail())
	local sidebarTip = SideBarTips[sidebarTipIndex]()
	ImGui.SetWindowFontScale(0.70)
	local _, textHeight = ImGui.CalcTextSize(sidebarTip, false, region.x)
	ImGui.SetCursorPos(0.0, math.max(ImGui.GetCursorPosY(), ImGui.GetCursorPosY() + region.y - textHeight - 25))
	ImGui.TextWrapped(sidebarTip)
	if (ImGui.SmallButton("<    ")) then
		GUI:PlaySound(GUI.Sounds.Nav)
		if (sidebarTipIndex == 1) then
			sidebarTipIndex = #SideBarTips
		else
			sidebarTipIndex = sidebarTipIndex - 1
		end
	end
	GUI:Tooltip(_T("GENERIC_PREVIOUS"))

	ImGui.SameLine()
	ImGui.SetWindowFontScale(1.25)
	DrawTipsIndicator(sidebarTipIndex)
	ImGui.SetWindowFontScale(0.70)

	ImGui.SameLine()
	if (ImGui.SmallButton("    >")) then
		GUI:PlaySound(GUI.Sounds.Nav)
		if (sidebarTipIndex == #SideBarTips) then
			sidebarTipIndex = 1
		else
			sidebarTipIndex = sidebarTipIndex + 1
		end
	end
	GUI:Tooltip(_T("GENERIC_NEXT"))
	ImGui.SetWindowFontScale(1.0)
	ImGui.EndChild()
end

return function()
	ImGui.BeginGroup()
	DrawSidebar()

	ImGui.SameLine()
	ImGui.BeginChildEx("##yim_actions_main",
		vec2:new(0, GVars.ui.window_size.y * 0.7),
		ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding
	)

	DrawSidebarItems()
	ImGui.EndChild()
	ImGui.EndGroup()

	sharedDrawFuncs.DrawPlayerFooter(selectedAction)
	return selectedAction
end
