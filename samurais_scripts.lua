---@diagnostic disable: undefined-global, lowercase-global, undefined-field


require('lib/samurais_utils')
require('lib/Translations')
require('data/objects')
require('data/actions')
require('data/refs')

SCRIPT_VERSION  = '1.1.4'   -- v1.1.4
TARGET_BUILD    = '3274'  -- Only YimResupplier needs a version check.
TARGET_VERSION  = '1.69'
CURRENT_BUILD   = Game.GetBuildNumber()
CURRENT_VERSION = Game.GetOnlineVersion()


Samurais_scripts = gui.add_tab("Samurai's Scripts")
local loading_label       = ""
local start_loading_anim  = false
default_config            = {
  shortcut_anim           = {},
  saved_vehicles          = {},
  Regen                   = false,
  -- objectiveTP             = false,
  disableTooltips         = false,
  phoneAnim               = false,
  disableProps            = false,
  sprintInside            = false,
  lockpick                = false,
  rod                     = false,
  clumsy                  = false,
  manualFlags             = false,
  controllable            = false,
  looped                  = false,
  upperbody               = false,
  freeze                  = false,
  usePlayKey              = false,
  replaceSneakAnim        = false,
  replacePointAct         = false,
  disableActionMode       = false,
  disableSound            = false,
  npc_godMode             = false,
  -- Triggerbot              = false,
  aimEnemy                = false,
  autoKill                = false,
  runaway                 = false,
  laserSight              = false,
  disableUiSounds         = false,
  driftMode               = false,
  DriftTires              = false,
  DriftSmoke              = false,
  driftMinigame           = false,
  speedBoost              = false,
  nosvfx                  = false,
  hornLight               = false,
  nosPurge                = false,
  insta180                = false,
  flappyDoors             = false,
  rgbLights               = false,
  loud_radio              = false,
  launchCtrl              = false,
  popsNbangs              = false,
  limitVehOptions         = false,
  missiledefense          = false,
  louderPops              = false,
  autobrklight            = false,
  holdF                   = false,
  keepWheelsTurned        = false,
  noJacking               = false,
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
  real_plane_speed        = false,
  nosPower                = 10,
  lightSpeed              = 1,
  DriftPowerIncrease      = 1,
  laser_switch            = 0,
  lang_idx                = 0,
  DriftIntensity          = 0,
  autoplay_chips_cap      = 0,
  laser_choice            = "proj_laser_enemy",
  LANG                    = 'en-US',
  current_lang            = 'English',
}

LANG                = lua_cfg.read("LANG")
current_lang        = lua_cfg.read("current_lang")
Regen               = lua_cfg.read("Regen")
-- objectiveTP         = lua_cfg.read("objectiveTP")
phoneAnim           = lua_cfg.read("phoneAnim")
sprintInside        = lua_cfg.read("sprintInside")
lockPick            = lua_cfg.read("lockPick")
replaceSneakAnim    = lua_cfg.read("replaceSneakAnim")
replacePointAct     = lua_cfg.read("replacePointAct")
disableActionMode   = lua_cfg.read("disableActionMode")
rod                 = lua_cfg.read("rod")
clumsy              = lua_cfg.read("clumsy")
manualFlags         = lua_cfg.read("manualFlags")
controllable        = lua_cfg.read("controllable")
looped              = lua_cfg.read("looped")
upperbody           = lua_cfg.read("upperbody")
freeze              = lua_cfg.read("freeze")
disableProps        = lua_cfg.read("disableProps")
npc_godMode         = lua_cfg.read("npc_godMode")
usePlayKey          = lua_cfg.read("usePlayKey")
shortcut_anim       = lua_cfg.read("shortcut_anim")
-- Triggerbot          = lua_cfg.read("Triggerbot")
aimEnemy            = lua_cfg.read("aimEnemy")
autoKill            = lua_cfg.read("autoKill")
runaway             = lua_cfg.read("runaway")
laserSight          = lua_cfg.read("laserSight")
laser_switch        = lua_cfg.read("laser_switch")
laser_choice        = lua_cfg.read("laser_choice")
driftMode           = lua_cfg.read("driftMode")
DriftIntensity      = lua_cfg.read("DriftIntensity")
DriftPowerIncrease  = lua_cfg.read("DriftPowerIncrease")
DriftTires          = lua_cfg.read("DriftTires")
DriftSmoke          = lua_cfg.read("DriftSmoke")
driftMinigame       = lua_cfg.read("driftMinigame")
speedBoost          = lua_cfg.read("speedBoost")
nosvfx              = lua_cfg.read("nosvfx")
hornLight           = lua_cfg.read("hornLight")
nosPurge            = lua_cfg.read("nosPurge")
nosPower            = lua_cfg.read("nosPower")
lightSpeed          = lua_cfg.read("lightSpeed")
loud_radio          = lua_cfg.read("loud_radio")
launchCtrl          = lua_cfg.read("launchCtrl")
popsNbangs          = lua_cfg.read("popsNbangs")
louderPops          = lua_cfg.read("louderPops")
limitVehOptions     = lua_cfg.read("limitVehOptions")
missiledefense      = lua_cfg.read("missiledefense")
autobrklight        = lua_cfg.read("autobrklight")
rgbLights           = lua_cfg.read("rgbLights")
holdF               = lua_cfg.read("holdF")
keepWheelsTurned    = lua_cfg.read("keepWheelsTurned")
noJacking           = lua_cfg.read("noJacking")
insta180            = lua_cfg.read("insta180")
flares_forall       = lua_cfg.read("flares_forall")
real_plane_speed    = lua_cfg.read("real_plane_speed")
tab1Sound           = true
tab2Sound           = true
tab3Sound           = true
is_playing_anim     = false
is_shortcut_anim    = false
anim_music          = false
is_playing_scenario = false
is_playing_radio    = false
-- aimBool             = false
HashGrabber         = false
drew_laser          = false
isCrouched          = false
is_handsUp          = false
is_car              = false
is_quad             = false
is_boat             = false
is_bike             = false
validModel          = false
has_xenon           = false
tire_smoke          = false
purge_started       = false
nos_started         = false
twostep_started     = false
is_typing           = false
open_sounds_window  = false
started_lct         = false
launch_active       = false
started_popSound    = false
started_popSound2   = false
customSmokeCol      = false
pedGrabber          = false
ped_grabbed         = false
vehicleGrabber      = false
vehicle_grabbed     = false
carpool             = false
show_npc_veh_ctrls  = false
stop_searching      = false
hijack_started      = false
sound_btn_off       = false
is_drifting         = false
start_rgb_loop      = false
flag                = 0
grp_anim_index      = 0
attached_ped        = 0
grabbed_veh         = 0
thisVeh             = 0
anim_index          = 0
scenario_index      = 0
npc_index           = 0
actions_switch      = 0
Entity              = 0
timerA              = 0
timerB              = 0
lastVeh             = 0
defaultXenon        = 0
vehSound_index      = 0
driftSmokeIndex     = 0
selected_smoke_col  = 0
pBus                = 0
dummyDriver         = 0
dummyCopCar         = 0
sound_index1        = 0
sound_index2        = 0
sound_switch        = 0
radio_index         = 0
drift_points        = 0
drift_extra_pts     = 0
straight_counter    = 0
drift_time          = 0
drift_multiplier    = 1
quote_alpha         = 1
pedthrowF           = 10
tdBtn               = 21
stop_anim           = 47
play_anim           = 256
previous_anim       = 316
next_anim           = 317
drift_streak_text   = ""
drift_extra_text    = ""
actions_search      = ""
currentMvmt         = ""
currentStrf         = ""
currentWmvmt        = ""
search_term         = ""
smokeHex            = ""
random_quote        = ""
selected_sound      = {}
selected_radio      = {}
smokePtfx_t         = {}
nosptfx_t           = {}
purgePtfx_t         = {}
lctPtfx_t           = {}
popSounds_t         = {}
popsPtfx_t          = {}
npc_blips           = {}
spawned_npcs        = {}
plyrProps           = {}
npcProps            = {}
selfPTFX            = {}
npcPTFX             = {}
curr_playing_anim   = {}
laserPtfx_T         = {}
chosen_anim         = {}

---@param musicSwitch string
---@param station? string
function play_music(musicSwitch, station)
  script.run_in_fiber(function(mp)
    if musicSwitch == "start" then
      local myPos       = self.get_pos()
      local bone_idx    = PED.GET_PED_BONE_INDEX(self.get_ped(), 24818)
      local pbus_model  = 345756458
      local dummy_model = 0xE75B4B1C
      if Game.requestModel(pbus_model) then
        pBus = VEHICLE.CREATE_VEHICLE(pbus_model, myPos.x, myPos.y, (myPos.z - 10), 0, true, false, false)
        ENTITY.SET_ENTITY_ALPHA(pBus, 0.0, false)
        ENTITY.FREEZE_ENTITY_POSITION(pBus, true)
        ENTITY.SET_ENTITY_COLLISION(pBus, false, 0)
        ENTITY.SET_ENTITY_INVINCIBLE(pBus, true)
        VEHICLE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(pBus, false, 0)
      end
      mp:sleep(500)
      if ENTITY.DOES_ENTITY_EXIST(pBus) then
        entities.take_control_of(pBus, 300)
        if Game.requestModel(dummy_model) then
          dummyDriver = PED.CREATE_PED("PED_TYPE_CIVMALE", dummy_model, myPos.x, myPos.y, (myPos.z + 40), 0, true, false)
          if ENTITY.DOES_ENTITY_EXIST(dummyDriver) then
            entities.take_control_of(dummyDriver, 300)
            ENTITY.SET_ENTITY_ALPHA(dummyDriver, 0.0, false)
            PED.SET_PED_INTO_VEHICLE(dummyDriver, pBus, -1)
            PED.SET_PED_CONFIG_FLAG(dummyDriver, 402, true)
            PED.SET_PED_CONFIG_FLAG(dummyDriver, 398, true)
            PED.SET_PED_CONFIG_FLAG(dummyDriver, 167, true)
            PED.SET_PED_CONFIG_FLAG(dummyDriver, 251, true)
            PED.SET_PED_CONFIG_FLAG(dummyDriver, 255, true)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(dummyDriver, true)
            AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(pBus, vehicles.get_vehicle_display_name(2765724541))
            VEHICLE.SET_VEHICLE_ENGINE_ON(pBus, true, false, false)
            AUDIO.SET_VEHICLE_RADIO_LOUD(pBus, true)
            VEHICLE.SET_VEHICLE_LIGHTS(pBus, 1)
            mp:sleep(500)
            AUDIO.SET_VEH_RADIO_STATION(pBus, station)
            mp:sleep(500)
            ENTITY.ATTACH_ENTITY_TO_ENTITY(pBus, self.get_ped(), bone_idx, -4.0, -1.3, -1.0, 0.0, 90.0, -90.0, false, true,
            false, true, 1, true, 1)
          else
            gui.show_error("Samurais Scripts", "Failed to start music!")
            return
          end
        end
      else
        gui.show_error("Samurais Scripts", "Failed to start music!")
        return
      end
    elseif musicSwitch == "stop" then
      if ENTITY.DOES_ENTITY_EXIST(dummyDriver) then
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(dummyDriver, true, true)
        mp:sleep(200)
        ENTITY.DELETE_ENTITY(dummyDriver)
        dummyDriver = 0
      end
      if ENTITY.DOES_ENTITY_EXIST(pBus) then
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(pBus, true, true)
        mp:sleep(200)
        ENTITY.DELETE_ENTITY(pBus)
        pBus = 0
      end
    end
  end)
end

function dummyCop()
  script.run_in_fiber(function(dcop)
    if current_vehicle ~= nil and current_vehicle ~= 0 then
      local polhash, veh_bone1, veh_bone2, attach_mode
      if is_car then
        if VEHICLE.DOES_VEHICLE_HAVE_ROOF(current_vehicle) and not VEHICLE.IS_VEHICLE_A_CONVERTIBLE(current_vehicle) then
          polhash, veh_bone1, veh_bone2, attach_mode = 0xD1E0B7D7, "interiorlight", "interiorlight", 1
        else
          polhash, veh_bone1, veh_bone2, attach_mode = 0xD1E0B7D7, "interiorlight", "dashglow", 2
        end
      elseif is_bike or is_quad then
        polhash, veh_bone1, veh_bone2, attach_mode = 0xFDEFAEC3, "chassis_dummy", "chassis_dummy", 1
      else
        gui.show_error("Samurais Scripts", "Can not equip a fake siren on this vehicle.")
      end
      if Game.requestModel(polhash) then
        dummyCopCar = VEHICLE.CREATE_VEHICLE(polhash, 0.0, 0.0, 0.0, 0, true, false, false)
        ENTITY.SET_ENTITY_COLLISION(dummyCopCar, false, 0)
        VEHICLE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(dummyCopCar, false, 0)
        VEHICLE.SET_VEHICLE_UNDRIVEABLE(dummyCopCar, true)
        ENTITY.SET_ENTITY_ALPHA(dummyCopCar, 49.0, false)
        ENTITY.SET_ENTITY_INVINCIBLE(dummyCopCar, true)
      end
      if ENTITY.DOES_ENTITY_EXIST(dummyCopCar) then
        entities.take_control_of(dummyCopCar, 300)
        local boneidx1 = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(dummyCopCar, veh_bone1)
        local boneidx2 = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(self.get_veh(), veh_bone2)
        VEHICLE.SET_VEHICLE_LIGHTS(dummyCopCar, 1)
        ENTITY.SET_ENTITY_HEADING(dummyCopCar, ENTITY.GET_ENTITY_HEADING(self.get_veh()))
        if attach_mode == 1 then
          ENTITY.ATTACH_ENTITY_BONE_TO_ENTITY_BONE(dummyCopCar, self.get_veh(), boneidx1, boneidx2, false, true)
        else
          ENTITY.ATTACH_ENTITY_TO_ENTITY(dummyCopCar, self.get_veh(), boneidx2, 0.46, 0.4, -0.9, 0.0, 0.0, 0.0, false, true,
            false, true, 1, true, 1)
        end
        dcop:sleep(500)
        VEHICLE.SET_VEHICLE_SIREN(dummyCopCar, true)
        VEHICLE.SET_VEHICLE_HAS_MUTED_SIRENS(dummyCopCar, false)
        AUDIO.TRIGGER_SIREN_AUDIO(dummyCopCar)
        VEHICLE.SET_VEHICLE_ACT_AS_IF_HAS_SIREN_ON(self.get_veh(), true)
        VEHICLE.SET_VEHICLE_CAUSES_SWERVING(self.get_veh(), true)
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(self.get_veh(), 0, true)
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(self.get_veh(), 1, true)
      end
    end
  end)
end

function showDriftCounter(text)
  wolrdPos = self.get_pos()
  local _, screenX, screenY = HUD.GET_HUD_SCREEN_POSITION_FROM_WORLD_POSITION(wolrdPos.x, wolrdPos.y, wolrdPos.z, screenX, screenY)
  HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("TWOSTRINGS")
  HUD.SET_TEXT_COLOUR(255, 192, 0, 200)
  HUD.SET_TEXT_SCALE(1, 0.7)
  HUD.SET_TEXT_OUTLINE()
  HUD.SET_TEXT_FONT(7)
  HUD.SET_TEXT_CENTRE(true)
  HUD.SET_TEXT_DROP_SHADOW()
  HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
  HUD.END_TEXT_COMMAND_DISPLAY_TEXT(screenX, (screenY - 0.6), 0)
end

function showDriftExtra(text)
  wolrdPos = self.get_pos()
  local _, screenX, screenY = HUD.GET_HUD_SCREEN_POSITION_FROM_WORLD_POSITION(wolrdPos.x, wolrdPos.y, wolrdPos.z, screenX, screenY)
  HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("TWOSTRINGS")
  HUD.SET_TEXT_COLOUR(255, 192, 0, 200)
  HUD.SET_TEXT_SCALE(1, 0.4)
  HUD.SET_TEXT_OUTLINE()
  HUD.SET_TEXT_FONT(7)
  HUD.SET_TEXT_CENTRE(true)
  HUD.SET_TEXT_DROP_SHADOW()
  HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
  HUD.END_TEXT_COMMAND_DISPLAY_TEXT(screenX, (screenY - 0.5142), 0)
end

function checkDriftCollision()
  local crashed     = false
  local text        = ""
  local entity      = ENTITY.GET_LAST_ENTITY_HIT_BY_ENTITY_(self.get_veh())
  local entity_type = Game.getEntityTypeString(entity)
  if ENTITY.IS_ENTITY_A_PED(entity) then
    text = "Hit and run"
    crashed = false
  elseif entity_type == "Vehicle" then
    text = "Samir, you're breaking the car!"
    crashed = true
  elseif entity_type == "Object" then
    -- ENTITY.GET_ENTITY_MODEL(entity) ~= 3300474446 and ENTITY.GET_ENTITY_MODEL(entity) ~= 3231494328 and ENTITY.GET_ENTITY_MODEL(entity) ~= 3008087081 and ENTITY.GET_ENTITY_MODEL(entity) ~= 874602658
    if ENTITY.GET_ENTITY_SPEED(self.get_veh()) > 5 then
      text = "Wrecking ball"
      crashed = false
    else
      text = "Samir, you're breaking the car!"
      crashed = true
    end
  elseif entity_type == "None" or entity_type == "Invalid" then
    text = "Samir, you're breaking the car!"
    crashed = true
  end
  return crashed, text
end

function bankDriftPoints_SP(points)
  local chars_T = {
    {hash = 225514697,  int = 0},
    {hash = 2602752943, int = 1},
    {hash = 2608926626, int = 2},
  }
  script.run_in_fiber(function()
    for _, v in ipairs(chars_T) do
      if ENTITY.GET_ENTITY_MODEL(self.get_ped()) == v.hash then
        stats.set_int("SP"..tostring(v.int).."_TOTAL_CASH", stats.get_int("SP"..tostring(v.int).."_TOTAL_CASH") + points)
        AUDIO.PLAY_SOUND_FRONTEND(-1, "LOCAL_PLYR_CASH_COUNTER_INCREASE", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS")
      end
    end
  end)
end

Samurais_scripts:add_imgui(function()
  local YY, MM, DD, H, M, S = CLOCK.GET_LOCAL_TIME(YY, MM, DD, H, M, S)
  if MM < 10 then
    MM = 0 .. MM
  end
  if DD < 10 then
    DD = 0 .. DD
  end
  if H < 10 then
    H = 0 .. H
  end
  if M < 10 then
    M = 0 .. M
  end
  if S < 10 then
    S = 0 .. S
  end
  local date_str = DD .. "-" .. months_T[tonumber(MM)] .. "-" .. YY
  local time_str = H .. ":" .. M .. ":" .. S
  local combined_str = "\10" .. "        " .. time_str .. "\10    " .. date_str .. "    " .. "\10\10"
  ImGui.Dummy(1, 10); ImGui.Dummy(150, 1); ImGui.SameLine();
  ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 80)
  UI.coloredButton(combined_str, '#A67C00', '#A67C00', '#A67C00', 0.15)
  ImGui.PopStyleVar()
  ImGui.Dummy(1, 10); ImGui.SeparatorText("About")
  UI.wrappedText("A collection of scripts aimed towards adding some roleplaying and fun elements to the game.", 25)
  ImGui.Dummy(1, 10)
  ImGui.BulletText("Script Version:   v" .. SCRIPT_VERSION)
  ImGui.BulletText("Game Version:   b" .. TARGET_BUILD .. "   Online " .. TARGET_VERSION)
  ImGui.Dummy(1, 20); ImGui.SeparatorText("Quote Of The Day"); ImGui.Spacing()
  UI.coloredText(random_quote, 'white', quote_alpha, 24)
end)

--[[
    *self*
]]
self_tab = Samurais_scripts:add_tab(translateLabel("Self"))
self_tab:add_imgui(function()
  Regen, RegenUsed = ImGui.Checkbox(translateLabel("Auto-Heal"), Regen, true)
  UI.helpMarker(false, translateLabel("autoheal_tooltip"))
  if RegenUsed then
    lua_cfg.save("Regen", Regen)
    UI.widgetSound("Nav2")
  end

  -- objectiveTP, objectiveTPUsed = ImGui.Checkbox(translateLabel("objectiveTP"), objectiveTP, true)
  -- UI.helpMarker(false, translateLabel("objectiveTP_tooltip"))
  -- if objectiveTPUsed then
  --   lua_cfg.save("objectiveTP", objectiveTP)
  --   UI.widgetSound("Nav2")
  -- end

  replaceSneakAnim, rsanimUsed = ImGui.Checkbox(translateLabel("CrouchCB"), replaceSneakAnim, true)
  UI.helpMarker(false, translateLabel("Crouch_tooltip"))
  if rsanimUsed then
    lua_cfg.save("replaceSneakAnim", replaceSneakAnim)
    UI.widgetSound("Nav2")
  end 

  replacePointAct, rpaUsed = ImGui.Checkbox(translateLabel("rpaCB"), replacePointAct, true)
  UI.helpMarker(false, translateLabel("rpa_tooltip"))
  if rpaUsed then
    lua_cfg.save("replacePointAct", replacePointAct)
    UI.widgetSound("Nav2")
  end

  phoneAnim, phoneAnimUsed = ImGui.Checkbox(translateLabel("PhoneAnimCB"), phoneAnim, true)
  UI.helpMarker(false, translateLabel("PhoneAnim_tooltip"))
  if phoneAnimUsed then
    lua_cfg.save("phoneAnim", phoneAnim)
    UI.widgetSound("Nav2")
  end

  sprintInside, sprintInsideUsed = ImGui.Checkbox(translateLabel("SprintInsideCB"), sprintInside, true)
  UI.helpMarker(false,
    translateLabel("SprintInside_tooltip"))
  if sprintInsideUsed then
    lua_cfg.save("sprintInside", sprintInside)
    UI.widgetSound("Nav2")
  end

  lockPick, lockPickUsed = ImGui.Checkbox(translateLabel("LockpickCB"), lockPick, true)
  UI.helpMarker(false,
    translateLabel("Lockpick_tooltip"))
  if lockPickUsed then
    lua_cfg.save("lockPick", lockPick)
    UI.widgetSound("Nav2")
  end

  disableActionMode, actionModeUsed = ImGui.Checkbox(translateLabel("ActionModeCB"), disableActionMode, true)
  UI.helpMarker(false, translateLabel("ActionMode_tooltip"))
  if actionModeUsed then
    lua_cfg.save("disableActionMode", disableActionMode)
    UI.widgetSound("Nav2")
  end

  clumsy, clumsyUsed = ImGui.Checkbox("Clumsy", clumsy, true)
  UI.helpMarker(false, translateLabel("clumsy_tt"))
  if clumsyUsed then
    rod = false
    lua_cfg.save("rod", false)
    lua_cfg.save("clumsy", clumsy)
    UI.widgetSound("Nav2")
  end
  if clumsy and clumsyUsed then
    script.run_in_fiber(function()
      if not PED.CAN_PED_RAGDOLL(self.get_ped()) then
        gui.show_warning("Samurais Scripts", "This option will not work if you're blocking ragdoll. Please make sure 'No Ragdoll' option is disabled in YimMennu.")
      end
    end)
  end

  rod, rodUsed = ImGui.Checkbox("Ragdoll On Demand", rod, true)
  UI.helpMarker(false, translateLabel("rod_tt"))
  if rodUsed then
    clumsy = false
    lua_cfg.save("rod", rod)
    lua_cfg.save("clumsy", false)
    UI.widgetSound("Nav2")
  end
  if rod and rodUsed then
    script.run_in_fiber(function()
      if not PED.CAN_PED_RAGDOLL(self.get_ped()) then
        gui.show_warning("Samurais Scripts", "This option will not work if you're blocking ragdoll. Please make sure 'No Ragdoll' option is disabled in YimMennu.")
      end
    end)
  end
end)


Actions = self_tab:add_tab("Actions")

local function updatefilteredAnims()
  filteredAnims = {}
  for _, anim in ipairs(animlist) do
    if string.find(string.lower(anim.name), string.lower(actions_search)) then
      table.insert(filteredAnims, anim)
    end
  end
  table.sort(animlist, function(a, b)
    return a.name < b.name
  end)
end

local function displayFilteredAnims()
  updatefilteredAnims()
  local animNames = {}
  for _, anim in ipairs(filteredAnims) do
    table.insert(animNames, anim.name)
  end
  anim_index, used = ImGui.ListBox("##animlistbox", anim_index, animNames, #filteredAnims)
end

local function updatefilteredScenarios()
  filteredScenarios = {}
  for _, scene in ipairs(ped_scenarios) do
    if string.find(string.lower(scene.name), string.lower(actions_search)) then
      table.insert(filteredScenarios, scene)
    end
  end
end

local function displayFilteredScenarios()
  updatefilteredScenarios()
  local scenarioNames = {}
  for _, scene in ipairs(filteredScenarios) do
    table.insert(scenarioNames, scene.name)
  end
  scenario_index, used = ImGui.ListBox("##scenarioList", scenario_index, scenarioNames, #filteredScenarios)
end

local function updateNpcs()
  filteredNpcs = {}
  for _, npc in ipairs(npcList) do
    table.insert(filteredNpcs, npc)
  end
  table.sort(filteredNpcs, function(a, b)
    return a.name < b.name
  end)
end

local function displayNpcs()
  updateNpcs()
  local npcNames = {}
  for _, npc in ipairs(filteredNpcs) do
    table.insert(npcNames, npc.name)
  end
  npc_index, used = ImGui.Combo("##npcList", npc_index, npcNames, #filteredNpcs)
end

local function setmanualflag()
  if looped then
    flag_loop = 1
  else
    flag_loop = 0
  end
  if freeze then
    flag_freeze = 2
  else
    flag_freeze = 0
  end
  if upperbody then
    flag_upperbody = 16
  else
    flag_upperbody = 0
  end
  if controllable then
    flag_control = 32
  else
    flag_control = 0
  end
  flag = flag_loop + flag_freeze + flag_upperbody + flag_control
end

local function setdrunk()
    script.run_in_fiber(function()
        -- PED.SET_PED_USING_ACTION_MODE(PLAYER.PLAYER_ID(), false, -1, -1)
        while not STREAMING.HAS_CLIP_SET_LOADED("move_m@drunk@verydrunk") and not STREAMING.HAS_CLIP_SET_LOADED("move_strafe@first_person@drunk") do
            STREAMING.REQUEST_CLIP_SET("move_m@drunk@verydrunk")
            STREAMING.REQUEST_CLIP_SET("move_strafe@first_person@drunk")
            coroutine.yield()
        end
        PED.SET_PED_MOVEMENT_CLIPSET(self.get_ped(), "move_m@drunk@verydrunk", 1.0)
        PED.SET_PED_WEAPON_MOVEMENT_CLIPSET(self.get_ped(), "move_m@drunk@verydrunk")
        PED.SET_PED_STRAFE_CLIPSET(self.get_ped(), "move_strafe@first_person@drunk")
        WEAPON.SET_WEAPON_ANIMATION_OVERRIDE(self.get_ped(), 2231620617)
        currentMvmt  = "move_m@drunk@verydrunk"
        currentWmvmt = "move_m@drunk@verydrunk"
        currentStrf  = "move_strafe@first_person@drunk"
    end)
end

local function sethoe()
  script.run_in_fiber(function()
      while not STREAMING.HAS_CLIP_SET_LOADED("move_f@maneater") do
          STREAMING.REQUEST_CLIP_SET("move_f@maneater")
          coroutine.yield()
      end
      PED.RESET_PED_WEAPON_MOVEMENT_CLIPSET(self.get_ped())
      PED.RESET_PED_STRAFE_CLIPSET(self.get_ped())
      PED.SET_PED_MOVEMENT_CLIPSET(self.get_ped(), "move_f@maneater", 1.0)
      WEAPON.SET_WEAPON_ANIMATION_OVERRIDE(self.get_ped(), 1830115867)
      currentMvmt  = "move_f@maneater"
      currentWmvmt = ""
      currentStrf  = ""
  end)
end

local function setgangsta()
  script.run_in_fiber(function()
      while not STREAMING.HAS_CLIP_SET_LOADED("move_m@gangster@ng") do
          STREAMING.REQUEST_CLIP_SET("move_m@gangster@ng")
          coroutine.yield()
      end
      while not STREAMING.HAS_CLIP_SET_LOADED("move_strafe@gang") do
          STREAMING.REQUEST_CLIP_SET("move_strafe@gang")
          coroutine.yield()
      end
      PED.RESET_PED_WEAPON_MOVEMENT_CLIPSET(self.get_ped())
      PED.SET_PED_MOVEMENT_CLIPSET(self.get_ped(), "move_m@gangster@ng", 0.3)
      PED.SET_PED_STRAFE_CLIPSET(self.get_ped(), "move_strafe@gang")
      WEAPON.SET_WEAPON_ANIMATION_OVERRIDE(self.get_ped(), 1917483703)
      currentMvmt  = "move_m@gangster@ng"
      currentStrf  = "move_strafe@gang"
      currentWmvmt = ""
  end)
end

local function setlester()
  script.run_in_fiber(function()
      while not STREAMING.HAS_CLIP_SET_LOADED("move_heist_lester") do
          STREAMING.REQUEST_CLIP_SET("move_heist_lester")
          coroutine.yield()
      end
      PED.RESET_PED_WEAPON_MOVEMENT_CLIPSET(self.get_ped())
      PED.RESET_PED_STRAFE_CLIPSET(self.get_ped())
      PED.SET_PED_MOVEMENT_CLIPSET(self.get_ped(), "move_heist_lester", 0.4)
      WEAPON.SET_WEAPON_ANIMATION_OVERRIDE(self.get_ped(), 2231620617)
      currentMvmt  = "move_heist_lester"
      currentWmvmt = ""
      currentStrf  = ""
  end)
end

local function setballistic()
  script.run_in_fiber(function()
      while not STREAMING.HAS_CLIP_SET_LOADED("anim_group_move_ballistic") and not STREAMING.HAS_CLIP_SET_LOADED("move_strafe@ballistic") do
          STREAMING.REQUEST_CLIP_SET("anim_group_move_ballistic")
          STREAMING.REQUEST_CLIP_SET("move_strafe@ballistic")
          coroutine.yield()
      end
      PED.RESET_PED_WEAPON_MOVEMENT_CLIPSET(self.get_ped())
      PED.SET_PED_MOVEMENT_CLIPSET(self.get_ped(), "anim_group_move_ballistic", 1)
      PED.SET_PED_STRAFE_CLIPSET(self.get_ped(), "move_strafe@ballistic")
      WEAPON.SET_WEAPON_ANIMATION_OVERRIDE(self.get_ped(), 1429513766)
      currentMvmt = "anim_group_move_ballistic"
      currentStrf = "move_strafe@ballistic"
      currentWmvmt = ""
  end)
end

function onAnimInterrupt()
  script.run_in_fiber(function()
    if Game.requestAnimDict(curr_playing_anim.curr_dict) then
      TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
      TASK.TASK_PLAY_ANIM(self.get_ped(), curr_playing_anim.curr_dict, curr_playing_anim.curr_anim, 4.0, -4.0, -1, curr_playing_anim.curr_flag, 1.0, false, false, false)
    end
  end)
end

Actions:add_imgui(function()
  ImGui.PushItemWidth(270)
  actions_search, used = ImGui.InputTextWithHint("##searchBar", translateLabel("search_hint"), actions_search, 32)
  ImGui.PopItemWidth()
  if ImGui.IsItemActive() then
    is_typing = true
  else
    is_typing = false
  end
  ImGui.BeginTabBar("Actionz", ImGuiTabBarFlags.None)
  if ImGui.BeginTabItem(translateLabel("animations")) then
    if tab1Sound then
      UI.widgetSound("Nav")
      tab1Sound = false
      tab2Sound = true
      tab3Sound = true
    end
    ImGui.PushItemWidth(345)
    displayFilteredAnims()
    ImGui.PopItemWidth()
    info = filteredAnims[anim_index + 1]
    ImGui.Separator(); manualFlags, used = ImGui.Checkbox("Edit Flags", manualFlags, true)
    if used then
      lua_cfg.save("manualFlags", manualFlags)
      UI.widgetSound("Nav2")
    end
    UI.helpMarker(false, translateLabel("flags_tt"))
    ImGui.SameLine(); disableProps, used = ImGui.Checkbox("Disable Props", disableProps, true)
    if used then
      lua_cfg.save("disableProps", disableProps)
      UI.widgetSound("Nav2")
    end
    UI.helpMarker(false, translateLabel("DisableProps_tt"))
    if manualFlags then
      ImGui.Separator()
      controllable, used = ImGui.Checkbox(translateLabel("Allow Control"), controllable, true)
      if used then
        lua_cfg.save("controllable", controllable)
        UI.widgetSound("Nav2")
      end
      UI.helpMarker(false, translateLabel("AllowControl_tt"))
      ImGui.SameLine(); ImGui.Dummy(27, 1); ImGui.SameLine()
      looped, used = ImGui.Checkbox("Loop", looped, true)
      if used then
        lua_cfg.save("looped", looped)
        UI.widgetSound("Nav2")
      end
      UI.helpMarker(false, translateLabel("looped_tt"))
      upperbody, used = ImGui.Checkbox(translateLabel("Upper Body Only"), upperbody, true)
      if used then
        lua_cfg.save("upperbody", upperbody)
        UI.widgetSound("Nav2")
      end
      UI.helpMarker(false, translateLabel("UpperBodyOnly_tt"))
      ImGui.SameLine(); ImGui.Dummy(1, 1); ImGui.SameLine()
      freeze, used = ImGui.Checkbox(translateLabel("Freeze"), freeze, true)
      if used then
        lua_cfg.save("freeze", freeze)
        UI.widgetSound("Nav2")
      end
      UI.helpMarker(false, translateLabel("Freeze_tt"))
    end
    if ImGui.Button(translateLabel("generic_play_btn") .. "##anim") then
      if not ped_grabbed then
        UI.widgetSound("Select")
        local coords     = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
        local heading    = ENTITY.GET_ENTITY_HEADING(self.get_ped())
        local forwardX   = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
        local forwardY   = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
        local boneIndex  = PED.GET_PED_BONE_INDEX(self.get_ped(), info.boneID)
        local bonecoords = PED.GET_PED_BONE_COORDS(self.get_ped(), info.boneID)
        if manualFlags then
          setmanualflag()
        else
          flag = info.flag
        end
        curr_playing_anim = {curr_dict = info.dict, curr_anim = info.anim, curr_flag = flag, curr_name = info.name}
        if lua_Fn.str_contains(curr_playing_anim.curr_name, "DJ") then
          if not is_playing_radio and not anim_music then
            play_music("start", "RADIO_22_DLC_BATTLE_MIX1_RADIO")
            anim_music = true
          end
        else
          if anim_music then
            play_music("stop")
            anim_music = false
          end
        end
        playSelected(self.get_ped(), flag, selfprop1, selfprop2, selfloopedFX, selfSexPed, boneIndex, coords, heading, forwardX,
          forwardY, bonecoords, "self", plyrProps, selfPTFX)
        is_playing_anim = true
      else
        UI.widgetSound("Error")
        gui.show_error("Samurais Scripts", translateLabel("You can not play animations while grabbing an NPC."))
      end
    end
    ImGui.SameLine()
    if ImGui.Button(translateLabel("generic_stop_btn") .. "##anim") then
      if is_playing_anim then
        UI.widgetSound("Cancel")
        if PED.IS_PED_SITTING_IN_ANY_VEHICLE(self.get_ped()) then
          local veh    = PED.GET_VEHICLE_PED_IS_IN(self.get_ped(), false)
          local mySeat = Game.getPedVehicleSeat(self.get_ped())
          cleanup()
          PED.SET_PED_INTO_VEHICLE(self.get_ped(), self.get_veh(), mySeat)
        else
          cleanup()
          local current_coords = self.get_pos()
          ENTITY.SET_ENTITY_COORDS_NO_OFFSET(self.get_ped(), current_coords.x, current_coords.y, current_coords.z, true,
            false, false)
        end
        if anim_music then
          play_music("stop")
          anim_music = false
        end
        is_playing_anim = false
      else
        UI.widgetSound("Error")
      end
    end
    UI.toolTip(false, translateLabel("stopAnims_tt"))
    ImGui.SameLine()
    local errCol = {}
    local errSound = false
    if plyrProps[1] ~= nil then
      errCol = { 104, 247, 114, 0.2 }
      errSound = false
    else
      errCol = { 225, 0, 0, 0.5 }
      errSound = true
    end
    if UI.coloredButton(translateLabel("Remove Attachments"), {104, 247, 114}, {104, 247, 114}, errCol, 0.6) then
      if not errSound then
        UI.widgetSound("Cancel")
      else
        UI.widgetSound("Error")
      end
      script.run_in_fiber(function()
        if all_objects == nil then
          all_objects = entities.get_all_objects_as_handles()
        end
        for _, v in ipairs(all_objects) do
          local modelHash      = ENTITY.GET_ENTITY_MODEL(v)
          local attachedObject = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(self.get_ped(), modelHash)
          if ENTITY.DOES_ENTITY_EXIST(attachedObject) then
            ENTITY.DETACH_ENTITY(attachedObject, true, true)
            ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(attachedObject)
            TASK.CLEAR_PED_TASKS(self.get_ped())
          end
        end
        if all_peds == nil then
          all_peds = entities.get_all_peds_as_handles()
        end
        for _, p in ipairs(all_peds) do
          local pedHash     = ENTITY.GET_ENTITY_MODEL(p)
          local attachedPed = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(self.get_ped(), pedHash)
          if ENTITY.DOES_ENTITY_EXIST(attachedPed) then
            ENTITY.DETACH_ENTITY(attachedPed, true, true)
            TASK.CLEAR_PED_TASKS(self.get_ped())
            TASK.CLEAR_PED_TASKS(attachedPed)
            ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(attachedPed)
          end
        end
        is_playing_anim = false
        if is_playing_scenario then
          if ENTITY.DOES_ENTITY_EXIST(bbq) then
            ENTITY.DELETE_ENTITY(bbq)
          end
          is_playing_scenario = false
        end
        if ped_grabbed then
          ENTITY.FREEZE_ENTITY_POSITION(attached_ped, false)
          TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(attached_ped, false)
          PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(attached_ped, false)
          PED.SET_PED_TO_RAGDOLL(attached_ped, 1500, 0, 0, false)
          TASK.CLEAR_PED_TASKS(self.get_ped())
          PED.SET_PED_CAN_SWITCH_WEAPON(self.get_ped(), true)
        end
        if plyrProps[1] ~= nil then
          for _, v in ipairs(plyrProps) do
            table.remove(v)
          end
        else
          if not ped_grabbed then
            gui.show_error("Samurais Scripts", "There are no objects or peds attached.")
          else
            ped_grabbed = false
          end
        end
      end)
    end
    UI.toolTip(false, translateLabel("RemoveAttachments_tt"))
    if LANG == 'en-US' then
      ImGui.SameLine()
    end
    if info ~= nil then
      if shortcut_anim.name ~= info.name then
        if ImGui.Button(translateLabel("animShortcut_btn")) then
          chosen_anim = info
          UI.widgetSound("Select2")
          ImGui.OpenPopup("Set Shortcut")
        end
        UI.toolTip(false, translateLabel("animShortcut_tt"))
        ImGui.SetNextWindowPos(760, 400, ImGuiCond.Appearing)
        ImGui.SetNextWindowBgAlpha(0.9)
        if ImGui.BeginPopupModal("Set Shortcut", true, ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
          if btn_name == nil then
            script.run_in_fiber(function()
              for i = 1, 360 do
                if PAD.IS_CONTROL_JUST_PRESSED(0, i) then
                  btn, btn_name = UI.getKeyPressed()
                  break
                end
              end
            end)
          end
          UI.coloredText("Selected Animation:  ", "green", 0.9, 20); ImGui.SameLine(); ImGui.Text("« " .. chosen_anim.name .. " »")
          ImGui.Dummy(1, 10)
          if btn_name == nil then
            start_loading_anim = true
            UI.coloredText(translateLabel("input_waiting") .. loading_label, "#FFFFFF", 0.75, 20)
          else
            start_loading_anim = false
            for _, key in pairs(reserved_keys_T) do
              if btn == key then
                _reserved = true
                break
              else
                _reserved = false
              end
            end
            if not _reserved then
              ImGui.Text("Shortcut Button: "); ImGui.SameLine(); ImGui.Text(btn_name)
            else
              UI.coloredText(translateLabel("reserved_button"), "red", 0.86, 20)
            end
            ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine()
            if UI.coloredButton(" " .. translateLabel("generic_clear_btn") .. " ##Shortcut", "#FFDB58", "#FFFAA0", "#FFFFF0", 0.7) then
              UI.widgetSound("Error")
              btn, btn_name = nil, nil
            end
          end
          ImGui.Dummy(1, 10)
          if not _reserved and btn ~= nil then
            if ImGui.Button(translateLabel("generic_confirm_btn") .. "##shotcut") then
              UI.widgetSound("Select")
              if manualFlags then
                setmanualflag()
              else
                flag = chosen_anim.flag
              end
              shortcut_anim     = chosen_anim
              shortcut_anim.btn = btn
              lua_cfg.save("shortcut_anim", shortcut_anim)
              gui.show_success("Samurais Scripts", translateLabel("shortcut_success_1/2") .. btn_name .. translateLabel("shortcut_success_2/2"))
              ImGui.CloseCurrentPopup()
            end
            ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
          end
          if ImGui.Button(translateLabel("generic_cancel_btn") .. "##shotcut") then
            UI.widgetSound("Cancel")
            btn, btn_name = nil, nil
            start_loading_anim = false
            ImGui.CloseCurrentPopup()
          end
          ImGui.End()
        end
      else
        if ImGui.Button(translateLabel("removeShortcut_btn")) then
          UI.widgetSound("Delete")
          shortcut_anim = {}
          lua_cfg.save("shortcut_anim", {})
          gui.show_success("Samurais Scripts", "Animation shortcut has been reset. Please reload the script!")
        end
        UI.toolTip(false, translateLabel("removeShortcut_tt"))
      end
    end
    ImGui.Spacing(); ImGui.SeparatorText(translateLabel("Movement Options:")); ImGui.Spacing()
    local isChanged = false
    actions_switch, isChanged = ImGui.RadioButton("Normal", actions_switch, 0)
    if isChanged then
      UI.widgetSound("Nav")
      PED.RESET_PED_MOVEMENT_CLIPSET(self.get_ped(), 0.3)
      PED.RESET_PED_STRAFE_CLIPSET(self.get_ped())
      PED.RESET_PED_WEAPON_MOVEMENT_CLIPSET(self.get_ped())
      WEAPON.SET_WEAPON_ANIMATION_OVERRIDE(self.get_ped(), 3839837909)
      currentMvmt  = ""
      currentStrf  = ""
      currentWmvmt = ""
      isChanged    = false
    end
    ImGui.SameLine(); ImGui.Dummy(23, 1); ImGui.SameLine()
    actions_switch, isChanged = ImGui.RadioButton("Drunk", actions_switch, 1)
    if isChanged then
      setdrunk()
      UI.widgetSound("Nav")
    end
    ImGui.SameLine(); ImGui.Dummy(22, 1); ImGui.SameLine()
    actions_switch, isChanged = ImGui.RadioButton("Hoe", actions_switch, 2)
    if isChanged then
      sethoe()
      UI.widgetSound("Nav")
    end
    actions_switch, isChanged = ImGui.RadioButton("Gangsta ", actions_switch, 3)
    if isChanged then
      setgangsta()
      UI.widgetSound("Nav")
    end
    ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
    actions_switch, isChanged = ImGui.RadioButton(" Lester ", actions_switch, 4)
    if isChanged then
      setlester()
      UI.widgetSound("Nav")
    end
    ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
    actions_switch, isChanged = ImGui.RadioButton("Heavy", actions_switch, 5)
    if isChanged then
      setballistic()
      UI.widgetSound("Nav")
    end
    ImGui.Spacing(); ImGui.SeparatorText(translateLabel("Play Animations On NPCs:"))
    ImGui.PushItemWidth(220)
    displayNpcs()
    ImGui.PopItemWidth()
    if UI.isItemClicked("lmb") then
      UI.widgetSound("Nav2")
    end
    ImGui.SameLine()
    npc_godMode, used = ImGui.Checkbox("Invincible", npc_godMode, true)
    if used then
      lua_cfg.save("npc_godMode", npc_godMode)
      UI.widgetSound("Nav")
    end
    UI.toolTip(false, translateLabel("Spawn NPCs in God Mode."))
    if ImGui.Button(translateLabel("Spawn") .. "##anim_npc") then
      UI.widgetSound("Select")
      script.run_in_fiber(function()
        local npcData     = filteredNpcs[npc_index + 1]
        local pedCoords   = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
        local pedHeading  = ENTITY.GET_ENTITY_HEADING(self.get_ped())
        local pedForwardX = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
        local pedForwardY = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
        local myGroup     = PED.GET_PED_GROUP_INDEX(self.get_ped())
        if not PED.DOES_GROUP_EXIST(myGroup) then
          myGroup = PED.CREATE_GROUP(0)
        end
        PED.SET_GROUP_SEPARATION_RANGE(myGroup, 16960)
        while not STREAMING.HAS_MODEL_LOADED(npcData.hash) do
          STREAMING.REQUEST_MODEL(npcData.hash)
          coroutine.yield()
        end
        npc = PED.CREATE_PED(npcData.group, npcData.hash, 0.0, 0.0, 0.0, 0.0, true, false)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(npc, pedCoords.x + pedForwardX * 1.4, pedCoords.y + pedForwardY * 1.4,
          pedCoords.z, true, false, false)
        ENTITY.SET_ENTITY_HEADING(npc, pedHeading - 180)
        PED.SET_PED_AS_GROUP_MEMBER(npc, myGroup)
        PED.SET_PED_NEVER_LEAVES_GROUP(npc, true)
        npcBlip = HUD.ADD_BLIP_FOR_ENTITY(npc)
        table.insert(npc_blips, npcBlip)
        HUD.SET_BLIP_AS_FRIENDLY(npcBlip, true)
        HUD.SET_BLIP_SCALE(npcBlip, 0.8)
        HUD.SHOW_HEADING_INDICATOR_ON_BLIP(npcBlip, true)
        WEAPON.GIVE_WEAPON_TO_PED(npc, 350597077, 9999, false, true)
        PED.SET_GROUP_FORMATION(myGroup, 2)
        PED.SET_GROUP_FORMATION_SPACING(myGroup, 1.0, 1.0, 1.0)
        PED.SET_PED_CONFIG_FLAG(npc, 179, true)
        PED.SET_PED_CONFIG_FLAG(npc, 294, true)
        PED.SET_PED_CONFIG_FLAG(npc, 398, true)
        PED.SET_PED_CONFIG_FLAG(npc, 401, true)
        PED.SET_PED_CONFIG_FLAG(npc, 443, true)
        PED.SET_PED_COMBAT_ABILITY(npc, 2)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 2, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 3, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 5, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 13, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 20, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 21, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 22, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 27, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 28, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 31, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 34, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 41, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 42, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 46, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 50, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 58, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 61, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 71, true)
        if npc_godMode then
          ENTITY.SET_ENTITY_INVINCIBLE(npc, true)
        end
        table.insert(spawned_npcs, npc)
      end)
    end
    ImGui.SameLine()
    if ImGui.Button(translateLabel("generic_delete") .. "##anim_npc") then
      UI.widgetSound("Delete")
      cleanupNPC()
      script.run_in_fiber(function()
        for k, v in ipairs(spawned_npcs) do
          if ENTITY.DOES_ENTITY_EXIST(v) then
            PED.REMOVE_PED_FROM_GROUP(v)
            ENTITY.DELETE_ENTITY(v)
          end
          table.remove(spawned_npcs, k)
        end
      end)
    end
    ImGui.SameLine()
    if ImGui.Button(translateLabel("generic_play_btn") .. "##npc_anim") then
      if spawned_npcs[1] ~= nil then
        UI.widgetSound("Select")
        for _, v in ipairs(spawned_npcs) do
          if ENTITY.DOES_ENTITY_EXIST(v) then
            local npcCoords      = ENTITY.GET_ENTITY_COORDS(v, false)
            local npcHeading     = ENTITY.GET_ENTITY_HEADING(v)
            local npcForwardX    = ENTITY.GET_ENTITY_FORWARD_X(v)
            local npcForwardY    = ENTITY.GET_ENTITY_FORWARD_Y(v)
            local npcBoneIndex   = PED.GET_PED_BONE_INDEX(v, info.boneID)
            local npcBboneCoords = PED.GET_PED_BONE_COORDS(v, info.boneID)
            if manualFlags then
              setmanualflag()
            else
              flag = info.flag
            end
            playSelected(v, flag, npcprop1, npcprop2, npcloopedFX, npcSexPed, npcBoneIndex, npcCoords, npcHeading, npcForwardX,
              npcForwardY, npcBboneCoords, "cunt", npcProps, npcPTFX)
          end
        end
      else
        UI.widgetSound("Error")
        gui.show_error("Samurais Scripts", "Spawn an NPC first!")
      end
    end
    ImGui.SameLine()
    if ImGui.Button(translateLabel("generic_stop_btn") .. "##npc_anim") then
      UI.widgetSound("Cancel")
      cleanupNPC()
      for _, v in ipairs(spawned_npcs) do
        script.run_in_fiber(function()
          if PED.IS_PED_IN_ANY_VEHICLE(v, false) then
            local veh      = PED.GET_VEHICLE_PED_IS_IN(v, false)
            local npcSeat  = Game.getPedVehicleSeat(v)
            PED.SET_PED_INTO_VEHICLE(v, veh, npcSeat)
          end
        end)
      end
    end
    usePlayKey, upkUsed = ImGui.Checkbox("Enable Animation Hotkeys", usePlayKey, true)
    UI.toolTip(false, translateLabel("animKeys_tt"))
    if upkUsed then
      lua_cfg.save("usePlayKey", usePlayKey)
      UI.widgetSound("Nav2")
    end
    ImGui.EndTabItem()
  end
  if ImGui.BeginTabItem(translateLabel("scenarios")) then
    if tab2Sound then
      UI.widgetSound("Nav2")
      tab2Sound = false
      tab1Sound = true
      tab3Sound = true
    end
    ImGui.PushItemWidth(335)
    displayFilteredScenarios()
    ImGui.PopItemWidth()
    ImGui.Separator()
    if ImGui.Button(translateLabel("generic_play_btn") .. "##scenarios") then
      if not ped_grabbed then
        UI.widgetSound("Select")
        if is_playing_anim then
          cleanup()
        end
        local data = filteredScenarios[scenario_index + 1]
        local coords = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
        local heading = ENTITY.GET_ENTITY_HEADING(self.get_ped())
        local forwardX = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
        local forwardY = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
        if data.name == "Cook On BBQ" then
          script.run_in_fiber(function()
            while not STREAMING.HAS_MODEL_LOADED(286252949) do
              STREAMING.REQUEST_MODEL(286252949)
              coroutine.yield()
            end
            bbq = OBJECT.CREATE_OBJECT(286252949, coords.x + (forwardX), coords.y + (forwardY), coords.z, true, true, false)
            ENTITY.SET_ENTITY_HEADING(bbq, heading)
            OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(bbq)
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
            TASK.TASK_START_SCENARIO_IN_PLACE(self.get_ped(), data.scenario, -1, true)
            is_playing_scenario = true
          end)
        else
          script.run_in_fiber(function()
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
            TASK.TASK_START_SCENARIO_IN_PLACE(self.get_ped(), data.scenario, -1, true)
            is_playing_scenario = true
            if ENTITY.DOES_ENTITY_EXIST(bbq) then
              ENTITY.DELETE_ENTITY(bbq)
            end
          end)
        end
      else
        gui.show_error("Samurais Scripts", translateLabel("You can not play scenarios while grabbing an NPC."))
      end
    end
    ImGui.SameLine(); ImGui.Dummy(60, 1); ImGui.SameLine()
    if ImGui.Button(translateLabel("generic_stop_btn") .. "##scenarios") then
      if is_playing_scenario then
        UI.widgetSound("Cancel")
        script.run_in_fiber(function(script)
          Game.busySpinnerOn(translateLabel("scenarios_spinner"), 3)
          TASK.CLEAR_PED_TASKS(self.get_ped())
          is_playing_scenario = false
          script:sleep(1000)
          Game.busySpinnerOff()
          if ENTITY.DOES_ENTITY_EXIST(bbq) then
            ENTITY.DELETE_ENTITY(bbq)
          end
        end)
      else
        UI.widgetSound("Error")
      end
    end
    UI.toolTip(false, translateLabel("stopScenarios_tt"))
    ImGui.Spacing(); ImGui.SeparatorText(translateLabel("Play Scenarios On NPCs:"))
    ImGui.PushItemWidth(220)
    displayNpcs()
    ImGui.PopItemWidth()
    ImGui.SameLine()
    npc_godMode, used = ImGui.Checkbox("Invincible", npc_godMode, true)
    UI.toolTip(false, translateLabel("Spawn NPCs in God Mode."))
    local npcData = filteredNpcs[npc_index + 1]
    if ImGui.Button(translateLabel("Spawn") .. "##scenario_npc") then
      UI.widgetSound("Select")
      script.run_in_fiber(function()
        local pedCoords = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
        local pedHeading = ENTITY.GET_ENTITY_HEADING(self.get_ped())
        local pedForwardX = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
        local pedForwardY = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
        local myGroup = PED.GET_PED_GROUP_INDEX(self.get_ped())
        if not PED.DOES_GROUP_EXIST(myGroup) then
          myGroup = PED.CREATE_GROUP(0)
        end
        while not STREAMING.HAS_MODEL_LOADED(npcData.hash) do
          STREAMING.REQUEST_MODEL(npcData.hash)
          coroutine.yield()
        end
        npc = PED.CREATE_PED(npcData.group, npcData.hash, 0.0, 0.0, 0.0, 0.0, true, false)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(npc, pedCoords.x + pedForwardX * 1.4, pedCoords.y + pedForwardY * 1.4,
          pedCoords.z, true, false, false)
        ENTITY.SET_ENTITY_HEADING(npc, pedHeading - 180)
        PED.SET_PED_AS_GROUP_MEMBER(npc, myGroup)
        PED.SET_PED_NEVER_LEAVES_GROUP(npc, true)
        npcBlip = HUD.ADD_BLIP_FOR_ENTITY(npc)
        HUD.SET_BLIP_AS_FRIENDLY(npcBlip, true)
        HUD.SET_BLIP_SCALE(npcBlip, 0.8)
        HUD.SHOW_HEADING_INDICATOR_ON_BLIP(npcBlip, true)
        HUD.SET_BLIP_SPRITE(npcBlip, 280)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(npc, pedCoords.x + pedForwardX * 1.4, pedCoords.y + pedForwardY * 1.4,
          pedCoords.z, true, false, false)
        ENTITY.SET_ENTITY_HEADING(npc, pedHeading - 180)
        WEAPON.GIVE_WEAPON_TO_PED(npc, 350597077, 9999, false, true)
        PED.SET_GROUP_FORMATION(myGroup, 2)
        PED.SET_GROUP_FORMATION_SPACING(myGroup, 1.0, 1.0, 1.0)
        PED.SET_PED_CONFIG_FLAG(npc, 179, true)
        PED.SET_PED_CONFIG_FLAG(npc, 294, true)
        PED.SET_PED_CONFIG_FLAG(npc, 398, true)
        PED.SET_PED_CONFIG_FLAG(npc, 401, true)
        PED.SET_PED_CONFIG_FLAG(npc, 443, true)
        PED.SET_PED_COMBAT_ABILITY(npc, 3)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 2, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 3, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 5, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 13, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 20, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 21, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 22, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 27, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 28, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 31, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 34, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 41, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 42, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 46, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 50, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 58, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 61, true)
        PED.SET_PED_COMBAT_ATTRIBUTES(npc, 71, true)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(npc, true)
        if npc_godMode then
          ENTITY.SET_ENTITY_INVINCIBLE(npc, true)
        end
        table.insert(spawned_npcs, npc)
      end)
    end
    ImGui.SameLine()
    if ImGui.Button(translateLabel("generic_delete") .. "##scenarios") then
      UI.widgetSound("Delete")
      script.run_in_fiber(function()
        for k, v in ipairs(spawned_npcs) do
          if ENTITY.DOES_ENTITY_EXIST(v) then
            PED.REMOVE_PED_FROM_GROUP(v)
            ENTITY.DELETE_ENTITY(v)
          end
          table.remove(spawned_npcs, k)
        end
      end)
    end
    ImGui.SameLine()
    if ImGui.Button(translateLabel("generic_play_btn") .. "##npc_scenarios") then
      if spawned_npcs[1] ~= nil then
        UI.widgetSound("Select")
        if is_playing_anim then
          cleanupNPC()
        end
        local data = filteredScenarios[scenario_index + 1]
        for _, v in ipairs(spawned_npcs) do
          local npcCoords = ENTITY.GET_ENTITY_COORDS(v, false)
          local npcHeading = ENTITY.GET_ENTITY_HEADING(v)
          local npcForwardX = ENTITY.GET_ENTITY_FORWARD_X(v)
          local npcForwardY = ENTITY.GET_ENTITY_FORWARD_Y(v)
          if data.name == "Cook On BBQ" then
            script.run_in_fiber(function()
              while not STREAMING.HAS_MODEL_LOADED(286252949) do
                STREAMING.REQUEST_MODEL(286252949)
                coroutine.yield()
              end
              bbq = OBJECT.CREATE_OBJECT(286252949, npcCoords.x + (npcForwardX), npcCoords.y + (npcForwardY), npcCoords
              .z, true, true, false)
              ENTITY.SET_ENTITY_HEADING(bbq, npcHeading)
              OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(bbq)
              TASK.CLEAR_PED_TASKS_IMMEDIATELY(v)
              TASK.TASK_START_SCENARIO_IN_PLACE(v, data.scenario, -1, true)
              is_playing_scenario = true
            end)
          else
            script.run_in_fiber(function()
              TASK.CLEAR_PED_TASKS_IMMEDIATELY(v)
              TASK.TASK_START_SCENARIO_IN_PLACE(v, data.scenario, -1, true)
              is_playing_scenario = true
              if ENTITY.DOES_ENTITY_EXIST(bbq) then
                ENTITY.DELETE_ENTITY(bbq)
              end
            end)
          end
        end
      else
        UI.widgetSound("Error")
      end
    end
    ImGui.SameLine()
    if ImGui.Button(translateLabel("generic_stop_btn") .. "##npc_scenarios") then
      if is_playing_scenario then
        UI.widgetSound("Cancel")
        script.run_in_fiber(function(script)
          Game.busySpinnerOn(translateLabel("scenarios_spinner"), 3)
          for _, v in ipairs(spawned_npcs) do
            TASK.CLEAR_PED_TASKS(v)
          end
          is_playing_scenario = false
          if ENTITY.DOES_ENTITY_EXIST(bbq) then
            ENTITY.DELETE_ENTITY(bbq)
          end
          script:sleep(1000)
          Game.busySpinnerOff()
        end)
      end
    end
    ImGui.EndTabItem()
  end
end)


--[[
    *weapon*
]]
weapon_tab = Samurais_scripts:add_tab(translateLabel("weaponTab"))
weapon_tab:add_imgui(function()
  HashGrabber, HgUsed = ImGui.Checkbox(translateLabel("hashgrabberCB"), HashGrabber, true)
  UI.helpMarker(false,
    translateLabel("hashgrabber_tt"))
  if HgUsed then
    UI.widgetSound("Nav2")
  end

  -- Triggerbot, TbUsed = ImGui.Checkbox(translateLabel("triggerbotCB"), Triggerbot, true)
  -- UI.helpMarker(false,
  --   translateLabel("triggerbot_tt"))
  -- if Triggerbot then
  --   ImGui.SameLine(); aimEnemy, aimEnemyUsed = ImGui.Checkbox(translateLabel("enemyonlyCB"), aimEnemy, true)
  --   if aimEnemyUsed then
  --     lua_cfg.save("aimEnemy", aimEnemy)
  --     UI.widgetSound("Nav2")
  --   end
  -- end
  -- if TbUsed then
  --   lua_cfg.save("Triggerbot", Triggerbot)
  --   UI.widgetSound("Nav2")
  -- end

  autoKill, autoKillUsed = ImGui.Checkbox(translateLabel("autokillCB"), autoKill, true)
  UI.helpMarker(false, translateLabel("autokill_tt"))
  if autoKillUsed then
    lua_cfg.save("autoKill", autoKill)
    UI.widgetSound("Nav2")
  end

  runaway, runawayUsed = ImGui.Checkbox(translateLabel("runawayCB"), runaway, true)
  UI.helpMarker(false, translateLabel("runaway_tt"))
  if runawayUsed then
    lua_cfg.save("runaway", runaway)
    UI.widgetSound("Nav2")
    if runaway then
      publicEnemy = false
    end
  end

  laserSight, laserSightUSed = ImGui.Checkbox(translateLabel("laserSightCB"), laserSight, true)
  UI.helpMarker(false, translateLabel("laserSight_tt"))
  if laserSightUSed then
    lua_cfg.save("laserSight", laserSight)
    UI.widgetSound("Nav2")
  end
  if laserSight then
    ImGui.Text(translateLabel("laserChoice_txt"))
    ImGui.SameLine(); laser_switch, lsrswUsed = ImGui.RadioButton("Red", laser_switch, 0)
    ImGui.SameLine(); laser_switch, lsrswUsed = ImGui.RadioButton("Green", laser_switch, 1)
    if lsrswUsed then
      UI.widgetSound("Nav")
      lua_cfg.save("laser_switch", laser_switch)
      lua_cfg.save("laser_choice", laser_choice)
    end
    if laser_switch == 0 then
      laser_choice = "proj_laser_enemy"
    else
      laser_choice = "proj_laser_player"
    end
  end
end)

sound_player = self_tab:add_tab(translateLabel "soundplayer")
function displayMaleSounds()
  filteredMaleSounds = {}
  for _, v in ipairs(male_sounds_T) do
    table.insert(filteredMaleSounds, v.name)
  end
  sound_index1, used = ImGui.Combo("##maleSounds", sound_index1, filteredMaleSounds, #male_sounds_T)
end

function displayFemaleSounds()
  filteredFemaleSounds = {}
  for _, v in ipairs(female_sounds_T) do
    table.insert(filteredFemaleSounds, v.name)
  end
  sound_index2, used = ImGui.Combo("##femaleSounds", sound_index2, filteredFemaleSounds, #female_sounds_T)
end

function displayRadioStations()
  filteredRadios = {}
  for _, v in ipairs(radio_stations) do
    table.insert(filteredRadios, v.name)
  end
  radio_index, used = ImGui.Combo("##radioStations", radio_index, filteredRadios, #radio_stations)
end

sound_player:add_imgui(function()
 ImGui.Spacing(); ImGui.SeparatorText("Human Sounds"); ImGui.Spacing()
  ImGui.Dummy(20, 1); ImGui.SameLine(); sound_switch, isChanged = ImGui.RadioButton(translateLabel("malesounds"), sound_switch, 0); ImGui.SameLine()
  if isChanged then
    UI.widgetSound("Nav")
  end
  ImGui.Dummy(20, 1); ImGui.SameLine(); sound_switch, isChanged = ImGui.RadioButton(translateLabel("femalesounds"), sound_switch, 1)
  if isChanged then
    UI.widgetSound("Nav")
  end
  ImGui.Spacing()
  if sound_switch == 0 then
    ImGui.PushItemWidth(280)
    displayMaleSounds()
    ImGui.PopItemWidth()
    selected_sound = male_sounds_T[sound_index1 + 1]
  else
    ImGui.PushItemWidth(280)
    displayFemaleSounds()
    ImGui.PopItemWidth()
    selected_sound = female_sounds_T[sound_index2 + 1]
  end
  ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
  if sound_btn_off then
    ImGui.BeginDisabled()
    ImGui.Button(" " .. loading_label .. " ", 60, 30)
    ImGui.EndDisabled()
  else
    if ImGui.Button(" " .. translateLabel("generic_play_btn") .. " ##sound") then
      script.run_in_fiber(function(playsnd)
        local myCoords = Game.getCoords(self.get_ped(), true)
        AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(selected_sound.soundName, selected_sound.soundRef, myCoords.x,
          myCoords.y, myCoords.z, "SPEECH_PARAMS_FORCE", 0)
        sound_btn_off = true
        start_loading_anim = true
        playsnd:sleep(5000)
        sound_btn_off = false
        start_loading_anim = false
      end)
    end
  end

  ImGui.Dummy(1, 10); ImGui.SeparatorText("Radio Stations")
  UI.toolTip(false, translateLabel("radioStations_tt"))
  ImGui.Spacing()
  ImGui.PushItemWidth(280)
  displayRadioStations()
  ImGui.PopItemWidth()
  selected_radio = radio_stations[radio_index + 1]
  if not radio_btn_off then
    ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
    if not is_playing_radio then
      if ImGui.Button(" " .. translateLabel("generic_play_btn") .. " ##radio") then
        script.run_in_fiber(function(rad)
          if not is_playing_anim then
            play_music("start", selected_radio.station)
            is_playing_radio   = true
            radio_btn_off      = true
            start_loading_anim = true
            rad:sleep(3000)
            radio_btn_off      = false
            start_loading_anim = false
          else
            gui.show_error("Samurais Scripts", "This option is disabled while playing animations to prevent bugs.")
          end
        end)
      end
    else
      if ImGui.Button(" " .. translateLabel("generic_stop_btn") .. " ##radio") then
        script.run_in_fiber(function(rad)
          play_music("stop")
          is_playing_radio   = false
          radio_btn_off      = true
          start_loading_anim = true
          rad:sleep(1500)
          radio_btn_off      = false
          start_loading_anim = false
        end)
      end
    end
  else
    ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
    ImGui.BeginDisabled()
    ImGui.Button(" " .. loading_label .. " ", 60, 30)
    ImGui.EndDisabled()
  end
end)


--[[
    *vehicle*
]]
vehicle_tab = Samurais_scripts:add_tab(translateLabel("vehicleTab"))

local popsnd, sndRef
local flame_size
local function filterVehNames()
  filteredNames = {}
  for _, veh in ipairs(gta_vehicles_T) do
    if VEHICLE.IS_THIS_MODEL_A_CAR(joaat(veh)) or VEHICLE.IS_THIS_MODEL_A_BIKE(joaat(veh)) or VEHICLE.IS_THIS_MODEL_A_QUADBIKE(joaat(veh)) then
      valid_veh = veh
      if string.find(string.lower(valid_veh), string.lower(search_term)) then
        table.insert(filteredNames, valid_veh)
      end
    end
  end
end

local function displayVehNames()
  filterVehNames()
  local vehNames = {}
  for _, veh in ipairs(filteredNames) do
    local vehName = vehicles.get_vehicle_display_name(joaat(veh))
    if string.find(string.lower(veh), "drift") then
      vehName = vehName .. "(Drift)"
    end
    table.insert(vehNames, vehName)
  end
  vehSound_index, used = ImGui.ListBox("##Vehicle Names", vehSound_index, vehNames, #filteredNames)
end

local function resetLastVehState()
  -- placeholder func
end

local function onVehEnter()
  lastVeh         = PLAYER.GET_PLAYERS_LAST_VEHICLE()
  current_vehicle = PED.GET_VEHICLE_PED_IS_USING(self.get_ped())
  lastVehPtr      = Game.getEntPtr(lastVeh)
  currentVehPtr   = Game.getEntPtr(current_vehicle)
  if current_vehicle ~= lastVeh then
    resetLastVehState()
  end
  return lastVeh, lastVehPtr, current_vehicle, currentVehPtr
end

function shoot_flares(sex)
  if Game.requestWeaponAsset(0x47757124) then
    for _, bone in pairs(plane_bones_T) do
      local bone_idx  = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(self.get_veh(), bone)
      local jet_fwd_X = ENTITY.GET_ENTITY_FORWARD_X(self.get_veh())
      local jet_fwd_Y = ENTITY.GET_ENTITY_FORWARD_Y(self.get_veh())
      if bone_idx ~= -1 then
        local bone_pos = ENTITY.GET_ENTITY_BONE_POSTION(self.get_veh(), bone_idx)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS((bone_pos.x + (jet_fwd_X * 1.3)), (bone_pos.y + jet_fwd_Y * 1.3) , bone_pos.z,
        (bone_pos.x - (jet_fwd_X * 1.3)), (bone_pos.y - jet_fwd_Y * 1.3), bone_pos.z - 0.06, 1, false, 0x47757124, self.get_ped(), true, false, 1.0)
        sex:sleep(250)
      end
    end
  end
end

vehicle_tab:add_imgui(function()
  if PED.IS_PED_IN_ANY_VEHICLE(self.get_ped(), true) then
    local manufacturer  = Game.Vehicle.manufacturer(self.get_veh())
    local vehicle_name  = Game.Vehicle.name(self.get_veh())
    local full_veh_name = manufacturer .. " " .. vehicle_name
    local vehicle_class = Game.Vehicle.class(self.get_veh())
    ImGui.Spacing()
    ImGui.SeparatorText("Drift Mode")
    if validModel then
      ImGui.Text(full_veh_name .. "   (" .. vehicle_class .. ")")
      driftMode, driftModeUsed = ImGui.Checkbox(translateLabel("driftModeCB"), driftMode, true)
      UI.helpMarker(false, translateLabel("driftMode_tt"))
      if driftModeUsed then
        UI.widgetSound("Nav2")
        lua_cfg.save("driftMode", driftMode)
        lua_cfg.save("DriftTires", false)
      end
      if driftMode then
        DriftTires = false
        ImGui.SameLine()
        ImGui.PushItemWidth(160)
        DriftIntensity, DriftIntensityUsed = ImGui.SliderInt("##Intensity", DriftIntensity, 0, 3)
        ImGui.PopItemWidth()
        UI.toolTip(false, translateLabel("driftSlider_tt"))
        if DriftIntensityUsed then
          UI.widgetSound("Nav")
          lua_cfg.save("DriftIntensity", DriftIntensity)
        end
      end

      DriftTires, DriftTiresUsed = ImGui.Checkbox(translateLabel("driftTiresCB"), DriftTires, true)
      UI.helpMarker(false, translateLabel("driftTires_tt"))
      if DriftTires then
        driftMode = false
      end
      if DriftTiresUsed then
        UI.widgetSound("Nav2")
        lua_cfg.save("DriftTires", DriftTires)
        lua_cfg.save("driftMode", false)
      end

      if driftMode or DriftTires then
        ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
        ImGui.PushItemWidth(160)
        DriftPowerIncrease, dpiUsed = ImGui.SliderInt("Torque", DriftPowerIncrease, 10, 100); ImGui.PopItemWidth()
        UI.toolTip(false, translateLabel("driftToruqe_tt"))
        if dpiUsed then
          UI.widgetSound("Nav2")
          lua_cfg.save("DriftPowerIncrease", DriftPowerIncrease)
        end

        DriftSmoke, dsmkUsed = ImGui.Checkbox("Drift Smoke", DriftSmoke, true)
        UI.toolTip(false, translateLabel("DriftSmoke_tt"))
        if dsmkUsed then
          UI.widgetSound("Nav2")
          lua_cfg.save("DriftSmoke", DriftSmoke)
        end

        ImGui.SameLine(); ImGui.Dummy(70, 1); ImGui.SameLine(); driftMinigame, drmgUsed = ImGui.Checkbox("Drift Minigame", driftMinigame, true)
        UI.toolTip(false, "[WIP] Accumulate points for drifting around without crashing. Your points are automatically transformed into cash once you stop drifting and don't crash for 3 seconds.\n\nNOTE: The cashout feature is for Signle Player only.")
        if drmgUsed then
          UI.widgetSound("Nav2")
          lua_cfg.save("driftMinigame", driftMinigame)
        end

        if DriftSmoke then
          ImGui.Spacing(); ImGui.Text(translateLabel("driftSmokeCol"))
          if not customSmokeCol then
            driftSmokeIndex, dsiUsed = ImGui.Combo("##tireSmoke", driftSmokeIndex, driftSmokeColors, #driftSmokeColors); ImGui.SameLine()
            if dsiUsed then
              selected_smoke_col = driftSmokeColors[driftSmokeIndex + 1]
              local r, g, b = UI.getColor(string.lower(selected_smoke_col))
              r, g, b = lua_Fn.round((r * 255), 2), lua_Fn.round((g * 255), 2), lua_Fn.round((b * 255), 2)
              driftSmoke_T.r, driftSmoke_T.g, driftSmoke_T.b = r, g, b
            end
          else
            local hex_len
            if smokeHex:find("^#") then
              hex_len = 8
            else
              hex_len = 7
            end
            smokeHex, smokeHexEntered = ImGui.InputTextWithHint("##customHex", "HEX", smokeHex, hex_len, ImGuiInputTextFlags.EnterReturnsTrue | ImGuiInputTextFlags.CharsNoBlank); ImGui.SameLine()
            if ImGui.IsItemActive() then
              is_typing = true
            else
              is_typing = false
            end
            UI.toolTip(false, translateLabel("hex_tt"))
            if smokeHexEntered then
              if smokeHex ~= nil then
                if not smokeHex:find("^#") then
                  smokeHex = "#" .. smokeHex
                end
                if smokeHex:len() > 1 then
                  if smokeHex:len() ~= 4 and smokeHex:len() ~= 7 then
                    UI.widgetSound("Error")
                    gui.show_warning("Samurais Scripts", "'" .. smokeHex .. "' is not a valid HEX color code. Please enter either a short or a long HEX string.")
                  else
                    UI.widgetSound("Select")
                    gui.show_success("Samurais Scripts", "Drift smoke color changed")
                  end
                else
                  UI.widgetSound("Error")
                  gui.show_warning("Samurais Scripts", "Please enter a valid HEX color code.")
                end
                driftSmoke_T.r, driftSmoke_T.g, driftSmoke_T.b = lua_Fn.hexToRGB(smokeHex)
              end
            end
          end
          customSmokeCol, cscUsed = ImGui.Checkbox(translateLabel("customLangTxt"), customSmokeCol, true)
          if cscUsed then
            UI.widgetSound("Nav2")
          end
        end
      end
    else
      UI.wrappedText(translateLabel("driftInvalidVehTxt"), 15)
    end

    ImGui.Spacing(); ImGui.Spacing(); ImGui.SeparatorText("Fun Features"); ImGui.Spacing();
    limitVehOptions, lvoUsed = ImGui.Checkbox(translateLabel("lvoCB"), limitVehOptions, true)
    UI.toolTip(false, translateLabel("lvo_tt"))
    if lvoUsed then
      UI.widgetSound("Nav2")
      lua_cfg.save("limitVehOptions", limitVehOptions)
    end

    ImGui.SameLine(); ImGui.Dummy(7, 1); ImGui.SameLine();
    missiledefense, mdefUsed = ImGui.Checkbox("Missile Defense", missiledefense, true)
    UI.toolTip(false, translateLabel("missile_def_tt"))
    if mdefUsed then
      UI.widgetSound("Radar")
      lua_cfg.save("missiledefense", missiledefense)
      if missiledefense then
        gui.show_success("Samurais Scripts", translateLabel("missile_def_on_notif"))
      end
    end
    if not missiledefense and mdefUsed then
      UI.widgetSound("Delete")
      gui.show_message("Samurais Scripts", translateLabel("missile_def_off_notif"))
    end

    launchCtrl, lctrlUsed = ImGui.Checkbox("Launch Control", launchCtrl, true)
    UI.toolTip(false, translateLabel("lct_tt"))
    if lctrlUsed then
      UI.widgetSound("Nav2")
      lua_cfg.save("launchCtrl", launchCtrl)
    end

    ImGui.SameLine(); ImGui.Dummy(31, 1); ImGui.SameLine(); speedBoost, spdbstUsed = ImGui.Checkbox("NOS", speedBoost,
      true)
    UI.toolTip(false, translateLabel("speedBoost_tt"))
    if spdbstUsed then
      UI.widgetSound("Nav2")
      lua_cfg.save("speedBoost", speedBoost)
    end
    if speedBoost then
      ImGui.SameLine(); nosvfx, nosvfxUsed = ImGui.Checkbox("VFX", nosvfx, true)
      UI.toolTip(false, translateLabel("vfx_tt"))
      if nosvfxUsed then
        UI.widgetSound("Nav2")
        lua_cfg.save("nosvfx", nosvfx)
      end
      ImGui.Dummy(192, 1); ImGui.SameLine()
      if ImGui.SmallButton("  NOS Power  ") then
        ImGui.OpenPopup("Nos Power")
      end
        ImGui.SetNextWindowPos(780, 400, ImGuiCond.Appearing)
        ImGui.SetNextWindowBgAlpha(0.9)
      if ImGui.BeginPopupModal("Nos Power", ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
        ImGui.Text("NOS Power")
        nosPower, nspwrUsed = ImGui.SliderInt("##nospower", nosPower, 10, 100, "%d", ImGuiSliderFlags.NoInput | ImGuiSliderFlags.AlwaysClamp | ImGuiSliderFlags.Logarithmic)
        if nspwrUsed then
          UI.widgetSound("Nav")
        end
        ImGui.Spacing(); if ImGui.Button(" Save ") then
          UI.widgetSound("Select2")
          lua_cfg.save("nosPower", nosPower)
          ImGui.CloseCurrentPopup()
        end
        ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine(); if ImGui.Button(" Cancel ") then
          UI.widgetSound("Cancel")
          ImGui.CloseCurrentPopup()
        end
        ImGui.End()
      end
    end

    loud_radio, loudRadioUsed = ImGui.Checkbox("Big Subwoofer", loud_radio, true)
    UI.toolTip(false, translateLabel("loudradio_tt"))
    if loudRadioUsed then
      UI.widgetSound("Nav2")
      lua_cfg.save("loud_radio", loud_radio)
    end
    if loud_radio then
      script.run_in_fiber(function()
        AUDIO.SET_VEHICLE_RADIO_LOUD(current_vehicle, true)
      end)
    else
      script.run_in_fiber(function()
        AUDIO.SET_VEHICLE_RADIO_LOUD(current_vehicle, false)
      end)
    end

    ImGui.SameLine(); ImGui.Dummy(32, 1); ImGui.SameLine(); nosPurge, nosPurgeUsed = ImGui.Checkbox("NOS Purge", nosPurge,
      true)
    UI.toolTip(false, translateLabel("purge_tt"))
    if nosPurgeUsed then
      UI.widgetSound("Nav2")
      lua_cfg.save("nosPurge", nosPurge)
    end

    popsNbangs, pnbUsed = ImGui.Checkbox("Pops & Bangs", popsNbangs, true)
    UI.toolTip(false, translateLabel("pnb_tt"))
    if pnbUsed then
      UI.widgetSound("Nav2")
      lua_cfg.save("popsNbangs", popsNbangs)
    end
    if popsNbangs then
      ImGui.SameLine(); ImGui.Dummy(37, 1); ImGui.SameLine(); louderPops, louderPopsUsed = ImGui.Checkbox("Louder Pops",
        louderPops, true)
      UI.toolTip(false, translateLabel("louderpnb_tt"))
      if louderPopsUsed then
        UI.widgetSound("Nav2")
        lua_cfg.save("louderPops", louderPops)
      end
    end

    hornLight, hornLightUsed = ImGui.Checkbox("High Beams on Horn", hornLight, true)
    UI.toolTip(false, translateLabel("highbeams_tt"))
    if hornLightUsed then
      UI.widgetSound("Nav2")
      lua_cfg.save("hornLight", hornLight)
    end

    ImGui.SameLine(); autobrklight, autobrkUsed = ImGui.Checkbox("Auto Brake Lights", autobrklight, true)
    UI.toolTip(false, translateLabel("brakeLight_tt"))
    if autobrkUsed then
      UI.widgetSound("Nav2")
      lua_cfg.save("autobrklight", autobrklight)
    end

    holdF, holdFused = ImGui.Checkbox("Keep Engine On", holdF, true)
    UI.toolTip(false, translateLabel("engineOn_tt"))
    if holdFused then
      UI.widgetSound("Nav2")
      lua_cfg.save("holdF", holdF)
    end

    ImGui.SameLine(); ImGui.Dummy(25, 1); ImGui.SameLine(); keepWheelsTurned, kwtrnd = ImGui.Checkbox("Keep Wheels Turned", keepWheelsTurned, true)
    UI.toolTip(false, translateLabel("wheelsturned_tt"))
    if kwtrnd then
      UI.widgetSound("Nav2")
      lua_cfg.save("keepWheelsTurned", keepWheelsTurned)
    end

    noJacking, noJackingUsed = ImGui.Checkbox(
      "Can't Touch This!", noJacking, true)
    UI.toolTip(false, translateLabel("canttouchthis_tt"))
    if noJackingUsed then
      UI.widgetSound("Nav2")
      lua_cfg.save("noJacking", noJacking)
    end

    ImGui.SameLine(); ImGui.Dummy(15, 1); ImGui.SameLine(); insta180, insta180Used = ImGui.Checkbox("Instant 180°", insta180, true)
    if insta180Used then
      UI.widgetSound("Nav2")
      lua_cfg.save("insta180", insta180)
    end
    UI.toolTip(false, translateLabel("insta180_tt"))

    if Game.isOnline() then
      flares_forall, flaresUsed = ImGui.Checkbox("Unlimited Flares", flares_forall, true)
      UI.toolTip(false, "Equip all planes with unlimited flares.\10\10 ¤ NOTE: There is a 3 second delay between each use of these flares.")
      if flaresUsed then
        UI.widgetSound("Nav2")
        lua_cfg.save("flares_forall", flares_forall)
      end
    else
      ImGui.BeginDisabled()
      flares_forall, flaresUsed = ImGui.Checkbox("Unlimited Flares", flares_forall, true)
      ImGui.EndDisabled()
      UI.toolTip(true, translateLabel("Unavailable in Single Player"), '#FF3333', 1)
    end

    ImGui.SameLine(); ImGui.Dummy(22, 1); ImGui.SameLine(); real_plane_speed, rpsUsed = ImGui.Checkbox("Higher Plane Speeds", real_plane_speed, true)
    UI.toolTip(false,
    "Increases the speed limit on planes.\10\10  ¤ Note 1: You must be flying at a reasonable altitude to gain speed, otherwise the game will force you to fly slowly if you're too low.\10\10  ¤ Note 2: Even with this option, we're still capping the speed at approximately 500km/h because anything over that will prevent textures from loading and eventually break your game, which is the reason why R* limited plane speeds in the first place.")
    if rpsUsed then
      UI.widgetSound("Nav2")
      lua_cfg.save("real_plane_speed", real_plane_speed)
    end

    rgbLights, rgbToggled = ImGui.Checkbox(translateLabel("rgbLights"), rgbLights, true)
    if rgbToggled then
      UI.widgetSound("Nav2")
      lua_cfg.save("rgbLights", rgbLights)
      if rgbLights then
        script.run_in_fiber(function(rgbhl)
          if not VEHICLE.IS_TOGGLE_MOD_ON(current_vehicle, 22) then
            has_xenon = false
          else
            has_xenon    = true
            defaultXenon = VEHICLE.GET_VEHICLE_XENON_LIGHT_COLOR_INDEX(current_vehicle)
          end
          rgbhl:sleep(200)
          start_rgb_loop = true
        end)
      else
        start_rgb_loop = false
      end
    end

    ImGui.SameLine(); ImGui.Dummy(62, 1); ImGui.SameLine(); flappyDoors, flappyDoorsUsed = ImGui.Checkbox("Flappy Doors",
      flappyDoors, true)
    if flappyDoorsUsed then
      UI.widgetSound("Nav2")
      lua_cfg.save("flappyDoors", flappyDoors)
    end

    if rgbLights then
      ImGui.PushItemWidth(120)
      lightSpeed, lightSpeedUsed = ImGui.SliderInt(translateLabel("rgbSlider"), lightSpeed, 1, 3)
      ImGui.PopItemWidth()
      if lightSpeedUsed then
        UI.widgetSound("Nav")
        lua_cfg.save("lightSpeed", lightSpeed)
      end
    end

    ImGui.Spacing();
    if ImGui.Button(translateLabel("engineSoundBtn")) then
      if is_car or is_bike or is_quad then
        open_sounds_window = true
      else
        open_sounds_window = false
        gui.show_error("Samurais Scripts", translateLabel("engineSoundErr"))
      end
    end
    if open_sounds_window then
      ImGui.SetNextWindowPos(740, 300, ImGuiCond.Appearing)
      ImGui.SetNextWindowSizeConstraints(100, 100, 600, 800)
      ImGui.Begin("Vehicle Sounds",
        ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoCollapse)
      if ImGui.Button(translateLabel("closeBtn")) then
        open_sounds_window = false
      end
      ImGui.Spacing(); ImGui.Spacing()
      ImGui.PushItemWidth(250)
      search_term, used = ImGui.InputTextWithHint("", translateLabel("searchVeh_hint"), search_term, 32)
      if ImGui.IsItemActive() then
        is_typing = true
      else
        is_typing = false
      end
      ImGui.PushItemWidth(270)
      displayVehNames()
      ImGui.PopItemWidth()
      local selected_name = filteredNames[vehSound_index + 1]
      ImGui.Spacing()
      if ImGui.Button(translateLabel("Use This Sound")) then
        script.run_in_fiber(function()
          AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(current_vehicle, selected_name)
        end)
      end
      ImGui.SameLine()
      if ImGui.Button(translateLabel("Restore Default")) then
        script.run_in_fiber(function()
          AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(current_vehicle,
            vehicles.get_vehicle_display_name(ENTITY.GET_ENTITY_MODEL(current_vehicle)))
        end)
      end
      ImGui.End()
    end

    ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
    local engineHealth = VEHICLE.GET_VEHICLE_ENGINE_HEALTH(current_vehicle)
    if engineHealth <= 300 then
      engineDestroyed = true
    else
      engineDestroyed = false
    end
    if engineDestroyed then
      engineButton_label = translateLabel("Fix Engine")
      engine_hp          = 1000
    else
      engineButton_label = translateLabel("Destroy Engine")
      engine_hp          = -4000
    end
    if ImGui.Button(engineButton_label) then
      script.run_in_fiber(function()
        VEHICLE.SET_VEHICLE_ENGINE_HEALTH(current_vehicle, engine_hp)
      end)
    end

    if dummyCopCar == 0 then
      if VEHICLE.GET_VEHICLE_CLASS(current_vehicle) ~= 18 then
        if ImGui.Button("Equip Fake Siren") then
          if is_car or is_bike and not PED.IS_PED_IN_FLYING_VEHICLE(self.get_ped()) then
            UI.widgetSound("Select")
            dummyCop()
          else
            UI.widgetSound("Error")
            gui.show_error("Samurais Scripts", "This feature is only available for cars and bikes.")
          end
        end
        if not Game.isOnline() then
          UI.toolTip(false, "The siren audio only works Online.")
        end
      else
        ImGui.BeginDisabled()
        ImGui.Button("Equip Fake Siren")
        ImGui.EndDisabled()
        UI.toolTip(false, "Your vehicle has a real siren. You don't need a fake one.")
      end
    else
      if ImGui.Button("Remove Fake Siren") then
        UI.widgetSound("Cancel")
        script.run_in_fiber(function(deletecop)
          VEHICLE.SET_VEHICLE_ACT_AS_IF_HAS_SIREN_ON(self.get_veh(), false)
          VEHICLE.SET_VEHICLE_CAUSES_SWERVING(self.get_veh(), false)
          VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(self.get_veh(), 0, false)
          VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(self.get_veh(), 1, false)
          if ENTITY.DOES_ENTITY_EXIST(dummyCopCar) then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(dummyCopCar)
            deletecop:sleep(200)
            ENTITY.DELETE_ENTITY(dummyCopCar)
          end
          dummyCopCar = 0
        end)
      end
    end
  else
    ImGui.Text(translateLabel("getinveh"))
  end
end)

flatbed = vehicle_tab:add_tab("Flatbed")
attached_vehicle = 0
tow_xAxis        = 0.0
tow_yAxis        = 0.0
tow_zAxis        = 0.0
modelOverride    = false
flatbed:add_imgui(function()
  local vehicleHandles = entities.get_all_vehicles_as_handles()
  local flatbedModel   = 1353720154
  local vehicle_model  = Game.getEntityModel(current_vehicle)
  local playerPosition = self.get_pos()
  local playerForwardX = Game.getForwardX(self.get_ped())
  local playerForwardY = Game.getForwardY(self.get_ped())
  for _, veh in ipairs(vehicleHandles) do
    script.run_in_fiber(function(detector)
      local detectPos = vec3:new(playerPosition.x - (playerForwardX * 10), playerPosition.y - (playerForwardY * 10),
        playerPosition.z)
      local vehPos    = ENTITY.GET_ENTITY_COORDS(veh, false)
      local vDist     = SYSTEM.VDIST(detectPos.x, detectPos.y, detectPos.z, vehPos.x, vehPos.y, vehPos.z)
      if vDist <= 5 then
        closestVehicle = veh
      else
        detector:sleep(50)
        closestVehicle = nil
        return
      end
    end)
  end
  local closestVehicleModel = Game.getEntityModel(closestVehicle)
  local iscar               = VEHICLE.IS_THIS_MODEL_A_CAR(closestVehicleModel)
  local isbike              = VEHICLE.IS_THIS_MODEL_A_BIKE(closestVehicleModel)
  local closestVehicleName  = vehicles.get_vehicle_display_name(closestVehicleModel)
  if vehicle_model == flatbedModel then
    is_in_flatbed = true
  else
    is_in_flatbed = false
  end
  if closestVehicleName == "" then
    displayText = translateLabel("fltbd_nonearbyvehTxt")
  elseif tostring(closestVehicleName) == "Flatbed" then
    displayText = translateLabel("fltbd_nootherfltbdTxt")
  else
    displayText = (translateLabel("fltbd_closest_veh") .. tostring(closestVehicleName))
  end
  if attached_vehicle ~= 0 then
    displayText = translateLabel("fltbd_towingTxt") ..
        vehicles.get_vehicle_display_name(ENTITY.GET_ENTITY_MODEL(attached_vehicle)) .. "."
  end
  if modelOverride then
    towable = true
  else
    towable = false
  end
  if iscar then
    towable = true
  end
  if isbike then
    towable = true
  end
  if closestVehicleModel == 745926877 then --Buzzard
    towable = true
  end
  if is_in_flatbed then
    ImGui.Text(displayText)
    towPos, towPosUsed = ImGui.Checkbox(translateLabel("Show Towing Position"), towPos, true)
    UI.helpMarker(false, translateLabel("towpos_tt"))
    if towPosUsed then
      UI.widgetSound("Nav2")
    end

    towEverything, towEverythingUsed = ImGui.Checkbox(translateLabel("Tow Everything"), towEverything, true)
    UI.helpMarker(false, translateLabel("TowEverything_tt"))
    if towEverythingUsed then
      UI.widgetSound("Nav2")
    end
    if towEverything then
      modelOverride = true
    else
      modelOverride = false
    end

    if attached_vehicle == 0 then
      if ImGui.Button(translateLabel("towBtn")) then
        UI.widgetSound("Select")
        if towable and closestVehicle ~= nil and closestVehicleModel ~= flatbedModel then
          script.run_in_fiber(function()
            controlled = entities.take_control_of(closestVehicle, 300)
            if controlled then
              flatbedHeading = ENTITY.GET_ENTITY_HEADING(current_vehicle)
              flatbedBone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, "chassis_dummy")
              vehBone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(closestVehicle, "chassis_dummy")
              local vehicleClass = VEHICLE.GET_VEHICLE_CLASS(closestVehicle)
              if vehicleClass == 1 then
                tow_zAxis = 0.9
                tow_yAxis = -2.3
              elseif vehicleClass == 2 then
                tow_zAxis = 0.993
                tow_yAxis = -2.17046
              elseif vehicleClass == 6 then
                tow_zAxis = 1.00069420
                tow_yAxis = -2.17046
              elseif vehicleClass == 7 then
                tow_zAxis = 1.009
                tow_yAxis = -2.17036
              elseif vehicleClass == 15 then
                tow_zAxis = 1.3
                tow_yAxis = -2.21069
              elseif vehicleClass == 16 then
                tow_zAxis = 1.5
                tow_yAxis = -2.21069
              else
                tow_zAxis = 1.1
                tow_yAxis = -2.0
              end
              ENTITY.SET_ENTITY_HEADING(closestVehicleModel, flatbedHeading)
              ENTITY.ATTACH_ENTITY_TO_ENTITY(closestVehicle, current_vehicle, flatbedBone, tow_xAxis, tow_yAxis, tow_zAxis, 0.0, 0.0,
                0.0, true, true, false, false, 1, true, 1)
              attached_vehicle = closestVehicle
              ENTITY.SET_ENTITY_CANT_CAUSE_COLLISION_DAMAGED_ENTITY(attached_vehicle, current_vehicle)
            else
              gui.show_error("Samurais Scripts", translateLabel("failed_veh_ctrl"))
            end
          end)
        end
        if closestVehicle ~= nil and closestVehicleModel ~= flatbedModel and not towable then
          gui.show_message("Samurais Scripts", translateLabel("fltbd_carsOnlyTxt"))
        end
        if closestVehicle ~= nil and closestVehicleModel == flatbedModel then
          gui.show_message("Samurais Scripts", translateLabel("fltbd_nootherfltbdTxt"))
        end
      end
    else
      if ImGui.Button(translateLabel("detachBtn")) then
        UI.widgetSound("Select2")
        script.run_in_fiber(function()
          local modelHash = ENTITY.GET_ENTITY_MODEL(attached_vehicle)
          local attachedVehicle = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(
            PED.GET_VEHICLE_PED_IS_USING(self.get_ped()), modelHash)
          local attachedVehcoords = ENTITY.GET_ENTITY_COORDS(attached_vehicle, false)
          controlled = entities.take_control_of(attachedVehicle, 300)
          if ENTITY.DOES_ENTITY_EXIST(attachedVehicle) then
            if controlled then
              ENTITY.DETACH_ENTITY(attachedVehicle)
              ENTITY.SET_ENTITY_COORDS(attachedVehicle, attachedVehcoords.x - (playerForwardX * 10),
                attachedVehcoords.y - (playerForwardY * 10), playerPosition.z, false, false, false, false)
              VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(attached_vehicle, 5.0)
              attached_vehicle = 0
            end
          end
        end)
      end
      ImGui.Spacing(); ImGui.Text(translateLabel("Adjust Vehicle Position"))
      if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 20)
        ImGui.TextWrapped(translateLabel("AdjustPosition_tt"))
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
      end
      ImGui.Separator(); ImGui.Spacing()
      ImGui.Dummy(100, 1); ImGui.SameLine()
      ImGui.ArrowButton("##Up", 2)
      if ImGui.IsItemActive() then
        tow_zAxis = tow_zAxis + 0.01
        ENTITY.ATTACH_ENTITY_TO_ENTITY(attached_vehicle, current_vehicle, flatbedBone, tow_xAxis, tow_yAxis, tow_zAxis, 0.0, 0.0, 0.0,
          true, true, false, false, 1, true, 1)
      end
      ImGui.Dummy(60, 1); ImGui.SameLine()
      ImGui.ArrowButton("##Left", 0)
      if ImGui.IsItemActive() then
        tow_yAxis = tow_yAxis + 0.01
        ENTITY.ATTACH_ENTITY_TO_ENTITY(attached_vehicle, current_vehicle, flatbedBone, tow_xAxis, tow_yAxis, tow_zAxis, 0.0, 0.0, 0.0,
          true, true, false, false, 1, true, 1)
      end
      ImGui.SameLine(); ImGui.Dummy(23, 1); ImGui.SameLine()
      ImGui.ArrowButton("##Right", 1)
      if ImGui.IsItemActive() then
        tow_yAxis = tow_yAxis - 0.01
        ENTITY.ATTACH_ENTITY_TO_ENTITY(attached_vehicle, current_vehicle, flatbedBone, tow_xAxis, tow_yAxis, tow_zAxis, 0.0, 0.0, 0.0,
          true, true, false, false, 1, true, 1)
      end
      ImGui.Dummy(100, 1); ImGui.SameLine()
      ImGui.ArrowButton("##Down", 3)
      if ImGui.IsItemActive() then
        tow_zAxis = tow_zAxis - 0.01
        ENTITY.ATTACH_ENTITY_TO_ENTITY(attached_vehicle, current_vehicle, flatbedBone, tow_xAxis, tow_yAxis, tow_zAxis, 0.0, 0.0, 0.0,
          true, true, false, false, 1, true, 1)
      end
    end
  else
    UI.wrappedText(translateLabel("getinsidefltbd"), 20)
    if ImGui.Button(translateLabel("spawnfltbd")) then
      script.run_in_fiber(function(script)
        if not PED.IS_PED_SITTING_IN_ANY_VEHICLE(self.get_ped()) then
          if Game.Self.isOutside() then
            local try = 0
            while not STREAMING.HAS_MODEL_LOADED(flatbedModel) do
              STREAMING.REQUEST_MODEL(flatbedModel)
              script:yield()
              if try > 100 then
                return
              else
                try = try + 1
              end
            end
            fltbd = VEHICLE.CREATE_VEHICLE(flatbedModel, playerPosition.x, playerPosition.y, playerPosition.z,
              ENTITY.GET_ENTITY_HEADING(self.get_ped()), true, false, false)
            PED.SET_PED_INTO_VEHICLE(self.get_ped(), fltbd, -1)
            ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(fltbd)
          else
            gui.show_error("Samurais Scripts", translateLabel("noSpawnInside"))
          end
        else
          gui.show_error("Samurais Scripts", translateLabel("Exit your current vehicle first."))
        end
      end)
    end
  end
end)

vehicle_creator   = vehicle_tab:add_tab("Vehicle Creator")
is_typing         = false
vCreator_searchQ  = ""
vehicleName       = ""
creation_name     = ""
main_vehicle_name = ""
veh_axisMult      = 1
vehicle_index     = 0
persist_index     = 0
spawned_veh_index = 0
vehicleHash       = 0
spawned_vehicle   = 0
main_vehicle      = 0
persist_switch    = 0
attachment_index  = 0
selected_attchmnt = 0
spawned_persist   = 0
veh_attach_X      = 0.0
veh_attach_Y      = 0.0
veh_attach_Z      = 0.0
veh_attach_RX     = 0.0
veh_attach_RY     = 0.0
veh_attach_RZ     = 0.0
spawned_vehicles  = {}
spawned_vehNames  = {}
filteredVehNames  = {}
persist_names     = {}
veh_attachments   = {}
attached_vehicles = {entity = 0, hash = 0, mods = {}, color_1 = {r = 0, g = 0, b = 0}, color_2 = {r = 0, g = 0, b = 0}, tint = 0, posx = 0.0, posy = 0.0, posz = 0.0, rotx = 0.0, roty = 0.0, rotz = 0.0}
vehicle_creation  = {name = "", main_veh = 0, mods = {}, color_1 = {r = 0, g = 0, b = 0}, color_2 = {r = 0, g = 0, b = 0}, tint = 0, attachments = {}}
saved_vehicles    = lua_cfg.read("saved_vehicles")

script.register_looped("disableInput", function()
  if is_typing then
    PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
  end
end)

local function updateFilteredVehicles()
  filtered_vehicles = {}
  for _, veh in ipairs(gta_vehicles_T) do
    if string.find(string.lower(veh), string.lower(vCreator_searchQ)) then
      table.insert(filtered_vehicles, veh)
    end
  end
end

local function displayFilteredList()
  updateFilteredVehicles()
  local vehicle_names = {}
  if filtered_vehicles[1] ~= nil then
    for _, veh in ipairs(filtered_vehicles) do
      local displayName = vehicles.get_vehicle_display_name(joaat(veh))
      if string.find(string.lower(veh), "drift") then
        displayName = displayName .. "  (Drift)"
      end
      table.insert(vehicle_names, displayName)
    end
  end
  vehicle_index, _ = ImGui.ListBox("##vehList", vehicle_index, vehicle_names, #filtered_vehicles)
end

local function showAttachedVehicles()
  attachment_names = {}
  for _, veh in pairs(veh_attachments) do
    table.insert(attachment_names, veh.name)
  end
  attachment_index, _ = ImGui.Combo("##attached_vehs", attachment_index, attachment_names, #veh_attachments)
end

local function filterSavedVehicles()
  filteredCreations = {}
  if saved_vehicles[1] ~= nil then
    for _, t in pairs(saved_vehicles) do
      table.insert(filteredCreations, t)
    end
  end
end

local function showSavedVehicles()
  filterSavedVehicles()
  for _, veh in pairs(filteredCreations) do
    table.insert(persist_names, veh.name)
  end
  persist_index, _ = ImGui.ListBox("##persist_vehs", persist_index, persist_names, #filteredCreations)
end

local function appendVehicleMods(v, t)
  script.run_in_fiber(function()
    for i = 0, 49 do
      table.insert(t, VEHICLE.GET_VEHICLE_MOD(v, i))
    end
  end)
end

local function setVehicleMods(v, t)
  script.run_in_fiber(function()
    VEHICLE.SET_VEHICLE_MOD_KIT(v, 0)
    for slot, mod in pairs(t) do
      VEHICLE.SET_VEHICLE_MOD(v, (slot - 1), mod, true)
    end
  end)
end

---@param main integer
---@param mods table
---@param col_1 table
---@param col_2 table
---@param attachments table
local function spawnPersistVeh(main, mods, col_1, col_2, tint, attachments)
  script.run_in_fiber(function()
    local Pos      = self.get_pos()
    local forwardX = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
    local forwardY = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
    local heading  = ENTITY.GET_ENTITY_HEADING(self.get_ped())
    Pos.x = Pos.x + (forwardX * 7)
    Pos.y = Pos.y + (forwardY * 7)
    if Game.requestModel(main) then
      spawned_persist = VEHICLE.CREATE_VEHICLE(main, Pos.x, Pos.y, Pos.z, heading, true, false, false)
      VEHICLE.SET_VEHICLE_IS_STOLEN(spawned_persist, false)
      DECORATOR.DECOR_SET_INT(spawned_persist, "MPBitset", 0)
      VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(spawned_persist, col_1.r, col_1.g, col_1.b)
      VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(spawned_persist, col_2.r, col_2.g, col_2.b)
      setVehicleMods(spawned_persist, mods)
      VEHICLE.SET_VEHICLE_WINDOW_TINT(spawned_persist, tint)
    end
    for _, att in ipairs(attachments) do
      if Game.requestModel(att.hash) then
        local attach = VEHICLE.CREATE_VEHICLE(att.hash, Pos.x, Pos.y, Pos.z, heading, true, false, false)
        VEHICLE.SET_VEHICLE_IS_STOLEN(attach, false)
        DECORATOR.DECOR_SET_INT(attach, "MPBitset", 0)
        VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(attach, att.color_1.r, att.color_1.g, att.color_1.b)
        VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(attach, att.color_2.r, att.color_2.g, att.color_2.b)
        setVehicleMods(attach, att.mods)
        VEHICLE.SET_VEHICLE_WINDOW_TINT(attach, att.tint)
        if ENTITY.DOES_ENTITY_EXIST(spawned_persist) and ENTITY.DOES_ENTITY_EXIST(attach) then
          local Bone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(spawned_persist, "chassis_dummy")
          ENTITY.ATTACH_ENTITY_TO_ENTITY(attach, spawned_persist, Bone, att.posx, att.posy, att.posz, att.rotx, att.roty, att.rotz, false, false, false, false, 2, true, 1)
        end
      end
    end
  end)
end

local function createWideBodyCivic()
  vehicle_creation = {
    name = "Widebody Civic", main_veh = 1074745671, mods = {}, color_1 = {r = 0, g = 0, b = 0}, color_2 = {r = 0, g = 0, b = 0}, tint = 1,
    attachments = {
      {entity = 0, hash = 987469656, posx = 0.0, posy = -0.075, posz = 0.076, rotx = 0.0, roty = 0.0, rotz = 0.0,
        mods = {5,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,3,2,2,-1,4,4,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
        color_1 = {r = 0, g = 0, b = 0}, color_2 = {r = 0, g = 0, b = 0}, tint = 1,
      }
    }
  }
  table.insert(saved_vehicles, vehicle_creation)
  lua_cfg.save("saved_vehicles", saved_vehicles)
  vehicle_creation = {}
end

local function resetOnSave()
  vehicleName       = ""
  creation_name     = ""
  main_vehicle_name = ""
  veh_axisMult      = 1
  vehicle_index     = 0
  persist_index     = 0
  spawned_veh_index = 0
  vehicleHash       = 0
  spawned_vehicle   = 0
  main_vehicle      = 0
  attachment_index  = 0
  selected_attchmnt = 0
  veh_attach_X      = 0.0
  veh_attach_Y      = 0.0
  veh_attach_Z      = 0.0
  veh_attach_RX     = 0.0
  veh_attach_RY     = 0.0
  veh_attach_RZ     = 0.0
  spawned_vehicles  = {}
  spawned_vehNames  = {}
  filteredVehNames  = {}
  persist_names     = {}
  veh_attachments   = {}
  attachment_names  = {}
  attached_vehicles = {}
  vehicle_creation  = {name = "", main_veh = 0, mods = {}, color_1 = {r = 0, g = 0, b = 0}, color_2 = {r = 0, g = 0, b = 0}, tint = 0, attachments = {}}
end

vehicle_creator:add_imgui(function()
  ImGui.Dummy(1, 10)
  persist_switch, pswChanged = ImGui.RadioButton(translateLabel("Create"), persist_switch, 0)
  UI.helpMarker(false, translateLabel("vcreator_tt"))
  if pswChanged then
    UI.widgetSound("Nav")
  end
  if saved_vehicles[1] ~= nil then
    ImGui.SameLine(); ImGui.Dummy(40, 1); ImGui.SameLine(); persist_switch, pswChanged = ImGui.RadioButton(translateLabel("vc_saved_vehs"), persist_switch, 1)
    if pswChanged then
      UI.widgetSound("Nav")
    end
  else
    ImGui.BeginDisabled()
    ImGui.SameLine(); ImGui.Dummy(40, 1); ImGui.SameLine(); persist_switch, pswChanged = ImGui.RadioButton(translateLabel("vc_saved_vehs"), persist_switch, 1)
    ImGui.EndDisabled()
    UI.toolTip(false, translateLabel("vc_saved_vehs_tt"))
  end
  if persist_switch == 0 then
    ImGui.Spacing()
    ImGui.PushItemWidth(350)
    vCreator_searchQ, used = ImGui.InputTextWithHint("##searchVehicles", translateLabel("search_hint"), vCreator_searchQ, 32)
    ImGui.PopItemWidth()
    if ImGui.IsItemActive() then
      is_typing = true
    else
      is_typing = false
    end
    ImGui.PushItemWidth(350)
    displayFilteredList()
    ImGui.PopItemWidth()
    ImGui.Separator()
    if filtered_vehicles[1] ~= nil then
      vehicleHash = joaat(filtered_vehicles[vehicle_index + 1])
      vehicleName = vehicles.get_vehicle_display_name(joaat(filtered_vehicles[vehicle_index + 1]))
    end
    if ImGui.Button("   " .. translateLabel("Spawn") .. "   ##vehcreator") then
      UI.widgetSound("Select")
      script.run_in_fiber(function()
        local plyrCoords   = self.get_pos()
        local plyrForwardX = Game.getForwardX(self.get_ped())
        local plyrForwardY = Game.getForwardY(self.get_ped())
        if Game.requestModel(vehicleHash) then
          spawned_vehicle = VEHICLE.CREATE_VEHICLE(vehicleHash, plyrCoords.x + (plyrForwardX * 5),
            plyrCoords.y + (plyrForwardY * 5), plyrCoords.z, (ENTITY.GET_ENTITY_HEADING(self.get_ped()) + 90), true, false, false)
          VEHICLE.SET_VEHICLE_IS_STOLEN(spawned_vehicle, false)
          DECORATOR.DECOR_SET_INT(spawned_vehicle, "MPBitset", 0)
          if main_vehicle == 0 then
            main_vehicle      = spawned_vehicle
            main_vehicle_name = vehicles.get_vehicle_display_name(ENTITY.GET_ENTITY_MODEL(main_vehicle))
          else
            table.insert(spawned_vehicles, spawned_vehicle)
            table.insert(spawned_vehNames, vehicleName)
            local dupes = lua_Fn.getTableDupes(spawned_vehNames, vehicleName)
            if dupes > 1 then
              newVehName = vehicleName .. " #" .. tostring(dupes)
              table.insert(filteredVehNames, newVehName)
            else
              table.insert(filteredVehNames, vehicleName)
            end
          end
        end
      end)
    end
    if saved_vehicles[1] == nil then
      ImGui.SameLine(); ImGui.Dummy(20, 1); ImGui.SameLine()
      if ImGui.Button(translateLabel("widebodycivic_Btn")) then
        UI.widgetSound("Select")
        createWideBodyCivic()
        spawnPersistVeh(saved_vehicles[1].main_veh, saved_vehicles[1].mods, saved_vehicles[1].color_1, saved_vehicles[1].color_2, saved_vehicles[1].tint, saved_vehicles[1].attachments)
      end
      UI.toolTip(false, translateLabel("widebodycivic_tt"))
    end
    if main_vehicle ~= 0 then
      ImGui.Separator()
      UI.coloredText(translateLabel("vc_main_veh"), 'green', 0.9, 20); ImGui.SameLine(); ImGui.Text(main_vehicle_name); ImGui.SameLine()
      if ImGui.Button(" " .. translateLabel("generic_delete") .. " ##mainVeh") then
        UI.widgetSound("Delete")
        script.run_in_fiber(function(delmv)
          if entities.take_control_of(main_vehicle, 300) then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(main_vehicle, true, true)
            delmv:sleep(100)
            ENTITY.DELETE_ENTITY(main_vehicle)
          end
          if attached_vehicles[1] ~= nil then
            table.remove(attached_vehicles, 1)
          end
          if spawned_vehicles[1] ~= nil then
            for k, veh in ipairs(spawned_vehicles) do
              if ENTITY.DOES_ENTITY_EXIST(veh) then
                main_vehicle = veh
                main_vehicle_name = vehicles.get_vehicle_display_name(ENTITY.GET_ENTITY_MODEL(main_vehicle))
                table.remove(spawned_vehicles, k)
                table.remove(spawned_vehNames, k)
                table.remove(filteredVehNames, k)
              end
            end
          end
        end)
      end
    end
    if spawned_vehicles[1] ~= nil then
      ImGui.SeparatorText(translateLabel("vc_spawned_vehs"))
      ImGui.PushItemWidth(230)
      spawned_veh_index, _ = ImGui.Combo("##Spawned Vehicles", spawned_veh_index, filteredVehNames, #spawned_vehicles)
      ImGui.PopItemWidth()
      selectedVeh = spawned_vehicles[spawned_veh_index + 1]
      ImGui.SameLine()
      if ImGui.Button("   " .. translateLabel("generic_delete") .. "   ##spawnedVeh") then
        UI.widgetSound("Delete")
        script.run_in_fiber(function(del)
          if entities.take_control_of(selectedVeh, 300) then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(selectedVeh, true, true)
            del:sleep(200)
            VEHICLE.DELETE_VEHICLE(selectedVeh)
            -- vehicle_creation = {}
            creation_name = ""
            attached_vehicle = 0
            if spawned_veh_index ~= 0 then
              spawned_veh_index = 0
            end
            if attachment_index ~= 0 then
              attachment_index = 0
            end
          else
            gui.show_error("Samurais Scripts", translateLabel("generic_veh_delete_fail"))
          end
        end)
      end
      if ImGui.Button(translateLabel("vc_attach_btn") .. main_vehicle_name) then
        if selectedVeh ~= main_vehicle then
          script.run_in_fiber(function()
            if not ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(selectedVeh, main_vehicle) then
              UI.widgetSound("Select")
              ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedVeh, main_vehicle,
                ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), veh_attach_X, veh_attach_Y,
                veh_attach_Z, veh_attach_RX, veh_attach_RY, veh_attach_RZ, false, false, false,
                false,
                2, true, 1)
              attached_vehicles.entity = selectedVeh
              attached_vehicles.hash   = ENTITY.GET_ENTITY_MODEL(selectedVeh)
              attached_vehicles.name   = vehicles.get_vehicle_display_name(ENTITY.GET_ENTITY_MODEL(selectedVeh))
              attached_vehicles.posx   = veh_attach_X
              attached_vehicles.posy   = veh_attach_Y
              attached_vehicles.posz   = veh_attach_Z
              attached_vehicles.rotx   = veh_attach_RX
              attached_vehicles.roty   = veh_attach_RY
              attached_vehicles.rotz   = veh_attach_RZ
              attached_vehicles.tint   = VEHICLE.GET_VEHICLE_WINDOW_TINT(selectedVeh)
              attached_vehicles.color_1.r, attached_vehicles.color_1.g, attached_vehicles.color_1.b = VEHICLE.GET_VEHICLE_CUSTOM_PRIMARY_COLOUR(selectedVeh, attached_vehicles.color_1.r, attached_vehicles.color_1.g, attached_vehicles.color_1.b)
              attached_vehicles.color_2.r, attached_vehicles.color_2.g, attached_vehicles.color_2.b = VEHICLE.GET_VEHICLE_CUSTOM_SECONDARY_COLOUR(selectedVeh, attached_vehicles.color_2.r, attached_vehicles.color_2.g, attached_vehicles.color_2.b)
              appendVehicleMods(selectedVeh, attached_vehicles.mods)
              table.insert(veh_attachments, attached_vehicles)
              attached_vehicles = {entity = 0, hash = 0, mods = {}, color_1 = {r = 0, g = 0, b = 0}, color_2 = {r = 0, g = 0, b = 0}, tint = 0, posx = 0.0, posy = 0.0, posz = 0.0, rotx = 0.0, roty = 0.0, rotz = 0.0}
            else
              UI.widgetSound("Error")
              gui.show_error("Samurais Scripts", translateLabel("vc_alrattached_err"))
            end
          end)
        else
          UI.widgetSound("Error")
          gui.show_error("Samurais Scripts", translateLabel("vc_selfattach_err"))
        end
      end
    end
    if veh_attachments[1] ~= nil then
      ImGui.Spacing(); ImGui.SeparatorText("Attached Vehicles")
      ImGui.PushItemWidth(230)
      showAttachedVehicles()
      ImGui.PopItemWidth()
      selected_attchmnt = veh_attachments[attachment_index + 1]
      ImGui.Text(translateLabel("generic_multiplier_label"))
      ImGui.PushItemWidth(271)
      veh_axisMult, _ = ImGui.InputInt("##AttachMultiplier", veh_axisMult, 1, 2, 0)
      ImGui.PopItemWidth()
      ImGui.Spacing()
      ImGui.Text("X Axis :"); ImGui.SameLine(); ImGui.Dummy(25, 1); ImGui.SameLine(); ImGui.Text("Y Axis :"); ImGui.SameLine()
      ImGui.Dummy(25, 1); ImGui.SameLine(); ImGui.Text("Z Axis :")
      ImGui.ArrowButton("##Xleft", 0)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.posx = selected_attchmnt.posx + 0.001 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx, selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false, false,
          false,
          2, true, 1)
      end
      ImGui.SameLine()
      ImGui.ArrowButton("##XRight", 1)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.posx = selected_attchmnt.posx - 0.001 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx, selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false, false,
          false,
          2, true, 1)
      end
      ImGui.SameLine()
      ImGui.Dummy(5, 1); ImGui.SameLine()
      ImGui.ArrowButton("##Yleft", 0)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.posy = selected_attchmnt.posy + 0.001 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx, selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false, false,
          false,
          2, true, 1)
      end
      ImGui.SameLine()
      ImGui.ArrowButton("##YRight", 1)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.posy = selected_attchmnt.posy - 0.001 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx, selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false, false,
          false,
          2, true, 1)
      end
      ImGui.SameLine()
      ImGui.Dummy(5, 1); ImGui.SameLine()
      ImGui.ArrowButton("##zUp", 2)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.posz = selected_attchmnt.posz + 0.001 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx, selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false, false,
          false,
          2, true, 1)
      end
      ImGui.SameLine()
      ImGui.ArrowButton("##zDown", 3)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.posz = selected_attchmnt.posz - 0.001 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx, selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false, false,
          false,
          2, true, 1)
      end
      ImGui.Text("X Rotation :"); ImGui.SameLine(); ImGui.Text("Y Rotation :"); ImGui.SameLine(); ImGui.Text(
        "Z Rotation :")
      ImGui.ArrowButton("##rotXleft", 0)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.rotx = selected_attchmnt.rotx + 0.01 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx, selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false, false,
          false,
          2, true, 1)
      end
      ImGui.SameLine()
      ImGui.ArrowButton("##rotXright", 1)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.rotx = selected_attchmnt.rotx - 0.01 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx, selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false, false,
          false,
          2, true, 1)
      end
      ImGui.SameLine()
      ImGui.Dummy(5, 1); ImGui.SameLine()
      ImGui.ArrowButton("##rotYleft", 0)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.roty = selected_attchmnt.roty + 0.01 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx, selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false, false,
          false,
          2, true, 1)
      end
      ImGui.SameLine()
      ImGui.ArrowButton("##rotYright", 1)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.roty = selected_attchmnt.roty - 0.01 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx, selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false, false,
          false,
          2, true, 1)
      end
      ImGui.SameLine()
      ImGui.Dummy(5, 1); ImGui.SameLine()
      ImGui.ArrowButton("##rotZup", 2)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.rotz = selected_attchmnt.rotz + 0.01 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx, selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false, false,
          false,
          2, true, 1)
      end
      ImGui.SameLine()
      ImGui.ArrowButton("##rotZdown", 3)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.rotz = selected_attchmnt.rotz - 0.01 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx, selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false, false,
          false,
          2, true, 1)
      end
      ImGui.Spacing()
      if ImGui.Button("   " .. translateLabel("saveBtn") .. "   ##vehcreator1") then
        UI.widgetSound("Select2")
        ImGui.OpenPopup("Save Merged Vehicles")
      end
      ImGui.SetNextWindowPos(760, 400, ImGuiCond.Appearing)
      ImGui.SetNextWindowBgAlpha(0.81)
      if ImGui.BeginPopupModal("Save Merged Vehicles", ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
        creation_name, _ = ImGui.InputTextWithHint("##save_merge", translateLabel("vc_choose_name_hint"), creation_name, 128)
        if ImGui.IsItemActive() then
          is_typing = true
        else
          is_typing = false
        end
        ImGui.Spacing()
        if not start_loading_anim then
          if ImGui.Button(translateLabel("saveBtn") .. "##vehcreator2") then
            script.run_in_fiber(function(save)
              if creation_name ~= "" then
                if saved_vehicles[1] ~= nil then
                  for _, v in pairs(saved_vehicles) do
                    if creation_name == v.name then
                      UI.widgetSound("Error")
                      gui.show_error("Samurai's Scripts", translateLabel("vc_same_name_err"))
                      return
                    end
                  end
                end
                UI.widgetSound("Select")
                vehicle_creation.name         = creation_name
                vehicle_creation.main_veh     = ENTITY.GET_ENTITY_MODEL(main_vehicle)
                vehicle_creation.attachments  = veh_attachments
                vehicle_creation.tint         = VEHICLE.GET_VEHICLE_WINDOW_TINT(main_vehicle)
                vehicle_creation.color_1.r, vehicle_creation.color_1.g, vehicle_creation.color_1.b = VEHICLE.GET_VEHICLE_CUSTOM_PRIMARY_COLOUR(main_vehicle, vehicle_creation.color_1.r, vehicle_creation.color_1.g, vehicle_creation.color_1.b)
                vehicle_creation.color_2.r, vehicle_creation.color_2.g, vehicle_creation.color_2.b = VEHICLE.GET_VEHICLE_CUSTOM_SECONDARY_COLOUR(main_vehicle, vehicle_creation.color_2.r, vehicle_creation.color_2.g, vehicle_creation.color_2.b)
                appendVehicleMods(main_vehicle, vehicle_creation.mods)
                start_loading_anim = true
                save:sleep(500)
                table.insert(saved_vehicles, vehicle_creation)
                lua_cfg.save("saved_vehicles", saved_vehicles)
                ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(main_vehicle)
                for _, veh in ipairs(spawned_vehicles) do
                  ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(veh)
                end
                gui.show_success("Samurais Scripts", translateLabel("vc_saved_msg"))
                resetOnSave()
                start_loading_anim = false
                ImGui.CloseCurrentPopup()
              else
                UI.widgetSound("Error")
                gui.show_warning("Samurais Scripts", translateLabel("vc_save_err"))
              end
            end)
          end
        else
          ImGui.BeginDisabled()
          ImGui.Button("  " .. loading_label .. "  ")
          ImGui.EndDisabled()
        end
        ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
        if ImGui.Button(translateLabel("generic_cancel_btn") .. "##vehcreator") then
          UI.widgetSound("Cancel")
          creation_name = ""
          ImGui.CloseCurrentPopup()
        end
        ImGui.End()
      end
    end
  elseif persist_switch == 1 then
    if saved_vehicles[1] ~= nil then
      ImGui.PushItemWidth(350)
      showSavedVehicles()
      ImGui.PopItemWidth()
      persist_info = filteredCreations[persist_index + 1]
      ImGui.Spacing()
      if ImGui.Button(translateLabel("vc_spawn_persist") .. "##vehcreator") then
        UI.widgetSound("Select")
        spawnPersistVeh(persist_info.main_veh, persist_info.mods, persist_info.color_1, persist_info.color_2, persist_info.tint, persist_info.attachments)
      end
      ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine()
      if UI.coloredButton(translateLabel("vc_delete_persist"), "#E40000", "#FF3F3F", "#FF8080", 0.87) then
        UI.widgetSound("Focus_In")
        ImGui.OpenPopup("Remove Persistent")
      end
      ImGui.SetNextWindowPos(760, 400, ImGuiCond.Appearing)
      ImGui.SetNextWindowSizeConstraints(200, 100, 400, 400)
      ImGui.SetNextWindowBgAlpha(0.7)
      if ImGui.BeginPopupModal("Remove Persistent", ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
        UI.coloredText(translateLabel("confirm_txt"), "yellow", 0.91, 35)
        ImGui.Dummy(1, 20)
        if ImGui.Button("   " .. translateLabel("yes") .. "   ##vehcreator") then
          for key, value in ipairs(saved_vehicles) do
            if persist_info == value then
              table.remove(saved_vehicles, key)
              lua_cfg.save("saved_vehicles", saved_vehicles)
            end
          end
          if saved_vehicles[1] == nil then
            persist_switch = 0
          end
          UI.widgetSound("Select")
          ImGui.CloseCurrentPopup()
          gui.show_success("Samurais Scripts", translateLabel("vc_delete_msg"))
        end
        ImGui.SameLine(); ImGui.Dummy(20, 1); ImGui.SameLine()
        if ImGui.Button("   " .. translateLabel("no") .. "   ##vehcreator") then
          UI.widgetSound("Cancel")
          ImGui.CloseCurrentPopup()
        end
        ImGui.End()
      end
    end
  end
end)


--[[
    *online*
]]
online_tab = Samurais_scripts:add_tab("Online")

-- Casino
casino_pacino = online_tab:add_tab("Casino Pacino") --IT'S NOT AL ANYMORE! IT'S DUNK!
blackjack_cards                       = 116
blackjack_decks                       = 846
blackjack_table_players               = 1776
blackjack_table_players_size          = 8
three_card_poker_table                = 749
three_card_poker_table_size           = 9
three_card_poker_cards                = 116
three_card_poker_current_deck         = 168
three_card_poker_anti_cheat           = 1038
three_card_poker_anti_cheat_deck      = 799
three_card_poker_deck_size            = 55
roulette_master_table                 = 124
roulette_outcomes_table               = 1357
roulette_ball_table                   = 153
slots_random_results_table            = 1348
slots_slot_machine_state              = 1638
prize_wheel_win_state                 = 280
prize_wheel_prize                     = 14
prize_wheel_prize_state               = 45
gb_casino_heist_planning              = 1964849
gb_casino_heist_planning_cut_offset   = 1497 + 736 + 92
fm_mission_controller_cart_grab       = 10255
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
casino_cooldown_update_str            = ""
dealers_card_str                      = ""
heist_cart_autograb   = lua_cfg.read("heist_cart_autograb")
bypass_casino_bans                    = lua_cfg.read("bypass_casino_bans")
force_poker_cards                     = lua_cfg.read("bypass_casino_bans")
set_dealers_poker_cards               = lua_cfg.read("bypass_casino_bans")
force_roulette_wheel                  = lua_cfg.read("force_roulette_wheel")
rig_slot_machine                      = lua_cfg.read("rig_slot_machine")
autoplay_slots                        = lua_cfg.read("autoplay_slots")
autoplay_cap                          = lua_cfg.read("autoplay_cap")
autoplay_chips_cap                    = lua_cfg.read("autoplay_chips_cap")

local function set_poker_cards(player_id, players_current_table, card_one, card_two, card_three)
  locals.set_int("three_card_poker",
    (three_card_poker_cards) + (three_card_poker_current_deck) +
    (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (1) + (player_id * 3), card_one)
  locals.set_int("three_card_poker",
    (three_card_poker_anti_cheat) + (three_card_poker_anti_cheat_deck) + (1) +
    (1 + (players_current_table * three_card_poker_deck_size)) + (1) + (player_id * 3), card_one)
  locals.set_int("three_card_poker",
    (three_card_poker_cards) + (three_card_poker_current_deck) +
    (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (2) + (player_id * 3), card_two)
  locals.set_int("three_card_poker",
    (three_card_poker_anti_cheat) + (three_card_poker_anti_cheat_deck) + (1) +
    (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (player_id * 3), card_two)
  locals.set_int("three_card_poker",
    (three_card_poker_cards) + (three_card_poker_current_deck) +
    (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (3) + (player_id * 3), card_three)
  locals.set_int("three_card_poker",
    (three_card_poker_anti_cheat) + (three_card_poker_anti_cheat_deck) + (1) +
    (1 + (players_current_table * three_card_poker_deck_size)) + (3) + (player_id * 3), card_three)
end

local function get_cardname_from_index(card_index)
  if card_index == 0 then
    return "Rolling"
  end

  local card_number = math.fmod(card_index, 13)
  local cardName = ""
  local cardSuit = ""

  if card_number == 1 then
    cardName = "Ace"
  elseif card_number == 11 then
    cardName = "Jack"
  elseif card_number == 12 then
    cardName = "Queen"
  elseif card_number == 0 then
    cardName = "King"
  else
    cardName = tostring(card_number)
  end

  if card_index >= 1 and card_index <= 13 then
    cardSuit = "Clubs"
  elseif card_index >= 14 and card_index <= 26 then
    cardSuit = "Diamonds"
  elseif card_index >= 27 and card_index <= 39 then
    cardSuit = "Hearts"
  elseif card_index >= 40 and card_index <= 52 then
    cardSuit = "Spades"
  end

  return cardName .. " of " .. cardSuit
end

casino_pacino:add_imgui(function()
  if Game.isOnline() then
    ImGui.BeginTabBar("Dunk Pacino")
    if ImGui.BeginTabItem(translateLabel("Gambling")) then
      bypass_casino_bans, bcbUsed = ImGui.Checkbox(translateLabel("bypassCasinoCooldownCB"), bypass_casino_bans, true)
      if bcbUsed then
        UI.widgetSound("Nav2")
        lua_cfg.save("bypass_casino_bans", bypass_casino_bans)
      end
      if not bypass_casino_bans then
        UI.toolTip(true, translateLabel("casinoCDwarn"), "#FFCC00", 1)
      end

      ImGui.Spacing(); ImGui.Text(translateLabel("casinoCDstatus")); ImGui.SameLine()
      ImGui.BulletText(casino_cooldown_update_str)

      ImGui.Spacing(); ImGui.SeparatorText("Poker")
      force_poker_cards, fpcUsed = ImGui.Checkbox(translateLabel("forcePokerCardsCB"), force_poker_cards, true)
      if fpcUsed then
        UI.widgetSound("Nav2")
        lua_cfg.save("force_poker_cards", force_poker_cards)
      end

      set_dealers_poker_cards, sdpcUsed = ImGui.Checkbox(translateLabel("setDealersCardsCB"), set_dealers_poker_cards, true)
      if sdpcUsed then
        UI.widgetSound("Nav2")
        lua_cfg.save("set_dealers_poker_cards", set_dealers_poker_cards)
      end

      ImGui.Spacing(); ImGui.SeparatorText("Blackjack")
      ImGui.Spacing(); ImGui.BulletText(translateLabel("faceDownCard")); ImGui.SameLine(); ImGui.Text(dealers_card_str); ImGui.Spacing()
      if ImGui.Button(translateLabel("dealerBustBtn")) then
        UI.widgetSound("Select")
        script.run_in_fiber(function(script)
          local player_id = PLAYER.PLAYER_ID()
          while NETWORK.NETWORK_GET_HOST_OF_SCRIPT("blackjack", -1, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("blackjack", 0, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("blackjack", 1, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("blackjack", 2, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("blackjack", 3, 0) ~= player_id do
            network.force_script_host("blackjack")
            gui.show_message("CasinoPacino", "Taking control of the blackjack script.") --If you see this spammed, someone is fighting you for control.
            script:yield()
          end
          local blackjack_table = locals.get_int("blackjack", blackjack_table_players + 1 + (player_id * blackjack_table_players_size) + 4) --The Player's current table he is sitting at.
          if blackjack_table ~= -1 then
            locals.set_int("blackjack", blackjack_cards + blackjack_decks + 1 + (blackjack_table * 13) + 1, 11)
            locals.set_int("blackjack", blackjack_cards + blackjack_decks + 1 + (blackjack_table * 13) + 2, 12)
            locals.set_int("blackjack", blackjack_cards + blackjack_decks + 1 + (blackjack_table * 13) + 3, 13)
            locals.set_int("blackjack", blackjack_cards + blackjack_decks + 1 + (blackjack_table * 13) + 12, 3)
          end
        end)
      end

      ImGui.Spacing(); ImGui.SeparatorText("Roulette")
      force_roulette_wheel, frwUsed = ImGui.Checkbox(translateLabel("forceRouletteCB"), force_roulette_wheel, true)
      if frwUsed then
        UI.widgetSound("Nav2")
        lua_cfg.save("force_roulette_wheel", force_roulette_wheel)
      end

      ImGui.Spacing(); ImGui.SeparatorText("Slot Machines")
      rig_slot_machine, rsmUsed = ImGui.Checkbox(translateLabel("rigSlotsCB"), rig_slot_machine, true)
      if rsmUsed then
        UI.widgetSound("Nav2")
        lua_cfg.save("rig_slot_machine", rig_slot_machine)
      end

      autoplay_slots, apsUsed = ImGui.Checkbox(translateLabel("autoplaySlotsCB"), autoplay_slots, true); ImGui.SameLine()
      if apsUsed then
        UI.widgetSound("Nav2")
        lua_cfg.save("autoplay_slots", autoplay_slots)
      end
      if autoplay_slots then
        autoplay_cap, apcapUsed = ImGui.Checkbox(translateLabel("autoplayCapCB"), autoplay_cap, true); ImGui.SameLine()
        if apcapUsed then
          UI.widgetSound("Nav2")
          lua_cfg.save("autoplay_cap", autoplay_cap)
        end
        if autoplay_cap then
          ImGui.PushItemWidth(200)
          autoplay_chips_cap, chipsCapUsed = ImGui.InputInt("##chips_cap", autoplay_chips_cap, 1000, 100000, ImGuiInputTextFlags.CharsDecimal)
          ImGui.PopItemWidth()
          if chipsCapUsed then
            UI.widgetSound("Nav2")
            lua_cfg.save("autoplay_chips_cap", autoplay_chips_cap)
          end
        end
      end

      ImGui.Spacing(); ImGui.SeparatorText("Lucky Wheel")
      if ImGui.Button(translateLabel("podiumVeh_Btn")) then
        script.run_in_fiber(function()
          if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("casino_lucky_wheel")) ~= 0 then
            UI.widgetSound("Select")
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 18)
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
          else
            UI.widgetSound("Error")
          end
        end)
      end
      ImGui.SameLine()
      if ImGui.Button(translateLabel("mysteryPrize_Btn")) then
        script.run_in_fiber(function()
          if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("casino_lucky_wheel")) ~= 0 then
            UI.widgetSound("Select")
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 11)
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
          else
            UI.widgetSound("Error")
          end
        end)
      end

      ImGui.SameLine()
      if ImGui.Button(translateLabel("50k_Btn")) then
        script.run_in_fiber(function()
          if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("casino_lucky_wheel")) ~= 0 then
            UI.widgetSound("Select")
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 19)
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
          else
            UI.widgetSound("Error")
          end
        end)
      end

      if ImGui.Button(translateLabel("25k_Btn")) then
        script.run_in_fiber(function()
          if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("casino_lucky_wheel")) ~= 0 then
            UI.widgetSound("Select")
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 15)
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
          else
            UI.widgetSound("Error")
          end
        end)
      end

      ImGui.SameLine(); ImGui.Dummy(6, 1); ImGui.SameLine()
      if ImGui.Button(translateLabel("15k_Btn")) then
        script.run_in_fiber(function()
          if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("casino_lucky_wheel")) ~= 0 then
            UI.widgetSound("Select")
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 17)
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
          else
            UI.widgetSound("Error")
          end
        end)
      end

      ImGui.SameLine(); ImGui.Dummy(21, 1); ImGui.SameLine()
      if ImGui.Button(translateLabel("%_Btn")) then
        script.run_in_fiber(function ()
          if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("casino_lucky_wheel")) ~= 0 then
            UI.widgetSound("Select")
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 4)
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
          else
            UI.widgetSound("Error")
          end
        end)
      end

      if ImGui.Button(translateLabel("clothing_Btn")) then
        script.run_in_fiber(function ()
          if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("casino_lucky_wheel")) ~= 0 then
            UI.widgetSound("Select")
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize), 8)
            locals.set_int("casino_lucky_wheel", (prize_wheel_win_state) + (prize_wheel_prize_state), 11)
          else
            UI.widgetSound("Error")
          end
        end)
      end
      ImGui.EndTabItem()
    end
    if ImGui.BeginTabItem("Casino Heist") then
      ImGui.PushItemWidth(165)
      new_approach, approach_clicked = ImGui.Combo(translateLabel("approach"), casino_heist_approach, { "Unselected", "Silent & Sneaky", "The Big Con", "Aggressive" }, 4) --You gotta sneak the word in there, like you're sneaking in food to a movie theater. Tuck it in your jacket for later, then when they least suspect it, deploy the word.
      if approach_clicked then
        script.run_in_fiber(function()
          stats.set_int("MPX_H3OPT_APPROACH", new_approach)
        end)
      end
      ImGui.SameLine(); ImGui.Dummy(24, 0); ImGui.SameLine()
      local new_target, target_clicked = ImGui.Combo(translateLabel("target"), casino_heist_target, { "Money", "Gold", "Art", "Diamonds" }, 4)
      if target_clicked then
        script.run_in_fiber(function()
          stats.set_int("MPX_H3OPT_TARGET", new_target)
        end)
      end
      local new_last_approach, last_approach_clicked = ImGui.Combo(translateLabel("last_approach"), casino_heist_last_approach, { "Unselected", "Silent & Sneaky", "The Big Con", "Aggressive" }, 4)
      if last_approach_clicked then
        script.run_in_fiber(function()
          stats.set_int("MPX_H3_LAST_APPROACH", new_last_approach)
        end)
      end
      ImGui.SameLine()
      local new_hard_approach, hard_approach_clicked = ImGui.Combo(translateLabel("hard_approach"), casino_heist_hard, { "Unselected", "Silent & Sneaky", "The Big Con", "Aggressive" }, 4)
      if hard_approach_clicked then
        script.run_in_fiber(function()
          stats.set_int("MPX_H3_HARD_APPROACH", new_hard_approach)
        end)
      end
      ImGui.PopItemWidth()

      ImGui.Spacing()
      ImGui.PushItemWidth(165)
      local new_gunman, gunman_clicked = ImGui.Combo(translateLabel("gunman"), casino_heist_gunman, { "Unselected", "Karl Abolaji", "Gustavo Mota", "Charlie Reed", "Chester McCoy", "Patrick McReary" }, 6)
      if gunman_clicked then
        script.run_in_fiber(function()
          stats.set_int("MPX_H3OPT_CREWWEAP", new_gunman)
        end)
      end
      if casino_heist_gunman == 1 then --Karl Abolaji
        ImGui.SameLine(); ImGui.Dummy(31, 1); ImGui.SameLine()
        local karl_gun_list = { {'##1", "##2'}, { "Micro SMG Loadout", "Machine Pistol Loadout" }, { "Micro SMG Loadout", "Shotgun Loadout" }, { "Shotgun Loadout", "Revolver Loadout" } }
        local new_weapons, weapons_clicked = ImGui.Combo(translateLabel("unmarked_weapons"), casino_heist_weapons, karl_gun_list[casino_heist_approach+1], 2)
        if weapons_clicked then
          script.run_in_fiber(function()
            stats.set_int("MPX_H3OPT_WEAPS", new_weapons)
          end)
        end
      elseif casino_heist_gunman == 2 then --Gustavo Fring
        ImGui.SameLine(); ImGui.Dummy(31, 1); ImGui.SameLine()
        local new_weapons, weapons_clicked = ImGui.Combo(translateLabel("unmarked_weapons"), casino_heist_weapons, { "Rifle Loadout", "Shotgun Loadout" }, 2)
        if weapons_clicked then
          script.run_in_fiber(function()
            stats.set_int("MPX_H3OPT_WEAPS", new_weapons)
          end)
        end
      elseif casino_heist_gunman == 3 then --Charlie Reed
        ImGui.SameLine(); ImGui.Dummy(31, 1); ImGui.SameLine()
        local charlie_gun_list = { {'##1", "##2'}, { "SMG Loadout", "Shotgun Loadout" }, { "Machine Pistol Loadout", "Shotgun Loadout" }, { "SMG Loadout", "Shotgun Loadout" } }
        local new_weapons, weapons_clicked = ImGui.Combo(translateLabel("unmarked_weapons"), casino_heist_weapons, charlie_gun_list[casino_heist_approach+1], 2)
        if weapons_clicked then
          script.run_in_fiber(function()
            stats.set_int("MPX_H3OPT_WEAPS", new_weapons)
          end)
        end
      elseif casino_heist_gunman == 4 then --Chester McCoy
        ImGui.SameLine(); ImGui.Dummy(31, 1); ImGui.SameLine()
        local chester_gun_list = { {'##1", "##2'}, { "MK II Shotgun Loadout", "MK II Rifle Loadout" }, { "MK II SMG Loadout", "MK II Rifle Loadout" }, { "MK II Shotgun Loadout", "MK II Rifle Loadout" } }
        local new_weapons, weapons_clicked = ImGui.Combo(translateLabel("unmarked_weapons"), casino_heist_weapons, chester_gun_list[casino_heist_approach+1], 2)
        if weapons_clicked then
          script.run_in_fiber(function()
            stats.set_int("MPX_H3OPT_WEAPS", new_weapons)
          end)
        end
      elseif casino_heist_gunman == 5 then --Laddie Paddie Sadie Enweird
        ImGui.SameLine(); ImGui.Dummy(31, 1); ImGui.SameLine()
        local laddie_paddie_gun_list = { {'##1", "##2'}, { "Combat PDW Loadout", "Rifle Loadout" }, { "Shotgun Loadout", "Rifle Loadout" }, { "Shotgun Loadout", "Combat MG Loadout" } }
        local new_weapons, weapons_clicked = ImGui.Combo(translateLabel("unmarked_weapons"), casino_heist_weapons, laddie_paddie_gun_list[casino_heist_approach+1], 2)
        if weapons_clicked then
          script.run_in_fiber(function()
            stats.set_int("MPX_H3OPT_WEAPS", new_weapons)
          end)
        end
      end

      local new_driver, driver_clicked = ImGui.Combo(translateLabel("driver"), casino_heist_driver, { "Unselected", "Karim Deniz", "Taliana Martinez", "Eddie Toh", "Zach Nelson", "Chester McCoy" }, 6)
      if driver_clicked then
        script.run_in_fiber(function()
          stats.set_int("MPX_H3OPT_CREWDRIVER", new_driver)
        end)
      end

      if casino_heist_driver == 1 then --Karim Deniz
        ImGui.SameLine(); ImGui.Dummy(50, 1); ImGui.SameLine()
        local new_car, car_clicked = ImGui.Combo(translateLabel("getaways"), casino_heist_cars, { "Issi Classic", "Asbo", "Kanjo", "Sentinel Classic" }, 4)
        if car_clicked then
          script.run_in_fiber(function()
            stats.set_int("MPX_H3OPT_VEHS", new_car)
          end)
        end
      elseif casino_heist_driver == 2 then --Taliana Martinez
        ImGui.SameLine(); ImGui.Dummy(50, 1); ImGui.SameLine()
        local new_car, car_clicked = ImGui.Combo(translateLabel("getaways"), casino_heist_cars, { "Retinue MK II", "Drift Yosemite", "Sugoi", "Jugular" }, 4)
        if car_clicked then
          script.run_in_fiber(function()
            stats.set_int("MPX_H3OPT_VEHS", new_car)
          end)
        end
      elseif casino_heist_driver == 3 then --Eddie Toh
        ImGui.SameLine(); ImGui.Dummy(50, 1); ImGui.SameLine()
        local new_car, car_clicked = ImGui.Combo(translateLabel("getaways"), casino_heist_cars, { "Sultan Classic", "Guantlet Classic", "Ellie", "Komoda" }, 4)
        if car_clicked then
          script.run_in_fiber(function()
            stats.set_int("MPX_H3OPT_VEHS", new_car)
          end)
        end
      elseif casino_heist_driver == 4 then --Zach Nelson
        ImGui.SameLine(); ImGui.Dummy(50, 1); ImGui.SameLine()
        local new_car, car_clicked = ImGui.Combo(translateLabel("getaways"), casino_heist_cars, { "Manchez", "Stryder", "Defiler", "Lectro" }, 4)
        if car_clicked then
          script.run_in_fiber(function()
            stats.set_int("MPX_H3OPT_VEHS", new_car)
          end)
        end
      elseif casino_heist_driver == 5 then --Chester McCoy
        ImGui.SameLine(); ImGui.Dummy(50, 1); ImGui.SameLine()
        local new_car, car_clicked = ImGui.Combo(translateLabel("getaways"), casino_heist_cars, { "Zhaba", "Vagrant", "Outlaw", "Everon" }, 4)
        if car_clicked then
          script.run_in_fiber(function()
            stats.set_int("MPX_H3OPT_VEHS", new_car)
          end)
        end
      end

      local new_hacker, hacker_clicked = ImGui.Combo(translateLabel("hacker"), casino_heist_hacker, { "Unselected", "Rickie Lukens", "Christian Feltz", "Yohan Blair", "Avi Schwartzman", "Page Harris" }, 6)
      if hacker_clicked then
        script.run_in_fiber(function()
          stats.set_int("MPX_H3OPT_CREWHACKER", new_hacker)
        end)
      end

      local new_masks, masks_clicked = ImGui.Combo(translateLabel("masks"), casino_heist_masks, { "Unselected", "Geometric Set", "Hunter Set", "Oni Half Mask Set", "Emoji Set", "Ornate Skull Set", "Lucky Fruit Set", "Gurilla Set", "Clown Set", "Animal Set", "Riot Set", "Oni Set", "Hockey Set" }, 13)
      if masks_clicked then
        script.run_in_fiber(function()
          stats.set_int("MPX_H3OPT_MASKS", new_masks)
        end)
      end

      heist_cart_autograb, hcagUsed = ImGui.Checkbox(translateLabel("autograb"), heist_cart_autograb, true)
      if hcagUsed then
        UI.widgetSound("Nav2")
        lua_cgf.save("heist_cart_autograb", heist_cart_autograb)
      end

      if ImGui.Button(translateLabel("Unlock All Heist Options")) then
        UI.widgetSound("Select")
        script.run_in_fiber(function()
          stats.set_int("MPX_H3OPT_ACCESSPOINTS", -1)
          stats.set_int("MPX_H3OPT_POI", -1)
          stats.set_int("MPX_H3OPT_BITSET0", -1)
          stats.set_int("MPX_H3OPT_BITSET1", -1)
          stats.set_int("MPX_H3OPT_BODYARMORLVL", 3)
          stats.set_int("MPX_H3OPT_DISRUPTSHIP", 3)
          stats.set_int("MPX_H3OPT_KEYLEVELS", 2)
          stats.set_int("MPX_H3_COMPLETEDPOSIX", 0)
          stats.set_int("MPX_CAS_HEIST_FLOW", -1)
          stats.set_int("MPPLY_H3_COOLDOWN", 0)
          stats.set_packed_stat_bool(26969, true) --Unlock High Roller
        end)
      end

      if ImGui.Button(translateLabel("%0_ai_cuts_Btn")) then
        UI.widgetSound("Select")
        tunables.set_int("CH_LESTER_CUT", 0)
        tunables.set_int("HEIST3_PREPBOARD_GUNMEN_KARL_CUT", 0)
        tunables.set_int("HEIST3_PREPBOARD_GUNMEN_GUSTAVO_CUT", 0)
        tunables.set_int("HEIST3_PREPBOARD_GUNMEN_CHARLIE_CUT", 0)
        tunables.set_int("HEIST3_PREPBOARD_GUNMEN_CHESTER_CUT", 0)
        tunables.set_int("HEIST3_PREPBOARD_GUNMEN_PATRICK_CUT", 0)
        tunables.set_int("HEIST3_DRIVERS_KARIM_CUT", 0)
        tunables.set_int("HEIST3_DRIVERS_TALIANA_CUT", 0)
        tunables.set_int("HEIST3_DRIVERS_EDDIE_CUT", 0)
        tunables.set_int("HEIST3_DRIVERS_ZACH_CUT", 0)
        tunables.set_int("HEIST3_DRIVERS_CHESTER_CUT", 0)
        tunables.set_int("HEIST3_HACKERS_CHRISTIAN_CUT", 0)
        tunables.set_int("HEIST3_HACKERS_YOHAN_CUT", 0)
        tunables.set_int("HEIST3_HACKERS_AVI_CUT", 0)
        tunables.set_int("HEIST3_HACKERS_RICKIE_CUT", 0)
        tunables.set_int("HEIST3_HACKERS_PAIGE_CUT", 0)
        tunables.set_int("HEIST3_FINALE_CLEAN_VEHICLE", 0)
        tunables.set_int("HEIST3_FINALE_DECOY_GUNMAN", 0)
      end

      if ImGui.Button(translateLabel("%100_p_cuts_Btn")) then
        UI.widgetSound("Select")
        for i = 1, 4, 1 do
          globals.set_int(gb_casino_heist_planning + gb_casino_heist_planning_cut_offset + i, 100)
        end
      end
      ImGui.EndTabItem()
    end
  else
    ImGui.Dummy(1, 5); ImGui.Text(translateLabel("Unavailable in Single Player"))
  end
end)

-- Players
players_tab = online_tab:add_tab(translateLabel("playersTab"))
playerIndex           = 0
local selectedPlayer  = 0
local playerCount     = 0
local targetPlayerPed = 0
local playerHeading   = 0
local playerHealth    = 0
local playerArmour    = 0
local playerVeh       = 0
local player_name     = ""
local playerWallet    = ""
local playerBank      = ""
local playerCoords    = vector3
local godmode         = false
local player_in_veh   = false
local player_active   = false
local targetPlayerIndex
players_tab:add_imgui(function()
  if Game.isOnline() then
    ImGui.Text(translateLabel("Total Players:") .. "  [ " .. playerCount .. " ]")
    ImGui.PushItemWidth(320)
    Game.displayPlayerList()
    ImGui.PopItemWidth()
    ImGui.Spacing()
    if player_active then
      ImGui.Spacing()
      ImGui.Text("Cash:" .. "      " .. playerWallet)
      ImGui.Spacing()
      ImGui.Text("Bank:" .. "      " .. playerBank)
      ImGui.Spacing()
      ImGui.Text("Coords:" .. "      " .. tostring(playerCoords))
      if ImGui.IsItemHovered() and ImGui.IsItemClicked(0) then
        log.debug(player_name .. "'s coords: " .. tostring(playerCoords))
        gui.show_message("Samurai's Scripts", player_name .. "'s coordinates logged to console.")
      end
      ImGui.Spacing()
      ImGui.Text("Heading:" .. "     " .. tostring(playerHeading))
      if ImGui.IsItemHovered() and ImGui.IsItemClicked(0) then
        log.debug(player_name .. "'s heading: " .. tostring(playerHeading))
        gui.show_message("Samurai's Scripts", player_name .. "'s heading logged to console.")
      end
      ImGui.Spacing()
      ImGui.Text("Health:" .. "        " .. tostring(playerHealth))
      if playerArmour ~= nil then
        ImGui.Spacing()
        ImGui.Text("Armour:" .. "      " .. tostring(playerArmour))
      end
      ImGui.Spacing()
      ImGui.Text("God Mode:" .. "  " .. tostring(godmode))
      if player_in_veh then
        ImGui.Spacing()
        ImGui.Text("Vehicle:" .. "  " .. tostring(vehicles.get_vehicle_display_name(ENTITY.GET_ENTITY_MODEL(playerVeh))))
        if ImGui.Button("Delete Vehicle") then
          script.run_in_fiber(function(del)
            local pvCTRL = entities.take_control_of(playerVeh, 350)
            if pvCTRL then
              ENTITY.SET_ENTITY_AS_MISSION_ENTITY(playerVeh, true, true)
              del:sleep(200)
              VEHICLE.DELETE_VEHICLE(playerVeh)
              gui.show_success("Samurai's Scripts", "" .. player_name .. "'s vehicle has been yeeted.")
            else
              gui.show_error("Samurai's Scripts",
                "Failed to delete the vehicle! " .. player_name .. " probably has protections on.")
            end
          end)
        end
      end
    else
      ImGui.Text("Player left the session.")
    end
  else
    ImGui.Dummy(1, 5); ImGui.Text(translateLabel("Unavailable in Single Player"))
  end
end)


--[[
    *world*
]]
world_tab = Samurais_scripts:add_tab(translateLabel("worldTab"))

local default_wanted_lvl = 5

local function playHandsUp()
  script.run_in_fiber(function()
    if Game.requestAnimDict("mp_missheist_countrybank@lift_hands") then
      TASK.TASK_PLAY_ANIM(self.get_ped(), "mp_missheist_countrybank@lift_hands", "lift_hands_in_air_outro", 4.0, -4.0, -1,
        50, 1.0, false, false, false)
    end
  end)
end

local function attachPed(ped)
  local myBone = PED.GET_PED_BONE_INDEX(self.get_ped(), 6286)
  script.run_in_fiber(function()
    if not ped_grabbed and not PED.IS_PED_A_PLAYER(ped) then
      if entities.take_control_of(ped, 300) then
        if is_handsUp then
          TASK.CLEAR_PED_TASKS(self.get_ped())
          is_handsUp = false
        end
        if is_playing_anim then
          if anim_music then
            play_music("stop")
            anim_music = false
          end
          cleanup()
          is_playing_anim = false
        end
        if is_playing_scenario then
          TASK.CLEAR_PED_TASKS(self.get_ped())
          if ENTITY.DOES_ENTITY_EXIST(bbq) then
            ENTITY.DELETE_ENTITY(bbq)
          end
          is_playing_scenario = false
        end
        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(ped, self.get_ped(), myBone, 0.35, 0.3, -0.04, 100.0, 90.0, -10.0, false, true,
          false, true, 1, true, 1)
        ped_grabbed = true
        attached_ped = ped
      else
        gui.show_error("Samurai's Scripts", translateLabel("failedToCtrlNPC"))
      end
    end
  end)
  return ped_grabbed, attached_ped
end

local function attachVeh(veh)
  local attach_X
  local veh_class = Game.Vehicle.class(veh)
  local myBone = PED.GET_PED_BONE_INDEX(self.get_ped(), 6286)
  script.run_in_fiber(function()
    if not vehicle_grabbed and not VEHICLE.IS_THIS_MODEL_A_TRAIN(veh_model) then
      if entities.take_control_of(veh, 300) then
        if is_handsUp then
          TASK.CLEAR_PED_TASKS(self.get_ped())
          is_handsUp = false
        end
        if is_playing_anim then
          if anim_music then
            play_music("stop")
            anim_music = false
          end
          cleanup()
          is_playing_anim = false
        end
        if is_playing_scenario then
          TASK.CLEAR_PED_TASKS(self.get_ped())
          if ENTITY.DOES_ENTITY_EXIST(bbq) then
            ENTITY.DELETE_ENTITY(bbq)
          end
          is_playing_scenario = false
        end
        if isCrouched then
          PED.RESET_PED_MOVEMENT_CLIPSET(self.get_ped(), 0.3)
          isCrouched = false
        end
        if veh_class == "Commercial" or veh_class == "Industrial" or veh_class == "Utility" then
          if VEHICLE.IS_BIG_VEHICLE(veh) then
            attach_X  = 2.1
            attach_RY = 0.0
          else
            attach_X  = 1.9
            attach_RY = 0.0
          end
        elseif veh_class == "Cycles" or veh_class == "Motorcycles" then
          attach_X  = 0.4
          attach_RY = 0.0
        elseif veh_class == "Planes" or veh_class == "Helicopters" then
          attach_X  = 1.45
          attach_RY = 90
        else
          attach_X  = 1.17
          attach_RY = 0.0
        end
        ENTITY.ATTACH_ENTITY_TO_ENTITY(veh, self.get_ped(), myBone, attach_X, 0.0, 0.0, 0.0, attach_RY, -16.0, false, true,
          false, true, 1, true, 1)
        vehicle_grabbed = true
        grabbed_veh     = veh
      else
        gui.show_error("Samurai's Scripts", translateLabel("failedToCtrlNPC"))
      end
    end
  end)
  return vehicle_grabbed, grabbed_veh
end

local function displayHijackAnims()
  local groupAnimNames = {}
  for _, anim in ipairs(hijackOptions) do
      table.insert(groupAnimNames, anim.name)
  end
  grp_anim_index, used = ImGui.Combo("##groupAnims", grp_anim_index, groupAnimNames, #hijackOptions)
end

world_tab:add_imgui(function()
  if ped_grabbed or vehicle_grabbed then
    ImGui.BeginDisabled()
    pedGrabber, pgUsed = ImGui.Checkbox(translateLabel("pedGrabber"), pedGrabber, true)
    ImGui.EndDisabled()
  else
    pedGrabber, pgUsed = ImGui.Checkbox(translateLabel("pedGrabber"), pedGrabber, true)
    UI.helpMarker(false, translateLabel("pedGrabber_tt"))
    if pgUsed then
      UI.widgetSound("Nav2")
      if pedGrabber then
        vehicleGrabber = false
      end
    end
  end

  if pedGrabber then
    ImGui.Text(translateLabel("Throw Force"))
    ImGui.PushItemWidth(220)
    pedthrowF, ptfUsed = ImGui.SliderInt("##throw_force", pedthrowF, 10, 100, "%d", 0)
    ImGui.PopItemWidth()
    if ptfUsed then
      UI.widgetSound("Nav")
    end
  end

  if ped_grabbed or vehicle_grabbed then
    ImGui.BeginDisabled()
    vehicleGrabber, vgUsed = ImGui.Checkbox("Vehicle Grabber", vehicleGrabber, true)
    ImGui.EndDisabled()
  else
    vehicleGrabber, vgUsed = ImGui.Checkbox("Vehicle Grabber", vehicleGrabber, true)
    UI.helpMarker(false, "Same as 'Ped Grabber' but with vehicles.")
    if vgUsed then
      UI.widgetSound("Nav2")
      if vehicleGrabber then
        pedGrabber = false
      end
    end
  end

  if vehicleGrabber then
    ImGui.Text("Throw Force")
    ImGui.PushItemWidth(220)
    pedthrowF, ptfUsed = ImGui.SliderInt("##throw_force", pedthrowF, 10, 100, "%d", 0)
    ImGui.PopItemWidth()
    if ptfUsed then
      UI.widgetSound("Nav")
    end
  end

  carpool, carpoolUsed = ImGui.Checkbox(translateLabel("carpool"), carpool, true)
  UI.helpMarker(false, translateLabel("carpool_tt"))
  if carpoolUsed then
    UI.widgetSound("Nav2")
  end

  if carpool then
    if show_npc_veh_ctrls and thisVeh ~= 0 then
      if ImGui.Button("< " .. translateLabel("prevSeat")) then
        script.run_in_fiber(function()
          if PED.IS_PED_SITTING_IN_VEHICLE(self.get_ped(), thisVeh) then
            local numSeats = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(thisVeh)
            local mySeat   = Game.getPedVehicleSeat(self.get_ped())
            if mySeat <= 0 then
              mySeat = numSeats
            end
            mySeat = mySeat - 1
            if VEHICLE.IS_VEHICLE_SEAT_FREE(thisVeh, mySeat, true) then
              UI.widgetSound("Nav")
              PED.SET_PED_INTO_VEHICLE(self.get_ped(), thisVeh, mySeat)
            else
              mySeat = mySeat - 1
              return
            end
          end
        end)
      end
      ImGui.SameLine()
      if ImGui.Button(translateLabel("nextSeat") .. " >") then
        script.run_in_fiber(function()
          if PED.IS_PED_SITTING_IN_VEHICLE(self.get_ped(), thisVeh) then
            local numSeats = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(thisVeh)
            local mySeat   = Game.getPedVehicleSeat(self.get_ped())
            if mySeat > numSeats then
              mySeat = 0
            end
            mySeat = mySeat + 1
            if VEHICLE.IS_VEHICLE_SEAT_FREE(thisVeh, mySeat, true) then
              UI.widgetSound("Nav")
              PED.SET_PED_INTO_VEHICLE(self.get_ped(), thisVeh, mySeat)
            else
              mySeat = mySeat + 1
              return
            end
          end
        end)
      end
    end
  end

  animateNPCs, used = ImGui.Checkbox("Animate Nearby NPCs", animateNPCs, true)
  if used then
    UI.widgetSound("Nav")
  end
  UI.helpMarker(false, "Make all nearby NPCs do one of the actions listed down below. This has no relation to the animations list and only works with NPCs that are on foot.")
  if animateNPCs then
    ImGui.PushItemWidth(220)
    displayHijackAnims()
    ImGui.PopItemWidth()
    local hijackData = hijackOptions[grp_anim_index + 1]
    ImGui.SameLine()
    if not hijack_started then
      if ImGui.Button("  Start  ##hjStart") then
        UI.widgetSound("Select")
        script.run_in_fiber(function(hjk)
          local gta_peds = entities.get_all_peds_as_handles()
          while not STREAMING.HAS_ANIM_DICT_LOADED(hijackData.dict) do
            STREAMING.REQUEST_ANIM_DICT(hijackData.dict)
            coroutine.yield()
          end
          for _, npc in pairs(gta_peds) do
            if not PED.IS_PED_A_PLAYER(npc) and not PED.IS_PED_IN_ANY_VEHICLE(npc, true) then
              TASK.CLEAR_PED_TASKS_IMMEDIATELY(npc)
              TASK.CLEAR_PED_SECONDARY_TASK(npc)
              hjk:sleep(50)
              TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(npc, true)
              PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(npc, true)
              TASK.TASK_PLAY_ANIM(npc, hijackData.dict, hijackData.anim, 4.0, -4.0, -1, 1, 1.0, false, false, false)
              hijack_started = true
            end
          end
        end)
      end
    else
      if ImGui.Button("  Stop  ##hjStop") then
        UI.widgetSound("Cancel")
        script.run_in_fiber(function()
          local gta_peds = entities.get_all_peds_as_handles()
          for _, npc in ipairs(gta_peds) do
            if not PED.IS_PED_A_PLAYER(npc) then
              TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(npc, false)
              PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(npc, false)
              TASK.CLEAR_PED_TASKS(npc)
              hijack_started = false
            end
          end
        end)
      end
    end
  end

  kamikazeDrivers, kdUsed = ImGui.Checkbox("Kamikaze Drivers", kamikazeDrivers, true)
  if kdUsed then
    UI.widgetSound("Nav2")
    if kamikazeDrivers then
      publicEnemy = false
    end
  end
  UI.helpMarker(false, translateLabel("kamikazeDrivers_tt"))

  publicEnemy, peUsed = ImGui.Checkbox("Public Enemy N°1", publicEnemy, true)
  UI.helpMarker(false, "Everyone is out to get you")
  if peUsed then
    UI.widgetSound("Nav2")
    if publicEnemy then
      kamikazeDrivers = false
      runaway         = false
      script.run_in_fiber(function()
        default_wanted_lvl = PLAYER.GET_MAX_WANTED_LEVEL()
      end)
    else
      script.run_in_fiber(function()
        local myGroup = PED.GET_PED_GROUP_INDEX(self.get_ped())
        if default_wanted_lvl ~= nil then
          PLAYER.SET_MAX_WANTED_LEVEL(default_wanted_lvl)
          PLAYER.SET_POLICE_IGNORE_PLAYER(self.get_id(), false)
        end
        for _, ped in ipairs(entities.get_all_peds_as_handles()) do
          if not PED.IS_PED_A_PLAYER(ped) and not PED.IS_PED_GROUP_MEMBER(ped, myGroup) then
            if PED.IS_PED_IN_COMBAT(ped, self.get_ped()) then
              for _, attr in ipairs(pe_combat_attributes_T) do
                PED.SET_PED_COMBAT_ATTRIBUTES(ped, attr.id, (not attr.bool))
              end
              for _, cflg in ipairs(pe_config_flags_T) do
                if PED.GET_PED_CONFIG_FLAG(ped, cflg.id, cflg.bool) then
                  PED.SET_PED_CONFIG_FLAG(ped, cflg.id, (not cflg.bool))
                end
              end
              TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
              TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, false)
              PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, false)
            end
          end
        end
      end)
    end
  end
end)

object_spawner = world_tab:add_tab("Object Spawner")
local coords                 = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
local heading                = ENTITY.GET_ENTITY_HEADING(self.get_ped())
local forwardX               = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
local forwardY               = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
local objects_search         = ""
local propName               = ""
local invalidType            = ""
local edit_mode              = false
local activeX                = false
local activeY                = false
local activeZ                = false
local rotX                   = false
local rotY                   = false
local rotZ                   = false
local attached               = false
local attachToSelf           = false
local attachToVeh            = false
local previewStarted         = false
local isChanged              = false
local showInvalidObjText     = false
local blacklisted_obj        = false
local prop                   = 0
local propHash               = 0
local os_switch              = 0
local prop_index             = 0
local objects_index          = 0
local spawned_index          = 0
local selectedObject         = 0
local axisMult               = 1
local selected_bone          = 0
local previewEntity          = 0
local currentObjectPreview   = 0
local attached_index         = 0
local zOffset                = 0
local spawned_props          = {}
local spawnedNames           = {}
local filteredSpawnNames     = {}
local selfAttachments        = {}
local selfAttachNames        = {}
local vehAttachments         = {}
local vehAttachNames         = {}
local filteredVehAttachNames = {}
local filteredAttachNames    = {}
local spawnDistance          = { x = 0, y = 0, z = 0 }
local spawnRot               = { x = 0, y = 0, z = 0 }
local attachPos              = { x = 0.0, y = 0.0, z = 0.0, rotX = 0.0, rotY = 0.0, rotZ = 0.0 }
local pedBones               = {
  { name = "Root",       ID = 0 },
  { name = "Head",       ID = 12844 },
  { name = "Spine 00",   ID = 23553 },
  { name = "Spine 01",   ID = 24816 },
  { name = "Spine 02",   ID = 24817 },
  { name = "Spine 03",   ID = 24818 },
  { name = "Right Hand", ID = 6286 },
  { name = "Left Hand",  ID = 18905 },
  { name = "Right Foot", ID = 35502 },
  { name = "Left Foot",  ID = 14201 },
}
local vehBones               = { "chassis", "chassis_lowlod", "chassis_dummy", "seat_dside_f", "seat_dside_r",
  "seat_dside_r1", "seat_dside_r2", "seat_dside_r3", "seat_dside_r4", "seat_dside_r5", "seat_dside_r6", "seat_dside_r7",
  "seat_pside_f", "seat_pside_r", "seat_pside_r1", "seat_pside_r2", "seat_pside_r3", "seat_pside_r4", "seat_pside_r5",
  "seat_pside_r6", "seat_pside_r7", "window_lf1", "window_lf2", "window_lf3", "window_rf1", "window_rf2", "window_rf3",
  "window_lr1", "window_lr2", "window_lr3", "window_rr1", "window_rr2", "window_rr3", "door_dside_f", "door_dside_r",
  "door_pside_f", "door_pside_r", "handle_dside_f", "handle_dside_r", "handle_pside_f", "handle_pside_r", "wheel_lf",
  "wheel_rf", "wheel_lm1", "wheel_rm1", "wheel_lm2", "wheel_rm2", "wheel_lm3", "wheel_rm3", "wheel_lr", "wheel_rr",
  "suspension_lf", "suspension_rf", "suspension_lm", "suspension_rm", "suspension_lr", "suspension_rr", "spring_rf",
  "spring_lf", "spring_rr", "spring_lr", "transmission_f", "transmission_m", "transmission_r", "hub_lf", "hub_rf",
  "hub_lm1", "hub_rm1", "hub_lm2", "hub_rm2", "hub_lm3", "hub_rm3", "hub_lr", "hub_rr", "windscreen", "windscreen_r",
  "window_lf", "window_rf", "window_lr", "window_rr", "window_lm", "window_rm", "bodyshell", "bumper_f", "bumper_r",
  "wing_rf", "wing_lf", "bonnet", "boot", "exhaust", "exhaust_2", "exhaust_3", "exhaust_4", "exhaust_5", "exhaust_6",
  "exhaust_7", "exhaust_8", "exhaust_9", "exhaust_10", "exhaust_11", "exhaust_12", "exhaust_13", "exhaust_14",
  "exhaust_15", "exhaust_16", "engine", "overheat", "overheat_2", "petrolcap", "petroltank", "petroltank_l",
  "petroltank_r", "steering", "hbgrip_l", "hbgrip_r", "headlight_l", "headlight_r", "taillight_l", "taillight_r",
  "indicator_lf", "indicator_rf", "indicator_lr", "indicator_rr", "brakelight_l", "brakelight_r", "brakelight_m",
  "reversinglight_l", "reversinglight_r", "extralight_1", "extralight_2", "extralight_3", "extralight_4", "numberplate",
  "interiorlight", "siren1", "siren2", "siren3", "siren4", "siren5", "siren6", "siren7", "siren8", "siren9", "siren10",
  "siren11", "siren12", "siren13", "siren14", "siren15", "siren16", "siren17", "siren18", "siren19", "siren20",
  "siren_glass1", "siren_glass2", "siren_glass3", "siren_glass4", "siren_glass5", "siren_glass6", "siren_glass7",
  "siren_glass8", "siren_glass9", "siren_glass10", "siren_glass11", "siren_glass12", "siren_glass13", "siren_glass14",
  "siren_glass15", "siren_glass16", "siren_glass17", "siren_glass18", "siren_glass19", "siren_glass20", "spoiler",
  "struts", "misc_a", "misc_b", "misc_c", "misc_d", "misc_e", "misc_f", "misc_g", "misc_h", "misc_i", "misc_j", "misc_k",
  "misc_l", "misc_m", "misc_n", "misc_o", "misc_p", "misc_q", "misc_r", "misc_s", "misc_t", "misc_u", "misc_v", "misc_w",
  "misc_x", "misc_y", "misc_z", "misc_1", "misc_2", "weapon_1a", "weapon_1b", "weapon_1c", "weapon_1d", "weapon_1a_rot",
  "weapon_1b_rot", "weapon_1c_rot", "weapon_1d_rot", "weapon_2a", "weapon_2b", "weapon_2c", "weapon_2d", "weapon_2a_rot",
  "weapon_2b_rot", "weapon_2c_rot", "weapon_2d_rot", "weapon_3a", "weapon_3b", "weapon_3c", "weapon_3d", "weapon_3a_rot",
  "weapon_3b_rot", "weapon_3c_rot", "weapon_3d_rot", "weapon_4a", "weapon_4b", "weapon_4c", "weapon_4d", "weapon_4a_rot",
  "weapon_4b_rot", "weapon_4c_rot", "weapon_4d_rot", "turret_1base", "turret_1barrel", "turret_2base", "turret_2barrel",
  "turret_3base", "turret_3barrel", "ammobelt", "searchlight_base", "searchlight_light", "attach_female", "roof", "roof2",
  "soft_1", "soft_2", "soft_3", "soft_4", "soft_5", "soft_6", "soft_7", "soft_8", "soft_9", "soft_10", "soft_11",
  "soft_12", "soft_13", "forks", "mast", "carriage", "fork_l", "fork_r", "forks_attach", "frame_1", "frame_2", "frame_3",
  "frame_pickup_1", "frame_pickup_2", "frame_pickup_3", "frame_pickup_4", "freight_cont", "freight_bogey",
  "freightgrain_slidedoor", "door_hatch_r", "door_hatch_l", "tow_arm", "tow_mount_a", "tow_mount_b", "tipper",
  "combine_reel", "combine_auger", "slipstream_l", "slipstream_r", "arm_1", "arm_2", "arm_3", "arm_4", "scoop", "boom",
  "stick", "bucket", "shovel_2", "shovel_3", "Lookat_UpprPiston_head", "Lookat_LowrPiston_boom", "Boom_Driver",
  "cutter_driver", "vehicle_blocker", "extra_1", "extra_2", "extra_3", "extra_4", "extra_5", "extra_6", "extra_7",
  "extra_8", "extra_9", "extra_ten", "extra_11", "extra_12", "break_extra_1", "break_extra_2", "break_extra_3",
  "break_extra_4", "break_extra_5", "break_extra_6", "break_extra_7", "break_extra_8", "break_extra_9", "break_extra_10",
  "mod_col_1", "mod_col_2", "mod_col_3", "mod_col_4", "mod_col_5", "handlebars", "forks_u", "forks_l", "wheel_f",
  "swingarm", "wheel_r", "crank", "pedal_r", "pedal_l", "static_prop", "moving_prop", "static_prop2", "moving_prop2",
  "rudder", "rudder2", "wheel_rf1_dummy", "wheel_rf2_dummy", "wheel_rf3_dummy", "wheel_rb1_dummy", "wheel_rb2_dummy",
  "wheel_rb3_dummy", "wheel_lf1_dummy", "wheel_lf2_dummy", "wheel_lf3_dummy", "wheel_lb1_dummy", "wheel_lb2_dummy",
  "wheel_lb3_dummy", "bogie_front", "bogie_rear", "rotor_main", "rotor_rear", "rotor_main_2", "rotor_rear_2", "elevators",
  "tail", "outriggers_l", "outriggers_r", "rope_attach_a", "rope_attach_b", "prop_1", "prop_2", "elevator_l",
  "elevator_r", "rudder_l", "rudder_r", "prop_3", "prop_4", "prop_5", "prop_6", "prop_7", "prop_8", "rudder_2",
  "aileron_l", "aileron_r", "airbrake_l", "airbrake_r", "wing_l", "wing_r", "wing_lr", "wing_rr", "engine_l", "engine_r",
  "nozzles_f", "nozzles_r", "afterburner", "wingtip_1", "wingtip_2", "gear_door_fl", "gear_door_fr", "gear_door_rl1",
  "gear_door_rr1", "gear_door_rl2", "gear_door_rr2", "gear_door_rml", "gear_door_rmr", "gear_f", "gear_rl", "gear_lm1",
  "gear_rr", "gear_rm1", "gear_rm", "prop_left", "prop_right", "legs", "attach_male", "draft_animal_attach_lr",
  "draft_animal_attach_rr", "draft_animal_attach_lm", "draft_animal_attach_rm", "draft_animal_attach_lf",
  "draft_animal_attach_rf", "wheelcover_l", "wheelcover_r", "barracks", "pontoon_l", "pontoon_r", "no_ped_col_step_l",
  "no_ped_col_strut_1_l", "no_ped_col_strut_2_l", "no_ped_col_step_r", "no_ped_col_strut_1_r", "no_ped_col_strut_2_r",
  "light_cover", "emissives", "neon_l", "neon_r", "neon_f", "neon_b", "dashglow", "doorlight_lf", "doorlight_rf",
  "doorlight_lr", "doorlight_rr", "unknown_id", "dials", "engineblock", "bobble_head", "bobble_base", "bobble_hand",
  "chassis_Control", }

local function resetSliders()
  spawnDistance = { x = 0, y = 0, z = 0 }
  spawnRot      = { x = 0, y = 0, z = 0 }
  attachPos     = { x = 0.0, y = 0.0, z = 0.0, rotX = 0.0, rotY = 0.0, rotZ = 0.0 }
end

object_spawner:add_imgui(function()
  ImGui.PushItemWidth(280)
  objects_search, used = ImGui.InputTextWithHint("##searchObjects", translateLabel("search_hint"), objects_search, 32)
  ImGui.PopItemWidth()
  if ImGui.IsItemActive() then
    is_typing = true
  else
    is_typing = false
  end
end)

local function updateFilteredProps()
  filteredProps = {}
  for _, p in ipairs(custom_props) do
    if string.find(string.lower(p.name), string.lower(objects_search)) then
      table.insert(filteredProps, p)
    end
    table.sort(custom_props, function(a, b)
      return a.name < b.name
    end)
  end
end

local function displayFilteredProps()
  updateFilteredProps()
  local propNames = {}
  for _, p in ipairs(filteredProps) do
    table.insert(propNames, p.name)
  end
  prop_index, used = ImGui.ListBox("##propList", prop_index, propNames, #filteredProps)
  prop = filteredProps[prop_index + 1]
  if prop ~= nil then
    propHash = prop.hash
    propName = prop.name
  end
end

local function getAllObjects()
  filteredObjects = {}
  for _, object in ipairs(gta_objets) do
    if objects_search ~= "" then
      if string.find(string.lower(object), string.lower(objects_search)) then
        table.insert(filteredObjects, object)
      end
    else
      table.insert(filteredObjects, object)
    end
  end
  objects_index, used = ImGui.ListBox("##gtaObjectsList", objects_index, filteredObjects, #filteredObjects)
  prop                = filteredObjects[objects_index + 1]
  propHash            = joaat(prop)
  propName            = prop
  if gui.is_open() and os_switch ~= 0 then
    for _, b in ipairs(mp_blacklist) do
      if propName == b then
        showInvalidObjText = true
        blacklisted_obj    = true
        invalidType = translateLabel("R*_blacklist")
        break
      else
        showInvalidObjText = false
        blacklisted_obj    = false
      end
      for _, c in ipairs(crash_objects) do
        if propName == c then
          showInvalidObjText = true
          invalidType = translateLabel("crash_object")
          break
        else
          showInvalidObjText = false
        end
      end
    end
  end
end

local function updateSelfBones()
  filteredSelfBones = {}
  for _, bone in ipairs(pedBones) do
    table.insert(filteredSelfBones, bone)
  end
end

local function displaySelfBones()
  updateSelfBones()
  local boneNames = {}
  for _, bone in ipairs(filteredSelfBones) do
    table.insert(boneNames, bone.name)
  end
  selected_bone, used = ImGui.Combo("##pedBones", selected_bone, boneNames, #filteredSelfBones)
end

local function updateVehBones()
  filteredVehBones = {}
  for _, bone in ipairs(vehBones) do
    local bone_idx = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, bone)
    if bone_idx ~= nil and bone_idx ~= -1 then
      table.insert(filteredVehBones, bone)
    end
  end
end

local function displayVehBones()
  updateVehBones()
  local boneNames = {}
  for _, bone in ipairs(filteredVehBones) do
    table.insert(boneNames, bone)
  end
  selected_bone, used = ImGui.Combo("##vehBones", selected_bone, boneNames, #filteredVehBones)
end

local function stopPreview()
  if previewStarted then
    previewStarted = false
  end
  pedPreviewModel     = 0
  vehiclePreviewModel = 0
  objectPreviewModel  = 0
  previewEntity       = 0
end

object_spawner:add_imgui(function()
  os_switch, os_switchUsed = ImGui.RadioButton(translateLabel("Custom Objects"), os_switch, 0)
  if os_switchUsed then
    UI.widgetSound("Nav")
  end
  ImGui.SameLine(); os_switch, os_switchUsed = ImGui.RadioButton(translateLabel("All Objects"), os_switch, 1)
  if os_switchUsed then
    UI.widgetSound("Nav")
  end
  if os_switch == 0 then
    ImGui.PushItemWidth(300)
    displayFilteredProps()
    ImGui.PopItemWidth()
  else
    ImGui.PushItemWidth(300)
    getAllObjects()
    ImGui.PopItemWidth()
  end
  ImGui.Spacing()
  if blacklisted_obj then
    ImGui.BeginDisabled()
    preview, _ = ImGui.Checkbox(translateLabel("Preview"), preview, true)
    ImGui.EndDisabled()
  else
    preview, previewUsed = ImGui.Checkbox(translateLabel("Preview"), preview, true)
    if previewUsed then
      UI.widgetSound("Nav2")
    end
  end
  if preview then
    spawnCoords            = ENTITY.GET_ENTITY_COORDS(previewEntity, false)
    previewLoop            = true
    currentObjectPreview   = propHash
    local previewObjectPos = ENTITY.GET_ENTITY_COORDS(previewEntity, false)
    ImGui.Text(translateLabel("Move_FB")); ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine(); ImGui.Text(translateLabel("Move_UD"))
    ImGui.Dummy(10, 1); ImGui.SameLine()
    ImGui.ArrowButton("##f2", 2)
    if ImGui.IsItemActive() then
      forwardX = forwardX * 0.1
      forwardY = forwardY * 0.1
      ENTITY.SET_ENTITY_COORDS(previewEntity, previewObjectPos.x + forwardX, previewObjectPos.y + forwardY,
        previewObjectPos.z)
    end
    ImGui.SameLine()
    ImGui.ArrowButton("##f3", 3)
    if ImGui.IsItemActive() then
      forwardX = forwardX * 0.1
      forwardY = forwardY * 0.1
      ENTITY.SET_ENTITY_COORDS(previewEntity, previewObjectPos.x - forwardX, previewObjectPos.y - forwardY,
        previewObjectPos.z)
    end
    ImGui.SameLine()
    ImGui.Dummy(60, 1); ImGui.SameLine()
    ImGui.ArrowButton("##z2", 2)
    if ImGui.IsItemActive() then
      zOffset = zOffset + 0.01
      ENTITY.SET_ENTITY_COORDS(previewEntity, previewObjectPos.x, previewObjectPos.y, previewObjectPos.z + 0.01)
    end
    ImGui.SameLine()
    ImGui.ArrowButton("##z3", 3)
    if ImGui.IsItemActive() then
      zOffset = zOffset - 0.01
      ENTITY.SET_ENTITY_COORDS(previewEntity, previewObjectPos.x, previewObjectPos.y, previewObjectPos.z - 0.01)
    end
  else
    previewStarted = false
    previewLoop    = false
    zOffset        = 0.0
    forwardX       = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
    forwardY       = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
  end
  if NETWORK.NETWORK_IS_SESSION_ACTIVE() then
    if not preview then
      ImGui.SameLine()
    end
    if blacklisted_obj then
      ImGui.BeginDisabled()
      spawnForPlayer, _ = ImGui.Checkbox(translateLabel("Spawn For a Player"), spawnForPlayer, true)
      ImGui.EndDisabled()
    else
      spawnForPlayer, spawnForPlayerUsed = ImGui.Checkbox(translateLabel("Spawn For a Player"), spawnForPlayer, true)
      if spawnForPlayerUsed then
        UI.widgetSound("Nav2")
      end
    end
  end
  if spawnForPlayer then
    ImGui.PushItemWidth(200)
    Game.displayPlayerList()
    ImGui.PopItemWidth()
    selectedPlayer = filteredPlayers[playerIndex + 1]
    coords         = ENTITY.GET_ENTITY_COORDS(selectedPlayer, false)
    heading        = ENTITY.GET_ENTITY_HEADING(selectedPlayer)
    forwardX       = ENTITY.GET_ENTITY_FORWARD_X(selectedPlayer)
    forwardY       = ENTITY.GET_ENTITY_FORWARD_Y(selectedPlayer)
    ImGui.SameLine()
  else
    coords   = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
    heading  = ENTITY.GET_ENTITY_HEADING(self.get_ped())
    forwardX = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
    forwardY = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
  end
  if blacklisted_obj then
    ImGui.BeginDisabled()
    ImGui.Button("   " .. translateLabel("Spawn") .. "  ")
    ImGui.EndDisabled()
  else
    if ImGui.Button("   " .. translateLabel("Spawn") .. "  ") then
      UI.widgetSound("Select")
      script.run_in_fiber(function()
        while not STREAMING.HAS_MODEL_LOADED(propHash) do
          STREAMING.REQUEST_MODEL(propHash)
          coroutine.yield()
        end
        if preview then
          spawnedObject = OBJECT.CREATE_OBJECT(propHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, true, true, false)
        else
          spawnedObject = OBJECT.CREATE_OBJECT(propHash, coords.x + (forwardX * 3), coords.y + (forwardY * 3), coords.z,
            true, true, false)
        end
        if ENTITY.DOES_ENTITY_EXIST(spawnedObject) then
          ENTITY.SET_ENTITY_HEADING(spawnedObject, heading)
          OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(spawnedObject)
          table.insert(spawned_props, spawnedObject)
          table.insert(spawnedNames, propName)
          local dupes = lua_Fn.getTableDupes(spawnedNames, propName)
          if dupes > 1 then
            newPropName = propName .. " #" .. tostring(dupes)
            table.insert(filteredSpawnNames, newPropName)
          else
            table.insert(filteredSpawnNames, propName)
          end
        end
      end)
    end
  end
  if showInvalidObjText then
    UI.coloredText(translateLabel("invalid_obj") .. invalidType, "#EED202", 1, 15)
  end
  if spawned_props[1] ~= nil then
    ImGui.Text(translateLabel("spawned_objects"))
    ImGui.PushItemWidth(230)
    spawned_index, used = ImGui.Combo("##Spawned Objects", spawned_index, filteredSpawnNames, #spawned_props)
    ImGui.PopItemWidth()
    selectedObject = spawned_props[spawned_index + 1]
    ImGui.SameLine()
    if ImGui.Button(translateLabel("generic_delete") .. "##objects") then
      UI.widgetSound("Delete")
      script.run_in_fiber(function(script)
        if ENTITY.DOES_ENTITY_EXIST(selectedObject) then
          ENTITY.SET_ENTITY_AS_MISSION_ENTITY(selectedObject)
          script:sleep(100)
          ENTITY.DELETE_ENTITY(selectedObject)
          table.remove(spawnedNames, spawned_index + 1)
          table.remove(filteredSpawnNames, spawned_index + 1)
          table.remove(spawned_props, spawned_index + 1)
          spawned_index = 0
          if spawned_index > 1 then
            spawned_index = spawned_index - 1
          end
          if selfAttachments[1] ~= nil or vehAttachments[1] ~= nil then
            attachPos      = { x = 0.0, y = 0.0, z = 0.0, rotX = 0.0, rotY = 0.0, rotZ = 0.0 }
            attached       = false
            attachedToSelf = false
            attachedToVeh  = false
          end
        end
      end)
    end
    ImGui.Separator()
    attachToSelf, attachToSelfUsed = ImGui.Checkbox(translateLabel("Attach To Self"), attachToSelf, true)
    if attachToSelfUsed then
      UI.widgetSound("Nav2")
    end
    if current_vehicle ~= nil and current_vehicle ~= 0 then
      ImGui.SameLine(); attachToVeh, attachToVehUsed = ImGui.Checkbox(translateLabel("Attach To Vehicle"), attachToVeh, true)
      if attachToVehUsed then
        attachToSelf = false
        UI.widgetSound("Nav2")
      end
    else
      ImGui.BeginDisabled()
      ImGui.SameLine(); attachToVeh, _ = ImGui.Checkbox(translateLabel("Attach To Vehicle"), attachToVeh, true)
      ImGui.EndDisabled()
      UI.toolTip(false, translateLabel("getinveh"))
    end
    if attachToSelf then
      attachToVeh = false
      displaySelfBones()
      boneData = filteredSelfBones[selected_bone + 1]
      ImGui.SameLine()
      if ImGui.Button(" " .. translateLabel("attachBtn") .. " " .. "##self") then
        UI.widgetSound("Select2")
        script.run_in_fiber(function()
          ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, self.get_ped(),
            PED.GET_PED_BONE_INDEX(self.get_ped(), boneData.ID), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false,
            2, true, 1)
          attached = true
          attachedObject = selectedObject
          attachedObjectName = propName
          if selfAttachments[1] ~= nil then
            for _, v in ipairs(selfAttachments) do
              if attachedObject ~= v then
                table.insert(selfAttachments, attachedObject)
                table.insert(selfAttachNames, attachedObjectName)
              end
            end
          else
            table.insert(selfAttachments, attachedObject)
            table.insert(selfAttachNames, attachedObjectName)
          end
          local attach_dupes = lua_Fn.getTableDupes(selfAttachNames, propName)
          if attach_dupes > 1 then
            attach_name = attachedObjectName .. " #" .. tostring(attach_dupes)
            table.insert(filteredAttachNames, attach_name)
          else
            table.insert(filteredAttachNames, propName)
          end
        end)
      end
      if selfAttachments[1] ~= nil then
        ImGui.Text(translateLabel("attached_objects"))
        ImGui.PushItemWidth(230)
        attached_index, used = ImGui.Combo("##Attached Objects", attached_index, filteredAttachNames, #selfAttachments)
        ImGui.PopItemWidth()
        selectedAttachment = selfAttachments[attached_index + 1]
        ImGui.SameLine()
        if ImGui.Button(translateLabel("detachBtn") .. "##self") then
          UI.widgetSound("Cancel")
          script.run_in_fiber(function()
            ENTITY.DETACH_ENTITY(selectedAttachment, true, true)
            attachPos = { x = 0.0, y = 0.0, z = 0.0, rotX = 0.0, rotY = 0.0, rotZ = 0.0 }
          end)
        end
      end
    end
    if attachToVeh then
      attachToSelf = false
      displayVehBones()
      boneData = filteredVehBones[selected_bone + 1]
      ImGui.SameLine()
      if ImGui.Button(" " .. translateLabel("attachBtn") .. " " .. "##veh") then
        UI.widgetSound("Select2")
        script.run_in_fiber(function()
          ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, current_vehicle,
            ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, boneData), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false,
            false,
            2, true, 1)
          attached = true
          attachedObject = selectedObject
          attachedObjectName = propName
          if vehAttachments[1] ~= nil then
            for _, v in ipairs(vehAttachments) do
              if attachedObject ~= v then
                table.insert(vehAttachments, attachedObject)
                table.insert(vehAttachNames, attachedObjectName)
              end
            end
          else
            table.insert(vehAttachments, attachedObject)
            table.insert(vehAttachNames, attachedObjectName)
          end
          local attach_dupes = lua_Fn.getTableDupes(vehAttachNames, propName)
          if attach_dupes > 1 then
            attach_name = attachedObjectName .. " #" .. tostring(attach_dupes)
            table.insert(filteredVehAttachNames, attach_name)
          else
            table.insert(filteredVehAttachNames, propName)
          end
        end)
      end
      if vehAttachments[1] ~= nil then
        ImGui.Text(translateLabel("attached_objects"))
        ImGui.PushItemWidth(230)
        attached_index, used = ImGui.Combo("##vehAttachedObjects", attached_index, filteredVehAttachNames,
          #vehAttachments)
        ImGui.PopItemWidth()
        selectedAttachment = vehAttachments[attached_index + 1]
        ImGui.SameLine()
        if ImGui.Button(translateLabel("detachBtn") .. "##veh") then
          UI.widgetSound("Cancel")
          script.run_in_fiber(function()
            ENTITY.DETACH_ENTITY(selectedAttachment, true, true)
            attachPos = { x = 0.0, y = 0.0, z = 0.0, rotX = 0.0, rotY = 0.0, rotZ = 0.0 }
          end)
        end
      end
    end
    ImGui.Separator()
    edit_mode, edit_modeUsed = ImGui.Checkbox(translateLabel("editMode"), edit_mode, true)
    if edit_modeUsed then
      UI.widgetSound("Nav2")
    end
    UI.helpMarker(false, translateLabel("editMode_tt"))
    if edit_mode and not attached then
      ImGui.Text(translateLabel("xyz_multiplier"))
      ImGui.PushItemWidth(280)
      axisMult, _ = ImGui.InputInt("##multiplier", axisMult, 1, 2, 0)
      ImGui.Text(translateLabel("Move Object:"))
      ImGui.Text("                        X Axis :")
      spawnDistance.x, _ = ImGui.SliderFloat(" ", spawnDistance.x, -0.1 * axisMult, 0.1 * axisMult)
      activeX = ImGui.IsItemActive()
      ImGui.Separator()
      ImGui.Text("                        Y Axis :")
      spawnDistance.y, _ = ImGui.SliderFloat("  ", spawnDistance.y, -0.1 * axisMult, 0.1 * axisMult)
      activeY = ImGui.IsItemActive()
      ImGui.Separator()
      ImGui.Text("                        Z Axis :")
      spawnDistance.z, _ = ImGui.SliderFloat("   ", spawnDistance.z, -0.05 * axisMult, 0.05 * axisMult)
      activeZ = ImGui.IsItemActive()
      ImGui.Separator(); ImGui.Text(translateLabel("Rotate Object:"))
      ImGui.Text("                        X Axis :")
      spawnRot.x, _ = ImGui.SliderFloat("##xRot", spawnRot.x, -0.1 * axisMult, 0.1 * axisMult)
      rotX = ImGui.IsItemActive()
      ImGui.Separator()
      ImGui.Text("                        Y Axis :")
      spawnRot.y, _ = ImGui.SliderFloat("##yRot", spawnRot.y, -0.1 * axisMult, 0.1 * axisMult)
      rotY = ImGui.IsItemActive()
      ImGui.Separator()
      ImGui.Text("                        Z Axis :")
      spawnRot.z, _ = ImGui.SliderFloat("##zRot", spawnRot.z, -0.5 * axisMult, 0.5 * axisMult)
      rotZ = ImGui.IsItemActive()
      ImGui.PopItemWidth()
    else
      if edit_mode and selfAttachments[1] ~= nil or edit_mode and vehAttachments[1] ~= nil then
        ImGui.Text(translateLabel("Move Object:") .. "##attached"); ImGui.Separator(); ImGui.Spacing()
        if attachToSelf then
          target     = self.get_ped()
          attachBone = PED.GET_PED_BONE_INDEX(self.get_ped(), boneData.ID)
        elseif attachToVeh then
          target     = current_vehicle
          attachBone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, boneData)
        end
        ImGui.Text(translateLabel("xyz_multiplier"))
        ImGui.PushItemWidth(271)
        axisMult, _ = ImGui.InputInt("##AttachMultiplier", axisMult, 1, 2, 0)
        ImGui.PopItemWidth()
        ImGui.Spacing()
        ImGui.Text("X Axis :"); ImGui.SameLine(); ImGui.Dummy(25, 1); ImGui.SameLine(); ImGui.Text("Y Axis :"); ImGui
            .SameLine()
        ImGui.Dummy(25, 1); ImGui.SameLine(); ImGui.Text("Z Axis :")
        ImGui.ArrowButton("##Xleft", 0)
        if ImGui.IsItemActive() then
          attachPos.x = attachPos.x + 0.001 * axisMult
          ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, target, attachBone, attachPos.x,
            attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true,
            1)
        end
        ImGui.SameLine()
        ImGui.ArrowButton("##XRight", 1)
        if ImGui.IsItemActive() then
          attachPos.x = attachPos.x - 0.001 * axisMult
          ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, target, attachBone, attachPos.x,
            attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true,
            1)
        end
        ImGui.SameLine()
        ImGui.Dummy(5, 1); ImGui.SameLine()
        ImGui.ArrowButton("##Yleft", 0)
        if ImGui.IsItemActive() then
          attachPos.y = attachPos.y + 0.001 * axisMult
          ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, target, attachBone, attachPos.x,
            attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true,
            1)
        end
        ImGui.SameLine()
        ImGui.ArrowButton("##YRight", 1)
        if ImGui.IsItemActive() then
          attachPos.y = attachPos.y - 0.001 * axisMult
          ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, target, attachBone, attachPos.x,
            attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true,
            1)
        end
        ImGui.SameLine()
        ImGui.Dummy(5, 1); ImGui.SameLine()
        ImGui.ArrowButton("##zUp", 2)
        if ImGui.IsItemActive() then
          attachPos.z = attachPos.z + 0.001 * axisMult
          ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, target, attachBone, attachPos.x,
            attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true,
            1)
        end
        ImGui.SameLine()
        ImGui.ArrowButton("##zDown", 3)
        if ImGui.IsItemActive() then
          attachPos.z = attachPos.z - 0.001 * axisMult
          ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, target, attachBone, attachPos.x,
            attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true,
            1)
        end
        ImGui.Text("X Rotation :"); ImGui.SameLine(); ImGui.Text("Y Rotation :"); ImGui.SameLine(); ImGui.Text(
          "Z Rotation :")
        ImGui.ArrowButton("##rotXleft", 0)
        if ImGui.IsItemActive() then
          attachPos.rotX = attachPos.rotX + 1 * axisMult
          ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, target, attachBone, attachPos.x,
            attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true,
            1)
        end
        ImGui.SameLine()
        ImGui.ArrowButton("##rotXright", 1)
        if ImGui.IsItemActive() then
          attachPos.rotX = attachPos.rotX - 1 * axisMult
          ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, target, attachBone, attachPos.x,
            attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true,
            1)
        end
        ImGui.SameLine()
        ImGui.Dummy(5, 1); ImGui.SameLine()
        ImGui.ArrowButton("##rotYleft", 0)
        if ImGui.IsItemActive() then
          attachPos.rotY = attachPos.rotY + 1 * axisMult
          ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, target, attachBone, attachPos.x,
            attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true,
            1)
        end
        ImGui.SameLine()
        ImGui.ArrowButton("##rotYright", 1)
        if ImGui.IsItemActive() then
          attachPos.rotY = attachPos.rotY - 1 * axisMult
          ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, target, attachBone, attachPos.x,
            attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true,
            1)
        end
        ImGui.SameLine()
        ImGui.Dummy(5, 1); ImGui.SameLine()
        ImGui.ArrowButton("##rotZup", 2)
        if ImGui.IsItemActive() then
          attachPos.rotZ = attachPos.rotZ + 1 * axisMult
          ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, target, attachBone, attachPos.x,
            attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true,
            1)
        end
        ImGui.SameLine()
        ImGui.ArrowButton("##rotZdown", 3)
        if ImGui.IsItemActive() then
          attachPos.rotZ = attachPos.rotZ - 1 * axisMult
          ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, target, attachBone, attachPos.x,
            attachPos.y, attachPos.z, attachPos.rotX, attachPos.rotY, attachPos.rotZ, false, false, false, false, 2, true,
            1)
        end
      end
    end
    if ImGui.Button("   " .. translateLabel("generic_reset") .. "   ") then
      UI.widgetSound("Select")
      resetSliders()
      if attached then
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedObject, target, attachBone, 0.0, 0.0, 0.0,
          0.0, 0.0, 0.0, false, false, false, false, 2, true, 1)
      else
        ENTITY.SET_ENTITY_COORDS(selectedObject, coords.x + (forwardX * 3), coords.y + (forwardY * 3), coords.z)
        ENTITY.SET_ENTITY_HEADING(selectedObject, heading)
        OBJECT.PLACE_OBJECT_ON_GROUND_OR_OBJECT_PROPERLY(selectedObject)
      end
    end
    UI.helpMarker(false, translateLabel("resetSlider_tt"))
  end
end)
--[[
    *settings*
]]
local settings_tab = Samurais_scripts:add_tab(translateLabel("settingsTab"))
lang_idx           = lua_cfg.read("lang_idx")
disableTooltips    = lua_cfg.read("disableTooltips")
disableUiSounds    = lua_cfg.read("disableUiSounds")
useGameLang        = lua_cfg.read("useGameLang")
local selected_lang
local lang_T       = {
  { name = 'English',               iso = 'en-US' },
  { name = 'Français',              iso = 'fr-FR' },
  { name = 'Deutsch',               iso = 'de-DE' },
  { name = 'Italiano',              iso = 'it-IT' },
  -- { name = 'Chinese (Traditional)', iso = 'zh-TW' },
  -- { name = 'Chinese (Simplified)',  iso = 'zh-CH' },
  -- { name = 'Español',               iso = 'es-ES' },
  { name = 'Português (Brasil)',    iso = 'pt-BR' },
  { name = 'Русский (Russian)',     iso = 'ru-RU' },
}

function displayLangs()
  filteredLangs = {}
  for _, lang in ipairs(lang_T) do
    table.insert(filteredLangs, lang.name)
  end
  lang_idx, lang_idxUsed = ImGui.Combo("##langs", lang_idx, filteredLangs, #lang_T)
end

settings_tab:add_imgui(function()
  disableTooltips, dtUsed = ImGui.Checkbox(translateLabel("Disable Tooltips"), disableTooltips, true)
  if dtUsed then
    lua_cfg.save("disableTooltips", disableTooltips)
    UI.widgetSound("Nav2")
  end

  disableUiSounds, duisndUsed = ImGui.Checkbox(translateLabel("DisableSound"), disableUiSounds, true)
  UI.toolTip(false, translateLabel("DisableSound_tt"))
  if duisndUsed then
    lua_cfg.save("disableUiSounds", disableUiSounds)
    UI.widgetSound("Nav2")
  end

  if shortcut_anim.anim ~= nil then
    if ImGui.Button(translateLabel("removeShortcut_btn2")) then
      UI.widgetSound("Delete")
      shortcut_anim = {}
      lua_cfg.save("shortcut_anim", {})
      gui.show_success("Samurais Scripts", "Animation shortcut has been successfully reset.")
    end
  else
    ImGui.BeginDisabled()
    ImGui.Button(translateLabel("removeShortcut_btn2"))
    ImGui.EndDisabled()
    UI.toolTip(false, translateLabel("no_shortcut_tt"))
  end

  ImGui.Dummy(1, 10); ImGui.Text(translateLabel("langTitle") .. " " .. current_lang)
  useGameLang, uglUsed = ImGui.Checkbox(translateLabel("gameLangCB"), useGameLang, true)
  if useGameLang then
    UI.toolTip(false, translateLabel("gameLang_tt"))
  end
  if useGameLang then
    LANG, current_lang = Game.GetLang()
  end
  if uglUsed then
    UI.widgetSound("Nav2")
    gui.show_success("Samurai's Scripts", translateLabel("lang_success_msg"))
    lua_cfg.save("useGameLang", useGameLang)
    lua_cfg.save("LANG", LANG)
    lua_cfg.save("lang_idx", 0)
  end

  if not useGameLang then
    ImGui.Text(translateLabel("customLangTxt"))
    ImGui.PushItemWidth(180)
    displayLangs()
    ImGui.PopItemWidth()
    selected_lang = lang_T[lang_idx + 1]
    ImGui.SameLine()
    if ImGui.Button(translateLabel("saveBtn") .. "##lang") then
      UI.widgetSound("Select")
      LANG         = selected_lang.iso
      current_lang = selected_lang.name
      lua_cfg.save("lang_idx", lang_idx)
      lua_cfg.save("LANG", LANG)
      lua_cfg.save("current_lang", current_lang)
      gui.show_success("Samurai's Scripts", translateLabel("lang_success_msg"))
    end
  end

  ImGui.Dummy(10, 1)
  if UI.coloredButton(translateLabel("reset_settings_Btn"), "#FF0000", "#EE4B2B", "#880808", 1) then
    UI.widgetSound("Focus_In")
    ImGui.OpenPopup("Confirm")
  end
  ImGui.SetNextWindowPos(760, 400, ImGuiCond.Appearing)
  ImGui.SetNextWindowBgAlpha(0.6)
  if ImGui.BeginPopupModal("Confirm", ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
    UI.coloredText(translateLabel("confirm_txt"), "yellow", 1, 20)
    if ImGui.Button("  " .. translateLabel("yes") .. "  ") then
      UI.widgetSound("Select2")
      lua_cfg.reset(default_config)
      shortcut_anim           = {}
      Regen                   = false
      -- objectiveTP             = false
      disableTooltips         = false
      phoneAnim               = false
      sprintInside            = false
      lockpick                = false
      replaceSneakAnim        = false
      replacePointAct         = false
      disableSound            = false
      disableActionMode       = false
      rod                     = false
      clumsy                  = false
      -- Triggerbot              = false
      aimEnemy                = false
      autoKill                = false
      runaway                 = false
      laserSight              = false
      disableUiSounds         = false
      driftMode               = false
      DriftTires              = false
      DriftSmoke              = false
      driftMinigame           = false
      speedBoost              = false
      nosvfx                  = false
      hornLight               = false
      nosPurge                = false
      insta180                = false
      flappyDoors             = false
      rgbLights               = false
      loud_radio              = false
      launchCtrl              = false
      popsNbangs              = false
      limitVehOptions         = false
      missiledefense          = false
      louderPops              = false
      autobrklight            = false
      holdF                   = false
      keepWheelsTurned        = false
      noJacking               = false
      useGameLang             = false
      disableProps            = false
      manualFlags             = false
      controllable            = false
      looped                  = false
      upperbody               = false
      freeze                  = false
      usePlayKey              = false
      npc_godMode             = false
      bypass_casino_bans      = false
      force_poker_cards       = false
      set_dealers_poker_cards = false
      force_roulette_wheel    = false
      rig_slot_machine        = false
      autoplay_slots          = false
      autoplay_cap            = false
      heist_cart_autograb     = false
      flares_forall           = false
      real_plane_speed        = false
      laser_switch            = 0
      DriftIntensity          = 0
      lang_idx                = 0
      autoplay_chips_cap      = 0
      lightSpeed              = 1
      DriftPowerIncrease      = 1
      nosPower                = 10
      laser_choice            = "proj_laser_enemy"
      LANG                    = "en-US"
      current_lang            = "English"
      ImGui.CloseCurrentPopup()
    end
    ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
    if ImGui.Button("  " .. translateLabel("no") .. "  ") then
      UI.widgetSound("Cancel")
      ImGui.CloseCurrentPopup()
    end
    ImGui.EndPopup()
  end
end)


local function SS_handle_events()
  if attached_ped ~= nil and attached_ped ~= 0 then
    ENTITY.DETACH_ENTITY(attached_ped, true, true)
    ENTITY.FREEZE_ENTITY_POSITION(attached_ped, false)
    TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(attached_ped, false)
    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(attached_ped, false)
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
  end

  if grabbed_veh ~= nil and grabbed_veh ~= 0 then
    ENTITY.DETACH_ENTITY(grabbed_veh, true, true)
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
  end

  if attached_vehicle ~= nil and attached_vehicle ~= 0 then
    local modelHash         = ENTITY.GET_ENTITY_MODEL(attached_vehicle)
    local attachedVehicle   = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(PED.GET_VEHICLE_PED_IS_USING(self.get_ped()),
      modelHash)
    local attachedVehcoords = ENTITY.GET_ENTITY_COORDS(attached_vehicle, false)
    local playerForwardX    = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
    local playerForwardY    = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
    controlled              = entities.take_control_of(attachedVehicle, 300)
    if ENTITY.DOES_ENTITY_EXIST(attachedVehicle) then
      if controlled then
        ENTITY.DETACH_ENTITY(attachedVehicle, true, true)
        ENTITY.SET_ENTITY_COORDS(attachedVehicle, attachedVehcoords.x - (playerForwardX * 10),
          attachedVehcoords.y - (playerForwardY * 10), playerPosition.z, false, false, false, false)
        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(attached_vehicle, 5.0)
        attached_vehicle = 0
      end
    end
  end

  if spawned_props[1] ~= nil then
    for _, p in ipairs(spawned_props) do
      if ENTITY.DOES_ENTITY_EXIST(p) then
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(p)
        ENTITY.DELETE_ENTITY(p)
      end
    end
  end

  if selfAttachments[1] ~= nil then
    for _, v in ipairs(selfAttachments) do
      ENTITY.DETACH_ENTITY(v, true, true)
    end
  end

  if vehAttachments[1] ~= nil then
    for _, v in ipairs(vehAttachments) do
      ENTITY.DETACH_ENTITY(v, true, true)
    end
  end

  if currentMvmt ~= "" then
    PED.RESET_PED_MOVEMENT_CLIPSET(self.get_ped(), 0.0)
  end

  if currentWmvmt ~= "" then
   PED.RESET_PED_WEAPON_MOVEMENT_CLIPSET(self.get_ped())
  end

  if currentStrf ~= "" then
   PED.RESET_PED_STRAFE_CLIPSET(self.get_ped())
  end

  if clumsy then
    PED.SET_PED_RAGDOLL_ON_COLLISION(self.get_ped(), false)
  end
  WEAPON.SET_WEAPON_ANIMATION_OVERRIDE(self.get_ped(), 3839837909)

  if is_playing_anim then
    if anim_music then
      if ENTITY.DOES_ENTITY_EXIST(pBus) then
        ENTITY.DELETE_ENTITY(pBus)
      end
      if ENTITY.DOES_ENTITY_EXIST(dummyDriver) then
        ENTITY.DELETE_ENTITY(dummyDriver)
      end
    end
    TASK.CLEAR_PED_TASKS(self.get_ped())
    if selfPTFX[1] ~= nil then
      for _, v in ipairs(selfPTFX) do
        GRAPHICS.STOP_PARTICLE_FX_LOOPED(v)
      end
    end
    local current_coords = self.get_pos()
    if PED.IS_PED_IN_ANY_VEHICLE(self.get_ped(), false) then
      local veh    = PED.GET_VEHICLE_PED_IS_USING(self.get_ped())
      local mySeat = Game.getPedVehicleSeat(self.get_ped())
      PED.SET_PED_INTO_VEHICLE(self.get_ped(), veh, mySeat)
    else
      ENTITY.SET_ENTITY_COORDS_NO_OFFSET(self.get_ped(), current_coords.x, current_coords.y, current_coords.z, true, false, false)
    end
    if plyrProps[1] ~= nil then
      for _, v in ipairs(plyrProps) do
        if ENTITY.DOES_ENTITY_EXIST(v) then
          ENTITY.SET_ENTITY_AS_MISSION_ENTITY(v)
          ENTITY.DELETE_ENTITY(v)
        end
      end
    end
  end

  if spawned_npcs[1] ~= nil then
    for _, v in ipairs(spawned_npcs) do
      if ENTITY.DOES_ENTITY_EXIST(v) then
        ENTITY.DELETE_ENTITY(v)
      end
    end
  end

  if is_playing_scenario then
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
    if ENTITY.DOES_ENTITY_EXIST(bbq) then
      ENTITY.DELETE_ENTITY(bbq)
    end
  end

  if is_playing_radio then
    if ENTITY.DOES_ENTITY_EXIST(pBus) then
      ENTITY.SET_ENTITY_AS_MISSION_ENTITY(pBus)
      ENTITY.DELETE_ENTITY(pBus)
    end
    if ENTITY.DOES_ENTITY_EXIST(dummyDriver) then
      ENTITY.DELETE_ENTITY(dummyDriver)
    end
  end

  if is_handsUp then
    TASK.CLEAR_PED_TASKS(self.get_ped())
  end

  if isCrouched then
    PED.RESET_PED_MOVEMENT_CLIPSET(self.get_ped(), 0)
  end
end

-- local function var_reset()
--   resetOnSave()
--   isCrouched = false; is_handsUp = false; anim_music = false; is_playing_radio = false; npc_blips = {}; spawned_npcs = {}; plyrProps = {}; npcProps = {}; selfPTFX = {}; npcPTFX = {}; curr_playing_anim = {}; is_playing_anim = false; is_playing_scenario = false; tab1Sound = true; tab2Sound = true; tab3Sound = true; actions_switch = 0; actions_search =
--   ""; currentMvmt = ""; currentStrf = ""; currentWmvmt = ""; aimBool = false; HashGrabber = false; drew_laser = false; Entity = 0; laserPtfx_T = {}; sound_btn_off = false; tire_smoke = false; purge_started = false; nos_started = false; twostep_started = false; open_sounds_window = false; started_lct = false; launch_active = false; started_popSound = false; started_popSound2 = false; timerA = 0; timerB = 0; lastVeh = 0; defaultXenon = 0; start_rgb_loop = false; vehSound_index = 0; smokePtfx_t = {}; nosptfx_t = {}; purgePtfx_t = {}; lctPtfx_t = {}; popSounds_t = {}; popsPtfx_t = {}; attached_vehicle = 0; tow_xAxis = 0.0; tow_yAxis = 0.0; tow_zAxis = 0.0; pedGrabber = false; ped_grabbed = false;; vehicleGrabber = false; vehicle_grabbed = false; carpool = false; show_npc_veh_ctrls = false; stop_searching = false; hijack_started = false; grp_anim_index = 0; attached_ped = 0; grabbed_veh = 0; thisVeh = 0; pedthrowF = 10; propName =
--   ""; invalidType = ""; preview = false; is_drifting = false; previewLoop = false; activeX = false; activeY = false; activeZ = false; rotX = false; rotY = false; rotZ = false; attached = false; attachToSelf = false; attachToVeh = false; previewStarted = false; isChanged = false; prop = 0; propHash = 0; os_switch = 0; prop_index = 0; objects_index = 0; spawned_index = 0; selectedObject = 0; selected_bone = 0; previewEntity = 0; currentObjectPreview = 0; attached_index = 0; zOffset = 0; spawned_props = {}; spawnedNames = {}; filteredSpawnNames = {}; selfAttachments = {}; selfAttachNames = {}; vehAttachments = {}; vehAttachNames = {}; filteredVehAttachNames = {}; filteredAttachNames = {}; missiledefense = false;
-- end




--[[
    *Threads*
]]

script.register_looped("basic ass loading text", function(balt)
  balt:yield()
  if start_loading_anim then
    loading_label = "-   "
    balt:sleep(80)
    loading_label = "--  "
    balt:sleep(80)
    loading_label = "--- "
    balt:sleep(80)
    loading_label = "----"
    balt:sleep(80)
    loading_label = " ---"
    balt:sleep(80)
    loading_label = "  --"
    balt:sleep(80)
    loading_label = "   -"
    balt:sleep(80)
    loading_label = "    "
    balt:sleep(80)
    return
  end
end)

script.register_looped("Quote Of The Day", function(qotd)
  qotd:yield()
  if gui.is_open() and Samurais_scripts:is_selected()  then
    random_quote = random_quotes_T[math.random(1, #random_quotes_T)]
    qotd:sleep(15000)
  end
end)
script.register_looped("QBE", function(qbe)
  qbe:yield()
  if gui.is_open() and Samurais_scripts:is_selected() and random_quote ~= "" then
    if quote_alpha > 0.1 then
      while quote_alpha > 0.1 do
        quote_alpha = quote_alpha - 0.05
        qbe:sleep(100)
      end
    else
      while quote_alpha < 1.0 do
        quote_alpha = quote_alpha + 0.05
        qbe:sleep(100)
      end
    end
  end
end)

-- Game Input
script.register_looped("GameInput", function()
  if is_typing then
    PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
  end

  if PAD.IS_USING_KEYBOARD_AND_MOUSE() then
    stopButton = "[G]"
  else
    stopButton = "[DPAD LEFT]"
  end

  if shortcut_anim.btn ~= nil then
    if gui.is_open() then
      PAD.DISABLE_CONTROL_ACTION(0, shortcut_anim.btn)
    end
  end

  if HashGrabber and WEAPON.IS_PED_ARMED(self.get_ped(), 4) then
    PAD.DISABLE_CONTROL_ACTION(0, 24, 1)
    PAD.DISABLE_CONTROL_ACTION(0, 257, 1)
  end

  if replaceSneakAnim and Game.Self.isOnFoot() then
    PAD.DISABLE_CONTROL_ACTION(0, 36, 1)
  end

  if replacePointAct or is_playing_anim or is_playing_scenario or ped_grabbed then
    PAD.DISABLE_CONTROL_ACTION(0, 29, 1)
  end

  if PED.IS_PED_SITTING_IN_ANY_VEHICLE(self.get_ped()) then
    if validModel then
      if nosPurge or is_in_flatbed then
        PAD.DISABLE_CONTROL_ACTION(0, 73, true)
      end
    end
    if speedBoost and PAD.IS_CONTROL_PRESSED(0, 71) and PAD.IS_CONTROL_PRESSED(0, tdBtn) then
      if validModel or is_boat or is_bike then
        -- prevent face planting when using NOS mid-air
        PAD.DISABLE_CONTROL_ACTION(0, 60, true)
        PAD.DISABLE_CONTROL_ACTION(0, 61, true)
        PAD.DISABLE_CONTROL_ACTION(0, 62, true)
      end
    end
    if holdF then
      if Game.Self.isDriving() and not is_typing and VEHICLE.IS_VEHICLE_STOPPED(self.get_veh()) then
        PAD.DISABLE_CONTROL_ACTION(0, 75, true)
      else
        timerB = 0
      end
    end
    if keepWheelsTurned then
      if Game.Self.isDriving() and not is_typing and VEHICLE.IS_VEHICLE_STOPPED(self.get_veh()) and (is_car or is_quad) then
        if PAD.IS_CONTROL_PRESSED(0, 34) or PAD.IS_CONTROL_PRESSED(0, 35) then
          PAD.DISABLE_CONTROL_ACTION(0, 75, true)
        end
      end
    end
  end

  if (pedGrabber or vehicleGrabber) and Game.Self.isOnFoot() and not WEAPON.IS_PED_ARMED(self.get_ped(), 7) then
    PAD.DISABLE_CONTROL_ACTION(0, 24, 1)
    PAD.DISABLE_CONTROL_ACTION(0, 25, 1)
    PAD.DISABLE_CONTROL_ACTION(0, 50, 1)
    PAD.DISABLE_CONTROL_ACTION(0, 68, 1)
    PAD.DISABLE_CONTROL_ACTION(0, 91, 1)
    PAD.DISABLE_CONTROL_ACTION(0, 257, 1)
  end
  if ped_grabbed or vehicle_grabbed then
    PAD.DISABLE_CONTROL_ACTION(0, 24, 1)
    PAD.DISABLE_CONTROL_ACTION(0, 25, 1)
    PAD.DISABLE_CONTROL_ACTION(0, 50, 1)
    PAD.DISABLE_CONTROL_ACTION(0, 68, 1)
    PAD.DISABLE_CONTROL_ACTION(0, 91, 1)
    PAD.DISABLE_CONTROL_ACTION(0, 257, 1)
  end
end)

-- self stuff
script.register_looped("auto-heal", function(ah)
  ah:yield()
  if Regen and Game.Self.isAlive() then
    local maxHp  = Game.Self.maxHealth()
    local myHp   = Game.Self.health()
    local myArmr = Game.Self.armour()
    if myHp < maxHp and myHp > 0 then
      if PED.IS_PED_IN_COVER(self.get_ped()) then
        ENTITY.SET_ENTITY_HEALTH(self.get_ped(), myHp + 10, 0, 0)
      else
        ENTITY.SET_ENTITY_HEALTH(self.get_ped(), myHp + 1, 0, 0)
      end
    end
    if myArmr == nil then
      PED.SET_PED_ARMOUR(self.get_ped(), 10)
    end
    if myArmr ~= nil and myArmr < 50 then
      PED.ADD_ARMOUR_TO_PED(self.get_ped(), 0.5)
    end
  end
end)
-- script.register_looped("objectiveTP", function()
--   if objectiveTP then
--     if PAD.IS_CONTROL_JUST_PRESSED(0, 57) then
--       for _, n in pairs(objectives_T) do
--         local blip = HUD.GET_CLOSEST_BLIP_INFO_ID(n)
--         if HUD.DOES_BLIP_EXIST(blip) then
--           blipCoords = HUD.GET_BLIP_COORDS(blip)
--           break
--         end
--       end
--       if blipCoords ~= nil then
--         Game.Self.teleport(true, blipCoords)
--       else
--         gui.show_warning("Objective Teleport", "No objective found!")
--       end
--     end
--   end
-- end)
script.register_looped("self features", function(script)
  -- Crouch instead of sneak
  if Game.Self.isOnFoot() and not Game.Self.isInWater() and not Game.Self.is_ragdoll() and not gui.is_open() then
    if replaceSneakAnim and not ped_grabbed and not is_playing_anim and not is_playing_scenario and not is_typing then
      if not isCrouched and PAD.IS_DISABLED_CONTROL_PRESSED(0, 36) then
        script:sleep(200)
        if is_handsUp then
          is_handsUp = false
          TASK.CLEAR_PED_TASKS(self.get_ped())
        end
        while not STREAMING.HAS_CLIP_SET_LOADED("move_ped_crouched") and not STREAMING.HAS_CLIP_SET_LOADED("move_aim_strafe_crouch_2h") do
          STREAMING.REQUEST_CLIP_SET("move_ped_crouched")
          STREAMING.REQUEST_CLIP_SET("move_aim_strafe_crouch_2h")
          coroutine.yield()
        end
        PED.SET_PED_MOVEMENT_CLIPSET(self.get_ped(), "move_ped_crouched", 0.3)
        PED.SET_PED_STRAFE_CLIPSET(self.get_ped(), "move_aim_strafe_crouch_2h")
        script:sleep(500)
        isCrouched = true
      end
    end
    if isCrouched and PAD.IS_DISABLED_CONTROL_PRESSED(0, 36) then
      script:sleep(200)
      PED.RESET_PED_MOVEMENT_CLIPSET(self.get_ped(), 0.3)
      script:sleep(500)
      isCrouched = false
    end
  end

  -- Replace 'Point At' Action
  if not gui.is_open() then
    if Game.Self.isOnFoot() or is_car then
      if replacePointAct and not ped_grabbed and not is_playing_anim and not is_playing_scenario and not is_typing then
        if not is_handsUp and PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 29) then
          script:sleep(200)
          if isCrouched then
            isCrouched = false
            PED.RESET_PED_MOVEMENT_CLIPSET(self.get_ped(), 0)
          end
          playHandsUp()
          is_handsUp = true
        end
      end
    end

    if is_handsUp and PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 29) then
      script:sleep(200)
      TASK.CLEAR_PED_TASKS(self.get_ped())
      script:sleep(500)
      is_handsUp = false
    end
  end
  if is_handsUp then
    if WEAPON.IS_PED_ARMED(self.get_ped(), 7) then
      if PAD.IS_CONTROL_PRESSED(0, 24) then
        TASK.CLEAR_PED_TASKS(self.get_ped())
        is_handsUp = false
      end
    end
    if PLAYER.IS_PLAYER_FREE_AIMING(self.get_id()) then
      TASK.CLEAR_PED_TASKS(self.get_ped())
      is_handsUp = false
    end
    if not Game.Self.isOnFoot() then
      if PED.IS_PED_SITTING_IN_ANY_VEHICLE(self.get_ped()) and not is_car then
        TASK.CLEAR_PED_TASKS(self.get_ped())
        is_handsUp = false
      end
    end
  end

  -- Online Phone Animations
  if NETWORK.NETWORK_IS_SESSION_ACTIVE() then
    if phoneAnim and not ENTITY.IS_ENTITY_DEAD(self.get_ped()) then
      if not is_playing_anim and not is_playing_scenario and not ped_grabbed and not is_handsUp and PED.COUNT_PEDS_IN_COMBAT_WITH_TARGET(self.get_ped()) == 0 then
        if PED.GET_PED_CONFIG_FLAG(self.get_ped(), 242, 1) then
          PED.SET_PED_CONFIG_FLAG(self.get_ped(), 242, false)
        end
        if PED.GET_PED_CONFIG_FLAG(self.get_ped(), 243, 1) then
          PED.SET_PED_CONFIG_FLAG(self.get_ped(), 243, false)
        end
        if PED.GET_PED_CONFIG_FLAG(self.get_ped(), 244, 1) then
          PED.SET_PED_CONFIG_FLAG(self.get_ped(), 244, false)
        end
        if not PED.GET_PED_CONFIG_FLAG(self.get_ped(), 243, 1) and AUDIO.IS_MOBILE_PHONE_CALL_ONGOING() then
          if not STREAMING.HAS_ANIM_DICT_LOADED("anim@scripted@freemode@ig19_mobile_phone@male@") then
            STREAMING.REQUEST_ANIM_DICT("anim@scripted@freemode@ig19_mobile_phone@male@")
            return
          end
          TASK.TASK_PLAY_PHONE_GESTURE_ANIMATION(self.get_ped(), "anim@scripted@freemode@ig19_mobile_phone@male@", "base",
            "BONEMASK_HEAD_NECK_AND_R_ARM", 0.25, 0.25, true, false)
          repeat
            script:sleep(10)
          until
            AUDIO.IS_MOBILE_PHONE_CALL_ONGOING() == false
          TASK.TASK_STOP_PHONE_GESTURE_ANIMATION(self.get_ped(), 0.25)
        end
      else
        PED.SET_PED_CONFIG_FLAG(self.get_ped(), 242, true)
        PED.SET_PED_CONFIG_FLAG(self.get_ped(), 243, true)
        PED.SET_PED_CONFIG_FLAG(self.get_ped(), 244, true)
      end
    else
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 242, true)
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 243, true)
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 244, true)
    end
  else
    if PED.GET_PED_CONFIG_FLAG(self.get_ped(), 242, 1) and PED.GET_PED_CONFIG_FLAG(self.get_ped(), 243, 1) and PED.GET_PED_CONFIG_FLAG(self.get_ped(), 244, 1) then
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 242, false)
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 243, false)
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 244, false)
    end
  end

  -- Sprint Inside
  if sprintInside then
    if PED.GET_PED_CONFIG_FLAG(self.get_ped(), 427, 1) == false then
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 427, true)
    end
  else
    if PED.GET_PED_CONFIG_FLAG(self.get_ped(), 427, 1) then
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 427, false)
    end
  end

  -- Lockpick animation
  if lockPick then
    if PED.GET_PED_CONFIG_FLAG(self.get_ped(), 426, 1) == false then
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 426, true)
    end
  else
    if PED.GET_PED_CONFIG_FLAG(self.get_ped(), 426, 1) then
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 426, false)
    end
  end
end)
script.register_looped("Ragdoll Loop", function(rgdl)
  rgdl:yield()
  if clumsy then
    if PED.IS_PED_RAGDOLL(self.get_ped()) then
      rgdl:sleep(2500)
      return
    end
    PED.SET_PED_RAGDOLL_ON_COLLISION(self.get_ped(), true)
    if isCrouched then
      isCrouched = false
    end
    if is_handsUp then
      is_handsUp = false
    end
  elseif rod then
    if PED.CAN_PED_RAGDOLL(self.get_ped()) then
      if PAD.IS_CONTROL_PRESSED(0, 252) and Game.getEntityModel(self.get_veh()) ~= 884483972 and Game.getEntityModel(self.get_veh()) ~= 2069146067 then
        PED.SET_PED_TO_RAGDOLL(self.get_ped(), 1500, 0, 0, false)
        if isCrouched then
          isCrouched = false
        end
        if is_handsUp then
          is_handsUp = false
        end
      end
    else
      if Game.Self.isOnFoot() and PAD.IS_CONTROL_JUST_PRESSED(0, 252) then
        gui.show_error("Samurais Scripts", "Unable to ragdoll you.\nPlease make sure 'No Ragdoll' option\nis disabled in YimMenu.")
      rgdl:sleep(200)
      end
    end
  end
  if PED.IS_PED_RAGDOLL(self.get_ped()) then
    if NETWORK.NETWORK_IS_SESSION_ACTIVE() then
      if PED.IS_PED_MALE(self.get_ped()) then
        soundName = "WAVELOAD_PAIN_MALE"
      else
        soundName = "WAVELOAD_PAIN_FEMALE"
      end
      rgdl:sleep(500)
      local myPos = ENTITY.GET_ENTITY_COORDS(self.get_ped(), true)
      AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE("SCREAM_PANIC_SHORT", soundName, myPos.x, myPos.y, myPos.z,
        "SPEECH_PARAMS_FORCE_SHOUTED", 0)
      repeat
        rgdl:sleep(100)
      until
        PED.IS_PED_RAGDOLL(self.get_ped()) == false
    end
  end
end)
script.register_looped("Sound Effects", function(animSfx)
  animSfx:yield()
  if not is_shortcut_anim then
    if is_playing_anim then
      local info = filteredAnims[anim_index + 1]
      if info.sfx ~= nil then
        local soundCoords = self.get_pos()
        AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(info.sfx, info.sfxName, soundCoords.x, soundCoords.y, soundCoords.z, info.sfxFlg, 0)
        animSfx:sleep(10000)
      end
    end
  end
  if is_shortcut_anim then
    if shortcut_anim.sfx ~= nil then
      local soundCoords = self.get_pos()
      AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(info.sfx, info.sfxName, soundCoords.x, soundCoords.y, soundCoords.z, info.sfxFlg, 0)
      animSfx:sleep(10000)
    end
  end
end)
-- Actions
script.register_looped("anim_interrupt_event", function (aiev)
  if is_playing_anim then
    if Game.Self.isAlive() then
      aiev:sleep(1000)
      if is_playing_anim and not ENTITY.IS_ENTITY_PLAYING_ANIM(self.get_ped(), curr_playing_anim.curr_dict, curr_playing_anim.curr_anim, 3) then
        if PED.IS_PED_RAGDOLL(self.get_ped()) then
          repeat
            aiev:sleep(500)
          until not PED.IS_PED_RAGDOLL(self.get_ped())
          if Game.Self.isAlive() and not PAD.IS_CONTROL_PRESSED(0, 47) then -- we're alive and we didn't manually stop it
            onAnimInterrupt()
          end
        elseif PED.IS_PED_FALLING(self.get_ped()) then
          repeat
            aiev:sleep(500)
          until not PED.IS_PED_FALLING(self.get_ped())
          if Game.Self.isAlive() and not PAD.IS_CONTROL_PRESSED(0, 47) then
            onAnimInterrupt()
          end
        else
          aiev:sleep(100)
          if Game.Self.isAlive() and not PAD.IS_CONTROL_PRESSED(0, 47) then
            onAnimInterrupt()
          end
        end
      end
    else
      if plyrProps[1] ~= nil then
        for _, p in ipairs(plyrProps) do
          if ENTITY.DOES_ENTITY_EXIST(p) then
            ENTITY.DELETE_ENTITY(p)
          end
        end
      end
      is_playing_anim = false
    end
  else
    aiev:sleep()
  end

  if is_playing_scenario then
    if not Game.Self.isAlive() then
      if bbq ~= nil and ENTITY.DOES_ENTITY_EXIST(bbq) then
        ENTITY.DELETE_ENTITY(bbq)
      end
      is_playing_scenario = false
    end
  end
end)

-- script.register_looped("on_game_mode_switch", function(ogms) -- <- it was behaving nice by resetting variables on session or game mode switches
--   if Game.isOnline() then                                      --  then started causing problems.
--     if NETWORK.NETWORK_IS_IN_SESSION() then
--       repeat
--         ogms:sleep(1000)
--       until not NETWORK.NETWORK_IS_IN_SESSION()
--       if is_playing_anim or is_playing_scenario or ped_grabbed then
--         TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
--       end
--       if is_playing_radio or anim_music then
--         play_music("stop")
--       end
--       var_reset()
--     end
--   else
--     repeat
--       ogms:sleep(1000)
--     until NETWORK.NETWORK_IS_SESSION_STARTED()
--     if is_playing_anim or is_playing_scenario or ped_grabbed then
--       TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
--     end
--     if is_playing_radio or anim_music then
--       play_music("stop")
--     end
--     var_reset()
--   end
-- end)
script.register_looped("animation hotkey", function(script)
  script:yield()
  if is_playing_anim then
    if PAD.IS_CONTROL_PRESSED(0, 47) then
      cleanup()
      if anim_music then
        play_music("stop")
        anim_music = false
      end
      if PED.IS_PED_IN_ANY_VEHICLE(self.get_ped(), false) then
        local veh = PED.GET_VEHICLE_PED_IS_IN(self.get_ped(), false)
        local mySeat = Game.getPedVehicleSeat(self.get_ped())
        local npcSeat = Game.getPedVehicleSeat(self.get_ped())
        PED.SET_PED_INTO_VEHICLE(self.get_ped(), veh, mySeat)
        if spawned_npcs[1] ~= nil then
          cleanupNPC()
          if PED.IS_PED_IN_ANY_VEHICLE(v, false) then
            PED.SET_PED_INTO_VEHICLE(v, veh, npcSeat)
          else
            local current_NPCcoords = ENTITY.GET_ENTITY_COORDS(v)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(v, current_NPCcoords.x, current_NPCcoords.y, current_NPCcoords.z, true,
              false, false)
          end
        end
      else
        local current_coords = ENTITY.GET_ENTITY_COORDS(self.get_ped())
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(self.get_ped(), current_coords.x, current_coords.y, current_coords.z, true,
          false, false)
      end
      is_playing_anim = false
      is_shortcut_anim = false
    end
  end
  if usePlayKey then
    if filteredAnims == nil then
      updatefilteredAnims()
    end
    if PAD.IS_CONTROL_PRESSED(0, 317) then
      anim_index = anim_index + 1
      info = filteredAnims[anim_index + 1]
      if info == nil then
        anim_index = 0
        info = filteredAnims[anim_index + 1]
        gui.show_message("Current Animation:", info.name)
      end
      if info ~= nil then
        gui.show_message("Current Animation:", info.name)
      end
      script:sleep(200) -- average iki is about what, 250ms? this should be enough.
    elseif PAD.IS_CONTROL_PRESSED(0, 316) and anim_index > 0 then   -- prevent going to index 0 which breaks the script.
      anim_index = anim_index - 1
      info = filteredAnims[anim_index + 1]
      gui.show_message("Current Animation:", info.name)
      script:sleep(200)
    elseif PAD.IS_CONTROL_PRESSED(0, 316) and anim_index == 0 then
      info = filteredAnims[anim_index + 1]
      gui.show_warning("Current Animation:", info.name .. "\n\nYou have reached the top of the list.")
      script:sleep(400)
    end
    if PAD.IS_CONTROL_PRESSED(0, 256) then
      if not ped_grabbed and not vehicle_grabbed then
        if not is_playing_anim then
          if info ~= nil then
            local mycoords     = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
            local myheading    = ENTITY.GET_ENTITY_HEADING(self.get_ped())
            local myforwardX   = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
            local myforwardY   = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
            local myboneIndex  = PED.GET_PED_BONE_INDEX(self.get_ped(), info.boneID)
            local mybonecoords = PED.GET_PED_BONE_COORDS(self.get_ped(), info.boneID)
            if manualFlags then
              setmanualflag()
            else
              flag = info.flag
            end
            playSelected(self.get_ped(), flag, selfprop1, selfprop2, selfloopedFX, selfSexPed, myboneIndex, mycoords, myheading,
              myforwardX, myforwardY, mybonecoords, "self", plyrProps, selfPTFX)
              curr_playing_anim = {curr_dict = info.dict, curr_anim = info.anim, curr_flag = flag, curr_name = info.name}
              is_playing_anim = true
              if lua_Fn.str_contains(curr_playing_anim.curr_name, "DJ") then
                if not is_playing_radio then
                  play_music("start", "RADIO_22_DLC_BATTLE_MIX1_RADIO")
                  anim_music = true
                end
              end
            script:sleep(200)
          end
        else
          PAD.SET_CONTROL_SHAKE(0, 500, 250)
          gui.show_warning("Samurais Scripts",
            "Press " .. stopButton .. " to stop the current animation before playing the next one.")
          script:sleep(800)
        end
      else
        gui.show_error("Samurais Scripts",
            "You can not play animations while grabbing an NPC.")
          script:sleep(800)
      end
    end
  end
  if npc_blips[1] ~= nil then
    for _, b in ipairs(npc_blips) do
      if HUD.DOES_BLIP_EXIST(b) then
        for _, npc in ipairs(spawned_npcs) do
          if PED.IS_PED_SITTING_IN_ANY_VEHICLE(npc) then
            HUD.SET_BLIP_ALPHA(b, 0.0)
          else
            HUD.SET_BLIP_ALPHA(b, 1000.0)
          end
        end
      end
    end
  end
  if spawned_npcs[1] ~= nil then
    for _, npc in ipairs(spawned_npcs) do
      local myPos    = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
      local fwdX     = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
      local fwdY     = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
      local npcPos   = ENTITY.GET_ENTITY_COORDS(npc, false)
      local distCalc = SYSTEM.VDIST(myPos.x, myPos.y, myPos.z, npcPos.x, npcPos.y, npcPos.z)
      if distCalc > 100 then
        script:sleep(1000)
        TASK.CLEAR_PED_TASKS(npc)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(npc, myPos.x - (fwdX * 2), myPos.y - (fwdY * 2), myPos.z, true, false, false)
      end
    end
  end
end)

-- Animation Shotrcut
script.register_looped("anim shortcut", function(animsc)
  if shortcut_anim.anim ~= nil and not gui.is_open() and not ped_grabbed and not vehicle_grabbed then
    if PAD.IS_CONTROL_JUST_PRESSED(0, shortcut_anim.btn) and not is_typing then
      is_shortcut_anim = true
      info = shortcut_anim
      local mycoords     = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
      local myheading    = ENTITY.GET_ENTITY_HEADING(self.get_ped())
      local myforwardX   = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
      local myforwardY   = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
      local myboneIndex  = PED.GET_PED_BONE_INDEX(self.get_ped(), info.boneID)
      local mybonecoords = PED.GET_PED_BONE_COORDS(self.get_ped(), info.boneID)
      if is_playing_anim or is_playing_scenario then
        cleanup()
        if ENTITY.DOES_ENTITY_EXIST(bbq) then
          ENTITY.DELETE_ENTITY(bbq)
        end
        is_playing_anim     = false
        is_playing_scenario = false
        animsc:sleep(500)
      end
      if is_handsUp then
        TASK.CLEAR_PED_TASKS(self.get_ped())
        is_handsUp = false
        animsc:sleep(100)
      end
      if isCrouched then
        PED.RESET_PED_MOVEMENT_CLIPSET(self.get_ped(), 0)
        isCrouched = false
        animsc:sleep(100)
      end
      if Game.requestAnimDict(shortcut_anim.dict) then
        playSelected(self.get_ped(), shortcut_anim.flag, selfprop1, selfprop2, selfloopedFX, selfSexPed, myboneIndex, mycoords, myheading,
          myforwardX, myforwardY, mybonecoords, "self", plyrProps, selfPTFX)
        curr_playing_anim = {curr_dict = shortcut_anim.dict, curr_anim = shortcut_anim.anim, curr_flag = shortcut_anim.flag}
        if lua_Fn.str_contains(shortcut_anim.name, "DJ") then
          if not is_playing_radio then
            play_music("start", "RADIO_22_DLC_BATTLE_MIX1_RADIO")
            anim_music = true
          end
        end
        animsc:sleep(200)
        is_playing_anim  = true
      end
    end
  end
end)

-- Action Mode
script.register_looped("action mode", function(amode)
  if disableActionMode then
    if PED.IS_PED_USING_ACTION_MODE(self.get_ped()) then
      PLAYER.SET_DISABLE_AMBIENT_MELEE_MOVE(self.get_id(), true)
      PED.SET_PED_USING_ACTION_MODE(self.get_ped(), false, -1, 0)
    else
      amode:sleep(500)
    end
    amode:yield()
  end
end)
script.register_looped("npc stuff", function(npcStuff)
  if spawned_npcs[1] ~= nil then
    for k, v in ipairs(spawned_npcs) do
      if ENTITY.DOES_ENTITY_EXIST(v) then
        if ENTITY.IS_ENTITY_DEAD(v) then
          PED.REMOVE_PED_FROM_GROUP(v)
          npcStuff:sleep(3000)
          PED.DELETE_PED(v)
          table.remove(spawned_npcs, k)
        end
      end
    end
  end
end)

-- Hash Grabber
script.register_looped("HashGrabber", function(hg)
  if HashGrabber then
    if WEAPON.IS_PED_ARMED(self.get_ped(), 4) and PLAYER.IS_PLAYER_FREE_AIMING(self.get_id()) and PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 24) then
      local ent  = Game.getAimedEntity()
      local hash = Game.getEntityModel(ent)
      local type = Game.getEntityTypeString(ent)
      log.debug("\n----- Info Gun -----" .. "\n¤ Handle: " .. tostring(ent) .. "\n¤ Hash:   " .. tostring(hash) .. "\n¤ Type:   " .. tostring(type))
    end
  end
  hg:yield()
end)

-- Triggerbot loop
-- script.register_looped("TriggerBot", function(trgrbot)
--   if Triggerbot then
--     if PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then
--       aimBool, Entity = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), Entity)
--       if aimBool then
--         if ENTITY.IS_ENTITY_A_PED(Entity) and PED.IS_PED_HUMAN(Entity) then
--           local bonePos = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(Entity, "head"))
--           weapon = Game.Self.weapon()
--           if WEAPON.IS_PED_WEAPON_READY_TO_SHOOT(self.get_ped()) and Game.Self.isOnFoot() and not PED.IS_PED_RELOADING(self.get_ped()) then
--             if not ENTITY.IS_ENTITY_DEAD(Entity) then
--               if PAD.IS_CONTROL_PRESSED(0, 21) then
--                 if aimEnemy then
--                   if PED.IS_PED_IN_COMBAT(Entity, self.get_ped()) then
--                     TASK.TASK_AIM_GUN_AT_COORD(self.get_ped(), bonePos.x, bonePos.y, bonePos.z, 250, true, false)
--                     TASK.TASK_SHOOT_AT_COORD(self.get_ped(), bonePos.x, bonePos.y, bonePos.z, 250, 2556319013)
--                   end
--                 else
--                   TASK.TASK_AIM_GUN_AT_COORD(self.get_ped(), bonePos.x, bonePos.y, bonePos.z, 250, true, false)
--                   TASK.TASK_SHOOT_AT_COORD(self.get_ped(), bonePos.x, bonePos.y, bonePos.z, 250, 2556319013)
--                 end
--               end
--             end
--           end
--         end
--       else
--         Entity = 0
--       end
--     else
--       bool = false
--     end
--   end
--   trgrbot:yield()
-- end)

script.register_looped("auto-kill-enemies", function(ak)
  if autoKill then
    local myCoords = self.get_pos()
    local gta_peds = entities.get_all_peds_as_handles()
    if (PED.COUNT_PEDS_IN_COMBAT_WITH_TARGET_WITHIN_RADIUS(self.get_ped(), myCoords.x, myCoords.y, myCoords.z, 100)) > 0 then
      for _, p in pairs(gta_peds) do
        if PED.IS_PED_HUMAN(p) and PED.IS_PED_IN_COMBAT(p, self.get_ped()) and not PED.IS_PED_A_PLAYER(p) then
          if PED.CAN_PED_IN_COMBAT_SEE_TARGET(p, self.get_ped()) then
            PED.APPLY_DAMAGE_TO_PED(p, 100000, 1, 0); PED.EXPLODE_PED_HEAD(p, 0x7FD62962)
          else
            ak:sleep(969) -- prevent kill spamming. It's fine, I just don't like it.
            PED.APPLY_DAMAGE_TO_PED(p, 100000, 1, 0); PED.EXPLODE_PED_HEAD(p, 0x7FD62962)
          end
          ak:yield()
        end
      end
    end
  end
  ak:yield()
end)
script.register_looped("enemies-flee", function(ef)
  if runaway then
    local myCoords = self.get_pos()
    local gta_peds = entities.get_all_peds_as_handles()
    if (PED.COUNT_PEDS_IN_COMBAT_WITH_TARGET_WITHIN_RADIUS(self.get_ped(), myCoords.x, myCoords.y, myCoords.z, 100)) > 0 then
      for _, p in pairs(gta_peds) do
        if PED.IS_PED_HUMAN(p) and PED.IS_PED_IN_COMBAT(p, self.get_ped()) and not PED.IS_PED_A_PLAYER(p) then
          TASK.CLEAR_PED_SECONDARY_TASK(p)
          TASK.CLEAR_PED_TASKS(p)
          PED.SET_PED_KEEP_TASK(p, false)
          PED.SET_PED_COMBAT_ATTRIBUTES(p, 5, false)
          PED.SET_PED_COMBAT_ATTRIBUTES(p, 13, false)
          PED.SET_PED_COMBAT_ATTRIBUTES(p, 31, false)
          PED.SET_PED_COMBAT_ATTRIBUTES(p, 50, false)
          PED.SET_PED_COMBAT_ATTRIBUTES(p, 58, false)
          PED.SET_PED_COMBAT_ATTRIBUTES(p, 17, true)
          PED.SET_PED_COMBAT_ATTRIBUTES(p, 77, true)
          if WEAPON.IS_PED_ARMED(p, 7) then
            WEAPON.SET_PED_DROPS_WEAPON(p)
          end
          if PED.IS_PED_IN_ANY_VEHICLE(p, false) then
            TASK.TASK_VEHICLE_TEMP_ACTION(p, PED.GET_VEHICLE_PED_IS_USING(p), 1, 2000)
            TASK.TASK_LEAVE_ANY_VEHICLE(p, 0, 4160)
          end
          TASK.TASK_SMART_FLEE_PED(p, self.get_ped(), 250, 5000, false, false)
        end
      end
    end
  end
  ef:yield()
end)
script.register_looped("laser_render", function(lsr)
  if laserSight and WEAPON.IS_PED_ARMED(self.get_ped(), 4) and Game.Self.isOnFoot() then
    local wpn_hash = WEAPON.GET_SELECTED_PED_WEAPON(self.get_ped())
    local wpn_idx  = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(self.get_ped())
    local hr, _, _ = NETWORK.NETWORK_GET_GLOBAL_MULTIPLAYER_CLOCK()
    local laser_a  = 1.0
    local wpn_bone = 0
    if wpn_hash ~= 0x34A67B97 and wpn_hash ~= 0xBA536372 and  wpn_hash ~= 0x184140A1 and  wpn_hash ~= 0x060EC506 then
      for _, bone in ipairs(weapbones_T) do
        bone_check = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(wpn_idx, bone)
        if bone_check ~= -1 then
          wpn_bone = bone_check
          break
        end
      end
    end
    if hr ~= nil then
      if hr > 6 and hr < 20 then
        laser_a = 0.5
      else
        laser_a = 0.2
      end
    else
      laser_a = 0.9
    end
    if PLAYER.IS_PLAYER_FREE_AIMING(self.get_id()) and wpn_bone ~= 0 then
      if Game.requestNamedPtfxAsset('core') then
        lsr:sleep(300)
        GRAPHICS.USE_PARTICLE_FX_ASSET('core')
        laserPtfx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE(laser_choice, wpn_idx,
        1.0, 0.0, -0.01, 0.0, 0.0, 90.0, wpn_bone, 0.20, false, false, false, 0, 0, 0)
        GRAPHICS.SET_PARTICLE_FX_LOOPED_ALPHA(laserPtfx, laser_a)
        table.insert(laserPtfx_T, laserPtfx)
        drew_laser = true
      end
      if drew_laser then
        repeat
          lsr:sleep(50)
        until PLAYER.IS_PLAYER_FREE_AIMING(self.get_id()) == false
        for _, laser in ipairs(laserPtfx_T) do
          if GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(laser) then
            GRAPHICS.STOP_PARTICLE_FX_LOOPED(laser)
            GRAPHICS.REMOVE_PARTICLE_FX(laser)
          end
          drew_laser = false
        end
      end
    end
  end
end)

-- vehicle stuff
script.register_looped("TDFT", function(script)
  script:yield()
  if PED.IS_PED_SITTING_IN_ANY_VEHICLE(self.get_ped()) then
    lastVeh, _, current_vehicle, _ = onVehEnter()
    is_car                         = VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(current_vehicle))
    is_quad                        = VEHICLE.IS_THIS_MODEL_A_QUADBIKE(ENTITY.GET_ENTITY_MODEL(current_vehicle))
    is_plane                       = VEHICLE.IS_THIS_MODEL_A_PLANE(ENTITY.GET_ENTITY_MODEL(current_vehicle))
    is_heli                        = VEHICLE.IS_THIS_MODEL_A_HELI(ENTITY.GET_ENTITY_MODEL(current_vehicle))
    is_bike                        = (VEHICLE.IS_THIS_MODEL_A_BIKE(ENTITY.GET_ENTITY_MODEL(current_vehicle))
    and VEHICLE.GET_VEHICLE_CLASS(current_vehicle) ~= 13 and ENTITY.GET_ENTITY_MODEL(current_vehicle) ~= 0x7B54A9D3)
    is_boat                        = VEHICLE.IS_THIS_MODEL_A_BOAT(ENTITY.GET_ENTITY_MODEL(current_vehicle)) or
        VEHICLE.IS_THIS_MODEL_A_JETSKI(ENTITY.GET_ENTITY_MODEL(current_vehicle))
    if is_car or is_quad then
      validModel = true
    else
      validModel = false
    end
    if validModel and DriftTires and PAD.IS_CONTROL_PRESSED(0, tdBtn) then
      if not VEHICLE.GET_DRIFT_TYRES_SET(current_vehicle) then
        VEHICLE.SET_DRIFT_TYRES(current_vehicle, true)
      end
      VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(current_vehicle, DriftPowerIncrease)
    else
      VEHICLE.SET_DRIFT_TYRES(current_vehicle, false)
      VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(current_vehicle, 1.0)
    end
    script:yield()
    if validModel and driftMode and PAD.IS_CONTROL_PRESSED(0, tdBtn) and not DriftTires then
      VEHICLE.SET_VEHICLE_REDUCE_GRIP(current_vehicle, true)
      VEHICLE.SET_VEHICLE_REDUCE_GRIP_LEVEL(current_vehicle, DriftIntensity)
      VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(current_vehicle, DriftPowerIncrease)
    else
      VEHICLE.SET_VEHICLE_REDUCE_GRIP(current_vehicle, false)
      VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(current_vehicle, 1.0)
    end
    if speedBoost then
      if validModel or is_boat or is_bike then
        if VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(current_vehicle) then
          if PAD.IS_DISABLED_CONTROL_PRESSED(0, tdBtn) and PAD.IS_CONTROL_PRESSED(0, 71) then
            VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(current_vehicle, (nosPower) / 5)
            VEHICLE.MODIFY_VEHICLE_TOP_SPEED(current_vehicle, nosPower)
            AUDIO.SET_VEHICLE_BOOST_ACTIVE(current_vehicle, true)
            using_nos = true
          end
        else
          if PED.IS_PED_SITTING_IN_ANY_VEHICLE(self.get_ped()) then
            if PAD.IS_DISABLED_CONTROL_PRESSED(0, tdBtn) and PAD.IS_CONTROL_PRESSED(0, 71) then
              if VEHICLE.GET_VEHICLE_ENGINE_HEALTH(current_vehicle) < 300 then
                failSound = AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "Engine_fail", current_vehicle,
                  "DLC_PILOT_ENGINE_FAILURE_SOUNDS", true, 0)
                repeat
                  script:sleep(50)
                until
                  AUDIO.HAS_SOUND_FINISHED(failSound) and PAD.IS_CONTROL_PRESSED(0, tdBtn) == false and PAD.IS_CONTROL_PRESSED(0, 71) == false
                AUDIO.STOP_SOUND(failSound)
              end
            end
          end
        end
      end
      if using_nos and PAD.IS_DISABLED_CONTROL_RELEASED(0, tdBtn) then
        VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(current_vehicle, 1.0)
        VEHICLE.MODIFY_VEHICLE_TOP_SPEED(current_vehicle, -1)
        AUDIO.SET_VEHICLE_BOOST_ACTIVE(current_vehicle, false)
        using_nos = false
      end
    end
    if hornLight and Game.Self.isDriving() then
      if not VEHICLE.GET_BOTH_VEHICLE_HEADLIGHTS_DAMAGED(current_vehicle) then
        if PAD.IS_CONTROL_PRESSED(0, 86) then
          VEHICLE.SET_VEHICLE_LIGHTS(current_vehicle, 2)
          VEHICLE.SET_VEHICLE_FULLBEAM(current_vehicle, true)
          repeat
            script:sleep(50)
          until
            PAD.IS_CONTROL_PRESSED(0, 86) == false
          VEHICLE.SET_VEHICLE_FULLBEAM(current_vehicle, false)
          VEHICLE.SET_VEHICLE_LIGHTS(current_vehicle, 0)
        end
      end
    end
    if Game.Self.isDriving() and (is_car or is_quad) and keepWheelsTurned and not holdF then
      if PAD.IS_DISABLED_CONTROL_PRESSED(0, 75) and (PAD.IS_CONTROL_PRESSED(0, 34) or PAD.IS_CONTROL_PRESSED(0, 35)) then
        VEHICLE.SET_VEHICLE_ENGINE_ON(current_vehicle, false, true, false)
        TASK.TASK_LEAVE_VEHICLE(self.get_ped(), current_vehicle, 16)
      end
    end
    if Game.Self.isDriving() and holdF then
      if PAD.IS_DISABLED_CONTROL_PRESSED(0, 75) then
        timerB = timerB + 1
        if timerB >= 15 then
          if keepWheelsTurned and (PAD.IS_CONTROL_PRESSED(0, 34) or PAD.IS_CONTROL_PRESSED(0, 35)) and (is_car or is_quad) then
            VEHICLE.SET_VEHICLE_ENGINE_ON(current_vehicle, false, true, false)
            TASK.TASK_LEAVE_VEHICLE(self.get_ped(), current_vehicle, 16)
            timerB = 0
          else
            PED.SET_PED_CONFIG_FLAG(self.get_ped(), 241, false)
            TASK.TASK_LEAVE_VEHICLE(self.get_ped(), current_vehicle, 0)
            timerB = 0
          end
        end
      end
      if timerB >= 1 and timerB <= 10 then
        if PAD.IS_DISABLED_CONTROL_RELEASED(0, 75) then
          if keepWheelsTurned and (PAD.IS_CONTROL_PRESSED(0, 34) or PAD.IS_CONTROL_PRESSED(0, 35)) and (is_car or is_quad) then
            TASK.TASK_LEAVE_VEHICLE(self.get_ped(), current_vehicle, 16)
            timerB = 0
          else
            PED.SET_PED_CONFIG_FLAG(self.get_ped(), 241, true)
            TASK.TASK_LEAVE_VEHICLE(self.get_ped(), current_vehicle, 0)
            timerB = 0
          end
        end
      end
    else
      if PED.GET_PED_CONFIG_FLAG(self.get_ped(), 241, 1) then
        PED.SET_PED_CONFIG_FLAG(self.get_ped(), 241, false)
      end
    end
  else
    if started_lct then
      started_lct = false
    end
    if started_popSound then
      started_popSound = false
    end
    if started_popSound2 then
      started_popSound2 = false
    end
  end
end)

script.register_looped("tire smoke", function(smkptfx)
  if driftMode or DriftTires then
    if DriftSmoke and Game.Self.isDriving() and is_drifting then
      if is_car and PAD.IS_CONTROL_PRESSED(0, tdBtn) and PAD.IS_CONTROL_PRESSED(0, 71) and VEHICLE.GET_VEHICLE_CURRENT_DRIVE_GEAR_(current_vehicle) > 0 and ENTITY.GET_ENTITY_SPEED(current_vehicle) > 6 then
        local dict = "scr_ba_bb"
        local wheels = { "wheel_lr", "wheel_rr" }
        if VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(current_vehicle) and not VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) then
          if Game.requestNamedPtfxAsset(dict) then
            for _, boneName in ipairs(wheels) do
              local r_wheels = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, boneName)
              GRAPHICS.USE_PARTICLE_FX_ASSET(dict)
              smokePtfx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE("scr_ba_bb_plane_smoke_trail",
                current_vehicle,
                -0.4, 0.0, 0.0, 0.0, 0.0, 0.0, r_wheels, 0.3, false, false, false, 0, 0, 0)
              GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(smokePtfx, driftSmoke_T.r, driftSmoke_T.g, driftSmoke_T.b, 0)
              table.insert(smokePtfx_t, smokePtfx)
              GRAPHICS.STOP_PARTICLE_FX_LOOPED(smoke)
              tire_smoke = true
            end
            if tire_smoke then
              repeat
                smkptfx:sleep(50)
              until
                PAD.IS_CONTROL_RELEASED(0, tdBtn) or PAD.IS_CONTROL_RELEASED(0, 71)
              for _, smoke in ipairs(smokePtfx_t) do
                if GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(smoke) then
                  GRAPHICS.STOP_PARTICLE_FX_LOOPED(smoke)
                  GRAPHICS.REMOVE_PARTICLE_FX(smoke)
                end
              end
              tire_smoke = false
            end
          end
        end
      end
    end
  end
end)

script.register_looped("LCTRL", function(lct)
  if launchCtrl and Game.Self.isDriving() then
    if limitVehOptions then
      if VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 4 and VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 6 and VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 7 then
        lct:yield()
        return
      end
    end
    local notif_sound, notif_ref
    if Game.isOnline() then
      notif_sound, notif_ref = "SELL", "GTAO_EXEC_SECUROSERV_COMPUTER_SOUNDS"
    else
      notif_sound, notif_ref = "MP_5_SECOND_TIMER", "HUD_FRONTEND_DEFAULT_SOUNDSET"
    end
    if validModel or is_bike or is_quad then
      if VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(current_vehicle) and VEHICLE.GET_VEHICLE_ENGINE_HEALTH(current_vehicle) > 300 then
        if PAD.IS_CONTROL_PRESSED(0, 71) and PAD.IS_CONTROL_PRESSED(0, 72) and not PAD.IS_CONTROL_PRESSED(0, tdBtn) then
          started_lct = true
          ENTITY.FREEZE_ENTITY_POSITION(current_vehicle, true)
          timerA = timerA + 1
          if timerA >= 100 then
            gui.show_success("Samurais Scripts", "Launch Control Activated!")
            AUDIO.PLAY_SOUND_FRONTEND(-1, notif_sound, notif_ref, true)
            repeat
              lct:sleep(100)
            until PAD.IS_CONTROL_RELEASED(0, 72)
            launch_active = true
          end
        elseif started_lct and timerA > 0 and timerA < 150 then
          if PAD.IS_CONTROL_RELEASED(0, 71) or PAD.IS_CONTROL_RELEASED(0, 72) then
            timerA = 0
            ENTITY.FREEZE_ENTITY_POSITION(current_vehicle, false)
            started_lct = false
          end
        end
      end
      if launch_active then
        if PAD.IS_CONTROL_PRESSED(0, 71) and PAD.IS_CONTROL_RELEASED(0, 72) then
          PHYSICS.SET_IN_ARENA_MODE(true)
          VEHICLE.SET_VEHICLE_MAX_LAUNCH_ENGINE_REVS_(current_vehicle, -1)
          VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(current_vehicle, 10)
          VEHICLE.MODIFY_VEHICLE_TOP_SPEED(current_vehicle, 100.0)
          ENTITY.FREEZE_ENTITY_POSITION(current_vehicle, false)
          VEHICLE.SET_VEHICLE_FORWARD_SPEED(current_vehicle, 9.3)
          lct:sleep(4269)
          VEHICLE.MODIFY_VEHICLE_TOP_SPEED(current_vehicle, -1)
          VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(current_vehicle, 1.0)
          VEHICLE.SET_VEHICLE_MAX_LAUNCH_ENGINE_REVS_(current_vehicle, 1.0)
          PHYSICS.SET_IN_ARENA_MODE(false)
          launch_active = false
          timerA = 0
        end
      end
    end
  end
  lct:yield()
end)

script.register_looped("MISC Vehicle Options", function(mvo)
  if Game.Self.isDriving() then
    if autobrklight then
      if VEHICLE.IS_VEHICLE_DRIVEABLE(current_vehicle) and VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(current_vehicle) then
        VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(current_vehicle, true)
      end
    end

    if insta180 then
      local vehRot = ENTITY.GET_ENTITY_ROTATION(current_vehicle, 2)
      if PAD.IS_CONTROL_JUST_PRESSED(0, 97) then -- numpad + // mouse scroll down
        if PAD.IS_CONTROL_PRESSED(0, 71) then
          local vehSpeed = ENTITY.GET_ENTITY_SPEED(current_vehicle)
          ENTITY.SET_ENTITY_ROTATION(current_vehicle, vehRot.x, vehRot.y, (vehRot.z - 180), 2, true)
          VEHICLE.SET_VEHICLE_FORWARD_SPEED(current_vehicle, vehSpeed)
        else
          ENTITY.SET_ENTITY_ROTATION(current_vehicle, vehRot.x, vehRot.y, (vehRot.z - 180), 2, true)
          if VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) then
            VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(current_vehicle, 5.0)
          end
        end
      end
    end
  end

  if flappyDoors and current_vehicle ~= 0 and is_car then
    local n_doors = VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(current_vehicle)
    if n_doors > 0 then
      for i = -1, n_doors + 1 do
        if VEHICLE.GET_IS_DOOR_VALID(current_vehicle, i) then
          mvo:sleep(180)
          VEHICLE.SET_VEHICLE_DOOR_OPEN(current_vehicle, i, false, false)
          mvo:sleep(180)
          VEHICLE.SET_VEHICLE_DOOR_SHUT(current_vehicle, i, false)
        end
      end
    end
  end
end)

script.register_looped("NOS ptfx", function(spbptfx)
  if speedBoost and Game.Self.isDriving() then
    if validModel or is_boat or is_bike then
      if PAD.IS_DISABLED_CONTROL_PRESSED(0, tdBtn) and PAD.IS_CONTROL_PRESSED(0, 71) then
        if VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(current_vehicle) then
          local effect  = "veh_xs_vehicle_mods"
          local counter = 0
          while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(effect) do
            STREAMING.REQUEST_NAMED_PTFX_ASSET(effect)
            spbptfx:yield()
            if counter > 100 then
              return
            else
              counter = counter + 1
            end
          end
          local exhaustCount = VEHICLE.GET_VEHICLE_MAX_EXHAUST_BONE_COUNT_() - 1
          for i = 0, exhaustCount do
            local retBool, boneIndex = VEHICLE.GET_VEHICLE_EXHAUST_BONE_(current_vehicle, i, retBool, boneIndex)
            if retBool then
              GRAPHICS.USE_PARTICLE_FX_ASSET(effect)
              nosPtfx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE("veh_nitrous", current_vehicle, 0.0,
                0.0, 0.0, 0.0, 0.0, 0.0, boneIndex, 1.0, false, false, false, 0, 0, 0)
              table.insert(nosptfx_t, nosPtfx)
              if nosvfx then
                GRAPHICS.ANIMPOSTFX_PLAY("DragRaceNitrous", 0, false)
              end
              nos_started = true
            end
          end
          if nos_started then
            repeat
              spbptfx:sleep(50)
            until
              PAD.IS_DISABLED_CONTROL_RELEASED(0, tdBtn) or PAD.IS_CONTROL_RELEASED(0, 71)
            if nosvfx then
              GRAPHICS.ANIMPOSTFX_PLAY("DragRaceNitrousOut", 0, false)
            end
            if GRAPHICS.ANIMPOSTFX_IS_RUNNING("DragRaceNitrous") then
              GRAPHICS.ANIMPOSTFX_STOP("DragRaceNitrous")
            end
            if GRAPHICS.ANIMPOSTFX_IS_RUNNING("DragRaceNitrousOut") then
              GRAPHICS.ANIMPOSTFX_STOP("DragRaceNitrousOut")
            end
            for _, nos in ipairs(nosptfx_t) do
              if GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(nos) then
                GRAPHICS.STOP_PARTICLE_FX_LOOPED(nos)
                GRAPHICS.REMOVE_PARTICLE_FX(nos)
                nos_started = false
              end
            end
          end
        end
      end
    end
  end
end)

script.register_looped("2-step", function(twostep)
  if launchCtrl and Game.Self.isDriving() then
    if limitVehOptions then
      if VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 4 and VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 6 and VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 7 then
        twostep:yield()
        return
      end
    end
    if validModel or is_bike or is_quad then
      if VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(current_vehicle) and VEHICLE.GET_VEHICLE_ENGINE_HEALTH(current_vehicle) >= 300 then
        if PAD.IS_CONTROL_PRESSED(0, 71) and PAD.IS_CONTROL_PRESSED(0, 72) and not PAD.IS_CONTROL_PRESSED(0, tdBtn) then
          local asset   = "core"
          local counter = 0
          while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(asset) do
            STREAMING.REQUEST_NAMED_PTFX_ASSET(asset)
            twostep:yield()
            if counter > 100 then
              return
            else
              counter = counter + 1
            end
          end
          local exhaustCount = VEHICLE.GET_VEHICLE_MAX_EXHAUST_BONE_COUNT_() - 1
          for i = 0, exhaustCount do
            local retBool, boneIndex = VEHICLE.GET_VEHICLE_EXHAUST_BONE_(current_vehicle, i, retBool, boneIndex)
            if retBool then
              GRAPHICS.USE_PARTICLE_FX_ASSET(asset)
              lctPtfx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE("veh_backfire", current_vehicle, 0.0,
                0.0, 0.0, 0.0, 0.0, 0.0, boneIndex, 0.69420, false, false, false, 0, 0, 0)
              table.insert(lctPtfx_t, lctPtfx)
              twostep_started = true
            end
          end
          if twostep_started then
            repeat
              twostep:sleep(50)
            until PAD.IS_CONTROL_RELEASED(0, 72) or launch_active == false
            for _, bfire in ipairs(lctPtfx_t) do
              if GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(bfire) then
                GRAPHICS.STOP_PARTICLE_FX_LOOPED(bfire)
                GRAPHICS.REMOVE_PARTICLE_FX(bfire)
              end
            end
            twostep_started = false
          end
        end
      end
    end
  end
end)

script.register_looped("LCTRL SFX", function(tstp)
  if Game.Self.isDriving() then
    if limitVehOptions then
      if VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 4 and VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 6 and VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 7 then
        tstp:yield()
        return
      end
    end

    if launchCtrl then
      if lctPtfx_t[1] ~= nil then
        local popSound
        if VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) and PAD.IS_CONTROL_PRESSED(0, 71) and PAD.IS_CONTROL_PRESSED(0, 72) and not PAD.IS_CONTROL_PRESSED(0, tdBtn) then
          for _, p in ipairs(lctPtfx_t) do
            if GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(p) then
              local randStime = math.random(60, 120)
              popSound = AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "BOOT_POP", current_vehicle, "DLC_VW_BODY_DISPOSAL_SOUNDS",
                true, 0)
              AUDIO.SET_AUDIO_SPECIAL_EFFECT_MODE(1)
              table.insert(popSounds_t, popSound)
              tstp:sleep(randStime)
              started_popSound = true
            end
          end
        end
        if started_popSound then
          if PAD.IS_CONTROL_RELEASED(0, 71) or PAD.IS_CONTROL_RELEASED(0, 72) then
            for _, s in ipairs(popSounds_t) do
              AUDIO.STOP_SOUND(s)
            end
          end
        end
      end
    end

    if popsNbangs then
      if VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) then
        rpmThreshold = 0.45
      else
        rpmThreshold = 0.69
      end
      if not louderPops then
        popsnd, sndRef = "BOOT_POP", "DLC_VW_BODY_DISPOSAL_SOUNDS"
        flame_size = 0.42069
      else
        popsnd, sndRef = "SNIPER_FIRE", "DLC_BIKER_RESUPPLY_MEET_CONTACT_SOUNDS"
        flame_size = 1.5
      end
      local currRPM  = VEHICLE.GET_VEHICLE_CURRENT_REV_RATIO_(current_vehicle)
      local currGear = VEHICLE.GET_VEHICLE_CURRENT_DRIVE_GEAR_(current_vehicle)
      if PAD.IS_CONTROL_RELEASED(0, 71) and currRPM < 1.0 and currRPM > rpmThreshold and currGear ~= 0 then
        local popSound2
        local randStime = math.random(60, 200)
        popSound2 = AUDIO.PLAY_SOUND_FROM_ENTITY(-1, popsnd, current_vehicle, sndRef, true, 0)
        table.insert(popSounds_t, popSound2)
        tstp:sleep(randStime)
        started_popSound2 = true
      end
      if started_popSound2 then
        currRPM = VEHICLE.GET_VEHICLE_CURRENT_REV_RATIO_(current_vehicle)
        if PAD.IS_CONTROL_PRESSED(0, 71) or currRPM < rpmThreshold then
          for _, s in ipairs(popSounds_t) do
            AUDIO.STOP_SOUND(s)
          end
        end
      end
    end
  else
    tstp:yield()
  end
end)

script.register_looped("pops&bangs", function(pnb)
  if Game.Self.isDriving() and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(current_vehicle) then
    if is_car or is_bike or is_quad then
      if popsNbangs then
        if limitVehOptions then
          if VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 4 and VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 6 and VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 7 then
            pnb:yield()
            return
          end
        end
        AUDIO.ENABLE_VEHICLE_EXHAUST_POPS(current_vehicle, false)
        local counter  = 0
        local asset    = "core"
        local currRPM  = VEHICLE.GET_VEHICLE_CURRENT_REV_RATIO_(current_vehicle)
        local currGear = VEHICLE.GET_VEHICLE_CURRENT_DRIVE_GEAR_(current_vehicle)
        if VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) then
          rpmThreshold = 0.45
        else
          rpmThreshold = 0.69
        end
        while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(asset) do
          STREAMING.REQUEST_NAMED_PTFX_ASSET(asset)
          pnb:yield()
          if counter > 100 then
            return
          else
            counter = counter + 1
          end
        end
        if PAD.IS_CONTROL_RELEASED(0, 71) and currRPM < 1.0 and currRPM > rpmThreshold and currGear ~= 0 then
          local exhaustCount = VEHICLE.GET_VEHICLE_MAX_EXHAUST_BONE_COUNT_() - 1
          for i = 0, exhaustCount do
            local retBool, boneIndex = VEHICLE.GET_VEHICLE_EXHAUST_BONE_(current_vehicle, i, retBool, boneIndex)
            if retBool then
              currRPM = VEHICLE.GET_VEHICLE_CURRENT_REV_RATIO_(current_vehicle)
              if currRPM < 1.0 and currRPM > 0.55 then
                GRAPHICS.USE_PARTICLE_FX_ASSET(asset)
                popsPtfx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE("veh_backfire", current_vehicle,
                  0.0, 0.0, 0.0, 0.0, 0.0, 0.0, boneIndex, flame_size, false, false, false, 0, 0, 0)
                GRAPHICS.STOP_PARTICLE_FX_LOOPED(popsPtfx)
                table.insert(popsPtfx_t, popsPtfx)
                started_popSound2 = true
              end
            end
          end
        end
        if started_popSound2 then
          currRPM = VEHICLE.GET_VEHICLE_CURRENT_REV_RATIO_(current_vehicle)
          if PAD.IS_CONTROL_PRESSED(0, 71) or currRPM < rpmThreshold then
            for _, bfire in ipairs(popsPtfx_t) do
              if GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(bfire) then
                GRAPHICS.STOP_PARTICLE_FX_LOOPED(bfire)
                GRAPHICS.REMOVE_PARTICLE_FX(bfire)
              end
            end
            for _, s in ipairs(popSounds_t) do
              AUDIO.STOP_SOUND(s)
            end
          end
        end
      else
        AUDIO.ENABLE_VEHICLE_EXHAUST_POPS(current_vehicle, true)
      end
    end
  else
    pnb:yield()
  end
end)

-- drift minigame (WIP)
script.register_looped("straight line counter", function()
  if driftMode or DriftTires and is_car then
    if Game.Self.isDriving() and is_drifting and driftMinigame then
      local vehSpeedVec = ENTITY.GET_ENTITY_SPEED_VECTOR(current_vehicle, true)
      if not VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) then
        if vehSpeedVec.x ~= 0 and vehSpeedVec.x < 2 or vehSpeedVec.x > - 2 then
          straight_counter = straight_counter + 1
        else
          straight_counter = 0
        end
      end
    end
  end
end)
script.register_looped("drift counter", function(dcounter)
  if driftMinigame then
    if driftMode or DriftTires and is_car then
      if Game.Self.isDriving() then
        local vehSpeedVec = ENTITY.GET_ENTITY_SPEED_VECTOR(current_vehicle, true)
        if vehSpeedVec.x ~= 0 and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(current_vehicle) then
          if vehSpeedVec.x > 6 or vehSpeedVec.x < - 6 then
            is_drifting = true
            drift_streak_text = 'Drift' .. '   x' .. drift_multiplier
            straight_counter  = 0
            drift_points = drift_points + (1 * drift_multiplier)
          end
          if vehSpeedVec.x > 11 or vehSpeedVec.x < - 11 then
            is_drifting = true
            drift_streak_text = 'Big Angle!' .. '   x' .. drift_multiplier
            straight_counter  = 0
            drift_points = drift_points + (5 * drift_multiplier)
          end
          if vehSpeedVec.x > 14 or vehSpeedVec.x < - 14 then
            is_drifting = true
            drift_streak_text = 'SICK ANGLE!!!' .. '   x' .. drift_multiplier
            straight_counter  = 0
            drift_points = drift_points + (10 * drift_multiplier)
          end
        end
        if is_drifting then
          if not VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) then
            if vehSpeedVec.x < 2 and vehSpeedVec.x > - 2 then
              if straight_counter > 400 then
                if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(current_vehicle) then
                  if checkDriftCollision() then
                    drift_streak_text = 'Streak lost!'
                    drift_points      = 0
                    drift_multiplier  = 1
                    drift_extra_pts   = 0
                    is_drifting       = false
                  end
                else
                  drift_streak_text = 'Banked Points: '
                  if not Game.isOnline() then
                    if drift_points > 100 then
                      bankDriftPoints_SP(lua_Fn.round((drift_points / 10), 0))
                    end
                  end
                  dcounter:sleep(3000)
                  drift_points     = 0
                  drift_extra_pts  = 0
                  drift_multiplier = 1
                  is_drifting      = false
                end
              end
            end
          end
          if not VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) then
            if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(current_vehicle) then
              if checkDriftCollision() then
                drift_streak_text = 'Streak Lost!'
                drift_points      = 0
                drift_extra_pts   = 0
                drift_multiplier  = 1
                dcounter:sleep(3000)
                is_drifting = false
              end
            end
          else
            dcounter:sleep(3000)
            if not ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(current_vehicle) then
              drift_streak_text = 'Banked Points: '
              if not Game.isOnline() then
                if drift_points > 100 then
                  bankDriftPoints_SP(lua_Fn.round((drift_points / 10), 0))
                end
              end
              dcounter:sleep(3000)
              drift_points     = 0
              drift_multiplier = 1
              is_drifting      = false
            else
              if checkDriftCollision() then
                drift_streak_text = 'Streak Lost!'
                drift_points      = 0
                drift_extra_pts   = 0
                drift_multiplier  = 1
                is_drifting = false
                dcounter:sleep(3000)
              end
            end
          end
        end
      else
        if is_drifting then
          drift_streak_text = 'Streak Lost!'
          drift_points      = 0
          drift_extra_pts   = 0
          drift_multiplier  = 1
          is_drifting = false
        end
      end
    end
  end
end)
script.register_looped("drift time counter", function(dtcounter)
  if Game.Self.isDriving  and is_car and is_drifting then
    if straight_counter == 0 then
      drift_time = drift_time + 1
      dtcounter:sleep(1000)
    end
  else
    if drift_time > 0 then -- no need to keep setting it to 0
      drift_time = 0
    end
  end
end)
script.register_looped("extra points checker", function(epc)
  if Game.Self.isDriving and is_car then
    if is_drifting and ENTITY.GET_ENTITY_SPEED(current_vehicle) > 7 then
      if not ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(current_vehicle) then
        local vehicle_height = ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(current_vehicle)
        if vehicle_height > 0.8 and not VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(current_vehicle) then
          if vehicle_height >= 1.1 and vehicle_height <= 5 and not lua_Fn.str_contains(drift_extra_text, "Big Air!") then
            drift_extra_pts  = drift_extra_pts + 1
            drift_points     = drift_points + drift_extra_pts
            drift_extra_text = "Air  +" .. drift_extra_pts .. " pts"
            epc:sleep(100)
          elseif vehicle_height > 5 then
            drift_extra_pts  = drift_extra_pts + 5
            drift_points     = drift_points + drift_extra_pts
            drift_extra_text = "Big Air!  +" .. drift_extra_pts .. " pts"
            epc:sleep(100)
          end
        else
          if drift_extra_pts > 0 then
            epc:sleep(2000)
            drift_extra_pts = 0
            drift_extra_text = ""
          end
        end
      else
        local bool, txt = checkDriftCollision()
        if not bool and drift_streak_text ~= "" then
          drift_extra_pts  = drift_extra_pts + 1
          drift_points     = drift_points + drift_extra_pts
          drift_extra_text = txt .. "  +" .. drift_extra_pts .. " pts"
        else
          drift_extra_text = txt
          epc:sleep(3000)
          if drift_extra_pts > 0 or drift_extra_text ~= "" then
            drift_extra_pts  = 0
            drift_extra_text = ""
          end
        end
      end
    else
      if drift_extra_pts > 0 then
        epc:sleep(2000)
        drift_extra_pts = 0
        drift_extra_text = ""
      end
    end
  else
    if drift_extra_pts > 0 then
      epc:sleep(2000)
      drift_extra_pts = 0
      drift_extra_text = ""
    end
  end
end)
script.register_looped("drift multiplier", function(dmult)
  if Game.Self.isDriving and is_car and is_drifting then
    if drift_time >= 10 and drift_time < 30 then
      drift_multiplier = 1
    elseif drift_time >= 20 and drift_time < 60 then
      drift_multiplier = 2
    elseif drift_time >= 60 and drift_time < 120 then
      drift_multiplier = 5
    elseif drift_time >= 120 then
      drift_multiplier = 10
    end
  else
    if drift_multiplier > 1 then
      drift_multiplier = 1
    end
  end
  dmult:yield()
end)
script.register_looped("drift points", function()
  if Game.Self.isDriving() and is_car and is_drifting then
    showDriftCounter(drift_streak_text .. "\n+" .. lua_Fn.separateInt(drift_points) .. " pts")
    if drift_extra_pts > 0 or drift_extra_text ~= "" then
      showDriftExtra(drift_extra_text)
    end
  end
end)

-- Missile defense
script.register_looped("missile defense", function(md)
  if missiledefense and current_vehicle ~= 0 then
    local missile
    local vehPos  = ENTITY.GET_ENTITY_COORDS(current_vehicle, true)
    local selfPos = self.get_pos()
    for _, p in pairs(projectile_types_T) do
      if MISC.IS_PROJECTILE_TYPE_IN_AREA(vehPos.x + 500, vehPos.y + 500, vehPos.z + 100, vehPos.x - 500, vehPos.y - 500, vehPos.z - 100, p, false) then
        missile = p
        break
      end
    end
    if missile ~= 0 then
      -- if MISC.IS_PROJECTILE_TYPE_IN_AREA(vehPos.x + 100, vehPos.y + 100, vehPos.z + 100, vehPos.x - 100, vehPos.y - 100, vehPos.z - 100, missile, false) then
      --   if Game.Self.isDriving() and (is_plane or is_heli) then
      --     shoot_flares(md)
      --   end
      -- end
      -- ^ auto-counters missiles with flares but it's too easy
      if MISC.IS_PROJECTILE_TYPE_IN_AREA(vehPos.x + 20, vehPos.y + 20, vehPos.z + 100, vehPos.x - 20, vehPos.y - 20, vehPos.z - 100, missile, false) then
        if not MISC.IS_PROJECTILE_TYPE_IN_AREA(vehPos.x + 10, vehPos.y + 10, vehPos.z + 50, vehPos.x - 10, vehPos.y - 10, vehPos.z - 50, missile, false) and not MISC.IS_PROJECTILE_TYPE_IN_AREA(selfPos.x + 10, selfPos.y + 10, selfPos.z + 50, selfPos.x - 10, selfPos.y - 10, selfPos.z - 50, missile, false) then
          log.info('Detected projectile within our defense area! Proceeding to destroy it.')
          WEAPON.REMOVE_ALL_PROJECTILES_OF_TYPE(missile, true)
          if Game.requestNamedPtfxAsset("scr_sm_counter") then
            GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", vehPos.x, vehPos.y, (vehPos.z + 2.5),
            0.0, 0.0, 0.0, 5.0, false, false, false, false)
          end
        else
          log.warning('Found a projectile very close to our vehicle! Proceeding to remove it.')
          WEAPON.REMOVE_ALL_PROJECTILES_OF_TYPE(missile, false)
          if Game.requestNamedPtfxAsset("scr_sm_counter") then
            GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", vehPos.x, vehPos.y, (vehPos.z + 2.5),
            0.0, 0.0, 0.0, 5.0, false, false, false, false)
          end
        end
      end
    end
    md:yield()
  end
end)

script.register_looped("Purge", function(nosprg)
  if Game.Self.isDriving() then
    if nosPurge and validModel or nosPurge and is_bike then
      if PAD.IS_DISABLED_CONTROL_PRESSED(0, 73) and not is_in_flatbed then
        local dict       = "core"
        local purgeBones = { "suspension_lf", "suspension_rf" }
        if not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(dict) then
          STREAMING.REQUEST_NAMED_PTFX_ASSET(dict)
          coroutine.yield()
        end
        for _, boneName in ipairs(purgeBones) do
          local purge_exit = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, boneName)
          if boneName == "suspension_lf" then
            purge_rotZ = -180.0
            purge_posX = -0.3
          else
            purge_rotZ = 0.0
            purge_posX = 0.3
          end
          GRAPHICS.USE_PARTICLE_FX_ASSET(dict)
          purgePtfx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE("weap_extinguisher", current_vehicle,
            purge_posX, -0.33, 0.2, 0.0, -17.5, purge_rotZ, purge_exit, 0.4, false, false, false, 0, 0, 0)
          table.insert(purgePtfx_t, purgePtfx)
          purge_started = true
        end
        if purge_started then
          repeat
            nosprg:sleep(50)
          until
            PAD.IS_DISABLED_CONTROL_RELEASED(0, 73)
          for _, purge in ipairs(purgePtfx_t) do
            if GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(purge) then
              GRAPHICS.STOP_PARTICLE_FX_LOOPED(purge)
              GRAPHICS.REMOVE_PARTICLE_FX(purge)
              purge_started = false
            end
          end
        end
      end
    end
  else
    nosprg:yield()
  end
end)

script.register_looped("rgbLights", function(rgb)
  if start_rgb_loop then
    for i = 0, 14 do
      if start_rgb_loop and not VEHICLE.GET_BOTH_VEHICLE_HEADLIGHTS_DAMAGED(current_vehicle) then
        if not has_xenon then
          VEHICLE.TOGGLE_VEHICLE_MOD(current_vehicle, 22, true)
        end
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 0.9)
        rgb:sleep(100 / lightSpeed)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 0.8)
        rgb:sleep(100 / lightSpeed)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 0.7)
        rgb:sleep(100 / lightSpeed)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 0.6)
        rgb:sleep(100 / lightSpeed)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 0.5)
        rgb:sleep(100 / lightSpeed)
        VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(current_vehicle, i)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 0.4)
        rgb:sleep(100 / lightSpeed)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 0.3)
        rgb:sleep(100 / lightSpeed)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 0.2)
        rgb:sleep(100 / lightSpeed)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 0.1)
        rgb:sleep(100 / lightSpeed)
        VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(current_vehicle, i)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 0.2)
        rgb:sleep(100 / lightSpeed)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 0.3)
        rgb:sleep(100 / lightSpeed)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 0.4)
        rgb:sleep(100 / lightSpeed)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 0.5)
        rgb:sleep(100 / lightSpeed)
        VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(current_vehicle, i)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 0.6)
        rgb:sleep(100 / lightSpeed)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 0.7)
        rgb:sleep(100 / lightSpeed)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 0.8)
        rgb:sleep(100 / lightSpeed)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 0.9)
        rgb:sleep(100 / lightSpeed)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 1.0)
        VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(current_vehicle, i)
        rgb:sleep(100 / lightSpeed)
      else
        if has_xenon then
          VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 1.0)
          VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(current_vehicle, defaultXenon)
          break
        else
          VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(current_vehicle, 1.0)
          VEHICLE.TOGGLE_VEHICLE_MOD(current_vehicle, 22, false)
          break
        end
      end
    end
  else
    rgb:yield()
  end
end)

script.register_looped("no jacking", function(ctt)
  if noJacking then
    if not PED.GET_PED_CONFIG_FLAG(self.get_ped(), 398, 1) then
      PED.SET_PED_CAN_BE_DRAGGED_OUT(self.get_ped(), false)
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 398, true)
    end
    if not PED.GET_PED_CONFIG_FLAG(self.get_ped(), 177, 1) then
      PED.SET_PED_CAN_BE_DRAGGED_OUT(self.get_ped(), false)
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 177, true)
    end
  else
    if PED.GET_PED_CONFIG_FLAG(self.get_ped(), 398, 1) then
      PED.SET_PED_CAN_BE_DRAGGED_OUT(self.get_ped(), true)
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 398, false)
    end
    if PED.GET_PED_CONFIG_FLAG(self.get_ped(), 177, 1) then
      PED.SET_PED_CAN_BE_DRAGGED_OUT(self.get_ped(), true)
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 177, false)
    end
  end
  ctt:yield()
end)

-- Planes & Helis
script.register_looped("Unlimited Flares", function(flrs)
  flrs:yield()
  if flares_forall then
    if Game.Self.isDriving() and (is_plane or is_heli) then
      if PAD.IS_CONTROL_PRESSED(0, 356) and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(current_vehicle) then
        shoot_flares(flrs)
        flrs:sleep(3000)
      end
    end
  end
end)
script.register_looped("Real Jet Speed", function(rjspd)
  rjspd:yield()
  if real_plane_speed then
    if Game.Self.isDriving() and is_plane then
      local jet_increase
      local current_speed = ENTITY.GET_ENTITY_SPEED(current_vehicle)
      local jet_rotation  = ENTITY.GET_ENTITY_ROTATION(current_vehicle, 2)
      if jet_rotation.x >= 30 then
        jet_increase = 0.4
      elseif jet_rotation.x >= 60 then
        jet_increase = 0.8
      else
        jet_increase  = 0.21
      end
      -- wait for the plane to go over the low altitude speed limit then start increasing its top speed and don't go over 500km/h 
      -- (500km/h is fast and safe. Higher speeds break the game)
      if current_speed >= 73 and current_speed < 140 then
        if PAD.IS_CONTROL_PRESSED(0, 87) and VEHICLE.GET_LANDING_GEAR_STATE(current_vehicle) == 4 then
          VEHICLE.SET_VEHICLE_FORWARD_SPEED(current_vehicle, (current_speed + jet_increase))
        end
      end
    end
  end
end)

script.register_looped("flatbed script", function(script)
  local vehicleHandles  = entities.get_all_vehicles_as_handles()
  local current_vehicle = PED.GET_VEHICLE_PED_IS_USING(self.get_ped())
  local vehicle_model   = ENTITY.GET_ENTITY_MODEL(current_vehicle)
  local flatbedHeading  = ENTITY.GET_ENTITY_HEADING(current_vehicle)
  local flatbedBone     = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, "chassis")
  local playerPosition  = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
  local playerForwardX  = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
  local playerForwardY  = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
  for _, veh in ipairs(vehicleHandles) do
    local detectPos = vec3:new(playerPosition.x - (playerForwardX * 10), playerPosition.y - (playerForwardY * 10),
      playerPosition.z)
    local vehPos = ENTITY.GET_ENTITY_COORDS(veh, false)
    local vDist = SYSTEM.VDIST(detectPos.x, detectPos.y, detectPos.z, vehPos.x, vehPos.y, vehPos.z)
    if vDist <= 5 then
      closestVehicle = veh
    end
  end
  local closestVehicleModel = ENTITY.GET_ENTITY_MODEL(closestVehicle)
  local iscar   = VEHICLE.IS_THIS_MODEL_A_CAR(closestVehicleModel)
  local isbike  = VEHICLE.IS_THIS_MODEL_A_BIKE(closestVehicleModel)
  local towable = false
  if modelOverride then
    towable = true
  else
    towable = false
  end
  if iscar then
    towable = true
  end
  if isbike then
    towable = true
  end
  if closestVehicleModel == 745926877 then --Buzzard
    towable = true
  end
  if closestVehicleModel == 1353720154 then
    towable = false
  end
  if vehicle_model == 1353720154 then
    is_in_flatbed = true
  else
    is_in_flatbed = false
  end
  if is_in_flatbed and attached_vehicle == 0 then
    if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 73) and towable and closestVehicleModel ~= flatbedModel then
      script:sleep(200)
      controlled = entities.take_control_of(closestVehicle, 350)
      if controlled then
        local vehicleClass = VEHICLE.GET_VEHICLE_CLASS(closestVehicle)
        if vehicleClass == 1 then
          tow_zAxis = 0.9
          tow_yAxis = -2.3
        elseif vehicleClass == 2 then
          tow_zAxis = 0.993
          tow_yAxis = -2.17046
        elseif vehicleClass == 6 then
          tow_zAxis = 1.00069420
          tow_yAxis = -2.17046
        elseif vehicleClass == 7 then
          tow_zAxis = 1.009
          tow_yAxis = -2.17036
        elseif vehicleClass == 15 then
          tow_zAxis = 1.3
          tow_yAxis = -2.21069
        elseif vehicleClass == 16 then
          tow_zAxis = 1.5
          tow_yAxis = -2.21069
        else
          tow_zAxis = 1.1
          tow_yAxis = -2.0
        end
        ENTITY.SET_ENTITY_HEADING(closestVehicleModel, flatbedHeading)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(closestVehicle, current_vehicle, flatbedBone, 0.0, tow_yAxis, tow_zAxis, 0.0, 0.0, 0.0,
          false, true, true, false, 1, true, 1)
        attached_vehicle = closestVehicle
        script:sleep(200)
      else
        gui.show_error("Samurais Scripts", translateLabel("failed_veh_ctrl"))
      end
    end
    if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 73) and closestVehicle ~= nil and not towable then
      gui.show_message("Samurais Scripts", translateLabel("fltbd_carsOnlyTxt"))
      script:sleep(400)
    end
    if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 73) and closestVehicleModel == flatbedModel then
      script:sleep(400)
      gui.show_message("Samurais Scripts", translateLabel("fltbd_nootherfltbdTxt"))
    end
  elseif is_in_flatbed and attached_vehicle ~= 0 then
    if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 73) then
      script:sleep(200)
      for _, v in ipairs(vehicleHandles) do
        local modelHash         = ENTITY.GET_ENTITY_MODEL(v)
        local attachedVehicle   = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(current_vehicle, modelHash)
        local attachedVehcoords = ENTITY.GET_ENTITY_COORDS(attached_vehicle, false)
        controlled              = entities.take_control_of(attachedVehicle, 350)
        if ENTITY.DOES_ENTITY_EXIST(attachedVehicle) then
          if controlled then
            ENTITY.DETACH_ENTITY(attachedVehicle)
            ENTITY.SET_ENTITY_COORDS(attachedVehicle, attachedVehcoords.x - (playerForwardX * 10),
              attachedVehcoords.y - (playerForwardY * 10), playerPosition.z, 0, 0, 0, 0)
            VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(attached_vehicle, 5.0)
            attached_vehicle = 0
          end
        end
      end
    end
  end
end)
script.register_looped("TowPos Marker", function()
  if towPos then
    if is_in_flatbed and attached_vehicle == 0 then
      local playerPosition = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
      local playerForwardX = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
      local playerForwardY = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
      local detectPos      = vec3:new(playerPosition.x - (playerForwardX * 10), playerPosition.y - (playerForwardY * 10),
        playerPosition.z)
      GRAPHICS.DRAW_MARKER_SPHERE(detectPos.x, detectPos.y, detectPos.z, 2.5, 180, 128, 0, 0.115)
    end
  end
end)
script.register_looped("vehicle creator organizer", function()
  for k, v in ipairs(spawned_vehicles) do
    if not ENTITY.DOES_ENTITY_EXIST(v) then
      table.remove(spawned_vehicles, k)
      table.remove(spawned_vehNames, k)
      table.remove(filteredVehNames, k)
    end
  end

  for k, v in ipairs(veh_attachments) do
    if not ENTITY.DOES_ENTITY_EXIST(v.entity) then
      table.remove(veh_attachments, k)
    end
  end

  if main_vehicle ~= 0 then
    if not ENTITY.DOES_ENTITY_EXIST(main_vehicle) then
      main_vehicle = 0
    end
  end
end)


-- World
script.register_looped("Ped Grabber", function(pg)
  if pedGrabber and not vehicleGrabber then
    if Game.Self.isOnFoot() and not gui.is_open() and not WEAPON.IS_PED_ARMED(self.get_ped(), 7) then
      local nearestPed = Game.getClosestPed(self.get_ped(), 10)
      local myGroup    = PED.GET_PED_GROUP_INDEX(self.get_ped())
      if not ped_grabbed and nearestPed ~= 0 then
        if PED.IS_PED_ON_FOOT(nearestPed) and not PED.IS_PED_A_PLAYER(nearestPed) and not PED.IS_PED_GROUP_MEMBER(nearestPed, myGroup) then
          if PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 257) then
            ped_grabbed, attached_ped = attachPed(nearestPed)
            pg:sleep(200)
            if attached_ped ~= 0 then
              playHandsUp()
              ENTITY.FREEZE_ENTITY_POSITION(attached_ped, true)
              PED.SET_PED_CAN_SWITCH_WEAPON(self.get_ped(), false)
              ped_grabbed = true
            end
          end
        end
      end
      if ped_grabbed and attached_ped ~= 0 then
        PED.FORCE_PED_MOTION_STATE(attached_ped, 0x0EC17E58, 0, 0, 0)
        if not ENTITY.IS_ENTITY_PLAYING_ANIM(self.get_ped(), "mp_missheist_countrybank@lift_hands", "lift_hands_in_air_outro", 3) then
          playHandsUp()
        end
        if PED.IS_PED_RAGDOLL(self.get_ped()) then
          repeat
            pg:sleep(100)
          until PED.IS_PED_RAGDOLL(self.get_ped()) == false
          playHandsUp()
        end
        if PED.IS_PED_USING_ACTION_MODE(self.get_ped()) then
          repeat
            pg:sleep(100)
          until PED.IS_PED_USING_ACTION_MODE(self.get_ped()) == false
          playHandsUp()
        end
        if PAD.IS_DISABLED_CONTROL_PRESSED(0, 25) then
          if PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 257) then
            local myFwdX = Game.getForwardX(self.get_ped())
            local myFwdY = Game.getForwardY(self.get_ped())
            ENTITY.FREEZE_ENTITY_POSITION(attached_ped, false)
            ENTITY.DETACH_ENTITY(attached_ped, true, true)
            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(attached_ped, false)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(attached_ped, false)
            PED.SET_PED_TO_RAGDOLL(attached_ped, 1500, 0, 0, false)
            ENTITY.SET_ENTITY_VELOCITY(attached_ped, (pedthrowF * myFwdX), (pedthrowF * myFwdY), 0)
            TASK.CLEAR_PED_TASKS(self.get_ped())
            PED.SET_PED_CAN_SWITCH_WEAPON(self.get_ped(), true)
            pg:sleep(200)
            attached_ped = 0
            ped_grabbed  = false
          end
        end
      end
    end
  end
  pg:yield()
end)

script.register_looped("Vehicle Grabber", function(vg)
  if vehicleGrabber and not pedGrabber then
    if Game.Self.isOnFoot() and not gui.is_open() and not WEAPON.IS_PED_ARMED(self.get_ped(), 7) then
      local nearestVeh = Game.getClosestVehicle(self.get_ped(), 10)
      if not vehicle_grabbed and nearestVeh ~= 0 then
        if PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 257) then
          vehicle_grabbed, grabbed_veh = attachVeh(nearestVeh)
          vg:sleep(200)
          if grabbed_veh ~= 0 then
            playHandsUp()
            PED.SET_PED_CAN_SWITCH_WEAPON(self.get_ped(), false)
            vehicle_grabbed = true
          end
        end
      end
      if vehicle_grabbed and grabbed_veh ~= 0 then
        if not ENTITY.IS_ENTITY_PLAYING_ANIM(self.get_ped(), "mp_missheist_countrybank@lift_hands", "lift_hands_in_air_outro", 3) then
          playHandsUp()
        end
        if PED.IS_PED_RAGDOLL(self.get_ped()) then
          repeat
            vg:sleep(100)
          until PED.IS_PED_RAGDOLL(self.get_ped()) == false
          playHandsUp()
        end
        if PED.IS_PED_USING_ACTION_MODE(self.get_ped()) then
          repeat
            vg:sleep(100)
          until PED.IS_PED_USING_ACTION_MODE(self.get_ped()) == false
          playHandsUp()
        end
        if PAD.IS_DISABLED_CONTROL_PRESSED(0, 25) then
          if PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 257) then
            local myFwdX = Game.getForwardX(self.get_ped())
            local myFwdY = Game.getForwardY(self.get_ped())
            ENTITY.DETACH_ENTITY(grabbed_veh, true, true)
            ENTITY.SET_ENTITY_VELOCITY(grabbed_veh, (pedthrowF * myFwdX), (pedthrowF * myFwdY), 0)
            TASK.CLEAR_PED_TASKS(self.get_ped())
            PED.SET_PED_CAN_SWITCH_WEAPON(self.get_ped(), true)
            vg:sleep(200)
            grabbed_veh     = 0
            vehicle_grabbed = false
          end
        end
      end
    end
  end
  vg:yield()
end)

script.register_looped("Carpool", function(cp)
  if carpool then
    if PED.IS_PED_SITTING_IN_ANY_VEHICLE(self.get_ped()) then
      stop_searching = true
    else
      stop_searching = false
    end
    if not stop_searching then
      nearestVeh = Game.getClosestVehicle(self.get_ped(), 10)
    end
    local trying_to_enter = PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(self.get_ped())
    if trying_to_enter ~= 0 and trying_to_enter == nearestVeh then
      driverPed = VEHICLE.GET_PED_IN_VEHICLE_SEAT(trying_to_enter, -1, true)
      if driverPed ~= nil and driverPed ~= self.get_ped() and not PED.IS_PED_A_PLAYER(driverPed) then
        thisVeh = trying_to_enter
        PED.SET_PED_CONFIG_FLAG(driverPed, 251, true)
        PED.SET_PED_CONFIG_FLAG(driverPed, 255, true)
        PED.SET_PED_CONFIG_FLAG(driverPed, 398, true)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driverPed, true)
      end
    end
    if PED.IS_PED_SITTING_IN_VEHICLE(self.get_ped(), thisVeh) then
      local ped_to_reset = VEHICLE.GET_PED_IN_VEHICLE_SEAT(thisVeh, -1, true)
      if ped_to_reset ~= nil and ped_to_reset ~= self.get_ped() and not PED.IS_PED_A_PLAYER(ped_to_reset) then
        if VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(thisVeh) > 1 then
          show_npc_veh_ctrls = true
        end
        stop_searching     = true
        repeat
          cp:sleep(100)
        until PED.IS_PED_SITTING_IN_VEHICLE(self.get_ped(), thisVeh) == false
        PED.SET_PED_CONFIG_FLAG(ped_to_reset, 251, false)
        PED.SET_PED_CONFIG_FLAG(ped_to_reset, 255, false)
        PED.SET_PED_CONFIG_FLAG(ped_to_reset, 398, false)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped_to_reset, false)
        show_npc_veh_ctrls = false
        stop_searching     = false
      else
        show_npc_veh_ctrls = false
      end
    end
  end
  cp:yield()
end)

-- object spawner
script.register_looped("Preview", function(preview)
  if previewLoop and gui.is_open() then
    local currentHeading = ENTITY.GET_ENTITY_HEADING(previewEntity)
    if currentObjectPreview ~= previewEntity then
      ENTITY.DELETE_ENTITY(previewEntity)
      previewStarted = false
    end
    if isChanged then
      ENTITY.DELETE_ENTITY(previewEntity)
      previewStarted = false
    end
    if not ENTITY.IS_ENTITY_DEAD(self.get_ped()) then
      while not STREAMING.HAS_MODEL_LOADED(propHash) do
        STREAMING.REQUEST_MODEL(propHash)
        coroutine.yield()
      end
      if not previewStarted then
        previewEntity = OBJECT.CREATE_OBJECT(propHash, coords.x + forwardX * 5, coords.y + forwardY * 5, coords.z,
          currentHeading, false, false, false)
        ENTITY.SET_ENTITY_ALPHA(previewEntity, 200.0, false)
        ENTITY.SET_ENTITY_COLLISION(previewEntity, false, false)
        ENTITY.SET_ENTITY_CAN_BE_DAMAGED(previewEntity, false)
        ENTITY.SET_ENTITY_PROOFS(previewEntity, true, true, true, true, true, true, true, true)
        ENTITY.SET_CAN_CLIMB_ON_ENTITY(previewEntity, false)
        OBJECT.SET_OBJECT_ALLOW_LOW_LOD_BUOYANCY(previewEntity, false)
        currentObjectPreview = ENTITY.GET_ENTITY_MODEL(previewEntity)
        previewStarted = true
      end
      if PED.IS_PED_STOPPED(self.get_ped()) then
        while true do
          preview:yield()
          if gui.is_open() and object_spawner:is_selected() then
            currentHeading = currentHeading + 1
            ENTITY.SET_ENTITY_HEADING(previewEntity, currentHeading)
            preview:sleep(10)
            if currentObjectPreview ~= ENTITY.GET_ENTITY_MODEL(previewEntity) then
              ENTITY.DELETE_ENTITY(previewEntity)
              previewStarted = false
            end
            if not PED.IS_PED_STOPPED(self.get_ped()) or not previewStarted then
              previewStarted = false
              break
            end
          else
            ENTITY.DELETE_ENTITY(previewEntity)
            previewStarted = false
          end
        end
      else
        return
      end
    end
  else
    ENTITY.DELETE_ENTITY(previewEntity)
    stopPreview()
  end
end)
script.register_looped("edit mode", function()
  if spawned_props[1] ~= nil then
    if edit_mode and selfAttachments[1] == nil and vehAttachments[1] == nil then
      local current_coords   = ENTITY.GET_ENTITY_COORDS(selectedObject)
      local current_rotation = ENTITY.GET_ENTITY_ROTATION(selectedObject, 2)
      if activeX then
        ENTITY.SET_ENTITY_COORDS(selectedObject, current_coords.x + spawnDistance.x, current_coords.y, current_coords.z)
      end
      if activeY then
        ENTITY.SET_ENTITY_COORDS(selectedObject, current_coords.x, current_coords.y + spawnDistance.y, current_coords.z)
      end
      if activeZ then
        ENTITY.SET_ENTITY_COORDS(selectedObject, current_coords.x, current_coords.y, current_coords.z + spawnDistance.z)
      end
      if rotX then
        ENTITY.SET_ENTITY_ROTATION(selectedObject, current_rotation.x + spawnRot.x, current_rotation.y,
          current_rotation.z, 2, true)
      end
      if rotY then
        ENTITY.SET_ENTITY_ROTATION(selectedObject, current_rotation.x, current_rotation.y + spawnRot.y,
          current_rotation.z, 2, true)
      end
      if rotZ then
        ENTITY.SET_ENTITY_ROTATION(selectedObject, current_rotation.x, current_rotation.y,
          current_rotation.z + spawnRot.z, 2, true)
      end
    end
    for k, v in ipairs(spawned_props) do
      if not ENTITY.DOES_ENTITY_EXIST(v) then
        table.remove(spawned_props, k)
      end
    end
  end
  if selfAttachments[1] ~= nil then
    for index, entity in ipairs(selfAttachments) do
      if not ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(entity, self.get_ped()) then
        table.remove(selfAttachments, index)
      end
    end
  end
  if vehAttachments[1] ~= nil then
    for index, entity in ipairs(vehAttachments) do
      if not ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(entity, lastVeh) then
        table.remove(vehAttachments, index)
      end
    end
  end
end)

script.register_looped("KamikazeDrivers", function (rd)
  if kamikazeDrivers and Game.Self.isAlive() then
    local gta_peds = entities.get_all_peds_as_handles()
    local myGroup  = PED.GET_PED_GROUP_INDEX(self.get_ped())
    for _, ped in pairs(gta_peds) do
      if ped ~= self.get_ped() and not PED.IS_PED_A_PLAYER(ped) and not PED.IS_PED_GROUP_MEMBER(ped, myGroup) then
        if PED.IS_PED_SITTING_IN_ANY_VEHICLE(ped) then
          local ped_veh = PED.GET_VEHICLE_PED_IS_USING(ped)
          if VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(ped_veh) then
            if VEHICLE.IS_VEHICLE_STOPPED(ped_veh) then
              TASK.TASK_VEHICLE_TEMP_ACTION(ped, ped_veh, 23, 1000)
            end
            if ENTITY.GET_ENTITY_SPEED(ped_veh) > 1.8 and ENTITY.GET_ENTITY_SPEED(ped_veh) < 70 then
              if VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(ped_veh) and not ENTITY.IS_ENTITY_DEAD(ped) then
                VEHICLE.SET_VEHICLE_BRAKE(ped_veh, false)
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(ped_veh, (ENTITY.GET_ENTITY_SPEED(ped_veh) + 0.7))
              end
            end
          end
        end
      end
    end
  end
  rd:yield()
end)

script.register_looped("Public Enemy", function (pe)
  if publicEnemy and Game.Self.isAlive() then
    local myGroup  = PED.GET_PED_GROUP_INDEX(self.get_ped())
    local gta_peds = entities.get_all_peds_as_handles()
    for _, ped in pairs(gta_peds) do
      if ped ~= self.get_ped() and not PED.IS_PED_A_PLAYER(ped) and not PED.IS_PED_GROUP_MEMBER(ped, myGroup) then
        for _, attr in ipairs(pe_combat_attributes_T) do
          PED.SET_PED_COMBAT_ATTRIBUTES(ped, attr.id, attr.bool)
        end
        if not PED.IS_PED_IN_COMBAT(ped, self.get_ped()) then
          PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
          for _, cflg in ipairs(pe_config_flags_T) do
            if not PED.GET_PED_CONFIG_FLAG(ped, cflg.id, cflg.bool) then
              PED.SET_PED_CONFIG_FLAG(ped, cflg.id, cflg.bool)
            end
          end
          TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
          PLAYER.SET_POLICE_IGNORE_PLAYER(self.get_id(), true)
          PLAYER.SET_MAX_WANTED_LEVEL(0)
          TASK.TASK_COMBAT_PED(ped, self.get_ped(), 0, 16)
        end
      end
    end
  end
  pe:yield()
end)

---online

-- Casino Pacino
script.register_looped("Casino Pacino Thread", function(pacino)
  if Game.isOnline() then
    if force_poker_cards then
      local player_id = PLAYER.PLAYER_ID()
      if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("three_card_poker")) ~= 0 then
        while NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", -1, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 0, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 1, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 2, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 3, 0) ~= player_id do 
          network.force_script_host("three_card_poker")
          gui.show_message("CasinoPacino", "Taking control of the three_card_poker script.") --If you see this spammed, someone if fighting you for control.
          pacino:sleep(500)
        end
        local players_current_table = locals.get_int("three_card_poker", three_card_poker_table + 1 + (player_id * three_card_poker_table_size) + 2) --The Player's current table he is sitting at.
        if (players_current_table ~= -1) then -- If the player is sitting at a poker table
          local player_0_card_1 = locals.get_int("three_card_poker", (three_card_poker_cards) + (three_card_poker_current_deck) + (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (1) + (0 * 3))
          local player_0_card_2 = locals.get_int("three_card_poker", (three_card_poker_cards) + (three_card_poker_current_deck) + (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (2) + (0 * 3))
          local player_0_card_3 = locals.get_int("three_card_poker", (three_card_poker_cards) + (three_card_poker_current_deck) + (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (3) + (0 * 3))
          if player_0_card_1 ~= 50 or player_0_card_2 ~= 51 or player_0_card_3 ~= 52 then --Check if we need to overwrite the deck.
            local total_players = 0
            for player_iter = 0, 31, 1 do
              local player_table = locals.get_int("three_card_poker", three_card_poker_table + 1 + (player_iter * three_card_poker_table_size) + 2)
              if player_iter ~= player_id and player_table == players_current_table then --An additional player is sitting at the user's table.
                total_players = total_players + 1
              end
            end
            for playing_player_iter = 0, total_players, 1 do
              set_poker_cards(playing_player_iter, players_current_table, 50, 51, 52)
            end
            if set_dealers_poker_cards then
              set_poker_cards(total_players + 1, players_current_table, 1, 8, 22)
            end
          end
        end
      end
    end

    if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("blackjack")) ~= 0 then
      local dealers_card = 0
      local blackjack_table = locals.get_int("blackjack", blackjack_table_players + 1 + (PLAYER.PLAYER_ID() * blackjack_table_players_size) + 4) --The Player's current table he is sitting at.
      if blackjack_table ~= -1 then
        dealers_card     = locals.get_int("blackjack", blackjack_cards + blackjack_decks + 1 + (blackjack_table * 13) + 1) --Dealer's facedown card.
        dealers_card_str = get_cardname_from_index(dealers_card)
      else
        dealers_card_str = "Not sitting at a Blackjack table."
      end
    else
        dealers_card_str = "Not in Casino."
    end

    if force_roulette_wheel then
      local player_id = PLAYER.PLAYER_ID()
      if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("casinoroulette")) ~= 0 then
        while NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", -1, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 0, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 1, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 2, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 3, 0) ~= player_id do 
          network.force_script_host("casinoroulette")
          gui.show_message("CasinoPacino", "Taking control of the casinoroulette script.") --If you see this spammed, someone if fighting you for control.
          script:sleep(500)
        end
        for tabler_iter = 0, 6, 1 do
          locals.set_int("casinoroulette", (roulette_master_table) + (roulette_outcomes_table) + (roulette_ball_table) + (tabler_iter), 18)
        end
      end
    end

    if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("casino_slots")) ~= 0 then
      local needs_run = false
      if rig_slot_machine then
        for slots_iter = 3, 196, 1 do
          if slots_iter ~= 67 and slots_iter ~= 132 then
            if locals.get_int("casino_slots", (slots_random_results_table) + (slots_iter)) ~= 6 then
              needs_run = true
            end
          end
        end
      else
        local sum = 0
        for slots_iter = 3, 196, 1 do
          if slots_iter ~= 67 and slots_iter ~= 132 then
            sum = sum + locals.get_int("casino_slots", (slots_random_results_table) + (slots_iter))
          end
        end
        needs_run = sum == 1152
      end
      if needs_run then
        for slots_iter = 3, 196, 1 do
          if slots_iter ~= 67 and slots_iter ~= 132 then
            local slot_result = 6
            if not rig_slot_machine then
              math.randomseed(os.time() + slots_iter)
              slot_result = math.random(0, 7)
            end
            locals.set_int("casino_slots", (slots_random_results_table) + (slots_iter), slot_result)
          end
        end
      end
      if autoplay_slots then
        local slotstate = locals.get_int("casino_slots", slots_slot_machine_state) --Local Laddie️™®️© is a product of Limited Laddies LLC, all rights reserved.
        if slotstate & (1 << 0) == 1 then --The user is sitting at a slot machine.
          local chips = stats.get_int('MPX_CASINO_CHIPS')
          local chip_cap = autoplay_chips_cap
          if (autoplay_cap and chips < chip_cap) or not autoplay_cap then
            if (slotstate & (1 << 24) == 0) then --The slot machine is not currently spinning.
              script:yield() -- Wait for the previous spin to clean up, if we just came from a spin.
              slotstate = slotstate | (1 << 3) -- Bitwise set the 3rd bit (begin playing)
              locals.set_int("casino_slots", slots_slot_machine_state, slotstate)
              script:sleep(500) --If we rewrite the begin playing bit again, the machine will get stuck.
            end
          end
        end
      end
    end
    if bypass_casino_bans then
      stats.set_int("MPPLY_CASINO_CHIPS_WON_GD", 0)
      stats.set_int("MPPLY_CASINO_CHIPS_WONTIM", 0)
      stats.set_int("MPPLY_CASINO_GMBLNG_GD", 0)
      stats.set_int("MPPLY_CASINO_BAN_TIME", 0)
      stats.set_int("MPPLY_CASINO_CHIPS_PURTIM", 0)
      stats.set_int("MPPLY_CASINO_CHIPS_PUR_GD", 0)
      stats.set_int("MPPLY_CASINO_CHIPS_SOLD", 0)
      stats.set_int("MPPLY_CASINO_CHIPS_SELTIM", 0)
    end
    if gui.is_open() and casino_pacino:is_selected() then
      casino_heist_approach      = stats.get_int("MPX_H3OPT_APPROACH")
      casino_heist_target        = stats.get_int("MPX_H3OPT_TARGET")
      casino_heist_last_approach = stats.get_int("MPX_H3_LAST_APPROACH")
      casino_heist_hard          = stats.get_int("MPX_H3_HARD_APPROACH")
      casino_heist_gunman        = stats.get_int("MPX_H3OPT_CREWWEAP")
      casino_heist_driver        = stats.get_int("MPX_H3OPT_CREWDRIVER")
      casino_heist_hacker        = stats.get_int("MPX_H3OPT_CREWHACKER")
      casino_heist_weapons       = stats.get_int("MPX_H3OPT_WEAPS")
      casino_heist_cars          = stats.get_int("MPX_H3OPT_VEHS")
      casino_heist_masks         = stats.get_int("MPX_H3OPT_MASKS")
      local cooldown_time        = tunables.get_int("VC_CASINO_CHIP_MAX_WIN_LOSS_COOLDOWN")
      local time_delta           = os.time() - stats.get_int("MPPLY_CASINO_CHIPS_WONTIM") --"I've won the jackpot, and it doesn't make me feel bad." ~Casino Pacino (He only cares about winners)
      local minutes_left         = (cooldown_time - time_delta) / 60
      local chipswon_gd          = stats.get_int("MPPLY_CASINO_CHIPS_WON_GD")
      local max_chip_wins        = tunables.get_int("VC_CASINO_CHIP_MAX_WIN_DAILY")
      casino_cooldown_update_str = (chipswon_gd >= max_chip_wins and "Cooldown expires in approximately: " .. string.format("%.2f", minutes_left) .. " minute(s)." or "Off Cooldown")
    end
    if fm_mission_controller_cart_autograb then
      if locals.get_int("fm_mission_controller", fm_mission_controller_cart_grab) == 3 then
        locals.set_int("fm_mission_controller", fm_mission_controller_cart_grab, 4)
      elseif locals.get_int("fm_mission_controller", fm_mission_controller_cart_grab) == 4 then
        locals.set_float("fm_mission_controller", fm_mission_controller_cart_grab + fm_mission_controller_cart_grab_speed, 2)
      end
    end
  end
end)

script.register_looped("Online Player Info", function()
  if Game.isOnline() and gui.is_open() and players_tab:is_selected() then
    playerCount       = Game.getPlayerCount()
    selectedPlayer    = filteredPlayers[playerIndex + 1]
    targetPlayerPed   = selectedPlayer
    targetPlayerIndex = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(targetPlayerPed)
    player_name       = PLAYER.GET_PLAYER_NAME(targetPlayerIndex)
    if NETWORK.NETWORK_IS_PLAYER_ACTIVE(targetPlayerIndex) then
      player_active = true
      playerWallet  = Game.getPlayerWallet(targetPlayerIndex)
      playerBank    = Game.getPlayerBank(targetPlayerIndex)
      playerCoords  = Game.getCoords(targetPlayerPed, false)
      playerHeading = math.floor(Game.getHeading(targetPlayerPed))
      playerHealth  = ENTITY.GET_ENTITY_HEALTH(targetPlayerPed)
      playerArmour  = PED.GET_PED_ARMOUR(targetPlayerPed)
      godmode       = PLAYER.GET_PLAYER_INVINCIBLE(targetPlayerIndex)
      if PED.IS_PED_SITTING_IN_ANY_VEHICLE(targetPlayerPed) then
        player_in_veh = true
        playerVeh = PED.GET_VEHICLE_PED_IS_IN(targetPlayerPed, true)
      else
        player_in_veh = false
      end
    else
      player_active = false
    end
  end
end)


--[[
   *event handlers*
]]
event.register_handler(menu_event.MenuUnloaded, function()
  SS_handle_events()
end)

event.register_handler(menu_event.ScriptsReloaded, function()
  SS_handle_events()
end)