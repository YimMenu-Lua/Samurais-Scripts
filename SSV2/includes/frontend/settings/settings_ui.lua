-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local ThemeManager  = require("includes.services.ThemeManager")
local selectedTheme = ThemeManager:GetCurrentTheme()
local newThemeBuff  = selectedTheme:Copy()
local cfgReset      = {
	---@type Set<string>
	exceptions = Set.new("backend.debug_mode"),
	excToggles = {
		{ pair = Pair.new("Casino Pacino", "features.dunk"),          clicked = false, selected = false },
		{ pair = Pair.new("EntityForge", "features.entity_forge"),    clicked = false, selected = false },
		{ pair = Pair.new("YimActions", "features.yim_actions"),      clicked = false, selected = false },
		{ pair = Pair.new("YimResupplier", "features.yrv3"),          clicked = false, selected = false },
		{ pair = Pair.new("Controller Keybinds", "gamepad_keybinds"), clicked = false, selected = false },
		{ pair = Pair.new("Keyboard Keybinds", "keyboard_keybinds"),  clicked = false, selected = false },
	},
	open = false,
}
local themeEditor   = {
	shouldDraw      = false,
	liveEdit        = false,
	shouldFocusName = false,
	valid           = true,
	errors          = {}
}
newThemeBuff.Name   = ""

local function onConfigReset()
	for _, v in pairs(cfgReset.excToggles) do
		v.clicked = false
		v.selected = false
	end
	cfgReset.open = false
end

local function drawGeneralSettings()
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
		cfgReset.open = true
	end

	if (cfgReset.open) then
		if (ImGui.Begin("##cfg_reset",
				ImGuiWindowFlags.NoTitleBar
				| ImGuiWindowFlags.NoMove
				| ImGuiWindowFlags.NoResize
				| ImGuiWindowFlags.AlwaysAutoResize
			)) then
			GUI:QuickConfigWindow(_T("SETTINGS_CFG_RESET"), function()
				ImGui.Text(_T("SETTINGS_RESET_PRESERVE_KEYS"))
				ImGui.Spacing()
				for _, v in pairs(cfgReset.excToggles) do
					local label = v.pair.first
					local gvar_key = v.pair.second
					v.selected, v.clicked = ImGui.Checkbox(label, v.selected)
					if (v.clicked) then
						if (v.selected) then
							cfgReset.exceptions:Push(gvar_key)
						else
							cfgReset.exceptions:Pop(gvar_key)
						end
					end
				end
				ImGui.Separator()
				ImGui.Spacing()
				if ImGui.Button(_T("GENERIC_RESET")) then
					ImGui.OpenPopup(_T("GENERIC_RESET"))
				end
				if ImGui.DialogBox(_T("GENERIC_RESET")) then
					Serializer:Reset(cfgReset.exceptions)
					onConfigReset()
				end
			end, function()
				cfgReset.exceptions:Clear()
				onConfigReset()
			end)
			ImGui.End()
		end
	end
	ImGui.Dummy(1, 10)
end

local function drawThemeSettings()
	if (not themeEditor.shouldDraw or not newThemeBuff) then
		return
	end

	if (ImGui.Begin("##new_theme",
			ImGuiWindowFlags.NoTitleBar
			| ImGuiWindowFlags.NoMove
			| ImGuiWindowFlags.NoResize
			| ImGuiWindowFlags.AlwaysAutoResize
		)) then
		GUI:QuickConfigWindow(_T("SETTINGS_WINDOW_NEW_THEME"), function()
			ImGui.SetNextWindowBgAlpha(0)
			ImGui.BeginChild(
				"##new_theme_scroll_region",
				GVars.ui.window_size.x * 0.65,
				GPointers.ScreenResolution.y * 0.75
			)

			themeEditor.liveEdit, _ = GUI:CustomToggle(
				_T("SETTINGS_NEW_THEME_LIVE_EDIT"),
				themeEditor.liveEdit,
				{
					onClick = function(v)
						ThemeManager:SetCurrentTheme(v and newThemeBuff or selectedTheme)
					end
				}
			)

			ImGui.Spacing()
			if (themeEditor.shouldFocusName) then
				ImGui.SetScrollHereY()
				ImGui.SetKeyboardFocusHere()
				newThemeBuff.Name = ""
				themeEditor.shouldFocusName = false
			end
			newThemeBuff.Name, _ = ImGui.InputText(_T("SETTINGS_NEW_THEME_NAME"), newThemeBuff.Name, 128)
			Backend.disable_input = ImGui.IsItemActive()

			ImGui.Spacing()
			GUI:HeaderText(_T("SETTINGS_NEW_THEME_COLORS"), { separator = true })
			ImGui.BeginChild(
				"##colors",
				0,
				ImGui.GetWindowHeight() * 0.34,
				true,
				ImGuiWindowFlags.AlwaysUseWindowPadding
			)

			ImGui.ColorEditVec4("Custom Accent", newThemeBuff.SSAccent)
			ImGui.ColorEditVec4("Accent Gradient", newThemeBuff.SSGradient)

			for k, v in pairs(newThemeBuff.Colors) do
				ImGui.ColorEditVec4(k, v)
			end
			ImGui.EndChild()

			ImGui.Spacing()
			GUI:HeaderText(_T("SETTINGS_NEW_THEME_STYLE"), { separator = true })
			ImGui.BeginChild(
				"##style",
				0,
				ImGui.GetWindowHeight() * 0.34,
				true,
				ImGuiWindowFlags.AlwaysUseWindowPadding
			)
			for k, v in pairs(newThemeBuff.Styles) do
				if (type(v) == "number") then
					newThemeBuff.Styles[k], _ = ImGui.SliderFloat(k, newThemeBuff.Styles[k], 0.0, 20.0)
				elseif (IsInstance(v, vec2)) then
					ImGui.Text(k)
					ImGui.SetNextItemWidth(160)
					v.x, _ = ImGui.SliderFloat(_F("X##%s", k), v.x, 1.0, 20.0)
					ImGui.SameLine()
					ImGui.SetNextItemWidth(160)
					v.y, _ = ImGui.SliderFloat(_F("Y##%s", k), v.y, 1.0, 20.0)
				end
			end
			ImGui.EndChild()

			ImGui.Spacing()
			local btnLabel    = _T("GENERIC_SAVE")
			local btnWidth    = ImGui.CalcTextSize(btnLabel) + 10 + (ImGui.GetStyle().FramePadding.x * 2)
			local disableCond = not string.isvalid(newThemeBuff.Name)
			ImGui.BeginDisabled(disableCond)
			if (GUI:Button(_T("GENERIC_SAVE"), { size = vec2:new(btnWidth, 35) })) then
				if (ThemeManager:DoesThemeExist(newThemeBuff.Name)) then
					Notifier:ShowError(
						_T("GENERIC_SETTINGS_LABEL"),
						_F(_T("SETTINGS_NEW_THEME_NAME_ERR"), newThemeBuff.Name),
						false,
						5
					)
					themeEditor.shouldFocusName = true
				else
					themeEditor.valid, themeEditor.errors = newThemeBuff:ValidateVisibility()
					if (themeEditor.valid) then
						ThemeManager:AddNewTheme(newThemeBuff:Copy())
						selectedTheme          = newThemeBuff:Copy()
						themeEditor.shouldDraw = false
						newThemeBuff:Clear()
					else
						ImGui.OpenPopup("##newColorBadContrast")
					end
				end
			end
			ImGui.EndDisabled()
			if (disableCond) then
				GUI:Tooltip(_T("SETTINGS_NEW_THEME_NAME_EMPTY"))
			end

			if (ImGui.BeginPopupModal("##newColorBadContrast")) then
				ImGui.Text(_T("SETTINGS_NEW_THEME_CONTRAST_ERR"))
				ImGui.Spacing()
				ImGui.Indent()
				for _, str in ipairs(themeEditor.errors) do
					ImGui.BulletText(str)
				end
				ImGui.Unindent()
				ImGui.Separator()
				ImGui.Spacing()
				if (GUI:Button("OK", { size = vec2:new(80, 35) })) then
					themeEditor.valid  = true
					themeEditor.errors = {}
					ImGui.CloseCurrentPopup()
				end
				ImGui.EndPopup()
			end
			ImGui.EndChild()
		end, function()
			if (themeEditor.liveEdit) then
				ThemeManager:SetCurrentTheme(selectedTheme)
			end
			themeEditor.shouldDraw = false
		end)
		ImGui.End()
	end
end

local function drawGuiSettings()
	ImGui.Spacing()
	GUI:HeaderText(_T("GENERIC_GENERAL_LABEL"), { separator = true })

	GVars.ui.disable_tooltips       = GUI:CustomToggle(_T("SETTINGS_TOOLTIPS"), GVars.ui.disable_tooltips)
	GVars.ui.disable_sound_feedback = GUI:CustomToggle(_T("SETTINGS_UI_SOUND"), GVars.ui.disable_sound_feedback)

	ImGui.Spacing()
	GUI:HeaderText(_T("SETTINGS_WINDOW_GEOMETRY"), { separator = true })

	GVars.ui.moveable, _ = GUI:CustomToggle(_T("SETTINGS_WINDOW_MOVEABLE"), GVars.ui.moveable,
		{ tooltip = _T("SETTINGS_WINDOW_MOVEABLE_TT") })

	if (GVars.ui.moveable) then
		ImGui.SameLine()
		if (GUI:Button(_T("SETTINGS_WINDOW_POS_RESET"))) then
			GUI:Snap()
		end

		ImGui.SameLine()
		if (GUI:Button(_T("SETTINGS_WINDOW_POS_SNAP"))) then
			ImGui.OpenPopup("##snapMainWindow")
		end
	end

	if (ImGui.BeginPopupModal("##snapMainWindow",
			ImGuiWindowFlags.NoMove
			| ImGuiWindowFlags.NoTitleBar
			| ImGuiWindowFlags.NoResize
			| ImGuiWindowFlags.AlwaysAutoResize)
		) then
		GUI:QuickConfigWindow(_T("SETTINGS_WINDOW_POS_SNAP"),
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
	GVars.ui.window_size.x, _ = ImGui.SliderFloat(
		_T("SETTINGS_WINDOW_WIDTH"),
		GVars.ui.window_size.x,
		620,
		resolution.x, "%.0f",
		---@diagnostic disable-next-line
		ImGuiSliderFlags.NoInput
	)

	ImGui.SameLine()
	if GUI:Button(_F("%s##width", _T("GENERIC_RESET"))) then
		GUI:ResetWidth()
	end

	local topBarHeight = GUI:GetMaxTopBarHeight()
	GVars.ui.window_size.y, _ = ImGui.SliderFloat(
		_T("SETTINGS_WINDOW_HEIGHT"),
		GVars.ui.window_size.y,
		topBarHeight + 240,
		resolution.y - (topBarHeight + 10),
		---@diagnostic disable-next-line
		"%.0f", ImGuiSliderFlags.NoInput
	)
	if (ImGui.IsItemHovered()) then
		GUI:ShowWindowHeightLimit()
	end
	GUI:HelpMarker(_T("SETTINGS_WINDOW_HEIGHT_TT"))

	ImGui.SameLine()
	if (GUI:Button(_F("%s##height", _T("GENERIC_RESET")))) then
		GUI:ResetHeight()
	end

	ImGui.BeginDisabled()
	GVars.ui.window_pos.x, _ = ImGui.SliderFloat(_T("SETTINGS_WINDOW_POS_X"), GVars.ui.window_pos.x, 0, resolution.x)
	GUI:Tooltip(_T("SETTINGS_WINDOW_POS_TT"))
	GVars.ui.window_pos.y, _ = ImGui.SliderFloat(_T("SETTINGS_WINDOW_POS_Y"), GVars.ui.window_pos.y, 0, resolution.y)
	GUI:Tooltip(_T("SETTINGS_WINDOW_POS_TT"))
	ImGui.EndDisabled()

	ImGui.Spacing()
	GUI:HeaderText(_T("SETTINGS_WINDOW_STYLE"), { separator = true })

	GVars.ui.style.bg_alpha, _ = ImGui.SliderFloat(_T("SETTINGS_WINDOW_ALPHA"), GVars.ui.style.bg_alpha, 0.01, 1.0)
	ImGui.SameLine()
	ImGui.Text(_F("(%d%%)", math.floor(GVars.ui.style.bg_alpha * 100)))
	local themeLabel = _T("SETTINGS_WINDOW_THEME")
	if (ImGui.BeginCombo(themeLabel, selectedTheme and selectedTheme.Name or themeLabel)) then
		for _, theme in pairs(ThemeManager:GetAllThemes()) do
			local name        = theme.Name or ""
			local is_selected = selectedTheme and selectedTheme.Name == name or false
			local is_json     = theme.JSON or false
			if (is_json) then
				name = _F("[*] %s", name)
			end

			if (ImGui.Selectable(name, is_selected)) then
				selectedTheme = theme
				ThemeManager:SetCurrentTheme(theme)
			end

			if (is_json) then
				if (ImGui.IsItemClicked(1)) then
					GUI:PlaySound("Click")
					ImGui.OpenPopup(name)
				end
				GUI:Tooltip(_T("SETTINGS_JSON_THEME_DELETE"))
			end

			if (ImGui.BeginPopup(name)) then
				if (ImGui.MenuItem(_T("GENERIC_DELETE"))) then
					ThemeManager:RemoveTheme(theme)
					selectedTheme = ThemeManager:GetCurrentTheme()
				end
				ImGui.EndPopup()
			end
		end
		ImGui.EndCombo()
	end

	ImGui.Spacing()
	if (GUI:Button(_T("SETTINGS_WINDOW_NEW_THEME"))) then
		newThemeBuff           = ThemeManager:GetCurrentTheme():Copy()
		newThemeBuff.Name      = ""
		themeEditor.shouldDraw = true

		if (themeEditor.liveEdit) then
			ThemeManager:SetCurrentTheme(newThemeBuff)
		end
	end

	if (themeEditor.shouldDraw) then
		drawThemeSettings()
	end
end

local settings_tab = GUI:RegisterNewTab(
	Enums.eTabID.TAB_SETTINGS,
	"GENERIC_GENERAL_LABEL",
	drawGeneralSettings,
	nil,
	true
)
settings_tab:RegisterSubtab(
	"SUBTAB_GUI",
	drawGuiSettings,
	nil,
	true
)
settings_tab:RegisterSubtab(
	"SETTINGS_KEYBINDS",
	require("includes.frontend.settings.keybinds_ui"),
	nil,
	true
)

--#region debug
if (not GVars.backend.debug_mode) then
	return
end
settings_tab:RegisterSubtab(
	"Debug",
	require("includes.frontend.settings.debug_ui"),
	nil,
	false
)
--#endregion
