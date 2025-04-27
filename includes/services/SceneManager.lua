-- Thanks to [Lucas7yoshi](https://rage.re/u/Lucas7yoshi) for the detailed explanation on network scenes: https://rage.re/t/network-synchronized-scenes/305

---@class Scene
---@field label string
---@field netHandle integer Network handle
---@field localHandle integer Script handle
---@field animDict string
---@field origin table Entity the scene will orient towards (ped, object)
---@field participants table<integer, table> List of entities participating in the scene
---@field params table Playback params (loop, holdLastFrame, ...)
Scene = {}
Scene.__index = Scene

---@param s_Label string
---@param s_AnimDict string
---@param origin table
---@param t_Participants table
---@param t_Params? table
function Scene.new(
    s_Label,
    s_AnimDict,
    origin,
    t_Participants,
    t_Params
)
    local instance = setmetatable({}, Scene)
    instance.label = s_Label
    instance.animDict = s_AnimDict
    instance.origin = origin
    instance.participants = t_Participants
    instance.params = t_Params or {}

    return instance
end

function Scene:IsRunning()
    if not self.localHandle or self.localHandle == -1 then
        return false
    end

    return PED.IS_SYNCHRONIZED_SCENE_RUNNING(self.localHandle)
end


---@class SceneManager
---@field CurrentlyPlaying Scene[]
SceneManager = {}
SceneManager.__index = SceneManager
SceneManager.CurrentlyPlaying = {}

function SceneManager:CreateParticipant(model)
    local v_SpawnPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
        Self.GetPedID(),
        0.0,
        0.0,
        -50.0
    )

    if type(model) == "string" then
        model = joaat(model)
    end

    if STREAMING.IS_MODEL_A_PED(model) then
        if model == Self.GetPedModel() then
            return Self.GetPedID()
        end

        return Game.CreatePed(
            model,
            v_SpawnPos,
            Self.GetHeading()
        )
    elseif STREAMING.IS_MODEL_A_VEHICLE(model) then
        return Game.CreateVehicle(
            model,
            v_SpawnPos,
            Self.GetHeading()
        )
    else
        return Game.CreateObject(
            model,
            v_SpawnPos,
            true,
            false,
            true,
            false,
            Self.GetHeading()
        )
    end
end

---@param t_Data table
function SceneManager:PrepareScene(t_Data)
    local originEntity
    local sceneParticipants = {}

    if t_Data.origin.isPlayer then
        originEntity = Self.GetPedID()
    else
        originEntity = self:CreateParticipant(t_Data.origin.model)
    end

    for _, participant in ipairs(t_Data.participants) do
        local handle = participant.isPlayer and Self.GetPedID() or self:CreateParticipant(participant.model)
        table.insert(
            sceneParticipants,
            {
                handle = handle,
                animName = participant.animName
            }
        )
    end

    return Scene.new(
        t_Data.label,
        t_Data.animDict,
        {handle = originEntity, pos_offset = t_Data.origin.pos_offset or vec3:zero()},
        sceneParticipants,
        t_Data.params or {}
    )
end

function SceneManager:GetSceneGroundPos(v_InitialPos)
    local success, groundZ = false, 0
    local x, y = v_InitialPos.x, v_InitialPos.y

    success, groundZ = MISC.GET_GROUND_Z_FOR_3D_COORD(
        x,
        y,
        v_InitialPos.z,
        groundZ,
        false,
        false
    )

    if success then
        return vec3:new(x, y, groundZ)
    end

    return v_InitialPos
end


---@param t_Data Scene
function SceneManager:PlayNetworkedScene(t_Data)
    if not Game.IsOnline() then
        return
    end

    if next(self.CurrentlyPlaying) ~= nil then
        YimToast:ShowMessage(
            "Samurai's Scripts",
            "A scene is already playing."
        )
        return
    end

    local scene = self:PrepareScene(t_Data)

    if not ENTITY.DOES_ENTITY_EXIST(scene.origin.handle) then
        log.warning("origin entity not found")
        return
    end

    local v_OriginPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
        Self.GetPedID(),
        scene.origin.pos_offset.x,
        scene.origin.pos_offset.y,
        scene.origin.pos_offset.z
    )

    if ENTITY.IS_ENTITY_A_PED(scene.origin.handle) then
        v_OriginPos = self:GetSceneGroundPos(v_OriginPos)
    end

    if scene.origin.handle ~= Self.GetPedID() then
        Game.SetEntityCoords(scene.origin.handle, v_OriginPos)
    end

    Await(Game.RequestAnimDict, scene.animDict)
    local v_OriginRot = Game.GetEntityRotation(scene.origin.handle, 2)
    local sceneHandle = NETWORK.NETWORK_CREATE_SYNCHRONISED_SCENE(
        v_OriginPos.x,
        v_OriginPos.y,
        v_OriginPos.z,
        v_OriginRot.x,
        v_OriginRot.y,
        v_OriginRot.z,
        2,
        t_Data.params.holdLastFrame or false,
        t_Data.params.loop or false,
        1.0,
        t_Data.params.startPhase or 0.0,
        t_Data.params.animSpeed or 1.0
    )

    for _, participant in ipairs(scene.participants) do
        if ENTITY.DOES_ENTITY_EXIST(participant.handle) then
            if ENTITY.IS_ENTITY_A_PED(participant.handle) then
                if participant.handle ~= Self.GetPedID() then
                    local offset = 1

                    entities.take_control_of(participant.handle, 300)
                    Game.SetEntityCoords(participant.handle, v_OriginPos + offset)
                    offset = offset + 1
                end

                TASK.CLEAR_PED_TASKS_IMMEDIATELY(participant.handle)
                NETWORK.NETWORK_ADD_PED_TO_SYNCHRONISED_SCENE(
                    participant.handle,
                    sceneHandle,
                    scene.animDict,
                    participant.animName,
                    4.0,
                    -4.0,
                    -1,
                    1,
                    8.0,
                    0
                )
            else
                NETWORK.NETWORK_ADD_ENTITY_TO_SYNCHRONISED_SCENE(
                    participant.handle,
                    sceneHandle,
                    scene.animDict,
                    participant.animName,
                    4.0,
                    -4.0,
                    0
                )
            end
        end
        yield()
    end

    NETWORK.NETWORK_START_SYNCHRONISED_SCENE(sceneHandle)
    scene.netHandle = sceneHandle
    Sleep(10)
    scene.localHandle = NETWORK.NETWORK_GET_LOCAL_SCENE_FROM_NETWORK_ID(scene.netHandle)

    if not sceneHandle or not PED.IS_SYNCHRONIZED_SCENE_RUNNING(scene.localHandle) then
        YimToast:ShowError(
            "Samurai's Scripts",
            "Failed to start scene!"
        )

        self:Wipe()
        return
    end

    self.CurrentlyPlaying[sceneHandle] = scene
end

---@param t_Data table
function SceneManager:PlayLocalScene(t_Data)
    if next(self.CurrentlyPlaying) ~= nil then
        YimToast:ShowMessage(
            "Samurai's Scripts",
            "A scene is already playing."
        )
        return
    end

    local scene = self:PrepareScene(t_Data)

    if not ENTITY.DOES_ENTITY_EXIST(scene.origin.handle) then
        log.warning("origin entity not found!")
        return
    end

    local v_OriginPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
        Self.GetPedID(),
        scene.origin.pos_offset.x,
        scene.origin.pos_offset.y,
        scene.origin.pos_offset.z
    )

    if ENTITY.IS_ENTITY_A_PED(scene.origin.handle) then
        v_OriginPos = self:GetSceneGroundPos(v_OriginPos)
    end

    if scene.origin.handle ~= Self.GetPedID() then
        Game.SetEntityCoords(scene.origin.handle, v_OriginPos)
    end

    Await(Game.RequestAnimDict, scene.animDict)
    local v_OriginRot = Game.GetEntityRotation(scene.origin.handle, 2)
    local sceneHandle = PED.CREATE_SYNCHRONIZED_SCENE(
        v_OriginPos.x,
        v_OriginPos.y,
        v_OriginPos.z,
        v_OriginRot.x,
        v_OriginRot.y,
        v_OriginRot.z,
        2
    )

    PED.SET_SYNCHRONIZED_SCENE_HOLD_LAST_FRAME(sceneHandle, scene.params.holdLastFrame or false)
    PED.SET_SYNCHRONIZED_SCENE_LOOPED(sceneHandle, scene.params.looped or false)

    for _, participant in ipairs(scene.participants) do
        if ENTITY.DOES_ENTITY_EXIST(participant.handle) then
            if not ENTITY.IS_ENTITY_A_PED(participant.handle) then
                Game.DeleteEntity(participant.handle, Game.GetCategoryFromEntityType(participant.handle))
                YimToast:ShowWarning(
                    "Samurai's Scripts",
                    "Some props from this scene have been removed because they are online-only.",
                    false,
                    5
                )
            else
                if participant.handle ~= Self.GetPedID() then
                    local tries = 0
                    while not ENTITY.DOES_ENTITY_EXIST(participant.handle) and tries < 20 do
                        yield()
                        tries = tries + 1
                    end

                    Game.SetEntityCoords(participant.handle, v_OriginPos)
                end

                TASK.TASK_SYNCHRONIZED_SCENE(
                    participant.handle,
                    sceneHandle,
                    scene.animDict,
                    participant.animName,
                    4.0,
                    -4.0,
                    0,
                    0,
                    0x447A0000,
                    0
                )
            end
        end
    end

    scene.netHandle = sceneHandle
    scene.localHandle = sceneHandle

    if  not scene.localHandle or not PED.IS_SYNCHRONIZED_SCENE_RUNNING(scene.localHandle) then
        YimToast:ShowError(
            "Samurai's Scripts",
            "Failed to start scene!"
        )

        self:Wipe()
        return
    end

    self.CurrentlyPlaying[scene.localHandle] = scene
end

function SceneManager:Play(t_Data)
    if Game.IsOnline() then
        self:PlayNetworkedScene(t_Data)
    else
        self:PlayLocalScene(t_Data)
    end
end

---@param scene Scene
function SceneManager:Stop(scene)
    if self.CurrentlyPlaying[scene.localHandle] then
        if Game.IsOnline() then
            NETWORK.NETWORK_STOP_SYNCHRONISED_SCENE(scene.netHandle)
        else
            for _, participant in ipairs(scene.participants) do
                TASK.CLEAR_PED_TASKS(participant.handle)
            end
        end

        self.CurrentlyPlaying[scene.localHandle] = nil
    end
end

function SceneManager:Wipe()
    if next(self.CurrentlyPlaying) == nil then
        return
    end

    for _, scn in pairs(self.CurrentlyPlaying) do
        NETWORK.NETWORK_STOP_SYNCHRONISED_SCENE(scn.netHandle)
        Game.DeleteEntity(scn.origin.handle, Game.GetCategoryFromEntityType(scn.origin.handle))

        for _, p in ipairs(scn.participants) do
            Game.DeleteEntity(p.handle, Game.GetCategoryFromEntityType(p.handle))
        end
    end

    TASK.CLEAR_PED_TASKS(Self.GetPedID())
    self.CurrentlyPlaying = {}
end
