---@diagnostic disable

local function Flatbed_Attach(vehicle)
    if not Self.Vehicle.IsFlatbed then
        return
    end

    script.run_in_fiber(function()
        ENTITY.ATTACH_ENTITY_TO_ENTITY(
                    vehicle,
                    Self.Vehicle.Current,
                    flatbedBone,
                    f_tow_xAxis,
                    f_tow_yAxis,
                    f_tow_zAxis,
                    0.0,
                    0.0,
                    0.0,
                    true,
                    true,
                    false,
                    false,
                    1,
                    true,
                    1
                )
    end)
end

function FlatbedUI()
    local f_PosY = 360
    if towed_vehicle ~= 0 then
        f_PosY = f_PosY * 1.7
    end

    ImGui.BeginChild("DriftModeChild", 400, f_PosY, true)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 25, 25)
    local window_size_x, _ = ImGui.GetContentRegionAvail()
    local s_flatbed_text = ""

    if fb_closestVehicleName == "" or fb_closestVehicleName == nil then
        s_flatbed_text = _T("FLTBD_NO_VEH_TXT_")
    elseif tostring(fb_closestVehicleName) == "Flatbed" then
        s_flatbed_text = _T("FLTBD_NOT_ALLOWED_TXT_")
    else
        s_flatbed_text = string.format("%s %s", _T("FLTBD_NEARBY_VEH_TXT_"), fb_closestVehicleName)
    end

    if towed_vehicle ~= 0 then
        s_flatbed_text = string.format("%s %s.", _T("FLTBD_TOWING_TXT_"),
            vehicles.get_vehicle_display_name(towed_vehicleModel))
    end

    if Self.Vehicle.IsFlatbed then
        ImGui.Dummy(1, 10)
        ImGui.BulletText(s_flatbed_text)
        ImGui.Dummy(1, 10)
        ImGui.BeginDisabled(not Self.IsDriving() or towed_vehicle ~= 0)
        towPos, towPosUsed = ImGui.Checkbox(_T("FLTBD_SHOW_TOWPOS_CB_"), towPos)
        ImGui.EndDisabled()
        UI.HelpMarker(_T("FLTBD_SHOW_TOWPOS_DESC_"))
        if towPosUsed then
            UI.WidgetSound("Nav2")
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
        if towed_vehicle == 0 then
            if ImGui.Button(_T("FLTBD_TOW_BTN_"), 80, 40) then
                UI.WidgetSound("Select")
                if towable and fb_closestVehicle ~= nil and fb_closestVehicleModel ~= flatbedModel then
                    script.run_in_fiber(function()
                        if entities.take_control_of(fb_closestVehicle, 300) then
                            local flatbedHeading = ENTITY.GET_ENTITY_HEADING(Self.Vehicle.Current)
                            local flatbedBone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(Self.Vehicle.Current, "chassis_dummy")
                            local vehBone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(fb_closestVehicle, "chassis_dummy")

                            f_tow_zAxis, f_tow_yAxis = Flatbed_GetTowOffset(fb_closestVehicle)
                            ENTITY.SET_ENTITY_HEADING(fb_closestVehicleModel, flatbedHeading)
                            Flatbed_Attach(fb_closestVehicle)
                            towed_vehicle = fb_closestVehicle
                            ENTITY.SET_ENTITY_CANT_CAUSE_COLLISION_DAMAGED_ENTITY(towed_vehicle, Self.Vehicle.Current)
                        else
                            YimToast:ShowError("Samurais Scripts", _T("VEH_CTRL_FAIL_"))
                        end
                    end)
                end
                if fb_closestVehicle ~= nil and fb_closestVehicleModel ~= flatbedModel and not towable then
                    YimToast:ShowMessage("Samurais Scripts", _T("FLTBD_CARS_ONLY_TXT_"))
                end
                if fb_closestVehicle ~= nil and fb_closestVehicleModel == flatbedModel then
                    YimToast:ShowMessage("Samurais Scripts", _T("FLTBD_NOT_ALLOWED_TXT_"))
                end
            end
        else
            if ImGui.Button(_T("GENERIC_DETACH_BTN_"), 80, 40) then
                UI.WidgetSound("Select2")
                script.run_in_fiber(function()
                    Flatbed_Detach()
                end)
            end
            ImGui.Dummy(1, 5)
            ImGui.SeparatorText(_T("FLTBD_ADJUST_POS_TXT_"))
            UI.Tooltip(_T("FLTBD_ADJUST_POS_DESC_"))
            ImGui.Spacing()
            ImGui.Dummy((window_size_x / 2) - 40, 1)
            ImGui.SameLine()
            ImGui.ArrowButton("##Up", 2)
            if ImGui.IsItemActive() then
                f_tow_zAxis = f_tow_zAxis + 0.01
                Flatbed_Attach(towed_vehicle)
            end

            ImGui.Dummy((window_size_x / 2) - 80, 1)
            ImGui.SameLine()
            ImGui.ArrowButton("##Left", 0)
            if ImGui.IsItemActive() then
                f_tow_yAxis = f_tow_yAxis + 0.01
                Flatbed_Attach(towed_vehicle)
            end

            ImGui.SameLine()
            ImGui.Dummy(1, 1)
            ImGui.SameLine()
            ImGui.ArrowButton("##Right", 1)
            if ImGui.IsItemActive() then
                f_tow_yAxis = f_tow_yAxis - 0.01
                Flatbed_Attach(towed_vehicle)
            end

            ImGui.Dummy((window_size_x / 2) - 40, 1)
            ImGui.SameLine()
            ImGui.ArrowButton("##Down", 3)
            if ImGui.IsItemActive() then
                f_tow_zAxis = f_tow_zAxis - 0.01
                Flatbed_Attach(towed_vehicle)
            end
        end
    else
        UI.WrappedText(_T("GET_IN_FLATBED_"), 20)
        if ImGui.Button(_T("SPAWN_FLATBED_BTN_")) then
            script.run_in_fiber(function(script)
                if Self.IsOnFoot() then
                    if Self.IsOutside() then
                        if not Game.RequestModel(flatbedModel) then
                            script:sleep(10)
                            return
                        end
                        local myPos = self.get_pos()
                        fltbd = VEHICLE.CREATE_VEHICLE(flatbedModel, myPos.x, myPos.y, myPos.z,
                            ENTITY.GET_ENTITY_HEADING(Self.GetPedID()), true, false, false)
                        PED.SET_PED_INTO_VEHICLE(Self.GetPedID(), fltbd, -1)
                        ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(fltbd)
                    else
                        YimToast:ShowError("Samurais Scripts", _T("FLTBD_INTERIOR_ERROR_"))
                    end
                else
                    YimToast:ShowError("Samurais Scripts", _T("FLTBD_EXIT_VEH_ERROR_"))
                end
            end)
        end
    end
    ImGui.PopStyleVar()
    ImGui.EndChild()
end
