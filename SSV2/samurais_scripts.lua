-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local start_time = os.clock()
require("includes.init")

if (Backend:IsMockEnv()) then
	require("includes.tests")
	return
end

local function populate_weapons()
	local weapons     = require("includes.data.weapons")
	local weapons_map = {
		["GROUP_MELEE"]       = weapons.Melee,
		["GROUP_PISTOL"]      = weapons.Pistols,
		["GROUP_RIFLE"]       = weapons.AssaultRifles,
		["GROUP_SHOTGUN"]     = weapons.Shotguns,
		["GROUP_SMG"]         = weapons.SMG,
		["GROUP_MG"]          = weapons.MachineGuns,
		["GROUP_SNIPER"]      = weapons.SniperRifles,
		["GROUP_HEAVY"]       = weapons.Heavy,
		["GROUP_THROWN"]      = weapons.Throwables,
		["GROUP_PETROLCAN"]   = weapons.Misc,
		["GROUP_STUNGUN"]     = weapons.Misc,
		["GROUP_TRANQILIZER"] = weapons.Misc,
	}
	local weaponData  = require("includes.data.weapon_data")
	local branch      = Backend:GetGameBranch()
	for hash, data in pairs(weaponData) do
		if (branch == Enums.eGameBranch.LAGECY and data.model_name == "WEAPON_STRICKLER") then
			goto continue
		end

		if (not WEAPON.IS_WEAPON_VALID(hash)) then
			goto continue
		end

		data.display_name  = Game.GetGXTLabel(data.gxt)
		local weapon_group = weapons_map[data.group]
		if (not weapon_group) then
			goto continue
		end

		table.insert(weapon_group, hash)
		table.insert(weapons.All, hash)

		::continue::
	end
end

local function register_commands()
	local yimActions      = require("includes.features.extra.yim_actions.YimActionsV3")
	local commandRegistry = require("includes.lib.commands")
	for name, cmd in pairs(commandRegistry) do
		CommandExecutor:RegisterCommand(name, cmd.callback, cmd.opts)
	end

	yimActions:RegisterCommands()
end

GPointers:Init()
Serializer:FlushObjectQueue()
Backend:RegisterHandlers()
Translator:Load()
GUI:LateInit()

ThreadManager:Run(function()
	populate_weapons()
	register_commands()

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
