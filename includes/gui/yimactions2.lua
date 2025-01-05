---@diagnostic disable: undefined-global, lowercase-global

function actionsUI()
  ImGui.Dummy(60, 1); ImGui.SameLine()
  ImGui.PushItemWidth(270)
  actions_search, used = ImGui.InputTextWithHint("##searchBar", GENERIC_SEARCH_HINT_, actions_search, 32)
  ImGui.PopItemWidth()
  is_typing = ImGui.IsItemActive()
  ImGui.BeginTabBar("Actionz", ImGuiTabBarFlags.None)
  if ImGui.BeginTabItem(ANIMATIONS_TAB_) then
    if tab1Sound then
      UI.widgetSound("Nav")
      tab1Sound = false
      tab2Sound = true
      tab3Sound = true
      tab4Sound = true
    end
    ImGui.Spacing(); ImGui.BulletText("Filter Animations: "); ImGui.SameLine()
    ImGui.PushItemWidth(220)
    anim_sortby_idx, animSortUsed = ImGui.Combo("##animCategories", anim_sortby_idx, animSortbyList, #animSortbyList)
    ImGui.PopItemWidth()
    if animSortUsed then
      UI.widgetSound("Nav2")
    end
    ImGui.Spacing(); ImGui.Separator(); ImGui.PushItemWidth(420) -- whatcha smokin'?
    displayFilteredAnims()
    ImGui.PopItemWidth()
    if filteredAnims ~= nil then
      info = filteredAnims[anim_index + 1]
    end

    ImGui.Separator(); manualFlags, used = ImGui.Checkbox("Edit Flags", manualFlags)
    if used then
      CFG.save("manualFlags", manualFlags)
      UI.widgetSound("Nav2")
    end
    UI.helpMarker(false, ANIM_FLAGS_DESC_)

    ImGui.SameLine(); disableProps, used = ImGui.Checkbox("Disable Props", disableProps)
    if used then
      CFG.save("disableProps", disableProps)
      UI.widgetSound("Nav2")
    end
    UI.helpMarker(false, ANIM_PROPS_DESC_)

    if manualFlags then
      controllable, controlUsed = ImGui.Checkbox(ANIM_CONTROL_CB_, controllable)
      if controlUsed then
        CFG.save("controllable", controllable)
        UI.widgetSound("Nav2")
      end
      UI.helpMarker(false, ANIM_CONTROL_DESC_)

      ImGui.SameLine(); ImGui.Dummy(27, 1); ImGui.SameLine()
      looped, loopUsed = ImGui.Checkbox("Loop", looped)
      if loopUsed then
        CFG.save("looped", looped)
        UI.widgetSound("Nav2")
      end
      UI.helpMarker(false, ANIM_LOOP_DESC_)

      upperbody, upperbodyUsed = ImGui.Checkbox(ANIM_UPPER_CB_, upperbody)
      if upperbodyUsed then
        CFG.save("upperbody", upperbody)
        UI.widgetSound("Nav2")
      end
      UI.helpMarker(false, ANIM_UPPER_DESC_)

      ImGui.SameLine(); ImGui.Dummy(1, 1); ImGui.SameLine()
      freeze, freezeUsed = ImGui.Checkbox(ANIM_FREEZE_CB_, freeze)
      if freezeUsed then
        CFG.save("freeze", freeze)
        UI.widgetSound("Nav2")
      end
      UI.helpMarker(false, ANIM_FREEZE_DESC_)

      noCollision, noCollUsed = ImGui.Checkbox(ANIM_NO_COLL_CB_, noCollision)
      if noCollUsed then
        CFG.save("noCollision", noCollision)
        UI.widgetSound("Nav2")
      end

      ImGui.SameLine(); ImGui.Dummy(35, 1); ImGui.SameLine()
      ImGui.BeginDisabled(looped)
      killOnEnd, koeUsed = ImGui.Checkbox(ANIM_KOE_CB_, killOnEnd)
      if koeUsed then
        CFG.save("killOnEnd", killOnEnd)
        UI.widgetSound("Nav2")
      end
      ImGui.EndDisabled()
      UI.helpMarker(false, ANIM_KOE_DESC_)
      ImGui.Separator()
    end
    if ImGui.Button(string.format("%s##anim", GENERIC_PLAY_BTN_)) then
      if not ped_grabbed and not vehicle_grabbed and not is_hiding and not is_sitting then
        UI.widgetSound("Select")
        script.run_in_fiber(function(pa)
          local coords     = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
          local heading    = ENTITY.GET_ENTITY_HEADING(self.get_ped())
          local forwardX   = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
          local forwardY   = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
          local boneIndex  = PED.GET_PED_BONE_INDEX(self.get_ped(), info.boneID)
          local bonecoords = PED.GET_PED_BONE_COORDS(self.get_ped(), info.boneID, 0.0, 0.0, 0.0)
          if manualFlags then
            anim_flag = setAnimFlags()
          else
            anim_flag = info.flag
          end
          playAnim(
            info, self.get_ped(), anim_flag, selfprop1, selfprop2, selfloopedFX, selfSexPed, boneIndex, coords, heading,
            forwardX, forwardY, bonecoords, plyrProps, selfPTFX, pa)
          is_playing_anim = true
          curr_playing_anim = info
          addActionToRecents(info)
        end)
      else
        UI.widgetSound("Error")
        gui.show_error("Samurais Scripts",
          "You can not play animations while grabbing an NPC, grabbing a vehicle, sitting or hiding.")
      end
    end
    ImGui.SameLine()
    ImGui.BeginDisabled(not is_playing_anim)
    if ImGui.Button(string.format("%s##anim", GENERIC_STOP_BTN_)) then
      if is_playing_anim then
        UI.widgetSound("Cancel")
        script.run_in_fiber(function(cu)
          cleanup(cu)
          is_playing_anim = false
        end)
      else
        UI.widgetSound("Error")
      end
    end
    UI.toolTip(false, ANIM_STOP_DESC_)
    ImGui.EndDisabled()
    ImGui.SameLine(); ImGui.Dummy(12, 1); ImGui.SameLine()
    local errCol = {}
    local errSound = false
    if plyrProps[1] ~= nil then
      errCol = { 104, 247, 114, 0.2 }
      errSound = false
    else
      errCol = { 225, 0, 0, 0.5 }
      errSound = true
    end
    if UI.coloredButton(ANIM_DETACH_BTN_, { 104, 247, 114 }, { 104, 247, 114 }, errCol, 0.6) then
      if not errSound then
        UI.widgetSound("Cancel")
      else
        UI.widgetSound("Error")
      end
      script.run_in_fiber(function(detachProps)
        if plyrProps[1] ~= nil then
          for k, v in ipairs(plyrProps) do
            if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(v, self.get_ped()) then
              ENTITY.DETACH_ENTITY(v, true, true)
              ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(v)
              table.remove(plyrProps, k)
            end
          end
        else
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
        end
        is_playing_anim = false
        if is_playing_scenario then
          stopScenario(self.get_ped(), detachProps)
        end
        if ped_grabbed then
          if attached_ped ~= 0 and ENTITY.DOES_ENTITY_EXIST(attached_ped) then
            ENTITY.FREEZE_ENTITY_POSITION(attached_ped, false)
            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(attached_ped, false)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(attached_ped, false)
            PED.SET_PED_TO_RAGDOLL(attached_ped, 1500, 0, 0, false, false, false)
            TASK.CLEAR_PED_TASKS(self.get_ped())
            PED.SET_PED_CAN_SWITCH_WEAPON(self.get_ped(), true)
          end
          ped_grabbed = false
        else
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
        end
      end)
    end
    UI.toolTip(false, ANIM_DETACH_DESC_)
    if info ~= nil then
      if shortcut_anim.name ~= info.name then
        if ImGui.Button(ANIM_HOTKEY_BTN_) then
          chosen_anim        = info
          is_setting_hotkeys = true
          UI.widgetSound("Select2")
          ImGui.OpenPopup("Set Shortcut")
        end
        UI.toolTip(false, ANIM_HOTKEY_DESC_)
        ImGui.SetNextWindowPos(760, 400, ImGuiCond.Appearing)
        ImGui.SetNextWindowBgAlpha(0.9)
        if ImGui.BeginPopupModal("Set Shortcut", true, ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
          UI.coloredText("Selected Animation:  ", "green", 0.9, 20); ImGui.SameLine(); ImGui.Text(string.format("« %s »",
            chosen_anim.name))
          ImGui.Dummy(1, 10)
          if btn_name == nil then
            start_loading_anim = true
            UI.coloredText(string.format("%s %s", INPUT_WAIT_TXT_, loading_label), "#FFFFFF", 0.75, 20)
            is_pressed, btn, btn_name = SS.isAnyKeyPressed()
          else
            start_loading_anim = false
            for _, key in pairs(reserved_keys_T.kb) do
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
              UI.coloredText(HOTKEY_RESERVED_, "red", 0.86, 20)
            end
            ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine()
            if UI.coloredButton(string.format("%s##shortcut", GENERIC_CLEAR_BTN_), "#FFDB58", "#FFFAA0", "#FFFFF0", 0.7) then
              UI.widgetSound("Error")
              btn, btn_name = nil, nil
            end
          end
          ImGui.Dummy(1, 10)
          if not _reserved and btn ~= nil then
            if ImGui.Button(string.format("%s##shortcut", GENERIC_CONFIRM_BTN_)) then
              UI.widgetSound("Select")
              if manualFlags then
                anim_flag = setAnimFlags()
              else
                anim_flag = chosen_anim.flag
              end
              shortcut_anim     = chosen_anim
              shortcut_anim.btn = btn
              CFG.save("shortcut_anim", shortcut_anim)
              gui.show_success("Samurais Scripts",
                string.format("%s %s %s", HOTKEY_SUCCESS1_, btn_name, HOTKEY_SUCCESS2_))
              btn, btn_name      = nil, nil
              is_setting_hotkeys = false
              ImGui.CloseCurrentPopup()
            end
            ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
          end
          if ImGui.Button(string.format("%s##shortcut", GENERIC_CANCEL_BTN_)) then
            UI.widgetSound("Cancel")
            btn, btn_name      = nil, nil
            start_loading_anim = false
            is_setting_hotkeys = false
            ImGui.CloseCurrentPopup()
          end
          ImGui.End()
        end
      else
        if ImGui.Button(ANIM_HOTKEY_DEL_) then
          UI.widgetSound("Delete")
          shortcut_anim = {}
          CFG.save("shortcut_anim", {})
          gui.show_success("Samurais Scripts", "Animation shortcut has been reset.")
        end
        UI.toolTip(false, DEL_HOTKEY_DESC_)
      end
      ImGui.SameLine(); ImGui.Dummy(4, 1); ImGui.SameLine()
      if favorite_actions[1] ~= nil then
        for _, v in ipairs(favorite_actions) do
          if info.name == v.name then
            fav_exists = true
            break
          else
            fav_exists = false
          end
        end
      else
        if fav_exists then
          fav_exists = false
        end
      end
      if not fav_exists then
        if ImGui.Button(string.format("%s##anims", ADD_TO_FAVS_)) then
          UI.widgetSound("Select")
          table.insert(favorite_actions, info)
          CFG.save("favorite_actions", favorite_actions)
        end
      else
        if ImGui.Button(REMOVE_FROM_FAVS_) then
          UI.widgetSound("Delete")
          for k, v in ipairs(favorite_actions) do
            if v == info then
              table.remove(favorite_actions, k)
            end
          end
          CFG.save("favorite_actions", favorite_actions)
        end
      end
    end
    ImGui.Spacing(); ImGui.SeparatorText(MVMT_OPTIONS_TXT_); ImGui.Spacing()
    jsonMvmt, jsonMvmtUsed = ImGui.Checkbox("Read From Json", jsonMvmt)
    UI.setClipBoard(
      "https://github.com/DurtyFree/gta-v-data-dumps/blob/master/movementClipsetsCompact.json",
      (ImGui.IsItemHovered() and SS.isKeyJustPressed(0x09))
    )
    UI.toolTip(
      false,
      "You have to place the file 'movementClipsetsCompact.json' inside the 'scripts_config' folder. Otherwise this will not do anything.\n\nYou can download the Json file from this GitHub link: https://github.com/DurtyFree/gta-v-data-dumps/blob/master/movementClipsetsCompact.json\n\nPress [TAB] to copy the link to clipboard."
    )
    if jsonMvmtUsed then
      UI.widgetSound("Nav2")
      mvmt_index = 0
      if jsonMvmt then
        if not io.exists("movementClipsetsCompact.json") then
          gui.show_error("Samurai's Scripts", "Json file not found!")
          jsonMvmt = false
        end
      end
    end
    displayMvmts()
    if UI.isItemClicked("lmb") then
      UI.widgetSound("Nav")
    end
    ImGui.BeginDisabled(currentMvmt == "")
    if ImGui.Button(GENERIC_RESET_BTN_) then
      UI.widgetSound("Cancel")
      mvmt_index = 0
      SS.resetMovement()
    end
    ImGui.EndDisabled()
    ImGui.Spacing(); ImGui.SeparatorText(NPC_ANIMS_TXT_)
    ImGui.PushItemWidth(220)
    displayNpcs()
    ImGui.PopItemWidth()
    if UI.isItemClicked("lmb") then
      UI.widgetSound("Nav2")
    end
    ImGui.SameLine()
    npc_godMode, ngodused = ImGui.Checkbox("Invincible", npc_godMode)
    if ngodused then
      CFG.save("npc_godMode", npc_godMode)
      UI.widgetSound("Nav")
      if spawned_npcs[1] ~= nil then
        script.run_in_fiber(function()
          for _, npc in ipairs(spawned_npcs) do
            if ENTITY.DOES_ENTITY_EXIST(npc) and not ENTITY.IS_ENTITY_DEAD(npc, true) then
              ENTITY.SET_ENTITY_INVINCIBLE(npc, npc_godMode)
            end
          end
        end)
      end
    end
    UI.toolTip(false, NPC_GODMODE_DESC_)
    if ImGui.Button(string.format("%s##anims_npc", GENERIC_SPAWN_BTN_)) then
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
    if ImGui.Button(string.format("%s##anim_npc", GENERIC_DELETE_BTN_)) then
      UI.widgetSound("Delete")
      script.run_in_fiber(function(cu)
        cleanupNPC(cu)
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
    if ImGui.Button(string.format("%s##anim_npc", GENERIC_PLAY_BTN_)) then
      if spawned_npcs[1] ~= nil then
        UI.widgetSound("Select")
        script.run_in_fiber(function(npca)
          for _, v in ipairs(spawned_npcs) do
            if ENTITY.DOES_ENTITY_EXIST(v) then
              local npcCoords      = ENTITY.GET_ENTITY_COORDS(v, false)
              local npcHeading     = ENTITY.GET_ENTITY_HEADING(v)
              local npcForwardX    = ENTITY.GET_ENTITY_FORWARD_X(v)
              local npcForwardY    = ENTITY.GET_ENTITY_FORWARD_Y(v)
              local npcBoneIndex   = PED.GET_PED_BONE_INDEX(v, info.boneID)
              local npcBboneCoords = PED.GET_PED_BONE_COORDS(v, info.boneID, 0.0, 0.0, 0.0)
              if manualFlags then
                anim_flag = setAnimFlags()
              else
                anim_flag = info.flag
              end
              playAnim(
                info, v, anim_flag, npcprop1, npcprop2, npcloopedFX, npcSexPed, npcBoneIndex, npcCoords, npcHeading,
                npcForwardX, npcForwardY, npcBboneCoords, npcProps, npcPTFX, npca
              )
            end
          end
        end)
      else
        UI.widgetSound("Error")
        gui.show_error("Samurais Scripts", "Spawn an NPC first!")
      end
    end
    ImGui.SameLine()
    if ImGui.Button(string.format("%s##npc_anim", GENERIC_STOP_BTN_)) then
      UI.widgetSound("Cancel")
      script.run_in_fiber(function(npca)
        cleanupNPC(npca)
      end)
    end
    usePlayKey, upkUsed = ImGui.Checkbox("Enable Animation Hotkeys", usePlayKey)
    UI.toolTip(false, ANIM_HOTKEYS_DESC_)
    if upkUsed then
      CFG.save("usePlayKey", usePlayKey)
      UI.widgetSound("Nav2")
    end
    ImGui.EndTabItem()
  end
  if ImGui.BeginTabItem(SCENARIOS_TAB_) then
    if tab2Sound then
      UI.widgetSound("Nav")
      tab2Sound = false
      tab1Sound = true
      tab3Sound = true
      tab4Sound = true
    end
    ImGui.PushItemWidth(420)
    displayFilteredScenarios()
    ImGui.PopItemWidth()
    if filteredScenarios ~= nil then
      data = filteredScenarios[scenario_index + 1]
    end
    ImGui.Separator()
    if ImGui.Button(string.format("%s##scenarios", GENERIC_PLAY_BTN_)) then
      if not ped_grabbed and not vehicle_grabbed and not is_hiding then
        UI.widgetSound("Select")
        script.run_in_fiber(function(psc)
          if Game.Self.isOnFoot() then
            if is_playing_anim then
              cleanup(psc)
            end
            playScenario(data, self.get_ped())
            addActionToRecents(data)
            is_playing_scenario = true
          else
            gui.show_error("Samurai's Scripts", "You can not play scenarios in vehicles.")
          end
        end)
      else
        gui.show_error("Samurais Scripts",
          "You can not play scenarios while grabbing an NPC, grabbing a vehicle or hiding.")
      end
    end
    ImGui.SameLine(); ImGui.Dummy(60, 1); ImGui.SameLine()
    if ImGui.Button(string.format("%s##scenarios", GENERIC_STOP_BTN_)) then
      if is_playing_scenario then
        UI.widgetSound("Cancel")
        script.run_in_fiber(function(stp)
          stopScenario(self.get_ped(), stp)
        end)
      else
        UI.widgetSound("Error")
      end
    end
    UI.toolTip(false, SCN_STOP_DESC_)
    ImGui.Spacing()
    if favorite_actions[1] ~= nil and filteredScenarios[1] ~= nil then
      for _, v in ipairs(favorite_actions) do
        if data.name == v.name then
          fav_exists = true
          break
        else
          fav_exists = false
        end
      end
    else
      if fav_exists then
        fav_exists = false
      end
    end
    if not fav_exists then
      if ImGui.Button(string.format("%s##favs", ADD_TO_FAVS_)) then
        UI.widgetSound("Select")
        table.insert(favorite_actions, data)
        CFG.save("favorite_actions", favorite_actions)
      end
    else
      if ImGui.Button(string.format("%s##favs", REMOVE_FROM_FAVS_)) then
        UI.widgetSound("Delete")
        for k, v in ipairs(favorite_actions) do
          if v == data then
            table.remove(favorite_actions, k)
          end
        end
        CFG.save("favorite_actions", favorite_actions)
      end
    end
    ImGui.Spacing(); ImGui.SeparatorText(NPC_SCENARIOS_)
    ImGui.PushItemWidth(220)
    displayNpcs()
    ImGui.PopItemWidth()
    ImGui.SameLine()
    npc_godMode, ngodused = ImGui.Checkbox("Invincible", npc_godMode)
    if ngodused then
      CFG.save("npc_godMode", npc_godMode)
      UI.widgetSound("Nav")
      if spawned_npcs[1] ~= nil then
        script.run_in_fiber(function()
          for _, npc in ipairs(spawned_npcs) do
            if ENTITY.DOES_ENTITY_EXIST(npc) and not ENTITY.IS_ENTITY_DEAD(npc, true) then
              ENTITY.SET_ENTITY_INVINCIBLE(npc, npc_godMode)
            end
          end
        end)
      end
    end
    UI.toolTip(false, NPC_GODMODE_DESC_)
    local npcData = filteredNpcs[npc_index + 1]
    if ImGui.Button(string.format("%s##scenario_npc", GENERIC_SPAWN_BTN_)) then
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
    if ImGui.Button(string.format("%s##scenarios", GENERIC_DELETE_BTN_)) then
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
    if ImGui.Button(string.format("%s##npc_scenarios", GENERIC_PLAY_BTN_)) then
      if spawned_npcs[1] ~= nil then
        UI.widgetSound("Select")
        script.run_in_fiber(function(npcsc)
          for _, npc in ipairs(spawned_npcs) do
            if PED.IS_PED_ON_FOOT(npc) then
              if is_playing_anim then
                cleanupNPC(npcsc)
                is_playing_anim = false
              end
              playScenario(data, npc)
              is_playing_scenario = true
            else
              gui.show_error("Samurai's Scripts", "Scenarios can not be played inside vehicles.")
            end
          end
        end)
      else
        UI.widgetSound("Error")
      end
    end
    ImGui.SameLine()
    if ImGui.Button(string.format("%s##npc_scenarios", GENERIC_STOP_BTN_)) then
      if is_playing_scenario then
        UI.widgetSound("Cancel")
        script.run_in_fiber(function(stp)
          for _, npc in ipairs(spawned_npcs) do
            stopScenario(npc, stp)
            is_playing_scenario = false
          end
        end)
      end
    end
    ImGui.EndTabItem()
  end
  if ImGui.BeginTabItem(FAVORITES_TAB_) then
    if tab3Sound then
      UI.widgetSound("Nav")
      tab3Sound = false
      tab1Sound = true
      tab2Sound = true
      tab4Sound = true
    end
    if favorite_actions[1] ~= nil then
      ImGui.PushItemWidth(420)
      displayFavoriteActions()
      ImGui.PopItemWidth()
      local selected_favorite = filteredFavs[fav_actions_index + 1]
      ImGui.Spacing()
      if ImGui.Button(string.format("%s##favs", GENERIC_PLAY_BTN_)) then
        if not ped_grabbed and not vehicle_grabbed and not is_hiding and not is_sitting then
          if selected_favorite.dict then -- anim type
            if selected_favorite.cat == "In-Vehicle" and (Game.Self.isOnFoot() or not is_car) then
              UI.widgetSound("Error")
              gui.show_error("Samurai's Scripts",
                "This animation can only be played while sitting inside a vehicle (cars and trucks only).")
            else
              UI.widgetSound("Select")
              script.run_in_fiber(function(pf)
                local coords     = self.get_pos()
                local heading    = Game.getHeading(self.get_ped())
                local forwardX   = Game.getForwardX(self.get_ped())
                local forwardY   = Game.getForwardY(self.get_ped())
                local boneIndex  = PED.GET_PED_BONE_INDEX(self.get_ped(), selected_favorite.boneID)
                local bonecoords = PED.GET_PED_BONE_COORDS(self.get_ped(), selected_favorite.boneID, 0.0, 0.0, 0.0)
                playAnim(
                  selected_favorite, self.get_ped(), selected_favorite.flag, selfprop1, selfprop2, selfloopedFX,
                  selfSexPed, boneIndex, coords, heading, forwardX, forwardY, bonecoords, plyrProps, selfPTFX, pf
                )
                curr_playing_anim = selected_favorite
                is_playing_anim   = true
              end)
            end
          elseif selected_favorite.scenario then -- scenario type
            UI.widgetSound("Select")
            playScenario(selected_favorite, self.get_ped())
            is_playing_scenario = true
          end
          addActionToRecents(selected_favorite)
        else
          UI.widgetSound("Error")
          gui.show_error("Samurais Scripts",
            "You can not play animations while grabbing an NPC, grabbing a vehicle, sitting or hiding.")
        end
      end
      ImGui.SameLine(); ImGui.Dummy(40, 1); ImGui.SameLine()
      if ImGui.Button(string.format("%s##favs", GENERIC_STOP_BTN_)) then
        UI.widgetSound("Cancel")
        script.run_in_fiber(function(fav)
          if is_playing_anim then
            cleanup(fav)
            is_playing_anim = false
          elseif is_playing_scenario then
            stopScenario(self.get_ped(), fav)
            is_playing_scenario = false
          end
        end)
      end
      ImGui.SameLine(); ImGui.Dummy(37, 1); ImGui.SameLine()
      if UI.coloredButton(string.format("%s##favs", REMOVE_FROM_FAVS_), "#FF0000", "#B30000", "#FF8080", 1) then
        UI.widgetSound("Delete")
        for k, v in ipairs(favorite_actions) do
          if v == selected_favorite then
            table.remove(favorite_actions, k)
          end
        end
        CFG.save("favorite_actions", favorite_actions)
      end
    else
      ImGui.Dummy(1, 5)
      UI.wrappedText(FAVS_NIL_TXT_, 20)
    end
    ImGui.EndTabItem()
  end
  if ImGui.BeginTabItem(RECENTS_TAB_) then
    if tab4Sound then
      UI.widgetSound("Nav")
      tab4Sound = false
      tab1Sound = true
      tab2Sound = true
      tab3Sound = true
    end
    if recently_played_a[1] ~= nil then
      ImGui.PushItemWidth(420)
      displayRecentlyPlayed()
      ImGui.PopItemWidth()
      local selected_recent = filteredRecents[recents_index + 1]
      if ImGui.Button(string.format("%s##recents", GENERIC_PLAY_BTN_)) then
        if not ped_grabbed and not vehicle_grabbed and not is_hiding and not is_sitting then
          if selected_recent.dict ~= nil then -- animation type
            if selected_recent.cat == "In-Vehicle" and (Game.Self.isOnFoot() or not is_car) then
              UI.widgetSound("Error")
              gui.show_error("Samurai's Scripts",
                "This animation can only be played while sitting inside a vehicle (cars and trucks only).")
            else
              UI.widgetSound("Select")
              script.run_in_fiber(function(pr)
                local coords     = self.get_pos()
                local heading    = Game.getHeading(self.get_ped())
                local forwardX   = Game.getForwardX(self.get_ped())
                local forwardY   = Game.getForwardY(self.get_ped())
                local boneIndex  = PED.GET_PED_BONE_INDEX(self.get_ped(), selected_recent.boneID)
                local bonecoords = PED.GET_PED_BONE_COORDS(self.get_ped(), selected_recent.boneID, 0.0, 0.0, 0.0)
                playAnim(
                  selected_recent, self.get_ped(), selected_recent.flag, selfprop1, selfprop2, selfloopedFX, selfSexPed,
                  boneIndex, coords, heading, forwardX, forwardY, bonecoords, plyrProps, selfPTFX, pr
                )
                curr_playing_anim = selected_recent
                is_playing_anim   = true
              end)
            end
          elseif selected_recent.scenario ~= nil then -- scenario type
            UI.widgetSound("Select")
            playScenario(selected_recent, self.get_ped())
            is_playing_scenario = true
          end
        else
          UI.widgetSound("Error")
          gui.show_error("Samurais Scripts",
            "You can not play animations while grabbing an NPC, grabbing a vehicle, sitting or hiding.")
        end
      end
      ImGui.SameLine(); ImGui.Dummy(40, 1); ImGui.SameLine()
      if ImGui.Button(string.format("%s##recents", GENERIC_STOP_BTN_)) then
        UI.widgetSound("Cancel")
        script.run_in_fiber(function(recent)
          if is_playing_anim then
            cleanup(recent)
            is_playing_anim = false
          elseif is_playing_scenario then
            stopScenario(self.get_ped(), recent)
            is_playing_scenario = false
          end
        end)
      end
    else
      ImGui.Dummy(1, 5); UI.wrappedText(RECENTS_NIL_TXT_, 20)
    end
    ImGui.EndTabItem()
  end
  ImGui.EndTabBar()
end
