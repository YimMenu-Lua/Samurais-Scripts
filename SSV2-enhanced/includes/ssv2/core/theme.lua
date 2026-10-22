local Widgets = require('includes.ssv2.core.widgets')
local builtins = require('includes.ssv2.data.themes')
local Settings = require('includes.ssv2.core.settings')
local Theme = {}; Theme.__index = Theme
local function copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}; for key, item in pairs(value) do result[key] = copy(item) end; return result
end
function Theme.new(ctx)
    return setmetatable({ ctx = ctx, store = Settings.new({ themes = {} }, 'ssv2/themes.json'), stack = {}, new_name = '' },
        Theme)
end

function Theme:library()
    local result = {}; for name, value in pairs(builtins) do result[name] = value end
    for name, value in pairs(self.store.data.themes) do result[name] = value end
    return result
end

function Theme:current()
    if self.draft and self.live_edit then return self.draft end
    local name = self.ctx.settings:get('ui.style.theme') or 'Synthwave'
    if self.current_name ~= name then
        self.current_name = name; self.value = copy(self:library()[name] or builtins.Synthwave)
    end
    return self.value
end

function Theme:push()
    local value = self:current(); local entry = { colors = 0, styles = 0 }
    for key, color in pairs(value.Colors or {}) do
        local index = ImGuiCol[key]
        if index ~= nil then
            ImGui.PushStyleColor(index, color.x, color.y, color.z, color.w); entry.colors = entry.colors + 1
        end
    end
    for key, style in pairs(value.Styles or {}) do
        local index = ImGuiStyleVar[key]
        if index ~= nil then
            if type(style) == 'table' then
                ImGui.PushStyleVar(index, style.x, style.y)
            else
                ImGui.PushStyleVar(index,
                    style)
            end
            entry.styles = entry.styles + 1
        end
    end
    self.stack[#self.stack + 1] = entry
end

function Theme:pop()
    local entry = table.remove(self.stack); assert(entry, 'Theme stack is empty')
    if entry.styles > 0 then ImGui.PopStyleVar(entry.styles) end
    if entry.colors > 0 then ImGui.PopStyleColor(entry.colors) end
end

function Theme:save(name, draft)
    assert(type(name) == 'string' and name:find('%S'), 'Enter a theme name')
    assert(not builtins[name], 'Built-in theme names are reserved')
    local values = copy(self.store.data.themes); local value = copy(draft or self:current()); value.Name = name
    values[name] = value; self.store:set('themes', values); self.store:save()
    self.ctx.settings:set('ui.style.theme', name); self.current_name = nil
end

function Theme:validate(value)
    local function luminance(color)
        local function linear(v) return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
        return 0.2126 * linear(color.x) + 0.7152 * linear(color.y) + 0.0722 * linear(color.z)
    end
    local function ratio(a, b)
        local x, y = luminance(a), luminance(b); return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05)
    end
    local errors = {}; local visible = false
    for _, color in pairs(value.Colors) do
        if color.w > 0 then
            visible = true; break
        end
    end
    if not visible then errors[#errors + 1] = 'All colors are invisible! This theme will break the UI.' end
    local text = ratio(value.Colors.Text, value.Colors.WindowBg)
    local border = ratio(value.Colors.Border, value.Colors.WindowBg)
    if text < 4.5 then errors[#errors + 1] = string.format('Text contrast too low (%.2f)', text) end
    if border < 1.5 then errors[#errors + 1] = string.format('Border contrast too low (%.2f)', border) end
    return #errors == 0, errors
end

function Theme:remove(name)
    assert(not builtins[name], 'Built-in themes cannot be removed')
    local values = copy(self.store.data.themes); values[name] = nil; self.store:set('themes', values); self.store:save()
    if self.current_name == name then
        self.ctx.settings:set('ui.style.theme', 'Synthwave'); self.current_name = nil
    end
end

function Theme:draw()
    local ctx = self.ctx; local tr = ctx.translator
    local alpha, changed = ImGui.SliderFloat(tr:text('SETTINGS_WINDOW_ALPHA'), ctx.settings:get('ui.style.bg_alpha'),
        0.01, 1)
    if changed then ctx.settings:set('ui.style.bg_alpha', alpha) end
    ImGui.SameLine(); ImGui.Text(string.format('(%d%%)', math.floor(alpha * 100)))
    local name = ctx.settings:get('ui.style.theme')
    if ImGui.BeginCombo(tr:text('SETTINGS_WINDOW_THEME'), name) then
        for key in pairs(self:library()) do
            local custom = self.store.data.themes[key] ~= nil; local label = (custom and '{..} ' or '') .. key
            ImGui.PushID(key); ImGui.Selectable(label, key == name)
            if ImGui.IsItemClicked(0) then
                ctx.settings:set('ui.style.theme', key); self.current_name = nil
            end
            if custom then
                if ImGui.IsItemClicked(1) then ImGui.OpenPopup('delete theme') end
                Widgets.tooltip(ctx, tr:text('SETTINGS_JSON_THEME_DELETE'))
                if ImGui.BeginPopup('delete theme') then
                    if ImGui.MenuItem(tr:text('GENERIC_DELETE')) then self:remove(key) end; ImGui.EndPopup()
                end
            end
            ImGui.PopID()
        end
        ImGui.EndCombo()
    end
    ImGui.Spacing()
    if Widgets.button(self.ctx, tr:text('SETTINGS_WINDOW_NEW_THEME')) then
        self.draft = copy(self:current()); self.draft.Name = ''; self.editor_open = true
    end
    if self.editor_open then self:draw_editor() end
end

function Theme:draw_editor()
    local tr = self.ctx.translator; local value = self.draft
    local flags = bit.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoResize,
        ImGuiWindowFlags.AlwaysAutoResize)
    local _, draw = ImGui.Begin('##new_theme', true, flags)
    if draw then
        if Widgets.quick_config(self.ctx, tr:text('SETTINGS_WINDOW_NEW_THEME'), function()
                self.editor_open = false; self.draft = nil; self.live_edit = false; self.current_name = nil
            end, true) then
            local _, screen_height = ImGui.GetDisplaySize()
            if ImGui.BeginChild('##new_theme_scroll_region', self.ctx.settings:get('ui.width') * 0.65, screen_height * 0.75, false) then
                self.live_edit = require('includes.ssv2.core.widgets').toggle(self.ctx,
                    tr:text('SETTINGS_NEW_THEME_LIVE_EDIT'), self.live_edit or false)
                ImGui.Spacing()
                if self.focus_name then
                    ImGui.SetScrollHereY(); ImGui.SetKeyboardFocusHere(); value.Name = ''; self.focus_name = false
                end
                local name = Widgets.input_text(self.ctx, tr:text('SETTINGS_NEW_THEME_NAME'), value.Name)
                value.Name = require('includes.ssv2.core.widgets').validated_text(value.Name, name, 128)
                ImGui.Spacing(); Widgets.header(tr:text('SETTINGS_NEW_THEME_COLORS'))
                if ImGui.BeginChild('##colors', 0, ImGui.GetWindowHeight() * 0.34, false, ImGuiWindowFlags.AlwaysUseWindowPadding) then
                    for _, key in ipairs({ 'SSAccent', 'SSGradient' }) do
                        local color = value[key]; local edited = ImGui.ColorEdit4(
                            key == 'SSAccent' and 'Custom Accent' or 'Accent Gradient', { color.x, color.y, color.z, color.w }); value[key] = {
                            x =
                                edited[1],
                            y = edited[2],
                            z = edited[3],
                            w = edited[4]
                        }
                    end
                    for key, color in pairs(value.Colors) do
                        local edited = ImGui.ColorEdit4(key, { color.x, color.y, color.z, color.w }); value.Colors[key] = {
                            x =
                                edited[1],
                            y = edited[2],
                            z = edited[3],
                            w = edited[4]
                        }
                    end
                end
                ImGui.EndChild(); ImGui.Spacing(); Widgets.header(tr:text('SETTINGS_NEW_THEME_STYLE'))
                if ImGui.BeginChild('##style', 0, ImGui.GetWindowHeight() * 0.34, false, ImGuiWindowFlags.AlwaysUseWindowPadding) then
                    for key, style in pairs(value.Styles) do
                        if type(style) == 'number' then
                            value.Styles[key] = ImGui.SliderFloat(key, style, 0, 20)
                        else
                            ImGui.Text(key); ImGui.SetNextItemWidth(160); local x = ImGui.SliderFloat('X##' .. key,
                                style.x, 1, 20); ImGui.SameLine(); ImGui.SetNextItemWidth(160); local y = ImGui
                                .SliderFloat('Y##' .. key, style.y, 1, 20); value.Styles[key] = { x = x, y = y }
                        end
                    end
                end
                ImGui.EndChild(); ImGui.Spacing()
                local disabled = not value.Name:find('%S'); ImGui.BeginDisabled(not not disabled)
                if Widgets.button(self.ctx, tr:text('GENERIC_SAVE'), 0, 35) and not disabled then
                    if self:library()[value.Name] then
                        self.ctx.notifier:error(tr:text('GENERIC_SETTINGS_LABEL'),
                        tr:format('SETTINGS_NEW_THEME_NAME_ERR', value.Name), 5); self.focus_name = true
                    else
                        local valid, errors = self:validate(value)
                        if valid then
                            self:save(value.Name, value); self.editor_open = false; self.draft = nil
                        else
                            self.errors = errors; ImGui.OpenPopup('##newColorBadContrast')
                        end
                    end
                end
                ImGui.EndDisabled()
                if disabled then Widgets.tooltip(self.ctx, tr:text('SETTINGS_NEW_THEME_NAME_EMPTY')) end
                local _, popup = ImGui.BeginPopupModal('##newColorBadContrast', true, ImGuiWindowFlags.AlwaysAutoResize)
                if popup then
                    ImGui.Text(tr:text('SETTINGS_NEW_THEME_CONTRAST_ERR')); ImGui.Spacing(); ImGui.Indent(); for _, message in ipairs(self.errors or {}) do
                        ImGui.BulletText(message)
                    end; ImGui.Unindent(); ImGui.Separator(); ImGui.Spacing(); if Widgets.button(self.ctx, 'OK', 80, 35) then
                        self.errors = {}; ImGui.CloseCurrentPopup()
                    end; ImGui.EndPopup()
                end
            end
            ImGui.EndChild()
        end
    end
    ImGui.End()
end

return Theme
