-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.

---@param teleportsArray array<{ label: string, coords: vec3 }>
return function(teleportsArray, selectedEntry)
	selectedEntry = selectedEntry or { label = "GENERIC_NONE", coords = vec3:zero() }

	ImGui.Spacing()
	ImGui.SeparatorText(_T("GENERIC_TELEPORT"))
	if (ImGui.BeginCombo("##teleportList", _T(selectedEntry.label))) then
		for _, v in ipairs(teleportsArray) do
			local is_selected = v == selectedEntry
			ImGui.Selectable(_T(v.label), is_selected)

			if (ImGui.IsItemClicked()) then
				selectedEntry = v
				LocalPlayer:Teleport(v.coords)
			end

			if (is_selected) then
				ImGui.SetItemDefaultFocus()
			end
		end
		ImGui.EndCombo()
	end
end
