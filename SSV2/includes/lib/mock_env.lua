-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@diagnostic disable: duplicate-set-field

local function nop() end

---@param t table
---@param ret_type any
local function dummy_mt(t, ret_type)
	return setmetatable(t, { __index = function(...) return ret_type or nop end })
end

return function(branch)
	if (branch ~= Enums.eGameBranch.MOCK) then
		return
	end

	if (not io["exists"]) then
		io.exists = function(filepath)
			local ok, f = pcall(io.open, filepath, "r")
			if (not ok or not f) then
				return false
			end

			f:close()
			return true
		end
	end

	local m_os_rename = os.rename
	os.rename = function(oldname, newname)
		if (io.exists(newname)) then os.remove(newname) end
		m_os_rename(oldname, newname)
	end

	if (not log) then
		local logger = require("includes.modules.Logger").new("SSV2", {
			level      = "debug",
			use_colors = true,
			file       = "./ssv2.log",
			max_size   = 1024 * 500
		})

		local levels <const> = { "debug", "info", "warning", "error" }

		---@class log
		log = {}

		for _, level in ipairs(levels) do
			log[level] = function(data)
				logger:log(level, data)
			end

			local flevel = "f" .. level
			log[flevel] = function(fmt, ...)
				logger:logf(level, fmt, ...)
			end
		end
	end

	if (not script) then
		script = {
			register_looped   = nop,
			run_in_fiber      = nop,
			execute_as_script = nop,
			is_active         = function(_) return false end,
		}
	end

	if (not event) then
		event = { register_handler = nop }
	end

	if (not menu_event) then
		menu_event = {
			PlayerLeave               = 0,
			PlayerJoin                = 1,
			PlayerMgrInit             = 2,
			PlayerMgrShutdown         = 3,
			ChatMessageReceived       = 4,
			ScriptedGameEventReceived = 5,
			MenuUnloaded              = 6,
			ScriptsReloaded           = 7,
			Wndproc                   = 8
		}
	end

	if (not memory) then
		memory = {
			pointer       = {
				add         = function(self, offset) return memory.pointer end,
				sub         = function(self, offset) return memory.pointer end,
				get_byte    = function(self) return 0 end,
				get_word    = function(self) return 0 end,
				get_dword   = function(self) return 0 end,
				get_qword   = function(self) return 0 end,
				get_int     = function(self) return 0 end,
				get_float   = function(self) return 0.0 end,
				get_vec3    = function(self) return vec3:zero() end,
				get_address = function(self) return 0x0 end,
				get_disp32  = function(self, offset, adjust) return 0 end,
				set_address = function(self, address) end,
				is_null     = function(self) return true end,
				is_valid    = function(self) return false end
			},

			scan_pattern  = function(ida_ptrn) return memory.pointer end,
			allocate      = function(size) return memory.pointer end,
			free          = function(ptr) end,
			handle_to_ptr = function(handle) return memory.pointer end,
			ptr_to_handle = function(ptr) return 0x0 end,
			dynamic_call  = function(ret_type, arg_types, ptr) end
		}
	end

	if (not vec3) then
		vec3         = {}
		vec3.__index = vec3
		---@param x float
		---@param y float
		---@param z float
		---@return vec3
		function vec3:new(x, y, z)
			return setmetatable({
				x = x or 0,
				y = y or 0,
				z = z or 0,
			}, self)
		end
	end

	if (not gui) then gui = dummy_mt({}, function() return gui end) end
	if (not STREAMING) then STREAMING = dummy_mt({}) end
	if (not stats) then stats = dummy_mt({}) end
	if (not tunables) then tunables = dummy_mt({}) end
	if (not ImGui) then ImGui = dummy_mt({}) end
	if (not ImGuiWindowFlags) then ImGuiWindowFlags = dummy_mt({}, 0) end
end
