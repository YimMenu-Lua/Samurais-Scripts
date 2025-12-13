---@diagnostic disable: param-type-mismatch

---@class ThemeColors
---@field WindowBg vec4
---@field ChildBg vec4
---@field PopupBg vec4
---@field Header vec4
---@field HeaderHovered vec4
---@field HeaderActive vec4
---@field Button vec4
---@field ButtonHovered vec4
---@field ButtonActive vec4
---@field FrameBg vec4
---@field FrameBgHovered vec4
---@field FrameBgActive vec4
---@field Tab vec4
---@field TabHovered vec4
---@field TabActive vec4
---@field CheckMark vec4
---@field SliderGrab vec4
---@field SliderGrabActive vec4
---@field Text vec4
---@field TextDisabled vec4

---@class ThemeStyles
---@field WindowRounding integer
---@field FrameRounding integer
---@field GrabRounding integer
---@field ScrollbarRounding integer
---@field TabRounding integer
---@field WindowBorderSize integer
---@field FrameBorderSize integer
---@field PopupBorderSize integer
---@field ItemSpacing vec2
---@field FramePadding vec2

---@class Theme
---@field Name string
---@field Colors ThemeColors
---@field Styles ThemeStyles
---@field TopBarFrameCol1 vec4
---@field TopBarFrameCol2 vec4
---@overload fun(name: string, colors: ThemeColors, styles: ThemeStyles, topBarGradient1: vec4, topBarGradient2: vec4): Theme
local Theme = {}
Theme.__index = Theme
setmetatable(Theme, {
	__call = function(_, ...)
		return Theme.new(...)
	end
})

---@param name string
---@param colors? ThemeColors
---@param styles? ThemeStyles
---@param topBarGradient1? vec4
---@param topBarGradient2? vec4
function Theme.new(name, colors, styles, topBarGradient1, topBarGradient2)
	local t = {
		Name = name,
		Colors = {
			WindowBg         = colors and colors.WindowBg or vec4:zero(),
			ChildBg          = colors and colors.ChildBg or vec4:zero(),
			PopupBg          = colors and colors.PopupBg or vec4:zero(),
			Header           = colors and colors.Header or vec4:zero(),
			HeaderHovered    = colors and colors.HeaderHovered or vec4:zero(),
			HeaderActive     = colors and colors.HeaderActive or vec4:zero(),
			Button           = colors and colors.Button or vec4:zero(),
			ButtonHovered    = colors and colors.ButtonHovered or vec4:zero(),
			ButtonActive     = colors and colors.ButtonActive or vec4:zero(),
			FrameBg          = colors and colors.FrameBg or vec4:zero(),
			FrameBgHovered   = colors and colors.FrameBgHovered or vec4:zero(),
			FrameBgActive    = colors and colors.FrameBgActive or vec4:zero(),
			Tab              = colors and colors.Tab or vec4:zero(),
			TabHovered       = colors and colors.TabHovered or vec4:zero(),
			TabActive        = colors and colors.TabActive or vec4:zero(),
			CheckMark        = colors and colors.CheckMark or vec4:zero(),
			SliderGrab       = colors and colors.SliderGrab or vec4:zero(),
			SliderGrabActive = colors and colors.SliderGrabActive or vec4:zero(),
			Text             = colors and colors.Text or vec4:zero(),
			TextDisabled     = colors and colors.TextDisabled or vec4:zero(),
		},
		Styles = {
			WindowRounding    = styles and styles.WindowRounding or 0,
			FrameRounding     = styles and styles.FrameRounding or 0,
			GrabRounding      = styles and styles.GrabRounding or 0,
			ScrollbarRounding = styles and styles.ScrollbarRounding or 0,
			TabRounding       = styles and styles.TabRounding or 0,
			WindowBorderSize  = styles and styles.WindowBorderSize or 0,
			FrameBorderSize   = styles and styles.FrameBorderSize or 0,
			PopupBorderSize   = styles and styles.PopupBorderSize or 0,
			ItemSpacing       = styles and styles.ItemSpacing or vec2:zero(),
			FramePadding      = styles and styles.FramePadding or vec2:zero(),
		},
		TopBarFrameCol1 = topBarGradient1 or vec4:zero(),
		TopBarFrameCol2 = topBarGradient2 or vec4:zero()
	}

	return setmetatable(t, Theme)
end

---@class ThemeLibrary
---@field Tenebris Theme
---@field MidnightNeon Theme
---@field SilverLight Theme
local ThemeLibrary <const> = {
	Tenebris = {
		Name = "Tenebris",
		Colors = {
			WindowBg         = vec4:new(0.10, 0.11, 0.12, 0.94),
			ChildBg          = vec4:new(0.11, 0.12, 0.13, 0.94),
			PopupBg          = vec4:new(0.09, 0.10, 0.11, 0.92),

			Header           = vec4:new(0.20, 0.22, 0.25, 0.80),
			HeaderHovered    = vec4:new(0.27, 0.30, 0.34, 0.90),
			HeaderActive     = vec4:new(0.33, 0.37, 0.42, 1.00),

			Button           = vec4:new(0.18, 0.20, 0.23, 0.85),
			ButtonHovered    = vec4:new(0.28, 0.30, 0.34, 0.95),
			ButtonActive     = vec4:new(0.23, 0.25, 0.29, 1.00),

			FrameBg          = vec4:new(0.14, 0.15, 0.17, 0.90),
			FrameBgHovered   = vec4:new(0.20, 0.21, 0.23, 0.95),
			FrameBgActive    = vec4:new(0.23, 0.24, 0.26, 1.00),

			Tab              = vec4:new(0.17, 0.18, 0.20, 0.86),
			TabHovered       = vec4:new(0.27, 0.29, 0.32, 1.00),
			TabActive        = vec4:new(0.25, 0.27, 0.30, 1.00),

			CheckMark        = vec4:new(0.36, 0.50, 0.90, 1.00),
			SliderGrab       = vec4:new(0.33, 0.40, 0.85, 0.80),
			SliderGrabActive = vec4:new(0.42, 0.48, 0.95, 1.00),

			Text             = vec4:new(0.95, 0.96, 0.97, 1.00),
			TextDisabled     = vec4:new(0.50, 0.52, 0.54, 1.00),
		},

		Styles = {
			WindowRounding    = 6,
			FrameRounding     = 5,
			GrabRounding      = 4,
			ScrollbarRounding = 6,
			TabRounding       = 5,
			WindowBorderSize  = 0,
			FrameBorderSize   = 0,
			PopupBorderSize   = 0,
			ItemSpacing       = vec2:new(10, 10),
			FramePadding      = vec2:new(5, 6),
		},

		TopBarFrameCol1 = vec4:new(0.36, 0.50, 0.90, 1.00),
		TopBarFrameCol2 = vec4:new(0.33, 0.40, 0.85, 0.80)
	},

	MidnightNeon = {
		Name = "MidnightNeon",
		Colors = {
			WindowBg         = vec4:new(0.06, 0.06, 0.08, 0.95),
			ChildBg          = vec4:new(0.07, 0.07, 0.09, 0.95),
			PopupBg          = vec4:new(0.05, 0.05, 0.08, 0.92),

			Header           = vec4:new(0.13, 0.10, 0.20, 0.80),
			HeaderHovered    = vec4:new(0.18, 0.14, 0.30, 0.95),
			HeaderActive     = vec4:new(0.22, 0.16, 0.40, 1.00),

			Button           = vec4:new(0.10, 0.15, 0.18, 0.90),
			ButtonHovered    = vec4:new(0.15, 0.22, 0.26, 0.95),
			ButtonActive     = vec4:new(0.11, 0.18, 0.22, 1.00),

			FrameBg          = vec4:new(0.08, 0.10, 0.12, 0.90),
			FrameBgHovered   = vec4:new(0.12, 0.15, 0.18, 0.95),
			FrameBgActive    = vec4:new(0.14, 0.17, 0.20, 1.00),

			Tab              = vec4:new(0.10, 0.08, 0.12, 0.80),
			TabHovered       = vec4:new(0.20, 0.14, 0.30, 1.00),
			TabActive        = vec4:new(0.15, 0.11, 0.22, 1.00),

			CheckMark        = vec4:new(0.00, 0.85, 0.80, 1.00),
			SliderGrab       = vec4:new(0.60, 0.10, 0.90, 0.80),
			SliderGrabActive = vec4:new(0.75, 0.20, 1.00, 1.00),

			Text             = vec4:new(0.92, 0.95, 0.98, 1.00),
			TextDisabled     = vec4:new(0.40, 0.40, 0.45, 1.00),
		},

		Styles = {
			WindowRounding    = 8,
			FrameRounding     = 6,
			GrabRounding      = 6,
			TabRounding       = 6,
			ScrollbarRounding = 8,
			WindowBorderSize  = 0,
			FrameBorderSize   = 0,
			PopupBorderSize   = 0,
			ItemSpacing       = vec2:new(10, 10),
			FramePadding      = vec2:new(5, 6),
		},

		TopBarFrameCol1 = vec4:new(0.00, 0.85, 0.80, 1.00),
		TopBarFrameCol2 = vec4:new(0.60, 0.10, 0.90, 0.80)
	},

	SilverLight = {
		Name = "SilverLight",
		Colors = {
			WindowBg         = vec4:new(0.92, 0.93, 0.94, 1.00),
			ChildBg          = vec4:new(0.95, 0.96, 0.97, 1.00),
			PopupBg          = vec4:new(0.98, 0.98, 0.99, 1.00),

			Header           = vec4:new(0.75, 0.78, 0.82, 1.00),
			HeaderHovered    = vec4:new(0.70, 0.73, 0.77, 1.00),
			HeaderActive     = vec4:new(0.65, 0.68, 0.72, 1.00),

			Button           = vec4:new(0.75, 0.77, 0.80, 1.00),
			ButtonHovered    = vec4:new(0.70, 0.72, 0.75, 1.00),
			ButtonActive     = vec4:new(0.65, 0.67, 0.70, 1.00),

			FrameBg          = vec4:new(0.82, 0.83, 0.85, 1.00),
			FrameBgHovered   = vec4:new(0.77, 0.78, 0.80, 1.00),
			FrameBgActive    = vec4:new(0.72, 0.73, 0.75, 1.00),

			Tab              = vec4:new(0.82, 0.82, 0.85, 1.00),
			TabHovered       = vec4:new(0.75, 0.75, 0.78, 1.00),
			TabActive        = vec4:new(0.70, 0.70, 0.73, 1.00),

			CheckMark        = vec4:new(0.15, 0.35, 0.80, 1.00),
			SliderGrab       = vec4:new(0.10, 0.30, 0.80, 0.90),
			SliderGrabActive = vec4:new(0.15, 0.40, 1.00, 1.00),

			Text             = vec4:new(0.15, 0.17, 0.19, 1.00),
			TextDisabled     = vec4:new(0.50, 0.50, 0.52, 1.00),
		},

		Styles = {
			WindowRounding    = 4,
			FrameRounding     = 4,
			GrabRounding      = 4,
			TabRounding       = 4,
			ScrollbarRounding = 6,
			WindowBorderSize  = 1,
			FrameBorderSize   = 1,
			PopupBorderSize   = 1,
			ItemSpacing       = vec2:new(10, 10),
			FramePadding      = vec2:new(5, 6),
		},

		TopBarFrameCol1 = vec4:new(0.15, 0.35, 0.80, 1.00),
		TopBarFrameCol2 = vec4:new(0.10, 0.30, 0.80, 0.90)
	},

	CrimsonVoid = {
		Name = "CrimsonVoid",
		Colors = {
			WindowBg         = vec4:new(0.08, 0.07, 0.08, 0.95),
			ChildBg          = vec4:new(0.09, 0.08, 0.09, 0.95),
			PopupBg          = vec4:new(0.07, 0.06, 0.07, 0.92),

			Header           = vec4:new(0.22, 0.05, 0.08, 0.82),
			HeaderHovered    = vec4:new(0.30, 0.07, 0.12, 0.92),
			HeaderActive     = vec4:new(0.38, 0.10, 0.16, 1.00),

			Button           = vec4:new(0.18, 0.05, 0.06, 0.85),
			ButtonHovered    = vec4:new(0.28, 0.08, 0.10, 0.95),
			ButtonActive     = vec4:new(0.35, 0.10, 0.12, 1.00),

			FrameBg          = vec4:new(0.12, 0.10, 0.11, 0.90),
			FrameBgHovered   = vec4:new(0.18, 0.12, 0.14, 0.95),
			FrameBgActive    = vec4:new(0.22, 0.15, 0.17, 1.00),

			Tab              = vec4:new(0.14, 0.05, 0.06, 0.85),
			TabHovered       = vec4:new(0.28, 0.10, 0.12, 1.00),
			TabActive        = vec4:new(0.22, 0.08, 0.10, 1.00),

			CheckMark        = vec4:new(0.90, 0.15, 0.25, 1.00),
			SliderGrab       = vec4:new(0.85, 0.10, 0.20, 0.85),
			SliderGrabActive = vec4:new(0.95, 0.20, 0.30, 1.00),

			Text             = vec4:new(0.96, 0.95, 0.96, 1.00),
			TextDisabled     = vec4:new(0.45, 0.44, 0.45, 1.00),
		},

		Styles = {
			WindowRounding    = 7,
			FrameRounding     = 6,
			GrabRounding      = 6,
			TabRounding       = 6,
			ScrollbarRounding = 8,
			WindowBorderSize  = 0,
			FrameBorderSize   = 0,
			PopupBorderSize   = 0,
			ItemSpacing       = vec2:new(10, 10),
			FramePadding      = vec2:new(5, 6),
		},

		TopBarFrameCol1 = vec4:new(0.90, 0.15, 0.25, 1.00),
		TopBarFrameCol2 = vec4:new(0.85, 0.10, 0.20, 0.90),
	},

	AzureDream = {
		Name = "AzureDream",
		Colors = {
			WindowBg         = vec4:new(0.88, 0.92, 0.97, 1.00),
			ChildBg          = vec4:new(0.93, 0.95, 0.98, 1.00),
			PopupBg          = vec4:new(0.96, 0.97, 0.99, 1.00),

			Header           = vec4:new(0.55, 0.65, 0.85, 1.00),
			HeaderHovered    = vec4:new(0.50, 0.60, 0.80, 1.00),
			HeaderActive     = vec4:new(0.45, 0.55, 0.75, 1.00),

			Button           = vec4:new(0.60, 0.70, 0.90, 1.00),
			ButtonHovered    = vec4:new(0.55, 0.65, 0.85, 1.00),
			ButtonActive     = vec4:new(0.48, 0.58, 0.80, 1.00),

			FrameBg          = vec4:new(0.80, 0.87, 0.95, 1.00),
			FrameBgHovered   = vec4:new(0.74, 0.82, 0.92, 1.00),
			FrameBgActive    = vec4:new(0.68, 0.77, 0.88, 1.00),

			Tab              = vec4:new(0.80, 0.86, 0.94, 1.00),
			TabHovered       = vec4:new(0.70, 0.78, 0.90, 1.00),
			TabActive        = vec4:new(0.64, 0.72, 0.85, 1.00),

			CheckMark        = vec4:new(0.10, 0.50, 0.95, 1.00),
			SliderGrab       = vec4:new(0.15, 0.40, 0.90, 0.90),
			SliderGrabActive = vec4:new(0.20, 0.50, 1.00, 1.00),

			Text             = vec4:new(0.10, 0.12, 0.15, 1.00),
			TextDisabled     = vec4:new(0.50, 0.50, 0.52, 1.00),
		},

		Styles = {
			WindowRounding    = 4,
			FrameRounding     = 4,
			GrabRounding      = 4,
			TabRounding       = 4,
			ScrollbarRounding = 6,
			WindowBorderSize  = 1,
			FrameBorderSize   = 1,
			PopupBorderSize   = 1,
			ItemSpacing       = vec2:new(10, 10),
			FramePadding      = vec2:new(5, 6),
		},

		TopBarFrameCol1 = vec4:new(0.10, 0.50, 0.95, 1.00),
		TopBarFrameCol2 = vec4:new(0.15, 0.40, 0.90, 0.90),
	},

	SerpentEmerald = {
		Name = "SerpentEmerald",
		Colors = {
			WindowBg         = vec4:new(0.07, 0.09, 0.08, 0.95),
			ChildBg          = vec4:new(0.08, 0.10, 0.09, 0.95),
			PopupBg          = vec4:new(0.06, 0.08, 0.07, 0.92),

			Header           = vec4:new(0.10, 0.20, 0.16, 0.85),
			HeaderHovered    = vec4:new(0.14, 0.28, 0.21, 0.95),
			HeaderActive     = vec4:new(0.18, 0.35, 0.26, 1.00),

			Button           = vec4:new(0.08, 0.18, 0.14, 0.90),
			ButtonHovered    = vec4:new(0.12, 0.25, 0.19, 0.95),
			ButtonActive     = vec4:new(0.16, 0.30, 0.24, 1.00),

			FrameBg          = vec4:new(0.10, 0.14, 0.12, 0.90),
			FrameBgHovered   = vec4:new(0.15, 0.21, 0.18, 0.95),
			FrameBgActive    = vec4:new(0.18, 0.26, 0.22, 1.00),

			Tab              = vec4:new(0.09, 0.16, 0.13, 0.85),
			TabHovered       = vec4:new(0.16, 0.28, 0.22, 1.00),
			TabActive        = vec4:new(0.14, 0.24, 0.20, 1.00),

			CheckMark        = vec4:new(0.15, 0.90, 0.55, 1.00),
			SliderGrab       = vec4:new(0.10, 0.80, 0.45, 0.80),
			SliderGrabActive = vec4:new(0.20, 1.00, 0.60, 1.00),

			Text             = vec4:new(0.92, 0.95, 0.93, 1.00),
			TextDisabled     = vec4:new(0.40, 0.42, 0.41, 1.00),
		},

		Styles = {
			WindowRounding    = 6,
			FrameRounding     = 5,
			GrabRounding      = 5,
			TabRounding       = 5,
			ScrollbarRounding = 6,
			WindowBorderSize  = 0,
			FrameBorderSize   = 0,
			PopupBorderSize   = 0,
			ItemSpacing       = vec2:new(10, 10),
			FramePadding      = vec2:new(5, 6),
		},

		TopBarFrameCol1 = vec4:new(0.15, 0.90, 0.55, 1.00),
		TopBarFrameCol2 = vec4:new(0.10, 0.80, 0.45, 0.80),
	},
}

---@class ThemeManager
---@field private m_current_theme Theme
---@field private m_col_stack integer
---@field private m_style_stack integer
local ThemeManager = {
	m_current_theme = ThemeLibrary.Tenebris,
}

---@param name string
---@return Theme
function ThemeManager:GetTheme(name)
	return ThemeLibrary[name]
end

---@return ThemeLibrary
function ThemeManager:GetThemes()
	return ThemeLibrary
end

---@return Theme
function ThemeManager:GetCurrentTheme()
	return self.m_current_theme
end

---@param theme Theme
function ThemeManager:SetCurrentTheme(theme)
	self.m_current_theme = theme
end

function ThemeManager:PushTheme()
	if (not self.m_current_theme) then
		return
	end

	local colors = self.m_current_theme.Colors
	local styles = self.m_current_theme.Styles

	self.m_col_stack = 0
	for k, v in pairs(colors) do
		if (ImGuiCol[k]) then
			ImGui.PushStyleColor(ImGuiCol[k], v.x, v.y, v.z, v.w)
			self.m_col_stack = self.m_col_stack + 1
		end
	end

	self.m_style_stack = 0
	for k, v in pairs(styles) do
		if (type(v) == "table") then
			ImGui.PushStyleVar(ImGuiStyleVar[k], v.x, v.y)
			self.m_style_stack = self.m_style_stack + 1
		else
			ImGui.PushStyleVar(ImGuiStyleVar[k], v)
			self.m_style_stack = self.m_style_stack + 1
		end
	end
end

function ThemeManager:PopTheme()
	if (self.m_col_stack ~= 0) then
		ImGui.PopStyleColor(self.m_col_stack)
	end

	if (self.m_style_stack ~= 0) then
		ImGui.PopStyleVar(self.m_style_stack)
	end
end

function ThemeManager:CreateNewTheme()
	-- TODO: Allow users to create and save custom themes.
	-- We have to approaches to this: Write an actual Theme class that serializes and deserializes itself
	-- or do it manually in this function: generate -> verify data -> save to json.
	--
	-- Since this is a static singleton, add a method to load user-generated themes from json and append them to the ThemeLibrary table.
	-- and call it on script load (init.lua or main file).
end

return ThemeManager
