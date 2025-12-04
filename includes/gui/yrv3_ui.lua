local sCooldownButtonLabel, bCooldownParam
local i_HangarSupplies    = 0
local i_HangarTotalValue  = 0
local i_BunkerTotalValue  = 0
local i_AcidLabTotalValue = 0
local b_AcidLabOwned      = false
local b_OwnsWarehouse     = false
local b_OwnsBikerBusiness = false

local TuneablesGlobal = ScriptGlobal(GetScriptGlobalOrLocal("tuneables_global"))
local FreemodeGlobal = ScriptGlobal(GetScriptGlobalOrLocal("freemode_business_global"))

local function CalcTotalBusinessIncome()
    return math.sum(
        YRV3.m_biker_value_sum,
        YRV3.m_ceo_value_sum,
        YRV3.m_safe_cash_sum,
        i_HangarTotalValue,
        i_BunkerTotalValue,
        i_AcidLabTotalValue
    )
end

local function GetAllCDCheckboxes()
    return GVars.mc_work_cd
    and GVars.hangar_cd
    and GVars.nc_management_cd
    and GVars.nc_vip_mission_chance
    and GVars.security_missions_cd
    and GVars.ie_vehicle_steal_cd
    and GVars.ie_vehicle_sell_cd
    and GVars.ceo_crate_buy_cd
    and GVars.ceo_crate_sell_cd
    and GVars.dax_work_cd
    and GVars.garment_rob_cd
end

---@param value boolean
local function SetAllCDCheckboxes(value)
    GVars.mc_work_cd = value
    GVars.hangar_cd = value
    GVars.nc_management_cd = value
    GVars.nc_vip_mission_chance = value
    GVars.security_missions_cd = value
    GVars.ie_vehicle_steal_cd = value
    GVars.ie_vehicle_sell_cd = value
    GVars.ceo_crate_buy_cd = value
    GVars.ceo_crate_sell_cd = value
    GVars.dax_work_cd = value
    GVars.garment_rob_cd = value
end

local function drawCEOwarehouses()
    if (not YRV3:DoesPlayerOwnAnyWarehouse()) then
        ImGui.Text("You don't own any CEO warehouses.")
        return
    end

    YRV3.m_ceo_value_sum = 0
    ImGui.SetWindowFontScale(0.9)
        for i, data in ipairs(YRV3.m_warehouse_data) do
            local slot = i - 1
            data.isOwned = stats.get_int(("MPX_PROP_WHOUSE_SLOT%d"):format(slot)) > 0

            if data.isOwned then
                b_OwnsWarehouse = true

                if (not YRV3.m_warehouse_data[i].wasChecked) then
                    YRV3:PopulateCEOwarehouseSlot(i)
                else
                    ImGui.Dummy(1, 5)
                    local warehouse = YRV3.m_warehouse_data[i]

                    data.i_TotalSupplies = stats.get_int(("MPX_CONTOTALFORWHOUSE%d"):format(slot))
                    data.i_TotalValue = YRV3:GetCEOCratesValue(data.i_TotalSupplies or 0)
                    YRV3.m_ceo_value_sum = YRV3.m_ceo_value_sum + data.i_TotalValue

                    if (warehouse.name and warehouse.size and warehouse.max) then
                        ImGui.PushID(_F("warehouse##%d", i))
                        ImGui.SeparatorText(tostring(warehouse.name))
                        ImGui.BulletText("Cargo Held:")
                        ImGui.SameLine()
                        ImGui.Dummy(20, 1)
                        ImGui.SameLine()

                        ImGui.ProgressBar(
                            (data.i_TotalSupplies / warehouse.max),
                            240,
                            30,
                            _F(
                                "%d Crates (%d%%)",
                                data.i_TotalSupplies,
                                (math.floor(data.i_TotalSupplies / warehouse.max) * 100)
                            )
                        )

                        ImGui.SameLine()
                        ImGui.Text(string.formatmoney(data.i_TotalValue))

                        if (warehouse.pos) then
                            if GUI:Button(_F("Teleport##%d", i)) then
                                YRV3:Teleport(warehouse.pos)
                            end
                        end

                        ImGui.SameLine()
                        ImGui.BeginDisabled(data.i_TotalSupplies >= warehouse.max)
                            ImGui.BeginDisabled(warehouse.autoFill)
                                if GUI:Button(_F("%s##wh%d", _T("GET_RANDOM_CRATES"), i)) then
                                    stats.set_bool_masked(
                                        "MPX_FIXERPSTAT_BOOL1",
                                        true,
                                        i + 11
                                    )
                                end
                            ImGui.EndDisabled()
                            ImGui.SameLine()
                            YRV3.m_warehouse_data[i].autoFill, _ = GUI:Checkbox(_F("Auto##wh%d", i), YRV3.m_warehouse_data[i].autoFill)
                        ImGui.EndDisabled()
                        ImGui.PopID()
                    end
                end
            end
        end

        if (b_OwnsWarehouse) then
            ImGui.Dummy(1, 5)
            ImGui.SeparatorText("MISC")
            ImGui.Spacing()
            local bCond = (not script.is_active("gb_contraband_buy") and not script.is_active("fm_content_cargo"))
            ImGui.BeginDisabled(bCond)
            if (GUI:Button("Finish Cargo Source Mission")) then
                YRV3:FinishCEOCargoSourceMission()
            end
            ImGui.EndDisabled()

            if (bCond) then
                GUI:Tooltip("Start a source mission then press this button to finish it.")
            end

            ImGui.BulletText("Total Value: " .. string.formatmoney(YRV3.m_ceo_value_sum))
        end
    ImGui.SetWindowFontScale(1)
end

local function drawHangar()
    local hangar_index = stats.get_int("MPX_HANGAR_OWNED")
    local hangarOwned = hangar_index ~= 0

    if (not hangarOwned) then
        ImGui.Text("You don't own a hangar.")
        return
    end

    local hangar_name = YRV3.t_Hangars[hangar_index].name
    local hangar_pos = YRV3.t_Hangars[hangar_index].coords

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

    if (i_HangarSupplies < 50) then
        ImGui.SameLine()

        ImGui.BeginDisabled(YRV3.m_hangar_loop)
        if GUI:Button(_F("%s##hangar", _T("GET_RANDOM_CRATES"))) then
            script.run_in_fiber(function()
                stats.set_bool_masked("MPX_DLC22022PSTAT_BOOL3", true, 9)
            end)
        end
        ImGui.EndDisabled()

        ImGui.SameLine()
        YRV3.m_hangar_loop, _ = GUI:Checkbox("Auto##hangar", YRV3.m_hangar_loop)
    end

    ImGui.BulletText("Stock:")
    ImGui.SameLine()
    ImGui.Dummy(33, 1)
    ImGui.SameLine()
    ImGui.ProgressBar(
        (i_HangarSupplies / 50),
        240,
        30,
        _F("%d Crates (%d%%)", i_HangarSupplies, math.floor(i_HangarSupplies / 0.5))
    )

    ImGui.SameLine()
    ImGui.Text(_F("Value: %s", string.formatmoney(i_HangarTotalValue)))
    ImGui.Spacing()
    ImGui.SeparatorText(_T"QUICK_TP_TXT")
    if GUI:Button(_T"TP_HANGAR") then
        YRV3:Teleport(hangar_pos, true)
    end
end

local function drawBunker()
    local bunker_index = stats.get_int("MPX_PROP_FAC_SLOT5")
    local bunkerOwned = bunker_index ~= 0

    if (not bunkerOwned) then
        ImGui.Text("You don't own a bunker.")
        return
    end

    ImGui.SeparatorText(YRV3.t_Bunkers[bunker_index].name)

    local bunkerUpdgrade1  = stats.get_int("MPX_BUNKER_EQUIPMENT") == 1
    local bunkerUpdgrade2  = stats.get_int("MPX_BUNKER_STAFF") == 1
    local bunkerOffset1    = 0
    local bunkerOffset2    = 0
    local bunkerEqLabelCol = "white"
    local bunkerStLabelCol = "white"

    if (bunkerUpdgrade1) then
        bunkerOffset1 = TuneablesGlobal:At(21256):ReadInt()
        bunkerEqLabelCol = "green"
    else
        bunkerOffset1 = 0
        bunkerEqLabelCol = "red"
    end

    if (bunkerUpdgrade2) then
        bunkerOffset2 = TuneablesGlobal:At(21255):ReadInt()
        bunkerStLabelCol = "green"
    else
        bunkerOffset2 = 0
        bunkerStLabelCol = "red"
    end

    local bunkerSupplies = stats.get_int("MPX_MATTOTALFORFACTORY5")
    local bunkerStock = stats.get_int("MPX_PRODTOTALFORFACTORY5")
    i_BunkerTotalValue = (TuneablesGlobal:At(21254):ReadInt() + bunkerOffset1 + bunkerOffset2) * bunkerStock

    ImGui.BulletText("Equipment Upgrade: ")
    ImGui.SameLine()
    GUI:TextColored(bunkerUpdgrade1 and "Active" or "Inactive", Color(bunkerEqLabelCol))

    ImGui.SameLine()
    ImGui.BulletText("Staff Upgrade: ")
    ImGui.SameLine()
    GUI:TextColored(bunkerUpdgrade2 and "Active" or "Inactive", Color(bunkerStLabelCol))

    ImGui.Spacing()
    ImGui.BulletText("Supplies:")
    ImGui.SameLine()
    ImGui.Dummy(10, 1)
    ImGui.SameLine()
    ImGui.ProgressBar((bunkerSupplies / 100), 240, 30)

    ImGui.SameLine()
    ImGui.BeginDisabled(bunkerSupplies >= 100)
    if (GUI:Button(" Fill Supplies ##bunker")) then
        FreemodeGlobal:At(5):At(1):WriteInt(1)
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
        _F("%d Crates (%d%%)", bunkerStock, bunkerStock)
    )

    ImGui.SameLine()
    ImGui.Text("Value:")
    ImGui.SameLine()
    ImGui.Text(
        _F(
            "¤ Blaine County: %s\n¤ Los Santos:      %s",
            string.formatmoney(i_BunkerTotalValue),
            string.formatmoney(math.floor(i_BunkerTotalValue * 1.5))
        )
    )

    ImGui.Spacing()
    ImGui.SeparatorText(_T"QUICK_TP_TXT")

    if (GUI:Button(_T"TP_BUNKER")) then
        YRV3:Teleport(YRV3.t_Bunkers[bunker_index].coords, true)
    end
end

local function drawAcidLab()
    b_AcidLabOwned = stats.get_int("MPX_XM22_LAB_OWNED") ~= 0
    if (not b_AcidLabOwned) then
        ImGui.Text("You don't own an acid lab.")
        return
    end

    ImGui.SeparatorText("Acid Lab")
    local acidUpdgrade = (stats.get_int("MPX_AWD_CALLME") >= 10) and
    (stats.get_int("MPX_XM22_LAB_EQUIP_UPGRADED") == 1)

    local acidUpgradeLabelCol = "white"
    local acidOffset = 0

    if (acidUpdgrade) then
        acidUpgradeLabelCol = "green"
        acidOffset = TuneablesGlobal:At(17330):ReadInt()
    else
        acidUpgradeLabelCol = "red"
        acidOffset = 0
    end

    local acidSupplies = stats.get_int("MPX_MATTOTALFORFACTORY6")
    local acidStock = stats.get_int("MPX_PRODTOTALFORFACTORY6")
    i_AcidLabTotalValue = TuneablesGlobal:At(17324):ReadInt() + acidOffset * acidStock

    ImGui.BulletText("Equipment Upgrade: ")
    ImGui.SameLine()
    GUI:TextColored(acidUpdgrade and "Active" or "Inactive", Color(acidUpgradeLabelCol))
    ImGui.BulletText("Supplies:")
    ImGui.SameLine()
    ImGui.Dummy(10, 1)
    ImGui.SameLine()
    ImGui.ProgressBar((acidSupplies / 100), 240, 30)

    ImGui.SameLine()
    ImGui.BeginDisabled(acidSupplies >= 100)
    if (GUI:Button(_F(" %s ##acid", _T"SUPPLIES_FILL"))) then
        FreemodeGlobal:At(6):At(1):WriteInt(1)
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
        _F(
            "%d Sheets (%d%%)",
            acidStock,
            math.floor(acidStock / 16 * 10)
        )
    )

    ImGui.SameLine()
    ImGui.Text(("Value: %s"):format(string.formatmoney(i_AcidLabTotalValue)))

    ImGui.Spacing()
    ImGui.SeparatorText(_T"QUICK_TP_TXT")

    if (GUI:Button("Teleport To The Freakshop")) then
        YRV3:Teleport(848)
    end
end

local function drawBikerBusiness()
    if (not YRV3:DoesPlayerOwnAnyBikerBusiness()) then
        ImGui.Text("You don't own any biker businesses.")
        return
    end

    YRV3.m_biker_value_sum = 0

    for i, data in ipairs(YRV3.m_biker_data) do
        local slot = i - 1
        local business = YRV3.m_biker_data[i]
        data.isOwned = stats.get_int(("MPX_PROP_FAC_SLOT%d"):format(slot)) ~= 0

        if (data.isOwned) then
            b_OwnsBikerBusiness = true

            if (not business.wasChecked) then
                YRV3:PopulateBikerBusinessSlot(i)
            elseif (business.name and business.val_offset) then
                ImGui.PushID(_F("bb##", i))
                ImGui.Dummy(1, 5)
                ImGui.SeparatorText(business.name)

                data.i_TotalSupplies = stats.get_int(_F("MPX_MATTOTALFORFACTORY%d", slot))
                data.i_TotalStock = stats.get_int(_F("MPX_PRODTOTALFORFACTORY%d", slot))
                data.i_TotalValue = TuneablesGlobal:At(business.val_offset):ReadInt() * data.i_TotalStock
                YRV3.m_biker_value_sum = YRV3.m_biker_value_sum + data.i_TotalValue

                ImGui.BulletText("Supplies:")
                ImGui.SameLine()
                ImGui.Dummy(10, 1)
                ImGui.SameLine()
                ImGui.ProgressBar(data.i_TotalSupplies / 100, 240, 30)

                ImGui.SameLine()
                ImGui.BeginDisabled(data.i_TotalSupplies >= 100)
                    if (GUI:Button(_F(" %s ##%d", _T("SUPPLIES_FILL"), i))) then
                        FreemodeGlobal:At(slot):At(1):WriteInt(1)
                    end
                ImGui.EndDisabled()

                ImGui.SameLine()
                if (GUI:Button(_F("Teleport##%d", i))) then
                    if (not business.blip) then
                        return
                    end

                    YRV3:Teleport(business.blip)
                end

                ImGui.BulletText("Stock:")
                ImGui.SameLine()
                ImGui.Dummy(33, 1)
                ImGui.SameLine()

                ImGui.ProgressBar(
                    (data.i_TotalStock / business.unit_max),
                    240,
                    30,
                    _F("%d%%", math.floor(data.i_TotalStock * (100 / business.unit_max)))
                )

                ImGui.SameLine()
                ImGui.Text("Value:")
                ImGui.SameLine()

                ImGui.Text(
                    _F("¤ Blaine County:  %s\n¤ Los Santos:      %s",
                        string.formatmoney(data.i_TotalValue),
                        string.formatmoney(math.floor(data.i_TotalValue * 1.5))
                    )
                )
                ImGui.PopID()
            end
        else
            ImGui.Text("You don't own this business.")
        end
    end

    if (b_OwnsBikerBusiness) then
        ImGui.Separator()
        ImGui.Spacing()
        ImGui.BulletText(
            _F("Approximate Total MC Business Value: %s", string.formatmoney(YRV3.m_biker_value_sum))
        )
        GUI:Tooltip("Prices may be higher depending on your business upgrades.")
    end
end

local function drawBusinessSafes()
    YRV3.m_safe_cash_sum = 0

    for name, data in pairs(YRV3.m_safe_cash_data) do
        ImGui.PushID(name)

        if data.isOwned() then
            local cashValue = data.cashValue()
            YRV3.m_safe_cash_sum = YRV3.m_safe_cash_sum + cashValue

            ImGui.Spacing()
            ImGui.SeparatorText(name)

            if (IsInstance(data.popularity, "function")) then
                local popValue = data.popularity()
                ImGui.BulletText("Popularity: ")
                ImGui.SameLine()
                ImGui.Dummy(18, 1)
                ImGui.SameLine()
                ImGui.ProgressBar(popValue / 1e3, 240, 30, _F("%d%%", math.floor(popValue / 10)))

                if (popValue < 1e3) then
                    ImGui.SameLine()

                    if GUI:Button(("Max Popularity##"):format(name)) then
                        data.maxPop()
                        Toast:ShowSuccess("Samurai's Scripts", "Nightclub popularity increased.")
                    end
                end
            end

            ImGui.BulletText("Safe: ")
            ImGui.SameLine()
            ImGui.Dummy(60, 1)
            ImGui.SameLine()

            ImGui.ProgressBar(cashValue / data.max_cash, 240, 30, string.formatmoney(cashValue))
            ImGui.SameLine()
            if (GUI:Button(_F("Teleport##%s", name))) then
                YRV3:Teleport(data.blip)
            end
        end
        ImGui.PopID()
    end

    ImGui.Separator()
    ImGui.Spacing()
    ImGui.BulletText(_F("Total Cash In All Safes: %s", string.formatmoney(YRV3.m_safe_cash_sum)))
end

local function YRV3UI()
    if (not YRV3:CanAccess()) then
        ImGui.Dummy(1, 5)
        ImGui.Text(_T("GENERIC_UNAVAILABLE"))
        return
    end

    ImGui.Spacing()
    ImGui.SetNextWindowBgAlpha(0)
    if (ImGui.BeginChild("main", 700, 800)) then
        if (ImGui.BeginTabBar("##BusinessManager")) then
            if (ImGui.BeginTabItem("CEO")) then
                drawCEOwarehouses()
                ImGui.EndTabItem()
            end

            if (ImGui.BeginTabItem("Hangar")) then
                ImGui.Dummy(1, 5)
                drawHangar()
                ImGui.EndTabItem()
            end

            if (ImGui.BeginTabItem("Bunker")) then
                ImGui.Dummy(1, 5)
                drawBunker()
                ImGui.EndTabItem()
            end

            if (ImGui.BeginTabItem("Acid Lab")) then
                ImGui.Dummy(1, 5)
                drawAcidLab()
                ImGui.EndTabItem()
            end

            if (ImGui.BeginTabItem("Biker Business")) then
                drawBikerBusiness()
                ImGui.EndTabItem()
            end

            if (ImGui.BeginTabItem("Safes")) then
                ImGui.Dummy(1, 5)
                drawBusinessSafes()
                ImGui.EndTabItem()
            end

            if (ImGui.BeginTabItem("MISC")) then
                ImGui.Dummy(1, 5)
                ImGui.SeparatorText("Cooldowns")

                GVars.mc_work_cd, _ = GUI:Checkbox("MC Club Work", GVars.mc_work_cd)
                ImGui.SameLine()
                ImGui.Dummy(58, 1)
                ImGui.SameLine()

                GVars.hangar_cd, _ = GUI:Checkbox("Hangar Crate Steal", GVars.hangar_cd)

                GVars.nc_management_cd, _ = GUI:Checkbox("Nightclub Management", GVars.nc_management_cd)

                ImGui.SameLine()
                GVars.nc_vip_mission_chance, _ = GUI:Checkbox("Always Troublemaker", GVars.nc_vip_mission_chance)
                GUI:HelpMarker("Always spawns the troublemaker nightclub missions and disables the knocked out VIP missions.")

                GVars.ie_vehicle_steal_cd, _ = GUI:Checkbox("I/E Vehicle Sourcing", GVars.ie_vehicle_steal_cd)

                ImGui.SameLine()
                ImGui.Dummy(12, 1)
                ImGui.SameLine()

                GVars.ie_vehicle_sell_cd, _ = GUI:Checkbox("I/E Vehicle Selling", GVars.ie_vehicle_sell_cd)

                GVars.ceo_crate_buy_cd, _ = GUI:Checkbox("CEO Crate Buy", GVars.ceo_crate_buy_cd)

                ImGui.SameLine()
                ImGui.Dummy(55, 1)
                ImGui.SameLine()

                GVars.ceo_crate_sell_cd, _ = GUI:Checkbox("CEO Crate Sell", GVars.ceo_crate_sell_cd)

                GVars.security_missions_cd, _ = GUI:Checkbox("Security Missions", GVars.security_missions_cd)

                ImGui.SameLine()
                ImGui.Dummy(29, 1)
                ImGui.SameLine()

                ImGui.BeginDisabled()
                    ImGui.Checkbox("Payphone Hits [x]", false)
                    if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and KeyManager:IsKeyJustPressed("TAB") then
                        ImGui.SetClipboardText("https://github.com/YimMenu-Lua/PayphoneHits")
                    end
                ImGui.EndDisabled()
                GUI:Tooltip("Use ShinyWasabi's Payphone Hits script instead. Press [TAB] to copy the GitHub link.")

                GVars.dax_work_cd, _ = GUI:Checkbox("Dax Work Cooldown", GVars.dax_work_cd)

                ImGui.SameLine()
                ImGui.Dummy(10, 1)
                ImGui.SameLine()

                GVars.garment_rob_cd, _ = GUI:Checkbox("Garment Factory Files", GVars.garment_rob_cd)

                ImGui.Dummy(1, 5)
                if (GetAllCDCheckboxes()) then
                    sCooldownButtonLabel, bCooldownParam = "Uncheck All", false
                else
                    sCooldownButtonLabel, bCooldownParam = "Check All", true
                end

                if (GUI:Button(sCooldownButtonLabel or "", {size = vec2:new(120, 40)})) then
                    SetAllCDCheckboxes(bCooldownParam)
                end

                ImGui.Spacing()
                ImGui.SeparatorText("Sell Missions")

                ImGui.Spacing()
                ImGui.TextWrapped("These options will not be saved. Each button disables the most tedious sell missions for that business.")

                ImGui.Spacing()
                GUI:TextColored(
                    "[NOTE]: If you plan on selling more than once for the same business, please switch sessions after finishing the first sale to reset the missions, otherwise a sesond mission will more than likely fail to start.",
                    Color("yellow")
                )

                for name, data in pairs(YRV3.t_ShittyMissions) do
                    local globals_get  = (data.type == "float") and globals.get_float or globals.get_int
                    local globals_set  = (data.type == "float") and globals.set_float or globals.set_int
                    local desiredValue = data.type == "float" and 0.0 or 1

                    if GUI:Button(("Easy %s Sell Missions"):format(name)) then
                        for _, index in pairs(data.idx) do
                            if globals_get(index) ~= desiredValue then
                                globals_set(index, desiredValue)
                            end
                        end

                        Toast:ShowSuccess("Samurai's Scripts",_F("Disabled the most annoying %s sell missions.", name:lower())
                        )
                    end
                end
                ImGui.EndTabItem()
            end

            if (ImGui.BeginTabItem("Sales")) then
                ImGui.TextWrapped("This is bad, unreliable code with little to no effort put into it.\n\nOnly these businesses are supported:")
                ImGui.BulletText("Bunker")
                ImGui.BulletText("Hangar (Air only)")
                ImGui.BulletText("CEO Warehouses")
                ImGui.BulletText("MC Businesses")
                ImGui.BulletText("Acid Lab")

                ImGui.Dummy(1, 10)
                ImGui.SeparatorText(_F("Currently Selling: %s", YRV3.m_sell_script_disp_name))
                ImGui.BeginDisabled(YRV3.m_has_triggered_autosell)
                GVars.autosell, _ = GUI:Checkbox("Auto-Sell", GVars.autosell)
                ImGui.EndDisabled()
                GUI:Tooltip(
                    "Automatically finishes a sale mission 20 seconds after it starts. Doesn't require you to interact with anything other than starting the mission."
                )

                if script.is_active("fm_content_smuggler_sell") then
                    GUI:TextColored("Land sales are currently not supported.", Color("red"))
                else
                    ImGui.BeginDisabled(GVars.autosell or YRV3.m_has_triggered_autosell or not YRV3.m_sell_script_running)
                    if (GUI:Button("Manually Finish Sale")) then
                        YRV3.m_has_triggered_autosell = true
                        YRV3:FinishSale()
                        script.run_in_fiber(function()
                            repeat
                                yield()
                            until not YRV3.m_sell_script_running
                            YRV3.m_has_triggered_autosell = false
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

        if (GUI:Button("Master Control Terminal")) then
            YRV3:MCT()
        end

        ImGui.SetWindowFontScale(0.85)
            ImGui.BulletText("Approximate Income From All Businesses: ")
            GUI:Tooltip("Cycle through all tabs to update the total amount.")

            ImGui.SameLine()

            GUI:TextColored(string.formatmoney(CalcTotalBusinessIncome()), Color("#85BB65"))
            GUI:Tooltip("Cycle through all tabs to update the total amount.")
        ImGui.SetWindowFontScale(1)
        ImGui.EndChild()
    end
end

GUI:GetMainTab():RegisterSubtab("YimResupplierV3", YRV3UI)
