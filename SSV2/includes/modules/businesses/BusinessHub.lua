-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessBase  = require("includes.modules.businesses.BusinessBase")
local SGSL          = require("includes.services.SGSL")

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
---@field private m_fast_prod_running boolean
---@field public fast_prod_enabled boolean
local BusinessHub   = setmetatable({}, BusinessBase)
BusinessHub.__index = BusinessHub

---@param opts HubOpts
---@return BusinessHub
function BusinessHub.new(opts)
	assert(type(opts.max_units) == "number", "Missing argument: max_units<integer>")

	local base                 = BusinessBase.new(opts)
	local instance             = setmetatable(base, BusinessHub)
	instance.fast_prod_enabled = false
	instance.fast_prod_running = false
	instance.m_vpu             = opts.vpu
	---@diagnostic disable-next-line
	return instance
end

function BusinessHub:Reset()
	self.fast_prod_enabled = false
	self.fast_prod_running = false
end

---@return integer
function BusinessHub:GetProductCount()
	assert(type(self.m_id) == "number" and math.isinrange(self.m_id, 0, 6), "Invalid Business Hub id.")
	return stats.get_int(_F("MPX_HUB_PROD_TOTAL_%d", self.m_id))
end

---@return integer
function BusinessHub:GetProductValue()
	return math.floor(self:GetProductCount() * self.m_vpu)
end

---@return milliseconds
function BusinessHub:GetTimeLeftBeforeProd()
	return SGSL:Get(SGSL.data.bhub_prod_time_global)
		:AsGlobal()
		:At(1, self.m_id)
		:ReadInt()
end

function BusinessHub:TriggerProduction()
	local g_ProdTime = SGSL:Get(SGSL.data.bhub_prod_time_global):AsGlobal():At(1, self.m_id)
	local g_ProdBool = SGSL:Get(SGSL.data.bhub_prod_bool_global):AsGlobal()

	if (g_ProdTime:ReadInt() < 1000) then
		return
	end

	g_ProdTime:WriteInt(100)
	g_ProdBool:At(1):At(self.m_id):WriteInt(0)
	g_ProdBool:WriteInt(1)
end

---@return boolean
function BusinessHub:IsFull()
	return self:GetProductCount() == self.m_max_units
end

---@return boolean
function BusinessHub:CanTriggerProduction()
	return self:GetTimeLeftBeforeProd() > 1000
end

function BusinessHub:LoopProduction()
	if (not self.fast_prod_enabled or self.m_fast_prod_running) then
		return
	end

	ThreadManager:Run(function()
		self.m_fast_prod_running = true

		while (self:IsValid() and self.fast_prod_enabled and not self:IsFull()) do
			self:TriggerProduction()
			yield()
		end

		self.fast_prod_enabled = false
		self.m_fast_prod_running = false
	end)
end

return BusinessHub
