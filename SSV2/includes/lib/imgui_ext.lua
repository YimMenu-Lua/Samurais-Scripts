-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- Global ImGui extensions

local spinner_chars <const> = {
	{ "_   ",  " _  ",  "  _  ", "   _" },
	{ "_   ",  "__  ",  "___ ",  "____", " ___", "  __", "   _", "    " },
	{ "_   ",  " _  ",  "  _ ",  "   _", "  _ ", " _  " },
	{ ".   ",  " .  ",  "  . ",  "   .", "    " },
	{ ".   ",  "..  ",  "... ",  "....", "    " },
	{ ".   ",  "..  ",  "... ",  "....", " ...", "  ..", "   .", "    " },
	{ "|",     "/",     "-",     "\\" },
	{ "  _  ", "  -  ", "  =  ", "  -  " },
	{ "=   ",  "==  ",  "=== ",  "====", " ===", "  ==", "   =", "    " },
	{ "*   ",  "**  ",  "*** ",  "****", " ***", "  **", "   *", "    " },
	{ "  _  ", "  -  ", "  _  ", "  -  " },
}

---@enum ImGuiSpinnerStyle
ImGuiSpinnerStyle = {
	SCAN        = 1,
	FILL        = 2,
	BOUNCE      = 3,
	DOT         = 4,
	DOTS        = 5,
	BOUNCE_DOTS = 6,
	ORBIT       = 7,
	TYPEWRITER  = 8,
	PROGRESS    = 9,
	ASTERISK    = 10,
	JUMP        = 11,
}

-- Returns a basic animated string
---@param label? string
---@param speed? float
---@param style? ImGuiSpinnerStyle
---@return string
function ImGui.TextSpinner(label, speed, style)
	speed          = speed or 7.0
	style          = style or 1

	local charlist = spinner_chars[style]
	local time     = ImGui.GetTime()
	local index    = math.floor(math.fmod(time * speed, #charlist)) + 1
	local current  = charlist[index]

	if (label) then
		return _F("%s %s", label, current)
	end

	return current
end

---@param bgColor Color
---@return Color
function ImGui.GetAutoTextColor(bgColor)
	return bgColor:IsDark() and Color("white") or Color("black")
end

-- Wrapper for `ImGui.ColorEdit3` that takes a vec3 and mutates it in place.
---@param label string
---@param outVector vec3
---@return boolean
function ImGui.ColorEditVec3(label, outVector)
	if (not IsInstance(outVector, vec3)) then
		Notifier:ShowError("ImGui", _F("Invalid argument #2: vec3 expected, got %s instead.", type(outVector)), true)
		return false
	end

	local temp, changed = { outVector:unpack() }, false
	temp, changed = ImGui.ColorEdit3(label, temp)
	if (changed) then
		outVector.x = temp[1]
		outVector.y = temp[2]
		outVector.z = temp[3]
	end

	return changed
end

-- Wrapper for `ImGui.ColorEdit4` that takes a vec4 and mutates it in place.
---@param label string
---@param outVector vec4
---@return boolean
function ImGui.ColorEditVec4(label, outVector)
	if (not IsInstance(outVector, vec4)) then
		Notifier:ShowError("ImGui", _F("Invalid argument #2: vec4 expected, got %s instead.", type(outVector)), true)
		return false
	end

	local temp, changed = { outVector:unpack() }, false
	temp, changed = ImGui.ColorEdit4(label, temp)
	if (changed) then
		outVector.x = temp[1]
		outVector.y = temp[2]
		outVector.z = temp[3]
		outVector.w = temp[4]
	end

	return changed
end

---@param label string
---@param outU32 uint32_t
---@return uint32_t, boolean
function ImGui.ColorEditU32(label, outU32)
	local temp, changed = { Color(outU32):AsFloat() }, false
	temp, changed = ImGui.ColorEdit4(label, temp)
	if (changed) then
		return Color(temp):AsU32(), changed
	end

	return outU32, changed
end

---@param label string
---@param stringBuffer string
---@param flags? integer ImGuiInputTextFlags
---@param maxWidth? float
---@param bufferSize? integer
---@return string, boolean
function ImGui.SearchBar(label, stringBuffer, flags, maxWidth, bufferSize)
	maxWidth      = maxWidth or -1
	bufferSize    = bufferSize or math.max(#stringBuffer + 32, 256)
	flags         = flags or ImGuiInputTextFlags.None
	local changed = false

	ImGui.SetNextItemWidth(maxWidth)
	ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 6)
	ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 6, 4)
	stringBuffer, changed = ImGui.InputTextWithHint(
		label,
		_T("GENERIC_SEARCH_HINT"),
		stringBuffer,
		bufferSize,
		flags
	)
	ImGui.PopStyleVar(2)
	return stringBuffer, changed
end

---@param label string
---@param selected boolean
---@param size vec2
---@param shouldHighlight? boolean
---@param highlightColor? Color
---@return boolean
function ImGui.Selectable2(label, selected, size, shouldHighlight, highlightColor)
	local drawList = ImGui.GetWindowDrawList()
	local pos = vec2:new(ImGui.GetCursorScreenPos())
	local max = pos + size
	local rect = Rect(pos, vec2:new(pos.x + size.x, pos.y + size.y))
	local rectSize = rect:GetSize()
	ImGui.InvisibleButton(label, rectSize.x, rectSize.y)
	local hovered = ImGui.IsItemHovered()
	-- local hovered = ImGui.IsMouseHoveringRect(pos.x, pos.y, max.x, max.y)
	local clicked = hovered and ImGui.IsItemClicked(0)
	local pressed = hovered and KeyManager:IsKeyPressed(eVirtualKeyCodes.VK_LBUTTON)

	if (shouldHighlight and highlightColor) then
		ImGui.ImDrawListAddRectFilled(
			drawList,
			pos.x,
			pos.y,
			max.x,
			max.y,
			highlightColor:AsU32(),
			8.0
		)
	end

	local accent = Color(0, 0, 0, 60):AsU32()
	local bg = selected and Color(95, 95, 95, 255):AsU32() or Color(100, 100, 100, 255):AsU32()

	if (hovered) then
		bg = Color(105, 105, 105, 255):AsU32()
	end

	if (pressed or clicked) then
		bg = Color(65, 65, 65, 255):AsU32()
	end

	if (hovered or pressed or selected) then
		ImGui.ImDrawListAddRectFilled(
			drawList,
			pos.x,
			pos.y + 2,
			max.x,
			max.y + 2,
			accent,
			8.0
		)

		ImGui.ImDrawListAddRectFilled(
			drawList,
			pos.x,
			pos.y,
			max.x,
			max.y,
			bg,
			8.0
		)
	end

	local textSizeX, textSizeY = ImGui.CalcTextSize(label)
	local textPos = pos + vec2:new((size.x - textSizeX) * 0.5, (size.y - textSizeY) * 0.5)
	local indicatorPos = pos + vec2:new(max.x - 40.0, (size.y - textSizeY) * 0.5)
	local windowBg = Color(GVars.ui.style.theme.Colors.WindowBg:unpack())
	local textCol = selected and Color(GVars.ui.style.theme.TopBarFrameCol1:unpack()) or ImGui.GetAutoTextColor(windowBg)

	ImGui.ImDrawListAddText(
		drawList,
		textPos.x,
		textPos.y,
		textCol:AsU32(),
		label
	)

	if (shouldHighlight) then
		ImGui.ImDrawListAddText(
			drawList,
			indicatorPos.x,
			indicatorPos.y,
			Color(204, 204, 55, 255):AsU32(),
			"!"
		)
	end

	ImGui.Dummy(0, 0)
	return clicked
end

---@param idx ImGuiCol
---@return uint32_t
function ImGui.GetStyleColorU32(idx)
	return Color(ImGui.GetStyleColorVec4(idx)):AsU32()
end

---@enum ImGuiValueBarFlags
ImGuiValueBarFlags = {
	NONE     = 0,
	VERTICAL = 1 << 0,
}

local ValueBarFontScale = 1
-- https://github.com/ocornut/imgui/issues/5263
---@param label string
---@param value float
---@param size vec2
---@param min_value float
---@param max_value float
---@param flags ImGuiValueBarFlags
function ImGui.ValueBar(label, value, size, min_value, max_value, flags)
	min_value           = min_value or 0
	max_value           = max_value or 1
	flags               = flags or ImGuiValueBarFlags.NONE

	local has_label     = #label > 0 and not label:startswith("##")
	local is_horizontal = not (flags & ImGuiValueBarFlags.VERTICAL)
	local style         = ImGui.GetStyle()
	local draw_list     = ImGui.GetWindowDrawList()
	local cursor_pos    = vec2:new(ImGui.GetCursorScreenPos())
	local fraction      = math.clamp((value - min_value) / (max_value - min_value), 0, 1)
	local frame_height  = ImGui.GetFrameHeight()
	local text_size     = vec2:new(ImGui.CalcTextSize(label))
	local label_size    = has_label and vec2:new(text_size.x, frame_height) or vec2:zero()
	local width         = (size and size.x > 0) and size.x or ImGui.CalcItemWidth()
	local rect_size     = is_horizontal
		and vec2:new(width, frame_height)
		or vec2:new(ImGui.GetFontSize() * 2, size.y - label_size.y)
	local rect_start    = cursor_pos + vec2:new(
		is_horizontal and 0 or math.max(0.0, (label_size.x - rect_size.x) / 2), 0
	)

	ImGui.ImDrawListAddRect(
		draw_list,
		rect_start.x,
		rect_start.y,
		rect_start.x + rect_size.x,
		rect_start.y + rect_size.y,
		ImGui.GetStyleColorU32(ImGuiCol.FrameBg),
		style.FrameRounding
	)

	local rect_start_2 = rect_start + vec2:new(0, is_horizontal and 0 or (1 - fraction) * rect_size.y)
	local rect_end_2 = rect_start + rect_size * vec2:new(is_horizontal and fraction or 1, 1)
	ImGui.ImDrawListAddRectFilled(
		draw_list,
		rect_start_2.x,
		rect_start_2.y,
		rect_end_2.x,
		rect_end_2.y,
		ImGui.GetStyleColorU32(ImGuiCol.PlotHistogram),
		style.FrameRounding
	)

	ImGui.SetWindowFontScale(ValueBarFontScale)
	local value_text = _F("%d%%", math.floor(value * 100))
	local value_text_size = vec2:new(ImGui.CalcTextSize(value_text))
	if (value_text_size.x >= (size.x - 0.1)) then
		ValueBarFontScale = ValueBarFontScale - 0.05
	end

	local value_text_pos = rect_start + (rect_size - value_text_size) / 2
	ImGui.ImDrawListAddText(
		draw_list,
		value_text_pos.x,
		value_text_pos.y,
		ImGui.GetStyleColorU32(ImGuiCol.Text),
		value_text
	)
	ImGui.SetWindowFontScale(1)

	if (has_label) then
		local label_pos = rect_start +
			vec2:new(is_horizontal and rect_size.x + style.ItemInnerSpacing.x or (rect_size.x - label_size.x) / 2,
				style.FramePadding.y + (is_horizontal and 0 or rect_size.y))
		ImGui.ImDrawListAddText(
			draw_list,
			label_pos.x,
			label_pos.y,
			ImGui.GetStyleColorU32(ImGuiCol.Text),
			label
		)
	end

	local total_height = rect_size.y + (has_label and label_size.y or 0)
	ImGui.Dummy(rect_size.x, total_height)
end
