---@diagnostic disable: undefined-global, lowercase-global

local sCooldownButtonLabel, bCooldownParam
local i_HangarSupplies = 0
local i_HangarTotalValue = 0
local i_BunkerTotalValue = 0
local i_AcidLabTotalValue = 0
local b_AcidLabOwned = false

local function CalcTotalBusinessIncome()
    return Sum(
        YRV3.i_BikerValueSum,
        YRV3.i_CEOvalueSum,
        YRV3.i_SafeCashValueSum,
        i_HangarTotalValue,
        i_BunkerTotalValue,
        i_AcidLabTotalValue
    )
end

local function GetAllCDCheckboxes()
    return mc_work_cd
    and hangar_cd
    and nc_management_cd
    and nc_vip_mission_chance
    and security_missions_cd
    and ie_vehicle_steal_cd
    and ie_vehicle_sell_cd
    and ceo_crate_buy_cd
    and ceo_crate_sell_cd
    and dax_work_cd
    and garment_rob_cd
end

local function drawCEOwarehouses()
    if not YRV3:DoesPlayerOwnAnyWarehouse() then
        ImGui.Text("You don't own any CEO warehouses")
        return
    end

    YRV3.i_CEOvalueSum = 0

    ImGui.SetWindowFontScale(0.9)
    for i, data in ipairs(YRV3.OwnedWarehouseData) do
        local slot = i - 1
        data.isOwned = stats.get_int(("MPX_PROP_WHOUSE_SLOT%d"):format(slot)) > 0

        if data.isOwned then

            if not YRV3.OwnedWarehouseData[i].wasChecked then
                YRV3:PopulateCEOwarehouseSlot(i)
            else
                ImGui.Dummy(1, 5)
                local warehouse = YRV3.OwnedWarehouseData[i]

                data.i_TotalSupplies = stats.get_int(("MPX_CONTOTALFORWHOUSE%d"):format(slot))
                data.i_TotalValue = YRV3:GetCEOCratesValue(data.i_TotalSupplies or 0)
                YRV3.i_CEOvalueSum = YRV3.i_CEOvalueSum + data.i_TotalValue

                if warehouse.name and warehouse.size and warehouse.max then
                    ImGui.PushID(("warehouse##"):format(i))
                    ImGui.SeparatorText(tostring(warehouse.name))
                    ImGui.BulletText("Cargo Held:")
                    ImGui.SameLine()
                    ImGui.Dummy(20, 1)
                    ImGui.SameLine()

                    ImGui.ProgressBar(
                        (data.i_TotalSupplies / warehouse.max),
                        240,
                        30,
                        string.format(
                            "%d Crates (%d%%)",
                            data.i_TotalSupplies,
                            (math.floor(data.i_TotalSupplies / warehouse.max) * 100)
                        )
                    )

                    ImGui.SameLine()
                    ImGui.Text(Lua_fn.FormatMoney(data.i_TotalValue))

                    if warehouse.pos then
                        if ImGui.Button(("Teleport##"):format(i)) then
                            YRV3:Teleport(warehouse.pos)
                        end
                    end

                    ImGui.SameLine()
                    ImGui.BeginDisabled(data.i_TotalSupplies >= warehouse.max)
                        ImGui.BeginDisabled(warehouse.autoFill)
                            if ImGui.Button(string.format("%s##wh%d", _T("CEO_RANDOM_CRATES_"), i)) then
                                stats.set_bool_masked(
                                    "MPX_FIXERPSTAT_BOOL1",
                                    true,
                                    i + 11
                                )
                            end
                        ImGui.EndDisabled()

                        ImGui.SameLine()
                        YRV3.OwnedWarehouseData[i].autoFill, _ = ImGui.Checkbox(("Auto##wh%d"):format(i), YRV3.OwnedWarehouseData[i].autoFill)

                        if UI.IsItemClicked("lmb") then
                            UI.WidgetSound("Nav2")
                        end
                    ImGui.EndDisabled()
                    ImGui.PopID()
                end
            end
        end
    end

    if YRV3:DoesPlayerOwnAnyWarehouse() then
        ImGui.Dummy(1, 5)
        ImGui.SeparatorText("MISC")
        ImGui.Spacing()

        local bCond = not (
            script.is_active("gb_contraband_buy")
            and script.is_active("fm_content_cargo")
        )

        ImGui.BeginDisabled(bCond)
            if ImGui.Button("Finish Cargo Source Mission") then
                UI.WidgetSound("Select")
                YRV3:FinishCEOCargoSourceMission()
            end
        ImGui.EndDisabled()

        if bCond then
            UI.Tooltip("Start a source mission then press this button to finish it.")
        end

        ImGui.BulletText("Total Value: " .. Lua_fn.FormatMoney(YRV3.i_CEOvalueSum))
    end
    ImGui.SetWindowFontScale(1)
end

local function drawHangar()
    local hangar_index = stats.get_int("MPX_HANGAR_OWNED")
    local hangarOwned = hangar_index ~= 0

    if not hangarOwned then
        ImGui.Text("You don't own a hangar.")
        return
    end

    local hangar_name = t_Hangars[hangar_index].name
    local hangar_pos = t_Hangars[hangar_index].coords

    ImGui.SeparatorText(hangar_name)
    i_HangarSupplies = stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL")
    i_HangarTotalValue = i_HangarSupplies * 30000

    ImGui.BulletText("Supplies:")
    ImGui.SameLine()
    ImGui.Dummy(10, 1)
    ImGui.SameLine()
    ImGui.ProgressBar(
        (i_HangarSupplies / 50),
        240,
        30
    )

    if i_HangarSupplies < 50 then
        ImGui.SameLine()

        ImGui.BeginDisabled(YRV3.b_HangarLoop)
            if ImGui.Button(string.format("%s##hangar", _T("CEO_RANDOM_CRATES_"))) then
                script.run_in_fiber(function()
                    stats.set_bool_masked("MPX_DLC22022PSTAT_BOOL3", true, 9)
                end)
            end
        ImGui.EndDisabled()

        ImGui.SameLine()
        YRV3.b_HangarLoop, hlUsed = ImGui.Checkbox("Auto##hangar", YRV3.b_HangarLoop)

        if hlUsed then
            UI.WidgetSound("Nav2")
        end
    end

    ImGui.BulletText("Stock:")
    ImGui.SameLine()
    ImGui.Dummy(33, 1)
    ImGui.SameLine()
    ImGui.ProgressBar(
        (i_HangarSupplies / 50),
        240,
        30,
        string.format("%d Crates (%d%%)", i_HangarSupplies, math.floor(i_HangarSupplies / 0.5))
    )

    ImGui.SameLine()
    ImGui.Text(string.format("Value: %s", Lua_fn.FormatMoney(i_HangarTotalValue)))

    ImGui.Spacing()
    ImGui.SeparatorText(_T("QUICK_TP_TXT_"))

    if ImGui.Button("Teleport To Hangar") then
        UI.WidgetSound("Select")
        YRV3:Teleport(hangar_pos, true)
    end
end

local function drawBunker()
    local bunker_index = stats.get_int("MPX_PROP_FAC_SLOT5")
    local bunkerOwned = bunker_index ~= 0

    if not bunkerOwned then
        ImGui.Text("You don't own a bunker.")
        return
    end

    ImGui.SeparatorText(t_Bunkers[bunker_index].name)

    local bunkerUpdgrade1 = stats.get_int("MPX_BUNKER_EQUIPMENT") == 1
    local bunkerUpdgrade2 = stats.get_int("MPX_BUNKER_STAFF") == 1
    local bunkerEqLabelCol = "white"
    local bunkerStLabelCol = "white"

    if bunkerUpdgrade1 then
        bunkerOffset1 = globals.get_int(FreemodeGlobal1 + 21256)
        bunkerEqLabelCol = "green"
    else
        bunkerOffset1 = 0
        bunkerEqLabelCol = "red"
    end

    if bunkerUpdgrade2 then
        bunkerOffset2 = globals.get_int(FreemodeGlobal1 + 21255)
        bunkerStLabelCol = "green"
    else
        bunkerOffset2 = 0
        bunkerStLabelCol = "red"
    end

    local bunkerSupplies = stats.get_int("MPX_MATTOTALFORFACTORY5")
    local bunkerStock = stats.get_int("MPX_PRODTOTALFORFACTORY5")
    i_BunkerTotalValue = (globals.get_int(FreemodeGlobal1 + 21254) + bunkerOffset1 + bunkerOffset2) * bunkerStock

    ImGui.BulletText("Equipment Upgrade: ")

    ImGui.SameLine()
    UI.ColoredText(bunkerUpdgrade1 and "Active" or "Inactive", bunkerEqLabelCol, 0.9, 35)

    ImGui.SameLine()
    ImGui.BulletText("Staff Upgrade: ")

    ImGui.SameLine()
    UI.ColoredText(bunkerUpdgrade2 and "Active" or "Inactive", bunkerStLabelCol, 0.9, 35)

    ImGui.Spacing()
    ImGui.BulletText("Supplies:")

    ImGui.SameLine()
    ImGui.Dummy(10, 1)
    ImGui.SameLine()
    ImGui.ProgressBar((bunkerSupplies / 100), 240, 30)

    ImGui.SameLine()
    ImGui.BeginDisabled(bunkerSupplies >= 100)
        if ImGui.Button(" Fill Supplies ##bunker") then
            globals.set_int(FreemodeGlobal2 + 5 + 1, 1)
        end
    ImGui.EndDisabled()

    ImGui.BulletText("Stock:")

    ImGui.SameLine()
    ImGui.Dummy(33, 1)
    ImGui.SameLine()

    ImGui.ProgressBar(
        (bunkerStock / 100),
        240,
        30,
        string.format("%d Crates (%d%%)", bunkerStock, bunkerStock)
    )

    ImGui.SameLine()
    ImGui.Text("Value:")
    ImGui.SameLine()

    ImGui.Text(
        string.format(
            "¤ Blaine County: %s\n¤ Los Santos:      %s",
            Lua_fn.FormatMoney(i_BunkerTotalValue),
            Lua_fn.FormatMoney(math.floor(i_BunkerTotalValue * 1.5))
        )
    )

    ImGui.Spacing()
    ImGui.SeparatorText("Quick Teleport")

    if ImGui.Button("Teleport To Bunker") then
        YRV3:Teleport(t_Bunkers[bunker_index].coords, true)
    end
end

local function drawAcidLab()
    b_AcidLabOwned = stats.get_int("MPX_XM22_LAB_OWNED") ~= 0

    if not b_AcidLabOwned then
        ImGui.Text("You don't own an acid lab.")
        return
    end

    ImGui.SeparatorText("Acid Lab")
    local acidUpdgrade = (stats.get_int("MPX_AWD_CALLME") >= 10) and
    (stats.get_int("MPX_XM22_LAB_EQUIP_UPGRADED") == 1)

    local acidUpgradeLabelCol = "white"

    if acidUpdgrade then
        acidUpgradeLabelCol = "green"
        acidOffset = globals.get_int(FreemodeGlobal1 + 17330)
    else
        acidUpgradeLabelCol = "red"
        acidOffset = 0
    end

    local acidSupplies = stats.get_int("MPX_MATTOTALFORFACTORY6")
    local acidStock = stats.get_int("MPX_PRODTOTALFORFACTORY6")
    i_AcidLabTotalValue = globals.get_int(FreemodeGlobal1 + 17324) + acidOffset * acidStock

    ImGui.BulletText("Equipment Upgrade: ")
    ImGui.SameLine()
    UI.ColoredText(acidUpdgrade and "Active" or "Inactive", acidUpgradeLabelCol, 0.9, 35)
    ImGui.BulletText("Supplies:")
    ImGui.SameLine()
    ImGui.Dummy(10, 1)
    ImGui.SameLine()
    ImGui.ProgressBar((acidSupplies / 100), 240, 30)

    ImGui.SameLine()
    ImGui.BeginDisabled(acidSupplies >= 100)
        if ImGui.Button(" Fill Supplies ##acid") then
            globals.set_int(FreemodeGlobal2 + 6 + 1, 1)
        end
    ImGui.EndDisabled()

    ImGui.BulletText("Stock:")
    ImGui.SameLine()
    ImGui.Dummy(33, 1)
    ImGui.SameLine()
    ImGui.ProgressBar(
        (acidStock / 160),
        240,
        30,
        string.format(
            "%d Sheets (%d%%)",
            acidStock,
            math.floor(acidStock / 16 * 10)
        )
    )

    ImGui.SameLine()
    ImGui.Text(("Value: %s"):format(Lua_fn.FormatMoney(i_AcidLabTotalValue)))

    ImGui.Spacing()
    ImGui.SeparatorText("Quick Teleport")

    if ImGui.Button("Teleport To The Freakshop") then
        YRV3:Teleport(848)
    end
end

local function drawBikerBusiness()
    YRV3.i_BikerValueSum = 0

    for i, data in ipairs(YRV3.OwnedBikerBusinessData) do
        local slot = i - 1
        local business = YRV3.OwnedBikerBusinessData[i]
        data.isOwned = stats.get_int(("MPX_PROP_FAC_SLOT%d"):format(slot)) ~= 0

        if data.isOwned then
            if not business.wasChecked then
                YRV3:PopulateBikerBusinessSlot(i)
            elseif business.name and business.val_offset then
                ImGui.PushID(string.format("bb##", i))
                ImGui.Dummy(1, 5)
                ImGui.SeparatorText(business.name)

                data.i_TotalSupplies = stats.get_int(("MPX_MATTOTALFORFACTORY%d"):format(slot))
                data.i_TotalStock = stats.get_int(("MPX_PRODTOTALFORFACTORY%d"):format(slot))
                data.i_TotalValue = globals.get_int(FreemodeGlobal1 + business.val_offset) * data.i_TotalStock
                YRV3.i_BikerValueSum = YRV3.i_BikerValueSum + data.i_TotalValue

                ImGui.BulletText("Supplies:")
                ImGui.SameLine()
                ImGui.Dummy(10, 1)
                ImGui.SameLine()
                ImGui.ProgressBar(data.i_TotalSupplies / 100, 240, 30)

                ImGui.SameLine()
                ImGui.BeginDisabled(data.i_TotalSupplies >= 100)
                    if ImGui.Button((" Fill Supplies ##%d"):format(i)) then
                        globals.set_int(FreemodeGlobal2 + slot + 1, 1)
                    end
                ImGui.EndDisabled()

                ImGui.SameLine()
                if ImGui.Button(("Teleport##%d"):format(i)) then
                    if not business.blip then
                        UI.WidgetSound("Error")
                        return
                    end

                    YRV3:Teleport(business.blip)
                end
                UI.HelpMarker(_T("QUICK_TP_WARN_"), "#FFA134")

                ImGui.BulletText("Stock:")
                ImGui.SameLine()
                ImGui.Dummy(33, 1)
                ImGui.SameLine()

                ImGui.ProgressBar(
                    (data.i_TotalStock / business.unit_max),
                    240,
                    30,
                    string.format(
                        "%d%%",
                        math.floor(data.i_TotalStock * (100 / business.unit_max))
                    )
                )

                ImGui.SameLine()
                ImGui.Text("Value:")
                ImGui.SameLine()

                ImGui.Text(
                    string.format(
                        "¤ Blaine County:  %s\n¤ Los Santos:      %s",
                        Lua_fn.FormatMoney(data.i_TotalValue),
                        Lua_fn.FormatMoney(math.floor(data.i_TotalValue * 1.5))
                    )
                )
                ImGui.PopID()
            end
        else
            ImGui.Text("You don't own this business.")
        end
    end

    if YRV3:DoesPlayerOwnAnyBikerBusiness() then
        ImGui.Separator()
        ImGui.Spacing()
        ImGui.BulletText(
            string.format(
                "Approximate Total MC Business Value: %s",
                Lua_fn.FormatMoney(YRV3.i_BikerValueSum)
            )
        )
        UI.Tooltip("Prices may be higher depending on your business upgrades.")
    end
end

local function drawBusinessSafes()
    YRV3.i_SafeCashValueSum = 0

    for name, data in pairs(YRV3.OwnedBusinessSafeData) do
        ImGui.PushID(name)

        if data.isOwned() then
            local cashValue = data.cashValue()
            YRV3.i_SafeCashValueSum = YRV3.i_SafeCashValueSum + cashValue

            ImGui.Spacing()
            ImGui.SeparatorText(name)

            if data.popularity then
                local popValue = data.popularity()
                ImGui.BulletText("Popularity: ")
                ImGui.SameLine()
                ImGui.Dummy(18, 1)
                ImGui.SameLine()
                ImGui.ProgressBar(
                    popValue / 1000,
                    240,
                    30,
                    string.format(
                        "%d%%",
                        math.floor(popValue / 10))
                    )

                if popValue < 1000 then
                    ImGui.SameLine()

                    if ImGui.Button(("Max Popularity##"):format(name)) then
                        UI.WidgetSound("Select")
                        data.maxPop()
                        YimToast:ShowSuccess(
                            "Samurai's Scripts",
                            "Nightclub popularity increased."
                        )
                    end
                end
            end

            ImGui.BulletText("Safe: ")
            ImGui.SameLine()
            ImGui.Dummy(60, 1)
            ImGui.SameLine()

            ImGui.ProgressBar(
                cashValue / data.max_cash,
                240,
                30,
                Lua_fn.FormatMoney(cashValue)
            )

            ImGui.SameLine()
            if ImGui.Button(("Teleport##"):format(name)) then
                YRV3:Teleport(data.blip)
            end
        else
            ImGui.Text(string.format("You don't own a %s.", name:lower()))
        end
        ImGui.PopID()
    end

    ImGui.Separator()
    ImGui.Spacing()
    ImGui.BulletText(
        string.format(
            "Total Cash In All Safes: %s",
            Lua_fn.FormatMoney(YRV3.i_SafeCashValueSum)
        )
    )
end


function YRV3UI()
    if not Game.IsOnline() then
        ImGui.Dummy(1, 5)
        ImGui.Text(_T("GENERIC_UNAVAILABLE_SP_"))
        return
    end

    if not SS.IsUpToDate() then
        ImGui.Dummy(1, 5)
        ImGui.Text("YRV3 is outdated!")
        return
    end

    ImGui.Spacing()
    ImGui.SetNextWindowBgAlpha(0)
    if ImGui.BeginChild("main", 700, 800) then
        if ImGui.BeginTabBar("##BusinessManager") then

            if ImGui.BeginTabItem(_T("CEO_WHOUSES_TXT_")) then
                drawCEOwarehouses()
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem(_T("HANGAR_TXT_")) then
                ImGui.Dummy(1, 5)
                drawHangar()
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Bunker") then
                ImGui.Dummy(1, 5)
                drawBunker()
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Acid Lab") then
                ImGui.Dummy(1, 5)
                drawAcidLab()
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Biker Business") then
                drawBikerBusiness()
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Safes") then
                ImGui.Dummy(1, 5)
                drawBusinessSafes()
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("MISC") then
                ImGui.Dummy(1, 5)
                ImGui.SeparatorText("Cooldowns")

                mc_work_cd, mcworkUsed = ImGui.Checkbox("MC Club Work", mc_work_cd)
                if mcworkUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("mc_work_cd", mc_work_cd)
                end

                ImGui.SameLine()
                ImGui.Dummy(58, 1)
                ImGui.SameLine()

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
                UI.HelpMarker("Always spawns the troublemaker nightclub missions and disables the knocked out VIP missions.")

                if nvipmcUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("nc_vip_mission_chance", nc_vip_mission_chance)
                end

                ie_vehicle_steal_cd, ievstealUsed = ImGui.Checkbox("I/E Vehicle Sourcing", ie_vehicle_steal_cd)
                if ievstealUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("ie_vehicle_steal_cd", ie_vehicle_steal_cd)
                end

                ImGui.SameLine()
                ImGui.Dummy(12, 1)
                ImGui.SameLine()

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

                ImGui.SameLine()
                ImGui.Dummy(55, 1)
                ImGui.SameLine()

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

                ImGui.SameLine()
                ImGui.Dummy(29, 1)
                ImGui.SameLine()

                ImGui.BeginDisabled()
                    payphone_hits_cd, _ = ImGui.Checkbox("Payphone Hits [x]", payphone_hits_cd)
                    if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and SS.IsKeyJustPressed("TAB") then
                        UI.SetClipBoardText("https://github.com/YimMenu-Lua/PayphoneHits", true)
                    end
                ImGui.EndDisabled()
                UI.Tooltip("Use ShinyWasabi's Payphone Hits script instead. Press [TAB] to copy the GitHub link.")

                dax_work_cd, dwcdUsed = ImGui.Checkbox("Dax Work Cooldown", dax_work_cd)
                if dwcdUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("dax_work_cd", dax_work_cd)
                end

                ImGui.SameLine()
                ImGui.Dummy(10, 1)
                ImGui.SameLine()

                garment_rob_cd, grcdUsed = ImGui.Checkbox("Garment Factory Files", garment_rob_cd)
                if grcdUsed then
                    UI.WidgetSound("Nav2")
                    CFG:SaveItem("garment_rob_cd", garment_rob_cd)
                end

                ImGui.Dummy(1, 5)
                if GetAllCDCheckboxes() then
                    sCooldownButtonLabel, bCooldownParam = "Uncheck All", false
                else
                    sCooldownButtonLabel, bCooldownParam = "Check All", true
                end

                if ImGui.Button(sCooldownButtonLabel or "", 120, 40) then
                    UI.WidgetSound("Select")
                    mc_work_cd = bCooldownParam; CFG:SaveItem("mc_work_cd", mc_work_cd)
                    hangar_cd = bCooldownParam; CFG:SaveItem("hangar_cd", hangar_cd)
                    nc_management_cd = bCooldownParam; CFG:SaveItem("nc_management_cd", nc_management_cd)
                    nc_vip_mission_chance = bCooldownParam; CFG:SaveItem("nc_vip_mission_chance", nc_vip_mission_chance)
                    security_missions_cd = bCooldownParam; CFG:SaveItem("security_missions_cd", security_missions_cd)
                    ie_vehicle_steal_cd = bCooldownParam; CFG:SaveItem("ie_vehicle_steal_cd", ie_vehicle_steal_cd)
                    ie_vehicle_sell_cd = bCooldownParam; CFG:SaveItem("ie_vehicle_sell_cd", ie_vehicle_sell_cd)
                    ceo_crate_buy_cd = bCooldownParam; CFG:SaveItem("ceo_crate_buy_cd", ceo_crate_buy_cd)
                    ceo_crate_sell_cd = bCooldownParam; CFG:SaveItem("ceo_crate_sell_cd", ceo_crate_sell_cd)
                    dax_work_cd = bCooldownParam; CFG:SaveItem("dax_work_cd", dax_work_cd)
                    garment_rob_cd = bCooldownParam; CFG:SaveItem("garment_rob_cd", dax_work_cd)
                end

                ImGui.Spacing()
                ImGui.SeparatorText("Sell Missions")

                ImGui.Spacing()
                UI.WrappedText(
                    "These options will not be saved. Each button disables the most tedious sell missions for that business.",
                    32
                )

                ImGui.Spacing()
                UI.ColoredText(
                    "[NOTE]: If you plan on selling more than once for the same business, please switch sessions after finishing the first sale to reset the missions, otherwise a sesond mission will more than likely fail to start.",
                    'yellow',
                    0.69,
                    30
                )

                for name, data in pairs(t_AnnoyingSellMissions) do
                    local globals_get  = (data.type == "float") and globals.get_float or globals.get_int
                    local globals_set  = (data.type == "float") and globals.set_float or globals.set_int
                    local desiredValue = data.type == "float" and 0.0 or 1

                    if ImGui.Button(("Easy %s Sell Missions"):format(name)) then
                        UI.WidgetSound("Select")
                        for _, index in pairs(data.idx) do
                            if globals_get(index) ~= desiredValue then
                                globals_set(index, desiredValue)
                            end
                        end
                        YimToast:ShowSuccess(
                            "Samurai's Scripts",
                            string.format(
                                "Successfully disabled the most annoying %s sell missions.",
                                name:lower()
                            )
                        )
                    end
                end
                ImGui.EndTabItem()
            end

            if ImGui.BeginTabItem("Sales") then
                ImGui.TextWrapped(
                    "This is bad, unreliable code with little to no effort put into it.\n\nOnly these businesses are supported:"
                )
                ImGui.BulletText("Bunker")
                ImGui.BulletText("Hangar (Air only)")
                ImGui.BulletText("CEO Warehouses")
                ImGui.BulletText("MC Businesses")
                ImGui.BulletText("Acid Lab")

                ImGui.Dummy(1, 10)
                ImGui.SeparatorText(string.format("Currently Selling: %s", YRV3.s_SellScriptDisplayName))

                ImGui.BeginDisabled(YRV3.b_HasTriggeredAutosell)
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
                    UI.ColoredText("Land sales are currently not supported.", "red", 0.8, 25)
                else
                    ImGui.BeginDisabled(autosell or YRV3.b_HasTriggeredAutosell or not YRV3.b_SellScriptIsRunning)
                        if ImGui.Button("Manually Finish Sale") then
                            UI.WidgetSound("Select")
                            YRV3.b_HasTriggeredAutosell = true
                            YRV3:FinishSale()

                            script.run_in_fiber(function(s)
                                repeat
                                    s:sleep(100)
                                until not YRV3.b_SellScriptIsRunning
                                YRV3.b_HasTriggeredAutosell = false
                            end)
                        end
                    ImGui.EndDisabled()
                end
                ImGui.EndTabItem()
            end
            ImGui.EndTabBar()
        end
        ImGui.EndChild()
    end

    if ImGui.BeginChild("yrv3_footer", 0, 80) then
        ImGui.Separator()
        ImGui.Spacing()
        ImGui.Dummy(1, 1)
        ImGui.SameLine()

        if ImGui.Button("Master Control Terminal") then
            YRV3:MCT()
        end

        ImGui.SetWindowFontScale(0.85)
            ImGui.BulletText("Approximate Income From All Businesses: ")
            UI.Tooltip("Cycle through all tabs to update the total amount.")

            ImGui.SameLine()

            UI.ColoredText(Lua_fn.FormatMoney(CalcTotalBusinessIncome()), "#85BB65")
            UI.Tooltip("Cycle through all tabs to update the total amount.")
        ImGui.SetWindowFontScale(1)
        ImGui.EndChild()
    end
end
