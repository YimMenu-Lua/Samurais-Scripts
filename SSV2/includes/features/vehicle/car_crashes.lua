-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")

---@class CrashLevel
---@field threshold fun(): integer
---@field healthDamage integer
---@field screenEffect string?
---@field kill boolean

---@class CarCrash : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_thread? Thread
---@field private m_last_update_time seconds
---@field private m_is_active boolean
---@field private m_crash_levels { minor: CrashLevel, major: CrashLevel, fatal: CrashLevel }
---@overload fun(pv: PlayerVehicle): CarCrash
---@diagnostic disable-next-line
local CarCrash = setmetatable({}, FeatureBase)
CarCrash.__index = CarCrash

---@param pv PlayerVehicle
---@return CarCrash
function CarCrash.new(pv)
	local self = FeatureBase.new(pv)
	---@diagnostic disable-next-line
	return setmetatable(self, CarCrash)
end

function CarCrash:Init()
	self.m_is_active = false
	self.m_last_update_time = 0
	self.m_crash_levels = {
		minor = {
			threshold = function()
				return 10
			end,
			healthDamage = 10,
			screenEffect = nil,
			kill = false
		},
		major = {
			threshold = function()
				return GVars.features.vehicle.fast_vehicles and 45 or 35
			end,
			healthDamage = 35,
			screenEffect = "ULP_PLAYERWAKEUP",
			kill = false
		},
		fatal = {
			threshold = function()
				return GVars.features.vehicle.fast_vehicles and 70 or 45
			end,
			healthDamage = 1000,
			screenEffect = nil,
			kill = true -- you gon' die bish
		}
	}

	self.m_entity:AddMemoryPatch({
		name = self.m_entity.MemoryPatches.DeformMult,
		onEnable = function(patch)
			local cvehicle = self.m_entity:Resolve()
			if (not cvehicle) then
				error("Handling data is null!")
			end

			local fDeformMult = cvehicle.m_deform_mult
			patch.m_state     = {
				ptr = fDeformMult,
				default_value = fDeformMult:get_float()
			}

			if (fDeformMult:is_valid()) then
				fDeformMult:set_float(2.69420)
			end
		end,
		onDisable = function(patch)
			if (not patch.m_state or patch.m_state.default_value == nil) then
				return
			end

			local ptr = patch.m_state.ptr
			if (not ptr or ptr:is_null()) then
				error("pointer is null")
			end

			ptr:set_float(patch.m_state.default_value)
		end
	})

	self.m_thread = ThreadManager:RegisterLooped("SS_VEH_CRASH", function()
		self:OnTick()
	end)
end

function CarCrash:ShouldRun()
	return (GVars.features.vehicle.strong_crash
		and self.m_entity
		and self.m_entity:IsValid()
		and self.m_entity:IsCar()
		and Self:IsAlive()
		and Self:IsDriving()
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
	local door = math.random(0, VEHICLE.GET_NUMBER_OF_VEHICLE_DOORS(vehicle) + 1)
	if (VEHICLE.GET_IS_DOOR_VALID(vehicle, door)) then
		VEHICLE.SET_VEHICLE_DOOR_BROKEN(vehicle, door, true)
	end
end

---@param levelName string
function CarCrash:PlaySpeech(levelName)
	if (not Game.IsOnline()) then
		return
	end

	local speech_name = (levelName == "major") and "DEATH_HIGH_MEDIUM" or "DYING_MOAN"
	local voice_name = Self:IsMale() and "WAVELOAD_PAIN_MALE" or "WAVELOAD_PAIN_FEMALE"
	Audio:PlaySpeechFromPosition(
		speech_name,
		voice_name,
		Self:GetPos(),
		"SPEECH_PARAMS_FORCE_SHOUTED"
	)
end

---@param levelName string
---@param vehicle handle
function CarCrash:OnCollision(levelName, vehicle)
	if (not self:ShouldRun()) then
		return
	end

	local lvl = self.m_crash_levels[levelName]
	if (not lvl) then
		return
	end

	if (lvl.screenEffect and not GRAPHICS.ANIMPOSTFX_IS_RUNNING(lvl.screenEffect)) then
		GRAPHICS.ANIMPOSTFX_PLAY(lvl.screenEffect, 5000, false)
	end

	local occupants = self.m_entity:GetOccupants()
	if (#occupants > 0) then
		for _, ped in ipairs(occupants) do
			-- if (PED.IS_PED_A_PLAYER(ped) and ped ~= Self:GetHandle()) then -- nah, kill players too.
			-- 	goto continue
			-- end

			if (lvl.kill) then
				ENTITY.SET_ENTITY_HEALTH(ped, 0, 0, 0)
			else
				ENTITY.SET_ENTITY_HEALTH(ped, math.max(0, ENTITY.GET_ENTITY_HEALTH(ped) - lvl.healthDamage), 0, 0)
			end

			-- ::continue::
		end
	end

	if (levelName == "minor") then
		VEHICLE.SMASH_VEHICLE_WINDOW(vehicle, math.random(0, 3))
		return
	end

	self:BreakRandomDoor(vehicle)
	self:PlaySpeech(levelName)

	if (levelName == "major") then
		VEHICLE.SET_VEHICLE_STEER_BIAS(vehicle, -0.6)
		sleep(500)
		VEHICLE.SET_VEHICLE_STEER_BIAS(vehicle, 0.6)
		sleep(500)
		VEHICLE.SET_VEHICLE_STEER_BIAS(vehicle, 0)
	end
end

function CarCrash:OnTick()
	if (not self:ShouldRun()) then
		sleep(1000)
		return
	end

	local PV = self.m_entity
	if (not PV:HasCrashed()) then
		return
	end

	local handle   = PV:GetHandle()
	local speed    = PV:GetSpeed()
	local levelKey = "minor"

	PV:ApplyPatch(PV.MemoryPatches.DeformMult)
	CAM.SHAKE_GAMEPLAY_CAM("GRENADE_EXPLOSION_SHAKE", speed / 30)

	if (speed >= self.m_crash_levels.major.threshold()) then
		local initial_speed = speed
		sleep(100)
		local current_speed = PV:GetSpeed()

		if (current_speed <= (initial_speed * 0.8) and current_speed > (initial_speed / 5)) then
			levelKey = "major"
		elseif (current_speed <= (initial_speed / 5)) then
			levelKey = "fatal"
		end
	elseif (speed >= self.m_crash_levels.minor.threshold()) then
		levelKey = "minor"
	end

	self:OnCollision(levelKey, handle)
	sleep(1200)
end

return CarCrash
