-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessBase = require("BusinessBase")
local SGSL         = require("includes.services.SGSL")

---@class HubOpts : BusinessOpts
---@field id integer
---@field max_units integer
---@field name string
---@field vpu integer Base Value Per Unit


-- Class representing a business that accumulates valuable cargo over time *(Nightclub cargo)*.
---@class BusinessHub : BusinessBase
---@field private m_id integer
---@field private m_name string
---@field private m_max_units integer
---@field private m_vpu integer
---@field private m_prod_time_g ScriptGlobal
---@field private m_prod_bool_g ScriptGlobal
---@field private m_tech_global ScriptGlobal
---@field private m_fast_prod_running boolean
---@field public fast_prod_enabled boolean
local BusinessHub   = setmetatable({}, BusinessBase)
BusinessHub.__index = BusinessHub

---@param opts HubOpts
---@return BusinessHub
function BusinessHub.new(opts)
	assert(type(opts.max_units) == "number", "Missing argument: max_units<integer>")

	local base                 = BusinessBase.new(opts)
	local instance             = setmetatable(base, BusinessHub) ---@cast instance BusinessHub
	instance.fast_prod_enabled = false
	instance.fast_prod_running = false
	instance.m_vpu             = opts.vpu
	instance.m_prod_time_g     = SGSL:Get(SGSL.data.bhub_prod_time_global):AsGlobal():At(1, base:GetIndex())
	instance.m_prod_bool_g     = SGSL:Get(SGSL.data.bhub_prod_bool_global):AsGlobal()
	instance.m_tech_global     = base:GetBaseGlobal():At(321)

	return instance
end

function BusinessHub:Reset()
	self.fast_prod_enabled = false
	self.fast_prod_running = false
end

---@return integer
function BusinessHub:GetProductCount()
	assert(type(self.m_id) == "number" and math.is_inrange(self.m_id, 0, 6), "Invalid Business Hub id.")
	return stats.get_int(_F("MPX_HUB_PROD_TOTAL_%d", self.m_id))
end

---@return integer
function BusinessHub:GetProductValue()
	return math.floor(self:GetProductCount() * self.m_vpu)
end

-- `BOOL func_19854(int iParam0, int iParam1) // Position - 0x5FD381 (6280065) (legacy b3788.0)`
---@private
---@param techIndex integer `0..5`
---@return boolean
function BusinessHub:IsTechAssignedToThis(techIndex)
	local idx    = self:GetIndex()
	local bitPos = idx
	local offset = 3
	if (techIndex < 4) then
		bitPos = (techIndex * 7) + idx
		offset = 2
	end
	return Bit.IsBitSet(self.m_tech_global:At(offset):ReadInt(), bitPos)
end

-- `int func_19853(int iParam0) // Position - 0x5FD348 (6280008) (legacy b3788.0)`
--
-- Actually wanted to improve UX with tech names using the return index
--
-- but apparently only Yohan has a name. We should probably return a bool instead
---@return integer TechIndex A number between 0 and 5 or -1 if no one is assigned.
function BusinessHub:GetAssignedTechIndex()
	for i = 0, 5 do
		if (self:IsTechAssignedToThis(i)) then
			return i
		end
	end

	return -1
end

---@return milliseconds
function BusinessHub:GetTimeLeftBeforeProd()
	return self.m_prod_time_g:ReadInt()
end

function BusinessHub:TriggerProduction()
	if (self.m_prod_time_g:ReadInt() < 1000 or self:GetAssignedTechIndex() == -1) then
		return
	end

	self.m_prod_time_g:WriteInt(100)
	self.m_prod_bool_g:WriteInt(1)
end

---@return boolean
function BusinessHub:HasFullProduction()
	return self:GetProductCount() == self.m_max_units
end

---@return boolean
function BusinessHub:CanTriggerProduction()
	return self:GetTimeLeftBeforeProd() > 1000
end

---@private
function BusinessHub:LoopProduction()
	ThreadManager:Run(function()
		while (self:IsValid() and self.fast_prod_enabled and not self:HasFullProduction()) do
			self:TriggerProduction()
			yield()
		end

		self.fast_prod_enabled   = false
		self.m_fast_prod_running = false
	end)
end

function BusinessHub:Update()
	if (not self:IsValid()) then
		return
	end

	if (self.fast_prod_enabled and not self.m_fast_prod_running and not self:HasFullProduction()) then
		if (self:GetAssignedTechIndex() == -1) then
			self.fast_prod_enabled = false
			Notifier:ShowError(self:GetName(), _T("YRV3_HUB_TECH_NOT_ASSIGNED_TT"))
			return
		end

		self.m_fast_prod_running = true
		self:LoopProduction()
	end
end

return BusinessHub
