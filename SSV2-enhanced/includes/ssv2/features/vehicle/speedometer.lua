local Feature = require('includes.ssv2.core.feature')
local Memory = require('includes.ssv2.core.vehicle_memory')
local Widgets = require('includes.ssv2.core.widgets')
local apps = require('includes.ssv2.data.app_scripts')
local defaults = { circle = 0xFF313195, circle_bg = 0x66090909, markings = 0xFFC7C7C7, text = 0xDDFFFFFF, needle = 0xFF3636FF, needle_base = 0xFF111111 }
local function rgba(value, alpha)
    return bit.band(value, 255), bit.band(bit.rshift(value, 8), 255), bit.band(bit.rshift(value, 16), 255),
        alpha and math.floor(alpha) or bit.band(bit.rshift(value, 24), 255)
end
local function color_table(value)
    local r, g, b, a = rgba(value); return { r / 255, g / 255, b / 255, a / 255 }
end
local function packed(value)
    local result = 0
    for i = 1, 4 do result = result + math.floor(value[i] * 255 + 0.5) * 256 ^ (i - 1) end
    return result
end
return function(ctx)
    local root = 'features.speedometer.'
    local f = Feature.new(ctx, {
        id = 'speedometer',
        category = 'vehicle',
        scope = 'vehicle',
        path = root .. 'enabled',
        controls = {
            { kind = 'toggle', path = root .. 'enabled',    label = 'VEH_SPEEDOMETER' },
            { kind = 'combo',  path = root .. 'speed_unit', label = 'VEH_SPEED_UNIT', options = { 'M/s', 'Km/h', 'Mi/h' } },
        },
        last_engine = true,
        background_alpha = 0x66
    })
    function f:ready(state) return state.alive and state.driving end

    function f:cleanup()
        self.snapshot = nil; self.max_speed = nil; self.esc = false; self.esc_next = 0
    end

    function f:update(state)
        local handle, gearbox = state.vehicle_handle, ctx.features.manual_gearbox
        local nos, flares, abs = ctx.features.nos, ctx.features.flares, ctx.features.abs_lights
        local visible = ctx.game.outside(state.handle) and not HUD.IS_PAUSE_MENU_ACTIVE()
            and not scripts.is_active('CELLPHONE_FLASHHAND') and not CAMERA.IS_SCREEN_FADING_OUT() and
            not CAMERA.IS_SCREEN_FADED_OUT()
        for _, name in ipairs(apps) do
            if scripts.is_active(name) then
                visible = false; break
            end
        end
        if not nos.boosting or not self.max_speed then self.max_speed = VEHICLE.GET_VEHICLE_ESTIMATED_MAX_SPEED(handle) end
        local multiplier = ({ [0] = 1, [1] = 3.6, [2] = 2.236936 })[ctx.settings:get(root .. 'speed_unit')]
        local manual = gearbox.active and gearbox.mode ~= 2 and not gearbox.single
        local gear = manual and gearbox.selected or state.vehicle:get_gear()
        local velocity = ENTITY.GET_ENTITY_SPEED_VECTOR(handle, true)
        local reverse = manual and gearbox.reverse or not manual and velocity.y < 0
        local gear_text
        if gear <= 0 or gear > 100 then
            gear_text = reverse and 'R' or 'N'
        else
            gear_text = manual and (gearbox.mode == 1 and 'S' .. gear or tostring(gear)) or 'D' .. gear
        end
        local has_abs = state.car and Memory.handling_model_flag(handle, 4)
        local drifting = state.car and math.abs(velocity.x) >= 6 and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(handle)
        if drifting and util.time() >= (self.esc_next or 0) then
            self.esc = not self.esc; self.esc_next = util.time() + 100
        elseif not drifting then
            self.esc = false
        end
        local esc_off = false
        if state.car then
            local field = Memory.flag_pointer(handle, 'advanced', 13)
            esc_off = field and bit.band(field:get_dword(), bit.bor(8192, 16384)) ~= 0 or false
        end
        local class = VEHICLE.GET_VEHICLE_CLASS(handle)
        self.snapshot = {
            visible = visible,
            engine = VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(handle),
            aircraft = state.aircraft,
            speed = ENTITY.GET_ENTITY_SPEED(handle) * multiplier,
            max_speed = math.max(1, math.ceil(self.max_speed * multiplier)),
            altitude = ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(handle),
            rpm = state.vehicle:get_rev_ratio(),
            throttle = math.max(0.1, Memory.get_float(handle, 'throttle')),
            gear = gear_text,
            manufacturer = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(VEHICLE.GET_MAKE_NAME_FROM_VEHICLE_MODEL(state
                .vehicle:get_model())),
            health = VEHICLE.GET_VEHICLE_ENGINE_HEALTH(handle),
            sports = class == 6 or class == 7,
            abs = has_abs,
            abs_engaged = abs.active and abs.off,
            esc = self.esc,
            esc_off = esc_off,
            nos = nos.boosting,
            danger = nos.danger or 0,
            flares = flares.active and #flares.shots > 0,
            landing_gear = state.aircraft and VEHICLE.GET_LANDING_GEAR_STATE(handle) or -1
        }
    end

    local function text(list, x, y, value, color, size, center, alpha)
        local r, g, b, a = rgba(color, alpha)
        if center then
            local width = ImGui.CalcTextSize(value); x = x - width * (size / ImGui.GetFontSize()) / 2
        end
        list:AddText(x, y, value, r, g, b, a, size)
    end
    function f:render()
        local state = self.snapshot
        if not self:enabled() or not state or not state.visible then return end
        local width, height = ImGui.GetDisplaySize(); local radius = 150
        local x, y = ctx.settings:get(root .. 'pos.x'), ctx.settings:get(root .. 'pos.y')
        if x == 0 and y == 0 then
            x, y = width - radius * 2.5, height - radius * 3.5; ctx.settings:set(root .. 'pos.x', x); ctx.settings:set(
                root .. 'pos.y', y)
        end
        local flags = bit.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoScrollbar,
            ImGuiWindowFlags.NoScrollWithMouse, ImGuiWindowFlags.NoCollapse, ImGuiWindowFlags.NoMove)
        if state.danger >= 0.8 then
            local pulse = 0.5 + 0.5 * math.sin(util.time() / 1000 * 12)
            ImGui.SetNextWindowSize(radius * 1.3, 100, ImGuiCond.Always); ImGui.SetNextWindowPos(x + radius * 0.7, y -
                120, ImGuiCond.Always)
            ImGui.PushStyleColor(ImGuiCol.WindowBg, 1, pulse, 0.02, 0.9); ImGui.PushStyleColor(ImGuiCol.Text, 0.1, 0.1,
                0.1, 1)
            if ImGui.Begin('##dangertomanifold', nil, flags) then
                ImGui.SetWindowFontScale(1.4); ImGui.SetCursorPosX((radius * 1.3 - ImGui.CalcTextSize('Warning!!!')) / 2); ImGui
                    .Text('Warning!!!')
                ImGui.SetWindowFontScale(1.2); ImGui.Text('Danger to Manifold'); ImGui.SetWindowFontScale(1)
            end
            ImGui.End(); ImGui.PopStyleColor(2)
        end
        ImGui.SetNextWindowBgAlpha(0); ImGui.SetNextWindowSize(radius * 2.5, radius * 2, ImGuiCond.Always); ImGui
            .SetNextWindowPos(x, y, ImGuiCond.Always)
        if ImGui.Begin('##SpeedometerWindow', nil, bit.bor(flags, ImGuiWindowFlags.NoBackground)) then
            local list = ImGui.GetWindowDrawList(); local wx, wy = ImGui.GetWindowPos(); local ww, wh = ImGui
                .GetWindowSize(); local cx, cy = wx + ww / 2, wy + wh / 2 + 11
            local colors = {}; for key in pairs(defaults) do colors[key] = ctx.settings:get(root .. 'colors.' .. key) end
            local alpha = state.engine and 255 or math.floor(0.35 * 255)
            if self.last_engine ~= state.engine then
                self.last_engine = state.engine
                self.background_alpha = state.engine and math.floor(0.52 * 255) or math.floor(0.78 * 255)
                for key, color in pairs(colors) do
                    if key ~= 'needle_base' then
                        color = bit.bor(bit.band(color, 0xFFFFFF), bit.lshift(alpha, 24)) % 4294967296; colors[key] =
                            color; ctx.settings:set(root .. 'colors.' .. key, color)
                    end
                end
            end
            local function draw_text(px, py, value, color, size, center)
                size = size or ImGui.GetFontSize(); local w = ImGui.CalcTextSize(value)
                if center then px = px - w * (size / ImGui.GetFontSize()) / 2 end
                local r, g, b, a = rgba(color); list:AddText(px, py, value, r, g, b, a, size)
            end
            local function line(x1, y1, x2, y2, color, thickness)
                local r, g, b, a = rgba(color); list:AddLine(x1, y1, x2, y2, r, g, b, a, thickness)
            end
            local r, g, b, a = rgba(colors.circle)
            list:AddCircleFilled(cx, cy, radius + 10, 9, 9, 9, self.background_alpha)
            list:AddCircle(cx, cy, radius + 10, r, g, b, a, 100, 3)
            if not state.aircraft then
                if state.manufacturer and state.manufacturer ~= '' then
                    draw_text(cx - 5 - ImGui.CalcTextSize(state.manufacturer) / 2, cy - 15 - radius / 2,
                        state.manufacturer, math.floor(colors.text - math.pi * 10) % 4294967296, 19.5, false)
                end
                if state.engine and state.health <= 800 then
                    local green = state.health < 400 and 0.5 + 0.5 * math.sin(util.time() / 1000 * 5) or 0.9
                    local px, py = cx - radius + 100, cy + 40
                    list:AddTriangle(px, py, px - 10, py + 15, px + 10, py + 15, 255, math.floor(green * 255), 0, 255, 1)
                    list:AddText(px - 1, py + 2.8, '!', 255, math.floor(green * 255), 0, 255, ImGui.GetFontSize())
                    list:AddText(px - 30, py + 20, 'CHECK ENGINE', 255, math.floor(green * 255), 0, 255, 11.2)
                end
            end
            local start, finish = -math.pi * 1.25, math.pi * 0.25
            local maximum = state.aircraft and 2500 or state.max_speed
            local tick_step = state.aircraft and 500 or 20; local tick_max = math.ceil(maximum / tick_step) * tick_step
            for value = 0, tick_max, tick_step do
                local angle = start + (finish - start) * value / tick_max; local cos, sin = math.cos(angle),
                    math.sin(angle)
                line(cx + cos * (radius - 10), cy + sin * (radius - 10), cx + cos * radius, cy + sin * radius,
                    colors.markings, 1.5)
                local label = tostring(value); local tw, th = ImGui.CalcTextSize(label)
                draw_text(cx + cos * (radius - 30) - tw / 2, cy + sin * (radius - 30) - th / 2, label, colors.text)
            end
            local value = state.aircraft and state.altitude or state.speed
            local angle = start + (finish - start) * math.min(value / maximum, 1); local dx, dy = math.cos(angle) *
                radius, math.sin(angle) * radius
            for fraction = 0, 1, 0.25 do
                line(cx, cy, cx + dx * fraction, cy + dy * fraction, colors.needle,
                    3 * (1 - fraction * 0.5))
            end
            r, g, b, a = rgba(colors.needle_base); list:AddCircleFilled(cx, cy, 51, r, g, b, a)
            draw_text(cx, cy - 20, tostring(state.engine and math.floor(state.speed) or 0), colors.text,
                ImGui.GetFontSize() * 1.4, true)
            draw_text(cx, cy + 15, ({ 'M/s', 'Km/h', 'Mi/h' })[ctx.settings:get(root .. 'speed_unit') + 1], colors.text,
                ImGui.GetFontSize(), true)
            if state.engine then
                local ratio = state.aircraft and state.throttle or state.rpm; local normalized = math.min(1,
                    math.max(0, ratio))
                for _ = 0, math.floor(12 * ratio) - 1 do
                    local begin_angle = start - 0.07; local end_angle = start + (start - finish) * ratio - 0.07
                    local px, py = cx + math.cos(begin_angle) * 50, cy + math.sin(begin_angle) * 50
                    for segment = 1, 32 do
                        local theta = begin_angle + (end_angle - begin_angle) * segment / 32; local nx, ny =
                            cx + math.cos(theta) * 50, cy + math.sin(theta) * 50
                        list:AddLine(px, py, nx, ny, math.floor(normalized ^ 1.2 * 255), math.floor((1 - normalized) *
                            255), 0, 255, 2.5); px, py = nx, ny
                    end
                end
            end
            local off = 0x8C191919
            if state.aircraft then
                draw_text(cx - 43, cy - 80, string.format('Altitude [%.0fm]', state.altitude), colors.text,
                    ImGui.GetFontSize() * 0.77)
                draw_text(cx - 50, cy + 100, 'FLRS', state.flares and 0xFF00E819 or off, ImGui.GetFontSize() * 0.77)
                draw_text(cx + 30, cy + 100, 'GEAR', state.landing_gear > -1 and state.landing_gear < 4 and 0xFF3636FF or
                    off, ImGui.GetFontSize() * 0.77)
            else
                draw_text(cx, cy + 59, state.gear, state.sports and 0xFF3636FF or colors.text, ImGui.GetFontSize() * 1.5,
                    true)
                if state.abs then
                    draw_text(cx - 60, cy + 100, 'ABS', state.engine and state.abs_engaged and 0xFF00CCFF or off,
                        ImGui.GetFontSize() * 0.77)
                    draw_text(cx + 19, cy + 100, state.esc_off and 'TC/ESC OFF' or 'TC ESC',
                        (state.esc_off or state.engine and state.esc) and 0xFF3636FF or off, ImGui.GetFontSize() * 0.77)
                end
                if state.nos then draw_text(cx - 20, cy + 100, 'NOS', 0xFFFF5036, ImGui.GetFontSize() * 0.77) end
            end
        end
        ImGui.End()
    end

    menu.add_always_draw_imgui(function() f:render() end)
    function f:draw()
        local width, height = ImGui.GetDisplaySize(); local tr = ctx.translator; local radius = ctx.settings:get(root ..
            'radius')
        ImGui.SeparatorText(tr:text('VEH_SPEED_UNIT'))
        local unit = ctx.settings:get(root .. 'speed_unit')
        for index, name in ipairs({ 'M/s', 'Km/h', 'Mi/h' }) do
            if index > 1 then ImGui.SameLine() end; unit = ImGui.RadioButton(name, unit, index - 1)
        end
        ctx.settings:set(root .. 'speed_unit', unit); ImGui.Spacing(); ImGui.SeparatorText(tr:text(
            'GENERIC_POSITION_LABEL'))
        for _, axis in ipairs({ 'x', 'y' }) do
            local maximum = axis == 'x' and width - radius * 2.2 or height - radius * 2
            local value, changed = ImGui.SliderFloat(
                tr:text(axis == 'x' and 'GENERIC_LEFT_RIGHT_LABEL' or 'GENERIC_UP_DOWN_LABEL'),
                ctx.settings:get(root .. 'pos.' .. axis), 0, maximum)
            if changed then ctx.settings:set(root .. 'pos.' .. axis, value) end
        end
        ImGui.Spacing(); ImGui.SeparatorText(tr:text('GENERIC_COLORS_LABEL'))
        for _, entry in ipairs({ { 'circle', 'VEH_SPEED_CIRCLE' }, { 'text', 'VEH_SPEED_TEXT' }, { 'markings', 'VEH_SPEED_MARK' }, { 'needle', 'VEH_SPEED_NEEDLE' }, { 'needle_base', 'VEH_SPEED_NEEDLE_BASE' } }) do
            local value, changed = ImGui.ColorEdit4(tr:text(entry[2]),
            color_table(ctx.settings:get(root .. 'colors.' .. entry[1])))
            if changed then ctx.settings:set(root .. 'colors.' .. entry[1], packed(value)) end
        end
        ImGui.Separator(); ImGui.Spacing()
        if Widgets.button(ctx, tr:text('GENERIC_RESET')) then
            for key, value in pairs(defaults) do
                ctx.settings:set(
                    root .. 'colors.' .. key, value)
            end
        end
    end

    return f
end
