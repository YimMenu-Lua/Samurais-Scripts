-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local PreviewService = require("includes.services.PreviewService")

---@class ObjectBrowserParams
---@field show_blacklist_filters? boolean
---@field show_mp_only_filters? boolean
---@field show_preview? boolean
---@field filter_combo_width? float
---@field max_entries? integer


---@class ObjectBrowser
---@field private m_items array<string>?
---@field private m_blacklisted_objects set<string> -- TODO
---@field private m_mp_only_objects set<string> -- TODO
---@field private m_selected_object? string
---@field private m_search_buffer? string
---@field private m_hovered_this_frame? joaat_t
---@field private m_wants_blacklist_filters boolean
---@field private m_wants_mp_filters boolean
---@field private m_wants_preview boolean
---@field private m_preview_enabled boolean
---@field private m_clicked boolean
---@field private m_max_entries integer
---@field private m_filter_combo_width float
---@field private m_draw_region vec2
local ObjectBrowser <const> = {}
ObjectBrowser.__index       = ObjectBrowser

---@param opts? ObjectBrowserParams
function ObjectBrowser.new(opts)
	opts = opts or {}
	return setmetatable({
		m_wants_blacklist_filters = opts.show_blacklist_filters or false,
		m_wants_mp_filters        = opts.show_mp_only_filters or false,
		m_wants_preview           = opts.show_preview or false,
		m_max_entries             = opts.max_entries or -1,
		m_filter_combo_width      = opts.filter_combo_width or 144.0,
		m_search_buffer           = "",
		m_preview_enabled         = false,
		m_clicked                 = false,
	}, ObjectBrowser)
end

function ObjectBrowser:Iterate()
	if (not self.m_items) then return end

	local processed = 0
	for _, obj in ipairs(self.m_items) do
		if (not self.m_search_buffer:isempty() and not obj:lower():contains(self.m_search_buffer)) then
			goto continue
		end

		if (ImGui.Selectable(obj, (self.m_selected_object == obj))) then
			self.m_selected_object = obj
		end

		if (ImGui.IsItemClicked(0)) then
			self.m_clicked = true
			ImGui.SetItemDefaultFocus()
		end

		if (ImGui.IsItemHovered() and self.m_preview_enabled) then
			self.m_hovered_this_frame = _J(obj)
		end

		processed = processed + 1
		if (self.m_max_entries > 0 and processed >= self.m_max_entries) then
			break
		end

		::continue::
	end
end

---@param region? vec2
---@return string selectedObject, boolean clicked
function ObjectBrowser:Draw(region)
	if (not self.m_items) then
		self.m_items = require("includes.data.objects")
	end

	self.m_clicked     = false
	self.m_draw_region = self.m_draw_region or region or vec2:new(ImGui.GetContentRegionAvail())
	if (self.m_draw_region.x == 0) then self.m_draw_region.x = -1 end
	if (self.m_draw_region.y == 0) then self.m_draw_region.y = -1 end

	local size_x, size_y = self.m_draw_region.x, self.m_draw_region.y

	if (self.m_wants_preview) then
		self.m_preview_enabled = GUI:CustomToggle(_T("GENERIC_PREVIEW"), self.m_preview_enabled)
	end

	self.m_search_buffer = ImGui.SearchBar("##ObjectBrowserSearchBar", self.m_search_buffer, 0, size_x)

	if (ImGui.BeginListBox("##ObjectBrowserListBox", size_x, size_y)) then
		if (self.m_max_entries > 0 and self.m_search_buffer:isempty()) then
			ImGui.TextDisabled("[ ! ]")
			GUI:Tooltip(_F(_T("ASSET_BROWSER_TRUNC_TT"), self.m_max_entries))
			ImGui.Separator()
		end

		self:Iterate()
		ImGui.EndListBox()
	end

	if (self.m_preview_enabled and self.m_hovered_this_frame) then
		PreviewService:OnTick(self.m_hovered_this_frame)
	end

	if (PreviewService:GetCurrentEntity() and not (ImGui.IsAnyItemHovered() and self.m_preview_enabled)) then
		self.m_hovered_this_frame = nil
		PreviewService:Clear()
	end

	return self.m_selected_object, self.m_clicked
end

return ObjectBrowser
