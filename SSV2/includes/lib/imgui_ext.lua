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

---@enum SpinnerStyle
ImGui.SpinnerStyle = {
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

---@param label? string
---@param speed? float
---@param style? SpinnerStyle
function ImGui.TextSpinner(label, speed, style)
	speed = speed or 7.0
	style = style or 1
	if (label) then
		ImGui.Text(label)
		ImGui.SameLine()
	end

	local charlist = spinner_chars[style]
	local time     = ImGui.GetTime()
	local index    = math.floor(math.fmod(time * speed, #charlist)) + 1
	ImGui.Text(charlist[index])
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
---@param inColor uint32_t
---@return uint32_t, boolean
function ImGui.ColorEditU32(label, inColor)
	local temp, changed = { Color(inColor):AsFloat() }, false
	temp, changed = ImGui.ColorEdit4(label, temp)
	if (changed) then
		return Color(temp):AsU32(), changed
	end

	return inColor, changed
end

---@param label string
---@param stringBuffer string
---@param maxWidth? number
---@param flags? integer ImGuiInputTextFlags
---@return string, boolean
function ImGui.SearchBar(label, stringBuffer, maxWidth, flags)
	if (maxWidth) then
		ImGui.SetNextItemWidth(maxWidth)
	end

	local out, changed = ImGui.InputTextWithHint(label, "Search", stringBuffer, SizeOf(stringBuffer), flags or 0)
	return out, changed
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
