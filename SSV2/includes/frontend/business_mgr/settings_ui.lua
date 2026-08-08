-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessMgr              = require("includes.features.online.business_mgr.BusinessManager")
local COL_RED <const>          = Color.RED
local COL_WARN <const>         = Color("safety_yellow")
local timerData <const>        = {
	{ label = "GENERIC_MILLIS_LABEL",  mult = 1 },
	{ label = "GENERIC_SECONDS_LABEL", mult = 1e3 },
	{ label = "GENERIC_MINUTES_LABEL", mult = 6e4 },
}
local supportedScripts <const> = {
	"YRV3_AUTOSELL_BUNKER_LABEL",
	"YRV3_AUTOSELL_HANGAR_LABEL",
	"YRV3_AUTOSELL_CEO_LABEL",
	"YRV3_AUTOSELL_BIKER_LABEL",
	"YRV3_AUTOSELL_NC_CARGO_LABEL",
	"YRV3_AUTOSELL_LSD_LAB_LABEL",
}
local unsafeFeatsPopupLabel ---@type string?

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
	local delay     = GVars.features.yrv3.autofill_delay
	local mode      = getTimeThreshold(delay)
	local data      = timerData[mode]
	local v         = delay / data.mult
	local stepMS    = getStepForDelay(delay)
	local step      = stepMS / data.mult
	local stepFast  = (stepMS * 5) / data.mult
	local newVal, c = ImGui.InputFloat(
		"##autofill_delay",
		v,
		step,
		stepFast,
		_F("%.1f %s", v, _T(data.label))
	)

	if (c) then
		GVars.features.yrv3.autofill_delay = math.clamp(newVal * data.mult, 100, 6e5)
	end
end

return function()
	local __state        = BusinessMgr:GetState()
	local autosellState  = BusinessMgr:GetAutoSellState()
	local isReloading    = __state == Enums.eBusinessMgrState.RELOADING
	local waitLabel      = _T("GENERIC_WAIT_LABEL")
	local label          = isReloading and ImGui.TextSpinner(waitLabel) or _T("GENERIC_RELOAD")
	local maxButtonWidth = ImGui.CalcTextSize(_F("%s ________", waitLabel)) + (ImGui.GetStyle().FramePadding.x * 2)

	ImGui.BeginDisabled(__state ~= Enums.eBusinessMgrState.RUNNING)
	if (GUI:Button(label, { size = vec2:new(maxButtonWidth, 36) })) then
		BusinessMgr:Reload()
	end
	ImGui.EndDisabled()

	if (isReloading) then return end

	GUI:HeaderText(_T("YRV3_AUTO_SELL"), { separator = true, spacing = true })
	ImGui.TextWrapped(_T("YRV3_AUTO_SELL_SUPPORT_NOTICE"))
	for _, scrName in ipairs(supportedScripts) do
		ImGui.BulletText(_T(scrName))
	end

	ImGui.Spacing()
	GVars.features.yrv3.autosell = GUI:CustomToggle(_T("YRV3_AUTO_SELL"), GVars.features.yrv3.autosell)
	GUI:Tooltip(_T("YRV3_AUTOSELL_TT"))

	if (script.is_active("fm_content_smuggler_sell")) then
		GUI:Text(_T("YRV3_HANGAR_LAND_ERR"), { color = COL_RED })
	else
		ImGui.BeginDisabled(autosellState == Enums.eAutoSellState.TRIGGERED or not BusinessMgr:IsAnySaleInProgress())
		local taskSellLabel = "YRV3_AUTO_SELL_MANUAL"
		if (autosellState == Enums.eAutoSellState.CANCELED or autosellState == Enums.eAutoSellState.FAILED) then
			taskSellLabel = "GENERIC_RETRY"
		end
		if (GUI:Button(_T(taskSellLabel))) then
			BusinessMgr:FinishSale(true)
		end
		ImGui.EndDisabled()
	end

	ImGui.Text(_T("YRV3_AUTOSELL_CURRENT", BusinessMgr:GetRunningSellScriptDisplayName()))
	GUI:HeaderText(_T("YRV3_AUTO_FILL"), { separator = true, spacing = true })
	ImGui.Text(_T("YRV3_AUTO_FILL_DELAY"))
	drawAutofillTimeSelector()
end
