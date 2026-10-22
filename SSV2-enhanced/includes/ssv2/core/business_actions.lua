local Managed = require('includes.ssv2.core.managed_value')
local definitions = require('includes.ssv2.data.business_definitions')
local Widgets = require('includes.ssv2.core.widgets')
local Actions = {}; Actions.__index = Actions
local sales = { 'gb_smuggler', 'gb_gunrunning', 'gb_contraband_sell', 'gb_biker_contraband_sell', 'business_battles_sell' }
function Actions.new(ctx, manager)
    return setmetatable({ ctx = ctx, manager = manager, leases = {}, sale_state = 'idle', next_scan = 0, mission_choices = {} },
        Actions)
end

function Actions:cleanup()
    for _, value in pairs(self.leases) do value:clear() end
    self.leases = {}; self.sale_state = 'idle'; self.mct_requested = false
end

function Actions:lease(key, definition, enabled)
    local value = self.leases[key]
    if enabled then
        if not value then
            value = Managed.new(self.ctx, definition); self.leases[key] = value
        end
        value:set_desired(definition.v)
        value:apply()
    elseif value then
        value:clear(); self.leases[key] = nil
    end
end

function Actions:finish_sale()
    local data = self.ctx.script_data
    local script_name = self.sale
    if not script_name then return false end
    if not data:host(script_name) then
        self.sale_state = 'failed'; self.ctx.notifier:error('Business Manager', 'Local player must host the sale script'); return false
    end
    if script_name == 'gb_smuggler' then
        data:write_local('gb_smuggler_sell_air_local_1', 0, { data:offset('gb_smuggler_sell_air_local_1', 1) })
        data:write_local('gb_smuggler_sell_air_local_1', 1, { data:offset('gb_smuggler_sell_air_local_2', 1) })
    elseif script_name == 'gb_gunrunning' then
        data:write_local('gb_gunrunning_sell_local', 1, { data:offset('bunker_sell_amt_delivered', 1) })
        data:write_local('gb_gunrunning_sell_local', 0, { data:offset('bunker_sell_num_vehs', 1) })
    elseif script_name == 'gb_contraband_sell' then
        data:write_local('gb_contraband_sell_local', 99999, { 1 })
    elseif script_name == 'gb_biker_contraband_sell' then
        local target = data:read_local('biker_deliveries_local', { data:offset('biker_required_deliveries_local', 1) })
        if target then data:write_local('biker_deliveries_local', target, { data:offset('biker_deliveries_local', 1) }) end
    elseif script_name == 'business_battles_sell' then
        local value = data:local_value('bb_sell_local')
        if not value then return false end
        value:at(data:offset('bb_sell_local', 2)):set_int(value:at(data:offset('bb_sell_local', 1)):get_int())
        local vehicle = value:at(data:value('bb_sell_vehicle_array_offset')):at(0, 42)
        vehicle:at(29):set_int(vehicle:at(30):get_int())
        local state = value:at(data:value('bb_sell_mission_state_offset'))
        state:at(1):set_int(4); state:set_int(30)
    end
    self.sale_state = 'requested'; return true
end

function Actions:finish_source()
    local data = self.ctx.script_data
    if scripts.is_active('gb_contraband_buy') then
        assert(data:host('gb_contraband_buy'), 'Local player must host the source mission')
        for offset, value in pairs({ [5] = 1, [191] = 6, [192] = 4 }) do
            data:write_local('gb_contraband_buy_local_1',
                value, { offset })
        end
    elseif scripts.is_active('fm_content_cargo') then
        assert(data:host('fm_content_cargo'), 'Local player must host the source mission')
        data:write_local_bits('gb_contraband_buy_local_2', { 11 }, true, { 1, 0 })
        data:write_local('gb_contraband_buy_local_3', 3, { data:offset('gb_contraband_buy_local_3', 1) })
    end
end

function Actions:start_mct()
    for _, name in ipairs(require('includes.ssv2.data.app_scripts')) do if scripts.is_active(name) then return end end
    self.mct_requested = true; self.mct_deadline = util.time() + 10000
end

function Actions:set_mission_choice(category, name, enabled)
    local info = definitions.SellMissionTunables[category]
    assert(info, 'Unknown sale category')
    local desired
    if info.type == 'bool' then desired = enabled else desired = enabled and 0 or 1 end
    self:lease('sale:' .. name, { t = name, kind = 'tunable', type = info.type, v = desired }, enabled)
    self.mission_choices[name] = enabled or nil
end

function Actions:easy_missions(category)
    local info = assert(definitions.SellMissionTunables[category], 'Unknown sale category')
    local floating = info.type == 'float'
    local get = floating and tunables.get_float or tunables.get_int
    local set = floating and tunables.set_float or tunables.set_int
    local desired = floating and 0 or 1
    for _, name in ipairs(info.tuneables) do if get(name) ~= desired then set(name, desired) end end
    -- These source buttons write tunables directly. They do not create restorable leases.
    self.ctx.notifier:success('Business Manager', self.ctx.translator:format('YRV3_SELL_MISSIONS_NOTIF', category))
end

function Actions:update(state, now)
    local data = self.ctx.script_data
    if now >= self.next_scan then
        local current
        for _, name in ipairs(sales) do
            if scripts.is_active(name) then
                current = name; break
            end
        end
        if current ~= self.sale then
            self.sale = current; self.sale_state = 'idle'; self.sale_due = nil
        end
        self.next_scan = now + 1200
    end
    if self.sale and self.ctx.settings:get('features.yrv3.autosell') and self.sale_state == 'idle'
        and not CAMERA.IS_SCREEN_FADED_OUT() and not CAMERA.IS_SCREEN_FADING_OUT() then
        self.sale_state = 'countdown'; self.sale_due = now + 20000
        local serial, sale = self.manager.serial, self.sale
        self.ctx.notifier:info('Business Manager', self.ctx.translator:text('YRV3_AUTO_SELL_COUNTDOWN'), 20, function()
            if self.manager.serial == serial and self.sale == sale and self.sale_state == 'countdown' then
                self.sale_state = 'cancelled'
                self.ctx.notifier:info('Business Manager', self.ctx.translator:text('YRV3_AUTO_SELL_CANCELED_MSG'))
            end
        end)
    end
    if self.sale_state == 'countdown' then
        if not self.ctx.settings:get('features.yrv3.autosell') or not scripts.is_active(self.sale) then
            self.sale_state = 'cancelled'; self.ctx.notifier:info('Business Manager',
                self.ctx.translator:text('YRV3_AUTO_SELL_CANCELED_MSG'))
        elseif now >= self.sale_due and not AUDIO.IS_MOBILE_PHONE_CALL_ONGOING() then
            self:finish_sale()
        end
    end
    if self.mct_requested then
        if now > self.mct_deadline then
            self.mct_requested = false; error('Master Control Terminal script timed out')
        end
        SCRIPT.REQUEST_SCRIPT('appArcadeBusinessHub')
        if SCRIPT.HAS_SCRIPT_LOADED('appArcadeBusinessHub') then
            local one = data:global('arcade_bhub_global_1'); if one then one:set_int(0) end
            self.mct_thread = BUILTIN.START_NEW_SCRIPT('appArcadeBusinessHub', 1424)
            SCRIPT.SET_SCRIPT_AS_NO_LONGER_NEEDED('appArcadeBusinessHub'); self.mct_requested = false
        end
    end
    if self.mct_thread and scripts.is_active('appArcadeBusinessHub') then
        local two = data:global('arcade_bhub_global_2'); if two and two:get_int() == -1 then two:set_int(0) end
        if self.sale then
            local one = data:global('arcade_bhub_global_1'); if one then one:set_int(0) end
            self.mct_thread = nil
        end
    elseif self.mct_thread then
        local one = data:global('arcade_bhub_global_1'); if one then one:set_int(0) end
        self.mct_thread = nil
    end
    if self.manager.fronts.nightclub then
        local enabled = self.ctx.settings:get('features.yrv3.nc_always_popular')
        for _, name in ipairs({ 'NIGHTCLUBPOPDECAY', 'INIGHTCLUBPOPDECAYSTAFFUPGRADE' }) do
            self:lease(name,
                { kind = 'tunable', type = 'float', t = name, v = -1e-16 }, enabled)
        end
        if enabled and stats.get_int('MPX_CLUB_POPULARITY') < 1000 then stats.set_int('MPX_CLUB_POPULARITY', 1000) end
    end
    if self.manager.fronts.salvage then
        local enabled = self.ctx.settings:get('features.yrv3.sy_always_max_income')
        self:lease('salvage_income', { kind = 'tunable', type = 'int', t = 797544186, v = 0 }, enabled)
        if enabled and stats.get_packed_int(51051) < 100 then stats.set_packed_int(51051, 100) end
    end
end

function Actions:draw()
    ImGui.SeparatorText(self.ctx.translator:text('YRV3_SELL_MISSIONS_LABEL'))
    ImGui.TextWrapped(self.ctx.translator:text('YRV3_SELL_MISSIONS_TT'))
    local width = self.mission_button_width or 80
    for category in pairs(definitions.SellMissionTunables) do
        width = math.max(width,
            ImGui.CalcTextSize('Easy ' .. category .. ' Missions') + ImGui.GetStyle().FramePadding.x * 2)
    end
    self.mission_button_width = width
    for category in pairs(definitions.SellMissionTunables) do
        if Widgets.button(self.ctx, 'Easy ' .. category .. ' Missions', width, 30) then
            self.manager:run(
                'easy sale missions', function() self:easy_missions(category) end)
        end
        require('includes.ssv2.core.widgets').same_line_if_available(width + ImGui.GetStyle().ItemSpacing.x)
    end
    ImGui.Dummy(0, 0); ImGui.Spacing()
    ImGui.PushStyleColor(ImGuiCol.Text, 240 / 255, 190 / 255, 2 / 255, 1)
    ImGui.TextWrapped(self.ctx.translator:text('YRV3_SELL_MISSIONS_NOTE')); ImGui.PopStyleColor()
end

return Actions
