-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local ThemeManager = require("includes.services.ThemeManager")
local selected_theme = ThemeManager:GetCurrentTheme()
local draw_cfg_reset_window = false

---@type Set<string>
local cfg_reset_exceptions = Set.new("backend.debug_mode")
local cfg_exc_keys = {
	{ pair = Pair.new("Casino Pacino", "features.dunk"),          clicked = false, selected = false },
	{ pair = Pair.new("EntityForge", "features.entity_forge"),    clicked = false, selected = false },
	{ pair = Pair.new("YimActions", "features.yim_actions"),      clicked = false, selected = false },
	{ pair = Pair.new("YimResupplier", "features.yrv3"),          clicked = false, selected = false },
	{ pair = Pair.new("Controller Keybinds", "gamepad_keybinds"), clicked = false, selected = false },
	{ pair = Pair.new("Keyboard Keybinds", "keyboard_keybinds"),  clicked = false, selected = false },
}

local function OnConfigReset()
	for _, v in pairs(cfg_exc_keys) do
		v.clicked = false
		v.selected = false
	end
	draw_cfg_reset_window = false
end

local settings_tab = GUI:RegisterNewTab(Enums.eTabID.TAB_SETTINGS, "GENERIC_GENERAL_LABEL", function()
	GVars.backend.auto_cleanup_entities = GUI:CustomToggle(_T("SETTINGS_ENTITY_REPLACE"),
		GVars.backend.auto_cleanup_entities
	)
	GUI:Tooltip(_T("SETTINGS_ENTITY_REPLACE_TT"))

	ImGui.Spacing()
	ImGui.BulletText(_F("%s: %s (%s)", _T("SETTINGS_LANGUAGE"), GVars.backend.language_name, GVars.backend.language_code))
	ImGui.Spacing()

	if ImGui.BeginCombo("##langs", _F("%s (%s)",
			Translator.locales[GVars.backend.language_index].name,
			Translator.locales[GVars.backend.language_index].iso
		)) then
		for i, lang in ipairs(Translator.locales) do
			local is_selected = (i == GVars.backend.language_index)
			if (ImGui.Selectable(_F("%s (%s)", lang.name, lang.iso), is_selected)) then
				GVars.backend.language_index = i
				GVars.backend.language_name  = lang.name
				GVars.backend.language_code  = lang.iso
			end
		end
		ImGui.EndCombo()
	end

	ImGui.Spacing()

	if ImGui.Button(_T("SETTINGS_CFG_RESET")) then
		draw_cfg_reset_window = true
	end

	if (draw_cfg_reset_window) then
		if (ImGui.Begin("##cfg_reset",
				ImGuiWindowFlags.NoTitleBar
				| ImGuiWindowFlags.NoMove
				| ImGuiWindowFlags.NoResize
				| ImGuiWindowFlags.AlwaysAutoResize
			)) then
			GUI:QuickConfigWindow(_T("SETTINGS_CFG_RESET"), function()
				ImGui.Text(_T("SETTINGS_RESET_PRESERVE_KEYS"))
				ImGui.Spacing()
				for _, v in pairs(cfg_exc_keys) do
					local label = v.pair.first
					local gvar_key = v.pair.second
					v.selected, v.clicked = ImGui.Checkbox(label, v.selected)
					if (v.clicked) then
						if (v.selected) then
							cfg_reset_exceptions:Push(gvar_key)
						else
							cfg_reset_exceptions:Pop(gvar_key)
						end
					end
				end
				ImGui.Separator()
				ImGui.Spacing()
				if ImGui.Button(_T("GENERIC_RESET")) then
					ImGui.OpenPopup("##confirm_cfg_reset")
				end
				if GUI:ConfirmPopup("##confirm_cfg_reset") then
					Serializer:Reset(cfg_reset_exceptions)
					OnConfigReset()
				end
			end, function()
				cfg_reset_exceptions:Clear()
				OnConfigReset()
			end)
			ImGui.End()
		end
	end
	ImGui.Dummy(1, 10)
end, nil, true)

local function DrawGuiSettings()
	ImGui.SeparatorText(_T("GENERIC_GENERAL_LABEL"))

	GVars.ui.disable_tooltips = GUI:CustomToggle(_T("SETTINGS_TOOLTIPS"), GVars.ui.disable_tooltips)

	ImGui.SameLine()
	GVars.ui.disable_sound_feedback = GUI:CustomToggle(_T("SETTINGS_UI_SOUND"), GVars.ui.disable_sound_feedback)

	ImGui.SeparatorText(_T("SETTING_WINDOW_GEOMETRY"))
	GVars.ui.moveable, _ = GUI:CustomToggle(_T("SETTING_WINDOW_MOVEABLE"), GVars.ui.moveable,
		{ tooltip = _T("SETTING_WINDOW_MOVEABLE_TT") })

	if (GVars.ui.moveable) then
		ImGui.SameLine()
		if (GUI:Button(_T("SETTING_WINDOW_POS_RESET"))) then
			GUI:Snap()
		end

		ImGui.SameLine()
		if (GUI:Button(_T("SETTING_WINDOW_POS_SNAP"))) then
			ImGui.OpenPopup("##snapMainWindow")
		end
	end

	if (ImGui.BeginPopupModal("##snapMainWindow",
			ImGuiWindowFlags.NoMove
			| ImGuiWindowFlags.NoTitleBar
			| ImGuiWindowFlags.NoResize
			| ImGuiWindowFlags.AlwaysAutoResize)
		) then
		GUI:QuickConfigWindow(_T("SETTING_WINDOW_POS_SNAP"),
			function()
				ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 35, 30)
				ImGui.InvisibleButton("##dummy0", 30, 30)
				ImGui.SameLine()
				if (ImGui.ArrowButton("##top", 2)) then
					GUI:Snap(0)
				end
				if (ImGui.ArrowButton("##left", 0)) then
					GUI:Snap(2)
				end
				ImGui.SameLine()
				if (ImGui.Button("O", 30, 30)) then
					GUI:Snap(4)
				end
				ImGui.SameLine()
				if (ImGui.ArrowButton("##right", 1)) then
					GUI:Snap(3)
				end
				ImGui.InvisibleButton("##dummy1", 30, 30)
				ImGui.SameLine()
				if (ImGui.ArrowButton("##bottom", 3)) then
					GUI:Snap(1)
				end

				ImGui.PopStyleVar()
				GUI:ShowWindowHeightLimit()
			end,
			ImGui.CloseCurrentPopup
		)
		ImGui.EndPopup()
	end

	local resolution = Game.GetScreenResolution()

	GVars.ui.window_size.x, _ = ImGui.SliderFloat(_T("SETTING_WINDOW_WIDTH"),
		GVars.ui.window_size.x,
		GUI:GetMaxTopBarHeight(),
		resolution.x, "%.0f",
		---@diagnostic disable-next-line
		ImGuiSliderFlags.NoInput
	)

	ImGui.SameLine()
	if GUI:Button(_F("%s##width", _T("GENERIC_RESET"))) then
		GUI:ResetWidth()
	end

	local top_bar_height = GUI:GetMaxTopBarHeight() + 10
	GVars.ui.window_size.y, _ = ImGui.SliderFloat(_T("SETTING_WINDOW_HEIGHT"),
		GVars.ui.window_size.y,
		top_bar_height, resolution.y - top_bar_height,
		---@diagnostic disable-next-line
		"%.0f", ImGuiSliderFlags.NoInput
	)
	if (ImGui.IsItemHovered()) then
		GUI:ShowWindowHeightLimit()
	end
	GUI:HelpMarker(_T("SETTING_WINDOW_HEIGHT_TT"))

	ImGui.SameLine()
	if (GUI:Button(_F("%s##height", _T("GENERIC_RESET")))) then
		GUI:ResetHeight()
	end

	ImGui.BeginDisabled()
	GVars.ui.window_pos.x, _ = ImGui.SliderFloat(_T("SETTING_WINDOW_POS_X"), GVars.ui.window_pos.x, 0, resolution.x)
	GUI:Tooltip(_T("SETTING_WINDOW_POS_TT"))
	GVars.ui.window_pos.y, _ = ImGui.SliderFloat(_T("SETTING_WINDOW_POS_Y"), GVars.ui.window_pos.y, 0, resolution.y)
	GUI:Tooltip(_T("SETTING_WINDOW_POS_TT"))
	ImGui.EndDisabled()

	ImGui.SeparatorText(_T("SETTING_WINDOW_STYLE"))

	if (ImGui.BeginCombo("##uitheme", selected_theme and selected_theme.Name or _T("SETTING_WINDOW_THEME"))) then
		for name, theme in pairs(ThemeManager:GetThemes()) do
			local is_selected = selected_theme and selected_theme.Name == name or false
			if (ImGui.Selectable(name, is_selected)) then
				selected_theme = theme
				GVars.ui.style.theme = theme
				ThemeManager:SetCurrentTheme(theme)
			end
		end
		ImGui.EndCombo()
	end

	ImGui.Spacing()

	GVars.ui.style.bg_alpha, _ = ImGui.SliderFloat(_T("SETTING_WINDOW_ALPHA"), GVars.ui.style.bg_alpha, 0.01, 1.0)

	ImGui.SameLine()
	ImGui.Text(_F("(%d%%)", math.floor(GVars.ui.style.bg_alpha * 100)))

	ImGui.ColorEditVec4(_T("SETTING_WINDOW_ACCENT_COL"), GVars.ui.style.theme.TopBarFrameCol1)
	ImGui.ColorEditVec4(_T("SETTING_WINDOW_TOP_FRAME_BG"), GVars.ui.style.theme.TopBarFrameCol2)
end

settings_tab:RegisterSubtab("SUBTAB_GUI", DrawGuiSettings, nil, true)
settings_tab:RegisterSubtab("SETTINGS_KEYBINDS", require("includes.frontend.settings.keybinds_ui"), nil, true)

--#region debug
if (not GVars.backend.debug_mode) then
	return
end
settings_tab:RegisterSubtab("Debug", require("includes.frontend.settings.debug_ui"), nil, false)
--#endregion
