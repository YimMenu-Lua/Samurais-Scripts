-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class FeatureBase
---@field protected m_entity Entity? -- reference to the entity if one owns the feature
---@field protected m_active boolean
local FeatureBase = {}
FeatureBase.__index = FeatureBase
setmetatable(FeatureBase, {
	__call = function(_, entity)
		return FeatureBase.new(entity)
	end
})

---@param entity Entity?
function FeatureBase.new(entity)
	return setmetatable({
		m_entity = entity,
		m_active = true
	}, FeatureBase)
end

---@return boolean
function FeatureBase:IsActive()
	return self.m_active
end

function FeatureBase:Init() end

function FeatureBase:ShouldRun() end

function FeatureBase:Update() end

function FeatureBase:PostUpdate() end

function FeatureBase:OnEnable() end

function FeatureBase:OnDisable() end

function FeatureBase:OnTick() end

function FeatureBase:Cleanup() end

return FeatureBase
