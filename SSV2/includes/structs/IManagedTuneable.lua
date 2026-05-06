-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local IManagedValue = require("includes.structs.IManagedValue")


---@generic T : integer|float|boolean
---@class IManagedTuneable<T> : IManagedValue
---@field protected m_name string must be unique
---@field protected m_id joaat_t|string tuneable name or joaat hash
---@field protected m_type eManagedValueDataType
---@field protected m_default_val? T
---@field protected m_modified boolean
---@field private __get fun(): T
---@field private __set fun(v: T): nil
local IManagedTuneable <const> = setmetatable({}, IManagedValue)
IManagedTuneable.__index       = IManagedTuneable

---@generic ID : joaat_t|string
---@param name string must be unique
---@param tuneable ID tuneable name or joaat hash
---@param dataType eManagedValueDataType
---@param desired_val integer|float|boolean
---@return IManagedTuneable<T>
---@overload fun(name: string, identifier: ID, dataType: 1, desired_val: integer): IManagedTuneable<integer>
---@overload fun(name: string, identifier: ID, dataType: 2, desired_val: float): IManagedTuneable<float>
---@overload fun(name: string, identifier: ID, dataType: 3, desired_val: boolean): IManagedTuneable<boolean>
---@overload fun(name: string, identifier: ID, dataType: 4, desired_val: boolean): IManagedTuneable<boolean>
function IManagedTuneable.new(name, tuneable, dataType, desired_val)
	local base = IManagedValue.new(name, tuneable, Enums.eManagedValueType.TUNEABLE, dataType, desired_val)
	return setmetatable(base, IManagedTuneable)
end

return IManagedTuneable
