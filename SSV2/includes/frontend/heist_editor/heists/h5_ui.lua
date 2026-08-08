-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local rawData <const>   = require("includes.data.heist_editor_data").K26Data
local drawTeleports     = require("includes.frontend.heist_editor.helpers.draw_teleports")
local targets <const>   = rawData.targets
local teleports <const> = rawData.teleports
local GXTLabels         = Translator.gxt_labels
local tpLabelWidths     = {} ---@type table<integer, integer>
local selectedTpLoc     = teleports[1]

---@param instance KortzHeist
---@return boolean
local function header(instance)
	local mansion     = instance:GetProperty()
	local ignore_prop = GVars.features.yim_heists.ignore_prop_req
	if (not mansion and not ignore_prop) then
		ImGui.TextWrapped(GXTLabels.K26_FLW_HLP4C --[[ works the same as _T("K26_FLW_HLP4C") minus the cost of calling _T ]])
		return false
	end

	if (mansion) then
		ImGui.SetWindowFontScale(1.16)
		ImGui.TextCentered(_T("YH_GENERIC_PROPERTY"))
		ImGui.SetWindowFontScale(0.88)
		ImGui.TextCentered(_T(mansion.name))
		ImGui.SetWindowFontScale(1.0)

		local has_art_room = mansion.has_art_room
		if (not has_art_room and not ignore_prop) then
			ImGui.TextWrapped(GXTLabels.K26_FLW_HLP4B --[[ works the same as _T("K26_FLW_HLP4C") minus the cost of calling _T ]])
			return false
		end

		local coords = mansion.coords
		if (coords and not coords:is_zero()) then
			local style          = ImGui.GetStyle()
			local tp_label       = _T("GENERIC_TELEPORT")
			local wp_label       = _T("GENERIC_SET_WAYPOINT")
			local lang_idx       = GVars.backend.language_index
			local tp_label_width = tpLabelWidths[lang_idx]
			if (not tp_label_width) then
				tp_label_width = ImGui.CalcTextSize(tp_label)
					+ ImGui.CalcTextSize(wp_label)
					+ style.ItemSpacing.x
					+ (style.FramePadding.x * 4); tpLabelWidths[lang_idx] = tp_label_width
			end

			ImGui.SetCursorPosX((ImGui.GetContentRegionAvail() - tp_label_width) * 0.5)
			if (GUI:Button(tp_label)) then
				LocalPlayer:Teleport(coords)
			end

			ImGui.SameLine()
			if (GUI:Button(wp_label)) then
				Game.SetWaypointCoords(coords)
			end
		end
	end
	return true
end

---@param instance KortzHeist
local function main(instance)
	GUI:HeaderText(_T("CP_HEIST_SETUP"), { separator = true, spacing = true })

	GUI:CustomToggle(_T("YH_CAYO_DIFFICULTY"), instance:IsOnHardMode(), {
		onClick = function()
			instance:ToggleHardMode()
		end
	})

	local preview = targets[instance.m_current_target + 1] or "GENERIC_NONE"
	if (ImGui.BeginCombo(_T("CP_HEIST_TARGET"), _T(preview))) then
		for i, v in ipairs(rawData.targets) do
			local is_selected = (i == instance.m_current_target + 1)
			if (ImGui.Selectable(_T(v), is_selected)) then
				instance.m_current_target = i - 1
			end

			if (is_selected) then
				ImGui.SetItemDefaultFocus()
			end
		end
		ImGui.EndCombo()
	end

	ImGui.Spacing()
	local alreadyUnlocked = instance:AreAllSecondariesUnlocked()
	ImGui.BeginDisabled(alreadyUnlocked)
	if (GUI:Button(_T("YH_GENERIC_SKIP_PREPS"))) then
		instance:UnlockSecondaries()
	end
	ImGui.EndDisabled() -- alreadyUnlocked
	if (alreadyUnlocked) then
		GUI:Tooltip(_T("YH_GENERIC_SKIP_PREPS_TT"))
	end

	GUI:HeaderText(_T("GENERIC_OPTIONS_LABEL"), { separator = true, spacing = true })

	local cfg = GVars.features.yim_heists
	cfg.kortz_cd = GUI:CustomToggle(_T("YH_GENERIC_CD_LABEL"), cfg.kortz_cd, {
		tooltip = _T("YH_COOLDOWN_BYPASS_TOOLTIP"),
		color   = Color.RED,
	})

	cfg.kortz_week_bypass = GUI:CustomToggle(_T("YH_K26_DISABLE_WEEKLY_RESET"), cfg.kortz_week_bypass)
end

return {
	header_callback = header,
	main_callback   = main,
	draw_teleports  = function(_)
		drawTeleports(teleports, selectedTpLoc)
	end
}
