---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local FeatureBase = require("includes.modules.FeatureBase")
local StateMachine = require("includes.structs.StateMachine")

---@class FlappyDoors : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_is_active boolean
---@field private m_state_machine StateMachine
local FlappyDoors = setmetatable({}, FeatureBase)
FlappyDoors.__index = FlappyDoors

---@param pv PlayerVehicle
---@return FlappyDoors
function FlappyDoors.new(pv)
	local self = FeatureBase.new(pv)
	return setmetatable(self, FlappyDoors)
end

function FlappyDoors:Init()
	self.m_is_active = false
	self.m_state_machine = StateMachine({
		predicate = function(_, veh)
			return veh:IsValid() and veh:IsCar()
		end,
		interval = 0.6,
	})
end

function FlappyDoors:ShouldRun()
	return (self.m_entity
		and self.m_entity:IsValid()
		and self.m_entity:IsCar()
		and GVars.features.vehicle.flappy_doors
	)
end

function FlappyDoors:Update()
	local PV = self.m_entity
	local handle = PV:GetHandle()
	self.m_state_machine:Update(PV)

	if (not self.m_state_machine:IsActive()) then
		return
	end

	for i = 0, VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(handle) + 1 do
		if (not VEHICLE.GET_IS_DOOR_VALID(handle, i)) then
			goto continue
		end

		local angle = VEHICLE.GET_VEHICLE_DOOR_ANGLE_RATIO(handle, i)
		if (self.m_state_machine:IsToggled()) then
			if (angle < 1) then
				VEHICLE.SET_VEHICLE_DOOR_OPEN(handle, i, false, false)
			end
		else
			if (angle > 0) then
				VEHICLE.SET_VEHICLE_DOOR_SHUT(handle, i, false)
			end
		end

		::continue::
	end
end

return FlappyDoors
