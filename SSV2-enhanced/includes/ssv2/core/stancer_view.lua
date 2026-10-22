-- Original Stancer controls. Copyright (C) 2026 SAMURAI & Contributors.
-- GPL-3.0-or-later.
local Widgets = require('includes.ssv2.core.widgets')
local View = {}; View.__index = View
local specs = {
    m_toe = { label = 'VEH_STANCE_TOE', min = -0.25, max = 0.25, format = '%.2f°' },
    m_camber = { label = 'VEH_STANCE_CAMBER', min = -1, max = 1, format = '%.2f°' },
    m_track_width = { label = 'VEH_STANCE_TRACK_WIDTH', min = -0.5, max = 0.5, format = '%.2f' },
    m_susp_comp = { label = 'VEH_STANCE_SUSP_COMP', format = '%.2f', physics = true },
    m_wheel_width = { label = 'VEH_STANCE_WHEEL_WIDTH', min = -0.5, max = 0.5, format = '%.2f', visual = true },
    m_wheel_size = { label = 'VEH_STANCE_WHEEL_SIZE', min = -0.5, max = 0.5, format = '%.2f', visual = true },
}
function View.new(ctx, f) return setmetatable({ ctx = ctx, f = f, selected_model = '' }, View) end

function View:text(key) return self.ctx.translator:text(key) end

function View:help(key)
    if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and not self.ctx.settings:get('ui.disable_tooltips') then
        Widgets.tooltip(self.ctx, self:text(key))
    end
end

function View:run(label, callback)
    local f = self.f; local identity = f.identity
    self.ctx.runtime:run(label, function() if f.active and f.identity == identity then callback() end end)
end

function View:physics()
    self:run('stance physics',
        function() if VEHICLE.IS_VEHICLE_STOPPED(self.f.identity) then PHYSICS.ACTIVATE_PHYSICS(self.f.identity) end end)
end

function View:limits(key)
    local spec = specs[key]; local base = self.f.bases[1].m_susp_comp or 0
    return spec.min or -base + 0.1, spec.max or base - 0.1
end

function View:slider(key, axle)
    local f, spec = self.f, specs[key]; local low, high = self:limits(key)
    local disabled = spec.visual and not f.custom or spec.physics and f.bounce
    ImGui.BeginDisabled(not not disabled); ImGui.PushButtonRepeat(true)
    local label = self:text(spec.label) .. '##' .. axle
    if ImGui.ArrowButton('##' .. label .. '_-', 0) and not disabled then
        f.deltas[axle][key] = math.max(low, f.deltas[axle][key] - 0.01); if spec.physics then self:physics() end
    end
    ImGui.SameLine()
    f.deltas[axle][key] = ImGui.SliderFloat('##' .. label, f.deltas[axle][key], low, high, spec.format)
    if ImGui.IsItemDeactivatedAfterEdit() and spec.physics then self:physics() end
    ImGui.SameLine()
    if ImGui.ArrowButton('##' .. label .. '_+', 1) and not disabled then
        f.deltas[axle][key] = math.min(high, f.deltas[axle][key] + 0.01); if spec.physics then self:physics() end
    end
    ImGui.PopButtonRepeat(); ImGui.SameLine(); ImGui.Text(self:text(spec.label)); ImGui.EndDisabled()
    if spec.visual and not f.custom then self:help('VEH_STANCE_NON_STOCK') end
end

function View:confirm(id, message, callback)
    if Widgets.dialog(self.ctx, id, message, id == '##update_stance' and 1 or 0) then callback() end
end

function View:saved()
    local f = self.f; local models = f.storage:get('models')
    if next(models) then
        if Widgets.button(self.ctx, self:text('VEH_STANCE_VIEW_SAVED')) then
            self.saved_open = true; self.request_names = true
        end
        ImGui.SameLine()
        local value, changed = Widgets.toggle(self.ctx, self:text('VEH_STANCE_AUTOAPPLY'),
            self.ctx.settings:get('features.vehicle.stancer.auto_apply_saved'))
        if changed then
            self.ctx.settings:set('features.vehicle.stancer.auto_apply_saved', value); if value then
                self:run(
                    'load saved stance', function() f:load(f.model) end)
            end
        end
        self:help('VEH_STANCE_AUTOAPPLY_TT')
    end
    local existing = models[f.model] ~= nil; local label = self:text(existing and 'VEH_STANCE_UPDATE_MODEL' or
        'VEH_STANCE_SAVE_MODEL')
    if Widgets.button(self.ctx, label) then
        if existing then
            ImGui.OpenPopup('##update_stance')
        else
            self:run(
                'save stance', function() f:save() end)
        end
    end
    self:confirm('##update_stance', self.ctx.translator:format('VEH_STANCE_UPDATE_WARN', f.model),
        function() self:run('update stance', function() f:save() end) end)
    if not self.saved_open then return end
    local _, draw = ImGui.Begin('##viewSavedVehicles', true,
        bit.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoResize))
    if draw then
        if Widgets.quick_config(self.ctx, self:text('VEH_STANCE_VIEW_SAVED'), function() self.saved_open = false end) then
            if ImGui.BeginListBox('##savedVehList', -1, 360) then
                for model in pairs(models) do
                    ImGui.Selectable(self.model_names and self.model_names[model] or model, self.selected_model == model); if ImGui.IsItemClicked() then
                        self.selected_model =
                            model
                    end
                end
                ImGui.EndListBox()
            end
            ImGui.Separator(); ImGui.BeginDisabled(self.selected_model == '' or models[self.selected_model] == nil)
            if Widgets.button(self.ctx, self:text('GENERIC_APPLY')) and models[self.selected_model] then
                local model = self.selected_model; self:run('apply saved stance', function() f:load(model) end)
            end
            ImGui.SameLine(); if Widgets.button(self.ctx, self:text('GENERIC_REMOVE')) and models[self.selected_model] then
                f:remove(self.selected_model); self.selected_model = ''
            end
            ImGui.EndDisabled(); ImGui.SameLine()
            if Widgets.button(self.ctx, self:text('GENERIC_REMOVE_ALL')) then ImGui.OpenPopup('##remove_stances') end
            self:confirm('##remove_stances', self:text('GENERIC_CONFIRM_WARN'),
                function()
                    f.storage:set('models', {}); f.storage:save(); self.saved_open = false; self.selected_model = ''
                end)
        end
    end
    ImGui.End()
end

function View:update()
    if self.request_names then
        self.model_names = {}; for model in pairs(self.f.storage:get('models')) do
            self.model_names[model] = HUD
                .GET_FILENAME_FOR_AUDIO_CONVERSATION(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(util.joaat(model)))
        end
        self.request_names = false
    end
end

function View:draw()
    local f = self.f
    if not f.active then
        ImGui.Text(self:text(f.identity and 'GENERIC_CARS_ONLY' or 'GENERIC_NOT_IN_VEH')); return
    end
    if f.locked then
        ImGui.TextColored(0.94, 0.745, 0.007, 1, self.ctx.translator:format('VEH_STANCE_LOCKED_FMT', self:text(f.locked))); ImGui
            .Spacing()
    end
    ImGui.BeginDisabled(f.locked ~= nil)
    if Widgets.button(self.ctx, self:text('GENERIC_RESET_ALL')) then self:run('reset stance', function() f:reset() end) end
    for axle = 1, 2 do
        ImGui.SeparatorText(self:text(axle == 1 and 'VEH_STANCE_FRONT_AXLE' or 'VEH_STANCE_REAR_AXLE')); for _, key in ipairs({ 'm_toe', 'm_camber', 'm_track_width', 'm_susp_comp' }) do
            self:slider(key, axle)
        end
    end
    ImGui.Spacing(); if Widgets.button(self.ctx, self:text('VEH_STANCE_COPY_FB')) then
        f.deltas[2].m_camber = f.deltas[1].m_camber; f.deltas[2].m_track_width = f.deltas[1].m_track_width
    end
    ImGui.SeparatorText(self:text('VEH_STANCE_GEN_OPTIONS')); ImGui.BeginDisabled(f.bounce); ImGui.PushButtonRepeat(true)
    if ImGui.ArrowButton('##rideHight-', 3) then f.height = math.min(0.2, f.height + 0.01) end
    ImGui.SameLine(); f.height = ImGui.SliderFloat('##rideHeight', f.height, -0.2, 0.2)
    ImGui.SameLine(); if ImGui.ArrowButton('##rideHight+', 2) then f.height = math.max(-0.2, f.height - 0.01) end
    ImGui.PopButtonRepeat(); ImGui.SameLine(); ImGui.Text(self:text('VEH_STANCE_RIDE_HEIGHT')); ImGui.EndDisabled()
    self:slider('m_wheel_width', 1); self:slider('m_wheel_size', 1)
    ImGui.Spacing(); ImGui.SeparatorText(self:text('VEH_STANCE_AIR_SUSPENSION'))
    local front, rear = f.deltas[1].m_susp_comp, f.deltas[2].m_susp_comp; local low, high = self:limits('m_susp_comp')
    ImGui.BeginDisabled(f.bounce)
    for i, item in ipairs({ { 'VEH_STANCE_AIR_SUSPENSION_RAISE', high, front >= high - 0.01 and rear >= high - 0.01 }, { 'GENERIC_RESET', 0, front == 0 and rear == 0 }, { 'VEH_STANCE_AIR_SUSPENSION_LOWER', low, front <= low + 0.01 and rear <= low + 0.01 } }) do
        if i > 1 then ImGui.SameLine() end; ImGui.BeginDisabled(item[3])
        if ImGui.Button(self:text(item[1]) .. '##airsuspension') and not item[3] then
            f:air_suspension(item[2],
                i == 1 and 0.01 or i == 3 and -0.01 or nil)
        end
        ImGui.EndDisabled()
    end
    ImGui.EndDisabled(); ImGui.SameLine()
    local value, changed = Widgets.toggle(self.ctx, self:text('VEH_STANCE_BOUNCE_MODE'), f.bounce)
    if changed then
        f.bounce = value; if not value then f:bounce_stop() end
    end; self:help('VEH_STANCE_BOUNCE_MODE_TT')
    ImGui.Separator(); self:saved(); ImGui.EndDisabled(); ImGui.Spacing()
end

return View
