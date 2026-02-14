-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.

local drawCashSafeLoopToggle = require("includes.frontend.yrv3.cashloop_toggle")
local colMoneyGreen = Color("#85BB65")

---@param business CarWash|CarWashSubBusiness
---@param isParent boolean
---@param kvSpacing number
---@param clearHeatLabel string
return function(business, isParent, kvSpacing, clearHeatLabel)
	if (not business) then
		return
	end

	local name    = business:GetName()
	local coords  = business:GetCoords()
	local heat    = business:GetHeat()
	local maxHeat = 100

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
		---@diagnostic disable-next-line
		local cashSafe      = business:GetCashSafe()
		local maxCash       = cashSafe:GetCapacity()
		local maxDuffle     = duffle:GetCapacity()
		local duffDirtyCash = duffle:GetDirtyCash()
		local duffCleanCash = duffle:GetDuffleValue()
		local safeCash      = cashSafe:GetCashValue()
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
				v1Col  = colMoneyGreen:Darken(0.12):AsU32(),
				v2Col  = Color("red"):AsU32(),
				fmt    = duffCashTxt
			}
		)

		ImGui.BulletText(_T("YRV3_CASH_SAFE"))
		ImGui.SameLine(kvSpacing)
		ImGui.ProgressBar(
			safeCash / maxCash,
			-1,
			25,
			string.formatmoney(safeCash)
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
		drawCashSafeLoopToggle(business:GetCashSafe())
	end

	GUI:CustomToggle(_T("YRV3_CWASH_LEGAL_WORK_CD"),
		business:GetLegalWorkCooldownState(),
		{
			onClick = function()
				business:ToggleLegalWorkCooldown()
			end
		}
	)

	GUI:CustomToggle(_T("YRV3_CWASH_ILLEGAL_WORK_CD"),
		business:GetIllegalWorkCooldownState(),
		{
			onClick = function()
				business:ToggleIllegalWorkCooldown()
			end
		}
	)

	ImGui.EndChild()
end
