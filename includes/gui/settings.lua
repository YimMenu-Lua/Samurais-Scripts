---@diagnostic disable

local selected_lang

local function DisplayLangs()
    filteredLangs = {}
    for _, lang in ipairs(t_Langs) do
        table.insert(filteredLangs, lang.name)
    end
    lang_idx, lang_idxUsed = ImGui.Combo("##langs", lang_idx, filteredLangs, #t_Langs)
    if UI.IsItemClicked("lmb") then
        UI.WidgetSound("Nav")
    end
end

function SettingsUI()
    local f_PosY = 660
    if not useGameLang then
        f_PosY = f_PosY + 100
    end

    ImGui.BeginChild("WoldChild", 400, f_PosY, true)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 20, 20)
    disableTooltips, dtUsed = ImGui.Checkbox(_T("DISABLE_TOOLTIPS_CB_"), disableTooltips)
    if dtUsed then
        CFG:SaveItem("disableTooltips", disableTooltips)
        UI.WidgetSound("Nav2")
    end

    disableUiSounds, duisndUsed = ImGui.Checkbox(_T("DISABLE_UISOUNDS_CB_"), disableUiSounds)
    UI.Tooltip(_T("DISABLE_UISOUNDS_DESC_"))
    if duisndUsed then
        CFG:SaveItem("disableUiSounds", disableUiSounds)
        UI.WidgetSound("Nav2")
    end

    disableFlightMusic, dpmUsed = ImGui.Checkbox(_T("FLIGHT_MUSIC_CB_"), disableFlightMusic)
    UI.Tooltip(_T("FLIGHT_MUSIC_DESC_"))
    if dpmUsed then
        CFG:SaveItem("disableFlightMusic", disableFlightMusic)
        UI.WidgetSound("Nav2")
        if not disableFlightMusic then
            script.run_in_fiber(function()
                AUDIO.SET_AUDIO_FLAG("DisableFlightMusic", false)
                flight_music_off = false
            end)
        end
    end

    disable_quotes, dqUsed = ImGui.Checkbox(_T("DAILY_QUOTES_CB_"), disable_quotes)
    UI.Tooltip(_T("DAILY_QUOTES_DESC_"))
    if dqUsed then
        UI.WidgetSound("Nav2")
        CFG:SaveItem("disable_quotes", disable_quotes)
    end

    disable_mdef_logs, dmlUsed = ImGui.Checkbox(_T("MISSILE_DEF_LOGS_CB_"), disable_mdef_logs)
    UI.Tooltip(_T("MISSILE_DEF_LOGS_DESC_"))
    if dmlUsed then
        UI.WidgetSound("Nav2")
        CFG:SaveItem("disable_mdef_logs", disable_mdef_logs)
    end

    if shortcut_anim.anim ~= nil then
        if ImGui.Button(_T("ANIM_HOTKEY_DEL2_")) then
            UI.WidgetSound("Delete")
            shortcut_anim = {}
            CFG:SaveItem("shortcut_anim", {})
            YimToast:ShowSuccess("Samurais Scripts", "Animation shortcut has been reset.")
        end
        UI.Tooltip(_T("DEL_HOTKEY_DESC_"))
    else
        ImGui.BeginDisabled()
        ImGui.Button(_T("ANIM_HOTKEY_DEL2_"))
        ImGui.EndDisabled()
        UI.Tooltip(_T("NO_HOTKEY_TXT_"))
    end

    ImGui.Text("Supplies Autofill Delay:")
    ImGui.BeginDisabled(wh1_loop or wh2_loop or wh3_loop or wh4_loop or wh5_loop or hangarLoop)
    ImGui.PushItemWidth(200)
    supply_autofill_delay, safdUsed = ImGui.SliderInt("##autofillDelay", supply_autofill_delay, 500, 60000)
    ImGui.PopItemWidth()
    ImGui.EndDisabled()
    UI.Tooltip(_T("AUTOFILL_TIMEDELAY_DESC_"))
    ImGui.SameLine()
    ImGui.Text(string.format("%.1f s", (supply_autofill_delay / 1000)))
    if safdUsed then
        UI.WidgetSound("Nav")
        CFG:SaveItem("supply_autofill_delay", supply_autofill_delay)
        supply_autofill_delay = CFG:ReadItem("supply_autofill_delay")
    end

    ImGui.Dummy(1, 5)
    ImGui.SetWindowFontScale(1.2)
    ImGui.SeparatorText(_T("LANGUAGE_TXT_"))
    ImGui.SetWindowFontScale(1.0)
    ImGui.Spacing()
    ImGui.BulletText(string.format("%s %s", _T("CURRENT_LANGUAGE_TXT_"), current_lang))
    useGameLang, uglUsed = ImGui.Checkbox(_T("GAME_LANGUAGE_CB_"), useGameLang)
    if useGameLang then
        UI.Tooltip(_T("GAME_LANGUAGE_DESC_"))
        LANG, current_lang = Game.GetLanguage()
    end
    if uglUsed then
        if not useGameLang then
            selected_lang = t_Langs[lang_idx + 1]
            LANG          = selected_lang.iso
            current_lang  = selected_lang.name
        end
        UI.WidgetSound("Nav2")
        CFG:SaveItem("useGameLang", useGameLang)
        CFG:SaveItem("current_lang", current_lang)
        CFG:SaveItem("LANG", LANG)
        CFG:SaveItem("lang_idx", lang_idx)
        YimToast:ShowSuccess("Samurai's Scripts", _T("LANG_CHANGED_NOTIF_"))
    end

    if not useGameLang then
        ImGui.Text(_T("GENERIC_CUSTOM_LABEL_"))
        ImGui.PushItemWidth(260)
        DisplayLangs()
        ImGui.PopItemWidth()
        selected_lang = t_Langs[lang_idx + 1]
        if lang_idxUsed then
            UI.WidgetSound("Select")
            LANG         = selected_lang.iso
            current_lang = selected_lang.name
            CFG:SaveItem("lang_idx", lang_idx)
            CFG:SaveItem("LANG", LANG)
            CFG:SaveItem("current_lang", current_lang)
            YimToast:ShowSuccess("Samurai's Scripts", _T("LANG_CHANGED_NOTIF_"))
        end
    end

    ImGui.Dummy(10, 1)
    if UI.ColoredButton(_T("RESET_SETTINGS_BTN_"), "#FF0000", "#EE4B2B", "#880808") then
        UI.WidgetSound("Focus_In")
        ImGui.OpenPopup("Confirm")
    end
    ImGui.SetNextWindowPos(760, 400, ImGuiCond.Appearing)
    ImGui.SetNextWindowBgAlpha(0.8)
    if ImGui.BeginPopupModal("Confirm", ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoTitleBar) then
        UI.ColoredText(_T("CONFIRM_PROMPT_"), "yellow", 1, 20)
        if ImGui.Button(string.format("  %s  ", _T("GENERIC_YES_"))) then
            UI.WidgetSound("Select2")
            SS.ResetSettings()
            ImGui.CloseCurrentPopup()
        end
        ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
        if ImGui.Button(string.format("  %s  ", _T("GENERIC_NO_"))) then
            UI.WidgetSound("Cancel")
            ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
    end
    ImGui.PopStyleVar()
    ImGui.EndChild()
end

function HotkeysUI()
    ImGui.BeginTabBar("Keyboard Hotkeys")
    if ImGui.BeginTabItem(_T("GENERIC_KEYBOARD_LABEL_")) then
        ImGui.Dummy(1, 5)

        SS.OpenKeyboardHotkeysWindow("Ragdoll On Demand", keybinds.rodBtn)

        SS.OpenKeyboardHotkeysWindow("Drift", keybinds.tdBtn)

        SS.OpenKeyboardHotkeysWindow("NOS", keybinds.nosBtn)

        SS.OpenKeyboardHotkeysWindow("Stop Animanimation", keybinds.stop_anim)

        SS.OpenKeyboardHotkeysWindow("Play Animanimation", keybinds.play_anim)

        SS.OpenKeyboardHotkeysWindow("Previous Animanimation", keybinds.previous_anim)

        SS.OpenKeyboardHotkeysWindow("Next Animanimation", keybinds.next_anim)

        SS.OpenKeyboardHotkeysWindow("Triggerbot Button", keybinds.triggerbotBtn)

        SS.OpenKeyboardHotkeysWindow("Flatbed Tow/Detach", keybinds.flatbedBtn)

        SS.OpenKeyboardHotkeysWindow("Purge", keybinds.purgeBtn)

        SS.OpenKeyboardHotkeysWindow("Toggle Auto-Kill", keybinds.autokill)

        SS.OpenKeyboardHotkeysWindow("Toggle Enemies Flee", keybinds.enemiesFlee)

        SS.OpenKeyboardHotkeysWindow("Toggle Missile Defence", keybinds.missl_def)

        SS.OpenKeyboardHotkeysWindow("Vehicle Mine", keybinds.vehicle_mine)

        SS.OpenKeyboardHotkeysWindow("Laser Sights", keybinds.laser_sight)

        SS.OpenKeyboardHotkeysWindow("PANIK!! Button", keybinds.panik)

        SS.OpenKeyboardHotkeysWindow("Command Executor", keybinds.commands)
        ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem(_T("GENERIC_CONTROLLER_LABEL_")) then
        ImGui.Dummy(1, 5)

        SS.OpenControllerHotkeysWindow("Ragdoll On Demand", gpad_keybinds.rodBtn)

        SS.OpenControllerHotkeysWindow("Triggerbot Button", gpad_keybinds.triggerbotBtn)

        SS.OpenControllerHotkeysWindow("Drift Button", gpad_keybinds.tdBtn)

        SS.OpenControllerHotkeysWindow("NOS Button", gpad_keybinds.nosBtn)

        SS.OpenControllerHotkeysWindow("Flatbed Button", gpad_keybinds.flatbedBtn)

        SS.OpenControllerHotkeysWindow("Purge Button", gpad_keybinds.purgeBtn)

        SS.OpenControllerHotkeysWindow("Vehicle Mine Button", gpad_keybinds.vehicle_mine)

        SS.OpenControllerHotkeysWindow("Laser Sights", gpad_keybinds.laser_sight)
        ImGui.EndTabItem()
    end
    ImGui.EndTabBar()
end
