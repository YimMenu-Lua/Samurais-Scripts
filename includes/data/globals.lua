---@diagnostic disable

local SCRIPT_NAME    <const> = "samurais_scripts"
local SCRIPT_VERSION <const> = "1.7.0"
local TARGET_BUILD   <const> = "3521"
local TARGET_VERSION <const> = "1.70"
local DEFAULT_CONFIG <const> = {
    favorite_entities       = {},
    forged_entities         = {},
    yav3_saved_peds         = {},
    yav3_shortcut           = {},
    yav3_favorites          = {
        anims = {},
        scenarios = {},
        clipsets = {},
        scenes = {},
    },
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
        rodBtn         = { code = 0x58, name = "[X]" },
        tdBtn          = { code = 0x10, name = "[Shift]" },
        nosBtn         = { code = 0x10, name = "[Shift]" },
        stop_anim      = { code = 0x47, name = "[G]" },
        play_anim      = { code = 0x2E, name = "[DEL]" },
        previous_anim  = { code = 0x21, name = "[PAGE UP]" },
        next_anim      = { code = 0x22, name = "[PAGE DOWN]" },
        flatbedBtn     = { code = 0x58, name = "[X]" },
        purgeBtn       = { code = 0x58, name = "[X]" },
        autokill       = { code = 0x76, name = "[F7]" },
        enemiesFlee    = { code = 0x77, name = "[F8]" },
        missl_def      = { code = 0x0,  name = "[Unbound]" },
        vehicle_mine   = { code = 0x4E, name = "[N]" },
        triggerbotBtn  = { code = 0x10, name = "[Shift]" },
        panik          = { code = 0x7B, name = "[F12]" },
        laser_sight    = { code = 0x4C, name = "[L]" },
        commands       = { code = 0x67, name = "[NUMPAD 7]" },
        cobra_maneuver = { code = 0x4D, name = "[M]" },
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
    speedometer_cfg             = {
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
    saved_escort_groups = {
        {
            name = "Armenian Mobsters",
            vehicleModel = 83136452,
            members = {
                {
                    modelHash = 0xE7714013,
                    name = "Levon Termendzhyan",
                    weapon = 0x1B06D571,
                },
                {
                    modelHash = 0xFDA94268,
                    name = "Armen Petrosyan",
                    weapon = 0x1B06D571,
                },
                {
                    modelHash = 0xF1E823A2,
                    name = "Yanni",
                    weapon = 0x1B06D571,
                },
            }
        },
        {
            name = "Bad Bitches",
            vehicleModel = 461465043,
            members = {
                {
                    modelHash = 0x28ABF95,
                    name = "Beretta Von PewPew",
                    weapon = 0xBFEFFF6D,
                },
                {
                    modelHash = 0x81441B71,
                    name = "Big Booty Iggy",
                    weapon = 0xBFEFFF6D,
                },
                {
                    modelHash = 0xAEEA76B5,
                    name = "Sasha Slasha",
                    weapon = 0xBFEFFF6D,
                },
            }
        },
        {
            name = "Private Mercenaries",
            vehicleModel = 2370534026,
            members = {
                {
                    modelHash = 0x613E626C,
                    name = "Jack Reacher",
                    weapon = 0x83BF0278,
                },
                {
                    modelHash = 0x5076A73B,
                    name = "Ethan Hunt",
                    weapon = 0x83BF0278,
                },
                {
                    modelHash = 0xB3F3EE34,
                    name = "Sam Fisher",
                    weapon = 0x83BF0278,
                },
            }
        },
        {
            name = "Sicarios",
            vehicleModel = 1254014755,
            members = {
                {
                    modelHash = 0x995B3F9F,
                    name = "Ovidio Guzman",
                    weapon = 0xBFEFFF6D,
                },
                {
                    modelHash = 0x7ED5AD78,
                    name = "Popeye",
                    weapon = 0xBFEFFF6D,
                },
                {
                    modelHash = 0xE6AC74A4,
                    name = "El Sueno",
                    weapon = 0xBFEFFF6D,
                },
            }
        },
        {
            name = "VIP Security",
            vehicleModel = 666166960,
            members = {
                {
                    modelHash = 0xF161D212,
                    name = "Arthur Bishop",
                    weapon = 0x83BF0278,
                },
                {
                    modelHash = 0x2930C1AB,
                    name = "Luke Wright",
                    weapon = 0x83BF0278,
                },
                {
                    modelHash = 0x55FE9B46,
                    name = "Frank Martin",
                    weapon = 0x83BF0278,
                },
            }
        },
    },
    b_AutoCleanupEntities   = false,
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
    driftScoreSound         = false,
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
    towPos                  = false,
    towBox                  = false,
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
    cobra_maneuver          = false,
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


-----------------------------------------------------
-- SS Utils
-----------------------------------------------------
-- `SS` as in Samurai's Scripts, not Schutzstaffel... 🙄
---@class SS
SS = {}
SS.__index = SS

SS.script_version = SCRIPT_VERSION
SS.target_build   = TARGET_BUILD
SS.target_version = TARGET_VERSION
SS.default_config = DEFAULT_CONFIG
----------------------------------------------
----------------------------------------------
b_ShouldAnimateLoadingLabel           = false
b_IsCrouched                          = false
b_IsHandsUp                           = false
b_PhoneAnimsEnabled                   = false
b_HasXenonLights                      = false
b_HasCustomTires                      = false
b_CustomTiresChecked                  = false
b_TireSmokeColChecked                 = false
tire_smoke                            = false
drift_started                         = false
b_IsTyping                            = false
b_IsSettingHotkeys                    = false
b_EngineSoundChanged                  = false
b_LaunchControlReady                  = false
b_LaunchControlActive                 = false
b_PedGrabber                          = false
b_PedGrabbed                          = false
b_VehicleGrabber                      = false
b_VehicleGrabbed                      = false
b_Carpool                             = false
b_StartRGBLoop                        = false
b_DefaultPopsDisabled                 = false
b_WorldBoundsExtended                 = false
b_AutopilotWaypoint                   = false
b_AutopilotObjective                  = false
b_AutopilotRandom                     = false
b_FlightMusicDisabled                 = false
b_SpawnedKatana                       = false
b_IsPlayingAmbientScenario            = false
b_ShouldFlashBrakeLights              = false
b_IsCommandsUIOpen                    = false
b_ShouldDrawCommandsUI                = false
b_BootVehicleRearEngined              = false
b_RwSteering                          = false
b_AwSteering                          = false
b_HandbrakeSteering                   = false
b_ShouldDrawSpeedometer               = false
i_SpeedometerUnitModifier             = 1
i_RadioStationIndex                   = 1
i_LastAimedAtPed                      = 0
i_AnimFlag                            = 0
i_GrabbedPed                          = 0
i_GrabbedVeh                          = 0
i_AnimIndex                           = 0
i_Entity                              = 0
i_TimerA                              = 0
i_TimerB                              = 0
i_DummyCopCar                         = 0
i_Katana                              = 0
i_HnSVehicle                          = 0
f_HnSVehicleLength                    = 0
i_HnSDumpster                         = 0
i_StalkingPervert                     = 0
f_DailyQuoteTextAlpha                 = 1.0
i_PedThrowForce                       = 10
i_DefaultWantedLevel                  = 5
FreemodeGlobal1                       = 262145
FreemodeGlobal2                       = 1667996
PVGLobal                              = 1572092
BusinessHubGlobal1                    = 1943773
BusinessHubGlobal2                    = 1963766
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
gb_casino_heist_planning_cut_offset   = 1497 + 736 + 92 -- .*?0->f_....?\.f_...?\.f_..?\[4\] > 0
fm_mission_controller_cart_grab       = 10291
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
s_LoadingLabel                        = ""
s_CurrentMovementClipset              = ""
s_CurrentStrafeClipset                = ""
s_CurrentWeaponMovement               = ""
s_RandomDailyQuote                    = ""
s_NpcDriveTask                        = ""
s_SpeedometerGearDisplay              = ""
v_NpcDriveDestination                 = vec3:zero()
default_tire_smoke                    = {
    r = 255,
    g = 255,
    b = 255,
}

yrv2_color = {
    0,
    255,
    255,
    1
}

t_CEOwarehouseData = {
    [1] = {
        isOwned = false,
        autoFill = false
    },
    [2] = {
        isOwned = false,
        autoFill = false
    },
    [3] = {
        isOwned = false,
        autoFill = false
    },
    [4] = {
        isOwned = false,
        autoFill = false
    },
    [5] = {
        isOwned = false,
        autoFill = false
    },
}

t_BikerBusinessData = {
    [1] = {isOwned = false},
    [2] = {isOwned = false},
    [3] = {isOwned = false},
    [4] = {isOwned = false},
    [5] = {isOwned = false},
}

g_WompusHasRisen   = false
g_CreatedBlips     = {}
g_AttachedEntities = {}
g_SpawnedEntities  = {
    peds = {},
    vehicles = {},
    objects = {},
}


Time       = require("includes.classes.Time")
KeyManager = require("includes.services.Hotkeys")
YimToast   = require("includes.lib.YimToast")
CFG        = require("includes.lib.YimConfig"):New(
    SCRIPT_NAME,
    DEFAULT_CONFIG,
    true,
    4
)
Timer = Time.Timer
yield = coroutine.yield
Sleep = Time.Sleep


local _init_G = coroutine.create(function()
    for key, _ in pairs(DEFAULT_CONFIG) do
        _G[key] = CFG:ReadItem(key) or DEFAULT_CONFIG[key]
        yield()
    end
end)

while coroutine.status(_init_G) ~= "dead" do
    coroutine.resume(_init_G)
end
