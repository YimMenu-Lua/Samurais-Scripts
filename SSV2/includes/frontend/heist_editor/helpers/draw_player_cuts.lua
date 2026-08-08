-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local sum = math.sum

---@param instance Heist
---@param sane_v boolean sane values *(prevents setting all cuts to 100)*
---@param launcher_script_name? string
return function(instance, sane_v, launcher_script_name)
	local getCuts = instance.GetPlayerCuts
	local setCuts = instance.SetPlayerCuts
	if not (getCuts and setCuts) then return end

	local cuts = getCuts(instance)
	if (not cuts) then return end

	ImGui.SeparatorText(_T("CP_HEIST_PLAYER_CUTS"))

	local max_all_v = sane_v and 25 or 100
	if (GUI:Button(_T("CP_HEIST_MAX_PLAYER_CUTS"))) then
		for i = 1, 4 do
			cuts[i] = max_all_v
		end

		if (launcher_script_name and script.is_active(launcher_script_name)) then
			ThreadManager:Run(function()
				setCuts(instance)
			end)
		end
	end

	local min, max = 5, 100
	for i = 1, 4 do
		if (sane_v) then
			min = 15
			max = 100 - sum(cuts) + cuts[i]
		end
		cuts[i] = ImGui.SliderIntWithStep(_T("GENERIC_PLAYER_FMT", i), cuts[i], min, max, 5)
	end
end
