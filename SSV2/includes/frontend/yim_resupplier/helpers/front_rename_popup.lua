-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@param name_buff { value: string } a reference to a string buffer
---@param business BusinessFront
return function(name_buff, business)
	ImGui.Spacing()

	-- GPBD_FM_3 stores a 64 byte fixed-length string but the in-game UI limits the length to just 15 chars.
	-- I can't find anything in the game that strictly enforces 15 characters other than the input box so we should be
	-- able to use the full 64. Not sure if that will break something else so for now we'll just keep the intended limit.
	name_buff.value = ImGui.InputTextWithHint("##newName", _T("GENERIC_NAME"), name_buff.value, 15)

	ImGui.SameLine()
	if (GUI:Button(_T("GENERIC_SAVE"))) then
		business:Rename(name_buff.value)
		ImGui.CloseCurrentPopup()
		name_buff.value = ""
	end

	ImGui.SameLine()
	if (GUI:Button(_T("GENERIC_CANCEL"))) then
		ImGui.CloseCurrentPopup()
		name_buff.value = ""
	end

	ImGui.Spacing()
end
