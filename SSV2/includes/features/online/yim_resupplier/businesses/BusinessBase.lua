-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local SGSL = require("includes.services.SGSL")

---@class BusinessOpts
---@field id integer
---@field name string
---@field coords? vec3
---@field blip? integer
---@field max_units? integer
---@field size? integer
---@field vpu integer? value per unit


-- Base class for most GTAO businesses.
---@class BusinessBase
---@field private m_id integer **Required:** Represents the in-game index. For Hangar, this should be -1
---@field private m_max_units integer
---@field private m_base_global ScriptGlobal
---@field private m_name? string
---@field private m_coords? vec3
---@field private m_blip? integer
---@field protected m_is_stale boolean
local BusinessBase   = {}
BusinessBase.__index = BusinessBase

---@param opts BusinessOpts
---@return BusinessBase
function BusinessBase.new(opts)
	local g_obj    = SGSL:Get(SGSL.data.mp_business_stuff)
	local SG       = g_obj:AsGlobal()
	local pid      = LocalPlayer:GetID() -- we're reading the player ID once but it's fine since YRV3 reloads on session switch anyway.
	local pid_size = g_obj:GetOffset(1) -- Legacy: 880 / Enhanced: 883
	local offset   = g_obj:GetOffset(2) -- 260
	return setmetatable({
		m_is_stale    = false,
		m_id          = opts.id,
		m_name        = opts.name or "",
		m_coords      = opts.coords,
		m_blip        = opts.blip,
		m_max_units   = opts.max_units,
		m_base_global = SG:At(pid, pid_size):At(offset)
	}, BusinessBase)
end

function BusinessBase:ResetImpl() self.m_is_stale = true end

---@return boolean
function BusinessBase:IsValid() return not self.m_is_stale end

---@return ScriptGlobal
function BusinessBase:GetBaseGlobal() return self.m_base_global end

---@return integer
function BusinessBase:GetIndex() return self.m_id end

---@return string
function BusinessBase:GetName() return self.m_name end

---@return integer
function BusinessBase:GetMaxUnits() return self.m_max_units end

-- Blip ID or vector 3 coordinates.
---@return (integer|vec3)?
function BusinessBase:GetCoords() return self.m_coords or self.m_blip end

---@return integer
function BusinessBase:GetProductValue() return 0 end

---@return integer
function BusinessBase:GetEstimatedIncome()
	if (not self:IsValid()) then return 0 end
	return self:GetProductValue()
end

---@meta

---@virtual
---@return integer
function BusinessBase:GetProductCount() end

---@virtual
---@return integer
function BusinessBase:GetSuppliesCount() end

---@virtual
function BusinessBase:ReStock() end

---@virtual
function BusinessBase:TriggerProduction() end

---@virtual
function BusinessBase:LoopProduction() end

---@virtual
function BusinessBase:Update() end

return BusinessBase
