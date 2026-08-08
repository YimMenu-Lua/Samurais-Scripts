-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local playerFundsTxnAmt        = 0
local playerFundsTxnWidgetType = 0
local playerFundsTxnInProgress = false

---@param operationType 0|1 -- 0: deposit | 1: withdraw
---@param isPopup? boolean
return function(operationType, isPopup)
	ImGui.Spacing()

	local isDeposit = operationType == 0
	local maxAmt    = isDeposit and LocalPlayer:GetWalletBalance() or LocalPlayer:GetBankBalance()

	ImGui.SetNextItemWidth(120)
	playerFundsTxnWidgetType = ImGui.Combo("Widget Type", playerFundsTxnWidgetType, "Slider\0Input\0")

	ImGui.SetNextItemWidth(400)
	if (playerFundsTxnWidgetType == 0) then
		playerFundsTxnAmt = ImGui.SliderInt("##dep/withdraw" .. operationType, playerFundsTxnAmt, 0, maxAmt, string.formatmoney(playerFundsTxnAmt))
	else
		playerFundsTxnAmt = ImGui.InputInt("##dep/withdraw" .. operationType, playerFundsTxnAmt, 1e3, 1e5)
		playerFundsTxnAmt = math.clamp(playerFundsTxnAmt, 0, maxAmt)
	end

	ImGui.SameLine()
	if (GUI:Button("Max")) then
		playerFundsTxnAmt = maxAmt
	end

	ImGui.BeginDisabled(playerFundsTxnAmt <= 0 or playerFundsTxnInProgress)
	if (GUI:Button(_T("GENERIC_CONFIRM"))) then
		local controller = LocalPlayer:GetMoneyController()
		local fn = isDeposit and controller.Deposit or controller.Withdraw
		ThreadManager:Run(function()
			playerFundsTxnInProgress = true
			fn(controller, playerFundsTxnAmt)
			playerFundsTxnAmt        = 0
			playerFundsTxnInProgress = false
		end)

		if (isPopup) then
			ImGui.CloseCurrentPopup()
		end
	end
	ImGui.EndDisabled()

	ImGui.SameLine()
	if (GUI:Button(_T("GENERIC_CANCEL"))) then
		playerFundsTxnAmt = 0
		if (isPopup) then
			ImGui.CloseCurrentPopup()
		end
	end
end
