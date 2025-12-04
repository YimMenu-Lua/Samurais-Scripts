---@class StructWarehouses
local StructWarehouses = {
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

---@class StructBikerBusiness
local StructBikerBusiness = {
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

---@class StructBusinessSafes
local StructBusinessSafes = {
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
    ["Car Wash"] = {
        isOwned = function()
            return stats.get_int("MPX_SB_CAR_WASH_OWNED") ~= 0
        end,
        cashValue = function()
            return stats.get_int("MPX_CWASH_SAFE_CASH_VALUE")
        end,
        max_cash = 1e5,
        blip = 931,
    },
}

---@class StructScriptDisplayNames
local StructScriptDisplayNames  <const> = {
    ["fm_content_smuggler_sell"] = "Hangar (Land. Not supported.)",
    ["gb_smuggler"]              = "Hangar (Air)",
    ["gb_contraband_sell"]       = "CEO",
    ["gb_gunrunning"]            = "Bunker",
    ["gb_biker_contraband_sell"] = "Biker Business",
    ["fm_content_acid_lab_sell"] = "Acid Lab",
}

local eShouldTerminateScripts <const> = {
    "appArcadeBusinessHub",
    "appsmuggler",
    "appbikerbusiness",
    "appbunkerbusiness",
    "appbusinesshub"
}

---@class YRV3
---@field m_total_sum number
---@field m_ceo_value_sum number
---@field m_biker_value_sum number
---@field m_safe_cash_sum number
---@field m_bhub_script_handle number
---@field m_warehouse_data StructWarehouses
---@field m_biker_data StructBikerBusiness
---@field m_safe_cash_data StructBusinessSafes
---@field m_hangar_loop boolean
---@field m_has_triggered_autosell boolean
---@field m_sell_script_running boolean
---@field m_sell_script_name string?
---@field m_sell_script_disp_name string
---@field m_display_names StructScriptDisplayNames
---@field private m_autosell_check_time number
local YRV3 = {}
YRV3.__index = YRV3

---@return YRV3
function YRV3:init()
    local instance = setmetatable({
        m_total_sum = 0,
        m_ceo_value_sum = 0,
        m_biker_value_sum = 0,
        m_safe_cash_sum = 0,
        m_bhub_script_handle = 0,
        m_autosell_check_time = 0,
        m_hangar_loop = false,
        m_has_triggered_autosell = false,
        m_sell_script_running = false,
        m_sell_script_name = nil,
        m_sell_script_disp_name = "None",
        m_warehouse_data = StructWarehouses,
        m_biker_data = StructBikerBusiness,
        m_safe_cash_data = StructBusinessSafes,
        m_display_names = StructScriptDisplayNames,
    }, self)

    ThreadManager:CreateNewThread("SS_YRV3", function()
        instance:Start()
    end)

    Backend:RegisterEventCallback(eBackendEvent.RELOAD_UNLOAD, function()
        instance:Reset()
    end)

    Backend:RegisterEventCallback(eBackendEvent.SESSION_SWITCH, function()
        instance:Reset()
    end)

    return instance
end

function YRV3:CanAccess()
    return (Backend:GetAPIVersion() == eAPIVersion.V1)
    and Backend:IsUpToDate()
    and Game.IsOnline()
    and not script.is_active("maintransition")
    and not NETWORK.NETWORK_IS_ACTIVITY_SESSION()
end

---@param where integer|vec3
---@param keepVehicle? boolean
function YRV3:Teleport(where, keepVehicle)
    if not Self:IsOutside() then
        GUI:PlaySound(GUI.Sounds.Error)
        Toast:ShowError(
            "YRV3",
            "Please go outdside first!"
        )
        return
    end

    GUI:PlaySound(GUI.Sounds.Select_alt)
    Self:Teleport(where, keepVehicle)
end

---@param stat string
---@param slot integer
---@return boolean
function YRV3:DoesPlayerOwnPropertySlot(stat, slot)
    return stats.get_int(_F("%s%d", stat, slot)) ~= 0
end

---@return boolean
function YRV3:DoesPlayerOwnAnyWarehouse()
    for i = 0, 4 do
       if (self:DoesPlayerOwnPropertySlot("MPX_PROP_WHOUSE_SLOT", i)) then
            return true
       end
    end

    return false
end

---@return boolean
function YRV3:DoesPlayerOwnAnyBikerBusiness()
    for i = 0, 4 do
       if (self:DoesPlayerOwnPropertySlot("MPX_PROP_FAC_SLOT", i)) then
            return true
       end
    end

    return false
end

---@param index integer
function YRV3:PopulateBikerBusinessSlot(index)
    script.run_in_fiber(function()
        if (self.m_biker_data[index].wasChecked) then
            return
        end

        for _, v in ipairs(self.t_BikerBusinessIDs) do
            local propertyIndex = stats.get_int(_F("MPX_FACTORYSLOT%d", index-1))

            if table.find(v.possible_ids, propertyIndex) then
                self.m_biker_data[index] = {
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
    end)
end

function YRV3:PopulateCEOwarehouseSlot(index)
    if self.m_warehouse_data[index].wasChecked then
        return
    end

    script.run_in_fiber(function()
        local property_index = (stats.get_int(_F("MPX_PROP_WHOUSE_SLOT%d", index-1))) - 1
        local warehouseName = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(_F("MP_WHOUSE_%d", property_index))

        if self.t_CEOwarehouses[property_index] then
            self.m_warehouse_data[index] = {
                wasChecked = true,
                isOwned = true,
                autoFill = false,
                name = warehouseName,
                size = self.t_CEOwarehouses[property_index].size,
                max = self.t_CEOwarehouses[property_index].max,
                pos = self.t_CEOwarehouses[property_index].coords,
            }
        end
    end)
end

---@param crates number
function YRV3:GetCEOCratesValue(crates)
    if (not crates or crates <= 0) then
        return 0
    end

    local FreeModeGlobal1 = ScriptGlobal(GetScriptGlobalOrLocal("tuneables_global") or 262145)
    if (crates == 1) then
        return FreeModeGlobal1:At(15732):ReadInt() -- EXEC_CONTRABAND_SALE_VALUE_THRESHOLD1
    end

    if (crates == 2) then
        return FreeModeGlobal1:At(15733):ReadInt() * 2
    end

    if (crates == 3) then
        return FreeModeGlobal1:At(15734):ReadInt() * 3
    end

    if (crates == 4 or crates == 5) then
        return FreeModeGlobal1:At(15735):ReadInt() * crates
    end

    if (crates >= 6 and crates <= 9) then
        return (FreeModeGlobal1:At(15735):ReadInt() + math.floor((crates - 4) / 2)) * crates
    end

    if (crates >= 10 and crates <= 110) then
        return (FreeModeGlobal1:At(15738):ReadInt() + math.floor((crates - 10) / 5)) * crates
    end

    if (crates == 111) then
        return FreeModeGlobal1:At(15752):ReadInt() * 111
    end

    return 0
end

function YRV3:FinishCEOCargoSourceMission()
    if script.is_active("gb_contraband_buy") then
        script.execute_as_script("gb_contraband_buy", function()
            if (not NETWORK.NETWORK_IS_HOST_OF_THIS_SCRIPT()) then
                Toast:ShowError("YRV3", "You are not host of this script.")
                return
            end

            local buyLocal = GetScriptGlobalOrLocal("gb_contraband_buy_local_1")
            if (buyLocal == 0) then
                Toast:ShowError("YRV3", "Auto-finish mission failed! Could not read local value.", true)
                return
            end
            locals.set_int("gb_contraband_buy", buyLocal + 5, 1)   -- 1.71 b3568.0 -- case -1: return "INVALID - UNSET";
            locals.set_int("gb_contraband_buy", buyLocal + 191, 6) -- 1.71 b3568.0 -- Local_623.f_191 = iParam0;
            locals.set_int("gb_contraband_buy", buyLocal + 192, 4) -- 1.71 b3568.0 -- Local_623.f_192 = iParam0;
        end)
    elseif script.is_active("fm_content_cargo") then
        script.execute_as_script("fm_content_cargo", function()
            if not NETWORK.NETWORK_IS_HOST_OF_THIS_SCRIPT() then
                Toast:ShowError("YRV3", "You are not host of this script.")
                return
            end

            local fmccLocal1 = GetScriptGlobalOrLocal("gb_contraband_buy_local_2")
            local fmccLocal2Obj = GetScriptGlobalOrLocalData("gb_contraband_buy_local_3")
            if (fmccLocal1 == 0 or fmccLocal2Obj.value == 0) then
                Toast:ShowError("YRV3", "Auto-finish mission failed! Could not read local value.", true)
                return
            end

            local FMMC1 = ScriptLocal(fmccLocal1, "fm_content_cargo"):At(1):At(0)  -- GENERIC_BITSET_I_WON -- 1.71 b3568.0: var uLocal_5973 = 4;
            local val = FMMC1:ReadInt()
            if (not Bit.is_set(val, 11)) then
                val = Bit.set(val, 11)
                FMMC1:WriteInt(val)
            end

            locals.set_int("fm_content_cargo", fmccLocal2Obj.value + fmccLocal2Obj.offsets[1].value, 3) -- EndReason
        end)
    end
end

function YRV3:WarehouseAutofill()
    if (not self:CanAccess()) then
        return
    end

    for i, v in ipairs(self.m_warehouse_data) do
        if (not v.autoFill) then
            goto continue
        end

        if (not v.wasChecked or not v.name or not v.max) then
            self:PopulateCEOwarehouseSlot(i)
            sleep(500)
        end

        if (stats.get_int(("MPX_CONTOTALFORWHOUSE%d"):format(i-1))) == v.max then
            GUI:PlaySound(GUI.Sounds.Error)
            Toast:ShowWarning("YRV3", _F("Warehouse N°%d is already full! Option has been disabled.", i))
            v.autoFill = false
            goto continue
        end

        while ((stats.get_int(_F("MPX_CONTOTALFORWHOUSE%d", i-1))) < v.max) do
            if (not v.autoFill) then
                break
            end

            stats.set_bool_masked("MPX_FIXERPSTAT_BOOL1", true, i+11)
            sleep(GVars.autofill_delay or 100)
        end

        ::continue::
        v.autoFill = false
    end

    sleep(1000)
end

function YRV3:HangarAutofill()
    if (not self:CanAccess()) then
        return
    end

    if (not self.m_hangar_loop) then
        return
    end

    if (stats.get_int("MPX_HANGAR_OWNED") == 0) then
        Toast:ShowWarning(
            "YRV3",
            "You don't seem to own a hangar. Option has been disabled.",
            false,
            3
        )

        self.m_hangar_loop = false
        return
    end

    if stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL") == 50 then
        Toast:ShowWarning("YRV3", "Your Hangar is already full! Option has been disabled.")
        self.m_hangar_loop = false
        return
    end

    while stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL") < 50 do
        if (not self.m_hangar_loop) then
            break
        end

        stats.set_bool_masked("MPX_DLC22022PSTAT_BOOL3", true, 9)
        sleep(GVars.autofill_delay or 100)
    end

    self.m_hangar_loop = false
end

function YRV3:FinishSaleOnCommand()
    if (not self:CanAccess()) then
        return
    end

    if (GVars.autosell) then
        Toast:ShowWarning(
            "YRV3",
            "You aleady have 'Auto-Sell' enabled. No need to manually trigger it.",
            false,
            1.5
        )
        return
    end

    if (not YRV3.m_sell_script_running) then
        Toast:ShowWarning(
            "YRV3",
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
    if (not self:CanAccess()) then
        return
    end

    script.run_in_fiber(function(s)
        if (not self.m_warehouse_data[index].wasChecked) then
            self:PopulateCEOwarehouseSlot(index)
            s:sleep(250)
        end

        if (not self.m_warehouse_data[index].isOwned) then
            Toast:ShowError(
            "YRV3",
            _F("No warehouse found in slot %d!", index),
            false
        )
            return
        end

        self.m_warehouse_data[index].autoFill = not self.m_warehouse_data[index].autoFill
        Toast:ShowMessage(
            "YRV3",
            _F("CEO Warehouse %d auto-fill %s.",
                index,
                self.m_warehouse_data[index].autoFill
                and "Enabled"
                or "Disabled"
            ),
            false,
            2
        )
    end)
end

function YRV3:FillAll()
    if (not self:CanAccess()) then
        return
    end

    script.run_in_fiber(function()
        if (stats.get_int("MPX_HANGAR_OWNED") ~= 0 and not YRV3.m_hangar_loop) then
            YRV3.m_hangar_loop = true
            sleep(math.random(100, 300))
        end

        local businessGlobal = GetScriptGlobalOrLocal("freemode_business_global")
        if (businessGlobal == 0) then
            Toast:ShowError("YRV3", "Auto-fill failed! Could not read global value")
            return
        end

        local FMG = ScriptGlobal(businessGlobal)
        if (stats.get_int("MPX_PROP_FAC_SLOT5") and stats.get_int("MPX_MATTOTALFORFACTORY5") < 100) then
            FMG:At(5):At(1):WriteInt(1)
            sleep(math.random(100, 300))
        end

        if (stats.get_int("MPX_XM22_LAB_OWNED") ~= 0) and (stats.get_int("MPX_MATTOTALFORFACTORY6") < 100) then
            FMG:At(6):At(1):WriteInt(1)
            sleep(math.random(100, 300))
        end

        for i, v in ipairs(self.m_warehouse_data) do
            if (not v.wasChecked or not v.max) then
                self:PopulateCEOwarehouseSlot(i)
                sleep(100)
            end
        end

        for _, v in ipairs(self.m_warehouse_data) do
            if (v.isOwned) then
                v.autoFill = true
            end
        end

        for i, v in ipairs(self.m_biker_data) do
            if (not v.wasChecked or not v.unit_max) then
                self:PopulateBikerBusinessSlot(i)
                sleep(100)
            end
        end

        for i, v in ipairs(self.m_biker_data) do
            local slot = i - 1
            local supplies = stats.get_int(_F("MPX_MATTOTALFORFACTORY%d", slot))
            if (v.isOwned and v.unit_max and supplies < 100) then
                FMG:At(slot):At(1):WriteInt(1)
                sleep(math.random(200, 666))
            end
        end
    end)
end

function YRV3:FinishSale()
    local sn = self.m_sell_script_name
    if (not sn or not self.t_SellScripts[sn]) then
        return
    end

    self.m_has_triggered_autosell = true
    script.execute_as_script(sn, function()
        if not self.t_SellScripts[sn].b then -- gb_*
            for _, data in pairs(self.t_SellScripts[sn]) do
                locals.set_int(sn, data.l + data.o, data.v)
            end
        else -- fm_content_*
            if not (NETWORK.NETWORK_GET_HOST_OF_THIS_SCRIPT() == Self:GetPlayerID()) then
                Toast:ShowWarning(
                    "YRV3",
                    "Unable to finish sale mission because you are not host of this script."
                )
                return
            end

            local val = locals.get_int(sn, self.t_SellScripts[sn].b + 1 + 0)
            if not Bit.is_set(val, 11) then
                val = Bit.set(val, 11)
                locals.set_int(sn, self.t_SellScripts[sn].b + 1 + 0, val)
            end

            locals.set_int(sn, self.t_SellScripts[sn].l + self.t_SellScripts[sn].o, 3) -- 3=End reason.
        end
    end)
end

function YRV3:GetRunningSellScriptDisplayName()
    if (not self.m_sell_script_running or not self.m_sell_script_name) then
        return "None"
    end

    return self.m_display_names[self.m_sell_script_name] or "None"
end

function YRV3:BackgroundWorker()
    if (Time.now() < self.m_autosell_check_time) then
        return
    end

    for sn in pairs(self.t_SellScripts) do
        if script.is_active(sn) then
            self.m_sell_script_name = sn
            self.m_sell_script_running = true
            self.m_sell_script_disp_name = self:GetRunningSellScriptDisplayName()
            break
        else
            self.m_sell_script_name = "None"
            self.m_sell_script_disp_name = "None"
            self.m_sell_script_running = false
        end
    end

    if (self.m_sell_script_running and self.m_bhub_script_handle ~= 0) then -- was triggered from the mct
        for _, scr in pairs(eShouldTerminateScripts) do
            if (script.is_active(scr)) then
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 202, 1.0)
                sleep(200)
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 202, 1.0)
                break
            end
        end

        if (CAM.IS_SCREEN_FADING_OUT() or CAM.IS_SCREEN_FADED_OUT()) then
            local fadedOutTimer = Timer.new(6969)

            while (not fadedOutTimer:is_done()) do
                if (not CAM.IS_SCREEN_FADED_OUT() or CAM.IS_SCREEN_FADING_IN()) then
                    break
                end
                yield()
            end

            -- recheck
            if (CAM.IS_SCREEN_FADED_OUT() and not CAM.IS_SCREEN_FADING_IN()) then -- Step bro, I'm stuck!
                CAM.DO_SCREEN_FADE_IN(100)
            end
        end
    end

    self.m_autosell_check_time = Time.now() + 1
end

function YRV3:Start()
    if (not self:CanAccess()) then
        return
    end

    self:BackgroundWorker()

    if (GVars.autosell and self.m_sell_script_running and not self.m_has_triggered_autosell and not CAM.IS_SCREEN_FADED_OUT()) then
        self.m_has_triggered_autosell = true
        Toast:ShowSuccess("YRV3", "Auto-Sell will start in 20 seconds.")
        sleep(2e4)

        while (AUDIO.IS_MOBILE_PHONE_CALL_ONGOING()) do
            yield()
        end

        self:FinishSale()
    end

    while (self.m_has_triggered_autosell) do
        if (not script.is_active(self.m_sell_script_name)) then
            break
        end

        yield()
    end

    self.m_has_triggered_autosell = false

    self:HangarAutofill()
    self:WarehouseAutofill()
end

-- Master Control Terminal
function YRV3:MCT()
    if Self:IsBrowsingApps() then
        GUI:PlaySound(GUI.Sounds.Error)
        return
    end

    local bhubG1 = GetScriptGlobalOrLocal("business_hub_global_1")
    local bhubG2 = GetScriptGlobalOrLocal("business_hub_global_2")
    if (bhubG1 == 0 or bhubG2 == 0) then
        Toast:ShowError("YRV3", "Failed to open Master Control Terminal! Could not read global value.")
        return
    end

    local BusinessHubGlobal1 = ScriptGlobal(bhubG1)
    local BusinessHubGlobal2 = ScriptGlobal(bhubG2)

    script.run_in_fiber(function()
        if BusinessHubGlobal1:ReadInt() ~= 0 then
            BusinessHubGlobal1:WriteInt(0)
        end

        Await(Game.RequestScript, "appArcadeBusinessHub")
        GUI:PlaySound(GUI.Sounds.Button)
        self.m_bhub_script_handle = SYSTEM.START_NEW_SCRIPT("appArcadeBusinessHub", 1424) -- STACK_SIZE_DEFAULT
        SCRIPT.SET_SCRIPT_AS_NO_LONGER_NEEDED("appArcadeBusinessHub")
        sleep(100)
        gui.toggle(false)

        while script.is_active("appArcadeBusinessHub") do
            if (BusinessHubGlobal2:ReadInt() == -1) then
                BusinessHubGlobal2:WriteInt(0)
            end

            yield()
        end

        while (Self:IsBrowsingApps()) do
            yield()
        end

        BusinessHubGlobal1:WriteInt(0)
        self.m_bhub_script_handle = 0
    end)
end

function YRV3:Reset()
    self.m_ceo_value_sum = 0
    self.m_biker_value_sum = 0
    self.m_safe_cash_sum = 0
    self.m_warehouse_data = StructWarehouses
    self.m_biker_data = StructBikerBusiness
    self.m_safe_cash_data = StructBusinessSafes
end


------------------------------------------------------------------------
--- Data
------------------------------------------------------------------------

YRV3.t_SellScripts = {
    ["gb_smuggler"] = { -- air
        {
            l = (function() return GetScriptGlobalOrLocal("gb_smuggler_sell_air_local_1") end)(),
            o = (function() return GetScriptGlobalOrLocalData("gb_smuggler_sell_air_local_1").offsets[1].value end)(),
            v = 0
        },
        {
            l = (function() return GetScriptGlobalOrLocal("gb_smuggler_sell_air_local_2") end)(),
            o = (function() return GetScriptGlobalOrLocalData("gb_smuggler_sell_air_local_2").offsets[1].value end)(),
            v = 1
        },
    },
    ["gb_gunrunning"] = {
        {
            l = (function() return GetScriptGlobalOrLocal("gb_gunrunning_sell_local_1") end)(),
            o = (function() return GetScriptGlobalOrLocalData("gb_gunrunning_sell_local_1").offsets[1].value end)(),
            v = 0
        },
        {
            l = (function() return GetScriptGlobalOrLocal("gb_gunrunning_sell_local_1") end)(),
            o = (function() return GetScriptGlobalOrLocalData("gb_gunrunning_sell_local_2").offsets[1].value end)(),
            v = 1
        },
    },
    ["gb_contraband_sell"] = {
        {
            l = (function() return GetScriptGlobalOrLocal("gb_contraband_sell_local") end)(),
            o = 1,
            v = 99999
        },
    },
    ["gb_biker_contraband_sell"] = {
        {
            l = (function() return GetScriptGlobalOrLocal("gb_biker_contraband_sell_local") end)(),
            o = (function() return GetScriptGlobalOrLocalData("gb_biker_contraband_sell_local").offsets[1].value end)(),
            v = 15
        },
    },
    ["fm_content_acid_lab_sell"] = {
        b = (function() return GetScriptGlobalOrLocal("acid_lab_sell_bitset") end)(),
        l = (function() return GetScriptGlobalOrLocal("acid_lab_sell_local") end)(),
        o = (function() return GetScriptGlobalOrLocalData("acid_lab_sell_local").offsets[1].value end)(),
    },
}

YRV3.t_CEOwarehouses = {
    { id = 1, size  = 0, max = 16,  coords = vec3:new(51.311188, -2568.470947, 6.004591) },
    { id = 2, size  = 0, max = 16,  coords = vec3:new(-1081.083740, -1261.013184, 5.648909) },
    { id = 3, size  = 0, max = 16,  coords = vec3:new(898.484314, -1031.882446, 34.966454) },
    { id = 4, size  = 0, max = 16,  coords = vec3:new(249.246918, -1955.651978, 23.161957) },
    { id = 5, size  = 0, max = 16,  coords = vec3:new(-424.773499, 184.146530, 80.752899) },
    { id = 6, size  = 2, max = 111, coords = vec3:new(-1045.004395, -2023.150146, 13.161570) },
    { id = 7, size  = 1, max = 42,  coords = vec3:new(-1269.286133, -813.215820, 17.107399) },
    { id = 8, size  = 2, max = 111, coords = vec3:new(-876.108032, -2734.502930, 13.844264) },
    { id = 9, size  = 0, max = 16,  coords = vec3:new(272.409424, -3015.267090, 5.707359) },
    { id = 10, size = 1, max = 42,  coords = vec3:new(1563.832031, -2135.110840, 77.616447) },
    { id = 11, size = 1, max = 42,  coords = vec3:new(-308.772247, -2698.393799, 6.000292) },
    { id = 12, size = 1, max = 42,  coords = vec3:new(503.738037, -653.082642, 24.751144) },
    { id = 13, size = 1, max = 42,  coords = vec3:new(-528.074585, -1782.701904, 21.483055) },
    { id = 14, size = 1, max = 42,  coords = vec3:new(-328.013458, -1354.755371, 31.296524) },
    { id = 15, size = 1, max = 42,  coords = vec3:new(349.901184, 327.976440, 104.303856) },
    { id = 16, size = 2, max = 111, coords = vec3:new(922.555481, -1560.048950, 30.756647) },
    { id = 17, size = 2, max = 111, coords = vec3:new(762.672363, -909.193054, 25.250854) },
    { id = 18, size = 2, max = 111, coords = vec3:new(1041.059814, -2172.653076, 31.488876) },
    { id = 19, size = 2, max = 111, coords = vec3:new(1015.361633, -2510.986572, 28.302608) },
    { id = 20, size = 2, max = 111, coords = vec3:new(-245.651718, 202.504669, 83.792648) },
    { id = 21, size = 1, max = 42,  coords = vec3:new(541.587646, -1944.362793, 24.985096) },
    { id = 22, size = 2, max = 111, coords = vec3:new(93.278641, -2216.144775, 6.033320) },
}

YRV3.t_BikerBusinessIDs = {
    { name = "Fake Documents",  id = 0, unit_max = 60, val_offset = 17319, blip = 498, possible_ids = { 5, 10, 15, 20 } },
    { name = "Weed",            id = 1, unit_max = 80, val_offset = 17323, blip = 496, possible_ids = { 2, 7, 12, 17 } },
    { name = "Fake Cash",       id = 2, unit_max = 40, val_offset = 17320, blip = 500, possible_ids = { 4, 9, 14, 19 } },
    { name = "Methamphetamine", id = 3, unit_max = 20, val_offset = 17322, blip = 499, possible_ids = { 1, 6, 11, 16 } },
    { name = "Cocaine",         id = 4, unit_max = 10, val_offset = 17321, blip = 497, possible_ids = { 3, 8, 13, 18 } },
}

YRV3.t_Hangars = {
    [1] = { name = "LSIA Hangar 1",            coords = vec3:new(-1148.908447, -3406.064697, 13.945053) },
    [2] = { name = "LSIA Hangar A17",          coords = vec3:new(-1393.322021, -3262.968262, 13.944828) },
    [3] = { name = "Fort Zancudo Hangar A2",   coords = vec3:new(-2022.336304, 3154.936768, 32.810272) },
    [4] = { name = "Fort Zancudo Hangar 3497", coords = vec3:new(-1879.105957, 3106.792969, 32.810234) },
    [5] = { name = "Fort Zancudo Hangar 3499", coords = vec3:new(-2470.278076, 3274.427734, 32.835461) },
}

YRV3.t_Bunkers = {
    [21] = { name = "Grand Senora Oilfields Bunker", coords = vec3:new(494.680878, 3015.895996, 41.041725) },
    [22] = { name = "Grand Senora Desert Bunker",    coords = vec3:new(849.619812, 3024.425781, 41.266800) },
    [23] = { name = "Route 68 Bunker",               coords = vec3:new(40.422565, 2929.004395, 55.746357) },
    [24] = { name = "Farmhouse Bunker",              coords = vec3:new(1571.949341, 2224.597168, 78.350952) },
    [25] = { name = "Smoke Tree Road Bunker",        coords = vec3:new(2107.135254, 3324.630615, 45.371754) },
    [26] = { name = "Thomson Scrapyard Bunker",      coords = vec3:new(2488.706055, 3164.616699, 49.080124) },
    [27] = { name = "Grapeseed Bunker",              coords = vec3:new(1798.502930, 4704.956543, 39.995476) },
    [28] = { name = "Paleto Forest Bunker",          coords = vec3:new(-754.225769, 5944.171875, 19.836382) },
    [29] = { name = "Raton Canyon Bunker",           coords = vec3:new(-388.333160, 4338.322754, 56.103130) },
    [30] = { name = "Lago Zancudo Bunker",           coords = vec3:new(-3030.341797, 3334.570068, 10.105902) },
    [31] = { name = "Chumash Bunker",                coords = vec3:new(-3156.140625, 1376.710693, 17.073570) },
}

YRV3.t_ShittyMissions = {
    ["CEO"] = {
        type = "bool",
        idx = {
            f_15624 = 262145 + 15624, -- bool CEO Disable Air Attacked Sell Mission *(false)*
            f_15636 = 262145 + 15636, -- bool CEO Disable Air Drop Sell Mission *(false)*
            f_15642 = 262145 + 15642, -- bool CEO Disable Fly Low Sell Mission *(false)*
            f_15643 = 262145 + 15643, -- bool CEO Disable Restricted Airspace Sell Mission *(false)*
            f_15649 = 262145 + 15649, -- bool CEO Disable Attacked Sell Mission *(false)*
            f_15651 = 262145 + 15651, -- bool CEO Disable Defend Sell Mission *(false)*
            f_15679 = 262145 + 15679, -- bool CEO Disable No-Damage Sell Mission *(false)*
            f_15680 = 262145 + 15680, -- bool CEO Disable Sea Attacked Sell Mission *(false)*
            f_15686 = 262145 + 15686, -- bool CEO Disable Sea Defend Sell Mission *(false)*
            f_15692 = 262145 + 15692, -- bool CEO Disable Sting Operation Sell Mission *(false)*
            f_15698 = 262145 + 15698, -- bool CEO Disable Trackify Sell Mission *(false)*
        }
    },
    ["Biker"] = {
        type = "bool",
        idx = {
            f_18356 = 262145 + 18356, -- bool MC Disable Convoy Sell Mission *(false)*
            -- f_18358 = 262145 + 18358, -- bool MC Disable Trashmaster Sell Mission *(false)*
            f_18361 = 262145 + 18361, -- bool MC Disable Proven Sell Mission *(false)*
            f_18363 = 262145 + 18363, -- bool MC Disable Friends In Need Sell Mission *(false)*
            f_18366 = 262145 + 18366, -- bool MC Disable Border Patrol Sell Mission *(false)*
            f_18388 = 262145 + 18388, -- bool MC Disable Heli Drop Sell Mission *(false)*
            f_18391 = 262145 + 18391, -- bool MC Disable Post OP Sell Mission *(false)*
            f_18393 = 262145 + 18393, -- bool MC Disable Air Drop Sell Mission *(false)*
            f_18398 = 262145 + 18398, -- bool MC Disable Sting Operation Sell Mission *(false)*
            -- f_18400 = 262145 + 18400, -- bool MC Disable Benson Sell Mission *(false)*
            f_18408 = 262145 + 18408, -- bool MC Disable Race Sell Mission *(false)*
        }
    },
    ["Nightclub"] = {
        type = "float",
        idx = {
            f_24048 = 262145 + 24048, -- float Nightclub Sell Mission Multi Drop *(1.0)*
            f_24049 = 262145 + 24049, -- float Nightclub Sell Mission Hack Drop *(1.0)*
            f_24050 = 262145 + 24050, -- float Nightclub Sell Mission Roadblock *(1.0)*
            f_24051 = 262145 + 24051, -- float Nightclub Sell Mission Protect Buyer *(1.0)*
            f_24052 = 262145 + 24052, -- float Nightclub Sell Mission Undercover Cops *(1.0)*
            f_24053 = 262145 + 24053, -- float Nightclub Sell Mission Offshore Transfer *(1.0)*
            f_24054 = 262145 + 24054, -- float Nightclub Sell Mission Not a Scratch *(1.0)*
            f_24055 = 262145 + 24055, -- float Nightclub Sell Mission Follow Heli *(1.0)*
            f_24056 = 262145 + 24056, -- float Nightclub Sell Mission Find Buyer *(1.0)*
        },
    },
    ["Hangar"] = {
        type = "float",
        idx = {
            f_22472 = 262145 + 22472, -- float Hangar Heavy Lifting Sell Mission *(1.0)*
            f_22509 = 262145 + 22509, -- float Hangar Contested Sell Mission *(1.0)*
            -- f_22511 = 262145 + 22511, -- float Hangar Agile Delivery Sell Mission *(1.0)*
            -- f_22513 = 262145 + 22513, -- float Hangar Precision Delivery Sell Mission *(1.0)*
            f_22515 = 262145 + 22515, -- float Hangar Flying Fortress Sell Mission *(1.0)*
            -- f_22517 = 262145 + 22517, -- float Hangar Fly Low Sell Mission *(1.0)*
            f_22519 = 262145 + 22519, -- float Hangar Air Delivery Sell Mission *(1.0)*
            f_22521 = 262145 + 22521, -- float Hangar Air Police Sell Mission *(1.0)*
            f_22523 = 262145 + 22523, -- float Hangar Under The Radar Sell Mission *(1.0)*
        },
    },
}

return YRV3
