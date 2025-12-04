---@diagnostic disable: param-type-mismatch, lowercase-global

local API_VER <const> = Backend:GetAPIVersion()

---@enum eThreadState
eThreadState = {
    UNK       = -1,
    DEAD      = 0,
    RUNNING   = 1,
    SUSPENDED = 2,
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
---@field private m_time_created Time.TimePoint
---@field private m_time_started seconds
---@overload fun(name: string, callback: function): Thread
local Thread = Class("Thread")
function Thread.new(name, callback)
    if string.isnullorwhitespace(name) then
        name = string.random(5, true):upper()
    end

    return setmetatable(
        {
            m_name         = name,
            m_callback     = callback,
            m_can_run      = false,
            m_should_pause = false,
            m_state        = eThreadState.UNK,
            m_time_created = TimePoint.new(),
            m_time_started = 0
        },
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
    return self.m_time_created.value
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
function Thread:Tick(s)
    self.m_can_run = (type(self.m_callback) == "function")
    if not self.m_can_run then
        log.fwarning("Thread %s was terminated because it has no callback", self.m_name)
        self:Stop()
        return
    end

    self.m_time_started = Time.now()
    Backend:debug("Started thread %s", self.m_name)
    while self.m_can_run do
        if self.m_should_pause then
            self.m_state = eThreadState.SUSPENDED
            self.m_time_started = 0
            repeat
                yield()
            until not self.m_should_pause
            self.m_time_started = Time.now()
        end

        self.m_state = eThreadState.RUNNING
        local ok, err = pcall(self.m_callback, s)
        if not ok then
            log.fwarning("Thread %s was terminated due to an unhandled exception: %s", self.m_name, err)
            self:Stop()
            return
        end
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
        log.fwarning("Thread %s was killed because it has no callback", self.m_name)
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
        [eAPIVersion.L54] = {
            dispatch = function(callback)
                table.insert(
                    instance.m_mock_routines,
                    coroutine.create(callback)
                )
            end
        },
        [eAPIVersion.V1] = {
            dispatch = function(callback)
                script.run_in_fiber(function(s)
                    callback(s)
                end)
            end
        },
        [eAPIVersion.V2] = {
            dispatch = function(callback)
                ---@diagnostic disable-next-line: undefined-field
                script.run_in_callback(function(s)
                    callback(s)
                end)
            end
        }
    }

    Backend:RegisterEventCallback(eBackendEvent.RELOAD_UNLOAD, function()
        instance:Shutdown()
    end)

    return instance
end

---@param func function
function ThreadManager:RunInFiber(func)
    if (type(func) ~= "function") then
        Backend:debug("[ThreadManager] Invalid parameter! Expected function, got %s instead.", type(func))
        return
    end

    local handler = self.m_callback_handlers[API_VER]
    if not (handler or handler.dispatch) then
        Backend:debug("[ThreadManager] No handler for API version: %s", EnumTostring(eAPIVersion, API_VER))
        return
    end

    handler.dispatch(func)
end

---@param name string
---@param func function
---@param suspended? boolean
---@param is_debug_thread? boolean
function ThreadManager:CreateNewThread(name, func, suspended, is_debug_thread)
    if (API_VER == eAPIVersion.L54 and not is_debug_thread) then
        return
    end

    if (is_debug_thread and API_VER ~= eAPIVersion.L54) then
        return
    end

    if string.isnullorwhitespace(name) then
        name = string.random(5, true):upper()
    end

    if self:IsThreadRegistered(name) then
        log.fwarning("Thread '%s' is already registered!", name)
        return
    end

    local thread = Thread(name, func)
    if suspended then
        thread:Suspend()
    end

    self.m_threads[name] = thread
    self:RunInFiber(function(s)
        thread:Tick(s)
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
        self:RunInFiber(function(s)
            new_thread:Tick(s)
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

    while (API_VER == eAPIVersion.L54) do
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
