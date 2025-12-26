-- Entry point for the entire Lua project.
--
-- Sets up global services, initializes pointer scanning, and makes
--
-- pointers available globally through the `GPointers` table.
---@module "init"


local SCRIPT_NAME <const>    = "Samurai's Scripts"
local SCRIPT_VERSION <const> = "1.7.4"
local TARGET_BUILD <const>   = "any"
local TARGET_VERSION <const> = "any"
local DEFAULT_CONFIG <const> = require("includes.data.config")

-- ### Enums Namespace.
--
-- All enums are stored here to avoid polluting the global namespace.
Enums                        = require("includes.data.enums.__init")

require("includes.backend")
Backend:init(SCRIPT_NAME, SCRIPT_VERSION, TARGET_BUILD, TARGET_VERSION)

require("includes.lib.types")
require("includes.lib.utils")
require("includes.lib.imgui_ext")
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

----------------------------------------------------------------------------------------------------
-- These services must be loaded before any class that registers with/uses them -------------------
ThreadManager = require("includes.services.ThreadManager"):init()
GPointers:Init() -- needs ThreadManager
Serializer = require("includes.services.Serializer"):init("ssv2", DEFAULT_CONFIG, GVars)

require("includes.classes.Vector2")
require("includes.classes.Vector3")
require("includes.classes.Vector4")

KeyManager          = require("includes.services.KeyManager"):init()
GUI                 = require("includes.services.GUI"):init()
Toast               = require("includes.services.ToastNotifier").new()
CommandExecutor     = require("includes.services.CommandExecutor").new()
----------------------------------------------------------------------------------------------------

------------------- Features -----------------------------------------------------------------------
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
