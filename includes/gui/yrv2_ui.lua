---@diagnostic disable

function YRV2UI()
    local window_width = ImGui.GetWindowWidth()
    ImGui.Spacing()
    ImGui.Dummy((window_width / 2) - 110, 1)
    ImGui.SameLine()
    UI.ColoredText(
        "- YimResupplier V2 -",
        yrv2_color,
        1,
        60
    )
    if Game.IsOnline() then
        local hangar_index   = stats.get_int("MPX_HANGAR_OWNED")
        local bunker_index   = stats.get_int("MPX_PROP_FAC_SLOT5")
        local hangarOwned    = hangar_index ~= 0
        local bunkerOwned    = bunker_index ~= 0
        local whouse_1_owned = stats.get_int("MPX_PROP_WHOUSE_SLOT0") > 0
        local whouse_2_owned = stats.get_int("MPX_PROP_WHOUSE_SLOT1") > 0
        local whouse_3_owned = stats.get_int("MPX_PROP_WHOUSE_SLOT2") > 0
        local whouse_4_owned = stats.get_int("MPX_PROP_WHOUSE_SLOT3") > 0
        local whouse_5_owned = stats.get_int("MPX_PROP_WHOUSE_SLOT4") > 0
        local slot0_owned    = stats.get_int("MPX_PROP_FAC_SLOT0") ~= 0
        local slot1_owned    = stats.get_int("MPX_PROP_FAC_SLOT1") ~= 0
        local slot2_owned    = stats.get_int("MPX_PROP_FAC_SLOT2") ~= 0
        local slot3_owned    = stats.get_int("MPX_PROP_FAC_SLOT3") ~= 0
        local slot4_owned    = stats.get_int("MPX_PROP_FAC_SLOT4") ~= 0
        local acidOwned      = stats.get_int("MPX_XM22_LAB_OWNED") ~= 0
        local wh1Total, wh2Total, wh3Total, wh4Total, wh5Total, ceo_moola = 0, 0, 0, 0, 0, 0
        if CURRENT_BUILD == TARGET_BUILD then
            ImGui.Spacing(); ImGui.BeginTabBar("##BusinessManager", ImGuiTabBarFlags.None)
            if whouse_1_owned or whouse_2_owned or whouse_3_owned or whouse_4_owned or whouse_5_owned then
                if ImGui.BeginTabItem(_T("CEO_WHOUSES_TXT_")) then
                    ImGui.Spacing()
                    if whouse_1_owned then
                        if whouse1.name == "" then SS.GetCEOwarehouseInfo(whouse1) end
                        i_Warehouse1Supplies = stats.get_int("MPX_CONTOTALFORWHOUSE0")
                        if i_Warehouse1Supplies ~= nil and i_Warehouse1Supplies > 0 then
                            local wh1Value = globals.get_int(FreemodeGlobal1 + SS.GetCEOCratesOffset(i_Warehouse1Supplies))
                            wh1Total = wh1Value * i_Warehouse1Supplies
                        end
                        ceo_moola = wh1Total
                        ImGui.SeparatorText(whouse1.name)
                        if whouse1.size.small or whouse1.size.medium or whouse1.size.large then
                            ImGui.BulletText("Cargo Held:"); ImGui.SameLine(); ImGui.Dummy(20, 1); ImGui.SameLine()
                            ImGui.ProgressBar((i_Warehouse1Supplies / whouse1.max), 240, 30,
                                tostring(i_Warehouse1Supplies) ..
                                " Crates (" .. tostring(math.floor((i_Warehouse1Supplies / whouse1.max) * 100)) .. "%)")
                            ImGui.SameLine(); ImGui.Text(Lua_fn.FormatMoney(wh1Total))
                            if whouse1.pos and Self.IsOutside() then
                                if ImGui.Button("Teleport##wh1") then
                                    local myPos = Self.GetPos()
                                    if myPos:distance(whouse1.pos) < 10 then
                                        UI.WidgetSound("Error")
                                        YimToast:ShowWarning("Samurai's Scripts", "It's right there bruh!")
                                    else
                                        UI.WidgetSound("Select")
                                        Self.Teleport(true, whouse1.pos)
                                    end
                                end
                            end
                            if i_Warehouse1Supplies < whouse1.max then
                                ImGui.SameLine(); ImGui.BeginDisabled(b_Warehouse1Loop)
                                if ImGui.Button(string.format("%s##wh1", _T("CEO_RANDOM_CRATES_"))) then
                                    stats.set_bool_masked("MPX_FIXERPSTAT_BOOL1", true, 12)
                                end
                                ImGui.EndDisabled(); ImGui.SameLine(); b_Warehouse1Loop, wh1lUsed = ImGui.Checkbox("Auto##wh1",
                                    b_Warehouse1Loop)
                                if wh1lUsed then
                                    UI.WidgetSound("Nav2")
                                end
                            end
                        end
                    end
                    -- 2
                    if whouse_2_owned then
                        if whouse2.name == "" then SS.GetCEOwarehouseInfo(whouse2) end
                        i_Warehouse2Supplies = stats.get_int("MPX_CONTOTALFORWHOUSE1")
                        if i_Warehouse2Supplies ~= nil and i_Warehouse2Supplies > 0 then
                            local wh2Value = globals.get_int(FreemodeGlobal1 + SS.GetCEOCratesOffset(i_Warehouse2Supplies))
                            wh2Total = wh2Value * i_Warehouse2Supplies
                        end
                        ceo_moola = ceo_moola + wh2Total
                        ImGui.SeparatorText(whouse2.name)
                        if whouse2.size.small or whouse2.size.medium or whouse2.size.large then
                            ImGui.BulletText("Cargo Held:"); ImGui.SameLine(); ImGui.Dummy(20, 1); ImGui.SameLine()
                            ImGui.ProgressBar((i_Warehouse2Supplies / whouse2.max), 240, 30,
                                tostring(i_Warehouse2Supplies) ..
                                " Crates (" .. tostring(math.floor((i_Warehouse2Supplies / whouse2.max) * 100)) .. "%)")
                            ImGui.SameLine(); ImGui.Text(Lua_fn.FormatMoney(wh2Total))
                            if whouse2.pos and Self.IsOutside() then
                                if ImGui.Button("Teleport##wh2") then
                                    local myPos = Self.GetPos()
                                    if myPos:distance(whouse2.pos) < 10 then
                                        UI.WidgetSound("Error")
                                        YimToast:ShowWarning("Samurai's Scripts", "It's right there bruh!")
                                    else
                                        UI.WidgetSound("Select")
                                        Self.Teleport(true, whouse2.pos)
                                    end
                                end
                            end
                            if i_Warehouse2Supplies < whouse2.max then
                                ImGui.SameLine(); ImGui.BeginDisabled(b_Warehouse2Loop)
                                if ImGui.Button(string.format("%s##wh2", _T("CEO_RANDOM_CRATES_"))) then
                                    stats.set_bool_masked("MPX_FIXERPSTAT_BOOL1", true, 13)
                                end
                                ImGui.EndDisabled(); ImGui.SameLine(); b_Warehouse2Loop, wh2lUsed = ImGui.Checkbox("Auto##wh2",
                                    b_Warehouse2Loop)
                                if wh2lUsed then
                                    UI.WidgetSound("Nav2")
                                end
                            end
                        end
                    end
                    -- 3
                    if whouse_3_owned then
                        if whouse3.name == "" then SS.GetCEOwarehouseInfo(whouse3) end
                        i_Warehouse3Supplies = stats.get_int("MPX_CONTOTALFORWHOUSE2")
                        if i_Warehouse3Supplies ~= nil and i_Warehouse3Supplies > 0 then
                            local wh3Value = globals.get_int(FreemodeGlobal1 + SS.GetCEOCratesOffset(i_Warehouse3Supplies))
                            wh3Total = wh3Value * i_Warehouse3Supplies
                        end
                        ceo_moola = ceo_moola + wh3Total
                        ImGui.SeparatorText(whouse3.name)
                        if whouse3.size.small or whouse3.size.medium or whouse3.size.large then
                            ImGui.BulletText("Cargo Held:"); ImGui.SameLine(); ImGui.Dummy(20, 1); ImGui.SameLine()
                            ImGui.ProgressBar((i_Warehouse3Supplies / whouse3.max), 240, 30,
                                tostring(i_Warehouse3Supplies) ..
                                " Crates (" .. tostring(math.floor((i_Warehouse3Supplies / whouse3.max) * 100)) .. "%)")
                            ImGui.SameLine(); ImGui.Text(Lua_fn.FormatMoney(wh3Total))
                            if whouse3.pos and Self.IsOutside() then
                                if ImGui.Button("Teleport##wh3") then
                                    local myPos = Self.GetPos()
                                    if myPos:distance(whouse3.pos) < 10 then
                                        UI.WidgetSound("Error")
                                        YimToast:ShowWarning("Samurai's Scripts", "It's right there bruh!")
                                    else
                                        UI.WidgetSound("Select")
                                        Self.Teleport(true, whouse3.pos)
                                    end
                                end
                            end
                            if i_Warehouse3Supplies < whouse3.max then
                                ImGui.SameLine(); ImGui.BeginDisabled(b_Warehouse3Loop)
                                if ImGui.Button(string.format("%s##wh3", _T("CEO_RANDOM_CRATES_"))) then
                                    stats.set_bool_masked("MPX_FIXERPSTAT_BOOL1", true, 14)
                                end
                                ImGui.EndDisabled(); ImGui.SameLine(); b_Warehouse3Loop, wh3lUsed = ImGui.Checkbox("Auto##wh3",
                                    b_Warehouse3Loop)
                                if wh3lUsed then
                                    UI.WidgetSound("Nav2")
                                end
                            end
                        end
                    end
                    -- 4
                    if whouse_4_owned then
                        if whouse4.name == "" then SS.GetCEOwarehouseInfo(whouse4) end
                        i_Warehouse4Supplies = stats.get_int("MPX_CONTOTALFORWHOUSE3")
                        if i_Warehouse4Supplies ~= nil and i_Warehouse4Supplies > 0 then
                            local wh4Value = globals.get_int(FreemodeGlobal1 + SS.GetCEOCratesOffset(i_Warehouse4Supplies))
                            wh4Total = wh4Value * i_Warehouse4Supplies
                        end
                        ceo_moola = ceo_moola + wh4Total
                        ImGui.SeparatorText(whouse4.name)
                        if whouse4.size.small or whouse4.size.medium or whouse4.size.large then
                            ImGui.BulletText("Cargo Held:"); ImGui.SameLine(); ImGui.Dummy(20, 1); ImGui.SameLine()
                            ImGui.ProgressBar((i_Warehouse4Supplies / whouse4.max), 240, 30,
                                tostring(i_Warehouse4Supplies) ..
                                " Crates (" .. tostring(math.floor((i_Warehouse4Supplies / whouse4.max) * 100)) .. "%)")
                            ImGui.SameLine(); ImGui.Text(Lua_fn.FormatMoney(wh4Total))
                            if whouse4.pos and Self.IsOutside() then
                                if ImGui.Button("Teleport##wh4") then
                                    local myPos = Self.GetPos()
                                    if myPos:distance(whouse4.pos) < 10 then
                                        UI.WidgetSound("Error")
                                        YimToast:ShowWarning("Samurai's Scripts", "It's right there bruh!")
                                    else
                                        UI.WidgetSound("Select")
                                        Self.Teleport(true, whouse4.pos)
                                    end
                                end
                            end
                            if i_Warehouse4Supplies < whouse4.max then
                                ImGui.SameLine(); ImGui.BeginDisabled(b_Warehouse4Loop)
                                if ImGui.Button(string.format("%s##wh4", _T("CEO_RANDOM_CRATES_"))) then
                                    stats.set_bool_masked("MPX_FIXERPSTAT_BOOL1", true, 15)
                                end
                                ImGui.EndDisabled(); ImGui.SameLine(); b_Warehouse4Loop, wh4lUsed = ImGui.Checkbox("Auto##wh4",
                                    b_Warehouse4Loop)
                                if wh4lUsed then
                                    UI.WidgetSound("Nav2")
                                end
                            end
                        end
                    end
                    -- 5
                    if whouse_5_owned then
                        if whouse5.name == "" then SS.GetCEOwarehouseInfo(whouse5) end
                        i_Warehouse5Supplies = stats.get_int("MPX_CONTOTALFORWHOUSE4")
                        if i_Warehouse5Supplies ~= nil and i_Warehouse5Supplies > 0 then
                            local wh5Value = globals.get_int(FreemodeGlobal1 + SS.GetCEOCratesOffset(i_Warehouse5Supplies))
                            wh5Total = wh5Value * i_Warehouse5Supplies
                        end
                        ceo_moola = ceo_moola + wh5Total
                        ImGui.SeparatorText(whouse5.name)
                        if whouse5.size.small or whouse5.size.medium or whouse5.size.large then
                            ImGui.BulletText("Cargo Held:"); ImGui.SameLine(); ImGui.Dummy(20, 1); ImGui.SameLine()
                            ImGui.ProgressBar((i_Warehouse5Supplies / whouse5.max), 240, 30,
                                tostring(i_Warehouse5Supplies) ..
                                " Crates (" .. tostring(math.floor((i_Warehouse5Supplies / whouse5.max) * 100)) .. "%)")
                            ImGui.SameLine(); ImGui.Text(Lua_fn.FormatMoney(wh5Total))
                            if whouse5.pos and Self.IsOutside() then
                                if ImGui.Button("Teleport##wh5") then
                                    local myPos = Self.GetPos()
                                    if myPos:distance(whouse5.pos) < 10 then
                                        UI.WidgetSound("Error")
                                        YimToast:ShowWarning("Samurai's Scripts", "It's right there bruh!")
                                    else
                                        UI.WidgetSound("Select")
                                        Self.Teleport(true, whouse5.pos)
                                    end
                                end
                            end
                            if i_Warehouse5Supplies < whouse5.max then
                                ImGui.SameLine(); ImGui.BeginDisabled(b_Warehouse5Loop)
                                if ImGui.Button(string.format("%s##wh5", _T("CEO_RANDOM_CRATES_"))) then
                                    stats.set_bool_masked("MPX_FIXERPSTAT_BOOL1", true, 16)
                                end
                                ImGui.EndDisabled(); ImGui.SameLine(); b_Warehouse5Loop, wh5lUsed = ImGui.Checkbox("Auto##wh5",
                                    b_Warehouse5Loop)
                                if wh5lUsed then
                                    UI.WidgetSound("Nav2")
                                end
                            end
                        end
                    end
                    ImGui.SeparatorText("MISC"); ImGui.Spacing()
                    local bCond = not script.is_active("gb_contraband_buy") and not script.is_active("fm_content_cargo")
                    ImGui.BeginDisabled(bCond)
                    if ImGui.Button("Finish Cargo Source Mission") then
                        UI.WidgetSound("Select")
                        SS.FinishCargoSourceMission()
                    end
                    ImGui.EndDisabled()
                    if bCond then
                        UI.Tooltip("Start a source mission then press this button to finish it.")
                    end
                    ImGui.BulletText("Total Value: " .. Lua_fn.FormatMoney(ceo_moola))
                    ImGui.EndTabItem()
                end
            end

            if ImGui.BeginTabItem(_T("HANGAR_TXT_")) then
                ImGui.Dummy(1, 5)
                if hangarOwned then
                    local hangar_name = t_Hangars[hangar_index].name
                    local hangar_pos  = t_Hangars[hangar_index].coords
                    ImGui.SeparatorText(hangar_name)
                    i_HangarSupplies = stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL")
                    i_HangarTotalValue    = i_HangarSupplies * 30000
                    ImGui.BulletText("Supplies:"); ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine(); ImGui
                        .ProgressBar(
                            (i_HangarSupplies / 50), 240, 30)
                    if i_HangarSupplies < 50 then
                        ImGui.SameLine()
                        ImGui.BeginDisabled(b_HangarLoop)
                        if ImGui.Button(string.format("%s##hangar", _T("CEO_RANDOM_CRATES_"))) then
                            script.run_in_fiber(function()
                                stats.set_bool_masked("MPX_DLC22022PSTAT_BOOL3", true, 9)
                            end)
                        end
                        ImGui.EndDisabled()
                        ImGui.SameLine(); b_HangarLoop, hlUsed = ImGui.Checkbox("Auto##hangar", b_HangarLoop)
                        if hlUsed then
                            UI.WidgetSound("Nav2")
                        end
                    end
                    ImGui.BulletText("Stock:"); ImGui.SameLine(); ImGui.Dummy(33, 1); ImGui.SameLine();
                    ImGui.ProgressBar((i_HangarSupplies / 50), 240, 30,
                        tostring(i_HangarSupplies) .. " Crates (" .. tostring(math.floor(i_HangarSupplies / 0.5)) .. "%)")
                    ImGui.SameLine(); ImGui.Text("Value: " .. Lua_fn.FormatMoney(i_HangarTotalValue))
                    if Self.IsOutside() then
                        ImGui.Spacing(); ImGui.SeparatorText(_T("QUICK_TP_TXT_"))
                        if ImGui.Button("Teleport To Hangar") then
                            UI.WidgetSound("Select")
                            Self.Teleport(true, hangar_pos)
                        end
                    end
                else
                    ImGui.Text("You don't own a hangar.")
                end
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Bunker") then
                ImGui.Dummy(1, 5)
                if bunkerOwned then
                    ImGui.SeparatorText(t_Bunkers[bunker_index].name)
                    local bunkerUpdgrade1  = stats.get_int("MPX_BUNKER_EQUIPMENT") == 1
                    local bunkerUpdgrade2  = stats.get_int("MPX_BUNKER_STAFF") == 1
                    local bunkerEqLabelCol = "white"
                    local bunkerStLabelCol = "white"
                    if bunkerUpdgrade1 then
                        bunkerEqLabelCol = "green"
                        bunkerOffset1 = globals.get_int(FreemodeGlobal1 + 21256)
                    else
                        bunkerEqLabelCol = "red"
                        bunkerOffset1 = 0
                    end
                    if bunkerUpdgrade2 then
                        bunkerStLabelCol = "green"
                        bunkerOffset2 = globals.get_int(FreemodeGlobal1 + 21255)
                    else
                        bunkerStLabelCol = "red"
                        bunkerOffset2 = 0
                    end
                    local bunkerSupplies = stats.get_int("MPX_MATTOTALFORFACTORY5")
                    local bunkerStock    = stats.get_int("MPX_PRODTOTALFORFACTORY5")
                    i_BunkerTotalValue          = ((globals.get_int(FreemodeGlobal1 + 21254) + bunkerOffset1 + bunkerOffset2) * bunkerStock)
                    ImGui.BulletText("Equipment Upgrade: "); ImGui.SameLine()
                    UI.ColoredText(bunkerUpdgrade1 and "Active" or "Inactive", bunkerEqLabelCol, 0.9, 35)
                    ImGui.SameLine()
                    ImGui.BulletText("Staff Upgrade: "); ImGui.SameLine()
                    UI.ColoredText(bunkerUpdgrade2 and "Active" or "Inactive", bunkerStLabelCol, 0.9, 35)
                    ImGui.Spacing()
                    ImGui.BulletText("Supplies:")
                    ImGui.SameLine()
                    ImGui.Dummy(10, 1)
                    ImGui.SameLine()
                    ImGui.ProgressBar((bunkerSupplies / 100), 240, 30)

                    if bunkerSupplies < 100 then
                        ImGui.SameLine()
                        if ImGui.Button(" Fill Supplies ##Bunker") then
                            globals.set_int(FreemodeGlobal2 + 5 + 1, 1)
                        end
                    end
                    ImGui.BulletText("Stock:"); ImGui.SameLine(); ImGui.Dummy(33, 1); ImGui.SameLine();
                    ImGui.ProgressBar((bunkerStock / 100), 240, 30, tostring(bunkerStock) ..
                        " Crates (" .. tostring(bunkerStock) .. "%)")
                    ImGui.SameLine(); ImGui.Text("Value:"); ImGui.SameLine();
                    ImGui.Text("¤ Blaine County:  " ..
                        Lua_fn.FormatMoney(i_BunkerTotalValue) ..
                        "\n¤ Los Santos:      " .. Lua_fn.FormatMoney(math.floor(i_BunkerTotalValue * 1.5)))
                    if Self.IsOutside() then
                        ImGui.Spacing(); ImGui.SeparatorText("Quick Teleport")
                        if ImGui.Button("Teleport To Bunker") then
                            UI.WidgetSound("Select")
                            Self.Teleport(true, t_Bunkers[bunker_index].coords)
                        end
                    end
                else
                    ImGui.Text("You don't own a bunker.")
                end
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("MC Businesses") then
                -- 0
                if slot0_owned then
                    if bb.slot0.name == "Unknown" then SS.GetMCbusinessInfo(stats.get_int("MPX_FACTORYSLOT0"), bb.slot0) end
                    ImGui.Dummy(1, 10); ImGui.SeparatorText(bb.slot0.name)
                    local slot0_supp  = stats.get_int("MPX_MATTOTALFORFACTORY0")
                    local slot0_stock = stats.get_int("MPX_PRODTOTALFORFACTORY0")
                    i_BikerSlot0TotalValue       = ((globals.get_int(FreemodeGlobal1 + bb.slot0.val_offset)) * slot0_stock)
                    ImGui.BulletText("Supplies:"); ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine();
                    ImGui.ProgressBar((slot0_supp / 100), 240, 30)
                    if slot0_supp < 100 then
                        ImGui.SameLine()
                        if ImGui.Button(" Fill Supplies ##FakeCash") then
                            globals.set_int(FreemodeGlobal2 + 0 + 1, 1)
                        end
                    end
                    ImGui.BulletText("Stock:"); ImGui.SameLine(); ImGui.Dummy(33, 1); ImGui.SameLine();
                    ImGui.ProgressBar((slot0_stock / bb.slot0.unit_max), 240, 30,
                        tostring(math.floor(slot0_stock * (100 / bb.slot0.unit_max))) .. "%")
                    ImGui.SameLine(); ImGui.Text("Value:"); ImGui.SameLine();
                    ImGui.Text("¤ Blaine County:  " ..
                        Lua_fn.FormatMoney(i_BikerSlot0TotalValue) ..
                        "\n¤ Los Santos:      " .. Lua_fn.FormatMoney(math.floor(i_BikerSlot0TotalValue * 1.5)))
                else
                    ImGui.Text("You don't own this business.")
                end
                -- 1
                if slot1_owned then
                    if bb.slot1.name == "Unknown" then SS.GetMCbusinessInfo(stats.get_int("MPX_FACTORYSLOT1"), bb.slot1) end
                    ImGui.Dummy(1, 10); ImGui.SeparatorText(bb.slot1.name)
                    local slot1_supp  = stats.get_int("MPX_MATTOTALFORFACTORY1")
                    local slot1_stock = stats.get_int("MPX_PRODTOTALFORFACTORY1")
                    i_BikerSlot1TotalValue       = ((globals.get_int(FreemodeGlobal1 + bb.slot1.val_offset)) * slot1_stock)
                    ImGui.BulletText("Supplies:"); ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine();
                    ImGui.ProgressBar((slot1_supp / 100), 240, 30)
                    if slot1_supp < 100 then
                        ImGui.SameLine()
                        if ImGui.Button(" Fill Supplies ##slot1") then
                            globals.set_int(FreemodeGlobal2 + 1 + 1, 1)
                        end
                    end
                    ImGui.BulletText("Stock:"); ImGui.SameLine(); ImGui.Dummy(33, 1); ImGui.SameLine();
                    ImGui.ProgressBar((slot1_stock / bb.slot1.unit_max), 240, 30,
                        tostring(math.floor(slot1_stock * (100 / bb.slot1.unit_max))) .. "%")
                    ImGui.SameLine(); ImGui.Text("Value:"); ImGui.SameLine();
                    ImGui.Text("¤ Blaine County:  " ..
                        Lua_fn.FormatMoney(i_BikerSlot1TotalValue) ..
                        "\n¤ Los Santos:      " .. Lua_fn.FormatMoney(math.floor(i_BikerSlot1TotalValue * 1.5)))
                else
                    ImGui.Text("You don't own this business.")
                end
                -- 2
                if slot2_owned then
                    if bb.slot2.name == "Unknown" then SS.GetMCbusinessInfo(stats.get_int("MPX_FACTORYSLOT2"), bb.slot2) end
                    ImGui.Dummy(1, 10); ImGui.SeparatorText(bb.slot2.name)
                    local slot2_supp  = stats.get_int("MPX_MATTOTALFORFACTORY2")
                    local slot2_stock = stats.get_int("MPX_PRODTOTALFORFACTORY2")
                    i_BikerSlot2TotalValue       = ((globals.get_int(FreemodeGlobal1 + bb.slot2.val_offset)) * slot2_stock)
                    ImGui.BulletText("Supplies:"); ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine();
                    ImGui.ProgressBar((slot2_supp / 100), 240, 30)
                    if slot2_supp < 100 then
                        ImGui.SameLine()
                        if ImGui.Button(" Fill Supplies ##slot2") then
                            globals.set_int(FreemodeGlobal2 + 2 + 1, 1)
                        end
                    end
                    ImGui.BulletText("Stock:"); ImGui.SameLine(); ImGui.Dummy(33, 1); ImGui.SameLine();
                    ImGui.ProgressBar((slot2_stock / bb.slot2.unit_max), 240, 30,
                        tostring(math.floor(slot2_stock * (100 / bb.slot2.unit_max))) .. "%")
                    ImGui.SameLine(); ImGui.Text("Value:"); ImGui.SameLine();
                    ImGui.Text("¤ Blaine County:  " ..
                        Lua_fn.FormatMoney(i_BikerSlot2TotalValue) ..
                        "\n¤ Los Santos:      " .. Lua_fn.FormatMoney(math.floor(i_BikerSlot2TotalValue * 1.5)))
                else
                    ImGui.Text("You don't own this business.")
                end
                -- 3
                if slot3_owned then
                    if bb.slot3.name == "Unknown" then SS.GetMCbusinessInfo(stats.get_int("MPX_FACTORYSLOT3"), bb.slot3) end
                    ImGui.Dummy(1, 10); ImGui.SeparatorText(bb.slot3.name)
                    local slot3_supp  = stats.get_int("MPX_MATTOTALFORFACTORY3")
                    local slot3_stock = stats.get_int("MPX_PRODTOTALFORFACTORY3")
                    i_BikerSlot3TotalValue       = ((globals.get_int(FreemodeGlobal1 + bb.slot3.val_offset)) * slot3_stock)
                    ImGui.BulletText("Supplies:"); ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine();
                    ImGui.ProgressBar((slot3_supp / 100), 240, 30)
                    if slot3_supp < 100 then
                        ImGui.SameLine()
                        if ImGui.Button(" Fill Supplies ##slot3") then
                            globals.set_int(FreemodeGlobal2 + 3 + 1, 1)
                        end
                    end
                    ImGui.BulletText("Stock:"); ImGui.SameLine(); ImGui.Dummy(33, 1); ImGui.SameLine();
                    ImGui.ProgressBar((slot3_stock / bb.slot3.unit_max), 240, 30,
                        tostring(math.floor(slot3_stock * (100 / bb.slot3.unit_max))) .. "%")
                    ImGui.SameLine(); ImGui.Text("Value:"); ImGui.SameLine();
                    ImGui.Text("¤ Blaine County:  " ..
                        Lua_fn.FormatMoney(i_BikerSlot3TotalValue) ..
                        "\n¤ Los Santos:      " .. Lua_fn.FormatMoney(math.floor(i_BikerSlot3TotalValue * 1.5)))
                else
                    ImGui.Text("You don't own this business.")
                end
                -- 4
                if slot4_owned then
                    if bb.slot4.name == "Unknown" then SS.GetMCbusinessInfo(stats.get_int("MPX_FACTORYSLOT4"), bb.slot4) end
                    ImGui.Dummy(1, 10); ImGui.SeparatorText(bb.slot4.name)
                    local slot4_supp  = stats.get_int("MPX_MATTOTALFORFACTORY4")
                    local slot4_stock = stats.get_int("MPX_PRODTOTALFORFACTORY4")
                    i_BikerSlot4TotalValue       = ((globals.get_int(FreemodeGlobal1 + bb.slot4.val_offset)) * slot4_stock)
                    ImGui.BulletText("Supplies:"); ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine();
                    ImGui.ProgressBar((slot4_supp / 100), 240, 30)
                    if slot4_supp < 100 then
                        ImGui.SameLine()
                        if ImGui.Button(" Fill Supplies ##slot4") then
                            globals.set_int(FreemodeGlobal2 + 4 + 1, 1)
                        end
                    end
                    ImGui.BulletText("Stock:"); ImGui.SameLine(); ImGui.Dummy(33, 1); ImGui.SameLine();
                    ImGui.ProgressBar((slot4_stock / bb.slot4.unit_max), 240, 30,
                        tostring(math.floor(slot4_stock * (100 / bb.slot4.unit_max))) .. "%")
                    ImGui.SameLine(); ImGui.Text("Value:"); ImGui.SameLine();
                    ImGui.Text("¤ Blaine County:  " ..
                        Lua_fn.FormatMoney(i_BikerSlot4TotalValue) ..
                        "\n¤ Los Santos:      " .. Lua_fn.FormatMoney(math.floor(i_BikerSlot4TotalValue * 1.5)))
                else
                    ImGui.Text("You don't own this business.")
                end

                if acidOwned then
                    ImGui.SeparatorText("Acid Lab")
                    local acidUpdgrade = stats.get_int("MPX_AWD_CALLME") >= 10 and
                    stats.get_int("MPX_XM22_LAB_EQUIP_UPGRADED") == 1
                    local acidUpgradeLabelCol = "white"
                    if acidUpdgrade then
                        acidUpgradeLabelCol = "green"
                        acidOffset = globals.get_int(FreemodeGlobal1 + 17330)
                    else
                        acidUpgradeLabelCol = "red"
                        acidOffset = 0
                    end
                    local acidSupplies = stats.get_int("MPX_MATTOTALFORFACTORY6")
                    local acidStock    = stats.get_int("MPX_PRODTOTALFORFACTORY6")
                    i_AcidLabTotalValue          = ((globals.get_int(FreemodeGlobal1 + 17324) + acidOffset) * acidStock)
                    ImGui.BulletText("Equipment Upgrade: "); ImGui.SameLine()
                    UI.ColoredText(acidUpdgrade and "Active" or "Inactive", acidUpgradeLabelCol, 0.9, 35)
                    ImGui.BulletText("Supplies:")
                    ImGui.SameLine()
                    ImGui.Dummy(10, 1)
                    ImGui.SameLine()
                    ImGui.ProgressBar((acidSupplies / 100), 240, 30)

                    if acidSupplies < 100 then
                        ImGui.SameLine()
                        if ImGui.Button(" Fill Supplies ##acid") then
                            globals.set_int(FreemodeGlobal2 + 6 + 1, 1)
                        end
                    end

                    ImGui.BulletText("Stock:"); ImGui.SameLine(); ImGui.Dummy(33, 1); ImGui.SameLine();
                    ImGui.ProgressBar((acidStock / 160), 240, 30,
                        tostring(acidStock) .. " Sheets (" .. tostring(math.floor(acidStock / 16 * 10)) .. "%)")
                    ImGui.SameLine(); ImGui.Text("Value: " .. Lua_fn.FormatMoney(i_AcidLabTotalValue))
                else
                    ImGui.Text("You don't own an acid lab.")
                end
                if slot0_owned or slot1_owned or slot2_owned or slot3_owned or slot4_owned or acidOwned then
                    ImGui.Separator(); ImGui.Spacing(); ImGui.Text("Approximate Total MC Business Value: " ..
                        Lua_fn.FormatMoney(i_BikerSlot0TotalValue + i_BikerSlot1TotalValue + i_BikerSlot2TotalValue + i_BikerSlot3TotalValue + i_BikerSlot4TotalValue +
                        i_AcidLabTotalValue))
                    UI.Tooltip("Prices may be higher depending on your business upgrades.")
                end
                ------------------------MC Quick TP------------------------------
                if Self.IsOutside() then
                    ImGui.Spacing(); ImGui.SeparatorText("Quick Teleport")
                    ImGui.BeginDisabled(not slot0_owned)
                    if ImGui.Button(("To %s"):format(bb.slot0.name)) then
                        script.run_in_fiber(function()
                            local blip = HUD.GET_FIRST_BLIP_INFO_ID(bb.slot0.blip)
                            if HUD.DOES_BLIP_EXIST(blip) then
                                UI.WidgetSound("Select")
                                local coords = HUD.GET_BLIP_COORDS(blip)
                                Self.Teleport(false, coords)
                            end
                        end)
                    end
                    ImGui.EndDisabled()
                    UI.HelpMarker(_T("QUICK_TP_WARN_"), "#FFA134")
                    ImGui.SameLine()
                    ImGui.BeginDisabled(not slot1_owned)
                    if ImGui.Button(("To %s"):format(bb.slot1.name)) then
                        script.run_in_fiber(function()
                            local blip = HUD.GET_FIRST_BLIP_INFO_ID(bb.slot1.blip)
                            if HUD.DOES_BLIP_EXIST(blip) then
                                UI.WidgetSound("Select")
                                local coords = HUD.GET_BLIP_COORDS(blip)
                                Self.Teleport(false, coords)
                            end
                        end)
                    end
                    ImGui.EndDisabled()
                    UI.HelpMarker(_T("QUICK_TP_WARN_"), "#FFA134")
                    ImGui.SameLine()
                    ImGui.BeginDisabled(not slot2_owned)
                    if ImGui.Button(("To %s"):format(bb.slot2.name)) then
                        script.run_in_fiber(function()
                            local blip = HUD.GET_FIRST_BLIP_INFO_ID(bb.slot2.blip)
                            if HUD.DOES_BLIP_EXIST(m_blip) then
                                UI.WidgetSound("Select")
                                local coords = HUD.GET_BLIP_COORDS(blip)
                                Self.Teleport(false, coords)
                            end
                        end)
                    end
                    ImGui.EndDisabled()
                    UI.HelpMarker(_T("QUICK_TP_WARN_"), "#FFA134")
                    ImGui.BeginDisabled(not slot3_owned)
                    if ImGui.Button(("To %s"):format(bb.slot3.name)) then
                        script.run_in_fiber(function()
                            local blip = HUD.GET_FIRST_BLIP_INFO_ID(bb.slot3.blip)
                            if HUD.DOES_BLIP_EXIST(blip) then
                                UI.WidgetSound("Select")
                                local coords = HUD.GET_BLIP_COORDS(blip)
                                Self.Teleport(false, coords)
                            end
                        end)
                    end
                    ImGui.EndDisabled()
                    UI.HelpMarker(_T("QUICK_TP_WARN_"), "#FFA134")
                    ImGui.SameLine()
                    ImGui.BeginDisabled(not slot4_owned)
                    if ImGui.Button(("To %s"):format(bb.slot4.name)) then
                        script.run_in_fiber(function()
                            local blip = HUD.GET_FIRST_BLIP_INFO_ID(bb.slot4.blip)
                            if HUD.DOES_BLIP_EXIST(blip) then
                                UI.WidgetSound("Select")
                                local coords = HUD.GET_BLIP_COORDS(blip)
                                Self.Teleport(false, coords)
                            end
                        end)
                    end
                    ImGui.EndDisabled()
                    UI.HelpMarker(_T("QUICK_TP_WARN_"), "#FFA134")
                    ImGui.SameLine()
                    ImGui.BeginDisabled(not acidOwned)
                    if ImGui.Button("To The Freak Shop") then
                        script.run_in_fiber(function()
                            local acid_blip = HUD.GET_FIRST_BLIP_INFO_ID(848)
                            local acid_coords
                            if HUD.DOES_BLIP_EXIST(acid_blip) then
                                UI.WidgetSound("Select")
                                acid_coords = HUD.GET_BLIP_COORDS(acid_blip)
                                Self.Teleport(false, acid_coords)
                            end
                        end)
                    end
                    ImGui.EndDisabled()
                    UI.HelpMarker(_T("QUICK_TP_WARN_"), "#FFA134")
                end
                ImGui.EndTabItem()
            end
            if ImGui.BeginTabItem("Safes") then
                local ncOwned = stats.get_int("MPX_NIGHTCLUB_OWNED") ~= 0
                local acOwned = stats.get_int("MPX_ARCADE_OWNED") ~= 0
                local agOwned = stats.get_int("MPX_FIXER_HQ_OWNED") ~= 0
                local chOwned = stats.get_int("MPX_PROP_CLUBHOUSE") ~= 0
                local boOwned = stats.get_int("MPX_BAIL_OFFICE_OWNED") ~= 0
                local syOwned = stats.get_int("MPX_SALVAGE_YARD_OWNED") ~= 0
                local hdOwned = stats.get_int("MPX_HACKER_DEN_OWNED") ~= 0
                ImGui.Dummy(1, 10)
                if ncOwned then
                    ImGui.Spacing(); ImGui.SeparatorText("Nightclub")
                    local currentNcPop    = stats.get_int("MPX_CLUB_POPULARITY")
                    local popDiff         = 1000 - currentNcPop
                    local currNcSafeMoney = stats.get_int("MPX_CLUB_SAFE_CASH_VALUE")
                    ImGui.BulletText("Popularity: "); ImGui.SameLine(); ImGui.Dummy(18, 1); ImGui.SameLine();
                    ImGui.ProgressBar(currentNcPop / 1000, 240, 30, tostring(currentNcPop))
                    if currentNcPop < 1000 then
                        ImGui.SameLine()
                        if ImGui.Button("Max Popularity") then
                            UI.WidgetSound("Select")
                            stats.set_int("MPX_CLUB_POPULARITY", currentNcPop + popDiff)
                            YimToast:ShowSuccess("Samurai's Scripts", "Nightclub popularity increased.")
                        end
                    end
                    ImGui.BulletText("Safe: "); ImGui.SameLine(); ImGui.Dummy(60, 1); ImGui.SameLine();
                    ImGui.ProgressBar(currNcSafeMoney / 250000, 240, 30, Lua_fn.FormatMoney(currNcSafeMoney))
                    if Self.IsOutside() then
                        ImGui.SameLine()
                        if ImGui.Button("Teleport##nc") then
                            UI.WidgetSound("Select")
                            script.run_in_fiber(function()
                                local ncBlip = HUD.GET_FIRST_BLIP_INFO_ID(614)
                                local ncLoc
                                if HUD.DOES_BLIP_EXIST(ncBlip) then
                                    ncLoc = HUD.GET_BLIP_COORDS(ncBlip)
                                    Self.Teleport(false, ncLoc)
                                end
                            end)
                        end
                    end
                else
                    ImGui.Text("You don't own a nightclub.")
                end

                if acOwned then
                    ImGui.Spacing()
                    ImGui.SeparatorText("Arcade")
                    local currArSafeMoney = stats.get_int("MPX_ARCADE_SAFE_CASH_VALUE")
                    ImGui.BulletText("Safe: ")
                    ImGui.SameLine(); ImGui.Dummy(60, 1); ImGui.SameLine();
                    ImGui.ProgressBar(currArSafeMoney / 100000, 240, 30, Lua_fn.FormatMoney(currArSafeMoney))
                    if Self.IsOutside() then
                        ImGui.SameLine()
                        if ImGui.Button("Teleport##arcade") then
                            UI.WidgetSound("Select")
                            script.run_in_fiber(function()
                                local arBlip = HUD.GET_FIRST_BLIP_INFO_ID(740)
                                local arLoc
                                if HUD.DOES_BLIP_EXIST(arBlip) then
                                    arLoc = HUD.GET_BLIP_COORDS(arBlip)
                                    Self.Teleport(false, arLoc)
                                end
                            end)
                        end
                    end
                else
                    ImGui.Text("You don't own an arcade.")
                end

                if agOwned then
                    ImGui.Spacing(); ImGui.SeparatorText("Agency")
                    local currAgSafeMoney = stats.get_int("MPX_FIXER_SAFE_CASH_VALUE")
                    ImGui.BulletText("Safe: "); ImGui.SameLine(); ImGui.Dummy(60, 1); ImGui.SameLine();
                    ImGui.ProgressBar(currAgSafeMoney / 250000, 240, 30, Lua_fn.FormatMoney(currAgSafeMoney))
                    if Self.IsOutside() then
                        ImGui.SameLine()
                        if ImGui.Button("Teleport##agnc") then
                            UI.WidgetSound("Select")
                            script.run_in_fiber(function()
                                local agncBlip = HUD.GET_FIRST_BLIP_INFO_ID(826)
                                local agncLoc
                                if HUD.DOES_BLIP_EXIST(agncBlip) then
                                    agncLoc = HUD.GET_BLIP_COORDS(agncBlip)
                                    Self.Teleport(false, agncLoc)
                                end
                            end)
                        end
                    end
                else
                    ImGui.Text("You don't own an agency.")
                end

                if chOwned then
                    ImGui.Spacing(); ImGui.SeparatorText("MC Clubhouse")
                    local currClubHouseBarProfit = stats.get_int("MPX_BIKER_BAR_RESUPPLY_CASH")
                    ImGui.BulletText("Bar Earnings:"); ImGui.SameLine(); ImGui.Dummy(2, 1); ImGui.SameLine();
                    ImGui.ProgressBar(currClubHouseBarProfit / 100000, 240, 30,
                        Lua_fn.FormatMoney(currClubHouseBarProfit))
                    if Self.IsOutside() then
                        ImGui.SameLine()
                        if ImGui.Button("Teleport##mc") then
                            UI.WidgetSound("Select")
                            script.run_in_fiber(function()
                                local mcBlip = HUD.GET_FIRST_BLIP_INFO_ID(492)
                                local mcLoc
                                if HUD.DOES_BLIP_EXIST(mcBlip) then
                                    mcLoc = HUD.GET_BLIP_COORDS(mcBlip)
                                    Self.Teleport(false, mcLoc)
                                end
                            end)
                        end
                    end
                else
                    ImGui.Text("You don't own a clubhouse.")
                end

                if boOwned then
                    ImGui.Spacing(); ImGui.SeparatorText("Bail Office")
                    local currBailSafe = stats.get_int("MPX_BAIL_SAFE_CASH_VALUE")
                    ImGui.BulletText("Safe:"); ImGui.SameLine(); ImGui.Dummy(60, 1); ImGui.SameLine();
                    ImGui.ProgressBar(currBailSafe / 100000, 240, 30, Lua_fn.FormatMoney(currBailSafe))
                    if Self.IsOutside() then
                        ImGui.SameLine()
                        if ImGui.Button("Teleport##bail") then
                            UI.WidgetSound("Select")
                            script.run_in_fiber(function()
                                local bailBlip = HUD.GET_FIRST_BLIP_INFO_ID(893)
                                local bailLoc
                                if HUD.DOES_BLIP_EXIST(bailBlip) then
                                    bailLoc   = HUD.GET_BLIP_COORDS(bailBlip)
                                    bailLoc.y = bailLoc.y + 1.2
                                    Self.Teleport(false, bailLoc)
                                end
                            end)
                        end
                    end
                else
                    ImGui.Text("You don't own a bail office.")
                end

                if syOwned then
                    ImGui.Spacing(); ImGui.SeparatorText("Salvage Yard")
                    local currSalvSafe = stats.get_int("MPX_SALVAGE_SAFE_CASH_VALUE")
                    ImGui.BulletText("Safe: "); ImGui.SameLine(); ImGui.Dummy(60, 1); ImGui.SameLine();
                    ImGui.ProgressBar(currSalvSafe / 250000, 240, 30, Lua_fn.FormatMoney(currSalvSafe))
                    if Self.IsOutside() then
                        ImGui.SameLine()
                        if ImGui.Button("Teleport##salvage") then
                            UI.WidgetSound("Select")
                            script.run_in_fiber(function()
                                local slvgBlip = HUD.GET_FIRST_BLIP_INFO_ID(867)
                                if HUD.DOES_BLIP_EXIST(slvgBlip) then
                                    local slvgLoc = HUD.GET_BLIP_COORDS(slvgBlip)
                                    Self.Teleport(false, slvgLoc)
                                end
                            end)
                        end
                    end
                else
                    ImGui.Text("You don't own a salvage yard.")
                end

                if hdOwned then
                    ImGui.Spacing(); ImGui.SeparatorText("Garment Factory")
                    local currH24Safe = stats.get_int("MPX_HDEN24_SAFE_CASH_VALUE")
                    ImGui.BulletText("Safe: "); ImGui.SameLine(); ImGui.Dummy(60, 1); ImGui.SameLine();
                    ImGui.ProgressBar(currH24Safe / 100000, 240, 30, Lua_fn.FormatMoney(currH24Safe))
                    if Self.IsOutside() then
                        ImGui.SameLine()
                        if ImGui.Button("Teleport##H24") then
                            UI.WidgetSound("Select")
                            script.run_in_fiber(function()
                                local H24Blip = HUD.GET_FIRST_BLIP_INFO_ID(900)
                                if HUD.DOES_BLIP_EXIST(H24Blip) then
                                    local H24Loc = HUD.GET_BLIP_COORDS(H24Blip)
                                    Self.Teleport(false, H24Loc)
                                end
                            end)
                        end
                    end
                else
                    ImGui.Text("You don't own a garment factory.")
                end

                if ncOwned or acOwned or agOwned or chOwned or boOwned or syOwned or hdOwned then
                    if Self.IsOutside() then
                        ImGui.Dummy(1, 10)
                        UI.ColoredText(_T("QUICK_TP_WARN2_"), "#FFA134", 1, 40)
                    end
                end
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("MISC") then
                ImGui.Dummy(1, 5); ImGui.SeparatorText("Business Hub")
                if ImGui.Button("Master Control Terminal") then
                    if not Self.IsBrowsingApps() then
                        script.run_in_fiber(function(mct)
                            if globals.get_int(BusinessHubGlobal1) ~= 0 then
                                globals.set_int(BusinessHubGlobal1, 0)
                            end

                            Await(Game.RequestScript, "appArcadeBusinessHub")
                            UI.WidgetSound("Select")
                            i_BhubScriptHandle = SYSTEM.START_NEW_SCRIPT("appArcadeBusinessHub", 1424) -- STACK_SIZE_DEFAULT
                            SCRIPT.SET_SCRIPT_AS_NO_LONGER_NEEDED("appArcadeBusinessHub")
                            mct:sleep(100)
                            gui.toggle(false)

                            while script.is_active("appArcadeBusinessHub") do
                                if globals.get_int(BusinessHubGlobal2) == -1 then
                                    globals.set_int(BusinessHubGlobal1, 0)
                                end
                                mct:yield()
                            end

                            repeat
                                mct:sleep(10)
                            until not Self.IsBrowsingApps()
                            globals.set_int(BusinessHubGlobal1, 0)
                            i_BhubScriptHandle = 0
                        end)
                    else
                        UI.WidgetSound("Error")
                    end
                end
                ImGui.SeparatorText("Cooldowns")
                mc_work_cd, mcworkUsed = ImGui.Checkbox("MC Club Work", mc_work_cd)
                if mcworkUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("mc_work_cd", mc_work_cd)
                end

                ImGui.SameLine(); ImGui.Dummy(58, 1); ImGui.SameLine()
                hangar_cd, hcdUsed = ImGui.Checkbox("Hangar Crate Steal", hangar_cd)
                if hcdUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("hangar_cd", hangar_cd)
                end

                nc_management_cd, ncmanagementUsed = ImGui.Checkbox("Nightclub Management", nc_management_cd)
                if ncmanagementUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("nc_management_cd", nc_management_cd)
                end

                ImGui.SameLine()
                nc_vip_mission_chance, nvipmcUsed = ImGui.Checkbox("Always Troublemaker", nc_vip_mission_chance)
                UI.HelpMarker(false,
                    "Always spawns the troublemaker nightclub missions and disables the knocked out VIP missions.")
                if nvipmcUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("nc_vip_mission_chance", nc_vip_mission_chance)
                end

                ie_vehicle_steal_cd, ievstealUsed = ImGui.Checkbox("I/E Vehicle Sourcing", ie_vehicle_steal_cd)
                if ievstealUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("ie_vehicle_steal_cd", ie_vehicle_steal_cd)
                end

                ImGui.SameLine(); ImGui.Dummy(12, 1); ImGui.SameLine()
                ie_vehicle_sell_cd, ievsellUsed = ImGui.Checkbox("I/E Vehicle Selling", ie_vehicle_sell_cd)
                if ievsellUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("ie_vehicle_sell_cd", ie_vehicle_sell_cd)
                end

                ceo_crate_buy_cd, ceobUsed = ImGui.Checkbox("CEO Crate Buy", ceo_crate_buy_cd)
                if ceobUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("ceo_crate_buy_cd", ceo_crate_buy_cd)
                end

                ImGui.SameLine(); ImGui.Dummy(55, 1); ImGui.SameLine()
                ceo_crate_sell_cd, ceosUsed = ImGui.Checkbox("CEO Crate Sell", ceo_crate_sell_cd)
                if ceosUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("ceo_crate_sell_cd", ceo_crate_sell_cd)
                end

                security_missions_cd, smcdUsed = ImGui.Checkbox("Security Missions", security_missions_cd)
                if smcdUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("security_missions_cd", security_missions_cd)
                end

                ImGui.SameLine(); ImGui.Dummy(29, 1); ImGui.SameLine()
                ImGui.BeginDisabled()
                payphone_hits_cd, _ = ImGui.Checkbox("Payphone Hits [x]", payphone_hits_cd)
                UI.SetClipBoardText("https://github.com/YimMenu-Lua/PayphoneHits",
                    ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and SS.IsKeyJustPressed(0x09)
                )
                ImGui.EndDisabled();
                UI.Tooltip("Use ShinyWasabi's Payphone Hits script instead. Press [TAB] to copy the GitHub link.")

                dax_work_cd, dwcdUsed = ImGui.Checkbox("Dax Work Cooldown", dax_work_cd)
                if dwcdUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("dax_work_cd", dax_work_cd)
                end

                ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
                garment_rob_cd, grcdUsed = ImGui.Checkbox("Garment Factory Files", garment_rob_cd)
                if grcdUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("garment_rob_cd", garment_rob_cd)
                end

                ImGui.Dummy(1, 5)
                if mc_work_cd and hangar_cd and nc_management_cd and nc_vip_mission_chance and security_missions_cd and
                    ie_vehicle_steal_cd and ie_vehicle_sell_cd and ceo_crate_buy_cd and ceo_crate_sell_cd and dax_work_cd and
                    garment_rob_cd then
                    sBtnLabel, bParam = "Uncheck All", false
                else
                    sBtnLabel, bParam = "Check All", true
                end
                if ImGui.Button(sBtnLabel or "", 120, 40) then
                    UI.WidgetSound("Select")
                    mc_work_cd = bParam; CFG:SaveItem("mc_work_cd", mc_work_cd)
                    hangar_cd = bParam; CFG:SaveItem("hangar_cd", hangar_cd)
                    nc_management_cd = bParam; CFG:SaveItem("nc_management_cd", nc_management_cd)
                    nc_vip_mission_chance = bParam; CFG:SaveItem("nc_vip_mission_chance", nc_vip_mission_chance)
                    security_missions_cd = bParam; CFG:SaveItem("security_missions_cd", security_missions_cd)
                    ie_vehicle_steal_cd = bParam; CFG:SaveItem("ie_vehicle_steal_cd", ie_vehicle_steal_cd)
                    ie_vehicle_sell_cd = bParam; CFG:SaveItem("ie_vehicle_sell_cd", ie_vehicle_sell_cd)
                    ceo_crate_buy_cd = bParam; CFG:SaveItem("ceo_crate_buy_cd", ceo_crate_buy_cd)
                    ceo_crate_sell_cd = bParam; CFG:SaveItem("ceo_crate_sell_cd", ceo_crate_sell_cd)
                    dax_work_cd = bParam; CFG:SaveItem("dax_work_cd", dax_work_cd)
                    garment_rob_cd = bParam; CFG:SaveItem("garment_rob_cd", dax_work_cd)
                end

                ImGui.Spacing(); ImGui.SeparatorText("Sell Missions")
                ImGui.Spacing(); UI.WrappedText(
                    "These options will not be saved. Each button disables the most tedious sell missions for that business.",
                    32)
                ImGui.Spacing(); UI.ColoredText(
                    "[ ! ] NOTE: If you plan on selling more than once for the same business (example: MC businesses or more than one CEO warehouse), please switch sessions after finishing the first sale to reset the missions, otherwise a sesond sell mission may fail to start.",
                    'yellow', 0.69, 30)

                if ImGui.Button("Easy Biker Sell Missions") then
                    UI.WidgetSound("Select")
                    for _, index in pairs(t_mc_sell_mission_types) do
                        if globals.get_int(index) == 0 then
                            globals.set_int(index, 1)
                        end
                    end
                    YimToast:ShowSuccess("Samurai's Scripts", "Successfully disabled the most annoying missions.")
                end

                ImGui.SameLine(); ImGui.Dummy(41, 1); ImGui.SameLine()
                if ImGui.Button("Easy CEO Sell Missions") then
                    UI.WidgetSound("Select")
                    for _, index in pairs(t_ceo_sell_mission_types) do
                        if globals.get_int(index) == 0 then
                            globals.set_int(index, 1)
                        end
                    end
                    YimToast:ShowSuccess("Samurai's Scripts", "Successfully disabled the most annoying missions.")
                end

                if ImGui.Button("Easy Nightclub Sell Missions") then
                    UI.WidgetSound("Select")
                    for _, index in pairs(t_nc_sell_mission_types) do
                        if globals.get_float(index) > 0.0 then
                            globals.get_float(index, 0.0)
                        end
                    end
                    YimToast:ShowSuccess("Samurai's Scripts", "Successfully disabled the most annoying missions.")
                end

                ImGui.SameLine(); ImGui.Dummy(10, 1); ImGui.SameLine()
                if ImGui.Button("Easy Hangar Sell Missions") then
                    UI.WidgetSound("Select")
                    for _, index in pairs(t_hangar_sell_mission_types) do
                        if globals.get_float(index) > 0.0 then
                            globals.get_float(index, 0.0)
                        end
                    end
                    YimToast:ShowSuccess("Samurai's Scripts", "Successfully disabled the most annoying missions.")
                end
                ImGui.EndTabItem()
            end
            if ImGui.BeginTabItem("Sales") then
                UI.WrappedText(
                    "This is shitty unreliable code with little to no effort put into it.\n\nOnly these businesses are supported:",
                    35
                )
                ImGui.BulletText("Bunker")
                ImGui.BulletText("Hangar (Air only)")
                ImGui.BulletText("CEO Warehouses")
                ImGui.BulletText("MC Businesses")
                ImGui.BulletText("Acid Lab")
                ImGui.Dummy(1, 10)
                ImGui.SeparatorText(string.format("Currently Selling: %s", s_SellScriptDisplayName))
                ImGui.BeginDisabled(b_HasTriggeredAutosell)
                autosell, autosellUsed = ImGui.Checkbox("Auto-Sell", autosell)
                if autosellUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("autosell", autosell)
                end
                ImGui.EndDisabled()
                UI.Tooltip(
                    "Automatically finishes a sale mission 20 seconds after it starts. Doesn't require you to interact with anything other than starting the mission."
                )
                if script.is_active("fm_content_smuggler_sell") then
                    UI.ColoredText("Land sales are currently not supported.", 'red', 0.8, 25)
                else
                    ImGui.BeginDisabled(autosell or b_HasTriggeredAutosell or not b_SellScriptIsRunning)
                    if ImGui.Button("Manually Finish Sale") then
                        UI.WidgetSound("Select")
                        SS.FinishSale(s_SellScriptName)
                        b_HasTriggeredAutosell = true
                        script.run_in_fiber(function(s)
                            repeat
                                s:sleep(100)
                            until not b_SellScriptIsRunning
                            b_HasTriggeredAutosell = false
                        end)
                    end
                    ImGui.EndDisabled()
                end
                ImGui.EndTabItem()
            end
            ImGui.EndTabBar()
        else
            ImGui.Dummy(1, 5); ImGui.SameLine(); ImGui.Text("Outdated.")
        end
    else
        ImGui.Dummy(1, 5); ImGui.Text(_T("GENERIC_UNAVAILABLE_SP_"))
    end
end
