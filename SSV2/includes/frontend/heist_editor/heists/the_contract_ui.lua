-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local missionNames = require("includes.data.heist_editor_data").DrDreData.missions

---@param instance TheContract
return function(instance)
	ImGui.Spacing()
	local locked = instance.m_none_unlocked
	if (locked) then
		if (GUI:Button(_T("GENERIC_UNLOCK_ALL"))) then
			instance:UnlockAllMissions()
		end
	end

	instance.m_current_bs = ImGui.Combo("##dreContract", instance.m_current_bs, missionNames, 12)

	ImGui.Spacing()
	local alreadyUnlocked = (instance.m_current_bs == 11)
	ImGui.BeginDisabled(alreadyUnlocked)
	if (GUI:Button(_T("YH_GENERIC_SKIP_PREPS"))) then
		instance:SkipPreps()
	end
	ImGui.EndDisabled() -- alreadyUnlocked
	if (alreadyUnlocked) then
		GUI:Tooltip(_T("YH_GENERIC_SKIP_PREPS_TT"))
	end

	GUI:HeaderText(_T("GENERIC_OPTIONS_LABEL"), { separator = true, spacing = true })

	local cfg = GVars.features.yim_heists
	cfg.dre_cd = GUI:CustomToggle(_T("YH_GENERIC_CD_LABEL"), cfg.dre_cd, {
		tooltip = _T("YH_COOLDOWN_BYPASS_TOOLTIP"),
		color   = Color.RED,
	})
end
