function DrawSalvageYardUI()
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 10, 10)

    ImGui.SeparatorText(_T("SY_VEHICLES"))
    for i = 1, 4 do
        ImGui.Text(_F(_T("SY_VEH_SLOT"), i))
        ImGui.SameLine()
        ImGui.BulletText((SalvageYard:GetCarFromSlot(i) or _T("SY_EMPTY")))
        if SalvageYard:GetCarFromSlot(i) then
            ImGui.SameLine()
            local value = stats.get_int(_F("%s%d", "MPX_SAL23_VALUE_VEH", i))
            GUI:TextColored(string.formatmoney(value), Color("#00aa00"))
        end
    end

    ImGui.SeparatorText(_T("SY_LIFTS"))
    for i = 1, 2 do
        if SalvageYard:IsLiftTaken(i) then
            ImGui.Text(_F(_T("SY_LIFT"), 1))
            ImGui.SameLine()
            local hash = _F("%s%d", stats.get_int("MPX_MPSV_MODEL_SALVAGE_LIFT"), 1)
            ImGui.BulletText(SalvageYard:GetCarNameFromHash(hash))
            ImGui.SameLine()
            local value = _F("%s%d", stats.get_int("MPX_MPSV_VALUE_SALVAGE_LIFT"), i)
            GUI:TextColored(string.formatmoney(value), Color("#00aa00"))
            local posix = stats.get_int(_F("%s%d", "MPX_SALVAGING_POSIX_LIFT", i))
            ImGui.Text(_F("SALVAGING_POSIX_LIFT: %d", posix)) -- time to be done?
        else
            ImGui.Text(_F(_T("SY_LIFT_AVAILABLE"), i))
        end

        ImGui.Dummy(3, 3)
    end

    if (GVars.backend.debug_mode) then
        ImGui.SeparatorText(_T("SY_INFORMATION"))
        ImGui.Text(_F("SALVAGE_POPULAR_TIME_LEFT : %d", stats.get_int("MPX_SALVAGE_POPULAR_TIME_LEFT"))) -- how long popular? -- more than likely yes and if so then you can figure out the max and lock it there to always get max payout
    end
end

function DrawRobberiesUI()
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 5)

    ImGui.SeparatorText(_T("SY_ROBBERY_COOLDOWN"))
    if GUI:Button(_T("SY_DISABLE_COOLDOWN")) then
        SalvageYard:DisableCooldown()
    end
    ImGui.SameLine()
    if GUI:Button(_T("SY_DISABLE_WEEKLY_COOLDOWN")) then
        SalvageYard:DisableWeeklyCooldown()
    end

    ImGui.SeparatorText(_T("SY_WEEKLY_ROBBERIES"))
    ImGui.Text(_F(_T("SY_WEEKLY_CAR_STATUS"), SalvageYard:CheckWeeklyRobberyStatus(0)))
    ImGui.Text(_F(_T("SY_WEEKLY_CAR_STATUS"), SalvageYard:CheckWeeklyRobberyStatus(1)))
    ImGui.Text(_F(_T("SY_WEEKLY_CAR_STATUS"), SalvageYard:CheckWeeklyRobberyStatus(2)))

    ImGui.Dummy(5, 5)
    ImGui.Text(_F(_T("SY_ROBBERY_ACTIVE_CAR"), SalvageYard:GetCarNameFromHash(stats.get_int("MPX_SALV23_VEH_MODEL"))))
    ImGui.Text(_F(_T("SY_ROBBERY_TYPE"), SalvageYard:GetRobberyTypeName()))
    ImGui.Text(_F(_T("SY_ROBBERY_CAR_VALUE"), SalvageYard:GetRobberyValue()))
    ImGui.Text(_F(_T("SY_ROBBERY_CAN_KEEP_CAR"), tostring(SalvageYard:GetRobberyKeepState())))
    if GUI:Button(_T("SY_DOUBLE_CAR_WORTH")) then
        SalvageYard:DoubleCarWorth()
    end
    ImGui.SameLine()
    if GUI:Button(_T("SY_COMPLETE_PREPARATIONS")) then
        SalvageYard:CompletePreparation()
    end

    ImGui.PopStyleVar()
end

function SalvageYardUI()
    if (not Game.IsOnline() or not Backend:IsUpToDate()) then
        ImGui.Text(_T("OFFLINE_OR_OUTDATED"))
        return
    end

    if not SalvageYard:OwnsSalvageYard() then
        ImGui.Text(_T("SY_DO_NOT_OWN_SALVAGE_YARD"))
        return
    end

    ImGui.BeginTabBar("SalvageYardless")

    if ImGui.BeginTabItem(_T("SY_SALVAGE_YARD")) then
        DrawSalvageYardUI()
        ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem(_T("SY_CAR_ROBBERIES")) then
        DrawRobberiesUI()
        ImGui.EndTabItem()
    end
    ImGui.EndTabBar()
end

GUI:RegisterNewTab(eTabID.TAB_ONLINE, "Salvage Yard", SalvageYardUI)