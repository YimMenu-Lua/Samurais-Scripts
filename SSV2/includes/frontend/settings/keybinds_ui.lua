-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local KeyBindEditorUI = require("includes.frontend.helpers.KeybindEditorUI").new()
local selectedType    = 0
local searchBuff      = ""
local defaultKeybinds = Serializer:GetDefaultConfig().keybinds

---@param mainKey "keybinds"|"quick_toggle_keybinds"
---@param height float
---@param translateLabel boolean
local function drawKeybindItems(mainKey, height, translateLabel)
	local list = GVars[mainKey] ---@type table<string, Keybind>
	if (not list) then return end

	ImGui.BeginTabBar(mainKey)
	if (ImGui.BeginTabItem(_T("SETTINGS_KEYBINDS_KEYBOARD"))) then
		local count = 0
		local path  = mainKey .. ".keyboard"
		ImGui.SetNextWindowBgAlpha(0.0)
		ImGui.BeginChildEx(path, vec2:new(0, height), ImGuiChildFlags.None, ImGuiWindowFlags.AlwaysUseWindowPadding)
		for k, v in pairs(list) do
			local keybindName = v:GetName()
			keybindName       = translateLabel and _T(keybindName) or keybindName
			if (searchBuff ~= "" and not k:lower():find(searchBuff) or not keybindName:lower():find(searchBuff)) then
				goto continue
			end

			KeyBindEditorUI:DrawKey(v, false, { defaultKeybind = defaultKeybinds[k], translateLabel = translateLabel })
			count = count + 1
			::continue::
		end

		if (count == 0) then
			ImGui.Text("Wow! Such empty!")
		end
		ImGui.EndChild()
		ImGui.EndTabItem()
	end

	if (ImGui.BeginTabItem(_T("SETTINGS_KEYBINDS_CONTROLLER"))) then
		local count = 0
		local path  = mainKey .. ".controller"
		ImGui.SetNextWindowBgAlpha(0.0)
		ImGui.BeginChildEx(path, vec2:new(0, height), ImGuiChildFlags.None, ImGuiWindowFlags.AlwaysUseWindowPadding)
		for k, v in pairs(list) do
			local keybindName = v:GetName()
			keybindName       = translateLabel and _T(keybindName) or keybindName
			if (searchBuff ~= "" and not k:lower():find(searchBuff) or not keybindName:lower():find(searchBuff)) then
				goto continue
			end

			KeyBindEditorUI:DrawKey(v, true, { defaultKeybind = defaultKeybinds[k], translateLabel = translateLabel })
			count = count + 1

			::continue::
		end

		if (count == 0) then
			ImGui.Text("Wow! Such empty!")
		end
		ImGui.EndChild()
		ImGui.EndTabItem()
	end
	ImGui.EndTabBar()
end

return function()
	selectedType = ImGui.Combo("##type", selectedType, "Feature Keybinds\0Quick Toggle Keybinds\0")
	ImGui.Spacing()
	ImGui.Separator()
	ImGui.Spacing()

	searchBuff = ImGui.SearchBar("##searchKeybinds", searchBuff)
	ImGui.Spacing()

	local maxHeight = GVars.ui.window_size.y * 0.7
	if (selectedType == 0) then
		drawKeybindItems("keybinds", maxHeight, false)
	else
		drawKeybindItems("quick_toggle_keybinds", maxHeight, true)
	end
end
