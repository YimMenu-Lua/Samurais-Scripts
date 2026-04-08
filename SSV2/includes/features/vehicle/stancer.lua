-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")
local CWheel      = require("includes.classes.gta.CWheel")
local StancerData = require("includes.data.stancer_data")


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

--------------------------------------
-- Class: Stancer
--------------------------------------
---@class Stancer : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_last_tick milliseconds
---@field private m_cached_model hash
---@field private m_reloading boolean
---@field private m_last_wheels_mod {type: integer, index: integer, var: integer}
---@field private m_last_wheel_mod_check_time seconds
---@field private m_json_filename "stancer.json"
---@field public m_base_values table<eWheelAxle, StanceObject>
---@field public m_deltas table<eWheelAxle, StanceObject>
---@field public m_wheels table<eWheelAxle, array<CWheel>>
---@field public m_suspension_height { m_current: float, m_last_seen: float }
---@field public m_is_active boolean
---@field public m_bounce_mode { enabled: boolean, margin: float, speed: float, last_height_f: float, last_height_r: float, t: milliseconds }
local Stancer   = setmetatable({
	m_base_values   = {
		[Enums.eWheelAxle.FRONT] = StanceObject.new(),
		[Enums.eWheelAxle.REAR]  = StanceObject.new(),
	},
	m_deltas        = {
		[Enums.eWheelAxle.FRONT] = StanceObject.new(),
		[Enums.eWheelAxle.REAR]  = StanceObject.new(),
	},
	m_json_filename = "stancer.json"
}, FeatureBase)
Stancer.__index = Stancer

---@param pv PlayerVehicle
---@return Stancer
function Stancer.new(pv)
	local base = FeatureBase.new(pv)
	---@diagnostic disable-next-line
	return setmetatable(base, Stancer)
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

	if (self.m_entity:IsValid()) then
		local handle = self.m_entity:GetHandle()
		if (not Decorator:IsEntityRegistered(handle)) then
			Decorator:Register(handle, "Stancer", true)
		end

		self:ReadWheelData()
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
	if (not self:ShouldRun()) then
		return false
	end

	local wheel_idx = self.m_last_wheels_mod.index
	return self.m_entity:HasWheelDrawData() and wheel_idx ~= -1
end

function Stancer:ResetDeltas()
	for _, v in ipairs(StancerData.decorators) do
		self.m_deltas[Enums.eWheelAxle.FRONT][v.key] = 0.0
		self.m_deltas[Enums.eWheelAxle.REAR][v.key]  = 0.0
	end

	self.m_suspension_height.m_current   = 0.0
	self.m_suspension_height.m_last_seen = 0.0
end

function Stancer:Reset()
	self:ResetDeltas()

	if (not self:ShouldRun()) then
		return
	end

	self.m_entity:SetRideHeight(0.0)
	self:ReadWheelData()

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

	for _, v in ipairs(StancerData.decorators) do
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
	self:ReadWheelData()
	self:ReadDefaults()

	self.m_reloading = false
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

---@return boolean
function Stancer:IsVehicleModelSaved()
	if (not self.m_entity or not self.m_entity:IsValid()) then
		return false
	end

	local model_str = tostring(self.m_entity:GetModelHash())
	return GVars.features.vehicle.stancer.saved_models[model_str] ~= nil
end

---@return boolean
function Stancer:IsWheelDataValid()
	local front_count = #self.m_wheels[Enums.eWheelAxle.FRONT]
	local rear_count  = #self.m_wheels[Enums.eWheelAxle.REAR]
	return front_count > 0 and rear_count > 0
end

function Stancer:ReadWheelData()
	self.m_wheels = {
		[Enums.eWheelAxle.FRONT] = {},
		[Enums.eWheelAxle.REAR]  = {}
	}

	if (not self:ShouldRun()) then return end

	local front_axle  = self.m_wheels[Enums.eWheelAxle.FRONT]
	local rear_axle   = self.m_wheels[Enums.eWheelAxle.REAR]
	local wheel_array = self.m_entity:Resolve().m_wheels

	for i = 1, wheel_array:Size() do
		local cwheel = CWheel(wheel_array:At(i):deref())
		if (not cwheel or not cwheel:IsValid()) then
			goto continue
		end

		if (cwheel:IsRearWheel()) then
			table.insert(rear_axle, cwheel)
		else
			table.insert(front_axle, cwheel)
		end

		::continue::
	end
end

---@private
---@param wheel CWheel
---@param value number
---@return number
function Stancer:GetValueBySideLR(wheel, value)
	return wheel:IsLeftWheel() and value or -value
end

---@noecxept
---@return table<eWheelAxle, array<CWheel>>
function Stancer:GetWheels()
	if (not self:IsWheelDataValid()) then
		self:ReadWheelData()
	end

	return self.m_wheels
end

---@param side eWheelAxle
---@return array<CWheel>?
function Stancer:GetAllWheelsForSide(side)
	return self:GetWheels()[side]
end

---@param side eWheelAxle
---@param n integer
---@return CWheel?
function Stancer:GetNthWheelForSide(side, n)
	local wheelsbyside = self:GetAllWheelsForSide(side)
	if (not wheelsbyside) then
		return
	end

	local count = #wheelsbyside
	if (count == 0 or n > count) then
		return
	end
	return self.m_wheels[side][n]
end

---@param side eWheelAxle
---@return CWheel?
function Stancer:GetFirstWheelForSide(side)
	return self:GetNthWheelForSide(side, 1)
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
		local prev_deltas_f = table.copy(self.m_deltas[Enums.eWheelAxle.FRONT])
		local prev_deltas_r = table.copy(self.m_deltas[Enums.eWheelAxle.REAR])

		self:Cleanup()
		self:OnNewVehicle()
		self.m_last_wheels_mod = self.m_entity:GetCustomWheels()

		for k, v in pairs(prev_deltas_f) do
			self.m_deltas[Enums.eWheelAxle.FRONT][k] = v
		end

		for k, v in pairs(prev_deltas_r) do
			self.m_deltas[Enums.eWheelAxle.REAR][k] = v
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
	local front_obj = saved[model][tostring(Enums.eWheelAxle.FRONT)]
	local rear_obj  = saved[model][tostring(Enums.eWheelAxle.REAR)]

	if (not front_obj or not rear_obj or next(front_obj) == nil or next(rear_obj) == nil) then
		return false
	end

	for k, v in pairs(self.m_deltas[Enums.eWheelAxle.FRONT]) do
		if (not math.is_equal(v, front_obj[k])) then
			return false
		end
	end

	for k, v in pairs(self.m_deltas[Enums.eWheelAxle.REAR]) do
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
	local front_obj = saved[model][Enums.eWheelAxle.FRONT]
	local rear_obj  = saved[model][Enums.eWheelAxle.REAR]

	if (not front_obj or not rear_obj) then
		return false
	end

	for k, v in pairs(front_obj) do
		if (k == "m_suspension_height") then
			self.m_suspension_height.m_current = v
		else
			self.m_deltas[Enums.eWheelAxle.FRONT][k] = v
		end
	end

	for k, v in pairs(rear_obj) do
		self.m_deltas[Enums.eWheelAxle.REAR][k] = v
	end

	self.m_entity:ActivetePhysics()
	return true
end

function Stancer:SaveCurrentVehicle()
	local strModel = tostring(self.m_entity:GetModelHash())
	local saved = GVars.features.vehicle.stancer.saved_models
	saved[strModel] = table.copy(self.m_deltas)
	saved[strModel][Enums.eWheelAxle.FRONT]["m_suspension_height"] = self.m_suspension_height.m_current
end

function Stancer:RestoreQueueFromDecors()
	if (self:IsVehicleModelSaved() and GVars.features.vehicle.stancer.auto_apply_saved) then
		return self:LoadSavedDeltas()
	end

	local handle = self.m_entity:GetHandle()
	if (not Decorator:IsEntityRegistered(handle)) then
		return
	end

	for _, v in ipairs(StancerData.decorators) do
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

	for _, v in ipairs(StancerData.decorators) do
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
		self.m_deltas[Enums.eWheelAxle.FRONT].m_susp_comp = last_f
		self.m_bounce_mode.last_height_f = nil
	end

	if (last_r) then
		self.m_deltas[Enums.eWheelAxle.REAR].m_susp_comp = last_r
		self.m_bounce_mode.last_height_r = nil
	end

	self.m_reloading = false
end

function Stancer:UpdateBounceMode()
	if (not self.m_bounce_mode.enabled) then
		return
	end

	local vehicle = self.m_entity
	if (not vehicle:IsValid()) then
		return
	end

	if (vehicle:GetClassID() ~= Enums.eVehicleClasses.SUVs) then
		Notifier:ShowError("Stancer", _T("VEH_STANCE_BOUNCE_MODE_UNAVAIL")) -- it works for all cars but nah.. **REALISM**
		self.m_bounce_mode.enabled = false
		return
	end

	if (not self.m_bounce_mode.last_height_f) then
		self.m_bounce_mode.last_height_f = self.m_deltas[Enums.eWheelAxle.FRONT].m_susp_comp
	end

	if (not self.m_bounce_mode.last_height_r) then
		self.m_bounce_mode.last_height_r = self.m_deltas[Enums.eWheelAxle.REAR].m_susp_comp
	end

	local bm    = self.m_bounce_mode
	bm.t        = bm.t + Game.GetFrameTime() * bm.speed
	local tri   = math.tent(bm.t)
	local n     = (tri + 1) * 0.5
	n           = math.smooth_step(n)
	local sweep = (n * 2 - 1) * bm.margin


	self.m_deltas[Enums.eWheelAxle.FRONT].m_susp_comp = sweep
	self.m_deltas[Enums.eWheelAxle.REAR].m_susp_comp  = sweep

	if (vehicle:IsStopped()) then
		vehicle:ActivetePhysics()
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

	for _, v in ipairs(StancerData.decorators) do
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
