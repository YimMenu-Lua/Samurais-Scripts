-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local YRV3                  = require("includes.features.online.yim_resupplier.YimResupplierV3")
local clubNames             = require("includes.data.yrv3_data").NightclubNames
local measureBulletWidths   = require("includes.frontend.helpers.measure_text_width")
local drawNamePlate         = require("includes.frontend.yim_resupplier.nameplate_ui")
local colMoneyGreen <const> = Color("#85BB65")
local hubChildWidth         = 300
local tempHubVal            = 0
local bools                 = {
	coloredNameplate      = false,
	bigTips               = false,
	techTransferEmptyOnly = false,
	drawRenamePopup       = false
}
local renamePopupLabel      = "##renameNightclub"

---@type array<integer>
local bulletWidths          = {}

local function getClubNameColor()
	-- synthwave and pain
	local t      = os.clock()
	local beat   = (math.sin(t * 1.8) + 1) * 0.5
	local accent = ((math.sin(t * 6.0) + 1) * 0.5) ^ 1.5
	local hue    = (t * 0.05) % 1.0
	local base   = Color(12, 12, 18, 220)
	local glow   = Color.FromHSV(hue, 0.7, 0.8, 1)
	local flash  = Color.FromHSV((hue + 0.2) % 1.0, 0.9, 1.0, 1)
	local bg     = base:Mix(glow, beat * 0.6)
	return bg:Mix(flash, accent * 0.8)
end

Backend:RegisterEventCallback(Enums.eBackendEvent.SESSION_SWITCH, function()
	bools.bigTips = false
end)

---@param club Nightclub
local function drawRenamePopup(club)
	ImGui.Spacing()

	local name_id = stats.get_int("MPX_PROP_NIGHTCLUB_NAME_ID")
	if (ImGui.BeginCombo("##clubName", clubNames[name_id + 1])) then
		for i, name in ipairs(clubNames) do
			local real_id     = i - 1
			local is_selected = name_id == real_id

			ImGui.Selectable(name, is_selected)
			if (ImGui.IsItemClicked()) then
				club:Rename(real_id)
				GUI:PlaySound(GUI.Sounds.Click)
				ImGui.EndCombo()
				ImGui.CloseCurrentPopup()
				return
			end

			if (is_selected) then
				ImGui.SetItemDefaultFocus()
			end
		end
		ImGui.EndCombo()
	end

	ImGui.Spacing()
end

local function contextCallback()
	bools.coloredNameplate = GUI:CustomToggle("Synthwave & Pain", bools.coloredNameplate)

	ImGui.Spacing()
	ImGui.Separator()

	if (ImGui.MenuItem(_T("GENERIC_RENAME"))) then
		bools.shouldDrawRenamePopup = true
		ImGui.CloseCurrentPopup()
	end
	ImGui.Separator()
end

return function()
	local club = YRV3:GetNightclub()
	if (not club) then
		ImGui.Text(_T("YRV3_CLUB_NOT_OWNED"))
		return
	end

	local HubTotalValue      = 0
	local unsafeFeatsEnabled = GVars.features.unsafe_feats_enabled
	local bg
	if (bools.coloredNameplate) then
		bg = getClubNameColor()
		ImGui.PushStyleColor(ImGuiCol.Border, bg:AsU32())
	end

	local customName = club:GetCustomName()
	drawNamePlate(club, { customName = customName, bgColor = bg, contextMenuCallback = contextCallback })

	if (bools.coloredNameplate) then
		ImGui.PopStyleColor()
	end

	local lang_index  = GVars.backend.language_index
	local bulletWidth = bulletWidths[lang_index]
	if (not bulletWidth) then
		bulletWidth = measureBulletWidths({
			_T("YRV3_POPULARITY"),
			_T("YRV3_CASH_SAFE"),
		}, 60.0)

		bulletWidths[lang_index] = bulletWidth
	end

	local popValue  = club:GetPopularity()
	local cashSafe  = club:GetCashSafe()
	local cashValue = cashSafe:GetCashValue()
	local maxCash   = cashSafe:GetCapacity()

	ImGui.BulletText(_T("YRV3_POPULARITY"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(popValue / 1e3,
		-1,
		25,
		_F("%d%%", math.floor(popValue / 10))
	)

	ImGui.BulletText(_T("YRV3_CASH_SAFE"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(
		cashValue / maxCash,
		-1,
		25,
		string.formatmoney(cashValue)
	)

	ImGui.Spacing()

	ImGui.BeginDisabled(popValue >= 999)
	if (GUI:Button(_F("%s %s", _T("GENERIC_MAX"), _T("YRV3_POPULARITY")))) then
		club:MaxPopularity()
	end
	ImGui.EndDisabled()

	ImGui.BeginDisabled(not unsafeFeatsEnabled)
	if (cashSafe:CanInstaFill()) then
		ImGui.BeginDisabled(cashValue == maxCash)
		if (GUI:Button(_T("YRV3_CASH_FILL"))) then
			cashSafe:FillNow()
		end
		ImGui.EndDisabled()
		GUI:HelpMarker(_T("YRV3_CASH_FILL_TT"))
	end

	if (cashSafe:CanLoop()) then
		ImGui.BeginDisabled(cashValue >= maxCash)
		cashSafe.cash_loop_enabled = GUI:CustomToggle(_T("YRV3_CASH_LOOP"), cashSafe.cash_loop_enabled)
		ImGui.EndDisabled()
	end
	ImGui.EndDisabled()

	GVars.features.yrv3.nc_always_popular = GUI:CustomToggle(_T("YRV3_NC_ALWAYS_POPULAR"),
		GVars.features.yrv3.nc_always_popular,
		{ onClick = function(v) club:TogglePopulatirtyLock(v) end }
	)

	bools.bigTips = GUI:CustomToggle(_T("YRV3_MILLION_DOLLAR_TIPS"), bools.bigTips,
		{ onClick = function(v) club:ToggleBigTips(v) end }
	)
	GUI:HelpMarker(_T("YRV3_MILLION_DOLLAR_TIPS_TT"))

	local hubs = club:GetSubBusinesses()
	if (not hubs) then return end

	local hubsize = #hubs
	if (hubsize == 0) then return end

	ImGui.Spacing()
	ImGui.SeparatorText(_T("YRV3_BUSINESS_HUB"))

	ImGui.BulletText(_T("YRV3_VALUE_TOTAL"))
	ImGui.SameLine()
	GUI:Text(string.formatmoney(tempHubVal), { color = colMoneyGreen })
	ImGui.Separator()
	ImGui.Spacing()

	hubChildWidth = math.min(hubChildWidth, ImGui.GetWindowWidth())

	for i = 1, hubsize do
		local this     = hubs[i]
		local tech_idx = this:GetAssignedTechIndex()
		local has_tech = tech_idx ~= -1

		ImGui.PushID(i)
		ImGui.SetNextWindowBgAlpha(0.64)
		ImGui.BeginChildEx("##hub_child",
			vec2:new(hubChildWidth, has_tech and 280 or 240),
			ImGuiChildFlags.AlwaysUseWindowPadding | ImGuiChildFlags.Borders,
			ImGuiWindowFlags.NoScrollbar
		)

		local prod      = this:GetProductCount()
		local hub_value = this:GetProductValue()
		local hub_name  = this:GetName() or _F("Hub %d", i)

		ImGui.BeginDisabled(not has_tech)
		ImGui.SeparatorText(hub_name)
		ImGui.SetWindowFontScale(0.68)
		local max_units   = this:GetMaxUnits()
		local prod_txt    = _F("%s/%s", prod, max_units)
		local text_width2 = ImGui.CalcTextSize(prod_txt)
		local regionWidth = ImGui.GetContentRegionAvail()
		ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (regionWidth - text_width2) * 0.5)
		ImGui.Text(prod_txt)
		ImGui.SetWindowFontScale(1)

		ImGui.Spacing()
		ImGui.ValueBar(
			"##bb_hub",
			prod / max_units,
			vec2:new(-1, 60),
			ImGuiValueBarFlags.VERTICAL
		)

		-- TODO: Fix glitchy behavior + session disconnect on Enhanced
		ImGui.BeginDisabled(not unsafeFeatsEnabled)
		ImGui.BeginDisabled(Game.IsEnhanced())

		local is_maxed = prod >= max_units
		ImGui.BeginDisabled(is_maxed)
		this.fast_prod_enabled = GUI:CustomToggle(_T("YRV3_AUTO_PROD"), this.fast_prod_enabled)
		ImGui.EndDisabled()
		GUI:Tooltip(_T("YRV3_TRIGGER_PROD_HUB_TT"))

		local prod_time          = this:GetTimeLeftBeforeProd()
		local safe_to_trigger    = this:CanTriggerProduction() and not this.fast_prod_enabled
		local trigger_label      = _T("YRV3_TRIGGER_PROD")
		local trigger_label_w    = ImGui.CalcTextSize(trigger_label) + (ImGui.GetStyle().FramePadding.x * 2)
		local btn_label          = (safe_to_trigger or prod_time < 0) and trigger_label or ImGui.TextSpinner()
		local transfer_popup_lbl = _F("##transfer_tech_%d", i)

		ImGui.BeginDisabled(not safe_to_trigger or is_maxed)
		if (GUI:Button(btn_label, { size = vec2:new(trigger_label_w, 0) })) then
			this:TriggerProduction()
		end
		ImGui.EndDisabled()

		ImGui.EndDisabled() -- enhanced
		ImGui.EndDisabled() -- no technician
		ImGui.EndDisabled() -- unsafe feats

		if (not has_tech) then
			if (not is_maxed) then
				GUI:Tooltip(_T("YRV3_HUB_TECH_NOT_ASSIGNED_TT"))
			end
		elseif (GUI:Button(_T("YRV3_HUB_TRANSFER_TECH"))) then
			ImGui.OpenPopup(transfer_popup_lbl)
		end

		if (ImGui.BeginPopup(transfer_popup_lbl)) then
			bools.techTransferEmptyOnly = GUI:CustomToggle(_T("YRV3_HUB_TRANSFER_TECH_REL_ONLY"), bools.techTransferEmptyOnly)
			GUI:HelpMarker(_T("YRV3_HUB_TRANSFER_TECH_REL_ONLY_TT"))
			ImGui.Separator()
			ImGui.Spacing()

			for _, hub in ipairs(hubs) do
				if (hub == this) then
					goto continue
				end

				if (bools.techTransferEmptyOnly and (hub:HasTechnician() or hub:HasFullProduction())) then
					goto continue
				end

				if (ImGui.MenuItem(hub:GetName())) then
					club:TransferTechnician(this, hub)
					ImGui.CloseCurrentPopup()
				end

				::continue::
			end

			ImGui.Separator()
			ImGui.Spacing()

			if (ImGui.Button(_T("GENERIC_CANCEL"))) then
				ImGui.CloseCurrentPopup()
			end
			ImGui.EndPopup()
		end

		ImGui.EndChild()
		ImGui.PopID()

		HubTotalValue = HubTotalValue + hub_value
		ImGui.SameLineIfAvail(hubChildWidth)
	end

	tempHubVal = HubTotalValue

	if (bools.shouldDrawRenamePopup) then
		ImGui.OpenPopup(renamePopupLabel)
		bools.shouldDrawRenamePopup = false
	end

	if (ImGui.BeginPopupModal(
			renamePopupLabel,
			true,
			ImGuiWindowFlags.AlwaysAutoResize
			| ImGuiWindowFlags.NoSavedSettings
			| ImGuiWindowFlags.NoMove
		)) then
		drawRenamePopup(club)
		ImGui.EndPopup()
	end
end
