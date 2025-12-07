-- Entry point for the entire Lua project.
--
-- Sets up global services, initializes pointer scanning, and makes
--
-- pointers available globally through the `GPointers` table.
---@module "init"


local SCRIPT_NAME    <const> = "Samurai's Scripts"
local SCRIPT_VERSION <const> = "1.7.2"
local TARGET_BUILD   <const> = "3586.0"
local TARGET_VERSION <const> = "1.71"
local DEFAULT_CONFIG <const> = {
    backend = {
        auto_cleanup_entities = false,
        language_index = 1,
        language_code = "en-US",
        language_name = "English"
    },
    ui = {
        disable_tooltips = false,
        disable_sound_feedback = false,
    },
    commands_console = {
        key = "F5",
        auto_close = false,
    },
    keyboard_keybinds = {},
    gamepad_keybinds = {},
    autofill_delay = 500,
}

require("includes.backend")
Backend:init(SCRIPT_NAME, SCRIPT_VERSION, TARGET_BUILD, TARGET_VERSION)

require("includes.lib.types")
require("includes.lib.utils")
require("includes.lib.class")
require("includes.lib.enum")
require("includes.classes.Range")
require("includes.classes.Vector2")
require("includes.classes.Vector3")
require("includes.classes.Vector4")
require("includes.classes.fMatrix44")
require("includes.classes.atArray")
require("includes.data.pointers")

Memory = require("includes.modules.Memory")
require("includes.modules.Game")


-- ### Global Runtime Variables
--
-- Used for persistent state that should be saved between sessions.
--
-- Any value assigned to GVars is automatically serialized to JSON (via __index | __newindex).
-- 
-- For temporary or internal state that should not be saved, use `_G` directly.
GVars = {}

-- ### Script Globals & Script Locals
--
-- It is highly recommended to not index `SG_SL` directly and instead use the `GetScriptGlobalOrLocal` function.
-- ___
-- - Example 1:
--
--```lua
-- local pv_global = GetScriptGlobalOrLocal("personal_vehicle_global") -- returns the value of the script global/local
-- -- create your script global object
-- local pv_global_object = ScriptGlobal(pv_global)
--```
--
-- - Example 2:
--
--```lua
-- local pv_global_table = GetScriptGlobalOrLocal("personal_vehicle_global", true) -- returns the full table.
-- -- create your script global object
-- local pv_global_object = ScriptGlobal(pv_global_table.value)
--```
--
-- - Not Recommended:
--
--```lua
-- local pv_global = SG_SL.personal_vehicle_global.LEGACY.value -- direct indexing is not recommended.
--```
SG_SL = require("includes.data.globals_locals")

----------------------------------------------------------------------------------------------------
-- These services must be loaded before any class that registers with/uses them -------------------
ThreadManager = require("includes.services.ThreadManager"):init()
GPointers:Init() -- needs ThreadManager

Serializer      = require("includes.services.Serializer"):init(SCRIPT_NAME, DEFAULT_CONFIG, GVars)
KeyManager      = require("includes.services.KeyManager"):init()
GUI             = require("includes.services.GUI"):init()
Toast           = require("includes.services.ToastNotifier").new()
CommandExecutor = require("includes.services.CommandExecutor").new()
----------------------------------------------------------------------------------------------------

------------------- Features ------------------------------------

YRV3 = require("includes.features.yrv3"):init()
CasinoPacino = require("includes.features.casino"):init()
SalvageYard = require("includes.features.salvage"):init()

------------------------------------------------------------------

local base_path = "includes"
local packages = {
    "data.enums",
    "data.refs",
    "data.peds",
    "data.vehicles",
    "data.weapons",

    "modules.Accessor",
    "modules.Decorator",
    "modules.Color",
    "modules.Entity",
    "modules.Object",
    "modules.Ped",
    "modules.Player",
    "modules.Self",
    "modules.Vehicle",

    "services.GridRenderer",
    "services.Translator",

    "gui.main_ui",
    "gui.settings_ui",
    "gui.yrv3_ui",
    "gui.casino_ui",
    "gui.salvage_ui",
}

for _, package in ipairs(packages) do
    require(_F("%s.%s", base_path, package))
end

Serializer:FlushObjectQueue()
Backend:RegisterHandlers()
Translator:Load()
GUI:Draw()
