-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local Heist = require("includes.features.online.heist_editor.heists.heist_base")
local Pair  = require("includes.classes.Pair")
local SGSL  = require("includes.services.SGSL")
local sgi   = stats.get_int
local ssi   = stats.set_int
local tgi   = tunables.get_int
local sco   = 52


---@class HeistStrand
---@field gxt GXT
---@field root_data Pair<string, joaat_t>
---@field int_index integer


---```c
---ePedComponentType func_8565(int iParam0) // Position - 0x29F3EF (2749423)
---```
---@type array<HeistStrand>
local heistData <const> = {
	{ gxt = "HTITLE_TUT",    int_index = 0, root_data = Pair("MPX_HEIST_SAVED_STRAND_0", tgi("ROOT_ID_HASH_THE_FLECCA_JOB")) },
	{ gxt = "HTITLE_PRISON", int_index = 1, root_data = Pair("MPX_HEIST_SAVED_STRAND_1", tgi("ROOT_ID_HASH_THE_PRISON_BREAK")) },
	{ gxt = "HTITLE_HUMANE", int_index = 2, root_data = Pair("MPX_HEIST_SAVED_STRAND_2", tgi("ROOT_ID_HASH_THE_HUMANE_LABS_RAID")) },
	{ gxt = "HTITLE_NARC",   int_index = 3, root_data = Pair("MPX_HEIST_SAVED_STRAND_3", tgi("ROOT_ID_HASH_SERIES_A_FUNDING")) },
	{ gxt = "HTITLE_ORNATE", int_index = 4, root_data = Pair("MPX_HEIST_SAVED_STRAND_4", tgi("ROOT_ID_HASH_THE_PACIFIC_STANDARD_JOB")) },
}

---@class ApartmentHeist : Heist
---@field private m_content_id_global ScriptGlobal
---@field private m_player_cuts Int4
---@field private m_apt_board_state_global ScriptGlobal
---@field private m_player_cuts_global_1 ScriptGlobal
---@field private m_player_cuts_global_2 ScriptGlobal
---@field private m_strand_list array<HeistStrand>
---@field public m_current_strand? HeistStrand
local ApartmentHeist    = setmetatable({}, Heist)
ApartmentHeist.__index  = ApartmentHeist

---@param apartment BasicProperty
---@return ApartmentHeist
function ApartmentHeist.new(apartment)
	local base = Heist.new({
		name              = "YH_APT_HEISTS_LABEL",
		script_name       = "fm_mission_controller",
		property          = apartment,
		requires_property = false, -- TODO (I really don't feel like scraping decompiled noodles for apartment data)
		gui_callback      = require("includes.frontend.heist_editor.heists.og_heists_ui"),
		property_fail_msg = "DLCC_HEIST_H",
		managed_values    = {
			["apartment_heist_cooldown"] = {
				get_state = function()
					return false
				end,
				defs = {
					-- { t = "MPX_GANGOPS_LAUNCH_TIME", v = Time.Epoch() - 2629743, obj_type = eValueType.STAT, data_type = eDataType.INT },
				}
			}
		}
	})


	local instance        = setmetatable(base, ApartmentHeist) ---@cast instance ApartmentHeist
	local CUTS_1_OBJ      = SGSL:Get(SGSL.data.og_heists_player_cuts_global_1)
	local CUTS_2_OBJ      = SGSL:Get(SGSL.data.og_heists_player_cuts_global_2)
	local CONTENT_ID_OBJ  = SGSL:Get(SGSL.data.jobs_root_content_id_global); sco = CONTENT_ID_OBJ:GetOffset(1)
	local BOARD_STATE_OBJ = SGSL:Get(SGSL.data.apt_heist_board_state_global)
	local cuts2Offset     = CUTS_2_OBJ:GetOffset(1)


	instance.m_player_cuts_global_1   = CUTS_1_OBJ:AsGlobal():At(1)
	instance.m_player_cuts_global_2   = CUTS_2_OBJ:AsGlobal():At(cuts2Offset)
	instance.m_content_id_global      = CONTENT_ID_OBJ:AsGlobal()
	instance.m_apt_board_state_global = BOARD_STATE_OBJ:AsGlobal()
	instance.m_player_cuts            = { 25, 25, 25, 25 }

	instance:Init()
	return instance
end

function ApartmentHeist:Init()
	local cuts = self.m_player_cuts or {}
	for i = 1, 4 do
		cuts[i] = 25
	end; self.m_player_cuts = cuts

	self:RebuildStrandList()
end

function ApartmentHeist:RebuildStrandList()
	self.m_current_strand = nil
	local rcid            = self.m_content_id_global:ReadInt()
	local lst             = self.m_strand_list or {}
	for i, strand in ipairs(heistData) do
		local data = strand.root_data
		local hash = data.second
		lst[i]     = strand
		if (hash == rcid) then
			self.m_current_strand = strand
		end
	end; self.m_strand_list = lst
end

---@return Int4
function ApartmentHeist:GetPlayerCuts()
	return self.m_player_cuts
end

---@return array<HeistStrand>
function ApartmentHeist:GetStrandList()
	return self.m_strand_list
end

---@param reset? boolean
function ApartmentHeist:SetCurrentStrand(reset)
	local scriptGlobal = self.m_content_id_global
	reset = reset or self.m_current_strand == nil
	if (reset) then
		ssi("MPX_CURRENT_HEIST_STRAND", 0)
		scriptGlobal:WriteInt(0)
		return
	end

	local strand = self.m_current_strand
	if (not strand) then return end

	local data      = strand.root_data
	local currentID = scriptGlobal:ReadInt()
	local targetID  = data.second

	if (currentID ~= targetID) then
		scriptGlobal:WriteInt(targetID)
	end

	local statName = data.first
	local isLocked = (sgi(data.first) ~= targetID)
	if (isLocked) then
		ssi(statName, targetID)
		ssi(statName .. "_L", 5) -- num times finished as leader (included in ShinyWasabi's UnlockEverything)
	end

	ssi("MPX_CURRENT_HEIST_STRAND", strand.int_index)
end

function ApartmentHeist:FixPlayerCuts()
	local cuts = self.m_player_cuts
	local sum  = math.sum(cuts)
	if (sum > 100) then
		local diff = sum - 100
		local largest, index = 0, 1
		for i, v in ipairs(cuts) do
			if (v > largest) then
				largest, index = v, i
			end
		end

		if (largest ~= 0) then
			cuts[index] = largest - diff
		end
	end
end

---@param reset? boolean
function ApartmentHeist:SetPlayerCuts(reset)
	local cuts = self.m_player_cuts
	if (not reset) then
		self:FixPlayerCuts()
	else
		for i = 1, 4 do
			cuts[i] = 25
		end
	end

	-- This part was shamelessly pasted from YimMenuV2
	-- My head hurts from looking at decompiled spaghetti...

	local base1 = self.m_player_cuts_global_1
	local base2 = self.m_player_cuts_global_2

	base1:At(0, 1):WriteInt(100 - (cuts[1] + cuts[2] + cuts[3] + cuts[4]))
	for i = 1, 3 do
		base2:At(i, 1):WriteInt(cuts[i + 1])
	end

	yield(500)

	local temp = {
		base1:At(0, 1):ReadInt(),
		base1:At(1, 1):ReadInt(),
		base1:At(2, 1):ReadInt(),
		base1:At(3, 1):ReadInt(),
	}

	base2:At(0, 1):WriteInt(100 - math.sum(temp))

	for i = 1, 3 do
		base2:At(i, 1):WriteInt(temp[i + 1])
	end
end

function ApartmentHeist:SkipPreps()
	ssi("MPX_HEIST_PLANNING_STAGE", -1)
end

function ApartmentHeist:Setup()
	self:SetPlayerCuts()
	-- self:SetCurrentStrand()
	-- self.m_apt_board_state_global:WriteInt(6)
end

function ApartmentHeist:Reset()
	self:SetPlayerCuts(true)
	-- self:SetCurrentStrand(true)
	-- self.m_apt_board_state_global:WriteInt(0)
	-- self.m_current_strand = nil
	ssi("MPX_HEIST_PLANNING_STAGE", 0)
end

return ApartmentHeist
