-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local drawNamePlate       = require("includes.frontend.yim_resupplier.nameplate_ui")
local drawFactory         = require("includes.frontend.yim_resupplier.factory_ui")
local measureBulletWidths = require("includes.frontend.helpers.measure_text_width")
local YRV3                = require("includes.features.online.yim_resupplier.YimResupplierV3")

---@type array<integer>
local bulletWidths        = {}

return function()
	local clubhouse = YRV3:GetClubhouse()
	if (not clubhouse) then
		ImGui.Text(_T("YRV3_CLUBHOUSE_NOT_OWNED"))
		return
	end

	drawNamePlate(
		clubhouse,
		clubhouse:GetCustomName(),
		Color(ImGui.GetStyleColorVec4(ImGuiCol.Text))
	)
	ImGui.Spacing()

	local lang_index  = GVars.backend.language_index
	local bulletWidth = bulletWidths[lang_index]
	if (not bulletWidth) then
		bulletWidth = measureBulletWidths({
			_T("YRV3_CASH_SAFE"),
			_T("YRV3_MC_CLIENT_BIKE_LABEL"),
		}, 60.0)

		bulletWidths[lang_index] = bulletWidth
	end

	local cashSafe  = clubhouse:GetCashSafe()
	local cashValue = cashSafe:GetCashValue()
	local maxCash   = cashSafe:GetCapacity()

	ImGui.BulletText(_T("YRV3_CASH_SAFE"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(
		cashValue / maxCash,
		-1,
		25,
		string.formatmoney(cashValue)
	)

	ImGui.BulletText(_T("YRV3_MC_CLIENT_BIKE_LABEL"))
	ImGui.SameLine(bulletWidth)
	ImGui.Text(clubhouse:GetClientBikeName())

	ImGui.Spacing()
	ImGui.SeparatorText(_T("YRV3_BUSINESSES_LABEL"))

	local subs = clubhouse:GetSubBusinesses()
	if (not subs or #subs == 0) then
		ImGui.Text(_T("YRV3_MC_NONE_OWNED"))
		return
	end

	ImGui.BeginTabBar("##mc_businesses")
	for i, bb in ipairs(subs) do
		local norm_name = bb:GetNormalizedName()
		local name      = norm_name or _T("GENERIC_UNKNOWN")
		ImGui.PushID(i)
		if (ImGui.BeginTabItem(name)) then
			drawFactory(bb)
			ImGui.EndTabItem()
		end
		ImGui.PopID()
	end
	ImGui.EndTabBar()
end
