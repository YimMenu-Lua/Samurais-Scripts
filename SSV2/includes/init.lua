-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- Entry point for the entire Lua project.
--
-- Sets up global services, initializes pointer scanning, and makes
--
-- pointers available globally through the `GPointers` table.
---@module "init"


-- ### Namespace: Enums
--
-- All enums are stored here to avoid polluting the global namespace.
--
-- Exposed globally so it can be extended from anywhere.
Enums = require("includes.data.enums.__init__")

---@enum eGameBranch
Enums.eGameBranch = {
	LEGACY   = 1,
	ENHANCED = 2,
	MOCK     = 99,
}


---@class VersionInfo
---@field build string
---@field online string

local SCRIPT_NAME <const>    = "Samurai's Scripts"
local SCRIPT_VERSION <const> = require("includes.version")
local DEFAULT_CONFIG <const> = require("includes.data.config")

---@alias GAME_VERSION table<eGameBranch, VersionInfo>
---@type GAME_VERSION
local GAME_VERSION <const>   = {
	[Enums.eGameBranch.LEGACY]   = { build = "3889.0", online = "1.73" },
	[Enums.eGameBranch.ENHANCED] = { build = "1158.13", online = "1.73" },
	[Enums.eGameBranch.MOCK]     = { build = "any", online = "any" },
}


-- ### Backend Module
--
-- provides centralized lifecycle and entity management across all environments.
--
-- It handles API/environment detection, cleanup logic, entity and blip tracking, etc.
--
-- This is the core system that ensures safe, predictable behavior when switching sessions, reloading scripts, or shutting down.
Backend = require("includes.backend"):init(SCRIPT_NAME, SCRIPT_VERSION, GAME_VERSION)


require("includes.lib.meta")
require("includes.lib.callable")
require("includes.lib.class")
require("includes.lib.enum")
require("includes.lib.extensions.__init__")
require("includes.modules.Accessor")


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
Serializer    = require("includes.services.Serializer"):Setup("ssv2", DEFAULT_CONFIG, GVars)


-- These may look out of place, but they register themselves with Serializer for seamless
--
-- object serialization and deserialization. They are also needed in the next batch of
--
-- services, especially vec2, hence the weird stage they are required at.
require("includes.classes.Vector2")
require("includes.classes.Vector3")
require("includes.classes.Vector4")
require("includes.modules.Color")


GPointers       = require("includes.data.pointers")
GGlobals        = require("includes.data.script_globals")
Memory          = require("includes.modules.Memory")
KeyManager      = require("includes.services.KeyManager")
GUI             = require("includes.services.GUI")
Notifier        = require("includes.services.ToastNotifier").new()
CommandExecutor = require("includes.services.CommandExecutor"):init()
Translator      = require("includes.services.Translator")
----------------------------------------------------------------------------------------------------


local base_path = "includes."
local sub_paths = {
	"modules.Entity",
	"modules.Object",
	"modules.Ped",
	"modules.Player",
	"modules.Vehicle",
	"modules.LocalPlayer",

	"frontend.self.self_ui",
	"frontend.vehicle.vehicle_ui",
	"frontend.world_ui",

	"frontend.yim_resupplier.yrv3_ui",
	"frontend.casino_ui",
	"frontend.mastermind_ui",
	"frontend.stat_controller_ui",

	"frontend.billionaire_services.bsv2_ui",
	"frontend.entity_forge.entity_forge_ui",
	"frontend.yim_actions.yav3_ui",

	"frontend.settings.settings_ui",
}

for _, sub_path in ipairs(sub_paths) do
	xpcall(require,
		function(err)
			log.warning(tostring(err))
		end,
		base_path .. sub_path
	)
end
