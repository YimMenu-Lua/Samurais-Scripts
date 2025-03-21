---@diagnostic disable: undefined-global, lowercase-global

function mainUI()
    local date_str = os.date("\10    %d-%b-%Y    \10         %H:%M\10\10")
    ImGui.Dummy(1, 10); ImGui.Dummy(150, 1); ImGui.SameLine();
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 80)
    UI.coloredButton(tostring(date_str), '#A67C00', '#A67C00', '#A67C00', 0.15)
    ImGui.PopStyleVar()
    if UI.isItemClicked('lmb') then
        debug_counter = debug_counter + 1
        if debug_counter == 7 then
            UI.widgetSound("Nav")
            log.debug("Debug mode activated.")
            SS_debug = true
            CFG:SaveItem("SS_debug", SS_debug)
        elseif debug_counter > 7 then
            UI.widgetSound("Cancel")
            log.debug("Debug mode deactivated.")
            SS_debug      = false
            debug_counter = 0
            CFG:SaveItem("SS_debug", SS_debug)
        end
    end
    ImGui.Dummy(1, 10); ImGui.SeparatorText("About")
    UI.wrappedText("A collection of scripts aimed towards adding some roleplaying and fun elements to the game.", 25)
    ImGui.Dummy(1, 10)
    ImGui.BulletText(string.format("Script Version:   v%s", SCRIPT_VERSION))
    ImGui.BulletText(string.format("Game Version:   b%s   Online %s", TARGET_BUILD, TARGET_VERSION))
    if not disable_quotes then
        ImGui.Dummy(1, 20); ImGui.SeparatorText("Quote Of The Day"); ImGui.Spacing()
        UI.coloredText(random_quote, 'white', quote_alpha, 24)
    end
end
