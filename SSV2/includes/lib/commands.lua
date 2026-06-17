-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- Raw command definition *(not the runtime `Command` object)*
---@class CommandDef
---@field callback fun(args: array<any>) -- CommandExecutor is guaranteed to feed an array into the callback. even if the command takes no arguments it will have an empty array.
---@field opts CommandMeta


local YRV3 = require("includes.features.online.yim_resupplier.YimResupplierV3")

---@param msg string
local function notify_err(msg)
	Notifier:ShowError("CommandExecutor", msg, true)
end

---@type dict<CommandDef>
return {
	["toggle_unsafe_feats"] = {
		callback = function(_)
			local cfg = GVars.features
			if (Game.IsFSL()) then
				cfg.unsafe_feats_enabled = true
				return
			end

			local newVal             = not cfg.unsafe_feats_enabled
			cfg.unsafe_feats_enabled = newVal
			local msg                = newVal and "YRV3_UNSAFE_FEATS_ENABLED" or "YRV3_UNSAFE_FEATS_DISABLED"
			local level              = newVal and Enums.eNotificationLevel.WARNING or Enums.eNotificationLevel.MESSAGE
			Notifier:Add("CommandExecutor", _T(msg), level)
		end,
		opts = {
			description = "Toggles unsafe features. Does nothing if FSL is enabled.",
			alias       = { "yolo", "dangerzone", "fuckit", "ilikeitraw" }
		}
	},
	["yrv3.fill_all_safes"] = {
		callback = function(_)
			if (not Game.IsOnline()) then
				notify_err(_T("GENERIC_UNAVAILABLE_SP"))
				return
			end

			YRV3:FillAllSafes()
		end,
		opts     = { description = "Fills all owned safes." }
	},
	["yrv3.finish_sale"] = {
		callback = function(_)
			if (not Game.IsOnline()) then
				notify_err(_T("GENERIC_UNAVAILABLE_SP"))
				return
			end

			YRV3:CommandFinishSale()
		end,
		opts     = { description = "Automatically finishes any sale mission you have at the moment (limited to missions supported by YRV3)." }
	},
	["yrv3.restock_all"] = {
		callback = function(_)
			if (not Game.IsOnline()) then
				notify_err(_T("GENERIC_UNAVAILABLE_SP"))
				return
			end

			YRV3:FillAll()
		end,
		opts     = { description = "Restocks all your owned businesses." }
	},
	["yrv3.restock_hangar"] = {
		callback = function(_)
			if (not Game.IsOnline()) then
				notify_err(_T("GENERIC_UNAVAILABLE_SP"))
				return
			end

			YRV3:CommandHangarAutoFill()
		end,
		opts     = { description = "Restocks your hangar." }
	},
	["yrv3.restock_warehouse"] = {
		callback = function(args)
			if (not Game.IsOnline()) then
				notify_err(_T("GENERIC_UNAVAILABLE_SP"))
				return
			end

			local office = YRV3:GetOffice()
			if (not office) then
				notify_err(_T("YRV3_CEO_OFFICE_NOT_OWNED"))
				return
			end

			local arg = args[1]
			if (type(arg) == "string" and arg == "all") then
				for _, wh in ipairs(office:GetCargoWarehouses()) do
					if (wh:IsValid() and not wh:HasFullProduction()) then
						wh.auto_fill = true
					end
				end
			elseif (type(arg) == "number") then
				YRV3:CommandWarehouseAutoFill(arg)
			else
				notify_err("Invalid command argument!")
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
			if (not Game.IsOnline()) then
				notify_err(_T("GENERIC_UNAVAILABLE_SP"))
				return
			end

			local arg = args[1]
			if (type(arg) == "string" and arg == "all") then
				for i = 1, 7 do
					YRV3:CommandFactoryRestock(i)
				end
			elseif (type(arg) == "number") then
				YRV3:CommandFactoryRestock(arg)
			else
				notify_err("Invalid command argument!")
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
			if (not Game.IsOnline()) then
				notify_err(_T("GENERIC_UNAVAILABLE_SP"))
				return
			end

			local arg = args[1]
			if (type(arg) == "string" and arg == "all") then
				for i = 1, 7 do
					YRV3:CommandToggleProduction(i, false)
				end
			elseif (type(arg) == "number") then
				YRV3:CommandToggleProduction(arg, false)
			else
				notify_err("Invalid command argument!")
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
			if (not Game.IsOnline()) then
				notify_err(_T("GENERIC_UNAVAILABLE_SP"))
				return
			end

			local arg = args[1]
			if (type(arg) == "string" and arg == "all") then
				for i = 1, 7 do
					YRV3:CommandToggleProduction(i, true)
				end
			elseif (type(arg) == "number") then
				YRV3:CommandToggleProduction(arg, true)
			else
				notify_err("Invalid command argument!")
			end
		end,
		opts = {
			description =
			"Toggles fast production for either one or all owned business hubs (Nightclub cargo).\nUsage Example:\n  - yrv3.toggle_nightclub_production 5\n  - yrv3.toggle_nightclub_production all",
			args = { "all<string> | integer: from 1 to 7" }
		}
	},
	["boss.register"] = {
		callback = function(args)
			if (not Game.IsOnline()) then
				notify_err(_T("GENERIC_UNAVAILABLE_SP"))
				return
			end
			local bosstype = args[1] ---@type number
			if (not AssertArg(bosstype, "bosstype", "number", notify_err)) then
				return
			end
			LocalPlayer:RegisterAsBoss(bosstype)
		end,
		opts = {
			description = "Registers you as a boss. The argument is a number between -1 and 1 and determines the boss type. Usage example:\n  - boss.register 0",
			args        = { "bosstype<number>: -1: Retire | 0: VIP/CEO | 1: MC>" },
		}
	},
	["boss.retire"] = {
		callback = function(_)
			if (not Game.IsOnline()) then
				notify_err(_T("GENERIC_UNAVAILABLE_SP"))
				return
			end

			LocalPlayer:Retire()
		end,
		opts     = { description = "Retire from being a boss. Does the same thing as invoking 'boss.register -1'." }
	},
	["money.withdraw"] = {
		callback = function(args)
			if (not Game.IsOnline()) then
				notify_err(_T("GENERIC_UNAVAILABLE_SP"))
				return
			end

			local amt = args[1] ---@type number
			if (not AssertArg(amt, "amount", "number", notify_err)) then
				return
			end

			local controller = LocalPlayer:GetMoneyController()
			if (amt <= 0) then
				if (amt == -1) then
					amt = controller:GetBankBalance()
				else
					notify_err("The specified amount is invalid. Only -1 or a number greater than 0 are accepted.")
					return
				end
			end

			-- executed in its own thread to avoid stalling CommandExecutor's main thread
			ThreadManager:Run(function() controller:Withdraw(amt) end)
		end,
		opts = {
			description = "[Online Only]: Transfers the specified amount from your bank account to your wallet. You can pass -1 to withdraw the maximum amount.",
			args        = { "amount<number>" },
		}
	},
	["money.deposit"] = {
		callback = function(args)
			if (not Game.IsOnline()) then
				notify_err(_T("GENERIC_UNAVAILABLE_SP"))
				return
			end

			local amt = args[1] ---@type number
			if (not AssertArg(amt, "amount", "number", notify_err)) then
				return
			end

			local controller = LocalPlayer:GetMoneyController()
			if (amt < 0) then
				if (amt == -1) then
					amt = controller:GetWalletBalance()
				else
					notify_err("The specified amount is invalid. Only -1 or a number bigger than 0 are accepted.")
					return
				end
			end

			-- executed in its own thread to avoid stalling CommandExecutor's main thread
			ThreadManager:Run(function() controller:Deposit(amt) end)
		end,
		opts = {
			description = "[Online Only]: Transfers the specified amount from your wallet to your bank account. You can pass -1 to deposit the maximum amount.",
			args        = { "amount<number>" },
		}
	},
	["clonepv"] = {
		callback = function(args)
			local PV = LocalPlayer:GetVehicle()
			if (not PV:IsValid()) then
				notify_err(_T("GENERIC_NOT_IN_VEH"))
				return
			end

			PV:Clone({ warp_into = (args[1] == true) })
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
			if (not PV:IsValid()) then return end

			local is_locked = PV:IsLocked()
			LocalPlayer:PlayKeyfobAnim()
			PV:LockDoors(not is_locked)
			CommandExecutor:notify(_T(is_locked and "VEH_UNLOCKED" or "VEH_LOCKED"))
		end,
		opts = { description = "Locks or unlocks your vehicle." }
	},
	["savepv"] = {
		callback = function(args)
			local PV = LocalPlayer:GetVehicle()
			if (not PV:IsValid()) then
				notify_err(_T("GENERIC_NOT_IN_VEH"))
				return
			end

			PV:SaveToJSON(args[1])
		end,
		opts = {
			args = { "Optional: file_name<string>" },
			description = "Saves the vehicle you're currently sitting in to JSON. Does nothing if you're on foot."
		}
	},
	["spawnjsonveh"] = {
		callback = function(args)
			local filename = args[1] ---@type string
			if (not AssertArg(filename, "filename", "string", notify_err)) then
				return
			end

			local warp = (args[2] == true)
			Vehicle.CreateFromJSON(filename, warp)
		end,
		opts = {
			args        = { "filename<string>", "Optional: warp_into<boolean>" },
			description = "Spawns a vehicle from JSON."
		}
	},
	["teleport"] = {
		callback = function(args)
			local x = args[1]
			local y = args[2]
			local z = args[3] or 0

			if (#args < 2) then
				local wpc = Game.GetWaypointCoords()
				if (not wpc) then
					notify_err("No waypoint active!")
					return
				end

				x, y, _ = wpc:unpack()
			end

			if ((type(x) ~= "number") or (type(y) ~= "number")) then
				notify_err("Missing or incorrect parameter. Usage: teleport <X> <Y> [Z]")
				return
			end

			local coords = vec3:new(x, y, z)
			LocalPlayer:Teleport(coords, false, z == 0)
		end,
		opts = {
			description =
			"Teleports to given coordinates or waypoint if none given. Will try to teleport to top level if no Z argument given.\nUsage Example:\n  - teleport 69 420 69\n  - tp 123.456 789.1011",
			args = { "X<number>", "Y<number>", "Optional: Z<number>" },
			alias = { "tp" }
		}
	},
	-- for copy/paste convenience. keep at the bottom
	--[[
	["example"] = {
		callback = function(args)
			doStuff()
		end,
		opts = {
			description = "blah blah",
			args        = { "p0<number>", "p1<boolean>", "..." },
			alias       = { "ex", }
		}
	},
	]]
}
