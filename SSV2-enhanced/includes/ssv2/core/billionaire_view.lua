-- Original Billionaire Services frontend, expressed with V2 widgets and services.
-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors. GPL-3.0-or-later.
local Widgets = require('includes.ssv2.core.widgets')
local Browser = require('includes.ssv2.core.model_browser')
local Weapons = require('includes.ssv2.core.weapon_browser')
local Data = require('includes.ssv2.data.billionaire_definitions')
local Radio = require('includes.ssv2.data.radio_stations')
local vehicle_status = { idle = 'Idle.', ['goto'] = 'Going to destination.', wander = 'Cruising around.', takeoff = 'Taking off.', land = 'Landing at destination.', hover = 'Hovering.', home = 'Going home.', dismissed = 'Going home.' }
local guard_status = {
    none = 'Idle.',
    follow = 'Following player.',
    vehicle_follow = "Escorting player's vehicle.",
    jack = 'Jacking a vehicle.',
    enter_vehicle = 'Entering a vehicle.',
    leave_vehicle = 'Leaving a vehicle.',
    combat = 'Engaging in combat.',
    stand_guard = 'Securing a perimeter.',
    wander = 'Wandering.',
    sitting = 'Sitting in a vehicle.',
    dismissed = 'Going home.',
    parachute = 'Parachuting.',
    rappel = 'Rappelling from helicopter.'
}
local View = {}; View.__index = View
local function copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}; for key, item in pairs(value) do result[key] = copy(item) end; return result
end
function View.new(ctx, f)
    return setmetatable({
        ctx = ctx,
        f = f,
        page = 1,
        guard_name = '',
        group_search = '',
        new_name = '',
        member_name = '',
        stage = 1,
        new_members = {},
        new_vehicle = 0,
        guard_browser = f.model_browser,
        member_browser = Browser.new(ctx, { fixed_kind = 1, humans_only = true, max_entries = 100, gender_filter = false, type_filter = false }),
        guard_weapons = Weapons.new(ctx),
        member_weapons = Weapons.new(ctx),
        heli_index = 0,
        jet_index = 0,
        airport_index = 0,
        destination = 0,
        properties = {}
    }, View)
end

function View:text(key, ...)
    if select('#', ...) > 0 then return self.ctx.translator:format(key, ...) end; return self.ctx.translator:text(key)
end

function View:button(key, callback, disabled, width, height)
    ImGui.BeginDisabled(not not disabled)
    if Widgets.button(self.ctx, self:text(key), width or 0, height or 0) and not disabled then self.f:run(key, callback) end
    ImGui.EndDisabled()
end

function View:ui_button(key, callback, disabled, width, height)
    ImGui.BeginDisabled(not not disabled)
    if Widgets.button(self.ctx, self:text(key), width or 0, height or 0) and not disabled then callback() end
    ImGui.EndDisabled()
end

function View:help(key) if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and not self.ctx.settings:get('ui.disable_tooltips') then Widgets.tooltip(self.ctx, self:text(key)) end end

function View:update(state)
    self.guard_weapons:load(); self.member_weapons:load()
    if util.time() < (self.next_properties or 0) then return end
    self.next_properties = util.time() + 3000; self.properties = {}
    local manager = self.ctx.features.businesses
    if manager and manager.active then
        local seen = {}
        local function add(name, pos)
            if pos then
                local id = name .. ':' .. pos.x .. ':' .. pos.y; if not seen[id] then
                    seen[id] = true; self.properties[#self.properties + 1] = { name = name, coords = pos }
                end
            end
        end
        for _, front in pairs(manager.fronts) do add(front.name, front.coords) end
        for _, record in ipairs(manager.records) do add(record.name, record.coords) end
    end
    self.new_vehicle_names = {}
    for index, hash in ipairs(Data.NewGroupVehicles) do self.new_vehicle_names[index] = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(hash)) end
end

function View:property_popup(target)
    local _, draw = ImGui.BeginPopupModal('##service_property', true, ImGuiWindowFlags.AlwaysAutoResize)
    if not draw then return end
    if not self.ctx.online then
        ImGui.Text(self:text('GENERIC_UNAVAILABLE_SP'))
    else
        ImGui.SetNextItemWidth(420); self.property_search = Widgets.input_text_with_hint(self.ctx, '##propertySearch', self:text('GENERIC_SEARCH_HINT'), self.property_search or '')
        if ImGui.BeginListBox('##propertybrowser', 420, math.min(400, #self.properties * ImGui.GetTextLineHeight())) then
            for _, item in ipairs(self.properties) do
                if item.name:lower():find(self.property_search:lower(), 1, true) then
                    ImGui.Selectable(item.name, false)
                    if ImGui.IsItemClicked(0) then
                        local pos = item.coords
                        self.f:run('service property destination', function()
                            HUD.SET_NEW_WAYPOINT(pos.x, pos.y)
                            if target.kind == 'limo' then self.f.vehicles:drive(target, pos, false) else self.f.escorts:drive(target, pos, false) end
                        end)
                        ImGui.CloseCurrentPopup()
                    end
                end
            end
            ImGui.EndListBox()
        end
    end
    ImGui.Separator(); ImGui.Spacing(); ImGui.TextWrapped(self:text('BSV2_ES_DRIVE_PROPERTY_TEXT'))
    if Widgets.button(self.ctx, self:text('GENERIC_CANCEL')) then ImGui.CloseCurrentPopup() end
    ImGui.EndPopup()
end

function View:bodyguards()
    local f = self.f
    if ImGui.BeginTabBar('##bodyguardsUI') then
        if ImGui.BeginTabItem(self:text('GENERIC_SPAWN')) then
            self.guard_model = self.guard_browser:draw(self.ctx.preview, { x = 0, y = 0 }); self.footer = 'guard_spawn'; ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(self:text('BSV2_BG_SPAWNED_TAB')) then
            local count = 0
            if ImGui.BeginListBox('##guardlist', -1, -1) then
                for _, guard in pairs(f.guards.members) do
                    if guard.role == 'bodyguard' then
                        count = count + 1; ImGui.PushID(guard.handle); ImGui.Selectable(guard.display_name or guard.name, self.guard == guard)
                        if ImGui.IsItemClicked(0) then
                            self.guard = guard; ImGui.SetItemDefaultFocus()
                        end
                        if ImGui.IsItemClicked(1) then
                            self.guard = guard; ImGui.OpenPopup('bodyguard_options')
                        end
                        self:help('GENERIC_RIGHT_CLICK_TT')
                        if ImGui.BeginPopup('bodyguard_options') then
                            ImGui.BeginDisabled(guard.dismissed or false)
                            for _, entry in ipairs({ { 'GENERIC_BRING', 'bring' }, { 'GENERIC_WARP_INTO_VEH', 'warp' }, { 'GENERIC_KILL', 'kill' }, { 'GENERIC_DISMISS', 'dismiss' } }) do
                                if ImGui.MenuItem(self:text(entry[1])) then
                                    local action = entry[2]; f:run('bodyguard option', function()
                                        if action == 'bring' then
                                            f.guards:bring(guard, true)
                                        elseif action == 'warp' then
                                            local state = self.ctx.state:read(); if state and state.vehicle then TASK.TASK_WARP_PED_INTO_VEHICLE(guard.handle, state.vehicle_handle, -2) else self.ctx.notifier:error('Billionaire Services', self:text('GENERIC_NOT_IN_VEH')) end
                                        elseif action == 'kill' then
                                            ENTITY.SET_ENTITY_HEALTH(guard.handle, 0, 0, 0)
                                        else
                                            f.guards:dismiss(guard)
                                        end
                                    end)
                                end
                            end
                            ImGui.EndDisabled(); ImGui.EndPopup()
                        end
                        ImGui.PopID()
                    end
                end
                if count == 0 then ImGui.Text(self:text('BSV2_BG_SPAWNED_NONE')) end
                ImGui.EndListBox()
            end
            self.footer = 'guard_spawned'; ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
end

function View:guard_footer()
    local f = self.f
    if self.footer == 'guard_spawn' then
        if ImGui.BeginChild('##bgFooter', 0, 280, false) then
            ImGui.SeparatorText(self:text('GENERIC_PREFERENCES_LABEL')); ImGui.BeginDisabled(not self.guard_model)
            f.guard_godmode = Widgets.toggle(self.ctx, self:text('GENERIC_INVINCIBLE'), f.guard_godmode); ImGui.SameLine()
            f.guard_no_ragdoll = Widgets.toggle(self.ctx, self:text('GENERIC_NORAGDOLL'), f.guard_no_ragdoll)
            ImGui.SetNextItemWidth(280); local name = Widgets.input_text_with_hint(self.ctx, '##bgname', self:text('GENERIC_NAME'), self.guard_name)
            self.guard_name = Widgets.validated_text(self.guard_name, name, 128); ImGui.SameLine()
            self:ui_button('GENERIC_RANDOM', function() self.guard_name = f:random_name(self.guard_model.metadata.ped_gender) end, not self.guard_model)
            ImGui.SeparatorText(self:text('BSV2_WEAPONS_LABEL')); f.guard_all_weapons = Widgets.toggle(self.ctx, self:text('BSV2_GIVE_ALL_WEAPONS'), f.guard_all_weapons)
            local weapon = f.guard_all_weapons or self.guard_weapons:draw()
            ImGui.Separator()
            self:ui_button('BSV2_CALL', function()
                local model, name, godmode, ragdoll = self.guard_model, self.guard_name, f.guard_godmode, f.guard_no_ragdoll
                f:run('spawn bodyguard', function(valid) f.guards:spawn(model.model, name ~= '' and name or f:random_name(model.metadata.ped_gender), nil, weapon, godmode, ragdoll, valid) end)
                self.guard_name = ''
            end, not self.guard_model, 80, 35)
            ImGui.EndDisabled()
        end
        ImGui.EndChild()
    elseif self.guard and f.guards.members[self.guard.handle] then
        local guard = self.guard; local count = 0; for _, member in pairs(f.guards.members) do if member.role == 'bodyguard' then count = count + 1 end end
        ImGui.Dummy(1, 10)
        if ImGui.BeginChild('##SpawnedBgFooter', 0, 140, false) then
            ImGui.SetWindowFontScale(1.12); ImGui.SeparatorText(guard.display_name or guard.name); ImGui.SetWindowFontScale(1); ImGui.BulletText('Status: ' .. (guard_status[guard.task] or guard.override_description or 'Running a custom task.'))
            self:button('GENERIC_DISMISS', function() f.guards:dismiss(guard) end, guard.dismissed, 80, 35); ImGui.SameLine()
            self:button('GENERIC_DISMISS_ALL', function() for _, member in pairs(f.guards.members) do if member.role == 'bodyguard' then f.guards:dismiss(member) end end end, count <= 1)
        end
        ImGui.EndChild()
    end
end

function View:radio(entry)
    ImGui.Spacing(); ImGui.SeparatorText(self:text('BSV2_RADIO_CTRL')); ImGui.Spacing()
    self:button(entry.radio == 'OFF' and 'GENERIC_TURN_ON' or 'GENERIC_TURN_OFF', function()
        local station = entry.radio == 'OFF' and 'RADIO_22_DLC_BATTLE_MIX1_RADIO' or 'OFF'
        AUDIO.SET_VEH_RADIO_STATION(entry.vehicle.handle, station); entry.radio = station
    end)
    if entry.radio ~= 'OFF' then
        ImGui.SameLine()
        if ImGui.BeginCombo('##service_radio', entry.radio_name or entry.radio) then
            for _, station in ipairs(Radio) do
                ImGui.Selectable(station.name, entry.radio == station.station); if ImGui.IsItemClicked(0) then self.f:run('service radio', function()
                        AUDIO.SET_VEH_RADIO_STATION(entry.vehicle.handle, station.station); entry.radio = station.station; entry.radio_name = station.name
                    end) end
            end
            ImGui.EndCombo()
        end
        ImGui.SetWindowFontScale(0.8); ImGui.BulletText('Now Playing: ' .. (entry.radio_name or entry.radio)); ImGui.SetWindowFontScale(1)
    end
end

function View:seats(entry)
    ImGui.Spacing(); ImGui.SeparatorText(self:text('BSV2_SEAT_CTRL')); ImGui.Spacing()
    self:button('< ' .. self:text('BSV2_SEAT_CTRL_PREV'), function() self.f.vehicles:shuffle(entry, -1) end, false, 180, 35); ImGui.SameLine()
    self:button(self:text('BSV2_SEAT_CTRL_NEXT') .. ' >', function() self.f.vehicles:shuffle(entry, 1) end, false, 180, 35)
end

function View:marker_destination(entry, objective)
    local pos = objective and self.ctx.game.objective() or self.ctx.game.waypoint()
    if not pos then
        self.ctx.notifier:error('Billionaire Services', self:text('GENERIC_TP_INVALID_COORDS_ERR')); return
    end
    if entry.kind == 'limo' then self.f.vehicles:drive(entry, pos, false) else self.f.vehicles:fly(entry, pos, nil, false) end
end

function View:limo()
    local f, entry = self.f, self.f.vehicles.active.limo
    if not entry then
        ImGui.SeparatorText(self:text('BSV2_LIMO_MODELS_AVAIL')); ImGui.Spacing()
        local width = 0; for name in pairs(Data.DefaultLimousines) do width = math.max(width, ImGui.CalcTextSize(name)) end
        width = math.min(width * 1.8, ImGui.GetContentRegionAvail() * 0.47)
        for name, preset in pairs(Data.DefaultLimousines) do
            ImGui.PushID(name)
            if ImGui.BeginChild(name, width, 200, true, ImGuiWindowFlags.NoScrollbar) then
                ImGui.SeparatorText(name)
                if ImGui.BeginChild('scrollRegion', 0, 97, false) then
                    ImGui.SetWindowFontScale(0.84); ImGui.TextWrapped(preset.description or ''); ImGui.SetWindowFontScale(1)
                end
                ImGui.EndChild()
                self:ui_button('BSV2_DISPATCH', function() f:call('limo', preset.model, preset, true) end, f.pending.limo, -1, 36)
            end
            ImGui.EndChild(); ImGui.PopID(); Widgets.same_line_if_available(width)
        end
        return
    end
    self.footer = entry
    if not entry.in_vehicle and not entry.remote then
        self:button('GENERIC_WARP_INTO_VEH', function() f.vehicles:warp(entry) end, entry.busy, 180, 35); ImGui.Text(self:text('BSV2_LIMO_MORE_OPTS_TT')); return
    end
    ImGui.BeginDisabled(entry.remote ~= nil)
    ImGui.Spacing(); ImGui.SeparatorText(self:text('GENERIC_DRIVING_STYLE')); ImGui.Spacing()
    local mode, changed = ImGui.RadioButton(self:text('GENERIC_DRIVING_STYLE_NORMAL'), entry.mode, 0)
    if changed then f:run('normal limo driving', function()
            entry.mode = mode; if entry.task == 'goto' or entry.task == 'wander' then f.vehicles:drive(entry, entry.destination, entry.task == 'wander') end
        end) end
    ImGui.SameLine(); mode, changed = ImGui.RadioButton(self:text('GENERIC_DRIVING_STYLE_AGGRO'), entry.mode, 1)
    if changed then f:run('aggressive limo driving', function()
            entry.mode = mode; if entry.task == 'goto' or entry.task == 'wander' then f.vehicles:drive(entry, entry.destination, entry.task == 'wander') end
        end) end
    ImGui.Spacing(); ImGui.SeparatorText(self:text('GENERIC_COMMANDS')); ImGui.Spacing()
    ImGui.EndDisabled()
    self:button(entry.remote and 'BSV2_LIMO_GIVE_CTRL' or 'BSV2_LIMO_TAKE_CTRL', function()
        local remote = require('includes.ssv2.core.limo_remote'); if entry.remote then remote.release(f.vehicles, entry, true) else remote.take(f.vehicles, entry) end
    end, entry.busy, 370, 35)
    self:help(entry.remote and 'BSV2_LIMO_GIVE_CTRL_TT' or 'BSV2_LIMO_TAKE_CTRL_TT')
    ImGui.BeginDisabled(entry.remote ~= nil)
    self:button('GENERIC_STOP', function() f.vehicles:cancel(entry) end, entry.speed and entry.speed <= 0.1 and entry.task == 'idle', 180, 35); ImGui.SameLine()
    self:button('GENERIC_EMERGENCY_STOP', function()
        f.vehicles:cancel(entry); VEHICLE.SET_VEHICLE_FORWARD_SPEED(entry.vehicle.handle, 0)
    end, false, 180, 35)
    self:button('BSV2_ES_DRIVE_WP', function() self:marker_destination(entry, false) end, false, 180, 35); ImGui.SameLine()
    self:button('BSV2_ES_DRIVE_OBJ', function() self:marker_destination(entry, true) end, false, 180, 35)
    self:button('GENERIC_WANDER', function() f.vehicles:drive(entry, nil, true) end, false, 180, 35); ImGui.SameLine()
    self:ui_button('BSV2_ES_DRIVE_PROPERTY', function() ImGui.OpenPopup('##service_property') end, false, 180, 35)
    self:property_popup(entry); self:seats(entry); self:radio(entry); ImGui.EndDisabled()
end

function View:helicopter()
    local f, entry = self.f, self.f.vehicles.active.heli
    if not entry then
        ImGui.SeparatorText(self:text('BSV2_HELI_MODELS_AVAIL')); ImGui.Spacing()
        if ImGui.BeginListBox('##heliList', -1, 0) then
            for index, item in ipairs(Data.DefaultHeliModels) do
                ImGui.Selectable(item.label, self.heli_index == index - 1); if ImGui.IsItemClicked(0) then self.heli_index = index - 1 end
            end
            ImGui.EndListBox()
        end
        ImGui.Dummy(1, 5); ImGui.Separator(); ImGui.Dummy(1, 5)
        self.heli_godmode = Widgets.toggle(self.ctx, self:text('GENERIC_INVINCIBLE'), self.heli_godmode or false)
        self:ui_button('BSV2_DISPATCH', function() f:call('heli', Data.DefaultHeliModels[self.heli_index + 1].value, nil, self.heli_godmode) end, f.pending.heli, 100, 40)
        return
    end
    self.footer = entry
    if not entry.in_vehicle then
        self:button('GENERIC_WARP_INTO_VEH', function() f.vehicles:warp(entry) end, entry.rappelling or entry.busy or not entry.ready, 180, 35); ImGui.SameLine()
        self:button('GENERIC_BRING', function() f.vehicles:bring(entry) end, not entry.far_away or entry.busy or entry.rappelling, 180, 35)
        ImGui.Text(self:text((entry.busy or entry.rappelling) and 'GENERIC_WAIT_LABEL' or 'BSV2_HELI_MORE_OPTS_TT')); return
    end
    ImGui.BeginDisabled(entry.rappelling or false); ImGui.Spacing(); ImGui.SeparatorText(self:text('GENERIC_COMMANDS')); ImGui.Spacing()
    self:button('BSV2_HELI_HOVER_HERE', function() f.vehicles:hover(entry) end, entry.task == 'hover' or (entry.altitude or 0) <= 3, 180, 35); ImGui.SameLine()
    self:button('BSV2_HELI_LAND_HERE', function() f.vehicles:land(entry) end, (entry.altitude or 0) <= 3, 180, 35)
    self:button('BSV2_FLY_WP', function() self:marker_destination(entry, false) end, false, 180, 35); ImGui.SameLine()
    self:button('BSV2_FLY_OBJ', function() self:marker_destination(entry, true) end, false, 180, 35)
    self:button('BSV2_FLY_SKIP', function() f.vehicles:skip(entry) end, entry.task ~= 'goto', 180, 35); ImGui.SameLine()
    if entry.allows_rappel then
        self:button('BSV2_HELI_RAPPELL', function()
            local state = self.ctx.state:read(); local seat = -1
            for index = -1, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(entry.vehicle.handle) - 1 do if VEHICLE.GET_PED_IN_VEHICLE_SEAT(entry.vehicle.handle, index, false) == state.handle then
                    seat = index; break
                end end
            if seat < 1 then self.ctx.notifier:error('Private Heli', self:text('BSV2_HELI_RAPPELL_SEAT_ERR')) else TASK.TASK_RAPPEL_FROM_HELI(state.handle, 5) end
        end, entry.task ~= 'hover' or (entry.altitude or 0) < 5 or entry.rappelling, 180, 35)
    end
    ImGui.Spacing(); ImGui.SeparatorText(self:text('BSV2_HELI_PRESETS')); ImGui.Spacing()
    local names = {}; for index, item in ipairs(Data.HeliPresetDestinations) do names[index] = item.label end
    self.destination = ImGui.Combo('##heliPresetDestinations', self.destination, names, #names); ImGui.SameLine()
    self:button('GENERIC_GO', function() f.vehicles:fly(entry, Data.HeliPresetDestinations[self.destination + 1].value, nil, true) end)
    self:seats(entry); self:radio(entry); ImGui.EndDisabled()
end

function View:airport_combo()
    local names = {}; for index, item in ipairs(Data.Airports) do names[index] = item.name end
    self.airport_index = ImGui.Combo('##airportCombo', self.airport_index, names, #names)
end

function View:jet()
    local f, entry = self.f, self.f.vehicles.active.jet
    if not entry then
        ImGui.SeparatorText(self:text('BSV2_JET_MODELS_AVAIL')); ImGui.Spacing()
        if ImGui.BeginListBox('##jetList', -1, 0) then
            for index, item in ipairs(Data.DefaultJetModels) do
                ImGui.Selectable(item.name, self.jet_index == index - 1); if ImGui.IsItemClicked(0) then self.jet_index = index - 1 end; if item.description then self:help(item.description) end
            end
            ImGui.EndListBox()
        end
        ImGui.Spacing(); ImGui.SeparatorText(self:text('BSV2_AIRPORTS')); ImGui.Spacing()
        self:airport_combo(); ImGui.Dummy(1, 5); ImGui.Separator(); ImGui.Dummy(1, 5)
        self:ui_button('BSV2_DISPATCH', function() f:call('jet', Data.DefaultJetModels[self.jet_index + 1].model, Data.Airports[self.airport_index + 1], true) end, f.pending.jet, 100, 40)
        self:help('BSV2_JET_TOO_FAR_WARN'); return
    end
    self.footer = entry
    if not entry.in_vehicle then
        self:button('GENERIC_WARP_INTO_VEH', function() self.f.vehicles:warp(entry) end, not entry.can_warp or entry.busy, 180, 35); ImGui.Spacing(); ImGui.Text(self:text('BSV2_JET_MORE_OPTS_TT')); return
    end
    ImGui.Spacing(); ImGui.SeparatorText(self:text('GENERIC_COMMANDS')); ImGui.Spacing()
    ImGui.BeginDisabled(entry.task == 'takeoff')
    self:button('BSV2_FLY_WP', function() self:marker_destination(entry, false) end, false, 180, 35); ImGui.SameLine()
    self:button('BSV2_FLY_OBJ', function() self:marker_destination(entry, true) end, false, 180, 35); ImGui.EndDisabled()
    self:button('BSV2_FLY_SKIP', function() f.vehicles:skip(entry) end, entry.task ~= 'goto', 180, 35); ImGui.SameLine()
    self:button('BSV2_JET_SKIP_LANDING', function() f.vehicles:finish_landing(entry) end, entry.task ~= 'land', 180, 35)
    ImGui.Spacing(); ImGui.SeparatorText(self:text('BSV2_JET_LANDING_DEST')); ImGui.Spacing(); self:airport_combo(); ImGui.SameLine()
    self:button('GENERIC_GO', function()
        local airport = Data.Airports[self.airport_index + 1]
        if entry.departure and entry.departure.name == airport.name then
            self.ctx.notifier:error('Private Jet', self:text('BSV2_JET_LANDING_SAME_AP_ERR', airport.name)); return
        end
        self.ctx.notifier:info('Private Jet', self:text('BSV2_JET_FLY_CONFIRM', airport.name))
        f.vehicles:fly(entry, airport.landingApproach.pos, airport, false)
    end)
    self:seats(entry); self:radio(entry)
end

function View:vehicle_footer(entry)
    ImGui.SetWindowFontScale(1.12); ImGui.SeparatorText(entry.name or 'Private ' .. entry.kind); ImGui.SetWindowFontScale(1); ImGui.Spacing()
    ImGui.BulletText((entry.kind == 'limo' and 'Driver: ' or 'Pilot: ') .. entry.driver_name)
    if entry.copilot_name then ImGui.BulletText('Co-Pilot: ' .. entry.copilot_name) end
    ImGui.BulletText('Status: ' .. (vehicle_status[entry.task] or 'Idle.')); ImGui.Spacing()
    self:button('GENERIC_REPAIR', function() self.f.vehicles:repair(entry, true) end, entry.kind == 'heli' and not entry.ready, 100, 35); ImGui.SameLine()
    self:button('GENERIC_DISMISS', function() self.f.vehicles:dismiss(entry) end, entry.kind == 'heli' and not entry.ready, 100, 35)
end

function View:escort_spawn()
    local f = self.f; local groups = copy(Data.DefaultEscortGroups)
    for name, group in pairs(f.store.data.groups) do groups[name] = group end
    self.group_search = Widgets.input_text_with_hint(self.ctx, '##searchEscorts', self:text('GENERIC_SEARCH_HINT'), self.group_search):lower()
    if ImGui.BeginListBox('##escortGroupList', -1, -1) then
        for name in pairs(groups) do if name:lower():find(self.group_search, 1, true) then
                ImGui.Selectable(name, self.selected_group == name); if ImGui.IsItemClicked(0) then self.selected_group = name end
            end end
        ImGui.EndListBox()
    end
    self.spawn_group = groups[self.selected_group]
end

function View:escort_footer()
    local f = self.f
    if self.footer == 'escort_spawn' then
        if ImGui.BeginChild('##escortGroupFooter', 0, 160, false) then
            ImGui.SetWindowFontScale(1.12); ImGui.SeparatorText(self:text('GENERIC_PREFERENCES_LABEL')); ImGui.SetWindowFontScale(1)
            ImGui.BeginDisabled(not self.spawn_group)
            self.escort_godmode = Widgets.toggle(self.ctx, self:text('GENERIC_INVINCIBLE'), self.escort_godmode or false); ImGui.SameLine()
            self.escort_no_ragdoll = Widgets.toggle(self.ctx, self:text('GENERIC_NORAGDOLL'), self.escort_no_ragdoll or false)
            ImGui.Spacing(); ImGui.Separator()
            self:button('BSV2_CALL', function(valid) f.escorts:spawn(self.spawn_group, self.escort_godmode, self.escort_no_ragdoll, valid) end, not self.spawn_group, 120, 40)
            if f.store.data.groups[self.selected_group] then
                ImGui.SameLine(); self:ui_button('GENERIC_DELETE', function()
                    if self.ctx.input.held[16] then self:delete_group() else ImGui.OpenPopup('##delete_escort_group') end
                end)
            end
            ImGui.EndDisabled()
            self:confirmation('##delete_escort_group', 'BSV2_CONFIRM_DELETE_GROUP', function() self:delete_group() end)
        end
        ImGui.EndChild()
    elseif self.footer == 'escort_spawned' and #f.escorts.groups > 1 then
        ImGui.Spacing(); ImGui.Separator()
        self:button('GENERIC_DISMISS_ALL', function() for _, group in ipairs(f.escorts.groups) do f.escorts:dismiss(group) end end)
    end
end

function View:delete_group()
    local groups = copy(self.f.store.data.groups); groups[self.selected_group] = nil; self.f.store:set('groups', groups); self.f.store:save(); self.selected_group = nil
end

function View:confirmation(id, message, callback)
    if Widgets.dialog(self.ctx, id, self:text(message), 0) then callback() end
end

function View:escort_spawned()
    local f = self.f
    if #f.escorts.groups == 0 then
        ImGui.Text(self:text('BSV2_ES_SPAWNED_NONE')); return
    end
    for _, group in ipairs(f.escorts.groups) do
        ImGui.PushID(group.name)
        local selected = self.open_group == group
        ImGui.Selectable('[' .. (selected and '-' or '+') .. '] ' .. group.name, selected)
        self:help(vehicle_status[group.task] or 'Idle.')
        if ImGui.IsItemClicked(0) then
            self.open_group = not selected and group or nil; self.ctx.view:play_sound('Click')
        end
        if self.open_group == group then
            ImGui.BeginDisabled(group.dismissed or false)
            ImGui.Text('Vehicle: ' .. (group.vehicle_name or group.vehicle.model)); ImGui.Text('Group Task: ' .. (vehicle_status[group.task] or 'Idle.'))
            ImGui.SeparatorText('Group Members (' .. #group.members .. '):')
            for _, member in ipairs(group.members) do
                ImGui.BulletText(member.display_name or member.name); Widgets.help(self.ctx, guard_status[member.task] or member.override_description or 'Running a custom task.')
            end
            self:button('GENERIC_REPAIR', function() f.vehicles:repair(group, true) end); ImGui.SameLine()
            self:button('GENERIC_GOTO', function() f.escorts:bring_player(group) end, group.in_vehicle); ImGui.SameLine()
            self:button('GENERIC_BRING', function() f.escorts:bring(group) end, group.in_vehicle); ImGui.SameLine()
            self:button('GENERIC_RESPAWN', function(valid)
                local definition = f.escorts:serialize(group)
                local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), math.random(-2, 2), -10, 0.1)
                f.escorts:remove(group); script.yield(250)
                if valid() then f.escorts:spawn(definition, self.escort_godmode, self.escort_no_ragdoll, valid, pos) end
            end, group.in_vehicle)
            if group.in_vehicle then
                self:ui_button('BSV2_ES_DRIVING_OPTIONS', function() ImGui.OpenPopup('escort driving options') end)
                if ImGui.BeginPopup('escort driving options') then
                    for _, entry in ipairs({ { 'GENERIC_WANDER', 'wander' }, { 'BSV2_ES_DRIVE_WP', 'waypoint' }, { 'BSV2_ES_DRIVE_OBJ', 'objective' }, { 'BSV2_ES_DRIVE_PROPERTY', 'property' }, { 'GENERIC_STOP', 'stop' } }) do
                        if ImGui.MenuItem(self:text(entry[1])) then
                            local action = entry[2]
                            if action == 'property' then
                                self.property_group = group; self.open_property = true
                            else
                                f:run('escort command', function()
                                    if action == 'wander' then
                                        f.escorts:drive(group, nil, true)
                                    elseif action == 'stop' then
                                        f.escorts:cancel(group); local driver = f.escorts:driver(group); if driver then TASK.TASK_VEHICLE_TEMP_ACTION(driver.handle, group.vehicle.handle, 1, -1) end
                                    else
                                        local pos = action == 'waypoint' and self.ctx.game.waypoint() or self.ctx.game.objective(); if pos then f.escorts:drive(group, pos, false) else self.ctx.notifier:error('Billionaire Services', self:text('GENERIC_TP_INVALID_COORDS_ERR')) end
                                    end
                                end)
                            end
                            ImGui.CloseCurrentPopup()
                        end
                    end
                    ImGui.SeparatorText(self:text('GENERIC_DRIVING_STYLE'))
                    local mode, changed = ImGui.RadioButton(self:text('GENERIC_DRIVING_STYLE_NORMAL'), group.mode, 0)
                    if changed then f:run('escort driving style', function()
                            group.mode = mode; if group.task == 'goto' or group.task == 'wander' then f.escorts:drive(group, group.destination, group.task == 'wander') end
                        end) end
                    ImGui.SameLine(); mode, changed = ImGui.RadioButton(self:text('GENERIC_DRIVING_STYLE_AGGRO'), group.mode, 1)
                    if changed then f:run('escort driving style', function()
                            group.mode = mode; if group.task == 'goto' or group.task == 'wander' then f.escorts:drive(group, group.destination, group.task == 'wander') end
                        end) end
                    ImGui.EndPopup()
                end
            end
            ImGui.SameLine(); self:button('GENERIC_DISMISS', function() f.escorts:dismiss(group) end)
            ImGui.EndDisabled()
        end
        ImGui.Separator(); ImGui.PopID()
    end
    if self.open_property then
        ImGui.OpenPopup('##service_property'); self.open_property = false
    end
    if self.property_group then self:property_popup(self.property_group) end
end

function View:group_creator()
    local existing = self.f.store.data.groups[self.new_name] or Data.DefaultEscortGroups[self.new_name]
    local valid = self.stage == 1 and self.new_name:find('%S') and not existing or self.stage == 2 and self.chosen_vehicle ~= nil or self.stage == 3 and #self.new_members == 3
    self:ui_button('<', function() self.stage = math.max(1, self.stage - 1) end, self.stage <= 1, 40, 30)
    self:help('GENERIC_PREVIOUS')
    ImGui.SameLine(); Widgets.value_bar(self.ctx, '', self.stage / 3, ImGui.GetContentRegionAvail() - 50, 30, false, nil, self:text('BSV2_ES_NEW_GROUP_STEP_LABEL', self.stage)); ImGui.SameLine()
    if self.stage < 3 then
        self:ui_button('>', function() self.stage = self.stage + 1 end, not valid, 40, 30)
    else
        self:ui_button('OK', function() ImGui.OpenPopup('##confirmNewGroup') end, not valid, 40, 30)
    end
    self:help(self.stage < 3 and 'GENERIC_NEXT' or 'GENERIC_CONFIRM')
    self:confirmation('##confirmNewGroup', self:text('BSV2_ES_NEW_GROUP_PROMPT', self.new_name), function()
        local groups = copy(self.f.store.data.groups)
        groups[self.new_name] = { name = self.new_name, vehicleModel = self.chosen_vehicle, members = copy(self.new_members), JSON = true }
        self.f.store:set('groups', groups); self.f.store:save(); self.stage = 1; self.new_name = ''; self.new_members = {}; self.chosen_vehicle = nil
    end)
    if self.stage == 1 then
        ImGui.Dummy(0, 15); ImGui.Text(self:text(valid and 'BSV2_ES_NEW_GROUP_NEXT' or 'BSV2_ES_NEW_GROUP_NAME', '[ > ]')); ImGui.Spacing()
        local name = Widgets.input_text_with_hint(self.ctx, '*##groupName', self:text('GENERIC_NAME'), self.new_name); self.new_name = Widgets.validated_text(self.new_name, name, 128)
        if existing then ImGui.TextColored(1, 0, 0, 1, self:text('BSV2_ES_NEW_GROUP_NAME_ERR')) end
    elseif self.stage == 2 then
        ImGui.Dummy(0, 15); ImGui.Text(self:text(valid and 'BSV2_ES_NEW_GROUP_NEXT' or 'BSV2_ES_NEW_GROUP_VEH', '[ > ]')); ImGui.Spacing()
        local names = self.new_vehicle_names or {}
        if #names > 0 then
            local index, changed = ImGui.Combo('*##newGroupVehicle', self.new_vehicle, names, #names); self.new_vehicle = index
            if changed then self.chosen_vehicle = Data.NewGroupVehicles[index + 1] end
        end
    else
        local count = #self.new_members
        ImGui.Text(self:text(count == 3 and 'BSV2_ES_NEW_GROUP_MEMBERS_DONE' or 'BSV2_ES_NEW_GROUP_MEMBERS')); ImGui.Spacing()
        ImGui.BulletText(self:text('BSV2_ES_NEW_GROUP_MEMBERS_COUNT', count)); ImGui.SameLine()
        self:ui_button(' - ', function() table.remove(self.new_members) end, count == 0); self:help('BSV2_ES_NEW_GROUP_MEMBERS_REMOVE'); ImGui.SameLine()
        self:ui_button(' + ', function()
            self.new_members[#self.new_members + 1] = { modelHash = self.member_model.model, name = self.member_name, weapon = self.member_weapons.selected }; self.member_name = ''
        end, not self.member_model or count == 3)
        self:help('BSV2_ES_NEW_GROUP_MEMBERS_ADD')
        if count < 3 then
            ImGui.SeparatorText(self:text('BSV2_ES_NEW_GROUP_PED_MODEL') .. ' *'); self.member_model = self.member_browser:draw()
            ImGui.SeparatorText(self:text('BSV2_ES_NEW_GROUP_PED_NAME'))
            local name = Widgets.input_text_with_hint(self.ctx, '##memberName', self:text('GENERIC_NAME'), self.member_name); self.member_name = Widgets.validated_text(self.member_name, name, 256)
            ImGui.SameLine(); self:ui_button('GENERIC_RANDOM', function() self.member_name = self.f:random_name(self.member_model.metadata.ped_gender) end, not self.member_model)
            ImGui.SeparatorText(self:text('BSV2_ES_NEW_GROUP_PED_WEAPON')); self.member_weapons:draw()
        end
    end
    if Widgets.button(self.ctx, ' ( ? ) ') then ImGui.OpenPopup('##newGroupHelp') end
    self:help('GENERIC_HELP_LABEL')
    local _, help = ImGui.BeginPopupModal('##newGroupHelp', true, bit.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoSavedSettings))
    if help then
        for index = 1, 3 do ImGui.TextWrapped(self:text('BSV2_ES_NEW_GROUP_HELP_' .. index)) end
        for index = 1, 5 do ImGui.BulletText(self:text('BSV2_ES_NEW_GROUP_HELP_3.' .. index)) end
        ImGui.TextWrapped(self:text('BSV2_ES_NEW_GROUP_HELP_4')); ImGui.TextWrapped(self:text('BSV2_ES_NEW_GROUP_HELP_5'))
        if Widgets.button(self.ctx, self:text('GENERIC_CLOSE')) then ImGui.CloseCurrentPopup() end
        ImGui.EndPopup()
    end
end

function View:escorts()
    if ImGui.BeginTabBar('##escortsUI') then
        if ImGui.BeginTabItem(self:text('GENERIC_SPAWN')) then
            self:escort_spawn(); self.footer = 'escort_spawn'; ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem(self:text('BSV2_ES_SPAWNED_TAB')) then
            self:escort_spawned(); self.footer = 'escort_spawned'; ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem('+ Group Creator') then
            self:group_creator(); self.footer = nil; ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
end

function View:draw()
    if not self.ctx.settings:get('ui.show_billionaire') then return end
    if self.f.failed and Widgets.button(self.ctx, 'Retry Billionaire Services') then self.f.failed = false end
    if not self.f.active then
        ImGui.Text('Billionaire Services requires a living player.'); return
    end
    self.footer = nil
    if ImGui.BeginChild('##main_sidebar', 160, self.ctx.settings:get('ui.height') * 0.6, false) then
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 20); ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 40)
        local count = #self.f.escorts.groups; for _ in pairs(self.f.vehicles.active) do count = count + 1 end
        for _, guard in pairs(self.f.guards.members) do if guard.role == 'bodyguard' then count = count + 1 end end
        self:button('GENERIC_DISMISS_ALL', function()
            for _, entry in pairs(self.f.vehicles.active) do self.f.vehicles:dismiss(entry) end
            for _, group in ipairs(self.f.escorts.groups) do self.f.escorts:dismiss(group) end
            for _, guard in pairs(self.f.guards.members) do if guard.role == 'bodyguard' then self.f.guards:dismiss(guard) end end
        end, count <= 1)
        self:help('BSV2_DISMISS_ALL_TT'); ImGui.Dummy(1, 20)
        for index, name in ipairs({ 'BSV2_BODYGUARDS_LABEL', 'BSV2_ESCORTS_LABEL', 'BSV2_LIMO_LABEL', 'BSV2_HELI_LABEL', 'BSV2_JET_LABEL' }) do
            local selected = self.page == index
            if selected then
                local c = self.ctx.theme:current().Colors.ButtonActive; ImGui.PushStyleColor(ImGuiCol.Button, c.x or c[1], c.y or c[2], c.z or c[3], c.w or c[4])
            end
            if ImGui.Button(self:text(name), selected and 160 or 120, 35) then
                self.page = index; self.ctx.view:play_navigation()
            end
            if selected then ImGui.PopStyleColor() end
        end
        ImGui.PopStyleVar(2)
    end
    ImGui.EndChild(); ImGui.SameLine()
    if ImGui.BeginChild('##main', 0, self.ctx.settings:get('ui.height') * 0.6, true) then
        ({ View.bodyguards, View.escorts, View.limo, View.helicopter, View.jet })[self.page](self)
    end
    ImGui.EndChild()
    if self.page == 1 then self:guard_footer() elseif self.page == 2 then self:escort_footer() elseif type(self.footer) == 'table' then self:vehicle_footer(self.footer) end
end

return View
