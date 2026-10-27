local paints = {}
for i, value in ipairs(require('includes.ssv2.data.custom_paints')) do paints[i] = value end
local filters = require('includes.ssv2.data.paint_filters')
local shades, manufacturers = filters.shades, filters.manufacturers
local Widgets = require('includes.ssv2.core.widgets')
table.sort(paints, function(a, b) return a.name < b.name end)
local function rgb(hex)
    assert(hex:match('^#%x%x%x%x%x%x$'), 'Invalid paint color')
    return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end
return function(ctx)
    local f = {
        id = 'paints',
        category = 'vehicle',
        controls = { { kind = 'toggle', path = 'ui.show_paints', label = 'Custom Paints' } },
        search = '',
        shade = 0,
        manufacturer = 0,
        selected = nil,
        primary = false,
        secondary = false,
        matte = false
    }
    function f:enabled() return ctx.settings:get('ui.show_paints') end

    function f:disable() ctx.settings:set('ui.show_paints', false) end

    function f:ready(state) return state.vehicle_handle ~= 0 end

    function f:update(state) self.vehicle = state.vehicle_handle end

    function f:cleanup() self.vehicle = nil end

    function f:apply(paint, primary, secondary, matte)
        local state = ctx.state:vehicle_state()
        if not state or not self.active or state.vehicle_handle ~= self.vehicle then return end
        if not primary and not secondary then
            ctx.notifier:error("Samurai's Scripts", ctx.translator:text('VEH_PAINT_NOT_SELECTED_ERR')); return
        end
        local r, g, b = rgb(paint.hex)
        VEHICLE.SET_VEHICLE_MOD_KIT(self.vehicle, 0)
        if primary then
            VEHICLE.SET_VEHICLE_MOD_COLOR_1(self.vehicle, matte and 3 or 1, 0, paint.p)
            VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(self.vehicle, r, g, b)
            VEHICLE.SET_VEHICLE_EXTRA_COLOURS(self.vehicle, paint.p, 0)
        end
        if secondary then
            VEHICLE.SET_VEHICLE_MOD_COLOR_2(self.vehicle, matte and 3 or 1, 0)
            VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(self.vehicle, r, g, b)
        end
    end

    f.owns_controls = true
    function f:draw_filter(id, title, current, names)
        ImGui.SetNextItemWidth(200)
        if ImGui.BeginCombo(id, current == 0 and title or names[current + 1]) then
            for i, name in ipairs(names) do
                ImGui.Selectable(name, current == i - 1)
                if ImGui.IsItemClicked(0) then
                    current = i - 1; self.selected = nil
                end
            end
            ImGui.EndCombo()
        end
        Widgets.tooltip(ctx, ctx.translator:text('VEH_PAINT_FILTER_TXT'))
        return current
    end

    function f:draw()
        local tr = ctx.translator
        if not self.active then
            ImGui.Text(tr:text('GENERIC_NOT_IN_VEH')); return
        end
        self.shade = self:draw_filter('##shades', 'Color Shade', self.shade, shades)
        Widgets.same_line_if_available(200)
        self.manufacturer = self:draw_filter('##manufacturer', 'Manufacturer', self.manufacturer, manufacturers)
        ImGui.SetNextItemWidth(-1); self.search = Widgets.search(ctx, '##custompaintssq', self.search)
        if ImGui.BeginListBox('##CustomPaints', -1, 324) then
            for index, paint in ipairs(paints) do
                if paint.name:lower():find(self.search) and (self.shade == 0 or paint.shade == shades[self.shade + 1]) and (self.manufacturer == 0 or paint.manufacturer == manufacturers[self.manufacturer + 1]) then
                    ImGui.Selectable(paint.name, self.selected == index)
                    if ImGui.IsItemClicked(0) then
                        self.selected = index; self.matte = paint.m
                    end
                    if ImGui.IsItemHovered() then
                        ImGui.SetNextWindowSize(220, 160, ImGuiCond.Always); ImGui.BeginTooltip()
                        local r, g, b = rgb(paint.hex); ImGui.SetNextWindowBgAlpha(1); ImGui.PushStyleColor(
                            ImGuiCol.ChildBg, r / 255, g / 255, b / 255, 1)
                        ImGui.BeginChild('##colDisplay', 0, 80, false); ImGui.EndChild(); ImGui.PopStyleColor()
                        ImGui.Spacing(); ImGui.SetWindowFontScale(0.7); ImGui.TextWrapped(tr:text('VEH_PAINT_NOTE')); ImGui
                            .SetWindowFontScale(1); ImGui.EndTooltip()
                    end
                end
            end
            ImGui.EndListBox()
        end
        if not self.selected then return end
        local paint = paints[self.selected]; ImGui.Spacing()
        local value, changed = Widgets.toggle(ctx, tr:text('VEH_PAINT_MATTE_CB'), paint.m)
        if changed then paint.m = value end; self.matte = paint.m
        Widgets.tooltip(ctx, tr:text('VEH_PAINT_MATTE_TT'))
        ImGui.Separator(); self.primary = Widgets.toggle(ctx, tr:text('VEH_PAINT_PRIMARY_CB'), self.primary); ImGui
            .SameLine(); self.secondary = Widgets.toggle(ctx, tr:text('VEH_PAINT_SECONDARY_CB'), self.secondary)
        if Widgets.button(ctx, tr:text('GENERIC_CONFIRM'), ImGui.CalcTextSize(tr:text('GENERIC_CONFIRM')) + 20, 40) then
            local primary, secondary, matte = self.primary, self.secondary, paint.m
            ctx.runtime:run('apply paint', function() self:apply(paint, primary, secondary, matte) end)
        end
        Widgets.tooltip(ctx, tr:text('VEH_PAINT_SAVE_TT'))
    end

    return f
end
