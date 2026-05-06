-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local IManagedValue = require("includes.structs.IManagedValue")


---@generic T : integer|float|boolean
---@class IManagedStat<T> : IManagedValue
---@field protected m_name string must be unique
---@field protected m_id joaat_t|string tuneable name or joaat hash
---@field protected m_type eManagedValueDataType
---@field protected m_default_val? T
---@field protected m_bit_index? integer
---@field protected m_modified boolean
---@field private __get fun(): T
---@field private __set fun(v: T): nil
local IManagedStat <const> = setmetatable({}, IManagedValue)
IManagedStat.__index       = IManagedStat

---@generic ID : joaat_t|string
---@param name string must be unique
---@param stat ID stat name or joaat hash
---@param dataType eManagedValueDataType
---@param desired_val integer|float|boolean
---@param packed? boolean
---@param bit_index? integer only for masked stats
---@return IManagedStat<T>
---@overload fun(name: string, identifier: ID, dataType: 1, desired_val: integer, packed?: boolean): IManagedStat<integer>
---@overload fun(name: string, identifier: ID, dataType: 2, desired_val: float, packed?: boolean): IManagedStat<float>
---@overload fun(name: string, identifier: ID, dataType: 3, desired_val: boolean, packed?: boolean): IManagedStat<boolean>
---@overload fun(name: string, identifier: ID, dataType: 4, desired_val: boolean, packed: false, bit_index: integer): IManagedStat<boolean>
function IManagedStat.new(name, stat, dataType, desired_val, packed, bit_index)
	if (dataType == Enums.eManagedValueDataType.BOOL_MASKED and bit_index ~= nil) then
		packed = false
	end

	local statType = packed and Enums.eManagedValueType.PACKED_STAT or Enums.eManagedValueType.STAT
	local base     = IManagedValue.new(name, stat, statType, dataType, desired_val, bit_index)
	return setmetatable(base, IManagedStat)
end

return IManagedStat
