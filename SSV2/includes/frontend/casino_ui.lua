-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Original Author: gir489/spankerincrease
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CasinoPacino = require("includes.features.online.CasinoPacino")
local casino_pos   = vec3:new(924.6380, 46.6918, 81.1063)
local prizeBtnSize = vec2:new(0, 32)

---@type dict<eCasinoPrize>
local prizeLabels  = {
	["CP_LUCKY_WHEEL_GIVE_VEHICLE"]  = Enums.eCasinoPrize.VEHICLE,
	["CP_LUCKY_WHEEL_GIVE_MYSTERY"]  = Enums.eCasinoPrize.MYSTERY,
	["CP_LUCKY_WHEEL_GIVE_CASH"]     = Enums.eCasinoPrize.CASH,
	["CP_LUCKY_WHEEL_GIVE_CHIPS"]    = Enums.eCasinoPrize.CHIPS,
	["CP_LUCKY_WHEEL_GIVE_RP"]       = Enums.eCasinoPrize.RP,
	["CP_LUCKY_WHEEL_GIVE_DISCOUNT"] = Enums.eCasinoPrize.DISCOUNT,
	["CP_LUCKY_WHEEL_GIVE_CLOTHING"] = Enums.eCasinoPrize.CLOTHING,
	["CP_LUCKY_WHEEL_GIVE_SURPRISE"] = Enums.eCasinoPrize.RANDOM,
}

GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, "Casino Pacino", function()
	if (not Game.IsOnline()) then
		ImGui.Text(_T("GENERIC_UNAVAILABLE_SP"))
		return
	end

	if (not Backend:IsUpToDate()) then
		ImGui.Text(_T("GENERIC_OUTDATED"))
		return
	end

	ImGui.SetWindowFontScale(1.3)
	ImGui.Text("Casino Pacino")
	ImGui.SetWindowFontScale(0.89)
	ImGui.Text("It's not Al anymore, it's DUNK!")
	ImGui.SetWindowFontScale(1.0)
	ImGui.Separator()


	if (GUI:Button(_T("CP_TP_CASINO"))) then
		LocalPlayer:Teleport(casino_pos)
	end

	ImGui.SameLine()

	if (GUI:Button(_T("GENERIC_SET_WAYPOINT"))) then
		Game.SetWaypointCoords(casino_pos)
	end

	ImGui.Separator()
	ImGui.Spacing()

	GUI:HeaderText(_T("CP_COOLDOWN_BYPASS"), { separator = true, spacing = true })

	local cfg = GVars.features.dunk
	cfg.bypass_casino_bans = GUI:CustomToggle(_T("CP_COOLDOWN_BYPASS_ENABLE"), cfg.bypass_casino_bans, {
		tooltip = _T("CP_COOLDOWN_BYPASS_TOOLTIP"),
		color   = Color.RED
	})

	ImGui.BulletText(_T("CP_COOLDOWN_BYPASS_STATUS"))
	ImGui.SameLine()
	ImGui.Text(CasinoPacino:GetCooldownString())

	GUI:HeaderText(_T("CP_POKER_SETTINGS"), { separator = true, spacing = true })

	cfg.force_poker_cards       = GUI:CustomToggle(_T("CP_POKER_FORCE_ROYAL_FLUSH"), cfg.force_poker_cards)
	cfg.set_dealers_poker_cards = GUI:CustomToggle(_T("CP_POKER_FORCE_BAD_BEAT"), cfg.set_dealers_poker_cards)

	GUI:HeaderText(_T("CP_BLACKJACK_SETTINGS"), { separator = true, spacing = true })
	ImGui.BulletText(_T("CP_BLACKJACK_DEALER_FACE_DOWN_CARD"))

	ImGui.SameLine()
	ImGui.Text(CasinoPacino:GetBJDealerCard())

	if (GUI:Button(_T("CP_BLACKJACK_FORCE_DEALER_BUST"))) then
		CasinoPacino:ForceDealerBust()
	end

	GUI:HeaderText(_T("CP_ROULETTE_SETTINGS"), { separator = true, spacing = true })

	cfg.force_roulette_wheel = GUI:CustomToggle(_T("CP_ROULETTE_FORCE_RED_18"), cfg.force_roulette_wheel)

	GUI:HeaderText(_T("CP_SLOT_MACHINES_SETTINGS"), { separator = true, spacing = true })

	cfg.rig_slot_machine = GUI:CustomToggle(_T("CP_SLOT_MACHINES_RIG"), cfg.rig_slot_machine)
	cfg.autoplay_slots   = GUI:CustomToggle(_T("CP_SLOT_MACHINES_AUTOPLAY"), cfg.autoplay_slots)

	if (cfg.autoplay_slots) then
		cfg.cap_slot_machine_chips = GUI:CustomToggle(_T("CP_SLOT_MACHINES_CAP_CHIPS"), cfg.cap_slot_machine_chips)

		if (cfg.cap_slot_machine_chips) then
			ImGui.SameLine()
			cfg.slot_machine_cap = ImGui.SliderInt("##chips_cap", cfg.slot_machine_cap, 1e3, 1e5)
		end

		ImGui.Text(_T("CP_AUTOPLAY_SLOTS_TIME_DELAY"))
		ImGui.SameLine()
		if (not cfg.autoplay_slots_delay_random) then
			cfg.autoplay_slots_delay = ImGui.SliderInt("##delay_time", cfg.autoplay_slots_delay, 500, 1e4, "%d ms")
			ImGui.SameLine()
		end

		cfg.autoplay_slots_delay_random = GUI:CustomToggle(_T("GENERIC_RANDOM"), cfg.autoplay_slots_delay_random)
	end

	GUI:HeaderText(_T("CP_LUCKY_WHEEL_SETTINGS"), { separator = true, spacing = true })

	if (prizeBtnSize.x == 0) then
		for key in pairs(prizeLabels) do
			local width = ImGui.CalcTextSize(_T(key)) + (ImGui.GetStyle().FramePadding.x * 4)
			if (width > prizeBtnSize.x) then
				prizeBtnSize.x = width
			end
		end
	end

	local btnIdx = 1
	for label, prizeID in pairs(prizeLabels) do
		if (GUI:Button(_T(label), { size = prizeBtnSize })) then
			CasinoPacino:GiveWheelPrize(prizeID)
		end

		if ((btnIdx & 1) == 1) then
			ImGui.SameLine()
		end

		btnIdx = btnIdx + 1
	end
end)
