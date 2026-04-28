-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@param src string Filename with extension
---@param dest string Filename with extension
---@return boolean, any
function io.copy(src, dest)
	if (not io.exists(src)) then
		log.warning("[File I/O]: Copy operation failed. Source file does not exist.")
		return false, nil
	end

	local f1 <close> = io.open(src, "r")
	local f2 <close> = io.open(dest, "w")
	if (not f1 or not f2) then
		return false, nil
	end

	local data = f1:read("a")
	if (not data) then
		return false, nil
	end

	f2:write(data)
	f2:flush()

	return true, data
end
