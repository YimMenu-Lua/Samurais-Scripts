-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local YRV3                  = require("includes.features.online.yim_resupplier.YimResupplierV3")
local colMoneyGreen <const> = Color("#85BB65")
local U32_RED <const>       = Color.RED:AsU32()
local U32_GREEN <const>     = colMoneyGreen:Darken(0.12):AsU32()

---@param business CarWash|CarWashSubBusiness
---@param isParent boolean
---@param kvSpacing number
---@param clearHeatLabel string
return function(business, isParent, kvSpacing, clearHeatLabel)
	if (not business) then return end
	local unsafeFeatsEnabled = GVars.features.unsafe_feats_enabled


	local name    = business:GetName()
	local coords  = business:GetCoords()
	local heat    = business:GetHeat()
	local maxHeat = 100
	local cashSafe, maxCash, currentSafeCash

	ImGui.BeginChildEx(name,
		vec2:new(0, isParent and 385 or 280),
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

	if (isParent) then
		---@diagnostic disable-next-line
		local duffle        = business:GetDuffleBag()
		local maxDuffle     = duffle:GetCapacity()
		local duffDirtyCash = duffle:GetDirtyCash()
		local duffCleanCash = duffle:GetDuffleValue()
		local dirtyCashTxt  = string.formatmoney(duffDirtyCash)
		local cleanCashTxt  = string.formatmoney(duffCleanCash)
		local duffCashTxt   = _F("(%s %s | %s %s) / $1M",
			_T("YRV3_CWASH_CASH_CLEAN"),
			cleanCashTxt,
			_T("YRV3_CWASH_CASH_DIRTY"),
			dirtyCashTxt
		)

		ImGui.BulletText(_T("YRV3_CWASH_WORK_EARNINGS"))
		ImGui.SameLine(kvSpacing)
		ImGui.ValueBar("##carWashDuffle",
			duffCleanCash / maxDuffle,
			vec2:new(-1, 25),
			ImGuiValueBarFlags.MULTI_VAL,
			{
				value2 = duffDirtyCash / maxDuffle,
				v1Col  = U32_GREEN,
				v2Col  = U32_RED,
				fmt    = duffCashTxt
			}
		)

		---@diagnostic disable-next-line
		cashSafe        = business:GetCashSafe()
		maxCash         = cashSafe:GetCapacity()
		currentSafeCash = cashSafe:GetCashValue()
		ImGui.BulletText(_T("YRV3_CASH_SAFE"))
		ImGui.SameLine(kvSpacing)
		ImGui.ProgressBar(
			currentSafeCash / maxCash,
			-1,
			25,
			string.formatmoney(currentSafeCash)
		)
	end

	if (heat) then
		local heatcol = math.clamp(heat / 100, 0, 1)
		local heatcolR = math.clamp(heatcol + 0.1, 0, 1)
		local heatcolG = math.clamp(0.5 - heatcol, 0, 1)
		ImGui.BulletText(_T("YRV3_CWASH_HEAT"))
		ImGui.SameLine(kvSpacing)
		ImGui.PushStyleColor(ImGuiCol.PlotHistogram, heatcolR, heatcolG, 0, 1)
		ImGui.ProgressBar(
			heat / maxHeat,
			-1,
			25,
			_F("%d%%", heat)
		)
		ImGui.PopStyleColor()

		ImGui.BeginDisabled(heat == 0)
		if (GUI:Button(clearHeatLabel)) then
			business:ClearHeat()
		end
		ImGui.EndDisabled()
		ImGui.Spacing()
	end

	if (isParent) then
		---@diagnostic disable-next-line: param-type-mismatch
		ImGui.BeginDisabled(not unsafeFeatsEnabled)
		if (cashSafe:CanInstaFill()) then
			ImGui.BeginDisabled(currentSafeCash == maxCash)
			if (GUI:Button(_T("YRV3_CASH_FILL"))) then
				cashSafe:FillNow()
			end
			ImGui.EndDisabled()
			GUI:HelpMarker(_T("YRV3_CASH_FILL_TT"))
		end

		if (cashSafe:CanLoop()) then
			ImGui.BeginDisabled(currentSafeCash >= maxCash)
			cashSafe.cash_loop_enabled = GUI:CustomToggle(_T("YRV3_CASH_LOOP"), cashSafe.cash_loop_enabled)
			ImGui.EndDisabled()
		end
		ImGui.EndDisabled()
	end

	GUI:CustomToggle(_T("YRV3_CWASH_LEGAL_WORK_CD"),
		business:GetLegalWorkCooldownState(),
		{ onClick = function() business:ToggleLegalWorkCooldown(YRV3) end } -- should use IManagedValue here instead of relying on YRV3
	)

	GUI:CustomToggle(_T("YRV3_CWASH_ILLEGAL_WORK_CD"),
		business:GetIllegalWorkCooldownState(),
		{ onClick = function() business:ToggleIllegalWorkCooldown(YRV3) end }
	)

	ImGui.EndChild()
end
