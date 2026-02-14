-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local selectedTabID        = 1
local colMoneyGreen        = Color("#85BB65")
local selfTranslateLabels  = Set.new("YRV3_CASH_SAFES_LABEL", "GENERIC_MISC")
local tabNames <const>     = {
	"GB_BOSSC",
	"CELL_HANGAR",
	"GB_REST_ACCM",
	"CELL_BUNKER",
	"CELL_ACID_LAB",
	"CELL_CLUB",
	"YRV3_CASH_SAFES_LABEL",
	"MP_CARWASH",
	"CELL_SLVG_YRD",
	"GENERIC_MISC",
	"CELL_16"
}

local tabCallbacks <const> = {
	require("includes.frontend.yrv3.office"),
	require("includes.frontend.yrv3.hangar"),
	require("includes.frontend.yrv3.clubhouse"),
	require("includes.frontend.yrv3.bunker"),
	require("includes.frontend.yrv3.acid_lab"),
	require("includes.frontend.yrv3.nightclub"),
	require("includes.frontend.yrv3.cash_safes"),
	require("includes.frontend.yrv3.money_fronts"),
	require("includes.frontend.yrv3.salvage_yard"),
	require("includes.frontend.yrv3.misc"),
	require("includes.frontend.yrv3.settings"),
}

---@return boolean
local function handleYRV3State()
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

local function YRV3UI()
	if (not handleYRV3State()) then
		return
	end

	local headerHeight   = 100.0
	local windowHeight   = math.max(400, GVars.ui.window_size.y - headerHeight - 100.0)
	local sidebarWidth   = math.max(100.0, ImGui.GetWindowWidth() * 0.2)
	local separatorWidth = 3.0

	if (ImGui.BeginChildEx("##yrv3_header", vec2:new(0, headerHeight), ImGuiChildFlags.Borders)) then
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
	end

	ImGui.Spacing()
	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##yrv3_2", 0, windowHeight)

	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##yrv3_3", sidebarWidth, 0)
	for i = 1, #tabNames do
		local name = tabNames[i]
		if (ImGui.Selectable2(
				name,
				i == selectedTabID,
				vec2:new(sidebarWidth, 27),
				"center",
				true
			)) then
			selectedTabID = i
		end
	end
	ImGui.EndChild()

	ImGui.SameLine()
	ImGui.VerticalSeparator(separatorWidth)
	ImGui.SameLine()

	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##yrv3_4")
	local callback = tabCallbacks[selectedTabID]
	if (type(callback) == "function") then
		callback()
	end
	ImGui.EndChild()

	ImGui.EndChild()
end

GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, "YimResupplierV3", YRV3UI)

ThreadManager:Run(function()
	for i = 1, #tabNames do
		local label = tabNames[i]
		if (selfTranslateLabels:Contains(label)) then -- no GXT; use our own translations
			tabNames[i] = _T(label)
		else
			tabNames[i] = Game.GetGXTLabel(label) -- get label from the game.
		end
	end
end)
