---@diagnostic disable

function driftModeUI()
    if Game.Self.isDriving() then
        local manufacturer  = Game.Vehicle.manufacturer(current_vehicle)
        local vehicle_name  = Game.Vehicle.name(current_vehicle)
        local full_veh_name = string.format("%s %s", manufacturer, vehicle_name)
        local vehicle_class = Game.Vehicle.class(current_vehicle)
        ImGui.Spacing()
        if validModel then
            ImGui.SeparatorText(string.format("%s  (%s)", full_veh_name, vehicle_class)); ImGui.Spacing()
            driftMode, driftModeUsed = ImGui.Checkbox(translateLabel("DRIFT_MODE_CB_"), driftMode)
            UI.helpMarker(false, translateLabel("DRIFT_MODE_DESC_"))
            if driftModeUsed then
                UI.widgetSound("Nav2")
                CFG:SaveItem("driftMode", driftMode)
                CFG:SaveItem("DriftTires", false)
            end
            if driftMode then
                DriftTires = false
                ImGui.SameLine()
                ImGui.PushItemWidth(160)
                DriftIntensity, DriftIntensityUsed = ImGui.SliderInt("##Intensity", DriftIntensity, 0, 3)
                ImGui.PopItemWidth()
                UI.toolTip(false, translateLabel("DRIFT_SLIDER_"))
                if DriftIntensityUsed then
                    UI.widgetSound("Nav")
                    CFG:SaveItem("DriftIntensity", DriftIntensity)
                end
            end

            DriftTires, DriftTiresUsed = ImGui.Checkbox(translateLabel("DRIFT_TIRES_CB_"), DriftTires)
            UI.helpMarker(false, translateLabel("DRIFT_TIRES_DESC_"))
            if DriftTires then
                driftMode = false
            end
            if DriftTiresUsed then
                UI.widgetSound("Nav2")
                CFG:SaveItem("DriftTires", DriftTires)
                CFG:SaveItem("driftMode", false)
            end

            if driftMode or DriftTires then
                ImGui.SeparatorText("Drift Options"); ImGui.Spacing()
                ImGui.Text("Torque: "); ImGui.SameLine()
                ImGui.PushItemWidth(210)
                DriftPowerIncrease, dpiUsed = ImGui.SliderInt("##Torque", DriftPowerIncrease, 10, 100)
                UI.toolTip(false, translateLabel("DRIFT_TORQUE_DESC_"))
                if dpiUsed then
                    UI.widgetSound("Nav2")
                    CFG:SaveItem("DriftPowerIncrease", DriftPowerIncrease)
                end

                ImGui.Spacing(); DriftSmoke, dsmkUsed = ImGui.Checkbox("Drift Smoke", DriftSmoke)
                UI.toolTip(false, translateLabel("DRIFT_SMOKE_COL_DESC_"))
                if dsmkUsed then
                    UI.widgetSound("Nav2")
                    CFG:SaveItem("DriftSmoke", DriftSmoke)
                    if not BurnoutSmoke and not DriftSmoke then
                        script.run_in_fiber(function()
                            if not has_custom_tires then
                                VEHICLE.TOGGLE_VEHICLE_MOD(current_vehicle, 20, false)
                            end
                            if default_tire_smoke.r ~= driftSmoke_T.r or default_tire_smoke.g ~= driftSmoke_T.g or default_tire_smoke.b ~= driftSmoke_T.b then
                                VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(current_vehicle, default_tire_smoke.r,
                                    default_tire_smoke.g,
                                    default_tire_smoke.b)
                            end
                        end)
                    end
                end
            end

            ImGui.SameLine(); BurnoutSmoke, bsmkUsed = ImGui.Checkbox("Burnout Smoke", BurnoutSmoke)
            if bsmkUsed then
                UI.widgetSound("Nav2")
                CFG:SaveItem("BurnoutSmoke", BurnoutSmoke)
                if not BurnoutSmoke and not DriftSmoke then
                    script.run_in_fiber(function()
                        if not has_custom_tires then
                            VEHICLE.TOGGLE_VEHICLE_MOD(current_vehicle, 20, false)
                        end
                        if default_tire_smoke.r ~= driftSmoke_T.r or default_tire_smoke.g ~= driftSmoke_T.g or default_tire_smoke.b ~= driftSmoke_T.b then
                            log.info('true')
                            VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(current_vehicle, default_tire_smoke.r,
                                default_tire_smoke.g,
                                default_tire_smoke.b)
                        end
                    end)
                end
            end
            if DriftSmoke or BurnoutSmoke then
                ImGui.Spacing(); UI.coloredText(translateLabel("DRIFT_SMOKE_COL_"),
                    { driftSmoke_T.r, driftSmoke_T.g, driftSmoke_T
                        .b }, 1, 35)
                if not customSmokeCol then
                    driftSmokeIndex, dsiUsed = ImGui.Combo("##tireSmoke", driftSmokeIndex, driftSmokeColors,
                        #driftSmokeColors)
                    ImGui.SameLine()
                    if dsiUsed then
                        CFG:SaveItem("driftSmokeIndex", driftSmokeIndex)
                        selected_smoke_col = driftSmokeColors[driftSmokeIndex + 1]
                        local r, g, b = UI.getColor(string.lower(selected_smoke_col))
                        r, g, b = Lua_fn.round((r * 255), 2), Lua_fn.round((g * 255), 2), Lua_fn.round((b * 255), 2)
                        driftSmoke_T.r, driftSmoke_T.g, driftSmoke_T.b = r, g, b
                        CFG:SaveItem("driftSmoke_T", driftSmoke_T)
                        script.run_in_fiber(function()
                            if not custom_tires_checked then
                                has_custom_tires = VEHICLE.IS_TOGGLE_MOD_ON(current_vehicle, 20)
                                custom_tires_checked = true
                            end
                            if has_custom_tires and not tire_smoke_col_checked then
                                default_tire_smoke.r, default_tire_smoke.g, default_tire_smoke.b = VEHICLE
                                .GET_VEHICLE_TYRE_SMOKE_COLOR(
                                    current_vehicle, default_tire_smoke.r, default_tire_smoke.g, default_tire_smoke.b)
                                tire_smoke_col_checked = true
                            end
                        end)
                    end
                else
                    local hex_len
                    if smokeHex:find("^#") then
                        hex_len = 8
                    else
                        hex_len = 7
                    end
                    smokeHex, smokeHexEntered = ImGui.InputTextWithHint("##customHex", "HEX", smokeHex, hex_len,
                        ImGuiInputTextFlags.EnterReturnsTrue | ImGuiInputTextFlags.CharsNoBlank |
                        ImGuiInputTextFlags.CharsHexadecimal | ImGuiInputTextFlags.CharsUppercase
                    )
                    is_typing = ImGui.IsItemActive()
                    UI.toolTip(false, translateLabel("HEX_SMOKE_DESC_")); ImGui.SameLine()
                    if smokeHexEntered then
                        if smokeHex ~= nil then
                            if not smokeHex:find("^#") then
                                smokeHex = "#" .. smokeHex
                            end
                            if smokeHex:len() > 1 then
                                if smokeHex:len() ~= 4 and smokeHex:len() ~= 7 then
                                    UI.widgetSound("Error")
                                    YimToast:ShowWarning(
                                        "Samurais Scripts",
                                        string.format(
                                            "' %s ' is not a valid HEX color code. Please enter either a short or a long HEX string.",
                                            smokeHex)
                                    )
                                else
                                    UI.widgetSound("Select")
                                    driftSmoke_T.r, driftSmoke_T.g, driftSmoke_T.b = Lua_fn.hexToRGB(smokeHex)
                                    CFG:SaveItem("driftSmoke_T", driftSmoke_T)
                                    script.run_in_fiber(function()
                                        if not custom_tires_checked then
                                            has_custom_tires = VEHICLE.IS_TOGGLE_MOD_ON(current_vehicle, 20)
                                            custom_tires_checked = true
                                        end
                                        if has_custom_tires and not tire_smoke_col_checked then
                                            default_tire_smoke.r, default_tire_smoke.g, default_tire_smoke.b = VEHICLE
                                                .GET_VEHICLE_TYRE_SMOKE_COLOR(
                                                    current_vehicle, default_tire_smoke.r, default_tire_smoke.g,
                                                    default_tire_smoke.b)
                                            tire_smoke_col_checked = true
                                        end
                                    end)
                                    YimToast:ShowMessage("Samurais Scripts", "Drift smoke color changed", false, 1.5)
                                end
                            else
                                UI.widgetSound("Error")
                                YimToast:ShowMWarning("Samurais Scripts", "Please enter a valid HEX color code.")
                            end
                        end
                    end
                end
                customSmokeCol, cscUsed = ImGui.Checkbox(translateLabel("GENERIC_CUSTOM_LABEL_"), customSmokeCol)
                if cscUsed then
                    UI.widgetSound("Nav2")
                    CFG:SaveItem("customSmokeCol", customSmokeCol)
                    if not customSmokeCol then
                        selected_smoke_col = driftSmokeColors[driftSmokeIndex + 1]
                        local r, g, b = UI.getColor(string.lower(selected_smoke_col))
                        r, g, b = Lua_fn.round((r * 255), 2), Lua_fn.round((g * 255), 2), Lua_fn.round((b * 255), 2)
                        driftSmoke_T.r, driftSmoke_T.g, driftSmoke_T.b = r, g, b
                        CFG:SaveItem("driftSmoke_T", driftSmoke_T)
                    end
                end
            end

            if driftMode or DriftTires then
                ImGui.Dummy(1, 10); ImGui.SeparatorText(translateLabel("DRIFT_GAME_EXPERIMENTAL_TXT_"))
                ImGui.Spacing(); driftMinigame, drmgUsed = ImGui.Checkbox("Drift Minigame", driftMinigame)
                UI.toolTip(false, translateLabel("DRIFT_GAME_DESC_"))
                if drmgUsed then
                    UI.widgetSound("Nav2")
                    CFG:SaveItem("driftMinigame", driftMinigame)
                end
                if driftMinigame then
                    ImGui.Dummy(1, 10)
                    UI.coloredText("Your Highest Score: ", 'yellow', 0.92, 20); ImGui.SameLine()
                    ImGui.Text(string.format("%s Points", Lua_fn.separateInt(driftPB)))
                end
            end
        else
            UI.wrappedText(translateLabel("DRIFT_INVALID_DESC_"), 15)
        end
    else
        ImGui.Dummy(1, 5); ImGui.Text(translateLabel("GET_IN_VEH_WARNING_"))
    end
end
