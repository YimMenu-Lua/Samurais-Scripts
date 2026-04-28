-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local __base_fields__ <const> = {
	x = 0x0,
	y = 0x4,
	z = 0x8
}

--------------------------------------
-- Class: fVector3
--------------------------------------
-- A zero allocation pointer backed vector3 view.
--
-- This has no math or geometric methods, it's a simple memory view
--
-- but can be cast to a vec3 object using the `as_vec3` method.
---@class fVector3
---@field protected m_ptr pointer
---@field public x float
---@field public y float
---@field public z float
---@field public new fun(ptr: pointer): fVector3 -- static
---@field public as_vec3 fun(self: fVector3): vec3 -- method
---@overload fun(ptr: pointer): fVector3
local fVector3 <const> = setmetatable({}, {
	__type     = "fVector3",
	__ptr_ctor = true,
	__call     = function(t, ...)
		return t.new(...)
	end
})

---@private
function fVector3:__index(key)
	local ptr = rawget(self, "m_ptr")
	assert(ptr ~= nil, "pointer is nil!")

	local offset = __base_fields__[key]
	if (offset) then
		return ptr:add(offset):get_float()
	end

	if (key == "as_vec3") then
		return function()
			return vec3:new(
				ptr:add(0x0):get_float(),
				ptr:add(0x4):get_float(),
				ptr:add(0x8):get_float()
			)
		end
	end

	---@diagnostic disable-next-line: param-type-mismatch
	return rawget(fVector3, key)
end

---@private
function fVector3:__newindex(key, value)
	local offset = __base_fields__[key]
	if (not offset) then
		rawset(self, key, value)
		return
	end

	local ptr = rawget(self, "m_ptr")
	assert(ptr ~= nil, "pointer is nil!")
	if (not ptr:is_valid()) then return end
	ptr:add(offset):set_float(value)
end

---@param ptr pointer
---@return fVector3
function fVector3.new(ptr)
	---@diagnostic disable-next-line: param-type-mismatch
	return setmetatable({ m_ptr = ptr }, fVector3)
end

return fVector3
