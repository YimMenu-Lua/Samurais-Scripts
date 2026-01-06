local SalvageYard = require("includes.features.SalvageYard")

local function DrawSalvageYardUI()
	ImGui.SeparatorText(_T("SY_VEHICLES"))
	for i = 1, 4 do
		local carname = SalvageYard:GetCarFromSlot(i)
		ImGui.Text(_F(_T("SY_VEH_SLOT"), i))
		ImGui.SameLine()
		ImGui.BulletText(carname or _T("SY_EMPTY"))
		ImGui.SameLine()
		local value = stats.get_int(_F("MPX_SAL23_VALUE_VEH%d", i))
		GUI:Text(string.formatmoney(value), Color("#00aa00"))
	end

	ImGui.SeparatorText(_T("SY_LIFTS"))
	for i = 1, 2 do
		if SalvageYard:IsLiftTaken(i) then
			ImGui.Text(_F(_T("SY_LIFT"), 1))
			ImGui.SameLine()
			local hash = stats.get_int(_F("MPX_MPSV_MODEL_SALVAGE_LIFT%d", 1))
			ImGui.BulletText(SalvageYard:GetCarNameFromHash(hash))
			ImGui.SameLine()
			local value = stats.get_int(_F("MPX_MPSV_VALUE_SALVAGE_LIFT%d", i))
			GUI:Text(string.formatmoney(value), Color("#00aa00"))

			ImGui.SameLine()
			if (ImGui.Button(_T("SY_INSTANT_SALVAGE"))) then
				SalvageYard:InstantSalvage(i)
			end
		else
			ImGui.Text(_F(_T("SY_LIFT_AVAILABLE"), i))
		end

		ImGui.Dummy(3, 3)
	end

	if (GVars.backend.debug_mode) then
		ImGui.SeparatorText(_T("SY_INFORMATION"))
		local pop_posix = stats.get_int("MPX_SALVAGE_POPULAR_TIME_LEFT")
		ImGui.Text(_F("SALVAGE_POPULAR_TIME_LEFT : %d (%s)", pop_posix, Time.format_time_ms(pop_posix))) -- how long popular? -- Time left in milliseconds. It updates every 15 seconds. We can lock it to a big value in a dedicated thread.
	end
end

local function DrawRobberiesUI()
	ImGui.SeparatorText(_T("SY_ROBBERY_COOLDOWN"))

	if GUI:Button(_T("SY_DISABLE_COOLDOWN")) then
		SalvageYard:DisableCooldown()
	end

	ImGui.SameLine()
	if GUI:Button(_T("SY_DISABLE_WEEKLY_COOLDOWN")) then
		SalvageYard:DisableWeeklyCooldown()
	end

	ImGui.SeparatorText(_T("SY_WEEKLY_ROBBERIES"))
	ImGui.Text(_F(_T("SY_WEEKLY_CAR_STATUS"), SalvageYard:CheckWeeklyRobberyStatus(0)))
	ImGui.Text(_F(_T("SY_WEEKLY_CAR_STATUS"), SalvageYard:CheckWeeklyRobberyStatus(1)))
	ImGui.Text(_F(_T("SY_WEEKLY_CAR_STATUS"), SalvageYard:CheckWeeklyRobberyStatus(2)))

	ImGui.Dummy(5, 5)
	if (not SalvageYard:IsRobberyActive()) then
		ImGui.Text("No Active Robbery")
		ImGui.Text(SalvageYard:GetCooldownString())
	else
		ImGui.Text(_F(_T("SY_ROBBERY_ACTIVE_CAR"), SalvageYard:GetCarNameFromHash(stats.get_int("MPX_SALV23_VEH_MODEL"))))
		ImGui.Text(_F(_T("SY_ROBBERY_TYPE"), SalvageYard:GetRobberyTypeName()))
		ImGui.Text(_F(_T("SY_ROBBERY_CAR_VALUE"), SalvageYard:GetRobberyValue()))
		ImGui.Text(_F(_T("SY_ROBBERY_CAN_KEEP_CAR"), tostring(SalvageYard:GetRobberyKeepState())))

		if GUI:Button(_T("SY_DOUBLE_CAR_WORTH")) then
			SalvageYard:DoubleCarWorth()
		end

		ImGui.SameLine()
		ImGui.BeginDisabled(SalvageYard:ArePrepsCompleted())
		if GUI:Button(_T("SY_COMPLETE_PREPARATIONS")) then
			SalvageYard:CompletePreparation()
		end
		ImGui.EndDisabled()
	end

	if (GUI:Button("Reset Everything")) then
		local bitset = stats.get_int("MPX_SALV23_GEN_BS")
		stats.set_int("MPX_SALV23_GEN_BS", Bit.clear(bitset, 0))
		stats.set_int("MPX_SALV23_INST_PROG", 0)
		stats.set_int("MPX_SALV23_SCOPE_BS", 0)
		Notifier:ShowMessage("Savage Yard", "Your Salvage Yard robbery has been reset")
	end
end

local function SalvageYardUI()
	if (not Game.IsOnline() or not Backend:IsUpToDate()) then
		ImGui.Text(_T("GENERIC_OFFLINE_OR_OUTDATED"))
		return
	end

	if not SalvageYard:OwnsSalvageYard() then
		ImGui.Text(_T("SY_DO_NOT_OWN_SALVAGE_YARD"))
		return
	end

	ImGui.BeginTabBar("SalvageYardless")

	if ImGui.BeginTabItem(_T("SY_SALVAGE_YARD")) then
		DrawSalvageYardUI()
		ImGui.EndTabItem()
	end

	if ImGui.BeginTabItem(_T("SY_CAR_ROBBERIES")) then
		DrawRobberiesUI()
		ImGui.EndTabItem()
	end
	ImGui.EndTabBar()
end

GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, "Salvage Yard", SalvageYardUI)
