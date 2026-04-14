-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local ActionBrowser          = require("includes.services.asset_browsers.ActionBrowser")
local ClipsetBrowser         = ActionBrowser.new(Enums.eActionType.CLIPSET)
local clipsetCategory        = 0
local clipsetsGithub         = "https://github.com/DurtyFree/gta-v-data-dumps/blob/master/movementClipsetsCompact.json"
local githubLinkColor        = "#0000EE"
local jsonClipsetListCreated = false
local selectedClipset        = nil
local jsonArray              = {}

local function GetMovementClipsetsFromJson()
	jsonClipsetListCreated = false
	local temp = Serializer:ReadFromFile("movementClipsetsCompact.json")
	if (type(temp) ~= "table") then
		Notifier:ShowError("YimActions",
			"Failed to read clipset data from Json. Are you use you have the correct file?",
			true, 5
		)
		return
	end

	ThreadManager:Run(function()
		jsonArray = temp
		table.sort(jsonArray, function(a, b)
			return a.Name < b.Name
		end)
		yield(400)
		jsonClipsetListCreated = (#jsonArray > 0)
	end)
end

local function DrawCustomMovementClipsets()
	local __t = ClipsetBrowser:ResetMode():Draw()
	selectedClipset = __t and __t.data or nil
end

local function DrawJsonMovementClipsets()
	if (#jsonArray == 0) then
		local exists = io.exists("movementClipsetsCompact.json")
		if (not exists) then
			ImGui.TextWrapped("You must download the clipsets Json file and save it to the 'scripts_config/samurais_scripts' folder.")
			ImGui.SetWindowFontScale(0.8)
			GUI:Text(clipsetsGithub, { color = Color(githubLinkColor) })
			ImGui.SetWindowFontScale(1.0)
			GUI:Tooltip("Right click to copy the link.")

			githubLinkColor = ImGui.IsItemHovered() and "#551A8B" or "#0000EE"

			if (ImGui.IsItemClicked(1)) then
				GUI:PlaySound("Click")
				GUI:SetClipBoardText(clipsetsGithub)
			end
		end

		ImGui.Dummy(1, 10)

		ImGui.BeginDisabled(not exists)
		if (GUI:Button("Read From Json")) then
			GetMovementClipsetsFromJson()
		end
		ImGui.EndDisabled()
	else
		if (not jsonClipsetListCreated) then
			ImGui.TextDisabled(ImGui.TextSpinner(_T("GENERIC_WAIT_LABEL"), 7, ImGuiSpinnerStyle.DOTS))
			ImGui.Spacing()
		end

		ImGui.BeginDisabled(not jsonClipsetListCreated)
		local __t = ClipsetBrowser:SwitchMode("other", jsonArray):Draw()
		ImGui.EndDisabled()

		selectedClipset = __t and __t.data or nil
	end
end

local function DrawFavoriteMovementClipsets()
	local favorites = YimActions.Favorites.clipsets
	if (not favorites or next(favorites) == nil) then
		ImGui.TextWrapped(("You don't have any saved clipsets."))
		return
	end

	local __t = ClipsetBrowser:SwitchMode("favorites", favorites):Draw()
	selectedClipset = __t and __t.data or nil
end

return function()
	ImGui.Spacing()
	ImGui.Spacing()
	clipsetCategory, _ = ImGui.RadioButton("Custom Movements", clipsetCategory, 0)

	ImGui.SameLine()
	ImGui.Dummy(10, 1)
	ImGui.SameLine()

	clipsetCategory, _ = ImGui.RadioButton("All Movement Clipsets", clipsetCategory, 1)
	ImGui.SameLine()
	ImGui.Dummy(10, 1)
	ImGui.SameLine()

	clipsetCategory, _ = ImGui.RadioButton("Favorites", clipsetCategory, 2)

	ImGui.BeginChildEx("##movementClipsets", vec2:new(0, GVars.ui.window_size.y * 0.6), ImGuiChildFlags.Borders)
	if (clipsetCategory == 0) then
		DrawCustomMovementClipsets()
	elseif (clipsetCategory == 1) then
		DrawJsonMovementClipsets()
	elseif (clipsetCategory == 2) then
		DrawFavoriteMovementClipsets()
	end
	ImGui.EndChild()

	ImGui.BeginChildEx("##mvmts_footer", vec2:new(0, 65), ImGuiChildFlags.Borders)
	ImGui.BeginDisabled(not selectedClipset)
	if (GUI:Button(_T("GENERIC_APPLY"), { size = vec2:new(80, 35) })) then
		if (not selectedClipset) then return end
		LocalPlayer:SetMovementClipset(selectedClipset, (clipsetCategory == 1))
	end
	ImGui.EndDisabled()

	ImGui.SameLine()

	if (ImGui.Button(_T("GENERIC_RESET"), 80, 35)) then
		GUI:PlaySound("Cancel")
		LocalPlayer:ResetMovementClipsets()
	end
	ImGui.EndChild()
end
