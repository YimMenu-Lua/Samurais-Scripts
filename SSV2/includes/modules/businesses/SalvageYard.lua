-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessFront = require("includes.modules.businesses.BusinessFront")
local data          = require("includes.data.sv23_data")

---@class SYOpts : BusinessFrontOpts

-- Class representing the SalvageYard business.
---@class SalvageYard : BusinessFront
---@field private m_id integer
---@field private m_name string
---@field private m_safe CashSafe
local SalvageYard   = setmetatable({}, BusinessFront)
SalvageYard.__index = SalvageYard

---@param opts SYOpts
---@return SalvageYard
function SalvageYard.new(opts)
	local base = BusinessFront.new(opts)
	---@diagnostic disable-next-line
	return setmetatable(base, SalvageYard)
end

function SalvageYard:Reset() --[[noop]] end

---@return boolean
function SalvageYard:HasStaffUpgrade()
	return stats.get_int("MPX_SALVAGE_YARD_STAFF") == 1
end

---@return boolean
function SalvageYard:HasWallSafeUpgrade()
	return stats.get_int("MPX_SALVAGE_YARD_WALL_SAFE") == 1
end

---@param slot integer
---@return boolean
function SalvageYard:IsLiftTaken(slot)
	return self:GetCarModelOnLift(slot) ~= 0
end

---@return boolean
function SalvageYard:IsRobberyActive()
	return self:GetRobberyType() >= 0
end

function SalvageYard:IsWeeklyCooldownDisabled()
	return tunables.get_int("SALV23_VEH_ROBBERY_WEEK_ID") ~= stats.get_int("MPX_SALV23_WEEK_SYNC")
end

---@return boolean
function SalvageYard:ArePrepsCompleted()
	return Bit.is_set(stats.get_int("MPX_SALV23_GEN_BS"), 0)
end

-- Similar to nightclub popularity.
---@return integer `0 .. 100`
function SalvageYard:GetIncomeThreshold()
	return stats.get_packed_stat_int(51051)
end

---@param slot integer
---@return hash
function SalvageYard:GetCarModelOnLift(slot)
	return stats.get_int(_F("MPX_MPSV_MODEL_SALVAGE_LIFT%d", slot))
end

---@param slot integer
---@return integer
function SalvageYard:GetCarValueOnLift(slot)
	return stats.get_int(_F("MPX_MPSV_VALUE_SALVAGE_LIFT%d", slot))
end

---@param slot integer
---@return integer
function SalvageYard:GetRobberyCarValue(slot)
	return stats.get_int(_F("MPX_SAL23_VALUE_VEH%d", slot))
end

---@param slot integer
---@return string
function SalvageYard:GetWeeklyRobberyStatus(slot)
	local status = stats.get_int(_F("MPX_SALV23_VEHROB_STATUS%d", slot))
	return _T(data.robbery_status_labels[status + 1] or "GENERIC_UNKOWN")
end

---@return string
function SalvageYard:GetRobberyCooldownString()
	local cd = stats.get_int("MPX_SALV23_VEHROB_CD")
	return cd <= 0 and _T("SY_CD_NONE") or _T("SY_CD_ACTIVE")
end

function SalvageYard:GetRobberyType()
	return stats.get_int("MPX_SALV23_VEH_ROB")
end

---@return string
function SalvageYard:GetRobberyName()
	local stringtype = data.robbery_types[self:GetRobberyType() + 1]
	return stringtype and stringtype.name or _T("GENERIC_NONE")
end

---@return hash
function SalvageYard:GetRobberyVehicleModel()
	return stats.get_int("MPX_SALV23_VEH_MODEL")
end

---@return string
function SalvageYard:GetRobberyVehicleName()
	return vehicles.get_vehicle_display_name(self:GetRobberyVehicleModel())
end

---@return integer
function SalvageYard:GetRobberyValue()
	return stats.get_int("MPX_SALV23_SALE_VAL")
end

---@return boolean
function SalvageYard:GetRobberyKeepState()
	return stats.get_bool("MPX_SALV23_CAN_KEEP")
end

---@param slot integer
---@return string
function SalvageYard:GetRobberyCarInSlot(slot)
	local index     = stats.get_int(_F("MPX_MPSV_MODEL_SALVAGE_VEH%d", slot))
	local modelName = data.vehicle_targets[index]
	if (not modelName) then
		return ""
	end

	return vehicles.get_vehicle_display_name(modelName)
end

function SalvageYard:DisableRobberyCooldown()
	stats.set_int("MPX_SALV23_VEHROB_CD", 0)
end

function SalvageYard:DisableWeeklyCooldown()
	tunables.set_int("SALV23_VEH_ROBBERY_WEEK_ID", stats.get_int("MPX_SALV23_WEEK_SYNC") + 1)
	Notifier:ShowSuccess("Salvage Yard", _T("SY_CD_SKIP_SUCCESS"))
end

function SalvageYard:SkipPreps()
	local current = self:GetRobberyType()
	local info = data.robbery_types[current + 1]
	if (not info) then
		Notifier:ShowError("Salvage Yard", _T("SY_CD_ROB_TYPE_ERR"))
		return
	end

	stats.set_int("MPX_SALV23_FM_PROG", info.fm_prog)
	stats.set_int("MPX_SALV23_SCOPE_BS", info.scope_bs)
	stats.set_int("MPX_SALV23_DISRUPT", info.disrupt)
	Notifier:ShowSuccess("Salvage Yard", _T("SY_PREP_SKIP"))
end

function SalvageYard:DoubleCarWorth()
	local current_worth = self:GetRobberyValue()
	stats.set_int("MPX_SALV23_SALE_VAL", current_worth * 2)
end

function SalvageYard:MaximizeIncome()
	if (self:GetIncomeThreshold() >= 100) then
		return
	end

	stats.set_packed_stat_int(51051, 100)
end

function SalvageYard:LockIncomeDecay()
	if (tunables.get_float(797544186) <= 0.0) then
		return
	end

	tunables.set_float(797544186, -1e-8)
	self:MaximizeIncome()
end

function SalvageYard:RestoreIncomeDecay()
	if (tunables.get_float(797544186) == 5.0) then
		return
	end

	tunables.set_float(797544186, 5.0)
end

---@param slot integer
function SalvageYard:SalvageNow(slot)
	if (not self:IsLiftTaken(slot)) then
		return
	end

	local diff     = self:HasStaffUpgrade() and 2880 or 5760
	local statName = _F("MPX_SALVAGING_POSIX_LIFT%d", slot)
	stats.set_int(statName, stats.get_int(statName) - diff)
end

---@return integer
function SalvageYard:GetEstimatedIncome()
	local sum = 0
	for i = 1, 4 do
		sum = sum + self:GetRobberyCarValue(i)
	end

	return sum + self.m_safe:GetCashValue()
end

return SalvageYard
