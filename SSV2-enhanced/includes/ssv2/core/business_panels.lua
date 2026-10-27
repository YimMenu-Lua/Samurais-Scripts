-- Native V2 business panels, preserving the original frontend's grouping and actions.
-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors. GPL-3.0-or-later.
local Widgets = require('includes.ssv2.core.widgets')
local definitions = require('includes.ssv2.data.business_definitions')
local Panels = {}; Panels.__index = Panels
local earnings = {
    { 'YRV3_LIFETIME_BUY_UNDERTAKEN',  'MPX_LIFETIME_BUY_UNDERTAKEN',  5000,      1,      100 },
    { 'YRV3_LIFETIME_BUY_COMPLETE',    'MPX_LIFETIME_BUY_COMPLETE',    5000,      1,      100 },
    { 'YRV3_LIFETIME_SELL_UNDERTAKEN', 'MPX_LIFETIME_SELL_UNDERTAKEN', 5000,      1,      100 },
    { 'YRV3_LIFETIME_SELL_COMPLETE',   'MPX_LIFETIME_SELL_COMPLETE',   5000,      1,      100 },
    { 'YRV3_LIFETIME_EARNINGS',        'MPX_LIFETIME_CONTRA_EARNINGS', 100000000, 100000, 1000000 },
}
local clutter = {
    { 'cash',            'CASH' }, { 'Swag_Silver', 'SILVER' }, { 'Swag_Pills', 'PILLS' }, { 'Swag_Med', 'MEDS' },
    { 'Swag_JewelWatch', 'JEWEL' }, { 'Swag_Ivory', 'IVORY' }, { 'Swag_Guns', 'CUNS' },
    { 'Swag_Gems',       'GEMS' }, { 'Swag_Furcoats', 'FURCOATS' }, { 'Swag_electronic', 'ELECTRONICS' },
    { 'Swag_DrugStatue', 'DRUGSTATUES' }, { 'Swag_DrugBags', 'DRUGBAGS' },
    { 'Swag_Counterfeit', 'COUNTERFEIT' }, { 'Swag_Booze_cigs', 'BOOZE' }, { 'Swag_Art', 'ART' },
}
local function money(value)
    local raw = tostring(math.floor(value or 0)); local negative = raw:sub(1, 1) == '-'
    if negative then raw = raw:sub(2) end
    return (negative and '-$' or '$') .. raw:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
end
function Panels.new(view) return setmetatable({ view = view, ctx = view.ctx, manager = view.manager }, Panels) end

function Panels:text(key) return self.ctx.translator:text(key) end

function Panels:button(key, callback, disabled, width, height)
    ImGui.BeginDisabled(disabled or false)
    if Widgets.button(self.ctx, self:text(key), width or 0, height or 0) then self.manager:run(key, callback) end
    ImGui.EndDisabled()
end

function Panels:help(key)
    Widgets.help(self.ctx, self:text(key))
end

function Panels:setting(key, label)
    local path = 'features.yrv3.' .. key
    local value, changed = Widgets.toggle(self.ctx, self:text(label), self.ctx.settings:get(path) or false)
    if changed then self.ctx.settings:set(path, value) end
end

function Panels:center(text)
    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + math.max(0, (ImGui.GetContentRegionAvail() - ImGui.CalcTextSize(text)) *
        0.5))
    ImGui.Text(text)
end

function Panels:nameplate(front, kind, keep_vehicle)
    ImGui.PushID(kind)
    local color
    if kind == 'nightclub' and self.synthwave then
        local t = os.clock(); local beat = (math.sin(t * 1.8) + 1) * 0.5; local accent = ((math.sin(t * 6) + 1) * 0.5) ^
            1.5
        local r, g, b = ImGui.ColorConvertHSVtoRGB((t * 0.05) % 1, 0.7, 0.8)
        local fr, fg, fb = ImGui.ColorConvertHSVtoRGB((t * 0.05 + 0.2) % 1, 0.9, 1)
        color = {}; for i, v in ipairs({ r, g, b }) do
            color[i] = (({ 12 / 255, 12 / 255, 18 / 255 })[i] * (1 - beat * 0.6) + v * beat * 0.6) *
                (1 - accent * 0.8) + ({ fr, fg, fb })[i] * accent * 0.8
        end
        color[4] = (220 / 255 * (1 - beat * 0.6) + beat * 0.6) * (1 - accent * 0.8) + accent * 0.8
        ImGui.PushStyleColor(ImGuiCol.Border, unpack(color))
    end
    if ImGui.BeginChild('##nameplate', 0, 130, true, bit.bor(ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.AlwaysUseWindowPadding)) then
        if kind == 'office' or kind == 'clubhouse' or kind == 'nightclub' then
            local y = ImGui.GetCursorPosY()
            ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - 30)
            ImGui.SetWindowFontScale(0.78)
            if ImGui.SmallButton(' . . . ') then ImGui.OpenPopup('##front_options') end
            ImGui.SetWindowFontScale(1)
            if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and not self.ctx.settings:get('ui.disable_tooltips') then
                Widgets.tooltip(self.ctx, self:text('GENERIC_OPTIONS_LABEL'))
            end
            if ImGui.BeginPopup('##front_options') then
                if kind == 'nightclub' then
                    self.synthwave = Widgets.toggle(self.ctx, 'Synthwave & Pain', self.synthwave or false); ImGui
                        .Separator()
                end
                if ImGui.MenuItem(self:text('GENERIC_RENAME')) then
                    self.rename_kind = kind; self.rename_text = front.custom or ''; self.open_rename = true; ImGui
                        .CloseCurrentPopup()
                end
                if kind == 'office' and ImGui.MenuItem(self:text('YRV3_OFFICE_CLUTTER_LABEL')) then
                    self.open_clutter = true; ImGui.CloseCurrentPopup()
                end
                ImGui.EndPopup()
            end
            ImGui.SetCursorPosY(y)
        end
        ImGui.SetWindowFontScale(1.18)
        if color then ImGui.PushStyleColor(ImGuiCol.Text, unpack(color)) end
        self:center(front.custom or front.name)
        if color then ImGui.PopStyleColor() end
        ImGui.Spacing(); ImGui.SetWindowFontScale(0.8)
        if front.name ~= front.custom and front.custom then self:center(front.name) end
        ImGui.SetWindowFontScale(1)
        self.view:location(front, keep_vehicle)
    end
    ImGui.EndChild(); if color then ImGui.PopStyleColor() end; ImGui.PopID()
    if self.open_rename then
        ImGui.OpenPopup('##front_rename'); self.open_rename = false
    end
    local _, draw = ImGui.BeginPopupModal('##front_rename', true,
        bit.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoSavedSettings, ImGuiWindowFlags.NoMove))
    if draw then
        if self.rename_kind == 'nightclub' then
            local current = (self.manager.fronts.nightclub and self.manager.fronts.nightclub.name_id) or 0
            local selected, changed = ImGui.Combo('##clubName', current, definitions.NightclubNames,
                #definitions.NightclubNames)
            if changed then
                self.manager:run('nightclub rename',
                    function() self.manager.extras:rename('nightclub', tostring(selected)) end); ImGui.CloseCurrentPopup()
            end
        else
            local value = Widgets.input_text_with_hint(self.ctx, '##newName', self:text('GENERIC_NAME'), self.rename_text)
            self.rename_text = Widgets.validated_text(self.rename_text, value, 15)
            ImGui.SameLine()
            ImGui.BeginDisabled(#self.rename_text > 15)
            if Widgets.button(self.ctx, self:text('GENERIC_SAVE')) then
                local kind, name = self.rename_kind, self.rename_text
                self.manager:run('business rename', function() self.manager.extras:rename(kind, name) end)
                self.rename_text = ''; ImGui.CloseCurrentPopup()
            end
            ImGui.EndDisabled()
            ImGui.SameLine()
            if Widgets.button(self.ctx, self:text('GENERIC_CANCEL')) then ImGui.CloseCurrentPopup() end
        end
        ImGui.EndPopup()
    end
end

function Panels:safe(record, without_progress)
    if not record then return end
    local value = record.snapshot or {}; local cash, maximum = value.count or 0, value.capacity or 0
    if not without_progress then self.view:progress('YRV3_CASH_SAFE', cash, maximum, money(cash)) end
    ImGui.BeginDisabled(not self.ctx.settings:get('features.unsafe_feats_enabled'))
    if record.global_offset or record.car_wash then
        self:button('YRV3_CASH_FILL', function() record:fill_safe() end, cash == maximum)
        self:help('YRV3_CASH_FILL_TT')
    end
    if record.paytime_stat then
        ImGui.BeginDisabled(cash >= maximum)
        record.loop = Widgets.toggle(self.ctx, self:text('YRV3_CASH_LOOP'), record.loop)
        ImGui.EndDisabled()
    end
    ImGui.EndDisabled()
end

function Panels:clutter()
    if self.open_clutter then
        ImGui.OpenPopup('##office_clutter'); self.open_clutter = false
    end
    local _, draw = ImGui.BeginPopupModal('##office_clutter', true, ImGuiWindowFlags.AlwaysAutoResize)
    if not draw then return end
    self:setting('office_clutter.auto_disable', 'YRV3_OFFICE_CLUTTER_AUTO_CLEAR'); self:help(
        'YRV3_OFFICE_CLUTTER_AUTO_CLEAR_TT')
    ImGui.Spacing(); ImGui.SeparatorText(self:text('YRV3_OFFICE_CLUTTER_ITEM_SELECT'))
    local all = true
    for _, item in ipairs(clutter) do if not self.ctx.settings:get('features.yrv3.office_clutter.items.' .. item[1]) then all = false end end
    if Widgets.button(self.ctx, self:text(all and 'YRV3_CB_UNCHECK_ALL' or 'YRV3_CB_CHECK_ALL')) then
        for _, item in ipairs(clutter) do self.ctx.settings:set('features.yrv3.office_clutter.items.' .. item[1], not all) end
    end
    for index, item in ipairs(clutter) do
        self:setting('office_clutter.items.' .. item[1], 'YRV3_OFFICE_CLUTTER_' .. item[2])
        if index % 2 == 1 and index < #clutter then ImGui.SameLine(260) end
    end
    ImGui.EndPopup()
end

function Panels:earnings()
    self.show_earnings = Widgets.toggle(self.ctx, self:text('YRV3_SHOW_EARNINGS_DATA'), self.show_earnings or false)
    if not self.show_earnings then return end
    ImGui.Separator()
    local label_width = 0
    for _, data in ipairs(earnings) do label_width = math.max(label_width, ImGui.CalcTextSize(self:text(data[1])) + 60) end
    for index, data in ipairs(earnings) do
        ImGui.PushID(index)
        if Widgets.button(self.ctx, self:text('GENERIC_EDIT')) then
            self.earnings_index = index; self.earnings_value = self.manager.extras.earnings[data[2]] or 0; self.open_earnings = true
        end
        ImGui.SameLine(); ImGui.Text(self:text(data[1])); ImGui.SameLine(label_width)
        local value = self.manager.extras.earnings[data[2]] or 0
        if index == 5 then ImGui.TextColored(0.52, 0.73, 0.40, 1, money(value)) else ImGui.Text(tostring(value)) end
        ImGui.PopID()
    end
    ImGui.Separator()
    local popup = self:text('YRV3_EDIT_EARNINGS_DATA') .. '##' .. tostring(self.earnings_index or 1)
    if self.open_earnings then
        ImGui.OpenPopup(popup); self.open_earnings = false
    end
    local _, draw = ImGui.BeginPopupModal(popup, true,
        bit.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoSavedSettings, ImGuiWindowFlags.NoMove))
    if draw then
        local data = earnings[self.earnings_index]
        ImGui.Text(self:text(data[1])); self.earnings_value = Widgets.input_int(self.ctx, '##new_value', self.earnings_value, data[4],
            data[5])
        self.earnings_value = math.max(0, math.min(data[3], math.floor(self.earnings_value)))
        ImGui.SameLine()
        if Widgets.button(self.ctx, self:text('GENERIC_SAVE')) then
            local value = self.earnings_value; self.manager:run('office earnings',
                function() stats.set_int(data[2], value) end); ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
    end
end

function Panels:vehicle_warehouse()
    local front = self.manager.fronts.vehicle_warehouse; local extras = self.manager.extras
    if not front then
        ImGui.Text(self:text('YRV3_IE_WH_NOT_OWNED')); return
    end
    if ImGui.BeginChild('##vehicle_warehouse', 0, 420, false, ImGuiWindowFlags.NoScrollbar) then
        ImGui.SeparatorText(front.name); self.view:location(front, false); ImGui.Separator(); ImGui.Spacing()
        self.view:progress('YRV3_IE_VEHS_AMT', #extras.storage, 40, tostring(#extras.storage) .. ' / 40')
        self.view:kv('YRV3_IE_VEHS_BASE_VAL_TOTAL', money(extras.ie_income), true)
        ImGui.Spacing(); ImGui.Text(self:text('YRV3_IE_VEHS_OVERVIEW'))
        local counts = extras.range_counts or { 0, 0, 0 }
        for _, entry in ipairs({ { 3, 'YRV3_IE_VEH_RANGE_LOW' }, { 2, 'YRV3_IE_VEH_RANGE_MID' }, { 1, 'YRV3_IE_VEH_RANGE_HIGH' } }) do
            self.view:kv(entry[2], tostring(counts[entry[1]]) .. ' / 10')
        end
        self.view:kv('YRV3_IE_STEAL_TOP_CHANCE',
            self:text(counts[2] == 10 and counts[3] == 10 and counts[1] >= 10 and 'YRV3_IE_STEAL_THRESHOLD_TRUE' or
                'YRV3_IE_STEAL_THRESHOLD_FALSE'))
        ImGui.SetWindowFontScale(0.85); ImGui.TextWrapped(self:text('YRV3_IE_STEAL_THRESHOLD_TT')); ImGui
            .SetWindowFontScale(1)
    end
    ImGui.EndChild()
    if #extras.storage > 0 then
        local changed
        self.storage_details, changed = Widgets.toggle(self.ctx, self:text('YRV3_IE_VEHS_DETAILS_CB'),
            self.storage_details or false)
        if self.storage_details and ImGui.BeginTable('##ie_veh_storage', 5, bit.bor(ImGuiTableFlags.RowBg, ImGuiTableFlags.Borders, ImGuiTableFlags.BordersInner)) then
            ImGui.TableSetupColumn(self:text('YRV3_IE_VEH_SLOT'), ImGuiTableColumnFlags.WidthFixed, 40)
            for _, key in ipairs({ 'GENERIC_NAME', 'YRV3_IE_VEH_PLATE', 'YRV3_IE_VEH_RANGE', 'YRV3_IE_VEH_COMMISSION' }) do
                ImGui.TableSetupColumn(self:text(key))
            end
            ImGui.TableHeadersRow()
            local range_labels = { 'YRV3_IE_VEH_RANGE_HIGH', 'YRV3_IE_VEH_RANGE_MID', 'YRV3_IE_VEH_RANGE_LOW' }
            for _, vehicle in ipairs(extras.storage) do
                ImGui.TableNextRow()
                for index, value in ipairs({ vehicle.slot, vehicle.name, vehicle.plate or '', self:text(range_labels[vehicle.range]), money(vehicle.value) }) do
                    ImGui.TableSetColumnIndex(index - 1); ImGui.Text(tostring(value))
                end
            end
            ImGui.EndTable()
        end
        if changed and self.storage_details and ImGui.GetCursorPosY() > ImGui.GetWindowHeight() then
            ImGui
                .SetScrollHereY()
        end
    end
end

function Panels:office()
    local front = self.manager.fronts.office
    if not front then
        ImGui.Text(self:text('YRV3_CEO_OFFICE_NOT_OWNED')); return
    end
    self:nameplate(front, 'office', false); self:clutter(); ImGui.Spacing()
    if ImGui.BeginTabBar('##import_export') then
        if ImGui.BeginTabItem(self:text('YRV3_CARGO_WAREHOUSES_LABEL')) then
            local records = self.view:records('office')
            if #records == 0 then
                ImGui.Text(self:text('YRV3_CEO_NONE_OWNED'))
            else
                self:earnings()
                if ImGui.BeginTabBar('##cargo_warehouses') then
                    for index, record in ipairs(records) do
                        if ImGui.BeginTabItem(self.ctx.translator:format('YRV3_WAREHOUSE_SLOT', index)) then
                            self.view:record(record); ImGui.EndTabItem()
                        end
                    end
                    ImGui.EndTabBar()
                end
            end
            local unavailable = not scripts.is_active('gb_contraband_buy') and not scripts.is_active('fm_content_cargo')
            self:button('YRV3_FINISH_SOURCE_MISSION', function() self.manager.actions:finish_source() end, unavailable)
            if unavailable then Widgets.tooltip(self.ctx, self:text('YRV3_FINISH_SOURCE_MISSION_TT')) end
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(self:text('YRV3_VEHICLE_WAREHOUSE_LABEL')) then
            self:vehicle_warehouse(); ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
end

function Panels:clubhouse()
    local front = self.manager.fronts.clubhouse
    if not front then
        ImGui.Text(self:text('YRV3_CLUBHOUSE_NOT_OWNED')); return
    end
    self:nameplate(front, 'clubhouse', false); ImGui.Spacing()
    local safe = self.manager.lookup.clubhouse_safe
    local balance = safe and safe.snapshot or {}
    self.view:progress('YRV3_CASH_SAFE', balance.count or 0, balance.capacity or 0, money(balance.count))
    self.view:kv('YRV3_MC_CLIENT_BIKE_LABEL', self.manager.extras.client_bike_name or self:text('GENERIC_NONE'))
    self:safe(safe, true)
    ImGui.Spacing(); ImGui.SeparatorText(self:text('YRV3_BUSINESSES_LABEL'))
    local count = 0
    if ImGui.BeginTabBar('##mc_businesses') then
        for _, record in ipairs(self.view:records('clubhouse')) do
            if record.kind == 'factory' then
                count = count + 1
                if ImGui.BeginTabItem(record.normalized_name or self:text('GENERIC_UNKNOWN')) then
                    self.view:record(record); ImGui.EndTabItem()
                end
            end
        end
        ImGui.EndTabBar()
    end
    if count == 0 then ImGui.Text(self:text('YRV3_MC_NONE_OWNED')) end
end

function Panels:nightclub()
    local manager, extras = self.manager, self.manager.extras
    local front = manager.fronts.nightclub
    if not front then
        ImGui.Text(self:text('YRV3_CLUB_NOT_OWNED')); return
    end
    self:nameplate(front, 'nightclub', false)
    self.view:progress('YRV3_POPULARITY', extras.popularity or 0, 1000,
        string.format('%d%%', math.floor((extras.popularity or 0) / 10)))
    local safe = manager.lookup.nightclub_safe; local balance = safe and safe.snapshot or {}
    self.view:progress('YRV3_CASH_SAFE', balance.count or 0, balance.capacity or 0, money(balance.count))
    ImGui.Spacing()
    self:button(self:text('GENERIC_MAX') .. ' ' .. self:text('YRV3_POPULARITY'),
        function() stats.set_int('MPX_CLUB_POPULARITY', 1000) end, (extras.popularity or 0) >= 999)
    self:safe(safe, true)
    self:setting('nc_always_popular', 'YRV3_NC_ALWAYS_POPULAR')
    local enabled, changed = Widgets.toggle(self.ctx, self:text('YRV3_MILLION_DOLLAR_TIPS'), extras.big_tips or false)
    if changed then
        extras.big_tips = enabled
        manager:run('nightclub tips',
            function()
                manager.actions:lease('nightclub_tips',
                    { kind = 'tunable', type = 'int', t = 'BB_NIGHTCLUB_TOILET_ATTENDANT_TIP_COST', v = 1000000 },
                    enabled)
            end)
    end
    self:help('YRV3_MILLION_DOLLAR_TIPS_TT')
    local hubs, total = {}, 0
    for _, record in ipairs(manager.records) do
        if record.kind == 'hub' then
            hubs[#hubs + 1] = record; total = total + (record.snapshot and record.snapshot.value or 0)
        end
    end
    if #hubs == 0 then return end
    ImGui.Spacing(); ImGui.SeparatorText(self:text('YRV3_BUSINESS_HUB'))
    self.view:kv('YRV3_VALUE_TOTAL', money(total), true); ImGui.Separator(); ImGui.Spacing()
    local width = math.min(300, ImGui.GetWindowWidth())
    for _, record in ipairs(hubs) do
        local value = record.snapshot or {}; local tech = value.technician or -1
        local count, capacity = value.count or 0, value.capacity or 0; local full = count >= capacity
        ImGui.PushID(record.key); ImGui.SetNextWindowBgAlpha(0.64)
        if ImGui.BeginChild('##hub_child', width, tech >= 0 and 280 or 240, true, ImGuiWindowFlags.NoScrollbar) then
            ImGui.BeginDisabled(tech < 0)
            ImGui.SeparatorText(record.name); ImGui.SetWindowFontScale(0.68)
            self:center(tostring(count) .. '/' .. capacity); ImGui.SetWindowFontScale(1); ImGui.Spacing()
            Widgets.value_bar(self.ctx, '##bb_hub', capacity > 0 and count / capacity or 0, -1, 60, true)
            -- The supplied original disables these production controls on Enhanced.
            ImGui.BeginDisabled(not self.ctx.settings:get('features.unsafe_feats_enabled'))
            ImGui.BeginDisabled(true)
            ImGui.BeginDisabled(full)
            record.auto = Widgets.toggle(self.ctx, self:text('YRV3_AUTO_PROD'), record.auto)
            ImGui.EndDisabled()
            Widgets.tooltip(self.ctx, self:text('YRV3_TRIGGER_PROD_HUB_TT'))
            local can_trigger = (value.timer or -1) > 1000 and not record.auto and not full
            local label = self:text('YRV3_TRIGGER_PROD')
            local button_label = (can_trigger or (value.timer or -1) < 0) and label or Widgets.spinner()
            ImGui.BeginDisabled(not can_trigger or full)
            if Widgets.button(self.ctx, button_label, ImGui.CalcTextSize(label) + ImGui.GetStyle().FramePadding.x * 2, 0) then
                manager:run('nightclub production', function() record:produce() end)
            end
            ImGui.EndDisabled()
            ImGui.EndDisabled(); ImGui.EndDisabled(); ImGui.EndDisabled()
            if tech < 0 and not full then Widgets.tooltip(self.ctx, self:text('YRV3_HUB_TECH_NOT_ASSIGNED_TT')) end
            if tech >= 0 and Widgets.button(self.ctx, self:text('YRV3_HUB_TRANSFER_TECH')) then
                ImGui.OpenPopup(
                    '##transfer_tech')
            end
            if ImGui.BeginPopup('##transfer_tech') then
                self.transfer_empty_only = Widgets.toggle(self.ctx, self:text('YRV3_HUB_TRANSFER_TECH_REL_ONLY'),
                    self.transfer_empty_only or false)
                self:help('YRV3_HUB_TRANSFER_TECH_REL_ONLY_TT'); ImGui.Separator(); ImGui.Spacing()
                for _, other in ipairs(hubs) do
                    local snapshot = other.snapshot or {}
                    if other ~= record and (not self.transfer_empty_only or (snapshot.technician or -1) < 0 and (snapshot.count or 0) < (snapshot.capacity or 0)) then
                        if ImGui.MenuItem(other.name) then
                            manager:run('transfer nightclub technician',
                                function() extras:transfer(record.key, other.key) end)
                            ImGui.CloseCurrentPopup()
                        end
                    end
                end
                ImGui.Separator(); ImGui.Spacing()
                if Widgets.button(self.ctx, self:text('GENERIC_CANCEL')) then ImGui.CloseCurrentPopup() end
                ImGui.EndPopup()
            end
        end
        ImGui.EndChild(); ImGui.PopID(); Widgets.same_line_if_available(width)
    end
end

function Panels:salvage()
    local manager, extras = self.manager, self.manager.extras
    local front = manager.fronts.salvage; local value = extras.salvage
    if not front or not value then
        ImGui.Text(self:text('SY_NOT_OWNED')); return
    end
    self:nameplate(front, 'salvage', true); ImGui.Spacing()
    local safe = manager.lookup.salvage_safe; local balance = safe and safe.snapshot or {}
    self.view:progress('YRV3_CASH_SAFE', balance.count or 0, balance.capacity or 0, money(balance.count))
    self.view:progress('SY_INCOME_THRESHOLD', value.income or 0, 100)
    self:button('SY_MAX_THRESHOLD', function() extras:salvage_action('income') end, (value.income or 0) >= 100)
    self:safe(safe, true)
    self:setting('sy_always_max_income', 'SY_ALWAYS_MAX_INCOME'); self:help('SY_ALWAYS_MAX_INCOME_TT')
    ImGui.Spacing()
    if ImGui.BeginTabBar('##salvage_yard_tb') then
        if ImGui.BeginTabItem(self:text('SY_CHOP_SHOP')) then
            ImGui.Spacing(); self:setting('sy_disable_tow_cd', 'SY_DISABLE_TOWING_COOLDOWN')
            self:button('SY_TOW_MISSION_BRING_VEH', function() extras:tow_target() end,
                not scripts.is_active('fm_content_tow_truck_work') or extras.towing)
            self:help('SY_TOW_MISSION_BRING_VEH_TT'); ImGui.Spacing(); ImGui.Separator()
            for index, lift in ipairs(value.lifts) do
                local taken = lift.model ~= 0
                ImGui.PushID(index); ImGui.SetNextWindowBgAlpha(0.64); ImGui.BeginDisabled(not taken)
                if ImGui.BeginChild('##lift', 240, taken and 210 or 100, false, ImGuiWindowFlags.NoScrollbar) then
                    ImGui.SeparatorText(self.ctx.translator:format('SY_LIFT', index)); ImGui.Spacing()
                    if not taken then
                        ImGui.Text(self:text('SY_LIFT_EMPTY'))
                    else
                        self.view:kv('GENERIC_VEHICLE', lift.name or '')
                        self.view:kv('GENERIC_VALUE', money(lift.value), true)
                        local seconds = math.max(0, lift.due - os.time())
                        self.view:kv('GENERIC_TIME_LEFT',
                            string.format('%02d:%02d:%02d', math.floor(seconds / 3600), math.floor(seconds / 60) % 60,
                                seconds % 60))
                        ImGui.Separator()
                        self:button('SY_INSTANT_SALVAGE', function() extras:salvage_now(index) end, lift.due <= 1)
                    end
                end
                ImGui.EndChild(); ImGui.EndDisabled(); ImGui.PopID(); Widgets.same_line_if_available(240)
            end
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(self:text('SY_CAR_ROBBERIES')) then
            self:setting('sy_disable_rob_cd', 'SY_DISABLE_COOLDOWN'); ImGui.SameLine()
            local path = 'features.yrv3.sy_disable_rob_weekly_cd'
            local enabled, changed = Widgets.toggle(self.ctx, self:text('SY_DISABLE_WEEKLY_COOLDOWN'),
                self.ctx.settings:get(path))
            if changed then
                self.ctx.settings:set(path, enabled)
                manager:run('salvage weekly cooldown',
                    function() extras:salvage_action(enabled and 'weekly' or 'weekly_reset') end)
            end
            ImGui.Spacing(); ImGui.SeparatorText(self:text('SY_WEEKLY_ROBBERIES'))
            local labels = require('includes.ssv2.data.sv23_data').robbery_status_labels
            for index, robbery in ipairs(value.weekly) do
                ImGui.Text(self.ctx.translator:format('SY_WEEKLY_CAR_STATUS', index,
                    self:text(labels[robbery.status + 1] or 'GENERIC_UNKNOWN'))); ImGui.Separator()
            end
            ImGui.Spacing(); ImGui.Text(self.ctx.translator:format('SY_CURRENT_ROBBERY', value.name))
            if value.active then
                ImGui.Text(self.ctx.translator:format('SY_ROBBERY_ACTIVE_CAR', value.vehicle_name or ''))
                ImGui.Text(self.ctx.translator:format('SY_ROBBERY_CAR_VALUE', value.value))
                ImGui.Text(self.ctx.translator:format('SY_ROBBERY_CAN_KEEP_CAR', tostring(value.keep)))
                self:button('SY_DOUBLE_CAR_WORTH', function() extras:salvage_action('double') end)
                ImGui.SameLine(); self:button('SY_COMPLETE_PREPARATIONS', function() extras:salvage_action('skip') end,
                    value.preps_complete)
            end
            ImGui.Spacing()
            for index, car in ipairs(value.garage) do
                local available = car.name and car.name ~= '' and car.name ~= 'Empty'
                ImGui.PushID(index); ImGui.SetNextWindowBgAlpha(0.64); ImGui.BeginDisabled(not available)
                if ImGui.BeginChild('##robbery', 240, available and 180 or 100, false, ImGuiWindowFlags.NoScrollbar) then
                    ImGui.SeparatorText(self.ctx.translator:format('SY_VEH_SLOT', index))
                    if not available then
                        ImGui.Text(self:text('SY_EMPTY'))
                    else
                        self.view:kv('GENERIC_VEHICLE', car.name); self.view:kv('GENERIC_VALUE', money(car.value), true)
                    end
                end
                ImGui.EndChild(); ImGui.EndDisabled(); ImGui.PopID(); Widgets.same_line_if_available(240)
            end
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
end

function Panels:money_fronts()
    local manager = self.manager
    if not manager.fronts.car_wash then
        ImGui.Text(self:text('YRV3_CWASH_NOT_OWNED')); return
    end
    local keys = { [24924] = 'cwash', [24925] = 'weedshop', [24926] = 'helitours' }
    for _, record in ipairs(manager.records) do
        if record.kind == 'heat' then
            local parent = record.heat == 24924; local value = record.snapshot or {}; local heat = value.heat or 0
            ImGui.PushID(record.key)
            if ImGui.BeginChild('##money_front', 0, parent and 385 or 280, false, ImGuiWindowFlags.NoScrollbar) then
                ImGui.SeparatorText(record.name); self.view:location(record, false); ImGui.Separator(); ImGui.Spacing()
                local safe = parent and manager.lookup.car_wash_safe
                if parent then
                    local duffle = manager.lookup.car_wash_duffle; local cash = duffle and duffle.snapshot or {}
                    local clean, dirty, capacity = cash.clean or 0, cash.pending or 0, cash.capacity or 0
                    ImGui.Text(self:text('YRV3_CWASH_WORK_EARNINGS')); ImGui.SameLine()
                    local text = string.format('(%s %s | %s %s) / $1M', self:text('YRV3_CWASH_CASH_CLEAN'), money(clean),
                        self:text('YRV3_CWASH_CASH_DIRTY'), money(dirty))
                    Widgets.value_bar(self.ctx, '##carWashDuffle', capacity > 0 and clean / capacity or 0, -1, 25, false,
                        capacity > 0 and dirty / capacity or 0, text, { 0.405, 0.584, 0.313, 1 }, { 1, 0, 0, 1 })
                    local balance = safe and safe.snapshot or {}
                    self.view:progress('YRV3_CASH_SAFE', balance.count or 0, balance.capacity or 0, money(balance.count))
                end
                ImGui.PushStyleColor(ImGuiCol.PlotHistogram, math.max(0, math.min(1, heat / 100 + 0.1)),
                    math.max(0, math.min(1, 0.5 - heat / 100)), 0, 1)
                self.view:progress('YRV3_CWASH_HEAT', heat, 100, string.format('%d%%', heat)); ImGui.PopStyleColor()
                self:button(self:text('GENERIC_CLEAR') .. ' ' .. self:text('YRV3_CWASH_HEAT'),
                    function() stats.set_packed_int(record.heat, 0) end, heat == 0)
                ImGui.Spacing()
                if safe then self:safe(safe, true) end
                self:setting(keys[record.heat] .. '_legal_work_cd', 'YRV3_CWASH_LEGAL_WORK_CD')
                self:setting(keys[record.heat] .. '_illegal_work_cd', 'YRV3_CWASH_ILLEGAL_WORK_CD')
            end
            ImGui.EndChild(); ImGui.PopID()
        end
    end
end

function Panels:misc()
    local cooldowns = {
        { 'YRV3_CLUB_WORK_CB',    'mc_work_cd' }, { 'YRV3_HANGAR_STEAL_CB', 'hangar_cd' },
        { 'YRV3_NC_MANAGMENT_CB', 'nc_management_cd' }, { 'YRV3_NC_CHANCE_ENCOUNTER_CB', 'nc_vip_mission_chance' },
        { 'YRV3_SECURITY_WORK_CB', 'security_missions_cd' }, { 'YRV3_IE_VEH_STEAL_CB', 'ie_vehicle_steal_cd' },
        { 'YRV3_IE_VEH_SELL_CB',   'ie_vehicle_sell_cd' }, { 'YRV3_CEO_BUY_CB', 'ceo_crate_buy_cd' },
        { 'YRV3_CEO_SELL_CB',      'ceo_crate_sell_cd' }, { 'YRV3_DAX_WORK_CB', 'dax_work_cd' },
        { 'YRV3_HACKER_DEN_CD_CB', 'garment_rob_cd' },
    }
    ImGui.SeparatorText(self:text('YRV3_COOLDOWNS_LABEL'))
    local all = true
    for _, entry in ipairs(cooldowns) do
        self:setting(entry[2], entry[1])
        if not self.ctx.settings:get('features.yrv3.' .. entry[2]) then all = false end
        if entry[2] == 'nc_vip_mission_chance' then self:help('YRV3_NC_CHANCE_ENCOUNTER_TT') end
    end
    ImGui.BeginDisabled(true); Widgets.toggle(self.ctx, self:text('YRV3_PAYHPONE_HITS_CB') .. ' [x]', false); ImGui
        .EndDisabled()
    if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
        Widgets.tooltip(self.ctx, self:text('YRV3_SEXY_SHINABI_NOTICE'))
        if ImGui.IsKeyPressed(ImGuiKey.Tab, false) then
            local url = 'https://github.com/YimMenu-Lua/PayphoneHits'; ImGui.SetClipboardText(url)
            self.ctx.notifier:info('Business Manager', self.ctx.translator:format('GENERIC_URL_COPY_SUCCESS', url), 6)
        end
    end
    ImGui.Spacing()
    if Widgets.button(self.ctx, self:text(all and 'YRV3_CB_UNCHECK_ALL' or 'YRV3_CB_CHECK_ALL'), 120, 40) then
        for _, entry in ipairs(cooldowns) do self.ctx.settings:set('features.yrv3.' .. entry[2], not all) end
    end
    ImGui.Spacing()
end

function Panels:draw(kind)
    if kind == 'office' then
        self:office()
    elseif kind == 'clubhouse' then
        self:clubhouse()
    elseif kind == 'nightclub' then
        self:nightclub()
    elseif kind == 'salvage' then
        self:salvage()
    elseif kind == 'car_wash' then
        self:money_fronts()
    else
        local records = self.view:records(kind)
        for _, record in ipairs(records) do
            if kind ~= 'safes' or record.key:match('^safe_') then
                self.view:record(
                    record)
            end
        end
        if #records == 0 and not self.manager.fronts[kind] then
            local label = ({ hangar = 'YRV3_HANGAR_NOT_OWNED', bunker = 'YRV3_BUNKER_NOT_OWNED', acid_lab = 'YRV3_LSD_LAB_NOT_OWNED', nightclub = 'YRV3_CLUB_NOT_OWNED', salvage = 'SY_NOT_OWNED', car_wash = 'YRV3_CWASH_NOT_OWNED' })
                [kind]
            ImGui.TextWrapped(self:text(label or 'GENERIC_NOT_OWNED'))
        end
    end
end

return Panels
