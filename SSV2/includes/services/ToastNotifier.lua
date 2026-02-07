local ThemeManager = require "includes.services.ThemeManager"
-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@enum eNotificationLevel
Enums.eNotificationLevel = {
	MESSAGE = 0,
	SUCCESS = 1,
	WARNING = 2,
	ERROR   = 3,
	__MAX   = 4,
}

---@enum eNotificationContext
Enums.eNotificationContext = {
	TOAST = 0,
	CENTER = 1,
}

local bgColors <const> = {
	[Enums.eNotificationLevel.MESSAGE] = Color(0.25, 0.25, 0.25, 1.0),
	[Enums.eNotificationLevel.SUCCESS] = Color(0.1, 0.6, 0.1, 0.5),
	[Enums.eNotificationLevel.WARNING] = Color(0.8, 0.6, 0.1, 0.5),
	[Enums.eNotificationLevel.ERROR]   = Color(0.8, 0.1, 0.1, 0.5),
}

local frontendSounds <const> = {
	[Enums.eNotificationLevel.MESSAGE] = {
		soundName = "PIN_CENTRED",
		soundRef  = "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS"
	},
	[Enums.eNotificationLevel.SUCCESS] = {
		soundName = "PIN_GOOD",
		soundRef  = "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS"
	},
	[Enums.eNotificationLevel.WARNING] = {
		soundName = "PIN_BAD",
		soundRef  = "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS"
	},
	[Enums.eNotificationLevel.ERROR] = {
		soundName = "ERROR",
		soundRef  = "HUD_FRONTEND_DEFAULT_SOUNDSET"
	},
}

---@param caller string
---@param message string
local function logError(caller, message)
	log.fwarning("[ERROR] (%s): %s", caller, message)
end

local logLevels <const> = {
	[Enums.eNotificationLevel.MESSAGE] = log.debug,
	[Enums.eNotificationLevel.SUCCESS] = log.info,
	[Enums.eNotificationLevel.WARNING] = log.warning,
	[Enums.eNotificationLevel.ERROR]   = logError,
}

--#region Notification

---@private
---@class Notification
---@field m_title string
---@field m_message string
---@field m_id string -- ImGui windfow ID
---@field m_time_created seconds
---@field m_level eNotificationLevel
---@field m_seen boolean
---@field m_accent_color Color
---@field m_callback? Callback
local Notification <const> = {}
Notification.__index = Notification

---@param title string
---@param message string
---@param level eNotificationLevel
---@param id string
---@param callback? Callback
---@return Notification
function Notification.new(title, message, level, id, callback)
	assert(math.is_inrange(level, 0, (Enums.eNotificationLevel.__MAX - 1)), "Invalid notification level.")

	return setmetatable({
		m_title        = title,
		m_message      = message,
		m_id           = id,
		m_time_created = Time.now(),
		m_level        = level,
		m_seen         = false,
		m_accent_color = bgColors[level],
		m_callback     = callback
	}, Notification)
end

function Notification:Dismiss()
	self.m_seen = true
end

function Notification:Invoke()
	if (type(self.m_callback) ~= "function") then
		return
	end

	xpcall(self.m_callback, function(err)
		logError(self.m_title, err)
	end)

	self:Dismiss()
end

---@return number
function Notification:GetEaseIn()
	local now   = Time.now()
	local age   = now - self.m_time_created
	local animT = 0.22
	return math.clamp(age / animT, 0, 1)
end

---@param context eNotificationContext
---@param x_left float
---@param content_width float
---@param pImDrawList ImDrawList
---@param ease? float
---@param pendingCount? number
---@param showProgress? boolean
---@param progress? float
function Notification:Draw(context, x_left, content_width, pImDrawList, ease, pendingCount, showProgress, progress)
	pendingCount       = pendingCount or 0
	ease               = ease or self:GetEaseIn()
	local cardRounding = context == Enums.eNotificationContext.TOAST and 3.0 or 8.0
	local padding      = 12.0
	local accentWidth  = 8.0
	local titleSpacing = 20.0
	local rightButtonW = 28.0
	local cursor       = vec2:new(x_left, vec2:new(ImGui.GetCursorScreenPos()).y)
	local titleScale   = context == Enums.eNotificationContext.TOAST and 1.1 or 1.0

	ImGui.SetWindowFontScale(titleScale)
	local titleSize = vec2:new(ImGui.CalcTextSize(self.m_title))
	ImGui.SetWindowFontScale(1)

	local wrapSize    = content_width - (padding * 3.0) - (accentWidth * 2.0) - rightButtonW
	local bodySize    = vec2:new(ImGui.CalcTextSize(self.m_message, false, wrapSize))
	local cardHeight  = math.max(50.0, titleSize.y + titleSpacing + bodySize.y + (padding * 2))
	local cardWidth   = content_width
	local stackLift   = math.min(pendingCount * 4, 12)
	local slideOffset = (1.0 - ease) * (10.0 + stackLift)
	local alpha       = 0.0 + ease
	local cardTL      = vec2:new(cursor.x, cursor.y + slideOffset)
	local cardBR      = vec2:new(cursor.x + cardWidth, cursor.y + slideOffset + cardHeight)
	local windowBG    = GVars.ui.style.theme.Colors.WindowBg
	local windowAlpha = GVars.ui.style.bg_alpha
	local notifBG     = Color(windowBG.x, windowBG.y, windowBG.z, windowAlpha * alpha):AsU32()

	if (context == Enums.eNotificationContext.TOAST and pendingCount > 0) then
		local stackSpacing = 6.0
		local maxOffset    = 24.0
		for i = 1, pendingCount do
			local ghostOffset = math.min((i - 1) * stackSpacing, maxOffset)
			ImGui.ImDrawListAddRectFilled(
				pImDrawList,
				cardTL.x + i - 1,
				cardBR.y + ghostOffset - 1,
				cardBR.x - i + 1,
				cardBR.y + ghostOffset + 6,
				ImGui.GetColorU32(windowBG.x, windowBG.y, windowBG.z, windowAlpha - (i * 0.1) * alpha),
				cardRounding + i
			)
		end

		local countFontSize = ImGui.GetFontSize() * 0.7
		local countText     = _F("+%d", pendingCount)

		ImGui.SetWindowFontScale(0.7)
		local countTextSize = vec2:new(ImGui.CalcTextSize(countText))
		ImGui.SetWindowFontScale(1)

		local radius     = 14.0
		local counterPos = vec2:new(cardTL.x - radius, cardBR.y + radius)
		local textPos    = vec2:new(counterPos.x - countTextSize.x / 2, counterPos.y - countTextSize.y / 2)
		ImGui.SetCursorScreenPos(cardTL.x, cardBR.y)
		ImGui.ImDrawListAddCircleFilled(
			pImDrawList,
			counterPos.x,
			counterPos.y,
			radius,
			ImGui.GetStyleColorU32(ImGuiCol.WindowBg)
		)

		ImGui.ImDrawListAddText(
			pImDrawList,
			countFontSize,
			textPos.x,
			textPos.y,
			ImGui.GetStyleColorU32(ImGuiCol.Text),
			countText
		)
	end

	ImGui.ImDrawListAddRectFilled(
		pImDrawList,
		cardTL.x,
		cardTL.y,
		cardBR.x,
		cardBR.y,
		notifBG,
		cardRounding
	)
	local hovered    = ImGui.IsMouseHoveringRect(cardTL.x, cardTL.y, cardBR.x, cardBR.y)

	local titlePos   = vec2:new(cardTL.x + padding, cardTL.y + padding)
	local textCol    = ImGui.GetAutoTextColor(Color(windowBG:unpack()))
	local r, g, b, _ = self.m_accent_color:AsFloat()
	local headerCol  = self.m_level == Enums.eNotificationLevel.MESSAGE and textCol or Color(r, g, b, 1.0 * alpha)
	ImGui.ImDrawListAddText(
		pImDrawList,
		ImGui.GetFontSize() * titleScale,
		titlePos.x,
		titlePos.y,
		headerCol:AsU32(),
		self.m_title
	)

	if (context == Enums.eNotificationContext.CENTER and hovered) then
		local btnPos = vec2:new(cardBR.x - padding - rightButtonW + 6.0, cardTL.y + padding - 2.0)
		local btnBR  = vec2:new(btnPos.x + 20.0, btnPos.y + 20.0)
		local btnBg  = ImGui.GetStyleColorU32(ImGuiCol.Button)
		ImGui.ImDrawListAddRectFilled(
			pImDrawList,
			btnPos.x,
			btnPos.y,
			btnBR.x,
			btnBR.y,
			btnBg,
			6.0
		)

		ImGui.ImDrawListAddText(
			pImDrawList,
			btnPos.x + 5.0,
			btnPos.y - 1.0,
			Color(200, 60, 60, 230.0 * alpha):AsU32(),
			"X"
		)

		local btnRect = Rect(btnPos, btnBR)
		if (not self.m_seen and ImGui.IsMouseHoveringRect(btnRect.min.x, btnRect.min.y, btnRect.max.x, btnRect.max.y)) then
			if (KeyManager:IsKeyJustPressed(eVirtualKeyCodes.VK_LBUTTON)) then
				self:Dismiss()
			end

			ImGui.SetTooltip(_T("GENERIC_DISMISS"))
		end
	end

	local bodyPos = vec2:new(cardTL.x + padding, cardTL.y + padding + titleSize.y + titleSpacing)
	local tr, tg, tb, ta = textCol:AsRGBA()
	ImGui.ImDrawListAddText(
		pImDrawList,
		ImGui.GetFontSize(),
		bodyPos.x,
		bodyPos.y,
		ImGui.GetColorU32(tr, tg, tb, ta * alpha),
		self.m_message,
		content_width - (padding * 2.0)
	)

	if (context == Enums.eNotificationContext.TOAST and showProgress and progress) then
		local barHeight = 4.0
		local barW      = cardWidth * (1.0 - progress)

		ImGui.ImDrawListAddRectFilled(
			pImDrawList,
			cardTL.x,
			cardBR.y - barHeight,
			cardTL.x + barW,
			cardBR.y,
			ImGui.GetColorU32(r, g, b, 0.9 * alpha)
		)
	end
end

function Notification:ComputeHeight()
	local wrapWidth     = ImGui.GetContentRegionAvail() - 20.0
	local _, textHeight = ImGui.CalcTextSize(self.m_message, false, wrapWidth)
	local panelHeight   = math.min(textHeight + 60.0, 144.0)
	return panelHeight
end

--#endregion

--#region Toast

--------------------------------------
-- Private Subclass: Toast
--------------------------------------
---@private
---@class Toast
---@field m_pos vec2
---@field m_size vec2
---@field m_safe_area vec2
---@field m_lifetime seconds
---@field m_duration seconds
---@field m_should_log? boolean **Optional:** Log to console as well.
---@field m_appeared boolean
---@field m_notification Notification
---@field m_expired boolean
local Toast = {
	m_size      = vec2:new(360, 20),
	m_safe_area = vec2:new(20, 20)
}
Toast.__index = Toast

---@param duration number **Optional:** The duration of the notification *(default 3s)*.
---@param log boolean **Optional:** Log to console as well.
function Toast.new(duration, log)
	return setmetatable({
		m_duration   = duration or 3.0,
		m_appeared   = false,
		m_expired    = false,
		m_should_log = log,
		m_pos        = vec2:new(
			GPointers.ScreenResolution.x - Toast.m_size.x - Toast.m_safe_area.x,
			Toast.m_safe_area.y
		),
	}, Toast)
end

---@param notif Notification
---@return Toast
function Toast:Bind(notif)
	self.m_notification = notif
	return self
end

function Toast:OnFirstAppearance()
	if (self.m_appeared) then
		return
	end

	local snd = frontendSounds[self:GetLevel()]
	if (snd) then
		ThreadManager:Run(function()
			AUDIO.PLAY_SOUND_FRONTEND(-1, snd.soundName, snd.soundRef, true)
		end)
	end

	if (self.m_should_log) then
		self:Log()
	end

	self.m_appeared = true
end

---@return boolean
function Toast:HasExpired()
	return self.m_notification.m_seen or (self.m_lifetime and Time.now() - self.m_lifetime >= self.m_duration)
end

function Toast:SetAsExpired()
	if (self:HasExpired()) then
		return
	end

	self.m_appeared = true
	self.m_lifetime = Time.now() + self.m_duration
end

function Toast:Dismiss()
	self.m_notification:Dismiss()
end

function Toast:Invoke()
	self.m_notification:Invoke()
end

---@return string
function Toast:GetTitle()
	return self.m_notification.m_title or ""
end

---@return string
function Toast:GetMessage()
	return self.m_notification.m_message or ""
end

---@return eNotificationLevel
function Toast:GetLevel()
	return self.m_notification.m_level
end

---@return number
function Toast:GetEase()
	if (not self.m_lifetime) then
		return 0.0
	end

	local now     = Time.now()
	local age     = now - self.m_lifetime
	local easeIn  = 0.22
	local easeOut = 0.22

	if (age < easeIn) then
		return math.clamp(age / easeIn, 0, 1)
	end

	local remaining = self.m_duration - age
	if (remaining < easeOut) then
		return math.clamp(remaining / easeOut, 0, 1)
	end

	return 1.0
end

---@return number
function Toast:GetDelta()
	if (not self.m_lifetime) then
		return 0.0
	end

	local age = Time.now() - self.m_lifetime
	return math.clamp(age / self.m_duration, 0, 1)
end

function Toast:Log()
	if (self.m_appeared) then
		return
	end

	local logFunc = logLevels[self:GetLevel()]
	if (type(logFunc) ~= "function") then
		return
	end

	logFunc(_F("%s, %s", self:GetTitle(), self:GetMessage()))
end

--#endregion


--#region Notifier

--------------------------------------
-- Class: Notifier
--------------------------------------
---@class Notifier
---@field private m_last_title string
---@field private m_last_message string
---@field private m_last_time seconds
---@field private m_rate_limit seconds
---@field private m_notifs Notification[]
---@field private m_toasts Toast[] -- FIFO
---@field private m_active_toast Toast
---@field private m_should_draw boolean
---@field private m_window_width float
---@field private m_viewed boolean
---@field private m_muted boolean
local Notifier = { m_window_width = 400.0 }
Notifier.__index = Notifier

---@return Notifier
function Notifier.new()
	local instance = setmetatable({
		m_toasts      = {},
		m_notifs      = {},
		m_should_draw = false,
		m_viewed      = true,
		m_muted       = false,
		m_last_time   = 0,
		m_rate_limit  = 3,
	}, Notifier)

	GUI:RegisterIndependentGUI(function()
		instance:DrawToasts()
	end)

	return instance
end

---@return boolean
function Notifier:IsMuted()
	return self.m_muted
end

function Notifier:ToggleMute()
	self.m_muted = not self.m_muted
end

---@return integer
function Notifier:GetNotifCount()
	return #self.m_notifs
end

---@return integer
function Notifier:GetToastCount()
	return #self.m_toasts
end

function Notifier:IsOpen()
	return self.m_should_draw
end

function Notifier:Open()
	if (self.m_should_draw) then
		return
	end

	self.m_should_draw = true
end

function Notifier:Close()
	self.m_should_draw = false
end

function Notifier:Toggle()
	self.m_should_draw = not self.m_should_draw
end

function Notifier:Clear()
	for _, notif in ipairs(self.m_notifs) do
		notif.m_seen = true
	end
end

function Notifier:ClearSeen()
	table.erase_if(self.m_toasts, function(_, toast)
		return toast:HasExpired()
	end)

	table.erase_if(self.m_notifs, function(_, notif)
		return notif.m_seen == true
	end)
end

function Notifier:ClearToasts()
	self.m_toasts = {}
end

---@return boolean
function Notifier:HasUnread()
	return self.m_viewed == false
end

function Notifier:ComputeTotalHeight()
	local total = 80.0

	for _, notif in ipairs(self.m_notifs) do
		if (not notif.m_seen) then
			total = total + notif:ComputeHeight()
			total = total + 10.0
		end
	end

	return total + 20
end

---@param title string The notification title.
---@param message string The notification body.
---@param level eNotificationLevel The notification type.
---@param opts? { log?: boolean, duration?: seconds, callback?: Callback }
function Notifier:Add(title, message, level, opts)
	opts = opts or {}

	local now = Time.now()
	if (self.m_last_title == title and self.m_last_message == message) and (now - self.m_last_time) < self.m_rate_limit then
		return
	end

	self.m_last_title   = title
	self.m_last_message = message
	self.m_last_time    = now
	self.m_viewed       = (self.m_should_draw == true)
	local id            = string.format("##%s%d", title, self:GetToastCount() + 1)
	local timestamp     = os.date("%H:%M")
	local notif         = Notification.new(_F("%s\t[%s]", title, timestamp), message, level, id, opts.callback)
	local toast         = Toast.new(opts.duration or 3.0, opts.log or false)

	table.insert(self.m_notifs, notif)

	if (not self:IsMuted()) then
		table.insert(self.m_toasts, toast:Bind(notif))
	end
end

---@param caller string The notification title.
---@param message string The notification body.
---@param withLog? boolean **Optional:** Log to console as well.
---@param duration? number **Optional:** The duration of the notification *(default 3s)*.
---@param callback? Callback
function Notifier:ShowMessage(caller, message, withLog, duration, callback)
	local opts = { duration = duration or 3, log = withLog or false, callback = callback }
	self:Add(caller, message, Enums.eNotificationLevel.MESSAGE, opts)
end

---@param caller string The notification title.
---@param message string The notification body.
---@param withLog? boolean **Optional:** Log to console as well.
---@param duration? number **Optional:** The duration of the notification *(default 3s)*.
---@param callback? Callback
function Notifier:ShowSuccess(caller, message, withLog, duration, callback)
	local opts = { duration = duration or 3, log = withLog or false, callback = callback }
	self:Add(caller, message, Enums.eNotificationLevel.SUCCESS, opts)
end

---@param caller string The notification title.
---@param message string The notification body.
---@param withLog? boolean **Optional:** Log to console as well.
---@param duration? number **Optional:** The duration of the notification *(default 3s)*.
---@param callback? Callback
function Notifier:ShowWarning(caller, message, withLog, duration, callback)
	local opts = { duration = duration or 3, log = withLog or false, callback = callback }
	self:Add(caller, message, Enums.eNotificationLevel.WARNING, opts)
end

---@param caller string The notification title.
---@param message string The notification body.
---@param withLog? boolean **Optional:** Log to console as well.
---@param duration? number **Optional:** The duration of the notification *(default 3s)*.
---@param callback? Callback
function Notifier:ShowError(caller, message, withLog, duration, callback)
	local opts = { duration = duration or 3, log = withLog or false, callback = callback }
	self:Add(caller, message, Enums.eNotificationLevel.ERROR, opts)
end

function Notifier:DrawToasts()
	local totalCount = self:GetToastCount()
	if (totalCount == 0) then
		return
	end

	local toast           = self.m_toasts[1]
	local width           = toast.m_size.x
	local notif           = toast.m_notification
	local padding <const> = 20

	if (not notif or toast:HasExpired()) then
		table.remove(self.m_toasts, 1)
		return
	end

	if (not toast.m_lifetime) then
		toast.m_lifetime = Time.now()
	end

	if (self.m_should_draw or self:IsMuted()) then
		self:ClearToasts()
		return
	end

	toast:OnFirstAppearance()

	ImGui.SetNextWindowPos(toast.m_pos.x, toast.m_pos.y)
	ImGui.SetNextWindowSizeConstraints(toast.m_size.x + padding, 200, toast.m_size.x + padding, 420)
	ThemeManager:PushTheme()
	if (ImGui.Begin(toast.m_notification.m_id,
			ImGuiWindowFlags.NoMove
			| ImGuiWindowFlags.NoResize
			| ImGuiWindowFlags.NoTitleBar
			| ImGuiWindowFlags.NoBackground
			| ImGuiWindowFlags.AlwaysAutoResize
			| ImGuiWindowFlags.NoSavedSettings
		)) then
		local drawList = ImGui.GetForegroundDrawList()
		local remaining = totalCount - 1
		ImGui.SetCursorScreenPos(toast.m_pos.x, toast.m_pos.y)
		notif:Draw(
			Enums.eNotificationContext.TOAST,
			toast.m_pos.x + (padding / 2),
			width,
			drawList,
			toast:GetEase(),
			remaining,
			true,
			toast:GetDelta()
		)
		ImGui.End()
	end
	ThemeManager:PopTheme()
end

---@param start_pos vec2
function Notifier:DrawNotifications(start_pos)
	self:ClearSeen()

	if (not self.m_should_draw) then
		return
	end

	self.m_viewed     = true
	local count       = self:GetNotifCount()
	local height      = self:ComputeTotalHeight() + 20
	local max_screen  = GPointers.ScreenResolution.x
	local window_pos  = vec2:new(start_pos.x + self.m_window_width, start_pos.y)
	local window_size = vec2:new(self.m_window_width, height)
	local style       = ImGui.GetStyle()
	if (window_pos.x >= max_screen) then
		window_pos.x = max_screen - self.m_window_width - 10
	end

	ImGui.SetNextWindowBgAlpha(0)
	ImGui.SetNextWindowPos(window_pos.x, window_pos.y)
	ImGui.SetNextWindowSize(window_size.x, window_size.y)
	ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 0)
	if (ImGui.Begin("##notif_center",
			ImGuiWindowFlags.NoMove
			| ImGuiWindowFlags.NoResize
			| ImGuiWindowFlags.NoTitleBar
			| ImGuiWindowFlags.AlwaysAutoResize
			| ImGuiWindowFlags.NoSavedSettings
		)) then
		local drawList = ImGui.GetWindowDrawList()
		local windowBG = vec4:new(ImGui.GetStyleColorVec4(ImGuiCol.WindowBg))
		local frame    = vec4:new(ImGui.GetStyleColorVec4(ImGuiCol.FrameBg))
		local contrast = math.abs(frame.x - windowBG.x)
		if (contrast >= 0.1) then
			frame.x = frame.x * 0.85
			frame.y = frame.y * 0.85
			frame.z = frame.z * 0.85
			frame.w = frame.w * 0.85
		end
		ImGui.ImDrawListAddRectFilled(
			drawList,
			window_pos.x + 10,
			window_pos.y + 10,
			window_pos.x + self.m_window_width - 10,
			window_pos.y + height - 10,
			ImGui.GetColorU32(frame.x, frame.y, frame.z, frame.w),
			GVars.ui.style.theme.Styles.WindowRounding or 2
		)

		ImGui.Spacing()
		ImGui.Spacing()
		ImGui.SameLine()
		ImGui.SetWindowFontScale(1.05)
		ImGui.Text(_T("GUI_NOTIFICATIONS"))
		ImGui.SetWindowFontScale(1.0)

		ImGui.SameLine()
		ImGui.SetWindowFontScale(0.81)
		local muteText      = _T(self:IsMuted() and "GENERIC_UNMUTE" or "GENERIC_MUTE")
		local muteTextWidth = ImGui.CalcTextSize(muteText)
		local totalWidth    = muteTextWidth + (style.FramePadding.x * (count > 0 and 4 or 2)) +
			(style.ItemSpacing.x * (count > 0 and 2 or 1))
		if (count > 0) then
			totalWidth = totalWidth + ImGui.CalcTextSize(_T("GENERIC_CLEAR_ALL"))
		end

		ImGui.SetCursorPosX((ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - totalWidth))
		if (GUI:Button(muteText)) then
			self:ToggleMute()
		end

		if (count > 0) then
			ImGui.SameLine()
			if (GUI:Button(_T("GENERIC_CLEAR_ALL"))) then
				self:Clear()
			end
		end
		ImGui.SetWindowFontScale(1.0)

		ImGui.Separator()
		ImGui.Spacing()

		if (count == 0) then
			ImGui.TextDisabled(_T("GUI_NOTIFICATIONS_NONE"))
		end

		local cursorPos = ImGui.GetCursorScreenPos()
		local contentW = ImGui.GetContentRegionAvail()
		for _, notif in ipairs(self.m_notifs) do
			if (not notif.m_seen) then
				notif:Draw(
					Enums.eNotificationContext.CENTER,
					cursorPos,
					contentW,
					drawList
				)

				ImGui.Dummy(1, notif:ComputeHeight())
			end
		end

		if (KeyManager:IsKeyJustPressed(eVirtualKeyCodes.VK_LBUTTON) or KeyManager:IsKeyJustPressed(eVirtualKeyCodes.VK_RBUTTON)) then
			if not ImGui.IsWindowHovered(
					ImGuiHoveredFlags.AllowWhenBlockedByActiveItem
					| ImGuiHoveredFlags.RootAndChildWindows
				) then
				self:Close()
			end
		end

		ImGui.End()
	end
	ImGui.PopStyleVar()

	if (self.m_should_draw and not GUI:IsOpen()) then
		self:Close()
	end
end

--#endregion

return Notifier
