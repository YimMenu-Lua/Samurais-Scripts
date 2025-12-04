--------------------------------------
-- Class: Time
--------------------------------------
--**Global Singleton.**
---@class Time
local Time = {}
Time.__index = Time
Time.__type = "Time"
setmetatable(Time, Time)

-- Returns an approximation of the amount in seconds of CPU time used by the program.
---@return seconds
function Time.now()
    return os.clock()
end

-- Returns an approximation of the amount in milliseconds of CPU time used by the program.
---@return milliseconds
function Time.millis()
    return os.clock() * 1000
end

-- Sleeps for the given duration in milliseconds. Must be called in a coroutine.
---@param ms milliseconds
function Time.sleep(ms)
    local future = Time.millis() + ms
    while Time.millis() < future do
        yield()
    end
end

---@param seconds seconds
---@return seconds
function Time.future(seconds)
    if (type(seconds) ~= "number") then
        return Time.now()
    end

    return Time.now() + seconds
end

---@param ms milliseconds
---@return milliseconds
function Time.future_ms(ms)
    if (type(ms) ~= "number") then
        return Time.millis()
    end

    return Time.millis() + ms
end

---@param seconds seconds
---@return seconds
function Time.seconds_ago(seconds)
    if (type(seconds) ~= "number") then
        return 0
    end

    return math.max(Time.now() - seconds, 0)
end

---@param ms milliseconds
---@return milliseconds
function Time.ms_ago(ms)
    if (type(ms) ~= "number") then
        return 0
    end

    return math.max(Time.millis() - ms, 0)
end

---@param since seconds
---@param duration seconds
---@return boolean
function Time.has_elapsed(since, duration)
    return Time.now() >= (since + duration)
end

---@param since milliseconds
---@param duration milliseconds
---@return boolean
function Time.has_elapsed_ms(since, duration)
    return Time.millis() >= (since + duration)
end

-- Same as `Time.seconds_ago`. just gor readability and intent
---@param since seconds
---@return seconds
function Time.elapsed(since)
    return Time.now() - since
end

-- Same as `Time.ms_ago`. just gor readability and intent
---@param since milliseconds
---@return milliseconds
function Time.elapsed_ms(since)
    return Time.millis() - since
end

---@param seconds seconds
---@return string `HH:MM:SS`
function Time.format_time_since(seconds)
    if (type(seconds) ~= "number" or seconds < 1) then
        return "00:00:00"
    end

    local diff = math.max(0, math.floor(Time.now() - seconds))
    local h = math.floor(diff / 3600)
    local m = math.floor((diff % 3600) / 60)
    local s = diff % 60

    return _F("%02d:%02d:%02d", h, m, s)
end

---@param ms milliseconds
---@return string `HH:MM:SS`
function Time.format_time_since_ms(ms)
    return Time.format_time_since(math.floor(ms / 1000))
end

--------------------------------------
-- Subclass: Timer
--------------------------------------
---@class Time.Timer
---@field private duration milliseconds
---@field private start_time milliseconds
---@field private pause_time milliseconds|nil
---@field private paused boolean
Time.Timer = {}
Time.Timer.__index = Time.Timer

-- Creates a new timer that runs for `duration` milliseconds.
---@param duration milliseconds
---@return Time.Timer
function Time.Timer.new(duration)
    return setmetatable(
        {
            duration = duration,
            start_time = Time.millis(),
            paused = false,
            pause_time = nil,
        },
        Time.Timer
    )
end

-- Returns the elapsed time in milliseconds.
---@return milliseconds
function Time.Timer:elapsed()
    if self.paused and self.pause_time then
        return self.pause_time - self.start_time
    else
        return Time.millis() - self.start_time
    end
end

---@return boolean
function Time.Timer:is_done()
    return self:elapsed() >= self.duration
end

function Time.Timer:pause()
    if not self.paused then
        self.paused = true
        self.pause_time = Time.millis()
    end
end

function Time.Timer:resume()
    if not self.paused then
        return
    end

    local pauseDuration = Time.millis() - self.pause_time
    self.start_time = self.start_time + pauseDuration
    self.paused = false
    self.pause_time = nil
end

-- Resets the timer to start over (optionally with a new duration).
---@param new_duration? milliseconds Optional.
function Time.Timer:reset(new_duration)
    self.duration = new_duration or self.duration
    self.start_time = Time.millis()
    self.paused = false
    self.pause_time = nil
end


--------------------------------------
-- Subclass: TimePoint
--------------------------------------
---@class Time.TimePoint
Time.TimePoint = {}
Time.TimePoint.__index = Time.TimePoint

-- Returns a new point in time in milliseconds.
---@return Time.TimePoint
function Time.TimePoint.new(_)
    return setmetatable({ value = Time.millis() }, Time.TimePoint)
end

-- Returns the amount of elapsed time since this point in time.
---@return milliseconds
function Time.TimePoint:elapsed()
    return Time.millis() - self.value
end

---@param ms milliseconds
---@return boolean
function Time.TimePoint:has_elapsed(ms)
    return self:elapsed() >= ms
end

-- Alias of `TimePoint:elapsed`
---@return milliseconds
function Time.TimePoint:age()
    return self:elapsed()
end

---@param offset milliseconds
function Time.TimePoint:increment(offset)
    self.value = self.value + offset
end

function Time.TimePoint:reset()
    self.value = Time.millis()
end

return Time
