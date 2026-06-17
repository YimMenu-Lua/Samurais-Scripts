-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local YRV3          = require("includes.features.online.yim_resupplier.YimResupplierV3")
local Pair          = require("includes.classes.Pair")
local clicked       = false
local searchBuffer  = ""
local lastParseTime = TimePoint()
local listboxHeight = 0
local PropertyData  = {} ---@type array<Pair<string, vec3>>
local selectedDest ---@type vec3?

---@param sub_array array<CashSafe|BusinessBase>
local function fromArray(sub_array)
	for _, sub in ipairs(sub_array) do
		local coords = sub:GetCoords()
		if (coords and type(coords) ~= "number") then ---@cast coords vec3
			table.insert(PropertyData, Pair(sub:GetName(), coords))
		end
	end
end

local function readBusinessData()
	if (not lastParseTime:HasElapsed(3000)) then
		return
	end

	PropertyData = {}
	for key, business in YRV3:BusinessIter() do
		if (key == "safes") then
			fromArray(business)
		else
			local coords = business:GetCoords()
			if (not coords or type(coords) == "number") then
				goto continue
			end ---@cast coords vec3

			table.insert(PropertyData, Pair(business:GetName(), coords))
			local getSubs = business.GetSubBusinesses
			if (type(getSubs) == "function") then
				---@diagnostic disable-next-line
				fromArray(getSubs(business))
			end
		end
		::continue::
	end

	local arraySize = #PropertyData
	listboxHeight   = math.min(400, arraySize * ImGui.GetTextLineHeightWithSpacing())
	lastParseTime:Reset()
end

Backend:RegisterEventCallback(Enums.eBackendEvent.RELOAD_UNLOAD, readBusinessData)
Backend:RegisterEventCallback(Enums.eBackendEvent.SESSION_SWITCH, readBusinessData)

---@return boolean clicked, vec3? coords
return function()
	if (not Game.IsOnline()) then
		ImGui.Text(_T("GENERIC_UNAVAILABLE_SP"))
		return false, nil
	end

	readBusinessData()

	searchBuffer = ImGui.SearchBar("##propertySearch", searchBuffer, ImGuiInputTextFlags.None, 420)
	clicked      = false

	if (ImGui.BeginListBox("##propertybrowser", 420, listboxHeight)) then
		for _, pair in ipairs(PropertyData) do
			local name, pos = pair.first, pair.second
			if (not name:lower():find(searchBuffer)) then
				goto continue
			end

			local is_selected = pos == selectedDest
			ImGui.Selectable(name, is_selected)
			if (ImGui.IsItemClicked()) then
				clicked      = true
				selectedDest = pos
			end

			if (is_selected) then
				ImGui.SetItemDefaultFocus()
			end

			::continue::
		end
		ImGui.EndListBox()
	end
	return clicked, selectedDest
end
