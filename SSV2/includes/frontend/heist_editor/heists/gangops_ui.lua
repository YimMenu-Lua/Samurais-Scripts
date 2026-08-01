-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local drawPlayerCuts   = require("includes.frontend.heist_editor.helpers.draw_player_cuts")
local actNames <const> = {
	"GENERIC_NONE",
	"ACH_ACHGO2_NAME",
	"ACH_ACHGO3_NAME",
	"ACH_ACHGO4_NAME",
}

---@param instance GangOps
return function(instance)
	local current_act = instance.m_current_act
	GUI:HeaderText(_T("CP_HEIST_SETUP"), { separator = true, spacing = true })
	if (ImGui.BeginCombo(_T("YH_DDAY_SELECTED_ACT"), _T(actNames[current_act + 2]))) then
		for i, v in ipairs(actNames) do
			local is_selected = i == current_act + 2
			if (ImGui.Selectable(_T(v), is_selected)) then
				current_act            = i - 2
				instance.m_current_act = current_act
			end

			if (is_selected) then
				ImGui.SetItemDefaultFocus()
			end
		end
		ImGui.EndCombo()
	end
	ImGui.Spacing()

	ImGui.BeginDisabled(current_act == -1)
	drawPlayerCuts(instance, false, "gb_gang_ops_planning")
	ImGui.EndDisabled() -- current_act == -1

	GUI:HeaderText(_T("GENERIC_OPTIONS_LABEL"), { separator = true, spacing = true })

	GVars.features.yim_heists.dday_cd, _ = GUI:CustomToggle(_T("YH_GENERIC_CD_LABEL"),
		GVars.features.yim_heists.dday_cd, {
			tooltip = _T("YH_COOLDOWN_BYPASS_TOOLTIP"),
			color   = Color.RED,
		})
end
