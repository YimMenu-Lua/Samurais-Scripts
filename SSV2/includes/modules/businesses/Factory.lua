-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessBase = require("includes.modules.businesses.BusinessBase")
local SGSL         = require("includes.services.SGSL")

---@class FactoryOpts : BusinessOpts
---@field max_units integer
---@field name string
---@field vpu integer Base Value Per Unit
---@field vpu_mult_1 integer Value Per Unit with equipment upgrade
---@field vpu_mult_2 integer Value Per Unit with staff upgrade
---@field normalized_name? string
---@field coords? vec3


-- Class representing a business that turns materials into product.
--
-- Can be any MC business including Bunker and Acid Lab.
---@class Factory : BusinessBase
---@field private m_id integer
---@field private m_name string
---@field private m_normalized_name? string
---@field private m_coords vec3
---@field private m_max_units integer
---@field private m_vpu integer
---@field private m_equipment_upgrade boolean
---@field private m_staff_upgrade boolean
---@field private m_fast_prod_running boolean
---@field public fast_prod_enabled boolean
local Factory   = setmetatable({}, BusinessBase)
Factory.__index = Factory

---@param opts FactoryOpts
---@return Factory
function Factory.new(opts)
	assert(type(opts.max_units) == "number", "Missing argument: max_units<integer>")
	assert(type(opts.id) == "number" and math.is_inrange(opts.id, 0, 6), "Invalid Biker Business id.")

	local base                   = BusinessBase.new(opts)
	local instance               = setmetatable(base, Factory)
	instance.m_normalized_name   = opts.normalized_name
	instance.fast_prod_enabled   = false
	instance.m_fast_prod_running = false


	local base_vpu               = opts.vpu
	local mult_1                 = opts.vpu_mult_1 or 0
	local mult_2                 = opts.vpu_mult_2 or 0
	instance.m_vpu               = base_vpu + mult_1 + mult_2
	instance.m_equipment_upgrade = mult_1 > 0
	instance.m_staff_upgrade     = mult_2 > 0
	---@diagnostic disable-next-line
	return instance
end

function Factory:Reset()
	self.fast_prod_enabled = false
	self.m_fast_prod_running = false
	self:ResetImpl()
end

---@return string?
function Factory:GetNormalizedName()
	return self.m_normalized_name
end

function Factory:IsSetup()
	return stats.get_int(_F("MPX_FACTORYSETUP%d", self.m_id))
end

---@return integer
function Factory:GetSuppliesCount()
	return stats.get_int(_F("MPX_MATTOTALFORFACTORY%d", self.m_id))
end

---@return integer
function Factory:GetProductCount()
	return stats.get_int(_F("MPX_PRODTOTALFORFACTORY%d", self.m_id))
end

---@return integer
function Factory:GetProductValue()
	return math.floor(self:GetProductCount() * self.m_vpu)
end

function Factory:ReStock()
	if (not self:IsValid() or not self:IsSetup()) then
		return
	end

	if (self:HasFullSupplies()) then
		local name = self:GetNormalizedName() or self:GetName()
		Notifier:ShowError(name, _T("YRV3_RESTOCK_ERR"))
		return
	end

	SGSL:Get(SGSL.data.freemode_business_global)
		:AsGlobal()
		:At(1, self.m_id)
		:WriteInt(1)
end

---@return milliseconds
function Factory:GetTimeLeftBeforeProd()
	local g_obj      = SGSL:Get(SGSL.data.biker_prod_time_global)
	local pid_size   = g_obj:GetOffset(1)
	local offset_2   = g_obj:GetOffset(2)
	local offset_3   = g_obj:GetOffset(3)
	local index_size = g_obj:GetOffset(4)
	return g_obj:AsGlobal()
		:At(LocalPlayer:GetPlayerID(), pid_size)
		:At(offset_2)
		:At(offset_3)
		:At(self.m_id, index_size)
		:At(9)
		:ReadInt()
end

function Factory:TriggerProduction()
	if (not self:IsValid() or not self:IsSetup()) then
		return
	end

	if (self:HasFullProduction()) then
		local name = self:GetNormalizedName() or self:GetName()
		Notifier:ShowError(name, _T("YRV3_FAST_PROD_ERR"))
		return
	end

	local g_obj      = SGSL:Get(SGSL.data.biker_prod_time_global)
	local pid_size   = g_obj:GetOffset(1)
	local offset_2   = g_obj:GetOffset(2)
	local offset_3   = g_obj:GetOffset(3)
	local index_size = g_obj:GetOffset(4)
	local global     = g_obj:AsGlobal()
		:At(LocalPlayer:GetPlayerID(), pid_size)
		:At(offset_2)
		:At(offset_3)
		:At(self.m_id, index_size)
		:At(9)

	if (global:ReadInt() < 1000) then
		return
	end

	global:WriteInt(100)
end

---@return boolean
function Factory:HasFullSupplies()
	return self:GetSuppliesCount() == 100
end

---@return boolean
function Factory:HasFullProduction()
	return self:GetProductCount() == self.m_max_units
end

---@return boolean
function Factory:HasEquipmentUpgrade()
	return self.m_equipment_upgrade
end

---@return boolean
function Factory:HasStaffUpgrade()
	return self.m_staff_upgrade
end

---@return boolean
function Factory:CanTriggerProduction()
	return self:GetTimeLeftBeforeProd() > 1000
end

---@private
function Factory:LoopProduction()
	ThreadManager:Run(function()
		while (self:IsValid() and self.fast_prod_enabled and not self:HasFullProduction()) do
			if (self:GetSuppliesCount() <= 25) then
				self:ReStock()
				sleep(250)
			end

			self:TriggerProduction()
			yield()
		end

		self.fast_prod_enabled = false
		self.m_fast_prod_running = false
	end)
end

function Factory:Update()
	if (not self:IsValid() or not self:IsSetup()) then
		return
	end

	if (self.fast_prod_enabled and not self.m_fast_prod_running and not self:HasFullProduction()) then
		self.m_fast_prod_running = true
		self:LoopProduction()
	end

	-- more stuff later
end

return Factory
