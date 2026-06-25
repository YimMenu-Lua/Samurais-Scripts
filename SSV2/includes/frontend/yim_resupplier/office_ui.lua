-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local YRV3                    = require("includes.features.online.yim_resupplier.YimResupplierV3")
local measureBulletWidths     = require("includes.frontend.helpers.measure_text_width")
local drawNamePlate           = require("includes.frontend.yim_resupplier.nameplate_ui")
local drawVehicleWarehouse    = require("includes.frontend.yim_resupplier.vehicle_warehouse_ui")
local drawWarehouse           = require("includes.frontend.yim_resupplier.warehouse_ui")
local colMoneyGreen <const>   = Color("#85BB65")

---@type array<integer>
local bulletWidths            = {}
local clutterItemNameWidths   = {}
local showEarningsData        = { v = false }
local earningDataIntBuff      = nil
local earningDataIdx          = 1
local earningPopupName        = ""
local newNameBuff             = ""
local popups                  = {
	rename  = false,
	clutter = false
}
local earningData <const>     = {
	{ label = "YRV3_LIFETIME_BUY_UNDERTAKEN",  pstat = "MPX_LIFETIME_BUY_UNDERTAKEN",  min = 0, max = 5e3, step = 1,   step_fast = 100 },
	{ label = "YRV3_LIFETIME_BUY_COMPLETE",    pstat = "MPX_LIFETIME_BUY_COMPLETE",    min = 0, max = 5e3, step = 1,   step_fast = 100 },
	{ label = "YRV3_LIFETIME_SELL_UNDERTAKEN", pstat = "MPX_LIFETIME_SELL_UNDERTAKEN", min = 0, max = 5e3, step = 1,   step_fast = 100 },
	{ label = "YRV3_LIFETIME_SELL_COMPLETE",   pstat = "MPX_LIFETIME_SELL_COMPLETE",   min = 0, max = 5e3, step = 1,   step_fast = 100 },
	{ label = "YRV3_LIFETIME_EARNINGS",        pstat = "MPX_LIFETIME_CONTRA_EARNINGS", min = 0, max = 1e8, step = 1e5, step_fast = 1e6 },
}
local clutterNamesMap <const> = {
	["cash"]             = "YRV3_OFFICE_CLUTTER_CASH",
	["Swag_Silver"]      = "YRV3_OFFICE_CLUTTER_SILVER",
	["Swag_Pills"]       = "YRV3_OFFICE_CLUTTER_PILLS",
	["Swag_Med"]         = "YRV3_OFFICE_CLUTTER_MEDS",
	["Swag_JewelWatch"]  = "YRV3_OFFICE_CLUTTER_JEWEL",
	["Swag_Ivory"]       = "YRV3_OFFICE_CLUTTER_IVORY",
	["Swag_Guns"]        = "YRV3_OFFICE_CLUTTER_CUNS",
	["Swag_Gems"]        = "YRV3_OFFICE_CLUTTER_GEMS",
	["Swag_Furcoats"]    = "YRV3_OFFICE_CLUTTER_FURCOATS",
	["Swag_electronic"]  = "YRV3_OFFICE_CLUTTER_ELECTRONICS",
	["Swag_DrugStatue"]  = "YRV3_OFFICE_CLUTTER_DRUGSTATUES",
	["Swag_DrugBags"]    = "YRV3_OFFICE_CLUTTER_DRUGBAGS",
	["Swag_Counterfeit"] = "YRV3_OFFICE_CLUTTER_COUNTERFEIT",
	["Swag_Booze_cigs"]  = "YRV3_OFFICE_CLUTTER_BOOZE",
	["Swag_Art"]         = "YRV3_OFFICE_CLUTTER_ART",
}; local clutterItemsCount    = table.getlen(clutterNamesMap)

---@param office Office
local function drawRenamePopup(office)
	ImGui.Spacing()

	newNameBuff = ImGui.InputTextWithHint("##newName", _T("GENERIC_NAME"), newNameBuff, 32)

	ImGui.SameLine()
	if (GUI:Button(_T("GENERIC_SAVE"))) then
		office:Rename(newNameBuff)
		ImGui.CloseCurrentPopup()
	end
	ImGui.SameLine()
	if (GUI:Button(_T("GENERIC_CANCEL"))) then
		newNameBuff = office:GetCustomName()
		ImGui.CloseCurrentPopup()
	end

	ImGui.Spacing()
end

---@param items table<string, boolean>
---@return boolean
local function areAllItemsEnabled(items)
	for _, bool in pairs(items) do
		if (not bool) then
			return false
		end
	end
	return true
end

local function drawOfficeClutterOptions()
	local cfg        = GVars.features.yrv3.office_clutter
	local items      = cfg.items
	cfg.auto_disable = GUI:CustomToggle(_T("YRV3_OFFICE_CLUTTER_AUTO_CLEAR"), cfg.auto_disable, {
		tooltip = _T("YRV3_OFFICE_CLUTTER_AUTO_CLEAR_TT"),
	})

	ImGui.Spacing()
	ImGui.SeparatorText(_T("YRV3_OFFICE_CLUTTER_ITEM_SELECT"))

	local allEnabled = areAllItemsEnabled(items)
	local btnLabel   = allEnabled and "YRV3_CB_UNCHECK_ALL" or "YRV3_CB_CHECK_ALL"
	if (GUI:Button(_T(btnLabel))) then
		for name in pairs(items) do
			items[name] = not allEnabled
		end
	end

	local langIndex  = GVars.backend.language_index
	local labelWidth = clutterItemNameWidths[langIndex]
	if (not labelWidth) then
		local labels = {}
		for _, name in pairs(clutterNamesMap) do
			table.insert(labels, _T(name))
		end
		labelWidth                       = measureBulletWidths(labels, 60.0)
		clutterItemNameWidths[langIndex] = labelWidth
	end

	ImGui.Spacing()
	local idx = 0
	for name, bValue in pairs(items) do
		local label = _T(clutterNamesMap[name] or "GENERIC_UNKNOWN")
		items[name] = GUI:CustomToggle(label, bValue)
		idx         = idx + 1

		if (idx < clutterItemsCount and (idx & 1 == 1)) then
			ImGui.SameLine(labelWidth)
		end
	end
end

---@param data { label: string, pstat: string, min: integer, max: integer, step: integer, step_fast: integer }
local function drawStatEdit(data)
	ImGui.Spacing()
	ImGui.Text(_T(data.label))

	if (not earningDataIntBuff) then
		earningDataIntBuff = stats.get_int(data.pstat)
	end

	earningDataIntBuff = ImGui.InputInt("##new_value", earningDataIntBuff, data.step, data.step_fast)
	earningDataIntBuff = math.clamp(math.floor(earningDataIntBuff), data.min, data.max)

	ImGui.SameLine()
	if (GUI:Button(_T("GENERIC_SAVE"))) then
		stats.set_int(data.pstat, earningDataIntBuff)
		earningDataIntBuff = nil
		ImGui.CloseCurrentPopup()
	end

	ImGui.Spacing()
end

local function drawEarningsRecap()
	GUI:CustomToggleEx(_T("YRV3_SHOW_EARNINGS_DATA"), showEarningsData)
	if (not showEarningsData.v) then return end

	local lang_index  = GVars.backend.language_index
	local bulletWidth = bulletWidths[lang_index]
	if (not bulletWidth) then
		local labels = {}
		for _, data in ipairs(earningData) do
			labels[#labels + 1] = _T(data.label)
		end
		bulletWidth              = measureBulletWidths(labels, 60.0)
		bulletWidths[lang_index] = bulletWidth
	end

	ImGui.Separator()
	for i, data in ipairs(earningData) do
		if (GUI:Button(_F("%s##%d", _T("GENERIC_EDIT"), i))) then
			earningDataIdx   = i
			earningPopupName = _F("%s##%d", _T("YRV3_EDIT_EARNINGS_DATA"), i)
			ImGui.OpenPopup(earningPopupName)
		end

		ImGui.SameLine()
		ImGui.Text(_T(data.label))

		local value   = stats.get_int(data.pstat)
		local isMoney = (i == 5)
		local str     = isMoney and string.formatmoney(value) or tostring(value)
		ImGui.SameLine(bulletWidth)
		GUI:Text(str, { color = isMoney and colMoneyGreen or nil })
	end
	ImGui.Separator()

	if (ImGui.BeginPopupModal(
			earningPopupName,
			true,
			ImGuiWindowFlags.AlwaysAutoResize
			| ImGuiWindowFlags.NoSavedSettings
			| ImGuiWindowFlags.NoMove
		)) then
		drawStatEdit(earningData[earningDataIdx])
		ImGui.EndPopup()
	end
end

---@param warehouses array<Warehouse>
local function drawSpecialCargo(warehouses)
	if (not warehouses or #warehouses == 0) then
		ImGui.Text(_T("YRV3_CEO_NONE_OWNED"))
		return
	else
		drawEarningsRecap()
		ImGui.BeginTabBar("##cargoWarehouses")
		for i, wh in ipairs(warehouses) do
			ImGui.PushID(i)
			if (ImGui.BeginTabItem(_T("YRV3_WAREHOUSE_SLOT", i))) then
				drawWarehouse(wh)
				ImGui.EndTabItem()
			end
			ImGui.PopID()
		end
		ImGui.EndTabBar()
	end

	ImGui.Spacing()
	local bCond = (not script.is_active("gb_contraband_buy") and not script.is_active("fm_content_cargo"))
	ImGui.BeginDisabled(bCond)
	if (GUI:Button(_T("YRV3_FINISH_SOURCE_MISSION"))) then
		YRV3:FinishCEOCargoSourceMission()
	end
	ImGui.EndDisabled()

	if (bCond) then
		GUI:Tooltip(_T("YRV3_FINISH_SOURCE_MISSION_TT"))
	end
end

local function contextCallback()
	if (ImGui.MenuItem(_T("GENERIC_RENAME"))) then
		popups.rename = true
		ImGui.CloseCurrentPopup()
	end

	if (ImGui.MenuItem(_T("YRV3_OFFICE_CLUTTER_LABEL"))) then
		popups.clutter = true
		ImGui.CloseCurrentPopup()
	end
end

return function()
	local office = YRV3:GetOffice()
	if (not office) then
		ImGui.Text(_T("YRV3_CEO_OFFICE_NOT_OWNED"))
		return
	end

	drawNamePlate(office, { customName = office:GetCustomName(), contextMenuCallback = contextCallback })

	if (popups.rename) then
		popups.rename = false
		newNameBuff   = office:GetCustomName()
		ImGui.OpenPopup("##renameCEO")
	end

	if (popups.clutter) then
		popups.clutter = false
		ImGui.OpenPopup("##officeClutter")
	end

	if (ImGui.BeginPopupModal(
			"##renameCEO",
			true,
			ImGuiWindowFlags.AlwaysAutoResize
			| ImGuiWindowFlags.NoSavedSettings
			| ImGuiWindowFlags.NoMove
		)) then
		drawRenamePopup(office)
		ImGui.EndPopup()
	end

	if (ImGui.BeginPopupModal(
			"##officeClutter",
			true,
			ImGuiWindowFlags.AlwaysAutoResize
			| ImGuiWindowFlags.NoSavedSettings
			| ImGuiWindowFlags.NoMove
		)) then
		drawOfficeClutterOptions()
		ImGui.EndPopup()
	end

	ImGui.Spacing()
	local vehicleWarehouse = office:GetVehicleWarehouse()
	local cargoWarehouses  = office:GetCargoWarehouses()
	if (ImGui.BeginTabBar("##import_export_")) then
		if (ImGui.BeginTabItem(_T("YRV3_CARGO_WAREHOUSES_LABEL"))) then
			drawSpecialCargo(cargoWarehouses)
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem(_T("YRV3_VEHICLE_WAREHOUSE_LABEL"))) then
			drawVehicleWarehouse(vehicleWarehouse)
			ImGui.EndTabItem()
		end
		ImGui.EndTabBar()
	end
end
