-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local sCooldownButtonLabel, bCooldownParam
local ownsWarehouse              = false
local alwaysPopularClicked       = false
local bigTips                    = false
local bigTipsClicked             = false
local maxSellMissionButtonSize   = vec2:new(80, 30)
local progressBarSize            = vec2:new(300, 25)
local moneyGreen                 = Color("#85BB65")

local tabNames <const>           = {
	"CEO",
	"Hangar",
	"Bunker",
	"Acid Lab",
	"Biker Business",
	"Nightclub",
	"Safes",
	"Money Fronts",
	"Misc",
	"Settings"
}

local money_fronts_order <const> = {
	"YRV3_CWASH_LABEL",
	"YRV3_WEED_SHOP_LABEL",
	"YRV3_HELITOURS_LABEL",
}

local function GetAllCDCheckboxes()
	return GVars.features.yrv3.mc_work_cd
		and GVars.features.yrv3.hangar_cd
		and GVars.features.yrv3.nc_management_cd
		and GVars.features.yrv3.nc_vip_mission_chance
		and GVars.features.yrv3.security_missions_cd
		and GVars.features.yrv3.ie_vehicle_steal_cd
		and GVars.features.yrv3.ie_vehicle_sell_cd
		and GVars.features.yrv3.ceo_crate_buy_cd
		and GVars.features.yrv3.ceo_crate_sell_cd
		and GVars.features.yrv3.dax_work_cd
		and GVars.features.yrv3.garment_rob_cd
		and GVars.features.yrv3.cfr_cd -- chicken factory raid
end

---@param value boolean
local function SetAllCDCheckboxes(value)
	GVars.features.yrv3.mc_work_cd            = value
	GVars.features.yrv3.hangar_cd             = value
	GVars.features.yrv3.nc_management_cd      = value
	GVars.features.yrv3.nc_vip_mission_chance = value
	GVars.features.yrv3.security_missions_cd  = value
	GVars.features.yrv3.ie_vehicle_steal_cd   = value
	GVars.features.yrv3.ie_vehicle_sell_cd    = value
	GVars.features.yrv3.ceo_crate_buy_cd      = value
	GVars.features.yrv3.ceo_crate_sell_cd     = value
	GVars.features.yrv3.dax_work_cd           = value
	GVars.features.yrv3.garment_rob_cd        = value
	GVars.features.yrv3.cfr_cd                = value

	YRV3:SetAllCooldownStatesDirty(true)
end

---@param warehouse? Warehouse
---@param notOwnedLabel? string Optional label to display if the business isn't owned
local function drawWarehouse(warehouse, notOwnedLabel)
	if (not warehouse or not warehouse:IsValid()) then
		if (notOwnedLabel) then
			ImGui.Text(notOwnedLabel)
		end

		return
	end

	local name   = warehouse:GetName()
	local max    = warehouse:GetMaxUnits()
	local prod   = warehouse:GetProductCount()
	local value  = warehouse:GetProductValue()
	local coords = warehouse:GetCoords()

	ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 8)
	ImGui.BeginChild(_F("wh##%s", name),
		0,
		180,
		false,
		ImGuiWindowFlags.NoScrollbar
		| ImGuiWindowFlags.AlwaysUseWindowPadding
	)
	ImGui.SeparatorText(tostring(name))
	ImGui.BulletText(_T("YRV3_CARGO_AMT"))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	ImGui.ProgressBar(
		(prod / max),
		progressBarSize.x,
		progressBarSize.y,
		_F(
			"%d %s (%d%%)",
			prod,
			_T("YRV3_CRATES_LABEL"),
			(math.floor(prod / max) * 100)
		)
	)

	ImGui.BulletText(_T("YRV3_VALUE_TOTAL"))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	GUI:Text(string.formatmoney(value), { color = moneyGreen })
	ImGui.Spacing()

	if (coords) then
		if (GUI:Button(_T("GENERIC_TELEPORT"))) then
			YRV3:Teleport(coords, false)
		end
	end

	ImGui.SameLine()
	ImGui.BeginDisabled(prod >= max)
	ImGui.BeginDisabled(warehouse.auto_fill)
	if GUI:Button(_T("YRV3_RANDOM_CRATES")) then
		warehouse:ReStock()
	end
	ImGui.EndDisabled()
	ImGui.SameLine()
	warehouse.auto_fill, _ = GUI:Checkbox(_T("YRV3_AUTO_FILL"), warehouse.auto_fill)
	ImGui.EndDisabled()
	ImGui.EndChild()
	ImGui.PopStyleVar()
end

---@param bb? BikerBusiness
---@param notOwnedLabel? string Optional label to display if the business isn't owned
local function drawBikerBusiness(bb, notOwnedLabel)
	if (not bb or not bb:IsValid()) then
		if (notOwnedLabel) then
			ImGui.Text(notOwnedLabel)
		end

		return
	end

	local name          = bb:GetName()
	local updgrade1     = bb:HasEquipmentUpgrade()
	local updgrade2     = bb:HasStaffUpgrade()
	local supplies      = bb:GetSuppliesCount()
	local stock         = bb:GetProductCount()
	local totalValue    = bb:GetProductValue()
	local eqLabelCol    = updgrade1 and "green" or "red"
	local staffLabelCol = updgrade2 and "green" or "red"
	local maxUnits      = bb:GetMaxUnits()

	ImGui.SeparatorText(name or "NULL")

	ImGui.BulletText(_T("YRV3_EQUIP_UPGDRADE"))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	GUI:Text(updgrade1 and _T("GENERIC_ACTIVE") or _T("GENERIC_INACTIVE"), { color = Color(eqLabelCol) })

	if (bb:GetIndex() < 6) then
		ImGui.BulletText(_T("YRV3_STAFF_UPGDRADE"))
		ImGui.SameLine()
		ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
		GUI:Text(updgrade2 and _T("GENERIC_ACTIVE") or _T("GENERIC_INACTIVE"), { color = Color(staffLabelCol) })
	end

	ImGui.BulletText(_T("YRV3_SUPPLIES_LABEL"))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	ImGui.ProgressBar((supplies / 100), progressBarSize.x, progressBarSize.y)

	ImGui.BulletText(_T("YRV3_STOCK_LABEL"))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	ImGui.ProgressBar(
		(stock / maxUnits),
		progressBarSize.x,
		progressBarSize.y,
		_F("%d %s (%d%%)", stock, _T("YRV3_CRATES_LABEL"), stock)
	)

	ImGui.BulletText(_T("YRV3_VALUE_TOTAL"))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	GUI:Text(string.formatmoney(totalValue), { color = moneyGreen })
	ImGui.Spacing()
	ImGui.Spacing()

	local coords = bb:GetCoords()
	if (coords) then
		if (GUI:Button(_T("GENERIC_TELEPORT"))) then
			YRV3:Teleport(coords, false)
		end
	end

	ImGui.SameLine()
	ImGui.BeginDisabled(supplies == 100)
	if (GUI:Button(_T("YRV3_FILL_SUPPLIES"))) then
		bb:ReStock()
	end
	ImGui.EndDisabled()

	ImGui.SameLine()
	ImGui.BeginDisabled(stock == maxUnits or supplies < 5 or bb.fast_prod_enabled)
	if (GUI:Button(_T("YRV3_TRIGGER_PROD"), { repeatable = true })) then
		bb:TriggerProduction()
	end
	ImGui.EndDisabled()
	GUI:HelpMarker(_T("YRV3_TRIGGER_PROD_TT"))

	ImGui.SameLine()
	ImGui.BeginDisabled(stock == maxUnits)
	bb.fast_prod_enabled, _ = GUI:Checkbox(_T("YRV3_AUTO_PROD"), bb.fast_prod_enabled)
	ImGui.EndDisabled()
end

local function drawCEOwarehouses()
	if (not YRV3:DoesPlayerOwnAnyWarehouse()) then
		ImGui.Text(_T("YRV3_CEO_NONE_OWNED"))
		return
	end

	local warehouses = YRV3:GetSCWarehouses()
	ownsWarehouse    = warehouses and #warehouses > 0

	for i, wh in ipairs(warehouses) do
		ImGui.PushID(i)
		drawWarehouse(wh)
		ImGui.PopID()
	end

	if (ownsWarehouse) then
		ImGui.Spacing()
		ImGui.SeparatorText(_T("GENERIC_MISC"))
		ImGui.Spacing()
		local bCond = (not script.is_active("gb_contraband_buy") and not script.is_active("fm_content_cargo"))
		ImGui.BeginDisabled(bCond)
		if (GUI:Button(_T("YRV3_FINISH_SOURCE_MISSION"))) then
			YRV3:FinishCEOCargoSourceMission()
		end
		ImGui.EndDisabled()

		if (bCond) then
			GUI:Tooltip(_T("YRV3_FINISH_SOURCE_MISSION_TT"))
		end
	end
end

local function drawHangar()
	drawWarehouse(YRV3:GetHangar(), _T("YRV3_HANGAR_NOT_OWNED"))
end

local function drawBunker()
	drawBikerBusiness(YRV3:GetBunker(), _T("YRV3_BUNKER_NOT_OWNED"))
end

local function drawAcidLab()
	drawBikerBusiness(YRV3:GetAcidLab(), _T("YRV3_LSD_LAB_NOT_OWNED"))
end

local function drawBikerBusinesses()
	if (not YRV3:DoesPlayerOwnAnyBikerBusiness()) then
		ImGui.Text(_T("YRV3_MC_NONE_OWNED"))
		return
	end

	for i, bb in ipairs(YRV3:GetBikerBusinesses()) do
		ImGui.PushID(i)
		drawBikerBusiness(bb)
		ImGui.PopID()
	end
end

local tempHubVal = 0
local function drawNightclub()
	local club = YRV3:GetNightclub()
	if (not club) then
		ImGui.Text(_T("YRV3_CLUB_NOT_OWNED"))
		return
	end

	local businessHubTotalValue = 0

	ImGui.BeginChild("##nightclub",
		0,
		130,
		true,
		ImGuiWindowFlags.NoScrollbar
		| ImGuiWindowFlags.AlwaysUseWindowPadding
	)

	ImGui.SetWindowFontScale(1.18)
	local custom_name = club:GetCustomName()
	local custom_name_width = ImGui.CalcTextSize(custom_name)
	ImGui.SetCursorPosX((ImGui.GetContentRegionAvail() - custom_name_width - 10) * 0.5)
	ImGui.Text(custom_name)

	ImGui.Spacing()
	ImGui.SetWindowFontScale(0.8)
	local prop_name = club:GetName() or "Nightclub"
	local prop_name_width = ImGui.CalcTextSize(prop_name)
	ImGui.SetCursorPosX((ImGui.GetContentRegionAvail() - prop_name_width - 10) * 0.5)
	ImGui.Text(prop_name)
	ImGui.SetWindowFontScale(1)

	local tp_label = _T("GENERIC_TELEPORT")
	local tp_label_width = ImGui.CalcTextSize(tp_label) + (ImGui.GetStyle().FramePadding.x * 2)
	local coords = club:GetCoords()
	ImGui.SetCursorPosX((ImGui.GetContentRegionAvail() - tp_label_width) * 0.5)
	if (coords) then
		if (GUI:Button(_T("GENERIC_TELEPORT"))) then
			YRV3:Teleport(coords)
		end
	end
	ImGui.EndChild()
	ImGui.Spacing()

	local cashValue = club:GetCashValue()
	local popValue  = club:GetPopularity()
	local maxCash   = club:GetMaxCash()

	ImGui.BulletText(_F("%s: ", _T("YRV3_POPULARITY")))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	ImGui.ProgressBar(popValue / 1e3,
		progressBarSize.x,
		progressBarSize.y,
		_F("%d%%", math.floor(popValue / 10))
	)

	ImGui.BulletText(_F("%s: ", _T("GENERIC_SAFE")))
	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
	ImGui.ProgressBar(
		cashValue / maxCash,
		progressBarSize.x,
		progressBarSize.y,
		string.formatmoney(cashValue)
	)

	ImGui.Spacing()

	ImGui.SameLine()
	ImGui.BeginDisabled(popValue >= 999)
	if (GUI:Button(_F("%s %s", _T("GENERIC_MAX"), _T("YRV3_POPULARITY")))) then
		club:MaxPopularity()
	end
	ImGui.EndDisabled()

	ImGui.SameLine()
	GVars.features.yrv3.nc_always_popular, alwaysPopularClicked = GUI:Checkbox(
		_T("YRV3_NC_ALWAYS_POPULAR"),
		GVars.features.yrv3.nc_always_popular
	)

	if (alwaysPopularClicked) then
		if (GVars.features.yrv3.nc_always_popular) then
			club:LockPopularityDecay()
		else
			club:RestorePopularityDecay()
		end
	end

	ImGui.SameLine()
	bigTips, bigTipsClicked = GUI:Checkbox(_T("YRV3_MILLION_DOLLAR_TIPS"), bigTips)

	if (bigTipsClicked) then
		club:ToggleBigTips(bigTips)
	end

	GUI:Tooltip(_T("YRV3_MILLION_DOLLAR_TIPS_TT"))

	local hubs = club:GetBusinessHubs()
	if (not hubs) then
		return
	end

	local hubsize = #hubs
	if (hubsize == 0) then
		return
	end

	ImGui.Spacing()
	ImGui.SeparatorText(_T("YRV3_BUSINESS_HUB"))
	ImGui.Spacing()
	ImGui.BulletText(_T("YRV3_VALUE_TOTAL"))
	ImGui.SameLine()
	GUI:Text(string.formatmoney(tempHubVal), { color = moneyGreen })

	for i = 1, hubsize do
		ImGui.SetNextWindowBgAlpha(0)
		ImGui.PushID(i)
		ImGui.BeginChild("##hub_child",
			90,
			300,
			false,
			ImGuiWindowFlags.NoScrollbar
			| ImGuiWindowFlags.AlwaysUseWindowPadding
		)
		local this            = hubs[i]
		local prod            = this:GetProductCount()
		local hub_value       = this:GetProductValue()
		businessHubTotalValue = businessHubTotalValue + hub_value


		local hub_name   = this:GetName() or _F("Hub %d", i)
		local text_width = ImGui.CalcTextSize(hub_name)
		ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (ImGui.GetContentRegionAvail() - text_width) * 0.5)
		ImGui.Text(hub_name)

		ImGui.SetWindowFontScale(0.68)
		local max_units   = this:GetMaxUnits()
		local prod_txt    = _F("%s/%s", prod, max_units)
		local text_width2 = ImGui.CalcTextSize(prod_txt)
		ImGui.SetCursorPosX(ImGui.GetCursorPosX() + (ImGui.GetContentRegionAvail() - text_width2) * 0.5)
		ImGui.Text(prod_txt)
		ImGui.SetWindowFontScale(1)

		ImGui.Spacing()

		ImGui.SetCursorPosX((ImGui.GetCursorPosX() + 35) * 0.5)
		ImGui.ValueBar(
			_F("##bb_hub_%d", i),
			prod / max_units,
			vec2:new(35, 140),
			0,
			1,
			ImGuiValueBarFlags.VERTICAL
		)

		ImGui.SetCursorPosX((ImGui.GetCursorPosX() + 40) * 0.5)
		ImGui.BeginDisabled(prod >= max_units)
		this.fast_prod_enabled, _ = GUI:Checkbox("##fast_prod", this.fast_prod_enabled)
		ImGui.EndDisabled()
		GUI:Tooltip(_T("YRV3_TRIGGER_PROD_HUB_TT"))

		local prod_time       = this:GetTimeLeftBeforeProd()
		local safe_to_trigger = this:CanTriggerProduction() and not this.fast_prod_running
		local btn_label       = (safe_to_trigger or prod_time <= -1)
			and _T("YRV3_TRIGGER_PROD_HUB")
			or ImGui.TextSpinner()
		local btn_size        = vec2:new(65, 30)

		ImGui.BeginDisabled(not safe_to_trigger or prod >= max_units)
		if (GUI:Button(btn_label, { size = btn_size })) then
			this:TriggerProduction()
		end
		ImGui.EndDisabled()

		ImGui.EndChild()
		ImGui.PopID()

		ImGui.SameLine()
		if (ImGui.GetContentRegionAvail() < 90) then
			ImGui.NewLine()
		end
	end

	tempHubVal = businessHubTotalValue
end

local function drawBusinessSafes()
	local safes = YRV3:GetBusinessSafes()
	if (not safes) then
		return
	end

	for name, data in pairs(safes) do
		if (not data.is_owned()) then
			goto continue
		end

		local hasSpecial = type(data.get_special_val) == "function"
		ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 8)
		ImGui.BeginChild(name,
			0,
			hasSpecial and 200 or 160,
			false,
			ImGuiWindowFlags.NoScrollbar
			| ImGuiWindowFlags.AlwaysUseWindowPadding
		)
		ImGui.PushID(name)
		local cashValue    = data.cash_value()
		local specialValue = hasSpecial and data.get_special_val() or 0

		ImGui.SeparatorText(name)
		ImGui.Spacing()

		if (hasSpecial) then
			ImGui.BulletText(_F("%s: ", _T("YRV3_POPULARITY")))
			ImGui.SameLine()
			ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
			ImGui.ProgressBar(specialValue / 1e3,
				progressBarSize.x,
				progressBarSize.y,
				_F("%d%%", math.floor(specialValue / 10))
			)
		end

		ImGui.BulletText(_F("%s: ", _T("GENERIC_SAFE")))
		ImGui.SameLine()
		ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - progressBarSize.x)
		ImGui.ProgressBar(cashValue / data.max_cash,
			progressBarSize.x,
			progressBarSize.y,
			string.formatmoney(cashValue)
		)

		ImGui.Spacing()

		if (GUI:Button(_F("%s##%s", _T("GENERIC_TELEPORT"), name))) then
			YRV3:Teleport(data.blip)
		end

		if (hasSpecial) then
			ImGui.SameLine()
			ImGui.BeginDisabled(specialValue >= 1e3)
			if GUI:Button(_F("%s %s##", _T("GENERIC_MAX"), _T("YRV3_POPULARITY"), name)) then
				data.set_special_val()
				Notifier:ShowSuccess("YRV3", _T("YRV3_POPULARITY_NOTIF"))
			end
			ImGui.EndDisabled()
		end

		ImGui.PopID()
		ImGui.EndChild()
		ImGui.PopStyleVar()

		::continue::
	end
end

local function drawMoneyFronts()
	local mf_data = YRV3:GetMoneyFrontsBusiness()
	if (not mf_data or not mf_data["YRV3_CWASH_LABEL"] or not mf_data["YRV3_CWASH_LABEL"].is_owned()) then
		ImGui.Text(_T("YRV3_CWASH_NOT_OWNED"))
		return
	end

	for i = 1, #money_fronts_order do
		local label = money_fronts_order[i]
		local data  = mf_data[label]

		if (not data.is_owned()) then
			goto continue
		end

		local region_width, _ = ImGui.GetContentRegionAvail()
		ImGui.PushID(label)
		ImGui.SeparatorText(_T(label))

		if (GUI:Button(_T("GENERIC_TELEPORT"))) then
			YRV3:Teleport(data.coords, false)
		end

		if (data.cash_value) then
			local cw_dirty_cash          = data.dirty_cash()
			local cw_clean_cash          = data.duffel_total() - cw_dirty_cash
			local cw_safe_cash           = data.cash_value()
			local dirty_cash_text        = string.formatmoney(cw_dirty_cash)
			local clean_cash_text        = string.formatmoney(cw_clean_cash)
			local cw_cash_text           = _F("%s %s | %s %s",
				_T("YRV3_CWASH_CASH_DIRTY"),
				dirty_cash_text,
				_T("YRV3_CWASH_CASH_CLEAN"),
				clean_cash_text
			)
			local duffel_cash_text_width = ImGui.CalcTextSize(cw_cash_text)
			ImGui.BulletText(_T("YRV3_CWASH_WORK_EARNINGS"))
			ImGui.SameLine()
			ImGui.SetCursorPosX(region_width - duffel_cash_text_width)
			ImGui.Text(cw_cash_text)
			ImGui.Spacing()
			ImGui.BulletText(_T("GENERIC_SAFE"))
			ImGui.SameLine()
			ImGui.SetCursorPosX(region_width - 240)
			ImGui.ProgressBar(cw_safe_cash / (data.max_cash or 1), 240, 32, string.formatmoney(cw_safe_cash))
		end

		local heat = data.get_special_val()
		local heatcol = math.max(0, heat / 100)
		local clearButtonLabel = _T("GENERIC_CLEAR")
		local clearButtonWidth, _ = ImGui.CalcTextSize(clearButtonLabel)
		local style = ImGui.GetStyle()
		ImGui.BulletText(_T("YRV3_CWASH_HEAT"))
		ImGui.SameLine()
		ImGui.SetCursorPosX(region_width - clearButtonWidth - 240 - (style.ItemSpacing.x * 2))
		ImGui.BeginDisabled(heat == 0)
		if (GUI:Button(_T("GENERIC_CLEAR"))) then
			data.set_special_val()
		end
		ImGui.EndDisabled()
		ImGui.SameLine()
		ImGui.PushStyleColor(ImGuiCol.PlotHistogram, heatcol, 1 - heatcol, 0, 1)
		ImGui.ProgressBar(heat / (data.max_heat or 100), 240, 32, _F("%d%%", heat))
		ImGui.PopStyleColor()

		local cb1_val = table.get_nested_key(GVars, data.gvar_key_1)
		cb1_val, data.cb1_clicked = GUI:Checkbox(_T("YRV3_CWASH_LEGAL_WORK_CD"), cb1_val)
		if (data.cb1_clicked) then
			data.on_cb1_click(YRV3, cb1_val)
		end

		local cb2_val = table.get_nested_key(GVars, data.gvar_key_2)
		cb2_val, data.cb2_clicked = GUI:Checkbox(_T("YRV3_CWASH_ILLEGAL_WORK_CD"), cb2_val)
		if (data.cb2_clicked) then
			data.on_cb2_click(YRV3, cb2_val)
		end

		ImGui.PopID()
		ImGui.Spacing()

		::continue::
	end
end

local cooldownsGrid = GridRenderer.new(1)
cooldownsGrid:AddCheckbox("YRV3_CEO_BUY_CB", "features.yrv3.ceo_crate_buy_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("ceo_crate_buy_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_CEO_SELL_CB", "features.yrv3.ceo_crate_sell_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("ceo_crate_sell_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_CLUB_WORK_CB", "features.yrv3.mc_work_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("mc_work_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_HANGAR_STEAL_CB", "features.yrv3.hangar_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("hangar_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_NC_MANAGMENT_CB", "features.yrv3.nc_management_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("nc_management_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_NC_CHANCE_ENCOUNTER_CB", "features.yrv3.nc_vip_mission_chance", {
	persistent = true,
	isTranslatorLabel = true,
	tooltip = "YRV3_NC_CHANCE_ENCOUNTER_TT",
	onClick = function()
		YRV3:SetCooldownStateDirty("nc_vip_mission_chance", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_HACKER_DEN_CD_CB", "features.yrv3.garment_rob_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("garment_rob_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_CFR_CD_CB", "features.yrv3.cfr_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("cfr_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_DAX_WORK_CB", "features.yrv3.dax_work_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("dax_work_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_IE_VEH_STEAL_CB", "features.yrv3.ie_vehicle_steal_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("ie_vehicle_steal_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_IE_VEH_SELL_CB", "features.yrv3.ie_vehicle_sell_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("ie_vehicle_sell_cd", true)
	end
})

cooldownsGrid:AddCheckbox("YRV3_SECURITY_WORK_CB", "features.yrv3.security_missions_cd", {
	persistent = true,
	isTranslatorLabel = true,
	onClick = function()
		YRV3:SetCooldownStateDirty("security_missions_cd", true)
	end
})

local function drawMisc()
	ImGui.SeparatorText(_T("YRV3_COOLDOWNS_LABEL"))

	cooldownsGrid:Draw()

	ImGui.BeginDisabled()
	ImGui.Checkbox(_F("%s [x]", _T("YRV3_PAYHPONE_HITS_CB")), false)
	ImGui.EndDisabled()
	if (ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and KeyManager:IsKeyJustPressed(eVirtualKeyCodes.TAB)) then
		local url = "https://github.com/YimMenu-Lua/PayphoneHits"
		Notifier:ShowMessage("YRV3", _F(_T("GENERIC_URL_COPY_SUCCESS"), url), true, 6)
		ImGui.SetClipboardText(url)
	end
	GUI:Tooltip(_T("YRV3_SEXY_SHINABI_NOTICE"))

	ImGui.Dummy(1, 5)
	if (GetAllCDCheckboxes()) then
		sCooldownButtonLabel, bCooldownParam = "YRV3_CB_UNCHECK_ALL", false
	else
		sCooldownButtonLabel, bCooldownParam = "YRV3_CB_CHECK_ALL", true
	end

	if (GUI:Button(_T(sCooldownButtonLabel), { size = vec2:new(120, 40) })) then
		SetAllCDCheckboxes(bCooldownParam)
	end

	ImGui.Spacing()
	ImGui.SeparatorText(_T("YRV3_SELL_MISSIONS_LABEL"))

	ImGui.Spacing()
	ImGui.TextWrapped(_T("YRV3_SELL_MISSIONS_TT"))

	ImGui.Spacing()
	GUI:Text(_T("YRV3_SELL_MISSIONS_NOTE"), Color("yellow"))

	for name, data in pairs(YRV3:GetSaleMissionTunables()) do
		local isFloat      = (data.type == "float")
		local get_func     = isFloat and tunables.get_float or tunables.get_int
		local set_func     = isFloat and tunables.set_float or tunables.set_int
		local desiredValue = isFloat and 0.0 or 1
		local style        = ImGui.GetStyle()
		local label        = _F("Easy %s Missions", name) -- I'm not even going to bother translating these
		local buttonWidth  = ImGui.CalcTextSize(label) + (style.FramePadding.x * 2)
		if (buttonWidth > maxSellMissionButtonSize.x) then
			maxSellMissionButtonSize.x = buttonWidth
		end

		if (GUI:Button(label, { size = maxSellMissionButtonSize })) then
			for _, index in pairs(data.tuneable) do
				if get_func(index) ~= desiredValue then
					set_func(index, desiredValue)
				end
			end

			Notifier:ShowSuccess("YRV3", _F(_T("YRV3_SELL_MISSIONS_NOTIF"), name:lower()))
		end

		ImGui.SameLine()
		if (ImGui.GetContentRegionAvail() <= (buttonWidth + style.ItemSpacing.x)) then
			ImGui.NewLine()
		end
	end
end

local function drawSettings()
	ImGui.SeparatorText(_T("YRV3_AUTO_SELL"))
	ImGui.TextWrapped(_T("YRV3_AUTO_SELL_SUPPORT_NOTICE"))
	ImGui.BulletText(_T("YRV3_AUTOSELL_BUNKER_LABEL"))
	ImGui.BulletText(_T("YRV3_AUTOSELL_HANGAR_LABEL"))
	ImGui.BulletText(_T("YRV3_AUTOSELL_CEO_LABEL"))
	ImGui.BulletText(_T("YRV3_AUTOSELL_BIKER_LABEL"))
	ImGui.BulletText(_T("YRV3_AUTOSELL_LSD_LAB_LABEL"))
	ImGui.Spacing()
	local autoSellTriggered = YRV3:HasTriggeredAutoSell()
	ImGui.BeginDisabled(autoSellTriggered)
	GVars.features.yrv3.autosell, _ = GUI:Checkbox(_T("YRV3_AUTO_SELL"), GVars.features.yrv3.autosell)
	ImGui.EndDisabled()
	GUI:Tooltip(_T("YRV3_AUTOSELL_TT"))

	if (script.is_active("fm_content_smuggler_sell")) then
		GUI:Text(_T("YRV3_HANGAR_LAND_ERR"), Color("red"))
	else
		ImGui.BeginDisabled(GVars.features.yrv3.autosell
			or autoSellTriggered
			or not YRV3:IsAnySaleInProgress()
		)
		if (GUI:Button(_T("YRV3_AUTO_SELL_MANUAL"))) then
			autoSellTriggered = true
			YRV3:FinishSale()
			ThreadManager:Run(function()
				repeat
					yield()
				until not YRV3:IsAnySaleInProgress()
				autoSellTriggered = false
			end)
		end
		ImGui.EndDisabled()
	end

	ImGui.Text(_F(_T("YRV3_AUTOSELL_CURRENT"), YRV3:GetRunningSellScriptDisplayName()))

	ImGui.SeparatorText(_T("YRV3_AUTO_FILL"))
	ImGui.Text(_T("YRV3_AUTO_FILL_DELAY"))
	ImGui.SetNextItemWidth(280)
	GVars.features.yrv3.autofill_delay, _ = ImGui.SliderFloat("##autofilldelay",
		GVars.features.yrv3.autofill_delay,
		100,
		5000,
		"%.0f ms"
	)
	ImGui.SameLine()
	ImGui.Text(_F("%.1f %s", GVars.features.yrv3.autofill_delay / 1000, _T("GENERIC_SECONDS_LABEL")))
end

local tabCallbacks <const> = {
	[tabNames[1]]  = drawCEOwarehouses,
	[tabNames[2]]  = drawHangar,
	[tabNames[3]]  = drawBunker,
	[tabNames[4]]  = drawAcidLab,
	[tabNames[5]]  = drawBikerBusinesses,
	[tabNames[6]]  = drawNightclub,
	[tabNames[7]]  = drawBusinessSafes,
	[tabNames[8]]  = drawMoneyFronts,
	[tabNames[9]]  = drawMisc,
	[tabNames[10]] = drawSettings,
}

local function YRV3UI()
	if (not YRV3:CanAccess()) then
		ImGui.Text(_T("GENERIC_UNAVAILABLE_SP"))
		return
	end

	if (not YRV3:IsDataInitialized()) then
		ImGui.TextDisabled(ImGui.TextSpinner(_T("GENERIC_WAIT_LABEL")))
		return
	end

	progressBarSize.x = math.max(progressBarSize.x, GVars.ui.window_size.x * 0.4)

	if ImGui.BeginChild("##yrv3_header", 0, 100, true, ImGuiWindowFlags.AlwaysUseWindowPadding) then
		local title       = _T("YRV3_MCT_TITLE")
		local textWidth   = ImGui.CalcTextSize(title) + ImGui.GetStyle().FramePadding.x + 10
		local regionWidth = ImGui.GetWindowWidth()
		ImGui.SetCursorPosX((regionWidth - textWidth) / 2)

		if (GUI:Button(title)) then
			if (YRV3:IsAnySaleInProgress()) then
				Notifier:ShowMessage("YRV3", _T("YRV3_MCT_UNAVAIL"))
			else
				YRV3:MCT()
				GUI:Close(true)
			end
		end

		ImGui.Spacing()
		ImGui.SetWindowFontScale(0.9)
		ImGui.BulletText(_T("YRV3_INCOME_APPROX_ALL"))
		ImGui.SameLine()
		GUI:Text(string.formatmoney(YRV3:GetEstimatedIncome()), { color = moneyGreen })
		ImGui.SetWindowFontScale(1)
		ImGui.EndChild()
	end

	ImGui.Spacing()
	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##yrv3_wrapped_tb", 0, math.max(400, GVars.ui.window_size.y - 200), false)
	if (ImGui.BeginTabBar("##yrv3_tb")) then
		for i = 1, #tabNames do
			local name = tabNames[i]
			local cb   = tabCallbacks[name]
			if (ImGui.BeginTabItem(name)) then
				cb()
				ImGui.EndTabItem()
			end
		end
		ImGui.EndTabBar()
	end
	ImGui.EndChild()
end

GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, "YimResupplierV3", YRV3UI)
