---@class VehicleFeatureBase
---@field protected m_pv PlayerVehicle
---@field protected m_active boolean
local VehicleFeatureBase = {}
VehicleFeatureBase.__index = VehicleFeatureBase
setmetatable(VehicleFeatureBase, {
    __call = function (_, pv)
        return VehicleFeatureBase.new(pv)
    end
})

---@param pv PlayerVehicle
function VehicleFeatureBase.new(pv)
    return setmetatable({
        m_pv = pv,
        active = true
    }, VehicleFeatureBase)
end

---@return boolean
function VehicleFeatureBase:IsActive()
    return self.m_active and self.m_pv and self.m_pv:IsValid()
end

function VehicleFeatureBase:Init() end
function VehicleFeatureBase:ShouldRun() end
function VehicleFeatureBase:Update() end
function VehicleFeatureBase:PostUpdate() end
function VehicleFeatureBase:OnEnterVehicle() end
function VehicleFeatureBase:OnLeaveVehicle() end
function VehicleFeatureBase:Cleanup() end

return VehicleFeatureBase
