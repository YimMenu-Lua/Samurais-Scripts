require("includes.data.globals")

local basePath = "includes"
local packages = {
    "data.refs",
    "data.actions",
    "data.commands",
    "data.objects",
    "lib.samurais_utils",
    "lib.Translations",
    "classes.vector2",
    "classes.vector3",
    "gui.main",
    "gui.self",
    "gui.yimactions2",
    "gui.soundplayer",
    "gui.weapon",
    "gui.vehicle",
    "gui.custom_paints",
    "gui.drift_mode",
    "gui.flatbed",
    "gui.handling_editor",
    "gui.vehicle_creator",
    "gui.yrv2",
    "gui.dunk",
    "gui.world",
    "gui.object_spawner",
    "gui.settings",
}

local __init = coroutine.create(function()
    for key, _ in pairs(DEFAULT_CONFIG) do
        _G[key] = CFG:ReadItem(key)
        coroutine.yield()
    end

    for _, package in pairs(packages) do
        require(string.format("%s.%s", basePath, package))
    end
end)

while coroutine.status(__init) ~= "dead" do
    coroutine.resume(__init)
end
