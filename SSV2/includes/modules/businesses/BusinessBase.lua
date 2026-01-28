-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@meta

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
---@field private m_name? string
---@field private m_coords? vec3
---@field private m_blip? integer
---@field protected m_is_stale boolean
local BusinessBase = {}
BusinessBase.__index = BusinessBase

---@param opts BusinessOpts
---@return BusinessBase
function BusinessBase.new(opts)
	return setmetatable({
		m_is_stale  = false,
		m_id        = opts.id,
		m_name      = opts.name or "",
		m_coords    = opts.coords,
		m_blip      = opts.blip,
		m_max_units = opts.max_units
		---@diagnostic disable-next-line
	}, BusinessBase)
end

function BusinessBase:ResetImpl() self.m_is_stale = true end

---@return boolean
function BusinessBase:IsValid() return not self.m_is_stale end

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
function BusinessBase:GetEstimatedValue() return self:GetProductValue() end

---@return integer
function BusinessBase:GetProductCount() end

---@return integer
function BusinessBase:GetProductValue() return 0 end

---@return integer
function BusinessBase:GetSuppliesCount() end

function BusinessBase:ReStock() end

function BusinessBase:TriggerProduction() end

function BusinessBase:LoopProduction() end

return BusinessBase
