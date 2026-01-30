-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local sCooldownButtonLabel, bCooldownParam
local alwaysPopularClicked     = false
local bigTips                  = false
local bigTipsClicked           = false
local coloredNameplate         = false
local maxSellMissionButtonSize = vec2:new(80, 30)
local progressBarSize          = vec2:new(300, 25)
local moneyGreen               = Color("#85BB65")

local tabNames <const>         = {
	"CEO",
	"Hangar",
	"MC",
	"Bunker",
	"Acid Lab",
	"Nightclub",
	"Safes",
	"Car Wash",
	"ChopShop",
	"Misc",
	"Settings"
}

local selectedTabName          = tabNames[1]

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

local function measureBulletWidths(labels)
	local max = 0
	for i = 1, #labels do
		local w = ImGui.CalcTextSize(labels[i])
		if w > max then
			max = w
		end
	end

	return max + 60 + ImGui.GetStyle().ItemSpacing.x
end

---@param business BusinessFront
---@param custom_name string
---@param bg Color
---@param tpKeepVeh? boolean
local function drawNamePlate(business, custom_name, bg, tpKeepVeh)
	ImGui.BeginChild("##nightclub",
		0,
		130,
		true,
		ImGuiWindowFlags.NoScrollbar
		| ImGuiWindowFlags.AlwaysUseWindowPadding
	)

	ImGui.SetWindowFontScale(1.18)
	local custom_name_width = ImGui.CalcTextSize(custom_name)
	ImGui.SetCursorPosX((ImGui.GetContentRegionAvail() - custom_name_width - 10) * 0.5)
	ImGui.TextColored(bg.r, bg.g, bg.b, bg.a, custom_name)

	ImGui.Spacing()
	ImGui.SetWindowFontScale(0.8)
	local prop_name = business:GetName() or "Club"
	if (prop_name == custom_name) then
		ImGui.Text("")
	else
		local prop_name_width = ImGui.CalcTextSize(prop_name)
		ImGui.SetCursorPosX((ImGui.GetContentRegionAvail() - prop_name_width - 10) * 0.5)
		ImGui.Text(prop_name)
	end
	ImGui.SetWindowFontScale(1)

	local tp_label       = _T("GENERIC_TELEPORT")
	local tp_label_width = ImGui.CalcTextSize(tp_label) + (ImGui.GetStyle().FramePadding.x * 2)
	local coords         = business:GetCoords()
	ImGui.SetCursorPosX((ImGui.GetContentRegionAvail() - tp_label_width) * 0.5)
	if (coords) then
		if (GUI:Button(_T("GENERIC_TELEPORT"))) then
			YRV3:Teleport(coords, tpKeepVeh)
		end
	end
	ImGui.EndChild()
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

	local bulletWidth = measureBulletWidths({
		_T("YRV3_CARGO_AMT"),
		_T("YRV3_VALUE_TOTAL"),
	})

	local name        = warehouse:GetName()
	local max         = warehouse:GetMaxUnits()
	local prod        = warehouse:GetProductCount()
	local value       = warehouse:GetProductValue()
	local coords      = warehouse:GetCoords()

	ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 8)
	ImGui.BeginChild(_F("wh##%s", name),
		0,
		240,
		false,
		ImGuiWindowFlags.NoScrollbar
		| ImGuiWindowFlags.AlwaysUseWindowPadding
	)

	ImGui.SeparatorText(name)
	if (coords) then
		if (GUI:Button(_T("GENERIC_TELEPORT"))) then
			YRV3:Teleport(coords, false)
		end
	end
	ImGui.Separator()
	ImGui.Spacing()

	ImGui.BulletText(_T("YRV3_CARGO_AMT"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(
		prod / max,
		-1,
		progressBarSize.y,
		_F(
			"%d %s (%d%%)",
			prod,
			_T("YRV3_CRATES_LABEL"),
			(math.floor(prod / max) * 100)
		)
	)

	ImGui.BulletText(_T("YRV3_VALUE_TOTAL"))
	ImGui.SameLine(bulletWidth)
	GUI:Text(string.formatmoney(value), { color = moneyGreen })
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

	local bulletWidth   = measureBulletWidths({
		_T("YRV3_EQUIP_UPGDRADE"),
		_T("YRV3_STAFF_UPGDRADE"),
		_T("YRV3_SUPPLIES_LABEL"),
		_T("YRV3_STOCK_LABEL"),
		_T("YRV3_VALUE_TOTAL"),
	})

	local name          = bb:GetName()
	local updgrade1     = bb:HasEquipmentUpgrade()
	local updgrade2     = bb:HasStaffUpgrade()
	local supplies      = bb:GetSuppliesCount()
	local stock         = bb:GetProductCount()
	local totalValue    = bb:GetProductValue()
	local eqLabelCol    = updgrade1 and "green" or "red"
	local staffLabelCol = updgrade2 and "green" or "red"
	local maxUnits      = bb:GetMaxUnits()

	ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 8)
	ImGui.BeginChild(_F("bb##%s", name),
		0,
		bb:GetIndex() < 6 and 330 or 300,
		false,
		ImGuiWindowFlags.NoScrollbar
		| ImGuiWindowFlags.AlwaysUseWindowPadding
	)

	ImGui.SeparatorText(name or "NULL")

	local coords = bb:GetCoords()
	if (coords) then
		if (GUI:Button(_T("GENERIC_TELEPORT"))) then
			YRV3:Teleport(coords, false)
		end

		ImGui.Separator()
	end

	ImGui.BulletText(_T("YRV3_EQUIP_UPGDRADE"))
	ImGui.SameLine(bulletWidth)
	GUI:Text(updgrade1 and _T("GENERIC_ACTIVE") or _T("GENERIC_INACTIVE"), { color = Color(eqLabelCol) })

	if (bb:GetIndex() < 6) then
		ImGui.BulletText(_T("YRV3_STAFF_UPGDRADE"))
		ImGui.SameLine(bulletWidth)
		GUI:Text(updgrade2 and _T("GENERIC_ACTIVE") or _T("GENERIC_INACTIVE"), { color = Color(staffLabelCol) })
	end

	ImGui.BulletText(_T("YRV3_SUPPLIES_LABEL"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(supplies / 100, -1, progressBarSize.y)

	ImGui.BulletText(_T("YRV3_STOCK_LABEL"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(stock / maxUnits, -1, progressBarSize.y)

	ImGui.BulletText(_T("YRV3_VALUE_TOTAL"))
	ImGui.SameLine(bulletWidth)
	GUI:Text(string.formatmoney(totalValue), { color = moneyGreen })
	ImGui.Spacing()

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
	bb.fast_prod_enabled, _ = GUI:CustomToggle(_T("YRV3_AUTO_PROD"), bb.fast_prod_enabled)
	ImGui.EndDisabled()

	ImGui.EndChild()
	ImGui.PopStyleVar()
end

local function drawCEOwarehouses()
	local warehouses = YRV3:GetSCWarehouses()
	if (not warehouses or #warehouses == 0) then
		ImGui.Text(_T("YRV3_CEO_NONE_OWNED"))
		return
	end

	for i, wh in ipairs(warehouses) do
		ImGui.PushID(i)
		drawWarehouse(wh)
		ImGui.PopID()
	end

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

	local cashSafe  = clubhouse:GetCashSafe()
	local cashValue = cashSafe:GetCashValue()
	local maxCash   = cashSafe:GetMaxCash()
	ImGui.BulletText(_T("YRV3_CASH_SAFE"))
	ImGui.SameLine(ImGui.GetContentRegionAvail() * 0.4)
	ImGui.ProgressBar(
		cashValue / maxCash,
		-1,
		progressBarSize.y,
		string.formatmoney(cashValue)
	)
	ImGui.Separator()
	ImGui.Dummy(0, 10)

	local subs = clubhouse:GetSubBusinesses()
	if (not subs or #subs == 0) then
		ImGui.Text(_T("YRV3_MC_NONE_OWNED"))
		return
	end

	ImGui.BeginTabBar("##mc_businesses")
	for i, bb in ipairs(subs) do
		local norm_name = bb:GetNormalizedName()
		local name      = norm_name or bb:GetName() or _F("Unk %d", i)
		if (ImGui.BeginTabItem(name)) then
			drawBikerBusiness(bb)
			ImGui.EndTabItem()
		end
	end
	ImGui.EndTabBar()
end

local function getClubNameColor()
	if (not coloredNameplate) then
		return Color(ImGui.GetStyleColorVec4(ImGuiCol.Text))
	end

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

local tempHubVal = 0
local function drawNightclub()
	local businessHubTotalValue = 0
	local club = YRV3:GetNightclub()
	if (not club) then
		ImGui.Text(_T("YRV3_CLUB_NOT_OWNED"))
		return
	end

	local bg = getClubNameColor()
	ImGui.PushStyleColor(ImGuiCol.Border, bg:AsU32())
	drawNamePlate(club, club:GetCustomName(), bg)
	ImGui.PopStyleColor()
	coloredNameplate, _ = GUI:CustomToggle("Synthwave & Pain", coloredNameplate)
	ImGui.Spacing()

	local popValue    = club:GetPopularity()
	local cash_safe   = club:GetCashSafe()
	local cashValue   = cash_safe:GetCashValue()
	local maxCash     = cash_safe:GetMaxCash()
	local bulletWidth = measureBulletWidths({
		_T("YRV3_POPULARITY"),
		_T("YRV3_CASH_SAFE"),
	})

	ImGui.BulletText(_T("YRV3_POPULARITY"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(popValue / 1e3,
		-1,
		progressBarSize.y,
		_F("%d%%", math.floor(popValue / 10))
	)

	ImGui.BulletText(_T("YRV3_CASH_SAFE"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(
		cashValue / maxCash,
		-1,
		progressBarSize.y,
		string.formatmoney(cashValue)
	)

	ImGui.Spacing()

	ImGui.BeginDisabled(popValue >= 999)
	if (GUI:Button(_F("%s %s", _T("GENERIC_MAX"), _T("YRV3_POPULARITY")))) then
		club:MaxPopularity()
	end
	ImGui.EndDisabled()

	GVars.features.yrv3.nc_always_popular, alwaysPopularClicked = GUI:CustomToggle(
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

	bigTips, bigTipsClicked = GUI:CustomToggle(_T("YRV3_MILLION_DOLLAR_TIPS"), bigTips)

	if (bigTipsClicked) then
		club:ToggleBigTips(bigTips)
	end

	GUI:HelpMarker(_T("YRV3_MILLION_DOLLAR_TIPS_TT"))

	local hubs = club:GetSubBusinesses()
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
		this.fast_prod_enabled, _ = GUI:CustomToggle("##fast_prod", this.fast_prod_enabled)
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
	if (not safes or #safes == 0) then
		return
	end

	for i, cashSafe in ipairs(safes) do
		local name = cashSafe:GetName() or _F("Cash Safe %d", i)
		ImGui.PushID(i)
		ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 8)
		ImGui.BeginChild(name,
			0,
			160,
			false,
			ImGuiWindowFlags.NoScrollbar
			| ImGuiWindowFlags.AlwaysUseWindowPadding
		)
		local cashValue = cashSafe:GetCashValue()
		local maxCash   = cashSafe:GetMaxCash()
		local coords    = cashSafe:GetCoords()
		ImGui.SeparatorText(name)
		if (coords) then
			if (GUI:Button(_F("%s##%s", _T("GENERIC_TELEPORT"), name))) then
				YRV3:Teleport(coords)
			end
		end
		ImGui.Separator()
		ImGui.Spacing()

		ImGui.BulletText(_F("%s: ", _T("YRV3_CASH_SAFE")))
		ImGui.SameLine()
		ImGui.ProgressBar(cashValue / maxCash,
			-1,
			progressBarSize.y,
			string.formatmoney(cashValue)
		)

		ImGui.EndChild()
		ImGui.PopStyleVar()
		ImGui.PopID()
	end
end

---@param business CarWash|CarWashSubBusiness
---@param isParent boolean
---@param kvSpacing number
---@param clearHeatLabel string
local function drawBasicBusiness(business, isParent, kvSpacing, clearHeatLabel)
	if (not business) then
		return
	end

	local name    = business:GetName()
	local coords  = business:GetCoords()
	local heat    = business:GetHeat()
	local maxHeat = 100

	ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 8)
	ImGui.BeginChild(name,
		0,
		isParent and 360 or 280,
		false,
		ImGuiWindowFlags.AlwaysUseWindowPadding
		| ImGuiWindowFlags.NoScrollbar
	)

	ImGui.SeparatorText(name)
	if (coords) then
		if (GUI:Button(_T("GENERIC_TELEPORT"))) then
			YRV3:Teleport(coords, false)
		end
	end
	ImGui.Separator()
	ImGui.Spacing()

	if (isParent) then
		---@diagnostic disable-next-line
		local duffle          = business:GetDuffleBag()
		---@diagnostic disable-next-line
		local cashSafe        = business:GetCashSafe()
		local maxCash         = cashSafe:GetMaxCash()
		local cw_dirty_cash   = duffle:GetDirtyCash()
		local cw_clean_cash   = duffle:GetDuffleValue()
		local cw_safe_cash    = cashSafe:GetCashValue()
		local dirty_cash_text = string.formatmoney(cw_dirty_cash)
		local clean_cash_text = string.formatmoney(cw_clean_cash)
		local cw_cash_text    = _F("%s %s | %s %s",
			_T("YRV3_CWASH_CASH_DIRTY"),
			dirty_cash_text,
			_T("YRV3_CWASH_CASH_CLEAN"),
			clean_cash_text
		)

		ImGui.BulletText(_T("YRV3_CWASH_WORK_EARNINGS"))
		ImGui.SameLine(kvSpacing)
		ImGui.Text(cw_cash_text)
		ImGui.Spacing()
		ImGui.BulletText(_T("YRV3_CASH_SAFE"))
		ImGui.SameLine(kvSpacing)
		ImGui.ProgressBar(
			cw_safe_cash / maxCash,
			-1,
			progressBarSize.y,
			string.formatmoney(cw_safe_cash)
		)
	end

	if (heat) then
		local heatcol = math.clamp(heat / 100, 0, 1)
		ImGui.BulletText(_T("YRV3_CWASH_HEAT"))
		ImGui.SameLine(kvSpacing)
		ImGui.PushStyleColor(ImGuiCol.PlotHistogram, heatcol, 1 - heatcol, 0, 1)
		ImGui.ProgressBar(
			heat / maxHeat,
			-1,
			progressBarSize.y,
			_F("%d%%", heat)
		)
		ImGui.PopStyleColor()

		ImGui.BeginDisabled(heat == 0)
		if (GUI:Button(clearHeatLabel)) then
			business:ClearHeat()
		end
		ImGui.EndDisabled()
		ImGui.Spacing()
	end

	GUI:CustomToggle(_T("YRV3_CWASH_LEGAL_WORK_CD"),
		business:GetLegalWorkCooldownState(),
		{
			onClick = function()
				business:ToggleLegalWorkCooldown()
			end
		}
	)

	GUI:CustomToggle(_T("YRV3_CWASH_ILLEGAL_WORK_CD"),
		business:GetIllegalWorkCooldownState(),
		{
			onClick = function()
				business:ToggleIllegalWorkCooldown()
			end
		}
	)

	ImGui.EndChild()
	ImGui.PopStyleVar()
end

local function drawMoneyFronts()
	local carWash = YRV3:GetCarWash()
	if (not carWash) then
		ImGui.Text(_T("YRV3_CWASH_NOT_OWNED"))
		return
	end

	local clearHeatLabel = _F("%s %s", _T("GENERIC_CLEAR"), _T("YRV3_CWASH_HEAT"))
	local bulletWidth = measureBulletWidths({
		_T("YRV3_CWASH_WORK_EARNINGS"),
		_T("YRV3_CASH_SAFE"),
		_T("YRV3_CWASH_HEAT"),
		clearHeatLabel
	})

	drawBasicBusiness(carWash, true, bulletWidth, clearHeatLabel)

	local subs = carWash:GetSubBusinesses()
	if (not subs or #subs == 0) then
		return
	end

	for _, sub in ipairs(subs) do
		drawBasicBusiness(sub, false, bulletWidth, clearHeatLabel)
	end
end

local function drawSalvageYard()
	local salvage_yard = YRV3:GetSalvageYard()
	if (not salvage_yard) then
		ImGui.Text(_T("SY_NOT_OWNED"))
		return
	end

	drawNamePlate(
		salvage_yard,
		salvage_yard:GetName(),
		Color(ImGui.GetStyleColorVec4(ImGuiCol.Text)),
		true
	)

	ImGui.Spacing()

	local childWidth  = 260
	local cash_safe   = salvage_yard:GetCashSafe()
	local cashValue   = cash_safe:GetCashValue()
	local maxCash     = cash_safe:GetMaxCash()
	local bulletWidth = measureBulletWidths({
		_T("YRV3_CASH_SAFE"),
		_T("SY_INCOME_THRESHOLD"),
	})

	ImGui.BulletText(_T("YRV3_CASH_SAFE"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(
		cashValue / maxCash,
		-1,
		progressBarSize.y,
		string.formatmoney(cashValue)
	)

	local threshold = salvage_yard:GetIncomeThreshold()
	ImGui.BulletText(_T("SY_INCOME_THRESHOLD"))
	ImGui.SameLine(bulletWidth)
	ImGui.ProgressBar(threshold / 100, -1, progressBarSize.y)

	ImGui.BeginDisabled(salvage_yard:GetIncomeThreshold() >= 100)
	if (GUI:Button(_T("SY_MAX_THRESHOLD"))) then
		salvage_yard:MaximizeIncome()
	end
	ImGui.EndDisabled()

	ImGui.SameLine()
	ImGui.Spacing()
	ImGui.SameLine()
	GVars.features.yrv3.sy_always_max_income, _ = GUI:CustomToggle(
		_T("SY_ALWAYS_MAX_INCOME"),
		GVars.features.yrv3.sy_always_max_income,
		{
			onClick = function(v)
				if (v) then
					salvage_yard:LockIncomeDecay()
				else
					salvage_yard:RestoreIncomeDecay()
				end
			end,
		}
	)
	GUI:HelpMarker(_T("SY_ALWAYS_MAX_INCOME_TT"))

	ImGui.Spacing()
	ImGui.BeginTabBar("##salvage_yard_tb")
	if (ImGui.BeginTabItem(_T("SY_CHOP_SHOP"))) then
		for i = 1, 2 do
			local isTaken = salvage_yard:IsLiftTaken(i)
			ImGui.SetNextWindowBgAlpha(0.64)
			ImGui.BeginDisabled(not isTaken)
			ImGui.BeginChild(
				_F("##lift%d", i),
				childWidth,
				isTaken and 180 or 100,
				false,
				ImGuiWindowFlags.NoScrollbar
				| ImGuiWindowFlags.AlwaysUseWindowPadding
			)
			ImGui.SeparatorText(_F(_T("SY_LIFT"), i))
			ImGui.Spacing()

			if (not isTaken) then
				ImGui.Text(_T("SY_LIFT_EMPTY"))
			else
				local vehName   = vehicles.get_vehicle_display_name(salvage_yard:GetCarModelOnLift(i))
				local value     = string.formatmoney(salvage_yard:GetCarValueOnLift(i))
				local nameWidth = ImGui.CalcTextSize(vehName)
				local valWidth  = ImGui.CalcTextSize(value)

				ImGui.BulletText(_T("GENERIC_VEHICLE"))
				ImGui.SameLine()
				ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - nameWidth - 10)
				ImGui.Text(vehName)

				ImGui.BulletText(_T("GENERIC_VALUE"))
				ImGui.SameLine()
				ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - valWidth - 10)
				GUI:Text(value, Color("#00AA00"))

				ImGui.Spacing()

				if (GUI:Button(_T("SY_INSTANT_SALVAGE"))) then
					salvage_yard:SalvageNow(i)
				end
			end
			ImGui.EndChild()
			ImGui.EndDisabled()
			ImGui.SameLine()
			if (ImGui.GetContentRegionAvail() < childWidth) then
				ImGui.NewLine()
			end
		end
		ImGui.EndTabItem()
	end

	if (ImGui.BeginTabItem(_T("SY_CAR_ROBBERIES"))) then
		GUI:CustomToggle(
			_T("SY_DISABLE_COOLDOWN"),
			GVars.features.yrv3.sy_disable_rob_cd,
			{
				onClick = function()
					YRV3:SetCooldownStateDirty("sy_disable_rob_cd", true)
				end
			}
		)

		ImGui.SameLine()
		GUI:CustomToggle(
			_T("SY_DISABLE_WEEKLY_COOLDOWN"),
			GVars.features.yrv3.sy_disable_rob_weekly_cd,
			{
				onClick = function()
					YRV3:SetCooldownStateDirty("sy_disable_rob_weekly_cd", true)
				end
			}
		)

		ImGui.Spacing()

		ImGui.SeparatorText(_T("SY_WEEKLY_ROBBERIES"))
		for i = 0, 2 do
			ImGui.Text(_F(_T("SY_WEEKLY_CAR_STATUS"), i + 1, salvage_yard:GetWeeklyRobberyStatus(i)))
			ImGui.Separator()
		end

		ImGui.Spacing()

		ImGui.Text(_F(_T("SY_CURRENT_ROBBERY"), salvage_yard:GetRobberyName()))
		if (salvage_yard:IsRobberyActive()) then
			ImGui.Text(
				_F(_T("SY_ROBBERY_ACTIVE_CAR"),
					salvage_yard:GetRobberyVehicleName())
			)
			ImGui.Text(_F(_T("SY_ROBBERY_CAR_VALUE"), salvage_yard:GetRobberyValue()))
			ImGui.Text(_F(_T("SY_ROBBERY_CAN_KEEP_CAR"), tostring(salvage_yard:GetRobberyKeepState())))

			if (GUI:Button(_T("SY_DOUBLE_CAR_WORTH"))) then
				salvage_yard:DoubleCarWorth()
			end

			ImGui.SameLine()
			ImGui.BeginDisabled(salvage_yard:ArePrepsCompleted())
			if (GUI:Button(_T("SY_COMPLETE_PREPARATIONS"))) then
				salvage_yard:SkipPreps()
			end
			ImGui.EndDisabled()
		end

		ImGui.Spacing()

		for i = 1, 4 do
			local carName = salvage_yard:GetRobberyCarInSlot(i)
			local isAvailable = carName and not carName:isempty()
			ImGui.SetNextWindowBgAlpha(0.64)
			ImGui.BeginDisabled(not isAvailable)
			ImGui.BeginChild(
				_F("##robbery%d", i),
				childWidth,
				isAvailable and 180 or 100,
				false,
				ImGuiWindowFlags.NoScrollbar
				| ImGuiWindowFlags.AlwaysUseWindowPadding
			)

			ImGui.SeparatorText(_F(_T("SY_VEH_SLOT"), i))
			if (not isAvailable) then
				ImGui.Text(_T("SY_EMPTY"))
			else
				local nameWidth = ImGui.CalcTextSize(carName)
				local carValue  = string.formatmoney(salvage_yard:GetRobberyCarValue(i))
				local valWidth  = ImGui.CalcTextSize(carValue)
				ImGui.BulletText(_T("GENERIC_VEHICLE"))
				ImGui.SameLine()
				ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - nameWidth - 10)
				ImGui.Text(carName)

				ImGui.BulletText(_T("GENERIC_VALUE"))
				ImGui.SameLine()
				ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - valWidth - 10)
				GUI:Text(string.formatmoney(carValue), Color("#00AA00"))
			end

			ImGui.EndChild()
			ImGui.EndDisabled()
			ImGui.SameLine()
			if (ImGui.GetContentRegionAvail() < childWidth) then
				ImGui.NewLine()
			end
		end
		ImGui.EndTabItem()
	end
	ImGui.EndTabBar()
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

	ImGui.Spacing()
	ImGui.BeginDisabled()
	ImGui.Toggle(_F("%s [x]", _T("YRV3_PAYHPONE_HITS_CB")), false)
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
	GVars.features.yrv3.autosell, _ = GUI:CustomToggle(_T("YRV3_AUTO_SELL"), GVars.features.yrv3.autosell)
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
	[tabNames[3]]  = drawBikerBusinesses,
	[tabNames[4]]  = drawBunker,
	[tabNames[5]]  = drawAcidLab,
	[tabNames[6]]  = drawNightclub,
	[tabNames[7]]  = drawBusinessSafes,
	[tabNames[8]]  = drawMoneyFronts,
	[tabNames[9]]  = drawSalvageYard,
	[tabNames[10]] = drawMisc,
	[tabNames[11]] = drawSettings,
}

---@return boolean
local function handleYRV3State()
	local __state = YRV3:GetState()
	local message = YRV3:GetLastError()

	if (__state == Enums.eYRState.RUNNING) then
		return true
	end

	if (__state == Enums.eYRState.LOADING) then
		message = ImGui.TextSpinner(message)
	end

	if (__state == Enums.eYRState.ERROR) then
		ImGui.TextColored(0.9, 0.1, 0.1, 1.0, message)
	else
		ImGui.Text(message)
	end

	return false
end

local function YRV3UI()
	if (not handleYRV3State()) then
		return
	end

	local headerHeight   = 100.0
	local windowHeight   = math.max(400, GVars.ui.window_size.y - headerHeight - 100.0)
	local sidebarWidth   = 90.0
	local separatorWidth = 3.0

	if (ImGui.BeginChild("##yrv3_header", 0, headerHeight, true, ImGuiWindowFlags.AlwaysUseWindowPadding)) then
		local title     = _T("YRV3_MCT_TITLE")
		local textWidth = ImGui.CalcTextSize(title) + (ImGui.GetStyle().FramePadding.x * 2)
		ImGui.SetCursorPosX((ImGui.GetContentRegionAvail() - textWidth) * 0.5)

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
		GUI:Text(string.formatmoney(YRV3:GetEstimatedIncome() or 0), { color = moneyGreen })
		ImGui.SetWindowFontScale(1)
		ImGui.EndChild()
	end

	ImGui.Spacing()
	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##yrv3_2", 0, windowHeight, false)

	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##yrv3_3", sidebarWidth, 0, false)
	for i = 1, #tabNames do
		local name = tabNames[i]
		if (ImGui.Selectable2(
				name,
				name == selectedTabName,
				vec2:new(sidebarWidth, 27),
				"center",
				true
			)) then
			selectedTabName = name
		end
	end
	ImGui.EndChild()

	ImGui.SameLine()
	ImGui.VerticalSeparator(separatorWidth)
	ImGui.SameLine()

	ImGui.SetNextWindowBgAlpha(0)
	ImGui.BeginChild("##yrv3_4")
	local callback = tabCallbacks[selectedTabName]
	if (type(callback) == "function") then
		callback()
	end
	ImGui.EndChild()

	ImGui.EndChild()
end

GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, "YimResupplierV3", YRV3UI)
