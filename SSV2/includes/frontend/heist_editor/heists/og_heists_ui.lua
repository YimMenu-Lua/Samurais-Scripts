-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local drawPlayerCuts = require("includes.frontend.heist_editor.helpers.draw_player_cuts")

---@param instance ApartmentHeist
return function(instance)
	GUI:HeaderText(_T("CP_HEIST_SETUP"), { separator = true, spacing = true })

	local current    = instance.m_current_strand
	local nil_strand = current == nil
	local preview    = current and current.gxt or "GENERIC_NONE"

	ImGui.InputText(_T("YH_APT_SELECTED_JOB"), _T(preview), 256, ImGuiInputTextFlags.ReadOnly)

	--[[ if (ImGui.BeginCombo(_T("YH_APT_SELECTED_JOB"), _T(preview))) then
		if (ImGui.Selectable(_T("GENERIC_NONE", nil_strand))) then
			instance.m_current_strand = nil
		end

		for _, strand in ipairs(instance:GetStrandList()) do
			local is_selected = strand == instance.m_current_strand
			if (ImGui.Selectable(_T(strand.gxt), is_selected)) then
				instance.m_current_strand = strand
			end

			if (is_selected) then
				ImGui.SetItemDefaultFocus()
			end
		end
		ImGui.EndCombo()
	end ]]
	ImGui.Spacing()

	ImGui.BeginDisabled(nil_strand)
	if (GUI:Button(_T("YH_GENERIC_SKIP_PREPS"))) then
		instance:SkipPreps()
	end

	ImGui.Spacing()

	drawPlayerCuts(instance, true, "fmmc_launcher")
	ImGui.EndDisabled() -- nil_strand
end
