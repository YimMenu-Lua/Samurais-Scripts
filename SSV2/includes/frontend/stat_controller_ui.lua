-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local MAX_ITEMS <const>         = 20
local MPStatController          = require("includes.features.online.MPStatController")
local drawKeyValue              = require("includes.frontend.helpers.draw_kv")
local BitTest                   = Bit.IsBitSet
local statChildSize             = vec2:new(0, 170)
local statSearchBuff            = ""
local newStatBuff               = { name = "", type = "", lock_val = nil, autolock = false }
local statDateEditBuff          = nil
local currentYear               = os.date("*t").year ---@cast currentYear integer
local currentBitView            = 0 -- 0: hex | 1: binary
local bitEditorIntChanged       = false
local statTypes <const>         = { "int", "float", "money", "bool", "string", "posix", "time", "date", "bitset" }
local statFilterTypes           = { "All" }
local selectedFilterType        = "All"
local days <const>              = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
local dateTimeDefault_t <const> = {
	["year"]  = { min = 1970, max = currentYear },
	["month"] = { min = 1, max = 12 },
	["day"]   = { min = 1, max = 31 },
	["hour"]  = { min = 0, max = 23 },
	["min"]   = { min = 0, max = 59 },
	["sec"]   = { min = 0, max = 59 },
}
local dateTimeOrder_t <const>   = {
	"year",
	"month",
	"day",
	"hour",
	"min",
	"sec",
}

for _, statType in ipairs(statTypes) do
	table.insert(statFilterTypes, statType)
end

---@param year integer
local function isLeapYear(year)
	return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

---@param year integer
---@return array<integer>
local function getDaysForYear(year)
	days[2] = isLeapYear(year) and 29 or 28
	return days
end

---@param year integer
---@param month integer
---@return integer
local function getMaxDaysForMonth(year, month)
	return getDaysForYear(year)[month]
end


---@param label string
---@param mpStat MPStat
---@param currentVal integer|float
---@param zeroMin boolean
---@param isFloat boolean
local function drawNumberEditor(label, mpStat, currentVal, zeroMin, isFloat)
	local inputFunc = isFloat and ImGui.InputFloat or ImGui.InputInt
	if (mpStat.value_buffer == nil) then
		mpStat.value_buffer = currentVal
	end

	mpStat.value_buffer = inputFunc(label, mpStat.value_buffer)
	if (zeroMin) then
		mpStat.value_buffer = math.max(0, mpStat.value_buffer)
	end

	ImGui.Separator()
	ImGui.Spacing()

	if (GUI:Button(_T("GENERIC_CONFIRM"))) then
		mpStat:Set(mpStat.value_buffer)
		mpStat.value_buffer = mpStat:Get()
		ImGui.CloseCurrentPopup()
	end

	ImGui.SameLine()
	if (GUI:Button(_T("GENERIC_CANCEL"))) then
		mpStat.value_buffer = mpStat:Get()
		ImGui.CloseCurrentPopup()
	end
end

---@param mpStat MPStat
---@param currentVal int32_t
local function drawBitsetEditor(mpStat, currentVal)
	ImGui.SeparatorText("Bit Editor")
	ImGui.PushStyleVar(ImGuiStyleVar.CellPadding, 10, 9)
	if (ImGui.BeginTable("##bitsetEditor", 9, ImGuiTableFlags.SizingFixedFit)) then
		ImGui.TableNextRow()
		ImGui.TableSetColumnIndex(0)
		ImGui.Text("")

		for bit = 7, 0, -1 do
			ImGui.TableSetColumnIndex(8 - bit)
			ImGui.Text(tostring(bit))
		end

		for byte = 3, 0, -1 do
			ImGui.TableNextRow()
			ImGui.TableSetColumnIndex(0)
			ImGui.Text(_F("Byte %d", byte + 1))

			for bit = 7, 0, -1 do
				local bitPos = (byte * 8) + bit
				ImGui.TableSetColumnIndex(8 - bit)
				local enabled = BitTest(currentVal, bitPos)
				if (enabled) then
					ImGui.PushStyleColor(ImGuiCol.Button, ImGui.GetStyleColorVec4(ImGuiCol.ButtonActive))
				end
				ImGui.SetWindowFontScale(0.8)
				if (ImGui.Button(enabled and "1" or "0", 23, 28)) then
					currentVal = Bit.Toggle(currentVal, bitPos, not enabled)
					mpStat:Set(currentVal)
				end
				ImGui.SetWindowFontScale(1.0)
				if (enabled) then
					ImGui.PopStyleColor()
				end
				GUI:Tooltip(_F("Bit %d", bitPos))
			end
		end

		ImGui.EndTable()
	end
	ImGui.PopStyleVar()

	ImGui.Spacing()
	ImGui.SeparatorText("Direct Value")
	currentVal, bitEditorIntChanged = ImGui.InputInt("##bitEditorInput", currentVal)
	if (bitEditorIntChanged) then
		mpStat:Set(currentVal)
	end

	ImGui.Spacing()
	ImGui.SeparatorText("View")
	currentBitView   = ImGui.Combo("##bitView", currentBitView, "Hexadecimal\0Binary\0Decimal\0")
	local bitViewStr = ""
	if (currentBitView == 0) then
		bitViewStr = _F("0x%08X", currentVal)
	elseif (currentBitView == 1) then
		bitViewStr = mpStat:Format()
	else
		bitViewStr = tostring(currentVal)
	end

	ImGui.TextDisabled(bitViewStr)
end

---@param buff osdatefixed
local function updateMaxDays(buff)
	local day = dateTimeDefault_t["day"]
	day.max = getMaxDaysForMonth(buff.year, buff.month)
	if (buff.day > day.max) then
		buff.day = day.max
	end
end

---@param mpStat MPStat
---@param current DateTime
local function drawDateEditor(mpStat, current)
	if (not statDateEditBuff) then
		statDateEditBuff = current:AsTable()
		dateTimeDefault_t["day"].max = getMaxDaysForMonth(statDateEditBuff.year, statDateEditBuff.month)
	end

	for _, v in pairs(dateTimeOrder_t) do
		local default       = dateTimeDefault_t[v]
		statDateEditBuff[v] = ImGui.SliderInt(v:titlecase(), statDateEditBuff[v], default.min, default.max)
		if (v == "year" or v == "month" and ImGui.IsItemDeactivatedAfterEdit()) then
			updateMaxDays(statDateEditBuff)
		end
	end

	ImGui.Separator()
	ImGui.Spacing()

	if (GUI:Button(_T("GENERIC_CONFIRM"))) then
		local newDateTime = DateTime(statDateEditBuff)
		mpStat:Set(newDateTime)
		mpStat.value_buffer = mpStat:Get()
		statDateEditBuff    = nil
		ImGui.CloseCurrentPopup()
	end

	ImGui.SameLine()
	if (GUI:Button(_T("GENERIC_CANCEL"))) then
		mpStat.value_buffer = mpStat:Get()
		statDateEditBuff    = nil
		ImGui.CloseCurrentPopup()
	end
end

---@param mpStat MPStat
local function drawStatEditor(mpStat)
	local label   = _F("##%s", mpStat.m_name)
	local current = mpStat:Get()
	local _type   = mpStat.m_type
	local isPosix = _type == "posix"
	local isTime  = isPosix or _type == "time"
	local isFloat = _type == "float"

	if (_type == "int" or _type == "money" or isTime or isFloat) then
		drawNumberEditor(label, mpStat, current, isTime, isFloat)
		return
	end

	if (_type == "date") then
		drawDateEditor(mpStat, current)
		return
	end

	if (_type == "bitset") then
		drawBitsetEditor(mpStat, current)
		return
	end

	if (_type == "bool") then
		if (select(2, GUI:Checkbox(label, current))) then
			mpStat:Set(not current)
		end
		return
	end

	if (_type == "string") then
		if (select(2, ImGui.InputText("##statString", current, 512, ImGuiInputTextFlags.EnterReturnsTrue))) then
			mpStat:Set(current)
		end
		GUI:Tooltip("Press [ENTER] to set the value.")
		return
	end
end

---@param mpStat MPStat
local function drawStatObject(mpStat)
	local name = mpStat.m_name
	ImGui.BeginChildEx(name, statChildSize, ImGuiChildFlags.Borders)
	drawKeyValue(_T("GENERIC_NAME"), name)
	drawKeyValue(_T("GENERIC_VALUE"), mpStat:Format())
	ImGui.Separator()

	if (GUI:Button(_T("GENERIC_EDIT"))) then
		ImGui.OpenPopup(name)
	end

	ImGui.SetNextWindowSizeConstraints(400, 144, 600, 600)
	if (ImGui.BeginPopupModal(name, true, ImGuiWindowFlags.NoResize | ImGuiWindowFlags.AlwaysAutoResize)) then
		drawStatEditor(mpStat)
		ImGui.EndPopup()
	end

	if (select(2, GUI:CustomToggle(_T("GENERIC_LOCK_VAL"), mpStat.autolock, { tooltip = _T("MPSTAT_LOCK_VAL_TT") }))) then
		mpStat.autolock = not mpStat.autolock
		mpStat.m_lock_val = mpStat:Get(mpStat.autolock)
		MPStatController:SaveStats()
	end

	ImGui.EndChild()
end

local function drawNewStatPopup()
	ImGui.PushItemWidth(420.69)
	newStatBuff.name = ImGui.InputText("Stat", newStatBuff.name, 128)

	if (ImGui.BeginCombo(_T("GENERIC_TYPE"), newStatBuff.type)) then
		for _, typeName in ipairs(statTypes) do
			if (ImGui.Selectable(typeName, (typeName == newStatBuff.type))) then
				newStatBuff.type = typeName
			end
		end
		ImGui.EndCombo()
	end
	ImGui.PopItemWidth()

	ImGui.Spacing()

	ImGui.BeginDisabled(newStatBuff.name == "" or newStatBuff.type == "")
	if (GUI:Button(_T("GENERIC_CONFIRM"))) then
		MPStatController:AddStat(table.copy(newStatBuff))
		newStatBuff = { name = "", type = "" }
		ImGui.CloseCurrentPopup()
	end
	ImGui.EndDisabled()

	ImGui.SameLine()
	if (GUI:Button(_T("GENERIC_CANCEL"))) then
		newStatBuff = { name = "", type = "" }
		ImGui.CloseCurrentPopup()
	end
end

local function drawStatCards()
	local statList   = MPStatController:GetStats()
	local orderArray = MPStatController:GetStatsOrder()
	local processed  = 0

	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChildEx("##statsScroll", vec2:new(0, GVars.ui.window_size.y * 0.63))
	for i, name in pairs(orderArray) do
		if (not name:lower():find(statSearchBuff)) then
			goto continue
		end

		if (processed > MAX_ITEMS) then
			goto continue
		end

		ImGui.PushID(i)
		local mpStat = statList[name]
		if (not mpStat) then goto continue end
		if (selectedFilterType ~= "All" and mpStat.m_type ~= selectedFilterType) then
			goto continue
		end

		drawStatObject(mpStat)
		ImGui.PopID()
		processed = processed + 1

		::continue::
	end
	ImGui.EndChild()

	local size = #orderArray
	if (size > MAX_ITEMS) then
		ImGui.TextColored(0.941, 0.745, 0.007, 1, "[ ! ]")
		GUI:Tooltip(_T("ASSET_BROWSER_TRUNC_TT", MAX_ITEMS))
	end
end

GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, "SUBTAB_MPSTAT_CONTROLLER", function()
	if (not Game.IsOnline()) then
		ImGui.Text(_T("GENERIC_UNAVAILABLE_SP"))
		return
	end

	ImGui.SetWindowFontScale(1.3)
	ImGui.Text(_T("SUBTAB_MPSTAT_CONTROLLER"))

	ImGui.SetWindowFontScale(0.89)
	ImGui.TextWrapped(_T("MPSTAT_CONTROLLDER_DESC"))
	ImGui.SetWindowFontScale(1.0)
	ImGui.Spacing()
	ImGui.Separator()
	ImGui.Spacing()

	if (ImGui.BeginCombo(_T("GENERIC_LIST_FILTER"), selectedFilterType)) then
		for _, typeName in ipairs(statFilterTypes) do
			if (ImGui.Selectable(typeName, (typeName == selectedFilterType))) then
				selectedFilterType = typeName
			end
		end
		ImGui.EndCombo()
	end

	statSearchBuff = ImGui.SearchBar("##searchStats", statSearchBuff)

	drawStatCards()
	ImGui.Separator()
	ImGui.Spacing()

	local addLabel  = _T("GENERIC_ADD")
	local addLabelW = ImGui.CalcTextSize(addLabel)
	if (GUI:Button(addLabel, { size = vec2:new(addLabelW + 30, 37) })) then
		ImGui.OpenPopup("##addNewStat")
	end

	if (ImGui.BeginPopupModal("##addNewStat", ImGuiWindowFlags.NoResize | ImGuiWindowFlags.AlwaysAutoResize)) then
		drawNewStatPopup()
		ImGui.EndPopup()
	end
end, nil, true)
