---@diagnostic disable

local s_SelectedSmokeColor = 0

function DriftModeUI()
    local f_PosY = 100
    if self.get_veh() ~= 0 then
        f_PosY = 600
    end
    if driftMinigame then
        f_PosY = f_PosY + 40
    end
    if DriftSmoke or BurnoutSmoke then
        f_PosY = f_PosY + 100
    end

    ImGui.BeginChild("DriftModeChild", 500, f_PosY, true)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 25, 25)
    if self.get_veh() ~= 0 then
        local manufacturer  = Game.Vehicle.Manufacturer(Self.Vehicle.Current)
        local vehicle_name  = Game.Vehicle.Name(Self.Vehicle.Current)
        local full_veh_name = string.format("%s %s", manufacturer, vehicle_name)
        local vehicle_class = Game.Vehicle.Class(Self.Vehicle.Current)
        if validModel then
            ImGui.SeparatorText(string.format("%s  (%s)", full_veh_name, vehicle_class))
            ImGui.Spacing()
            driftMode, driftModeUsed = ImGui.Checkbox(_T("DRIFT_MODE_CB_"), driftMode)
            UI.HelpMarker(_T("DRIFT_MODE_DESC_"))
            if driftModeUsed then
                UI.WidgetSound("Nav2")
                CFG:SaveItem("driftMode", driftMode)
                CFG:SaveItem("DriftTires", false)
            end
            if driftMode then
                DriftTires = false
                ImGui.SameLine()
                ImGui.PushItemWidth(160)
                DriftIntensity, DriftIntensityUsed = ImGui.SliderInt("##Intensity", DriftIntensity, 0, 3)
                ImGui.PopItemWidth()
                UI.Tooltip(_T("DRIFT_SLIDER_"))
                if DriftIntensityUsed then
                    UI.WidgetSound("Nav")
                    CFG:SaveItem("DriftIntensity", DriftIntensity)
                end
            end

            DriftTires, DriftTiresUsed = ImGui.Checkbox(_T("DRIFT_TIRES_CB_"), DriftTires)
            UI.HelpMarker(_T("DRIFT_TIRES_DESC_"))
            if DriftTires then
                driftMode = false
            end
            if DriftTiresUsed then
                UI.WidgetSound("Nav2")
                CFG:SaveItem("DriftTires", DriftTires)
                CFG:SaveItem("driftMode", false)
            end

            if driftMode or DriftTires then
                ImGui.SeparatorText("Drift Options")
                ImGui.Spacing()
                ImGui.Text("Torque: ")
                ImGui.SameLine()
                ImGui.PushItemWidth(210)
                DriftPowerIncrease, dpiUsed = ImGui.SliderInt("##Torque", DriftPowerIncrease, 10, 100)
                UI.Tooltip(_T("DRIFT_TORQUE_DESC_"))
                if dpiUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("DriftPowerIncrease", DriftPowerIncrease)
                end

                ImGui.Spacing(); DriftSmoke, dsmkUsed = ImGui.Checkbox("Drift Smoke", DriftSmoke)
                UI.Tooltip(_T("DRIFT_SMOKE_COL_DESC_"))
                if dsmkUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("DriftSmoke", DriftSmoke)
                    if not BurnoutSmoke and not DriftSmoke then
                        script.run_in_fiber(function()
                            if not has_custom_tires then
                                VEHICLE.TOGGLE_VEHICLE_MOD(Self.Vehicle.Current, 20, false)
                            end
                            if default_tire_smoke.r ~= driftSmoke_T.r or default_tire_smoke.g ~= driftSmoke_T.g or default_tire_smoke.b ~= driftSmoke_T.b then
                                VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(Self.Vehicle.Current, default_tire_smoke.r,
                                    default_tire_smoke.g,
                                    default_tire_smoke.b)
                            end
                        end)
                    end
                end
            end

            ImGui.SameLine(); BurnoutSmoke, bsmkUsed = ImGui.Checkbox("Burnout Smoke", BurnoutSmoke)
            if bsmkUsed then
                UI.WidgetSound("Nav2")
                CFG:SaveItem("BurnoutSmoke", BurnoutSmoke)
                if not BurnoutSmoke and not DriftSmoke then
                    script.run_in_fiber(function()
                        if not has_custom_tires then
                            VEHICLE.TOGGLE_VEHICLE_MOD(Self.Vehicle.Current, 20, false)
                        end
                        if default_tire_smoke.r ~= driftSmoke_T.r or default_tire_smoke.g ~= driftSmoke_T.g or default_tire_smoke.b ~= driftSmoke_T.b then
                            VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(Self.Vehicle.Current, default_tire_smoke.r,
                                default_tire_smoke.g,
                                default_tire_smoke.b)
                        end
                    end)
                end
            end
            if DriftSmoke or BurnoutSmoke then
                ImGui.Spacing()
                UI.ColoredText(_T("DRIFT_SMOKE_COL_"), {math.floor(driftSmoke_T.r), math.floor(driftSmoke_T.g), math.floor(driftSmoke_T.b), 255}, nil, 35)
                if not customSmokeCol then
                    driftSmokeIndex, dsiUsed = ImGui.Combo("##tireSmoke", driftSmokeIndex, t_DriftSmokeColors, #t_DriftSmokeColors)
                    ImGui.SameLine()
                    if dsiUsed then
                        CFG:SaveItem("driftSmokeIndex", driftSmokeIndex)
                        s_SelectedSmokeColor = t_DriftSmokeColors[driftSmokeIndex + 1]
                        driftSmoke_T.r, driftSmoke_T.g, driftSmoke_T.b, _ = Col(s_SelectedSmokeColor:lower()):AsRGBA()
                        CFG:SaveItem("driftSmoke_T", driftSmoke_T)
                        script.run_in_fiber(function()
                            if not custom_tires_checked then
                                has_custom_tires = VEHICLE.IS_TOGGLE_MOD_ON(Self.Vehicle.Current, 20)
                                custom_tires_checked = true
                            end
                            if has_custom_tires and not tire_smoke_col_checked then
                                default_tire_smoke.r, default_tire_smoke.g, default_tire_smoke.b = VEHICLE
                                .GET_VEHICLE_TYRE_SMOKE_COLOR(
                                    Self.Vehicle.Current, default_tire_smoke.r, default_tire_smoke.g, default_tire_smoke.b)
                                tire_smoke_col_checked = true
                            end
                        end)
                    end
                else
                    local hex_len
                    if smokeHex:find("^#") then
                        hex_len = 10
                    else
                        hex_len = 9
                    end
                    smokeHex, smokeHexEntered = ImGui.InputTextWithHint("##customHex", "HEX", smokeHex, hex_len,
                        ImGuiInputTextFlags.EnterReturnsTrue | ImGuiInputTextFlags.CharsNoBlank |
                        ImGuiInputTextFlags.CharsHexadecimal | ImGuiInputTextFlags.CharsUppercase
                    )
                    is_typing = ImGui.IsItemActive()
                    UI.Tooltip(_T("HEX_SMOKE_DESC_"))
                    ImGui.SameLine()
                    if smokeHexEntered and smokeHex ~= nil then
                        if not smokeHex:find("^#") then
                            smokeHex = "#" .. smokeHex
                        end

                        if #smokeHex > 1 then
                            if #smokeHex:gsub("#", "") ~= 6 and #smokeHex:gsub("#", "") ~= 8 then
                                UI.WidgetSound("Error")
                                YimToast:ShowWarning(
                                    "Samurais Scripts",
                                    string.format(
                                        "' %s ' is not a valid HEX color code. Please enter either a short or a long HEX string.",
                                        smokeHex)
                                )
                            else
                                UI.WidgetSound("Select")
                                driftSmoke_T.r, driftSmoke_T.g, driftSmoke_T.b, _ = Col(smokeHex):AsRGBA()
                                CFG:SaveItem("driftSmoke_T", driftSmoke_T)
                                script.run_in_fiber(function()
                                    if not custom_tires_checked then
                                        has_custom_tires = VEHICLE.IS_TOGGLE_MOD_ON(Self.Vehicle.Current, 20)
                                        custom_tires_checked = true
                                    end
                                    if has_custom_tires and not tire_smoke_col_checked then
                                        default_tire_smoke.r, default_tire_smoke.g, default_tire_smoke.b = VEHICLE
                                            .GET_VEHICLE_TYRE_SMOKE_COLOR(
                                                Self.Vehicle.Current, default_tire_smoke.r, default_tire_smoke.g,
                                                default_tire_smoke.b)
                                        tire_smoke_col_checked = true
                                    end
                                end)
                                YimToast:ShowMessage("Samurais Scripts", "Drift smoke color changed", false, 1.5)
                            end
                        else
                            UI.WidgetSound("Error")
                            YimToast:ShowMWarning("Samurais Scripts", "Please enter a valid HEX color code.")
                        end
                    end
                end
                customSmokeCol, cscUsed = ImGui.Checkbox(_T("GENERIC_CUSTOM_LABEL_"), customSmokeCol)
                if cscUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("customSmokeCol", customSmokeCol)
                    if not customSmokeCol then
                        s_SelectedSmokeColor = t_DriftSmokeColors[driftSmokeIndex + 1]
                        driftSmoke_T.r, driftSmoke_T.g, driftSmoke_T.b, _ = Col(s_SelectedSmokeColor:lower()):AsRGBA()
                        CFG:SaveItem("driftSmoke_T", driftSmoke_T)
                    end
                end
            end

            if driftMode or DriftTires then
                ImGui.Dummy(1, 5)
                ImGui.SeparatorText(_T("DRIFT_GAME_EXPERIMENTAL_TXT_"))
                driftMinigame, drmgUsed = ImGui.Checkbox("Drift Minigame", driftMinigame)
                UI.Tooltip(_T("DRIFT_GAME_DESC_"))
                if drmgUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("driftMinigame", driftMinigame)
                end
                if driftMinigame then
                    UI.ColoredText("Your Highest Score: ", "yellow", 0.92, 20)
                    ImGui.SameLine()
                    ImGui.Text(string.format("%s Points", Lua_fn.SeparateInt(driftPB)))
                end
            end
        else
            UI.WrappedText(_T("DRIFT_INVALID_DESC_"), 15)
        end
    else
        ImGui.SetWindowFontScale(1.15)
        ImGui.Text(_T("GET_IN_VEH_WARNING_"))
        ImGui.SetWindowFontScale(1.0)
    end
    ImGui.PopStyleVar()
    ImGui.EndChild()
end
