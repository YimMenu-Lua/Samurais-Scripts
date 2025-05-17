---@diagnostic disable: lowercase-global

---@alias ActionType integer
--- | -1 # TYPE_UNK
--- | 0 # TYPE_ANIM
--- | 1 # TYPE_SCENARIO
--- | 2 # TYPE_SCENE

local TYPE_UNK      <const> = -1
local TYPE_ANIM     <const> = 0
local TYPE_SCENARIO <const> = 1
local TYPE_SCENE    <const> = 2


-----------------------------------------------------
-- Action Struct
-----------------------------------------------------
-- A playable action (animation, scenario, synchronized scene).
---@class Action
---@field data table
---@field action_type ActionType
---@field default_flags number
Action = {}
Action.__index = Action

---@param action_data table
---@param action_type ActionType
function Action.new(action_data, action_type)
    local instance = setmetatable({}, Action)
    instance.action_type = action_type
    instance.data = action_data

    if action_type == TYPE_ANIM then
        instance.default_flags = action_data.flags or 0 -- track default hardcoded flags for later. -- nvm this is broken
    end

    return instance
end

function Action:TypeAsString()
    if self.action_type == 0 then
        return "Animation"
    elseif self.action_type == 1 then
        return "Scenario"
    elseif self.action_type == 2 then
        return "Synchronized Scene"
    else
        return "Unknown"
    end
end


-----------------------------------------------------
-- YimActions V3
-----------------------------------------------------
-- Wompus Theater™
---@class YimActions
---@field CurrentlyPlaying Action[]
---@field LastPlayed Action[]
---@field CompanionManager CompanionManager
---@field SceneManager SceneManager
YimActions = {}
YimActions.__index = YimActions
YimActions.CompanionManager = CompanionManager.new()
YimActions.SceneManager = SceneManager
YimActions.CurrentlyPlaying = {}
YimActions.LastPlayed = {}
YimActions.ACTION_TYPES = { -- expose action types for future stuff that I have in mind. Hopefully I can get myself to finish this cursed abomination
    -- Unknown/Undefined
    UNK = TYPE_UNK,
    -- Animation
    ANIM = TYPE_ANIM,
    -- Scenario
    SCENARIO = TYPE_SCENARIO,
    -- Synchronized Scene (WIP)
    SCENE = TYPE_SCENE,
}


---@param ped? integer
function YimActions:GetPed(ped)
    return ped or Self.GetPedID()
end

---@param ped? integer
function YimActions:AddActionToRecents(ped)
    ped = self:GetPed(ped)
    local current = self.CurrentlyPlaying[ped]

    if not current then
        return
    end

    if (#self.LastPlayed == 0) then
        table.insert(self.LastPlayed, current)
    else
        local exists = false
        for _, action in ipairs(self.LastPlayed) do
            if action.data.label == current.data.label then
                exists = true
                break
            end
        end

        if not exists then
            table.insert(self.LastPlayed, current)
        end
    end
end

function YimActions:RefreshFavorites()
    yav3_favorites = CFG:ReadItem("yav3_favorites")
end

function YimActions:SaveFavorites()
    CFG:SaveItem("yav3_favorites", yav3_favorites)
    self:RefreshFavorites()
end

---@param category string
---@param name string
---@return boolean
function YimActions:DoesFavoriteExist(category, name)
    return yav3_favorites and (yav3_favorites[category][name] ~= nil) or false
end

---@param category string
---@param name string
---@param data table
---@param action_type ActionType
function YimActions:AddToFavorites(category, name, data, action_type)
    if self:DoesFavoriteExist(category, name) then
        YimToast:ShowError(
            "Samurai's Scripts",
            "This action is already saved as a favorite!"
        )
        return
    end

    data["type"] = action_type
    yav3_favorites[category][name] = data
    self:SaveFavorites()
end

---@param category string
---@param name string
function YimActions:RemoveFromFavorites(category, name)
    yav3_favorites[category][name] = nil
    self:SaveFavorites()
end

---@return boolean
function YimActions:IsPlayerBusy()
    return
    b_PedGrabbed or
    b_VehicleGrabbed or
    HNS.isHiding or
    b_IsHandsUp or
    PublicSeating.isSitting or
    b_IsPlayingAmbientScenario or
    b_IsSettingHotkeys or
    CUTSCENE.IS_CUTSCENE_ACTIVE() or
    CUTSCENE.IS_CUTSCENE_PLAYING() or
    HUD.IS_MP_TEXT_CHAT_TYPING() or
    Self.IsBrowsingApps() or
    Self.IsSwitchingPlayers() or
    Self.IsInWater() or
    Self.IsRagdolling() or
    script.is_active("maintransition")
end

---@param ped? integer
---@return boolean
function YimActions:IsPedPlaying(ped)
    ped = self:GetPed(ped)
    return self.CurrentlyPlaying[ped] ~= nil or PED.IS_PED_USING_ANY_SCENARIO(ped)
end

---@param ped? integer
---@param animData table
---@return boolean
function YimActions:IsAnimDone(ped, animData)
    return ENTITY.GET_ENTITY_ANIM_CURRENT_TIME(
        self:GetPed(ped),
        animData.dict,
        animData.name
    ) >= 0.99 or
    animData.playTime ~= -1
end

---@param ped? integer
---@return boolean
function YimActions:WasActionInterrupted(ped)
    ped = self:GetPed(ped)
    local current = self.CurrentlyPlaying[ped]

    if not current then
        return false
    end

    if current.action_type == TYPE_ANIM then
        return not ENTITY.IS_ENTITY_PLAYING_ANIM(ped, current.data.dict, current.data.name, -1)
    elseif current.action_type == TYPE_SCENARIO then
        return not PED.IS_PED_USING_ANY_SCENARIO(ped)
    else
        return false -- no scenes yet
    end
end

---@param animData table
---@param targetPed? integer
function YimActions:PlayAnim(animData, targetPed)
    if not targetPed then
        targetPed = Self.GetPedID()
    end

    Await(Game.RequestAnimDict, animData.dict)
    TASK.TASK_PLAY_ANIM(
        targetPed,
        animData.dict,
        animData.name,
        animData.blendInSpeed or 4.0,
        animData.blendOutSpeed or -4.0,
        animData.playTime or -1,
        animData.flags or 0,
        0.0,
        false,
        false,
        false
    )
    self:AddActionToRecents(targetPed)

    if (animData.props and #animData.props > 0) then
        YimActions.PropManager:AttachProp(targetPed, animData.props)
    end

    if (animData.propPeds and #animData.propPeds > 0) then
        YimActions.PropManager:AttachProp(targetPed, animData.propPeds, true)
    end

    if animData.ptfx and animData.ptfx.name then
        YimActions.FXManager:StartPTFX(targetPed, animData.ptfx)
    end

    local b_IsLooped = Lua_fn.has_bit(animData.flags, ANIMFLAGS._LOOPING)
    local b_IsFrozen = Lua_fn.has_bit(animData.flags, ANIMFLAGS._HOLD_LAST_FRAME)

    if not b_IsLooped and not b_IsFrozen then
        repeat
            yield()
        until self:IsAnimDone(targetPed, animData)
        self.CurrentlyPlaying[targetPed] = nil
    end
end

---@param scenarioData table
---@param targetPed? integer
---@param playImmediately? boolean
function YimActions:PlayScenario(scenarioData, targetPed, playImmediately)
    targetPed = self:GetPed(targetPed)

    if scenarioData.label == "Cook On BBQ" then
        local offsetCoords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
            targetPed,
            0.0,
            1.0,
            0.0
        )

        local bbq = YimActions.PropManager:SpawnProp(
            targetPed,
            {model = 286252949},
            false,
            offsetCoords,
            true,
            true,
            true
        )

        if bbq and bbq ~= 0 then
            ENTITY.SET_ENTITY_HEADING(bbq, Game.GetHeading(bbq) - 180)
        end
    end

    if self:IsPedPlaying(targetPed) then
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(targetPed) -- avoid scenario exit anims if we start a scenario while already playing one
    end

    TASK.TASK_START_SCENARIO_IN_PLACE(
        targetPed,
        scenarioData.scenario,
        -1,
        not playImmediately
    )
end

function YimActions:PlaySyncedScene(data)
    self.SceneManager:Play(data)
end

---@param action Action
---@param ped? integer
function YimActions:Play(action, ped)
    if not action or not action.data then
        log.warning("[ERROR]: (YimActions) No action data!")
        return
    end

    ped = self:GetPed(ped)

    if ped == Self.GetPedID() and self:IsPlayerBusy() then
        YimToast:ShowMessage(
            "Samurai's Scripts",
            "Player is unavailable at this moment. Clear any other tasks then try again."
        )
        return
    end

    self:Cleanup(ped)
    Await(function() return self.CurrentlyPlaying[ped] == nil end)

    self.CurrentlyPlaying[ped] = action

    if action.action_type == TYPE_SCENARIO then
        self:PlayScenario(action.data, ped)
    elseif action.action_type == TYPE_ANIM then
        self:PlayAnim(action.data, ped)
    elseif action.action_type == TYPE_SCENE then
        self:PlaySyncedScene(action.data)
    end

    self:AddActionToRecents(ped)

    if SS_debug then
        self.Debugger:Update(ped)
    end
end

function YimActions:ResetPlayer()
    TASK.CLEAR_PED_TASKS(Self.GetPedID())
    SS.ResetMovement()
    PublicSeating:Cleanup()

    if HNS.isHiding then
        HNS:Reset()
    end

    if b_PedGrabbed and (i_GrabbedPed ~= 0) and ENTITY.IS_ENTITY_ATTACHED(i_GrabbedPed) then
        ENTITY.DETACH_ENTITY(i_GrabbedPed, true, true)
        ENTITY.FREEZE_ENTITY_POSITION(i_GrabbedPed, false)
        TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_GrabbedPed, false)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(i_GrabbedPed, false)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(Self.GetPedID())

    end

    if b_VehicleGrabbed and (i_GrabbedVeh ~= 0) and ENTITY.IS_ENTITY_ATTACHED(i_GrabbedVeh) then
        ENTITY.DETACH_ENTITY(i_GrabbedVeh, true, true)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(Self.GetPedID())
    end

    if next(Game.Audio.ActiveEmitters) ~= nil then
        for _, emitter in pairs(Game.Audio.ActiveEmitters) do
            if emitter.owner == Self.GetPedID() then
                Game.Audio:ToggleEmitter(emitter, false)
            end
        end
    end

    b_IsHandsUp = false
    b_IsCrouched = false
    b_PedGrabbed = false
    b_VehicleGrabbed = false
    i_GrabbedPed = 0
    i_GrabbedVeh = 0
end

---@param ped? integer
function YimActions:Cleanup(ped)
    ped = self:GetPed(ped)

    if not self.CurrentlyPlaying[ped] then
        return
    end

    YimActions.FXManager:StopPTFX(ped)
    YimActions.PropManager:Cleanup(ped)
    YimActions.SceneManager:Wipe()

    if string.find(self.CurrentlyPlaying[ped].data.label, "DJ") then
        Game.Audio:PartyMode(false)
    end

    Sleep(200)
    TASK.CLEAR_PED_TASKS(ped)

    if ped == Self.GetPedID() then
        if PED.IS_PED_USING_ANY_SCENARIO(ped) then
            Game.BusySpinnerOn(_T("SCN_STOP_SPINNER_"), 3)
            repeat
                Sleep(10)
            until not PED.IS_PED_USING_ANY_SCENARIO(ped)
            Game.BusySpinnerOff()
        end

        self:ResetPlayer()
    end

    self.CurrentlyPlaying[ped] = nil
    if SS_debug then
        YimActions.Debugger:Remove(ped)
    end
end

function YimActions:ForceCleanup()
    self.FXManager:Wipe()
    self.PropManager:Wipe()
    self.SceneManager:Wipe()
    self.CompanionManager:Wipe()
    self.CurrentlyPlaying = {}
    self:ResetPlayer()
    Game.Audio:StopAllEmitters()
    TASK.CLEAR_PED_TASKS(Self.GetPedID())
end

function YimActions:OnInterruptEvent(s)
    if self.CurrentlyPlaying[Self.GetPedID()] then
        s:sleep(1000)

        local localPlayer = Self.GetPedID()
        local current = self.CurrentlyPlaying[localPlayer]
        local b_IsLooped
        local b_IsFrozen

        if current then
            if current.action_type == TYPE_ANIM then
                b_IsLooped = Lua_fn.has_bit(current.data.flags, ANIMFLAGS._LOOPING)
                b_IsFrozen = Lua_fn.has_bit(current.data.flags, ANIMFLAGS._HOLD_LAST_FRAME)
            elseif current.action_type == TYPE_SCENARIO then
                b_IsLooped = true
                b_IsFrozen = true
            else
                b_IsLooped = false
                b_IsFrozen = false
            end

            if (b_IsLooped or b_IsFrozen) then
                if (
                    not Self.IsAlive() or
                    PLAYER.IS_PLAYER_BEING_ARRESTED(Self.GetPlayerID(), true) or
                    Self.IsSwitchingPlayers() or
                    script.is_active("maintransition")
                ) then
                    self:ForceCleanup()
                    s:sleep(1000)
                    return
                end

                if self.CurrentlyPlaying[localPlayer] and self:WasActionInterrupted(localPlayer) then
                    if Self.IsFalling() then
                        repeat
                            s:sleep(1000)
                        until not Self.IsFalling()
                        s:sleep(1000)
                    end

                    if Self.IsRagdolling() then
                        repeat
                            s:sleep(1000)
                        until not Self.IsRagdolling()
                        s:sleep(1000)
                    end

                    if Self.IsSwimming() then
                        self:Cleanup(localPlayer)
                        s:sleep(1000)
                        return
                    end

                    self:Play(current, localPlayer)
                end
            end
        end
    end
end

function YimActions:BackgroundWorker(s, ped)
    if (next(self.CurrentlyPlaying) == nil) and
    (next(self.PropManager.Props) == nil) and
    (#self.CompanionManager.Companions == 0) then
        return
    end

    if SS.IsKeyPressed(keybinds.stop_anim.code) then
        local timer = Timer.new(1000)
        local isDone = false
        repeat
            isDone = timer:isDone()
            if isDone then
                UI.WidgetSound("Cancel")
                self:ForceCleanup()
                self:ResetPlayer()
                break
            end
            yield()
        until isDone or not SS.IsKeyPressed(keybinds.stop_anim.code)
    end

    ped = self:GetPed(ped)
    local current = self.CurrentlyPlaying[ped]

    if not current then
        return
    end

    if SS.IsKeyJustPressed(keybinds.stop_anim.code) then
        self:Cleanup(ped)
    end

    if self.CurrentlyPlaying[ped] and current.action_type == TYPE_ANIM then
        if string.find(string.lower(current.data.label), "police torch") then
            local torch = YimActions.PropManager.Props[ped][1]

            if ENTITY.DOES_ENTITY_EXIST(torch) and (Game.GetEntityModel(torch) == 211760048) then
                local torchPos = Game.GetEntityCoords(torch, false)
                local torchFwd = (Game.GetForwardVector(torch)):inverse()

                GRAPHICS.DRAW_SPOT_LIGHT(
                    torchPos.x,
                    torchPos.y,
                    torchPos.z - 0.2,
                    torchFwd.x,
                    torchFwd.y,
                    torchFwd.z,
                    226,
                    130,
                    78,
                    50.0,
                    8.0,
                    1.0,
                    10.0,
                    1.0
                )
            end
        end

        -- this is very stupid but it works. kinda...
        if ENTITY.IS_ENTITY_PLAYING_ANIM(ped, "mp_suicide", "pistol", 3) then
            for _, w in ipairs(weapons.get_all_weapons_of_group_type(416676503)) do
                if WEAPON.HAS_PED_GOT_WEAPON(ped, joaat(w), false) then
                    WEAPON.SET_CURRENT_PED_WEAPON(ped, joaat(w), true)
                    break
                end
            end

            local i_AnimTime = 0
            repeat
                i_AnimTime = ENTITY.GET_ENTITY_ANIM_CURRENT_TIME(ped, "mp_suicide", "pistol")
                s:sleep(1)
            until i_AnimTime >= 0.299
            AUDIO.PLAY_SOUND_FRONTEND(-1, "SNIPER_FIRE", "DLC_BIKER_RESUPPLY_MEET_CONTACT_SOUNDS", true)
            repeat
                s:sleep(10)
            until not ENTITY.IS_ENTITY_PLAYING_ANIM(ped, "mp_suicide", "pistol", 3)
        end

        if current.data.sfx then
            self.FXManager:StartSFX()
        end
    end
end

-----------------------------------------------------
-- PropManager Subclass
-----------------------------------------------------
-- Handles props.
---@class YimActions.PropManager
YimActions.PropManager = {Props = {}}
YimActions.PropManager.__index = YimActions.PropManager

---@param owner integer
---@param propData table
---@param isPed? boolean
---@param coords? vec3
---@param faceOwner? boolean
---@param isDynamic? boolean
---@param placeOnGround? boolean
function YimActions.PropManager:SpawnProp(owner, propData, isPed, coords, faceOwner, isDynamic, placeOnGround)
    if not propData or not propData.model or not Game.EnsureModelHash(propData.model) then
        return
    end

    if not coords then
        coords = vec3:zero()
    end

    if (propData.model == 2767137151) or (propData.model == 976772591) then
        Game.Audio:PartyMode(true, owner)
    end

    Await(Game.RequestModel, propData.model)
    local prop

    if not isPed then
        prop = Game.CreateObject(
            propData.model,
            coords,
            Game.IsOnline(),
            false,
            isDynamic,
            placeOnGround,
            faceOwner and (Game.GetHeading(owner) - 180) or 0
        )
    else
        prop = Game.CreatePed(
            propData.model,
            vec3:zero(),
            0,
            Game.IsOnline(),
            false
        )
    end

    entities.take_control_of(prop, 300)

    if ENTITY.IS_ENTITY_A_PED(prop) then
        PED.SET_PED_CONFIG_FLAG(prop, 179, true)
        PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(prop, true)
        PED.SET_PED_KEEP_TASK(prop, false)
        TASK.TASK_STAND_STILL(prop, -1)
    end

    ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(prop)

    self.Props[owner] = self.Props[owner] or {}
    table.insert(self.Props[owner], prop)
    return prop
end

---@param ped integer
---@param propData table
---@param isPed? boolean
function YimActions.PropManager:AttachProp(ped, propData, isPed)
    if (
        not Game.IsScriptHandle(ped) or not
        ENTITY.DOES_ENTITY_EXIST(ped) or not
        propData or
        (next(propData) == nil)
    ) then
        return
    end

    for _, prop in ipairs(propData) do
        local i_BoneIndex = Game.GetPedBoneIndex(ped, prop.parentBone)
        local handle = self:SpawnProp(ped, prop, isPed)

        for _ = 1, 500 do
            if handle then
                if prop.parentBone ~= -1 then
                    ENTITY.ATTACH_ENTITY_TO_ENTITY(
                        handle,
                        ped,
                        i_BoneIndex,
                        prop.pos.x,
                        prop.pos.y,
                        prop.pos.z,
                        prop.rot.x,
                        prop.rot.y,
                        prop.rot.z,
                        false,
                        false,
                        false,
                        false,
                        2,
                        true,
                        1
                    )
                else
                    local placePos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 0.7, 0.0)
                    local _, groundZ = MISC.GET_GROUND_Z_FOR_3D_COORD(
                        placePos.x,
                        placePos.y,
                        placePos.z,
                        ---@diagnostic disable-next-line
                        groundZ,
                        false,
                        false
                    )

                    ENTITY.SET_ENTITY_HEADING(handle, Game.GetHeading(ped))
                    ENTITY.SET_ENTITY_COORDS(
                        handle,
                        placePos.x,
                        placePos.y,
                        groundZ,
                        false,
                        false,
                        false,
                        false
                    )
                    PHYSICS.ACTIVATE_PHYSICS(handle)
                    OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(handle)
                    ENTITY.SET_CAN_CLIMB_ON_ENTITY(handle, false)
                end

                if ENTITY.IS_ENTITY_A_PED(handle) and prop.dict then
                    Await(Game.RequestAnimDict, prop.dict)
                    Sleep(1000)
                    TASK.TASK_PLAY_ANIM(
                        handle,
                        prop.dict,
                        prop.name,
                        4.0,
                        -4.0,
                        -1,
                        1,
                        1.0,
                        false,
                        false,
                        false
                    )
                end
                break
            end
            yield()
        end

        if not handle then
            YimToast:ShowError(
                "Samurai's Scripts",
                "Failed to spawn animation prop! Please try again later."
            )
            return
        end

        if prop.ptfx and prop.ptfx.name then
            YimActions.FXManager:StartPTFX(handle, prop.ptfx)
        end
    end
end

function YimActions.PropManager:Cleanup(ped)
    ped = YimActions:GetPed(ped)

    if self.Props[ped] then
        for _, prop in ipairs(self.Props[ped]) do
            Game.DeleteEntity(prop, Game.GetCategoryFromEntityType(prop))
        end
    end

    Game.Audio:PartyMode(false)
    self.Props[ped] = nil
end

function YimActions.PropManager:Wipe()
    if next(self.Props) == nil then
        return
    end

    for _, propTable in pairs(self.Props) do
        for _, prop in pairs(propTable) do
            Game.DeleteEntity(prop, "objects")
        end
    end

    self.Props = {}
end


-----------------------------------------------------
-- FXManager Subclass
-----------------------------------------------------
-- Handles sound and visual effects.
---@class YimActions.FXManager
---@field SFXTimers table
YimActions.FXManager = {Fx = {}}
YimActions.FXManager.__index = YimActions.FXManager
YimActions.FXManager.SFXTimers = {}

function YimActions.FXManager:StartPTFX(parent, ptfxData)
    if (
        not Game.IsScriptHandle(parent) or
        not ENTITY.DOES_ENTITY_EXIST(parent) or
        not ptfxData or
        not ptfxData.dict
    ) then
        return
    end

    Await(Game.RequestNamedPtfxAsset, ptfxData.dict)
    local handle

    if Game.IsOnline() and parent ~= Self.GetPedID() then
        Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(parent))
    end

    if ptfxData.delay then
        Sleep(ptfxData.delay)
    end

    GRAPHICS.USE_PARTICLE_FX_ASSET(ptfxData.dict)

    if ENTITY.IS_ENTITY_A_PED(parent) then
        handle = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE(
            ptfxData.name,
            parent,
            ptfxData.pos.x,
            ptfxData.pos.y,
            ptfxData.pos.z,
            ptfxData.rot.x,
            ptfxData.rot.y,
            ptfxData.rot.z,
            ptfxData.bone or 0,
            ptfxData.scale or 1.0,
            false,
            false,
            false,
            0,
            0,
            0,
            255
        )
    else
        handle = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY(
            ptfxData.name,
            parent,
            ptfxData.pos.x,
            ptfxData.pos.y,
            ptfxData.pos.z,
            ptfxData.rot.x,
            ptfxData.rot.y,
            ptfxData.rot.z,
            ptfxData.scale or 1.0,
            false,
            false,
            false,
            0,
            0,
            0,
            255
        )
    end

    self.Fx[parent] = self.Fx[parent] or {}
    table.insert(self.Fx[parent], handle)
end

---@param ped integer
function YimActions.FXManager:StopPTFX(ped)
    ped = YimActions:GetPed(ped)

    if self.Fx[ped] then
        for _, fx in ipairs(self.Fx[ped]) do
            GRAPHICS.STOP_PARTICLE_FX_LOOPED(fx, false)
            GRAPHICS.REMOVE_PARTICLE_FX(fx, false)
        end

        self.Fx[ped] = nil
    end
end

function YimActions.FXManager:StartSFX(ped)
    ped = YimActions:GetPed(ped)
    local current = YimActions.CurrentlyPlaying[ped]

    if not current or not current.data.sfx.speechName then
        return
    end

    if not YimActions.PropManager.Props[ped] then
        return
    end

    self.SFXTimers[ped] = self.SFXTimers[ped] or Timer.new(0)
    local timer = self.SFXTimers[ped]

    if not timer:isDone() then
        return
    end

    for _, p in pairs(YimActions.PropManager.Props[ped]) do
        if ENTITY.IS_ENTITY_A_PED(p) and not AUDIO.IS_AMBIENT_SPEECH_PLAYING(p) then
            AUDIO.PLAY_PED_AMBIENT_SPEECH_WITH_VOICE_NATIVE(
                p,
                current.data.sfx.speechName,
                current.data.sfx.voiceName,
                current.data.sfx.speechParam or "SPEECH_PARAMS_FORCE",
                false
            )
            break
        end
    end

    timer:reset(2500)
end

function YimActions.FXManager:Wipe()
    if next(self.Fx) == nil then
        return
    end

    for _, fxTable in pairs(self.Fx) do
        for _, fxHandle in pairs(fxTable) do
            GRAPHICS.STOP_PARTICLE_FX_LOOPED(fxHandle, false)
            GRAPHICS.REMOVE_PARTICLE_FX(fxHandle, false)
        end
    end

    self.Fx = {}
end

---@class YimActions.Debugger
---@field CurrentActions table
---@field t_Props table
---@field t_Ptfx table
---@field t_Sfx table
---@field t_Actors table
YimActions.Debugger = {}
YimActions.Debugger.__index = YimActions.Debugger
YimActions.Debugger.i_PropIndex = 1
YimActions.Debugger.i_ActorIndex = 0
YimActions.Debugger.selectedProp = nil
YimActions.Debugger.t_Data = {
    CurrentActions = {},
    t_Props = {},
    t_Ptfx = {},
    t_Sfx = {},
    t_Actors = {},
}

---@param ped integer
function YimActions.Debugger:Update(ped)
    self.t_Data.CurrentActions = YimActions.CurrentlyPlaying
    self.t_Data.t_Props = YimActions.PropManager.Props
    self.t_Data.t_Ptfx = YimActions.FXManager.Fx

    t_CurrentActor = {
        handle = ped,
        props = YimActions.PropManager.Props[ped],
        ptfx = YimActions.FXManager.Fx[ped],
        sfx = {},
        isLocalPlayer = (ped == Self.GetPedID())
    }

    local actor_exists = false

    if #self.t_Data.t_Actors == 0 then
        actor_exists = false
    else
        for i = 1, #self.t_Data.t_Actors do
            if self.t_Data.t_Actors[i] and (self.t_Data.t_Actors[i].handle == ped) then
                actor_exists = true
                self.t_Data.t_Actors[i] = t_CurrentActor
                break
            end
        end
    end

    if not actor_exists then
        table.insert(self.t_Data.t_Actors, t_CurrentActor)
    end
end

---@param ped integer
function YimActions.Debugger:Remove(ped)
    for i = 1, #self.t_Data.t_Actors do
        if self.t_Data.t_Actors[i] and (self.t_Data.t_Actors[i].handle == ped) then
            self.t_Data.t_Actors[i] = nil
            return
        end
    end
end

function YimActions.Debugger:GetActionCount()
    return table.GetLength(YimActions.CurrentlyPlaying)
end

function YimActions.Debugger:GetPropCount()
    return table.GetLength(YimActions.PropManager.Props)
end

function YimActions.Debugger:GetFxCount()
    return table.GetLength(YimActions.FXManager.Fx)
end

function YimActions.Debugger:Draw()
    local actorNames = {}

    for _, v in pairs(self.t_Data.t_Actors) do
        if v then
            table.insert(actorNames, (string.format("Ped [ %d ]", v.handle)))
        end
    end

    ImGui.Spacing()
    ImGui.SeparatorText("Global Data")
    ImGui.BulletText(("Active Actions: [ %d ]"):format(self:GetActionCount()))
    ImGui.BulletText(("Active Props: [ %d ]"):format(self:GetPropCount()))
    ImGui.BulletText(("Active FX: [ %d ]"):format(self:GetFxCount()))

    ImGui.Spacing()
    ImGui.Spacing()
    ImGui.SeparatorText("Actors")
    if not self.t_Data.t_Actors or #self.t_Data.t_Actors == 0 then
        ImGui.Text("None.")
    else
        ImGui.SetNextItemWidth(200)
        self.i_ActorIndex, _ = ImGui.Combo("##actors", self.i_ActorIndex, actorNames, #self.t_Data.t_Actors)
        local actor = self.t_Data.t_Actors[self.i_ActorIndex + 1]

        if not actor then
            return
        end

        local action = YimActions.CurrentlyPlaying[actor.handle]
        ImGui.BulletText(
            string.format(
                "Current Actor: [ %s ]",
                actor.handle == Self.GetPedID() and
                "You" or
                YimActions.CompanionManager:GetCompanionNameFromHandle(actor.handle)
            )
        )
        ImGui.BulletText(("Is Player: [ %s ]"):format(actor.isLocalPlayer))

        if action then
            ImGui.BulletText("Current Action:")
            ImGui.Indent()
                ImGui.Text(
                    string.format(
                        "- Label: %s\n- Type: [ %s ]",
                        action.data.label or "N/A",
                        action:TypeAsString()
                    )
                )
            ImGui.Unindent()
            ImGui.Dummy(1, 10)
        end

        if actor.props and #actor.props > 0 then
            ImGui.BeginGroup()
            ImGui.BeginChild("##debugProplist", 200, 200, true)
                ImGui.SeparatorText("Props")
                for i = 1, #actor.props do
                    local is_selected = (self.i_PropIndex == i - 1)

                    if ImGui.Selectable(tostring(actor.props[i]), is_selected) then
                        self.i_PropIndex = i - 1
                    end

                    if UI.IsItemClicked("lmb") then
                        script.run_in_fiber(function()
                            self.selectedProp = {
                                handle = actor.props[self.i_PropIndex],
                                attached = ENTITY.IS_ENTITY_ATTACHED(actor.props[self.i_PropIndex]),
                                type = Game.GetEntityTypeString(actor.props[self.i_PropIndex])
                            }
                        end)
                    end
                end
            ImGui.EndChild()

            ImGui.SameLine()
            ImGui.SetNextWindowBgAlpha(0.0)
            ImGui.BeginChild("##debugPropInfo", 250, 200)
                ImGui.SeparatorText("Prop Info")
                if not self.selectedProp then
                    UI.ColoredText("Not Selected.", "yellow")
                else
                    ImGui.BulletText(("Prop Type: [ %s ]"):format(self.selectedProp.type))
                    ImGui.BulletText(("Is Attached: [ %s ]"):format(self.selectedProp.attached))
                end
            ImGui.EndChild()
            ImGui.EndGroup()

            if ImGui.Button("Remove Props") then
                script.run_in_fiber(function()
                    YimActions.PropManager:Cleanup(actor.handle)
                end)
            end

            ImGui.SameLine()

            if ImGui.Button("Stop FX") then
                script.run_in_fiber(function()
                    YimActions.FXManager:StopPTFX(actor.handle)
                end)
            end

            ImGui.SameLine()

            if ImGui.Button("Reset") then
                script.run_in_fiber(function()
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(actor.handle)
                end)
            end

            if ImGui.Button("Wipe") then
                script.run_in_fiber(function()
                    YimActions:ForceCleanup()
                end)
            end
        end
    end
end
