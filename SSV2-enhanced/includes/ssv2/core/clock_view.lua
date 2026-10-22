-- Original SSV2 analog clock. Copyright (C) 2026 SAMURAI & Contributors.
-- GPL-3.0-or-later.
return function()
    local now = os.date('*t')
    local seconds = now.sec; local minutes = now.min + seconds / 60; local hours = now.hour % 12 + minutes / 60
    local list = ImGui.GetWindowDrawList(); local x, y = ImGui.GetCursorScreenPos()
    local cx, cy = x + ImGui.GetContentRegionAvail() / 2, y + 100; local radius = 90
    list:AddCircleFilled(cx, cy, radius, 0, 0, 0, 77)
    list:AddText(cx - 20, cy + 15, os.date('%b') .. ' ' .. now.day, 255, 255, 255, 255, ImGui.GetFontSize() * 0.8)
    for i = 0, 11 do
        local angle = i / 12 * math.pi * 2 - math.pi / 2; local cos, sin = math.cos(angle), math.sin(angle)
        list:AddLine(cx + cos * (radius - 10), cy + sin * (radius - 10), cx + cos * radius, cy + sin * radius, 255, 0, 0,
            255, 2)
        local label = tostring(i == 0 and 12 or i); local w, h = ImGui.CalcTextSize(label)
        list:AddText(cx + cos * (radius - 22) - w / 2, cy + sin * (radius - 22) - h / 2, label, 255, 255, 255, 255,
            ImGui.GetFontSize())
    end
    for i = 0, 59 do
        local angle = i / 60 * math.pi * 2 - math.pi / 2; local cos, sin = math.cos(angle), math.sin(angle)
        list:AddLine(cx + cos * (radius - 2.5), cy + sin * (radius - 2.5), cx + cos * radius, cy + sin * radius, 255, 255,
            255, 153, 1)
    end
    for _, hand in ipairs({ { hours / 12, 0.5, 4, 255 }, { minutes / 60, 0.7, 3, 255 }, { seconds / 60, 0.9, 2, 0 } }) do
        local angle = hand[1] * math.pi * 2 - math.pi / 2
        list:AddLine(cx, cy, cx + math.cos(angle) * radius * hand[2], cy + math.sin(angle) * radius * hand[2], 255,
            hand[4], hand[4], 255, hand[3])
    end
    ImGui.Dummy(200, 200)
end
