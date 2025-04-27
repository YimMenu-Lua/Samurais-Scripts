-----------------------------------------------------
-- CompanionManager Class
-----------------------------------------------------
-- Handles comanions (NPCs).
---@class CompanionManager
---@field Companions Companion[]
---@field PedCombatAttributes table<integer, integer>
---@field PedConfigFlags table<integer, integer>
CompanionManager = {}
CompanionManager.__index = CompanionManager
CompanionManager.Companions = {}
CompanionManager.PedCombatAttributes = {
    1, 2, 3, 4, 5, 13, 20, 21, 22, 27, 28, 31, 34, 38, 41, 42, 46, 50, 54, 55, 58, 61, 68, 71
}
CompanionManager.PedConfigFlags = {
    118, 141, 179, 188, 193, 208, 261, 268, 286, 294, 301, 364, 398, 401, 443
}

function CompanionManager:New()
    local instance = setmetatable({}, CompanionManager)
    instance.Companions = {}

    return instance
end

---@param pedModel integer|string
---@param s_Name string
---@param b_IsInvincible? boolean
---@param b_IsArmed? boolean
---@param b_IsSaved? boolean
function CompanionManager:SpawnCompanion(pedModel, s_Name, b_IsInvincible, b_IsArmed, b_IsSaved)
    if not Game.EnsureModelHash(pedModel) then
        return 0
    end

    if type(pedModel) == "string" then
        pedModel = Game.GetPedHash(pedModel)
    end

    Await(Game.RequestModel, pedModel)

    local localPlayer = Self.GetPedID()
    local playerGroup = Self.GetGroupIndex()
    local v_OffsetCoords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
        localPlayer,
        math.random(-5, 5),
        math.random(2, 5),
        0.0
    )

    local i_Handle = Game.CreatePed(
        pedModel,
        v_OffsetCoords,
        Game.GetHeading(localPlayer) - 180,
        Game.IsOnline(),
        false
    )

    entities.take_control_of(i_Handle, 300)
    PED.SET_PED_AS_GROUP_MEMBER(i_Handle, playerGroup)
    PED.SET_PED_NEVER_LEAVES_GROUP(i_Handle, true)
    PED.SET_PED_CAN_TELEPORT_TO_GROUP_LEADER(i_Handle, playerGroup, true)
    PED.SET_PED_CONFIG_FLAG(i_Handle, 167, false)
    PED.SET_PED_FLEE_ATTRIBUTES(i_Handle, 1 << 15, false)
    ENTITY.SET_ENTITY_INVINCIBLE(i_Handle, b_IsInvincible or false)


    for _, flag in ipairs(self.PedConfigFlags) do
        PED.SET_PED_CONFIG_FLAG(i_Handle, flag, true)
    end

    for i = 0, 17 do
        PED.SET_RAGDOLL_BLOCKING_FLAGS(i_Handle, i)
    end

    if b_IsArmed then
        WEAPON.GIVE_WEAPON_TO_PED(i_Handle, 350597077, 9999, false, true)
        PED.SET_PED_FIRING_PATTERN(i_Handle, 0xC6EE6B4C) -- full auto goes brrrrrrrr
        PED.SET_PED_COMBAT_ABILITY(i_Handle, 2)
        PED.SET_PED_CAN_BE_TARGETTED(i_Handle, false)

        for _, attr in ipairs(self.PedCombatAttributes) do
            PED.SET_PED_COMBAT_ATTRIBUTES(i_Handle, attr, true)
        end
    end

    local i_Blip = Game.AddBlipForEntity(i_Handle, 0.8, true, true, "YAV3 Companion")
    table.insert(
        self.Companions,
            Companion.new(
            s_Name,
            i_Handle,
            pedModel,
            b_IsInvincible,
            b_IsArmed,
            i_Blip,
            b_IsSaved
        )
    )

    return i_Handle
end

---@param handle integer
function CompanionManager:GetCompanionNameFromHandle(handle)
    if next(self.Companions) == nil then
        return tostring(handle)
    end

    for _, companion in ipairs(self.Companions) do
        if companion.handle == handle then
            return companion.name
        end
    end

    return tostring(handle)
end

function CompanionManager:AreAnyCompanionsPlaying()
    if next(self.Companions) == nil then
        return false
    end

    for _, companion in ipairs(self.Companions) do
        if YimActions:IsPedPlaying(companion.handle) then
            return true
        end
    end

    return false
end

---@param action Action
function CompanionManager:AllCompanionsPlay(action)
    if next(self.Companions) == nil then
        return
    end

    for _, companion in ipairs(self.Companions) do
        if companion and companion.handle then
            YimActions:Play(action, companion.handle)
        end
    end
end

function CompanionManager:StopAllCompanions()
    if next(self.Companions) == nil then
        return
    end

    for _, companion in ipairs(self.Companions) do
        if companion and companion.handle and YimActions:IsPedPlaying(companion.handle) then
            YimActions:Cleanup(companion.handle)
        end
    end
end

-- Teleports all companions in front of the player
function CompanionManager:BringAllCompanions()
    if next(self.Companions) == nil then
        return
    end

    local x_offset = 1
    local y_offset = Self.IsOnFoot() and 1 or 6.9 -- I'm a child

    for _, companion in ipairs(self.Companions) do
        local offsetCoords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
            Self.GetPedID(),
            x_offset,
            y_offset,
            0.0
        )

        if companion and companion.handle then
            YimActions:Cleanup(companion.handle)
            Game.SetEntityCoordsNoOffset(companion.handle, offsetCoords)
            x_offset = x_offset + 1
            y_offset = y_offset + 1
        end
        Sleep(200)
    end
end

---@param companion Companion
function CompanionManager:RemoveCompanion(companion)
    YimActions:Cleanup(companion.handle)

    if Game.IsScriptHandle(companion.handle) then
        if PED.IS_PED_GROUP_MEMBER(companion.handle, Self.GetGroupIndex()) then
            PED.REMOVE_PED_FROM_GROUP(companion.handle)
        end

        HUD.REMOVE_BLIP(companion.blip.handle)
        Game.DeleteEntity(companion.handle, "peds")
        for i = #self.Companions, 1, -1 do
            if self.Companions[i].handle == companion.handle then
                self.Companions[i] = nil
                break
            end
        end
    end
end

function CompanionManager:Wipe()
    if next(self.Companions) == nil then
        return
    end

    for _, companion in pairs(self.Companions) do
        Game.DeleteEntity(companion.handle, "peds")
    end

    self.Companions = {}
end

-- Handles dead and/or stale companions and their map blips.
function CompanionManager:Watchdog()
    if next(self.Companions) == nil then
        return
    end

    for i = #self.Companions, 1, -1 do
        if not ENTITY.DOES_ENTITY_EXIST(self.Companions[i].handle) then
            self.Companions[i] = nil
        else
            if ENTITY.IS_ENTITY_DEAD(self.Companions[i].handle, false) then
                self:RemoveCompanion(self.Companions[i])
            else
                if PED.IS_PED_IN_ANY_VEHICLE(self.Companions[i].handle, true) then
                    if self.Companions[i].blip.alpha > 0 then
                        self.Companions[i].blip.alpha = 0
                        HUD.SET_BLIP_ALPHA(self.Companions[i].blip.handle, 0)
                    end
                else
                    if self.Companions[i].blip.alpha < 255 then
                        self.Companions[i].blip.alpha = 255
                        HUD.SET_BLIP_ALPHA(self.Companions[i].blip.handle, 255)
                    end
                end
            end
        end
    end
end


-----------------------------------------------------
-- Companion Class
-----------------------------------------------------
-- Represents a companion (NPC).
---@class Companion
---@field name string
---@field handle integer script handle
---@field model integer model hash
---@field godmode boolean
---@field armed boolean
---@field blip table<string, integer>
---@field time_created number
---@field is_saved boolean I forgot what I was going to use this for
Companion = {}
Companion.__index = Companion

---@param name string
---@param handle integer
---@param model integer
---@param is_invincible? boolean
---@param is_armed? boolean
---@param blip? integer
---@param is_saved? boolean
function Companion.new(name, handle, model, is_invincible, is_armed, blip, is_saved)
    local instance = setmetatable({}, Companion)
    instance.name = name or "unknown"
    instance.handle = handle
    instance.model = model
    instance.godmode = is_invincible or false
    instance.armed = is_armed or false
    instance.blip = {handle = blip or 0, alpha = 255}
    instance.is_saved = is_saved or false
    instance.time_created = Time.now()

    return instance
end

-- Enables/Disables ped invincibility.
function Companion:ToggleGodmode()
    script.run_in_fiber(function()
        ENTITY.SET_ENTITY_INVINCIBLE(self.handle, not self.godmode)
        self.godmode = not self.godmode
    end)
end

-- Disarms the ped if they are armed or gives them a tactical SMG if they are not.
--
-- Custom weapons are neither supported nor they will be. I'm not turning this into a bodyguard service.
function Companion:ToggleWeapon()
    script.run_in_fiber(function()
        if self.armed then
            WEAPON.REMOVE_ALL_PED_WEAPONS(self.handle, true)
        else
            WEAPON.GIVE_WEAPON_TO_PED(self.handle, 350597077, 9999, false, true)
        end
        self.armed = not self.armed
    end)
end

-- Wompus shall rise
function CompanionManager:FulfillTheProphecy()
    script.run_in_fiber(function()
        local spawnPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
            Self.GetPedID(),
            0.0,
            10.0,
            20.0
        )

        local handle = Game.CreatePed(joaat("A_C_Boar_02"), spawnPos, Self.GetHeading() - 180)
        local MinimusWompusMeridius = Companion.new(
            "Minimus Wompus Meridius",
            handle,
            joaat("A_C_Boar_02")
        )

        -- TODO: RNG to decide whether to spawn wholesome or evil Wompus. For now it's just evil Wompus blowing you and himself up
        MinimusWompusMeridius:AD_MORTEM_INIMICUS()
    end)
end

-- PERII
function Companion:AD_MORTEM_INIMICUS()
    if NETWORK.NETWORK_IS_ACTIVITY_SESSION() or not Self.IsOutside() then
        return
    end

    ENTITY.FREEZE_ENTITY_POSITION(self.handle, true)
    ENTITY.SET_ENTITY_INVINCIBLE(self.handle, true)
    PED.SET_PED_KEEP_TASK(self.handle, false)
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.handle)
    TASK.TASK_STAND_STILL(self.handle, -1)
    WEAPON.GIVE_WEAPON_TO_PED(self.handle, joaat("WEAPON_MACHETE"), 1, false, true)
    PED.SET_PED_CONFIG_FLAG(self.handle, 118, false)
    PED.SET_PED_CONFIG_FLAG(self.handle, 294, true)
    PED.SET_PED_COMBAT_ATTRIBUTES(self.handle, 63, false)

    for _, flag in ipairs(CompanionManager.PedCombatAttributes) do
        PED.SET_PED_COMBAT_ATTRIBUTES(self.handle, flag, true)
    end

    local cam = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", true)
    local rot = Self.GetRot()
    local camPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
        Self.GetPedID(),
        0,
        1,
        1
    )

    CAM.SET_CAM_PARAMS(
        cam,
        camPos.x,
        camPos.y,
        camPos.z,
        rot.x,
        rot.y,
        rot.z,
        80,
        0,
        1,
        1,
        2
    )

    Game.Audio:ToggleEmitter(
        Game.Audio.Emitters.rave_1,
        true,
        self.handle,
        "HIDDEN_RADIO_04_PUNK"
    )
    CAM.POINT_CAM_AT_ENTITY(cam, self.handle, 0, 0, 0, true)
    UI.WidgetSound("Focus_Out")
    CAM.RENDER_SCRIPT_CAMS(true, true, 500, true, false)
    MISC.SET_OVERRIDE_WEATHER("THUNDER")
    GRAPHICS.ANIMPOSTFX_PLAY("PPGREEN", 25000, false)
    Await(Game.RequestWeaponAsset, joaat("WEAPON_RPG"))

    local highPos = Game.GetEntityCoords(self.handle, false)
    Sleep(2500)
    AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(
        "GENERIC_INSULT_HIGH",
        "S_M_Y_BLACKOPS_01_BLACK_MINI_01",
        highPos.x,
        highPos.y,
        highPos.z,
        "SPEECH_PARAMS_FORCE_HELI"
    )
    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
        highPos.x,
        highPos.y,
        highPos.z,
        highPos.x,
        highPos.y,
        highPos.z - 0.1,
        0,
        false,
        joaat("WEAPON_RPG"),
        Self.GetPedID(),
        true,
        false,
        -1
    )
    Sleep(2500)

    local timer = Timer.new(5000)

    while ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(self.handle) > 1 and not timer:isDone() do
        local tDelta = math.min(1, Self.GetDeltaTime() * 10)
        local lastPos = Game.GetEntityCoords(self.handle, false)
        local targetPos = vec3:new(lastPos.x, lastPos.y, lastPos.z - 1)

        lastPos = lastPos:lerp(targetPos, tDelta)
        Game.SetEntityCoordsNoOffset(self.handle, lastPos)
        yield()
    end

    CAM.SHAKE_CAM(cam, "LARGE_EXPLOSION_SHAKE", 0.5)
    Await(Game.RequestNamedPtfxAsset, "scr_family5")
    Game.StartSyncedPtfxNonLoopedOnEntityBone(
        self.handle,
        "scr_xs_dr",
        "scr_xs_dr_emp",
        {0x0},
        vec3:zero(),
        vec3:zero(),
        1
    )
    Sleep(2000)

    local groundPos = Game.GetEntityCoords(self.handle, false)
    AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(
        "GENERIC_WAR_CRY",
        "S_M_Y_BLACKOPS_01_BLACK_MINI_01",
        groundPos.x,
        groundPos.y,
        groundPos.z,
        "SPEECH_PARAMS_FORCE_HELI"
    )

    YimToast:ShowMessage(
        "MINIMUS WOMPUS MERIDIUS",
        "« And thus began the chronicles of Minimus Wompus Meridius:\nProtector of funk, destroyer of HUDs, sniffer of drift tires. »",
        false,
        10
    )
    log.info(WompusChronicles)

    local wompus_group = PED.GET_PED_RELATIONSHIP_GROUP_HASH(self.handle)
    local my_group = Self.GetRelationshipGroupHash()

    PED.SET_RELATIONSHIP_BETWEEN_GROUPS(5, wompus_group, my_group)
    PED.SET_RELATIONSHIP_BETWEEN_GROUPS(5, my_group, wompus_group)
    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(self.handle, true)
    TASK.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(self.handle, true)
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.handle)
    PED.SET_PED_KEEP_TASK(self.handle, true)
    TASK.TASK_COMBAT_PED(self.handle, Self.GetPedID(), 0, 16)
    ENTITY.FREEZE_ENTITY_POSITION(self.handle, false)
    CAM.RENDER_SCRIPT_CAMS(false, true, 500, true, false)
    CAM.DESTROY_CAM(cam, false)

    local timer_2 = Timer.new(10000)
    while not timer_2:isDone() do
        if not Self.IsAlive() then
            break
        end

        local pos = Game.GetEntityCoords(self.handle, false)
        local f_ScreenX, f_ScreenY = 0, 0
        _, f_ScreenX, f_ScreenY = GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(
            pos.x,
            pos.y,
            pos.z,
            f_ScreenX,
            f_ScreenY
        )

        Game.DrawText(
            vec2:new(f_ScreenX - 0.025, f_ScreenY - 0.09),
            "MINIMUS  WOMPUS  MERIDIUS",
            Col(255, 255, 255, 220),
            vec2:new(0.1, 0.3),
            4
        )
        yield()
    end

    local most_recent_pos = Game.GetEntityCoords(self.handle, false)
    ENTITY.SET_ENTITY_INVINCIBLE(self.handle, false)
    Sleep(10)
    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
        most_recent_pos.x,
        most_recent_pos.y,
        most_recent_pos.z + 0.1,
        most_recent_pos.x,
        most_recent_pos.y,
        most_recent_pos.z,
        999,
        false,
        joaat("WEAPON_RPG"),
        Self.GetPedID(),
        true,
        false,
        -1
    )

    GRAPHICS.ANIMPOSTFX_STOP("PPGREEN")
    MISC.CLEAR_OVERRIDE_WEATHER()
    ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(self.handle)
    Game.Audio:StopAllEmitters()
    YimToast:ShowMessage(
        "MINIMUS WOMPUS MERIDIUS",
        "The prophecy has been fulfilled! Wompus shall rise. Wompus shall rave. Wompus shall rupture.",
        false,
        10
    )
end

return CompanionManager
