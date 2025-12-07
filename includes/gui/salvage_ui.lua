function DrawSalvageYardUI()
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 5)

    ImGui.SeparatorText(_T("SY_VEHICLES"))
    ImGui.Text(string.format(_T("SY_VEH_SLOT") .. " ", 1))
    ImGui.SameLine()
    ImGui.BulletText((SalvageYard:GetCarFromSlot(1) or _T("SY_EMPTY")))
    if SalvageYard:GetCarFromSlot(1) ~= nil then
        ImGui.SameLine()
        GUI:TextColored("$" .. stats.get_int("MPX_SAL23_VALUE_VEH1"), Color("#00aa00"))
    end

    ImGui.Text(string.format(_T("SY_VEH_SLOT"), 2))
    ImGui.SameLine()
    ImGui.BulletText((SalvageYard:GetCarFromSlot(2) or _T("SY_EMPTY")))
    if SalvageYard:GetCarFromSlot(2) ~= nil then
        ImGui.SameLine()
        GUI:TextColored("$" .. stats.get_int("MPX_SAL23_VALUE_VEH2"), Color("#00aa00"))
    end

    ImGui.Text(string.format(_T("SY_VEH_SLOT"), 3))
    ImGui.SameLine()
    ImGui.BulletText((SalvageYard:GetCarFromSlot(3) or _T("SY_EMPTY")))
    if SalvageYard:GetCarFromSlot(3) ~= nil then
        ImGui.SameLine()
        GUI:TextColored("$" .. stats.get_int("MPX_SAL23_VALUE_VEH3"), Color("#00aa00"))
    end

    ImGui.Text(string.format(_T("SY_VEH_SLOT"), 4))
    ImGui.SameLine()
    ImGui.BulletText((SalvageYard:GetCarFromSlot(4) or _T("SY_EMPTY")))
    if SalvageYard:GetCarFromSlot(4) ~= nil then
        ImGui.SameLine()
        GUI:TextColored("$" .. stats.get_int("MPX_SAL23_VALUE_VEH4"), Color("#00aa00"))
    end

    ImGui.SeparatorText(_T("SY_LIFTS"))
    if SalvageYard:LiftTaken(1) then
        ImGui.Text(string.format(_T("SY_LIFT"), 1) .. " ")
        ImGui.SameLine()
        ImGui.BulletText(SalvageYard:GetCarNameFromHash(stats.get_int("MPX_MPSV_MODEL_SALVAGE_LIFT1")))
        ImGui.SameLine()
        GUI:TextColored("$" .. stats.get_int("MPX_MPSV_VALUE_SALVAGE_LIFT1"), Color("#00aa00"))
        ImGui.Text("SALVAGING_POSIX_LIFT1: " .. stats.get_int("MPX_SALVAGING_POSIX_LIFT1")) -- time to be done?
    else
        ImGui.Text(string.format(_T("SY_LIFT_AVAILABLE"), 1))
    end

    ImGui.Dummy(3, 3)

    if SalvageYard:LiftTaken(2) then
        ImGui.Text(string.format(_T("SY_LIFT"), 2))
        ImGui.SameLine()
        ImGui.BulletText(SalvageYard:GetCarNameFromHash(stats.get_int("MPX_MPSV_MODEL_SALVAGE_LIFT2")))
        ImGui.SameLine()
        GUI:TextColored("$" .. stats.get_int("MPX_MPSV_VALUE_SALVAGE_LIFT2"), Color("#00aa00"))
        ImGui.Text("SALVAGING_POSIX_LIFT2: " .. tunables.get_int("MPX_SALVAGING_POSIX_LIFT2")) -- time to be done?
    else
        ImGui.Text(string.format(_T("SY_LIFT_AVAILABLE"), 2))
    end

    ImGui.SeparatorText(_T("SY_INFORMATION"))
    ImGui.Text("SALVAGE_POPULAR_TIME_LEFT : " .. stats.get_int("MPX_SALVAGE_POPULAR_TIME_LEFT")) -- how long popular?
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
    ImGui.Text(string.format(_T("SY_WEEKLY_CAR_STATUS"), SalvageYard:CheckWeeklyRobberyStatus(0)))
    ImGui.Text(string.format(_T("SY_WEEKLY_CAR_STATUS"), SalvageYard:CheckWeeklyRobberyStatus(1)))
    ImGui.Text(string.format(_T("SY_WEEKLY_CAR_STATUS"), SalvageYard:CheckWeeklyRobberyStatus(2)))

    ImGui.Dummy(5, 5)
    ImGui.Text(string.format(_T("SY_ROBBERY_ACTIVE_CAR"), SalvageYard:GetCarNameFromHash(stats.get_int("MPX_SALV23_VEH_MODEL"))))
    ImGui.Text(string.format(_T("SY_ROBBERY_TYPE"), SalvageYard:GetRobberyTypeName()))
    ImGui.Text(string.format(_T("SY_ROBBERY_CAR_VALUE"), SalvageYard:GetRobberyValue()))
    ImGui.Text(string.format(_T("SY_ROBBERY_CAN_KEEP_CAR"), tostring(SalvageYard:GetRobberyKeepState())))
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
    if not Game.IsOnline() and not Backend:IsUpToDate() then
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

GUI:GetMainTab():RegisterSubtab("Salvage Yard", SalvageYardUI)