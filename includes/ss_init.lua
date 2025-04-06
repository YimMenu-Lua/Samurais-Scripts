local s_basePath = "includes"
local t_packages = {
    "data.globals",
    "classes.color",
    "classes.commands",
    "classes.memory",
    "classes.vector2",
    "classes.vector3",
    "classes.translator",
    "classes.cGame",
    "classes.cSelf",
    "classes.cVehicle",
    "classes.VehicleManager",
    "data.refs",
    "data.actions",
    "data.objects",
    "lib.ss_utils",
    "gui.grid_renderer",
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

for _, package in pairs(t_packages) do
    require(string.format("%s.%s", s_basePath, package))
end
