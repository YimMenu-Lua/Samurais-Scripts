-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessMgr      = require("includes.features.online.business_mgr.BusinessManager")
local selectedBossType = -1

return function()
	local currentBossType = LocalPlayer:GetBossType()
	local IsAssociate     = LocalPlayer:IsAssociate()
	if (currentBossType > -1 and not IsAssociate) then
		if (GUI:Button(_T("PIM_MAGM0B"))) then
			LocalPlayer:Retire()
		end
		return
	end

	ImGui.BeginDisabled(IsAssociate)
	if (GUI:Button(_T("PIM_REGBOSS"))) then
		ImGui.OpenPopup("##bossRegister")
	end
	ImGui.EndDisabled()

	if (IsAssociate) then
		GUI:Tooltip(_T("YRV3_DASHBOARD_BOSS_ASSOCIATE_ERR"))
	end

	if (ImGui.BeginPopupModal("##bossRegister", true, ImGuiWindowFlags.NoResize | ImGuiWindowFlags.AlwaysAutoResize)) then
		ImGui.Spacing()

		local availableBossTypes = BusinessMgr:GetAvailableBossTypes()
		local availType          = availableBossTypes[selectedBossType + 1]
		if (ImGui.BeginCombo("##registerAsBoss", _T(availType and availType.name or "GENERIC_NONE"))) then
			for _, bossType in ipairs(availableBossTypes) do
				local id = bossType.id
				if (ImGui.Selectable(_T(bossType.name), (id == selectedBossType))) then
					selectedBossType = id
				end
			end
			ImGui.EndCombo()
		end

		ImGui.Spacing()
		ImGui.BeginDisabled(selectedBossType == -1)
		if (GUI:Button(_T("GENERIC_CONFIRM"))) then
			LocalPlayer:RegisterAsBoss(selectedBossType)
			ImGui.CloseCurrentPopup()
		end
		ImGui.EndDisabled()

		ImGui.SameLine()
		if (GUI:Button(_T("GENERIC_CANCEL"))) then
			selectedBossType = -1
			ImGui.CloseCurrentPopup()
		end
		ImGui.EndPopup()
	end
end
