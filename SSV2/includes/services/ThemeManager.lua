-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.



local Theme <const>        = require("includes.structs.Theme")
local ThemeLibrary <const> = require("includes.data.theme_library")


---@class ThemeManager
---@field private m_current_theme Theme
---@field private m_stack_depth integer
---@field private m_col_stack integer
---@field private m_style_stack integer
---@field private m_theme_library ThemeLibrary
---@field m_themes_file string
local ThemeManager   = {
	m_current_theme = Theme.new(ThemeLibrary.Tenebris),
	m_themes_file   = "ss_themes.json",
	m_theme_library = {},
	m_stack_depth   = 0,
}
ThemeManager.__index = ThemeManager

---@private
function ThemeManager:LoadLibrary()
	for k, t in pairs(ThemeLibrary) do
		self.m_theme_library[k] = Theme.new(t)
	end
end

function ThemeManager:Load()
	self:LoadLibrary()
	self:FetchSavedThemes()
	local current = GVars.ui.style.theme

	if (not current or not current.Colors) then
		current = self:GetDefaultTheme()
	end

	if (current.JSON or not current.__type or not IsInstance(current.SSAccent, vec4)) then
		current = Theme.deserialize(current)
	end

	GVars.ui.style.theme = current
	self.m_current_theme = current
end

function ThemeManager:GetStackDepth()
	return self.m_stack_depth
end

---@param name string
---@return Theme?
function ThemeManager:GetTheme(name)
	return self.m_theme_library[name]
end

---@return ThemeLibrary
function ThemeManager:GetAllThemes()
	return self.m_theme_library
end

---@return Theme
function ThemeManager:GetDefaultTheme()
	return self.m_theme_library.Tenebris or Theme.new(ThemeLibrary.Tenebris)
end

---@return Theme
function ThemeManager:GetCurrentTheme()
	return self.m_current_theme
end

---@param theme Theme
function ThemeManager:SetCurrentTheme(theme)
	GVars.ui.style.theme = theme
	self.m_current_theme = theme
end

---@param name string
function ThemeManager:DoesThemeExist(name)
	return self:GetTheme(name) ~= nil
end

---@return boolean
function ThemeManager:IsBackgroundDark()
	return ImGui.GetStyleColor(ImGuiCol.WindowBg):IsDark()
end

---@return table<string, Theme>
function ThemeManager:ReadThemesJson()
	if (not io.exists(self.m_themes_file)) then
		Serializer:WriteToFile(self.m_themes_file, {})
		return {}
	end

	---@type table<string, Theme>
	local themes = Serializer:ReadFromFile(self.m_themes_file)
	if (type(themes) ~= "table") then
		log.warning("Theme data appears to be corrupted! Returning an empty table.")
		Serializer:WriteToFile(self.m_themes_file, {})
		return {}
	end

	return themes
end

---@param theme Theme
---@param apply? boolean
function ThemeManager:AddNewTheme(theme, apply)
	if (self:DoesThemeExist(theme.Name)) then
		return
	end

	theme.JSON       = true
	local lib        = self.m_theme_library
	local json       = self:ReadThemesJson()
	local serialized = theme:serialize()
	json[theme.Name] = serialized
	lib[theme.Name]  = theme

	if (apply) then self:SetCurrentTheme(theme) end
	Serializer:WriteToFile(self.m_themes_file, json)
end

---@param theme Theme
function ThemeManager:RemoveTheme(theme)
	if (not theme.JSON) then
		return
	end

	if (self:GetCurrentTheme().Name == theme.Name) then
		self:SetCurrentTheme(self:GetDefaultTheme())
	end

	local lib        = self.m_theme_library
	local json       = self:ReadThemesJson()
	json[theme.Name] = nil
	lib[theme.Name]  = nil

	Serializer:WriteToFile(self.m_themes_file, json)
end

function ThemeManager:FetchSavedThemes()
	local themes = self:ReadThemesJson()
	for name, data in pairs(themes) do
		if (not self:DoesThemeExist(name)) then
			self.m_theme_library[name] = Theme.deserialize(data)
			self.m_theme_library[name].JSON = true
		end
	end
end

function ThemeManager:PushTheme()
	if (not self.m_current_theme) then
		return
	end

	local colors = self.m_current_theme.Colors
	local styles = self.m_current_theme.Styles

	self.m_col_stack = 0
	for k, v in pairs(colors) do
		local idx = ImGuiCol[k]
		if (idx) then
			ImGui.PushStyleColor(idx, v.x, v.y, v.z, v.w)
			self.m_col_stack = self.m_col_stack + 1
		end
	end

	self.m_style_stack = 0
	for k, v in pairs(styles) do
		local idx = ImGuiStyleVar[k]
		if (not idx) then
			goto continue
		end

		if (type(v) == "table" and v.__type == "vec2") then
			ImGui.PushStyleVar(idx, v.x, v.y)
		else
			ImGui.PushStyleVar(idx, v)
		end
		self.m_style_stack = self.m_style_stack + 1

		::continue::
	end

	self.m_stack_depth = self.m_stack_depth + 1
end

function ThemeManager:PopTheme()
	if (self.m_col_stack > 0) then
		ImGui.PopStyleColor(self.m_col_stack)
	end

	if (self.m_style_stack > 0) then
		ImGui.PopStyleVar(self.m_style_stack)
	end

	self.m_stack_depth = self.m_stack_depth - 1
end

return ThemeManager
