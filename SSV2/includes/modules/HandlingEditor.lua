-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local HandlingPreset   = require("includes.structs.HandlingPreset")
local DefaultPresets   = require("includes.data.handling_presets")

---@type table<eHandlingEditorTypes, { enum : table<string, integer>, set: fun(veh: PlayerVehicle, flag: integer, toggle: boolean), get: fun(veh: PlayerVehicle, flag: integer): boolean }>
local FlagData <const> = {
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

---@class HandlingEditor
---@field private m_vehicle PlayerVehicle
---@field private m_deltas table<eHandlingEditorTypes, table<string, boolean>>
---@field private m_stale_deltas table<joaat_t, table<eHandlingEditorTypes, table<string, boolean>>> -- save by model in case a vehicle despawns before cleanup
---@field private m_presets array<HandlingPreset>
---@field private m_preset_lookup dict<integer> -- presetName -> m_presets array index. we really need an OrderedList now this is getting out of hand
---@field private m_active_presets dict<HandlingPreset>
---@field private m_owned_flags table<string, integer> reference count by flag name
---@field private m_file_name "handling_editor.json"
---@field private m_initialized boolean
---@field private m_presets_ready boolean
local HandlingEditor   = {
	m_initialized    = false,
	m_presets_ready  = false,
	m_file_name      = "handling_editor.json",
	m_presets        = {},
	m_preset_lookup  = {},
	m_active_presets = {},
	m_owned_flags    = {},
}
HandlingEditor.__index = HandlingEditor

---@param veh PlayerVehicle
function HandlingEditor:init(veh)
	if (self.m_initialized) then
		log.warning("[HandlingEditor]: Attempt to re-initialize. Only one instance is allowed.")
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

function HandlingEditor:FetchPresets()
	ThreadManager:Run(function()
		local json_presets    = Serializer:ReadFromFile(self.m_file_name) or {} ---@cast json_presets array<HandlingPresetData>
		---@type table<string, HandlingPreset>
		local default_presets = {}
		local index           = 0
		for _, preset in pairs(DefaultPresets) do
			local reference = HandlingPreset.new(preset)
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
				table.insert(self.m_presets, HandlingPreset.new(presetData))
				index = index + 1
				self.m_preset_lookup[name] = index
			end
		end

		self.m_presets_ready = true
	end)
end

---@nodiscard
---@return boolean
function HandlingEditor:IsInitialized()
	return self.m_initialized
end

---@nodiscard
---@return boolean
function HandlingEditor:ArePresetsReady()
	return self.m_presets_ready
end

---@return boolean
function HandlingEditor:HasEdits()
	for _, data in pairs(self.m_deltas) do
		if (next(data) ~= nil) then
			return true
		end
	end
	return false
end

---@param flagName string
function HandlingEditor:IsFlagOwned(flagName)
	local refCount = self.m_owned_flags[flagName]
	return refCount and refCount > 0 or false
end

---@return boolean
function HandlingEditor:IsAnyPresetEnabled()
	return next(self.m_active_presets) ~= nil
end

---@param preset HandlingPreset
---@return boolean
function HandlingEditor:IsPresetEnabled(preset)
	return self.m_active_presets[preset:GetName()] ~= nil
end

---@param name string
---@return boolean
function HandlingEditor:IsNameReserved(name)
	return HandlingPreset.IsNameReserved(name)
end

---@param preset HandlingPreset
---@return boolean
function HandlingEditor:DoesPresetExist(preset)
	return self.m_preset_lookup[preset:GetName()] ~= nil
end

---@param name string
---@return boolean
function HandlingEditor:DoesPresetExistByName(name)
	return self.m_preset_lookup[name] ~= nil
end

---@param allowed_types integer
function HandlingEditor:AssertVehicleType(allowed_types)
	local vehType = self.m_vehicle:GetType()
	return Bit.IsBitSet(allowed_types, vehType)
end

---@param presets? array<HandlingPreset>
---@return array<HandlingPreset> -- serialized presets
function HandlingEditor:SerializePresets(presets)
	presets    = presets or self.m_presets
	local buff = {}
	for _, preset in ipairs(presets) do
		table.insert(buff, preset:Serialize())
	end
	return buff
end

function HandlingEditor:SavePresets()
	Serializer:WriteToFile(self.m_file_name, self:SerializePresets())
end

function HandlingEditor:GetPresets()
	return self.m_presets
end

---@param name string
---@param vehicleTypes integer
---@param description? string
---@param autoEnable? boolean
---@return HandlingPreset
function HandlingEditor:GeneratePresetFromCurrentDeltas(name, vehicleTypes, description, autoEnable)
	autoEnable = autoEnable or false
	local deltas = {}
	for hType, data in pairs(self.m_deltas) do
		deltas[hType] = deltas[hType] or {}
		for sName, bState in pairs(data) do
			deltas[hType][sName] = not bState -- no need to read flags from memory. if a flag is saved then the user wants the opposite of default
		end
	end

	return HandlingPreset.new({
		name                  = name,
		deltas                = deltas,
		description           = description or _T("GENERIC_NO_DESCRIPTION"),
		allowed_vehicle_types = vehicleTypes,
		auto_apply            = autoEnable or false,
		is_default_preset     = false,
		is_user_generated     = true,
	})
end

---@nodiscard
---@param preset HandlingPreset
---@return boolean
function HandlingEditor:AddNewPreset(preset)
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

---@param preset HandlingPreset
function HandlingEditor:RemovePreset(preset)
	self.m_presets_ready = false
	if (preset:IsDefault()) then
		Notifier:ShowError("HandlingEditor", _T("VEH_FLAGS_PRESET_NO_DELETE"))
		self.m_presets_ready = true
		return
	end

	local name = preset:GetName()
	local index = self.m_preset_lookup[name]
	table.remove(self.m_presets, index)
	self.m_preset_lookup[name] = nil
	self:SavePresets()
	self.m_presets_ready = true
end

---@private
function HandlingEditor:SaveStaleState()
	if (not self:HasEdits()) then return end

	local lastModel = self.m_vehicle:GetPreviousModelHash()
	if (not math.is_null(lastModel)) then
		self.m_stale_deltas[lastModel] = table.copy(self.m_deltas)
	end
end

---@private
function HandlingEditor:ResetStaleState()
	local model  = self.m_vehicle:GetModelHash()
	local stales = self.m_stale_deltas
	if (stales[model]) then
		self:Reset()
		stales[model] = nil
	end
end

---@param preset HandlingPreset
---@param toggle boolean
function HandlingEditor:TogglePreset(preset, toggle)
	if (not self.m_vehicle:IsValid()) then
		if (not toggle) then self:SaveStaleState() end
		return
	end

	if (toggle == self:IsPresetEnabled(preset)) then
		return
	end

	local name          = preset:GetName()
	local deltas        = preset.m_deltas
	local allowed_types = preset.m_veh_types_bs
	if (not self:AssertVehicleType(allowed_types)) then
		self.m_active_presets[name] = nil
		return
	end

	local ownedFlags = self.m_owned_flags
	for hFlag, data in pairs(deltas) do
		local ref = FlagData[hFlag]
		if (not ref) then goto continue end

		local enum = ref.enum
		if (not enum) then goto continue end

		for name, state in pairs(data) do
			local flag = enum[name]
			if (toggle) then
				if (self:Push(hFlag, flag, state, allowed_types)) then
					ownedFlags[name] = (ownedFlags[name] or 0) + 1
				end
			else
				ownedFlags[name] = (ownedFlags[name] or 1) - 1
				if (ownedFlags[name] == 0) then
					self:Push(hFlag, flag, not state, allowed_types)
				end
			end
		end

		::continue::
	end

	self.m_active_presets[name] = toggle and preset or nil
end

function HandlingEditor:ApplyPresets()
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
---@return boolean
function HandlingEditor:Push(flagType, flag, state, allowed_types)
	local vehicle = self.m_vehicle
	if (not vehicle:IsValid()) then return false end

	self:ResetStaleState()

	if (not self:AssertVehicleType(allowed_types)) then
		return false
	end

	local ref = FlagData[flagType]
	assert(ref ~= nil, "Unknown flag type!", 2)

	local name = EnumToString(ref.enum, flag)
	assert(name ~= "Unknown", "Unknown flag!", 2)

	local default = ref.get(self.m_vehicle, flag)
	if (default == state) then return false end -- skip saving flags that should not be mutated

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
function HandlingEditor:Reset(manual_trigger)
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
	if (manual_trigger and vehicle:IsValid()) then
		self:ApplyPresets()
	end
end

return HandlingEditor
