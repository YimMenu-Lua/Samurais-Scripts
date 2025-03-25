local basePath = "includes"
local packages = {
    "data.globals",
    "classes.commands",
    "classes.translator",
    "classes.vector2",
    "classes.vector3",
    "data.refs",
    "data.actions",
    "data.objects",
    "lib.samurais_utils",
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

for _, package in pairs(packages) do
    require(string.format("%s.%s", basePath, package))
end
