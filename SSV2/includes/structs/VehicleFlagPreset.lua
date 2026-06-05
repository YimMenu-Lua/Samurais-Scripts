-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@type dict<set<string>>
local BAD_CALLBACKS <const>     = {}
local CARS_BIT <const>          = Enums.eVehicleType.VEHICLE_TYPE_CAR
local DEFAULT_PRESETS <const>   = require("includes.data.vehicle_flag_presets")
local DEFAULT_CALLBACKS <const> = require("includes.data.vehicle_flag_preset_callbacks")
local Pair                      = require("includes.classes.Pair")
local RESERVED_NAMES <const>    = {}
for _, preset in pairs(DEFAULT_PRESETS) do
	RESERVED_NAMES[preset.name] = true
end

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

---@param name string
---@param data VehicleFlagPresetData
---@return VehicleFlagCallbackData? data, string? filename
local function load_callbacks_for_preset(name, data)
	if (RESERVED_NAMES[name]) then
		return DEFAULT_CALLBACKS[name]
	end

	local filename = data.callback_defs_filename
	if (type(filename) ~= "string") then
		return
	end

	local ok, res = pcall(require, data.callback_defs_filename)
	if (not ok) then
		log.fwarning("Custom Handling Presets: Failed to load callback file: %s", tostring(res))
		return
	end

	local data_type = type(res)
	if (data_type ~= "table") then
		log.fwarning("Custom Handling Presets: Invalid data type. Expected table, got %s instead.", data_type)
		return
	end

	---@cast res dict<VehicleFlagCallbackData>
	local out = res[name]
	if (not out) then
		log.fwarning("Custom Handling Presets: The provided file does not contain any callback definitions for a preset with name '%s'.", name)
	end

	if (out and not (type(out.onEnable) == "function" or type(out.onDisable) == "function")) then
		log.fwarning([[Custom Handling Presets: The provided file does not define any of the expected functions.
Either one or both of these table keys must exist with these exact names: onEnable | onDisable.
Please refer to "includes/data/handling_preset_callbacks.lua" for table structure example.]])
	end

	return out, filename
end


---@class VehicleFlagPresetData
---@field name string
---@field deltas table<eHandlingEditorTypes, table<string, boolean>>
---@field auto_apply? boolean
---@field vehicle_bitset? integer -- bitset of eVehicleType (cars and bikes only)
---@field is_translator_name? boolean
---@field is_user_generated? boolean
---@field is_default_preset? boolean
---@field description? string
---@field callback_defs_filename? string


---@class VehicleFlagPreset : Callable<VehicleFlagPreset>
---@field private m_name string
---@field private m_description? string
---@field private m_is_translator_name boolean
---@field private m_cached_flags array<Pair<string, boolean>>
---@field private m_is_default_preset boolean
---@field private m_is_user_generated boolean
---@field private m_on_enable_callback? fun(self: VehicleFlagPreset, editor: VehicleFlagController): any
---@field private m_on_disable_callback? fun(self: VehicleFlagPreset, editor: VehicleFlagController): any
---@field public m_callback_defs_filename string
---@field public m_deltas table<eHandlingEditorTypes, table<string, boolean>>
---@field public m_vehicle_bitset integer -- bitset of eVehicleType (cars and bikes only)
---@field public m_category string
---@field public auto_apply boolean
---@overload fun(data: VehicleFlagPresetData) : VehicleFlagPreset
local VehicleFlagPreset <const> = Callable("VehicleFlagPreset", {
	ctor = function(self, ...)
		return self.new(...)
	end
})

---@param data VehicleFlagPresetData
---@return VehicleFlagPreset
function VehicleFlagPreset.new(data)
	local name                = data.name
	local is_default          = RESERVED_NAMES[name]
	local callbacks, filename = load_callbacks_for_preset(name, data)
	return MakeInstance({
		m_name                   = name,
		m_deltas                 = NormalizeDeltas(data.deltas, false),
		m_vehicle_bitset         = data.vehicle_bitset or (1 << CARS_BIT),
		m_is_translator_name     = data.is_translator_name or false,
		auto_apply               = data.auto_apply or false,
		m_is_user_generated      = data.is_user_generated or false,
		m_is_default_preset      = is_default,
		m_description            = data.description,
		m_on_enable_callback     = callbacks and callbacks.onEnable or nil,
		m_on_disable_callback    = callbacks and callbacks.onDisable or nil,
		m_callback_defs_filename = not is_default and filename or nil,
	}, VehicleFlagPreset)
end

---@return boolean
function VehicleFlagPreset:IsDefault()
	return self.m_is_default_preset == true
end

---@return string
function VehicleFlagPreset:GetName()
	return self.m_name
end

---@return string
function VehicleFlagPreset:GetDisplayName()
	if (not self.m_is_user_generated and self.m_is_translator_name) then
		return _T(self.m_name)
	end
	return self.m_name
end

---@return string?
function VehicleFlagPreset:GetDescription()
	local desc = self.m_description
	if (not desc) then return end

	if (not self.m_is_user_generated and self.m_is_translator_name) then
		return _T(desc)
	end
	return desc
end

---@return array<Pair<string, boolean>>
function VehicleFlagPreset:GetAssociatedFlags()
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

function VehicleFlagPreset:Copy()
	return VehicleFlagPreset.Deserialize(self:Serialize())
end

function VehicleFlagPreset:Serialize()
	return {
		name                   = self.m_name,
		deltas                 = NormalizeDeltas(self.m_deltas, true),
		vehicle_bitset         = self.m_vehicle_bitset,
		auto_apply             = self.auto_apply,
		description            = self.m_description,
		is_translator_name     = self.m_is_translator_name,
		is_user_generated      = self.m_is_user_generated,
		is_default_preset      = self.m_is_default_preset,
		callback_defs_filename = self.m_callback_defs_filename,
	}
end

---@private
---@param func fun(self: VehicleFlagPreset, editor: VehicleFlagController)
---@param editorInst VehicleFlagController
---@param funcIndex integer -- 1 OnEnable | 2 OnDisable
function VehicleFlagPreset:__run(func, editorInst, funcIndex)
	if (type(func) ~= "function") then return end
	if (not editorInst or not editorInst:IsInitialized()) then return end

	local presetName = self.m_name
	local funcName   = funcIndex == 1 and "OnEnable" or "OnDisable"
	local ref        = BAD_CALLBACKS[presetName]
	if (ref and ref[funcName]) then
		log.fwarning(
			"[VehicleFlagPreset]: %s callback execution blocked for preset '%s' (bad callback).",
			funcName,
			presetName
		)
		return
	end

	ThreadManager:Run(function()
		local ok, res = pcall(function()
			TaskWait(func, { self, editorInst }, 500)
		end)

		if (not ok) then
			log.fwarning(
				"[VehicleFlagPreset]: %s callback failed for preset '%s'. Future executions will be blocked.\nTraceback: %s",
				funcName,
				presetName,
				res
			)

			ref                       = ref or {}
			ref[funcName]             = true
			BAD_CALLBACKS[presetName] = ref
		end
	end)
end

---@param editorInst VehicleFlagController
function VehicleFlagPreset:OnEnable(editorInst)
	self:__run(self.m_on_enable_callback, editorInst, 1)
end

---@param editorInst VehicleFlagController
function VehicleFlagPreset:OnDisable(editorInst)
	self:__run(self.m_on_disable_callback, editorInst, 2)
end

--#region static funcs

---@nodiscard
---@param data VehicleFlagPresetData
---@return boolean
function VehicleFlagPreset.AssertArgs(data)
	if (type(data) ~= "table") then
		return false
	end

	local deltas = data.deltas
	if (type(data.name) ~= "string" or type(deltas) ~= "table") then
		return false
	end

	for _, t in pairs(deltas) do
		if (type(t) ~= "table") then
			return false
		end

		for k, v in pairs(t) do
			if (type(k) ~= "string" or type(v) ~= "boolean") then
				return false
			end
		end
	end

	return true
end

---@param name string
---@return boolean
function VehicleFlagPreset.IsNameReserved(name)
	return RESERVED_NAMES[name]
end

---@param data VehicleFlagPresetData
---@return VehicleFlagPreset
function VehicleFlagPreset.Deserialize(data)
	local is_user_generated = not RESERVED_NAMES[data.name]
	return MakeInstance({
		m_name                   = data.name,
		m_description            = data.description,
		m_deltas                 = NormalizeDeltas(data.deltas, false),
		m_vehicle_bitset         = data.vehicle_bitset or (1 << CARS_BIT),
		auto_apply               = data.auto_apply or false,
		m_is_translator_name     = data.is_translator_name,
		m_is_default_preset      = data.is_default_preset,
		m_is_user_generated      = is_user_generated,
		m_callback_defs_filename = is_user_generated and data.callback_defs_filename or nil
	}, VehicleFlagPreset)
end

--#endregion

return VehicleFlagPreset
