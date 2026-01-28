-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessBase = require("includes.modules.businesses.BusinessBase")
local BusinessHub  = require("includes.modules.businesses.BusinessHub")

---@class ClubOpts : BusinessOpts
---@field name string
---@field custom_name string
---@field max_cash integer
---@field coords vec3

-- Class representing the Nightclub business.
---@class Nightclub : BusinessBase
---@field private m_id integer
---@field private m_name string
---@field private m_custom_name string
---@field private m_max_cash integer
---@field private m_fast_prod_running boolean
---@field private m_hubs BusinessHub[]
---@field public fast_prod_enabled boolean
local Nightclub    = setmetatable({}, BusinessBase)
Nightclub.__index  = Nightclub

---@param opts ClubOpts
---@return Nightclub
function Nightclub.new(opts)
	assert(type(opts.max_cash) == "number", "Missing argument: max_units<integer>")

	local base                 = BusinessBase.new(opts)
	local instance             = setmetatable(base, Nightclub)
	instance.m_custom_name     = opts.custom_name
	instance.m_max_cash        = opts.max_cash
	instance.fast_prod_enabled = false
	instance.fast_prod_running = false
	instance.m_hubs            = {}
	---@diagnostic disable-next-line
	return instance
end

function Nightclub:Reset()
	self.fast_prod_enabled = false
	self.fast_prod_running = false
end

---@return integer
function Nightclub:GetCashValue()
	return stats.get_int("MPX_CLUB_SAFE_CASH_VALUE")
end

---@return string
function Nightclub:GetCustomName()
	return self.m_custom_name or "The Palace"
end

---@return boolean
function Nightclub:IsFull()
	return self.m_max_cash <= self:GetCashValue()
end

---@return integer
function Nightclub:GetMaxCash()
	return self.m_max_cash or 25e4
end

---@return integer
function Nightclub:GetPopularity()
	return stats.get_int("MPX_CLUB_POPULARITY")
end

---@return integer
function Nightclub:GetEstimatedValue()
	local moola = self:GetCashValue()
	for _, hub in ipairs(self.m_hubs) do
		if (hub and hub:IsValid()) then
			moola = moola + hub:GetEstimatedValue()
		end
	end
	return moola
end

function Nightclub:MaxPopularity()
	if (self:GetPopularity() >= 1e3) then
		return
	end

	stats.set_int("MPX_CLUB_POPULARITY", 1e3)
	Notifier:ShowSuccess(self:GetCustomName(), _T("YRV3_POPULARITY_NOTIF"))
end

function Nightclub:LockPopularityDecay()
	tunables.set_float("NIGHTCLUBPOPDECAY", -1e-8)
	tunables.set_float("INIGHTCLUBPOPDECAYSTAFFUPGRADE", -1e-8)
	self:MaxPopularity()
end

function Nightclub:RestorePopularityDecay()
	tunables.set_float("NIGHTCLUBPOPDECAY", -0.1)
	tunables.set_float("INIGHTCLUBPOPDECAYSTAFFUPGRADE", -0.05)
end

function Nightclub:ToggleBigTips(toggle)
	local val = toggle and 1e6 or 1
	tunables.set_int("BB_NIGHTCLUB_TOILET_ATTENDANT_TIP_COST", val)
end

---@param index integer
---@param reference_table BusinessHubs
function Nightclub:SetupBusinessHub(index, reference_table)
	if (not self:IsValid()) then
		return
	end

	local ref = reference_table[index + 1]
	if (not ref) then
		return
	end

	table.insert(self.m_hubs, BusinessHub.new({
		id        = index,
		name      = ref.name,
		max_units = tunables.get_int(ref.max_units_tunable),
		vpu       = tunables.get_int(ref.vpu_tunable)
	}))
end

---@return array<BusinessHub>
function Nightclub:GetBusinessHubs()
	return self.m_hubs
end

return Nightclub
