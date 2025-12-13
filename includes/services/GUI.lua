---@diagnostic disable: param-type-mismatch, lowercase-global

GVars.keyboard_keybinds.gui_toggle = GVars.keyboard_keybinds.gui_toggle or "F5"
local Tab = require("includes.modules.Tab")
local WindowAnimator = require("includes.structs.WindowAnimator")
local ThemeManager = require("includes.services.ThemeManager")
local debug_counter = GVars.backend.debug_mode and 7 or 0
local DrawClock = require("includes.frontend.clock")

---@class WindowRequest
---@field m_should_draw boolean
---@field m_label string
---@field m_callback GuiCallback
---@field m_flags? integer
---@field m_size? vec2
---@field m_pos? vec2

---@enum eTabID
eTabID = {
	TAB_SELF     = 1,
	TAB_VEHICLE  = 2,
	TAB_WORLD    = 3,
	TAB_ONLINE   = 4,
	TAB_EXTRA    = 5,
	TAB_SETTINGS = 6,
}

---@type table<eTabID, table>
local defaultTabs = {}

---@type table<eTabID, string>
local tabIdToString = {}

for name, enum in pairs(eTabID) do
	defaultTabs[enum] = { first = "", second = {} }
	tabIdToString[enum] = string.replace(name, "TAB_", ""):titlecase():trim()
end

--#region GUI
--------------------------------------
-- GUI Class
--------------------------------------
---@class GUI : ClassMeta<GUI>
---@field private m_main_window_label string
---@field private m_seleted_tab Tab
---@field private m_selected_category eTabID
---@field private m_selected_category_tabs array<Pair<string, Tab>>
---@field private m_dummy_tab tab -- default YimMenu API tab object
---@field private m_tabs table<eTabID, array<Pair<string, Tab>>>
---@field private m_independent_windows array<GuiCallback>
---@field private m_requested_windows table<string, WindowRequest>
---@field private m_screen_resolution vec2
---@field private m_should_draw boolean
---@field private m_is_drawing_sidebar boolean
---@field private m_cursor_pos vec2
---@field private m_sidebar_width number
---@field private m_snap_animator WindowAnimator
local GUI = Class("GUI")

---@return GUI
function GUI:init()
	---@type GUI
	local instance = setmetatable({
		m_main_window_label = "##ss_main_window",
		m_should_draw = false,
		m_is_drawing_sidebar = false,
		m_cb_window_pos = vec2:zero(),
		m_screen_resolution = Game.GetScreenResolution(),
		m_sidebar_width = 200,
		m_tabs = defaultTabs,
		m_independent_windows = {},
		m_requested_windows = {},
		m_snap_animator = WindowAnimator()
	}, GUI)

	if (not GVars.ui.style.theme or not GVars.ui.style.theme.Colors) then
		GVars.ui.style.theme = ThemeManager:GetThemes().MidnightNeon
	end

	ThemeManager:SetCurrentTheme(GVars.ui.style.theme)

	gui.add_always_draw_imgui(function()
		instance:Draw()
	end)

	instance.m_dummy_tab = gui.add_tab(Backend.script_name or "Samurai's Scripts")
	instance.m_dummy_tab:add_imgui(function()
		instance:DrawDummyTab()
	end)

	KeyManager:RegisterKeybind(GVars.keyboard_keybinds.gui_toggle, function()
		instance:Toggle()
	end)

	Backend:RegisterEventCallback(eBackendEvent.RELOAD_UNLOAD, function()
		instance:Close()
	end)

	return instance
end

function GUI:LateInit()
	for _, drawfunc in ipairs(self.m_independent_windows) do
		gui.add_always_draw_imgui(drawfunc)
	end
end

function GUI:Toggle()
	self.m_should_draw = not self.m_should_draw
	gui.override_mouse(self.m_should_draw)
end

function GUI:Close()
	self.m_should_draw = false
	gui.override_mouse(false)
end

---@param align? number -- 0: top center | 1: bottom center | 2: left center | 3: right center | 4: center
function GUI:Snap(align)
	align = align or 0
	local size = GVars.ui.window_size
	local resolution = Game.GetScreenResolution()
	local _, center = self:GetNewWindowSizeAndCenterPos(0.5, 0.8, size)
	local top_center = vec2:new(center.x, 0)
	local endPos = Switch(align) {
		[0] = top_center,
		[1] = vec2:new(center.x, resolution.y - size.y),
		[2] = vec2:new(0, center.y),
		[3] = vec2:new(resolution.x - size.x, center.y),
		[4] = center,
		default = top_center
	}

	self.m_snap_animator:Init(self.m_main_window_label, GVars.ui.window_pos, endPos, 0.3)
	self:PlaySound(self.Sounds.Nav)
end

function GUI:ResetWidth()
	local default_size, _ = self:GetNewWindowSizeAndCenterPos(0.45, 0.8)
	ImGui.SetWindowSize(self.m_main_window_label, default_size.x, GVars.ui.window_size.y, ImGuiCond.Always)
	GVars.ui.window_size.x = default_size.x
end

function GUI:ResetHeight()
	local default_size, _ = self:GetNewWindowSizeAndCenterPos(0.45, 0.8)
	ImGui.SetWindowSize(self.m_main_window_label, GVars.ui.window_size.x, default_size.y, ImGuiCond.Always)
	GVars.ui.window_size.y = default_size.y
end

function GUI:ResetSize()
	local default_size, _ = self:GetNewWindowSizeAndCenterPos(0.45, 0.8)
	ImGui.SetWindowSize(self.m_main_window_label, default_size.x, default_size.y, ImGuiCond.Always)
	GVars.ui.window_size = default_size
end

function GUI:IsOpen()
	return self.m_should_draw
end

function GUI:GetCurrentTab()
	return self.m_seleted_tab
end

---@param id eTabID Category
---@param name string
---@return boolean
function GUI:DoesTabExist(id, name)
	for _, pair in ipairs(self.m_tabs[id]) do
		if (pair.first == name) then
			return true
		end
	end

	return false
end

---@param id eTabID Category
---@param name string
---@param drawable? function
---@param subtabs? Tab[]
---@return Tab
function GUI:RegisterNewTab(id, name, drawable, subtabs)
	assert((not string.isnullorempty(name)), "Attempt to register a new tab with no name.")

	if (self:DoesTabExist(id, name)) then
		error(_F("Tab '%s' already exists.", name))
	end

	local newtab = Pair:new(name, Tab(name, drawable, subtabs))
	table.insert(self.m_tabs[id], newtab)

	return newtab.second
end

---@param id eTabID Category
---@param name string
---@return Tab?
function GUI:GetTab(id, name)
	for _, pair in ipairs(self.m_tabs[id]) do
		if (pair.first == name) then
			return pair.second
		end
	end
end

---@param id eTabID Category
---@param name string
---@param parent_name string
---@return Tab?
function GUI:GetSubtab(id, name, parent_name)
	local parent = self:GetTab(id, parent_name)
	if (not parent) then
		self:notify("A parent tab with the name '%s' does not exist.", parent_name)
		return
	end

	local child = parent:GetSubtab(name)
	if (not child) then
		self:notify("A sub-tab with the name '%s' does not exist.", name)
		return
	end

	return child
end

-- Registers an independent window that can only be drawn when the menu is open.
---@param windowData WindowRequest
function GUI:RequestWindow(windowData)
	if (type(windowData.m_label) ~= "string" or windowData.m_label:isnullorempty()) then
		log.warning("[GUI]: Failed to register window request. Invalid window name")
		return
	end

	if (self.m_requested_windows[windowData.m_label]) then
		log.fwarning("[GUI]: Failed to register window request. A window with the name %s already exists!",
			windowData.m_label)
		return
	end

	self.m_requested_windows[windowData.m_label] = windowData
end

---@param label string
---@param toggle boolean
function GUI:SetRequestedWindowDraw(label, toggle)
	local req = self.m_requested_windows[label]
	if (not req) then
		return
	end

	req.m_should_draw = toggle
end

-- Registers an independent window that can be drawn without the menu open.
---@param drawfunc function
function GUI:RegisterIndependentGUI(drawfunc)
	if (type(drawfunc) ~= "function") then
		log.debug("not a function")
		return
	end

	table.insert(self.m_independent_windows, drawfunc)
end

---@param fmt string
---@param ... any
function GUI:Notify(fmt, ...)
	local msg = (... ~= nil) and _F(fmt, ...) or fmt
	local name = Backend.script_name:replace("_", " "):titlecase()
	Toast:ShowMessage(name, msg)
end

-- Calculates a new window size and center position vectors in relation to the screen resolution.
---@param x_mod float x modifier (ex: 0.5)
---@param y_mod float y modifier (ex: 0.3)
---@param custom_size? vec2
---@return vec2, vec2 -- size, center position
function GUI:GetNewWindowSizeAndCenterPos(x_mod, y_mod, custom_size)
	if (self.m_screen_resolution:is_zero()) then
		self.m_screen_resolution = Game.GetScreenResolution()
	end

	local size = custom_size or vec2:new(
		self.m_screen_resolution.x * x_mod,
		self.m_screen_resolution.y * y_mod
	)
	local center = vec2:new(
		(self.m_screen_resolution.x - size.x) / 2,
		(self.m_screen_resolution.y - size.y) / 2
	)

	return size, center
end

---@param desired vec2
function GUI:GetMaxSizeForWindow(desired)
	local maxwidth = math.min(desired.x, GVars.ui.window_size.x - 20)
	local maxheight = math.min(desired.y, GVars.ui.window_size.y - 20)
	return vec2:new(maxwidth, maxheight)
end

function GUI:DrawDummyTab()
	ImGui.SetNextWindowBgAlpha(0)
	DrawClock()
	ImGui.Dummy(1, 10)
	ImGui.SetWindowFontScale(1.2)
	ImGui.SeparatorText("Important")
	ImGui.SetWindowFontScale(1.0)
	ImGui.Text(_F("The script's UI is now independent from the menu. Press %s to toggle it.",
		GVars.keyboard_keybinds.gui_toggle or "F5"))
	ImGui.Spacing()
	ImGui.Separator()

	ImGui.SetNextWindowBgAlpha(0)
	if ImGui.BeginChild("footer", -1, 40, false) then
		ImGui.Spacing()
		ImGui.TextDisabled(("v%s"):format(Backend.__version))
		if (self:IsItemClicked(self.MouseButtons.LEFT)) then
			debug_counter = debug_counter + 1

			if (debug_counter == 7) then
				self:PlaySound(GUI.Sounds.Nav)
				log.debug("Debug mode activated.")
				GVars.backend.debug_mode = true
			elseif (debug_counter > 7) then
				self:PlaySound(GUI.Sounds.Cancel)
				log.debug("Debug mode deactivated.")
				GVars.backend.debug_mode = false
				debug_counter = 0
			end
		end
		ImGui.EndChild()
	end
end

---@param bgColor Color
---@return Color
function GUI:GetAutoTextColor(bgColor)
	return bgColor:IsDark() and Color("white") or Color("black")
end

local underlineX = 0.0
local underlineW = 0.0
local underlineTargetX = 0.0
local underlineTargetW = 0.0
local underlineSet = false
function GUI:DrawTopBar()
	local drawList = ImGui.GetWindowDrawList()
	local spacing = 10
	local availWidth, _ = ImGui.GetContentRegionAvail()
	local elemWidth = 90.0
	local elemHeight = 40.0
	local tabHeight = 50.0
	local tabCount = table.getlen(tabIdToString)
	local totalWidth = tabCount * elemWidth + (tabCount - 1) * spacing
	local startX = (availWidth - totalWidth) * 0.5
	local cursorPos = vec2:new(ImGui.GetCursorScreenPos())
	local _col1 = GVars.ui.style.theme.TopBarFrameCol1
	local _col2 = GVars.ui.style.theme.TopBarFrameCol2

	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + startX)

	for i = 1, tabCount do
		local tabName = tabIdToString[i]
		local selected = (self.m_selected_category == i)

		cursorPos = vec2:new(ImGui.GetCursorScreenPos())
		local yCenter = cursorPos.y + tabHeight * 0.5 - elemHeight * 0.5
		local elemPos = vec2:new(cursorPos.x, yCenter)
		local rect = Rect(elemPos, vec2:new(elemPos.x + elemWidth, elemPos.y + elemHeight))
		local rectSize = rect:GetSize()

		ImGui.PushID(i)
		ImGui.InvisibleButton(tabName, rectSize.x, rectSize.y)
		local hovered = ImGui.IsItemHovered()
		local clicked = ImGui.IsItemClicked()
		local held = (hovered and KeyManager:IsKeyPressed(eVirtualKeyCodes.VK_LBUTTON))
		local rectMod = vec2:new((held or clicked) and 1 or 0, (held or clicked) and 1 or 0)

		if (not underlineSet) then
			underlineTargetX = rect.min.x
			underlineTargetW = elemWidth
			underlineSet = true
		end

		local selectedColor1 = Color(_col1.x, _col1.y, _col1.z, held and _col1.w or 230)
		local selectedColor2 = Color(_col2.x, _col2.y, _col2.z, held and _col2.w or 255)
		local defaultColor1  = Color(60, 60, 80, held and 100 or 150)
		local defaultColor2  = Color(80, 80, 110, held and 130 or 180)
		local col1           = selected and selectedColor1 or defaultColor1
		local col2           = selected and selectedColor2 or defaultColor2
		if (hovered or selected) then
			ImGui.ImDrawListAddRectFilledMultiColor(
				drawList,
				rect.min.x + rectMod.x,
				rect.min.y + rectMod.y,
				rect.max.x - rectMod.x,
				rect.max.y - rectMod.y,
				col1:AsU32(),
				col2:AsU32(),
				col2:AsU32(),
				col1:AsU32()
			)
		end

		local textSize = vec2:new(ImGui.CalcTextSize(tabName))
		local textPos = vec2:new(
			rect.min.x + (elemWidth - textSize.x) * 0.5,
			rect.min.y + (elemHeight - textSize.y) * 0.5
		)

		local bg = (hovered or selected) and col1 or Color(GVars.ui.style.theme.Colors.WindowBg:unpack())
		local textColor = self:GetAutoTextColor(bg)
		ImGui.ImDrawListAddText(
			drawList,
			textPos.x,
			textPos.y,
			textColor:AsU32(),
			tabName
		)

		if (clicked) then
			if (self.m_selected_category ~= i and self.m_seleted_tab) then
				self.m_seleted_tab = nil
			end

			self.m_selected_category = i
			self.m_selected_category_tabs = self.m_tabs[i]
			self:PlaySound(self.Sounds.Nav)
			underlineTargetX = rect.min.x
			underlineTargetW = elemWidth
		end

		if (selected) then
			underlineTargetX = rect.min.x
			underlineTargetW = elemWidth;
		end

		ImGui.PopID()

		if (i < tabCount) then
			ImGui.SameLine()
		end
	end

	underlineX = underlineX + (underlineTargetX - underlineX) * 0.15
	underlineW = underlineW + (underlineTargetW - underlineW) * 0.15

	local underlineHeight = 3.0
	local underlinePos = vec2:new(underlineX, cursorPos.y + tabHeight - underlineHeight)
	local underlineEnd = vec2:new(underlineX + underlineW, underlinePos.y + underlineHeight)
	local underlineCol = Color(_col1.x, _col1.y, _col1.z, 255):AsU32()
	ImGui.ImDrawListAddRectFilled(
		drawList,
		underlineX,
		underlinePos.y,
		underlineEnd.x,
		underlineEnd.y,
		underlineCol,
		1.5
	)

	ImGui.Separator()
	self.m_cursor_pos = vec2:new(ImGui.GetCursorScreenPos())
end

function GUI:DrawSideBar()
	if (not self.m_selected_category or not tabIdToString[self.m_selected_category]) then
		self.m_is_drawing_sidebar = false
		return
	end

	self.m_selected_category_tabs = self.m_selected_category_tabs or {}
	local ctabsCount = #self.m_selected_category_tabs
	if (ctabsCount > 1) then
		local selectableSize = vec2:new(self.m_sidebar_width - 30, 32)
		local style = ImGui.GetStyle()

		ImGui.SetNextWindowBgAlpha(GVars.ui.style.bg_alpha)
		ImGui.SetNextWindowPos(GVars.ui.window_pos.x + (style.FramePadding.x * 3), self.m_cursor_pos.y, ImGuiCond.Always)
		ImGui.SetNextWindowSizeConstraints(self.m_sidebar_width, 0, self.m_sidebar_width, GVars.ui.window_size.y)
		ThemeManager:PushTheme()
		if (ImGui.Begin("##ss_side_bar",
				ImGuiWindowFlags.NoTitleBar |
				ImGuiWindowFlags.NoResize |
				ImGuiWindowFlags.NoMove |
				ImGuiWindowFlags.AlwaysAutoResize)
			) then
			for _, pair in ipairs(self.m_selected_category_tabs or {}) do
				if (pair and pair.second) then
					local tab = pair.second
					if (self:Selectable2(pair.first, self.m_seleted_tab == tab, selectableSize)) then
						self:PlaySound(self.Sounds.Nav)
						self.m_seleted_tab = tab
					end
				end
			end
		end
		ImGui.End()
		ThemeManager:PopTheme()
		self.m_is_drawing_sidebar = true
	elseif (ctabsCount == 1) then
		self.m_seleted_tab = self.m_selected_category_tabs[1].second
		self.m_is_drawing_sidebar = false
	end
end

function GUI:Draw()
	if (not self.m_should_draw) then
		return
	end

	if (not gui.mouse_override()) then
		gui.override_mouse(true)
	end

	local default_size, default_pos = self:GetNewWindowSizeAndCenterPos(0.45, 0.8)
	default_pos.y = 0
	local windowFlags = ImGuiWindowFlags.NoTitleBar
		| ImGuiWindowFlags.NoResize
		| ImGuiWindowFlags.NoBackground
		| ImGuiWindowFlags.NoBringToFrontOnFocus

	if (GVars.ui.moveable) then
		windowFlags = Bit.clear(windowFlags, ImGuiWindowFlags.NoMove)
	else
		windowFlags = Bit.set(windowFlags, ImGuiWindowFlags.NoMove)
	end

	if (GVars.ui.window_pos:is_zero()) then
		ImGui.SetNextWindowPos(default_pos.x, default_pos.y, ImGuiCond.Always)
		GVars.ui.window_pos = default_pos
	else
		ImGui.SetNextWindowPos(default_pos.x, default_pos.y,
			GVars.ui.moveable and ImGuiCond.FirstUseEver or ImGuiCond.Always)
	end

	if (GVars.ui.window_size:is_zero()) then
		ImGui.SetNextWindowSize(default_size.x, default_size.y, ImGuiCond.Always)
		GVars.ui.window_size = default_size
	else
		ImGui.SetNextWindowSize(GVars.ui.window_size.x, GVars.ui.window_size.y, ImGuiCond.Always)
	end

	self.m_snap_animator:Apply()

	ThemeManager:PushTheme()
	ImGui.SetNextWindowBgAlpha(0)
	if (ImGui.Begin(self.m_main_window_label, windowFlags)) then
		ImGui.SetNextWindowBgAlpha(GVars.ui.style.bg_alpha)
		ImGui.BeginChild("##ss_top_bar", 0, 110)
		local fontScale = 1.5
		local titleWidth = ImGui.CalcTextSize("Samurai's Scripts") * fontScale
		local winWidth = ImGui.GetWindowWidth()
		ImGui.SetCursorPosX((winWidth - titleWidth) / 2)
		ImGui.SetWindowFontScale(fontScale)
		ImGui.Text("Samurai's Scripts")
		ImGui.SetWindowFontScale(1)
		ImGui.Spacing()
		self:DrawTopBar()
		ImGui.EndChild()

		GVars.ui.window_pos = vec2:new(ImGui.GetWindowPos())
		ImGui.End()
	end
	ThemeManager:PopTheme()

	if (self.m_is_drawing_sidebar) then
		self.m_cursor_pos.x = self.m_cursor_pos.x + self.m_sidebar_width + 10
	end

	self.m_cursor_pos.y = self.m_cursor_pos.y + 7 -- the fuck is this weird padding bruh
	if (self.m_seleted_tab) then
		local fixedWidth = self.m_is_drawing_sidebar and (GVars.ui.window_size.x - self.m_sidebar_width - 40) or
		GVars.ui.window_size.x - 30
		ImGui.SetNextWindowBgAlpha(GVars.ui.style.bg_alpha)
		ImGui.SetNextWindowPos(self.m_cursor_pos.x, self.m_cursor_pos.y, ImGuiCond.Always)
		ImGui.SetNextWindowSizeConstraints(fixedWidth, 20, fixedWidth, GVars.ui.window_size.y - 10)
		ThemeManager:PushTheme()
		if (ImGui.Begin("##ss_callback_window",
				ImGuiWindowFlags.NoTitleBar |
				ImGuiWindowFlags.NoMove |
				ImGuiWindowFlags.AlwaysAutoResize)
			) then
			ImGui.PushTextWrapPos(fixedWidth - 10)
			self.m_seleted_tab:Draw()
			ImGui.PopTextWrapPos()
			ImGui.End()
		end
		ThemeManager:PopTheme()
	end

	self:DrawSideBar()

	for label, window in pairs(self.m_requested_windows) do
		if (window.m_should_draw) then
			-- if (window.m_pos) then
			--     ImGui.SetNextWindowPos(window.m_pos.x, window.m_pos.y, ImGuiCond.Always)
			-- end
			if (window.m_size) then
				ImGui.SetNextWindowSize(window.m_size.x, window.m_size.y, ImGuiCond.Always)
			end

			ThemeManager:PushTheme()
			if (ImGui.Begin(label, window.m_flags)) then
				window.m_callback()
				ImGui.End()
			end
			ThemeManager:PopTheme()
		end
	end
end

--#region Wrappers

-- Wrapper for `ImGui::TextColored`.
---@param text string
---@param color Color
---@param opts? { alpha: number, wrap_pos: number }
function GUI:TextColored(text, color, opts)
	opts = opts or {}
	local r, g, b, a -- fwd decl
	local has_wrap_pos = type(opts.wrap_pos) == "number"

	if (not IsInstance(color, Color)) then
		r, g, b, a = 1, 0.1, 0, 1
	end

	r, g, b, a = color:AsFloat()
	ImGui.PushStyleColor(ImGuiCol.Text, r, g, b, opts.alpha or a or 1)

	if (has_wrap_pos) then
		ImGui.PushTextWrapPos(opts.wrap_pos)
	end

	ImGui.TextWrapped(text)
	ImGui.PopStyleColor(1)

	if (has_wrap_pos) then
		ImGui.PopTextWrapPos()
	end
end

-- Displays a tooltip whenever the widget this function is called after is hovered.
---@param text string
---@param opts? { color: Color, alpha: number, wrap_pos: number }
function GUI:Tooltip(text, opts)
	if (GVars.ui.disable_tooltips) then
		return
	end

	opts = opts or {}
	wrap_pos = opts.wrap_pos or ImGui.GetFontSize() * 25

	if (ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled)) then
		ImGui.SetNextWindowBgAlpha(GVars.ui.style.bg_alpha)
		ImGui.BeginTooltip()
		if IsInstance(opts.color, Color) then
			self:TextColored(text, opts.color, wrap_pos)
		else
			ImGui.PushTextWrapPos(wrap_pos)
			ImGui.TextWrapped(text)
			ImGui.PopTextWrapPos()
		end
		ImGui.EndTooltip()
	end
end

-- Creates a help marker `(?)` symbol in front of the widget this function is called after.
--
-- When the symbol is hovered, it displays a tooltip.
---@param text string
---@param opts? { color: Color, alpha: number, wrap_pos: number }
function GUI:HelpMarker(text, opts)
	if (GVars.ui.disable_tooltips) then
		return
	end

	ImGui.SameLine()
	ImGui.TextDisabled("(?)")
	self:Tooltip(text, opts)
end

-- Displays a multiline tooltip when the ImGui widget this function is called after is hovered.
---@param lines string[]
---@param wrap_pos? number
function GUI:TooltipMultiline(lines, wrap_pos)
	if (GVars.ui.disable_tooltips) then
		return
	end

	wrap_pos = wrap_pos or (ImGui.GetFontSize() * 25)

	if (ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled)) then
		ImGui.SetNextWindowBgAlpha(GVars.ui.style.bg_alpha)
		ImGui.BeginTooltip()
		ImGui.PushTextWrapPos(wrap_pos)
		for _, line in pairs(lines) do
			if not string.iswhitespace(line) then
				ImGui.Text(line)
				ImGui.Spacing()
			end
		end
		ImGui.PopTextWrapPos()
		ImGui.EndTooltip()
	end
end

-- Draws a small confirmation popup window with Yes/No buttons.
--
-- Can execute a callback function on confirmation.
---@param name string
---@param callback function
---@param ... any
function GUI:ConfirmPopup(name, callback, ...)
	if ImGui.BeginPopupModal(
			name,
			ImGuiWindowFlags.NoTitleBar |
			ImGuiWindowFlags.AlwaysAutoResize
		) then
		local buttonSize = vec2:new(80, 30)
		ImGui.PushTextWrapPos(ImGui.GetWindowWidth() - 10)
		self:TextColored("Are you sure?", Color("yellow"), { alpha = 0.9 })
		ImGui.Spacing()

		if (self:Button("Yes", { size = buttonSize })) then
			callback(...)
			ImGui.CloseCurrentPopup()
		end

		ImGui.SameLine()
		ImGui.Dummy(20, 1)
		ImGui.SameLine()

		if (self:Button("No", { size = buttonSize })) then
			ImGui.CloseCurrentPopup()
		end

		ImGui.PopTextWrapPos()
		ImGui.EndPopup()
		return true
	end
end

-- A simple window for features to draw further customizations (drift power, NOS effects, engine swap, etc.)
---@param label string
---@param callback GuiCallback
---@param onClose function -- Close button callback
function GUI:QuickConfigWindow(label, callback, onClose)
	local size = vec2:new(ImGui.GetWindowSize())
	local _, center = self:GetNewWindowSizeAndCenterPos(0.5, 0.5, size)
	ImGui.SetWindowPos(center.x, center.y)

	ImGui.SeparatorText(label)
	if (self:Button("Close")) then
		onClose()
		return
	end

	if (type(callback) ~= "function") then
		return
	end

	ImGui.Separator()
	ImGui.Dummy(0, 10)
	callback()
end

-- Checks if an ImGui widget was clicked.
---@param button GUI.MouseButtons
---@return boolean
function GUI:IsItemClicked(button)
	if (button == self.MouseButtons.LEFT) then
		return (ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and ImGui.IsItemClicked(0))
	elseif (button == self.MouseButtons.RIGHT) then
		return (ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and ImGui.IsItemClicked(1))
	end

	return false
end

-- Sets the clipboard text.
---@param text string
---@param eval? function
function GUI:SetClipBoardText(text, eval)
	if (type(eval) == "function" and not eval()) then
		return
	end

	self:PlaySound(self.Sounds.Click)
	ImGui.SetClipboardText(text)
	self:Notify("Link copied to clipboard.")
end

-- Plays a sound when an ImGui widget is clicked.
---@param sound string|table
function GUI:PlaySound(sound)
	if GVars.ui.disable_sound_feedback then
		return
	end

	local _sound = (type(sound) == "string") and self.Sounds[sound] or sound
	if (not _sound) then
		return
	end

	ThreadManager:RunInFiber(function()
		AUDIO.PLAY_SOUND_FRONTEND(-1, _sound.soundName, _sound.soundRef, false)
	end)
end

---@param label string
---@param bool boolean
---@param opts? { tooltip?: string, color?: Color, onClick?: function }
---@return boolean, boolean
function GUI:Checkbox(label, bool, opts)
	local clicked = false
	bool, clicked = ImGui.Checkbox(label, bool)

	if (clicked) then
		self:PlaySound(self.Sounds.Checkbox)
		if (opts and type(opts.onClick) == "function") then
			opts.onClick()
		end
	end

	if (opts and opts.tooltip) then
		self:Tooltip(opts.tooltip, opts.color)
	end

	return bool, clicked
end

---@param label string
---@param opts? { size?: vec2, repeatable?: boolean, tooltip?: string }
function GUI:Button(label, opts)
	opts = opts or {}
	opts.size = opts.size or vec2:zero()

	ImGui.PushButtonRepeat(opts.repeatable or false)
	local pressed = ImGui.Button(label, opts.size.x, opts.size.y)
	ImGui.PopButtonRepeat()
	if (opts.tooltip) then
		self:Tooltip(opts.tooltip)
	end

	if (pressed) then
		self:PlaySound(self.Sounds.Button)
	end

	return pressed
end

---@param label string
---@param color Color
---@param hover_color Color
---@param active_color Color
---@param opts? { size?: vec2, repeatable?: boolean }
function GUI:ButtonColored(label, color, hover_color, active_color, opts)
	ImGui.PushStyleColor(ImGuiCol.Button, color:AsRGBA())
	ImGui.PushStyleColor(ImGuiCol.ButtonHovered, hover_color:AsRGBA())
	ImGui.PushStyleColor(ImGuiCol.ButtonActive, active_color:AsRGBA())
	local pressed = self:Button(label, opts)
	ImGui.PopStyleColor(3)

	if (pressed) then
		self:PlaySound(self.Sounds.Button)
	end

	return pressed
end

--- Draws an ImGui item and handles enabling/disabling it on `condition`.
---@generic T1, T2, T3, T4, T5
---@param ImGuiItem fun(...: any): T1, T2, T3, T4, T5
---@param condition boolean Disables the item when true.
---@param ... any
---@return T1, T2, T3, T4, T5, ...
function GUI:ConditionalItem(ImGuiItem, condition, ...)
	ImGui.BeginDisabled(condition)
	local ret = table.pack(ImGuiItem(...))
	ImGui.EndDisabled()

	return table.unpack(ret)
end

---@param label string
---@param stringBuffer string
---@param maxWidth? number
---@param flags? ImGuiInputTextFlags
---@return string, boolean
function GUI:SearchBar(label, stringBuffer, maxWidth, flags)
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
function GUI:Selectable2(label, selected, size, shouldHighlight, highlightColor)
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

	if (shouldHighlight) then
		ImGui.ImDrawListAddRectFilled(
			drawList,
			pos.x,
			pos.y,
			max.x,
			max.y,
			highlightColor,
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
	local textCol = selected and Color(GVars.ui.style.theme.TopBarFrameCol1:unpack()) or self:GetAutoTextColor(windowBg)

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

-- ---@param label string
-- ---@param outVector vec4
-- ---@return boolean
-- function GUI:ColorEditVec4(label, outVector)
--     if (not IsInstance(outVector, vec4)) then
--         self:Notify("Invalid argument #2: vec4 expected, got %s instead.", type(vec4))
--     end

--     local temp, changed = {}, false
--     temp, changed = ImGui.ColorEdit4(label, temp)
--     if (changed) then
--         outVector.x = temp[1]
--         outVector.y = temp[2]
--         outVector.z = temp[3]
--         outVector.w = temp[4]
--     end
--     return changed
-- end

--#endregion

--#region metadata
GUI.Sounds = {
	Radar = {
		soundName = "RADAR_ACTIVATE",
		soundRef = "DLC_BTL_SECURITY_VANS_RADAR_PING_SOUNDS"
	},
	Button = {
		soundName = "SELECT",
		soundRef = "HUD_FRONTEND_DEFAULT_SOUNDSET"
	},
	Pickup = {
		soundName = "PICK_UP",
		soundRef = "HUD_FRONTEND_DEFAULT_SOUNDSET"
	},
	Pickup_alt = {
		soundName = "PICK_UP_WEAPON",
		soundRef = "HUD_FRONTEND_CUSTOM_SOUNDSET"
	},
	Fail = {
		soundName = "CLICK_FAIL",
		soundRef = "WEB_NAVIGATION_SOUNDS_PHONE"
	},
	Click = {
		soundName = "CLICK_LINK",
		soundRef = "DLC_H3_ARCADE_LAPTOP_SOUNDS"
	},
	Notify = {
		soundName = "LOSE_1ST",
		soundRef = "GTAO_FM_EVENTS_SOUNDSET"
	},
	Delete = {
		soundName = "DELETE",
		soundRef = "HUD_DEATHMATCH_SOUNDSET"
	},
	Cancel = {
		soundName = "CANCEL",
		soundRef = "HUD_FREEMODE_SOUNDSET"
	},
	Error = {
		soundName = "ERROR",
		soundRef = "HUD_FREEMODE_SOUNDSET"
	},
	Nav = {
		soundName = "NAV_LEFT_RIGHT",
		soundRef = "HUD_FREEMODE_SOUNDSET"
	},
	Checkbox = {
		soundName = "NAV_UP_DOWN",
		soundRef = "HUD_FREEMODE_SOUNDSET"
	},
	Select_alt = {
		soundName = "CHANGE_STATION_LOUD",
		soundRef = "RADIO_SOUNDSET"
	},
	Focus_in = {
		soundName = "FOCUSIN",
		soundRef = "HINTCAMSOUNDS"
	},
	Focus_out = {
		soundName = "FOCUSOUT",
		soundRef = "HINTCAMSOUNDS"
	},
}

---@enum GUI.MouseButtons
GUI.MouseButtons = {
	LEFT = 0x0,
	RIGHT = 0x1
}

--#endregion

return GUI
