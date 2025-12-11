---@diagnostic disable: lowercase-global

---@class BlipData
---@field handle integer
---@field owner integer
---@field alpha integer

---@enum eAPIVersion
eAPIVersion = {
    V1  = 1,  -- YimMenu V1 (Lua54)
    V2  = 2,  -- YimMenu V2 (LuaJIT) // placeholder
    L54 = 99, -- Mock environment (Lua54)
}

---@enum eBackendEvent
eBackendEvent = {
    RELOAD_UNLOAD  = 1,
    SESSION_SWITCH = 2,
    PLAYER_SWITCH  = 3,
}

---@enum eEntityType
eEntityType = {
    Ped     = 1,
    Vehicle = 2,
    Object  = 3
}

-- Global Singleton.
---@class Backend
---@field private api_version eAPIVersion
Backend = {
    __version           = "",
    target_build        = "",
    target_version      = "",
    disable_input       = false, -- Never serialize this runtime variable!

    ---@type table<integer, integer>
    ControlsToDisable  = {},

    ---@type table<integer, BlipData>
    CreatedBlips       = {},

    ---@type array<handle>
    AttachedEntities   = {},

    ---@type table<eBackendEvent, array<function>>
    EventCallbacks     = {
        [eBackendEvent.RELOAD_UNLOAD]  = {},
        [eBackendEvent.SESSION_SWITCH] = {},
        [eBackendEvent.PLAYER_SWITCH]  = {}
    },

    ---@type table<eEntityType, array<handle>>
    SpawnedEntities    = {
        [eEntityType.Ped]     = {},
        [eEntityType.Vehicle] = {},
        [eEntityType.Object]  = {},
    },

    ---@type table<eEntityType, integer>
    MaxAllowedEntities = {
        [eEntityType.Ped]     = 50,
        [eEntityType.Vehicle] = 25,
        [eEntityType.Object]  = 75,
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
end

---@return eAPIVersion
function Backend:GetAPIVersion()
    if self.api_version then
        return self.api_version
    end

    if (script and (type(script) == "table")) then
        if (menu_event and menu_event.Wndproc) then
            return eAPIVersion.V1
        end

        if (type(script["run_in_callback"]) == "function") then
            return eAPIVersion.V2
        end
        ---@diagnostic disable-next-line: undefined-global
    elseif (util or (menu and menu.root) or SCRIPT_SILENT_START or (_VERSION ~= "Lua 5.4")) then -- should probably place these in a lookup table
        error("Failed to load: Unknown or unsupported environment.")
    end

    return eAPIVersion.L54
end

---@return boolean
function Backend:IsMockEnv()
    return self:GetAPIVersion() == eAPIVersion.L54
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

-- TODO: Refactor this
function Backend:EntitySweep()
    for _, category in ipairs(self.SpawnedEntities) do
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

---@param event eBackendEvent
---@param func function
function Backend:RegisterEventCallback(event, func)
    local evnt = self.EventCallbacks[event]

    if ((type(func) ~= "function") or not evnt) then
        log.fdebug("Failed to register event: %s", EnumTostring(eBackendEvent, event))
        return
    end

    if table.find(evnt, func) then
        return
    end

    table.insert(evnt, func)
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
                log.fwarning("[Backend]: Callback error for event %s: %s", EnumTostring(eBackendEvent, event), err)
            end
        end
    end
end

function Backend:Cleanup()
    self:EntitySweep()
    self:TriggerEventCallbacks(eBackendEvent.RELOAD_UNLOAD)
end

function Backend:OnSessionSwitch()
    if (not script.is_active("maintransition")) then
        return
    end

    self:TriggerEventCallbacks(eBackendEvent.SESSION_SWITCH)

    repeat
        sleep(100)
    until not script.is_active("maintransition")
    sleep(1000)
end

function Backend:OnPlayerSwitch()
    if (not self:IsPlayerSwitchInProgress()) then
        return
    end

    self:TriggerEventCallbacks(eBackendEvent.PLAYER_SWITCH)

    repeat
        sleep(100)
    until not self:IsPlayerSwitchInProgress()
    sleep(1000)
end

function Backend:RegisterHandlers()
    self.debug_mode = self:IsMockEnv() or GVars.backend.debug_mode or false

    if (self:GetAPIVersion() ~= eAPIVersion.L54) then
        ThreadManager:CreateNewThread("SS_CTRLS", function()
            if (self.disable_input) then
                PAD.DISABLE_ALL_CONTROL_ACTIONS(0)
            end

            for _, control in pairs(self.ControlsToDisable) do
                PAD.DISABLE_CONTROL_ACTION(0, control, true)
            end
        end)
    end

    if (self:GetAPIVersion() == eAPIVersion.V1) then
        ThreadManager:CreateNewThread("SS_BACKEND", function()
            self:OnPlayerSwitch()
            self:OnSessionSwitch()
            sleep(200)
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
    ThreadManager:RunInFiber(function()
        self:Cleanup()
        for i = eBackendEvent.SESSION_SWITCH, eBackendEvent.PLAYER_SWITCH do
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
