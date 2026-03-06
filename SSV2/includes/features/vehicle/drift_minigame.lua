-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase = require("includes.modules.FeatureBase")
-- if (self.m_drift_time >= 10 and self.m_drift_time < 30) then
-- 	self.m_multiplier = 1
-- elseif (self.m_drift_time >= 30 and self.m_drift_time < 60) then
-- 	self.m_multiplier = 2
-- elseif (self.m_drift_time >= 60 and self.m_drift_time < 120) then
-- 	self.m_multiplier = 5
-- elseif (self.m_drift_time >= 120) then
-- 	self.m_multiplier = 10
-- end
local MultiplierStages <const> = {
	{ mult = 1,  threshold = { min = 1500, max = 2900 } },
	{ mult = 2,  threshold = { min = 3000, max = 5900 } },
	{ mult = 5,  threshold = { min = 6000, max = 11900 } },
	{ mult = 10, threshold = { min = 12000, max = math.int32_max() } },
}

---@class DriftMinigame : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_is_active boolean
---@field private m_points integer
---@field private m_extra_points integer
---@field private m_multiplier integer
---@field private m_drift_time integer
---@field private m_straight_counter integer
---@field private m_streak_text string
---@field private m_extra_text string
---@field private m_player_best integer
---@field private m_extra_text_time integer
---@field private m_text_height float
---@field private m_has_crashed boolean
local DriftMinigame = setmetatable({}, FeatureBase)
DriftMinigame.__index = DriftMinigame

---@param pv PlayerVehicle
---@return DriftMinigame
function DriftMinigame.new(pv)
	local self = FeatureBase.new(pv)
	---@diagnostic disable-next-line
	return setmetatable(self, DriftMinigame)
end

function DriftMinigame:Init()
	self.m_is_active        = false
	self.m_has_crashed      = false
	self.m_points           = 0
	self.m_extra_points     = 0
	self.m_multiplier       = 1
	self.m_drift_time       = 0
	self.m_straight_counter = 0
	self.m_streak_text      = ""
	self.m_extra_text       = ""
	self.m_extra_text_time  = 0
	self.m_text_height      = 0.7
	self.m_player_best      = GVars.features.vehicle.drift_minigame.player_best
end

function DriftMinigame:Cleanup()
	self:Init()
end

function DriftMinigame:ShouldRun()
	return (GVars.features.vehicle.drift_minigame.enabled
		and self.m_entity
		and self.m_entity:IsValid()
		and self.m_entity:IsCar())
end

---@return boolean
function DriftMinigame:IsActive()
	return self.m_is_active
end

---@return number
function DriftMinigame:GetMultiplier()
	for _, v in ipairs(MultiplierStages) do
		if (self.m_drift_time >= v.threshold.min and self.m_drift_time < v.threshold.max) then
			return v.mult
		end
	end

	return 1
end

function DriftMinigame:SetMultiplierPlenalty()
	if (self.m_multiplier == 1) then
		return
	end

	for i = #MultiplierStages, 2, -1 do
		local curr_stage = MultiplierStages[i]
		local prev_stage = MultiplierStages[i - 1]
		if (self.m_multiplier == curr_stage.mult) then
			self.m_drift_time = prev_stage.threshold.min
			self.m_multiplier = prev_stage.mult
			break
		end
	end
end

function DriftMinigame:PlayIncrementSound()
	if (GVars.features.vehicle.drift_minigame.score_sound) then
		GUI:PlaySound(GUI.Sounds.Nav)
	end
end

---@param points number
function DriftMinigame:BankDriftPoints_SP(points)
	stats.increment_stat(
		stats.get_prefixed_stat("SPX_TOTAL_CASH"),
		points,
		0,
		math.int32_max()
	)
	AUDIO.PLAY_SOUND_FRONTEND(
		-1,
		"LOCAL_PLYR_CASH_COUNTER_INCREASE",
		"DLC_HEISTS_GENERAL_FRONTEND_SOUNDS",
		true
	)
end

---@param forceReset? boolean
function DriftMinigame:ResetStreak(forceReset)
	self.m_extra_points = 0

	if (self.m_multiplier > 1 and not forceReset) then
		self.m_extra_text      = _T("VEH_DRIFT_MINIGAME_PENALTY")
		self.m_extra_text_time = Game.GetGameTimer() + 3000
		self:SetMultiplierPlenalty()
		sleep(250)
		return
	end

	self.m_extra_text  = ""
	self.m_text_height = 0.7
	self.m_streak_text = _T("VEH_DRIFT_MINIGAME_STREAK_LOST")

	sleep(3000)
	self.m_points           = 0
	self.m_drift_time       = 0
	self.m_straight_counter = 0
	self.m_extra_points     = 0
	self.m_multiplier       = 1
	self.m_streak_text      = ""
	self.m_is_active        = false
end

function DriftMinigame:Update()
	if (self.m_points == 0) then
		return
	end

	local col = Color(255, 192, 0, 200)
	local driftText = _F("%s\n+%s pts", self.m_streak_text, string.formatint(self.m_points))
	if (self.m_has_crashed and self.m_multiplier == 1) then
		driftText = self.m_streak_text
	end

	Game.DrawText(
		vec2:new(0.5, 0.03),
		driftText,
		col,
		vec2:new(1, self.m_text_height),
		7,
		true
	)

	if (self.m_extra_text ~= "" and Game.GetGameTimer() < self.m_extra_text_time) then
		Game.DrawText(
			vec2:new(0.5, 0.12),
			self.m_extra_text,
			col,
			vec2:new(1, 0.4),
			7,
			true
		)
	end
end

function DriftMinigame:OnTick()
	if (not self:ShouldRun()) then
		return
	end

	local PV = self.m_entity
	if (self.m_is_active and (not LocalPlayer:IsDriving() or PV:GetCurrentGear() < 1)) then
		self:ResetStreak(true)
		return
	end

	local handle                       = PV:GetHandle()
	local speedVec                     = PV:GetSpeedVector()
	local speed                        = PV:GetSpeed()
	local height                       = PV:GetHeightAboveGround()
	local localCrashText               = ""
	local angle                        = math.abs(speedVec.x)
	self.m_has_crashed, localCrashText = PV:HasCrashed()
	if (PV:IsDrifting()) then
		self.m_is_active        = true
		self.m_text_height      = 0.7
		self.m_streak_text      = _F("%s   x%d", _T("VEH_DRIFT_MINIGAME_DRIFT_LABEL"), self.m_multiplier)
		self.m_points           = self.m_points + (1 * self.m_multiplier)
		self.m_straight_counter = 0
		self:PlayIncrementSound()
	end

	if (angle > 11) then
		self.m_streak_text = _F("%s   x%d", _T("VEH_DRIFT_MINIGAME_BIG_ANGLE"), self.m_multiplier)
		self.m_points = self.m_points + (5 * self.m_multiplier)
	end

	if (angle > 14) then
		self.m_streak_text = _F("%s   x%d", _T("VEH_DRIFT_MINIGAME_SICK_ANGLE"), self.m_multiplier)
		self.m_points = self.m_points + (10 * self.m_multiplier)
	end

	if (angle < 2 and not VEHICLE.IS_VEHICLE_STOPPED(handle)) then
		self.m_straight_counter = self.m_straight_counter + 1
	else
		self.m_straight_counter = 0
	end

	if (self.m_straight_counter == 0 and self.m_is_active) then
		self.m_drift_time = self.m_drift_time + (1 * (speed // 10))
	end

	self.m_multiplier = self:GetMultiplier()

	if (speed > 5 and not self.m_has_crashed) then
		if (height > 1 and height < 5) then
			self.m_extra_points = self.m_extra_points + 1
			self.m_points       = self.m_points + self.m_extra_points
			self.m_extra_text   = _F("%s  +%d pts", _T("VEH_DRIFT_MINIGAME_AIR"), self.m_extra_points)
		elseif (height >= 5) then
			self.m_extra_points = self.m_extra_points + 5
			self.m_points       = self.m_points + self.m_extra_points
			self.m_extra_text   = _F("%s  +%d pts", _T("VEH_DRIFT_MINIGAME_BIG_AIR"), self.m_extra_points)
		end

		if (not localCrashText:isempty()) then
			self.m_extra_points    = self.m_extra_points + 1
			self.m_extra_text      = _F("%s  +%d", localCrashText, self.m_extra_points)
			self.m_extra_text_time = Game.GetGameTimer() + 3000
		end
	end

	if (self.m_has_crashed) then
		if (self.m_multiplier < 2) then
			self.m_streak_text = localCrashText
		end
		self:ResetStreak()
	elseif (self.m_straight_counter > 100 or PV:IsStopped()) then
		local timer = Timer.new(5000)

		while (not timer:IsDone()) do
			if not LocalPlayer:IsDriving() then
				self:ResetStreak(true)
				return
			end

			if (PV:IsDrifting() or ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(handle)) then
				timer:Reset(3000)
				return
			end

			local pulse = 0.67 + 0.03 * math.sin(Game.GetGameTimer() / 120)
			self.m_text_height = pulse
			sleep(16)
		end

		self.m_streak_text = _T("VEH_DRIFT_MINIGAME_BANKED_PTS")

		if (not Game.IsOnline() and self.m_points > 100) then
			self:BankDriftPoints_SP(math.floor(self.m_points / 10))
		end

		if (self.m_points > self.m_player_best) then
			self.m_player_best = self.m_points
			GVars.features.vehicle.drift_minigame.player_best = self.m_points
			Notifier:ShowSuccess(_T("VEH_DRIFT_MINIGAME"), _T("VEH_DRIFT_MINIGAME_NEW_PB"))
		end

		sleep(3000)
		self.m_streak_text = ""
		self.m_points = 0
		self.m_extra_points = 0
		self.m_multiplier = 1
		self.m_is_active = false
	end
end

return DriftMinigame
