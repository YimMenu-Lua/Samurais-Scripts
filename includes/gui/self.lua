---@diagnostic disable: undefined-global, lowercase-global

function selfUI()
    Regen, RegenUsed = ImGui.Checkbox(translateLabel("AUTOHEAL_"), Regen)
    UI.helpMarker(false, translateLabel("AUTOHEAL_DESC_"))
    if RegenUsed then
        CFG:SaveItem("Regen", Regen)
        UI.widgetSound("Nav2")
    end

    replaceSneakAnim, rsanimUsed = ImGui.Checkbox(translateLabel("CROUCHCB_"), replaceSneakAnim)
    UI.helpMarker(false, translateLabel("CROUCH_DESC_"))
    if rsanimUsed then
        CFG:SaveItem("replaceSneakAnim", replaceSneakAnim)
        UI.widgetSound("Nav2")
    end

    replacePointAct, rpaUsed = ImGui.Checkbox(translateLabel("REPLACE_PA_CB_"), replacePointAct)
    UI.helpMarker(false, translateLabel("REPLACE_PA_DESC_"))
    if rpaUsed then
        CFG:SaveItem("replacePointAct", replacePointAct)
        UI.widgetSound("Nav2")
    end

    phoneAnim, phoneAnimUsed = ImGui.Checkbox(translateLabel("PHONEANIMS_CB_"), phoneAnim)
    UI.helpMarker(false, translateLabel("PHONEANIMS_DESC_"))
    if phoneAnimUsed then
        CFG:SaveItem("phoneAnim", phoneAnim)
        UI.widgetSound("Nav2")
    end

    sprintInside, sprintInsideUsed = ImGui.Checkbox(translateLabel("SPRINT_INSIDE_CB_"), sprintInside)
    UI.helpMarker(false, translateLabel("SPRINT_INSIDE_DESC_"))
    if sprintInsideUsed then
        CFG:SaveItem("sprintInside", sprintInside)
        UI.widgetSound("Nav2")
    end

    lockPick, lockPickUsed = ImGui.Checkbox(translateLabel("LOCKPICK_CB_"), lockPick)
    UI.helpMarker(false, translateLabel("LOCKPICK_DESC_"))
    if lockPickUsed then
        CFG:SaveItem("lockPick", lockPick)
        UI.widgetSound("Nav2")
    end

    disableActionMode, actionModeUsed = ImGui.Checkbox(translateLabel("ACTION_MODE_CB_"), disableActionMode)
    UI.helpMarker(false, translateLabel("ACTION_MODE_DESC_"))
    if actionModeUsed then
        CFG:SaveItem("disableActionMode", disableActionMode)
        UI.widgetSound("Nav2")
    end

    clumsy, clumsyUsed = ImGui.Checkbox("Clumsy", clumsy)
    UI.helpMarker(false, translateLabel("CLUMSY_DESC_"))
    if clumsyUsed then
        rod = false
        CFG:SaveItem("rod", false)
        CFG:SaveItem("clumsy", clumsy)
        UI.widgetSound("Nav2")
    end
    if clumsy and clumsyUsed then
        script.run_in_fiber(function()
            if not PED.CAN_PED_RAGDOLL(self.get_ped()) then
                YimToast:ShowWarning(
                    "Samurais Scripts",
                    "This option will not work if you're blocking ragdoll. Please make sure 'No Ragdoll' option is disabled in YimMennu."
                )
            end
        end)
    end

    rod, rodUsed = ImGui.Checkbox("Ragdoll On Demand", rod)
    UI.helpMarker(false, translateLabel("ROD_DESC_"))
    if rodUsed then
        clumsy = false
        CFG:SaveItem("rod", rod)
        CFG:SaveItem("clumsy", false)
        UI.widgetSound("Nav2")
    end
    if rod and rodUsed then
        script.run_in_fiber(function()
            if not PED.CAN_PED_RAGDOLL(self.get_ped()) then
                YimToast:ShowWarning(
                    "Samurais Scripts",
                    "This option will not work if you're blocking ragdoll. Please make sure 'No Ragdoll' option is disabled in YimMennu."
                )
            end
        end)
    end

    ragdoll_sound, rgdlsnd = ImGui.Checkbox("Ragdoll Sound", ragdoll_sound)
    UI.helpMarker(false, translateLabel("RAGDOLL_SOUND_DESC_"))
    if rgdlsnd then
        UI.widgetSound("Nav2")
        CFG:SaveItem("ragdoll_sound", ragdoll_sound)
    end

    hideFromCops, hfcUsed = ImGui.Checkbox("Hide & Seek", hideFromCops)
    UI.helpMarker(false, translateLabel("HIDENSEEK_DESC_"))
    if hfcUsed then
        UI.widgetSound("Nav2")
        CFG:SaveItem("hideFromCops", hideFromCops)
    end

    hatsinvehs, hvehsUsed = ImGui.Checkbox("Allow Hats In Vehicles", hatsinvehs)
    UI.helpMarker(false, translateLabel("HATSINVEHS_DESC_"))
    if hvehsUsed then
        UI.widgetSound("Nav2")
        CFG:SaveItem("hatsinvehs", hatsinvehs)
    end

    novehragdoll, nvrUsed = ImGui.Checkbox("Don't Fall Off Vehicles", novehragdoll)
    UI.helpMarker(false, translateLabel("NOVEHRAGDOLL_DESC_"))
    if nvrUsed then
        UI.widgetSound("Nav2")
        CFG:SaveItem("novehragdoll", novehragdoll)
    end
end
