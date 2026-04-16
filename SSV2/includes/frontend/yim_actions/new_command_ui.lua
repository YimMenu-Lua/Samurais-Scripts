-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local YimActions = require("includes.features.extra.yim_actions.YimActionsV3")
local strBuffer  = ""
local windowSize = vec2:new(400, 200)

---@type vec2?
local windowPos

---@param selected_action Action?
return function(selected_action)
	if (not selected_action) then
		YimActions.ShouldDrawCmdWindow = false
		return
	end

	if (not YimActions.ShouldDrawCmdWindow) then
		return
	end

	if (not windowPos) then
		_, windowPos = GUI:GetNewWindowSizeAndCenterPos(0.5, 0.5, windowSize)
	end

	ImGui.SetNextWindowSize(windowSize.x, windowSize.y)
	ImGui.SetNextWindowPos(windowPos.x, windowPos.y, ImGuiCond.Always)
	if (ImGui.Begin("##yav3_new_command",
			ImGuiWindowFlags.NoMove
			| ImGuiWindowFlags.NoResize
			| ImGuiWindowFlags.NoTitleBar
			| ImGuiWindowFlags.NoSavedSettings
			| ImGuiWindowFlags.AlwaysAutoResize)
		) then
		ImGui.Dummy(0, 20)
		ImGui.SetNextItemWidth(-1)
		strBuffer = ImGui.InputTextWithHint("##cmd", "Command Name (ex: /sitdown)", strBuffer, 64, ImGuiInputTextFlags.CharsNoBlank)

		ImGui.Dummy(0, 40)
		ImGui.BeginDisabled(strBuffer:isempty())
		if (GUI:Button(_T("GENERIC_CONFIRM"))) then
			ThreadManager:Run(function()
				YimActions:AddCommandAction(
					strBuffer,
					---@diagnostic disable-next-line
					{ label = selected_action.data.label, type = selected_action.action_type }
				)
				strBuffer = ""
			end)

			YimActions.ShouldDrawCmdWindow = false
		end
		ImGui.EndDisabled()

		ImGui.SameLine()
		if (GUI:Button(_T("GENERIC_CANCEL"))) then
			strBuffer = ""
			YimActions.ShouldDrawCmdWindow = false
		end

		ImGui.End()
	end
end
