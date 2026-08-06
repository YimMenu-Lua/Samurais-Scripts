-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local ssi                          = stats.set_int
local sfb                          = stats.flip_bit
local sgi                          = stats.get_int
local sgb                          = stats.get_bit
local Heist                        = require("includes.features.online.heist_editor.heists.heist_base")
local SGSL                         = require("includes.services.SGSL")
local heistData                    = require("includes.data.heist_editor_data").CayoPericoData
local drawFuncs                    = require("includes.frontend.heist_editor.heists.h4_ui")
local eDataType                    = Enums.eManagedValueDataType
local eValueType                   = Enums.eManagedValueType
local gpbgObject                   = SGSL:Get(SGSL.data.gpbd)
local GPBD <const>                 = gpbgObject:AsGlobal()
local KosatkaRequestGlobal <const> = SGSL:Get(SGSL.data.request_services_global):AsGlobal():At(613)
local pidSize                      = gpbgObject:GetOffset(1)
local offset2                      = gpbgObject:GetOffset(2)
local subOffset                    = 4


---@class VehicleProperty
---@field name string GXT
---@field is_spawned boolean
---@field coords vec3
---@field heading float

---@class CayoPrericoSetupData
---@field primary_target integer
---@field weapons integer
---@field supply_truck_loc integer


---@class CayoPericoHeist : Heist
---@field private m_owns_kosatka boolean
---@field private m_last_sub_check_time TimePoint
---@field private m_setup_data CayoPrericoSetupData
---@field private m_player_cuts Int4
---@field private m_player_cuts_global ScriptGlobal
---@field private m_kosatka? VehicleProperty
---@field m_kosatka_global ScriptGlobal
local CayoPericoHeist   = setmetatable({}, Heist)
CayoPericoHeist.__index = CayoPericoHeist

---@return CayoPericoHeist
function CayoPericoHeist.new()
	local base = Heist.new({
		name              = "DLCC_ISLAN",
		script_name       = "fm_mission_controller_2020",
		requires_property = true,
		gui_callback      = drawFuncs.main_callback,
		custom_header_cb  = drawFuncs.header_callback,
		managed_values    = {
			["cayo_perico_heist_cooldown"] = {
				get_state = function() return GVars.features.yim_heists.cayo_cd end,
				defs      = {
					{ t = "MPX_H4_COOLDOWN",       v = 0, obj_type = eValueType.STAT,     data_type = eDataType.INT },
					{ t = "MPX_H4_COOLDOWN_HARD",  v = 0, obj_type = eValueType.STAT,     data_type = eDataType.INT },
					{ t = "MPPLY_H4_COOLDOWN",     v = 0, obj_type = eValueType.STAT,     data_type = eDataType.INT },
					{ t = "H4_COOLDOWN_TIME",      v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT },
					{ t = "H4_COOLDOWN_HARD_TIME", v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT },
					{ t = "H4_SOLO_COOLDOWN",      v = 0, obj_type = eValueType.TUNEABLE, data_type = eDataType.INT },
				},
			},
		}
	})


	local instance     = setmetatable(base, CayoPericoHeist) ---@cast instance CayoPericoHeist
	local owns_kosatka = sgi("MPX_IH_SUB_OWNED") == _J("kosatka")
	local HIP          = SGSL:Get(SGSL.data.cayo_perico_player_cut_global):AsGlobal()
	local obj          = SGSL:Get(SGSL.data.cayo_perico_player_cut_offsets)
	local cuts_offset1 = obj:GetValue() -- 831
	local cuts_offset2 = obj:GetOffset(1) -- 56


	instance.m_player_cuts_global  = HIP:At(cuts_offset1):At(cuts_offset2)
	instance.m_kosatka_global      = GPBD:At(LocalPlayer:GetID(), pidSize):At(offset2)
	instance.m_last_sub_check_time = TimePoint()

	if (owns_kosatka) then
		instance.m_kosatka = {
			name       = "CELL_SUBMARINE",
			is_spawned = false,
			coords     = vec3:zero(),
			heading    = 0.0,
		}
	end

	instance:Init()
	return instance
end

function CayoPericoHeist:Init()
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

	self.m_player_cuts = playerCuts
	self.m_setup_data  = setupData
end

---@return VehicleProperty?
function CayoPericoHeist:GetProperty()
	return self.m_kosatka
end

---@return CayoPrericoSetupData
function CayoPericoHeist:GetSetupData()
	return self.m_setup_data
end

---@return Int4
function CayoPericoHeist:GetPlayerCuts()
	return self.m_player_cuts
end

---@nodiscard
---@return boolean
function CayoPericoHeist:GetKosatkaRequestState()
	return KosatkaRequestGlobal:ReadInt() == 1
end

---@return vec3 coords, float heading
function CayoPericoHeist:GetKosatkaCoordsAndHeading()
	if (not self.m_kosatka.is_spawned) then
		return vec3:zero(), 0.0
	end

	local _g = self.m_kosatka_global:At(13)
	return _g:ReadVec3(), _g:At(3):ReadFloat()
end

function CayoPericoHeist:RequestKosatka()
	if (KosatkaRequestGlobal:ReadInt() == 1) then
		return
	end
	KosatkaRequestGlobal:WriteInt(1)
end

---@param reset? boolean
function CayoPericoHeist:SetPlayerCuts(reset)
	local sg   = self.m_player_cuts_global
	local cuts = self.m_player_cuts
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

---@param reset? boolean
function CayoPericoHeist:SetSecondaries(reset)
	for _, pair in ipairs(heistData.secondary_objectives) do
		local v = reset and 0 or pair.second
		ssi(pair.first, v)
	end
end

function CayoPericoHeist:Setup()
	local data    = self.m_setup_data
	local rawData = heistData.setup_data
	for k, v in pairs(rawData) do
		ssi(v.stat, data[k])
	end

	self:SetPlayerCuts()
	self:SetSecondaries()
end

function CayoPericoHeist:Reset()
	local data = self.m_setup_data
	for k, v in pairs(heistData.setup_data) do
		data[k] = 0
		ssi(v.stat, 0)
	end

	self:SetPlayerCuts(true)
	self:SetSecondaries(true)
	stats.toggle_bit("MPX_H4_PROGRESS", 12, false)
end

---@return boolean
function CayoPericoHeist:IsOnHardMode()
	return sgb("MPX_H4_PROGRESS", 12) ~= 0
end

function CayoPericoHeist:ToggleHardMode()
	sfb("MPX_H4_PROGRESS", 12)
end

function CayoPericoHeist:Update()
	local kosatka = self.m_kosatka
	if (not kosatka) then
		return
	end

	if (not self.m_last_sub_check_time:HasElapsed(2000)) then
		return
	end

	local is_kosatka_spawned        = self.m_kosatka_global:At(subOffset):GetBit(31) ~= 0
	kosatka.is_spawned              = is_kosatka_spawned
	kosatka.coords, kosatka.heading = self:GetKosatkaCoordsAndHeading()
end

return CayoPericoHeist
