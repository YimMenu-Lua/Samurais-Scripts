---@diagnostic disable: param-type-mismatch, return-type-mismatch, assign-type-mismatch

local FeatureBase = require("includes.modules.FeatureBase")

---@class CobraManeuver : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_is_active boolean
local CobraManeuver = setmetatable({}, FeatureBase)
CobraManeuver.__index = CobraManeuver

---@param pv PlayerVehicle
---@return CobraManeuver
function CobraManeuver.new(pv)
	local self = FeatureBase.new(pv)
	return setmetatable(self, CobraManeuver)
end

function CobraManeuver:Init()
	self.m_is_active = false
end

function CobraManeuver:ShouldRun()
	return (GVars.features.vehicle.cobra_maneuver
		and Self:IsDriving()
		and self.m_entity
		and self.m_entity:IsValid()
		and self.m_entity:IsPlane()
	)
end

---@return boolean
function CobraManeuver:WasInterrupted()
	return KeyManager:IsKeyJustPressed(eVirtualKeyCodes.CTRL)
end

function CobraManeuver:OnTick()
	if (not self:ShouldRun()) then
		sleep(1000)
		return
	end

	if (KeyManager:IsKeyJustPressed(eVirtualKeyCodes.X)) then
		local PV = self.m_entity
		if PV:GetHeightAboveGround() < 500 then
			Toast:ShowError(
				"Samurai's Scripts",
				_T("VEH_COBRA_MANEUVER_TOO_lOW")
			)
			return
		end

		if (PV:GetSpeed() < 50) then
			Toast:ShowError("Samurai's Scripts", _T("VEH_COBRA_MANEUVER_TOO_SlOW"))
			return
		end

		local handle = PV:GetHandle()
		local startRot = Game.GetEntityRotation(handle, 2)
		local currentPitch = startRot.x

		if (startRot.x <= -6 or startRot.y <= -20 or startRot.y >= 20) then
			Toast:ShowError("Samurai's Scripts", _T("VEH_COBRA_MANEUVER_NOT_LEVEL"))
			return
		end

		Toast:ShowMessage("Samurai's Scripts", _T("VEH_COBRA_MANEUVER_CANCEL"))
		PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 51, 1.0)

		local pitchDelta = 89.0
		local targetPitch = currentPitch + pitchDelta

		if (currentPitch < -10.0) then
			targetPitch = 85.0
		elseif (currentPitch > 10.0) then
			targetPitch = math.min(currentPitch + 50.0, 85.0)
		else
			targetPitch = 85.0
		end

		local targetRot = vec3:new(targetPitch, startRot.y, startRot.z)
		local steps = 500

		for i = 1, steps do
			if (self:WasInterrupted()) then
				Toast:ShowWarning(
					"Samurai's Scripts",
					"Cobra Maneuver was interrupted! Giving control back to the player."
				)
				return
			end

			local alpha = i / steps * 5
			local newRot = startRot:lerp(targetRot, alpha)

			if (GVars.features.vehicle.flares) then
				PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 88, 1.0)
			end

			ENTITY.SET_ENTITY_ROTATION(
				handle,
				newRot.x,
				newRot.y,
				newRot.z,
				2,
				true
			)

			local velocity = ENTITY.GET_ENTITY_VELOCITY(handle)
			if (i == math.floor(steps / 50)) then
				local backwardImpulse = vec3:new(
					-velocity.x * 1.5,
					-velocity.y * 1.5,
					0.0
				)

				ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(
					handle,
					1,
					backwardImpulse.x,
					backwardImpulse.y,
					backwardImpulse.z,
					true,
					true,
					true,
					true
				)

				ENTITY.SET_ENTITY_VELOCITY(
					handle,
					velocity.x * 0.2,
					velocity.y * 0.2,
					velocity.z * 0.2
				)
			end

			sleep(10)

			if (newRot.x >= (targetPitch - 0.1) and velocity.y <= 10) then
				sleep(500)
				break
			end
		end

		for _ = 1, 100 do
			if (self:WasInterrupted()) then
				Toast:ShowWarning("Samurai's Scripts", _T("VEH_COBRA_MANEUVER_INTERRUPT"))
				return
			end

			PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 87, 1.0)
			PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 110, -1.0)
			yield()
		end
	end

	yield()
end

return CobraManeuver
