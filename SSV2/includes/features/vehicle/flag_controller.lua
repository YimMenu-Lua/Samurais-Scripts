-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FlagPreset <const>      = require("includes.structs.VehicleFlagPreset")
local DefaultPresets <const>  = require("includes.data.vehicle_flag_presets")

---@type table<eHandlingEditorTypes, { enum : table<string, integer>, set: fun(veh: PlayerVehicle, flag: integer, toggle: boolean), get: fun(veh: PlayerVehicle, flag: integer): boolean }>
local FlagData <const>        = {
	[Enums.eHandlingEditorTypes.TYPE_AF] = {
		enum = Enums.eVehicleAdvancedFlags,
		get  = function(veh, flag) return veh:GetAdvancedFlag(flag) end,
		set  = function(veh, flag, toggle) veh:SetAdvancedFlag(flag, toggle) end,
	},
	[Enums.eHandlingEditorTypes.TYPE_HF] = {
		enum = Enums.eVehicleHandlingFlags,
		get  = function(veh, flag) return veh:GetHandlingFlag(flag) end,
		set  = function(veh, flag, toggle) veh:SetHandlingFlag(flag, toggle) end,
	},
	[Enums.eHandlingEditorTypes.TYPE_MF] = {
		enum = Enums.eVehicleModelFlags,
		get  = function(veh, flag) return veh:GetModelFlag(flag) end,
		set  = function(veh, flag, toggle) veh:SetModelFlag(flag, toggle) end,
	},
	[Enums.eHandlingEditorTypes.TYPE_MIF] = {
		enum = Enums.eVehicleModelInfoFlags,
		get  = function(veh, flag) return veh:GetModelInfoFlag(flag) end,
		set  = function(veh, flag, toggle) veh:SetModelInfoFlag(flag, toggle) end,
	},
}

---@class VehicleFlagController
---@field private m_vehicle PlayerVehicle
---@field private m_deltas table<eHandlingEditorTypes, table<string, boolean>>
---@field private m_stale_deltas table<joaat_t, table<eHandlingEditorTypes, table<string, boolean>>> -- save by model in case a vehicle despawns before cleanup
---@field private m_presets array<VehicleFlagPreset>
---@field private m_preset_lookup dict<integer> -- presetName -> m_presets array index. we really need an OrderedList now this is getting out of hand
---@field private m_active_presets dict<VehicleFlagPreset>
---@field private m_owned_flags table<string, integer> reference count by flag name. keys are typed like so to abvoid name collision: enumType:flagName (ex: "1:FREEWHEEL_NO_GAS") where "1" is eHandlingEditorTypes.TYPE_HF
---@field private m_file_name "handling_editor.json"
---@field private m_initialized boolean
---@field private m_presets_ready boolean
local VehicleFlagController   = {
	m_initialized    = false,
	m_presets_ready  = false,
	m_file_name      = "handling_editor.json",
	m_presets        = {},
	m_preset_lookup  = {},
	m_active_presets = {},
	m_owned_flags    = {},
}
VehicleFlagController.__index = VehicleFlagController

---@param veh PlayerVehicle
function VehicleFlagController:init(veh)
	if (self.m_initialized) then
		log.warning("[VehicleFlagController]: Attempt to re-initialize. Only one instance is allowed.")
		return self
	end

	self.m_vehicle      = veh
	self.m_stale_deltas = {}
	self.m_deltas       = {
		[Enums.eHandlingEditorTypes.TYPE_AF]  = {},
		[Enums.eHandlingEditorTypes.TYPE_HF]  = {},
		[Enums.eHandlingEditorTypes.TYPE_MF]  = {},
		[Enums.eHandlingEditorTypes.TYPE_MIF] = {},
	}

	if (not io.exists(self.m_file_name)) then
		Serializer:WriteToFile(self.m_file_name, DefaultPresets)
	end

	self:FetchPresets()
	self.m_initialized = true
	return self
end

function VehicleFlagController:FetchPresets()
	ThreadManager:Run(function()
		---@type table<string, VehicleFlagPreset>
		local default_presets = {}
		self.m_presets        = {}
		self.m_preset_lookup  = {}
		local index           = 0
		local json_presets    = Serializer:ReadFromFile(self.m_file_name) or {} ---@cast json_presets array<VehicleFlagPresetData>

		for _, preset in pairs(DefaultPresets) do
			local reference = FlagPreset(preset)
			local name = preset.name
			table.insert(self.m_presets, reference)
			default_presets[name] = reference
			index = index + 1
			self.m_preset_lookup[name] = index
		end

		for _, presetData in ipairs(json_presets) do
			local name = presetData.name
			local reference = default_presets[name]
			if (reference) then
				reference.auto_apply = presetData.auto_apply
			else
				table.insert(self.m_presets, FlagPreset(presetData))
				index = index + 1
				self.m_preset_lookup[name] = index
			end
		end

		self.m_presets_ready = true
	end)
end

---@nodiscard
---@return boolean
function VehicleFlagController:IsInitialized()
	return self.m_initialized
end

---@nodiscard
---@return boolean
function VehicleFlagController:ArePresetsReady()
	return self.m_presets_ready
end

---@return boolean
function VehicleFlagController:HasEdits()
	for _, data in pairs(self.m_deltas) do
		if (next(data) ~= nil) then
			return true
		end
	end
	return false
end

-- The flag name must be concatenated with its type enum
--
-- Example:
--
--```Lua
-- local is_owned = HandlingEditor:IsFlagOwned(_F("%d:%s", Enums.eHandlingEditorTypes.TYPE_HF, "FREEWHEEL_NO_GAS"))
--```
---@param flagName string
---@return boolean
function VehicleFlagController:IsFlagOwned(flagName)
	local refCount = self.m_owned_flags[flagName]
	return refCount and refCount > 0 or false
end

---@return boolean
function VehicleFlagController:IsAnyPresetEnabled()
	return next(self.m_active_presets) ~= nil
end

---@param presetName string
---@return boolean
function VehicleFlagController:IsPresetEnabled(presetName)
	return self.m_active_presets[presetName] ~= nil
end

---@param name string
---@return boolean
function VehicleFlagController:IsNameReserved(name)
	return FlagPreset.IsNameReserved(name)
end

---@param preset VehicleFlagPreset
---@return boolean
function VehicleFlagController:DoesPresetExist(preset)
	return self.m_preset_lookup[preset:GetName()] ~= nil
end

---@param name string
---@return boolean
function VehicleFlagController:DoesPresetExistByName(name)
	return self.m_preset_lookup[name] ~= nil
end

---@param allowed_types integer
---@return boolean
function VehicleFlagController:AssertVehicleType(allowed_types)
	local vehType = self.m_vehicle:GetType()
	return Bit.IsBitSet(allowed_types, vehType)
end

---@param presets? array<VehicleFlagPreset>
---@return array<VehicleFlagPreset> -- serialized presets
function VehicleFlagController:SerializePresets(presets)
	presets    = presets or self.m_presets
	local buff = {}
	for _, preset in ipairs(presets) do
		table.insert(buff, preset:Serialize())
	end
	return buff
end

function VehicleFlagController:SavePresets()
	Serializer:WriteToFile(self.m_file_name, self:SerializePresets())
end

---@return array<VehicleFlagPreset>
function VehicleFlagController:GetPresets()
	return self.m_presets
end

---@param name string
---@param vehicleTypes integer
---@param description? string
---@param autoEnable? boolean
---@param cbFileName? string
---@return VehicleFlagPreset
function VehicleFlagController:GeneratePresetFromCurrentDeltas(name, vehicleTypes, description, autoEnable, cbFileName)
	autoEnable = autoEnable or false
	local deltas = {}
	for enumType, data in pairs(self.m_deltas) do
		deltas[enumType] = deltas[enumType] or {}
		for sName, bState in pairs(data) do
			deltas[enumType][sName] = not bState -- no need to read flags from memory. if a flag is saved then the user wants the opposite of default
		end
	end

	return FlagPreset({
		name                   = name,
		deltas                 = deltas,
		description            = description or _T("GENERIC_NO_DESCRIPTION"),
		vehicle_bitset         = vehicleTypes,
		auto_apply             = autoEnable or false,
		is_default_preset      = false,
		is_user_generated      = true,
		callback_defs_filename = cbFileName,
	})
end

---@nodiscard
---@param preset VehicleFlagPreset
---@return boolean
function VehicleFlagController:AddNewPreset(preset)
	self.m_presets_ready = false
	local name = preset:GetName()
	if (self.m_preset_lookup[name]) then
		Notifier:ShowError("HandlingEditor", _T("VEH_FLAGS_NEW_PRESET_ERR"))
		self.m_presets_ready = true
		return false
	end

	table.insert(self.m_presets, preset)
	self.m_preset_lookup[name] = #self.m_presets
	self:SavePresets()
	self.m_presets_ready = true
	Notifier:ShowSuccess("HandlingEditor", _T("VEH_FLAGS_NEW_PRESET_SUCCESS", name))
	return true
end

---@param preset VehicleFlagPreset
function VehicleFlagController:RemovePreset(preset)
	self.m_presets_ready = false
	if (preset:IsDefault()) then
		Notifier:ShowError("HandlingEditor", _T("VEH_FLAGS_PRESET_NO_DELETE"))
		self.m_presets_ready = true
		return
	end

	local index = self.m_preset_lookup[preset:GetName()]
	table.remove(self.m_presets, index)

	self.m_preset_lookup = {}
	for i, p in ipairs(self.m_presets) do
		self.m_preset_lookup[p:GetName()] = i
	end

	self:SavePresets()
	self.m_presets_ready = true
end

---@param data VehicleFlagPresetData
function VehicleFlagController:ImportPreset(data)
	if (not FlagPreset.AssertArgs(data)) then
		return false
	end

	if (self:DoesPresetExistByName(data.name)) then
		Notifier:ShowError("HandlingEditor", _T("VEH_FLAGS_NEW_PRESET_ERR"))
		return false
	end

	local preset = FlagPreset(data)
	if (not preset) then return false end
	return self:AddNewPreset(preset)
end

---@private
function VehicleFlagController:SaveStaleState()
	if (not self:HasEdits()) then return end

	local lastModel = self.m_vehicle:GetPreviousModelHash()
	if (not math.is_null(lastModel)) then
		self.m_stale_deltas[lastModel] = table.copy(self.m_deltas)
	end
end

---@private
function VehicleFlagController:ResetStaleState()
	local model  = self.m_vehicle:GetModelHash()
	local stales = self.m_stale_deltas
	if (stales[model]) then
		self:Reset()
		stales[model] = nil
	end
end

---@param preset VehicleFlagPreset
---@param toggle boolean
function VehicleFlagController:TogglePreset(preset, toggle)
	if (not self.m_vehicle:IsValid()) then
		if (not toggle) then self:SaveStaleState() end
		return
	end

	local name = preset:GetName()
	if (toggle == self:IsPresetEnabled(name)) then
		return
	end

	local vehBS = preset.m_vehicle_bitset
	if (not self:AssertVehicleType(vehBS)) then
		self.m_active_presets[name] = nil
		return
	end

	local deltas     = preset.m_deltas
	local ownedFlags = self.m_owned_flags
	for editorType, data in pairs(deltas) do
		local ref = FlagData[editorType]
		if (not ref) then
			log.fwarning("[HandlingEditor]: Unknown reference for type enum %s (%s). Skipping.", editorType, type(editorType))
			goto continue
		end

		local enum = ref.enum
		if (not enum) then
			log.warning("[HandlingEditor]: Reference table has no flag enum! Skipping.")
			goto continue
		end

		for flagName, state in pairs(data) do
			local flag = enum[flagName]
			if (not flag) then
				log.fwarning("[HandlingEditor]: Could not find a vehicle flag with name %s. Skipping.", flagName)
				goto skip
			end

			local ownedFlagName = _F("%d:%s", editorType, flagName)
			if (toggle) then
				if (self:Push(editorType, flag, state, vehBS, flagName)) then
					ownedFlags[ownedFlagName] = (ownedFlags[ownedFlagName] or 0) + 1
				end
			else
				local default_data = self.m_deltas[editorType]
				if (not default_data) then goto skip end

				local default_state = default_data[flagName]
				if (default_state == nil) then goto skip end

				ownedFlags[ownedFlagName] = (ownedFlags[ownedFlagName] or 1) - 1
				if (ownedFlags[ownedFlagName] == 0) then
					self:Push(editorType, flag, default_state, vehBS, flagName)
				end
			end
			::skip::
		end
		::continue::
	end

	if (toggle) then
		preset:OnEnable(self)
		self.m_active_presets[name] = preset
	else
		preset:OnDisable(self)
		self.m_active_presets[name] = nil
	end
end

function VehicleFlagController:ApplyPresets()
	for _, preset in ipairs(self.m_presets) do
		if (preset.auto_apply) then
			self:TogglePreset(preset, true)
		end
	end
end

---@param flagType eHandlingEditorTypes
---@param flag integer
---@param state boolean
---@param allowed_types integer
---@param flagName? string -- Mostly used internally to skip converting the int flag back to a string name.
---@return boolean
function VehicleFlagController:Push(flagType, flag, state, allowed_types, flagName)
	local vehicle = self.m_vehicle
	if (not vehicle:IsValid()) then return false end

	self:ResetStaleState()

	if (not self:AssertVehicleType(allowed_types)) then
		return false
	end

	local ref = FlagData[flagType]
	if (not ref) then
		log.fwarning("[HandlingEditor]: Unknown reference for type enum %s (%s). Skipping.", flagType, type(flagType))
		return false
	end

	-- Flags are converted back and forth between string and int because our 3rd party json module can not handle sparse arrays, so deltas are keyed by flag name instead.
	local name = flagName or EnumToString(ref.enum, flag)
	if (not name or name == "Unknown") then
		log.fwarning("[HandlingEditor]: Failed to get name from flag %s (type: %s)", flag, type(flag))
		return false
	end

	local default = ref.get(self.m_vehicle, flag)
	if (default == state) then
		-- Backend:debug("[HandlingEditor]: Skipped flag %s (already enabled).", name)
		return false
	end

	local saved = self.m_deltas[flagType][name]
	if (saved == nil) then
		self.m_deltas[flagType][name] = default
	elseif (saved == state) then
		self.m_deltas[flagType][name] = nil
	end

	ref.set(self.m_vehicle, flag, state)
	return true
end

---@param manual_trigger? boolean
function VehicleFlagController:Reset(manual_trigger)
	local vehicle = self.m_vehicle
	if (not vehicle:IsValid()) then
		self:SaveStaleState()
		return
	end

	local deltas = self.m_deltas
	for editorType, data in pairs(deltas) do
		local ref = FlagData[editorType]
		if (not ref) then goto continue end

		local enum = ref.enum
		local set  = ref.set
		for name, state in pairs(data) do
			local flag = enum[name]
			if (type(flag) == "number") then
				set(vehicle, flag, state)
			end
		end

		::continue::
	end

	for _, i in pairs(Enums.eHandlingEditorTypes) do
		self.m_deltas[i] = {}
	end

	self.m_active_presets = {}
	self.m_owned_flags    = {}
	if (manual_trigger and vehicle:IsValid()) then
		self:ApplyPresets()
	end
end

return VehicleFlagController
