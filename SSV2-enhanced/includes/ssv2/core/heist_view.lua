-- Original Heist Editor frontend, expressed with V2 widgets and services.
-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors. GPL-3.0-or-later.
local Widgets = require('includes.ssv2.core.widgets')
local Game = require('includes.ssv2.core.game')
local Raw = require('includes.ssv2.data.heist_definitions')
local View = {}; View.__index = View
local names = { 'YH_APT_HEISTS_LABEL', 'DLCC_DOOMS', 'CH_END_NAME', 'DLCC_ISLAN', 'DLCC_KORTZ', 'FIX_APP_VIP_TU' }
local failures = {
    doomsday = 'GOPS_BASE_HELP',
    casino = 'CH_HLP_2',
    cayo = 'HIF_SUB_HELP',
    kortz = 'K26_FLW_HLP4C',
    contract =
    'FIX_FLOW_HLP0'
}
function View.new(ctx, f) return setmetatable({ ctx = ctx, f = f }, View) end

function View:text(key, ...)
    if select('#', ...) > 0 then return self.ctx.translator:format(key, ...) end; return self.ctx.translator:text(key)
end

function View:center(key, scale)
    local label = self:text(key); ImGui.SetWindowFontScale(scale or 1)
    ImGui.SetCursorPosX(ImGui.GetCursorPosX() + math.max(0, (ImGui.GetContentRegionAvail() - ImGui.CalcTextSize(label)) *
        0.5))
    ImGui.Text(label); ImGui.SetWindowFontScale(1)
end

function View:help(key)
    if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and not self.ctx.settings:get('ui.disable_tooltips') then
        Widgets.tooltip(self.ctx, self:text(key))
    end
end

function View:button(key, callback, disabled, width, height)
    ImGui.BeginDisabled(not not disabled)
    if Widgets.button(self.ctx, self:text(key), width or 0, height or 0) and not disabled then self.f:run(key, callback) end
    ImGui.EndDisabled()
end

function View:toggle(key, path, help, red)
    local value, changed = Widgets.toggle(self.ctx, self:text(key), self.ctx.settings:get(path),
        red and { x = 1, y = 0, z = 0, w = 1 } or nil)
    if changed then self.ctx.settings:set(path, value) end
    if help then self:help(help) end
end

function View:heading(key)
    ImGui.Spacing(); ImGui.SetWindowFontScale(1.1); ImGui.SeparatorText(self:text(key)); ImGui.SetWindowFontScale(1); ImGui
        .Spacing()
end

function View:property(entry)
    local ignore = self.ctx.settings:get('features.yim_heists.ignore_prop_req')
    if not entry.property and not (entry.kind == 'cayo' and entry.owned) and not ignore then
        ImGui.TextWrapped(self:text(failures[entry.kind])); return false
    end
    if entry.property or entry.kind == 'cayo' and entry.owned then
        self:center('YH_GENERIC_PROPERTY', 1.16)
        self:center(
            entry.kind == 'cayo' and 'CELL_SUBMARINE' or entry.property.name or entry.property.gxt or 'YH_GENERIC_PROPERTY',
            0.88)
        if entry.kind == 'kortz' and not entry.art_room and not ignore then
            ImGui.TextWrapped(self:text('K26_FLW_HLP4B')); return false
        end
        if entry.kind == 'cayo' and not entry.spawned then
            if entry.requested then
                ImGui.TextDisabled(self:text('GENERIC_WAIT_LABEL') .. string.rep('.', math.floor(util.time() / 200) % 4))
            else
                local label = self:text('YH_CAYO_REQUEST_SUB')
                ImGui.SetCursorPosX(math.max(0, (ImGui.GetContentRegionAvail() - ImGui.CalcTextSize(label)) * 0.5))
                self:button('YH_CAYO_REQUEST_SUB',
                    function()
                        local value = self.ctx.script_data:global('request_services_global', { 613 }); if value then
                            value:set_int(1)
                        end
                    end)
            end
        else
            local p = entry.kind == 'cayo' and entry.coords or entry.property.coords
            if p and (p.x ~= 0 or p.y ~= 0 or p.z ~= 0) then
                local width = ImGui.CalcTextSize(self:text('GENERIC_TELEPORT')) +
                    ImGui.CalcTextSize(self:text('GENERIC_SET_WAYPOINT')) + ImGui.GetStyle().ItemSpacing.x +
                    ImGui.GetStyle().FramePadding.x * 4
                ImGui.SetCursorPosX(math.max(0, (ImGui.GetContentRegionAvail() - width) * 0.5))
                self:button('GENERIC_TELEPORT', function()
                    local x, y, z = p.x, p.y, p.z
                    if entry.kind == 'cayo' then
                        local angle = math.rad(entry.heading + 90); x, y, z = x + math.cos(angle), y + math.sin(angle),
                            z + 4
                    end
                    Game.teleport(self.ctx, { x = x, y = y, z = z })
                end)
                ImGui.SameLine(); self:button('GENERIC_SET_WAYPOINT', function() HUD.SET_NEW_WAYPOINT(p.x, p.y) end)
            end
        end
    end
    return true
end

function View:cuts(entry)
    ImGui.SeparatorText(self:text('CP_HEIST_PLAYER_CUTS'))
    self:button('CP_HEIST_MAX_PLAYER_CUTS', function()
        for i = 1, 4 do entry.cuts[i] = entry.kind == 'apartment' and 25 or 100 end
        if entry.launcher_active then self.f:cuts(entry, false) end
    end)
    if not ImGuiSliderFlags or ImGuiSliderFlags.NoInput == nil then
        ImGui.TextWrapped('Player-cut sliders require the V2 slider-flags API addition (G19).')
        return
    end
    for i = 1, 4 do
        local total = 0; for _, cut in ipairs(entry.cuts) do total = total + cut end
        local minimum, maximum = entry.kind == 'apartment' and 15 or 5,
            entry.kind == 'apartment' and 100 - total + entry.cuts[i] or 100
        local value = ImGui.SliderInt(self:text('GENERIC_PLAYER_FMT', i), math.floor(entry.cuts[i] / 5),
            math.floor(minimum / 5), math.floor(maximum / 5), entry.cuts[i] .. '%%', ImGuiSliderFlags.NoInput)
        entry.cuts[i] = value * 5
    end
end

function View:combo(entry, key, options, label)
    local definition = entry.metadata.setup_data[key]; options = options or entry.metadata[definition.combo_data_key]
    local translated = {}; for i, value in ipairs(options) do translated[i] = self:text(value) end
    ImGui.SetNextItemWidth(math.min(200, ImGui.GetContentRegionAvail() - 60))
    entry.setup[key] = ImGui.Combo(self:text(label or definition.label), entry.setup[key] or 0, translated, #translated)
end

function View:skip_preps(entry, disabled, callback)
    self:button('YH_GENERIC_SKIP_PREPS', callback or function() self.f:secondaries(entry, false) end, disabled)
    if disabled then self:help('YH_GENERIC_SKIP_PREPS_TT') end
end

function View:main(entry)
    local kind = entry.kind
    if kind ~= 'contract' then self:heading('CP_HEIST_SETUP') end
    if kind == 'apartment' then
        if entry.none_unlocked then
            ImGui.TextWrapped(self:text('YH_APT_STRANDS_LOCKED'))
            self:button('GENERIC_UNLOCK_ALL',
                function()
                    self.f:apartment_unlock(false); self.f:refresh_apartment(entry)
                end); return
        end
        Widgets.input_text(self.ctx, self:text('YH_APT_SELECTED_JOB'), self:text(entry.current_strand or 'GENERIC_NONE'),
            ImGuiInputTextFlags.ReadOnly)
        ImGui.Spacing(); ImGui.BeginDisabled(not entry.current_strand)
        self:skip_preps(entry, false, function() stats.set_int('MPX_HEIST_PLANNING_STAGE', -1) end)
        ImGui.Spacing(); self:cuts(entry); ImGui.EndDisabled(); return
    elseif kind == 'doomsday' then
        local acts = {}; for i, key in ipairs({ 'GENERIC_NONE', 'ACH_ACHGO2_NAME', 'ACH_ACHGO3_NAME', 'ACH_ACHGO4_NAME' }) do
            acts[i] =
                self:text(key)
        end
        entry.selection = ImGui.Combo(self:text('YH_DDAY_SELECTED_ACT'), entry.selection + 1, acts, #acts) - 1
        ImGui.Spacing(); ImGui.BeginDisabled(entry.selection == -1); self:cuts(entry); ImGui.EndDisabled()
    elseif kind == 'casino' then
        for _, key in ipairs({ 'target', 'approach', 'last_approach', 'hard_approach', 'gunman', 'driver', 'hacker', 'masks' }) do
            self:combo(entry, key)
        end
        if entry.setup.gunman > 0 then
            if not entry.metadata.guns[entry.setup.gunman] then entry.setup.gunman = 1 end
            self:combo(entry, 'weapons', entry.metadata.guns[entry.setup.gunman][entry.setup.approach + 1],
                'CP_HEIST_WEAPONS')
        end
        if entry.setup.driver > 0 then
            if not entry.metadata.cars[entry.setup.driver] then entry.setup.driver = 1 end
            self:combo(entry, 'cars', entry.metadata.cars[entry.setup.driver], 'CP_HEIST_GETAWAY_VEHS')
        end
        self:cuts(entry)
    elseif kind == 'cayo' or kind == 'kortz' then
        local _, changed = Widgets.toggle(self.ctx, self:text('YH_CAYO_DIFFICULTY'), entry.hard or false)
        if changed then self.f:run('heist difficulty', function() self.f:hard(entry) end) end
        if kind == 'cayo' then
            for _, key in ipairs({ 'primary_target', 'weapons', 'supply_truck_loc' }) do self:combo(entry, key) end
            ImGui.TextDisabled(self:text('YH_SECONDARY_TARGET_TXT')); self:cuts(entry)
        else
            local targets = {}; for i, key in ipairs(entry.metadata.targets) do targets[i] = self:text(key) end
            if ImGui.BeginCombo(self:text('CP_HEIST_TARGET'), targets[entry.selection + 1] or self:text('GENERIC_NONE')) then
                for i, label in ipairs(targets) do
                    ImGui.Selectable(label, entry.selection == i - 1); if ImGui.IsItemClicked() then
                        entry.selection = i -
                            1
                    end; if entry.selection == i - 1 then ImGui.SetItemDefaultFocus() end
                end
                ImGui.EndCombo()
            end
            ImGui.Spacing(); self:skip_preps(entry, entry.secondaries_unlocked)
        end
    else
        ImGui.Spacing()
        if entry.none_unlocked then
            self:button('GENERIC_UNLOCK_ALL', function()
                stats.set_int('MPX_FIXER_COMPLETED_BS', -1); stats.set_int('MPX_FIXER_GENERAL_BS', -1); stats.set_int(
                    'MPX_FIXER_FIRST_TIME', 1); self.f:setup(entry, true); entry.none_unlocked = false
            end)
        end
        local missions = {}; for i, key in ipairs(entry.metadata.missions) do missions[i] = self:text(key) end
        entry.selection = ImGui.Combo('##dreContract', entry.selection, missions, #missions)
        ImGui.Spacing(); self:skip_preps(entry, entry.selection == 11, function() entry.selection = 11 end)
    end
    self:heading('GENERIC_OPTIONS_LABEL')
    local paths = {
        doomsday = 'features.yim_heists.dday_cd',
        casino = 'features.dunk.disable_heist_cooldown',
        cayo =
        'features.yim_heists.cayo_cd',
        kortz = 'features.yim_heists.kortz_cd',
        contract = 'features.yim_heists.dre_cd'
    }
    if kind == 'casino' then
        self:skip_preps(entry, entry.secondaries_unlocked); ImGui.Spacing()
    end
    self:toggle('YH_GENERIC_CD_LABEL', paths[kind], kind ~= 'casino' and 'YH_COOLDOWN_BYPASS_TOOLTIP' or nil,
        kind ~= 'casino')
    if kind == 'casino' then
        self:toggle('CP_HEIST_ZERO_AI_CUTS', 'features.dunk.zero_ai_cuts')
        self:toggle('YH_TROLLEY_AUTOGRAB', 'features.dunk.ch_cart_autograb')
        local solo = self.ctx.features.solo_missions
        ImGui.BeginDisabled(not self.ctx.settings:get('features.yim_heists.solo_missions') or solo.failed or false)
        local value, changed = Widgets.toggle(self.ctx, self:text('YH_CH_SOLO_PATCH'), solo.patch_enabled or false)
        if changed then
            solo.patch_enabled = value; self.f:run('casino solo patch', function() solo:patch_casino(value) end)
        end
        self:help('YH_CH_SOLO_PATCH_TT'); ImGui.EndDisabled()
        if not self.ctx.settings:get('features.yim_heists.solo_missions') and ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
            Widgets.tooltip(self.ctx, "Please enable 'SoloMissions' first!")
        end
    elseif kind == 'cayo' then
        self:toggle('YH_TROLLEY_AUTOGRAB', 'features.yim_heists.cayo_cart_autograb')
    elseif kind == 'kortz' then
        self:toggle('YH_K26_DISABLE_WEEKLY_RESET', 'features.yim_heists.kortz_week_bypass')
    end
end

function View:active(entry)
    if entry.kind == 'kortz' then
        self:button('YH_K26_DISABLE_LASERS', function()
            local pointer = ScriptPointer.new('ssv2_disable_lasers', '2D 01 03 00 00 5D ? ? ? 2A 56 ? ? 62'):scan(
                'fm_mission_controller_v3')
            assert(pointer and pointer:get_address() ~= 0, 'Laser function was not found')
            ScriptFunction.new('fm_mission_controller_v3', pointer):call('b=n', true)
        end, not entry.lasers_active)
        ImGui.Spacing()
    end
    if entry.metadata and entry.metadata.teleports then
        local list = entry.metadata.teleports; ImGui.Spacing(); ImGui.SeparatorText(self:text('GENERIC_TELEPORT'))
        if ImGui.BeginCombo('##teleportList', self:text(list[1].label)) then
            for i, item in ipairs(list) do
                ImGui.Selectable(self:text(item.label), i == 1)
                if ImGui.IsItemClicked() then
                    self.f:run('heist teleport',
                        function() Game.teleport(self.ctx, item.coords) end)
                end
                if i == 1 then ImGui.SetItemDefaultFocus() end
            end
            ImGui.EndCombo()
        end
    end
end

function View:entry(entry)
    if entry.kind ~= 'apartment' then
        ImGui.BeginDisabled(entry.running or false); ImGui.SetNextWindowBgAlpha(0.45)
        local allowed = true; if ImGui.BeginChild('##heist_header', 0, 130, true) then allowed = self:property(entry) end
        ImGui.EndChild(); ImGui.EndDisabled(); if not allowed then return end
    end
    local waiting = util.time() < (entry.confirm_until or 0)
    ImGui.SetNextWindowBgAlpha(0.4)
    if ImGui.BeginChild('##heist_scroll', 0, math.max(50, self.ctx.settings:get('ui.height') - 124.2 - (entry.kind == 'apartment' and 0 or 130) - 205), false) then
        local boost = ({ casino = 8, kortz = 13, contract = 9 })[entry.kind]
        if boost then
            ImGui.SetWindowFontScale(0.7); ImGui.BulletText(self:text('YH_BOOST_STATUS')); ImGui.SameLine()
            local enabled = self.f.boosted and self.f.boosted[boost]
            ImGui.TextColored(enabled and 0 or 1, enabled and 1 or 0, 0, 1,
                self:text(enabled and 'GENERIC_ACTIVE' or 'GENERIC_INACTIVE')); ImGui.SetWindowFontScale(1)
        end
        if waiting then
            ImGui.Dummy(0, 15); ImGui.SetWindowFontScale(1.15); ImGui.Text(self:text('GENERIC_WAIT_LABEL') ..
                string.rep('.', math.floor(util.time() / 200) % 4)); ImGui.SetWindowFontScale(1)
        else
            ImGui.BeginDisabled(entry.running or false); self:main(entry); ImGui.EndDisabled()
            if entry.kind == 'casino' or entry.kind == 'kortz' then
                ImGui.BeginDisabled(not entry.running); self:active(entry); ImGui.EndDisabled()
            end
        end
    end
    ImGui.EndChild(); ImGui.Separator()
    local width = math.max(120, ImGui.CalcTextSize(self:text('YH_GENERIC_SKIP_CUTSCENE')) + 20)
    ImGui.BeginDisabled(waiting or entry.running or false)
    for _, item in ipairs({ { 'GENERIC_CONFIRM', false }, { 'GENERIC_RESET', true } }) do
        if not item[2] or entry.kind ~= 'doomsday' then
            if item[2] then ImGui.SameLine() end
            if Widgets.button(self.ctx, self:text(item[1]), width, 32) then
                entry.confirm_until = util.time() + 1200; self.f:run('heist setup',
                    function() self.f:setup(entry, item[2]) end)
            end
        end
    end
    ImGui.EndDisabled(); Widgets.same_line_if_available(width)
    self:button('YH_GENERIC_SKIP_CUTSCENE',
        function() if CUTSCENE.IS_CUTSCENE_PLAYING() then CUTSCENE.STOP_CUTSCENE_IMMEDIATELY() end end, not entry
        .running, width, 32)
end

function View:boosts()
    ImGui.SetNextWindowSizeConstraints(480, 400, 600, 800)
    local _, draw = ImGui.BeginPopupModal('MPX_WEEKLY_BOOST_BS', true,
        bit.bor(ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoResize))
    if not draw then return end
    local bits = {}; for i = 31, 0, -1 do
        bits[#bits + 1] = bit.band(self.f.boost_bits or 0, bit.lshift(1, i)) ~= 0 and
            '1' or '0'
    end
    ImGui.Separator(); ImGui.TextDisabled(table.concat(bits)); ImGui.Separator()
    local disabled = not self.ctx.settings:get('features.unsafe_feats_enabled')
    if disabled then
        ImGui.TextWrapped(self:text('YRV3_UNSAFE_FEAT_BYPASS_ERR')); ImGui.Spacing(); ImGui.Spacing()
    end
    ImGui.BeginDisabled(disabled)
    for index, key in ipairs(Raw.BoostableHeistNames) do
        local _, changed = Widgets.toggle(self.ctx, self:text(key), self.f.boosted and self.f.boosted[index - 1] or false)
        if changed then self.f:run('weekly boost', function() self.f:boost(index - 1) end) end
    end
    ImGui.EndDisabled(); ImGui.EndPopup()
end

function View:draw()
    local ctx, f = self.ctx, self.f
    if not ctx.online then
        ImGui.Text(self:text('GENERIC_UNAVAILABLE_SP')); return
    end
    if not ctx.build.compatible then
        ImGui.TextColored(1, 0, 0, 1, self:text('GENERIC_OUTDATED')); return
    end
    ImGui.BeginDisabled(not f.active); ImGui.SetWindowFontScale(1.3); ImGui.Text('Heist Editor'); ImGui
        .SetWindowFontScale(0.8)
    ImGui.SameLine(ImGui.GetContentRegionAvail() - ImGui.CalcTextSize('  . . .  '))
    if ImGui.SmallButton(' . . . ') then ImGui.OpenPopup('##HeistEditorCtx') end
    ImGui.Text(self:text('YH_SUBTITLE_TXT')); ImGui.SetWindowFontScale(1); ImGui.EndDisabled(); ImGui.Spacing()
    if not f.active then
        ImGui.Text(self:text('GENERIC_WAIT_LABEL')); ImGui.Dummy(0, 20); return
    end
    if Widgets.button(self.ctx, self:text('YH_VIEW_BOOSTS')) then ImGui.OpenPopup('MPX_WEEKLY_BOOST_BS') end
    ImGui.SameLine(); local value, changed = Widgets.checkbox(ctx, ' $69 ',
        ctx.settings:get('features.yim_heists.sixty_nine')); if changed then
        ctx.settings:set(
            'features.yim_heists.sixty_nine', value)
    end; self:help('YH_SIXTY_NINE_TT')
    local solo = ctx.features.solo_missions
    Widgets.same_line_if_available(ImGui.CalcTextSize('SoloMissions') + 50)
    ImGui.BeginDisabled(solo.failed or false)
    value, changed = Widgets.checkbox(ctx, 'SoloMissions', ctx.settings:get('features.yim_heists.solo_missions')); if changed then
        ctx.settings:set('features.yim_heists.solo_missions', value)
    end
    self:help('YH_SOLO_MISSIONS_TT'); ImGui.EndDisabled()
    if solo.failed then Widgets.tooltip(ctx, self:text('YH_SM_LOAD_ERR'), { 1, 0, 0, 1 }) end
    Widgets.same_line_if_available(ImGui.CalcTextSize('Ignore Property') + 50)
    value, changed = Widgets.checkbox(ctx, 'Ignore Property', ctx.settings:get('features.yim_heists.ignore_prop_req')); if changed then
        ctx.settings:set('features.yim_heists.ignore_prop_req', value)
    end; self:help('YH_IGNORE_PROP_REQ_TT')
    ImGui.Separator()
    local width = 0; for _, key in ipairs({ 'YH_FAIL_MISSION', 'YH_SKIP_OBJECTIVE', 'YH_FINISH_MISSION' }) do
        width =
            math.max(width, ImGui.CalcTextSize(self:text(key)) + 40)
    end
    for i, item in ipairs({ { 'YH_FAIL_MISSION', 'fail' }, { 'YH_SKIP_OBJECTIVE', 'skip' }, { 'YH_FINISH_MISSION', 'finish' } }) do
        if i > 1 then Widgets.same_line_if_available(width + ImGui.GetStyle().ItemSpacing.x) end
        if i == 1 then
            ImGui.PushStyleColor(ImGuiCol.Button, 1, 0, 0, 1); ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 1, 0.12, 0.12,
                1); ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0.88, 0, 0, 1)
        end
        self:button(item[1], function() solo[item[2]](solo) end, solo.failed or not f.mission_active, width, 32)
        if i == 1 then ImGui.PopStyleColor(3) else self:help(item[1] .. '_TT') end
    end
    local mgh = ctx.features.minigame_hack; Widgets.same_line_if_available(ImGui.CalcTextSize('>_ MGH') + 20)
    self:button('>_ MGH', function() mgh:run() end, mgh.busy or mgh.failed)
    if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and not ctx.settings:get('ui.disable_tooltips') then
        Widgets.tooltip(self.ctx, self:text('YH_MGH_FMT', ctx.input:key_name('minigamehack')))
    end
    if mgh.failed then Widgets.tooltip(ctx, self:text('YH_MGH_LOAD_ERR'), { 1, 0, 0, 1 }) end
    ImGui.Separator()
    if #f.entries == 0 then
        ImGui.Text('Wow! Such empty!'); return
    end
    local width = ImGui.GetContentRegionAvail() * 0.8
    ImGui.SetCursorPosX((ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - width) * 0.5); ImGui.SetNextItemWidth(
        width)
    ImGui.PushStyleVar(ImGuiStyleVar.SelectableTextAlign, 0.5, 0.5)
    if ImGui.BeginCombo('##heisList', '') then
        for i, entry in ipairs(f.entries) do
            ImGui.Selectable(self:text(names[i]), f.selected == i - 1); if ImGui.IsItemClicked() then f.selected = i - 1 end; if f.selected == i - 1 then
                ImGui.SetItemDefaultFocus()
            end
        end
        ImGui.EndCombo()
    end
    ImGui.PopStyleVar()
    local label = self:text(names[f.selected + 1]); ImGui.SameLine(); ImGui.SetCursorPosX(ImGui.GetCursorPosX() +
        (width - 50 - ImGui.CalcTextSize(label)) * 0.5 - width); ImGui.Text(label)
    self:entry(f.entries[f.selected + 1])
    if ImGui.BeginPopup('##HeistEditorCtx') then
        if ImGui.MenuItem(self:text('GENERIC_RELOAD')) then
            f:run('reload heists', function()
                f:cleanup(); f:enter()
            end); ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
    end
    self:boosts()
end

return View
