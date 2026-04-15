-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


--[[
	// Summary:

	- Both arrays and dicts are supported. This base broswer only decides whether to use pairs or ipairs for iteration. Other than that, it has no clue what is what
	and should never do.

	- Subclasses (PedBrowser, ActionBrowser, etc.) must define what their data is and how it should be handled.

	- This base class has stubs (the poor man's virtual functions) that can be overloaded by subclasses to extend the browser's functionality.

	- Member `m_items` must never be mutated after being set. If we need to mutate the data then we have to mark the browser as not ready either by temporarily setting m_items
	to nil or adding some type of gating around the draw function (see ActionBrowser:SwitchMode for an examplr), do our thing then mark it back as ready.
	
	- Optional sorting, filtering, and iteration limits do not touch the data itself but use gotos and breaks inside the loop. A "view cache" type of layer lay be added in the future
	if we ever need actual data filtering but for now it's just control flow.

	- All our subclass browsers currently lazy-load their data sets once in the drawing function but an instance can always be created with a reference to a data list (see BrowserBaseParams).

	[Known Issue]
	- By default, this base assumes it will be working with game entities and defines a default preview handling function that works with PreviewService. This is bad and can lead to
	severe issues. It's only the case because for now only game entity browsers actually have a preview option. If that ever changes, the HandlePreview method MUST be stubbed in this
	base class and instead defined in each subclass that needs it.
]]


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
---@field has_context_menu? boolean


--------------------------------------
-- AssetBrowserBase
--------------------------------------
-- Base class that draws a game asset list in an ImGui ListBox. Intoduces a reusable object across the entire project
--
-- while eliminating repetitive code.
---@class AssetBrowserBase<K, V>
---@field protected m_items table<K, V>?
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
---@field protected m_has_context_menu? boolean
---@field protected m_should_update_scroll_y? boolean
---@field protected m_on_load_error? function -- [Optional] Basic ImGui callback to draw on error.
---@field public GetModelFromIterable? fun(self: AssetBrowserBase, k: K, v: V): joaat_t -- This is for browsers that work with entities and offer a preview toggle.
---@field public GetNameFromIterable? fun(self: AssetBrowserBase, k: K, v: V): string -- Should be global for all browsers since base has no notion of what "key" and "value" are.
---@field public OnClick? fun(self: AssetBrowserBase, k: K, v: V) -- [Optional] Must be overloaded to execute some logic when an item is clicked.
---@field public DrawItemContext? fun(self: AssetBrowserBase, k: K, v: V) -- [Optional] Must be overloaded to draw item context menu on right click.
local AssetBrowserBase <const> = {}
AssetBrowserBase.__index = AssetBrowserBase

---@param opts BrowserBaseParams
---@return AssetBrowserBase
function AssetBrowserBase.new(opts)
	REF_COUNTER = REF_COUNTER + 1
	local instance = setmetatable({
		m_items           = opts.item_list,
		m_max_entries     = opts.max_entries or -1,
		m_wants_preview   = opts.show_preview or false,
		m_preview_enabled = false,
		m_clicked         = false,
		m_search_buffer   = "",
		m_iter_idx        = 0,
		m_uid             = _J("ASSET_BROWSER_" .. REF_COUNTER)
	}, AssetBrowserBase)

	instance.m_has_context_menu = opts.has_context_menu or instance.DrawItemContext ~= nil
	return instance
end

--#region overloads

-- Must be overloaded to run filtering logic.
---@virtual
---@param k K optional iterator current key
---@param v V optional iterator current value
function AssetBrowserBase:TryFilters(k, v) return true end

-- Must be overloaded to draw filtering widgets (combos, etc.).
---@virtual
function AssetBrowserBase:DrawFilters() end

--#endregion

---@public
---@return boolean
function AssetBrowserBase:WasClicked() return self.m_clicked end

---@public
---@return any
function AssetBrowserBase:GetSelectedItem() return self.m_selected_item end

---@private
---@param tag string hidden tag
---@param label? string display label
---@return string
function AssetBrowserBase:fmt(tag, label)
	return _F("%s##%s%d", tag, self.m_uid, label or "")
end

---@private
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

	local is_selected = (v == self.m_selected_item)
	ImGui.Selectable(label, is_selected)

	if (is_selected and self.m_should_update_scroll_y) then
		ImGui.SetScrollHereY()
		self.m_should_update_scroll_y = false
	end

	if (ImGui.IsItemClicked(0)) then
		self.m_selected_item = v
		self.m_clicked       = true
		ImGui.SetItemDefaultFocus()

		local onClickFunc = self.OnClick
		if (onClickFunc) then
			pcall(onClickFunc, self, k, v)
		end
	end

	if (self.m_has_context_menu) then
		if (ImGui.IsItemClicked(1)) then
			self.m_selected_item = v
		end

		GUI:Tooltip(_T("ASSET_BROWSER_CONTEXT_TT"))
		self:DrawItemContext(k, v)
	end

	if (self.m_preview_enabled and ImGui.IsItemHovered()) then
		local getModel = self.GetModelFromIterable
		if (getModel) then
			self.m_hovered_this_frame = getModel(self, k, v)
		end
	end

	if (self.m_should_update_scroll_y and not self.m_selected_item) then
		self.m_should_update_scroll_y = false
	end

	return true
end

---@private
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

---@private
---@param search_empty boolean
function AssetBrowserBase:__iPairs(search_empty)
	for i, v in ipairs(self.m_items) do
		if (self:__ProcessItem(i, v, search_empty)) then
			self.m_iter_idx = self.m_iter_idx + 1
		end

		if (self.m_max_entries > 0 and self.m_iter_idx >= self.m_max_entries) then
			break
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
		if (not self.m_items) then
			local err_callback = self.m_on_load_error
			if (err_callback) then
				err_callback()
			else
				ImGui.TextDisabled(ImGui.TextSpinner(_T("GENERIC_WAIT_LABEL")))
			end

			ImGui.EndListBox()
			return
		end

		local max_entries = self.m_max_entries
		if (max_entries > 0 and is_buff_empty and (self.m_iter_idx >= max_entries)) then
			ImGui.TextColored(0.941, 0.745, 0.007, 1.000, "[ ! ]")
			GUI:Tooltip(_F(_T("ASSET_BROWSER_TRUNC_TT"), max_entries))
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
	self.m_clicked     = false
	self.m_draw_region = self.m_draw_region or region or vec2:new(ImGui.GetContentRegionAvail())
	if (self.m_draw_region.x == 0) then self.m_draw_region.x = -1 end
	if (self.m_draw_region.y == 0) then self.m_draw_region.y = -1 end

	ImGui.BeginDisabled(self.m_items == nil)
	ImGui.PushID(self.m_uid)

	if (self.m_wants_preview) then
		self.m_preview_enabled = GUI:CustomToggle(_T("GENERIC_PREVIEW"), self.m_preview_enabled)
	end

	self:DrawFilters()
	self:__DrawListBox()

	ImGui.PopID()
	ImGui.EndDisabled()

	self:HandlePreview()
	return self.m_selected_item, self.m_clicked
end

return AssetBrowserBase
