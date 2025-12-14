---@diagnostic disable: lowercase-global

require("includes.init")
local commandRegistry = require("includes.lib.commands")

Serializer:FlushObjectQueue()
Backend:RegisterHandlers()
Translator:Load()
GUI:LateInit()

script.run_in_fiber(function()
	local start_time = os.clock()
	for name, cmd in pairs(commandRegistry) do
		CommandExecutor:RegisterCommand(name, cmd.callback, cmd.opts)
	end

	t_MeleeWeapons = weapons.get_all_weapons_of_group_type("GROUP_MELEE")
	t_Handguns = weapons.get_all_weapons_of_group_type("GROUP_PISTOL")
	t_AssaultRifles = weapons.get_all_weapons_of_group_type("GROUP_RIFLE")
	t_Shotguns = weapons.get_all_weapons_of_group_type("GROUP_SHOTGUN")
	t_SMG = weapons.get_all_weapons_of_group_type("GROUP_SMG")
	t_MachineGuns = weapons.get_all_weapons_of_group_type("GROUP_MG")
	t_SniperRifles = weapons.get_all_weapons_of_group_type("GROUP_SNIPER")
	t_HeavyWeapons = weapons.get_all_weapons_of_group_type("GROUP_HEAVY")
	t_Throwables = weapons.get_all_weapons_of_group_type("GROUP_THROWN")

	for _, wpn in ipairs(weapons.get_all_weapons_of_group_type("GROUP_PETROLCAN")) do
		table.insert(t_MiscWeapons, wpn)
	end

	for _, wpn in ipairs(weapons.get_all_weapons_of_group_type("GROUP_STUNGUN")) do
		table.insert(t_MiscWeapons, wpn)
	end

	for _, wpn in ipairs(weapons.get_all_weapons_of_group_type("GROUP_TRANQILIZER")) do
		table.insert(t_MiscWeapons, wpn)
	end

	for _, t in ipairs({
		t_MeleeWeapons,
		t_Handguns,
		t_AssaultRifles,
		t_Shotguns,
		t_SMG,
		t_MachineGuns,
		t_SniperRifles,
		t_HeavyWeapons,
		t_Throwables
	}) do
		for _, wpn in ipairs(t) do
			table.insert(t_AllWeapons, wpn)
		end
	end

	while not PatternScanner:IsDone() do
		yield()
	end

	Backend:debug("Script loaded in %.0fms", (os.clock() - start_time) * 1000)
end)
