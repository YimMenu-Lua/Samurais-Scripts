-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BSV2                 = require("includes.features.extra.billionaire_services.BillionaireServicesV2")
local DrawBodyguards       = require("includes.frontend.billionaire_services.bodyguards_ui")
local DrawEscorts          = require("includes.frontend.billionaire_services.escort_groups_ui")
local DrawLimousine        = require("includes.frontend.billionaire_services.limo_ui")
local DrawHeliService      = require("includes.frontend.billionaire_services.heli_ui")
local DrawJetService       = require("includes.frontend.billionaire_services.jet_ui")
local iSelectedSidebarItem = 1
local sPreviousTab         = ""

---@type function?
local funCurrentFooter     = nil
local sCurrentTab          = ""

local function OnTabItemSwitch()
	if (sCurrentTab ~= sPreviousTab) then
		GUI:PlaySound("Nav")
		sPreviousTab = sCurrentTab
	end
end

local function DrawFooter()
	if (type(funCurrentFooter) ~= "function") then
		return
	end

	funCurrentFooter()
end

local SidebarItems <const> = {
	{
		label    = "BSV2_BODYGUARDS_LABEL",
		callback = DrawBodyguards,
	},
	{
		label    = "BSV2_ESCORTS_LABEL",
		callback = DrawEscorts,
	},
	{
		label    = "BSV2_LIMO_LABEL",
		callback = DrawLimousine
	},
	{
		label    = "BSV2_HELI_LABEL",
		callback = DrawHeliService
	},
	{
		label    = "BSV2_JET_LABEL",
		callback = DrawJetService
	},
}

local function DrawSidebarItems()
	local selectedTab = SidebarItems[iSelectedSidebarItem]
	if (selectedTab and type(selectedTab.callback) == "function") then
		sCurrentTab, funCurrentFooter = selectedTab.callback()
	end
end

local dismissAllBtnCols = {
	button        = Color("#FF0000"),
	buttonHovered = Color("#EE4B2B"),
	buttonActive  = Color("#880808")
}

local function DrawMainSidebar()
	ImGui.SetNextWindowBgAlpha(0.0)
	ImGui.BeginChild("##main_sidebar", 160, GVars.ui.window_size.y * 0.6)
	ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 20)
	ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 40)
	if BSV2:GetServiceCount() > 1 then
		if (GUI:Button(_T("GENERIC_DISMISS_ALL"), { colors = dismissAllBtnCols })) then
			BSV2:Dismiss(BSV2.SERVICE_TYPE.ALL)
		end
	else
		ImGui.TextDisabled(_T("GENERIC_DISMISS_ALL"))
	end
	GUI:Tooltip(_T("BSV2_DISMISS_ALL_TT"))

	ImGui.Dummy(1, 20)

	for i, tab in ipairs(SidebarItems) do
		local is_selected = (iSelectedSidebarItem == i)
		if (is_selected) then
			local r, g, b, a = ImGui.GetStyleColorVec4(ImGuiCol.ButtonActive)
			ImGui.PushStyleColor(ImGuiCol.Button, r, g, b, a)
		end

		if (ImGui.Button(_T(tab.label), is_selected and 160 or 120, 35)) then
			GUI:PlaySound(GUI.Sounds.Nav)
			iSelectedSidebarItem = i
		end

		if (is_selected) then
			ImGui.PopStyleColor()
		end
	end

	ImGui.PopStyleVar(2)
	ImGui.EndChild()
end

local function BSV2UI()
	ImGui.BeginGroup()
	DrawMainSidebar()
	ImGui.SameLine()
	ImGui.BeginChildEx("##main",
		vec2:new(0, GVars.ui.window_size.y * 0.6),
		ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding
	)
	DrawSidebarItems()
	ImGui.EndChild()
	ImGui.EndGroup()

	OnTabItemSwitch()
	DrawFooter()
end

GUI:RegisterNewTab(Enums.eTabID.TAB_EXTRA, "Billionaire Services", BSV2UI)
