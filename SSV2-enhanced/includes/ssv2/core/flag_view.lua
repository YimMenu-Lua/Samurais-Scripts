-- Original Handling Editor frontend. Copyright (C) 2026 SAMURAI & Contributors.
-- GPL-3.0-or-later.
local Widgets = require('includes.ssv2.core.widgets')
local Codec = require('includes.ssv2.core.codec')
local TableView = require('includes.ssv2.core.table_view')
local View = {}; View.__index = View
function View.new(ctx, f, groups)
    return setmetatable({ ctx = ctx, f = f, groups = groups, preset_search = '', card_width = 200 },
        View)
end

function View:text(key) return self.ctx.translator:text(key) end

function View:help(key)
    if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and not self.ctx.settings:get('ui.disable_tooltips') then
        Widgets.tooltip(self.ctx, self:text(key))
    end
end

function View:run(label, callback)
    local identity, generation = self.f.identity, self.ctx.runtime.generation
    self.ctx.runtime:run(label,
        function()
            if self.ctx.runtime.generation == generation and self.f.active and self.f.identity == identity then
                callback()
            end
        end)
end

function View:button(key, callback, disabled, width, height)
    ImGui.BeginDisabled(not not disabled)
    if Widgets.button(self.ctx, self:text(key), width or 0, height or 0) and not disabled then callback() end
    ImGui.EndDisabled()
end

function View:confirm(id, message, callback)
    if Widgets.dialog(self.ctx, id, message, 1) then callback() end
end

function View:flags(category)
    local f, group = self.f, self.groups[category]
    if not f:allowed(group.allowed) then
        ImGui.Text(self:text('VEH_FLAGS_WRONG_VEH_TYPE')); ImGui.Spacing(); return
    end
    local flags = f.cache[category] or {}
    table.sort(flags, function(a, b) return f.sort == 0 and a.index < b.index or f.sort == 1 and a.name < b.name end)
    if ImGui.BeginChild('##vehFlags', 0, math.min(self.ctx.settings:get('ui.height') * 0.58, #flags * ImGui.GetTextLineHeightWithSpacing()), true) then
        for _, item in ipairs(flags) do
            if f.filter == 0 or f.filter == 1 and item.value or f.filter == 2 and not item.value then
                ImGui.PushID(item.name); ImGui.BeginDisabled(item.owned)
                local enabled, changed = Widgets.toggle(self.ctx, item.name, item.value)
                if changed and not item.owned then
                    self:run('edit vehicle flag',
                        function() f:push(category, item.name, enabled) end)
                end
                ImGui.EndDisabled(); if item.owned then self:help('VEH_FLAGS_FLAG_OWNED_WARN') end
                ImGui.SameLine(); ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - 70)
                ImGui.TextDisabled('( 1 << ' .. item.index .. ' )'); ImGui.PopID()
            end
        end
    end
    ImGui.EndChild(); ImGui.Separator(); ImGui.SetWindowFontScale(0.8)
    local raw = f.raw_flags and f.raw_flags[category] or 0
    if type(raw) == 'table' then
        local words = {}; for i, value in ipairs(raw) do words[i] = string.format('0x%08X', value) end; ImGui
            .TextWrapped('{ ' .. table.concat(words, ', ') .. ' }')
    else
        ImGui.TextWrapped(string.format('0x%08X', raw))
    end
    ImGui.SetWindowFontScale(1)
end

function View:editor()
    local f = self.f
    f.filter = ImGui.Combo(self:text('GENERIC_LIST_FILTER'), f.filter,
        { self:text('GENERIC_ALL'), self:text('VEH_FLAGS_FILTER_ENABLED_ONLY'), self:text(
            'VEH_FLAGS_FILTER_DISABLED_ONLY') }, 3)
    f.sort = ImGui.Combo(self:text('GENERIC_LIST_SORT'), f.sort, { 'Flag', self:text('GENERIC_NAME') }, 2)
    local presets = next(f.active_presets) ~= nil; local edits = next(f.edits) ~= nil
    local width = math.max(ImGui.CalcTextSize(self:text('GENERIC_RESET_DEFAULT')),
        ImGui.CalcTextSize(self:text('VEH_FLAGS_NEW_PRESET'))) + 20
    self:button('GENERIC_RESET_DEFAULT',
        function()
            self:run('reset manual flags',
                function()
                    self.ctx.vehicle_flags:release(f); f.edits = {}; f.next_cache = 0
                end)
        end, presets or not edits, width, 37.5)
    if presets then self:help('VEH_FLAGS_NO_RESET') end
    ImGui.SameLine()
    local warning = self:text('GENERIC_WARN_LABEL') .. '##new_preset_warning'
    self:button('VEH_FLAGS_NEW_PRESET',
        function() if presets then ImGui.OpenPopup(warning) else self.new_open = true end end, not edits, width, 37.5)
    self:confirm(warning, self:text('VEH_FLAGS_NEW_PRESET_WARN'), function() self.new_open = true end)
    if self.ctx.settings:get('backend.debug_mode') then
        ImGui.SameLine(); self:button('Parse Object',
            function() self.ctx.debug_view:dump({ name = 'test', deltas = f.edits, vehicle_bitset = 1 }) end, not edits,
            width, 37.5)
    end
    ImGui.Separator()
    if ImGui.BeginTabBar('##flagsEditor') then
        for index = 0, 3 do
            ImGui.PushID(index)
            if ImGui.BeginTabItem(self:text(self.groups[index].label)) then
                self:flags(index); ImGui.EndTabItem()
            end
            ImGui.PopID()
        end
        ImGui.EndTabBar()
    end
end

function View:import_dialog()
    ImGui.SetNextWindowSizeConstraints(400, 300, 640, 800)
    local _, draw = ImGui.BeginPopupModal('##presetImportPopup', true, ImGuiWindowFlags.AlwaysAutoResize)
    if not draw then return end
    if not self.imported then
        self:button('GENERIC_CLIPBOARD_DECODE', function()
            local ok, value = pcall(Codec.decode, ImGui.GetClipboardText())
            if ok and type(value) == 'table' then
                self.imported = value
            else
                self.ctx.notifier:error('HandlingEditor',
                    self:text('GENERIC_DATA_PARSE_FAIL'))
            end
        end, false, 180, 40)
        ImGui.Dummy(0, 25); ImGui.TextWrapped(self:text('VEH_FLAGS_PRESET_PARSER_TOOLTIP'))
    else
        TableView.draw(self.imported, 610, 620); ImGui.Spacing()
        self:button('GENERIC_CONFIRM', function()
            local value = self.imported
            self:run('import handling preset', function()
                local ok = pcall(function() self.f:import(value) end)
                self.ctx.notifier[ok and 'success' or 'error'](self.ctx.notifier, 'HandlingEditor',
                    self:text(ok and 'VEH_FLAGS_PRESET_IMPORT_SUCCESS' or 'VEH_FLAGS_PRESET_IMPORT_FAIL'))
            end)
            self.imported = nil; ImGui.CloseCurrentPopup()
        end, false, 180, 40)
        ImGui.SameLine(); self:button('GENERIC_CLEAR', function() self.imported = nil end, false, 180, 40)
    end
    ImGui.EndPopup()
end

function View:serialize(preset)
    local value = {}; for key, item in pairs(preset) do if key ~= 'previous_stance' then value[key] = item end end; return
        value
end

function View:preset_card(preset)
    local f = self.f; local name = self:text(preset.name)
    self.card_width = math.min(300,
        math.max(self.card_width, ImGui.CalcTextSize(name) + 50, ImGui.GetContentRegionAvail() * 0.48))
    ImGui.PushID(preset.name)
    if ImGui.BeginChild(name, self.card_width, 240, true, ImGuiWindowFlags.NoScrollbar) then
        ImGui.SeparatorText(name); ImGui.PushStyleVar(ImGuiStyleVar.ScrollbarSize, 5); ImGui.SetNextWindowBgAlpha(0)
        if ImGui.BeginChild('##description', 0, 75, false) then
            ImGui.SetWindowFontScale(0.78); ImGui.TextWrapped(self:text(preset.description or 'GENERIC_NO_DESCRIPTION')); ImGui
                .SetWindowFontScale(1)
        end
        ImGui.EndChild(); ImGui.Separator()
        ImGui.BeginDisabled(not f:allowed(preset.vehicle_bitset))
        local enabled, changed = Widgets.toggle(self.ctx, self:text('GENERIC_ENABLE'), f.active_presets[preset.name] ~=
            nil)
        if changed then self:run('toggle handling preset', function() f:toggle(preset, enabled) end) end
        ImGui.EndDisabled(); if not f:allowed(preset.vehicle_bitset) then self:help('VEH_FLAGS_WRONG_VEH_TYPE') end
        local automatic, changed = Widgets.toggle(self.ctx, self:text('GENERIC_AUTO_ENABLE'), preset.auto_apply)
        if changed then
            preset.auto_apply = automatic; f:save(); if automatic then
                self:run('enable saved handling preset',
                    function() f:toggle(preset, true) end)
            end
        end
        self:help('VEH_FLAGS_AUTOENABLE_TT')
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + self.card_width - 60); ImGui.SetWindowFontScale(0.78)
        if ImGui.SmallButton(' . . . ') then ImGui.OpenPopup('##presetMenu') end
        ImGui.SetWindowFontScale(1); self:help('GENERIC_OPTIONS_LABEL')
        local reserved = f.reserved[preset.name]
        if ImGui.BeginPopup('##presetMenu') then
            if ImGui.MenuItem(self:text('VEH_FLAGS_DUMP_PRESET_FLAGS')) then self.open_dump = true end
            ImGui.BeginDisabled(reserved or false)
            if ImGui.MenuItem(self:text('GENERIC_SHARE')) and not reserved then
                ImGui.SetClipboardText(Codec.encode(self:serialize(preset), true)); self.ctx.notifier:success(
                    'HandlingEditor', self.ctx.translator:format('VEH_FLAGS_PRESET_SHARE_SUCCESS_FMT', name))
            end
            ImGui.EndDisabled(); if reserved then
                self:help('VEH_FLAGS_PRESET_NO_SHARE')
            elseif preset.callback_defs_filename then
                if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
                    Widgets.tooltip(self.ctx,
                        self.ctx.translator:format('VEH_FLAGS_PRESET_CB_FILE_WARN_FMT', preset.callback_defs_filename))
                end
            end
            ImGui.BeginDisabled(reserved or false); if ImGui.MenuItem(self:text('GENERIC_DELETE')) and not reserved then self.open_delete = true end
            ImGui.EndDisabled(); if reserved then self:help('VEH_FLAGS_PRESET_NO_DELETE') end; ImGui.EndPopup()
        end
        if self.open_dump then
            ImGui.OpenPopup('##presetFlags'); self.open_dump = false
        end
        if self.open_delete then
            ImGui.OpenPopup('##deletePreset'); self.open_delete = false
        end
        self:confirm('##deletePreset', self:text('GENERIC_CONFIRM_WARN'),
            function() self:run('remove handling preset', function() f:remove(preset.name) end) end)
        ImGui.SetNextWindowSizeConstraints(400, 160, 600, 600)
        local _, draw = ImGui.BeginPopupModal('##presetFlags', true,
            bit.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoResize))
        if draw then
            local count = 0; for _, flags in pairs(preset.deltas) do for _ in pairs(flags) do count = count + 1 end end
            ImGui.Text('Flag count: [ ' .. count .. ' ]'); ImGui.Spacing(); ImGui.Separator()
            for _, flags in pairs(preset.deltas) do
                for flag, enabled in pairs(flags) do
                    ImGui.Text('[ ' ..
                        (enabled and 'On' or 'Off') .. ' ]  ' .. flag)
                end
            end
            ImGui.Separator(); ImGui.EndPopup()
        end
        ImGui.PopStyleVar()
    end
    ImGui.EndChild(); ImGui.PopID()
end

function View:presets()
    local f = self.f
    f.preset_filter = ImGui.Combo(self:text('GENERIC_LIST_SORT'), f.preset_filter,
        { self:text('GENERIC_ALL'), self:text('VEH_FLAGS_PRESET_FILTER_CARS_ONLY'), self:text(
            'VEH_FLAGS_PRESET_FILTER_BIKES_ONLY') }, 3)
    self.preset_search = Widgets.input_text_with_hint(self.ctx, '##presetSearch', self:text('GENERIC_SEARCH_HINT'), self.preset_search)
        :lower(); ImGui.Separator(); ImGui.SetNextWindowBgAlpha(0)
    if ImGui.BeginChild('##presetsScrollRegion', 0, self.ctx.settings:get('ui.height') * 0.7, false) then
        ImGui.SetWindowFontScale(3)
        if Widgets.button(self.ctx, '+', self.card_width - 1, 240) then ImGui.OpenPopup('##presetImportPopup') end
        ImGui.SetWindowFontScale(1); self:help('EF_IMPORT_DATA'); self:import_dialog(); Widgets.same_line_if_available(
            self.card_width)
        for _, preset in ipairs(f.presets) do
            local mask = preset.vehicle_bitset
            if self:text(preset.name):lower():find(self.preset_search, 1, true) and (f.preset_filter == 0 or f.preset_filter == 1 and bit.band(mask, 1) ~= 0 or f.preset_filter == 2 and bit.band(mask, 2048) ~= 0 and bit.band(mask, 1) == 0) then
                self:preset_card(preset); Widgets.same_line_if_available(self.card_width)
            end
        end
    end
    ImGui.EndChild()
end

function View:new_preset()
    if not self.new_open then return end
    local f = self.f
    local _, draw = ImGui.Begin('##newPresetWindow', true,
        bit.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.AlwaysAutoResize,
            ImGuiWindowFlags.NoMove))
    if draw then
        if Widgets.quick_config(self.ctx, self:text('VEH_FLAGS_NEW_PRESET_LABEL'), function()
                self.new_open = false; f.preset_name = ''; f.description = ''; f.callback_module = ''; f.allow_cars = true; f.allow_bikes = false; f.new_auto = false
            end, true) then
            local function field(id, key, label, limit, flags)
                local value = Widgets.input_text_with_hint(self.ctx, id, self:text(label), f[key], flags or 0); f[key] = Widgets
                    .validated_text(f[key], value, limit)
            end
            field('*##newPresetName', 'preset_name', 'GENERIC_NAME', 64); field('*##newPresetDesc', 'description',
                'GENERIC_DESCRIPTION', 512)
            field('*##newPresetCb', 'callback_module', 'GENERIC_FILENAME', 64, ImGuiInputTextFlags.CharsNoBlank); f.callback_module =
                f.callback_module:gsub('[/\\]', ''):gsub('%.lua$', ''); Widgets.help(self.ctx,
                self:text('VEH_FLAGS_NEW_PRESET_CB_FILE_TT'))
            f.new_auto = Widgets.checkbox(self.ctx, self:text('GENERIC_AUTO_ENABLE'), f.new_auto)
            ImGui.SeparatorText(self:text('VEH_FLAGS_NEW_PRESET_VEHICLE_BS'))
            f.allow_cars = Widgets.checkbox(self.ctx, self:text('GENERIC_CARS'), f.allow_cars); f.allow_bikes = Widgets
                .checkbox(self.ctx, self:text('GENERIC_BIKES'), f.allow_bikes)
            if not f.allow_cars and not f.allow_bikes then f.allow_cars = true end
            if not f.preset_name:find('%S') then
                ImGui.TextColored(1, 0, 0, 1, self:text('SETTINGS_NEW_THEME_NAME_EMPTY'))
            elseif f.lookup[f.preset_name] then
                ImGui.TextColored(1, 0, 0, 1, self:text('GENERIC_NAME_ERR'))
            else
                ImGui.Spacing(); ImGui.Separator()
                self:button('GENERIC_CONFIRM', function()
                    local name, description, module, automatic, mask = f.preset_name, f.description, f.callback_module,
                        f.new_auto, (f.allow_cars and 1 or 0) + (f.allow_bikes and 2048 or 0)
                    self:run('create handling preset',
                        function() f:make_preset(name, mask, description, automatic, module) end)
                    self.new_open = false; f.preset_name = ''; f.description = ''; f.callback_module = ''; f.allow_cars = true; f.allow_bikes = false; f.new_auto = false
                end, false, 180, 40)
            end
        end
    end
    ImGui.End()
end

function View:draw()
    if not self.f.active then
        ImGui.Text(self:text('GENERIC_NOT_IN_VEH')); return
    end
    if ImGui.BeginTabBar('##vehicleFlagsMain') then
        if ImGui.BeginTabItem(self:text('VEH_FLAGS_EDITOR_TAB')) then
            self:editor(); ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(self:text('VEH_FLAGS_PRESETS_TAB')) then
            self:presets(); ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
    self:new_preset()
end

return View
