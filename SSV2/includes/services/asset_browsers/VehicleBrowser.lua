-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local AssetBrowserBase      = require("includes.services.asset_browsers.AssetBrowserBase")
local RawDataService        = require("includes.services.RawDataService")
local Manufacturers <const> = require("includes.data.refs").t_VehicleManufacturers


---@type array<string>
local ClassFilterArray = { "GENERIC_NONE" }
for i = 0, 22 do
	local str = EnumToString(Enums.eVehicleClass, i)
	ClassFilterArray[#ClassFilterArray + 1] = str:gsub("%_+", " "):titlecase()
end

---@type array<string>
local MfrFilterArray = { "GENERIC_NONE" }
for _, str in ipairs(Manufacturers) do
	MfrFilterArray[#MfrFilterArray + 1] = str
end


---@class VehBrowserParams : BrowserBaseParams
---@field show_class_filters? boolean
---@field show_manufacturer_filters? boolean
---@field filter_combo_width? float
---@field max_entries? integer
---@field show_preview? boolean
---@field cars_only? boolean


--------------------------------------
-- VehicleBrowser
--------------------------------------
-- A simple ped browser UI class.
--
-- Draws vehicles inside an ImGui Listbox and provides search and filtering controls.
---@class VehicleBrowser<string, RawVehicleData> : AssetBrowserBase
---@field private m_selected_item? RawVehicleData
---@field private m_cars_only boolean
---@field private m_wants_class_filters boolean
---@field private m_class_filter_array? array<string>
---@field private m_class_filter_index integer
---@field private m_wants_manufacturer_filters boolean
---@field private m_manufacturer_filter_array? array<string>
---@field private m_selected_manufacturer string
---@field private m_filter_combo_width float
local VehicleBrowser <const> = setmetatable({}, AssetBrowserBase)
VehicleBrowser.__index       = VehicleBrowser

---@param opts? VehBrowserParams
---@return VehicleBrowser
function VehicleBrowser.new(opts)
	opts = opts or {}
	opts.is_normalized_array = true

	local base = AssetBrowserBase.new(opts)
	local instance = setmetatable(base, VehicleBrowser)
	instance.m_cars_only = opts.cars_only or false
	instance.m_wants_preview = opts.show_preview or false
	instance.m_filter_combo_width = opts.filter_combo_width or 144.0
	instance.m_class_filter_index = 1
	instance.m_wants_class_filters = opts.show_class_filters or false
	instance.m_selected_manufacturer = "GENERIC_NONE"
	instance.m_wants_manufacturer_filters = opts.show_manufacturer_filters or false

	---@diagnostic disable-next-line
	return instance
end

---@private
---@return boolean
function VehicleBrowser:ShouldFilterByClass()
	return self.m_wants_class_filters
end

---@private
---@return boolean
function VehicleBrowser:ShouldFilterByManufacturer()
	return self.m_wants_manufacturer_filters
end

---@private
function VehicleBrowser:DrawManufacturerFilter()
	if (not self:ShouldFilterByManufacturer()) then
		return
	end

	local preview = self.m_selected_manufacturer == "GENERIC_NONE" and _T("GENERIC_MANUFACTURER") or self.m_selected_manufacturer
	ImGui.SetNextItemWidth(self.m_filter_combo_width)
	if (ImGui.BeginCombo("##VehicleBrowserMfrFilter", preview)) then
		for i, v in ipairs(MfrFilterArray) do
			local label = (i == 1) and _T(v) or v
			if (ImGui.Selectable(label, (v == self.m_selected_manufacturer))) then
				self.m_selected_manufacturer = v
			end
		end
		ImGui.EndCombo()
	end
	GUI:Tooltip(_T("GENERIC_LIST_FILTER"))
end

---@private
function VehicleBrowser:DrawClassFilter()
	if (not self:ShouldFilterByClass()) then
		return
	end

	if (self:ShouldFilterByManufacturer()) then
		ImGui.SameLineIfAvail(self.m_filter_combo_width)
	end

	local str     = ClassFilterArray[self.m_class_filter_index]
	local preview = self.m_class_filter_index == 1 and _T("GENERIC_CLASS") or str
	ImGui.SetNextItemWidth(self.m_filter_combo_width)
	if (ImGui.BeginCombo("##VehicleBrowserClassFilter", preview)) then
		for i, v in ipairs(ClassFilterArray) do
			local label = (i == 1) and _T(v) or v
			if (ImGui.Selectable(label, (i == self.m_class_filter_index))) then
				self.m_class_filter_index = i
			end
		end
		ImGui.EndCombo()
	end
	GUI:Tooltip(_T("GENERIC_LIST_FILTER"))
end

function VehicleBrowser:DrawFilters()
	self:DrawManufacturerFilter()
	self:DrawClassFilter()
end

---@private
---@param current_mfr string
---@return boolean
function VehicleBrowser:FilterByManufacturer(current_mfr)
	if (not self:ShouldFilterByManufacturer() or self.m_selected_manufacturer == "GENERIC_NONE") then
		return true
	end

	return current_mfr == self.m_selected_manufacturer
end

---@private
---@param currentClassID eVehicleClass
---@return boolean
function VehicleBrowser:FilterByClass(currentClassID)
	if (not self:ShouldFilterByClass() or self.m_class_filter_index == 1) then
		return true
	end

	return currentClassID == (self.m_class_filter_index - 2)
end

--#region overloads

---@override
---@param v RawVehicleData
function VehicleBrowser:TryFilters(_, v)
	return self:FilterByManufacturer(v.manufacturer)
		and self:FilterByClass(v.class_id)
end

---@override
---@param v RawVehicleData
---@return joaat_t
function VehicleBrowser:GetModelFromIterable(_, v)
	return v.model_hash
end

---@override
---@param v RawVehicleData
---@return string
function VehicleBrowser:GetNameFromIterable(_, v)
	return v.display_name
end

--#endregion

---@public
---@param region? vec2
---@return RawVehicleData? selectedVehicle, boolean clicked
function VehicleBrowser:Draw(region)
	if (not self.m_items) then
		self.m_items = RawDataService:GetNormalizedVehicles()
	end

	return self:__DrawImpl(region)
end

return VehicleBrowser
