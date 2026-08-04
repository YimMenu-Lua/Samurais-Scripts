-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@type Heist?
local selectedHeist

local COL_RED <const>      = Color.RED
local SoloMissions <const> = require("includes.thirdparty.SoloMissions.SoloMissions")
local MiniGameHack <const> = require("includes.thirdparty.MiniGameHack.MiniGameHack")
local HeistEditor          = require("includes.features.online.heist_editor.heist_editor")
local SGSL                 = require("includes.services.SGSL")
local measureTextWidth     = require("includes.frontend.helpers.measure_text_width")
local boostableHeistNames  = require("includes.data.heist_editor_data").BoostableHeistNames
local boostTunableOffset   = SGSL:Get(SGSL.data.heist_boosts_global_start):GetValue()
local boostTunableInit     = ScriptGlobal(262145):At(boostTunableOffset)
local editorButtonWidths   = {} ---@type table<int, int>
local editorButtonSize     = vec2:new(0, 32)
local buttonRedColors      = {
	["Button"]        = COL_RED,
	["ButtonHovered"] = COL_RED:Brighten(0.12),
	["ButtonActive"]  = COL_RED:Darken(0.12)
}
local checkboxSizes        = {
	["SoloMissions"]   = nil,
	["IgnoreProperty"] = nil,
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
		GUI:Text(_T("GENERIC_UNAVAILABLE_SP"))
		return
	end

	if (not Backend:IsUpToDate()) then
		GUI:Text(_T("GENERIC_OUTDATED"), { color = COL_RED })
		return
	end

	local isReady = HeistEditor:IsReady()
	ImGui.BeginDisabled(not isReady)
	ImGui.SetWindowFontScale(1.3)
	ImGui.Text("Heist Editor")
	ImGui.SetWindowFontScale(0.8)
	local dotsWidth = ImGui.CalcTextSize("  . . .  ")
	ImGui.SameLine(ImGui.GetContentRegionAvail() - dotsWidth)
	if (ImGui.SmallButton(" . . . ")) then
		ImGui.OpenPopup("##HeistEditorCtx")
	end
	ImGui.Text(_T("YH_SUBTITLE_TXT"))
	ImGui.SetWindowFontScale(1.0)
	ImGui.EndDisabled()
	ImGui.Spacing()

	if (not isReady) then
		ImGui.Text(ImGui.TextSpinner(_T("GENERIC_WAIT_LABEL"), 7.0, ImGuiSpinnerStyle.DOTS))
		ImGui.Dummy(0, 20)
		return
	end

	if (GUI:Button(_T("YH_VIEW_BOOSTS"))) then
		ImGui.OpenPopup("MPX_WEEKLY_BOOST_BS")
	end

	ImGui.SameLine()
	local cfg = GVars.features.yim_heists
	cfg.sixty_nine = GUI:Checkbox(" $69 ", cfg.sixty_nine, {
		tooltip = _T("YH_SIXTY_NINE_TT"), -- all setups cost sixty nine dallas
		onClick = function(v)
			HeistEditor:ToggleSetupCosts(v)
		end
	})

	local sm_cb_x = checkboxSizes["SoloMissions"]
	if (not sm_cb_x) then
		sm_cb_x = ImGui.CalcTextSize("SoloMissions") + 50
		checkboxSizes["SoloMissions"] = sm_cb_x
	end

	ImGui.SameLineIfAvail(sm_cb_x)
	cfg.solo_missions = GUI:Checkbox("SoloMissions", cfg.solo_missions, { tooltip = _T("YH_SOLO_MISSIONS_TT") })

	local prop_cb_x = checkboxSizes["IgnoreProperty"]
	if (not prop_cb_x) then
		prop_cb_x = ImGui.CalcTextSize("Ignore Property") + 50
		checkboxSizes["IgnoreProperty"] = prop_cb_x
	end

	ImGui.SameLineIfAvail(prop_cb_x)
	cfg.ignore_prop_req = GUI:Checkbox("Ignore Property", cfg.ignore_prop_req, { tooltip = _T("YH_IGNORE_PROP_REQ_TT") })

	local langIdx       = GVars.backend.language_index
	local btnWidth      = editorButtonWidths[langIdx]
	if (not btnWidth) then
		btnWidth = measureTextWidth({
			_T("YH_SKIP_OBJECTIVE"),
			_T("YH_FAIL_MISSION"),
			_T("YH_FINISH_MISSION"),
		}, 40)
		editorButtonWidths[langIdx] = btnWidth
		editorButtonSize.x = btnWidth
	end

	ImGui.Separator()

	ImGui.BeginDisabled(not HeistEditor:GetRunningScript())
	if (GUI:Button(_T("YH_FAIL_MISSION"), { size = editorButtonSize, colors = buttonRedColors })) then
		SoloMissions:ForceFail()
	end

	local ItemSpacing = ImGui.GetStyle().ItemSpacing.x
	ImGui.SameLineIfAvail(editorButtonSize.x + ItemSpacing)
	if (GUI:Button(_T("YH_SKIP_OBJECTIVE"), { size = editorButtonSize, tooltip = _T("YH_SKIP_OBJECTIVE_TT") })) then
		SoloMissions:SkipObjective()
	end

	ImGui.SameLineIfAvail(editorButtonSize.x + ItemSpacing)
	if (GUI:Button(_T("YH_FINISH_MISSION"), { size = editorButtonSize, tooltip = _T("YH_FINISH_MISSION_TT") })) then
		SoloMissions:InstantFinish()
	end
	ImGui.EndDisabled()

	ImGui.SameLineIfAvail(ItemSpacing + ImGui.CalcTextSize(">_ MGH"))
	local isMghDisabled = MiniGameHack:IsDisabled()
	ImGui.BeginDisabled(MiniGameHack:IsBusy() or isMghDisabled)
	if (GUI:Button(">_ MGH")) then
		MiniGameHack:OnCall()
	end
	ImGui.EndDisabled()
	GUI:Tooltip(_T("YH_MGH_FMT", GVars.keybinds.minigamehack:GetCurrentKeyName()))
	if (isMghDisabled) then
		GUI:Tooltip(_T("YH_MGH_ERR"), { color = COL_RED })
	end
	ImGui.Separator()

	local heists      = HeistEditor:GetHeists()
	local heistsCount = #heists
	if (heistsCount == 0) then
		ImGui.Spacing()
		ImGui.Text("Wow! Such empty!")
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

	if (ImGui.BeginPopup("##HeistEditorCtx")) then
		if (ImGui.MenuItem(_T("GENERIC_RELOAD"))) then
			HeistEditor:Reload()
			ImGui.CloseCurrentPopup()
		end
		ImGui.EndPopup()
	end

	ImGui.SetNextWindowSizeConstraints(480, 400, 600, 800)
	if (ImGui.BeginPopupModal("MPX_WEEKLY_BOOST_BS", true, ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoResize)) then
		drawBoostedHeists()
		ImGui.EndPopup()
	end
end)
