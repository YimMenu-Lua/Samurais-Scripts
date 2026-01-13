local UnitCases = {
	[0] = 1,
	[1] = 3.6,
	default = 2.236936
}

---@class Speedometer
local Speedometer = {}
Speedometer.__index = Speedometer
Speedometer.cached_ticks = nil
Speedometer.cached_unit_sizes = {}
Speedometer.last_max_fractions = nil
Speedometer.last_max_value = nil
Speedometer.tick_marks = 10
Speedometer.line_thickness = 3.0
Speedometer.font_scale = 1.0
Speedometer._state = {
	should_draw = false,
	speed_modifier = 1,
	PV = nil,
	IsEngineOn = false,
	HasABS = false,
	IsABSEngaged = false,
	IsESCEngaged = false,
	IsNOSActive = false,
	IsAircraft = false,
	IsSports = false,
	IsShootingFlares = false,
	Manufacturer = "",
	NOSDangerRatio = 0.0,
	CurrentSpeed = 0,
	CurrentAltitude = 0,
	MaxSpeed = 0,
	Throttle = 0,
	RPM = 0,
	Gear = 0,
	EngineHealth = 0,
	LandingGearState = Enums.eLandingGearState.UNK
}

function Speedometer:UpdateState()
	self._state.PV = Self:GetVehicle()
	if (not self._state.PV) then
		self._state.should_draw = false
		return
	end

	self._state.speed_modifier   = Match(GVars.features.speedometer.speed_unit, UnitCases)
	self._state.CurrentSpeed     = self._state.PV:GetSpeed() * self._state.speed_modifier
	self._state.MaxSpeed         = math.floor(
		(self._state.PV:GetDefaultMaxSpeed()
			* (GVars.features.vehicle.fast_vehicles and 1.8 or 1))
		* self._state.speed_modifier
	)
	self._state.CurrentAltitude  = self._state.PV:GetHeightAboveGround()
	self._state.Manufacturer     = self._state.PV:GetManufacturerName()
	self._state.IsEngineOn       = self._state.PV:IsEngineOn()
	self._state.HasABS           = self._state.PV:HasABS()
	self._state.IsABSEngaged     = self._state.PV:IsABSEngaged()
	self._state.IsESCEngaged     = self._state.PV:IsESCEngaged()
	self._state.IsNOSActive      = self._state.PV:IsNOSActive()
	self._state.IsAircraft       = self._state.PV:IsPlane() or self._state.PV:IsHeli()
	self._state.IsSports         = self._state.PV:IsSportsOrSuper()
	self._state.IsShootingFlares = self._state.PV.m_is_shooting_flares
	self._state.Throttle         = self._state.PV:GetThrottle()
	self._state.RPM              = self._state.PV:GetRPM()
	self._state.Gear             = self._state.PV:GetCurrentGear()
	self._state.EngineHealth     = self._state.PV:GetEngineHealth()
	self._state.NOSDangerRatio   = self._state.PV:GetNOSDangerRatio()
	self._state.LandingGearState = self._state.PV:GetLandingGearState()
	self._state.should_draw      = (self._state.PV and self._state.PV:IsValid()
		and self._state.IsEngineOn
		and Self:IsDriving()
		and not Self:IsUsingPhone()
		and not Self:IsBrowsingApps()
		and not HUD.IS_PAUSE_MENU_ACTIVE()
		and not CAM.IS_SCREEN_FADING_OUT()
		and not CAM.IS_SCREEN_FADED_OUT()
	)
end

---@param radius number
---@param start_angle number
---@param end_angle number
---@param max_value number
---@param IsAircraft boolean
function Speedometer:GenerateTicks(radius, start_angle, end_angle, max_value, IsAircraft)
	local tick_step = not IsAircraft and 20 or 500
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
	if (not self._state.PV) then
		return
	end

	if (self._state.HasABS) then
		local abs_color = self._state.IsABSEngaged and Color(1.0, 0.8, 0.0, 1.0):AsU32() or
			Color(0.1, 0.1, 0.1, 0.5):AsU32()

		ImGui.ImDrawListAddText(
			ImDrawlist,
			center.x - 50,
			center.y + 100,
			abs_color,
			"ABS"
		)

		local esc_color = self._state.IsESCEngaged and Color(1.0, 0.215, 0.215, 1.0):AsU32() or
			Color(0.1, 0.1, 0.1, 0.5):AsU32()

		ImGui.ImDrawListAddText(
			ImDrawlist,
			center.x + 25,
			center.y + 100,
			esc_color,
			"ESC"
		)
	end

	if (self._state.IsNOSActive) then
		ImGui.ImDrawListAddText(
			ImDrawlist,
			center.x - 12.5,
			center.y + 100,
			Color(0.215, 0.315, 1.0, 1.0):AsU32(),
			"NOS"
		)
	end
end

---@param ImDrawlist userdata
---@param center vec2
function Speedometer:DrawAirplaneIndicators(ImDrawlist, center)
	local flare_color = self._state.IsShootingFlares and Color(0.1, 0.91, 0.0, 1.0) or Color(0.1, 0.1, 0.1, 0.5)

	ImGui.ImDrawListAddText(
		ImDrawlist,
		center.x - 50,
		center.y + 100,
		flare_color:AsU32(),
		"FLRS"
	)

	local gearState = self._state.LandingGearState
	local gear_color = (gearState > -1 and gearState < 4)
		and Color(0.91, 0.1, 0.0, 1.0) or Color(0.1, 0.1, 0.1, 0.5)

	ImGui.ImDrawListAddText(
		ImDrawlist,
		center.x + 30,
		center.y + 100,
		gear_color:AsU32(),
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

	if (self._state.IsAircraft) then
		self:DrawAirplaneIndicators(ImDrawlist, center)
	else
		self:DrawABSNOSESCIndicators(ImDrawlist, center)
	end
end

---@param ImDrawList userdata
---@param center vec2
---@param radius number
function Speedometer:DrawEngineWarning(ImDrawList, center, radius)
	if (self._state.EngineHealth < 800) then
		local pulse = 0.5 + 0.5 * math.sin(Time.now() * 5)
		local color = Color(1, self._state.EngineHealth < 400 and pulse or 0.9, 0, 1):AsU32()
		local offset = vec2:new(-radius + 72, 15)
		local p1 = center + offset + vec2:new(0, -7)
		local p2 = center + offset + vec2:new(-12, 12)
		local p3 = center + offset + vec2:new(12, 12)
		ImGui.ImDrawListAddTriangle(ImDrawList, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, color)
		ImGui.ImDrawListAddText(ImDrawList, p1.x - 1, p1.y + 2.8, color, "!")
		ImGui.ImDrawListAddText(ImDrawList, 11.2, p1.x - 30, p1.y + 25, color, "CHECK ENGINE")
	end
end

---@param ImDrawList userdata
---@param center vec2
---@param radius number
---@param current_speed number
---@param max_speed number
---@param current_altitude number
---@param max_altitude number
function Speedometer:DrawImpl(ImDrawList, center, radius, current_speed, max_speed, current_altitude, max_altitude)
	local value = self._state.IsAircraft and current_altitude or current_speed
	local max_value = self._state.IsAircraft and max_altitude or max_speed
	local max_fractions = self.tick_marks or 10
	local start_angle, end_angle = -math.pi * 1.25, math.pi * 0.25

	self:GenerateTicks(radius, start_angle, end_angle, max_value, self._state.IsAircraft)

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
		GVars.features.speedometer.colors.circle_bg
	)

	-- outer circle
	ImGui.ImDrawListAddCircle(
		ImDrawList,
		center.x,
		center.y,
		radius + 10,
		GVars.features.speedometer.colors.circle,
		100,
		self.line_thickness
	)

	-- if IsNOSActive() then -- TODO: Replace with crash detection + red-ish color
	--     local alpha = 0.3 + 0.2 * math.sin(Time.now() * 8)
	--     ImGui.ImDrawListAddCircleFilled(ImDrawList, center.x, center.y, radius + 10, Color(0.215, 0.315, 1, alpha):AsU32())
	-- end

	-- check engine
	if (not self._state.IsAircraft) then
		if (type(self._state.Manufacturer) == "string") then
			local textWidth = ImGui.CalcTextSize(self._state.Manufacturer)
			ImGui.ImDrawListAddText(
				ImDrawList,
				19.5,
				center.x - 5 - (textWidth / 2),
				center.y - 15 - (radius / 2),
				GVars.features.speedometer.colors.text - (math.pi * 10),
				self._state.Manufacturer
			)
		end
		self:DrawEngineWarning(ImDrawList, center, radius)
	end

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
			GVars.features.speedometer.colors.markings,
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
			GVars.features.speedometer.colors.text,
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
			GVars.features.speedometer.colors.needle,
			thickness
		)
	end

	-- inner circle
	ImGui.ImDrawListAddCircleFilled(
		ImDrawList,
		center.x,
		center.y,
		self.line_thickness * 17.0,
		GVars.features.speedometer.colors.needle_base
	)

	local unit_buff = (GVars.features.speedometer.speed_unit == 0 and "M/s") or
		(GVars.features.speedometer.speed_unit == 1 and "Km/h") or "Mi/h"
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
		GVars.features.speedometer.colors.text,
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
		GVars.features.speedometer.colors.text,
		unit_buff
	)

	if (self._state.IsEngineOn) then
		-- rpm/jet throttle
		local rpm_ratio = self._state.IsAircraft and self._state.Throttle or self._state.RPM
		local max_segments = 12
		local active_segments = math.floor(max_segments * rpm_ratio)
		local normalized_rpm = math.min(math.max(rpm_ratio, 0.0), 1.0)
		local r = normalized_rpm ^ 1.2
		local g = 1.0 - normalized_rpm
		local b = 0.0
		local a = 1.0
		local rpm_color = Color(r, g, b, a):AsU32()

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

	if (self._state.IsAircraft) then
		if self.font_scale ~= 0.77 then
			ImGui.SetWindowFontScale(0.77)
			self.font_scale = 0.77
		end

		ImGui.ImDrawListAddText(
			ImDrawList,
			center.x - 43,
			center.y - 80,
			GVars.features.speedometer.colors.text,
			_F("Altitude [%.0fm]", current_altitude)
		)
	elseif (self._state.Gear) then
		if (self.font_scale ~= 1.5) then
			ImGui.SetWindowFontScale(1.5)
			self.font_scale = 1.5
		end

		local gear_str = (self._state.Gear == 0) and ((current_speed > 1 and "R") or "N") or
			_F("%s%d", self._state.IsSports and "S" or "D", self._state.Gear)
		local gear_color = self._state.IsSports and Color(1.0, 0.3, 0.3, 1.0):AsU32() or
			GVars.features.speedometer.colors.text
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

---@param offset? float
function Speedometer:Draw(offset)
	if (not Self:IsDriving() or not GVars.features.speedometer.enabled) then
		return
	end

	local radius = 150
	local resolution = Game.GetScreenResolution()
	if (GVars.features.speedometer.pos:is_zero()) then
		GVars.features.speedometer.pos.x = resolution.x - (radius * 2.5)
		GVars.features.speedometer.pos.y = resolution.y - (radius * 3.5)
	end

	local windowFlags = ImGuiWindowFlags.NoTitleBar
		| ImGuiWindowFlags.NoResize
		| ImGuiWindowFlags.NoScrollbar
		| ImGuiWindowFlags.NoScrollWithMouse
		| ImGuiWindowFlags.NoCollapse
		| ImGuiWindowFlags.NoMove

	-- RIP Paul Walker
	if (self._state.NOSDangerRatio >= 0.8) then
		local window_width = radius * 1.3
		local pulse = 0.5 + 0.5 * math.sin(Time.now() * 12)
		ImGui.SetNextWindowSize(window_width, 100, ImGuiCond.Always)
		ImGui.SetNextWindowPos(
			GVars.features.speedometer.pos.x + radius * 0.7,
			GVars.features.speedometer.pos.y - 120,
			ImGuiCond.Always
		)
		ImGui.PushStyleColor(ImGuiCol.WindowBg, 1, pulse, 0.02, 0.9)
		ImGui.PushStyleColor(ImGuiCol.Text, 0.1, 0.1, 0.1, 1.0)
		if (ImGui.Begin("##dangertomanifold", windowFlags)) then
			ImGui.SetWindowFontScale(1.4)
			local wrn_width = ImGui.CalcTextSize("Warning!!!")
			ImGui.SetCursorPosX((window_width - wrn_width) / 2)
			ImGui.Text("Warning!!!")
			ImGui.SetWindowFontScale(1.2)
			ImGui.Text("Danger to Manifold")
			ImGui.SetWindowFontScale(1.0)
			ImGui.End()
		end
		ImGui.PopStyleColor(2)
	end

	ImGui.SetNextWindowBgAlpha(0.0)
	ImGui.SetNextWindowSize(radius * 2.5, radius * 2)
	ImGui.SetNextWindowPos(GVars.features.speedometer.pos.x, GVars.features.speedometer.pos.y, ImGuiCond.Always)
	if ImGui.Begin("##SpeedometerWindow", windowFlags | ImGuiWindowFlags.NoBackground) then
		if (not self._state.should_draw) then
			ImGui.End()
			return
		end

		local pos_offset = offset or 0.0
		local ImDrawList = ImGui.GetWindowDrawList()
		local window_pos = vec2:new(ImGui.GetWindowPos())
		local window_size = vec2:new(ImGui.GetWindowSize())
		local center = window_pos + window_size * 0.5 + pos_offset
		local max_altitude = 2500
		center.y = center.y + 11

		self:DrawImpl(
			ImDrawList,
			center,
			radius,
			self._state.CurrentSpeed,
			self._state.MaxSpeed,
			self._state.CurrentAltitude,
			max_altitude
		)
		ImGui.End()
	end
end

GUI:RegisterIndependentGUI(function()
	Speedometer:Draw()
end)

return Speedometer
