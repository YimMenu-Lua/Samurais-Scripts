-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.

---@param labels array<string>
return function(labels)
	for i = 1, #labels do
		local label = labels[i]
        local GXT = Game.GetGXTLabel(label)
        if (string.isvalid(GXT) and GXT ~= "NULL") then
            labels[i] = GXT -- get label from the game.
        else
            labels[i] = _T(label)  -- no GXT; use our own translations
        end
	end
end
