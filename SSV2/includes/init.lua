-- Entry point for the entire Lua project.
--
-- Sets up global services, initializes pointer scanning, and makes
--
-- pointers available globally through the `GPointers` table.
---@module "init"


local SCRIPT_NAME <const>    = "Samurai's Scripts"
local SCRIPT_VERSION <const> = require("includes.version")
local DEFAULT_CONFIG <const> = require("includes.data.config")
local TARGET_BUILD <const>   = "any"
local TARGET_VERSION <const> = "any"

-- ### Enums Namespace.
--
-- All enums are stored here to avoid polluting the global namespace.
Enums                        = require("includes.data.enums.__init")

-- ### Backend Module
--
-- provides centralized lifecycle and entity management across all environments.
--
-- It handles API/environment detection, cleanup logic, entity and blip tracking, etc.
--
-- This is the core system that ensures safe, predictable behavior when switching sessions, reloading scripts, or shutting down.
Backend                      = require("includes.backend"):init(SCRIPT_NAME, SCRIPT_VERSION, TARGET_BUILD, TARGET_VERSION)

require("includes.lib.types")
require("includes.lib.utils")
require("includes.lib.imgui_ext")
require("includes.lib.class")
require("includes.lib.enum")
require("includes.classes.Pair")
require("includes.classes.Range")
require("includes.classes.Rect")
require("includes.classes.Set")
require("includes.classes.gta.fMatrix44")
require("includes.classes.gta.atArray")
require("includes.modules.Accessor")


-- ### Global Runtime Variables
--
-- Used for persistent state that should be saved between sessions.
--
-- Any value assigned to GVars is automatically serialized to JSON.
--
-- For temporary or internal state that should not be saved, use `_G` directly.
---@class GVars : Config
GVars         = {}

----------------------------------------------------------------------------------------------------
-- These services must be loaded before any class that registers with/uses them -------------------
ThreadManager = require("includes.services.ThreadManager"):init()
Serializer    = require("includes.services.Serializer"):init("ssv2", DEFAULT_CONFIG, GVars)

-- These may look out of place, but they register themselves with Serializer for seamless
--
-- object serialization and deserialization. They are also needed in the next batch of
--
-- services, especially vec2, hence the weird stage they are required at.
require("includes.classes.Vector2")
require("includes.classes.Vector3")
require("includes.classes.Vector4")
require("includes.modules.Color")

GPointers           = require("includes.data.pointers")
Memory              = require("includes.modules.Memory")
KeyManager          = require("includes.services.KeyManager"):init()
GUI                 = require("includes.services.GUI"):init()
Notifier            = require("includes.services.ToastNotifier").new()
CommandExecutor     = require("includes.services.CommandExecutor"):init()
----------------------------------------------------------------------------------------------------

----------------- Big Features (for smaller features, refer to includes/features) ------------------
BillionaireServices = require("includes.features.BillionaireServicesV2"):init()
EntityForge         = require("includes.features.EntityForge"):init()
YimActions          = require("includes.features.YimActionsV3"):init()
YRV3                = require("includes.features.YimResupplierV3"):init()
----------------------------------------------------------------------------------------------------

local base_path     = "includes"
local packages      = {
	"data.refs",
	"data.weapons",

	"structs.StateMachine",

	"modules.Audio",
	"modules.Decorator",
	"modules.Entity",
	"modules.Object",
	"modules.Ped",
	"modules.Player",
	"modules.Vehicle",
	"modules.Self",

	"services.GridRenderer",
	"services.Translator",

	"frontend.entity_forge_ui",
	"frontend.bsv2_ui",
	"frontend.casino_ui",
	"frontend.salvage_ui",
	"frontend.self_ui",
	"frontend.settings.settings_ui",
	"frontend.vehicle.vehicle_ui",
	"frontend.world_ui",
	"frontend.yav3_ui",
	"frontend.yrv3_ui",
}

for _, package in ipairs(packages) do
	xpcall(require,
		function(err)
			log.warning(tostring(err))
		end,
		_F("%s.%s", base_path, package)
	)
end
