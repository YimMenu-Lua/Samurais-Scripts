-- This code was refactored and implemented from SoloMissions: https://github.com/YimMenu-Lua/SoloMissions with the author's permission.
--
-- Original Author: TCRoid (Rostal): https://github.com/TCRoid
--
-- License: None.


local dataLoaded, smData   = pcall(require, "includes.thirdparty.SoloMissions.sm_data")
local GetRunningFmmcScript = Game.GetRunningFmmcScript


---@class SoloMissions
---@field private m_initialized boolean
---@field private m_is_disabled boolean
---@field private m_ch_patch? scr_patch
---@field private m_mhmp_g ScriptGlobal MissionHeaderMinPlayers
---@field private m_mhmp_size integer array size
local SoloMissions   = { m_initialized = false, m_is_disabled = false }
SoloMissions.__index = SoloMissions

---@private
---@return SoloMissions
function SoloMissions:init()
	if (self.m_initialized) then
		return self
	end

	if (not dataLoaded) then
		self.m_initialized = true
		self.m_is_disabled = true
		log.warning("SoloMissions failed to load! Module will be disabled.")
		return self
	end

	self.m_mhmp_g    = smData.missionHeaderMinPlayers.scr_global
	self.m_mhmp_size = smData.missionHeaderMinPlayers.read_size

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

---@nodiscard
---@return boolean
function SoloMissions:IsDisabled()
	return self.m_is_disabled
end

function SoloMissions:SkipObjective()
	if (self.m_is_disabled) then return end

	local scr = GetRunningFmmcScript()
	if (not scr) then return end

	local scrLocals = smData.sm_locals[scr]
	if (not scrLocals) then return end

	scrLocals.serverBitSet2:SetBit(17)
end

function SoloMissions:ForceFail()
	if (self.m_is_disabled) then return end

	local scr = GetRunningFmmcScript()
	if (not scr) then return end

	local scrLocals = smData.sm_locals[scr]
	if (not scrLocals) then return end

	scrLocals.serverBitSet:SetBits({ 16, 20 })
end

function SoloMissions:InstantFinish()
	if (self.m_is_disabled) then return end

	local scr = GetRunningFmmcScript()
	if (not scr) then return end

	local scrLocals     = smData.sm_locals[scr]
	local nextContentID = smData.sm_globals.nextContentID

	for i = 0, 5 do
		nextContentID:At(i, 6):WriteString("")
	end

	scrLocals.nextMission:WriteInt(5)
	scrLocals.teamScore:WriteInt(999999)
	scrLocals.teamScore:SetBits({ 9, 16 })
end

---@param v boolean
function SoloMissions:ToggleCasinoPatch(v)
	if (self.m_is_disabled) then return end

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
	if (self.m_is_disabled or not GVars.features.yim_heists.solo_missions) then
		return
	end

	if (script.is_active("fmmc_launcher")) then
		local missionHeaderMinPlayers = self.m_mhmp_g
		local mhmpReadSize            = self.m_mhmp_size
		local fmmcLocals              = smData.sm_locals.fmmc_launcher
		local index                   = fmmcLocals.missionVariation:ReadInt()
		if (index > 0) then
			fmmcLocals.minPlayers:WriteInt(1)
			missionHeaderMinPlayers:At(index, mhmpReadSize):At(75):WriteInt(1)
		end
	end

	local scrGlobals = smData.sm_globals
	scrGlobals.minNumParticipants:WriteInt(1)
	scrGlobals.numPlayersPerTeam:At(1):WriteInt(1)
	scrGlobals.criticalMinimumForTeam:At(1):WriteInt(0)
	scrGlobals.numberOfTeams:WriteInt(1)
	scrGlobals.maxNumberOfTeams:WriteInt(1)
end

local singleInstance <const> = SoloMissions:init()
return singleInstance
