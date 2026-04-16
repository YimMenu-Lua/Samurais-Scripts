-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local PreviewService = require("includes.services.PreviewService")
local ClearPreview   = function() PreviewService:Clear() end


---@class BlipData
---@field handle integer
---@field owner integer
---@field alpha integer

---@enum eGameBranch
Enums.eGameBranch   = {
	LAGECY   = 1,
	ENHANCED = 2,
	MOCK     = 99,
}

---@enum eBackendEvent
Enums.eBackendEvent = {
	RELOAD_UNLOAD  = 1,
	SESSION_SWITCH = 2,
	PLAYER_SWITCH  = 3,
}

---@enum eEntityType
Enums.eEntityType   = {
	Invalid = -1,
	Ped     = 1,
	Vehicle = 2,
	Object  = 3
}

-- Global Singleton.
---@class Backend
---@field private m_game_branch eGameBranch
local Backend       = {
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
		[Enums.eBackendEvent.SESSION_SWITCH] = { ClearPreview },
		[Enums.eBackendEvent.PLAYER_SWITCH]  = { ClearPreview }
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
	FeatureEntityHandlers    = {}
}
Backend.__index     = Backend

---@param name string
---@param script_version string
---@param game_version? GAME_VERSION
function Backend:init(name, script_version, game_version)
	local branch        = self:GetGameBranch()
	self.m_game_branch  = branch
	self.script_name    = name
	self.__version      = script_version
	self.target_build   = game_version and game_version[branch].build or "any"
	self.target_version = game_version and game_version[branch].online or "any"

	require("includes.lib.compat").SetupEnv(self.m_game_branch)
	return self
end

---@return eGameBranch
function Backend:GetGameBranch()
	if (self.m_game_branch) then
		return self.m_game_branch
	end

	if (not script or (type(script) ~= "table")) then
		---@diagnostic disable-next-line: undefined-global
		if (util or (menu and menu.root) or SCRIPT_SILENT_START or (_VERSION ~= "Lua 5.4")) then
			error("Failed to load: Unknown or unsupported Lua environment.")
		end

		self.m_game_branch = Enums.eGameBranch.MOCK
		return self.m_game_branch
	end

	if (type(script["run_in_callback"]) == "function") then
		error("YimMenuV2 is not supported. If you want to run this script in GTA V Enhanced, download YimLuaAPI.")
	end

	if (not menu_event or not menu_event.Wndproc) then
		error("Unknown or unsupported API.")
	end

	---@type (fun(): integer)?
	local get_game_branch = _G["get_game_branch"]
	if (type(get_game_branch) ~= "function") then
		self.m_game_branch = Enums.eGameBranch.LAGECY
		return self.m_game_branch
	end

	local branch = get_game_branch()
	if (type(branch) ~= "number" or branch > 1) then
		error("Failed to load: Unknown or unsupported game branch.")
	end

	self.m_game_branch = branch + 1 -- Our own eGameBranch starts at 1 to make it compatible with Lua table indices. YimLuaAPI's naturally starts at 0
	return self.m_game_branch
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
	if (not self.debug_mode) then
		return
	end

	log.fdebug(data, ...)
end

function Backend:MatchGameVersion()
	local gv = Memory:GetGameVersion()
	return (gv and gv.build
		and gv.online
		and (self.target_build == gv.build)
		and (self.target_version == gv.online)
	)
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
	if not self.MaxAllowedEntities[entity_type] then
		return 0
	end

	return self.MaxAllowedEntities[entity_type]
end

---@param value number
---@param entity_type eEntityType
function Backend:SetMaxAllowedEntities(entity_type, value)
	if not self.MaxAllowedEntities[entity_type] then
		return
	end

	self.MaxAllowedEntities[entity_type] = value
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
		if cat[handle] then
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
	if not Game.IsScriptHandle(handle) then
		return
	end

	if (not self.SpawnedEntities[entity_type]) then
		log.fwarning("Attempt to register an entity to an unknown type: %s", entity_type)
		return
	end

	self.SpawnedEntities[entity_type][handle] = etc or handle
end

---@param handle number
---@param entity_type eEntityType
function Backend:RemoveEntity(handle, entity_type)
	if not (self.SpawnedEntities[entity_type] or self.SpawnedEntities[entity_type][handle]) then
		return
	end

	self.SpawnedEntities[entity_type][handle] = nil
end

---@param blip_handle number
---@param owner number
---@param initial_alpha? number
function Backend:RegisterBlip(blip_handle, owner, initial_alpha)
	if not Game.IsScriptHandle(owner) or not HUD.DOES_BLIP_EXIST(blip_handle) then
		return
	end

	if self.CreatedBlips[owner] then
		Game.RemoveBlipFromEntity(self.CreatedBlips[owner].handle)
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
			if (HUD.DOES_BLIP_EXIST(blip.handle)) then
				HUD.REMOVE_BLIP(blip.handle)
			end
			self:RemoveBlip(blip.owner)
		end
	end
end

function Backend:PoolMgr()
	local timeout = self.debug_mode and 500 or 2e3

	for index, category in ipairs({
		self.SpawnedEntities[Enums.eEntityType.Object],
		self.SpawnedEntities[Enums.eEntityType.Ped],
		self.SpawnedEntities[Enums.eEntityType.Vehicle]
	}) do
		if (next(category) == nil) then
			goto continue
		end

		for handle in pairs(category) do
			if (not ENTITY.DOES_ENTITY_EXIST(handle)) then
				self:CheckFeatureEntities(handle)
				Game.DeleteEntity(handle, index)
			end

			if (ENTITY.IS_ENTITY_DEAD(handle, false)) then
				self:CheckFeatureEntities(handle)
				Game.DeleteEntity(handle, index)
			elseif (ENTITY.IS_ENTITY_A_PED(handle) and self.CreatedBlips[handle]) then
				local blip = self.CreatedBlips[handle]
				if (PED.IS_PED_IN_ANY_VEHICLE(handle, true)) then
					if (blip.alpha > 0) then
						HUD.SET_BLIP_ALPHA(blip.handle, 0)
						blip.alpha = 0
					end
				else
					if (blip.alpha < 255) then
						HUD.SET_BLIP_ALPHA(blip.handle, 255)
						blip.alpha = 255
					end
				end
			end
		end

		::continue::
	end

	sleep(timeout)
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
	for _, fn in ipairs(self.EventCallbacks[event] or {}) do
		if (type(fn) == "function") then
			xpcall(fn, function(err)
				log.fwarning("[Backend]: Callback error for event %s: %s", EnumToString(Enums.eBackendEvent, event), err)
			end)
		end
	end
end

function Backend:Cleanup()
	self:EntitySweep()
	self:TriggerEventCallbacks(Enums.eBackendEvent.RELOAD_UNLOAD)
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
	self.debug_mode = mockEnv or GVars.backend.debug_mode or false

	if (mockEnv) then return end

	ThreadManager:RegisterLooped("SS_CTRLS", function()
		if (self.disable_input or GUI:WantsInput()) then
			PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
		else
			if ((gui.is_open() or GUI:IsOpen())) then
				self:DisableAttackInput()
			end

			for _, control in pairs(self.ControlsToDisable) do
				PAD.DISABLE_CONTROL_ACTION(0, control, true)
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
	end)

	ThreadManager:RegisterLooped("SS_POOLMGR", function()
		self:PoolMgr()
		yield()
	end)

	event.register_handler(menu_event.MenuUnloaded, function() self:Cleanup() end)
	event.register_handler(menu_event.ScriptsReloaded, function() self:Cleanup() end)
end

-- ### Baguette
------
-- Note: This **will remove** all registered threads and not just stop or suspend them.
--
-- You can only restart (re-register) them by reloading the script.
function Backend:PANIQUE()
	ThreadManager:Run(function()
		self:Cleanup()
		for i = Enums.eBackendEvent.SESSION_SWITCH, Enums.eBackendEvent.PLAYER_SWITCH do
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

function Backend:DisableAttackInput()
	PAD.DISABLE_CONTROL_ACTION(0, 18, true)
	PAD.DISABLE_CONTROL_ACTION(0, 24, true)
	PAD.DISABLE_CONTROL_ACTION(0, 25, true)
	PAD.DISABLE_CONTROL_ACTION(0, 69, true)
	PAD.DISABLE_CONTROL_ACTION(0, 70, true)
	PAD.DISABLE_CONTROL_ACTION(0, 106, true)
	PAD.DISABLE_CONTROL_ACTION(0, 122, true)
	PAD.DISABLE_CONTROL_ACTION(0, 135, true)
	PAD.DISABLE_CONTROL_ACTION(0, 142, true)
	PAD.DISABLE_CONTROL_ACTION(0, 144, true)
	PAD.DISABLE_CONTROL_ACTION(0, 176, true)
	PAD.DISABLE_CONTROL_ACTION(0, 223, true)
	PAD.DISABLE_CONTROL_ACTION(0, 229, true)
	PAD.DISABLE_CONTROL_ACTION(0, 237, true)
	PAD.DISABLE_CONTROL_ACTION(0, 257, true)
	PAD.DISABLE_CONTROL_ACTION(0, 294, true)
end

return Backend
