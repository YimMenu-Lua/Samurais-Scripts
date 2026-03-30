-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local ReservedKeys <const>  = {
	kb   = Set.new(0x01, 0x07, 0x0A, 0x0B, 0x1B, 0x24, 0x2C, 0x2D, 0x46, 0x5B, 0x5C, 0x5E),
	gpad = Set.new(23, 24, 25, 71, 75)
}

local NoUnbindKeys <const>  = Set.new("gui_toggle")
local DefaultConfig <const> = Serializer:GetDefaultConfig()
local keyName, keyCode
local currentKeyName        = ""
local _reserved             = false
local key_container_size    = vec2:new(160, 32)
local button_size           = vec2:new(120, 32)


local function GetCurrentKey()
	local _, code, name = KeyManager:IsAnyKeyPressed()
	if (code == eVirtualKeyCodes.VK_LBUTTON
			or code == eVirtualKeyCodes.VK_RBUTTON
		-- or code == eVirtualKeyCodes.ALT
		) then
		return
	end

	return code, name
end

local function IsDefault(current_key, default_key, isController)
	if (type(current_key) ~= type(default_key)) then
		return false
	end

	if (isController) then
		return current_key.name == default_key.name
	end

	return current_key == default_key
end

---@param gvarKey string
---@param isController? boolean
local function DrawKeybind(gvarKey, isController)
	local label               = gvarKey:replace("_", " "):titlecase()
	local main_path           = isController and "gamepad_keybinds" or "keyboard_keybinds"
	local current_path        = _F("%s.%s", main_path, gvarKey)
	local current_key         = table.get_nested_key(GVars, current_path)
	local default_key         = table.get_nested_key(DefaultConfig, current_path)
	local style               = ImGui.GetStyle()
	local framePaddingX       = style.FramePadding.x
	local unbind_label        = _T("SETTINGS_KEYBINDS_UNBIND")
	local reset_label         = _T("GENERIC_RESET")
	local unbind_button_width = ImGui.CalcTextSize(unbind_label) + (framePaddingX * 2)
	local reset_button_width  = ImGui.CalcTextSize(reset_label) + (framePaddingX * 2)

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
		- key_container_size.x
		- unbind_button_width
		- reset_button_width
		- (style.ItemSpacing.x * 2)
	)

	if (ImGui.Button(_F("%s##%s", currentKeyName, label), key_container_size.x, key_container_size.y)) then
		GUI:PlaySound(GUI.Sounds.Click)
		ImGui.OpenPopup(label)
		Backend.disable_input = true
	end

	local is_default = IsDefault(current_key, default_key, isController)
	local resetPopup = _F("%s##%s%s", reset_label, label, currentKeyName)
	ImGui.SameLine()
	ImGui.BeginDisabled(is_default or default_key == nil)
	if (GUI:Button(reset_label)) then
		ImGui.OpenPopup(resetPopup)
	end
	ImGui.EndDisabled()
	if (is_default) then
		GUI:Tooltip(_T("SETTINGS_KEYBINDS_NO_RESET"))
	end

	local no_unbind   = NoUnbindKeys:Contains(gvarKey)
	local unbindPopup = _F("%s##%s%s", unbind_label, label, currentKeyName)
	ImGui.SameLine()
	ImGui.BeginDisabled(keyCode == 0 or no_unbind)
	if (GUI:Button(_F("%s##%s", unbind_label, label), { size = vec2:new(unbind_button_width, 32) })) then
		ImGui.OpenPopup(unbindPopup)
	end
	ImGui.EndDisabled()
	if (no_unbind) then
		GUI:Tooltip(_T("SETTINGS_KEYBINDS_NO_UNBIND"))
	end

	if (default_key and ImGui.DialogBox(resetPopup, _T("SETTINGS_KEYBINDS_RESET_COFNIRM"), ImGuiDialogBoxStyle.WARN)) then
		local newKey = isController and table.copy(default_key) or default_key
		table.set_nested_key(GVars, current_path, newKey)
	end

	if (ImGui.DialogBox(unbindPopup, _T("SETTINGS_KEYBINDS_UNBIND_COFNIRM"), ImGuiDialogBoxStyle.WARN)) then
		local newKey = isController and { name = "Unbound", code = 0 } or "Unbound"
		table.set_nested_key(GVars, current_path, newKey)
	end

	ImGui.SetNextWindowSize(400, 220)
	if ImGui.BeginPopupModal(
			label,
			ImGuiWindowFlags.AlwaysAutoResize
			| ImGuiWindowFlags.NoTitleBar
			| ImGuiWindowFlags.NoMove
		) then
		local winSize = vec2:new(ImGui.GetWindowSize())
		local _, pos  = GUI:GetNewWindowSizeAndCenterPos(0.5, 0.5, winSize)
		ImGui.SetWindowPos(label, pos.x, pos.y, ImGuiCond.Always)

		if ImGui.SmallButton("X") then
			ImGui.CloseCurrentPopup()
			Backend.disable_input = false
			keyCode, keyName      = nil, nil
		end

		ImGui.Separator()
		ImGui.Dummy(1, 10)

		local confirm_label       = _T("GENERIC_CONFIRM")
		local clear_label         = _T("GENERIC_CLEAR")
		local confirm_label_width = ImGui.CalcTextSize(confirm_label) + (framePaddingX * 2)
		local clear_label_width   = ImGui.CalcTextSize(clear_label) + (framePaddingX * 2)
		if (confirm_label_width > button_size.x) then
			button_size.x = confirm_label_width
		end

		if (clear_label_width > button_size.x) then
			button_size.x = clear_label_width
		end

		local reserved_set = isController and ReservedKeys.gpad or ReservedKeys.kb
		if (not keyName) then
			ImGui.Text(ImGui.TextSpinner(_T("SETTINGS_HOTKEY_WAIT"), 10, ImGuiSpinnerStyle.BOUNCE_DOTS))

			if (isController) then
				keyCode, keyName = Game.GetKeyPressed()
			else
				keyCode, keyName = GetCurrentKey()
			end
		else
			_reserved = reserved_set:Contains(keyCode)

			if (_reserved) then
				GUI:Text(_T("SETTINGS_HOTKEY_RESERVED"), { color = Color("red"), alpha = 0.86, wrap_pos = winSize.x })
			else
				local valueBarSize = vec2:new(button_size.x, ImGui.GetTextLineHeightWithSpacing())
				ImGui.Text(_T("SETTINGS_HOTKEY_FOUND"))
				ImGui.SameLine()
				ImGui.SetCursorPosX(winSize.x - valueBarSize.x - style.WindowPadding.x)
				ImGui.ValueBar(
					"##keyName",
					0,
					valueBarSize,
					ImGuiValueBarFlags.NONE,
					{ fmt = keyName }
				)
			end
		end

		local _, availY = ImGui.GetContentRegionAvail()
		-- ImGui.SetCursorPosY crashes in YimLuaAPI for no reason that I can make sense of.
		-- I give up. here's a dummy instead.
		ImGui.Dummy(0, math.max(0, availY - button_size.y - style.WindowPadding.y))

		if (keyCode and keyName and not _reserved) then
			if (GUI:Button(confirm_label, { size = button_size })) then
				if (not isController) then
					KeyManager:UpdateKeybind(current_key, { id = keyName })
				end

				local newKey = isController and { name = keyName, code = keyCode } or keyName
				table.set_nested_key(GVars, current_path, newKey)
				ImGui.CloseCurrentPopup()
				Backend.disable_input = false
				keyCode, keyName      = nil, nil
			end

			ImGui.SameLine()
			ImGui.SetCursorPosX(winSize.x - button_size.x - style.WindowPadding.x)
		end

		if (keyName) then
			if (GUI:Button(clear_label, { size = button_size })) then
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
				DrawKeybind(key, false)
			end
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem(_T("SETTINGS_KEYBINDS_CONTROLLER"))) then
			for key in pairs(GVars.gamepad_keybinds) do
				DrawKeybind(key, true)
			end
			ImGui.EndTabItem()
		end
		ImGui.EndTabBar()
	end
end
