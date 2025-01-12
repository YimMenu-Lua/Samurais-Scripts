---@diagnostic disable

function worldUI()
  ImGui.BeginDisabled(ped_grabbed or vehicle_grabbed)
  pedGrabber, pgUsed = ImGui.Checkbox(PED_GRABBER_CB_, pedGrabber)
  UI.helpMarker(false, PED_GRABBER_DESC_)
  if pgUsed then
    UI.widgetSound("Nav2")
    vehicleGrabber = false
  end
  vehicleGrabber, vgUsed = ImGui.Checkbox("Vehicle Grabber", vehicleGrabber)
  UI.helpMarker(false, VEH_GRABBER_DESC_)
  if vgUsed then
    UI.widgetSound("Nav2")
    pedGrabber = false
  end
  ImGui.EndDisabled()

  if pedGrabber or vehicleGrabber then
    ImGui.Text(THROW_FORCE_TXT_)
    ImGui.PushItemWidth(220)
    pedthrowF, ptfUsed = ImGui.SliderInt("##throw_force", pedthrowF, 10, 100, "%d", 0)
    ImGui.PopItemWidth()
    if ptfUsed then
      UI.widgetSound("Nav")
    end
  end

  carpool, carpoolUsed = ImGui.Checkbox(CARPOOL_CB_, carpool)
  UI.helpMarker(false, CARPOOL_DESC_)
  if carpoolUsed then
    UI.widgetSound("Nav2")
  end

  if carpool then
    if show_npc_veh_ui then
      SS.showNPCvehicleControls()
    end
  end

  animateNPCs, used = ImGui.Checkbox(ANIMATE_NPCS_CB_, animateNPCs)
  if used then
    UI.widgetSound("Nav")
  end
  UI.helpMarker(false, ANIMATE_NPCS_DESC_)
  if animateNPCs then
    ImGui.PushItemWidth(220)
    displayHijackAnims()
    ImGui.PopItemWidth()
    local hijackData = hijackOptions[grp_anim_index + 1]
    ImGui.SameLine()
    if not hijack_started then
      if ImGui.Button(string.format("  %s  ##hjStart", GENERIC_PLAY_BTN_)) then
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
      if ImGui.Button(string.format("  %s  ##hjStop", GENERIC_STOP_BTN_)) then
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

  kamikazeDrivers, kdUsed = ImGui.Checkbox(KAMIKAZE_DRIVERS_CB_, kamikazeDrivers)
  UI.helpMarker(false, KAMIKAZE_DRIVERS_DESC_)
  if kdUsed then
    UI.widgetSound("Nav2")
    if kamikazeDrivers then
      publicEnemy = false
    end
  end

  publicEnemy, peUsed = ImGui.Checkbox(PUBLIC_ENEMY_CB_, publicEnemy)
  UI.helpMarker(false, PUBLIC_ENEMY_DESC_)
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

  public_seats, pseatsUsed = ImGui.Checkbox("Public Seating", public_seats)
  UI.helpMarker(false, PUBLIC_SEATS_DESC_)
  if pseatsUsed then
    UI.widgetSound("Nav2")
    CFG.save("public_seats", public_seats)
  end

  ambient_scenarios, ascnUsed = ImGui.Checkbox("Ambient Scenarios", ambient_scenarios)
  UI.helpMarker(false, AMB_SCN_DESC_)
  if ascnUsed then
    UI.widgetSound("Nav2")
    CFG.save("ambient_scenarios", ambient_scenarios)
  end

  if ambient_scenarios then
    ImGui.SameLine()
    ambient_scenario_prompt, ascnpUsed = ImGui.Checkbox("Show Prompt", ambient_scenario_prompt)
    UI.helpMarker(false, "Enable or disable button prompts when near an ambient scenario location.")
    if ascnpUsed then
      UI.widgetSound("Nav2")
      CFG.save("ambient_scenario_prompt", ambient_scenario_prompt)
    end
  end

  extend_world, ewbUsed = ImGui.Checkbox(EXTEND_WORLD_CB_, extend_world)
  UI.helpMarker(false, EXTEND_WORLD_DESC_)
  if ewbUsed then
    UI.widgetSound("Nav2")
    CFG.save("extend_world", extend_world)
    if not extend_world then
      script.run_in_fiber(function()
        Game.World.extendBounds(false)
        world_extended = false
      end)
    end
  end

  disable_waves, dowUsed = ImGui.Checkbox(SMOOTH_WATERS_CB_, disable_waves)
  UI.helpMarker(false, SMOOTH_WATERS_DESC_)
  if dowUsed then
    UI.widgetSound("Nav2")
    Game.World.disableOceanWaves(disable_waves)
  end
end
