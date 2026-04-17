-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local PropManager      = require("PropManager")
local FXManager        = require("FXManager")
local YAV3Debugger     = require("YAV3Debugger")

local SceneManager     = require("includes.services.SceneManager")
local CompanionManager = require("includes.services.CompanionManager")
local Action           = require("includes.structs.Action")
local ActionsHistory   = require("includes.structs.ActionsHistory")
local Weapons          = require("includes.data.weapons")

---@alias ActionCategory
--- | "anims"
--- | "scenarios"
--- | "scenes"
--- | "clipsets"

---@class YimActionsFavorites
---@field anims table<string, AnimData>
---@field scenarios table<string, ScenarioData>
---@field scenes table<string, SyncedSceneData>
---@field clipsets table<string, MovementClipsetData>


-----------------------------------------------------
-- YimActions V3
-----------------------------------------------------
-- Wompus Theater™
---@class YimActions
---@field protected m_initialized boolean
---@field private m_file_names { favorites: "saved_actions.json", commands: "action_commands.json" }
---@field private m_prop_mgr PropManager
---@field private m_fx_mgr FXManager
---@field private m_scene_mgr SceneManager
---@field public Favorites YimActionsFavorites
---@field public Commands table<string, ActionCommandData>
---@field public ShouldDrawCmdWindow boolean
---@field public CurrentlyPlaying table<handle, Action>
---@field public LastPlayed ActionsHistory
---@field public CompanionManager CompanionManager
---@field private Debugger YimActionsDebugger?
local YimActions   = { ShouldDrawCmdWindow = false }
YimActions.__index = YimActions

---@return YimActions
function YimActions:init()
	if (self.m_initialized) then return self end

	local instance            = setmetatable({}, YimActions)
	instance.m_scene_mgr      = SceneManager.new(instance)
	instance.m_prop_mgr       = PropManager.new(instance)
	instance.m_fx_mgr         = FXManager.new(instance)
	instance.CompanionManager = CompanionManager.new(instance)
	instance.LastPlayed       = ActionsHistory.new()
	instance.Debugger         = YAV3Debugger.new(instance)
	instance.CurrentlyPlaying = {}
	instance.Commands         = {}
	instance.Favorites        = {
		anims     = {},
		scenarios = {},
		scenes    = {},
		clipsets  = {},
	}
	instance.m_file_names     = {
		favorites = "saved_actions.json",
		commands  = "action_commands.json",
	}

	instance:ReadSavedFavorites()
	ThreadManager:RegisterLooped("SS_YIMACTIONS", function() instance:OnTick() end)
	Backend:RegisterEventCallbackAll(function() instance:ForceCleanup() end)
	Backend:RegisterFeatureEntityHandler("YimActions", function(handle)
		instance.CompanionManager:RemoveCompanionByHandle(handle)
	end)

	instance.m_initialized = true
	return instance
end

---@param ped? integer
function YimActions:GetPed(ped)
	return ped or LocalPlayer:GetHandle()
end

---@return PropManager
function YimActions:GetPropManager()
	return self.m_prop_mgr
end

---@return FXManager
function YimActions:GetFxManager()
	return self.m_fx_mgr
end

---@private
---@param ped? integer
function YimActions:UpdatePlayHistory(ped)
	local current = self.CurrentlyPlaying[self:GetPed(ped)]
	if (not current) then return end
	self.LastPlayed:Push(current)
end

---@param index integer
function YimActions:RemoveFromHistory(index)
	self.LastPlayed:Pop(index)
end

function YimActions:ClearPlayHistory()
	self.LastPlayed:Clear()
end

---@param mode ActionHistorySortMode?
function YimActions:SortPlayHistory(mode)
	self.LastPlayed:Sort(mode)
end

---@return boolean
function YimActions:IsPlayerBusy()
	return CUTSCENE.IS_CUTSCENE_ACTIVE()
		or CUTSCENE.IS_CUTSCENE_PLAYING()
		or NETWORK.NETWORK_IS_IN_MP_CUTSCENE()
		or HUD.IS_MP_TEXT_CHAT_TYPING()
		or LocalPlayer:IsBrowsingApps()
		or LocalPlayer:IsInWater()
		or LocalPlayer:IsRagdoll()
		or Game.IsInNetworkTransition()
		or Backend:IsPlayerSwitchInProgress()
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
		return self.m_scene_mgr:IsPlaying()
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

---@nodiscard
---@param animData AnimData
---@param targetPed? handle
---@return boolean
function YimActions:PlayAnim(animData, targetPed)
	targetPed = self:GetPed(targetPed)
	if (animData.category == "In-Vehicle" and not self:InitInVehicleAnim(animData, targetPed)) then
		return false
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

	if (not GVars.features.yim_actions.disable_props) then
		if (animData.props and #animData.props > 0) then
			self.m_prop_mgr:AttachProp(targetPed, animData.props)
		end

		if (animData.propPeds and #animData.propPeds > 0) then
			self.m_prop_mgr:AttachProp(targetPed, animData.propPeds, true)
		end
	end

	if (not GVars.features.yim_actions.disable_ptfx and animData.ptfx and animData.ptfx.name) then
		self.m_fx_mgr:StartPTFX(targetPed, animData.ptfx)
	end

	local isLooped = Bit.IsBitSet(animData.flags, Enums.eAnimFlags.LOOPING)
	local isFrozen = Bit.IsBitSet(animData.flags, Enums.eAnimFlags.HOLD_LAST_FRAME)
	if (not isLooped and not isFrozen) then
		ThreadManager:Run(function(s)
			while (not self:IsAnimDone(targetPed, animData)) do
				s:yield()
			end
			self.CurrentlyPlaying[targetPed] = nil
		end)
	end

	return true
end

---@nodiscard
---@param scenarioData ScenarioData
---@param targetPed? handle
---@param playImmediately? boolean
---@return boolean
function YimActions:PlayScenario(scenarioData, targetPed, playImmediately)
	targetPed = self:GetPed(targetPed)
	if (scenarioData.label == "Cook On BBQ") then
		local offsetCoords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
			targetPed,
			0.0,
			1.0,
			0.0
		)
		local bbq = self.m_prop_mgr:SpawnProp(
			targetPed,
			{ model = 286252949 },
			false,
			offsetCoords,
			true,
			true,
			true
		)
		if (bbq and bbq ~= 0) then
			ENTITY.SET_ENTITY_HEADING(bbq, Game.GetHeading(bbq) - 180)
		end
	end

	if (self:IsPedPlaying(targetPed)) then
		TASK.CLEAR_PED_TASKS_IMMEDIATELY(targetPed) -- avoid scenario exit anims if we start a scenario while already playing one
	end

	TASK.TASK_START_SCENARIO_IN_PLACE(
		targetPed,
		scenarioData.scenario,
		-1,
		not playImmediately
	)

	return true
end

---@nodiscard
---@param data SyncedSceneData
---@return boolean
function YimActions:PlaySyncedScene(data)
	self.m_scene_mgr:Play(data)
	return true
end

---@param action? Action
---@param ped? handle
function YimActions:Play(action, ped)
	if (not action or not action.data) then
		log.warning("[ERROR]: (YimActions) No action data!")
		return
	end

	ped = self:GetPed(ped)

	if (ped == LocalPlayer:GetHandle() and self:IsPlayerBusy()) then
		Notifier:ShowMessage("YimActions",
			"Player is unavailable at this moment. Clear any other tasks then try again."
		)
		return
	end

	self:Cleanup(ped)
	TaskWait(function() return self.CurrentlyPlaying[ped] == nil end)

	self.CurrentlyPlaying[ped] = action
	local success = false

	---@diagnostic disable: param-type-mismatch
	if (action.action_type == Enums.eActionType.SCENARIO) then
		success = self:PlayScenario(action.data, ped)
	elseif action.action_type == Enums.eActionType.ANIM then
		success = self:PlayAnim(action.data, ped)
	elseif action.action_type == Enums.eActionType.SCENE then
		success = self:PlaySyncedScene(action.data)
	end
	---@diagnostic enable: param-type-mismatch

	if (success) then
		self:UpdatePlayHistory(ped)
		if (Backend.debug_mode) then
			self.Debugger:Update(ped)
		end
	end
end

function YimActions:ResetPlayer()
	LocalPlayer:Cleanup()

	if (not Audio:AreAnyEmittersEnabled()) then
		return
	end

	for _, emitter in pairs(Audio:GetActiveEmitters()) do
		if (emitter:GetOwner() == LocalPlayer:GetHandle()) then
			Audio:ToggleEmitter(emitter, false)
		end
	end
end

---@param ped? integer
function YimActions:Cleanup(ped)
	ped           = self:GetPed(ped)
	local current = self.CurrentlyPlaying[ped]
	if (not current) then return end

	self.m_fx_mgr:StopPTFX(ped)
	self.m_prop_mgr:Cleanup(ped)
	self.m_scene_mgr:Wipe()

	if (string.find(self.CurrentlyPlaying[ped].data.label, "DJ")) then
		Audio:PartyMode(false, ped)
	end

	sleep(16)
	TASK.CLEAR_PED_TASKS(ped)
	local __type = current.action_type
	if (__type == Enums.eActionType.ANIM or __type == Enums.eActionType.SCENE) then
		STREAMING.REMOVE_ANIM_DICT(current.data.animDict)
	end
	self.CurrentlyPlaying[ped] = nil

	if (ped == LocalPlayer:GetHandle()) then
		if (PED.IS_PED_USING_ANY_SCENARIO(ped)) then
			Game.BusySpinnerOn(_T("YAV3_SCN_STOP_SPINNER"), 3)
			repeat
				yield()
			until not PED.IS_PED_USING_ANY_SCENARIO(ped)
			Game.BusySpinnerOff()
		end

		self:ResetPlayer()
	end

	if (Backend.debug_mode) then
		self.Debugger:Remove(ped)
	end
end

function YimActions:ForceCleanup()
	self.m_fx_mgr:Wipe()
	self.m_prop_mgr:Wipe()
	self.m_scene_mgr:Wipe()
	self.CompanionManager:Wipe()
	self:ResetPlayer()
	Audio:StopAllEmitters()
	LocalPlayer:ClearTasks()
	self.CurrentlyPlaying = {}
end

function YimActions:OnInterruptEvent()
	local playerHandle = LocalPlayer:GetHandle()
	local current      = self.CurrentlyPlaying[playerHandle]
	if (not current) then
		yield()
		return
	end

	local isLooped, isFrozen = false, false
	if (current.action_type == Enums.eActionType.ANIM) then
		isLooped = Bit.IsBitSet(current.data.flags, Enums.eAnimFlags.LOOPING)
		isFrozen = Bit.IsBitSet(current.data.flags, Enums.eAnimFlags.HOLD_LAST_FRAME)
	elseif (current.action_type == Enums.eActionType.SCENARIO) then
		isLooped, isFrozen = true, true
	end

	if (not isLooped and not isFrozen) then
		return
	end

	if (not LocalPlayer:IsAlive() or LocalPlayer:IsBeingArrested() or Backend:IsPlayerSwitchInProgress() or Game.IsInNetworkTransition()) then
		self:ForceCleanup()
		yield()
		return
	end

	if (current and self:WasActionInterrupted(playerHandle)) then
		if (LocalPlayer:IsFalling()) then
			repeat
				yield()
			until not LocalPlayer:IsFalling()
			sleep(1000)
		end

		if (LocalPlayer:IsRagdoll()) then
			repeat
				yield()
			until not LocalPlayer:IsRagdoll()
			sleep(1000)
		end

		if (LocalPlayer:IsSwimming()) then
			self:Cleanup(playerHandle)
			sleep(1000)
			return
		end

		self:Play(current, playerHandle)
	end
end

function YimActions:ParseFavorites()
	Serializer:WriteToFile(self.m_file_names.favorites, self.Favorites)
end

function YimActions:ParseCommands()
	Serializer:WriteToFile(self.m_file_names.commands, self.Commands)
end

function YimActions:ReadSavedFavorites()
	if (not io.exists(self.m_file_names.favorites)) then
		-- This exists because my dumbass keeps drastically changing
		-- the config. To avoid pissing off users who have saved favorites,
		-- this is the price: a few more micro seconds on load.
		-- This will be removed after one or two more releases.

		---@type YimActionsFavorites?
		local existing = GVars.features.yim_actions.favorites
		if (existing) then
			for k, v in pairs(existing) do
				if (next(v) ~= nil) then
					self.Favorites[k] = table.copy(v)
				end
			end

			GVars.features.yim_actions.favorites = nil
		end

		self:ParseFavorites()
		return
	end

	---@type YimActionsFavorites?
	local data = Serializer:ReadFromFile(self.m_file_names.favorites)
	if (type(data) ~= "table" or not data.anims) then
		return
	end

	self.Favorites = data
end

---@param category ActionCategory
---@param name string
---@return boolean
function YimActions:DoesFavoriteExist(category, name)
	return self.Favorites[category][name] ~= nil
end

---@param category ActionCategory
---@param name string
---@param data ActionData
---@param action_type eActionType
function YimActions:AddToFavorites(category, name, data, action_type)
	if (self:DoesFavoriteExist(category, name)) then
		Notifier:ShowError("YimActions", "This action is already saved as a favorite!")
		return
	end

	---@type table<string, ActionData>?
	local cat = self.Favorites[category]
	if (type(cat) ~= "table") then
		Notifier:ShowError("YimActions", "Unknown action category!")
		return
	end

	data["type"] = action_type
	cat[name] = data
	self:ParseFavorites()
end

---@param category ActionCategory
---@param name string
function YimActions:RemoveFromFavorites(category, name)
	---@type table<string, ActionData>?
	local cat = self.Favorites[category]
	if (type(cat) ~= "table") then
		return
	end

	cat[name] = nil
	self:ParseFavorites()
end

function YimActions:ReadSavedCommands()
	---@type table<string, ActionCommandData>?
	local data = Serializer:ReadFromFile(self.m_file_names.commands)
	if (type(data) ~= "table") then
		Serializer:WriteToFile(self.m_file_names.commands, {})
		return
	end

	self.Commands = data
	self:ParseCommands()
end

function YimActions:RegisterCommands()
	self:ReadSavedCommands()
	if (next(self.Commands) == nil) then return end

	local failed = {}
	for label, data in pairs(self.Commands) do
		local action = self:FindActionByStrID(data.type, label)
		if (not action) then
			table.insert(failed, data.command)
			goto continue
		end

		CommandExecutor:RegisterCommand(data.command,
			function(_)
				ThreadManager:Run(function() self:Play(action) end)
			end,
			{ description = _F("YimActions Command: Plays the '%s' %s.", label, action:TypeAsString():lower()) }
		)

		::continue::
	end

	if (#failed > 0) then
		Notifier:ShowError("YimActions",
			"Some commands were not registered (no matching action). Dumping to console..."
		)

		Backend:debug("Failed commands:\n\t%s", table.concat(failed, "\n"))
	end
end

---@param cmd_name string
---@param data { type: eActionType, label: string, is_json?: boolean }
function YimActions:AddCommandAction(cmd_name, data)
	if (not string.isvalid(cmd_name)) then
		Notifier:ShowError("YimActions", "Invalid command name.")
		return
	end

	if (not data or not data.type or (data.type == Enums.eActionType.UNK) or (data.type > Enums.eActionType.SCENARIO)) then
		Notifier:ShowError("YimActions", "Invalid action data")
		Backend:debug("command data: %s", table.serialize(data))
		return
	end

	if (self.Commands[data.label] or CommandExecutor:DoesCommandExist(cmd_name)) then
		Notifier:ShowError("YimActions", _F("Command '%s' already exists.", data))
		return
	end

	local action = self:FindActionByStrID(data.type, data.label)
	if (not action) then
		Notifier:ShowError("YimActions", _F("Could not find action by name: '%s'", data.label))
		return
	end

	self.Commands[data.label] = {
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

	self:ParseCommands()
	Notifier:ShowSuccess("YimActions", _F("New %s command successfully registered: '%s'", typename, cmd_name))
end

---@param action_label string
function YimActions:RemoveCommandAction(action_label)
	if (not self.Commands[action_label]) then
		return
	end

	local command_name          = self.Commands[action_label].command
	self.Commands[action_label] = nil
	self:ParseCommands()
	CommandExecutor:RemoveCommand(command_name)
	Notifier:ShowMessage("YimActions", _F("Action command '%s' has been removed.", command_name))
end

---@param action_type eActionType
---@param str_id string
---@return Action?
function YimActions:FindActionByStrID(action_type, str_id)
	---@type array<AnimData|ScenarioData>?
	local lookup_array = Switch(action_type) {
		[Enums.eActionType.ANIM]     = require("includes.data.actions.animations"),
		[Enums.eActionType.SCENARIO] = require("includes.data.actions.scenarios"),
		default                      = nil
	}

	if (not lookup_array) then return nil end

	for _, data in ipairs(lookup_array) do
		if (data.label == str_id) then
			return Action.new(data, action_type)
		end
	end

	return nil
end

function YimActions:DrawPoliceTorchLight()
	local playerProps = self.m_prop_mgr:GetPropsForPed(LocalPlayer:GetHandle())
	if (not playerProps) then return end

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
	local ped = LocalPlayer:GetHandle()
	if (not ENTITY.IS_ENTITY_PLAYING_ANIM(ped, "mp_suicide", "pistol", 3) or ENTITY.GET_ENTITY_ANIM_CURRENT_TIME(ped, "mp_suicide", "pistol") > 0.299) then
		return
	end

	ThreadManager:Run(function()
		local current  = LocalPlayer:GetCurrentWeaponHash()
		local is_armed = false
		if (current ~= 0 and WEAPON.GET_WEAPONTYPE_GROUP(current) ~= _J("GROUP_PISTOL")) then
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

function YimActions:OnKeyDown()
	if (Backend:AreControlsDisabled()) then
		return
	end

	if (KeyManager:IsKeybindJustPressed("stop_anim")) then
		ThreadManager:Run(function()
			local timer = Timer.new(1000)
			while (KeyManager:IsKeybindPressed("stop_anim")) do
				if (timer:IsDone()) then
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

function YimActions:OnTick()
	if (next(self.CurrentlyPlaying) == nil)
		and (next(self.m_prop_mgr:GetProps()) == nil)
		and (#self.CompanionManager.Companions == 0) then
		yield()
		return
	end

	self:OnKeyDown()

	local ped     = LocalPlayer:GetHandle()
	local current = self.CurrentlyPlaying[ped]
	if (not current) then return end

	if (current.action_type == Enums.eActionType.ANIM) then
		if (current.data.category == "In-Vehicle" and (LocalPlayer:IsOnFoot() or PAD.IS_CONTROL_PRESSED(0, 75) or PAD.IS_DISABLED_CONTROL_PRESSED(0, 75))) then
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
			self.m_fx_mgr:StartSFX()
		end
	end

	self:OnInterruptEvent()
end

return YimActions:init() -- single instance
