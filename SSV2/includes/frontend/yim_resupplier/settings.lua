-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local timer_data <const> = {
	{ label = "GENERIC_MILLIS_LABEL",  mult = 1 },
	{ label = "GENERIC_SECONDS_LABEL", mult = 1e3 },
	{ label = "GENERIC_MINUTES_LABEL", mult = 6e4 },
}

---@param v integer
local function getTimeThreshold(v)
	if (v < 1e3) then
		return 1
	elseif (v < 6e4) then
		return 2
	else
		return 3
	end
end

local function getStepForDelay(ms)
	if (ms < 1e3) then
		return 100
	elseif (ms < 1e4) then
		return 500
	elseif (ms < 6e4) then
		return 1000
	else
		return 10000
	end
end

local function drawAutofillTimeSelector()
	local delay        = GVars.features.yrv3.autofill_delay
	local mode         = getTimeThreshold(delay)
	local data         = timer_data[mode]
	local v            = delay / data.mult
	local step_ms      = getStepForDelay(delay)
	local step         = step_ms / data.mult
	local step_fast    = (step_ms * 5) / data.mult
	local new_value, c = ImGui.InputFloat(
		"##autofill_delay",
		v,
		step,
		step_fast,
		_F("%.1f %s", v, _T(data.label))
	)

	if (c) then
		GVars.features.yrv3.autofill_delay = math.clamp(new_value * data.mult, 100, 6e5)
	end
end

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

	GUI:HeaderText(_T("YRV3_AUTO_SELL"), { separator = true, spacing = true })
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

	GUI:HeaderText(_T("YRV3_AUTO_FILL"), { separator = true, spacing = true })
	ImGui.Text(_T("YRV3_AUTO_FILL_DELAY"))
	drawAutofillTimeSelector()
end
