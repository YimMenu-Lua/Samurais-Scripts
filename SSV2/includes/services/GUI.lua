---@diagnostic disable: param-type-mismatch, lowercase-global

GVars.keyboard_keybinds.gui_toggle = GVars.keyboard_keybinds.gui_toggle or "F5"
local Tab = require("includes.modules.Tab")
local WindowAnimator = require("includes.services.WindowAnimator")
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
Enums.eTabID = {
	TAB_SELF     = 1,
	TAB_VEHICLE  = 2,
	TAB_WORLD    = 3,
	TAB_ONLINE   = 4,
	TAB_EXTRA    = 5,
	TAB_SETTINGS = 6,
}

local TABID_MIN <const> = 1
local TABID_MAX <const> = table.getlen(Enums.eTabID)

---@type table<eTabID, table>
local defaultTabs = {}

---@type table<eTabID, string>
local tabIdToString <const> = {
	[Enums.eTabID.TAB_SELF]     = "TAB_SELF",
	[Enums.eTabID.TAB_VEHICLE]  = "TAB_VEHICLE",
	[Enums.eTabID.TAB_WORLD]    = "TAB_WORLD",
	[Enums.eTabID.TAB_ONLINE]   = "TAB_ONLINE",
	[Enums.eTabID.TAB_EXTRA]    = "TAB_EXTRA",
	[Enums.eTabID.TAB_SETTINGS] = "GENERIC_SETTINGS_LABEL",
	default                     = "GENERIC_ERR_LABEL"
}

for _, enum in pairs(Enums.eTabID) do
	defaultTabs[enum] = { first = "", second = {} }
end

--#region GUI
--------------------------------------
-- GUI Class
--------------------------------------
---@class GUI : ClassMeta<GUI>
---@field private m_main_window_label string
---@field private m_selected_tab Tab
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
---@field private m_notifier_pos vec2
local GUI = Class("GUI")

---@return GUI
function GUI:init()
	---@type GUI
	local instance = setmetatable({
		m_main_window_label = "##ss_main_window",
		m_should_draw = false,
		m_is_drawing_sidebar = false,
		m_cb_window_pos = vec2:zero(),
		m_notifier_pos = vec2:zero(),
		m_screen_resolution = Game.GetScreenResolution(),
		m_sidebar_width = 200,
		m_selected_category = Enums.eTabID.TAB_SELF,
		m_tabs = defaultTabs,
		m_independent_windows = {},
		m_requested_windows = {},
		m_snap_animator = WindowAnimator()
	}, GUI)

	ThemeManager:Load()

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

	Backend:RegisterEventCallback(Enums.eBackendEvent.RELOAD_UNLOAD, function()
		instance:Close()
	end)

	return instance
end

function GUI:LateInit()
	for _, drawfunc in ipairs(self.m_independent_windows) do
		gui.add_always_draw_imgui(drawfunc)
	end

	if (not math.isinrange(GVars.ui.last_tab.tab_id, TABID_MIN, TABID_MAX)) then
		GVars.ui.last_tab.tab_id = 1
	end

	local __t = self.m_tabs[GVars.ui.last_tab.tab_id][GVars.ui.last_tab.array_index]
	if (not __t) then
		GVars.ui.last_tab.array_index = 1
	end

	self.m_selected_category      = GVars.ui.last_tab.tab_id
	self.m_selected_tab           = self.m_tabs[GVars.ui.last_tab.tab_id][GVars.ui.last_tab.array_index].second
	self.m_selected_category_tabs = self.m_tabs[GVars.ui.last_tab.tab_id]
	self.m_is_drawing_sidebar     = #self.m_selected_category_tabs > 1
end

function GUI:Toggle()
	self.m_should_draw = not self.m_should_draw
	gui.override_mouse(self.m_should_draw)
end

function GUI:Close()
	self.m_should_draw = false
	gui.override_mouse(false)
end

---@return float
function GUI:GetMaxTopBarHeight()
	return Game.GetScreenResolution().y * 0.115
end

---@param align? number -- 0: top center | 1: bottom center | 2: left center | 3: right center | 4: center
function GUI:Snap(align)
	align = align or 0
	local resolution = Game.GetScreenResolution()
	local top_bar_height = resolution.y * 0.12
	local size = vec2:new(GVars.ui.window_size.x, GVars.ui.window_size.y + top_bar_height + 10)
	local _, center = self:GetNewWindowSizeAndCenterPos(0.5, 0.8, size)
	local top_center = vec2:new(center.x, 1)
	local endPos = Switch(align) {
		[0] = top_center,
		[1] = vec2:new(center.x, resolution.y - size.y),
		[2] = vec2:new(1, center.y),
		[3] = vec2:new(resolution.x - size.x - 1, center.y),
		[4] = center,
		default = top_center
	}

	self.m_snap_animator:Init(self.m_main_window_label, GVars.ui.window_pos, endPos, 3)
	self:PlaySound(self.Sounds.Nav)
end

function GUI:ResetWidth()
	local default_size, _ = self:GetNewWindowSizeAndCenterPos(0.45, 0.8)
	ImGui.SetWindowSize(self.m_main_window_label, default_size.x, self:GetMaxTopBarHeight(), ImGuiCond.Always)
	GVars.ui.window_size.x = default_size.x
end

function GUI:ResetHeight()
	local default_size, _ = self:GetNewWindowSizeAndCenterPos(0.45, 0.8)
	ImGui.SetWindowSize(self.m_main_window_label, GVars.ui.window_size.x, self:GetMaxTopBarHeight(), ImGuiCond.Always)
	GVars.ui.window_size.y = default_size.y
end

function GUI:ResetSize()
	local default_size, _ = self:GetNewWindowSizeAndCenterPos(0.45, 0.8)
	ImGui.SetWindowSize(self.m_main_window_label, default_size.x, self:GetMaxTopBarHeight(), ImGuiCond.Always)
	GVars.ui.window_size.x, GVars.ui.window_size.y = default_size.x, default_size.y
end

function GUI:IsOpen()
	return self.m_should_draw
end

function GUI:GetCurrentTab()
	return self.m_selected_tab
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
---@param isTranslatorLabel? boolean If you want to pass a translator key as the label, provide it as is without the `_T` function and set this to true.
---@return Tab
function GUI:RegisterNewTab(id, name, drawable, subtabs, isTranslatorLabel)
	assert((not string.isnullorempty(name)), "Attempt to register a new tab with no name.")

	if (self:DoesTabExist(id, name)) then
		error(_F("Tab '%s' already exists.", name))
	end

	local newtab = Pair.new(name, Tab(name, drawable, subtabs, isTranslatorLabel))
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
	Notifier:ShowMessage(name, msg)
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
	ImGui.BeginChild("##clock", 480, 400)
	DrawClock()
	ImGui.Dummy(1, 10)
	ImGui.SetWindowFontScale(1.2)
	ImGui.SeparatorText(_T("GENERIC_IMPORTANT"))
	ImGui.SetWindowFontScale(1.0)
	ImGui.TextWrapped(_F(_T("GUI_NEW_LAYOUT_NOTICE"), GVars.keyboard_keybinds.gui_toggle))
	ImGui.Spacing()
	ImGui.EndChild()

	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##footer", 480, 40)
	ImGui.Separator()
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
	local tabHeight = 55.0
	local tabCount = table.getlen(tabIdToString) - 1
	local totalWidth = tabCount * elemWidth + (tabCount - 1) * spacing
	local startX = (availWidth - totalWidth) * 0.5
	local cursorPos = vec2:new(ImGui.GetCursorScreenPos())
	local _col1 = GVars.ui.style.theme.TopBarFrameCol1
	local _col2 = GVars.ui.style.theme.TopBarFrameCol2

	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + startX)

	for i = 1, tabCount do
		local tabName = _T(Match(i, tabIdToString))
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
		local textColor = ImGui.GetAutoTextColor(bg)
		ImGui.ImDrawListAddText(
			drawList,
			textPos.x,
			textPos.y,
			textColor:AsU32(),
			tabName
		)

		if (clicked) then
			if (self.m_selected_category ~= i and self.m_selected_tab) then
				self.m_selected_tab = nil
			end

			GVars.ui.last_tab.tab_id = i
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

	underlineX = underlineX + (underlineTargetX - underlineX - 0.5) * 0.15
	underlineW = underlineW + (underlineTargetW - underlineW) * 0.15

	local underlineHeight = 4.0
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

---@param yPos float
function GUI:DrawSideBar(yPos)
	if (not self.m_selected_category or not tabIdToString[self.m_selected_category]) then
		self.m_is_drawing_sidebar = false
		return
	end

	self.m_selected_category_tabs = self.m_selected_category_tabs or {}
	local ctabsCount = #self.m_selected_category_tabs
	if (ctabsCount > 1) then
		local selectableSize = vec2:new(self.m_sidebar_width - 30, 32)
		ImGui.SetNextWindowBgAlpha(GVars.ui.style.bg_alpha)
		ImGui.SetNextWindowPos(GVars.ui.window_pos.x, yPos, ImGuiCond.Always)
		ImGui.SetNextWindowSizeConstraints(self.m_sidebar_width, 0, self.m_sidebar_width, GVars.ui.window_size.y)
		ThemeManager:PushTheme()
		if (ImGui.Begin("##ss_side_bar",
				ImGuiWindowFlags.NoTitleBar |
				ImGuiWindowFlags.NoResize |
				ImGuiWindowFlags.NoMove |
				ImGuiWindowFlags.NoBringToFrontOnFocus |
				ImGuiWindowFlags.AlwaysAutoResize)
			) then
			for i, pair in ipairs(self.m_selected_category_tabs) do
				if (pair and pair.second) then
					local tab = pair.second
					local label = tab:GetName()
					if (ImGui.Selectable2(label, self.m_selected_tab == tab, selectableSize)) then
						self:PlaySound(self.Sounds.Nav)
						self.m_selected_tab = tab
						GVars.ui.last_tab.array_index = i
					end
				end
			end
			ImGui.End()
		end
		ThemeManager:PopTheme()
		self.m_is_drawing_sidebar = true
	elseif (ctabsCount == 1) then
		self.m_selected_tab = self.m_selected_category_tabs[1].second
		self.m_is_drawing_sidebar = false
	end
end

function GUI:ShowWindowHeightLimit()
	local windowFlags = ImGuiWindowFlags.NoTitleBar
		| ImGuiWindowFlags.NoResize
		| ImGuiWindowFlags.NoBringToFrontOnFocus
		| ImGuiWindowFlags.NoScrollbar
		| ImGuiWindowFlags.AlwaysAutoResize
		| ImGuiWindowFlags.NoBackground

	local color = Color(GVars.ui.style.theme.TopBarFrameCol1:unpack())
	local top_height = self:GetMaxTopBarHeight()
	local pos = vec2:new(GVars.ui.window_pos.x, GVars.ui.window_pos.y + GVars.ui.window_size.y + top_height - 10)
	ImGui.SetNextWindowSize(GVars.ui.window_size.x + 10, 0)
	ImGui.SetNextWindowPos(pos.x - 10, pos.y)
	if (ImGui.Begin("##indicator", windowFlags)) then
		local ImDrawList = ImGui.GetWindowDrawList()
		local cursorPos = vec2:new(ImGui.GetCursorScreenPos())
		local p2 = vec2:new(cursorPos.x + GVars.ui.window_size.x, cursorPos.y)
		ImGui.ImDrawListAddLine(ImDrawList, cursorPos.x, cursorPos.y, p2.x, p2.y, color:AsU32(), 3)
		ImGui.End()
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
	default_pos.y = 1

	local windowFlags = ImGuiWindowFlags.NoTitleBar
		| ImGuiWindowFlags.NoResize
		| ImGuiWindowFlags.NoBringToFrontOnFocus
		| ImGuiWindowFlags.NoScrollbar

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

	local fixed_height = self:GetMaxTopBarHeight()
	if (GVars.ui.window_size:is_zero()) then
		ImGui.SetNextWindowSize(default_size.x, fixed_height, ImGuiCond.Always)
		GVars.ui.window_size = default_size
	else
		ImGui.SetNextWindowSize(GVars.ui.window_size.x, fixed_height, ImGuiCond.Always)
	end

	self.m_snap_animator:Apply()

	ThemeManager:PushTheme()
	ImGui.SetNextWindowBgAlpha(GVars.ui.style.bg_alpha)
	if (ImGui.Begin(self.m_main_window_label, windowFlags)) then
		local fontScale = 1.5
		local titleWidth = ImGui.CalcTextSize("Samurai's Scripts") * fontScale
		local winWidth = ImGui.GetWindowWidth()
		ImGui.SetCursorPosX((winWidth - titleWidth) / 2)
		ImGui.SetWindowFontScale(fontScale)
		ImGui.Text("Samurai's Scripts")
		ImGui.SetWindowFontScale(1)
		ImGui.SameLine()
		local nextPosX = ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - 40
		ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - 40)
		if (Notifier) then
			local count = Notifier:GetNotifCount()
			local label = Notifier:HasUnread() and "!" or ". . ."
			local tt = count > 0 and _F("%d %s", count, _T("GUI_NOTIFICATIONS_UNREAD")) or _T("GUI_NOTIFICATIONS")
			ImGui.SetWindowFontScale(0.8)
			if (self:Button(label, { size = vec2:new(35, 30) })) then
				Notifier:Toggle()
			end
			ImGui.SetWindowFontScale(1)
			self.m_notifier_pos = vec2:new(nextPosX, ImGui.GetCursorPosY())
			self:Tooltip(tt)
		end
		ImGui.Spacing()
		self:DrawTopBar()

		local current_pos = vec2:new(ImGui.GetWindowPos())
		GVars.ui.window_pos.x, GVars.ui.window_pos.y = current_pos.x, current_pos.y
		ImGui.End()
	end

	if (Notifier) then
		Notifier:DrawNotifications(self.m_notifier_pos)
	end
	ThemeManager:PopTheme()

	local next_y_pos = GVars.ui.window_pos.y + fixed_height + 10
	local cb_window_pos_x = GVars.ui.window_pos.x
	if (self.m_is_drawing_sidebar) then
		cb_window_pos_x = cb_window_pos_x + self.m_sidebar_width + 10
	end

	if (self.m_selected_tab) then
		local fixedWidth = self.m_is_drawing_sidebar
			and (GVars.ui.window_size.x - self.m_sidebar_width - 10)
			or GVars.ui.window_size.x

		ImGui.SetNextWindowBgAlpha(GVars.ui.style.bg_alpha)
		ImGui.SetNextWindowPos(cb_window_pos_x, next_y_pos, ImGuiCond.Always)
		ImGui.SetNextWindowSizeConstraints(fixedWidth, 20, fixedWidth, GVars.ui.window_size.y - 10)
		ThemeManager:PushTheme()
		if (ImGui.Begin("##ss_callback_window",
				ImGuiWindowFlags.NoTitleBar |
				ImGuiWindowFlags.NoMove |
				ImGuiWindowFlags.NoBringToFrontOnFocus |
				ImGuiWindowFlags.AlwaysAutoResize)
			) then
			ImGui.PushTextWrapPos(fixedWidth - 10)
			self.m_selected_tab:Draw()
			ImGui.PopTextWrapPos()
			ImGui.End()
		end
		ThemeManager:PopTheme()
	end

	self:DrawSideBar(next_y_pos)

	for label, window in pairs(self.m_requested_windows) do
		if (window.m_should_draw) then
			if (window.m_pos) then
				ImGui.SetNextWindowPos(window.m_pos.x, window.m_pos.y, ImGuiCond.Always)
			end

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

---@param text string
---@param opts? { scale: float, color: Color }
function GUI:HeaderText(text, opts)
	opts = opts or {}
	ImGui.SetWindowFontScale(opts.scale or 1.114)
	self:Text(text, opts)
	ImGui.SetWindowFontScale(1.0)
end

-- Wrapper for `ImGui::Text` that supports optional colors and text formatting.
--
-- To use formatting, pass the label as the format string and pass a table of arguments in the optional parameters.
--
-- **Example:**
--
--```Lua
-- GUI:Text("Found %s at 0x%X", { color = Color("green"), fmt = { "somePointer", 20015998343868 }})
---@param text string
---@param opts? { color: Color, alpha: number, wrap_pos: number, fmt: table } Optional parameters
function GUI:Text(text, opts)
	opts = opts or {}
	if (type(opts.fmt) == "table") then
		text = _F(text, table.unpack(opts.fmt))
	end

	if (not IsInstance(opts.color, Color)) then
		ImGui.TextWrapped(text)
		return
	end

	local has_wrap_pos = type(opts.wrap_pos) == "number"
	local r, g, b, a   = opts.color:AsFloat()

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
---@param opts? { color: Color, alpha: number, wrap_pos: number, fmt: table }
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
			self:Text(text, opts)
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
---@param opts? { color: Color, alpha: number, wrap_pos: number, fmt: table }
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

-- Draws a small confirmation popup window with Confirm/Cancel buttons.
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
--	ImGui.OpenPopup("myConfirmLabel")
-- end
--
-- if GUI:ConfirmPopup("myConfirmLabel") then
-- 	scary_func()
-- end
--```
---@param name string
function GUI:ConfirmPopup(name)
	local windowSize = vec2:new(420, 210)
	local _, pos = self:GetNewWindowSizeAndCenterPos(0.5, 0.5, windowSize)
	ImGui.SetNextWindowSize(windowSize.x, windowSize.y, ImGuiCond.Always)
	ImGui.SetNextWindowPos(pos.x, pos.y, ImGuiCond.Always)
	if ImGui.BeginPopupModal(
			name,
			ImGuiWindowFlags.NoTitleBar |
			ImGuiWindowFlags.NoMove |
			ImGuiWindowFlags.NoResize
		) then
		local buttonSize     = vec2:new(windowSize.x / 4, 35)
		local width          = windowSize.x
		local spacing        = ImGui.GetStyle().ItemSpacing.x
		local firstCursorPos = (width - ((buttonSize.x + spacing) * 3)) / 2

		self:HeaderText(_T("GENERIC_WARN_LABEL"), { color = Color("yellow") })
		ImGui.Separator()
		ImGui.Spacing()
		self:Text(_T("GENERIC_CONFIRM_WARN"))
		ImGui.Dummy(1, 10)
		ImGui.SetCursorPosX(ImGui.GetCursorPosX() + firstCursorPos)
		if (self:Button(_T("GENERIC_CONFIRM"), { size = buttonSize })) then
			ImGui.CloseCurrentPopup()
			return true
		end

		ImGui.SameLine()
		ImGui.SetCursorPosX(ImGui.GetCursorPosX() + buttonSize.x - spacing)

		if (self:Button(_T("GENERIC_CANCEL"), { size = buttonSize })) then
			ImGui.CloseCurrentPopup()
			return false
		end

		ImGui.EndPopup()
	end

	return false
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

	ThreadManager:Run(function()
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

local radioStationIdx = 1
---@param vehicle integer
---@param comboName string
---@param stationName? string
function GUI:VehicleRadioCombo(vehicle, comboName, stationName)
	local comboPeek = selectedStation or Audio.RadioStations[radioStationIdx].name
	if ImGui.BeginCombo(("##%s"):format(comboName), comboPeek) then
		for i, radio in ipairs(Audio.RadioStations) do
			if ImGui.Selectable(radio.name, (radioStationIdx == i)) then
				radioStationIdx = i
				selectedStation = radio.name
			end

			if self:IsItemClicked(0) then
				self:PlaySound("Click")
				script.run_in_fiber(function()
					AUDIO.SET_VEH_RADIO_STATION(vehicle, radio.station)
				end)
			end
		end
		ImGui.EndCombo()
	end

	ImGui.SetWindowFontScale(0.8)
	ImGui.BulletText(_F("Now Playing: %s", stationName or "Unknown station."))
	ImGui.SetWindowFontScale(1)
end

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
