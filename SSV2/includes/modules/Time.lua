-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


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

---@return seconds
function Time.epoch()
	return os.time()
end

---@param s seconds
---@return string `HH:MM:SS`
function Time.format_time_seconds(s)
	if (type(s) ~= "number" or s <= 0) then
		return "00:00:00"
	end

	local h = math.floor(s / 3600)
	local m = math.floor((s % 3600) / 60)
	return _F("%02d:%02d:%02d", h, m, s % 60)
end

---@param ms milliseconds
---@return string `HH:MM:SS`
function Time.format_time_ms(ms)
	if (type(ms) ~= "number" or ms <= 0) then
		return "00:00:00"
	end

	return Time.format_time_seconds(math.floor(ms / 1000))
end

---@param s seconds
---@return string `HH:MM:SS`
function Time.format_time_since(s)
	if (type(s) ~= "number" or s <= 0) then
		return "00:00:00"
	end

	local diff = math.max(0, math.floor(Time.now() - s))
	local H    = math.floor(diff / 3600)
	local M    = math.floor((diff % 3600) / 60)
	local S    = diff % 60

	return _F("%02d:%02d:%02d", H, M, S)
end

---@param ms milliseconds
---@return string `HH:MM:SS`
function Time.format_time_since_ms(ms)
	if (type(ms) ~= "number" or ms <= 0) then
		return "00:00:00"
	end

	return Time.format_time_since(math.floor(ms / 1000))
end

--------------------------------------
-- Subclass: Timer
--------------------------------------
---@class Timer
---@field private m_duration milliseconds
---@field private m_start_time milliseconds
---@field private m_pause_time milliseconds|nil
---@field private m_is_paused boolean
local Timer <const> = { __type = "Timer" }
Timer.__index = Timer

-- Creates a new timer that runs for `duration` milliseconds.
---@param duration milliseconds
---@return Timer
function Timer.new(duration)
	return setmetatable({
		m_duration   = duration,
		m_start_time = Time.millis(),
		m_pause_time = nil,
		m_is_paused  = false,
	}, Timer)
end

---@return boolean
function Timer:is_done()
	return self:elapsed() >= self.m_duration
end

---@return boolean
function Timer:is_paused()
	return self.m_is_paused
end

-- Returns the elapsed time in milliseconds.
---@return milliseconds
function Timer:elapsed()
	if self.m_is_paused and self.m_pause_time then
		return self.m_pause_time - self.m_start_time
	else
		return Time.millis() - self.m_start_time
	end
end

-- Returns the remaining time in milliseconds.
---@return milliseconds
function Timer:remaining()
	return math.max(0, self.m_duration - self:elapsed())
end

function Timer:pause()
	if not self.m_is_paused then
		self.m_is_paused  = true
		self.m_pause_time = Time.millis()
	end
end

function Timer:resume()
	if not self.m_is_paused then
		return
	end

	local pauseDuration = Time.millis() - self.m_pause_time
	self.m_start_time   = self.m_start_time + pauseDuration
	self.m_is_paused    = false
	self.m_pause_time   = nil
end

-- Resets the timer to start over (optionally with a new duration).
---@param new_duration? milliseconds Optional.
function Timer:reset(new_duration)
	self.m_duration   = new_duration or self.m_duration
	self.m_start_time = Time.millis()
	self.m_is_paused  = false
	self.m_pause_time = nil
end

--------------------------------------
-- Subclass: TimePoint
--------------------------------------
---@class TimePoint
---@field private m_value milliseconds
local TimePoint <const> = { __type = "TimePoint" }
TimePoint.__index = TimePoint

-- Returns a new point in time in milliseconds starting now *(zero ms)*.
---@return TimePoint
function TimePoint.new()
	---@diagnostic disable-next-line
	return setmetatable({ m_value = Time.millis() }, TimePoint)
end

---@return milliseconds
function TimePoint:value()
	return self.m_value
end

-- Returns the amount of elapsed time since this point in time.
---@return milliseconds
function TimePoint:elapsed()
	return Time.millis() - self.m_value
end

---@param ms milliseconds
---@return boolean
function TimePoint:has_elapsed(ms)
	return self:elapsed() >= ms
end

-- Alias of `TimePoint:elapsed`
---@return milliseconds
function TimePoint:age()
	return self:elapsed()
end

---@param offset milliseconds
function TimePoint:increment(offset)
	self.m_value = self.m_value + offset
end

function TimePoint:reset()
	self.m_value = Time.millis()
end

---@return milliseconds
function TimePoint:capture()
	return Time.millis() - self.m_value
end

--------------------------------------
-- Subclass: DateTime
--------------------------------------
---@class DateTime
---@field private m_epoch seconds
---@field m_dt osdate
local DateTime <const> = { __type = "DateTime" }
DateTime.__index = DateTime

---@param p1 (seconds|osdateparam)?
---@return DateTime
function DateTime.new(p1)
	local epoch
	local dt

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
	}, DateTime)
end

---@return DateTime
function DateTime.now()
	return DateTime.new(os.time())
end

---@param fmt? string
---@return string
function DateTime:format(fmt)
	---@diagnostic disable
	if (string.isvalid(fmt) and fmt == "*t") then
		return os.date("%Y-%m-%d %H:%M:%S", self.m_epoch)
	end

	return os.date(fmt or "%Y-%m-%d %H:%M:%S", self.m_epoch)
	---@diagnostic enable
end

---@return seconds
function DateTime:epoch()
	return self.m_epoch
end

---@return osdate
function DateTime:to_table()
	return self.m_dt
end

---@return milliseconds
function DateTime:to_millis()
	return self.m_epoch / 1000
end

---@param a DateTime|seconds
---@param b DateTime|seconds
---@return DateTime
function DateTime.__add(a, b)
	if type(a) == "number" then
		return DateTime.new(b.m_epoch + a)
	elseif type(b) == "number" then
		return DateTime.new(a.m_epoch + b)
	else
		error("Attempt to perform arithmetic on a DateTime object with an invalid operand.")
	end
end

---@param a DateTime|seconds
---@param b DateTime|seconds
---@return DateTime
function DateTime.__sub(a, b)
	if (type(a) == "number") then
		return DateTime.new(b.m_epoch - a)
	elseif (type(b) == "number") then
		return DateTime.new(a.m_epoch - b)
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
		error("Attempt to compare a DateTime object to an unknown operand.")
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
	---@diagnostic disable-next-line
	return self:format()
end

return {
	Time      = Time,
	Timer     = Timer,
	TimePoint = TimePoint,
	DateTime  = DateTime,
}
