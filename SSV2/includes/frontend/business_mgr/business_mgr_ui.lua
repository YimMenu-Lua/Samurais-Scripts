-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessMgr        = require("includes.features.online.business_mgr.BusinessManager")
local drawTxnUI          = require("includes.frontend.business_mgr.helpers.withdraw_deposit_popup")
local drawBossRegisterUI = require("includes.frontend.business_mgr.helpers.boss_register_combo")


local TABS <const> = {
	{ label = "YRV3_DASHBOARD",        callback = require("includes.frontend.business_mgr.dashboard_ui") },
	{ label = "GB_BOSSC",              callback = require("includes.frontend.business_mgr.office_ui") },
	{ label = "GB_REST_ACCM",          callback = require("includes.frontend.business_mgr.clubhouse_ui") },
	{ label = "CELL_CLUB",             callback = require("includes.frontend.business_mgr.nightclub_ui") },
	{ label = "CELL_HANGAR",           callback = require("includes.frontend.business_mgr.hangar_ui") },
	{ label = "CELL_BUNKER",           callback = require("includes.frontend.business_mgr.bunker_ui") },
	{ label = "CELL_ACID_LAB",         callback = require("includes.frontend.business_mgr.acid_lab_ui") },
	{ label = "CELL_SLVG_YRD",         callback = require("includes.frontend.business_mgr.salvage_yard_ui") },
	{ label = "MP_CARWASH",            callback = require("includes.frontend.business_mgr.money_fronts_ui") },
	{ label = "YRV3_CASH_SAFES_LABEL", callback = require("includes.frontend.business_mgr.cash_safes_ui") },
	{ label = "GENERIC_MISC",          callback = require("includes.frontend.business_mgr.misc_ui") },
	{ label = "CELL_16",               callback = require("includes.frontend.business_mgr.settings_ui") },
}; local selectedTab = TABS[1]


---@return boolean
local function handleState()
	local __state = BusinessMgr:GetState()
	local message = BusinessMgr:GetLastError()

	if (__state == Enums.eBusinessMgrState.RUNNING) then
		return true
	end

	if (__state == Enums.eBusinessMgrState.LOADING) then
		-- message = ImGui.TextSpinner(message) -- unnecessary, this state should not stay for more than a second
		return true
	end

	if (__state == Enums.eBusinessMgrState.RELOADING) then
		return true
	end

	if (__state == Enums.eBusinessMgrState.ERROR) then
		ImGui.TextColored(0.9, 0.1, 0.1, 1.0, message)
	else
		ImGui.Text(message)
	end

	return false
end

GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, "Business Manager", function()
	if (not handleState()) then return end

	local headerHeight   = 100.0
	local lowerPadding   = 60.0
	local windowHeight   = math.max(400, GVars.ui.window_size.y - headerHeight - lowerPadding)
	local sidebarWidth   = math.max(100.0, ImGui.GetWindowWidth() * 0.2)
	local separatorWidth = 3.0

	ImGui.SetNextWindowBgAlpha(0.85)
	ImGui.BeginChildEx("##yrv3_header", vec2:new(0, headerHeight), ImGuiChildFlags.Borders)
	ImGui.SetWindowFontScale(1.12)
	local title     = _T("YRV3_HEADER_TITLE")
	local textWidth = ImGui.CalcTextSize(title) + (ImGui.GetStyle().FramePadding.x * 2)
	ImGui.SetCursorPosX((ImGui.GetContentRegionAvail() - textWidth) * 0.5)
	ImGui.Text(title)
	ImGui.SetWindowFontScale(1.0)

	local manageFundsLabel = _T("YRV3_DASHBOARD_MANAGE_FUNDS")
	ImGui.BeginDisabled(selectedTab == TABS[1])
	if (GUI:Button(manageFundsLabel)) then
		ImGui.OpenPopup(manageFundsLabel)
	end

	ImGui.SameLine()
	drawBossRegisterUI()
	ImGui.EndDisabled()

	if (ImGui.BeginPopupModal(manageFundsLabel, true, ImGuiWindowFlags.NoResize | ImGuiWindowFlags.AlwaysAutoResize)) then
		if (ImGui.BeginTabBar("##manageFunds")) then
			if (ImGui.BeginTabItem(_T("YRV3_DASHBOARD_FUNDS_DEPOSIT"))) then
				drawTxnUI(0)
				ImGui.EndTabItem()
			end
			if (ImGui.BeginTabItem(_T("YRV3_DASHBOARD_FUNDS_WITHDRAW"))) then
				drawTxnUI(1)
				ImGui.EndTabItem()
			end
			ImGui.EndTabBar()
		end

		ImGui.EndPopup()
	end

	ImGui.SameLine()
	if (GUI:Button(_T("YRV3_MCT_TITLE"))) then
		if (BusinessMgr:IsAnySaleInProgress()) then
			Notifier:ShowMessage("Business Manager", _T("YRV3_MCT_UNAVAIL"))
		else
			BusinessMgr:MCT()
			GUI:Close(true)
		end
	end

	ImGui.EndChild() --[[header main]]

	ImGui.Spacing()
	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##yrv3_2", 0, windowHeight)

	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##yrv3_3", sidebarWidth, 0)
	for _, v in ipairs(TABS) do
		local label = v.label
		if (ImGui.Selectable2(
				_T(label),
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
