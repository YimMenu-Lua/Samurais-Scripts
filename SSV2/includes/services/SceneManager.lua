local Scene = require("includes.structs.SynchronizedScene")

---@class SceneManager
---@field CurrentlyPlaying table<integer, Scene>
local SceneManager = {}
SceneManager.__index = SceneManager
SceneManager.CurrentlyPlaying = {}

---@param model string|hash
function SceneManager:CreateParticipant(model)
	local v_SpawnPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
		Self:GetHandle(),
		0.0,
		0.0,
		-50.0
	)

	if (type(model) == "string") then
		model = joaat(model)
	end

	if (STREAMING.IS_MODEL_A_PED(model)) then
		if model == Self:GetModelHash() then
			return Self:GetHandle()
		end

		return Game.CreatePed(
			model,
			v_SpawnPos,
			Self:GetHeading()
		)
	elseif STREAMING.IS_MODEL_A_VEHICLE(model) then
		return Game.CreateVehicle(
			model,
			v_SpawnPos,
			Self:GetHeading()
		)
	else
		return Game.CreateObject(
			model,
			v_SpawnPos,
			true,
			false,
			true,
			false,
			Self:GetHeading()
		)
	end
end

---@param t_Data SyncedSceneData
function SceneManager:PrepareScene(t_Data)
	local originEntity
	local sceneParticipants = {}

	if (t_Data.origin.isPlayer) then
		originEntity = Self:GetHandle()
	else
		originEntity = self:CreateParticipant(t_Data.origin.model)
	end

	for _, participant in ipairs(t_Data.participants) do
		local handle = participant.isPlayer and Self:GetHandle() or self:CreateParticipant(participant.model)
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
		{ handle = originEntity, pos_offset = t_Data.origin.pos_offset or vec3:zero() },
		sceneParticipants,
		t_Data.params or {}
	)
end

---@param initial_pos vec3
function SceneManager:GetSceneGroundPos(initial_pos)
	local success, groundZ = false, 0
	local x, y = initial_pos.x, initial_pos.y

	success, groundZ = MISC.GET_GROUND_Z_FOR_3D_COORD(
		x,
		y,
		initial_pos.z,
		groundZ,
		false,
		false
	)

	if (success) then
		return vec3:new(x, y, groundZ)
	end

	return initial_pos
end

---@return boolean
function SceneManager:IsPlaying()
	return next(self.CurrentlyPlaying) ~= nil
end

---@param sceneData SyncedSceneData
function SceneManager:PlayNetworkedScene(sceneData)
	if (not Game.IsOnline()) then
		return
	end

	if (self:IsPlaying()) then
		Notifier:ShowMessage(
			"Samurai's Scripts",
			"A scene is already playing."
		)
		return
	end

	local scene = self:PrepareScene(sceneData)

	if (not ENTITY.DOES_ENTITY_EXIST(scene.origin.handle)) then
		log.warning("origin entity not found")
		return
	end

	local originPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
		Self:GetHandle(),
		scene.origin.pos_offset.x,
		scene.origin.pos_offset.y,
		scene.origin.pos_offset.z
	)

	if (ENTITY.IS_ENTITY_A_PED(scene.origin.handle)) then
		originPos = self:GetSceneGroundPos(originPos)
	end

	if scene.origin.handle ~= Self:GetHandle() then
		Game.SetEntityCoords(scene.origin.handle, originPos)
	end

	TaskWait(Game.RequestAnimDict, scene.animDict)
	local originRot = Game.GetEntityRotation(scene.origin.handle, 2)
	local sceneHandle = NETWORK.NETWORK_CREATE_SYNCHRONISED_SCENE(
		originPos.x,
		originPos.y,
		originPos.z,
		originRot.x,
		originRot.y,
		originRot.z,
		2,
		sceneData.params.holdLastFrame or false,
		sceneData.params.looped or false,
		1.0,
		sceneData.params.startPhase or 0.0,
		sceneData.params.animSpeed or 1.0
	)

	for _, participant in ipairs(scene.participants) do
		if ENTITY.DOES_ENTITY_EXIST(participant.handle) then
			if (ENTITY.IS_ENTITY_A_PED(participant.handle)) then
				if (participant.handle ~= Self:GetHandle()) then
					local offset = 1
					entities.take_control_of(participant.handle, 300)
					Game.SetEntityCoords(participant.handle, originPos + offset)
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
	sleep(10)
	scene.localHandle = NETWORK.NETWORK_GET_LOCAL_SCENE_FROM_NETWORK_ID(scene.netHandle)

	if (not sceneHandle or not PED.IS_SYNCHRONIZED_SCENE_RUNNING(scene.localHandle)) then
		Notifier:ShowError(
			"Samurai's Scripts",
			"Failed to start scene!"
		)

		self:Wipe()
		return
	end

	self.CurrentlyPlaying[sceneHandle] = scene
end

---@param sceneData SyncedSceneData
function SceneManager:PlayLocalScene(sceneData)
	if (self:IsPlaying()) then
		Notifier:ShowMessage(
			"Samurai's Scripts",
			"A scene is already playing."
		)
		return
	end

	local scene = self:PrepareScene(sceneData)

	if (not ENTITY.DOES_ENTITY_EXIST(scene.origin.handle)) then
		log.warning("origin entity not found!")
		return
	end

	local originPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
		Self:GetHandle(),
		scene.origin.pos_offset.x,
		scene.origin.pos_offset.y,
		scene.origin.pos_offset.z
	)

	if (ENTITY.IS_ENTITY_A_PED(scene.origin.handle)) then
		originPos = self:GetSceneGroundPos(originPos)
	end

	if (scene.origin.handle ~= Self:GetHandle()) then
		Game.SetEntityCoords(scene.origin.handle, originPos)
	end

	TaskWait(Game.RequestAnimDict, scene.animDict)
	local originRot = Game.GetEntityRotation(scene.origin.handle, 2)
	local sceneHandle = PED.CREATE_SYNCHRONIZED_SCENE(
		originPos.x,
		originPos.y,
		originPos.z,
		originRot.x,
		originRot.y,
		originRot.z,
		2
	)

	PED.SET_SYNCHRONIZED_SCENE_HOLD_LAST_FRAME(sceneHandle, scene.params.holdLastFrame or false)
	PED.SET_SYNCHRONIZED_SCENE_LOOPED(sceneHandle, scene.params.looped or false)

	for _, participant in ipairs(scene.participants) do
		if ENTITY.DOES_ENTITY_EXIST(participant.handle) then
			if not ENTITY.IS_ENTITY_A_PED(participant.handle) then
				Game.DeleteEntity(participant.handle)
				Notifier:ShowWarning(
					"Samurai's Scripts",
					"Some props from this scene have been removed because they are online-only.",
					false,
					5
				)
			else
				if (participant.handle ~= Self:GetHandle()) then
					local tries = 0
					while (not ENTITY.DOES_ENTITY_EXIST(participant.handle) and tries < 20) do
						yield()
						tries = tries + 1
					end

					Game.SetEntityCoords(participant.handle, originPos)
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

	if (not scene.localHandle or not PED.IS_SYNCHRONIZED_SCENE_RUNNING(scene.localHandle)) then
		Notifier:ShowError(
			"Samurai's Scripts",
			"Failed to start scene!"
		)

		self:Wipe()
		return
	end

	self.CurrentlyPlaying[scene.localHandle] = scene
end

---@param sceneData SyncedSceneData
function SceneManager:Play(sceneData)
	if (Game.IsOnline()) then
		self:PlayNetworkedScene(sceneData)
	else
		self:PlayLocalScene(sceneData)
	end
end

---@param scene Scene
function SceneManager:Stop(scene)
	if (not self.CurrentlyPlaying[scene.localHandle]) then
		return
	end

	if (Game.IsOnline()) then
		NETWORK.NETWORK_STOP_SYNCHRONISED_SCENE(scene.netHandle)
	else
		for _, participant in ipairs(scene.participants) do
			TASK.CLEAR_PED_TASKS(participant.handle)
		end
	end

	self.CurrentlyPlaying[scene.localHandle] = nil
end

function SceneManager:Wipe()
	if (not self:IsPlaying()) then
		return
	end

	for _, scn in pairs(self.CurrentlyPlaying) do
		NETWORK.NETWORK_STOP_SYNCHRONISED_SCENE(scn.netHandle)
		Game.DeleteEntity(scn.origin.handle)

		for _, p in ipairs(scn.participants) do
			Game.DeleteEntity(p.handle)
		end
	end

	Self:ClearTasks()
	self.CurrentlyPlaying = {}
end

return SceneManager
