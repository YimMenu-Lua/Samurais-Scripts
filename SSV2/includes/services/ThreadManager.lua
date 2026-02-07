-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@diagnostic disable: lowercase-global

local API_VER <const> = Backend:GetAPIVersion()

---@enum eThreadState
eThreadState = {
	UNK       = -1,
	DEAD      = 0,
	RUNNING   = 1,
	SUSPENDED = 2,
}

---@enum eInternalThreadState
eInternalThreadState = {
	NORMAL     = 0,
	STALLED    = 1,
	HUNG       = 2,
	BURSTING   = 3,
	TOO_FAST   = 4,
	TOO_SLOW   = 5,
	STARVED    = 5,
	DEADLOCKED = 5,
}

--#region Thread

--------------------------------------
-- Class: Thread
--------------------------------------
---@ignore
---@class Thread : ClassMeta<Thread>
---@field private m_name string
---@field private m_callback function
---@field private m_can_run boolean
---@field private m_should_pause boolean
---@field private m_state eThreadState
---@field private m_time_created TimePoint
---@field private m_time_started seconds
---@field private m_last_entry_at seconds
---@field private m_last_exit_at seconds
---@field private m_last_yield_at seconds
---@field private m_avg_work_ms milliseconds
---@field private m_avg_cycle_ms milliseconds
---@overload fun(name: string, callback: function): Thread
local Thread = Class("Thread")
function Thread.new(name, callback)
	if not string.isvalid(name) then
		name = string.random(5, true):upper()
	end

	return setmetatable(
		{
			m_name          = name,
			m_callback      = callback,
			m_can_run       = false,
			m_should_pause  = false,
			m_state         = eThreadState.UNK,
			m_time_created  = TimePoint.new(),
			m_time_started  = 0,
			m_last_entry_at = 0,
			m_last_exit_at  = 0,
			m_last_yield_at = 0,
			m_avg_work_ms   = 0,
			m_avg_cycle_ms  = 0,
		},
		---@diagnostic disable-next-line
		Thread
	)
end

---@return string
function Thread:GetName()
	return self.m_name
end

---@return eThreadState
function Thread:GetState()
	return self.m_state
end

---@return function
function Thread:GetCallback()
	return self.m_callback
end

---@return milliseconds
function Thread:GetTimeCreated()
	return self.m_time_created:value()
end

---@return seconds
function Thread:GetTimeStarted()
	return self.m_time_started
end

---@return string
function Thread:GetLifetime()
	return Time.format_time_since_ms(self:GetTimeCreated())
end

---@return string
function Thread:GetRunningTime()
	return Time.format_time_since(self:GetTimeStarted())
end

---@return boolean
function Thread:CanRun()
	return self.m_can_run and type(self.m_callback) == "function"
end

---@return boolean
function Thread:IsRunning()
	return self.m_state == eThreadState.RUNNING
end

---@return boolean
function Thread:IsSuspended()
	return self.m_state == eThreadState.SUSPENDED
end

---@param s? script_util
function Thread:OnTick(s)
	self.m_can_run = (type(self.m_callback) == "function")
	if (not self.m_can_run) then
		log.fwarning("Thread %s was terminated because it has no callback", self.m_name)
		self:Stop()
		return
	end

	self.m_time_started  = Time.now()
	self.m_last_entry_at = Time.now()
	Backend:debug("Started thread %s", self.m_name)

	while (self.m_can_run) do
		if (self.m_should_pause) then
			self.m_state = eThreadState.SUSPENDED
			self.m_last_entry_at = 0
			repeat
				self.m_last_yield_at = Time.now()
				yield()
			until not self.m_should_pause
			self.m_time_started = Time.now()
			self.m_last_entry_at = Time.now()
		end

		self.m_state = eThreadState.RUNNING

		local cycle_start = Time.now()
		self.m_last_entry_at = cycle_start

		local work_start = cycle_start
		local ok, err = pcall(self.m_callback, s)
		local work_end = Time.now()
		local work_ms = (work_end - work_start) * 1000
		self.m_avg_work_ms = self.m_avg_work_ms * 0.9 + work_ms * 0.1

		if (not ok) then
			log.fwarning("Thread %s was terminated due to an unhandled exception: %s", self.m_name, err)
			self:Stop()
			return
		end

		self.m_last_exit_at = Time.now()
		self.m_last_yield_at = self.m_last_exit_at
		local cycle_ms = (self.m_last_exit_at - cycle_start) * 1000
		self.m_avg_cycle_ms = self.m_avg_cycle_ms * 0.9 + cycle_ms * 0.1

		yield()
	end
end

---@return boolean
function Thread:Start()
	if (self.m_state == eThreadState.DEAD or self.m_state == eThreadState.UNK) then
		return false
	end

	self.m_can_run = (type(self.m_callback) == "function")
	if not self.m_can_run then
		log.fwarning("Thread %s was terminated because it had no callback", self.m_name)
		self.m_state = eThreadState.DEAD
		return false
	end

	self.m_state = eThreadState.RUNNING
	self.m_time_started = Time.now()
	Backend:debug("Started thread %s", self.m_name)
	return true
end

function Thread:Stop()
	if (self.m_state == eThreadState.UNK or self.m_state == eThreadState.DEAD) then
		return
	end

	self.m_time_started = 0
	self.m_can_run = false
	self.m_state = eThreadState.DEAD
	Backend:debug("Terminated thread %s", self.m_name)
end

function Thread:Suspend()
	self.m_time_started = 0
	self.m_should_pause = true
end

function Thread:Resume()
	self.m_should_pause = false
	self.m_time_started = Time.now()
end

---@return eInternalThreadState
function Thread:GetInternalState()
	local now = Time.now()

	if (now - self.m_last_entry_at > 5.0) then
		return eInternalThreadState.STALLED
	end

	if (now - self.m_last_exit_at > 2.0) then
		return eInternalThreadState.STARVED
	end

	if (self.m_avg_cycle_ms < 0.02) then
		return eInternalThreadState.TOO_FAST
	end

	if (self.m_avg_work_ms < 0.1) then
		return eInternalThreadState.BURSTING
	end

	return eInternalThreadState.NORMAL
end

---@return milliseconds
function Thread:GetLoadAvg()
	if (self.m_avg_cycle_ms == 0) then
		return 0
	end

	return self.m_avg_work_ms / self.m_avg_cycle_ms
end

--#endregion


--#region ThreadManager

-- TODO: state-bucketed refactor: split m_threads into separate tables by state
-- (RUNNING/SUSPENDED/DEAD/UNK) for faster bulk operations in high thread count use cases

---------------------------------------
-- Class: ThreadManager
---------------------------------------
---@class ThreadManager : ClassMeta<ThreadManager>
---@field private m_threads table<string, Thread>
---@field private m_mock_routines table<integer, thread>
---@field private m_callback_handlers table<integer, { dispatch: function}>
local ThreadManager = Class("ThreadManager")

---@return ThreadManager
function ThreadManager:init()
	local instance = setmetatable({
		m_threads = {},
		m_mock_routines = {}
	}, self)

	instance.m_callback_handlers = {
		[Enums.eAPIVersion.L54] = {
			dispatch = function(callback)
				table.insert(
					instance.m_mock_routines,
					coroutine.create(callback)
				)
			end
		},
		[Enums.eAPIVersion.V1] = {
			dispatch = function(callback)
				script.run_in_fiber(function(s)
					callback(s)
				end)
			end
		},
		[Enums.eAPIVersion.V2] = {
			dispatch = function(callback)
				script.run_in_fiber(function(s)
					callback(s)
				end)
			end
			-- dispatch = function(callback)
			-- 	---@diagnostic disable-next-line: undefined-field
			-- 	script.run_in_callback(function(s)
			-- 		callback(s)
			-- 	end)
			-- end
		}
	}

	Backend:RegisterEventCallback(Enums.eBackendEvent.RELOAD_UNLOAD, function()
		instance:Shutdown()
	end)

	return instance
end

-- Runs a callback once in a fiber.
---@param func function
function ThreadManager:Run(func)
	if (type(func) ~= "function") then
		Backend:debug("[ThreadManager] Invalid parameter! Expected function, got %s instead.", type(func))
		return
	end

	local handler = self.m_callback_handlers[API_VER]
	if not (handler or handler.dispatch) then
		Backend:debug("[ThreadManager] No handler for API version: %s", EnumToString(Enums.eAPIVersion, API_VER))
		return
	end

	handler.dispatch(func)
end

-- Creates a thread that runs in a loop.
---@param name string
---@param func function
---@param suspended? boolean
---@param is_debug_thread? boolean
function ThreadManager:RegisterLooped(name, func, suspended, is_debug_thread)
	if (API_VER == Enums.eAPIVersion.L54 and not is_debug_thread) then
		return
	end

	if (is_debug_thread and API_VER ~= Enums.eAPIVersion.L54) then
		return
	end

	if (string.isempty(name) or string.iswhitespace(name)) then
		name = string.random(5, true):upper()
	end

	if (self:IsThreadRegistered(name)) then
		log.fwarning("a thread with the name '%s' is already registered!", name)
		return
	end

	local thread = Thread(name, func)
	if suspended then
		thread:Suspend()
	end

	self.m_threads[name] = thread
	self:Run(function(s)
		thread:OnTick(s)
	end)

	return thread
end

---@return Thread
function ThreadManager:GetThread(name)
	return self.m_threads[name]
end

---@return eThreadState
function ThreadManager:GetThreadState(name)
	local thread = self:GetThread(name)
	if not thread then
		return eThreadState.UNK
	end

	return thread:GetState()
end

function ThreadManager:ListThreads()
	return self.m_threads
end

---@param name string
---@return boolean
function ThreadManager:IsThreadRegistered(name)
	return self.m_threads[name] ~= nil
end

---@param name string
---@return boolean
function ThreadManager:IsThreadRunning(name)
	local thread = self:GetThread(name)
	return thread and thread:IsRunning() or false
end

---@param name string
function ThreadManager:StartThread(name)
	local thread = self:GetThread(name)
	if not thread then
		return
	end

	local ok = thread:Start()
	if not ok then
		local func = thread:GetCallback()
		local new_thread = Thread(name, func)

		self.m_threads[name] = new_thread
		self:Run(function(s)
			new_thread:OnTick(s)
		end)
	end
end

---@param name string
function ThreadManager:SuspendThread(name)
	local thread = self:GetThread(name)
	if not thread then
		return
	end

	thread:Suspend()
end

---@param name string
function ThreadManager:ResumeThread(name)
	local thread = self:GetThread(name)
	if not thread then
		return
	end

	thread:Resume()
end

---@param name string
function ThreadManager:StopThread(name)
	local thread = self:GetThread(name)
	if not thread then
		return
	end

	thread:Stop()
end

---@param name string
function ThreadManager:RemoveThread(name)
	self:StopThread(name)
	self.m_threads[name] = nil
end

function ThreadManager:SuspendAllThreads()
	for _, thread in pairs(self.m_threads) do
		thread:Suspend()
	end
end

function ThreadManager:ResumeAllThreads()
	for _, thread in pairs(self.m_threads) do
		thread:Resume()
	end
end

function ThreadManager:RemoveAllThreads()
	for name, _ in pairs(self.m_threads) do
		self:RemoveThread(name)
	end

	self.m_mock_routines = {}
end

function ThreadManager:Shutdown()
	self:RemoveAllThreads()
end

function ThreadManager:DebugPrint()
	if (not Backend.debug_mode) then
		return
	end

	for name, thread in pairs(self.m_threads) do
		printf(
			"[%s] running: %s, suspended: %s",
			name,
			thread:IsRunning(),
			thread:IsSuspended()
		)
	end
end

function ThreadManager:UpdateMockRoutines()
	if (#self.m_mock_routines == 0) then
		return
	end

	while (API_VER == Enums.eAPIVersion.L54) do
		for i = #self.m_mock_routines, 1, -1 do
			local co = self.m_mock_routines[i]
			if (coroutine.status(co) == "dead") then
				table.remove(self.m_mock_routines, i)
			else
				local ok, err = coroutine.resume(co)
				if (not ok) then
					Backend:debug("[Coroutine error]: %s", err)
					table.remove(self.m_mock_routines, i)
				end
			end
		end
	end
end

--#endregion

return ThreadManager
