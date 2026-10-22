local View = {}
View.__index = View
local Layout = require('includes.ssv2.data.ui_layout')
local Widgets = require('includes.ssv2.core.widgets')
local control_tooltips = require('includes.ssv2.data.control_tooltips')
local category_labels = {
    self = 'TAB_SELF',
    vehicle = 'TAB_VEHICLE',
    world = 'TAB_WORLD',
    online = 'TAB_ONLINE',
    extra =
    'TAB_EXTRA',
    settings = 'GENERIC_SETTINGS_LABEL'
}
local header_height, sidebar_width, window_gap = 124.2, 200, 10
local binding_labels = {
    gui_toggle = 'Toggle GUI',
    rod = 'SELF_ROD',
    kill_all_enemies = 'WRLD_KILL_ALL',
    laser_sights = 'SELF_LASER_SIGHTS',
    enemies_flee = 'WRLD_FLEE_ALL',
    veh_mine = 'VEH_MINES',
    cobra_maneuver = 'VEH_COBRA_MANEUVER',
    cobra_cancel = 'Cancel Cobra Maneuver',
    nos = 'VEH_NOS',
    nos_purge = 'VEH_NOS_PURGE',
    drift_mode = 'VEH_DRIFT_MODE',
    rolling_launch = 'Rolling Anti-Lag'
}
local function options_from(map)
    local options = { { 'Unbound', 0 } }
    for name, code in pairs(map) do
        if name ~= '(NONE)' then options[#options + 1] = { name, code } end
    end
    table.sort(options, function(a, b) return a[2] == b[2] and a[1] < b[1] or a[2] < b[2] end)
    return options
end
local key_options = options_from(require('includes.ssv2.data.keyboard_keys'))
local controller_options = options_from(require('includes.ssv2.data.gamepad_keys'))

function View.new(ctx)
    local self = setmetatable({ ctx = ctx, open = false, groups = {}, actions = {}, controls = {}, last_pages = {} },
        View)
    if ctx.settings:get('ui.layout_revision') < 1 then
        ctx.settings:set('ui.moveable', true)
        ctx.settings:set('ui.layout_revision', 1)
    end
    local tab = ctx.settings:get('ui.last_tab')
    self.category_index = math.max(1, math.min(#Layout.categories, tab.tab_id))
    self.last_pages[Layout.categories[self.category_index]] = tab.array_index
    ctx.input.blocked = function()
        local forge = ctx.features.entity_forge
        return self.open and self.wants_input or
            ctx.console and (ctx.console.open or util.time() < (ctx.console.input_release_at or 0)) or
            ctx.input.capture ~= nil
            or forge and forge.frontend and forge.frontend.mouse_override or false
    end
    ctx.input:bind('gui_toggle', function() self:toggle() end, true)
    menu.set_menu_name("Samurai's Scripts")
    local hub = menu.get_submenu("Samurai's Scripts"):add_category("Samurai's Scripts"):add_group('Interface')
    hub:add_button('ssv2_open_panel', "Open Samurai's Scripts", 'Toggle with F5', function() self:toggle() end)
    hub:imgui(function()
        ImGui.SetNextWindowBgAlpha(0)
        if ImGui.BeginChild('##dummy_tab_clock', 480, 400, false) then
            require('includes.ssv2.core.clock_view')()
            ImGui.Dummy(1, 10); ImGui.SetWindowFontScale(1.2); ImGui.SeparatorText(ctx.translator:text(
                'GENERIC_IMPORTANT')); ImGui.SetWindowFontScale(1)
            local key = ctx.settings:get('keybinds.gui_toggle.keyboard'); local label = tostring(key)
            for name, code in pairs(require('includes.ssv2.data.keyboard_keys')) do
                if code == key then
                    label = name; break
                end
            end
            ImGui.TextWrapped(ctx.translator:format('GUI_NEW_LAYOUT_NOTICE', label)); ImGui.Spacing()
        end
        ImGui.EndChild(); ImGui.SetNextWindowBgAlpha(0)
        if ImGui.BeginChild('##dummy_tab_footer', 480, 40, false) then
            ImGui.Separator(); ImGui.TextDisabled('SSV2 v' .. require('includes.ssv2.data.version') ..
                (ctx.settings:get('backend.debug_mode') and ' [DEBUG]' or ''))
            if ImGui.IsItemClicked(0) then
                self.debug_clicks = (self.debug_clicks or 0) + 1
                if self.debug_clicks >= 7 then
                    ctx.settings:set('backend.debug_mode', self.debug_clicks == 7); self:play_navigation(); if self.debug_clicks > 7 then self.debug_clicks = 0 end
                end
            end
        end
        ImGui.EndChild()
    end)
    menu.add_always_draw_imgui(function() self:draw() end)
    ctx.runtime.shutdown[#ctx.runtime.shutdown + 1] = function() self:close() end
    return self
end

function View:toggle()
    if self.open then
        self:close()
    else
        self.open = true; self:update_mouse()
    end
end

function View:update_mouse()
    local forge = self.ctx.features.entity_forge
    menu.set_mouse_override(self.open or self.ctx.console and self.ctx.console.open or self.ctx.notifier.open
        or forge and forge.frontend and forge.frontend.mouse_override or false)
end

function View:close(close_parent)
    self.open = false
    self.wants_input = false
    self.header_drag = nil; self.motion = nil; self.option = nil; self.option_requested = nil; self.reset_open = false
    self.ctx.input.capture = nil
    self:update_mouse()
    if close_parent and menu.is_open() then menu.toggle() end
end

function View:add(feature)
    local group = self.groups[feature.category] or {}
    self.groups[feature.category] = group
    group[#group + 1] = feature
    for _, control in ipairs(feature.controls or {}) do
        control.tooltip = control.tooltip or control_tooltips[control.path]
        self.controls[control.path] = { control = control, feature = feature }
    end
end

function View:add_action(category, label, callback)
    local actions = self.actions[category] or {}
    self.actions[category] = actions
    actions[#actions + 1] = { label = label, callback = callback }
end

function View:draw_control(control)
    local settings, translator = self.ctx.settings, self.ctx.translator
    local label = translator:text(control.label) .. '##' .. control.path
    local value, changed
    if control.visible and not control.visible() then return end
    if control.kind == 'toggle' then
        local current
        if control.get then current = control.get() else current = settings:get(control.path) end
        value, changed = Widgets.toggle(self.ctx, label, current)
    elseif control.kind == 'int' then
        local low, high = control.min, control.max
        if control.bounds then low, high = control.bounds() end
        ImGui.BeginDisabled(control.disabled and control.disabled() or false)
        value, changed = ImGui.SliderInt(label, settings:get(control.path), low, high, control.format)
        ImGui.EndDisabled()
    elseif control.kind == 'float' then
        local low, high = control.min, control.max
        if control.bounds then low, high = control.bounds() end
        value, changed = ImGui.SliderFloat(label, settings:get(control.path), low, high, control.format)
    elseif control.kind == 'color' or control.kind == 'color4' then
        value, changed = ImGui.ColorEdit4(label, settings:get(control.path))
    elseif control.kind == 'color3' then
        value, changed = ImGui.ColorEdit3(label, settings:get(control.path))
    elseif control.kind == 'combo' then
        local names = {}
        for _, option in ipairs(control.options) do names[#names + 1] = translator:text(option) end
        value, changed = ImGui.Combo(label, settings:get(control.path), names, #names)
    end
    if changed then
        if control.set then control.set(value) else settings:set(control.path, value) end
        if value == true and control.path == 'features.self.rod' then
            settings:set('features.self.clumsy', false)
        elseif value == true and control.path == 'features.self.clumsy' then
            settings:set('features.self.rod', false)
        end
    end
    if control.tooltip then Widgets.tooltip(self.ctx, translator:text(control.tooltip), control.tooltip_color) end
    return value, changed
end

function View:select_category(index)
    assert(Layout.categories[index], 'Invalid UI category')
    self.category_index = index
    self.ctx.settings:set('ui.last_tab', { tab_id = index, array_index = self.last_pages[Layout.categories[index]] or 1 })
end

function View:select_page(index)
    local category = Layout.categories[self.category_index]
    assert(Layout.pages[category][index], 'Invalid UI page')
    self.last_pages[category] = index
    self.ctx.settings:set('ui.last_tab', { tab_id = self.category_index, array_index = index })
end

function View:play_navigation()
    self:play_sound('Nav')
end

function View:play_sound(kind)
    if not self.ctx.settings:get('ui.disable_sound_feedback') then
        local sound = assert(require('includes.ssv2.data.ui_sounds')[kind], 'Unknown original UI sound')
        self.ctx.runtime:run('UI navigation', function()
            AUDIO.PLAY_SOUND_FRONTEND(-1, sound[1], sound[2], false)
        end)
    end
end

function View:draw_grid(kind)
    local entries = assert(Layout.grids[kind], 'Missing original control grid')
    self.grid_metrics = self.grid_metrics or {}
    local metrics = self.grid_metrics[kind] or { width = 0, height = 0 }; self.grid_metrics[kind] = metrics
    local x, y = ImGui.GetCursorPos(); local start_x = x; local padding = ImGui.GetStyle().ItemSpacing
    for i, entry in ipairs(entries) do
        local control = assert(self.controls[entry.path], 'Missing original control: ' .. entry.path).control
        ImGui.PushID(i); ImGui.SetCursorPos(x, y)
        self:draw_control(control)
        local item_width = ImGui.CalcTextSize(self.ctx.translator:text(control.label)) + 90
        local item_height = math.max(ImGui.GetFrameHeight(), ImGui.GetTextLineHeightWithSpacing()) + padding.y
        ImGui.SetCursorPos(x + item_width - 35, y + 10); ImGui.SetWindowFontScale(0.75)
        if ImGui.SmallButton(' . . . ##' .. entry.path) then
            self.option = entry; self.option_requested = true
        end
        ImGui.SetWindowFontScale(1)
        Widgets.tooltip(self.ctx, self.ctx.translator:text('GENERIC_OPTIONS_LABEL'))
        metrics.width = math.max(metrics.width, item_width + padding.x)
        ImGui.SameLine()
        if x + metrics.width > ImGui.GetContentRegionAvail() then
            x = start_x; y = y + item_height
        else
            x = x + metrics.width
        end
        metrics.height = math.max(metrics.height, item_height)
        ImGui.PopID()
    end
    ImGui.Spacing()
end

function View:draw_tool(id)
    local feature = assert(self.ctx.features[id], 'Missing original tool: ' .. id)
    for _, control in ipairs(feature.controls) do
        if control.path == 'features.unsafe_feats_enabled' then
            -- The source places this guarded setting in General settings.
        elseif control.path:match('^ui%.show_') then
            if not self.ctx.settings:get(control.path) then self.ctx.settings:set(control.path, true) end
        elseif id ~= 'businesses' and not feature.owns_controls then
            self:draw_control(control)
        end
    end
    if feature.requires_build and not self.ctx.build.compatible and not feature.owns_controls then
        ImGui.TextWrapped('Requires Enhanced ' ..
            self.ctx.build.expected_build .. ' / online ' .. self.ctx.build.expected_online)
    end
    if feature.draw then feature:draw() end
    if feature.error then ImGui.TextWrapped('Disabled after an error. See the menu log; enabling retries the feature.') end
end

function View:draw_page(page)
    if page.settings then
        if ImGui.BeginTabBar('ssv2_settings') then
            for _, tab in ipairs({ { 'GENERIC_GENERAL_LABEL', 'general' }, { 'SUBTAB_GUI', 'gui' }, { 'SETTINGS_KEYBINDS', 'keybinds' }, { 'Debug', 'debug' } }) do
                if tab[2] ~= 'debug' or self.ctx.settings:get('backend.debug_mode') then
                    if ImGui.BeginTabItem(self.ctx.translator:text(tab[1])) then
                        self:draw_settings(tab[2]); ImGui.EndTabItem()
                    end
                end
            end
            ImGui.EndTabBar()
        end
    elseif page.tabs then
        if ImGui.BeginTabBar('ssv2_vehicle') then
            for _, tab in ipairs(page.tabs) do
                if ImGui.BeginTabItem(self.ctx.translator:text(tab.label)) then
                    self:draw_page(tab); ImGui.EndTabItem()
                end
            end
            ImGui.EndTabBar()
        end
    elseif page.grid then
        if page.grid == 'self' then ImGui.SeparatorText(self.ctx.translator:text('GENERIC_GENERAL_LABEL')) end
        self:draw_grid(page.grid)
        if page.grid == 'self' and self.ctx.online then
            ImGui.Spacing(); ImGui.SeparatorText(self.ctx.translator:text('SELF_ABILITY_EDITOR'))
            local control = self.controls['ui.show_abilities'].control
            local value, changed = Widgets.toggle(self.ctx, self.ctx.translator:text('GENERIC_ENABLE'),
                self.ctx.settings:get(control.path))
            if changed then self.ctx.settings:set(control.path, value) end
            self.ctx.features.abilities:draw()
        elseif page.grid == 'cars' then
            ImGui.Spacing(); ImGui.SeparatorText(self.ctx.translator:text('GENERIC_SETTINGS_LABEL'))
            self:draw_control(self.controls['features.vehicle.performance_only'].control)
        elseif page.grid == 'aircraft' then
            self.ctx.features.aircraft:draw()
        elseif page.grid == 'world' then
            ImGui.Spacing()
            self:draw_control(self.ctx.features.public_enemy.controls[1])
            local width = 0
            for _, action in ipairs(self.actions.world or {}) do
                width = math.max(width,
                    ImGui.CalcTextSize(self.ctx.translator:text(action.label)) + 20)
            end
            for _, action in ipairs(self.actions.world or {}) do
                if Widgets.button(self.ctx, self.ctx.translator:text(action.label), width, 36) then
                    self.ctx.runtime:run(
                        action.label, action.callback)
                end
                Widgets.tooltip(self.ctx, self.ctx.translator:text(action.label .. '_TT'))
            end
            self.ctx.features.carpool:draw()
            ImGui.Spacing(); ImGui.Separator(); ImGui.TextDisabled('The world is simple. For now.')
        end
    else
        self:draw_tool(page.feature)
    end
end

function View:draw_category(category)
    local pages = assert(Layout.pages[category], 'Missing original category')
    local selected = math.max(1, math.min(#pages, self.last_pages[category] or 1))
    self:draw_page(pages[selected])
    self:draw_options()
end

function View:draw_header()
    local settings = self.ctx.settings
    local width = settings:get('ui.width')
    local x, y = ImGui.GetWindowPos()
    ImGui.SetCursorPos(12, 12)
    ImGui.InvisibleButton('##ssv2_header_drag', width - 85, 40)
    if settings:get('ui.moveable') and ImGui.IsItemActive() then
        if not self.header_drag then self.header_drag = { x = x, y = y } end
        local dx, dy = ImGui.GetMouseDragDelta(0, 0)
        if dx ~= 0 or dy ~= 0 then
            self.motion = nil
            x, y = self.header_drag.x + dx, self.header_drag.y + dy
            ImGui.SetWindowPos(x, y, ImGuiCond.Always)
        end
    else
        self.header_drag = nil
    end
    local position = settings:get('ui.position')
    if position.x ~= x or position.y ~= y then settings:set('ui.position', { x = x, y = y }) end
    local list = ImGui.GetWindowDrawList()
    local title = "Samurai's Scripts"
    local title_width = ImGui.CalcTextSize(title) * 1.5
    Widgets.text(list, x + (width - title_width) * 0.5, y + 18, title, self.ctx.theme:current().Colors.Text, 1.5)
    ImGui.SetCursorPos(width - 68, 18)
    self.ctx.notifier.position = { x = x + ImGui.GetContentRegionAvail(), y = y + ImGui.GetCursorPosY() }
    if Widgets.notification(self.ctx) then
        self.ctx.notifier.open = not self.ctx.notifier.open; self:update_mouse()
    end
    local count = #Layout.categories
    local tab_width = math.min(90, (width - 24 - (count - 1) * 10) / count)
    local row_width = count * tab_width + (count - 1) * 10
    local start = (width - row_width) * 0.5
    for i, category in ipairs(Layout.categories) do
        ImGui.SetCursorPos(start + (i - 1) * (tab_width + 10), 73)
        if Widgets.navigation(self.ctx, '##ss_category_' .. category, self.ctx.translator:text(category_labels[category]),
                self.category_index == i, tab_width, 40, true, false) then
            self:select_category(i); self:play_navigation()
        end
    end
    local target = start + (self.category_index - 1) * (tab_width + 10)
    self.underline_x = (self.underline_x or target) + (target - (self.underline_x or target)) * 0.15
    local r, g, b, a = Widgets.rgba(self.ctx.theme:current().SSGradient)
    list:AddRectFilled(x + self.underline_x, y + 117, x + self.underline_x + tab_width, y + 121, r, g, b, a, 2)
end

function View:snap(alignment)
    local width, height = ImGui.GetDisplaySize(); local w, h = self.ctx.settings:get('ui.width'),
        self.ctx.settings:get('ui.height') + header_height + window_gap
    local x, y = math.max(1, (width - w) / 2), math.max(1, (height - h) / 2)
    local target = ({ { x = x, y = 1 }, { x = x, y = math.max(1, height - h - 1) }, { x = 1, y = y }, { x = math.max(1, width - w - 1), y = y }, { x = x, y = y } })
        [alignment + 1]
    local current = self.ctx.settings:get('ui.position')
    self.motion = { from = { x = current.x, y = current.y }, target = target, started = util.time() }
    self:play_navigation()
end

function View:show_height_limit()
    local settings = self.ctx.settings; local width = settings:get('ui.width'); local position = settings:get(
        'ui.position')
    ImGui.SetNextWindowSize(width + 10, 0)
    ImGui.SetNextWindowPos(position.x - 10, position.y + settings:get('ui.height') + header_height - 10)
    local flags = bit.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoBringToFrontOnFocus,
        ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoBackground)
    if ImGui.Begin('##indicator', nil, flags) then
        local x, y = ImGui.GetCursorScreenPos(); local r, g, b, a = Widgets.rgba(self.ctx.theme:current().SSAccent)
        ImGui.GetWindowDrawList():AddLine(x, y, x + width, y, r, g, b, a, 3)
    end
    ImGui.End()
end

local function binding_combo(settings, path, label, options, allow_unbound)
    local current, names, values = settings:get(path), {}, {}
    local selected = 0
    for _, option in ipairs(options) do
        if allow_unbound or option[2] ~= 0 then
            names[#names + 1], values[#values + 1] = option[1], option[2]
            if option[2] == current then selected = #values - 1 end
        end
    end
    local value, changed = ImGui.Combo(label, selected, names, #names)
    if changed then settings:set(path, values[value + 1]) end
end

function View:draw_options()
    local entry = self.option
    if not entry then return end
    local pair = assert(self.controls[entry.path])
    local label = self.ctx.translator:text(pair.control.label) .. '##ssv2_options'
    if self.option_requested then
        ImGui.OpenPopup(label); self.option_requested = false
    end
    ImGui.SetNextWindowSizeConstraints(400, 140, 600, 800)
    local open, draw = ImGui.BeginPopupModal(label, true,
        bit.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoResize))
    if not open then self.option = nil end
    if draw then
        local quick = self.ctx.quick_toggles
        ImGui.SeparatorText(self.ctx.translator:text('SETTINGS_KEYBINDS'))
        local id = quick.registered[entry.path]
        if not id then
            quick:add(entry.path); id = quick.registered[entry.path]
        end
        if id then
            if not self.keybinds_view then self.keybinds_view = require('includes.ssv2.core.keybinds_view').new(self.ctx) end
            local binding
            for _, item in ipairs(self.ctx.input.bindings) do
                if item.id == id then
                    binding = item; break
                end
            end
            if binding and ImGui.BeginTabBar('##gridItemKeybind') then
                for _, source in ipairs({ 'keyboard', 'controller' }) do
                    if ImGui.BeginTabItem(self.ctx.translator:text(source == 'keyboard' and 'SETTINGS_KEYBINDS_KEYBOARD' or 'SETTINGS_KEYBINDS_CONTROLLER')) then
                        self.keybinds_view:row(binding, source, true); ImGui.EndTabItem()
                    end
                end
                ImGui.EndTabBar()
            end
            ImGui.Separator(); ImGui.Spacing()
        end
        if #entry.options > 0 or entry.draw then ImGui.SeparatorText(self.ctx.translator:text('GENERIC_OPTIONS_LABEL')) end
        for _, path in ipairs(entry.options) do
            self:draw_control(assert(self.controls[path],
                'Missing original option: ' .. path).control)
        end
        if entry.draw then self.ctx.features[entry.draw]:draw() end
        if ImGui.Button(self.ctx.translator:text('GENERIC_CLOSE', 'Close')) then
            ImGui.CloseCurrentPopup(); self.option = nil
        end
        self:draw_input_capture()
        ImGui.EndPopup()
    end
end

function View:draw_settings(section)
    local settings, tr = self.ctx.settings, self.ctx.translator
    if section == 'debug' then
        self.ctx.debug_view:draw(); return
    end
    if not section or section == 'general' then
        local cleanup, changed = Widgets.toggle(self.ctx, tr:text('SETTINGS_ENTITY_REPLACE'),
            settings:get('backend.auto_cleanup_entities'))
        if changed then settings:set('backend.auto_cleanup_entities', cleanup) end
        Widgets.help(self.ctx, tr:text('SETTINGS_ENTITY_REPLACE_TT'))
        Widgets.header(tr:text('SETTINGS_LANGUAGE'), true)
        ImGui.BeginDisabled(util.time() < (tr.reload_after or 0))
        local automatic, changed = Widgets.toggle(self.ctx, tr:text('SETTINGS_GAME_LANGUAGE'),
            settings:get('backend.use_game_language'))
        if changed then settings:set('backend.use_game_language', automatic) end
        ImGui.EndDisabled()
        Widgets.help(self.ctx, tr:text('SETTINGS_GAME_LANGUAGE_TT'))
        ImGui.Spacing()
        ImGui.BeginDisabled(settings:get('backend.use_game_language'))
        local current = tr.locales[settings:get('backend.language_index')]
        if ImGui.BeginCombo('##langs', current and tr:text(current) or 'NULL') then
            for i, iso in ipairs(tr.locales) do
                ImGui.Selectable(tr:text(iso) .. ' (' .. iso .. ')', settings:get('backend.language_index') == i)
                if ImGui.IsItemClicked(0) then settings:set('backend.language_index', i) end
            end
            ImGui.EndCombo()
        end
        ImGui.EndDisabled()
        ImGui.Spacing(); ImGui.Separator()
        if ImGui.Button(tr:text('SETTINGS_CFG_RESET')) then
            self.reset_exceptions = {}; self.reset_open = true
        end
        ImGui.Spacing(); Widgets.header(tr:text('YRV3_DANGER_ZONE'), true, { 0.941, 0.745, 0.007, 1 })
        ImGui.BeginDisabled(self.ctx.fsl or false)
        local _, changed = Widgets.checkbox(self.ctx, tr:text('YRV3_UNSAFE_FEATS_CB'),
            settings:get('features.unsafe_feats_enabled'))
        if changed then
            if settings:get('features.unsafe_feats_enabled') then
                settings:set('features.unsafe_feats_enabled', false)
            else
                ImGui.OpenPopup(tr:text('GENERIC_WARN_LABEL') .. '##ssv2_unsafe')
            end
        end
        ImGui.EndDisabled()
        ImGui.Spacing(); ImGui.SetWindowFontScale(0.9); ImGui.TextWrapped(tr:text(self.ctx.fsl and
            'YRV3_UNSAFE_FEATS_FSL_ON_TXT' or 'YRV3_UNSAFE_FEATS_HINT')); ImGui.SetWindowFontScale(1)
        if Widgets.dialog(self.ctx, tr:text('GENERIC_WARN_LABEL') .. '##ssv2_unsafe', tr:text('YRV3_UNSAFE_FEATS_PROMPT'), 1) then
            settings:set('features.unsafe_feats_enabled', true)
        end
    end
    if not section or section == 'gui' then
        ImGui.SeparatorText(tr:text('GENERIC_GENERAL_LABEL'))
        local sounds, changed = Widgets.toggle(self.ctx, tr:text('SETTINGS_UI_SOUND'),
            settings:get('ui.disable_sound_feedback'))
        if changed then settings:set('ui.disable_sound_feedback', sounds) end
        local tooltips, changed = Widgets.toggle(self.ctx, tr:text('SETTINGS_TOOLTIPS'),
            settings:get('ui.disable_tooltips'))
        if changed then settings:set('ui.disable_tooltips', tooltips) end
        ImGui.Spacing(); ImGui.SeparatorText(tr:text('SETTINGS_WINDOW_GEOMETRY'))
        local moveable, changed = Widgets.toggle(self.ctx, tr:text('SETTINGS_WINDOW_MOVEABLE'),
            settings:get('ui.moveable'))
        if changed then settings:set('ui.moveable', moveable) end
        Widgets.tooltip(self.ctx, tr:text('SETTINGS_WINDOW_MOVEABLE_TT'))
        if moveable then
            ImGui.SameLine(); if Widgets.button(self.ctx, tr:text('SETTINGS_WINDOW_POS_RESET')) then self:snap(0) end
            ImGui.SameLine(); if Widgets.button(self.ctx, tr:text('SETTINGS_WINDOW_POS_SNAP')) then
                ImGui.OpenPopup(
                    '##snapMainWindow')
            end
        end
        local _, draw = ImGui.BeginPopupModal('##snapMainWindow', true,
            bit.bor(ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoResize,
                ImGuiWindowFlags.AlwaysAutoResize))
        if draw then
            if Widgets.quick_config(self.ctx, tr:text('SETTINGS_WINDOW_POS_SNAP'), nil, true) then
                ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 35, 30)
                ImGui.InvisibleButton('##dummy0', 30, 30); ImGui.SameLine(); if ImGui.ArrowButton('##top', 2) then
                    self
                        :snap(0)
                end
                if ImGui.ArrowButton('##left', 0) then self:snap(2) end
                ImGui.SameLine(); if ImGui.Button('O', 30, 30) then self:snap(4) end
                ImGui.SameLine(); if ImGui.ArrowButton('##right', 1) then self:snap(3) end
                ImGui.InvisibleButton('##dummy1', 30, 30); ImGui.SameLine(); if ImGui.ArrowButton('##bottom', 3) then
                    self:snap(1)
                end
                ImGui.PopStyleVar()
                if ImGui.Button(tr:text('GENERIC_CLOSE')) then ImGui.CloseCurrentPopup() end
                self:show_height_limit()
            end
            ImGui.EndPopup()
        end
        local screen_width, screen_height = ImGui.GetDisplaySize()
        if ImGuiSliderFlags and ImGuiSliderFlags.NoInput ~= nil then
            local width, changed = ImGui.SliderFloat(tr:text('SETTINGS_WINDOW_WIDTH'), settings:get('ui.width'), 620,
                screen_width, '%.0f', ImGuiSliderFlags.NoInput)
            if changed then settings:set('ui.width', width) end
            ImGui.SameLine(); if Widgets.button(self.ctx, tr:text('GENERIC_RESET') .. '##width') then
                settings:set(
                    'ui.width', screen_width * 0.45)
            end
            local height, changed = ImGui.SliderFloat(tr:text('SETTINGS_WINDOW_HEIGHT'), settings:get('ui.height'),
                header_height + 240, screen_height - header_height - 10, '%.0f', ImGuiSliderFlags.NoInput)
            if changed then settings:set('ui.height', height) end
            if ImGui.IsItemHovered() then self:show_height_limit() end
            Widgets.help(self.ctx, tr:text('SETTINGS_WINDOW_HEIGHT_TT'))
            ImGui.SameLine(); if Widgets.button(self.ctx, tr:text('GENERIC_RESET') .. '##height') then
                settings:set(
                    'ui.height', screen_height * 0.8)
            end
        else
            ImGui.TextWrapped('Window width and height controls require the V2 slider-flags API addition (G19).')
        end
        ImGui.BeginDisabled(true)
        ImGui.SliderFloat(tr:text('SETTINGS_WINDOW_POS_X'), settings:get('ui.position.x'), 0, screen_width)
        ImGui.SliderFloat(tr:text('SETTINGS_WINDOW_POS_Y'), settings:get('ui.position.y'), 0, screen_height)
        ImGui.EndDisabled()
        Widgets.tooltip(self.ctx, tr:text('SETTINGS_WINDOW_POS_TT'))
        ImGui.Spacing(); Widgets.header(tr:text('SETTINGS_WINDOW_STYLE')); self.ctx.theme:draw()
    end
    if not section or section == 'keybinds' then
        if not self.keybinds_view then self.keybinds_view = require('includes.ssv2.core.keybinds_view').new(self.ctx) end
        self.keybinds_view:draw()
    end
    if not section or section == 'general' then
        if settings.last_error then ImGui.TextWrapped('Settings could not be saved. See the menu log.') end
    end
end

function View:draw_input_capture()
    local input, tr = self.ctx.input, self.ctx.translator
    local capture = input.capture
    if self.capture_drawn or not capture and not self.capture_popup_active then return end
    self.capture_drawn = true
    local popup = 'Key binding##ssv2_capture'
    if capture and capture.requested then
        ImGui.OpenPopup(popup); capture.requested = false; self.capture_popup_active = true
    end
    ImGui.SetNextWindowSizeConstraints(400, 220, 480, 600)
    local _, draw = ImGui.BeginPopupModal(popup, true,
        bit.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoMove))
    if not draw then return end
    if not capture then
        ImGui.CloseCurrentPopup(); ImGui.EndPopup(); self.capture_popup_active = nil; return
    end
    local width, height = ImGui.GetDisplaySize(); local w, h = ImGui.GetWindowSize()
    ImGui.SetWindowPos((width - w) * 0.5, (height - h) * 0.5, ImGuiCond.Always)
    if ImGui.SmallButton('X') then
        input.capture = nil; self.capture_popup_active = nil; ImGui.CloseCurrentPopup(); ImGui.EndPopup(); return
    end
    local name = capture.id
    for _, binding in ipairs(input.bindings) do
        if binding.id == capture.id then
            local pair = binding.label and self.controls[binding.label]
            name = pair and tr:text(pair.control.label) or binding.label or
                tr:text(binding_labels[capture.id] or capture.id); break
        end
    end
    ImGui.Text(name .. (capture.modifier_only and ' — ' .. capture.source .. ' modifier' or ' — ' .. capture.source))
    ImGui.Separator()
    if capture.key == nil then
        ImGui.Text(Widgets.spinner(tr:text('SETTINGS_HOTKEY_WAIT')))
        ImGui.Spacing(); ImGui.SetWindowFontScale(0.9); ImGui.TextWrapped(tr:text('SETTINGS_HOTKEY_MOD_TIP')); ImGui
            .SetWindowFontScale(1)
    else
        local options = capture.source == 'keyboard' and key_options or controller_options
        local function key_name(code)
            for _, option in ipairs(options) do if option[2] == code then return option[1] end end
            return tostring(code)
        end
        local key = key_name(capture.key)
        if capture.modifier ~= 0 then key = key_name(capture.modifier) .. ' + ' .. key end
        ImGui.Text(tr:text('SETTINGS_HOTKEY_FOUND')); ImGui.SameLine()
        local bar_width = math.max(200, ImGui.GetContentRegionAvail() / 4)
        ImGui.SetCursorPosX(w - bar_width - (ImGui.GetStyle().WindowPadding.x))
        if capture.waiting_release then
            ImGui.Text(Widgets.spinner(key .. ' + '))
        else
            Widgets.value_bar(self.ctx, '##keyName', 0, bar_width, ImGui.GetTextLineHeightWithSpacing(), false, nil, key)
        end
        if capture.reserved then ImGui.TextColored(1, 0, 0, 0.86, tr:text('SETTINGS_HOTKEY_RESERVED')) end
        if #capture.conflicts > 0 then ImGui.TextWrapped('Also assigned to: ' .. table.concat(capture.conflicts, ', ')) end
    end
    ImGui.Spacing(); ImGui.Separator(); ImGui.Spacing()
    local style = ImGui.GetStyle(); local _, available_height = ImGui.GetContentRegionAvail()
    ImGui.Dummy(0, math.max(0, available_height - 32 - style.WindowPadding.y))
    local disabled = capture.key == nil or capture.reserved or capture.waiting_release
    ImGui.BeginDisabled(disabled)
    if Widgets.button(self.ctx, tr:text('GENERIC_CONFIRM'), 120, 32) and not disabled then
        input:apply_capture(); self.capture_popup_active = nil; ImGui.CloseCurrentPopup()
    end
    ImGui.EndDisabled(); ImGui.SameLine(); ImGui.SetCursorPosX(w - 120 - style.WindowPadding.x)
    ImGui.BeginDisabled(capture.key == nil)
    if Widgets.button(self.ctx, tr:text('GENERIC_CLEAR'), 120, 32) and capture.key ~= nil then input:clear_capture() end
    ImGui.EndDisabled()
    ImGui.EndPopup()
end

function View:reset_settings(exceptions)
    local settings = self.ctx.settings
    local preserved = {}
    for _, path in ipairs(exceptions or {}) do preserved[path] = settings:get(path) end
    preserved['backend.debug_mode'] = settings:get('backend.debug_mode')
    settings.data = {}; settings:normalize()
    for path, value in pairs(preserved) do settings:set(path, value) end
    settings:set('ui.layout_revision', 1)
    settings.dirty = true
    return settings:save()
end

function View:draw_reset()
    if not self.reset_open then return end
    local tr = self.ctx.translator
    local open, draw = ImGui.Begin('##cfg_reset', true,
        bit.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoResize,
            ImGuiWindowFlags.AlwaysAutoResize))
    if not open then self.reset_open = false end
    if draw then
        if Widgets.quick_config(self.ctx, tr:text('SETTINGS_CFG_RESET'), function()
                self.reset_open = false; self.reset_exceptions = {}
            end, true) then
            ImGui.Text(tr:text('SETTINGS_RESET_PRESERVE_KEYS'))
            ImGui.Spacing()
            for _, entry in ipairs({ { 'GUI', 'ui' }, { 'Keybinds', 'keybinds' }, { 'Quick Toggle Keybinds', 'quick_toggle_keybinds' },
                { 'Casino Pacino', 'features.dunk' }, { 'EntityForge', 'features.entity_forge' }, { 'YimActions', 'features.yim_actions' },
                { 'YimResupplier', 'features.yrv3' } }) do
                self.reset_exceptions[entry[2]] = ImGui.Checkbox(entry[1], self.reset_exceptions[entry[2]] or false)
            end
            ImGui.Separator(); ImGui.Spacing()
            if ImGui.Button(tr:text('GENERIC_RESET')) then ImGui.OpenPopup(tr:text('GENERIC_RESET')) end
            if Widgets.dialog(self.ctx, tr:text('GENERIC_RESET')) then
                local paths = {}; for path, enabled in pairs(self.reset_exceptions) do
                    if enabled then
                        paths[#paths + 1] =
                            path
                    end
                end
                self:reset_settings(paths); self.reset_open = false; self.reset_exceptions = {}
            end
        end
    end
    ImGui.End()
end

function View:draw()
    self.wants_input = false
    if not self.open then return end
    self.capture_drawn = false
    local settings = self.ctx.settings
    self.ctx.theme:push()
    ImGui.SetNextWindowBgAlpha(settings:get('ui.style.bg_alpha'))
    ImGui.SetNextWindowSize(settings:get('ui.width'), header_height, ImGuiCond.Always)
    local position = settings:get('ui.position')
    if self.motion then
        local t = math.min(1, (util.time() - self.motion.started) / 800); local ease = t * t * (3 - 2 * t)
        position = {
            x = self.motion.from.x + (self.motion.target.x - self.motion.from.x) * ease,
            y = self.motion.from.y +
                (self.motion.target.y - self.motion.from.y) * ease
        }
        if t == 1 then
            settings:set('ui.position', position); self.motion = nil
        end
    end
    ImGui.SetNextWindowPos(position.x, position.y, ImGuiCond.Always)
    local flags = bit.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoResize,
        ImGuiWindowFlags.NoBringToFrontOnFocus, ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.NoSavedSettings)
    if not settings:get('ui.moveable') then flags = bit.bor(flags, ImGuiWindowFlags.NoMove) end
    local draw = ImGui.Begin('##ssv2_header', nil, flags)
    if draw then self:draw_header() end
    ImGui.End()
    position = settings:get('ui.position')
    local category = Layout.categories[self.category_index]
    local pages = Layout.pages[category]
    local selected = math.max(1, math.min(#pages, self.last_pages[category] or 1))
    local sidebar = #pages > 1
    local width = settings:get('ui.width') - (sidebar and sidebar_width + window_gap or 0)
    local body_y = position.y + header_height + window_gap
    local body_flags = bit.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoResize,
        ImGuiWindowFlags.NoBringToFrontOnFocus, ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoSavedSettings)
    if sidebar then
        ImGui.SetNextWindowBgAlpha(settings:get('ui.style.bg_alpha'))
        ImGui.SetNextWindowPos(position.x, body_y, ImGuiCond.Always)
        ImGui.SetNextWindowSizeConstraints(sidebar_width, 20, sidebar_width, settings:get('ui.height') - 10)
        if ImGui.Begin('##ssv2_sidebar', nil, body_flags) then
            for i, page in ipairs(pages) do
                if Widgets.navigation(self.ctx, '##ss_page_' .. i, self.ctx.translator:text(page.label), selected == i,
                        sidebar_width - 30, 32, false, true) then
                    self:select_page(i); self:play_navigation()
                end
                ImGui.Dummy(0, 10)
            end
        end
        ImGui.End()
    end
    ImGui.SetNextWindowBgAlpha(settings:get('ui.style.bg_alpha'))
    ImGui.SetNextWindowPos(position.x + (sidebar and sidebar_width + window_gap or 0), body_y, ImGuiCond.Always)
    ImGui.SetNextWindowSizeConstraints(width, 20, width, settings:get('ui.height') - 10)
    if ImGui.Begin('##ssv2_content', nil, body_flags) then
        self:draw_category(category); self:draw_input_capture()
    end
    ImGui.End()
    self:draw_reset()
    self.ctx.theme:pop()
end

return View
