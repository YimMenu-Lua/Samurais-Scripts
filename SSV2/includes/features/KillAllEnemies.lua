-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- Scares nearby enemies and forces them to flee
---@class EnemyKiller
---@field private m_last_trigger_time seconds
local EnemyKiller = { m_last_trigger_time = 0 }
EnemyKiller.__index = EnemyKiller

function EnemyKiller:OnClick()
	if (Time.Millis() - self.m_last_trigger_time < 500) then
		return
	end

	ThreadManager:Run(function()
		if (not LocalPlayer:IsInCombat()) then
			Notifier:ShowMessage("Samurai's Scripts", _T("GENERIC_NOT_IN_COMBAT"), false, 3)
			return
		end

		Notifier:ShowSuccess("Samurai's Scripts", _T("WRLD_KILL_ALL_NOTIF"))
		for _, p in ipairs(entities.get_all_peds_as_handles()) do
			if (not PED.IS_PED_A_PLAYER(p) and LocalPlayer:IsPedMyEnemy(p)) then
				if (PED.IS_PED_IN_ANY_VEHICLE(p, false)) then
					local enemy_vehicle = PED.GET_VEHICLE_PED_IS_IN(p, false)
					local distance      = LocalPlayer:GetPos():distance(Game.GetEntityCoords(enemy_vehicle, true))

					if (distance <= 100) then
						VEHICLE.SET_VEHICLE_ENGINE_HEALTH(enemy_vehicle, -4000)
						for i = 0, 7 do
							VEHICLE.SET_VEHICLE_TYRE_BURST(enemy_vehicle, i, false, 1000.0)
						end
					end
				end

				PED.APPLY_DAMAGE_TO_PED(p, 10000, true, 0, 0x7FD62962)
			end

			yield()
		end

		self.m_last_trigger_time = Time.Millis()
	end)
end

KeyManager:RegisterKeybind(GVars.keyboard_keybinds.kill_all_enemies, function()
	EnemyKiller:OnClick()
end)

return EnemyKiller
