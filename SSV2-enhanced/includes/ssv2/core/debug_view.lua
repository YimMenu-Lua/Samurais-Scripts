local Widgets = require('includes.ssv2.core.widgets')
-- Original SSV2 debugger tabs, expressed with native V2 services.
-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors. GPL-3.0-or-later.
local Debug = {}; Debug.__index = Debug
function Debug.new(ctx)
    local self = setmetatable(
        {
            ctx = ctx,
            script_name = 'freemode',
            global_index = 0,
            local_index = 0,
            offsets = '',
            kind = 0,
            value_text = '',
            value = '',
            pattern = '',
            address = '',
            pointer_value = '',
            sound_name = '',
            sound_ref = '',
            log_search = '',
            notes = {},
            global_reader = { index = 0, offsets = {}, kind = 1 },
            local_reader = { index = 0, offsets = {}, kind = 1, script = '' },
            entity_type = 'ped',
            entity_snapshot = {},
            patterns = {},
            next_snapshot = 0,
            gxt_input = '',
            gxt_result = '',
            vehicles = {},
            audio_loaded = false
        }, Debug)
    return self
end

local function offsets(text)
    local result = {}; for item in text:gmatch('[^,%s]+') do
        result[#result + 1] = assert(tonumber(item),
            'Offsets must be numbers')
    end
    return result
end
function Debug:slot(local_slot)
    local index = local_slot and self.local_index or self.global_index
    for _, offset in ipairs(offsets(self.offsets)) do index = index + offset end
    if local_slot then
        return assert(self.ctx.script_data:local_index(self.script_name, index),
            'Script local is unavailable')
    end
    return assert(self.ctx.script_data:global_index(index), 'Script global is unavailable')
end

function Debug:access(local_slot, write)
    local value = self:slot(local_slot)
    if write then
        if self.kind == 2 then
            assert(not local_slot, 'Local string editing is not used by the source debugger'); value:set_string(
                self.value_text, 48)
        else
            local number = assert(tonumber(self.value_text), 'Enter a numeric value')
            if self.kind == 1 then value:set_float(number) else value:set_int(number) end
        end
    elseif self.kind == 2 then
        self.value = value:get_string() or ''
    elseif self.kind == 1 then
        self.value = tostring(value:get_float())
    else
        self.value = tostring(value:get_int())
    end
end

local read_types = { 'Int', 'Uint', 'Float', 'String', 'Vec3', 'Pointer' }
local state_colors = { Running = { 0, 1, 0, 1 }, Suspended = { 0, 0.4, 1, 1 }, Dead = { 1, 0, 0, 1 }, Unknown = { 0.39, 0.39, 0.39, 1 } }
local textures = {
    akuma = 'sssa_default',
    baller2 = 'sssa_default',
    brigham = 'sssa_dlc_2023_01',
    clique2 =
    'sssa_dlc_2023_01'
}
function Debug:dump(value)
    local function printable(item, seen)
        if type(item) ~= 'table' then return type(item) == 'userdata' and tostring(item) or item end
        if item.get_address then return string.format('0x%X', item:get_address()) end
        seen = seen or {}; if seen[item] then return '<cycle>' end; seen[item] = true
        local result = {}; for key, member in pairs(item) do
            if type(member) ~= 'function' then
                result[tostring(key)] =
                    printable(member, seen)
            end
        end
        seen[item] = nil; return result
    end
    log.info(require('includes.ssv2.core.codec').encode(printable(value), false))
end

function Debug:button(label, callback, disabled, width, height)
    ImGui.BeginDisabled(not not disabled)
    if Widgets.button(self.ctx, label, width or 0, height or 0) and not disabled then
        self.ctx.runtime:run(
            'debug ' .. label, callback)
    end
    ImGui.EndDisabled()
end

function Debug:read_reader(reader, local_slot)
    local value = local_slot and self.ctx.script_data:local_index(reader.script, reader.index) or
        self.ctx.script_data:global_index(reader.index)
    if not value then
        reader.value = 'Unavailable'; return
    end
    for _, offset in ipairs(reader.offsets) do value = value:at(offset) end
    local kind = read_types[reader.kind]
    if kind == 'Int' then
        reader.value = tostring(value:get_int())
    elseif kind == 'Uint' then
        reader.value = tostring(value:get_int() % 4294967296)
    elseif kind == 'Float' then
        reader.value = tostring(value:get_float())
    elseif kind == 'String' then
        reader.value = value:get_string() or ''
    elseif kind == 'Vec3' then
        local v = value:get_vector3(); reader.value = string.format('(%s, %s, %s)', v.x, v.y, v.z)
    else
        reader.value = string.format('0x%X', value:get_pointer():get_address())
    end
    local index = reader.index; for _, offset in ipairs(reader.offsets) do index = index + offset end
    reader.name = (local_slot and 'Local_' or 'Global_') .. index
end

function Debug:scan_patterns()
    local definitions = {
        { 'ScreenResolution', '75 39 0F 57 C0 F3 0F 2A 05', function(p)
            return {
                x = p:add(9):rip()
                    :get_int(),
                y = p:add(34):rip():get_int()
            }
        end },
        { 'GameVersion', '4C 8D 0D ? ? ? ? 48 8D 5C 24 ? 48 89 D9 48 89 FA', function(p)
            return {
                build = p:add(3)
                    :rip():get_string(),
                online = p:add(74):rip():get_string()
            }
        end },
        { 'ScriptGlobals', '48 8B 8E B8 00 00 00 48 8D 15 ? ? ? ? 49 89 D8', function(p) return p:add(10):rip() end },
        { 'GameState',     '83 3D ? ? ? ? ? 0F 85 ? ? ? ? BA ? 00',          function(p) return p:add(2):rip():add(1) end },
    }
    for _, definition in ipairs(definitions) do
        local previous = self.patterns[definition[1]]
        if not previous or previous.failed then
            local entry = { name = definition[1], signature = definition[2], address = 0, failed = true }
            self.patterns[entry.name] = entry
            local ok, result = pcall(function()
                local p = memory.scan_pattern(entry.signature)
                if not p or not p:is_valid() then return end
                entry.address = p:get_address(); return definition[3](p)
            end)
            entry.failed = not ok or result == nil; entry.value = ok and result or tostring(result)
        end
    end
    self.scan_requested = false
end

function Debug:update(state)
    if not self.ctx.settings:get('backend.debug_mode') then return end
    if self.scan_requested and self.ctx.build.compatible then self:scan_patterns() end
    for _, scope in ipairs({ { self.global_reader, false }, { self.local_reader, true } }) do
        local reader = scope[1]
        if reader.reading and self.ctx.build.compatible then
            local ok, err = pcall(function() self:read_reader(reader, scope[2]) end)
            if not ok then reader.value = tostring(err) end
        end
    end
    if self.preview then
        local p = self.preview
        if util.time() - p.touched < 100 and self.ctx.view.open then
            if self.texture and self.texture ~= p.dictionary then
                GRAPHICS.SET_STREAMED_TEXTURE_DICT_AS_NO_LONGER_NEEDED(
                    self.texture)
            end
            self.texture = p.dictionary
            GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(p.dictionary, false)
            if GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(p.dictionary) then
                GRAPHICS.DRAW_SPRITE(p.dictionary, p.name, (p.x + 128) / p.width, (p.y + 64) / p.height, 256 / p.width,
                    128 / p.height, 0, 255, 255, 255, 255, false, 0)
            end
        else
            self.preview = nil
        end
    end
    if self.texture and (not self.preview or self.preview.dictionary ~= self.texture) then
        GRAPHICS.SET_STREAMED_TEXTURE_DICT_AS_NO_LONGER_NEEDED(self.texture); self.texture = nil
    end
    if util.time() < self.next_snapshot then return end
    self.next_snapshot = util.time() + 500; self.entity_snapshot = { ped = {}, vehicle = {}, object = {} }
    for handle, entry in pairs(self.ctx.owned_entities) do
        if ENTITY.DOES_ENTITY_EXIST(handle) then
            local kind = type(entry) == 'table' and entry.kind or
                ({ [1] = 'ped', [2] = 'vehicle', [3] = 'object' })[ENTITY.GET_ENTITY_TYPE(handle)]
            if self.entity_snapshot[kind] then
                self.entity_snapshot[kind][#self.entity_snapshot[kind] + 1] = {
                    handle =
                        handle,
                    model = ENTITY.GET_ENTITY_MODEL(handle),
                    record = entry
                }
            end
        end
    end
    if #self.vehicles == 0 then
        for name in pairs(textures) do
            self.vehicles[#self.vehicles + 1] = {
                name = name,
                label = HUD
                    .GET_FILENAME_FOR_AUDIO_CONVERSATION(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(util.joaat(name)))
            }
        end
        table.sort(self.vehicles, function(a, b) return a.label < b.label end)
    end
end

function Debug:clone_vehicle(handle)
    if not ENTITY.DOES_ENTITY_EXIST(handle) then return end
    local runtime = self.ctx.runtime; local generation = runtime.generation
    local valid = function()
        return runtime.running and runtime.generation == generation and
            ENTITY.DOES_ENTITY_EXIST(handle)
    end
    local appearance = require('includes.ssv2.core.appearance').vehicle(handle)
    local minimum, maximum = self.ctx.game.model_dimensions(ENTITY.GET_ENTITY_MODEL(handle))
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(handle, 0, maximum.y - minimum.y, 0.1)
    local pool = self.ctx.console.pool
    local entry = pool:create('vehicle', ENTITY.GET_ENTITY_MODEL(handle), pos, ENTITY.GET_ENTITY_HEADING(handle), valid)
    if entry then
        if require('includes.ssv2.core.appearance').apply_vehicle(entry.handle, appearance, valid) then
            local pointer = memory.allocate(4); pointer:set_int(entry.handle)
            local ok, err = pcall(ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED, pointer)
            memory.free(pointer); if not ok then error(err) end
        else
            pool:delete(entry.handle)
        end
    end
end

function Debug:entities()
    local count, total = 0, 0
    for _, kind in ipairs({ 'ped', 'vehicle', 'object' }) do
        count = count + #(self.entity_snapshot[kind] or {}); total = total + self.ctx.entity_limits[kind]
    end
    ImGui.BulletText('Maximum Allowed Entities: [' .. total .. ']'); ImGui.BulletText('Total Spawned Entities: [' ..
        count .. ']')
    if ImGui.BeginChild('##entitytypes', 200, 200, true) then
        for _, kind in ipairs({ 'ped', 'vehicle', 'object' }) do
            local label = kind:sub(1, 1):upper() ..
                kind:sub(2) .. 's (' .. #(self.entity_snapshot[kind] or {}) .. '/' .. self.ctx.entity_limits[kind] .. ')'
            ImGui.Selectable(label, self.entity_type == kind); if ImGui.IsItemClicked() then self.entity_type = kind end
        end
    end
    ImGui.EndChild(); ImGui.SameLine()
    if ImGui.BeginChild('##entitydetails', 0, 0, true) then
        if ImGui.BeginTable('entity_table', 4, bit.bor(ImGuiTableFlags.RowBg, ImGuiTableFlags.Borders, ImGuiTableFlags.BordersInner)) then
            for _, name in ipairs({ 'Handle', 'Model Hash', 'Type', 'Actions' }) do ImGui.TableSetupColumn(name) end; ImGui
                .TableHeadersRow()
            for _, entry in ipairs(self.entity_snapshot[self.entity_type] or {}) do
                ImGui.TableNextRow(); ImGui.TableSetColumnIndex(0); ImGui.Text(tostring(entry.handle)); ImGui
                    .TableSetColumnIndex(1); ImGui.Text(tostring(entry.model)); ImGui.TableSetColumnIndex(2); ImGui.Text(
                    self.entity_type); ImGui.TableSetColumnIndex(3); ImGui.PushID(entry.handle)
                if self.entity_type == 'ped' then
                    self:button(' K ',
                        function()
                            if ENTITY.DOES_ENTITY_EXIST(entry.handle) then
                                ENTITY.SET_ENTITY_HEALTH(entry.handle,
                                    0, 0, 0)
                            end
                        end); ImGui.SameLine()
                elseif self.entity_type == 'vehicle' then
                    self:button(' C ', function() self:clone_vehicle(entry.handle) end); ImGui.SameLine()
                end
                self:button(' X ',
                    function()
                        if type(entry.record) == 'table' and entry.record.pool then
                            entry.record.pool:delete(
                                entry.handle)
                        else
                            Entity.new(entry.handle):delete(); self.ctx.owned_entities[entry.handle] = nil
                        end
                    end)
                ImGui.PopID()
            end
            ImGui.EndTable()
        end
    end
    ImGui.EndChild()
end

function Debug:thread_state(feature)
    return (feature.debug_removed or feature.debug_disabled or feature.failed) and
        'Dead' or (feature.paused or feature.auto_suspended) and 'Suspended' or 'Running'
end

function Debug:threads()
    local list = {}
    for _, feature in ipairs(self.ctx.runtime.services) do if not feature.debug_removed then list[#list + 1] = feature end end
    ImGui.BulletText('Thread Count: [' .. #list .. ']')
    if ImGui.BeginChild('##threadlist', ImGui.GetContentRegionAvail() - 200, math.min(#list * 20, self.ctx.settings:get('ui.height') - 60), false) then
        ImGui.SetNextWindowBgAlpha(0)
        if ImGui.BeginListBox('##thread_listbox', -1, -1) then
            for _, feature in ipairs(list) do
                local state = self:thread_state(feature); local c = state_colors[state]
                ImGui.PushStyleColor(ImGuiCol.Text, unpack(c))
                ImGui.Selectable(feature.id, self.thread == feature); if ImGui.IsItemClicked() then self.thread = feature end; ImGui
                    .PopStyleColor()
                local seconds = feature.started_at and feature.started_at > 0 and (util.time() - feature.started_at) /
                    1000 or 0
                Widgets.tooltip(self.ctx, string.format('CPU time: %.1f seconds', seconds))
            end
            ImGui.EndListBox()
        end
    end
    ImGui.EndChild()
    if self.thread then
        local feature = self.thread; local state = self:thread_state(feature); ImGui.SameLine()
        if ImGui.BeginChild('##threadctrls', 170, 155, true) then
            self:button('Remove', function()
                self.ctx.runtime:control(feature, 'remove'); self.thread = nil
            end, false, 140, 35)
            if state == 'Running' then
                self:button('Suspend', function() self.ctx.runtime:control(feature, 'pause') end, false, 140, 35)
                self:button('Kill', function() self.ctx.runtime:control(feature, 'stop') end, false, 140, 35)
            elseif state == 'Suspended' then
                self:button('Resume', function() self.ctx.runtime:control(feature, 'resume') end, false, 140, 35)
            elseif state == 'Dead' then
                self:button('Start', function()
                    feature.failed = false; self.ctx.runtime:control(feature, 'resume')
                end, false, 140, 35)
            end
        end
        ImGui.EndChild()
        local runtime = self.ctx.runtime
        ImGui.BulletText('Internal State: ' .. runtime:internal_state(feature)); ImGui.BulletText(string.format(
            'Average Load: %.1fms', runtime:load_average(feature)))
    end
end

function Debug:pointers()
    if next(self.patterns) == nil then self.scan_requested = true end
    local total, failed = 0, 0; for _, entry in pairs(self.patterns) do
        total = total + 1; if entry.failed then failed = failed + 1 end
    end
    ImGui.BulletText('Total Count: [' .. total .. ']')
    if ImGui.BeginChild('##ptr_list', 0, math.min(total * 65, self.ctx.settings:get('ui.height') - 30), true) then
        ImGui.SetNextWindowBgAlpha(0)
        if ImGui.BeginListBox('##ptr_listbox', -1, -1) then
            for name, entry in pairs(self.patterns) do
                if entry.address == 0 then ImGui.PushStyleColor(ImGuiCol.Text, 1, 0, 0, 1) end
                local value
                if entry.value and (type(entry.value) == 'table' or type(entry.value) == 'userdata') and entry.value.get_address then
                    value = string.format('0x%X', entry.value:get_address())
                else
                    value = type(entry.value) == 'table' and
                        require('includes.ssv2.core.codec').encode(entry.value, false) or tostring(entry.value)
                end
                ImGui.Selectable(string.format('%s @ 0x%X = [%s]', name, entry.address, value), self.pointer_name == name)
                if ImGui.IsItemClicked() then self.pointer_name = name end
                if entry.address == 0 then ImGui.PopStyleColor() end
            end
            ImGui.EndListBox()
        end
    end
    ImGui.EndChild()
    if failed > 0 and Widgets.button(self.ctx, 'Rescan Failed Pointers') then self.scan_requested = true end
end

function Debug:reader(reader, local_slot)
    local suffix = local_slot and 'locals' or 'globals'; ImGui.PushID(suffix)
    ImGui.Spacing(); ImGui.SeparatorText(local_slot and 'ScriptLocal' or 'ScriptGlobal'); ImGui.Text(local_slot and
        'Local_' or 'Global_'); ImGui.SameLine(); ImGui.SetNextItemWidth(200)
    reader.index = math.max(0, (Widgets.input_int(self.ctx, '##index', reader.index)))
    if local_slot then
        ImGui.SameLine(); ImGui.SetNextItemWidth(200); local value = Widgets.input_text_with_hint(self.ctx, '##scr_name', 'Script Name',
            reader.script)
        reader.script = require('includes.ssv2.core.widgets').validated_text(reader.script, value, 64)
    end
    local disabled = reader.index == 0 or local_slot and reader.script == ''
    ImGui.BeginDisabled(not not disabled); ImGui.SameLine()
    if Widgets.button(self.ctx, 'Add Offset') and not disabled then reader.offsets[#reader.offsets + 1] = 0 end
    ImGui.SameLine(); ImGui.BeginDisabled(#reader.offsets == 0)
    if Widgets.button(self.ctx, 'Remove Offset') and #reader.offsets > 0 then table.remove(reader.offsets) end
    ImGui.EndDisabled(); ImGui.SameLine()
    if Widgets.button(self.ctx, 'Clear') and not disabled then
        reader.index = 0; reader.offsets = {}; reader.kind = 1; reader.reading = false; reader.value = nil; if local_slot then
            reader.script =
            ''
        end
    end
    for i, value in ipairs(reader.offsets) do
        ImGui.Text('.f_'); ImGui.SameLine(); ImGui.SetNextItemWidth(140); reader.offsets[i] = math.max(0,
            (Widgets.input_int(self.ctx, '##offset' .. i, value)))
    end
    ImGui.Text('Type:')
    for i, kind in ipairs(read_types) do
        if not local_slot or kind ~= 'String' then
            ImGui.SameLine(); reader.kind = ImGui.RadioButton(kind, reader.kind, i)
        end
    end
    self:button('Read ' .. read_types[reader.kind],
        function()
            reader.reading = true; self:read_reader(reader, local_slot)
        end, disabled or not self.ctx.build.compatible)
    ImGui.EndDisabled()
    if reader.value then ImGui.Text((reader.name or '') .. ' = ' .. reader.value) end
    ImGui.PopID()
end

function Debug:serializer()
    local s = self.ctx.settings
    local service = self.ctx.runtime.service_names.SS_SERIALIZER
    ImGui.BulletText('Thread State: ' .. self:thread_state(service):upper())
    ImGui.BulletText('Is Disabled: ' .. tostring(s.debug_disabled or false)); ImGui.BulletText(string.format(
        'Time Since Last Flush: %.0f seconds ago.', (util.time() - (s.last_flush or util.time())) / 1000))
    for mode = 0, 1 do
        if mode == 1 then ImGui.SameLine() end
        self:button('Break ' .. mode, function()
            s.debug_disabled = true; s.dirty = false
            if mode == 0 then
                FileMgr.WriteFileContent(s.path, '{ royallyfuckedjson', false)
            else
                local text = FileMgr.ReadFileContent(s.path); if text ~= '' then
                    FileMgr.WriteFileContent(s.path,
                        text:sub(1, math.floor(#text / 2)), false)
                end
            end
        end)
    end
    if Widgets.button(self.ctx, 'Dump') then self:dump(s.data) end
end

function Debug:translator()
    local tr = self.ctx.translator; local index = self.ctx.settings:get('backend.language_index')
    ImGui.TextDisabled('You can switch between available languages in Settings -> General.'); ImGui.Spacing()
    ImGui.BulletText('State: ' .. (tr.debug_disabled and 'DISABLED' or 'RUNNING'))
    if not tr.debug_disabled then
        ImGui.BulletText('Index: ' .. index); ImGui.BulletText('ISO: ' .. tr.locales[index]); ImGui.BulletText(
            'Translated Name: ' .. tr:text(tr.locales[index]))
    end
    ImGui.Spacing()
    self:button('Break', function() tr:reload(true) end, tr.debug_disabled or util.time() < (tr.reload_after or 0)); ImGui
        .SameLine()
    self:button('Reload', function() tr:reload(false) end, util.time() < (tr.reload_after or 0))
    for _, item in ipairs({ { 'Dump Labels', tr.english }, { 'Dump Locales', tr.locales }, { 'Dump Cache', tr.cache } }) do
        if Widgets.button(self.ctx, item[1]) then
            self:dump(item[2])
        end
    end
    ImGui.Separator(); ImGui.Spacing()
    local value, entered = Widgets.input_text(self.ctx, 'GXT Translator', self.gxt_input, ImGuiInputTextFlags.EnterReturnsTrue)
    self.gxt_input = require('includes.ssv2.core.widgets').validated_text(self.gxt_input, value, 64)
    if entered then
        local key = self.gxt_input; self.gxt_input = ''; self.ctx.runtime:run('debug GXT',
            function() self.gxt_result = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(key) end)
    end
    ImGui.Text('Result: ' .. self.gxt_result); ImGui.Spacing()
end

function Debug:preview_test()
    ImGui.Text('Lightweight Vehicle Preview Test')
    local hovered = false
    if ImGui.BeginListBox('##dummyvehlist', -1, 0) then
        for i, vehicle in ipairs(self.vehicles) do
            ImGui.PushID(i); ImGui.Selectable(vehicle.label, false)
            if ImGui.IsItemHovered() then
                local _, y = ImGui.GetItemRectMin(); local x = ImGui.GetWindowPos(); local width, height = ImGui
                    .GetDisplaySize()
                self.preview = {
                    name = vehicle.name,
                    dictionary = textures[vehicle.name],
                    x = x + ImGui.GetWindowWidth(),
                    y =
                        y,
                    width = width,
                    height = height,
                    touched = util.time()
                }; hovered = true
            end
            ImGui.PopID()
        end
        ImGui.EndListBox()
    end
    if not hovered then self.preview = nil end
end

function Debug:patches()
    local owners = {}
    for _, feature in ipairs(self.ctx.runtime.features) do
        local values = {}
        if feature.patch then
            values[#values + 1] = {
                name = 'Casino solo planning board',
                enabled = feature
                    .patch_enabled or false
            }
        end
        if feature.lease then values[#values + 1] = { name = feature.id .. ' field lease', enabled = true } end
        for name, value in pairs(feature.leases or {}) do
            values[#values + 1] = {
                name = name,
                enabled = value.modified or
                    value.applied or false
            }
        end
        if #values > 0 then owners[#owners + 1] = { name = feature.id, values = values } end
    end
    for key, entry in pairs(self.ctx.vehicle_flags.entries) do
        local values = {}; for owner in pairs(entry.owners) do
            values[#values + 1] = {
                name = key ..
                    ' (' .. tostring(owner.id or owner) .. ')',
                enabled = true
            }
        end
        owners[#owners + 1] = { name = 'Vehicle flags ' .. key, values = values }
    end
    if #owners == 0 then
        ImGui.Text('No registered memory patches.'); return
    end
    if ImGui.BeginChild('##patchlist', self.patch_owner and ImGui.GetContentRegionAvail() * 0.4 or 0, 0, false) then
        ImGui.SetNextWindowBgAlpha(0)
        if ImGui.BeginListBox('##patches', -1, 0) then
            for _, owner in ipairs(owners) do
                ImGui.Selectable(owner.name .. ' [' .. #owner.values .. ']', self.patch_owner == owner.name); if ImGui.IsItemClicked() then
                    self.patch_owner =
                        owner.name
                end
            end
            ImGui.EndListBox()
        end
    end
    ImGui.EndChild()
    if self.patch_owner then
        ImGui.SameLine()
        if ImGui.BeginChild('##patchesbyowner', 0, 0, true) then
            for _, owner in ipairs(owners) do
                if owner.name == self.patch_owner then
                    for _, entry in ipairs(owner.values) do
                        ImGui.Selectable(entry.name .. ' (' .. (entry.enabled and 'Applied' or 'Not applied') .. ')',
                            self.patch_name == entry.name); if ImGui.IsItemClicked() then self.patch_name = entry.name end
                    end
                end
            end
        end
        ImGui.EndChild()
    end
end

function Debug:misc()
    if ImGui.BeginTabBar('miscTests') then
        if ImGui.BeginTabItem('Misc Stuff') then
            self:button('Dump Subhandling Data', function()
                local state = self.ctx.state:read(); if not state or state.vehicle_handle == 0 then return end
                local kind = state.car and 'CCarHandlingData' or state.bike and 'CBikeHandlingData' or
                    state.aircraft and 'CFlyingHandlingData'
                if not kind then return end
                local base = require('includes.ssv2.core.vehicle_memory').subhandling(state.vehicle_handle)
                local data = { __type = kind, m_ptr = base }
                for field, offset in pairs(require('includes.ssv2.data.subhandling_fields')[kind]) do
                    data[field] = base
                        :add(offset)
                end
                self:dump(data)
            end, not self.ctx.build.compatible)
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem('Audio Debugger') then
            local value = Widgets.input_text_with_hint(self.ctx, '##audioName', 'Audio Name', self.sound_name); self.sound_name =
                require('includes.ssv2.core.widgets').validated_text(self.sound_name, value, 64)
            value = Widgets.input_text_with_hint(self.ctx, '##audioRef', 'Audio Reference', self.sound_ref,
                ImGuiInputTextFlags.CharsNoBlank); self.sound_ref = require('includes.ssv2.core.widgets').validated_text(
                self.sound_ref, value, 128)
            self:button('Play##audio', function()
                if not self.sound_name:find('%S') or not self.sound_ref:find('%S') then return end
                if not self.ctx.online or not self.audio_loaded then
                    AUDIO.SET_AUDIO_FLAG('LoadMPData', true); self.audio_loaded = true
                end
                if self.sound_id then
                    AUDIO.STOP_SOUND(self.sound_id); AUDIO.RELEASE_SOUND_ID(self.sound_id)
                end
                self.sound_id = AUDIO.GET_SOUND_ID(); AUDIO.PLAY_SOUND_FRONTEND(self.sound_id, self.sound_name,
                    self.sound_ref, true)
            end); ImGui.SameLine()
            self:button('Stop##audio',
                function()
                    if self.sound_id then
                        AUDIO.STOP_SOUND(self.sound_id); AUDIO.RELEASE_SOUND_ID(self.sound_id); self.sound_id = nil
                    end
                end)
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
end

function Debug:draw()
    if not self.ctx.settings:get('backend.debug_mode') then return end
    if ImGui.BeginTabBar('##ss_debug') then
        ImGui.PushTextWrapPos()
        for _, tab in ipairs({ { 'Entities', Debug.entities }, { 'Threads', Debug.threads }, { 'Pointers', Debug.pointers }, { 'Patches', Debug.patches },
            { 'Globals & Locals', function(self)
                self:reader(self.global_reader, false); self:reader(self.local_reader, true)
            end },
            { 'Serializer', Debug.serializer }, { 'Translator', Debug.translator }, { 'Preview Test', Debug.preview_test }, { 'Misc Tests', Debug.misc } }) do
            if ImGui.BeginTabItem(tab[1]) then
                tab[2](self); ImGui.EndTabItem()
            end
        end
        ImGui.PopTextWrapPos(); ImGui.EndTabBar()
    end
end

function Debug:clear()
    if self.texture then
        GRAPHICS.SET_STREAMED_TEXTURE_DICT_AS_NO_LONGER_NEEDED(self.texture); self.texture = nil
    end
    self.preview = nil
    if self.sound_id then
        AUDIO.STOP_SOUND(self.sound_id); AUDIO.RELEASE_SOUND_ID(self.sound_id); self.sound_id = nil
    end
end

return Debug
