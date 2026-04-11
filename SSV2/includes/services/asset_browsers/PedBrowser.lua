-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local AssetBrowserBase = require("includes.services.asset_browsers.AssetBrowserBase")
local RawDataService   = require("includes.services.RawDataService")
local TypeFilterArray  = { "GENERIC_NONE" }
for i = 0, 29 do
	TypeFilterArray[#TypeFilterArray + 1] = EnumToString(Enums.ePedType, i)
end

---@class PedBrowserParams : BrowserBaseParams
---@field show_type_filters? boolean
---@field show_gender_filters? boolean
---@field filter_combo_width? float
---@field max_entries? integer
---@field show_preview? boolean
---@field humans_only? boolean


--------------------------------------
-- PedBrowser
--------------------------------------
-- A simple ped browser UI class.
--
-- Draws peds inside an ImGui Listbox and provides search and filtering controls.
---@class PedBrowser : AssetBrowserBase
---@field private m_selected_item? RawPedData
---@field private m_wants_type_filters boolean
---@field private m_type_filter_index integer
---@field private m_wants_gender_filters boolean
---@field private m_gender_filter_array array<string>
---@field private m_gender_filter_index integer
---@field private m_humans_only boolean
---@field private m_clicked boolean
---@field private m_filter_combo_width float
---@field public GetSelectedItem fun(self: PedBrowser): RawPedData
local PedBrowser <const> = setmetatable({}, AssetBrowserBase)
PedBrowser.__index       = PedBrowser

---@param opts? PedBrowserParams
---@return PedBrowser
function PedBrowser.new(opts)
	opts = opts or {}
	local base = AssetBrowserBase.new(opts)
	local instance = setmetatable(base, PedBrowser)
	instance.m_humans_only = opts.humans_only or false
	instance.m_type_filter_index = 1
	instance.m_filter_combo_width = opts.filter_combo_width or 144.0
	instance.m_wants_type_filters = opts.show_type_filters or false
	instance.m_gender_filter_index = 1
	instance.m_wants_gender_filters = opts.show_gender_filters or false

	if (instance.m_wants_gender_filters) then
		local gender_array = { "GENERIC_NONE", "GENERIC_MALE", "GENERIC_FEMALE" }
		if (not instance.m_humans_only) then
			gender_array[4] = "GENERIC_UNKOWN"
		end

		instance.m_gender_filter_array = gender_array
	end

	---@diagnostic disable-next-line
	return instance
end

---@private
---@return boolean
function PedBrowser:ShouldFilterByType()
	return self.m_wants_type_filters
end

---@private
---@return boolean
function PedBrowser:ShouldFilterByGender()
	return self.m_wants_gender_filters
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

	local preview = self.m_type_filter_index == 1 and _T("GENERIC_TYPE") or TypeFilterArray[self.m_type_filter_index]
	ImGui.SetNextItemWidth(self.m_filter_combo_width)
	if (ImGui.BeginCombo("##PedBrowserTypeFilter", preview)) then
		for i, v in ipairs(TypeFilterArray) do
			local label = (i == 1) and _T(v) or v
			if (ImGui.Selectable(label, (i == self.m_type_filter_index))) then
				self.m_type_filter_index = i
			end
		end
		ImGui.EndCombo()
	end
	GUI:Tooltip(_T("GENERIC_LIST_FILTER"))
end

function PedBrowser:DrawFilters()
	self:DrawGenderFilter()
	self:DrawTypeFilter()
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

---@param data RawPedData
function PedBrowser:FilterNonHumans(data)
	if (not self.m_humans_only) then return true end
	return data.is_human
end

--#region overloads

---@override
---@param v Pair<string, RawPedData>
function PedBrowser:TryFilters(_, v)
	local data = v.second
	return self:FilterByGender(data.ped_gender)
		and self:FilterByType(data.ped_type)
		and self:FilterNonHumans(data)
end

---@override
---@param v Pair<string, RawPedData>
---@return joaat_t
function PedBrowser:GetModelFromIterable(_, v)
	return v.second.model_hash
end

---@override
---@param v Pair<string, RawPedData>
---@return string
function PedBrowser:GetNameFromIterable(_, v)
	return v.first
end

--#endregion

---@public
---@param region? vec2
---@return RawPedData? selectedPed, boolean clicked
function PedBrowser:Draw(region)
	if (not self.m_items) then
		self.m_items = RawDataService:GetNormalizedPeds()
	end

	return self:__DrawImpl(region)
end

return PedBrowser
