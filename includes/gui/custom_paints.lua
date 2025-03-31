---@diagnostic disable

local i_CustomPaintIndex   = 0
local i_PaintsColSortIndex = 0
local i_PaintsMfrSortIndex = 0
local i_PaintsSortbySwitch = 0

local function SortCustomPaints()
    filteredPaints = {}
    for _, v in ipairs(t_CustomPaints) do
        if i_PaintsSortbySwitch == 0 then
            if i_PaintsColSortIndex == 0 then
                if string.find((v.name):lower(), custom_paints_sq:lower()) then
                    table.insert(filteredPaints, v)
                end
            else
                if v.shade == t_CustomPintShades[i_PaintsColSortIndex + 1] then
                    if string.find((v.name):lower(), custom_paints_sq:lower()) then
                        table.insert(filteredPaints, v)
                    end
                end
            end
        elseif i_PaintsSortbySwitch == 1 then
            if i_PaintsMfrSortIndex == 0 then
                if string.find((v.name):lower(), custom_paints_sq:lower()) then
                    table.insert(filteredPaints, v)
                end
            else
                if v.manufacturer == t_CustomPaintsManufacturers[i_PaintsMfrSortIndex + 1] then
                    if string.find((v.name):lower(), custom_paints_sq:lower()) then
                        table.insert(filteredPaints, v)
                    end
                end
            end
        end
    end
    table.sort(filteredPaints, function(a, b)
        return a.name < b.name
    end)
end

local function DisplayCustomPaints()
    SortCustomPaints()
    local customPaintNames = {}
    for _, v in ipairs(filteredPaints) do
        table.insert(customPaintNames, v.name)
    end
    i_CustomPaintIndex, isChanged = ImGui.ListBox(
        "##customPaintsList",
        i_CustomPaintIndex,
        customPaintNames,
        #filteredPaints
    )
end

local function ShowCustomPaintsCount()
    if filteredPaints ~= nil then
        ImGui.Text(string.format("[ %d ]", #filteredPaints))
    else
        ImGui.Text("[ 0 ]")
    end
end

function CustomPaintsUI()
    if Self.Vehicle.Current == 0 then
        ImGui.Dummy(1, 5); ImGui.Text(_T("GET_IN_VEH_WARNING_"))
    else
        ImGui.BulletText(_T("SORT_BY_TXT_")); ImGui.SameLine()
        i_PaintsSortbySwitch, isChanged = ImGui.RadioButton(_T("SORT_BY_COLOR_TXT_"), i_PaintsSortbySwitch, 0); ImGui
            .SameLine(); ImGui
            .Dummy(35, 1)
        if isChanged then
            UI.widgetSound("Nav")
        end
        ImGui.SameLine(); i_PaintsSortbySwitch, isChanged = ImGui.RadioButton(_T("SORT_BY_MFR_TXT_"),
            i_PaintsSortbySwitch, 1)
        if isChanged then
            UI.widgetSound("Nav")
        end
        ImGui.PushItemWidth(180)
        if i_PaintsSortbySwitch == 0 then
            ImGui.Dummy(20, 1); ImGui.SameLine()
            i_PaintsColSortIndex, sortbyUsed = ImGui.Combo("##sortpaintjobs", i_PaintsColSortIndex, t_CustomPintShades,
                #t_CustomPintShades)
            if sortbyUsed then
                UI.widgetSound("Nav")
                i_CustomPaintIndex = 0
            end
            ImGui.SameLine(); ShowCustomPaintsCount()
        else
            ImGui.Dummy(120, 1); ImGui.SameLine(); ShowCustomPaintsCount(); ImGui.SameLine()
            i_PaintsMfrSortIndex, sortbyMfrUsed = ImGui.Combo("##sortpaintjobs2", i_PaintsMfrSortIndex, t_CustomPaintsManufacturers,
                #t_CustomPaintsManufacturers)
            if sortbyMfrUsed then
                UI.widgetSound("Nav")
                i_CustomPaintIndex = 0
            end
        end
        ImGui.PopItemWidth()
        ImGui.PushItemWidth(420)
        custom_paints_sq, cpsqUsed = ImGui.InputTextWithHint("##custompaintssq", _T("GENERIC_SEARCH_HINT_"),
            custom_paints_sq, 64)
        is_typing = ImGui.IsItemActive()
        DisplayCustomPaints()
        ImGui.PopItemWidth()
        local selected_paint = filteredPaints[i_CustomPaintIndex + 1]
        ImGui.Spacing()
        ImGui.BeginDisabled(selected_paint == nil)
        mf_overwrite, movwUsed = ImGui.Checkbox(_T("CUSTOM_PAINT_MATTE_CB_"),
            selected_paint ~= nil and selected_paint.m or false)
        UI.Tooltip(_T("APPLY_MATTE_DESC_"))
        if movwUsed then
            UI.widgetSound("Nav2")
            selected_paint.m = not selected_paint.m
        end
        ImGui.Separator()
        is_primary, isPused = ImGui.Checkbox(_T("COL_PRIMARY_CB_"), is_primary); ImGui.SameLine()
        is_secondary, isSused = ImGui.Checkbox(_T("COL_SECONDARY_CB_"), is_secondary)
        if isPused or isSused then
            UI.widgetSound("Nav2")
        end
        local text_x, _ = ImGui.CalcTextSize(_T("GENERIC_CONFIRM_BTN_"))
        if ImGui.Button(_T("GENERIC_CONFIRM_BTN_"), text_x + 20, 40) and selected_paint ~= nil then
            if not is_primary and not is_secondary then
                UI.widgetSound("Error")
                YimToast:ShowError("Samurai's Scripts", _T("CUSTOM_PAINT_NOT_SELECTED_ERR_"))
            else
                UI.widgetSound("Select")
                Game.Vehicle.SetCustomPaint(Self.Vehicle.Current, selected_paint.hex, selected_paint.p, selected_paint.m,
                    is_primary,
                    is_secondary)
            end
        end
        ImGui.EndDisabled()
        if selected_paint ~= nil then
            UI.Tooltip(_T("SAVE_PAINT_DESC_"))
        end
    end
end
