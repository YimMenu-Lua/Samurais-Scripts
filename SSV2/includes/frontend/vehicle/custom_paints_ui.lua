-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class CustomPaint
---@field name string
---@field hex string
---@field p integer
---@field m boolean
---@field manufacturer string
---@field shade string

---@type array<CustomPaint>
local t_CustomPaints        = {}
local ShadesFilters <const> = {
	"All",
	"Beige",
	"Black",
	"Blue",
	"Brown",
	"Gold",
	"Green",
	"Grey",
	"Orange",
	"Pink",
	"Purple",
	"Red",
	"White",
	"Yellow",
}

local MfrFilters <const>    = {
	"All",
	"Alfa Romeo",
	"AMC",
	"Apollo Automobili",
	"Aston Martin",
	"Audi",
	"Austin/Morris",
	"Bentley",
	"BMW",
	"Bugatti",
	"Chevrolet",
	"Dodge",
	"Ferrari",
	"Ford",
	"Honda",
	"Jaguar",
	"Koenigsegg",
	"Lamborghini",
	"Land Rover",
	"Lexus",
	"Lotus",
	"Mazda",
	"McLaren",
	"Mercedes-AMG",
	"Mercedes-Benz",
	"Nissan",
	"Pagani",
	"Plymouth",
	"Porsche",
	"Rimac Automobili",
	"Rolls-Royce",
	"Spyker",
	"Top Secret Jpn",
	"Toyota",
	"Volkswagen",
}

---@type CustomPaint?
local selectedPaint
local selectedShadeFilter   = "All"
local selectedMfrFilter     = "All"
local searchBuffer          = ""
local filterComboWidth      = 200
local matteClicked          = false
local isPrimary             = false
local isSecondary           = false

local function drawShadesFilter()
	local preview = selectedShadeFilter == "All" and "Color Shade" or selectedShadeFilter
	ImGui.SetNextItemWidth(filterComboWidth)
	if (ImGui.BeginCombo("##shades", preview)) then
		for _, shade in ipairs(ShadesFilters) do
			ImGui.Selectable(shade, (shade == selectedShadeFilter))
			if (ImGui.IsItemClicked(0)) then
				selectedShadeFilter = shade
				selectedPaint       = nil
			end
		end
		ImGui.EndCombo()
	end
	GUI:Tooltip(_T("VEH_PAINT_FILTER_TXT"))
end

local function drawMfrFilter()
	local preview = selectedMfrFilter == "All" and "Manufacturer" or selectedMfrFilter
	ImGui.SetNextItemWidth(filterComboWidth)
	if (ImGui.BeginCombo("##manufacturer", preview)) then
		for _, mfrName in ipairs(MfrFilters) do
			ImGui.Selectable(mfrName, (mfrName == selectedMfrFilter))
			if (ImGui.IsItemClicked(0)) then
				selectedMfrFilter = mfrName
				selectedPaint     = nil
			end
		end
		ImGui.EndCombo()
	end
	GUI:Tooltip(_T("VEH_PAINT_FILTER_TXT"))
end

---@param v CustomPaint
local function filterByShade(v)
	if (selectedShadeFilter == "All") then
		return true
	end

	return v.shade == selectedShadeFilter
end

---@param v CustomPaint
local function filterByMfr(v)
	if (selectedMfrFilter == "All") then
		return true
	end

	return v.manufacturer == selectedMfrFilter
end

---@param v CustomPaint
---@return boolean
local function filterPaints(v)
	return filterByMfr(v) and filterByShade(v)
end

local function DisplayCustomPaints()
	if (ImGui.BeginListBox("##CustomPaints", -1, 324)) then
		for _, v in ipairs(t_CustomPaints) do
			if (#searchBuffer > 0 and not v.name:lower():find(searchBuffer)) then
				goto continue
			end

			if (not filterPaints(v)) then
				goto continue
			end

			if (ImGui.Selectable(v.name, (v == selectedPaint))) then
				selectedPaint = v
			end

			if (ImGui.IsItemHovered()) then
				ImGui.SetNextWindowSize(220, 160)
				ImGui.BeginTooltip()
				local r, g, b, a = Color(v.hex):AsFloat()
				ImGui.SetNextWindowBgAlpha(1.0)
				ImGui.PushStyleColor(ImGuiCol.ChildBg, r, g, b, a)
				ImGui.BeginChild("##colDisplay", 0, 80)
				ImGui.EndChild()
				ImGui.PopStyleColor()
				ImGui.Spacing()
				ImGui.SetWindowFontScale(0.7)
				ImGui.TextWrapped(_T("VEH_PAINT_NOTE"))
				ImGui.SetWindowFontScale(1.0)
				ImGui.EndTooltip()
			end

			::continue::
		end
		ImGui.EndListBox()
	end
end

local function CustomPaintsUI()
	drawShadesFilter()
	ImGui.SameLineIfAvail(filterComboWidth)
	drawMfrFilter()

	ImGui.SetNextItemWidth(-1)
	searchBuffer = ImGui.SearchBar("##custompaintssq", searchBuffer)

	DisplayCustomPaints()

	if (not selectedPaint) then return end

	ImGui.Spacing()
	ImGui.BeginDisabled(not selectedPaint)
	_, matteClicked = GUI:CustomToggle(_T("VEH_PAINT_MATTE_CB"), selectedPaint and selectedPaint.m or false)
	GUI:Tooltip(_T("VEH_PAINT_MATTE_TT"))

	if (matteClicked) then
		selectedPaint.m = not selectedPaint.m
	end

	ImGui.Separator()
	isPrimary = GUI:CustomToggle(_T("VEH_PAINT_PRIMARY_CB"), isPrimary)

	ImGui.SameLine()
	isSecondary = GUI:CustomToggle(_T("VEH_PAINT_SECONDARY_CB"), isSecondary)

	local text_x = ImGui.CalcTextSize(_T("GENERIC_CONFIRM"))
	if (GUI:Button(_T("GENERIC_CONFIRM"), { size = vec2:new(text_x + 20, 40) }) and selectedPaint ~= nil) then
		if (not isPrimary and not isSecondary) then
			Notifier:ShowError("Samurai's Scripts", _T("VEH_PAINT_NOT_SELECTED_ERR"))
		else
			LocalPlayer:GetVehicle():SetCustomPaint(
				selectedPaint.hex,
				selectedPaint.p,
				selectedPaint.m,
				isPrimary,
				isSecondary
			)
		end
	end
	ImGui.EndDisabled()

	if (selectedPaint) then
		GUI:Tooltip(_T("VEH_PAINT_SAVE_TT"))
	end
end

ThreadManager:Run(function()
	t_CustomPaints = require("includes.data.custom_paints")
	table.sort(t_CustomPaints, function(a, b)
		return a.name < b.name
	end)
end)

return CustomPaintsUI
