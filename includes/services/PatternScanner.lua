---@diagnostic disable: param-type-mismatch

--------------------------------------
-- Class: Pointer
--------------------------------------
-- Represents a single memory pattern pointer. Used internally by `PatternScanner` to hold the scan pattern, result address, and name.
-- > [!Note]
-- > This is just an intermediate object. There is no use for it outside of `PatternScanner`.
---@generic T
---@class Pointer<T> @internal
---@field private m_name string
---@field private m_address integer
---@field private m_ptr pointer YimMenu API usertype
---@field private m_pattern string
---@field private m_func fun(ptr: pointer): any
---@overload fun(name: string, pattern: string, func: fun(ptr: pointer): any): Pointer
local Pointer = {}
Pointer.__index = Pointer
setmetatable(Pointer, {
    __call = function(cls, ...)
        return cls:new(...)
    end,
})

function Pointer:__tostring()
    return _F("Pointer<%s @ 0x%X>", self.m_name, self.m_address)
end

-- Creates a new unresolved `Pointer`.
---@param name string
---@param pattern string
---@param func fun(ptr: pointer)
---@return Pointer
function Pointer:new(name, pattern, func)
    local instance = setmetatable({}, Pointer)

    instance.m_name = name
    instance.m_pattern = pattern
    instance.m_func = func
    instance.m_address = 0x0

    return instance
end

-- Scans memory for this pointer's pattern and resolves its address.
--
-- Logs a debug message if successful.
---@return boolean
function Pointer:Scan()
    self.m_ptr = memory.scan_pattern(self.m_pattern)
    self.m_address = self.m_ptr:get_address()

    if (self.m_ptr:is_null()) then
        log.fwarning("[PatternScanner]: Failed to find pattern: %s", self.m_name)
    end

    log.fdebug("[PatternScanner]: Found %s at 0x%X", self.m_name, self.m_address)

    local ok, result = pcall(self.m_func, self.m_ptr)
    if (not ok) then
        log.fwarning("[PatternScanner]: Resolver failed for %s: %s", self.m_name, result)
        return false
    end

    return self.m_ptr:is_valid()
end

function Pointer:GetAddress()
    return self.m_address
end

---@enum eScannerState
local eScannerState = {
    NONE = 0x0,
    BUSY = 0x1,
    DONE = 0x2
}

--------------------------------------
-- Class: PatternScanner
--------------------------------------
-- A simple manager for storing and lazy scanning multiple memory patterns.
---@class PatternScanner : ClassMeta<PatternScanner>
---@field private m_pointers dict<Pointer>
---@field private m_failed_pointers array<Pointer>
---@field private m_state eScannerState
---@overload fun(_: any): PatternScanner
local PatternScanner = Class("PatternScanner")

-- Initializes a new `PatternScanner` instance.
---@return PatternScanner
function PatternScanner:init()
    return setmetatable(
        {
            m_pointers = {},
            m_failed_pointers = {},
            m_state = eScannerState.NONE
        },
        PatternScanner
    )
end

-- Registers a new pointer to be scanned later. If a pointer with the same name already exists, the new name will be concatenated with four random characters.
---@generic T -- Type inference.
---@param name string -- Unique name for the pointer
---@param pattern string -- AOB pattern string to scan for (IDA-style)
---@param func fun(ptr: pointer) -- Resolver called with the found pointer.
function PatternScanner:Add(name, pattern, func)
    if self.m_pointers[name] then
        name = name .. string.random(4)
        log.fwarning("[PatternScanner]: A pointer with the same name already exists. Renamed this one to %s", name)
    end

    local ptr = Pointer(name, pattern, func)
    self.m_pointers[name] = ptr
end

-- Retrieves a previously registered `Pointer` by name.
---@return Pointer -- Our custom `Pointer` object, not the default API usertype.
function PatternScanner:Get(name)
    return self.m_pointers[name]
end

-- Scans for all registered pointers asynchronously in a fiber.
--
-- Each pointer's pattern is scanned and resolved individually.
--
-- Should be called on script init.
function PatternScanner:Scan()
    if (self:IsBusy()) then
        log.debug("PatternScanner is busy at the moment. Try again later.")
        return
    end

    ThreadManager:RunInFiber(function()
        self.m_state = eScannerState.BUSY

        for _, ptr in pairs(self.m_pointers) do
            if not ptr:Scan() then
                table.insert(self.m_failed_pointers, ptr)
            end

            yield()
        end

        self.m_state = eScannerState.DONE
    end)
end

-- Retries failed pointer scans (if any) asynchronously in a fiber.
--
-- Manually called.
function PatternScanner:RetryScan()
    if (self:IsBusy()) then
        log.debug("PatternScanner is busy at the moment. Try again later.")
        return
    end

    local sizeof_failed = #self.m_failed_pointers
    if (sizeof_failed == 0) then
        log.debug("[PatternScanner] No failed pointers to rescan.")
        return
    end

    ThreadManager:RunInFiber(function()
        local success = 0
        self.m_state = eScannerState.BUSY

        for i = sizeof_failed, 1, -1 do
            local ptr = self.m_failed_pointers[i]

            if ptr:Scan() then
                table.remove(self.m_failed_pointers, i)
                success = success + 1
            end

            yield()
        end

        log.fdebug("[PatternScanner] Recovered %d/%d failed pointer(s)", success, sizeof_failed)
        self.m_state = eScannerState.DONE
    end)
end

-- Returns whether all deferred scans are complete.
---@return boolean
function PatternScanner:IsDone()
    return self.m_state == eScannerState.DONE
end

-- Returns whether a pattern scan is in-progress.
---@return boolean
function PatternScanner:IsBusy()
    return self.m_state == eScannerState.BUSY
end

---@return dict<Pointer>, array<Pointer>
function PatternScanner:ListPointers()
    return self.m_pointers, self.m_failed_pointers
end

return PatternScanner
