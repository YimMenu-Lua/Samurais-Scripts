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
---@field private m_prod_count_stat string
---@field private m_prod_time_g ScriptGlobal
---@field private m_prod_bool_g ScriptGlobal
---@field private m_tech_idx_g ScriptGlobal
---@field private m_tech_stopwatch_g ScriptGlobal
---@field private m_fast_prod_running boolean
---@field public fast_prod_enabled boolean
local BusinessHub   = setmetatable({}, BusinessBase)
BusinessHub.__index = BusinessHub

---@param opts HubOpts
---@return BusinessHub
function BusinessHub.new(opts)
	assert(type(opts.max_units) == "number", "Missing argument: max_units<integer>")
	local id = opts.id
	assert(type(opts.id) == "number" and math.is_inrange(opts.id, 0, 6), "Invalid Business Hub id.")

	local base                  = BusinessBase.new(opts)
	local instance              = setmetatable(base, BusinessHub) ---@cast instance BusinessHub
	instance.m_prod_count_stat  = _F("MPX_HUB_PROD_TOTAL_%d", id)
	instance.fast_prod_enabled  = false
	instance.fast_prod_running  = false
	instance.m_vpu              = opts.vpu

	local sgslObj               = SGSL:Get(SGSL.data.bhub_prod_time_global)
	local globalIndex           = sgslObj:GetValue()
	instance.m_prod_time_g      = ScriptGlobal(globalIndex):At(1, base:GetIndex())
	instance.m_tech_stopwatch_g = ScriptGlobal(globalIndex - 19)
	instance.m_prod_bool_g      = SGSL:Get(SGSL.data.bhub_prod_bool_global):AsGlobal()
	instance.m_tech_idx_g       = base:GetBaseGlobal():At(321)

	return instance
end

function BusinessHub:Reset()
	self.fast_prod_enabled = false
	self.fast_prod_running = false
end

---@return integer
function BusinessHub:GetProductCount()
	return stats.get_int(self.m_prod_count_stat)
end

---@return integer
function BusinessHub:GetProductValue()
	return math.floor(self:GetProductCount() * self.m_vpu)
end

---@private
---@param techIndex integer `0..5`
---@return integer offset, integer bitPos
function BusinessHub:GetTechOffsetAndBitPos(techIndex)
	local idx    = self:GetIndex()
	local bitPos = idx
	local offset = 3
	if (techIndex < 4) then
		bitPos = (techIndex * 7) + idx
		offset = 2
	end
	return offset, bitPos
end

-- `BOOL func_19854(int iParam0, int iParam1) // Position - 0x5FD381 (6280065) (legacy b3788.0)`
---@private
---@param techIndex integer `0..5`
---@return boolean
function BusinessHub:IsTechAssignedToThis(techIndex)
	local offset, bitPos = self:GetTechOffsetAndBitPos(techIndex)
	return self.m_tech_idx_g:At(offset):GetBit(bitPos) ~= 0
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

---@nodiscard
---@return boolean
function BusinessHub:HasTechnician()
	return self:GetAssignedTechIndex() ~= -1
end

---@return boolean success
function BusinessHub:RemoveTechnician()
	local techIndex = self:GetAssignedTechIndex()
	if (techIndex == -1) then return false end

	local offset, bitPos = self:GetTechOffsetAndBitPos(techIndex)
	self.m_tech_idx_g:At(offset):ClearBit(bitPos)
	self.m_tech_stopwatch_g:At(techIndex, 2):WriteInt(0)
	return true
end

---@param techIndex integer `0..5`
---@return boolean success
function BusinessHub:AssignTechnician(techIndex)
	local current = self:GetAssignedTechIndex()
	if (techIndex == -1 or techIndex == current) then
		return false
	end

	if (current ~= -1) then
		self:RemoveTechnician()
	end

	local offset, bitPos = self:GetTechOffsetAndBitPos(techIndex)
	self.m_tech_idx_g:At(offset):SetBit(bitPos)
	return true
end

---@return milliseconds
function BusinessHub:GetTimeLeftBeforeProd()
	return self.m_prod_time_g:ReadInt()
end

-- Do not directly call this private function, it does not perform any sanity checks.
---@private
---@param count integer
function BusinessHub:SetProductCount(count)
	local idx = self.m_id
	self.m_tech_idx_g:At(8):At(1, idx):WriteInt(count)
	stats.set_int(self.m_prod_count_stat, count)
end

---@param count? integer
function BusinessHub:TriggerProduction(count)
	if (self.m_prod_time_g:ReadInt() < 1000) then
		return
	end

	local max     = self:GetMaxUnits()
	local current = self:GetProductCount()
	local techIdx = self:GetAssignedTechIndex()
	if (techIdx == -1 or current == max) then return end

	-- we're not cehcking if count and count < current so this can also remove product
	local nextVal = math.min(count or (current + 1), max)
	if (nextVal < max) then
		self:SetProductCount(nextVal)
	else
		self.m_tech_stopwatch_g:At(techIdx, 2):WriteInt(0)
		self.m_prod_time_g:WriteInt(0)
		self.m_prod_bool_g:WriteInt(1)
	end
end

-- https://www.youtube.com/watch?v=-Gh1lTcwdGY
function BusinessHub:InstantFillProduction()
	self:TriggerProduction(self:GetMaxUnits() - 1)
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
			yield(250)
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
