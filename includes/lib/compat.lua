-- Basic compatibility layers/API stubs
---@diagnostic disable: lowercase-global

local Compat = {}
Compat.__index = Compat

---@param version integer eAPIVersion
function Compat.SetupEnvironment(version)
	if (version == Enums.eAPIVersion.V1) then
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
				elseif IsInstance(v, "pointer") then
					str = string.format("Pointer @ 0x%X", v:get_address())
				else
					local ok, result = pcall(tostring, v)
					str = ok and result or "<tostring error!>"
				end

				out[i] = str
			end

			log.info(table.concat(out, "\t"))
		end

		do
			local levels = {
				debug   = log.debug,
				info    = log.info,
				warning = log.warning,
			}

			for level, func in pairs(levels) do
				local fname = "f" .. level
				log[fname] = function(fmt, ...)
					local ok, msg = pcall(string.format, fmt, ...)
					if not ok then
						msg = string.format("<format error: %s> %s", tostring(msg), tostring(fmt))
					end

					func(msg)
				end
			end
		end
	elseif (version == Enums.eAPIVersion.V2) then
		error("YmMenu V2 is not supported. Please remove the script.")
	elseif (version == Enums.eAPIVersion.L54) then
		require("includes.lib.mock_env")
	end

	printf = function(fmt, ...)
		log.finfo(fmt, ...)
	end
end

return Compat
