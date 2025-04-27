---@diagnostic disable

function FlatbedUI()
    local f_PosY

    if Flatbed.towedVehicle then
        f_PosY = 680
    else
        f_PosY = 400
    end

    ImGui.BeginChild("FlatbedChild", 400, f_PosY, true)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 25, 25)
    local window_size_x, _ = ImGui.GetContentRegionAvail()

    if Self.Vehicle.IsFlatbed then
        ImGui.Dummy(1, 10)
        ImGui.BulletText(Flatbed.displayText)
        ImGui.Dummy(1, 10)
        towPos, towPosUsed = ImGui.Checkbox(_T("FLTBD_SHOW_TOWPOS_CB_"), towPos)
        UI.HelpMarker(_T("FLTBD_SHOW_TOWPOS_DESC_"))

        if towPosUsed then
            UI.WidgetSound("Nav2")
            CFG:SaveItem("towPos", towPos)
        end

        towBox, towBoxUsed = ImGui.Checkbox("Draw Box", towBox)
        UI.HelpMarker("Draw a bounding box around the detected vehicle.")

        if towBoxUsed then
            UI.WidgetSound("Nav2")
            CFG:SaveItem("towBox", towBox)
        end

        towEverything, towEverythingUsed = ImGui.Checkbox(_T("FLTBD_TOW_ALL_CB_"), towEverything)
        UI.HelpMarker(_T("FLTBD_TOW_ALL_DESC_"))

        if towEverythingUsed then
            UI.WidgetSound("Nav2")
            CFG:SaveItem("towEverything", towEverything)
        end

        ImGui.Dummy(1, 10)
        ImGui.Dummy((window_size_x / 2) - 60, 1)
        ImGui.SameLine()

        if ImGui.Button(not Flatbed.towedVehicle and _T("FLTBD_TOW_BTN_") or _T("GENERIC_DETACH_BTN_"), 80, 40) then
            UI.WidgetSound("Select")
            script.run_in_fiber(function(fltbd)
                Flatbed:OnKeyPress(fltbd)
            end)
        end

        if Flatbed.towedVehicle then
            ImGui.Dummy(1, 5)
            ImGui.SeparatorText(_T("FLTBD_ADJUST_POS_TXT_"))
            UI.Tooltip(_T("FLTBD_ADJUST_POS_DESC_"))
            ImGui.SetWindowFontScale(0.8)
            ImGui.BulletText("Hold [SHIFT] to move faster.")
            ImGui.SetWindowFontScale(1.0)
            ImGui.Dummy((window_size_x / 2) - 40, 1)
            ImGui.SameLine()

            ImGui.PushButtonRepeat(true)
            if ImGui.ArrowButton("##Up", 2) then
                Flatbed:MoveAttachment(0.0, 0.0, 0.01)
            end

            ImGui.Dummy((window_size_x / 2) - 80, 1)
            ImGui.SameLine()
            if ImGui.ArrowButton("##Left", 0) then
                Flatbed:MoveAttachment(0.0, 0.01, 0.0)
            end

            ImGui.SameLine()
            ImGui.Dummy(1, 1)
            ImGui.SameLine()
            if ImGui.ArrowButton("##Right", 1) then
                Flatbed:MoveAttachment(0.0, -0.01, 0.0)
            end

            ImGui.Dummy((window_size_x / 2) - 40, 1)
            ImGui.SameLine()
            if ImGui.ArrowButton("##Down", 3) then
                Flatbed:MoveAttachment(0.0, 0.0, -0.01)
            end
            ImGui.PopButtonRepeat()
        end
    else
        UI.WrappedText(_T("GET_IN_FLATBED_"), 20)

        if ImGui.Button(_T("SPAWN_FLATBED_BTN_")) then
            Flatbed:Spawn()
        end
    end
    ImGui.PopStyleVar()
    ImGui.EndChild()
end
