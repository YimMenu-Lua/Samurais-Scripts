-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local COL_RED <const>     = Color.RED
local selectedHeist       = nil ---@type Heist?
local HeistEditor         = require("includes.features.online.heist_editor.heist_editor")
local SGSL                = require("includes.services.SGSL")
local measureTextWidth    = require("includes.frontend.helpers.measure_text_width")
local boostableHeistNames = require("includes.data.heist_editor_data").BoostableHeistNames
local boostTunableInit    = SGSL:Get(SGSL.data.heist_boosts_global_start):AsGlobal()
local editorButtonWidths  = {} ---@type table<int, int>
local editorButtonSize    = vec2:new(0, 32)
local buttonRedColors     = {
	["Button"]        = COL_RED,
	["ButtonHovered"] = COL_RED:Brighten(0.12),
	["ButtonActive"]  = COL_RED:Darken(0.12)
}

local function drawBoostedHeists()
	local v = stats.get_int("MPX_WEEKLY_BOOST_BS")

	ImGui.Separator()
	ImGui.TextDisabled(Bit.Tostring(v, 32))
	ImGui.Separator()

	local should_disable = not GVars.features.unsafe_feats_enabled
	if (should_disable) then
		ImGui.TextWrapped(_T("YRV3_UNSAFE_FEAT_BYPASS_ERR"))
		ImGui.Spacing()
		ImGui.Spacing()
	end

	ImGui.BeginDisabled(should_disable)
	for i, gxt in ipairs(boostableHeistNames) do
		local label   = _T(gxt)
		local bitPos  = i - 1
		local boosted = not Bit.IsBitSet(v, bitPos) and boostTunableInit:At(bitPos, 1):ReadInt() == 0
		if (select(2, GUI:CustomToggle(label, boosted))) then
			stats.set_int("MPX_WEEKLY_BOOST_BS", Bit.Flip(v, bitPos))
			if (boostTunableInit:ReadInt() ~= 0) then
				boostTunableInit:WriteInt(0)
			end
			boostTunableInit:At(bitPos, 1):WriteInt(boosted and 1 or 0)
		end
	end
	ImGui.EndDisabled()
end

GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, "Heist Editor", function()
	if (not Game.IsOnline()) then
		ImGui.Text(_T("GENERIC_UNAVAILABLE_SP"))
		return
	end

	if (not Backend:IsUpToDate()) then
		ImGui.Text(_T("GENERIC_OUTDATED"))
		return
	end

	local heists = HeistEditor:GetHeists()
	ImGui.SetWindowFontScale(1.3)
	ImGui.Text("Heist Editor")
	ImGui.SetWindowFontScale(0.8)
	ImGui.Text(_T("YH_SUBTITLE_TXT"))
	ImGui.SetWindowFontScale(1.0)
	ImGui.Spacing()

	if (GUI:Button(_T("YH_VIEW_BOOSTS"))) then
		ImGui.OpenPopup("MPX_WEEKLY_BOOST_BS")
	end

	local langIdx = GVars.backend.language_index
	local btnWidth = editorButtonWidths[langIdx]
	if (not btnWidth) then
		btnWidth = measureTextWidth({
			_T("YH_SKIP_OBJECTIVE"),
			_T("YH_FAIL_MISSION"),
			_T("YH_FINISH_MISSION"),
		}, 40)
		editorButtonWidths[langIdx] = btnWidth
		editorButtonSize.x = btnWidth
	end

	ImGui.SameLine()
	local cfg = GVars.features.yim_heists
	cfg.sixty_nine = GUI:Checkbox("$69", cfg.sixty_nine, {
		tooltip = "Heist setups cost sixty nine dollars.",
		onClick = function(v)
			HeistEditor:ToggleSetupCosts(v)
		end
	})

	ImGui.BeginDisabled(not HeistEditor:GetRunningScript())
	if (GUI:Button(_T("YH_FAIL_MISSION"), { size = editorButtonSize, colors = buttonRedColors })) then
		HeistEditor.SoloMissions:ForceFail()
	end

	local ItemSpacing = ImGui.GetStyle().ItemSpacing.x
	ImGui.SameLineIfAvail(editorButtonSize.x + ItemSpacing)
	if (GUI:Button(_T("YH_SKIP_OBJECTIVE"), { size = editorButtonSize, tooltip = _T("YH_SKIP_OBJECTIVE_TT") })) then
		HeistEditor.SoloMissions:SkipObjective()
	end

	ImGui.SameLineIfAvail(editorButtonSize.x + ItemSpacing)
	if (GUI:Button(_T("YH_FINISH_MISSION"), { size = editorButtonSize, tooltip = _T("YH_FINISH_MISSION_TT") })) then
		HeistEditor.SoloMissions:InstantFinish()
	end
	ImGui.EndDisabled()

	ImGui.SetNextWindowSizeConstraints(480, 400, 600, 800)
	if (ImGui.BeginPopupModal("MPX_WEEKLY_BOOST_BS", true, ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoResize)) then
		drawBoostedHeists()
		ImGui.EndPopup()
	end

	ImGui.Separator()

	local heistsCount = #heists
	if (heistsCount == 0) then
		ImGui.Spacing()
		GUI:Text(_T("YH_LOAD_ERR"), { color = Color.RED })
		ImGui.Spacing()
		return
	end

	if (not selectedHeist) then
		selectedHeist = heists[1]
	end

	local regionWidth, _ = ImGui.GetContentRegionAvail()
	local comboWidth     = regionWidth * 0.8
	ImGui.SetCursorPosX((ImGui.GetCursorPosX() + regionWidth - comboWidth) * 0.5)
	ImGui.SetNextItemWidth(comboWidth)
	ImGui.PushStyleVar(ImGuiStyleVar.SelectableTextAlign, 0.5, 0.5)
	if (ImGui.BeginCombo("##heisList", "")) then
		for i = 1, heistsCount do
			local heist    = heists[i]
			local selected = (heist == selectedHeist)
			if (ImGui.Selectable(heist:GetName(), selected)) then
				selectedHeist = heist
			end

			if (selected) then
				ImGui.SetItemDefaultFocus()
			end
		end
		ImGui.EndCombo()
	end
	ImGui.PopStyleVar()

	local previewText   = selectedHeist:GetName()
	local textWidth     = ImGui.CalcTextSize(previewText)
	local previewSpaceW = comboWidth - 50 -- I don't know what size the combo arrow is. 50 looks close enough.
	local centrePos     = (previewSpaceW - textWidth) * 0.5
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + centrePos - comboWidth)
	ImGui.Text(previewText)

	if (selectedHeist) then
		selectedHeist:Draw()
	end
end)
