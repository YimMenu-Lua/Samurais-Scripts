---@diagnostic disable

SCRIPT_NAME    = "samurais_scripts"
SCRIPT_VERSION = "1.6.5"
TARGET_BUILD   = "3504"
TARGET_VERSION = "1.70"
DEFAULT_CONFIG = {
    shortcut_anim           = {},
    favorite_actions        = {},
    favorite_entities       = {},
    forged_entities         = {},
    driftSmoke_T            = {
        r = 255,
        g = 255,
        b = 255,
    },
    vmine_type              = {
        spikes = false,
        slick = false,
        explosive = false,
        emp = false,
        kinetic = false
    },
    keybinds                = {
        rodBtn        = { code = 0x58, name = "[X]" },
        tdBtn         = { code = 0x10, name = "[Shift]" },
        nosBtn        = { code = 0x10, name = "[Shift]" },
        stop_anim     = { code = 0x47, name = "[G]" },
        play_anim     = { code = 0x2E, name = "[DEL]" },
        previous_anim = { code = 0x21, name = "[PAGE UP]" },
        next_anim     = { code = 0x22, name = "[PAGE DOWN]" },
        flatbedBtn    = { code = 0x58, name = "[X]" },
        purgeBtn      = { code = 0x58, name = "[X]" },
        autokill      = { code = 0x76, name = "[F7]" },
        enemiesFlee   = { code = 0x77, name = "[F8]" },
        missl_def     = { code = 0x0, name = "[Unbound]" },
        vehicle_mine  = { code = 0x4E, name = "[N]" },
        triggerbotBtn = { code = 0x10, name = "[Shift]" },
        panik         = { code = 0x7B, name = "[F12]" },
        laser_sight   = { code = 0x4C, name = "[L]" },
        commands      = { code = 0x67, name = "[NUMPAD 7]" },
    },
    gpad_keybinds           = {
        rodBtn        = { code = 0, name = "[Unbound]" },
        tdBtn         = { code = 0, name = "[Unbound]" },
        nosBtn        = { code = 0, name = "[Unbound]" },
        flatbedBtn    = { code = 0, name = "[Unbound]" },
        purgeBtn      = { code = 0, name = "[Unbound]" },
        vehicle_mine  = { code = 0, name = "[Unbound]" },
        triggerbotBtn = { code = 0, name = "[Unbound]" },
        laser_sight   = { code = 0, name = "[Unbound]" },
    },
    laser_choice            = {
        r = 237,
        g = 47,
        b = 50,
    },
    cannon_marker_color     = {
        0,
        1,
        0
    },
    speedometer             = {
        enabled = false,
        speed_unit = 0,
        radius = 160,
        pos = {
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
    Regen                   = false,
    disableTooltips         = false,
    phoneAnim               = false,
    disableProps            = false,
    sprintInside            = false,
    lockpick                = false,
    rod                     = false,
    clumsy                  = false,
    ragdoll_sound           = false,
    hideFromCops            = false,
    hatsinvehs              = false,
    novehragdoll            = false,
    manualFlags             = false,
    controllable            = false,
    looped                  = false,
    upperbody               = false,
    freeze                  = false,
    noCollision             = false,
    killOnEnd               = false,
    usePlayKey              = false,
    replaceSneakAnim        = false,
    replacePointAct         = false,
    disableActionMode       = false,
    disableSound            = false,
    npc_godMode             = false,
    Triggerbot              = false,
    MagicBullet             = false,
    aimEnemy                = false,
    autoKill                = false,
    runaway                 = false,
    laserSight              = false,
    disableUiSounds         = false,
    driftMode               = false,
    DriftTires              = false,
    DriftSmoke              = false,
    BurnoutSmoke            = false,
    customSmokeCol          = false,
    driftMinigame           = false,
    speedBoost              = false,
    nosvfx                  = false,
    nosAudio                = false,
    nosFlames               = false,
    hornLight               = false,
    nosPurge                = false,
    insta180                = false,
    flappyDoors             = false,
    rgbLights               = false,
    fender_bender           = false,
    loud_radio              = false,
    launchCtrl              = false,
    popsNbangs              = false,
    limitVehOptions         = false,
    missiledefense          = false,
    louderPops              = false,
    autobrklight            = false,
    abs_lights              = false,
    holdF                   = false,
    keepWheelsTurned        = false,
    noJacking               = false,
    veh_mines               = false,
    fast_vehicles           = false,
    autovehlocks            = false,
    autoraiseroof           = false,
    towEverything           = false,
    noEngineBraking         = false,
    kersBoost               = false,
    offroaderx2             = false,
    rallyTires              = false,
    noTractionCtrl          = false,
    easyWheelie             = false,
    useGameLang             = false,
    bypass_casino_bans      = false,
    force_poker_cards       = false,
    set_dealers_poker_cards = false,
    force_roulette_wheel    = false,
    rig_slot_machine        = false,
    autoplay_slots          = false,
    autoplay_cap            = false,
    heist_cart_autograb     = false,
    flares_forall           = false,
    unbreakableWindows      = false,
    real_plane_speed        = false,
    no_stall                = false,
    cannon_triggerbot       = false,
    cannon_enemies_only     = true,
    cannon_manual_aim       = false,
    extend_world            = false,
    disableFlightMusic      = false,
    disable_quotes          = false,
    disable_mdef_logs       = false,
    replace_pool_q          = false,
    public_seats            = false,
    ambient_scenarios       = false,
    ambient_scenario_prompt = false,
    mc_work_cd              = false,
    hangar_cd               = false,
    nc_management_cd        = false,
    nc_vip_mission_chance   = false,
    security_missions_cd    = false,
    ie_vehicle_steal_cd     = false,
    ie_vehicle_sell_cd      = false,
    ceo_crate_buy_cd        = false,
    ceo_crate_sell_cd       = false,
    ceo_crate_buy_f_cd      = false,
    ceo_crate_sell_f_cd     = false,
    dax_work_cd             = false,
    garment_rob_cd          = false,
    autosell                = false,
    SS_debug                = false,
    nosBtn                  = 21,
    nosPower                = 10,
    lightSpeed              = 1,
    DriftPowerIncrease      = 1,
    driftPB                 = 0,
    driftSmokeIndex         = 0,
    laser_switch            = 0,
    lang_idx                = 0,
    DriftIntensity          = 0,
    autoplay_chips_cap      = 0,
    cannon_triggerbot_range = 1000,
    cannon_marker_size      = 1.5,
    supply_autofill_delay   = 500,
    katana_replace_model    = 0xDD5DF8D9,
    katana_replace_index    = 0,
    LANG                    = "en-US",
    current_lang            = "English",
}

tab1Sound                             = true
tab2Sound                             = true
tab3Sound                             = true
tab4Sound                             = true
start_loading_anim                    = false
is_playing_anim                       = false
is_shortcut_anim                      = false
anim_music                            = false
is_playing_scenario                   = false
is_playing_radio                      = false
aimBool                               = false
HashGrabber                           = false
drew_laser                            = false
isCrouched                            = false
is_handsUp                            = false
phoneAnimsEnabled                     = false
validModel                            = false
fb_model_override                     = false
has_xenon                             = false
has_custom_tires                      = false
custom_tires_checked                  = false
tire_smoke_col_checked                = false
tire_smoke                            = false
drift_started                         = false
purge_started                         = false
nos_started                           = false
twostep_started                       = false
is_typing                             = false
is_setting_hotkeys                    = false
is_shooting_flares                    = false
engine_sound_changed                  = false
open_sounds_window                    = false
open_engine_swap_window               = false
started_lct                           = false
launch_active                         = false
started_popSound                      = false
started_popSound2                     = false
pedGrabber                            = false
ped_grabbed                           = false
vehicleGrabber                        = false
vehicle_grabbed                       = false
carpool                               = false
isCarpooling                          = false
show_npc_veh_seat_ctrl                = false
show_npc_veh_ui                       = false
npc_veh_radio_on                      = false
npc_veh_has_conv_roof                 = false
stop_searching                        = false
hijack_started                        = false
sound_btn_off                         = false
is_drifting                           = false
start_rgb_loop                        = false
default_pops_disabled                 = false
wh1_loop                              = false
wh2_loop                              = false
wh3_loop                              = false
wh4_loop                              = false
wh5_loop                              = false
hangarLoop                            = false
world_extended                        = false
autopilot_waypoint                    = false
autopilot_objective                   = false
autopilot_random                      = false
flight_music_off                      = false
q_replaced                            = false
is_sitting                            = false
is_playing_amb_scenario               = false
is_hiding                             = false
ducking_in_car                        = false
hiding_in_boot                        = false
hiding_in_dumpster                    = false
mf_overwrite                          = false
is_primary                            = false
is_secondary                          = false
scr_is_running                        = false
autosell_was_triggered                = false
should_flash_bl                       = false
cmd_ui_is_open                        = false
should_draw_cmd_ui                    = false
mvmtSelected                          = false
jsonMvmt                              = false
isChanged                             = false
boot_vehicle_re                       = false
rwSteering                            = false
awSteering                            = false
handbrakeSteering                     = false
should_draw_speedometer               = false
debug_counter                         = not SS_debug and 0 or 7
i_SpeedometerUnitModifier             = 1
i_LastAimedAtPed                      = 0
i_AnimFlag                            = 0
i_AttachedPed                         = 0
i_GrabbedVeh                          = 0
i_ThisVeh                             = 0
i_NpcDriver                           = 0
i_AnimIndex                           = 0
i_Entity                              = 0
i_TimerA                              = 0
i_TimerB                              = 0
i_FlameSize                           = 0
i_DefaultXenon                        = 0
pBus                                  = 0
dummyDriver                           = 0
dummyCopCar                           = 0
drift_points                          = 0
drift_extra_pts                       = 0
straight_counter                      = 0
drift_time                            = 0
loud_pops_event                       = 0
towed_vehicle                         = 0
towed_vehicleModel                    = 0
f_tow_xAxis                           = 0.0
f_tow_yAxis                           = 0.0
f_tow_zAxis                           = 0.0
katana                                = 0
hangarTotal                           = 0
slot0_total                           = 0
slot1_total                           = 0
slot2_total                           = 0
slot3_total                           = 0
slot4_total                           = 0
bunkerTotal                           = 0
acidTotal                             = 0
wh1Supplies                           = 0
wh2Supplies                           = 0
wh3Supplies                           = 0
wh4Supplies                           = 0
wh5Supplies                           = 0
hangarSupplies                        = 0
wh1Value                              = 0
wh2Value                              = 0
wh3Value                              = 0
wh4Value                              = 0
wh5Value                              = 0
ceo_moola                             = 0
boot_vehicle                          = 0
boot_vehicle_len                      = 0
thisDumpster                          = 0
thisSeat                              = 0
npc_veh_roof_state                    = 0
perv                                  = 0
abhubScriptHandle                     = 0
npc_veh_speed                         = 0
npcDriveSwitch                        = 0
npcDrivingFlags                       = 803243
pv_global                             = 1572092
gb_global                             = 1667995
tun_global                            = 262145
flatbedModel                          = 1353720154
npcDrivingSpeed                       = 19
drift_multiplier                      = 1
quote_alpha                           = 1
pedthrowF                             = 10
default_wanted_lvl                    = 5
------------------- Casino Pacino -------------------
blackjack_cards                       = 134
blackjack_decks                       = 846
blackjack_table_players               = 1794
blackjack_table_players_size          = 8
three_card_poker_table                = 767
three_card_poker_table_size           = 9
three_card_poker_cards                = 134
three_card_poker_current_deck         = 168
three_card_poker_anti_cheat           = 1056
three_card_poker_anti_cheat_deck      = 799
three_card_poker_deck_size            = 55
roulette_master_table                 = 142
roulette_outcomes_table               = 1357
roulette_ball_table                   = 153
slots_random_results_table            = 1366
slots_slot_machine_state              = 1656
prize_wheel_win_state                 = 298
prize_wheel_prize                     = 14
prize_wheel_prize_state               = 45
gb_casino_heist_planning              = 1965614
gb_casino_heist_planning_cut_offset   = 1497 + 736 + 92
fm_mission_controller_cart_grab       = 10289 -- 10291
fm_mission_controller_cart_grab_speed = 14
casino_heist_approach                 = 0
casino_heist_target                   = 0
casino_heist_last_approach            = 0
casino_heist_hard                     = 0
casino_heist_gunman                   = 0
casino_heist_driver                   = 0
casino_heist_hacker                   = 0
casino_heist_weapons                  = 0
casino_heist_cars                     = 0
casino_heist_masks                    = 0
new_approach                          = 0
new_target                            = 0
new_last_approach                     = 0
new_hard_approach                     = 0
new_gunman                            = 0
new_weapons                           = 0
new_driver                            = 0
new_car                               = 0
new_hacker                            = 0
new_masks                             = 0
casino_cooldown_update_str            = ""
dealers_card_str                      = ""
-----------------------------------------------------
loading_label                         = ""
sound_search                          = ""
popsnd                                = ""
sndRef                                = ""
drift_streak_text                     = ""
drift_extra_text                      = ""
actions_search                        = ""
currentMvmt                           = ""
currentStrf                           = ""
currentWmvmt                          = ""
search_term                           = ""
smokeHex                              = ""
random_quote                          = ""
custom_paints_sq                      = ""
npcDriveTask                          = ""
user_command                          = ""
jsonMvmtSearch                        = ""
speedometer_gear_display              = ""
script_name                           = "None"
simplified_scr_name                   = "None"
npcDriveDest                          = vec3:zero()
recently_played_a                     = {}
selected_sound                        = {}
selected_radio                        = {}
smokePtfx_t                           = {}
nosptfx_t                             = {}
purgePtfx_t                           = {}
lctPtfx_t                             = {}
popSounds_t                           = {}
popsPtfx_t                            = {}
npc_blips                             = {}
spawned_npcs                          = {}
plyrProps                             = {}
npcProps                              = {}
selfPTFX                              = {}
npcPTFX                               = {}
curr_playing_anim                     = {}
chosen_anim                           = {}
jsonMvmts_t                           = {}
default_tire_smoke                    = {
    r = 255,
    g = 255,
    b = 255,
}

yrv2_color                            = {
    0,
    255,
    255,
    1
}

whouse1                               = {
    id   = 0,
    max  = 0,
    name = "",
    pos  = nil,
    size = {
        small  = false,
        medium = false,
        large  = false,
    }
}

whouse2                               = {
    id   = 1,
    max  = 0,
    name = "",
    pos  = nil,
    size = {
        small  = false,
        medium = false,
        large  = false,
    }
}

whouse3                               = {
    id   = 2,
    max  = 0,
    name = "",
    pos  = nil,
    size = {
        small  = false,
        medium = false,
        large  = false,
    }
}

whouse4                               = {
    id   = 3,
    max  = 0,
    name = "",
    pos  = nil,
    size = {
        small  = false,
        medium = false,
        large  = false,
    }
}

whouse5                               = {
    id   = 4,
    max  = 0,
    name = "",
    pos  = nil,
    size = {
        small  = false,
        medium = false,
        large  = false,
    }
}

-- biker businesses
bb                                    = {
    slot0 = {
        name       = "Unknown",
        id         = 0,
        blip       = 0,
        unit_max   = 0,
        val_offset = 0,
    },
    slot1 = {
        name       = "Unknown",
        id         = 0,
        blip       = 0,
        unit_max   = 0,
        val_offset = 0,
    },
    slot2 = {
        name       = "Unknown",
        id         = 0,
        blip       = 0,
        unit_max   = 0,
        val_offset = 0,
    },
    slot3 = {
        name       = "Unknown",
        id         = 0,
        blip       = 0,
        unit_max   = 0,
        val_offset = 0,
    },
    slot4 = {
        name       = "Unknown",
        id         = 0,
        blip       = 0,
        unit_max   = 0,
        val_offset = 0,
    },
}

KeyManager = require("includes.classes.hotkeys")
YimToast   = require("includes.lib.YimToast")
CFG        = require("includes.lib.YimConfig"):New(
    SCRIPT_NAME,
    DEFAULT_CONFIG,
    true,
    4
)

local _init_G = coroutine.create(function()
    for key, _ in pairs(DEFAULT_CONFIG) do
        _G[key] = CFG:ReadItem(key)
        coroutine.yield()
    end
end)

while coroutine.status(_init_G) ~= "dead" do
    coroutine.resume(_init_G)
end
