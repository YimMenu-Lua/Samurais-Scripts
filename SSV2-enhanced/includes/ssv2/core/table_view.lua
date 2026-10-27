-- Original read-only TableRenderer. Copyright (C) 2026 SAMURAI & Contributors.
-- GPL-3.0-or-later.
local View = {}
local colors = { boolean = { 0, 0, 1, 1 }, number = { 1, 1, 0.4, 1 }, string = { 1, 0.65, 0, 1 } }
local purple = { 0.5, 0, 0.5, 1 }
local function object(value, key)
    local c = colors[type(value)] or purple
    local text = type(value) == 'string' and '"' .. value .. '"' or tostring(value)
    if key then
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 0, 0); ImGui.TextColored(purple[1], purple[2], purple[3], purple
            [4], '['); ImGui.SameLine()
    end
    ImGui.TextColored(c[1], c[2], c[3], c[4], text)
    if key then
        ImGui.SameLine(); ImGui.TextColored(purple[1], purple[2], purple[3], purple[4], ']'); ImGui.PopStyleVar()
    end
end
local function value(item, seen)
    if type(item) ~= 'table' then
        object(item, false); return
    end
    if seen[item] then
        ImGui.TextColored(1, 0, 0, 1, '<circular_reference>'); return
    end
    seen[item] = true; ImGui.Text('{'); ImGui.Indent()
    for key, member in pairs(item) do
        object(key, true); ImGui.SameLine(); ImGui.Text('='); ImGui.SameLine(); value(member, seen)
    end
    ImGui.Unindent(); ImGui.Text('}')
end
function View.draw(data, width, height)
    ImGui.PushStyleColor(ImGuiCol.ChildBg, 0.01, 0, 0, 1); ImGui.PushStyleVar(ImGuiStyleVar.ScrollbarSize, 11.3)
    if ImGui.BeginChild('##tableRenderer', width, height, true) then value(data, {}) end
    ImGui.EndChild(); ImGui.PopStyleColor(); ImGui.PopStyleVar()
end

return View
