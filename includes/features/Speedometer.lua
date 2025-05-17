---@class Speedometer
Speedometer = {}
Speedometer.__index = Speedometer
Speedometer.cached_ticks = nil
Speedometer.cached_unit_sizes = {}
Speedometer.last_max_fractions = nil
Speedometer.last_max_value = nil
Speedometer.tick_marks = 10
Speedometer.line_thickness = 3.0
Speedometer.font_scale = 1.0


---@param radius number
---@param start_angle number
---@param end_angle number
---@param max_value number
---@param is_flying boolean
function Speedometer:GenerateTicks(radius, start_angle, end_angle, max_value, is_flying)
    local tick_step = not is_flying and 20 or 500
    local max_fractions = math.ceil(max_value / tick_step) * tick_step

    if (self.last_max_fractions == max_fractions) and (self.last_max_value == max_value) then
        return
    end

    self.last_max_fractions = max_fractions
    self.last_max_value = max_value
    self.cached_ticks = {}

    for i = 0, max_fractions, tick_step do
        local fraction = i / max_fractions
        local angle = start_angle + (end_angle - start_angle) * fraction
        local sin_a, cos_a = math.sin(angle), math.cos(angle)

        table.insert(self.cached_ticks, {
            x1 = cos_a * (radius - 10),
            y1 = sin_a * (radius - 10),
            x2 = cos_a * radius,
            y2 = sin_a * radius,
            angle = angle,
            value = i,
        })
    end
end

---@param ImDrawlist userdata
---@param center vec2
function Speedometer:DrawABSNOSESCIndicators(ImDrawlist, center)
    if Game.Vehicle.HasABS(Self.Vehicle.Current) then
        local abs_color = b_ShouldFlashBrakeLights and ImU32(1.0, 0.8, 0.0, 1.0) or ImU32(0.1, 0.1, 0.1, 0.5)

        ImGui.ImDrawListAddText(
            ImDrawlist,
            center.x - 50,
            center.y + 100,
            abs_color,
            "ABS"
        )

        local esc_color = Self.Vehicle.ShouldFlashESC and ImU32(1.0, 0.215, 0.215, 1.0) or ImU32(0.1, 0.1, 0.1, 0.5)

        ImGui.ImDrawListAddText(
            ImDrawlist,
            center.x + 25,
            center.y + 100,
            esc_color,
            "ESC"
        )
    end

    if using_nos then
        ImGui.ImDrawListAddText(
            ImDrawlist,
            center.x - 12.5,
            center.y + 100,
            ImU32(0.215, 0.315, 1.0, 1.0),
            "NOS"
        )
    end
end

---@param ImDrawlist userdata
---@param center vec2
function Speedometer:DrawAirplaneIndicators(ImDrawlist, center)
    local flare_color = FlareCountermeasures.active and ImU32(0.1, 0.91, 0.0, 1.0) or ImU32(0.1, 0.1, 0.1, 0.5)

    ImGui.ImDrawListAddText(
        ImDrawlist,
        center.x - 50,
        center.y + 100,
        flare_color,
        "FLRS"
    )

    local gear_color = (Self.Vehicle.LandingGearState > -1 and Self.Vehicle.LandingGearState < 4)
    and ImU32(0.91, 0.1, 0.0, 1.0) or ImU32(0.1, 0.1, 0.1, 0.5)

    ImGui.ImDrawListAddText(
        ImDrawlist,
        center.x + 30,
        center.y + 100,
        gear_color,
        "GEAR"
    )
end

---@param ImDrawList userdata
---@param center vec2
---@param radius number
---@param angle_start number
---@param angle_end number
---@param color number -- U32
---@param thickness number
---@param segments number
function Speedometer:DrawSmoothArc(ImDrawList, center, radius, angle_start, angle_end, color, thickness, segments)
    local step = (angle_end - angle_start) / segments
    local prev = {
        x = center.x + math.cos(angle_start) * radius,
        y = center.y + math.sin(angle_start) * radius
    }

    for i = 1, segments do
        local angle = angle_start + step * i
        local curr = {
            x = center.x + math.cos(angle) * radius,
            y = center.y + math.sin(angle) * radius
        }

        ImGui.ImDrawListAddLine(
            ImDrawList,
            prev.x,
            prev.y,
            curr.x,
            curr.y,
            color,
            thickness
        )
        prev = curr
    end
end

---@param ImDrawlist userdata
---@param center vec2
function Speedometer:DrawLowerIndicators(ImDrawlist, center)
    if self.font_scale ~= 0.77 then
        ImGui.SetWindowFontScale(0.77)
        self.font_scale = 0.77
    end

    if (Self.Vehicle.IsPlane or Self.Vehicle.IsHeli) then
        self:DrawAirplaneIndicators(ImDrawlist, center)
    else
        self:DrawABSNOSESCIndicators(ImDrawlist, center)
    end
end

---@param ImDrawList userdata
---@param center vec2
---@param radius number
---@param current_speed number
---@param max_speed number
---@param current_altitude number
---@param max_altitude number
function Speedometer:Draw(ImDrawList, center, radius, current_speed, max_speed, current_altitude, max_altitude)
    local is_flying = Self.Vehicle.IsPlane or Self.Vehicle.IsHeli
    local value = is_flying and current_altitude or current_speed
    local max_value = is_flying and max_altitude or max_speed
    local max_fractions = self.tick_marks or 10
    local start_angle, end_angle = -math.pi * 1.25, math.pi * 0.25

    self:GenerateTicks(radius, start_angle, end_angle, max_value, is_flying)

    local ratio = math.min(value / max_value, 1.0)
    local angle = start_angle + (end_angle - start_angle) * ratio
    local cos_a, sin_a = math.cos(angle), math.sin(angle)
    local needle_end = center + vec2:new(cos_a * radius, sin_a * radius)

    -- background
    ImGui.ImDrawListAddCircleFilled(
        ImDrawList,
        center.x,
        center.y,
        radius + 10,
        speedometer_cfg.circle_bgcolor
    )

    -- outer circle
    ImGui.ImDrawListAddCircle(
        ImDrawList,
        center.x,
        center.y,
        radius + 10,
        speedometer_cfg.circle_color,
        100,
        self.line_thickness
    )

    -- fractions
    for _, tick in ipairs(self.cached_ticks or {}) do
        local p1 = center + vec2:new(tick.x1, tick.y1)
        local p2 = center + vec2:new(tick.x2, tick.y2)

        ImGui.ImDrawListAddLine(
            ImDrawList,
            p1.x,
            p1.y,
            p2.x,
            p2.y,
            speedometer_cfg.markings_color,
            1.5
        )

        local label_pos = center + vec2:new(
            math.cos(tick.angle) * (radius - 30),
            math.sin(tick.angle) * (radius - 30)
        )
        local label = tostring(tick.value)
        local text_size = vec2:new(ImGui.CalcTextSize(label))
        local txt_draw_pos = vec2:new(
            label_pos.x - text_size.x * 0.5,
            label_pos.y - text_size.y * 0.5
        )

        ImGui.ImDrawListAddText(
            ImDrawList,
            txt_draw_pos.x,
            txt_draw_pos.y,
            speedometer_cfg.text_color,
            label
        )
    end

    -- analog needle
    for t = 0.0, 1.0, 0.25 do
        local segment = center + (needle_end - center) * t
        local thickness = self.line_thickness * (1.0 - t * 0.5)

        ImGui.ImDrawListAddLine(
            ImDrawList,
            center.x,
            center.y,
            segment.x,
            segment.y,
            speedometer_cfg.needle_color,
            thickness
        )
    end

    -- inner circle
    ImGui.ImDrawListAddCircleFilled(
        ImDrawList,
        center.x,
        center.y,
        self.line_thickness * 17.0,
        speedometer_cfg.needle_base_color
    )

    local unit_buff = (speedometer_cfg.speed_unit == 0 and "M/s") or (speedometer_cfg.speed_unit == 1 and "Km/h") or "Mi/h"
    local display_value = math.floor(current_speed)
    local value_str = tostring(display_value)
    local unit_size = self.cached_unit_sizes[unit_buff]

    if not unit_size then
        unit_size = vec2:new(ImGui.CalcTextSize(unit_buff))
        self.cached_unit_sizes[unit_buff] = unit_size
    end

    if self.font_scale ~= 1.4 then
        ImGui.SetWindowFontScale(1.4)
        self.font_scale = 1.4
    end

    local value_text_size = vec2:new(ImGui.CalcTextSize(value_str))

    ImGui.ImDrawListAddText(
        ImDrawList,
        center.x - (value_text_size.x * 0.5),
        center.y - 20,
        speedometer_cfg.text_color,
        value_str
    )

    if self.font_scale ~= 1.0 then
        ImGui.SetWindowFontScale(1.0)
        self.font_scale = 1.0
    end

    ImGui.ImDrawListAddText(
        ImDrawList,
        center.x - unit_size.x * 0.5,
        center.y + 15,
        speedometer_cfg.text_color,
        unit_buff
    )

    if Self.Vehicle.IsEngineOn then
        -- rpm/jet throttle
        local rpm_ratio = is_flying and Self.Vehicle.Throttle or Self.Vehicle.RPM
        local max_segments = 12
        local active_segments = math.floor(max_segments * rpm_ratio)
        local normalized_rpm = math.min(math.max(rpm_ratio, 0.0), 1.0)
        local r = normalized_rpm^1.2
        local g = 1.0 - normalized_rpm
        local b = 0.0
        local a = 1.0
        local rpm_color = ImU32(r, g, b, a)

        for _ = 0, active_segments - 1 do
            local rpm_angle_range = start_angle - end_angle
            local rpm_angle_end = start_angle + rpm_angle_range * rpm_ratio - 0.07

            self:DrawSmoothArc(
                ImDrawList,
                center,
                50,
                start_angle - 0.07,
                rpm_angle_end,
                rpm_color,
                2.5,
                32
            )
        end
    end

    if is_flying then
        if self.font_scale ~= 0.77 then
            ImGui.SetWindowFontScale(0.77)
            self.font_scale = 0.77
        end

        ImGui.ImDrawListAddText(
            ImDrawList,
            center.x - 43,
            center.y -80,
            speedometer_cfg.text_color,
            string.format("Altitude [%.0fm]", current_altitude)
        )
    elseif Self.Vehicle.Gear then
        if self.font_scale ~= 1.5 then
            ImGui.SetWindowFontScale(1.5)
            self.font_scale = 1.5
        end

        local gear = Self.Vehicle.Gear
        local gear_str = (gear == 0) and ((current_speed > 1 and "R") or "N") or string.format("%s%d", Self.Vehicle.IsSportsCar and "S" or "D", gear)
        local gear_color = Self.Vehicle.IsSportsCar and ImU32(1.0, 0.3, 0.3, 1.0) or speedometer_cfg.text_color
        local gear_text_width, _ = ImGui.CalcTextSize(gear_str)

        ImGui.ImDrawListAddText(
            ImDrawList,
            center.x - (gear_text_width * 0.5),
            center.y + 59,
            gear_color,
            gear_str
        )
    end

    self:DrawLowerIndicators(ImDrawList, center)
end
