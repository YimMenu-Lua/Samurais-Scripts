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
---@field m_swim_speed pointer<float>
---@field m_game_state pointer<eGameState>
---@field m_is_wanted pointer<bool>
---@field m_wanted_level pointer<uint32_t>
---@field m_wanted_level_display pointer<uint32_t>
---@field m_run_speed pointer<float>
---@field m_stamina pointer<float>
---@field m_stamina_regen pointer<float>
---@field m_weapon_damage_mult pointer<float>
---@field m_weapon_defence_mult pointer<float> // 0x0D70
---@overload fun(ptr: pointer): CPlayerInfo
local CPlayerInfo = CStructView("CPlayerInfo", 0x0D78)

---@param ptr pointer
---@return CPlayerInfo
function CPlayerInfo.new(ptr)
	return setmetatable({
		m_ptr                  = ptr,
		m_swim_speed           = ptr:add(0x01C8),
		m_game_state           = ptr:add(0x0230),
		m_is_wanted            = ptr:add(0x08E0),
		m_wanted_level         = ptr:add(0x08E8),
		m_wanted_level_display = ptr:add(0x08EC),
		m_run_speed            = ptr:add(0x0D50),
		m_stamina              = ptr:add(0x0D54),
		m_stamina_regen        = ptr:add(0x0D58),
		m_weapon_damage_mult   = ptr:add(0x0D6C),
		m_weapon_defence_mult  = ptr:add(0x0D70),
		---@diagnostic disable-next-line: param-type-mismatch
	}, CPlayerInfo)
end

---@return eGameState
function CPlayerInfo:GetGameState()
	return self:__safecall(Enums.eGameState.Invalid, function()
		return self.m_game_state:get_int()
	end)
end

return CPlayerInfo
