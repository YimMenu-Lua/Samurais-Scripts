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

	if (not sane_v) then
		for i = 1, 4 do
			cuts[i] = ImGui.SliderIntWithStep(_T("GENERIC_PLAYER_FMT", i), cuts[i], 5, 100, 5)
		end
	else
		cuts[1] = ImGui.SliderIntWithStep(_T("GENERIC_PLAYER_FMT", 1), cuts[1], 15 --[[MEMBER_MIN_HEIST_FINALE_TAKE_PERCENTAGE]], (100 - sum(cuts[2], cuts[3], cuts[4])), 5)
		cuts[2] = ImGui.SliderIntWithStep(_T("GENERIC_PLAYER_FMT", 2), cuts[2], 15 --[[MEMBER_MIN_HEIST_FINALE_TAKE_PERCENTAGE]], (100 - sum(cuts[1], cuts[3], cuts[4])), 5)
		cuts[3] = ImGui.SliderIntWithStep(_T("GENERIC_PLAYER_FMT", 3), cuts[3], 15 --[[MEMBER_MIN_HEIST_FINALE_TAKE_PERCENTAGE]], (100 - sum(cuts[1], cuts[2], cuts[4])), 5)
		cuts[4] = ImGui.SliderIntWithStep(_T("GENERIC_PLAYER_FMT", 4), cuts[4], 15 --[[MEMBER_MIN_HEIST_FINALE_TAKE_PERCENTAGE]], (100 - sum(cuts[1], cuts[2], cuts[3])), 5)
	end
end
