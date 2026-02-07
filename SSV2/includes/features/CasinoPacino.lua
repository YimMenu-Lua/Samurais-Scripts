-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local SGSL = require("includes.services.SGSL")

---@enum eCasinoPrize
Enums.eCasinoPrize = {
	VEHICLE  = 1,
	MYSTERY  = 2,
	CASH     = 3,
	CHIPS    = 4,
	RP       = 5,
	DISCOUNT = 6,
	CLOTHING = 7,
}

local CasinoPrizes <const> = {
	[Enums.eCasinoPrize.VEHICLE] = { v = 18 },
	[Enums.eCasinoPrize.MYSTERY] = { v = 11 },
	[Enums.eCasinoPrize.CASH] = { v = 19 },
	[Enums.eCasinoPrize.CHIPS] = { v = 15 },
	[Enums.eCasinoPrize.RP] = { v = 17 },
	[Enums.eCasinoPrize.DISCOUNT] = { v = 4 },
	[Enums.eCasinoPrize.CLOTHING] = { v = 8 },
}

---@class CasinoPacino
---@field m_tab Tab
---@field protected m_thread Thread?
local CasinoPacino = {}
CasinoPacino.__index = CasinoPacino

---@return CasinoPacino
function CasinoPacino:init()
	local instance = setmetatable({
		m_tab = GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, "Casino Pacino")
	}, self)

	instance.m_thread = ThreadManager:RegisterLooped("SS_DUNK", function()
		instance:Main()
	end)

	return instance
end

function CasinoPacino:CanAccess()
	return (Backend:GetAPIVersion() == Enums.eAPIVersion.V1)
		and Backend:IsUpToDate()
		and Game.IsOnline()
		and not script.is_active("maintransition")
		and not NETWORK.NETWORK_IS_ACTIVITY_SESSION()
end

---@param prizeID eCasinoPrize
function CasinoPacino:GiveWheelPrize(prizeID)
	if (not script.is_active("casino_lucky_wheel")) then
		Notifier:ShowError("CasinoPacino", _T("CP_MUST_BE_AT_WHEEL"))
		return
	end

	local win_state_local         = SGSL:Get(SGSL.data.prize_wheel_win_state)
	local prize_wheel_win_state   = win_state_local:AsLocal()
	local prize_wheel_prize       = win_state_local:GetOffset(1)
	local prize_wheel_prize_state = SGSL:Get(SGSL.data.prize_wheel_prize_state):GetOffset(1)
	local obj                     = CasinoPrizes[prizeID]
	if (not obj) then
		log.fdebug("Unknown prize ID selected: %d", prizeID)
		return
	end


	prize_wheel_win_state:At(prize_wheel_prize):WriteInt(obj.v)
	prize_wheel_win_state:At(prize_wheel_prize_state):WriteInt(11)
	-- locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), obj.v)
	-- locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
end

---@param card_index number
function CasinoPacino:GetCardNameFromIndex(card_index)
	if (card_index == 0) then
		return "Rolling"
	end

	local card_number = math.fmod(card_index, 13)
	local numberCases = {
		[0] = _T("CP_CARD_KING"),
		[1] = _T("CP_CARD_ACE"),
		[11] = _T("CP_CARD_JACK"),
		[12] = _T("CP_CARD_QUEEN"),
		default = tostring(card_number)
	}
	local cardName = Match(card_number, numberCases)
	local cardSuit = ""

	if card_index >= 1 or card_index <= 13 then
		cardSuit = _T("CP_CARD_CLUBS")
	elseif card_index >= 14 or card_index <= 26 then
		cardSuit = _T("CP_CARD_DIAMONDS")
	elseif card_index >= 27 or card_index <= 39 then
		cardSuit = _T("CP_CARD_HEARTS")
	elseif card_index >= 40 or card_index <= 52 then
		cardSuit = _T("CP_CARD_SPADES")
	end

	return _F("%s of %s", cardName, cardSuit)
end

function CasinoPacino:ForceDealerBust()
	ThreadManager:Run(function(s)
		local player_id                    = Self:GetPlayerID()
		local bjc_obj                      = SGSL:Get(SGSL.data.blackjack_cards)
		local btp_obj                      = SGSL:Get(SGSL.data.blackjack_table_players)
		local blackjack_cards              = bjc_obj:GetValue()
		local blackjack_decks              = bjc_obj:GetOffset(1)
		local blackjack_table_players      = btp_obj:GetValue()
		local blackjack_table_players_size = btp_obj:GetOffset(1)
		if (not player_id
				or not blackjack_cards
				or not blackjack_decks
				or not blackjack_table_players
				or not blackjack_table_players_size
			) then
			Notifier:ShowError("Casino Pacino", "Failed to force dealer to bsut! Unable to read script local.")
			return
		end

		local giveupTimer = Timer.new(3e4)
		local success     = true
		Notifier:ShowMessage("Casino Pacino", _T("CP_BLACKJACK_SCRIPT_CONTROL"))
		while (not Self:IsHostOfScript("blackjack")) do
			if (giveupTimer:is_done()) then
				success = false
				break
			end

			network.force_script_host("blackjack")
			s:yield()
		end

		if (not success) then
			Notifier:ShowError("Casino Pacino", _T("GENERIC_SCRIPT_CTRL_FAIL"))
			return
		end

		local blackjack_table = locals.get_int("blackjack",
			blackjack_table_players
			+ 1
			+ (player_id * blackjack_table_players_size)
			+ 4
		) --The Player's current table he is sitting at.

		if (blackjack_table == -1) then
			return
		end

		local BJCards = ScriptLocal(
				blackjack_cards,
				"blackjack")
			:At(blackjack_decks)
			:At(1)
			:At(blackjack_table * 13)

		BJCards:At(1):WriteInt(11)
		BJCards:At(2):WriteInt(12)
		BJCards:At(3):WriteInt(13)
		BJCards:At(12):WriteInt(3)
	end)
end

---@param player_id integer
---@param players_current_table integer
---@param card_one integer
---@param card_two integer
---@param card_three integer
function CasinoPacino:SetPokerCards(player_id, players_current_table, card_one, card_two, card_three)
	local tcpc_obj                         = SGSL:Get(SGSL.data.three_card_poker_cards)
	local tcp_ac_obj                       = SGSL:Get(SGSL.data.three_card_poker_anti_cheat)
	local three_card_poker_cards           = tcpc_obj:GetValue()
	local three_card_poker_current_deck    = tcpc_obj:GetOffset(1)
	local three_card_poker_deck_size       = SGSL:Get(SGSL.data.three_card_poker_deck_size):GetValue()
	local three_card_poker_anti_cheat      = tcp_ac_obj:GetValue()
	local three_card_poker_anti_cheat_deck = tcp_ac_obj:GetOffset(1)
	local TCPCards                         = ScriptLocal(
			three_card_poker_cards,
			"three_card_poker")
		:At(three_card_poker_current_deck)
		:At(1)
		:At(players_current_table * three_card_poker_deck_size)
		:At(2)

	local TCPAC                            = ScriptLocal(
			three_card_poker_anti_cheat,
			"three_card_poker")
		:At(three_card_poker_anti_cheat_deck)
		:At(1)
		:At(1)
		:At(players_current_table * three_card_poker_deck_size)

	TCPCards:At(1):At(player_id * 3):WriteInt(card_one)
	TCPAC:At(1):At(player_id * 3):WriteInt(card_one)

	TCPCards:At(2):At(player_id * 3):WriteInt(card_two)
	TCPAC:At(2):At(player_id * 3):WriteInt(card_two)

	TCPCards:At(3):At(player_id * 3):WriteInt(card_three)
	TCPAC:At(3):At(player_id * 3):WriteInt(card_three)
end

function CasinoPacino:ForcePokerCards()
	if (not GVars.features.dunk.force_poker_cards or not script.is_active("three_card_poker")) then
		return
	end

	local player_id = Self:GetPlayerID()
	while ((NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", -1, 0) ~= player_id)
			and (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 0, 0) ~= player_id)
			and (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 1, 0) ~= player_id)
			and (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 2, 0) ~= player_id)
			and (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 3, 0) ~= player_id)
		) do
		network.force_script_host("three_card_poker")
		Notifier:ShowMessage("CasinoPacino", _T("CP_POKER_SCRIPT_CONTROL"))
		sleep(500)
	end

	local tcpt_obj                      = SGSL:Get(SGSL.data.three_card_poker_table)
	local tcpc_obj                      = SGSL:Get(SGSL.data.three_card_poker_cards)
	local three_card_poker_table        = tcpt_obj:GetValue()
	local three_card_poker_table_size   = tcpt_obj:GetOffset(1)
	local three_card_poker_cards        = tcpc_obj:GetValue()
	local three_card_poker_current_deck = tcpc_obj:GetOffset(1)
	local three_card_poker_deck_size    = SGSL:Get(SGSL.data.three_card_poker_deck_size):GetValue()
	local TCTable                       = ScriptLocal(three_card_poker_table, "three_card_poker"):At(1)
	local players_current_table         = TCTable:At(player_id * three_card_poker_table_size):At(2):ReadInt()

	if (players_current_table ~= -1) then -- If the player is sitting at a poker table
		-- "three_card_poker", (three_card_poker_cards) + (three_card_poker_current_deck) + (1 + (players_current_table * three_card_poker_deck_size)) + (2) +
		local PlayerCardLocal = ScriptLocal(
				three_card_poker_cards,
				"three_card_poker")
			:At(three_card_poker_current_deck)
			:At(1)
			:At(players_current_table * three_card_poker_deck_size)
			:At(2)

		local player_0_card_1 = PlayerCardLocal:At(1):At(0 * 3):ReadInt()
		local player_0_card_2 = PlayerCardLocal:At(2):At(0 * 3):ReadInt()
		local player_0_card_3 = PlayerCardLocal:At(3):At(0 * 3):ReadInt()

		if (player_0_card_1 ~= 50) or (player_0_card_2 ~= 51) or (player_0_card_3 ~= 52) then
			local total_players = 0

			for player_iter = 0, 31, 1 do
				local player_table = TCTable:At(player_iter * three_card_poker_table_size):At(2):ReadInt()
				if (player_iter ~= player_id) and (player_table == players_current_table) then
					total_players = total_players + 1
				end
			end

			for playing_player_iter = 0, total_players, 1 do
				self:SetPokerCards(playing_player_iter, players_current_table, 50, 51, 52)
			end

			if (GVars.features.dunk.set_dealers_poker_cards) then
				self:SetPokerCards(total_players + 1, players_current_table, 1, 8, 22)
			end
		end
	end
end

function CasinoPacino:ForceRouletteWheel()
	if (not GVars.features.dunk.force_roulette_wheel or not script.is_active("casinoroulette")) then
		return
	end

	local player_id               = Self:GetPlayerID()
	local rmt_obj                 = SGSL:Get(SGSL.data.roulette_master_table)
	local roulette_master_table   = rmt_obj:GetValue()
	local roulette_outcomes_table = rmt_obj:GetOffset(1)
	local roulette_ball_table     = SGSL:Get(SGSL.data.roulette_ball_table_offset):GetValue()

	while (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", -1, 0) ~= player_id
			and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 0, 0) ~= player_id
			and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 1, 0) ~= player_id
			and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 2, 0) ~= player_id
			and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 3, 0) ~= player_id
		) do
		network.force_script_host("casinoroulette")
		Notifier:ShowMessage("CasinoPacino", _T("CP_ROULETTE_SCRIPT_CONTROL")) --If you see this spammed, someone if fighting you for control.
		sleep(500)
	end

	for tabler_iter = 0, 6, 1 do
		locals.set_int("casinoroulette",
			(roulette_master_table) + (roulette_outcomes_table) + (roulette_ball_table) + (tabler_iter), 18)
	end
end

function CasinoPacino:RigSlotMachine()
	if (not script.is_active("casino_slots")) then
		return
	end

	local needs_run = false
	local SlotsResultLocal = SGSL:Get(SGSL.data.slots_random_result_table):AsLocal()

	if (GVars.features.dunk.rig_slot_machine) then
		for slots_iter = 3, 196, 1 do
			if (slots_iter ~= 67 and slots_iter ~= 132) then
				if (SlotsResultLocal:At(slots_iter):ReadInt() ~= 6) then
					needs_run = true
				end
			end
		end
	else
		local sum = 0
		for slots_iter = 3, 196, 1 do
			if (slots_iter ~= 67 and slots_iter ~= 132) then
				sum = sum + SlotsResultLocal:At(slots_iter):ReadInt()
			end
		end
		needs_run = sum == 1152
	end

	if (not needs_run) then
		return
	end

	for slots_iter = 3, 196, 1 do
		if (slots_iter ~= 67 and slots_iter ~= 132) then
			local slot_result = 6
			if (not GVars.features.dunk.rig_slot_machine) then
				math.randomseed(os.time() + slots_iter)
				slot_result = math.random(0, 7)
			end

			SlotsResultLocal:At(slots_iter):WriteInt(slot_result)
		end
	end
end

function CasinoPacino:AutoPlaySlots()
	if (not GVars.features.dunk.autoplay_slots) then
		return
	end

	local slots_slot_machine_state = SGSL:Get(SGSL.data.slots_slot_machine_state):AsLocal()
	local slotstate = slots_slot_machine_state:ReadInt()
	local autoplay_cap = GVars.features.dunk.cap_slot_machine_chips
	local delay = GVars.features.dunk.autoplay_slots_delay

	if (GVars.features.dunk.autoplay_slots_delay_random) then
		math.randomseed(os.time() * 60)
		delay = math.random(500, 1e4)
	end

	if (Bit.is_set(slotstate, 0)) then --The user is sitting at a slot machine.
		local chips = stats.get_int("MPX_CASINO_CHIPS")
		local chip_cap = GVars.features.dunk.slot_machine_cap
		if ((autoplay_cap and chips < chip_cap) or not autoplay_cap) then
			if (not Bit.is_set(slotstate, 24)) then --The slot machine is not currently spinning.
				yield()                    -- Wait for the previous spin to clean up, if we just came from a spin.
				slotstate = Bit.set(slotstate, 3) -- Bitwise set the 3rd bit (begin playing)
				slots_slot_machine_state:WriteInt(slotstate)
				sleep(delay)               -- If we rewrite the begin playing bit again, the machine will get stuck.
			end
		end
	end
end

---@return string
function CasinoPacino:GetCooldownString()
	local cooldown_time = tunables.get_int("VC_CASINO_CHIP_MAX_WIN_LOSS_COOLDOWN")
	local time_delta    = os.time() - stats.get_int("MPPLY_CASINO_CHIPS_WONTIM")
	local minutes_left  = (cooldown_time - time_delta) / 60
	local chipswon_gd   = stats.get_int("MPPLY_CASINO_CHIPS_WON_GD")
	local max_chip_wins = tunables.get_int("VC_CASINO_CHIP_MAX_WIN_DAILY")

	return
		(chipswon_gd >= max_chip_wins)
		and _F(_T("CP_COOLDOWN_BYPASS_STATUS_FORMAT"), minutes_left)
		or _T("CP_COOLDOWN_BYPASS_STATUS_OFF")
end

---@return string
function CasinoPacino:GetBJDealerCard()
	if (not script.is_active("blackjack")) then
		return _T("CP_NOT_IN_CASINO")
	end

	local bjc_obj                      = SGSL:Get(SGSL.data.blackjack_cards)
	local bjtp_obj                     = SGSL:Get(SGSL.data.blackjack_table_players)
	local blackjack_cards              = bjc_obj:GetValue()
	local blackjack_decks              = bjc_obj:GetOffset(1)
	local blackjack_table_players      = bjtp_obj:GetValue()
	local blackjack_table_players_size = bjtp_obj:GetOffset(1)
	local blackjack_table              = locals.get_int("blackjack",
		blackjack_table_players
		+ 1
		+ (Self:GetPlayerID() * blackjack_table_players_size)
		+ 4
	)

	if (blackjack_table ~= -1) then
		local dealers_card = locals.get_int("blackjack",
			blackjack_cards
			+ blackjack_decks
			+ 1
			+ (blackjack_table * 13)
			+ 1
		)
		return self:GetCardNameFromIndex(dealers_card)
	else
		return _T("CP_NOT_PLAYING_BLACKJACK")
	end
end

function CasinoPacino:SetCartAutoGrab()
	if (not GVars.features.dunk.ch_cart_autograb) then
		return
	end

	local fmmc_obj    = SGSL:Get(SGSL.data.fm_mission_controller_cart_grab)
	local fmmc_cg     = fmmc_obj:AsLocal()
	local fmmc_cg_spd = fmmc_obj:GetOffset(1)

	if (fmmc_cg:ReadInt() == 3) then
		fmmc_cg:WriteInt(4)
	elseif (fmmc_cg:ReadInt() == 4) then
		fmmc_cg:At(fmmc_cg_spd):WriteFloat(2.0)
	end
end

function CasinoPacino:BypassCooldown()
	if (not GVars.features.dunk.bypass_casino_bans) then
		return
	end

	stats.set_int("MPPLY_CASINO_CHIPS_WON_GD", 0)
	stats.set_int("MPPLY_CASINO_CHIPS_WONTIM", 0)
	stats.set_int("MPPLY_CASINO_GMBLNG_GD", 0)
	stats.set_int("MPPLY_CASINO_BAN_TIME", 0)
	stats.set_int("MPPLY_CASINO_CHIPS_PURTIM", 0)
	stats.set_int("MPPLY_CASINO_CHIPS_PUR_GD", 0)
	stats.set_int("MPPLY_CASINO_CHIPS_SOLD", 0)
	stats.set_int("MPPLY_CASINO_CHIPS_SELTIM", 0)
end

function CasinoPacino:Main()
	if (not Backend:IsUpToDate() and self.m_thread and self.m_thread:IsRunning()) then
		self.m_thread:Stop()
	end

	if (not self:CanAccess()) then
		sleep(500)
		return
	end

	self:BypassCooldown()
	self:ForcePokerCards()
	self:ForceRouletteWheel()
	self:RigSlotMachine()
	self:SetCartAutoGrab()
	self:AutoPlaySlots()
end

return CasinoPacino
