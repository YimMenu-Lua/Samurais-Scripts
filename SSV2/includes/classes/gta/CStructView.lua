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
---@field private __type string
---@field private __ptr_ctor true
---@field public new fun(...): T
---@field public IsValid fun(self: T): boolean
---@field public GetPointer fun(self: T): pointer
---@field public GetAddress fun(self: T): uint64_t
---@field __safecall fun(self: T, default: any, func: fun(...): R1, R2?, R3?, R4?, R5?, ...?): R1, R2?, R3?, R4?, R5?, ...?

---@alias ptrstep integer|"deref"
---@alias ptrfunc fun(base: pointer): anyval
---@alias ptrchain integer|ptrstep[]|ptrfunc

---@class CStructLayout
---@field [1] string
---@field [2] ptrchain
---@field [3] (Obj|any)?

-- A helper function that allows us to quickly define game classes while eliminating repetitive code.
--
-- The `layout` parameter is an array of tables defining the class structure:
--
-- 1. **Field name:** string
-- 2. **Offset(s):** Can be an integer (one offset), an array of integers (multiple offsets), an array of integers and strings (instructions), or a function.
-- 3. **Wrapper (Optional):** An object to wrap the pointer in. Example `atArray`.
--
-- **Usage Example:**
--
--```lua
-- local CExample = CStructView("CExample", {
-- 	{ "m_simple_field", 0x10 },
-- 	{ "m_nested_field", { -0x20, "deref", 0x8 } },
-- 	{ "m_array_field",  { 0x28, 0x4, 0x10 }, atArray },
-- 	{ "m_class_field",  { 0x112 }, CPlayerInfo },
-- 	{ "m_simple_field_2", function (basePtr) return basePtr:add(0x0F10):deref() end },
-- }, 0x123)
--```
---@generic T
---@param name string
---@param layout array<CStructLayout>
---@param size? integer Optional sugar, plays nice with `SizeOf`
---@param is_ref_ptr? boolean
---@return CStructBase<T>
local function CStructView(name, layout, size, is_ref_ptr)
	local cls = {
		m_size     = size or GenericClass.m_size,
		__type     = name,
		__ptr_ctor = true
	}

	cls.__index = cls
	---@param ptr pointer
	function cls.new(ptr)
		ptr = ptr or nullptr
		if (is_ref_ptr and ptr:is_valid()) then
			ptr = ptr:deref()
		end

		local instance = setmetatable({ m_ptr = ptr }, cls)
		if (ptr:is_null()) then
			return instance
		end

		for _, field in ipairs(layout) do
			local fieldname = field[1]
			local chain     = field[2]
			local wrapper   = field[3]
			local current   = ptr

			if (type(chain) == "number") then
				current = current:add(chain)
			elseif (type(chain) == "table") then
				for _, step in ipairs(chain) do
					if (type(step) == "number") then
						current = current:add(step)
					elseif (step == "deref") then
						current = current:deref()
					else
						error("Unknown pointer step: " .. tostring(step))
					end
				end
			end

			if (wrapper) then
				current = current:as(wrapper)
			end

			instance[fieldname] = current
		end

		return instance
	end

	setmetatable(cls, {
		__call = function(t, ptr)
			return t.new(ptr)
		end
	})

	---@return boolean
	function cls:IsValid()
		return self.m_ptr and self.m_ptr:is_valid() or false
	end

	---@return pointer
	function cls:GetPointer()
		return self.m_ptr or nullptr
	end

	---@return uint64_t
	function cls:GetAddress()
		return self.m_ptr and self.m_ptr:get_address() or 0x0
	end

	---@private
	---@generic R1, R2, R3, R4, R5
	---@param default any Defaul value to return on failure
	---@param func fun(...): R1, R2?, R3?, R4?, R5?, ... ?
	---@param ... any
	---@return R1, R2?, R3?, R4?, R5?, ... ?
	function cls:__safecall(default, func, ...)
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

	return cls
end

return CStructView
