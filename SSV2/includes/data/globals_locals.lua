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
	gpbd = {
		description = [[ GlobalPlayerBD
		Used in the project to get the status of Service Vehicles.
		To find bitsets:
		> freemode.c func_15166
		> 	Global_2733138.f_XXX ;; i.e. 613 for Kosatka, 592 for Acid Lab
		> 		func_15202(blah, blah, blah, THIS_NUMBER_IS_YOUR_BITSET_OFFSET);

		Scrolling through offsets for Vectors has revealed that this has the coords of:
		- Super Yacht @ offset -48
		- Kosatka/Terrorbyte/MOC @ offset +13
		- Acid Lab @ offset +75	
		]],
		file = "freemode.c",
		LEGACY = {
			value = 2658293,
			pattern = [[MISC::SET_BIT\(&\(Global_(\d{7})\[PLAYER::PLAYER_ID\(\) /\*(\d{3})\*/\]\.(f_\d{3})\.f_\d{1}\), 31\);]],
			capture_group = 1,
			offsets = {
				{
					value = 468,
					capture_group = 2,
					description = "playerID read size."
				},
				{
					value = 325,
					capture_group = 3
				}
			}
		},
		ENHANCED = {
			value = 2658296,
			pattern = [[MISC::SET_BIT\(&\(Global_(\d{7})\[PLAYER::PLAYER_ID\(\) /\*(\d{3})\*/\]\.(f_\d{3})\.f_\d{1}\), 31\);]],
			capture_group = 1,
			offsets = {
				{
					value = 468,
					capture_group = 2,
					description = "playerID read size."
				},
				{
					value = 325,
					capture_group = 3
				}
			}
		}
	},
	gpbd_fm_3 = {
		description = "GPBD_FM_3",
		file = "freemode.c",
		LEGACY = {
			value = 1892925,
			pattern = [[\w+\(&\(Global_(\d{7})\[.*?/\*(\d+)\*/\]\.f_10\.f_343\), \w+, 64\);]],
			capture_group = 1,
			offsets = {
				{
					value = 615,
					capture_group = 2,
					description = "player id size"
				}
			}
		},
		ENHANCED = {
			value = 1893070,
			pattern = [[\w+\(&\(Global_(\d{7})\[.*?/\*(\d+)\*/\]\.f_10\.f_343\), \w+, 64\);]],
			capture_group = 1,
			offsets = {
				{
					value = 615,
					capture_group = 2,
					description = "player id size"
				}
			}
		}
	},
	freemode_business_global = {
		description = "Freemode Business Global",
		file = "freemode.c",
		LEGACY = {
			value = 1673813,
			pattern = [[if.*?Global_\d{7}\[.*?\] != 0 && func_\w+\(.*?\) && \w+\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1673820,
			pattern = [[if.*?Global_\d{7}\[.*?\] != 0 && func_\w+\(.*?\) && \w+\)]],
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
			value = 1950557,
			pattern = [[else if \(Global_\w{7}\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1951071,
			pattern = [[else if \(Global_\w{7}\)]],
			capture_group = 1
		}
	},
	arcade_bhub_global_2 = {
		description = "Arcade Business Hub Global 2",
		file = "apparcadebusinesshub.c",
		LEGACY = {
			value = 1970624,
			pattern = [[if \(MISC::IS_STRING_NULL_OR_EMPTY\(\w+\) \|\| (Global_\w{7}) ==.*?\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1971195,
			pattern = [[if \(MISC::IS_STRING_NULL_OR_EMPTY\(\w+\) \|\| (Global_\w{7}) ==.*?\)]],
			capture_group = 1
		}
	},
	mp_business_stuff = {
		description = "Business stuff",
		file = "freemode.c",
		LEGACY = {
			value = 1845298,
			pattern = [[Global_(\d{7})\[.*? /\*(\d+)\*/\]\.(f_\d{3}).f_\d{3}\[.*? /\*\d+\*/\].f_9 = .*?;]],
			capture_group = 1,
			offsets = {
				{
					value = 881,
					capture_group = 2,
					description = "playerID read size."
				},
				{
					value = 260,
					capture_group = 3
				}
			}
		},
		ENHANCED = {
			value = 1845347,
			pattern = [[Global_(\d{7})\[.*? /\*(\d+)\*/\]\.(f_\d{3}).f_\d{3}\[.*? /\*\d+\*/\].f_9 = .*?;]],
			capture_group = 1,
			offsets = {
				{
					value = 884,
					capture_group = 2,
					description = "playerID read size."
				},
				{
					value = 260,
					capture_group = 3
				}
			}
		}
	},
	bhub_prod_time_global = {
		description = "Business Hub time left to produce.",
		file = "freemode.c",
		LEGACY = {
			value = 2709062,
			pattern = [[Global_(\d{7})\[.*?\] =.*?Global_\d{7}\[.*?\] +.*?Global_(\d{7})\.(f_1)\[.*?\] - .*?;]],
			capture_group = 1
		},
		ENHANCED = {
			value = 2709197,
			pattern = [[Global_(\d{7})\[.*?\] =.*?Global_\d{7}\[.*?\] +.*?Global_(\d{7})\.(f_1)\[.*?\] - .*?;]],
			capture_group = 1
		}
	},
	bhub_prod_bool_global = {
		description = "Business Hub some production bool. Flips back after production is triggered.",
		file = "freemode.c",
		LEGACY = {
			value = 2709073,
			pattern = [[Global_(\d{7})\[.*?\] =.*?Global_\d{7}\[.*?\] +.*?Global_(\d{7})\.(f_1)\[.*?\] - .*?;]],
			capture_group = 2,
			offsets = {
				{
					value = 1,
					capture_group = 3,
					description = "some int value indexed by hub slot. can't be bothered -_-"
				}
			}
		},
		ENHANCED = {
			value = 2709208,
			pattern = [[Global_(\d{7})\[.*?\] = Global_\d{7}\[.*?\] +.*?Global_(\d{7})\.(f_1)\[.*?\] - .*?;]],
			capture_group = 2,
			offsets = {
				{
					value = 1,
					capture_group = 3,
					description = "some int value indexed by hub slot. can't be bothered -_-"
				}
			}
		}
	},
	car_wash_safe_global = {
		description = "car wash safe global",
		file = "freemode.c",
		LEGACY = {
			value = 1882652,
			pattern = [[Global_(\d{7})\[.*?/\*(\d{3})\*/\]\.f_(\d{3})\.f_27\.f_2 = \w+0;]],
			capture_group = 1,
			offsets = {
				{
					value = 321,
					capture_group = 2,
					description = "player id read size"
				},
				{
					value = 158,
					capture_group = 3,
					description = "car wash entry?"
				}
			}
		},
		ENHANCED = {
			value = 1882797,
			pattern = [[Global_(\d{7})\[.*?/\*(\d{3})\*/\]\.f_(\d{3})\.f_27\.f_2 = \w+0;]],
			capture_group = 1,
			offsets = {
				{
					value = 321,
					capture_group = 2,
					description = "player id read size"
				},
				{
					value = 158,
					capture_group = 3,
					description = "car wash entry?"
				}
			}
		}
	},
	gb_contraband_buy_local_1 = {
		description = "Contraband Buy Local 1",
		file = "gb_contraband_buy.c",
		LEGACY = {
			value = 632,
			pattern = [[switch \(.*?Local_(\d{3})\.f_5]],
			capture_group = 1
		},
		ENHANCED = {
			value = 634,
			pattern = [[switch \(.*?Local_(\d{3})\.f_5]],
			capture_group = 1
		}
	},
	gb_contraband_buy_local_2 = {
		description = "Contraband Buy Local 2",
		file = "fm_content_cargo.c",
		LEGACY = {
			value = 6030,
			pattern = [[Position.*?0x21F25C[^\r\n]*\r?\n\s*\{\r?\n\s*return\s+func.*?Local_(\d{4}),\s*\w+0\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 6068,
			pattern = [[Position.*?0x22F3DC[^\r\n]*\r?\n\s*\{\r?\n\s*return\s+func.*?Local_(\d{4}),\s*\w+0\);]],
			capture_group = 1
		}
	},
	gb_contraband_buy_local_3 = {
		description = "Contraband Buy Local 3",
		file = "fm_content_cargo.c",
		LEGACY = {
			value = 6149,
			pattern = [[if \(.*?(Local_6\d{3})\.(f_1\d{3}) == 0]],
			capture_group = 1,
			offsets = {
				{
					value = 1180,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 6151,
			pattern = [[if \(.*?(Local_6\d{3})\.(f_1\d{3}) == 0]],
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
			value = 574,
			pattern = [[MISC::CLEAR_BIT\(&\(.*?Local_(\d{3})\.f_\d{1,2}\), \w+0]],
			capture_group = 1
		},
		ENHANCED = {
			value = 576,
			pattern = [[MISC::CLEAR_BIT\(&\(.*?Local_(\d{3})\.f_\d{1,2}\), \w+0]],
			capture_group = 1
		}
	},
	biker_required_deliveries_local = {
		description = "Biker Contraband Sell Local",
		file = "gb_biker_contraband_sell.c",
		LEGACY = {
			value = 736,
			pattern = [[.*?Local_(\d{3})\.f_(\d{3}) = func_\w+\(-1\);]],
			capture_group = 1,
			offsets = {
				{
					value = 174,
					capture_group = 2,
					description = "expected deliveries."
				}
			}
		},
		ENHANCED = {
			value = 738,
			pattern = [[.*?Local_(\d{3})\.f_(\d{3}) = func_\w+\(-1\);]],
			capture_group = 1,
			offsets = {
				{
					value = 174,
					capture_group = 2,
					description = "expected deliveries."
				}
			}
		}
	},
	biker_deliveries_local = {
		description = "Biker Contraband Sell Local",
		file = "gb_biker_contraband_sell.c",
		LEGACY = {
			value = 736,
			pattern = [[else if \(!func_\w+\(.*?\) &&.*?(Local_\d{3})(\.f_\d{3}) > 0\)]],
			capture_group = 1,
			offsets = {
				{
					value = 122,
					capture_group = 2,
					description = "number of deliveries made"
				}
			}
		},
		ENHANCED = {
			value = 738,
			pattern = [[else if \(!func_\w+\(.*?\) &&.*?(Local_\d{3})(\.f_\d{3}) > 0\)]],
			capture_group = 1,
			offsets = {
				{
					value = 122,
					capture_group = 2,
					description = "number of deliveries made"
				}
			}
		}
	},
	gb_smuggler_sell_air_local_1 = {
		description = "Hangar Sell Local 1 (air)",
		file = "gb_smuggler.c",
		LEGACY = {
			value = 1996,
			pattern = [[for \(i = 0; i < func_\w{2}\(func_\w{4}\(\), func_\w{2}\(\), .*?(Local_\d{4})\.(f_\d{4}), -1\); i = i \+ 1\)]],
			capture_group = 1,
			offsets = {
				{
					value = 1035,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 1998,
			pattern = [[for \(i = 0; i < func_\w{2}\(func_\w{4}\(\), func_\w{2}\(\), .*?(Local_\d{4})\.(f_\d{4}), -1\); i = i \+ 1\)]],
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
			value = 1996,
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
			value = 1998,
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
	gb_gunrunning_sell_local = {
		description = "Bunker Sell Local 1",
		file = "gb_gunrunning.c",
		LEGACY = {
			value = 1273,
			pattern = [[Local_1\d{3}\.f_\d{3} = func_\w+\(func_\w+\(\),.*?(Local_1\d{3})\.(f_\d{3}), \w+, -1\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1275,
			pattern = [[Local_1\d{3}\.f_\d{3} = func_\w+\(func_\w+\(\),.*?(Local_1\d{3})\.(f_\d{3}), \w+, -1\);]],
			capture_group = 1
		}
	},
	bunker_sell_amt_delivered = {
		description = "Amount delivered.",
		file = "gb_gunrunning.c",
		LEGACY = {
			value = 1273,
			pattern = [[func_\w+\(.*?Local_(\d{4})\.f_(\d{3}), \w+, "GR_HUD_TOT".*?, 255, 0\);]],
			capture_group = 1,
			offsets = {
				{
					value = 816,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 1275,
			pattern = [[func_\w+\(.*?Local_(\d{4})\.f_(\d{3}), \w+, "GR_HUD_TOT".*?, 255, 0\);]],
			capture_group = 1,
			offsets = {
				{
					value = 816,
					capture_group = 2
				}
			}
		}
	},
	bunker_sell_num_vehs = {
		description = "Number of delivery vehicles.",
		file = "gb_gunrunning.c",
		LEGACY = {
			value = 1273,
			pattern = [[for \(i = 0; i < func_\w+\(func_\w+\(\), func_\w+\(\),.*?(Local_\d{4})(\.f_\d{3}),.*?Local_\d{4}\.f_\d{3}\); i = i \+ 1\)]],
			capture_group = 1,
			offsets = {
				{
					value = 774,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 1275,
			pattern = [[for \(i = 0; i < func_\w+\(func_\w+\(\), func_\w+\(\),.*?(Local_\d{4})(\.f_\d{3}),.*?Local_\d{4}\.f_\d{3}\); i = i \+ 1\)]],
			capture_group = 1,
			offsets = {
				{
					value = 774,
					capture_group = 2
				}
			}
		}
	},
	acid_lab_sell_deliveries_local = {
		description = "Acid Lab Deliveries. This shit is pissing me off and my dumbass doesn't know how to use scrDBG without creating a bazillion GB log file.",
		file = "fm_content_acid_lab_sell.c",
		LEGACY = {
			value = 151,
			pattern = [[if \(.*?Local_(\d{3})\.f_(\d{1}) !=.*?Local_\d{3}\.f_\d{4}\[0 /\*6\*/\]\.f_2\)]],
			capture_group = 1,
			offsets = {
				{
					value = 9,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 153,
			pattern = [[if \(.*?Local_(\d{3})\.f_(\d{1}) !=.*?Local_\d{3}\.f_\d{4}\[0 /\*6\*/\]\.f_2\)]],
			capture_group = 1,
			offsets = {
				{
					value = 9,
					capture_group = 2
				}
			}
		}
	},
	acid_lab_sell_mission_state_local = {
		description = "Acid Lab Mission State",
		file = "fm_content_acid_lab_sell.c",
		LEGACY = {
			value = 5758,
			pattern = [[if \(.*?Local_(5\d{3})(\.f_\d{4}) == 0\)]],
			capture_group = 1,
			offsets = {
				{
					value = 1339,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 5760,
			pattern = [[if \(.*?Local_(5\d{3})(\.f_\d{4}) == 0\)]],
			capture_group = 1,
			offsets = {
				{
					value = 1339,
					capture_group = 2
				}
			}
		}
	},
	acid_lab_sell_gen_bs = {
		description = "Acid Lab Sell Generic Bitset",
		file = "fm_content_acid_lab_sell.c",
		LEGACY = {
			value = 5632,
			pattern = [[func_\w{3}\(&.?(Local_5\d+), \w+\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 5634,
			pattern = [[func_\w{3}\(&.?(Local_5\d+), \w+\)]],
			capture_group = 1
		}
	},
	three_card_poker_table = {
		description = "Three Card Poker Table Local",
		file = "three_card_poker.c",
		LEGACY = {
			value = 778,
			pattern = [[if \(.*?Local_(\d{3})\[.*? /\*(\d+)\*/\]\.f_\d+ ==.*?&&.*?Local_\d{3}\[.*?\]\.f_\d+ > 0 \|\| .*?Local_\d{3}\[.*?\]\.f_\d+ > 0\)]],
			capture_group = 1,
			offsets = {
				{
					value = 9,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 780,
			pattern = [[if \(.*?Local_(\d{3})\[.*? /\*(\d+)\*/\]\.f_\d+ ==.*?&&.*?Local_\d{3}\[.*?\]\.f_\d+ > 0 \|\| .*?Local_\d{3}\[.*?\]\.f_\d+ > 0\)]],
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
			value = 145,
			pattern = [[STREAMING::REQUEST_MODEL\(func_\d+\(.*?Local_(\d{3})(\.f_\d{3})\[.*?\]\.f_\d+\[.*?\], .*?Local_\d{4}\.f_\d+\)\);]],
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
			value = 147,
			pattern = [[STREAMING::REQUEST_MODEL\(func_\d+\(.*?Local_(\d{3})(\.f_\d{3})\[.*?\]\.f_\d+\[.*?\], .*?Local_\d{4}\.f_\d+\)\);]],
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
			pattern = [[if \(!NETWORK::NETWORK_HAS_CONTROL_OF_NETWORK_ID\(.*?Local_\d{3}(\.f_\d{2})\[\w+\(\w+, 0\)\]\)\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 55,
			pattern = [[if \(!NETWORK::NETWORK_HAS_CONTROL_OF_NETWORK_ID\(.*?Local_\d{3}(\.f_\d{2})\[\w+\(\w+, 0\)\]\)\)]],
			capture_group = 1
		}
	},
	three_card_poker_anti_cheat = {
		description = "Three Card Poker Anti Cheat",
		file = "three_card_poker.c",
		LEGACY = {
			value = 1067,
			pattern = [[if \(.*?(Local_\d{4})(\.f_\d{3})\.f_\d+\[.*?\] !=.*?Local_\d{3}\.f_\d+\[PLAYER::PLAYER_ID\(\) .*?\]\.f_1\[.*?\]\)]],
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
			value = 1069,
			pattern = [[if \(.*?(Local_\d{4})(\.f_\d{3})\.f_\d+\[.*?\] !=.*?Local_\d{3}\.f_\d+\[PLAYER::PLAYER_ID\(\) .*?\]\.f_1\[.*?\]\)]],
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
			value = 1805,
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
			value = 1807,
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
			value = 145,
			pattern = [[if \(func_\w+\(.*?(Local_\d{3})(\.f_\d{3})\[.*?\]\) == 10 \|\| func_\d+\(.*?Local_\d{3}\.f_\d{3}\[.*?\]\) == 11\)]],
			capture_group = 1,
			offsets = {
				{
					value = 846,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 147,
			pattern = [[if \(func_\w+\(.*?(Local_\d{3})(\.f_\d{3})\[.*?\]\) == 10 \|\| func_\d+\(.*?Local_\d{3}\.f_\d{3}\[.*?\]\) == 11\)]],
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
			value = 153,
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
			value = 155,
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
			value = 1379,
			pattern = [[\w+ = func_\d+\(.*?(Local_\d{4})\.f_1\[.*?\]\[.*?Local_\d+\[0\]\], .*?Local_\d+?\.f_1\[.*?\]\[.*?Local_\d+\[1\]\], .*?Local_\d{4}\.f_1\[.*?\]\[.*?Local_\d+\[2\]\]\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1381,
			pattern = [[\w+ = func_\d+\(.*?(Local_\d{4})\.f_1\[.*?\]\[.*?Local_\d+\[0\]\], .*?Local_\d+?\.f_1\[.*?\]\[.*?Local_\d+\[1\]\], .*?Local_\d{4}\.f_1\[.*?\]\[.*?Local_\d+\[2\]\]\);]],
			capture_group = 1
		}
	},
	slots_slot_machine_state = {
		description = "Slots Slot Machine State",
		file = "casino_slots.c",
		LEGACY = {
			value = 1669,
			pattern = [[MISC::CLEAR_BIT\(&.*?(Local_\d{4}), 18\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1671,
			pattern = [[MISC::CLEAR_BIT\(&.*?(Local_\d{4}), 18\)]],
			capture_group = 1
		}
	},
	prize_wheel_win_state = {
		description = "Prize Wheel Win State Local",
		file = "casino_lucky_wheel.c",
		LEGACY = {
			value = 309,
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
			value = 311,
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
			value = 309,
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
			value = 311,
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
			value = 1972483,
			pattern = [[!NETWORK::NETWORK_IS_PLAYER_ACTIVE\(Global_\d{7}\.f_\d{4}]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1973762,
			pattern = [[!NETWORK::NETWORK_IS_PLAYER_ACTIVE\(Global_\d{7}\.f_\d{4}]],
			capture_group = 1
		}
	},
	og_heists_player_cuts_global_1 = {
		description = "OG heists Player Cuts Global1 + 1",
		file = "fmmc_launcher.c",
		LEGACY = {
			value = 1935929,
			pattern = [[if\s+\(func_\d+\(PLAYER::PLAYER_ID\(\)\)\)[\r\n]?.?\s+func_\d+\(Global_\d+, Global_\d+\.f_\d+, Global_\d+\.f_\d+\);[\r\n]?.?\s+else[\r\n]?.?\s+func_\d+\(Global_\d+, Global_\d+\.f_\d{2}, Global_(\d+)\.f_1\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1936406,
			pattern = [[if\s+\(func_\d+\(PLAYER::PLAYER_ID\(\)\)\)[\r\n]?.?\s+func_\d+\(Global_\d+, Global_\d+\.f_\d+, Global_\d+\.f_\d+\);[\r\n]?.?\s+else[\r\n]?.?\s+func_\d+\(Global_\d+, Global_\d+\.f_\d{2}, Global_(\d+)\.f_1\);]],
			capture_group = 1
		}
	},
	og_heists_player_cuts_global_2 = {
		description = "OG heists Player Cuts Global2 (struct<5>)",
		file = "fmmc_launcher.c",
		LEGACY = {
			value = 1937897,
			pattern = [[if\s+\(func_\d+\(PLAYER::PLAYER_ID\(\)\)\)[\r\n]?.?\s+func_\d+\(Global_\d+, Global_\d+\.f_\d+, Global_(\d{7})\.f_(\d{4})\);[\r\n]?.?\s+else[\r\n]?.?\s+func_\d+\(Global_\d+, Global_\d+\.f_\d{2}, Global_\d+\.f_1\);]],
			capture_group = 1,
			offsets = {
				{
					value = 3008,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 1938374,
			pattern = [[if\s+\(func_\d+\(PLAYER::PLAYER_ID\(\)\)\)[\r\n]?.?\s+func_\d+\(Global_\d+, Global_\d+\.f_\d+, Global_(\d{7})\.f_(\d{4})\);[\r\n]?.?\s+else[\r\n]?.?\s+func_\d+\(Global_\d+, Global_\d+\.f_\d{2}, Global_\d+\.f_1\);]],
			capture_group = 1,
			offsets = {
				{
					value = 3008,
					capture_group = 2
				}
			}
		}
	},
	gb_gang_ops_planning_player_cuts = {
		description = "GangOps Player Cuts Global + Offsets",
		file = "gb_gang_ops_planning.c",
		LEGACY = {
			value = 1968511,
			pattern = [[Global_\d{7}\.f_\d{3}\.f_\d{2}\[.+?\]\s+?=\s+?-1;[\r\n]?\s+?Global_(\d{7})\.f_(\d{3})\.f_(\d{2})\[.+?\]\s+?=\s+?0;]],
			capture_group = 1,
			offsets = {
				{
					value = 812,
					capture_group = 2
				},
				{
					value = 50,
					capture_group = 3
				},
			}
		},
		ENHANCED = {
			value = 1969071,
			pattern = [[Global_\d{7}\.f_\d{3}\.f_\d{2}\[.+?\]\s+?=\s+?-1;[\r\n]?\s+?Global_(\d{7})\.f_(\d{3})\.f_(\d{2})\[.+?\]\s+?=\s+?0;]],
			capture_group = 1,
			offsets = {
				{
					value = 812,
					capture_group = 2
				},
				{
					value = 50,
					capture_group = 3
				},
			}
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
	fmmc_trolley_scene = {
		description = "FM Mission Controller loot trolley synchronized scene local.",
		file = "fm_mission_controller.c",
		LEGACY = {
			value = 10311,
			pattern = [[PED::SET_SYNCHRONIZED_SCENE_RATE\(NETWORK::NETWORK_GET_LOCAL_SCENE_FROM_NETWORK_ID\(.?Local_\d+\.f_\d+\), .?Local_(\d+)\.f_(\d+)\)]],
			capture_group = 1,
			offsets = {
				{
					value = 14,
					capture_group = 2,
					description = "scene rate"
				}
			}
		},
		ENHANCED = {
			value = 10713,
			pattern = [[PED::SET_SYNCHRONIZED_SCENE_RATE\(NETWORK::NETWORK_GET_LOCAL_SCENE_FROM_NETWORK_ID\(.?Local_\d+\.f_\d+\), .?Local_(\d+)\.f_(\d+)\)]],
			capture_group = 1,
			offsets = {
				{
					value = 14,
					capture_group = 2,
					description = "scene rate"
				}
			}
		}
	},
	fmmc20_trolley_scene = {
		description = "FM Mission Controller 2020 loot trolley synchronized scene local.",
		file = "fm_mission_controller_2020.c",
		LEGACY = {
			value = 30873,
			pattern = [[PED::SET_SYNCHRONIZED_SCENE_RATE\(NETWORK::NETWORK_GET_LOCAL_SCENE_FROM_NETWORK_ID\(.?Local_\d+\.f_\d+\), .?Local_(\d+)\.f_(\d+)\)]],
			capture_group = 1,
			offsets = {
				{
					value = 14,
					capture_group = 2,
					description = "scene rate"
				}
			}
		},
		ENHANCED = {
			value = 31275,
			pattern = [[PED::SET_SYNCHRONIZED_SCENE_RATE\(NETWORK::NETWORK_GET_LOCAL_SCENE_FROM_NETWORK_ID\(.?Local_\d+\.f_\d+\), .?Local_(\d+)\.f_(\d+)\)]],
			capture_group = 1,
			offsets = {
				{
					value = 14,
					capture_group = 2,
					description = "scene rate"
				}
			}
		}
	},
	fmmc_v3_trolley_scene = {
		description = "FM Mission Controller V3 loot trolley synchronized scene local.",
		file = "fm_mission_controller_v3.c",
		LEGACY = {
			value = 30965,
			pattern = [[PED::SET_SYNCHRONIZED_SCENE_RATE\(NETWORK::NETWORK_GET_LOCAL_SCENE_FROM_NETWORK_ID\(.?Local_\d+\.f_\d+\), .?Local_(\d+)\.f_(\d+)\)]],
			capture_group = 1,
			offsets = {
				{
					value = 14,
					capture_group = 2,
					description = "scene rate"
				}
			}
		},
		ENHANCED = {
			value = 31367,
			pattern = [[PED::SET_SYNCHRONIZED_SCENE_RATE\(NETWORK::NETWORK_GET_LOCAL_SCENE_FROM_NETWORK_ID\(.?Local_\d+\.f_\d+\), .?Local_(\d+)\.f_(\d+)\)]],
			capture_group = 1,
			offsets = {
				{
					value = 14,
					capture_group = 2,
					description = "scene rate"
				}
			}
		}
	},
	cayo_perico_player_cut_global = {
		description = "Player cuts global",
		file = "heist_island_planning.c",
		LEGACY = {
			value = 1979291,
			pattern = [[return IS_BIT_SET\(Global_(\d{7})\.f_\d{4}, 15\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1980570,
			pattern = [[.*->f_(\d{3})\.f_(\d{2})\[\d\] = \*Global_262145\.f_\d{5};]],
			capture_group = 1
		},
	},
	cayo_perico_player_cut_offsets = {
		description = "Player cuts offsets",
		file = "heist_island_planning.c",
		LEGACY = {
			value = 831,
			pattern = [[.*->f_(\d{3})\.f_(\d{2})\[\d\] = \*Global_262145\.f_\d{5};]],
			capture_group = 1,
			offsets = {
				{
					value = 56,
					capture_group = 2,
				}
			}
		},
		ENHANCED = {
			value = 831,
			pattern = [[.*->f_(\d{3})\.f_(\d{2})\[\d\] = \*Global_262145\.f_\d{5};]],
			capture_group = 1,
			offsets = {
				{
					value = 56,
					capture_group = 2,
				}
			}
		},
	},
	fmmc_launcher_min_players_local = {
		description = "fmmc launcher minimum required players",
		file = "fmmc_launcher.c",
		LEGACY = {
			value = 20194,
			pattern = [[Local_(\d+)\.f_(\d+)\s+=\s+1;[\r\n]?\s+Global_\d+\.f_\d+\s+=\s+1;]],
			capture_group = 1,
			offsets = {
				{
					value = 15,
					capture_group = 2,
				}
			}
		},
		ENHANCED = {
			value = 20196,
			pattern = [[Local_(\d+)\.f_(\d+)\s+=\s+1;[\r\n]?\s+Global_\d+\.f_\d+\s+=\s+1;]],
			capture_group = 1,
			offsets = {
				{
					value = 15,
					capture_group = 2,
				}
			}
		},
	},
	fmmc_launcher_mission_var_offset = {
		description = "fmmc launcher mission variation offset",
		file = "fmmc_launcher.c",
		LEGACY = {
			value = 34,
			pattern = [[HUD_MG_TENNIS.*,\s+64\);[\r\n]?.+?Local_\d+\.f_\d+\),.*Local_\d+\.f_(\d+)\s+\+\s+1,\s+64\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 34,
			pattern = [[HUD_MG_TENNIS.*,\s+64\);[\r\n]?.+?Local_\d+\.f_\d+\),.*Local_\d+\.f_(\d+)\s+\+\s+1,\s+64\);]],
			capture_group = 1
		},
	},
	fmmc_skip_obj_local = {
		description = "fm mission controller skip objective",
		file = "fm_mission_controller.c",
		LEGACY = {
			value = 19808,
			pattern = [[Local_(\d+)\.f_(\d+)\s?<\s?6\s?&&.*>= 0]],
			capture_group = 1,
			offsets = {
				{
					value = 1062,
					capture_group = 2,
				}
			}
		},
		ENHANCED = {
			value = 20412,
			pattern = [[Local_(\d+)\.f_(\d+)\s?<\s?6\s?&&.*>= 0]],
			capture_group = 1,
			offsets = {
				{
					value = 1062,
					capture_group = 2,
				}
			}
		},
	},
	fmmc_team_score_offset = {
		description = "fm mission controller team score",
		file = "fm_mission_controller.c",
		LEGACY = {
			value = 1232,
			pattern = [[OVT_BLIMP_T.*\);[\r\n]?\s+?HUD::ADD_TEXT_COMPONENT_INTEGER.*?Local_\d{5}\.f_(\d{4})\[0\]\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1232,
			pattern = [[OVT_BLIMP_T.*\);[\r\n]?\s+?HUD::ADD_TEXT_COMPONENT_INTEGER.*?Local_\d{5}\.f_(\d{4})\[0\]\);]],
			capture_group = 1
		},
	},
	fmmc_20_skip_obj_local = {
		description = "",
		file = "fm_mission_controller_2020.c",
		LEGACY = {
			value = 56070,
			pattern = [[Local_(\d+)\.f_(\d+)\s?<\s?6\s?&&.*>= 0]],
			capture_group = 1,
			offsets = {
				{
					value = 1589,
					capture_group = 2,
				}
			}
		},
		ENHANCED = {
			value = 56504,
			pattern = [[Local_(\d+)\.f_(\d+)\s?<\s?6\s?&&.*>= 0]],
			capture_group = 1,
			offsets = {
				{
					value = 1589,
					capture_group = 2,
				}
			}
		},
	},
	fmmc_20_team_score_offset = {
		description = "fm mission controller 2020 team score",
		file = "fm_mission_controller_2020.c",
		LEGACY = {
			value = 1776,
			pattern = [[if\s+\(.*?\+\s+.?Local_\d{5}\.f_(\d{4})\[0\]\s+<\s+.?Local_\d{5}\.f_\d{4}\[1\]\s+\|\|\s+.*?\s+\+\s+.?Local_\d{5}\.f_\d{4}\[1\]\s+<\s+.?Local_\d{5}\.f_\d{4}\[0\]\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1776,
			pattern = [[if\s+\(.*?\+\s+.?Local_\d{5}\.f_(\d{4})\[0\]\s+<\s+.?Local_\d{5}\.f_\d{4}\[1\]\s+\|\|\s+.*?\s+\+\s+.?Local_\d{5}\.f_\d{4}\[1\]\s+<\s+.?Local_\d{5}\.f_\d{4}\[0\]\)]],
			capture_group = 1
		},
	},
	ie_objective_local = {
		description = "Import/Export steal auto complete mission.",
		file = "gb_vehicle_export.c",
		LEGACY = {
			value = 887,
			pattern = [[.*?Local_(\d{3})\.f_(459)\s+=\s+\w+;]],
			capture_group = 1,
			offsets = {
				{
					value = 459,
					capture_group = 2,
					description = "Current objective. This hasn't changed in years, hence the reason it's hardcoded in the regex pattern."
				}
			}
		},
		ENHANCED = {
			value = 889,
			pattern = [[.*?Local_(\d{3})\.f_(459)\s+=\s+\w+;]],
			capture_group = 1,
			offsets = {
				{
					value = 459,
					capture_group = 2
				}
			}
		}
	},
	ie_bitset_1 = {
		description = "Import/Export some other array of bits. Hardcoded as well because it hasn't changed either.",
		file = "gb_vehicle_export.c",
		LEGACY = {
			value = 453,
			pattern = [[.*?Local_\d{3}\.f_(453)\.*?]],
			capture_group = 1
		},
		ENHANCED = {
			value = 453,
			pattern = [[.*?Local_\d{3}\.f_(453)\.*?]],
			capture_group = 1
		}
	},
	ie_num_vehs = {
		description = "Import/Export steal number of vehicles.",
		file = "gb_vehicle_export.c",
		LEGACY = {
			value = 650,
			pattern = [[Local_\d{3}\.(f_\d{3})\s+=\s+func_\w+\(func_\w+\(\),.*?Local_\d{3}\.f_\d{3},\s+func_\w+\(func_\d{3}\(\)\)\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 650,
			pattern = [[Local_\d{3}\.(f_\d{3})\s+=\s+func_\w+\(func_\w+\(\),.*?Local_\d{3}\.f_\d{3},\s+func_\w+\(func_\d{3}\(\)\)\);]],
			capture_group = 1
		}
	},
	ie_steal_bitset = {
		description = [[This stores indices of bitsets??
		It's indexed by the number of targets (size 2, idx from 1 to 4) which is stored in Local_880.f_650.
		Still haven't figured out which bits we need to set.
		Attempts made:
		- Use Arthur's scrDbg to log calls to func_9 and func_140
			- Result: 1.7GB log file that broke my text editor (skill issue on my part).
		- Log the final value after finishing the mission normally and try to directly set it. Feels wrong, bad, and weird but does (kida) work.
			- Result: Mission passes but vehicle won't be stored in our garage.
		]],
		file = "gb_vehicle_export.c",
		LEGACY = {
			value = 48,
			pattern = [[.*?Local_\d{3}\.f_(\d{2})\[.*?/\*(\d+)\*/\]\[\w+\], \w+\);]],
			capture_group = 1,
			offsets = {
				{
					value = 2,
					capture_group = 2,
					description = "read size."
				}
			}
		},
		ENHANCED = {
			value = 48,
			pattern = [[.*?Local_\d{3}\.f_(\d{2})\[.*?/\*(\d+)\*/\]\[\w+\], \w+\);]],
			capture_group = 1,
			offsets = {
				{
					value = 2,
					capture_group = 2,
					description = "read size."
				}
			}
		}
	},
	bb_sell_local = {
		description = "business battles sell local",
		file = "business_battles_sell.c",
		LEGACY = {
			value = 2393,
			pattern = [[if.*?Local_(\d{4})\.f_(\d{3}) -.*?Local_\d{4}\.f_(\d{3}) <= 1 && func_\d+\(28\)]],
			capture_group = 1,
			offsets = {
				{
					value = 203,
					capture_group = 2,
					description = "required deliveries"
				},
				{
					value = 202,
					capture_group = 3,
					description = "deliveries made"
				}
			}
		},
		ENHANCED = {
			value = 2395,
			pattern = [[if.*?Local_(\d{4})\.f_(\d{3}) -.*?Local_\d{4}\.f_(\d{3}) <= 1 && func_\d+\(28\)]],
			capture_group = 1,
			offsets = {
				{
					value = 205,
					capture_group = 2,
					description = "required deliveries"
				},
				{
					value = 204,
					capture_group = 3,
					description = "deliveries made"
				}
			}
		}
	},
	bb_sell_mission_state_offset = {
		description = "business battles sell mission state local",
		file = "business_battles_sell.c",
		LEGACY = {
			value = 25,
			pattern = [[.*?Local_\d{4}\.f_(\d{2})\s*=\s*\w+0;]],
			capture_group = 1
		},
		ENHANCED = {
			value = 27,
			pattern = [[.*?Local_\d{4}\.f_(\d{2})\s*=\s*\w+0;]],
			capture_group = 1
		}
	},
	bb_sell_vehicle_array_offset = {
		description = "business battles sell mission vehicle array",
		file = "business_battles_sell.c",
		LEGACY = {
			value = 32,
			pattern = [[Local_\d{4}\.f_(\d{2})\[i /\*42\*/\]\.f_30 = func_\d{3}\(\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 34,
			pattern = [[Local_\d{4}\.f_(\d{2})\[i /\*42\*/\]\.f_30 = func_\d{3}\(\);]],
			capture_group = 1
		}
	},
	request_services_global = {
		description = "Request Services Global. Only used for Kosatka atm, same global for all services.",
		file = "am_mp_submarine.c",
		LEGACY = {
			value = 2733190,
			pattern = [[return Global_(\d{7})\.f_371;]],
			capture_group = 1
		},
		ENHANCED = {
			value = 2733326,
			pattern = [[return Global_(\d{7})\.f_371;]],
			capture_group = 1
		}
	},
	heist_boosts_global_start = {
		description = "weekly boost global init",
		file = "tuneables_processing.c",
		LEGACY = {
			value = 37632,
			pattern = [[Global_262145\.f_(\d{5})\s+=.*-341592538, .*\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 38231,
			pattern = [[Global_262145\.f_(\d{5})\s+=.*-341592538, .*\);]],
			capture_group = 1
		}
	},
	jobs_root_content_id_global = {
		description = "Stores root content ID hash of original heists and hacker24 jobs (maybe more jobs, haven't checked)",
		file = "freemode.c",
		LEGACY = {
			value = 2635459,
			pattern = [[HUD::SET_WARNING_MESSAGE_WITH_HEADER\("HCOST_TITLE".*?,\s+"HCOST_BODY".*?,\s+18,\s+"HEIST_WARN_2".*?,\s+true,\s+Global_(\d+)\.f_(\d{2}),\s+func_\d+\(Global_\d+\),\s+0,\s+true,\s+0\);]],
			capture_group = 1,
			offsets = {
				{
					value = 52,
					capture_group = 2,
					description = "Setup cost offset."
				}
			}
		},
		ENHANCED = {
			value = 2635459,
			pattern = [[HUD::SET_WARNING_MESSAGE_WITH_HEADER\("HCOST_TITLE".*?,\s+"HCOST_BODY".*?,\s+18,\s+"HEIST_WARN_2".*?,\s+true,\s+Global_(\d+)\.f_(\d{2}),\s+func_\d+\(Global_\d+\),\s+0,\s+true,\s+0\);]],
			capture_group = 1,
			offsets = {
				{
					value = 52,
					capture_group = 2,
					description = "Setup cost offset."
				}
			}
		}
	},
	apt_heist_board_state_global = {
		description = "1: default. 6: heist selected. 7: prompt to pay setup fee. 8: launching. 9: in heist launch menu (do not directly set to 9, it breaks. set to 8 instead)",
		file = "freemode.c",
		LEGACY = {
			value = 2635125,
			pattern = [[HUD::SET_WARNING_MESSAGE_WITH_HEADER\("HCOST_TITLE".*?,\s+"HCOST_BODY".*?,\s+18,\s+"HEIST_WARN_2".*?,\s+true,\s+Global_(\d+)\.f_(\d{2}),\s+func_\d+\(Global_\d+\),\s+0,\s+true,\s+0\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 2635459,
			pattern = [[HUD::SET_WARNING_MESSAGE_WITH_HEADER\("HCOST_TITLE".*?,\s+"HCOST_BODY".*?,\s+18,\s+"HEIST_WARN_2".*?,\s+true,\s+Global_(\d+)\.f_(\d{2}),\s+func_\d+\(Global_\d+\),\s+0,\s+true,\s+0\);]],
			capture_group = 1
		}
	},
	k26_gen_bs_global = {
		description = "kortz heist general bitset",
		file = "kortz_planning.c",
		LEGACY = {
			value = 1983730,
			pattern = [[SET_BIT\(&\(Global_(\d+)\[.*/\*(\d{3})\*/\]\.f_(\d{3})\), 28\);]],
			capture_group = 1,
			offsets = {
				{
					value = 149,
					capture_group = 2,
					description = "array size"
				},
				{
					value = 137,
					capture_group = 3,
					description = "gen bs offset"
				}
			}
		},
		ENHANCED = {
			value = 1985024,
			pattern = [[SET_BIT\(&\(Global_(\d+)\[.*/\*(\d{3})\*/\]\.f_(\d{3})\), 28\);]],
			capture_group = 1,
			offsets = {
				{
					value = 149,
					capture_group = 2,
					description = "array size"
				},
				{
					value = 137,
					capture_group = 3,
					description = "gen bs offset"
				}
			}
		}
	},
	h4_gen_bs_global = {
		description = "Cayo Perico general bitset",
		file = "heist_island_planning.c",
		LEGACY = {
			value = 1981269,
			pattern = [[SET_BIT\(&\(Global_(\d+)\[.*/\*(\d{2})\*/\]\.f_1\), 12\);]],
			capture_group = 1,
			offsets = {
				{
					value = 53,
					capture_group = 2,
					description = "array size"
				},
			}
		},
		ENHANCED = {
			value = 1982548,
			pattern = [[SET_BIT\(&\(Global_(\d+)\[.*/\*(\d{2})\*/\]\.f_1\), 12\);]],
			capture_group = 1,
			offsets = {
				{
					value = 53,
					capture_group = 2,
					description = "array size"
				},
			}
		}
	},
	solo_missions_global = {
		description = "SoloMissions global",
		file = "fmmc_launcher.c",
		LEGACY = {
			value = 4718592,
			pattern = [[Global_(\d+)\.f_\d+\s?=.+?"minNu"]],
			capture_group = 1
		},
		ENHANCED = {
			value = 4718592,
			pattern = [[Global_(\d+)\.f_\d+\s?=.+?"minNu"]],
			capture_group = 1
		}
	},
	solo_missions_global_offset_1 = {
		description = "SoloMissions global offset minNumParticipants",
		file = "fmmc_launcher.c",
		LEGACY = {
			value = 3769,
			pattern = [[Global_\d+\.f_(\d+)\s?=.+?"minNu"]],
			capture_group = 1
		},
		ENHANCED = {
			value = 3769,
			pattern = [[Global_(\d+)\.f_\d+\s?=.+?"minNu"]],
			capture_group = 1
		}
	},
	solo_missions_global_offset_2 = {
		description = "SoloMissions global offset numberOfTeams",
		file = "fmmc_launcher.c",
		LEGACY = {
			value = 3772,
			pattern = [[Global_\d+\.f_(\d+)\s?=.+?"dtn"]],
			capture_group = 1
		},
		ENHANCED = {
			value = 3772,
			pattern = [[Global_\d+\.f_(\d+)\s?=.+?"dtn"]],
			capture_group = 1
		}
	},
	solo_missions_global_offset_3 = {
		description = "SoloMissions global offset maxNumberOfTeams",
		file = "fmmc_launcher.c",
		LEGACY = {
			value = 3773,
			pattern = [[Global_\d+\.f_(\d+)\s?=.+?"tnum"]],
			capture_group = 1
		},
		ENHANCED = {
			value = 3773,
			pattern = [[Global_\d+\.f_(\d+)\s?=.+?"tnum"]],
			capture_group = 1
		}
	},
	solo_missions_global_offset_4 = {
		description = "SoloMissions global offset numPlayersPerTeam",
		file = "fmmc_launcher.c",
		LEGACY = {
			value = 3775,
			pattern = [[else.*[\r\n]?.*?HUD::ADD_TEXT_COMPONENT_INTEGER\(Global_\d+\.f_(\d+)\[.*\]\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 3775,
			pattern = [[else.*[\r\n]?.*?HUD::ADD_TEXT_COMPONENT_INTEGER\(Global_\d+\.f_(\d+)\[.*\]\);]],
			capture_group = 1
		}
	},
	solo_missions_global_offset_5 = {
		description = "SoloMissions global offset nextContentID",
		file = "fmmc_launcher.c",
		LEGACY = {
			value = 133252,
			pattern = [[if\s+?\(!MISC::IS_STRING_NULL_OR_EMPTY\(&Global_\d+\.f_(\d+)\[.*/\*6\*/\]\)\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 139752,
			pattern = [[if\s+?\(!MISC::IS_STRING_NULL_OR_EMPTY\(&Global_\d+\.f_(\d+)\[.*/\*6\*/\]\)\)]],
			capture_group = 1
		}
	},
	solo_missions_global_offset_6 = {
		description = "SoloMissions global offset criticalMinimumForTeam",
		file = "fmmc_launcher.c",
		LEGACY = {
			value = 190163,
			pattern = [[MISC::SET_BIT.*?Global_\d+\.f_\d{4}\[.*?/\*\d+\*/\]\.f_\d{5}\), 0\);[\r\n]?\s+?Global_\d+\.f_(\d+)\[.*?\]\s+=\s+Global_\d+\.f_\d{4}\[.*?\];]],
			capture_group = 1
		},
		ENHANCED = {
			value = 196663,
			pattern = [[MISC::SET_BIT.*?Global_\d+\.f_\d{4}\[.*?/\*\d+\*/\]\.f_\d{5}\), 0\);[\r\n]?\s+?Global_\d+\.f_(\d+)\[.*?\]\s+=\s+Global_\d+\.f_\d{4}\[.*?\];]],
			capture_group = 1
		}
	},
	solo_missions_mission_header_global = {
		description = "SoloMissions mission header minimum players global",
		file = "fmmc_launcher.c",
		LEGACY = {
			value = 794989,
			pattern = [[Global_\d+\.f_\d{3}\[.*?/\*204\*/\]\.f_\d{3}\s+=\s+Global_(\d{6})\.f_(\d)\[.*?/\*(\d{2})\*/\]\.f_75;]],
			capture_group = 1,
			offsets = {
				{
					value = 4,
					capture_group = 2
				},
				{
					value = 95,
					capture_group = 3,
					description = "stride"
				},
			}
		},
		ENHANCED = {
			value = 794989,
			pattern = [[MISC::SET_BIT.*?Global_\d+\.f_\d{4}\[.*?/\*\d+\*/\]\.f_\d{5}\), 0\);[\r\n]?\s+?Global_\d+\.f_(\d+)\[.*?\]\s+=\s+Global_\d+\.f_\d{4}\[.*?\];]],
			capture_group = 1,
			offsets = {
				{
					value = 4,
					capture_group = 2
				},
				{
					value = 95,
					capture_group = 3,
					description = "stride"
				},
			}
		}
	},
	mgh_h3_hack_1 = {
		description = "",
		file = "fm_mission_controller.c",
		LEGACY = {
			value = 54118,
			pattern = [[MISC::CLEAR_BIT\(&.?Local_\d+,\s+12\);[\r\n]\s+func_\d+\(&.?Local_(\d{5}),\s+&.?Local_\d{5}\[.*\/\*2\*\/\],\s+false,\s+joaat\("heist"\),\s+Global_\d{6}\.f_1\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 55028,
			pattern = [[MISC::CLEAR_BIT\(&.?Local_\d+,\s+12\);[\r\n]\s+func_\d+\(&.?Local_(\d{5}),\s+&.?Local_\d{5}\[.*\/\*2\*\/\],\s+false,\s+joaat\("heist"\),\s+Global_\d{6}\.f_1\);]],
			capture_group = 1
		}
	},
	mgh_h3_hack_1_p = {
		description = "",
		file = "am_mp_arc_cab_manager.c",
		LEGACY = {
			value = 2872,
			pattern = [[case\s+0:[\r\n]\s+if\s+\(.?Local_\d+\.f_\d+\s+!=\s+79\s+&&\s+.?Local_\d+\.f_\d+\s+!=\s+80\s+&&\s+.?Local_\d+\.f_\d+\s+!=\s+11\)[\r\n]\s+func_\d+\(&.?Local_(\d{4}),\s+&\(.?Local_\d+\.f_\d+\),\s+4,\s+-1,\s+false\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 2874,
			pattern = [[case\s+0:[\r\n]\s+if\s+\(.?Local_\d+\.f_\d+\s+!=\s+79\s+&&\s+.?Local_\d+\.f_\d+\s+!=\s+80\s+&&\s+.?Local_\d+\.f_\d+\s+!=\s+11\)[\r\n]\s+func_\d+\(&.?Local_(\d{4}),\s+&\(.?Local_\d+\.f_\d+\),\s+4,\s+-1,\s+false\);]],
			capture_group = 1
		}
	},
	mgh_h3_hack_2 = {
		description = "",
		file = "fm_mission_controller.c",
		LEGACY = {
			value = 55188,
			pattern = [[MISC::CLEAR_BIT\(&.?Local_\d+,\s+13\);[\r\n]\s+func_\d+\(&.?Local_(\d{5}),\s+&.?Local_\d{5}\[.*\/\*2\*\/\],\s+false,\s+joaat\("heist"\),\s+Global_\d{6}\.f_1\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 56098,
			pattern = [[MISC::CLEAR_BIT\(&.?Local_\d+,\s+13\);[\r\n]\s+func_\d+\(&.?Local_(\d{5}),\s+&.?Local_\d{5}\[.*\/\*2\*\/\],\s+false,\s+joaat\("heist"\),\s+Global_\d{6}\.f_1\);]],
			capture_group = 1
		}
	},
	mgh_h3_hack_2_p = {
		description = "",
		file = "am_mp_arc_cab_manager.c",
		LEGACY = {
			value = 3877,
			pattern = [[case\s+1:[\r\n]\s+if\s+\(.?Local_\d+\.f_\d+\s+!=\s+79\s+&&\s+.?Local_\d+\.f_\d+\s+!=\s+80\s+&&\s+.?Local_\d+\.f_\d+\s+!=\s+11\)[\r\n]\s+func_\d+\(&.?Local_(\d{4}),\s+&\(.?Local_\d+\.f_\d+\),\s+4,\s+-1,\s+false\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 3879,
			pattern = [[case\s+1:[\r\n]\s+if\s+\(.?Local_\d+\.f_\d+\s+!=\s+79\s+&&\s+.?Local_\d+\.f_\d+\s+!=\s+80\s+&&\s+.?Local_\d+\.f_\d+\s+!=\s+11\)[\r\n]\s+func_\d+\(&.?Local_(\d{4}),\s+&\(.?Local_\d+\.f_\d+\),\s+4,\s+-1,\s+false\);]],
			capture_group = 1
		}
	},
	mgh_h4_hack = {
		description = "",
		file = "fm_mission_controller_2020.c",
		LEGACY = {
			value = 27240,
			pattern = [[MISC::CLEAR_BIT\(&.?Local_\d+,\s+11\);[\r\n]\s+func_\d+\(&.?Local_(\d{5}),\s+&.?Local_\d{5}\[.*\/\*2\*\/\],\s+false,\s+joaat\("heist"\),\s+Global_\d{6}\.f_1\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 27642,
			pattern = [[MISC::CLEAR_BIT\(&.?Local_\d+,\s+11\);[\r\n]\s+func_\d+\(&.?Local_(\d{5}),\s+&.?Local_\d{5}\[.*\/\*2\*\/\],\s+false,\s+joaat\("heist"\),\s+Global_\d{6}\.f_1\);]],
			capture_group = 1
		}
	},
	mgh_fmmc20_local_1 = {
		description = "All casino fingerprints and keyboard access control (+24)",
		file = "fm_mission_controller_2020.c",
		LEGACY = {
			value = 10088,
			pattern = [[if\s+\(func_\d+\(false,\s+false\)\)[\r\n]\s+\{[\r\n]\s+func_\d+\(&.?Local_(\d+),\s+\w+\(.?Local_\d{5}\.f_\d{4},\s+3\),\s+true\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 10490,
			pattern = [[if\s+\(func_\d+\(false,\s+false\)\)[\r\n]\s+\{[\r\n]\s+func_\d+\(&.?Local_(\d+),\s+\w+\(.?Local_\d{5}\.f_\d{4},\s+3\),\s+true\);]],
			capture_group = 1
		}
	},
	mgh_fmmc20_local_2 = {
		description = "All casino fingerprints and keyboard access control",
		file = "fm_mission_controller_2020.c",
		LEGACY = {
			value = 1021,
			pattern = [[switch\s+\(.*?Local_(\d{4})\.f_(\d{3})\)[\r\n]\s+\{[\r\n]\s+case\s+0:]],
			capture_group = 1,
			offsets = {
				{
					value = 135,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 1023,
			pattern = [[switch\s+\(.*?Local_(\d{4})\.f_(\d{3})\)[\r\n]\s+\{[\r\n]\s+case\s+0:]],
			capture_group = 1,
			offsets = {
				{
					value = 135,
					capture_group = 2
				}
			}
		}
	},
	mgh_fmmc20_local_3 = {
		description = "All casino fingerprints and keyboard access control",
		file = "fm_mission_controller_2020.c",
		LEGACY = {
			value = 31109,
			pattern = [[if\s+\(.?Local_(\d{5})\s+==\s+4\)[\r\n]\s+func_\d+\("UT_WELD_HELP",\s+"UT_WELD_HELP_MK",.*,\s+true]],
			capture_group = 1
		},
		ENHANCED = {
			value = 31511,
			pattern = [[if\s+\(.?Local_(\d{5})\s+==\s+4\)[\r\n]\s+func_\d+\("UT_WELD_HELP",\s+"UT_WELD_HELP_MK",.*,\s+true]],
			capture_group = 1
		}
	},
	mgh_fmmc20_local_4 = {
		description = "All casino fingerprints and keyboard access control",
		file = "fm_mission_controller_2020.c",
		LEGACY = {
			value = 32349,
			pattern = [[Local_\d+\.f_3\s+=\s+.*\.f_13\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 32751,
			pattern = [[Local_\d+\.f_3\s+=\s+.*\.f_13\);]],
			capture_group = 1
		}
	},
	mgh_fmmc20_local_5 = {
		description = "All casino fingerprints and keyboard access control",
		file = "fm_mission_controller_2020.c",
		LEGACY = {
			value = 1266,
			pattern = [[AUDIO::PLAY_SOUND_FRONTEND\(-1,\s+"Input_Highlight",\s+.?Local_\d+,\s+true\);[\r\n]\s+MISC::SET_BIT.*Local_(\d{4})\.f_\d{2}\),\s+5\s+\+\s+.*\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1268,
			pattern = [[AUDIO::PLAY_SOUND_FRONTEND\(-1,\s+"Input_Highlight",\s+.?Local_\d+,\s+true\);[\r\n]\s+MISC::SET_BIT.*Local_(\d{4})\.f_\d{2}\),\s+5\s+\+\s+.*\);]],
			capture_group = 1
		}
	},
	mgh_fmmc20_local_6 = {
		description = "voltlab Complete immediately. this:set_int(this:at(1):get_int()); this:at(2):set_int(3)",
		file = "fm_mission_controller_2020.c",
		LEGACY = {
			value = 1764,
			pattern = [[if\s+\(.?Local_\d{4}\s+==\s+.?Local_(\d{4})\)[\r\n]\s+AUDIO::PLAY_SOUND_FRONTEND\(-1,\s+"All_Connected_Correct",]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1766,
			pattern = [[if\s+\(.?Local_\d{4}\s+==\s+.?Local_(\d{4})\)[\r\n]\s+AUDIO::PLAY_SOUND_FRONTEND\(-1,\s+"All_Connected_Correct",]],
			capture_group = 1
		}
	},
	mgh_fmmc20_local_7 = {
		description = "h3 pwd box",
		file = "fm_mission_controller_2020.c",
		LEGACY = {
			value = 32323,
			pattern = [[if\s+\(.?Local_\d{5}\.f_\d{4}\[.*\]\s+==.*Local_\d{5}\s+&&\s+.?Local_(\d{5})\s+>\s+0\)[\r\n]\s+NETWORK::NETWORK_REQUEST_CONTROL_OF_ENTITY]],
			capture_group = 1
		},
		ENHANCED = {
			value = 32725,
			pattern = [[if\s+\(.?Local_\d{5}\.f_\d{4}\[.*\]\s+==.*Local_\d{5}\s+&&\s+.?Local_(\d{5})\s+>\s+0\)[\r\n]\s+NETWORK::NETWORK_REQUEST_CONTROL_OF_ENTITY]],
			capture_group = 1
		}
	},
	mgh_fmmc_v3_local_1 = {
		description = "(+24)",
		file = "fm_mission_controller_v3.c",
		LEGACY = {
			value = 10111,
			pattern = [[if\s+\(func_\d+\(false,\s+false\)\)[\r\n]\s+\{[\r\n]\s+func_\d+\(&.?Local_(\d+),\s+\w+\(.?Local_\d{5}\.f_\d{4},\s+3\),\s+true\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 10513,
			pattern = [[if\s+\(func_\d+\(false,\s+false\)\)[\r\n]\s+\{[\r\n]\s+func_\d+\(&.?Local_(\d+),\s+\w+\(.?Local_\d{5}\.f_\d{4},\s+3\),\s+true\);]],
			capture_group = 1
		}
	},
	mgh_fmmc_v3_local_2 = {
		description = "",
		file = "fm_mission_controller_v3.c",
		LEGACY = {
			value = 1021,
			pattern = [[switch\s+\(.*?Local_(\d{4})\.f_(\d{3})\)[\r\n]\s+\{[\r\n]\s+case\s+0:]],
			capture_group = 1,
			offsets = {
				{
					value = 135,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 1023,
			pattern = [[switch\s+\(.*?Local_(\d{4})\.f_(\d{3})\)[\r\n]\s+\{[\r\n]\s+case\s+0:]],
			capture_group = 1,
			offsets = {
				{
					value = 135,
					capture_group = 2
				}
			}
		}
	},
	mgh_fmmc_v3_local_3 = {
		description = "",
		file = "fm_mission_controller_v3.c",
		LEGACY = {
			value = 31201,
			pattern = [[if\s+\(.?Local_(\d{5})\s+==\s+4\)[\r\n]\s+func_\d+\("UT_WELD_HELP",\s+"UT_WELD_HELP_MK",.*,\s+true]],
			capture_group = 1
		},
		ENHANCED = {
			value = 31603,
			pattern = [[if\s+\(.?Local_(\d{5})\s+==\s+4\)[\r\n]\s+func_\d+\("UT_WELD_HELP",\s+"UT_WELD_HELP_MK",.*,\s+true]],
			capture_group = 1
		}
	},
	mgh_fmmc_v3_local_4 = {
		description = "",
		file = "fm_mission_controller_v3.c",
		LEGACY = {
			value = 32453,
			pattern = [[Local_(\d+)\[.*/\*13\*/\]\.f_3\s+=.*\.f_13\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 32855,
			pattern = [[Local_(\d+)\[.*/\*13\*/\]\.f_3\s+=.*\.f_13\);]],
			capture_group = 1
		}
	},
	mgh_fmmc_v3_local_5 = {
		description = "",
		file = "fm_mission_controller_v3.c",
		LEGACY = {
			value = 1266,
			pattern = [[AUDIO::PLAY_SOUND_FRONTEND\(-1,\s+"Input_Highlight",\s+.?Local_\d+,\s+true\);[\r\n]\s+MISC::SET_BIT.*Local_(\d{4})\.f_\d{2}\),\s+5\s+\+\s+.*\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1268,
			pattern = [[AUDIO::PLAY_SOUND_FRONTEND\(-1,\s+"Input_Highlight",\s+.?Local_\d+,\s+true\);[\r\n]\s+MISC::SET_BIT.*Local_(\d{4})\.f_\d{2}\),\s+5\s+\+\s+.*\);]],
			capture_group = 1
		}
	},
	mgh_fmmc_v3_local_6 = {
		description = "",
		file = "fm_mission_controller_v3.c",
		LEGACY = {
			value = 1764,
			pattern = [[if\s+\(.?Local_\d{4}\s+==\s+.?Local_(\d{4})\)[\r\n]\s+AUDIO::PLAY_SOUND_FRONTEND\(-1,\s+"All_Connected_Correct",]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1766,
			pattern = [[if\s+\(.?Local_\d{4}\s+==\s+.?Local_(\d{4})\)[\r\n]\s+AUDIO::PLAY_SOUND_FRONTEND\(-1,\s+"All_Connected_Correct",]],
			capture_group = 1
		}
	},
	mgh_fmmc_v3_local_7 = {
		description = "",
		file = "fm_mission_controller_v3.c",
		LEGACY = {
			value = 32415,
			pattern = [[if\s+\(.?Local_\d{5}\.f_\d{4}\[.*\]\s+==.*Local_\d{5}\s+&&\s+.?Local_(\d{5})\s+>\s+0\)[\r\n]\s+NETWORK::NETWORK_REQUEST_CONTROL_OF_ENTITY]],
			capture_group = 1
		},
		ENHANCED = {
			value = 32817,
			pattern = [[if\s+\(.?Local_\d{5}\.f_\d{4}\[.*\]\s+==.*Local_\d{5}\s+&&\s+.?Local_(\d{5})\s+>\s+0\)[\r\n]\s+NETWORK::NETWORK_REQUEST_CONTROL_OF_ENTITY]],
			capture_group = 1
		}
	},
	mgh_fmmc_v3_local_8 = {
		description = "data crack",
		file = "fm_mission_controller_v3.c",
		LEGACY = {
			value = 1386,
			pattern = [[.?Local(_\d+)\[7\s+\/\*4\*\/\]\s+=\s+0;[\r\n]\s+MISC::CLEAR_BIT\(&.?Local_\d{5},\s+26\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1388,
			pattern = [[.?Local(_\d+)\[7\s+\/\*4\*\/\]\s+=\s+0;[\r\n]\s+MISC::CLEAR_BIT\(&.?Local_\d{5},\s+26\);]],
			capture_group = 1
		}
	},
	mgh_fmmc_v3_local_9 = {
		description = "",
		file = "fm_mission_controller_v3.c",
		LEGACY = {
			value = 26464,
			pattern = [[MISC::CLEAR_BIT\(&.?Local_\d+,\s+10\);[\r\n]\s+func_\d+\(&.?Local_(\d{5}),\s+&.?Local_\d{5}\[.*\/\*2\*\/\],\s+false,\s+joaat\("heist"\),\s+Global_\d{6}\.f_1\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 26866,
			pattern = [[MISC::CLEAR_BIT\(&.?Local_\d+,\s+10\);[\r\n]\s+func_\d+\(&.?Local_(\d{5}),\s+&.?Local_\d{5}\[.*\/\*2\*\/\],\s+false,\s+joaat\("heist"\),\s+Global_\d{6}\.f_1\);]],
			capture_group = 1
		}
	},
	mgh_fmmc_v3_local_10 = {
		description = "",
		file = "fm_mission_controller_v3.c",
		LEGACY = {
			value = 27512,
			pattern = [[COPY_SCRIPT_STRUCT\(.*\);[\r\n]\s+func_\d+\(&.*?Local_(\d+),\s+&.?Local_\d+\[.*/\*2\*/\],.*Global_\d+\.f_1\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 27914,
			pattern = [[COPY_SCRIPT_STRUCT\(.*\);[\r\n]\s+func_\d+\(&.*?Local_(\d+),\s+&.?Local_\d+\[.*/\*2\*/\],.*Global_\d+\.f_1\);]],
			capture_group = 1
		}
	},
	mgh_fmmc_v3_local_11 = {
		description = "k26 access code",
		file = "fm_mission_controller_v3.c",
		LEGACY = {
			value = 32416,
			pattern = [[Local_(\d+)\.f_9\s+=\s+GRAPHICS::REQUEST_SCALEFORM_MOVIE\("DIGITAL_SAFE_DISPLAY"\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 32818,
			pattern = [[Local_(\d+)\.f_9\s+=\s+GRAPHICS::REQUEST_SCALEFORM_MOVIE\("DIGITAL_SAFE_DISPLAY"\);]],
			capture_group = 1
		}
	},
	mgh_fmmc_local_1 = {
		description = "IP address minigame",
		file = "fm_mission_controller.c",
		LEGACY = {
			value = 187,
			pattern = [[AUDIO::PLAY_SOUND_FRONTEND\(.?Local_(\d{3})\[0\],\s+"HACKING_COUNTDOWN_IP_FIND",\s+0,]],
			capture_group = 1
		},
		ENHANCED = {
			value = 189,
			pattern = [[AUDIO::PLAY_SOUND_FRONTEND\(.?Local_(\d{3})\[0\],\s+"HACKING_COUNTDOWN_IP_FIND",\s+0,]],
			capture_group = 1
		}
	},
	mgh_fmmc_local_2 = {
		description = "IP address minigame",
		file = "fm_mission_controller.c",
		LEGACY = {
			value = 184,
			pattern = [[if\s+\(.?Local_(\d{3})\s==\s+0\)[\r\n]\s+\{[\r\n].*\("H_USE_PC8", -1\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 186,
			pattern = [[AUDIO::PLAY_SOUND_FRONTEND\(.?Local_(\d{3})\[0\],\s+"HACKING_COUNTDOWN_IP_FIND",\s+0,]],
			capture_group = 1
		}
	},
	mgh_fmmc_local_3 = {
		description = "IP address minigame",
		file = "fm_mission_controller.c",
		LEGACY = {
			value = 199,
			pattern = [[if\s+\(.?Local_(\d{3})\s+== 5\s+\|\|\s+.?Local_(\d{3})\s+==\s+6\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 201,
			pattern = [[if\s+\(.?Local_(\d{3})\s+== 5\s+\|\|\s+.?Local_(\d{3})\s+==\s+6\)]],
			capture_group = 1
		}
	},
	mgh_fmmc_local_4 = {
		description = "IP address minigame",
		file = "fm_mission_controller.c",
		LEGACY = {
			value = 1312,
			pattern = [[switch\s+\(.*?Local_(\d{4})\.f_(\d{3})\)[\r\n]\s+\{[\r\n]\s+case\s+0:]],
			capture_group = 1,
			offsets = {
				{
					value = 135,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 1314,
			pattern = [[if\s+\(.?Local_(\d{3})\s+== 5\s+\|\|\s+.?Local_(\d{3})\s+==\s+6\)]],
			capture_group = 1,
			offsets = {
				{
					value = 135,
					capture_group = 2
				}
			}
		}
	},
	mgh_fmmc_local_5 = {
		description = "IP address minigame (+24)",
		file = "fm_mission_controller.c",
		LEGACY = {
			value = 11837,
			pattern = [[if\s+\(func_\w+\(&.?Local_(\d{5})\)\)[\r\n].*if\s+\(!PED::IS_PED_RUNNING_MOBILE_PHONE_TASK]],
			capture_group = 1
		},
		ENHANCED = {
			value = 12239,
			pattern = [[if\s+\(func_\w+\(&.?Local_(\d{5})\)\)[\r\n].*if\s+\(!PED::IS_PED_RUNNING_MOBILE_PHONE_TASK]],
			capture_group = 1
		}
	},
	mgh_fmmc_local_6 = {
		description = "skip drilling",
		file = "fm_mission_controller.c",
		LEGACY = {
			value = 10125,
			pattern = [[if\s+\(!ENTITY::IS_ENTITY_ATTACHED\(\S+\)\s+&&\s+.?Local_(\d+)\.f_\d+\s+>\s+0\.08f\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 10527,
			pattern = [[if\s+\(!ENTITY::IS_ENTITY_ATTACHED\(\S+\)\s+&&\s+.?Local_(\d+)\.f_\d+\s+>\s+0\.08f\)]],
			capture_group = 1
		}
	},
	mgh_fmmc_local_7 = {
		description = "skip drilling",
		file = "fm_mission_controller.c",
		LEGACY = {
			value = 10165,
			pattern = [[else\s+if\s+\(.?Local_(\d{5})\.f_7\s+==\s+.*?Local_\d{5}\.f_37\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 10567,
			pattern = [[else\s+if\s+\(.?Local_(\d{5})\.f_7\s+==\s+.*?Local_\d{5}\.f_37\)]],
			capture_group = 1
		}
	},
	mgh_fmmc_local_8 = {
		description = "ch dkc",
		file = "fm_mission_controller.c",
		LEGACY = {
			value = 63445,
			pattern = [[\s+>\s+8800\)[\r\n]\s+MISC::SET_BIT\(&.?Local_(\d{5}),\s+1\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 64655,
			pattern = [[\s+>\s+8800\)[\r\n]\s+MISC::SET_BIT\(&.?Local_(\d{5}),\s+1\);]],
			capture_group = 1
		}
	},
	mgh_fmmc_local_9 = {
		description = "ch dkc",
		file = "fm_mission_controller.c",
		LEGACY = {
			value = 1586,
			pattern = [[AUDIO::SET_VARIABLE_ON_SOUND\(.?Local_\d+,\s+"Damage",\s+.?Local_\d+\);[\r\n]\s+switch\s+\(.?Local_(\d{4})\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 1588,
			pattern = [[AUDIO::SET_VARIABLE_ON_SOUND\(.?Local_\d+,\s+"Damage",\s+.?Local_\d+\);[\r\n]\s+switch\s+\(.?Local_(\d{4})\)]],
			capture_group = 1
		}
	},
	mgh_fm_c_ih_1 = {
		description = "this:set_int(this:at(1):get_int()); this:at(2):set_int(3)",
		file = "fm_content_island_heist.c",
		LEGACY = {
			value = 798,
			pattern = [[if\s+\(.?Local_\d{3}\s+==\s+.?Local_(\d{3})\)[\r\n].*AUDIO::PLAY_SOUND_FRONTEND\(-1,\s+"All_Connected_Correct",.*,\s+true\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 800,
			pattern = [[if\s+\(.?Local_\d{3}\s+==\s+.?Local_(\d{3})\)[\r\n].*AUDIO::PLAY_SOUND_FRONTEND\(-1,\s+"All_Connected_Correct",.*,\s+true\);]],
			capture_group = 1
		}
	},
	mgh_fm_c_ih_2 = {
		description = "+24",
		file = "fm_content_island_heist.c",
		LEGACY = {
			value = 10279,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+;[\r\n]\s+return -1;]],
			capture_group = 1
		},
		ENHANCED = {
			value = 10281,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+;[\r\n]\s+return -1;]],
			capture_group = 1
		}
	},
	mgh_fm_c_vehrob_prep_1 = {
		description = "this:set_int(this:at(1):get_int()); this:at(2):set_int(3)",
		file = "fm_content_vehrob_prep.c",
		LEGACY = {
			value = 579,
			pattern = [[if\s+\(.?Local_\d{3}\s+==\s+.?Local_(\d{3})\)[\r\n].*AUDIO::PLAY_SOUND_FRONTEND\(-1,\s+"All_Connected_Correct",.*,\s+true\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 581,
			pattern = [[if\s+\(.?Local_\d{3}\s+==\s+.?Local_(\d{3})\)[\r\n].*AUDIO::PLAY_SOUND_FRONTEND\(-1,\s+"All_Connected_Correct",.*,\s+true\);]],
			capture_group = 1
		}
	},
	mgh_fm_c_vehrob_prep_2 = {
		description = "+24",
		file = "fm_content_vehrob_prep.c",
		LEGACY = {
			value = 9338,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+;[\r\n]\s+return -1;]],
			capture_group = 1
		},
		ENHANCED = {
			value = 9340,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+;[\r\n]\s+return -1;]],
			capture_group = 1
		}
	},
	mgh_am_mp_arc_cab_magr_1 = {
		description = "this:set_int(this:at(1):get_int()); this:at(2):set_int(3)",
		file = "am_mp_arc_cab_manager.c",
		LEGACY = {
			value = 487,
			pattern = [[if\s+\(.?Local_\d{3}\s+==\s+.?Local_(\d{3})\)[\r\n].*AUDIO::PLAY_SOUND_FRONTEND\(-1,\s+"All_Connected_Correct",.*,\s+true\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 489,
			pattern = [[if\s+\(.?Local_\d{3}\s+==\s+.?Local_(\d{3})\)[\r\n].*AUDIO::PLAY_SOUND_FRONTEND\(-1,\s+"All_Connected_Correct",.*,\s+true\);]],
			capture_group = 1
		}
	},
	mgh_fm_c_bb = {
		description = "this:at(24):set_int(7)",
		file = "fm_content_business_battles.c",
		LEGACY = {
			value = 4251,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+;[\r\n]\s+return -1;]],
			capture_group = 1
		},
		ENHANCED = {
			value = 4253,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+;[\r\n]\s+return -1;]],
			capture_group = 1
		}
	},
	mgh_hotwire = {
		description = "",
		file = "am_mp_hotwire.c",
		LEGACY = {
			value = 310,
			pattern = [[else\s+if.*Local_(\d{3}),\s+3000,.*\)[\r\n]\s+\{[\r\n]\s+.*\(.*,\s+0\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 312,
			pattern = [[else\s+if.*Local_(\d{3}),\s+3000,.*\)[\r\n]\s+\{[\r\n]\s+.*\(.*,\s+0\);]],
			capture_group = 1
		}
	},
	mgh_wordhack = {
		description = "offset 53. success is case 5 in func_15",
		file = "word_hack.c",
		LEGACY = {
			value = 68,
			pattern = [[func_1\(.*,\s+&Global_\d+,\s+&.?Local_(\d{2}),\s+&.?Local_\d+\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 68,
			pattern = [[func_1\(.*,\s+&Global_\d+,\s+&.?Local_(\d{2}),\s+&.?Local_\d+\);]],
			capture_group = 1
		}
	},
	mgh_circ_block_hack = {
		description = "offset 9. success is case 2 in func_1",
		file = "circuitblockhack.c",
		LEGACY = {
			value = 72,
			pattern = [[switch\s+\(.?Local_(\d{2})\.f_(\d{1})\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 72,
			pattern = [[switch\s+\(.?Local_(\d{2})\.f_(\d{1})\)]],
			capture_group = 1
		}
	},
	mgh_fm_c_hh_finale = {
		description = "+1",
		file = "fm_content_hacker_house_finale.c",
		LEGACY = {
			value = 6062,
			pattern = [[switch\s+\(.?Local_(\d{4})\.f_\d{4}\[.*\/\*5\*\/\]\)]],
			capture_group = 1
		},
		ENHANCED = {
			value = 6064,
			pattern = [[switch\s+\(.?Local_(\d{4})\.f_\d{4}\[.*\/\*5\*\/\]\)]],
			capture_group = 1
		}
	},
	mgh_fm_c_hwp = {
		description = "",
		file = "fm_content_hacker_whistle_prep.c",
		LEGACY = {
			value = 5230,
			pattern = [[func_\d+\(&.?Local_\d{4}, 5, 5, 10, 10, 8, 10, 0, 0,]],
			capture_group = 1
		},
		ENHANCED = {
			value = 5232,
			pattern = [[func_\d+\(&.?Local_\d{4}, 5, 5, 10, 10, 8, 10, 0, 0,]],
			capture_group = 1
		}
	},
	mgh_ah3b = {
		description = "",
		file = "agency_heist3b.c",
		LEGACY = {
			value = 6229,
			pattern = [[func_\d+\(&.?Local_\d{4}, 5, 5, 50, 10, 8, 0, 0, 0,]],
			capture_group = 1
		},
		ENHANCED = {
			value = 6229,
			pattern = [[func_\d+\(&.?Local_\d{4}, 5, 5, 50, 10, 8, 0, 0, 0,]],
			capture_group = 1
		}
	},
	mgh_bb_sell = {
		description = "",
		file = "business_battles_sell.c",
		LEGACY = {
			value = 463,
			pattern = [[MISC::SET_BIT\(&.?Local_(\d+), 0\);[\r\n]\s+MISC::SET_BIT\(&\(.?Local_\d+\.f_1\), 0\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 465,
			pattern = [[MISC::SET_BIT\(&.?Local_(\d+), 0\);[\r\n]\s+MISC::SET_BIT\(&\(.?Local_\d+\.f_1\), 0\);]],
			capture_group = 1
		}
	},
	mgh_fm_c_bb_bs = {
		description = "",
		file = "fm_content_business_battles.c",
		LEGACY = {
			value = 4251,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+;[\r\n]\s+return -1;]],
			capture_group = 1
		},
		ENHANCED = {
			value = 4253,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+;[\r\n]\s+return -1;]],
			capture_group = 1
		}
	},
	mgh_fm_c_ih_bs = {
		description = "",
		file = "fm_content_island_heist.c",
		LEGACY = {
			value = 10279,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+;[\r\n]\s+return -1;]],
			capture_group = 1
		},
		ENHANCED = {
			value = 10281,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+;[\r\n]\s+return -1;]],
			capture_group = 1
		}
	},
	mgh_fm_c_vrcp_bs = {
		description = "+2",
		file = "fm_content_vehrob_casino_prize.c",
		LEGACY = {
			value = 7893,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+;[\r\n]\s+return -1;]],
			capture_group = 1
		},
		ENHANCED = {
			value = 7895,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+;[\r\n]\s+return -1;]],
			capture_group = 1
		}
	},
	mgh_fm_c_vrp_bs = {
		description = "",
		file = "fm_content_vehrob_police.c",
		LEGACY = {
			value = 7772,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+\.f_\d+;[\r\n]\s+switch]],
			capture_group = 1
		},
		ENHANCED = {
			value = 7774,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+\.f_\d+;[\r\n]\s+switch]],
			capture_group = 1
		}
	},
	mgh_fm_c_vehrob_prep_bs = {
		description = "",
		file = "fm_content_vehrob_prep.c",
		LEGACY = {
			value = 9338,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+\.f_\d+;[\r\n]\s+switch]],
			capture_group = 1
		},
		ENHANCED = {
			value = 9340,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+\.f_\d+;[\r\n]\s+switch]],
			capture_group = 1
		}
	},
	mgh_fm_c_vip_c_bs = {
		description = "",
		file = "fm_content_vip_contract_1.c",
		LEGACY = {
			value = 7661,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+\.f_\d+;[\r\n]\s+switch]],
			capture_group = 1
		},
		ENHANCED = {
			value = 7663,
			pattern = [[Local_(\d+)\.f_\d+\s+=\s+.?Local_\d+\.f_\d+;[\r\n]\s+switch]],
			capture_group = 1
		}
	},
	mgh_fmmc20_bs = {
		description = "",
		file = "fm_mission_controller_2020.c",
		LEGACY = {
			value = 30325,
			pattern = [[.?Local_\d+\[7\s+\/\*4\*\/\]\s+=\s+0;[\r\n]\s+MISC::CLEAR_BIT\(&.?Local_(\d{5}),\s+26\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 30727,
			pattern = [[.?Local_\d+\[7\s+\/\*4\*\/\]\s+=\s+0;[\r\n]\s+MISC::CLEAR_BIT\(&.?Local_(\d{5}),\s+26\);]],
			capture_group = 1
		}
	},
	mgh_fmmc_v3_bs = {
		description = "",
		file = "fm_mission_controller_2020.c",
		LEGACY = {
			value = 30417,
			pattern = [[.?Local_\d+\[7\s+\/\*4\*\/\]\s+=\s+0;[\r\n]\s+MISC::CLEAR_BIT\(&.?Local_(\d{5}),\s+26\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 30819,
			pattern = [[.?Local_\d+\[7\s+\/\*4\*\/\]\s+=\s+0;[\r\n]\s+MISC::CLEAR_BIT\(&.?Local_(\d{5}),\s+26\);]],
			capture_group = 1
		}
	},
	mgh_fmmc_bs = {
		description = "",
		file = "fm_mission_controller.c",
		LEGACY = {
			value = 9831,
			pattern = [[if\s+\(\*Global_\d{7}\.f_\d{6}\s+!=\s+Global_262145\.f_\d+\)[\r\n]\s+func_\d+\(&.?Local_(\d+),\s+true,\s+true\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 10233,
			pattern = [[if\s+\(\*Global_\d{7}\.f_\d{6}\s+!=\s+Global_262145\.f_\d+\)[\r\n]\s+func_\d+\(&.?Local_(\d+),\s+true,\s+true\);]],
			capture_group = 1
		}
	},
	mgh_gb_cashingout_bs = {
		description = "",
		file = "gb_cashing_out.c",
		LEGACY = {
			value = 433,
			pattern = [[MISC::SET_BIT\(&.?Local_(\d+), 0\);[\r\n]\s+MISC::SET_BIT\(&\(.?Local_\d+\.f_1\), 0\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 435,
			pattern = [[MISC::SET_BIT\(&.?Local_(\d+), 0\);[\r\n]\s+MISC::SET_BIT\(&\(.?Local_\d+\.f_1\), 0\);]],
			capture_group = 1
		}
	},
	mgh_gb_gr_defend_bs = {
		description = "",
		file = "gb_gunrunning_defend.c",
		LEGACY = {
			value = 2293,
			pattern = [[MISC::SET_BIT\(&.?Local_(\d+), 0\);[\r\n]\s+MISC::SET_BIT\(&\(.?Local_\d+\.f_1\), 0\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 2295,
			pattern = [[MISC::SET_BIT\(&.?Local_(\d+), 0\);[\r\n]\s+MISC::SET_BIT\(&\(.?Local_\d+\.f_1\), 0\);]],
			capture_group = 1
		}
	},
	mgh_gb_sightseer_bs = {
		description = "",
		file = "gb_sightseer.c",
		LEGACY = {
			value = 489,
			pattern = [[MISC::SET_BIT\(&.?Local_(\d+), 0\);[\r\n]\s+MISC::SET_BIT\(&\(.?Local_\d+\.f_1\), 0\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 491,
			pattern = [[MISC::SET_BIT\(&.?Local_(\d+), 0\);[\r\n]\s+MISC::SET_BIT\(&\(.?Local_\d+\.f_1\), 0\);]],
			capture_group = 1
		}
	},
	mgh_tmp_v2_global = {
		description = "",
		file = "gb_casino_heist.c",
		LEGACY = {
			value = 2731782,
			pattern = [[func_\w+\(&Global_(\d+),\s+"BBHACK_YET"\s+/\*YETARIAN\*/\);]],
			capture_group = 1
		},
		ENHANCED = {
			value = 2731918,
			pattern = [[MISC::SET_BIT\(&.?Local_(\d+), 0\);[\r\n]\s+MISC::SET_BIT\(&\(.?Local_\d+\.f_1\), 0\);]],
			capture_group = 1
		}
	},
	mgh_stash_house = {
		description = "",
		file = "fm_content_stash_house.c",
		LEGACY = {
			value = 151,
			pattern = [[Local_(\d+)\.f_(\d{2})\[.*/\*2\*/\]\s+=\s+iLocal_(\d+)\.f_(\d{2})\[.*/\*2\*/\]\s+\+\s+\w+0;]],
			capture_group = 1,
			offsets = {
				{
					value = 22,
					capture_group = 2
				}
			}
		},
		ENHANCED = {
			value = 153,
			pattern = [[Local_(\d+)\.f_(\d{2})\[.*/\*2\*/\]\s+=\s+iLocal_(\d+)\.f_(\d{2})\[.*/\*2\*/\]\s+\+\s+\w+0;]],
			capture_group = 1,
			offsets = {
				{
					value = 22,
					capture_group = 2
				}
			}
		}
	},
}
