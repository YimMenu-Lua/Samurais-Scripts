-- This code was implemented from SoloMissions: https://github.com/YimMenu-Lua/SoloMissions with the author's permission.
--
-- Original Author: TCRoid (Rostal): https://github.com/TCRoid
--
-- License: None.


local SGSL                 = require("includes.services.SGSL")
local GetRunningFmmcScript = Game.GetRunningFmmcScript
local sgslData             = SGSL.data
local soloMissionsGlobal   = SGSL:Get(sgslData.solo_missions_global):AsGlobal()
local FMMC_L_MP_OBJ        = SGSL:Get(sgslData.fmmc_launcher_min_players_local)
local fmmcLMinPlayers      = FMMC_L_MP_OBJ:AsLocal()


local FMMC_SERV_BS_OBJ        = SGSL:Get(sgslData.fmmc_skip_obj_local)
local fmmcBsLocal             = FMMC_SERV_BS_OBJ:AsLocal()

local FMMC20_SERV_BS_OBJ      = SGSL:Get(sgslData.fmmc_20_skip_obj_local)
local fmmc20BsLocal           = FMMC20_SERV_BS_OBJ:AsLocal()

local MHMP_OBJ                = SGSL:Get(sgslData.solo_missions_mission_header_global)
local mhmpOffset              = MHMP_OBJ:GetOffset(1)
local mhmpReadSize            = MHMP_OBJ:GetOffset(2)
local missionHeaderMinPlayers = MHMP_OBJ:AsGlobal():At(mhmpOffset)

local SoloMissionsGlobals     = {
	minNumParticipants     = soloMissionsGlobal:At(SGSL:Get(sgslData.solo_missions_global_offset_1):GetValue()),
	numberOfTeams          = soloMissionsGlobal:At(SGSL:Get(sgslData.solo_missions_global_offset_2):GetValue()),
	maxNumberOfTeams       = soloMissionsGlobal:At(SGSL:Get(sgslData.solo_missions_global_offset_3):GetValue()),
	numPlayersPerTeam      = soloMissionsGlobal:At(SGSL:Get(sgslData.solo_missions_global_offset_4):GetValue()),
	nextContentID          = soloMissionsGlobal:At(SGSL:Get(sgslData.solo_missions_global_offset_5):GetValue()),
	criticalMinimumForTeam = soloMissionsGlobal:At(SGSL:Get(sgslData.solo_missions_global_offset_6):GetValue()),
}

local SoloMissionsLocals      = {
	["fmmc_launcher"] = {
		minPlayers       = fmmcLMinPlayers:At(FMMC_L_MP_OBJ:GetOffset(1)),
		missionVariation = fmmcLMinPlayers:At(SGSL:Get(sgslData.fmmc_launcher_mission_var_offset):GetValue()),
	},
	["fm_mission_controller"] = {
		serverBitSet  = fmmcBsLocal:At(1),
		serverBitSet2 = fmmcBsLocal:At(2),
		nextMission   = fmmcBsLocal:At(FMMC_SERV_BS_OBJ:GetOffset(1)),
		teamScore     = fmmcBsLocal:At(SGSL:Get(sgslData.fmmc_team_score_offset):GetValue()):At(1),
	},
	["fm_mission_controller_2020"] = {
		serverBitSet  = fmmc20BsLocal:At(1),
		serverBitSet2 = fmmc20BsLocal:At(2),
		nextMission   = fmmc20BsLocal:At(FMMC20_SERV_BS_OBJ:GetOffset(1)),
		teamScore     = fmmc20BsLocal:At(SGSL:Get(sgslData.fmmc_20_team_score_offset):GetValue()):At(1),
	},
	["fm_mission_controller_v3"] = { -- TODO
		serverBitSet  = fmmc20BsLocal:At(1),
		serverBitSet2 = fmmc20BsLocal:At(2),
		nextMission   = fmmc20BsLocal:At(FMMC20_SERV_BS_OBJ:GetOffset(1)),
		teamScore     = fmmc20BsLocal:At(SGSL:Get(sgslData.fmmc_20_team_score_offset):GetValue()):At(1),
	}
}


---@class SoloMissions
---@field private m_initialized boolean
---@field private m_ch_patch? scr_patch
local SoloMissions   = {}
SoloMissions.__index = SoloMissions

---@private
---@return SoloMissions
function SoloMissions:new()
	if (self.m_initialized) then
		return self
	end

	Backend:RegisterEventCallback(Enums.eBackendEvent.RELOAD_UNLOAD, function()
		local patch = self.m_ch_patch
		if (not patch) then return end

		patch:disable_patch()
	end)

	ThreadManager:RegisterLooped("SS_SOLO_MISSIONS", function()
		self:OnTick()
	end)

	self.m_initialized = true
	return self
end

function SoloMissions:SkipObjective()
	local scr = GetRunningFmmcScript()
	if (not scr) then return end

	SoloMissionsLocals[scr].serverBitSet2:SetBit(17)
end

function SoloMissions:ForceFail()
	local scr = GetRunningFmmcScript()
	if (not scr) then return end

	SoloMissionsLocals[scr].serverBitSet:SetBits({ 16, 20 })
end

function SoloMissions:InstantFinish()
	local scr = GetRunningFmmcScript()
	if (not scr) then return end

	local scrLocals = SoloMissionsLocals[scr]

	for i = 0, 5 do
		SoloMissionsGlobals.nextContentID:At(i, 6):WriteString("")
	end

	scrLocals.nextMission:WriteInt(5)
	scrLocals.teamScore:WriteInt(999999)
	scrLocals.teamScore:SetBits({ 9, 16 })
end

---@param v boolean
function SoloMissions:ToggleCasinoPatch(v)
	ThreadManager:Run(function()
		local patch = self.m_ch_patch
		if (v) then
			if (patch) then
				patch:enable_patch()
				return
			end

			self.m_ch_patch = scr_patch:new(
				"fmmc_launcher",
				"SCJJAT",
				"2D 01 03 00 00 5D ? ? ? 2A 06 56 05 00 5D ? ? ? 20 2A 06 56 05 00 5D",
				5,
				{ 0x71, 0x2E, 0x01, 0x01 }
			)
		elseif (patch) then
			patch:disable_patch()
		end
	end)
end

function SoloMissions:OnTick()
	if (not GVars.features.yim_heists.solo_missions) then
		return
	end

	if (script.is_active("fmmc_launcher")) then
		local fmmcLocals = SoloMissionsLocals["fmmc_launcher"]
		local index      = fmmcLocals.missionVariation:ReadInt()
		if (index > 0) then
			fmmcLocals.minPlayers:WriteInt(1)
			missionHeaderMinPlayers:At(index, mhmpReadSize):At(75):WriteInt(1)
		end
	end

	SoloMissionsGlobals.minNumParticipants:WriteInt(1)
	SoloMissionsGlobals.numPlayersPerTeam:At(1):WriteInt(1)
	SoloMissionsGlobals.criticalMinimumForTeam:At(1):WriteInt(0)
	SoloMissionsGlobals.numberOfTeams:WriteInt(1)
	SoloMissionsGlobals.maxNumberOfTeams:WriteInt(1)
end

local singleInstance <const> = SoloMissions:new()
return singleInstance
