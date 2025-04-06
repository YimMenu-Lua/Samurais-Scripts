---@diagnostic disable: undefined-global, lowercase-global


function MainUI()
    local date_str = os.date("\10    %d-%b-%Y    \10         %H:%M\10\10")
    ImGui.Dummy(1, 10); ImGui.Dummy(150, 1); ImGui.SameLine();
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 80)
    UI.ColoredButton(tostring(date_str), '#A67C00', '#A67C00', '#A67C00', 0.15)
    ImGui.PopStyleVar()
    if UI.IsItemClicked('lmb') then
        debug_counter = debug_counter + 1
        if debug_counter == 7 then
            UI.WidgetSound("Nav")
            log.debug("Debug mode activated.")
            SS_debug = true
            CFG:SaveItem("SS_debug", SS_debug)
        elseif debug_counter > 7 then
            UI.WidgetSound("Cancel")
            log.debug("Debug mode deactivated.")
            SS_debug      = false
            debug_counter = 0
            CFG:SaveItem("SS_debug", SS_debug)
        end
    end
    ImGui.Dummy(1, 10); ImGui.SeparatorText("About")
    UI.WrappedText("A collection of scripts aimed towards adding some roleplaying and fun elements to the game.", 25)
    ImGui.Dummy(1, 10)
    ImGui.BulletText(string.format("Script Version:   v%s", SCRIPT_VERSION))
    ImGui.BulletText(string.format("Game Version:   b%s   Online %s", TARGET_BUILD, TARGET_VERSION))
    if not disable_quotes then
        ImGui.Dummy(1, 20); ImGui.SeparatorText("Quote Of The Day"); ImGui.Spacing()
        UI.ColoredText(random_quote, "white", quote_alpha, 24)
    end
end
