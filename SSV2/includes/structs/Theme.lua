---@class ThemeColors
---@field WindowBg vec4
---@field ChildBg vec4
---@field PopupBg vec4
---@field Border vec4
---@field ScrollbarBg vec4
---@field ScrollbarGrab vec4
---@field ScrollbarGrabHovered vec4
---@field ScrollbarGrabActive vec4
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
---@field PlotHistogram vec4
---@field PlotHistogramHovered vec4

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
---@field JSON? boolean
---@overload fun(themeTable?: table): Theme
local Theme = { __type = "Theme" }
Theme.__index = Theme
---@diagnostic disable-next-line
setmetatable(Theme, {
	__call = function(_, ...)
		return Theme.new(...)
	end
})

---@param themeTable? table
---@return Theme
function Theme.new(themeTable)
	local name   = themeTable and themeTable.Name or ""
	local colors = themeTable and themeTable.Colors or nil
	local styles = themeTable and themeTable.Styles or nil
	local tbg1   = themeTable and themeTable.TopBarFrameCol1 or nil
	local tbg2   = themeTable and themeTable.TopBarFrameCol2 or nil

	local __t    = {
		Name = name,
		Colors = {
			WindowBg             = colors and colors.WindowBg or vec4:new(0, 0, 0, 1),
			ChildBg              = colors and colors.ChildBg or vec4:new(0, 0, 0, 1),
			PopupBg              = colors and colors.PopupBg or vec4:new(0, 0, 0, 1),
			Border               = colors and colors.Border or vec4:new(0, 0, 0, 1),
			ScrollbarBg          = colors and colors.ScrollbarBg or vec4:new(0, 0, 0, 1),
			ScrollbarGrab        = colors and colors.ScrollbarGrab or vec4:new(0, 0, 0, 1),
			ScrollbarGrabHovered = colors and colors.ScrollbarGrabHovered or vec4:new(0, 0, 0, 1),
			ScrollbarGrabActive  = colors and colors.ScrollbarGrabActive or vec4:new(0, 0, 0, 1),
			Header               = colors and colors.Header or vec4:new(0, 0, 0, 1),
			HeaderHovered        = colors and colors.HeaderHovered or vec4:new(0, 0, 0, 1),
			HeaderActive         = colors and colors.HeaderActive or vec4:new(0, 0, 0, 1),
			Button               = colors and colors.Button or vec4:new(0, 0, 0, 1),
			ButtonHovered        = colors and colors.ButtonHovered or vec4:new(0, 0, 0, 1),
			ButtonActive         = colors and colors.ButtonActive or vec4:new(0, 0, 0, 1),
			FrameBg              = colors and colors.FrameBg or vec4:new(0, 0, 0, 1),
			FrameBgHovered       = colors and colors.FrameBgHovered or vec4:new(0, 0, 0, 1),
			FrameBgActive        = colors and colors.FrameBgActive or vec4:new(0, 0, 0, 1),
			Tab                  = colors and colors.Tab or vec4:new(0, 0, 0, 1),
			TabHovered           = colors and colors.TabHovered or vec4:new(0, 0, 0, 1),
			TabActive            = colors and colors.TabActive or vec4:new(0, 0, 0, 1),
			CheckMark            = colors and colors.CheckMark or vec4:new(0, 0, 0, 1),
			SliderGrab           = colors and colors.SliderGrab or vec4:new(0, 0, 0, 1),
			SliderGrabActive     = colors and colors.SliderGrabActive or vec4:new(0, 0, 0, 1),
			Text                 = colors and colors.Text or vec4:new(0, 0, 0, 1),
			TextDisabled         = colors and colors.TextDisabled or vec4:new(0, 0, 0, 1),
			PlotHistogram        = colors and colors.PlotHistogram or vec4:new(0, 0, 0, 1),
			PlotHistogramHovered = colors and colors.PlotHistogramHovered or vec4:new(0, 0, 0, 1),
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
			ItemSpacing       = styles and styles.ItemSpacing or vec2:new(1, 1),
			FramePadding      = styles and styles.FramePadding or vec2:new(1, 1),
		},
		TopBarFrameCol1 = tbg1 or vec4:new(0, 0, 0, 1),
		TopBarFrameCol2 = tbg2 or vec4:new(0, 0, 0, 1)
	}

	---@diagnostic disable-next-line
	return setmetatable(__t, Theme)
end

---@param p1 vec4
---@param p2 vec4
---@return float
function Theme:GetContrastRatio(p1, p2)
	return Color(p1):GetContrastRatio(Color(p2))
end

function Theme:AreAllColorsInvisible()
	local zero_alpha = true
	for _, v in pairs(self.Colors) do
		if (v.w > 0) then
			zero_alpha = false
		end
	end

	return zero_alpha
end

---@return boolean -- Contrast check
---@return array<string> -- Array of error messages showing what failed the test.
function Theme:ValidateVisibility()
	local is_valid = true
	local errs     = {}
	local twRatio  = self:GetContrastRatio(self.Colors.Text, self.Colors.WindowBg)
	local bwRatio  = self:GetContrastRatio(self.Colors.Border, self.Colors.WindowBg)

	if (self:AreAllColorsInvisible()) then
		is_valid = false
		table.insert(errs, "All colors are invisible! This theme will break the UI.")
	end

	if (twRatio < 4.5) then
		is_valid = false
		table.insert(errs, _F("Text contrast too low (%.2f)", twRatio))
	end

	if (bwRatio < 1.5) then
		is_valid = false
		table.insert(errs, _F("Border contrast too low (%.2f)", bwRatio))
	end

	return is_valid, errs
end

function Theme:Normalize()
	-- TODO: add more sanity checks
	if (self:AreAllColorsInvisible()) then
		for _, v in pairs(self.Colors) do
			v.w = 1.0
		end
	end

	if (self:GetContrastRatio(self.Colors.Border, self.Colors.WindowBg) < 1.5) then
		self.Colors.Border = self.Colors.Text * vec4:new(0.8, 0.8, 0.8, 1)
	end
end

function Theme:Clear()
	self.Name = ""
	self.TopBarFrameCol1 = vec4:new(0, 0, 0, 1)
	self.TopBarFrameCol2 = vec4:new(0, 0, 0, 1)

	for k, _ in pairs(self.Colors) do
		self.Colors[k] = vec4:new(0, 0, 0, 1)
	end

	for k, v in pairs(self.Styles) do
		if (type(v) == "number") then
			self.Styles[k] = 0
		elseif (IsInstance(v, vec2)) then
			self.Styles[k] = vec2:new(1, 1)
		end
	end
end

function Theme:Copy()
	local out = Theme.new(self)
	out.TopBarFrameCol1 = self.TopBarFrameCol1:copy()
	out.TopBarFrameCol2 = self.TopBarFrameCol2:copy()

	for k, v in pairs(self.Colors) do
		out.Colors[k] = v:copy()
	end

	for k, v in pairs(self.Styles) do
		if (IsInstance(v, vec2)) then
			out.Styles[k] = v:copy()
		elseif (type(v) == "number") then
			out.Styles[k] = v
		end
	end

	return out
end

---@return table
function Theme:serialize()
	local __t = {
		Name            = self.Name,
		Colors          = {},
		Styles          = {},
		TopBarFrameCol1 = self.TopBarFrameCol1:serialize(),
		TopBarFrameCol2 = self.TopBarFrameCol2:serialize(),
		__type          = self.__type,
		JSON            = true
	}

	for k, v in pairs(self.Colors) do
		__t.Colors[k] = v:serialize()
	end

	for k, v in pairs(self.Styles) do
		if (IsInstance(v, vec2)) then
			__t.Styles[k] = v:serialize()
		elseif (type(v) == "number") then
			__t.Styles[k] = v
		end
	end

	return __t
end

---@param t table
---@return Theme
function Theme.deserialize(t)
	if (type(t) ~= "table" or next(t) == nil) then
		return Theme.new()
	end

	local newTheme = Theme.new(t)
	for k, v in pairs(t.Colors) do
		newTheme.Colors[k] = vec4.deserialize(v)
	end

	for k, v in pairs(t.Styles) do
		if (type(v) == "table" and v.__type == "vec2") then
			newTheme.Styles[k] = vec2.deserialize(v)
		elseif (type(v) == "number") then
			newTheme.Styles[k] = v
		end
	end

	newTheme.TopBarFrameCol1 = vec4.deserialize(t.TopBarFrameCol1)
	newTheme.TopBarFrameCol2 = vec4.deserialize(t.TopBarFrameCol2)

	newTheme:Normalize()
	return newTheme
end

if (Serializer and not Serializer.class_types["Theme"]) then
	Serializer:RegisterNewType("Theme", Theme.serialize, Theme.deserialize)
end

return Theme
