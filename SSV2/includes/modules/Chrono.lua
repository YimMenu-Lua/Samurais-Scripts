-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- TODO: refactor all this into a chrono class.

--------------------------------------
-- Class: Time
--------------------------------------
--**Global Singleton.**
---@class Time
---@field TimePoint TimePoint
---@field Timer Timer
---@field DateTime DateTime
local Time = { __type = "Time" }
Time.__index = Time
setmetatable(Time, Time)

-- Returns an approximation of the amount in seconds of CPU time used by the program.
--
-- **NOTE:** if you need real world clock time, use `DateTime.Now()` or `DateTime.new()`
---@return seconds
function Time.Now()
	return os.clock()
end

-- Returns an approximation of the amount in milliseconds of CPU time used by the program.
---@return milliseconds
function Time.Millis()
	return os.clock() * 1000
end

---@param seconds seconds
---@return seconds
function Time.Future(seconds)
	if (type(seconds) ~= "number") then
		return Time.Now()
	end

	return Time.Now() + seconds
end

---@param ms milliseconds
---@return milliseconds
function Time.FutureMS(ms)
	if (type(ms) ~= "number") then
		return Time.Millis()
	end

	return Time.Millis() + ms
end

-- Sleeps for the given duration in milliseconds.
--
-- Must be called inside a coroutine and within a scheduler loop.
---@param ms milliseconds
function Time.Sleep(ms)
	local future = Time.FutureMS(ms)
	while Time.Millis() < future do
		yield()
	end
end

---@param seconds seconds
---@return seconds
function Time.SecondsAgo(seconds)
	if (type(seconds) ~= "number") then
		return 0
	end

	return math.max(Time.Now() - seconds, 0)
end

---@param ms milliseconds
---@return milliseconds
function Time.MillisAgo(ms)
	if (type(ms) ~= "number") then
		return 0
	end

	return math.max(Time.Millis() - ms, 0)
end

---@param since seconds
---@param duration seconds
---@return boolean
function Time.HasElapsed(since, duration)
	return Time.Now() >= (since + duration)
end

---@param since milliseconds
---@param duration milliseconds
---@return boolean
function Time.HasElapsedMillis(since, duration)
	return Time.Millis() >= (since + duration)
end

-- Same as `Time.seconds_ago`. just gor readability and intent
---@param since seconds
---@return seconds
function Time.Elapsed(since)
	return Time.Now() - since
end

-- Same as `Time.ms_ago`. just gor readability and intent
---@param since milliseconds
---@return milliseconds
function Time.ElapsedMillis(since)
	return Time.Millis() - since
end

---@return seconds
function Time.Epoch()
	return os.time()
end

---@param s seconds
---@return string `HH:MM:SS`
function Time.FormatSeconds(s)
	if (type(s) ~= "number" or s <= 0) then
		return "00:00:00"
	end

	local h = math.floor(s / 3600)
	local m = math.floor((s % 3600) / 60)
	return _F("%02d:%02d:%02d", h, m, s % 60)
end

---@param ms milliseconds
---@return string `HH:MM:SS`
function Time.FormatMillis(ms)
	if (type(ms) ~= "number" or ms <= 0) then
		return "00:00:00"
	end

	return Time.FormatSeconds(math.floor(ms / 1000))
end

---@param s seconds
---@return string `HH:MM:SS`
function Time.FormatSince(s)
	if (type(s) ~= "number" or s <= 0) then
		return "00:00:00"
	end

	local diff = math.max(0, math.floor(Time.Now() - s))
	local H    = math.floor(diff / 3600)
	local M    = math.floor((diff % 3600) / 60)
	local S    = diff % 60

	return _F("%02d:%02d:%02d", H, M, S)
end

---@param ms milliseconds
---@return string `HH:MM:SS`
function Time.FormatSinceMillis(ms)
	if (type(ms) ~= "number" or ms <= 0) then
		return "00:00:00"
	end

	return Time.FormatSince(math.floor(ms / 1000))
end

--------------------------------------
-- Subclass: Timer
--------------------------------------
---@class Timer
---@field private m_duration milliseconds
---@field private m_start_time milliseconds
---@field private m_pause_time milliseconds|nil
---@field private m_is_paused boolean
---@overload fun(ms: milliseconds): Timer
local Timer <const> = { __type = "Timer" }
Timer.__index = Timer
---@diagnostic disable-next-line: param-type-mismatch
setmetatable(Timer, {
	__call = function(_, ...)
		return Timer.new(...)
	end
})

-- Creates a new timer that runs for `duration` milliseconds.
---@param duration milliseconds
---@return Timer
function Timer.new(duration)
	assert(type(duration) == "number" and duration > 0, "Timer duration must be a number >= 0 (milliseconds).")
	return setmetatable({
		m_duration   = math.max(0, duration or 0),
		m_start_time = Time.Millis(),
		m_pause_time = nil,
		m_is_paused  = false,
		---@diagnostic disable-next-line: param-type-mismatch
	}, Timer)
end

---@return boolean
function Timer:IsDone()
	return self:Elapsed() >= self.m_duration
end

---@return boolean
function Timer:IsPaused()
	return self.m_is_paused
end

-- Returns the elapsed time in milliseconds.
---@return milliseconds
function Timer:Elapsed()
	if self.m_is_paused and self.m_pause_time then
		return self.m_pause_time - self.m_start_time
	else
		return Time.Millis() - self.m_start_time
	end
end

-- Returns the remaining time in milliseconds.
---@return milliseconds
function Timer:Remaining()
	return math.max(0, self.m_duration - self:Elapsed())
end

function Timer:Pause()
	if not self.m_is_paused then
		self.m_is_paused  = true
		self.m_pause_time = Time.Millis()
	end
end

function Timer:Resume()
	if not self.m_is_paused then
		return
	end

	local pauseDuration = Time.Millis() - self.m_pause_time
	self.m_start_time   = self.m_start_time + pauseDuration
	self.m_is_paused    = false
	self.m_pause_time   = nil
end

-- Resets the timer to start over (optionally with a new duration).
---@param new_duration? milliseconds Optional.
function Timer:Reset(new_duration)
	self.m_duration   = new_duration or self.m_duration
	self.m_start_time = Time.Millis()
	self.m_is_paused  = false
	self.m_pause_time = nil
end

--------------------------------------
-- Subclass: TimePoint
--------------------------------------
---@class TimePoint
---@field private m_value milliseconds
---@overload fun(): TimePoint
local TimePoint <const> = { __type = "TimePoint" }
TimePoint.__index = TimePoint
---@diagnostic disable-next-line: param-type-mismatch
setmetatable(TimePoint, {
	__call = function(_, ...)
		return TimePoint.new()
	end
})

-- Returns a new point in time in milliseconds starting now *(zero ms)*.
---@return TimePoint
function TimePoint.new()
	---@diagnostic disable-next-line: param-type-mismatch
	return setmetatable({ m_value = Time.Millis() }, TimePoint)
end

---@return milliseconds
function TimePoint:Value()
	return self.m_value
end

-- Returns the amount of elapsed time since this point in time.
---@return milliseconds
function TimePoint:Elapsed()
	return Time.Millis() - self.m_value
end

---@param ms milliseconds
---@return boolean
function TimePoint:HasElapsed(ms)
	return self:Elapsed() >= ms
end

---@param offset milliseconds
function TimePoint:Increment(offset)
	self.m_value = self.m_value + offset
end

function TimePoint:Reset()
	self.m_value = Time.Millis()
end

--------------------------------------
-- Subclass: DateTime
--------------------------------------
---@class DateTime
---@field private m_epoch seconds
---@field private m_dt osdate
---@overload fun(p1: (seconds|osdateparam)?): DateTime
local DateTime <const> = { __type = "DateTime" }
DateTime.__index = DateTime
---@diagnostic disable-next-line: param-type-mismatch
setmetatable(DateTime, {
	__call = function(_, p1)
		return DateTime.new(p1)
	end
})

---@param p1 (seconds|osdateparam)?
---@return DateTime
function DateTime.new(p1)
	local epoch

	if (type(p1) == "table") then
		assert(type(p1.year) == "number", "Invalid argument: year<integer>")
		assert(type(p1.month) == "number", "Invalid argument: month<integer>")
		assert(type(p1.day) == "number", "Invalid argument: day<integer>")
		---@diagnostic disable-next-line: param-type-mismatch
		epoch = os.time(p1)
	elseif (type(p1) == "number") then
		epoch = p1
	else
		epoch = os.time()
	end

	return setmetatable({
		m_epoch = epoch,
		m_dt    = os.date("*t", epoch)
		---@diagnostic disable-next-line: param-type-mismatch
	}, DateTime)
end

---@return DateTime
function DateTime.Now()
	return DateTime.new()
end

---@param fmt? string
---@return string
function DateTime:Format(fmt)
	---@diagnostic disable
	if (string.isvalid(fmt) and fmt == "*t") then
		return os.date("%Y-%m-%d %H:%M:%S", self.m_epoch)
	end

	return os.date(fmt or "%Y-%m-%d %H:%M:%S", self.m_epoch)
	---@diagnostic enable
end

---@return seconds
function DateTime:Epoch()
	return self.m_epoch
end

---@return osdate
function DateTime:AsTable()
	return self.m_dt
end

---@return milliseconds
function DateTime:ToMillis()
	return self.m_epoch * 1000
end

---@param a DateTime|seconds
---@param b DateTime|seconds
---@return DateTime
function DateTime.__add(a, b)
	if type(a) == "number" then
		return DateTime.new(b.m_epoch + a)
	elseif type(b) == "number" then
		return DateTime.new(a.m_epoch + b)
	elseif (IsInstance(a, DateTime) and IsInstance(b, DateTime)) then
		return DateTime.new(a.m_epoch + b.m_epoch)
	else
		error("Attempt to perform arithmetic on a DateTime object with an invalid operand.")
	end
end

---@param a DateTime|seconds
---@param b DateTime|seconds
---@return DateTime|seconds -- DateTime or duration
function DateTime.__sub(a, b)
	if (type(a) == "number") then
		return DateTime.new(b.m_epoch - a)
	elseif (type(b) == "number") then
		return DateTime.new(a.m_epoch - b)
	elseif (IsInstance(a, DateTime) and IsInstance(b, DateTime)) then
		return a.m_epoch - b.m_epoch
	else
		error("Attempt to perform arithmetic on a DateTime object with an invalid operand.")
	end
end

---@param a DateTime|seconds
---@param b DateTime|seconds
---@return boolean
function DateTime.__lt(a, b)
	if (type(a) == "number") then
		return b.m_epoch < a
	elseif (type(b) == "number") then
		return a.m_epoch < b
	elseif (IsInstance(a, DateTime) and IsInstance(b, DateTime)) then
		return a.m_epoch < b.m_epoch
	else
		error("Attempt to compare a DateTime object to an invalid operand.")
	end
end

---@param a DateTime|seconds
---@param b DateTime|seconds
---@return boolean
function DateTime.__le(a, b)
	if (type(a) == "number") then
		return b.m_epoch <= a
	elseif (type(b) == "number") then
		return a.m_epoch <= b
	elseif (IsInstance(a, DateTime) and IsInstance(b, DateTime)) then
		return a.m_epoch <= b.m_epoch
	else
		error("Attempt to compare a DateTime object to an unknown operand.")
	end
end

---@param a DateTime|seconds
---@param b DateTime|seconds
---@return boolean
function DateTime.__eq(a, b)
	if (type(a) == "number") then
		return b.m_epoch == a
	elseif (type(b) == "number") then
		return a.m_epoch == b
	elseif (IsInstance(a, DateTime) and IsInstance(b, DateTime)) then
		return a.m_epoch == b.m_epoch
	else
		error("Attempt to compare a DateTime object to an unknown operand.")
	end
end

---@return string
function DateTime:__tostring()
	return self:Format()
end

return {
	Time      = Time,
	Timer     = Timer,
	TimePoint = TimePoint,
	DateTime  = DateTime,
}
