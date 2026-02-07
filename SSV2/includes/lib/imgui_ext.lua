-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- Global ImGui extensions

---@class NotifBellState
---@field unreadCount number
---@field muted boolean
---@field unread boolean
---@field open boolean

---@enum ImGuiSpinnerStyle
ImGuiSpinnerStyle             = {
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

---@enum ImGuiValueBarFlags
ImGuiValueBarFlags            = {
	NONE      = 0,
	VERTICAL  = 1 << 0,
	MULTI_VAL = 1 << 1,
}

---@enum ImGuiDialogBoxStyle
ImGuiDialogBoxStyle           = {
	INFO   = 0,
	WARN   = 1,
	SEVERE = 2,
}

local toggleStates            = {}

local spinner_chars <const>   = {
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

local DialogBoxColors <const> = {
	-- info is just derived from default theme
	[ImGuiDialogBoxStyle.WARN]   = Color(240, 190, 2, 255), -- safety yellow; we should probably define this in the Color class as a named color
	[ImGuiDialogBoxStyle.SEVERE] = Color("red"),
}

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
---@return Color
function ImGui.GetStyleColor(idx)
	return Color(ImGui.GetStyleColorVec4(idx))
end

---@param idx ImGuiCol
---@return uint32_t
function ImGui.GetStyleColorU32(idx)
	return ImGui.GetStyleColor(idx):AsU32()
end

-- https://github.com/ocornut/imgui/issues/5263
---@param label string
---@param value float
---@param size? vec2
---@param flags? ImGuiValueBarFlags
---@param opts? { value2?: float, v1Col?: uint32_t, v2Col?: uint32_t, fmt?: string }
function ImGui.ValueBar(label, value, size, flags, opts)
	flags              = flags or ImGuiValueBarFlags.NONE
	size               = size or vec2:zero()
	opts               = opts or {}

	---@type boolean
	local isMultiVal   = flags & ImGuiValueBarFlags.MULTI_VAL ~= 0
	local isHotizontal = flags & ImGuiValueBarFlags.VERTICAL == 0
	local region       = vec2:new(ImGui.GetContentRegionAvail())

	if (size.x <= 0) then
		if (isHotizontal) then
			size.x = region.x
		else
			size.y = region.y
		end
	end

	if (size.y <= 0) then
		if (isHotizontal) then
			size.y = 32
		else
			size.y = region.y
		end
	end

	local pDrawList = ImGui.GetWindowDrawList()
	local style     = ImGui.GetStyle()
	local cursorPos = vec2:new(ImGui.GetCursorScreenPos())
	local hasLabel  = #label > 0 and not label:startswith("##")
	local minV      = 0
	local maxV      = 1
	local fraction  = math.clamp((value - minV) / (maxV - minV), 0, 1)
	local frameH    = ImGui.GetFrameHeight() - style.FramePadding.y
	local textSize  = vec2:new(ImGui.CalcTextSize(label))
	local labelSize = hasLabel and vec2:new(textSize.x, frameH) or vec2:zero()
	local width     = (size and size.x > 0) and size.x or ImGui.CalcItemWidth()
	local rectSize  = isHotizontal
		and vec2:new(width, frameH)
		or vec2:new(ImGui.GetFontSize() * 2, size.y - labelSize.y)
	local rectStart = cursorPos + vec2:new(
		isHotizontal and 0 or math.max(0.0, (labelSize.x - rectSize.x) / 2), 0
	)
	local v1Col     = opts.v1Col or ImGui.GetStyleColorU32(ImGuiCol.PlotHistogram)

	ImGui.ImDrawListAddRectFilled(
		pDrawList,
		rectStart.x,
		rectStart.y,
		rectStart.x + rectSize.x,
		rectStart.y + rectSize.y,
		ImGui.GetStyleColorU32(ImGuiCol.FrameBg),
		style.FrameRounding
	)

	local value2     = opts.value2 or 0
	local rect2Start = rectStart + vec2:new(0, isHotizontal and 0 or (1 - fraction) * rectSize.y)
	local rect2End   = rectStart + rectSize * vec2:new(isHotizontal and fraction or 1, 1)
	if (value > 0) then
		ImGui.ImDrawListAddRectFilled(
			pDrawList,
			rect2Start.x,
			rect2Start.y,
			rect2End.x,
			rect2End.y,
			v1Col,
			style.FrameRounding,
			isHotizontal and (value < 1 and 80 or 240) or 240 -- ImDrawFlags_RoundCorners*
		)
	end

	if (isMultiVal and value2 > 0) then
		local v2Col      = opts.v2Col or ImGui.GetStyleColor(ImGuiCol.PlotHistogram):Brighten(0.2):AsU32()
		local fraction2  = math.clamp((value2 - minV) / (maxV - minV), 0, 1)
		local rect3Start = vec2:new(rect2End.x, rect2Start.y) +
			vec2:new(0, isHotizontal and 0 or (1 - fraction2) * rectSize.y)
		local rect3End   = rect3Start + rectSize * vec2:new(isHotizontal and fraction2 or 1, 1)
		local rounding   = 0
		local dlFlags    = 0
		if (value == 0) then
			rounding = style.FrameRounding
			dlFlags = 80
		elseif (value + value2 >= 1) then
			rounding = style.FrameRounding
			dlFlags = 160
		end
		ImGui.ImDrawListAddRectFilled(
			pDrawList,
			rect3Start.x,
			rect3Start.y,
			rect3End.x,
			rect3End.y,
			v2Col,
			rounding,
			dlFlags
		)
	end

	local valueText    = opts.fmt or _F("%d%%", math.floor(value * 100))
	local maxTextWidth = rectSize.x - style.FramePadding.x * 2
	local fontScale    = ImGui.CalcFontScaleToFitWidth(
		valueText,
		maxTextWidth,
		0.6,
		1.0
	)

	ImGui.SetWindowFontScale(fontScale)
	local valTextSize = vec2:new(ImGui.CalcTextSize(valueText))
	local valTextPos  = rectStart + (rectSize - valTextSize) / 2
	ImGui.ImDrawListAddText(
		pDrawList,
		valTextPos.x,
		valTextPos.y,
		ImGui.GetStyleColorU32(ImGuiCol.Text),
		valueText
	)
	ImGui.SetWindowFontScale(1)

	if (hasLabel) then
		local posX = isHotizontal and rectSize.x + style.ItemInnerSpacing.x or (rectSize.x - labelSize.x) / 2
		local posY = style.FramePadding.y + (isHotizontal and 0 or rectSize.y)
		ImGui.ImDrawListAddText(
			pDrawList,
			posX,
			posY,
			ImGui.GetStyleColorU32(ImGuiCol.Text),
			label
		)
	end

	local totalH = rectSize.y + (hasLabel and labelSize.y or 0)
	ImGui.Dummy(rectSize.x, totalH)
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

			if (c > 9) then
				c = 9
			end

			ImGui.SetWindowFontScale(0.5)
			local countTxt = _F("%s%d", state.unreadCount > 9 and "+" or "", c)
			local txtSize = vec2:new(ImGui.CalcTextSize(countTxt))
			ImGui.ImDrawListAddText(
				pDrawList,
				14,
				bx - txtSize.x * 0.5,
				by - txtSize.y * 0.75,
				ImGui.GetAutoTextColor(accent):AsU32(),
				countTxt
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

-- Draws a dialog box with Confirm/Cancel buttons.
--
-- You must call `ImGui.OpenPopup` right before it and use the same label.
--
-- **Example:**
--
--```Lua
-- local function scary_func()
-- 	MyClass:DoTheThing()
-- end
--
-- if ImGui.Button("Do The Thing") then
--	ImGui.OpenPopup("Delete File")
-- end
--
-- if ImGui.DialogBox(
-- 	"Delete File",
-- 	"Are you sure you want to delete this file?",
-- 	ImGuiDialogBoxStyle.WARN
-- ) then
-- 	scary_func()
-- end
--```
---@param label string
---@param message? string -- Optional: Defaults to: "This action is irreversible. Are you sure you want to proceed?"
---@param boxStyle? ImGuiDialogBoxStyle
---@return boolean
function ImGui.DialogBox(label, message, boxStyle)
	boxStyle      = boxStyle or ImGuiDialogBoxStyle.INFO
	message       = message or _T("GENERIC_CONFIRM_WARN")
	local col     = DialogBoxColors[boxStyle] or Color(ImGui.GetStyleColorVec4(ImGuiCol.PopupBg))
	local textCol = ImGui.GetAutoTextColor(col)
	local v       = false

	ImGui.SetNextWindowBgAlpha(0.97)
	ImGui.SetNextWindowSizeConstraints(440, 200, 440, 600)
	ImGui.PushStyleColor(ImGuiCol.TitleBg, col.r, col.g, col.b, col.a)
	ImGui.PushStyleColor(ImGuiCol.TitleBgActive, col.r, col.g, col.b, col.a)
	ImGui.PushStyleColor(ImGuiCol.TitleBgCollapsed, col.r, col.g, col.b, col.a) -- is this even necessary?
	ImGui.PushStyleColor(ImGuiCol.Text, textCol.r, textCol.g, textCol.b, textCol.a)
	local open = ImGui.BeginPopupModal(
		label,
		true,
		ImGuiWindowFlags.NoMove
		| ImGuiWindowFlags.NoResize
		| ImGuiWindowFlags.NoCollapse
		| ImGuiWindowFlags.AlwaysAutoResize
		| ImGuiWindowFlags.NoSavedSettings
	)
	ImGui.PopStyleColor(4)

	if (open) then
		local windowSize = vec2:new(ImGui.GetWindowSize())
		local _, pos     = GUI:GetNewWindowSizeAndCenterPos(0.5, 0.5, windowSize)
		ImGui.SetWindowPos(pos.x, pos.y, ImGuiCond.Always)
		ImGui.Spacing()

		local buttonSize     = vec2:new(windowSize.x * 0.3, 35)
		local spacing        = ImGui.GetStyle().ItemSpacing.x
		local firstCursorPos = (windowSize.x - ((buttonSize.x + spacing) * 3)) / 2
		ImGui.TextWrapped(message)

		ImGui.Dummy(0, 40)
		if (boxStyle > ImGuiDialogBoxStyle.INFO) then
			ImGui.PushStyleColor(ImGuiCol.Button, col.r, col.g, col.b, math.max(col.a * 0.8, 0.8))
			ImGui.PushStyleColor(ImGuiCol.ButtonHovered, col.r, col.g, col.b, col.a)
			ImGui.PushStyleColor(ImGuiCol.ButtonActive, col.r, col.g, col.b, math.max(col.a * 0.7, 0.7))
			ImGui.PushStyleColor(ImGuiCol.Text, textCol.r, textCol.g, textCol.b, textCol.a)
		end

		ImGui.SetCursorPosX(ImGui.GetCursorPosX() + firstCursorPos)
		if (ImGui.Button(_T("GENERIC_CONFIRM"), buttonSize.x, buttonSize.y)) then
			v = true
			ImGui.CloseCurrentPopup()
		end

		if (boxStyle > 0) then
			ImGui.PopStyleColor(4)
		end

		ImGui.SameLine()
		ImGui.SetCursorPosX(ImGui.GetCursorPosX() + buttonSize.x - spacing)

		if (ImGui.Button(_T("GENERIC_CANCEL"), buttonSize.x, buttonSize.y)) then
			v = false
			ImGui.CloseCurrentPopup()
		end

		ImGui.Spacing()
		ImGui.EndPopup()
	end

	return v
end
