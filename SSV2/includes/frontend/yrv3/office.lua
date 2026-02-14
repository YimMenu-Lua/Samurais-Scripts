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
