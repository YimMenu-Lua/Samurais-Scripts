---@class FeatureBase
---@field protected m_entity PlayerVehicle | Self -- reference to the entity that owns the features
---@field protected m_active boolean
local FeatureBase = {}
FeatureBase.__index = FeatureBase
setmetatable(FeatureBase, {
	__call = function(_, pv)
		return FeatureBase.new(pv)
	end
})

---@param entity PlayerVehicle | Self
function FeatureBase.new(entity)
	return setmetatable({
		m_entity = entity,
		m_active = true
	}, FeatureBase)
end

---@return boolean
function FeatureBase:IsActive()
	return self.m_active and self.m_entity and self.m_entity:IsValid()
end

function FeatureBase:Init() end

function FeatureBase:ShouldRun() end

function FeatureBase:Update() end

function FeatureBase:PostUpdate() end

function FeatureBase:OnEnable() end

function FeatureBase:OnDisable() end

function FeatureBase:Cleanup() end

return FeatureBase
