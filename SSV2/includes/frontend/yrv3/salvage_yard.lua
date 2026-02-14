-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local measureBulletWidths    = require("includes.frontend.helpers.measure_text_width")
local drawNamePlate          = require("includes.frontend.yrv3.nameplate")
local drawCashSafeLoopToggle = require("includes.frontend.yrv3.cashloop_toggle")

---@type table<string, integer>
local bulletWidths           = {}

return function()
	local salvage_yard = YRV3:GetSalvageYard()
	if (not salvage_yard) then
		ImGui.Text(_T("SY_NOT_OWNED"))
		return
	end

	drawNamePlate(
		salvage_yard,
		salvage_yard:GetName(),
		Color(ImGui.GetStyleColorVec4(ImGuiCol.Text)),
		true
	)

	ImGui.Spacing()

	local iso         = GVars.backend.language_code
	local bulletWidth = bulletWidths[iso]
	if (not bulletWidth) then
		bulletWidth = measureBulletWidths({
			_T("YRV3_CASH_SAFE"),
			_T("SY_INCOME_THRESHOLD"),
		}, 60.0)

		bulletWidths[iso] = bulletWidth
	end

	local childWidth = 240
	local cashSafe   = salvage_yard:GetCashSafe()
	local cashValue  = cashSafe:GetCashValue()
	local maxCash    = cashSafe:GetCapacity()

	ImGui.BulletText(_T("YRV3_CASH_SAFE"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(
		cashValue / maxCash,
		-1,
		25,
		string.formatmoney(cashValue)
	)

	local threshold = salvage_yard:GetIncomeThreshold()
	ImGui.BulletText(_T("SY_INCOME_THRESHOLD"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(threshold / 100, -1, 25)

	ImGui.BeginDisabled(salvage_yard:GetIncomeThreshold() >= 100)
	if (GUI:Button(_T("SY_MAX_THRESHOLD"))) then
		salvage_yard:MaximizeIncome()
	end
	ImGui.EndDisabled()

	GVars.features.yrv3.sy_always_max_income, _ = GUI:CustomToggle(
		_T("SY_ALWAYS_MAX_INCOME"),
		GVars.features.yrv3.sy_always_max_income,
		{
			onClick = function(v)
				if (v) then
					salvage_yard:LockIncomeDecay()
				else
					salvage_yard:RestoreIncomeDecay()
				end
			end,
		}
	)
	GUI:HelpMarker(_T("SY_ALWAYS_MAX_INCOME_TT"))

	drawCashSafeLoopToggle(cashSafe)

	ImGui.Spacing()
	ImGui.BeginTabBar("##salvage_yard_tb")
	if (ImGui.BeginTabItem(_T("SY_CHOP_SHOP"))) then
		ImGui.Spacing()
		GVars.features.yrv3.sy_disable_tow_cd = GUI:CustomToggle(
			_T("SY_DISABLE_TOWING_COOLDOWN"),
			GVars.features.yrv3.sy_disable_tow_cd,
			{
				onClick = function()
					YRV3:SetCooldownStateDirty("sy_disable_tow_cd", true)
				end
			}
		)
		ImGui.BeginDisabled(not salvage_yard:IsTowMissionActive() or salvage_yard:IsBringingTowMissionTarget())
		if (GUI:Button(_T("SY_TOW_MISSION_BRING_VEH"))) then
			salvage_yard:BringTowMissionTarget()
		end
		ImGui.EndDisabled()
		GUI:HelpMarker(_T("SY_TOW_MISSION_BRING_VEH_TT"))

		ImGui.Spacing()
		ImGui.Separator()

		for i = 1, 2 do
			local isTaken = salvage_yard:IsLiftTaken(i)
			ImGui.SetNextWindowBgAlpha(0.64)
			ImGui.BeginDisabled(not isTaken)
			ImGui.BeginChildEx(
				_F("##lift%d", i),
				vec2:new(childWidth, isTaken and 210 or 100),
				ImGuiChildFlags.AlwaysUseWindowPadding,
				ImGuiWindowFlags.NoScrollbar
			)
			ImGui.SeparatorText(_F(_T("SY_LIFT"), i))
			ImGui.Spacing()

			if (not isTaken) then
				ImGui.Text(_T("SY_LIFT_EMPTY"))
			else
				local vehName   = vehicles.get_vehicle_display_name(salvage_yard:GetCarModelOnLift(i))
				local value     = string.formatmoney(salvage_yard:GetCarValueOnLift(i))
				local timeleft  = salvage_yard:GetSalvagePosixForLift(i)
				local timeStr   = Time.format_time_seconds(timeleft - Time.epoch())
				local nameWidth = ImGui.CalcTextSize(vehName)
				local valWidth  = ImGui.CalcTextSize(value)
				local timeWidth = ImGui.CalcTextSize(timeStr)

				ImGui.BulletText(_T("GENERIC_VEHICLE"))
				ImGui.SameLine()
				ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - nameWidth - 10)
				ImGui.Text(vehName)

				ImGui.BulletText(_T("GENERIC_VALUE"))
				ImGui.SameLine()
				ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - valWidth - 10)
				GUI:Text(value, Color("#00AA00"))

				ImGui.BulletText(_T("GENERIC_TIME_LEFT"))
				ImGui.SameLine()
				ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - timeWidth - 10)
				ImGui.Text(timeStr)

				ImGui.Separator()

				ImGui.BeginDisabled(timeleft <= 1e3)
				if (GUI:Button(_T("SY_INSTANT_SALVAGE"))) then
					salvage_yard:SalvageNow(i)
				end
				ImGui.EndDisabled()
			end
			ImGui.EndChild()
			ImGui.EndDisabled()
			ImGui.SameLine()
			if (ImGui.GetContentRegionAvail() < childWidth) then
				ImGui.NewLine()
			end
		end
		ImGui.EndTabItem()
	end

	if (ImGui.BeginTabItem(_T("SY_CAR_ROBBERIES"))) then
		GVars.features.yrv3.sy_disable_rob_cd = GUI:CustomToggle(
			_T("SY_DISABLE_COOLDOWN"),
			GVars.features.yrv3.sy_disable_rob_cd,
			{
				onClick = function()
					YRV3:SetCooldownStateDirty("sy_disable_rob_cd", true)
				end
			}
		)

		ImGui.SameLine()
		GVars.features.yrv3.sy_disable_rob_weekly_cd = GUI:CustomToggle(
			_T("SY_DISABLE_WEEKLY_COOLDOWN"),
			GVars.features.yrv3.sy_disable_rob_weekly_cd,
			{
				onClick = function()
					YRV3:SetCooldownStateDirty("sy_disable_rob_weekly_cd", true)
				end
			}
		)

		ImGui.Spacing()

		ImGui.SeparatorText(_T("SY_WEEKLY_ROBBERIES"))
		for i = 0, 2 do
			ImGui.Text(_F(_T("SY_WEEKLY_CAR_STATUS"), i + 1, salvage_yard:GetWeeklyRobberyStatus(i)))
			ImGui.Separator()
		end

		ImGui.Spacing()

		ImGui.Text(_F(_T("SY_CURRENT_ROBBERY"), salvage_yard:GetRobberyName()))
		if (salvage_yard:IsRobberyActive()) then
			ImGui.Text(
				_F(_T("SY_ROBBERY_ACTIVE_CAR"),
					salvage_yard:GetRobberyVehicleName())
			)
			ImGui.Text(_F(_T("SY_ROBBERY_CAR_VALUE"), salvage_yard:GetRobberyValue()))
			ImGui.Text(_F(_T("SY_ROBBERY_CAN_KEEP_CAR"), tostring(salvage_yard:GetRobberyKeepState())))

			if (GUI:Button(_T("SY_DOUBLE_CAR_WORTH"))) then
				salvage_yard:DoubleCarWorth()
			end

			ImGui.SameLine()
			ImGui.BeginDisabled(salvage_yard:ArePrepsCompleted())
			if (GUI:Button(_T("SY_COMPLETE_PREPARATIONS"))) then
				salvage_yard:SkipPreps()
			end
			ImGui.EndDisabled()
		end

		ImGui.Spacing()

		for i = 1, 4 do
			local carName = salvage_yard:GetRobberyCarInSlot(i)
			local isAvailable = carName and not carName:isempty()
			ImGui.SetNextWindowBgAlpha(0.64)
			ImGui.BeginDisabled(not isAvailable)
			ImGui.BeginChildEx(
				_F("##robbery%d", i),
				vec2:new(childWidth, isAvailable and 180 or 100),
				ImGuiChildFlags.AlwaysUseWindowPadding,
				ImGuiWindowFlags.NoScrollbar
			)

			ImGui.SeparatorText(_F(_T("SY_VEH_SLOT"), i))
			if (not isAvailable) then
				ImGui.Text(_T("SY_EMPTY"))
			else
				local nameWidth = ImGui.CalcTextSize(carName)
				local carValue  = string.formatmoney(salvage_yard:GetRobberyCarValue(i))
				local valWidth  = ImGui.CalcTextSize(carValue)
				ImGui.BulletText(_T("GENERIC_VEHICLE"))
				ImGui.SameLine()
				ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - nameWidth - 10)
				ImGui.Text(carName)

				ImGui.BulletText(_T("GENERIC_VALUE"))
				ImGui.SameLine()
				ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - valWidth - 10)
				GUI:Text(string.formatmoney(carValue), Color("#00AA00"))
			end

			ImGui.EndChild()
			ImGui.EndDisabled()
			ImGui.SameLine()
			if (ImGui.GetContentRegionAvail() < childWidth) then
				ImGui.NewLine()
			end
		end
		ImGui.EndTabItem()
	end
	ImGui.EndTabBar()
end
