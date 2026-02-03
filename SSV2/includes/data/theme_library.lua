-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class ThemeLibrary
local ThemeLibrary <const> = {
	---@type Theme
	Tenebris = {
		Name = "Tenebris",
		Colors = {
			WindowBg             = vec4:new(0.10, 0.11, 0.12, 0.94),
			ChildBg              = vec4:new(0.11, 0.12, 0.13, 0.94),
			PopupBg              = vec4:new(0.09, 0.10, 0.11, 0.92),
			Border               = vec4:new(0.95, 0.96, 0.97, 1.00),

			ScrollbarBg          = vec4:new(0.11, 0.12, 0.13, 0.94),
			ScrollbarGrab        = vec4:new(0.20, 0.22, 0.25, 0.80),
			ScrollbarGrabHovered = vec4:new(0.27, 0.30, 0.34, 0.90),
			ScrollbarGrabActive  = vec4:new(0.33, 0.37, 0.42, 1.00),

			Header               = vec4:new(0.20, 0.22, 0.25, 0.80),
			HeaderHovered        = vec4:new(0.27, 0.30, 0.34, 0.90),
			HeaderActive         = vec4:new(0.33, 0.37, 0.42, 1.00),

			Button               = vec4:new(0.18, 0.20, 0.23, 0.85),
			ButtonHovered        = vec4:new(0.28, 0.30, 0.34, 0.95),
			ButtonActive         = vec4:new(0.23, 0.25, 0.29, 1.00),

			FrameBg              = vec4:new(0.14, 0.15, 0.17, 0.90),
			FrameBgHovered       = vec4:new(0.20, 0.21, 0.23, 0.95),
			FrameBgActive        = vec4:new(0.23, 0.24, 0.26, 1.00),

			Tab                  = vec4:new(0.17, 0.18, 0.20, 0.86),
			TabHovered           = vec4:new(0.27, 0.29, 0.32, 1.00),
			TabActive            = vec4:new(0.25, 0.27, 0.30, 1.00),

			CheckMark            = vec4:new(0.36, 0.50, 0.90, 1.00),
			SliderGrab           = vec4:new(0.33, 0.40, 0.85, 0.80),
			SliderGrabActive     = vec4:new(0.42, 0.48, 0.95, 1.00),

			Text                 = vec4:new(0.95, 0.96, 0.97, 1.00),
			TextDisabled         = vec4:new(0.50, 0.52, 0.54, 1.00),

			PlotHistogram        = vec4:new(0.36, 0.50, 0.90, 0.85),
			PlotHistogramHovered = vec4:new(0.42, 0.55, 1.00, 1.00),
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

	---@type Theme
	Cyberpunk = {
		Name = "Cyberpunk",
		Colors = {
			WindowBg             = vec4:new(0.06, 0.06, 0.08, 0.95),
			ChildBg              = vec4:new(0.07, 0.07, 0.09, 0.95),
			PopupBg              = vec4:new(0.05, 0.05, 0.08, 0.92),
			Border               = vec4:new(0.92, 0.95, 0.98, 1.00),

			ScrollbarBg          = vec4:new(0.07, 0.07, 0.09, 0.95),
			ScrollbarGrab        = vec4:new(0.13, 0.10, 0.20, 0.80),
			ScrollbarGrabHovered = vec4:new(0.18, 0.14, 0.30, 0.95),
			ScrollbarGrabActive  = vec4:new(0.22, 0.16, 0.40, 1.00),

			Header               = vec4:new(0.13, 0.10, 0.20, 0.80),
			HeaderHovered        = vec4:new(0.18, 0.14, 0.30, 0.95),
			HeaderActive         = vec4:new(0.22, 0.16, 0.40, 1.00),

			Button               = vec4:new(0.10, 0.15, 0.18, 0.90),
			ButtonHovered        = vec4:new(0.15, 0.22, 0.26, 0.95),
			ButtonActive         = vec4:new(0.11, 0.18, 0.22, 1.00),

			FrameBg              = vec4:new(0.08, 0.10, 0.12, 0.90),
			FrameBgHovered       = vec4:new(0.12, 0.15, 0.18, 0.95),
			FrameBgActive        = vec4:new(0.14, 0.17, 0.20, 1.00),

			Tab                  = vec4:new(0.10, 0.08, 0.12, 0.80),
			TabHovered           = vec4:new(0.20, 0.14, 0.30, 1.00),
			TabActive            = vec4:new(0.15, 0.11, 0.22, 1.00),

			CheckMark            = vec4:new(0.00, 0.85, 0.80, 1.00),
			SliderGrab           = vec4:new(0.60, 0.10, 0.90, 0.80),
			SliderGrabActive     = vec4:new(0.75, 0.20, 1.00, 1.00),

			Text                 = vec4:new(0.92, 0.95, 0.98, 1.00),
			TextDisabled         = vec4:new(0.40, 0.40, 0.45, 1.00),

			PlotHistogram        = vec4:new(0.60, 0.15, 0.90, 0.85),
			PlotHistogramHovered = vec4:new(0.75, 0.25, 1.00, 1.00),
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
		TopBarFrameCol2 = vec4:new(0.19, 0.35, 0.70, 0.70)
	},

	---@type Theme
	Silverlight = {
		Name = "Silverlight",
		Colors = {
			WindowBg             = vec4:new(0.92, 0.93, 0.94, 1.00),
			ChildBg              = vec4:new(0.95, 0.96, 0.97, 1.00),
			PopupBg              = vec4:new(0.98, 0.98, 0.99, 1.00),
			Border               = vec4:new(0.15, 0.17, 0.19, 1.00),

			ScrollbarBg          = vec4:new(0.95, 0.96, 0.97, 1.00),
			ScrollbarGrab        = vec4:new(0.75, 0.78, 0.82, 1.00),
			ScrollbarGrabHovered = vec4:new(0.70, 0.73, 0.77, 1.00),
			ScrollbarGrabActive  = vec4:new(0.65, 0.68, 0.72, 1.00),

			Header               = vec4:new(0.75, 0.78, 0.82, 1.00),
			HeaderHovered        = vec4:new(0.70, 0.73, 0.77, 1.00),
			HeaderActive         = vec4:new(0.65, 0.68, 0.72, 1.00),

			Button               = vec4:new(0.75, 0.77, 0.80, 1.00),
			ButtonHovered        = vec4:new(0.70, 0.72, 0.75, 1.00),
			ButtonActive         = vec4:new(0.65, 0.67, 0.70, 1.00),

			FrameBg              = vec4:new(0.82, 0.83, 0.85, 1.00),
			FrameBgHovered       = vec4:new(0.77, 0.78, 0.80, 1.00),
			FrameBgActive        = vec4:new(0.72, 0.73, 0.75, 1.00),

			Tab                  = vec4:new(0.82, 0.82, 0.85, 1.00),
			TabHovered           = vec4:new(0.75, 0.75, 0.78, 1.00),
			TabActive            = vec4:new(0.70, 0.70, 0.73, 1.00),

			CheckMark            = vec4:new(0.15, 0.35, 0.80, 1.00),
			SliderGrab           = vec4:new(0.10, 0.30, 0.80, 0.90),
			SliderGrabActive     = vec4:new(0.15, 0.40, 1.00, 1.00),

			Text                 = vec4:new(0.15, 0.17, 0.19, 1.00),
			TextDisabled         = vec4:new(0.50, 0.50, 0.52, 1.00),

			PlotHistogram        = vec4:new(0.10, 0.35, 0.80, 0.90),
			PlotHistogramHovered = vec4:new(0.15, 0.45, 1.00, 1.00),
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

		TopBarFrameCol1 = vec4:new(0.25, 0.55, 0.85, 1.00),
		TopBarFrameCol2 = vec4:new(0.15, 0.35, 0.80, 0.55)
	},

	---@type Theme
	CrimsonVoid = {
		Name = "Crimson Void",
		Colors = {
			WindowBg             = vec4:new(0.08, 0.07, 0.08, 0.95),
			ChildBg              = vec4:new(0.09, 0.08, 0.09, 0.95),
			PopupBg              = vec4:new(0.07, 0.06, 0.07, 0.92),
			Border               = vec4:new(0.96, 0.95, 0.96, 1.00),

			ScrollbarBg          = vec4:new(0.09, 0.08, 0.09, 0.95),
			ScrollbarGrab        = vec4:new(0.22, 0.05, 0.08, 0.82),
			ScrollbarGrabHovered = vec4:new(0.30, 0.07, 0.12, 0.92),
			ScrollbarGrabActive  = vec4:new(0.38, 0.10, 0.16, 1.00),

			Header               = vec4:new(0.22, 0.05, 0.08, 0.82),
			HeaderHovered        = vec4:new(0.30, 0.07, 0.12, 0.92),
			HeaderActive         = vec4:new(0.38, 0.10, 0.16, 1.00),

			Button               = vec4:new(0.18, 0.05, 0.06, 0.85),
			ButtonHovered        = vec4:new(0.28, 0.08, 0.10, 0.95),
			ButtonActive         = vec4:new(0.35, 0.10, 0.12, 1.00),

			FrameBg              = vec4:new(0.12, 0.10, 0.11, 0.90),
			FrameBgHovered       = vec4:new(0.18, 0.12, 0.14, 0.95),
			FrameBgActive        = vec4:new(0.22, 0.15, 0.17, 1.00),

			Tab                  = vec4:new(0.14, 0.05, 0.06, 0.85),
			TabHovered           = vec4:new(0.28, 0.10, 0.12, 1.00),
			TabActive            = vec4:new(0.22, 0.08, 0.10, 1.00),

			CheckMark            = vec4:new(0.90, 0.15, 0.25, 1.00),
			SliderGrab           = vec4:new(0.85, 0.10, 0.20, 0.85),
			SliderGrabActive     = vec4:new(0.95, 0.20, 0.30, 1.00),

			Text                 = vec4:new(0.96, 0.95, 0.96, 1.00),
			TextDisabled         = vec4:new(0.45, 0.44, 0.45, 1.00),

			PlotHistogram        = vec4:new(0.85, 0.15, 0.20, 0.85),
			PlotHistogramHovered = vec4:new(0.95, 0.25, 0.30, 1.00),
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

		TopBarFrameCol1 = vec4:new(0.99, 0.05, 0.05, 1.00),
		TopBarFrameCol2 = vec4:new(0.65, 0.10, 0.10, 0.60),
	},

	---@type Theme
	AzureDream = {
		Name = "Azure Dream",
		Colors = {
			WindowBg             = vec4:new(0.88, 0.92, 0.97, 1.00),
			ChildBg              = vec4:new(0.93, 0.95, 0.98, 1.00),
			PopupBg              = vec4:new(0.96, 0.97, 0.99, 1.00),
			Border               = vec4:new(0.10, 0.12, 0.15, 1.00),

			ScrollbarBg          = vec4:new(0.93, 0.95, 0.98, 1.00),
			ScrollbarGrab        = vec4:new(0.55, 0.65, 0.85, 1.00),
			ScrollbarGrabHovered = vec4:new(0.50, 0.60, 0.80, 1.00),
			ScrollbarGrabActive  = vec4:new(0.45, 0.55, 0.75, 1.00),

			Header               = vec4:new(0.55, 0.65, 0.85, 1.00),
			HeaderHovered        = vec4:new(0.50, 0.60, 0.80, 1.00),
			HeaderActive         = vec4:new(0.45, 0.55, 0.75, 1.00),

			Button               = vec4:new(0.60, 0.70, 0.90, 1.00),
			ButtonHovered        = vec4:new(0.55, 0.65, 0.85, 1.00),
			ButtonActive         = vec4:new(0.48, 0.58, 0.80, 1.00),

			FrameBg              = vec4:new(0.80, 0.87, 0.95, 1.00),
			FrameBgHovered       = vec4:new(0.74, 0.82, 0.92, 1.00),
			FrameBgActive        = vec4:new(0.68, 0.77, 0.88, 1.00),

			Tab                  = vec4:new(0.80, 0.86, 0.94, 1.00),
			TabHovered           = vec4:new(0.70, 0.78, 0.90, 1.00),
			TabActive            = vec4:new(0.64, 0.72, 0.85, 1.00),

			CheckMark            = vec4:new(0.10, 0.50, 0.95, 1.00),
			SliderGrab           = vec4:new(0.15, 0.40, 0.90, 0.90),
			SliderGrabActive     = vec4:new(0.20, 0.50, 1.00, 1.00),

			Text                 = vec4:new(0.10, 0.12, 0.15, 1.00),
			TextDisabled         = vec4:new(0.50, 0.50, 0.52, 1.00),

			PlotHistogram        = vec4:new(0.15, 0.45, 0.90, 0.90),
			PlotHistogramHovered = vec4:new(0.20, 0.55, 1.00, 1.00),
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

	---@type Theme
	SerpentEmerald = {
		Name = "Serpent Emerald",
		Colors = {
			WindowBg             = vec4:new(0.07, 0.09, 0.08, 0.95),
			ChildBg              = vec4:new(0.08, 0.10, 0.09, 0.95),
			PopupBg              = vec4:new(0.06, 0.08, 0.07, 0.92),
			Border               = vec4:new(0.92, 0.95, 0.93, 1.00),

			ScrollbarBg          = vec4:new(0.08, 0.10, 0.09, 0.95),
			ScrollbarGrab        = vec4:new(0.10, 0.20, 0.16, 0.85),
			ScrollbarGrabHovered = vec4:new(0.14, 0.28, 0.21, 0.95),
			ScrollbarGrabActive  = vec4:new(0.18, 0.35, 0.26, 1.00),

			Header               = vec4:new(0.10, 0.20, 0.16, 0.85),
			HeaderHovered        = vec4:new(0.14, 0.28, 0.21, 0.95),
			HeaderActive         = vec4:new(0.18, 0.35, 0.26, 1.00),

			Button               = vec4:new(0.08, 0.18, 0.14, 0.90),
			ButtonHovered        = vec4:new(0.12, 0.25, 0.19, 0.95),
			ButtonActive         = vec4:new(0.16, 0.30, 0.24, 1.00),

			FrameBg              = vec4:new(0.10, 0.14, 0.12, 0.90),
			FrameBgHovered       = vec4:new(0.15, 0.21, 0.18, 0.95),
			FrameBgActive        = vec4:new(0.18, 0.26, 0.22, 1.00),

			Tab                  = vec4:new(0.09, 0.16, 0.13, 0.85),
			TabHovered           = vec4:new(0.16, 0.28, 0.22, 1.00),
			TabActive            = vec4:new(0.14, 0.24, 0.20, 1.00),

			CheckMark            = vec4:new(0.15, 0.90, 0.55, 1.00),
			SliderGrab           = vec4:new(0.10, 0.80, 0.45, 0.80),
			SliderGrabActive     = vec4:new(0.20, 1.00, 0.60, 1.00),

			Text                 = vec4:new(0.92, 0.95, 0.93, 1.00),
			TextDisabled         = vec4:new(0.40, 0.42, 0.41, 1.00),

			PlotHistogram        = vec4:new(0.10, 0.80, 0.45, 0.85),
			PlotHistogramHovered = vec4:new(0.20, 1.00, 0.60, 1.00),
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

	---@type Theme
	CriminalMastermind = {
		Name = "Criminal Mastermind",
		Colors = {
			WindowBg             = vec4:new(0.07, 0.07, 0.08, 0.96),
			ChildBg              = vec4:new(0.08, 0.08, 0.09, 0.96),
			PopupBg              = vec4:new(0.06, 0.06, 0.07, 0.94),
			Border               = vec4:new(0.92, 0.90, 0.86, 1.00),

			ScrollbarBg          = vec4:new(0.08, 0.08, 0.09, 0.96),
			ScrollbarGrab        = vec4:new(0.16, 0.15, 0.13, 0.85),
			ScrollbarGrabHovered = vec4:new(0.22, 0.21, 0.18, 0.95),
			ScrollbarGrabActive  = vec4:new(0.28, 0.26, 0.22, 1.00),

			Header               = vec4:new(0.16, 0.15, 0.13, 0.85),
			HeaderHovered        = vec4:new(0.22, 0.21, 0.18, 0.95),
			HeaderActive         = vec4:new(0.28, 0.26, 0.22, 1.00),

			Button               = vec4:new(0.14, 0.13, 0.11, 0.90),
			ButtonHovered        = vec4:new(0.20, 0.19, 0.16, 0.95),
			ButtonActive         = vec4:new(0.26, 0.24, 0.20, 1.00),

			FrameBg              = vec4:new(0.11, 0.11, 0.12, 0.92),
			FrameBgHovered       = vec4:new(0.17, 0.16, 0.14, 0.96),
			FrameBgActive        = vec4:new(0.22, 0.21, 0.18, 1.00),

			Tab                  = vec4:new(0.12, 0.11, 0.10, 0.90),
			TabHovered           = vec4:new(0.22, 0.21, 0.18, 1.00),
			TabActive            = vec4:new(0.18, 0.17, 0.14, 1.00),

			CheckMark            = vec4:new(0.78, 0.65, 0.30, 1.00),

			SliderGrab           = vec4:new(0.72, 0.60, 0.28, 0.75),
			SliderGrabActive     = vec4:new(0.85, 0.72, 0.35, 1.00),

			PlotHistogram        = vec4:new(0.72, 0.60, 0.28, 0.85),
			PlotHistogramHovered = vec4:new(0.85, 0.72, 0.35, 1.00),

			Text                 = vec4:new(0.92, 0.90, 0.86, 1.00),
			TextDisabled         = vec4:new(0.45, 0.44, 0.42, 1.00),
		},

		Styles = {
			WindowRounding    = 6,
			FrameRounding     = 5,
			GrabRounding      = 4,
			TabRounding       = 5,
			ScrollbarRounding = 6,

			WindowBorderSize  = 0,
			FrameBorderSize   = 0,
			PopupBorderSize   = 0,

			ItemSpacing       = vec2:new(10, 10),
			FramePadding      = vec2:new(6, 6),
		},

		TopBarFrameCol1 = vec4:new(0.78, 0.65, 0.30, 1.00),
		TopBarFrameCol2 = vec4:new(0.55, 0.45, 0.22, 0.85),
	},
}

return ThemeLibrary
