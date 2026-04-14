-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local DrawNewCommandWindow = require("includes.frontend.yim_actions.new_command_ui")
local DrawMainActions      = require("includes.frontend.yim_actions.actions_ui")
local DrawCompanions       = require("includes.frontend.yim_actions.companions_ui")
local DrawClipsets         = require("includes.frontend.yim_actions.movement_clipsets_ui")

---@type Action?
local selectedAction

GUI:RegisterNewTab(Enums.eTabID.TAB_EXTRA, "YimActions", function()
	ImGui.BeginDisabled(YimActions.DrawNewCommandWindow)
	if (ImGui.BeginTabBar("##yimactionsv3")) then
		if (ImGui.BeginTabItem("Actions")) then
			selectedAction = DrawMainActions()
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem("Movement Styles")) then
			DrawClipsets()
			ImGui.EndTabItem()
		end

		if (ImGui.BeginTabItem("Companions")) then
			DrawCompanions()
			ImGui.EndTabItem()
		end

		if (Backend.debug_mode and ImGui.BeginTabItem("Debug")) then
			YimActions.Debugger:Draw()
			ImGui.EndTabItem()
		end
		ImGui.EndTabBar()
	end
	ImGui.EndDisabled()

	DrawNewCommandWindow(selectedAction)
end)
