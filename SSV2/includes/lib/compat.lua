-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- Basic compatibility layers/API stubs

local Compat <const> = {}
Compat.__index       = Compat
local _f             = string.format
local tostr          = tostring

---@param version eGameBranch
function Compat.SetupEnv(version)
	if (version == Enums.eGameBranch.MOCK) then
		require("includes.lib.mock_env")(version)
	else
		print = function(...)
			local out = {}

			for i = 1, select("#", ...) do
				local v = select(i, ...)
				local str

				if (type(v) == "table") then
					if v.__tostring then
						str = v:__tostring()
					elseif (type(table.serialize) == "function") then -- this is defined in utils.lua
						local ok, result = pcall(table.serialize, v)
						str = ok and result or "<serialization error!>"
					end
				elseif (IsInstance(v, "pointer")) then
					str = _f("Pointer @ 0x%X", v:get_address())
				else
					local ok, result = pcall(tostr, v)
					str = ok and result or "<tostring error!>"
				end

				out[i] = str
			end

			log.info(table.concat(out, "\t"))
		end

		---@diagnostic disable-next-line
		log.error = function(msg)
			log.warning(_f("\27[31m[ERROR]: %s\27[0m", msg))
		end

		do
			local levels = {
				debug   = log.debug,
				info    = log.info,
				warning = log.warning,
				error   = log.error
			}

			for level, func in pairs(levels) do
				local fname = "f" .. level
				log[fname] = function(fmt, ...)
					local ok, msg = pcall(_f, fmt, ...)
					if (not ok) then
						msg = _f("<format error: %s> %s", tostr(msg), tostr(fmt))
					end

					func(msg)
				end
			end
		end
	end

	---@param fmt string
	---@param ... any
	---@diagnostic disable-next-line
	printf = function(fmt, ...) log.finfo(fmt, ...) end
end

return Compat
