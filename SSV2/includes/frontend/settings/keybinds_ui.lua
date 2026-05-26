-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local DrawKeybind = require("includes.frontend.helpers.draw_keybind")

return function()
	local height = GVars.ui.window_size.y - 200
	if (ImGui.BeginTabBar("##ss_keybinds")) then
		if (ImGui.BeginTabItem(_T("SETTINGS_KEYBINDS_KEYBOARD"))) then
			ImGui.SetNextWindowBgAlpha(0.0)
			ImGui.BeginChild("##ckeyboardrKeybindsScroll", 0, height)
			for key in pairs(GVars.keyboard_keybinds) do
				DrawKeybind(key, false)
			end
			ImGui.EndChild()
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem(_T("SETTINGS_KEYBINDS_CONTROLLER"))) then
			ImGui.SetNextWindowBgAlpha(0.0)
			ImGui.BeginChild("##controllerKeybindsScroll", 0, height)
			for key in pairs(GVars.gamepad_keybinds) do
				DrawKeybind(key, true)
			end
			ImGui.EndChild()
			ImGui.EndTabItem()
		end
		ImGui.EndTabBar()
	end
end
