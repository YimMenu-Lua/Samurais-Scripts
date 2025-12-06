---@class CasinoPacino
---@field casino_cooldown_update_str string
---@field dealers_card_str string
local CasinoPacino = {}
CasinoPacino.__index = CasinoPacino

---@return CasinoPacino
function CasinoPacino:init()
    local instance = setmetatable({
        casino_cooldown_update_str = "",
        dealers_card_str = "",
    }, self)

    ThreadManager:CreateNewThread("SS_DUNK", function()
        instance:Start()
    end)

    Backend:RegisterEventCallback(eBackendEvent.RELOAD_UNLOAD, function()
        instance:Reset()
    end)

    Backend:RegisterEventCallback(eBackendEvent.SESSION_SWITCH, function()
        instance:Reset()
    end)

    return instance
end

function CasinoPacino:CanAccess()
    return (Backend:GetAPIVersion() == eAPIVersion.V1)
    and Backend:IsUpToDate()
    and Game.IsOnline()
    and not script.is_active("maintransition")
    and not NETWORK.NETWORK_IS_ACTIVITY_SESSION()
end

---@param prizeType string
function CasinoPacino:GiveWheelPrize(prizeType)
    local prize_wheel_win_state     = GetScriptGlobalOrLocal("prize_wheel_win_state")
    local prize_wheel_prize         = GetScriptGlobalOrLocal("prize_wheel_prize")
    local prize_wheel_prize_state   = GetScriptGlobalOrLocal("prize_wheel_prize_state")
    --add logic to give prize based on type
    if prizeType == "vehicle" then
        if script.is_active("casino_lucky_wheel") then
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 18)
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
        else
            Toast:ShowMessage("CasinoPacino", _T("CP_MUST_BE_AT_WHEEL"))
        end
    elseif prizeType == "mystery" then
        if script.is_active("casino_lucky_wheel") then
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 11)
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
        else
            Toast:ShowMessage("CasinoPacino", _T("CP_MUST_BE_AT_WHEEL"))
        end
    elseif prizeType == "cash" then
        if script.is_active("casino_lucky_wheel") then
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 19)
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
        else
            Toast:ShowMessage("CasinoPacino", _T("CP_MUST_BE_AT_WHEEL"))
        end
    elseif prizeType == "chips" then
        if script.is_active("casino_lucky_wheel") then
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 15)
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
        else
            Toast:ShowMessage("CasinoPacino", _T("CP_MUST_BE_AT_WHEEL"))
        end
    elseif prizeType == "rp" then
        if script.is_active("casino_lucky_wheel") then
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 17)
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
        else
            Toast:ShowMessage("CasinoPacino", _T("CP_MUST_BE_AT_WHEEL"))
        end
    elseif prizeType == "discount" then
        if script.is_active("casino_lucky_wheel") then
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 4)
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
        else
            Toast:ShowMessage("CasinoPacino", _T("CP_MUST_BE_AT_WHEEL"))
        end
    elseif prizeType == "clothing" then
        if script.is_active("casino_lucky_wheel") then
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 8)
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
        else
            Toast:ShowMessage("CasinoPacino", _T("CP_MUST_BE_AT_WHEEL"))
        end
    elseif prizeType == "surprise" then
        Toast:ShowMessage("CasinoPacino", _T("CP_FEATURE_DISABLED"))
    end
end

function CasinoPacino:GetCardNameFromIndex(card_index)
    if card_index == 0 then
        return "Rolling"
    end

    local card_number = math.fmod(card_index, 13)
    local cardName = ""
    local cardSuit = ""

    if card_number == 1 then
        cardName = _T("CP_CARD_ACE")
    elseif card_number == 11 then
        cardName = _T("CP_CARD_JACK")
    elseif card_number == 12 then
        cardName = _T("CP_CARD_QUEEN")
    elseif card_number == 0 then
        cardName = _T("CP_CARD_KING")
    else
        cardName = tostring(card_number)
    end

    if card_index >= 1 and card_index <= 13 then
        cardSuit = _T("CP_CARD_CLUBS")
    elseif card_index >= 14 and card_index <= 26 then
        cardSuit = _T("CP_CARD_DIAMONDS")
    elseif card_index >= 27 and card_index <= 39 then
        cardSuit = _T("CP_CARD_HEARTS")
    elseif card_index >= 40 and card_index <= 52 then
        cardSuit = _T("CP_CARD_SPADES")
    end

    return string.format("%s of %s", cardName, cardSuit)
end

---@param player_id integer
---@param players_current_table integer
---@param card_one integer
---@param card_two integer
---@param card_three integer
function CasinoPacino:SetPokerCards(player_id, players_current_table, card_one, card_two, card_three)
    local three_card_poker_cards            = GetScriptGlobalOrLocal("three_card_poker_cards")
    local three_card_poker_current_deck     = GetScriptGlobalOrLocal("three_card_poker_current_deck")
    local three_card_poker_deck_size        = GetScriptGlobalOrLocal("three_card_poker_deck_size")
    local three_card_poker_anti_cheat       = GetScriptGlobalOrLocal("three_card_poker_anti_cheat")
    local three_card_poker_anti_cheat_deck  = GetScriptGlobalOrLocal("three_card_poker_anti_cheat_deck")

    locals.set_int("three_card_poker", (three_card_poker_cards) + (three_card_poker_current_deck) + (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (1) + (player_id * 3), card_one)
    locals.set_int("three_card_poker", (three_card_poker_anti_cheat) + (three_card_poker_anti_cheat_deck) + (1) + (1 + (players_current_table * three_card_poker_deck_size)) + (1) + (player_id * 3), card_one)
    locals.set_int("three_card_poker", (three_card_poker_cards) + (three_card_poker_current_deck) + (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (2) + (player_id * 3), card_two)
    locals.set_int("three_card_poker", (three_card_poker_anti_cheat) + (three_card_poker_anti_cheat_deck) + (1) + (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (player_id * 3), card_two)
    locals.set_int("three_card_poker", (three_card_poker_cards) + (three_card_poker_current_deck) + (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (3) + (player_id * 3), card_three)
    locals.set_int("three_card_poker", (three_card_poker_anti_cheat) + (three_card_poker_anti_cheat_deck) + (1) + (1 + (players_current_table * three_card_poker_deck_size)) + (3) + (player_id * 3), card_three)
end

function CasinoPacino:ForceDealerBust()
    script.run_in_fiber(function(script)
        local player_id                     = Self:GetPlayerID()
        local blackjack_cards               = GetScriptGlobalOrLocal("blackjack_cards")
        local blackjack_decks               = GetScriptGlobalOrLocal("blackjack_decks")
        local blackjack_table_players       = GetScriptGlobalOrLocal("blackjack_table_players")
        local blackjack_table_players_size  = GetScriptGlobalOrLocal("blackjack_table_players_size")

        while (
            (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("blackjack", -1, 0) ~= player_id) and
            (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("blackjack", 0, 0) ~= player_id) and
            (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("blackjack", 1, 0) ~= player_id) and
            (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("blackjack", 2, 0) ~= player_id) and
            (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("blackjack", 3, 0) ~= player_id)
        ) do
            network.force_script_host("blackjack")
            Toast:ShowMessage("CasinoPacino", _T("CP_BLACKJACK_SCRIPT_CONTROL")) --If you see this spammed, someone is fighting you for control.
            script:yield()
        end

        local blackjack_table = locals.get_int("blackjack", blackjack_table_players + 1 + (player_id * blackjack_table_players_size) + 4) --The Player's current table he is sitting at.
        if blackjack_table ~= -1 then
            locals.set_int("blackjack", blackjack_cards + blackjack_decks + 1 + (blackjack_table * 13) + 1, 11 )
            locals.set_int("blackjack", blackjack_cards + blackjack_decks + 1 + (blackjack_table * 13) + 2, 12 )
            locals.set_int("blackjack", blackjack_cards + blackjack_decks + 1 + (blackjack_table * 13) + 3, 13 )
            locals.set_int("blackjack", blackjack_cards + blackjack_decks + 1 + (blackjack_table * 13) + 12, 3 )
        end
    end)
end

function CasinoPacino:ForcePokerCards()
    local player_id = Self:GetPlayerID()
    if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("three_card_poker")) ~= 0 then
        while (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", -1, 0) ~= player_id)
        and (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 0, 0) ~= player_id)
        and (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 1, 0) ~= player_id)
        and( NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 2, 0) ~= player_id)
        and (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 3, 0) ~= player_id) do
            network.force_script_host("three_card_poker")
            Toast:ShowMessage("CasinoPacino", _T("CP_POKER_SCRIPT_CONTROL"))
            sleep(500)
        end

        local three_card_poker_table        = GetScriptGlobalOrLocal("three_card_poker_table")
        local three_card_poker_table_size   = GetScriptGlobalOrLocal("three_card_poker_table_size")
        local three_card_poker_cards        = GetScriptGlobalOrLocal("three_card_poker_cards")
        local three_card_poker_current_deck = GetScriptGlobalOrLocal("three_card_poker_current_deck")
        local three_card_poker_deck_size    = GetScriptGlobalOrLocal("three_card_poker_deck_size")
        local players_current_table         = locals.get_int("three_card_poker", three_card_poker_table + 1 + (player_id * three_card_poker_table_size) + 2 )

        if (players_current_table ~= -1) then -- If the player is sitting at a poker table
            local player_0_card_1 = locals.get_int("three_card_poker", (three_card_poker_cards) + (three_card_poker_current_deck) + (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (1) + (0 * 3))
            local player_0_card_2 = locals.get_int("three_card_poker", (three_card_poker_cards) + (three_card_poker_current_deck) + (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (2) + (0 * 3))
            local player_0_card_3 = locals.get_int("three_card_poker", (three_card_poker_cards) + (three_card_poker_current_deck) + (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (3) + (0 * 3))

            if (player_0_card_1 ~= 50) or (player_0_card_2 ~= 51) or (player_0_card_3 ~= 52) then
                local total_players = 0

                for player_iter = 0, 31, 1 do
                    local player_table = locals.get_int("three_card_poker", three_card_poker_table + 1 + (player_iter * three_card_poker_table_size) + 2)

                    if (player_iter ~= player_id) and (player_table == players_current_table) then
                        total_players = total_players + 1
                    end
                end

                for playing_player_iter = 0, total_players, 1 do
                    self:SetPokerCards(playing_player_iter, players_current_table, 50, 51, 52)
                end

                if GVars.set_dealers_poker_cards then
                    self:SetPokerCards(total_players + 1, players_current_table, 1, 8, 22)
                end
            end
        end
    end
end

function CasinoPacino:ForceRouletteWheel()
    local player_id = Self:GetPlayerID()
    local roulette_master_table = GetScriptGlobalOrLocal("roulette_master_table")
    local roulette_outcomes_table = GetScriptGlobalOrLocal("roulette_outcomes_table")
    local roulette_ball_table = GetScriptGlobalOrLocal("roulette_ball_table")
    if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("casinoroulette")) ~= 0 then
        while NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", -1, 0) ~= player_id
            and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 0, 0) ~= player_id
            and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 1, 0) ~= player_id
            and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 2, 0) ~= player_id
            and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 3, 0) ~= player_id do
            network.force_script_host("casinoroulette")
            Toast:ShowMessage("CasinoPacino", _T("CP_ROULETTE_SCRIPT_CONTROL")) --If you see this spammed, someone if fighting you for control.
            sleep(500)
        end

        for tabler_iter = 0, 6, 1 do
            locals.set_int("casinoroulette", (roulette_master_table) + (roulette_outcomes_table) + (roulette_ball_table) + (tabler_iter), 18)
        end
    end
end

function CasinoPacino:RigSlotMachine(enabled)
    if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("casino_slots")) ~= 0 then
        local needs_run = false
        local slots_random_results_table = GetScriptGlobalOrLocal("slots_random_result_table")

        for slots_iter = 3, 196, 1 do
            if slots_iter ~= 67 and slots_iter ~= 132 then
                if locals.get_int("casino_slots", (slots_random_results_table) + (slots_iter)) ~= 6 then
                    needs_run = true
                end
            end
        end

        if needs_run then
            for slots_iter = 3, 196, 1 do
                if slots_iter ~= 67 and slots_iter ~= 132 then
                    local slot_result = 6
                    if not enabled then
                        math.randomseed(os.time() + slots_iter)
                        slot_result = math.random(0, 7)
                    end
                    locals.set_int("casino_slots", (slots_random_results_table) + (slots_iter), slot_result)
                end
            end
        end
    end
end

function CasinoPacino:AutoPlaySlots()
    local slots_slot_machine_state = GetScriptGlobalOrLocal("slots_slot_machine_state")
    local slotstate = locals.get_int("casino_slots", slots_slot_machine_state)
    local autoplay_chips_cap = 0
    local autoplay_cap = false

    if slotstate & (1 << 0) == 1 then --The user is sitting at a slot machine.
        local chips = stats.get_int('MPX_CASINO_CHIPS')
        local chip_cap = autoplay_chips_cap
        if (autoplay_cap and chips < chip_cap) or not autoplay_cap then
            if (slotstate & (1 << 24) == 0) then --The slot machine is not currently spinning.
                yield() -- Wait for the previous spin to clean up, if we just came from a spin.
                slotstate = slotstate | (1 << 3) -- Bitwise set the 3rd bit (begin playing)
                locals.set_int("casino_slots", slots_slot_machine_state, slotstate)
                sleep(500) -- If we rewrite the begin playing bit again, the machine will get stuck.
            end
        end
    end
end

function CasinoPacino:SetCooldownString()
    local cooldown_time             = tunables.get_int("VC_CASINO_CHIP_MAX_WIN_LOSS_COOLDOWN")
    local time_delta                = os.time() - stats.get_int("MPPLY_CASINO_CHIPS_WONTIM")
    local minutes_left              = (cooldown_time - time_delta) / 60
    local chipswon_gd               = stats.get_int("MPPLY_CASINO_CHIPS_WON_GD")
    local max_chip_wins             = tunables.get_int("VC_CASINO_CHIP_MAX_WIN_DAILY")
    self.casino_cooldown_update_str = chipswon_gd >= max_chip_wins
    and string.format(_T("CP_COOLDOWN_BYPASS_STATUS_FORMAT"), minutes_left) or _T("CP_COOLDOWN_BYPASS_STATUS_OFF")
end

---@return string
function CasinoPacino:GetCooldownString()
    return self.casino_cooldown_update_str
end

function CasinoPacino:SetBlackjackString()
    if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("blackjack")) ~= 0 then
        local dealers_card                  = 0
        local blackjack_cards               = GetScriptGlobalOrLocal("blackjack_cards")
        local blackjack_decks               = GetScriptGlobalOrLocal("blackjack_decks")
        local blackjack_table_players       = GetScriptGlobalOrLocal("blackjack_table_players")
        local blackjack_table_players_size  = GetScriptGlobalOrLocal("blackjack_table_players_size")
        local blackjack_table               = locals.get_int("blackjack", blackjack_table_players + 1 + (Self:GetPlayerID() * blackjack_table_players_size) + 4)

        if blackjack_table ~= -1 then
            dealers_card = locals.get_int("blackjack", blackjack_cards + blackjack_decks + 1 + (blackjack_table * 13) + 1)
            self.dealers_card_str = self:GetCardNameFromIndex(dealers_card)
        else
            self.dealers_card_str = _T("CP_NOT_PLAYING_BLACKJACK")
        end
    else
        self.dealers_card_str = _T("CP_NOT_IN_CASINO")
    end
end

function CasinoPacino:BypassCooldown()
    stats.set_int("MPPLY_CASINO_CHIPS_WON_GD", 0)
    stats.set_int("MPPLY_CASINO_CHIPS_WONTIM", 0)
    stats.set_int("MPPLY_CASINO_GMBLNG_GD", 0)
    stats.set_int("MPPLY_CASINO_BAN_TIME", 0)
    stats.set_int("MPPLY_CASINO_CHIPS_PURTIM", 0)
    stats.set_int("MPPLY_CASINO_CHIPS_PUR_GD", 0)
    stats.set_int("MPPLY_CASINO_CHIPS_SOLD", 0)
    stats.set_int("MPPLY_CASINO_CHIPS_SELTIM", 0)
end

---@return string
function CasinoPacino:GetBlackjackString()
    return self.dealers_card_str
end

function CasinoPacino:Start()
    if (not self:CanAccess()) then
        return
    end

    self:SetCooldownString()
    self:SetBlackjackString()

    if GVars.bypass_casino_bans then
        self:BypassCooldown()
    end

    if GVars.force_poker_cards then
        self:ForcePokerCards()
    end

    if GVars.force_roulette_wheel then
        self:ForceRouletteWheel()
    end

    if GVars.rig_slot_machine then
        self:RigSlotMachine(true)
    end

end

function CasinoPacino:Reset()
    --
end

return CasinoPacino