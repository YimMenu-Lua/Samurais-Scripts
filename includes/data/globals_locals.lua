return { -- NOTTE: if a value isn't needed, use a default of the same type (int: 0, string: "", etc.) do not mix types
    --#region YRV3
    tuneables_global = {
        description = "Tuneables",
        file = "tuneables_processing.c",
        LEGACY = {
            value = 262145, -- never changed
            pattern = [[switch \((Global_......?)\.f_....?\)]],
            capture_group = 1
        },
        ENHANCED = {}
    },
    freemode_business_global = {
        description = "Freemode Business Global",
        file = "freemode.c",
        LEGACY = {
            value = 1668000,
            pattern = [[if \(\((Global_.......?)\[\w+0\] != 0 && func_.....?\(\w+0\)\) && \w+2\)]],
            capture_group = 1
        },
        ENHANCED = {}
    },
    personal_vehicle_global = {
        description = "Personal Vehicle Global",
        file = "freemode.c",
        LEGACY = {
            value = 1572094,
            pattern = [[if \(VEHICLE::GET_IS_VEHICLE_ENGINE_RUNNING\((Global_.......?)\)\)]],
            capture_group = 1
        },
        ENHANCED = {}
    },
    business_hub_global_1 = {
        description = "Business Hub Global 1",
        file = "apparcadebusinesshub.c",
        LEGACY = {
            value = 1945779,
            pattern = [[else if \(Global_19.....?\)]], -- returns 2 matches, we want the first
            capture_group = 1
        },
        ENHANCED = {}
    },
    business_hub_global_2 = {
        description = "Business Hub Global 2",
        file = "apparcadebusinesshub.c",
        LEGACY = {
            value = 1965869,
            pattern = [[if \(MISC::IS_STRING_NULL_OR_EMPTY\(\w+\) \|\| (Global_.......?) == -1\)]],
            capture_group = 1
        },
        ENHANCED = {}
    },
    gb_contraband_buy_local_1 = {
        description = "Contraband Buy Local 1",
        file = "gb_contraband_buy.c",
        LEGACY = {
            value = 623,
            pattern = [[switch \((Local_...?)\.f_5\)]],
            capture_group = 1
        },
        ENHANCED = {}
    },
    gb_contraband_buy_local_2 = {
        description = "Contraband Buy Local 2",
        file = "fm_content_cargo.c",
        LEGACY = {
            value = 5973,
            pattern = [[if \(func_..?\(&.*?(Local_[5-7]...?), \w+?\)\)]], -- multiple matches but we need the first
            capture_group = 1
        },
        ENHANCED = {}
    },
    gb_contraband_buy_local_3 = {
        description = "Contraband Buy Local 3",
        file = "fm_content_cargo.c",
        LEGACY = {
            value = 6092,
            pattern = [[if \((Local_[5-9]...?)\.(f_1...?) == 0\)]], -- multiple matches but we need the first
            capture_group = 1,
            offsets = {
                {
                    value = 1180,
                    capture_group = 2
                },
            }
        },
        ENHANCED = {}
    },
    gb_contraband_sell_local = {
        description = "Contraband Sell Local",
        file = "gb_contraband_sell.c",
        LEGACY = {
            value = 565,
            pattern = [[MISC::CLEAR_BIT\(.*?(Local_...?)\.f_1\), .*?Param0]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    gb_biker_contraband_sell_local = {
        description = "Biker Contraband Sell Local",
        file = "gb_biker_contraband_sell.c",
        LEGACY = {
            value = 727,
            pattern = [[else if \(.*?!func_.*?\(1\) && .*?(Local_...?)(\.f_...?) > 0\)]],
            capture_group = 1,
            offsets = {
                {
                    value = 122,
                    capture_group = 2
                },
            }
        },
        ENHANCED = {}
    },
    gb_smuggler_sell_air_local_1 = {
        description = "Hangar Sell Local 1 (air)",
        file = "gb_smuggler.c",
        LEGACY = {
            value = 1987,
            pattern = [[while \(bVar0 < func_..?\(func_....?\(\), func_..?\(\), (Local_....?)\(\.f_....?), -1]],
            capture_group = 1,
            offsets = {
                {
                    value = 1035,
                    capture_group = 2
                },
            }
        },
        ENHANCED = {}
    },
    gb_smuggler_sell_air_local_2 = {
        description = "Hangar Sell Local 2 (air)",
        file = "gb_smuggler.c",
        LEGACY = {
            value = 1987,
            pattern = [[if .*?(Local_....?)(\.f_....?) > 0 && func_.*?&.*?Local_....?\.f_....?\), 30000, 0]],
            capture_group = 1,
            offsets = {
                {
                    value = 1078,
                    capture_group = 2
                },
            }
        },
        ENHANCED = {}
    },
    gb_gunrunning_sell_local_1 = {
        description = "Bunker Sell Local 1",
        file = "gb_gunrunning.c",
        LEGACY = {
            value = 1264,
            pattern = [[.*?(Local_1...?)(\.f_...?) = func_.*?\(func_.*?\(\), .*?Local_1...?\.f_...?, .*?Param0, -1\);]],
            capture_group = 1,
            offsets = {
                {
                    value = 774,
                    capture_group = 2
                },
            }
        },
        ENHANCED = {}
    },
    gb_gunrunning_sell_local_2 = {
        description = "Bunker Sell Local 2",
        file = "gb_gunrunning.c",
        LEGACY = {
            value = 1264,
            pattern = [[func_....?\(.*?(Local_....?)(\.f_...?), \w+, "GR_HUD_TOT", \w+, 1, 4, 0, 0, 0, 0, 0, 1, 1, 0, 255, 0\);]],
            capture_group = 1,
            offsets = {
                {
                    value = 816,
                    capture_group = 2
                },
            }
        },
        ENHANCED = {}
    },
    acid_lab_sell_local = {
        description = "Acid Lab Sell Local",
        file = "fm_content_acid_lab_sell.c",
        LEGACY = {
            value = 5708,
            pattern = [[if \(.*?(Local_5...?)(\.f_....?) == 0\)]],
            capture_group = 1,
            offsets = {
                {
                    value = 1339,
                    capture_group = 2
                },
            }
        },
        ENHANCED = {}
    },
    acid_lab_sell_bitset = {
        description = "Acid Lab Sell Generic Bitset",
        file = "fm_content_acid_lab_sell.c",
        LEGACY = {
            value = 5582,
            pattern = [[if \(func_..?\((.*?Local_5...?), \w+\)\)]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    --#endregion

    --#region Casino Pacino
    three_card_poker_table = {
        description = "Three Card Poker Table",
        file = "casino_poker.c",
        LEGACY = {
            value = 769,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    three_card_poker_table_size = {
        description = "Three Card Poker Table Size",
        file = "casino_poker.c",
        LEGACY = {
            value = 9,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    three_card_poker_cards = {
        description = "Three Card Poker Cards",
        file = "casino_poker.c",
        LEGACY = {
            value = 136,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    three_card_poker_current_deck = {
        description = "Three Card Poker Current Deck",
        file = "casino_poker.c",
        LEGACY = {
            value = 168,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    three_card_poker_deck_size = {
        description = "Three Card Poker Deck Size",
        file = "casino_poker.c",
        LEGACY = {
            value = 55,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    three_card_poker_anti_cheat = {
        description = "Three Card Poker Anti Cheat",
        file = "casino_poker.c",
        LEGACY = {
            value = 1058,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    three_card_poker_anti_cheat_deck = {
        description = "Three Card Poker Anti Cheat Deck",
        file = "casino_poker.c",
        LEGACY = {
            value = 856,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    blackjack_table_players = {
        description = "Blackjack Table Players",
        file = "casino_blackjack.c",
        LEGACY = {
            value = 1796,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    blackjack_table_players_size = {
        description = "Blackjack Table Players Size",
        file = "casino_blackjack.c",
        LEGACY = {
            value = 8,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    blackjack_cards = {
        description = "Blackjack Cards",
        file = "casino_blackjack.c",
        LEGACY = {
            value = 136,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    blackjack_decks = {
        description = "Blackjack Decks",
        file = "casino_blackjack.c",
        LEGACY = {
            value = 846,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    roulette_master_table = {
        description = "Roulette Master Table",
        file = "casino_roulette.c",
        LEGACY = {
            value = 144,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    roulette_outcomes_table = {
        description = "Roulette Outcomes Table",
        file = "casino_roulette.c",
        LEGACY = {
            value = 1357,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    roulette_ball_table = {
        description = "Roulette Ball Table",
        file = "casino_roulette.c",
        LEGACY = {
            value = 153,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    slots_random_result_table = {
        description = "Slots Random Results Table",
        file = "casino_slots.c",
        LEGACY = {
            value = 1348,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    slots_slot_machine_state = {
        description = "Slots Slot Machine State",
        file = "casino_slots.c",
        LEGACY = {
            value = 1638,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    prize_wheel_win_state = {
        description = "Prize Wheel Win State",
        file = "casino_prize_wheel.c",
        LEGACY = {
            value = 300,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    prize_wheel_prize = {
        description = "Prize Wheel Prize",
        file = "casino_prize_wheel.c",
        LEGACY = {
            value = 14,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    prize_wheel_prize_state = {
        description = "Prize Wheel Prize State",
        file = "casino_prize_wheel.c",
        LEGACY = {
            value = 45,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    gb_casino_heist_planning = {
        description = "Casino Heist Planning Global",
        file = "gb_casino_heist_planning.c",
        LEGACY = {
            value = 1967717,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    gb_casino_heist_planning_cut_offset = {
        description = "Casino Heist Planning Cut Offset",
        file = "gb_casino_heist_planning.c",
        LEGACY = {
            value = 1497 + 736 + 92,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    fm_mission_controller_cart_grab = {
        description = "FM Mission Controller Cart Grab",
        file = "fm_mission_controller.c",
        LEGACY = {
            value = 10293,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    fm_mission_controller_cart_grab_speed = {
        description = "FM Mission Controller Cart Grab Speed",
        file = "fm_mission_controller.c",
        LEGACY = {
            value = 14,
            pattern = [[TBA]],
            capture_group = 1,
        },
        ENHANCED = {}
    },
    --#endregion
}
