local sCooldownButtonLabel, bCooldownParam
local SGSL                     = require("includes.structs.SGSL")
local hangarSupplies           = 0
local hangarTotalValue         = 0
local bunkerTotalValue         = 0
local acidLabTotalValue        = 0
local acidLabOwned             = false
local ownsWarehouse            = false
local ownsBikerBusiness        = false
local maxSellMissionButtonSize = vec2:new(80, 30)

local yrv3_state               = {
	disabled = false,
	reason   = _T("GENERIC_CONTACT_DEV")
}

local tabNames <const>         = {
	"CEO",
	"Hangar",
	"Bunker",
	"Acid Lab",
	"Biker Business",
	"Safes",
	"Money Fronts",
	"Misc",
	"Settings"
}

local selectedTabName          = tabNames[1]
local FreemodeGlobal           = SGSL:Get(SGSL.data.freemode_business_global):AsGlobal()

local function CalcTotalBusinessIncome()
	return math.sum(
		YRV3.m_biker_value_sum,
		YRV3.m_ceo_value_sum,
		YRV3.m_safe_cash_sum,
		YRV3.m_cwash_cash_sum,
		hangarTotalValue,
		bunkerTotalValue,
		acidLabTotalValue
	)
end

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
	GVars.features.yrv3.mc_work_cd = value
	GVars.features.yrv3.hangar_cd = value
	GVars.features.yrv3.nc_management_cd = value
	GVars.features.yrv3.nc_vip_mission_chance = value
	GVars.features.yrv3.security_missions_cd = value
	GVars.features.yrv3.ie_vehicle_steal_cd = value
	GVars.features.yrv3.ie_vehicle_sell_cd = value
	GVars.features.yrv3.ceo_crate_buy_cd = value
	GVars.features.yrv3.ceo_crate_sell_cd = value
	GVars.features.yrv3.dax_work_cd = value
	GVars.features.yrv3.garment_rob_cd = value
	GVars.features.yrv3.cfr_cd = value

	YRV3:SetAllCooldownStatesDirty(true)
end

local function drawCEOwarehouses()
	if (not YRV3:DoesPlayerOwnAnyWarehouse()) then
		ImGui.Text(_T("YRV3_CEO_NONE_OWNED"))
		return
	end

	YRV3.m_ceo_value_sum = 0
	for i, wh in ipairs(YRV3.m_warehouse_data) do
		local slot = i - 1
		wh.isOwned = stats.get_int(("MPX_PROP_WHOUSE_SLOT%d"):format(slot)) > 0

		if wh.isOwned then
			ownsWarehouse = true

			if (not YRV3.m_warehouse_data[i].wasChecked) then
				YRV3:PopulateCEOwarehouseSlot(i)
			else
				wh.totalSupplies = stats.get_int(("MPX_CONTOTALFORWHOUSE%d"):format(slot))
				wh.totalValue = YRV3:GetCEOCratesValue(wh.totalSupplies or 0)
				YRV3.m_ceo_value_sum = YRV3.m_ceo_value_sum + wh.totalValue

				if (wh.name and wh.size and wh.max) then
					ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 8)
					ImGui.BeginChild(_F("wh##%d", i),
						0,
						140,
						false,
						ImGuiWindowFlags.NoScrollbar
						| ImGuiWindowFlags.AlwaysUseWindowPadding
					)
					ImGui.PushID(i)
					ImGui.SeparatorText(tostring(wh.name))
					ImGui.BulletText(_T("YRV3_CARGO_AMT"))
					ImGui.SameLine()
					ImGui.Dummy(20, 1)
					ImGui.SameLine()

					ImGui.ProgressBar(
						(wh.totalSupplies / wh.max),
						240,
						30,
						_F(
							"%d %s (%d%%)",
							wh.totalSupplies,
							_T("YRV3_CRATES_LABEL"),
							(math.floor(wh.totalSupplies / wh.max) * 100)
						)
					)
					GUI:Tooltip(_F("%s: %d / %d", wh.name, wh.totalSupplies, wh.max))

					ImGui.SameLine()
					ImGui.Text(string.formatmoney(wh.totalValue))

					if (wh.pos) then
						if GUI:Button(_F("%s##%d", _T("GENERIC_TELEPORT"), i)) then
							YRV3:Teleport(wh.pos)
						end
					end

					ImGui.SameLine()
					ImGui.BeginDisabled(wh.totalSupplies >= wh.max)
					ImGui.BeginDisabled(wh.autoFill)
					if GUI:Button(_F("%s##wh%d", _T("YRV3_RANDOM_CRATES"), i)) then
						stats.set_bool_masked(
							"MPX_FIXERPSTAT_BOOL1",
							true,
							i + 11
						)
					end
					ImGui.EndDisabled()
					ImGui.SameLine()
					YRV3.m_warehouse_data[i].autoFill, _ = GUI:Checkbox(_F("%s##wh%d", _T("YRV3_AUTO_FILL"), i),
						YRV3.m_warehouse_data[i].autoFill)
					ImGui.EndDisabled()
					ImGui.PopID()
					ImGui.EndChild()
					ImGui.PopStyleVar()
				end
			end
		end
	end

	if (ownsWarehouse) then
		ImGui.Spacing()
		ImGui.BulletText(_F("%s: %s", _T("YRV3_VALUE_TOTAL"), string.formatmoney(YRV3.m_ceo_value_sum)))
		ImGui.Dummy(1, 5)
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
	local hangar_index = stats.get_int("MPX_HANGAR_OWNED")
	local hangarOwned = hangar_index ~= 0

	if (not hangarOwned) then
		ImGui.Text(_T("YRV3_HANGAR_NOT_OWNED"))
		return
	end

	local hangar_name = YRV3.t_Hangars[hangar_index].name
	local hangar_pos = YRV3.t_Hangars[hangar_index].coords

	ImGui.SeparatorText(hangar_name)
	hangarSupplies = stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL")
	hangarTotalValue = hangarSupplies * 30000

	ImGui.BulletText(_T("YRV3_SUPPLIES_LABEL"))
	ImGui.SameLine()
	ImGui.Dummy(10, 1)
	ImGui.SameLine()
	ImGui.ProgressBar(
		(hangarSupplies / 50),
		240,
		30
	)

	if (hangarSupplies < 50) then
		ImGui.SameLine()
		ImGui.BeginDisabled(YRV3.m_hangar_loop)
		if GUI:Button(_F("%s##hangar", _T("YRV3_RANDOM_CRATES"))) then
			script.run_in_fiber(function()
				stats.set_bool_masked("MPX_DLC22022PSTAT_BOOL3", true, 9)
			end)
		end
		ImGui.EndDisabled()
		ImGui.SameLine()
		YRV3.m_hangar_loop, _ = GUI:Checkbox(_F("%s##hangar", _T("YRV3_AUTO_FILL")), YRV3.m_hangar_loop)
	end

	ImGui.BulletText(_T("YRV3_STOCK_LABEL"))
	ImGui.SameLine()
	ImGui.Dummy(33, 1)
	ImGui.SameLine()
	ImGui.ProgressBar(
		(hangarSupplies / 50),
		240,
		30,
		_F("%d %s (%d%%)", hangarSupplies, _T("YRV3_CRATES_LABEL"), math.floor(hangarSupplies / 0.5))
	)

	ImGui.SameLine()
	ImGui.Text(_F("%s: %s", _T("YRV3_VALUE_TOTAL"), string.formatmoney(hangarTotalValue)))

	ImGui.Spacing()
	if GUI:Button(_T("GENERIC_QUICK_TP")) then
		YRV3:Teleport(hangar_pos, true)
	end
end

local function drawBunker()
	local bunker_index = stats.get_int("MPX_PROP_FAC_SLOT5")
	local bunkerOwned = bunker_index ~= 0

	if (not bunkerOwned) then
		ImGui.Text(_T("YRV3_BUNKER_NOT_OWNED"))
		return
	end

	ImGui.SeparatorText(YRV3.t_Bunkers[bunker_index].name)

	local bunkerUpdgrade1  = stats.get_int("MPX_BUNKER_EQUIPMENT") == 1
	local bunkerUpdgrade2  = stats.get_int("MPX_BUNKER_STAFF") == 1
	local bunkerOffset1    = 0
	local bunkerOffset2    = 0
	local bunkerEqLabelCol = "white"
	local bunkerStLabelCol = "white"

	if (bunkerUpdgrade1) then
		bunkerOffset1 = tunables.get_int("GR_MANU_PRODUCT_VALUE_EQUIPMENT_UPGRADE")
		bunkerEqLabelCol = "green"
	else
		bunkerOffset1 = 0
		bunkerEqLabelCol = "red"
	end

	if (bunkerUpdgrade2) then
		bunkerOffset2 = tunables.get_int("GR_MANU_PRODUCT_VALUE_STAFF_UPGRADE")
		bunkerStLabelCol = "green"
	else
		bunkerOffset2 = 0
		bunkerStLabelCol = "red"
	end

	local bunkerSupplies = stats.get_int("MPX_MATTOTALFORFACTORY5")
	local bunkerStock = stats.get_int("MPX_PRODTOTALFORFACTORY5")
	bunkerTotalValue = (tunables.get_int("GR_MANU_PRODUCT_VALUE") + bunkerOffset1 + bunkerOffset2) * bunkerStock

	ImGui.BulletText(_T("YRV3_EQUIP_UPGDRADE"))
	ImGui.SameLine()
	GUI:Text(bunkerUpdgrade1 and _T("GENERIC_ACTIVE") or _T("GENERIC_INACTIVE"), Color(bunkerEqLabelCol))

	ImGui.SameLine()
	ImGui.BulletText(_T("YRV3_STAFF_UPGDRADE"))
	ImGui.SameLine()
	GUI:Text(bunkerUpdgrade2 and _T("GENERIC_ACTIVE") or _T("GENERIC_INACTIVE"), Color(bunkerStLabelCol))

	ImGui.Spacing()
	ImGui.BulletText(_T("YRV3_SUPPLIES_LABEL"))
	ImGui.SameLine()
	ImGui.Dummy(10, 1)
	ImGui.SameLine()
	ImGui.ProgressBar((bunkerSupplies / 100), 240, 30)

	ImGui.SameLine()
	ImGui.BeginDisabled(bunkerSupplies >= 100)
	if (GUI:Button(_F(" %s ##bunker", _T("YRV3_FILL_SUPPLIES")))) then
		FreemodeGlobal:At(5):At(1):WriteInt(1)
	end
	ImGui.EndDisabled()

	ImGui.BulletText(_T("YRV3_STOCK_LABEL"))
	ImGui.SameLine()
	ImGui.Dummy(33, 1)
	ImGui.SameLine()
	ImGui.ProgressBar(
		(bunkerStock / 100),
		240,
		30,
		_F("%d %s (%d%%)", bunkerStock, _T("YRV3_CRATES_LABEL"), bunkerStock)
	)

	ImGui.BulletText(_F(
		"%s\tBlaine County: %s | Los Santos: %s",
		_T("YRV3_VALUE_TOTAL"),
		string.formatmoney(bunkerTotalValue),
		string.formatmoney(math.floor(bunkerTotalValue * 1.5))
	))

	ImGui.Spacing()

	if (GUI:Button(_T("GENERIC_QUICK_TP"))) then
		YRV3:Teleport(YRV3.t_Bunkers[bunker_index].coords, true)
	end
end

local function drawAcidLab()
	acidLabOwned = stats.get_int("MPX_XM22_LAB_OWNED") ~= 0
	if (not acidLabOwned) then
		ImGui.Text(_T("YRV3_LSD_LAB_NOT_OWNED"))
		return
	end

	local acidUpdgrade = (stats.get_int("MPX_AWD_CALLME") >= 10)
		and (stats.get_int("MPX_XM22_LAB_EQUIP_UPGRADED") == 1)

	local acidUpgradeLabelCol = "white"
	local acidOffset = 0
	acidUpgradeLabelCol = "red"

	if (acidUpdgrade) then
		acidUpgradeLabelCol = "green"
		acidOffset = tunables.get_int("BIKER_ACID_PRODUCT_VALUE_EQUIPMENT_UPGRADE")
	end

	local acidSupplies = stats.get_int("MPX_MATTOTALFORFACTORY6")
	local acidStock    = stats.get_int("MPX_PRODTOTALFORFACTORY6")
	acidLabTotalValue  = tunables.get_int("BIKER_ACID_PRODUCT_VALUE") + acidOffset * acidStock

	ImGui.BulletText(_T("YRV3_EQUIP_UPGDRADE"))
	ImGui.SameLine()
	GUI:Text(acidUpdgrade and _T("GENERIC_ACTIVE") or _T("GENERIC_INACTIVE"), Color(acidUpgradeLabelCol))
	ImGui.BulletText(_T("YRV3_SUPPLIES_LABEL"))
	ImGui.SameLine()
	ImGui.Dummy(10, 1)
	ImGui.SameLine()
	ImGui.ProgressBar((acidSupplies / 100), 240, 30)

	ImGui.SameLine()
	ImGui.BeginDisabled(acidSupplies >= 100)
	if (GUI:Button(_F(" %s ##acid", _T("YRV3_FILL_SUPPLIES")))) then
		FreemodeGlobal:At(6):At(1):WriteInt(1)
	end
	ImGui.EndDisabled()

	ImGui.BulletText(_T("YRV3_STOCK_LABEL"))
	ImGui.SameLine()
	ImGui.Dummy(33, 1)
	ImGui.SameLine()
	ImGui.ProgressBar(
		(acidStock / 160),
		240,
		30,
		_F(
			"%d %s (%d%%)",
			acidStock,
			_T("YRV3_CRATES_LABEL"),
			math.floor(acidStock / 16 * 10)
		)
	)

	ImGui.SameLine()
	ImGui.Text(_F("%s: %s", _T("YRV3_VALUE_TOTAL"), string.formatmoney(acidLabTotalValue)))

	ImGui.Spacing()
	if (GUI:Button(_T("GENERIC_QUICK_TP"))) then
		YRV3:Teleport(848)
	end
end

local function drawBikerBusiness()
	if (not YRV3:DoesPlayerOwnAnyBikerBusiness()) then
		ImGui.Text(_T("YRV3_MC_NONE_OWNED"))
		return
	end

	YRV3.m_biker_value_sum = 0

	for i, data in ipairs(YRV3.m_biker_data) do
		local slot = i - 1
		local business = YRV3.m_biker_data[i]
		data.isOwned = stats.get_int(_F("MPX_PROP_FAC_SLOT%d", slot)) ~= 0

		if (data.isOwned) then
			ownsBikerBusiness = true

			if (not business.wasChecked) then
				YRV3:PopulateBikerBusinessSlot(i)
			elseif (business.name and business.value_tunable) then
				ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 8)
				ImGui.BeginChild(_F("mc##%d", i),
					0,
					180,
					false,
					ImGuiWindowFlags.NoScrollbar
					| ImGuiWindowFlags.AlwaysUseWindowPadding
				)
				ImGui.PushID(i)
				ImGui.SeparatorText(business.name)

				data.totalSupplies = stats.get_int(_F("MPX_MATTOTALFORFACTORY%d", slot))
				data.totalStock = stats.get_int(_F("MPX_PRODTOTALFORFACTORY%d", slot))
				data.totalValue = tunables.get_int(business.value_tunable) * data.totalStock
				YRV3.m_biker_value_sum = YRV3.m_biker_value_sum + data.totalValue

				ImGui.BulletText(_T("YRV3_SUPPLIES_LABEL"))
				ImGui.SameLine()
				ImGui.Dummy(10, 1)
				ImGui.SameLine()
				ImGui.ProgressBar(data.totalSupplies / 100, 240, 30)

				ImGui.SameLine()
				ImGui.BeginDisabled(data.totalSupplies >= 100)
				if (GUI:Button(_F(" %s ##%d", _T("YRV3_SUPPLIES_FILL"), i))) then
					FreemodeGlobal:At(slot):At(1):WriteInt(1)
				end
				ImGui.EndDisabled()

				ImGui.SameLine()
				if (GUI:Button(_F("%s##%d", _T("GENERIC_TELEPORT"), i))) then
					if (not business.blip) then
						return
					end

					YRV3:Teleport(business.blip)
				end

				ImGui.BulletText(_T("YRV3_STOCK_LABEL"))
				ImGui.SameLine()
				ImGui.Dummy(33, 1)
				ImGui.SameLine()

				ImGui.ProgressBar(
					(data.totalStock / business.unit_max),
					240,
					30,
					_F("%d%%", math.floor(data.totalStock * (100 / business.unit_max)))
				)

				ImGui.BulletText(_F("%s:\tBlaine County: %s | Los Santos: %s",
					_T("YRV3_VALUE_TOTAL"),
					string.formatmoney(data.totalValue),
					string.formatmoney(math.floor(data.totalValue * 1.5))
				))
				ImGui.PopID()
				ImGui.EndChild()
				ImGui.PopStyleVar()
			end
		else
			ImGui.Text(_T("YRV3_GENERIC_NOT_OWNED"))
		end
	end

	if (ownsBikerBusiness) then
		ImGui.Separator()
		ImGui.Spacing()
		ImGui.BulletText(
			_F("%s: %s", _T("YRV3_INCOME_APPROX_MC"), string.formatmoney(YRV3.m_biker_value_sum))
		)
		GUI:Tooltip(_T("YRV3_PRICE_NOTICE"))
	end
end

local function drawBusinessSafes()
	YRV3.m_safe_cash_sum = 0

	for name, data in pairs(YRV3.m_safe_cash_data) do
		if data.isOwned() then
			ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, 8)
			ImGui.BeginChild(name,
				0,
				140,
				false,
				ImGuiWindowFlags.NoScrollbar
				| ImGuiWindowFlags.AlwaysUseWindowPadding
			)
			ImGui.PushID(name)
			local cashValue = data.cashValue()
			YRV3.m_safe_cash_sum = YRV3.m_safe_cash_sum + cashValue

			ImGui.SeparatorText(name)

			if (type(data.getSpecialVal) == "function") then
				local popValue = data.getSpecialVal()
				ImGui.BulletText(_F("%s: ", _T("YRV3_POPULARITY")))
				ImGui.SameLine()
				ImGui.Dummy(18, 1)
				ImGui.SameLine()
				ImGui.ProgressBar(popValue / 1e3, 240, 30, _F("%d%%", math.floor(popValue / 10)))

				if (popValue < 1e3) then
					ImGui.SameLine()

					if GUI:Button(_F("%s %s##", _T("GENERIC_MAX"), _T("YRV3_POPULARITY"), name)) then
						data.setSpecialVal()
						Toast:ShowSuccess("Samurai's Scripts", _T("YRV3_POPULARITY_NOTIF"))
					end
				end
			end

			ImGui.BulletText(_F("%s: ", _T("GENERIC_SAFE")))
			ImGui.SameLine()
			ImGui.Dummy(60, 1)
			ImGui.SameLine()

			ImGui.ProgressBar(cashValue / data.max_cash, 240, 30, string.formatmoney(cashValue))
			ImGui.SameLine()
			if (GUI:Button(_F("%s##%s", _T("GENERIC_TELEPORT"), name))) then
				YRV3:Teleport(data.blip)
			end

			ImGui.PopID()
			ImGui.EndChild()
			ImGui.PopStyleVar()
		end
	end

	ImGui.Separator()
	ImGui.Spacing()
	ImGui.BulletText(_F("%s: %s", _T("YRV3_SAFECASH_TOTAL"), string.formatmoney(YRV3.m_safe_cash_sum)))
end

local money_fronts_order <const> = {
	"YRV3_CWASH_LABEL",
	"YRV3_WEED_SHOP_LABEL",
	"YRV3_HELITOURS_LABEL",
}

local function drawMoneyFronts()
	if (not YRV3.m_money_fronts_data["YRV3_CWASH_LABEL"].isOwned()) then
		ImGui.Text(_T("YRV3_CWASH_NOT_OWNED"))
		return
	end

	YRV3.m_cwash_cash_sum = 0
	for i = 1, #money_fronts_order do
		local label = money_fronts_order[i]
		local data = YRV3.m_money_fronts_data[label]

		if (not data.isOwned()) then
			goto continue
		end

		local region_width, _ = ImGui.GetContentRegionAvail()
		ImGui.PushID(label)
		ImGui.SeparatorText(_T(label))
		if (GUI:Button(_T("GENERIC_TELEPORT"))) then
			Self:Teleport(data.coords, false)
		end

		if (data.cashValue) then
			local cw_dirty_cash = data.dirtyCash()
			local cw_clean_cash = data.duffelTotal() - cw_dirty_cash
			local cw_safe_cash = data.cashValue()
			local dirty_cash_text = string.formatmoney(cw_dirty_cash)
			local clean_cash_text = string.formatmoney(cw_clean_cash)
			local cw_cash_text = _F("%s %s | %s %s",
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
			YRV3.m_cwash_cash_sum = YRV3.m_cwash_cash_sum + cw_clean_cash + cw_safe_cash
		end

		local heat = data.getSpecialVal()
		local heatcol = math.max(0, heat / 100)
		local clearButtonLabel = _T("GENERIC_CLEAR")
		local clearButtonWidth, _ = ImGui.CalcTextSize(clearButtonLabel)
		local style = ImGui.GetStyle()
		ImGui.BulletText(_T("YRV3_CWASH_HEAT"))
		ImGui.SameLine()
		ImGui.SetCursorPosX(region_width - clearButtonWidth - 240 - (style.ItemSpacing.x * 2))
		ImGui.BeginDisabled(heat == 0)
		if (GUI:Button(_T("GENERIC_CLEAR"))) then
			data.setSpecialVal()
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
		Toast:ShowMessage("YRV3", _F(_T("GENERIC_URL_COPY_SUCCESS"), url), true, 6)
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

	for name, data in pairs(YRV3.t_ShittyMissions) do
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

			Toast:ShowSuccess("Samurai's Scripts", _F(_T("YRV3_SELL_MISSIONS_NOTIF"), name:lower()))
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
	ImGui.BeginDisabled(YRV3.m_has_triggered_autosell)
	GVars.features.yrv3.autosell, _ = GUI:Checkbox(_T("YRV3_AUTO_SELL"), GVars.features.yrv3.autosell)
	ImGui.EndDisabled()
	GUI:Tooltip(_T("YRV3_AUTOSELL_TT"))

	if (script.is_active("fm_content_smuggler_sell")) then
		GUI:Text(_T("YRV3_HANGAR_LAND_ERR"), Color("red"))
	else
		ImGui.BeginDisabled(GVars.features.yrv3.autosell or YRV3.m_has_triggered_autosell or
			not YRV3.m_sell_script_running)
		if (GUI:Button(_T("YRV3_AUTO_SELL_MANUAL"))) then
			YRV3.m_has_triggered_autosell = true
			YRV3:FinishSale()
			ThreadManager:Run(function()
				repeat
					yield()
				until not YRV3.m_sell_script_running
				YRV3.m_has_triggered_autosell = false
			end)
		end
		ImGui.EndDisabled()
	end

	ImGui.Text(_F(_T("YRV3_AUTOSELL_CURRENT"), YRV3.m_sell_script_disp_name))

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
	[tabNames[1]] = drawCEOwarehouses,
	[tabNames[2]] = drawHangar,
	[tabNames[3]] = drawBunker,
	[tabNames[4]] = drawAcidLab,
	[tabNames[5]] = drawBikerBusiness,
	[tabNames[6]] = drawBusinessSafes,
	[tabNames[7]] = drawMoneyFronts,
	[tabNames[8]] = drawMisc,
	[tabNames[9]] = drawSettings,
}

local function YRV3UI()
	if (yrv3_state.disabled) then
		ImGui.Text(yrv3_state.reason)
		return
	end

	if (not YRV3:CanAccess()) then
		ImGui.Text(_T("GENERIC_OFFLINE_OR_OUTDATED"))
		return
	end

	if ImGui.BeginChild("##yrv3_header", 0, 100, true, ImGuiWindowFlags.AlwaysUseWindowPadding) then
		local title = _T("YRV3_MCT_TITLE")
		local textWidth = ImGui.CalcTextSize(title) + ImGui.GetStyle().FramePadding.x + 10
		local regionWidth = ImGui.GetWindowWidth()
		ImGui.SetCursorPosX((regionWidth - textWidth) / 2)

		if (GUI:Button(title)) then
			if (YRV3.m_sell_script_running) then
				Toast:ShowMessage("YRV3", _T("YRV3_MCT_UNAVAIL"))
			else
				YRV3:MCT()
				GUI:Close()
			end
		end

		ImGui.Spacing()
		ImGui.SetWindowFontScale(0.9)
		local tooltip = _T("YRV3_INCOME_APPROX_ALL_TT")
		ImGui.BulletText(_T("YRV3_INCOME_APPROX_ALL"))
		GUI:Tooltip(tooltip)
		ImGui.SameLine()
		GUI:Text(string.formatmoney(CalcTotalBusinessIncome()), Color("#85BB65"))
		GUI:Tooltip(tooltip)
		ImGui.SetWindowFontScale(1)
		ImGui.EndChild()
	end

	ImGui.Spacing()
	ImGui.SetNextWindowBgAlpha(0)
	if ImGui.BeginChild("##yrv3_wrapped_tb", 0, 40, false, ImGuiWindowFlags.NoScrollbar) then
		ImGui.BeginTabBar("##yrv3_tb")
		for i = 1, #tabNames do
			local name = tabNames[i]
			if (ImGui.BeginTabItem(name)) then
				selectedTabName = name
				ImGui.EndTabItem()
			end
		end
		ImGui.EndChild()
	end
	ImGui.EndTabBar()

	ImGui.SetCursorPosY(ImGui.GetCursorPosY() - ImGui.GetStyle().ItemSpacing.y - 10)
	ImGui.SetNextWindowBgAlpha(0.75)
	if (ImGui.BeginChild("##yrv3_main", 0, GVars.ui.window_size.y - GUI:GetMaxTopBarHeight() - 100, false, ImGuiWindowFlags.AlwaysUseWindowPadding)) then
		for name, callback in pairs(tabCallbacks) do
			if (name == selectedTabName and type(callback) == "function") then
				callback()
			end
		end
		ImGui.EndChild()
	end
end

GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, "YRV3", YRV3UI)
