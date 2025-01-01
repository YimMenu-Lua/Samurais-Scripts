---@diagnostic disable

SCRIPT_NAME    = "samurais_scripts"
SCRIPT_VERSION = '1.5.2'
TARGET_BUILD   = '3411'
TARGET_VERSION = '1.70'
DEFAULT_CONFIG          = {
  shortcut_anim           = {},
  saved_vehicles          = {},
  persist_attachments     = {},
  favorite_actions        = {},
  driftSmoke_T            = {
    r = 255,
    g = 255,
    b = 255,
  },
  vmine_type              = { spikes = false, slick = false, explosive = false, emp = false, kinetic = false },
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
  autovehlocks            = false,
  autoraiseroof           = false,
  towEverything           = false,
  noEngineBraking         = false,
  kersBoost               = false,
  offroaderx2             = false,
  rallyTires              = false,
  noTractionCtrl          = false,
  easyWheelie             = false,
  rwSteering              = false,
  awSteering              = false,
  handbrakeSteering       = false,
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
  bunkerUpdgrade1         = false,
  bunkerUpdgrade2         = false,
  acidUpdgrade            = false,
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
  supply_autofill_delay   = 500,
  LANG                    = 'en-US',
  current_lang            = 'English',
}

current_vehicle         = self.get_veh()
last_vehicle            = self.get_veh()
tab1Sound               = true
tab2Sound               = true
tab3Sound               = true
tab4Sound               = true
start_loading_anim      = false
is_playing_anim         = false
is_shortcut_anim        = false
anim_music              = false
is_playing_scenario     = false
is_playing_radio        = false
aimBool                 = false
HashGrabber             = false
drew_laser              = false
isCrouched              = false
is_handsUp              = false
phoneAnimsEnabled       = false
is_car                  = false
is_quad                 = false
is_boat                 = false
is_bike                 = false
validModel              = false
fb_model_override       = false
has_xenon               = false
has_custom_tires        = false
custom_tires_checked    = false
tire_smoke_col_checked  = false
tire_smoke              = false
drift_started           = false
purge_started           = false
nos_started             = false
twostep_started         = false
is_typing               = false
is_setting_hotkeys      = false
open_sounds_window      = false
started_lct             = false
launch_active           = false
started_popSound        = false
started_popSound2       = false
pedGrabber              = false
ped_grabbed             = false
vehicleGrabber          = false
vehicle_grabbed         = false
carpool                 = false
is_carpooling           = false
show_npc_veh_seat_ctrl  = false
show_npc_veh_ui         = false
npc_veh_radio_on        = false
npc_veh_has_conv_roof   = false
stop_searching          = false
hijack_started          = false
sound_btn_off           = false
is_drifting             = false
start_rgb_loop          = false
ubwindowsToggled        = false
default_pops_disabled   = false
engine_brake_disabled   = false
traction_ctrl_disabled  = false
kers_boost_enabled      = false
offroader_enabled       = false
rally_tires_enabled     = false
easy_wheelie_enabled    = false
-- rw_steering_enabled       = false --[[
-- aw_steering_enabled       = false -- they work but the steering is not rendered.
-- hb_steering_enabled       = false --]]
wh1_loop                = false
wh2_loop                = false
wh3_loop                = false
wh4_loop                = false
wh5_loop                = false
hangarLoop              = false
world_extended          = false
autopilot_waypoint      = false
autopilot_objective     = false
autopilot_random        = false
flight_music_off        = false
loud_radio_enabled      = false
q_replaced              = false
is_sitting              = false
is_playing_amb_scenario = false
is_hiding               = false
ducking_in_car          = false
hiding_in_boot          = false
hiding_in_dumpster      = false
mf_overwrite            = false
is_primary              = false
is_secondary            = false
scr_is_running          = false
autosell_was_triggered  = false
should_flash_bl         = false
cmd_ui_is_open          = false
should_draw_cmd_ui      = false
mvmtSelected            = false
jsonMvmt                = false
edit_mode               = false
activeX                 = false
activeY                 = false
activeZ                 = false
rotX                    = false
rotY                    = false
rotZ                    = false
attached                = false
attachToSelf            = false
attachToVeh             = false
previewStarted          = false
isChanged               = false
showInvalidObjText      = false
blacklisted_obj         = false
spawned_persist_props   = false
debug_counter           = not SS_debug and 0 or 7
vehicleLockStatus       = 0
anim_flag               = 0
anim_sortby_idx         = 0
grp_anim_index          = 0
attached_ped            = 0
grabbed_veh             = 0
thisVeh                 = 0
npcDriver               = 0
anim_index              = 0
scenario_index          = 0
recents_index           = 0
fav_actions_index       = 0
mvmt_index              = 0
npc_index               = 0
Entity                  = 0
timerA                  = 0
timerB                  = 0
flame_size              = 0
defaultXenon            = 0
vehSound_index          = 0
selected_smoke_col      = 0
pBus                    = 0
dummyDriver             = 0
dummyCopCar             = 0
sound_index1            = 0
sound_index2            = 0
sound_switch            = 0
radio_index             = 0
drift_points            = 0
drift_extra_pts         = 0
straight_counter        = 0
drift_time              = 0
loud_pops_event         = 0
towed_vehicle           = 0
tow_xAxis               = 0
tow_yAxis               = 0
tow_zAxis               = 0
veh_axisMult            = 1
vehicle_index           = 0
persist_index           = 0
spawned_veh_index       = 0
vehicleHash             = 0
spawned_vehicle         = 0
main_vehicle            = 0
persist_switch          = 0
attachment_index        = 0
selected_attchmnt       = 0
spawned_persist         = 0
veh_attach_X            = 0
veh_attach_Y            = 0
veh_attach_Z            = 0
veh_attach_RX           = 0
veh_attach_RY           = 0
veh_attach_RZ           = 0
katana                  = 0
hangarTotal             = 0
slot0_total             = 0
slot1_total             = 0
slot2_total             = 0
slot3_total             = 0
slot4_total             = 0
bunkerTotal             = 0
acidTotal               = 0
wh1Supplies             = 0
wh2Supplies             = 0
wh3Supplies             = 0
wh4Supplies             = 0
wh5Supplies             = 0
hangarSupplies          = 0
wh1Value                = 0
wh2Value                = 0
wh3Value                = 0
wh4Value                = 0
wh5Value                = 0
ceo_moola               = 0
prop                    = 0
propHash                = 0
os_switch               = 0
prop_index              = 0
objects_index           = 0
spawned_index           = 0
selectedObject          = 0
axisMult                = 1
selected_bone           = 0
previewEntity           = 0
currentObjectPreview    = 0
attached_index          = 0
vattached_index         = 0
zOffset                 = 0
persist_prop_index      = 0
boot_vehicle            = 0
thisDumpster            = 0
thisSeat                = 0
custom_paint_index      = 0
paints_col_sort_idx     = 0
paints_mfr_sort_idx     = 0
paints_sortby_switch    = 0
npc_veh_roof_state      = 0
perv                    = 0
npc_veh_speed           = 0.0
npcDriveSwitch          = 0
npcDrivingFlags         = 803243
pv_global               = 1572092
gb_global               = 1667995
tun_global              = 262145
npcDrivingSpeed         = 19
drift_multiplier        = 1
quote_alpha             = 1
pedthrowF               = 10
default_wanted_lvl      = 5
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
fm_mission_controller_cart_grab       = 10289
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
loading_label           = ""
sound_search            = ""
popsnd                  = ""
sndRef                  = ""
drift_streak_text       = ""
drift_extra_text        = ""
actions_search          = ""
currentMvmt             = ""
currentStrf             = ""
currentWmvmt            = ""
search_term             = ""
smokeHex                = ""
random_quote            = ""
custom_paints_sq        = ""
vCreator_searchQ        = ""
vehicleName             = ""
creation_name           = ""
main_vehicle_name       = ""
npcDriveTask            = ""
user_command            = ""
jsonMvmtSearch          = ""
objects_search          = ""
propName                = ""
invalidType             = ""
saved_props_name        = ""
script_name             = "None"
simplified_scr_name     = "None"
spawnDistance           = vec3:new(0, 0, 0)
spawnRot                = vec3:new(0, 0, 0)
npcDriveDest            = vec3:new(0.0, 0.0, 0.0)
filteredPlayers         = {}
recently_played_a       = {}
selected_sound          = {}
selected_radio          = {}
smokePtfx_t             = {}
nosptfx_t               = {}
purgePtfx_t             = {}
lctPtfx_t               = {}
popSounds_t             = {}
popsPtfx_t              = {}
npc_blips               = {}
spawned_npcs            = {}
plyrProps               = {}
npcProps                = {}
selfPTFX                = {}
npcPTFX                 = {}
curr_playing_anim       = {}
chosen_anim             = {}
depressorBanList        = {}
jsonMvmts_t             = {}
spawned_vehicles        = {}
spawned_vehNames        = {}
filteredVehNames        = {}
persist_names           = {}
veh_attachments         = {}
spawned_props           = {}
vehAttachments          = {}
vehicle_attachments     = {}
spawned_persist_T       = {}
attached_props          = {}
selfAttachNames         = {}
attached_vehicles       = {
  entity = 0,
  hash   = 0,
  mods   = {},
  color_1 = {
    r = 0,
    g = 0,
    b = 0
  },
  color_2 = {
    r = 0,
    g = 0,
    b = 0
  },
  tint = 0,
  posx = 0.0,
  posy = 0.0,
  posz = 0.0,
  rotx = 0.0,
  roty = 0.0,
  rotz = 0.0
}
vehicle_creation        = {
  name = "",
  main_veh = 0,
  mods = {},
  color_1 = {
    r = 0,
    g = 0,
    b = 0
  },
  color_2 = {
    r = 0,
    g = 0,
    b = 0
  },
  tint = 0,
  attachments = {}
}
default_tire_smoke      = {
  r = 255,
  g = 255,
  b = 255,
}
yrv2_color              = {
  0,
  255,
  255,
  1
}
whouse1                 = {
  id   = 0,
  max  = 0,
  name = "",
  size = {
    small  = false,
    medium = false,
    large  = false,
  }
}
whouse2                 = {
  id   = 1,
  max  = 0,
  name = "",
  size = {
    small  = false,
    medium = false,
    large  = false,
  }
}
whouse3                 = {
  id   = 2,
  max  = 0,
  name = "",
  size = {
    small  = false,
    medium = false,
    large  = false,
  }
}
whouse4                 = {
  id   = 3,
  max  = 0,
  name = "",
  size = {
    small  = false,
    medium = false,
    large  = false,
  }
}
whouse5                 = {
  id   = 4,
  max  = 0,
  name = "",
  size = {
    small  = false,
    medium = false,
    large  = false,
  }
}
-- biker businesses
bb                      = {
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
prop_creation         = {
  name  = "",
  props = {}
}
selfAttachments       = {
  entity = 0,
  hash   = 0,
  bone   = 0,
  posx   = 0.0,
  posy   = 0.0,
  posz   = 0.0,
  rotx   = 0.0,
  roty   = 0.0,
  rotz   = 0.0
}
CFG = require("lib/YimConfig")

 -- read global vars from config
for key, _ in pairs(DEFAULT_CONFIG) do
  _G[key] = CFG.read(key)
end
