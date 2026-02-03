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
---@field private m_col_stack integer
---@field private m_style_stack integer
---@field private m_theme_library ThemeLibrary
---@field m_themes_file string
local ThemeManager   = {
	m_current_theme = Theme.new(ThemeLibrary.Cyberpunk),
	m_themes_file   = "ss_themes.json",
	m_theme_library = {},
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
		GVars.ui.style.theme = current
	end

	if (not current.__type or not IsInstance(current.TopBarFrameCol1, vec4)) then
		current = Theme.deserialize(current)
		GVars.ui.style.theme = current
	end

	self.m_current_theme = current
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
	return self.m_theme_library.Cyberpunk or Theme.new(ThemeLibrary.Cyberpunk)
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

---@return table<string, table>
function ThemeManager:ReadThemesJson()
	if (not io.exists(self.m_themes_file)) then
		Serializer:WriteToFile({}, self.m_themes_file)
		return {}
	end

	local themes = Serializer:ReadFromFile(self.m_themes_file)
	if (type(themes) ~= "table") then
		log.warning("Theme data appears to be corrupted! Returning an empty table.")
		themes = {}
	end

	return themes
end

---@param theme Theme
function ThemeManager:AddNewTheme(theme)
	if (self:DoesThemeExist(theme.Name)) then
		return
	end

	local json_themes                = self:ReadThemesJson()
	theme.JSON                       = true
	json_themes[theme.Name]          = theme
	self.m_theme_library[theme.Name] = theme

	Serializer:WriteToFile(json_themes, self.m_themes_file)
	self:SetCurrentTheme(theme)
end

---@param theme Theme
function ThemeManager:RemoveTheme(theme)
	if (not theme.JSON) then
		return
	end

	if (self:GetCurrentTheme().Name == theme.Name) then
		self:SetCurrentTheme(self:GetDefaultTheme())
	end

	local json_themes                = self:ReadThemesJson()
	json_themes[theme.Name]          = nil
	self.m_theme_library[theme.Name] = nil

	Serializer:WriteToFile(json_themes, self.m_themes_file)
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
		if (ImGuiCol[k]) then
			ImGui.PushStyleColor(ImGuiCol[k], v.x, v.y, v.z, v.w)
			self.m_col_stack = self.m_col_stack + 1
		end
	end

	self.m_style_stack = 0
	for k, v in pairs(styles) do
		if (type(v) == "table") then
			ImGui.PushStyleVar(ImGuiStyleVar[k], v.x, v.y)
			self.m_style_stack = self.m_style_stack + 1
		else
			ImGui.PushStyleVar(ImGuiStyleVar[k], v)
			self.m_style_stack = self.m_style_stack + 1
		end
	end
end

function ThemeManager:PopTheme()
	if (self.m_col_stack ~= 0) then
		ImGui.PopStyleColor(self.m_col_stack)
	end

	if (self.m_style_stack ~= 0) then
		ImGui.PopStyleVar(self.m_style_stack)
	end
end

return ThemeManager
