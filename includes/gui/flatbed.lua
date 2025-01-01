---@diagnostic disable

function flatbedUI()
  local window_size_x, _ = ImGui.GetWindowSize()
  local vehicleHandles   = entities.get_all_vehicles_as_handles()
  local flatbedModel     = 1353720154
  local vehicle_model    = Game.getEntityModel(current_vehicle)
  local playerPosition   = self.get_pos()
  local flatbedPosition  = ENTITY.GET_ENTITY_COORDS(current_vehicle, true)
  local flatbedForwardX  = Game.getForwardX(current_vehicle)
  local flatbedForwardY  = Game.getForwardY(current_vehicle)
  for _, veh in ipairs(vehicleHandles) do
    script.run_in_fiber(function(detector)
      local detectPos = vec3:new(flatbedPosition.x - (flatbedForwardX * 10), flatbedPosition.y - (flatbedForwardY * 10),
        flatbedPosition.z)
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
  local closestVehicleModel = 0
  if closestVehicle ~= nil then
    closestVehicleModel = Game.getEntityModel(closestVehicle)
  end
  local iscar              = VEHICLE.IS_THIS_MODEL_A_CAR(closestVehicleModel)
  local isbike             = VEHICLE.IS_THIS_MODEL_A_BIKE(closestVehicleModel)
  local closestVehicleName = vehicles.get_vehicle_display_name(closestVehicleModel)
  if vehicle_model == flatbedModel then
    is_in_flatbed = true
  else
    is_in_flatbed = false
  end
  if closestVehicleName == "" then
    displayText = FLTBD_NO_VEH_TXT_
  elseif tostring(closestVehicleName) == "Flatbed" then
    displayText = FLTBD_NOT_ALLOWED_TXT_
  else
    displayText = string.format("%s %s", FLTBD_NEARBY_VEH_TXT_, closestVehicleName)
  end
  if towed_vehicle ~= 0 then
    displayText = string.format("%s %s.", FLTBD_TOWING_TXT_,
      vehicles.get_vehicle_display_name(ENTITY.GET_ENTITY_MODEL(towed_vehicle)))
  end
  if fb_model_override then
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
    ImGui.Dummy(1, 10); ImGui.SeparatorText(displayText)
    ImGui.Dummy(1, 10);
    ImGui.BeginDisabled(not Game.Self.isDriving() or towed_vehicle ~= 0)
    towPos, towPosUsed = ImGui.Checkbox(FLTBD_SHOW_TOWPOS_CB_, towPos)
    ImGui.EndDisabled()
    UI.helpMarker(false, FLTBD_SHOW_TOWPOS_DESC_)
    if towPosUsed then
      UI.widgetSound("Nav2")
    end

    towEverything, towEverythingUsed = ImGui.Checkbox(FLTBD_TOW_ALL_CB_, towEverything)
    UI.helpMarker(false, FLTBD_TOW_ALL_DESC_)
    if towEverythingUsed then
      UI.widgetSound("Nav2")
      CFG.save("towEverything", towEverything)
    end
    if towEverything then
      fb_model_override = true
    else
      fb_model_override = false
    end

    ImGui.Dummy(1, 10); ImGui.Dummy((window_size_x // 2) - 65, 1); ImGui.SameLine()
    if towed_vehicle == 0 then
      if ImGui.Button(FLTBD_TOW_BTN_, 80, 40) then
        UI.widgetSound("Select")
        if towable and closestVehicle ~= nil and closestVehicleModel ~= flatbedModel then
          script.run_in_fiber(function()
            if entities.take_control_of(closestVehicle, 300) then
              flatbedHeading     = ENTITY.GET_ENTITY_HEADING(current_vehicle)
              flatbedBone        = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, "chassis_dummy")
              vehBone            = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(closestVehicle, "chassis_dummy")
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
              ENTITY.ATTACH_ENTITY_TO_ENTITY(closestVehicle, current_vehicle, flatbedBone, tow_xAxis, tow_yAxis,
                tow_zAxis, 0.0, 0.0,
                0.0, true, true, false, false, 1, true, 1)
              towed_vehicle = closestVehicle
              ENTITY.SET_ENTITY_CANT_CAUSE_COLLISION_DAMAGED_ENTITY(towed_vehicle, current_vehicle)
            else
              gui.show_error("Samurais Scripts", VEH_CTRL_FAIL_)
            end
          end)
        end
        if closestVehicle ~= nil and closestVehicleModel ~= flatbedModel and not towable then
          gui.show_message("Samurais Scripts", FLTBD_CARS_ONLY_TXT_)
        end
        if closestVehicle ~= nil and closestVehicleModel == flatbedModel then
          gui.show_message("Samurais Scripts", FLTBD_NOT_ALLOWED_TXT_)
        end
      end
    else
      if ImGui.Button(GENERIC_DETACH_BTN_, 80, 40) then
        UI.widgetSound("Select2")
        script.run_in_fiber(function()
          local modelHash         = ENTITY.GET_ENTITY_MODEL(towed_vehicle)
          local attachedVehicle   = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(current_vehicle, modelHash)
          local attachedVehcoords = ENTITY.GET_ENTITY_COORDS(towed_vehicle, false)
          local controlled        = entities.take_control_of(attachedVehicle, 300)
          if ENTITY.DOES_ENTITY_EXIST(attachedVehicle) then
            if controlled then
              ENTITY.DETACH_ENTITY(attachedVehicle, true, true)
              ENTITY.SET_ENTITY_COORDS(attachedVehicle, attachedVehcoords.x - (flatbedForwardX * 10),
                attachedVehcoords.y - (flatbedForwardY * 10), flatbedPosition.z, false, false, false, false)
              VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(towed_vehicle, 5.0)
              towed_vehicle = 0
            end
          end
        end)
      end
      ImGui.Dummy(1, 5); ImGui.SeparatorText(FLTBD_ADJUST_POS_TXT_)
      UI.toolTip(false, FLTBD_ADJUST_POS_DESC_)
      ImGui.Spacing(); ImGui.Dummy((window_size_x // 2) - 40, 1); ImGui.SameLine()
      ImGui.ArrowButton("##Up", 2)
      if ImGui.IsItemActive() then
        tow_zAxis = tow_zAxis + 0.01
        ENTITY.ATTACH_ENTITY_TO_ENTITY(towed_vehicle, current_vehicle, flatbedBone, tow_xAxis, tow_yAxis, tow_zAxis,
          0.0, 0.0, 0.0,
          true, true, false, false, 1, true, 1)
      end
      ImGui.Dummy((window_size_x // 2) - 80, 1); ImGui.SameLine()
      ImGui.ArrowButton("##Left", 0)
      if ImGui.IsItemActive() then
        tow_yAxis = tow_yAxis + 0.01
        ENTITY.ATTACH_ENTITY_TO_ENTITY(towed_vehicle, current_vehicle, flatbedBone, tow_xAxis, tow_yAxis, tow_zAxis,
          0.0, 0.0, 0.0,
          true, true, false, false, 1, true, 1)
      end
      ImGui.SameLine(); ImGui.Dummy(23, 1); ImGui.SameLine()
      ImGui.ArrowButton("##Right", 1)
      if ImGui.IsItemActive() then
        tow_yAxis = tow_yAxis - 0.01
        ENTITY.ATTACH_ENTITY_TO_ENTITY(towed_vehicle, current_vehicle, flatbedBone, tow_xAxis, tow_yAxis, tow_zAxis,
          0.0, 0.0, 0.0,
          true, true, false, false, 1, true, 1)
      end
      ImGui.Dummy((window_size_x // 2) - 40, 1); ImGui.SameLine()
      ImGui.ArrowButton("##Down", 3)
      if ImGui.IsItemActive() then
        tow_zAxis = tow_zAxis - 0.01
        ENTITY.ATTACH_ENTITY_TO_ENTITY(towed_vehicle, current_vehicle, flatbedBone, tow_xAxis, tow_yAxis, tow_zAxis,
          0.0, 0.0, 0.0,
          true, true, false, false, 1, true, 1)
      end
    end
  else
    UI.wrappedText(GET_IN_FLATBED_, 20)
    if ImGui.Button(SPAWN_FLATBED_BTN_) then
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
            gui.show_error("Samurais Scripts", FLTBD_INTERIOR_ERROR_)
          end
        else
          gui.show_error("Samurais Scripts", FLTBD_EXIT_VEH_ERROR_)
        end
      end)
    end
  end
end
