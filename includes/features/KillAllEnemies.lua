-- Scares nearby enemies and forces them to flee
---@class EnemyKiller
---@field private m_last_trigger_time seconds
local EnemyKiller = { m_last_trigger_time = 0 }
EnemyKiller.__index = EnemyKiller

function EnemyKiller:OnClick()
	if (Time.millis() - self.m_last_trigger_time < 500) then
		return
	end

	ThreadManager:Run(function()
		if (not Self:IsInCombat(500)) then
			Toast:ShowMessage("Samurai's Scripts", _T("GENERIC_NOT_IN_COMBAT"), false, 3)
			return
		end

		Toast:ShowMessage("Samurai's Scripts", _T("WRLD_KILL_ALL_NOTIF"))
		for _, p in pairs(entities.get_all_peds_as_handles()) do
			if (PED.IS_PED_HUMAN(p) and Self:IsPedMyEnemy(p) and not PED.IS_PED_A_PLAYER(p)) then
				if (not PED.IS_PED_IN_ANY_VEHICLE(p, false)) then
					PED.APPLY_DAMAGE_TO_PED(p, 100000, true, 0, 0x7FD62962)
				else
					local enemy_vehicle = PED.GET_VEHICLE_PED_IS_IN(p, false)
					local enemy_vehicle_coords = Game.GetEntityCoords(enemy_vehicle, true)
					local dist = enemy_vehicle_coords:distance(Self:GetPos())

					if (dist >= 30) then
						VEHICLE.SET_VEHICLE_ENGINE_HEALTH(enemy_vehicle, -4000)
						for i = 0, 7 do
							VEHICLE.SET_VEHICLE_TYRE_BURST(enemy_vehicle, i, false, 1000.0)
						end

						PED.APPLY_DAMAGE_TO_PED(p, 100000, true, 0, 0x7FD62962)
						-- NETWORK.NETWORK_EXPLODE_VEHICLE(enemy_vehicle, true, false, 0)
					end
				end
			end
		end

		self.m_last_trigger_time = Time.millis()
	end)
end

KeyManager:RegisterKeybind(GVars.keyboard_keybinds.kill_all_enemies, function()
	EnemyKiller:OnClick()
end)

return EnemyKiller
