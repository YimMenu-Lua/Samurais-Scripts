-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@param cashSafe CashSafe
local function onCashLoopEnable(cashSafe)
	if (GVars.features.yrv3.safe_loop_warn_ack) then
		return
	end

	if (ImGui.DialogBox(_T("GENERIC_WARN_LABEL"), _T("YRV3_CASH_LOOP_WARN_ACK"), ImGuiDialogBoxStyle.WARN)) then
		GVars.features.yrv3.safe_loop_warn_ack = true
		cashSafe.cash_loop_enabled = true
	end
end

---@param cashSafe CashSafe
return function(cashSafe)
	if (not cashSafe:CanLoop()) then
		return
	end

	local isOpen = ImGui.IsPopupOpen(_T("GENERIC_WARN_LABEL"))
	ImGui.BeginDisabled(isOpen or (not cashSafe.cash_loop_enabled and cashSafe:IsFull()))
	cashSafe.cash_loop_enabled, _ = GUI:CustomToggle(
		_F("%s##%s", _T("YRV3_CASH_LOOP"), cashSafe:GetName()),
		cashSafe.cash_loop_enabled,
		{
			onClick = function(v)
				if (KeyManager:IsKeyPressed(eVirtualKeyCodes.SHIFT) and GVars.features.yrv3.safe_loop_warn_ack) then
					GVars.features.yrv3.safe_loop_warn_ack = false
					return
				end
				if (v and not isOpen and not GVars.features.yrv3.safe_loop_warn_ack) then
					ImGui.OpenPopup(_T("GENERIC_WARN_LABEL"))
				end
			end
		}
	)
	ImGui.EndDisabled()

	if (GVars.features.yrv3.safe_loop_warn_ack) then
		GUI:HelpMarker(_T("YRV3_CASH_LOOP_ACK_DISABLE_TT"))
	end

	onCashLoopEnable(cashSafe)
end
