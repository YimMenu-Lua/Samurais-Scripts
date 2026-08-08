-- This code was refactored and implemented from SoloMissions: https://github.com/YimMenu-Lua/SoloMissions with the author's permission.
--
-- Original Author: TCRoid (Rostal): https://github.com/TCRoid
--
-- License: None.


local SGSL               = require("includes.services.SGSL")
local sgslData           = SGSL.data
local soloMissionsGlobal = SGSL:Get(sgslData.solo_missions_global):AsGlobal()
local FMMC_L_MP_OBJ      = SGSL:Get(sgslData.fmmc_launcher_min_players_local)
local fmmcLMinPlayers    = FMMC_L_MP_OBJ:AsLocal()

local FMMC_SERV_BS_OBJ   = SGSL:Get(sgslData.fmmc_skip_obj_local)
local fmmcBsLocal        = FMMC_SERV_BS_OBJ:AsLocal()

local FMMC20_SERV_BS_OBJ = SGSL:Get(sgslData.fmmc_20_skip_obj_local)
local fmmc20BsLocal      = FMMC20_SERV_BS_OBJ:AsLocal()

local MHMP_OBJ           = SGSL:Get(sgslData.solo_missions_mission_header_global)
local mhmpOffset         = MHMP_OBJ:GetOffset(1)
local mhmpReadSize       = MHMP_OBJ:GetOffset(2)

return {
	sm_globals = {
		minNumParticipants     = soloMissionsGlobal:At(SGSL:Get(sgslData.solo_missions_global_offset_1):GetValue()),
		numberOfTeams          = soloMissionsGlobal:At(SGSL:Get(sgslData.solo_missions_global_offset_2):GetValue()),
		maxNumberOfTeams       = soloMissionsGlobal:At(SGSL:Get(sgslData.solo_missions_global_offset_3):GetValue()),
		numPlayersPerTeam      = soloMissionsGlobal:At(SGSL:Get(sgslData.solo_missions_global_offset_4):GetValue()),
		nextContentID          = soloMissionsGlobal:At(SGSL:Get(sgslData.solo_missions_global_offset_5):GetValue()),
		criticalMinimumForTeam = soloMissionsGlobal:At(SGSL:Get(sgslData.solo_missions_global_offset_6):GetValue()),
	},
	sm_locals = {
		fmmc_launcher = {
			minPlayers       = fmmcLMinPlayers:At(FMMC_L_MP_OBJ:GetOffset(1)),
			missionVariation = fmmcLMinPlayers:At(SGSL:Get(sgslData.fmmc_launcher_mission_var_offset):GetValue()),
		},
		fm_mission_controller = {
			serverBitSet  = fmmcBsLocal:At(1),
			serverBitSet2 = fmmcBsLocal:At(2),
			nextMission   = fmmcBsLocal:At(FMMC_SERV_BS_OBJ:GetOffset(1)),
			teamScore     = fmmcBsLocal:At(SGSL:Get(sgslData.fmmc_team_score_offset):GetValue()):At(1),
		},
		fm_mission_controller_2020 = {
			serverBitSet  = fmmc20BsLocal:At(1),
			serverBitSet2 = fmmc20BsLocal:At(2),
			nextMission   = fmmc20BsLocal:At(FMMC20_SERV_BS_OBJ:GetOffset(1)),
			teamScore     = fmmc20BsLocal:At(SGSL:Get(sgslData.fmmc_20_team_score_offset):GetValue()):At(1),
		},
	},
	missionHeaderMinPlayers = { scr_global = MHMP_OBJ:AsGlobal():At(mhmpOffset), read_size = mhmpReadSize }
}
