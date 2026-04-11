-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- ---@enum eAssetBrowserDrawMode
-- Enums.eAssetBrowserDrawMode = {
-- 	COMBO   = 0,
-- 	LISTBOX = 1,
-- }

local REF_COUNTER = 0

---@class BrowserBaseParams<K, V>
---@field item_list? table<K, V>
---@field show_preview? boolean
---@field max_entries? integer


--------------------------------------
-- AssetBrowserBase
--------------------------------------
-- Base class that draws a game asset list in an ImGui ListBox. Intoduces a reusable object across the entire project
--
-- while eliminating repetitive code.
--___
-- **NOTE:**
--
-- Because our assets are mostly dicts, all asset lists are treated as such which breaks ordering for arrays.
--
-- Normalizing all dicts into arrays would cause the script to consume more memory for little to no benefit
--
-- because I don't see a way to achieve that without copying asset lists.
--
-- This design choice however is not final and may change in the future.
---@class AssetBrowserBase<K, V>
---@field protected m_items table<K, V>
---@field protected m_selected_item V?
---@field protected m_search_buffer string
---@field protected m_max_entries integer
---@field protected m_draw_region vec2
---@field protected m_wants_preview? boolean
---@field protected m_preview_enabled boolean
---@field protected m_clicked boolean
---@field protected m_hovered_this_frame? joaat_t
---@field protected m_uid joaat_t
---@field protected m_is_array boolean
---@field protected m_iter_idx integer
---@field GetModelFromIterable? fun(self: AssetBrowserBase, k: K, v: V): joaat_t -- This is for browsers that work with entities and offer a preview toggle.
---@field GetNameFromIterable? fun(self: AssetBrowserBase, k: K, v: V): string -- should be global for all browsers since base does not know what a label is.
local AssetBrowserBase <const> = {}
AssetBrowserBase.__index = AssetBrowserBase

---@param opts BrowserBaseParams
---@return AssetBrowserBase
function AssetBrowserBase.new(opts)
	REF_COUNTER = REF_COUNTER + 1
	return setmetatable({
		m_items           = opts.item_list,
		m_max_entries     = opts.max_entries or -1,
		m_wants_preview   = opts.show_preview or false,
		m_preview_enabled = false,
		m_clicked         = false,
		m_search_buffer   = "",
		m_iter_idx        = 0,
		m_uid             = _J("ASSET_BROWSER_" .. REF_COUNTER)
	}, AssetBrowserBase)
end

---@param tag string hidden tag
---@param label? string display label
---@return string
function AssetBrowserBase:fmt(tag, label)
	return _F("%s##%s%d", self.m_uid, tag, label or "")
end

-- Must be overloaded to run filtering logic.
---@param k? K optional iterator current key
---@param v? V optional iterator current value
---@return boolean
function AssetBrowserBase:TryFilters(k, v) return true end

-- Must be overloaded to draw filtering widgets (combos, etc.).
---@param k? K optional iterator current key
---@param v? V optional iterator current value
function AssetBrowserBase:DrawFilters(k, v) end

-- Must be overloaded to run OnClick logic.
---@param k? K optional iterator current key
---@param v? V optional iterator current value
function AssetBrowserBase:OnItemClicked(k, v) end

---@public
---@return boolean
function AssetBrowserBase:WasClicked()
	return self.m_clicked
end

---@return V
function AssetBrowserBase:GetSelectedItem()
	return self.m_selected_item
end

---@param k any
---@param v any
---@param search_empty boolean
function AssetBrowserBase:__ProcessItem(k, v, search_empty)
	if (not self:TryFilters(k, v)) then
		return false
	end

	local getName = self.GetNameFromIterable
	---@type string
	---@diagnostic disable-next-line
	local label   = getName and getName(self, k, v) or tostring(k)
	if (not search_empty and not label:lower():contains(self.m_search_buffer)) then
		return false
	end

	if (ImGui.Selectable(label, (v == self.m_selected_item))) then
		self.m_selected_item = v
		ImGui.SetItemDefaultFocus()
	end

	if (ImGui.IsItemClicked(0)) then
		self.m_clicked = true
		pcall(self.OnItemClicked, self, k, v)
	end

	if (ImGui.IsItemHovered() and self.m_preview_enabled) then
		local getModel = self.GetModelFromIterable
		if (getModel) then
			self.m_hovered_this_frame = getModel(self, k, v)
		end
	end

	return true
end

---@param search_empty boolean
function AssetBrowserBase:__Pairs(search_empty)
	for k, v in pairs(self.m_items) do
		if (self:__ProcessItem(k, v, search_empty)) then
			self.m_iter_idx = self.m_iter_idx + 1
		end

		if (self.m_max_entries > 0 and self.m_iter_idx >= self.m_max_entries) then
			break
		end
	end
end

---@param search_empty boolean
function AssetBrowserBase:__iPairs(search_empty)
	for i, v in ipairs(self.m_items) do
		if (self.m_max_entries > 0 and self.m_iter_idx >= self.m_max_entries) then
			break
		end

		if (self:__ProcessItem(i, v, search_empty)) then
			self.m_iter_idx = self.m_iter_idx + 1
		end
	end
end

---@private
---@param is_search_empty boolean
function AssetBrowserBase:__Iterate(is_search_empty)
	if (not self.m_items) then
		return
	end

	if (self.m_is_array == nil) then
		self.m_is_array = table.is_array(self.m_items)
	end

	self.m_iter_idx = 0
	if (self.m_is_array) then
		self:__iPairs(is_search_empty)
	else
		self:__Pairs(is_search_empty)
	end
end

---@private
function AssetBrowserBase:__DrawListBox()
	local size_x, size_y = self.m_draw_region.x, self.m_draw_region.y
	self.m_search_buffer = ImGui.SearchBar("##searchbar", self.m_search_buffer, 0, size_x)
	local is_buff_empty  = self.m_search_buffer:isempty()

	if (ImGui.BeginListBox("##listBox", size_x, size_y)) then
		if (self.m_max_entries > 0 and is_buff_empty and (self.m_iter_idx >= self.m_max_entries)) then
			ImGui.TextColored(0.941, 0.745, 0.007, 1.000, "[ ! ]")
			GUI:Tooltip(_F(_T("ASSET_BROWSER_TRUNC_TT"), self.m_max_entries))
			ImGui.Separator()
		end

		self:__Iterate(is_buff_empty)
		ImGui.EndListBox()
	end
end

-- This can be overridden by browsers that don't work with game entities
--
-- but offer preview nonetheless (ex: AnimBrowser).
function AssetBrowserBase:HandlePreview()
	if (not self.m_wants_preview) then
		return
	end

	if (self.m_preview_enabled and self.m_hovered_this_frame) then
		PreviewService:OnTick(self.m_hovered_this_frame)
	end

	if (PreviewService:GetCurrentEntity() and not (ImGui.IsAnyItemHovered() and self.m_preview_enabled)) then
		self.m_hovered_this_frame = nil
		PreviewService:Clear()
	end
end

---@generic V
---@param region? vec2
---@return V? selectedItem, boolean clicked
function AssetBrowserBase:__DrawImpl(region)
	if (not self.m_items) then
		ImGui.TextDisabled(ImGui.TextSpinner(_T("GENERIC_WAIT_LABEL")))
		return nil, false
	end

	self.m_clicked     = false
	self.m_draw_region = self.m_draw_region or region or vec2:new(ImGui.GetContentRegionAvail())
	if (self.m_draw_region.x == 0) then self.m_draw_region.x = -1 end
	if (self.m_draw_region.y == 0) then self.m_draw_region.y = -1 end

	ImGui.PushID(self.m_uid)

	if (self.m_wants_preview) then
		self.m_preview_enabled = GUI:CustomToggle(_T("GENERIC_PREVIEW"), self.m_preview_enabled)
	end

	self:DrawFilters()
	self:__DrawListBox()

	ImGui.PopID()

	self:HandlePreview()
	return self.m_selected_item, self.m_clicked
end

return AssetBrowserBase
