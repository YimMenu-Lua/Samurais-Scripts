-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local YRV3                   = require("includes.features.online.yim_resupplier.YimResupplierV3")
local measureBulletWidths    = require("includes.frontend.helpers.measure_text_width")
local drawNamePlate          = require("includes.frontend.yim_resupplier.nameplate_ui")
local drawCashSafeLoopToggle = require("includes.frontend.yim_resupplier.cashloop_toggle")
local colMoneyGreen <const>  = Color("#85BB65")
local childWidth             = 240

---@type table<integer, integer>
local bulletWidths           = {}

return function()
	local SalvageYard = YRV3:GetSalvageYard()
	if (not SalvageYard) then
		ImGui.Text(_T("SY_NOT_OWNED"))
		return
	end

	drawNamePlate(
		SalvageYard,
		SalvageYard:GetName(),
		Color(ImGui.GetStyleColorVec4(ImGuiCol.Text)),
		true
	)

	ImGui.Spacing()

	local lang_index  = GVars.backend.language_index
	local bulletWidth = bulletWidths[lang_index]
	if (not bulletWidth) then
		bulletWidth = measureBulletWidths({
			_T("YRV3_CASH_SAFE"),
			_T("SY_INCOME_THRESHOLD"),
		}, 60.0)

		bulletWidths[lang_index] = bulletWidth
	end

	local cashSafe  = SalvageYard:GetCashSafe()
	local cashValue = cashSafe:GetCashValue()
	local maxCash   = cashSafe:GetCapacity()

	ImGui.BulletText(_T("YRV3_CASH_SAFE"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(
		cashValue / maxCash,
		-1,
		25,
		string.formatmoney(cashValue)
	)

	local threshold = SalvageYard:GetIncomeThreshold()
	ImGui.BulletText(_T("SY_INCOME_THRESHOLD"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(threshold / 100, -1, 25)

	ImGui.BeginDisabled(SalvageYard:GetIncomeThreshold() >= 100)
	if (GUI:Button(_T("SY_MAX_THRESHOLD"))) then
		SalvageYard:MaximizeIncome()
	end
	ImGui.EndDisabled()

	GVars.features.yrv3.sy_always_max_income, _ = GUI:CustomToggle(
		_T("SY_ALWAYS_MAX_INCOME"),
		GVars.features.yrv3.sy_always_max_income,
		{
			onClick = function(v)
				if (v) then
					SalvageYard:LockIncomeDecay()
				else
					SalvageYard:RestoreIncomeDecay()
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
		ImGui.BeginDisabled(not SalvageYard:IsTowMissionActive() or SalvageYard:IsBringingTowMissionTarget())
		if (GUI:Button(_T("SY_TOW_MISSION_BRING_VEH"))) then
			SalvageYard:BringTowMissionTarget()
		end
		ImGui.EndDisabled()
		GUI:HelpMarker(_T("SY_TOW_MISSION_BRING_VEH_TT"))

		ImGui.Spacing()
		ImGui.Separator()

		for i = 1, 2 do
			local isTaken = SalvageYard:IsLiftTaken(i)
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
				local vehName   = Game.GetVehicleDisplayName(SalvageYard:GetSalvageModelOnLift(i))
				local value     = string.formatmoney(SalvageYard:GetSalvageValueOnLift(i))
				local timeleft  = SalvageYard:GetSalvagePosixForLift(i)
				local timeStr   = Time.FormatSeconds(timeleft - Time.Epoch())
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
				GUI:Text(value, { color = colMoneyGreen })

				ImGui.BulletText(_T("GENERIC_TIME_LEFT"))
				ImGui.SameLine()
				ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - timeWidth - 10)
				ImGui.Text(timeStr)

				ImGui.Separator()

				ImGui.BeginDisabled(timeleft <= 1)
				if (GUI:Button(_T("SY_INSTANT_SALVAGE"))) then
					SalvageYard:SalvageNow(i)
				end
				ImGui.EndDisabled()
			end
			ImGui.EndChild()
			ImGui.EndDisabled()
			ImGui.SameLineIfAvail(childWidth)
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
			ImGui.Text(_F(_T("SY_WEEKLY_CAR_STATUS"), i + 1, SalvageYard:GetWeeklyRobberyStatus(i)))
			ImGui.Separator()
		end

		ImGui.Spacing()

		ImGui.Text(_F(_T("SY_CURRENT_ROBBERY"), SalvageYard:GetRobberyName()))
		if (SalvageYard:IsRobberyActive()) then
			ImGui.Text(
				_F(_T("SY_ROBBERY_ACTIVE_CAR"),
					SalvageYard:GetRobberyVehicleName())
			)
			ImGui.Text(_F(_T("SY_ROBBERY_CAR_VALUE"), SalvageYard:GetRobberyValue()))
			ImGui.Text(_F(_T("SY_ROBBERY_CAN_KEEP_CAR"), tostring(SalvageYard:GetRobberyKeepState())))

			if (GUI:Button(_T("SY_DOUBLE_CAR_WORTH"))) then
				SalvageYard:DoubleCarWorth()
			end

			ImGui.SameLine()
			ImGui.BeginDisabled(SalvageYard:ArePrepsCompleted())
			if (GUI:Button(_T("SY_COMPLETE_PREPARATIONS"))) then
				SalvageYard:SkipPreps()
			end
			ImGui.EndDisabled()
		end

		ImGui.Spacing()

		for i = 1, 4 do
			local carName = SalvageYard:GetSalvageCarInSlot(i)
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
				local carValue  = string.formatmoney(SalvageYard:GetRobberyCarValue(i))
				local valWidth  = ImGui.CalcTextSize(carValue)
				ImGui.BulletText(_T("GENERIC_VEHICLE"))
				ImGui.SameLine()
				ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - nameWidth - 10)
				ImGui.Text(carName)

				ImGui.BulletText(_T("GENERIC_VALUE"))
				ImGui.SameLine()
				ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - valWidth - 10)
				GUI:Text(string.formatmoney(carValue), { color = colMoneyGreen })
			end

			ImGui.EndChild()
			ImGui.EndDisabled()
			ImGui.SameLineIfAvail(childWidth)
		end
		ImGui.EndTabItem()
	end
	ImGui.EndTabBar()
end
