-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessFront    = require("includes.modules.businesses.BusinessFront")
local VehicleWarehouse = require("includes.modules.businesses.VehicleWarehouse")
local Warehouse        = require("includes.modules.businesses.Warehouse")
local RawBusinessData  = require("includes.data.yrv3_data")


---@class OfficeOpts : BusinessFrontOpts
---@field custom_name string
---@field safe_data nil

---@class OfficeEarningsReport : BusinessEarningsReport
---@field lifetime_buy_undertaken integer
---@field lifetime_buy_completed integer
---@field lifetime_sell_undertaken integer
---@field lifetime_sell_completed integer
---@field lifetime_earnings integer
---@field lifetime_earnings_fmt string

-- Class representing the CEO Office.
---@class Office : BusinessFront
---@field private m_id integer
---@field private m_name string
---@field private m_custom_name string
---@field private m_subs array<Warehouse>
---@field private m_vehicle_warehouse? VehicleWarehouse
---@field private m_earnings_report OfficeEarningsReport
---@field private m_last_report_check_time milliseconds
local Office   = setmetatable({}, BusinessFront)
Office.__index = Office

---@param opts OfficeOpts
---@return Office
function Office.new(opts)
	local base                 = BusinessFront.new(opts)

	---@type Office
	---@diagnostic disable-next-line
	local instance             = setmetatable(base, Office)
	instance.m_custom_name     = opts.custom_name
	instance.m_earnings_report = {
		lifetime_buy_undertaken  = 0,
		lifetime_buy_completed   = 0,
		lifetime_sell_undertaken = 0,
		lifetime_sell_completed  = 0,
		lifetime_earnings        = 0,
		lifetime_earnings_fmt    = "$0",
	}
	instance:CheckVehicleWarehouse()
	return instance
end

function Office:Reset()
	self:ResetImpl()
end

---@private
function Office:CheckVehicleWarehouse()
	local ie_wh_prop = stats.get_int("MPX_PROP_IE_WAREHOUSE")
	if (ie_wh_prop == 0 or ie_wh_prop >= math.int32_max()) then
		return
	end

	local idx = ie_wh_prop - 114
	local ref = RawBusinessData.VehicleWarehouses[idx]
	if (not ref) then
		return
	end

	self.m_vehicle_warehouse = VehicleWarehouse.new(
		Game.GetGXTLabel(ref.gxt),
		ref.coords
	)
end

---@return VehicleWarehouse?
function Office:GetVehicleWarehouse()
	return self.m_vehicle_warehouse
end

---@return string
function Office:GetCustomName()
	return self.m_custom_name or "CEO Office"
end

---@return boolean
function Office:HasCargoWarehouse()
	return self.m_subs[1] and self.m_subs[1]:IsValid()
end

---@return integer
function Office:GetNumberOfOwnedCargoWarehouses()
	return #self.m_subs
end

---@param index integer `1 .. 5`
---@return Warehouse?
function Office:GetCargoWarehouseByIndex(index)
	for _, wh in ipairs(self.m_subs) do
		if (wh:GetIndex() == index - 1) then
			return wh
		end
	end

	return nil
end

-- Alias for `GetSubBusinesses`
---@return array<Warehouse>
function Office:GetCargoWarehouses()
	return self.m_subs
end

---@return integer
function Office:GetEstimatedIncome()
	local count = 0
	if (self.m_vehicle_warehouse) then
		count = count + self.m_vehicle_warehouse:GetEstimatedIncome()
	end

	for _, wh in ipairs(self.m_subs) do
		count = count + wh:GetEstimatedIncome()
	end
	return count
end

---@return OfficeEarningsReport
function Office:GetEarningsReport()
	return self.m_earnings_report
end

function Office:UpdateEarningsReport()
	self.m_earnings_report                          = self.m_earnings_report or {}

	local lifetime_earnings                         = stats.get_int("MPX_LIFETIME_CONTRA_EARNINGS")
	self.m_earnings_report.lifetime_earnings        = lifetime_earnings
	self.m_earnings_report.lifetime_earnings_fmt    = string.formatmoney(lifetime_earnings)
	self.m_earnings_report.lifetime_buy_undertaken  = stats.get_int("MPX_LIFETIME_BUY_UNDERTAKEN")
	self.m_earnings_report.lifetime_buy_completed   = stats.get_int("MPX_LIFETIME_BUY_COMPLETE")
	self.m_earnings_report.lifetime_sell_undertaken = stats.get_int("MPX_LIFETIME_SELL_UNDERTAKEN")
	self.m_earnings_report.lifetime_sell_completed  = stats.get_int("MPX_LIFETIME_SELL_COMPLETE")
end

---@param index integer
function Office:AddSubBusiness(index)
	if (not self:IsValid()) then
		return
	end

	if (not math.is_inrange(index, 0, 4)) then
		return
	end

	local property_index = stats.get_int(_F("MPX_PROP_WHOUSE_SLOT%d", index))
	local ref            = RawBusinessData.CEOWarehouses[property_index]
	if (not ref) then
		return
	end

	table.insert(self.m_subs, Warehouse.new({
		id        = index,
		size      = ref.size,
		max_units = ref.max,
		name      = Game.GetGXTLabel(_F("MP_WHOUSE_%d", property_index - 1)),
		coords    = ref.coords,
	}, Enums.eWarehouseType.SPECIAL_CARGO))
end

function Office:Update()
	if (self.m_vehicle_warehouse) then
		self.m_vehicle_warehouse:Update()
	end

	for _, wh in ipairs(self.m_subs) do
		if (wh:IsValid() and type(wh.Update) == "function") then
			wh:Update()
		end
	end

	if (Time.Millis() - self.m_last_report_check_time > 5000 and GUI:IsOpen()) then
		self:UpdateEarningsReport()
		self.m_last_report_check_time = Time.Millis()
	end
end

return Office
