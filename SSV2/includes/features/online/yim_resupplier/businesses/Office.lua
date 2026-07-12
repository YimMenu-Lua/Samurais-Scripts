-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessFront       = require("BusinessFront")
local VehicleWarehouse    = require("VehicleWarehouse")
local Warehouse           = require("Warehouse")
local RawBusinessData     = require("includes.data.yrv3_data")
local IPLPrefixes <const> = {
	"ex_sm_13_",
	"ex_sm_15_",
	"ex_dt1_02_",
	"ex_dt1_11_",
}
local IPLVars <const>     = {
	"office_01a",
	"office_01b",
	"office_01c",
	"office_02a",
	"office_02b",
	"office_02c",
	"office_03a",
	"office_03b",
	"office_03c",
}

---@class OfficeClutterItemsParam
---@field cash boolean
---@field Swag_Silver? boolean
---@field Swag_Pills? boolean
---@field Swag_Med? boolean
---@field Swag_JewelWatch? boolean
---@field Swag_Ivory? boolean
---@field Swag_Guns? boolean
---@field Swag_Gems? boolean
---@field Swag_Furcoats? boolean
---@field Swag_electronic? boolean
---@field Swag_DrugStatue? boolean
---@field Swag_DrugBags? boolean
---@field Swag_Counterfeit? boolean
---@field Swag_Booze_cigs? boolean
---@field Swag_Art? boolean

---@class OfficeOpts : BusinessFrontOpts
---@field custom_name nil
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
---@field private m_ipl_name string
---@field private m_interior_name_hash joaat_t
---@field private m_subs array<Warehouse>
---@field private m_vehicle_warehouse? VehicleWarehouse
---@field private m_earnings_report OfficeEarningsReport
---@field private m_last_report_check_time milliseconds
---@field private m_last_known_interior integer
local Office   = setmetatable({}, BusinessFront)
Office.__index = Office

---@param opts OfficeOpts
---@return Office
function Office.new(opts)
	local base       = BusinessFront.new(opts)
	local instance   = setmetatable(base, Office) ---@cast instance Office
	local customName = stats.get_string("MPX_GB_OFFICE_NAME") .. stats.get_string("MPX_GB_OFFICE_NAME2")
	if (not string.isvalid(customName)) then
		customName = Game.GetLabelText("GB_REST_ACC")
	end

	local iplPrefix                = IPLPrefixes[opts.id or 1]
	local iplSuffix                = IPLVars[stats.get_int("MPX_PROP_OFFICE_VAR")]
	instance.m_ipl_name            = iplPrefix .. iplSuffix
	instance.m_last_known_interior = 0
	instance.m_custom_name         = customName
	instance.m_earnings_report     = {
		lifetime_buy_undertaken  = 0,
		lifetime_buy_completed   = 0,
		lifetime_sell_undertaken = 0,
		lifetime_sell_completed  = 0,
		lifetime_earnings        = 0,
		lifetime_earnings_fmt    = "$0",
	}

	for i = 0, 4 do
		instance:AddSubBusiness(i)
	end
	instance:CheckVehicleWarehouse()
	--[[
	scr_function.add_script_function_hook("am_mp_property_int", "NO_OFFICE_CLUTTER", "2D 03 05 00 00 43 75 04 66 38", function(args, rets)
		local iParam0 = args:get_int(0)
		if (iParam0 == 0 or iParam0 == 1) then
			rets:set_int(0, 0)
			return false
		end
		return true
	end) ]]

	return instance
end

function Office:Reset()
	-- scr_function.remove_script_function_hook("am_mp_property_int", "NO_OFFICE_CLUTTER")
	self:ResetImpl()
end

---@return string
function Office:GetIPLName()
	return self.m_ipl_name
end

---@return boolean
function Office:IsPlayerInside()
	if (LocalPlayer:IsOutside()) then
		return false
	end

	return STREAMING.IS_IPL_ACTIVE(self.m_ipl_name)
end

---@private
function Office:CheckVehicleWarehouse()
	local ie_wh_prop = stats.get_int("MPX_PROP_IE_WAREHOUSE")
	if (ie_wh_prop == 0 or ie_wh_prop >= math.int32_max()) then
		return
	end

	local idx = ie_wh_prop - 114
	local ref = RawBusinessData.VehicleWarehouses[idx]
	if (not ref) then return end

	self.m_vehicle_warehouse = VehicleWarehouse.new(
		Game.GetLabelText(ref.gxt),
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
		name      = Game.GetLabelText(_F("MP_WHOUSE_%d", property_index - 1)),
		coords    = ref.coords,
	}, Enums.eWarehouseType.SPECIAL_CARGO))
end

---@param newName string
function Office:Rename(newName)
	ThreadManager:Run(function()
		if (not string.isvalid(newName)) then
			newName = Game.GetLabelText("GB_REST_ACC")
		end

		scr_function.call_script_function("freemode",
			"OFFICE_RENAME",
			"2D 02 14 00 00 38 01 56 ? ? 38 00 2C 05 ? ? 06 56 ? ? 26 2D",
			"void",
			{
				{ "const char*", newName },
				{ "bool",        true },
			}
		)

		self.m_custom_name = newName
	end)
end

---@private
---@param officeInt integer
---@return boolean
local function remove_office_cash_clutter_set(officeInt)
	local out = false
	for i = 1, 24 do
		local suffix = i < 10 and "0" .. i or tostring(i)
		local setName = "Cash_Set_" .. suffix
		if (INTERIOR.IS_INTERIOR_ENTITY_SET_ACTIVE(officeInt, setName)) then
			INTERIOR.DEACTIVATE_INTERIOR_ENTITY_SET(officeInt, setName)
			out = true
		end
	end
	return out
end

---@private
---@param officeInt integer
---@param baseName string
---@return boolean
local function remove_office_clutter_set(officeInt, baseName)
	local out = false
	if (INTERIOR.IS_INTERIOR_ENTITY_SET_ACTIVE(officeInt, baseName)) then
		INTERIOR.DEACTIVATE_INTERIOR_ENTITY_SET(officeInt, baseName)
		out = true
	end

	for i = 2, 3 do
		local setName = baseName .. i
		if (INTERIOR.IS_INTERIOR_ENTITY_SET_ACTIVE(officeInt, setName)) then
			INTERIOR.DEACTIVATE_INTERIOR_ENTITY_SET(officeInt, setName)
			out = true
		end
	end

	return out
end

---@param clutter_t OfficeClutterItemsParam
function Office:RemoveClutter(clutter_t)
	local interior = LocalPlayer:GetInteriorID()
	if (interior == self.m_last_known_interior) then
		return
	end

	if (not self:IsPlayerInside()) then
		self.m_last_known_interior = interior
		return
	end

	if (not LocalPlayer:HasControl()) then
		return
	end

	local shouldRefresh = false
	for name, bValue in pairs(clutter_t) do
		if (not bValue) then
			goto continue
		end

		if (name == "cash") then
			if (remove_office_cash_clutter_set(interior)) then
				shouldRefresh = true
			end
		elseif (remove_office_clutter_set(interior, name)) then
			shouldRefresh = true
		end

		::continue::
	end

	if (shouldRefresh) then
		INTERIOR.REFRESH_INTERIOR(interior)
	end
	self.m_last_known_interior = interior
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

	local now_ms = Time.Millis()
	if (now_ms - self.m_last_report_check_time > 5000 and GUI:IsOpen()) then
		self:UpdateEarningsReport()
		self.m_last_report_check_time = now_ms
	end

	local cfg = GVars.features.yrv3.office_clutter
	if (cfg.auto_disable) then
		self:RemoveClutter(cfg.items)
	end
end

return Office.new
