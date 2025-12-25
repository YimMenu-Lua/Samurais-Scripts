-- Scares nearby enemies and forces them to flee
---@class Terrifier
---@field private m_active boolean
local Terrifier = { m_active = false }
Terrifier.__index = Terrifier

function Terrifier:OnClick()
	if (self.m_active) then
		return
	end

	ThreadManager:Run(function()
		if (not Self:IsInCombat()) then
			Toast:ShowMessage("Samurai's Scripts", _T("GENERIC_NOT_IN_COMBAT"), false, 3)
			return
		end

		Toast:ShowSuccess("Samurai's Scripts", _T("WRLD_FLEE_ALL_NOTIF"), false, 5)
		self.m_active = true
		local timer = Timer.new(5000)
		while not (timer:is_done()) do
			if (not Self:IsAlive()) then
				break
			end

			for _, p in pairs(entities.get_all_peds_as_handles()) do
				if (PED.IS_PED_HUMAN(p) and Self:IsPedMyEnemy(p) and not PED.IS_PED_A_PLAYER(p)) then
					TASK.CLEAR_PED_SECONDARY_TASK(p)
					TASK.CLEAR_PED_TASKS(p)
					PED.SET_PED_KEEP_TASK(p, false)
					PED.SET_PED_COMBAT_ATTRIBUTES(p, 5, false)
					PED.SET_PED_COMBAT_ATTRIBUTES(p, 13, false)
					PED.SET_PED_COMBAT_ATTRIBUTES(p, 31, false)
					PED.SET_PED_COMBAT_ATTRIBUTES(p, 50, false)
					PED.SET_PED_COMBAT_ATTRIBUTES(p, 58, false)
					PED.SET_PED_COMBAT_ATTRIBUTES(p, 17, true)
					PED.SET_PED_COMBAT_ATTRIBUTES(p, 77, true)

					if WEAPON.IS_PED_ARMED(p, 7) then
						WEAPON.SET_PED_DROPS_WEAPON(p)
					end

					if PED.IS_PED_IN_ANY_VEHICLE(p, false) then
						TASK.TASK_VEHICLE_TEMP_ACTION(p, PED.GET_VEHICLE_PED_IS_USING(p), 1, 2000)
						TASK.TASK_LEAVE_ANY_VEHICLE(p, 0, 4160) -- make them yeet themselves out
					end

					TASK.TASK_SMART_FLEE_PED(p, Self:GetHandle(), 1000, -1, false, false)
				end
			end

			yield()
		end

		self.m_active = false
	end)
end

KeyManager:RegisterKeybind(GVars.keyboard_keybinds.enemies_flee, function()
	Terrifier:OnClick()
end)

return Terrifier
