-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local PStats <const> = {
	{ label = "SELF_ABILITY_STAM",          stat_1 = "MPX_STAMINA",             stat_2 = "MPX_SCRIPT_INCREASE_STAM", incr_val = 1,   func = stats.get_int },
	{ label = "SELF_ABILITY_SHOOTING",      stat_1 = "MPX_SHOOTING_ABILITY",    stat_2 = "MPX_SCRIPT_INCREASE_SHO",  incr_val = 1,   func = stats.get_int },
	{ label = "SELF_ABILITY_STRENGTH",      stat_1 = "MPX_STRENGTH",            stat_2 = "MPX_SCRIPT_INCREASE_STRN", incr_val = 1,   func = stats.get_int },
	{ label = "SELF_ABILITY_STEALTH",       stat_1 = "MPX_STEALTH_ABILITY",     stat_2 = "MPX_SCRIPT_INCREASE_STL",  incr_val = 1,   func = stats.get_int },
	{ label = "SELF_ABILITY_FLYING",        stat_1 = "MPX_FLYING_ABILITY",      stat_2 = "MPX_SCRIPT_INCREASE_FLY",  incr_val = 1,   func = stats.get_int },
	{ label = "SELF_ABILITY_DRIVING",       stat_1 = "MPX_WHEELIE_ABILITY",     stat_2 = "MPX_SCRIPT_INCREASE_DRIV", incr_val = 1,   func = stats.get_int },
	{ label = "SELF_ABILITY_LUNG_CAPACITY", stat_1 = "MPX_LUNG_CAPACITY",       stat_2 = "MPX_SCRIPT_INCREASE_LUNG", incr_val = 1,   func = stats.get_int },
	{ label = "SELF_ABILITY_MENTAL_STATE",  stat_1 = "MPX_PLAYER_MENTAL_STATE", stat_2 = "MPX_PLAYER_MENTAL_STATE",  incr_val = 1.0, func = stats.get_float },
}

---@param label string
---@param read_func fun(stat: string): number
---@param read_stat string
---@param incr_stat string
---@param incr_val number
---@param spec_func? function
---@param min? number
---@param max? number
local function DrawAblityControls(label, read_func, read_stat, incr_stat, incr_val, spec_func, min, max)
	local val = read_func(read_stat) or 0
	spec_func = spec_func or NOP
	min       = min or 0
	max       = max or 100

	ImGui.Text(_T(label))

	ImGui.BeginDisabled(val <= min)
	if (ImGui.Button(" - ")) then
		ThreadManager:Run(function()
			stats.increment_stat(incr_stat, -incr_val, min, max)
			spec_func()
		end)
	end
	ImGui.EndDisabled()

	ImGui.SameLine()
	ImGui.ProgressBar(val / max, 300, 30)

	ImGui.SameLine()
	ImGui.BeginDisabled(val >= max)
	if ImGui.Button(" + ") then
		ThreadManager:Run(function()
			stats.increment_stat(incr_stat, incr_val)
			spec_func()
		end)
	end
	ImGui.EndDisabled()
end

return function()
	ImGui.SetWindowFontScale(1.17)
	local charName      = Self:GetName()
	local charNameWidth = ImGui.CalcTextSize(charName)
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (ImGui.GetContentRegionAvail() - charNameWidth) * 0.5)
	ImGui.Text(charName)
	ImGui.SetWindowFontScale(1.0)

	ImGui.PushButtonRepeat(true)
	for i, v in ipairs(PStats) do
		ImGui.PushID(i)
		DrawAblityControls(
			v.label,
			v.func,
			v.stat_1,
			v.stat_2,
			v.incr_val
		)
		ImGui.PopID()
	end
	ImGui.PopButtonRepeat()
end
