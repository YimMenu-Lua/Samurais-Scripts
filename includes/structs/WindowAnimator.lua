---@diagnostic disable: param-type-mismatch

--------------------------------------
-- WindowAnimator Struct
--------------------------------------
-- Basic slide animator for out main window
---@class WindowAnimator
---@field m_window_label string
---@field m_active boolean
---@field m_ease number
---@field m_start_time seconds
---@field m_duration seconds
---@field m_start_pos vec2
---@field m_end_pos vec2
---@overload fun() : WindowAnimator
local WindowAnimator = {}
WindowAnimator.__index = WindowAnimator
setmetatable(WindowAnimator, {
    __call = function (...)
        return setmetatable({
            m_active     = false,
            m_start_time = 0,
            m_start_pos  = vec2:zero(),
            m_end_pos    = vec2:zero(),
            m_duration   = 0.18
        }, WindowAnimator)
    end
})

---@param windowLabel string
---@param startPos vec2
---@param endPos vec2
---@param duration? seconds
---@param easeOut? number
function WindowAnimator:Init(windowLabel, startPos, endPos, duration, easeOut)
    self.m_window_label = windowLabel
    self.m_active       = true
    self.m_start_time   = Time.now()
    self.m_start_pos    = startPos
    self.m_end_pos      = endPos
    self.m_duration     = duration or 0.18

    if (easeOut) then
        self.m_ease = easeOut
    end
end

---@return boolean
function WindowAnimator:IsActive()
    return self.m_active
end

---@param t number time delta
function WindowAnimator:EaseOutQuad(t)
    return 1 - (1 - t) * (1 - t)
end

function WindowAnimator:Apply()
    if (not self.m_active) then
        return
    end

    local t = (Time.now() - self.m_start_time) / self.m_duration
    if (t >= 1) then
        self.m_active = false
        ImGui.SetWindowPos(self.m_window_label, self.m_end_pos.x, self.m_end_pos.y, ImGuiCond.Always)
        return
    end

    local ease = self.m_ease or self:EaseOutQuad(t)
    local target = self.m_start_pos:lerp(self.m_end_pos, ease)
    ImGui.SetWindowPos(self.m_window_label, target.x, target.y, ImGuiCond.Always)
end

function WindowAnimator:Cancel()
    self.m_active = false
end

return WindowAnimator
