---@diagnostic disable: undefined-global, lowercase-global

---@enum eToastLevel
local eToastLevel <const> = {
    MESSAGE = 0,
    SUCCESS = 1,
    WARNING = 2,
    ERROR   = 3,
}

local bgColors <const> = {
    [0] = {r = 0.15, g = 0.15, b = 0.15, a = 1.0},
    [1] = {r = 0.1, g = 0.6, b = 0.1, a = 0.5},
    [2] = {r = 0.8, g = 0.6, b = 0.1, a = 0.5},
    [3] = {r = 0.8, g = 0.1, b = 0.1, a = 0.5},
}

local textColors <const> = {
    [0] = {r = 1.0, g = 1.0, b = 1.0, a = 1.0},
    [1] = {r = 1.0, g = 1.0, b = 1.0, a = 0.8},
    [2] = {r = 0.01, g = 0.01, b = 0.01, a = 1.0},
    [3] = {r = 0.01, g = 0.01, b = 0.01, a = 1.0},
}

local frontendSounds <const> = {
    [0] = {
        soundName = "PIN_CENTRED",
        soundRef = "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS"
    },
    [1] = {
        soundName = "PIN_GOOD",
        soundRef = "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS"
    },
    [2] = {
        soundName = "PIN_BAD",
        soundRef = "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS"
    },
    [3] = {
        soundName = "ERROR",
        soundRef = "HUD_FRONTEND_DEFAULT_SOUNDSET"
    },
}

local logLevels <const> = {
    [0] = log.info,
    [1] = log.info,
    [2] = log.warning,
}

---@param caller string
---@param message string
local function logError(caller, message)
    log.warning(("[ERROR] (%s): %s"):format(caller, message))
end

local function GetScreenResolution()
    if PatternScanner:IsDone() then
        return Game.GetScreenResolution()
    end

    local pScreenResolution = memory.scan_pattern("66 0F 6E 0D ? ? ? ? 0F B7 3D")
    if pScreenResolution:is_null() then
        return { x = 0, y = 0}
    end

    return {
        x = pScreenResolution:sub(0x4):rip():get_word(),
        y = pScreenResolution:add(0x4):rip():get_word()
    }
end

local SCREEN_RESOLUTION = GetScreenResolution()

--#region Toast

--------------------------------------
-- Private Subclass: Toast
--------------------------------------
---@ignore
---@class Toast
---@field caller string The notification title.
---@field message string The notification body.
---@field level eToastLevel The type of message to show.
---@field duration number **Optional:** The duration of the notification *(default 3s)*.
---@field start_time number Time at which the notification was first shown.
---@field should_draw boolean Whether the notification UI should be drawn.
---@field should_log? boolean **Optional:** Log to console as well.
local Toast = {}
Toast.__index = Toast
Toast.ui_width = 320
Toast.ui_pos_x = SCREEN_RESOLUTION.x - Toast.ui_width - 20
Toast.ui_pos_y = -200.0

---@param caller string The notification title.
---@param message string The notification body.
---@param level eToastLevel The type of message to show.
---@param duration number **Optional:** The duration of the notification *(default 3s)*.
---@param log boolean **Optional:** Log to console as well.
function Toast.new(caller, message, level, duration, log)
    return setmetatable(
        {
            caller      = caller or "Toast",
            message     = message,
            level       = level or 0,
            duration    = duration or 3.0,
            start_time  = Time.now(),
            should_draw = false,
            should_log  = log
        },
        Toast
    )
end

---@param notifier Notifier
function Toast:Draw(notifier)
    if not self.should_draw then
        return
    end

    local windowBgCol = bgColors[self.level] or bgColors[0]
    local textCol     = textColors[self.level] or textColors[0]
    local elapsed     = Time.now() - self.start_time
    local progress    = 1.0 - (elapsed / self.duration)

    ---@type string
    local __caller__

    if (notifier and notifier:GetQueueCount() > 0) then
        __caller__ = _F("%s  (+%d)", self.caller, notifier:GetQueueCount())
    else
        __caller__ = self.caller
    end

    ImGui.SetNextWindowSizeConstraints(self.ui_width, 100, self.ui_width, 400)
    ImGui.SetNextWindowBgAlpha(0.8)
    ImGui.SetNextWindowPos(self.ui_pos_x, self.ui_pos_y)
    ImGui.PushStyleColor(
        ImGuiCol.WindowBg,
        windowBgCol.r,
        windowBgCol.g,
        windowBgCol.b,
        windowBgCol.a
    )
    ImGui.PushStyleColor(
        ImGuiCol.Text,
        textCol.r,
        textCol.g,
        textCol.b,
        textCol.a
    )
    if ImGui.Begin(("Toast##%s"):format(self.start_time),
            ImGuiWindowFlags.AlwaysAutoResize |
            ImGuiWindowFlags.NoTitleBar |
            ImGuiWindowFlags.NoMove |
            ImGuiWindowFlags.NoCollapse |
            ImGuiWindowFlags.NoFocusOnAppearing |
            ImGuiWindowFlags.NoSavedSettings |
            ImGuiWindowFlags.NoScrollbar |
            ImGuiWindowFlags.NoScrollWithMouse
    ) then
        ImGui.PushTextWrapPos(self.ui_width - (ImGui.GetFontSize() / 2))
        ImGui.SetWindowFontScale(1.2)
        ImGui.SeparatorText(__caller__)
        ImGui.SetWindowFontScale(1)
        ImGui.Spacing()
        ImGui.Text(self.message)
        ImGui.Dummy(1, 10)
        ImGui.ProgressBar(progress, -1, 3)
        ImGui.PopTextWrapPos()
        ImGui.PopStyleColor(2)
        ImGui.End()
    end
end

--#endregion


--#region Notifier

--------------------------------------
-- Class: Notifier
--------------------------------------
---@class Notifier
---@field private last_caller string
---@field private last_message string
---@field private last_time number
---@field private rate_limit number
---@field private queue Toast[]
---@field private active Toast
---@field private should_draw boolean
local Notifier = {}
Notifier.__index = Notifier

function Notifier.new()
    local instance = setmetatable(
        {
            queue       = {},
            should_draw = false,
            last_time   = 0,
            rate_limit  = 3.0,
        },
        Notifier
    )

    GUI:RegisterIndependentGUI(function()
        instance:Draw()
    end)

    ThreadManager:CreateNewThread("SB_TOAST", function()
        instance:Update()
        sleep(1)
    end)

    return instance
end

function Notifier:GetQueueCount()
    return #self.queue
end

---@param caller string The notification title.
---@param message string The notification body.
---@param level eToastLevel The notification type.
---@param withLog? boolean **Optional:** Log to console as well.
---@param duration? number **Optional:** The duration of the notification *(default 3s)*.
function Notifier:Notify(caller, message, level, withLog, duration)
    local current_time = Time.now()
    if (self.last_caller == caller and self.last_message == message) and (current_time - self.last_time) < self.rate_limit then
        return
    end

    self.last_caller = caller
    self.last_message = message
    self.last_time = current_time
    table.insert(self.queue, Toast.new(caller, message, level, duration or 3.0, withLog or false))
end

---@param caller string The notification title.
---@param message string The notification body.
---@param withLog? boolean **Optional:** Log to console as well.
---@param duration? number **Optional:** The duration of the notification *(default 3s)*.
function Notifier:ShowMessage(caller, message, withLog, duration)
    local current_time = Time.now()
    if (self.last_caller == caller and self.last_message == message) and (current_time - self.last_time) < self.rate_limit then
        return
    end

    self.last_caller = caller
    self.last_message = message
    self.last_time = current_time
    table.insert(self.queue, Toast.new(caller, message, eToastLevel.MESSAGE, duration or 3.0, withLog or false))
end

---@param caller string The notification title.
---@param message string The notification body.
---@param withLog? boolean **Optional:** Log to console as well.
---@param duration? number **Optional:** The duration of the notification *(default 3s)*.
function Notifier:ShowSuccess(caller, message, withLog, duration)
    local current_time = Time.now()
    if (self.last_caller == caller and self.last_message == message) and (current_time - self.last_time) < self.rate_limit then
        return
    end

    self.last_caller = caller
    self.last_message = message
    self.last_time = current_time
    table.insert(self.queue, Toast.new(caller, message, eToastLevel.SUCCESS, duration or 3.0, withLog or false))
end

---@param caller string The notification title.
---@param message string The notification body.
---@param withLog? boolean **Optional:** Log to console as well.
---@param duration? number **Optional:** The duration of the notification *(default 3s)*.
function Notifier:ShowWarning(caller, message, withLog, duration)
    local current_time = Time.now()
    if (self.last_caller == caller and self.last_message == message) and (current_time - self.last_time) < self.rate_limit then
        return
    end

    self.last_caller = caller
    self.last_message = message
    self.last_time = current_time
    table.insert(self.queue, Toast.new(caller, message, eToastLevel.WARNING, duration or 3.0, withLog or false))
end

---@param caller string The notification title.
---@param message string The notification body.
---@param withLog? boolean **Optional:** Log to console as well.
---@param duration? number **Optional:** The duration of the notification *(default 3s)*.
function Notifier:ShowError(caller, message, withLog, duration)
    local current_time = Time.now()
    if (self.last_caller == caller and self.last_message == message) and (current_time - self.last_time) < self.rate_limit then
        return
    end

    self.last_caller = caller
    self.last_message = message
    self.last_time = current_time
    table.insert(self.queue, Toast.new(caller, message, eToastLevel.ERROR, duration or 3.0, withLog or false))
end

function Notifier:Update()
    if not self.active and #self.queue > 0 then
        self.active = table.remove(self.queue, 1)
        self.active.start_time = Time.now()
        self.active.should_draw = true
        self.should_draw = true

        GUI:PlaySound(frontendSounds[self.active.level])

        if self.active.should_log then
            if self.active.level < 3 then
                logFunc = logLevels[self.active.level] or log.info
                logFunc(("(%s): %s"):format(self.active.caller, self.active.message))
            else
                logError(self.active.caller, self.active.message)
            end
        end
    end

    if self.active then
        if (Time.now() - self.active.start_time) < (self.active.duration / 3) then
            if self.active.ui_pos_y < 20 then
                self.active.ui_pos_y = self.active.ui_pos_y + 20
            end
        end

        if (Time.now() - self.active.start_time) >= (self.active.duration * 0.95) then
            if self.active.ui_pos_y > -200 then
                self.active.ui_pos_y = self.active.ui_pos_y - 20
                if self.active.ui_pos_y <= -100 then
                    self.active.message = ""
                end
            end
        end

        if (Time.now() - self.active.start_time) >= self.active.duration then
            self.active.should_draw = false
            self.active = nil
            self.should_draw = false
        end
    end
end

function Notifier:Draw()
    if self.should_draw and self.active then
        self.active:Draw(self)
    end
end

--#endregion

return Notifier
