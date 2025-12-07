---@diagnostic disable

local function CasinoUI()
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 10, 10)

    ImGui.SeparatorText(_T("CP_COOLDOWN_BYPASS"))
    GVars.features.dunk.bypass_casino_bans, _ = GUI:Checkbox(_T("CP_COOLDOWN_BYPASS_ENABLE"), 
        GVars.features.dunk.bypass_casino_bans, { 
            tooltip = _T("CP_COOLDOWN_BYPASS_TOOLTIP"), 
            color = Color("#AA0000") 
        })

    ImGui.SameLine()
    ImGui.BulletText(_T("CP_COOLDOWN_BYPASS_STATUS"))
    ImGui.SameLine()
    ImGui.Text(CasinoPacino:GetCooldownString())

    ImGui.SeparatorText(_T("CP_POKER_SETTINGS"))
    GVars.features.dunk.force_poker_cards, _ = GUI:Checkbox(_T("CP_POKER_FORCE_ROYAL_FLUSH"), GVars.features.dunk.force_poker_cards)
    GVars.features.dunk.set_dealers_poker_cards, _ = GUI:Checkbox(_T("CP_POKER_FORCE_BAD_BEAT"), GVars.features.dunk.set_dealers_poker_cards)

    ImGui.SeparatorText(_T("CP_BLACKJACK_SETTINGS"))
    ImGui.BulletText(_T("CP_BLACKJACK_DEALER_FACE_DOWN_CARD"))
    ImGui.SameLine()
    ImGui.Text(CasinoPacino:GetBlackjackString())
    if GUI:Button(_T("CP_BLACKJACK_FORCE_DEALER_BUST")) then
        CasinoPacino:ForceDealerBust()
    end

    ImGui.SeparatorText(_T("CP_ROULETTE_SETTINGS"))
    GVars.features.dunk.force_roulette_wheel, _ = GUI:Checkbox(_T("CP_ROULETTE_FORCE_RED_18"), GVars.features.dunk.force_roulette_wheel)

    ImGui.SeparatorText(_T("CP_SLOT_MACHINES_SETTINGS"))
    GVars.features.dunk.rig_slot_machine, _ = GUI:Checkbox(_T("CP_SLOT_MACHINES_RIG"), GVars.features.dunk.rig_slot_machine)
    -- GVars.features.dunk.autoplay_slots, _ = GUI:Checkbox(_T("CP_SLOT_MACHINES_AUTOPLAY"), GVars.features.dunk.autoplay_slots)
    -- if GVars.features.dunk.autoplay_slots then
    --     GVars.features.dunk.cap_slot_machine_chips, _ = GUI:Checkbox(_T("CP_SLOT_MACHINES_CAP_CHIPS"), GVars.features.dunk.cap_slot_machine_chips)
    -- end

    ImGui.SeparatorText(_T("CP_LUCKY_WHEEL_SETTINGS"))
    if GUI:Button(_T("CP_LUCKY_WHEEL_GIVE_VEHICLE")) then
        CasinoPacino:GiveWheelPrize(eCasinoPrize.VEHICLE)
    end
    
    ImGui.SameLine()
    if GUI:Button(_T("CP_LUCKY_WHEEL_GIVE_MYSTERY")) then
        CasinoPacino:GiveWheelPrize(eCasinoPrize.MYSTERY)
    end
    
    if GUI:Button(_T("CP_LUCKY_WHEEL_GIVE_CASH")) then
        CasinoPacino:GiveWheelPrize(eCasinoPrize.CASH)
    end
    ImGui.SameLine()
    if GUI:Button(_T("CP_LUCKY_WHEEL_GIVE_CHIPS")) then
        CasinoPacino:GiveWheelPrize(eCasinoPrize.CHIPS)
    end
    
    if GUI:Button(_T("CP_LUCKY_WHEEL_GIVE_RP")) then
        CasinoPacino:GiveWheelPrize(eCasinoPrize.RP)
    end

    ImGui.SameLine()
    if GUI:Button(_T("CP_LUCKY_WHEEL_GIVE_DISCOUNT")) then
        CasinoPacino:GiveWheelPrize(eCasinoPrize.DISCOUNT)
    end
    
    if GUI:Button(_T("CP_LUCKY_WHEEL_GIVE_CLOTHING")) then
        CasinoPacino:GiveWheelPrize(eCasinoPrize.CLOSTHING)
    end
    ImGui.SameLine()
    if GUI:Button(_T("CP_LUCKY_WHEEL_GIVE_SURPRISE")) then
        CasinoPacino:GiveWheelPrize(eCasinoPrize.RANDOM)
    end

    ImGui.PopStyleVar()
end

local function drawCasinoHeistUI()
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 5)

    ImGui.SeparatorText(_T("CP_COOLDOWN_BYPASS"))
    ImGui.PopStyleVar()
end

function DrawDunk()
    if (not Game.IsOnline() or not Backend:IsUpToDate()) then
        ImGui.Text(_T("OFFLINE_OR_OUTDATED"))
        return
    end

    ImGui.BeginTabBar(_T("CP_CASINO_TAB_BAR"))

    if ImGui.BeginTabItem(_T("CP_CASINO_FEATURES_TAB")) then
        CasinoUI()
        ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem(_T("CP_CASINO_HEIST_TAB")) then
        drawCasinoHeistUI()
        ImGui.EndTabItem()
    end

    ImGui.EndTabBar()
end

GUI:RegisterNewTab(eTabID.TAB_ONLINE, "Casino Pacino", DrawDunk)
