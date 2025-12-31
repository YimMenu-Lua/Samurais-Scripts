---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

-- Unfinished, WIP

local FeatureBase = require("includes.modules.FeatureBase")
local CWheel      = require("includes.classes.CWheel")

---@class StanceObject
---@field public m_front_track_width float
---@field public m_rear_track_width float
---@field public m_front_camber float
---@field public m_rear_camber float


---@class Stancer : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_wheel_array atArray<CWheel>
---@field private m_last_tick milliseconds
---@field private m_default_data array<StanceObject>
---@field public m_object_queue array<StanceObject>
local Stancer   = setmetatable({}, FeatureBase)
Stancer.__index = Stancer

---@param pv PlayerVehicle
---@return Stancer
function Stancer.new(pv)
	local self = FeatureBase.new(pv)
	return setmetatable(self, Stancer)
end

function Stancer:Init()
	self.m_last_tick = 0
	self.m_default_data = {}
	self.m_object_queue = {}

	if (self.m_entity:IsValid()) then
		self.m_wheel_array = self.m_entity:Resolve().m_wheels
	end
end

function Stancer:ReadDefaults()
	if (not self.m_entity:IsValid()) then
		return
	end

	self.m_wheel_array = self.m_entity:Resolve().m_wheels
	for i, ptr in self.m_wheel_array:Iter() do
		local cwheel = CWheel(ptr)
		if (not cwheel) then
			return
		end

		self.m_default_data[i] = {
			m_front_camber = self:GetValueByWheelSide(i, cwheel.m_y_rotation:get_float()),
			m_rear_camber = self:GetValueByWheelSide(i, cwheel.m_y_rotation:get_float()),
			m_front_track_width = self:GetValueByWheelSide(i, cwheel.m_x_offset:get_float()),
			m_rear_track_width = self:GetValueByWheelSide(i, cwheel.m_x_offset:get_float()),
		}

		self.m_object_queue[i] = {
			m_front_camber = self:GetValueByWheelSide(i, cwheel.m_y_rotation:get_float()),
			m_rear_camber = self:GetValueByWheelSide(i, cwheel.m_y_rotation:get_float()),
			m_front_track_width = self:GetValueByWheelSide(i, cwheel.m_x_offset:get_float()),
			m_rear_track_width = self:GetValueByWheelSide(i, cwheel.m_x_offset:get_float()),
		}
	end
end

function Stancer:ShouldRun()
	return self.m_entity
		and self.m_entity:IsValid()
		and self.m_entity:IsCar()
end

---@param wheelIndex integer
---@param value number
---@return number
function Stancer:GetValueByWheelSide(wheelIndex, value)
	return wheelIndex % 2 == 0 and value or -value
end

function Stancer:Cleanup()
	if (not self.m_wheel_array) then
		return
	end

	for i, obj in ipairs(self.m_default_data) do
		local cwheel = CWheel(self.m_wheel_array:Get(i))
		if (not cwheel) then
			return
		end

		if (i < 3) then
			if (math.abs(obj.m_front_camber) ~= math.abs(cwheel.m_y_rotation:get_float())) then
				local signed = self:GetValueByWheelSide(i, obj.m_front_camber)
				cwheel.m_y_rotation:set_float(signed)
				cwheel.m_y_rotation_inv:set_float(-signed)
			end

			if (math.abs(obj.m_front_track_width) ~= math.abs(cwheel.m_x_offset:get_float())) then
				cwheel.m_x_offset:set_float(self:GetValueByWheelSide(i, obj.m_front_track_width))
			end
		else
			if (math.abs(obj.m_rear_camber) ~= math.abs(cwheel.m_y_rotation:get_float())) then
				local signed = self:GetValueByWheelSide(i, obj.m_rear_camber)
				cwheel.m_y_rotation:set_float(signed)
				cwheel.m_y_rotation_inv:set_float(-signed)
			end

			if (math.abs(obj.m_rear_track_width) ~= math.abs(cwheel.m_x_offset:get_float())) then
				cwheel.m_x_offset:set_float(self:GetValueByWheelSide(i, obj.m_rear_track_width))
			end
		end
	end
end

function Stancer:Update()
	if (not self.m_wheel_array) then
		self:ReadDefaults()
	end

	-- if (Time.millis() - self.m_last_tick < 5) then -- causes flicker when fighting the game's overrides
	-- 	return
	-- end

	for i, obj in ipairs(self.m_object_queue) do
		local cwheel = CWheel(self.m_wheel_array:Get(i))
		if (not cwheel) then
			return
		end

		if (i < 3) then
			if (math.abs(obj.m_front_camber) ~= math.abs(cwheel.m_y_rotation:get_float())) then
				local signed = self:GetValueByWheelSide(i, obj.m_front_camber)
				cwheel.m_y_rotation:set_float(signed)
				cwheel.m_y_rotation_inv:set_float(-signed)
			end

			if (math.abs(obj.m_front_track_width) ~= math.abs(cwheel.m_x_offset:get_float())) then
				cwheel.m_x_offset:set_float(self:GetValueByWheelSide(i, obj.m_front_track_width))
			end
		else
			if (math.abs(obj.m_rear_camber) ~= math.abs(cwheel.m_y_rotation:get_float())) then
				local signed = self:GetValueByWheelSide(i, obj.m_rear_camber)
				cwheel.m_y_rotation:set_float(signed)
				cwheel.m_y_rotation_inv:set_float(-signed)
			end

			if (math.abs(obj.m_rear_track_width) ~= math.abs(cwheel.m_x_offset:get_float())) then
				cwheel.m_x_offset:set_float(self:GetValueByWheelSide(i, obj.m_rear_track_width))
			end
		end
	end

	-- self.m_last_tick = Time.millis()
end

return Stancer
