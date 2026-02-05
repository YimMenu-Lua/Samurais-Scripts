-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessBase    = require("includes.modules.businesses.BusinessBase")
local CashSafe        = require("includes.modules.businesses.CashSafe")

---@class BusinessFrontOpts : BusinessOpts
---@field id integer
---@field name string
---@field safe_data CashSafeOpts
---@field coords vec3

-- Class representing a Business Front.
--
-- Can be: Nightclub or MC clubhouse
---@class BusinessFront : BusinessBase
---@field private m_id integer
---@field private m_name string
---@field private m_safe CashSafe
---@field private m_subs Factory[]|BusinessHub[]
local BusinessFront   = setmetatable({}, BusinessBase)
BusinessFront.__index = BusinessFront

---@param opts BusinessFrontOpts
---@return BusinessFront
function BusinessFront.new(opts)
	assert(type(opts.id) == "number", "Missing argument: id<integer>")
	assert(type(opts.name) == "string", "Missing argument: name<string>")
	assert(type(opts.safe_data) == "table", "Missing argument: safe_data<CashSafeOpts>")
	-- assert(IsInstance(opts.coords, vec3), "Missing argument: coords<vec3>") -- not necessary. UI does not render a tp button if this is missing and LuaLS will warn as well

	local base      = BusinessBase.new(opts)
	local instance  = setmetatable(base, BusinessFront)
	instance.m_subs = {}
	instance.m_safe = CashSafe.new(opts.safe_data)

	---@diagnostic disable-next-line
	return instance
end

function BusinessFront:Reset() end

---@param index integer
function BusinessFront:AddSubBusiness(index) end

---@return CashSafe
function BusinessFront:GetCashSafe() return self.m_safe end

---@return array<Factory>|array<BusinessHub>
function BusinessFront:GetSubBusinesses() return self.m_subs end

---@return boolean
function BusinessFront:HasSubBusinesses()
	return self.m_subs and #self.m_subs > 0
end

---@return integer
function BusinessFront:GetEstimatedIncome()
	local moola = self.m_safe and self.m_safe:GetCashValue() or 0
	for _, sub in ipairs(self.m_subs) do
		moola = moola + sub:GetEstimatedIncome()
	end
	return moola
end

function BusinessFront:Update()
	if (not self:IsValid()) then
		return
	end

	if (self:HasSubBusinesses()) then
		for _, sub in ipairs(self.m_subs) do
			sub:Update()
		end
	end

	if (self.m_safe and self.m_safe:CanLoop()) then
		self.m_safe:Update()
	end
end

return BusinessFront
