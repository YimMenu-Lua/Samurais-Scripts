-- Registers and runs lightweight features.
--
-- If your feature has a function that needs to yield or sleep, have it register its own thread in its Init() method *(refer to FeatureBase)*
--
-- and name your function that will run in a thread anything other than `Update()`.
---@class FeatureManager
---@field private m_entity PlayerVehicle | Self -- reference to the entity that owns the features
---@field private m_features FeatureBase[]
local FeatureManager = {}
FeatureManager.__index = FeatureManager

---@param entity PlayerVehicle | Self
function FeatureManager.new(entity)
	local instane = setmetatable({
		m_entity = entity,
		m_features = {}
	}, FeatureManager)

	return instane
end

---@generic T : FeatureBase
---@param feature FeatureBase
---@return T
function FeatureManager:Add(feature)
	feature:Init()
	table.insert(self.m_features, feature)
	return feature
end

function FeatureManager:Update()
	for _, feat in ipairs(self.m_features) do
		if (feat:ShouldRun()) then
			feat:Update()
		end
	end
end

function FeatureManager:PostUpdate()
	for _, feat in ipairs(self.m_features) do
		if (feat:ShouldRun()) then
			feat:PostUpdate()
		end
	end
end

function FeatureManager:OnEnable()
	for _, feat in ipairs(self.m_features) do
		feat:OnEnable()
	end
end

function FeatureManager:OnDisable()
	for _, feat in ipairs(self.m_features) do
		feat:OnDisable()
	end
end

function FeatureManager:Cleanup()
	for _, feat in ipairs(self.m_features) do
		pcall(function()
			feat:Cleanup()
		end)
	end
end

return FeatureManager
