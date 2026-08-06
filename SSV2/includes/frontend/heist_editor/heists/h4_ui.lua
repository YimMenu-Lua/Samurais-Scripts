-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local rawData <const> = require("includes.data.heist_editor_data").CayoPericoData
local drawPlayerCuts  = require("includes.frontend.heist_editor.helpers.draw_player_cuts")
local setupOrder      = { "primary_target", "weapons", "supply_truck_loc" }
local tpLabelWidths   = {} ---@type table<integer, integer>
local GXTLabels       = Translator.gxt_labels

---@param instance CayoPericoHeist
---@return boolean
local function header(instance)
	local kosatka = instance:GetProperty()
	local ignore_prop = GVars.features.yim_heists.ignore_prop_req
	if (not kosatka and not ignore_prop) then
		ImGui.TextWrapped(GXTLabels.HIF_SUB_HELP --[[ works the same as _T("HIF_SUB_HELP") minus the cost of calling _T ]])
		return false
	end

	if (kosatka) then
		ImGui.SetWindowFontScale(1.16)
		ImGui.TextCentered(_T("YH_GENERIC_PROPERTY"))
		ImGui.SetWindowFontScale(0.88)
		ImGui.TextCentered(GXTLabels.CELL_SUBMARINE)
		ImGui.SetWindowFontScale(1.0)

		local is_spawned = kosatka.is_spawned
		if (not is_spawned) then
			if (instance:GetKosatkaRequestState()) then
				ImGui.TextDisabled(ImGui.TextSpinner())
			else
				local btn_label   = _T("YH_CAYO_REQUEST_SUB")
				local label_width = ImGui.CalcTextSize(btn_label)
				ImGui.SetCursorPosX((ImGui.GetContentRegionAvail() - label_width) * 0.5)
				if (GUI:Button(btn_label)) then
					instance:RequestKosatka()
				end
			end
		else
			local coords, heading = kosatka.coords, kosatka.heading
			if (not coords or coords:is_zero()) then
				return true
			end

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
				local fwd_angle = math.rad(heading + 90)
				local offset    = vec3:new(math.cos(fwd_angle), math.sin(fwd_angle), 4) -- front of door
				LocalPlayer:Teleport(coords + offset)
			end

			ImGui.SameLine()
			if (GUI:Button(wp_label)) then
				Game.SetWaypointCoords(coords)
			end
		end
	end

	return true
end

---@param instance CayoPericoHeist
local function main(instance)
	GUI:HeaderText(_T("CP_HEIST_SETUP"), { separator = true, spacing = true })

	GUI:CustomToggle(_T("YH_CAYO_DIFFICULTY"), instance:IsOnHardMode(), {
		onClick = function()
			instance:ToggleHardMode()
		end
	})

	local heistData = instance:GetSetupData()
	local setupData = rawData.setup_data
	ImGui.PushItemWidth(math.min(200, ImGui.GetContentRegionAvail() - 60))
	for _, key in ipairs(setupOrder) do
		local setupDataEntry = setupData[key]
		local iValue         = heistData[key] ---@type integer?
		if not (setupDataEntry) then
			goto continue
		end

		local comboDataEntry = rawData[setupDataEntry.combo_data_key]
		if (not comboDataEntry) then
			goto continue
		end

		heistData[key] = ImGui.Combo(_T(setupDataEntry.label), (iValue or 0), comboDataEntry, setupDataEntry.data_size)

		::continue::
	end

	ImGui.PopItemWidth()

	ImGui.PushTextWrapPos()
	ImGui.TextDisabled(_T("YH_SECONDARY_TARGET_TXT"))
	ImGui.PopTextWrapPos()

	drawPlayerCuts(instance, false, "heist_island_planning")

	GUI:HeaderText(_T("GENERIC_OPTIONS_LABEL"), { separator = true, spacing = true })

	local cfg = GVars.features.yim_heists
	cfg.cayo_cd = GUI:CustomToggle(_T("YH_GENERIC_CD_LABEL"), cfg.cayo_cd, {
		tooltip = _T("YH_COOLDOWN_BYPASS_TOOLTIP"),
		color   = Color.RED,
	})
end

return {
	header_callback = header,
	main_callback   = main
}
