---@diagnostic disable

local function drawCasinoUI()
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 5)

    ImGui.SeparatorText(_T("CP_COOLDOWN_BYPASS"))
    GVars.bypass_casino_bans, _ = GUI:Checkbox(_T("CP_COOLDOWN_BYPASS_ENABLE"), GVars.bypass_casino_bans, { tooltip = _T("CP_COOLDOWN_BYPASS_TOOLTIP"), color = Color("#AA0000") } )
    ImGui.SameLine()
    ImGui.BulletText(_T("CP_COOLDOWN_BYPASS_STATUS"))
    ImGui.SameLine()
    ImGui.Text(CasinoPacino:GetCooldownString())

    ImGui.SeparatorText(_T("CP_POKER_SETTINGS"))
    GVars.force_poker_cards, _ = GUI:Checkbox(_T("CP_POKER_FORCE_ROYAL_FLUSH"), GVars.force_poker_cards)
    GVars.set_dealers_poker_cards, _ = GUI:Checkbox(_T("CP_POKER_FORCE_BAD_BEAT"), GVars.set_dealers_poker_cards)

    ImGui.SeparatorText(_T("CP_BLACKJACK_SETTINGS"))
    ImGui.BulletText(_T("CP_BLACKJACK_DEALER_FACE_DOWN_CARD"))
    ImGui.SameLine()
    ImGui.Text(CasinoPacino:GetBlackjackString())
    if GUI:Button(_T("CP_BLACKJACK_FORCE_DEALER_BUST")) then
        CasinoPacino:ForceDealerBust()
    end

    ImGui.SeparatorText(_T("CP_ROULETTE_SETTINGS"))
    GVars.force_roulette_wheel, _ = GUI:Checkbox(_T("CP_ROULETTE_FORCE_RED_18"), GVars.force_roulette_wheel)

    ImGui.SeparatorText(_T("CP_SLOT_MACHINES_SETTINGS"))
    GVars.rig_slot_machine, _ = GUI:Checkbox(_T("CP_SLOT_MACHINES_RIG"), GVars.rig_slot_machine)
    -- GVars.autoplay_slots, _ = GUI:Checkbox(_T("CP_SLOT_MACHINES_AUTOPLAY"), GVars.autoplay_slots)
    -- if GVars.autoplay_slots then
    --     GVars.cap_slot_machine_chips, _ = GUI:Checkbox(_T("CP_SLOT_MACHINES_CAP_CHIPS"), GVars.cap_slot_machine_chips)
    -- end

    ImGui.SeparatorText(_T("CP_LUCKY_WHEEL_SETTINGS"))
    if GUI:Button(_T("CP_LUCKY_WHEEL_GIVE_VEHICLE")) then
        CasinoPacino:GiveWheelPrize("vehicle")
    end
    ImGui.SameLine()
    if GUI:Button(_T("CP_LUCKY_WHEEL_GIVE_MYSTERY")) then
        CasinoPacino:GiveWheelPrize("mystery")
    end
    
    if GUI:Button(_T("CP_LUCKY_WHEEL_GIVE_CASH")) then
        CasinoPacino:GiveWheelPrize("cash")
    end
    ImGui.SameLine()
    if GUI:Button(_T("CP_LUCKY_WHEEL_GIVE_CHIPS")) then
        CasinoPacino:GiveWheelPrize("chips")
    end
    
    if GUI:Button(_T("CP_LUCKY_WHEEL_GIVE_RP")) then
        CasinoPacino:GiveWheelPrize("rp")
    end
    ImGui.SameLine()
    if GUI:Button(_T("CP_LUCKY_WHEEL_GIVE_DISCOUNT")) then
        CasinoPacino:GiveWheelPrize("discount")
    end
    
    if GUI:Button(_T("CP_LUCKY_WHEEL_GIVE_CLOTHING")) then
        CasinoPacino:GiveWheelPrize("clothing")
    end
    ImGui.SameLine()
    if GUI:Button(_T("CP_LUCKY_WHEEL_GIVE_SURPRISE")) then
        CasinoPacino:GiveWheelPrize("surprise")
    end

    ImGui.PopStyleVar()
end

local function drawCasinoHeistUI()
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 5)

    ImGui.SeparatorText(_T("CP_COOLDOWN_BYPASS"))
    ImGui.PopStyleVar()
end

function CasinoUI()
    if not Game.IsOnline() and not Backend:IsUpToDate() then
        ImGui.Text(_T("OFFLINE_OR_OUTDATED"))
        return
    end

    ImGui.BeginTabBar(_T("CP_CASINO_TAB_BAR"))

    if ImGui.BeginTabItem(_T("CP_CASINO_FEATURES_TAB")) then
        drawCasinoUI()
        ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem(_T("CP_CASINO_HEIST_TAB")) then
        drawCasinoHeistUI()
        ImGui.EndTabItem()
    end
    ImGui.EndTabBar()
end

GUI:GetMainTab():RegisterSubtab("Casino", CasinoUI)