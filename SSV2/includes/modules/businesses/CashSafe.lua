-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class CashSafeOpts
---@field name string
---@field get_max_cash fun(): integer
---@field cash_value_stat string
---@field coords? vec3

-- Class representing a Business Safe that stores cash
---@class CashSafe
---@field private m_name string
---@field private m_max_cash integer
---@field private m_cash_stat string
---@field private m_coords? vec3
local CashSafe   = {}
CashSafe.__index = CashSafe

---@param opts CashSafeOpts
---@return CashSafe
function CashSafe.new(opts)
	assert(type(opts.get_max_cash) == "function", "Missing argument: get_max_cash<function>")
	assert(type(opts.cash_value_stat) == "string", "Missing argument: cash_value_stat<string>")

	local instance = setmetatable({
		m_cash_stat = opts.cash_value_stat,
		m_max_cash  = opts.get_max_cash(),
		m_name      = opts.name or "NULL",
	}, CashSafe)

	if (opts.coords) then
		instance.m_coords = opts.coords
	end

	return instance
end

---@return string
function CashSafe:GetName()
	return self.m_name
end

---@return vec3?
function CashSafe:GetCoords()
	return self.m_coords
end

---@return integer
function CashSafe:GetCashValue()
	assert(type(self.m_cash_stat) == "string", "Invalid player stat.")
	return stats.get_int(self.m_cash_stat)
end

---@return integer
function CashSafe:GetMaxCash()
	return self.m_max_cash
end

---@return boolean
function CashSafe:IsFull()
	-- le because some people like to break their safes and go over the max
	return self.m_max_cash <= self:GetCashValue()
end

return CashSafe
