-- Scares nearby enemies and forces them to flee
---@class Terrifier
---@field private m_active boolean
---@field private m_last_triggered milliseconds
local Terrifier = { m_active = false, m_last_triggered = 0 }
Terrifier.__index = Terrifier

function Terrifier:OnClick()
	if (self.m_active or Time.millis() - self.m_last_triggered < 500) then
		return
	end

	ThreadManager:Run(function(s)
		if (not Self:IsInCombat()) then
			Notifier:ShowMessage("Samurai's Scripts", _T("GENERIC_NOT_IN_COMBAT"), false, 3)
			return
		end

		Notifier:ShowSuccess("Samurai's Scripts", _T("WRLD_FLEE_ALL_NOTIF"), false, 10.5)
		self.m_active = true
		---@type Set<handle>
		local task_set = Set.new()
		local trash = {}
		local timer = Timer.new(1e4)

		while (not timer:is_done()) do
			for _, p in ipairs(entities.get_all_peds_as_handles()) do
				if (not PED.IS_PED_A_PLAYER(p) and Self:IsPedMyEnemy(p) and not task_set:Contains(p)) then
					TASK.CLEAR_PED_TASKS(p)
					TASK.CLEAR_PED_SECONDARY_TASK(p)
					PED.SET_PED_COMBAT_ATTRIBUTES(p, 5, false)
					PED.SET_PED_COMBAT_ATTRIBUTES(p, 13, false)
					PED.SET_PED_COMBAT_ATTRIBUTES(p, 31, false)
					PED.SET_PED_COMBAT_ATTRIBUTES(p, 50, false)
					PED.SET_PED_COMBAT_ATTRIBUTES(p, 58, false)
					PED.SET_PED_COMBAT_ATTRIBUTES(p, 17, true)
					PED.SET_PED_COMBAT_ATTRIBUTES(p, 77, true)

					-- if WEAPON.IS_PED_ARMED(p, 7) then
					-- 	WEAPON.SET_PED_DROPS_WEAPON(p) -- too spammy for LEOs
					-- end

					if PED.IS_PED_IN_ANY_VEHICLE(p, false) then
						TASK.TASK_LEAVE_ANY_VEHICLE(p, 0, 4160) -- make them yeet themselves out
					end

					PED.SET_PED_KEEP_TASK(p, true)
					TASK.TASK_SMART_FLEE_PED(p, Self:GetHandle(), 300, 10000, false, true)
					task_set:Push(p)
				end

				s:yield()
			end

			s:sleep(1000)

			-- This is for scripted attackers (cops, mission enemies, etc.) they refuse to back down so we remind them who's the boss
			for ped in task_set:Iter() do
				if (not TASK.GET_IS_TASK_ACTIVE(ped, Enums.ePedTaskIndex.SmartFlee)) then
					TASK.TASK_SMART_FLEE_PED(ped, Self:GetHandle(), 300, -1, false, true)
				else
					table.insert(trash, ped)
				end
			end

			for _, ped in ipairs(trash) do
				task_set:Pop(ped)
			end
		end

		self.m_active         = false
		self.m_last_triggered = Time.millis()
	end)
end

KeyManager:RegisterKeybind(GVars.keyboard_keybinds.enemies_flee, function()
	Terrifier:OnClick()
end)

return Terrifier
