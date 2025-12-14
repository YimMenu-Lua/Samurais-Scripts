---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local FeatureBase = require("includes.modules.FeatureBase")

---@class CrashLevel
---@field threshold integer
---@field healthDamage integer
---@field screenEffect string?
---@field kill boolean

---@class CarCrash : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_thread Thread
---@field private m_last_update_time seconds
---@field private m_is_active boolean
---@field private m_crash_levels { minor: CrashLevel, major: CrashLevel, fatal: CrashLevel }
---@overload fun(pv: PlayerVehicle): CarCrash
local CarCrash = setmetatable({}, FeatureBase)
CarCrash.__index = CarCrash

---@param pv PlayerVehicle
---@return CarCrash
function CarCrash.new(pv)
	local self = FeatureBase.new(pv)
	return setmetatable(self, CarCrash)
end

function CarCrash:Init()
	self.m_is_active = false
	self.m_last_update_time = 0
	self.m_crash_levels = {
		minor = {
			threshold = 10,
			healthDamage = 10,
			screenEffect = nil,
			kill = false
		},
		major = {
			threshold = GVars.features.vehicle.fast_vehicles and 45 or 35,
			healthDamage = 35,
			screenEffect = "ULP_PLAYERWAKEUP",
			kill = false
		},
		fatal = {
			threshold = GVars.features.vehicle.fast_vehicles and 70 or 45,
			healthDamage = 1000,
			screenEffect = nil,
			kill = true -- you gon' die bish
		}
	}

	self.m_thread = ThreadManager:CreateNewThread("SS_VEH_CRASH", function()
		self:Mainthread()
	end)
end

function CarCrash:ShouldRun()
	return (self.m_entity
		and self.m_entity:IsValid()
		and self.m_entity:IsLandVehicle()
		and Self:IsAlive()
		and Self:IsDriving()
		and GVars.features.vehicle.strong_crash
		and not VEHICLE.IS_VEHICLE_STUCK_ON_ROOF(self.m_entity:GetHandle())
	)
end

---@return boolean
function CarCrash:IsActive()
	return self.m_is_active
end

function CarCrash:OnEnable()
	if (self.m_thread and not self.m_thread:IsRunning()) then
		self.m_thread:Resume()
	end
end

function CarCrash:OnDisable()
	if (self.m_thread and self.m_thread:IsRunning()) then
		self.m_thread:Suspend()
	end
end

function CarCrash:BreakRandomDoor(vehicle)
	for i = 0, VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(vehicle) + 1 do
		if (VEHICLE.GET_IS_DOOR_VALID(vehicle, i)) then
			VEHICLE.SET_VEHICLE_DOOR_BROKEN(vehicle, i, true)
		end
	end
end

---@param level CrashLevel
---@param vehicle handle
function CarCrash:HandleVehicleCrash(level, vehicle)
	local lvl = self.m_crash_levels[level]
	if (not lvl) then
		return
	end

	if (lvl.screenEffect and not GRAPHICS.ANIMPOSTFX_IS_RUNNING(lvl.screenEffect)) then
		GRAPHICS.ANIMPOSTFX_PLAY(lvl.screenEffect, 5000, false)
	end

	local occupants = self.m_entity:GetOccupants()
	if (#occupants ~= 0) then
		for _, ped in ipairs(occupants) do
			if (lvl.kill) then
				ENTITY.SET_ENTITY_HEALTH(ped, 0, 0, 0)
			else
				ENTITY.SET_ENTITY_HEALTH(ped, ENTITY.GET_ENTITY_HEALTH(ped) - lvl.healthDamage, 0, 0)
			end
		end
	end

	if (level == "minor") then
		VEHICLE.SMASH_VEHICLE_WINDOW(vehicle, math.random(0, 3))
	elseif (level == "major") then
		self:BreakRandomDoor(vehicle)
		VEHICLE.SET_VEHICLE_STEER_BIAS(vehicle, -0.69)
		sleep(500)
		VEHICLE.SET_VEHICLE_STEER_BIAS(vehicle, 0.69)
		sleep(500)
		VEHICLE.SET_VEHICLE_STEER_BIAS(vehicle, 0)
	elseif (level == "fatal") then
		self:BreakRandomDoor(vehicle)
	end

	if (lvl == "major" or lvl == "fatal" and Game.IsOnline()) then
		local pos = Self:GetPos()
		local speech_name = (
			(Self:GetModelHash() == 0x705E61F2)
			and "WAVELOAD_PAIN_MALE"
			or "WAVELOAD_PAIN_FEMALE"
		)

		AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(
			"SCREAM_PANIC_SHORT",
			speech_name,
			pos.x,
			pos.y,
			pos.z,
			"SPEECH_PARAMS_FORCE_SHOUTED"
		)
	end
end

function CarCrash:Mainthread()
	local PV = self.m_entity
	local handle = PV:GetHandle()
	local speed = PV:GetSpeed()

	if (PV:HasCrashed()) then
		local deform_mult = self.m_entity:Resolve().m_deform_mult
		if (deform_mult:get_float() < 2.69420) then
			self.m_entity:WriteMemory(deform_mult, deform_mult.get_float, deform_mult.set_float, 2.69420)
		end

		CAM.SHAKE_GAMEPLAY_CAM("GRENADE_EXPLOSION_SHAKE", speed / 30)

		if (speed >= self.m_crash_levels.major.threshold) then
			local initial_speed = speed
			sleep(100)
			local current_speed = PV:GetSpeed()

			if (current_speed <= (initial_speed * 0.8) and current_speed > (initial_speed / 5)) then
				self:HandleVehicleCrash("major", handle)
			elseif (current_speed <= (initial_speed / 5)) then
				self:HandleVehicleCrash("fatal", handle)
			end
		elseif speed >= self.m_crash_levels.minor.threshold then
			self:HandleVehicleCrash("minor", handle)
		end

		sleep(1200)
	end
end

return CarCrash
