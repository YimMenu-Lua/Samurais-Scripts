-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local commandRegistry = require("includes.lib.commands")
local Weapons         = require("includes.data.weapons")

---@param t table
---@param group_type string
local function populate_weapon_list(t, group_type)
	for _, v in ipairs(weapons.get_all_weapons_of_group_type(group_type)) do
		local hash = joaat(v)
		table.insert(t, hash)
		table.insert(Weapons.All, hash)
	end
end

local weapons_map = {
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

	for group_name, list in pairs(weapons_map) do
		populate_weapon_list(list, group_name)
	end

	KeyManager:RegisterKeybind(eVirtualKeyCodes.NUMPAD8, function()
		Self:GetVehicle():RamForward()
	end)

	KeyManager:RegisterKeybind(eVirtualKeyCodes.NUMPAD4, function()
		Self:GetVehicle():RamLeft()
	end)

	KeyManager:RegisterKeybind(eVirtualKeyCodes.NUMPAD6, function()
		Self:GetVehicle():RamRight()
	end)

	while not PatternScanner:IsDone() do
		yield()
	end

	Backend:debug("Script loaded in %.0fms", (os.clock() - start_time) * 1000)
end)
