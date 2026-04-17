-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


--#region SGSL structs

-----------------------------------------------------
-- SGSLTable
-----------------------------------------------------
-- Represents each table in the globals_locals table.
---@class SGSLTable
---@field description string
---@field file string
---@field LEGACY SGSLEntry
---@field ENHANCED SGSLEntry

-----------------------------------------------------
-- SGSLEntry
-----------------------------------------------------
-- Represents an entry in SGSLTable, in other words, the LEGACY/ENHANCED field
--
-- that contains the actual data.
---@class SGSLEntry
---@field value number
---@field pattern string
---@field capture_group number
---@field bit_index number
---@field offsets array<{ value: number, capture_group: number, description?: string }>
---@field script_name string
local SGSLEntry   = {}
SGSLEntry.__index = SGSLEntry

---@param value number
---@param offsets array<{ value: number, capture_group: number, description?: string }>
---@param script_name string
---@param pattern? string
---@param capture_group? number
---@param bit_index? number
---@return SGSLEntry
function SGSLEntry.new(value, offsets, script_name, pattern, capture_group, bit_index)
	return setmetatable({
		value         = value,
		offsets       = offsets,
		script_name   = script_name,
		pattern       = pattern,
		capture_group = capture_group,
		bit_index     = bit_index
	}, SGSLEntry)
end

---@return number
function SGSLEntry:GetValue()
	assert(type(self.value) == "number", "Invalid value.")
	return self.value
end

---@param index number
---@return number
function SGSLEntry:GetOffset(index)
	local _t = self.offsets[index]
	if (not _t) then
		error("Script Globals/Locals: offset index out of bounds.")
	end

	assert(type(_t.value) == "number", "Invalid value.")
	return _t.value
end

-- ---@generic T : ScriptGlobal | ScriptLocal
-- ---@param accessor T
-- ---@return T
-- function SGSLEntry:As(accessor)
-- 	---@diagnostic disable-next-line
-- 	if (accessor:GetType() == eAccessorType.GLOBAL) then
-- 		return ScriptGlobal(self.value)
-- 	else
-- 		return ScriptLocal(self.value, self.script_name)
-- 	end
-- end

--prefer explicit methods to keep me from punching a hole in my monitor

-- Wraps the value in a `ScriptGlobal` object.
---@return ScriptGlobal
function SGSLEntry:AsGlobal()
	return ScriptGlobal(self.value)
end

-- Wraps the value in a `ScriptLocal` object.
---@return ScriptLocal
function SGSLEntry:AsLocal()
	return ScriptLocal(self.value, self.script_name)
end

--#endregion

--#region SGSL

-----------------------------------------------------
-- SGSL
-----------------------------------------------------
-- Fetches script globals, locals, and their offsets.
--
-- Provides methods to wrap globals/locals in an `Accessor` object instance *(ScriptGlobal/ScriptLocal)*.
--
-- **NOTE:** The `Get` method throws on error. If you're not sure if it will succeed, wrap it in a protected call.
--___
-- **Usage Example:**
--
--```Lua
--[[
if (ImGui.Button("Write value at offset")) then
	local obj 	 = SGSL:Get(SGSL.data.fm_mission_controller_cart_grab) -- returns an SGSLEntry struct
	local FMMCCG = obj:AsGlobal() -- Wrap in a ScriptGlobal instance.
	local offset = obj:GetOffset(1) -- Get first offset in the struct.
	FMMCCG:At(offset):WriteFloat(0.123) -- Write data using the ScriptGlobal accessor.
end
]]
--```
---@class SGSL
---@field private m_branch_key "LEGACY" | "ENHANCED"
---@field private m_cache table<SGSLTable, SGSLEntry>
local SGSL = {
	data         = require("includes.data.globals_locals"),
	m_branch_key = Backend:GetGameBranch() == Enums.eGameBranch.LAGECY and "LEGACY" or "ENHANCED",
	m_cache      = {}
}
SGSL.__index = SGSL

-- This method throws on error. If you're not sure if it will succeed, wrap it in a protected call.
---@param object SGSLTable
function SGSL:Get(object)
	local cached = self.m_cache[object]
	if (cached) then return cached end

	local objType = type(object)
	assert(objType == "table", _F("Invalid object type. Table expected, got %s instead.", objType))

	---@type SGSLEntry?
	local entry = object[self.m_branch_key]
	if (not entry) then
		error("Failed to find a script global/script local entry!")
	end

	local outEntry = SGSLEntry.new(
		entry.value,
		entry.offsets,
		object.file:trim():replace(".c", ""),
		-- fields below are unnecessary but I'm adding them for debugging purposes
		entry.pattern,
		entry.capture_group,
		entry.bit_index
	)

	self.m_cache[object] = outEntry
	return outEntry
end

--#endregion

return SGSL
