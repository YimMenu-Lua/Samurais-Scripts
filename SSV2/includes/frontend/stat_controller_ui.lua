-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local MPStatController = require("includes.modules.MPStatController")
local drawKeyValue     = require("includes.frontend.helpers.draw_kv")
local statChildSize    = vec2:new(0, 170)
local statSearchBuff   = ""
local newStatBuff      = { name = "", type = "", lock_val = nil, autolock = false }
local statDateEditBuff = nil
local currentYear      = os.date("*t").year ---@cast currentYear integer


local dateTimeDefault_t <const> = {
	["year"]  = { min = 1970, max = currentYear },
	["month"] = { min = 1, max = 12 },
	["day"]   = { min = 1, max = 31 },
	["hour"]  = { min = 0, max = 23 },
	["min"]   = { min = 0, max = 59 },
	["sec"]   = { min = 0, max = 59 },
}
local dateTimeOrder_t <const> = {
	"year",
	"month",
	"day",
	"hour",
	"min",
	"sec",
}

local statTypes <const> = { "int", "float", "money", "bool", "string", "posix", "date" }

---@param label string
---@param mpStat MPStat
---@param currentVal integer|float
---@param zeroMin boolean
---@param isFloat boolean
local function drawIntFloatEditor(label, mpStat, currentVal, zeroMin, isFloat)
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

---@param label string
---@param mpStat MPStat
---@param currentVal boolean
local function drawBoolEditor(label, mpStat, currentVal)
	if (select(2, GUI:Checkbox(label, currentVal))) then
		mpStat:Set(not currentVal)
	end
end

---@param mpStat MPStat
---@param current DateTime
local function drawDateEditor(mpStat, current)
	if (not statDateEditBuff) then
		statDateEditBuff = current:AsTable()
	end

	for _, v in pairs(dateTimeOrder_t) do
		local vv = statDateEditBuff[v]
		local default = dateTimeDefault_t[v]
		if (type(vv) ~= "number") then
			statDateEditBuff[v] = tonumber(vv) or dateTimeDefault_t[v].min
		end

		if (v == "year") then
			statDateEditBuff[v] = ImGui.InputInt("Year", statDateEditBuff[v])
			statDateEditBuff[v] = math.clamp(statDateEditBuff[v], default.min, default.max)
		else
			statDateEditBuff[v] = ImGui.SliderInt(v:titlecase(), statDateEditBuff[v], default.min, default.max)
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
	local _type   = mpStat.m_type
	local label   = _F("##%s", mpStat.m_name)
	local current = mpStat:Get()

	if (_type == "int" or _type == "posix" or _type == "money" or _type == "float") then
		drawIntFloatEditor(label, mpStat, current, (_type == "posix"), (_type == "float"))
		return
	end

	if (_type == "bool") then
		drawBoolEditor(label, mpStat, current)
		return
	end

	if (_type == "date") then
		drawDateEditor(mpStat, current)
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
	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChildEx("##statsScroll", vec2:new(0, GVars.ui.window_size.y * 0.7))
	local statList   = MPStatController:GetStats()
	local orderArray = MPStatController:GetStatsOrder()
	for i, name in pairs(orderArray) do
		if (not name:lower():find(statSearchBuff)) then
			goto continue
		end

		ImGui.PushID(i)
		local mpStat = statList[name]
		if (not mpStat) then goto continue end

		drawStatObject(mpStat)
		ImGui.PopID()
		::continue::
	end
	ImGui.EndChild()
end

GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, "SUBTAB_MPSTAT_CONTROLLER", function()
	ImGui.SetWindowFontScale(1.3)
	ImGui.Text(_T("SUBTAB_MPSTAT_CONTROLLER"))

	ImGui.SetWindowFontScale(0.89)
	ImGui.TextWrapped(_T("MPSTAT_CONTROLLDER_DESC"))
	ImGui.SetWindowFontScale(1.0)
	ImGui.Spacing()
	ImGui.Separator()
	ImGui.Dummy(0, 10)

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
