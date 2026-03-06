-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView = require("includes.classes.gta.CStructView")

--------------------------------------
-- Class: CPlayerInfo
--------------------------------------
---@ignore
---@class CPlayerInfo : CStructBase<CPlayerInfo>
---@field protected m_ptr pointer
---@field public m_swim_speed pointer<float>
---@field public m_game_state pointer<eGameState>
---@field public m_is_wanted pointer<bool>
---@field public m_wanted_level pointer<uint32_t>
---@field public m_wanted_level_display pointer<uint32_t>
---@field public m_run_speed pointer<float>
---@field public m_stamina pointer<float>
---@field public m_stamina_regen pointer<float>
---@field public m_weapon_damage_mult pointer<float>
---@field public m_weapon_defence_mult pointer<float> // 0x0D70
---@overload fun(ptr: pointer): CPlayerInfo|nil
local CPlayerInfo = CStructView("CPlayerInfo", {
	{ "m_swim_speed",           0x01C8 },
	{ "m_game_state",           0x0230 },
	{ "m_is_wanted",            0x08E0 },
	{ "m_wanted_level",         0x08E8 },
	{ "m_wanted_level_display", 0x08EC },
	{ "m_run_speed",            0x0D50 },
	{ "m_stamina",              0x0D54 },
	{ "m_stamina_regen",        0x0D58 },
	{ "m_weapon_damage_mult",   0x0D6C },
	{ "m_weapon_defence_mult",  0x0D70 },
}, 0x0D74)

---@return eGameState
function CPlayerInfo:GetGameState()
	return self:__safecall(Enums.eGameState.Invalid, function()
		return self.m_game_state:get_int()
	end)
end

return CPlayerInfo
