---@diagnostic disable

function flatbedUI()
    local window_size_x, _ = ImGui.GetWindowSize()
    if fb_closestVehicleName == "" or fb_closestVehicleName == nil then
        displayText = translateLabel("FLTBD_NO_VEH_TXT_")
    elseif tostring(fb_closestVehicleName) == "Flatbed" then
        displayText = translateLabel("FLTBD_NOT_ALLOWED_TXT_")
    else
        displayText = string.format("%s %s", translateLabel("FLTBD_NEARBY_VEH_TXT_"), fb_closestVehicleName)
    end
    if towed_vehicle ~= 0 then
        displayText = string.format("%s %s.", translateLabel("FLTBD_TOWING_TXT_"),
            vehicles.get_vehicle_display_name(towed_vehicleModel))
    end
    if is_using_flatbed then
        ImGui.Dummy(1, 10); ImGui.SeparatorText(displayText)
        ImGui.Dummy(1, 10);
        ImGui.BeginDisabled(not Game.Self.isDriving() or towed_vehicle ~= 0)
        towPos, towPosUsed = ImGui.Checkbox(translateLabel("FLTBD_SHOW_TOWPOS_CB_"), towPos)
        ImGui.EndDisabled()
        UI.helpMarker(false, translateLabel("FLTBD_SHOW_TOWPOS_DESC_"))
        if towPosUsed then
            UI.widgetSound("Nav2")
        end

        towEverything, towEverythingUsed = ImGui.Checkbox(translateLabel("FLTBD_TOW_ALL_CB_"), towEverything)
        UI.helpMarker(false, translateLabel("FLTBD_TOW_ALL_DESC_"))
        if towEverythingUsed then
            UI.widgetSound("Nav2")
            CFG:SaveItem("towEverything", towEverything)
        end

        ImGui.Dummy(1, 10); ImGui.Dummy((window_size_x // 2) - 65, 1); ImGui.SameLine()
        if towed_vehicle == 0 then
            if ImGui.Button(translateLabel("FLTBD_TOW_BTN_"), 80, 40) then
                UI.widgetSound("Select")
                if towable and fb_closestVehicle ~= nil and fb_closestVehicleModel ~= flatbedModel then
                    script.run_in_fiber(function()
                        if entities.take_control_of(fb_closestVehicle, 300) then
                            local flatbedHeading       = ENTITY.GET_ENTITY_HEADING(current_vehicle)
                            local flatbedBone          = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle,
                                "chassis_dummy")
                            local vehBone              = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(fb_closestVehicle,
                                "chassis_dummy")
                            local tow_zAxis, tow_yAxis = flatbed_getTowOffset(fb_closestVehicle)
                            ENTITY.SET_ENTITY_HEADING(fb_closestVehicleModel, flatbedHeading)
                            ENTITY.ATTACH_ENTITY_TO_ENTITY(fb_closestVehicle, current_vehicle, flatbedBone, tow_xAxis,
                                tow_yAxis,
                                tow_zAxis, 0.0, 0.0,
                                0.0, true, true, false, false, 1, true, 1)
                            towed_vehicle = fb_closestVehicle
                            ENTITY.SET_ENTITY_CANT_CAUSE_COLLISION_DAMAGED_ENTITY(towed_vehicle, current_vehicle)
                        else
                            YimToast:ShowError("Samurais Scripts", translateLabel("VEH_CTRL_FAIL_"))
                        end
                    end)
                end
                if fb_closestVehicle ~= nil and fb_closestVehicleModel ~= flatbedModel and not towable then
                    YimToast:ShowMessage("Samurais Scripts", translateLabel("FLTBD_CARS_ONLY_TXT_"))
                end
                if fb_closestVehicle ~= nil and fb_closestVehicleModel == flatbedModel then
                    YimToast:ShowMessage("Samurais Scripts", translateLabel("FLTBD_NOT_ALLOWED_TXT_"))
                end
            end
        else
            if ImGui.Button(translateLabel("GENERIC_DETACH_BTN_"), 80, 40) then
                UI.widgetSound("Select2")
                script.run_in_fiber(function()
                    flatbed_detach()
                end)
            end
            ImGui.Dummy(1, 5); ImGui.SeparatorText(translateLabel("FLTBD_ADJUST_POS_TXT_"))
            UI.toolTip(false, translateLabel("FLTBD_ADJUST_POS_DESC_"))
            ImGui.Spacing(); ImGui.Dummy((window_size_x // 2) - 40, 1); ImGui.SameLine()
            ImGui.ArrowButton("##Up", 2)
            if ImGui.IsItemActive() then
                tow_zAxis = tow_zAxis + 0.01
                ENTITY.ATTACH_ENTITY_TO_ENTITY(towed_vehicle, current_vehicle, flatbedBone, tow_xAxis, tow_yAxis,
                    tow_zAxis,
                    0.0, 0.0, 0.0,
                    true, true, false, false, 1, true, 1)
            end
            ImGui.Dummy((window_size_x // 2) - 80, 1); ImGui.SameLine()
            ImGui.ArrowButton("##Left", 0)
            if ImGui.IsItemActive() then
                tow_yAxis = tow_yAxis + 0.01
                ENTITY.ATTACH_ENTITY_TO_ENTITY(towed_vehicle, current_vehicle, flatbedBone, tow_xAxis, tow_yAxis,
                    tow_zAxis,
                    0.0, 0.0, 0.0,
                    true, true, false, false, 1, true, 1)
            end
            ImGui.SameLine(); ImGui.Dummy(23, 1); ImGui.SameLine()
            ImGui.ArrowButton("##Right", 1)
            if ImGui.IsItemActive() then
                tow_yAxis = tow_yAxis - 0.01
                ENTITY.ATTACH_ENTITY_TO_ENTITY(towed_vehicle, current_vehicle, flatbedBone, tow_xAxis, tow_yAxis,
                    tow_zAxis,
                    0.0, 0.0, 0.0,
                    true, true, false, false, 1, true, 1)
            end
            ImGui.Dummy((window_size_x // 2) - 40, 1); ImGui.SameLine()
            ImGui.ArrowButton("##Down", 3)
            if ImGui.IsItemActive() then
                tow_zAxis = tow_zAxis - 0.01
                ENTITY.ATTACH_ENTITY_TO_ENTITY(towed_vehicle, current_vehicle, flatbedBone, tow_xAxis, tow_yAxis,
                    tow_zAxis,
                    0.0, 0.0, 0.0,
                    true, true, false, false, 1, true, 1)
            end
        end
    else
        UI.wrappedText(translateLabel("GET_IN_FLATBED_"), 20)
        if ImGui.Button(translateLabel("SPAWN_FLATBED_BTN_")) then
            script.run_in_fiber(function(script)
                if Game.Self.isOnFoot() then
                    if Game.Self.isOutside() then
                        if not Game.requestModel(flatbedModel) then
                            script:sleep(10)
                            return
                        end
                        local myPos = self.get_pos()
                        fltbd = VEHICLE.CREATE_VEHICLE(flatbedModel, myPos.x, myPos.y, myPos.z,
                            ENTITY.GET_ENTITY_HEADING(self.get_ped()), true, false, false)
                        PED.SET_PED_INTO_VEHICLE(self.get_ped(), fltbd, -1)
                        ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(fltbd)
                    else
                        YimToast:ShowError("Samurais Scripts", translateLabel("FLTBD_INTERIOR_ERROR_"))
                    end
                else
                    YimToast:ShowError("Samurais Scripts", translateLabel("FLTBD_EXIT_VEH_ERROR_"))
                end
            end)
        end
    end
end
