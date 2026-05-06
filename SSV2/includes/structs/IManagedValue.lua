-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local TypeRefs <const> = {
	[Enums.eManagedValueType.TUNEABLE]    = {
		sol_table = _G.tunables,
		func_suffix = {
			[Enums.eManagedValueDataType.INT]   = "int",
			[Enums.eManagedValueDataType.FLOAT] = "float",
			[Enums.eManagedValueDataType.BOOL]  = "bool",
		}
	},
	[Enums.eManagedValueType.STAT]        = {
		sol_table = _G.stats,
		func_suffix = {
			[Enums.eManagedValueDataType.INT]         = "int",
			[Enums.eManagedValueDataType.FLOAT]       = "float",
			[Enums.eManagedValueDataType.BOOL]        = "bool",
			[Enums.eManagedValueDataType.BOOL_MASKED] = "bool_masked",
		}
	},
	[Enums.eManagedValueType.PACKED_STAT] = {
		sol_table = _G.stats,
		func_suffix = {
			[Enums.eManagedValueDataType.INT]  = "packed_stat_int",
			[Enums.eManagedValueDataType.BOOL] = "packed_stat_bool",
		}
	},
}


---@generic T : integer|float|boolean
---@class IManagedValue<T>
---@field protected m_name string must be unique
---@field protected m_id joaat_t|string tuneable/stat name or joaat hash
---@field protected m_managed_type eManagedValueType
---@field protected m_data_type eManagedValueDataType
---@field protected m_default_val? T
---@field protected m_desired_val T
---@field private m_modified boolean
---@field private __get fun(t: joaat_t|string): T
---@field private __set fun(t: joaat_t|string, v: T)
local IManagedValue <const> = {}
IManagedValue.__index       = IManagedValue

---@generic ID : joaat_t|string
---@param name string must be unique
---@param identifier joaat_t|string tuneable/stat name or joaat hash
---@param valueType eManagedValueType
---@param dataType eManagedValueDataType
---@param desired_val integer|float|boolean
---@return IManagedValue<T>
---@overload fun(name: string, identifier: ID, valueType: eManagedValueType, dataType: 1, desired_val: integer): IManagedValue<integer>
---@overload fun(name: string, identifier: ID, valueType: eManagedValueType, dataType: 2, desired_val: float): IManagedValue<float>
---@overload fun(name: string, identifier: ID, valueType: eManagedValueType, dataType: 3, desired_val: boolean): IManagedValue<boolean>
---@overload fun(name: string, identifier: ID, valueType: 2, dataType: 4, desired_val: boolean): IManagedValue<boolean>
function IManagedValue.new(name, identifier, valueType, dataType, desired_val)
	local ref = TypeRefs[valueType]
	assert(ref ~= nil, "Unknown type reference.")

	local sol_table = ref.sol_table
	local suffix    = ref.func_suffix[dataType]
	local get_name  = "get_" .. suffix
	local set_name  = "set_" .. suffix
	local get_func  = sol_table[get_name]
	local set_func  = sol_table[set_name]
	if (type(get_func) ~= "function" or type(set_func) ~= "function") then
		error(_F(
			"No suitable getters/setters for ManagedValue with type: %s and of data type: %s",
			EnumToString(Enums.eManagedValueType, valueType),
			EnumToString(Enums.eManagedValueDataType, dataType))
		)
	end

	local instance = setmetatable({
		m_name         = name,
		m_id           = identifier,
		m_managed_type = valueType,
		m_data_type    = dataType,
		m_desired_val  = desired_val,
		m_modified     = false,
		__get          = get_func,
		__set          = set_func
	}, IManagedValue)


	local __clear__ = function() instance:Clear() end
	Backend:RegisterEventCallback(Enums.eBackendEvent.RELOAD_UNLOAD, __clear__)
	Backend:RegisterEventCallback(Enums.eBackendEvent.SESSION_SWITCH, __clear__)

	instance:SaveDefaultValue()
	return instance
end

---@protected
---@nodiscard
---@return boolean
function IManagedValue:CanAccess()
	return Game.IsOnline()
end

---@nodiscard
---@return boolean
function IManagedValue:IsReady()
	return self.m_default_val ~= nil
end

---@nodiscard
---@return boolean
function IManagedValue:NeedsUpdate()
	return self:GetValue() ~= self.m_desired_val
end

function IManagedValue:SaveDefaultValue()
	if (not self:CanAccess()) then return end

	local default      = self.__get(self.m_id)
	self.m_default_val = default
end

---@nodiscard
---@return T
function IManagedValue:GetDefaultValue()
	if (not self.m_default_val) then
		self:SaveDefaultValue()
	end

	return self.m_default_val
end

---@nodiscard
---@return string
function IManagedValue:GetName()
	return self.m_name
end

---@return T
function IManagedValue:GetValue()
	return self.__get(self.m_id)
end

---@nodiscard
---@return boolean
function IManagedValue:Apply()
	if (not self:IsReady()) then
		self:SaveDefaultValue()
		return false
	end

	self.__set(self.m_id, self.m_desired_val)
	self.m_modified = true
	return true
end

function IManagedValue:Reset()
	if not (self.m_default_val and self.m_modified) then
		return
	end

	self.__set(self.m_id, self.m_default_val)
	self.m_modified = false
end

function IManagedValue:RebaseDefault()
	if (self:CanAccess()) then
		self.m_default_val = self:GetValue()
	end
end

---@param v T
function IManagedValue:SetDesiredValue(v)
	self.m_desired_val = v
	self.m_modified    = false
end

function IManagedValue:Clear()
	self:Reset()
	self.m_default_val = nil
	self.m_modified    = false
end

return IManagedValue
