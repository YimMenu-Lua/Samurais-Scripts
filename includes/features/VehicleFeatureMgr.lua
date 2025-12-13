-- Registers and runs lightweight features.
--
-- If your feature has a function that needs to yield or sleep, have it register its own thread in its Init() method *(refer to VehicleFeatureBase)*
--
-- and name your function that will run in a thread anything other than `Update()`.
---@class VehicleFeatureMgr
---@field private m_pv PlayerVehicle
---@field private m_features VehicleFeatureBase[]
local VehicleFeatureMgr = {}
VehicleFeatureMgr.__index = VehicleFeatureMgr

---@param pv PlayerVehicle
function VehicleFeatureMgr.new(pv)
	local instane = setmetatable({
		m_pv = pv,
		m_features = {}
	}, VehicleFeatureMgr)

	return instane
end

---@generic T : VehicleFeatureBase
---@param feature VehicleFeatureBase
---@return T
function VehicleFeatureMgr:Add(feature)
	feature:Init()
	table.insert(self.m_features, feature)
	return feature
end

function VehicleFeatureMgr:Update()
	for _, feat in ipairs(self.m_features) do
		if (feat:ShouldRun()) then
			feat:Update()
		end
	end
end

function VehicleFeatureMgr:PostUpdate()
	for _, feat in ipairs(self.m_features) do
		if (feat:ShouldRun()) then
			feat:PostUpdate()
		end
	end
end

function VehicleFeatureMgr:OnEnterVehicle()
	for _, feat in ipairs(self.m_features) do
		feat:OnEnterVehicle()
	end
end

function VehicleFeatureMgr:OnLeaveVehicle()
	for _, feat in ipairs(self.m_features) do
		feat:OnLeaveVehicle()
	end
end

function VehicleFeatureMgr:Cleanup()
	for _, feat in ipairs(self.m_features) do
		pcall(function()
			feat:Cleanup()
		end)
	end
end

return VehicleFeatureMgr
