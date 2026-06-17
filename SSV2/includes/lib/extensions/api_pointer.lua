-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@diagnostic disable: lowercase-global

local Range = require("includes.classes.Range")

do
	---@class nullptr : pointer
	local nullptr <const>     = { __type = "nullptr" }
	local NOP <const>         = function() end -- there's also a global no-op function but it gets defined after we load this file.
	local RET_ZERO <const>    = function() return 0 end
	local RET_STR <const>     = function() return "" end
	local RET_NULLPTR <const> = function() return nullptr end
	local RET_TRUE <const>    = function() return true end
	local RET_FALSE <const>   = function() return false end
	local THROW <const>       = function() error("Attempt to dereference a null pointer!", 2) end
	local CONST_THROW <const> = function() error("Attempt to modify nullptr!", 2) end
	local TOSTRING <const>    = function() return "nullptr" end
	local __null_idx <const>  = {
		is_valid    = RET_FALSE,
		is_null     = RET_TRUE,
		get_address = RET_ZERO,
		set_address = NOP,
		deref       = THROW,
		rip         = RET_NULLPTR,
		add         = RET_NULLPTR,
		sub         = RET_NULLPTR,
		new         = RET_NULLPTR,
	}


	local sol_ptr_mt = getmetatable(memory.pointer)
	if (sol_ptr_mt) then
		for k, v in pairs(sol_ptr_mt) do
			if (type(k) ~= "string" or __null_idx[k] or type(v) ~= "function") then
				goto continue
			end

			local sub = k:sub(1, 3)
			if (sub == "set") then
				__null_idx[k] = NOP
			elseif (sub == "get") then
				__null_idx[k] = (k == "get_string") and RET_STR or RET_ZERO
			else
				__null_idx[k] = v
			end

			::continue::
		end
	end

	local __null_mt <const> = {
		__index     = __null_idx,
		__newindex  = CONST_THROW,
		__tostring  = TOSTRING,
		__metatable = false
	}; setmetatable(nullptr, __null_mt); _G.nullptr = nullptr
end

local fMatrix44      = require("includes.classes.gta.fMatrix44")
local newptr <const> = memory.pointer.new

---@return pointer
function memory.pointer:new(addr)
	if (addr == 0) then return nullptr end
	return newptr(self, addr)
end

-- Wrapper around `memory.allocate` that registers the allocated
--
-- pointer in `Backend` to guarantee all allocations are freed on cleanup.
---@param size integer
function malloc(size)
	local ptr = memory.allocate(size)
	Backend.AllocatedPointers[ptr:get_address()] = ptr
	return ptr
end

---@param ptr pointer
function free(ptr)
	Backend.AllocatedPointers[ptr:get_address()] = nil
	memory.free(ptr)
end

-- Equality comparator for pointer objects.
---@type Comparator<pointer, pointer>
function memory.pointer:__eq(right)
	return self:get_address() == right:get_address()
end

-- Allows pointer to number, pointer, and nullptr equality comparisions.
--
-- **Note:** When comparing with a number, the return will indicate whether the pointer's address equals `v`.
---@param v pointer|nullptr|number
---@return boolean
function memory.pointer:is_equal(v)
	if (v == self) then
		return true
	end

	if (type(v) == "number") then
		return self:get_address() == v
	end

	if (not IsInstance(v, "pointer")) then
		return false
	end

	return self:get_address() == v:get_address()
end

-- Casts the pointer to an object.
--
-- **IMPORTANT:** You must only cast to objects that take a pointer parameter in their constructors otherwise this method will throw.
--
-- **Example Usage:**
--```lua
--print(memory.handle_to_ptr(self.get_ped()):add(0x10B8):as(CPedWeaponManager))
--```
---@generic T
---@param obj T
---@return T
function memory.pointer:as(obj)
	if (self:is_null()) then
		error("Attempt to cast a null pointer")
	end

	local param_type = type(obj)
	if (param_type ~= "table") then
		error(_F("Invalid parameter #1: Expected class, got %s instead.", param_type))
	end

	local obj_name = obj.__type or obj.__name or tostring(obj)
	if (not obj.__ptr_ctor) then
		error(_F("Class '%s' constructor does not expect a pointer.", obj_name))
	end

	if (type(obj.new) == "function") then
		return obj.new(self)
	end

	if (type(obj.init) == "function") then
		return obj:init(self)
	end

	local __mt = getmetatable(obj)
	local call = __mt and __mt.__call or nil
	if (type(call) == "function") then
		return call(obj, self)
	end

	error(_F("Class '%s' has no valid pointer constructor", obj_name))
end

-- Writes a fixed-length string at the address.
---@param str string
---@param max_len integer
function memory.pointer:set_fixed_string(str, max_len)
	str = str:sub(1, max_len - 1)
	local len = #str
	for i = 1, len do
		self:add(i - 1):set_byte(str:byte(i))
	end
	self:add(len):set_byte(0)
	for i = len + 1, max_len - 1 do
		self:add(i):set_byte(0)
	end
end

-- Retrieves a 32-bit displacement value from the memory address, optionally adding an offset and adjustment.
--
-- **Example Usage:**
-- ```lua
-- displacement = pointer:get_disp32(offset, adjust)
-- ```
---@param offset? integer
---@param adjust? integer
---@return number -- imm32 displacement
function memory.pointer:get_disp32(offset, adjust)
	if (self:is_null()) then
		log.warning("Attempt to get imm32 displacement from a null pointer!")
		return 0
	end

	offset = offset or 0
	adjust = adjust or 0
	return self:add(offset):get_int() + adjust
end

---@return vec3
function memory.pointer:get_vec3()
	if (self:is_null()) then
		return vec3:zero()
	end

	return vec3:new(
		self:add(0x0):get_float(),
		self:add(0x4):get_float(),
		self:add(0x8):get_float()
	)
end

---@param vector3 vec3
function memory.pointer:set_vec3(vector3)
	if (self:is_null()) then return end

	self:add(0x0):set_float(vector3.x)
	self:add(0x4):set_float(vector3.y)
	self:add(0x8):set_float(vector3.z)
end

---@return vec4
function memory.pointer:get_vec4()
	if (self:is_null()) then
		return vec4:zero()
	end

	return vec4:new(
		self:add(0x0):get_float(),
		self:add(0x4):get_float(),
		self:add(0x8):get_float(),
		self:add(0xC):get_float()
	)
end

---@param vector4 vec4
function memory.pointer:set_vec4(vector4)
	if (self:is_null()) then
		return
	end

	self:add(0x0):set_float(vector4.x)
	self:add(0x4):set_float(vector4.y)
	self:add(0x8):set_float(vector4.z)
	self:add(0xC):set_float(vector4.w)
end

---@return fMatrix44
function memory.pointer:get_matrix44()
	if (self:is_null()) then
		return fMatrix44:zero()
	end

	return fMatrix44:new(
		self:add(0x00):get_float(), self:add(0x04):get_float(), self:add(0x08):get_float(), self:add(0x0C):get_float(),
		self:add(0x10):get_float(), self:add(0x14):get_float(), self:add(0x18):get_float(), self:add(0x1C):get_float(),
		self:add(0x20):get_float(), self:add(0x24):get_float(), self:add(0x28):get_float(), self:add(0x2C):get_float(),
		self:add(0x30):get_float(), self:add(0x34):get_float(), self:add(0x38):get_float(), self:add(0x3C):get_float()
	)
end

---@param matrix fMatrix44
function memory.pointer:set_matrix44(matrix)
	if (self:is_null()) then
		return
	end

	local m1 = matrix:R1()
	local m2 = matrix:R2()
	local m3 = matrix:R3()
	local m4 = matrix:R4()

	self:add(0x00):set_float(m1.x); self:add(0x04):set_float(m1.y); self:add(0x08):set_float(m1.z); self:add(0x0C):set_float(m1.w)
	self:add(0x10):set_float(m2.x); self:add(0x14):set_float(m2.y); self:add(0x18):set_float(m2.z); self:add(0x1C):set_float(m2.w)
	self:add(0x20):set_float(m3.x); self:add(0x24):set_float(m3.y); self:add(0x28):set_float(m3.z); self:add(0x2C):set_float(m3.w)
	self:add(0x30):set_float(m4.x); self:add(0x34):set_float(m4.y); self:add(0x38):set_float(m4.z); self:add(0x3C):set_float(m4.w)
end

---@param size? number bytes
function memory.pointer:dump(size)
	if (self:is_null()) then
		log.debug("Memory Dump<nullptr>")
		return
	end

	local result = {}
	size         = size or 0x10
	for i = 0, size - 1 do
		table.insert(result, _F("%02X", self:add(i):get_byte()))
	end

	log.fdebug(
		"Memory Dump<0x%X + 0x%X>: %s",
		self:get_address(),
		size,
		table.concat(result, " ")
	)
end

---@param size? number bytes
function memory.pointer:create_pattern(size)
	if (self:is_null()) then return "" end

	size               = size or 0x10
	local out          = {}
	local direct_range = Range(0xC0, 0x100)

	for i = 0, size - 1 do
		local byte = self:add(i):get_byte()
		out[#out + 1] = direct_range:Contains(byte) and "??" or _F("%02X", byte)
	end

	return table.concat(out, " ")
end
