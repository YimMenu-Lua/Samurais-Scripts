-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@param labels array<string>
---@param padding float
---@return float
return function(labels, padding)
	local max = 0
	padding = padding or 0

	for i = 1, #labels do
		local w = ImGui.CalcTextSize(labels[i])
		if (w > max) then
			max = w
		end
	end

	return max + padding + ImGui.GetStyle().ItemSpacing.x
end
