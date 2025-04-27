---@diagnostic disable

local selected_paint
local i_CustomPaintIndex   = 0
local i_PaintsColSortIndex = 0
local i_PaintsMfrSortIndex = 0
local i_PaintsSortbySwitch = 0
local s_PaintSearchQuery   = ""
local b_MattePaint         = false
local b_IsPrimary          = false
local b_IsSecondary        = false


local function SortCustomPaints()
    local filteredPaints = {}
    for _, v in ipairs(t_CustomPaints) do
        if i_PaintsSortbySwitch == 0 then
            if i_PaintsColSortIndex == 0 then
                if string.find((v.name):lower(), s_PaintSearchQuery:lower()) then
                    table.insert(filteredPaints, v)
                end
            else
                if v.shade == t_CustomPintShades[i_PaintsColSortIndex + 1] then
                    if string.find((v.name):lower(), s_PaintSearchQuery:lower()) then
                        table.insert(filteredPaints, v)
                    end
                end
            end
        elseif i_PaintsSortbySwitch == 1 then
            if i_PaintsMfrSortIndex == 0 then
                if string.find((v.name):lower(), s_PaintSearchQuery:lower()) then
                    table.insert(filteredPaints, v)
                end
            else
                if v.manufacturer == t_CustomPaintsManufacturers[i_PaintsMfrSortIndex + 1] then
                    if string.find((v.name):lower(), s_PaintSearchQuery:lower()) then
                        table.insert(filteredPaints, v)
                    end
                end
            end
        end
    end
    table.sort(filteredPaints, function(a, b)
        return a.name < b.name
    end)

    return filteredPaints
end

local function DisplayCustomPaints()
    filteredPaints = SortCustomPaints()
    if ImGui.BeginListBox("##CustomPaints", 420, 0) then
        for i = 1, #filteredPaints do
            local is_selected = (i_CustomPaintIndex == i - 1)
            if ImGui.Selectable(filteredPaints[i].name, is_selected) then
                i_CustomPaintIndex = i - 1
            end
            if ImGui.IsItemHovered() then
                ImGui.SetNextWindowSize(220, 140)
                ImGui.BeginTooltip()
                local r, g, b, a = ImCol(filteredPaints[i].hex)
                ImGui.SetNextWindowBgAlpha(1.0)
                ImGui.PushStyleColor(ImGuiCol.ChildBg, r, g, b, a)
                ImGui.BeginChild("##colDisplay", 0, 80)
                ImGui.EndChild()
                ImGui.PopStyleColor()
                ImGui.Spacing()
                ImGui.SetWindowFontScale(0.7)
                ImGui.BulletText("Colors look different in-game.")
                ImGui.SetWindowFontScale(1.0)
                ImGui.EndTooltip()
            end

            if is_selected then
                selected_paint = filteredPaints[i_CustomPaintIndex + 1]
                ImGui.SetItemDefaultFocus()
            end
        end
        ImGui.EndListBox()
    end
end

local function ShowCustomPaintsCount()
    ImGui.Text(
        string.format(
            "[ %d ]",
            filteredPaints and #filteredPaints or 0
        )
    )
end

function CustomPaintsUI()
    if Self.Vehicle.Current == 0 then
        ImGui.Dummy(1, 5); ImGui.Text(_T("GET_IN_VEH_WARNING_"))
    else
        ImGui.BulletText(_T("SORT_BY_TXT_")); ImGui.SameLine()
        i_PaintsSortbySwitch, isChanged = ImGui.RadioButton(_T("SORT_BY_COLOR_TXT_"), i_PaintsSortbySwitch, 0)
        ImGui.SameLine()
        ImGui.Dummy(35, 1)
        if isChanged then
            UI.WidgetSound("Nav")
        end
        ImGui.SameLine(); i_PaintsSortbySwitch, isChanged = ImGui.RadioButton(_T("SORT_BY_MFR_TXT_"),
            i_PaintsSortbySwitch, 1)
        if isChanged then
            UI.WidgetSound("Nav")
        end
        ImGui.PushItemWidth(180)
        if i_PaintsSortbySwitch == 0 then
            ImGui.Dummy(20, 1); ImGui.SameLine()
            i_PaintsColSortIndex, sortbyUsed = ImGui.Combo("##sortpaintjobs", i_PaintsColSortIndex, t_CustomPintShades,
                #t_CustomPintShades)
            if sortbyUsed then
                UI.WidgetSound("Nav")
                i_CustomPaintIndex = 0
            end
            ImGui.SameLine(); ShowCustomPaintsCount()
        else
            ImGui.Dummy(120, 1); ImGui.SameLine(); ShowCustomPaintsCount(); ImGui.SameLine()
            i_PaintsMfrSortIndex, sortbyMfrUsed = ImGui.Combo("##sortpaintjobs2", i_PaintsMfrSortIndex, t_CustomPaintsManufacturers,
                #t_CustomPaintsManufacturers)
            if sortbyMfrUsed then
                UI.WidgetSound("Nav")
                i_CustomPaintIndex = 0
            end
        end
        ImGui.PopItemWidth()
        ImGui.PushItemWidth(420)
        s_PaintSearchQuery, cpsqUsed = ImGui.InputTextWithHint("##custompaintssq", _T("GENERIC_SEARCH_HINT_"),
            s_PaintSearchQuery, 64)
        b_IsTyping = ImGui.IsItemActive()
        ImGui.PopItemWidth()
        DisplayCustomPaints()
        ImGui.Spacing()
        ImGui.BeginDisabled(selected_paint == nil)
        b_MattePaint, movwUsed = ImGui.Checkbox(_T("CUSTOM_PAINT_MATTE_CB_"),
            selected_paint ~= nil and selected_paint.m or false)
        UI.Tooltip(_T("APPLY_MATTE_DESC_"))
        if movwUsed then
            UI.WidgetSound("Nav2")
            selected_paint.m = not selected_paint.m
        end
        ImGui.Separator()
        b_IsPrimary, isPused = ImGui.Checkbox(_T("COL_PRIMARY_CB_"), b_IsPrimary); ImGui.SameLine()
        b_IsSecondary, isSused = ImGui.Checkbox(_T("COL_SECONDARY_CB_"), b_IsSecondary)
        if isPused or isSused then
            UI.WidgetSound("Nav2")
        end
        local text_x, _ = ImGui.CalcTextSize(_T("GENERIC_CONFIRM_BTN_"))
        if ImGui.Button(_T("GENERIC_CONFIRM_BTN_"), text_x + 20, 40) and selected_paint ~= nil then
            if not b_IsPrimary and not b_IsSecondary then
                UI.WidgetSound("Error")
                YimToast:ShowError("Samurai's Scripts", _T("CUSTOM_PAINT_NOT_SELECTED_ERR_"))
            else
                UI.WidgetSound("Select")
                Game.Vehicle.SetCustomPaint(
                    Self.Vehicle.Current,
                    selected_paint.hex,
                    selected_paint.p,
                    selected_paint.m,
                    b_IsPrimary,
                    b_IsSecondary
                )
            end
        end
        ImGui.EndDisabled()
        if selected_paint ~= nil then
            UI.Tooltip(_T("SAVE_PAINT_DESC_"))
        end
    end
end
