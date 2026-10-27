-- EntityForge's original tab/dialog and attachment-editor workflow, using V2 APIs.
-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors. GPL-3.0-or-later.
local Widgets = require('includes.ssv2.core.widgets')
local Codec = require('includes.ssv2.core.codec')
local Appearance = require('includes.ssv2.core.appearance')
local Refs = require('includes.ssv2.data.forge_refs')
local View = {}; View.__index = View
local function copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}; for key, item in pairs(value) do result[key] = copy(item) end; return result
end
local function wrap(text) return text:gsub('(.?' .. string.rep('.', 39) .. ')', '%1\n') end
function View.new(ctx, f)
    local self = setmetatable(
        {
            ctx = ctx,
            f = f,
            attach_to = 0,
            ped_bone = 0,
            veh_bone = 'chassis',
            vehicle_bones = {},
            movement = 1,
            rotation = 1,
            name =
            ''
        }, View)
    menu.add_always_draw_imgui(function() self:draw_independent() end)
    event.register_handler(menu_event.WndProc, function(_, message, key, detail)
        if message == 256 and key == 0x49 and bit.band(detail or 0, 0x40000000) == 0
            and (self.axis_open or self.custom_open) and not ctx.input.capture and not ctx.console.open then
            self.mouse_override = not self.mouse_override; ctx.view:update_mouse()
        end
    end)
    return self
end

function View:text(key, ...)
    if select('#', ...) > 0 then return self.ctx.translator:format(key, ...) end; return self.ctx.translator:text(key)
end

function View:button(label, callback, disabled, width, height)
    ImGui.BeginDisabled(disabled or false)
    if Widgets.button(self.ctx, self:text(label), width or 0, height or 0) and not disabled then callback() end
    ImGui.EndDisabled()
end

function View:run(label, callback) self.f:run(label, callback) end

function View:help(text)
    if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and not self.ctx.settings:get('ui.disable_tooltips') then
        Widgets.tooltip(self.ctx, self:text(text))
    end
end

function View:setting(path, label)
    local value, changed = ImGui.Checkbox(self:text(label), self.ctx.settings:get(path))
    if changed then self.ctx.settings:set(path, value) end
end

function View:name_dialog(title, callback, hint)
    local _, draw = ImGui.BeginPopupModal(title, true,
        bit.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.AlwaysAutoResize))
    if not draw then return end
    ImGui.Spacing(); ImGui.SetNextItemWidth(400)
    local value = Widgets.input_text_with_hint(self.ctx, '##name', 'Name', self.name)
    self.name = Widgets.validated_text(self.name, value, 128)
    if hint then
        ImGui.Spacing(); ImGui.Text(self:text(hint))
    end
    ImGui.Spacing()
    local confirm
    if title == 'Add Favorite' then
        confirm = Widgets.button(self.ctx, self:text('GENERIC_CONFIRM'))
    else
        confirm = ImGui.Button(self:text('GENERIC_CONFIRM'), 80, 30)
    end
    if confirm then
        if callback(self.name) ~= false then
            self.name = ''; ImGui.CloseCurrentPopup()
        end
    end
    ImGui.SameLine()
    if Widgets.button(self.ctx, self:text('GENERIC_CANCEL')) then
        self.name = ''; ImGui.CloseCurrentPopup()
    end
    ImGui.EndPopup()
end

function View:confirm(title, callback)
    if Widgets.dialog(self.ctx, title) then callback() end
end

function View:spawner()
    local f = self.f; local height = self.ctx.settings:get('ui.height') * 0.7
    if ImGui.BeginChild('##sidebar', 160, height, false) then
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 20); ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 40)
        ImGui.SetWindowFontScale(1.05); ImGui.SeparatorText('Game Entities'); ImGui.SetWindowFontScale(1); ImGui.Dummy(1,
            40)
        for _, entry in ipairs({ { 'Peds', 1 }, { 'Vehicles', 2 }, { 'Objects', 0 } }) do
            local selected = f.browser.kind == entry[2]
            if selected then
                local col = self.ctx.theme:current().Colors.ButtonActive; ImGui.PushStyleColor(ImGuiCol.Button,
                    col.x or col[1], col.y or col[2], col.z or col[3], col.w or col[4])
            end
            if Widgets.button(self.ctx, entry[1], selected and 158 or 128, 35) then f.browser:select_kind(entry[2]) end
            if selected then ImGui.PopStyleColor() end
        end
        ImGui.PopStyleVar(2)
    end
    ImGui.EndChild(); ImGui.SameLine()
    if ImGui.BeginChild('##items', 0, height, true) then
        ImGui.PushID(f.browser.uid)
        local model = f.browser:draw_list(f.preview, ({ 'object', 'ped', 'vehicle' })[f.browser.kind + 1],
            { x = 0, y = math.max(200, height - 220) })
        ImGui.PopID(); self.model = model
        ImGui.Spacing()
        self:button('GENERIC_SPAWN', function()
            self:run('spawn forge model', function(valid)
                local pos = f.preview.current and ENTITY.GET_ENTITY_COORDS(f.preview.current.handle, false) or nil
                f.selected = f.forge:spawn(model.model or model.name, model.label, model.kind, pos, 255, valid)
            end)
        end, not model, 120, 35)
        ImGui.SameLine()
        self:button('Add To Favorites', function()
            self.name = ''; ImGui.OpenPopup('Add Favorite')
        end, not model, ImGui.CalcTextSize('Add To Favorites') + 20, 35)
        self:name_dialog('Add Favorite', function(name)
            if not model then return false end
            f:favorite({ model = model.model or util.joaat(model.name), name = model.label, kind = model.kind, alpha = 255 },
                name)
        end)
    end
    ImGui.EndChild(); ImGui.Dummy(1, 10); ImGui.SeparatorText('Preferences')
    self:setting('features.entity_forge.entity_gun', 'Entity Grabber'); ImGui.SameLine()
    self:button('Cleanup Everything',
        function()
            self:run('forge cleanup', function()
                f.forge:clear(); f.selected = nil; self.parent = nil
            end)
        end, #f.forge.order == 0)
end

function View:spawned()
    local f = self.f
    if #f.forge.order == 0 then
        ImGui.Dummy(1, 10); ImGui.TextWrapped('Spawned and/or grabbed entities will appear here.'); return
    end
    if ImGui.BeginListBox('##SpawnedEntities', 530, 280) then
        for _, entry in ipairs(f.forge.order) do
            local name = entry.name ..
                ' [' .. (entry.player and 'Yourself' or entry.handle) .. ']' .. (entry.forged and '  (Saved Creation)' or '')
            ImGui.Selectable(name, f.selected == entry)
            if ImGui.IsItemClicked(0) then f.selected = entry end
        end
        ImGui.EndListBox()
    end
    self:setting('features.entity_forge.mark_selected', 'Mark Selected Entity'); ImGui.SameLine()
    self:setting('features.entity_forge.entity_gun', 'EF_ENTITY_GUN'); self:help('EF_ENTITY_GUN_TT'); ImGui.Spacing()
    local selected = f.selected
    self:button('GENERIC_DELETE',
        function()
            self:run('delete forge entity',
                function()
                    f.forge:remove(selected, selected.forged); f.selected = nil
                end)
        end, not selected)
    ImGui.SameLine(); self:button('Delete All',
        function()
            self:run('delete forge entities', function()
                f.forge:clear(); f.selected = nil
            end)
        end, #f.forge.order == 0)
    local count = 0; for _, entry in ipairs(f.forge.order) do if entry.world then count = count + 1 end end
    if selected and selected.world then
        self:button('Free From Forge Pool',
            function()
                self:run('release world entity', function()
                    f.forge:release(selected); f.selected = nil
                end)
            end)
    end
    if count > 1 then
        ImGui.SameLine(); self:button('Free Up All World Entities',
            function()
                self:run('release world entities', function()
                    for index = #f.forge.order, 1, -1 do
                        local entry = f.forge.order[index]; if entry.world then f.forge:release(entry) end
                    end
                end)
            end)
    end
end

function View:favorites()
    local f = self.f; local values = f.favorites.data.models
    if not next(values) then
        ImGui.Dummy(1, 10); ImGui.TextWrapped("You don't have any saved favorites."); return
    end
    if ImGui.BeginListBox('##FavoriteEntities', 530, 280) then
        for key, item in pairs(values) do
            ImGui.Selectable(item.name, self.favorite_key == key); if ImGui.IsItemClicked(0) then self.favorite_key = key end
        end
        ImGui.EndListBox()
    end
    local item = values[self.favorite_key]; ImGui.Spacing()
    self:button('GENERIC_SPAWN',
        function()
            self:run('spawn favorite model',
                function(valid)
                    f.selected = f.forge:spawn(item.model, item.name, item.kind, nil, item.alpha or 255,
                        valid)
                end)
        end, not item)
    ImGui.SameLine(); self:button('Rename', function()
        self.name = ''; ImGui.OpenPopup('Rename Favorite')
    end, not item)
    self:name_dialog('Rename Favorite', function(name)
        if not item then return false end
        local next_values = copy(values); next_values[self.favorite_key].name = name; f.favorites:set('models',
            next_values); f.favorites:save()
    end)
    self:button('GENERIC_REMOVE', function() ImGui.OpenPopup('Remove Favorite') end, not item)
    self:confirm('Remove Favorite',
        function()
            local next_values = copy(values); next_values[self.favorite_key] = nil; f.favorites:set('models', next_values); f
                .favorites:save(); self.favorite_key = nil
        end)
    ImGui.SameLine(); self:button('GENERIC_REMOVE_ALL', function() ImGui.OpenPopup('Remove All Favorites') end,
        not next(values))
    self:confirm('Remove All Favorites',
        function()
            f.favorites:set('models', {}); f.favorites:save(); self.favorite_key = nil
        end)
end

function View:saved()
    local f = self.f; local values = f.saved.data.creations
    if not next(values) then
        ImGui.Dummy(1, 10); ImGui.TextWrapped(self:text('EF_SAVED_NONE')); return
    else
        if ImGui.BeginListBox('##ForgedEntities', 530, 280) then
            for name in pairs(values) do
                ImGui.Selectable(name, self.saved_name == name); if ImGui.IsItemClicked(0) then self.saved_name = name end
            end
            ImGui.EndListBox()
        end
    end
    local item = values[self.saved_name]; ImGui.Spacing()
    self:button('GENERIC_SPAWN',
        function()
            self:run('spawn saved forge',
                function(valid)
                    f.selected = f.forge:load(item, valid); self.parent = f.selected
                end)
        end, not item)
    ImGui.SameLine(); self:button('GENERIC_RENAME', function()
        self.name = ''; ImGui.OpenPopup('Rename Saved Creation')
    end, not item)
    self:name_dialog('Rename Saved Creation', function(name)
        if values[name] then
            self.ctx.notifier:error('EntityForge', self:text('EF_NAME_EXISTS_ERR')); return false
        end
        if not item then return false end
        local next_values = copy(values); next_values[name] = copy(item); next_values[name].name = name; next_values[self.saved_name] = nil
        f.saved:set('creations', next_values); f.saved:save(); self.saved_name = name
    end)
    ImGui.SameLine(); self:button('GENERIC_SHARE',
        function()
            self.share = Codec.encode(item, true); self.share_item = item; ImGui.OpenPopup('share creation')
        end, not item)
    local _, share = ImGui.BeginPopupModal('share creation', true,
        bit.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoTitleBar))
    if share then
        self:description(self.share_item); ImGui.Separator(); ImGui.Spacing(); ImGui.Text('Forge Data:')
        Widgets.input_text_multiline(self.ctx, '##b64', wrap(self.share), 440, 150, ImGuiInputTextFlags.ReadOnly)
        if Widgets.button(self.ctx, self:text('GENERIC_COPY')) then
            ImGui.SetClipboardText(self.share); self.ctx.notifier:success('EntityForge', self:text('EF_SHARE_SUCCESS'), 6); self.share = nil; ImGui
                .CloseCurrentPopup()
        end
        ImGui.SameLine(); if Widgets.button(self.ctx, self:text('GENERIC_CANCEL')) then
            self.share = nil; ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
    end
    ImGui.SameLine(); self:button('EF_IMPORT_DATA',
        function()
            self.import_text = ''; self.imported = nil; ImGui.OpenPopup('import creation')
        end)
    local _, import = ImGui.BeginPopupModal('import creation', true,
        bit.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoTitleBar))
    if import then
        if self.imported then
            self:description(self.imported); ImGui.Separator(); ImGui.Spacing()
        else
            ImGui.Text(self:text('EF_IMPORT_DATA_INSTR'))
        end
        Widgets.input_text_multiline(self.ctx, '##b64', wrap(self.import_text), 440, 150, ImGuiInputTextFlags.ReadOnly)
        ImGui.Spacing()
        if not self.imported then
            if Widgets.button(self.ctx, self:text('EF_IMPORT_DATA_CLIPBOARD')) then
                local text = ImGui.GetClipboardText()
                local ok, value = pcall(Codec.decode, text)
                if ok and type(value) == 'table' and type(value.name) == 'string' and type(value.children) == 'table' then
                    self.import_text = text; self.imported = value
                else
                    self.ctx.notifier:error('EntityForge', self:text('EF_IMPORT_DATA_CLIPBOARD_ERR'))
                end
            end
        elseif Widgets.button(self.ctx, self:text('GENERIC_ADD')) then
            local value = copy(self.imported); local next_values = copy(values)
            if next_values[value.name] then
                value.name = value.name .. ' [import]'; self.ctx.notifier:warn('EntityForge',
                    self:text('EF_IMPORT_DATA_NOTICE'))
            end
            next_values[value.name] = value; f.saved:set('creations', next_values); f.saved:save()
            self.imported = nil; self.import_text = ''; ImGui.CloseCurrentPopup()
        end
        ImGui.SameLine(); if Widgets.button(self.ctx, self:text('GENERIC_CANCEL')) then
            self.imported = nil; self.import_text = ''; ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
    end
    self:button('GENERIC_REMOVE', function() ImGui.OpenPopup('Remove Creation') end, not item)
    self:confirm('Remove Creation',
        function()
            local next_values = copy(values); next_values[self.saved_name] = nil; f.saved:set('creations', next_values); f
                .saved:save(); self.saved_name = nil
        end)
    ImGui.SameLine(); self:button('GENERIC_REMOVE_ALL', function() ImGui.OpenPopup('Remove All Creations') end,
        not next(values))
    self:confirm('Remove All Creations', function()
        f.saved:set('creations', {}); f.saved:save(); self.saved_name = nil
    end)
end

function View:description(item)
    ImGui.Spacing(); ImGui.BulletText('Name: ' .. item.name)
    ImGui.BulletText('N° Of Attachments: [ ' .. #item.children .. ' ]')
    ImGui.BulletText('Nested Child Attachments: [ ' .. (item.children[1] and 'Yes' or 'No') .. ' ]')
end

function View:candidates()
    local children, parents = {}, {}
    for _, entry in ipairs(self.f.forge.order) do
        if not entry.player and not entry.forged and not entry.parent then
            children[#children + 1] = entry
            if entry ~= self.child then parents[#parents + 1] = entry end
        end
    end
    return children, parents
end

function View:select_parent(entry)
    if self.parent == entry then return end
    self.parent = entry; self.vehicle_bones = {}
    if entry and entry.kind == 'vehicle' then
        self:run('find attachment bones', function(valid)
            local bones = {}
            for _, name in ipairs(Refs.vehicle_bones) do
                if not valid() then return end; if ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(entry.handle, name) ~= -1 then
                    bones[#bones + 1] =
                        name
                end
            end
            if self.parent == entry then self.vehicle_bones = bones end
        end)
    end
end

function View:creator()
    local f = self.f
    if #f.forge.order == 0 then
        ImGui.Dummy(1, 10); ImGui.TextWrapped(self:text('EF_NONE_SPAWNED_HINT')); return
    end
    local children, parents = self:candidates(); local avail = ImGui.GetContentRegionAvail()
    local child_width = avail / 2 - ImGui.GetStyle().ItemSpacing.x * 2 - 60; local height = self.ctx.settings:get(
        'ui.height') * 0.4
    if ImGui.BeginChild('##ChildList', child_width, height, true) then
        ImGui.SeparatorText(self:text('EF_CHILD_CANDIDATES'))
        if ImGui.BeginListBox('##children', -1, -1) then
            for _, entry in ipairs(children) do
                ImGui.Selectable(entry.name .. ' [' .. entry.handle .. ']', self.child == entry); if ImGui.IsItemClicked(0) then
                    self.child =
                        entry
                end
            end
            ImGui.EndListBox()
        end
    end
    ImGui.EndChild(); ImGui.SameLine()
    if ImGui.BeginChild('##midpart', 120, height, false) then
        if self.child and self.child.kind == 'ped' and not self.child.player then
            ImGui.Dummy(1, 10); ImGui.BeginDisabled(self.custom_open or false)
            if Widgets.button(self.ctx, 'Customize') and not self.custom_open then self:open_custom(self.child) end
            ImGui.EndDisabled()
        end
        ImGui.SetCursorPosY(height * 0.5 - 40)
        local parent = self.attach_to == 1 and self.player or self.parent
        self:button(self:text('GENERIC_ATTACH') .. ' ->', function()
            local bone = parent.kind == 'ped' and Refs.ped_bones[self.ped_bone + 1].ID or
                parent.kind == 'vehicle' and self.veh_bone or 0
            local child = self.child
            self:run('attach forge entity',
                function()
                    f.forge:attach(child, parent, bone, { x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 }); self.parent =
                        parent
                end)
        end, not self.child or not parent, 100, 40)
        if parent and (parent.kind == 'ped' or parent.kind == 'vehicle') then
            ImGui.Text('Attachment\nBone:'); ImGui.SetNextItemWidth(-1)
            if parent.kind == 'ped' then
                local names = {}; for index, item in ipairs(Refs.ped_bones) do names[index] = item.name end
                self.ped_bone = ImGui.Combo('##pedBones', self.ped_bone, names, #names)
            elseif ImGui.BeginCombo('##vehBones', self.veh_bone) then
                for _, name in ipairs(self.vehicle_bones) do
                    ImGui.Selectable(name, self.veh_bone == name); if ImGui.IsItemClicked(0) then self.veh_bone = name end
                end
                ImGui.EndCombo()
            end
        end
    end
    ImGui.EndChild(); ImGui.SameLine()
    if ImGui.BeginChild('##ParentList', 0, height, true) then
        ImGui.SeparatorText(self:text('EF_PARENT_CANDIDATES')); ImGui.SetNextItemWidth(-1)
        local value, changed = ImGui.Combo('##attach_candidates', self.attach_to,
            { self:text('EF_SPAWNED_ENTITIES'), self:text('GENERIC_YOU') }, 2)
        self.attach_to = value
        if changed and value == 1 then self:run('forge player parent', function() self.player = f.forge:player() end) end
        if self.attach_to == 0 then
            if ImGui.BeginListBox('##parents', -1, -1) then
                for _, entry in ipairs(parents) do
                    ImGui.Selectable(entry.name .. ' [' .. entry.handle .. ']', self.parent == entry); if ImGui.IsItemClicked(0) then
                        self:select_parent(entry)
                    end
                end
                ImGui.EndListBox()
            end
        else
            ImGui.Dummy(1, 40); ImGui.TextWrapped(self:text('EF_SELF_ATTACH_HINT'))
        end
    end
    ImGui.EndChild()
    if self.parent and #self.parent.children > 0 then self:canvas(self.parent) end
end

function View:alpha(entry)
    ImGui.SetNextItemWidth(-1); ImGui.BeginDisabled(entry.player or false)
    local value, changed = ImGui.SliderInt('##childvis', entry.alpha or 255, 0, 255, self:text('EF_ALPHA'))
    if changed and not entry.player then
        self:run('forge opacity',
            function()
                entry.alpha = value; ENTITY.SET_ENTITY_ALPHA(entry.handle, value, false)
            end)
    end
    ImGui.EndDisabled()
    if entry.player then self:help('EF_ALPHA_PLAYER_NOT_ALLOWED') end
end

function View:axis(entry, rotation)
    if not entry then return end
    ImGui.SeparatorText(self:text(rotation and 'EF_ROTATE_OBJECT' or 'EF_MOVE_OBJECT')); ImGui.Dummy(1, 10); ImGui
        .SetNextItemWidth(-1)
    local field = rotation and 'rotation' or 'movement'
    self[field] = ImGui.SliderFloat(rotation and '##f_arvm' or '##f_amvm', self[field], 1, 100,
        self:text('EF_MULTIPLIER_LABEL'))
    ImGui.Dummy(1, 10); ImGui.PushButtonRepeat(true)
    local directions = rotation and { { 2, 3, -1, 1 }, { 0, 1, -1, 1 }, { 2, 3, 1, -1 } } or
        { { 0, 1, -1, 1 }, { 2, 3, 1, -1 }, { 2, 3, 1, -1 } }
    for index, name in ipairs({ 'X', 'Y', 'Z' }) do
        ImGui.Text(name .. ': '); ImGui.SameLine()
        for button = 1, 2 do
            if button == 2 then ImGui.SameLine() end
            if ImGui.ArrowButton('##' .. field .. name .. button, directions[index][button]) then
                local delta = { 0, 0, 0 }; delta[index] = (rotation and 0.05 or 0.001) * self[field] *
                    directions[index][button + 2]
                self:run('forge attachment axis',
                    function()
                        (rotation and self.f.forge.rotate_attachment or self.f.forge.move_attachment)(
                                self.f.forge, entry, unpack(delta))
                    end)
            end
        end
    end
    ImGui.PopButtonRepeat(); ImGui.Dummy(1, 10)
    ImGui.TextWrapped(rotation and self:text('EF_ROTATION_AXIS_HINT') or 'Movement is relative to the attachment bone.')
end

function View:canvas(parent)
    local f = self.f; local width = ImGui.GetContentRegionAvail()
    if ImGui.BeginChild('##lowerpart', 0, self.ctx.settings:get('ui.height') * 0.5, false) then
        if ImGui.BeginChild('MoveXYZ', width * 0.25, 0, false) then
            self:axis(self.canvas_child, false); ImGui.Dummy(1, 10)
            ImGui.BeginDisabled(not self.canvas_child)
            local open, changed = Widgets.toggle(self.ctx, self:text('EF_AXIS_WINDOW'), self.axis_open or false)
            if changed and self.canvas_child then
                self.axis_open = open; if open then
                    self.mouse_override = true; self.ctx.view:close(true); self.ctx.view:update_mouse()
                end
            end
            ImGui.EndDisabled(); self:help('EF_AXIS_WINDOW_TT')
        end
        ImGui.EndChild(); ImGui.SameLine()
        if ImGui.BeginChild('##current_parent', width * 0.45, 0, true) then
            ImGui.SetWindowFontScale(1.05); ImGui.SeparatorText('Parent: ' .. (parent.player and 'You' or parent.name)); ImGui
                .SetWindowFontScale(1)
            self:alpha(parent); ImGui.Spacing(); ImGui.Text(self:text('EF_CHILD_ITEMS'))
            if ImGui.BeginListBox('##ChildItems', -1, 0) then
                for index, entry in ipairs(parent.children) do
                    ImGui.Selectable(entry.name .. '##' .. index, self.canvas_child == entry); if ImGui.IsItemClicked(0) then
                        self.canvas_child =
                            entry
                    end
                end
                ImGui.EndListBox()
            end
            local child = self.canvas_child
            if child then
                if child.kind == 'ped' then
                    self:button('GENERIC_CUSTOMIZE', function() self:open_custom(child) end, self.custom_open); ImGui
                        .SameLine()
                end
                self:button('GENERIC_DETACH',
                    function()
                        self:run('detach forge child',
                            function()
                                f.forge:detach(child, true); self.canvas_child = nil
                            end)
                    end)
                ImGui.SameLine(); self:button('GENERIC_DELETE',
                    function()
                        self:run('delete forge child',
                            function()
                                f.forge:remove(child, false); self.canvas_child = nil
                            end)
                    end)
                if #parent.children > 1 then
                    self:button('GENERIC_DETACH_ALL',
                        function()
                            self:run('detach forge children',
                                function()
                                    for index = #parent.children, 1, -1 do f.forge:detach(parent.children[index], true) end; self.canvas_child = nil
                                end)
                        end)
                    ImGui.SameLine(); self:button('GENERIC_DELETE_ALL',
                        function()
                            self:run('clear forge',
                                function()
                                    f.forge:clear(); self.parent = nil; self.canvas_child = nil
                                end)
                        end)
                end
                self:alpha(child)
            end
            if parent.forged then
                self:button('Overwrite', function() ImGui.OpenPopup('Overwrite Data?') end, false, 100, 35)
                self:confirm('Overwrite Data?',
                    function()
                        self:run('overwrite forge',
                            function() f:save(parent, parent.saved_name or parent.name, true) end)
                    end)
            else
                self:button('GENERIC_SAVE', function()
                    self.name = ''; ImGui.OpenPopup('confirm save creation')
                end, false, 100, 35)
            end
            self:name_dialog('confirm save creation', function(name)
                if f.saved.data.creations[name] then
                    self.ctx.notifier:error('EntityForge', self:text('EF_NAME_EXISTS_ERR')); return false
                end
                self:run('save forge', function(valid)
                    f:save(parent, name, false); self.ctx.notifier:success('EntityForge',
                        self:text('EF_NEW_FORGE_SUCCESS', name))
                    script.yield(300); if valid() then
                        f.forge:clear(); self.parent = nil; self.canvas_child = nil
                    end
                end)
            end, 'EF_NEW_NAME_HINT')
        end
        ImGui.EndChild(); ImGui.SameLine()
        if ImGui.BeginChild('RotateXYZ', width * 0.25, 0, false) then self:axis(self.canvas_child, true) end
        ImGui.EndChild()
    end
    ImGui.EndChild()
end

function View:open_custom(entry)
    self.custom_target = entry; self.custom_open = true; self.mouse_override = true
    self:run('read forge ped components',
        function()
            self.components = Appearance.ped(entry.handle); entry.properties.components = self.components
        end)
    self.ctx.view:close(true); self.ctx.view:update_mouse()
end

function View:close_independent(reopen)
    self.axis_open = false; self.custom_open = false; self.mouse_override = false
    if reopen then self.ctx.view.open = true end
    self.ctx.view:update_mouse()
end

function View:update()
    local entries = self.f.forge.entries
    for _, name in ipairs({ 'parent', 'child', 'canvas_child', 'custom_target', 'player' }) do
        local entry = self[name]; if entry and entries[entry.handle] ~= entry then self[name] = nil end
    end
    if self.axis_open and not self.canvas_child then self.axis_open = false end
    if self.custom_open and not self.custom_target then self.custom_open = false end
    if not self.axis_open and not self.custom_open and self.mouse_override then
        self.mouse_override = false; self.ctx.view:update_mouse()
    end
    if self.axis_open then self.f:mark(self.canvas_child, -1) end
    if self.custom_open then self.f:mark(self.custom_target, -0.1) end
end

function View:draw_independent()
    if not self.f.active then return end
    if self.axis_open and self.canvas_child then
        ImGui.SetNextWindowBgAlpha(0.4)
        local draw = ImGui.Begin('Axis Window', nil,
            bit.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.AlwaysAutoResize))
        if draw then
            if Widgets.button(self.ctx, self:text('GENERIC_CLOSE')) then self:close_independent(true) end
            ImGui.Text(self:text('EF_MOUSE_CURSOR_HINT', 'I',
                self:text(self.mouse_override and 'GENERIC_DISABLE' or 'GENERIC_ENABLE')))
            if ImGui.BeginChild('##axis_movement', 220, 340, true) then self:axis(self.canvas_child, false) end
            ImGui.EndChild(); ImGui.SameLine()
            if ImGui.BeginChild('##axis_rotation', 220, 340, true) then self:axis(self.canvas_child, true) end
            ImGui.EndChild(); ImGui.TextWrapped('Selected Entity: ' ..
                self.canvas_child.name .. ' [' .. self.canvas_child.handle .. ']')
        end
        ImGui.End()
    end
    if self.custom_open and self.custom_target then
        local entry = self.custom_target
        local draw = ImGui.Begin('##childPedCustomization', nil,
            bit.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.AlwaysAutoResize))
        if draw then
            if Widgets.button(self.ctx, self:text('GENERIC_CLOSE')) then self:close_independent(true) end
            ImGui.Text(self:text('EF_MOUSE_CURSOR_HINT', 'I',
                self:text(self.mouse_override and 'GENERIC_DISABLE' or 'GENERIC_ENABLE')))
            if ImGui.BeginTabBar('ForgeChildCustomization') then
                if ImGui.BeginTabItem('Components') then
                    local components = self.components
                    if components then
                        if ImGui.BeginChild('##Names', 160, #components * 20, false) then
                            for index, item in ipairs(components) do
                                if item.max_drawables > 0 then
                                    ImGui.BulletText(Refs.ped_components[index] or tostring(index)); ImGui.Dummy(1, 3)
                                end
                            end
                        end
                        ImGui.EndChild(); ImGui.SameLine()
                        if ImGui.BeginChild('components', 300, #components * 20, false) then
                            for index, item in ipairs(components) do
                                if item.max_drawables > 0 then
                                    ImGui.PushID(index); ImGui.SetNextItemWidth(-1); item.drawable = ImGui.SliderInt(
                                        '##ped_component', item.drawable, 0, item.max_drawables - 1); ImGui.PopID()
                                end
                            end
                        end
                        ImGui.EndChild()
                        self:button('GENERIC_APPLY',
                            function()
                                local value = copy(components); self:run('apply forge components',
                                    function()
                                        Appearance.apply_ped(entry.handle, value); entry.properties.components = value
                                    end)
                            end)
                        ImGui.SameLine()
                    end
                    self:button('GENERIC_RANDOM',
                        function()
                            self:run('random forge components',
                                function()
                                    PED.SET_PED_RANDOM_COMPONENT_VARIATION(entry.handle, 0); self.components = Appearance
                                        .ped(entry.handle); entry.properties.components = self.components
                                end)
                        end)
                    ImGui.EndTabItem()
                end
                if ImGui.BeginTabItem('Scenarios') then
                    if ImGui.BeginListBox('##forgescenarios', 400, 300) then
                        for _, item in ipairs(require('includes.ssv2.data.actions.scenarios')) do
                            ImGui.Selectable(item.label, self.scenario == item.scenario); if ImGui.IsItemClicked(0) then
                                self.scenario =
                                    item.scenario
                            end
                        end
                        ImGui.EndListBox()
                    end
                    ImGui.Dummy(1, 10)
                    self:button('Add & Play',
                        function()
                            local scenario = self.scenario; self:run('forge ped scenario',
                                function()
                                    entry.properties.action = { scenario = scenario }; TASK.CLEAR_PED_TASKS_IMMEDIATELY(
                                        entry.handle); TASK.TASK_START_SCENARIO_IN_PLACE(entry.handle, scenario, -1, false)
                                end)
                        end, not self.scenario)
                    ImGui.SameLine()
                    self:button('Stop & Clear', function()
                        self:run('clear forge scenario', function(valid)
                            entry.properties.action = nil
                            if not PED.IS_PED_USING_ANY_SCENARIO(entry.handle) then return end
                            TASK.CLEAR_PED_TASKS_IMMEDIATELY(entry.handle)
                            if entry.parent then
                                local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entry.handle, 1, 2, 0)
                                ENTITY.SET_ENTITY_COORDS_NO_OFFSET(entry.handle, pos.x, pos.y, pos.z, false, false, false)
                                script.yield(100); if not valid() then return end
                                self.f.forge:stand(entry); script.yield(200); if not valid() then return end
                                self.f.forge:attach(entry, entry.parent, entry.parent_bone, entry.attach_pos,
                                    entry.attach_rot)
                            end
                        end)
                    end, not self.scenario)
                    ImGui.EndTabItem()
                end
                ImGui.EndTabBar()
            end
        end
        ImGui.End()
    end
end

function View:draw()
    if not self.ctx.settings:get('ui.show_forge') then return end
    if self.f.failed and Widgets.button(self.ctx, 'Retry EntityForge') then self.f.failed = false end
    if not self.f.active then
        ImGui.Text('EntityForge requires a living player.'); return
    end
    if ImGui.BeginTabBar('##entityforge_tb') then
        for _, tab in ipairs({ { 'EF_TAB_SPAWNER', 'spawner' }, { 'EF_TAB_CREATOR', 'creator' }, { 'EF_TAB_SPAWNED_ENTITIES', 'spawned' }, { 'GENERIC_FAVORITES', 'favorites' }, { 'EF_TAB_SAVED_FORGES', 'saved' } }) do
            if ImGui.BeginTabItem(self:text(tab[1])) then
                self[tab[2]](self); ImGui.EndTabItem()
            end
        end
        ImGui.EndTabBar()
    end
end

return View
