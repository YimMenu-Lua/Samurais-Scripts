-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Decorator      = require("includes.modules.Decorator")
local PreviewService = require("includes.services.PreviewService")
local ClearPreview   = function() PreviewService:Clear() end


---@class BlipData
---@field handle integer
---@field owner integer
---@field alpha integer

---@enum eBackendEvent
Enums.eBackendEvent      = {
	RELOAD_UNLOAD  = 1,
	PLAYER_SWITCH  = 2,
	SESSION_SWITCH = 3,
	SESSION_JOIN   = 4,
	SESSION_LEAVE  = 5,
}

---@enum eEntityType
Enums.eEntityType        = {
	Invalid = -1,
	Ped     = 1,
	Vehicle = 2,
	Object  = 3
}

local mouse_keys <const> = {
	18,
	24,
	25,
	68,
	69,
	70,
	91,
	92,
	106,
	114,
	122,
	135,
	142,
	144,
	176,
	223,
	229,
	237,
	257,
	294,
}
local disableControl     = PAD.DISABLE_CONTROL_ACTION
local function disableMouseInput()
	for _, action in ipairs(mouse_keys) do
		disableControl(0, action, true)
	end
end


-- Global Singleton.
---@class Backend
---@field private m_game_branch eGameBranch
local Backend = {
	__version                = "",
	target_build             = "",
	target_version           = "",
	disable_input            = false, -- Never serialize this runtime variable!
	is_in_session_transition = false,
	is_in_player_transition  = false,

	---@type table<integer, integer>
	ControlsToDisable        = {},

	---@type table<integer, BlipData>
	CreatedBlips             = {},

	---@type array<handle>
	AttachedEntities         = {},

	---@type table<eBackendEvent, array<function>>
	EventCallbacks           = {
		[Enums.eBackendEvent.RELOAD_UNLOAD]  = { ClearPreview },
		[Enums.eBackendEvent.PLAYER_SWITCH]  = { ClearPreview },
		[Enums.eBackendEvent.SESSION_SWITCH] = {},
		[Enums.eBackendEvent.SESSION_LEAVE]  = {},
	},

	---@type table<eEntityType, table<handle, handle>>
	SpawnedEntities          = {
		[Enums.eEntityType.Ped]     = {},
		[Enums.eEntityType.Vehicle] = {},
		[Enums.eEntityType.Object]  = {},
	},

	---@type table<eEntityType, integer>
	MaxAllowedEntities       = {
		[Enums.eEntityType.Ped]     = 25,
		[Enums.eEntityType.Vehicle] = 15,
		[Enums.eEntityType.Object]  = 35,
	},

	---@type table<string, fun(handle: handle): any>
	FeatureEntityHandlers    = {},

	---@type table<uint64_t, pointer>
	AllocatedPointers        = {}
}; Backend.__index = Backend

---@param name string
---@param script_version string
---@param game_version? GAME_VERSION
function Backend:init(name, script_version, game_version)
	game_version        = game_version or {}
	local branch        = self:GetGameBranch()
	local version_t     = game_version[branch] or { build = "any", online = "any" }
	self.target_build   = version_t.build
	self.target_version = version_t.online
	self.script_name    = name
	self.__version      = script_version

	require("includes.lib.compat")(branch)
	return self
end

---@diagnostic disable: undefined-global, undefined-field

---@nodiscard
---@return boolean
local function is_standalone()
	local arg = _G.arg
	if (type(arg) ~= "table") then
		return false
	end

	if (arg[0] == nil and arg[-1] == nil) then
		return false
	end

	return true
end

---@nodiscard
---@return boolean
local function is_yim_api()
	local _t1, _t2 = _G.menu_event, _G.scr_function
	if (type(_t1) ~= "table" or type(_t2) ~= "table") then
		return false
	end

	return _t1.Wndproc == 8 and type(_t2.call_script_function) == "function"
end

--[[
---@nodiscard
---@return boolean
local function is_stand_api()
	local menu = _G.menu
	if (type(menu) ~= "table" or _G.SCRIPT_SILENT_START == nil) then
		return false
	end

	return type(menu.my_root) == "function"
end

---@nodiscard
---@return boolean
local function is_cherax_api()
	local g_lua = _G.g_lua
	if (type(g_lua) ~= "table") then
		return false
	end

	return type(g_lua.register) == "function"
end
]]

---@return eGameBranch
function Backend:GetGameBranch()
	if (self.m_game_branch) then
		return self.m_game_branch
	end

	local has_jit = (type(_G.jit) == "table")
	if (is_standalone()) then
		if (has_jit) then
			error("LuaJIT is not supported!") -- var attributes, bit operators, etc. not worth the headache
		end

		print(("Running locally in %s for %s."):format(_VERSION, (package.config:sub(1, 1) == "\\") and "Windows" or "Unix"))
		self.m_game_branch = Enums.eGameBranch.MOCK
		return self.m_game_branch
	end

	local script = _G.script
	if (type(script) ~= "table") then
		error("Failed to load! Wrong API.")
	end

	if (type(script["run_in_callback"]) == "function" and has_jit) then
		error("YimMenuV2 is not supported. If you want to run the project in GTA V Enhanced, download YimLuaAPI from GitHub.")
	end

	if (not is_yim_api()) then
		error("Failed to load! Unknown host.")
	end

	local get_game_branch --[[@type (fun(): integer)?]] = _G.get_game_branch
	if (type(get_game_branch) ~= "function") then
		self.m_game_branch = Enums.eGameBranch.LEGACY
	else
		local branch = get_game_branch()
		if (type(branch) ~= "number" or not math.is_inrange(branch, 0, 1)) then
			error(_F("Failed to load! Unknown or unsupported game branch (%s). Is this YimLuaAPI?"), branch)
		end
		self.m_game_branch = branch + 1 -- Our game branch enum starts at 1. YimLuaAPI's naturally starts at 0
	end

	return self.m_game_branch
end

---@diagnostic enable: undefined-global, undefined-field

---@return boolean
function Backend:IsDebug()
	return self.is_debug
end

---@return boolean
function Backend:IsMockEnv()
	return self:GetGameBranch() == Enums.eGameBranch.MOCK
end

---@return boolean
function Backend:AreControlsDisabled()
	return self.disable_input or GUI:WantsInput()
end

---@param data string
function Backend:debug(data, ...)
	if (not self.is_debug) then
		return
	end

	log.fdebug(data, ...)
end

---@return boolean
function Backend:MatchGameVersion()
	local gv = GPointers.GameVersion
	return self.target_build == gv.build and self.target_version == gv.online
end

---@return boolean
function Backend:IsUpToDate()
	return (self.target_build == "any") or self:MatchGameVersion()
end

---@param handle integer
---@return boolean
function Backend:IsScriptEntity(handle)
	return Decorator:Validate(handle)
end

function Backend:IsPlayerSwitchInProgress()
	return STREAMING.IS_PLAYER_SWITCH_IN_PROGRESS()
end

---@param entity_type eEntityType
---@return number
function Backend:GetMaxAllowedEntities(entity_type)
	return self.MaxAllowedEntities[entity_type] or 0
end

---@param value number
---@param entity_type eEntityType
function Backend:SetMaxAllowedEntities(entity_type, value)
	local max = self.MaxAllowedEntities
	if (not max[entity_type]) then return end
	max[entity_type] = value
end

---@param entity_type eEntityType
---@return boolean
function Backend:CanCreateEntity(entity_type)
	local currentCount = table.getlen(self.SpawnedEntities[entity_type])
	return currentCount < (self:GetMaxAllowedEntities(entity_type))
end

---@param handle number
---@return boolean
function Backend:IsEntityRegistered(handle)
	for _, cat in pairs(self.SpawnedEntities) do
		if (cat[handle]) then
			return true
		end
	end

	return false
end

---@param handle number
---@return boolean
function Backend:IsBlipRegistered(handle)
	return self.CreatedBlips[handle] ~= nil
end

---@param handle integer
---@param entity_type? eEntityType
---@param etc? table -- metadata
function Backend:RegisterEntity(handle, entity_type, etc)
	if (not Game.IsScriptHandle(handle)) then
		return
	end

	entity_type = entity_type or Game.GetEntityType(handle)
	local entry = self.SpawnedEntities[entity_type]
	if (not entry) then
		log.ferror("Attempt to register an entity to an unknown type: %s", entity_type)
		return
	end

	entry[handle] = etc or handle
end

---@param handle number
---@param entity_type eEntityType
function Backend:RemoveEntity(handle, entity_type)
	entity_type = entity_type or Game.GetEntityType(handle)
	local entry = self.SpawnedEntities[entity_type]
	if not (entry and entry[handle]) then
		return
	end

	entry[handle] = nil
end

---@param blip_handle number
---@param owner number
---@param initial_alpha? number
function Backend:RegisterBlip(blip_handle, owner, initial_alpha)
	if (not Game.IsScriptHandle(owner) or not HUD.DOES_BLIP_EXIST(blip_handle)) then
		return
	end

	local blipData = self.CreatedBlips[owner]
	if (blipData) then
		Game.RemoveBlipFromEntity(blipData.handle)
	end

	self.CreatedBlips[owner] = {
		handle = blip_handle,
		owner  = owner,
		alpha  = initial_alpha or 255
	}
end

---@param owner number
function Backend:RemoveBlip(owner)
	self.CreatedBlips[owner] = nil
end

---@param name string
---@param callback fun(handle: handle): any
function Backend:RegisterFeatureEntityHandler(name, callback)
	self.FeatureEntityHandlers[name] = callback
end

---@param handle integer
function Backend:CheckFeatureEntities(handle)
	for featName, callback in pairs(self.FeatureEntityHandlers) do
		if (Decorator:ExistsOn(handle, featName)) then
			callback(handle)
		end
	end
end

-- TODO: Refactor this
function Backend:EntitySweep()
	for _, category in pairs(self.SpawnedEntities) do
		if (next(category) == nil) then
			goto continue
		end

		for handle in pairs(category) do
			if (ENTITY.DOES_ENTITY_EXIST(handle)) then
				ENTITY.SET_ENTITY_AS_MISSION_ENTITY(handle, true, true)
				ENTITY.DELETE_ENTITY(handle)
				Game.RemoveBlipFromEntity(handle)
				category[handle] = nil
			end
		end

		::continue::
	end

	if (next(self.CreatedBlips) ~= nil) then
		for _, blip in pairs(self.CreatedBlips) do
			local hBlip = blip.handle
			if (HUD.DOES_BLIP_EXIST(hBlip)) then
				HUD.REMOVE_BLIP(hBlip)
			end
			self:RemoveBlip(blip.owner)
		end
	end
end

local entityArray <const> = {
	Backend.SpawnedEntities[Enums.eEntityType.Object],
	Backend.SpawnedEntities[Enums.eEntityType.Ped],
	Backend.SpawnedEntities[Enums.eEntityType.Vehicle]
}
function Backend:PoolMgr()
	local timeout = self.is_debug and 500 or 2e3
	local blips   = self.CreatedBlips

	for eType, entry in ipairs(entityArray) do
		if (next(entry) == nil) then
			goto continue
		end

		for handle in pairs(entry) do
			if (not ENTITY.DOES_ENTITY_EXIST(handle)) then
				self:CheckFeatureEntities(handle)
				Game.DeleteEntity(handle, eType)
			end

			if (ENTITY.IS_ENTITY_DEAD(handle, false)) then
				self:CheckFeatureEntities(handle)
				Game.DeleteEntity(handle, eType)
			elseif (ENTITY.IS_ENTITY_A_PED(handle) and blips[handle]) then
				local blipData = blips[handle]
				local alpha    = blipData.alpha
				local hBlip    = blipData.handle
				if (PED.IS_PED_IN_ANY_VEHICLE(handle, true)) then
					if (alpha > 0) then
						alpha = 0
						HUD.SET_BLIP_ALPHA(hBlip, alpha)
						blipData.alpha = alpha
					end
				elseif (alpha < 255) then
					alpha = 255
					HUD.SET_BLIP_ALPHA(hBlip, alpha)
					blipData.alpha = alpha
				end
			end
		end

		::continue::
	end

	yield(timeout)
end

-- Registers a callback to execute on backend event.
---@param event eBackendEvent
---@param callback function
function Backend:RegisterEventCallback(event, callback)
	local evnt = self.EventCallbacks[event]

	if ((type(callback) ~= "function") or not evnt) then
		log.fdebug("Failed to register event: %s", EnumToString(Enums.eBackendEvent, event))
		return
	end

	if (table.find(evnt, callback)) then
		return
	end

	table.insert(evnt, callback)
end

-- Registers a callback to execute on all backend events.
---@param callback function
function Backend:RegisterEventCallbackAll(callback)
	if (type(callback) ~= "function") then
		return
	end

	for i = Enums.eBackendEvent.RELOAD_UNLOAD, Enums.eBackendEvent.PLAYER_SWITCH do
		self:RegisterEventCallback(i, callback)
	end
end

---@param key integer
function Backend:RegisterDisabledControl(key)
	if (self.ControlsToDisable[key]) then
		return
	end

	self.ControlsToDisable[key] = key
end

---@param key integer
function Backend:RemoveDisabledControl(key)
	if (not self.ControlsToDisable[key]) then
		return
	end

	self.ControlsToDisable[key] = nil
end

---@param event eBackendEvent
function Backend:TriggerEventCallbacks(event)
	for _, cb in ipairs(self.EventCallbacks[event] or {}) do
		if (type(cb) == "function") then
			xpcall(cb, function(err)
				local evt_name = EnumToString(Enums.eBackendEvent, event)
				log.fwarning("[Backend]: Callback failed for event '%s': %s", evt_name, err)
			end)
		end
	end
end

function Backend:Cleanup()
	self:EntitySweep()
	self:TriggerEventCallbacks(Enums.eBackendEvent.RELOAD_UNLOAD)

	for _, ptr in pairs(self.AllocatedPointers) do
		free(ptr)
	end
end

function Backend:OnSessionSwitch()
	if (self.is_in_session_transition) then
		return
	end

	if (not Game.IsInNetworkTransition()) then
		return
	end

	self.is_in_session_transition = true
	ThreadManager:Run(function()
		self:TriggerEventCallbacks(Enums.eBackendEvent.SESSION_SWITCH)

		while (Game.IsInNetworkTransition()) do
			yield()
		end

		sleep(1000)
		self.is_in_session_transition = false
	end)
end

function Backend:OnPlayerSwitch()
	if (self.is_in_player_transition) then
		return
	end

	if (not self:IsPlayerSwitchInProgress()) then
		return
	end

	self.is_in_player_transition = true
	ThreadManager:Run(function()
		self:TriggerEventCallbacks(Enums.eBackendEvent.PLAYER_SWITCH)

		while (self:IsPlayerSwitchInProgress()) do
			yield()
		end

		self.is_in_player_transition = false
	end)
end

function Backend:RegisterHandlers()
	local mockEnv = self:IsMockEnv()
	self.is_debug = mockEnv or GVars.backend.debug_mode or false

	if (mockEnv) then return end

	ThreadManager:RegisterLooped("SS_CTRLS", function()
		if (self:AreControlsDisabled()) then
			PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
		else
			if (gui.is_open() or GUI:IsOpen()) then
				disableMouseInput()
			end

			for _, control in pairs(self.ControlsToDisable) do
				disableControl(0, control, true)
			end
		end
	end)

	ThreadManager:RegisterLooped("SS_BACKEND", function()
		self:OnPlayerSwitch()
		self:OnSessionSwitch()

		PreviewService:Update()
		Decorator:CollectGarbage()
		Translator:OnTick()

		yield()
	end, { exception_handler = function() self:Cleanup() end })

	ThreadManager:RegisterLooped("SS_POOLMGR", function()
		self:PoolMgr()
		yield()
	end)

	event.register_handler(menu_event.MenuUnloaded, function()
		self:Cleanup()
	end)

	event.register_handler(menu_event.ScriptsReloaded, function()
		self:Cleanup()
	end)

	event.register_handler(menu_event.PlayerMgrInit, function()
		self:TriggerEventCallbacks(Enums.eBackendEvent.SESSION_JOIN)
	end)

	event.register_handler(menu_event.PlayerMgrShutdown, function()
		self:TriggerEventCallbacks(Enums.eBackendEvent.SESSION_LEAVE)
	end)
end

-- ### Baguette
function Backend:PANIQUE()
	ThreadManager:Run(function()
		self:Cleanup()
		for i = Enums.eBackendEvent.PLAYER_SWITCH, Enums.eBackendEvent.SESSION_LEAVE do
			self:TriggerEventCallbacks(i)
			sleep(100)
		end

		local pos = LocalPlayer:GetPos()
		AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(
			"ELECTROCUTION",
			"MISTERK",
			pos.x, pos.y, pos.z,
			"SPEECH_PARAMS_FORCE"
		)

		gui.show_warning("PANIQUE!", "(Ó _ Ò )!!")
	end)
end

return Backend
