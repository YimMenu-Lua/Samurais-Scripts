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

---@class NotifBellState
---@field unreadCount number
---@field muted boolean
---@field unread boolean
---@field open boolean

local toggleStates = {}

-- Returns a basic animated string
---@param label? string
---@param speed? float
---@param style? ImGuiSpinnerStyle
---@return string
function ImGui.TextSpinner(label, speed, style)
	speed = speed or 7.0
	style = style or 1

	local charlist = spinner_chars[style]
	if (type(charlist) ~= "table" or #charlist == 0) then
		return label or ""
	end

	local time    = ImGui.GetTime()
	local count   = #charlist
	local index   = math.floor((time * speed) % count) + 1
	local current = charlist[index]

	if (type(current) ~= "string") then
		current = ""
	end

	if (label ~= nil) then
		return _F("%s %s", label, current)
	end

	return current
end

---@param bgColor Color
---@return Color
function ImGui.GetAutoTextColor(bgColor)
	return bgColor:IsDark() and Color("white") or Color("black")
end

---@param text string
---@param width float
---@return string
function ImGui.TrimTextToWidth(text, width)
	if (ImGui.CalcTextSize(text) < width) then
		return text
	end

	local ellipsis  = "."
	local ellipsisW = ImGui.CalcTextSize(ellipsis)
	local maxW      = width - ellipsisW
	local trimmed   = text

	if (#trimmed > 64) then
		trimmed = text:sub(1, 128)
	end

	while (#trimmed > 0) do
		local w = ImGui.CalcTextSize(trimmed)
		if (w <= maxW) then
			break
		end
		trimmed = trimmed:sub(1, -2)
	end

	return _F("%s%s", trimmed, ellipsis)
end

---@param text string
---@param maxWidth number
---@param minScale number?
---@param maxScale number?
---@return number
function ImGui.CalcFontScaleToFitWidth(text, maxWidth, minScale, maxScale)
	minScale = minScale or 0.5
	maxScale = maxScale or 1.0

	ImGui.SetWindowFontScale(maxScale)
	if (ImGui.CalcTextSize(text) <= maxWidth) then
		ImGui.SetWindowFontScale(1)
		return maxScale
	end

	local low, high = minScale, maxScale
	local avg = minScale

	for _ = 1, 8 do
		local mid = (low + high) * 0.5
		ImGui.SetWindowFontScale(mid)
		local w = ImGui.CalcTextSize(text)

		if (w <= maxWidth) then
			avg = mid
			low = mid
		else
			high = mid
		end
	end

	ImGui.SetWindowFontScale(1)
	return avg
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
---@param align? "center"|"left"
---@param ellipsis? boolean
---@param shouldHighlight? boolean
---@param highlightColor? Color
---@return boolean
function ImGui.Selectable2(label, selected, size, align, ellipsis, shouldHighlight, highlightColor)
	local drawList = ImGui.GetWindowDrawList()
	local pos      = vec2:new(ImGui.GetCursorScreenPos())
	local max      = pos + size
	local rect     = Rect(pos, vec2:new(pos.x + size.x, pos.y + size.y))
	local rectSize = rect:GetSize()

	ImGui.InvisibleButton(label, rectSize.x, rectSize.y)
	local hovered = ImGui.IsItemHovered()
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

	local accent       = GVars.ui.style.theme.SSAccent
	local gradient     = GVars.ui.style.theme.SSGradient
	local selectedCol  = ImGui.GetColorU32(
		accent.x,
		accent.y,
		accent.z,
		pressed and accent.w - 0.25 or (hovered and 1.0 or accent.w)
	)
	local defaultCol   = ImGui.GetColorU32(0.31, 0.31, 0.43, pressed and 0.50 or 1.00)
	local background   = selected and selectedCol or defaultCol
	local shadow       = Color(0.01, 0.01, 0.01, 55):AsU32()
	local textW, textH = ImGui.CalcTextSize(label)
	local padding      = 8
	local rounding     = ImGui.GetStyle().FrameRounding
	local textX

	if (hovered or pressed or selected) then
		ImGui.ImDrawListAddRectFilled(
			drawList,
			pos.x,
			pos.y + 2,
			max.x,
			max.y + 2,
			shadow,
			8.0
		)

		ImGui.ImDrawListAddRectFilled(
			drawList,
			pos.x,
			pos.y,
			max.x,
			max.y,
			background,
			rounding or 0.0
		)
	end

	local indicatorPos = pos + vec2:new(max.x - 40.0, (size.y - textH) * 0.5)
	local frameRegion  = size.x - padding * 2
	local clipped      = textW > frameRegion
	local finalLabel   = ImGui.TrimTextToWidth(label, frameRegion)

	if (clipped and ellipsis) then
		ImGui.PushClipRect(
			pos.x + padding,
			pos.y,
			pos.x + size.x - padding,
			pos.y + size.y,
			true
		)

		align = "left"
	end

	if (align == "left") then
		textX = pos.x + padding
	else
		textX = pos.x + (size.x - textW) * 0.5
	end

	local textY            = pos.y + (size.y - textH) * 0.5
	local defaultTextColor = ImGui.GetStyleColorU32(ImGuiCol.Text)
	local autoTextColor    = ImGui.GetAutoTextColor(Color(background)):AsU32()
	local textColor        = (hovered or selected) and autoTextColor or defaultTextColor
	ImGui.ImDrawListAddText(drawList, textX, textY, textColor, finalLabel)

	if (clipped) then
		if (ellipsis) then
			ImGui.PopClipRect()
		end

		if (hovered) then
			ImGui.SetTooltip(label)
		end
	end

	if (shouldHighlight) then
		ImGui.ImDrawListAddText(
			drawList,
			indicatorPos.x,
			indicatorPos.y,
			Color(204, 204, 55, 255):AsU32(),
			"!"
		)
	end

	if (not hovered and not clicked and not selected) then
		local finalLabelW = ImGui.CalcTextSize(finalLabel)
		local diff = ((size.x - finalLabelW) * 0.5)
		local mod = clipped and 4 or 0
		if (diff < 0) then
			diff = 0
		end

		ImGui.ImDrawListAddLine(
			drawList,
			pos.x + diff - mod,
			max.y,
			pos.x + size.x - diff - mod,
			max.y,
			ImGui.GetColorU32(
				gradient.x,
				gradient.y,
				gradient.z,
				gradient.w
			),
			1.3
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

	local value_text   = _F("%d%%", math.floor(value * 100))
	local maxTextWidth = rect_size.x - style.FramePadding.x * 2
	local fontScale    = ImGui.CalcFontScaleToFitWidth(
		value_text,
		maxTextWidth,
		0.6,
		1.0
	)

	ImGui.SetWindowFontScale(fontScale)
	local value_text_size = vec2:new(ImGui.CalcTextSize(value_text))
	local value_text_pos  = rect_start + (rect_size - value_text_size) / 2
	ImGui.ImDrawListAddText(
		draw_list,
		value_text_pos.x,
		value_text_pos.y,
		ImGui.GetStyleColorU32(ImGuiCol.Text),
		value_text
	)
	ImGui.SetWindowFontScale(1)

	if (has_label) then
		local posX = is_horizontal and rect_size.x + style.ItemInnerSpacing.x or (rect_size.x - label_size.x) / 2
		local posY = style.FramePadding.y + (is_horizontal and 0 or rect_size.y)
		ImGui.ImDrawListAddText(
			draw_list,
			posX,
			posY,
			ImGui.GetStyleColorU32(ImGuiCol.Text),
			label
		)
	end

	local total_height = rect_size.y + (has_label and label_size.y or 0)
	ImGui.Dummy(rect_size.x, total_height)
end

---@param thickness? float
---@param color? uint32_t
function ImGui.VerticalSeparator(thickness, color)
	thickness        = thickness or 1
	color            = color or ImGui.GetStyleColorU32(ImGuiCol.Separator)
	local drawList   = ImGui.GetWindowDrawList()
	local cursorX    = ImGui.GetCursorScreenPos()
	local _, winPosY = ImGui.GetWindowPos()
	local winHeight  = ImGui.GetWindowHeight()

	ImGui.ImDrawListAddRectFilled(
		drawList,
		cursorX,
		winPosY,
		cursorX + thickness,
		winPosY + winHeight,
		color
	)

	ImGui.Dummy(thickness, 0)
end

---@param label string
---@param v boolean
---@param height? float
---@return boolean, boolean
function ImGui.Toggle(label, v, height)
	local textHeight  = ImGui.GetTextLineHeight() + 0.4
	local frameHeight = ImGui.GetFrameHeight()
	height            = height or textHeight
	local width       = height * 1.8
	local cursorPos   = vec2:new(ImGui.GetCursorScreenPos())
	local pDrawList   = ImGui.GetWindowDrawList()
	local toggleRect  = Rect(
		cursorPos,
		vec2:new(cursorPos.x + width, cursorPos.y + height)
	)

	if (height < frameHeight) then
		local diff = frameHeight - height
		toggleRect.min.y = toggleRect.min.y + (diff * 0.5)
		toggleRect.max.y = toggleRect.max.y + (diff * 0.5)
	end

	ImGui.BeginGroup()
	ImGui.InvisibleButton(label, width, height)
	local hovered = ImGui.IsItemHovered()
	local clicked = ImGui.IsItemClicked(0)

	if (clicked) then
		GUI:PlaySound(GUI.Sounds.Nav)
		v = not v
	end

	local disabled = ImGui.GetStyle().Alpha < 1.0
	local windowBG = vec4:new(ImGui.GetStyleColorVec4(ImGuiCol.WindowBg))
	local frame    = vec4:new(ImGui.GetStyleColorVec4(ImGuiCol.Button))
	local contrast = math.abs(frame.x - windowBG.x)
	if (contrast < 0.05) then
		frame.x = frame.x * 0.85
		frame.y = frame.y * 0.85
		frame.z = frame.z * 0.85
	end

	local checkmark    = vec4:new(ImGui.GetStyleColorVec4(ImGuiCol.CheckMark))
	local frameHovered = vec4:new(ImGui.GetStyleColorVec4(ImGuiCol.ButtonHovered))
	local bgOff        = ImGui.GetColorU32(
		frame.x * 0.9,
		frame.y * 0.9,
		frame.z * 0.9,
		frame.w
	)
	local bgOn         = ImGui.GetColorU32(
		checkmark.x,
		checkmark.y,
		checkmark.z,
		0.8
	)
	local bgHover      = v and bgOn or ImGui.GetColorU32(
		frameHovered.x,
		frameHovered.y,
		frameHovered.z,
		frameHovered.w
	)
	local knob         = ImGui.GetStyleColorU32(disabled and ImGuiCol.TextDisabled or ImGuiCol.Text)
	local bg           = v and bgOn or bgOff
	local radius       = height * 0.5

	ImGui.ImDrawListAddRectFilled(
		pDrawList,
		toggleRect.min.x,
		toggleRect.min.y,
		toggleRect.max.x,
		toggleRect.max.y,
		hovered and bgHover or bg,
		radius
	)

	local uniqueKey         = _F("%s%s%s", label, cursorPos.x, cursorPos.y)
	local anim              = toggleStates[uniqueKey] or (v and 1.0 or 0.0)
	local target            = v and 1.0 or 0.0
	anim                    = math.lerp(anim, target, 0.17)
	toggleStates[uniqueKey] = anim
	local knobX             = cursorPos.x + radius + anim * (width - height)
	ImGui.ImDrawListAddCircleFilled(
		pDrawList,
		knobX,
		cursorPos.y + radius,
		radius * 0.85,
		knob
	)

	if (label and not label:startswith("##")) then
		if (label:contains("##")) then
			label = label:match("(.-)##")
		end

		local textY = cursorPos.y + (height - textHeight) * 0.5
		ImGui.SetCursorScreenPos(cursorPos.x + width + 10, textY)
		ImGui.TextUnformatted(label)
	end

	ImGui.EndGroup()

	return v, clicked
end

-- idk what to call this
---@param state NotifBellState
---@param size vec2
---@return boolean clicked
function ImGui.NotifWidget(state, size)
	ImGui.BeginGroup()

	local clicked   = ImGui.InvisibleButton("##ss_bell_widget", size.x, size.y)
	local hovered   = ImGui.IsItemHovered()
	local pDrawList = ImGui.GetWindowDrawList()
	local pmin      = vec2:new(ImGui.GetItemRectMin())
	local pmax      = vec2:new(ImGui.GetItemRectMax())
	local width     = pmax.x - pmin.x
	local height    = pmax.y - pmin.y
	local accent    = Color(GVars.ui.style.theme.SSAccent)
	local widgetCol = ImGui.GetStyleColorU32(ImGuiCol.Button)

	if (not state.muted) then
		if (state.open and not hovered) then
			widgetCol = ImGui.GetStyleColorU32(ImGuiCol.ButtonActive)
		end

		if (hovered) then
			widgetCol = ImGui.GetStyleColorU32(ImGuiCol.ButtonHovered)
		end
	end

	local rounding = height * 0.55
	local expandX  = height * 0.25
	local expandY  = height * 0.10
	local baseX    = pmin.x + height * 0.27
	local baseY    = (pmax.y - height * 0.15) + expandY
	local tipX     = baseX - height * 0.45
	local tipY     = baseY + height * 0.45
	ImGui.ImDrawListAddTriangleFilled(
		pDrawList,
		baseX,
		baseY,
		baseX + height * 0.55,
		baseY + height * 0.08,
		tipX,
		tipY,
		widgetCol
	)
	ImGui.ImDrawListAddRectFilled(
		pDrawList,
		pmin.x - expandX,
		pmin.y - expandY,
		pmax.x + expandX,
		pmax.y + expandY,
		widgetCol,
		rounding
	)

	if (not state.muted) then
		local dotsRad = (width / 3) * 0.3
		local dotsY   = (pmin.y + pmax.y) * 0.5
		local spacing = dotsRad * 3
		local startX  = (pmin.x + pmax.x) * 0.5 - spacing
		for i = 0, 2 do
			ImGui.ImDrawListAddCircleFilled(
				pDrawList,
				startX + i * spacing,
				dotsY,
				dotsRad,
				ImGui.GetStyleColorU32(ImGuiCol.Text),
				12
			)
		end

		if (state.unread and state.unreadCount > 0) then
			local c  = state.unreadCount
			local r  = height * 0.32
			local bx = pmax.x + r * 1.25
			local by = pmin.y + r * 0.7
			ImGui.ImDrawListAddCircleFilled(
				pDrawList,
				bx,
				by,
				r,
				accent:AsU32(),
				12
			)

			if (c > 99) then
				c = 99
			end

			ImGui.SetWindowFontScale(0.5)
			local countTxt = _F("%s%d", c >= 99 and "+" or "", c)
			local txtSize = vec2:new(ImGui.CalcTextSize(countTxt))
			ImGui.ImDrawListAddText(
				pDrawList,
				14,
				bx - txtSize.x * 0.5,
				by - txtSize.y * 0.75,
				ImGui.GetAutoTextColor(accent):AsU32(),
				_F("%s%d", c >= 99 and "+" or "", c)
			)
			ImGui.SetWindowFontScale(1.0)
		end
	else
		ImGui.ImDrawListAddLine(
			pDrawList,
			pmin.x - 3,
			pmin.y - 3,
			pmax.x + 3,
			pmax.y + 3,
			ImGui.GetStyleColorU32(ImGuiCol.TextDisabled),
			2.4
		)
	end

	ImGui.EndGroup()

	return clicked
end
