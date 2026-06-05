-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@generic T
---@generic R1, R2, R3, R4, R5
---@class CStructBase<T>
---@field protected m_ptr pointer
---@field private m_size integer
---@field private __ptr_ctor true
---@field public __type string
---@field public new fun(...): T
---@field public IsValid fun(self: T): boolean
---@field public GetPointer fun(self: T): pointer
---@field public GetAddress fun(self: T): uint64_t
---@field __safecall fun(self: T, default: any, func: fun(...?): R1, R2?, R3?, R4?, R5?, ...?): R1, R2?, R3?, R4?, R5?, ...?

---@diagnostic disable: invisible

---@param self CStructBase
local function is_valid(self)
	return self.m_ptr and self.m_ptr:is_valid() or false
end

---@param self CStructBase
local function get_pointer(self)
	return self.m_ptr or nullptr
end

---@param self CStructBase
local function get_address(self)
	return self.m_ptr and self.m_ptr:get_address() or 0x0
end

---@generic R1, R2, R3, R4, R5
---@param self CStructBase
---@param default any Defaul value to return on failure
---@param func fun(...): R1, R2?, R3?, R4?, R5?, ... ?
---@param ... any
---@return R1, R2?, R3?, R4?, R5?, ... ?
local function safe_call(self, default, func, ...)
	if (not self:IsValid()) then
		return default
	end

	local results = { pcall(func, ...) }
	local ok      = results[1]
	local err     = results[2]

	if (not ok) then
		log.fwarning("Safecall failed in %s: %s", self.__type, err)
		return default
	end

	table.remove(results, 1)
	return table.unpack(results)
end

---@diagnostic enable: invisible

-- Creates a basic GTA class definition with default methods.
---@generic T
---@param name string
---@param size? integer Optional sugar, plays nice with `SizeOf`
---@return CStructBase<T>
return function(name, size)
	return Callable(name, {
		ctor     = function(t, ptr) return t.new(ptr) end,
		ptr_ctor = true,
		t_data   = {
			m_size     = size or GenericClass.m_size,
			IsValid    = is_valid,
			GetPointer = get_pointer,
			GetAddress = get_address,
			__safecall = safe_call
		},
	})
end
