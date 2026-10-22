-- Original MP Stat Controller frontend. Copyright (C) 2026 SAMURAI & Contributors.
-- GPL-3.0-or-later.
local Widgets = require('includes.ssv2.core.widgets')
local Calendar = require('includes.ssv2.core.calendar')
local View = {}; View.__index = View
local types = { 'int', 'float', 'money', 'bool', 'string', 'posix', 'time', 'date', 'bitset' }
local function copy(value)
    if type(value) ~= 'table' then return value end; local result = {}; for key, item in pairs(value) do
        result[key] =
            copy(item)
    end; return result
end
function View.new(ctx, f) return setmetatable({ ctx = ctx, f = f, new_kind = '', bit_view = 0 }, View) end

function View:text(key) return self.ctx.translator:text(key) end

function View:run(label, callback) self.ctx.runtime:run(label, function() if self.ctx.online then callback() end end) end

function View:bits(value)
    local bits = {}; for index = 31, 0, -1 do bits[#bits + 1] = bit.band(value, bit.lshift(1, index)) ~= 0 and '1' or '0' end; return
        table.concat(bits)
end

function View:bit_editor(name, value)
    local f = self.f
    ImGui.SeparatorText('Bit Editor'); ImGui.PushStyleVar(ImGuiStyleVar.CellPadding, 10, 9)
    if ImGui.BeginTable('##bitsetEditor', 9, ImGuiTableFlags.SizingFixedFit) then
        ImGui.TableNextRow(); ImGui.TableSetColumnIndex(0); ImGui.Text('')
        for index = 7, 0, -1 do
            ImGui.TableSetColumnIndex(8 - index); ImGui.Text(tostring(index))
        end
        for byte = 3, 0, -1 do
            ImGui.TableNextRow(); ImGui.TableSetColumnIndex(0); ImGui.Text('Byte ' .. byte + 1)
            for index = 7, 0, -1 do
                local position = byte * 8 + index; local enabled = bit.band(value, bit.lshift(1, position)) ~= 0
                ImGui.TableSetColumnIndex(8 - index)
                if enabled then
                    local c = self.ctx.theme:current().Colors.ButtonActive; ImGui.PushStyleColor(ImGuiCol.Button, c.x,
                        c.y, c.z, c.w)
                end
                ImGui.SetWindowFontScale(0.8); ImGui.PushID(position)
                if ImGui.Button(enabled and '1' or '0', 23, 28) then
                    value = bit.bxor(value, bit.lshift(1, position)); local updated = value
                    self:run('toggle stat bit', function() f:set(name, updated) end)
                end
                ImGui.PopID(); ImGui.SetWindowFontScale(1); if enabled then ImGui.PopStyleColor() end
                if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
                    Widgets.tooltip(self.ctx,
                        'Bit ' .. position)
                end
            end
        end
        ImGui.EndTable()
    end
    ImGui.PopStyleVar(); ImGui.Spacing(); ImGui.SeparatorText('Direct Value')
    local changed; value, changed = Widgets.input_int(self.ctx, '##bitEditorInput', value)
    if changed then
        local updated = value; self:run('set bit stat', function() f:set(name, updated) end)
    end
    f.buffers[name] = value; ImGui.Spacing(); ImGui.SeparatorText('View')
    self.bit_view = ImGui.Combo('##bitView', self.bit_view, { 'Hexadecimal', 'Binary', 'Decimal' }, 3)
    ImGui.TextDisabled(self.bit_view == 0 and string.format('0x%08X', value % 4294967296) or
        self.bit_view == 1 and self:bits(value) or tostring(value))
end

function View:editor(name, definition)
    local f = self.f; local kind = definition.type; local value = f.buffers[name]
    if value == nil then
        ImGui.TextDisabled('Unavailable'); return
    end
    if kind == 'bitset' then
        self:bit_editor(name, value); return
    elseif kind == 'bool' then
        local updated, changed = ImGui.Checkbox('##value', value); if changed then
            f.buffers[name] = updated; self:run('set boolean stat', function() f:set(name, updated) end)
        end; return
    elseif kind == 'string' then
        local text, entered = Widgets.input_text(self.ctx, '##statString', value, ImGuiInputTextFlags.EnterReturnsTrue); local valid
        text, valid = Widgets.validated_text(value, text, 512); f.buffers[name] = text
        if entered then self:run('set string stat', function() f:set(name, text) end) end
        if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
            Widgets.tooltip(self.ctx,
                'Press [ENTER] to set the value.')
        end; return
    elseif kind == 'date' then
        local year = Calendar.current_local().year
        for _, field in ipairs({ { 'year', 1970, year }, { 'month', 1, 12 }, { 'day', 1, 31 }, { 'hour', 0, 23 }, { 'min', 0, 59 }, { 'sec', 0, 59 } }) do
            local max = field[1] == 'day' and
                Calendar.from_epoch(Calendar.to_epoch({ year = value.year, month = value.month + 1, day = 1 }, 0) - 86400, 0)
                .day or field[3]
            value[field[1]] = ImGui.SliderInt(field[1]:sub(1, 1):upper() .. field[1]:sub(2), value[field[1]], field[2],
                max)
            if field[1] == 'year' or field[1] == 'month' then
                value.day = math.min(value.day,
                    Calendar.from_epoch(Calendar.to_epoch({ year = value.year, month = value.month + 1, day = 1 }, 0) -
                        86400, 0).day)
            end
        end
    elseif kind == 'float' then
        value = Widgets.input_float(self.ctx, '##value', value)
    else
        value = Widgets.input_int(self.ctx, '##value', value); if kind == 'posix' or kind == 'time' then value = math.max(0, value) end
    end
    f.buffers[name] = value; ImGui.Separator(); ImGui.Spacing()
    if Widgets.button(self.ctx, self:text('GENERIC_CONFIRM')) then
        local edited = copy(value); self:run('set stat', function() f:set(name, edited) end); ImGui.CloseCurrentPopup()
    end
    ImGui.SameLine(); if Widgets.button(self.ctx, self:text('GENERIC_CANCEL')) then
        f.buffers[name] = copy(f.values[name]); ImGui.CloseCurrentPopup()
    end
end

function View:card(name, definition)
    local f = self.f
    if ImGui.BeginChild(name, 0, 170, true) then
        ImGui.Text(self:text('GENERIC_NAME')); ImGui.SameLine(); ImGui.Text(name)
        ImGui.Text(self:text('GENERIC_VALUE')); ImGui.SameLine(); ImGui.Text(definition.type == 'bitset' and
            self:bits(f.values[name] or 0) or f:format(name, definition.type)); ImGui.Separator()
        if Widgets.button(self.ctx, self:text('GENERIC_EDIT')) then
            f.buffers[name] = copy(f.values[name]); ImGui.OpenPopup('##statEditor')
        end
        ImGui.SetNextWindowSizeConstraints(400, 144, 600, 600)
        local _, draw = ImGui.BeginPopupModal('##statEditor', true,
            bit.bor(ImGuiWindowFlags.NoResize, ImGuiWindowFlags.AlwaysAutoResize))
        if draw then
            self:editor(name, definition); ImGui.EndPopup()
        end
        local locked, changed = Widgets.toggle(self.ctx, self:text('GENERIC_LOCK_VAL'), definition.autolock or false)
        if changed then self:run('lock stat', function() f:lock(name, locked) end) end
        if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and not self.ctx.settings:get('ui.disable_tooltips') then
            Widgets.tooltip(self.ctx, self:text('MPSTAT_LOCK_VAL_TT'))
        end
    end
    ImGui.EndChild()
end

function View:new_stat()
    local f = self.f; ImGui.SetNextWindowSizeConstraints(450, 140, 600, 600)
    local _, draw = ImGui.BeginPopupModal('##addNewStat', true, ImGuiWindowFlags.AlwaysAutoResize)
    if not draw then return end
    ImGui.SetNextItemWidth(420.69); local value = Widgets.input_text(self.ctx, 'Stat', f.new_name); f.new_name = Widgets
        .validated_text(f.new_name, value, 128)
    ImGui.SetNextItemWidth(420.69)
    if ImGui.BeginCombo(self:text('GENERIC_TYPE'), self.new_kind) then
        for _, kind in ipairs(types) do
            ImGui.Selectable(kind, self.new_kind == kind); if ImGui.IsItemClicked() then self.new_kind = kind end
        end; ImGui.EndCombo()
    end
    ImGui.Spacing(); ImGui.BeginDisabled(f.new_name == '' or self.new_kind == '')
    if Widgets.button(self.ctx, self:text('GENERIC_CONFIRM')) and f.new_name ~= '' and self.new_kind ~= '' then
        local name, kind = f.new_name, self.new_kind; self:run('add stat', function() f:add(name, kind) end); f.new_name =
        ''; self.new_kind = ''; ImGui.CloseCurrentPopup()
    end
    ImGui.EndDisabled(); ImGui.SameLine(); if Widgets.button(self.ctx, self:text('GENERIC_CANCEL')) then
        f.new_name = ''; self.new_kind = ''; ImGui.CloseCurrentPopup()
    end
    ImGui.EndPopup()
end

function View:draw()
    local f = self.f
    if not self.ctx.online then
        ImGui.Text(self:text('GENERIC_UNAVAILABLE_SP')); return
    end
    ImGui.SetWindowFontScale(1.3); ImGui.Text(self:text('SUBTAB_MPSTAT_CONTROLLER')); ImGui.SetWindowFontScale(0.89); ImGui
        .TextWrapped(self:text('MPSTAT_CONTROLLDER_DESC')); ImGui.SetWindowFontScale(1)
    ImGui.Spacing(); ImGui.Separator(); ImGui.Spacing()
    local filters = { self:text('GENERIC_ALL') }; for _, kind in ipairs(types) do filters[#filters + 1] = kind end
    f.filter = ImGui.Combo(self:text('GENERIC_LIST_FILTER'), f.filter, filters, #filters)
    f.search = Widgets.input_text_with_hint(self.ctx, '##searchStats', self:text('GENERIC_SEARCH_HINT'), f.search):lower()
    local names = {}; for name in pairs(f:definitions()) do names[#names + 1] = name end; table.sort(names)
    ImGui.SetNextWindowBgAlpha(0)
    if ImGui.BeginChild('##statsScroll', 0, self.ctx.settings:get('ui.height') * 0.63, false) then
        local processed = 0
        for _, name in ipairs(names) do
            local definition = f:definitions()[name]
            if processed <= 20 and name:lower():find(f.search, 1, true) and (f.filter == 0 or definition.type == types[f.filter]) then
                ImGui.PushID(name); self:card(name, definition); ImGui.PopID(); processed = processed + 1
            end
        end
    end
    ImGui.EndChild()
    if #names > 20 then
        ImGui.TextColored(0.941, 0.745, 0.007, 1, '[ ! ]'); if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
            Widgets.tooltip(self.ctx, self.ctx.translator:format('ASSET_BROWSER_TRUNC_TT', 20))
        end
    end
    ImGui.Separator(); ImGui.Spacing()
    if Widgets.button(self.ctx, self:text('GENERIC_ADD'), ImGui.CalcTextSize(self:text('GENERIC_ADD')) + 30, 37) then
        ImGui.OpenPopup('##addNewStat')
    end
    self:new_stat()
end

return View
