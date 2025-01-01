---@diagnostic disable

function vehicleUI()
  if current_vehicle ~= nil and current_vehicle ~= 0 then
    local manufacturer  = Game.Vehicle.manufacturer(current_vehicle)
    local vehicle_name  = Game.Vehicle.name(current_vehicle)
    local full_veh_name = string.format("%s %s", manufacturer, vehicle_name)
    local vehicle_class = Game.Vehicle.class(current_vehicle)
    ImGui.SeparatorText(string.format("%s  (%s)", full_veh_name, vehicle_class))
  else
    ImGui.SeparatorText("On Foot")
  end
  ImGui.Spacing(); limitVehOptions, lvoUsed = ImGui.Checkbox(LIMIT_OPTIONS_CB_, limitVehOptions)
  UI.toolTip(false, LIMIT_OPTIONS_DESC_)
  if lvoUsed then
    UI.widgetSound("Nav2")
    CFG.save("limitVehOptions", limitVehOptions)
  end

  ImGui.SameLine(); ImGui.Dummy(7, 1); ImGui.SameLine();
  missiledefense, mdefUsed = ImGui.Checkbox("Missile Defence", missiledefense)
  UI.toolTip(false, MISSILE_DEF_DESC_)
  if mdefUsed then
    CFG.save("missiledefense", missiledefense)
    if missiledefense then
      UI.widgetSound("Radar")
      gui.show_success("Samurais Scripts", MISSILE_DEF_ON_)
    else
      UI.widgetSound("Delete")
      gui.show_message("Samurais Scripts", MISSILE_DEF_OFF_)
    end
  end

  launchCtrl, lctrlUsed = ImGui.Checkbox("Launch Control", launchCtrl)
  UI.toolTip(false, LAUNCH_CTRL_DESC_)
  if lctrlUsed then
    UI.widgetSound("Nav2")
    CFG.save("launchCtrl", launchCtrl)
  end

  ImGui.SameLine(); ImGui.Dummy(31, 1); ImGui.SameLine(); speedBoost, spdbstUsed = ImGui.Checkbox("NOS", speedBoost)
  UI.toolTip(false, NOS_DESC_)
  if spdbstUsed then
    UI.widgetSound("Nav2")
    CFG.save("speedBoost", speedBoost)
  end
  if speedBoost then
    ImGui.SameLine()
    if ImGui.Button("NOS Settings") then
      UI.widgetSound("Select")
      ImGui.OpenPopup("Nos Settings")
    end
    ImGui.SetNextWindowPos(780, 400, ImGuiCond.Appearing)
    ImGui.SetNextWindowBgAlpha(0.9)
    ImGui.SetNextWindowSize(450, 260)
    if ImGui.BeginPopupModal("Nos Settings", ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
      ImGui.Spacing(); ImGui.Text("NOS Settings"); ImGui.SameLine(); ImGui.Dummy(256, 1); ImGui.SameLine()
      ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 80)
      if ImGui.Button("  X  ##nos_settings") then
        UI.widgetSound("Cancel")
        ImGui.CloseCurrentPopup()
      end
      ImGui.PopStyleVar(); ImGui.Separator(); ImGui.Dummy(1, 10)
      nosAudio, nosaudioUsed = ImGui.Checkbox("NOS Sound", nosAudio)
      if nosaudioUsed then
        UI.widgetSound("Nav2")
        CFG.save("nosAudio", nosAudio)
      end

      ImGui.SameLine(); nosFlames, nosflamesUsed = ImGui.Checkbox("NOS Flames", nosFlames)
      if nosflamesUsed then
        UI.widgetSound("Nav2")
        CFG.save("nosFlames", nosFlames)
      end

      ImGui.SameLine(); nosvfx, nosvfxUsed = ImGui.Checkbox("Screen Effect", nosvfx)
      UI.toolTip(false, NOS_VFX_DESC_)
      if nosvfxUsed then
        UI.widgetSound("Nav2")
        CFG.save("nosvfx", nosvfx)
      end

      ImGui.Dummy(1, 15); ImGui.Text(" Power:  "); ImGui.SameLine()
      nosPower, nspwrUsed = ImGui.SliderInt("##nospower", nosPower, 10, 100, "%d",
        ImGuiSliderFlags.NoInput | ImGuiSliderFlags.AlwaysClamp | ImGuiSliderFlags.Logarithmic)
      if nspwrUsed then
        UI.widgetSound("Nav")
      end
      ImGui.Dummy(1, 20)
      if ImGui.Button(string.format(" %s ##nos_settings", GENERIC_SAVE_BTN_)) then
        UI.widgetSound("Select")
        CFG.save("nosPower", nosPower)
        ImGui.CloseCurrentPopup()
      end
      ImGui.SameLine(); ImGui.Dummy(30, 1); ImGui.SameLine()
      if ImGui.Button(string.format(" %s ##nos_settings", GENERIC_CANCEL_BTN_)) then
        UI.widgetSound("Cancel")
        ImGui.CloseCurrentPopup()
      end
      ImGui.End()
    end
  end

  loud_radio, loudRadioUsed = ImGui.Checkbox("Big Subwoofer", loud_radio)
  UI.toolTip(false, LOUD_RADIO_DESC_)
  if loudRadioUsed then
    UI.widgetSound("Nav2")
    CFG.save("loud_radio", loud_radio)
    if not loud_radio then
      script.run_in_fiber(function()
        AUDIO.SET_VEHICLE_RADIO_LOUD(current_vehicle, false)
        loud_radio_enabled = false
      end)
    end
  end

  ImGui.SameLine(); ImGui.Dummy(32, 1); ImGui.SameLine(); nosPurge, nosPurgeUsed = ImGui.Checkbox("NOS Purge", nosPurge)
  UI.toolTip(false, NOS_PURGE_DESC_)
  if nosPurgeUsed then
    UI.widgetSound("Nav2")
    CFG.save("nosPurge", nosPurge)
  end

  popsNbangs, pnbUsed = ImGui.Checkbox("Pops & Bangs", popsNbangs)
  UI.toolTip(false, POPSNBANGS_DESC_)
  if pnbUsed then
    UI.widgetSound("Nav2")
    CFG.save("popsNbangs", popsNbangs)
  end
  if popsNbangs then
    ImGui.SameLine(); ImGui.Dummy(37, 1); ImGui.SameLine(); louderPops, louderPopsUsed = ImGui.Checkbox("Louder Pops",
      louderPops)
    UI.toolTip(false, LOUDER_POPS_DESC_)
    if louderPopsUsed then
      UI.widgetSound("Nav2")
      CFG.save("louderPops", louderPops)
    end
  end

  hornLight, hornLightUsed = ImGui.Checkbox("High Beams on Horn", hornLight)
  UI.toolTip(false, HIGH_BEAMS_DESC_)
  if hornLightUsed then
    UI.widgetSound("Nav2")
    CFG.save("hornLight", hornLight)
  end

  ImGui.SameLine(); autobrklight, autobrkUsed = ImGui.Checkbox("Auto Brake Lights", autobrklight)
  UI.toolTip(false, BRAKE_LIGHT_DESC_)
  if autobrkUsed then
    UI.widgetSound("Nav2")
    CFG.save("autobrklight", autobrklight)
  end

  holdF, holdFused = ImGui.Checkbox("Keep Engine On", holdF)
  UI.toolTip(false, IV_STYLE_EXIT_DESC_)
  if holdFused then
    UI.widgetSound("Nav2")
    CFG.save("holdF", holdF)
  end

  ImGui.SameLine(); ImGui.Dummy(25, 1); ImGui.SameLine(); keepWheelsTurned, kwtrnd = ImGui.Checkbox(
    "Keep Wheels Turned", keepWheelsTurned)
  UI.toolTip(false, KEEP_WHEELS_TURNED_DESC_)
  if kwtrnd then
    UI.widgetSound("Nav2")
    CFG.save("keepWheelsTurned", keepWheelsTurned)
  end

  noJacking, noJackingUsed = ImGui.Checkbox(
    "Can't Touch This!", noJacking)
  UI.toolTip(false, CANT_TOUCH_THIS_DESC_)
  if noJackingUsed then
    UI.widgetSound("Nav2")
    CFG.save("noJacking", noJacking)
  end

  ImGui.SameLine(); ImGui.Dummy(15, 1); ImGui.SameLine(); insta180, insta180Used = ImGui.Checkbox("Instant 180°",
    insta180)
  if insta180Used then
    UI.widgetSound("Nav2")
    CFG.save("insta180", insta180)
  end
  UI.toolTip(false, INSTA_180_DESC_)

  if Game.isOnline() then
    flares_forall, flaresUsed = ImGui.Checkbox("Flares For All", flares_forall)
    UI.toolTip(false, FLARES_FOR_ALL_DESC_)
    if flaresUsed then
      UI.widgetSound("Nav2")
      CFG.save("flares_forall", flares_forall)
    end
  else
    ImGui.BeginDisabled()
    flares_forall, flaresUsed = ImGui.Checkbox("Flares For All", flares_forall)
    ImGui.EndDisabled()
    UI.toolTip(true, GENERIC_UNAVAILABLE_SP_, '#FF3333', 1)
  end

  ImGui.SameLine(); ImGui.Dummy(46, 1); ImGui.SameLine(); real_plane_speed, rpsUsed = ImGui.Checkbox(
    "Higher Plane Speeds", real_plane_speed)
  UI.toolTip(false, PLANE_SPEED_DESC_)
  if rpsUsed then
    UI.widgetSound("Nav2")
    CFG.save("real_plane_speed", real_plane_speed)
  end

  unbreakableWindows, ubwUsed = ImGui.Checkbox("Strong Windows", unbreakableWindows)
  UI.toolTip(false, STRONG_WINDOWS_DESC_)
  if ubwUsed then
    UI.widgetSound("Nav2")
    CFG.save("unbreakableWindows", unbreakableWindows)
    if not unbreakableWindows and ubwindowsToggled then
      VEHICLE.SET_DONT_PROCESS_VEHICLE_GLASS(current_vehicle, false)
      ubwindowsToggled = false
    end
  end

  ImGui.SameLine(); ImGui.Dummy(18, 1); ImGui.SameLine(); flappyDoors, flappyDoorsUsed = ImGui.Checkbox("Flappy Doors",
    flappyDoors)
  if flappyDoorsUsed then
    UI.widgetSound("Nav2")
    CFG.save("flappyDoors", flappyDoors)
  end

  veh_mines, vmnsUsed = ImGui.Checkbox("Vehicle Mines", veh_mines)
  if vmnsUsed then
    UI.widgetSound("Nav2")
    CFG.save("veh_mines", veh_mines)
  end
  UI.toolTip(false, VEHICLE_MINES_DESC_)
  if veh_mines then
    ImGui.SameLine(); ImGui.Dummy(35, 1); ImGui.SameLine();
    if ImGui.Button(MINES_TYPE_BTN_) then
      UI.widgetSound("Select")
      ImGui.OpenPopup("Mine Types")
    end
    ImGui.SetNextWindowPos(760, 400, ImGuiCond.Appearing)
    ImGui.SetNextWindowBgAlpha(0.81)
    if ImGui.BeginPopupModal("Mine Types", true, ImGuiWindowFlags.AlwaysAutoResize) then
      ImGui.Dummy(1, 5); ImGui.Text(MINES_TYPE_DESC_); ImGui.Dummy(1, 5)
      vmine_type.spikes, spikeUsed = ImGui.Checkbox("Spike", vmine_type.spikes)
      if spikeUsed then
        UI.widgetSound("Nav2")
        vmine_type.slick     = false
        vmine_type.explosive = false
        vmine_type.emp       = false
        vmine_type.kinetic   = false
        CFG.save("vmine_type", vmine_type)
      end

      ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
      vmine_type.slick, slickUsed = ImGui.Checkbox("Slick", vmine_type.slick)
      if slickUsed then
        UI.widgetSound("Nav2")
        vmine_type.spikes    = false
        vmine_type.explosive = false
        vmine_type.emp       = false
        vmine_type.kinetic   = false
        CFG.save("vmine_type", vmine_type)
      end

      ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
      vmine_type.explosive, expUsed = ImGui.Checkbox("Explosive", vmine_type.explosive)
      if expUsed then
        UI.widgetSound("Nav2")
        vmine_type.spikes  = false
        vmine_type.slick   = false
        vmine_type.emp     = false
        vmine_type.kinetic = false
        CFG.save("vmine_type", vmine_type)
      end

      ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
      vmine_type.emp, empUsed = ImGui.Checkbox("EMP", vmine_type.emp)
      if empUsed then
        UI.widgetSound("Nav2")
        vmine_type.spikes    = false
        vmine_type.slick     = false
        vmine_type.explosive = false
        vmine_type.kinetic   = false
        CFG.save("vmine_type", vmine_type)
      end

      ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
      vmine_type.kinetic, kntcUsed = ImGui.Checkbox("Kinetic", vmine_type.kinetic)
      if kntcUsed then
        UI.widgetSound("Nav2")
        vmine_type.spikes    = false
        vmine_type.slick     = false
        vmine_type.explosive = false
        vmine_type.emp       = false
        CFG.save("vmine_type", vmine_type)
      end

      ImGui.Dummy(1, 5)
      if missiledefense and (vmine_type.slick or vmine_type.explosive or vmine_type.emp or vmine_type.kinetic) then
        UI.coloredText(
          "[ ! ] NOTE: You have 'Missile Defence' activated which will automatically destroy / remove these mines. If you still want to use them, please disable 'Missile Defence'.",
          "yellow", 0.69, 30)
      end
      ImGui.Dummy(1, 5)
      if vmine_type.spikes or vmine_type.slick or vmine_type.explosive or vmine_type.emp or vmine_type.kinetic then
        if ImGui.Button("Confirm") then
          UI.widgetSound("Select")
          CFG.save("vmine_type", vmine_type)
          ImGui.CloseCurrentPopup()
        end
      end
      ImGui.End()
    end
  end

  rgbLights, rgbToggled = ImGui.Checkbox(RGB_LIGHTS_DESC_, rgbLights)
  if rgbToggled then
    UI.widgetSound("Nav2")
    CFG.save("rgbLights", rgbLights)
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
  if rgbLights then
    ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine()
    ImGui.PushItemWidth(150)
    lightSpeed, lightSpeedUsed = ImGui.SliderInt(RGB_SPEED_TXT_, lightSpeed, 1, 3)
    ImGui.PopItemWidth()
    if lightSpeedUsed then
      UI.widgetSound("Nav")
      CFG.save("lightSpeed", lightSpeed)
    end
  end

  abs_lights, abslUsed = ImGui.Checkbox("ABS Brake Lights", abs_lights)
  UI.toolTip(false,
    "Flashes your brake lights repeatedly when braking at high speed (over 100km/h).\nOnly works on vehicles that have ABS.")
  if abslUsed then
    UI.widgetSound("Nav2")
    CFG.save("abs_lights", abs_lights)
  end

  ImGui.SameLine(); ImGui.Dummy(13, 1); ImGui.SameLine()
  fender_bender, fbenderUsed = ImGui.Checkbox("Better Car Crashes", fender_bender)
  UI.toolTip(false, FENDER_BENDER_DESC_)
  if fbenderUsed then
    UI.widgetSound("Nav2")
    CFG.save("fender_bender", fender_bender)
  end

  ImGui.Spacing(); ImGui.SeparatorText("Auto-Pilot")
  if current_vehicle ~= nil and current_vehicle ~= 0 then
    local aircraft_check = Game.Self.isDriving() and (is_plane or is_heli)
    ImGui.BeginDisabled(not aircraft_check)
    if ImGui.Button(" Fly To Waypoint ") then
      UI.widgetSound("Select")
      script.run_in_fiber(function(ap)
        local wp = HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_WAYPOINT_BLIP_ENUM_ID())
        if HUD.DOES_BLIP_EXIST(wp) then
          local waypoint_coords = HUD.GET_BLIP_COORDS(wp)
          if autopilot_objective or autopilot_random then
            TASK.CLEAR_PED_TASKS(self.get_ped())
            TASK.CLEAR_PRIMARY_VEHICLE_TASK(current_vehicle)
          end
          autopilot_waypoint  = true
          autopilot_objective = false
          autopilot_random    = false
          gui.show_success("Samurai's Scripts", "Flying towards your waypoint")
          if is_plane then
            TASK.TASK_PLANE_MISSION(
              self.get_ped(), current_vehicle, 0, 0, waypoint_coords.x, waypoint_coords.y, waypoint_coords.z + 600,
              4, 100.0, 0, 90, 0, 0, true
            )
            if VEHICLE.GET_VEHICLE_HAS_LANDING_GEAR(current_vehicle) and VEHICLE.IS_PLANE_LANDING_GEAR_INTACT(current_vehicle) then
              if VEHICLE.GET_LANDING_GEAR_STATE(current_vehicle) ~= 4 then
                if Game.Self.get_elevation() >= 15 then
                  VEHICLE.CONTROL_LANDING_GEAR(current_vehicle, 1)
                else
                  repeat
                    ap:sleep(10)
                  until Game.Self.get_elevation() >= 15
                  VEHICLE.CONTROL_LANDING_GEAR(current_vehicle, 1)
                end
              end
            end
          elseif is_heli then
            TASK.TASK_HELI_MISSION(
              self.get_ped(), current_vehicle, 0, 0, waypoint_coords.x, waypoint_coords.y, waypoint_coords.z,
              4, 50.0, 4.0, -1, -1, 100, 100.0, 0
            )
          end
        else
          gui.show_warning("Samurai's Scripts", "Please set a waypoint on the map first!")
        end
      end)
    end
    ImGui.SameLine()
    if ImGui.Button(" Fly To Objective ") then
      UI.widgetSound("Select")
      script.run_in_fiber(function(ap)
        local objective_found, objective_coords = Game.findObjectiveBlip()
        if objective_found and objective_coords ~= nil then
          if autopilot_waypoint or autopilot_random then
            TASK.CLEAR_PED_TASKS(self.get_ped())
            TASK.CLEAR_PRIMARY_VEHICLE_TASK(current_vehicle)
          end
          autopilot_waypoint  = false
          autopilot_objective = true
          autopilot_random    = false
          gui.show_success("Samurai's Scripts", "Flying towards objective")
          if is_plane then
            TASK.TASK_PLANE_MISSION(
              self.get_ped(), current_vehicle, 0, 0, objective_coords.x, objective_coords.y, objective_coords.z + 600,
              4, 100.0, 0, 90, 0, 0, true
            )
            if VEHICLE.GET_VEHICLE_HAS_LANDING_GEAR(current_vehicle) and VEHICLE.IS_PLANE_LANDING_GEAR_INTACT(current_vehicle) then
              if VEHICLE.GET_LANDING_GEAR_STATE(current_vehicle) ~= 4 then
                if Game.Self.get_elevation() >= 15 then
                  VEHICLE.CONTROL_LANDING_GEAR(current_vehicle, 1)
                else
                  repeat
                    ap:sleep(10)
                  until Game.Self.get_elevation() >= 15
                  VEHICLE.CONTROL_LANDING_GEAR(current_vehicle, 1)
                end
              end
            end
          elseif is_heli then
            TASK.TASK_HELI_MISSION(
              self.get_ped(), current_vehicle, 0, 0, objective_coords.x, objective_coords.y, objective_coords.z,
              4, 50.0, 4.0, -1, -1, 100, 100.0, 0
            )
          end
        else
          gui.show_warning("Samurai's Scripts", "No objective found!")
        end
      end)
    end
    ImGui.SameLine()
    if ImGui.Button(" Random ") then
      UI.widgetSound("Select")
      script.run_in_fiber(function(ap)
        if autopilot_waypoint or autopilot_objective then
          TASK.CLEAR_PED_TASKS(self.get_ped())
          TASK.CLEAR_PRIMARY_VEHICLE_TASK(current_vehicle)
        end
        autopilot_waypoint  = false
        autopilot_objective = false
        autopilot_random    = true
        gui.show_success("Samurai's Scripts", "Flying towards some random coordinates")
        if is_plane then
          TASK.TASK_PLANE_MISSION(
            self.get_ped(), current_vehicle, 0, 0, math.random(-3000, 3000), math.random(-3000, 3000),
            math.random(400, 900), 4, 100.0, 0, 90, 0, 0, true
          )
          if VEHICLE.GET_VEHICLE_HAS_LANDING_GEAR(current_vehicle) and VEHICLE.IS_PLANE_LANDING_GEAR_INTACT(current_vehicle) then
            if VEHICLE.GET_LANDING_GEAR_STATE(current_vehicle) ~= 4 then
              if Game.Self.get_elevation() >= 15 then
                VEHICLE.CONTROL_LANDING_GEAR(current_vehicle, 1)
              else
                repeat
                  ap:sleep(10)
                until Game.Self.get_elevation() >= 15
                VEHICLE.CONTROL_LANDING_GEAR(current_vehicle, 1)
              end
            end
          end
        elseif is_heli then
          TASK.TASK_HELI_MISSION(
            self.get_ped(), current_vehicle, 0, 0, math.random(-3000, 3000), math.random(-3000, 3000),
            math.random(10, 300),
            4, 50.0, 4.0, -1, -1, 100, 100.0, 0
          )
        end
      end)
    end
    if autopilot_waypoint or autopilot_objective or autopilot_random then
      ImGui.Dummy(160, 1); ImGui.SameLine()
      if ImGui.Button("Stop", 60, 35) then
        UI.widgetSound("Cancel")
        script.run_in_fiber(function()
          TASK.CLEAR_PED_TASKS(self.get_ped())
          TASK.CLEAR_PRIMARY_VEHICLE_TASK(current_vehicle)
          autopilot_waypoint  = false
          autopilot_objective = false
          autopilot_random    = false
        end)
      end
    end
    ImGui.EndDisabled()
    if not aircraft_check then
      UI.coloredText(AUTOPILOT_ERROR_TXT_, 'yellow', 0.87, 20)
    end
  else
    UI.coloredText(AUTOPILOT_ERROR_TXT_, 'yellow', 0.87, 20)
  end
  ImGui.Dummy(1, 5); ImGui.SeparatorText("MISC")
  ImGui.BeginDisabled(current_vehicle == 0)
  if ImGui.Button(string.format(" %s ", ENGINE_SOUND_BTN_)) then
    if is_car or is_bike or is_quad then
      UI.widgetSound("Select")
      open_sounds_window = true
    else
      open_sounds_window = false
      UI.widgetSound("Error")
      gui.show_error("Samurais Scripts", ENGINE_SOUND_ERROR_TXT_)
    end
  end

  ImGui.SameLine(); ImGui.Dummy(30, 1); ImGui.SameLine()
  if dummyCopCar == 0 then
    if VEHICLE.GET_VEHICLE_CLASS(current_vehicle) ~= 18 then
      if ImGui.Button(" Equip Fake Siren ") then
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
        VEHICLE.SET_VEHICLE_ACT_AS_IF_HAS_SIREN_ON(current_vehicle, false)
        VEHICLE.SET_VEHICLE_CAUSES_SWERVING(current_vehicle, false)
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(current_vehicle, 0, false)
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(current_vehicle, 1, false)
        if ENTITY.DOES_ENTITY_EXIST(dummyCopCar) then
          ENTITY.SET_ENTITY_AS_MISSION_ENTITY(dummyCopCar, true, true)
          deletecop:sleep(200)
          ENTITY.DELETE_ENTITY(dummyCopCar)
        end
        dummyCopCar = 0
      end)
    end
  end

  if ImGui.Button("Ejecto Seato Cuz") then
    UI.widgetSound("Select")
    script.run_in_fiber(function(ejecto)
      local passengers = Game.Vehicle.getOccupants(current_vehicle)
      if #passengers == 1 then
        if passengers[1] == self.get_ped() then
          gui.show_error("Samurai's Scripts", "You can not ejecto seato on yourself, cuz!")
          goto pass
        end
      elseif #passengers >= 1 then
        gui.show_message("Samurai's Scripts", "YEET!")
      end
      for _, ped in ipairs(passengers) do
        if ped ~= self.get_ped() then
          if not PED.IS_PED_A_PLAYER(ped) then
            TASK.CLEAR_PED_TASKS(ped)
            TASK.TASK_LEAVE_VEHICLE(ped, current_vehicle, 4160)
          else
            local player_index = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(ped)
            command.call("vehkick", { player_index })
            ejecto:sleep(1000)
            if PED.IS_PED_SITTING_IN_VEHICLE(ped, current_vehicle) then
              gui.show_error("Samurai's Scripts", "Failed to eject the player from our vehicle!")
            end
          end
        end
      end
      ::pass::
    end)
  end
  UI.toolTip(false, EJECTO_SEATO_DESC_)

  if current_vehicle ~= 0 then
    local engineHealth = VEHICLE.GET_VEHICLE_ENGINE_HEALTH(current_vehicle)
    if engineHealth <= 300 then
      engineDestroyed = true
    else
      engineDestroyed = false
    end
  end
  if engineDestroyed then
    engineButton_label = FIX_ENGINE_
    engine_hp          = 1000
    button_color_1     = "#008000"
    button_color_2     = "#005A00"
    button_color_3     = "#BFFFBF"
  else
    engineButton_label = DESTROY_ENGINE_
    engine_hp          = -4000
    button_color_1     = "#FF0000"
    button_color_2     = "#B30000"
    button_color_3     = "#FF8080"
  end
  ImGui.SameLine(); ImGui.Dummy(97, 1); ImGui.SameLine()
  if UI.coloredButton(engineButton_label, button_color_1, button_color_2, button_color_3, 1) then
    UI.widgetSound("Select")
    script.run_in_fiber(function()
      VEHICLE.SET_VEHICLE_ENGINE_HEALTH(current_vehicle, engine_hp)
    end)
  end
  ImGui.EndDisabled()

  ImGui.BeginDisabled(Game.Self.isDriving() or not Game.Self.isOutside() or current_vehicle == 0)
  if ImGui.Button("TP Into Last Vehicle") then
    UI.widgetSound("Select")
    script.run_in_fiber(function()
      if ENTITY.DOES_ENTITY_EXIST(current_vehicle) and ENTITY.IS_ENTITY_A_VEHICLE(current_vehicle) then
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
        PED.SET_PED_INTO_VEHICLE(self.get_ped(), current_vehicle, -1)
      else
        gui.show_error("Samurai's Scripts", "Your last vehicle no longer exists in the game world.")
      end
    end)
  end
  ImGui.SameLine(); ImGui.Dummy(55, 1); ImGui.SameLine()
  if ImGui.Button("Bring Last Vehicle") then
    UI.widgetSound("Select")
    script.run_in_fiber(function(blv)
      if ENTITY.DOES_ENTITY_EXIST(current_vehicle) and ENTITY.IS_ENTITY_A_VEHICLE(current_vehicle) then
        local veh_coords  = ENTITY.GET_ENTITY_COORDS(current_vehicle, true)
        local self_coords = self.get_pos()
        local distance    = MISC.GET_DISTANCE_BETWEEN_COORDS(veh_coords.x, veh_coords.y, veh_coords.z, self_coords.x,
          self_coords.y, self_coords.z, false)
        if distance <= 15 then
          gui.show_warning("Samurai's Scripts", "Your last vehicle is already too close")
        else
          local self_fwd   = ENTITY.GET_ENTITY_FORWARD_VECTOR(self.get_ped())
          local veh_hash   = ENTITY.GET_ENTITY_MODEL(current_vehicle)
          local vmin, vmax = Game.getModelDimensions(veh_hash, blv)
          local veh_length = vmax.y - vmin.y
          local tp_offset  = { x = self_fwd.x * veh_length, y = self_fwd.y * veh_length }
          ENTITY.SET_ENTITY_COORDS(current_vehicle, self_coords.x + tp_offset.x, self_coords.y + tp_offset.y,
            self_coords.z, false, false, false, true)
        end
      else
        gui.show_error("Samurai's Scripts", "Your last vehicle no longer exists in the game world.")
      end
    end)
  end
  ImGui.EndDisabled()
  if Game.isOnline() then
    if globals.get_int(pv_global) > 0 and current_vehicle ~= globals.get_int(pv_global) then
      ImGui.BeginDisabled(Game.Self.isDriving() or not Game.Self.isOutside() or globals.get_int(pv_global) <= 0)
      if ImGui.Button("TP Into Personal Vehicle") then
        UI.widgetSound("Select")
        script.run_in_fiber(function()
          if ENTITY.DOES_ENTITY_EXIST(globals.get_int(pv_global)) then
            if INTERIOR.GET_INTERIOR_FROM_ENTITY(globals.get_int(pv_global)) == 0 then
              TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.get_ped())
              PED.SET_PED_INTO_VEHICLE(self.get_ped(), globals.get_int(pv_global), -1)
            else
              gui.show_error("Samurai's Scripts", "Your personal vehicle is not outside.")
            end
          else
            gui.show_error("Samurai's Scripts", "Your personal vehicle no longer exists in the game world.")
          end
        end)
      end
      ImGui.SameLine()
      if ImGui.Button("Bring Personal Vehicle") then
        UI.widgetSound("Select")
        script.run_in_fiber(function(bpv)
          if ENTITY.DOES_ENTITY_EXIST(globals.get_int(pv_global)) then
            if INTERIOR.GET_INTERIOR_FROM_ENTITY(globals.get_int(pv_global)) == 0 then
              local veh_coords  = ENTITY.GET_ENTITY_COORDS(globals.get_int(pv_global), true)
              local self_coords = self.get_pos()
              local distance    = MISC.GET_DISTANCE_BETWEEN_COORDS(veh_coords.x, veh_coords.y, veh_coords.z,
                self_coords.x,
                self_coords.y, self_coords.z, false)
              if distance <= 15 then
                gui.show_warning("Samurai's Scripts", "Your personal vehicle is already too close")
              else
                local self_fwd   = ENTITY.GET_ENTITY_FORWARD_VECTOR(self.get_ped())
                local veh_hash   = ENTITY.GET_ENTITY_MODEL(globals.get_int(pv_global))
                local vmin, vmax = Game.getModelDimensions(veh_hash, bpv)
                local veh_length = vmax.y - vmin.y
                local tp_offset  = { x = self_fwd.x * veh_length, y = self_fwd.y * veh_length }
                ENTITY.SET_ENTITY_COORDS(globals.get_int(pv_global), self_coords.x + tp_offset.x,
                  self_coords.y + tp_offset
                  .y, self_coords.z, false, false, false, true)
              end
            else
              gui.show_error("Samurai's Scripts", "Your personal vehicle is not outside.")
            end
          else
            gui.show_error("Samurai's Scripts", "Your personal vehicle no longer exists in the game world.")
          end
        end)
      end
      ImGui.EndDisabled()
    end
  end

  ImGui.BeginDisabled(Game.Self.isDriving() or not Game.Self.isOutside() or current_vehicle == 0 or not is_car)
  if ImGui.Button(("%s Doors"):format(vehicleLockStatus <= 1 and "Lock" or "Unlock")) then
    script.run_in_fiber(function(dlocks)
      if current_vehicle ~= 0 and is_car then
        if last_vehicle ~= 0 and last_vehicle ~= current_vehicle and
            VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(last_vehicle)) and
            (VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(last_vehicle) ~= 1) then
          VEHICLE.SET_VEHICLE_DOORS_LOCKED(last_vehicle, 1)
        end
        SS.playKeyfobAnim()
        AUDIO.PLAY_SOUND_FRONTEND(-1, "REMOTE_CONTROL_FOB", "PI_MENU_SOUNDS", false)
        dlocks:sleep(250)
        local toggle = (VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(current_vehicle) == 1) and true or false
        vehicleLockStatus = toggle and 2 or 1
        Game.Vehicle.lockDoors(current_vehicle, toggle, dlocks)
      end
    end)
  end
  ImGui.EndDisabled();
  if current_vehicle ~= 0 and not is_car then
    UI.toolTip(false, "You can only lock/unlock cars and trucks.")
  end
  ImGui.SameLine()
  autovehlocks, avlUsed = ImGui.Checkbox("Auto-Lock", autovehlocks)
  UI.toolTip(false, AUTOVEHLOCKS_DESC_)
  if avlUsed then
    UI.widgetSound("Nav2")
    CFG.save("autovehlocks", autovehlocks)
  end

  ImGui.SameLine(); autoraiseroof, autoroofUsed = ImGui.Checkbox("Auto-Raise Roof", autoraiseroof)
  UI.toolTip(false, AUTO_RAISE_ROOF_DESC_)
  if autoroofUsed then
    UI.widgetSound("Nav2")
    CFG.save("autoraiseroof", autoraiseroof)
  end

  if open_sounds_window then
    ImGui.SetNextWindowPos(740, 300, ImGuiCond.Appearing)
    ImGui.SetNextWindowSizeConstraints(100, 100, 600, 800)
    ImGui.Begin("Vehicle Sounds",
      ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoCollapse)
    if ImGui.Button(GENERIC_CLOSE_BTN_) then
      UI.widgetSound("Cancel")
      open_sounds_window = false
    end
    ImGui.Spacing(); ImGui.Spacing()
    ImGui.PushItemWidth(250)
    search_term, used = ImGui.InputTextWithHint("", SEARCH_VEH_HINT_, search_term, 32)
    is_typing = ImGui.IsItemActive()
    ImGui.PushItemWidth(270)
    displayVehNames()
    ImGui.PopItemWidth()
    local selected_name = filteredNames[vehSound_index + 1]
    ImGui.Spacing()
    if ImGui.Button(SELECT_SOUND_TXT_) then
      UI.widgetSound("Select")
      script.run_in_fiber(function()
        AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(current_vehicle, selected_name)
      end)
    end
    ImGui.SameLine()
    if ImGui.Button(RESTORE_DEFAULT_) then
      UI.widgetSound("Delete")
      script.run_in_fiber(function()
        AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(current_vehicle,
          vehicles.get_vehicle_display_name(ENTITY.GET_ENTITY_MODEL(current_vehicle)))
      end)
    end
    ImGui.End()
  end
end
