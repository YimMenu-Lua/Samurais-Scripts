-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local sgi        = stats.get_int
local ssi        = stats.set_int
local sgb        = stats.get_bit
local Pair       = require("includes.classes.Pair")
local Heist      = require("includes.features.online.heist_editor.heists.heist_base")
local SGSL       = require("includes.services.SGSL")
local eDataType  = Enums.eManagedValueDataType
local eValueType = Enums.eManagedValueType


local actSetups <const> = {
	[0] = Pair(229383, 503),
	[1] = Pair(229378, 240),
	[2] = Pair(229380, 16368),
}
local actBoostBits <const> = {
	[0] = 5,
	[1] = 6,
	[2] = 7,
}


---@class GangOps : Heist
---@field private m_player_cuts Int4
---@field private m_player_cuts_global ScriptGlobal
---@field private m_property? BasicProperty
---@field public m_current_act integer
local GangOps   = setmetatable({}, Heist)
GangOps.__index = GangOps

---@param facilityProperty BasicProperty
---@return GangOps
function GangOps.new(facilityProperty)
	local base = Heist.new({
		name              = "DLCC_DOOMS",
		script_name       = "fm_mission_controller",
		property          = facilityProperty,
		requires_property = true,
		gui_callback      = require("includes.frontend.heist_editor.heists.gangops_ui"),
		property_fail_msg = "GOPS_BASE_HELP",
		managed_values    = {
			["doomsday_heist_cooldown"] = {
				get_state = function()
					return GVars.features.yim_heists.dday_cd
				end,
				defs = {
					{ t = "MPX_GANGOPS_LAUNCH_TIME", v = Time.Epoch() - 2629743, obj_type = eValueType.STAT, data_type = eDataType.INT },
				}
			}
		}
	})


	local instance                = setmetatable(base, GangOps) ---@cast instance GangOps
	local CUTS_OBJ                = SGSL:Get(SGSL.data.gb_gang_ops_planning_player_cuts)
	local cutsOffset1             = CUTS_OBJ:GetOffset(1) -- 812
	local cutsOffset2             = CUTS_OBJ:GetOffset(2) -- 50
	instance.m_player_cuts_global = CUTS_OBJ:AsGlobal():At(cutsOffset1):At(cutsOffset2)

	instance:Init()
	return instance
end

---@protected
function GangOps:Init()
	self.m_current_act = self:GetCurrentAct()
	local playerCuts   = self.m_player_cuts or {}
	for i = 1, 4 do
		playerCuts[i] = 25
	end; self.m_player_cuts = playerCuts
end

---@override
---@nodiscard
---@return boolean
function GangOps:CanBeBoosted()
	return self.m_current_act ~= -1
end

---@override
---@nodiscard
---@return boolean
function GangOps:IsBoosted()
	local bitPos = actBoostBits[self.m_current_act]
	if (not bitPos) then
		return false
	end

	if (self:IsWeeklyBoostDisabledImpl(bitPos)) then
		return false
	end

	return sgb("MPX_WEEKLY_BOOST_BS", bitPos) == 0
end

---@private
---@return integer
function GangOps:GetCurrentAct()
	local v = sgi("MPX_GANGOPS_HEIST_STATUS")
	for i = 0, 2 do
		if (Bit.IsBitSet(v, i)) then
			return i
		end
	end
	return -1
end

---@return Int4
function GangOps:GetPlayerCuts()
	return self.m_player_cuts
end

---@param reset? boolean
function GangOps:SetPlayerCuts(reset)
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

function GangOps:Setup()
	local pair = actSetups[self.m_current_act]
	if (not pair) then
		return
	end

	ssi("MPX_GANGOPS_HEIST_STATUS", pair.first)
	ssi("MPX_GANGOPS_FLOW_MISSION_PROG", pair.second)
	ssi("MPX_GANGOPS_FLOW_NOTIFICATIONS", 1557)
end

-- function GangOps:Reset()
-- TODO: follow the trail of calling Lester to cancel the heist and redo it here.
-- preferably find and call a script function if possible otherwise replicate whatever the game does.
-- end

return GangOps
