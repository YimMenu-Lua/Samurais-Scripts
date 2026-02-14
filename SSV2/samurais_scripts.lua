-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local commandRegistry = require("includes.lib.commands")
local Weapons         = require("includes.data.weapons")
local weaponData      = require("includes.data.weapon_data")
local weapons_map     = {
	["GROUP_MELEE"]       = Weapons.Melee,
	["GROUP_PISTOL"]      = Weapons.Pistols,
	["GROUP_RIFLE"]       = Weapons.AssaultRifles,
	["GROUP_SHOTGUN"]     = Weapons.Shotguns,
	["GROUP_SMG"]         = Weapons.SMG,
	["GROUP_MG"]          = Weapons.MachineGuns,
	["GROUP_SNIPER"]      = Weapons.SniperRifles,
	["GROUP_HEAVY"]       = Weapons.Heavy,
	["GROUP_THROWN"]      = Weapons.Throwables,
	["GROUP_PETROLCAN"]   = Weapons.Misc,
	["GROUP_STUNGUN"]     = Weapons.Misc,
	["GROUP_TRANQILIZER"] = Weapons.Misc,
}

local function populate_weapons()
	for hash, data in pairs(weaponData) do
		data.display_name  = Game.GetGXTLabel(data.gxt)
		local weapon_group = weapons_map[data.group]
		if (not weapon_group) then
			goto continue
		end

		table.insert(weapon_group, hash)
		table.insert(Weapons.All, hash)

		::continue::
	end
end

require("includes.init")

GPointers:Init()
Serializer:FlushObjectQueue()
Backend:RegisterHandlers()
Translator:Load()
GUI:LateInit()

ThreadManager:Run(function()
	local start_time = os.clock()
	for name, cmd in pairs(commandRegistry) do
		CommandExecutor:RegisterCommand(name, cmd.callback, cmd.opts)
	end

	YimActions:RegisterCommands()

	populate_weapons()

	KeyManager:RegisterKeybind(eVirtualKeyCodes.NUMPAD8, function()
		LocalPlayer:GetVehicle():RamForward()
	end)

	KeyManager:RegisterKeybind(eVirtualKeyCodes.NUMPAD4, function()
		LocalPlayer:GetVehicle():RamLeft()
	end)

	KeyManager:RegisterKeybind(eVirtualKeyCodes.NUMPAD6, function()
		LocalPlayer:GetVehicle():RamRight()
	end)

	while not PatternScanner:IsDone() do
		yield()
	end

	Backend:debug("Script loaded in %.0fms", (os.clock() - start_time) * 1000)
end)

print(Game.GetGXTLabel("AWT_521"))
