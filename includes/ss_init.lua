local s_basePath = "includes"
local t_packages = {
    "classes.vector2",
    "classes.vector3",
    "data.globals",
    "classes.color",
    "classes.commands",
    "classes.memory",
    "classes.translator",
    "classes.cGame",
    "classes.cSelf",
    "classes.cVehicle",
    "classes.VehicleManager",
    "classes.PreviewService",
    "classes.EntityForge",
    "data.refs",
    "data.actions",
    "data.objects",
    "data.vehicles",
    "data.peds",
    "lib.ss_utils",
    "gui.grid_renderer",
    "gui.custom_paints",
    "gui.drift_mode",
    "gui.dunk",
    "gui.entity_forge",
    "gui.flatbed",
    "gui.handling_editor",
    "gui.main",
    "gui.self",
    "gui.settings",
    "gui.soundplayer",
    "gui.vehicle",
    "gui.weapon",
    "gui.world",
    "gui.yimactions2",
    "gui.yrv2",
}

for _, package in pairs(t_packages) do
    require(string.format("%s.%s", s_basePath, package))
end
