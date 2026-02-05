-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class Config
local Config <const> = {
	backend = {
		debug_mode = false,
		auto_cleanup_entities = false,
		language_index = 1,
		language_code = "en-US",
		language_name = "English"
	},
	ui = {
		disable_tooltips = false,
		disable_sound_feedback = false,
		moveable = false,
		style = {
			bg_alpha = 0.7,
		},
		window_size = {
			__type = "vec2",
			x = 864,
			y = 864,
		},
		window_pos = {
			__type = "vec2",
			x = 0,
			y = 0,
		},
		last_tab = {
			tab_id = 1,
			array_index = 1,
		}
	},
	commands_console = {
		key = "F4",
		auto_close = false,
	},
	keyboard_keybinds = {
		gui_toggle = "F5",
		kill_all_enemies = "F7",
		enemies_flee = "F8",
		-- missile_defence = "F9",
		cobra_maneuver = "X",
		flatbed = "X",
		laser_sights = "L",
		nos = "MOUSE5",
		panik = "F12",
		nos_purge = "X",
		rod = "X",
		drift_mode = "SHIFT",
		-- trigger_bot = "SHIFT",
		veh_mine = "NUMPAD0",
		stop_anim = "G"
	},
	gamepad_keybinds = {
		flatbed = {
			code = 288,
			name = "A"
		},
		laser_sights = {
			code = 303,
			name = "DPAD UP"
		},
		nos = {
			code = 289,
			name = "X"
		},
		nos_purge = {
			code = 288,
			name = "A"
		},
		rod = {
			code = 288,
			name = "A"
		},
		drift_mode = {
			code = 288,
			name = "A"
		},
		-- trigger_bot = {
		-- 	code = 0,
		-- 	name = "Unbound"
		-- },
		veh_mine = {
			code = 0,
			name = "Unbound"
		},
		stop_anim = {
			code = 0,
			name = "Unbound"
		}
	},
	features = {
		self = {
			phone_anims = false,
			mc_alt_bike_anims = false,
			sprint_inside_interiors = false,
			jacking_always_lockpick_anim = false,
			disable_action_mode = false,
			allow_headprops_in_vehicles = false,
			stand_on_veh_roof = false,
			no_carjacking = false,
			crouch = false,
			hands_up = false,
			rod = false,
			clumsy = false,
			ragdoll_sound = false,
			autoheal = {
				enabled = false,
				regen_speed = 1
			},
		},
		vehicle = {
			nos = {
				enabled = false,
				power = 50,
				screen_effect = false,
				sound_effect = false,
				purge = false,
				can_damage_engine = false
			},
			drift = {
				enabled = false,
				mode = 0,
				intensity = 1,
				power = 50,
				smoke_fx = {
					enabled = false,
					color = {
						__type = "vec3",
						x = 1,
						y = 1,
						z = 1,
					}
				},
			},
			bangs_rpm_max = 9000.0,
			bangs_rpm_min = 4000.0,
			performance_only = false,
			burble_tune = false,
			launch_control = false,
			launch_control_mode = 0,
			abs_lights = false,
			subwoofer = false,
			horn_beams = false,
			fast_vehicles = false,
			auto_brake_lights = false,
			iv_exit = false,
			no_wheel_recenter = false,
			no_carjacking = false,
			unbreakable_windows = false,
			flappy_doors = false,
			rgb_lights = {
				enabled = false,
				speed = 1,
			},
			mines = {
				enabled = false,
				selected_type_hash = -647126932, -- spike mines default
			},
			missile_defence = false,
			strong_crash = false,
			auto_lock_doors = false,
			cobra_maneuver = false,
			fast_jets = false,
			no_jet_stall = false,
			no_turbulence = false,
			aircraft_mg = {
				triggerbot = false,
				tiggerbot_range = 200.0,
				manual_aim = false,
				enemies_only = false,
				marker_size = 1.6,
				marker_color = {
					__type = "vec4",
					x = 0,
					y = 1,
					z = 0,
					w = 1,
				}
			},
			flares = false,
			drift_minigame = {
				enabled = false,
				score_sound = false,
				player_best = 0
			},
			no_engine_brake = false,
			kers_boost = false,
			offroad_abilities = false,
			rallye_tyres = false,
			no_traction_control = false,
			low_speed_wheelies = false,
			rocket_boost = false,
			jump_capability = false,
			parachute = false,
			steer_rear_wheels = false,
			steer_handbrake = false,
			stancer = {
				---@type table<string, table<integer, StanceObject>>
				saved_models = {},
				auto_apply_saved = false,
			},
		},
		speedometer = {
			enabled = false,
			speed_unit = 0,
			radius = 160,
			pos = {
				__type = "vec2",
				x = 0.0,
				y = 0.0
			},
			colors = {
				circle = 0xFF313195,
				circle_bg = 0x66090909,
				markings = 0xFFC7C7C7,
				text = 0xDDFFFFFF,
				needle = 0xFF3636FF,
				needle_base = 0xFF111111,
			},
		},
		flatbed = {
			enabled = false,
			tow_everything = false,
			show_towing_position = false,
			show_esp = false,
		},
		weapon = {
			magic_bullet = false,
			laser_sights = {
				enabled = false,
				keybind = "L",
				ray_length = 500,
				color = {
					__type = "vec4",
					x = 1,
					y = 0,
					z = 0,
					w = 0.9
				}
			},
			katana = {
				enabled = false,
				model = 0x958A4A8F,
				name = "Baseball Bat"
			},
		},
		world = {
			hide_n_seek = false,
			disable_ocean_waves = false,
			extend_bounds = false,
			disable_flight_music = false,
			disable_wanted_music = false,
			carpool = false,
			public_enemy = false,
			kamikaze_drivers = false,
		},
		dunk = {
			bypass_casino_bans = false,
			force_poker_cards = false,
			set_dealers_poker_cards = false,
			force_roulette_wheel = false,
			rig_slot_machine = false,
			autoplay_slots = false,
			cap_slot_machine_chips = false,
			ch_cart_autograb = false,
			autoplay_slots_delay_random = false,
			slot_machine_cap = 0,
			autoplay_slots_delay = 500,
		},
		yrv3 = {
			autofill_delay = 500,
			auto_sell = false,
			hangar_cd = false,
			nc_management_cd = false,
			nc_vip_mission_chance = false,
			security_missions_cd = false,
			ie_vehicle_steal_cd = false,
			ie_vehicle_sell_cd = false,
			ceo_crate_buy_cd = false,
			ceo_crate_sell_cd = false,
			dax_work_cd = false,
			garment_rob_cd = false,
			cfr_cd = false,
			cwash_legal_work_cd = false,
			cwash_illegal_work_cd = false,
			weedshop_legal_work_cd = false,
			weedshop_illegal_work_cd = false,
			helitours_legal_work_cd = false,
			helitours_illegal_work_cd = false,
			nc_always_popular = false,
			sy_always_max_income = false,
			sy_disable_rob_cd = false,
			sy_disable_rob_weekly_cd = false,
			safe_loop_warn_ack = false,
		},
		bsv2 = {
			escort_groups = {
				{
					members = {
						{
							modelHash = 3882958867,
							name = "Levon Termendzhyan",
							weapon = 453432689
						},
						{
							modelHash = 4255728232,
							name = "Armen Petrosyan",
							weapon = 453432689
						},
						{
							modelHash = 4058522530,
							name = "Yanni",
							weapon = 453432689
						}
					},
					name = "Armenian Mobsters",
					vehicleModel = 83136452
				},
				{
					members = {
						{
							modelHash = 42647445,
							name = "Beretta Von PewPew",
							weapon = 3220176749
						},
						{
							modelHash = 2168724337,
							name = "Big Booty Iggy",
							weapon = 3220176749
						},
						{
							modelHash = 2934601397,
							name = "Sasha Slasha",
							weapon = 3220176749
						}
					},
					name = "Bad Bitches",
					vehicleModel = 461465043
				},
				{
					members = {
						{
							modelHash = 1631478380,
							name = "Jack Reacher",
							weapon = 2210333304
						},
						{
							modelHash = 1349953339,
							name = "Ethan Hunt",
							weapon = 2210333304
						},
						{
							modelHash = 3019107892,
							name = "Sam Fisher",
							weapon = 2210333304
						}
					},
					name = "Private Mercenaries",
					vehicleModel = 2370534026
				},
				{
					members = {
						{
							modelHash = 2572894111,
							name = "Ovidio Guzman",
							weapon = 3220176749
						},
						{
							modelHash = 2127932792,
							name = "Popeye",
							weapon = 3220176749
						},
						{
							modelHash = 3870061732,
							name = "El Sueno",
							weapon = 3220176749
						}
					},
					name = "Sicarios",
					vehicleModel = 1254014755
				},
				{
					members = {
						{
							modelHash = 4049719826,
							name = "Arthur Bishop",
							weapon = 2210333304
						},
						{
							modelHash = 691061163,
							name = "Luke Wright",
							weapon = 2210333304
						},
						{
							modelHash = 1442749254,
							name = "Frank Martin",
							weapon = 2210333304
						}
					},
					name = "VIP Security",
					vehicleModel = 666166960
				}
			},
		},
		yim_actions = {
			auto_close_ped_window = false,
			disable_props = false,
			disable_ptfx = false,
			disable_sfx = false,
			favorites = {
				---@type table<string, AnimData>
				anims = {},
				---@type table<string, ScenarioData>
				scenarios = {},
				---@type table<string, SyncedSceneData>
				scenes = {},
				clipsets = {},
			},
			---@type table<string, ActionCommandData>
			action_commands = {},
		},
		entity_forge = {
			---@type table<hash, {name: string, entityType: eEntityType}>
			favorites = {},
			---@type table<string, ForgeEntity>
			forged_entities = {},
		},
	},
}

return Config
