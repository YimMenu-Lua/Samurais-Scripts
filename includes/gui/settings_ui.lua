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

    ImGui.BeginChild("settingsui", 400, f_PosY, true)
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
                    b_FlightMusicDisabled = false
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

        b_AutoCleanupEntities, autocleanupClicked = ImGui.Checkbox("Auto-Cleanup Entities", b_AutoCleanupEntities)
        UI.Tooltip(_T("AUTO_CLEAN_ENTITIES_CB_"))

        if autocleanupClicked then
            UI.WidgetSound("Nav2")
            CFG:SaveItem("b_AutoCleanupEntities", b_AutoCleanupEntities)
        end

        ImGui.Text("Supplies Autofill Delay:")
        ImGui.SetNextItemWidth(200)
        supply_autofill_delay, safdUsed = ImGui.SliderInt("##autofillDelay", supply_autofill_delay, 500, 60000)
        UI.Tooltip(_T("AUTOFILL_TIMEDELAY_DESC_"))

        ImGui.SameLine()
        ImGui.Text(string.format("%.1f s", (supply_autofill_delay / 1000)))

        if safdUsed then
            UI.WidgetSound("Nav")
            CFG:SaveItem("supply_autofill_delay", supply_autofill_delay)
        end

        ImGui.Dummy(1, 5)
        ImGui.SetWindowFontScale(1.2)
        ImGui.SeparatorText(_T("LANGUAGE_TXT_"))
        ImGui.SetWindowFontScale(1.0)
        ImGui.Spacing()
        ImGui.BulletText(string.format("%s %s", _T("CURRENT_LANGUAGE_TXT_"), current_lang))

        useGameLang, uglUsed = ImGui.Checkbox(_T("GAME_LANGUAGE_CB_"), useGameLang)

        if uglUsed then
            if useGameLang then
                LANG, current_lang = Game.GetLanguage()
            else
                selected_lang = t_Langs[lang_idx + 1]
                LANG          = selected_lang.iso
                current_lang  = selected_lang.name
            end

            UI.WidgetSound("Nav2")
            CFG:SaveItem("useGameLang", useGameLang)
            CFG:SaveItem("LANG", LANG)
            CFG:SaveItem("current_lang", current_lang)
            CFG:SaveItem("lang_idx", lang_idx)
            YimToast:ShowSuccess("Samurai's Scripts", _T("LANG_CHANGED_NOTIF_"))
        end

        if useGameLang then
            UI.Tooltip(_T("GAME_LANGUAGE_DESC_"))
        else
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
            ImGui.OpenPopup("confirm_settings_reset")
        end

        ImGui.SetNextWindowPos(760, 400, ImGuiCond.Appearing)
        ImGui.SetNextWindowBgAlpha(0.8)
        UI.ConfirmPopup("confirm_settings_reset", SS.ResetSettings)
    ImGui.EndChild()
end

function HotkeysUI()
    ImGui.BeginTabBar("Keyboard Hotkeys")
    if ImGui.BeginTabItem(_T("GENERIC_KEYBOARD_LABEL_")) then
        ImGui.Dummy(1, 5)

        UI.HotkeyPrompt("Ragdoll On Demand", keybinds.rodBtn)

        UI.HotkeyPrompt("Drift", keybinds.tdBtn)

        UI.HotkeyPrompt("NOS", keybinds.nosBtn)

        UI.HotkeyPrompt("Stop Animanimation", keybinds.stop_anim)

        -- UI.HotkeyPrompt("Play Animanimation", keybinds.play_anim)

        -- UI.HotkeyPrompt("Previous Animanimation", keybinds.previous_anim)

        -- UI.HotkeyPrompt("Next Animanimation", keybinds.next_anim)

        UI.HotkeyPrompt("Triggerbot Button", keybinds.triggerbotBtn)

        UI.HotkeyPrompt("Flatbed Tow/Detach", keybinds.flatbedBtn)

        UI.HotkeyPrompt("Purge", keybinds.purgeBtn)

        UI.HotkeyPrompt("Vehicle Mine", keybinds.vehicle_mine)

        UI.HotkeyPrompt("Toggle Auto-Kill", keybinds.autokill)

        UI.HotkeyPrompt("Toggle Enemies Flee", keybinds.enemiesFlee)

        UI.HotkeyPrompt("Toggle Missile Defence", keybinds.missl_def)

        UI.HotkeyPrompt("Cobra Maneuver", keybinds.cobra_maneuver)

        UI.HotkeyPrompt("Laser Sights", keybinds.laser_sight)

        UI.HotkeyPrompt("Command Executor", keybinds.commands)

        UI.HotkeyPrompt("PANIK!! Button", keybinds.panik)

        ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem(_T("GENERIC_CONTROLLER_LABEL_")) then
        ImGui.Dummy(1, 5)

        UI.HotkeyPrompt("Ragdoll On Demand", gpad_keybinds.rodBtn, true)

        UI.HotkeyPrompt("Triggerbot Button", gpad_keybinds.triggerbotBtn, true)

        UI.HotkeyPrompt("Drift Button", gpad_keybinds.tdBtn, true)

        UI.HotkeyPrompt("NOS Button", gpad_keybinds.nosBtn, true)

        UI.HotkeyPrompt("Flatbed Button", gpad_keybinds.flatbedBtn, true)

        UI.HotkeyPrompt("Purge Button", gpad_keybinds.purgeBtn, true)

        UI.HotkeyPrompt("Vehicle Mine Button", gpad_keybinds.vehicle_mine, true)

        UI.HotkeyPrompt("Laser Sights", gpad_keybinds.laser_sight, true)
        ImGui.EndTabItem()
    end
    ImGui.EndTabBar()
end
