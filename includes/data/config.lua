---@class Config
local Config <const> = {
	__config_version = "0.2",
	__dev_reset = false,
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
		style = {
			bg_alpha = 0.7,
		},
		moveable = false,
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
	},
	commands_console = {
		key = "F4",
		auto_close = false,
	},
	keyboard_keybinds = {
		gui_toggle = "F5",
		auto_kill = "F7",
		cobra_maneuver = "M",
		enemies_flee = "F8",
		flatbed = "X",
		laser_sights = "L",
		missile_defence = "F9",
		nos = "MOUSE5",
		panik = "F12",
		nos_purge = "X",
		rod = "X",
		drift_mode = "SHIFT",
		trigger_bot = "SHIFT",
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
		trigger_bot = {
			code = 0,
			name = "Unbound"
		},
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
			performance_only = false,
			burble_tune = false,
			launch_control = false,
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
			flatbed = false,
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
		weapon = {},
		world = {
			hide_n_seek = false,
			disable_ocean_waves = false,
			extend_bounds = false,
			disable_flight_music = false,
			disable_wanted_music = false,
			carpool = false,
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
		},
		yrv3 = {
			auto_sell = false,
			autofill_delay = 500,
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
			favorites = {
				---@type table<string, AnimData>
				anims = {},
				---@type table<string, ScenarioData>
				scenarios = {},
				---@type table<string, SyncedSceneData>
				scenes = {},
				clipsets = {},
			},
		},
		entity_forge = {},
	},
}

return Config
