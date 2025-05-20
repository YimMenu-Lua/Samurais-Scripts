---@diagnostic disable: undefined-global, lowercase-global, undefined-field

require("ss_init")
log.info("version " .. SS.script_version)
SS.SyncConfing(CFG:Read(), SS.default_config)

local Samurais_scripts <const> = gui.add_tab("Samurai's Scripts")
Samurais_scripts:add_imgui(MainUI)

local self_tab <const> = Samurais_scripts:add_tab(_T("SELF_TAB_"))
self_tab:add_imgui(SelfUI)
self_tab:add_tab("YimActions V3"):add_imgui(YimActionsV3UI)
self_tab:add_tab(_T("SOUND_PLAYER_")):add_imgui(SoundPlayerUI)
self_tab:add_tab(_T("WEAPON_TAB_")):add_imgui(WeaponsUI)

local vehicle_tab <const> = Samurais_scripts:add_tab(_T("VEHICLE_TAB_"))
vehicle_tab:add_imgui(VehicleUI)
vehicle_tab:add_tab("Custom Paint Jobs"):add_imgui(CustomPaintsUI)
vehicle_tab:add_tab("Drift Mode"):add_imgui(DriftModeUI)
vehicle_tab:add_tab("Flatbed"):add_imgui(FlatbedUI)
vehicle_tab:add_tab("Handling Editor"):add_imgui(HandingEditorUI)

local world_tab <const> = Samurais_scripts:add_tab(_T("WORLD_TAB_"))
world_tab:add_imgui(WorldUI)
world_tab:add_tab("EntityForge"):add_imgui(EntityForgeUI)
world_tab:add_tab("Billionare Services V2"):add_imgui(BSV2UI)

local online_tab <const> = Samurais_scripts:add_tab("Online ")
local casino_pacino <const> = online_tab:add_tab("Casino Pacino ") -- IT'S NOT AL ANYMORE! IT'S DUNK!
casino_pacino:add_imgui(DunkUI)

local business_tab <const> = online_tab:add_tab("YimResupplier V3")
business_tab:add_imgui(YRV3UI)

local settings_tab <const> = Samurais_scripts:add_tab(_T("SETTINGS_TAB_"))
settings_tab:add_imgui(SettingsUI)
settings_tab:add_tab(_T("HOTKEYS_TAB_")):add_imgui(HotkeysUI)



gui.add_always_draw_imgui(ForgeAxisWindow)
gui.add_always_draw_imgui(ForgeChildCustomizationWindow)

gui.add_always_draw_imgui(function()
    CommandExecutor:Draw()
end)

gui.add_always_draw_imgui(function()
    DrawSpeedometer(
        Self.Vehicle.Speed * i_SpeedometerUnitModifier,
        math.floor((Self.Vehicle.MaxSpeed * (not fast_vehicles and 1.4 or 1.2)) * i_SpeedometerUnitModifier),
        s_SpeedometerGearDisplay,
        Self.Vehicle.Altitude,
        2500,
        0.0
    )
end)

----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------- Commands -----------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

CommandExecutor:RegisterCommand("autoheal", function()
    YimToast:ShowMessage("Samurai's Scripts", ("Autoheal %s."):format(Regen and "disabled" or "enabled"), false, 1.5)
    Regen = not Regen
    CFG:SaveItem("Regen", Regen)
end)

CommandExecutor:RegisterCommand("rod", function()
    YimToast:ShowMessage("Samurai's Scripts", ("Ragdoll On Demand %s."):format(rod and "disabled" or "enabled"), false,
        1.5)
    rod = not rod
    CFG:SaveItem("rod", rod)
end)

CommandExecutor:RegisterCommand("autofill.hangar", function()
    if Game.IsOnline() then
        YimToast:ShowMessage("Samurai's Scripts", ("Hangar auto-fill %s."):format(YRV3.b_HangarLoop and "disabled" or "enabled"),
            false, 1.5)
        YRV3.b_HangarLoop = not YRV3.b_HangarLoop
    else
        YimToast:ShowError("Samurai's Scripts", "Unavailable in Single Player!")
    end
end)

CommandExecutor:RegisterCommand("autofill.whouse1", function()
    YRV3:WarehouseAutofillOnCommand(1)
end)

CommandExecutor:RegisterCommand("autofill.whouse2", function()
    YRV3:WarehouseAutofillOnCommand(2)
end)

CommandExecutor:RegisterCommand("autofill.whouse3", function()
    YRV3:WarehouseAutofillOnCommand(3)
end)

CommandExecutor:RegisterCommand("autofill.whouse4", function()
    YRV3:WarehouseAutofillOnCommand(4)
end)

CommandExecutor:RegisterCommand("autofill.whouse5", function()
    YRV3:WarehouseAutofillOnCommand(5)
end)

CommandExecutor:RegisterCommand("yrv3.fillall", function()
    YRV3:FillAll()
end)

CommandExecutor:RegisterCommand("finishsale", function()
    YRV3:FinishSaleOnCommand()
end)

CommandExecutor:RegisterCommand("spawnmeaperv", function()
    SpawnPervert(Self.GetPedID(), "you")
end)

CommandExecutor:RegisterCommand("kys", function()
    command.call("suicide", {})
end)

CommandExecutor:RegisterCommand("vehlock", function()
    script.run_in_fiber(function(vehlock)
        if Self.Vehicle.Current ~= 0 and Self.Vehicle.IsCar then
            Self.PlayKeyfobAnim()
            AUDIO.PLAY_SOUND_FRONTEND(-1, "REMOTE_CONTROL_FOB", "PI_MENU_SOUNDS", false)
            vehlock:sleep(250)
            local toggle = (
                VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(Self.Vehicle.Current) == 1
            ) and true or false
            Self.Vehicle.DoorLockState = toggle and 2 or 1
            Game.Vehicle.LockDoors(Self.Vehicle.Current, toggle, vehlock)
        end
    end)
end)

CommandExecutor:RegisterCommand("PANIK", function()
    SS.Cleanup()
    AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(
        "ELECTROCUTION",
        "MISTERK",
        self.get_pos().x,
        self.get_pos().y,
        self.get_pos().z,
        "SPEECH_PARAMS_FORCE"
    )
    YimToast:ShowWarning("PANIK!", "(Ó _ Ò )!!")
end)

CommandExecutor:RegisterCommand("fastvehs", function()
    fast_vehicles = not fast_vehicles
    CFG:SaveItem("fast_vehicles", fast_vehicles)
    YimToast:ShowMessage(
        "Samurai's Scripts",
        ("Fast Vehicles %s"):format(fast_vehicles and "enabled" or "disabled"),
        false,
        1.5
    )
end)

CommandExecutor:RegisterCommand("resetcfg", SS.ResetSettings)

if SS_debug then
    CommandExecutor:RegisterCommand("wompus", function()
        CompanionManager:FulfillTheProphecy()
    end)
end


----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------- Keybinds ----------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

KeyManager:RegisterKeybind(keybinds.autokill.code, function()
    if SS.CanUseKeybinds() then
        autoKill = not autoKill
        YimToast:ShowMessage(
            "Samurai's Scripts",
            ("Auto-Kill Enemies %s."):format(autoKill and "enabled" or "disabled"),
            false,
            2
        )
        CFG:SaveItem("autoKill", autoKill)
    end
end)

KeyManager:RegisterKeybind(keybinds.enemiesFlee.code, function()
    if SS.CanUseKeybinds() then
        runaway = not runaway
        YimToast:ShowMessage(
            "Samurai's Scripts",
            ("Enemies Flee %s."):format(runaway and "enabled" or "disabled"),
            false,
            2
        )
        CFG:SaveItem("runaway", runaway)
    end
end)

KeyManager:RegisterKeybind(keybinds.missl_def.code, function()
    if SS.CanUseKeybinds() then
        missiledefense = not missiledefense
        YimToast:ShowMessage(
            "Samurai's Scripts",
            ("Missile Defence %s."):format(missiledefense and "enabled" or "disabled"),
            fasle,
            2
        )
        CFG:SaveItem("missiledefense", missiledefense)
    end
end)

KeyManager:RegisterKeybind(keybinds.cobra_maneuver.code, function()
    if (
        SS.CanUseKeybinds()
        and cobra_maneuver
        and Self.IsDriving()
        and Self.Vehicle.IsPlane
        and not gui.is_open()
        and not script.is_active("CELLPHONE_FLASHHAND")
    ) then
        script.run_in_fiber(function(cobra)
            CobraManeuver(cobra)
        end)
    end
end)

KeyManager:RegisterKeybind(keybinds.commands.code, function()
    if (SS.CanUseKeybinds() and not gui.is_open() and not b_IsCommandsUIOpen) then
        b_ShouldDrawCommandsUI = true
        b_IsCommandsUIOpen = true
        gui.override_mouse(true)
    end
end)

KeyManager:RegisterKeybind("ESC", function()
    if b_IsCommandsUIOpen then
        b_ShouldDrawCommandsUI = false
        b_IsCommandsUIOpen = false
        gui.override_mouse(false)
    end
end)

KeyManager:RegisterKeybind(keybinds.panik.code, function()
    if (
        SS.CanUseKeybinds() and not
        gui.is_open() and not
        script.is_active("CELLPHONE_FLASHHAND")
    ) then
        SS.Cleanup()
        AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(
            "ELECTROCUTION",
            "MISTERK",
            self.get_pos().x,
            self.get_pos().y,
            self.get_pos().z,
            "SPEECH_PARAMS_FORCE"
        )
        YimToast:ShowWarning("PANIK!", "(Ó _ Ò )!!")
    end
end)


----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------- Threads -----------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

script.register_looped("SS_HANDLERS", function(ss)
    KeyManager:HandleCallbacks()
    CommandExecutor:HandleCallbacks()
    PreviewService:Update()
    SS.OnPlayerSwitch(ss)
    SS.OnSessionSwitch(ss)
end)

script.register_looped("SS_POOLMGR", function(poolmgr)
    local sleepTime = SS_debug and 500 or 5e3

    for _, category in ipairs({g_SpawnedEntities.objects, g_SpawnedEntities.peds, g_SpawnedEntities.vehicles}) do
        if next(category) ~= nil then
            for handle in pairs(category) do
                local bExists = ENTITY.DOES_ENTITY_EXIST(handle)

                if not handle or not bExists then
                    SS.CheckFeatureEntities(handle)
                    Game.DeleteEntity(handle, Game.GetCategoryFromEntityType(handle))
                end

                if ENTITY.IS_ENTITY_DEAD(handle, false) then
                    SS.CheckFeatureEntities(handle)
                    Game.DeleteEntity(handle, Game.GetCategoryFromEntityType(handle))
                elseif ENTITY.IS_ENTITY_A_PED(handle) and g_CreatedBlips[handle] then
                    local blip = g_CreatedBlips[handle]
                    if PED.IS_PED_IN_ANY_VEHICLE(handle, true) then
                        if blip.alpha > 0 then
                            HUD.SET_BLIP_ALPHA(blip.handle, 0)
                            blip.alpha = 0
                        end
                    else
                        if blip.alpha < 255 then
                            HUD.SET_BLIP_ALPHA(blip.handle, 255)
                            blip.alpha = 255
                        end
                    end
                end
            end
        end
    end

    poolmgr:sleep(sleepTime)
end)

script.register_looped("SS_VEHMGR", function(vehmgr)
    Self.Vehicle:OnTick(vehmgr)
end)

-- BillionaireServices V2
script.register_looped("SS_BILLIONAIRE", function(grpmgr)
    BillionaireServices.GroupManager:OnTick(grpmgr)
end)

-- EntityForge
script.register_looped("SS_ENTITY_GRABBER", function()
    if EntityForge.EntityGunEnabled and WEAPON.IS_PED_ARMED(Self.GetPedID(), 4) then
        EntityForge:EntityGun()
    end
end)

-- Flatbed
script.register_looped("SS_FLATBED", function(fltbd)
    Flatbed:BackgroundWorker(fltbd)
end)

-- YimActions V3
script.register_looped("SS_MISC_ANIM", function(misc)
    YimActions:BackgroundWorker(misc)
end)

-- YimResupplier V3
script.register_looped("SS_AUTOSELL", function(as)
    YRV3:AutoSell(as)
end)
script.register_looped("SS_HSUPP", function(hsupp)
    YRV3:HangarAutofill(hsupp)
end)
script.register_looped("SS_WH_AUTOFILL", function(whaf)
    YRV3:WarehouseAutofill(whaf)
end)

-- Carpool
script.register_looped("SS_CARPOOL", function(cp)
    if b_Carpool then
        Carpool:Main(cp)
    end
end)

-- PublicSeating
script.register_looped("SS_PUBLICSEATS", function(s)
    if public_seats then
        PublicSeating:Update(s)
    end
end)

script.register_looped("SS_ANIMATED_LABEL", function(s) -- basic ass loading label
    if b_ShouldAnimateLoadingLabel then
        s_LoadingLabel = "-   "
        s:sleep(80)
        s_LoadingLabel = "--  "
        s:sleep(80)
        s_LoadingLabel = "--- "
        s:sleep(80)
        s_LoadingLabel = "----"
        s:sleep(80)
        s_LoadingLabel = " ---"
        s:sleep(80)
        s_LoadingLabel = "  --"
        s:sleep(80)
        s_LoadingLabel = "   -"
        s:sleep(80)
        s_LoadingLabel = "    "
        s:sleep(80)
        return
    end
end)

s_RandomDailyQuote = eRandomQuotes[math.random(1, #eRandomQuotes)]
script.register_looped("SS_DAILYQUOTE", function(qotd)
    if not disable_quotes
    and gui.is_open()
    and Samurais_scripts:is_selected() then
        if f_DailyQuoteTextAlpha > 0.1 then
            repeat
                f_DailyQuoteTextAlpha = f_DailyQuoteTextAlpha - 0.01
                qotd:sleep(20)
            until f_DailyQuoteTextAlpha <= 0.1
            s_RandomDailyQuote = eRandomQuotes[math.random(1, #eRandomQuotes)]
        end

        if f_DailyQuoteTextAlpha < 1.0 then
            repeat
                f_DailyQuoteTextAlpha = f_DailyQuoteTextAlpha + 0.01
                qotd:sleep(20)
            until f_DailyQuoteTextAlpha >= 1.0
            qotd:sleep(6942)
        end
    end
end)

script.register_looped("SS_INPUT", function() -- controls
    if b_IsTyping or b_IsSettingHotkeys then
        if not gui.is_open() then
            b_IsTyping, b_IsSettingHotkeys = false, false
        end

        PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
    end

    if EntityForge.EntityGunEnabled and WEAPON.IS_PED_ARMED(Self.GetPedID(), 4) then
        PAD.DISABLE_CONTROL_ACTION(0, 24, true)
        PAD.DISABLE_CONTROL_ACTION(0, 257, true)
    end

    if replaceSneakAnim and Self.IsOnFoot() then
        PAD.DISABLE_CONTROL_ACTION(0, 36, true)
    end

    if replacePointAct or YimActions:IsPedPlaying(self.get_ped()) or b_PedGrabbed or b_VehicleGrabbed then
        PAD.DISABLE_CONTROL_ACTION(0, 29, true)
    end

    if b_IsDuckingInVehicle then
        PAD.DISABLE_CONTROL_ACTION(0, 73, true)
        PAD.DISABLE_CONTROL_ACTION(0, 75, true)
        PAD.DISABLE_CONTROL_ACTION(0, 86, true)
    end

    if b_IsCarpooling then
        PAD.DISABLE_CONTROL_ACTION(0, 75, true)
    end

    if PAD.IS_USING_KEYBOARD_AND_MOUSE(0) then
        pressing_drift_button = SS.IsKeyPressed(keybinds.tdBtn.code) and not
            b_IsTyping and not b_IsSettingHotkeys and not HUD.IS_MP_TEXT_CHAT_TYPING()
        pressing_nos_button   = SS.IsKeyPressed(keybinds.nosBtn.code) and not
            b_IsTyping and not b_IsSettingHotkeys and not HUD.IS_MP_TEXT_CHAT_TYPING()
        pressing_purge_button = SS.IsKeyPressed(keybinds.purgeBtn.code) and not
            b_IsTyping and not b_IsSettingHotkeys and not HUD.IS_MP_TEXT_CHAT_TYPING()
        pressing_fltbd_button = SS.IsKeyJustPressed(keybinds.flatbedBtn.code) and not
            b_IsTyping and not b_IsSettingHotkeys and not HUD.IS_MP_TEXT_CHAT_TYPING()
        pressing_vmine_button = SS.IsKeyJustPressed(keybinds.vehicle_mine.code) and not
            b_IsTyping and not b_IsSettingHotkeys and not HUD.IS_MP_TEXT_CHAT_TYPING()
        pressing_rod_button   = SS.IsKeyPressed(keybinds.rodBtn.code) and not
            b_IsTyping and not b_IsSettingHotkeys and not HUD.IS_MP_TEXT_CHAT_TYPING()
        pressing_laser_button = SS.IsKeyJustPressed(keybinds.laser_sight.code) and not
            b_IsTyping and not b_IsSettingHotkeys and not HUD.IS_MP_TEXT_CHAT_TYPING()
    else
        pressing_drift_button = (gpad_keybinds.tdBtn.code ~= 0)
        and PAD.IS_CONTROL_PRESSED(0, gpad_keybinds.tdBtn.code)

        pressing_nos_button = (gpad_keybinds.nosBtn.code ~= 0)
        and PAD.IS_CONTROL_PRESSED(0, gpad_keybinds.nosBtn.code)

        pressing_purge_button = (gpad_keybinds.purgeBtn.code ~= 0)
        and (PAD.IS_CONTROL_PRESSED(0, gpad_keybinds.purgeBtn.code)
        or PAD.IS_DISABLED_CONTROL_PRESSED(0, gpad_keybinds.purgeBtn.code))

        pressing_fltbd_button = (gpad_keybinds.flatbedBtn.code ~= 0)
        and (PAD.IS_CONTROL_JUST_PRESSED(0, gpad_keybinds.flatbedBtn.code)
        or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, gpad_keybinds.flatbedBtn.code))

        pressing_vmine_button = (gpad_keybinds.vehicle_mine.code ~= 0)
        and (PAD.IS_CONTROL_JUST_PRESSED(0, gpad_keybinds.vehicle_mine.code)
        or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, gpad_keybinds.vehicle_mine.code))

        pressing_rod_button = (gpad_keybinds.rodBtn.code ~= 0)
        and (PAD.IS_CONTROL_PRESSED(0, gpad_keybinds.rodBtn.code)
        or PAD.IS_DISABLED_CONTROL_PRESSED(0, gpad_keybinds.rodBtn.code))

        pressing_laser_button = (gpad_keybinds.laser_sight.code ~= 0)
        and (PAD.IS_CONTROL_JUST_PRESSED(0, gpad_keybinds.laser_sight.code)
        or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, gpad_keybinds.laser_sight.code))
    end

    if Self.Vehicle.IsFlatbed
    and ((keybinds.flatbedBtn.code == 0x58) or (gpad_keybinds.flatbedBtn.code == 73)) then
        PAD.DISABLE_CONTROL_ACTION(0, 73, true)
    end

    if nosPurge and Self.IsDriving() and Self.Vehicle.IsValidLandVehicle
    and ((keybinds.purgeBtn.code == 0x58) or( gpad_keybinds.purgeBtn.code == 73)) then
        PAD.DISABLE_CONTROL_ACTION(0, 73, true)
    end

    if Self.IsDriving() then
        if speedBoost and ((keybinds.nosBtn.code == 0x10) or (gpad_keybinds.nosBtn.code == 21)) then
            if PAD.IS_CONTROL_PRESSED(0, 71) and pressing_nos_button then
                if Self.Vehicle.IsValidLandVehicle or Self.Vehicle.IsBoat or Self.Vehicle.IsBike then
                    -- prevent face planting when using NOS mid-air
                    PAD.DISABLE_CONTROL_ACTION(0, 60, true)
                    PAD.DISABLE_CONTROL_ACTION(0, 61, true)
                    PAD.DISABLE_CONTROL_ACTION(0, 62, true)
                end
            end
        end

        if holdF and Self.IsOutside() then
            if not b_IsDuckingInVehicle
            and VEHICLE.IS_VEHICLE_STOPPED(self.get_veh())
            and not b_IsTyping
            and not b_IsSettingHotkeys
            and not b_IsCommandsUIOpen then
                PAD.DISABLE_CONTROL_ACTION(0, 75, true)
            else
                i_TimerB = 0
            end
        end

        if keepWheelsTurned and Self.IsOutside() then
            if (Self.Vehicle.IsCar or Self.Vehicle.IsQuad) and not b_IsDuckingInVehicle
                and VEHICLE.IS_VEHICLE_STOPPED(self.get_veh()) then
                if PAD.IS_CONTROL_PRESSED(0, 34) or PAD.IS_CONTROL_PRESSED(0, 35) then
                    PAD.DISABLE_CONTROL_ACTION(0, 75, true)
                end
            end
        end
    end

    if (b_PedGrabber or b_PedGrabbed or b_VehicleGrabber or b_VehicleGrabbed)
    and Self.IsOnFoot()
    and not WEAPON.IS_PED_ARMED(Self.GetPedID(), 7) then
        PAD.DISABLE_CONTROL_ACTION(0, 24, true)
        PAD.DISABLE_CONTROL_ACTION(0, 25, true)
        PAD.DISABLE_CONTROL_ACTION(0, 50, true)
        PAD.DISABLE_CONTROL_ACTION(0, 68, true)
        PAD.DISABLE_CONTROL_ACTION(0, 91, true)
        PAD.DISABLE_CONTROL_ACTION(0, 257, true)
    end

    if b_IsCommandsUIOpen then
        PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
    end
end)

script.register_looped("SS_SELF", function(script) -- Self Features
    -- Auto-Heal
    if Regen and Self.IsAlive() then
        local maxHp = Self.MaxHealth()
        local myHp = Self.Health()
        local maxArmr = Self.MaxArmour()
        local myArmr = Self.Armour()

        if myHp < maxHp and myHp > 0 then
            if PED.IS_PED_IN_COVER(Self.GetPedID(), false) then
                ENTITY.SET_ENTITY_HEALTH(Self.GetPedID(), myHp + 10, 0, 0)
            else
                ENTITY.SET_ENTITY_HEALTH(Self.GetPedID(), myHp + 1, 0, 0)
            end
        end

        if (myArmr == nil) then
            PED.SET_PED_ARMOUR(Self.GetPedID(), 10)
        end

        if myArmr and myArmr < maxArmr then
            PED.ADD_ARMOUR_TO_PED(Self.GetPedID(), 0.5)
        end
    end

    -- Crouch
    if replaceSneakAnim
    and not b_IsCrouched
    and PAD.IS_DISABLED_CONTROL_PRESSED(0, 36)
    and Self.CanCrouch() then
        Await(Game.RequestClipSet, "move_ped_crouched")
        -- Await(Game.RequestClipSet, "move_aim_strafe_crouch_2h")

        if b_IsHandsUp then
            b_IsHandsUp = false
            TASK.CLEAR_PED_TASKS(Self.GetPedID())
        end

        PED.SET_PED_MOVEMENT_CLIPSET(Self.GetPedID(), "move_ped_crouched", 0.3)
        PED.SET_PED_STRAFE_CLIPSET(Self.GetPedID(), "move_aim_strafe_crouch_2h")
        script:sleep(250)
        b_IsCrouched = true
    end

    if b_IsCrouched
    and PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 36)
    and not HUD.IS_MP_TEXT_CHAT_TYPING() then
        PED.RESET_PED_MOVEMENT_CLIPSET(Self.GetPedID(), 0.3)
        PED.RESET_PED_STRAFE_CLIPSET(Self.GetPedID())
        script:sleep(250)
        b_IsCrouched = false
    end

    -- Replace 'Point At' Action
    if replacePointAct then
        if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 29) then
            PublicSeating:Cleanup()

            if not b_IsHandsUp then
                if Self.CanUseHandsUp() then
                    if b_IsCrouched then
                        b_IsCrouched = false
                        PED.RESET_PED_MOVEMENT_CLIPSET(Self.GetPedID(), 0)
                        PED.RESET_PED_STRAFE_CLIPSET(Self.GetPedID())
                    end
                end

                PlayHandsUp()
                b_IsHandsUp = true
            else
                TASK.CLEAR_PED_TASKS(Self.GetPedID())
                b_IsHandsUp = false
            end
        end
    end

    if b_IsHandsUp then
        if WEAPON.IS_PED_ARMED(Self.GetPedID(), 7) then
            if PAD.IS_CONTROL_PRESSED(0, 24) then
                TASK.CLEAR_PED_TASKS(Self.GetPedID())
                b_IsHandsUp = false
            end
        end

        if PLAYER.IS_PLAYER_FREE_AIMING(self.get_id()) then
            TASK.CLEAR_PED_TASKS(Self.GetPedID())
            b_IsHandsUp = false
        end

        if not Self.IsOnFoot() then
            if PED.IS_PED_SITTING_IN_ANY_VEHICLE(Self.GetPedID()) and not Self.Vehicle.IsCar then
                TASK.CLEAR_PED_TASKS(Self.GetPedID())
                b_IsHandsUp = false
            end
        end
    end

    -- Online Phone Animations
    if phoneAnim then
        if Game.IsOnline() and Self.CanUsePhoneAnims() then
            Self.TogglePhoneAnims(true)
            Self.PlayPhoneGestures(script)
            b_PhoneAnimsEnabled = true
        else
            if b_PhoneAnimsEnabled then
                Self.TogglePhoneAnims(false)
                b_PhoneAnimsEnabled = false
            end
        end
    else
        if b_PhoneAnimsEnabled then
            Self.TogglePhoneAnims(false)
            b_PhoneAnimsEnabled = false
        end
    end

    -- Sprint Inside
    if sprintInside then
        if not PED.GET_PED_CONFIG_FLAG(Self.GetPedID(), 427, true) then
            PED.SET_PED_CONFIG_FLAG(Self.GetPedID(), 427, true)
        end
    else
        if PED.GET_PED_CONFIG_FLAG(Self.GetPedID(), 427, true) then
            PED.SET_PED_CONFIG_FLAG(Self.GetPedID(), 427, false)
        end
    end

    -- Lockpick animation
    if lockPick then
        if not PED.GET_PED_CONFIG_FLAG(Self.GetPedID(), 426, true) then
            PED.SET_PED_CONFIG_FLAG(Self.GetPedID(), 426, true)
        end
    else
        if PED.GET_PED_CONFIG_FLAG(Self.GetPedID(), 426, true) then
            PED.SET_PED_CONFIG_FLAG(Self.GetPedID(), 426, false)
        end
    end
end)

script.register_looped("SS_RAGDOLL", function(rgdl) -- Ragdoll
    if clumsy then
        if PED.IS_PED_RAGDOLL(Self.GetPedID()) then
            rgdl:sleep(2500)
            return
        end
        PED.SET_PED_RAGDOLL_ON_COLLISION(Self.GetPedID(), true)
        if b_IsCrouched then
            b_IsCrouched = false
        end
        if b_IsHandsUp then
            b_IsHandsUp = false
        end
    elseif rod and Self.IsOnFoot() and pressing_rod_button and not HNS.isHiding then
        if PED.CAN_PED_RAGDOLL(Self.GetPedID()) then
            if not Self.IsBrowsingApps() then
                PED.SET_PED_TO_RAGDOLL(Self.GetPedID(), 1500, 0, 0, false, false, false)
            end
            if b_IsCrouched then
                b_IsCrouched = false
            end
            if b_IsHandsUp then
                b_IsHandsUp = false
            end
        else
            YimToast:ShowError(
                "Samurais Scripts",
                "Unable to ragdoll you.\nPlease make sure 'No Ragdoll' option\nis disabled in YimMenu."
            )
            rgdl:sleep(200)
        end
    end

    if ragdoll_sound and Game.IsOnline() and PED.IS_PED_RAGDOLL(Self.GetPedID()) then
        rgdl:sleep(500)
        local soundName = (
            (Self.GetPedModel() == 0x705E61F2) and
            "WAVELOAD_PAIN_MALE" or
            "WAVELOAD_PAIN_FEMALE"
        )

        AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(
            "SCREAM_PANIC_SHORT",
            soundName,
            self.get_pos().x,
            self.get_pos().y,
            self.get_pos().z,
            "SPEECH_PARAMS_FORCE_SHOUTED"
        )
        repeat
            rgdl:sleep(100)
        until not PED.IS_PED_RAGDOLL(Self.GetPedID())
    end
end)

script.register_looped("SS_HNS", function(hns) -- Hide & Seek
    if hideFromCops then
        HNS:Main()
    end
end)

script.register_looped("SS_TRIGGERBOT", function() -- Triggerbot
    if Triggerbot and PLAYER.IS_PLAYER_FREE_AIMING(self.get_id()) then
        local Entity = Self.GetEntityInCrosshairs()
        if Entity and ENTITY.IS_ENTITY_A_PED(Entity) and PED.IS_PED_HUMAN(Entity) then
            local bonePos = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(Entity,
                ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(Entity, "head"))
            weapon = Self.Weapon()
            if WEAPON.IS_PED_WEAPON_READY_TO_SHOOT(Self.GetPedID()) and Self.IsOnFoot() and not PED.IS_PED_RELOADING(Self.GetPedID()) then
                if PAD.IS_CONTROL_PRESSED(0, 21) and not ENTITY.IS_ENTITY_DEAD(Entity, false) then
                    if aimEnemy then
                        if Self.IsPedMyEnemy(Entity) then
                            TASK.TASK_AIM_GUN_AT_COORD(Self.GetPedID(), bonePos.x, bonePos.y, bonePos.z, 250, true,
                                false)
                            TASK.TASK_SHOOT_AT_COORD(Self.GetPedID(), bonePos.x, bonePos.y, bonePos.z, 250,
                                2556319013)
                        end
                    else
                        TASK.TASK_AIM_GUN_AT_COORD(Self.GetPedID(), bonePos.x, bonePos.y, bonePos.z, 250, true, false)
                        TASK.TASK_SHOOT_AT_COORD(Self.GetPedID(), bonePos.x, bonePos.y, bonePos.z, 250, 2556319013)
                    end
                end
            end
        end
    end
end)

script.register_looped("SS_MAGICBULLET", function(mb)
    if MagicBullet then
        if PLAYER.IS_PLAYER_FREE_AIMING(self.get_id()) then
            local isAiming, Entity = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(self.get_id(), i_Entity)

            if isAiming and ENTITY.IS_ENTITY_A_PED(Entity) and PED.IS_PED_HUMAN(Entity) then
                local pedPos = Game.GetEntityCoords(Entity, true)

                if Entity ~= 0 then
                    i_LastAimedAtPed = Entity
                end

                if not PED.HAS_PED_CLEAR_LOS_TO_ENTITY_(Self.GetPedID(), i_LastAimedAtPed, pedPos.x, pedPos.y, pedPos.z, 0, false, false) then
                    i_LastAimedAtPed = 0
                end
            end
        end

        if i_LastAimedAtPed ~= 0 and not ENTITY.IS_ENTITY_DEAD(i_LastAimedAtPed, false) then
            local pedBonePos = PED.GET_PED_BONE_COORDS(i_LastAimedAtPed, 0x796E, 0, 0, 0)
            local wpn_hash = Self.Weapon()

            if PAD.IS_CONTROL_PRESSED(0, 24) and not PED.IS_PED_RELOADING(Self.GetPedID()) then
                Await(Game.RequestWeaponAsset, wpn_hash)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
                    pedBonePos.x - 1.0,
                    pedBonePos.y - 1.0,
                    pedBonePos.z,
                    pedBonePos.x + 1.0,
                    pedBonePos.y + 1.0,
                    pedBonePos.z,
                    300,
                    false,
                    wpn_hash,
                    Self.GetPedID(),
                    true,
                    false,
                    -1082130432
                )
                mb:sleep(150)
            end
        end
    end
end)

script.register_looped("SS_AUTOKILL", function(ak) -- Auto-kill enemies
    if (autoKill and
        (PED.COUNT_PEDS_IN_COMBAT_WITH_TARGET_WITHIN_RADIUS(
            Self.GetPedID(),
            self.get_pos().x,
            self.get_pos().y,
            self.get_pos().z,
            500
        )) > 0
    ) then
        for _, p in pairs(entities.get_all_peds_as_handles()) do
            if PED.IS_PED_HUMAN(p) and Self.IsPedMyEnemy(p) and not PED.IS_PED_A_PLAYER(p) then
                if PED.IS_PED_IN_ANY_VEHICLE(p, false) then
                    local enemy_vehicle = PED.GET_VEHICLE_PED_IS_IN(p, false)
                    local enemy_vehicle_coords = Game.GetEntityCoords(enemy_vehicle, true)
                    local dist = enemy_vehicle_coords:distance(Self.GetPos())

                    if dist >= 20 then
                        VEHICLE.SET_VEHICLE_ENGINE_HEALTH(enemy_vehicle, -4000)
                        if (
                            Game.Vehicle.IsBike(enemy_vehicle) or
                            Game.Vehicle.IsCar(enemy_vehicle)
                        ) then
                            for i = 0, 7 do
                                VEHICLE.SET_VEHICLE_TYRE_BURST(enemy_vehicle, i, false, 1000.0)
                            end
                        end

                        PED.APPLY_DAMAGE_TO_PED(p, 100000, true, 0, 0x7FD62962)
                        -- NETWORK.NETWORK_EXPLODE_VEHICLE(enemy_vehicle, true, false, 0)
                    end
                else
                    PED.APPLY_DAMAGE_TO_PED(p, 100000, true, 0, 0x7FD62962)
                end
            end
        end
        ak:sleep(10)
    end
end)

script.register_looped("SS_EF", function() -- Enemies Flee
    if runaway then
        if Self.IsInCombat() then
            for _, p in pairs(entities.get_all_peds_as_handles()) do
                if PED.IS_PED_HUMAN(p) and Self.IsPedMyEnemy(p) and not PED.IS_PED_A_PLAYER(p) then
                    TASK.CLEAR_PED_SECONDARY_TASK(p)
                    TASK.CLEAR_PED_TASKS(p)
                    PED.SET_PED_KEEP_TASK(p, false)
                    PED.SET_PED_COMBAT_ATTRIBUTES(p, 5, false)
                    PED.SET_PED_COMBAT_ATTRIBUTES(p, 13, false)
                    PED.SET_PED_COMBAT_ATTRIBUTES(p, 31, false)
                    PED.SET_PED_COMBAT_ATTRIBUTES(p, 50, false)
                    PED.SET_PED_COMBAT_ATTRIBUTES(p, 58, false)
                    PED.SET_PED_COMBAT_ATTRIBUTES(p, 17, true)
                    PED.SET_PED_COMBAT_ATTRIBUTES(p, 77, true)

                    if WEAPON.IS_PED_ARMED(p, 7) then
                        WEAPON.SET_PED_DROPS_WEAPON(p)
                    end

                    if PED.IS_PED_IN_ANY_VEHICLE(p, false) then
                        TASK.TASK_VEHICLE_TEMP_ACTION(p, PED.GET_VEHICLE_PED_IS_USING(p), 1, 2000)
                        TASK.TASK_LEAVE_ANY_VEHICLE(p, 0, 4160)
                    end

                    TASK.TASK_SMART_FLEE_PED(p, Self.GetPedID(), 1000, -1, false, false)
                end
            end
        end
    end
end)

script.register_looped("SS_KATANA", function(rpq)
    if replace_pool_q then
        if WEAPON.IS_PED_ARMED(Self.GetPedID(), 1) and WEAPON.GET_SELECTED_PED_WEAPON(Self.GetPedID()) == katana_replace_model then
            local currentWeapon = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(Self.GetPedID(), 0)

            if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(currentWeapon, Self.GetPedID()) then
                if not ENTITY.DOES_ENTITY_EXIST(i_Katana) then
                    Await(Game.RequestModel, 0xE2BA016F)
                    i_Katana = OBJECT.CREATE_OBJECT(0xE2BA016F, 0, 0, 0, true, false, true)

                    if ENTITY.DOES_ENTITY_EXIST(i_Katana) then
                        ENTITY.SET_ENTITY_COLLISION(i_Katana, false, false)
                        ENTITY.SET_ENTITY_ALPHA(currentWeapon, 0, false)
                        ENTITY.SET_ENTITY_VISIBLE(currentWeapon, false, false)
                        rpq:sleep(100)
                        ENTITY.ATTACH_ENTITY_TO_ENTITY(
                            i_Katana,
                            currentWeapon,
                            0,
                            0.0,
                            0.0,
                            0.025,
                            0.0,
                            0.0,
                            0.0,
                            false,
                            false,
                            false,
                            false,
                            2,
                            true,
                            0
                        )
                        b_SpawnedKatana = true
                    end
                end
            else
                if b_SpawnedKatana then
                    if ENTITY.DOES_ENTITY_EXIST(i_Katana) then
                        ENTITY.DELETE_ENTITY(i_Katana)
                    end
                    b_SpawnedKatana = false
                    i_Katana = 0
                end
            end
        else
            if b_SpawnedKatana then
                if ENTITY.DOES_ENTITY_EXIST(i_Katana) then
                    ENTITY.DELETE_ENTITY(i_Katana)
                end

                b_SpawnedKatana = false
                i_Katana = 0
            end
        end
    end
end)

script.register_looped("SS_RENDERLASER", function() -- Laser Sight
    if (
        SS.CanUseKeybinds() and
        PLAYER.IS_PLAYER_FREE_AIMING(self.get_id()) and
        pressing_laser_button
    ) then
        laserSight = not laserSight
        AUDIO.PLAY_SOUND_FRONTEND(
            -1,
            "Target_Counter_Tick",
            "DLC_SM_Generic_Mission_Sounds",
            false
        )
        YimToast:ShowMessage(
            "Samurai's Scripts",
            ("Laser Sights %s."):format(laserSight and "enabled" or "disabled"),
            false,
            1.5
        )
        CFG:SaveItem("laserSight", laserSight)
    end

    if (
        laserSight and
        Self.IsOnFoot() and
        WEAPON.IS_PED_ARMED(Self.GetPedID(), 4) and
        PLAYER.IS_PLAYER_FREE_AIMING(self.get_id())
    ) then
        local wpn_idx = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(Self.GetPedID(), 0)
        local wpn_bone = 0

        if (wpn_hash ~= 0x34A67B97)
        and (wpn_hash ~= 0xBA536372)
        and (wpn_hash ~= 0x184140A1)
        and (wpn_hash ~= 0x060EC506) then
            for _, bone in ipairs(eWeaponBones) do
                local boneIndex = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(wpn_idx, bone)
                if boneIndex ~= -1 then
                    wpn_bone = boneIndex
                    break
                end
            end
        end

        local bone_pos = ENTITY.GET_ENTITY_BONE_POSTION(wpn_idx, wpn_bone)
        local camRotation = CAM.GET_GAMEPLAY_CAM_ROT(0)
        local direction = Lua_fn.RotToDir(camRotation)
        local destination = vec3:new(
            bone_pos.x + direction.x * 1000,
            bone_pos.y + direction.y * 1000,
            bone_pos.z + direction.z * 1000
        )

        local hit, endCoords, _ = Game.RayCast(bone_pos, destination, -1, Self.GetPedID())
        DrawLaser(hit, bone_pos, endCoords, destination, laser_choice)
    end
end)

script.register_looped("SS_VEHICLE", function(ssveh)
    b_ShouldDrawSpeedometer = (
        speedometer_cfg.enabled
        and Self.IsDriving()
        and (Self.Vehicle.BodyHealth > 0)
        and not HUD.IS_PAUSE_MENU_ACTIVE()
    )

    if Self.IsDriving() then
        if b_ShouldDrawSpeedometer then
            if speedometer_cfg.speed_unit == 0 then
                i_SpeedometerUnitModifier = 1
            elseif speedometer_cfg.speed_unit == 1 then
                i_SpeedometerUnitModifier = 3.6
            else
                i_SpeedometerUnitModifier = 2.236936
            end
        end

        if Self.Vehicle.IsValidLandVehicle and (driftMode or DriftTires) then
            if pressing_drift_button then
                if not drift_started then
                    if driftMode then
                        VEHICLE.SET_VEHICLE_REDUCE_GRIP(Self.Vehicle.Current, true)
                        VEHICLE.SET_VEHICLE_REDUCE_GRIP_LEVEL(Self.Vehicle.Current, DriftIntensity)
                    elseif DriftTires then
                        VEHICLE.SET_DRIFT_TYRES(Self.Vehicle.Current, true)
                    end
                    drift_started = true
                end
                VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(Self.Vehicle.Current, DriftPowerIncrease)
            else
                if drift_started then
                    VEHICLE.SET_VEHICLE_REDUCE_GRIP(Self.Vehicle.Current, false)
                    VEHICLE.SET_DRIFT_TYRES(Self.Vehicle.Current, false)
                    VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(Self.Vehicle.Current, 1.0)
                    drift_started = false
                end
            end
        end

        if speedBoost and (Self.Vehicle.IsValidLandVehicle or Self.Vehicle.IsBoat) and not Game.Vehicle.IsElectric(Self.Vehicle.Current) then
            if VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(Self.Vehicle.Current) then
                if pressing_nos_button and PAD.IS_CONTROL_PRESSED(0, 71) then
                    VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(Self.Vehicle.Current, (nosPower) / 5)
                    VEHICLE.MODIFY_VEHICLE_TOP_SPEED(Self.Vehicle.Current, nosPower)
                    if nosAudio then
                        AUDIO.SET_VEHICLE_BOOST_ACTIVE(Self.Vehicle.Current, true)
                    end
                    if nosvfx then
                        GRAPHICS.ANIMPOSTFX_PLAY("DragRaceNitrous", 0, false)
                    end
                    using_nos = true
                end
            else
                if PED.IS_PED_SITTING_IN_ANY_VEHICLE(Self.GetPedID()) then
                    if pressing_nos_button and PAD.IS_CONTROL_PRESSED(0, 71) then
                        if VEHICLE.GET_VEHICLE_ENGINE_HEALTH(Self.Vehicle.Current) < 300 then
                            AUDIO.PLAY_SOUND_FROM_ENTITY(-1, "Engine_fail", Self.Vehicle.Current,
                                "DLC_PILOT_ENGINE_FAILURE_SOUNDS", true, 0)
                        end
                    end
                end
            end
            if using_nos and not pressing_nos_button then
                VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(Self.Vehicle.Current, 1.0)
                VEHICLE.MODIFY_VEHICLE_TOP_SPEED(Self.Vehicle.Current, -1)
                AUDIO.SET_VEHICLE_BOOST_ACTIVE(Self.Vehicle.Current, false)
                if nosvfx then
                    GRAPHICS.ANIMPOSTFX_PLAY("DragRaceNitrousOut", 0, false)
                end
                if GRAPHICS.ANIMPOSTFX_IS_RUNNING("DragRaceNitrous") then
                    GRAPHICS.ANIMPOSTFX_STOP("DragRaceNitrous")
                end
                if GRAPHICS.ANIMPOSTFX_IS_RUNNING("DragRaceNitrousOut") then
                    GRAPHICS.ANIMPOSTFX_STOP("DragRaceNitrousOut")
                end
                using_nos = false
            end
        end

        if hornLight and Self.IsDriving() then
            if not VEHICLE.GET_BOTH_VEHICLE_HEADLIGHTS_DAMAGED(Self.Vehicle.Current) then
                if PAD.IS_CONTROL_PRESSED(0, 86) then
                    VEHICLE.SET_VEHICLE_LIGHTS(Self.Vehicle.Current, 2)
                    VEHICLE.SET_VEHICLE_FULLBEAM(Self.Vehicle.Current, true)
                    repeat
                        ssveh:sleep(50)
                    until
                        PAD.IS_CONTROL_PRESSED(0, 86) == false
                    VEHICLE.SET_VEHICLE_FULLBEAM(Self.Vehicle.Current, false)
                    VEHICLE.SET_VEHICLE_LIGHTS(Self.Vehicle.Current, 0)
                end
            end
        end

        if(
            keepWheelsTurned and
            Self.IsDriving() and
            Self.IsOutside() and
            Self.Vehicle.IsCar and not
            holdF and not
            b_IsDuckingInVehicle and not
            b_IsTyping and not
            b_IsSettingHotkeys and
            PAD.IS_DISABLED_CONTROL_PRESSED(0, 75) and
            (PAD.IS_CONTROL_PRESSED(0, 34) or PAD.IS_CONTROL_PRESSED(0, 35)) and not
            HUD.IS_MP_TEXT_CHAT_TYPING()
        ) then
            VEHICLE.SET_VEHICLE_ENGINE_ON(Self.Vehicle.Current, false, true, false)
            TASK.TASK_LEAVE_VEHICLE(Self.GetPedID(), Self.Vehicle.Current, 16)
        end

        if holdF and Self.IsDriving() and Self.IsOutside() then
            if PAD.IS_DISABLED_CONTROL_PRESSED(0, 75) and not HUD.IS_MP_TEXT_CHAT_TYPING() then
                i_TimerB = i_TimerB + 1

                if i_TimerB >= 15 then
                    if (
                        keepWheelsTurned and
                        (PAD.IS_CONTROL_PRESSED(0, 34) or PAD.IS_CONTROL_PRESSED(0, 35)) and
                        Self.Vehicle.IsCar and not
                        b_IsDuckingInVehicle
                    ) then
                        VEHICLE.SET_VEHICLE_ENGINE_ON(Self.Vehicle.Current, false, true, false)
                        TASK.TASK_LEAVE_VEHICLE(Self.GetPedID(), Self.Vehicle.Current, 16)
                        i_TimerB = 0
                    else
                        VEHICLE.SET_VEHICLE_ENGINE_ON(Self.Vehicle.Current, false, false, false)
                        PED.SET_PED_CONFIG_FLAG(Self.GetPedID(), 241, false)
                        TASK.TASK_LEAVE_VEHICLE(Self.GetPedID(), Self.Vehicle.Current, 0)
                        i_TimerB = 0
                    end
                end
            end

            if i_TimerB >= 1 and i_TimerB <= 10 then
                if (
                    PAD.IS_DISABLED_CONTROL_RELEASED(0, 75) and not
                    HUD.IS_MP_TEXT_CHAT_TYPING() and not b_IsTyping and not
                    b_IsSettingHotkeys
                ) then
                    if (
                        keepWheelsTurned and
                        (PAD.IS_CONTROL_PRESSED(0, 34) or PAD.IS_CONTROL_PRESSED(0, 35)) and
                        Self.Vehicle.IsCar and not
                        b_IsDuckingInVehicle
                    ) then
                        TASK.TASK_LEAVE_VEHICLE(Self.GetPedID(), Self.Vehicle.Current, 16)
                        i_TimerB = 0
                    else
                        PED.SET_PED_CONFIG_FLAG(Self.GetPedID(), 241, true)
                        TASK.TASK_LEAVE_VEHICLE(Self.GetPedID(), Self.Vehicle.Current, 0)
                        i_TimerB = 0
                    end
                end
            end
        else
            if PED.GET_PED_CONFIG_FLAG(Self.GetPedID(), 241, true) then
                PED.SET_PED_CONFIG_FLAG(Self.GetPedID(), 241, false)
            end
        end
    else
        if b_LaunchControlReady then
            b_LaunchControlReady = false
        end
    end
end)

script.register_looped("SS_DSPTFX", function() -- Drift Smoke FX
    if Self.IsDriving() and Self.Vehicle.IsCar then
        local fxBones = { "suspension_lr", "suspension_rr" }
        local vmin, vmax = Game.GetModelDimensions(Self.Vehicle:GetModel())
        local height = vmax.z - vmin.z
        local f_BoneZoffset = height / 4

        if not VEHICLE.IS_VEHICLE_STOPPED(Self.Vehicle.Current) then
            if (
                DriftSmoke and
                (driftMode or DriftTires) and
                Self.Vehicle.IsDrifting and
                (Self.Vehicle.Gear > 0) and
                (Self.Vehicle.Speed > 5)
            ) then
                local f_FxScale = Self.Vehicle.Speed / 111

                if not b_HasCustomTires then
                    VEHICLE.TOGGLE_VEHICLE_MOD(Self.Vehicle.Current, 20, true)
                end

                if not i_TireSmokeFX and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(Self.Vehicle.Current) then
                    i_TireSmokeFX = Game.StartSyncedPtfxLoopedOnEntityBone(
                        Self.Vehicle.Current,
                        "scr_ba_bb",
                        "scr_ba_bb_plane_smoke_trail",
                        fxBones,
                        f_FxScale,
                        vec3:new(1.2, 0.0, -f_BoneZoffset),
                        vec3:zero(),
                        Col(driftSmoke_T.r, driftSmoke_T.g, driftSmoke_T.b)
                    )
                end
            elseif i_TireSmokeFX then
                Game.StopParticleEffects(i_TireSmokeFX, "scr_ba_bb")
                i_TireSmokeFX = nil
            end
        else
            if BurnoutSmoke and (Self.Vehicle.RPM >= 0.9) then
                if VEHICLE.IS_VEHICLE_IN_BURNOUT(Self.Vehicle.Current) then
                    if not b_HasCustomTires then
                        VEHICLE.TOGGLE_VEHICLE_MOD(Self.Vehicle.Current, 20, true)
                    end

                    if not i_TireSmokeFX then
                        i_TireSmokeFX = Game.StartSyncedPtfxLoopedOnEntityBone(
                            Self.Vehicle.Current,
                            "scr_ba_bb",
                            "scr_ba_bb_plane_smoke_trail",
                            fxBones,
                            0.4,
                            vec3:new(1.2, 0.0, -f_BoneZoffset),
                            vec3:zero(),
                            Col(driftSmoke_T.r, driftSmoke_T.g, driftSmoke_T.b)
                        )
                    end
                elseif i_TireSmokeFX then
                    Game.StopParticleEffects(i_TireSmokeFX, "scr_ba_bb")
                    i_TireSmokeFX = nil
                end
            end
        end
        if i_TireSmokeFX and #i_TireSmokeFX > 0 then
            for _, fx in ipairs(i_TireSmokeFX) do
                GRAPHICS.SET_PARTICLE_FX_LOOPED_COLOUR(fx, driftSmoke_T.r, driftSmoke_T.g, driftSmoke_T.b, false)
            end
        end
    end
end)

script.register_looped("SS_ABSLIGHTS", function(abs)
    if Self.IsDriving() and Self.Vehicle.IsCar then
        if limitVehOptions and not Game.Vehicle.IsSportsOrSuper(Self.Vehicle.Current) then
            return
        end

        if (
            Game.Vehicle.HasABS(Self.Vehicle.Current) and
            PAD.IS_CONTROL_PRESSED(0, 72) and
            ((Self.Vehicle.Speed * 3.6) > 100)
        ) then
            repeat
                b_ShouldFlashBrakeLights = not b_ShouldFlashBrakeLights
                abs:sleep(100)
            until (Self.Vehicle.Speed * 3.6) < 10 or PAD.IS_CONTROL_RELEASED(0, 72) or
                not VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(Self.Vehicle.Current)
            b_ShouldFlashBrakeLights = false
        end
    end
end)

-- elecronic stability control indicator for the speedometer
script.register_looped("SS_ESC_INDICATOR", function(esc)
    if (
        speedometer_cfg and
        speedometer_cfg.enabled and
        Self.IsDriving() and
        Self.Vehicle.IsCar
    )then
        if limitVehOptions and not Game.Vehicle.IsSportsOrSuper(Self.Vehicle.Current) then
            return
        end

        if (
            Game.Vehicle.HasABS(Self.Vehicle.Current) and
            Self.Vehicle.IsDrifting
        ) then
            repeat
                Self.Vehicle.ShouldFlashESC = not Self.Vehicle.ShouldFlashESC
                esc:sleep(100)
            until
                not Self.Vehicle.IsDrifting or
                not VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(Self.Vehicle.Current)
            Self.Vehicle.ShouldFlashESC = false
        end
    end
end)

script.register_looped("SS_MISC_VEH", function(mvo)
    if Self.IsDriving() then
        if autobrklight then
            if VEHICLE.IS_VEHICLE_DRIVEABLE(Self.Vehicle.Current, false) and VEHICLE.IS_VEHICLE_STOPPED(Self.Vehicle.Current) and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(Self.Vehicle.Current) then
                VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(Self.Vehicle.Current, true)
            end
        end

        if abs_lights and Self.Vehicle.IsCar and Game.Vehicle.HasABS(Self.Vehicle.Current) and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(Self.Vehicle.Current)
            and not VEHICLE.IS_VEHICLE_STOPPED(Self.Vehicle.Current) then
            if b_ShouldFlashBrakeLights then
                VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(Self.Vehicle.Current, false)
            end
        end

        if insta180 then
            local vehRot = ENTITY.GET_ENTITY_ROTATION(Self.Vehicle.Current, 2)
            if PAD.IS_CONTROL_JUST_PRESSED(0, 97) then -- numpad + || mouse scroll down
                if PAD.IS_CONTROL_PRESSED(0, 71) then
                    local vehSpeed = ENTITY.GET_ENTITY_SPEED(Self.Vehicle.Current)
                    ENTITY.SET_ENTITY_ROTATION(Self.Vehicle.Current, vehRot.x, vehRot.y, (vehRot.z - 180), 2, true)
                    VEHICLE.SET_VEHICLE_FORWARD_SPEED(Self.Vehicle.Current, vehSpeed)
                else
                    ENTITY.SET_ENTITY_ROTATION(Self.Vehicle.Current, vehRot.x, vehRot.y, (vehRot.z - 180), 2, true)
                    if VEHICLE.IS_VEHICLE_STOPPED(Self.Vehicle.Current) then
                        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(Self.Vehicle.Current, 5.0)
                    end
                end
            end
        end
    end

    if flappyDoors and Self.Vehicle.Current ~= 0 and not Self.Vehicle.IsBike and not Self.Vehicle.IsBoat then
        local n_doors = VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(Self.Vehicle.Current)
        if n_doors > 0 then
            for i = -1, n_doors + 1 do
                if VEHICLE.GET_IS_DOOR_VALID(Self.Vehicle.Current, i) then
                    mvo:sleep(180)
                    VEHICLE.SET_VEHICLE_DOOR_OPEN(Self.Vehicle.Current, i, false, false)
                    mvo:sleep(180)
                    VEHICLE.SET_VEHICLE_DOOR_SHUT(Self.Vehicle.Current, i, false)
                end
            end
        end
    end

    if loud_radio then
        if Self.Vehicle.Current ~= 0 then
            if not Self.Vehicle.HasLoudRadio then
                AUDIO.SET_VEHICLE_RADIO_LOUD(Self.Vehicle.Current, true)
                Self.Vehicle.HasLoudRadio = true
            end
        else
            if Self.Vehicle.HasLoudRadio then
                Self.Vehicle.HasLoudRadio = false
            end
        end
    end

    if autovehlocks and (Self.Vehicle.Current ~= 0) and Self.Vehicle.IsCar then
        local vehPos   = Game.GetEntityCoords(Self.Vehicle.Current, true)
        local distance = vehPos:distance(Self.GetPos())
        local isLocked = VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(Self.Vehicle.Current) > 1

        if not isLocked and distance > 20 then
            Game.Vehicle.LockDoors(Self.Vehicle.Current, true, mvo)
        end

        if isLocked and PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(Self.GetPedID()) == Self.Vehicle.Current then
            Game.Vehicle.LockDoors(Self.Vehicle.Current, false, mvo)
        end
        Self.Vehicle.DoorLockState = isLocked and 2 or 1
    end

    if fast_vehicles and (Self.Vehicle.Current ~= 0) and (Self.Vehicle.IsCar or Self.Vehicle.IsBike or Self.Vehicle.IsQuad) then
        if Self.Vehicle.MaxSpeed <= 50 then
            VEHICLE.MODIFY_VEHICLE_TOP_SPEED(Self.Vehicle.Current, 100)
        end
    end
end)

-- script.register_looped("SS_VEHALARM", function(amgr)
--     if Self.Vehicle.DoorLockState == 2 and VEHICLE.IS_VEHICLE_ALARM_ACTIVATED(Self.Vehicle.Current) then
--         repeat
--             amgr:sleep(100)
--         until not VEHICLE.IS_VEHICLE_ALARM_ACTIVATED(Self.Vehicle.Current)
--         VEHICLE.SET_VEHICLE_ALARM(Self.Vehicle.Current, Self.Vehicle.DoorLockState == 2)
--     end
-- end)

script.register_looped("SS_VEHICLEFX", function()
    if (
        nosFlames and
        speedBoost and
        Self.IsDriving() and
        (Self.Vehicle.IsValidLandVehicle or Self.Vehicle.IsBoat) and
        pressing_nos_button and
        PAD.IS_CONTROL_PRESSED(0, 71) and
        VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(Self.Vehicle.Current)
    ) then
        if not i_NosFX then
            local bones = Game.Vehicle.GetVehicleExhaustBones(Self.Vehicle.Current)
            i_NosFX = Game.StartSyncedPtfxLoopedOnEntityBone(
                Self.Vehicle.Current,
                "veh_xs_vehicle_mods",
                "veh_nitrous",
                bones,
                1.0,
                vec3:zero(),
                vec3:zero()
            )
        end
    elseif i_NosFX then
        Game.StopParticleEffects(i_NosFX, "veh_xs_vehicle_mods")
        i_NosFX = nil
    end

    if (
        Self.IsDriving() and
        nosPurge and
        pressing_purge_button and
        (Self.Vehicle.IsCar or Self.Vehicle.IsQuad or Self.Vehicle.IsBike) and not
        Self.Vehicle.IsFlatbed
    ) then
        if not i_PurgeFX_l then
            i_PurgeFX_l = Game.StartSyncedPtfxLoopedOnEntityBone(
                Self.Vehicle.Current,
                "core",
                "weap_extinguisher",
                "suspension_lf",
                0.4,
                vec3:new(-0.3, -0.33, 0.2),
                vec3:new(0.0, -17.5, -180.0)
            )
        end

        if not i_PurgeFX_r then
            i_PurgeFX_r = Game.StartSyncedPtfxLoopedOnEntityBone(
                Self.Vehicle.Current,
                "core",
                "weap_extinguisher",
                "suspension_rf",
                0.4,
                vec3:new(0.3, -0.33, 0.2),
                vec3:new(0.0, -17.5, 0.0)
            )
        end
    else
        if i_PurgeFX_l then
            Game.StopParticleEffects(i_PurgeFX_l)
            i_PurgeFX_l = nil
        end

        if i_PurgeFX_r then
            Game.StopParticleEffects(i_PurgeFX_r)
            i_PurgeFX_r = nil
        end
    end
end)

script.register_looped("SS_LCTRL", function(lct) -- Launch Control
    if launchCtrl and Self.IsDriving() and Self.Vehicle.IsValidLandVehicle then
        if limitVehOptions and not Game.Vehicle.IsSportsOrSuper(Self.Vehicle.Current) then
            return
        end

        local notif_sound, notif_ref

        if Game.IsOnline() then
            notif_sound, notif_ref = "SELL", "GTAO_EXEC_SECUROSERV_COMPUTER_SOUNDS"
        else
            notif_sound, notif_ref = "MP_5_SECOND_TIMER", "HUD_FRONTEND_DEFAULT_SOUNDSET"
        end

        if (
            VEHICLE.IS_VEHICLE_STOPPED(Self.Vehicle.Current) and
            VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(Self.Vehicle.Current) and
            VEHICLE.GET_VEHICLE_ENGINE_HEALTH(Self.Vehicle.Current) > 300
        ) then
            if PAD.IS_CONTROL_PRESSED(0, 71) and PAD.IS_CONTROL_PRESSED(0, 72) and not pressing_drift_button then
                local fgCol = Col(255, 255, 255, 255)

                b_LaunchControlReady = true
                ENTITY.FREEZE_ENTITY_POSITION(Self.Vehicle.Current, true)

                if i_TimerA < 1 then
                    i_TimerA = i_TimerA + 0.005
                end

                if i_TimerA >= 1 then
                    fgCol = Col(111, 194, 118, 255)
                end

                Game.DrawText(
                    vec2:new(0.42, 0.936),
                    "Launch Control",
                    fgCol,
                    vec2:new(0, 0.35),
                    2
                )

                Game.DrawBar(
                    vec2:new(0.53, 0.95),
                    0.1,
                    0.01,
                    fgCol,
                    Col(0, 0, 0, 150),
                    i_TimerA
                )

                if i_TimerA >= 1 then
                    if not b_LaunchControlActive then
                        YimToast:ShowSuccess("Samurais Scripts", "Launch Control Ready!")
                        AUDIO.PLAY_SOUND_FRONTEND(-1, notif_sound, notif_ref, true)
                    end
                    b_LaunchControlActive = true
                end
            elseif b_LaunchControlReady and i_TimerA > 0 and i_TimerA < 1 then
                if PAD.IS_CONTROL_RELEASED(0, 71) or PAD.IS_CONTROL_RELEASED(0, 72) then
                    fgCol = Col(255, 255, 255, 255)
                    i_TimerA = 0
                    ENTITY.FREEZE_ENTITY_POSITION(Self.Vehicle.Current, false)
                    b_LaunchControlReady = false
                    b_LaunchControlActive = false
                end
            end
        end

        if b_LaunchControlActive then
            if PAD.IS_CONTROL_PRESSED(0, 71) and PAD.IS_CONTROL_RELEASED(0, 72) then
                PHYSICS.SET_IN_ARENA_MODE(true)
                VEHICLE.SET_VEHICLE_MAX_LAUNCH_ENGINE_REVS_(Self.Vehicle.Current, -1)
                VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(Self.Vehicle.Current, 10)
                VEHICLE.MODIFY_VEHICLE_TOP_SPEED(Self.Vehicle.Current, 100.0)
                ENTITY.FREEZE_ENTITY_POSITION(Self.Vehicle.Current, false)
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(Self.Vehicle.Current, 9.3)
                lct:sleep(4269)
                VEHICLE.MODIFY_VEHICLE_TOP_SPEED(Self.Vehicle.Current, -1)
                VEHICLE.SET_VEHICLE_CHEAT_POWER_INCREASE(Self.Vehicle.Current, 1.0)
                VEHICLE.SET_VEHICLE_MAX_LAUNCH_ENGINE_REVS_(Self.Vehicle.Current, 1.0)
                PHYSICS.SET_IN_ARENA_MODE(false)
                b_LaunchControlActive = false
                i_TimerA = 0
            end
        end
    end
end)

script.register_looped("SS_TWOSTEP", function(twostep)
    if (
        launchCtrl and
        Self.IsDriving() and
        (Self.Vehicle.IsValidLandVehicle or Self.Vehicle.IsBike or Self.Vehicle.IsQuad) and not
        Game.Vehicle.IsElectric(Self.Vehicle.Current)
    ) then
        if limitVehOptions and not Game.Vehicle.IsSportsOrSuper(Self.Vehicle.Current) then
            return
        end

        if (VEHICLE.IS_VEHICLE_STOPPED(Self.Vehicle.Current) and
            VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(Self.Vehicle.Current) and
            VEHICLE.GET_VEHICLE_ENGINE_HEALTH(Self.Vehicle.Current) >= 300 and
            (PAD.IS_CONTROL_PRESSED(0, 71) and PAD.IS_CONTROL_PRESSED(0, 72)) and not
            pressing_drift_button
        ) then
            local bones = Game.Vehicle.GetVehicleExhaustBones(Self.Vehicle.Current)
            Game.StartSyncedPtfxNonLoopedOnEntityBone(
                Self.Vehicle.Current,
                "core",
                "veh_backfire",
                bones,
                vec3:zero(),
                vec3:zero(),
                0.69420
            )
            Game.Audio.PlayExhaustPop(Self.Vehicle.Current)
            twostep:sleep(math.random(60, 120))
        end
    end
end)


script.register_looped("SS_PNB", function(pnp) -- Pops & Bangs
    if (
        Self.IsDriving() and not
        Game.Vehicle.IsElectric(Self.Vehicle.Current) and
        (Self.Vehicle.IsCar or Self.Vehicle.IsBike) and
        VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(Self.Vehicle.Current)
    ) then
        if popsNbangs then
            if limitVehOptions and not Game.Vehicle.IsSportsOrSuper(Self.Vehicle.Current) then
                return
            end

            AUDIO.ENABLE_VEHICLE_EXHAUST_POPS(Self.Vehicle.Current, false)
            b_DefaultPopsDisabled = true

            if VEHICLE.IS_VEHICLE_STOPPED(Self.Vehicle.Current) then
                rpmThreshold = 0.45
            elseif noEngineBraking then
                rpmThreshold = 0.80
            else
                rpmThreshold = 0.69
            end

            if (
                PAD.IS_CONTROL_RELEASED(0, 71) and
                (Self.Vehicle.RPM < 1.0) and
                (Self.Vehicle.RPM > rpmThreshold) and
                (Self.Vehicle.Gear ~= 0)
            ) then
                local bones = Game.Vehicle.GetVehicleExhaustBones(Self.Vehicle.Current)
                local myPos = self.get_pos()

                Game.StartSyncedPtfxNonLoopedOnEntityBone(
                    Self.Vehicle.Current,
                    "core",
                    "veh_backfire",
                    bones,
                    vec3:zero(),
                    vec3:zero(),
                    louderPops and 1.5 or 0.42069
                )

                Game.Audio.PlayExhaustPop(Self.Vehicle.Current, louderPops)

                if not i_ExhaustShockingEvent and not EVENT.IS_SHOCKING_EVENT_IN_SPHERE(79, myPos.x, myPos.y, myPos.z, 50) then
                    i_ExhaustShockingEvent = EVENT.ADD_SHOCKING_EVENT_FOR_ENTITY(79, Self.Vehicle.Current, 10)
                end
                pnp:sleep(math.random(69, 200))
            else
                if i_ExhaustShockingEvent then
                    EVENT.REMOVE_SHOCKING_EVENT(i_ExhaustShockingEvent)
                    i_ExhaustShockingEvent = nil
                end
            end
        else
            if b_DefaultPopsDisabled then
                AUDIO.ENABLE_VEHICLE_EXHAUST_POPS(Self.Vehicle.Current, true)
                b_DefaultPopsDisabled = false
            end
        end
    end
end)

-- drift minigame
script.register_looped("SS_DRIFT_MINIGAME_MAIN", function()
    if driftMinigame and Self.Vehicle.IsCar then
        DriftMinigame:Update()
    end
end)

script.register_looped("SS_DRIFT_MINIGAME_UI", function()
    if driftMinigame then
        DriftMinigame:Draw()
    end
end)

script.register_looped("SS_VEHMINES", function(vmns) -- Vehicle Mines
    if veh_mines and Self.IsDriving() and Self.Vehicle.IsValidLandVehicle then
        local s_BoneName = "chassis_dummy"
        local i_MineHash

        if vmine_type.spikes then
            i_MineHash = -647126932
        elseif vmine_type.slick then
            i_MineHash = 1459276487
        elseif vmine_type.explosive then
            i_MineHash = 1508567460
        elseif vmine_type.emp then
            i_MineHash = 1776356704
        elseif vmine_type.kinetic then
            i_MineHash = 1007245390
        else
            i_MineHash = -647126932 -- default to spikes if nothing else was selected.
        end

        local bone_idx = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(self.get_veh(), s_BoneName)

        if pressing_vmine_button then
            Await(Game.RequestWeaponAsset, i_MineHash)
            if bone_idx ~= -1 then
                local bone_pos    = ENTITY.GET_ENTITY_BONE_POSTION(self.get_veh(), bone_idx)
                local veh_pos     = ENTITY.GET_ENTITY_COORDS(self.get_veh(), true)
                local veh_fwd     = ENTITY.GET_ENTITY_FORWARD_VECTOR(self.get_veh())
                local veh_hash    = ENTITY.GET_ENTITY_MODEL(self.get_veh())
                local vmin, vmax  = Game.GetModelDimensions(veh_hash)
                local veh_len     = vmax.y - vmin.y
                local _, ground_z = MISC.GET_GROUND_Z_FOR_3D_COORD(
                    veh_pos.x,
                    veh_pos.y,
                    veh_pos.z,
                    groundZ,
                    false,
                    false
                )

                local x_offset = veh_fwd.x * (veh_len / 1.6)
                local y_offset = veh_fwd.y * (veh_len / 1.6)

                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
                    bone_pos.x - x_offset, bone_pos.y - y_offset, bone_pos.z,
                    bone_pos.x - x_offset, bone_pos.y - y_offset, ground_z,
                    0.0, false, i_MineHash, Self.GetPedID(), true, false, 0.01
                )
            end
            vmns:sleep(969)
        end
    end
end)

script.register_looped("SS_MISSILEDEFENCE", function() -- Missile defence
    if missiledefense and Self.Vehicle.Current ~= 0 then
        local missile
        local vehPos  = ENTITY.GET_ENTITY_COORDS(Self.Vehicle.Current, true)
        local selfPos = self.get_pos()

        for _, p in pairs(eProjectileTypes) do
            if MISC.IS_PROJECTILE_TYPE_IN_AREA(
                vehPos.x + 500,
                vehPos.y + 500,
                vehPos.z + 100,
                vehPos.x - 500,
                vehPos.y - 500,
                vehPos.z - 100,
                p,
                false
            ) then
                missile = p
                break
            end
        end

        if (missile and missile ~= 0) then
            --[[
            if MISC.IS_PROJECTILE_TYPE_IN_AREA(vehPos.x + 100, vehPos.y + 100, vehPos.z + 100, vehPos.x - 100, vehPos.y - 100, vehPos.z - 100, missile, false) then
                if Self.isDriving() and (Self.Vehicle.IsPlane or Self.Vehicle.IsHeli) then
                shoot_flares(md)
                end
            end
            ^ auto-counters missiles with flares but it's too easy in dogfights.
        ]]
            if MISC.IS_PROJECTILE_TYPE_IN_AREA(vehPos.x + 20, vehPos.y + 20, vehPos.z + 100, vehPos.x - 20, vehPos.y - 20, vehPos.z - 100, missile, false) then
                if not MISC.IS_PROJECTILE_TYPE_IN_AREA(vehPos.x + 10, vehPos.y + 10, vehPos.z + 50, vehPos.x - 10, vehPos.y - 10, vehPos.z - 50, missile, false) and not MISC.IS_PROJECTILE_TYPE_IN_AREA(selfPos.x + 10, selfPos.y + 10, selfPos.z + 50, selfPos.x - 10, selfPos.y - 10, selfPos.z - 50, missile, false) then
                    if not disable_mdef_logs then
                        log.info('Detected projectile within our defence area! Proceeding to destroy it.')
                    end
                    WEAPON.REMOVE_ALL_PROJECTILES_OF_TYPE(missile, true)
                    Await(Game.RequestNamedPtfxAsset, "scr_sm_counter")
                    GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                    GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
                        "scr_sm_counter_chaff",
                        vehPos.x,
                        vehPos.y,
                        (vehPos.z + 2.5),
                        0.0,
                        0.0,
                        0.0,
                        5.0,
                        false,
                        false,
                        false,
                        false
                    )
                else
                    if not disable_mdef_logs then
                        log.warning('Found a projectile very close to our vehicle! Proceeding to remove it.')
                    end

                    WEAPON.REMOVE_ALL_PROJECTILES_OF_TYPE(missile, false)
                    Await(Game.RequestNamedPtfxAsset, "scr_sm_counter")
                    GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                    GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(
                        "scr_sm_counter_chaff",
                        vehPos.x,
                        vehPos.y,
                        (vehPos.z + 2.5),
                        0.0,
                        0.0,
                        0.0,
                        5.0,
                        false,
                        false,
                        false,
                        false
                    )
                end
            end
        end
    end
end)

local rgbIndex   = 0
local brightness = 1.0
local direction  = -0.1

script.register_looped("SS_RGBLIGHTS", function(rgb)
    if b_StartRGBLoop and (self.get_veh() ~= 0) then
        if not b_HasXenonLights then
            VEHICLE.TOGGLE_VEHICLE_MOD(Self.Vehicle.Current, 22, true)
        end

        VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(Self.Vehicle.Current, rgbIndex)
        VEHICLE.SET_VEHICLE_LIGHT_MULTIPLIER(Self.Vehicle.Current, brightness)

        brightness = brightness + direction

        if brightness <= 0.1 or brightness >= 1.0 then
            rgbIndex = (rgbIndex + 1) % 13
            direction = -direction
        end

        rgb:sleep(100 / lightSpeed)
    end
end)

script.register_looped("SS_CARCRASH", function(bcc) -- Better Car Crashes
    if fender_bender
    and Self.IsDriving()
    and Self.Vehicle.IsValidLandVehicle
    and not VEHICLE.IS_VEHICLE_STUCK_ON_ROOF(Self.Vehicle.Current)
    and Game.Vehicle.HasCrashed() then
        if not Self.Vehicle.DeformMult and (Self.Vehicle.Previous == Self.Vehicle.Current) then
            Self.Vehicle.DeformMult = Game.Vehicle.GetDeformation(Self.Vehicle.Current)
            Sleep(100)
            Game.Vehicle.SetDeformation(Self.Vehicle.Current, 2.69420)
        end

        CAM.SHAKE_GAMEPLAY_CAM(
            "GRENADE_EXPLOSION_SHAKE",
            Self.Vehicle.Speed / 30
        )

        if Self.Vehicle.Speed >= SS.CrashLevels.major.threshold then
            local f_InitialSpeed = Self.Vehicle.Speed
            bcc:sleep(100)
            local f_CurrentSpeed = Self.Vehicle.Speed

            if f_CurrentSpeed <= (f_InitialSpeed * 0.8) and f_CurrentSpeed > (f_InitialSpeed / 5) then
                SS.HandleVehicleCrash("major", Self.Vehicle.Current)
            elseif f_CurrentSpeed <= (f_InitialSpeed / 5) then
                SS.HandleVehicleCrash("fatal", Self.Vehicle.Current)
                if Game.IsOnline() then
                    local v_PlayerPos = Self.GetPos()
                    local s_SoundName = (
                        (Self.GetPedModel() == 0x705E61F2) and
                        "WAVELOAD_PAIN_MALE" or
                        "WAVELOAD_PAIN_FEMALE"
                    )

                    AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(
                        "SCREAM_PANIC_SHORT",
                        s_SoundName,
                        v_PlayerPos.x,
                        v_PlayerPos.y,
                        v_PlayerPos.z,
                        "SPEECH_PARAMS_FORCE_SHOUTED"
                    )
                end
            end
        elseif Self.Vehicle.Speed >= SS.CrashLevels.minor.threshold then
            SS.HandleVehicleCrash("minor", Self.Vehicle.Current)
        end
        bcc:sleep(1000)
    end
end)

-- Planes & Helis

script.register_looped("SS_FLARES", function()
    if (
        flares_forall
        and Self.IsDriving()
        and (Self.Vehicle.IsPlane or Self.Vehicle.IsHeli)
        and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(Self.Vehicle.Current)
    ) then
        if PAD.IS_CONTROL_PRESSED(0, 356) then
            FlareCountermeasures:Deploy()
        end
    end

    FlareCountermeasures:Update()
end)

script.register_looped("SS_MISC_PLANES", function()
    if (
        real_plane_speed and
        Self.IsDriving() and
        Self.Vehicle.IsPlane and
        (VEHICLE.GET_VEHICLE_FLIGHT_NOZZLE_POSITION(Self.Vehicle.Current) ~= 1.0)
    ) then

        local f_SpeedIncrement = 0.21
        local v_PlaneRotation = ENTITY.GET_ENTITY_ROTATION(Self.Vehicle.Current, 2)

        if v_PlaneRotation.x >= 30 then
            f_SpeedIncrement = 0.4
        elseif v_PlaneRotation.x >= 60 then
            f_SpeedIncrement = 0.8
        end

        if Self.Vehicle.Speed >= 73 and Self.Vehicle.Speed < 160 then
            if PAD.IS_CONTROL_PRESSED(0, 87) and Self.Vehicle.LandingGearState == 4 then
                VEHICLE.SET_VEHICLE_FORWARD_SPEED(Self.Vehicle.Current, (Self.Vehicle.Speed + f_SpeedIncrement))
            end
        end
    end

    if no_stall and Self.IsDriving() and Self.Vehicle.IsPlane then
        if VEHICLE.IS_VEHICLE_DRIVEABLE(Self.Vehicle.Current, true) and VEHICLE.GET_VEHICLE_ENGINE_HEALTH(Self.Vehicle.Current) > 350
            and Self.GetElevation() > 5.0 and not VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(Self.Vehicle.Current) then
            VEHICLE.SET_VEHICLE_ENGINE_ON(Self.Vehicle.Current, true, true, false)
        end
    end

    if (
        Self.IsDriving() and
        (Self.Vehicle.IsPlane or Self.Vehicle.IsHeli) and
        Game.Vehicle.IsWeaponized(self.get_veh()) and (ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Current) ~= 0x96E24857)
    ) then
        local armed, _ = Self.IsUsingAirctaftMG()

        if not armed then
            if ENTITY.GET_ENTITY_ALPHA(Self.Vehicle.Current) < 255 then
                ENTITY.RESET_ENTITY_ALPHA(Self.Vehicle.Current)
            end
            return
        end
        local v_PlayerPos = Self.GetPos()

        if cannon_triggerbot then
            local v_Rot = ENTITY.GET_ENTITY_ROTATION(Self.Vehicle.Current, 2)
            local v_Dir = Lua_fn.RotToDir(v_Rot)
            local v_Dest = v_PlayerPos + v_Dir * cannon_triggerbot_range
            local hit, endCoords, _ = Game.RayCast(v_PlayerPos, v_Dest, -1, Self.Vehicle.Current)

            if hit then
                local ped, veh = Game.GetClosestPed(endCoords, 50, true),
                    Game.GetClosestVehicle(endCoords, 50, self.get_veh())
                if ped ~= 0 then
                    ShootCannon(cannon_enemies_only, ped, ENTITY.GET_ENTITY_COORDS(ped, true))
                end
                if veh ~= 0 then
                    ShootCannon(cannon_enemies_only, veh, ENTITY.GET_ENTITY_COORDS(veh, true))
                end
            end
        end

        if cannon_manual_aim then
            local v_Rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
            local v_Dir = Lua_fn.RotToDir(v_Rot)
            local v_Dest = v_PlayerPos + v_Dir * 200
            local b_Hit, v_EndCoords, _ = Game.RayCast(v_PlayerPos, v_Dest, -1, Self.Vehicle.Current)
            local endPos = b_Hit and v_EndCoords or v_PlayerPos + v_Dir * 1000
            local markerDest = b_Hit and v_EndCoords or vec3:new(
                v_PlayerPos.x + v_Dir.x * 50,
                v_PlayerPos.y + v_Dir.y * 50,
                (v_PlayerPos.z + v_Dir.z * 50) + 1
            )
            local r, g, b, a = Col(cannon_marker_color):AsRGBA()
            local i_MarkerSize = cannon_marker_size

            GRAPHICS.DRAW_MARKER_EX(
                3,
                markerDest.x,
                markerDest.y,
                markerDest.z,
                0,
                0,
                0,
                0,
                0,
                0,
                i_MarkerSize,
                i_MarkerSize,
                i_MarkerSize,
                r,
                g,
                b,
                a or 255,
                ---@diagnostic disable-next-line: param-type-mismatch
                false, true, 1, false, nil, nil, true, true, false
            )

            if Self.Vehicle.IsHeli then
                local camHeading = CAM.GET_GAMEPLAY_CAM_RELATIVE_HEADING()

                if camHeading > 15 or camHeading < -15 then
                    if ENTITY.GET_ENTITY_ALPHA(Self.Vehicle.Current) > 150 then
                        ENTITY.SET_ENTITY_ALPHA(Self.Vehicle.Current, 150, false)
                    end
                else
                    if ENTITY.GET_ENTITY_ALPHA(Self.Vehicle.Current) < 255 then
                        ENTITY.RESET_ENTITY_ALPHA(Self.Vehicle.Current)
                    end
                end
            end

            if PAD.IS_CONTROL_PRESSED(0, 70) then
                ShootExplosiveMG(v_PlayerPos, endPos, 1000, Self.GetPedID(), 300.0)
            end

            if cannon_triggerbot and b_Hit then
                local ped, veh = Game.GetClosestPed(v_EndCoords, 50, true),
                    Game.GetClosestVehicle(v_EndCoords, 50, self.get_veh())

                if not cannon_enemies_only then
                    if (ped ~= 0) or (veh ~= 0) then
                        local target = (ped ~= 0) and ped or veh

                        ShootCannon(false, target, ENTITY.GET_ENTITY_COORDS(target, true)) -- just for the MG sound
                        ShootExplosiveMG(v_PlayerPos, endPos, 1000, Self.GetPedID(), 300.0)
                    end
                else
                    if (ped ~= 0) and not ENTITY.IS_ENTITY_DEAD(ped, false) and Self.IsPedMyEnemy(ped) then
                        ShootCannon(false, ped, ENTITY.GET_ENTITY_COORDS(ped, true))
                        ShootExplosiveMG(v_PlayerPos, ENTITY.GET_ENTITY_COORDS(ped, true), 1000, Self.GetPedID(), 300.0)
                    end

                    if (veh ~= 0) and not ENTITY.IS_ENTITY_DEAD(veh, false) and Game.Vehicle.IsEnemyVehicle(veh) then
                        ShootCannon(false, veh, ENTITY.GET_ENTITY_COORDS(veh, true))
                        ShootExplosiveMG(v_PlayerPos, ENTITY.GET_ENTITY_COORDS(veh, true), 1000, Self.GetPedID(), 300.0)
                    end
                end
            end
        end
    else
        if ENTITY.GET_ENTITY_ALPHA(Self.Vehicle.Current) < 255 then
            ENTITY.RESET_ENTITY_ALPHA(Self.Vehicle.Current)
        end
    end
end)

script.register_looped("SS_AUTOPILOT_INTERRUPT", function(apki) -- Auto Pilot Keyboard Interrupt
    if (b_AutopilotWaypoint or b_AutopilotObjective or b_AutopilotRandom) then
        if (
            not Self.IsDriving() or
            not Self.Vehicle.IsHeli or
            not Self.Vehicle.IsPlane or
            not Self.IsAlive() or
            Self.IsSwitchingPlayers() or
            script.is_active("maintransition")
        ) then
            TASK.CLEAR_PED_TASKS(Self.GetPedID())
            TASK.CLEAR_PRIMARY_VEHICLE_TASK(Self.Vehicle.Current)
            b_AutopilotWaypoint  = false
            b_AutopilotObjective = false
            b_AutopilotRandom    = false
            apki:sleep(50)
        end

        for _, ctrl in pairs(eFlightControls) do
            if PAD.IS_CONTROL_PRESSED(0, ctrl) then
                TASK.CLEAR_PED_TASKS(Self.GetPedID())
                TASK.CLEAR_PRIMARY_VEHICLE_TASK(Self.Vehicle.Current)
                YimToast:ShowMessage(
                    "Samurai's Scripts",
                    "Autopilot interrupted! Giving back control to the player.",
                    false,
                    2
                )

                b_AutopilotWaypoint  = false
                b_AutopilotObjective = false
                b_AutopilotRandom    = false
                break
            end
        end
    end
end)

-- World
script.register_looped("SS_PEDGRABBER", function(pg)
    if b_PedGrabber
    and Self.IsOnFoot()
    and not b_VehicleGrabber
    and not HUD.IS_MP_TEXT_CHAT_TYPING()
    and not YimActions:IsPedPlaying(self.get_ped())
    and not b_IsCrouched
    and not b_IsHandsUp
    and not HNS.isHiding
    and not gui.is_open()
    and not WEAPON.IS_PED_ARMED(Self.GetPedID(), 7) then
        local nearestPed = Game.GetClosestPed(Self.GetPedID(), 10, true)
        local myGroup = Self.GetGroupIndex()

        if not b_PedGrabbed
        and (nearestPed ~= 0) 
        and PED.IS_PED_ON_FOOT(nearestPed)
        and not PED.IS_PED_A_PLAYER(nearestPed)
        and not PED.IS_PED_GROUP_MEMBER(nearestPed, myGroup)
        and (PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 257))
        and not Self.IsBrowsingApps() then
            b_PedGrabbed, i_GrabbedPed = AttachPed(nearestPed)
            pg:sleep(200)

            if i_GrabbedPed ~= 0 then
                PlayHandsUp()
                ENTITY.FREEZE_ENTITY_POSITION(i_GrabbedPed, true)
                PED.SET_PED_CAN_SWITCH_WEAPON(Self.GetPedID(), false)
                b_PedGrabbed = true
            end
        end
    end

    if b_PedGrabbed and (i_GrabbedPed ~= 0) then
        PED.FORCE_PED_MOTION_STATE(i_GrabbedPed, 0x0EC17E58, false, 0, false)

        if not ENTITY.IS_ENTITY_PLAYING_ANIM(
            Self.GetPedID(),
            "mp_missheist_countrybank@lift_hands",
            "lift_hands_in_air_outro", 3
        ) then
            PlayHandsUp()
        end

        if PED.IS_PED_USING_ACTION_MODE(Self.GetPedID()) then
            repeat
                pg:sleep(100)
            until not PED.IS_PED_USING_ACTION_MODE(Self.GetPedID())
            PlayHandsUp()
        end

        if PED.IS_PED_RAGDOLL(Self.GetPedID()) or Self.IsSwimming() or not Self.IsAlive() then
            ENTITY.FREEZE_ENTITY_POSITION(i_GrabbedPed, false)
            ENTITY.DETACH_ENTITY(i_GrabbedPed, true, true)
            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_GrabbedPed, false)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_GrabbedPed, false)
            PED.SET_PED_TO_RAGDOLL(i_GrabbedPed, 1500, 0, 0, false, false, false)
            TASK.CLEAR_PED_TASKS(Self.GetPedID())
            PED.SET_PED_CAN_SWITCH_WEAPON(Self.GetPedID(), true)
            i_GrabbedPed = 0
            b_PedGrabbed = false
        end

        if PAD.IS_DISABLED_CONTROL_PRESSED(0, 25)
        and (PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 257)) then
            local myFwdX = Game.GetForwardX(Self.GetPedID())
            local myFwdY = Game.GetForwardY(Self.GetPedID())

            ENTITY.FREEZE_ENTITY_POSITION(i_GrabbedPed, false)
            ENTITY.DETACH_ENTITY(i_GrabbedPed, true, true)
            TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_GrabbedPed, false)
            PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_GrabbedPed, false)
            PED.SET_PED_TO_RAGDOLL(i_GrabbedPed, 1500, 0, 0, false, false, false)
            ENTITY.SET_ENTITY_VELOCITY(i_GrabbedPed, (i_PedThrowForce * myFwdX), (i_PedThrowForce * myFwdY), 0)
            TASK.CLEAR_PED_TASKS(Self.GetPedID())
            PED.SET_PED_CAN_SWITCH_WEAPON(Self.GetPedID(), true)
            pg:sleep(200)
            i_GrabbedPed = 0
            b_PedGrabbed = false
        end
    end
end)

script.register_looped("SS_VEHICLEGRABBER", function(vg)
    if b_VehicleGrabber
    and Self.IsOnFoot()
    and not b_PedGrabber
    and not HUD.IS_MP_TEXT_CHAT_TYPING()
    and not YimActions:IsPedPlaying(self.get_ped())
    and not gui.is_open()
    and not WEAPON.IS_PED_ARMED(Self.GetPedID(), 7) then
        local nearestVeh = Game.GetClosestVehicle(Self.GetPedID(), 10)

        if not b_VehicleGrabbed
        and (nearestVeh ~= 0)
        and (PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 257))
        and not Self.IsBrowsingApps() then
            b_VehicleGrabbed, i_GrabbedVeh = AttachVeh(nearestVeh)
            vg:sleep(200)

            if i_GrabbedVeh ~= 0 then
                PlayHandsUp()
                PED.SET_PED_CAN_SWITCH_WEAPON(Self.GetPedID(), false)
                b_VehicleGrabbed = true
            end
        end
    end

    if b_VehicleGrabbed and (i_GrabbedVeh ~= 0) then
        if not ENTITY.IS_ENTITY_PLAYING_ANIM(
            Self.GetPedID(),
            "mp_missheist_countrybank@lift_hands",
            "lift_hands_in_air_outro",
            3
        ) then
            PlayHandsUp()
        end

        if PED.IS_PED_USING_ACTION_MODE(Self.GetPedID()) then
            repeat
                vg:sleep(100)
            until not PED.IS_PED_USING_ACTION_MODE(Self.GetPedID())
            PlayHandsUp()
        end

        if PED.IS_PED_RAGDOLL(Self.GetPedID()) or Self.IsSwimming() or not Self.IsAlive() then
            ENTITY.DETACH_ENTITY(i_GrabbedVeh, true, true)
            TASK.CLEAR_PED_TASKS(Self.GetPedID())
            PED.SET_PED_CAN_SWITCH_WEAPON(Self.GetPedID(), true)
            i_GrabbedVeh = 0
            b_VehicleGrabbed = false
        end

        if PAD.IS_DISABLED_CONTROL_PRESSED(0, 25)
        and (PAD.IS_DISABLED_CONTROL_PRESSED(0, 24) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 257)) then
            local myFwdX = Game.GetForwardX(Self.GetPedID())
            local myFwdY = Game.GetForwardY(Self.GetPedID())

            ENTITY.DETACH_ENTITY(i_GrabbedVeh, true, true)
            ENTITY.SET_ENTITY_VELOCITY(
                i_GrabbedVeh,
                (i_PedThrowForce * myFwdX),
                (i_PedThrowForce * myFwdY),
                0
            )
            TASK.CLEAR_PED_TASKS(Self.GetPedID())
            PED.SET_PED_CAN_SWITCH_WEAPON(Self.GetPedID(), true)
            vg:sleep(200)
            i_GrabbedVeh = 0
            b_VehicleGrabbed = false
        end
    end
end)

script.register_looped("SS_AMBSCN", function(ambscn) -- Ambient Scenarios
    if ambient_scenarios and Self.IsOutside() and Self.IsOnFoot() then
        if not b_IsPlayingAmbientScenario then
            local myPos = self.get_pos()
            local amb_scenario_exists, amb_scenario_name = Game.DoesHumanScenarioExistInArea(myPos, 2, true)
            local force_start = PAD.IS_CONTROL_PRESSED(0, 21)

            if amb_scenario_exists
            and not PublicSeating.isSitting
            and not b_IsPlayingAmbientScenario
            and not b_PedGrabbed
            and not b_VehicleGrabbed
            and not b_IsCrouched
            and not script.is_active("CELLPHONE_FLASHHAND") then
                Disable_E()

                if ambient_scenario_prompt then
                    Game.ShowButtonPrompt(
                        string.format(
                            "Press ~INPUT_PICKUP~ to play the nearest scenario (%s).",
                            amb_scenario_name
                        )
                    )
                end

                local UseNearestScenarioCall = force_start
                and TASK.TASK_USE_NEAREST_SCENARIO_TO_COORD_WARP
                or TASK.TASK_USE_NEAREST_SCENARIO_TO_COORD

                if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 38) then
                    YimActions:ResetPlayer()

                    if not PED.GET_PED_CONFIG_FLAG(Self.GetPedID(), 414, true) then
                        PED.SET_PED_CONFIG_FLAG(Self.GetPedID(), 414, true)
                    end

                    UseNearestScenarioCall(Self.GetPedID(), myPos.x, myPos.y, myPos.z, 2, -1)
                    ambscn:sleep(1500)

                    if not force_start then
                        YimToast:ShowMessage(
                            "Samurai's Scripts",
                            "If the ambient scenario glitches or fails to start, you can hold [Left Shift] and press [E] to force start or stop it.",
                            false,
                            10
                        )
                    end

                    b_IsPlayingAmbientScenario = true
                end
            end
        else
            Disable_E()
            Game.ShowButtonPrompt("Press ~INPUT_PICKUP~ or ~INPUT_AIM~ to stop.")

            if not Self.IsAlive() then
                b_IsPlayingAmbientScenario = false
            end

            if Self.IsRagdolling()
            or Self.IsInCombat()
            or PLAYER.IS_PLAYER_FREE_AIMING(Self.GetPlayerID()) then
                TASK.CLEAR_PED_TASKS_IMMEDIATELY(Self.GetPedID())
                b_IsPlayingAmbientScenario = false
            end

            if PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, 38) or PAD.IS_CONTROL_JUST_PRESSED(0, 25) then
                if PAD.IS_CONTROL_PRESSED(0, 21) then  -- force stop
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(Self.GetPedID())
                else
                    TASK.CLEAR_PED_TASKS(Self.GetPedID())

                    if PED.IS_PED_USING_ANY_SCENARIO(Self.GetPedID()) then
                        Game.BusySpinnerOn(_T("SCN_STOP_SPINNER_"), 3)
                        repeat
                            Sleep(10)
                        until not PED.IS_PED_USING_ANY_SCENARIO(Self.GetPedID())
                        Game.BusySpinnerOff()
                    end
                end

                ambscn:sleep(1000)
                b_IsPlayingAmbientScenario = false
            end
        end
    end
end)

script.register_looped("SS_KAMIKAZE", function(s)
    if kamikazeDrivers and Self.IsAlive() then
        local gta_peds = entities.get_all_peds_as_handles()
        local myGroup  = PED.GET_PED_GROUP_INDEX(Self.GetPedID())

        for _, ped in pairs(gta_peds) do
            if (ped ~= Self.GetPedID())
            and PED.IS_PED_SITTING_IN_ANY_VEHICLE(ped)
            and not PED.IS_PED_A_PLAYER(ped)
            and not PED.IS_PED_GROUP_MEMBER(ped, myGroup)
            and not SS.IsScriptEntity(ped) then
                local ped_veh = PED.GET_VEHICLE_PED_IS_USING(ped)

                if VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(ped_veh) then
                    if VEHICLE.IS_VEHICLE_STOPPED(ped_veh) then
                        TASK.TASK_VEHICLE_TEMP_ACTION(ped, ped_veh, 23, 1000)
                    end

                    if ENTITY.GET_ENTITY_SPEED(ped_veh) > 1.8
                    and ENTITY.GET_ENTITY_SPEED(ped_veh) < 70
                    and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(ped_veh)
                    and not ENTITY.IS_ENTITY_DEAD(ped, false) then
                        VEHICLE.SET_VEHICLE_BRAKE(ped_veh, false)
                        VEHICLE.SET_VEHICLE_FORWARD_SPEED(ped_veh, (ENTITY.GET_ENTITY_SPEED(ped_veh) + 0.7))
                    end
                end
            end
            s:sleep(1)
        end
    end
end)

script.register_looped("SS_PUBLICENEMY", function(s) -- Public Enemy
    if publicEnemy and Self.IsAlive() then
        local myGroup = Self.GetGroupIndex()
        local gta_peds = entities.get_all_peds_as_handles()

        for _, ped in pairs(gta_peds) do
            if (ped ~= Self.GetPedID())
            and not PED.IS_PED_A_PLAYER(ped)
            and not PED.IS_PED_GROUP_MEMBER(ped, myGroup)
            and not SS.IsScriptEntity(ped) then
                for _, attr in ipairs(t_PEcombatAttributes) do
                    PED.SET_PED_COMBAT_ATTRIBUTES(ped, attr.id, attr.bool)
                end

                if not PED.IS_PED_IN_COMBAT(ped, Self.GetPedID()) then
                    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)

                    for _, cflag in ipairs(t_PEconfigFlags) do
                        if not PED.GET_PED_CONFIG_FLAG(ped, cflag.id, cflag.bool) then
                            PED.SET_PED_CONFIG_FLAG(ped, cflag.id, cflag.bool)
                        end
                    end

                    if WEAPON.IS_PED_ARMED(ped, 7) then
                        WEAPON.SET_PED_DROPS_WEAPON(ped)
                    end

                    PED.SET_PED_RESET_FLAG(ped, 440, true) -- PRF_IgnoreCombatManager so they can all gang up on you and beat your ass without waiting for their turns
                    TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                    PLAYER.SET_POLICE_IGNORE_PLAYER(self.get_id(), true)
                    PLAYER.SET_MAX_WANTED_LEVEL(0)
                    TASK.TASK_COMBAT_PED(ped, Self.GetPedID(), 0, 16)
                end
            end
            s:sleep(3)
        end
    end
end)

-- Casino Pacino
script.register_looped("SS_CASINOPACINO", function(dunk)
    if not Game.IsOnline() or not SS.IsUpToDate() then
        return
    end

    if force_poker_cards then
        local player_id = self.get_id()

        if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("three_card_poker")) ~= 0 then
            while (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", -1, 0) ~= player_id)
            and (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 0, 0) ~= player_id)
            and (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 1, 0) ~= player_id)
            and( NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 2, 0) ~= player_id)
            and (NETWORK.NETWORK_GET_HOST_OF_SCRIPT("three_card_poker", 3, 0) ~= player_id) do
                network.force_script_host("three_card_poker")
                YimToast:ShowMessage(
                    "Samuai's Scripts",
                    _T("CP_TCC_CTRL_NOTIF_")
                ) -- If you see this spammed, someone if fighting you for control. -- YimToast has a 3s cooldown before showing the same notification again
                dunk:sleep(500)
            end

            local players_current_table = locals.get_int(
                "three_card_poker",
                three_card_poker_table
                + 1
                + (player_id * three_card_poker_table_size)
                + 2
            ) -- The Player's current table he is sitting at.

            if (players_current_table ~= -1) then -- If the player is sitting at a poker table
                local player_0_card_1 = locals.get_int(
                    "three_card_poker",
                    (three_card_poker_cards)
                    + (three_card_poker_current_deck)
                    + (1 + (players_current_table * three_card_poker_deck_size))
                    + (2)
                    + (1)
                    + (0 * 3)
                )

                local player_0_card_2 = locals.get_int(
                    "three_card_poker",
                    (three_card_poker_cards)
                    + (three_card_poker_current_deck)
                    + (1 + (players_current_table * three_card_poker_deck_size))
                    + (2)
                    + (2)
                    + (0 * 3)
                )

                local player_0_card_3 = locals.get_int(
                    "three_card_poker",
                    (three_card_poker_cards)
                    + (three_card_poker_current_deck)
                    + (1 + (players_current_table * three_card_poker_deck_size))
                    + (2)
                    + (3)
                    + (0 * 3)
                )

                if (player_0_card_1 ~= 50) or (player_0_card_2 ~= 51) or (player_0_card_3 ~= 52) then --Check if we need to overwrite the deck.
                    local total_players = 0

                    for player_iter = 0, 31, 1 do
                        local player_table = locals.get_int(
                            "three_card_poker",
                            three_card_poker_table
                            + 1
                            + (player_iter * three_card_poker_table_size)
                            + 2
                        )

                        if (player_iter ~= player_id) and (player_table == players_current_table) then --An additional player is sitting at the user's table.
                            total_players = total_players + 1
                        end
                    end

                    for playing_player_iter = 0, total_players, 1 do
                        SetPokerCards(playing_player_iter, players_current_table, 50, 51, 52)
                    end

                    if set_dealers_poker_cards then
                        SetPokerCards(total_players + 1, players_current_table, 1, 8, 22)
                    end
                end
            end
        end
    end

    if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("blackjack")) ~= 0 then
        local dealers_card = 0
        local blackjack_table = locals.get_int("blackjack",
            blackjack_table_players + 1 + (self.get_id() * blackjack_table_players_size) + 4) --The Player's current table he is sitting at.
        if blackjack_table ~= -1 then
            dealers_card     = locals.get_int("blackjack",
                blackjack_cards + blackjack_decks + 1 + (blackjack_table * 13) + 1) --Dealer's facedown card.
            dealers_card_str = GetCardNameFromIndex(dealers_card)
        else
            dealers_card_str = _T("CP_NOT_PLAYING_BJ_TXT_")
        end
    else
        dealers_card_str = _T("CP_NOT_IN_CASINO_TXT_")
    end

    if force_roulette_wheel then
        local player_id = self.get_id()
        if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("casinoroulette")) ~= 0 then
            while NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", -1, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 0, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 1, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 2, 0) ~= player_id and NETWORK.NETWORK_GET_HOST_OF_SCRIPT("casinoroulette", 3, 0) ~= player_id do
                network.force_script_host("casinoroulette")
                YimToast:ShowMessage("Samurai's Scripts", _T("CP_ROULETTE_CTRL_NOTIF_")) --If you see this spammed, someone if fighting you for control.
                dunk:sleep(500)
            end

            for tabler_iter = 0, 6, 1 do
                locals.set_int(
                    "casinoroulette",
                    (roulette_master_table)
                    + (roulette_outcomes_table)
                    + (roulette_ball_table)
                    + (tabler_iter),
                    18
                )
            end
        end
    end

    if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("casino_slots")) ~= 0 then
        local needs_run = false

        if rig_slot_machine then
            for slots_iter = 3, 196, 1 do
                if slots_iter ~= 67 and slots_iter ~= 132 then
                    if locals.get_int("casino_slots", (slots_random_results_table) + (slots_iter)) ~= 6 then
                        needs_run = true
                    end
                end
            end
        else
            local sum = 0
            for slots_iter = 3, 196, 1 do
                if slots_iter ~= 67 and slots_iter ~= 132 then
                    sum = sum + locals.get_int("casino_slots", (slots_random_results_table) + (slots_iter))
                end
            end
            needs_run = sum == 1152
        end

        if needs_run then
            for slots_iter = 3, 196, 1 do
                if slots_iter ~= 67 and slots_iter ~= 132 then
                    local slot_result = 6
                    if not rig_slot_machine then
                        math.randomseed(os.time() + slots_iter)
                        slot_result = math.random(0, 7)
                    end
                    locals.set_int("casino_slots", (slots_random_results_table) + (slots_iter), slot_result)
                end
            end
        end

        if autoplay_slots then
            local slotstate = locals.get_int("casino_slots", slots_slot_machine_state) --Local Laddie️™®️© is a product of Limited Laddies LLC, all rights reserved.

            if slotstate & (1 << 0) == 1 then --The user is sitting at a slot machine.
                local chips = stats.get_int('MPX_CASINO_CHIPS')
                local chip_cap = autoplay_chips_cap
                if (autoplay_cap and chips < chip_cap) or not autoplay_cap then
                    if (slotstate & (1 << 24) == 0) then --The slot machine is not currently spinning.
                        dunk:yield() -- Wait for the previous spin to clean up, if we just came from a spin.
                        slotstate = slotstate | (1 << 3) -- Bitwise set the 3rd bit (begin playing)
                        locals.set_int("casino_slots", slots_slot_machine_state, slotstate)
                        dunk:sleep(500) -- If we rewrite the begin playing bit again, the machine will get stuck.
                    end
                end
            end
        end
    end

    if bypass_casino_bans then
        stats.set_int("MPPLY_CASINO_CHIPS_WON_GD", 0)
        stats.set_int("MPPLY_CASINO_CHIPS_WONTIM", 0)
        stats.set_int("MPPLY_CASINO_GMBLNG_GD", 0)
        stats.set_int("MPPLY_CASINO_BAN_TIME", 0)
        stats.set_int("MPPLY_CASINO_CHIPS_PURTIM", 0)
        stats.set_int("MPPLY_CASINO_CHIPS_PUR_GD", 0)
        stats.set_int("MPPLY_CASINO_CHIPS_SOLD", 0)
        stats.set_int("MPPLY_CASINO_CHIPS_SELTIM", 0)
    end

    if gui.is_open() and casino_pacino:is_selected() then
        casino_heist_approach      = stats.get_int("MPX_H3OPT_APPROACH")
        casino_heist_target        = stats.get_int("MPX_H3OPT_TARGET")
        casino_heist_last_approach = stats.get_int("MPX_H3_LAST_APPROACH")
        casino_heist_hard          = stats.get_int("MPX_H3_HARD_APPROACH")
        casino_heist_gunman        = stats.get_int("MPX_H3OPT_CREWWEAP")
        casino_heist_driver        = stats.get_int("MPX_H3OPT_CREWDRIVER")
        casino_heist_hacker        = stats.get_int("MPX_H3OPT_CREWHACKER")
        casino_heist_weapons       = stats.get_int("MPX_H3OPT_WEAPS")
        casino_heist_cars          = stats.get_int("MPX_H3OPT_VEHS")
        casino_heist_masks         = stats.get_int("MPX_H3OPT_MASKS")

        local cooldown_time = tunables.get_int("VC_CASINO_CHIP_MAX_WIN_LOSS_COOLDOWN")
        local time_delta    = os.time() - stats.get_int("MPPLY_CASINO_CHIPS_WONTIM") -- "I've won the jackpot, and it doesn't make me feel bad." ~Casino Pacino (He only cares about winners)
        local minutes_left  = (cooldown_time - time_delta) / 60
        local chipswon_gd   = stats.get_int("MPPLY_CASINO_CHIPS_WON_GD")
        local max_chip_wins = tunables.get_int("VC_CASINO_CHIP_MAX_WIN_DAILY")

        casino_cooldown_update_str = chipswon_gd >= max_chip_wins
        and string.format("Cooldown expires in approximately: %.2f minute(s).", minutes_left) or "Off Cooldown"
    end

    if heist_cart_autograb then
        if locals.get_int("fm_mission_controller", fm_mission_controller_cart_grab) == 3 then
            locals.set_int("fm_mission_controller", fm_mission_controller_cart_grab, 4)
        elseif locals.get_int("fm_mission_controller", fm_mission_controller_cart_grab) == 4 then
            locals.set_float(
                "fm_mission_controller",
                fm_mission_controller_cart_grab + fm_mission_controller_cart_grab_speed,
                2
            )
        end
    end
end)

-- Misc toggleables
script.register_looped("SS_TOGGLABLES", function(hfe)
    if disableActionMode then
        Self.DisableActionMode()
    end

    if hatsinvehs then
        Self.AllowHatsInVehicles()
    end

    if novehragdoll then
        Self.NoRagdollOnVehRoof()
    end

    if disableFlightMusic and not b_FlightMusicDisabled then
        AUDIO.SET_AUDIO_FLAG("DisableFlightMusic", true)
        b_FlightMusicDisabled = true
    end

    if extend_world and not b_WorldBoundsExtended then
        Game.World.ExtendBounds(true)
        b_WorldBoundsExtended = true
    end

    if unbreakableWindows
    and (Self.Vehicle.Current ~= 0)
    and not Self.Vehicle.HasUnbreakableWindows then
        VEHICLE.SET_DONT_PROCESS_VEHICLE_GLASS(Self.Vehicle.Current, true)
        Self.Vehicle.HasUnbreakableWindows = true
    end

    if Self.IsOutside()
    and Self.IsDriving()
    and VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(Self.Vehicle.Current)
    and (Self.Vehicle.Current == Self.Vehicle.Previous)
    and not Self.Vehicle.IsPlane
    and not Self.Vehicle.IsHeli
    and not Self.Vehicle.IsBoat then
        if noEngineBraking and not Self.Vehicle.IsEngineBrakeDisabled then
            Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._FREEWHEEL_NO_GAS, true)
            hfe:sleep(100)
        end

        if kersBoost and not Self.Vehicle.HasKersBoost and not VEHICLE.GET_VEHICLE_HAS_KERS(Self.Vehicle.Current) then
            Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._HAS_KERS, true)
            VEHICLE.SET_VEHICLE_KERS_ALLOWED(Self.Vehicle.Current, true)
            hfe:sleep(100)
        end

        if offroaderx2 and not Self.Vehicle.IsOffroaderEnabled then
            Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._OFFROAD_ABILITIES_X2, true)
            hfe:sleep(100)
        end

        if rallyTires and not Self.Vehicle.HasRallyTires then
            Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._HAS_RALLY_TYRES, true)
            hfe:sleep(100)
        end

        if (Self.Vehicle.IsBike or Self.Vehicle.IsQuad) then
            if noTractionCtrl and not Self.Vehicle.IsTractionControlDisabled then
                Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._FORCE_NO_TC_OR_SC, true)
                hfe:sleep(100)
            end

            if easyWheelie and not Self.Vehicle.IsLowSpeedWheelieEnabled then
                Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._LOW_SPEED_WHEELIES, true)
                hfe:sleep(100)
            end
        end
    end

    if Game.IsOnline() and SS.IsUpToDate() then
        if mc_work_cd and (tunables.get_int("BIKER_CLUB_WORK_COOLDOWN_GLOBAL") > 0) then
            tunables.set_int("BIKER_CLUB_WORK_COOLDOWN_GLOBAL", 0)
        end

        if hangar_cd then
            if tunables.get_int("SMUG_STEAL_EASY_COOLDOWN_TIMER") > 0 then
                tunables.set_int("SMUG_STEAL_EASY_COOLDOWN_TIMER", 0)
            end
            if tunables.get_int("SMUG_STEAL_MED_COOLDOWN_TIMER") > 0 then
                tunables.set_int("SMUG_STEAL_MED_COOLDOWN_TIMER", 0)
            end
            if tunables.get_int("SMUG_STEAL_HARD_COOLDOWN_TIMER") > 0 then
                tunables.set_int("SMUG_STEAL_HARD_COOLDOWN_TIMER", 0)
            end
        end

        if nc_management_cd and (tunables.get_int("BB_CLUB_MANAGEMENT_CLUB_MANAGEMENT_MISSION_COOLDOWN") > 0) then
            tunables.set_int("BB_CLUB_MANAGEMENT_CLUB_MANAGEMENT_MISSION_COOLDOWN", 0)
        end

        if nc_vip_mission_chance then
            if tunables.get_int("NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT") > 0 then
                tunables.set_int("NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT", 0)
            end
        else
            if tunables.get_int("NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT") == 0 then
                tunables.set_int("NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT", 50)
            end
        end

        if security_missions_cd and (tunables.get_int("FIXER_SECURITY_CONTRACT_COOLDOWN_TIME") > 0) then
            tunables.set_int("FIXER_SECURITY_CONTRACT_COOLDOWN_TIME", 0)
        end

        if ie_vehicle_steal_cd and (tunables.get_int("IMPEXP_STEAL_COOLDOWN") > 0) then
            tunables.set_int("IMPEXP_STEAL_COOLDOWN", 0)
        end

        if ie_vehicle_sell_cd then
            if tunables.get_int("IMPEXP_SELL_COOLDOWN") > 0 then
                tunables.set_int("IMPEXP_SELL_COOLDOWN", 0)
            end
            if tunables.get_int("IMPEXP_SELL_1_CAR_COOLDOWN") > 0 then
                tunables.set_int("IMPEXP_SELL_1_CAR_COOLDOWN", 0)
            end
            if tunables.get_int("IMPEXP_SELL_2_CAR_COOLDOWN") > 0 then
                tunables.set_int("IMPEXP_SELL_2_CAR_COOLDOWN", 0)
            end
            if tunables.get_int("IMPEXP_SELL_3_CAR_COOLDOWN") > 0 then
                tunables.set_int("IMPEXP_SELL_3_CAR_COOLDOWN", 0)
            end
            if tunables.get_int("IMPEXP_SELL_4_CAR_COOLDOWN") > 0 then
                tunables.set_int("IMPEXP_SELL_4_CAR_COOLDOWN", 0)
            end
        end

        if ceo_crate_buy_cd then
            if tunables.get_int("EXEC_BUY_COOLDOWN") > 0 then
                tunables.set_int("EXEC_BUY_COOLDOWN", 0)
            end
            if tunables.get_int("EXEC_BUY_FAIL_COOLDOWN") > 0 then
                tunables.set_int("EXEC_BUY_FAIL_COOLDOWN", 0)
            end
        end

        if ceo_crate_sell_cd then
            if tunables.get_int("EXEC_SELL_COOLDOWN") > 0 then
                tunables.set_int("EXEC_SELL_COOLDOWN", 0)
            end
            if tunables.get_int("EXEC_SELL_FAIL_COOLDOWN") > 0 then
                tunables.set_int("EXEC_SELL_FAIL_COOLDOWN", 0)
            end
        end

        if dax_work_cd and (stats.get_int("MPX_XM22JUGGALOWORKCDTIMER") > 0) then
            stats.set_int("MPX_XM22JUGGALOWORKCDTIMER", 0)
        end

        if garment_rob_cd and (stats.get_int("MPX_HACKER24_ROBBERY_CD") > 0) then
            stats.set_int("MPX_HACKER24_ROBBERY_CD", 0)
        end
    end
end)

event.register_handler(menu_event.MenuUnloaded, function()
    SS.Cleanup()
end)

event.register_handler(menu_event.ScriptsReloaded, function()
    SS.Cleanup()
end)
