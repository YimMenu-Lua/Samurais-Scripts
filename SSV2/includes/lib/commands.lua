local businessCommandCallbacks <const> = {
	["hangar"] = function(_)
		YRV3.m_hangar_loop = not YRV3.m_hangar_loop
		Notifier:ShowMessage("YRV3",
			_F("Hangar auto-fill %s.", YRV3.m_hangar_loop and "enabled" or "disabled"),
			false, 1.5
		)
	end,
	["warehouse"] = function(index)
		if (type(index) ~= "number") then
			Notifier:ShowError("CommandExecutor",
				"Missing or invalid warehouse index! Usage: autofill warehouse <number> (a number from 1 to 5)")
			return
		end

		YRV3:WarehouseAutofillOnCommand(index)
	end,
	["all"] = function(_)
		YRV3:FillAll()
	end,
}

local commandRegistry <const> = {
	["autofill"] = {
		callback = function(args)
			if (not Game.IsOnline()) then
				Notifier:ShowError("Samurai's Scripts", "Unavailable in Single Player!")
				return
			end

			local business = args[1]
			local arg2 = args[2]
			if (type(business) ~= "string") then
				Notifier:ShowError(
					"CommandExecutor",
					_F("Invalid command argument %s. Argmuments are: hangar | warehouse <number>", business)
				)
				return
			end

			local callback = businessCommandCallbacks[business:lower()]
			if ((type(callback) ~= "function")) then
				Notifier:ShowError("CommandExecutor", _F("Unknown argument %s", business))
				return
			end

			callback(arg2)
		end,
		opts = {
			args = { "all<string> | hangar<string> | warehouse<string> index<number>" },
			description =
			"Auto fills businesses based on argument passed. For hangar or all businesses, you can simply pass 'hangar' and 'all' respectively. For warehouses, you have to also specify which one, ex: 'autofill warehouse 1'"
		}
	},
	["finishsale"] = {
		callback = function()
			YRV3:FinishSaleOnCommand()
		end,
		opts = { description = "Automatically finishes any sale mission you have at the moment (limited to missions supported by YRV3)." }
	},
	["clonepv"] = {
		callback = function(args)
			ThreadManager:Run(function()
				local PV = Self:GetVehicle()
				if not PV then
					Notifier:ShowError("CommandExecutor", "You are not in a vehicle.")
					return
				end

				local warp = args and args[1] or false
				PV:Clone({ warp_into = warp })
			end)
		end,
		opts = {
			args = { "Optional: warp_into<boolean>" },
			description =
			"Spawns an exact replica of the vehicle you're currently sitting in. Does nothing if you're on foot."
		}
	},
	["lockpv"] = {
		callback = function(_)
			ThreadManager:Run(function()
				local PV = Self:GetVehicle()
				if (not PV:IsValid()) then
					return
				end

				local is_locked = PV:IsLocked()
				Self:PlayKeyfobAnim()
				PV:LockDoors(not PV:IsLocked())
				CommandExecutor:notify(_T(is_locked and "VEH_UNLOCKED" or "VEH_LOCKED"))
			end)
		end,
		opts = {
			description = "Locks or unlocks your vehicle."
		}
	},
	["savepv"] = {
		callback = function(args)
			ThreadManager:Run(function()
				local PV = Self:GetVehicle()
				if not PV then
					Notifier:ShowError("CommandExecutor", "You are not in a vehicle.")
					return
				end

				local filename = args and args[1] or nil
				PV:SaveToJSON(filename)
			end)
		end,
		opts = {
			args = { "Optional: file_name<string>" },
			description = "Saves the vehicle you're currently sitting in to JSON."
		}
	},
	["spawnjsonveh"] = {
		callback = function(args)
			ThreadManager:Run(function()
				if (type(args) ~= "table") then
					Notifier:ShowError("CommandExecutor", "Missing parameter. Usage: spawnjsonveh MyCustomVehicle.json",
						true)
				end

				local filename = args[1]
				local warp = args[2]

				Vehicle.CreateFromJSON(filename, warp)
			end)
		end,
		opts = {
			args = { "filename<string>", "Optional: warp_into<boolean>" },
			description = "Spawns a vehicle from JSON."
		}
	},
}

return commandRegistry
