-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local rawData <const>      = require("includes.data.heist_editor_data").CasinoHeistData
local SoloMissions <const> = require("includes.thirdparty.SoloMissions")
local drawPlayerCuts       = require("includes.frontend.heist_editor.helpers.draw_player_cuts")
local enableBoardPatch     = false
local teleportsArray       = rawData.teleports
local selectedTpLoc        = teleportsArray[1]
local setupOrder           = {
	"target",
	"approach",
	"last_approach",
	"hard_approach",
	"gunman",
	"driver",
	"hacker",
	"weapons",
	"cars",
	"masks"
}

---@param instance CasinoHeist
local function drawTeleports(instance)
	ImGui.Spacing()
	ImGui.SeparatorText(_T("GENERIC_TELEPORT"))
	if (ImGui.BeginCombo("##teleportList", _T(selectedTpLoc.label))) then
		for _, v in ipairs(teleportsArray) do
			local is_selected = v == selectedTpLoc
			if (ImGui.Selectable(_T(v.label), is_selected)) then
				selectedTpLoc = v
			end
			if (is_selected) then
				ImGui.SetItemDefaultFocus()
			end
		end
		ImGui.EndCombo()
	end

	local coords = selectedTpLoc.coords
	ImGui.SameLine()
	ImGui.BeginDisabled(not coords or coords:is_zero())
	if (GUI:Button(_T("GENERIC_GO"))) then
		LocalPlayer:Teleport(coords)
	end
	ImGui.EndDisabled() -- !coords
end

---@param instance CasinoHeist
local function main(instance)
	GUI:HeaderText(_T("CP_HEIST_SETUP"), { separator = true, spacing = true })
	ImGui.PushItemWidth(math.min(200, ImGui.GetContentRegionAvail() - 60))

	local cfg       = GVars.features.dunk
	local heistData = instance:GetSetupData()
	local setupData = rawData.setup_data
	for _, key in ipairs(setupOrder) do
		if (key == "weapons" or key == "cars") then
			goto continue
		end

		local setupDataEntry = setupData[key]
		local iValue         = heistData[key] ---@type integer?
		if (not setupDataEntry) then
			goto continue
		end

		local comboDataEntry = rawData[setupDataEntry.combo_data_key]
		if (not comboDataEntry) then
			goto continue
		end

		heistData[key] = ImGui.Combo(_T(setupDataEntry.label), (iValue or 0), comboDataEntry, setupDataEntry.data_size)

		::continue::
	end

	local gunman = heistData.gunman
	if (gunman > 0) then
		local weaps = rawData.guns[gunman]
		if (not weaps) then
			heistData.gunman = 1
			weaps = rawData.guns[1]
		end
		heistData.weapons = ImGui.Combo(_T("CP_HEIST_WEAPONS"), heistData.weapons, weaps[heistData.approach + 1], 2)
	end

	local driver = heistData.driver
	if (driver > 0) then
		local vehs = rawData.cars[driver]
		if (not vehs) then
			heistData.driver = 1
			vehs = rawData.cars[1]
		end

		heistData.cars = ImGui.Combo(_T("CP_HEIST_GETAWAY_VEHS"), heistData.cars, vehs, 4)
	end

	ImGui.PopItemWidth()

	drawPlayerCuts(instance, false, "gb_casino_heist_planning")

	GUI:HeaderText(_T("GENERIC_OPTIONS_LABEL"), { separator = true, spacing = true })

	local alreadyUnlocked = instance:HasUnlockedSecondaries()
	ImGui.BeginDisabled(alreadyUnlocked)
	if (GUI:Button(_T("YH_GENERIC_SKIP_PREPS"))) then
		instance:SetSecondaries()
	end
	ImGui.EndDisabled() -- alreadyUnlocked
	if (alreadyUnlocked) then
		GUI:Tooltip(_T("YH_GENERIC_SKIP_PREPS_TT"))
	end

	ImGui.Spacing()
	cfg.disable_heist_cooldown = GUI:CustomToggle(_T("YH_GENERIC_CD_LABEL"), cfg.disable_heist_cooldown)
	cfg.zero_ai_cuts           = GUI:CustomToggle(_T("CP_HEIST_ZERO_AI_CUTS"), cfg.zero_ai_cuts)
	cfg.ch_cart_autograb       = GUI:CustomToggle(_T("CP_HEIST_AUTOGRAB"), cfg.ch_cart_autograb)
	enableBoardPatch           = GUI:CustomToggle(_T("YH_CH_SOLO_PATCH"), enableBoardPatch, {
		onClick = function(v)
			SoloMissions:ToggleCasinoPatch(v)
		end,
		tooltip = _T("YH_CH_SOLO_PATCH_TT")
	})
end

return {
	main_callback  = main,
	draw_teleports = drawTeleports
}
