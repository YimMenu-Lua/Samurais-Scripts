-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local PedList <const>  = require("includes.data.peds")
local ListSize <const> = table.getlen(PedList)
local PreviewService   = require("includes.services.PreviewService")
local RET_TRUE <const> = function() return true end

---@class RawPedData
---@field model_hash hash
---@field ped_type ePedType
---@field ped_gender ePedGender
---@field is_human boolean

---@class PedBrowserParams
---@field filter_pred? Predicate<RawPedData>
---@field humans_only? boolean
---@field show_type_filters? boolean
---@field show_gender_filters? boolean
---@field max_entries? integer
---@field filter_combo_width? float
---@field show_preview? boolean


-- TODO: Add an AssetBrowser base class

--------------------------------------
-- PedBrowser
--------------------------------------
-- A simple ped browser UI class.
--
-- Draws peds inside an ImGui Listbox and provides search and filtering controls.
---@class PedBrowser
---@field private m_draw_region vec2
---@field private m_filter_pred? Predicate<RawPedData>
---@field private m_max_entries integer
---@field private m_selected_model_name string
---@field private m_selected_ped? RawPedData
---@field private m_hovered_this_frame hash?
---@field private m_search_buffer string
---@field private m_humans_only boolean
---@field private m_wants_preview boolean
---@field private m_preview_enabled boolean
---@field private m_wants_type_filters boolean
---@field private m_type_filter_array? array<string>
---@field private m_type_filter_index integer
---@field private m_wants_gender_filters boolean
---@field private m_gender_filter_array? array<string>
---@field private m_gender_filter_index integer
---@field private m_clicked boolean
---@field private m_filter_combo_width float
local PedBrowser <const> = {}
PedBrowser.__index       = PedBrowser

---@param opts? PedBrowserParams
---@return PedBrowser
function PedBrowser.new(opts)
	opts = opts or {}
	local instance = setmetatable({
		m_filter_pred          = opts.filter_pred or RET_TRUE,
		m_search_buffer        = "",
		m_selected_model_name  = "",
		m_humans_only          = opts.humans_only or false,
		m_wants_preview        = opts.show_preview or false,
		m_wants_type_filters   = opts.show_type_filters or false,
		m_wants_gender_filters = opts.show_gender_filters or false,
		m_max_entries          = opts.max_entries or -1,
		m_filter_combo_width   = opts.filter_combo_width or 144.0,
		m_type_filter_index    = 1,
		m_gender_filter_index  = 1,
		m_preview_enabled      = false,
		m_clicked              = false,
	}, PedBrowser)

	if (instance.m_wants_gender_filters) then
		local gender_array = { "GENERIC_NONE", "GENERIC_MALE", "GENERIC_FEMALE" }
		if (not instance.m_humans_only) then
			gender_array[4] = "GENERIC_UNKOWN"
		end
		instance.m_gender_filter_array = gender_array
	end

	if (instance.m_wants_type_filters) then
		local type_array = { "GENERIC_NONE" }
		for i = 0, 29 do -- it's probably better to exclude ped types 0 to 3 then sub when filtering but whatever
			type_array[#type_array + 1] = EnumToString(Enums.ePedType, i)
		end
		instance.m_type_filter_array = type_array
	end

	return instance
end

---@private
---@return boolean
function PedBrowser:ShouldFilterByType()
	return self.m_wants_type_filters and (self.m_type_filter_array ~= nil)
end

---@private
---@return boolean
function PedBrowser:ShouldFilterByGender()
	return self.m_wants_gender_filters and (self.m_gender_filter_array ~= nil)
end

---@private
function PedBrowser:DrawGenderFilter()
	if (not self:ShouldFilterByGender()) then
		return
	end

	local preview = self.m_gender_filter_index == 1 and "GENERIC_GENDER" or self.m_gender_filter_array[self.m_gender_filter_index]
	ImGui.SetNextItemWidth(self.m_filter_combo_width)
	if (ImGui.BeginCombo("##PedBrowserGendrFilter", _T(preview))) then
		for i, v in ipairs(self.m_gender_filter_array) do
			if (ImGui.Selectable(_T(v), (i == self.m_gender_filter_index))) then
				self.m_gender_filter_index = i
			end
		end
		ImGui.EndCombo()
	end
	GUI:Tooltip(_T("GENERIC_LIST_FILTER"))
end

---@private
function PedBrowser:DrawTypeFilter()
	if (not self:ShouldFilterByType()) then
		return
	end

	if (self:ShouldFilterByGender()) then
		ImGui.SameLineIfAvail(self.m_filter_combo_width)
	end

	local preview = self.m_type_filter_index == 1 and _T("GENERIC_TYPE") or self.m_type_filter_array[self.m_type_filter_index]
	ImGui.SetNextItemWidth(self.m_filter_combo_width)
	if (ImGui.BeginCombo("##PedBrowserTypeFilter", preview)) then
		for i, v in ipairs(self.m_type_filter_array) do
			local label = (i == 1) and _T(v) or v
			if (ImGui.Selectable(label, (i == self.m_type_filter_index))) then
				self.m_type_filter_index = i
			end
		end
		ImGui.EndCombo()
	end
	GUI:Tooltip(_T("GENERIC_LIST_FILTER"))
end

---@private
---@param currentGender ePedGender
---@return boolean
function PedBrowser:FilterByGender(currentGender)
	if (not self:ShouldFilterByGender() or self.m_gender_filter_index == 1) then
		return true
	end

	return currentGender == (self.m_gender_filter_index - 2)
end

---@private
---@param currentType ePedType
---@return boolean
function PedBrowser:FilterByType(currentType)
	if (not self:ShouldFilterByType() or self.m_type_filter_index == 1) then
		return true
	end

	return currentType == (self.m_type_filter_index - 2)
end

---@public
---@return boolean
function PedBrowser:WasClicked()
	return self.m_clicked
end

---@public
---@return RawPedData
function PedBrowser:GetSelectedPed()
	return self.m_selected_ped
end

---@public
---@param region vec2
---@return RawPedData selectedPed, boolean clicked
function PedBrowser:Draw(region)
	self.m_clicked = false
	self.m_draw_region = self.m_draw_region or region

	if (self.m_draw_region.x == 0) then self.m_draw_region.x = -1 end
	if (self.m_draw_region.y == 0) then self.m_draw_region.y = -1 end

	if (self.m_wants_preview) then
		self.m_preview_enabled = GUI:CustomToggle(_T("GENERIC_PREVIEW"), self.m_preview_enabled)
	end

	self:DrawGenderFilter()
	self:DrawTypeFilter()

	self.m_search_buffer = ImGui.SearchBar("##PedBrowserSearchbar", self.m_search_buffer, 0, -1)
	self.m_search_buffer = self.m_search_buffer:lower()
	local isSearchEmpty  = self.m_search_buffer:isempty()

	if (ImGui.BeginListBox("##PedBrowserBox", self.m_draw_region.x, self.m_draw_region.y)) then
		if (self.m_max_entries > 0 and self.m_max_entries < ListSize and isSearchEmpty) then
			ImGui.TextDisabled("[ ! ]")
			GUI:Tooltip(_F(_T("PED_BROWSER_TRUNC_TT"), self.m_max_entries))
			ImGui.Spacing()
		end

		local generic_idx = 1
		for model, data in pairs(PedList) do
			if (self.m_humans_only and not data.is_human) then
				goto continue
			end

			if (self.m_max_entries > 0 and generic_idx >= self.m_max_entries) then
				goto continue
			end

			if (not isSearchEmpty and not model:contains(self.m_search_buffer)) then
				goto continue
			end

			if (not self:FilterByGender(data.ped_gender)) then
				goto continue
			end

			if (not self:FilterByType(data.ped_type)) then
				goto continue
			end

			if (not self.m_filter_pred(data)) then
				goto continue
			end

			if (ImGui.Selectable(model, (model == self.m_selected_model_name))) then
				self.m_selected_model_name = model
				self.m_selected_ped        = data
			end

			if (ImGui.IsItemClicked()) then
				self.m_clicked = true
			end

			if (ImGui.IsItemHovered() and self.m_preview_enabled) then
				self.m_hovered_this_frame = data.model_hash
			end

			generic_idx = generic_idx + 1

			::continue::
		end
		ImGui.EndListBox()
	end

	if (self.m_preview_enabled and self.m_hovered_this_frame) then
		PreviewService:OnTick(self.m_hovered_this_frame, Enums.eEntityType.Ped)
	end

	if (PreviewService:GetCurrentEntity() and not (ImGui.IsAnyItemHovered() and self.m_preview_enabled)) then
		self.m_hovered_this_frame = nil
		PreviewService:Clear()
	end

	return self.m_selected_ped, self.m_clicked
end

return PedBrowser
