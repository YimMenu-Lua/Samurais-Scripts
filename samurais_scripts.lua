---@diagnostic disable: undefined-global, lowercase-global, undefined-field

require('ss_init')
CURRENT_BUILD   = Game.Version()._build
CURRENT_VERSION = Game.Version()._online

log.info("version " .. SCRIPT_VERSION)
SS.check_kb_keybinds()
SS.check_gpad_keybinds()

Samurais_scripts = gui.add_tab("Samurai's Scripts")
Samurais_scripts:add_imgui(mainUI)

self_tab = Samurais_scripts:add_tab(SELF_TAB_)
self_tab:add_imgui(selfUI)

Actions = self_tab:add_tab("Actions ")
Actions:add_imgui(actionsUI)

sound_player = self_tab:add_tab(SOUND_PLAYER_)
sound_player:add_imgui(soundPlayerUI)

weapon_tab = Samurais_scripts:add_tab(WEAPON_TAB_)
weapon_tab:add_imgui(weaponUI)

vehicle_tab = Samurais_scripts:add_tab(VEHICLE_TAB_)
vehicle_tab:add_imgui(vehicleUI)

custom_paints_tab = vehicle_tab:add_tab("Custom Paint Jobs")
custom_paints_tab:add_imgui(customPaintsUI)

drift_mode_tab = vehicle_tab:add_tab("Drift Mode")
drift_mode_tab:add_imgui(driftModeUI)

flatbed_tab = vehicle_tab:add_tab("Flatbed")
flatbed_tab:add_imgui(flatbedUI)

handling_tab = vehicle_tab:add_tab("Handling Editor")
handling_tab:add_imgui(handingEditorUI)

vehicle_creator   = vehicle_tab:add_tab("Vehicle Creator")
vehicle_creator:add_imgui(vCreatorUI)

online_tab = Samurais_scripts:add_tab("Online ")

business_tab = online_tab:add_tab("Business Manager (YRV2)")
business_tab:add_imgui(yrv2UI)

casino_pacino = online_tab:add_tab("Casino Pacino ") -- IT'S NOT AL ANYMORE! IT'S DUNK!
casino_pacino:add_imgui(dunkUI)

world_tab = Samurais_scripts:add_tab(WORLD_TAB_)
world_tab:add_imgui(worldUI)

object_spawner = world_tab:add_tab("Object Spawner ")
object_spawner:add_imgui(objectSpawnerUI)

settings_tab = Samurais_scripts:add_tab(SETTINGS_TAB_)
settings_tab:add_imgui(settingsUI)

hotkeys_tab = settings_tab:add_tab(HOTKEYS_TAB_)
hotkeys_tab:add_imgui(hotkeysUI)

gui.add_always_draw_imgui(command_ui)

----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------- Commands -----------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

RegisterCommand("autoheal", function()
  gui.show_message("Samurai's Scripts", ("Autoheal %s."):format(Regen and "disabled" or "enabled"))
  Regen = not Regen
  CFG.save("Regen", Regen)
end)

RegisterCommand("rod", function()
  gui.show_message("Samurai's Scripts", ("Ragdoll On Demand %s."):format(rod and "disabled" or "enabled"))
  rod = not rod
  CFG.save("rod", rod)
end)

RegisterCommand("autofill.hangar", function()
  if Game.isOnline() then
    gui.show_message("Samurai's Scripts", ("Hangar auto-fill %s."):format(hangarLoop and "disabled" or "enabled"))
    hangarLoop = not hangarLoop
  else
    gui.show_error("Samurai's Scripts", "Unavailable in Single Player.")
  end
end)

RegisterCommand("autofill.whouse1", function()
  if Game.isOnline() then
    gui.show_message("Samurai's Scripts", ("CEO Warehouse 1 auto-fill %s."):format(wh1_loop and "disabled" or "enabled"))
    wh1_loop = not wh1_loop
  else
    gui.show_error("Samurai's Scripts", "Unavailable in Single Player.")
  end
end)

RegisterCommand("autofill.whouse2", function()
  if Game.isOnline() then
    gui.show_message("Samurai's Scripts", ("CEO Warehouse 2 auto-fill %s."):format(wh2_loop and "disabled" or "enabled"))
    wh2_loop = not wh2_loop
  else
    gui.show_error("Samurai's Scripts", "Unavailable in Single Player.")
  end
end)

RegisterCommand("autofill.whouse3", function()
  if Game.isOnline() then
    gui.show_message("Samurai's Scripts", ("CEO Warehouse 3 auto-fill %s."):format(wh3_loop and "disabled" or "enabled"))
    wh3_loop = not wh3_loop
  else
    gui.show_error("Samurai's Scripts", "Unavailable in Single Player.")
  end
end)

RegisterCommand("autofill.whouse4", function()
  if Game.isOnline() then
    gui.show_message("Samurai's Scripts", ("CEO Warehouse 4 auto-fill %s."):format(wh4_loop and "disabled" or "enabled"))
    wh4_loop = not wh4_loop
  else
    gui.show_error("Samurai's Scripts", "Unavailable in Single Player.")
  end
end)

RegisterCommand("autofill.whouse5", function()
  if Game.isOnline() then
    gui.show_message("Samurai's Scripts", ("CEO Warehouse 5 auto-fill %s."):format(wh5_loop and "disabled" or "enabled"))
    wh5_loop = not wh5_loop
  else
    gui.show_error("Samurai's Scripts", "Unavailable in Single Player.")
  end
end)

RegisterCommand("yrv2.fillall", function()
  script.run_in_fiber(function(fa)
    SS.fillAll(fa)
  end)
end)

RegisterCommand("finishsale", function()
  if Game.isOnline() then
    if autosell then
      gui.show_warning("Samurai's Scripts", "You aleady have 'Auto-Sell' enabled. No need to manually trigger it.")
    else
      if scr_is_running then
        SS.FinishSale(script_name)
      else
        gui.show_warning("Samurai's Scripts", "No supported sale script is currently running.")
      end
    end
  else
    gui.show_error("Samurai's Scripts", "Unavailable in Single Player.")
  end
end)

RegisterCommand("spawnmeaperv", function()
  spawnPervert(self.get_ped(), "you")
end)

RegisterCommand("kys", function()
  command.call("suicide", {})
end)

RegisterCommand("vehlock", function()
  script.run_in_fiber(function(vehlock)
    if current_vehicle ~= 0 and is_car then
      SS.playKeyfobAnim()
      AUDIO.PLAY_SOUND_FRONTEND(-1, "REMOTE_CONTROL_FOB", "PI_MENU_SOUNDS", false)
      vehlock:sleep(250)
      local toggle = (VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(current_vehicle) == 1) and true or false
      vehicleLockStatus = toggle and 2 or 1
      Game.Vehicle.lockDoors(current_vehicle, toggle, vehlock)
    end
  end)
end)

RegisterCommand("PANIK", function()
  SS.handle_events()
  AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(
    "ELECTROCUTION", "MISTERK", self.get_pos().x,
    self.get_pos().y, self.get_pos().z, "SPEECH_PARAMS_FORCE"
  )
  gui.show_message("PANIK!", "(Ó _ Ò )!!")
end)

RegisterCommand("resetcfg", SS.reset_settings)

RegisterCommand("fastvehs", function()
  fast_vehicles = not fast_vehicles
  gui.show_message("Samurai's Scripts", ("Fast Vehicles %s"):format(fast_vehicles and "enabled" or "disabled"))
  if not fast_vehicles and current_vehicle ~= 0 and (is_car or is_bike or is_quad) then
    script.run_in_fiber(function()
      VEHICLE.MODIFY_VEHICLE_TOP_SPEED(current_vehicle, 0)
    end)
  end
end)

----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------- Threads -----------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

script.register_looped("BALT", function(balt) -- Basic Ass Loading Text
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
script.register_looped("SRGBT", function(rgbtxt) -- Shitty RGB Text
  if gui.is_open() and business_tab:is_selected() then
    rgbtxt:sleep(200)
    yrv2_color = { 0, 255, 255, 1 }
    rgbtxt:sleep(200)
    yrv2_color = { 0, 127, 255, 1 }
    rgbtxt:sleep(200)
    yrv2_color = { 0, 0, 255, 1 }
    rgbtxt:sleep(200)
    yrv2_color = { 127, 0, 255, 1 }
    rgbtxt:sleep(200)
    yrv2_color = { 255, 0, 255, 1 }
    rgbtxt:sleep(200)
    yrv2_color = { 255, 0, 127, 1 }
    rgbtxt:sleep(200)
    yrv2_color = { 255, 0, 0, 1 }
    rgbtxt:sleep(200)
    yrv2_color = { 255, 127, 0, 1 }
    rgbtxt:sleep(200)
    yrv2_color = { 255, 255, 0, 1 }
    rgbtxt:sleep(200)
    yrv2_color = { 127, 255, 0, 1 }
    rgbtxt:sleep(200)
    yrv2_color = { 0, 255, 0, 1 }
    rgbtxt:sleep(200)
    yrv2_color = { 0, 255, 127, 1 }
  end
end)
script.register_looped("QOTD", function(qotd) -- Quote Of The Day
  qotd:yield()
  if not disable_quotes then
    if gui.is_open() and Samurais_scripts:is_selected() then
      quote_changed = false
      random_quote  = random_quotes_T[math.random(1, #random_quotes_T)]
      qotd:sleep(8000)
      quote_changed = true
      qotd:sleep(2000)
    else
      random_quote  = ""
      quote_changed = false
      quote_alpha   = 1.0
    end
  end
end)
script.register_looped("QBE", function(qbe) -- Quote Breathe Effect
  qbe:yield()
  if not disable_quotes then
    if gui.is_open() and Samurais_scripts:is_selected() and random_quote ~= "" and quote_changed then
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
  end
end)

script.register_looped("GINPUT", function() -- Game Input
  if is_typing or is_setting_hotkeys then
    if not gui.is_open() then
      is_typing, is_setting_hotkeys = false, false
    end
    PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
  end

  if HashGrabber and WEAPON.IS_PED_ARMED(self.get_ped(), 4) then
    PAD.DISABLE_CONTROL_ACTION(0, 24, true)
    PAD.DISABLE_CONTROL_ACTION(0, 257, true)
  end

  if replaceSneakAnim and Game.Self.isOnFoot() then
    PAD.DISABLE_CONTROL_ACTION(0, 36, true)
  end

  if replacePointAct or is_playing_anim or is_playing_scenario or ped_grabbed or vehicle_grabbed then
    PAD.DISABLE_CONTROL_ACTION(0, 29, true)
  end

  if ducking_in_car then
    PAD.DISABLE_CONTROL_ACTION(0, 73, true)
    PAD.DISABLE_CONTROL_ACTION(0, 75, true)
    PAD.DISABLE_CONTROL_ACTION(0, 86, true)
  end

  if is_carpooling then
    PAD.DISABLE_CONTROL_ACTION(0, 75, true)
  end

  if PAD.IS_USING_KEYBOARD_AND_MOUSE(0) then
    pressing_drift_button = SS.isKeyPressed(keybinds.tdBtn.code) and not
        is_typing and not is_setting_hotkeys and not HUD.IS_MP_TEXT_CHAT_TYPING()
    pressing_nos_button   = SS.isKeyPressed(keybinds.nosBtn.code) and not
        is_typing and not is_setting_hotkeys and not HUD.IS_MP_TEXT_CHAT_TYPING()
    pressing_purge_button = SS.isKeyPressed(keybinds.purgeBtn.code) and not
        is_typing and not is_setting_hotkeys and not HUD.IS_MP_TEXT_CHAT_TYPING()
    pressing_fltbd_button = SS.isKeyJustPressed(keybinds.flatbedBtn.code) and not
        is_typing and not is_setting_hotkeys and not HUD.IS_MP_TEXT_CHAT_TYPING()
    pressing_vmine_button = SS.isKeyJustPressed(keybinds.vehicle_mine.code) and not
        is_typing and not is_setting_hotkeys and not HUD.IS_MP_TEXT_CHAT_TYPING()
    pressing_rod_button =  SS.isKeyPressed(keybinds.rodBtn.code) and not
    is_typing and not is_setting_hotkeys and not HUD.IS_MP_TEXT_CHAT_TYPING()
    pressing_laser_button = SS.isKeyJustPressed(keybinds.laser_sight.code) and not
    is_typing and not is_setting_hotkeys and not HUD.IS_MP_TEXT_CHAT_TYPING()
  else
    pressing_drift_button = gpad_keybinds.tdBtn.code ~= 0 and PAD.IS_CONTROL_PRESSED(0, gpad_keybinds.tdBtn.code)
    pressing_nos_button   = gpad_keybinds.nosBtn.code ~= 0 and PAD.IS_CONTROL_PRESSED(0, gpad_keybinds.nosBtn.code)
    pressing_purge_button = gpad_keybinds.purgeBtn.code ~= 0 and
        (PAD.IS_CONTROL_PRESSED(0, gpad_keybinds.purgeBtn.code) or PAD.IS_DISABLED_CONTROL_PRESSED(0, gpad_keybinds.purgeBtn.code))
    pressing_fltbd_button = gpad_keybinds.flatbedBtn.code ~= 0 and
        (PAD.IS_CONTROL_JUST_PRESSED(0, gpad_keybinds.flatbedBtn.code) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, gpad_keybinds.flatbedBtn.code))
    pressing_vmine_button = gpad_keybinds.vehicle_mine.code ~= 0 and
        (PAD.IS_CONTROL_JUST_PRESSED(0, gpad_keybinds.vehicle_mine.code) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, gpad_keybinds.vehicle_mine.code))
    pressing_rod_button = gpad_keybinds.rodBtn.code ~= 0 and
        (PAD.IS_CONTROL_PRESSED(0, gpad_keybinds.rodBtn.code) or PAD.IS_DISABLED_CONTROL_PRESSED(0, gpad_keybinds.rodBtn.code))
    pressing_laser_button = gpad_keybinds.laser_sight.code ~= 0 and
        (PAD.IS_CONTROL_JUST_PRESSED(0, gpad_keybinds.laser_sight.code) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, gpad_keybinds.laser_sight.code))
  end

  if is_using_flatbed then
    if keybinds.flatbedBtn.code == 0x58 or gpad_keybinds.flatbedBtn.code == 73 then
      PAD.DISABLE_CONTROL_ACTION(0, 73, true)
    end
  end

  if nosPurge and Game.Self.isDriving() then
    if validModel and keybinds.purgeBtn.code == 0x58 or gpad_keybinds.purgeBtn.code == 73 then
      PAD.DISABLE_CONTROL_ACTION(0, 73, true)
    end
  end

  if Game.Self.isDriving() then
    if speedBoost and (keybinds.nosBtn.code == 0x10 or gpad_keybinds.nosBtn.code == 21) then
      if PAD.IS_CONTROL_PRESSED(0, 71) and pressing_nos_button then
        if validModel or is_boat or is_bike then
          -- prevent face planting when using NOS mid-air
          PAD.DISABLE_CONTROL_ACTION(0, 60, true)
          PAD.DISABLE_CONTROL_ACTION(0, 61, true)
          PAD.DISABLE_CONTROL_ACTION(0, 62, true)
        end
      end
    end
    if holdF and Game.Self.isOutside() then
      if not ducking_in_car and VEHICLE.IS_VEHICLE_STOPPED(self.get_veh())
      and not is_typing and not is_setting_hotkeys and not cmd_ui_is_open then
        PAD.DISABLE_CONTROL_ACTION(0, 75, true)
      else
        timerB = 0
      end
    end
    if keepWheelsTurned and Game.Self.isOutside() then
      if (is_car or is_quad) and not ducking_in_car
          and VEHICLE.IS_VEHICLE_STOPPED(self.get_veh()) then
        if PAD.IS_CONTROL_PRESSED(0, 34) or PAD.IS_CONTROL_PRESSED(0, 35) then
          PAD.DISABLE_CONTROL_ACTION(0, 75, true)
        end
      end
    end
  end

  if (pedGrabber or vehicleGrabber) and Game.Self.isOnFoot() and not WEAPON.IS_PED_ARMED(self.get_ped(), 7) then
    PAD.DISABLE_CONTROL_ACTION(0, 24, true)
    PAD.DISABLE_CONTROL_ACTION(0, 25, true)
    PAD.DISABLE_CONTROL_ACTION(0, 50, true)
    PAD.DISABLE_CONTROL_ACTION(0, 68, true)
    PAD.DISABLE_CONTROL_ACTION(0, 91, true)
    PAD.DISABLE_CONTROL_ACTION(0, 257, true)
  end
  if ped_grabbed or vehicle_grabbed then
    PAD.DISABLE_CONTROL_ACTION(0, 24, true)
    PAD.DISABLE_CONTROL_ACTION(0, 25, true)
    PAD.DISABLE_CONTROL_ACTION(0, 50, true)
    PAD.DISABLE_CONTROL_ACTION(0, 68, true)
    PAD.DISABLE_CONTROL_ACTION(0, 91, true)
    PAD.DISABLE_CONTROL_ACTION(0, 257, true)
  end

  if cmd_ui_is_open then
    PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
  end
end)

-- self stuff
script.register_looped("AHL", function(ah) -- Auto-Heal
  ah:yield()
  if Regen and Game.Self.isAlive() then
    local maxHp   = Game.Self.maxHealth()
    local myHp    = Game.Self.health()
    local maxArmr = Game.Self.maxArmour()
    local myArmr  = Game.Self.armour()
    if myHp < maxHp and myHp > 0 then
      if PED.IS_PED_IN_COVER(self.get_ped(), false) then
        ENTITY.SET_ENTITY_HEALTH(self.get_ped(), myHp + 10, 0, 0)
      else
        ENTITY.SET_ENTITY_HEALTH(self.get_ped(), myHp + 1, 0, 0)
      end
    end
    if myArmr == nil then
      PED.SET_PED_ARMOUR(self.get_ped(), 10)
    end
    if myArmr ~= nil and myArmr < maxArmr then
      PED.ADD_ARMOUR_TO_PED(self.get_ped(), 0.5)
    end
  end
end)

script.register_looped("SELFFT", function(script) -- Self Features
  -- Crouch instead of sneak
  if replaceSneakAnim then
    if PAD.IS_DISABLED_CONTROL_PRESSED(0, 36) and SS.canCrouch() then
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
  if isCrouched and PAD.IS_DISABLED_CONTROL_PRESSED(0, 36)
      and not HUD.IS_MP_TEXT_CHAT_TYPING() and not Game.Self.isBrowsingApps() then
    script:sleep(200)
    PED.RESET_PED_MOVEMENT_CLIPSET(self.get_ped(), 0.3)
    script:sleep(500)
    isCrouched = false
  end

  -- Replace 'Point At' Action
  if replacePointAct then
    if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 29) and SS.canUseHandsUp() then
      if not is_handsUp then
        script:sleep(200)
        if isCrouched then
          isCrouched = false
          PED.RESET_PED_MOVEMENT_CLIPSET(self.get_ped(), 0)
        end
        if is_sitting then
          standUp()
        end
        playHandsUp()
        is_handsUp = true
      else
        script:sleep(200)
        TASK.CLEAR_PED_TASKS(self.get_ped())
        script:sleep(500)
        is_handsUp = false
      end
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
  if phoneAnim then
    if Game.isOnline() and SS.canUsePhoneAnims() then
      Game.Self.PhoneAnims(true)
      Game.Self.PlayPhoneGestures(script)
      phoneAnimsEnabled = true
    else
      if phoneAnimsEnabled then
        Game.Self.PhoneAnims(false)
        phoneAnimsEnabled = false
      end
    end
  else
    if phoneAnimsEnabled then
      Game.Self.PhoneAnims(false)
      phoneAnimsEnabled = false
    end
  end

  -- Sprint Inside
  if sprintInside then
    if not PED.GET_PED_CONFIG_FLAG(self.get_ped(), 427, true) then
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 427, true)
    end
  else
    if PED.GET_PED_CONFIG_FLAG(self.get_ped(), 427, true) then
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 427, false)
    end
  end

  -- Lockpick animation
  if lockPick then
    if not PED.GET_PED_CONFIG_FLAG(self.get_ped(), 426, true) then
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 426, true)
    end
  else
    if PED.GET_PED_CONFIG_FLAG(self.get_ped(), 426, true) then
      PED.SET_PED_CONFIG_FLAG(self.get_ped(), 426, false)
    end
  end
end)
script.register_looped("RGDL", function(rgdl) -- Ragdoll
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
  elseif rod and Game.Self.isOnFoot() and pressing_rod_button and not is_hiding then
    if PED.CAN_PED_RAGDOLL(self.get_ped()) then
      if not Game.Self.isBrowsingApps() then
        PED.SET_PED_TO_RAGDOLL(self.get_ped(), 1500, 0, 0, false, false, false)
      end
      if isCrouched then
        isCrouched = false
      end
      if is_handsUp then
        is_handsUp = false
      end
    else
      gui.show_error("Samurais Scripts",
        "Unable to ragdoll you.\nPlease make sure 'No Ragdoll' option\nis disabled in YimMenu.")
      rgdl:sleep(200)
    end
  end
  if ragdoll_sound and Game.isOnline() then
    if PED.IS_PED_RAGDOLL(self.get_ped()) then
      rgdl:sleep(500)
      local soundName = (ENTITY.GET_ENTITY_MODEL(self.get_ped()) == 0x705E61F2) and "WAVELOAD_PAIN_MALE" or
      "WAVELOAD_PAIN_FEMALE"
      local myPos = ENTITY.GET_ENTITY_COORDS(self.get_ped(), true)
      AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE("SCREAM_PANIC_SHORT", soundName, myPos.x, myPos.y, myPos.z,
        "SPEECH_PARAMS_FORCE_SHOUTED")
      repeat
        rgdl:sleep(100)
      until not PED.IS_PED_RAGDOLL(self.get_ped())
    end
  end
end)
script.register_looped("ASVFX", function(animSfx) -- Anim FX
  if is_playing_anim then
    if curr_playing_anim.sfx ~= nil then
      local soundCoords = self.get_pos()
      AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(curr_playing_anim.sfx, curr_playing_anim.sfxName, soundCoords.x,
        soundCoords.y,
        soundCoords.z, curr_playing_anim.sfxFlg)
      animSfx:sleep(10000)
    elseif string.find(string.lower(curr_playing_anim.name), "police torch") then
      local myPos = self.get_pos()
      local torch = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(myPos.x, myPos.y, myPos.z, 1, curr_playing_anim.prop1, false, false,
        false)
      if ENTITY.DOES_ENTITY_EXIST(torch) then
        local torchPos = ENTITY.GET_ENTITY_COORDS(torch, false)
        local torchFwd = (Game.getForwardVec(torch)):inverse()
        GRAPHICS.DRAW_SPOT_LIGHT(
          torchPos.x, torchPos.y, torchPos.z - 0.2,
          torchFwd.x, torchFwd.y, torchFwd.z, 226, 130, 78,
          50.0, 8.0, 1.0, 10.0, 1.0
        )
      end
    end
  end
end)
script.register_looped("HFC", function(hfc) -- Hide From Cops
  if hideFromCops then
    local isWanted    = PLAYER.GET_PLAYER_WANTED_LEVEL(self.get_id()) > 0
    local was_spotted = PLAYER.IS_WANTED_AND_HAS_BEEN_SEEN_BY_COPS(self.get_id())
    local cond
    if not is_hiding then
      if PED.IS_PED_IN_ANY_VEHICLE(self.get_ped(), false) and is_car then
        if Game.Self.isDriving() then
          cond = VEHICLE.IS_VEHICLE_STOPPED(current_vehicle)
        else
          cond = true
        end
        if cond and not PAD.IS_CONTROL_PRESSED(0, 71) and not PAD.IS_CONTROL_PRESSED(0, 72)
            and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(current_vehicle) and isWanted and not was_spotted then
          Game.showButtonPrompt("Press ~INPUT_FRONTEND_ACCEPT~ to hide inside the vehicle.")
          if PAD.IS_CONTROL_JUST_PRESSED(0, 201) and not HUD.IS_MP_TEXT_CHAT_TYPING() then
            if is_handsUp then
              TASK.CLEAR_PED_TASKS(self.get_ped())
              is_handsUp = false
            end
            if Game.requestAnimDict("missmic3leadinout_mcs1") then
              VEHICLE.SET_VEHICLE_IS_WANTED(current_vehicle, false)
              TASK.TASK_PLAY_ANIM(self.get_ped(), "missmic3leadinout_mcs1", "cockpit_pilot", 6.0, 3.0, -1, 18, 1.0, false,
                false, false)
              if Game.Self.isDriving() then
                VEHICLE.SET_VEHICLE_ENGINE_ON(self.get_veh(), false, false, true)
              end
              is_hiding, ducking_in_car = true, true
              hfc:sleep(1000)
            end
          end
        end
      end
      if Game.Self.isOnFoot() then
        local nearBoot, vehicle, isRearEngined = SS.isNearCarTrunk()
        local nearBin, bin      = SS.isNearTrashBin()
        if not nearBoot and not nearBin then
          hfc:sleep(1000)
        end
        if nearBoot and vehicle > 0 and not is_playing_anim and not is_playing_scenario and not ped_grabbed and not vehicle_grabbed then
          Game.showButtonPrompt("Press ~INPUT_PICKUP~ to hide in the trunk.")
          if PAD.IS_CONTROL_JUST_PRESSED(0, 38) then
            local z_offset = 0.93
            if is_handsUp then
              TASK.CLEAR_PED_TASKS(self.get_ped())
              is_handsUp = false
            end
            if isCrouched then
              PED.RESET_PED_MOVEMENT_CLIPSET(self.get_ped(), 0)
              isCrouched = false
            end
            if not was_spotted then
              if Game.Vehicle.class(vehicle) == "Vans" then
                z_offset = 1.1
              else
                if Game.Vehicle.class(vehicle) == "SUVs" then
                  z_offset = 1.2
                end
              end
              if Game.requestAnimDict("rcmnigel3_trunk") then
                if not ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY_IN_FRONT(self.get_ped(), vehicle) then
                  TASK.TASK_TURN_PED_TO_FACE_ENTITY(self.get_ped(), vehicle, 0)
                  repeat
                    hfc:sleep(10)
                  until not TASK.GET_IS_TASK_ACTIVE(self.get_ped(), 225) -- CTaskTurnToFaceEntityOrCoord
                end
                TASK.TASK_PLAY_ANIM(
                  self.get_ped(), "rcmnigel3_trunk", "out_trunk_trevor", 4.0, -4.0, 1500, 2, 0.0,
                  false, false, false
                )
              end
              hfc:sleep(800)
              if VEHICLE.IS_VEHICLE_STOPPED(vehicle) then
                ENTITY.FREEZE_ENTITY_POSITION(self.get_ped(), true)
                ENTITY.SET_ENTITY_COLLISION(self.get_ped(), false, true)
                hfc:sleep(50)
                VEHICLE.SET_VEHICLE_DOOR_OPEN(vehicle, 5, false, false)
                hfc:sleep(500)
                ENTITY.FREEZE_ENTITY_POSITION(self.get_ped(), false)
                local chassis_bone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(vehicle, "chassis_dummy")
                if chassis_bone == nil or chassis_bone == -1 then
                  chassis_bone = 0
                end
                local veh_hash   = ENTITY.GET_ENTITY_MODEL(vehicle)
                local vmin, vmax = Game.getModelDimensions(veh_hash)
                boot_vehicle_len = vmax.y - vmin.y
                local attachPosY = isRearEngined and (boot_vehicle_len / 3) or (-boot_vehicle_len / 3)
                if Game.requestAnimDict("timetable@tracy@sleep@") then
                  TASK.TASK_PLAY_ANIM(
                    self.get_ped(), "timetable@tracy@sleep@", "base",
                    4.0, -4.0, -1, 2, 1.0, false, false, false
                  )
                  ENTITY.ATTACH_ENTITY_TO_ENTITY(
                  self.get_ped(), vehicle, chassis_bone, -0.3, attachPosY, z_offset,
                    180.0, 0.0, 0.0, false, false, false, false, 20, true, 1
                  )
                  hfc:sleep(500)
                  VEHICLE.SET_VEHICLE_DOOR_SHUT(vehicle, 5, false)
                  ENTITY.SET_ENTITY_COLLISION(self.get_ped(), true, true)
                  is_hiding, hiding_in_boot, boot_vehicle, boot_vehicle_re = true, true, vehicle, isRearEngined
                  hfc:sleep(1000)
                end
              else
                TASK.CLEAR_PED_TASKS(self.get_ped())
                gui.show_warning("Samurai's Scripts", "Vehicle must be stopped.")
              end
            else
              gui.show_warning("Samurai's Scripts",
                "The cops have spotted you. You can't hide until they lose sight of you.")
            end
          end
        end
        if nearBin and not is_playing_anim and not is_playing_scenario and not ped_grabbed and not vehicle_grabbed then
          Game.showButtonPrompt("Press ~INPUT_PICKUP~ to hide in the dumpster")
          if PAD.IS_CONTROL_JUST_PRESSED(0, 38) then
            if is_handsUp then
              TASK.CLEAR_PED_TASKS(self.get_ped())
              is_handsUp = false
            end
            if isCrouched then
              PED.RESET_PED_MOVEMENT_CLIPSET(self.get_ped(), 0)
              isCrouched = false
            end
            if not was_spotted then
              if ENTITY.DOES_ENTITY_EXIST(bin) then
                TASK.TASK_TURN_PED_TO_FACE_ENTITY(self.get_ped(), bin, 10)
                CAM.DO_SCREEN_FADE_OUT(500)
                hfc:sleep(1000)
                ENTITY.ATTACH_ENTITY_TO_ENTITY(self.get_ped(), bin, -1, 0.0, 0.12, 1.13, 0.0, 0.0, 90.0, false,
                  false, false, false, 20, true, 1)
                if Game.requestAnimDict("anim@amb@inspect@crouch@male_a@base") then
                  TASK.TASK_PLAY_ANIM(self.get_ped(), "anim@amb@inspect@crouch@male_a@base", "base", 4.0, -4.0, -1, 1,
                    1.0, false, false, false)
                end
                hfc:sleep(200)
                CAM.DO_SCREEN_FADE_IN(500)
                hfc:sleep(200)
                AUDIO.PLAY_SOUND_FRONTEND(-1, "TRASH_BAG_LAND", "DLC_HEIST_SERIES_A_SOUNDS", true)
                hfc:sleep(1000)
                is_hiding, hiding_in_dumpster, thisDumpster = true, true, bin
              end
            else
              gui.show_warning("Samurai's Scripts",
                "The cops have spotted you! You can't hide until they lose sight of you.")
            end
          end
        end
      end
    end
  end
  if is_hiding then
    if not Game.Self.isAlive() then
      is_hiding, ducking_in_car, hiding_in_boot, hiding_in_dumpster, boot_vehicle, thisDumpster = false, false, false, false, 0, 0
      PLAYER.RESET_WANTED_LEVEL_DIFFICULTY(self.get_id())
    end
    if ducking_in_car and not ENTITY.DOES_ENTITY_EXIST(self.get_veh()) then
      is_hiding, ducking_in_car = false, false
      TASK.CLEAR_PED_TASKS(self.get_ped())
      PLAYER.RESET_WANTED_LEVEL_DIFFICULTY(self.get_id())
    end
    if hiding_in_boot and not ENTITY.DOES_ENTITY_EXIST(boot_vehicle) then
      is_hiding, hiding_in_boot, boot_vehicle = false, false, 0
      TASK.CLEAR_PED_TASKS(self.get_ped())
      PLAYER.RESET_WANTED_LEVEL_DIFFICULTY(self.get_id())
    end
    if hiding_in_dumpster and not ENTITY.DOES_ENTITY_EXIST(thisDumpster) then
      is_hiding, hiding_in_dumpster, thisDumpster = false, false, 0
      TASK.CLEAR_PED_TASKS(self.get_ped())
      PLAYER.RESET_WANTED_LEVEL_DIFFICULTY(self.get_id())
    end
    local isWanted    = PLAYER.GET_PLAYER_WANTED_LEVEL(self.get_id()) > 0
    local was_spotted = PLAYER.IS_WANTED_AND_HAS_BEEN_SEEN_BY_COPS(self.get_id())
    local offsetCoords
    if offsetCoords == nil then
      offsetCoords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
        self.get_ped(), math.random(10.0, 50.0),
        math.random(10.0, 50.0), math.random(1.0, 10.0)
      )
    end
    if isWanted and not was_spotted then
      PED.SET_COP_PERCEPTION_OVERRIDES(40.0, 40.0, 40.0, 100.0, 100.0, 100.0, 0.0)
      ---@diagnostic disable-next-line
      PLAYER.SET_PLAYER_WANTED_CENTRE_POSITION(self.get_id(), offsetCoords)
    end
    if ducking_in_car then
      if was_spotted then
        gui.show_warning("Samurai's Scripts",
          "You have been spotted by the cops! You can't hide until they lose sight of you.")
        is_hiding, ducking_in_car = false, false
        TASK.CLEAR_PED_TASKS(self.get_ped())
      end
      Game.showButtonPrompt(
      "Press ~INPUT_FRONTEND_ACCEPT~ or ~INPUT_VEH_ACCELERATE~ or ~INPUT_VEH_BRAKE~ to stop hiding.")
      if PAD.IS_CONTROL_JUST_PRESSED(0, 201) or PAD.IS_CONTROL_PRESSED(0, 71)
          or PAD.IS_CONTROL_PRESSED(0, 72) and not HUD.IS_MP_TEXT_CHAT_TYPING() then
        TASK.CLEAR_PED_TASKS(self.get_ped())
        if Game.Self.isDriving() then
          VEHICLE.SET_VEHICLE_ENGINE_ON(self.get_veh(), true, false, false)
        end
        is_hiding, ducking_in_car = false, false
        hfc:sleep(1000)
      end
    end
    if hiding_in_boot then
      Game.showButtonPrompt("Press ~INPUT_PICKUP~ to get out.")
      if PAD.IS_CONTROL_JUST_PRESSED(0, 38) then
        local my_pos      = self.get_pos()
        local veh_fwd     = ENTITY.GET_ENTITY_FORWARD_VECTOR(boot_vehicle)
        local _, ground_z = MISC.GET_GROUND_Z_FOR_3D_COORD(my_pos.x, my_pos.y, my_pos.z, ground_z, false, false)
        local outHeading  = boot_vehicle_re and ENTITY.GET_ENTITY_HEADING(boot_vehicle) or
        (ENTITY.GET_ENTITY_HEADING(boot_vehicle) - 180)
        local outPos = boot_vehicle_re and vec2:new(
          my_pos.x + (veh_fwd.x * boot_vehicle_len / 3),
          my_pos.y + (veh_fwd.y * boot_vehicle_len / 3)
        ) or vec2:new(
          my_pos.x - (veh_fwd.x * boot_vehicle_len / 3),
          my_pos.y - (veh_fwd.y * boot_vehicle_len / 3)
        )
        VEHICLE.SET_VEHICLE_DOOR_OPEN(boot_vehicle, 5, false, false)
        hfc:sleep(500)
        TASK.CLEAR_PED_TASKS(self.get_ped())
        ENTITY.DETACH_ENTITY(self.get_ped(), true, false)
        ENTITY.SET_ENTITY_COORDS(self.get_ped(), outPos.x, outPos.y, ground_z, false, false, false, false)
        ENTITY.SET_ENTITY_HEADING(self.get_ped(), outHeading)
        VEHICLE.SET_VEHICLE_DOOR_SHUT(boot_vehicle, 5, false)
        hfc:sleep(200)
        if ENTITY.GET_ENTITY_SPEED(boot_vehicle) > 4.0 then
          PED.SET_PED_TO_RAGDOLL(self.get_ped(), 1500, 0, 0, false, false, false)
        end
        is_hiding, hiding_in_boot, boot_vehicle_re, boot_vehicle, boot_vehicle_len = false, false, false, 0, 0
        hfc:sleep(1000)
      end
    end
    if hiding_in_dumpster then
      Game.showButtonPrompt("Press ~INPUT_PICKUP~ to get out.")
      if PAD.IS_CONTROL_JUST_PRESSED(0, 38) then
        CAM.DO_SCREEN_FADE_OUT(500)
        hfc:sleep(1000)
        local my_pos      = self.get_pos()
        local _, ground_z = MISC.GET_GROUND_Z_FOR_3D_COORD(my_pos.x, my_pos.y, my_pos.z, ground_z, false, false)
        ENTITY.DETACH_ENTITY(self.get_ped(), true, false)
        ENTITY.SET_ENTITY_HEADING(self.get_ped(), (ENTITY.GET_ENTITY_HEADING(self.get_ped()) + 90))
        TASK.CLEAR_PED_TASKS(self.get_ped())
        local my_fwd = Game.getForwardVec(self.get_ped())
        ENTITY.SET_ENTITY_COORDS(self.get_ped(), my_pos.x + (my_fwd.x * 1.3),
          my_pos.y + (my_fwd.y * 1.3), ground_z, false, false, false, false)
        CAM.DO_SCREEN_FADE_IN(500)
        AUDIO.PLAY_SOUND_FRONTEND(-1, "TRASH_BAG_LAND", "DLC_HEIST_SERIES_A_SOUNDS", true)
        if Game.requestAnimDict("move_m@_idles@shake_off") then
          TASK.TASK_PLAY_ANIM(self.get_ped(), "move_m@_idles@shake_off", "shakeoff_1", 4.0, -4.0, 3000, 48, 0.0, false,
            false, false)
        end
        hfc:sleep(1000)
        is_hiding, hiding_in_dumpster = false, false
      end
    end
  else
    if offsetCoords ~= nil then
      offsetCoords = nil
    end
  end
end)

-- Actions
script.register_looped("AIEV", function(aiev) -- Anim Interrupt Event
  if is_playing_anim then
    if Game.Self.isSwimming() then
      cleanup(aiev)
      is_playing_anim = false
    end
    local isLooped = Lua_fn.has_bit(curr_playing_anim.flag, 0)
    local isFrozen = Lua_fn.has_bit(curr_playing_anim.flag, 1)
    if not isLooped and not isFrozen then
      repeat
        aiev:sleep(200)
      until not ENTITY.IS_ENTITY_PLAYING_ANIM(self.get_ped(), curr_playing_anim.dict, curr_playing_anim.anim, 3)
      is_playing_anim = false
    end
    if Game.Self.isAlive() then
      if is_playing_anim and not ENTITY.IS_ENTITY_PLAYING_ANIM(self.get_ped(), curr_playing_anim.dict, curr_playing_anim.anim, 3)
          and not SS.isKeyJustPressed(keybinds.stop_anim.code) then
        aiev:sleep(1000)
        if PED.IS_PED_FALLING(self.get_ped()) then
          repeat
            aiev:sleep(1000)
          until not PED.IS_PED_FALLING(self.get_ped())
          aiev:sleep(1000)
        end
        if PED.IS_PED_RAGDOLL(self.get_ped()) then
          repeat
            aiev:sleep(1000)
          until not PED.IS_PED_RAGDOLL(self.get_ped())
          aiev:sleep(1000)
        end
        onAnimInterrupt()
      end
    else
      cleanup(aiev)
      is_playing_anim = false
    end
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
script.register_looped("MISCANIM", function(miscanim)
  if is_playing_anim or is_shortcut_anim then
    if WEAPON.IS_PED_ARMED(self.get_ped(), 7) then
      WEAPON.SET_CURRENT_PED_WEAPON(self.get_ped(), 0xA2719263, false)
    end
    if ENTITY.IS_ENTITY_PLAYING_ANIM(self.get_ped(), "mp_suicide", "pistol", 3) then
      for _, w in ipairs(handguns_T) do
        if WEAPON.HAS_PED_GOT_WEAPON(self.get_ped(), w, false) then
          WEAPON.SET_CURRENT_PED_WEAPON(self.get_ped(), w, true)
          break
        end
      end
      miscanim:sleep(555)
      AUDIO.PLAY_SOUND_FRONTEND(-1, "SNIPER_FIRE", "DLC_BIKER_RESUPPLY_MEET_CONTACT_SOUNDS", true)
      repeat
        miscanim:sleep(10)
      until ENTITY.IS_ENTITY_PLAYING_ANIM(self.get_ped(), "mp_suicide", "pistol", 3) == false
      PED.SET_PED_CAN_SWITCH_WEAPON(self.get_ped(), true)
    end
    repeat
      miscanim:sleep(10)
    until is_playing_anim == false or is_shortcut_anim == false
    PED.SET_PED_CAN_SWITCH_WEAPON(self.get_ped(), true)
    if curr_playing_anim.cat == "In-Vehicle" then
      if PAD.IS_CONTROL_PRESSED(0, 75) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 75) or Game.Self.isOnFoot() then
        cleanup(miscanim)
        is_playing_anim = false
      end
    end
  end
end)

script.register_looped("AHK", function(script) -- Anim Hotkeys
  if not HUD.IS_PAUSE_MENU_ACTIVE() and not HUD.IS_MP_TEXT_CHAT_TYPING() then
    if is_playing_anim then
      if SS.isKeyJustPressed(keybinds.stop_anim.code) and not Game.Self.isBrowsingApps() then
        UI.widgetSound("Cancel")
        cleanup(script)
        is_playing_anim  = false
        is_shortcut_anim = false
        if spawned_npcs[1] ~= nil then
          cleanupNPC(script)
        end
      end
    end
    if usePlayKey then
      if filteredAnims == nil then
        updatefilteredAnims()
      end
      if SS.isKeyJustPressed(keybinds.next_anim.code) and not Game.Self.isBrowsingApps() then
        UI.widgetSound("Nav")
        if anim_index < #filteredAnims - 1 then
          anim_index = anim_index + 1
        else
          anim_index = 0
        end
        info = filteredAnims[anim_index + 1]
        gui.show_message("Current Animation:", info.name)
        script:sleep(200)
      end
      if SS.isKeyJustPressed(keybinds.previous_anim.code) and not Game.Self.isBrowsingApps() then
        UI.widgetSound("Nav")
        if anim_index <= 0 then
          anim_index = #filteredAnims - 1
        else
          anim_index = anim_index - 1
        end
        info = filteredAnims[anim_index + 1]
        gui.show_message("Current Animation:", info.name)
        script:sleep(200)
      end
      if SS.isKeyJustPressed(keybinds.play_anim.code) and not Game.Self.isBrowsingApps() then
        if not ped_grabbed and not vehicle_grabbed and not is_hiding and not is_sitting then
          if not is_playing_anim then
            if info ~= nil then
              if info.cat == "In-Vehicle" and (Game.Self.isOnFoot() or not is_car) then
                UI.widgetSound("Error")
                gui.show_error("Samurai's Scripts",
                  "This animation can only be played while sitting inside a vehicle (cars and trucks only).")
              else
                UI.widgetSound("Select")
                local mycoords     = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
                local myheading    = ENTITY.GET_ENTITY_HEADING(self.get_ped())
                local myforwardX   = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
                local myforwardY   = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
                local myboneIndex  = PED.GET_PED_BONE_INDEX(self.get_ped(), info.boneID)
                local mybonecoords = PED.GET_PED_BONE_COORDS(self.get_ped(), info.boneID, 0.0, 0.0, 0.0)
                if manualFlags then
                  anim_flag = setAnimFlags()
                else
                  anim_flag = info.flag
                end
                playAnim(info, self.get_ped(), anim_flag, selfprop1, selfprop2, selfloopedFX, selfSexPed, myboneIndex,
                  mycoords,
                  myheading, myforwardX, myforwardY, mybonecoords, plyrProps, selfPTFX, script
                )
                curr_playing_anim = info
                is_playing_anim   = true
              end
              script:sleep(200)
            end
          else
            UI.widgetSound("Error")
            if not PAD.IS_USING_KEYBOARD_AND_MOUSE(0) then
              PAD.SET_CONTROL_SHAKE(0, 500, 250)
            end
            gui.show_warning("Samurais Scripts",
              string.format("Press %s to stop the current animation before playing the next one.", STOP_ANIM_BUTTON))
            script:sleep(800)
          end
        else
          UI.widgetSound("Error")
          gui.show_error("Samurais Scripts",
            "You can not play animations while grabbing an NPC, grabbing a vehicle or hiding.")
          script:sleep(800)
        end
      end
    end
  end
  if npc_blips[1] ~= nil then
    for _, b in ipairs(npc_blips) do
      if HUD.DOES_BLIP_EXIST(b) then
        for _, npc in ipairs(spawned_npcs) do
          if PED.IS_PED_SITTING_IN_ANY_VEHICLE(npc) then
            if HUD.GET_BLIP_ALPHA(b) > 1.0 then
              HUD.SET_BLIP_ALPHA(b, 0.0)
            end
          else
            if HUD.GET_BLIP_ALPHA(b) < 1000.0 then
              HUD.SET_BLIP_ALPHA(b, 1000.0)
            end
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

  if is_playing_scenario then
    if SS.isKeyJustPressed(keybinds.stop_anim.code) then
      stopScenario(self.get_ped(), script)
    end
  end
end)

-- Animation Shotrcut
script.register_looped("ANIMSC", function(animsc) -- Anim Shortcut
  if shortcut_anim.anim ~= nil and not gui.is_open() and not ped_grabbed and not vehicle_grabbed and not is_hiding then
    if SS.isKeyJustPressed(shortcut_anim.btn) and not is_typing and not is_setting_hotkeys and not is_playing_anim and not is_playing_scenario then
      if not ped_grabbed and not vehicle_grabbed and not is_hiding and not is_sitting then
        is_shortcut_anim   = true
        info               = shortcut_anim
        local mycoords     = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
        local myheading    = ENTITY.GET_ENTITY_HEADING(self.get_ped())
        local myforwardX   = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
        local myforwardY   = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
        local myboneIndex  = PED.GET_PED_BONE_INDEX(self.get_ped(), info.boneID)
        local mybonecoords = PED.GET_PED_BONE_COORDS(self.get_ped(), info.boneID, 0.0, 0.0, 0.0)
        if is_playing_anim or is_playing_scenario then
          cleanup(animsc)
          if ENTITY.DOES_ENTITY_EXIST(bbq) then
            ENTITY.DELETE_ENTITY(bbq)
          end
          is_playing_anim     = false
          is_playing_scenario = false
          animsc:sleep(500)
        end
        if Game.requestAnimDict(shortcut_anim.dict) then
          playAnim(shortcut_anim, self.get_ped(), anim_flag, selfprop1, selfprop2, selfloopedFX, selfSexPed,
            myboneIndex, mycoords, myheading, myforwardX, myforwardY, mybonecoords, plyrProps, selfPTFX, animsc
          )
          curr_playing_anim = shortcut_anim
          animsc:sleep(100)
          curr_playing_anim = shortcut_anim
          is_playing_anim   = true
          is_shortcut_anim  = true
        end
      else
        gui.show_error("Samurai's Scripts",
          "You can not play animations while grabbing an NPC, grabbing a vehicle, sitting or hiding.")
      end
    end
  end
  if is_shortcut_anim and SS.isKeyJustPressed(shortcut_anim.btn) then
    animsc:sleep(100)
    cleanup(animsc)
    is_playing_anim  = false
    is_shortcut_anim = false
  end
end)

script.register_looped("PRF", function()
  if disableActionMode then
    Game.Self.DisableActionMode()
  end
  if hatsinvehs then
    Game.Self.AllowHatsInVehicles()
  end
  if novehragdoll then
    Game.Self.NoRagdollOnVehRoof()
  end
end)

script.register_looped("MISCNPC", function()
  if spawned_npcs[1] ~= nil then
    for k, v in ipairs(spawned_npcs) do
      if ENTITY.DOES_ENTITY_EXIST(v) and ENTITY.IS_ENTITY_DEAD(v, false) then
        PED.REMOVE_PED_FROM_GROUP(v)
        ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(v)
        table.remove(spawned_npcs, k)
      end
    end
  end
end)

-- weapon stuff
script.register_looped("HG", function() -- Hash Grabber
  if HashGrabber then
    if WEAPON.IS_PED_ARMED(self.get_ped(), 4) and PLAYER.IS_PLAYER_FREE_AIMING(self.get_id()) and PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 24) then
      local ent                 = Game.getAimedEntity()
      local hash                = Game.getEntityModel(ent)
      local type_index          = SS.getEntityType(ent)
      local eModelTypes <const> = {
        [0]     = 'Invalid',
        [1]     = 'Object',
        [2]     = 'MLO',
        [3]     = 'Time',
        [4]     = 'Weapon',
        [5]     = 'Vehicle',
        [6]     = 'Ped',
        [7]     = 'Destructible',
        [33]    = 'Destructible',
        [157]   = 'Building/Map Texture',
        [43649] = 'Fixed Map Object',
        [16385] = 'Fixed Map Object',
      }
      local type_name           = eModelTypes[type_index] ~= nil and eModelTypes[type_index] or "Unk"
      log.debug(string.format(
      "\n----- Info Gun -----\n¤ Handle:      %d\n¤ Hash:        %d\n¤ Type Index:  %d\n¤ Type Name:   %s", ent, hash,
        type_index, type_name))
    end
  end
end)
script.register_looped("TB", function() -- Triggerbot
  if Triggerbot then
    if PLAYER.IS_PLAYER_FREE_AIMING(PLAYER.PLAYER_ID()) then
      local aimBool, Entity = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID(), Entity)
      if aimBool and ENTITY.IS_ENTITY_A_PED(Entity) and PED.IS_PED_HUMAN(Entity) then
        local bonePos = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(Entity,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(Entity, "head"))
        weapon = Game.Self.weapon()
        if WEAPON.IS_PED_WEAPON_READY_TO_SHOOT(self.get_ped()) and Game.Self.isOnFoot() and not PED.IS_PED_RELOADING(self.get_ped()) then
          if PAD.IS_CONTROL_PRESSED(0, 21) and not ENTITY.IS_ENTITY_DEAD(Entity, false) then
            if aimEnemy then
              if Game.Self.isPedEnemy(Entity) then
                TASK.TASK_AIM_GUN_AT_COORD(self.get_ped(), bonePos.x, bonePos.y, bonePos.z, 250, true, false)
                TASK.TASK_SHOOT_AT_COORD(self.get_ped(), bonePos.x, bonePos.y, bonePos.z, 250, 2556319013)
              end
            else
              TASK.TASK_AIM_GUN_AT_COORD(self.get_ped(), bonePos.x, bonePos.y, bonePos.z, 250, true, false)
              TASK.TASK_SHOOT_AT_COORD(self.get_ped(), bonePos.x, bonePos.y, bonePos.z, 250, 2556319013)
            end
          end
        end
      end
    end
  end
end)
script.register_looped("AKE", function(ak) -- Auto-kill enemies
  if autoKill then
    local myCoords = self.get_pos()
    local gta_peds = entities.get_all_peds_as_handles()
    if (PED.COUNT_PEDS_IN_COMBAT_WITH_TARGET_WITHIN_RADIUS(self.get_ped(), myCoords.x, myCoords.y, myCoords.z, 500)) > 0 then
      ak:sleep(10)
      for _, p in pairs(gta_peds) do
        if PED.IS_PED_HUMAN(p) and Game.Self.isPedEnemy(p) and not PED.IS_PED_A_PLAYER(p) then
          if PED.IS_PED_IN_ANY_VEHICLE(p, false) then
            local enemy_vehicle        = PED.GET_VEHICLE_PED_IS_IN(p, false)
            local enemy_vehicle_coords = ENTITY.GET_ENTITY_COORDS(enemy_vehicle, true)
            local dist                 = SYSTEM.VDIST(enemy_vehicle_coords.x, enemy_vehicle_coords.y,
              enemy_vehicle_coords.z, myCoords.x, myCoords.y, myCoords.z)
            if dist >= 20 then
              VEHICLE.SET_VEHICLE_ENGINE_HEALTH(enemy_vehicle, -4000)
              if VEHICLE.IS_THIS_MODEL_A_BIKE(ENTITY.GET_ENTITY_MODEL(enemy_vehicle)) or VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(enemy_vehicle)) then
                for i = 0, 7 do
                  VEHICLE.SET_VEHICLE_TYRE_BURST(enemy_vehicle, i, false, 1000.0)
                end
              end
              PED.APPLY_DAMAGE_TO_PED(p, 100000, true, 0, 0x7FD62962)
              -- NETWORK.NETWORK_EXPLODE_VEHICLE(enemy_vehicle, true, false, 0)
            end
          else
            PED.APPLY_DAMAGE_TO_PED(p, 100000, true, 0, 0x7FD62962)
          end
        end
      end
    end
  end
end)
script.register_looped("EF", function() -- Enemies Flee
  if runaway then
    local myCoords = self.get_pos()
    if (PED.COUNT_PEDS_IN_COMBAT_WITH_TARGET_WITHIN_RADIUS(self.get_ped(), myCoords.x, myCoords.y, myCoords.z, 100)) > 0 then
      for _, p in pairs(entities.get_all_peds_as_handles()) do
        if PED.IS_PED_HUMAN(p) and Game.Self.isPedEnemy(p) and not PED.IS_PED_A_PLAYER(p) then
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
end)
script.register_looped("KATANA", function(rpq)
  if replace_pool_q then
    if WEAPON.IS_PED_ARMED(self.get_ped(), 1) and WEAPON.GET_SELECTED_PED_WEAPON(self.get_ped()) == katana_replace_model then
      local pool_q = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(self.get_ped(), 0)
      if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(pool_q, self.get_ped()) then
        if not ENTITY.DOES_ENTITY_EXIST(katana) then
          if Game.requestModel(0xE2BA016F) then
            katana = OBJECT.CREATE_OBJECT(0xE2BA016F, 0, 0, 0, true, false, true)
            if ENTITY.DOES_ENTITY_EXIST(katana) then
              ENTITY.SET_ENTITY_COLLISION(katana, false, false)
              ENTITY.SET_ENTITY_ALPHA(pool_q, 0.0, false)
              ENTITY.SET_ENTITY_VISIBLE(pool_q, false, false)
              rpq:sleep(100)
              ENTITY.ATTACH_ENTITY_TO_ENTITY(
              katana, pool_q, 0, 0.0, 0.0, 0.025, 0.0, 0.0, 0.0,
              false, false, false, false, 2, true, 0
              )
              q_replaced = true
            end
          end
        end
      else
        if q_replaced then
          if ENTITY.DOES_ENTITY_EXIST(katana) then
            ENTITY.DELETE_ENTITY(katana)
          end
          q_replaced = false
          katana     = 0
        end
      end
    else
      if q_replaced then
        if ENTITY.DOES_ENTITY_EXIST(katana) then
          ENTITY.DELETE_ENTITY(katana)
        end
        q_replaced = false
        katana     = 0
      end
    end
  end
end)

script.register_looped("LSR", function() -- Laser Sight
  if laserSight and WEAPON.IS_PED_ARMED(self.get_ped(), 4) and Game.Self.isOnFoot() then
    if PLAYER.IS_PLAYER_FREE_AIMING(self.get_id()) then
      local wpn_idx = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(self.get_ped(), 0)
      local wpn_bone = 0
      if wpn_hash ~= 0x34A67B97 and wpn_hash ~= 0xBA536372 and wpn_hash ~= 0x184140A1 and wpn_hash ~= 0x060EC506 then
        for _, bone in ipairs(weapbones_T) do
          bone_check = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(wpn_idx, bone)
          if bone_check ~= -1 then
            wpn_bone = bone_check
            break
          end
        end
      end
      local bone_pos    = ENTITY.GET_ENTITY_BONE_POSTION(wpn_idx, wpn_bone)
      local camRotation = CAM.GET_GAMEPLAY_CAM_ROT(0)
      local direction   = Lua_fn.RotToDir(camRotation)
      local destination = vec3:new(
        bone_pos.x + direction.x * 1000,
        bone_pos.y + direction.y * 1000,
        bone_pos.z + direction.z * 1000
      )
      local hit, endCoords, _ = Game.rayCast(bone_pos, destination, -1, self.get_ped())
      draw_laser(hit, bone_pos, endCoords, destination, laser_choice)
    end
  end
end)

-- vehicle stuff
script.register_looped("TDFT", function(script)
  if PED.IS_PED_IN_ANY_VEHICLE(self.get_ped(), false) then
    current_vehicle = onVehEnter()
    cv_engineHealth = VEHICLE.GET_VEHICLE_ENGINE_HEALTH(current_vehicle)
    cv_topSpeed     = VEHICLE.GET_VEHICLE_ESTIMATED_MAX_SPEED(current_vehicle)
    is_car          = VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(current_vehicle))
    is_quad         = VEHICLE.IS_THIS_MODEL_A_QUADBIKE(ENTITY.GET_ENTITY_MODEL(current_vehicle))
    is_plane        = VEHICLE.IS_THIS_MODEL_A_PLANE(ENTITY.GET_ENTITY_MODEL(current_vehicle))
    is_heli         = VEHICLE.IS_THIS_MODEL_A_HELI(ENTITY.GET_ENTITY_MODEL(current_vehicle))
    is_bike         = (VEHICLE.IS_THIS_MODEL_A_BIKE(ENTITY.GET_ENTITY_MODEL(current_vehicle))
      and VEHICLE.GET_VEHICLE_CLASS(current_vehicle) ~= 13 and ENTITY.GET_ENTITY_MODEL(current_vehicle) ~= 0x7B54A9D3)
    is_boat         = (VEHICLE.IS_THIS_MODEL_A_BOAT(ENTITY.GET_ENTITY_MODEL(current_vehicle)) or
      VEHICLE.IS_THIS_MODEL_A_JETSKI(ENTITY.GET_ENTITY_MODEL(current_vehicle)))
    vehicleLockStatus = (VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(current_vehicle) <= 1) and 1 or 2
    if is_car or is_quad or is_bike then
      validModel = true
    else
      validModel = false
    end
    if validModel and (driftMode or DriftTires) then
      if pressing_drift_button then
        if not drift_started then
          if driftMode then
            VEHICLE.SET_VEHICLE_REDUCE_GRIP(current_vehicle, true)
            VEHICLE.SET_VEHICLE_REDUCE_GRIP_LEVEL(current_vehicle, DriftIntensity)
          elseif DriftTires then
            VEHICLE.SET_DRIFT_TYRES(current_vehicle, true)
          end
          drift_started = true
        end
        VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(current_vehicle, DriftPowerIncrease)
      else
        if drift_started then
          VEHICLE.SET_VEHICLE_REDUCE_GRIP(current_vehicle, false)
          VEHICLE.SET_DRIFT_TYRES(current_vehicle, false)
          VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(current_vehicle, 1.0)
          drift_started = false
        end
      end
    end

    if speedBoost then
      if validModel or is_boat then
        if VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(current_vehicle) then
          if pressing_nos_button and PAD.IS_CONTROL_PRESSED(0, 71) then
            VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(current_vehicle, (nosPower) / 5)
            VEHICLE.MODIFY_VEHICLE_TOP_SPEED(current_vehicle, nosPower)
            if nosAudio then
              AUDIO.SET_VEHICLE_BOOST_ACTIVE(current_vehicle, true)
            end
            if nosvfx then
              GRAPHICS.ANIMPOSTFX_PLAY("DragRaceNitrous", 0, false)
            end
            using_nos = true
          end
        else
          if PED.IS_PED_SITTING_IN_ANY_VEHICLE(self.get_ped()) then
            if pressing_nos_button and PAD.IS_CONTROL_PRESSED(0, 71) then
              if VEHICLE.GET_VEHICLE_ENGINE_HEALTH(current_vehicle) < 300 then
                AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "Engine_fail", current_vehicle,
                  "DLC_PILOT_ENGINE_FAILURE_SOUNDS", true, 0)
              end
            end
          end
        end
      end
      if using_nos and not pressing_nos_button then
        VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(current_vehicle, 1.0)
        VEHICLE.MODIFY_VEHICLE_TOP_SPEED(current_vehicle, -1)
        AUDIO.SET_VEHICLE_BOOST_ACTIVE(current_vehicle, false)
        if nosvfx then
          GRAPHICS.ANIMPOSTFX_PLAY("DragRaceNitrousOut", 0, false)
        end
        if GRAPHICS.ANIMPOSTFX_IS_RUNNING("DragRaceNitrous") then
          GRAPHICS.ANIMPOSTFX_STOP("DragRaceNitrous")
        end
        if GRAPHICS.ANIMPOSTFX_IS_RUNNING("DragRaceNitrousOut") then
          GRAPHICS.ANIMPOSTFX_STOP("DragRaceNitrousOut")
        end
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
    if keepWheelsTurned and Game.Self.isDriving() and Game.Self.isOutside() and is_car and not holdF and not ducking_in_car
    and not is_typing and not is_setting_hotkeys then
      if PAD.IS_DISABLED_CONTROL_PRESSED(0, 75) and (PAD.IS_CONTROL_PRESSED(0, 34) or PAD.IS_CONTROL_PRESSED(0, 35))
      and not HUD.IS_MP_TEXT_CHAT_TYPING() then
        VEHICLE.SET_VEHICLE_ENGINE_ON(current_vehicle, false, true, false)
        TASK.TASK_LEAVE_VEHICLE(self.get_ped(), current_vehicle, 16)
      end
    end
    if holdF and Game.Self.isDriving() and Game.Self.isOutside() then
      if PAD.IS_DISABLED_CONTROL_PRESSED(0, 75) and not HUD.IS_MP_TEXT_CHAT_TYPING() then
        timerB = timerB + 1
        if timerB >= 15 then
          if keepWheelsTurned and (PAD.IS_CONTROL_PRESSED(0, 34) or PAD.IS_CONTROL_PRESSED(0, 35)) and is_car and not ducking_in_car then
            VEHICLE.SET_VEHICLE_ENGINE_ON(current_vehicle, false, true, false)
            TASK.TASK_LEAVE_VEHICLE(self.get_ped(), current_vehicle, 16)
            timerB = 0
          else
            VEHICLE.SET_VEHICLE_ENGINE_ON(current_vehicle, false, false, false)
            PED.SET_PED_CONFIG_FLAG(self.get_ped(), 241, false)
            TASK.TASK_LEAVE_VEHICLE(self.get_ped(), current_vehicle, 0)
            timerB = 0
          end
        end
      end
      if timerB >= 1 and timerB <= 10 then
        if PAD.IS_DISABLED_CONTROL_RELEASED(0, 75) and not HUD.IS_MP_TEXT_CHAT_TYPING() and not is_typing and not is_setting_hotkeys then
          if keepWheelsTurned and (PAD.IS_CONTROL_PRESSED(0, 34) or PAD.IS_CONTROL_PRESSED(0, 35)) and is_car and not ducking_in_car then
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
      if PED.GET_PED_CONFIG_FLAG(self.get_ped(), 241, true) then
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
    if current_vehicle ~= 0 then
      if not ENTITY.DOES_ENTITY_EXIST(current_vehicle) then
        current_vehicle = 0
      end
    end
  end
end)
script.register_looped("DSPTFX", function(dsptfx) -- Drift Sound/Partice FX
  if Game.Self.isDriving() then
    local dict = "scr_ba_bb"
    local wheels = { "wheel_lr", "wheel_rr" }
    if not VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) then
      if DriftSmoke and (driftMode or DriftTires) then
        local vehSpeedVec = ENTITY.GET_ENTITY_SPEED_VECTOR(current_vehicle, true)
        if (vehSpeedVec.x > 6 or vehSpeedVec.x < -6) and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(current_vehicle) then
          if is_car and pressing_drift_button and PAD.IS_CONTROL_PRESSED(0, 71) and VEHICLE.GET_VEHICLE_CURRENT_DRIVE_GEAR_(current_vehicle) > 0 and ENTITY.GET_ENTITY_SPEED(current_vehicle) > 6 then
            if Game.requestNamedPtfxAsset(dict) then
              if not has_custom_tires then
                VEHICLE.TOGGLE_VEHICLE_MOD(current_vehicle, 20, true)
              end
              VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(current_vehicle, driftSmoke_T.r, driftSmoke_T.g, driftSmoke_T.b)
              for _, boneName in ipairs(wheels) do
                local r_wheels = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, boneName)
                GRAPHICS.USE_PARTICLE_FX_ASSET(dict)
                smokePtfx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE("scr_ba_bb_plane_smoke_trail",
                  current_vehicle,
                  -0.4, 0.0, 0.0, 0.0, 0.0, 0.0, r_wheels, 0.3, false, false, false, 0, 0, 0, 255)
                GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(smokePtfx, driftSmoke_T.r, driftSmoke_T.g, driftSmoke_T.b, false)
                table.insert(smokePtfx_t, smokePtfx)
                GRAPHICS.STOP_PARTICLE_FX_LOOPED(smoke, false)
                tire_smoke = true
              end
              if tire_smoke then
                repeat
                  dsptfx:sleep(50)
                until
                  not pressing_drift_button or PAD.IS_CONTROL_RELEASED(0, 71) or VEHICLE.IS_VEHICLE_STOPPED(current_vehicle)
                for _, smoke in ipairs(smokePtfx_t) do
                  if GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(smoke) then
                    GRAPHICS.STOP_PARTICLE_FX_LOOPED(smoke, false)
                    GRAPHICS.REMOVE_PARTICLE_FX(smoke, false)
                  end
                end
                tire_smoke = false
              end
            end
          end
        end
      end
    else
      if BurnoutSmoke and not launchCtrl then
        if VEHICLE.IS_VEHICLE_IN_BURNOUT(current_vehicle) then
          dsptfx:sleep(1000)
          if Game.requestNamedPtfxAsset(dict) then
            if not has_custom_tires then
              VEHICLE.TOGGLE_VEHICLE_MOD(current_vehicle, 20, true)
            end
            VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(current_vehicle, driftSmoke_T.r, driftSmoke_T.g, driftSmoke_T.b)
            for _, boneName in ipairs(wheels) do
              local r_wheels = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, boneName)
              GRAPHICS.USE_PARTICLE_FX_ASSET(dict)
              smokePtfx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE("scr_ba_bb_plane_smoke_trail",
                current_vehicle,
                -0.4, 0.0, 0.0, 0.0, 0.0, 90.0, r_wheels, 0.2, false, false, false, 0, 0, 0, 255)
              GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(smokePtfx, driftSmoke_T.r, driftSmoke_T.g, driftSmoke_T.b, false)
              table.insert(smokePtfx_t, smokePtfx)
              GRAPHICS.STOP_PARTICLE_FX_LOOPED(smoke, false)
              tire_smoke = true
            end
            if tire_smoke then
              repeat
                dsptfx:sleep(50)
              until
                VEHICLE.IS_VEHICLE_IN_BURNOUT(current_vehicle) == false
              for _, smoke in ipairs(smokePtfx_t) do
                if GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(smoke) then
                  GRAPHICS.STOP_PARTICLE_FX_LOOPED(smoke, false)
                  GRAPHICS.REMOVE_PARTICLE_FX(smoke, false)
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
script.register_looped("LCTRL", function(lct) -- Launch Control
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
        if PAD.IS_CONTROL_PRESSED(0, 71) and PAD.IS_CONTROL_PRESSED(0, 72) and not pressing_drift_button then
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
script.register_looped("ABSPREP", function(abs)
  if abs_lights and Game.Self.isDriving() and is_car then
    if Game.Vehicle.hasABS() and PAD.IS_CONTROL_PRESSED(0, 72) then
      if (ENTITY.GET_ENTITY_SPEED(self.get_veh()) * 3.6) > 100 then
        repeat
          should_flash_bl = not should_flash_bl
          abs:sleep(100)
        until (ENTITY.GET_ENTITY_SPEED(self.get_veh()) * 3.6) < 50 or not PAD.IS_CONTROL_PRESSED(0, 72) or
          not VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(current_vehicle)
        should_flash_bl = false
      end
    end
  end
end)
script.register_looped("MISCVEH", function(mvo)
  if Game.Self.isDriving() then
    if autobrklight then
      if VEHICLE.IS_VEHICLE_DRIVEABLE(current_vehicle, false) and VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(current_vehicle) then
        VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(current_vehicle, true)
      end
    end

    if abs_lights and is_car and Game.Vehicle.hasABS() and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(current_vehicle)
        and not VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) then
      if should_flash_bl then
        VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(current_vehicle, false)
      end
    end

    if insta180 then
      local vehRot = ENTITY.GET_ENTITY_ROTATION(current_vehicle, 2)
      if PAD.IS_CONTROL_JUST_PRESSED(0, 97) then -- numpad + || mouse scroll down
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

  if flappyDoors and current_vehicle ~= 0 and not is_bike and not is_boat then
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

  if loud_radio then
    if current_vehicle ~= nil and current_vehicle ~= 0 then
      if not loud_radio_enabled then
        AUDIO.SET_VEHICLE_RADIO_LOUD(current_vehicle, true)
        loud_radio_enabled = true
      end
    else
      if loud_radio_enabled then
        loud_radio_enabled = false
      end
    end
  end

  if autovehlocks then
    if current_vehicle ~= 0 and is_car then
      local vehPos   = Game.getCoords(current_vehicle, true)
      local selfPos  = self.get_pos()
      local distance = vec3:distance(vehPos, selfPos)
      local isLocked = VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(current_vehicle) > 1
      if not isLocked and distance > 20 then
        Game.Vehicle.lockDoors(current_vehicle, true, mvo)
      end
      if isLocked and PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(self.get_ped()) == current_vehicle then
        Game.Vehicle.lockDoors(current_vehicle, false, mvo)
      end
      vehicleLockStatus = isLocked and 2 or 1
    end
  end

  if fast_vehicles and current_vehicle ~= 0 and (is_car or is_bike or is_quad) then
    if cv_topSpeed <= 50 then
      VEHICLE.MODIFY_VEHICLE_TOP_SPEED(current_vehicle, 100)
    end
  end
end)
script.register_looped("ALARMMGR", function(amgr)
  if vehicleLockStatus == 2 and VEHICLE.IS_VEHICLE_ALARM_ACTIVATED(current_vehicle) then
    repeat
      amgr:sleep(100)
    until not VEHICLE.IS_VEHICLE_ALARM_ACTIVATED(current_vehicle)
    VEHICLE.SET_VEHICLE_ALARM(current_vehicle, vehicleLockStatus == 2)
  end
end)
script.register_looped("NOSPTFX", function(spbptfx)
  spbptfx:yield()
  if nosFlames then
    if speedBoost and Game.Self.isDriving() then
      if validModel or is_boat or is_bike then
        if pressing_nos_button and PAD.IS_CONTROL_PRESSED(0, 71) then
          if VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(current_vehicle) then
            local effect = "veh_xs_vehicle_mods"
            if Game.requestNamedPtfxAsset(effect) then
              local exhaustCount = VEHICLE.GET_VEHICLE_MAX_EXHAUST_BONE_COUNT_() - 1
              for i = 0, exhaustCount do
                local retBool, boneIndex = VEHICLE.GET_VEHICLE_EXHAUST_BONE_(current_vehicle, i, retBool, boneIndex)
                if retBool then
                  GRAPHICS.USE_PARTICLE_FX_ASSET(effect)
                  nosPtfx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE("veh_nitrous", current_vehicle,
                    0.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, boneIndex, 1.0, false, false, false, 0, 0, 0, 255)
                  table.insert(nosptfx_t, nosPtfx)
                  nos_started = true
                end
              end
            end
            if nos_started then
              repeat
                spbptfx:sleep(50)
              until
                not pressing_nos_button or PAD.IS_CONTROL_RELEASED(0, 71)
              for _, nos in ipairs(nosptfx_t) do
                if GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(nos) then
                  GRAPHICS.STOP_PARTICLE_FX_LOOPED(nos, false)
                  GRAPHICS.REMOVE_PARTICLE_FX(nos, false)
                end
              end
              STREAMING.REMOVE_NAMED_PTFX_ASSET(effect)
              nos_started = false
            end
          end
        end
      end
    end
  end
end)
script.register_looped("TWOSTEP", function(twostep)
  if launchCtrl and Game.Self.isDriving() then
    if limitVehOptions then
      if VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 4 and VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 6 and VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 7 then
        return
      end
    end
    if validModel or is_bike or is_quad then
      if VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(current_vehicle) and VEHICLE.GET_VEHICLE_ENGINE_HEALTH(current_vehicle) >= 300 then
        if PAD.IS_CONTROL_PRESSED(0, 71) and PAD.IS_CONTROL_PRESSED(0, 72) and not pressing_drift_button then
          local asset = "core"
          if Game.requestNamedPtfxAsset(asset) then
            local exhaustCount = VEHICLE.GET_VEHICLE_MAX_EXHAUST_BONE_COUNT_() - 1
            for i = 0, exhaustCount do
              local retBool, boneIndex = VEHICLE.GET_VEHICLE_EXHAUST_BONE_(current_vehicle, i, retBool, boneIndex)
              if retBool then
                GRAPHICS.USE_PARTICLE_FX_ASSET(asset)
                lctPtfx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE("veh_backfire", current_vehicle, 0.0,
                  0.0, 0.0, 0.0, 0.0, 0.0, boneIndex, 0.69420, false, false, false, 0, 0, 0, 255)
                table.insert(lctPtfx_t, lctPtfx)
                twostep_started = true
              end
            end
          end
          if twostep_started then
            repeat
              twostep:sleep(50)
            until PAD.IS_CONTROL_RELEASED(0, 72) or launch_active == false
            for _, bfire in ipairs(lctPtfx_t) do
              if GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(bfire) then
                GRAPHICS.STOP_PARTICLE_FX_LOOPED(bfire, false)
                GRAPHICS.REMOVE_PARTICLE_FX(bfire, false)
              end
            end
            STREAMING.REMOVE_NAMED_PTFX_ASSET(asset)
            twostep_started = false
          end
        end
      end
    end
  end
end)
script.register_looped("LCSFX", function(tstp) -- Launch Contol SFX
  if Game.Self.isDriving() then
    if limitVehOptions then
      if VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 4 and VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 6 and VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 7 then
        return
      end
    end
    if launchCtrl and lctPtfx_t[1] ~= nil then
      if VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) and PAD.IS_CONTROL_PRESSED(0, 71) and PAD.IS_CONTROL_PRESSED(0, 72) and not pressing_drift_button then
        for _, p in ipairs(lctPtfx_t) do
          if GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(p) then
            local randStime = math.random(60, 120)
            AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "BOOT_POP", current_vehicle, "DLC_VW_BODY_DISPOSAL_SOUNDS",
              true, 0)
            tstp:sleep(randStime)
            started_popSound = true
          end
        end
      end
    end
    if popsNbangs then
      if VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) then
        rpmThreshold = 0.45
      elseif noEngineBraking then
        rpmThreshold = 0.80
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
        local randStime = math.random(60, 200)
        AUDIO.PLAY_SOUND_FROM_ENTITY(-1, popsnd, current_vehicle, sndRef, true, 0)
        tstp:sleep(randStime)
        started_popSound2 = true
      end
    end
  end
end)
script.register_looped("PNB", function(pnb) -- Pops & Bangs
  if Game.Self.isDriving() and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(current_vehicle) then
    if is_car or is_bike or is_quad then
      if popsNbangs then
        if limitVehOptions then
          if VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 4 and VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 6 and VEHICLE.GET_VEHICLE_CLASS(self.get_veh()) ~= 7 then
            return
          end
        end
        AUDIO.ENABLE_VEHICLE_EXHAUST_POPS(current_vehicle, false)
        default_pops_disabled = true
        local asset           = "core"
        local currRPM         = VEHICLE.GET_VEHICLE_CURRENT_REV_RATIO_(current_vehicle)
        local currGear        = VEHICLE.GET_VEHICLE_CURRENT_DRIVE_GEAR_(current_vehicle)
        if VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) then
          rpmThreshold = 0.45
        elseif noEngineBraking then
          rpmThreshold = 0.80
        else
          rpmThreshold = 0.69
        end
        if Game.requestNamedPtfxAsset(asset) then
          if PAD.IS_CONTROL_RELEASED(0, 71) and currRPM < 1.0 and currRPM > rpmThreshold and currGear ~= 0 then
            local exhaustCount = VEHICLE.GET_VEHICLE_MAX_EXHAUST_BONE_COUNT_() - 1
            for i = 0, exhaustCount do
              local retBool, boneIndex = VEHICLE.GET_VEHICLE_EXHAUST_BONE_(current_vehicle, i, retBool, boneIndex)
              if retBool then
                currRPM = VEHICLE.GET_VEHICLE_CURRENT_REV_RATIO_(current_vehicle)
                if currRPM < 1.0 and currRPM > 0.55 then
                  GRAPHICS.USE_PARTICLE_FX_ASSET(asset)
                  popsPtfx = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE("veh_backfire", current_vehicle,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, boneIndex, flame_size, false, false, false, 0, 0, 0, 255)
                  GRAPHICS.STOP_PARTICLE_FX_LOOPED(popsPtfx, false)
                  table.insert(popsPtfx_t, popsPtfx)
                  started_popSound2 = true
                end
              end
            end
          end
        end
        if started_popSound2 then
          currRPM = VEHICLE.GET_VEHICLE_CURRENT_REV_RATIO_(current_vehicle)
          if PAD.IS_CONTROL_PRESSED(0, 71) or currRPM < rpmThreshold then
            for _, bfire in ipairs(popsPtfx_t) do
              if GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(bfire) then
                GRAPHICS.STOP_PARTICLE_FX_LOOPED(bfire, false)
                GRAPHICS.REMOVE_PARTICLE_FX(bfire, false)
              end
            end
            STREAMING.REMOVE_NAMED_PTFX_ASSET(asset)
            started_popSound2 = false
          end
        end
      else
        if default_pops_disabled then
          AUDIO.ENABLE_VEHICLE_EXHAUST_POPS(current_vehicle, true)
          default_pops_disabled = false
        end
      end
    end
  end
end)
script.register_looped("PNBSE", function(pnbse) -- Pops & Bangs Shocking Event
  if started_popSound2 and louderPops then
    local myPos = self.get_pos()
    if not EVENT.IS_SHOCKING_EVENT_IN_SPHERE(79, myPos.x, myPos.y, myPos.z, 50) then
      loud_pops_event = EVENT.ADD_SHOCKING_EVENT_FOR_ENTITY(79, current_vehicle, 10.0)
      repeat
        pnbse:sleep(10)
      until started_popSound2 == false
      EVENT.REMOVE_SHOCKING_EVENT(loud_pops_event)
    end
  end
end)
script.register_looped("VEHMNS", function(vmns) -- Vehicle Mines
  if Game.Self.isDriving() then
    if veh_mines and current_vehicle ~= 0 and (is_car or is_bike or is_quad) then
      local bone_n = "chassis_dummy"
      local mine_hash
      if vmine_type.spikes then
        mine_hash = -647126932
      elseif vmine_type.slick then
        mine_hash = 1459276487
      elseif vmine_type.explosive then
        mine_hash = 1508567460
      elseif vmine_type.emp then
        mine_hash = 1776356704
      elseif vmine_type.kinetic then
        mine_hash = 1007245390
      else
        mine_hash = -647126932 -- default to spikes if nothing else was selected.
      end
      local bone_idx = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(self.get_veh(), bone_n)
      if pressing_vmine_button then
        if Game.requestWeaponAsset(mine_hash) then
          if bone_idx ~= -1 then
            local bone_pos    = ENTITY.GET_ENTITY_BONE_POSTION(self.get_veh(), bone_idx)
            local veh_pos     = ENTITY.GET_ENTITY_COORDS(self.get_veh(), true)
            local veh_fwd     = ENTITY.GET_ENTITY_FORWARD_VECTOR(self.get_veh())
            local veh_hash    = ENTITY.GET_ENTITY_MODEL(self.get_veh())
            local vmin, vmax  = Game.getModelDimensions(veh_hash)
            local veh_len     = vmax.y - vmin.y
            local _, ground_z = MISC.GET_GROUND_Z_FOR_3D_COORD(veh_pos.x, veh_pos.y, veh_pos.z, ground_z, false, false)
            local x_offset    = veh_fwd.x * (veh_len / 1.6)
            local y_offset    = veh_fwd.y * (veh_len / 1.6)
            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
              bone_pos.x - x_offset, bone_pos.y - y_offset, bone_pos.z,
              bone_pos.x - x_offset, bone_pos.y - y_offset, ground_z,
              0.0, false, mine_hash, self.get_ped(), true, false, 0.01
            )
          end
        end
        vmns:sleep(969)
      end
    end
  end
end)
-- drift minigame (WIP)
script.register_looped("SLCTR", function() -- Straight Line Counter
  if (driftMode or DriftTires) and driftMinigame and is_car then
    if Game.Self.isDriving() and is_drifting and driftMinigame then
      local vehSpeedVec = ENTITY.GET_ENTITY_SPEED_VECTOR(current_vehicle, true)
      if not VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) then
        if vehSpeedVec.x ~= 0 and vehSpeedVec.x < 2 or vehSpeedVec.x > -2 then
          straight_counter = straight_counter + 1
        else
          straight_counter = 0
        end
      end
    end
  end
end)
script.register_looped("DCTR", function(dcounter) -- Drift Counter
  if driftMinigame then
    if (driftMode or DriftTires) and is_car then
      if Game.Self.isDriving() then
        local vehSpeedVec = ENTITY.GET_ENTITY_SPEED_VECTOR(current_vehicle, true)
        if vehSpeedVec.x ~= 0 and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(current_vehicle) then
          if vehSpeedVec.x > 6 or vehSpeedVec.x < -6 then
            is_drifting       = true
            drift_streak_text = string.format("Drift   x%d", drift_multiplier)
            straight_counter  = 0
            drift_points      = drift_points + (1 * drift_multiplier)
          end
          if vehSpeedVec.x > 11 or vehSpeedVec.x < -11 then
            is_drifting       = true
            drift_streak_text = string.format("Big Angle!   x%d", drift_multiplier)
            straight_counter  = 0
            drift_points      = drift_points + (5 * drift_multiplier)
          end
          if vehSpeedVec.x > 14 or vehSpeedVec.x < -14 then
            is_drifting       = true
            drift_streak_text = string.format("SICK ANGLE!   x%d", drift_multiplier)
            straight_counter  = 0
            drift_points      = drift_points + (10 * drift_multiplier)
          end
        end
        if is_drifting then
          if not VEHICLE.IS_VEHICLE_STOPPED(current_vehicle) then
            if vehSpeedVec.x < 2 and vehSpeedVec.x > -2 then
              if straight_counter > 400 then
                if ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(current_vehicle) then
                  if checkVehicleCollision() then
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
                      bankDriftPoints_SP(Lua_fn.round((drift_points / 10), 0))
                    end
                  end
                  if drift_points > driftPB then
                    CFG.save("driftPB", drift_points)
                    driftPB = CFG.read("driftPB")
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
              if checkVehicleCollision() then
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
                  bankDriftPoints_SP(Lua_fn.round((drift_points / 10), 0))
                end
              end
              if drift_points > driftPB then
                CFG.save("driftPB", drift_points)
                driftPB = CFG.read("driftPB")
              end
              dcounter:sleep(3000)
              drift_points     = 0
              drift_multiplier = 1
              is_drifting      = false
            else
              if checkVehicleCollision() then
                drift_streak_text = 'Streak Lost!'
                drift_points      = 0
                drift_extra_pts   = 0
                drift_multiplier  = 1
                is_drifting       = false
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
          is_drifting       = false
        end
      end
    end
  end
end)
script.register_looped("drift time counter", function(dtcounter)
  if Game.Self.isDriving and is_car and driftMinigame and is_drifting then
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
script.register_looped("EPC", function(epc) -- Extra Points Checker
  if Game.Self.isDriving and is_car and driftMinigame then
    if is_drifting and ENTITY.GET_ENTITY_SPEED(current_vehicle) > 7 then
      if not ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(current_vehicle) then
        local vehicle_height = ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(current_vehicle)
        if vehicle_height > 0.8 and not VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(current_vehicle) then
          if vehicle_height >= 1.1 and vehicle_height <= 5 and not Lua_fn.str_contains(drift_extra_text, "Big Air!") then
            drift_extra_pts  = drift_extra_pts + 1
            drift_points     = drift_points + drift_extra_pts
            drift_extra_text = string.format("Air  +%d pts", drift_extra_pts)
            epc:sleep(100)
          elseif vehicle_height > 5 then
            drift_extra_pts  = drift_extra_pts + 5
            drift_points     = drift_points + drift_extra_pts
            drift_extra_text = string.format("Big Air!  +%d pts", drift_extra_pts)
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
        local bool, txt = checkVehicleCollision()
        if not bool and drift_streak_text ~= "" then
          drift_extra_pts  = drift_extra_pts + 1
          drift_points     = drift_points + drift_extra_pts
          drift_extra_text = string.format("%s  +%d pts", txt, drift_extra_pts)
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
script.register_looped("DMULT", function(dmult) -- Drift Multiplier
  if Game.Self.isDriving and is_car and driftMinigame and is_drifting then
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
script.register_looped("DP", function() -- Drift Points
  if Game.Self.isDriving() and is_car and driftMinigame and is_drifting then
    local diaplay_str = string.format("%s\n+%s pts", drift_streak_text, Lua_fn.separateInt(drift_points))
    showDriftCounter(diaplay_str)
    if drift_extra_pts > 0 or drift_extra_text ~= "" then
      showDriftExtra(drift_extra_text)
    end
  end
end)
script.register_looped("MDEF", function(md) -- Missile defence
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
    if missile ~= nil and missile ~= 0 then
      --[[
      if MISC.IS_PROJECTILE_TYPE_IN_AREA(vehPos.x + 100, vehPos.y + 100, vehPos.z + 100, vehPos.x - 100, vehPos.y - 100, vehPos.z - 100, missile, false) then
        if Game.Self.isDriving() and (is_plane or is_heli) then
          shoot_flares(md)
        end
      end
      ^ auto-counters missiles with flares but it's too easy in dogfights.
    ]]
      if MISC.IS_PROJECTILE_TYPE_IN_AREA(vehPos.x + 20, vehPos.y + 20, vehPos.z + 100, vehPos.x - 20, vehPos.y - 20, vehPos.z - 100, missile, false) then
        if not MISC.IS_PROJECTILE_TYPE_IN_AREA(vehPos.x + 10, vehPos.y + 10, vehPos.z + 50, vehPos.x - 10, vehPos.y - 10, vehPos.z - 50, missile, false) and not MISC.IS_PROJECTILE_TYPE_IN_AREA(selfPos.x + 10, selfPos.y + 10, selfPos.z + 50, selfPos.x - 10, selfPos.y - 10, selfPos.z - 50, missile, false) then
          if not disable_mdef_logs then
            log.info('Detected projectile within our defence area! Proceeding to destroy it.')
          end
          WEAPON.REMOVE_ALL_PROJECTILES_OF_TYPE(missile, true)
          if Game.requestNamedPtfxAsset("scr_sm_counter") then
            GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", vehPos.x, vehPos.y,
              (vehPos.z + 2.5),
              0.0, 0.0, 0.0, 5.0, false, false, false, false)
          end
        else
          if not disable_mdef_logs then
            log.warning('Found a projectile very close to our vehicle! Proceeding to remove it.')
          end
          WEAPON.REMOVE_ALL_PROJECTILES_OF_TYPE(missile, false)
          if Game.requestNamedPtfxAsset("scr_sm_counter") then
            GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
            GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", vehPos.x, vehPos.y,
              (vehPos.z + 2.5),
              0.0, 0.0, 0.0, 5.0, false, false, false, false)
          end
        end
      end
    end
    md:yield()
  end
end)
script.register_looped("NOSPRG", function(nosprg) -- NOS Purge
  if Game.Self.isDriving() then
    if nosPurge and validModel or nosPurge and is_bike then
      if pressing_purge_button and not is_using_flatbed then
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
            purge_posX, -0.33, 0.2, 0.0, -17.5, purge_rotZ, purge_exit, 0.4, false, false, false, 0, 0, 0, 255)
          table.insert(purgePtfx_t, purgePtfx)
          purge_started = true
        end
        if purge_started then
          repeat
            nosprg:sleep(50)
          until
            not pressing_purge_button
          for _, purge in ipairs(purgePtfx_t) do
            if GRAPHICS.DOES_PARTICLE_FX_LOOPED_EXIST(purge) then
              GRAPHICS.STOP_PARTICLE_FX_LOOPED(purge, false)
              GRAPHICS.REMOVE_PARTICLE_FX(purge, false)
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
script.register_looped("RGBL", function(rgb) -- RGB Lights
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

script.register_looped("CTT", function(ctt) -- Can't Touch This
  Game.Self.NoJacking(noJacking)
end)

script.register_looped("BCC", function(die) -- Better Car Crashes
  if fender_bender then
    if Game.Self.isDriving() and (is_car or is_bike or is_quad) then
      local myPos      = self.get_pos()
      local veh_speed  = ENTITY.GET_ENTITY_SPEED(current_vehicle)
      local shake_amp  = veh_speed / 30
      local soundName  = (ENTITY.GET_ENTITY_MODEL(self.get_ped()) == 0x705E61F2) and "WAVELOAD_PAIN_MALE" or
      "WAVELOAD_PAIN_FEMALE"
      local Occupants  = Game.Vehicle.getOccupants(current_vehicle)
      local crashed, _ = checkVehicleCollision()
      if PED.IS_PED_SITTING_IN_VEHICLE(self.get_ped(), current_vehicle) then
        local deform_mult = SS.getVehicleInfo().m_deformation_mult
        if deform_mult ~= nil and deform_mult:is_valid() then
          if deform_mult:get_float() < 2.0 then
            deform_mult:set_float(2.0)
          end
        end
      end
      if veh_speed >= 20 and ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(current_vehicle) and crashed then
        CAM.SHAKE_GAMEPLAY_CAM("GRENADE_EXPLOSION_SHAKE", shake_amp)
        if veh_speed >= 33 and veh_speed < 50 then
          die:sleep(100)
          if ENTITY.GET_ENTITY_SPEED(current_vehicle) < veh_speed - 5 then
            if not ENTITY.IS_ENTITY_A_MISSION_ENTITY(current_vehicle) then
              VEHICLE.SET_VEHICLE_ENGINE_HEALTH(current_vehicle,
                (VEHICLE.GET_VEHICLE_ENGINE_HEALTH(current_vehicle) - 200))
            end
            for _, ped in ipairs(Occupants) do
              ENTITY.SET_ENTITY_HEALTH(ped, (ENTITY.GET_ENTITY_HEALTH(ped) - (20 + (shake_amp * 5))), 0, 0)
            end
            if not GRAPHICS.ANIMPOSTFX_IS_RUNNING("ULP_PLAYERWAKEUP") then
              if Game.Self.isAlive() then
                GRAPHICS.ANIMPOSTFX_PLAY("ULP_PLAYERWAKEUP", 5000, false)
                if Game.isOnline() then
                  AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE("SCREAM_PANIC_SHORT", soundName, myPos.x, myPos.y,
                    myPos.z,
                    "SPEECH_PARAMS_FORCE_SHOUTED")
                end
              end
            end
          end
        elseif veh_speed >= 50 then
          die:sleep(200)
          if ENTITY.GET_ENTITY_SPEED(current_vehicle) < veh_speed / 2 then
            VEHICLE.SET_VEHICLE_OUT_OF_CONTROL(current_vehicle, true, false)
            if Game.isOnline() then
              AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE("DEATH_HIGH_MEDIUM", soundName, myPos.x, myPos.y, myPos.z,
                "SPEECH_PARAMS_FORCE_SHOUTED")
            end
            if not ENTITY.IS_ENTITY_A_MISSION_ENTITY(current_vehicle) then
              VEHICLE.SET_VEHICLE_ENGINE_HEALTH(current_vehicle, -4000)
            end
            for _, ped in ipairs(Occupants) do
              if not ENTITY.IS_ENTITY_DEAD(ped, true) then
                ENTITY.SET_ENTITY_HEALTH(ped, 0, 0, 0)
              end
            end
          end
        end
        die:sleep(1000)
      end
    end
  end
end)

-- Planes & Helis
script.register_looped("FLRS", function(flrs) -- Flares
  flrs:yield()
  if flares_forall then
    if Game.Self.isDriving() and (is_plane or is_heli) then
      if PAD.IS_CONTROL_PRESSED(0, 356) and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(current_vehicle) and Game.isOnline() then
        shoot_flares(flrs)
        flrs:sleep(3000)
      end
    end
  end
end)
script.register_looped("MISCPLANES", function(miscp)
  if real_plane_speed and Game.Self.isDriving() and is_plane
  and VEHICLE.GET_VEHICLE_FLIGHT_NOZZLE_POSITION(current_vehicle) ~= 1.0 then
    local jet_increase = 0.21
    local current_speed = ENTITY.GET_ENTITY_SPEED(current_vehicle)
    local jet_rotation  = ENTITY.GET_ENTITY_ROTATION(current_vehicle, 2)
    if jet_rotation.x >= 30 then
      jet_increase = 0.4
    elseif jet_rotation.x >= 60 then
      jet_increase = 0.8
    end
    -- wait for the plane to go over the low altitude speed limit then start increasing its top speed and don't go over 500km/h
    -- 576km/h is fast and safe (the game engine's max). Higher speeds my break the game
    if current_speed >= 73 and current_speed < 160 then
      if PAD.IS_CONTROL_PRESSED(0, 87) and VEHICLE.GET_LANDING_GEAR_STATE(current_vehicle) == 4 then
        VEHICLE.SET_VEHICLE_FORWARD_SPEED(current_vehicle, (current_speed + jet_increase))
      end
    end
  end

  if no_stall and Game.Self.isDriving() and is_plane then
    if VEHICLE.IS_VEHICLE_DRIVEABLE(current_vehicle, true) and VEHICLE.GET_VEHICLE_ENGINE_HEALTH(current_vehicle) > 350
    and Game.Self.get_elevation() > 5.0 and not VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(current_vehicle) then
      VEHICLE.SET_VEHICLE_ENGINE_ON(current_vehicle, true, true, false)
    end
  end

  if Game.Self.isDriving() and (is_plane or is_heli) and Game.Vehicle.hasWeapons()
  and ENTITY.GET_ENTITY_MODEL(current_vehicle) ~= 0x96E24857 then
    local armed, _ = SS.isUsingAirctaftMG()
    if armed then
      local pos = self.get_pos()
      if cannon_triggerbot then
        local rot  = ENTITY.GET_ENTITY_ROTATION(current_vehicle, 2)
        local dir  = Lua_fn.RotToDir(rot)
        local dest = vec3:new(
          pos.x + dir.x * cannon_triggerbot_range,
          pos.y + dir.y * cannon_triggerbot_range,
          pos.z + dir.z * cannon_triggerbot_range
        )
        local hit, endCoords, _ = Game.rayCast(pos, dest, -1, current_vehicle)
        if hit then
          local ped, veh = Game.getClosestPed(endCoords, 50, true), Game.getClosestVehicle(endCoords, 50, self.get_veh())
          if ped ~= 0 then
            shoot_cannon(cannon_enemies_only, ped, ENTITY.GET_ENTITY_COORDS(ped, true))
          end
          if veh ~= 0 then
            shoot_cannon(cannon_enemies_only, veh, ENTITY.GET_ENTITY_COORDS(veh, true))
          end
        end
      end
      if cannon_manual_aim then
        local rot  = CAM.GET_GAMEPLAY_CAM_ROT(0)
        local dir  = Lua_fn.RotToDir(rot)
        local dest = vec3:new(
          pos.x + dir.x * 200,
          pos.y + dir.y * 200,
          pos.z + dir.z * 200
        )
        local hit, endCoords, _ = Game.rayCast(pos, dest, -1, current_vehicle)
        local endPos = hit and endCoords or vec3:new(
          pos.x + dir.x * 1000,
          pos.y + dir.y * 1000,
          pos.z + dir.z * 1000
        )
        local markerDest = hit and endCoords or vec3:new(
          pos.x + dir.x * 50,
          pos.y + dir.y * 50,
          (pos.z + dir.z * 50) + 1
        )
        local r, g, b = cannon_marker_color[1] * 255, cannon_marker_color[2] * 255, cannon_marker_color[3] * 255
        local size = cannon_marker_size
        GRAPHICS.DRAW_MARKER_EX(
          3, markerDest.x, markerDest.y, markerDest.z,
          0, 0, 0, 0, 0, 0, size, size, size, r, g, b, 255,
        ---@diagnostic disable-next-line: param-type-mismatch
          false, true, 1, false, nil, nil, true, true, false
        )
        if is_heli then
          local camHeading = CAM.GET_GAMEPLAY_CAM_RELATIVE_HEADING()
          if camHeading > 15 or camHeading < -15 then
            if ENTITY.GET_ENTITY_ALPHA(current_vehicle) > 150 then
              ENTITY.SET_ENTITY_ALPHA(current_vehicle, 150, false)
            end
          else
            if ENTITY.GET_ENTITY_ALPHA(current_vehicle) < 255 then
              ENTITY.RESET_ENTITY_ALPHA(current_vehicle)
            end
          end
        end
        if PAD.IS_CONTROL_PRESSED(0, 70) then
          shoot_explosive_mg(pos, endPos, 1000, self.get_ped(), 300.0)
        end
        if cannon_triggerbot and hit then
          local ped, veh = Game.getClosestPed(endCoords, 50, true), Game.getClosestVehicle(endCoords, 50, self.get_veh())
          if not cannon_enemies_only then
            if ped ~= 0 or veh ~= 0 then
              local target = ped ~= 0 and ped or veh
              shoot_cannon(false, target, ENTITY.GET_ENTITY_COORDS(target, true)) -- just for the MG sound
              shoot_explosive_mg(pos, endPos, 1000, self.get_ped(), 300.0)
            end
          else
            if ped ~= 0 and Game.Self.isPedEnemy(ped) and not ENTITY.IS_ENTITY_DEAD(ped, false) then
              shoot_cannon(false, ped, ENTITY.GET_ENTITY_COORDS(ped, true))
              shoot_explosive_mg(pos, ENTITY.GET_ENTITY_COORDS(ped, true), 1000, self.get_ped(), 300.0)
            end
            if veh ~= 0 then
              local occupants = Game.Vehicle.getOccupants(veh)
              if #occupants > 0 then
                for _, p in ipairs(occupants) do
                  if not ENTITY.IS_ENTITY_DEAD(p, false) and Game.Self.isPedEnemy(p) then
                    shoot_cannon(false, veh, ENTITY.GET_ENTITY_COORDS(veh, true))
                    shoot_explosive_mg(pos, ENTITY.GET_ENTITY_COORDS(veh, true), 1000, self.get_ped(), 300.0)
                    break
                  end
                end
              end
            end
          end
        end
      end
    else
      if ENTITY.GET_ENTITY_ALPHA(current_vehicle) < 255 then
        ENTITY.RESET_ENTITY_ALPHA(current_vehicle)
      end
    end
  else
    if ENTITY.GET_ENTITY_ALPHA(current_vehicle) < 255 then
      ENTITY.RESET_ENTITY_ALPHA(current_vehicle)
    end
  end
end)
script.register_looped("UBWIN", function()
  if unbreakableWindows and current_vehicle ~= nil and current_vehicle ~= 0 then
    if not ubwindowsToggled then
      VEHICLE.SET_DONT_PROCESS_VEHICLE_GLASS(current_vehicle, true)
      ubwindowsToggled = true
    end
  end
end)
script.register_looped("APKI", function(apki) -- Auto Pilot Keyboard Interrupt
  if autopilot_waypoint or autopilot_objective or autopilot_random then
    if Game.Self.isDriving() then
      for _, ctrl in pairs(flight_controls_T) do
        if PAD.IS_CONTROL_PRESSED(0, ctrl) then
          TASK.CLEAR_PED_TASKS(self.get_ped())
          TASK.CLEAR_PRIMARY_VEHICLE_TASK(current_vehicle)
          gui.show_message("Samurai's Scripts", "Autopilot interrupted! Giving back control to the player.")
          autopilot_waypoint  = false
          autopilot_objective = false
          autopilot_random    = false
          break
        end
      end
    else
      TASK.CLEAR_PED_TASKS(self.get_ped())
      TASK.CLEAR_PRIMARY_VEHICLE_TASK(current_vehicle)
      autopilot_waypoint  = false
      autopilot_objective = false
      autopilot_random    = false
    end
  end
  apki:yield()
end)
script.register_looped("FLTBD", function(script) -- Flatbed Main
  is_using_flatbed  = Game.getEntityModel(current_vehicle) == flatbedModel
  if is_using_flatbed then
    flatbedHeading  = ENTITY.GET_ENTITY_HEADING(current_vehicle)
    flatbedPosition = ENTITY.GET_ENTITY_COORDS(current_vehicle, false)
    flatbedForward  = ENTITY.GET_ENTITY_FORWARD_VECTOR(current_vehicle)
    flatbedBone     = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, "chassis")
    playerPosition  = ENTITY.GET_ENTITY_COORDS(self.get_ped(), true)
    playerForwardX  = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
    playerForwardY  = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
    detectPos       = vec3:new(
      flatbedPosition.x - (flatbedForward.x * 10),
      flatbedPosition.y - (flatbedForward.y * 10),
      flatbedPosition.z
    )
    fb_closestVehicle = Game.getClosestVehicle(detectPos, 5, current_vehicle)
    fb_closestVehicleModel = fb_closestVehicle ~= 0 and Game.getEntityModel(fb_closestVehicle) or 0
    fb_closestVehicleName  = fb_closestVehicleModel ~= 0 and vehicles.get_vehicle_display_name(fb_closestVehicleModel) or ""
    fb_isCar  = VEHICLE.IS_THIS_MODEL_A_CAR(fb_closestVehicleModel)
    fb_isBike = VEHICLE.IS_THIS_MODEL_A_BIKE(fb_closestVehicleModel)
    towable   = towEverything or fb_isCar or fb_isBike or fb_closestVehicleModel == 745926877
    if towed_vehicle == 0 and fb_closestVehicle ~= nil then
      if pressing_fltbd_button and towable and fb_closestVehicleModel ~= flatbedModel then
        script:sleep(200)
        local controlled = false
        if fb_closestVehicle ~= nil and fb_closestVehicle > 0 then
          controlled = entities.take_control_of(fb_closestVehicle, 350)
        end
        if controlled and fb_closestVehicle ~= nil then
          tow_zAxis, tow_yAxis = flatbed_getTowOffset(fb_closestVehicle)
          ENTITY.SET_ENTITY_HEADING(fb_closestVehicleModel, flatbedHeading)
          ENTITY.ATTACH_ENTITY_TO_ENTITY(fb_closestVehicle, current_vehicle, flatbedBone, 0.0, tow_yAxis, tow_zAxis, 0.0, 0.0,
            0.0,
            false, true, true, false, 1, true, 1)
          towed_vehicle = fb_closestVehicle
          script:sleep(200)
        else
          gui.show_error("Samurais Scripts", VEH_CTRL_FAIL_)
        end
      end
      if pressing_fltbd_button and fb_closestVehicle ~= nil and not towable then
        gui.show_message("Samurais Scripts", FLTBD_CARS_ONLY_TXT_)
        script:sleep(400)
      end
      if pressing_fltbd_button and fb_closestVehicleModel == flatbedModel then
        script:sleep(400)
        gui.show_message("Samurais Scripts", FLTBD_NOT_ALLOWED_TXT_)
      end
    else
      towed_vehicleModel = ENTITY.GET_ENTITY_MODEL(towed_vehicle)
      if pressing_fltbd_button then
        script:sleep(200)
        flatbed_detach()
      end
    end
  end
end)
script.register_looped("FLTBDTPM", function() -- Flatbed Tow Pos Marker
  if towPos then
    if is_using_flatbed and towed_vehicle == 0 then
      local flatbedPos = ENTITY.GET_ENTITY_COORDS(current_vehicle, false)
      local flatbedFwd = ENTITY.GET_ENTITY_FORWARD_VECTOR(current_vehicle)
      local detectPos  = vec3:new(
        flatbedPos.x - (flatbedFwd.x * 10),
        flatbedPos.y - (flatbedFwd.y * 10),
        flatbedPos.z
      )
      GRAPHICS.DRAW_MARKER_SPHERE(detectPos.x, detectPos.y, detectPos.z, 2.5, 180, 128, 0, 0.115)
    end
  end
end)
script.register_looped("HFE", function(hfe) -- Handling Flags Editor
  if Game.Self.isOutside() then
    if Game.Self.isDriving() and current_vehicle == last_vehicle
        and not is_plane and not is_heli and not is_boat
        and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(current_vehicle) then
      if noEngineBraking then
        if not engine_brake_disabled then
          SS.setHandlingFlag(HF._FREEWHEEL_NO_GAS, true)
          hfe:sleep(100)
        end
      end

      if kersBoost then
        if not kers_boost_enabled and not VEHICLE.GET_VEHICLE_HAS_KERS(current_vehicle) then
          SS.setHandlingFlag(HF._HAS_KERS, true)
          VEHICLE.SET_VEHICLE_KERS_ALLOWED(current_vehicle, true)
          hfe:sleep(100)
        end
      end

      if offroaderx2 then
        if not offroader_enabled then
          SS.setHandlingFlag(HF._OFFROAD_ABILITIES_X2, true)
          hfe:sleep(100)
        end
      end

      if rallyTires then
        if not rally_tires_enabled then
          SS.setHandlingFlag(HF._HAS_RALLY_TYRES, true)
          hfe:sleep(100)
        end
      end

      if is_bike or is_quad then
        if noTractionCtrl then
          if not traction_ctrl_disabled then
            SS.setHandlingFlag(HF._FORCE_NO_TC_OR_SC, true)
            hfe:sleep(100)
          end
        end

        if easyWheelie then
          if not easy_wheelie_enabled then
            SS.setHandlingFlag(HF._LOW_SPEED_WHEELIES, true)
            hfe:sleep(100)
          end
        end
      end

      -- the ones below do work but the steering is not rendered.
      -- if rwSteering then
      --   if not rw_steering_enabled then
      --     SS.setHandlingFlag(HF._STEER_REARWHEELS, true)
      --     hfe:sleep(100)
      --   end
      -- else
      --   if rw_steering_enabled then
      --     SS.setHandlingFlag(HF._STEER_REARWHEELS, false)
      --     hfe:sleep(100)
      --   end
      -- end

      -- if awSteering then
      --   if not aw_steering_enabled then
      --     SS.setHandlingFlag(HF._STEER_ALL_WHEELS, true)
      --     hfe:sleep(100)
      --   end
      -- else
      --   if aw_steering_enabled then
      --     SS.setHandlingFlag(HF._STEER_ALL_WHEELS, false)
      --     hfe:sleep(100)
      --   end
      -- end

      -- if handbrakeSteering then
      --   if not hb_steering_enabled then
      --     SS.setHandlingFlag(HF._HANDBRAKE_REARWHEELSTEER, true)
      --     hfe:sleep(100)
      --   end
      -- else
      --   if hb_steering_enabled then
      --     SS.setHandlingFlag(HF._HANDBRAKE_REARWHEELSTEER, false)
      --     hfe:sleep(100)
      --   end
      -- end
    end
  end
end)
script.register_looped("VCO", function() -- Vehicle Creator Organizer
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
script.register_looped("PG", function(pg) -- Ped Grabber
  if pedGrabber and not vehicleGrabber and not HUD.IS_MP_TEXT_CHAT_TYPING() and not is_playing_anim
      and not is_playing_scenario and not isCrouched and not is_handsUp and not is_hiding then
    if Game.Self.isOnFoot() and not gui.is_open() and not WEAPON.IS_PED_ARMED(self.get_ped(), 7) then
      local nearestPed = Game.getClosestPed(self.get_ped(), 10, true)
      local myGroup    = PED.GET_PED_GROUP_INDEX(self.get_ped())
      if not ped_grabbed and nearestPed ~= 0 then
        if PED.IS_PED_ON_FOOT(nearestPed) and not PED.IS_PED_A_PLAYER(nearestPed) and not PED.IS_PED_GROUP_MEMBER(nearestPed, myGroup) then
          if (PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 257)) and not Game.Self.isBrowsingApps() then
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
        PED.FORCE_PED_MOTION_STATE(attached_ped, 0x0EC17E58, false, 0, false)
        if not ENTITY.IS_ENTITY_PLAYING_ANIM(self.get_ped(), "mp_missheist_countrybank@lift_hands", "lift_hands_in_air_outro", 3) then
          playHandsUp()
        end
        if PED.IS_PED_USING_ACTION_MODE(self.get_ped()) then
          repeat
            pg:sleep(100)
          until not PED.IS_PED_USING_ACTION_MODE(self.get_ped())
          playHandsUp()
        end
        if PED.IS_PED_RAGDOLL(self.get_ped()) or Game.Self.isSwimming() or not Game.Self.isAlive() then
          ENTITY.FREEZE_ENTITY_POSITION(attached_ped, false)
          ENTITY.DETACH_ENTITY(attached_ped, true, true)
          TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(attached_ped, false)
          PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(attached_ped, false)
          PED.SET_PED_TO_RAGDOLL(attached_ped, 1500, 0, 0, false, false, false)
          TASK.CLEAR_PED_TASKS(self.get_ped())
          PED.SET_PED_CAN_SWITCH_WEAPON(self.get_ped(), true)
          attached_ped = 0
          ped_grabbed  = false
        end
        if PAD.IS_DISABLED_CONTROL_PRESSED(0, 25) then
          if PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 257) then
            local myFwdX = Game.getForwardX(self.get_ped())
            local myFwdY = Game.getForwardY(self.get_ped())
            ENTITY.FREEZE_ENTITY_POSITION(attached_ped, false)
            ENTITY.DETACH_ENTITY(attached_ped, true, true)
            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(attached_ped, false)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(attached_ped, false)
            PED.SET_PED_TO_RAGDOLL(attached_ped, 1500, 0, 0, false, false, false)
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
end)
script.register_looped("VG", function(vg) -- Vehicle Grabber
  if vehicleGrabber and not pedGrabber and not HUD.IS_MP_TEXT_CHAT_TYPING() and not is_playing_anim
      and not is_playing_scenario and not isCrouched and not is_handsUp and not is_hiding then
    if Game.Self.isOnFoot() and not gui.is_open() and not WEAPON.IS_PED_ARMED(self.get_ped(), 7) then
      local nearestVeh = Game.getClosestVehicle(self.get_ped(), 10)
      if not vehicle_grabbed and nearestVeh ~= 0 then
        if (PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 257))
            and not Game.Self.isBrowsingApps() then
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
        if PED.IS_PED_USING_ACTION_MODE(self.get_ped()) then
          repeat
            vg:sleep(100)
          until not PED.IS_PED_USING_ACTION_MODE(self.get_ped())
          playHandsUp()
        end
        if PED.IS_PED_RAGDOLL(self.get_ped()) or Game.Self.isSwimming() or not Game.Self.isAlive() then
          ENTITY.DETACH_ENTITY(grabbed_veh, true, true)
          TASK.CLEAR_PED_TASKS(self.get_ped())
          PED.SET_PED_CAN_SWITCH_WEAPON(self.get_ped(), true)
          grabbed_veh     = 0
          vehicle_grabbed = false
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
end)
script.register_looped("RWNPC", function(cp) -- Ride With NPCs
  if carpool then
    stop_searching = PED.IS_PED_SITTING_IN_ANY_VEHICLE(self.get_ped()) and true or false
    if not stop_searching then
      nearestVeh = Game.getClosestVehicle(self.get_ped(), 10)
    end
    local trying_to_enter = PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(self.get_ped())
    if trying_to_enter ~= 0 and trying_to_enter == nearestVeh and VEHICLE.ARE_ANY_VEHICLE_SEATS_FREE(trying_to_enter) then
      local Occupants = Game.Vehicle.getOccupants(trying_to_enter)
      for _, occupant in ipairs(Occupants) do
        if occupant ~= nil and ENTITY.IS_ENTITY_A_PED(occupant) and not PED.IS_PED_A_PLAYER(occupant) then
          thisVeh = trying_to_enter
          PED.SET_PED_CONFIG_FLAG(occupant, 251, true)
          PED.SET_PED_CONFIG_FLAG(occupant, 255, true)
          PED.SET_PED_CONFIG_FLAG(occupant, 398, true)
          PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(occupant, true)
        end
      end
    end
    if PED.IS_PED_SITTING_IN_VEHICLE(self.get_ped(), thisVeh) then
      is_carpooling          = true
      local Occupants        = Game.Vehicle.getOccupants(thisVeh)
      local numPassengers    = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(thisVeh)
      npcDriver              = VEHICLE.GET_PED_IN_VEHICLE_SEAT(thisVeh, -1, true)
      npc_veh_has_conv_roof  = VEHICLE.IS_VEHICLE_A_CONVERTIBLE(thisVeh, false)
      show_npc_veh_seat_ctrl = numPassengers > 1
      stop_searching         = true
      show_npc_veh_ui        = true
      repeat
        npc_veh_radio_on = AUDIO.IS_VEHICLE_RADIO_ON(thisVeh)
        npc_veh_speed    = ENTITY.GET_ENTITY_SPEED(thisVeh)
        if npc_veh_has_conv_roof then
          npc_veh_roof_state = VEHICLE.GET_CONVERTIBLE_ROOF_STATE(thisVeh)
        end
        cp:sleep(100)
      until not PED.IS_PED_SITTING_IN_VEHICLE(self.get_ped(), thisVeh) or not PED.IS_PED_SITTING_IN_VEHICLE(npcDriver, thisVeh)
      for _, occupant in ipairs(Occupants) do
        if occupant ~= nil and ENTITY.IS_ENTITY_A_PED(occupant) and not PED.IS_PED_A_PLAYER(occupant) then
          PED.SET_PED_CONFIG_FLAG(occupant, 251, false)
          PED.SET_PED_CONFIG_FLAG(occupant, 255, false)
          PED.SET_PED_CONFIG_FLAG(occupant, 398, false)
          PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(occupant, false)
        end
      end
      is_carpooling          = false
      stop_searching         = false
      show_npc_veh_ui        = false
      show_npc_veh_seat_ctrl = false
      thisVeh                = 0
      npcDriver              = 0
      npcDriveTask           = ""
    else
      is_carpooling = false
      if show_npc_veh_ui then
        show_npc_veh_ui = false
      end
      if show_npc_veh_seat_ctrl then
        show_npc_veh_seat_ctrl = false
      end
    end
  end
end)
script.register_looped("CPEF", function(cpef) -- carpool exit fix
  if is_carpooling then
    if PAD.IS_DISABLED_CONTROL_PRESSED(0, 75) then
      if not VEHICLE.IS_VEHICLE_STOPPED(thisVeh) then
        TASK.TASK_VEHICLE_TEMP_ACTION(npcDriver, thisVeh, 1, 3000)
        repeat
          cpef:sleep(10)
        until VEHICLE.IS_VEHICLE_STOPPED(thisVeh)
      end
      TASK.TASK_LEAVE_VEHICLE(self.get_ped(), thisVeh, 0)
    end
  end
end)
script.register_looped("WBNDS", function() -- World Bounds
  if extend_world then
    if not world_extended then
      Game.World.extendBounds(true)
      world_extended = true
    end
  end
end)
script.register_looped("PSEATS", function(pseats) -- Public Seats
  if public_seats and Game.Self.isOutside() and Game.Self.isOnFoot() and not NETWORK.NETWORK_IS_ACTIVITY_SESSION() and not is_sitting then
    local near_seat, seat, x_offset, z_offset = SS.isNearPublicSeat()
    if near_seat and Game.Self.isAlive() and not PLAYER.IS_PLAYER_FREE_AIMING(self.get_id()) and not TASK.PED_HAS_USE_SCENARIO_TASK(self.get_ped())
        and not is_playing_anim and not is_playing_scenario and not ped_grabbed and not vehicle_grabbed and not is_playing_amb_scenario
        and not is_handsUp and not isCrouched and not ped_grabbed and not vehicle_grabbed and not is_hiding then
      Game.showButtonPrompt("Press ~INPUT_PICKUP~ to sit down")
      if PAD.IS_CONTROL_PRESSED(0, 38) then
        if Game.requestAnimDict("timetable@ron@ig_3_couch") then
          if ENTITY.DOES_ENTITY_EXIST(seat) then
            ENTITY.FREEZE_ENTITY_POSITION(seat, true)
            TASK.TASK_TURN_PED_TO_FACE_ENTITY(self.get_ped(), seat, 100)
            pseats:sleep(150)
            TASK.TASK_PLAY_ANIM(self.get_ped(), "timetable@ron@ig_3_couch", "base", 1.69, 4.0, -1, 33, 1.0, false, false,
              false)
            local bone_index = PED.GET_PED_BONE_INDEX(self.get_ped(), 0)
            ENTITY.ATTACH_ENTITY_TO_ENTITY(self.get_ped(), seat, bone_index, x_offset, -0.6, z_offset, 0.0, 0.0, 180.0,
              false,
              false, false, false, 20, true, 1)
            pseats:sleep(1000)
            is_sitting, thisSeat = true, seat
          end
        end
      end
    else
      pseats:sleep(1000)
    end
  end
  if is_sitting then
    if PED.IS_PED_IN_MELEE_COMBAT(self.get_ped()) then
      standUp()
    end
    if PED.IS_PED_RAGDOLL(self.get_ped()) then
      standUp()
    end
    if PLAYER.IS_PLAYER_FREE_AIMING(self.get_id()) then
      standUp()
    end
    if not Game.Self.isAlive() then
      if ENTITY.DOES_ENTITY_EXIST(thisSeat) then
        ENTITY.FREEZE_ENTITY_POSITION(thisSeat, false)
        if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(self.get_ped(), thisSeat) then
          ENTITY.DETACH_ENTITY(self.get_ped(), true, true)
        end
        thisSeat = 0
      end
      is_sitting = false
    end
    if not ENTITY.IS_ENTITY_PLAYING_ANIM(self.get_ped(), "timetable@ron@ig_3_couch", "base", 3) then
      if ENTITY.DOES_ENTITY_EXIST(thisSeat) then
        ENTITY.FREEZE_ENTITY_POSITION(thisSeat, false)
        if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(self.get_ped(), thisSeat) then
          ENTITY.DETACH_ENTITY(self.get_ped(), true, true)
        end
        thisSeat = 0
      end
      is_sitting = false
    else
      Game.showButtonPrompt("Press ~INPUT_PICKUP~ to get up")
      if PAD.IS_CONTROL_PRESSED(0, 38) then
        ENTITY.DETACH_ENTITY(self.get_ped(), true, false)
        TASK.STOP_ANIM_TASK(self.get_ped(), "timetable@ron@ig_3_couch", "base", -2.69)
        if ENTITY.DOES_ENTITY_EXIST(thisSeat) then
          ENTITY.FREEZE_ENTITY_POSITION(thisSeat, false)
        end
        pseats:sleep(1000)
        is_sitting, thisSeat = false, 0
      end
    end
  end
end)
-- ambient scenarios
script.register_looped("AMBSCN", function(ambscn)
  if ambient_scenarios and Game.Self.isOutside() and Game.Self.isOnFoot() then
    local myPos = self.get_pos()
    local amb_scenario_exists, amb_scenario_name = Game.DoesHumanScenarioExistInArea(myPos, 2, true)
    local force_start = PAD.IS_CONTROL_PRESSED(0, 21)
    if amb_scenario_exists and not is_playing_amb_scenario and not ped_grabbed
        and not vehicle_grabbed and not is_sitting and not isCrouched
        and not script.is_active("CELLPHONE_FLASHHAND") then
      Disable_E()
      if ambient_scenario_prompt then
        Game.showButtonPrompt(
          ("Press ~INPUT_PICKUP~ to play the nearest scenario (%s)."):format(amb_scenario_name)
        )
      end
      local UseNearestScenarioCall = force_start and TASK.TASK_USE_NEAREST_SCENARIO_TO_COORD_WARP or
      TASK.TASK_USE_NEAREST_SCENARIO_TO_COORD
      if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 38) then
        if is_playing_anim then
          cleanup(ambscn)
          is_playing_anim = false
        end
        if is_handsUp then
          TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
          is_handsUp = false
        end
        if not PED.GET_PED_CONFIG_FLAG(self.get_ped(), 414, true) then
          PED.SET_PED_CONFIG_FLAG(self.get_ped(), 414, true)
        end
        UseNearestScenarioCall(self.get_ped(), myPos.x, myPos.y, myPos.z, 2, -1)
        ambscn:sleep(1500)
        gui.show_message("Samurai's Scripts",
          "If the ambient scenario glitches or fails to start, you can hold Left Shift and press E to force start/stop it.")
        is_playing_amb_scenario = true
      end
    end
    if is_playing_amb_scenario then
      if not Game.Self.isAlive() or PED.IS_PED_RAGDOLL(self.get_ped()) then
        is_playing_amb_scenario = false
      end
      Disable_E()
      if ambient_scenario_prompt then
        Game.showButtonPrompt("Press ~INPUT_PICKUP~ to stop.")
      end
      if PAD.IS_CONTROL_PRESSED(0, 21) then
        if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 38) then
          TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
          is_playing_amb_scenario = false
          ambscn:sleep(1000)
        end
      else
        if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 38) then
          stopScenario(self.get_ped(), ambscn)
          is_playing_amb_scenario = false
          ambscn:sleep(1000)
        end
      end
    end
  end
end)
-- object spawner
script.register_looped("PREVIEW", function(preview)
  if previewLoop and gui.is_open() then
    local coords = self.get_pos()
    local fwdVec = Game.getForwardVec(self.get_ped())
    local currentHeading = ENTITY.GET_ENTITY_HEADING(previewEntity)
    if currentObjectPreview ~= previewEntity then
      ENTITY.DELETE_ENTITY(previewEntity)
      previewStarted = false
    end
    if isChanged then
      ENTITY.DELETE_ENTITY(previewEntity)
      previewStarted = false
    end
    if not ENTITY.IS_ENTITY_DEAD(self.get_ped(), false) then
      while not STREAMING.HAS_MODEL_LOADED(propHash) do
        STREAMING.REQUEST_MODEL(propHash)
        coroutine.yield()
      end
      if not previewStarted then
        previewEntity = OBJECT.CREATE_OBJECT(
          propHash, coords.x + fwdVec.x * 5, coords.y + fwdVec.y * 5, coords.z, false, false, false
        )
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
script.register_looped("EM", function() -- Edit Mode
  if spawned_props[1] ~= nil then
    if edit_mode and not ENTITY.IS_ENTITY_ATTACHED(selectedObject.entity) then
      local current_coords   = ENTITY.GET_ENTITY_COORDS(selectedObject.entity, true)
      local current_rotation = ENTITY.GET_ENTITY_ROTATION(selectedObject.entity, 2)
      if activeX then
        ENTITY.SET_ENTITY_COORDS(selectedObject.entity, current_coords.x + spawnDistance.x, current_coords.y,
          current_coords.z,
          false, false, false, false)
      end
      if activeY then
        ENTITY.SET_ENTITY_COORDS(selectedObject.entity, current_coords.x, current_coords.y + spawnDistance.y,
          current_coords.z,
          false, false, false, false)
      end
      if activeZ then
        ENTITY.SET_ENTITY_COORDS(selectedObject.entity, current_coords.x, current_coords.y,
          current_coords.z + spawnDistance.z,
          false, false, false, false)
      end
      if rotX then
        ENTITY.SET_ENTITY_ROTATION(selectedObject.entity, current_rotation.x + spawnRot.x, current_rotation.y,
          current_rotation.z, 2, true)
      end
      if rotY then
        ENTITY.SET_ENTITY_ROTATION(selectedObject.entity, current_rotation.x, current_rotation.y + spawnRot.y,
          current_rotation.z, 2, true)
      end
      if rotZ then
        ENTITY.SET_ENTITY_ROTATION(selectedObject.entity, current_rotation.x, current_rotation.y,
          current_rotation.z + spawnRot.z, 2, true)
      end
    end
    for k, v in ipairs(spawned_props) do
      if not ENTITY.DOES_ENTITY_EXIST(v.entity) then
        table.remove(spawned_props, k)
      end
    end
  end
  if attached_props[1] ~= nil then
    for i, v in ipairs(attached_props) do
      if not ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(v.entity, self.get_ped()) then
        table.remove(attached_props, i)
      end
    end
  end
  if vehicle_attachments[1] ~= nil then
    for i, v in ipairs(vehicle_attachments) do
      if not ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(v.entity, self.get_veh()) then
        table.remove(vehicle_attachments, i)
      end
    end
  end
  if spawned_persist_T[1] ~= nil then
    for k, v in ipairs(spawned_persist_T) do
      if not ENTITY.DOES_ENTITY_EXIST(v) then
        table.remove(spawned_persist_T, k)
      end
    end
  end
  if vehAttachments[1] ~= nil then
    for index, entity in ipairs(vehAttachments) do
      if not ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(entity, current_vehicle) then
        table.remove(vehAttachments, index)
      end
    end
  end
  if selfAttachments[1] ~= nil then
    for k, v in ipairs(selfAttachments) do
      if not ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(v.entity, self.get_ped()) then
        table.remove(selfAttachments, k)
      end
    end
  end
end)

script.register_looped("KDRV", function() -- Kamikaze Drivers
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
              if VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(ped_veh) and not ENTITY.IS_ENTITY_DEAD(ped, false) then
                VEHICLE.SET_VEHICLE_BRAKE(ped_veh, false)
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(ped_veh, (ENTITY.GET_ENTITY_SPEED(ped_veh) + 0.7))
              end
            end
          end
        end
      end
    end
  end
end)

script.register_looped("PE", function() -- Public Enemy
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
          for _, cflag in ipairs(pe_config_flags_T) do
            if not PED.GET_PED_CONFIG_FLAG(ped, cflag.id, cflag.bool) then
              PED.SET_PED_CONFIG_FLAG(ped, cflag.id, cflag.bool)
            end
          end
          PED.SET_PED_RESET_FLAG(ped, 440, true) -- PRF_IgnoreCombatManager so they can all gang up on you and beat your ass without waiting for their turns
          TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
          PLAYER.SET_POLICE_IGNORE_PLAYER(self.get_id(), true)
          PLAYER.SET_MAX_WANTED_LEVEL(0)
          TASK.TASK_COMBAT_PED(ped, self.get_ped(), 0, 16)
        end
      end
    end
  end
end)

---online

-- Casino Pacino
script.register_looped("CASINO", function(script)
  if Game.isOnline() then
    if force_poker_cards then
      local player_id = PLAYER.PLAYER_ID()
      if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("three_card_poker")) ~= 0 then
        while NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", -1, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 0, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 1, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 2, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 3, 0) ~= player_id do
          network.force_script_host("three_card_poker")
          gui.show_message("Samuai's Scripts", CP_TCC_CTRL_NOTIF_) -- If you see this spammed, someone if fighting you for control.
          script:sleep(500)
        end
        local players_current_table = locals.get_int("three_card_poker",
          three_card_poker_table + 1 + (player_id * three_card_poker_table_size) + 2) -- The Player's current table he is sitting at.
        if (players_current_table ~= -1) then                                         -- If the player is sitting at a poker table
          local player_0_card_1 = locals.get_int("three_card_poker",
            (three_card_poker_cards) + (three_card_poker_current_deck) +
            (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (1) + (0 * 3))
          local player_0_card_2 = locals.get_int("three_card_poker",
            (three_card_poker_cards) + (three_card_poker_current_deck) +
            (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (2) + (0 * 3))
          local player_0_card_3 = locals.get_int("three_card_poker",
            (three_card_poker_cards) + (three_card_poker_current_deck) +
            (1 + (players_current_table * three_card_poker_deck_size)) + (2) + (3) + (0 * 3))
          if player_0_card_1 ~= 50 or player_0_card_2 ~= 51 or player_0_card_3 ~= 52 then --Check if we need to overwrite the deck.
            local total_players = 0
            for player_iter = 0, 31, 1 do
              local player_table = locals.get_int("three_card_poker",
                three_card_poker_table + 1 + (player_iter * three_card_poker_table_size) + 2)
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
      local blackjack_table = locals.get_int("blackjack",
        blackjack_table_players + 1 + (PLAYER.PLAYER_ID() * blackjack_table_players_size) + 4)                             --The Player's current table he is sitting at.
      if blackjack_table ~= -1 then
        dealers_card     = locals.get_int("blackjack", blackjack_cards + blackjack_decks + 1 + (blackjack_table * 13) + 1) --Dealer's facedown card.
        dealers_card_str = get_cardname_from_index(dealers_card)
      else
        dealers_card_str = CP_NOT_PLAYING_BJ_TXT_
      end
    else
      dealers_card_str = CP_NOT_IN_CASINO_TXT_
    end

    if force_roulette_wheel then
      local player_id = PLAYER.PLAYER_ID()
      if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("casinoroulette")) ~= 0 then
        while NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", -1, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 0, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 1, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 2, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 3, 0) ~= player_id do
          network.force_script_host("casinoroulette")
          gui.show_message("Samurai's Scripts", CP_ROULETTE_CTRL_NOTIF_) --If you see this spammed, someone if fighting you for control.
          script:sleep(500)
        end
        for tabler_iter = 0, 6, 1 do
          locals.set_int("casinoroulette",
            (roulette_master_table) + (roulette_outcomes_table) + (roulette_ball_table) + (tabler_iter), 18)
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
        if slotstate & (1 << 0) == 1 then                                          --The user is sitting at a slot machine.
          local chips = stats.get_int('MPX_CASINO_CHIPS')
          local chip_cap = autoplay_chips_cap
          if (autoplay_cap and chips < chip_cap) or not autoplay_cap then
            if (slotstate & (1 << 24) == 0) then --The slot machine is not currently spinning.
              script:yield()                     -- Wait for the previous spin to clean up, if we just came from a spin.
              slotstate = slotstate | (1 << 3)   -- Bitwise set the 3rd bit (begin playing)
              locals.set_int("casino_slots", slots_slot_machine_state, slotstate)
              script:sleep(500)                  --If we rewrite the begin playing bit again, the machine will get stuck.
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
      local time_delta           = os.time() -
          stats.get_int("MPPLY_CASINO_CHIPS_WONTIM") -- "I've won the jackpot, and it doesn't make me feel bad." ~Casino Pacino (He only cares about winners)
      local minutes_left         = (cooldown_time - time_delta) / 60
      local chipswon_gd          = stats.get_int("MPPLY_CASINO_CHIPS_WON_GD")
      local max_chip_wins        = tunables.get_int("VC_CASINO_CHIP_MAX_WIN_DAILY")
      casino_cooldown_update_str = chipswon_gd >= max_chip_wins and
      string.format("Cooldown expires in approximately: %.2f minute(s).", minutes_left) or "Off Cooldown"
    end
    if fm_mission_controller_cart_autograb then
      if locals.get_int("fm_mission_controller", fm_mission_controller_cart_grab) == 3 then
        locals.set_int("fm_mission_controller", fm_mission_controller_cart_grab, 4)
      elseif locals.get_int("fm_mission_controller", fm_mission_controller_cart_grab) == 4 then
        locals.set_float("fm_mission_controller", fm_mission_controller_cart_grab + fm_mission_controller_cart_grab_speed,
          2)
      end
    end
  end
end)

script.register_looped("CDK", function() -- Cooldown Killer
  if Game.isOnline() and TARGET_BUILD == CURRENT_BUILD and not script.is_active("maintransition") then
    if mc_work_cd then
      if tunables.get_int("BIKER_CLUB_WORK_COOLDOWN_GLOBAL") > 0 then
        tunables.set_int("BIKER_CLUB_WORK_COOLDOWN_GLOBAL", 0)
      end
    end
    if hangar_cd then
      if tunables.get_int("SMUG_STEAL_EASY_COOLDOWN_TIMER") > 0 then
        tunables.set_int("SMUG_STEAL_EASY_COOLDOWN_TIMER", 0)
      end
      if tunables.get_int("SMUG_STEAL_MED_COOLDOWN_TIMER") > 0 then
        tunables.set_int("SMUG_STEAL_MED_COOLDOWN_TIMER", 0)
      end
      if tunables.get_int("SMUG_STEAL_HARD_COOLDOWN_TIMER") > 0 then
        tunables.set_int("SMUG_STEAL_HARD_COOLDOWN_TIMER", 0)
      end
    end
    if nc_management_cd then
      if tunables.get_int("BB_CLUB_MANAGEMENT_CLUB_MANAGEMENT_MISSION_COOLDOWN") > 0 then
        tunables.set_int("BB_CLUB_MANAGEMENT_CLUB_MANAGEMENT_MISSION_COOLDOWN", 0)
      end
    end
    if nc_vip_mission_chance then
      if tunables.get_int("NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT") > 0 then
        tunables.set_int("NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT", 0)
      end
    else
      if tunables.get_int("NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT") == 0 then
        tunables.set_int("NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT", 50)
      end
    end
    if security_missions_cd then
      if tunables.get_int("FIXER_SECURITY_CONTRACT_COOLDOWN_TIME") > 0 then
        tunables.set_int("FIXER_SECURITY_CONTRACT_COOLDOWN_TIME", 0)
      end
    end
    if ie_vehicle_steal_cd then
      if tunables.get_int("IMPEXP_STEAL_COOLDOWN") > 0 then
        tunables.set_int("IMPEXP_STEAL_COOLDOWN", 0)
      end
    end
    if ie_vehicle_sell_cd then
      if tunables.get_int("IMPEXP_SELL_COOLDOWN") > 0 then
        tunables.set_int("IMPEXP_SELL_COOLDOWN", 0)
      end
      if tunables.get_int("IMPEXP_SELL_1_CAR_COOLDOWN") > 0 then
        tunables.set_int("IMPEXP_SELL_1_CAR_COOLDOWN", 0)
      end
      if tunables.get_int("IMPEXP_SELL_2_CAR_COOLDOWN") > 0 then
        tunables.set_int("IMPEXP_SELL_2_CAR_COOLDOWN", 0)
      end
      if tunables.get_int("IMPEXP_SELL_3_CAR_COOLDOWN") > 0 then
        tunables.set_int("IMPEXP_SELL_3_CAR_COOLDOWN", 0)
      end
      if tunables.get_int("IMPEXP_SELL_4_CAR_COOLDOWN") > 0 then
        tunables.set_int("IMPEXP_SELL_4_CAR_COOLDOWN", 0)
      end
    end
    if ceo_crate_buy_cd then
      if tunables.get_int("EXEC_BUY_COOLDOWN") > 0 then
        tunables.set_int("EXEC_BUY_COOLDOWN", 0)
      end
      if tunables.get_int("EXEC_BUY_FAIL_COOLDOWN") > 0 then
        tunables.set_int("EXEC_BUY_FAIL_COOLDOWN", 0)
      end
    end
    if ceo_crate_sell_cd then
      if tunables.get_int("EXEC_SELL_COOLDOWN") > 0 then
        tunables.set_int("EXEC_SELL_COOLDOWN", 0)
      end
      if tunables.get_int("EXEC_SELL_FAIL_COOLDOWN") > 0 then
        tunables.set_int("EXEC_SELL_FAIL_COOLDOWN", 0)
      end
    end

    if dax_work_cd then
      if stats.get_int("MPX_XM22JUGGALOWORKCDTIMER") > 0 then
        stats.set_int("MPX_XM22JUGGALOWORKCDTIMER", 0)
      end
    end

    if garment_rob_cd then
      if stats.get_int("MPX_HACKER24_ROBBERY_CD") > 0 then
        stats.set_int("MPX_HACKER24_ROBBERY_CD", 0)
      end
    end
  end
end)

script.register_looped("ISALE", function(isale)
  for sn in pairs(supported_sale_scripts) do
    if script.is_active(sn) then
      script_name, scr_is_running = sn, true
      for _, v in ipairs(simplified_scr_names) do
        if v.scr == script_name then
          simplified_scr_name = v.sn
          break
        end
      end
      break
    else
      script_name, simplified_scr_name, scr_is_running = "None", "None", false
    end
  end
  if scr_is_running and abhubScriptHandle ~= 0 then
    for _, scr in pairs(should_terminate_scripts) do
      if script.is_active(scr) then -- was triggered from the mct
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 202, 1.0)
        isale:sleep(200)
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 202, 1.0)
        break
      end
    end
    if (CAM.IS_SCREEN_FADING_OUT() or CAM.IS_SCREEN_FADED_OUT()) then
      isale:sleep(6969)
      if CAM.IS_SCREEN_FADED_OUT() and not CAM.IS_SCREEN_FADING_IN() then -- step bro I'm stuck
        CAM.DO_SCREEN_FADE_IN(100)
      end
    end
  end
  isale:sleep(1000)
end)
script.register_looped("AUTOSELL", function(as)
  if autosell and scr_is_running and not autosell_was_triggered and not CAM.IS_SCREEN_FADED_OUT() then
    autosell_was_triggered = true
    gui.show_message("Samurai's Scripts", "Auto-Sell will start in 20 seconds.")
    as:sleep(20000)
    if AUDIO.IS_MOBILE_PHONE_CALL_ONGOING() then
      repeat
        as:sleep(100)
      until not AUDIO.IS_MOBILE_PHONE_CALL_ONGOING()
    end
    SS.FinishSale(script_name)
  end

  if autosell_was_triggered then
    repeat
      as:sleep(100)
    until not scr_is_running -- most scripts take a few seconds to terminate.
    autosell_was_triggered = false
  end
end)

---MISC
script.register_looped("DFM", function() -- Disable Flight Music
  if disableFlightMusic then
    if not flight_music_off then
      AUDIO.SET_AUDIO_FLAG("DisableFlightMusic", true)
      flight_music_off = true
    end
  end
end)

script.register_looped("REOPT", function(ro) -- Remote Options. Probably better to rewrite these to something similar to `RegisterCommand()` but I'm too lazy.
  if not is_typing and not is_setting_hotkeys and not Game.Self.isBrowsingApps()
      and not HUD.IS_MP_TEXT_CHAT_TYPING() and not HUD.IS_PAUSE_MENU_ACTIVE() then
    if SS.isKeyJustPressed(keybinds.autokill.code) then
      UI.widgetSound(autoKill and "Cancel" or "Notif")
      gui.show_message("Samurai's Scripts", ("Auto-Kill Enemies %s."):format(autoKill and "disabled" or "enabled"))
      autoKill = not autoKill
      CFG.save("autoKill", autoKill)
      ro:sleep(200)
    end

    if SS.isKeyJustPressed(keybinds.enemiesFlee.code) then
      UI.widgetSound(runaway and "Cancel" or "Notif")
      gui.show_message("Samurai's Scripts", ("Enemies Flee %s."):format(runaway and "disabled" or "enabled"))
      runaway = not runaway
      CFG.save("runaway", runaway)
      ro:sleep(200)
    end

    if SS.isKeyJustPressed(keybinds.missl_def.code) then
      UI.widgetSound(missiledefense and "Cancel" or "Notif")
      gui.show_message("Samurai's Scripts", ("Missile Defence %s."):format(missiledefense and "disabled" or "enabled"))
      missiledefense = not missiledefense
      CFG.save("missiledefense", missiledefense)
      ro:sleep(200)
    end

    if PLAYER.IS_PLAYER_FREE_AIMING(self.get_id()) and pressing_laser_button then
      AUDIO.PLAY_SOUND_FRONTEND(-1, "Target_Counter_Tick", "DLC_SM_Generic_Mission_Sounds", false)
      gui.show_message("Samurai's Scripts", ("Laser Sights %s."):format(laserSight and "disabled" or "enabled"))
      laserSight = not laserSight
      CFG.save("laserSight", laserSight)
      ro:sleep(200)
    end

    if SS.isKeyJustPressed(keybinds.commands.code) and not cmd_ui_is_open and not gui.is_open() and not
    HUD.IS_MP_TEXT_CHAT_TYPING() and not HUD.IS_PAUSE_MENU_ACTIVE() then
      should_draw_cmd_ui, cmd_ui_is_open = true, true
      gui.override_mouse(true)
    end
    if SS.isKeyJustPressed(0x1B) and cmd_ui_is_open then -- ESC
      should_draw_cmd_ui, cmd_ui_is_open = false, false
      gui.override_mouse(false)
    end
  end
  CommandExecutor()
end)

-- Business Autofill
script.register_looped("HSUPP", function(hgl)
  if hangarLoop then
    if hangarOwned == nil then
      hangarOwned = stats.get_int("MPX_HANGAR_OWNED") ~= 0
    end
    if hangarOwned then
      if stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL") == 50 then
        UI.widgetSound("Error")
        gui.show_warning("Samurai's Scripts", "Your Hangar is already full! Option has been disabled.")
        hangarLoop = false
      else
        repeat
          stats.set_bool_masked("MPX_DLC22022PSTAT_BOOL3", true, 9)
          hangarSupplies = stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL")
          hgl:sleep(supply_autofill_delay)
        until hangarSupplies == 50 or hangarLoop == false
        if hangarLoop then
          hangarLoop = false
        end
      end
    else
      gui.show_warning("Samurai's Scripts", "You don't seem to own a hangar. Option has been disabled.")
      hangarLoop = false
    end
  end
end)

script.register_looped("WH1SUPP", function(wh_1)
  if wh1_loop then
    if whouse_1_owned == nil then
      whouse_1_owned = (stats.get_int("MPX_PROP_WHOUSE_SLOT0") - 1) >= 0
    end
    if whouse_1_owned then
      if whouse1.name == "" then
        SS.getCEOwhouseInfo(whouse1)
      end
      if stats.get_int("MPX_CONTOTALFORWHOUSE0") == whouse1.max then
        UI.widgetSound("Error")
        gui.show_warning("Samurai's Scripts", "Warehouse N°1 is already full! Option has been disabled.")
        wh1_loop = false
      else
        repeat
          stats.set_bool_masked("MPX_FIXERPSTAT_BOOL1", true, 12)
          wh1Supplies = stats.get_int("MPX_CONTOTALFORWHOUSE0")
          wh_1:sleep(supply_autofill_delay)
        until wh1Supplies == whouse1.max or wh1_loop == false
        if wh1_loop then
          wh1_loop = false
        end
      end
    else
      UI.widgetSound("Error")
      gui.show_warning("Samurai's Scripts", "No warehouse found at this slot!")
      wh1_loop = false
    end
  end
end)

script.register_looped("WH2SUPP", function(wh_2)
  if wh2_loop then
    if whouse_2_owned == nil then
      whouse_2_owned = (stats.get_int("MPX_PROP_WHOUSE_SLOT1") - 1) >= 0
    end
    if whouse_2_owned then
      if whouse2.name == "" then
        SS.getCEOwhouseInfo(whouse2)
      end
      if stats.get_int("MPX_CONTOTALFORWHOUSE1") == whouse2.max then
        UI.widgetSound("Error")
        gui.show_warning("Samurai's Scripts", "Warehouse N°2 is already full! Option has been disabled.")
        wh2_loop = false
      else
        repeat
          stats.set_bool_masked("MPX_FIXERPSTAT_BOOL1", true, 13)
          wh2Supplies = stats.get_int("MPX_CONTOTALFORWHOUSE1")
          wh_2:sleep(supply_autofill_delay)
        until wh2Supplies == whouse2.max or wh2_loop == false
        if wh2_loop then
          wh2_loop = false
        end
      end
    else
      UI.widgetSound("Error")
      gui.show_warning("Samurai's Scripts", "No warehouse found at this slot!")
      wh2_loop = false
    end
  end
end)

script.register_looped("WH3SUPP", function(wh_3)
  if wh3_loop then
    if whouse_3_owned == nil then
      whouse_3_owned = (stats.get_int("MPX_PROP_WHOUSE_SLOT2") - 1) >= 0
    end
    if whouse_3_owned then
      if whouse3.name == "" then
        SS.getCEOwhouseInfo(whouse3)
      end
      if stats.get_int("MPX_CONTOTALFORWHOUSE2") == whouse3.max then
        UI.widgetSound("Error")
        gui.show_warning("Samurai's Scripts", "Warehouse N°3 is already full! Option has been disabled.")
        wh3_loop = false
      else
        repeat
          stats.set_bool_masked("MPX_FIXERPSTAT_BOOL1", true, 14)
          wh3Supplies = stats.get_int("MPX_CONTOTALFORWHOUSE2")
          wh_3:sleep(supply_autofill_delay)
        until wh3Supplies == whouse3.max or wh3_loop == false
        if wh3_loop then
          wh3_loop = false
        end
      end
    else
      UI.widgetSound("Error")
      gui.show_warning("Samurai's Scripts", "No warehouse found at this slot!")
      wh3_loop = false
    end
  end
end)

script.register_looped("WH4SUPP", function(wh_4)
  if wh4_loop then
    if whouse_4_owned == nil then
      whouse_4_owned = (stats.get_int("MPX_PROP_WHOUSE_SLOT3") - 1) >= 0
    end
    if whouse_4_owned then
      if whouse4.name == "" then
        SS.getCEOwhouseInfo(whouse4)
      end
      if stats.get_int("MPX_CONTOTALFORWHOUSE3") == whouse4.max then
        UI.widgetSound("Error")
        gui.show_warning("Samurai's Scripts", "Warehouse N°4 is already full! Option has been disabled.")
        wh4_loop = false
      else
        repeat
          stats.set_bool_masked("MPX_FIXERPSTAT_BOOL1", true, 15)
          wh4Supplies = stats.get_int("MPX_CONTOTALFORWHOUSE3")
          wh_4:sleep(supply_autofill_delay)
        until wh4Supplies == whouse4.max or wh4_loop == false
        if wh4_loop then
          wh4_loop = false
        end
      end
    else
      UI.widgetSound("Error")
      gui.show_warning("Samurai's Scripts", "No warehouse found at this slot!")
      wh4_loop = false
    end
  end
end)

script.register_looped("WH5SUPP", function(wh_5)
  if wh5_loop then
    if whouse_5_owned == nil then
      whouse_5_owned = (stats.get_int("MPX_PROP_WHOUSE_SLOT4") - 1) >= 0
    end
    if whouse_5_owned then
      if whouse5.name == "" then
        SS.getCEOwhouseInfo(whouse5)
      end
      if stats.get_int("MPX_CONTOTALFORWHOUSE4") == whouse5.max then
        UI.widgetSound("Error")
        gui.show_warning("Samurai's Scripts", "Warehouse N°5 is already full! Option has been disabled.")
        wh5_loop = false
      else
        repeat
          stats.set_bool_masked("MPX_FIXERPSTAT_BOOL1", true, 16)
          wh5Supplies = stats.get_int("MPX_CONTOTALFORWHOUSE4")
          wh_5:sleep(supply_autofill_delay)
        until wh5Supplies == whouse5.max or wh5_loop == false
        if wh5_loop then
          wh5_loop = false
        end
      end
    else
      UI.widgetSound("Error")
      gui.show_warning("Samurai's Scripts", "No warehouse found at this slot!")
      wh5_loop = false
    end
  end
end)

script.register_looped("PANIK", function(panik) -- Panic Button
  if SS.isKeyJustPressed(keybinds.panik.code) and not HUD.IS_MP_TEXT_CHAT_TYPING() and not HUD.IS_PAUSE_MENU_ACTIVE()
      and not is_typing and not is_setting_hotkeys and not gui.is_open() and not script.is_active("CELLPHONE_FLASHHAND") then
    panik:sleep(200)
    SS.handle_events()
    AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(
      "ELECTROCUTION", "MISTERK", self.get_pos().x,
      self.get_pos().y, self.get_pos().z, "SPEECH_PARAMS_FORCE"
    )
    gui.show_message("PANIK!", "(Ó _ Ò )!!")
  end
end)


--[[
   *event handlers*
]]
event.register_handler(menu_event.MenuUnloaded, function()
  SS.handle_events()
end)

event.register_handler(menu_event.ScriptsReloaded, function()
  SS.handle_events()
end)

event.register_handler(menu_event.Wndproc, function(_, msg, wParam, _)
  if msg == WM._KEYDOWN or msg == WM._SYSKEYDOWN or msg == WM._XBUTTONDOWN then
    for _, key in ipairs(VK_T) do
      if wParam == key.code then
        key.pressed      = true
        key.just_pressed = false
        break
      end
    end
  elseif msg == WM._KEYUP or msg == WM._SYSKEYUP then
    for _, key in ipairs(VK_T) do
      if wParam == key.code then
        key.pressed      = false
        key.just_pressed = true
        script.run_in_fiber(function(s)
          s:sleep(1)
          key.just_pressed = false
        end)
        break
      end
    end
  elseif msg == WM._XBUTTONUP then
    for _, key in ipairs(VK_T) do
      if key.code == 0x10020 then
        if key.pressed then
          key.pressed      = false
          key.just_pressed = true
          script.run_in_fiber(function(s)
            s:sleep(1)
            key.just_pressed = false
          end)
          break
        end
      elseif key.code == 0x20040 then
        if key.pressed then
          key.pressed      = false
          key.just_pressed = true
          script.run_in_fiber(function(s)
            s:sleep(1)
            key.just_pressed = false
          end)
          break
        end
      end
    end
  end
end)
