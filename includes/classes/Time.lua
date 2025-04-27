---@class Time
local Time = {}
Time.__index = Time

-- Constructor
function Time.new()
    return setmetatable({}, Time)
end

-- Returns an approximation of the amount in seconds of CPU time used by the program.
function Time.now()
    return os.clock()
end

-- Returns an approximation of the amount in milliseconds of CPU time used by the program.
function Time.millis()
    return os.clock() * 1000
end

-- Sleeps for the given duration in milliseconds. Must be called in a coroutine.
---@param ms number Milliseconds.
function Time.Sleep(ms)
    local future = Time.millis() + ms
    while Time.millis() < future do
        coroutine.yield()
    end
end

-----------------------------------------------------
-- Timer Subclass
-----------------------------------------------------
---@class Time.Timer
Time.Timer = {}
Time.Timer.__index = Time.Timer

-- Creates a new timer that runs for `duration` milliseconds.
---@param duration number
---@return Time.Timer
function Time.Timer.new(duration)
    return setmetatable(
        {
            duration = duration,
            startTime = Time.millis(),
            paused = false,
            pauseTime = nil,
        },
        Time.Timer
    )
end

-- Returns the elapsed time in milliseconds.
function Time.Timer:elapsed()
    if self.paused then
        return self.pauseTime - self.startTime
    else
        return Time.millis() - self.startTime
    end
end

-- Returns true if the timer has finished.
function Time.Timer:isDone()
    return self:elapsed() >= self.duration
end

-- Pauses the timer.
function Time.Timer:pause()
    if not self.paused then
        self.paused = true
        self.pauseTime = Time.millis()
    end
end

-- Resumes the timer.
function Time.Timer:resume()
    if not self.paused then
        return
    end

    local pauseDuration = Time.millis() - self.pauseTime
    self.startTime = self.startTime + pauseDuration
    self.paused = false
    self.pauseTime = nil
end

-- Resets the timer to start over (optionally with a new duration).
---@param newDuration? number|nil Optional.
function Time.Timer:reset(newDuration)
    self.duration = newDuration or self.duration
    self.startTime = Time.millis()
    self.paused = false
    self.pauseTime = nil
end

return Time
