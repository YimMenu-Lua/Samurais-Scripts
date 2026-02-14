-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local measureBulletWidths = require("includes.frontend.helpers.measure_text_width")
local colMoneyGreen       = Color("#85BB65")
local colGreen            = Color("green")
local colRed              = Color("red")
local drawDetailsTable    = false
local bottomTextSize

---@type table<string, integer>
local bulletWidths        = {}

---@param warehouse? VehicleWarehouse
return function(warehouse)
	if (not warehouse) then
		ImGui.Text(_T("YRV3_IE_WH_NOT_OWNED"))
		return
	end

	local iso         = GVars.backend.language_code
	local bulletWidth = bulletWidths[iso]
	if (not bulletWidth) then
		bulletWidth = measureBulletWidths({
			_T("YRV3_IE_VEHS_AMT"),
			_T("YRV3_IE_VEHS_BASE_VAL_TOTAL"),
			_T("YRV3_IE_VEH_RANGE_LOW"),
			_T("YRV3_IE_VEH_RANGE_MID"),
			_T("YRV3_IE_VEH_RANGE_HIGH"),
			_T("YRV3_IE_STEAL_TOP_CHANCE"),
		}, 60.0)

		bulletWidths[iso] = bulletWidth
	end

	local name       = warehouse:GetName()
	local coords     = warehouse:GetCoords()
	local storedVehs = warehouse:GetStoredVehicles()
	local totalValue = warehouse:GetEstimatedIncome()
	local top        = warehouse:GetTopRangeCount()
	local mid        = warehouse:GetMidRangeCount()
	local low        = warehouse:GetLowRangeCount()
	local count      = storedVehs and #storedVehs or 0
	local maxStorage = 40

	if (not bottomTextSize) then
		ImGui.SetWindowFontScale(0.85)
		bottomTextSize = vec2:new(ImGui.CalcTextSize(_T("YRV3_IE_STEAL_THRESHOLD_TT"),
			false,
			ImGui.GetWindowWidth() - (ImGui.GetStyle().WindowPadding.x * 4)
		))
		ImGui.SetWindowFontScale(1.0)
	end

	ImGui.BeginChildEx(name,
		vec2:new(0, 365 + bottomTextSize.y),
		ImGuiChildFlags.AlwaysUseWindowPadding,
		ImGuiWindowFlags.NoScrollbar
	)

	ImGui.SeparatorText(name)
	if (coords) then
		if (GUI:Button(_T("GENERIC_TELEPORT"))) then
			LocalPlayer:Teleport(coords, false)
		end

		ImGui.SameLine()
		if (GUI:Button(_T("GENERIC_SET_WAYPOINT"))) then
			Game.SetWaypointCoords(coords)
		end
	end
	ImGui.Separator()
	ImGui.Spacing()

	ImGui.BulletText(_T("YRV3_IE_VEHS_AMT"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(count / maxStorage, -1, 25, _F("%d / 40", count))

	ImGui.BulletText(_T("YRV3_IE_VEHS_BASE_VAL_TOTAL"))
	ImGui.SameLine(bulletWidth)
	GUI:Text(string.formatmoney(totalValue), { color = colMoneyGreen })

	ImGui.Spacing()
	ImGui.Text(_T("YRV3_IE_VEHS_OVERVIEW"))
	local low_col = low == 10 and colGreen or colRed
	local mid_col = mid == 10 and colGreen or colRed
	local top_col = top < 10 and colRed or colGreen
	ImGui.BulletText(_T("YRV3_IE_VEH_RANGE_LOW"))
	ImGui.SameLine(bulletWidth)
	GUI:Text(tostring(low), { color = low_col })
	ImGui.SameLine()
	ImGui.Text("/ 10")

	ImGui.BulletText(_T("YRV3_IE_VEH_RANGE_MID"))
	ImGui.SameLine(bulletWidth)
	GUI:Text(tostring(mid), { color = mid_col })
	ImGui.SameLine()
	ImGui.Text("/ 10")

	ImGui.BulletText(_T("YRV3_IE_VEH_RANGE_HIGH"))
	ImGui.SameLine(bulletWidth)
	GUI:Text(tostring(top), { color = top_col })
	ImGui.SameLine()
	ImGui.Text("/ 10")

	ImGui.Spacing()
	ImGui.Text(_T("YRV3_IE_STEAL_TOP_CHANCE"))
	ImGui.SameLine(bulletWidth)
	ImGui.Text(_T(warehouse:HasReachedOptimalStealingThreshold()
		and "YRV3_IE_STEAL_THRESHOLD_TRUE"
		or "YRV3_IE_STEAL_THRESHOLD_FALSE")
	)

	ImGui.SetWindowFontScale(0.85)
	ImGui.TextWrapped(_T("YRV3_IE_STEAL_THRESHOLD_TT"))
	ImGui.SetWindowFontScale(1.0)
	ImGui.EndChild()

	if (count == 0) then
		return
	end

	if (Backend.debug_mode) then
		if (ImGui.Button("Test")) then
			warehouse:FinishStealMission()
		end
	end

	drawDetailsTable = GUI:Checkbox(_T("YRV3_IE_VEHS_DETAILS_CB"), drawDetailsTable)

	if (not drawDetailsTable) then
		return
	end

	if (ImGui.BeginTable("##ie_veh_storage", 5, ImGuiTableFlags.RowBg | ImGuiTableFlags.Borders | ImGuiTableFlags.BordersInner)) then
		ImGui.TableSetupColumn(_T("YRV3_IE_VEH_SLOT"), ImGuiTableColumnFlags.WidthFixed, 40)
		ImGui.TableSetupColumn(_T("YRV3_IE_VEH_NAME"))
		ImGui.TableSetupColumn(_T("YRV3_IE_VEH_PLATE"))
		ImGui.TableSetupColumn(_T("YRV3_IE_VEH_RANGE"))
		ImGui.TableSetupColumn(_T("YRV3_IE_VEH_COMMISSION"))
		ImGui.TableHeadersRow()

		for _, veh in ipairs(storedVehs) do
			ImGui.TableNextRow()

			ImGui.TableSetColumnIndex(0)
			ImGui.Text(tostring(veh.slot))

			ImGui.TableSetColumnIndex(1)
			ImGui.Text(veh.name)

			ImGui.TableSetColumnIndex(2)
			ImGui.Text(veh.plate_text)

			ImGui.TableSetColumnIndex(3)
			ImGui.Text(veh.range_str)

			ImGui.TableSetColumnIndex(4)
			ImGui.Text(veh.commis_fmt)
		end
		ImGui.EndTable()
	end
end
