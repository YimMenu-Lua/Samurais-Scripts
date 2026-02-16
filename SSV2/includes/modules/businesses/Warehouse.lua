-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessBase = require("includes.modules.businesses.BusinessBase")

---@param crates integer
local function GetCEOCratesValue(crates)
	if (not crates or crates <= 0) then
		return 0
	end

	local val
	if crates <= 3 then
		val = tostring(crates)
	elseif crates <= 5 then
		val = "4"
	elseif crates <= 7 then
		val = "5"
	elseif crates <= 9 then
		val = "6"
	elseif crates <= 14 then
		val = "7"
	elseif crates <= 19 then
		val = "8"
	elseif crates <= 24 then
		val = "9"
	elseif crates <= 29 then
		val = "10"
	elseif crates <= 34 then
		val = "11"
	elseif crates <= 39 then
		val = "12"
	elseif crates <= 44 then
		val = "13"
	elseif crates <= 49 then
		val = "14"
	elseif crates <= 59 then
		val = "15"
	elseif crates <= 69 then
		val = "16"
	elseif crates <= 79 then
		val = "17"
	elseif crates <= 89 then
		val = "18"
	elseif crates <= 99 then
		val = "19"
	elseif crates <= 110 then
		val = "20"
	elseif crates == 111 then
		val = "21"
	end

	return val and (tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD" .. val) * crates) or 0
end

---@enum eWarehouseType
Enums.eWarehouseType = {
	SPECIAL_CARGO = 0x0,
	HANGAR        = 0x1
}

---@class WarehouseOpts : BusinessOpts
---@field max_units integer
---@field name string
---@field coords vec3
---@field size? integer Special Cargo only

-- Class representing a warehouse that stores valuable cargo.
--
-- Can be `CEO Special Cargo Warehouse` or `Hangar`.
---@class Warehouse : BusinessBase
---@field private m_id integer
---@field private m_type eWarehouseType
---@field private m_auto_fill_running boolean
---@field private m_name string
---@field private m_coords vec3
---@field private m_size integer
---@field private m_max_units integer
---@field public auto_fill boolean
local Warehouse = setmetatable({}, BusinessBase)
Warehouse.__index = Warehouse

---@param opts WarehouseOpts
---@param warehouse_type eWarehouseType
---@return Warehouse
function Warehouse.new(opts, warehouse_type)
	assert(type(opts.max_units) == "number", "Missing argument: max_units<integer>")

	local base                   = BusinessBase.new(opts)
	local instance               = setmetatable(base, Warehouse)
	instance.m_type              = warehouse_type
	instance.m_size              = opts.size
	instance.auto_fill           = false
	instance.m_auto_fill_running = false

	---@diagnostic disable-next-line
	return instance
end

function Warehouse:Reset()
	self.auto_fill           = false
	self.m_auto_fill_running = false
	self:ResetImpl()
end

---@return eWarehouseType
function Warehouse:GetType()
	return self.m_type
end

---@return integer
function Warehouse:GetSize()
	return self.m_size
end

---@return integer
function Warehouse:GetProductCount()
	if (self.m_type == Enums.eWarehouseType.HANGAR) then
		return stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL")
	elseif (self.m_type == Enums.eWarehouseType.SPECIAL_CARGO) then
		if (not self.m_id or not math.is_inrange(self.m_id, 0, 4)) then
			return 0
		end
		return stats.get_int(_F("MPX_CONTOTALFORWHOUSE%d", self.m_id))
	end

	return 0
end

---@return integer
function Warehouse:GetProductValue()
	local stock = self:GetProductCount()
	if (self.m_type == Enums.eWarehouseType.HANGAR) then
		return math.floor(stock * 3e4)
	elseif (self.m_type == Enums.eWarehouseType.SPECIAL_CARGO) then
		return GetCEOCratesValue(stock)
	end

	return 0
end

---@return boolean
function Warehouse:HasFullProduction()
	return self:GetProductCount() == self.m_max_units
end

function Warehouse:ReStock()
	if (self:HasFullProduction()) then
		Notifier:ShowError(self:GetName(), _T("YRV3_FAST_PROD_ERR"))
		return
	end

	if (self.m_type == Enums.eWarehouseType.HANGAR) then
		stats.set_bool_masked("MPX_DLC22022PSTAT_BOOL3", true, 9)
	elseif (self.m_type == Enums.eWarehouseType.SPECIAL_CARGO) then
		if (not self.m_id or not math.is_inrange(self.m_id, 0, 4)) then
			return 0
		end
		stats.set_bool_masked("MPX_FIXERPSTAT_BOOL1", true, self.m_id + 12)
	end
end

function Warehouse:AutoFill()
	ThreadManager:Run(function()
		while (self:IsValid() and self.auto_fill and not self:HasFullProduction()) do
			self:ReStock()
			if (not Game.IsOnline()) then
				break
			end

			sleep(GVars.features.yrv3.autofill_delay or 300)
		end

		self.auto_fill = false
		self.m_auto_fill_running = false
	end)
end

function Warehouse:Update()
	if (not self:IsValid()) then
		return
	end

	if (self.auto_fill and not self.m_auto_fill_running) then
		if (self:HasFullProduction()) then
			self.auto_fill = false
			return
		end

		self.m_auto_fill_running = true
		self:AutoFill()
	end
end

return Warehouse
