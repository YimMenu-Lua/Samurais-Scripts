-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase  = require("includes.modules.FeatureBase")
local CWheel       = require("includes.classes.gta.CWheel")

---@class StanceObject
---@field m_track_width float
---@field m_camber float
---@field m_susp_comp float
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
---@field private m_reloading boolean
---@field private m_last_wheels_mod {type: integer, index: integer, var: integer}
---@field private m_last_wheel_mod_check_time seconds
---@field public m_base_values table<eWheelSide, StanceObject>
---@field public m_deltas table<eWheelSide, StanceObject>
---@field public m_wheels table<eWheelSide, array<CWheel>>
---@field public m_suspension_height { m_current: float, m_last_seen: float }
---@field public m_is_active boolean
---@field public m_bounce_mode { enabled: boolean, margin: float, speed: float, last_height_f: float, last_height_r: float, t: milliseconds }
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
		key        = "m_camber",
		wheel_side = Stancer.eWheelSide.FRONT,
		read_func  = function(w) return w.m_y_rotation:get_float() end,
		write_func = function(w, v)
			w.m_y_rotation:set_float(v)
			w.m_y_rotation_inv:set_float(-v)
		end
	},
	{
		key        = "m_track_width",
		wheel_side = Stancer.eWheelSide.FRONT,
		read_func  = function(w) return w.m_x_offset:get_float() end,
		write_func = function(w, v) w.m_x_offset:set_float(v) end
	},
	{
		key            = "m_susp_comp",
		wheel_side     = Stancer.eWheelSide.FRONT,
		side_dont_care = true,
		read_func      = function(w) return w.m_suspension_forward_offset:get_float() end,
		write_func     = function(w, v) w.m_suspension_forward_offset:set_float(v) end
	},
	{
		key            = "m_wheel_width",
		wheel_side     = Stancer.eWheelSide.FRONT, -- doesn't matter
		side_dont_care = true,
		read_func      = function(w) return w.m_tyre_width:get_float() end,
		write_func     = function(w, v, veh)
			w.m_tyre_width:set_float(v)
			local cached = Decorator:GetDecor(veh:GetHandle(), "m_visual_width")
			if (cached and cached > 0 and veh:GetVisualWheelWidth() ~= cached + v) then
				veh:SetVisualWheelWidth(cached + v)
			end
		end
	},
	{
		key            = "m_wheel_size",
		wheel_side     = Stancer.eWheelSide.FRONT, -- doesn't matter
		side_dont_care = true,
		read_func      = function(w) return w.m_tyre_radius:get_float() end,
		write_func     = function(w, v, veh)
			w.m_tyre_radius:set_float(v)
			local cached = Decorator:GetDecor(veh:GetHandle(), "m_visual_size")
			if (cached and cached > 0 and veh:GetVisualWheelSize() ~= cached + v) then
				veh:SetVisualWheelSize(cached + v)
			end
		end
	},
	{
		key        = "m_camber",
		wheel_side = Stancer.eWheelSide.BACK,
		read_func  = function(w) return w.m_y_rotation:get_float() end,
		write_func = function(w, v)
			w.m_y_rotation:set_float(v)
			w.m_y_rotation_inv:set_float(-v)
		end
	},
	{
		key        = "m_track_width",
		wheel_side = Stancer.eWheelSide.BACK,
		read_func  = function(w) return w.m_x_offset:get_float() end,
		write_func = function(w, v) w.m_x_offset:set_float(v) end
	},
	{
		key            = "m_susp_comp",
		wheel_side     = Stancer.eWheelSide.BACK,
		side_dont_care = true,
		read_func      = function(w) return w.m_suspension_forward_offset:get_float() end,
		write_func     = function(w, v) w.m_suspension_forward_offset:set_float(v) end
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
	self.m_last_tick                 = 0
	self.m_last_wheel_mod_check_time = 0
	self.m_reloading                 = false
	self.m_bounce_mode               = {
		enabled = false,
		margin  = 0.09,
		speed   = 0.988,
		t       = 0.0
	}
	self.m_last_wheels_mod           = {
		index = -1,
		type  = -1,
		var   = -1
	}
	self.m_suspension_height         = {
		m_current   = 0.0,
		m_last_seen = 0.0
	}

	self:ResetDeltas()

	if (self.m_entity:IsValid()) then
		local handle = self.m_entity:GetHandle()
		if (not Decorator:IsEntityRegistered(handle)) then
			Decorator:Register(handle, "Stancer", true)
		end

		self:ReadWheelArray()
		self:ReadDefaults()
		self.m_cached_model    = self.m_entity:GetModelHash()
		self.m_last_wheels_mod = self.m_entity:GetCustomWheels()
	end
end

function Stancer:ShouldRun()
	return self.m_entity and self.m_entity:IsValid()
end

---@return boolean
function Stancer:CanApplyDrawData()
	return self.m_entity and self.m_entity:HasWheelDrawData()
		and self.m_last_wheels_mod and self.m_last_wheels_mod.index ~= -1
end

function Stancer:Reset()
	self:ReadWheelArray()
	self:ResetDeltas()

	if not (self.m_entity and self.m_entity:IsValid()) then
		return
	end

	self.m_entity:SetRideHeight(0.0)
	local handle = self.m_entity:GetHandle()
	if (not Decorator:IsEntityRegistered(handle)) then
		return
	end

	local visual_size  = Decorator:GetDecor(handle, "m_visual_size")
	local visual_width = Decorator:GetDecor(handle, "m_visual_width")
	if (visual_size and visual_size > 0) then
		self.m_entity:SetVisualWheelSize(visual_size)
	end

	if (visual_width and visual_width > 0) then
		self.m_entity:SetVisualWheelWidth(visual_width)
	end

	for _, v in ipairs(self.decorators) do
		local wheel_array = self:GetAllWheelsForSide(v.wheel_side)
		self:ForEach(wheel_array, function(i, cwheel)
			local decor_key = _F("%s_%d_%d", v.key, v.wheel_side, i)
			local default   = Decorator:GetDecor(handle, decor_key)
			if (type(default) == "number") then
				v.write_func(cwheel, default, self.m_entity)
			end
		end)
	end
end

function Stancer:Cleanup()
	self:Reset()
	Decorator:RemoveEntity(self.m_entity:GetHandle())
	self.m_cached_model = nil
end

-- Main entry
function Stancer:OnNewVehicle()
	if (not self.m_entity:IsValid()) then
		return
	end

	self.m_reloading = true

	local handle = self.m_entity:GetHandle()
	if (not Decorator:IsEntityRegistered(handle)) then
		Decorator:Register(handle, "Stancer", true)
	end

	self.m_cached_model = self.m_entity:GetModelHash()
	self:ResetDeltas()
	self:ReadWheelArray()
	self:ReadDefaults()

	self.m_reloading = false
end

---@param wheel CWheel
---@param value number
---@return number
function Stancer:GetValueBySideLR(wheel, value)
	return wheel:IsLeftWheel() and value or -value
end

---@param array array<CWheel>?
---@param fn fun(i: integer, cwheel: CWheel)
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

	return GVars.features.vehicle.stancer.saved_models[tostring(self.m_entity:GetModelHash())] ~= nil
end

function Stancer:ResetDeltas()
	for _, v in ipairs(self.decorators) do
		self.m_deltas[self.eWheelSide.FRONT][v.key] = 0.0
		self.m_deltas[self.eWheelSide.BACK][v.key]  = 0.0
	end

	self.m_suspension_height.m_current   = 0.0
	self.m_suspension_height.m_last_seen = 0.0
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
		return {}
	end

	return self.m_wheels[side]
end

---@param side eWheelSide
---@return CWheel?
function Stancer:GetFirstWheelForSide(side)
	local wheelsbyside = self:GetAllWheelsForSide(side)
	if (not wheelsbyside or #wheelsbyside == 0) then
		return
	end

	return wheelsbyside[1]
end

---@param side eWheelSide
---@param wheel_n integer
---@return CWheel?
function Stancer:GetNthWheelForSide(side, wheel_n)
	local wheelsbyside = self:GetAllWheelsForSide(side)
	if (not wheelsbyside) then
		return
	end

	local count = #wheelsbyside
	if (count == 0 or wheel_n > count) then
		return
	end

	return self.m_wheels[side][wheel_n]
end

function Stancer:OnWheelsChanged()
	if (not self.m_entity or not self.m_entity:IsValid()) then
		return
	end

	if (Time.Now() - self.m_last_wheel_mod_check_time < 2) then
		return
	end

	local current = self.m_entity:GetCustomWheels()
	if (not table.is_equal(self.m_last_wheels_mod, current)) then
		self.m_reloading    = true
		local prev_height   = self.m_suspension_height.m_current
		local prev_deltas_f = table.copy(self.m_deltas[self.eWheelSide.FRONT])
		local prev_deltas_r = table.copy(self.m_deltas[self.eWheelSide.BACK])

		self:Cleanup()
		self:OnNewVehicle()
		self.m_last_wheels_mod = self.m_entity:GetCustomWheels()

		for k, v in pairs(prev_deltas_f) do
			self.m_deltas[self.eWheelSide.FRONT][k] = v
		end

		for k, v in pairs(prev_deltas_r) do
			self.m_deltas[self.eWheelSide.BACK][k] = v
		end

		self.m_suspension_height.m_current = prev_height
		self.m_reloading = false
	end

	self.m_last_wheel_mod_check_time = Time.Now()
end

---@return boolean
function Stancer:AreSavedDeltasLoaded()
	if (not self.m_entity or not self.m_entity:IsValid()) then
		return false
	end

	if (not self:IsVehicleModelSaved()) then
		return false
	end

	local model     = tostring(self.m_entity:GetModelHash())
	local saved     = GVars.features.vehicle.stancer.saved_models
	local front_obj = saved[model][tostring(self.eWheelSide.FRONT)]
	local rear_obj  = saved[model][tostring(self.eWheelSide.BACK)]

	if (not front_obj or not rear_obj or next(front_obj) == nil or next(rear_obj) == nil) then
		return false
	end

	for k, v in pairs(self.m_deltas[self.eWheelSide.FRONT]) do
		if (not math.is_equal(v, front_obj[k])) then
			return false
		end
	end

	for k, v in pairs(self.m_deltas[self.eWheelSide.BACK]) do
		if (not math.is_equal(v, rear_obj[k])) then
			return false
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

	local model     = tostring(self.m_entity:GetModelHash())
	local saved     = GVars.features.vehicle.stancer.saved_models
	local front_obj = saved[model][self.eWheelSide.FRONT]
	local rear_obj  = saved[model][self.eWheelSide.BACK]

	if (not front_obj or not rear_obj) then
		return false
	end

	for k, v in pairs(front_obj) do
		if (k == "m_suspension_height") then
			self.m_suspension_height.m_current = v
		else
			self.m_deltas[self.eWheelSide.FRONT][k] = v
		end
	end

	for k, v in pairs(rear_obj) do
		self.m_deltas[self.eWheelSide.BACK][k] = v
	end

	PHYSICS.ACTIVATE_PHYSICS(self.m_entity:GetHandle())
	return true
end

function Stancer:SaveCurrentVehicle()
	local strModel = tostring(self.m_entity:GetModelHash())
	local saved = GVars.features.vehicle.stancer.saved_models
	saved[strModel] = table.copy(self.m_deltas)
	saved[strModel][self.eWheelSide.FRONT]["m_suspension_height"] = self.m_suspension_height.m_current
end

function Stancer:RestoreQueueFromDecors()
	if (self:IsVehicleModelSaved() and GVars.features.vehicle.stancer.auto_apply_saved) then
		return self:LoadSavedDeltas()
	end

	local handle = self.m_entity:GetHandle()
	if (not Decorator:IsEntityRegistered(handle)) then
		return
	end

	for _, v in ipairs(self.decorators) do
		local queued_key = _F("%s_%d_queue", v.key, v.wheel_side)
		local val = Decorator:GetDecor(handle, queued_key)
		if (type(val) == "number") then
			self.m_deltas[v.wheel_side][v.key] = val
		end
	end

	local suspension = Decorator:GetDecor(handle, "m_suspension_height_q")
	if (type(suspension) == "number") then
		self.m_suspension_height.m_current = suspension
	end
end

function Stancer:ReadWheelArray()
	self.m_wheels = {
		[self.eWheelSide.FRONT] = {},
		[self.eWheelSide.BACK]  = {}
	}

	if (not self.m_entity or not self.m_entity:IsValid()) then
		return
	end

	local wheel_array = self.m_entity:Resolve().m_wheels
	local wheel_count = wheel_array:Size()
	for i = 1, wheel_count do
		local cwheel = CWheel(wheel_array:At(i))
		if (not cwheel or not cwheel:IsValid()) then
			goto continue
		end

		if (cwheel:IsRearWheel()) then
			table.insert(self.m_wheels[self.eWheelSide.BACK], cwheel)
		else
			table.insert(self.m_wheels[self.eWheelSide.FRONT], cwheel)
		end

		::continue::
	end
end

function Stancer:ReadDefaults()
	if (not self.m_entity:IsValid() or not self.m_entity:IsCar()) then
		return
	end

	self:RestoreQueueFromDecors()
	local handle       = self.m_entity:GetHandle()
	local visual_size  = self.m_entity:GetVisualWheelSize()
	local visual_width = self.m_entity:GetVisualWheelWidth()
	Decorator:Register(handle, "m_visual_size", visual_size)
	Decorator:Register(handle, "m_visual_width", visual_width)

	for _, v in ipairs(self.decorators) do
		local wheel_array = self:GetAllWheelsForSide(v.wheel_side)
		self:ForEach(wheel_array, function(i, cwheel)
			local decor       = _F("%s_%d_%d", v.key, v.wheel_side, i)
			local existsOn    = Decorator:ExistsOn(handle, decor)
			local default_val = existsOn and Decorator:GetDecor(handle, decor) or v.read_func(cwheel)
			if (not existsOn) then
				Decorator:Register(handle, decor, default_val)
			end

			-- our base values are based on left wheels per axle
			if (cwheel:IsLeftWheel()) then
				self.m_base_values[v.wheel_side][v.key] = default_val
			end
		end)
	end
end

function Stancer:OnBounceModeDisable()
	self.m_reloading = true

	local last_f = self.m_bounce_mode.last_height_f
	local last_r = self.m_bounce_mode.last_height_r

	if (last_f) then
		self.m_deltas[self.eWheelSide.FRONT].m_susp_comp = last_f
		self.m_bounce_mode.last_height_f = nil
	end

	if (last_r) then
		self.m_deltas[self.eWheelSide.BACK].m_susp_comp = last_r
		self.m_bounce_mode.last_height_r = nil
	end

	self.m_reloading = false
end

function Stancer:UpdateBounceMode()
	if (not self.m_bounce_mode.enabled) then
		return
	end

	if (self.m_entity:GetClassID() ~= Enums.eVehicleClasses.SUVs) then
		Notifier:ShowError("Stancer", _T("VEH_STANCE_BOUNCE_MODE_UNAVAIL")) -- it works for all cars but nah.. **REALISM**
		self.m_bounce_mode.enabled = false
		return
	end

	if (not self.m_bounce_mode.last_height_f) then
		self.m_bounce_mode.last_height_f = self.m_deltas[self.eWheelSide.FRONT].m_susp_comp
	end

	if (not self.m_bounce_mode.last_height_r) then
		self.m_bounce_mode.last_height_r = self.m_deltas[self.eWheelSide.BACK].m_susp_comp
	end

	local bm = self.m_bounce_mode
	bm.t = bm.t + Game.GetFrameTime() * bm.speed

	local tri = math.tent(bm.t)
	local n = (tri + 1) * 0.5
	n = math.smooth_step(n)

	local sweep = (n * 2 - 1) * bm.margin


	self.m_deltas[self.eWheelSide.FRONT].m_susp_comp = sweep
	self.m_deltas[self.eWheelSide.BACK].m_susp_comp  = sweep

	if (self.m_entity:IsStopped()) then
		PHYSICS.ACTIVATE_PHYSICS(self.m_entity:GetHandle())
	end
end

function Stancer:Update()
	self.m_is_active = self.m_entity:IsCar()

	if (not self.m_is_active or not self.m_wheels or self.m_reloading) then
		return
	end

	self:OnWheelsChanged()
	self:UpdateBounceMode()

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
		local wheel_array = self:GetAllWheelsForSide(v.wheel_side)
		local delta       = self.m_deltas[v.wheel_side][v.key]
		local base        = self.m_base_values[v.wheel_side][v.key]
		local sum         = base + delta
		local queued_key  = _F("%s_%d_queue", v.key, v.wheel_side)
		if (Decorator:ExistsOn(handle, queued_key)) then
			Decorator:UpdateDecor(handle, queued_key, delta)
		else
			Decorator:Register(handle, queued_key, delta)
		end

		self:ForEach(wheel_array, function(_, cwheel)
			local current = v.read_func(cwheel)
			local desired = v.side_dont_care and sum or self:GetValueBySideLR(cwheel, sum)
			if (math.abs(desired) ~= math.abs(current)) then
				v.write_func(cwheel, desired, self.m_entity)
			end
		end)
	end

	self.m_last_tick = Game.GetGameTimer()
end

return Stancer
