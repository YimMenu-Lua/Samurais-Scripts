local Widgets = require('includes.ssv2.core.widgets')
local Notifier = {}; Notifier.__index = Notifier
local colors = { info = { 0.25, 0.25, 0.25, 1 }, success = { 0.1, 0.6, 0.1, 0.5 }, warn = { 0.8, 0.6, 0.1, 0.5 }, error = { 0.8, 0.1, 0.1, 0.5 } }
local sounds = {
    info = { 'PIN_CENTRED', 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS' },
    success = { 'PIN_GOOD', 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS' },
    warn = { 'PIN_BAD', 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS' },
    error = { 'ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDSET' }
}
function Notifier.new(ctx)
    local self = setmetatable({ ctx = ctx, history = {}, queue = {}, muted = false, open = false, serial = 0, viewed = true },
        Notifier)
    menu.add_always_draw_imgui(function() self:draw() end)
    ctx.runtime.shutdown[#ctx.runtime.shutdown + 1] = function()
        self.open = false; self.queue = {}; if ctx.view then ctx.view:update_mouse() end
    end
    return self
end

function Notifier:add(title, message, level, duration, callback)
    local now = util.time()
    if self.last and self.last.title == title and self.last.message == message and now - self.last.created < 3000 then return end
    self.serial = self.serial + 1
    local entry = {
        id = self.serial,
        title = title,
        message = message,
        level = level or 'info',
        created = now,
        duration = (duration or 3) * 1000,
        callback = callback,
        seen = false,
        timestamp = os.date('%H:%M')
    }
    self.viewed = self.open
    self.history[#self.history + 1] = entry; self.last = entry
    if not self.muted and not self.open then self.queue[#self.queue + 1] = entry end
    return entry
end

for _, level in ipairs({ 'info', 'success', 'warn', 'error' }) do
    Notifier[level] = function(self, title, message, duration, callback)
        return self:add(title, message, level, duration,
            callback)
    end
end
function Notifier:invoke(entry)
    entry.seen = true
    if entry.callback then self.ctx.runtime:run('notification_action', entry.callback) end
    for i = #self.queue, 1, -1 do if self.queue[i] == entry then table.remove(self.queue, i) end end
end

function Notifier:count()
    local count = 0; for _, entry in ipairs(self.history) do if not entry.seen then count = count + 1 end end; return
        count
end

function Notifier:card(entry, x, width, list, ease, pending, toast, progress)
    local _, y = ImGui.GetCursorScreenPos(); ease = ease or math.min(1, (util.time() - entry.created) / 220)
    local padding, accent, right = 12, 8, 28
    local title = entry.title .. '\t[' .. entry.timestamp .. ']'
    local scale = toast and 1.1 or 1
    ImGui.SetWindowFontScale(scale); local _, title_height = ImGui.CalcTextSize(title); ImGui.SetWindowFontScale(1)
    local wrap = width - padding * 3 - accent * 2 - right
    local _, body_height = ImGui.CalcTextSize(entry.message, false, wrap)
    local height = math.max(50, title_height + 20 + body_height + padding * 2)
    local top = y + (1 - ease) * (10 + math.min((pending or 0) * 4, 12)); local bottom = top + height
    local theme = self.ctx.theme:current(); local color = theme.Colors.FrameBg
    local hovered = ImGui.IsMouseHoveringRect(x, top, x + width, bottom, true)
    local alpha = toast and self.ctx.settings:get('ui.style.bg_alpha') * ease or 1
    local delta = hovered and entry.callback and ((color.x * 0.299 + color.y * 0.587 + color.z * 0.114) < 0.5 and 0.12 or -0.12) or
        0
    local function byte(v) return math.floor(math.max(0, math.min(1, v)) * 255) end
    if toast and (pending or 0) > 0 then
        for i = 1, pending do
            list:AddRectFilled(x + i - 1, bottom + math.min((i - 1) * 6, 24) - 1, x + width - i + 1,
                bottom + math.min((i - 1) * 6, 24) + 6, byte(color.x), byte(color.y), byte(color.z),
                byte(self.ctx.settings:get('ui.style.bg_alpha') - i * 0.1 * ease), 3 + i)
        end
        list:AddCircleFilled(x - 14, bottom + 14, 14, byte(theme.Colors.WindowBg.x), byte(theme.Colors.WindowBg.y),
            byte(theme.Colors.WindowBg.z), byte(theme.Colors.WindowBg.w))
        local label = '+' .. pending; ImGui.SetWindowFontScale(0.7); local tw, th = ImGui.CalcTextSize(label); ImGui
            .SetWindowFontScale(1)
        list:AddText(x - 14 - tw / 2, bottom + 14 - th / 2, label, byte(theme.Colors.Text.x), byte(theme.Colors.Text.y),
            byte(theme.Colors.Text.z), 255, ImGui.GetFontSize() * 0.7)
    end
    list:AddRectFilled(x, top, x + width, bottom, byte(color.x + delta), byte(color.y + delta), byte(color.z + delta),
        byte(alpha), toast and 3 or 8)
    local foreground = (color.x * 0.299 + color.y * 0.587 + color.z * 0.114) > 0.5 and 0 or 1
    local tint = entry.level == 'info' and { foreground, foreground, foreground } or colors[entry.level]
    list:AddText(x + padding, top + padding, title, byte(tint[1]), byte(tint[2]), byte(tint[3]), byte(ease),
        ImGui.GetFontSize() * scale)
    local close_hovered = false
    if hovered and not toast then
        local bx, by = x + width - padding - right + 6, top + padding - 2
        local c = theme.Colors.Button
        list:AddRectFilled(bx, by, bx + 20, by + 20, byte(c.x), byte(c.y), byte(c.z), byte(c.w), 6)
        list:AddText(bx + 5, by - 1, 'X', 200, 60, 60, byte(230 / 255 * ease), ImGui.GetFontSize())
        close_hovered = ImGui.IsMouseHoveringRect(bx, by, bx + 20, by + 20, true)
        if close_hovered then
            ImGui.SetTooltip(self.ctx.translator:text('GENERIC_DISMISS')); if ImGui.IsMouseClicked(0, false) then entry.seen = true end
        end
    end
    if hovered and entry.callback and not close_hovered then
        ImGui.SetTooltip('Click to execute.')
        if ImGui.IsMouseClicked(0, false) then
            self.ctx.view:play_sound('Click'); self:invoke(entry)
        end
    end
    local body_y = top + padding + title_height + 20
    list:AddText(x + padding, body_y, entry.message, byte(foreground), byte(foreground), byte(foreground), byte(ease),
        ImGui.GetFontSize(), width - padding * 2)
    if toast then
        local c = colors[entry.level]; list:AddRectFilled(x, bottom - 4, x + width * (1 - progress), bottom, byte(c[1]),
            byte(c[2]), byte(c[3]), byte(0.9 * ease), 0)
    end
    ImGui.SetCursorScreenPos(x, bottom + 20)
    return height
end

function Notifier:draw_center()
    self.viewed = true
    local count = self:count(); local screen_width, screen_height = ImGui.GetDisplaySize()
    local p = self.position or self.ctx.settings:get('ui.position')
    local x = math.min(screen_width - 800, p.x) + 400; local y = p.y
    local total = 100
    for _, entry in ipairs(self.history) do
        if not entry.seen then
            local _, height = ImGui.CalcTextSize(entry.message, false, 380); total = total + math.min(height + 60, 144) +
                10
        end
    end
    local height = count <= 4 and total + 40 or math.min(700, screen_height * 0.65)
    ImGui.SetNextWindowPos(x, y, ImGuiCond.Always); ImGui.SetNextWindowSize(400, height, ImGuiCond.Always); ImGui
        .SetNextWindowBgAlpha(0)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 0); ImGui.PushStyleVar(ImGuiStyleVar.ScrollbarSize, 9.5); ImGui
        .PushStyleColor(ImGuiCol.ScrollbarBg, 0, 0, 0, 0)
    local flags = bit.bor(ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoTitleBar,
        ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoSavedSettings)
    local _, draw = ImGui.Begin('##notif_center', true, flags)
    if draw then
        local list = ImGui.GetWindowDrawList(); local theme = self.ctx.theme:current(); local c = theme.Colors.WindowBg
        local r, g, b, a = require('includes.ssv2.core.widgets').rgba(c); list:AddRectFilled(x + 10, y + 10, x + 390,
            y + total - 10, r, g, b, a, theme.Styles.WindowRounding or 2)
        ImGui.Spacing(); ImGui.Spacing(); ImGui.SameLine(); ImGui.SetWindowFontScale(1.05); ImGui.Text(self.ctx
            .translator:text('GUI_NOTIFICATIONS')); ImGui.SetWindowFontScale(0.81)
        local mute = self.ctx.translator:text(self.muted and 'GENERIC_UNMUTE' or 'GENERIC_MUTE')
        local clear = self.ctx.translator:text('GENERIC_CLEAR_ALL'); local style = ImGui.GetStyle()
        local width = ImGui.CalcTextSize(mute) + style.FramePadding.x * (count > 0 and 4 or 2) +
            style.ItemSpacing.x * (count > 0 and 2 or 1) + (count > 0 and ImGui.CalcTextSize(clear) or 0)
        ImGui.SameLine(); ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - width)
        if Widgets.button(self.ctx, mute) then self.muted = not self.muted end
        if count > 0 then
            ImGui.SameLine(); if Widgets.button(self.ctx, clear) then for _, entry in ipairs(self.history) do entry.seen = true end end
        end
        ImGui.SetWindowFontScale(1); ImGui.Separator(); ImGui.Spacing()
        if count == 0 then ImGui.TextDisabled(self.ctx.translator:text('GUI_NOTIFICATIONS_NONE')) end
        for _, entry in ipairs(self.history) do
            if not entry.seen then
                local left = ImGui.GetCursorScreenPos(); self:card(entry, left, ImGui.GetContentRegionAvail(), list, nil,
                    0, false)
            end
        end
        if (ImGui.IsMouseClicked(0, false) or ImGui.IsMouseClicked(1, false)) and not ImGui.IsWindowHovered(bit.bor(ImGuiHoveredFlags.AllowWhenBlockedByActiveItem, ImGuiHoveredFlags.RootAndChildWindows)) then self.open = false end
    end
    ImGui.End(); ImGui.PopStyleVar(2); ImGui.PopStyleColor()
    if not self.ctx.view.open then self.open = false end
    self.ctx.view:update_mouse()
end

function Notifier:draw()
    if not self.ctx.runtime.running then return end
    if self.open then
        self.queue = {}; self.ctx.theme:push(); self:draw_center(); self.ctx.theme:pop(); return
    end
    if self.muted then
        self.queue = {}; return
    end
    local entry = self.queue[1]; if not entry then return end
    local now = util.time()
    if entry.seen or entry.appeared and now - entry.appeared >= entry.duration then
        table.remove(self.queue, 1); return
    end
    if not entry.appeared then
        entry.appeared = now; local sound = sounds[entry.level]
        self.ctx.runtime:run('notification_sound', function() AUDIO.PLAY_SOUND_FRONTEND(-1, sound[1], sound[2], true) end)
    end
    local elapsed = now - entry.appeared; local ease = math.max(0, math.min(1, elapsed / 220,
        (entry.duration - elapsed) / 220))
    local width = ImGui.GetDisplaySize(); local x, y = width - 380, 20
    local flags = bit.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoResize,
        ImGuiWindowFlags.NoBackground, ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoSavedSettings)
    ImGui.SetNextWindowPos(x, y, ImGuiCond.Always); ImGui.SetNextWindowSizeConstraints(380, 200, 380, 420)
    self.ctx.theme:push(); local _, draw = ImGui.Begin('ssv2_toast_' .. entry.id, true, flags)
    if draw then
        ImGui.SetCursorScreenPos(x, y); self:card(entry, x + 10, 360, ImGui.GetForegroundDrawList(), ease, #self.queue -
            1, true, elapsed / entry.duration)
    end
    ImGui.End(); self.ctx.theme:pop()
end

return Notifier
