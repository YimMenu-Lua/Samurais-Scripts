-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- Returns the stat with the appropriate character prefix. This is used with either natives or single player stats
--
-- since YimMenu's API already supports the `MPX` syntax for multiplayer stats.
--
-- For online stats, you can pass a stat starting with `MPX`, `MP0`, `MP1`, or `MP_STAT`.
--
-- For single player, you can pass a stat starting with, `SPX`, `SP0`, `SP1`, `SP2`, or `SP_STAT`.
--
-- **Usage Example:**
-- - YimMenu API:
-- ```Lua
-- local spMoney = stats.get_int(stats.prefix("SPX_TOTAL_CASH")) -- now single player stats work the same as multiplayer
-- local mpHangar = stats.get_int(stats.prefix("MP_STAT_HANGAR_OWNED")) -- useless since we can just use "MPX_HANGAR_OWNED"
-- ```
--
-- - Natives:
-- ```Lua
-- local halfOfficeName = STATS.STAT_GET_STRING(joaat(stats.prefix("MPX_GB_OFFICE_NAME")), -1)
-- ```
---@param stat_name string
---@return string
function stats.prefix(stat_name)
	local char_idx = Game.GetCharacterIndex()
	if (stat_name:startswith("MP_STAT")) then
		local ret, _ = stat_name:replace("MP_STAT", _F("MP%d", char_idx))
		return ret
	end

	if (stat_name:startswith("MP") or stat_name:startswith("SP")) then
		return stat_name:replace_char(3, tostring(char_idx))
	end

	return stat_name
end

---@param stat_name string
---@return string
function stats.get_string(stat_name)
	return STATS.STAT_GET_STRING(_J(stats.prefix(stat_name)), -1)
end

---@param stat_name string
---@param v string
function stats.set_string(stat_name, v)
	stat_name = stats.prefix(stat_name)
	if (not stat_name:startswith("MP") and not stat_name:startswith("SP")) then
		return
	end

	STATS.STAT_SET_STRING(_J(stat_name), v, true)
end

-- TODO: make it clear that this is not the same as `STATS.STAT_INCREMENT` and add a wrapper for that.
---@param stat_name string
---@param v number
---@param min? number
---@param max? number
function stats.increment_stat(stat_name, v, min, max)
	min = min or 0
	max = max or 100

	local stat_get, stat_set
	if (math.type(v) == "integer") then
		stat_get, stat_set = stats.get_int, stats.set_int
	elseif (math.type(v) == "float") then
		stat_get, stat_set = stats.get_float, stats.set_float
	end

	if (not stat_get or not stat_set) then
		return
	end

	local sum = stat_get(stat_name) + v
	if (sum < min or sum > max) then
		return
	end

	stat_set(stat_name, sum)
end

---@param stat_name string
---@return DateTime
function stats.get_date(stat_name)
	stat_name = stats.prefix(stat_name)
	local ptr = malloc(0x8 * 7)

	if (not STATS.STAT_GET_DATE(_J(stat_name), ptr:get_address(), 7, -1)) then
		log.warning("STAT_GET_DATE native call failed! Returning a default DateTime object. (note: the native also returns false if you try to read a multiplayer stat in single player).")
		return DateTime(0)
	end

	return DateTime.FromRageStruct(ptr)
end

---@param stat_name string
---@param date DateTime
---@return boolean success
function stats.set_date(stat_name, date)
	stat_name     = stats.prefix(stat_name)
	local ptr     = date:AsRageDateStruct()
	local success = STATS.STAT_SET_DATE(_J(stat_name), ptr:get_address(), 7, true)

	free(ptr)
	return success
end
