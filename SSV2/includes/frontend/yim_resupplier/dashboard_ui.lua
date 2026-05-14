-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local YRV3                    = require("includes.features.online.yim_resupplier.YimResupplierV3")
local drawKeyValue            = require("includes.frontend.helpers.draw_kv")
local drawTxnPopup            = require("includes.frontend.yim_resupplier.helpers.withdraw_deposit_popup")
local drawBossRegisterUI      = require("includes.frontend.yim_resupplier.helpers.boss_register_combo")
local colMoneyGreen <const>   = Color("#85BB65")
local moneyCardChildSize      = vec2:new(200, 90)
local moneyCardBtnSize        = vec2:new(0, 35)
local bossLabel               = ""
local moneyCardColors <const> = {
	[0] = Color(0.033, 0.45, 0.15, 0.95),
	[1] = Color(0.78, 0.78, 0.78, 0.90)
}

---@param cardType 0|1 -- 0: wallet | 1: bank
---@param money integer
---@param formattedMoney string
local function drawMoneyCard(cardType, money, formattedMoney)
	local outerWidth = ImGui.GetContentRegionAvail()
	local label      = (cardType == 0) and "YRV3_DASHBOARD_FUNDS_WALLET" or "YRV3_DASHBOARD_FUNDS_BANK"
	local bgCol      = moneyCardColors[cardType]
	ImGui.PushStyleColor(ImGuiCol.ChildBg, bgCol:AsFloat())
	ImGui.PushStyleColor(ImGuiCol.Text, ImGui.GetAutoTextColor(bgCol):AsFloat())
	ImGui.BeginChildEx(label, moneyCardChildSize, ImGuiChildFlags.AlwaysUseWindowPadding)
	if (money > 9999999) then
		local availWidth, _ = ImGui.GetContentRegionAvail()
		ImGui.SetWindowFontScale(1.15)
		if (ImGui.CalcTextSize(formattedMoney) > availWidth and outerWidth > moneyCardChildSize.x) then
			moneyCardChildSize.x = moneyCardChildSize.x + 10
		end
		ImGui.SetWindowFontScale(1.0)
	end

	ImGui.SetWindowFontScale(0.75)
	ImGui.Text(_T(label))

	ImGui.SetWindowFontScale(1.15)
	ImGui.Text(formattedMoney)
	ImGui.SetWindowFontScale(1.0)
	ImGui.Spacing()
	ImGui.EndChild()
	ImGui.PopStyleColor(2)
end

local function drawPortfolio()
	local walletBal = LocalPlayer:GetWalletBalance()
	local walletFmt = LocalPlayer:GetWalletBalanceFmt()
	local bankBal   = LocalPlayer:GetBankBalance()
	local bankFmt   = LocalPlayer:GetBankBalanceFmt()

	ImGui.PushStyleColor(ImGuiCol.ChildBg, 0.08, 0.08, 0.08, 0.9)
	ImGui.BeginChildEx("##portfolio", vec2:new(0, 315), ImGuiChildFlags.Borders)
	GUI:HeaderText(_T("YRV3_DASHBOARD_FINANCES"), { separator = true })

	ImGui.SetWindowFontScale(0.8)
	drawKeyValue(_T("YRV3_DASHBOARD_NET_WORTH"), string.formatmoney(stats.get_int("MPPLY_TOTAL_EARNED")), colMoneyGreen)
	drawKeyValue(_T("YRV3_DASHBOARD_FUNDS_TOTAL"), LocalPlayer:GetTotalBalanceFmt(), colMoneyGreen)
	drawKeyValue(_T("YRV3_INCOME_APPROX_ALL"), YRV3:GetEstimatedIncomeFmt(), colMoneyGreen)
	ImGui.SetWindowFontScale(1.0)
	ImGui.Separator()
	ImGui.Spacing()

	moneyCardChildSize.x = math.max(200, ImGui.GetContentRegionAvail() * 0.484)
	drawMoneyCard(0, walletBal, walletFmt)
	ImGui.SameLineIfAvail(moneyCardChildSize.x)
	drawMoneyCard(1, bankBal, bankFmt)

	local withdrawLabel = _T("YRV3_DASHBOARD_FUNDS_WITHDRAW")
	local depositLabel  = _T("YRV3_DASHBOARD_FUNDS_DEPOSIT")
	moneyCardBtnSize.x  = moneyCardChildSize.x

	ImGui.Spacing()
	ImGui.BeginDisabled(walletBal <= 0)
	if (GUI:Button(depositLabel, { size = moneyCardBtnSize })) then
		ImGui.OpenPopup(depositLabel)
	end
	ImGui.EndDisabled()

	ImGui.SameLineIfAvail(moneyCardBtnSize.x)
	ImGui.BeginDisabled(bankBal <= 0)
	if (GUI:Button(withdrawLabel, { size = moneyCardBtnSize })) then
		ImGui.OpenPopup(withdrawLabel)
	end
	ImGui.EndDisabled()

	if (ImGui.BeginPopupModal(depositLabel, true, ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoResize)) then
		drawTxnPopup(0, true)
		ImGui.EndPopup()
	end

	if (ImGui.BeginPopupModal(withdrawLabel, true, ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoResize)) then
		drawTxnPopup(1, true)
		ImGui.EndPopup()
	end

	ImGui.EndChild()
	ImGui.PopStyleColor()
end

return function()
	ImGui.SetWindowFontScale(1.34)
	local title      = _F("%s, %s", _T("GENERIC_HELLO"), LocalPlayer:GetName())
	local titleWidth = ImGui.CalcTextSize(title)
	ImGui.SetCursorPosX((ImGui.GetContentRegionAvail() - titleWidth) * 0.5)
	ImGui.Text(title)
	ImGui.Separator()

	ImGui.SetWindowFontScale(0.88)
	drawKeyValue(_T("YRV3_MP_CHAR_INDEX"), tostring(stats.get_character_index()))
	drawKeyValue(_T("YRV3_MP_CHAR_NAME"), stats.get_string("MPX_CHAR_NAME"))

	if (LocalPlayer:IsBoss()) then
		local bossType = LocalPlayer:GetBossType()
		local isMC     = bossType == 1
		local fmt      = isMC and "YRV3_DASHBOARD_BOSS_PRES_FMT" or "YRV3_DASHBOARD_BOSS_CEO_FMT"
		local property = isMC and YRV3:GetClubhouse() or YRV3:GetOffice()
		bossLabel      = _T(fmt, property and property:GetCustomName() or "GENERIC_UNKNOWN")
	else
		bossLabel = _T("YRV3_DASHBOARD_BOSS_RETIRED")
	end

	drawKeyValue(_T("YRV3_DASHBOARD_BOSS_TYPE"), bossLabel)
	ImGui.SetWindowFontScale(1.0)

	ImGui.Spacing()
	drawBossRegisterUI()

	ImGui.Separator()
	ImGui.Spacing()
	drawPortfolio()
end
