---@diagnostic disable

local selected_lang
function settingsUI()
    disableTooltips, dtUsed = ImGui.Checkbox(translateLabel("DISABLE_TOOLTIPS_CB_"), disableTooltips)
    if dtUsed then
        CFG:SaveItem("disableTooltips", disableTooltips)
        UI.widgetSound("Nav2")
    end

    disableUiSounds, duisndUsed = ImGui.Checkbox(translateLabel("DISABLE_UISOUNDS_CB_"), disableUiSounds)
    UI.toolTip(false, translateLabel("DISABLE_UISOUNDS_DESC_"))
    if duisndUsed then
        CFG:SaveItem("disableUiSounds", disableUiSounds)
        UI.widgetSound("Nav2")
    end

    disableFlightMusic, dpmUsed = ImGui.Checkbox(translateLabel("FLIGHT_MUSIC_CB_"), disableFlightMusic)
    UI.toolTip(false, translateLabel("FLIGHT_MUSIC_DESC_"))
    if dpmUsed then
        CFG:SaveItem("disableFlightMusic", disableFlightMusic)
        UI.widgetSound("Nav2")
        if not disableFlightMusic then
            script.run_in_fiber(function()
                AUDIO.SET_AUDIO_FLAG("DisableFlightMusic", false)
                flight_music_off = false
            end)
        end
    end

    disable_quotes, dqUsed = ImGui.Checkbox(translateLabel("DAILY_QUOTES_CB_"), disable_quotes)
    UI.toolTip(false, translateLabel("DAILY_QUOTES_DESC_"))
    if dqUsed then
        UI.widgetSound("Nav2")
        CFG:SaveItem("disable_quotes", disable_quotes)
    end

    disable_mdef_logs, dmlUsed = ImGui.Checkbox(translateLabel("MISSILE_DEF_LOGS_CB_"), disable_mdef_logs)
    UI.toolTip(false, translateLabel("MISSILE_DEF_LOGS_DESC_"))
    if dmlUsed then
        UI.widgetSound("Nav2")
        CFG:SaveItem("disable_mdef_logs", disable_mdef_logs)
    end

    ImGui.Spacing()
    if shortcut_anim.anim ~= nil then
        if ImGui.Button(translateLabel("ANIM_HOTKEY_DEL2_")) then
            UI.widgetSound("Delete")
            shortcut_anim = {}
            CFG:SaveItem("shortcut_anim", {})
            YimToast:ShowSuccess("Samurais Scripts", "Animation shortcut has been reset.")
        end
        UI.toolTip(false, translateLabel("DEL_HOTKEY_DESC_"))
    else
        ImGui.BeginDisabled()
        ImGui.Button(translateLabel("ANIM_HOTKEY_DEL2_"))
        ImGui.EndDisabled()
        UI.toolTip(false, translateLabel("NO_HOTKEY_TXT_"))
    end

    ImGui.Spacing(); ImGui.Text("Supplies Autofill Delay:")
    ImGui.BeginDisabled(wh1_loop or wh2_loop or wh3_loop or wh4_loop or wh5_loop or hangarLoop)
    ImGui.PushItemWidth(200)
    supply_autofill_delay, safdUsed = ImGui.SliderInt("##autofillDelay", supply_autofill_delay, 500, 60000)
    ImGui.PopItemWidth()
    ImGui.EndDisabled()
    UI.toolTip(false, translateLabel("AUTOFILL_TIMEDELAY_DESC_"))
    ImGui.SameLine(); ImGui.Text(string.format("%.1f s", (supply_autofill_delay / 1000)))
    if safdUsed then
        UI.widgetSound("Nav")
        CFG:SaveItem("supply_autofill_delay", supply_autofill_delay)
        supply_autofill_delay = CFG:ReadItem("supply_autofill_delay")
    end

    ImGui.Dummy(1, 10); ImGui.SeparatorText(translateLabel("LANGUAGE_TXT_"))
    ImGui.Spacing(); ImGui.BulletText(string.format("%s %s", translateLabel("CURRENT_LANGUAGE_TXT_"), current_lang))
    ImGui.Spacing(); useGameLang, uglUsed = ImGui.Checkbox(translateLabel("GAME_LANGUAGE_CB_"), useGameLang)
    if useGameLang then
        UI.toolTip(false, translateLabel("GAME_LANGUAGE_DESC_"))
        LANG, current_lang = Game.Language()
    end
    if uglUsed then
        if not useGameLang then
            selected_lang = lang_T[lang_idx + 1]
            LANG          = selected_lang.iso
            current_lang  = selected_lang.name
        end
        UI.widgetSound("Nav2")
        CFG:SaveItem("useGameLang", useGameLang)
        CFG:SaveItem("current_lang", current_lang)
        CFG:SaveItem("LANG", LANG)
        CFG:SaveItem("lang_idx", lang_idx)
        initStrings()
        YimToast:ShowSuccess("Samurai's Scripts", translateLabel("LANG_CHANGED_NOTIF_"))
    end

    if not useGameLang then
        ImGui.Text(translateLabel("GENERIC_CUSTOM_LABEL_"))
        ImGui.PushItemWidth(260)
        displayLangs()
        ImGui.PopItemWidth()
        selected_lang = lang_T[lang_idx + 1]
        if lang_idxUsed then
            UI.widgetSound("Select")
            LANG         = selected_lang.iso
            current_lang = selected_lang.name
            CFG:SaveItem("lang_idx", lang_idx)
            CFG:SaveItem("LANG", LANG)
            CFG:SaveItem("current_lang", current_lang)
            initStrings()
            YimToast:ShowSuccess("Samurai's Scripts", translateLabel("LANG_CHANGED_NOTIF_"))
        end
    end

    ImGui.Dummy(10, 1)
    if UI.coloredButton(translateLabel("RESET_SETTINGS_BTN_"), "#FF0000", "#EE4B2B", "#880808", 1) then
        UI.widgetSound("Focus_In")
        ImGui.OpenPopup("Confirm")
    end
    ImGui.SetNextWindowPos(760, 400, ImGuiCond.Appearing)
    ImGui.SetNextWindowBgAlpha(0.8)
    if ImGui.BeginPopupModal("Confirm", ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
        UI.coloredText(translateLabel("CONFIRM_PROMPT_"), "yellow", 1, 20)
        if ImGui.Button(string.format("  %s  ", translateLabel("GENERIC_YES_"))) then
            UI.widgetSound("Select2")
            SS.reset_settings()
            ImGui.CloseCurrentPopup()
        end
        ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
        if ImGui.Button(string.format("  %s  ", translateLabel("GENERIC_NO_"))) then
            UI.widgetSound("Cancel")
            ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
    end
end

function hotkeysUI()
    ImGui.BeginTabBar("Keyboard Hotkeys")
    if ImGui.BeginTabItem(translateLabel("GENERIC_KEYBOARD_LABEL_")) then
        ImGui.Dummy(1, 5)

        SS.openHotkeyWindow("Ragdoll On Demand", keybinds.rodBtn)

        SS.openHotkeyWindow("Drift", keybinds.tdBtn)

        SS.openHotkeyWindow("NOS", keybinds.nosBtn)

        SS.openHotkeyWindow("Stop Animanimation", keybinds.stop_anim)

        SS.openHotkeyWindow("Play Animanimation", keybinds.play_anim)

        SS.openHotkeyWindow("Previous Animanimation", keybinds.previous_anim)

        SS.openHotkeyWindow("Next Animanimation", keybinds.next_anim)

        SS.openHotkeyWindow("Triggerbot Button", keybinds.triggerbotBtn)

        SS.openHotkeyWindow("Flatbed Tow/Detach", keybinds.flatbedBtn)

        SS.openHotkeyWindow("Purge", keybinds.purgeBtn)

        SS.openHotkeyWindow("Toggle Auto-Kill", keybinds.autokill)

        SS.openHotkeyWindow("Toggle Enemies Flee", keybinds.enemiesFlee)

        SS.openHotkeyWindow("Toggle Missile Defence", keybinds.missl_def)

        SS.openHotkeyWindow("Vehicle Mine", keybinds.vehicle_mine)

        SS.openHotkeyWindow("Laser Sights", keybinds.laser_sight)

        SS.openHotkeyWindow("PANIK!! Button", keybinds.panik)

        SS.openHotkeyWindow("Command Executor", keybinds.commands)
        ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem(translateLabel("GENERIC_CONTROLLER_LABEL_")) then
        ImGui.Dummy(1, 5)

        SS.gpadHotkeyWindow("Ragdoll On Demand", gpad_keybinds.rodBtn)

        SS.gpadHotkeyWindow("Triggerbot Button", gpad_keybinds.triggerbotBtn)

        SS.gpadHotkeyWindow("Drift Button", gpad_keybinds.tdBtn)

        SS.gpadHotkeyWindow("NOS Button", gpad_keybinds.nosBtn)

        SS.gpadHotkeyWindow("Flatbed Button", gpad_keybinds.flatbedBtn)

        SS.gpadHotkeyWindow("Purge Button", gpad_keybinds.purgeBtn)

        SS.gpadHotkeyWindow("Vehicle Mine Button", gpad_keybinds.vehicle_mine)

        SS.gpadHotkeyWindow("Laser Sights", gpad_keybinds.laser_sight)
        ImGui.EndTabItem()
    end
    ImGui.EndTabBar()
end
