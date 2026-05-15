-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local HandlingEditor           = require("includes.modules.HandlingEditor")
local Mutex                    = require("includes.classes.Mutex")
local TableRenderer            = require("includes.frontend.helpers.TableRenderer").new()
local measureTextWidth         = require("includes.frontend.helpers.measure_text_width")
local PV <const>               = LocalPlayer:GetVehicle()
local CARS_BIT <const>         = Enums.eVehicleType.VEHICLE_TYPE_CAR
local BIKES_BIT <const>        = Enums.eVehicleType.VEHICLE_TYPE_BIKE
local BIT_TEST <const>         = Bit.IsBitSet
local presetChildSize          = vec2:new(200, 240)
local presetSearchBuff         = ""
local importedPreset           = { clipboardStr = "", decoded = nil }
local presetSortMode           = 0 -- 0 All | 1: Cars Only | 2: Bikes Only
local flagFilterMode           = 0 -- 0 All | 1: Enabled Only | 2: Disabled Only
local flagSortMode             = 0 -- 0: Flag | 1: Name
local sortModeClicked          = false
local flagListMutex            = Mutex()
local btnSize                  = vec2:new(0, 37)
local mainButtonLabelWidths    = {}
local popupsToDraw             = {
	flagDump      = false,
	confirmDelete = false
}
local newPresetWindowData      = {
	shouldDraw      = false,
	wantsAutoEnable = false,
	nameBuffer      = "",
	descBuffer      = "",
	cb_filename     = "",
	vehTypesBs      = 1 << CARS_BIT,
}

---@alias getFlag  fun(veh: PlayerVehicle, flag: integer): boolean
---@alias getAllFlags  fun(veh: PlayerVehicle): uint32_t|array<uint32_t>

---@alias vehicleDebugDataAlias { enum: table<string, integer>, type: eHandlingEditorTypes, allowed_types: integer, get: getFlag, get_all: getAllFlags, ordered_flags: array<Pair<string, integer>>, flag_count?: integer }
---@type dict<vehicleDebugDataAlias>
local vehicleFlagData          = {
	["VEH_FLAGS_ADVANCED"] = {
		enum          = Enums.eVehicleAdvancedFlags,
		type          = Enums.eHandlingEditorTypes.TYPE_AF,
		ordered_flags = {},
		get           = function(veh, flag) return veh:GetAdvancedFlag(flag) end,
		get_all       = function(veh) return veh:GetAdvancedFlags() end,
		allowed_types = 1 << CARS_BIT,
		flag_count    = 0 -- incremenred in the fiber that populates the ordered_flags array
	},
	["VEH_FLAGS_HANDLING"] = {
		enum          = Enums.eVehicleHandlingFlags,
		type          = Enums.eHandlingEditorTypes.TYPE_HF,
		ordered_flags = {},
		get           = function(veh, flag) return veh:GetHandlingFlag(flag) end,
		get_all       = function(veh) return veh:GetHandlingFlags() end,
		allowed_types = 1 << CARS_BIT | 1 << BIKES_BIT,
		flag_count    = 0
	},
	["VEH_FLAGS_MODEL"] = {
		enum          = Enums.eVehicleModelFlags,
		type          = Enums.eHandlingEditorTypes.TYPE_MF,
		ordered_flags = {},
		get           = function(veh, flag) return veh:GetModelFlag(flag) end,
		get_all       = function(veh) return veh:GetModelFlags() end,
		allowed_types = 1 << CARS_BIT,
		flag_count    = 0
	},
	["VEH_FLAGS_MODEL_INFO"] = {
		enum          = Enums.eVehicleModelInfoFlags,
		type          = Enums.eHandlingEditorTypes.TYPE_MIF,
		ordered_flags = {},
		get           = function(veh, flag) return veh:GetModelInfoFlag(flag) end,
		get_all       = function(veh) return veh:GetModelInfoFlags() end,
		allowed_types = 1 << CARS_BIT,
		flag_count    = 0
	},
}

local vehicleFlagOrder <const> = {
	"VEH_FLAGS_ADVANCED",
	"VEH_FLAGS_HANDLING",
	"VEH_FLAGS_MODEL",
	"VEH_FLAGS_MODEL_INFO",
}

-- **must be called in a coroutine**
local function SortAllOrderedFlags()
	flagListMutex:WithLock(function()
		for _, data in pairs(vehicleFlagData) do
			local ordered_flags = data.ordered_flags
			if (#ordered_flags == 0) then
				local count = 0
				for name, flag in pairs(data.enum) do
					table.insert(ordered_flags, Pair.new(name, flag))
					count = count + 1
				end
				data.flag_count = count
			end

			table.sort(ordered_flags, function(a, b)
				local key = flagSortMode == 0 and "second" or "first"
				return a[key] < b[key]
			end)
		end
	end)
end

---@param flags uint32_t|array<uint32_t>
---@return string
local function formatFlags(flags)
	local argType = type(flags)
	if (argType == "table") then
		local out = {}
		for i, u32 in ipairs(flags) do
			out[i] = _F("0x%X", u32)
		end
		return _F("{ %s }", table.concat(out, ", "))
	end

	if (argType ~= "number") then
		flags = 0
	end

	return _F("0x%X", flags)
end

---@param data vehicleDebugDataAlias
local function drawVehicleFlags(data)
	if (not BIT_TEST(data.allowed_types, PV:GetType())) then
		ImGui.Text(_T("VEH_FLAGS_WRONG_VEH_TYPE"))
		ImGui.Spacing()
		return
	end

	local orderedPairs = data.ordered_flags
	local count        = data.flag_count
	local maxHeight    = math.min(GVars.ui.window_size.y * 0.58, count * ImGui.GetTextLineHeightWithSpacing())
	local allFlags     = data.get_all(PV)
	local getFunc      = data.get

	ImGui.BeginDisabled(not PV:IsValid())
	ImGui.BulletText(formatFlags(allFlags))

	-- we should really consider bumping ImGui in MR-X's fork. I'm tired of not having auto-resizing child windows
	if (ImGui.BeginChildEx("##vehFlags", vec2:new(0, maxHeight), ImGuiChildFlags.Borders)) then
		for _, pair in ipairs(orderedPairs) do
			local flag      = pair.second
			local isEnabled = getFunc(PV, flag)
			if (flagFilterMode == 1 and not isEnabled) then
				goto continue
			end

			if (flagFilterMode == 2 and isEnabled) then
				goto continue
			end

			-- TODO: translate names? most of them will stop making sense though and these are for power users anyway
			-- also keeping them as is may help users who want to do research since they can use the exact flag name as a reference
			local flagName = pair.first
			local flagType = data.type
			local isOwned  = HandlingEditor:IsFlagOwned(_F("%d:%s", flagType, flagName))
			ImGui.BeginDisabled(isOwned)
			if (select(2, GUI:CustomToggle(flagName, isEnabled))) then
				HandlingEditor:Push(flagType, flag, not isEnabled, data.allowed_types)
			end
			ImGui.EndDisabled()
			if (isOwned) then
				GUI:WarningMarker(_T("VEH_FLAGS_FLAG_OWNED_WARN"))
			end

			ImGui.SameLine()
			ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - 70)
			ImGui.TextDisabled(_F("( 1 << %d )", flag))

			::continue::
		end
		ImGui.EndChild()
	end
	ImGui.EndDisabled()
end

---@param currentPreset HandlingPreset
---@return boolean
local function filterPresets(currentPreset)
	local bs = currentPreset.m_vehicle_bitset or 0
	if (presetSortMode == 1) then
		return BIT_TEST(bs, CARS_BIT)
	elseif (presetSortMode == 2) then
		return BIT_TEST(bs, BIKES_BIT) and not BIT_TEST(bs, CARS_BIT)
	end

	return true
end

local function drawImportWindow()
	if (type(importedPreset.decoded) ~= "table") then
		if (GUI:Button(_T("GENERIC_CLIPBOARD_DECODE"), { size = btnSize })) then
			importedPreset.clipboardStr = ImGui.GetClipboardText()
			if (not string.isvalid(importedPreset.clipboardStr)) then
				Notifier:ShowError("HandlingEditor", _T("GENERIC_DATA_PARSE_FAIL"))
				return
			end

			local ok, res = Serializer:Decode(importedPreset.clipboardStr)
			if (not ok) then
				log.warning("Failed to decode JSON data.")
				importedPreset.decoded = nil
			else
				importedPreset.decoded = res
			end
		end

		ImGui.Dummy(0, 25)
		ImGui.TextWrapped(_T("VEH_FLAGS_PRESET_PARSER_TOOLTIP"))
		return
	end

	TableRenderer:Draw(importedPreset.decoded, vec2:new(610, 620))
	ImGui.Spacing()
	if (GUI:Button(_T("GENERIC_CONFIRM"), { size = btnSize })) then
		if (HandlingEditor:ImportPreset(importedPreset.decoded)) then
			Notifier:ShowSuccess("HandlingEditor", _T("VEH_FLAGS_PRESET_IMPORT_SUCCESS"))
		else
			Notifier:ShowError("HandlingEditor", _T("VEH_FLAGS_PRESET_IMPORT_FAIL"))
		end
		importedPreset.clipboardStr = ""
		importedPreset.decoded      = nil
		ImGui.CloseCurrentPopup()
	end

	ImGui.SameLine()
	if (GUI:Button(_T("GENERIC_CLEAR"), { size = btnSize })) then
		importedPreset.clipboardStr = ""
		importedPreset.decoded      = nil
	end
end

local function drawPresets()
	if (not HandlingEditor:ArePresetsReady()) then
		ImGui.Text(ImGui.TextSpinner(_T("GENERIC_WAIT_LABEL")))
		ImGui.Spacing()
		return
	end

	presetSortMode = ImGui.Combo(
		_T("GENERIC_LIST_SORT"),
		presetSortMode,
		{
			_T("GENERIC_ALL"),
			_T("VEH_FLAGS_PRESET_FILTER_CARS_ONLY"),
			_T("VEH_FLAGS_PRESET_FILTER_BIKES_ONLY"),
		},
		3
	)

	presetSearchBuff = ImGui.SearchBar("##presetSearch", presetSearchBuff)
	ImGui.Separator()

	ImGui.SetNextWindowBgAlpha(0.0)
	ImGui.BeginChild("##presetsScrollRegion", 0, GVars.ui.window_size.y * 0.675)
	local presets = HandlingEditor:GetPresets()
	local count   = #presets
	for i, preset in ipairs(presets) do
		ImGui.PushID(i)
		local name = preset:GetDisplayName()
		if (not name:lower():find(presetSearchBuff)) then
			goto continue
		end

		if (not filterPresets(preset)) then
			goto continue
		end

		local nameWidth   = ImGui.CalcTextSize(name) + 50
		presetChildSize.x = math.min(300, math.max(presetChildSize.x, nameWidth, ImGui.GetContentRegionAvail() * 0.48))
		ImGui.BeginChildEx(name, presetChildSize, ImGuiChildFlags.Borders, ImGuiWindowFlags.NoScrollbar)
		ImGui.SeparatorText(name)
		local desc = preset:GetDescription() or _T("GENERIC_NO_DESCRIPTION")
		ImGui.PushStyleVar(ImGuiStyleVar.ScrollbarSize, 5.0)
		ImGui.SetNextWindowBgAlpha(0)
		ImGui.BeginChild("##description", 0, presetChildSize.y - 165)
		ImGui.SetWindowFontScale(0.78)
		ImGui.TextWrapped(desc)
		ImGui.SetWindowFontScale(1.0)
		ImGui.EndChild()
		ImGui.Separator()

		local unsupportedVeh = not HandlingEditor:AssertVehicleType(preset.m_vehicle_bitset)
		ImGui.BeginDisabled(unsupportedVeh)
		GUI:CustomToggle(_T("GENERIC_ENABLE"), HandlingEditor:IsPresetEnabled(preset), {
			onClick = function(v) HandlingEditor:TogglePreset(preset, v) end
		})
		ImGui.EndDisabled()
		if (unsupportedVeh) then
			GUI:Tooltip(_T("VEH_FLAGS_WRONG_VEH_TYPE"))
		end

		GUI:CustomToggle(_T("GENERIC_AUTO_ENABLE"), preset.auto_apply, {
			onClick = function(v)
				preset.auto_apply = v
				HandlingEditor:SavePresets()
				if (v) then HandlingEditor:TogglePreset(preset, v) end
			end,
			tooltip = _T("VEH_FLAGS_AUTOENABLE_TT")
		})

		ImGui.SetCursorPosX(ImGui.GetCursorPosX() + presetChildSize.x - 60)
		ImGui.SetWindowFontScale(0.78)
		if (ImGui.SmallButton(" . . . ")) then
			ImGui.OpenPopup("##presetMenu")
		end
		ImGui.SetWindowFontScale(1.0)
		GUI:Tooltip(_T("GENERIC_OPTIONS_LABEL"))

		local flagDumpLabel = _T("VEH_FLAGS_DUMP_PRESET_FLAGS")
		local isDefault     = preset:IsDefault()
		if (ImGui.BeginPopup("##presetMenu")) then
			if (ImGui.MenuItem(flagDumpLabel)) then
				popupsToDraw.flagDump = true
			end

			local callbackFileName = preset.m_callback_defs_filename
			local hasCallbackFile  = not isDefault and (callbackFileName ~= nil)
			ImGui.BeginDisabled(isDefault)
			if (ImGui.MenuItem(_T("GENERIC_SHARE"))) then
				local str = Serializer:Encode(preset:Serialize())
				if (not str) then
					Notifier:ShowError("HandlingEditor", _T("GENERIC_DATA_PARSE_FAIL"))
				else
					ImGui.SetClipboardText(str)
					log.fdebug("\n ----------------- %s -----------------\n%s", name, str)
					Notifier:ShowSuccess("HandlingEditor", _T("VEH_FLAGS_PRESET_SHARE_SUCCESS_FMT", name))
				end
			end
			ImGui.EndDisabled()
			if (isDefault) then
				GUI:Tooltip(_T("VEH_FLAGS_PRESET_NO_SHARE"))
			elseif (hasCallbackFile) then
				GUI:WarningMarker(_T("VEH_FLAGS_PRESET_CB_FILE_WARN_FMT", callbackFileName))
			end

			ImGui.BeginDisabled(isDefault)
			if (ImGui.MenuItem(_T("GENERIC_DELETE"))) then
				popupsToDraw.confirmDelete = true
			end
			ImGui.EndDisabled()
			if (isDefault) then
				GUI:Tooltip(_T("VEH_FLAGS_PRESET_NO_DELETE"))
			end
			ImGui.EndPopup()
		end

		if (popupsToDraw.flagDump) then
			ImGui.OpenPopup(flagDumpLabel)
			popupsToDraw.flagDump = false
		end

		if (popupsToDraw.confirmDelete) then
			ImGui.OpenPopup(_T("GENERIC_WARN_LABEL"))
			popupsToDraw.confirmDelete = false
		end

		if (ImGui.DialogBox(_T("GENERIC_WARN_LABEL"), _T("GENERIC_CONFIRM_WARN"), ImGuiDialogBoxStyle.WARN)) then
			HandlingEditor:RemovePreset(preset)
		end

		ImGui.SetNextWindowSizeConstraints(400, 160, 600, 600)
		if (ImGui.BeginPopupModal(flagDumpLabel, true, ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoResize)) then
			local flagsArray = preset:GetAssociatedFlags()
			local flagsCount = #flagsArray
			ImGui.Text(_F("Flag count: [ %d ]", flagsCount))
			ImGui.Spacing()
			ImGui.Separator()
			for _, data in ipairs(flagsArray) do
				ImGui.Text(_F("[ %s ]  %s", data.second and "On" or "Off", data.first))
			end
			ImGui.Separator()
			ImGui.EndPopup()
		end

		ImGui.EndChild()
		if (i < count) then
			ImGui.SameLineIfAvail(presetChildSize.x)
		end
		ImGui.PopID()
		::continue::
	end
	ImGui.EndChild()

	ImGui.Separator()
	if (GUI:Button(_T("EF_IMPORT_DATA"), { size = btnSize })) then -- this label should've been a generic but oh well
		ImGui.OpenPopup("##presetImportPopup")
	end

	ImGui.SetNextWindowSizeConstraints(400, 300, 640, 800)
	if (ImGui.BeginPopupModal("##presetImportPopup", true, ImGuiWindowFlags.AlwaysAutoResize)) then
		drawImportWindow()
		ImGui.EndPopup()
	end
end

local function clearPresetWindow()
	newPresetWindowData.shouldDraw      = false
	newPresetWindowData.nameBuffer      = ""
	newPresetWindowData.descBuffer      = ""
	newPresetWindowData.cb_filename     = ""
	newPresetWindowData.vehTypesBs      = 1 << CARS_BIT
	newPresetWindowData.wantsAutoEnable = false
end

local function drawNewPresetWindow()
	if (not newPresetWindowData.shouldDraw) then
		return
	end

	ImGui.Begin("##newPresetWindow",
		ImGuiWindowFlags.NoTitleBar
		| ImGuiWindowFlags.NoResize
		| ImGuiWindowFlags.AlwaysAutoResize
		| ImGuiWindowFlags.NoMove
	)

	local data = newPresetWindowData
	GUI:QuickConfigWindow(_T("VEH_FLAGS_NEW_PRESET_LABEL"), function()
		data.nameBuffer  = ImGui.InputTextWithHint("*##newPresetName", _T("GENERIC_NAME"), data.nameBuffer, 64)
		data.descBuffer  = ImGui.InputTextWithHint("*##newPresetDesc", _T("GENERIC_DESCRIPTION"), data.descBuffer, 512)
		data.cb_filename = ImGui.InputTextWithHint(
			"*##newPresetCb",
			_T("GENERIC_FILENAME"),
			data.cb_filename,
			64,
			ImGuiInputTextFlags.CharsNoBlank
		); data.cb_filename = data.cb_filename:gsub("[/\\]", ""):gsub("%.lua$", "")

		GUI:HelpMarker(_T("VEH_FLAGS_NEW_PRESET_CB_FILE_TT"))

		data.wantsAutoEnable = GUI:Checkbox(_T("GENERIC_AUTO_ENABLE"), data.wantsAutoEnable)

		ImGui.SeparatorText(_T("VEH_FLAGS_NEW_PRESET_VEHICLE_BS"))
		local allowCars  = BIT_TEST(data.vehTypesBs, CARS_BIT)
		local allowBikes = BIT_TEST(data.vehTypesBs, BIKES_BIT)
		if (select(2, GUI:Checkbox(_T("GENERIC_CARS"), allowCars))) then
			data.vehTypesBs = Bit.Toggle(data.vehTypesBs, CARS_BIT, not allowCars)
		end

		if (select(2, GUI:Checkbox(_T("GENERIC_BIKES"), allowBikes))) then
			data.vehTypesBs = Bit.Toggle(data.vehTypesBs, BIKES_BIT, not allowBikes)
		end

		if (not allowCars and not allowBikes) then
			log.warning("[Handling Editor]: At least one vehicle type must be selected. Defaulting to cars.")
			data.vehTypesBs = Bit.Set(data.vehTypesBs, CARS_BIT)
		end

		if (not string.isvalid(data.nameBuffer)) then
			GUI:Text(_T("SETTINGS_NEW_THEME_NAME_EMPTY"), { color = Color.RED })
			return
		end

		if (HandlingEditor:DoesPresetExistByName(data.nameBuffer)) then
			GUI:Text(_T("GENERIC_NAME_ERR"), { color = Color.RED })
			return
		end

		ImGui.Spacing()
		ImGui.Separator()
		if (GUI:Button(_T("GENERIC_CONFIRM"), { size = btnSize })) then
			if (HandlingEditor:AddNewPreset(HandlingEditor:GeneratePresetFromCurrentDeltas(
					data.nameBuffer,
					data.vehTypesBs,
					data.descBuffer,
					data.wantsAutoEnable,
					data.cb_filename
				))) then
				clearPresetWindow()
			end
		end
	end, clearPresetWindow, true)

	ImGui.End()
end

ThreadManager:Run(SortAllOrderedFlags)

return function()
	if (PV:GetHandle() == 0) then
		ImGui.Text(_T("GENERIC_NOT_IN_VEH"))
		return
	end

	if (not HandlingEditor:IsInitialized()) then
		ImGui.Text(_T("GENERIC_UNAVAILABLE"))
		return
	end

	local mainTabBarOpen = ImGui.BeginTabBar("##vehicleFlagsMain")
	if (not mainTabBarOpen) then
		return
	end

	if (ImGui.BeginTabItem(_T("VEH_FLAGS_EDITOR_TAB"))) then
		ImGui.BeginDisabled(flagListMutex:IsLocked())
		flagFilterMode = ImGui.Combo(
			_T("GENERIC_LIST_FILTER"),
			flagFilterMode,
			{ _T("GENERIC_ALL"), _T("VEH_FLAGS_FILTER_ENABLED_ONLY"), _T("VEH_FLAGS_FILTER_DISABLED_ONLY") },
			3
		)

		flagSortMode, sortModeClicked = ImGui.Combo(_T("GENERIC_LIST_SORT"), flagSortMode, { "Flag", _T("GENERIC_NAME") }, 2)
		if (sortModeClicked) then
			ThreadManager:Run(SortAllOrderedFlags)
		end

		local landIdx        = GVars.backend.language_index
		local maxButtonWidth = mainButtonLabelWidths[landIdx]
		if (not maxButtonWidth) then
			maxButtonWidth = measureTextWidth({
				_T("GENERIC_RESET_DEFAULT"),
				_T("VEH_FLAGS_NEW_PRESET")
			})
			mainButtonLabelWidths[landIdx] = maxButtonWidth
		end

		ImGui.Spacing()
		local hasPresets = HandlingEditor:IsAnyPresetEnabled()
		local hasEdits   = HandlingEditor:HasEdits()
		ImGui.BeginDisabled(hasPresets or not hasEdits)
		if (GUI:Button(_T("GENERIC_RESET_DEFAULT"), { size = vec2:new(maxButtonWidth, 37.5) })) then
			HandlingEditor:Reset(true)
		end
		ImGui.EndDisabled()
		if (hasPresets) then
			GUI:WarningMarker(_T("VEH_FLAGS_NO_RESET"))
		end

		ImGui.SameLine()
		ImGui.BeginDisabled(not hasEdits)
		if (GUI:Button(_T("VEH_FLAGS_NEW_PRESET"), { size = vec2:new(maxButtonWidth, 37.5) })) then
			if (hasPresets) then
				ImGui.OpenPopup(_T("GENERIC_WARN_LABEL"))
			else
				newPresetWindowData.shouldDraw = true
			end
		end
		ImGui.EndDisabled()

		if (Backend.debug_mode) then
			ImGui.SameLine()
			if (ImGui.Button("Parse Object", maxButtonWidth, 37.5) and hasEdits) then
				print(table.serialize(HandlingEditor:GeneratePresetFromCurrentDeltas("test", 1 << CARS_BIT)))
			end
		end

		if (ImGui.DialogBox(_T("GENERIC_WARN_LABEL"), _T("VEH_FLAGS_NEW_PRESET_WARN"), ImGuiDialogBoxStyle.WARN)) then
			newPresetWindowData.shouldDraw = true
		end

		ImGui.Separator()
		if (ImGui.BeginTabBar("##flagsEditor")) then
			for i, name in ipairs(vehicleFlagOrder) do
				ImGui.PushID(i)
				if (ImGui.BeginTabItem(_T(name))) then
					drawVehicleFlags(vehicleFlagData[name])
					ImGui.EndTabItem()
				end
				ImGui.PopID()
			end
			ImGui.EndTabBar()
		end

		ImGui.EndDisabled()
		ImGui.EndTabItem()
	end

	if (ImGui.BeginTabItem(_T("VEH_FLAGS_PRESETS_TAB"))) then
		drawPresets()
		ImGui.EndTabItem()
	end

	if (mainTabBarOpen) then
		ImGui.EndTabBar()
	end

	if (newPresetWindowData.shouldDraw) then
		drawNewPresetWindow()
	end
end
