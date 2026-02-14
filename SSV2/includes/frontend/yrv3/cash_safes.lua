-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local drawCashSafeLoopToggle = require("includes.frontend.yrv3.cashloop_toggle")

return function()
	local safes = YRV3:GetBusinessSafes()
	if (not safes or #safes == 0) then
		return
	end

	for i, cashSafe in ipairs(safes) do
		local name = cashSafe:GetName() or _F("Cash Safe %d", i)
		ImGui.PushID(i)
		ImGui.BeginChildEx(name,
			vec2:new(0, cashSafe:CanLoop() and 195 or 160),
			ImGuiChildFlags.AlwaysUseWindowPadding,
			ImGuiWindowFlags.NoScrollbar
		)

		local cashValue = cashSafe:GetCashValue()
		local maxCash   = cashSafe:GetCapacity()
		local coords    = cashSafe:GetCoords()

		ImGui.SeparatorText(name)
		if (coords) then
			if (GUI:Button(_F("%s##%s", _T("GENERIC_TELEPORT"), name))) then
				LocalPlayer:Teleport(coords)
			end

			ImGui.SameLine()
			if (GUI:Button(_T("GENERIC_SET_WAYPOINT"))) then
				Game.SetWaypointCoords(coords)
			end
		end
		ImGui.Separator()
		ImGui.Spacing()

		ImGui.BulletText(_F("%s: ", _T("YRV3_CASH_SAFE")))
		ImGui.SameLine()
		ImGui.ProgressBar(cashValue / maxCash,
			-1,
			25,
			string.formatmoney(cashValue)
		)

		drawCashSafeLoopToggle(cashSafe)

		ImGui.EndChild()
		ImGui.PopID()
	end
end
