local t_WarehouseData = {
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

local t_BikerBusinessData = {
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
YRV3.OwnedWarehouseData = t_WarehouseData
YRV3.OwnedBikerBusinessData = t_BikerBusinessData
YRV3.OwnedBusinessSafeData = t_BusinessSafeData
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

    for _, v in ipairs(t_BikerBusinessIDs) do
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

        if t_CEOwarehouses[warehouseName] then
            self.OwnedWarehouseData[index] = {
                wasChecked = true,
                isOwned = true,
                autoFill = false,
                name = warehouseName,
                size = t_CEOwarehouses[warehouseName].size,
                max = t_CEOwarehouses[warehouseName].max,
                pos = t_CEOwarehouses[warehouseName].coords,
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
            and (stats.get_int(("MPX_MATTOTALFORFACTORY%d"):format(slot)) < v.unit_max) then
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

    if not t_SellScripts[self.s_SellScriptName] then
        return
    end

    local sn = self.s_SellScriptName
    self.b_HasTriggeredAutosell = true

    script.execute_as_script(sn, function(s)
        if not t_SellScripts[sn].b then -- gb_*
            for _, data in pairs(t_SellScripts[sn]) do
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

            local val = locals.get_int(sn, t_SellScripts[sn].b + 1 + 0)
            if not Lua_fn.has_bit(val, 11) then
                val = Lua_fn.set_bit(val, 11)
                locals.set_int(sn, t_SellScripts[sn].b + 1 + 0, val)
            end

            locals.set_int(sn, t_SellScripts[sn].l + t_SellScripts[sn].o, 3) -- End reason.
        end
    end)
end

function YRV3:GetRunningSellScriptDisplayName()
    if not self.b_SellScriptIsRunning or not self.s_SellScriptName then
        return "None"
    end

    return self.SellScriptsDisplayNames[self.s_SellScriptName] or "None"
end

function YRV3:IsSellScriptRunning()
    if Time.now() < self.i_AutosellLastCheckTime then
        return
    end

    for sn in pairs(t_SellScripts) do
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

    if YRV3.b_SellScriptIsRunning and YRV3.i_BhubScriptHandle ~= 0 then
        for _, scr in pairs(eShouldTerminateScripts) do
            if script.is_active(scr) then -- was triggered from the mct
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

    self:IsSellScriptRunning()

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
    self.OwnedWarehouseData = t_WarehouseData
    self.OwnedBikerBusinessData = t_BikerBusinessData
    self.OwnedBusinessSafeData = t_BusinessSafeData
end
