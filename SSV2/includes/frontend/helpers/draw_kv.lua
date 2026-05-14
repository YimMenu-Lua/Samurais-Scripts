-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@param key string
---@param value string
---@param valueColor? Color
return function(key, value, valueColor)
	if (type(value) ~= "string") then
		value = tostring(value)
	end

	ImGui.Text(key)
	ImGui.SameLine()

	local anchorWidth    = ImGui.CalcTextSize(value)
	local cursorX, _     = ImGui.GetCursorPosX()
	local availX, _      = ImGui.GetContentRegionAvail()
	local hasEnoughWidth = anchorWidth < (availX - cursorX)

	if (hasEnoughWidth) then
		ImGui.SetCursorPosX(cursorX + availX - anchorWidth)
	else
		ImGui.NewLine()
		ImGui.Indent()
	end

	GUI:Text(value, { color = valueColor })

	if (not hasEnoughWidth) then
		ImGui.Unindent()
	end
end
