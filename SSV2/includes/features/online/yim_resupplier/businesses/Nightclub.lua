-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessFront   = require("BusinessFront")
local BusinessHub     = require("BusinessHub")
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
	local instance         = setmetatable(base, Nightclub) ---@cast instance Nightclub
	instance.m_custom_name = opts.custom_name or "Nightclub"

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
	return self.m_custom_name
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
	Notifier:ShowSuccess(self.m_custom_name, _T("YRV3_POPULARITY_NOTIF"))
end

function Nightclub:LockPopularityDecay()
	tunables.set_float("NIGHTCLUBPOPDECAY", -1e-16)
	tunables.set_float("INIGHTCLUBPOPDECAYSTAFFUPGRADE", -1e-16)
	self:MaxPopularity()
end

function Nightclub:RestorePopularityDecay()
	tunables.set_float("NIGHTCLUBPOPDECAY", -0.1)
	tunables.set_float("INIGHTCLUBPOPDECAYSTAFFUPGRADE", -0.05)
end

---@param toggle boolean
function Nightclub:TogglePopulatirtyLock(toggle)
	if (toggle) then
		self:LockPopularityDecay()
	else
		self:RestorePopularityDecay()
	end
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
		name      = Game.GetGXTLabel(_F("CLUB_STOCK%d", index)),
		max_units = tunables.get_int(ref.max_units_tunable),
		vpu       = tunables.get_int(ref.vpu_tunable)
	}))
end

---@param src BusinessHub
---@param dest BusinessHub
function Nightclub:TransferTechnician(src, dest)
	local srcIDX  = src:GetAssignedTechIndex()
	local destIDX = dest:GetAssignedTechIndex()
	if (srcIDX == -1 or srcIDX == destIDX) then -- UI blocks this anyway
		return
	end

	local clubName = self:GetCustomName()
	local srcName  = src:GetName()
	if (not src:RemoveTechnician()) then
		Notifier:ShowError(clubName, _T("YRV3_HUB_REMOVE_TECH_FAIL_FMT", srcName))
		return
	end

	local destName     = dest:GetName()
	local destIdxValid = destIDX ~= -1
	if (destIdxValid and not dest:RemoveTechnician()) then
		src:AssignTechnician(srcIDX)
		Notifier:ShowError(clubName, _T("YRV3_HUB_REMOVE_TECH_FAIL_FMT", destName))
		return
	end

	if (not dest:AssignTechnician(srcIDX)) then
		src:AssignTechnician(srcIDX)
		if (destIdxValid) then
			dest:AssignTechnician(destIDX)
		end

		Notifier:ShowError(clubName, _T("YRV3_HUB_TRANSFER_TECH_FAIL_FMT", srcName, destName))
		return
	end

	if (destIdxValid and not src:AssignTechnician(destIDX)) then
		Notifier:ShowWarning(clubName, _T("YRV3_HUB_SWAP_TECH_WARN_FMT"))
		return
	end

	local msg = destIdxValid and "YRV3_HUB_SWAP_TECH_SUCCESS_FMT" or "YRV3_HUB_TRANSFER_TECH_SUCCESS_FMT"
	Notifier:ShowSuccess(clubName, _T(msg, srcName, destName))
end

return Nightclub.new
