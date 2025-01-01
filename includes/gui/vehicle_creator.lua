---@ diagnostic disable

function vCreatorUI()
  ImGui.Dummy(1, 10)
  persist_switch, pswChanged = ImGui.RadioButton(CREATE_TXT_, persist_switch, 0)
  UI.helpMarker(false, CREATOR_DESC_)
  if pswChanged then
    UI.widgetSound("Nav")
  end
  if saved_vehicles[1] ~= nil then
    ImGui.SameLine(); ImGui.Dummy(40, 1); ImGui.SameLine(); persist_switch, pswChanged = ImGui.RadioButton(
      SAVED_VEHS_TXT_, persist_switch, 1)
    if pswChanged then
      UI.widgetSound("Nav")
    end
  else
    ImGui.BeginDisabled()
    ImGui.SameLine(); ImGui.Dummy(40, 1); ImGui.SameLine(); persist_switch, pswChanged = ImGui.RadioButton(
      SAVED_VEHS_TXT_, persist_switch, 1)
    ImGui.EndDisabled()
    UI.toolTip(false, SAVED_VEHS_DESC_)
  end
  if persist_switch == 0 then
    ImGui.Spacing()
    ImGui.PushItemWidth(350)
    vCreator_searchQ, used = ImGui.InputTextWithHint("##searchVehicles", GENERIC_SEARCH_HINT_, vCreator_searchQ,
      32)
    ImGui.PopItemWidth()
    is_typing = ImGui.IsItemActive()
    ImGui.PushItemWidth(350)
    displayFilteredList()
    ImGui.PopItemWidth()
    ImGui.Separator()
    if filtered_vehicles[1] ~= nil then
      vehicleHash = filtered_vehicles[vehicle_index + 1].hash
      vehicleName = filtered_vehicles[vehicle_index + 1].name
    end
    if ImGui.Button(string.format("   %s   ##vehcreator", GENERIC_SPAWN_BTN_)) then
      UI.widgetSound("Select")
      script.run_in_fiber(function()
        local plyrCoords   = self.get_pos()
        local plyrForwardX = Game.getForwardX(self.get_ped())
        local plyrForwardY = Game.getForwardY(self.get_ped())
        if Game.requestModel(vehicleHash) then
          spawned_vehicle = VEHICLE.CREATE_VEHICLE(vehicleHash, plyrCoords.x + (plyrForwardX * 5),
            plyrCoords.y + (plyrForwardY * 5), plyrCoords.z, (ENTITY.GET_ENTITY_HEADING(self.get_ped()) + 90), true,
            false, false)
          VEHICLE.SET_VEHICLE_IS_STOLEN(spawned_vehicle, false)
          DECORATOR.DECOR_SET_INT(spawned_vehicle, "MPBitset", 0)
          if main_vehicle == 0 then
            main_vehicle      = spawned_vehicle
            main_vehicle_name = vehicles.get_vehicle_display_name(ENTITY.GET_ENTITY_MODEL(main_vehicle))
          else
            table.insert(spawned_vehicles, spawned_vehicle)
            table.insert(spawned_vehNames, vehicleName)
            local dupes = Lua_fn.getTableDupes(spawned_vehNames, vehicleName)
            if dupes > 1 then
              newVehName = string.format("%s #%d", vehicleName, dupes)
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
      if ImGui.Button(VC_DEMO_VEH_BTN_) then
        UI.widgetSound("Select")
        createWideBodyCivic()
        spawnPersistVeh(saved_vehicles[1].main_veh, saved_vehicles[1].mods, saved_vehicles[1].color_1,
          saved_vehicles[1].color_2, saved_vehicles[1].tint, saved_vehicles[1].attachments)
      end
      UI.toolTip(false, VC_DEMO_VEH_DESC_)
    end
    if main_vehicle ~= 0 then
      ImGui.Separator()
      UI.coloredText(VC_MAIN_VEH_TXT_, 'green', 0.9, 20); ImGui.SameLine(); ImGui.Text(main_vehicle_name); ImGui
          .SameLine()
      if ImGui.Button(string.format(" %s ##mainVeh", GENERIC_DELETE_BTN_)) then
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
      ImGui.SeparatorText(VC_SPAWNED_VEHS_TXT_)
      ImGui.PushItemWidth(230)
      spawned_veh_index, _ = ImGui.Combo("##Spawned Vehicles", spawned_veh_index, filteredVehNames, #spawned_vehicles)
      ImGui.PopItemWidth()
      selectedVeh = spawned_vehicles[spawned_veh_index + 1]
      ImGui.SameLine()
      if ImGui.Button(string.format("   %s   ##spawnedVeh", GENERIC_DELETE_BTN_)) then
        UI.widgetSound("Delete")
        script.run_in_fiber(function(del)
          if entities.take_control_of(selectedVeh, 300) then
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(selectedVeh, true, true)
            del:sleep(200)
            VEHICLE.DELETE_VEHICLE(selectedVeh)
            -- vehicle_creation = {}
            creation_name    = ""
            attached_vehicle = 0
            if spawned_veh_index ~= 0 then
              spawned_veh_index = 0
            end
            if attachment_index ~= 0 then
              attachment_index = 0
            end
          else
            gui.show_error("Samurais Scripts", GENERIC_VEH_DELETE_ERROR_)
          end
        end)
      end
      if ImGui.Button(string.format("%s%s", VC_ATTACH_BTN_, main_vehicle_name)) then
        if selectedVeh ~= main_vehicle then
          script.run_in_fiber(function()
            if not ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(selectedVeh, main_vehicle) then
              UI.widgetSound("Select")
              ENTITY.ATTACH_ENTITY_TO_ENTITY(selectedVeh, main_vehicle,
                ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), veh_attach_X, veh_attach_Y,
                veh_attach_Z, veh_attach_RX, veh_attach_RY, veh_attach_RZ, false, false, false,
                false,
                2, true, 1)
              attached_vehicles.entity                                                              = selectedVeh
              attached_vehicles.hash                                                                = ENTITY
                  .GET_ENTITY_MODEL(selectedVeh)
              attached_vehicles.name                                                                = vehicles
                  .get_vehicle_display_name(ENTITY.GET_ENTITY_MODEL(selectedVeh))
              attached_vehicles.posx                                                                = veh_attach_X
              attached_vehicles.posy                                                                = veh_attach_Y
              attached_vehicles.posz                                                                = veh_attach_Z
              attached_vehicles.rotx                                                                = veh_attach_RX
              attached_vehicles.roty                                                                = veh_attach_RY
              attached_vehicles.rotz                                                                = veh_attach_RZ
              attached_vehicles.tint                                                                = VEHICLE
                  .GET_VEHICLE_WINDOW_TINT(selectedVeh)
              attached_vehicles.color_1.r, attached_vehicles.color_1.g, attached_vehicles.color_1.b = VEHICLE
                  .GET_VEHICLE_CUSTOM_PRIMARY_COLOUR(selectedVeh, attached_vehicles.color_1.r,
                    attached_vehicles.color_1.g,
                    attached_vehicles.color_1.b)
              attached_vehicles.color_2.r, attached_vehicles.color_2.g, attached_vehicles.color_2.b = VEHICLE
                  .GET_VEHICLE_CUSTOM_SECONDARY_COLOUR(selectedVeh, attached_vehicles.color_2.r,
                    attached_vehicles.color_2.g,
                    attached_vehicles.color_2.b)
              appendVehicleMods(selectedVeh, attached_vehicles.mods)
              table.insert(veh_attachments, attached_vehicles)
              attached_vehicles = { entity = 0, hash = 0, mods = {}, color_1 = { r = 0, g = 0, b = 0 }, color_2 = { r = 0, g = 0, b = 0 }, tint = 0, posx = 0.0, posy = 0.0, posz = 0.0, rotx = 0.0, roty = 0.0, rotz = 0.0 }
            else
              UI.widgetSound("Error")
              gui.show_error("Samurais Scripts", VC_ALREADY_ATTACHED_)
            end
          end)
        else
          UI.widgetSound("Error")
          gui.show_error("Samurais Scripts", VC_SELF_ATTACH_ERR_)
        end
      end
    end
    if veh_attachments[1] ~= nil then
      ImGui.Spacing(); ImGui.SeparatorText("Attached Vehicles")
      ImGui.PushItemWidth(230)
      showAttachedVehicles()
      ImGui.PopItemWidth()
      selected_attchmnt = veh_attachments[attachment_index + 1]
      ImGui.Text(GENERIC_MULTIPLIER_LABEL_)
      ImGui.PushItemWidth(271)
      veh_axisMult, _ = ImGui.InputInt("##AttachMultiplier", veh_axisMult, 1, 2)
      ImGui.PopItemWidth()
      ImGui.Spacing()
      ImGui.Text("X Axis :"); ImGui.SameLine(); ImGui.Dummy(25, 1); ImGui.SameLine(); ImGui.Text("Y Axis :"); ImGui
          .SameLine()
      ImGui.Dummy(25, 1); ImGui.SameLine(); ImGui.Text("Z Axis :")
      ImGui.ArrowButton("##Xleft", 0)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.posx = selected_attchmnt.posx + 0.001 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx,
          selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false,
          false,
          false,
          2, true, 1)
      end
      ImGui.SameLine()
      ImGui.ArrowButton("##XRight", 1)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.posx = selected_attchmnt.posx - 0.001 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx,
          selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false,
          false,
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
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx,
          selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false,
          false,
          false,
          2, true, 1)
      end
      ImGui.SameLine()
      ImGui.ArrowButton("##YRight", 1)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.posy = selected_attchmnt.posy - 0.001 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx,
          selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false,
          false,
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
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx,
          selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false,
          false,
          false,
          2, true, 1)
      end
      ImGui.SameLine()
      ImGui.ArrowButton("##zDown", 3)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.posz = selected_attchmnt.posz - 0.001 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx,
          selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false,
          false,
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
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx,
          selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false,
          false,
          false,
          2, true, 1)
      end
      ImGui.SameLine()
      ImGui.ArrowButton("##rotXright", 1)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.rotx = selected_attchmnt.rotx - 0.01 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx,
          selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false,
          false,
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
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx,
          selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false,
          false,
          false,
          2, true, 1)
      end
      ImGui.SameLine()
      ImGui.ArrowButton("##rotYright", 1)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.roty = selected_attchmnt.roty - 0.01 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx,
          selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false,
          false,
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
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx,
          selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false,
          false,
          false,
          2, true, 1)
      end
      ImGui.SameLine()
      ImGui.ArrowButton("##rotZdown", 3)
      if ImGui.IsItemActive() then
        UI.widgetSound("Nav")
        selected_attchmnt.rotz = selected_attchmnt.rotz - 0.01 * veh_axisMult
        ENTITY.ATTACH_ENTITY_TO_ENTITY(selected_attchmnt.entity, main_vehicle,
          ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(main_vehicle, "chassis_dummy"), selected_attchmnt.posx,
          selected_attchmnt.posy,
          selected_attchmnt.posz, selected_attchmnt.rotx, selected_attchmnt.roty, selected_attchmnt.rotz, false, false,
          false,
          false,
          2, true, 1)
      end
      ImGui.Spacing()
      if ImGui.Button(string.format("   %s   ##vehcreator1", GENERIC_SAVE_BTN_)) then
        UI.widgetSound("Select2")
        ImGui.OpenPopup("Save Merged Vehicles")
      end
      ImGui.SetNextWindowPos(760, 400, ImGuiCond.Appearing)
      ImGui.SetNextWindowBgAlpha(0.81)
      if ImGui.BeginPopupModal("Save Merged Vehicles", ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
        creation_name, _ = ImGui.InputTextWithHint(
          "##save_merge", VC_NAME_HINT_, creation_name, 128
        )
        is_typing = ImGui.IsItemActive(); ImGui.Spacing()
        if not start_loading_anim then
          if ImGui.Button(string.format("%s##vehcreator2", GENERIC_SAVE_BTN_)) then
            script.run_in_fiber(function(save)
              if creation_name ~= "" then
                if saved_vehicles[1] ~= nil then
                  for _, v in pairs(saved_vehicles) do
                    if creation_name == v.name then
                      UI.widgetSound("Error")
                      gui.show_error("Samurai's Scripts", VC_NAME_ERROR_)
                      return
                    end
                  end
                end
                UI.widgetSound("Select")
                vehicle_creation.name                                                              = creation_name
                vehicle_creation.main_veh                                                          = ENTITY
                    .GET_ENTITY_MODEL(main_vehicle)
                vehicle_creation.attachments                                                       = veh_attachments
                vehicle_creation.tint                                                              = VEHICLE
                    .GET_VEHICLE_WINDOW_TINT(main_vehicle)
                vehicle_creation.color_1.r, vehicle_creation.color_1.g, vehicle_creation.color_1.b = VEHICLE
                    .GET_VEHICLE_CUSTOM_PRIMARY_COLOUR(main_vehicle, vehicle_creation.color_1.r,
                      vehicle_creation.color_1.g,
                      vehicle_creation.color_1.b)
                vehicle_creation.color_2.r, vehicle_creation.color_2.g, vehicle_creation.color_2.b = VEHICLE
                    .GET_VEHICLE_CUSTOM_SECONDARY_COLOUR(main_vehicle, vehicle_creation.color_2.r,
                      vehicle_creation.color_2
                      .g, vehicle_creation.color_2.b)
                appendVehicleMods(main_vehicle, vehicle_creation.mods)
                start_loading_anim = true
                save:sleep(500)
                table.insert(saved_vehicles, vehicle_creation)
                CFG.save("saved_vehicles", saved_vehicles)
                ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(main_vehicle)
                for _, veh in ipairs(spawned_vehicles) do
                  ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(veh)
                end
                gui.show_success("Samurais Scripts", VC_SAVE_SUCCESS_)
                resetOnSave()
                start_loading_anim = false
                ImGui.CloseCurrentPopup()
              else
                UI.widgetSound("Error")
                gui.show_warning("Samurais Scripts", VC_SAVE_ERROR_)
              end
            end)
          end
        else
          ImGui.BeginDisabled()
          ImGui.Button(string.format("  %s  ", loading_label))
          ImGui.EndDisabled()
        end
        ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
        if ImGui.Button(string.format("%s##vehcreator", GENERIC_CANCEL_BTN_)) then
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
      if ImGui.Button(string.format("%s##vehcreator", VC_SPAWN_PERSISTENT_)) then
        UI.widgetSound("Select")
        spawnPersistVeh(persist_info.main_veh, persist_info.mods, persist_info.color_1, persist_info.color_2,
          persist_info.tint, persist_info.attachments)
      end
      ImGui.SameLine(); ImGui.Dummy(5, 1); ImGui.SameLine()
      if UI.coloredButton(VC_DELETE_PERSISTENT_, "#E40000", "#FF3F3F", "#FF8080", 0.87) then
        UI.widgetSound("Focus_In")
        ImGui.OpenPopup("Remove Persistent")
      end
      ImGui.SetNextWindowPos(760, 400, ImGuiCond.Appearing)
      ImGui.SetNextWindowSizeConstraints(200, 100, 400, 400)
      ImGui.SetNextWindowBgAlpha(0.7)
      if ImGui.BeginPopupModal("Remove Persistent", ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
        UI.coloredText(CONFIRM_PROMPT_, "yellow", 0.91, 35)
        ImGui.Dummy(1, 20)
        if ImGui.Button(string.format("   %s   ##vehcreator", GENERIC_YES_)) then
          for key, value in ipairs(saved_vehicles) do
            if persist_info == value then
              table.remove(saved_vehicles, key)
              CFG.save("saved_vehicles", saved_vehicles)
            end
          end
          if saved_vehicles[1] == nil then
            persist_switch = 0
          end
          UI.widgetSound("Select")
          ImGui.CloseCurrentPopup()
          gui.show_success("Samurais Scripts", VC_DELETE_NOTIF_)
        end
        ImGui.SameLine(); ImGui.Dummy(20, 1); ImGui.SameLine()
        if ImGui.Button(string.format("   %s   ##vehcreator", GENERIC_NO_)) then
          UI.widgetSound("Cancel")
          ImGui.CloseCurrentPopup()
        end
        ImGui.End()
      end
    end
  end
end
