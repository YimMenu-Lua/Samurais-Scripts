local businessCommandCallbacks <const> = {
    ["hangar"] = function(_)
        YRV3.m_hangar_loop = not YRV3.m_hangar_loop
        Toast:ShowMessage("YRV3",
            _F("Hangar auto-fill %s.", YRV3.m_hangar_loop and "enabled" or "disabled"),
            false, 1.5
        )
    end,
    ["warehouse"] = function(index)
        if (type(index) ~= "number") then
            Toast:ShowError("CommandExecutor", "Missing or invalid warehouse index! Usage: autofill warehouse <number> (a number from 1 to 5)")
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
                Toast:ShowError("Samurai's Scripts", "Unavailable in Single Player!")
                return
            end

            local business = args[1]
            local arg2 = args[2]
            if (type(business) ~= "string") then
                Toast:ShowError("CommandExecutor", _F("Invalid command argument %s. Argmuments are: hangar | warehouse <number>", business))
                return
            end

            local callback = businessCommandCallbacks[business:lower()]
            if ((type(callback) ~= "function")) then
                Toast:ShowError("CommandExecutor", _F("Unknown argument %s", business))
                return
            end

            callback(arg2)
        end,
        opts = {
            args =  { "all<string> | hangar<string> | warehouse<string> index<number>" },
            description = "Auto fills businesses based on argument passed. For hangar or all businesses, you can simply pass 'hangar' and 'all' respectively. For warehouses, you have to also specify which one, ex: 'autofill warehouse 1'"
        }
    },

    ["finishsale"] = {
        callback = function()
            YRV3:FinishSaleOnCommand()
        end,
        opts = {description = "Automatically finishes any sale mission you have at the moment (limited to missions supported by YRV3)."}
    },

    ["clonepv"] = {
        callback = function(args)
            ThreadManager:RunInFiber(function()
                local PV = Self:GetVehicle()
                if not PV then
                    Toast:ShowError("CommandExecutor", "You are not in a vehicle.")
                    return
                end

                local warp = args and args[1] or false
                PV:Clone({ warp_into = warp })
            end)
        end,
        opts = {
            args = { "Optional: warp_into<boolean>" },
            description = "Spawns an exact replica of the vehicle you're currently sitting in. Does nothing if you're on foot."
        }
    },

    ["savepv"] = {
        callback = function(args)
            ThreadManager:RunInFiber(function()
                local PV = Self:GetVehicle()
                if not PV then
                    Toast:ShowError("CommandExecutor", "You are not in a vehicle.")
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
            ThreadManager:RunInFiber(function()
                if (type(args) ~= "table") then
                    Toast:ShowError("CommandExecutor", "Missing parameter. Usage: spawnjsonveh MyCustomVehicle.json", true)
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

    ["fastvehs"] = {
        callback = function(_)
            GVars.features.vehicle.fast_vehicles = not GVars.features.vehicle.fast_vehicles
            Toast:ShowMessage(
                    "Samurai's Scripts",
                    ("Fast Vehicles %s"):format(GVars.features.vehicle.fast_vehicles and "enabled" or "disabled"),
                    false,
                    1.5
                )
        end,
        opts = { description = "Increases the top speed of any land vehicle you drive." }
    }
}

return commandRegistry
