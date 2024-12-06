---@diagnostic disable: undefined-global, lowercase-global, undefined-doc-name, undefined-field

local gvov                  = memory.scan_pattern("8B C3 33 D2 C6 44 24 20")
local game_build_offset     = gvov:add(0x24):rip()
local online_version_offset = game_build_offset:add(0x20)

--#region Global functions

-- Must be called from inside a coroutine. Input time is in seconds.
---@param s integer
function sleep(s)
  local ntime = os.clock() + s
  repeat
    coroutine.yield()
  until
    os.clock() > ntime
end

---@param ... number
---@return number
sum = function(...)
  local args, result = { ... }, 0
  for i = 1, #args do
    if type(args[i]) ~= 'number' then
      error(string.format(
        "Invalid argument '%s' at position (%d) in function sum(). The function only takes numbers as parameters.",
        args[i], i
      ))
    end
    result = result + args[i]
  end
  return result
end

local logMsg = true
-- Translates text to the user's language.
--
-- If the label to translate is missing or the language 
--
-- is invalid, it defaults to English (US).
---@param g string
function translateLabel(g)
  ---@type string
  local retStr
  if Labels[g] then
    for _, v in pairs(Labels[g]) do
      if LANG == v.iso then
        retStr = v.text
        break
      end
    end
    -- Replace "---" and "___" placeholders with button names.
    if retStr ~= nil and retStr ~= "" then
      for _, tr in ipairs(translations_button_map) do
        if tr.name == g then
          if Lua_fn.str_contains(retStr, "___") then
            retStr = Lua_fn.str_replace(retStr, "___", tr.kbm)
          end
          if Lua_fn.str_contains(retStr, "---") then
            retStr = Lua_fn.str_replace(retStr, "---", tr.gpad)
          end
        end
      end
    else
      if logMsg then
        gui.show_warning("Samurai's Scripts",
          "Unsupported language or missing label(s) detected! Defaulting to English.")
        log.warning("Unsupported language or missing label(s) detected! Defaulting to English.")
        retStr = Labels[g][1].text
        logMsg = false
      end
      SS.debug('Missing: ' .. Labels[g][1].text)
    end
  else
    retStr = string.format("%s [MISSING LABEL!]", g)
  end
  return retStr ~= nil and retStr or string.format("%s [MISSING LABEL!]", g)
end

-- Translate all strings once instead
--
-- of calling `translateLabel()` inside the
--
-- GUI loop like a god damn retard.
function initStrings()
  -- Generic
  GENERIC_PLAY_BTN_          = translateLabel("generic_play_btn")
  GENERIC_STOP_BTN_          = translateLabel("generic_stop_btn")
  GENERIC_OPEN_BTN_          = translateLabel("openBtn")
  GENERIC_CLOSE_BTN_         = translateLabel("closeBtn")
  GENERIC_SAVE_BTN_          = translateLabel("saveBtn")
  GENERIC_SPAWN_BTN_         = translateLabel("Spawn")
  GENERIC_ATTACH_BTN_        = translateLabel("attachBtn")
  GENERIC_DELETE_BTN_        = translateLabel("generic_delete")
  GENERIC_RESET_BTN_         = translateLabel("generic_reset")
  GENERIC_CONFIRM_BTN_       = translateLabel("generic_confirm_btn")
  GENERIC_CLEAR_BTN_         = translateLabel("generic_clear_btn")
  GENERIC_CANCEL_BTN_        = translateLabel("generic_cancel_btn")
  GENERIC_DETACH_BTN_        = translateLabel("detachBtn")
  GENERIC_YES_               = translateLabel("yes")
  GENERIC_NO_                = translateLabel("NO")
  GENERIC_SEARCH_HINT_       = translateLabel("search_hint")
  GENERIC_VEH_DELETE_ERROR_  = translateLabel("generic_veh_delete_fail")
  GENERIC_MULTIPLIER_LABEL_  = translateLabel("generic_multiplier_label")
  GENERIC_UNAVAILABLE_SP_    = translateLabel("Unavailable in Single Player")
  GENERIC_CUSTOM_LABEL_      = translateLabel("generic_custom_label")
  -- Self
  SELF_TAB_           = translateLabel("Self")
  AUTOHEAL_           = translateLabel("Auto-Heal")
  AUTOHEAL_DESC_      = translateLabel("autoheal_tt")
  OBJECTIVETP_        = translateLabel("objectiveTP")
  OBJECTIVETP_DESC_   = translateLabel("objectiveTP_tt")
  CROUCHCB_           = translateLabel("CrouchCB")
  CROUCH_DESC_        = translateLabel("Crouch_tt")
  REPLACE_PA_CB_      = translateLabel("rpaCB")
  REPLACE_PA_DESC_    = translateLabel("rpa_tt")
  PHONEANIMS_CB_      = translateLabel("PhoneAnimCB")
  PHONEANIMS_DESC_    = translateLabel("PhoneAnim_tt")
  SPRINT_INSIDE_CB_   = translateLabel("SprintInsideCB")
  SPRINT_INSIDE_DESC_ = translateLabel("SprintInside_tt")
  LOCKPICK_CB_        = translateLabel("LockpickCB")
  LOCKPICK_DESC_      = translateLabel("Lockpick_tt")
  ACTION_MODE_CB_     = translateLabel("ActionModeCB")
  ACTION_MODE_DESC_   = translateLabel("ActionMode_tt")
  CLUMSY_DESC_        = translateLabel("clumsy_tt")
  ROD_DESC_           = translateLabel("rod_tt")
  RAGDOLL_SOUND_DESC_ = translateLabel("ragdoll_sound_tt")
  HIDENSEEK_DESC_     = translateLabel("hide&seek_tt")
  -- Sound Player
  SOUND_PLAYER_        = translateLabel("soundplayer")
  MALE_SOUNDS_         = translateLabel("malesounds")
  FEMALE_SOUNDS_       = translateLabel("femalesounds")
  RADIO_STATIONS_DESC_ = translateLabel("radioStations_tt")
  -- Animations
  ANIMATIONS_TAB_    = translateLabel("animations")
  ANIM_FLAGS_DESC_   = translateLabel("flags_tt")
  ANIM_PROPS_DESC_   = translateLabel("DisableProps_tt")
  ANIM_CONTROL_CB_   = translateLabel("Allow Control")
  ANIM_CONTROL_DESC_ = translateLabel("AllowControl_tt")
  ANIM_LOOP_DESC_    = translateLabel("looped_tt")
  ANIM_UPPER_CB_     = translateLabel("Upper Body Only")
  ANIM_UPPER_DESC_   = translateLabel("UpperBodyOnly_tt")
  ANIM_FREEZE_CB_    = translateLabel("Freeze")
  ANIM_FREEZE_DESC_  = translateLabel("Freeze_tt")
  ANIM_NO_COLL_CB_   = translateLabel("nocoll_cb")
  ANIM_NO_COLL_DESC_ = translateLabel("nocoll_tt")
  ANIM_KOE_CB_       = translateLabel("koe_cb")
  ANIM_KOE_DESC_     = translateLabel("koe_tt")
  ANIM_GRAB_ERROR_   = translateLabel("You can not play animations while grabbing an NPC.")
  ANIM_STOP_DESC_    = translateLabel("stopAnims_tt")
  ANIM_DETACH_BTN_   = translateLabel("Remove Attachments")
  ANIM_DETACH_DESC_  = translateLabel("RemoveAttachments_tt")
  ANIM_HOTKEYS_DESC_ = translateLabel("animKeys_tt")
  MVMT_OPTIONS_TXT_  = translateLabel("Movement Options:")
  ANIM_HOTKEY_BTN_   = translateLabel("animShortcut_btn")
  ANIM_HOTKEY_DESC_  = translateLabel("animShortcut_tt")
  ANIM_HOTKEY_DEL_   = translateLabel("removeShortcut_btn")
  ANIM_HOTKEY_DEL2_  = translateLabel("removeShortcut_btn2")
  DEL_HOTKEY_DESC_   = translateLabel("removeShortcut_tt")
  NO_HOTKEY_TXT_     = translateLabel("no_shortcut_tt")
  INPUT_WAIT_TXT_    = translateLabel("input_waiting")
  HOTKEY_RESERVED_   = translateLabel("reserved_button")
  HOTKEY_SUCCESS1_   = translateLabel("shortcut_success_1/2")
  HOTKEY_SUCCESS2_   = translateLabel("shortcut_success_2/2")
  NPC_ANIMS_TXT_     = translateLabel("Play Animations On NPCs:")
  NPC_GODMODE_DESC_  = translateLabel("Spawn NPCs in God Mode.")
  SCENARIOS_TAB_     = translateLabel("scenarios")
  SCN_GRAB_ERROR_    = translateLabel("You can not play scenarios while grabbing an NPC.")
  SCN_STOP_DESC_     = translateLabel("stopScenarios_tt")
  SCN_STOP_SPINNER_  = translateLabel("scenarios_spinner")
  NPC_SCENARIOS_     = translateLabel("Play Scenarios On NPCs:")
  ADD_TO_FAVS_       = translateLabel("add_to_favs")
  REMOVE_FROM_FAVS_  = translateLabel("remove_from_favs")
  FAVORITES_TAB_     = translateLabel("favs_tab")
  FAVS_NIL_TXT_      = translateLabel("favs_nil_txt")
  RECENTS_TAB_       = translateLabel("recents_tab")
  RECENTS_NIL_TXT_   = translateLabel("recents_nil_txt")
  -- Weapons
  WEAPON_TAB_        = translateLabel("weaponTab")
  HASHGRABBER_CB_    = translateLabel("hashgrabberCB")
  HASHGRABBER_DESC_  = translateLabel("hashgrabber_tt")
  TRIGGERBOT_CB_     = translateLabel("triggerbotCB")
  TRIGGERBOT_DESC_   = translateLabel("triggerbot_tt")
  ENEMY_ONLY_CB_     = translateLabel("enemyonlyCB")
  AUTOKILL_CB_       = translateLabel("autokillCB")
  AUTOKILL_DESC_     = translateLabel("autokill_tt")
  ENEMIES_FLEE_CB_   = translateLabel("runawayCB")
  ENEMIES_FLEE_DESC_ = translateLabel("runaway_tt")
  KATANA_CB_         = translateLabel("katanaCB")
  KATANA_DESC_       = translateLabel("katana_tt")
  LASER_SIGHT_CB_    = translateLabel("laserSightCB")
  LASER_SIGHT_DESC_  = translateLabel("laserSight_tt")
  LASER_CHOICE_TXT_  = translateLabel("laserChoice_txt")
  -- Vehicle
  VEHICLE_TAB_             = translateLabel("vehicleTab")
  GET_IN_VEH_WARNING_      = translateLabel("getinveh")
  -- Custom Paint Jobs
  SORT_BY_TXT_       = translateLabel("sort_by_txt")
  SORT_BY_COLOR_TXT_ = translateLabel("color_txt")
  SORT_BY_MFR_TXT_   = translateLabel("manufacturer_txt")
  REMOVE_MATTE_CB_   = translateLabel("remove_matte_CB")
  APPLY_MATTE_CB_    = translateLabel("apply_matte_CB")
  APPLY_MATTE_DESC_  = translateLabel("apply_matte_tt")
  SAVE_PAINT_DESC_   = translateLabel("save_paint_tt")
  -- Drift tab
  DRIFT_MODE_CB_           = translateLabel("driftModeCB")
  DRIFT_MODE_DESC_         = translateLabel("driftMode_tt")
  DRIFT_SLIDER_            = translateLabel("driftSlider")
  DRIFT_SLIDER_DESC        = translateLabel("driftSlider_tt")
  DRIFT_SMOKE_COL_         = translateLabel("driftSmokeCol")
  DRIFT_SMOKE_COL_DESC_    = translateLabel("DriftSmoke_tt")
  HEX_SMOKE_DESC_          = translateLabel("hex_tt")
  DRIFT_TIRES_CB_          = translateLabel("driftTiresCB")
  DRIFT_TIRES_DESC_        = translateLabel("driftTires_tt")
  DRIFT_TORQUE_DESC_       = translateLabel("driftToruqe_tt")
  DRIFT_GAME_DESC_         = translateLabel("DriftGame_tt")
  DRIFT_INVALID_DESC_      = translateLabel("driftInvalidVehTxt")
  LIMIT_OPTIONS_CB_        = translateLabel("lvoCB")
  LIMIT_OPTIONS_DESC_      = translateLabel("lvo_tt")
  MISSILE_DEF_DESC_        = translateLabel("missile_def_tt")
  MISSILE_DEF_ON_          = translateLabel("missile_def_on_notif")
  MISSILE_DEF_OFF_         = translateLabel("missile_def_off_notif")
  LAUNCH_CTRL_DESC_        = translateLabel("lct_tt")
  NOS_DESC_                = translateLabel("speedBoost_tt")
  NOS_VFX_DESC_            = translateLabel("vfx_tt")
  NOS_PURGE_DESC_          = translateLabel("purge_tt")
  LOUD_RADIO_DESC_         = translateLabel("loudradio_tt")
  POPSNBANGS_DESC_         = translateLabel("pnb_tt")
  LOUDER_POPS_DESC_        = translateLabel("louderpnb_tt")
  HIGH_BEAMS_DESC_         = translateLabel("highbeams_tt")
  BRAKE_LIGHT_DESC_        = translateLabel("brakeLight_tt")
  IV_STYLE_EXIT_DESC_      = translateLabel("engineOn_tt")
  KEEP_WHEELS_TURNED_DESC_ = translateLabel("wheelsturned_tt")
  CANT_TOUCH_THIS_DESC_    = translateLabel("canttouchthis_tt")
  INSTA_180_DESC_          = translateLabel("insta180_tt")
  FLARES_FOR_ALL_DESC_     = translateLabel("flaresforall_tt")
  PLANE_SPEED_DESC_        = translateLabel("planeSpeed_tt")
  STRONG_WINDOWS_DESC_     = translateLabel("strongWindows_tt")
  VEHICLE_MINES_DESC_      = translateLabel("veh_mines_tt")
  MINES_TYPE_BTN_          = translateLabel("mine_type_btn")
  MINES_TYPE_DESC_         = translateLabel("mine_type_txt")
  RGB_LIGHTS_DESC_         = translateLabel("rgbLights")
  RGB_SPEED_TXT_           = translateLabel("rgbSlider")
  AUTOPILOT_ERROR_TXT_     = translateLabel("autopilot_err_txt")
  ENGINE_SOUND_BTN_        = translateLabel("engineSoundBtn")
  ENGINE_SOUND_ERROR_TXT_  = translateLabel("engineSoundErr")
  SEARCH_VEH_HINT_         = translateLabel("searchVeh_hint")
  SELECT_SOUND_TXT_        = translateLabel("Use This Sound")
  RESTORE_DEFAULT_         = translateLabel("Restore Default")
  FIX_ENGINE_              = translateLabel("Fix Engine")
  DESTROY_ENGINE_          = translateLabel("Destroy Engine")
  EJECTO_SEATO_DESC_       = translateLabel("ejecto_seato_tt")
  FENDER_BENDER_DESC_      = translateLabel("fenderBender_tt")
  -- Flatbed
  GET_IN_FLATBED_         = translateLabel("getinsidefltbd")
  SPAWN_FLATBED_BTN_      = translateLabel("spawnfltbd")
  FLTBD_NO_VEH_TXT_       = translateLabel("fltbd_nonearbyvehTxt")
  FLTBD_NOT_ALLOWED_TXT_  = translateLabel("fltbd_nootherfltbdTxt")
  FLTBD_CARS_ONLY_TXT_    = translateLabel("fltbd_carsOnlyTxt")
  FLTBD_NEARBY_VEH_TXT_   = translateLabel("fltbd_closest_veh")
  FLTBD_TOWING_TXT_       = translateLabel("fltbd_towingTxt")
  FLTBD_SHOW_TOWPOS_CB_   = translateLabel("Show Towing Position")
  FLTBD_SHOW_TOWPOS_DESC_ = translateLabel("towpos_tt")
  FLTBD_TOW_ALL_CB_       = translateLabel("Tow Everything")
  FLTBD_TOW_ALL_DESC_     = translateLabel("TowEverything_tt")
  FLTBD_TOW_BTN_          = translateLabel("towBtn")
  FLTBD_ADJUST_POS_TXT_   = translateLabel("Adjust Vehicle Position")
  FLTBD_ADJUST_POS_DESC_  = translateLabel("AdjustPosition_tt")
  FLTBD_EXIT_VEH_ERROR_   = translateLabel("Exit your current vehicle first.")
  FLTBD_INTERIOR_ERROR_   = translateLabel("noSpawnInside")
  -- Vehicle Creator
  CREATE_TXT_           = translateLabel("Create")
  CREATOR_DESC_         = translateLabel("vcreator_tt")
  SAVED_VEHS_TXT_       = translateLabel("vc_saved_vehs")
  SAVED_VEHS_DESC_      = translateLabel("vc_saved_vehs_tt")
  VC_DEMO_VEH_BTN_      = translateLabel("widebodycivic_Btn")
  VC_DEMO_VEH_DESC_     = translateLabel("widebodycivic_tt")
  VC_MAIN_VEH_TXT_      = translateLabel("vc_main_veh")
  VC_SPAWNED_VEHS_TXT_  = translateLabel("vc_spawned_vehs")
  VC_ATTACH_BTN_        = translateLabel("vc_attach_btn")
  VC_ALREADY_ATTACHED_  = translateLabel("vc_alrattached_err")
  VC_SELF_ATTACH_ERR_   = translateLabel("vc_selfattach_err")
  VC_NAME_HINT_         = translateLabel("vc_choose_name_hint")
  VC_NAME_ERROR_        = translateLabel("vc_same_name_err")
  VC_SAVE_SUCCESS_      = translateLabel("vc_saved_msg")
  VC_SAVE_ERROR_        = translateLabel("vc_save_err")
  VC_SPAWN_PERSISTENT_  = translateLabel("vc_spawn_persist")
  VC_DELETE_PERSISTENT_ = translateLabel("vc_delete_persist")
  VC_DELETE_NOTIF_      = translateLabel("vc_delete_msg")
  -- online
  -- Casino Pacino
  CP_GAMBLING_TXT_             = translateLabel("Gambling")
  CP_BYPASSCD_CP_              = translateLabel("bypassCasinoCooldownCB")
  CP_BYPASSCD_WARN_            = translateLabel("casinoCDwarn")
  CP_COOLDOWN_STATUS_          = translateLabel("casinoCDstatus")
  CP_FORCE_POKER_RF_CB_        = translateLabel("forcePokerCardsCB")
  CP_FORCE_BADBEAT_CB_         = translateLabel("setDealersCardsCB")
  CP_DEALER_FACEDOWN_TXT_      = translateLabel("faceDownCard")
  CP_DEALER_BUST_BTN_          = translateLabel("dealerBustBtn")
  CP_FORCE_ROULETTE_CB_        = translateLabel("forceRouletteCB")
  CP_NOT_PLAYING_BJ_TXT_       = translateLabel("not_playing_bj_txt")
  CP_NOT_IN_CASINO_TXT_        = translateLabel("not_in_casino_txt")
  CP_ROULETTE_CTRL_NOTIF_      = translateLabel("roulette_ctrl_txt")
  CP_TCC_CTRL_NOTIF_           = translateLabel("tcc_ctrl_txt")
  CP_RIG_SLOTS_CB_             = translateLabel("rigSlotsCB")
  CP_AUTOPLAY_SLOTS_CB_        = translateLabel("autoplaySlotsCB")
  CP_AUTOPLAY_CAP_CB_          = translateLabel("autoplayCapCB")
  CP_PODIUM_VEH_BTN_           = translateLabel("podiumVeh_Btn")
  CP_MYSTERY_PRIZE_BTN_        = translateLabel("mysteryPrize_Btn")
  CP_50K_BTN_                  = translateLabel("50k_Btn")
  CP_25K_BTN_                  = translateLabel("25k_Btn")
  CP_15K_BTN_                  = translateLabel("15k_Btn")
  CP_DISCOUNT_BTN_             = translateLabel("%_Btn")
  CP_CLOTHING_BTN_             = translateLabel("clothing_Btn")
  CP_HEIST_APPROACH_TXT_       = translateLabel("approach")
  CP_HEIST_LAST_APPROACH_TXT_  = translateLabel("last_approach")
  CP_HEIST_HARD_APPROACH_TXT_  = translateLabel("hard_approach")
  CP_HEIST_TARGET_TXT_         = translateLabel("target")
  CP_HEIST_GUNMAN_TXT_         = translateLabel("gunman")
  CP_HEIST_DRIVER_TXT_         = translateLabel("driver")
  CP_HEIST_HACKER_TXT_         = translateLabel("hacker")
  CP_HEIST_WEAPONS_TXT_        = translateLabel("unmarked_weapons")
  CP_HEIST_GETAWAY_VEHS_TXT_   = translateLabel("getaways")
  CP_HEIST_MASKS_TXT_          = translateLabel("masks")
  CP_HEIST_AUTOGRAB_           = translateLabel("autograb")
  CP_HEIST_UNLOCK_ALL_BTN_     = translateLabel("Unlock All Heist Options")
  CP_HEIST_ZERO_AI_CUTS_BTN_   = translateLabel("%0_ai_cuts_Btn")
  CP_HEIST_MAX_PLAYER_CUTS_BTN_= translateLabel("%100_p_cuts_Btn")
  -- YimResupplierV2
  CEO_WHOUSES_TXT_   = translateLabel("ceo_whouses_title")
  CEO_WHOUSES_DESC_  = translateLabel("ceo_whouses_txt")
  CEO_WAREHOUSE_     = translateLabel("Warehouse")
  CEO_RANDOM_CRATES_ = translateLabel("random_crates")
  QUICK_TP_TXT_      = translateLabel("quick_tp")
  QUICK_TP_WARN_     = translateLabel("tp_warn")
  QUICK_TP_WARN2_    = translateLabel("tp_warn_2")
  HANGAR_TXT_        = translateLabel("hangar_title")
  -- Players
  PLAYERS_TAB_          = translateLabel("playersTab")
  TOTAL_PLAYERS_TXT_    = translateLabel("Total Players:")
  TEMP_DISABLED_NOTIF_  = translateLabel("temporarily disabled")
  PERVERT_STALKER_DESC_ = translateLabel("pervertStalker_tt")
  -- World
  WORLD_TAB_             = translateLabel("worldTab")
  NPC_CTRL_FAIL_         = translateLabel("failedToCtrlNPC")
  VEH_CTRL_FAIL_         = translateLabel("failed_veh_ctrl")
  PED_GRABBER_CB_        = translateLabel("pedGrabber")
  PED_GRABBER_DESC_      = translateLabel("pedGrabber_tt")
  THROW_FORCE_TXT_       = translateLabel("Throw Force")
  CARPOOL_CB_            = translateLabel("carpool")
  CARPOOL_DESC_          = translateLabel("carpool_tt")
  PREVIOUS_SEAT_BTN_     = translateLabel("prevSeat")
  NEXT_SEAT_BTN_         = translateLabel("nextSeat")
  ANIMATE_NPCS_CB_       = translateLabel("animateNPCsCB")
  ANIMATE_NPCS_DESC_     = translateLabel("animateNPCs_tt")
  KAMIKAZE_DRIVERS_CB_   = translateLabel("kamikazeCB")
  KAMIKAZE_DRIVERS_DESC_ = translateLabel("kamikazeDrivers_tt")
  PUBLIC_ENEMY_CB_       = translateLabel("publicEnemyCB")
  PUBLIC_ENEMY_DESC_     = translateLabel("publicEnemy_tt")
  EXTEND_WORLD_CB_       = translateLabel("extendWorldCB")
  EXTEND_WORLD_DESC_     = translateLabel("extendWorld_tt")
  SMOOTH_WATERS_CB_      = translateLabel("smoothwatersCB")
  SMOOTH_WATERS_DESC_    = translateLabel("smoothwaters_tt")
  -- Object Spawner
  EDIT_MODE_CB_            = translateLabel("editMode")
  EDIT_MODE_DESC_          = translateLabel("editMode_tt")
  COCKSTAR_BLACKLIST_WARN_ = translateLabel("R*_blacklist")
  CRASH_OBJECT_WARN_       = translateLabel("crash_object")
  CUSTOM_OBJECTS_TXT_      = translateLabel("Custom Objects")
  ALL_OBJECTS_TXT_         = translateLabel("All Objects")
  PREVIEW_OBJECTS_CB_      = translateLabel("Preview")
  MOVE_OBJECTS_FB_         = translateLabel("Move_FB")
  MOVE_OBJECTS_UD_         = translateLabel("Move_UD")
  SPAWN_FOR_PLAYER_CB_     = translateLabel("Spawn For a Player")
  INVALID_OBJECT_TXT_      = translateLabel("invalid_obj")
  SPAWNED_OBJECTS_TXT_     = translateLabel("spawned_objects")
  ATTACH_TO_SELF_CB_       = translateLabel("Attach To Self")
  ATTACH_TO_VEH_CB_        = translateLabel("Attach To Vehicle")
  ATTACHED_OBJECTS_TXT_    = translateLabel("attached_objects")
  XYZ_MULTIPLIER_TXT_      = translateLabel("xyz_multiplier")
  MOVE_OBJECT_TXT_         = translateLabel("Move Object:")
  ROTATE_OBJECT_TXT_       = translateLabel("Rotate Object:")
  RESET_OBJECT_DESC_       = translateLabel("resetSlider_tt")
  -- Settings
  SETTINGS_TAB_            = translateLabel("settingsTab")
  DISABLE_TOOLTIPS_CB_     = translateLabel("Disable Tooltips")
  DISABLE_UISOUNDS_CB_     = translateLabel("DisableSound")
  DISABLE_UISOUNDS_DESC_   = translateLabel("DisableSound_tt")
  FLIGHT_MUSIC_CB_         = translateLabel("flightMusicCB")
  FLIGHT_MUSIC_DESC_       = translateLabel("flightMusic_tt")
  DAILY_QUOTES_CB_         = translateLabel("dailyQuotesCB")
  DAILY_QUOTES_DESC_       = translateLabel("dailyQuotes_tt")
  MISSILE_DEF_LOGS_CB_     = translateLabel("missileLogsCB")
  MISSILE_DEF_LOGS_DESC_   = translateLabel("missileLogs_tt")
  AUTOFILL_TIMEDELAY_DESC_ = translateLabel("autofillDelay_tt")
  LANGUAGE_TXT_            = translateLabel("langTitle")
  CURRENT_LANGUAGE_TXT_    = translateLabel("currentLang_txt")
  GAME_LANGUAGE_CB_        = translateLabel("gameLangCB")
  GAME_LANGUAGE_DESC_      = translateLabel("gameLang_tt")
  LANG_CHANGED_NOTIF_      = translateLabel("lang_success_msg")
  RESET_SETTINGS_BTN_      = translateLabel("reset_settings_Btn")
  CONFIRM_PROMPT_          = translateLabel("confirm_txt")
  log.info(string.format("Loaded %d %s translations.", Lua_fn.getTableLength(Labels), current_lang))
end

---@param level integer
doWantedStars = function(level)
  local stars = ""
  if level == 0 then
    return "Clear"
  end
  for _ = 1, level do
    stars = stars .. " *"
  end
  return stars
end

spawnPervert = function(playerPed, playerName)
  if not Game.requestModel(0x55446010) then
    return
  end
  local sequenceID = 0
  local spawn_pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
    playerPed, math.random(3, 10), math.random(3, 10), 0.0
  )

  perv = PED.CREATE_PED(PED_TYPE._CIVMALE, 0x55446010, spawn_pos.x, spawn_pos.y, spawn_pos.z, math.random(1, 180), true, false)
  if ENTITY.DOES_ENTITY_EXIST(perv) then
    UI.widgetSound("Select")
    gui.show_success("Samurai's Scripts", string.format("Spawned a stalker pervert for %s.", playerName))
    TASK.OPEN_SEQUENCE_TASK(sequenceID)
    TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(perv, true)
    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(perv, true)
    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(
      perv, playerPed, 3.0, 3.0, 3.0,
      20.0, -1, 10.0, true
    )
    if Game.requestAnimDict("switch@trevor@jerking_off") then
      TASK.TASK_PLAY_ANIM(
        perv, "switch@trevor@jerking_off", "trev_jerking_off_loop",
        4.0, -4.0, -1, 196665, 1.0, false, false, false
      )
    end
    TASK.SET_SEQUENCE_TO_REPEAT(sequenceID, true)
    TASK.TASK_PERFORM_SEQUENCE(perv, sequenceID)
    TASK.CLEAR_SEQUENCE_TASK(sequenceID)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(0x55446010)
    ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(perv)
  else
    UI.widgetSound("Error")
    gui.show_error("Samurai's Scripts", string.format("Failed to spawn a stalker pervert for %s.", playerName))
  end
end
--#endregion


--#region Helpers

-- Lua helpers.
---@class Lua_fn
Lua_fn = {}
Lua_fn.__index = Lua_fn

---@param cond boolean
---@param ifTrue any
---@param ifFalse any
Lua_fn.condReturn = function(cond, ifTrue, ifFalse)
  return cond and ifTrue or ifFalse
end

-- Checks whether a string starts with the provided prefix and returns true or false.
---@param str string
---@param prefix string
Lua_fn.str_startswith = function(str, prefix)
  return str:sub(1, #prefix) == prefix
end

-- Checks whether a string contains the provided substring and returns true or false.
---@param str string
---@param sub string
Lua_fn.str_contains = function(str, sub)
  return str:find(sub, 1, true) ~= nil
end

-- Checks whether a string ends with the provided suffix and returns true or false.
---@param str string
---@param suffix string
Lua_fn.str_endswith = function(str, suffix)
  return str:sub(- #suffix) == suffix
end

-- Inserts a string into another string at the given position. (index starts from 0).
--[[ -- Example:

    Lua_fn.str_insert("Hello", 5, " World")
      -> "Hello World"
]]
---@param str string
---@param pos integer
---@param text string
Lua_fn.str_insert = function(str, pos, text)
  return str:sub(1, pos) .. text .. str:sub(pos)
end

-- Replaces a string with a new string.
---@param str string
---@param old string
---@param new string
Lua_fn.str_replace = function(str, old, new)
  local search_index = 1
  local result
  while true do
    local start_index, end_index = str:find(old, search_index, true)
    if not start_index then
      break
    end
    local changed = str:sub(end_index + 1)
    result = str:sub(1, (start_index - 1)) .. new .. changed
    search_index = -1 * changed:len()
  end
  return result
end

-- Rounds n float to x number of decimals.
--[[ -- Example:

    Lua_fn.round(420.69458797, 2)
      -> 420.69
]]
---@param n number
---@param x integer
Lua_fn.round = function(n, x)
  return tonumber(string.format("%." .. (x or 0) .. "f", n))
end

-- Helper function for printing
-- floats with a maximum of 4 decimal fractions.
---@param num number
Lua_fn.floatPrecision = function(num)
  if #tostring(math.fmod(num, 1)) > 6 then
    return string.format("%.4f", num)
  end
  return string.format(num)
end

-- Returns a string containing the input value separated by the thousands.
--[[ -- Example:

    Lua_fn.separateInt(42069)
      -> "42,069"
]]
---@param value number | string
Lua_fn.separateInt = function(value)
  return tostring(value):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

-- Returns a string containing the input value separated by the thousands and prefixed by a dollar sign.
--[[ -- Example:

    Lua_fn.formatMoney(42069)
      -> "$42,069"
]]
---@param value number | string
Lua_fn.formatMoney = function(value)
  return "$" .. tostring(Lua_fn.separateInt(value))
end

--[[ Converts a HEX string to RGB integers and returns 3 numbers representing Red, Green and Blue respectively.

- Example:

      red, green, blue = Lua_fn.hexToRGB("#E0D0B6")
        -> 224, 208, 182
- Another example:

      r, g, b = Lua_fn.hexToRGB("0B4")
        -> 0, 187, 68
]]
---@param hex string
Lua_fn.hexToRGB = function(hex)
  local r, g, b
  hex = hex:gsub("#", "")
  if hex:len() == 3 then -- short HEX
    r, g, b = (tonumber("0x" .. hex:sub(1, 1)) * 17), (tonumber("0x" .. hex:sub(2, 2)) * 17),
        (tonumber("0x" .. hex:sub(3, 3)) * 17)
  else
    r, g, b = tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)),
        tonumber("0x" .. hex:sub(5, 6))
  end
  return r, g, b
end

---@param r number
---@param g number
---@param b number
Lua_fn.RGBtoHex = function(r, g, b)
  return string.format("#%02X%02X%02X", r, g, b)
end

--[[ Decodes hex to string.

HEX must be provided in a string format.

- Example:

      Lua_fn.hexToString("63756E74")
        -> "cunt"
]]
---@param hex string
---@return string
Lua_fn.hexToString = function(hex)
  return (hex:gsub("%x%x", function(digits)
    return string.char(tonumber(digits, 16))
  end))
end

-- Encodes a string into hex
---@param str string
---@return string
Lua_fn.stringToHex = function(str)
  return (str:gsub(".", function(char)
    return string.format("%02x", char:byte())
  end))
end

---@param n integer
---@param base integer
Lua_fn.decimalToHex = function(n, base)
  local hex_rep, str, i, d = "0123456789ABCDEF", "", 0, 0
  while n > 0 do
    i = i + 1
    n, d = math.floor(n / base), (n % base) + 1
    str = string.sub(hex_rep, d, d) .. str
  end
  return '0x' .. str
end

Lua_fn.tableContains = function(tbl, value)
  if #tbl == 0 then
    return false
  end
  for i = 1, #tbl do
    if tbl[i] == value then
      return true
    end
  end
  return false
end

-- Returns key, value pairs of a table.
---@param t table
---@param indent? integer
---@return string
Lua_fn.listIter = function(t, indent)
  if not indent then
    indent = 0
  end
  local ret_str = string.rep(" ", indent) .. "{\r\n"
  indent = indent + 2
  for k, v in pairs(t) do
    ret_str = ret_str .. string.rep(" ", indent)
    if type(k) == "number" then
      ret_str = ret_str .. "[" .. k .. "] = "
    elseif type(k) == "string" then
      ret_str = ret_str .. k .. " = "
    end
    if type(v) == "number" then
      ret_str = ret_str .. v .. ",\r\n"
    elseif type(v) == "string" then
      ret_str = ret_str .. "\"" .. v .. "\",\r\n"
    elseif type(v) == "table" then
      ret_str = ret_str .. Lua_fn.listIter(v, indent + 2) .. ",\r\n"
    else
      ret_str = ret_str .. "\"" .. tostring(v) .. "\",\r\n"
    end
  end
  ret_str = ret_str .. string.rep(" ", indent - 2) .. "}"
  return ret_str
end

-- Returns the number of values in a table. Doesn't count nil fields.
---@param t table
---@return number
Lua_fn.getTableLength = function(t)
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

-- Returns the number of duplicate items in a table.
---@param t table
---@param value string | number | integer | table
Lua_fn.getTableDupes = function(t, value)
  local count = 0
  for _, v in ipairs(t) do
    if value == v then
      count = count + 1
    end
  end
  return count
end

-- Removes duplicate items from a table and returns a new one with the results.
--
-- If `is_dev` is set to `true`, it adds a table with duplicate items to the return as well.
--
-- If you use the dev flag then you will need to specify which table you want to use (clean items or duplicates)
--
--[[
  **Example:**

  case1:

    local clean_items = Lua_fn.removeTableDupes(yourTable, false) -- when set to false it only returns a table with clean items (no duplicates)
    log.info(tostring(Lua_fn.listIter(clean_items, 0)))

  case2:

    local results = Lua_fn.removeTableDupes(yourTable, true) -- when set to true it returns a table containing both clean items and duplicates.
    local clean_items = results.clean_T
    local duplicate_items = results.dupes_T
    log.info("\10Clean Items:\10" .. tostring(Lua_fn.listIter(clean_items, 0)))
    log.info("\10Duplicate Items:\10" .. tostring(Lua_fn.listIter(duplicate_items, 0)))
]]
---@param t table
---@param is_dev boolean
Lua_fn.removeTableDupes = function(t, is_dev)
  local exists_T, clean_T, dupes_T, result_T = {}, {}, {}, {}
  for _, v in ipairs(t) do
    if not exists_T[v] then
      clean_T[#clean_T + 1] = v
      exists_T[v] = true
    else
      if is_dev then
        dupes_T[#dupes_T + 1] = v
      end
    end
  end
  if is_dev then
    result_T.clean_T = clean_T
    result_T.dupes_T = dupes_T
  end
  return Lua_fn.condReturn(is_dev, result_T, clean_T)
end

-- Converts 0 and 1 values to Lua booleans. Useful when working with memory.
---@param value integer
Lua_fn.Lua_bool = function(value)
  if type(value) == "number" then
    if value == 0 then
      return false
    elseif value == 1 then
      return true
    else
      return error("Incorrect value", 2)
    end
  else
    return error("Incorrect value", 2)
  end
end

--
-- Bitwise Operations
--
---@param num number
---@param bit number
Lua_fn.get_bit = function(num, bit)
  return (num & (1 << bit)) >> bit
end

---@param num number
---@param bit number
Lua_fn.has_bit = function(num, bit)
  return (num & (1 << bit)) ~= 0
end

---@param num number
---@param bit number
Lua_fn.set_bit = function(num, bit)
  return num | (1 << bit)
end

---@param num number
---@param bit number
Lua_fn.clear_bit = function(num, bit)
  return num & ~(1 << bit)
end

-- Lua version of Bob Jenskins' "Jenkins One At A Time" hash function
--
-- https://en.wikipedia.org/wiki/Jenkins_hash_function
---@param key string
---@return integer
Lua_fn.joaat = function(key)
  local hash = 0
  for i = 1, #key do
    hash = hash + string.byte(key, i)
    hash = hash + (hash << 10)
    hash = hash & 0xFFFFFFFF
    hash = hash ~ (hash >> 6)
  end
  hash = hash + (hash << 3)
  hash = hash & 0xFFFFFFFF
  hash = hash ~ (hash >> 11)
  hash = hash + (hash << 15)
  hash = hash & 0xFFFFFFFF
  return hash
end

-- Converts a rotation vector to a direction vector.
---@param rotation vec3
Lua_fn.RotToDir = function(rotation)
	local radians = vec3:new(
    rotation.x * (math.pi / 180),
    rotation.y * (math.pi / 180),
    rotation.z * (math.pi / 180)
  )

	local direction = vec3:new(
    -math.sin(radians.z) * math.abs(math.cos(radians.x)),
    math.cos(radians.z) * math.abs(math.cos(radians.x)),
    math.sin(radians.x)
  )

	return direction
end


-- ImGui helpers.
---@class UI
UI = {}
UI.__index = UI

---@param col string | table
UI.getColor = function(col)
  local r, g, b
  local errorMsg = ""
  if type(col) == "string" then
    if col:find("^#") then
      r, g, b = Lua_fn.hexToRGB(col)
      r, g, b = Lua_fn.round((r / 255), 1), Lua_fn.round((g / 255), 1), Lua_fn.round((b / 255), 1)
    elseif col == "black" then
      r, g, b = 0, 0, 0
    elseif col == "white" then
      r, g, b = 1, 1, 1
    elseif col == "red" then
      r, g, b = 1, 0, 0
    elseif col == "green" then
      r, g, b = 0, 1, 0
    elseif col == "blue" then
      r, g, b = 0, 0, 1
    elseif col == "yellow" then
      r, g, b = 1, 1, 0
    elseif col == "orange" then
      r, g, b = 1, 0.5, 0
    elseif col == "pink" then
      r, g, b = 1, 0, 0.5
    elseif col == "purple" then
      r, g, b = 1, 0, 1
    else
      r, g, b = 1, 1, 1
      errorMsg = ("'" .. tostring(col) .. "' is not a valid color for this function.\nOnly these strings can be used as color inputs:\n - 'black'\n - 'white'\n - 'red'\n - 'green'\n - 'blue'\n - 'yellow'\n - 'orange'\n - 'pink'\n - 'purple'")
    end
  elseif type(col) == "table" then
    -- check color input values and convert them to floats between 0 and 1 which is what ImGui accepts for color values.
    if col[1] > 1 then
      col[1] = Lua_fn.round((col[1] / 255), 2)
    end
    if col[2] > 1 then
      col[2] = Lua_fn.round((col[2] / 255), 2)
    end
    if col[3] > 1 then
      col[3] = Lua_fn.round((col[3] / 255), 2)
    end
    r, g, b = col[1], col[2], col[3]
  end
  return r, g, b, errorMsg
end

-- Creates a text wrapped around the provided size. (We can use coloredText() and set the color to white but this is simpler.)
---@param text string
---@param wrap_size integer
UI.wrappedText = function(text, wrap_size)
  ImGui.PushTextWrapPos(ImGui.GetFontSize() * wrap_size)
  ImGui.TextWrapped(text)
  ImGui.PopTextWrapPos()
end

-- Creates a colored ImGui text.
---@param text string
---@param color string | table
---@param alpha? integer
---@param wrap_size number
--[[ -- Usage:
  - text: The text to display.
  - color: Can be either a HEX string (both short and long hex formats are accepted) or a table containing 3 color numbers in RGB format (you can use standard RGB values between 0 and 255 or ImGui values between 0 and 1), or a string literal (ex: "red").
  - alpha: A value between 0 and 1 representing visibility.
  - wrap_size: A number representing the size your text will wrap around.
]]
UI.coloredText = function(text, color, alpha, wrap_size)
  r, g, b, errorMsg = UI.getColor(color)
  if type(alpha) ~= "number" or alpha == nil then
    alpha = 1
  end
  if alpha > 1 then
    alpha = 1
  end
  ImGui.PushStyleColor(ImGuiCol.Text, r, g, b, alpha)
  ImGui.PushTextWrapPos(ImGui.GetFontSize() * wrap_size)
  ImGui.TextWrapped(text)
  ImGui.PopTextWrapPos()
  ImGui.PopStyleColor(1)
  if errorMsg ~= "" then
    if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
      ImGui.SetNextWindowBgAlpha(0.8)
      ImGui.BeginTooltip()
      ImGui.PushTextWrapPos(ImGui.GetFontSize() * wrap_size)
      ImGui.TextWrapped(errorMsg)
      ImGui.PopTextWrapPos()
      ImGui.EndTooltip()
    end
  end
end

-- Creates a colored ImGui button.
---@param text string
---@param color string | table
---@param hovercolor string | table
---@param activecolor string | table
---@param alpha? integer
---@return boolean
--[[ -- Usage:
  - text: The button label.
  - color: The default button color. Can be either a HEX string (both short and long hex formats are accepted), a table containing 3 color numbers in RGB format (you can use standard RGB values between 0 and 255 or ImGui values between 0 and 1), or a string literal (ex: "red").
  - hovercolor: The color the button will change to when it's hovered. Same format as the 'color' parameter.
  - activecolor: The color the button will change to when it's clicked. Same format as the 'color' parameter.
  - alpha: A value between 0 and 1 representing visibility.
]]
UI.coloredButton = function(text, color, hovercolor, activecolor, alpha)
  local r, g, b                   = UI.getColor(color)
  local hoverR, hoverG, hoverB    = UI.getColor(hovercolor)
  local activeR, activeG, activeB = UI.getColor(activecolor)
  if type(alpha) ~= "number" or alpha == nil then
    alpha = 1
  end
  if alpha > 1 then
    alpha = 1
  end
  ImGui.PushStyleColor(ImGuiCol.Button, r, g, b, alpha)
  ImGui.PushStyleColor(ImGuiCol.ButtonHovered, hoverR, hoverG, hoverB, alpha)
  ImGui.PushStyleColor(ImGuiCol.ButtonActive, activeR, activeG, activeB, alpha)
  local retVal = ImGui.Button(text)
  ImGui.PopStyleColor(3)
  return retVal
end

-- Creates a help marker (?) symbol in front of the widget this function is called after. When the symbol is hovered, it displays a tooltip.
---@param colorFlag boolean
---@param text string
---@param color? string | table | any
---@param alpha? integer | any
--[[ -- Usage:
  - colorFlag: true/false. If set to true, the color parameter will be required and the provided text will be colored, otherwise the color parameter will be ignored and can be left empty.
  - text: The text that will be displayed inside the tooltip.
  - color: Can be either a HEX string (both short and long hex formats are accepted), a table containing 3 color numbers in RGB format (you can use standard RGB values between 0 and 255 or ImGui values between 0 and 1), or a string literal (ex: "red"). If colorFlag is set to true, this parameter will be required.
  - alpha: A value between 0 and 1 representing visibility. If left empty it defaults to 1.
]]
UI.helpMarker = function(colorFlag, text, color, alpha)
  if not disableTooltips then
    ImGui.SameLine()
    ImGui.TextDisabled("(?)")
    if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
      ImGui.SetNextWindowBgAlpha(0.75)
      ImGui.BeginTooltip()
      if colorFlag == true then
        UI.coloredText(text, color, alpha, 20)
      else
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 20)
        ImGui.TextWrapped(text)
        ImGui.PopTextWrapPos()
      end
      ImGui.EndTooltip()
    end
  end
end

-- Displays a tooltip whenever the widget this function is called after is hovered.
---@param colorFlag boolean
---@param text string
---@param color? any
---@param alpha? any
--[[ -- Usage:
  - colorFlag: true/false. If set to true, the color parameter will be required and the provided text will be colored otherwise the color parameter will be ignored and can be left empty.
  - text: The text that will be displayed inside the tooltip.
  - color: Can be either a HEX string (both short and long hex formats are accepted), a table containing 3 color numbers in RGB format (you can use standard RGB values between 0 and 255 or ImGui values between 0 and 1), or a string literal (ex: "red"). If colorFlag is set to true, this parameter will be required.
  - alpha: A value between 0 and 1 representing visibility. If left empty it defaults to 1.
]]
UI.toolTip = function(colorFlag, text, color, alpha)
  if not disableTooltips then
    if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
      ImGui.SetNextWindowBgAlpha(0.75)
      ImGui.BeginTooltip()
      if colorFlag == true then
        UI.coloredText(text, color, alpha, 20)
      else
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 20)
        ImGui.TextWrapped(text)
        ImGui.PopTextWrapPos()
      end
      ImGui.EndTooltip()
    end
  end
end

---Checks if an ImGui widget was clicked with either the left or the right mouse button.
---@param mb string
---@return boolean
--[[

**Usage:**
- mb: A string representing a mouse button. Can be either "lmb" for Left Mouse Button or "rmb" for Right Mouse Button.
]]
UI.isItemClicked = function(mb)
  local retBool = false
  if mb == "lmb" then
    retBool = ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and ImGui.IsItemClicked(0)
  elseif mb == "rmb" then
    retBool = ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and ImGui.IsItemClicked(1)
  else
    error(
      string.format("Error in function isItemClicked(): Invalid param %s. Correct inputs: 'lmb' for Left Mouse Button or 'rmb' for Right Mouse Button.", mb),
      2)
  end
  return retBool
end

-- Sets the clipboard text.
---@param text string
---@param alt_condition boolean
UI.setClipBoard = function(text, alt_condition)
  local cond = UI.isItemClicked("lmb") and true or alt_condition
  if cond then
    ImGui.SetClipboardText(text)
  end
end

-- Plays a sound when an ImGui widget is clicked.
---@param sound string
--[[

**Sound strings:**

"Select" | "Select2"  | "Cancel"   | "Error"  | "Nav" |

"Nav2"   | "Pickup"   | "Radar"    | "Delete" | "W_Pickup" |

"Fail"   | "Focus_In" | "Focus_Out" | "Notif"
]]
UI.widgetSound = function(sound)
  if not disableUiSounds then
    local sounds_T <const> = {
      { name = "Radar",     sound = "RADAR_ACTIVATE",      soundRef = "DLC_BTL_SECURITY_VANS_RADAR_PING_SOUNDS" },
      { name = "Select",    sound = "SELECT",              soundRef = "HUD_FRONTEND_DEFAULT_SOUNDSET" },
      { name = "Pickup",    sound = "PICK_UP",             soundRef = "HUD_FRONTEND_DEFAULT_SOUNDSET" },
      { name = "W_Pickup",  sound = "PICK_UP_WEAPON",      soundRef = "HUD_FRONTEND_CUSTOM_SOUNDSET" },
      { name = "Fail",      sound = "CLICK_FAIL",          soundRef = "WEB_NAVIGATION_SOUNDS_PHONE" },
      { name = "Click",     sound = "CLICK_LINK",          soundRef = "DLC_H3_ARCADE_LAPTOP_SOUNDS" },
      { name = "Notif",     sound = "LOSE_1ST",            soundRef = "GTAO_FM_EVENTS_SOUNDSET" },
      { name = "Delete",    sound = "DELETE",              soundRef = "HUD_DEATHMATCH_SOUNDSET" },
      { name = "Cancel",    sound = "CANCEL",              soundRef = "HUD_FREEMODE_SOUNDSET" },
      { name = "Error",     sound = "ERROR",               soundRef = "HUD_FREEMODE_SOUNDSET" },
      { name = "Nav",       sound = "NAV_LEFT_RIGHT",      soundRef = "HUD_FREEMODE_SOUNDSET" },
      { name = "Nav2",      sound = "NAV_UP_DOWN",         soundRef = "HUD_FREEMODE_SOUNDSET" },
      { name = "Select2",   sound = "CHANGE_STATION_LOUD", soundRef = "RADIO_SOUNDSET" },
      { name = "Focus_In",  sound = "FOCUSIN",             soundRef = "HINTCAMSOUNDS" },
      { name = "Focus_Out", sound = "FOCUSOUT",            soundRef = "HINTCAMSOUNDS" },
    }
    script.run_in_fiber(function()
      for _, snd in ipairs(sounds_T) do
        if sound == snd.name then
          AUDIO.PLAY_SOUND_FRONTEND(-1, snd.sound, snd.soundRef, false)
          break
        end
      end
    end)
  end
end


-- Script-specific helpers.
--
-- SS as in Samurai's Scripts, not Schutzstaffel... 🙄
SS = {}
SS.__index = SS

---@param data string
SS.debug = function(data)
  if SS_debug then
    log.debug(data)
  end
end

SS.isAnyKeyPressed = function()
  ---@type boolean
  local check
  ---@type integer
  local key_code
  ---@type string
  local key_name
  for _, k in ipairs(VK_T) do
    if k.just_pressed then
      check    = true
      key_code = k.code
      key_name = k.name
      break
    end
  end
  return check, key_code, key_name
end

---@param key integer
SS.isKeyPressed = function(key)
  for _, k in ipairs(VK_T) do
    if key == k.code then
      if k.pressed then
        return true
      else
        return false
      end
    end
  end
end

---@param key integer
SS.isKeyJustPressed = function(key)
  for _, k in ipairs(VK_T) do
    if key == k.code then
      return k.just_pressed
    end
  end
  return false
end

---@param keybind table
SS.set_hotkey = function(keybind)
  ImGui.Dummy(1, 10)
  if key_name == nil then
    start_loading_anim = true
    UI.coloredText(string.format("%s%s", INPUT_WAIT_TXT_, loading_label), "#FFFFFF", 0.75, 20)
    key_pressed, key_code, key_name = SS.isAnyKeyPressed()
  else
    start_loading_anim = false
    for _, key in pairs(reserved_keys_T.kb) do
      if key_code == key then
        _reserved = true
        break
      else
        _reserved = false
      end
    end
    if not _reserved then
      ImGui.Text("New Key: "); ImGui.SameLine(); ImGui.Text(key_name)
    else
      UI.coloredText(HOTKEY_RESERVED_, "red", 0.86, 20)
    end
    ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine()
    if UI.coloredButton(string.format(" %s ##Shortcut", GENERIC_CLEAR_BTN_), "#FFDB58", "#FFFAA0", "#FFFFF0", 0.7) then
      UI.widgetSound("Cancel")
      key_code, key_name = nil, nil
    end
  end
  ImGui.Dummy(1, 10)
  if not _reserved and key_code ~= nil then
    if ImGui.Button(string.format("%s##keybinds", GENERIC_CONFIRM_BTN_)) then
      UI.widgetSound("Select")
      keybind.code, keybind.name = key_code, key_name
      CFG.save("keybinds", keybinds)
      key_code, key_name = nil, nil
      is_setting_hotkeys = false
      ImGui.CloseCurrentPopup()
    end
    ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
  end
  if ImGui.Button(string.format("%s##keybinds", GENERIC_CANCEL_BTN_)) then
    UI.widgetSound("Cancel")
    key_code, key_name = nil, nil
    start_loading_anim = false
    is_setting_hotkeys = false
    ImGui.CloseCurrentPopup()
  end
end

SS.openHotkeyWindow = function(window_name, keybind)
  ImGui.PushItemWidth(120)
  ImGui.BulletText(window_name)
  ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
  keybind.name, _ = ImGui.InputText(string.format("##%s", window_name), keybind.name, 32, ImGuiInputTextFlags.ReadOnly)
  ImGui.PopItemWidth()
  if UI.isItemClicked('lmb') then
    UI.widgetSound("Select2")
    ImGui.OpenPopup(window_name)
    is_setting_hotkeys = true
  end
  ImGui.SameLine(); ImGui.BeginDisabled(keybind.code == 0x0)
  if ImGui.Button(string.format("Remove##%s", window_name)) then
    UI.widgetSound("Delete")
    keybind.code, keybind.name = 0x0, "[Unbound]"
    CFG.save("keybinds", keybinds)
  end
  ImGui.EndDisabled()
  ImGui.SetNextWindowPos(780, 400, ImGuiCond.Appearing)
  ImGui.SetNextWindowSizeConstraints(240, 60, 600, 400)
  ImGui.SetNextWindowBgAlpha(0.8)
  if ImGui.BeginPopupModal(window_name, true, ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoTitleBar) then
    is_setting_hotkeys = true
    SS.set_hotkey(keybind)
    ImGui.End()
  end
end

---@param keybind table
SS.set_gpad_hotkey = function(keybind)
  ImGui.Dummy(1, 10)
  if gpad_keyName == nil then
    start_loading_anim = true
    UI.coloredText(string.format("%s%s", INPUT_WAIT_TXT_, loading_label), "#FFFFFF", 0.75, 20)
    gpad_keyCode, gpad_keyName = Game.getKeyPressed()
  else
    start_loading_anim = false
    for _, key in pairs(reserved_keys_T.gpad) do
      if gpad_keyCode == key then
        _reserved = true
        break
      else
        _reserved = false
      end
    end
    if not _reserved then
      ImGui.Text("New Key: "); ImGui.SameLine(); ImGui.Text(gpad_keyName)
    else
      UI.coloredText(HOTKEY_RESERVED_, "red", 0.86, 20)
    end
    ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine()
    if UI.coloredButton(string.format(" %s ##gpadkeybinds", GENERIC_CLEAR_BTN_), "#FFDB58", "#FFFAA0", "#FFFFF0", 0.7) then
      UI.widgetSound("Cancel")
      gpad_keyCode, gpad_keyName = nil, nil
    end
  end
  ImGui.Dummy(1, 10)
  if not _reserved and gpad_keyCode ~= nil then
    if ImGui.Button(string.format("%s##gpadkeybinds", GENERIC_CONFIRM_BTN_)) then
      UI.widgetSound("Select")
      keybind.code, keybind.name = gpad_keyCode, gpad_keyName
      CFG.save("gpad_keybinds", gpad_keybinds)
      gpad_keyCode, gpad_keyName = nil, nil
      is_setting_hotkeys = false
      ImGui.CloseCurrentPopup()
    end
    ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
  end
  if ImGui.Button(string.format("%s##gpadkeybinds", GENERIC_CANCEL_BTN_)) then
    UI.widgetSound("Cancel")
    gpad_keyCode, gpad_keyName = nil, nil
    start_loading_anim = false
    is_setting_hotkeys = false
    ImGui.CloseCurrentPopup()
  end
end

---@param window_name string
---@param keybind table
SS.gpadHotkeyWindow = function(window_name, keybind)
  ImGui.PushItemWidth(120)
  ImGui.BulletText(window_name)
  ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
  keybind.name, _ = ImGui.InputText("##" .. window_name, keybind.name, 32, ImGuiInputTextFlags.ReadOnly)
  ImGui.PopItemWidth()
  if UI.isItemClicked('lmb') then
    UI.widgetSound("Select2")
    ImGui.OpenPopup(window_name)
    is_setting_hotkeys = true
  end
  ImGui.SameLine(); ImGui.BeginDisabled(keybind.code == 0)
  if ImGui.Button(string.format("Remove##%s", window_name)) then
    UI.widgetSound("Delete")
    keybind.code, keybind.name = 0, "[Unbound]"
    CFG.save("gpad_keybinds", gpad_keybinds)
  end
  ImGui.EndDisabled()
  ImGui.SetNextWindowPos(780, 400, ImGuiCond.Appearing)
  ImGui.SetNextWindowSizeConstraints(240, 60, 600, 400)
  ImGui.SetNextWindowBgAlpha(0.8)
  if ImGui.BeginPopupModal(window_name, true, ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoTitleBar) then
    SS.set_gpad_hotkey(keybind)
    ImGui.End()
  end
end

-- Seamlessly add/remove keyboard keybinds on script update without requiring a config reset.
SS.check_kb_keybinds = function()
  local kb_keybinds_list = DEFAULT_CONFIG.keybinds
  local t_len            = Lua_fn.getTableLength
  if t_len(keybinds) == t_len(kb_keybinds_list) then
    SS.debug('No new keyboard keybinds.')
    return false -- early exit
  elseif t_len(keybinds) > t_len(kb_keybinds_list) then
    for k, _ in pairs(keybinds) do
      local kk = kb_keybinds_list[k]
      if kk == nil then -- removed keybind
        SS.debug('Removed keyboard keybind: ' .. tostring(keybinds[k]))
        keybinds[k] = nil
        CFG.save("keybinds", keybinds)  -- save
        keybinds = CFG.read("keybinds") -- refresh
      end
    end
  else
    for k, _ in pairs(kb_keybinds_list) do
      local kk = keybinds[k]
      if kk == nil then -- new keybind
        SS.debug('Added keyboard keybind: ' .. tostring(k))
        keybinds[k] = kb_keybinds_list[k]
        CFG.save("keybinds", keybinds)  -- save
        keybinds = CFG.read("keybinds") -- refresh
      end
    end
  end
end

-- Seamlessly add/remove controller keybinds on script update without requiring a config reset.
SS.check_gpad_keybinds = function()
  local gpad_keybinds_list = DEFAULT_CONFIG.gpad_keybinds
  local t_len              = Lua_fn.getTableLength
  if t_len(gpad_keybinds) == t_len(gpad_keybinds_list) then
    SS.debug('No new gamepad keybinds.')
    return false -- early exit
  elseif t_len(gpad_keybinds) > t_len(gpad_keybinds_list) then
    for k, _ in pairs(gpad_keybinds) do
      local kk = gpad_keybinds_list[k]
      if kk == nil then -- removed keybind
        SS.debug('Removed gamepad keybind: ' .. tostring(gpad_keybinds[k]))
        gpad_keybinds[k] = nil
        CFG.save("gpad_keybinds", gpad_keybinds)  -- save
        gpad_keybinds = CFG.read("gpad_keybinds") -- refresh
      end
    end
  else
    for k, _ in pairs(gpad_keybinds_list) do
      local kk = gpad_keybinds[k]
      if kk == nil then -- new keybind
        SS.debug('Added gamepad keybind: ' .. tostring(k))
        gpad_keybinds[k] = gpad_keybinds_list[k]
        CFG.save("gpad_keybinds", gpad_keybinds)  -- save
        gpad_keybinds = CFG.read("gpad_keybinds") -- refresh
      end
    end
  end
end

SS.canUsePhoneAnims = function ()
  return not ENTITY.IS_ENTITY_DEAD(self.get_ped(), false) and not is_playing_anim and not is_playing_scenario
  and not ped_grabbed and not vehicle_grabbed and not is_handsUp and not is_sitting
  and not is_hiding and PED.COUNT_PEDS_IN_COMBAT_WITH_TARGET(self.get_ped()) == 0
end

SS.canCrouch = function ()
  return Game.Self.isOnFoot() and not Game.Self.isInWater() and not Game.Self.is_ragdoll()
  and not gui.is_open() and not ped_grabbed and not vehicle_grabbed and not is_playing_anim
  and not is_playing_scenario and not is_typing and not is_sitting and not is_setting_hotkeys
  and not is_hiding and not isCrouched and not HUD.IS_MP_TEXT_CHAT_TYPING() and not Game.Self.isBrowsingApps()
end

SS.canUseHandsUp = function()
  return (Game.Self.isOnFoot() or is_car) and not gui.is_open() and not HUD.IS_MP_TEXT_CHAT_TYPING()
  and not ped_grabbed and not vehicle_grabbed and not is_playing_anim and not is_playing_scenario
  and not is_typing and not is_setting_hotkeys and not is_hiding and not Game.Self.isBrowsingApps()
end

-- Reverts changes done by the script.
SS.handle_events = function()
  if attached_ped ~= nil and attached_ped ~= 0 then
    ENTITY.DETACH_ENTITY(attached_ped, true, true)
    ENTITY.FREEZE_ENTITY_POSITION(attached_ped, false)
    TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(attached_ped, false)
    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(attached_ped, false)
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
    attached_ped = 0; ped_grabbed = false
  end

  if grabbed_veh ~= nil and grabbed_veh ~= 0 then
    ENTITY.DETACH_ENTITY(grabbed_veh, true, true)
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
    grabbed_veh = 0; vehicle_grabbed = false
  end

  if attached_vehicle ~= nil and attached_vehicle ~= 0 then
    local modelHash         = ENTITY.GET_ENTITY_MODEL(attached_vehicle)
    local attachedVehicle   = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(
      PED.GET_VEHICLE_PED_IS_USING(self.get_ped()),
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
      end
    end
    attached_vehicle = 0
  end

  if spawned_props[1] ~= nil then
    for i, v in ipairs(spawned_props) do
      if ENTITY.DOES_ENTITY_EXIST(v.entity) then
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(v.entity, false, false)
        ENTITY.DELETE_ENTITY(v.entity)
        table.remove(spawned_props, i)
      end
    end
  end

  if selfAttachments[1] ~= nil then
    for i, v in ipairs(selfAttachments) do
      ENTITY.DETACH_ENTITY(v.entity, true, true)
      table.remove(selfAttachments, i)
    end
  end

  if vehAttachments[1] ~= nil then
    for i, v in ipairs(vehAttachments) do
      ENTITY.DETACH_ENTITY(v.entity, true, true)
      table.remove(vehAttachments, i)
    end
  end

  if currentMvmt ~= "" then
    PED.RESET_PED_MOVEMENT_CLIPSET(self.get_ped(), 0.0)
    currentMvmt = ""
  end

  if currentWmvmt ~= "" then
    PED.RESET_PED_WEAPON_MOVEMENT_CLIPSET(self.get_ped())
    currentWmvmt = ""
  end

  if currentStrf ~= "" then
    PED.RESET_PED_STRAFE_CLIPSET(self.get_ped())
    currentStrf = ""
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
        GRAPHICS.STOP_PARTICLE_FX_LOOPED(v, false)
      end
    end
    local current_coords = self.get_pos()
    if PED.IS_PED_IN_ANY_VEHICLE(self.get_ped(), false) then
      local veh    = PED.GET_VEHICLE_PED_IS_USING(self.get_ped())
      local mySeat = Game.getPedVehicleSeat(self.get_ped())
      PED.SET_PED_INTO_VEHICLE(self.get_ped(), veh, mySeat)
    else
      ENTITY.SET_ENTITY_COORDS_NO_OFFSET(self.get_ped(), current_coords.x, current_coords.y, current_coords.z, true,
        false, false)
    end
    if plyrProps[1] ~= nil then
      for _, v in ipairs(plyrProps) do
        if ENTITY.DOES_ENTITY_EXIST(v) then
          ENTITY.SET_ENTITY_AS_MISSION_ENTITY(v, false, false)
          ENTITY.DELETE_ENTITY(v)
        end
      end
    end
    is_playing_anim = false
  end

  if spawned_npcs[1] ~= nil then
    for i, v in ipairs(spawned_npcs) do
      if ENTITY.DOES_ENTITY_EXIST(v) then
        ENTITY.DELETE_ENTITY(v)
        table.remove(spawned_npcs, i)
      end
    end
  end

  if is_playing_scenario then
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
    if ENTITY.DOES_ENTITY_EXIST(bbq) then
      ENTITY.DELETE_ENTITY(bbq)
    end
    is_playing_scenario = false
  end

  if is_playing_radio then
    if ENTITY.DOES_ENTITY_EXIST(pBus) then
      ENTITY.SET_ENTITY_AS_MISSION_ENTITY(pBus, false, false)
      ENTITY.DELETE_ENTITY(pBus)
    end
    if ENTITY.DOES_ENTITY_EXIST(dummyDriver) then
      ENTITY.DELETE_ENTITY(dummyDriver)
    end
    is_playing_radio = false
  end

  if is_handsUp then
    TASK.CLEAR_PED_TASKS(self.get_ped())
    is_handsUp = false
  end

  if isCrouched then
    PED.RESET_PED_MOVEMENT_CLIPSET(self.get_ped(), 0)
    isCrouched = false
  end

  if disable_waves then
    Game.World.disableOceanWaves(false)
    disable_waves = false
  end

  if autopilot_waypoint or autopilot_objective or autopilot_random then
    if Game.Self.isDriving() then
      TASK.CLEAR_PED_TASKS(self.get_ped())
      TASK.CLEAR_PRIMARY_VEHICLE_TASK(current_vehicle)
      autopilot_waypoint, autopilot_objective, autopilot_random = false, false, false
    end
  end

  if spawned_persist_T[1] ~= nil then
    for i, v in ipairs(spawned_persist_T) do
      if ENTITY.DOES_ENTITY_EXIST(v) then
        ENTITY.SET_ENTITY_AS_MISSION_ENTITY(v, true, true)
        ENTITY.DELETE_ENTITY(v)
        table.remove(spawned_persist_T, i)
      end
    end
  end

  if is_sitting or ENTITY.IS_ENTITY_PLAYING_ANIM(self.get_ped(), "timetable@ron@ig_3_couch", "base", 3) then
    ENTITY.DETACH_ENTITY(self.get_ped(), true, false)
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
    if ENTITY.DOES_ENTITY_EXIST(thisSeat) then
      ENTITY.FREEZE_ENTITY_POSITION(thisSeat, false)
    end
    is_sitting, thisSeat = false, 0
  end

  engine_brake_disabled, kers_boost_enabled, offroader_enabled,
  rally_tires_enabled, traction_ctrl_disabled, easy_wheelie_enabled = false, false, false, false, false, false

  if is_hiding then
    if hiding_in_boot or hiding_in_dumpster then
      ENTITY.DETACH_ENTITY(self.get_ped(), false, false)
      hiding_in_boot, hiding_in_dumpster = false, false
    end
    TASK.CLEAR_PED_TASKS(self.get_ped())
    is_hiding = false
  end
  TASK.CLEAR_PED_TASKS(self.get_ped())
end

-- Checks if localPlayer is standing near a public seat
--
-- and returns its position and rotation vectors.
SS.isNearPublicSeat = function()
  local retBool, prop, seatPos, x_offset, z_offset, myCoords = false, 0, vec3:new(0.0, 0.0, 0.0), 0.0, 1.0, self.get_pos()
  for _, seat in ipairs(world_seats_T) do
    prop = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(myCoords.x, myCoords.y, myCoords.z, 1.5, joaat(seat), false, false, false)
    if ENTITY.DOES_ENTITY_EXIST(prop) then
      seatPos = Game.getCoords(prop, false)
      local distCalc = SYSTEM.VDIST2(myCoords.x, myCoords.y, myCoords.z, seatPos.x, seatPos.y, seatPos.z)
      if distCalc <= 2 then
        retBool = true
        if string.find(string.lower(seat), "bench") and seat ~= "prop_bench_07" then
          x_offset = -0.5
        end
        if seat == "prop_hobo_seat_01" then
          z_offset = 0.8
        end
        if string.find(string.lower(seat), "skid_chair") then
          z_offset = 0.6
        end
        break
      end
    end
  end
  return retBool, prop, x_offset, z_offset
end

-- Checks if localPlayer is near a trash bin
--
-- and returns the entity handle of the bin if true.
SS.isNearTrashBin = function()
  local retBool, bin, binPos, myCoords = false, 0, vec3:new(0.0, 0.0, 0.0), self.get_pos()
  for _, trash in ipairs(trash_bins_T) do
    bin = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(myCoords.x, myCoords.y, myCoords.z, 1.5, joaat(trash), false, false, false)
    if ENTITY.DOES_ENTITY_EXIST(bin) then
      binPos = Game.getCoords(bin, false)
      local distCalc = SYSTEM.VDIST2(myCoords.x, myCoords.y, myCoords.z, binPos.x, binPos.y, binPos.z)
      if distCalc <= 3.3 then
        retBool = true
        break
      end
    end
  end
  return retBool, bin
end

-- Checks if localPlayer is near any vehicle's trunk
--
-- and returns the vehicle handle if true.
SS.isNearCarTrunk = function()
  local retBool, veh, myCoords = false, Game.getClosestVehicle(self.get_ped(), 10), self.get_pos()
  if veh ~= 0 and veh ~= nil then
    if VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(veh)) then
      local vehClass = Game.Vehicle.class(veh)
      local bootBoneName
      if vehClass == "Vans" then
        bootBoneName = "door_pside_r"
      else
        bootBoneName = "boot"
      end
      local bootBone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(veh, bootBoneName)
      if bootBone ~= -1 then
        local bonePos  = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(veh, bootBone)
        local distCalc = SYSTEM.VDIST2(bonePos.x, bonePos.y, bonePos.z, myCoords.x, myCoords.y, myCoords.z)
        if distCalc <= 3.0 then
          retBool = true
        end
      end
    end
  end
  return retBool, veh
end

-- Related to the Carpool option.
SS.updateNPCdriveTask = function()
  TASK.CLEAR_PED_TASKS(npcDriver)
  TASK.CLEAR_PED_SECONDARY_TASK(npcDriver)
  TASK.CLEAR_PRIMARY_VEHICLE_TASK(thisVeh)
  TASK.TASK_VEHICLE_TEMP_ACTION(npcDriver, thisVeh, 1, 500)
  if npcDriveTask == "wp" or npcDriveTask == "obj" then
    TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(npcDriver, thisVeh, npcDriveDest.x, npcDriveDest.y, npcDriveDest.z, npcDrivingSpeed, npcDrivingFlags, 100)
  else
    TASK.TASK_VEHICLE_DRIVE_WANDER(npcDriver, thisVeh, npcDrivingSpeed, npcDrivingFlags)
  end
  gui.show_message("Samurai's Scripts", string.format("NPC driving style changed to %s.", npcDriveSwitch == 0 and "Normal" or "Aggressive"))
end

-- Related to the Carpool option.
SS.showNPCvehicleControls = function()
  ImGui.SeparatorText("NPC Vehicle Options")
  if show_npc_veh_seat_ctrl and thisVeh ~= 0 then
    ImGui.Text("Seats:")
    if ImGui.Button(string.format("< %s", PREVIOUS_SEAT_BTN_)) then
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
    if ImGui.Button(string.format("%s >", NEXT_SEAT_BTN_)) then
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
  if npcDriver ~= 0 and ENTITY.DOES_ENTITY_EXIST(npcDriver) and not ENTITY.IS_ENTITY_DEAD(npcDriver, true)
  and PED.IS_PED_SITTING_IN_VEHICLE(npcDriver, thisVeh) then
    ImGui.Spacing(); ImGui.Text("Radio:")
    local mainRadioButtonLabel = npc_veh_radio_on and "Turn Off" or "Turn On"
    local mainRadioButtonParam = npc_veh_radio_on and "OFF" or radio_stations[math.random(1, (#radio_stations - 1))].station
    if ImGui.Button(mainRadioButtonLabel) then
      UI.widgetSound("Select2")
      script.run_in_fiber(function()
        AUDIO.SET_VEH_RADIO_STATION(thisVeh, mainRadioButtonParam)
      end)
    end
    if npc_veh_radio_on then
      ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
      if ImGui.Button("< Previous Station") then
        UI.widgetSound("Nav")
        script.run_in_fiber(function()
          AUDIO.SET_RADIO_RETUNE_DOWN()
        end)
      end
      ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
      if ImGui.Button("Next Station >") then
        UI.widgetSound("Nav")
        script.run_in_fiber(function()
          AUDIO.SET_RADIO_RETUNE_UP()
        end)
      end
    end
    if npc_veh_has_conv_roof then
      ImGui.Spacing(); ImGui.Text("Convertible Roof:")
      local roofButtonLabel
      if npc_veh_roof_state == 0 then
        roofButtonLabel = "Lower"
      elseif npc_veh_roof_state == 1 then
        roofButtonLabel = "Lowering..."
      elseif npc_veh_roof_state == 2 then
        roofButtonLabel = "Raise"
      elseif npc_veh_roof_state == 3 then
        roofButtonLabel = "Raising..."
      else
        roofButtonLabel = ""
      end
      ImGui.BeginDisabled(npc_veh_roof_state == 1 or npc_veh_roof_state == 3)
      if ImGui.Button(roofButtonLabel) then
        if npc_veh_speed > 6.66 then
          UI.widgetSound("Error")
          gui.show_error("Samurai's Scripts", "You can not operate the convertible roof at this speed.")
        end
        UI.widgetSound("Select")
        script.run_in_fiber(function()
          if npc_veh_roof_state == 0 then
            VEHICLE.LOWER_CONVERTIBLE_ROOF(thisVeh, false)
          elseif npc_veh_roof_state == 2 then
            VEHICLE.RAISE_CONVERTIBLE_ROOF(thisVeh, false)
          end
        end)
      end
      ImGui.EndDisabled()
    end
    ImGui.Spacing(); ImGui.Text("Driving Commands:")
    ImGui.BulletText("Driving Style:"); ImGui.SameLine(); npcDriveSwitch, isChanged = ImGui.RadioButton("Chill", npcDriveSwitch, 0)
    if isChanged then
      UI.widgetSound("Nav")
      npcDrivingFlags = 803243
      npcDrivingSpeed = 19
      script.run_in_fiber(function()
        TASK.SET_DRIVE_TASK_DRIVING_STYLE(npcDriver, 803243)
        TASK.SET_DRIVE_TASK_CRUISE_SPEED(npcDriver, 19.0)
        SS.updateNPCdriveTask()
      end)
    end
    ImGui.SameLine(); npcDriveSwitch, isChanged = ImGui.RadioButton("Aggressive", npcDriveSwitch, 1)
    if isChanged then
      UI.widgetSound("Nav")
      npcDrivingFlags = 787324
      npcDrivingSpeed = 70.0
      script.run_in_fiber(function()
        TASK.SET_DRIVE_TASK_DRIVING_STYLE(npcDriver, 787324)
        TASK.SET_DRIVE_TASK_CRUISE_SPEED(npcDriver, 70.0)
        SS.updateNPCdriveTask()
      end)
    end
    if ImGui.Button("Stop The Vehicle") then
      script.run_in_fiber(function(stp)
        TASK.CLEAR_PED_TASKS(npcDriver)
        TASK.CLEAR_PED_SECONDARY_TASK(npcDriver)
        TASK.CLEAR_PRIMARY_VEHICLE_TASK(thisVeh)
        if not VEHICLE.IS_VEHICLE_STOPPED(thisVeh) then
          TASK.TASK_VEHICLE_TEMP_ACTION(npcDriver, thisVeh, 1, 5000)
          repeat
            stp:sleep(10)
          until VEHICLE.IS_VEHICLE_STOPPED(thisVeh)
          ENTITY.FREEZE_ENTITY_POSITION(thisVeh, true)
        end
        npcDriveTask = ""
        repeat
          stp:sleep(10)
        until npcDriveTask ~= "" or not PED.IS_PED_SITTING_IN_VEHICLE(self.get_ped(), thisVeh) or ENTITY.IS_ENTITY_DEAD(npcDriver, true)
        ENTITY.FREEZE_ENTITY_POSITION(thisVeh, false)
      end)
    end
    if ImGui.Button("Drive Around") then
      script.run_in_fiber(function()
        if npcDriveTask ~= "" then
          TASK.CLEAR_PED_TASKS(npcDriver)
          TASK.CLEAR_PED_SECONDARY_TASK(npcDriver)
          TASK.CLEAR_PRIMARY_VEHICLE_TASK(thisVeh)
        end
        TASK.TASK_VEHICLE_DRIVE_WANDER(npcDriver, thisVeh, npcDrivingSpeed, npcDrivingFlags)
        npcDriveTask = "random"
        gui.show_message("Samurai's Scripts", "Cruising around...")
      end)
    end
    ImGui.SameLine()
    if ImGui.Button("Drive To Waypoint") then
      script.run_in_fiber(function()
        local waypoint = HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_WAYPOINT_BLIP_ENUM_ID())
        if not HUD.DOES_BLIP_EXIST(waypoint) then
          UI.widgetSound("Error")
          gui.show_error("Samurai's Scripts", "Please set a waypoint on the map first!")
          return
        else
          UI.widgetSound("Select")
          if npcDriveTask ~= "" then
            TASK.CLEAR_PED_TASKS(npcDriver)
            TASK.CLEAR_PED_SECONDARY_TASK(npcDriver)
            TASK.CLEAR_PRIMARY_VEHICLE_TASK(thisVeh)
          end
          npcDriveDest = HUD.GET_BLIP_COORDS(waypoint)
          TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(npcDriver, thisVeh, npcDriveDest.x, npcDriveDest.y, npcDriveDest.z, npcDrivingSpeed, npcDrivingFlags, 100)
          npcDriveTask = "wp"
          gui.show_message("Samurai's Scripts", "Driving to waypoint...")
        end
      end)
    end
    ImGui.SameLine()
    if ImGui.Button("Drive To Objective") then
      local objective_found, objective_coords = Game.findObjectiveBlip()
      if not objective_found then
        UI.widgetSound("Error")
        gui.show_error("Samurai's Scripts", "No objective found!")
      else
        npcDriveDest = objective_coords
        TASK.TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE(npcDriver, thisVeh, npcDriveDest.x, npcDriveDest.y, npcDriveDest.z, npcDrivingSpeed, npcDrivingFlags, 100)
        npcDriveTask = "obj"
        gui.show_message("Samurai's Scripts", "Driving to objective...")
      end
    end
  end
  ImGui.Separator()
end

-- Reads localPlayer's vehicle information from memory.
SS.getVehicleInfo = function()
  local vehPtr = memory.handle_to_ptr(self.get_veh())
  ---@class vehicleInfo
  local vehicleInfo = {}
  vehicleInfo.__index = vehicleInfo
  if vehPtr:is_valid() then
    local CHandlingData  = vehPtr:add(0x0960):deref()
    local CVehicleDamage = vehPtr:add(0x0420)
    local CDeformation   = CVehicleDamage:add(0x0010)
    vehicleInfo.m_model_flags       = CHandlingData:add(0x0124)
    vehicleInfo.m_handling_flags    = CHandlingData:add(0x0128)
    vehicleInfo.m_deformation_mult  = CHandlingData:add(0x00F8)
    vehicleInfo.m_sub_handling_data = CHandlingData:add(0x158):deref()
    vehicleInfo.m_deformation       = CDeformation:add(0x0000)
    vehicleInfo.m_deform_god        = vehPtr:add(0x096C)
  end
  return vehicleInfo
end

-- Checks if a handling flag is enabled or disabled
--
-- for localPlayer's current vehicle.
---@param flag number
SS.getHandlingFlagState = function(flag)
  local m_handling_flags = SS.getVehicleInfo().m_handling_flags
  local handling_flags   = m_handling_flags:get_dword()
  return Lua_fn.has_bit(handling_flags, flag)
end

-- Enables or disables a handling flag for localPlayer's vehicle.
---@param flag number
---@param switch boolean
SS.setHandlingFlag = function(flag, switch)
  if not is_car and not is_bike and not is_quad then
    return
  end
  local m_handling_flags = SS.getVehicleInfo().m_handling_flags
  local handling_flags   = m_handling_flags:get_dword()
  local bitwiseOp = switch and Lua_fn.set_bit or Lua_fn.clear_bit
  local new_flag  = bitwiseOp(handling_flags, flag)
  m_handling_flags:set_dword(new_flag)
end

---@unused
---@param dword integer
SS.setWeaponEffectGroup = function(dword)
  local pedPtr = memory.handle_to_ptr(self.get_ped())
  if pedPtr:is_valid() then
    local CPedWeaponManager = pedPtr:add(0x10B8):deref()
    local CWeaponInfo       = CPedWeaponManager:add(0x0020):deref()
    local sWeaponFx         = CWeaponInfo:add(0x0170)
    local eEffectGroup      = sWeaponFx:add(0x00) -- int32_t
    eEffectGroup:set_dword(dword)
  end
end

-- Returns the model type of an entity (ped, object, vehicle, MLO, time, etc...)
---@param entity integer
SS.getEntityType = function(entity)
  if ENTITY.DOES_ENTITY_EXIST(entity) then
    local entPtr = memory.handle_to_ptr(entity)
    if entPtr:is_valid() then
      local m_model_info = entPtr:add(0x0020):deref()
      local m_model_type = m_model_info:add(0x009D)
      return m_model_type:get_word()
    end
  end
  return 0
end

-- Reads information about the player from memory.
--
-- **Note:** param `ped` is a Ped ID, not a Player ID.
---@param ped integer
SS.getPlayerInfo = function(ped)
  local pedPtr = memory.handle_to_ptr(ped)
  if pedPtr:is_valid() then
    ---@class pedInfo
    local pedInfo   = setmetatable({}, {})
    pedInfo.__index = pedInfo
    local gameState <const> = {
      { str = "Invalid",       int = -1 },
      { str = "Playing",       int = 0 },
      { str = "Died",          int = 1 },
      { str = "Arrested",      int = 2 },
      { str = "FailedMission", int = 3 },
      { str = "LeftGame",      int = 4 },
      { str = "Respawn",       int = 5 },
      { str = "InMPCutscene",  int = 6 },
    }
    local CPlayerInfo         = pedPtr:add(0x10A8):deref()
    local m_ped_type          = pedPtr:add(0x1098) -- uint32_t
    local m_ped_task_flag     = pedPtr:add(0x144B) -- uint8_t
    local m_seatbelt          = pedPtr:add(0x143C):get_word() -- uint8_t
    pedInfo.ped_type          = m_ped_type:get_dword()
    pedInfo.task_flag         = m_ped_task_flag:get_word()
    pedInfo.swim_speed_ptr    = CPlayerInfo:add(0x01C8)
    pedInfo.run_speed_ptr     = CPlayerInfo:add(0x0D50)
    pedInfo.velocity_ptr      = CPlayerInfo:add(0x0300)
    pedInfo.canPedRagdoll = function()
      return (pedInfo.ped_type & 0x20) > 0
    end;
    pedInfo.hasSeatbelt = function()
      return (m_seatbelt & 0x3) > 0
    end;
    pedInfo.getGameState = function()
      local m_game_state = CPlayerInfo:add(0x0230):get_dword()
      for _, v in ipairs(gameState) do
        if m_game_state == v.int then
          return v.str
        end
      end
    end;
    return pedInfo
  end
end

SS.get_ceo_global_offset = function(crates)
  local offset
  if crates ~= nil then
    if crates == 1 then
      offset = 15732 -- EXEC_CONTRABAND_SALE_VALUE_THRESHOLD1
    end
    if crates == 2 then
      offset = 15733
    end
    if crates == 3 then
      offset = 15734
    end
    if crates == 4 or crates == 5 then
      offset = 15735
    end
    if crates == 6 or crates == 7 then
      offset = 15736
    end
    if crates == 8 or crates == 9 then
      offset = 15737
    end
    if crates >= 10 and crates <= 14 then
      offset = 15738
    end
    if crates >= 15 and crates <= 19 then
      offset = 15739
    end
    if crates >= 20 and crates <= 24 then
      offset = 15740
    end
    if crates >= 25 and crates <= 29 then
      offset = 15741
    end
    if crates >= 30 and crates <= 34 then
      offset = 15742
    end
    if crates >= 35 and crates <= 39 then
      offset = 15743
    end
    if crates >= 40 and crates <= 44 then
      offset = 15744
    end
    if crates >= 45 and crates <= 49 then
      offset = 15745
    end
    if crates >= 50 and crates <= 59 then
      offset = 15746
    end
    if crates >= 60 and crates <= 69 then
      offset = 15747
    end
    if crates >= 70 and crates <= 79 then
      offset = 15748
    end
    if crates >= 80 and crates <= 89 then
      offset = 15749
    end
    if crates >= 90 and crates <= 99 then
      offset = 15750
    end
    if crates >= 100 and crates <= 110 then
      offset = 15751
    end
    if crates == 111 then
      offset = 15752
    end
  else
    offset = 0
  end
  return offset
end

-- Reset saved config without affecting
--
-- custom outfits and custom vehicles.
SS.reset_settings = function()
  shortcut_anim = {}; CFG.save("shortcut_anim", shortcut_anim)
  vmine_type = { spikes = false, slick = false, explosive = false, emp = false, kinetic = false }; CFG.save(
    "vmine_type", vmine_type)
  whouse_1_size = { small = false, medium = false, large = false }; CFG.save("whouse_1_size", whouse_1_size)
  whouse_2_size = { small = false, medium = false, large = false }; CFG.save("whouse_2_size", whouse_2_size)
  whouse_3_size = { small = false, medium = false, large = false }; CFG.save("whouse_3_size", whouse_3_size)
  whouse_4_size = { small = false, medium = false, large = false }; CFG.save("whouse_4_size", whouse_4_size)
  whouse_5_size = { small = false, medium = false, large = false }; CFG.save("whouse_5_size", whouse_5_size)
  keybinds = {
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
    missl_def     = { code = 0x0,  name = "[Unbound]"},
    vehicle_mine  = { code = 0x4E, name = "[N]" },
    triggerbotBtn = { code = 0x10, name = "[Shift]" },
    panik         = { code = 0x7B, name = "[F12]" },
  }; CFG.save("keybinds", keybinds)
  gpad_keybinds = {
    rodBtn        = { code = 0, name = "[Unbound]" },
    tdBtn         = { code = 0, name = "[Unbound]" },
    nosBtn        = { code = 0, name = "[Unbound]" },
    flatbedBtn    = { code = 0, name = "[Unbound]" },
    purgeBtn      = { code = 0, name = "[Unbound]" },
    vehicle_mine  = { code = 0, name = "[Unbound]" },
    triggerbotBtn = { code = 0, name = "[Unbound]" },
  }; CFG.save("gpad_keybinds", gpad_keybinds)
  Regen = false; CFG.save("Regen", Regen)
  -- objectiveTP             = false
  disableTooltips         = false; CFG.save("disableTooltips", disableTooltips)
  phoneAnim               = false; CFG.save("phoneAnim", phoneAnim)
  sprintInside            = false; CFG.save("sprintInside", sprintInside)
  lockpick                = false; CFG.save("lockpick", lockpick)
  replaceSneakAnim        = false; CFG.save("replaceSneakAnim", replaceSneakAnim)
  replacePointAct         = false; CFG.save("replacePointAct", replacePointAct)
  disableSound            = false; CFG.save("disableSound", disableSound)
  disableActionMode       = false; CFG.save("disableActionMode", disableActionMode)
  hideFromCops            = false; CFG.save("hideFromCops", hideFromCops)
  rod                     = false; CFG.save("rod", rod)
  clumsy                  = false; CFG.save("clumsy", clumsy)
  ragdoll_sound           = false; CFG.save("ragdoll_sound", ragdoll_sound)
  Triggerbot              = false; CFG.save("Triggerbot", Triggerbot)
  aimEnemy                = false; CFG.save("aimEnemy", aimEnemy)
  autoKill                = false; CFG.save("autoKill", autoKill)
  runaway                 = false; CFG.save("runaway", runaway)
  laserSight              = false; CFG.save("laserSight", laserSight)
  disableUiSounds         = false; CFG.save("disableUiSounds", disableUiSounds)
  driftMode               = false; CFG.save("driftMode", driftMode)
  DriftTires              = false; CFG.save("DriftTires", DriftTires)
  DriftSmoke              = false; CFG.save("DriftSmoke", DriftSmoke)
  driftMinigame           = false; CFG.save("driftMinigame", driftMinigame)
  speedBoost              = false; CFG.save("speedBoost", speedBoost)
  nosvfx                  = false; CFG.save("nosvfx", nosvfx)
  nosAudio                = false; CFG.save("nosAudio", nosAudio)
  nosFlames               = false; CFG.save("nosFlames", nosFlames)
  hornLight               = false; CFG.save("hornLight", hornLight)
  nosPurge                = false; CFG.save("nosPurge", nosPurge)
  insta180                = false; CFG.save("insta180", insta180)
  flappyDoors             = false; CFG.save("flappyDoors", flappyDoors)
  rgbLights               = false; CFG.save("rgbLights", rgbLights)
  loud_radio              = false; CFG.save("loud_radio", loud_radio)
  launchCtrl              = false; CFG.save("launchCtrl", launchCtrl)
  popsNbangs              = false; CFG.save("popsNbangs", popsNbangs)
  limitVehOptions         = false; CFG.save("limitVehOptions", limitVehOptions)
  missiledefense          = false; CFG.save("missiledefense", missiledefense)
  louderPops              = false; CFG.save("louderPops", louderPops)
  autobrklight            = false; CFG.save("autobrklight", autobrklight)
  holdF                   = false; CFG.save("holdF", holdF)
  keepWheelsTurned        = false; CFG.save("keepWheelsTurned", keepWheelsTurned)
  towEverything           = false; CFG.save("towEverything", towEverything)
  noJacking               = false; CFG.save("noJacking", noJacking)
  noEngineBraking         = false; CFG.save("noEngineBraking", noEngineBraking)
  kersBoost               = false; CFG.save("kersBoost", kersBoost)
  offroaderx2             = false; CFG.save("offroaderx2", offroaderx2)
  rallyTires              = false; CFG.save("rallyTires", rallyTires)
  noTractionCtrl          = false; CFG.save("noTractionCtrl", noTractionCtrl)
  easyWheelie             = false; CFG.save("easyWheelie", easyWheelie)
  rwSteering              = false; CFG.save("rwSteering", rwSteering)
  awSteering              = false; CFG.save("awSteering", awSteering)
  handbrakeSteering       = false; CFG.save("handbrakeSteering", handbrakeSteering)
  useGameLang             = false; CFG.save("useGameLang", useGameLang)
  disableProps            = false; CFG.save("disableProps", disableProps)
  manualFlags             = false; CFG.save("manualFlags", manualFlags)
  controllable            = false; CFG.save("controllable", controllable)
  looped                  = false; CFG.save("looped", looped)
  upperbody               = false; CFG.save("upperbody", upperbody)
  freeze                  = false; CFG.save("freeze", freeze)
  noCollision             = false; CFG.save("noCollision", noCollision)
  killOnEnd               = false; CFG.save("killOnEnd", killOnEnd)
  usePlayKey              = false; CFG.save("usePlayKey", usePlayKey)
  npc_godMode             = false; CFG.save("npc_godMode", npc_godMode)
  bypass_casino_bans      = false; CFG.save("bypass_casino_bans", bypass_casino_bans)
  force_poker_cards       = false; CFG.save("force_poker_cards", force_poker_cards)
  set_dealers_poker_cards = false; CFG.save("set_dealers_poker_cards", set_dealers_poker_cards)
  force_roulette_wheel    = false; CFG.save("force_roulette_wheel", force_roulette_wheel)
  rig_slot_machine        = false; CFG.save("rig_slot_machine", rig_slot_machine)
  autoplay_slots          = false; CFG.save("autoplay_slots", autoplay_slots)
  autoplay_cap            = false; CFG.save("autoplay_cap", autoplay_cap)
  heist_cart_autograb     = false; CFG.save("heist_cart_autograb", heist_cart_autograb)
  flares_forall           = false; CFG.save("flares_forall", flares_forall)
  real_plane_speed        = false; CFG.save("real_plane_speed", real_plane_speed)
  extend_world            = false; CFG.save("extend_world", extend_world)
  unbreakableWindows      = false; CFG.save("unbreakableWindows", unbreakableWindows)
  disableFlightMusic      = false; CFG.save("disableFlightMusic", disableFlightMusic)
  disable_quotes          = false; CFG.save("disable_quotes", disable_quotes)
  disable_mdef_logs       = false; CFG.save("disable_mdef_logs", disable_mdef_logs)
  replace_pool_q          = false; CFG.save("replace_pool_q", replace_pool_q)
  public_seats            = false; CFG.save("public_seats", public_seats)
  mc_work_cd              = false; CFG.save("mc_work_cd", mc_work_cd)
  hangar_cd               = false; CFG.save("hangar_cd", hangar_cd)
  nc_management_cd        = false; CFG.save("nc_management_cd", nc_management_cd)
  nc_vip_mission_chance   = false; CFG.save("nc_vip_mission_chance", nc_vip_mission_chance)
  security_missions_cd    = false; CFG.save("security_missions_cd", security_missions_cd)
  ie_vehicle_steal_cd     = false; CFG.save("ie_vehicle_steal_cd", ie_vehicle_steal_cd)
  ie_vehicle_sell_cd      = false; CFG.save("ie_vehicle_sell_cd", ie_vehicle_sell_cd)
  ceo_crate_buy_cd        = false; CFG.save("ceo_crate_buy_cd", ceo_crate_buy_cd)
  ceo_crate_sell_cd       = false; CFG.save("ceo_crate_sell_cd", ceo_crate_sell_cd)
  ceo_crate_buy_f_cd      = false; CFG.save("ceo_crate_buy_f_cd", ceo_crate_buy_f_cd)
  ceo_crate_sell_f_cd     = false; CFG.save("ceo_crate_sell_f_cd", ceo_crate_sell_f_cd)
  cashUpdgrade1           = false; CFG.save("cashUpdgrade1", cashUpdgrade1)
  cashUpdgrade2           = false; CFG.save("cashUpdgrade2", cashUpdgrade2)
  cokeUpdgrade1           = false; CFG.save("cokeUpdgrade1", cokeUpdgrade1)
  cokeUpdgrade2           = false; CFG.save("cokeUpdgrade2", cokeUpdgrade2)
  methUpdgrade1           = false; CFG.save("methUpdgrade1", methUpdgrade1)
  methUpdgrade2           = false; CFG.save("methUpdgrade2", methUpdgrade2)
  weedUpdgrade1           = false; CFG.save("weedUpdgrade1", weedUpdgrade1)
  weedUpdgrade2           = false; CFG.save("weedUpdgrade2", weedUpdgrade2)
  fdUpdgrade1             = false; CFG.save("fdUpdgrade1", fdUpdgrade1)
  fdUpdgrade2             = false; CFG.save("fdUpdgrade2", fdUpdgrade2)
  bunkerUpdgrade1         = false; CFG.save("bunkerUpdgrade1", bunkerUpdgrade1)
  bunkerUpdgrade2         = false; CFG.save("bunkerUpdgrade2", bunkerUpdgrade2)
  acidUpdgrade            = false; CFG.save("acidUpdgrade", acidUpdgrade)
  whouse_1_owned          = false; CFG.save("whouse_1_owned", whouse_1_owned)
  whouse_2_owned          = false; CFG.save("whouse_2_owned", whouse_2_owned)
  whouse_3_owned          = false; CFG.save("whouse_3_owned", whouse_3_owned)
  whouse_4_owned          = false; CFG.save("whouse_4_owned", whouse_4_owned)
  whouse_5_owned          = false; CFG.save("whouse_5_owned", whouse_5_owned)
  veh_mines               = false; CFG.save("veh_mines", veh_mines)
  SS_debug                = false; CFG.save("SS_debug", SS_debug)
  laser_switch            = 0; CFG.save("laser_switch", laser_switch)
  DriftIntensity          = 0; CFG.save("DriftIntensity", DriftIntensity)
  lang_idx                = 0; CFG.save("lang_idx", lang_idx)
  autoplay_chips_cap      = 0; CFG.save("autoplay_chips_cap", autoplay_chips_cap)
  lightSpeed              = 1; CFG.save("lightSpeed", lightSpeed)
  DriftPowerIncrease      = 1; CFG.save("DriftPowerIncrease", DriftPowerIncrease)
  nosPower                = 10; CFG.save("nosPower", nosPower)
  nosBtn                  = 21; CFG.save("nosBtn", nosBtn)
  supply_autofill_delay   = 500; CFG.save("supply_autofill_delay", supply_autofill_delay)
  laser_choice            = { r = 237, g = 47, b = 50 }; CFG.save("laser_choice", laser_choice)
  LANG                    = "en-US"; CFG.save("LANG", LANG)
  current_lang            = "English"; CFG.save("current_lang", current_lang)
  initStrings()
end


-- GTA helpers.
---@class Game
Game = {}
Game.__index = Game

--[[

  Returns GTA V's current build number.

  **Credits:** [tupoy-ya](https://github.com/tupoy-ya)

]]
---@return string
Game.GetBuildNumber = function()
  return game_build_offset:get_string()
end

--[[

  Returns GTA V's current online version.

  **Credits:** [tupoy-ya](https://github.com/tupoy-ya)

]]
---@return string
Game.GetOnlineVersion = function()
  return online_version_offset:get_string()
end

Game.GetLang = function()
  local language_codes_T <const> = {
    { name = "English",             id = 0,  iso = "en-US" },
    { name = "French",              id = 1,  iso = "fr-FR" },
    { name = "German",              id = 2,  iso = "de-DE" },
    { name = "Italian",             id = 3,  iso = "it-IT" },
    { name = "Spanish, Spain",      id = 4,  iso = "es-ES" },
    { name = "Portugese",           id = 5,  iso = "pt-BR" },
    { name = "Polish",              id = 6,  iso = "pl-PL" },
    { name = "Russian",             id = 7,  iso = "ru-RU" },
    { name = "Korean",              id = 8,  iso = "ko-KR" },
    { name = "Chinese Traditional", id = 9,  iso = "zh-TW" },
    { name = "Japanese",            id = 10, iso = "ja-JP" },
    { name = "Spanish, Mexico",     id = 11, iso = "es-MX" },
    { name = "Chinese Simplified",  id = 12, iso = "zh-CN" },
  }
  local lang_iso, lang_name
  local lang = LOCALIZATION.GET_CURRENT_LANGUAGE()
  for _, l in ipairs(language_codes_T) do
    if lang == l.id then
      lang_iso  = l.iso
      lang_name = l.name
      break
    else
      lang_iso  = "en-US"
      lang_name = "English"
    end
  end
  if lang_iso == "es-MX" then
    lang_iso = "es-ES"
  end
  return lang_iso, lang_name
end

Game.getKeyPressed = function()
  local btn, gpad
  local controls_T <const> = {
    { ctrl = 7,   gpad = "[R3]" },
    { ctrl = 10,  gpad = "[LT]" },
    { ctrl = 11,  gpad = "[RT]" },
    { ctrl = 14,  gpad = "[DPAD RIGHT]" },
    { ctrl = 15,  gpad = "[DPAD LEFT]" },
    { ctrl = 19,  gpad = "[DPAD DOWN]" },
    { ctrl = 20,  gpad = "[DPAD DOWN]" },
    { ctrl = 21,  gpad = "[A]" },
    { ctrl = 22,  gpad = "[X]" },
    { ctrl = 23,  gpad = "[Y]" },
    { ctrl = 27,  gpad = "[DPAD UP]" },
    { ctrl = 29,  gpad = "[R3]" },
    { ctrl = 30,  gpad = "[LEFT STICK]" },
    { ctrl = 34,  gpad = "[LEFT STICK]" },
    { ctrl = 36,  gpad = "[L3]" },
    { ctrl = 37,  gpad = "[LB]" },
    { ctrl = 38,  gpad = "[LB]" },
    { ctrl = 42,  gpad = "[DPAD UP]" },
    { ctrl = 43,  gpad = "[DPAD DOWN]" },
    { ctrl = 44,  gpad = "[RB]" },
    { ctrl = 45,  gpad = "[B]" },
    { ctrl = 46,  gpad = "[DPAD RIGHT]" },
    { ctrl = 47,  gpad = "[DPAD LEFT]" },
    { ctrl = 56,  gpad = "[Y]" },
    { ctrl = 57,  gpad = "[B]" },
    { ctrl = 70,  gpad = "[A]" },
    { ctrl = 71,  gpad = "[RT]" },
    { ctrl = 72,  gpad = "[LT]" },
    { ctrl = 73,  gpad = "[A]" },
    { ctrl = 74,  gpad = "[DPAD RIGHT]" },
    { ctrl = 75,  gpad = "[Y]" },
    { ctrl = 76,  gpad = "[RB]" },
    { ctrl = 79,  gpad = "[R3]" },
    { ctrl = 81,  gpad = "(NONE)" },
    { ctrl = 82,  gpad = "(NONE)" },
    { ctrl = 83,  gpad = "(NONE)" },
    { ctrl = 84,  gpad = "(NONE)" },
    { ctrl = 84,  gpad = "[DPAD LEFT]" },
    { ctrl = 96,  gpad = "(NONE)" },
    { ctrl = 97,  gpad = "(NONE)" },
    { ctrl = 124, gpad = "[LEFT STICK]" },
    { ctrl = 125, gpad = "[LEFT STICK]" },
    { ctrl = 112, gpad = "[LEFT STICK]" },
    { ctrl = 127, gpad = "[LEFT STICK]" },
    { ctrl = 117, gpad = "[LB]" },
    { ctrl = 118, gpad = "[RB]" },
    { ctrl = 167, gpad = "(NONE)" },
    { ctrl = 168, gpad = "(NONE)" },
    { ctrl = 169, gpad = "(NONE)" },
    { ctrl = 170, gpad = "[B]" },
    { ctrl = 172, gpad = "[DPAD UP]" },
    { ctrl = 173, gpad = "[DPAD DOWN]" },
    { ctrl = 174, gpad = "[DPAD LEFT]" },
    { ctrl = 175, gpad = "[DPAD RIGHT]" },
    { ctrl = 178, gpad = "[Y]" },
    { ctrl = 194, gpad = "[B]" },
    { ctrl = 243, gpad = "(NONE)" },
    { ctrl = 244, gpad = "[BACK]" },
    { ctrl = 249, gpad = "(NONE)" },
    { ctrl = 288, gpad = "[A]" },
    { ctrl = 289, gpad = "[X]" },
    { ctrl = 303, gpad = "[DPAD UP]" },
    { ctrl = 307, gpad = "[DPAD RIGHT]" },
    { ctrl = 308, gpad = "[DPAD LEFT]" },
    { ctrl = 311, gpad = "[DPAD DOWN]" },
    { ctrl = 318, gpad = "[START]" },
    { ctrl = 322, gpad = "(NONE)" },
    { ctrl = 344, gpad = "[DPAD RIGHT]" },
  }
  for _, v in ipairs(controls_T) do
    if PAD.IS_CONTROL_JUST_PRESSED(0, v.ctrl) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, v.ctrl) then
      btn, gpad = v.ctrl, v.gpad
    end
  end
  if not PAD.IS_USING_KEYBOARD_AND_MOUSE(0) then
    return btn, gpad
  else
    return nil, nil
  end
end

Game.isOnline = function()
  return network.is_session_started()
end

---@param ped integer
Game.is_in_session = function(ped)
  return (Game.isOnline() and not script.is_active("maintransition"))
    and SS.getPlayerInfo(ped).getGameState() ~= "Invalid"
    and SS.getPlayerInfo(ped).getGameState() ~= "LeftGame"
end

Game.getPlayerList = function()
  filteredPlayers = {}
  local players = entities.get_all_peds_as_handles()
  for _, ped in ipairs(players) do
    if PED.IS_PED_A_PLAYER(ped) and Game.is_in_session(ped) then
      table.insert(filteredPlayers, ped)
    end
  end
end

Game.filterPlayerList = function()
  Game.getPlayerList()
  local playerNames = {}
  for _, player in ipairs(filteredPlayers) do
    local playerIdx   = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(player)
    local playerName  = PLAYER.GET_PLAYER_NAME(playerIdx)
    local playerHost  = NETWORK.NETWORK_GET_HOST_PLAYER_INDEX()
    if playerIdx == self.get_id() then
      playerName = playerName .. "  [You]"
    end
    if network.is_player_friend(playerIdx) then
      playerName = playerName .. "  [Friend]"
    end
    if playerHost == playerIdx then
      playerName = playerName .. "  [Host]"
    end
    table.insert(playerNames, playerName)
  end
  return playerNames
end

-- Displays all players in the session inside an ImGui Combo
Game.displayPlayerListCombo = function()
  Game.getPlayerList()
  local playerNames = Game.filterPlayerList()
  playerIndex, used = ImGui.Combo("##playerList", playerIndex, playerNames, #filteredPlayers)
end

-- Returns the number of players in an online session.
---@return number
Game.getPlayerCount = function()
  if Game.isOnline() then
    return NETWORK.NETWORK_GET_NUM_CONNECTED_PLAYERS()
  end
  return 0
end

-- Returns the player's cash
---@param player integer
Game.getPlayerWallet = function(player)
  if player ~= self.get_id() then
    return Lua_fn.formatMoney(network.get_player_wallet(player)), 0
  end

  local wallet_int = (tonumber(Lua_fn.str_replace(MONEY.NETWORK_GET_STRING_WALLET_BALANCE(stats.get_character_index()), "$", "")) * 1)
  local formatted  = Lua_fn.formatMoney(wallet_int)
  return formatted, wallet_int
end

-- Returns the player's bank balance
---@param player integer
Game.getPlayerBank = function(player)
  if player ~= self.get_id() then
    return Lua_fn.formatMoney(network.get_player_bank(player))
  end

  local _, wallet_int = Game.getPlayerWallet(self.get_id())
  local bank = (tonumber(Lua_fn.str_replace(MONEY.NETWORK_GET_STRING_BANK_WALLET_BALANCE(stats.get_character_index()), "$", "")) - wallet_int)
  return Lua_fn.formatMoney(bank)
end

-- Returns the player's RP rank.
---@param player integer
Game.getPlayerRank = function(player)
  if player ~= self.get_id() then
    return tostring(network.get_player_rank(player))
  end

  local self_rp = stats.get_int("MPX_CHAR_XP_FM")
  for i = 1, #rp_levels do
    if i < #rp_levels then
      if self_rp == rp_levels[i] or (self_rp > rp_levels[i] and self_rp < rp_levels[i+1]) then
        return i
      end
    end
  end
  return 8000
end

---@param text string
---@param type integer
Game.busySpinnerOn = function(text, type)
  HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("STRING")
  HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
  HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(type)
end

Game.busySpinnerOff = function()
  return HUD.BUSYSPINNER_OFF()
end

---@param text string
Game.showButtonPrompt = function(text)
  HUD.BEGIN_TEXT_COMMAND_DISPLAY_HELP("STRING")
  HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
  HUD.END_TEXT_COMMAND_DISPLAY_HELP(0, false, true, -1)
end

---@param entity integer
Game.createBlip = function(entity)
  return HUD.ADD_BLIP_FOR_ENTITY(entity)
end

-- Full list of blip icon IDs: https://wiki.rage.mp/index.php?title=Blips
---@param blip integer
---@param icon integer
Game.blipIcon = function(blip, icon)
  HUD.SET_BLIP_SPRITE(blip, icon)
end

-- Sets a custom name for a blip. Custom names appear on the pause menu and the world map.
---@param blip integer
---@param name string
Game.blipName = function(blip, name)
  HUD.BEGIN_TEXT_COMMAND_SET_BLIP_NAME("STRING")
  HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(name)
  HUD.END_TEXT_COMMAND_SET_BLIP_NAME(blip)
end

---@param model integer
Game.requestModel = function(model)
  local counter = 0
  while not STREAMING.HAS_MODEL_LOADED(model) do
    STREAMING.REQUEST_MODEL(model)
    coroutine.yield()
    if counter > 100 then
      return
    else
      counter = counter + 1
    end
  end
  return STREAMING.HAS_MODEL_LOADED(model)
end

---@param model integer
---@param s script_util
Game.getModelDimensions = function(model, s)
  local vmin, vmax = vec3:new(0.0, 0.0, 0.0), vec3:new(0.0, 0.0, 0.0)
  if STREAMING.IS_MODEL_VALID(model) then
    if Game.requestModel(model) then
      vmin, vmax = MISC.GET_MODEL_DIMENSIONS(model, vmin, vmax)
      s:sleep(100)
      STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model)
    end
  end
  return vmin, vmax
end

---@param dict string
Game.requestNamedPtfxAsset = function(dict)
  local counter = 0
  while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(dict) do
    STREAMING.REQUEST_NAMED_PTFX_ASSET(dict)
    coroutine.yield()
    if counter > 100 then
      return
    else
      counter = counter + 1
    end
  end
  return STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(dict)
end

---@param dict string
Game.requestAnimDict = function(dict)
  while not STREAMING.HAS_ANIM_DICT_LOADED(dict) do
    STREAMING.REQUEST_ANIM_DICT(dict)
    coroutine.yield()
  end
  return STREAMING.HAS_ANIM_DICT_LOADED(dict)
end

---@param weapon integer
Game.requestWeaponAsset = function(weapon)
  while not WEAPON.HAS_WEAPON_ASSET_LOADED(weapon) do
    WEAPON.REQUEST_WEAPON_ASSET(weapon, 31, 0)
    coroutine.yield()
  end
  return WEAPON.HAS_WEAPON_ASSET_LOADED(weapon)
end

---@param entity integer
---@param isAlive boolean
Game.getCoords = function(entity, isAlive)
  local coords = ENTITY.GET_ENTITY_COORDS(entity, isAlive)
  return vec3:new(coords.x, coords.y, coords.z)
end

---@param entity integer
Game.getHeading = function(entity)
  return ENTITY.GET_ENTITY_HEADING(entity)
end

---@param entity integer
Game.getForwardX = function(entity)
  return ENTITY.GET_ENTITY_FORWARD_X(entity)
end

---@param entity integer
Game.getForwardY = function(entity)
  return ENTITY.GET_ENTITY_FORWARD_Y(entity)
end

---@param entity integer
Game.getForwardVec = function(entity)
  local fwdVec = ENTITY.GET_ENTITY_FORWARD_VECTOR(entity)
  return vec3:new(fwdVec.x, fwdVec.y, fwdVec.z)
end

---@param ped integer
---@param boneID integer
Game.getPedBoneIndex = function(ped, boneID)
  return PED.GET_PED_BONE_INDEX(ped, boneID)
end

---@param ped integer
---@param boneID integer
Game.getPedBoneCoords = function(ped, boneID)
  return PED.GET_PED_BONE_COORDS(ped, boneID, 0, 0, 0)
end

---@param entity integer
---@param boneName string
Game.getEntityBoneIndexByName = function(entity, boneName)
  return ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(entity, boneName)
end

---@param entity integer
---@param boneName string
Game.getWorldPosFromEntityBone = function(entity, boneName)
  local boneIndex = Game.getEntityBoneIndexByName(entity, boneName)
  return ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(entity, boneIndex)
end

---@param entity integer
---@param boneName string
Game.getEntityBonePos = function(entity, boneName)
  local boneIndex = Game.getEntityBoneIndexByName(entity, boneName)
  return ENTITY.GET_ENTITY_BONE_POSTION(entity, boneIndex)
end

---@param entity integer
---@param boneName string
Game.getEntityBoneRot = function(entity, boneName)
  local boneIndex = Game.getEntityBoneIndexByName(entity, boneName)
  return ENTITY.GET_ENTITY_BONE_ROTATION(entity, boneIndex)
end

---@param entity integer
Game.getEntityBoneCount = function(entity)
  return ENTITY.GET_ENTITY_BONE_COUNT(entity)
end

---Returns the entity localPlayer is aiming at.
Game.getAimedEntity = function()
  local Entity = 0
  if PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then
    _, Entity = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), Entity)
  end
  return Entity
end

---Gets the hash from an entity handle.
---@param entity integer
Game.getEntityModel = function(entity)
  return ENTITY.GET_ENTITY_MODEL(entity)
end

---Returns a number for the vehicle seat the provided ped is sitting in (-1 driver, 0 front passenger, etc...).
---@param ped integer
Game.getPedVehicleSeat = function(ped)
  if PED.IS_PED_SITTING_IN_ANY_VEHICLE(ped) then
    ---@type integer
    local pedSeat
    local vehicle  = PED.GET_VEHICLE_PED_IS_IN(ped, false)
    local maxSeats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(vehicle))
    for i = -1, maxSeats do
      if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, i, true) then
        local sittingPed = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, i, true)
        if sittingPed == ped then
          pedSeat = i
          break
        end
      end
    end
    return pedSeat
  end
end

---Returns an entity handle for the closest vehicle to a provided entity.
---@param closeTo integer
---@param range integer
Game.getClosestVehicle = function(closeTo, range)
  local vehicleHandles = entities.get_all_vehicles_as_handles()
  local closestVehicle = 0
  for _, veh in ipairs(vehicleHandles) do
    local thisPos = ENTITY.GET_ENTITY_COORDS(closeTo, true)
    local vehPos  = ENTITY.GET_ENTITY_COORDS(veh, true)
    local vDist   = SYSTEM.VDIST2(thisPos.x, thisPos.y, thisPos.z, vehPos.x, vehPos.y, vehPos.z)
    if vDist <= range then
      closestVehicle = veh
    end
  end
  return closestVehicle
end

---Returns an entity handle for the closest human ped to a provided entity.
---@param closeTo integer
---@param range integer
Game.getClosestPed = function(closeTo, range)
  local closestPed = 0
  local gtaPeds = entities.get_all_peds_as_handles()
  for _, ped in ipairs(gtaPeds) do
    if PED.IS_PED_HUMAN(ped) and ped ~= self.get_ped() then
      local thisPos      = ENTITY.GET_ENTITY_COORDS(closeTo, true)
      local randomPedPos = ENTITY.GET_ENTITY_COORDS(ped, true)
      local distCalc     = SYSTEM.VDIST2(thisPos.x, thisPos.y, thisPos.z, randomPedPos.x, randomPedPos.y,
        randomPedPos.z)
      if distCalc <= range then
        if not ENTITY.IS_ENTITY_DEAD(ped, false) then
          closestPed = ped
        end
      end
    end
  end
  return closestPed
end

-- Temporary workaround to fix auto-pilot's "fly to objective" option.
Game.findObjectiveBlip = function()
  for _, v in ipairs(objectives_T) do
    local blip = HUD.GET_FIRST_BLIP_INFO_ID(v)
    if HUD.DOES_BLIP_EXIST(blip) then
      return true, HUD.GET_BLIP_INFO_ID_COORD(blip)
    else
      local stdBlip    = HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_STANDARD_BLIP_ENUM_ID())
      local blipCoords = HUD.GET_BLIP_INFO_ID_COORD(stdBlip)
      if blipCoords ~= vec3:new(0.0, 0.0, 0.0) then
        return true, blipCoords
      else
        return false, nil
      end
    end
  end
end


--[[
-- Unused. Causes a crash on its first call then starts working fine.
-- It was supposed to be used for the laser sights feature but I'm too stupid to fix it.

-- Performs a raycast world probe shape test and returns its result.
---@param src vec3
---@param dest vec3
---@param entity integer
Game.shapeTest = function(src, dest, entity)
  local shapeTestHandle = SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
    src.x, src.y, src.z,
    dest.x, dest.y, dest.z,
    511, entity, 4
  )

  local iParam1, hit, endCoords, surfaceNormal, iParam2 = SHAPETEST.GET_SHAPE_TEST_RESULT(
    shapeTestHandle,
    hit, endCoords,
    surfaceNormal, iParam2
  )

  return (iParam1 == 2) and hit, endCoords or false
end
]]

---@class Self
Game.Self = {}
Game.Self.__index = Game.Self

---@return number
Game.Self.get_elevation = function()
  return ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(self.get_ped())
end

---@return boolean
Game.Self.is_ragdoll = function()
  return PED.IS_PED_RAGDOLL(self.get_ped())
end

-- Returns localPlayer's maximum health.
---@return integer
Game.Self.maxHealth = function()
  return ENTITY.GET_ENTITY_MAX_HEALTH(self.get_ped())
end

-- Returns localPlayer's current health.
---@return integer
Game.Self.health = function()
  return ENTITY.GET_ENTITY_HEALTH(self.get_ped())
end

-- Returns localPlayer's maximum armour.
---@return integer
Game.Self.maxArmour = function()
  return PLAYER.GET_PLAYER_MAX_ARMOUR(self.get_id())
end

-- Returns localPlayer's current armour
---@return integer
Game.Self.armour = function()
  return PED.GET_PED_ARMOUR(self.get_ped())
end

-- Checks if localPlayer is alive.
Game.Self.isAlive = function()
  if ENTITY.IS_ENTITY_DEAD(self.get_ped(), false) then
    return false
  else
    return true
  end
end

-- Checks if localPlayer is on foot.
---@return boolean
Game.Self.isOnFoot = function()
  return PED.IS_PED_ON_FOOT(self.get_ped())
end

-- Checks if localPlayer is in water.
---@return boolean
Game.Self.isInWater = function()
  return ENTITY.IS_ENTITY_IN_WATER(self.get_ped())
end

Game.Self.isSwimming = function()
  return PED.IS_PED_SWIMMING(self.get_ped()) or PED.IS_PED_SWIMMING_UNDER_WATER(self.get_ped())
end

-- Checks if localPlayer is outside.
Game.Self.isOutside = function()
  if INTERIOR.GET_INTERIOR_FROM_ENTITY(self.get_ped()) == 0 then
    return true
  else
    return false
  end
end

Game.Self.isMoving = function()
  if PED.IS_PED_STOPPED(self.get_ped()) then
    return false
  else
    return true
  end
end

Game.Self.isDriving = function()
  local retBool
  if not Game.Self.isOnFoot() then
    if Game.getPedVehicleSeat(self.get_ped()) == -1 then
      retBool = true
    else
      retBool = false
    end
  else
    retBool = false
  end
  return retBool
end

-- Returns the hash of localPlayer's selected weapon.
---@return integer
Game.Self.weapon = function()
  local weaponHash
  check, weapon = WEAPON.GET_CURRENT_PED_WEAPON(self.get_ped(), weapon, false)
  if check then
    weaponHash = weapon
  end
  return weaponHash
end

-- Teleports localPlayer to the provided coordinates.
---@param keepVehicle boolean
---@param coords vec3
Game.Self.teleport = function(keepVehicle, coords)
  script.run_in_fiber(function(selftp)
    STREAMING.REQUEST_COLLISION_AT_COORD(coords.x, coords.y, coords.z)
    selftp:sleep(200)
    if keepVehicle then
      PED.SET_PED_COORDS_KEEP_VEHICLE(self.get_ped(), coords.x, coords.y, coords.z)
    else
      if not Game.Self.isOnFoot() then
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
      end
      ENTITY.SET_ENTITY_COORDS(self.get_ped(), coords.x, coords.y, coords.z, false, false, true, false)
    end
  end)
end

---Enables or disables physical phone intercations in GTA Online
---@param toggle boolean
Game.Self.PhoneAnims = function(toggle)
  for i = 242, 244 do
    if PED.GET_PED_CONFIG_FLAG(self.get_ped(), i, true) == toggle then
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), i, not toggle)
    end
  end
end

---Enables phone gestures in GTA Online.
---@param s script_util
Game.Self.PlayPhoneGestures = function(s)
  local is_phone_in_hand   = SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(
    joaat("CELLPHONE_FLASHHAND")
  ) > 0
  local is_browsing_email  = SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(
    joaat("APPMPEMAIL")
  ) > 0
  local call_anim_dict     = "anim@scripted@freemode@ig19_mobile_phone@male@"
  local call_anim          = "base"
  local call_anim_boneMask = "BONEMASK_HEAD_NECK_AND_R_ARM"
  if AUDIO.IS_MOBILE_PHONE_CALL_ONGOING() then
    if Game.requestAnimDict(call_anim_dict) then
      TASK.TASK_PLAY_PHONE_GESTURE_ANIMATION(
        self.get_ped(), call_anim_dict, call_anim,
        call_anim_boneMask, 0.25, 0.25, true, false
      )
      repeat
        s:sleep(10)
      until not AUDIO.IS_MOBILE_PHONE_CALL_ONGOING() or not SS.canUsePhoneAnims()
      TASK.TASK_STOP_PHONE_GESTURE_ANIMATION(self.get_ped(), 0.25)
    end
  end
  if is_phone_in_hand then
    MOBILE.CELL_HORIZONTAL_MODE_TOGGLE(is_browsing_email)
    for _, v in ipairs(cell_inputs_T) do
      if PAD.IS_CONTROL_JUST_PRESSED(0, v.control) then
        MOBILE.CELL_SET_INPUT(v.input)
      end
    end
  end
end

-- Returns whether the player is currently using any mobile or computer app.
Game.Self.isBrowsingApps = function()
  for _, v in ipairs(app_script_names_T) do
    if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat(v)) > 0 then
      return true
    end
  end
  return false
end

-- Returns whether the player is currently modifying their vehicle in a modshop. <- Also returns true when just near a mod shop and not actually inside (tested with LS Customs).
Game.Self.isInCarModShop = function()
  for _, v in ipairs(modshop_script_names) do
    return script.is_active(v)
  end
  return false
end

---@class Vehicle
-- Conflicts with YimLLS `Vehicle` alias.
Game.Vehicle = {}
Game.Vehicle.__index = Game.Vehicle

-- Returns the name of the specified vehicle.
---@param vehicle number
Game.Vehicle.name = function(vehicle)
  ---@type string
  local retVal
  if ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then
    retVal = vehicles.get_vehicle_display_name(Game.getEntityModel(vehicle))
  else
    retVal = ""
  end
  return retVal
end

-- Returns the manufacturer's name of the specified vehicle.
---@param vehicle number
Game.Vehicle.manufacturer = function(vehicle)
  ---@type string
  local retVal
  if ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then
    local mfr = VEHICLE.GET_MAKE_NAME_FROM_VEHICLE_MODEL(Game.getEntityModel(vehicle))
    retVal = (mfr:lower():gsub("^%l", string.upper))
  else
    retVal = ""
  end
  return retVal
end

-- Returns the class of the specified vehicle.
Game.Vehicle.class = function(vehicle)
  local class_T <const> = {
    { class = 0,  name = "Compacts" },
    { class = 1,  name = "Sedans" },
    { class = 2,  name = "SUVs" },
    { class = 3,  name = "Coupes" },
    { class = 4,  name = "Muscle" },
    { class = 5,  name = "Sports Classics" },
    { class = 6,  name = "Sports" },
    { class = 7,  name = "Super" },
    { class = 8,  name = "Motorcycles" },
    { class = 9,  name = "Off-road" },
    { class = 10, name = "Industrial" },
    { class = 11, name = "Utility" },
    { class = 12, name = "Vans" },
    { class = 13, name = "Cycles" },
    { class = 14, name = "Boats" },
    { class = 15, name = "Helicopters" },
    { class = 16, name = "Planes" },
    { class = 17, name = "Service" },
    { class = 18, name = "Emergency" },
    { class = 19, name = "Military" },
    { class = 20, name = "Commercial" },
    { class = 21, name = "Trains" },
    { class = 22, name = "Open Wheel" },
  }

  for _, v in ipairs(class_T) do
    if VEHICLE.GET_VEHICLE_CLASS(vehicle) == v.class then
      return v.name
    end
  end
  return "Unknown" -- in case R* adds a new class.
end

-- Returns a table containing all occupants of a vehicle.
---@param vehicle integer
Game.Vehicle.getOccupants = function(vehicle)
  if ENTITY.DOES_ENTITY_EXIST(vehicle) and ENTITY.IS_ENTITY_A_VEHICLE(vehicle) then
    local passengers    = {}
    local maxPassengers = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(vehicle))
    for i = -1, maxPassengers do
      if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, i, true) then
        local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, i, false)
        if ped ~= 0 then
          table.insert(passengers, ped)
        end
      end
    end
    return passengers
  end
end

-- Returns whether a vehicle has weapons or not.
---@return boolean
Game.Vehicle.isWeaponized = function()
  return VEHICLE.DOES_VEHICLE_HAVE_WEAPONS(self.get_veh())
end

-- Applies a custom paint job to the vehicle
---@param veh integer
---@param hex string
---@param p integer
---@param m boolean
---@param is_primary boolean
---@param is_secondary boolean
Game.Vehicle.setCustomPaint = function(veh, hex, p, m, is_primary, is_secondary)
  local pt = 1
  if ENTITY.DOES_ENTITY_EXIST(veh) then
    if m then
      pt = 3
    end
    local r, g, b = Lua_fn.hexToRGB(hex)
    VEHICLE.SET_VEHICLE_MOD_KIT(veh, 0)
    if is_primary then
      VEHICLE.SET_VEHICLE_MOD_COLOR_1(veh, pt, 0, p)
      VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(veh, r, g, b)
      VEHICLE.SET_VEHICLE_EXTRA_COLOURS(veh, p, 0)
    end
    if is_secondary then
      VEHICLE.SET_VEHICLE_MOD_COLOR_2(veh, pt, 0)
      VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(veh, r, g, b)
    end
  end
end

---@class World
Game.World = {}
Game.World.__index = Game.World

---@param bool boolean
Game.World.extendBounds = function(bool)
  if bool then
    PLAYER.EXTEND_WORLD_BOUNDARY_FOR_PLAYER(-42069420.0, -42069420.0, -42069420.0)
    PLAYER.EXTEND_WORLD_BOUNDARY_FOR_PLAYER(42069420.0, 42069420.0, 42069420.0)
  else
    PLAYER.RESET_WORLD_BOUNDARY_FOR_PLAYER()
  end
end

---@param bool boolean
Game.World.disableOceanWaves = function(bool)
  if bool then
    MISC.WATER_OVERRIDE_SET_STRENGTH(1.0)
  else
    MISC.WATER_OVERRIDE_SET_STRENGTH(-1)
  end
end

-- Shows a green chevron down element on top of an entity in the game world.
---@param entity integer
Game.World.markSelectedEntity = function(entity)
  script.run_in_fiber(function(mse)
    if not ENTITY.IS_ENTITY_ATTACHED(entity) then
      local entity_hash  = ENTITY.GET_ENTITY_MODEL(entity)
      local entity_pos   = ENTITY.GET_ENTITY_COORDS(entity, false)
      local min, max     = Game.getModelDimensions(entity_hash, mse)
      local entityHeight = max.z - min.z
      GRAPHICS.DRAW_MARKER(2, entity_pos.x, entity_pos.y, entity_pos.z + (entityHeight + 0.4),
      --[[
        Using 0 for both textureDict and textureName works when drawing a chevron down but 
        it causes an exception [ACESS_VIOLATION] (only once).
        Using const char* for both params when using type 2 (chevron) crashes my game.
        **Reference for textures: https://github.com/esc0rtd3w/illicit-sprx/blob/master/main/illicit/textures.h
      ]]
      ---@diagnostic disable-next-line: param-type-mismatch
        0, 0, 0, 0, 180, 0, 0.3, 0.3, 0.3, 0, 255, 0, 100, true, true, 1, false, 0, 0, false)
    end
  end)
end
--#endregion
