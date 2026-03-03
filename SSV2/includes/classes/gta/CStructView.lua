---@generic T
---@class CStructBase<T>
---@field protected m_ptr pointer
---@field private m_size integer
---@field private __type string
---@field private __safecall fun(self: T, default: any, func: fun(...): ...): ...
---@field new fun(...): T
---@field IsValid fun(self: T): boolean
---@field GetPointer fun(self: T): pointer
---@field GetAddress fun(self: T): uint64_t

---@alias ptrstep integer|"deref"
---@alias ptrfunc fun(base: pointer): anyval
---@alias ptrchain integer|ptrstep[]|ptrfunc

---@class CStructLayout
---@field [1] string
---@field [2] ptrchain
---@field [3] Obj|any?

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
		m_size = size or GenericClass.m_size,
		__type = name
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
				instance[fieldname] = wrapper(current)
			else
				instance[fieldname] = current
			end
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
		return self.m_ptr and self.m_ptr:is_valid()
	end

	---@return pointer
	function cls:GetPointer()
		return self.m_ptr or nullptr
	end

	---@return uint64_t
	function cls:GetAddress()
		return self.m_ptr and self.m_ptr:get_address() or 0x0
	end

	---@param default any Defaul value to return on failure
	---@param func fun(...): ...
	---@param ... any
	---@return ...
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
