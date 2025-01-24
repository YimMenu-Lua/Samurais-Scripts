---@diagnostic disable

function handingEditorUI()
  ImGui.Spacing(); noEngineBraking, nebrUsed = ImGui.Checkbox("Disable Engine Braking", noEngineBraking)
  UI.toolTip(false, NOENGINEBRAKING_DESC_)
  if nebrUsed then
    UI.widgetSound("Nav2")
    CFG.save("noEngineBraking", noEngineBraking)
    if not noEngineBraking then
      if engine_brake_disabled then
        SS.setHandlingFlag(HF._FREEWHEEL_NO_GAS, false)
      end
    end
  end

  ImGui.SameLine(); ImGui.Dummy(37, 1); ImGui.SameLine();
  kersBoost, kbUsed = ImGui.Checkbox("KERS Boost", kersBoost)
  UI.toolTip(false, KERSBOOST_DESC_)
  if kbUsed then
    UI.widgetSound("Nav2")
    CFG.save("kersBoost", kersBoost)
    if not kersBoost then
      if kers_boost_enabled then
        SS.setHandlingFlag(HF._HAS_KERS, false)
        script.run_in_fiber(function()
          if VEHICLE.GET_VEHICLE_HAS_KERS(current_vehicle) then
            VEHICLE.SET_VEHICLE_KERS_ALLOWED(current_vehicle, false)
          end
        end)
      end
    end
  end

  offroaderx2, offroadrUsed = ImGui.Checkbox("Better Offroad Capabilities", offroaderx2)
  UI.toolTip(false, OFFROADERX2_DESC_)
  if offroadrUsed then
    UI.widgetSound("Nav2")
    CFG.save("offroaderx2", offroaderx2)
    if not offroaderx2 then
      if offroader_enabled then
        SS.setHandlingFlag(HF._OFFROAD_ABILITIES_X2, false)
      end
    end
  end

  ImGui.SameLine(); ImGui.Dummy(15, 1); ImGui.SameLine();
  rallyTires, rallytiresUsed = ImGui.Checkbox("Rally Tires", rallyTires)
  UI.toolTip(false, RALLYTIRES_DESC_)
  if rallytiresUsed then
    UI.widgetSound("Nav2")
    CFG.save("rallyTires", rallyTires)
    if not rallyTires then
      if rally_tires_enabled then
        SS.setHandlingFlag(HF._HAS_RALLY_TYRES, false)
      end
    end
  end

  noTractionCtrl, notcUsed = ImGui.Checkbox("Force No Traction Control", noTractionCtrl)
  UI.toolTip(false, FORCE_NO_TC_DESC_)
  if notcUsed then
    UI.widgetSound("Nav2")
    CFG.save("noTractionCtrl", noTractionCtrl)
    if not noTractionCtrl then
      if traction_ctrl_disabled and (is_bike or is_quad) then
        SS.setHandlingFlag(HF._FORCE_NO_TC_OR_SC, false)
      end
    end
  end

  ImGui.SameLine(); ImGui.Dummy(20, 1); ImGui.SameLine();
  easyWheelie, ezwUsed = ImGui.Checkbox("Easy Wheelie", easyWheelie)
  UI.toolTip(false, EASYWHEELIE_DESC_)
  if ezwUsed then
    UI.widgetSound("Nav2")
    CFG.save("easyWheelie", easyWheelie)
    if not easyWheelie then
      if easy_wheelie_enabled and (is_bike or is_quad) then
        SS.setHandlingFlag(HF._LOW_SPEED_WHEELIES, false)
      end
    end
  end

  ImGui.Spacing(); ImGui.SeparatorText("MISC")
  if self.get_veh() ~= 0 then
    rocketBoost, rbUsed = ImGui.Checkbox("Rocket Boost", SS.getVehicleModelFlag(VMF._HAS_ROCKET_BOOST))
    UI.toolTip(false, ROCKET_BOOST_DESC_)
    if rbUsed and (is_car or is_bike or is_quad) then
      UI.widgetSound("Nav2")
      SS.setVehicleModelFlag(VMF._HAS_ROCKET_BOOST, rocketBoost)
      if not Game.Vehicle.isElectric() then
        script.run_in_fiber(function()
          if not rocketBoost and (is_car or is_bike or is_quad) then
            STREAMING.REMOVE_NAMED_PTFX_ASSET("veh_impexp_rocket")
          else
            Game.requestNamedPtfxAsset("veh_impexp_rocket")
          end
        end)
      end
    end
  
    ImGui.SameLine(); ImGui.Dummy(40, 1); ImGui.SameLine();
    vehJump, vjUsed = ImGui.Checkbox("Vehicle Jump", SS.getVehicleModelFlag(VMF._JUMPING_CAR))
    UI.toolTip(false, VEH_JUMP_DESC_)
    if vjUsed then
      UI.widgetSound("Nav2")
      if (is_car or is_bike or is_quad) then
        SS.setVehicleModelFlag(VMF._JUMPING_CAR, vehJump)
        script.run_in_fiber(function()
          VEHICLE.SET_USE_HIGHER_CAR_JUMP(current_vehicle, vehJump)
        end)
      end
    end
  
    if vehJump then
      ImGui.SameLine(); ImGui.Dummy(28, 1); ImGui.SameLine(); ImGui.BeginDisabled(not is_car)
      vehChute, vehChuteUsed = ImGui.Checkbox("Parachute", SS.getVehicleModelFlag(VMF._HAS_PARACHUTE))
      ImGui.EndDisabled()
      UI.toolTip(false, VEH_PARACHUTE_DESC_)
      if vehChuteUsed then
        UI.widgetSound("Nav2")
        if is_car then
          SS.setVehicleModelFlag(VMF._HAS_PARACHUTE, vehChute)
        end
      end
    else
      if vehChute then
        vehChute = false
      end
    end

    rwSteering, rwstrUsed = ImGui.Checkbox("Rear Wheel Steering", SS.getVehicleHandlingFlag(HF._STEER_REARWHEELS))
    UI.toolTip(false, REAR_WHEEL_STEERING_DESC_)
    if rwstrUsed then
      UI.widgetSound("Nav2")
      if rwSteering and (is_car or is_bike or is_quad) then
        if awSteering then
          SS.setHandlingFlag(HF._STEER_ALL_WHEELS, false)
          awSteering = false
        end
        if handbrakeSteering then
          SS.setHandlingFlag(HF._HANDBRAKE_REARWHEELSTEER, false)
          handbrakeSteering = false
        end
        SS.setHandlingFlag(HF._STEER_REARWHEELS, true)
      else
        SS.setHandlingFlag(HF._STEER_REARWHEELS, false)
      end
    end

    ImGui.SameLine(); awSteering, awstrUsed = ImGui.Checkbox("All Wheel Steering", SS.getVehicleHandlingFlag(HF._STEER_ALL_WHEELS))
    UI.toolTip(false, ALL_WHEEL_STEERING_DESC_)
    if awstrUsed then
      UI.widgetSound("Nav2")
      if awSteering and (is_car or is_bike or is_quad) then
        if rwSteering then
          SS.setHandlingFlag(HF._STEER_REARWHEELS, false)
          rwSteering = false
        end
        if handbrakeSteering then
          SS.setHandlingFlag(HF._HANDBRAKE_REARWHEELSTEER, false)
          handbrakeSteering = false
        end
        SS.setHandlingFlag(HF._STEER_ALL_WHEELS, true)
      else
        SS.setHandlingFlag(HF._STEER_ALL_WHEELS, false)
      end
    end

    ImGui.SameLine(); handbrakeSteering, hbstrUsed = ImGui.Checkbox("Handbrake Steering", SS.getVehicleHandlingFlag(HF._HANDBRAKE_REARWHEELSTEER))
    UI.toolTip(false, HANDBRAKE_STEERING_DESC_)
    if hbstrUsed then
      UI.widgetSound("Nav2")
      if handbrakeSteering and (is_car or is_bike or is_quad) then
        if rwSteering then
          SS.setHandlingFlag(HF._STEER_REARWHEELS, false)
          rwSteering = false
        end
        if awSteering then
          SS.setHandlingFlag(HF._STEER_ALL_WHEELS, false)
          awSteering = false
        end
        SS.setHandlingFlag(HF._HANDBRAKE_REARWHEELSTEER, true)
      else
        SS.setHandlingFlag(HF._HANDBRAKE_REARWHEELSTEER, false)
      end
    end
    ImGui.Spacing(); UI.coloredText(STEERING_FLAGS_NOTE_TXT_, 'orange', 0.8, 25)
  else
    ImGui.Text(GET_IN_VEH_WARNING_)
  end
end
