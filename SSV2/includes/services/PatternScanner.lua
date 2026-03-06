-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


--------------------------------------
-- Class: Pattern
--------------------------------------
-- Represents a scannable memory pattern.
--
-- Used internally by `PatternScanner` to hold the scan pattern, result address, callback, and name.
--
-- > [!Note]
--
-- > This is just an intermediate object. There is no use for it outside of `PatternScanner`.
---@generic T
---@class Pattern<T>
---@field private m_name string
---@field private m_address uint64_t
---@field protected m_ptr pointer
---@field private m_sig string
---@field private m_func fun(ptr: pointer): any
---@overload fun(name: string, ida_sig: string, func: fun(ptr: pointer): any): Pattern
local Pattern = { __type = "Pattern" }
Pattern.__index = Pattern
---@diagnostic disable-next-line
setmetatable(Pattern, {
	__call = function(cls, ...)
		return cls.new(...)
	end,
})

function Pattern:__tostring()
	return _F("Pattern<%s> @ 0x%X", self.m_name, self.m_address)
end

---@param name string
---@param ida_sig string
---@param func fun(ptr: pointer)
---@return Pattern
function Pattern.new(name, ida_sig, func)
	return setmetatable({
		m_name    = name,
		m_sig     = ida_sig,
		m_ptr     = nullptr,
		m_address = 0x0,
		m_func    = func
		---@diagnostic disable-next-line: param-type-mismatch
	}, Pattern)
end

-- Scans memory for this pointer's pattern and resolves its address.
--
-- Logs a debug message if successful.
---@return boolean
function Pattern:Scan()
	self.m_ptr     = memory.scan_pattern(self.m_sig)
	self.m_address = self.m_ptr:get_address()

	if (self.m_ptr:is_null()) then
		log.fwarning("[PatternScanner]: Failed to find pattern: %s", self.m_name)
		return false
	end

	log.fdebug("[PatternScanner]: Found %s at 0x%X", self.m_name, self.m_address)

	if (type(self.m_func) == "function") then
		local ok, result = pcall(self.m_func, self.m_ptr)
		if (not ok) then
			log.fwarning("[PatternScanner]: Resolver failed for %s: %s", self.m_name, result)
			return false
		end
	end

	return self.m_ptr:is_valid()
end

---@return uint64_t
function Pattern:GetAddress()
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
-- A singleton manager for storing and lazy scanning multiple memory patterns.
---@class PatternScanner : ClassMeta<PatternScanner>
---@field private m_patterns dict<Pattern>
---@field private m_failed_patterns array<Pattern>
---@field private m_state eScannerState
---@field protected m_initialized boolean
---@overload fun(): PatternScanner
local PatternScanner = Class("PatternScanner")

---@return PatternScanner
function PatternScanner:init()
	if (self.m_initialized) then
		log.warning("Attempt to create a second instance of a singleton (PatternScanner)")
		return self
	end

	self.m_patterns        = {}
	self.m_failed_patterns = {}
	self.m_state           = eScannerState.NONE
	self.m_initialized     = true
	return self
end

-- Registers a new pattern to be scanned later.
--
-- If a pattern with the same name already exists, the new name will be concatenated with four random characters.
---@param name string -- Unique name
---@param sig string -- IDA signature
---@param func fun(ptr: pointer) -- Resolver called with the found pointer.
function PatternScanner:Add(name, sig, func)
	if (self.m_patterns[name]) then
		name = name .. string.random(4)
		log.fwarning("[PatternScanner]: A pattern with the same name already exists. Renamed current to '%s'", name)
	end

	self.m_patterns[name] = Pattern(name, sig, func)
end

---@return Pattern?
function PatternScanner:Get(name)
	return self.m_patterns[name]
end

-- Scans all registered patterns asynchronously in a fiber.
--
-- Should be called on script init.
function PatternScanner:Scan()
	if (self:IsBusy()) then
		log.debug("PatternScanner is busy at the moment. Try again later.")
		return
	end

	-- Scanning in a fiber improves perceived load time
	-- but delays pointer availability during script initialization.
	-- Since we only scan a small number of patterns,
	-- we currently run synchronously to guarantee immediate access.
	-- The fiber call can be reintroduced if scan count grows.

	-- ThreadManager:Run(function()
	self.m_state = eScannerState.BUSY

	for _, ptr in pairs(self.m_patterns) do
		if (not ptr:Scan()) then
			table.insert(self.m_failed_patterns, ptr)
		end

		-- yield()
	end

	self.m_state = eScannerState.DONE
	-- end)
end

-- Retries failed pattern scans (if any) asynchronously in a fiber.
--
-- Manually called.
function PatternScanner:RetryScan()
	if (self:IsBusy()) then
		log.debug("PatternScanner is busy at the moment. Try again later.")
		return
	end

	local sizeof_failed = #self.m_failed_patterns
	if (sizeof_failed == 0) then
		log.debug("[PatternScanner] No failed pointers to rescan.")
		return
	end

	ThreadManager:Run(function()
		local success = 0
		self.m_state = eScannerState.BUSY

		for i = sizeof_failed, 1, -1 do
			local ptr = self.m_failed_patterns[i]

			if (ptr:Scan()) then
				table.remove(self.m_failed_patterns, i)
				success = success + 1
			end

			yield()
		end

		log.fdebug("[PatternScanner] Recovered %d/%d failed pattern(s)", success, sizeof_failed)
		self.m_state = eScannerState.DONE
	end)
end

---@return eScannerState
function PatternScanner:GetState()
	return self.m_state
end

---@return boolean
function PatternScanner:IsDone()
	return self.m_state == eScannerState.DONE
end

---@return boolean
function PatternScanner:IsBusy()
	return self.m_state == eScannerState.BUSY
end

---@return dict<Pattern>, array<Pattern>
function PatternScanner:ListPointers()
	return self.m_patterns, self.m_failed_patterns
end

return PatternScanner()
