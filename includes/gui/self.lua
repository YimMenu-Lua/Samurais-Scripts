---@diagnostic disable: undefined-global, lowercase-global

function selfUI()
  Regen, RegenUsed = ImGui.Checkbox(AUTOHEAL_, Regen)
  UI.helpMarker(false, AUTOHEAL_DESC_)
  if RegenUsed then
    CFG.save("Regen", Regen)
    UI.widgetSound("Nav2")
  end

  replaceSneakAnim, rsanimUsed = ImGui.Checkbox(CROUCHCB_, replaceSneakAnim)
  UI.helpMarker(false, CROUCH_DESC_)
  if rsanimUsed then
    CFG.save("replaceSneakAnim", replaceSneakAnim)
    UI.widgetSound("Nav2")
  end

  replacePointAct, rpaUsed = ImGui.Checkbox(REPLACE_PA_CB_, replacePointAct)
  UI.helpMarker(false, REPLACE_PA_DESC_)
  if rpaUsed then
    CFG.save("replacePointAct", replacePointAct)
    UI.widgetSound("Nav2")
  end

  phoneAnim, phoneAnimUsed = ImGui.Checkbox(PHONEANIMS_CB_, phoneAnim)
  UI.helpMarker(false, PHONEANIMS_DESC_)
  if phoneAnimUsed then
    CFG.save("phoneAnim", phoneAnim)
    UI.widgetSound("Nav2")
  end

  sprintInside, sprintInsideUsed = ImGui.Checkbox(SPRINT_INSIDE_CB_, sprintInside)
  UI.helpMarker(false, SPRINT_INSIDE_DESC_)
  if sprintInsideUsed then
    CFG.save("sprintInside", sprintInside)
    UI.widgetSound("Nav2")
  end

  lockPick, lockPickUsed = ImGui.Checkbox(LOCKPICK_CB_, lockPick)
  UI.helpMarker(false, LOCKPICK_DESC_)
  if lockPickUsed then
    CFG.save("lockPick", lockPick)
    UI.widgetSound("Nav2")
  end

  disableActionMode, actionModeUsed = ImGui.Checkbox(ACTION_MODE_CB_, disableActionMode)
  UI.helpMarker(false, ACTION_MODE_DESC_)
  if actionModeUsed then
    CFG.save("disableActionMode", disableActionMode)
    UI.widgetSound("Nav2")
  end

  clumsy, clumsyUsed = ImGui.Checkbox("Clumsy", clumsy)
  UI.helpMarker(false, CLUMSY_DESC_)
  if clumsyUsed then
    rod = false
    CFG.save("rod", false)
    CFG.save("clumsy", clumsy)
    UI.widgetSound("Nav2")
  end
  if clumsy and clumsyUsed then
    script.run_in_fiber(function()
      if not PED.CAN_PED_RAGDOLL(self.get_ped()) then
        gui.show_warning("Samurais Scripts",
          "This option will not work if you're blocking ragdoll. Please make sure 'No Ragdoll' option is disabled in YimMennu.")
      end
    end)
  end

  rod, rodUsed = ImGui.Checkbox("Ragdoll On Demand", rod)
  UI.helpMarker(false, ROD_DESC_)
  if rodUsed then
    clumsy = false
    CFG.save("rod", rod)
    CFG.save("clumsy", false)
    UI.widgetSound("Nav2")
  end
  if rod and rodUsed then
    script.run_in_fiber(function()
      if not PED.CAN_PED_RAGDOLL(self.get_ped()) then
        gui.show_warning("Samurais Scripts",
          "This option will not work if you're blocking ragdoll. Please make sure 'No Ragdoll' option is disabled in YimMennu.")
      end
    end)
  end

  ragdoll_sound, rgdlsnd = ImGui.Checkbox("Ragdoll Sound", ragdoll_sound)
  UI.helpMarker(false, RAGDOLL_SOUND_DESC_)
  if rgdlsnd then
    UI.widgetSound("Nav2")
    CFG.save("ragdoll_sound", ragdoll_sound)
  end

  hideFromCops, hfcUsed = ImGui.Checkbox("Hide & Seek", hideFromCops)
  UI.helpMarker(false, HIDENSEEK_DESC_)
  if hfcUsed then
    UI.widgetSound("Nav2")
    CFG.save("hideFromCops", hideFromCops)
  end

  hatsinvehs, hvehsUsed = ImGui.Checkbox("Allow Hats In Vehicles", hatsinvehs)
  UI.helpMarker(false, HATSINVEHS_DESC_)
  if hvehsUsed then
    UI.widgetSound("Nav2")
    CFG.save("hatsinvehs", hatsinvehs)
  end

  novehragdoll, nvrUsed = ImGui.Checkbox("Don't Fall Off Vehicles", novehragdoll)
  UI.helpMarker(false, NOVEHRAGDOLL_DESC_)
  if nvrUsed then
    UI.widgetSound("Nav2")
    CFG.save("novehragdoll", novehragdoll)
  end
end
