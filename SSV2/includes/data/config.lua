-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


require("includes.classes.Vector2")
require("includes.classes.Vector3")
require("includes.classes.Vector4")

local Keybind = require("includes.structs.Keybind")


---@class Config
local Config <const> = {
	backend = {
		debug_mode = false,
		auto_cleanup_entities = false,
		language_index = 1,
		use_game_language = false
	},
	ui = {
		disable_tooltips = false,
		disable_sound_feedback = false,
		moveable = false,
		style = {
			bg_alpha = 0.7,
			theme = "Synthwave"
		},
		window_size = vec2:new(864, 864),
		window_pos = vec2:new(1, 1),
		last_tab = {
			tab_id = 1,
			array_index = 1,
		}
	},
	commands_console = { auto_close = false },
	keybinds = {
		gui_toggle = Keybind:new("Toggle GUI",
			{
				keyboard_binding = {
					key = { name = "F5", code = 0x74 }
				},
				controller_binding = {
					key = { name = "Unbound", code = 0 }
				},
			},
			{
				no_gamepad = true,
				is_exclusive = true,
				repeat_on_hold = false,
				allow_unbind = false
			}
		),
		commands_console_toggle = Keybind:new("Toggle Commands Console",
			{
				keyboard_binding = {
					key = { name = "F4", code = 0x73 }
				},
				controller_binding = {
					key = { name = "Unbound", code = 0 }
				},
			},
			{
				no_gamepad = true,
				is_exclusive = true,
				repeat_on_hold = false,
				allow_unbind = false
			}
		),
		kill_all_enemies = Keybind:new("Kill All Enemies",
			{
				keyboard_binding = {
					key = { name = "F7", code = 0x76 }
				},
				controller_binding = {
					key = { name = "Unbound", code = 0 }
				},
			}
		),
		enemies_flee = Keybind:new("Enemies Flee",
			{
				keyboard_binding = {
					key = { name = "F8", code = 0x77 }
				},
				controller_binding = {
					key = { name = "Unbound", code = 0 }
				},
			}
		),
		cobra_maneuver = Keybind:new("Cobra Maneuver",
			{
				keyboard_binding = {
					key = { name = "X", code = 0x58 }
				},
				controller_binding = {
					key = { name = "Unbound", code = 0 }
				},
			}
		),
		flatbed_tow = Keybind:new("Flatbed Tow",
			{
				keyboard_binding = {
					key = { name = "X", code = 0x58 }
				},
				controller_binding = {
					key = { name = "A", code = 288 }
				},
			}
		),
		nos_purge = Keybind:new("NOS Purge",
			{
				keyboard_binding = {
					key = { name = "X", code = 0x58 }
				},
				controller_binding = {
					key = { name = "A", code = 288 }
				},
			}
		),
		rod = Keybind:new("Ragdoll On Demand",
			{
				keyboard_binding = {
					key = { name = "X", code = 0x58 }
				},
				controller_binding = {
					key = { name = "A", code = 288 }
				},
			}
		),
		laser_sights = Keybind:new("Laser Sights",
			{
				keyboard_binding = {
					key = { name = "L", code = 0x4C }
				},
				controller_binding = {
					key = { name = "DPAD UP", code = 303 }
				},
			}
		),
		nos = Keybind:new("NOS",
			{
				keyboard_binding = {
					key = { name = "MOUSE5", code = 0x20040 }
				},
				controller_binding = {
					key = { name = "X", code = 289 }
				},
			}
		),
		rolling_launch = Keybind:new("Rolling Anti-Lag",
			{
				keyboard_binding = {
					key = { name = "N", code = 0x4E }
				},
				controller_binding = {
					key = { name = "Unbound", code = 0 }
				},
			}
		),
		panik = Keybind:new("PANIQUE!!!",
			{
				keyboard_binding = {
					key = { name = "F12", code = 0x7B },
					modifier = { name = "Control", code = 0x11 }
				},
				controller_binding = {
					key = { name = "Unbound", code = 0 }
				},
			},
			{ allow_unbind = false }
		),
		drift_mode = Keybind:new("Drift Mode",
			{
				keyboard_binding = {
					key = { name = "SHIFT", code = 0x10 }
				},
				controller_binding = {
					key = { name = "A", code = 288 }
				},
			}
		),
		stop_anim = Keybind:new("Stop Animation/Scenario",
			{
				keyboard_binding = {
					key = { name = "G", code = 0x47 }
				},
				controller_binding = {
					key = { name = "Unbound", code = 0 }
				},
			}
		),
		veh_mine = Keybind:new("Deploy Vehicle Mines",
			{
				keyboard_binding = {
					key = { name = "NUMPAD0", code = 0x60 }
				},
				controller_binding = {
					key = { name = "Unbound", code = 0 }
				},
			}
		),
		shift_up = Keybind:new("ManualGearbox: Shift Up",
			{
				keyboard_binding = {
					key = { name = "NUMPAD9", code = 0x69 }
				},
				controller_binding = {
					key = { name = "Unbound", code = 0 }
				},
			},
			{ is_exclusive = true }
		),
		shift_down = Keybind:new("ManualGearbox: Shift Down",
			{
				keyboard_binding = {
					key = { name = "NUMPAD3", code = 0x63 }
				},
				controller_binding = {
					key = { name = "Unbound", code = 0 }
				},
			},
			{ is_exclusive = true }
		),
		clutch = Keybind:new("ManualGearbox: Clutch",
			{
				keyboard_binding = {
					key = { name = "NUMPAD5", code = 0x65 }
				},
				controller_binding = {
					key = { name = "Unbound", code = 0 }
				},
			},
			{ is_exclusive = true }
		),
		engine_start_stop = Keybind:new("ManualGearbox: Engine Start/Stop",
			{
				keyboard_binding = {
					key = { name = "NUMPAD1", code = 0x61 }
				},
				controller_binding = {
					key = { name = "Unbound", code = 0 }
				},
			},
			{ is_exclusive = true }
		),
		veh_ram_fwd = Keybind:new("Vehicle Ram Forward",
			{
				keyboard_binding = {
					key = { name = "NUMPAD8", code = 0x68 }
				},
				controller_binding = {
					key = { name = "Unbound", code = 0 }
				},
			},
			{ is_exclusive = true }
		),
		veh_ram_left = Keybind:new("Vehicle Ram Left",
			{
				keyboard_binding = {
					key = { name = "NUMPAD4", code = 0x64 }
				},
				controller_binding = {
					key = { name = "Unbound", code = 0 }
				},
			},
			{ is_exclusive = true }
		),
		veh_ram_right = Keybind:new("Vehicle Ram Left",
			{
				keyboard_binding = {
					key = { name = "NUMPAD6", code = 0x66 }
				},
				controller_binding = {
					key = { name = "Unbound", code = 0 }
				},
			},
			{ is_exclusive = true }
		),
		minigamehack = Keybind:new("MiniGameHack",
			{
				keyboard_binding = {
					key = { name = "DEL", code = 0x2E }
				},
				controller_binding = {
					key = { name = "Unbound", code = 0 }
				},
			},
			{ is_exclusive = true }
		),
	},
	quick_toggle_keybinds = {}, ---@type table<string, Keybind>
	features = {
		unsafe_feats_enabled = false,
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
					color = vec3:new(1, 1, 1)
				},
			},
			default_station = {
				enabled = false,
				station_name = "OFF",
				display_name = "Off"
			},
			manual_gearbox = {
				enabled = false,
				disable_stalling = false,
				mode = 0, ---@type eManualGearboxType
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
			fast_vehicles_speed = 10,
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
				name = nil ---@type string?
			},
			missile_defence = false,
			strong_crash = false,
			auto_lock_doors = false,
			cobra_maneuver = false,
			fast_jets = false,
			fast_jets_speed = 150.0,
			no_jet_stall = false,
			no_turbulence = false,
			aircraft_mg = {
				triggerbot = false,
				tiggerbot_range = 200.0,
				manual_aim = false,
				enemies_only = false,
				marker_size = 1.6,
				marker_color = vec4:new(0, 1, 0, 1)
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
			stancer = { auto_apply_saved = false, },
		},
		speedometer = {
			enabled = false,
			speed_unit = 0,
			radius = 160,
			pos = vec2:zero(),
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
				color = vec4:new(1, 0, 0, 0.9)
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
			autoplay_slots_delay_random = false,
			zero_ai_cuts = false,
			slot_machine_cap = 0,
			autoplay_slots_delay = 500,
			disable_heist_cooldown = false,
			ch_cart_autograb = false,
		},
		yim_heists = {
			cfr_cd = false,
			knoway_cd = false,
			dre_cd = false,
			ogfa_cd = false,
			cayo_cd = false,
			dday_cd = false,
			kortz_cd = false,
			kortz_week_bypass = false,
			sixty_nine = false,
			solo_missions = false,
			ignore_prop_req = false
		},
		yrv3 = {
			autofill_delay = 500,
			autosell = false,
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
			sy_disable_tow_cd = false,
			office_clutter = {
				auto_disable = false,
				items = {
					cash             = false,
					Swag_Silver      = false,
					Swag_Pills       = false,
					Swag_Med         = false,
					Swag_JewelWatch  = false,
					Swag_Ivory       = false,
					Swag_Guns        = false,
					Swag_Gems        = false,
					Swag_Furcoats    = false,
					Swag_electronic  = false,
					Swag_DrugStatue  = false,
					Swag_DrugBags    = false,
					Swag_Counterfeit = false,
					Swag_Booze_cigs  = false,
					Swag_Art         = false,
				}
			}
		},
		yim_actions = {
			auto_close_ped_window = false,
			disable_props = false,
			disable_ptfx = false,
			disable_sfx = false,
		},
	},
}

return Config
