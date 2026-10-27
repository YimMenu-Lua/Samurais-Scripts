-- Original Settings keybind selector and editor. GPL-3.0-or-later.
local Widgets = require('includes.ssv2.core.widgets')
local View = {}; View.__index = View
local keys = require('includes.ssv2.data.keyboard_keys')
local pad = require('includes.ssv2.data.gamepad_keys')
local labels = {
    gui_toggle = 'Toggle GUI',
    rod = 'SELF_ROD',
    kill_all_enemies = 'WRLD_KILL_ALL',
    laser_sights = 'SELF_LASER_SIGHTS',
    enemies_flee = 'WRLD_FLEE_ALL',
    veh_mine = 'VEH_MINES',
    cobra_maneuver = 'VEH_COBRA_MANEUVER',
    cobra_cancel = 'Cancel Cobra Maneuver',
    nos = 'VEH_NOS',
    nos_purge = 'VEH_NOS_PURGE',
    drift_mode = 'VEH_DRIFT_MODE',
    rolling_launch = 'Rolling Anti-Lag'
}
labels.shift_up = 'ManualGearbox: Shift Up'; labels.shift_down = 'ManualGearbox: Shift Down'
labels.clutch = 'ManualGearbox: Clutch'; labels.engine_start_stop = 'ManualGearbox: Engine Start/Stop'
function View.new(ctx) return setmetatable({ ctx = ctx, selected_type = 0, search = '' }, View) end

function View:text(key) return self.ctx.translator:text(key) end

function View:key_name(code, source)
    if not code or code == 0 then return self:text('GENERIC_NONE') end
    for name, value in pairs(source == 'keyboard' and keys or pad) do if value == code then return name end end
    return tostring(code)
end

function View:name(binding)
    local pair = binding.label and self.ctx.view.controls[binding.label]
    return pair and self:text(pair.control.label) or binding.label or
        self.ctx.settings:get('keybinds.' .. binding.id .. '.name') or self:text(labels[binding.id] or binding.id)
end

function View:help(key)
    if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and not self.ctx.settings:get('ui.disable_tooltips') then
        Widgets.tooltip(self.ctx, self:text(key))
    end
end

function View:row(binding, source, hide_label)
    if source == 'controller' and (binding.ui_action or self.ctx.settings:get('keybinds.' .. binding.id .. '.no_gamepad')) then return end
    local settings = self.ctx.settings; local root = 'keybinds.' .. binding.id .. '.'
    local key = settings:get(root .. source) or 0; local modifier = settings:get(root .. source .. '_modifier') or 0
    local no_unbind = binding.ui_action or settings:get(root .. 'allow_unbind') == false
    local label = self:key_name(key, source)
    if modifier ~= 0 then label = self:key_name(modifier, source) .. '  +  ' .. label end
    local defaults = require('includes.ssv2.data.defaults').keybinds[binding.id] or
        { keyboard = 0, controller = 0, keyboard_modifier = 0, controller_modifier = 0 }
    local is_default = true
    for _, field in ipairs({ 'keyboard', 'controller', 'keyboard_modifier', 'controller_modifier' }) do if (settings:get(root .. field) or 0) ~= (defaults[field] or 0) then is_default = false end end
    ImGui.PushID(binding.id .. source)
    if not hide_label then ImGui.SeparatorText(self:name(binding)) end
    ImGui.Spacing()
    if ImGui.Button(label, math.max(200, ImGui.GetContentRegionAvail() / 4), 32) then
        self.ctx.input:listen(binding.id, source, false); self.ctx.view:play_sound('Click')
    end
    ImGui.SameLine(); ImGui.BeginDisabled(is_default)
    if Widgets.button(self.ctx, self:text('GENERIC_RESET') .. '##reset') and not is_default then
        ImGui.OpenPopup(
            '##reset_binding')
    end
    ImGui.EndDisabled(); if is_default then self:help('SETTINGS_KEYBINDS_NO_RESET') end
    ImGui.SameLine(); ImGui.BeginDisabled(no_unbind or key == 0)
    if Widgets.button(self.ctx, self:text('SETTINGS_KEYBINDS_UNBIND') .. '##unbind', 0, 32) and not no_unbind and key ~= 0 then
        ImGui.OpenPopup('##unbind_binding')
    end
    ImGui.EndDisabled(); if no_unbind then self:help('SETTINGS_KEYBINDS_NO_UNBIND') end
    for _, action in ipairs({ 'reset', 'unbind' }) do
        if Widgets.dialog(self.ctx, '##' .. action .. '_binding', self:text(action == 'reset' and 'SETTINGS_KEYBINDS_RESET_COFNIRM' or 'SETTINGS_KEYBINDS_UNBIND_COFNIRM'), 1) then
            for _, field in ipairs({ 'keyboard', 'controller', 'keyboard_modifier', 'controller_modifier' }) do
                settings
                    :set(root .. field, action == 'reset' and (defaults[field] or 0) or 0)
            end
        end
    end
    self.ctx.view:draw_input_capture()
    ImGui.PopID()
end

function View:draw()
    self.selected_type = ImGui.Combo('##type', self.selected_type, { 'Feature Keybinds', 'Quick Toggle Keybinds' }, 2)
    ImGui.Spacing(); ImGui.Separator(); ImGui.Spacing()
    self.search = Widgets.search(self.ctx, '##searchKeybinds', self.search); ImGui.Spacing()
    local bindings, registered = {}, {}
    for _, binding in ipairs(self.ctx.input.bindings) do
        bindings[#bindings + 1] = binding; registered[binding.id] = true
    end
    for id in pairs(self.ctx.settings:get('keybinds')) do
        if not registered[id] and not id:match('^quick_') then bindings[#bindings + 1] = { id = id } end
    end
    if ImGui.BeginTabBar('##settingsKeybinds') then
        for _, source in ipairs({ 'keyboard', 'controller' }) do
            if ImGui.BeginTabItem(self:text(source == 'keyboard' and 'SETTINGS_KEYBINDS_KEYBOARD' or 'SETTINGS_KEYBINDS_CONTROLLER')) then
                local count = 0; ImGui.SetNextWindowBgAlpha(0)
                if ImGui.BeginChild('keybinds.' .. source, 0, self.ctx.settings:get('ui.height') * 0.7, false, ImGuiWindowFlags.AlwaysUseWindowPadding) then
                    for _, binding in ipairs(bindings) do
                        local quick = binding.id:match('^quick_') ~= nil
                        local name = self:name(binding)
                        if quick == (self.selected_type == 1) and (source ~= 'controller' or not binding.ui_action)
                            and (source ~= 'controller' or not self.ctx.settings:get('keybinds.' .. binding.id .. '.no_gamepad'))
                            and (self.search == '' or binding.id:lower():find(self.search, 1, true) and name:lower():find(self.search, 1, true)) then
                            self:row(binding, source); count = count + 1
                        end
                    end
                    if count == 0 then ImGui.Text('Wow! Such empty!') end
                end
                ImGui.EndChild(); ImGui.EndTabItem()
            end
        end
        ImGui.EndTabBar()
    end
end

return View
