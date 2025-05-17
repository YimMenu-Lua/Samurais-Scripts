---@diagnostic disable

function DunkUI()
    if Game.IsOnline() then
        if SS.IsUpToDate() then
            ImGui.BeginTabBar("Dunk Pacino")
            if ImGui.BeginTabItem(_T("CP_GAMBLING_TXT_")) then
                bypass_casino_bans, bcbUsed = ImGui.Checkbox(_T("CP_BYPASSCD_CP_"), bypass_casino_bans)
                if bcbUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("bypass_casino_bans", bypass_casino_bans)
                end
                if not bypass_casino_bans then
                    UI.Tooltip(_T("CP_BYPASSCD_WARN_"), "#FFCC00")
                end

                ImGui.Spacing()
                ImGui.Text(_T("CP_COOLDOWN_STATUS_"))
                ImGui.SameLine()
                ImGui.BulletText(casino_cooldown_update_str)

                ImGui.Spacing()
                ImGui.SeparatorText("Poker")
                force_poker_cards, fpcUsed = ImGui.Checkbox(_T("CP_FORCE_POKER_RF_CB_"), force_poker_cards)
                if fpcUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("force_poker_cards", force_poker_cards)
                end

                set_dealers_poker_cards, sdpcUsed = ImGui.Checkbox(_T("CP_FORCE_BADBEAT_CB_"),
                    set_dealers_poker_cards)
                if sdpcUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("set_dealers_poker_cards", set_dealers_poker_cards)
                end

                ImGui.Spacing()
                ImGui.SeparatorText("Blackjack")
                ImGui.Spacing()
                ImGui.BulletText(_T("CP_DEALER_FACEDOWN_TXT_"))
                ImGui.SameLine()
                ImGui
                    .Text(dealers_card_str)
                ImGui
                    .Spacing()
                if ImGui.Button(_T("CP_DEALER_BUST_BTN_")) then
                    UI.WidgetSound("Select")
                    script.run_in_fiber(function(script)
                        local player_id = PLAYER.PLAYER_ID()
                        while (
                            (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("blackjack", -1, 0) ~= player_id) and
                            (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("blackjack", 0, 0) ~= player_id) and
                            (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("blackjack", 1, 0) ~= player_id) and
                            (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("blackjack", 2, 0) ~= player_id) and
                            (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("blackjack", 3, 0) ~= player_id)
                        ) do
                            network.force_script_host("blackjack")
                            YimToast:ShowMessage(
                                "CasinoPacino",
                                "Taking control of the blackjack script..."
                            ) --If you see this spammed, someone is fighting you for control.
                            script:yield()
                        end

                        local blackjack_table = locals.get_int(
                            "blackjack",
                            blackjack_table_players + 1 + (player_id * blackjack_table_players_size) + 4
                        ) --The Player's current table he is sitting at.
                        if blackjack_table ~= -1 then
                            locals.set_int(
                                "blackjack",
                                blackjack_cards + blackjack_decks + 1 + (blackjack_table * 13) + 1,
                                11
                            )
                            locals.set_int(
                                "blackjack",
                                blackjack_cards + blackjack_decks + 1 + (blackjack_table * 13) + 2,
                                12
                            )
                            locals.set_int(
                                "blackjack",
                                blackjack_cards + blackjack_decks + 1 + (blackjack_table * 13) + 3,
                                13
                            )
                            locals.set_int(
                                "blackjack",
                                blackjack_cards + blackjack_decks + 1 + (blackjack_table * 13) + 12,
                                3
                            )
                        end
                    end)
                end

                ImGui.Spacing()
                ImGui.SeparatorText("Roulette")
                force_roulette_wheel, frwUsed = ImGui.Checkbox(_T("CP_FORCE_ROULETTE_CB_"),
                    force_roulette_wheel)
                if frwUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("force_roulette_wheel", force_roulette_wheel)
                end

                ImGui.Spacing()
                ImGui.SeparatorText("Slot Machines")
                rig_slot_machine, rsmUsed = ImGui.Checkbox(_T("CP_RIG_SLOTS_CB_"), rig_slot_machine)
                if rsmUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("rig_slot_machine", rig_slot_machine)
                end

                autoplay_slots, apsUsed = ImGui.Checkbox(_T("CP_AUTOPLAY_SLOTS_CB_"), autoplay_slots)
                ImGui.SameLine()
                if apsUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("autoplay_slots", autoplay_slots)
                end
                if autoplay_slots then
                    autoplay_cap, apcapUsed = ImGui.Checkbox(_T("CP_AUTOPLAY_CAP_CB_"), autoplay_cap)
                    ImGui
                        .SameLine()
                    if apcapUsed then
                        UI.WidgetSound("Nav2")
                        CFG:SaveItem("autoplay_cap", autoplay_cap)
                    end
                    if autoplay_cap then
                        ImGui.PushItemWidth(200)
                        autoplay_chips_cap, chipsCapUsed = ImGui.InputInt("##chips_cap", autoplay_chips_cap, 1000, 100000,
                            ImGuiInputTextFlags.CharsDecimal)
                        ImGui.PopItemWidth()
                        if chipsCapUsed then
                            UI.WidgetSound("Nav2")
                            CFG:SaveItem("autoplay_chips_cap", autoplay_chips_cap)
                        end
                    end
                end

                ImGui.Spacing()
                ImGui.SeparatorText("Lucky Wheel")
                if ImGui.Button(_T("CP_PODIUM_VEH_BTN_")) then
                    if script.is_active("casino_lucky_wheel") then
                        UI.WidgetSound("Select")
                        locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 18)
                        locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
                    else
                        UI.WidgetSound("Error")
                    end
                end

                ImGui.SameLine()
                if ImGui.Button(_T("CP_MYSTERY_PRIZE_BTN_")) then
                    if script.is_active("casino_lucky_wheel") then
                        UI.WidgetSound("Select")
                        locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 11)
                        locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
                    else
                        UI.WidgetSound("Error")
                    end
                end

                ImGui.SameLine()
                if ImGui.Button(_T("CP_50K_BTN_")) then
                    if script.is_active("casino_lucky_wheel") then
                        UI.WidgetSound("Select")
                        locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 19)
                        locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
                    else
                        UI.WidgetSound("Error")
                    end
                end

                if ImGui.Button(_T("CP_25K_BTN_")) then
                    if script.is_active("casino_lucky_wheel") then
                        UI.WidgetSound("Select")
                        locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 15)
                        locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
                    else
                        UI.WidgetSound("Error")
                    end
                end

                ImGui.SameLine()
                ImGui.Dummy(6, 1)
                ImGui.SameLine()
                if ImGui.Button(_T("CP_15K_BTN_")) then
                    if script.is_active("casino_lucky_wheel") then
                        UI.WidgetSound("Select")
                        locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 17)
                        locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
                    else
                        UI.WidgetSound("Error")
                    end
                end

                ImGui.SameLine()
                ImGui.Dummy(21, 1)
                ImGui.SameLine()
                if ImGui.Button(_T("CP_DISCOUNT_BTN_")) then
                    if script.is_active("casino_lucky_wheel") then
                        UI.WidgetSound("Select")
                        locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 4)
                        locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
                    else
                        UI.WidgetSound("Error")
                    end
                end

                if ImGui.Button(_T("CP_CLOTHING_BTN_")) then
                    if script.is_active("casino_lucky_wheel") then
                        UI.WidgetSound("Select")
                        locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 8)
                        locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
                    else
                        UI.WidgetSound("Error")
                    end
                end
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Casino Heist") then
                ImGui.PushItemWidth(165)
                new_approach, approach_clicked = ImGui.Combo(
                    _T("CP_HEIST_APPROACH_TXT_"),
                    casino_heist_approach,
                    { "Unselected", "Silent & Sneaky", "The Big Con", "Aggressive" },
                    4
                )
                
                if approach_clicked then
                    stats.set_int("MPX_H3OPT_APPROACH", new_approach)
                end

                ImGui.SameLine()
                ImGui.Dummy(24, 0)
                ImGui.SameLine()
                local new_target, target_clicked = ImGui.Combo(
                    _T("CP_HEIST_TARGET_TXT_"),
                    casino_heist_target,
                    { "Money", "Gold", "Art", "Diamonds" },
                    4
                )

                if target_clicked then
                    stats.set_int("MPX_H3OPT_TARGET", new_target)
                end

                local new_last_approach, last_approach_clicked = ImGui.Combo(
                    _T("CP_HEIST_LAST_APPROACH_TXT_"),
                    casino_heist_last_approach,
                    { "Unselected", "Silent & Sneaky", "The Big Con", "Aggressive" },
                    4
                )
                if last_approach_clicked then
                    stats.set_int("MPX_H3_LAST_APPROACH", new_last_approach)
                end

                ImGui.SameLine()
                local new_hard_approach, hard_approach_clicked = ImGui.Combo(
                    _T("CP_HEIST_HARD_APPROACH_TXT_"),
                    casino_heist_hard,
                    { "Unselected", "Silent & Sneaky", "The Big Con", "Aggressive" },
                    4
                )
                if hard_approach_clicked then
                    stats.set_int("MPX_H3_HARD_APPROACH", new_hard_approach)
                end
                ImGui.PopItemWidth()

                ImGui.Spacing()
                ImGui.PushItemWidth(165)
                local new_gunman, gunman_clicked = ImGui.Combo(
                    _T("CP_HEIST_GUNMAN_TXT_"),
                    casino_heist_gunman,
                    { "Unselected", "Karl Abolaji", "Gustavo Mota", "Charlie Reed", "Chester McCoy", "Patrick McReary" },
                    6
                )
                if gunman_clicked then
                    stats.set_int("MPX_H3OPT_CREWWEAP", new_gunman)
                end
                if casino_heist_gunman == 1 then --Karl Abolaji
                    ImGui.SameLine()
                    ImGui.Dummy(31, 1)
                    ImGui.SameLine()
                    local karl_gun_list = {
                        { '##1", "##2' },
                        { "Micro SMG Loadout", "Machine Pistol Loadout" },
                        { "Micro SMG Loadout", "Shotgun Loadout" },
                        { "Shotgun Loadout", "Revolver Loadout" } 
                    }
                    local new_weapons, weapons_clicked = ImGui.Combo(
                        _T("CP_HEIST_WEAPONS_TXT_"),
                        casino_heist_weapons,
                        karl_gun_list[casino_heist_approach + 1],
                        2
                    )
                    if weapons_clicked then
                        stats.set_int("MPX_H3OPT_WEAPS", new_weapons)
                    end
                elseif casino_heist_gunman == 2 then --Gustavo Fring
                    ImGui.SameLine()
                    ImGui.Dummy(31, 1)
                    ImGui.SameLine()
                    local new_weapons, weapons_clicked = ImGui.Combo(
                        _T("CP_HEIST_WEAPONS_TXT_"),
                        casino_heist_weapons,
                        { "Rifle Loadout", "Shotgun Loadout" },
                        2
                    )
                    if weapons_clicked then
                        stats.set_int("MPX_H3OPT_WEAPS", new_weapons)
                    end
                elseif casino_heist_gunman == 3 then --Charlie Reed
                    ImGui.SameLine()
                    ImGui.Dummy(31, 1)
                    ImGui.SameLine()
                    local charlie_gun_list = {
                        { '##1", "##2' },
                        { "SMG Loadout", "Shotgun Loadout" },
                        { "Machine Pistol Loadout", "Shotgun Loadout" },
                        { "SMG Loadout", "Shotgun Loadout" }
                    }
                    local new_weapons, weapons_clicked = ImGui.Combo(
                    _T("CP_HEIST_WEAPONS_TXT_"),
                        casino_heist_weapons,
                        charlie_gun_list[casino_heist_approach + 1],
                        2
                    )
                    if weapons_clicked then
                        stats.set_int("MPX_H3OPT_WEAPS", new_weapons)
                    end
                elseif casino_heist_gunman == 4 then --Chester McCoy
                    ImGui.SameLine()
                    ImGui.Dummy(31, 1)
                    ImGui.SameLine()
                    local chester_gun_list = {
                        { '##1", "##2' },
                        { "MK II Shotgun Loadout", "MK II Rifle Loadout" },
                        { "MK II SMG Loadout", "MK II Rifle Loadout" },
                        { "MK II Shotgun Loadout", "MK II Rifle Loadout" }
                    }
                    local new_weapons, weapons_clicked = ImGui.Combo(
                        _T("CP_HEIST_WEAPONS_TXT_"),
                        casino_heist_weapons,
                        chester_gun_list[casino_heist_approach + 1],
                        2
                    )
                    if weapons_clicked then
                        stats.set_int("MPX_H3OPT_WEAPS", new_weapons)
                    end
                elseif casino_heist_gunman == 5 then --Laddie Paddie Sadie Enweird
                    ImGui.SameLine()
                    ImGui.Dummy(31, 1)
                    ImGui.SameLine()
                    local laddie_paddie_gun_list = {
                        { '##1", "##2' },
                        { "Combat PDW Loadout", "Rifle Loadout" },
                        { "Shotgun Loadout", "Rifle Loadout" },
                        { "Shotgun Loadout", "Combat MG Loadout" }
                    }
                    local new_weapons, weapons_clicked = ImGui.Combo(
                        _T("CP_HEIST_WEAPONS_TXT_"),
                        casino_heist_weapons,
                        laddie_paddie_gun_list[casino_heist_approach + 1],
                        2
                    )
                    if weapons_clicked then
                        stats.set_int("MPX_H3OPT_WEAPS", new_weapons)
                    end
                end

                local new_driver, driver_clicked = ImGui.Combo(
                    _T("CP_HEIST_DRIVER_TXT_"),
                    casino_heist_driver,
                    {
                        "Unselected",
                        "Karim Deniz",
                        "Taliana Martinez",
                        "Eddie Toh",
                        "Zach Nelson",
                        "Chester McCoy"
                    },
                    6
                )
                if driver_clicked then
                    stats.set_int("MPX_H3OPT_CREWDRIVER", new_driver)
                end

                if casino_heist_driver == 1 then --Karim Deniz
                    ImGui.SameLine()
                    ImGui.Dummy(50, 1)
                    ImGui.SameLine()
                    local new_car, car_clicked = ImGui.Combo(
                        _T("CP_HEIST_GETAWAY_VEHS_TXT_"),
                        casino_heist_cars,
                        {
                            "Issi Classic",
                            "Asbo",
                            "Kanjo",
                            "Sentinel Classic"
                        },
                        4
                    )
                    if car_clicked then
                        stats.set_int("MPX_H3OPT_VEHS", new_car)
                    end
                elseif casino_heist_driver == 2 then --Taliana Martinez
                    ImGui.SameLine()
                    ImGui.Dummy(50, 1)
                    ImGui.SameLine()
                    local new_car, car_clicked = ImGui.Combo(
                        _T("CP_HEIST_GETAWAY_VEHS_TXT_"),
                        casino_heist_cars,
                        {
                            "Retinue MK II",
                            "Drift Yosemite",
                            "Sugoi",
                            "Jugular"
                        },
                        4
                    )
                    if car_clicked then
                        stats.set_int("MPX_H3OPT_VEHS", new_car)
                    end
                elseif casino_heist_driver == 3 then --Eddie Toh
                    ImGui.SameLine()
                    ImGui.Dummy(50, 1)
                    ImGui.SameLine()
                    local new_car, car_clicked = ImGui.Combo(
                        _T("CP_HEIST_GETAWAY_VEHS_TXT_"),
                        casino_heist_cars,
                        {
                            "Sultan Classic",
                            "Guantlet Classic",
                            "Ellie",
                            "Komoda"
                        },
                        4
                    )
                    if car_clicked then
                        stats.set_int("MPX_H3OPT_VEHS", new_car)
                    end
                elseif casino_heist_driver == 4 then --Zach Nelson
                    ImGui.SameLine()
                    ImGui.Dummy(50, 1)
                    ImGui.SameLine()
                    local new_car, car_clicked = ImGui.Combo(
                        _T("CP_HEIST_GETAWAY_VEHS_TXT_"),
                        casino_heist_cars,
                        {
                            "Manchez",
                            "Stryder",
                            "Defiler",
                            "Lectro"
                        },
                        4
                    )
                    if car_clicked then
                        stats.set_int("MPX_H3OPT_VEHS", new_car)
                    end
                elseif casino_heist_driver == 5 then --Chester McCoy
                    ImGui.SameLine()
                    ImGui.Dummy(50, 1)
                    ImGui.SameLine()
                    local new_car, car_clicked = ImGui.Combo(
                        _T("CP_HEIST_GETAWAY_VEHS_TXT_"),
                        casino_heist_cars,
                        {
                            "Zhaba",
                            "Vagrant",
                            "Outlaw",
                            "Everon"
                        },
                        4
                    )
                    if car_clicked then
                        stats.set_int("MPX_H3OPT_VEHS", new_car)
                    end
                end

                local new_hacker, hacker_clicked = ImGui.Combo(
                    _T("CP_HEIST_HACKER_TXT_"),
                    casino_heist_hacker,
                    {
                        "Unselected",
                        "Rickie Lukens",
                        "Christian Feltz",
                        "Yohan Blair",
                        "Avi Schwartzman",
                        "Page Harris"
                    },
                    6
                )
                if hacker_clicked then
                    stats.set_int("MPX_H3OPT_CREWHACKER", new_hacker)
                end

                local new_masks, masks_clicked = ImGui.Combo(
                    _T("CP_HEIST_MASKS_TXT_"),
                    casino_heist_masks,
                    { 
                        "Unselected",
                        "Geometric Set",
                        "Hunter Set",
                        "Oni Half Mask Set",
                        "Emoji Set",
                        "Ornate Skull Set",
                        "Lucky Fruit Set",
                        "Gurilla Set",
                        "Clown Set",
                        "Animal Set",
                        "Riot Set",
                        "Oni Set",
                        "Hockey Set"
                    },
                    13
                )
                if masks_clicked then
                    stats.set_int("MPX_H3OPT_MASKS", new_masks)
                end

                heist_cart_autograb, hcagUsed = ImGui.Checkbox(_T("CP_HEIST_AUTOGRAB_"), heist_cart_autograb)
                if hcagUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("heist_cart_autograb", heist_cart_autograb)
                end

                if ImGui.Button(_T("CP_HEIST_UNLOCK_ALL_BTN_")) then
                    UI.WidgetSound("Select")
                    stats.set_int("MPX_H3OPT_ACCESSPOINTS", -1)
                    stats.set_int("MPX_H3OPT_POI", -1)
                    stats.set_int("MPX_H3OPT_BITSET0", -1)
                    stats.set_int("MPX_H3OPT_BITSET1", -1)
                    stats.set_int("MPX_H3OPT_BODYARMORLVL", 3)
                    stats.set_int("MPX_H3OPT_DISRUPTSHIP", 3)
                    stats.set_int("MPX_H3OPT_KEYLEVELS", 2)
                    stats.set_int("MPX_H3_COMPLETEDPOSIX", 0)
                    stats.set_int("MPX_CAS_HEIST_FLOW", -1)
                    stats.set_int("MPPLY_H3_COOLDOWN", 0)
                    stats.set_packed_stat_bool(26969, true) --Unlock High Roller
                end

                if ImGui.Button(_T("CP_HEIST_ZERO_AI_CUTS_BTN_")) then
                    UI.WidgetSound("Select")
                    tunables.set_int("CH_LESTER_CUT", 0)
                    tunables.set_int("HEIST3_PREPBOARD_GUNMEN_KARL_CUT", 0)
                    tunables.set_int("HEIST3_PREPBOARD_GUNMEN_GUSTAVO_CUT", 0)
                    tunables.set_int("HEIST3_PREPBOARD_GUNMEN_CHARLIE_CUT", 0)
                    tunables.set_int("HEIST3_PREPBOARD_GUNMEN_CHESTER_CUT", 0)
                    tunables.set_int("HEIST3_PREPBOARD_GUNMEN_PATRICK_CUT", 0)
                    tunables.set_int("HEIST3_DRIVERS_KARIM_CUT", 0)
                    tunables.set_int("HEIST3_DRIVERS_TALIANA_CUT", 0)
                    tunables.set_int("HEIST3_DRIVERS_EDDIE_CUT", 0)
                    tunables.set_int("HEIST3_DRIVERS_ZACH_CUT", 0)
                    tunables.set_int("HEIST3_DRIVERS_CHESTER_CUT", 0)
                    tunables.set_int("HEIST3_HACKERS_CHRISTIAN_CUT", 0)
                    tunables.set_int("HEIST3_HACKERS_YOHAN_CUT", 0)
                    tunables.set_int("HEIST3_HACKERS_AVI_CUT", 0)
                    tunables.set_int("HEIST3_HACKERS_RICKIE_CUT", 0)
                    tunables.set_int("HEIST3_HACKERS_PAIGE_CUT", 0)
                    tunables.set_int("HEIST3_FINALE_CLEAN_VEHICLE", 0)
                    tunables.set_int("HEIST3_FINALE_DECOY_GUNMAN", 0)
                end

                if ImGui.Button(_T("CP_HEIST_MAX_PLAYER_CUTS_BTN_")) then
                    UI.WidgetSound("Select")
                    for i = 1, 4, 1 do
                        globals.set_int(gb_casino_heist_planning + gb_casino_heist_planning_cut_offset + i, 100)
                    end
                end
                ImGui.EndTabItem()
            end
            ImGui.EndTabBar()
        else
            ImGui.Dummy(1, 5)
            ImGui.Text("Outdated.")
        end
    else
        ImGui.Dummy(1, 5)
        ImGui.Text(_T("GENERIC_UNAVAILABLE_SP_"))
    end
end
