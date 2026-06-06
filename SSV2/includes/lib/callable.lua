-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class Callable<T>
---@field public __name string
---@field public __type string
---@overload fun(...) : Callable<T>

---@class CallableParams<T>
---@field t_data? table Optional default data
---@field ctor? fun(t, ...): Callable<T> Optional constructor definition. If not provided, __call will try to find either a `.new` static function or an `:init` method and use it; otherwise it will return a simple metatable.
---@field ptr_ctor? boolean Whether this callable's constructor takes a pointer parameter *(used in `memory.pointer:as(obj)`)*.

-- Creates a basic callable object. Use this instead of `Class` if you don't need a heavy object.
---@generic T
---@param name string
---@param args? CallableParams
---@return Callable<T>
function Callable(name, args)
	args           = args or {}
	local ctor     = args.ctor
	local obj      = args.t_data or {}
	obj.__name     = name
	obj.__type     = name
	obj.__ptr_ctor = args.ptr_ctor
	obj.__index    = obj

	if (type(ctor) == "function") then
		return setmetatable(obj, { __call = ctor })
	end

	return setmetatable(obj, {
		__call = function(t, ...)
			if (t.new) then -- static function
				return t.new(...)
			end

			if (t.init) then -- method
				return t:init(...)
			end

			return setmetatable({}, t)
		end
	})
end

-- A `setmetatable` abstraction to avoid param-type-mismatch warnings.
---@generic T
---@param t T
---@param base T
---@return T
function MakeInstance(t, base)
	---@diagnostic disable-next-line
	return setmetatable(t, base)
end
