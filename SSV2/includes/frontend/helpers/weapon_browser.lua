-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.

local Weapons <const>    = require("includes.data.weapons")

---@type array<{name: string, list?: array<hash>}>
local Categories <const> = {
	{ name = "None" },
	{ name = "Melee",          list = Weapons.Melee },
	{ name = "Pistols",        list = Weapons.Pistols },
	{ name = "SMGs",           list = Weapons.SMG },
	{ name = "Shotguns",       list = Weapons.Shotguns },
	{ name = "Assault Rifles", list = Weapons.AssaultRifles },
	{ name = "Machine Guns",   list = Weapons.MachineGuns },
	{ name = "Sniper Rifles",  list = Weapons.SniperRifles },
	{ name = "Heavy Weapons",  list = Weapons.Heavy },
	{ name = "Throwables",     list = Weapons.Throwables },
	{ name = "Miscellaneous",  list = Weapons.Misc },
}


--------------------------------------
-- WeaponBrowser
--------------------------------------
-- A simple weapon browser UI class.
--
-- Draws weapon groups and lists inside either ImGui ListBoxes or Combos
--
-- based on constructor parameters *(defaults to Combos)*.
---@class WeaponBrowser
---@field private m_selected_category { name: string, list: array<integer>? }
---@field private m_selected_weapon_hash hash
---@field private m_selected_weapon_name string
---@field private m_draw_mode 0|1
---@field private m_draw_region vec2
---@field private m_clicked boolean
---@field private m_is_category_open boolean
---@field private m_is_list_open boolean
local WeaponBrowser <const> = {}
WeaponBrowser.__index       = WeaponBrowser

---@param drawMode? 0|1
---@param drawRegion? vec2
---@return WeaponBrowser
function WeaponBrowser.new(drawMode, drawRegion)
	return setmetatable({
		m_selected_category    = Categories[1],
		m_selected_weapon_name = "",
		m_selected_weapon_hash = 0,
		m_draw_mode            = drawMode or 0,
		m_draw_region          = drawRegion,
		m_clicked              = false,
		m_is_category_open     = false,
		m_is_list_open         = false,
	}, WeaponBrowser)
end

---@private
function WeaponBrowser:DrawCategories()
	for _, cat in ipairs(Categories) do
		local selected = (cat == self.m_selected_category)
		ImGui.Selectable(cat.name, selected)
		if (ImGui.IsItemClicked()) then
			self.m_selected_category = cat
			ImGui.SetItemDefaultFocus()

			if (cat.list and #cat.list > 0) then
				self.m_selected_weapon_hash = cat.list[1]
				self.m_selected_weapon_name = Game.GetWeaponDisplayName(self.m_selected_weapon_hash)
			end
		end
	end
end

---@private
function WeaponBrowser:DrawWeaponList()
	if (not self.m_selected_category.list) then
		return
	end

	for _, hash in ipairs(self.m_selected_category.list) do
		local name     = Game.GetWeaponDisplayName(hash)
		local selected = (hash == self.m_selected_weapon_hash)
		ImGui.Selectable(name, selected)
		if (ImGui.IsItemClicked()) then
			self.m_selected_weapon_hash = hash
			self.m_selected_weapon_name = name
			self.m_clicked              = true
			ImGui.SetItemDefaultFocus()
		end
	end
end

-- Returns whether the weapon list was clicked this frame.
---@public
---@return boolean
function WeaponBrowser:WasClicked()
	return self.m_clicked
end

---@public
---@return hash
function WeaponBrowser:GetSelectedWeaponHash()
	return self.m_selected_weapon_hash
end

---@public
---@return string
function WeaponBrowser:GetSelectedWeaponName()
	return self.m_selected_weapon_name
end

---@public
---@return hash weaponHash, boolean clicked
function WeaponBrowser:Draw()
	if (not self.m_draw_region) then
		self.m_draw_region = vec2:new(ImGui.GetContentRegionAvail())
	end

	local style     = ImGui.GetStyle()
	local mode      = self.m_draw_mode
	local category  = self.m_selected_category
	local itemWidth = (self.m_draw_region.x - style.ItemSpacing.x) * 0.5
	self.m_clicked  = false

	if (mode == 0) then
		ImGui.PushItemWidth(itemWidth)
		self.m_is_category_open = ImGui.BeginCombo("##weaponCategories", category.name)
	else
		self.m_is_category_open = ImGui.BeginListBox("##weaponCategories", itemWidth, self.m_draw_region.y)
	end

	if (self.m_is_category_open) then
		self:DrawCategories()
		if (mode == 0) then
			ImGui.EndCombo()
			ImGui.PopItemWidth()
		else
			ImGui.EndListBox()
		end
	end

	local selectedList = category.list
	if (selectedList and #selectedList > 0) then
		ImGui.SameLine()

		if (mode == 0) then
			ImGui.PushItemWidth(itemWidth)
			self.m_is_list_open = ImGui.BeginCombo("##weaponlist", self.m_selected_weapon_name)
		else
			self.m_is_list_open = ImGui.BeginListBox("##weaponlist", itemWidth, self.m_draw_region.y)
		end

		if (self.m_is_list_open) then
			self:DrawWeaponList()
			if (mode == 0) then
				ImGui.EndCombo()
				ImGui.PopItemWidth()
			else
				ImGui.EndListBox()
			end
		end
	end

	return self.m_selected_weapon_hash, self.m_clicked
end

return WeaponBrowser
