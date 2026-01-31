-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessFront   = require("includes.modules.businesses.BusinessFront")
local BusinessHub     = require("includes.modules.businesses.BusinessHub")
local RawBusinessData = require("includes.data.yrv3_data")

---@class ClubOpts : BusinessFrontOpts
---@field custom_name string

-- Class representing the Nightclub business.
---@class Nightclub : BusinessFront
---@field private m_id integer
---@field private m_name string
---@field private m_custom_name string
---@field private m_safe CashSafe
---@field private m_subs BusinessHub[]
---@field public GetSubBusinesses fun(self: Nightclub): BusinessHub[]
local Nightclub       = setmetatable({}, BusinessFront)
Nightclub.__index     = Nightclub

---@param opts ClubOpts
---@return Nightclub
function Nightclub.new(opts)
	local base             = BusinessFront.new(opts)
	local instance         = setmetatable(base, Nightclub)
	instance.m_custom_name = opts.custom_name
	---@diagnostic disable-next-line
	return instance
end

function Nightclub:Reset()
	self:ResetImpl()
end

---@return boolean
function Nightclub:HasBusinessHub()
	return stats.get_int("MPX_BUSINESSHUB_OWNED") == self.m_id
end

---@return integer
function Nightclub:GetHubStorageLevels()
	return stats.get_int("MPX_BUSINESSHUB_MOD_3")
end

---@return string
function Nightclub:GetCustomName()
	return self.m_custom_name or "The Palace"
end

---@return integer
function Nightclub:GetPopularity()
	return stats.get_int("MPX_CLUB_POPULARITY")
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
function Nightclub:AddSubBusiness(index)
	if (not self:IsValid() or not self:HasBusinessHub()) then
		return
	end

	local ref = RawBusinessData.BusinessHubs[index + 1]
	if (not ref) then
		return
	end

	table.insert(self.m_subs, BusinessHub.new({
		id        = index,
		name      = ref.name,
		max_units = tunables.get_int(ref.max_units_tunable),
		vpu       = tunables.get_int(ref.vpu_tunable)
	}))
end

return Nightclub
