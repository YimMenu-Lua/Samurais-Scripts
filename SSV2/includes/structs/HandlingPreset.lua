-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CARS_BIT <const>        = Enums.eVehicleType.VEHICLE_TYPE_CAR
local RESERVED_NAMES <const>  = {}
local DEFAULT_PRESETS <const> = require("includes.data.handling_presets")
for _, preset in pairs(DEFAULT_PRESETS) do
	RESERVED_NAMES[preset.name] = true
end

---@type table<string, { onEnable: fun(editor: HandlingEditor), onDisable: fun(editor: HandlingEditor) }>
local PRESET_CALLBACKS <const> = {
	["VEH_KERS_BOOST"] = {
		onEnable = function(_)
			local PV = LocalPlayer:GetVehicle()
			if (not PV:IsValid()) then return end
			VEHICLE.SET_VEHICLE_KERS_ALLOWED(PV:GetHandle(), true)
		end,
		onDisable = function(_)
			local PV = LocalPlayer:GetVehicle()
			if (not PV:IsValid()) then return end
			VEHICLE.SET_VEHICLE_KERS_ALLOWED(PV:GetHandle(), false)
		end
	},
	["VEH_ROCKET_BOOST"] = {
		onEnable  = function(_) Game.RequestNamedPtfxAsset("VEH_IMPEXP_ROCKET") end,
		onDisable = function(_) STREAMING.REMOVE_NAMED_PTFX_ASSET("VEH_IMPEXP_ROCKET") end
	},
	["VEH_JUMP"] = {
		onEnable  = function(_)
			local PV = LocalPlayer:GetVehicle()
			if (not PV:IsValid()) then return end
			VEHICLE.SET_USE_HIGHER_CAR_JUMP(PV:GetHandle(), true)
		end,
		onDisable = function(_)
			local PV = LocalPlayer:GetVehicle()
			if (not PV:IsValid()) then return end
			VEHICLE.SET_USE_HIGHER_CAR_JUMP(PV:GetHandle(), false)
		end
	},
}

---@param json boolean
---@return table<eHandlingEditorTypes, table<string, boolean>>
local function NormalizeDeltas(deltas, json)
	-- FUCKIONG JSON!!!!!!!!!!!!!!!!!!
	local d = {}
	local f = json and tostring or tonumber
	for hFlag, tData in pairs(deltas) do
		d[f(hFlag)] = tData
	end
	return d
end

---@class HandlingPresetData
---@field name string
---@field deltas table<eHandlingEditorTypes, table<string, boolean>>
---@field auto_apply? boolean
---@field allowed_vehicle_types? integer -- bitset of eVehicleType (cars and bikes only)
---@field is_translator_name? boolean
---@field is_user_generated? boolean
---@field is_default_preset? boolean
---@field description? string

---@class HandlingPreset
---@field private m_name string
---@field private m_description? string
---@field private m_is_translator_name boolean
---@field private m_cached_flags array<Pair<string, boolean>>
---@field private m_is_default_preset boolean
---@field private m_is_user_generated boolean
---@field public m_deltas table<eHandlingEditorTypes, table<string, boolean>>
---@field public m_veh_types_bs integer -- bitset of eVehicleType (cars and bikes only)
---@field public auto_apply boolean
---@field public OnEnable? fun(editor: HandlingEditor): any
---@field public OnDisable? fun(editor: HandlingEditor): any
local HandlingPreset <const> = { m_deltas = {} }
HandlingPreset.__index       = HandlingPreset

---@param data HandlingPresetData
---@return HandlingPreset
function HandlingPreset.new(data)
	local name      = data.name
	local callbacks = PRESET_CALLBACKS[name]
	return setmetatable({
		m_name               = name,
		m_deltas             = NormalizeDeltas(data.deltas, false),
		m_veh_types_bs       = data.allowed_vehicle_types or (1 << CARS_BIT),
		m_is_translator_name = data.is_translator_name or false,
		auto_apply           = data.auto_apply or false,
		m_is_user_generated  = data.is_user_generated or false,
		m_is_default_preset  = RESERVED_NAMES[name],
		m_description        = data.description,
		OnEnable             = callbacks and callbacks.onEnable or nil,
		OnDisable            = callbacks and callbacks.onDisable or nil,
	}, HandlingPreset)
end

---@return boolean
function HandlingPreset:IsDefault()
	return self.m_is_default_preset or not self.m_is_user_generated
end

---@return string
function HandlingPreset:GetName()
	return self.m_name
end

---@return string
function HandlingPreset:GetDisplayName()
	if (not self.m_is_user_generated and self.m_is_translator_name) then
		return _T(self.m_name)
	end
	return self.m_name
end

---@return string?
function HandlingPreset:GetDescription()
	local desc = self.m_description
	if (not desc) then return end

	if (not self.m_is_user_generated and self.m_is_translator_name) then
		return _T(desc)
	end
	return desc
end

---@return array<Pair<string, boolean>>
function HandlingPreset:GetAssociatedFlags()
	if (not self.m_cached_flags) then
		local temp = {}
		for _, data in pairs(self.m_deltas) do
			for name, bool in pairs(data) do
				table.insert(temp, Pair.new(name, bool))
			end
		end
		self.m_cached_flags = temp
	end

	return self.m_cached_flags
end

function HandlingPreset:Copy()
	return HandlingPreset.Deserialize(self:Serialize())
end

function HandlingPreset:Serialize()
	return {
		name                  = self.m_name,
		deltas                = NormalizeDeltas(self.m_deltas, true),
		allowed_vehicle_types = self.m_veh_types_bs,
		auto_apply            = self.auto_apply,
		description           = self.m_description,
		is_translator_name    = self.m_is_translator_name,
		is_user_generated     = self.m_is_user_generated,
		is_default_preset     = self.m_is_default_preset,
	}
end

--#region static funcs

---@param name string
---@return boolean
function HandlingPreset.IsNameReserved(name)
	return RESERVED_NAMES[name]
end

---@param data HandlingPresetData
---@return HandlingPreset
function HandlingPreset.Deserialize(data)
	return setmetatable({
		m_name               = data.name,
		m_description        = data.description,
		m_deltas             = NormalizeDeltas(data.deltas, false),
		m_veh_types_bs       = data.allowed_vehicle_types or CARS_BIT,
		auto_apply           = data.auto_apply or false,
		m_is_translator_name = data.is_translator_name,
		m_is_default_preset  = data.is_default_preset,
		m_is_user_generated  = data.is_user_generated or not data.is_default_preset or not RESERVED_NAMES[data.name],
	}, HandlingPreset)
end

--#endregion

return HandlingPreset
