-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local t_CustomPaints = require("includes.data.custom_paints")
table.sort(t_CustomPaints, function(a, b)
	return a.name < b.name
end)

local customPintShades          = {
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

local customPaintsManufacturers = {
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
	"Koeniggsegg",
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

local eSortType <const>         = {
	ALL          = 0,
	SHADE        = 1,
	MANUFACTURER = 2
}

local selected_paint
local customPaintIndex          = 1
local paintsColSortIndex        = 0
local paintsMfrSortIndex        = 0
local paintsSortbySwitch        = 0
local paintSearchBuffer         = ""
local sortbyShadeClicked        = false
local sortbyMfrClicked          = false
local matteClicked              = false
local isPrimary                 = false
local isSecondary               = false

---@param index integer
local function FilterPaints(index)
	if (paintsSortbySwitch == eSortType.ALL) then
		return true
	end

	local v = t_CustomPaints[index]
	if (paintsSortbySwitch == eSortType.SHADE) then
		if (paintsColSortIndex == 0) then
			return true
		elseif (v.shade == customPintShades[paintsColSortIndex + 1]) then
			return true
		end
	elseif (paintsSortbySwitch == eSortType.MANUFACTURER) then
		if (paintsMfrSortIndex == 0) then
			return true
		elseif (v.manufacturer == customPaintsManufacturers[paintsMfrSortIndex + 1]) then
			return true
		end
	end

	return false
end

local function DisplayCustomPaints()
	if ImGui.BeginListBox("##CustomPaints", -1, 324) then
		for i = 1, #t_CustomPaints do
			local v = t_CustomPaints[i]
			if (not FilterPaints(i)) then
				goto continue
			end

			if (#paintSearchBuffer > 0 and not v.name:lower():find(paintSearchBuffer:lower())) then
				goto continue
			end

			local is_selected = (customPaintIndex == i)
			if ImGui.Selectable(v.name, is_selected) then
				customPaintIndex = i
				selected_paint = v
			end

			if ImGui.IsItemHovered() then
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
	ImGui.Text(_T("VEH_PAINT_FILTER_TXT"))
	ImGui.SameLine()
	paintsSortbySwitch, _ = ImGui.RadioButton(_T("VEH_PAINT_FILTER_ALL"), paintsSortbySwitch, 0)

	ImGui.SameLine()
	paintsSortbySwitch, _ = ImGui.RadioButton(_T("VEH_PAINT_FILTER_COL"), paintsSortbySwitch, 1)

	ImGui.SameLine()
	paintsSortbySwitch, _ = ImGui.RadioButton(_T("VEH_PAINT_FILTER_MFR"), paintsSortbySwitch, 2)

	ImGui.PushItemWidth(180)
	if (paintsSortbySwitch == eSortType.SHADE) then
		paintsColSortIndex, sortbyShadeClicked = ImGui.Combo("##sortpaintjobs",
			paintsColSortIndex,
			customPintShades,
			#customPintShades
		)
		if (sortbyShadeClicked) then
			customPaintIndex = 0
		end
	elseif (paintsSortbySwitch == eSortType.MANUFACTURER) then
		paintsMfrSortIndex, sortbyMfrClicked = ImGui.Combo("##sortpaintjobs2",
			paintsMfrSortIndex,
			customPaintsManufacturers,
			#customPaintsManufacturers
		)

		if (sortbyMfrClicked) then
			customPaintIndex = 0
		end
	end
	ImGui.PopItemWidth()
	ImGui.PushItemWidth(420)

	paintSearchBuffer, _ = ImGui.InputTextWithHint("##custompaintssq",
		_T("GENERIC_SEARCH_HINT"),
		paintSearchBuffer,
		64
	)
	Backend.disable_input = ImGui.IsItemActive()
	ImGui.PopItemWidth()

	DisplayCustomPaints()
	ImGui.Spacing()
	ImGui.BeginDisabled(selected_paint == nil)
	_, matteClicked = GUI:Checkbox(_T("VEH_PAINT_MATTE_CB"), selected_paint and selected_paint.m or false)
	GUI:Tooltip(_T("VEH_PAINT_MATTE_TT"))

	if (matteClicked) then
		selected_paint.m = not selected_paint.m
	end
	ImGui.Separator()

	isPrimary, _ = GUI:Checkbox(_T("VEH_PAINT_PRIMARY_CB"), isPrimary)

	ImGui.SameLine()
	isSecondary, _ = GUI:Checkbox(_T("VEH_PAINT_SECONDARY_CB"), isSecondary)

	local text_x = ImGui.CalcTextSize(_T("GENERIC_CONFIRM"))
	if (GUI:Button(_T("GENERIC_CONFIRM"), { size = vec2:new(text_x + 20, 40) }) and selected_paint ~= nil) then
		if (not isPrimary and not isSecondary) then
			Notifier:ShowError("Samurai's Scripts", _T("VEH_PAINT_NOT_SELECTED_ERR"))
		else
			Self:GetVehicle():SetCustomPaint(
				selected_paint.hex,
				selected_paint.p,
				selected_paint.m,
				isPrimary,
				isSecondary
			)
		end
	end
	ImGui.EndDisabled()
	if selected_paint ~= nil then
		GUI:Tooltip(_T("VEH_PAINT_SAVE_TT"))
	end
end

return CustomPaintsUI
