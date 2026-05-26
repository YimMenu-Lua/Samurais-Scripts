-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- [[Summary]]
--
-- Handling presets define what vehicle flags they toggle and what vehicle types they are compatible with.
-- This file extends that by defining additional logic that a handling preset can execute when enabled, when disabled, or both.
-- User-generated presets can provide an additional file name parameter in their metadata, which would point to a user-defined file that looks exactly like this one (minus the LuaLS annotations).
-- The reason they must define a separate file is so that script updates do not touch their custom logic (if custom preset logic is defined here, it will be wiped with each update).
-- And the reason code execution is defined in a separate file in the first place is because both Lua's load and loadstring functions are removed from this sandbox.
--
-- NOTE: This file is only for default callbacks. Please do not edit unless you're contributing a new default handling preset.
-- For user-generated callbacks, you can define a new file with the same structure of this one.

---@alias HandlingPresetCallback fun(self: HandlingPreset, editor: VehicleFlagController): boolean
---@alias HandlingPresetCallbackData { onEnable: HandlingPresetCallback, onDisable: HandlingPresetCallback }

---@type dict<HandlingPresetCallbackData>
return {
	["VEH_KERS_BOOST"] = {
		onEnable = function(_)
			local PV = LocalPlayer:GetVehicle()
			if (not PV:IsValid()) then return true end
			VEHICLE.SET_VEHICLE_KERS_ALLOWED(PV:GetHandle(), true)
			return true
		end,
		onDisable = function(_)
			local PV = LocalPlayer:GetVehicle()
			if (not PV:IsValid()) then return true end
			VEHICLE.SET_VEHICLE_KERS_ALLOWED(PV:GetHandle(), false)
			return true
		end
	},
	["VEH_ROCKET_BOOST"] = {
		onEnable  = function(_)
			Game.RequestNamedPtfxAsset("VEH_IMPEXP_ROCKET")
			return true
		end,
		onDisable = function(_)
			STREAMING.REMOVE_NAMED_PTFX_ASSET("VEH_IMPEXP_ROCKET")
			return true
		end
	},
	["VEH_JUMP"] = {
		onEnable  = function(_)
			local PV = LocalPlayer:GetVehicle()
			if (not PV:IsValid()) then return true end
			VEHICLE.SET_USE_HIGHER_CAR_JUMP(PV:GetHandle(), true)
			return true
		end,
		onDisable = function(_)
			local PV = LocalPlayer:GetVehicle()
			if (not PV:IsValid()) then return true end
			VEHICLE.SET_USE_HIGHER_CAR_JUMP(PV:GetHandle(), false)
			return true
		end
	},
	["VEH_RAMP"] = {
		onEnable  = function(_)
			local PV = LocalPlayer:GetVehicle()
			if (not PV:IsValid()) then return true end
			VEHICLE.SET_ALLOW_RAMMING_SOOP_OR_RAMP(PV:GetHandle(), true)
			VEHICLE.VEHICLE_SET_RAMP_AND_RAMMING_CARS_TAKE_DAMAGE(PV:GetHandle(), false)
			return true
		end,
		onDisable = function(_)
			local PV = LocalPlayer:GetVehicle()
			if (not PV:IsValid()) then return true end
			local model = PV:GetModelHash()
			if (model ~= 0xCEB28249 and model ~= 0xED62BFA9) then
				VEHICLE.SET_ALLOW_RAMMING_SOOP_OR_RAMP(PV:GetHandle(), false)
			end
			return true
		end
	},
	["VEH_OFFROAD_ABILITIES"] = {
		onEnable  = function(_)
			local PV = LocalPlayer:GetVehicle()
			if (not PV:IsValid()) then return true end
			local stancer = PV.m_stancer
			local deltas  = stancer.m_deltas
			local front   = deltas[Enums.eWheelAxle.FRONT]
			local rear    = deltas[Enums.eWheelAxle.REAR]
			stancer:Lock(_T("VEH_OFFROAD_ABILITIES"))
			front.m_susp_comp   = 0.1207
			front.m_track_width = -0.047
			rear.m_susp_comp    = 0.1201
			rear.m_track_width  = -0.052
			PV:ActivatePhysics()
			return true
		end,
		onDisable = function(_)
			local PV = LocalPlayer:GetVehicle()
			if (not PV:IsValid()) then return true end
			local stancer = PV.m_stancer
			stancer:ResetDeltas(true)
			stancer:Unlock()
			PV:ActivatePhysics()
			return true
		end
	},
}
