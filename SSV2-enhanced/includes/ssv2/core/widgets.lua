-- Native V2 rendering of SSV2's custom widgets. GPL-3.0-or-later; see LICENSE.
local Widgets = {}
local animations = {}
local function rgba(color, alpha)
    local result = {}
    for i, key in ipairs({ 'x', 'y', 'z', 'w' }) do
        local value = color[key] or color[i] or (i == 4 and 1 or 0)
        if i == 4 and alpha then value = value * alpha end
        result[i] = math.floor(math.max(0, math.min(1, value)) * 255 + 0.5)
    end
    return unpack(result)
end
local function packed(color)
    return ImGui.ColorConvertRGBAToU32({ rgba(color) })
end
-- Keep RGBA expansion separate from trailing arguments: Lua only expands the last expression.
local function rectangle(list, x1, y1, x2, y2, color, rounding)
    local r, g, b, a = rgba(color)
    list:AddRectFilled(x1, y1, x2, y2, r, g, b, a, rounding or 0)
end
local function circle(list, x, y, radius, color, segments)
    local r, g, b, a = rgba(color)
    list:AddCircleFilled(x, y, radius, r, g, b, a, segments or 0)
end
local function draw_text(list, x, y, label, color, scale)
    local r, g, b, a = rgba(color)
    list:AddText(x, y, label, r, g, b, a, ImGui.GetFontSize() * (scale or 1))
end
Widgets.rgba, Widgets.packed, Widgets.text = rgba, packed, draw_text

-- Input ownership belongs to the field being edited. Mouse-held buttons,
-- sliders and window dragging must not request all game controls.
local function capture_input(ctx, ...)
    if ctx.view then ctx.view.wants_input = ctx.view.wants_input or ImGui.IsItemActive() end
    return ...
end

function Widgets.input_text(ctx, ...)
    return capture_input(ctx, ImGui.InputText(...))
end

function Widgets.input_text_with_hint(ctx, ...)
    return capture_input(ctx, ImGui.InputTextWithHint(...))
end

function Widgets.input_text_multiline(ctx, ...)
    return capture_input(ctx, ImGui.InputTextMultiline(...))
end

function Widgets.input_int(ctx, ...)
    return capture_input(ctx, ImGui.InputInt(...))
end

function Widgets.input_float(ctx, ...)
    return capture_input(ctx, ImGui.InputFloat(...))
end

local function style_color(index)
    local r, g, b, a = ImGui.GetStyleColorVec4(index)
    return { x = r, y = g, z = b, w = a }
end

function Widgets.vertical_separator(thickness)
    thickness = thickness or 1
    ImGui.SameLine()
    local x = ImGui.GetCursorScreenPos()
    local _, y = ImGui.GetWindowPos()
    rectangle(ImGui.GetWindowDrawList(), x, y, x + thickness, y + ImGui.GetWindowHeight(),
        style_color(ImGuiCol.Separator), 0)
    ImGui.Dummy(thickness, 0)
    ImGui.SameLine()
end

-- Text limits belong to the script's field validation. Retaining the last valid
-- value avoids cutting a UTF-8 sequence when a typing/paste result is too long.
function Widgets.validated_text(previous, value, max_bytes)
    assert(type(previous) == 'string' and type(value) == 'string')
    assert(type(max_bytes) == 'number' and max_bytes >= 0)
    if #value > max_bytes then return previous, false end
    return value, value ~= previous
end

function Widgets.same_line_if_available(width)
    if ImGui.GetContentRegionAvail() > width then ImGui.SameLine() end
end

function Widgets.spinner(label, speed)
    local frames = { '_   ', ' _  ', '  _ ', '   _' }
    return (label or '') .. ' ' .. frames[math.floor(ImGui.GetTime() * (speed or 7)) % #frames + 1]
end

function Widgets.button(ctx, label, width, height, repeatable)
    local pressed = ImGui.Button(label, width or 0, height or 0)
    if pressed and not repeatable then ctx.view:play_sound('Button') end
    return pressed
end

function Widgets.checkbox(ctx, label, value)
    local result, changed = ImGui.Checkbox(label, value)
    if changed then ctx.view:play_sound('Checkbox') end
    return result, changed
end

function Widgets.quick_config(ctx, label, on_close, always_center)
    local width, height = ImGui.GetWindowSize(); local screen_width, screen_height = ImGui.GetDisplaySize()
    ImGui.SetWindowPos((screen_width - width) / 2, (screen_height - height) / 2,
        always_center and ImGuiCond.Always or ImGuiCond.Once)
    ImGui.SeparatorText(label)
    if Widgets.button(ctx, 'Close') then
        (on_close or ImGui.CloseCurrentPopup)(); return false
    end
    ImGui.Separator(); ImGui.Dummy(0, 10)
    return true
end

function Widgets.tooltip(ctx, text, color, alpha, wrap_width)
    if ctx.settings:get('ui.disable_tooltips') or not ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then return end
    ImGui.SetNextWindowBgAlpha(ctx.settings:get('ui.style.bg_alpha'))
    ImGui.BeginTooltip()
    if color then
        ImGui.PushStyleColor(ImGuiCol.Text, color.x or color[1], color.y or color[2], color.z or color[3],
            alpha or color.w or color[4] or 1)
    end
    ImGui.PushTextWrapPos(wrap_width or ImGui.GetFontSize() * 25)
    ImGui.TextWrapped(text); ImGui.PopTextWrapPos()
    if color then ImGui.PopStyleColor() end
    ImGui.EndTooltip()
end

function Widgets.help(ctx, text, color)
    if ctx.settings:get('ui.disable_tooltips') then return end
    ImGui.SameLine(); ImGui.TextDisabled('(?)'); Widgets.tooltip(ctx, text, color)
end

function Widgets.header(text, spacing, color, scale)
    if spacing then ImGui.Spacing() end
    if color then
        for _, index in ipairs({ ImGuiCol.Text, ImGuiCol.Separator }) do ImGui.PushStyleColor(index, unpack(color)) end
    end
    ImGui.SetWindowFontScale(scale or 1.114); ImGui.SeparatorText(text); ImGui.SetWindowFontScale(1)
    if color then ImGui.PopStyleColor(2) end
end

function Widgets.dialog(ctx, id, message, severity)
    severity = severity or 0
    local color = severity == 1 and { x = 0.941, y = 0.745, z = 0.007, w = 1 }
        or severity == 2 and { x = 1, y = 0, z = 0, w = 1 } or style_color(ImGuiCol.PopupBg)
    local dark = color.x * 0.299 + color.y * 0.587 + color.z * 0.114 <= 0.5
    local foreground = dark and { 0.9, 0.9, 0.9, 0.87 } or { 0.01, 0.01, 0.01, 0.87 }
    ImGui.SetNextWindowSizeConstraints(440, 200, 440, 600)
    for _, index in ipairs({ ImGuiCol.TitleBg, ImGuiCol.TitleBgActive, ImGuiCol.TitleBgCollapsed }) do
        ImGui
            .PushStyleColor(index, color.x, color.y, color.z, color.w)
    end
    ImGui.PushStyleColor(ImGuiCol.Text, unpack(foreground))
    local _, draw = ImGui.BeginPopupModal(id, true,
        bit.bor(ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoCollapse,
            ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoSavedSettings))
    ImGui.PopStyleColor(4)
    if not draw then return false end
    local width, height = ImGui.GetWindowSize(); local screen_width, screen_height = ImGui.GetDisplaySize()
    ImGui.SetWindowPos((screen_width - width) / 2, (screen_height - height) / 2, ImGuiCond.Always)
    ImGui.Spacing(); ImGui.TextWrapped(message or ctx.translator:text('GENERIC_CONFIRM_WARN')); ImGui.Dummy(0, 40)
    local button_width, spacing = width * 0.3, ImGui.GetStyle().ItemSpacing.x
    if severity > 0 then
        ImGui.PushStyleColor(ImGuiCol.Button, color.x, color.y, color.z, math.max(color.w * 0.8, 0.8))
        ImGui.PushStyleColor(ImGuiCol.ButtonHovered, color.x, color.y, color.z, color.w)
        ImGui.PushStyleColor(ImGuiCol.ButtonActive, color.x, color.y, color.z, math.max(color.w * 0.7, 0.7))
        ImGui.PushStyleColor(ImGuiCol.Text, unpack(foreground))
    end
    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (width - (button_width + spacing) * 3) / 2)
    local confirmed = Widgets.button(ctx, ctx.translator:text('GENERIC_CONFIRM'), button_width, 35)
    if confirmed then ImGui.CloseCurrentPopup() end
    if severity > 0 then ImGui.PopStyleColor(4) end
    ImGui.SameLine(); ImGui.SetCursorPosX(ImGui.GetCursorPosX() + button_width - spacing)
    if Widgets.button(ctx, ctx.translator:text('GENERIC_CANCEL'), button_width, 35) then
        confirmed = false; ImGui.CloseCurrentPopup()
    end
    ImGui.Spacing(); ImGui.EndPopup(); return confirmed
end

function Widgets.search(ctx, id, previous, width, flags, limit)
    ImGui.SetNextItemWidth(width or -1); ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 15, 5)
    local value, changed = Widgets.input_text_with_hint(ctx, id, ctx.translator:text('GENERIC_SEARCH_HINT'), previous, flags or 0)
    ImGui.PopStyleVar()
    local accepted = Widgets.validated_text(previous, value, limit or math.max(#previous + 32, 256))
    return accepted:lower(), changed and accepted ~= previous
end

-- SSV2's readonly ValueBar is a script widget, including vertical and two-value
-- fills. Keep its drawing here rather than replacing it with a generic slider.
function Widgets.value_bar(ctx, id, value, width, height, vertical, second, format, first_color, second_color)
    local theme, style = ctx.theme:current(), ImGui.GetStyle()
    local x, y = ImGui.GetCursorScreenPos()
    width = width and width > 0 and width or ImGui.GetContentRegionAvail()
    height = height or ImGui.GetFrameHeight() - style.FramePadding.y
    local list = ImGui.GetWindowDrawList()
    local rounding = style.FrameRounding or 0
    local fraction = math.max(0, math.min(1, value or 0))
    rectangle(list, x, y, x + width, y + height, style_color(ImGuiCol.FrameBg), rounding)
    local function fill(x1, y1, x2, y2, color, rounding_value, flags)
        if x2 <= x1 or y2 <= y1 then return end
        local r, g, b, a = rgba(color)
        list:AddRectFilled(x1, y1, x2, y2, r, g, b, a, rounding_value, flags)
    end
    local first = first_color or style_color(ImGuiCol.PlotHistogram)
    if fraction > 0 then
        if vertical then
            fill(x, y + (1 - fraction) * height, x + width, y + height, first, rounding, 240)
        else
            fill(x, y, x + width * fraction, y + height, first, rounding, value < 1 and 80 or 240)
        end
    end
    if second and second > 0 then
        local f2 = math.max(0, math.min(1, second))
        local base = style_color(ImGuiCol.PlotHistogram)
        local color = second_color or
            { x = math.min(1, base.x + 0.2), y = math.min(1, base.y + 0.2), z = math.min(1, base.z + 0.2), w = base.w }
        local round2, flags = 0, 0
        if value == 0 then round2, flags = rounding, 80 elseif value + second >= 1 then round2, flags = rounding, 160 end
        if vertical then
            fill(x + width, y + (1 - fraction) * height + (1 - f2) * height, x + width * 2, y + (3 - fraction - f2) *
                height, color, round2, flags)
        else
            fill(x + width * fraction, y, x + width * (fraction + f2), y + height, color, round2, flags)
        end
    end
    local label = format or string.format('%d%%', math.floor((value or 0) * 100))
    local scale = 1; local text_width = width - style.FramePadding.x * 2
    ImGui.SetWindowFontScale(1)
    if ImGui.CalcTextSize(label) > text_width then
        local low, high = 0.6, 1; scale = 0.6
        for _ = 1, 8 do
            local middle = (low + high) * 0.5; ImGui.SetWindowFontScale(middle)
            if ImGui.CalcTextSize(label) <= text_width then
                scale = middle; low = middle
            else
                high = middle
            end
        end
    end
    ImGui.SetWindowFontScale(scale)
    local tw, th = ImGui.CalcTextSize(label)
    draw_text(list, x + (width - tw) * 0.5, y + (height - th) * 0.5, label,
        style_color(style.Alpha < 1 and ImGuiCol.TextDisabled or ImGuiCol.Text))
    ImGui.SetWindowFontScale(1)
    ImGui.Dummy(width, height)
end

function Widgets.toggle(ctx, label, value, active_color)
    local text_height = ImGui.GetTextLineHeight()
    local height = text_height + 0.4
    local frame_height = math.max(height, ImGui.GetFrameHeight())
    local width, x, y = height * 1.8, ImGui.GetCursorScreenPos()
    local offset = (frame_height - height) * 0.5
    local center_y = y + offset + height * 0.5
    ImGui.BeginGroup()
    ImGui.InvisibleButton(label, width, frame_height)
    local clicked = ImGui.IsItemClicked(0)
    local hovered = ImGui.IsItemHovered()
    if clicked then
        value = not value; if ctx.view then ctx.view:play_navigation() end
    end
    local target = value and 1 or 0
    local key = label .. x .. y
    local animation = animations[key]
    animation = (animation or target) + (target - (animation or target)) * 0.17
    animations[key] = animation
    local list = ImGui.GetWindowDrawList()
    local frame = style_color(ImGuiCol.Button)
    local factor = math.abs(frame.x - style_color(ImGuiCol.WindowBg).x) < 0.05 and 0.85 or 1
    local off = { x = frame.x * factor * 0.9, y = frame.y * factor * 0.9, z = frame.z * factor * 0.9, w = frame.w }
    local mark = style_color(ImGuiCol.CheckMark)
    local on = { x = mark.x, y = mark.y, z = mark.z, w = 0.8 }
    local color = value and on or off
    if hovered then color = value and on or style_color(ImGuiCol.ButtonHovered) end
    local radius = height * 0.5
    rectangle(list, x, y + offset, x + width, y + height + offset, color, radius)
    circle(list, x + radius + animation * (width - height), center_y, radius * 0.85,
        style_color(ImGui.GetStyle().Alpha < 1 and ImGuiCol.TextDisabled or ImGuiCol.Text))
    local visible = label:match('^(.-)##') or label
    if visible ~= '' then
        ImGui.SetCursorScreenPos(x + width + 10, center_y - text_height * 0.5)
        ImGui.TextUnformatted(visible)
    end
    ImGui.EndGroup()
    return value, clicked
end

function Widgets.navigation(ctx, id, label, selected, width, height, gradient, underline)
    local theme = ctx.theme:current()
    local x, y = ImGui.GetCursorScreenPos()
    ImGui.InvisibleButton(id, width, height)
    local clicked = ImGui.IsItemClicked(0)
    local hovered = ImGui.IsItemHovered()
    local held = hovered and (ctx.input.held[1] or ImGui.IsItemActive()) or false
    local list = ImGui.GetWindowDrawList()
    local color = style_color(ImGuiCol.Text)
    if selected or hovered then
        local accent = theme.SSAccent
        local first = selected and
            {
                x = accent.x,
                y = accent.y,
                z = accent.z,
                w = held and accent.w - 0.25 or not gradient and hovered and 1 or
                    accent.w
            }
            or { x = 0.31, y = 0.31, z = 0.43, w = held and 0.5 or gradient and 0.7 or 1 }
        local tint = theme.SSGradient
        local second = selected and { x = tint.x, y = tint.y, z = tint.z, w = held and tint.w - 0.25 or 1 }
            or { x = 0.23, y = 0.23, z = 0.31, w = held and 0.39 or 0.58 }
        if gradient then
            local inset = (held or clicked) and 1 or 0
            local a, b = packed(first), packed(second)
            list:AddRectFilledMultiColor(x + inset, y + inset, x + width - inset, y + height - inset, a, a, b, b)
        else
            rectangle(list, x, y + 2, x + width, y + height + 2, { x = 0.01, y = 0.01, z = 0.01, w = 55 / 255 }, 8)
            rectangle(list, x, y, x + width, y + height, first, ImGui.GetStyle().FrameRounding or 0)
        end
        local luminance = first.x * 0.299 + first.y * 0.587 + first.z * 0.114
        color = luminance > 0.5 and { x = 0, y = 0, z = 0, w = 1 } or { x = 1, y = 1, z = 1, w = 1 }
    end
    local clipped = label
    local padding = gradient and 10 or 16
    if ImGui.CalcTextSize(label) >= width - padding then
        while ImGui.CalcTextSize(clipped) > width - padding - ImGui.CalcTextSize('.') and #clipped > 0 do
            clipped = clipped:gsub('[%z\1-\127\194-\244][\128-\191]*$', '')
        end
        clipped = clipped .. '.'
    end
    local tw, th = ImGui.CalcTextSize(clipped)
    draw_text(list, x + (width - tw) * 0.5, y + (height - th) * 0.5, clipped, color)
    if underline and not hovered and not clicked and not selected then
        local shift = clipped ~= label and 4 or 0
        local r, g, b, a = rgba(theme.SSGradient)
        list:AddLine(x + math.max(0, (width - tw) * 0.5) - shift, y + height, x + (width + tw) * 0.5 - shift, y + height,
            r, g, b, a, 1.3)
    end
    if clipped ~= label and hovered and not ctx.settings:get('ui.disable_tooltips') then ImGui.SetTooltip(label) end
    return clicked
end

function Widgets.notification(ctx)
    local x, y = ImGui.GetCursorScreenPos()
    ImGui.BeginGroup()
    local width, height = 27, 22
    local clicked = ImGui.InvisibleButton('##ss_notifications', width, height)
    local hovered = ImGui.IsItemHovered()
    local theme, list = ctx.theme:current(), ImGui.GetWindowDrawList()
    local notifier = ctx.notifier
    local color = style_color(ImGuiCol.Button)
    if not notifier.muted then
        color = style_color(hovered and ImGuiCol.ButtonHovered or
            notifier.open and ImGuiCol.ButtonActive or ImGuiCol.Button)
    end
    local r, g, b, a = rgba(color)
    local base_x, base_y = x + height * 0.27, y + height * 0.95
    list:AddTriangleFilled(base_x, base_y, base_x + height * 0.55, base_y + height * 0.08, base_x - height * 0.45,
        base_y + height * 0.45, r, g, b, a)
    rectangle(list, x - height * 0.25, y - height * 0.1, x + width + height * 0.25, y + height + height * 0.1, color,
        height * 0.55)
    if not notifier.muted then
        local radius = width / 3 * 0.3; local spacing = radius * 3
        for i = 0, 2 do
            circle(list, x + width / 2 - spacing + i * spacing, y + height / 2, radius,
                style_color(ImGuiCol.Text), 12)
        end
        local count = notifier:count()
        if not notifier.viewed and count > 0 then
            local radius = height * 0.32; local bx, by = x + width + radius * 1.25, y + radius * 0.7
            circle(list, bx, by, radius, theme.SSAccent, 12)
            local label = (count > 9 and '+' or '') .. math.min(count, 9)
            ImGui.SetWindowFontScale(0.5); local tw, th = ImGui.CalcTextSize(label); ImGui.SetWindowFontScale(1)
            local c = theme.SSAccent
            local foreground = (c.x * 0.299 + c.y * 0.587 + c.z * 0.114) > 0.5 and { x = 0, y = 0, z = 0, w = 1 } or
                { x = 1, y = 1, z = 1, w = 1 }
            draw_text(list, bx - tw / 2, by - th * 0.75, label, foreground, 14 / ImGui.GetFontSize())
        end
    else
        local r, g, b, a = rgba(style_color(ImGuiCol.TextDisabled))
        list:AddLine(x - 3, y - 3, x + width + 3, y + height + 3, r, g, b, a, 2.4)
    end
    if ImGui.IsItemHovered() and not ctx.settings:get('ui.disable_tooltips') then
        ImGui.SetTooltip(ctx.translator:text('GUI_NOTIFICATIONS', 'Notifications'))
    end
    ImGui.EndGroup(); return clicked
end

return Widgets
