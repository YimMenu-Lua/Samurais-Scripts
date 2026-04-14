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
---@field private m_stack { depth: integer, colors: integer, style_vars: integer }
---@field private m_theme_library ThemeLibrary
---@field m_themes_file string
local ThemeManager   = {
	m_themes_file   = "ss_themes.json",
	m_theme_library = {},
	m_stack         = {
		depth      = 0,
		colors     = 0,
		style_vars = 0
	}
}
ThemeManager.__index = ThemeManager

---@private
function ThemeManager:LoadLibrary()
	for k, t in pairs(ThemeLibrary) do
		self.m_theme_library[k] = Theme.new(t)
	end

	self:MergeSavedThemes()
end

function ThemeManager:Load()
	self:LoadLibrary()

	local current = GVars.ui.style.theme
	if (not current or not current.Colors) then
		current = self:GetDefaultTheme()
	end

	if (Theme.IsRawTable(current)) then
		current = Theme.deserialize(current)
	end

	GVars.ui.style.theme = current
	self.m_current_theme = current
end

---@return integer
function ThemeManager:GetStackDepth()
	return self.m_stack.depth
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
	return Theme.new(ThemeLibrary.Synthwave)
end

---@return Theme
function ThemeManager:GetCurrentTheme()
	return self.m_current_theme
end

---@param theme Theme
function ThemeManager:SetCurrentTheme(theme)
	if (Theme.IsRawTable(theme)) then
		theme = Theme.deserialize(theme)
	end

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

---@private
---@return table<string, Theme>
function ThemeManager:ReadSavedThemes()
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

---@param theme Theme A Theme instance not plain table.
---@param apply? boolean Set as current theme.
function ThemeManager:AddNewTheme(theme, apply)
	if (self:DoesThemeExist(theme.Name)) then
		return
	end

	theme.JSON       = true
	local lib        = self.m_theme_library
	local json       = self:ReadSavedThemes()
	local serialized = theme:serialize()

	json[theme.Name] = serialized
	lib[theme.Name]  = serialized

	if (apply) then self:SetCurrentTheme(theme) end
	Serializer:WriteToFile(self.m_themes_file, json)
end

---@param theme Theme
function ThemeManager:RemoveTheme(theme)
	if (not theme.JSON) then
		log.warning("[ThemeManager]: Default themes can not be removed.")
		return
	end

	if (self:GetCurrentTheme().Name == theme.Name) then
		self:SetCurrentTheme(self:GetDefaultTheme())
	end

	local lib        = self.m_theme_library
	local json       = self:ReadSavedThemes()
	json[theme.Name] = nil
	lib[theme.Name]  = nil

	Serializer:WriteToFile(self.m_themes_file, json)
end

---@private
function ThemeManager:MergeSavedThemes()
	local themes = self:ReadSavedThemes()
	for name, data in pairs(themes) do
		if (not self:DoesThemeExist(name)) then
			local instance             = Theme.deserialize(data)
			instance.JSON              = true
			self.m_theme_library[name] = instance
		end
	end
end

---@private
---@param theme Theme
function ThemeManager:__push(theme)
	self.m_stack.colors = 0
	for k, v in pairs(theme.Colors) do
		local idx = ImGuiCol[k]
		if (idx) then
			ImGui.PushStyleColor(idx, v.x, v.y, v.z, v.w)
			self.m_stack.colors = self.m_stack.colors + 1
		end
	end

	self.m_stack.style_vars = 0
	for k, v in pairs(theme.Styles) do
		local idx = ImGuiStyleVar[k]
		if (not idx) then
			goto continue
		end

		if (type(v) == "table" and v.__type == "vec2") then
			ImGui.PushStyleVar(idx, v.x, v.y)
		else
			ImGui.PushStyleVar(idx, v)
		end
		self.m_stack.style_vars = self.m_stack.style_vars + 1

		::continue::
	end

	self.m_stack.depth = self.m_stack.depth + 1
end

---@private
function ThemeManager:__pop()
	if (self.m_stack.colors > 0) then
		ImGui.PopStyleColor(self.m_stack.colors)
	end

	if (self.m_stack.style_vars > 0) then
		ImGui.PopStyleVar(self.m_stack.style_vars)
	end

	self.m_stack.depth = self.m_stack.depth - 1
end

function ThemeManager:PushTheme()
	if (not self.m_current_theme) then
		return
	end

	self:__push(self.m_current_theme)
end

function ThemeManager:PopTheme()
	self:__pop()
end

-- Wraps a gui callback in a theme push/pop
---@param theme Theme Theme to use
---@param func function ImGui callback
function ThemeManager:WithTheme(theme, func)
	self:__push(theme)
	xpcall(func, function(err) log.warning(err) end)
	self:__pop()
end

return ThemeManager
