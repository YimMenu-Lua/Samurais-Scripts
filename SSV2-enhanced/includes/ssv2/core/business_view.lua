-- Business Manager's header/sidebar/dashboard arrangement from the original frontend.
-- GPL-3.0-or-later; see LICENSE.
local Widgets = require('includes.ssv2.core.widgets')
local Game = require('includes.ssv2.core.game')
local View = {}; View.__index = View
local pages = {
    { 'YRV3_DASHBOARD', 'dashboard' }, { 'GB_BOSSC', 'office' }, { 'GB_REST_ACCM', 'clubhouse' },
    { 'CELL_CLUB',      'nightclub' }, { 'CELL_HANGAR', 'hangar' }, { 'CELL_BUNKER', 'bunker' },
    { 'CELL_ACID_LAB',         'acid_lab' }, { 'CELL_SLVG_YRD', 'salvage' }, { 'MP_CARWASH', 'car_wash' },
    { 'YRV3_CASH_SAFES_LABEL', 'safes' }, { 'GENERIC_MISC', 'misc' }, { 'CELL_16', 'settings' },
}
local function money(value)
    local text = tostring(math.floor(value or 0))
    local negative = text:sub(1, 1) == '-'
    if negative then text = text:sub(2) end
    text = text:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
    return (negative and '-$' or '$') .. text
end
function View.new(ctx, manager)
    return setmetatable({ ctx = ctx, manager = manager, selected = 1, transfer_amount = 0, transfer_widget = 0 }, View)
end

function View:kv(label, value, green)
    local width = ImGui.GetContentRegionAvail()
    local x, y = ImGui.GetCursorPos()
    ImGui.Text(self.ctx.translator:text(label))
    ImGui.SameLine()
    local text = tostring(value)
    ImGui.SetCursorPos(x + math.max(0, width - ImGui.CalcTextSize(text)), y)
    if green then ImGui.TextColored(0.52, 0.73, 0.40, 1, text) else ImGui.Text(text) end
end

function View:boss()
    local extras, tr = self.manager.extras, self.ctx.translator
    local boss = extras.boss or { type = -1 }
    if boss.type > -1 and not boss.associate then
        if Widgets.button(self.ctx, tr:text('PIM_MAGM0B')) then
            self.manager:run('retire',
                function() extras:boss_action(-1) end)
        end
        return
    end
    ImGui.BeginDisabled(boss.associate or false)
    if Widgets.button(self.ctx, tr:text('PIM_REGBOSS')) then ImGui.OpenPopup('##bossRegister') end
    ImGui.EndDisabled()
    if boss.associate then Widgets.tooltip(self.ctx, tr:text('YRV3_DASHBOARD_BOSS_ASSOCIATE_ERR')) end
    local _, draw = ImGui.BeginPopupModal('##bossRegister', true,
        bit.bor(ImGuiWindowFlags.NoResize, ImGuiWindowFlags.AlwaysAutoResize))
    if draw then
        self.boss_type = self.boss_type or -1
        local choices = { { name = self.manager.fronts.office and 'PIM_MAGBC' or 'PIM_MAGB', id = 0 } }
        if self.manager.fronts.clubhouse then choices[#choices + 1] = { name = 'PI_BIK_MCP', id = 1 } end
        ImGui.Spacing()
        local selected = choices[self.boss_type + 1]
        if ImGui.BeginCombo('##registerAsBoss', tr:text(selected and selected.name or 'GENERIC_NONE')) then
            for _, choice in ipairs(choices) do
                ImGui.Selectable(tr:text(choice.name), self.boss_type == choice.id)
                if ImGui.IsItemClicked(0) then self.boss_type = choice.id end
            end
            ImGui.EndCombo()
        end
        ImGui.Spacing(); ImGui.BeginDisabled(self.boss_type == -1)
        if Widgets.button(self.ctx, tr:text('GENERIC_CONFIRM')) and self.boss_type >= 0 then
            local kind = self.boss_type
            self.manager:run('boss registration', function() extras:boss_action(kind) end); ImGui.CloseCurrentPopup()
        end
        ImGui.EndDisabled(); ImGui.SameLine()
        if Widgets.button(self.ctx, tr:text('GENERIC_CANCEL')) then
            self.boss_type = -1; ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
    end
end

function View:transfer(deposit, popup)
    local account = self.manager.extras.money
    local maximum = deposit and account.wallet or account.bank
    ImGui.SetNextItemWidth(120)
    self.transfer_widget = ImGui.Combo('Widget Type', self.transfer_widget, { 'Slider', 'Input' }, 2)
    ImGui.SetNextItemWidth(400)
    if self.transfer_widget == 0 then
        self.transfer_amount = ImGui.SliderInt('##account_transfer', self.transfer_amount, 0, maximum,
            money(self.transfer_amount))
    else
        self.transfer_amount = Widgets.input_int(self.ctx, '##account_transfer', self.transfer_amount, 1000, 100000)
    end
    self.transfer_amount = math.max(0, math.min(maximum, self.transfer_amount))
    ImGui.SameLine()
    if Widgets.button(self.ctx, 'Max') then self.transfer_amount = maximum end
    ImGui.BeginDisabled(self.transfer_amount <= 0 or account.busy)
    if Widgets.button(self.ctx, self.ctx.translator:text('GENERIC_CONFIRM')) then
        local amount, serial = self.transfer_amount, self.manager.serial
        self.manager:run('account transfer', function()
            account:transfer(deposit, amount, function() return self.manager.active and self.manager.serial == serial end)
            self.transfer_amount = 0
        end)
        if popup then ImGui.CloseCurrentPopup() end
    end
    ImGui.EndDisabled(); ImGui.SameLine()
    if Widgets.button(self.ctx, self.ctx.translator:text('GENERIC_CANCEL')) then
        self.transfer_amount = 0; if popup then ImGui.CloseCurrentPopup() end
    end
end

function View:funds_popup()
    local _, draw = ImGui.BeginPopupModal('Manage Funds##ssv2_funds', true, ImGuiWindowFlags.AlwaysAutoResize)
    if draw then
        if ImGui.BeginTabBar('##funds') then
            for _, entry in ipairs({ { 'YRV3_DASHBOARD_FUNDS_DEPOSIT', true }, { 'YRV3_DASHBOARD_FUNDS_WITHDRAW', false } }) do
                if ImGui.BeginTabItem(self.ctx.translator:text(entry[1])) then
                    self:transfer(entry[2], false); ImGui.EndTabItem()
                end
            end
            ImGui.EndTabBar()
        end
        ImGui.EndPopup()
    end
end

function View:card(label, value, width, bank)
    local bg = bank and { 0.78, 0.78, 0.78, 0.90 } or { 0.033, 0.45, 0.15, 0.95 }
    ImGui.PushStyleColor(ImGuiCol.ChildBg, unpack(bg))
    ImGui.PushStyleColor(ImGuiCol.Text, bank and 0.05 or 0.9, bank and 0.05 or 0.9, bank and 0.05 or 0.9, 1)
    if ImGui.BeginChild('##money_card_' .. label, width, 90, false) then
        ImGui.SetWindowFontScale(0.75); ImGui.Text(self.ctx.translator:text(label))
        ImGui.SetWindowFontScale(1.15); ImGui.Text(money(value)); ImGui.SetWindowFontScale(1)
    end
    ImGui.EndChild(); ImGui.PopStyleColor(2)
end

function View:dashboard()
    local manager, extras, tr = self.manager, self.manager.extras, self.ctx.translator
    ImGui.SetWindowFontScale(1.34)
    local greeting = tr:text('GENERIC_HELLO') .. ', ' .. (extras.player_name or extras.character_name or '')
    local width = ImGui.GetContentRegionAvail()
    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + math.max(0, (width - ImGui.CalcTextSize(greeting)) * 0.5))
    ImGui.Text(greeting); ImGui.SetWindowFontScale(1); ImGui.Separator()
    ImGui.SetWindowFontScale(0.88)
    self:kv('YRV3_MP_CHAR_INDEX', extras.character_index or 0)
    self:kv('YRV3_MP_CHAR_NAME', extras.character_name or '')
    local boss = extras.boss
    local description
    if boss and boss.type == 0 then
        local office = manager.fronts.office
        description = tr:format('YRV3_DASHBOARD_BOSS_CEO_FMT',
            office and (office.custom or office.name) or tr:text('GENERIC_UNKNOWN'))
    elseif boss and boss.type == 1 then
        local club = manager.fronts.clubhouse
        description = tr:format('YRV3_DASHBOARD_BOSS_PRES_FMT',
            club and (club.custom or club.name) or tr:text('GENERIC_UNKNOWN'))
    else
        description = tr:text(boss and boss.associate and 'YRV3_DASHBOARD_BOSS_ASSOCIATE' or
            'YRV3_DASHBOARD_BOSS_RETIRED')
    end
    self:kv('YRV3_DASHBOARD_BOSS_TYPE', description)
    ImGui.SetWindowFontScale(1); ImGui.Spacing(); self:boss(); ImGui.Separator(); ImGui.Spacing()
    ImGui.PushStyleColor(ImGuiCol.ChildBg, 0.08, 0.08, 0.08, 0.9)
    if ImGui.BeginChild('##portfolio', 0, 315, true) then
        ImGui.SeparatorText(tr:text('YRV3_DASHBOARD_FINANCES'))
        ImGui.SetWindowFontScale(0.8)
        self:kv('YRV3_DASHBOARD_NET_WORTH', money(extras.net_worth), true)
        self:kv('YRV3_DASHBOARD_FUNDS_TOTAL', money(extras.money.total), true)
        self:kv('YRV3_INCOME_APPROX_ALL', money(manager.total), true)
        ImGui.SetWindowFontScale(1); ImGui.Separator(); ImGui.Spacing()
        local available = ImGui.GetContentRegionAvail()
        local card_width = math.max(200, available * 0.484)
        self:card('YRV3_DASHBOARD_FUNDS_WALLET', extras.money.wallet, card_width, false)
        if available >= card_width * 2 + 10 then ImGui.SameLine() end
        self:card('YRV3_DASHBOARD_FUNDS_BANK', extras.money.bank, card_width, true)
        ImGui.Spacing()
        for index, entry in ipairs({ { 'YRV3_DASHBOARD_FUNDS_DEPOSIT', true }, { 'YRV3_DASHBOARD_FUNDS_WITHDRAW', false } }) do
            if index == 2 and available >= card_width * 2 + 10 then ImGui.SameLine() end
            ImGui.BeginDisabled((entry[2] and extras.money.wallet or extras.money.bank) <= 0)
            if Widgets.button(self.ctx, tr:text(entry[1]), card_width, 35) then
                self.deposit = entry[2]; self.transfer_requested = true
            end
            ImGui.EndDisabled()
        end
        if self.transfer_requested then
            ImGui.OpenPopup('Account Transfer##ssv2_transfer'); self.transfer_requested = false
        end
        local _, draw = ImGui.BeginPopupModal('Account Transfer##ssv2_transfer', true, ImGuiWindowFlags.AlwaysAutoResize)
        if draw then
            self:transfer(self.deposit, true); ImGui.EndPopup()
        end
    end
    ImGui.EndChild(); ImGui.PopStyleColor()
end

function View:records(kind)
    local records = {}
    for _, record in ipairs(self.manager.records) do
        local show = kind == 'office' and record.kind == 'cargo'
            or kind == 'clubhouse' and (record.kind == 'factory' and record.index < 5 or record.key == 'clubhouse_safe')
            or kind == 'nightclub' and (record.kind == 'hub' or record.key == 'nightclub_safe')
            or kind == 'hangar' and record.kind == 'hangar'
            or kind == 'bunker' and record.key == 'factory_5'
            or kind == 'acid_lab' and record.key == 'factory_6'
            or kind == 'salvage' and record.key == 'salvage_safe'
            or kind == 'car_wash' and (record.kind == 'duffle' or record.kind == 'heat' or record.key == 'car_wash_safe')
            or kind == 'safes' and record.kind == 'safe'
        if show then records[#records + 1] = record end
    end
    return records
end

function View:settings()
    local tr, settings = self.ctx.translator, self.ctx.settings
    ImGui.BeginDisabled(self.manager.reloading or false)
    if Widgets.button(self.ctx, self.manager.reloading and Widgets.spinner(tr:text('GENERIC_WAIT_LABEL')) or tr:text('GENERIC_RELOAD'), ImGui.CalcTextSize(tr:text('GENERIC_WAIT_LABEL') .. ' ________') + ImGui.GetStyle().FramePadding.x * 2, 36) then
        self.manager:reload()
    end
    ImGui.EndDisabled(); if self.manager.reloading then return end
    Widgets.header(tr:text('YRV3_AUTO_SELL'), true)
    ImGui.TextWrapped(tr:text('YRV3_AUTO_SELL_SUPPORT_NOTICE'))
    for _, key in ipairs({ 'YRV3_AUTOSELL_BUNKER_LABEL', 'YRV3_AUTOSELL_HANGAR_LABEL', 'YRV3_AUTOSELL_CEO_LABEL', 'YRV3_AUTOSELL_BIKER_LABEL', 'YRV3_AUTOSELL_NC_CARGO_LABEL', 'YRV3_AUTOSELL_LSD_LAB_LABEL' }) do
        ImGui.BulletText(tr:text(key))
    end
    ImGui.Spacing()
    local enabled, changed = Widgets.toggle(self.ctx, tr:text('YRV3_AUTO_SELL'), settings:get('features.yrv3.autosell'))
    if changed then settings:set('features.yrv3.autosell', enabled) end
    if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and not settings:get('ui.disable_tooltips') then
        Widgets
            .tooltip(self.ctx, tr:text('YRV3_AUTOSELL_TT'))
    end
    local actions = self.manager.actions
    if scripts.is_active('fm_content_smuggler_sell') then
        ImGui.TextColored(1, 0, 0, 1, tr:text('YRV3_HANGAR_LAND_ERR'))
    else
        ImGui.BeginDisabled(not actions.sale or actions.sale_state == 'countdown' or actions.sale_state == 'requested')
        local label = (actions.sale_state == 'cancelled' or actions.sale_state == 'failed') and 'GENERIC_RETRY' or
            'YRV3_AUTO_SELL_MANUAL'
        if Widgets.button(self.ctx, tr:text(label)) then
            self.manager:run('finish business sale',
                function() actions:finish_sale() end)
        end
        ImGui.EndDisabled()
    end
    local names = require('includes.ssv2.data.business_definitions').ScriptDisplayNames
    ImGui.Text(tr:format('YRV3_AUTOSELL_CURRENT', names[actions.sale] or 'None'))
    Widgets.header(tr:text('YRV3_AUTO_FILL'), true)
    ImGui.Text(tr:text('YRV3_AUTO_FILL_DELAY'))
    local delay = settings:get('features.yrv3.autofill_delay')
    local unit = delay < 1000 and 1 or delay < 60000 and 1000 or 60000
    local unit_name = tr:text(unit == 1 and 'GENERIC_MILLIS_LABEL' or unit == 1000 and 'GENERIC_SECONDS_LABEL' or
        'GENERIC_MINUTES_LABEL')
    local step = delay < 1000 and 100 or delay < 10000 and 500 or delay < 60000 and 1000 or 10000
    local value, changed = Widgets.input_float(self.ctx, '##autofill_delay', delay / unit, step / unit, step * 5 / unit,
        string.format('%.1f %s', delay / unit, unit_name))
    if changed then settings:set('features.yrv3.autofill_delay', value * unit) end
end

function View:location(record, keep_vehicle)
    local tr, manager = self.ctx.translator, self.manager
    if record.coords then
        if Widgets.button(self.ctx, tr:text('GENERIC_TELEPORT')) then
            manager:run('business teleport', function()
                Game.teleport(self.ctx, record.coords, keep_vehicle)
            end)
        end
        ImGui.SameLine()
        if Widgets.button(self.ctx, tr:text('GENERIC_SET_WAYPOINT')) then
            manager:run('business waypoint',
                function() HUD.SET_NEW_WAYPOINT(record.coords.x, record.coords.y) end)
        end
    end
end

function View:progress(label, value, maximum, format)
    ImGui.Text(self.ctx.translator:text(label))
    ImGui.SameLine()
    ImGui.ProgressBar(maximum > 0 and value / maximum or 0, -1, 25, format)
end

function View:record(record)
    local snapshot = record.snapshot or {}
    local tr, manager = self.ctx.translator, self.manager
    if record.kind == 'factory' and snapshot.setup == false then
        ImGui.Text(tr:text('YRV3_GENERIC_NOT_SETUP')); return
    end
    local count, capacity = snapshot.count or 0, snapshot.capacity or 0
    local full = count >= capacity
    local height = record.kind == 'factory' and (record.index < 6 and 400 or 370)
        or record.kind == 'safe' and (record.paytime_stat and 230 or 195)
        or (record.kind == 'cargo' or record.kind == 'hangar') and 240 or 280
    ImGui.PushID(record.key)
    if ImGui.BeginChild('##business_record', 0, height, false, bit.bor(ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.AlwaysUseWindowPadding)) then
        ImGui.SeparatorText(record.name or record.key)
        self:location(record); ImGui.Separator(); ImGui.Spacing()
        if record.kind == 'factory' then
            local spacing = 0
            for _, key in ipairs({ 'YRV3_EQUIP_UPGDRADE', 'YRV3_STAFF_UPGDRADE', 'YRV3_SUPPLIES_LABEL', 'YRV3_STOCK_LABEL', 'YRV3_VALUE_TOTAL' }) do
                spacing =
                    math.max(spacing, ImGui.CalcTextSize(tr:text(key)) + 60)
            end
            for _, upgrade in ipairs({ { 'YRV3_EQUIP_UPGDRADE', record.equipment }, { 'YRV3_STAFF_UPGDRADE', record.staff } }) do
                if upgrade[1] ~= 'YRV3_STAFF_UPGDRADE' or record.index < 6 then
                    ImGui.BulletText(tr:text(upgrade[1])); ImGui.SameLine(spacing)
                    ImGui.TextColored(upgrade[2] and 0 or 1, upgrade[2] and 1 or 0, 0, 1,
                        tr:text(upgrade[2] and 'GENERIC_ACTIVE' or 'GENERIC_INACTIVE'))
                end
            end
            ImGui.BulletText(tr:text('YRV3_SUPPLIES_LABEL')); ImGui.SameLine(spacing); ImGui.ProgressBar(
                (snapshot.supplies or 0) / 100, -1, 25)
            ImGui.BulletText(tr:text('YRV3_STOCK_LABEL')); ImGui.SameLine(spacing); ImGui.ProgressBar(
                capacity > 0 and count / capacity or 0, -1, 25)
            ImGui.BulletText(tr:text('YRV3_VALUE_TOTAL')); ImGui.SameLine(spacing); ImGui.TextColored(0.5216, 0.7333,
                0.3961, 1, money(snapshot.value)); ImGui.Spacing()
            ImGui.BeginDisabled((snapshot.supplies or 0) >= 100)
            if Widgets.button(self.ctx, tr:text('YRV3_FILL_SUPPLIES')) then
                manager:run('restock factory',
                    function() record:restock() end)
            end
            ImGui.EndDisabled()
            ImGui.BeginDisabled(not self.ctx.settings:get('features.unsafe_feats_enabled'))
            ImGui.BeginDisabled(record.auto or full or (snapshot.supplies or 0) < 25)
            ImGui.PushButtonRepeat(true)
            if Widgets.button(self.ctx, tr:text('YRV3_TRIGGER_PROD'), 0, 0, true) then
                manager:run(
                    'trigger factory production', function() record:produce() end)
            end
            ImGui.PopButtonRepeat(); ImGui.EndDisabled()
            if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and not self.ctx.settings:get('ui.disable_tooltips') then
                Widgets.tooltip(self.ctx, tr:text('YRV3_TRIGGER_PROD_TT'))
            end
            ImGui.BeginDisabled(full)
            record.auto = Widgets.toggle(self.ctx, tr:text('YRV3_AUTO_PROD'), record.auto)
            if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and not self.ctx.settings:get('ui.disable_tooltips') then
                Widgets.tooltip(self.ctx, tr:text('YRV3_AUTO_PROD_TT'))
            end
            ImGui.EndDisabled(); ImGui.EndDisabled()
        elseif record.kind == 'cargo' or record.kind == 'hangar' then
            local spacing = math.max(ImGui.CalcTextSize(tr:text('YRV3_CARGO_AMT')),
                ImGui.CalcTextSize(tr:text('YRV3_VALUE_TOTAL'))) + 60
            ImGui.BulletText(tr:text('YRV3_CARGO_AMT')); ImGui.SameLine(spacing)
            ImGui.ProgressBar(capacity > 0 and count / capacity or 0, -1, 25,
                string.format('%d %s (%d%%)', count, tr:text('YRV3_CRATES_LABEL'),
                    capacity > 0 and math.floor(count / capacity * 100) or 0))
            ImGui.BulletText(tr:text('YRV3_VALUE_TOTAL')); ImGui.SameLine(spacing); ImGui.TextColored(0.5216, 0.7333,
                0.3961, 1, money(snapshot.value)); ImGui.Spacing()
            ImGui.BeginDisabled(full)
            ImGui.BeginDisabled(record.auto)
            if Widgets.button(self.ctx, tr:text('YRV3_RANDOM_CRATES')) then
                manager:run('request cargo sourcing',
                    function() record:restock() end)
            end
            ImGui.EndDisabled(); ImGui.SameLine()
            record.auto = Widgets.toggle(self.ctx, tr:text('YRV3_AUTO_FILL'), record.auto)
            ImGui.EndDisabled()
        elseif record.kind == 'safe' then
            ImGui.BulletText(tr:text('YRV3_CASH_SAFE') .. ': '); ImGui.SameLine()
            ImGui.ProgressBar(capacity > 0 and count / capacity or 0, -1, 25, money(count))
            ImGui.BeginDisabled(not self.ctx.settings:get('features.unsafe_feats_enabled'))
            if record.global_offset or record.car_wash then
                ImGui.BeginDisabled(count == capacity)
                if Widgets.button(self.ctx, tr:text('YRV3_CASH_FILL')) then
                    manager:run('fill safe',
                        function() record:fill_safe() end)
                end
                ImGui.EndDisabled(); Widgets.help(self.ctx, tr:text('YRV3_CASH_FILL_TT'))
            end
            ImGui.BeginDisabled(full)
            if record.paytime_stat then record.loop = Widgets.toggle(self.ctx, tr:text('YRV3_CASH_LOOP'), record.loop) end
            ImGui.EndDisabled(); ImGui.EndDisabled()
        elseif record.kind == 'hub' then
            self:progress('YRV3_STOCK_LABEL', count, capacity, tostring(count) .. ' / ' .. capacity)
            self:kv('YRV3_VALUE_TOTAL', money(snapshot.value), true)
            local names = { 'None', 'Technician 1', 'Technician 2', 'Technician 3', 'Technician 4', 'Technician 5' }
            local selected, changed = ImGui.Combo('Technician', (snapshot.technician or -1) + 1, names, #names)
            if changed then manager:run('assign nightclub technician', function() record:assign(selected - 1) end) end
            ImGui.BeginDisabled(not self.ctx.settings:get('features.unsafe_feats_enabled') or full or
                (snapshot.technician or -1) < 0)
            if Widgets.button(self.ctx, tr:text('YRV3_TRIGGER_PROD'), 0, 0, true) then
                manager:run(
                    'nightclub production', function() record:produce() end)
            end
            record.auto = Widgets.toggle(self.ctx, tr:text('YRV3_AUTO_PROD'), record.auto)
            if Widgets.button(self.ctx, 'Fill production') then
                manager:run('fill nightclub production',
                    function() record:produce(capacity) end)
            end
            ImGui.EndDisabled()
        elseif record.kind == 'duffle' then
            self:progress('YRV3_CWASH_WORK_EARNINGS', count, capacity, money(count))
            self:kv('YRV3_CWASH_CASH_CLEAN', money(snapshot.clean))
            self:kv('YRV3_CWASH_CASH_DIRTY', money(snapshot.pending))
            if Widgets.button(self.ctx, 'Clean pending cash') then
                manager:run('clean duffle cash',
                    function() stats.set_int('MPX_CAR_WASH_DUFFEL_POSIX', os.time() + 1000) end)
            end
        elseif record.heat then
            self:progress('YRV3_CWASH_HEAT', snapshot.heat or 0, 100)
            ImGui.BeginDisabled((snapshot.heat or 0) == 0)
            if Widgets.button(self.ctx, 'Clear heat') then
                manager:run('clear business heat',
                    function() stats.set_packed_int(record.heat, 0) end)
            end
            ImGui.EndDisabled()
        end
    end
    ImGui.EndChild(); ImGui.PopID()
end

function View:draw()
    local ctx, manager = self.ctx, self.manager
    ImGui.SetNextWindowBgAlpha(0.85)
    if ImGui.BeginChild('##yrv3_header', 0, 100, true) then
        ImGui.SetWindowFontScale(1.12)
        local title = ctx.translator:text('YRV3_HEADER_TITLE', 'Quick Actions')
        local width = ImGui.GetContentRegionAvail()
        ImGui.SetCursorPosX(ImGui.GetCursorPosX() + math.max(0, (width - ImGui.CalcTextSize(title)) * 0.5))
        ImGui.Text(title)
        ImGui.SetWindowFontScale(1)
        ImGui.BeginDisabled(self.selected == 1)
        if Widgets.button(self.ctx, ctx.translator:text('YRV3_DASHBOARD_MANAGE_FUNDS', 'Manage Funds')) then
            ImGui
                .OpenPopup('Manage Funds##ssv2_funds')
        end
        ImGui.SameLine(); self:boss(); ImGui.EndDisabled()
        self:funds_popup(); ImGui.SameLine()
        if Widgets.button(self.ctx, ctx.translator:text('YRV3_MCT_TITLE')) then
            manager:run('Master Control Terminal', function()
                if manager.actions.sale then
                    ctx.notifier:info('Business Manager', ctx.translator:text('YRV3_MCT_UNAVAIL'))
                else
                    manager.actions:start_mct(); ctx.view:close(true)
                end
            end)
        end
    end
    ImGui.EndChild(); ImGui.Spacing()
    local sidebar = math.max(100, ImGui.GetWindowWidth() * 0.2)
    local height = math.max(400, ctx.settings:get('ui.height') - 160)
    if ImGui.BeginChild('##business_sidebar', sidebar, height, false) then
        for index, page in ipairs(pages) do
            if Widgets.navigation(ctx, '##business_page_' .. index, ctx.translator:text(page[1]), self.selected == index, sidebar - 10, 27, false, true) then
                self.selected =
                    index
            end
        end
    end
    ImGui.EndChild(); Widgets.vertical_separator(3)
    if ImGui.BeginChild('##business_content', 0, height, false) then
        local kind = pages[self.selected][2]
        if kind == 'dashboard' then
            self:dashboard()
        elseif kind == 'settings' then
            self:settings()
        elseif kind == 'misc' then
            self.panels = self.panels or require('includes.ssv2.core.business_panels').new(self)
            self.panels:misc()
            manager.actions:draw()
        else
            self.panels = self.panels or require('includes.ssv2.core.business_panels').new(self)
            self.panels:draw(kind)
        end
    end
    ImGui.EndChild()
end

return View
