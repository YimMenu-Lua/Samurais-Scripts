-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local reservedKeys <const> = {
	kb   = Set.new(0x01, 0x07, 0x0A, 0x0B, 0x1B, 0x24, 0x2C, 0x2D, 0x46, 0x5B, 0x5C, 0x5E),
	gpad = Set.new(23, 24, 25, 71, 75)
}


local keyName, keyCode
local currentKeyName = ""
local _reserved      = false
local button_size    = vec2:new(120, 32)

local function GetCurrentKey()
	local _, code, name = KeyManager:IsAnyKeyPressed()
	if (code == eVirtualKeyCodes.VK_LBUTTON
			or code == eVirtualKeyCodes.VK_RBUTTON
			or code == eVirtualKeyCodes.ALT
		) then
		return
	end

	return code, name
end

---@param gvarKey string
---@param isController? boolean
local function DrawKeybinds(gvarKey, isController)
	local label               = gvarKey:replace("_", " "):titlecase()
	local main_path           = isController and "gamepad_keybinds" or "keyboard_keybinds"
	local current_path        = _F("%s.%s", main_path, gvarKey)
	local current_key         = table.get_nested_key(GVars, current_path)
	local key_container_width = 160
	local reset_button_width  = 80
	local style               = ImGui.GetStyle()

	ImGui.BulletText(label)
	local avail_x, _ = ImGui.GetContentRegionAvail()

	if (isController) then
		currentKeyName = current_key.name
	else
		currentKeyName = current_key
	end

	ImGui.SameLine()
	ImGui.SetCursorPosX(
		avail_x
		- key_container_width
		- reset_button_width
		- style.ItemSpacing.x
	)

	ImGui.SetNextItemWidth(key_container_width)
	currentKeyName, _ = ImGui.InputText(_F("##%s", label), currentKeyName, 16, ImGuiInputTextFlags.ReadOnly)

	if GUI:IsItemClicked(0) then
		ImGui.OpenPopup(label)
		Backend.disable_input = true
	end

	ImGui.SameLine()
	ImGui.BeginDisabled(keyCode == 0)
	if ImGui.Button(_F("%s##%s", _T("GENERIC_RESET"), label), reset_button_width, 32) then
		GUI:PlaySound("Delete")
		local newKey = isController and { name = "Unbound", code = 0 } or "Unbound"
		table.set_nested_key(GVars, current_path, newKey)
	end
	ImGui.EndDisabled()

	ImGui.SetNextWindowSize(400, 220)
	if ImGui.BeginPopupModal(
			label,
			ImGuiWindowFlags.AlwaysAutoResize
			| ImGuiWindowFlags.NoTitleBar
			| ImGuiWindowFlags.NoMove
		) then
		local size   = vec2:new(ImGui.GetWindowSize())
		local _, pos = GUI:GetNewWindowSizeAndCenterPos(0.5, 0.5, size)
		local region = vec2:new(ImGui.GetContentRegionAvail())
		ImGui.SetWindowPos(label, pos.x, pos.y, ImGuiCond.Always)

		local reserved_set = isController and reservedKeys.gpad or reservedKeys.kb
		if ImGui.SmallButton("X") then
			keyCode, keyName = nil, nil
			Backend.disable_input = false
			ImGui.CloseCurrentPopup()
		end

		ImGui.Separator()
		ImGui.Dummy(1, 10)

		if not keyName then
			ImGui.Text(ImGui.TextSpinner(_T("SETTINGS_HOTKEY_WAIT"), 10, ImGuiSpinnerStyle.BOUNCE_DOTS))

			if isController then
				keyCode, keyName = Game.GetKeyPressed()
			else
				keyCode, keyName = GetCurrentKey()
			end
		else
			_reserved = reserved_set:Contains(keyCode)

			if not _reserved then
				local valueBarSize = vec2:new(button_size.x, ImGui.GetTextLineHeightWithSpacing())
				ImGui.Text(_T("SETTINGS_HOTKEY_FOUND"))
				ImGui.SameLine()
				ImGui.SetCursorPosX(size.x - valueBarSize.x - style.WindowPadding.x)
				ImGui.ValueBar(
					"##keyName",
					0,
					valueBarSize,
					ImGuiValueBarFlags.NONE,
					{ fmt = keyName }
				)
			else
				GUI:Text(_T("SETTINGS_HOTKEY_RESERVED"), { color = Color("red"), alpha = 0.86, wrap_pos = size.x })
			end
		end
		ImGui.SetCursorPosY(region.y - button_size.y + style.WindowPadding.y)

		if (keyCode and keyName and not _reserved) then
			if GUI:Button(_T("GENERIC_CONFIRM"), { size = button_size }) then
				if not isController then
					KeyManager:UpdateKeybind(current_key, { id = keyName })
				end

				local newKey = isController and { name = keyName, code = keyCode } or keyName
				table.set_nested_key(GVars, current_path, newKey)
				keyCode, keyName = nil, nil
				Backend.disable_input = false
				ImGui.CloseCurrentPopup()
			end
			ImGui.SameLine()
			ImGui.SetCursorPosX(size.x - button_size.x - style.WindowPadding.x)
		end

		if (keyName) then
			if GUI:Button(_T("GENERIC_CLEAR"), { size = button_size }) then
				keyCode, keyName = nil, nil
			end
		end
		ImGui.EndPopup()
	end
end

return function()
	if (ImGui.BeginTabBar("##ss_keybinds")) then
		if (ImGui.BeginTabItem(_T("SETTINGS_KEYBINDS_KEYBOARD"))) then
			for key in pairs(GVars.keyboard_keybinds) do
				DrawKeybinds(key, false)
			end
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem(_T("SETTINGS_KEYBINDS_CONTROLLER"))) then
			for key in pairs(GVars.gamepad_keybinds) do
				DrawKeybinds(key, true)
			end
			ImGui.EndTabItem()
		end
		ImGui.EndTabBar()
	end
end
