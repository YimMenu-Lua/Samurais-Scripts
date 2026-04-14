-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local colMoneyGreen <const> = Color("#85BB65")
local TABS <const>          = {
	{ label = "GB_BOSSC",              isGXT = true,  callback = require("includes.frontend.yim_resupplier.office") },
	{ label = "CELL_HANGAR",           isGXT = true,  callback = require("includes.frontend.yim_resupplier.hangar") },
	{ label = "GB_REST_ACCM",          isGXT = true,  callback = require("includes.frontend.yim_resupplier.clubhouse") },
	{ label = "CELL_BUNKER",           isGXT = true,  callback = require("includes.frontend.yim_resupplier.bunker") },
	{ label = "CELL_ACID_LAB",         isGXT = true,  callback = require("includes.frontend.yim_resupplier.acid_lab") },
	{ label = "CELL_CLUB",             isGXT = true,  callback = require("includes.frontend.yim_resupplier.nightclub") },
	{ label = "YRV3_CASH_SAFES_LABEL", isGXT = false, callback = require("includes.frontend.yim_resupplier.cash_safes") },
	{ label = "MP_CARWASH",            isGXT = true,  callback = require("includes.frontend.yim_resupplier.money_fronts") },
	{ label = "CELL_SLVG_YRD",         isGXT = true,  callback = require("includes.frontend.yim_resupplier.salvage_yard") },
	{ label = "GENERIC_MISC",          isGXT = false, callback = require("includes.frontend.yim_resupplier.misc") },
	{ label = "CELL_16",               isGXT = true,  callback = require("includes.frontend.yim_resupplier.settings") },
}; local selectedTab        = TABS[1]

ThreadManager:Run(function()
	for _, v in ipairs(TABS) do
		if (v.isGXT) then
			v.label = Game.GetGXTLabel(v.label)
		end
	end
end)

---@return boolean
local function handleState()
	local __state = YRV3:GetState()
	local message = YRV3:GetLastError()

	if (__state == Enums.eYRState.RUNNING) then
		return true
	end

	if (__state == Enums.eYRState.LOADING) then
		-- message = ImGui.TextSpinner(message) -- unnecessary, this state should not stay for more than a second
		return true
	end

	if (__state == Enums.eYRState.RELOADING) then
		return true
	end

	if (__state == Enums.eYRState.ERROR) then
		ImGui.TextColored(0.9, 0.1, 0.1, 1.0, message)
	else
		ImGui.Text(message)
	end

	return false
end

GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, "YimResupplierV3", function()
	if (not handleState()) then return end

	local headerHeight   = 100.0
	local footerPadding  = 100.0
	local windowHeight   = math.max(400, GVars.ui.window_size.y - headerHeight - footerPadding)
	local sidebarWidth   = math.max(100.0, ImGui.GetWindowWidth() * 0.2)
	local separatorWidth = 3.0

	ImGui.BeginChildEx("##yrv3_header", vec2:new(0, headerHeight), ImGuiChildFlags.Borders)
	local title     = _T("YRV3_MCT_TITLE")
	local textWidth = ImGui.CalcTextSize(title) + (ImGui.GetStyle().FramePadding.x * 2)
	ImGui.SetCursorPosX((ImGui.GetContentRegionAvail() - textWidth) * 0.5)

	if (GUI:Button(title)) then
		if (YRV3:IsAnySaleInProgress()) then
			Notifier:ShowMessage("YRV3", _T("YRV3_MCT_UNAVAIL"))
		else
			YRV3:MCT()
			GUI:Close(true)
		end
	end

	ImGui.Spacing()
	ImGui.SetWindowFontScale(0.9)
	ImGui.BulletText(_T("YRV3_INCOME_APPROX_ALL"))
	ImGui.SameLine()
	GUI:Text(string.formatmoney(YRV3:GetEstimatedIncome() or 0), { color = colMoneyGreen })
	ImGui.SetWindowFontScale(1)
	ImGui.EndChild()

	ImGui.Spacing()
	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##yrv3_2", 0, windowHeight)

	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##yrv3_3", sidebarWidth, 0)
	for i, v in ipairs(TABS) do
		local label = v.label
		if (ImGui.Selectable2(
				v.isGXT and label or _T(label),
				(v == selectedTab),
				vec2:new(sidebarWidth, 27),
				"center",
				true
			)) then
			selectedTab = v
		end
	end
	ImGui.EndChild()
	ImGui.VerticalSeparator(separatorWidth)
	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##yrv3_4")
	selectedTab.callback()
	ImGui.EndChild()

	ImGui.EndChild()
end)
