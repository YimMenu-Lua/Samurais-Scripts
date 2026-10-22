-- Original YimActions frontend expressed with native V2 widgets and runtime services.
-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors. GPL-3.0-or-later.
local Widgets = require('includes.ssv2.core.widgets')
local View = {}; View.__index = View
local categories = { 'All', 'Actions', 'Activities', 'Gestures', 'In-Vehicle', 'Movements', 'MISC', 'NSFW' }
local types = { 'All', 'Looped', 'Full Body', 'Has Props', 'Has PTFX', 'Has SFX' }
local flags = {
    { 'YAV3_FLAGS_LOOPING',     0 }, { 'YAV3_FLAGS_UPPERBODY', 4 }, { 'YAV3_FLAGS_SECONDARY', 5 },
    { 'YAV3_FLAGS_HIDE_WEAPON', 20 }, { 'YAV3_FLAGS_ENDS_IN_DEAD_POSE', 21 }, { 'YAV3_FLAGS_HOLD_LAST_FRAME', 1 },
    { 'YAV3_FLAGS_NOT_INTERRUPTABLE', 3 }, { 'YAV3_FLAGS_ADDITIVE', 8 }, { 'YAV3_FLAGS_TURN_OFF_COLLISION', 9 },
    { 'YAV3_FLAGS_FORCE_START',       17 }, { 'YAV3_FLAGS_PROCESS_ATTACHMENTS', 26 },
    { 'YAV3_FLAGS_ALTERNATIVE_FP_ANIM', 28 }, { 'YAV3_FLAGS_USE_FULL_BLENDING', 30 },
}
local function copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}; for key, item in pairs(value) do result[key] = copy(item) end; return result
end
local function label(item) return item.label or item.Name end
function View.new(ctx, feature)
    return setmetatable({
        ctx = ctx,
        f = feature,
        sidebar = 1,
        tip = 1,
        states = {},
        default_flags = {},
        clipset_mode = 0,
        command_name =
        ''
    }, View)
end

function View:text(key, ...)
    if select('#', ...) > 0 then return self.ctx.translator:format(key, ...) end; return self.ctx.translator:text(key)
end

function View:setting(path, title)
    local value, changed = Widgets.toggle(self.ctx, self:text(title), self.ctx.settings:get(path))
    if changed then self.ctx.settings:set(path, value) end
end

function View:run(title, callback) self.f:run(title, callback) end

function View:command_for(kind, name)
    for command, entry in pairs(self.f.commands.data.aliases) do
        if entry.kind == kind and entry.label == name then
            return
                command
        end
    end
end

function View:context(kind, item, mode, index)
    local f, name = self.f, label(item)
    local favorite = f.favorites.data[kind][name]
    local command = self:command_for(kind, name)
    local id = '##action_context_' .. index
    if ImGui.IsItemClicked(1) then
        self.context_selected = { kind = kind, data = item, default_flags = item.flags }; ImGui.OpenPopup(id)
    end
    local indicators = (favorite and mode ~= 'favorites' and '[*] ' or '') .. (command and '[C] ' or '')
    if indicators ~= '' then
        ImGui.SameLine(ImGui.GetContentRegionAvail() - ImGui.CalcTextSize(indicators)); ImGui.TextDisabled(indicators)
    end
    if not ImGui.BeginPopup(id) then return end
    if favorite and (mode == 'main' or mode == 'other' or mode == 'favorites') and ImGui.MenuItem('Remove From Favorites') then
        local values = copy(f.favorites.data[kind]); values[name] = nil; f.favorites:set(kind, values); f.favorites:save()
    elseif not favorite and (mode == 'main' or mode == 'other') and ImGui.MenuItem('Add To Favorites') then
        local values = copy(f.favorites.data[kind]); values[name] = copy(item); f.favorites:set(kind, values); f
            .favorites:save()
    end
    if kind == 'anims' or kind == 'scenarios' then
        if command and (mode == 'main' or mode == 'other') and ImGui.MenuItem('Remove Command') then
            local values = copy(f.commands.data.aliases); values[command] = nil; f.commands:set('aliases', values); f
                .commands:save()
            self.ctx.notifier:info('YimActions', "Action command '" .. command .. "' has been removed.")
        elseif not command and (mode == 'main' or mode == 'other') and ImGui.MenuItem('Create Command') then
            self.command_action = { kind = kind, data = copy(item) }; self.command_name = ''; self.command_open = true
        end
    end
    ImGui.EndPopup()
end

function View:browser(kind, mode, id, data, height)
    local key = kind .. ':' .. mode .. ':' .. id
    local state = self.states[key] or { search = '', category = 0, filter = 0 }; self.states[key] = state
    ImGui.PushID(key)
    if kind == 'anims' then
        local function filter(id, current, items, empty)
            ImGui.SetNextItemWidth(144)
            if ImGui.BeginCombo(id, current == 0 and empty or items[current + 1]) then
                for index, name in ipairs(items) do
                    ImGui.Selectable(name, current == index - 1)
                    if ImGui.IsItemClicked(0) then current = index - 1 end
                end
                ImGui.EndCombo()
            end
            return current
        end
        state.category = filter('##categoryCombo', state.category, categories, 'Category')
        Widgets.same_line_if_available(144); ImGui.SetNextItemWidth(144)
        state.filter = filter('##typeCombo', state.filter, types, 'Type')
    end
    ImGui.SetNextItemWidth(-1); ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 15, 5)
    local text = Widgets.input_text_with_hint(self.ctx, '##assetBrowserSearchbar', self:text('GENERIC_SEARCH_HINT'), state.search)
    ImGui.PopStyleVar()
    state.search = Widgets.validated_text(state.search, text, math.max(#state.search + 32, 256))
    local items = {}
    for _, item in pairs(data or self.f.datasets[kind]) do
        local name = label(item)
        local match = name and name:lower():find(state.search:lower(), 1, true)
        if match and kind == 'anims' then
            match = (state.category == 0 or item.category == categories[state.category + 1])
            local filter = state.filter
            match = match and
                (filter == 0 or filter == 1 and bit.band(item.flags or 0, 1) ~= 0 or filter == 2 and bit.band(item.flags or 0, 16) == 0
                    or filter == 3 and item.props and item.propPeds and (next(item.props) ~= nil or next(item.propPeds) ~= nil)
                    or filter == 4 and item.ptfx and next(item.ptfx) ~= nil or filter == 5 and item.sfx and next(item.sfx) ~= nil)
        end
        if match then items[#items + 1] = item end
    end
    table.sort(items, function(a, b) return label(a) < label(b) end)
    if ImGui.BeginListBox('##assetBrowserlistBox', -1, height or -1) then
        for index, item in ipairs(items) do
            local name = label(item)
            ImGui.Selectable(name, state.selected and label(state.selected.data) == name or false)
            if ImGui.IsItemClicked(0) then
                state.selected = { kind = kind, data = item, default_flags = item.flags }; ImGui.SetItemDefaultFocus()
            end
            self:context(kind, item, mode, index)
            if self.context_selected then
                state.selected = self.context_selected; self.context_selected = nil
            end
        end
        ImGui.EndListBox()
    end
    ImGui.PopID()
    return state.selected
end

function View:history()
    local f = self.f
    if #f.history == 0 and not f.history_locked then
        ImGui.TextWrapped(self:text('YAV3_ANIM_HISTORY_TT')); return
    end
    ImGui.BeginDisabled(f.history_locked or false)
    if Widgets.button(self.ctx, self:text('GENERIC_CLEAR')) then
        f:clear_history(); self.history_selected = nil
    end
    ImGui.Separator()
    if (f.history_clear_count or #f.history) > 1 then
        local mode, changed = ImGui.Combo(self:text('GENERIC_LIST_SORT'), f.history_sort or 0,
            { self:text('GENERIC_TIME'), self:text('GENERIC_TYPE'), self:text('GENERIC_LABEL') }, 3)
        if changed then f:sort_history(mode) end
    end
    local items = {}; for index, entry in ipairs(f.history) do items[#items + 1] = { entry = entry, index = index } end
    local remove
    if ImGui.BeginListBox('##playHistory', -1, -1) then
        for _, row in ipairs(items) do
            local entry = row.entry
            ImGui.PushID(row.index); ImGui.SetWindowFontScale(0.8); ImGui.TextDisabled(os.date('%H:%M', entry.timestamp)); ImGui
                .SetWindowFontScale(1)
            local type_name = ({ anims = 'Animation', scenarios = 'Scenario', scenes = 'Synchronized Scene', clipsets = 'Movement Clipset' })
                [entry.kind]
            ImGui.SameLine(); ImGui.Selectable('[' .. type_name .. ']  ' .. label(entry.data),
                self.history_selected and label(self.history_selected.data) == label(entry.data) or false, 0,
                ImGui.GetContentRegionAvail() - 80, ImGui.GetTextLineHeight())
            if ImGui.IsItemClicked(0) then
                self.history_selected = {
                    kind = entry.kind,
                    data = entry.data,
                    default_flags =
                        entry.data.flags
                }
            end
            local x1, y1 = ImGui.GetItemRectMin(); local x2, y2 = ImGui.GetItemRectMax()
            if ImGui.IsMouseHoveringRect(x1, y1, x2 + 30, y2, true) then
                ImGui.SameLine(); if ImGui.SmallButton(' x ') then remove = row.index end
                Widgets.tooltip(self.ctx, self:text('GENERIC_DELETE'))
            end
            ImGui.PopID()
        end
        ImGui.EndListBox()
    end
    if remove then
        local entry = table.remove(f.history, remove); f.history_set[label(entry.data)] = nil
    end
    ImGui.EndDisabled()
    return self.history_selected
end

function View:footer(selected)
    local f = self.f
    ImGui.Separator(); ImGui.SetNextWindowBgAlpha(0.69)
    if ImGui.BeginChild('##player_footer', 0, 65, true, ImGuiWindowFlags.NoScrollbar) then
        local width = math.max(ImGui.CalcTextSize(self:text('GENERIC_PLAY')),
            ImGui.CalcTextSize(self:text('GENERIC_STOP'))) + 20 + ImGui.GetStyle().ItemSpacing.x
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 10, 10)
        ImGui.BeginDisabled(not selected or f.player_busy)
        if Widgets.button(self.ctx, self:text('GENERIC_PLAY'), width, 35) then
            self:run('play player action',
                function() f:play(selected.kind, selected.data) end)
        end
        ImGui.EndDisabled(); ImGui.SameLine()
        ImGui.BeginDisabled(not f.playing[f.identity])
        if Widgets.button(self.ctx, self:text('GENERIC_STOP'), width, 35) then
            self:run('stop player action',
                function() f:stop(f.identity) end)
        end
        ImGui.EndDisabled()
        if selected and selected.kind == 'anims' then
            ImGui.SameLine(); ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() -
                ImGui.CalcTextSize(self:text('GENERIC_OPTIONS_LABEL')) - 25)
            if Widgets.button(self.ctx, self:text('GENERIC_OPTIONS_LABEL'), 0, 35) then
                local name = label(selected.data)
                if self.default_flags[name] == nil then self.default_flags[name] = selected.data.flags or 0 end
                selected.default_flags = self.default_flags[name]
                self.flag_action = selected; ImGui.OpenPopup('##animflags')
            end
        end
        ImGui.PopStyleVar()
    end
    ImGui.EndChild()
    local _, draw = ImGui.BeginPopupModal('##animflags', true,
        bit.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.AlwaysAutoResize))
    if draw then
        if Widgets.quick_config(self.ctx, self:text('GENERIC_OPTIONS_LABEL')) then
            if ImGui.BeginChild('##flagsChild', 500, 400, false) then
                ImGui.SeparatorText(self:text('GENERIC_GENERAL_LABEL'))
                for _, entry in ipairs({ { 'disable_props', 'YAV3_DISABLE_PROPS' }, { 'disable_ptfx', 'YAV3_DISABLE_PTFX' }, { 'disable_sfx', 'YAV3_DISABLE_SFX' } }) do
                    self:setting('features.yim_actions.' .. entry[1], entry[2])
                end
                ImGui.Spacing(); ImGui.SeparatorText(self:text('YAV3_ANIM_FLAGS'))
                local action = self.flag_action; local bits = {}
                for index = 31, 0, -1 do
                    bits[#bits + 1] = bit.band(action.data.flags or 0, bit.lshift(1, index)) ~= 0 and
                        '1' or '0'
                end
                ImGui.TextDisabled(table.concat(bits)); ImGui.SameLine()
                ImGui.BeginDisabled(action.data.flags == action.default_flags)
                if Widgets.button(self.ctx, self:text('GENERIC_RESET')) then
                    action.data.flags = action.default_flags or
                        0
                end
                ImGui.EndDisabled(); ImGui.Spacing(); ImGui.Separator()
                for _, entry in ipairs(flags) do
                    local mask = bit.lshift(1, entry[2]); local _, changed = ImGui.Checkbox(self:text(entry[1]),
                        bit.band(action.data.flags or 0, mask) ~= 0)
                    if changed then
                        action.data.flags = bit.bxor(action.data.flags or 0, mask); self.ctx.view:play_navigation()
                    end
                    if entry[2] == 21 and ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
                        Widgets.tooltip(
                            self.ctx, self:text('YAV3_FLAGS_DEAD_POSE_LOOPED_TT'))
                    end
                end
            end
            ImGui.EndChild()
        end
        ImGui.EndPopup()
    end
end

function View:actions()
    local selected
    if ImGui.BeginChild('##actions_sidebar', 160, self.ctx.settings:get('ui.height') * 0.7, false) then
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 20); ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 40); ImGui
            .Dummy(1, 100)
        for index, name in ipairs({ 'Animations', 'Scenarios', 'Favorites', 'History' }) do
            local selected = self.sidebar == index
            if selected then
                local color = self.ctx.theme:current().Colors.ButtonActive; ImGui.PushStyleColor(ImGuiCol.Button,
                    color.x or color[1], color.y or color[2], color.z or color[3], color.w or color[4])
            end
            if ImGui.Button(name, selected and 150 or 128, 35) then
                self.sidebar = index; self.ctx.view:play_navigation()
            end
            if selected then ImGui.PopStyleColor() end
        end
        ImGui.PopStyleVar(2)
        local tips = { self:text('YAV3_STOP_BTN_HINT', self.ctx.input:key_name('stop_anim')), self:text(
            'YAV3_SYMBOL_DEFS_HINT', '[*]', '[C]', '[U]'), self:text('YAV3_LIST_VIEW_HINT'), self:text('YAV3_VEH_ANIM_HINT') }
        local w, h = ImGui.GetContentRegionAvail()
        ImGui.SetWindowFontScale(0.7); local _, text_height = ImGui.CalcTextSize(tips[self.tip], false, w)
        local y = ImGui.GetCursorPosY(); ImGui.SetCursorPos(0, math.max(y, y + h - text_height - 25)); ImGui.TextWrapped(
            tips[self.tip])
        if ImGui.SmallButton('<    ') then
            self.tip = (self.tip - 2) % #tips + 1; self.ctx.view:play_navigation()
        end
        Widgets.tooltip(self.ctx, self:text('GENERIC_PREVIOUS'))
        ImGui.SameLine(); ImGui.SetWindowFontScale(1.25); ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 1, 1)
        for index = 1, #tips do
            ImGui.SetCursorPosY(ImGui.GetCursorPosY() - 10); ImGui.BeginDisabled(index ~= self.tip); ImGui.Text('.'); ImGui
                .EndDisabled()
            if index < #tips then ImGui.SameLine() end
        end
        ImGui.PopStyleVar(); ImGui.SetWindowFontScale(0.7); ImGui.SameLine()
        if ImGui.SmallButton('    >') then
            self.tip = self.tip % #tips + 1; self.ctx.view:play_navigation()
        end
        Widgets.tooltip(self.ctx, self:text('GENERIC_NEXT'))
        ImGui.SetWindowFontScale(1)
    end
    ImGui.EndChild(); ImGui.SameLine()
    if ImGui.BeginChild('##yim_actions_main', 0, self.ctx.settings:get('ui.height') * 0.7, true) then
        if self.sidebar == 1 then
            selected = self:browser('anims', 'main', 'Animations')
        elseif self.sidebar == 2 then
            selected = self:browser('scenarios', 'main', 'Scenarios')
        elseif self.sidebar == 3 then
            if ImGui.BeginTabBar('##Favorites') then
                for _, entry in ipairs({ { 'Animations', 'anims' }, { 'Scenarios', 'scenarios' }, { 'Scenes', 'scenes' } }) do
                    if ImGui.BeginTabItem(entry[1]) then
                        if entry[2] == 'scenes' then
                            ImGui.Dummy(1, 60); ImGui.TextDisabled(self:text('GENERIC_UNAVAILABLE'))
                        elseif next(self.f.favorites.data[entry[2]]) then
                            selected = self:browser(entry[2], 'favorites', 'Favorites', self.f.favorites.data[entry[2]])
                        else
                            ImGui.TextWrapped("You don't have any saved " .. entry[2] .. '.')
                        end
                        ImGui.EndTabItem()
                    end
                end
                ImGui.EndTabBar()
            end
        else
            selected = self:history()
        end
    end
    ImGui.EndChild(); self.f.selected = selected; self:footer(selected)
end

function View:movements()
    ImGui.Spacing(); ImGui.Spacing()
    for index, name in ipairs({ 'Custom Movements', 'All Movement Clipsets', 'Favorites' }) do
        if index > 1 then ImGui.SameLine() end
        self.clipset_mode = ImGui.RadioButton(name, self.clipset_mode, index - 1)
    end
    local selected
    if ImGui.BeginChild('##movementClipsets', 0, self.ctx.settings:get('ui.height') * 0.6, true) then
        if self.clipset_mode == 0 then
            selected = self:browser('clipsets', 'main', 'Custom Movements')
        elseif self.clipset_mode == 2 then
            if next(self.f.favorites.data.clipsets) then
                selected = self:browser('clipsets', 'favorites', 'Movement Favorites', self.f.favorites.data.clipsets)
            else
                ImGui.TextWrapped("You don't have any saved clipsets.")
            end
        elseif self.imported and #self.imported > 0 then
            ImGui.BeginDisabled(not self.import_ready); selected = self:browser('clipsets', 'other', 'Imported Movements',
                self.imported); ImGui.EndDisabled()
        else
            local exists = FileMgr.DoesFileExist('movementClipsetsCompact.json')
            if not exists then
                ImGui.TextWrapped("Download movementClipsetsCompact.json and save it in the script data folder.")
                local url = 'https://github.com/DurtyFree/gta-v-data-dumps/blob/master/movementClipsetsCompact.json'
                ImGui.TextColored(0, 0, 0.933, 1, url)
                if ImGui.IsItemClicked(1) then ImGui.SetClipboardText(url) end
            end
            ImGui.Dummy(1, 10); ImGui.BeginDisabled(not exists)
            if Widgets.button(self.ctx, 'Read From Json') then
                local data = self.f.favorites:read('movementClipsetsCompact.json')
                if type(data) ~= 'table' then
                    self.ctx.notifier:error('YimActions',
                        'Failed to read clipset data from Json. Are you sure you have the correct file?', 5)
                else
                    self.imported = {}; self.import_ready = false
                    for _, item in ipairs(data) do
                        if type(item) == 'table' and type(item.Name) == 'string' then
                            self.imported[#self.imported + 1] = {
                                Name =
                                    item.Name,
                                mvmt = item.Name
                            }
                        end
                    end
                    table.sort(self.imported, function(a, b) return a.Name < b.Name end)
                    self:run('read movement JSON',
                        function(valid)
                            script.yield(400); if valid() then self.import_ready = true end
                        end)
                end
            end
            ImGui.EndDisabled()
        end
    end
    ImGui.EndChild()
    if ImGui.BeginChild('##mvmts_footer', 0, 65, true) then
        ImGui.BeginDisabled(not selected)
        if Widgets.button(self.ctx, self:text('GENERIC_APPLY'), 80, 35) then
            self:run('apply movement',
                function() self.f:play('clipsets', selected.data) end)
        end
        ImGui.EndDisabled(); ImGui.SameLine()
        if Widgets.button(self.ctx, self:text('GENERIC_RESET'), 80, 35) then
            self:run('reset movement',
                function() self.f:reset_movement(self.f.identity) end)
        end
    end
    ImGui.EndChild()
end

function View:companions()
    local f = self.f; local height = self.ctx.settings:get('ui.height') * 0.4
    if ImGui.BeginChild('##spawned_companions', math.max(100, ImGui.GetContentRegionAvail() - 160 - ImGui.GetStyle().ItemSpacing.x * 3), height, true) then
        if #f.companions.members == 0 then
            ImGui.Text('No companions spawned.')
        elseif ImGui.BeginListBox('##spawned_companions', -1, -1) then
            for _, member in ipairs(f.companions.members) do
                ImGui.PushID(member.handle); ImGui.Selectable(member.name .. ' [' .. member.handle .. ']',
                    self.companion == member)
                if ImGui.IsItemClicked(0) then self.companion = member end
                if ImGui.IsItemClicked(1) then
                    self.companion = member; ImGui.OpenPopup('##companion_controls')
                end
                if ImGui.BeginPopup('##companion_controls') then
                    if ImGui.MenuItem('Warp Into Vehicle') then
                        self:run('warp companion', function()
                            local state = self.ctx.state:read()
                            if state and state.vehicle then
                                TASK.TASK_WARP_PED_INTO_VEHICLE(member.handle, state.vehicle_handle, -2)
                            else
                                self.ctx.notifier:warn("Samurai's Scripts", 'No vehicle to warp into.')
                            end
                        end)
                    end
                    ImGui.EndPopup()
                end
                ImGui.PopID()
            end
            ImGui.EndListBox()
        end
    end
    ImGui.EndChild(); ImGui.SameLine()
    if ImGui.BeginChild('##companion_controls', 0, height, false) then
        local function button(name, callback, disabled)
            ImGui.BeginDisabled(disabled or false)
            if Widgets.button(self.ctx, name, 160, 32) then self:run('companion control', callback) end
            ImGui.EndDisabled()
        end
        if Widgets.button(self.ctx, 'Spawn Companion', 160, 32) then self.spawner_open = true end
        local member = self.companion
        if member and #f.companions.members > 0 then
            button('Remove', function()
                f.companions:remove(member); self.companion = nil
            end)
            button(member.godmode and 'Disable God Mode' or 'Enable God Mode',
                function()
                    member.godmode = not member.godmode; ENTITY.SET_ENTITY_INVINCIBLE(member.handle, member.godmode, false)
                end)
            button(member.armed and 'Disarm' or 'Arm', function()
                member.armed = not member.armed
                if member.armed then
                    WEAPON.GIVE_WEAPON_TO_PED(member.handle, 350597077, 9999, false, true)
                else
                    WEAPON
                        .REMOVE_ALL_PED_WEAPONS(member.handle, true)
                end
            end)
            local selected = self.companion_action
            button('Play', function() f:play(selected.kind, selected.data, member.handle) end, not selected)
            button('Stop', function() f:stop(member.handle) end, not selected or not f.playing[member.handle])
            button('All Play',
                function(valid)
                    for _, entry in ipairs(f.companions.members) do
                        if not valid() then return end; f:play(selected.kind, selected.data, entry.handle)
                    end
                end, not selected or #f.companions.members <= 1)
            local playing = false; for _, entry in ipairs(f.companions.members) do if f.playing[entry.handle] then playing = true end end
            button('Stop All', function() for _, entry in ipairs(f.companions.members) do f:stop(entry.handle) end end,
                #f.companions.members <= 1 or not playing)
            button('Bring All', function(valid) f.companions:bring(valid) end, #f.companions.members == 0)
        end
    end
    ImGui.EndChild(); ImGui.SeparatorText('Companion Actions')
    if ImGui.BeginChild('##companion_actions_child', 0, 335, true) then
        if ImGui.BeginTabBar('##companion_actions_tabbar') then
            for _, entry in ipairs({ { 'Animations##companions', 'anims' }, { 'Scenarios##companions', 'scenarios' } }) do
                if ImGui.BeginTabItem(entry[1]) then
                    self.companion_action = self:browser(entry[2], 'main', entry[1]); ImGui.EndTabItem()
                end
            end
            ImGui.EndTabBar()
        end
    end
    ImGui.EndChild(); self:footer(self.companion_action)
    if self.spawner_open then
        local draw = ImGui.Begin('Companion Spawner', nil,
            bit.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoResize,
                ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.NoCollapse))
        if draw then
            if Widgets.button(self.ctx, self:text('GENERIC_CLOSE')) then self.spawner_open = false end
            ImGui.Separator(); ImGui.Dummy(1, 10)
            self.ped_browser = self.ped_browser or
                require('includes.ssv2.core.model_browser').new(self.ctx, { fixed_kind = 1, max_entries = 250 })
            local model = self.ped_browser:draw(self.ctx.preview, { x = 400, y = 400 })
            self.godmode = Widgets.toggle(self.ctx, 'Spawn Invincible', self.godmode or false); ImGui.SameLine()
            self.armed = Widgets.toggle(self.ctx, 'Spawn Armed', self.armed or false)
            ImGui.Spacing(); ImGui.BeginDisabled(not model)
            if Widgets.button(self.ctx, 'Spawn', 80, 35) then
                local godmode, armed = self.godmode, self.armed
                self:run('spawn companion', function(valid)
                    f.companions:spawn(model.model, model.name, godmode, armed, valid)
                    if self.ctx.settings:get('features.yim_actions.auto_close_ped_window') then self.spawner_open = false end
                end)
            end
            ImGui.EndDisabled(); ImGui.SameLine(); self:setting('features.yim_actions.auto_close_ped_window',
                'Auto-Close Window')
        end
        ImGui.End()
    end
end

function View:commands()
    if not self.command_open then return end
    ImGui.SetNextWindowSize(400, 200, ImGuiCond.Always)
    local w, h = ImGui.GetDisplaySize(); ImGui.SetNextWindowPos((w - 400) * 0.5, (h - 200) * 0.5, ImGuiCond.Always)
    local draw = ImGui.Begin('##yav3_new_command', nil,
        bit.bor(ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoTitleBar,
            ImGuiWindowFlags.NoSavedSettings, ImGuiWindowFlags.AlwaysAutoResize))
    if draw then
        ImGui.Dummy(0, 20); ImGui.SetNextItemWidth(-1)
        local text = Widgets.input_text_with_hint(self.ctx, '##cmd', 'Command Name (ex: /sitdown)', self.command_name,
            ImGuiInputTextFlags.CharsNoBlank)
        self.command_name = Widgets.validated_text(self.command_name, text, 64)
        ImGui.Dummy(0, 40); ImGui.BeginDisabled(self.command_name == '')
        if Widgets.button(self.ctx, self:text('GENERIC_CONFIRM')) then
            local name = self.command_name; local action = self.command_action
            if self.f.commands.data.aliases[name] or self.ctx.console:lookup(name) or self:command_for(action.kind, label(action.data)) then
                self.ctx.notifier:error('YimActions', "Command '" .. name .. "' already exists.")
            else
                local values = copy(self.f.commands.data.aliases); values[name] = {
                    kind = action.kind,
                    label = label(
                        action.data),
                    data = copy(action.data.data or action.data)
                }
                self.f.commands:set('aliases', values); self.f.commands:save()
                self.ctx.notifier:success('YimActions', "New command successfully registered: '" .. name .. "'")
                self.command_name = ''; self.command_open = false
            end
        end
        ImGui.EndDisabled(); ImGui.SameLine()
        if Widgets.button(self.ctx, self:text('GENERIC_CANCEL')) then
            self.command_name = ''; self.command_open = false
        end
    end
    ImGui.End()
end

function View:debug()
    local f = self.f
    if ImGui.SmallButton('!Summon Wompus') then self:run('wompus start', function() f.wompus:start() end) end
    ImGui.Spacing(); ImGui.SeparatorText('Global Data')
    local count = { actors = 0, props = 0, effects = 0 }
    for _ in pairs(f.playing) do count.actors = count.actors + 1 end
    for _, owner in pairs(f.props.owners) do
        count.props = count.props + #owner.entities; count.effects = count.effects + #owner.effects
    end
    ImGui.BulletText('Active Actions: [ ' .. count.actors .. ' ]'); ImGui.BulletText('Active Props: [ ' ..
        count.props .. ' ]'); ImGui.BulletText('Active FX: [ ' .. count.effects .. ' ]')
    ImGui.Spacing(); ImGui.Spacing(); ImGui.SeparatorText('Actors')
    local actors = f.debug_actors or {}
    if not next(actors) then
        ImGui.Text('None.'); return
    end
    ImGui.SetNextItemWidth(200)
    if ImGui.BeginCombo('##debugActors', actors[self.debug_actor] and actors[self.debug_actor].name or 'Actors') then
        for handle, actor in pairs(actors) do
            ImGui.Selectable(actor.name, self.debug_actor == handle); if ImGui.IsItemClicked() then
                self.debug_actor = handle; self.debug_prop = nil
            end
        end
        ImGui.EndCombo()
    end
    local actor = actors[self.debug_actor]; if not actor then return end
    ImGui.BulletText('Current Actor: [ ' .. actor.name .. ' ]'); ImGui.BulletText('Is Player: [ ' ..
        tostring(actor.player) .. ' ]')
    local current = f.playing[self.debug_actor]
    if current then
        ImGui.BulletText('Current Action:'); ImGui.Indent(); ImGui.Text('- Label: ' ..
            (label(current.data) or 'N/A') ..
            '\n- Type: [ ' ..
            (({ anims = 'Animation', scenarios = 'Scenario', scenes = 'Synchronized Scene', clipsets = 'Movement Clipset' })[current.kind] or 'Unknown') ..
            ' ]'); ImGui.Unindent(); ImGui.Dummy(1, 10)
    end
    local owner = f.props.owners[self.debug_actor]
    if not owner or #owner.entities == 0 then return end
    ImGui.BeginGroup()
    if ImGui.BeginChild('##debugProplist', 200, 200, true, ImGuiWindowFlags.AlwaysUseWindowPadding) then
        ImGui.SeparatorText('Props')
        for _, entry in ipairs(owner.entities) do
            ImGui.Selectable(tostring(entry.handle), self.debug_prop and self.debug_prop.handle == entry.handle or false)
            if ImGui.IsItemClicked() then
                self.debug_prop = { handle = entry.handle, type = entry.kind, attached = nil }; local selected = self
                    .debug_prop
                self:run('inspect action prop',
                    function()
                        if ENTITY.DOES_ENTITY_EXIST(entry.handle) then
                            selected.attached = ENTITY
                                .IS_ENTITY_ATTACHED(entry.handle)
                        end
                    end)
            end
        end
    end
    ImGui.EndChild(); ImGui.SameLine(); ImGui.SetNextWindowBgAlpha(0)
    if ImGui.BeginChild('##debugPropInfo', 250, 200, false) then
        ImGui.SeparatorText('Prop Info')
        if not self.debug_prop then
            ImGui.TextColored(1, 1, 0, 1, 'Not Selected.')
        else
            ImGui.BulletText('Prop Type: [ ' .. self.debug_prop.type .. ' ]'); ImGui.BulletText('Is Attached: [ ' ..
                tostring(self.debug_prop.attached) .. ' ]')
        end
    end
    ImGui.EndChild(); ImGui.EndGroup()
    local handle = self.debug_actor
    if Widgets.button(self.ctx, 'Remove Props') then
        self:run('action debug props',
            function() f.props:clear_props(handle) end)
    end
    ImGui.SameLine(); if Widgets.button(self.ctx, 'Stop FX') then
        self:run('action debug fx',
            function() f.props:clear_effects(handle) end)
    end
    ImGui.SameLine(); if Widgets.button(self.ctx, 'Reset') then
        self:run('action debug reset',
            function() if ENTITY.DOES_ENTITY_EXIST(handle) then TASK.CLEAR_PED_TASKS_IMMEDIATELY(handle) end end)
    end
    if Widgets.button(self.ctx, 'Wipe') then self:run('action debug wipe', function() f:cleanup() end) end
end

function View:draw()
    local f = self.f
    if not self.ctx.settings:get('ui.show_actions') then return end
    if f.failed and Widgets.button(self.ctx, 'Retry Yim Actions') then f.failed = false end
    if not f.active then
        ImGui.Text('YimActions requires a living player.'); return
    end
    ImGui.BeginDisabled(self.command_open or false)
    if ImGui.BeginTabBar('##yimactionsv3') then
        for _, entry in ipairs({ { 'Actions', 'actions' }, { 'Movement Styles', 'movements' }, { 'Companions', 'companions' } }) do
            if ImGui.BeginTabItem(entry[1]) then
                self[entry[2]](self); ImGui.EndTabItem()
            end
        end
        if self.ctx.settings:get('backend.debug_mode') and ImGui.BeginTabItem('Debug##YAV3') then
            self:debug(); ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
    ImGui.EndDisabled(); self:commands()
end

return function(ctx, f)
    local view = View.new(ctx, f); f.frontend = view
    return function() view:draw() end
end
