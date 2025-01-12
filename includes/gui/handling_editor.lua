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

  -- ImGui.SameLine(); ImGui.Dummy(37, 1); ImGui.SameLine();
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

  -- ImGui.SameLine(); ImGui.Dummy(15, 1); ImGui.SameLine();
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

  -- ImGui.SameLine(); ImGui.Dummy(20, 1); ImGui.SameLine();
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

  --[[
  ImGui.Spacing(); ImGui.SeparatorText("Steering")
  rwSteering, rwstrUsed = ImGui.Checkbox("Rear Wheels", rwSteering)
  UI.toolTip(false, "Your vehicle will use the rear wheels to steer instead of the front.")
  if rwstrUsed then
    UI.widgetSound("Nav2")
    CFG.save("rwSteering", rwSteering)
  end

  ImGui.SameLine(); awSteering, awstrUsed = ImGui.Checkbox("All Wheels", awSteering)
  UI.toolTip(false, "Your vehicle will use all its wheels to steer.")
  if awstrUsed then
    UI.widgetSound("Nav2")
    CFG.save("awSteering", awSteering)
  end

  ImGui.SameLine(); handbrakeSteering, hbstrUsed = ImGui.Checkbox("Handbrake Steering", handbrakeSteering)
  UI.toolTip(false, "When you press the handbrake, your vehicle will use all its wheels to steer, similar to monster trucks.")
  if hbstrUsed then
    UI.widgetSound("Nav2")
    CFG.save("handbrakeSteering", handbrakeSteering)
  end

  ImGui.Spacing(); UI.wrappedText("[ ! ] NOTE: These options change your vehicle's steering behavior but you can not visually see the difference.", 25)
  ]]
end
