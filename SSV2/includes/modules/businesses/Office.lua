-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessFront   = require("includes.modules.businesses.BusinessFront")
local Warehouse       = require("includes.modules.businesses.Warehouse")
local RawBusinessData = require("includes.data.yrv3_data")

---@class OfficeOpts : BusinessFrontOpts
---@field custom_name string
---@field safe_data nil

-- Class representing the CEO Office.
---@class Office : BusinessFront
---@field private m_id integer
---@field private m_name string
---@field private m_custom_name string
---@field private m_subs array<Warehouse>
---@field public GetSubBusinesses fun(self: Office): array<Warehouse>
local Office          = setmetatable({}, BusinessFront)
Office.__index        = Office

---@param opts OfficeOpts
---@return Office
function Office.new(opts)
	local base             = BusinessFront.new(opts)
	local instance         = setmetatable(base, Office)
	instance.m_custom_name = opts.custom_name
	---@diagnostic disable-next-line
	return instance
end

function Office:Reset()
	self:ResetImpl()
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
	for _, wh in ipairs(self.m_subs) do
		count = count + wh:GetEstimatedIncome()
	end
	return count
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
	for _, wh in ipairs(self.m_subs) do
		if (wh:IsValid() and type(wh.Update) == "function") then
			wh:Update()
		end
	end
end

return Office
