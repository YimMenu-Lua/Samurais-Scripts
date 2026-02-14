-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


return function()
	local __state        = YRV3:GetState()
	local isReloading    = __state == Enums.eYRState.RELOADING
	local waitLabel      = _T("GENERIC_WAIT_LABEL")
	local label          = isReloading and ImGui.TextSpinner(waitLabel) or _T("GENERIC_RELOAD")
	local maxButtonWidth = ImGui.CalcTextSize(_F("%s ________", waitLabel)) + (ImGui.GetStyle().FramePadding.x * 2)

	ImGui.BeginDisabled(__state ~= Enums.eYRState.RUNNING)
	if (GUI:Button(label, { size = vec2:new(maxButtonWidth, 36) })) then
		YRV3:Reload()
	end
	ImGui.EndDisabled()

	if (isReloading) then
		return
	end

	ImGui.SeparatorText(_T("YRV3_AUTO_SELL"))
	ImGui.TextWrapped(_T("YRV3_AUTO_SELL_SUPPORT_NOTICE"))
	ImGui.BulletText(_T("YRV3_AUTOSELL_BUNKER_LABEL"))
	ImGui.BulletText(_T("YRV3_AUTOSELL_HANGAR_LABEL"))
	ImGui.BulletText(_T("YRV3_AUTOSELL_CEO_LABEL"))
	ImGui.BulletText(_T("YRV3_AUTOSELL_BIKER_LABEL"))
	ImGui.BulletText(_T("YRV3_AUTOSELL_LSD_LAB_LABEL"))
	ImGui.Spacing()
	local autoSellTriggered = YRV3:HasTriggeredAutoSell()
	ImGui.BeginDisabled(autoSellTriggered)
	GVars.features.yrv3.autosell, _ = GUI:CustomToggle(_T("YRV3_AUTO_SELL"), GVars.features.yrv3.autosell)
	ImGui.EndDisabled()
	GUI:Tooltip(_T("YRV3_AUTOSELL_TT"))

	if (script.is_active("fm_content_smuggler_sell")) then
		GUI:Text(_T("YRV3_HANGAR_LAND_ERR"), Color("red"))
	else
		ImGui.BeginDisabled(GVars.features.yrv3.autosell
			or autoSellTriggered
			or not YRV3:IsAnySaleInProgress()
		)
		if (GUI:Button(_T("YRV3_AUTO_SELL_MANUAL"))) then
			autoSellTriggered = true
			YRV3:FinishSale()
			ThreadManager:Run(function()
				repeat
					yield()
				until not YRV3:IsAnySaleInProgress()
				autoSellTriggered = false
			end)
		end
		ImGui.EndDisabled()
	end

	ImGui.Text(_F(_T("YRV3_AUTOSELL_CURRENT"), YRV3:GetRunningSellScriptDisplayName()))
	ImGui.SeparatorText(_T("YRV3_AUTO_FILL"))
	ImGui.Text(_T("YRV3_AUTO_FILL_DELAY"))
	ImGui.SetNextItemWidth(280)
	GVars.features.yrv3.autofill_delay, _ = ImGui.SliderFloat("##autofilldelay",
		GVars.features.yrv3.autofill_delay,
		100,
		5000,
		"%.0f ms"
	)
	ImGui.SameLine()
	ImGui.Text(_F("%.1f %s", GVars.features.yrv3.autofill_delay / 1000, _T("GENERIC_SECONDS_LABEL")))
end
