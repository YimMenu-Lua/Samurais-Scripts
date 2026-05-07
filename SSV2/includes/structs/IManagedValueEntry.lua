-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local ManagedStat     = require("includes.structs.IManagedStat")
local ManagedTuneable = require("includes.structs.IManagedTuneable")
local TypeRes <const> = {
	integer = Enums.eManagedValueDataType.INT,
	float   = Enums.eManagedValueDataType.FLOAT,
}
local ObjRes <const>  = {
	[Enums.eManagedValueType.TUNEABLE] = ManagedTuneable,
	[Enums.eManagedValueType.STAT]     = ManagedStat,
}


---@generic T : integer|float|boolean
---@class IManagedValueEntry<T>
---@field private m_name string
---@field private m_data array<{ object: IManagedValue<T>, desired_val: T }>
---@field private m_dirty boolean
---@field private GetCheckboxState fun(): boolean
local IManagedValueEntry <const> = {}
IManagedValueEntry.__index       = IManagedValueEntry

---@param name string
---@param data_t IManagedValueCtorData
---@return IManagedValueEntry
function IManagedValueEntry.new(name, data_t)
	local data = {}
	for i, entry in ipairs(data_t.defs) do
		local value    = entry.v
		local dataType = entry.data_type
		if (not dataType) then
			local lua_type = type(value)
			if (lua_type == "boolean") then
				dataType = Enums.eManagedValueDataType.BOOL
			elseif (lua_type == "number") then
				dataType = TypeRes[math.type(value)]
			end
			assert(dataType ~= nil, "Unsupported value type! Param #2 must be integer, float, or boolean.")
		end

		local objType = entry.obj_type
		local Object  = ObjRes[objType]
		assert(Object ~= nil,
			_F("Missing or invalid object type! Expected 1 (tuneable), 2 (stat), or 3 (packed stat), got %s instead", objType)
		)

		local objName      = _F("%s_%d", name, i)
		local managedValue = Object.new(objName, entry.t, dataType, entry.v)
		table.insert(data, { object = managedValue, desired_val = value })
	end

	local instance = setmetatable({
		m_name           = name,
		m_data           = data,
		m_dirty          = true,
		GetCheckboxState = data_t.get_state
	}, IManagedValueEntry)

	Backend:RegisterEventCallback(Enums.eBackendEvent.SESSION_SWITCH, function()
		instance:SetDirty(true)
	end)

	return instance
end

---@nodiscard
---@return boolean
function IManagedValueEntry:IsDirty()
	return self.m_dirty
end

---@param state boolean
function IManagedValueEntry:SetDirty(state)
	self.m_dirty = state
end

---@nodiscard
---@return boolean
function IManagedValueEntry:Apply()
	local success = true
	for _, entry in ipairs(self.m_data) do
		if (not entry.object:Apply()) then
			success = false
		end
	end

	return success
end

function IManagedValueEntry:Reset()
	for _, entry in ipairs(self.m_data) do
		entry.object:Reset()
	end
end

---@param force? boolean
function IManagedValueEntry:OnCall(force)
	if (not self.m_dirty) then
		if (not force) then return end
	end

	local state = self:GetCheckboxState()
	if (not state) then
		self:Reset()
	elseif (not self:Apply()) then
		return
	end

	self.m_dirty = false
end

return IManagedValueEntry
