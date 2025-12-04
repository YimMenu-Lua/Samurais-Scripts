local debug_counter = GVars.backend.debug_mode and 7 or 0
local function DrawClock()
    local now = os.date("*t")
    local month = os.date("%b")
    local day = now.day
    local seconds = now.sec
    local minutes = now.min + seconds / 60
    local hours = now.hour % 12 + minutes / 60
    local ImDrawList = ImGui.GetWindowDrawList()
    local cursorPosX, cursorPosY = ImGui.GetCursorScreenPos()
    local region_width, _ = ImGui.GetContentRegionAvail()
    local size = 200
    local radius = size / 2 - 10
    local center = vec2:new(
        cursorPosX + (region_width / 2),
        cursorPosY + size / 2
    )

    ImGui.ImDrawListAddCircleFilled(
        ImDrawList,
        center.x,
        center.y,
        radius,
        ImGui.GetColorU32(0, 0, 0, 0.3)
    )

    ImGui.SetWindowFontScale(0.8)
    ImGui.ImDrawListAddText(
        ImDrawList,
        center.x - 20,
        center.y + 15,
        ImGui.GetColorU32(255, 255, 255, 255),
        _F("%s %s", month, day)
    )
    ImGui.SetWindowFontScale(1.0)

    for i = 0, 11, 1 do
        local angle = i / 12 * 2 * math.pi - math.pi / 2
        local x1 = center.x + math.cos(angle) * (radius - 10)
        local y1 = center.y + math.sin(angle) * (radius - 10)
        local x2 = center.x + math.cos(angle) * radius
        local y2 = center.y + math.sin(angle) * radius

        ImGui.ImDrawListAddLine(
            ImDrawList,
            x1,
            y1,
            x2,
            y2,
            ImGui.GetColorU32(255, 0, 0, 255),
            2
        )

        local label = tostring((i == 0) and 12 or i)
        local text_width, text_height = ImGui.CalcTextSize(label)
        local text_x = center.x + math.cos(angle) * (radius - 22) - text_width / 2
        local text_y = center.y + math.sin(angle) * (radius - 22) - text_height / 2

        ImGui.ImDrawListAddText(
            ImDrawList,
            text_x,
            text_y,
            ImGui.GetColorU32(255, 255, 255, 255),
            label
        )
    end

    for i = 0, 59, 1 do
        local angle = i / 60 * 2 * math.pi - math.pi / 2
        local x1 = center.x + math.cos(angle) * (radius - 2.5)
        local y1 = center.y + math.sin(angle) * (radius - 2.5)
        local x2 = center.x + math.cos(angle) * radius
        local y2 = center.y + math.sin(angle) * radius

        ImGui.ImDrawListAddLine(
            ImDrawList,
            x1,
            y1,
            x2,
            y2,
            ImGui.GetColorU32(255, 255, 255, 0.6),
            1
        )
    end

    do
        local angle = (hours / 12) * 2 * math.pi - math.pi / 2
        local length = radius * 0.5
        local x = center.x + math.cos(angle) * length
        local y = center.y + math.sin(angle) * length

        ImGui.ImDrawListAddLine(
            ImDrawList,
            center.x,
            center.y,
            x,
            y,
            ImGui.GetColorU32(255, 255, 255, 255),
            4
        )
    end

    do
        local angle = (minutes / 60) * 2 * math.pi - math.pi / 2
        local length = radius * 0.7
        local x = center.x + math.cos(angle) * length
        local y = center.y + math.sin(angle) * length

        ImGui.ImDrawListAddLine(
            ImDrawList,
            center.x,
            center.y,
            x,
            y,
            ImGui.GetColorU32(255, 255, 255, 255),
            3
        )
    end

    do
        local angle = (seconds / 60) * 2 * math.pi - math.pi / 2
        local length = radius * 0.9
        local x = center.x + math.cos(angle) * length
        local y = center.y + math.sin(angle) * length

        ImGui.ImDrawListAddLine(
            ImDrawList,
            center.x,
            center.y,
            x,
            y,
            ImGui.GetColorU32(255, 0, 0, 255),
            2
        )
    end

    ImGui.Dummy(size, size)
end

GUI:GetMainTab():RegisterGUI(function()
    DrawClock()
    ImGui.Dummy(1, 10)
    ImGui.SeparatorText("About")

    if GUI:IsItemClicked(GUI.MouseButtons.LEFT) then
        debug_counter = debug_counter + 1
        if (debug_counter == 7) then
            GUI:PlaySound(GUI.Sounds.Nav)
            log.debug("Debug mode activated.")
            GVars.backend.debug_mode = true
        elseif debug_counter > 7 then
            GUI:PlaySound(GUI.Sounds.Cancel)
            log.debug("Debug mode deactivated.")
            GVars.backend.debug_mode = false
            debug_counter = 0
        end
    end

    ImGui.Text("A Lua base for YimMenu V1.\nCross-compatibility with V2 may be added in the future.")
    ImGui.Dummy(1, 10)
    ImGui.Separator()

    ImGui.SetNextWindowBgAlpha(0)
    if ImGui.BeginChild("footer", -1, 40, false) then
        ImGui.Spacing()
        ImGui.TextDisabled(("v%s"):format(Backend.__version))
        ImGui.EndChild()
    end
end)
