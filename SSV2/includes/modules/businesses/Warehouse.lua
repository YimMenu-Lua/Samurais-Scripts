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

	if (crates == 1) then
		return tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD1")
	end

	if (crates == 2) then
		return tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD2") * 2 -- +1
	end

	if (crates == 3) then
		return tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD3") * 3 -- +1
	end

	if (crates == 4 or crates == 5) then
		return tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD4") * crates -- +1
	end

	if (crates >= 6 and crates <= 9) then
		return (tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD4") + math.floor((crates - 4) / 2)) * crates -- +0
	end

	if (crates >= 10 and crates <= 110) then
		return (tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD7") + math.floor((crates - 10) / 5)) * crates -- +3
	end

	if (crates == 111) then
		return tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD21") * 111 -- + 14
	end

	return 0
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
