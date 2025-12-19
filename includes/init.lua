-- Entry point for the entire Lua project.
--
-- Sets up global services, initializes pointer scanning, and makes
--
-- pointers available globally through the `GPointers` table.
---@module "init"


local SCRIPT_NAME <const> = "SSV2"
local SCRIPT_VERSION <const> = "1.7.4 beta"
local TARGET_BUILD <const> = "3725.0"
local TARGET_VERSION <const> = "1.72"
local DEFAULT_CONFIG <const> = require("includes.data.config")

require("includes.backend")
Backend:init(SCRIPT_NAME, SCRIPT_VERSION, TARGET_BUILD, TARGET_VERSION)

require("includes.lib.types")
require("includes.lib.utils")
require("includes.lib.class")
require("includes.lib.enum")
require("includes.classes.Pair")
require("includes.classes.Range")
require("includes.classes.Rect")
require("includes.classes.Set")
require("includes.classes.fMatrix44")
require("includes.classes.atArray")

GPointers = require("includes.data.pointers")
Memory = require("includes.modules.Memory")
require("includes.modules.Game")


-- ### Global Runtime Variables
--
-- Used for persistent state that should be saved between sessions.
--
-- Any value assigned to GVars is automatically serialized to JSON.
--
-- For temporary or internal state that should not be saved, use `_G` directly.
---@class GVars : Config
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
Serializer = require("includes.services.Serializer"):init(SCRIPT_NAME, DEFAULT_CONFIG, GVars)

require("includes.classes.Vector2")
require("includes.classes.Vector3")
require("includes.classes.Vector4")

KeyManager      = require("includes.services.KeyManager"):init()
GUI             = require("includes.services.GUI"):init()
Toast           = require("includes.services.ToastNotifier").new()
CommandExecutor = require("includes.services.CommandExecutor").new()
----------------------------------------------------------------------------------------------------

------------------- Features -----------------------------------------------------------------------
require("includes.features.Speedometer")
YRV3 = require("includes.features.YRV3"):init()
----------------------------------------------------------------------------------------------------

local base_path = "includes"
local packages = {
	"data.enums",
	"data.refs",
	"data.peds",
	"data.vehicles",
	"data.weapons",

	"structs.StateMachine",

	"modules.Accessor",
	"modules.Audio",
	"modules.Decorator",
	"modules.Color",
	"modules.Entity",
	"modules.Object",
	"modules.Ped",
	"modules.Player",
	"modules.Vehicle",
	"modules.Self",

	"services.GridRenderer",
	"services.Translator",

	"frontend.casino_ui",
	"frontend.salvage_ui",
	"frontend.self_ui",
	"frontend.settings_ui",
	"frontend.vehicle_ui",
	"frontend.yrv3_ui",
}

for _, package in ipairs(packages) do
	require(_F("%s.%s", base_path, package))
end
