local FeatureBase = require("includes.modules.FeatureBase")

local trashBins <const> = {
	"m23_2_prop_m32_dumpster_01a",
	"prop_cs_dumpster_01a",
	"prop_dumpster_01a",
	"prop_dumpster_02a",
	"prop_dumpster_02b",
	"prop_dumpster_3a",
	"prop_dumpster_4a",
	"prop_dumpster_4b",
	"p_dumpster_t",
}

local vehAnim <const> = {
	dict = "missmic3leadinout_mcs1",
	anim = "cockpit_pilot"
}

local trashAnim <const> = {
	dict = "anim@amb@inspect@crouch@male_a@base",
	anim = "base"
}

local bootAnim <const> = {
	dict = "timetable@tracy@sleep@",
	anim = "base"
}

---@enum eHNSContext
local eHNSContext <const> = {
	NONE       = 0x0,
	CAR_BOOT   = 0x1,
	TRASH      = 0x2,
	IN_VEHICLE = 0x3
}

---@class BootVehicle
---@field m_handle handle
---@field m_is_rear_engined boolean
---@field m_length float
---@field m_height float
---@overload fun(handle?: handle, m_is_rear_engined?: boolean, length?: float, height?: float): BootVehicle
local BootVehicle = {}
BootVehicle.__index = BootVehicle
---@diagnostic disable-next-line
setmetatable(BootVehicle, {
	__call = function(_, handle, m_is_rear_engined, length, height)
		return setmetatable({
			m_handle = handle or 0,
			m_is_rear_engined = m_is_rear_engined or false,
			m_length = length or 0.0,
			m_height = height or 0.0,
			---@diagnostic disable-next-line
		}, BootVehicle)
	end
})

---@class HideNSeek : FeatureBase
---@field private m_entity Self
---@field private m_is_active boolean
---@field private m_was_spotted boolean
---@field private m_is_wanted boolean
---@field private m_context eHNSContext
---@field private m_boot_vehicle BootVehicle
---@field private m_trash_bin handle
---@field private m_last_check_time seconds
local HideNSeek = setmetatable({}, FeatureBase)
HideNSeek.__index = HideNSeek

---@param ent any
---@return HideNSeek
function HideNSeek.new(ent)
	local self = FeatureBase.new(ent)
	local instance = setmetatable(self, HideNSeek)
	instance:Init()
	---@diagnostic disable-next-line
	return instance
end

function HideNSeek:Init()
	self.m_is_active       = false
	self.m_was_spotted     = false
	self.m_is_wanted       = false
	self.m_context         = eHNSContext.NONE
	self.m_boot_vehicle    = BootVehicle()
	self.m_trash_bin       = 0
	self.m_last_check_time = 0
end

function HideNSeek:ShouldRun()
	return GVars.features.world.hide_n_seek
		and not Self:IsSwimming()
		and not HUD.IS_PAUSE_MENU_ACTIVE()
		and not NETWORK.NETWORK_IS_IN_MP_CUTSCENE()
end

function HideNSeek:Cleanup()
	if (not self.m_is_active) then
		return
	end

	local pedHandle = Self:GetHandle()
	TASK.CLEAR_PED_TASKS(pedHandle)
	PLAYER.RESET_WANTED_LEVEL_DIFFICULTY(Self:GetPlayerID())
	if (ENTITY.IS_ENTITY_ATTACHED(pedHandle)) then
		ENTITY.DETACH_ENTITY(pedHandle, true, false)
	end

	self:Init()
end

function HideNSeek:OnEnable()
	self:Init()
end

function HideNSeek:OnDisable()
	self:Cleanup()
end

---@return boolean
function HideNSeek:IsActive()
	return self.m_is_active
end

function HideNSeek:HideInVehicle()
	if (Self:IsOnFoot() or not self.m_is_wanted) then
		return
	end

	local veh = Self:GetVehicleNative()
	if (not VEHICLE.IS_THIS_MODEL_A_CAR(Game.GetEntityModel(veh))) then
		return
	end

	local cond = not Self:IsDriving() or VEHICLE.IS_VEHICLE_STOPPED(veh)
	if (cond
			and not PAD.IS_CONTROL_PRESSED(0, 71)
			and not PAD.IS_CONTROL_PRESSED(0, 72)
			and VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(veh)
		) then
		Game.ShowButtonPrompt("Press ~INPUT_FRONTEND_ACCEPT~ to hide inside the vehicle.")
		if (PAD.IS_CONTROL_JUST_PRESSED(0, 201) and not HUD.IS_MP_TEXT_CHAT_TYPING()) then
			YimActions:ResetPlayer()
			Await(Game.RequestAnimDict, vehAnim.dict)

			TASK.TASK_PLAY_ANIM(
				Self:GetHandle(),
				vehAnim.dict,
				vehAnim.anim,
				6.0,
				3.0,
				-1,
				18,
				1.0,
				false,
				false,
				false
			)

			VEHICLE.SET_VEHICLE_IS_WANTED(veh, false)
			if (Self:IsDriving()) then
				VEHICLE.SET_VEHICLE_ENGINE_ON(veh, false, false, true)
			end

			self.m_is_active = true
			self.m_context = eHNSContext.IN_VEHICLE
			sleep(1000)
		end
	end
end

function HideNSeek:HideInTrash()
	if (self.m_trash_bin == 0 or not ENTITY.DOES_ENTITY_EXIST(self.m_trash_bin)) then
		return
	end

	Game.ShowButtonPrompt("Press ~INPUT_PICKUP~ to hide in the dumpster.")

	if PAD.IS_CONTROL_JUST_PRESSED(0, 38) then
		if (self.m_was_spotted) then
			Notifier:ShowWarning(
				"Samurai's Scripts",
				"The cops have spotted you! You can't hide until they lose sight of you."
			)
			return
		end

		local pedHandle = Self:GetHandle()
		YimActions:ResetPlayer()
		TASK.TASK_TURN_PED_TO_FACE_ENTITY(pedHandle, self.m_trash_bin, 10)
		CAM.DO_SCREEN_FADE_OUT(500)
		sleep(1000)
		ENTITY.ATTACH_ENTITY_TO_ENTITY(
			pedHandle,
			self.m_trash_bin,
			-1,
			0.0,
			0.12,
			1.13,
			0.0,
			0.0,
			90.0,
			false,
			false,
			false,
			false,
			20,
			true,
			1
		)

		Await(Game.RequestAnimDict, trashAnim.dict)
		TASK.TASK_PLAY_ANIM(
			pedHandle,
			trashAnim.dict,
			trashAnim.anim,
			4.0,
			-4.0,
			-1,
			1,
			1.0,
			false,
			false,
			false
		)

		sleep(200)
		CAM.DO_SCREEN_FADE_IN(500)
		sleep(200)
		AUDIO.PLAY_SOUND_FRONTEND(
			-1,
			"TRASH_BAG_LAND",
			"DLC_HEIST_SERIES_A_SOUNDS",
			true
		)
		sleep(1000)

		self.m_is_active = true
		self.m_context = eHNSContext.TRASH
	end
end

function HideNSeek:HideInTrunk()
	if (self.m_boot_vehicle.m_handle == 0) or not ENTITY.DOES_ENTITY_EXIST(self.m_boot_vehicle.m_handle) then
		return
	end

	Game.ShowButtonPrompt("Press ~INPUT_PICKUP~ to hide in the trunk.")

	if PAD.IS_CONTROL_JUST_PRESSED(0, 38) then
		local z_offset = 0.93
		local veh = self.m_boot_vehicle.m_handle

		if (self.m_was_spotted) then
			Notifier:ShowWarning(
				"Samurai's Scripts",
				"The cops have spotted you. You can't hide until they lose sight of you."
			)
			return
		end

		local cls = VEHICLE.GET_VEHICLE_CLASS(veh)
		if (cls == Enums.eVehicleClasses.Vans) then
			z_offset = 1.1
		elseif cls == Enums.eVehicleClasses.SUVs then
			z_offset = 1.2
		end

		Await(Game.RequestAnimDict, "rcmnigel3_trunk")
		YimActions:ResetPlayer()

		local pedHandle = Self:GetHandle()
		if not ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY_IN_FRONT(pedHandle, veh) then
			TASK.TASK_TURN_PED_TO_FACE_ENTITY(pedHandle, veh, 0)
			repeat
				yield()
			until not TASK.GET_IS_TASK_ACTIVE(pedHandle, Enums.ePedTaskIndex.TurnToFaceEntityOrCoord)
		end

		TASK.TASK_PLAY_ANIM(
			pedHandle,
			"rcmnigel3_trunk",
			"out_trunk_trevor",
			4.0,
			-4.0,
			1500,
			2,
			0.0,
			false,
			false,
			false
		)
		sleep(800)

		if not VEHICLE.IS_VEHICLE_STOPPED(veh) then
			TASK.CLEAR_PED_TASKS(pedHandle)
			Notifier:ShowWarning(
				"Samurai's Scripts",
				"Vehicle must be stopped."
			)
			return
		end

		ENTITY.FREEZE_ENTITY_POSITION(pedHandle, true)
		ENTITY.SET_ENTITY_COLLISION(pedHandle, false, true)
		sleep(50)
		VEHICLE.SET_VEHICLE_DOOR_OPEN(veh, 5, false, false)
		sleep(500)
		ENTITY.FREEZE_ENTITY_POSITION(pedHandle, false)

		local chassis_bone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(veh, "chassis_dummy")
		if (chassis_bone == -1) then
			chassis_bone = 0
		end

		local veh_hash = ENTITY.GET_ENTITY_MODEL(veh)
		local vmin, vmax = Game.GetModelDimensions(veh_hash)

		self.m_boot_vehicle.m_length = vmax.y - vmin.y
		self.m_boot_vehicle.m_height = vmax.z - vmin.z
		local attachPosY = self.m_boot_vehicle.m_is_rear_engined
			and (self.m_boot_vehicle.m_length / 3)
			or (-self.m_boot_vehicle.m_length / 3)
		-- local attachPosZ = self.bootVehicle.height * 0.42

		Await(Game.RequestAnimDict, bootAnim.dict)

		TASK.TASK_PLAY_ANIM(
			pedHandle,
			bootAnim.dict,
			bootAnim.anim,
			4.0,
			-4.0,
			-1,
			2,
			1.0,
			false,
			false,
			false
		)

		ENTITY.ATTACH_ENTITY_TO_ENTITY(
			pedHandle,
			veh,
			chassis_bone,
			-0.3,
			attachPosY,
			z_offset,
			180.0,
			0.0,
			0.0,
			false,
			false,
			false,
			false,
			20,
			true,
			1
		)

		sleep(500)
		VEHICLE.SET_VEHICLE_DOOR_SHUT(veh, 5, false)
		ENTITY.SET_ENTITY_COLLISION(pedHandle, true, true)
		VEHICLE.SET_VEHICLE_IS_WANTED(veh, false)
		self.m_is_active = true
		self.m_context = eHNSContext.CAR_BOOT
		sleep(1000)
	end
end

function HideNSeek:IsNearCarTrunk()
	if Self:IsOnFoot() and not YimActions:IsPedPlaying() then
		local selfPos = Self:GetPos()
		local selfFwd = Game.GetForwardVector(Self:GetHandle())
		local fwdPos = vec3:new(selfPos.x + (selfFwd.x * 1.3), selfPos.y + (selfFwd.y * 1.3), selfPos.z)
		local veh = Game.GetClosestVehicle(fwdPos, 20, nil, false, 2)

		if (veh ~= nil and veh > 0) then
			if (not VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(veh))) then
				return false, 0, false
			end

			local bootBone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(veh, "boot")
			if (bootBone ~= -1) then
				local vehCoords         = ENTITY.GET_ENTITY_COORDS(veh, false)
				local vehFwdVec         = ENTITY.GET_ENTITY_FORWARD_VECTOR(veh)
				local engineBone        = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(veh, "engine")
				local lfwheelBone       = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(veh, "wheel_lf")
				local engBoneCoords     = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(veh, engineBone)
				local lfwBoneCoords     = ENTITY.GET_WORLD_POSITION_OF_ENTITY_BONE(veh, lfwheelBone)
				local bonedistance      = lfwBoneCoords:distance(engBoneCoords)
				local m_is_rear_engined = bonedistance > 2 -- Can also read vehicle model flag FRONT_BOOT
				local vmin, vmax        = Game.GetModelDimensions(ENTITY.GET_ENTITY_MODEL(veh))
				local veh_length        = vmax.y - vmin.y
				local tempPos           = m_is_rear_engined
					and vec2:new(
						vehCoords.x + (vehFwdVec.x * (veh_length / 1.6)),
						vehCoords.y + (vehFwdVec.y * (veh_length / 1.6))
					)
					or vec2:new(
						vehCoords.x - (vehFwdVec.x * (veh_length / 1.6)),
						vehCoords.y - (vehFwdVec.y * (veh_length / 1.6))
					)

				local search_area       = vec3:new(tempPos.x, tempPos.y, vehCoords.z)
				if (search_area:distance(Self:GetPos()) <= 1.5) then
					return true, veh, m_is_rear_engined
				end
			end
		end
	end

	return false, 0, false
end

function HideNSeek:IsNearTrashBin()
	local binPos = vec3:zero()
	local myCoords = Self:GetPos()
	local myFwdVec = Self:GetForwardVector()
	local searchPos = vec3:new(
		myCoords.x + myFwdVec.x * 1.2,
		myCoords.y + myFwdVec.y * 1.2,
		myCoords.z + myFwdVec.z * 1.2
	)

	for _, trash in ipairs(trashBins) do
		local bin = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(
			searchPos.x,
			searchPos.y,
			searchPos.z,
			1.5,
			joaat(trash),
			false,
			false,
			false
		)

		if (ENTITY.DOES_ENTITY_EXIST(bin)) then
			binPos = Game.GetEntityCoords(bin, false)
			if (searchPos:distance(binPos) <= 1.3) then
				return true, bin
			end
		end
	end

	return false, 0
end

function HideNSeek:WhileOnFoot()
	if (self.m_is_active or not Self:IsOutside() or not Self:IsOnFoot()) then
		return
	end

	local currentTime = Game.GetGameTimer()
	if (currentTime - self.m_last_check_time < 1000) then
		return
	end

	self.m_last_check_time = currentTime
	ThreadManager:Run(function(s)
		if (self.m_boot_vehicle.m_handle == 0) then
			_, self.m_boot_vehicle.m_handle, self.m_boot_vehicle.m_is_rear_engined = self:IsNearCarTrunk()
			s:sleep(250)
		end

		if (self.m_trash_bin == 0) then
			_, self.m_trash_bin = self:IsNearTrashBin()
			s:sleep(250)
		end
	end)

	if (self.m_boot_vehicle.m_handle ~= 0) then
		if (Self:GetPos():distance(Game.GetEntityCoords(self.m_boot_vehicle.m_handle, false)) >= 3.5) then
			self.m_boot_vehicle = BootVehicle()
			return
		end
	end

	if (self.m_trash_bin ~= 0) then
		if Self:GetPos():distance(Game.GetEntityCoords(self.m_trash_bin, false)) > 2 then
			self.m_trash_bin = 0
			return
		end
	end
end

function HideNSeek:GetHidingContext()
	if (Self:IsOnFoot()) then
		self:WhileOnFoot()

		if (self.m_trash_bin ~= 0) then
			self:HideInTrash()
		elseif (self.m_boot_vehicle.m_handle ~= 0) then
			self:HideInTrunk()
		end
	elseif (self.m_is_wanted and not self.m_was_spotted) then
		self:HideInVehicle()
	end
end

function HideNSeek:WhileHiding()
	local v_WantedCentrePos

	if (self.m_is_active) then
		if (not Self:IsAlive()) then
			self:Cleanup()
		end

		if (self.m_context == eHNSContext.IN_VEHICLE and not ENTITY.DOES_ENTITY_EXIST(Self:GetVehicleNative())) then
			self:Cleanup()
			Self:ClearTasks()
			PLAYER.RESET_WANTED_LEVEL_DIFFICULTY(Self:GetPlayerID())
		end

		if (self.m_context == eHNSContext.CAR_BOOT and not ENTITY.DOES_ENTITY_EXIST(self.m_boot_vehicle.m_handle)) then
			self:Cleanup()
			Self:ClearTasks()
			PLAYER.RESET_WANTED_LEVEL_DIFFICULTY(Self:GetPlayerID())
		end

		if (self.m_context == eHNSContext.TRASH and not ENTITY.DOES_ENTITY_EXIST(self.m_trash_bin)) then
			self:Cleanup()
			Self:ClearTasks()
			PLAYER.RESET_WANTED_LEVEL_DIFFICULTY(Self:GetPlayerID())
		end

		if (not v_WantedCentrePos) then
			v_WantedCentrePos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
				Self:GetHandle(),
				math.random(-200, 200),
				math.random(-200, 200),
				math.random(0, 20)
			)
		end

		if (self.m_is_wanted and not self.m_was_spotted) then
			PED.SET_COP_PERCEPTION_OVERRIDES(0.1, 0.1, 0.1, 1.0, 1.0, 1.0, 0.0)
			---@diagnostic disable-next-line
			PLAYER.SET_PLAYER_WANTED_CENTRE_POSITION(Self:GetPlayerID(), v_WantedCentrePos, true)
		end

		if (self.m_context == eHNSContext.IN_VEHICLE) then
			if self.m_was_spotted then
				Notifier:ShowWarning(
					"Samurai's Scripts",
					"You have been spotted by the cops! You can't hide until they lose sight of you."
				)

				self:Cleanup()
				Self:ClearTasks()
				return
			end

			Game.ShowButtonPrompt(
				"Press ~INPUT_FRONTEND_ACCEPT~ or ~INPUT_VEH_ACCELERATE~ or ~INPUT_VEH_BRAKE~ to stop hiding."
			)

			if ((PAD.IS_CONTROL_JUST_PRESSED(0, 201)
						or PAD.IS_CONTROL_PRESSED(0, 71)
						or PAD.IS_CONTROL_PRESSED(0, 72))
					and not HUD.IS_MP_TEXT_CHAT_TYPING()
				) then
				Self:ClearTasks()
				if (Self:IsDriving()) then
					VEHICLE.SET_VEHICLE_ENGINE_ON(Self:GetVehicleNative(), true, false, false)
				end

				self:Cleanup()
				sleep(1000)
			end
		end

		if (self.m_context == eHNSContext.CAR_BOOT) then
			Game.ShowButtonPrompt("Press ~INPUT_PICKUP~ to get out.")

			if (PAD.IS_CONTROL_JUST_PRESSED(0, 38)) then
				local my_pos = Self:GetPos()
				local groundZ = 0
				local outPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(
					Self:GetHandle(),
					0,
					self.m_boot_vehicle.m_is_rear_engined and 2 or -2,
					0
				)

				_, groundZ = MISC.GET_GROUND_Z_FOR_3D_COORD(
					my_pos.x,
					my_pos.y,
					my_pos.z,
					groundZ,
					false,
					false
				)

				local outHeading = self.m_boot_vehicle.m_is_rear_engined
					and Game.GetHeading(self.m_boot_vehicle.m_handle)
					or (Game.GetHeading(self.m_boot_vehicle.m_handle) - 180)

				VEHICLE.SET_VEHICLE_DOOR_OPEN(self.m_boot_vehicle.m_handle, 5, false, false)
				sleep(500)
				Self:ClearTasks()
				ENTITY.DETACH_ENTITY(Self:GetHandle(), true, false)
				ENTITY.SET_ENTITY_COORDS(
					Self:GetHandle(),
					outPos.x,
					outPos.y,
					groundZ,
					false,
					false,
					false,
					false
				)

				ENTITY.SET_ENTITY_HEADING(Self:GetHandle(), outHeading)
				VEHICLE.SET_VEHICLE_DOOR_SHUT(self.m_boot_vehicle.m_handle, 5, false)
				sleep(200)

				if ENTITY.GET_ENTITY_SPEED(self.m_boot_vehicle.m_handle) > 4.0 then
					PED.SET_PED_TO_RAGDOLL(Self:GetHandle(), 1500, 0, 0, false, false, false)
				end

				self:Cleanup()
				sleep(1000)
			end
		end

		if (self.m_context == eHNSContext.TRASH) then
			Game.ShowButtonPrompt("Press ~INPUT_PICKUP~ to get out.")
			if PAD.IS_CONTROL_JUST_PRESSED(0, 38) then
				CAM.DO_SCREEN_FADE_OUT(500)
				sleep(1000)
				local my_pos = Self:GetPos()
				local groundZ = 0

				_, groundZ = MISC.GET_GROUND_Z_FOR_3D_COORD(
					my_pos.x,
					my_pos.y,
					my_pos.z,
					groundZ,
					false,
					false
				)

				ENTITY.DETACH_ENTITY(Self:GetHandle(), true, false)
				ENTITY.SET_ENTITY_HEADING(Self:GetHandle(), Self:GetHeading(90))
				Self:ClearTasks()

				local my_fwd = Self:GetForwardVector()
				ENTITY.SET_ENTITY_COORDS(
					Self:GetHandle(),
					my_pos.x + (my_fwd.x * 1.3),
					my_pos.y + (my_fwd.y * 1.3),
					groundZ,
					false,
					false,
					false,
					false
				)
				CAM.DO_SCREEN_FADE_IN(500)
				AUDIO.PLAY_SOUND_FRONTEND(-1, "TRASH_BAG_LAND", "DLC_HEIST_SERIES_A_SOUNDS", true)

				Await(Game.RequestAnimDict, "move_m@_idles@shake_off")
				TASK.TASK_PLAY_ANIM(
					Self:GetHandle(),
					"move_m@_idles@shake_off",
					"shakeoff_1",
					4.0,
					-4.0,
					3000,
					48,
					0.0,
					false,
					false,
					false
				)

				sleep(1000)
				self:Cleanup()
			end
		end
	elseif v_WantedCentrePos then
		v_WantedCentrePos = nil
	end
end

function HideNSeek:OnTick()
	if (not self:ShouldRun()) then
		yield()
		return
	end

	self.m_is_wanted = PLAYER.GET_PLAYER_WANTED_LEVEL(Self:GetPlayerID()) > 0
	self.m_was_spotted = PLAYER.IS_WANTED_AND_HAS_BEEN_SEEN_BY_COPS(Self:GetPlayerID())
	if (not self.m_is_active) then
		self:GetHidingContext()
	else
		self:WhileHiding()
	end
end

return HideNSeek
