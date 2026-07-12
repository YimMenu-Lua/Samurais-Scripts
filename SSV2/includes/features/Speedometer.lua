-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local gui_registered           = false
local last_engine_state        = true
local last_captured_top_spd    = 0.0
local RUNTIME_COLORS <const>   = {
	INDICATOR_RED   = Color(1.0, 0.215, 0.215, 1.0):AsU32(),
	INDICATOR_GREEN = Color(0.1, 0.91, 0.0, 1.0):AsU32(),
	INDICATOR_BLUE  = Color(0.215, 0.315, 1.0, 1.0):AsU32(),
	INDICATOR_AMBER = Color(1.0, 0.8, 0.0, 1.0):AsU32(),
	INDICATOR_OFF   = Color(0.1, 0.1, 0.1, 0.55):AsU32(),
	CIRCLE_BG       = 1711868169
}
local UNIT_MULTIPLIERS <const> = {
	[0]     = 1,
	[1]     = 3.6,
	default = 2.236936
}
local windowFlags              = ImGuiWindowFlags.NoTitleBar
	| ImGuiWindowFlags.NoResize
	| ImGuiWindowFlags.NoScrollbar
	| ImGuiWindowFlags.NoScrollWithMouse
	| ImGuiWindowFlags.NoCollapse
	| ImGuiWindowFlags.NoMove

---@param col uint32_t
---@param alpha integer
---@return uint32_t
local function set_u32_alpha(col, alpha)
	alpha = math.clamp(math.floor(alpha), 0, 255)
	return (col & 0xFFFFFF) | (alpha << 0x18)
end

---@param veh PlayerVehicle
---@return boolean
local function get_is_tc_esc_dsabled(veh)
	return veh:GetAdvancedFlag(Enums.eVehicleAdvancedFlags.DISABLE_TRACTION_CONTROL)
		or veh:GetAdvancedFlag(Enums.eVehicleAdvancedFlags.DISABLE_STABILITY_CONTROL)
end


---@class Speedometer
---@field private m_cached_ticks { x1: float, y1: float, x2: float, y2: float, angle: float, value: integer }
---@field private m_cached_unit_sizes dict<vec2>
---@field private m_last_max_fractions integer
---@field private m_last_max_value integer
---@field private m_tick_marks integer
---@field private m_line_thickness float
---@field private m_font_scale float
local Speedometer   = {
	m_cached_ticks       = {},
	m_cached_unit_sizes  = {},
	m_last_max_fractions = 0,
	m_last_max_value     = 0,
	m_tick_marks         = 10,
	m_line_thickness     = 3.0,
	m_font_scale         = 1.0,

	---@public
	_state               = {
		should_draw      = false,
		speed_modifier   = 1,
		PV               = nil, ---@type PlayerVehicle
		IsEngineOn       = false,
		IsSingleGear     = false,
		HasABS           = false,
		IsABSEngaged     = false,
		IsESCEngaged     = false,
		IsESCDisabled    = false,
		IsNOSActive      = false,
		IsAircraft       = false,
		IsSports         = false,
		IsShootingFlares = false,
		IsReversing      = false,
		IsStopped        = false,
		Manufacturer     = "",
		GearName         = "",
		NOSDangerRatio   = 0.0,
		CurrentSpeed     = 0,
		CurrentAltitude  = 0,
		MaxSpeed         = 0,
		Throttle         = 0,
		RPM              = 0,
		Gear             = 0,
		EngineHealth     = 0,
		LandingGearState = Enums.eLandingGearState.UNK
	}
}; Speedometer.__index = Speedometer

---@public
---@param PV PlayerVehicle
function Speedometer:UpdateState(PV)
	local state = self._state
	if not (PV and PV:IsValid()) then
		state.should_draw = false
		return
	end

	local speed_modifier = Match(GVars.features.speedometer.speed_unit, UNIT_MULTIPLIERS)
	local IsEngineOn     = PV:IsEngineOn()
	local IsNosActive    = PV:IsNOSActive()
	if (not IsNosActive) then
		last_captured_top_spd = PV:GetMaxSpeed()
	end

	state.PV               = PV
	state.speed_modifier   = speed_modifier
	state.CurrentSpeed     = PV:GetSpeed() * speed_modifier
	state.MaxSpeed         = math.ceil(last_captured_top_spd * speed_modifier)
	state.CurrentAltitude  = PV:GetHeightAboveGround()
	state.Manufacturer     = PV:GetManufacturerName()
	state.IsEngineOn       = IsEngineOn
	state.IsSingleGear     = PV.m_manual_gearbox:IsSingleGear()
	state.HasABS           = PV:HasABS()
	state.IsABSEngaged     = PV:IsABSEngaged()
	state.IsESCEngaged     = PV:IsESCEngaged()
	state.IsESCDisabled    = get_is_tc_esc_dsabled(PV)
	state.IsNOSActive      = IsNosActive
	state.IsAircraft       = PV:IsPlane() or PV:IsHeli()
	state.IsSports         = PV:IsSportsOrSuper()
	state.IsShootingFlares = PV.m_is_shooting_flares
	state.Throttle         = math.max(0.1, PV:GetThrottle())
	state.RPM              = PV:GetRPM()
	state.Gear             = PV:GetCurrentGear()
	state.GearName         = PV:GetCurrentGearName()
	state.EngineHealth     = PV:GetEngineHealth()
	state.NOSDangerRatio   = PV:GetNOSDangerRatio()
	state.LandingGearState = PV:GetLandingGearState()
	state.IsReversing      = PV:IsReversing()
	state.IsStopped        = PV:IsStopped()
	state.should_draw      = (PV and PV:IsValid())
		and LocalPlayer:IsDriving()
		and LocalPlayer:IsOutside()
		and not LocalPlayer:IsUsingPhone()
		and not LocalPlayer:IsBrowsingApps()
		and not HUD.IS_PAUSE_MENU_ACTIVE()
		and not CAM.IS_SCREEN_FADING_OUT()
		and not CAM.IS_SCREEN_FADED_OUT()
end

---@private
---@param scale float
function Speedometer:SetFontScale(scale)
	if (self.m_font_scale ~= scale) then
		self.m_font_scale = scale
		ImGui.SetWindowFontScale(scale)
	end
end

---@private
function Speedometer:ResetFontScale()
	if (self.m_font_scale == 1.0) then
		return
	end

	self.m_font_scale = 1.0
	ImGui.SetWindowFontScale(1.0)
end

function Speedometer:HandleVisibility()
	local engine_state = self._state.IsEngineOn
	if (last_engine_state == engine_state) then
		return
	end

	last_engine_state        = engine_state
	local target_bg_alpha    = engine_state and 1.0 or 0.35
	local target_fg_alpha    = engine_state and 0.52 or 0.78
	local user_colors        = GVars.features.speedometer.colors
	RUNTIME_COLORS.CIRCLE_BG = set_u32_alpha(RUNTIME_COLORS.CIRCLE_BG, target_fg_alpha * 255)

	for k, user_col in pairs(user_colors) do
		if (k ~= "needle_base") then
			user_colors[k] = set_u32_alpha(user_col, target_bg_alpha * 255)
		end
	end
end

---@private
---@param radius number
---@param start_angle number
---@param end_angle number
---@param max_value number
---@param IsAircraft boolean
function Speedometer:GenerateTicks(radius, start_angle, end_angle, max_value, IsAircraft)
	local tick_step     = not IsAircraft and 20 or 500
	local max_fractions = math.ceil(max_value / tick_step) * tick_step
	if (self.m_last_max_fractions == max_fractions and self.m_last_max_value == max_value) then
		return
	end

	self.m_last_max_fractions = max_fractions
	self.m_last_max_value     = max_value
	self.m_cached_ticks       = {}

	for i = 0, max_fractions, tick_step do
		local fraction     = i / max_fractions
		local angle        = start_angle + (end_angle - start_angle) * fraction
		local sin_a, cos_a = math.sin(angle), math.cos(angle)
		table.insert(self.m_cached_ticks, {
			x1    = cos_a * (radius - 10),
			y1    = sin_a * (radius - 10),
			x2    = cos_a * radius,
			y2    = sin_a * radius,
			angle = angle,
			value = i,
		})
	end
end

---@private
---@param ImDrawlist userdata
---@param center vec2
function Speedometer:DrawABSNOSESCIndicators(ImDrawlist, center)
	local state = self._state
	if (not state.PV) then return end

	local engine_on = state.IsEngineOn
	local pos_y     = center.y + 100
	if (state.HasABS) then
		local abs_color = (engine_on and state.IsABSEngaged) and RUNTIME_COLORS.INDICATOR_AMBER or RUNTIME_COLORS.INDICATOR_OFF
		ImGui.ImDrawListAddText(
			ImDrawlist,
			center.x - 60,
			pos_y,
			abs_color,
			"ABS"
		)


		local esc_color = (engine_on and state.IsESCEngaged) and RUNTIME_COLORS.INDICATOR_RED or RUNTIME_COLORS.INDICATOR_OFF
		local esc_txt   = "TC ESC"
		if (state.IsESCDisabled) then
			esc_color = RUNTIME_COLORS.INDICATOR_RED
			esc_txt   = "TC/ESC OFF"
		end

		ImGui.ImDrawListAddText(
			ImDrawlist,
			center.x + 19,
			pos_y,
			esc_color,
			esc_txt
		)
	end

	if (state.IsNOSActive) then
		ImGui.ImDrawListAddText(
			ImDrawlist,
			center.x - 20,
			pos_y,
			RUNTIME_COLORS.INDICATOR_BLUE,
			"NOS"
		)
	end
end

---@private
---@param ImDrawlist userdata
---@param center vec2
function Speedometer:DrawAirplaneIndicators(ImDrawlist, center)
	local state       = self._state
	local flare_color = state.IsShootingFlares and RUNTIME_COLORS.INDICATOR_GREEN or RUNTIME_COLORS.INDICATOR_OFF
	ImGui.ImDrawListAddText(
		ImDrawlist,
		center.x - 50,
		center.y + 100,
		flare_color,
		"FLRS"
	)

	local gearState  = state.LandingGearState
	local gear_color = (gearState > -1 and gearState < 4) and RUNTIME_COLORS.INDICATOR_RED or RUNTIME_COLORS.INDICATOR_OFF
	ImGui.ImDrawListAddText(
		ImDrawlist,
		center.x + 30,
		center.y + 100,
		gear_color,
		"GEAR"
	)
end

---@private
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

---@private
---@param ImDrawlist userdata
---@param center vec2
function Speedometer:DrawLowerIndicators(ImDrawlist, center)
	self:SetFontScale(0.77)
	if (self._state.IsAircraft) then
		self:DrawAirplaneIndicators(ImDrawlist, center)
	else
		self:DrawABSNOSESCIndicators(ImDrawlist, center)
	end
end

---@private
---@param ImDrawList userdata
---@param center vec2
---@param radius number
function Speedometer:DrawEngineWarning(ImDrawList, center, radius)
	local state  = self._state
	local health = state.EngineHealth
	if (not state.IsEngineOn or health > 800) then
		return
	end

	local pulse  = 0.5 + 0.5 * math.sin(Time.Now() * 5)
	local color  = Color(1, health < 400 and pulse or 0.9, 0, 1):AsU32()
	local offset = vec2:new(-radius + 100, 45)
	local p1     = center + offset + vec2:new(0, -5)
	local p2     = center + offset + vec2:new(-10, 10)
	local p3     = center + offset + vec2:new(10, 10)
	ImGui.ImDrawListAddTriangle(ImDrawList, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, color)
	ImGui.ImDrawListAddText(ImDrawList, p1.x - 1, p1.y + 2.8, color, "!")
	ImGui.ImDrawListAddText(ImDrawList, 11.2, p1.x - 30, p1.y + 20, color, "CHECK ENGINE")
end

---@private
---@param ImDrawList userdata
---@param center vec2
---@param radius number
---@param current_speed number
---@param max_speed number
---@param current_altitude number
---@param max_altitude number
function Speedometer:DrawImpl(ImDrawList, center, radius, current_speed, max_speed, current_altitude, max_altitude)
	local state                  = self._state
	local value                  = state.IsAircraft and current_altitude or current_speed
	local max_value              = state.IsAircraft and max_altitude or max_speed
	local start_angle, end_angle = -math.pi * 1.25, math.pi * 0.25
	local cgf_colors             = GVars.features.speedometer.colors

	self:GenerateTicks(radius, start_angle, end_angle, max_value, state.IsAircraft)

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
		RUNTIME_COLORS.CIRCLE_BG
	)

	-- outer circle
	ImGui.ImDrawListAddCircle(
		ImDrawList,
		center.x,
		center.y,
		radius + 10,
		cgf_colors.circle,
		100,
		self.m_line_thickness
	)

	-- if IsNOSActive() then -- TODO: Replace with crash detection + red-ish color
	--     local alpha = 0.3 + 0.2 * math.sin(Time.now() * 8)
	--     ImGui.ImDrawListAddCircleFilled(ImDrawList, center.x, center.y, radius + 10, Color(0.215, 0.315, 1, alpha):AsU32())
	-- end

	-- check engine
	if (not state.IsAircraft) then
		local mfr = state.Manufacturer
		if (string.isvalid(mfr)) then
			local textWidth = ImGui.CalcTextSize(mfr)
			ImGui.ImDrawListAddText(
				ImDrawList,
				19.5,
				center.x - 5 - (textWidth / 2),
				center.y - 15 - (radius / 2),
				cgf_colors.text - (math.pi * 10),
				mfr
			)
		end
		self:DrawEngineWarning(ImDrawList, center, radius)
	end

	-- fractions
	for _, tick in ipairs(self.m_cached_ticks) do
		local p1 = center + vec2:new(tick.x1, tick.y1)
		local p2 = center + vec2:new(tick.x2, tick.y2)

		ImGui.ImDrawListAddLine(
			ImDrawList,
			p1.x,
			p1.y,
			p2.x,
			p2.y,
			cgf_colors.markings,
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
			cgf_colors.text,
			label
		)
	end

	-- analog needle
	for t = 0.0, 1.0, 0.25 do
		local segment = center + (needle_end - center) * t
		local thickness = self.m_line_thickness * (1.0 - t * 0.5)

		ImGui.ImDrawListAddLine(
			ImDrawList,
			center.x,
			center.y,
			segment.x,
			segment.y,
			cgf_colors.needle,
			thickness
		)
	end

	-- inner circle
	ImGui.ImDrawListAddCircleFilled(
		ImDrawList,
		center.x,
		center.y,
		self.m_line_thickness * 17.0,
		cgf_colors.needle_base
	)

	local unit      = GVars.features.speedometer.speed_unit
	local unit_buff = (unit == 0 and "M/s") or (unit == 1 and "Km/h") or "Mi/h"
	local value_str = tostring(state.IsEngineOn and math.floor(current_speed) or 0)
	local unit_size = self.m_cached_unit_sizes[unit_buff]

	if (not unit_size) then
		unit_size = vec2:new(ImGui.CalcTextSize(unit_buff))
		self.m_cached_unit_sizes[unit_buff] = unit_size
	end

	self:SetFontScale(1.4)
	local value_text_size = vec2:new(ImGui.CalcTextSize(value_str))
	ImGui.ImDrawListAddText(
		ImDrawList,
		center.x - (value_text_size.x * 0.5),
		center.y - 20,
		cgf_colors.text,
		value_str
	)

	self:ResetFontScale()
	ImGui.ImDrawListAddText(
		ImDrawList,
		center.x - unit_size.x * 0.5,
		center.y + 15,
		cgf_colors.text,
		unit_buff
	)

	local IsAircraft = state.IsAircraft
	if (state.IsEngineOn) then
		-- rpm/jet throttle
		local rpm_ratio       = IsAircraft and state.Throttle or state.RPM
		local max_segments    = 12
		local active_segments = math.floor(max_segments * rpm_ratio)
		local normalized_rpm  = math.min(math.max(rpm_ratio, 0.0), 1.0)
		local r               = normalized_rpm ^ 1.2
		local g               = 1.0 - normalized_rpm
		local b               = 0.0
		local a               = 1.0
		local rpm_color       = Color(r, g, b, a):AsU32()

		for _ = 0, active_segments - 1 do
			local rpm_angle_range = start_angle - end_angle
			local rpm_angle_end   = start_angle + rpm_angle_range * rpm_ratio - 0.07

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

	local gear     = state.Gear
	local text_col = cgf_colors.text
	if (IsAircraft) then
		self:SetFontScale(0.77)
		ImGui.ImDrawListAddText(
			ImDrawList,
			center.x - 43,
			center.y - 80,
			text_col,
			_F("Altitude [%.0fm]", current_altitude)
		)
	elseif (gear) then
		self:SetFontScale(1.5)
		local gear_name = state.GearName
		local gear_str  = gear_name
		local IsSports  = state.IsSports
		if (gear > 0 and gear < 255) then
			local gbox_cfg = GVars.features.vehicle.manual_gearbox
			local mode = gbox_cfg.mode
			if (gbox_cfg.enabled and mode < 2 and not state.IsSingleGear) then
				gear_str = mode == 0 and gear_name or _F("S%s", gear_name)
			else
				gear_str = _F("D%s", gear_name)
			end
		end

		local gear_color      = IsSports and RUNTIME_COLORS.INDICATOR_RED or text_col
		local gear_text_width = ImGui.CalcTextSize(gear_str)
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

---@public
---@param offset? float
function Speedometer:Draw(offset)
	local state = self._state
	local cfg = GVars.features.speedometer
	if not (cfg.enabled and state.should_draw) then
		return
	end

	self:HandleVisibility()

	local pos        = cfg.pos
	local radius     = 150
	local resolution = GPointers.ScreenResolution
	if (pos.x == 0 and pos.y == 0) then
		pos.x = resolution.x - (radius * 2.5)
		pos.y = resolution.y - (radius * 3.5)
	end

	-- RIP Paul Walker
	if (state.NOSDangerRatio >= 0.8) then
		local width = radius * 1.3
		local pulse = 0.5 + 0.5 * math.sin(Time.Now() * 12)
		ImGui.SetNextWindowSize(width, 100, ImGuiCond.Always)
		ImGui.SetNextWindowPos(pos.x + radius * 0.7, pos.y - 120, ImGuiCond.Always)
		ImGui.PushStyleColor(ImGuiCol.WindowBg, 1, pulse, 0.02, 0.9)
		ImGui.PushStyleColor(ImGuiCol.Text, 0.1, 0.1, 0.1, 1.0)
		if (ImGui.Begin("##dangertomanifold", windowFlags)) then
			ImGui.SetWindowFontScale(1.4)
			local title     = "Warning!!!"
			local wrn_width = ImGui.CalcTextSize(title)
			ImGui.SetCursorPosX((width - wrn_width) / 2)
			ImGui.Text(title)
			ImGui.SetWindowFontScale(1.2)
			ImGui.Text("Danger to Manifold")
			ImGui.SetWindowFontScale(1.0)
			ImGui.End()
		end
		ImGui.PopStyleColor(2)
	end

	ImGui.SetNextWindowBgAlpha(0.0)
	ImGui.SetNextWindowSize(radius * 2.5, radius * 2)
	ImGui.SetNextWindowPos(pos.x, pos.y, ImGuiCond.Always)
	if (ImGui.Begin("##SpeedometerWindow", windowFlags | ImGuiWindowFlags.NoBackground)) then
		if (not state.should_draw) then
			ImGui.End()
			return
		end

		local pos_offset   = offset or 0.0
		local ImDrawList   = ImGui.GetWindowDrawList()
		local window_pos   = vec2:new(ImGui.GetWindowPos())
		local window_size  = vec2:new(ImGui.GetWindowSize())
		local center       = window_pos + window_size * 0.5 + pos_offset
		local max_altitude = 2500
		center.y           = center.y + 11

		self:DrawImpl(
			ImDrawList,
			center,
			radius,
			state.CurrentSpeed,
			state.MaxSpeed,
			state.CurrentAltitude,
			max_altitude
		)
		ImGui.End()
	end
end

if (not gui_registered) then
	gui_registered = true
	GUI:RegisterIndependentGUI(function() Speedometer:Draw() end)
end

return Speedometer
