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
---@field private __get fun(t: joaat_t|string): T
---@field private __set fun(t: joaat_t|string, v: T): nil
local IManagedTuneable <const> = setmetatable({}, IManagedValue)
IManagedTuneable.__index       = IManagedTuneable

---@generic V : integer|float|boolean
---@generic ID : joaat_t|string
---@param name string must be unique
---@param tuneable ID tuneable name or joaat hash
---@param dataType eManagedValueDataType
---@param desired_val V
---@overload fun(name: string, identifier: ID, dataType: 0, desired_val: V): IManagedTuneable<integer>
---@overload fun(name: string, identifier: ID, dataType: 1, desired_val: V): IManagedTuneable<float>
---@overload fun(name: string, identifier: ID, dataType: 2, desired_val: V): IManagedTuneable<boolean>
---@return IManagedTuneable<T>
function IManagedTuneable.new(name, tuneable, dataType, desired_val)
	local base     = IManagedValue.new(name, tuneable, Enums.eManagedValueType.TUNEABLE, dataType, desired_val)
	local instance = setmetatable(base, IManagedTuneable) ---@cast instance IManagedTuneable

	if (script.is_active("tuneables_processing")) then
		instance:SaveDefaultValue()
	end

	return instance
end

return IManagedTuneable
