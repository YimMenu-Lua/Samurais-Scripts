-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@type Action?
local selectedAction
local ActionBrowser   = require("includes.services.asset_browsers.ActionBrowser")
local currentTabName  = ""
local previousTabName = ""


---@type table<ActionCategory, ActionBrowser>
local Browsers <const> = {
	scenarios = ActionBrowser.new(Enums.eActionType.SCENARIO),
	scenes    = ActionBrowser.new(Enums.eActionType.SCENE),
	anims     = ActionBrowser.new(Enums.eActionType.ANIM, {
		show_category_filters = true,
		show_type_filters     = true,
	}),
}

local function OnTabItemSwitch()
	if (currentTabName ~= previousTabName) then
		GUI:PlaySound(GUI.Sounds.Nav)
		previousTabName = currentTabName
		selectedAction  = nil
	end
end

---@param category ActionCategory
local function ListFavoritesByCategory(category)
	local cat = YimActions.Favorites[category]
	if (not cat or next(cat) == nil) then
		ImGui.TextWrapped(_F("You don't have any saved %s.", category or "actions of this type"))
		return
	end

	local browser = Browsers[category]
	if (not browser) then
		GUI:Text("No suitable browser to draw %s list!", { fmt = { category }, color = Color.RED })
		return
	end

	selectedAction = browser:SwitchMode("favorites", cat):Draw()
end

local function DrawFavorites()
	local favorites = YimActions.Favorites
	if (not favorites or next(favorites) == nil) then
		ImGui.Dummy(1, 80)
		ImGui.TextWrapped("Nothig saved yet.")
		return
	end

	if (ImGui.BeginTabBar("##AnimationsTabBar")) then
		if (ImGui.BeginTabItem("Animations")) then
			currentTabName = "anims"
			ListFavoritesByCategory("anims")
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem("Scenarios")) then
			currentTabName = "scenarios"
			ListFavoritesByCategory("scenarios")
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem("Scenes")) then
			currentTabName = "scenes"
			-- ListFavoritesByCategory("scenes") -- Disabled. Experimental.
			ImGui.Dummy(1, 60)
			ImGui.TextDisabled(_T("GENERIC_UNAVAILABLE"))
			ImGui.EndTabItem()
		end

		OnTabItemSwitch()
		ImGui.EndTabBar()
	end

	return selectedAction
end

local function DrawHistory()
	local count = YimActions.LastPlayed.count
	if (count == 0) then
		ImGui.TextWrapped("Animations, scenarios, and scenes you play will appear here.")
		return
	end

	if (GUI:Button(_T("GENERIC_CLEAR"))) then
		YimActions:ClearPlayHistory()
	end
	ImGui.Separator()

	if (count > 1) then
		local sort_mode, clicked = ImGui.Combo(_T("GENERIC_LIST_SORT"), YimActions.LastPlayed.sort_mode, "Time\0Type\0Label\0")
		if (clicked) then
			YimActions:SortPlayHistory(sort_mode)
		end
	end

	if (ImGui.BeginListBox("##playHistory", -1, -1)) then
		local button_width      = 30
		local selectable_width  = ImGui.GetContentRegionAvail() - 80
		local selectable_height = ImGui.GetTextLineHeight()
		local to_eemove         = nil

		for i, entry in ipairs(YimActions.LastPlayed.data) do
			ImGui.SetWindowFontScale(0.8)
			ImGui.TextDisabled(DateTime(entry.timestamp):Format("%H:%M"))
			ImGui.SetWindowFontScale(1.0)

			local action = entry.action
			ImGui.SameLine()
			ImGui.Selectable(entry.fmt, (selectedAction == action), 0, selectable_width, selectable_height)
			if (ImGui.IsItemClicked()) then
				selectedAction = action
			end

			local rectMin = vec2:new(ImGui.GetItemRectMin())
			local rectMax = vec2:new(ImGui.GetItemRectMax())
			local hovered = ImGui.IsMouseHoveringRect(rectMin.x, rectMin.y, rectMax.x + button_width, rectMax.y)
			if (hovered) then
				ImGui.SameLine()
				if (ImGui.SmallButton(" x ")) then
					to_eemove = i
				end
				GUI:Tooltip(_T("GENERIC_DELETE"))
			end
		end

		if (to_eemove) then
			YimActions:RemoveFromHistory(to_eemove)
		end
		ImGui.EndListBox()
	end

	return selectedAction
end

local function DrawAnims()
	return Browsers.anims:ResetMode():Draw()
end

local function DrawScenarios()
	return Browsers.scenarios:ResetMode():Draw()
end

local function DrawScenes()
	return Browsers.scenes:ResetMode():Draw()
end

return {
	DrawAnims        = DrawAnims,
	DrawScenarios    = DrawScenarios,
	DrawScenes       = DrawScenes,
	DrawFavorites    = DrawFavorites,
	DrawHistory      = DrawHistory,
	DrawPlayerFooter = require("includes.frontend.yim_actions.player_footer_ui"),
}
