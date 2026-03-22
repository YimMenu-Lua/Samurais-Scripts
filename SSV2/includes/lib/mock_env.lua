-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@diagnostic disable: duplicate-set-field

local MockEnv <const> = {}
MockEnv.__index = MockEnv

function MockEnv.Setup(version)
	if (version ~= Enums.eAPIVersion.L54) then
		return
	end

	if (not io["exists"]) then
		io.exists = function(filepath)
			local ok, f = pcall(io.open, filepath, "r")
			if not ok or not f then
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

		local levels <const> = { "debug", "info", "warning" }

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
			register_looped = function(name, fn)
				print("[mock script looped]", name)
				fn({ sleep = NOP, yield = NOP })
			end,
			run_in_fiber = function(fn)
				fn({ sleep = NOP, yield = NOP })
			end,

			is_active = function(scr_name)
				print("[mock script active check]", scr_name)
				return false
			end
		}
	end

	if (not event) then
		event = {
			register_handler = function(evt, fn)
				print("[mock event]", evt)
				return fn
			end
		}
	end

	if (not menu_event) then
		menu_event = {
			playerLeave               = 1,
			playerJoin                = 2,
			playerMgrInit             = 3,
			playerMgrShutdown         = 4,
			ChatMessageReceived       = 5,
			ScriptedGameEventReceived = 6,
			MenuUnloaded              = 7,
			ScriptsReloaded           = 8,
			Wndproc                   = 9
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
		vec3 = {}
		---@param x float
		---@param y float
		---@param z float
		---@return vec3
		function vec3:new(x, y, z)
			return setmetatable(
				{
					x = x or 0,
					y = y or 0,
					z = z or 0,
				},
				vec3
			)
		end
	end

	if (not gui) then
		gui                       = {}
		gui.add_tab               = function(_)
			print("[mock gui.add_tab]")
			return gui
		end
		gui.add_imgui             = NOP
		gui.add_always_draw_imgui = NOP
	end

	if (not STREAMING) then
		STREAMING = { IS_PLAYER_SWITCH_IN_PROGRESS = function() return false end, }
	end

	if (not stats) then stats = {} end
	if (not ImGui) then ImGui = {} end
end

return MockEnv
