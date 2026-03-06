-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FeatureBase              = require("includes.modules.FeatureBase")
local MultiplierStages <const> = {
	{ mult = 1,  threshold = { min = 1500, max = 2999 } },
	{ mult = 2,  threshold = { min = 3000, max = 5999 } },
	{ mult = 5,  threshold = { min = 6000, max = 11999 } },
	{ mult = 10, threshold = { min = 12000, max = math.int32_max() } },
}


---@class DriftMinigame : FeatureBase
---@field private m_entity PlayerVehicle
---@field private m_is_active boolean
---@field private m_points integer
---@field private m_extra_points integer
---@field private m_multiplier integer
---@field private m_multiplier_threshold integer
---@field private m_straight_counter integer
---@field private m_streak_text string
---@field private m_extra_text string
---@field private m_player_best integer
---@field private m_extra_text_time integer
---@field private m_text_height float
---@field private m_has_crashed boolean
---@field private m_text_color Color
---@field private m_bank_timer Timer
---@field private m_game_timer number
local DriftMinigame   = setmetatable({}, FeatureBase)
DriftMinigame.__index = DriftMinigame

---@param pv PlayerVehicle
---@return DriftMinigame
function DriftMinigame.new(pv)
	local self = FeatureBase.new(pv)
	---@diagnostic disable-next-line
	return setmetatable(self, DriftMinigame)
end

function DriftMinigame:Init()
	self.m_is_active            = false
	self.m_has_crashed          = false
	self.m_points               = 0
	self.m_extra_points         = 0
	self.m_multiplier           = 1
	self.m_multiplier_threshold = 0
	self.m_straight_counter     = 0
	self.m_extra_text_time      = 0
	self.m_text_height          = 0.7
	self.m_streak_text          = ""
	self.m_extra_text           = ""
	self.m_player_best          = GVars.features.vehicle.drift_minigame.player_best
	self.m_text_color           = Color(255, 192, 0, 200)
	self.m_bank_timer           = Timer.new(5e3)
	self.m_game_timer           = 0
end

function DriftMinigame:Cleanup()
	self.m_is_active            = false
	self.m_has_crashed          = false
	self.m_points               = 0
	self.m_extra_points         = 0
	self.m_multiplier           = 1
	self.m_multiplier_threshold = 0
	self.m_straight_counter     = 0
	self.m_extra_text_time      = 0
	self.m_text_height          = 0.7
	self.m_streak_text          = ""
	self.m_extra_text           = ""
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
		if (math.is_inrange(self.m_multiplier_threshold, v.threshold.min, v.threshold.max)) then
			return v.mult
		end
	end

	return 1
end

function DriftMinigame:SetMultiplierPenalty()
	if (self.m_multiplier == 1) then
		return
	end

	for i = #MultiplierStages, 2, -1 do
		local curr_stage = MultiplierStages[i]
		local prev_stage = MultiplierStages[i - 1]
		if (self.m_multiplier == curr_stage.mult) then
			self.m_multiplier_threshold = prev_stage.threshold.min
			self.m_multiplier           = prev_stage.mult
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
		self.m_extra_text_time = self.m_game_timer + 3000
		self:SetMultiplierPenalty()
		sleep(250)
		return
	end

	self.m_extra_text  = ""
	self.m_text_height = 0.7
	self.m_streak_text = _T("VEH_DRIFT_MINIGAME_STREAK_LOST")

	sleep(3000)
	self:Cleanup()
end

function DriftMinigame:DrawText()
	local txt = _F("%s\n+%s pts", self.m_streak_text, string.formatint(self.m_points))
	if (self.m_has_crashed and self.m_multiplier == 1) then
		txt = self.m_streak_text
	end

	Game.DrawText(
		vec2:new(0.5, 0.03),
		txt,
		self.m_text_color,
		vec2:new(1, self.m_text_height),
		7,
		true
	)
end

function DriftMinigame:DrawExtraText()
	if (self.m_extra_text == "") then
		return
	end

	if (self.m_game_timer >= self.m_extra_text_time) then
		self.m_extra_text      = ""
		self.m_extra_text_time = 0
		return
	end

	Game.DrawText(
		vec2:new(0.5, 0.12),
		self.m_extra_text,
		self.m_text_color,
		vec2:new(1, 0.4),
		7,
		true
	)
end

function DriftMinigame:Update()
	if (not self.m_is_active) then
		return
	end

	self.m_game_timer = Game.GetGameTimer()

	if (self.m_points == 0) then
		return
	end

	self:DrawText()
	self:DrawExtraText()
end

function DriftMinigame:OnTick()
	yield()

	if (not self:ShouldRun()) then
		return
	end

	local playerVehicle = self.m_entity
	if (self.m_is_active and (not LocalPlayer:IsDriving() or playerVehicle:GetCurrentGear() < 1)) then
		self:ResetStreak(true)
		return
	end

	local handle                 = playerVehicle:GetHandle()
	local speedVec               = playerVehicle:GetSpeedVector()
	local speed                  = playerVehicle:GetSpeed()
	local height                 = playerVehicle:GetHeightAboveGround()
	local angle                  = math.abs(speedVec.x)
	local bonusTxt               = ""
	local angleTxt               = ""
	local baseBonus              = 1
	local angleBonus             = 1
	self.m_has_crashed, bonusTxt = playerVehicle:HasCrashed()

	if (VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(handle) and angle >= 6) then
		self.m_is_active        = true
		self.m_text_height      = 0.7
		self.m_straight_counter = 0
		self:PlayIncrementSound()
	end

	if (angle > 15) then
		angleTxt   = "VEH_DRIFT_MINIGAME_SICK_ANGLE"
		angleBonus = 10
	elseif (angle > 12) then
		angleTxt   = "VEH_DRIFT_MINIGAME_BIG_ANGLE"
		angleBonus = 5
	else
		angleTxt   = "VEH_DRIFT_MINIGAME_DRIFT_LABEL"
		angleBonus = 1
	end

	if (angle < 2 and not playerVehicle:IsStopped()) then
		self.m_straight_counter = self.m_straight_counter + 1
	else
		self.m_straight_counter = 0
	end

	if (self.m_straight_counter == 0 and self.m_is_active) then
		self.m_multiplier_threshold = self.m_multiplier_threshold + (speed // 10)
	end

	if (speed > 5 and not self.m_has_crashed) then
		if (height > 1) then
			if (height < 5) then
				bonusTxt = "VEH_DRIFT_MINIGAME_AIR"
			elseif (height >= 5) then
				bonusTxt = "VEH_DRIFT_MINIGAME_BIG_AIR"
				baseBonus = 5
			end
		end

		if (not bonusTxt:isempty()) then
			self.m_extra_points    = self.m_extra_points + baseBonus
			self.m_extra_text      = _F("%s  +%d", bonusTxt, self.m_extra_points)
			self.m_extra_text_time = self.m_game_timer + 3000
		end
	end

	self.m_multiplier  = self:GetMultiplier()
	self.m_streak_text = _F("%s   x%d", _T(angleTxt), self.m_multiplier)
	self.m_points      = self.m_points + self.m_extra_points + (angleBonus * self.m_multiplier)

	if (self.m_has_crashed) then
		if (self.m_multiplier < 2) then
			self.m_streak_text = bonusTxt
		end
		self:ResetStreak()
	elseif (self.m_straight_counter > 100 or playerVehicle:IsStopped()) then
		self.m_bank_timer:Reset(5e3)
		while (not self.m_bank_timer:IsDone()) do
			if (not LocalPlayer:IsDriving()) then
				self:ResetStreak(true)
				return
			end

			if (self.m_is_active or ENTITY.HAS_ENTITY_COLLIDED_WITH_ANYTHING(handle)) then
				return
			end

			self.m_text_height = 0.67 + 0.03 * math.sin(Game.GetGameTimer() / 120)
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
		self:Cleanup()
	end
end

return DriftMinigame
