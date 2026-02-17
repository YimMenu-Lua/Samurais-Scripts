-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.



local drawNamePlate        = require("includes.frontend.yrv3.nameplate")
local drawVehicleWarehouse = require("includes.frontend.yrv3.vehicle_warehouse")
local drawWarehouse        = require("includes.frontend.yrv3.warehouse")
local measureBulletWidths  = require("includes.frontend.helpers.measure_text_width")
local colMoneyGreen        = Color("#85BB65")

---@type table<string, integer>
local bulletWidths         = {}
local showEarningsData     = false
local earningDataIntBuff   = nil
local earningDataIdx       = 1
local earningPopupName     = ""
local earningData <const>  = {
	{ label = "YRV3_LIFETIME_BUY_UNDERTAKEN",  pstat = "MPX_LIFETIME_BUY_UNDERTAKEN",  min = 0, max = 5e3, step = 1,   step_fast = 100 },
	{ label = "YRV3_LIFETIME_BUY_COMPLETE",    pstat = "MPX_LIFETIME_BUY_COMPLETE",    min = 0, max = 5e3, step = 1,   step_fast = 100 },
	{ label = "YRV3_LIFETIME_SELL_UNDERTAKEN", pstat = "MPX_LIFETIME_SELL_UNDERTAKEN", min = 0, max = 5e3, step = 1,   step_fast = 100 },
	{ label = "YRV3_LIFETIME_SELL_COMPLETE",   pstat = "MPX_LIFETIME_SELL_COMPLETE",   min = 0, max = 5e3, step = 1,   step_fast = 100 },
	{ label = "YRV3_LIFETIME_EARNINGS",        pstat = "MPX_LIFETIME_CONTRA_EARNINGS", min = 0, max = 1e8, step = 1e5, step_fast = 1e6 },
}

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

return function()
	local office = YRV3:GetOffice()
	if (not office) then
		ImGui.Text(_T("YRV3_CEO_OFFICE_NOT_OWNED"))
		return
	end

	drawNamePlate(
		office,
		office:GetCustomName()
	)

	ImGui.Spacing()
	showEarningsData = GUI:CustomToggle(_T("YRV3_SHOW_EARNINGS_DATA"), showEarningsData)

	if (showEarningsData) then
		local iso         = GVars.backend.language_code
		local bulletWidth = bulletWidths[iso]
		if (not bulletWidth) then
			local labels = {}
			for _, data in ipairs(earningData) do
				labels[#labels + 1] = _T(data.label)
			end
			bulletWidth = measureBulletWidths(labels, 60.0)

			bulletWidths[iso] = bulletWidth
		end

		ImGui.Separator()
		for i, data in ipairs(earningData) do
			local value = stats.get_int(data.pstat)
			ImGui.BulletText(_T(data.label))
			ImGui.SameLine(bulletWidth)
			if (GUI:Button(_F("%s##%d", _T("GENERIC_EDIT"), i))) then
				earningDataIdx = i
				earningPopupName = _F("%s##%d", _T("YRV3_EDIT_EARNINGS_DATA"), i)
				ImGui.OpenPopup(earningPopupName)
			end
			ImGui.SameLine()
			local isMoney = (i == 5)
			local str     = isMoney and string.formatmoney(value) or tostring(value)
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

	ImGui.Spacing()
	local vehicleWarehouse = office:GetVehicleWarehouse()
	local cargoWarehouses  = office:GetCargoWarehouses()
	if (ImGui.BeginTabBar("##import_export_")) then
		if (ImGui.BeginTabItem(_T("YRV3_CARGO_WAREHOUSES_LABEL"))) then
			if (not cargoWarehouses or #cargoWarehouses == 0) then
				ImGui.Text(_T("YRV3_CEO_NONE_OWNED"))
			else
				ImGui.BeginTabBar("##cargoWarehouses")
				for i, wh in ipairs(cargoWarehouses) do
					ImGui.PushID(i)
					if (ImGui.BeginTabItem(_F(_T("YRV3_WAREHOUSE_SLOT"), i))) then
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
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem(_T("YRV3_VEHICLE_WAREHOUSE_LABEL"))) then
			drawVehicleWarehouse(vehicleWarehouse)
			ImGui.EndTabItem()
		end
		ImGui.EndTabBar()
	end
end
