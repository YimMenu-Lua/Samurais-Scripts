-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local ped_list <const>     = require("includes.data.peds")
local ped_hashmap <const>  = require("includes.data.ped_hashmap")
local veh_hashmap <const>  = require("includes.data.vehicle_hashmap")
local weapon_data <const>  = require("includes.data.weapon_data")
local vehicle_data <const> = require("includes.data.vehicles")
local Refs                 = require("includes.data.refs")
local SP_CharIDs <const>   = {
	[225514697]  = 0,
	[2602752943] = 1,
	[2608926626] = 2,
}
local SP_CharNames <const> = {
	"Michael",
	"Franklin",
	"Trevor",
}


--------------------------------------
-- Class: Game
--------------------------------------
-- **Global Singleton.**
--
-- Native wrappers and generic helpers.
---@class Game
Game         = {}
Game.__index = Game

---@return VersionInfo
function Game.GetVersion()
	return Memory:GetGameVersion()
end

---@return vec2
function Game.GetScreenResolution()
	return Memory:GetScreenResolution() or vec2:zero()
end

---@return string, string
function Game.GetLanguage()
	local lang_iso = "en-US"
	local lang_name = "English"
	local i_LangID = LOCALIZATION.GET_CURRENT_LANGUAGE()

	for _, _lang in ipairs(Refs.locales) do
		if i_LangID == _lang.id then
			lang_iso = _lang.iso
			lang_name = _lang.name
			break
		end
	end

	if lang_iso == "es-MX" then
		lang_iso = "es-ES"
	end

	return lang_iso, lang_name
end

---@return float
function Game.GetFrameCount()
	return MISC.GET_FRAME_COUNT()
end

---@return float
function Game.GetFrameTime()
	return MISC.GET_FRAME_TIME()
end

---@return float
function Game.GetGameTimer()
	return MISC.GET_GAME_TIMER()
end

---@return integer | nil, string | nil
function Game.GetKeyPressed()
	if PAD.IS_USING_KEYBOARD_AND_MOUSE(0) then
		return nil, nil
	end

	for _, v in ipairs(Refs.gamepadControls) do
		if PAD.IS_CONTROL_JUST_PRESSED(0, v.ctrl) or PAD.IS_DISABLED_CONTROL_JUST_PRESSED(0, v.ctrl) then
			return v.ctrl, v.gpad
		end
	end
end

---@return boolean
function Game.IsLegacy()
	return Backend:GetAPIVersion() == Enums.eAPIVersion.V1
end

---@return boolean
function Game.IsEnhanced()
	return Backend:GetAPIVersion() == Enums.eAPIVersion.V2
end

---@return boolean
function Game.IsOnline()
	return network.is_session_started() and not script.is_active("maintransition")
end

---@param handle integer
---@return boolean
function Game.IsScriptHandle(handle)
	if not handle or type(handle) ~= "number" then
		return false
	end

	return ENTITY.DOES_ENTITY_EXIST(handle)
end

---@param value integer | string
---@return boolean
function Game.IsModelHash(value)
	if type(value) == "string" then
		value = joaat(value)
	end

	return type(value) == "number" and value >= 0xFFFF and STREAMING.IS_MODEL_VALID(value)
end

---@param input any
---@return integer
function Game.EnsureModelHash(input)
	if not input then
		return 0
	end

	if Game.IsModelHash(input) then
		if type(input) == "string" then
			return joaat(input)
		else
			return input
		end
	end

	if Game.IsScriptHandle(input) then
		return Game.GetEntityModel(input)
	end

	return 0
end

---@param arg (integer|vec3)?
---@return vec3?
function Game.Ensure3DCoords(arg)
	if (IsInstance(arg, vec3)) then
		---@type vec3
		return arg
	end

	if (type(arg) == "number") then
		if (Game.IsScriptHandle(arg)) then
			return Game.GetEntityCoords(arg, false)
		end

		local blip = HUD.GET_FIRST_BLIP_INFO_ID(arg)
		if (HUD.DOES_BLIP_EXIST(blip)) then
			return HUD.GET_BLIP_COORDS(blip)
		end
	end

	return nil
end

---@param model_hash integer
---@param spawn_pos vec3
---@param heading? integer
---@param is_networked? boolean
---@param is_sripthost_ped? boolean
function Game.CreatePed(model_hash, spawn_pos, heading, is_networked, is_sripthost_ped)
	if not Backend:CanCreateEntity(Enums.eEntityType.Ped) then
		if not GVars.backend.auto_cleanup_entities then
			Notifier:ShowError(
				"Samurai's Scripts",
				_T("WARN_PED_SPAWN_LIMIT"),
				true,
				5
			)
			return 0
		end

		local oldest = table.remove(Backend.SpawnedEntities[Enums.eEntityType.Ped], 1)
		Game.DeleteEntity(oldest, Enums.eEntityType.Ped)
	end

	TaskWait(Game.RequestModel, model_hash)
	local i_Handle = PED.CREATE_PED(
		Game.GetPedTypeFromModel(model_hash),
		model_hash,
		spawn_pos.x,
		spawn_pos.y,
		spawn_pos.z,
		heading or math.random(1, 180),
		is_networked or false,
		is_sripthost_ped or false
	)

	Backend:RegisterEntity(i_Handle, Enums.eEntityType.Ped)
	return i_Handle
end

---@param model_hash integer
---@param spawn_pos vec3
---@param heading? integer
---@param is_networked? boolean
---@param is_scripthost_veh? boolean
function Game.CreateVehicle(model_hash, spawn_pos, heading, is_networked, is_scripthost_veh)
	if not Backend:CanCreateEntity(Enums.eEntityType.Vehicle) then
		if not GVars.backend.auto_cleanup_entities then
			Notifier:ShowError(
				"Samurai's Scripts",
				_T("WARN_VEH_SPAWN_LIMIT"),
				true,
				5
			)
			return 0
		end

		local oldest = table.remove(Backend.SpawnedEntities[Enums.eEntityType.Vehicle], 1)
		Game.DeleteEntity(oldest, Enums.eEntityType.Vehicle)
	end

	TaskWait(Game.RequestModel, model_hash)
	local i_Handle = VEHICLE.CREATE_VEHICLE(
		model_hash,
		spawn_pos.x,
		spawn_pos.y,
		spawn_pos.z,
		heading or math.random(1, 180),
		is_networked or false,
		is_scripthost_veh or false,
		false
	)

	VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(i_Handle, 5.0)
	VEHICLE.SET_VEHICLE_IS_STOLEN(i_Handle, false)

	if Game.IsOnline() then
		DECORATOR.DECOR_SET_INT(i_Handle, "MPBitset", 0)
	end
	Backend:RegisterEntity(i_Handle, Enums.eEntityType.Vehicle)

	return i_Handle
end

---@param model_hash integer
---@param spawn_pos vec3
---@param is_networked? boolean
---@param is_scripthost_obj? boolean
---@param is_dynamic? boolean
---@param should_place_on_ground? boolean
---@param heading? integer
function Game.CreateObject(model_hash, spawn_pos, is_networked, is_scripthost_obj, is_dynamic, should_place_on_ground,
						   heading)
	if not Backend:CanCreateEntity(Enums.eEntityType.Object) then
		if not GVars.backend.auto_cleanup_entities then
			Notifier:ShowError(
				"Samurai's Scripts",
				_T("WARN_OBJ_SPAWN_LIMIT"),
				true,
				5
			)
			return 0
		end

		local oldest = table.remove(Backend.SpawnedEntities[Enums.eEntityType.Object], 1)
		Game.DeleteEntity(oldest, Enums.eEntityType.Object)
	end

	TaskWait(Game.RequestModel, model_hash)
	local i_Handle = OBJECT.CREATE_OBJECT(
		model_hash,
		spawn_pos.x,
		spawn_pos.y,
		spawn_pos.z,
		is_networked or false,
		is_scripthost_obj or false,
		(is_dynamic ~= nil) and is_dynamic or true
	)

	if should_place_on_ground then
		OBJECT.PLACE_OBJECT_ON_GROUND_OR_OBJECT_PROPERLY(i_Handle)
	end

	if heading then
		ENTITY.SET_ENTITY_HEADING(i_Handle, heading)
	end
	Backend:RegisterEntity(i_Handle, Enums.eEntityType.Object)

	return i_Handle
end

function Game.RemovePedFromGroup(ped)
	local groupID = PED.GET_PED_GROUP_INDEX(LocalPlayer:GetHandle())
	if PED.DOES_GROUP_EXIST(groupID) and PED.IS_PED_GROUP_MEMBER(ped, groupID) then
		PED.REMOVE_PED_FROM_GROUP(ped)
	end
end

---@param entity integer
---@param entity_type? eEntityType
function Game.DeleteEntity(entity, entity_type)
	ThreadManager:Run(function()
		entity_type = entity_type or Game.GetEntityType(entity)
		if (not Game.IsScriptHandle(entity) or entity == LocalPlayer:GetHandle()) then
			return
		end

		if ENTITY.IS_ENTITY_A_PED(entity) then
			Game.RemovePedFromGroup(entity)
		end

		if Backend:IsBlipRegistered(entity) then
			Game.RemoveBlipFromEntity(entity)
		end

		STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(Game.GetEntityModel(entity))
		ENTITY.DELETE_ENTITY(entity)
		sleep(50)

		if ENTITY.DOES_ENTITY_EXIST(entity) then
			ENTITY.SET_ENTITY_AS_MISSION_ENTITY(entity, true, true)
			ENTITY.DELETE_ENTITY(entity)
			sleep(50)

			if (ENTITY.DOES_ENTITY_EXIST(entity) and Game.IsOnline()) then
				TaskWait(entities.take_control_of, { entity, 300 }, 500)
				ENTITY.DELETE_ENTITY(entity)
			end
			sleep(50)

			if ENTITY.DOES_ENTITY_EXIST(entity) then
				Notifier:ShowError(
					"Samurai's Scripts",
					_F("Failed to delete entity: [%d]", entity)
				)
				return
			end
		end

		Backend:RemoveEntity(entity, entity_type)
	end)
end

---@param text string
---@param spinner_type integer
function Game.BusySpinnerOn(text, spinner_type)
	HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("STRING")
	HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
	HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(spinner_type)
end

function Game.BusySpinnerOff()
	HUD.BUSYSPINNER_OFF()
end

---@param text string
function Game.ShowButtonPrompt(text)
	if not HUD.IS_HELP_MESSAGE_ON_SCREEN() then
		HUD.BEGIN_TEXT_COMMAND_DISPLAY_HELP("STRING")
		HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
		HUD.END_TEXT_COMMAND_DISPLAY_HELP(0, false, true, -1)
	end
end

---@param position vec2
---@param width float
---@param height float
---@param fgCol Color
---@param bgCol Color
---@param value number
function Game.DrawProgressBar(position, width, height, fgCol, bgCol, value)
	local bgPaddingX = 0.005
	local bgPaddingY = 0.01
	local fg = {}
	local bg = {}

	fg.r, fg.g, fg.b, fg.a = fgCol:AsRGBA()
	bg.r, bg.g, bg.b, bg.a = bgCol:AsRGBA()

	-- background
	GRAPHICS.DRAW_RECT(
		position.x,
		position.y,
		width + bgPaddingX,
		height + bgPaddingY,
		bg.r,
		bg.g,
		bg.b,
		bg.a,
		false
	)

	-- foreground
	GRAPHICS.DRAW_RECT(
		position.x - width * 0.5 + value * width * 0.5,
		position.y, width * value,
		height,
		fg.r,
		fg.g,
		fg.b,
		fg.a,
		false
	)
end

---@param position vec2
---@param text string
---@param color Color | table
---@param scale vec2 | table
---@param font number
---@param center? boolean
function Game.DrawText(position, text, color, scale, font, center)
	local r, g, b, a = color:AsRGBA()
	HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
	HUD.SET_TEXT_COLOUR(r, g, b, a)
	HUD.SET_TEXT_SCALE(scale.x, scale.y)
	HUD.SET_TEXT_OUTLINE()
	HUD.SET_TEXT_FONT(font)

	if center then
		HUD.SET_TEXT_CENTRE(true)
	else
		HUD.SET_TEXT_JUSTIFICATION(1)
	end

	HUD.SET_TEXT_DROP_SHADOW()
	HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
	HUD.END_TEXT_COMMAND_DISPLAY_TEXT(position.x, position.y, 0)
end

---@param entity number
---@param scale? float
---@param isFriendly? boolean
---@param showHeading? boolean
---@param name? string
---@param alpha? number
function Game.AddBlipForEntity(entity, scale, isFriendly, showHeading, name, alpha)
	local blip = HUD.ADD_BLIP_FOR_ENTITY(entity)

	if not blip or not HUD.DOES_BLIP_EXIST(blip) then
		return 0
	end

	HUD.SET_BLIP_SCALE(blip, scale or 1.0)
	HUD.SET_BLIP_AS_FRIENDLY(blip, isFriendly or false)
	HUD.SHOW_HEADING_INDICATOR_ON_BLIP(blip, showHeading or false)

	if name then
		Game.SetBlipName(blip, name)
	end

	if alpha then
		HUD.SET_BLIP_ALPHA(blip, alpha)
	end

	Backend:RegisterBlip(blip, entity, alpha)
	return blip
end

---@param handle integer
function Game.RemoveBlipFromEntity(handle)
	local blip = Backend.CreatedBlips[handle]

	if not blip or not HUD.DOES_BLIP_EXIST(blip.handle) then
		return
	end

	HUD.REMOVE_BLIP(blip.handle)
	Backend:RemoveBlip(handle)
end

-- Blip Sprites: https://wiki.rage.mp/index.php?title=Blips
---@param blip number
---@param icon number
function Game.SetBlipSprite(blip, icon)
	if not blip or not HUD.DOES_BLIP_EXIST(blip) then
		return
	end

	HUD.SET_BLIP_SPRITE(blip, icon)
end

-- Sets a custom name for a blip. Custom names appear on the pause menu and the world map.
---@param blip integer
---@param name string
function Game.SetBlipName(blip, name)
	if not blip or not HUD.DOES_BLIP_EXIST(blip) then
		return
	end

	HUD.BEGIN_TEXT_COMMAND_SET_BLIP_NAME("STRING")
	HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(name)
	HUD.END_TEXT_COMMAND_SET_BLIP_NAME(blip)
end

---@param entity handle
---@param heading float
function Game.SetEntityHeading(entity, heading)
	if not Game.IsScriptHandle(entity) then
		return
	end

	ENTITY.SET_ENTITY_HEADING(entity, heading)
end

---@param handle integer
---@param coords vec3
---@param x_axis? boolean
---@param y_axis? boolean
---@param z_axis? boolean
---@param should_clear_area? boolean
function Game.SetEntityCoords(handle, coords, x_axis, y_axis, z_axis, should_clear_area)
	ThreadManager:Run(function()
		ENTITY.SET_ENTITY_COORDS(
			handle,
			coords.x,
			coords.y,
			coords.z,
			x_axis or false,
			y_axis or false,
			z_axis or false,
			should_clear_area or false
		)
	end)
end

---@param handle integer
---@param coords vec3
---@param x_axis? boolean
---@param y_axis? boolean
---@param z_axis? boolean
function Game.SetEntityCoordsNoOffset(handle, coords, x_axis, y_axis, z_axis)
	ThreadManager:Run(function()
		ENTITY.SET_ENTITY_COORDS_NO_OFFSET(
			handle,
			coords.x,
			coords.y,
			coords.z,
			x_axis or false,
			y_axis or false,
			z_axis or false
		)
	end)
end

---@param model integer
---@return boolean
function Game.RequestModel(model)
	if STREAMING.IS_MODEL_VALID(model) and STREAMING.IS_MODEL_IN_CDIMAGE(model) then
		STREAMING.REQUEST_MODEL(model)
		return STREAMING.HAS_MODEL_LOADED(model)
	end
	return false
end

---@param dict string
---@return boolean
function Game.RequestNamedPtfxAsset(dict)
	STREAMING.REQUEST_NAMED_PTFX_ASSET(dict)
	return STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(dict)
end

---@param clipset string
---@return boolean
function Game.RequestClipSet(clipset)
	STREAMING.REQUEST_CLIP_SET(clipset)
	return STREAMING.HAS_CLIP_SET_LOADED(clipset)
end

---@param dict string
---@return boolean
function Game.RequestAnimDict(dict)
	STREAMING.REQUEST_ANIM_DICT(dict)
	return STREAMING.HAS_ANIM_DICT_LOADED(dict)
end

---@param dict string
---@return boolean
function Game.RequestTextureDict(dict)
	GRAPHICS.REQUEST_STREAMED_TEXTURE_DICT(dict, false)
	return GRAPHICS.HAS_STREAMED_TEXTURE_DICT_LOADED(dict)
end

---@param weapon integer
---@return boolean
function Game.RequestWeaponAsset(weapon)
	WEAPON.REQUEST_WEAPON_ASSET(weapon, 31, 0)
	return WEAPON.HAS_WEAPON_ASSET_LOADED(weapon)
end

---@param scr string
---@return boolean
function Game.RequestScript(scr)
	SCRIPT.REQUEST_SCRIPT(scr)
	return SCRIPT.HAS_SCRIPT_LOADED(scr)
end

---@param entity integer
---@param is_alive boolean
---@return vec3
function Game.GetEntityCoords(entity, is_alive)
	return ENTITY.GET_ENTITY_COORDS(entity, is_alive)
end

---@param entity integer
---@param order? integer
---@return vec3
function Game.GetEntityRotation(entity, order)
	return ENTITY.GET_ENTITY_ROTATION(entity, order or 2)
end

---@param entity integer
---@return number
function Game.GetHeading(entity)
	return ENTITY.GET_ENTITY_HEADING(entity)
end

---@param entity integer
---@return number
function Game.GetForwardX(entity)
	return ENTITY.GET_ENTITY_FORWARD_X(entity)
end

---@param entity integer
---@return number
function Game.GetForwardY(entity)
	return ENTITY.GET_ENTITY_FORWARD_Y(entity)
end

---@param entity integer
---@return vec3
function Game.GetForwardVector(entity)
	return ENTITY.GET_ENTITY_FORWARD_VECTOR(entity)
end

---@param ped integer
---@param boneID integer
---@return integer
function Game.GetPedBoneIndex(ped, boneID)
	return PED.GET_PED_BONE_INDEX(ped, boneID)
end

---@param ped integer
---@param boneID integer
---@return vec3
function Game.GetPedBoneCoords(ped, boneID)
	return PED.GET_PED_BONE_COORDS(ped, boneID, 0, 0, 0)
end

---@param entity integer
---@param boneName string
---@return integer
function Game.GetEntityBoneIndexByName(entity, boneName)
	return ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(entity, boneName)
end

---@param entity integer
---@param bone number | string
---@return vec3
function Game.GetWorldPositionOfEntityBone(entity, bone)
	local boneIndex

	if type(bone) == "string" then
		boneIndex = Game.GetEntityBoneIndexByName(entity, bone)
	else
		boneIndex = bone
	end

	return ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(entity, boneIndex)
end

---@param entity integer
---@param bone integer | string
---@return vec3
function Game.GetEntityBonePos(entity, bone)
	if type(bone) == "string" then
		bone = Game.GetEntityBoneIndexByName(entity, bone)
	end

	return ENTITY.GET_ENTITY_BONE_POSTION(entity, bone)
end

---@param entity integer
---@param bone integer | string
---@return vec3
function Game.GetEntityBoneRot(entity, bone)
	if type(bone) == "string" then
		bone = Game.GetEntityBoneIndexByName(entity, bone)
	end

	return ENTITY.GET_ENTITY_BONE_ROTATION(entity, bone)
end

---@param entity integer
---@return integer
function Game.GetEntityBoneCount(entity)
	return ENTITY.GET_ENTITY_BONE_COUNT(entity)
end

-- Returns the entity localPlayer is aiming at.
---@param player integer
---@return integer | nil
function Game.GetEntityPlayerIsFreeAimingAt(player)
	local bIsAiming, Entity = false, 0

	if PLAYER.IS_PLAYER_FREE_AIMING(player) then
		bIsAiming, Entity = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(self.get_id(), Entity)
	end

	return bIsAiming and Entity or nil
end

---@param entity handle
---@return integer
function Game.GetEntityModel(entity)
	return ENTITY.GET_ENTITY_MODEL(entity)
end

---@param entity handle
---@return eEntityType
function Game.GetEntityType(entity)
	return ENTITY.GET_ENTITY_TYPE(entity)
end

---@param entity handle
---@return string
function Game.GetEntityTypeString(entity)
	return EnumToString(Enums.eEntityType, Game.GetEntityType(entity)) or "Unknown"
end

---@param model joaat_t
---@return vec3, vec3
function Game.GetModelDimensions(model)
	local vmin, vmax = vec3:zero(), vec3:zero()
	if (STREAMING.IS_MODEL_VALID(model)) then
		vmin, vmax = MISC.GET_MODEL_DIMENSIONS(model, vmin, vmax)
	end

	return vmin, vmax
end

-- Returns a number for the vehicle seat the provided ped
--
-- is sitting in (-1 driver, 0 front passenger, etc...).
---@param ped handle
---@return integer | nil
function Game.GetPedVehicleSeat(ped)
	if not PED.IS_PED_SITTING_IN_ANY_VEHICLE(ped) then
		return
	end

	local vehicle  = PED.GET_VEHICLE_PED_IS_IN(ped, false)
	local maxSeats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(vehicle))

	for i = -1, maxSeats do
		if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, i, true) then
			if VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, i, true) == ped then
				return i
			end
		end
	end
end

---@param netID integer
function Game.SyncNetworkID(netID)
	if not Game.IsOnline() or not NETWORK.NETWORK_DOES_NETWORK_ID_EXIST(netID) then
		return false
	end

	local timer = Timer.new(250)
	NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netID)
	while not NETWORK.NETWORK_HAS_CONTROL_OF_NETWORK_ID(netID) and not timer:is_done() do
		NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netID)
		yield()
	end

	NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netID, true)
	NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(netID, true)

	return NETWORK.NETWORK_HAS_CONTROL_OF_NETWORK_ID(netID)
end

function Game.DesyncNetworkID(netID)
	if not Game.IsOnline() or not NETWORK.NETWORK_DOES_NETWORK_ID_EXIST(netID) then
		return
	end

	local timer = Timer.new(250)
	NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netID)
	while not NETWORK.NETWORK_HAS_CONTROL_OF_NETWORK_ID(netID) and timer:is_done() do
		NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(netID)
		yield()
	end

	NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netID, false)
	NETWORK.SET_NETWORK_ID_CAN_BE_REASSIGNED(netID, false)
	NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(netID, false)

	return NETWORK.NETWORK_HAS_CONTROL_OF_NETWORK_ID(netID)
end

---@param i_EntityHandle integer
---@param s_PtfxDict string
---@param s_PtfxName string
---@param bone string | integer | table
---@param f_Scale integer
---@param v_Pos vec3
---@param v_Rot vec3
---@param color? Color
---@return table | nil
function Game.StartSyncedPtfxLoopedOnEntityBone(i_EntityHandle, s_PtfxDict, s_PtfxName, bone, f_Scale, v_Pos, v_Rot,
												color)
	if not i_EntityHandle or not ENTITY.DOES_ENTITY_EXIST(i_EntityHandle) then
		return
	end

	local effects = {}

	TaskWait(Game.RequestNamedPtfxAsset, s_PtfxDict)
	local r, g, b, a = color and color:AsRGBA() or 0, 0, 0, 255
	local boneList = {}
	local isRightBone = false

	if Game.IsOnline() and (i_EntityHandle ~= LocalPlayer:GetHandle()) and entities.take_control_of(i_EntityHandle, 300) then
		Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(i_EntityHandle))
	end

	if type(bone) == "table" then
		boneList = bone
	else
		boneList = { bone }
	end

	for _, boneIndex in ipairs(boneList) do
		if type(boneIndex) == "string" then
			isRightBone = (string.find(boneIndex, "_rf") ~= nil) or (string.find(boneIndex, "_rr") ~= nil)
			boneIndex = Game.GetEntityBoneIndexByName(i_EntityHandle, boneIndex)
		end

		if boneIndex ~= -1 then
			GRAPHICS.USE_PARTICLE_FX_ASSET(s_PtfxDict)
			local fxHandle = GRAPHICS.START_NETWORKED_PARTICLE_FX_LOOPED_ON_ENTITY_BONE(
				s_PtfxName,
				i_EntityHandle,
				isRightBone and -v_Pos.x or v_Pos.x,
				v_Pos.y,
				v_Pos.z,
				v_Rot.x,
				v_Rot.y,
				v_Rot.z,
				boneIndex,
				f_Scale,
				false,
				false,
				false,
				r,
				g,
				b,
				a
			)

			table.insert(effects, fxHandle)
			yield()
		end
	end

	return effects
end

---@param i_EntityHandle integer
---@param s_PtfxDict string
---@param s_PtfxName string
---@param bone string | integer | table
---@param v_Pos vec3
---@param v_Rot vec3
---@param f_Scale integer
function Game.StartSyncedPtfxNonLoopedOnEntityBone(i_EntityHandle, s_PtfxDict, s_PtfxName, bone, v_Pos, v_Rot, f_Scale)
	if not i_EntityHandle or not ENTITY.DOES_ENTITY_EXIST(i_EntityHandle) then
		return
	end

	TaskWait(Game.RequestNamedPtfxAsset, s_PtfxDict)

	local boneList = {}

	if Game.IsOnline() and (i_EntityHandle ~= LocalPlayer:GetHandle()) and entities.take_control_of(i_EntityHandle, 500) then
		Game.SyncNetworkID(NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(i_EntityHandle))
	end

	if type(bone) == "table" then
		boneList = bone
	else
		boneList = { bone }
	end

	for _, boneIndex in ipairs(boneList) do
		if type(boneIndex) == "string" then
			boneIndex = Game.GetEntityBoneIndexByName(i_EntityHandle, boneIndex)
		end

		GRAPHICS.USE_PARTICLE_FX_ASSET(s_PtfxDict)
		GRAPHICS.START_PARTICLE_FX_NON_LOOPED_ON_ENTITY_BONE(
			s_PtfxName,
			i_EntityHandle,
			v_Pos.x,
			v_Pos.y,
			v_Pos.z,
			v_Rot.x,
			v_Rot.y,
			v_Rot.z,
			boneIndex or 0,
			f_Scale,
			false,
			false,
			false
		)
	end
end

---@param fxHandles table
---@param dict? string
function Game.StopParticleEffects(fxHandles, dict)
	for _, fx in ipairs(fxHandles) do
		GRAPHICS.STOP_PARTICLE_FX_LOOPED(fx, false)
		GRAPHICS.REMOVE_PARTICLE_FX(fx, false)
	end

	if dict then
		STREAMING.REMOVE_NAMED_PTFX_ASSET(dict)
	end
end

function Game.GetPedComponents(ped)
	local variations = {}

	for i = 0, 11 do
		local max_drawables = 0
		local drawable      = PED.GET_PED_DRAWABLE_VARIATION(ped, i)
		local max_textures  = PED.GET_NUMBER_OF_PED_TEXTURE_VARIATIONS(ped, i, drawable)
		local texture       = PED.GET_PED_TEXTURE_VARIATION(ped, i)
		local palette       = PED.GET_PED_PALETTE_VARIATION(ped, i)

		for _drawable = 0, 100 do
			local count = PED.GET_NUMBER_OF_PED_TEXTURE_VARIATIONS(ped, i, _drawable)
			if count > 0 then
				max_drawables = max_drawables + 1
			else
				break
			end
		end

		table.insert(variations, {
			component = i,
			max_drawables = max_drawables,
			max_textures = max_textures,
			drawable = drawable,
			texture = texture,
			palette = palette
		})
	end

	return variations
end

---@param ped number
---@param components table
function Game.ApplyPedComponents(ped, components)
	if (not components or next(components) == nil) then
		return
	end

	for _, part in ipairs(components) do
		if PED.IS_PED_COMPONENT_VARIATION_VALID(
				ped,
				part.component,
				part.drawable,
				part.texture
			) then
			PED.SET_PED_COMPONENT_VARIATION(
				ped,
				part.component,
				part.drawable,
				part.texture,
				part.palette
			)
		end
	end
end

-- Returns a handle for the closest vehicle to a provided entity or coordinates.
---@param closeTo integer|vec3
---@param range number
---@param excludeEntity? integer **Optional**: a specific vehicle to ignore.
---@param nonPlayerVehicle? boolean -- **Optional**: if true, ignores player vehicles
---@param maxSpeed? number  -- **Optional**: if set, skips vehicles faster than this speed (m/s)
---@return integer -- vehicle handle or 0
function Game.GetClosestVehicle(closeTo, range, excludeEntity, nonPlayerVehicle, maxSpeed)
	local this = type(closeTo) == "number" and Game.GetEntityCoords(closeTo, false) or closeTo
	local closestVeh = 0
	local closestDist = range * range

	if VEHICLE.IS_ANY_VEHICLE_NEAR_POINT(this.x, this.y, this.z, range) then
		local veh_handles = entities.get_all_vehicles_as_handles()

		for _, veh in ipairs(veh_handles) do
			if veh ~= excludeEntity then
				local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh, -1, true)

				if not (nonPlayerVehicle and PED.IS_PED_A_PLAYER(driver)) then
					local vehPos = Game.GetEntityCoords(veh, true)
					---@diagnostic disable-next-line -- it's literally evaluated at the top 😡
					local distance = this:distance(vehPos)

					if distance <= closestDist and math.floor(VEHICLE.GET_VEHICLE_BODY_HEALTH(veh)) > 0 then
						if maxSpeed then
							local vehSpeed = ENTITY.GET_ENTITY_SPEED(veh)
							if vehSpeed <= maxSpeed then
								closestVeh = veh
								closestDist = distance
							end
						else
							closestVeh = veh
							closestDist = distance
						end
					end
				end
			end
		end
	end

	return closestVeh
end

-- Returns a handle for the closest human ped to a provided entity or coordinates.
---@param closeTo integer|vec3
---@param range integer
---@param aliveOnly boolean **Optional**: if true, ignores dead peds.
---@return integer
function Game.GetClosestPed(closeTo, range, aliveOnly)
	local this = type(closeTo) == 'number' and Game.GetEntityCoords(closeTo, false) or closeTo
	local closestDist = range * range

	if PED.IS_ANY_PED_NEAR_POINT(this.x, this.y, this.z, range) then
		for _, ped in ipairs(entities.get_all_peds_as_handles()) do
			if PED.IS_PED_HUMAN(ped) and (ped ~= LocalPlayer:GetHandle()) then
				local pedPos = Game.GetEntityCoords(ped, true)
				---@diagnostic disable-next-line
				local distance = this:distance(pedPos)

				if distance <= closestDist then
					if aliveOnly then
						if not ENTITY.IS_ENTITY_DEAD(ped, false) then
							return ped
						end
					else
						return ped
					end
				end
			end
		end
	end

	return 0
end

-- Temporary workaround to fix auto-pilot's "fly to objective" option.
---@return boolean, vec3
function Game.GetObjectiveBlipCoords()
	for _, v in ipairs(Refs.objectiveBlips) do
		local blipID = HUD.GET_FIRST_BLIP_INFO_ID(v)
		if HUD.DOES_BLIP_EXIST(blipID) then
			return true, HUD.GET_BLIP_INFO_ID_COORD(blipID)
		else
			local i_stdBlip = HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_STANDARD_BLIP_ENUM_ID())
			local vec_blipCoords = HUD.GET_BLIP_INFO_ID_COORD(i_stdBlip)

			if vec_blipCoords ~= vec3:zero() then
				return true, vec_blipCoords
			end
		end
	end

	return false, vec3:zero()
end

---@return vec3|nil
function Game.GetWaypointCoords()
	local waypoint = HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_WAYPOINT_BLIP_ENUM_ID())

	if (HUD.DOES_BLIP_EXIST(waypoint)) then
		return HUD.GET_BLIP_COORDS(waypoint)
	end
end

---@param target vec2|vec3|integer BlipID | Entity handle | Vector2 | Vector3
function Game.SetWaypointCoords(target)
	ThreadManager:Run(function()
		local x, y
		if (IsInstance(target, vec3) or IsInstance(target, vec2)) then
			x, y = target.x, target.y
		elseif (type(target) == "number") then
			local testBlip = HUD.GET_FIRST_BLIP_INFO_ID(target)
			if (HUD.DOES_BLIP_EXIST(testBlip)) then
				x, y, _ = HUD.GET_BLIP_INFO_ID_COORD(testBlip):unpack()
			elseif (Game.IsScriptHandle(target)) then
				x, y, _ = Game.GetEntityCoords(target, false):unpack()
			end
		end

		if (not x or not y) then
			return
		end

		HUD.DELETE_WAYPOINTS_FROM_THIS_PLAYER()
		HUD.SET_NEW_WAYPOINT(x, y)
	end)
end

---@param vecMin vec3
---@param vecMax vec3
---@return vec3
function Game.GetRandomCoordsInRange(vecMin, vecMax)
	math.randomseed(os.time())
	return vec3:new(
		math.random(vecMin.x, vecMax.x),
		math.random(vecMin.y, vecMax.y),
		math.random(vecMin.z, vecMax.z)
	)
end

---@param modelHash number|string
function Game.GetModelType(modelHash)
	modelHash = Game.EnsureModelHash(modelHash)

	if not Game.IsModelHash(modelHash) then
		return 0
	end

	if STREAMING.IS_MODEL_A_PED(modelHash) then
		return Enums.eEntityType.Ped
	elseif STREAMING.IS_MODEL_A_VEHICLE(modelHash) then
		return Enums.eEntityType.Vehicle
	else
		return Enums.eEntityType.Object
	end
end

---@param modelName string
function Game.GetModelHash(modelName)
	return Game.EnsureModelHash(modelName)
end

---@param modelHash integer
---@return string
function Game.GetPedName(modelHash)
	return ped_hashmap[modelHash] or _F("0x%X", modelHash)
end

---@param model integer|string
function Game.GetPedTypeFromModel(model)
	if (type(model) == "number") then
		model = ped_hashmap[model]
	end

	return ped_list[model].ped_type or Enums.ePedType.CIVMALE
end

---@param model integer|string
---@return ePedGender
function Game.GetPedGenderFromModel(model)
	if (type(model) == "number") then
		model = ped_hashmap[model]
	end

	local found = ped_list[model]
	---@diagnostic disable-next-line
	return found and found.ped_gender or Enums.ePedGender.UNK
end

---@param model integer|string
function Game.IsPedModelHuman(model)
	if (type(model) == "number") then
		model = ped_hashmap[model]
	end

	local found = ped_list[model]
	return found and found.is_human or false
end

---@param vehModel string|joaat_t
---@return string
function Game.GetVehicleDisplayName(vehModel)
	if (not _G.FAKE_YIMAPI) then
		return vehicles.get_vehicle_display_name(vehModel)
	end

	local modelName = ""
	if (type(vehModel) == "string") then
		modelName = vehModel
	elseif (type(vehModel) == "integer") then
		modelName = veh_hashmap[vehModel]
	end

	local data = vehicle_data[modelName]
	if (not data) then
		return "NULL"
	end

	-- display_name can be nil as well
	return data.display_name or "NULL"
end

---@param weapon string|joaat_t
---@return string
function Game.GetWeaponDisplayName(weapon)
	if (not _G.FAKE_YIMAPI) then
		return weapons.get_weapon_display_name(weapon)
	end

	local hash
	if (type(weapon) == "string") then
		hash = joaat(weapon)
	elseif (type(weapon) == "number") then
		hash = weapon
	end

	if (not hash) then
		return "NULL"
	end

	local data = weapon_data[hash]
	if (not data) then
		return "NULL"
	end

	return weapon_data[hash].display_name or "NULL"
end

---@return integer
function Game.GetCharacterIndex()
	if (Game.IsOnline()) then
		return stats.get_character_index()
	else
		if (self.get_ped() == 0) then
			return 0
		end

		return SP_CharIDs[LocalPlayer:GetModelHash()]
	end
end

function Game.GetCharacterName()
	local char_idx = Game.GetCharacterIndex()
	if (Game.IsOnline()) then
		return STATS.STAT_GET_STRING(joaat(_F("MP%d_CHAR_NAME", char_idx)), -1)
	end

	if (self.get_ped() == 0) then
		return "Unknown"
	end

	return SP_CharNames[char_idx + 1]
end

---@param coords vec3
---@param forwardVector vec3
---@param distance integer
---@return vec3|nil
function Game.FindSpawnPointInDirection(coords, forwardVector, distance)
	local bFound, vOutPos = false, vec3:zero()

	bFound, vOutPos = MISC.FIND_SPAWN_POINT_IN_DIRECTION(
		coords.x,
		coords.y,
		coords.z,
		forwardVector.x,
		forwardVector.y,
		forwardVector.z,
		distance,
		vOutPos
	)

	return bFound and vOutPos or nil
end

---@param distance integer
function Game.FindSpawnPointNearPlayer(distance)
	return Game.FindSpawnPointInDirection(
		LocalPlayer:GetPos(),
		LocalPlayer:GetForwardVector(),
		distance
	)
end

---@param coords vec3
---@param nodeType integer
---@return vec3, integer
function Game.GetClosestVehicleNodeWithHeading(coords, nodeType)
	local outPos = vec3:zero()
	local outHeading = 0

	_, outPos, outHeading = PATHFIND.GET_CLOSEST_VEHICLE_NODE_WITH_HEADING(
		coords.x,
		coords.y,
		coords.z,
		outPos,
		outHeading,
		nodeType,
		3,
		0
	)

	return outPos, outHeading
end

---@param entity integer | table
function Game.FadeOutEntity(entity)
	if not Game.IsOnline() then
		return
	end

	if type(entity) == "number" then
		if ENTITY.DOES_ENTITY_EXIST(entity) then
			NETWORK.NETWORK_FADE_OUT_ENTITY(entity, false, true)
		end
	elseif type(entity) == "table" then
		for i = 1, #entity do
			if ENTITY.DOES_ENTITY_EXIST(entity[i]) then
				NETWORK.NETWORK_FADE_OUT_ENTITY(entity[i], false, true)
			end
		end
	end
end

---@param entity integer | table
function Game.FadeInEntity(entity)
	if not Game.IsOnline() then
		return
	end

	if type(entity) == "number" then
		if ENTITY.DOES_ENTITY_EXIST(entity) then
			NETWORK.NETWORK_FADE_IN_ENTITY(entity, false, true)
		end
	elseif type(entity) == "table" then
		for i = 1, #entity do
			if ENTITY.DOES_ENTITY_EXIST(entity[i]) then
				NETWORK.NETWORK_FADE_IN_ENTITY(entity[i], false, true)
			end
		end
	end
end

-- Loads ground at the given coordinates. **Must be called in a coroutine**.
---@param coords vec3
function Game.LoadGroundAtCoord(coords)
	local max_ground_check = 1000
	local max_attempts = 300
	local ground_z = coords.z
	local current_attempts = 0
	local found = false
	local p1, height = false, 0

	while (not found and current_attempts < max_attempts) do
		found, ground_z = MISC.GET_GROUND_Z_FOR_3D_COORD(coords.x, coords.y, max_ground_check, ground_z, false, false)
		STREAMING.REQUEST_COLLISION_AT_COORD(coords.x, coords.y, coords.z)

		if (current_attempts % 10 == 0) then
			coords.z = coords.z + 25
		end

		current_attempts = current_attempts + 1
		yield()
	end

	if (not found) then
		return false
	end

	p1, height = WATER.GET_WATER_HEIGHT(coords.x, coords.y, coords.z, height)
	if (p1) then
		coords.z = height
	else
		coords.z = ground_z + 1.0
	end

	return true
end

---@param label string
function Game.GetGXTLabel(label)
	return HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(label or "")
end

---@param weaponHash hash
---@param startPos vec3
---@param endPos vec3
---@param damage number
---@param owner integer
---@param speed integer
function Game.ShootBulletBetweenCoords(weaponHash, startPos, endPos, damage, owner, speed)
	TaskWait(Game.RequestWeaponAsset, weaponHash)
	MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
		startPos.x,
		startPos.y,
		startPos.z,
		endPos.x,
		endPos.y,
		endPos.z,
		damage,
		false,
		weaponHash,
		owner,
		true,
		false,
		speed
	)
end

---@param entity handle
function Game.GetBoxCorners(entity)
	local corners = {}
	local vmin, vmax = Game.GetModelDimensions(Game.GetEntityModel(entity))

	for x = 0, 1 do
		for y = 0, 1 do
			for z = 0, 1 do
				local offset_vector = vec3:new(
					x == 0 and vmin.x or vmax.x,
					y == 0 and vmin.y or vmax.y,
					z == 0 and vmin.z or vmax.z
				)

				local world_pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
					entity,
					offset_vector.x,
					offset_vector.y,
					offset_vector.z
				)
				table.insert(corners, world_pos)
			end
		end
	end

	return corners
end

---@param entity handle
---@param color Color
function Game.DrawBoundingBox(entity, color)
	if (not ENTITY.DOES_ENTITY_EXIST(entity)) then
		return
	end
	local r, g, b, a = color:AsRGBA()
	local corners = Game.GetBoxCorners(entity)
	local connections = {
		{ 1, 2 }, { 2, 4 }, { 4, 3 }, { 3, 1 },
		{ 5, 6 }, { 6, 8 }, { 8, 7 }, { 7, 5 },
		{ 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 },
	}

	for _, pair in ipairs(connections) do
		local corner_a = corners[pair[1]]
		local corner_b = corners[pair[2]]

		GRAPHICS.DRAW_LINE(
			corner_a.x,
			corner_a.y,
			corner_a.z,
			corner_b.x,
			corner_b.y,
			corner_b.z,
			r,
			g,
			b,
			a or 255
		)
	end
end
