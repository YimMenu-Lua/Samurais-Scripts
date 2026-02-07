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

function SalvageYard:IsTowMissionActive()
	return script.is_active("fm_content_tow_truck_work")
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
	if (tunables.get_int(797544186) <= 0) then
		return
	end

	tunables.set_int(797544186, 0)
	self:MaximizeIncome()
end

function SalvageYard:RestoreIncomeDecay()
	if (tunables.get_int(797544186) == 5) then
		return
	end

	tunables.set_int(797544186, 5)
end

---@return seconds
function SalvageYard:GetSalvagePosixForLift(slot)
	if (not self:IsLiftTaken(slot)) then
		return 0
	end

	return stats.get_int(_F("MPX_SALVAGING_POSIX_LIFT%d", slot))
end

function SalvageYard:BringTowMissionTarget()
	ThreadManager:Run(function()
		-- This is low quality but works... kinda.
		-- The proper way to do it it so check the mission flow bitset in fm_content_tow_truck_work
		-- then get the target vehicle. But I'm lazy and don't want to maintain any more script globals and locals.
		-- 		- Target vehicle: ScriptLocal(1850, "fm_content_tow_truck_work"):At(48):At(0, 9) -- (netID)
		-- 		- Tow truck: ScriptLocal(1850, "fm_content_tow_truck_work"):At(48):At(1, 9) -- (netID)
		--

		if (not self:IsTowMissionActive()) then
			return
		end

		if (not Self:IsHostOfScript("fm_content_tow_truck_work")) then
			Notifier:ShowError("YRV3", _T("YRV3_SCRIPT_HOST_ERR"))
			return
		end

		local PV = Self:GetVehicle()
		if (Self:IsOnFoot() or not PV:IsTowTruck()) then
			Notifier:ShowError(_T("SY_SALVAGE_YARD"), _T("SY_NOT_IN_TOWTRUCK_ERR"))
			return
		end

		local found, objective = Game.GetObjectiveBlipCoords()
		if (not found or not objective or objective:is_zero()) then
			Notifier:ShowError(_T("SY_SALVAGE_YARD"), _T("SY_TOW_OBJECTIVE_NOT_FOUND_ERR"))
			return
		end

		local veh = Game.GetClosestVehicle(objective, 1, nil, true, 0)
		if (veh == 0 or not ENTITY.IS_ENTITY_A_VEHICLE(veh)) then
			Notifier:ShowError(_T("SY_SALVAGE_YARD"), _T("SY_TOW_VEH_NOT_FOUND_ERR"))
			return
		end

		local myPos     = Self:GetPos()
		local heading   = Self:GetHeading()
		local bonePos   = PV:GetBonePosition("tow_mount_a")
		local forward   = PV:GetForwardVector()
		local offsetPos = vec3:new(
			bonePos.x - forward.x * 3.5,
			bonePos.y - forward.y * 3.5,
			bonePos.z
		)

		if (myPos:distance(objective) >= 100) then
			PED.SET_PED_COORDS_KEEP_VEHICLE(Self:GetHandle(), objective.x, objective.y, objective.z)
			yield()
			PED.SET_PED_COORDS_KEEP_VEHICLE(Self:GetHandle(), myPos.x, myPos.y, myPos.z)
			VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(PV:GetHandle(), 5.0)
		end

		VEHICLE.SET_VEHICLE_TOW_TRUCK_ARM_POSITION(PV:GetHandle(), 0.0)
		sleep(2000)
		ENTITY.SET_ENTITY_HEADING(veh, heading)
		ENTITY.SET_ENTITY_PROOFS(
			veh,
			false,
			false,
			false,
			true,
			false,
			false,
			false,
			false
		)
		Game.SetEntityCoords(veh, offsetPos)
		while (Game.GetEntityCoords(veh, false):distance(offsetPos) > 50) do
			yield()
		end

		VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(veh, 5.0)
		if (not ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(veh, PV:GetHandle())) then
			VEHICLE.ATTACH_VEHICLE_TO_TOW_TRUCK(PV:GetHandle(), veh, false, 0, 0, 0)
			sleep(500)
		end

		VEHICLE.SET_VEHICLE_TOW_TRUCK_ARM_POSITION(PV:GetHandle(), 1.0)

		---@diagnostic disable
		local syPos = self:GetCoords()
		if (Self:GetPos():distance(syPos) > 10 and ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(veh, PV:GetHandle())) then
			Self:Teleport(syPos, true)
		end
		---@diagnostic enable
	end)
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

	for i = 1, 2 do
		sum = sum + self:GetCarValueOnLift(i)
	end

	for i = 1, 4 do
		sum = sum + self:GetRobberyCarValue(i)
	end

	return sum + self.m_safe:GetCashValue()
end

return SalvageYard
