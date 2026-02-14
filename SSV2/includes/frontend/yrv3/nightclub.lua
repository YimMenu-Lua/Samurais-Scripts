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
local colMoneyGreen          = Color("#85BB65")
local tempHubVal             = 0
local bools                  = {
	coloredNameplate = false,
	bigTips          = false
}

---@type table<string, integer>
local bulletWidths           = {}

local function getClubNameColor()
	-- synthwave and pain
	local t      = os.clock()
	local beat   = (math.sin(t * 1.8) + 1) * 0.5
	local accent = ((math.sin(t * 6.0) + 1) * 0.5) ^ 1.5
	local hue    = (t * 0.05) % 1.0
	local base   = Color(12, 12, 18, 220)
	local glow   = Color.FromHSV(hue, 0.7, 0.8, 1)
	local flash  = Color.FromHSV((hue + 0.2) % 1.0, 0.9, 1.0, 1)
	local bg     = base:Mix(glow, beat * 0.6)
	return bg:Mix(flash, accent * 0.8)
end

Backend:RegisterEventCallback(Enums.eBackendEvent.SESSION_SWITCH, function()
	bools.bigTips = false
end)

return function()
	local HubTotalValue = 0
	local club = YRV3:GetNightclub()
	if (not club) then
		ImGui.Text(_T("YRV3_CLUB_NOT_OWNED"))
		return
	end

	local bg
	if (bools.coloredNameplate) then
		bg = getClubNameColor()
		ImGui.PushStyleColor(ImGuiCol.Border, bg:AsU32())
	end

	drawNamePlate(club, club:GetCustomName(), bg)

	if (bools.coloredNameplate) then
		ImGui.PopStyleColor()
	end

	bools.coloredNameplate, _ = GUI:CustomToggle("Synthwave & Pain", bools.coloredNameplate)
	ImGui.Spacing()

	local iso         = GVars.backend.language_code
	local bulletWidth = bulletWidths[iso]
	if (not bulletWidth) then
		bulletWidth = measureBulletWidths({
			_T("YRV3_POPULARITY"),
			_T("YRV3_CASH_SAFE"),
		}, 60.0)

		bulletWidths[iso] = bulletWidth
	end

	local popValue  = club:GetPopularity()
	local cashSafe  = club:GetCashSafe()
	local cashValue = cashSafe:GetCashValue()
	local maxCash   = cashSafe:GetCapacity()

	ImGui.BulletText(_T("YRV3_POPULARITY"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(popValue / 1e3,
		-1,
		25,
		_F("%d%%", math.floor(popValue / 10))
	)

	ImGui.BulletText(_T("YRV3_CASH_SAFE"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(
		cashValue / maxCash,
		-1,
		25,
		string.formatmoney(cashValue)
	)

	ImGui.Spacing()

	ImGui.BeginDisabled(popValue >= 999)
	if (GUI:Button(_F("%s %s", _T("GENERIC_MAX"), _T("YRV3_POPULARITY")))) then
		club:MaxPopularity()
	end
	ImGui.EndDisabled()

	GVars.features.yrv3.nc_always_popular, _ = GUI:CustomToggle(
		_T("YRV3_NC_ALWAYS_POPULAR"),
		GVars.features.yrv3.nc_always_popular,
		{
			onClick = function(v)
				if (v) then
					club:LockPopularityDecay()
				else
					club:RestorePopularityDecay()
				end
			end
		}
	)

	drawCashSafeLoopToggle(cashSafe)

	bools.bigTips, _ = GUI:CustomToggle(
		_T("YRV3_MILLION_DOLLAR_TIPS"),
		bools.bigTips,
		{
			onClick = function(v)
				club:ToggleBigTips(v)
			end
		}
	)
	GUI:HelpMarker(_T("YRV3_MILLION_DOLLAR_TIPS_TT"))

	local hubs = club:GetSubBusinesses()
	if (not hubs) then
		return
	end

	local hubsize = #hubs
	if (hubsize == 0) then
		return
	end

	ImGui.Spacing()
	ImGui.SeparatorText(_T("YRV3_BUSINESS_HUB"))

	ImGui.BulletText(_T("YRV3_VALUE_TOTAL"))
	ImGui.SameLine()
	GUI:Text(string.formatmoney(tempHubVal), { color = colMoneyGreen })
	ImGui.Spacing()

	for i = 1, hubsize do
		ImGui.PushID(i)
		ImGui.SetNextWindowBgAlpha(0.64)
		ImGui.BeginChildEx("##hub_child",
			vec2:new(90, 300),
			ImGuiChildFlags.AlwaysUseWindowPadding,
			ImGuiWindowFlags.NoScrollbar
		)

		local this       = hubs[i]
		local prod       = this:GetProductCount()
		local hub_value  = this:GetProductValue()
		HubTotalValue    = HubTotalValue + hub_value

		local hub_name   = this:GetName() or _F("Hub %d", i)
		local text_width = ImGui.CalcTextSize(hub_name)
		ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (ImGui.GetContentRegionAvail() - text_width) * 0.5)
		ImGui.Text(hub_name)

		ImGui.SetWindowFontScale(0.68)
		local max_units   = this:GetMaxUnits()
		local prod_txt    = _F("%s/%s", prod, max_units)
		local text_width2 = ImGui.CalcTextSize(prod_txt)
		ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (ImGui.GetContentRegionAvail() - text_width2) * 0.5)
		ImGui.Text(prod_txt)
		ImGui.SetWindowFontScale(1)

		ImGui.Spacing()
		ImGui.SetCursorPosX((ImGui.GetCursorPosX() + 35) * 0.5)
		ImGui.ValueBar(
			_F("##bb_hub_%d", i),
			prod / max_units,
			vec2:new(40, 140),
			ImGuiValueBarFlags.VERTICAL
		)

		ImGui.SetCursorPosX((ImGui.GetCursorPosX() + 40) * 0.5)
		-- TODO: Fix glitchy behavior + session disconnect on Enhanced/YLAPI(?)
		ImGui.BeginDisabled(Game.IsEnhanced())
		ImGui.BeginDisabled(prod >= max_units)
		this.fast_prod_enabled, _ = GUI:CustomToggle("##fast_prod", this.fast_prod_enabled)
		ImGui.EndDisabled()
		GUI:Tooltip(_T("YRV3_TRIGGER_PROD_HUB_TT"))

		local prod_time       = this:GetTimeLeftBeforeProd()
		local safe_to_trigger = this:CanTriggerProduction() and not this.fast_prod_running
		local btn_label       = (safe_to_trigger or prod_time <= -1)
			and _T("YRV3_TRIGGER_PROD_HUB")
			or ImGui.TextSpinner()

		ImGui.BeginDisabled(not safe_to_trigger or prod >= max_units)
		if (GUI:Button(btn_label, { size = vec2:new(65, 30) })) then
			this:TriggerProduction()
		end
		ImGui.EndDisabled()
		ImGui.EndDisabled()

		ImGui.EndChild()
		ImGui.PopID()

		ImGui.SameLine()
		if (ImGui.GetContentRegionAvail() < 90) then
			ImGui.NewLine()
		end
	end

	tempHubVal = HubTotalValue
end
