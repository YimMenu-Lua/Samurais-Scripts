---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

-- Unfinished, WIP

local FeatureBase = require("includes.modules.FeatureBase")
local CWheel      = require("includes.classes.CWheel")


---@class Stancer : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_wheel_array atArray<CWheel>
---@field private m_last_tick milliseconds
---@field public m_suspension_offsets { front: float, rear: float }
---@field public m_is_active boolean
local Stancer = setmetatable({}, FeatureBase)
Stancer.__index = Stancer
Stancer.m_queue = {
	m_front_track_width_queue = 0.0,
	m_rear_track_width_queue  = 0.0,
	m_front_camber_queue      = 0.0,
	m_rear_camber_queue       = 0.0,
	m_wheel_width_queue       = 0.0,
	m_wheel_size_queue        = 0.0
}

---@alias ptr_read fun(w: CWheel): anyval
---@type array<{ default_key: string, wheel_index: integer, read_func: ptr_read, write_func: fun(w: CWheel, v: anyval, veh?: PlayerVehicle), side_dont_care?: boolean}>
Stancer.decorators = {
	{
		default_key = "m_front_camber",
		wheel_index = 2,
		read_func = function(w)
			return w.m_y_rotation:get_float()
		end,
		write_func = function(w, v)
			w.m_y_rotation:set_float(v)
			w.m_y_rotation_inv:set_float(-v)
		end
	},
	{
		default_key = "m_front_track_width",
		wheel_index = 2,
		read_func = function(w)
			return w.m_x_offset:get_float()
		end,
		write_func = function(w, v)
			w.m_x_offset:set_float(v)
		end
	},
	{
		default_key = "m_wheel_width",
		wheel_index = 2,
		side_dont_care = true,
		read_func = function(w)
			return w.m_tire_width:get_float()
		end,
		write_func = function(w, v, veh)
			w.m_tire_width:set_float(v)
			veh:SetVisualWheelWidth(v * 2)
		end
	},
	{
		default_key = "m_wheel_size",
		wheel_index = 2,
		side_dont_care = true,
		read_func = function(w)
			return w.m_tire_radius:get_float()
		end,
		write_func = function(w, v, veh)
			w.m_tire_radius:set_float(v)
			veh:SetVisualWheelSize(v * 2)
		end
	},
	{
		default_key = "m_rear_camber",
		wheel_index = 4,
		read_func = function(w)
			return w.m_y_rotation:get_float()
		end,
		write_func = function(w, v)
			w.m_y_rotation:set_float(v)
			w.m_y_rotation_inv:set_float(-v)
		end
	},
	{
		default_key = "m_rear_track_width",
		wheel_index = 4,
		read_func = function(w)
			return w.m_x_offset:get_float()
		end,
		write_func = function(w, v)
			w.m_x_offset:set_float(v)
		end
	},
}

---@param pv PlayerVehicle
---@return Stancer
function Stancer.new(pv)
	local self = FeatureBase.new(pv)
	return setmetatable(self, Stancer)
end

function Stancer:Init()
	self.m_last_tick = 0
	self.m_suspension_offsets = {
		front = 0.0,
		rear  = 0.0
	}

	if (self.m_entity:IsValid()) then
		self.m_wheel_array = self.m_entity:Resolve().m_wheels
	end
end

---@return boolean
function Stancer:AreDefaultsRegistered()
	local handle = self.m_entity:GetHandle()
	for _, decor in ipairs(self.decorators) do
		if (not Decorator:ExistsOn(handle, decor.default_key)) then
			return false
		end
	end

	return true
end

function Stancer:ReadDefaults()
	if (not self.m_entity:IsValid() or not self.m_entity:IsCar()) then
		return
	end

	if (self:AreDefaultsRegistered()) then
		return
	end

	self.m_wheel_array = self.m_entity:Resolve().m_wheels
	for _, v in ipairs(self.decorators) do
		local key = v.default_key
		local pending_key = key .. "_queue"
		local read_func = v.read_func
		local cwheel = CWheel(self.m_wheel_array:Get(v.wheel_index))
		if (not cwheel or not cwheel:IsValid()) then
			break
		end

		local default_val = read_func(cwheel)
		Decorator:Register(self.m_entity:GetHandle(), key, default_val)
		Decorator:Register(self.m_entity:GetHandle(), pending_key, default_val)
		self.m_queue[pending_key] = default_val
	end
end

function Stancer:ShouldRun()
	return self.m_entity and self.m_entity:IsValid()
end

---@param wheelIndex integer
---@param value number
---@return number
function Stancer:GetValueByWheelSide(wheelIndex, value)
	return wheelIndex % 2 == 0 and value or -value
end

---@return boolean
function Stancer:CanApplyDrawData()
	return self.m_entity and self.m_entity:HasWheelDrawData()
end

function Stancer:Cleanup()
	if (not self.m_wheel_array) then
		return
	end

	if (not self:AreDefaultsRegistered()) then
		return
	end

	for _, v in ipairs(self.decorators) do
		local num_wheels  = self.m_entity:GetNumberOfWheels()
		local wheel_range = v.wheel_index == 2 and Range(1, 2) or Range(3, num_wheels)
		local default_val = Decorator:GetDecor(self.m_entity:GetHandle(), v.default_key)
		if (not default_val or type(default_val) ~= "number") then
			break
		end

		for i in wheel_range:Iter() do
			local cwheel = CWheel(self.m_wheel_array:Get(i))
			if (not cwheel) then
				break
			end

			local val = v.side_dont_care and default_val or self:GetValueByWheelSide(i, default_val)
			v.write_func(cwheel, val, self.m_entity)
		end
	end
end

function Stancer:Update()
	self.m_is_active = self.m_entity:IsCar()

	if (not self.m_is_active or not self.m_wheel_array) then
		return
	end

	-- thanks for making me reload this slow ass game 15 times.
	-- here's a guard dog
	if (not self:AreDefaultsRegistered()) then
		return
	end

	if (Game.GetGameTimer() - self.m_last_tick < 5) then
		return
	end

	for _, v in ipairs(self.decorators) do
		local queued_key  = v.default_key .. "_queue"
		local queued_val  = self.m_queue[queued_key]
		local num_wheels  = self.m_entity:GetNumberOfWheels()
		local wheel_range = v.wheel_index == 2 and Range(1, 2) or Range(3, num_wheels)

		for i in wheel_range:Iter() do
			local cwheel = CWheel(self.m_wheel_array:Get(i))
			if (not cwheel) then
				break
			end

			local current_val = v.read_func(cwheel)
			if (math.abs(queued_val) ~= math.abs(current_val)) then
				local val = v.side_dont_care and queued_val or self:GetValueByWheelSide(i, queued_val)
				v.write_func(cwheel, val, self.m_entity)
				Decorator:UpdateDecor(self.m_entity:GetHandle(), queued_key, queued_val)
			end
		end
	end

	self.m_last_tick = Game.GetGameTimer()
end

return Stancer
