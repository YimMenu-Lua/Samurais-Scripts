-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class BasicBusinessOpts : table<string, string>
---@field name string
---@field coords vec3
---@field generic_val_get_func? fun(): any
---@field generic_val_set_func? function

---@class BasicBusiness
---@field private m_name string
---@field private m_coords vec3
---@field private m_generic_val_get_func fun(): anyval
---@field private m_generic_val_set_func function
---@field protected m_is_stale boolean
local BasicBusiness = {}
BasicBusiness.__index = BasicBusiness

---@param opts BasicBusinessOpts
function BasicBusiness.new(opts)
	return setmetatable({
		m_name                 = opts.name,
		m_coords               = opts.coords,
		m_generic_val_get_func = opts.generic_val_get_func or NOP,
		generic_val_set_func   = opts.generic_val_set_func or NOP,
		m_is_stale             = false,
	}, BasicBusiness)
end

---@return boolean
function BasicBusiness:IsValid()
	return not self.m_is_stale
end

---@return string
function BasicBusiness:GetName()
	return self.m_name
end

---@return vec3
function BasicBusiness:GetCoords()
	return self.m_coords
end

function BasicBusiness:GetGenericValue()
	return self.m_generic_val_get_func()
end

function BasicBusiness:SetGenericValue()
	self.m_generic_val_set_func()
end

return BasicBusiness
