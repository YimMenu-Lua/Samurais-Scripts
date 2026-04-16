-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local IEData <const> = require("includes.data.imp_exp_vehicles")
local SGSL           = require("includes.services.SGSL")

---@alias IEStoredVehicle array<{ name: string, plate_text: string, range: integer, range_str: string, base_commis: integer, slot: integer, commis_fmt: string }>


local VehicleRangeToStr <const> = {
	"YRV3_IE_VEH_RANGE_HIGH",
	"YRV3_IE_VEH_RANGE_MID",
	"YRV3_IE_VEH_RANGE_LOW",
}


---@class VehicleWarehouse
---@field private m_name string
---@field private m_coords vec3
---@field private m_last_storage_update_time milliseconds
---@field private m_cached_veh_storage IEStoredVehicle
---@field private m_cached_income integer
---@field private m_range_count_table { top: integer, mid: integer, low: integer }
local VehicleWarehouse <const> = {}
VehicleWarehouse.__index       = VehicleWarehouse

---@param name string
---@param coords vec3
---@return VehicleWarehouse
function VehicleWarehouse.new(name, coords)
	return setmetatable({
		m_name                     = name,
		m_coords                   = coords,
		m_last_storage_update_time = 0,
		m_cached_income            = 0,
		m_cached_veh_storage       = {},
		m_range_count_table        = {
			top = 0,
			mid = 0,
			low = 0,
		},
	}, VehicleWarehouse)
end

function VehicleWarehouse:ClearStoredRanges()
	self.m_range_count_table.top = 0
	self.m_range_count_table.mid = 0
	self.m_range_count_table.low = 0
end

---@param r integer
function VehicleWarehouse:IncrementStoredRange(r)
	if (r == 1) then
		self.m_range_count_table.top = self.m_range_count_table.top + 1
	elseif (r == 2) then
		self.m_range_count_table.mid = self.m_range_count_table.mid + 1
	elseif (r == 3) then
		self.m_range_count_table.low = self.m_range_count_table.low + 1
	end
end

---@return integer
function VehicleWarehouse:GetTopRangeCount()
	return self.m_range_count_table.top
end

---@return integer
function VehicleWarehouse:GetMidRangeCount()
	return self.m_range_count_table.mid
end

---@return integer
function VehicleWarehouse:GetLowRangeCount()
	return self.m_range_count_table.low
end

---@return boolean
function VehicleWarehouse:HasReachedOptimalStealingThreshold()
	local top = self:GetTopRangeCount()
	local mid = self:GetMidRangeCount()
	local low = self:GetLowRangeCount()

	return mid == 10 and low == 10 and top >= 10
end

---@return string
function VehicleWarehouse:GetName()
	return self.m_name or "Vehicle Warehouse"
end

---@return vec3
function VehicleWarehouse:GetCoords()
	return self.m_coords
end

---@param slot integer
---@return integer
function VehicleWarehouse:GetVehicleInSlot(slot)
	return stats.get_int(_F("MPX_IE_WH_OWNED_VEHICLE_%d", slot))
end

---@param index integer
---@return string
function VehicleWarehouse:GetVehicleNameAtIndex(index)
	local ie_entry = IEData.base_data[index]
	if (not ie_entry) then
		return "NULL"
	end

	return Game.GetVehicleDisplayName(ie_entry.model)
end

---@return IEStoredVehicle
function VehicleWarehouse:GetStoredVehicles()
	return self.m_cached_veh_storage
end

---@return integer
function VehicleWarehouse:GetNumberOfStoredVehicles()
	return #self:GetStoredVehicles()
end

---@return integer
function VehicleWarehouse:GetEstimatedIncome()
	return self.m_cached_income
end

---@private
---@param index integer
---@param pos integer
---@return boolean
function VehicleWarehouse:IsMissionBitSet(index, pos)
	local obj_1        = SGSL:Get(SGSL.data.ie_objective_local)
	local obj_2        = SGSL:Get(SGSL.data.ie_steal_bitset)
	local local_offset = obj_2:GetValue()
	local bs_read_size = obj_2:GetOffset(1)
	local ImportExport = obj_1:AsLocal()
	local bit_offset   = math.floor(pos / 32)
	local bit          = pos % 32
	local v            = ImportExport:At(local_offset):At(index, bs_read_size):At(bit_offset):ReadInt()
	return Bit.IsBitSet(v, bit)
end

---@private
---@param index integer
---@param pos integer
function VehicleWarehouse:SetMissionBit(index, pos)
	local obj_1        = SGSL:Get(SGSL.data.ie_objective_local)
	local obj_2        = SGSL:Get(SGSL.data.ie_steal_bitset)
	local local_offset = obj_2:GetValue()
	local bs_read_size = obj_2:GetOffset(1)
	local ImportExport = obj_1:AsLocal()
	local bit_offset   = math.floor(pos / 32)
	local bit          = pos % 32
	ImportExport:At(local_offset)
		:At(index, bs_read_size)
		:At(bit_offset):SetBit(bit)
end

---@private
---@param index integer
---@param pos integer
function VehicleWarehouse:ClearMissionBit(index, pos)
	local obj_1        = SGSL:Get(SGSL.data.ie_objective_local)
	local obj_2        = SGSL:Get(SGSL.data.ie_steal_bitset)
	local local_offset = obj_2:GetValue()
	local bs_read_size = obj_2:GetOffset(1)
	local ImportExport = obj_1:AsLocal()
	local bit_offset   = math.floor(pos / 32)
	local bit          = pos % 32
	ImportExport:At(local_offset)
		:At(index, bs_read_size)
		:At(bit_offset)
		:ClearBit(bit)
end

---@private
---@param pos integer
function VehicleWarehouse:SetMissionBit2(pos)
	local obj          = SGSL:Get(SGSL.data.ie_objective_local)
	local local_offset = SGSL:Get(SGSL.data.ie_bitset_1):GetValue()
	local ImportExport = obj:AsLocal()
	local bit_offset   = math.floor(pos / 32)
	local bit          = pos % 32
	ImportExport:At(local_offset):At(bit_offset):SetBit(bit)
end

---@return boolean
function VehicleWarehouse:IsStealMission()
	if (not script.is_active("gb_vehicle_export")) then
		return false
	end

	-- TODO: this is wrong as well.
	return self:IsMissionBitSet(1, 1)
end

function VehicleWarehouse:FinishStealMission()
	-- if (not self:IsStealMission()) then
	-- 	return
	-- end

	local obj_1           = SGSL:Get(SGSL.data.ie_objective_local)
	local obj_2           = SGSL:Get(SGSL.data.ie_steal_bitset)
	local num_vehs        = SGSL:Get(SGSL.data.ie_num_vehs):GetValue()
	local objective_state = obj_1:GetOffset(1)
	local bs1             = SGSL:Get(SGSL.data.ie_bitset_1):GetValue()
	local bs2             = obj_2:GetValue()
	local bs_read_size    = obj_2:GetOffset(1)
	local ImportExport    = obj_1:AsLocal()
	ImportExport:At(objective_state + 1):WriteInt(2)       -- uLocal_880.f_460 so .f_459 + 1 // func_2() == 2
	ImportExport:At(objective_state):WriteInt(13)
	ImportExport:At(bs1):WriteInt(420972882)               -- this is horrible. This is not how the bitsets should be flipped
	ImportExport:At(bs2):At(bs_read_size):WriteInt(420972882) -- //

	-- self:SetMissionBit2(0)
	-- self:SetMissionBit2(19)

	-- for i = 0, num_vehs do
	-- 	self:SetMissionBit(i, 6)
	-- 	self:SetMissionBit(i, 15)
	-- 	self:SetMissionBit(i, 16)
	-- 	self:SetMissionBit(i, 25)
	-- end
end

function VehicleWarehouse:Update()
	if (Time.Millis() - self.m_last_storage_update_time < 1200 or not GUI:IsOpen()) then
		return
	end

	self.m_cached_income = 0
	self:ClearStoredRanges()

	local temp = {}
	for i = 0, 39 do
		local idx   = self:GetVehicleInSlot(i)
		local entry = IEData.base_data[idx]
		if (idx == 0 or not entry) then
			goto continue
		end

		local model           = entry.model
		local range_data      = IEData.range_data[model]
		local range           = range_data and range_data.range or 3 -- R* also defaults to low range.
		local commission_base = tunables.get_int(IEData.base_value_tunables[range])
		self.m_cached_income  = self.m_cached_income + commission_base
		self:IncrementStoredRange(range)
		table.insert(temp, {
			slot        = i + 1,
			name        = Game.GetVehicleDisplayName(model),
			plate_text  = entry.plate or "NULL",
			range       = range,
			range_str   = _T(VehicleRangeToStr[range]),
			base_commis = commission_base,
			commis_fmt  = string.formatmoney(commission_base)
		})

		::continue::
	end

	-- table.overwrite(self.m_cached_veh_storage, temp) -- unnecessary as we currently don't hold refs to this table anywhere
	self.m_cached_veh_storage       = temp
	self.m_last_storage_update_time = Time.Millis()
end

return VehicleWarehouse
