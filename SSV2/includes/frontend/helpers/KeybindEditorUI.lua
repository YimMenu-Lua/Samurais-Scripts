-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Set                         = require("includes.classes.Set")
local Keybind                     = require("includes.structs.Keybind")
local keyContainerSize            = vec2:new(200, 32)
local buttonSize                  = vec2:new(120, 32)
local isAnyPadKeyPressed          = Game.IsAnyControllerKeyPressed
local isAnyPadKeyJustReleased     = Game.IsAnyControllerKeyJustReleased
local ReservedKeys <const>        = {
	[false] = Set(0x01, 0x07, 0x0A, 0x0B, 0x1B, 0x24, 0x2C, 0x2D, 0x46, 0x5B, 0x5C, 0x5E),
	[true]  = Set(23, 24, 25, 71, 75)
}

---@enum eKeyEditorState
local eKeybindEditorState <const> = {
	NONE         = 0,
	KEY_LISTEN   = 1,
	WAIT_RELEASE = 2,
	WAIT_CONFIRM = 3,
	CANCEL       = 4,
	CLEANUP      = 5,
	CLEAR_KEY    = 6,
}


---@class KeyBindEditorUI
---@field private m_state eKeyEditorState
---@field private m_primary_key GenericKey
---@field private m_modifier GenericKey
---@field private m_is_key_reserved boolean
---@field private m_conflict_keyname string
---@field private m_temp_buffer { pressed: boolean?, code: integer?, name: string? }
local KeyBindEditorUI   = {}
KeyBindEditorUI.__index = KeyBindEditorUI

---@return KeyBindEditorUI
function KeyBindEditorUI.new()
	local instance = setmetatable({
		m_state            = eKeybindEditorState.NONE,
		m_primary_key      = nil,
		m_modifier         = nil,
		m_conflict_keyname = nil,
		m_is_key_reserved  = false,
		m_temp_buffer      = {}
	}, KeyBindEditorUI)

	return instance
end

---@private
---@param is_gamepad boolean
function KeyBindEditorUI:UpdateState(is_gamepad)
	local state = self.m_state
	if (state == eKeybindEditorState.NONE) then
		return
	end

	local wantsClr = state == eKeybindEditorState.CLEAR_KEY
	if (wantsClr or state == eKeybindEditorState.CANCEL or state == eKeybindEditorState.CLEANUP) then
		self.m_primary_key     = nil
		self.m_modifier        = nil
		self.m_temp_buffer     = {}
		self.m_is_key_reserved = false

		if (wantsClr) then
			self.m_state = eKeybindEditorState.KEY_LISTEN
		else
			self.m_state = eKeybindEditorState.NONE
		end
	end

	local buff = self.m_temp_buffer
	local reservedSet = ReservedKeys[is_gamepad]
	if (state == eKeybindEditorState.KEY_LISTEN) then
		if (is_gamepad) then
			buff.pressed, buff.code, buff.name = isAnyPadKeyPressed()
		else
			buff.pressed, buff.code, buff.name = KeyManager:IsAnyKeyPressed()
		end

		if (buff.pressed and buff.code and buff.name) then
			local reserved         = reservedSet:Contains(buff.code)
			self.m_is_key_reserved = reserved
			self.m_primary_key     = { name = buff.name, code = buff.code }
			self.m_state           = not reserved and eKeybindEditorState.WAIT_RELEASE or eKeybindEditorState.WAIT_CONFIRM
		end
	end

	if (state == eKeybindEditorState.WAIT_RELEASE) then
		local released, code2, name2
		if (is_gamepad) then
			released, code2, name2 = isAnyPadKeyJustReleased()
		else
			released, code2, name2 = KeyManager:IsAnyKeyJustReleased()
		end

		if (released and code2 and name2 and buff.code and buff.name) then
			self.m_is_key_reserved = reservedSet:Contains(buff.code) or reservedSet:Contains(code2)
			if (buff.code ~= code2 and buff.name ~= name2) then
				self.m_modifier    = { name = buff.name, code = buff.code }
				self.m_primary_key = { name = name2, code = code2 }
			end

			self.m_state = eKeybindEditorState.WAIT_CONFIRM
		end
	end

	if (self.m_is_key_reserved) then
		self.m_state = eKeybindEditorState.WAIT_CONFIRM
		return
	end
end

-- TODO
---@param list table<string, Keybind>
---@param currentKey string
function KeyBindEditorUI:CheckConflict(list, currentKey)
	local selected = self.m_primary_key
	if (not selected) then
		return
	end

	if (self.m_conflict_keyname ~= nil) then
		return
	end

	local keycode = selected.code
	for k, v in pairs(list) do
		if (k == currentKey) then
			goto continue
		end

		local k1, k2 = v:GetKeyboardBinding(), v:GetControllerBinding()
		if (k1.key == keycode or k2.key == keycode) then
			self.m_conflict_keyname = v:GetName()
			break
		end

		::continue::
	end
end

---@param keybind Keybind
---@param drawGamepad boolean -- Draw the gamepad binding (because keybinding UIs must be separated to avoid confusion, this indicates that you're calling this method in your Controller bindings tab or window or whatever)
---@param args? { defaultKeybind?: Keybind, hideLabel: boolean?, translateLabel: boolean? }
function KeyBindEditorUI:DrawKey(keybind, drawGamepad, args)
	if (not keybind) then return end -- should never happen. we must make sure the keybind exists (if it doesn't, create it or get it from default table before passing it here)

	if (not drawGamepad and keybind:IgnoresGamepad()) then
		return -- does not support controller bindings (currently GUI and CommandExecutor use this)
	end

	args                 = args or {}
	local defaultKeybind = args.defaultKeybind
	if (not defaultKeybind) then
		defaultKeybind = Keybind.MakeDummy(keybind:GetName()) -- so we can reset to something even if the keybind doesn't have a default
	end

	self:UpdateState(drawGamepad)

	local keybindName = keybind:GetName()
	if (keybindName and args.translateLabel) then
		keybindName = _T(keybindName)
	end

	local binding         = drawGamepad and keybind:GetControllerBinding() or keybind:GetKeyboardBinding()
	local currentKey      = binding.key
	local currentModifier = binding.modifier
	local style           = ImGui.GetStyle()
	local label           = keybindName
	local framePaddingX   = style.FramePadding.x
	local unbindLabel     = _T("SETTINGS_KEYBINDS_UNBIND")
	local resetLabel      = _T("GENERIC_RESET")
	local unbindButtonX   = ImGui.CalcTextSize(unbindLabel) + (framePaddingX * 2)

	ImGui.PushID(keybind:GetID())
	if (not args.hideLabel) then
		ImGui.SeparatorText(keybindName)
	end

	ImGui.Spacing()
	local availX, _ = ImGui.GetContentRegionAvail()
	keyContainerSize.x = math.max(keyContainerSize.x, availX / 4)

	local buttonName = currentKey.name
	if (currentModifier and currentModifier.code ~= 0) then
		buttonName = _F("%s  +  %s", currentModifier.name, buttonName)
	end

	if (ImGui.Button(buttonName, keyContainerSize.x, keyContainerSize.y)) then
		self.m_state = eKeybindEditorState.KEY_LISTEN
		GUI:PlaySound(GUI.Sounds.Click)
		ImGui.OpenPopup(label)
	end

	local isDefault      = (keybind == defaultKeybind)
	local resetMainPopup = _F("%s##%s%s", resetLabel, label, currentKey.name)
	ImGui.SameLine()
	ImGui.BeginDisabled(isDefault)
	if (GUI:Button(_F("%s##%s", resetLabel, label))) then
		ImGui.OpenPopup(resetMainPopup)
	end
	ImGui.EndDisabled()
	if (isDefault) then
		GUI:Tooltip(_T("SETTINGS_KEYBINDS_NO_RESET"))
	end

	local noUnbind    = not keybind:AllowsUnbinding()
	local unbindPopup = _F("%s##%s%s", unbindLabel, label, currentKey.name)
	ImGui.SameLine()
	ImGui.BeginDisabled(keybind:IsDummy() or noUnbind)
	if (GUI:Button(_F("%s##%s", unbindLabel, label), { size = vec2:new(unbindButtonX, 32) })) then
		ImGui.OpenPopup(unbindPopup)
	end
	ImGui.EndDisabled()
	if (noUnbind) then
		GUI:Tooltip(_T("SETTINGS_KEYBINDS_NO_UNBIND"))
	end

	if (ImGui.DialogBox(resetMainPopup, _T("SETTINGS_KEYBINDS_RESET_COFNIRM"), ImGuiDialogBoxStyle.WARN)) then
		keybind:SetKeysFrom(defaultKeybind)
	end

	if (ImGui.DialogBox(unbindPopup, _T("SETTINGS_KEYBINDS_UNBIND_COFNIRM"), ImGuiDialogBoxStyle.WARN)) then
		keybind:Unbind()
	end

	GUI:RequestInput(ImGui.IsPopupOpen(label))
	ImGui.SetNextWindowSizeConstraints(400, 220, 480, 600)
	if (ImGui.BeginPopupModal(label,
			ImGuiWindowFlags.AlwaysAutoResize
			| ImGuiWindowFlags.NoTitleBar
			| ImGuiWindowFlags.NoMove
		)) then
		local winSize = vec2:new(ImGui.GetWindowSize())
		local _, pos  = GUI:GetNewWindowSizeAndCenterPos(0.5, 0.5, winSize)
		ImGui.SetWindowPos(label, pos.x, pos.y, ImGuiCond.Always)

		if (ImGui.SmallButton("X")) then
			self.m_state = eKeybindEditorState.CANCEL
			ImGui.CloseCurrentPopup()
		end

		if (self.m_state == eKeybindEditorState.KEY_LISTEN) then
			ImGui.Text(ImGui.TextSpinner(_T("SETTINGS_HOTKEY_WAIT")))

			ImGui.Spacing()
			ImGui.SetWindowFontScale(0.9)
			ImGui.TextWrapped(_T("SETTINGS_HOTKEY_MOD_TIP"))
			ImGui.SetWindowFontScale(1.0)
			ImGui.Spacing()
		end

		ImGui.Separator()
		ImGui.Dummy(1, 10)

		local confirmLabel = _T("GENERIC_CONFIRM")
		local clearLabel   = _T("GENERIC_CLEAR")
		local confirmLbelX = ImGui.CalcTextSize(confirmLabel) + (framePaddingX * 2)
		local clearLabelX  = ImGui.CalcTextSize(clearLabel) + (framePaddingX * 2)
		if (confirmLbelX > buttonSize.x) then
			buttonSize.x = confirmLbelX
		end

		if (clearLabelX > buttonSize.x) then
			buttonSize.x = clearLabelX
		end

		local reserved    = self.m_is_key_reserved
		local selectedKey = self.m_primary_key
		if (reserved) then
			GUI:Text(_T("SETTINGS_HOTKEY_RESERVED"), { color = Color.RED, alpha = 0.86 })
		elseif (selectedKey) then
			ImGui.Text(_T("SETTINGS_HOTKEY_FOUND"))
			ImGui.SameLine()
			local valueBarSize = vec2:new(keyContainerSize.x, ImGui.GetTextLineHeightWithSpacing())
			ImGui.SetCursorPosX(winSize.x - valueBarSize.x - style.WindowPadding.x)

			if (self.m_state == eKeybindEditorState.WAIT_RELEASE) then
				ImGui.Text(ImGui.TextSpinner(selectedKey.name .. " + "))
			else
				local selectedModifier = self.m_modifier
				local displayName      = selectedKey.name
				if (selectedModifier and selectedModifier.code ~= 0) then
					displayName = _F("%s + %s", selectedModifier.name, selectedKey.name)
				end
				ImGui.ValueBar(
					"##keyName",
					0,
					valueBarSize,
					ImGuiValueBarFlags.NONE,
					{ fmt = displayName }
				)
			end
		end

		local _, availY = ImGui.GetContentRegionAvail()
		ImGui.Dummy(0, math.max(0, availY - buttonSize.y - style.WindowPadding.y))

		ImGui.BeginDisabled(not selectedKey or reserved)
		if (GUI:Button(confirmLabel, { size = buttonSize })) then
			binding.key = selectedKey
			if (self.m_modifier) then
				binding.modifier = self.m_modifier
			end
			ImGui.CloseCurrentPopup()
			self.m_state = eKeybindEditorState.CLEANUP
		end
		ImGui.EndDisabled()

		ImGui.SameLine()
		ImGui.SetCursorPosX(winSize.x - buttonSize.x - style.WindowPadding.x)

		ImGui.BeginDisabled(not selectedKey)
		if (GUI:Button(clearLabel, { size = buttonSize })) then
			self.m_state = eKeybindEditorState.CLEAR_KEY
		end
		ImGui.EndDisabled()

		ImGui.EndPopup()
	end

	ImGui.Spacing()
	ImGui.PopID()
end

---@param list table<string, Keybind>
---@param drawGamepad boolean
---@param defaultList? table<string, Keybind>
---@param args? { defaultKeybind?: Keybind, hideLabel: boolean?, translateLabel: boolean? }
function KeyBindEditorUI:DrawList(list, drawGamepad, defaultList, args)
	defaultList = defaultList or {}
	args = args or {}
	for k, v in pairs(list) do
		args.defaultKeybind = defaultList[k]
		self:DrawKey(v, drawGamepad, args)
	end
end

return KeyBindEditorUI
