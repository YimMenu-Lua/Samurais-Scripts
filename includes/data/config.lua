
return {
    __config_version = "0.1a",
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
        }
    },
    features = {
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
                mode = 1,
                intensity = 1,
                power = 50,
            },
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
            rgb_lights = false,
            cobra_maneuver = false,
            missile_defence = false,
            mines = false,
            strong_crash = false,
            flatbed = false,
            auto_lock_doors = false,
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
    },
}
