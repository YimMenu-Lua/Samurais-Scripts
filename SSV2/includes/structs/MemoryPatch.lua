-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-----------------------------------------------------
-- Memory Patch Struct
-----------------------------------------------------
-- Represents a memory patch.
---@class MemoryPatch
---@field protected m_name string
---@field protected m_enabled boolean
---@field private OnEnable fun(patch: MemoryPatch): any
---@field private OnDisable fun(patch: MemoryPatch): any
---@field public m_state any Capture a default state to reset later if needed. *(see `PlayerVehicle:AddMemoryPatch` for default state example)*
local MemoryPatch <const> = {}
MemoryPatch.__index = MemoryPatch
MemoryPatch.__type = "MemoryPatch"

---@param name string
---@param onEnable function
---@param onDisable function
---@return MemoryPatch
function MemoryPatch.new(name, onEnable, onDisable)
	return setmetatable({
		m_name = name,
		m_enabled = false,
		OnEnable = onEnable,
		OnDisable = onDisable
	}, MemoryPatch)
end

---@return boolean
function MemoryPatch:IsEnabled()
	return self.m_enabled
end

---@return boolean
function MemoryPatch:IsDisabled()
	return not self.m_enabled
end

---@generic T
---@return T
function MemoryPatch:Apply()
	if (self.m_enabled) then
		return self.m_state
	end

	local ok, res = xpcall(function()
		self:OnEnable()
	end, function(err)
		log.fwarning("[MemoryPatch]: Failed to apply patch '%s': %s", self.m_name, err)
		return nil
	end)

	if (not ok) then
		return nil
	end

	self.m_enabled = true
	return res
end

---@generic T
---@return T
function MemoryPatch:Restore()
	if (not self.m_enabled) then
		return self.m_state
	end

	local ok, res = xpcall(function()
		self:OnDisable()
	end, function(err)
		log.fwarning("[MemoryPatch]: Failed to restore patch '%s': %s", self.m_name, err)
		return nil
	end)

	if (not ok) then
		return nil
	end

	self.m_enabled = false
	return res
end

function MemoryPatch:OnEnable() end

function MemoryPatch:OnDisable() end

return MemoryPatch
