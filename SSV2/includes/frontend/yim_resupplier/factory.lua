-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local measureBulletWidths = require("includes.frontend.helpers.measure_text_width")
local colMoneyGreen       = Color("#85BB65")
local COL_RED <const>     = Color("red")
local COL_GREEN <const>   = Color("green")

---@type array<integer>
local bulletWidths        = {}

---@param bb? Factory
---@param notOwnedLabel? string Optional label to display if the business isn't owned
return function(bb, notOwnedLabel)
	if (not bb or not bb:IsValid()) then
		if (notOwnedLabel) then
			ImGui.Text(notOwnedLabel)
		end

		return
	end

	if (not bb:IsSetup()) then
		ImGui.Text(_T("YRV3_GENERIC_NOT_SETUP"))
		return
	end

	local lang_idx    = GVars.backend.language_index
	local bulletWidth = bulletWidths[lang_idx]
	if (not bulletWidth) then
		bulletWidth = measureBulletWidths({
			_T("YRV3_EQUIP_UPGDRADE"),
			_T("YRV3_STAFF_UPGDRADE"),
			_T("YRV3_SUPPLIES_LABEL"),
			_T("YRV3_STOCK_LABEL"),
			_T("YRV3_VALUE_TOTAL"),
		}, 60.0)

		bulletWidths[lang_idx] = bulletWidth
	end

	local name          = bb:GetName()
	local updgrade1     = bb:HasEquipmentUpgrade()
	local updgrade2     = bb:HasStaffUpgrade()
	local supplies      = bb:GetSuppliesCount()
	local stock         = bb:GetProductCount()
	local totalValue    = bb:GetProductValue()
	local eqLabel       = updgrade1 and "GENERIC_ACTIVE" or "GENERIC_INACTIVE"
	local eqLabelCol    = updgrade1 and COL_GREEN or COL_RED
	local staffLabel    = updgrade2 and "GENERIC_ACTIVE" or "GENERIC_INACTIVE"
	local staffLabelCol = updgrade2 and COL_GREEN or COL_RED
	local maxUnits      = bb:GetMaxUnits()
	local index         = bb:GetIndex() or -1

	ImGui.BeginChildEx(_F("bb##%s", name),
		vec2:new(0, index < 6 and 330 or 300),
		ImGuiChildFlags.AlwaysUseWindowPadding,
		ImGuiWindowFlags.NoScrollbar
	)

	ImGui.SeparatorText(name or "NULL")

	local coords = bb:GetCoords()
	if (coords) then
		if (GUI:Button(_T("GENERIC_TELEPORT"))) then
			LocalPlayer:Teleport(coords, false)
		end

		ImGui.SameLine()
		if (GUI:Button(_T("GENERIC_SET_WAYPOINT"))) then
			Game.SetWaypointCoords(coords)
		end
		ImGui.Separator()
	end

	ImGui.BulletText(_T("YRV3_EQUIP_UPGDRADE"))
	ImGui.SameLine(bulletWidth)
	GUI:Text(_T(eqLabel), { color = eqLabelCol })

	if (index < 6) then
		ImGui.BulletText(_T("YRV3_STAFF_UPGDRADE"))
		ImGui.SameLine(bulletWidth)
		GUI:Text(_T(staffLabel), { color = staffLabelCol })
	end

	ImGui.BulletText(_T("YRV3_SUPPLIES_LABEL"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(supplies / 100, -1, 25)

	ImGui.BulletText(_T("YRV3_STOCK_LABEL"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(stock / maxUnits, -1, 25)

	ImGui.BulletText(_T("YRV3_VALUE_TOTAL"))
	ImGui.SameLine(bulletWidth)
	GUI:Text(string.formatmoney(totalValue), { color = colMoneyGreen })
	ImGui.Spacing()

	ImGui.BeginDisabled(supplies >= 100)
	if (GUI:Button(_T("YRV3_FILL_SUPPLIES"))) then
		bb:ReStock()
	end
	ImGui.EndDisabled()

	ImGui.SameLine()
	ImGui.BeginDisabled(bb.fast_prod_enabled or stock == maxUnits or supplies < 25)
	if (GUI:Button(_T("YRV3_TRIGGER_PROD"), { repeatable = true })) then
		bb:TriggerProduction()
	end
	ImGui.EndDisabled()
	GUI:HelpMarker(_T("YRV3_TRIGGER_PROD_TT"))

	ImGui.SameLine()
	ImGui.BeginDisabled(stock == maxUnits)
	bb.fast_prod_enabled, _ = GUI:CustomToggle(_T("YRV3_AUTO_PROD"), bb.fast_prod_enabled)
	ImGui.EndDisabled()

	ImGui.EndChild()
end
