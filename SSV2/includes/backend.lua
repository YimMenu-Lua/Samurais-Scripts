---@diagnostic disable: lowercase-global

local PreviewService = require("includes.services.PreviewService")
local function ClearPreview()
	PreviewService:Clear()
end

---@class BlipData
---@field handle integer
---@field owner integer
---@field alpha integer

---@enum eAPIVersion
Enums.eAPIVersion = {
	V1  = 1, -- YimMenu V1 (Lua54)
	V2  = 2, -- YimMenu V2 (LuaJIT) // placeholder
	L54 = 99, -- Mock environment (Lua54)
}

---@enum eBackendEvent
Enums.eBackendEvent = {
	RELOAD_UNLOAD  = 1,
	SESSION_SWITCH = 2,
	PLAYER_SWITCH  = 3,
}

---@enum eEntityType
Enums.eEntityType = {
	Ped     = 1,
	Vehicle = 2,
	Object  = 3
}

-- Global Singleton.
---@class Backend
---@field private api_version eAPIVersion
local Backend = {
	__version          = "",
	target_build       = "",
	target_version     = "",
	disable_input      = false, -- Never serialize this runtime variable!

	---@type table<integer, integer>
	ControlsToDisable  = {},

	---@type table<integer, BlipData>
	CreatedBlips       = {},

	---@type array<handle>
	AttachedEntities   = {},

	---@type table<eBackendEvent, array<function>>
	EventCallbacks     = {
		[Enums.eBackendEvent.RELOAD_UNLOAD]  = { ClearPreview },
		[Enums.eBackendEvent.SESSION_SWITCH] = { ClearPreview },
		[Enums.eBackendEvent.PLAYER_SWITCH]  = { ClearPreview }
	},

	---@type table<eEntityType, table<handle, handle>>
	SpawnedEntities    = {
		[Enums.eEntityType.Ped]     = {},
		[Enums.eEntityType.Vehicle] = {},
		[Enums.eEntityType.Object]  = {},
	},

	---@type table<eEntityType, integer>
	MaxAllowedEntities = {
		[Enums.eEntityType.Ped]     = 50,
		[Enums.eEntityType.Vehicle] = 25,
		[Enums.eEntityType.Object]  = 75,
	},
}
Backend.__index = Backend

---@param name string
---@param version string
---@param game_build? string
---@param target_version? string
function Backend:init(name, version, game_build, target_version)
	self.api_version    = self:GetAPIVersion()
	self.script_name    = name
	self.__version      = version
	self.target_build   = game_build or "any"
	self.target_version = target_version or "any"

	require("includes.lib.compat").SetupEnvironment(self.api_version)

	return self
end

---@return eAPIVersion
function Backend:GetAPIVersion()
	if (not self.api_version) then
		if (script and (type(script) == "table")) then
			if (menu_event and menu_event.Wndproc) then
				if (type(_G["get_game_branch"]) == "function") then
					local branch = _G["get_game_branch"]()
					if (type(branch) ~= "number" or branch > 1) then
						error("Unknown or unsupported game branch.")
					end

					self.api_version = _G["get_game_branch"]() + 1
				else
					self.api_version = Enums.eAPIVersion.V1
				end
			end

			if (type(script["run_in_callback"]) == "function") then
				error(
					"YmMenu V2 is not supported. If you want to run this script in GTA V Enhanced, download YimLuaAPI.") -- test error; add Github link later
			end
			---@diagnostic disable-next-line: undefined-global
		elseif (util or (menu and menu.root) or SCRIPT_SILENT_START or (_VERSION ~= "Lua 5.4")) then -- should probably place these in a lookup table
			error("Failed to load: Unknown or unsupported Lua environment.")
		else
			self.api_version = Enums.eAPIVersion.L54
		end
	end

	return self.api_version
end

---@return boolean
function Backend:IsMockEnv()
	return self:GetAPIVersion() == Enums.eAPIVersion.L54
end

---@return boolean
function Backend:AreControlsDisabled()
	return self.disable_input
end

---@param data string
function Backend:debug(data, ...)
	if (not self.debug_mode) then
		return
	end

	log.fdebug(data, ...)
end

function Backend:MatchVersion()
	local gv = Game.GetVersion()
	return (gv and gv._build
		and gv._online
		and (self.target_build == gv._build)
		and (self.target_version == gv._online)
	)
end

---@return boolean
function Backend:IsUpToDate()
	return (self.target_build == "any") or self:MatchVersion()
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

---@param handle integer
function Backend:CheckFeatureEntities(handle)
	if Decorator:ExistsOn(handle, "EntityForge") then
		EntityForge:RemoveEntityByHandle(handle)
	end

	if Decorator:ExistsOn(handle, "BillionaireServices") then
		BillionaireServices:RemoveEntityByHandle(handle)
	end

	if Decorator:ExistsOn(handle, "YimActions") then
		YimActions.CompanionManager:RemoveCompanionByHandle(handle)
	end
end

-- TODO: Refactor this
function Backend:EntitySweep()
	for _, category in pairs(self.SpawnedEntities) do
		if next(category) ~= nil then
			for handle in pairs(category) do
				if ENTITY.DOES_ENTITY_EXIST(category[handle]) then
					ENTITY.SET_ENTITY_AS_MISSION_ENTITY(category[handle], true, true)
					ENTITY.DELETE_ENTITY(category[handle])
					Game.RemoveBlipFromEntity(category[handle])
					category[handle] = nil
				end
			end
		end
	end

	if next(self.CreatedBlips) ~= nil then
		for _, blip in pairs(self.CreatedBlips) do
			if HUD.DOES_BLIP_EXIST(blip.handle) then
				HUD.REMOVE_BLIP(blip.handle)
			end
			self:RemoveBlip(blip.owner)
		end
	end
end

function Backend:PoolMgr()
	local timeout = self.debug_mode and 500 or 2e3

	for index, category in ipairs({ self.SpawnedEntities[Enums.eEntityType.Object], self.SpawnedEntities[Enums.eEntityType.Ped], self.SpawnedEntities[Enums.eEntityType.Vehicle] }) do
		if (next(category) == nil) then
			goto continue
		end

		for handle in pairs(category) do
			local bExists = ENTITY.DOES_ENTITY_EXIST(handle)

			if (not bExists) then
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
		log.fdebug("Failed to register event: %s", EnumTostring(Enums.eBackendEvent, event))
		return
	end

	if table.find(evnt, callback) then
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
			local ok, err = pcall(fn)
			if (not ok) then
				log.fwarning("[Backend]: Callback error for event %s: %s", EnumTostring(Enums.eBackendEvent, event), err)
			end
		end
	end
end

function Backend:Cleanup()
	self:EntitySweep()
	self:TriggerEventCallbacks(Enums.eBackendEvent.RELOAD_UNLOAD)
end

function Backend:OnSessionSwitch()
	if (not script.is_active("maintransition")) then
		return
	end

	self:TriggerEventCallbacks(Enums.eBackendEvent.SESSION_SWITCH)

	repeat
		sleep(100)
	until not script.is_active("maintransition")
	sleep(1000)
end

function Backend:OnPlayerSwitch()
	if (not self:IsPlayerSwitchInProgress()) then
		return
	end

	self:TriggerEventCallbacks(Enums.eBackendEvent.PLAYER_SWITCH)

	repeat
		sleep(100)
	until not self:IsPlayerSwitchInProgress()
	sleep(1000)
end

function Backend:RegisterHandlers()
	self.debug_mode = self:IsMockEnv() or GVars.backend.debug_mode or false

	if (self:GetAPIVersion() ~= Enums.eAPIVersion.L54) then
		ThreadManager:RegisterLooped("SS_CTRLS", function()
			if (self.disable_input) then
				PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
			end

			if ((gui.is_open() or GUI:IsOpen()) and not self.disable_input) then
				self:DisableAttackInput()
			end

			for _, control in pairs(self.ControlsToDisable) do
				PAD.DISABLE_CONTROL_ACTION(0, control, true)
			end
		end)
	end

	if (self:GetAPIVersion() == Enums.eAPIVersion.V1) then
		ThreadManager:RegisterLooped("SS_BACKEND", function()
			self:OnPlayerSwitch()
			self:OnSessionSwitch()
			PreviewService:Update()
			Decorator:CollectGarbage()
			yield()
		end)

		ThreadManager:RegisterLooped("SS_POOLMGR", function()
			self:PoolMgr()
		end)

		event.register_handler(menu_event.MenuUnloaded, function() self:Cleanup() end)
		event.register_handler(menu_event.ScriptsReloaded, function() self:Cleanup() end)
	end
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

		local pos = Self:GetPos()
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
