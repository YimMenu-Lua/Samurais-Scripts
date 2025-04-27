---@diagnostic disable

SCRIPT_NAME    = "samurais_scripts"
SCRIPT_VERSION = "1.6.6"
TARGET_BUILD   = "3504"
TARGET_VERSION = "1.70"
DEFAULT_CONFIG = {
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
pedGrabber                            = false
b_PedGrabbed                          = false
vehicleGrabber                        = false
b_VehicleGrabbed                      = false
carpool                               = false
b_IsCarpooling                        = false
b_ShowCarpoolSeatControls             = false
b_ShowCarpoolUI                       = false
b_CarpoolVehRadioEnabled              = false
b_CarpoolVehIsConvertible             = false
b_StopCarpoolSearch                   = false
b_NPCAnimStarted                      = false
sound_btn_off                         = false
b_IsDrifting                          = false
b_StartRGBLoop                        = false
b_DefaultPopsDisabled                 = false
b_Warehouse1Loop                      = false
b_Warehouse2Loop                      = false
b_Warehouse3Loop                      = false
b_Warehouse4Loop                      = false
b_Warehouse5Loop                      = false
b_HangarLoop                          = false
b_WorldBoundsExtended                 = false
autopilot_waypoint                    = false
autopilot_objective                   = false
autopilot_random                      = false
b_FlightMusicDisabled                 = false
b_SpawnedKatana                       = false
b_IsSitting                           = false
b_IsPlayingAmbientScenario            = false
b_IsHiding                            = false
b_IsDuckingInVehicle                  = false
b_IsHidingInTrunk                     = false
b_IsHidingInDumpster                  = false
b_SellScriptIsRunning                 = false
b_HasTriggeredAutosell                = false
b_ShouldFlashBrakeLights              = false
b_IsCommandsUIOpen                    = false
b_ShouldDrawCommandsUI                = false
jsonMvmt                              = false
b_BootVehicleRearEngined              = false
rwSteering                            = false
awSteering                            = false
handbrakeSteering                     = false
b_ShouldDrawSpeedometer               = false
i_SpeedometerUnitModifier             = 1
i_LastAimedAtPed                      = 0
i_AnimFlag                            = 0
i_GrabbedPed                          = 0
i_GrabbedVeh                          = 0
i_AnimIndex                           = 0
i_Entity                              = 0
i_TimerA                              = 0
i_TimerB                              = 0
i_DefaultXenonLightsIndex             = 0
i_DummyCopCar                         = 0
i_DriftModePoints                     = 0
i_DriftModeExtraPoints                = 0
straight_counter                      = 0
i_DriftTime                           = 0
i_Katana                              = 0
i_HangarTotalValue                    = 0
i_BikerSlot0TotalValue                = 0
i_BikerSlot1TotalValue                = 0
i_BikerSlot2TotalValue                = 0
i_BikerSlot3TotalValue                = 0
i_BikerSlot4TotalValue                = 0
i_BunkerTotalValue                    = 0
i_AcidLabTotalValue                   = 0
i_Warehouse1Supplies                  = 0
i_Warehouse2Supplies                  = 0
i_Warehouse3Supplies                  = 0
i_Warehouse4Supplies                  = 0
i_Warehouse5Supplies                  = 0
i_HangarSupplies                      = 0
i_Warehouse1Value                     = 0
i_Warehouse2Value                     = 0
i_Warehouse3Value                     = 0
i_Warehouse4Value                     = 0
i_Warehouse5Value                     = 0
ceo_moola                             = 0
i_HnSVehicle                          = 0
f_HnSVehicleLength                    = 0
i_HnSDumpster                         = 0
i_PublicSeat                          = 0
i_StalkingPervert                     = 0
i_BhubScriptHandle                    = 0
i_CarpoolVehicle                      = 0
i_CarpoolDriver                       = 0
i_CarpoolVehRoofState                 = 0
f_CarpoolVehicleCurrentSpeed          = 0
i_CarpoolDefaultDrivingSpeed          = 19
i_CarpoolDrivingStyleSwitch           = 0
i_CarpoolDrivingFlags                 = 803243
i_DriftMultiplier                     = 1
f_DailyQuoteTextAlpha                 = 1.0
i_PedThrowForce                       = 10
i_DefaultWantedLevel                  = 5
FreemodeGlobal1                       = 262145
FreemodeGlobal2                       = 1667996
BusinessHubGlobal1                    = 1943773
BusinessHubGlobal2                    = 1963766
PersonalVehicleGlobal                 = 1572092
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
s_SellScriptName                      = "None"
s_SellScriptDisplayName               = "None"
v_NpcDriveDestination                 = vec3:zero()
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
