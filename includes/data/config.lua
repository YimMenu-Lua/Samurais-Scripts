return {
    __config_version = "0.1a",
    __debug = false,
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
            category_rect_bg_1 = {
                0.274,
                0.51,
                1,
                0.901
            },
            category_rect_bg_2 = {
                0.392,
                0.627,
                1,
                1
            },
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
    },
    gamepad_keybinds = {},
    features = {
        dunk = {
            bypass_casino_bans = false,
            force_poker_cards = false,
            set_dealers_poker_cards = false,
            force_roulette_wheel = false,
            rig_slot_machine = false,
            autoplay_slots = false,
            cap_slot_machine_chips = false,
        },
        yrv3 = {
            auto_sell = false,
            autofill_delay = 500
        },
        vehicle = {
            abs_lights = true,
            fast_vehicles = false,
        },
        speedometer = {
            enabled = true,
            speed_unit = 0,
            radius = 160,
            pos = {
                __type = "vec2",
                x = 0.0,
                y = 0.0
            },
            circle_bgcolor = 0x66090909,
            circle_color = 0xFF313195,
            markings_color = 0xFFC7C7C7,
            text_color = 0xDDFFFFFF,
            needle_color = 0xFF3636FF,
            needle_base_color = 0xFF111111,
        },
    },
}
