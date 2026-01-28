-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


return {
	tuneables_global = {
		description = "Tuneables (never changed)",
		file = "tuneables_processing.c",
		LEGACY = {
			value = 262145,
			pattern = [[switch \((Global_\w{6})\.f_\w{4}\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 262145,
			pattern = [[switch \((Global_\w{6})\.f_\w{4}\)]],
			capture_group = 1
		}
	},
	freemode_business_global = {
		description = "Freemode Business Global",
		file = "freemode.c",
		LEGACY = {
			value = 1673807,
			pattern = [[if \(Global_\d{7}\[.*?\] != 0 && func_\w+\(.*?\) && \w+\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1673830,
			pattern =
			[[if \(Global_\d{7}\[PLAYER::PLAYER_ID\(\) /\*883\*/\]\.f_\d{3}\.f_\d{3}\[.*?/\*13\*/\] != HUD_COLOUR_PURE_WHITE && (Global_\d{7})\[.*?\] != 0\)]],
			capture_group = 1
		}
	},
	personal_vehicle_global = {
		description = "Personal Vehicle Global",
		file = "freemode.c",
		LEGACY = {
			value = 1572199,
			pattern = [[if \(VEHICLE::GET_IS_VEHICLE_ENGINE_RUNNING\((Global_\w{7})\)\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1572199,
			pattern = [[if \(VEHICLE::GET_IS_VEHICLE_ENGINE_RUNNING\((Global_\w{7})\)\)]],
			capture_group = 1
		}
	},
	arcade_bhub_global_1 = {
		description = "Arcade Business Hub Global 1",
		file = "apparcadebusinesshub.c",
		LEGACY = {
			value = 1950053,
			pattern = [[else if \(Global_\w{7}\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1950567,
			pattern = [[else if \(Global_\w{7}\)]],
			capture_group = 1
		}
	},
	arcade_bhub_global_2 = {
		description = "Arcade Business Hub Global 2",
		file = "apparcadebusinesshub.c",
		LEGACY = {
			value = 1970093,
			pattern = [[if \(MISC::IS_STRING_NULL_OR_EMPTY\(\w+\) \|\| (Global_\w{7}) ==.*?\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1970664,
			pattern = [[if \(MISC::IS_STRING_NULL_OR_EMPTY\(\w+\) \|\| (Global_\w{7}) ==.*?\)]],
			capture_group = 1
		}
	},
	biker_prod_time_global = {
		description = "Trigger production for all biker businesses.",
		file = "freemode.c",
		LEGACY = {
			value = 1845250,
			pattern = [[(Global_\d{7})\[.*?(.*?)\]\.(f_\d{3}).(f_\d{3})\[.*?/(.*?)\].f_9 = .*?;]],
			capture_group = 1,
			offsets = {
				{
					value = 880,
					capture_group = 2,
					description = "playerID read size."
				},
				{
					value = 260,
					capture_group = 3
				},
				{
					value = 205,
					capture_group = 4
				},
				{
					value = 13,
					capture_group = 5,
					description = "business index read size."
				},
			},
		},
		ENHANCED = {
			value = 1845299,
			pattern = [[(Global_\d{7})\[.*?(.*?)\]\.(f_\d{3}).(f_\d{3})\[.*?/(.*?)\].f_9 = .*?;]],
			capture_group = 1,
			offsets = {
				{
					value = 883,
					capture_group = 2,
					description = "playerID read size."
				},
				{
					value = 260,
					capture_group = 3
				},
				{
					value = 205,
					capture_group = 4
				},
				{
					value = 13,
					capture_group = 5,
					description = "business index read size."
				},
			},
		}
	},
	bhub_prod_time_global = {
		description = "Business Hub time left to produce.",
		file = "freemode.c",
		LEGACY = {
			value = 2708951,
			pattern = [[Global_(\d{7})\[.*?\] = Global_\d{7}\[.*?\] +.*?Global_(\d{7})\.(f_1)\[.*?\] - .*?;]],
			capture_group = 1
		},
		ENHANCED = {
			value = 2709086,
			pattern = [[Global_(\d{7})\[.*?\] = Global_\d{7}\[.*?\] +.*?Global_(\d{7})\.(f_1)\[.*?\] - .*?;]],
			capture_group = 1
		}
	},
	bhub_prod_bool_global = {
		description = "Business Hub some production bool. Flips back after production is triggered.",
		file = "freemode.c",
		LEGACY = {
			value = 2708962,
			pattern = [[Global_(\d{7})\[.*?\] = Global_\d{7}\[.*?\] +.*?Global_(\d{7})\.(f_1)\[.*?\] - .*?;]],
			capture_group = 2,
			offsets = {
				{
					1,
					capture_group = 3,
					description = "some int value indexed by hub slot. can't be bothered -_-"
				}
			}
		},
		ENHANCED = {
			value = 2709097,
			pattern = [[Global_(\d{7})\[.*?\] = Global_\d{7}\[.*?\] +.*?Global_(\d{7})\.(f_1)\[.*?\] - .*?;]],
			capture_group = 2,
			offsets = {
				{
					1,
					capture_group = 3,
					description = "some int value indexed by hub slot. can't be bothered -_-"
				}
			}
		}
	},
	gb_contraband_buy_local_1 = {
		description = "Contraband Buy Local 1",
		file = "gb_contraband_buy.c",
		LEGACY = {
			value = 625,
			pattern = [[switch \(((.*?Local_\d{3}))\.f_5]],
			capture_group = 1
		},
		ENHANCED = {
			value = 627,
			pattern = [[switch \(((.*?Local_\d{3}))\.f_5]],
			capture_group = 1
		}
	},
	gb_contraband_buy_local_2 = {
		description = "Contraband Buy Local 2",
		file = "fm_content_cargo.c",
		LEGACY = {
			value = 5991,
			pattern = [[func_\w+\(&.*?Local_(59..?), \w+\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 5993,
			pattern = [[func_\w+\(&.*?Local_(59..?), \w+\);]],
			capture_group = 1
		}
	},
	gb_contraband_buy_local_3 = {
		description = "Contraband Buy Local 3",
		file = "fm_content_cargo.c",
		LEGACY = {
			value = 6110,
			pattern = [[if \(.*?(Local_\d{4})\.(f_\d{4}) == 0]],
			capture_group = 1,
			offsets = {
				{
					value = 1180,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 6112,
			pattern = [[if \(.*?(Local_\d{4})\.(f_\d{4}) == 0]],
			capture_group = 1,
			offsets = {
				{
					value = 1180,
					capture_group = 2
				}
			}
		}
	},
	gb_contraband_sell_local = {
		description = "Contraband Sell Local",
		file = "gb_contraband_sell.c",
		LEGACY = {
			value = 567,
			pattern = [[MISC::CLEAR_BIT\(&\((.*?Local_\d{3})\.f_\d{1,2}\), \w+0]],
			capture_group = 1
		},
		ENHANCED = {
			value = 569,
			pattern = [[MISC::CLEAR_BIT\(&\((.*?Local_\d{3})\.f_\d{1,2}\), \w+0]],
			capture_group = 1
		}
	},
	gb_biker_contraband_sell_local = {
		description = "Biker Contraband Sell Local",
		file = "gb_biker_contraband_sell.c",
		LEGACY = {
			value = 729,
			pattern = [[else if \(!func_\w+\(.*?\) &&.*?(Local_\d{3})(\.f_\d{3}) > 0\)]],
			capture_group = 1,
			offsets = {
				{
					value = 122,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 731,
			pattern = [[else if \(!func_\w+\(.*?\) &&.*?(Local_\d{3})(\.f_\d{3}) > 0\)]],
			capture_group = 1,
			offsets = {
				{
					value = 122,
					capture_group = 2
				}
			}
		}
	},
	gb_smuggler_sell_air_local_1 = {
		description = "Hangar Sell Local 1 (air)",
		file = "gb_smuggler.c",
		LEGACY = {
			value = 1989,
			pattern =
			[[for \(i = 0; i < func_\w{2}\(func_\w{4}\(\), func_\w{2}\(\), .*?(Local_\d{4})\.(f_\d{4}), -1\); i = i \+ 1\)]],
			capture_group = 1,
			offsets = {
				{
					value = 1035,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 1991,
			pattern =
			[[for \(i = 0; i < func_\w{2}\(func_\w{4}\(\), func_\w{2}\(\), .*?(Local_\d{4})\.(f_\d{4}), -1\); i = i \+ 1\)]],
			capture_group = 1,
			offsets = {
				{
					value = 1035,
					capture_group = 2
				}
			}
		}
	},
	gb_smuggler_sell_air_local_2 = {
		description = "Hangar Sell Local 2 (air)",
		file = "gb_smuggler.c",
		LEGACY = {
			value = 1989,
			pattern = [[if .*?(Local_\d{4})\.(f_\d{4}) > 0 && func_.*?&.*?Local_\d{4}\.f_\d{4}\), 30000, \w+]],
			capture_group = 1,
			offsets = {
				{
					value = 1078,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 1991,
			pattern = [[if .*?(Local_\d{4})\.(f_\d{4}) > 0 && func_.*?&.*?Local_\d{4}\.f_\d{4}\), 30000, \w+]],
			capture_group = 1,
			offsets = {
				{
					value = 1078,
					capture_group = 2
				}
			}
		}
	},
	gb_gunrunning_sell_local_1 = {
		description = "Bunker Sell Local 1",
		file = "gb_gunrunning.c",
		LEGACY = {
			value = 1266,
			pattern = [[Local_1\d{3}\.f_\d{3} = func_\w+\(func_\w+\(\),.*?(Local_1\d{3})\.(f_\d{3}), \w+, -1\);]],
			capture_group = 1,
			offsets = {
				{
					value = 762,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 1268,
			pattern = [[Local_1\d{3}\.f_\d{3} = func_\w+\(func_\w+\(\),.*?(Local_1\d{3})\.(f_\d{3}), \w+, -1\);]],
			capture_group = 1,
			offsets = {
				{
					value = 762,
					capture_group = 2
				}
			}
		}
	},
	gb_gunrunning_sell_local_2 = {
		description = "Amount delivered.",
		file = "gb_gunrunning.c",
		LEGACY = {
			value = 1266,
			pattern = [[func_\w+\((.*?Local_\d{4})(\.f_\d{3}), \w+, "GR_HUD_TOT".*?, 255, 0\);]],
			capture_group = 1,
			offsets = {
				{
					value = 816,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 1268,
			pattern = [[func_\w+\((.*?Local_\d{4})(\.f_\d{3}), \w+, "GR_HUD_TOT".*?, 255, 0\);]],
			capture_group = 1,
			offsets = {
				{
					value = 816,
					capture_group = 2
				}
			}
		}
	},
	gb_gunrunning_sell_local_3 = {
		description = "Remaining delivery vehicles.",
		file = "gb_gunrunning.c",
		LEGACY = {
			value = 1266,
			pattern =
			[[for \(i = 0; i < func_\w+\(func_\w+\(\), func_\w+\(\),.*?(Local_\d{4})(\.f_\d{3}),.*?Local_\d{4}\.f_\d{3}\); i = i \+ 1\)]],
			capture_group = 1,
			offsets = {
				{
					value = 774,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 1268,
			pattern =
			[[for \(i = 0; i < func_\w+\(func_\w+\(\), func_\w+\(\),.*?(Local_\d{4})(\.f_\d{3}),.*?Local_\d{4}\.f_\d{3}\); i = i \+ 1\)]],
			capture_group = 1,
			offsets = {
				{
					value = 774,
					capture_group = 2
				}
			}
		}
	},
	acid_lab_sell_local = {
		description = "Acid Lab Sell Local",
		file = "fm_content_acid_lab_sell.c",
		LEGACY = {
			value = 5723,
			pattern = [[if \((.*?Local_5\d{3})(\.f_\d{4}) == 0\)]],
			capture_group = 1,
			offsets = {
				{
					value = 1339,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 5725,
			pattern = [[if \((.*?Local_5\d{3})(\.f_\d{4}) == 0\)]],
			capture_group = 1,
			offsets = {
				{
					value = 1339,
					capture_group = 2
				}
			}
		}
	},
	acid_lab_sell_bitset = {
		description = "Acid Lab Sell Generic Bitset",
		file = "fm_content_acid_lab_sell.c",
		LEGACY = {
			value = 5597,
			pattern = [[func_\w{3}\(&.?(Local_5\d+), \w+\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 5599,
			pattern = [[func_\w{3}\(&.?(Local_5\d+), \w+\)]],
			capture_group = 1
		}
	},
	three_card_poker_table = {
		description = "Three Card Poker Table Local",
		file = "three_card_poker.c",
		LEGACY = {
			value = 771,
			pattern =
			[[if \((.*?Local_\d{3})\[.*? /\*(\d+)\*/\]\.f_\d+ ==.*?&&.*?Local_\d{3}\[.*?\]\.f_\d+ > 0 \|\| .*?Local_\d{3}\[.*?\]\.f_\d+ > 0\)]],
			capture_group = 1,
			offsets = {
				{
					value = 9,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 773,
			pattern =
			[[if \((.*?Local_\d{3})\[.*? /\*(\d+)\*/\]\.f_\d+ ==.*?&&.*?Local_\d{3}\[.*?\]\.f_\d+ > 0 \|\| .*?Local_\d{3}\[.*?\]\.f_\d+ > 0\)]],
			capture_group = 1,
			offsets = {
				{
					value = 9,
					capture_group = 2
				}
			}
		}
	},
	three_card_poker_cards = {
		description = "Three Card Poker Cards Local",
		file = "three_card_poker.c",
		LEGACY = {
			value = 138,
			pattern =
			[[STREAMING::REQUEST_MODEL\(func_\d+\(.*?(Local_\d{3})(\.f_\d{3})\[.*?\]\.f_\d+\[.*?\], .*?Local_\d{4}\.f_\d+\)\);]],
			capture_group = 1,
			offsets = {
				{
					value = 168,
					capture_group = 2,
					description = "current deck"
				}
			}
		},
		ENHANCED = {
			value = 140,
			pattern =
			[[STREAMING::REQUEST_MODEL\(func_\d+\(.*?(Local_\d{3})(\.f_\d{3})\[.*?\]\.f_\d+\[.*?\], .*?Local_\d{4}\.f_\d+\)\);]],
			capture_group = 1,
			offsets = {
				{
					value = 168,
					capture_group = 2,
					description = "current deck"
				}
			}
		}
	},
	three_card_poker_deck_size = {
		description = "Three Card Poker Deck Size",
		file = "three_card_poker.c",
		LEGACY = {
			value = 55,
			pattern =
			[[if \(!NETWORK::NETWORK_HAS_CONTROL_OF_NETWORK_ID\(.*?Local_\d{3}(\.f_\d{2})\[\w+\(\w+, 0\)\]\)\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 55,
			pattern =
			[[if \(!NETWORK::NETWORK_HAS_CONTROL_OF_NETWORK_ID\(.*?Local_\d{3}(\.f_\d{2})\[\w+\(\w+, 0\)\]\)\)]],
			capture_group = 1
		}
	},
	three_card_poker_anti_cheat = {
		description = "Three Card Poker Anti Cheat",
		file = "three_card_poker.c",
		LEGACY = {
			value = 1060,
			pattern =
			[[if \(.*?(Local_\d{4})(\.f_\d{3})\.f_\d+\[.*?\] !=.*?Local_\d{3}\.f_\d+\[PLAYER::PLAYER_ID\(\) .*?\]\.f_1\[.*?\]\)]],
			capture_group = 1,
			offsets = {
				{
					value = 856,
					capture_group = 2,
					description = "anti cheat deck"
				}
			}
		},
		ENHANCED = {
			value = 1062,
			pattern =
			[[if \(.*?(Local_\d{4})(\.f_\d{3})\.f_\d+\[.*?\] !=.*?Local_\d{3}\.f_\d+\[PLAYER::PLAYER_ID\(\) .*?\]\.f_1\[.*?\]\)]],
			capture_group = 1,
			offsets = {
				{
					value = 856,
					capture_group = 2,
					description = "anti cheat deck"
				}
			}
		}
	},
	blackjack_table_players = {
		description = "Blackjack Table Players Local",
		file = "blackjack.c",
		LEGACY = {
			value = 1798,
			pattern = [[if \(.*?Local_\d{4}\[.*?/\*(\d+)\*/\]\.f_\d+ == \w+ && \w+\(.*?Local_\d{4}\[.*?\], \d+\)\)]],
			capture_group = 2,
			offsets = {
				{
					value = 8,
					capture_group = 1
				}
			}
		},
		ENHANCED = {
			value = 1800,
			pattern = [[if \(.*?Local_\d{4}\[.*?/\*(\d+)\*/\]\.f_\d+ == \w+ && \w+\(.*?Local_\d{4}\[.*?\], \d+\)\)]],
			capture_group = 2,
			offsets = {
				{
					value = 8,
					capture_group = 1
				}
			}
		}
	},
	blackjack_cards = {
		description = "Blackjack Cards Local",
		file = "blackjack.c",
		LEGACY = {
			value = 138,
			pattern =
			[[if \(func_\w+\(.*?(Local_\d{3})(\.f_\d{3})\[.*?\]\) == 10 \|\| func_\d+\(.*?Local_\d{3}\.f_\d{3}\[.*?\]\) == 11\)]],
			capture_group = 1,
			offsets = {
				{
					value = 846,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 140,
			pattern =
			[[if \(func_\w+\(.*?(Local_\d{3})(\.f_\d{3})\[.*?\]\) == 10 \|\| func_\d+\(.*?Local_\d{3}\.f_\d{3}\[.*?\]\) == 11\)]],
			capture_group = 1,
			offsets = {
				{
					value = 846,
					capture_group = 2
				}
			}
		}
	},
	roulette_master_table = {
		description = "Roulette Master Table Local",
		file = "casinoroulette.c",
		LEGACY = {
			value = 146,
			pattern = [[NETWORK::NETWORK_REGISTER_HOST_BROADCAST_VARIABLES\(&\(.*?(Local_\d{3})(\.f_\d{4})\), 295, 0\);]],
			capture_group = 1,
			offsets = {
				{
					value = 1357,
					capture_group = 2,
					description = "roulette outcomes table"
				}
			}
		},
		ENHANCED = {
			value = 148,
			pattern = [[NETWORK::NETWORK_REGISTER_HOST_BROADCAST_VARIABLES\(&\(.*?(Local_\d{3})(\.f_\d{4})\), 295, 0\);]],
			capture_group = 1,
			offsets = {
				{
					value = 1357,
					capture_group = 2,
					description = "roulette outcomes table"
				}
			}
		}
	},
	roulette_ball_table_offset = {
		description = "Roulette Ball Table Offset",
		file = "casinoroulette.c",
		LEGACY = {
			value = 153,
			pattern = [[\w+\.f_1 = \w+->f_\d{4}(\.f_\d{3})\[.*?\];]],
			capture_group = 1
		},
		ENHANCED = {
			value = 153,
			pattern = [[\w+\.f_1 = \w+->f_\d{4}(\.f_\d{3})\[.*?\];]],
			capture_group = 1
		}
	},
	slots_random_result_table = {
		description = "Slots Random Results Table Local",
		file = "casino_slots.c",
		LEGACY = {
			value = 1372,
			pattern =
			[[\w+ = func_\d+\(.*?(Local_\d{4})\.f_1\[.*?\]\[.*?Local_\d+\[0\]\], .*?Local_\d+?\.f_1\[.*?\]\[.*?Local_\d+\[1\]\], .*?Local_\d{4}\.f_1\[.*?\]\[.*?Local_\d+\[2\]\]\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1374,
			pattern =
			[[\w+ = func_\d+\(.*?(Local_\d{4})\.f_1\[.*?\]\[.*?Local_\d+\[0\]\], .*?Local_\d+?\.f_1\[.*?\]\[.*?Local_\d+\[1\]\], .*?Local_\d{4}\.f_1\[.*?\]\[.*?Local_\d+\[2\]\]\);]],
			capture_group = 1
		}
	},
	slots_slot_machine_state = {
		description = "Slots Slot Machine State",
		file = "casino_slots.c",
		LEGACY = {
			value = 1662,
			pattern = [[MISC::CLEAR_BIT\(&.*?(Local_\d{4}), 18\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1664,
			pattern = [[MISC::CLEAR_BIT\(&.*?(Local_\d{4}), 18\)]],
			capture_group = 1
		}
	},
	prize_wheel_win_state = {
		description = "Prize Wheel Win State Local",
		file = "casino_lucky_wheel.c",
		LEGACY = {
			value = 302,
			pattern = [[(Local_\d{3})(\.f_\d{2}) =.*?Local_\d{3}\.f_\d{2} % 20]],
			capture_group = 1,
			offsets = {
				{
					value = 14,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 304,
			pattern = [[(Local_\d{3})(\.f_\d{2}) =.*?Local_\d{3}\.f_\d{2} % 20]],
			capture_group = 1,
			offsets = {
				{
					value = 14,
					capture_group = 2
				}
			}
		}
	},
	prize_wheel_prize_state = {
		description = "Prize Wheel Prize State Offset",
		file = "casino_lucky_wheel.c",
		LEGACY = {
			value = 302,
			pattern = [[if \(.?(Local_\d{3})(\.f_..) >= 5 && .?Local_\d{3}\.f_\d{2} <= 12\)]],
			capture_group = 1,
			offsets = {
				{
					value = 45,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 304,
			pattern = [[if \(.?(Local_\d{3})(\.f_..) >= 5 && .?Local_\d{3}\.f_\d{2} <= 12\)]],
			capture_group = 1,
			offsets = {
				{
					value = 45,
					capture_group = 2
				}
			}
		}
	},
	gb_casino_heist_planning = {
		description = "Casino Heist Planning Global",
		file = "gb_casino_heist_planning.c",
		LEGACY = {
			value = 1971952,
			pattern = [[!NETWORK::NETWORK_IS_PLAYER_ACTIVE\(Global_\d{7}\.f_\d{4}]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1973231,
			pattern = [[!NETWORK::NETWORK_IS_PLAYER_ACTIVE\(Global_\d{7}\.f_\d{4}]],
			capture_group = 1
		}
	},
	gb_casino_heist_planning_cut_offset = {
		description = "Casino Heist Planning Cut Offset",
		file = "gb_casino_heist_planning.c",
		LEGACY = {
			value = 1497,
			pattern = [[\w+->(f_\d{4})(\.f_\d{3})(\.f_\d{2})\[4\] > 0]],
			capture_group = 1,
			offsets = {
				{
					value = 736,
					capture_group = 2
				},
				{
					value = 92,
					capture_group = 3
				}
			}
		},
		ENHANCED = {
			value = 1497,
			pattern = [[\w+->(f_\d{4})(\.f_\d{3})(\.f_\d{2})\[4\] > 0]],
			capture_group = 1,
			offsets = {
				{
					value = 736,
					capture_group = 2
				},
				{
					value = 92,
					capture_group = 3
				}
			}
		}
	},
	fm_mission_controller_cart_grab = {
		description = "FM Mission Controller Cart Grab Local",
		file = "fm_mission_controller.c",
		LEGACY = {
			value = 10295,
			pattern =
			[[PED::SET_SYNCHRONIZED_SCENE_RATE\(NETWORK::NETWORK_GET_LOCAL_SCENE_FROM_NETWORK_ID\(.?Local_\d{5}\.f_\d+\), .?(Local_\d{5})(\.f_\d+\))]],
			capture_group = 1,
			offsets = {
				{
					value = 14,
					capture_group = 2,
					description = "grab speed"
				}
			}
		},
		ENHANCED = {
			value = 10697,
			pattern =
			[[PED::SET_SYNCHRONIZED_SCENE_RATE\(NETWORK::NETWORK_GET_LOCAL_SCENE_FROM_NETWORK_ID\(.?Local_\d{5}\.f_\d+\), .?(Local_\d{5})(\.f_\d+\))]],
			capture_group = 1,
			offsets = {
				{
					value = 14,
					capture_group = 2,
					description = "grab speed"
				}
			}
		}
	}
}
