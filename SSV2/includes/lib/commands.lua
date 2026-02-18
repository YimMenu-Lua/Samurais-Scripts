-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.

local commandRegistry <const> = {
	["yrv3.finish_sale"] = {
		callback = function(_)
			YRV3:CommandFinishSale()
		end,
		opts = { description = "Automatically finishes any sale mission you have at the moment (limited to missions supported by YRV3)." }
	},
	["yrv3.restock_all"] = {
		callback = function(_)
			YRV3:FillAll()
		end,
		opts = { description = "Restocks all your owned businesses." }
	},
	["yrv3.restock_hangar"] = {
		callback = function(_)
			YRV3:CommandHangarAutoFill()
		end,
		opts = { description = "Restocks your hangar." }
	},
	["yrv3.restock_warehouse"] = {
		callback = function(args)
			local office = YRV3:GetOffice()
			if (not office) then
				Notifier:ShowError("CommandExecutor", _T("YRV3_CEO_OFFICE_NOT_OWNED"))
				return
			end

			local arg = args and args[1] or nil
			if (type(arg) == "string" and arg == "all") then
				for _, wh in ipairs(office:GetCargoWarehouses()) do
					if (wh:IsValid() and not wh:HasFullProduction()) then
						wh.auto_fill = true
					end
				end
			elseif (type(arg) == "number") then
				YRV3:CommandWarehouseAutoFill(arg)
			else
				Notifier:ShowError("CommandExecutor", "Invalid command argument!")
			end
		end,
		opts = {
			description =
			"Restocks either one or all owned warehouses.\nUsage Example:\n  - yrv3.restock_warehouse 2\n  - yrv3.restock_warehouse all",
			args = { "all<string> | integer: from 1 to 5" }
		}
	},
	["yrv3.restock_factory"] = {
		callback = function(args)
			local arg = args and args[1] or nil
			if (type(arg) == "string" and arg == "all") then
				for i = 1, 7 do
					YRV3:CommandFactoryRestock(i)
				end
			elseif (type(arg) == "number") then
				YRV3:CommandFactoryRestock(arg)
			else
				Notifier:ShowError("CommandExecutor", "Invalid command argument!")
			end
		end,
		opts = {
			description =
			"Restocks either one or all owned factories (MC businesses).\nUsage Example:\n  - yrv3.restock_factory 5\n  - yrv3.restock_factory all",
			args = { "all<string> | integer: from 1 to 7" }
		}
	},
	["yrv3.toggle_factory_production"] = {
		callback = function(args)
			local arg = args and args[1] or nil
			if (type(arg) == "string" and arg == "all") then
				for i = 1, 7 do
					YRV3:CommandToggleProduction(i, false)
				end
			elseif (type(arg) == "number") then
				YRV3:CommandToggleProduction(arg, false)
			else
				Notifier:ShowError("CommandExecutor", "Invalid command argument!")
			end
		end,
		opts = {
			description =
			"Toggles fast production for either one or all owned factories (MC businesses).\nUsage Example:\n  - yrv3.toggle_factory_production 5\n  - yrv3.toggle_factory_production all",
			args = { "all<string> | integer: from 1 to 7" }
		}
	},
	["yrv3.toggle_nightclub_production"] = {
		callback = function(args)
			local arg = args and args[1] or nil
			if (type(arg) == "string" and arg == "all") then
				for i = 1, 7 do
					YRV3:CommandToggleProduction(i, true)
				end
			elseif (type(arg) == "number") then
				YRV3:CommandToggleProduction(arg, true)
			else
				Notifier:ShowError("CommandExecutor", "Invalid command argument!")
			end
		end,
		opts = {
			description =
			"Toggles fast production for either one or all owned business hubs (Nightclub cargo).\nUsage Example:\n  - yrv3.toggle_nightclub_production 5\n  - yrv3.toggle_nightclub_production all",
			args = { "all<string> | integer: from 1 to 7" }
		}
	},
	["clonepv"] = {
		callback = function(args)
			local PV = LocalPlayer:GetVehicle()
			if not PV then
				Notifier:ShowError("CommandExecutor", _T("GENERIC_NOT_IN_VEH"))
				return
			end

			args       = args or {}
			local warp = args[1] or false
			PV:Clone({ warp_into = warp })
		end,
		opts = {
			args = { "Optional: warp_into<boolean>" },
			description =
			"Spawns an exact replica of the vehicle you're currently sitting in. Does nothing if you're on foot."
		}
	},
	["lockpv"] = {
		callback = function(_)
			local PV = LocalPlayer:GetVehicle()
			if (not PV:IsValid()) then
				return
			end

			local is_locked = PV:IsLocked()
			LocalPlayer:PlayKeyfobAnim()
			PV:LockDoors(not is_locked)
			CommandExecutor:notify(_T(is_locked and "VEH_UNLOCKED" or "VEH_LOCKED"))
		end,
		opts = {
			description = "Locks or unlocks your vehicle."
		}
	},
	["savepv"] = {
		callback = function(args)
			local PV = LocalPlayer:GetVehicle()
			if (not PV) then
				Notifier:ShowError("CommandExecutor", _T("GENERIC_NOT_IN_VEH"))
				return
			end

			args           = args or {}
			local filename = args[1]
			PV:SaveToJSON(filename)
		end,
		opts = {
			args = { "Optional: file_name<string>" },
			description = "Saves the vehicle you're currently sitting in to JSON."
		}
	},
	["spawnjsonveh"] = {
		callback = function(args)
			if (type(args) ~= "table") then
				Notifier:ShowError(
					"CommandExecutor",
					"Missing parameter. Usage: spawnjsonveh MyCustomVehicle.json",
					true,
					5
				)
				return
			end

			local filename = args[1]
			local warp     = args[2]
			Vehicle.CreateFromJSON(filename, warp)
		end,
		opts = {
			args = { "filename<string>", "Optional: warp_into<boolean>" },
			description = "Spawns a vehicle from JSON."
		}
	},
	["teleport"] = {
		callback = function(args)
			local notifE = function()
				Notifier:ShowError(
					"CommandExecutor",
					"Missing or incorrect parameter. Usage: teleport [X] [Y] [Z]",
					true,
					5
				)
			end

			if (type(args) ~= "table") then
				notifE()
				return
			end

			local x = args[1]
			local y = args[2]
			local z = args[3]

			if (#args < 2) then
				local wpc = Game.GetWaypointCoords()
				if (not wpc) then
					Notifier:ShowError(
						"CommandExecutor",
						"No waypoint active!",
						true,
						3
					)
					return
				end

				x, y, _ = wpc:unpack()
			end

			if (type(x) ~= "number" or type(y) ~= "number") then
				notifE()
				return
			end

			local coords = vec3:new(x, y, z or 0)
			LocalPlayer:Teleport(coords, false, z == nil)
		end,
		opts = {
			description =
			"Teleports to given coordinates or waypoint if none given. Will try to teleport to top level if no Z argument given.\nUsage Example:\n  - teleport 69 420 69\n  - tp 123.456 789.1011",
			args = { "X<number>", "Y<number>", "Optional: Z<number>" },
			alias = { "tp" }
		}
	},
}

return commandRegistry
