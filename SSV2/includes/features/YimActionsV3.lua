-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local SceneManager     = require("includes.services.SceneManager")
local CompanionManager = require("includes.services.CompanionManager")
local t_AnimList       = require("includes.data.actions.animations")
local t_PedScenarios   = require("includes.data.actions.scenarios")
local Action           = require("includes.structs.Action")
local Weapons          = require("includes.data.weapons")

---@alias ActionCategory
--- | "anims"
--- | "scenarios"
--- | "scenes"
--- | "clipsets"


-----------------------------------------------------
-- YimActions V3
-----------------------------------------------------
-- Wompus Theater™
---@class YimActions
---@field protected m_initialized boolean
---@field CurrentlyPlaying table<handle, Action>
---@field LastPlayed Action[]
---@field CompanionManager CompanionManager
---@field SceneManager SceneManager
local YimActions   = {}
YimActions.__index = YimActions

---@return YimActions
function YimActions:init()
	if (self.m_initialized) then
		return self
	end

	self.CompanionManager = CompanionManager.new()
	self.SceneManager     = SceneManager
	self.CurrentlyPlaying = {}
	self.LastPlayed       = {}

	Backend:RegisterEventCallbackAll(function()
		self:ForceCleanup()
	end)

	ThreadManager:RegisterLooped("SS_YIMACTIONS", function()
		self:MainThread()
	end)

	self.m_initialized = true
	return self
end

---@param ped? integer
function YimActions:GetPed(ped)
	return ped or Self:GetHandle()
end

---@param ped? integer
function YimActions:AddActionToRecents(ped)
	ped = self:GetPed(ped)
	local current = self.CurrentlyPlaying[ped]

	if (not current) then
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

---@param category ActionCategory
---@param name string
---@return boolean
function YimActions:DoesFavoriteExist(category, name)
	return GVars.features.yim_actions.favorites[category][name] ~= nil
end

---@param category ActionCategory
---@param name string
---@param data ActionData
---@param action_type eActionType
function YimActions:AddToFavorites(category, name, data, action_type)
	if (self:DoesFavoriteExist(category, name)) then
		Notifier:ShowError(
			"Samurai's Scripts",
			"This action is already saved as a favorite!"
		)
		return
	end

	data["type"] = action_type
	GVars.features.yim_actions.favorites[category][name] = data
end

---@param category ActionCategory
---@param name string
function YimActions:RemoveFromFavorites(category, name)
	GVars.features.yim_actions.favorites[category][name] = nil
end

---@return boolean
function YimActions:IsPlayerBusy()
	return CUTSCENE.IS_CUTSCENE_ACTIVE()
		or CUTSCENE.IS_CUTSCENE_PLAYING()
		or NETWORK.NETWORK_IS_IN_MP_CUTSCENE()
		or HUD.IS_MP_TEXT_CHAT_TYPING()
		or Self:IsBrowsingApps()
		or Self:IsInWater()
		or Self:IsRagdoll()
		or script.is_active("maintransition")
		or Backend:IsPlayerSwitchInProgress()
		or Backend:AreControlsDisabled()
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
	if (not current) then
		return false
	end

	if (current.action_type == Enums.eActionType.ANIM) then
		return not ENTITY.IS_ENTITY_PLAYING_ANIM(ped, current.data.dict, current.data.name, 3)
	elseif (current.action_type == Enums.eActionType.SCENARIO) then
		return not PED.IS_PED_USING_ANY_SCENARIO(ped)
	elseif (current.action_type == Enums.eActionType.SCENE) then
		return self.SceneManager:IsPlaying()
	else
		return false
	end
end

---@param animData AnimData
---@param targetPed handle
---@return boolean
function YimActions:InitInVehicleAnim(animData, targetPed)
	if (PED.IS_PED_ON_FOOT(targetPed)) then
		Notifier:ShowError("YimActions", "This action can not be played on foot. Ped must be in a vehicle.", false, 5)
		return false
	end

	local veh = PED.GET_VEHICLE_PED_IS_IN(targetPed, true)
	if (veh == 0) then -- should never happen
		return false
	end

	local seat = Game.GetPedVehicleSeat(targetPed)
	if (not seat or seat > 2) then
		return true
	end

	if (animData.label:find("Race Taunt") and seat == -1) then
		VEHICLE.ROLL_DOWN_WINDOW(veh, 0)
	elseif (animData.label:match("Lean.+%(in%-car%)")) then
		VEHICLE.ROLL_DOWN_WINDOW(veh, seat + 1)
	end

	return true
end

---@param animData AnimData
---@param targetPed? handle
function YimActions:PlayAnim(animData, targetPed)
	targetPed = self:GetPed(targetPed)

	if (animData.category == "In-Vehicle" and not self:InitInVehicleAnim(animData, targetPed)) then
		return
	end

	TaskWait(Game.RequestAnimDict, animData.dict)
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

	if (not GVars.features.yim_actions.disable_props) then
		if (animData.props and #animData.props > 0) then
			YimActions.PropManager:AttachProp(targetPed, animData.props)
		end

		if (animData.propPeds and #animData.propPeds > 0) then
			YimActions.PropManager:AttachProp(targetPed, animData.propPeds, true)
		end
	end

	if (not GVars.features.yim_actions.disable_ptfx and animData.ptfx and animData.ptfx.name) then
		YimActions.FXManager:StartPTFX(targetPed, animData.ptfx)
	end

	local isLooped = Bit.is_set(animData.flags, Enums.eAnimFlags.LOOPING)
	local isFrozen = Bit.is_set(animData.flags, Enums.eAnimFlags.HOLD_LAST_FRAME)

	if (not isLooped and not isFrozen) then
		repeat
			yield()
		until self:IsAnimDone(targetPed, animData)
		self.CurrentlyPlaying[targetPed] = nil
	end
end

---@param scenarioData ScenarioData
---@param targetPed? handle
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
			{ model = 286252949 },
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

---@param data SyncedSceneData
function YimActions:PlaySyncedScene(data)
	self.SceneManager:Play(data)
end

---@param action? Action
---@param ped? handle
function YimActions:Play(action, ped)
	if (not action or not action.data) then
		log.warning("[ERROR]: (YimActions) No action data!")
		return
	end

	ped = self:GetPed(ped)

	if (ped == Self:GetHandle() and self:IsPlayerBusy()) then
		Notifier:ShowMessage(
			"Samurai's Scripts",
			"Player is unavailable at this moment. Clear any other tasks then try again."
		)
		return
	end

	self:Cleanup(ped)
	TaskWait(function() return self.CurrentlyPlaying[ped] == nil end)

	self.CurrentlyPlaying[ped] = action

	if (action.action_type == Enums.eActionType.SCENARIO) then
		---@diagnostic disable-next-line
		self:PlayScenario(action.data, ped)
	elseif action.action_type == Enums.eActionType.ANIM then
		---@diagnostic disable-next-line
		self:PlayAnim(action.data, ped)
	elseif action.action_type == Enums.eActionType.SCENE then
		---@diagnostic disable-next-line
		self:PlaySyncedScene(action.data)
	end

	self:AddActionToRecents(ped)

	if (Backend.debug_mode) then
		self.Debugger:Update(ped)
	end
end

function YimActions:ResetPlayer()
	Self:Cleanup()

	if (not Audio:AreAnyEmittersEnabled()) then
		return
	end

	for _, emitter in pairs(Audio:GetActiveEmitters()) do
		if (emitter:GetOwner() == Self:GetHandle()) then
			Audio:ToggleEmitter(emitter, false)
		end
	end
end

---@param ped? integer
function YimActions:Cleanup(ped)
	ped = self:GetPed(ped)

	if (not self.CurrentlyPlaying[ped]) then
		return
	end

	self.FXManager:StopPTFX(ped)
	self.PropManager:Cleanup(ped)
	self.SceneManager:Wipe()

	if (string.find(self.CurrentlyPlaying[ped].data.label, "DJ")) then
		Audio:PartyMode(false)
	end

	sleep(200)
	TASK.CLEAR_PED_TASKS(ped)

	if (ped == Self:GetHandle()) then
		if (PED.IS_PED_USING_ANY_SCENARIO(ped)) then
			Game.BusySpinnerOn(_T("YAV3_SCN_STOP_SPINNER"), 3)
			repeat
				yield()
			until not PED.IS_PED_USING_ANY_SCENARIO(ped)
			Game.BusySpinnerOff()
		end

		self:ResetPlayer()
	end

	self.CurrentlyPlaying[ped] = nil
	if (Backend.debug_mode) then
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
	Audio:StopAllEmitters()
	Self:ClearTasks()
end

function YimActions:OnInterruptEvent()
	local localPlayer = Self:GetHandle()
	local current = self.CurrentlyPlaying[localPlayer]
	if (not current) then
		yield()
		return
	end

	local isLooped, isFrozen = false, false
	if (current.action_type == Enums.eActionType.ANIM) then
		isLooped = Bit.is_set(current.data.flags, Enums.eAnimFlags.LOOPING)
		isFrozen = Bit.is_set(current.data.flags, Enums.eAnimFlags.HOLD_LAST_FRAME)
	elseif (current.action_type == Enums.eActionType.SCENARIO) then
		isLooped, isFrozen = true, true
	end

	if (not isLooped and not isFrozen) then
		return
	end

	if (not Self:IsAlive() or Self:IsBeingArrested() or Backend:IsPlayerSwitchInProgress() or script.is_active("maintransition")) then
		self:ForceCleanup()
		sleep(1000)
		return
	end

	if (current and self:WasActionInterrupted(localPlayer)) then
		if (Self:IsFalling()) then
			repeat
				sleep(1000)
			until not Self:IsFalling()
			sleep(1000)
		end

		if Self:IsRagdoll() then
			repeat
				sleep(1000)
			until not Self:IsRagdoll()
			sleep(1000)
		end

		if Self:IsSwimming() then
			self:Cleanup(localPlayer)
			sleep(1000)
			return
		end

		self:Play(current, localPlayer)
	end
end

function YimActions:RegisterCommands()
	if (next(GVars.features.yim_actions.action_commands) == nil) then
		return
	end

	local failed = {}
	for label, data in pairs(GVars.features.yim_actions.action_commands) do
		local action = self:FindActionByStrID(data.type, label)
		if (not action) then
			table.insert(failed, data.command)
			goto continue
		end

		CommandExecutor:RegisterCommand(data.command,
			function(_)
				ThreadManager:Run(function()
					self:Play(action)
				end)
			end,
			{ description = _F("YimActions Command: Plays the '%s' %s.", label, action:TypeAsString():lower()) }
		)

		::continue::
	end

	if (#failed > 0) then
		Notifier:ShowError(
			"YimActions",
			"Some commands were not registered (no matching action). Dumping to console..."
		)

		log.fdebug("Failed commands:\n\t%s", table.concat(failed, "\n"))
	end
end

---@param cmd_name string
---@param data { type: eActionType, label: string, is_json?: boolean }
function YimActions:AddCommandAction(cmd_name, data)
	if (not string.isvalid(cmd_name)) then
		Notifier:ShowError("YimActions", "Invalid command name.")
		return
	end

	if (not data or not data.type or data.type == Enums.eActionType.UNK or data.type > Enums.eActionType.SCENARIO) then
		Notifier:ShowError("YimActions", "Invalid action data")
		Backend:debug("command data: %s", table.serialize(data))
		return
	end

	if (GVars.features.yim_actions.action_commands[data.label] or CommandExecutor:DoesCommandExist(cmd_name)) then
		Notifier:ShowError("YimActions", _F("Command '%s' already exists.", data))
		return
	end

	local action = self:FindActionByStrID(data.type, data.label)
	if (not action) then
		Notifier:ShowError("YimActions", _F("Could not match an action to ID: '%s'", data.label))
		return
	end

	GVars.features.yim_actions.action_commands[data.label] = {
		type    = data.type,
		command = cmd_name,
		is_json = false, -- debug flag. unused
	}

	local typename = action:TypeAsString():lower()
	CommandExecutor:RegisterCommand(cmd_name,
		function(_)
			ThreadManager:Run(function()
				self:Play(action)
			end)
		end,
		{ description = _F("YimActions Command: Plays the '%s' %s.", data.label, typename) }
	)

	Notifier:ShowSuccess("YimActions", _F("New %s command successfully registered: '%s'", typename, cmd_name))
end

---@param action_label string
function YimActions:RemoveCommandAction(action_label)
	if (not GVars.features.yim_actions.action_commands[action_label]) then
		return
	end

	local cmd = GVars.features.yim_actions.action_commands[action_label].command
	GVars.features.yim_actions.action_commands[action_label] = nil
	CommandExecutor:RemoveCommand(cmd)
	Notifier:ShowMessage("YimActions", _F("Action command '%s' removed.", cmd))
end

---@param action_type eActionType
---@param id string
---@return Action?
function YimActions:FindActionByStrID(action_type, id)
	---@type AnimData|ScenarioData?
	local lookup_array = Switch(action_type) {
		[Enums.eActionType.ANIM]     = t_AnimList,
		[Enums.eActionType.SCENARIO] = t_PedScenarios,
		default                      = nil
	}

	if (not lookup_array) then
		return nil
	end

	for _, data in ipairs(lookup_array) do
		if (data.label == id) then
			return Action.new(data, action_type)
		end
	end

	return nil
end

function YimActions:DrawPoliceTorchLight()
	local playerProps = YimActions.PropManager.Props[Self:GetHandle()]
	if (not playerProps) then
		return
	end

	local torch = playerProps[1]
	if not (torch and ENTITY.DOES_ENTITY_EXIST(torch) and (Game.GetEntityModel(torch) == 211760048)) then
		return
	end

	local torchPos = Game.GetEntityCoords(torch, false)
	local torchFwd = (Game.GetForwardVector(torch)):inverse(true)
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

function YimActions:GoofyUnaliveAnim()
	local ped = Self:GetHandle()
	if (not ENTITY.IS_ENTITY_PLAYING_ANIM(ped, "mp_suicide", "pistol", 3) or ENTITY.GET_ENTITY_ANIM_CURRENT_TIME(ped, "mp_suicide", "pistol") > 0.299) then
		return
	end

	ThreadManager:Run(function()
		local current  = Self:GetCurrentWeaponHash()
		local is_armed = false
		if (current ~= 0 and WEAPON.GET_WEAPONTYPE_GROUP(current) ~= joaat("GROUP_PISTOL")) then
			is_armed = true
		else
			for _, hash in ipairs(Weapons.Pistols) do
				if (WEAPON.HAS_PED_GOT_WEAPON(ped, hash, false)) then
					WEAPON.SET_CURRENT_PED_WEAPON(ped, hash, true)
					is_armed = true
					break
				end
			end
		end

		PED.SET_PED_CAN_SWITCH_WEAPON(ped, false)

		while (ENTITY.GET_ENTITY_ANIM_CURRENT_TIME(ped, "mp_suicide", "pistol") < 0.299) do
			yield()
		end

		if (is_armed) then
			PED.SET_PED_SHOOTS_AT_COORD(ped, 0.0, 0.0, 0.0, false)
		end

		PED.SET_PED_CAN_SWITCH_WEAPON(ped, true)
	end)
end

function YimActions:HandleCleanupKeybind()
	if (KeyManager:IsKeybindJustPressed("stop_anim")) then
		ThreadManager:Run(function()
			local timer = Timer.new(1000)
			while (KeyManager:IsKeybindPressed("stop_anim")) do
				if (timer:is_done()) then
					GUI:PlaySound(GUI.Sounds.Cancel)
					self:ForceCleanup()
					self:ResetPlayer()
					return
				end

				yield()
			end

			GUI:PlaySound(GUI.Sounds.Button)
			self:Cleanup()
		end)
	end
end

function YimActions:MainThread()
	if (next(self.CurrentlyPlaying) == nil)
		and (next(self.PropManager.Props) == nil)
		and (#self.CompanionManager.Companions == 0) then
		yield()
		return
	end

	self:HandleCleanupKeybind()

	local ped     = Self:GetHandle()
	local current = self.CurrentlyPlaying[ped]
	if (not current) then
		return
	end

	if (current.action_type == Enums.eActionType.ANIM) then
		if (current.data.category == "In-Vehicle" and (Self:IsOnFoot() or PAD.IS_CONTROL_PRESSED(0, 75) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 75))) then
			self:Cleanup()
			return
		end

		if (not GVars.features.yim_actions.disable_ptfx and not GVars.features.yim_actions.disable_props) then
			if (current.data.label and current.data.label:lower():find("police torch")) then
				self:DrawPoliceTorchLight()
			end
		end

		-- this is very stupid but it works... kinda.
		if (ENTITY.IS_ENTITY_PLAYING_ANIM(ped, "mp_suicide", "pistol", 3) and Weapons.Pistols and #Weapons.Pistols > 0) then
			self:GoofyUnaliveAnim()
		end

		if (current.data.sfx and not GVars.features.yim_actions.disable_sfx) then
			self.FXManager:StartSFX()
		end
	end

	self:OnInterruptEvent()
end

-----------------------------------------------------
-- PropManager Subclass
-----------------------------------------------------
-- Handles props.
---@class YimActions.PropManager
YimActions.PropManager = { Props = {} }
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

	if (propData.model == 2767137151 or propData.model == 976772591) then
		Audio:PartyMode(true, owner)
	end

	TaskWait(Game.RequestModel, propData.model)
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
	if (not Game.IsScriptHandle(ped)
			or not ENTITY.DOES_ENTITY_EXIST(ped)
			or not propData
			or (next(propData) == nil)
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
					TaskWait(Game.RequestAnimDict, prop.dict)
					sleep(1000)
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
			Notifier:ShowError(
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
			Game.DeleteEntity(prop)
		end
	end

	Audio:PartyMode(false)
	self.Props[ped] = nil
end

function YimActions.PropManager:Wipe()
	if next(self.Props) == nil then
		return
	end

	for _, propTable in pairs(self.Props) do
		for _, prop in pairs(propTable) do
			Game.DeleteEntity(prop, Enums.eEntityType.Object)
		end
	end

	self.Props = {}
end

-----------------------------------------------------
-- FXManager Subclass
-----------------------------------------------------
-- Handles sound and visual effects.
---@class YimActions.FXManager
---@field SFXTimers table<handle, Timer>
YimActions.FXManager = { Fx = {} }
YimActions.FXManager.__index = YimActions.FXManager
YimActions.FXManager.SFXTimers = {}

function YimActions.FXManager:StartPTFX(parent, ptfxData)
	if (not Game.IsScriptHandle(parent)
			or not ENTITY.DOES_ENTITY_EXIST(parent)
			or not ptfxData
			or not ptfxData.dict
		) then
		return
	end

	TaskWait(Game.RequestNamedPtfxAsset, ptfxData.dict)

	local handle
	if (Game.IsOnline() and parent ~= Self:GetHandle()) then
		Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(parent))
	end

	if (ptfxData.delay) then
		sleep(ptfxData.delay)
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

	if (not timer:is_done()) then
		return
	end

	for _, p in pairs(YimActions.PropManager.Props[ped]) do
		if (ENTITY.IS_ENTITY_A_PED(p) and not AUDIO.IS_AMBIENT_SPEECH_PLAYING(p)) then
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
	if (next(self.Fx) == nil) then
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

	local t_CurrentActor = {
		handle = ped,
		props = YimActions.PropManager.Props[ped],
		ptfx = YimActions.FXManager.Fx[ped],
		sfx = {},
		isLocalPlayer = (ped == Self:GetHandle())
	}

	local actor_exists = false

	if (#self.t_Data.t_Actors == 0) then
		actor_exists = false
	else
		for i = 1, #self.t_Data.t_Actors do
			if (self.t_Data.t_Actors[i] and (self.t_Data.t_Actors[i].handle == ped)) then
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

---@param ped handle
function YimActions.Debugger:Remove(ped)
	for i = 1, #self.t_Data.t_Actors do
		if (self.t_Data.t_Actors[i] and (self.t_Data.t_Actors[i].handle == ped)) then
			self.t_Data.t_Actors[i] = nil
			return
		end
	end
end

---@return number
function YimActions.Debugger:GetActionCount()
	return table.getlen(YimActions.CurrentlyPlaying)
end

---@return number
function YimActions.Debugger:GetPropCount()
	return table.getlen(YimActions.PropManager.Props)
end

---@return number
function YimActions.Debugger:GetFxCount()
	return table.getlen(YimActions.FXManager.Fx)
end

function YimActions.Debugger:Draw()
	if (ImGui.SmallButton("!Summon Wompus")) then
		YimActions.CompanionManager:FulfillTheProphecy()
	end

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
	if (not self.t_Data.t_Actors or #self.t_Data.t_Actors == 0) then
		ImGui.Text("None.")
	else
		ImGui.SetNextItemWidth(200)
		self.i_ActorIndex, _ = ImGui.Combo("##actors", self.i_ActorIndex, actorNames, #self.t_Data.t_Actors)
		local actor = self.t_Data.t_Actors[self.i_ActorIndex + 1]

		if (not actor) then
			return
		end

		local action = YimActions.CurrentlyPlaying[actor.handle]
		ImGui.BulletText(
			string.format(
				"Current Actor: [ %s ]",
				actor.handle == Self:GetHandle() and
				"You" or
				YimActions.CompanionManager:GetCompanionNameFromHandle(actor.handle)
			)
		)
		ImGui.BulletText(("Is Player: [ %s ]"):format(actor.isLocalPlayer))

		if (action) then
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

		if (not actor.props or #actor.props == 0) then
			return
		end

		ImGui.BeginGroup()
		ImGui.BeginChildEx("##debugProplist",
			vec2:new(200, 200),
			ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding
		)
		ImGui.SeparatorText("Props")
		for i = 1, #actor.props do
			local is_selected = (self.i_PropIndex == i - 1)

			if (ImGui.Selectable(tostring(actor.props[i]), is_selected)) then
				self.i_PropIndex = i - 1
			end

			if (GUI:IsItemClicked(GUI.MouseButtons.LEFT)) then
				ThreadManager:Run(function()
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
		if (not self.selectedProp) then
			GUI:Text("Not Selected.", Color("yellow"))
		else
			ImGui.BulletText(("Prop Type: [ %s ]"):format(self.selectedProp.type))
			ImGui.BulletText(("Is Attached: [ %s ]"):format(self.selectedProp.attached))
		end
		ImGui.EndChild()
		ImGui.EndGroup()

		if (GUI:Button("Remove Props")) then
			ThreadManager:Run(function()
				YimActions.PropManager:Cleanup(actor.handle)
			end)
		end

		ImGui.SameLine()

		if (GUI:Button("Stop FX")) then
			ThreadManager:Run(function()
				YimActions.FXManager:StopPTFX(actor.handle)
			end)
		end

		ImGui.SameLine()

		if (GUI:Button("Reset")) then
			ThreadManager:Run(function()
				TASK.CLEAR_PED_TASKS_IMMEDIATELY(actor.handle)
			end)
		end

		if GUI:Button("Wipe") then
			ThreadManager:Run(function()
				YimActions:ForceCleanup()
			end)
		end
	end
end

return YimActions
