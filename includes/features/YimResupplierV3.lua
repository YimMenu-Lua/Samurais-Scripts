local t_WarehouseInit = {
    [1] = {
        wasChecked = false,
        isOwned = false,
        autoFill = false
    },
    [2] = {
        wasChecked = false,
        isOwned = false,
        autoFill = false
    },
    [3] = {
        wasChecked = false,
        isOwned = false,
        autoFill = false
    },
    [4] = {
        wasChecked = false,
        isOwned = false,
        autoFill = false
    },
    [5] = {
        wasChecked = false,
        isOwned = false,
        autoFill = false
    },
}

local t_BikerBusinessInit = {
    [1] = {
        wasChecked = false,
        isOwned = false,
    },
    [2] = {
        wasChecked = false,
        isOwned = false,
    },
    [3] = {
        wasChecked = false,
        isOwned = false,
    },
    [4] = {
        wasChecked = false,
        isOwned = false,
    },
    [5] = {
        wasChecked = false,
        isOwned = false,
    },
}

local eShouldTerminateScripts <const> = {
    "appArcadeBusinessHub",
    "appsmuggler",
    "appbikerbusiness",
    "appbunkerbusiness",
    "appbusinesshub"
}


---@class YRV3
YRV3 = {}
YRV3.__index = YRV3

YRV3.i_TotalSum = 0
YRV3.i_CEOvalueSum = 0
YRV3.i_BikerValueSum = 0
YRV3.i_SafeCashValueSum = 0
YRV3.i_BhubScriptHandle = 0
YRV3.i_AutosellLastCheckTime = 0
YRV3.OwnedWarehouseData = t_WarehouseInit
YRV3.OwnedBikerBusinessData = t_BikerBusinessInit
YRV3.OwnedBusinessSafeData = YRV3.t_BusinessSafeData
YRV3.b_HangarLoop = false
YRV3.b_HasTriggeredAutosell = false
YRV3.b_SellScriptIsRunning = false
YRV3.s_SellScriptName = nil
YRV3.s_SellScriptDisplayName = "None"
YRV3.SellScriptsDisplayNames = {
    ["fm_content_smuggler_sell"] = "Hangar (Land. Not supported.)",
    ["gb_smuggler"]              = "Hangar (Air)",
    ["gb_contraband_sell"]       = "CEO",
    ["gb_gunrunning"]            = "Bunker",
    ["gb_biker_contraband_sell"] = "Biker Business",
    ["fm_content_acid_lab_sell"] = "Acid Lab",
}


---@param where integer|vec3
---@param keepVehicle? boolean
function YRV3:Teleport(where, keepVehicle)
    if not Self.IsOutside() then
        UI.WidgetSound("Error")
        YimToast:ShowError(
            "Samurai's Scripts",
            "Please go outdside first!"
        )
        return
    end

    UI.WidgetSound("Select")
    Self.Teleport(where, keepVehicle)
end

---@param stat string
---@return boolean
function YRV3:DoesPlayerOwnPropertySlot(stat)
    for i = 0, 4 do
        if stats.get_int(string.format("%s%d", stat, i)) ~= 0 then
            return true
        end
    end

    return false
end

---@return boolean
function YRV3:DoesPlayerOwnAnyWarehouse()
    return self:DoesPlayerOwnPropertySlot("MPX_PROP_WHOUSE_SLOT")
end

---@return boolean
function YRV3:DoesPlayerOwnAnyBikerBusiness()
    return self:DoesPlayerOwnPropertySlot("MPX_PROP_FAC_SLOT")
end

---@param index integer
function YRV3:PopulateBikerBusinessSlot(index)
    if self.OwnedBikerBusinessData[index].wasChecked then
        return
    end

    for _, v in ipairs(self.t_BikerBusinessIDs) do
        local propertyIndex = stats.get_int(("MPX_FACTORYSLOT%d"):format(index-1))

        if table.Find(v.possible_ids, propertyIndex) then
            self.OwnedBikerBusinessData[index] = {
                wasChecked = true,
                isOwned = true,
                name = v.name,
                id = v.id,
                unit_max = v.unit_max,
                val_offset = v.val_offset,
                blip = v.blip,
            }
        end
    end
end

function YRV3:PopulateCEOwarehouseSlot(index)
    if self.OwnedWarehouseData[index].wasChecked then
        return
    end

    script.run_in_fiber(function()
        local property_index = (stats.get_int(("MPX_PROP_WHOUSE_SLOT%d"):format(index-1))) - 1
        local warehouseName = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(("MP_WHOUSE_%d"):format(property_index))

        if self.t_CEOwarehouses[warehouseName] then
            self.OwnedWarehouseData[index] = {
                wasChecked = true,
                isOwned = true,
                autoFill = false,
                name = warehouseName,
                size = self.t_CEOwarehouses[warehouseName].size,
                max = self.t_CEOwarehouses[warehouseName].max,
                pos = self.t_CEOwarehouses[warehouseName].coords,
            }
        end
    end)
end

---@param crates number
function YRV3:GetCEOCratesValue(crates)
    if not crates or crates <= 0 then
        return 0
    end

    if crates == 1 then
        return globals.get_int(FreemodeGlobal1 + 15732) -- EXEC_CONTRABAND_SALE_VALUE_THRESHOLD1
    end

    if crates == 2 then
        return globals.get_int(FreemodeGlobal1 + 15733) * 2
    end

    if crates == 3 then
        return globals.get_int(FreemodeGlobal1 + 15734) * 3
    end

    if crates == 4 or crates == 5 then
        return globals.get_int(FreemodeGlobal1 + 15735) * crates
    end

    if crates >= 6 and crates <= 9 then
        return (globals.get_int(FreemodeGlobal1 + 15735) + math.floor((crates - 4) / 2)) * crates
    end

    if crates >= 10 and crates <= 110 then
        return (globals.get_int(FreemodeGlobal1 + 15738) + math.floor((crates - 10) / 5)) * crates
    end

    if crates == 111 then
        return globals.get_int(FreemodeGlobal1 + 15752) * 111
    end

    return 0
end

function YRV3:FinishCEOCargoSourceMission()
    if script.is_active("gb_contraband_buy") then
        script.execute_as_script("gb_contraband_buy", function()
            if not NETWORK.NETWORK_IS_HOST_OF_THIS_SCRIPT() then
                YimToast:ShowError("Samurai's Scripts", "You are not host of this script.")
                return
            end

            locals.set_int("gb_contraband_buy", 621 + 5, 1)   -- 1.70 b3442 -- case -1: return "INVALID - UNSET";
            locals.set_int("gb_contraband_buy", 621 + 191, 6) -- 1.70 b3442 -- func_40 Local_621.f_191 = iParam0;
            locals.set_int("gb_contraband_buy", 621 + 192, 4) -- 1.70 b3442 -- func_15 Local_621.f_192 = iParam0;
        end)
    elseif script.is_active("fm_content_cargo") then
        script.execute_as_script("fm_content_cargo", function()
            if not NETWORK.NETWORK_IS_HOST_OF_THIS_SCRIPT() then
                YimToast:ShowError("Samurai's Scripts", "You are not host of this script.")
                return
            end

            local val = locals.get_int("fm_content_cargo", 5883 + 1 + 0) -- GENERIC_BITSET_I_WON -- 1.70 b3442 -- var uLocal_5883 = 4;
            if not Lua_fn.has_bit(val, 11) then
                val = Lua_fn.set_bit(val, 11)
                locals.set_int("fm_content_cargo", 5883 + 1 + 0, val)
            end
            locals.set_int("fm_content_cargo", 5979 + 1157, 3) -- EndReason -- 1.70 b3442 -- func_8 Local_5979.f_1157 = iParam0;
        end)
    end
end

---@param s script_util
function YRV3:WarehouseAutofill(s)
    if not Game.IsOnline() or not SS.IsUpToDate() then
        return
    end

    for i, v in ipairs(self.OwnedWarehouseData) do
        if v.autoFill then
            if not v.wasChecked or not v.name or not v.max then
                self:PopulateCEOwarehouseSlot(i)
                s:sleep(500)
            end

            if (stats.get_int(("MPX_CONTOTALFORWHOUSE%d"):format(i-1))) == v.max then
                UI.WidgetSound("Error")
                YimToast:ShowWarning(
                    "Samurai's Scripts",
                    string.format(
                        "Warehouse N°%d is already full! Option has been disabled.",
                        i
                    ),
                    false,
                    1.5
                )

                v.autoFill = false
                return
            end

            while (stats.get_int(("MPX_CONTOTALFORWHOUSE%d"):format(i-1))) < v.max do
                if not v.autoFill then
                    break
                end

                stats.set_bool_masked("MPX_FIXERPSTAT_BOOL1", true, i+11)
                s:sleep(supply_autofill_delay or 100)
            end

            v.autoFill = false
        end
    end

    s:sleep(1000)
end

---@param s script_util
function YRV3:HangarAutofill(s)
    if not Game.IsOnline() or not SS.IsUpToDate() then
        return
    end

    if not self.b_HangarLoop then
        return
    end

    if (stats.get_int("MPX_HANGAR_OWNED") == 0) then
        YimToast:ShowWarning(
            "Samurai's Scripts",
            "You don't seem to own a hangar. Option has been disabled.",
            false,
            3
        )

        self.b_HangarLoop = false
        return
    end

    if stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL") == 50 then
        YimToast:ShowWarning(
            "Samurai's Scripts",
            "Your Hangar is already full! Option has been disabled.",
            false,
            3
        )

        self.b_HangarLoop = false
        return
    end

    while stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL") < 50 do
        if not self.b_HangarLoop then
            break
        end

        stats.set_bool_masked("MPX_DLC22022PSTAT_BOOL3", true, 9)
        s:sleep(supply_autofill_delay)
    end

    self.b_HangarLoop = false
end

function YRV3:FinishSaleOnCommand()
    if not Game.IsOnline() or not SS.IsUpToDate() then
        return
    end

    if autosell then
        YimToast:ShowWarning(
            "Samurai's Scripts",
            "You aleady have 'Auto-Sell' enabled. No need to manually trigger it.",
            false,
            1.5
        )
        return
    end

    if not YRV3.b_SellScriptIsRunning then
        YimToast:ShowWarning(
            "Samurai's Scripts",
            "No supported sale script is currently running.",
            false,
            1.5
        )
        return
    end

    self:FinishSale()
end

---@param index number
function YRV3:WarehouseAutofillOnCommand(index)
    if not Game.IsOnline() or not SS.IsUpToDate() then
        return
    end

    script.run_in_fiber(function(s)
        if not self.OwnedWarehouseData[index].wasChecked then
            self:PopulateCEOwarehouseSlot(index)
            s:sleep(250)
        end

        if not self.OwnedWarehouseData[index].isOwned then
            YimToast:ShowError(
            "Samurai's Scripts",
            string.format(
                "No warehouse found in slot %d!",
                index
            ),
            false
        )
            return
        end

        self.OwnedWarehouseData[index].autoFill = not self.OwnedWarehouseData[index].autoFill
        YimToast:ShowMessage(
            "Samurai's Scripts",
            string.format(
                "CEO Warehouse %d auto-fill %s.",
                index,
                self.OwnedWarehouseData[index].autoFill
                and "Enabled"
                or "Disabled"
            ),
            false,
            2
        )
    end)
end

function YRV3:FillAll()
    if not Game.IsOnline() or not SS.IsUpToDate() then
        return
    end

    script.run_in_fiber(function(s)
        if (stats.get_int("MPX_HANGAR_OWNED") ~= 0) then
            if not YRV3.b_HangarLoop then
                YRV3.b_HangarLoop = true
                s:sleep(math.random(100, 300))
            end
        end

        if (stats.get_int("MPX_PROP_FAC_SLOT5")) and (stats.get_int("MPX_MATTOTALFORFACTORY5") < 100) then
            globals.set_int(FreemodeGlobal2 + 5 + 1, 1)
            s:sleep(math.random(100, 300))
        end

        if (stats.get_int("MPX_XM22_LAB_OWNED") ~= 0) and (stats.get_int("MPX_MATTOTALFORFACTORY6") < 100) then
            globals.set_int(FreemodeGlobal2 + 6 + 1, 1)
            s:sleep(math.random(100, 300))
        end

        for i, v in ipairs(self.OwnedWarehouseData) do
            if not v.wasChecked or not v.max then
                self:PopulateCEOwarehouseSlot(i)
                s:sleep(100)
            end
        end

        for _, v in ipairs(self.OwnedWarehouseData) do
            if v.isOwned then
                v.autoFill = true
            end
        end

        for i, v in ipairs(self.OwnedBikerBusinessData) do
            if not v.wasChecked or not v.unit_max then
                self:PopulateBikerBusinessSlot(i)
                s:sleep(100)
            end
        end

        for i, v in ipairs(self.OwnedBikerBusinessData) do
            local slot = i - 1

            if v.isOwned and v.unit_max
            and (stats.get_int(("MPX_MATTOTALFORFACTORY%d"):format(slot)) < 100) then
                globals.set_int(FreemodeGlobal2 + slot + 1, 1)
                s:sleep(math.random(200, 666))
            end
        end
    end)
end

function YRV3:FinishSale()
    if not self.s_SellScriptName or type(self.s_SellScriptName) ~= "string" then
        return
    end

    if not self.t_SellScripts[self.s_SellScriptName] then
        return
    end

    local sn = self.s_SellScriptName
    self.b_HasTriggeredAutosell = true

    script.execute_as_script(sn, function()
        if not self.t_SellScripts[sn].b then -- gb_*
            for _, data in pairs(self.t_SellScripts[sn]) do
                locals.set_int(sn, data.l + data.o, data.v)
            end
        else -- fm_content_*
            if not (NETWORK.NETWORK_GET_HOST_OF_THIS_SCRIPT() == Self.GetPlayerID()) then
                YimToast:ShowWarning(
                    "Samurai's Scripts",
                    "Unable to finish sale mission because you are not host of this script."
                )
                return
            end

            local val = locals.get_int(sn, self.t_SellScripts[sn].b + 1 + 0)

            if not Lua_fn.has_bit(val, 11) then
                val = Lua_fn.set_bit(val, 11)
                locals.set_int(sn, self.t_SellScripts[sn].b + 1 + 0, val)
            end

            locals.set_int(sn, self.t_SellScripts[sn].l + self.t_SellScripts[sn].o, 3) -- End reason.
        end
    end)
end

function YRV3:GetRunningSellScriptDisplayName()
    if not self.b_SellScriptIsRunning or not self.s_SellScriptName then
        return "None"
    end

    return self.SellScriptsDisplayNames[self.s_SellScriptName] or "None"
end

function YRV3:BackgroundWorker()
    if Time.now() < self.i_AutosellLastCheckTime then
        return
    end

    for sn in pairs(self.t_SellScripts) do
        if script.is_active(sn) then
            self.s_SellScriptName = sn
            self.b_SellScriptIsRunning = true
            self.s_SellScriptDisplayName = self:GetRunningSellScriptDisplayName()
            break
        else
            self.s_SellScriptName = "None"
            self.s_SellScriptDisplayName = "None"
            self.b_SellScriptIsRunning = false
        end
    end

    if self.b_SellScriptIsRunning and self.i_BhubScriptHandle ~= 0 then -- was triggered from the mct
        for _, scr in pairs(eShouldTerminateScripts) do
            if script.is_active(scr) then
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 202, 1.0)
                Sleep(200)
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 202, 1.0)
                break
            end
        end

        if (CAM.IS_SCREEN_FADING_OUT() or CAM.IS_SCREEN_FADED_OUT()) then
            local fadedOutTimer = Timer.new(6969)

            while not fadedOutTimer:isDone() do
                if not CAM.IS_SCREEN_FADED_OUT() or CAM.IS_SCREEN_FADING_IN() then
                    break
                end
                yield()
            end

            -- recheck
            if CAM.IS_SCREEN_FADED_OUT() and not CAM.IS_SCREEN_FADING_IN() then -- Step bro, I'm stuck!
                CAM.DO_SCREEN_FADE_IN(100)
            end
        end
    end

    self.i_AutosellLastCheckTime = Time.now() + 1
end

---@param s script_util
function YRV3:AutoSell(s)
    if not Game.IsOnline() or not SS.IsUpToDate() then
        return
    end

    self:BackgroundWorker()

    if autosell and YRV3.b_SellScriptIsRunning and not YRV3.b_HasTriggeredAutosell and not CAM.IS_SCREEN_FADED_OUT() then
        YRV3.b_HasTriggeredAutosell = true
        YimToast:ShowSuccess("Samurai's Scripts", "Auto-Sell will start in 20 seconds.")
        s:sleep(20000)

        if AUDIO.IS_MOBILE_PHONE_CALL_ONGOING() then
            repeat
                s:sleep(100)
            until not AUDIO.IS_MOBILE_PHONE_CALL_ONGOING()
        end

        self:FinishSale()
    end

    if YRV3.b_HasTriggeredAutosell then
        repeat
            s:sleep(100) -- wait for the script to terminate.
        until not script.is_active(self.s_SellScriptName)
        YRV3.b_HasTriggeredAutosell = false
    end
end

function YRV3:MCT()
    if Self.IsBrowsingApps() then
        UI.WidgetSound("Error")
        return
    end

    script.run_in_fiber(function(mct)
        if globals.get_int(1943773) ~= 0 then
            globals.set_int(1943773, 0)
        end

        Await(Game.RequestScript, "appArcadeBusinessHub")

        UI.WidgetSound("Select")
        self.i_BhubScriptHandle = SYSTEM.START_NEW_SCRIPT("appArcadeBusinessHub", 1424) -- STACK_SIZE_DEFAULT
        SCRIPT.SET_SCRIPT_AS_NO_LONGER_NEEDED("appArcadeBusinessHub")
        mct:sleep(100)
        gui.toggle(false)

        while script.is_active("appArcadeBusinessHub") do
            if globals.get_int(1963766) == -1 then
                globals.set_int(1963766, 0)
            end
            mct:yield()
        end

        repeat
            mct:sleep(10)
        until not Self.IsBrowsingApps()
        globals.set_int(1943773, 0)
        self.i_BhubScriptHandle = 0
    end)
end

function YRV3:Reset()
    self.i_CEOvalueSum = 0
    self.i_BikerValueSum = 0
    self.i_SafeCashValueSum = 0
    self.OwnedWarehouseData = t_WarehouseInit
    self.OwnedBikerBusinessData = t_BikerBusinessInit
    self.OwnedBusinessSafeData = self.t_BusinessSafeData
end


------------------------------------------------------------------------
--- Data
------------------------------------------------------------------------

YRV3.t_SellScripts = {
    ["gb_smuggler"] = { -- air
        {               -- (1.70) while .*?0 < func_.*?\(func_.*?, func_.*?, .*?Local_....?\.f_....?, -1
            l = 1985,
            o = 1035,
            v = 0
        },
        { -- (1.70) if .*?Local_....?\.f_....? > 0 && func_.*?&.*?Local_....?\.f_....?\), 30000, 0
            l = 1985,
            o = 1078,
            v = 1
        },
    },
    ["gb_gunrunning"] = {
        { -- (1.70) .*?Local_1...?\.f_...? = func_.*?\(func_.*?\(\), .*?Local_1...?\.f_...?, .*?Param0, -1\);
            l = 1262,
            o = 774,
            v = 0
        },
        { -- (1.70) func_....?\(Local_1...?\.f_...?, .*?1, \"GR_HUD_TOT\", .*?4, 1, 4, 0, 0, 0, 0, 0, 1, 1, 0, 255, 0\);
            l = 1262,
            o = 816,
            v = 1
        },
    },
    ["gb_contraband_sell"] = {
        { -- (1.70) MISC::CLEAR_BIT\(.*?Local_...?\.f_1\), .*?Param0
            l = 563,
            o = 1,
            v = 99999
        },
    },
    ["gb_biker_contraband_sell"] = {
        { -- (1.70) else if .*?!func_.*?\(1\) && .*?Local_...?\.f_...? > 0\)
            l = 725,
            o = 122,
            v = 15
        },
    },
    ["fm_content_acid_lab_sell"] = {
        b = 5557, -- GENERICBITSET_I_WON -- (1.70) if .*?func_...?\(&.*?Local_....?, .*?Param0 // (uLocal_5557 = 4;)
        l = 5653, -- (1.70) if .*?Local_5...?\.f_....? == 0\)
        o = 1309
    },
    -- ["fm_content_smuggler_sell"] = {
    --   b = 3991, -- GENERICBITSET_I_WON -- (1.70) if .*?func_...?\(&.*?Local_....?, .*?Param0 // (uLocal_3991 = 4;)
    --   l = 4133, -- (1.70) if .*?Local_4...?\.f_....? == 0\)
    --   o = 489
    -- },
}

YRV3.t_CEOwarehouses = {
    ["Convenience Store Lockup"] = {
        size = 0, max = 16, coords = vec3:new(249.246918, -1955.651978, 23.161957)
    },
    ["Celltowa Unit"] = {
        size = 0, max = 16, coords = vec3:new(898.484314, -1031.882446, 34.966454)
    },
    ["White Widow Garage"] = {
        size = 0, max = 16, coords = vec3:new(-1081.083740, -1261.013184, 5.648909)
    },
    ["Pacific Bait Storage"] = {
        size = 0, max = 16, coords = vec3:new(51.311188, -2568.470947, 6.004591)
    },
    ["Pier 400 Utility Building"] = {
        size = 0, max = 16, coords = vec3:new(272.409424, -3015.267090, 5.707359)
    },
    ["Foreclosed Garage"] = {
        size = 0, max = 16, coords = vec3:new(-424.773499, 184.146530, 80.752899)
    },
    ["GEE Warehouse"] = {
        size = 1, max = 42, coords = vec3:new(1563.832031, -2135.110840, 77.616447)
    },
    ["Derriere Lingerie Backlot"] = {
        size = 1, max = 42, coords = vec3:new(-1269.286133, -813.215820, 17.107399)
    },
    ["Fridgit Annexe"] = {
        size = 1, max = 42, coords = vec3:new(-528.074585, -1782.701904, 21.483055)
    },
    ["Discount Retail Unit"] = {
        size = 1, max = 42, coords = vec3:new(349.901184, 327.976440, 104.303856)
    },
    ["Disused Factory Outlet"] = {
        size = 1, max = 42, coords = vec3:new(-328.013458, -1354.755371, 31.296524)
    },
    ["LS Marine Building 3"] = {
        size = 1, max = 42, coords = vec3:new(-308.772247, -2698.393799, 6.000292)
    },
    ["Old Power Station"] = {
        size = 1, max = 42, coords = vec3:new(541.587646, -1944.362793, 24.985096)
    },
    ["Railyard Warehouse"] = {
        size = 1, max = 42, coords = vec3:new(503.738037, -653.082642, 24.751144)
    },
    ["Wholesale Furniture"] = {
        size = 2, max = 111, coords = vec3:new(1041.059814, -2172.653076, 31.488876)
    },
    ["West Vinewood Backlot"] = {
        size = 2, max = 111, coords = vec3:new(-245.651718, 202.504669, 83.792648)
    },
    ["Xero Gas Factory"] = {
        size = 2, max = 111, coords = vec3:new(-1045.004395, -2023.150146, 13.161570)
    },
    ["Logistics Depot"] = {
        size = 2, max = 111, coords = vec3:new(922.555481, -1560.048950, 30.756647)
    },
    ["Bilgeco Warehouse"] = {
        size = 2, max = 111, coords = vec3:new(-876.108032, -2734.502930, 13.844264)
    },
    ["Walker & Sons Warehouse"] = {
        size = 2, max = 111, coords = vec3:new(93.278641, -2216.144775, 6.033320)
    },
    ["Cypress Warehouses"] = {
        size = 2, max = 111, coords = vec3:new(1015.361633, -2510.986572, 28.302608)
    },
    ["Darnell Bros Warehouse"] = {
        size = 2, max = 111, coords = vec3:new(762.672363, -909.193054, 25.250854)
    },
}

YRV3.t_BikerBusinessIDs = {
    { name = "Fake Documents",  id = 0, unit_max = 60, val_offset = 17319, blip = 498, possible_ids = { 5, 10, 15, 20 } },
    { name = "Weed",            id = 1, unit_max = 80, val_offset = 17323, blip = 496, possible_ids = { 2, 7, 12, 17 } },
    { name = "Fake Cash",       id = 2, unit_max = 40, val_offset = 17320, blip = 500, possible_ids = { 4, 9, 14, 19 } },
    { name = "Methamphetamine", id = 3, unit_max = 20, val_offset = 17322, blip = 499, possible_ids = { 1, 6, 11, 16 } },
    { name = "Cocaine",         id = 4, unit_max = 10, val_offset = 17321, blip = 497, possible_ids = { 3, 8, 13, 18 } },
}

YRV3.t_Hangars = {
    [1] = { name = "LSIA Hangar 1", coords = vec3:new(-1148.908447, -3406.064697, 13.945053) },
    [2] = { name = "LSIA Hangar A17", coords = vec3:new(-1393.322021, -3262.968262, 13.944828) },
    [3] = { name = "Fort Zancudo Hangar A2", coords = vec3:new(-2022.336304, 3154.936768, 32.810272) },
    [4] = { name = "Fort Zancudo Hangar 3497", coords = vec3:new(-1879.105957, 3106.792969, 32.810234) },
    [5] = { name = "Fort Zancudo Hangar 3499", coords = vec3:new(-2470.278076, 3274.427734, 32.835461) },
}

YRV3.t_Bunkers = {
    [21] = { name = "Grand Senora Oilfields Bunker", coords = vec3:new(494.680878, 3015.895996, 41.041725) },
    [22] = { name = "Grand Senora Desert Bunker", coords = vec3:new(849.619812, 3024.425781, 41.266800) },
    [23] = { name = "Route 68 Bunker", coords = vec3:new(40.422565, 2929.004395, 55.746357) },
    [24] = { name = "Farmhouse Bunker", coords = vec3:new(1571.949341, 2224.597168, 78.350952) },
    [25] = { name = "Smoke Tree Road Bunker", coords = vec3:new(2107.135254, 3324.630615, 45.371754) },
    [26] = { name = "Thomson Scrapyard Bunker", coords = vec3:new(2488.706055, 3164.616699, 49.080124) },
    [27] = { name = "Grapeseed Bunker", coords = vec3:new(1798.502930, 4704.956543, 39.995476) },
    [28] = { name = "Paleto Forest Bunker", coords = vec3:new(-754.225769, 5944.171875, 19.836382) },
    [29] = { name = "Raton Canyon Bunker", coords = vec3:new(-388.333160, 4338.322754, 56.103130) },
    [30] = { name = "Lago Zancudo Bunker", coords = vec3:new(-3030.341797, 3334.570068, 10.105902) },
    [31] = { name = "Chumash Bunker", coords = vec3:new(-3156.140625, 1376.710693, 17.073570) },
}

YRV3.t_BusinessSafeData = {
    ["Nightclub"] = {
        isOwned = function()
            return stats.get_int("MPX_NIGHTCLUB_OWNED") ~= 0
        end,
        cashValue = function()
            return stats.get_int("MPX_CLUB_SAFE_CASH_VALUE")
        end,
        max_cash = 25e4,
        blip = 614,
        popularity = function()
            return stats.get_int("MPX_CLUB_POPULARITY")
        end,
        maxPop = function()
            if stats.get_int("MPX_CLUB_POPULARITY") >= 1e3 then
                return
            end
            stats.set_int("MPX_CLUB_POPULARITY", 1e3)
        end
    },
    ["Arcade"] = {
        isOwned = function()
            return stats.get_int("MPX_ARCADE_OWNED") ~= 0
        end,
        cashValue = function()
            return stats.get_int("MPX_ARCADE_SAFE_CASH_VALUE")
        end,
        max_cash = 1e5,
        blip = 740,
    },
    ["Agency"] = {
        isOwned = function()
            return stats.get_int("MPX_FIXER_HQ_OWNED") ~= 0
        end,
        cashValue = function()
            return stats.get_int("MPX_FIXER_SAFE_CASH_VALUE")
        end,
        max_cash = 25e4,
        blip = 826,
    },
    ["MC Clubhouse"] = {
        isOwned = function()
            return stats.get_int("MPX_PROP_CLUBHOUSE") ~= 0
        end,
        cashValue = function()
            return stats.get_int("MPX_BIKER_BAR_RESUPPLY_CASH")
        end,
        max_cash = 1e5,
        blip = 492,
    },
    ["Bail Office"] = {
        isOwned = function()
            return stats.get_int("MPX_BAIL_OFFICE_OWNED") ~= 0
        end,
        cashValue = function()
            return stats.get_int("MPX_BAIL_SAFE_CASH_VALUE")
        end,
        max_cash = 1e5,
        blip = 893,
    },
    ["Salvage Yard"] = {
        isOwned = function()
            return stats.get_int("MPX_SALVAGE_YARD_OWNED") ~= 0
        end,
        cashValue = function()
            return stats.get_int("MPX_SALVAGE_SAFE_CASH_VALUE")
        end,
        max_cash = 25e4,
        blip = 867,
    },
    ["Garment Factory"] = {
        isOwned = function()
            return stats.get_int("MPX_HACKER_DEN_OWNED") ~= 0
        end,
        cashValue = function()
            return stats.get_int("MPX_HDEN24_SAFE_CASH_VALUE")
        end,
        max_cash = 1e5,
        blip = 900,
    },
}
