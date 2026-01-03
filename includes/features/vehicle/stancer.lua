-- Unfinished, WIP

local FeatureBase  = require("includes.modules.FeatureBase")
local CWheel       = require("includes.classes.CWheel")

---@class StanceObject
---@field m_track_width float
---@field m_camber float
---@field m_wheel_width float
---@field m_wheel_size float
local StanceObject = {}

---@return StanceObject
function StanceObject.new()
	return {
		m_track_width = 0.0,
		m_camber      = 0.0,
		m_susp_comp   = 0.0,
		m_wheel_width = 0.0,
		m_wheel_size  = 0.0,
	}
end

---@class Stancer : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_last_tick milliseconds
---@field private m_cached_model hash
---@field public m_base_values table<eWheelSide, StanceObject>
---@field public m_deltas table<eWheelSide, StanceObject>
---@field public m_wheels table<eWheelSide, array<CWheel>>
---@field public m_suspension_height { m_current: float, m_last_seen: float }
---@field public m_is_model_saved boolean
---@field public m_is_active boolean
local Stancer         = setmetatable({}, FeatureBase)
Stancer.__index       = Stancer

---@enum eWheelSide
Stancer.eWheelSide    = {
	FRONT = 1,
	BACK  = 2,
}

Stancer.m_base_values = {
	[Stancer.eWheelSide.FRONT] = StanceObject.new(),
	[Stancer.eWheelSide.BACK]  = StanceObject.new(),
}

Stancer.m_deltas      = {
	[Stancer.eWheelSide.FRONT] = StanceObject.new(),
	[Stancer.eWheelSide.BACK]  = StanceObject.new(),
}

---@alias ptr_read fun(w: CWheel): anyval
---@type array<{ key: string, wheel_side: eWheelSide, read_func: ptr_read, write_func: fun(w: CWheel, v: anyval, veh?: PlayerVehicle), side_dont_care?: boolean}>
Stancer.decorators    = {
	{
		key = "m_camber",
		wheel_side = Stancer.eWheelSide.FRONT,
		read_func = function(w)
			return w.m_y_rotation:get_float()
		end,
		write_func = function(w, v)
			w.m_y_rotation:set_float(v)
			w.m_y_rotation_inv:set_float(-v)
		end
	},
	{
		key = "m_track_width",
		wheel_side = Stancer.eWheelSide.FRONT,
		read_func = function(w)
			return w.m_x_offset:get_float()
		end,
		write_func = function(w, v)
			w.m_x_offset:set_float(v)
		end
	},
	{
		key = "m_susp_comp",
		wheel_side = Stancer.eWheelSide.FRONT,
		side_dont_care = true,
		read_func = function(w)
			return w.m_suspension_compression:get_float()
		end,
		write_func = function(w, v)
			w.m_suspension_compression:set_float(v)
		end
	},
	{
		key = "m_wheel_width",
		wheel_side = Stancer.eWheelSide.FRONT, -- doesn't matter
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
		key = "m_wheel_size",
		wheel_side = Stancer.eWheelSide.FRONT, -- doesn't matter
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
		key = "m_camber",
		wheel_side = Stancer.eWheelSide.BACK,
		read_func = function(w)
			return w.m_y_rotation:get_float()
		end,
		write_func = function(w, v)
			w.m_y_rotation:set_float(v)
			w.m_y_rotation_inv:set_float(-v)
		end
	},
	{
		key = "m_track_width",
		wheel_side = Stancer.eWheelSide.BACK,
		read_func = function(w)
			return w.m_x_offset:get_float()
		end,
		write_func = function(w, v)
			w.m_x_offset:set_float(v)
		end
	},
	{
		key = "m_susp_comp",
		wheel_side = Stancer.eWheelSide.BACK,
		side_dont_care = true,
		read_func = function(w)
			return w.m_suspension_compression:get_float()
		end,
		write_func = function(w, v)
			w.m_suspension_compression:set_float(v)
		end
	},
}

---@param pv PlayerVehicle
---@return Stancer
function Stancer.new(pv)
	local self = FeatureBase.new(pv)
	---@diagnostic disable-next-line
	return setmetatable(self, Stancer)
end

function Stancer:Init()
	self.m_last_tick = 0
	self.m_suspension_height = {
		m_current = 0.0,
		m_last_seen = 0.0
	}

	if (self.m_entity:IsValid()) then
		self:ReadWheelArray()
		self.m_cached_model = self.m_entity:GetModelHash()
	end
end

function Stancer:ShouldRun()
	return self.m_entity and self.m_entity:IsValid()
end

---@return boolean
function Stancer:CanApplyDrawData()
	return self.m_entity and self.m_entity:HasWheelDrawData()
end

function Stancer:Reset()
	if (not self.m_wheels) then
		return
	end

	self.m_suspension_height.m_current   = 0.0
	self.m_suspension_height.m_last_seen = 0.0

	for _, v in ipairs(self.decorators) do
		self.m_deltas[v.wheel_side][v.key] = 0.0
		local wheel_array = self:GetAllWheelsForSide(v.wheel_side)
		self:ForEach(wheel_array, function(i, cwheel)
			local decor_key = _F("%s_%d", v.key, i)
			local default = Decorator:GetDecor(self.m_entity:GetHandle(), decor_key)
			if (type(default) == "number") then
				v.write_func(cwheel, default, self.m_entity)
			end
		end)
	end

	if (self.m_entity and self.m_entity:IsValid()) then
		self.m_entity:SetRideHeight(0.0)
		local visual_size  = Decorator:GetDecor(self.m_entity:GetHandle(), "m_visual_size")
		local visual_width = Decorator:GetDecor(self.m_entity:GetHandle(), "m_visual_width")
		if (visual_size and visual_size > 0) then
			self.m_entity:SetVisualWheelSize(visual_size)
		end
		if (visual_width and visual_width > 0) then
			self.m_entity:SetVisualWheelWidth(visual_width)
		end
	end
end

function Stancer:Cleanup()
	if (not self.m_wheels) then
		return
	end

	self:Reset()
	Decorator:RemoveEntity(self.m_entity:GetHandle())
	self.m_cached_model = nil
end

-- Main entry
function Stancer:OnNewVehicle()
	if (not self.m_entity or not self.m_entity:IsValid()) then
		return
	end

	self.m_cached_model = self.m_entity:GetModelHash()
	self:ReadDefaults()
	if (self:IsVehicleModelSaved() and GVars.features.vehicle.stancer.auto_apply_saved) then
		self:LoadSavedDeltas()
	end
end

---@param wheelIndex integer
---@param value number
---@return number
function Stancer:GetValueByWheelIndex(wheelIndex, value)
	-- this is not flipped. default values are referenced from the first wheel per side (front/back)
	return wheelIndex == 1 and value or -value
end

---@param array array<CWheel>?
---@param fn function
function Stancer:ForEach(array, fn)
	if (not array or #array == 0) then
		return
	end

	for i, v in ipairs(array) do
		if (v and v:IsValid()) then
			fn(i, v)
		end
	end
end

function Stancer:IsVehicleModelSaved()
	if (not self.m_entity or not self.m_entity:IsValid()) then
		return false
	end

	if (not self.m_cached_model) then
		self.m_cached_model = self.m_entity:GetModelHash()
	end

	return GVars.features.vehicle.stancer.saved_models[tostring(self.m_cached_model)] ~= nil
end

function Stancer:ReadWheelArray()
	if (self.m_wheels) then
		return
	end

	self.m_wheels = {
		[self.eWheelSide.FRONT] = {},
		[self.eWheelSide.BACK]  = {}
	}

	local wheel_array = self.m_entity:Resolve().m_wheels
	local wheel_count = self.m_entity:GetNumberOfWheels()
	if (wheel_count == 2) then
		table.insert(self.m_wheels[self.eWheelSide.FRONT], CWheel(wheel_array:Get(1)))
		table.insert(self.m_wheels[self.eWheelSide.BACK], CWheel(wheel_array:Get(2)))
	else
		-- I don't think there are any "cars" in GTA with more or less than 2 front wheels
		local front_count = 2
		local back_count  = wheel_count - front_count
		for i = 1, front_count do
			self.m_wheels[self.eWheelSide.FRONT][i] = CWheel(wheel_array:Get(i))
		end

		if (back_count == 1) then -- I think there's one vehicle with just one back wheel. I have the memory of a goldfish so I can't remember
			self.m_wheels[self.eWheelSide.BACK][1] = CWheel(wheel_array:Get(3))
		else
			for i = 1, back_count do
				self.m_wheels[self.eWheelSide.BACK][i] = CWheel(wheel_array:Get(i + front_count))
			end
		end
	end
end

---@return table<eWheelSide, array<CWheel>>
function Stancer:GetWheels()
	if (not self.m_wheels) then
		self:ReadWheelArray()
	end

	return self.m_wheels
end

---@param side eWheelSide
---@return array<CWheel>?
function Stancer:GetAllWheelsForSide(side)
	self.m_wheels = self:GetWheels()
	if (#self.m_wheels[side] == 0) then
		return
	end

	return self.m_wheels[side]
end

---@param side eWheelSide
---@return CWheel?
function Stancer:GetFirstWheelForSide(side)
	local wheelsbyside = self.m_wheels[side]
	if (#wheelsbyside == 0) then
		return
	end

	return wheelsbyside[1]
end

---@param side eWheelSide
---@param wheel_n integer
---@return CWheel?
function Stancer:GetNthWheelForSide(side, wheel_n)
	local wheelsbyside = self.m_wheels[side]
	local count = #wheelsbyside
	if (count == 0 or wheel_n > count) then
		return
	end

	return self.m_wheels[side][wheel_n]
end

---@return boolean
function Stancer:AreSavedDeltasLoaded()
	if (not self.m_entity or not self.m_entity:IsValid()) then
		return false
	end

	if (not self:IsVehicleModelSaved()) then
		return false
	end

	local model     = tostring(self.m_cached_model or self.m_entity:GetModelHash())
	local saved     = GVars.features.vehicle.stancer.saved_models
	local front_obj = saved[model][tostring(self.eWheelSide.FRONT)]
	local rear_obj  = saved[model][tostring(self.eWheelSide.BACK)]

	if (not front_obj or not rear_obj or next(front_obj) == nil or next(rear_obj) == nil) then
		return false
	end

	local front_match = true
	local rear_match  = true
	for k, v in pairs(self.m_deltas[self.eWheelSide.FRONT]) do
		if (not math.is_equal(v, front_obj[k])) then
			front_match = false
			break
		end
	end

	for k, v in pairs(self.m_deltas[self.eWheelSide.BACK]) do
		if (not math.is_equal(v, rear_obj[k])) then
			rear_match = false
			break
		end
	end

	return front_match and rear_match
end

---@return boolean
function Stancer:AreDefaultsRegistered()
	if (not self.m_wheels) then
		return false
	end

	local handle = self.m_entity:GetHandle()
	for _, v in ipairs(self.decorators) do
		local wheel_array = self:GetAllWheelsForSide(v.wheel_side)
		for i = 1, #wheel_array do
			local decor = _F("%s_%d", v.key, i)
			if (not Decorator:ExistsOn(handle, decor)) then
				return false
			end
		end
	end

	return true
end

---@return boolean
function Stancer:LoadSavedDeltas()
	if (not self.m_entity or not self.m_entity:IsValid()) then
		return false
	end

	if (not self:IsVehicleModelSaved()) then
		return false
	end

	local model     = tostring(self.m_cached_model or self.m_entity:GetModelHash())
	local saved     = GVars.features.vehicle.stancer.saved_models
	local front_obj = saved[model][tostring(self.eWheelSide.FRONT)]
	local rear_obj  = saved[model][tostring(self.eWheelSide.BACK)]

	if (not front_obj or not rear_obj or next(front_obj) == nil or next(rear_obj) == nil) then
		return false
	end

	for k, v in pairs(front_obj) do
		self.m_deltas[self.eWheelSide.FRONT][k] = v
	end

	for k, v in pairs(rear_obj) do
		self.m_deltas[self.eWheelSide.BACK][k] = v
	end

	self.m_suspension_height.m_current = saved[model]["m_suspension_height"] or 0.0

	return true
end

function Stancer:SaveCurrentVehicle()
	local model = self.m_cached_model or self.m_entity:GetModelHash()
	local __t = {
		[self.eWheelSide.FRONT] = StanceObject.new(),
		[self.eWheelSide.BACK] = StanceObject.new(),
		m_suspension_height = self.m_suspension_height.m_current
	}

	for k, v in pairs(self.m_deltas[self.eWheelSide.FRONT]) do
		__t[self.eWheelSide.FRONT][k] = v
	end

	for k, v in pairs(self.m_deltas[self.eWheelSide.BACK]) do
		__t[self.eWheelSide.BACK][k] = v
	end

	GVars.features.vehicle.stancer.saved_models[tostring(model)] = table.copy(__t)
end

---@return boolean
function Stancer:RestoreQueueFromDecors()
	local handle = self.m_entity:GetHandle()
	if (not Decorator:IsEntityRegistered(handle)) then
		return false
	end

	local success = true
	for _, v in ipairs(self.decorators) do
		local queued_key = _F("%s_%d_queue", v.key, v.wheel_side)
		local val = Decorator:GetDecor(handle, queued_key)
		if (type(val) ~= "number") then
			success = false
		else
			self.m_deltas[v.wheel_side][v.key] = val
		end
	end

	local suspension = Decorator:GetDecor(handle, "m_suspension_height_q")
	if (type(suspension) ~= "number") then
		return false
	end

	self.m_suspension_height.m_current = suspension
	return success
end

function Stancer:ReadDefaults()
	if (not self.m_entity:IsValid() or not self.m_entity:IsCar()) then
		return
	end

	local queued_decors_loaded = self:RestoreQueueFromDecors()

	if (self:AreDefaultsRegistered()) then
		return
	end

	for _, v in ipairs(self.decorators) do
		local read_func = v.read_func
		local wheel_array = self:GetAllWheelsForSide(v.wheel_side)
		local visual_size = self.m_entity:GetVisualWheelSize()
		local visual_width = self.m_entity:GetVisualWheelWidth()
		Decorator:Register(self.m_entity:GetHandle(), "m_visual_size", visual_size)
		Decorator:Register(self.m_entity:GetHandle(), "m_visual_width", visual_width)

		self:ForEach(wheel_array, function(i, cwheel)
			local default_val = read_func(cwheel)
			local wheel_key = _F("%s_%d", v.key, i)
			Decorator:Register(self.m_entity:GetHandle(), wheel_key, default_val)

			-- our values are based on the first wheel per axle
			if (i == 1) then
				self.m_base_values[v.wheel_side][v.key] = default_val
				if (not queued_decors_loaded) then
					local pending_key = _F("%s_%d_queue", v.key, v.wheel_side)
					if (not Decorator:ExistsOn(self.m_entity:GetHandle(), pending_key)) then
						Decorator:Register(self.m_entity:GetHandle(), pending_key, default_val)
					end

					self.m_deltas[v.wheel_side][v.key] = 0.0
				end
			end
		end)
	end
end

function Stancer:Update()
	self.m_is_active = self.m_entity:IsCar()

	-- I'm paranoid about unnecessarily calling natives on tick
	-- possible RAGE engine PTSD involved
	self.m_is_model_saved = self:IsVehicleModelSaved()

	if (not self.m_is_active or not self.m_wheels) then
		return
	end

	-- thanks for making me reload this slow ass game 15 times.
	-- here's a guard dog
	if (not self:AreDefaultsRegistered()) then
		return
	end

	-- must have high frequency updates, otherwise wheels will flicker
	-- when the game tries to force-reset them
	if (Game.GetGameTimer() - self.m_last_tick < 5) then
		return
	end

	local handle = self.m_entity:GetHandle()
	if (self.m_suspension_height.m_current ~= self.m_suspension_height.m_last_seen) then
		self.m_entity:SetRideHeight(self.m_suspension_height.m_current)
		self.m_suspension_height.m_last_seen = self.m_suspension_height.m_current
		Decorator:UpdateDecor(handle, "m_suspension_height_q", self.m_suspension_height.m_current)
	end

	for _, v in ipairs(self.decorators) do
		local delta_val = self.m_deltas[v.wheel_side][v.key]
		if (delta_val == 0) then
			goto continue
		end

		local wheel_array = self:GetAllWheelsForSide(v.wheel_side)
		local base_val    = self.m_base_values[v.wheel_side][v.key]
		local pending_key = _F("%s_%d_queue", v.key, v.wheel_side)

		if (not math.is_equal(Decorator:GetDecor(handle, pending_key), base_val)) then
			Decorator:UpdateDecor(handle, pending_key, base_val)
		end

		self:ForEach(wheel_array, function(i, cwheel)
			local desired = v.side_dont_care and base_val + delta_val or
				self:GetValueByWheelIndex(i, base_val + delta_val)

			if (math.abs(desired) ~= math.abs(v.read_func(cwheel))) then
				v.write_func(cwheel, desired, self.m_entity)
			end
		end)

		::continue::
	end

	self.m_last_tick = Game.GetGameTimer()
end

return Stancer
