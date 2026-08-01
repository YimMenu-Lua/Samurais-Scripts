-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- Kills nearby enemies
---@class EnemyKiller
---@field private m_last_trigger_time seconds
local EnemyKiller   = { m_last_trigger_time = 0 }
EnemyKiller.__index = EnemyKiller

function EnemyKiller:OnClick()
	if (Time.Millis() - self.m_last_trigger_time < 500) then
		return
	end

	ThreadManager:Run(function()
		local count = 0
		for _, p in ipairs(entities.get_all_peds_as_handles()) do
			if (PED.IS_PED_A_PLAYER(p) or not LocalPlayer:IsPedMyEnemy(p)) then
				goto continue
			end

			local veh = PED.GET_VEHICLE_PED_IS_IN(p, false)
			if (veh ~= 0) then
				VEHICLE.SET_VEHICLE_ENGINE_HEALTH(veh, -4000)
			end

			PED.APPLY_DAMAGE_TO_PED(p, 10000, true, 0, 0x7FD62962)
			count = count + 1
			yield()

			::continue::
		end

		self.m_last_trigger_time = Time.Millis()

		if (count == 0) then
			Notifier:ShowError("Samurai's Scripts", _T("GENERIC_NOT_IN_COMBAT"), false, 3)
		else
			Notifier:ShowSuccess("Samurai's Scripts", _T("WRLD_KILL_ALL_NOTIF"))
		end
	end)
end

KeyManager:RegisterKeybind(GVars.keyboard_keybinds.kill_all_enemies, function()
	EnemyKiller:OnClick()
end)

return EnemyKiller
