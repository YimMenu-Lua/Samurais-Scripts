-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local ssi        = stats.set_int
local sgi        = stats.get_int
local tsi        = tunables.set_int
local Heist      = require("includes.features.online.heist_editor.heists.heist_base")
local drawFuncs  = require("includes.frontend.heist_editor.heists.casino_heist_ui")
local SGSL       = require("includes.services.SGSL")
local heistData  = require("includes.data.heist_editor_data").CasinoHeistData
local eDataType  = Enums.eManagedValueDataType
local eValueType = Enums.eManagedValueType

---@nodiscard
---@return boolean
local function areSecondariesUnlocked()
	for _, pair in ipairs(heistData.secondary_objectives) do
		if (sgi(pair.first) ~= pair.second) then
			return false
		end
	end

	if (not stats.get_packed_stat_bool(26969)) then
		return false
	end

	return true
end


---@class CasinoHeistSetupData
---@field approach integer
---@field target integer
---@field last_approach integer
---@field hard_approach integer
---@field gunman integer
---@field driver integer
---@field hacker integer
---@field weapons integer
---@field cars integer
---@field masks integer


---@class CasinoHeist : Heist
---@field private m_boost_bit integer
---@field private m_player_cuts Int4
---@field private m_player_cuts_global ScriptGlobal
---@field private m_cart_grab_local ScriptLocal
---@field private m_scene_rate_local ScriptLocal
---@field private m_setup_data CasinoHeistSetupData
---@field private m_secondaries_unlocked boolean
---@field private m_property BasicProperty
local CasinoHeist   = setmetatable({}, Heist)
CasinoHeist.__index = CasinoHeist

---@param arcadeProperty BasicProperty
---@return CasinoHeist
function CasinoHeist.new(arcadeProperty)
	local base = Heist.new({
		name              = "CH_END_NAME",
		script_name       = "fm_mission_controller",
		property          = arcadeProperty,
		requires_property = true,
		boost_bit         = 8,
		gui_callback      = drawFuncs.main_callback,
		property_fail_msg = "CH_HLP_2",
		managed_values    = {
			["casino_heist_cooldown"] = {
				get_state = function()
					return GVars.features.dunk.disable_heist_cooldown
				end,
				defs = {
					{ t = "MPPLY_H3_COOLDOWN",     v = 0, obj_type = eValueType.STAT, data_type = eDataType.INT },
					{ t = "MPX_H3_COMPLETEDPOSIX", v = 0, obj_type = eValueType.STAT, data_type = eDataType.INT }
				}
			}
		}
	})


	local instance    = setmetatable(base, CasinoHeist) ---@cast instance CasinoHeist

	local FMMC_OBJ    = SGSL:Get(SGSL.data.fm_mission_controller_cart_grab)
	local GBCHP       = SGSL:Get(SGSL.data.gb_casino_heist_planning):AsGlobal()
	local CUTS_OBJ    = SGSL:Get(SGSL.data.gb_casino_heist_planning_cut_offset)

	local sceneLocal  = FMMC_OBJ:AsLocal()
	local rateOffset  = FMMC_OBJ:GetOffset(1)

	local cutsOffset1 = CUTS_OBJ:GetValue() -- 1497
	local cutsOffset2 = CUTS_OBJ:GetOffset(1) -- 736
	local cutsOffset3 = CUTS_OBJ:GetOffset(2) -- 92


	instance.m_player_cuts_global = GBCHP:At(cutsOffset1):At(cutsOffset2):At(cutsOffset3)
	instance.m_cart_grab_local    = sceneLocal
	instance.m_scene_rate_local   = sceneLocal:At(rateOffset)
	instance.DrawWhenActive       = drawFuncs.draw_teleports

	instance:Init()
	return instance
end

---@private
function CasinoHeist:Init()
	local playerCuts = self.m_player_cuts or {}
	local setupData  = self.m_setup_data or {}
	local rawData    = heistData.setup_data

	for i = 1, 4 do
		playerCuts[i] = 25
	end

	for key, data in pairs(rawData) do
		local stat_name = data.stat
		local value     = sgi(stat_name)
		local max_value = data.data_size - 1
		if (value > max_value) then
			value = 0
			ssi(stat_name, value)
		end
		setupData[key] = value
	end

	self.m_player_cuts          = playerCuts
	self.m_setup_data           = setupData
	self.m_secondaries_unlocked = areSecondariesUnlocked()
end

---@nodiscard
---@return boolean
function CasinoHeist:HasUnlockedSecondaries()
	return self.m_secondaries_unlocked
end

---@return CasinoHeistSetupData
function CasinoHeist:GetSetupData()
	return self.m_setup_data
end

---@return Int4
function CasinoHeist:GetPlayerCuts()
	return self.m_player_cuts
end

---@param reset? boolean
function CasinoHeist:SetSecondaries(reset)
	local unlocked = self.m_secondaries_unlocked
	if ((not reset and unlocked) or (reset and not unlocked)) then
		return
	end

	for _, pair in ipairs(heistData.secondary_objectives) do
		local v = reset and 0 or pair.second
		ssi(pair.first, v)
	end

	if (not reset) then
		stats.set_packed_stat_bool(26969, true) -- High Roller
		self.m_secondaries_unlocked = true
	else
		self.m_secondaries_unlocked = false
	end
end

---@param reset? boolean
function CasinoHeist:SetPlayerCuts(reset)
	local cuts = self.m_player_cuts
	local sg   = self.m_player_cuts_global
	if (reset) then
		for i = 1, 4 do
			cuts[i] = 25
			sg:At(i):WriteInt(25)
		end
	else
		for i, v in ipairs(cuts) do
			sg:At(i):WriteInt(v)
		end
	end
end

function CasinoHeist:SetCartAutoGrab()
	local sceneLocal = self.m_cart_grab_local
	local pbrLocal   = self.m_scene_rate_local
	local sceneState = sceneLocal:ReadInt()

	if (sceneState == 3) then
		sceneLocal:WriteInt(4)
	elseif (sceneState == 4 and pbrLocal:ReadFloat() ~= 2.0) then
		pbrLocal:WriteFloat(2.0)
	end
end

function CasinoHeist:Setup()
	local data    = self.m_setup_data
	local rawData = heistData.setup_data
	for k, v in pairs(rawData) do
		ssi(v.stat, data[k])
	end

	self:SetPlayerCuts()
	self:SetSecondaries()
end

function CasinoHeist:Reset()
	local data    = self.m_setup_data
	local rawData = heistData.setup_data
	for k, v in pairs(rawData) do
		data[k] = 0
		ssi(v.stat, 0)
	end

	self:SetPlayerCuts(true)
	self:SetSecondaries(true)
end

function CasinoHeist:Update()
	if (self.m_is_active) then
		self:SetCartAutoGrab()
	end

	-- ai cuts sometimes revert when you select the final board.
	-- this writes them again even though we avoid spamming memory writes pretty much everywhere in the project
	if (GVars.features.dunk.zero_ai_cuts and script.is_active("gb_casino_heist_planning")) then
		for _, v in ipairs(heistData.ai_cuts_tunables) do
			tsi(v, 0)
		end
		yield(500)
	end
end

return CasinoHeist
