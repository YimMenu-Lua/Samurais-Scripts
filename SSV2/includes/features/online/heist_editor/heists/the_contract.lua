-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Heist       = require("includes.features.online.heist_editor.heists.heist_base")
local missionData = require("includes.data.heist_editor_data").DrDreData
local sgi         = stats.get_int
local ssi         = stats.set_int
local eValueType  = Enums.eManagedValueType
local eDataType   = Enums.eManagedValueDataType
Translator:TranslateGXTList(missionData.missions)


---@class TheContract : Heist
---@field public m_current_bs uint8_t
---@field public m_none_unlocked boolean
local TheContract   = setmetatable({}, Heist)
TheContract.__index = TheContract

---@param apartment BasicProperty
---@return TheContract
function TheContract.new(apartment)
	local base = Heist.new({
		name              = "FIX_APP_VIP_TU",
		script_name       = "fm_mission_controller_2020",
		property          = apartment,
		requires_property = true,
		boost_bit         = 9,
		gui_callback      = require("includes.frontend.heist_editor.heists.the_contract_ui"),
		property_fail_msg = "FIX_FLOW_HLP0",
		managed_values    = {
			["dre_contract_cooldown"] = {
				get_state = function()
					return GVars.features.yim_heists.dre_cd
				end,
				defs = {
					{ t = "FIXER_STORY_COOLDOWN_POSIX", v = Time.Epoch() - 2629743, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT },
					{ t = "MPX_FIXER_STORY_COOLDOWN",   v = 0,                      obj_type = eValueType.STAT,     data_type = eDataType.INT },
				}
			}
		}
	})


	local instance        = setmetatable(base, TheContract) ---@cast instance TheContract
	instance.m_current_bs = sgi("MPX_FIXER_STORY_BS")

	instance:Init()
	return instance
end

function TheContract:Init()
	local bs      = sgi("MPX_FIXER_STORY_BS")
	local bs2     = sgi("MPX_FIXER_COMPLETED_BS")
	local highest = 0
	for i = 0, 11 do
		if (Bit.IsBitSet(bs, i)) then
			highest = i
		end
	end
	self.m_current_bs    = highest
	self.m_none_unlocked = not (Bit.IsBitSet(bs2, 0) and Bit.IsBitSet(bs2, 4)) -- bit 9 is payphone hits which are automatically unlocked when you buy an agency
end

---@return Int4
function TheContract:GetPlayerCuts()
	return self.m_player_cuts
end

---@param reset? boolean
function TheContract:SetProgression(reset)
	ssi("MPX_FIXER_STORY_BS", 0)
	if (reset) then
		ssi("MPX_FIXER_STORY_STRAND", 0)
		return
	end

	local selectedBs = self.m_current_bs
	local v = sgi("MPX_FIXER_STORY_BS")
	for i = 0, selectedBs do
		v = v | (1 << i)
	end
	ssi("MPX_FIXER_STORY_BS", v)

	local strand = 0
	if (math.is_inrange(selectedBs, 3, 5)) then
		strand = 1
	elseif (selectedBs > 5) then
		strand = 2
	end
	ssi("MPX_FIXER_STORY_STRAND", strand)
end

function TheContract:UnlockAllMissions()
	ssi("MPX_FIXER_COMPLETED_BS", -1)
	ssi("MPX_FIXER_GENERAL_BS", -1)
	ssi("MPX_FIXER_FIRST_TIME", 1)
	self.m_current_bs = 1
end

function TheContract:SkipPreps()
	self.m_current_bs = 11
end

function TheContract:Setup()
	self:SetProgression()
end

function TheContract:Reset()
	self.m_current_bs = 0
	self:SetProgression(true)
end

return TheContract
