-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local measureBulletWidths = require("includes.frontend.helpers.measure_text_width")
local colMoneyGreen       = Color("#85BB65")

---@type table<string, integer>
local bulletWidths        = {}

---@param warehouse? Warehouse
---@param notOwnedLabel? string Optional label to display if the business isn't owned
return function(warehouse, notOwnedLabel)
	if (not warehouse or not warehouse:IsValid()) then
		if (notOwnedLabel) then
			ImGui.Text(notOwnedLabel)
		end

		return
	end

	local iso         = GVars.backend.language_code
	local bulletWidth = bulletWidths[iso]
	if (not bulletWidth) then
		bulletWidth = measureBulletWidths({
			_T("YRV3_CARGO_AMT"),
			_T("YRV3_VALUE_TOTAL"),
		}, 60.0)

		bulletWidths[iso] = bulletWidth
	end

	local name   = warehouse:GetName()
	local max    = warehouse:GetMaxUnits()
	local prod   = warehouse:GetProductCount()
	local value  = warehouse:GetProductValue()
	local coords = warehouse:GetCoords()

	ImGui.BeginChildEx(name,
		vec2:new(0, 240),
		ImGuiChildFlags.AlwaysUseWindowPadding,
		ImGuiWindowFlags.NoScrollbar
	)

	ImGui.SeparatorText(name)
	if (coords) then
		if (GUI:Button(_T("GENERIC_TELEPORT"))) then
			LocalPlayer:Teleport(coords, false)
		end

		ImGui.SameLine()
		if (GUI:Button(_T("GENERIC_SET_WAYPOINT"))) then
			Game.SetWaypointCoords(coords)
		end
	end
	ImGui.Separator()
	ImGui.Spacing()

	ImGui.BulletText(_T("YRV3_CARGO_AMT"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(
		prod / max,
		-1,
		25,
		_F("%d %s (%d%%)",
			prod,
			_T("YRV3_CRATES_LABEL"),
			(math.floor((prod / max) * 100))
		)
	)

	ImGui.BulletText(_T("YRV3_VALUE_TOTAL"))
	ImGui.SameLine(bulletWidth)
	GUI:Text(string.formatmoney(value), { color = colMoneyGreen })
	ImGui.Spacing()

	ImGui.BeginDisabled(prod >= max)
	ImGui.BeginDisabled(warehouse.auto_fill)
	if GUI:Button(_T("YRV3_RANDOM_CRATES")) then
		warehouse:ReStock()
	end
	ImGui.EndDisabled()

	ImGui.SameLine()
	warehouse.auto_fill, _ = GUI:CustomToggle(_T("YRV3_AUTO_FILL"), warehouse.auto_fill)
	ImGui.EndDisabled()
	ImGui.EndChild()
end
