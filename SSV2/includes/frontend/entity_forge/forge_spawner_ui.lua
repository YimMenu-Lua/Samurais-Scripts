-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local PedBrowser     = require("includes.services.asset_browsers.PedBrowser").new({
	show_preview        = true,
	show_gender_filters = true,
	show_type_filters   = true,
	max_entries         = 250
})

local VehicleBrowser = require("includes.services.asset_browsers.VehicleBrowser").new({
	show_preview              = true,
	show_class_filters        = true,
	show_manufacturer_filters = true,
	max_entries               = 250

})

local ObjectBrowser  = require("includes.services.asset_browsers.ObjectBrowser").new({
	show_preview = true,
	max_entries = 300
})


local childSize           = vec2:new(0, GVars.ui.window_size.y * 0.7)
local browser_region      = vec2:new(childSize.x, math.max(200, childSize.y - 220))
local selectedSidebarItem = Enums.eEntityType.Ped
local newEntityNameBuffer = ""

---@type (RawPedData|RawVehicleData|string)?
local selected_entity

local spawnerSidebarItems = {
	[Enums.eEntityType.Ped]     = "Peds",
	[Enums.eEntityType.Vehicle] = "Vehicles",
	[Enums.eEntityType.Object]  = "Objects",
}

local function DrawSpawnerSideBar()
	ImGui.SetNextWindowBgAlpha(0.0)
	ImGui.BeginChild("##sidebar", 160, childSize.y)
	ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 20)
	ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 40)
	ImGui.SetWindowFontScale(1.05)
	ImGui.SeparatorText("Game Entities")
	ImGui.SetWindowFontScale(1.0)
	ImGui.Dummy(1, 40)

	for i, tab in ipairs(spawnerSidebarItems) do
		local is_selected = (selectedSidebarItem == i)
		if (is_selected) then
			local r, g, b, a = ImGui.GetStyleColorVec4(ImGuiCol.ButtonActive)
			ImGui.PushStyleColor(ImGuiCol.Button, r, g, b, a)
		end

		if (GUI:Button(tab, { size = vec2:new(is_selected and 158 or 128, 35) })) then
			selectedSidebarItem = i
		end

		if (is_selected) then
			ImGui.PopStyleColor()
		end
	end

	ImGui.PopStyleVar(2)
	ImGui.EndChild()
end

local function DrawSpawnerItems()
	if (selectedSidebarItem == Enums.eEntityType.Object) then
		selected_entity = ObjectBrowser:Draw(browser_region)
	elseif (selectedSidebarItem == Enums.eEntityType.Vehicle) then
		selected_entity = VehicleBrowser:Draw(browser_region)
	elseif (selectedSidebarItem == Enums.eEntityType.Ped) then
		selected_entity = PedBrowser:Draw(browser_region)
	end
end

---@return string
local function GetSelectedEntityName()
	if (not selected_entity) then
		return string.random()
	end

	if (selectedSidebarItem == Enums.eEntityType.Object) then
		---@type string
		return selected_entity
	elseif (selectedSidebarItem == Enums.eEntityType.Vehicle) then
		return selected_entity.display_name
	elseif (selectedSidebarItem == Enums.eEntityType.Ped) then
		return Game.GetPedModelName(selected_entity.model_hash)
	end

	return string.random()
end

---@return joaat_t
local function GetSelectedEntityModel()
	if (not selected_entity) then return 0 end

	if (type(selected_entity) == "string") then
		return _J(selected_entity)
	end

	return selected_entity.model_hash
end

local function DrawFavoritePopup()
	if ImGui.BeginPopupModal("Add Favorite", ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.AlwaysAutoResize) then
		ImGui.Spacing()
		ImGui.SetNextItemWidth(400)
		newEntityNameBuffer, _ = ImGui.InputTextWithHint("##favname", "Name", newEntityNameBuffer, 128)
		ImGui.Dummy(1, 10)

		if (GUI:Button(_T("GENERIC_CONFIRM"))) then
			if (not selected_entity) then return end
			local model = GetSelectedEntityModel()
			EntityForge:AddModelToFavorites(model, newEntityNameBuffer, selectedSidebarItem)
			newEntityNameBuffer = ""
			ImGui.CloseCurrentPopup()
		end

		ImGui.SameLine()

		if GUI:Button(_T("GENERIC_CANCEL")) then
			newEntityNameBuffer = ""
			ImGui.CloseCurrentPopup()
		end

		ImGui.EndPopup()
	end
end

return function()
	DrawSpawnerSideBar()

	ImGui.SameLine()
	ImGui.BeginChildEx("##items", childSize, ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding)
	DrawSpawnerItems()

	ImGui.Spacing()
	ImGui.BeginDisabled(not selected_entity)
	if (GUI:Button(_T("GENERIC_SPAWN"), { size = vec2:new(120, 35) })) then
		ThreadManager:Run(function()
			if (not selected_entity) then return end
			local preview_pos = PreviewService:GetCurrentPosition()
			local pos         = preview_pos or LocalPlayer:GetOffsetInWorldCoords(1, 5, 0)
			local model       = GetSelectedEntityModel()
			local name        = GetSelectedEntityName()
			EntityForge:CreateEntity(model, name, selectedSidebarItem, pos)
		end)
	end

	ImGui.SameLine()
	local text_width = ImGui.CalcTextSize("Add To Favorites")
	if (GUI:Button("Add To Favorites", { size = vec2:new(text_width + 20, 35) })) then
		newEntityNameBuffer = ""
		ImGui.OpenPopup("Add Favorite")
	end
	ImGui.EndDisabled()

	DrawFavoritePopup()

	ImGui.EndChild()
	ImGui.Dummy(1, 10)
	ImGui.SeparatorText("Preferences")

	EntityForge.EntityGunEnabled = GUI:Checkbox("Entity Grabber", EntityForge.EntityGunEnabled)

	ImGui.SameLine()
	ImGui.Spacing()
	ImGui.SameLine()

	ImGui.BeginDisabled(EntityForge:IsEmpty())
	if (GUI:Button("Cleanup Everything")) then
		EntityForge:Cleanup()
	end
	ImGui.EndDisabled()
end
