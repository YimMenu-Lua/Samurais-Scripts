local SGSL = require("includes.services.SGSL")

---@class WarehouseStruct
---@field wasChecked boolean
---@field isOwned boolean
---@field autoFill boolean
---@field name? string
---@field max? integer
---@field size? integer
---@field pos? vec3
---@field totalSupplies? integer
---@field totalValue? integer

---@class BikerBusinessStruct
---@field wasChecked boolean
---@field isOwned boolean
---@field unit_max? integer
---@field name? string
---@field value_tunable? string
---@field totalSupplies? integer
---@field totalStock? integer
---@field totalValue? integer
---@field blip? integer

---@class BusinessSafeStruct
---@field isOwned fun(): bool
---@field cashValue fun(): integer
---@field max_cash integer
---@field blip integer
---@field getSpecialVal? fun(): integer
---@field setSpecialVal? fun()

---@class MoneyFrontsStruct : BusinessSafeStruct
---@field cashValue? fun(): integer
---@field duffelTotal? fun(): integer
---@field dirtyCash? fun(): integer
---@field blip? integer
---@field max_cash? integer
---@field max_heat integer
---@field gvar_key_1 string
---@field gvar_key_2 string
---@field cb1_clicked boolean
---@field cb2_clicked boolean
---@field on_cb1_click fun(this: YRV3, newVal: boolean)
---@field on_cb2_click fun(this: YRV3, newVal: boolean)
---@field coords vec3

---@type array<WarehouseStruct>
local Wh_Default = {
	[1] = {
		wasChecked = false,
		isOwned = false,
		autoFill = false
	},
	[2] = {
		wasChecked = false,
		isOwned = false,
		autoFill = false
	},
	[3] = {
		wasChecked = false,
		isOwned = false,
		autoFill = false
	},
	[4] = {
		wasChecked = false,
		isOwned = false,
		autoFill = false
	},
	[5] = {
		wasChecked = false,
		isOwned = false,
		autoFill = false
	},
}

---@type array<BikerBusinessStruct>
local BB_Default = {
	[1] = {
		wasChecked = false,
		isOwned = false,
	},
	[2] = {
		wasChecked = false,
		isOwned = false,
	},
	[3] = {
		wasChecked = false,
		isOwned = false,
	},
	[4] = {
		wasChecked = false,
		isOwned = false,
	},
	[5] = {
		wasChecked = false,
		isOwned = false,
	},
}

---@type dict<BusinessSafeStruct>
local BS_Default = {
	["Nightclub"] = {
		isOwned = function()
			return stats.get_int("MPX_NIGHTCLUB_OWNED") ~= 0
		end,
		cashValue = function()
			return stats.get_int("MPX_CLUB_SAFE_CASH_VALUE")
		end,
		max_cash = 25e4,
		blip = 614,
		getSpecialVal = function()
			return stats.get_int("MPX_CLUB_POPULARITY")
		end,
		setSpecialVal = function()
			if stats.get_int("MPX_CLUB_POPULARITY") >= 1e3 then
				return
			end
			stats.set_int("MPX_CLUB_POPULARITY", 1e3)
		end
	},
	["Arcade"] = {
		isOwned = function()
			return stats.get_int("MPX_ARCADE_OWNED") ~= 0
		end,
		cashValue = function()
			return stats.get_int("MPX_ARCADE_SAFE_CASH_VALUE")
		end,
		max_cash = 1e5,
		blip = 740,
	},
	["Agency"] = {
		isOwned = function()
			return stats.get_int("MPX_FIXER_HQ_OWNED") ~= 0
		end,
		cashValue = function()
			return stats.get_int("MPX_FIXER_SAFE_CASH_VALUE")
		end,
		max_cash = 25e4,
		blip = 826,
	},
	["MC Clubhouse"] = {
		isOwned = function()
			return stats.get_int("MPX_PROP_CLUBHOUSE") ~= 0
		end,
		cashValue = function()
			return stats.get_int("MPX_BIKER_BAR_RESUPPLY_CASH")
		end,
		max_cash = 1e5,
		blip = 492,
	},
	["Bail Office"] = {
		isOwned = function()
			return stats.get_int("MPX_BAIL_OFFICE_OWNED") ~= 0
		end,
		cashValue = function()
			return stats.get_int("MPX_BAIL_SAFE_CASH_VALUE")
		end,
		max_cash = 1e5,
		blip = 893,
	},
	["Salvage Yard"] = {
		isOwned = function()
			return stats.get_int("MPX_SALVAGE_YARD_OWNED") ~= 0
		end,
		cashValue = function()
			return stats.get_int("MPX_SALVAGE_SAFE_CASH_VALUE")
		end,
		max_cash = 25e4,
		blip = 867,
	},
	["Garment Factory"] = {
		isOwned = function()
			return stats.get_int("MPX_HACKER_DEN_OWNED") ~= 0
		end,
		cashValue = function()
			return stats.get_int("MPX_HDEN24_SAFE_CASH_VALUE")
		end,
		max_cash = 1e5,
		blip = 900,
	},
}

---@type dict<MoneyFrontsStruct>
local MF_Default = {
	["YRV3_CWASH_LABEL"] = {
		isOwned = function()
			return stats.get_int("MPX_SB_CAR_WASH_OWNED") ~= 0
		end,
		cashValue = function()
			return stats.get_int("MPX_CWASH_SAFE_CASH_VALUE")
		end,
		duffelTotal = function()
			return stats.get_int("MPX_CAR_WASH_DUFFEL_VALUE")
		end,
		dirtyCash = function()
			local posix = stats.get_int("MPX_CAR_WASH_DUFFEL_POSIX")
			local pending_cash = stats.get_int("MPX_CAR_WASH_DUFFEL_PENDING") -- why is this always 35k even after it gets cleaned?
			return Time.epoch() < posix and pending_cash or 0
		end,
		getSpecialVal = function()
			return stats.get_packed_stat_int(24924)
		end,
		setSpecialVal = function()
			if (stats.get_packed_stat_int(24924) == 0) then
				return
			end

			stats.set_packed_stat_int(24924, 0)
		end,
		max_cash = 1e5,
		max_heat = 100,
		blip = 931,
		gvar_key_1 = "features.yrv3.cwash_legal_work_cd",
		gvar_key_2 = "features.yrv3.cwash_illegal_work_cd",
		cb1_clicked = false,
		cb2_clicked = false,
		on_cb1_click = function(yrv3, newVal)
			table.set_nested_key(GVars, "features.yrv3.cwash_legal_work_cd", newVal)
			yrv3:SetCooldownStateDirty("cwash_legal_work_cd", true)
		end,
		on_cb2_click = function(yrv3, newVal)
			table.set_nested_key(GVars, "features.yrv3.cwash_illegal_work_cd", newVal)
			yrv3:SetCooldownStateDirty("cwash_illegal_work_cd", true)
		end,
		coords = vec3:new(25.645266, -1412.290649, 29.362230)
	},
	["YRV3_WEED_SHOP_LABEL"] = {
		isOwned = function()
			return stats.get_int("MPX_SB_WEED_SHOP_OWNED") ~= 0
		end,
		getSpecialVal = function()
			return stats.get_packed_stat_int(24925)
		end,
		setSpecialVal = function()
			if (stats.get_packed_stat_int(24925) == 0) then
				return
			end

			stats.set_packed_stat_int(24925, 0)
		end,
		max_heat = 100,
		gvar_key_1 = "features.yrv3.weedshop_legal_work_cd",
		gvar_key_2 = "features.yrv3.weedshop_illegal_work_cd",
		cb1_clicked = false,
		cb2_clicked = false,
		---@param yrv3 YRV3
		on_cb1_click = function(yrv3, newVal)
			table.set_nested_key(GVars, "features.yrv3.weedshop_legal_work_cd", newVal)
			yrv3:SetCooldownStateDirty("weedshop_legal_work_cd", true)
		end,
		on_cb2_click = function(yrv3, newVal)
			table.set_nested_key(GVars, "features.yrv3.weedshop_illegal_work_cd", newVal)
			yrv3:SetCooldownStateDirty("weedshop_illegal_work_cd", true)
		end,
		coords = vec3:new(-1162.051147, -1564.757202, 4.410227)
	},
	["YRV3_HELITOURS_LABEL"] = {
		isOwned = function()
			return stats.get_int("MPX_SB_HELI_TOURS_OWNED") ~= 0
		end,
		getSpecialVal = function()
			return stats.get_packed_stat_int(24926)
		end,
		setSpecialVal = function()
			if (stats.get_packed_stat_int(24926) == 0) then
				return
			end

			stats.set_packed_stat_int(24926, 0)
		end,
		max_heat = 100,
		gvar_key_1 = "features.yrv3.helitours_legal_work_cd",
		gvar_key_2 = "features.yrv3.helitours_illegal_work_cd",
		cb1_clicked = false,
		cb2_clicked = false,
		---@param yrv3 YRV3
		on_cb1_click = function(yrv3, newVal)
			table.set_nested_key(GVars, "features.yrv3.helitours_legal_work_cd", newVal)
			yrv3:SetCooldownStateDirty("helitours_legal_work_cd", true)
		end,
		on_cb2_click = function(yrv3, newVal)
			table.set_nested_key(GVars, "features.yrv3.helitours_illegal_work_cd", newVal)
			yrv3:SetCooldownStateDirty("helitours_illegal_work_cd", true)
		end,
		coords = vec3:new(-753.524841, -1511.244751, 5.015130)
	},
}

---@class StructScriptDisplayNames
local StructScriptDisplayNames <const> = {
	["fm_content_smuggler_sell"] = "Hangar (Land. Not supported.)",
	["gb_smuggler"]              = "Hangar (Air)",
	["gb_contraband_sell"]       = "CEO",
	["gb_gunrunning"]            = "Bunker",
	["gb_biker_contraband_sell"] = "Biker Business",
	["fm_content_acid_lab_sell"] = "Acid Lab",
}

local eShouldTerminateScripts <const> = {
	"appArcadeBusinessHub",
	"appsmuggler",
	"appbikerbusiness",
	"appbunkerbusiness",
	"appbusinesshub"
}

---@class YRV3
---@field m_total_sum number
---@field m_ceo_value_sum number
---@field m_biker_value_sum number
---@field m_safe_cash_sum number
---@field m_cwash_cash_sum number
---@field m_bhub_script_handle number
---@field m_warehouse_data array<WarehouseStruct>
---@field m_biker_data array<BikerBusinessStruct>
---@field m_safe_cash_data dict<BusinessSafeStruct>
---@field m_money_fronts_data dict<MoneyFrontsStruct>
---@field m_hangar_loop boolean
---@field m_has_triggered_autosell boolean
---@field m_sell_script_running boolean
---@field m_sell_script_name string?
---@field m_sell_script_disp_name string
---@field m_display_names StructScriptDisplayNames
---@field private m_last_as_check_time number
---@field private m_cooldown_state_dirty boolean
---@field protected m_thread Thread?
local YRV3 = {}
YRV3.__index = YRV3

---@return YRV3
function YRV3:init()
	local instance = setmetatable({
		m_total_sum = 0,
		m_ceo_value_sum = 0,
		m_biker_value_sum = 0,
		m_safe_cash_sum = 0,
		m_cwash_cash_sum = 0,
		m_bhub_script_handle = 0,
		m_last_as_check_time = 0,
		m_hangar_loop = false,
		m_has_triggered_autosell = false,
		m_sell_script_running = false,
		m_sell_script_name = nil,
		m_sell_script_disp_name = "None",
		m_warehouse_data = Wh_Default,
		m_biker_data = BB_Default,
		m_safe_cash_data = BS_Default,
		m_money_fronts_data = MF_Default,
		m_display_names = StructScriptDisplayNames,
		m_cooldown_state_dirty = true,
	}, self)

	self.m_thread = ThreadManager:RegisterLooped("SS_YRV3", function()
		instance:Main()
	end)

	Backend:RegisterEventCallback(Enums.eBackendEvent.RELOAD_UNLOAD, function()
		instance:Reset()
	end)

	Backend:RegisterEventCallback(Enums.eBackendEvent.SESSION_SWITCH, function()
		instance:Reset()
	end)

	return instance
end

function YRV3:CanAccess()
	return (Backend:GetAPIVersion() == Enums.eAPIVersion.V1)
		and Backend:IsUpToDate()
		and Game.IsOnline()
		and not script.is_active("maintransition")
		and not NETWORK.NETWORK_IS_ACTIVITY_SESSION()
end

---@param where integer|vec3
---@param keepVehicle? boolean
function YRV3:Teleport(where, keepVehicle)
	if not Self:IsOutside() then
		Notifier:ShowError("YRV3", "Please go outdside first!")
		return
	end

	Self:Teleport(where, keepVehicle)
end

---@param stat string
---@param slot integer
---@return boolean
function YRV3:DoesPlayerOwnPropertySlot(stat, slot)
	return stats.get_int(_F("%s%d", stat, slot)) ~= 0
end

---@return boolean
function YRV3:DoesPlayerOwnAnyWarehouse()
	for i = 0, 4 do
		if (self:DoesPlayerOwnPropertySlot("MPX_PROP_WHOUSE_SLOT", i)) then
			return true
		end
	end

	return false
end

---@return boolean
function YRV3:DoesPlayerOwnAnyBikerBusiness()
	for i = 0, 4 do
		if (self:DoesPlayerOwnPropertySlot("MPX_PROP_FAC_SLOT", i)) then
			return true
		end
	end

	return false
end

---@param index integer
function YRV3:PopulateBikerBusinessSlot(index)
	script.run_in_fiber(function()
		if (self.m_biker_data[index].wasChecked) then
			return
		end

		for _, v in ipairs(self.t_BikerBusinessIDs) do
			local propertyIndex = stats.get_int(_F("MPX_FACTORYSLOT%d", index - 1))

			if table.find(v.possible_ids, propertyIndex) then
				self.m_biker_data[index] = {
					wasChecked = true,
					isOwned = true,
					name = v.name,
					id = v.id,
					unit_max = v.unit_max,
					value_tunable = v.val_tunable,
					blip = v.blip,
				}
			end
		end
	end)
end

function YRV3:PopulateCEOwarehouseSlot(index)
	if self.m_warehouse_data[index].wasChecked then
		return
	end

	script.run_in_fiber(function()
		local property_index = (stats.get_int(_F("MPX_PROP_WHOUSE_SLOT%d", index - 1)))
		local warehouseName = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(_F("MP_WHOUSE_%d", property_index - 1))

		if self.t_CEOwarehouses[property_index] then
			self.m_warehouse_data[index] = {
				wasChecked = true,
				isOwned = true,
				autoFill = false,
				name = warehouseName,
				size = self.t_CEOwarehouses[property_index].size,
				max = self.t_CEOwarehouses[property_index].max,
				pos = self.t_CEOwarehouses[property_index].coords,
			}
		end
	end)
end

---@param crates number
function YRV3:GetCEOCratesValue(crates)
	if (not crates or crates <= 0) then
		return 0
	end

	if (crates == 1) then
		return tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD1") -- EXEC_CONTRABAND_SALE_VALUE_THRESHOLD1
	end

	if (crates == 2) then
		return tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD2") * 2 -- +1
	end

	if (crates == 3) then
		return tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD3") * 3 -- +1
	end

	if (crates == 4 or crates == 5) then
		return tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD4") * crates -- +1
	end

	if (crates >= 6 and crates <= 9) then
		return (tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD4") + math.floor((crates - 4) / 2)) * crates -- +0
	end

	if (crates >= 10 and crates <= 110) then
		return (tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD7") + math.floor((crates - 10) / 5)) * crates -- +3
	end

	if (crates == 111) then
		return tunables.get_int("EXEC_CONTRABAND_SALE_VALUE_THRESHOLD21") * 111 -- + 14
	end

	return 0
end

function YRV3:FinishCEOCargoSourceMission()
	if script.is_active("gb_contraband_buy") then
		script.execute_as_script("gb_contraband_buy", function()
			if (not NETWORK.NETWORK_IS_HOST_OF_THIS_SCRIPT()) then
				Notifier:ShowError("YRV3", "You are not host of this script.")
				return
			end

			local buyLocal = SGSL:Get(SGSL.data.gb_contraband_buy_local_1):AsLocal()
			buyLocal:At(5):WriteInt(1) -- 1.71 b3568.0 -- case -1: return "INVALID - UNSET";
			buyLocal:At(191):WriteInt(6) -- 1.71 b3568.0 -- Local_623.f_191 = iParam0;
			buyLocal:At(192):WriteInt(4) -- 1.71 b3568.0 -- Local_623.f_192 = iParam0;
		end)
	elseif script.is_active("fm_content_cargo") then
		script.execute_as_script("fm_content_cargo", function()
			if not NETWORK.NETWORK_IS_HOST_OF_THIS_SCRIPT() then
				Notifier:ShowError("YRV3", "You are not host of this script.")
				return
			end

			local fmccLocal2       = SGSL:Get(SGSL.data.gb_contraband_buy_local_2):AsLocal():At(1):At(0) -- GENERIC_BITSET_I_WON -- 1.71 b3568.0: var uLocal_5973 = 4;
			local gbcb_obj         = SGSL:Get(SGSL.data.gb_contraband_buy_local_3)
			local fmccLocal3       = gbcb_obj:AsLocal()
			local fmccLocal3Offset = gbcb_obj:GetOffset(1)
			local bs               = fmccLocal2:ReadInt()

			if (not Bit.is_set(bs, 11)) then
				bs = Bit.set(bs, 11)
				fmccLocal2:WriteInt(bs)
			end

			fmccLocal3:At(fmccLocal3Offset):WriteInt(3) -- EndReason
		end)
	end
end

function YRV3:WarehouseAutofill()
	if (not self:CanAccess()) then
		return
	end

	for i, v in ipairs(self.m_warehouse_data) do
		if (not v.autoFill) then
			goto continue
		end

		if (not v.wasChecked or not v.name or not v.max) then
			self:PopulateCEOwarehouseSlot(i)
			sleep(500)
		end

		if (stats.get_int(_F("MPX_CONTOTALFORWHOUSE%d", i - 1))) == v.max then
			GUI:PlaySound(GUI.Sounds.Error)
			Notifier:ShowWarning("YRV3", _F("Warehouse N°%d is already full! Option has been disabled.", i))
			v.autoFill = false
			goto continue
		end

		ThreadManager:Run(function()
			while ((stats.get_int(_F("MPX_CONTOTALFORWHOUSE%d", i - 1))) < v.max) do
				if (not v.autoFill) then
					break
				end

				stats.set_bool_masked("MPX_FIXERPSTAT_BOOL1", true, i + 11)
				sleep(GVars.features.yrv3.autofill_delay or 100)
			end

			v.autoFill = false
		end)

		::continue::
	end

	sleep(1000)
end

function YRV3:HangarAutofill()
	if (not self:CanAccess()) then
		return
	end

	if (not self.m_hangar_loop) then
		return
	end

	if (stats.get_int("MPX_HANGAR_OWNED") == 0) then
		Notifier:ShowWarning(
			"YRV3",
			"You don't seem to own a hangar. Option has been disabled.",
			false,
			3
		)

		self.m_hangar_loop = false
		return
	end

	if stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL") == 50 then
		Notifier:ShowWarning("YRV3", "Your Hangar is already full! Option has been disabled.")
		self.m_hangar_loop = false
		return
	end

	ThreadManager:Run(function()
		while stats.get_int("MPX_HANGAR_CONTRABAND_TOTAL") < 50 do
			if (not self.m_hangar_loop) then
				break
			end

			stats.set_bool_masked("MPX_DLC22022PSTAT_BOOL3", true, 9)
			sleep(GVars.features.yrv3.autofill_delay or 100)
		end

		self.m_hangar_loop = false
	end)
end

function YRV3:FinishSaleOnCommand()
	if (not self:CanAccess()) then
		return
	end

	if (GVars.features.yrv3.autosell) then
		Notifier:ShowWarning(
			"YRV3",
			"You aleady have 'Auto-Sell' enabled. No need to manually trigger it.",
			false,
			1.5
		)
		return
	end

	if (not self.m_sell_script_running) then
		Notifier:ShowWarning(
			"YRV3",
			"No supported sale script is currently running.",
			false,
			1.5
		)
		return
	end

	self:FinishSale()
end

---@param index number
function YRV3:WarehouseAutofillOnCommand(index)
	if (not self:CanAccess()) then
		return
	end

	script.run_in_fiber(function(s)
		if (not self.m_warehouse_data[index].wasChecked) then
			self:PopulateCEOwarehouseSlot(index)
			s:sleep(250)
		end

		if (not self.m_warehouse_data[index].isOwned) then
			Notifier:ShowError(
				"YRV3",
				_F("No warehouse found in slot %d!", index),
				false
			)
			return
		end

		self.m_warehouse_data[index].autoFill = not self.m_warehouse_data[index].autoFill
		Notifier:ShowMessage(
			"YRV3",
			_F("CEO Warehouse %d auto-fill %s.",
				index,
				self.m_warehouse_data[index].autoFill
				and "Enabled"
				or "Disabled"
			),
			false,
			2
		)
	end)
end

function YRV3:FillAll()
	if (not self:CanAccess()) then
		return
	end

	ThreadManager:Run(function()
		if (stats.get_int("MPX_HANGAR_OWNED") ~= 0 and not self.m_hangar_loop) then
			self.m_hangar_loop = true
			sleep(math.random(100, 300))
		end

		for i, v in ipairs(self.m_warehouse_data) do
			if (not v.wasChecked or not v.max) then
				self:PopulateCEOwarehouseSlot(i)
				sleep(100)
			end
		end

		for _, v in ipairs(self.m_warehouse_data) do
			if (v.isOwned) then
				v.autoFill = true
			end
		end

		local FMG = SGSL:Get(SGSL.data.freemode_business_global):AsGlobal()
		if (stats.get_int("MPX_PROP_FAC_SLOT5") ~= 0 and stats.get_int("MPX_MATTOTALFORFACTORY5") < 100) then
			FMG:At(5):At(1):WriteInt(1)
			sleep(math.random(100, 300))
		end

		if (stats.get_int("MPX_XM22_LAB_OWNED") ~= 0 and stats.get_int("MPX_MATTOTALFORFACTORY6") < 100) then
			FMG:At(6):At(1):WriteInt(1)
			sleep(math.random(100, 300))
		end

		for i, v in ipairs(self.m_biker_data) do
			if (not v.wasChecked or not v.unit_max) then
				self:PopulateBikerBusinessSlot(i)
				sleep(100)
			end
		end

		for i, v in ipairs(self.m_biker_data) do
			local slot = i - 1
			local supplies = stats.get_int(_F("MPX_MATTOTALFORFACTORY%d", slot))
			if (v.isOwned and v.unit_max and supplies < 100) then
				FMG:At(slot):At(1):WriteInt(1)
				sleep(math.random(200, 666))
			end
		end
	end)
end

function YRV3:FinishSale()
	local sn = self.m_sell_script_name
	if (not sn or not self.t_SellScripts[sn]) then
		return
	end

	self.m_has_triggered_autosell = true
	script.execute_as_script(sn, function()
		if not self.t_SellScripts[sn].b then -- gb_*
			for _, data in pairs(self.t_SellScripts[sn]) do
				locals.set_int(sn, data.l + data.o, data.v)
			end
		else -- fm_content_*
			if not (NETWORK.NETWORK_GET_HOST_OF_THIS_SCRIPT() == Self:GetPlayerID()) then
				Notifier:ShowWarning(
					"YRV3",
					"Unable to finish sale mission. You are not host of this script."
				)
				return
			end

			local val = locals.get_int(sn, self.t_SellScripts[sn].b + 1 + 0)
			if not Bit.is_set(val, 11) then
				val = Bit.set(val, 11)
				locals.set_int(sn, self.t_SellScripts[sn].b + 1 + 0, val)
			end

			locals.set_int(sn, self.t_SellScripts[sn].l + self.t_SellScripts[sn].o, 3) -- 3=End reason.
		end
	end)
end

function YRV3:GetRunningSellScriptDisplayName()
	if (not self.m_sell_script_running or not self.m_sell_script_name) then
		return "None"
	end

	return self.m_display_names[self.m_sell_script_name] or "None"
end

---@param key string
---@param state boolean
function YRV3:SetCooldownStateDirty(key, state)
	local data = self.t_CooldownData[key]
	if (not data) then
		return
	end

	data.dirty = state
end

---@param state boolean
function YRV3:SetAllCooldownStatesDirty(state)
	self.m_cooldown_state_dirty = state
end

function YRV3:CheckAllCooldowns()
	if (not self.m_cooldown_state_dirty) then
		return
	end

	for _, data in pairs(self.t_CooldownData) do
		local gvar = data.gstate()
		if (gvar and data.onEnable) then
			data.onEnable()
		elseif (not gvar and type(data.onDisable) == "function") then
			data.onDisable()
		end
		data.dirty = false
	end

	self.m_cooldown_state_dirty = false
end

function YRV3:CooldownHandler()
	if (self.m_cooldown_state_dirty) then
		self:CheckAllCooldowns()
		return
	end

	for _, data in pairs(self.t_CooldownData) do
		if (not data.dirty) then
			goto continue
		end

		local gvar = data.gstate()
		if (gvar and data.onEnable) then
			data.onEnable()
		elseif (not gvar and type(data.onDisable) == "function") then
			data.onDisable()
		end
		data.dirty = false

		::continue::
	end
end

local fadedOutTimer = Timer.new(1e4)
function YRV3:SetupAutosell()
	if (Time.now() < self.m_last_as_check_time) then
		return
	end

	for sn in pairs(self.t_SellScripts) do
		if script.is_active(sn) then
			self.m_sell_script_name = sn
			self.m_sell_script_running = true
			self.m_sell_script_disp_name = self:GetRunningSellScriptDisplayName()
			break
		else
			self.m_sell_script_name = "None"
			self.m_sell_script_disp_name = "None"
			self.m_sell_script_running = false
		end
	end

	if (self.m_sell_script_running and self.m_bhub_script_handle ~= 0) then -- was triggered from the mct
		for _, scr in pairs(eShouldTerminateScripts) do
			if (script.is_active(scr)) then
				PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 202, 1.0)
				sleep(200)
				PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 202, 1.0)
				break
			end
		end

		sleep(1000)

		if (CAM.IS_SCREEN_FADING_OUT() or CAM.IS_SCREEN_FADED_OUT()) then
			while (not fadedOutTimer:is_done()) do
				if (not CAM.IS_SCREEN_FADED_OUT() or CAM.IS_SCREEN_FADING_IN()) then
					break
				end

				yield()
			end

			-- recheck
			if (CAM.IS_SCREEN_FADED_OUT() and not CAM.IS_SCREEN_FADING_IN()) then -- Step bro, I'm stuck!
				CAM.DO_SCREEN_FADE_IN(100)
			end
		end

		fadedOutTimer:reset()
	end

	self.m_last_as_check_time = Time.now() + 1
end

function YRV3:AutoSellHandler()
	self:SetupAutosell()

	if (GVars.features.yrv3.autosell
			and self.m_sell_script_running
			and not self.m_has_triggered_autosell
			and not CAM.IS_SCREEN_FADED_OUT()
		) then
		self.m_has_triggered_autosell = true
		Notifier:ShowMessage("YRV3", "Auto-Sell will start in 20 seconds.")
		sleep(2e4)

		while (AUDIO.IS_MOBILE_PHONE_CALL_ONGOING()) do
			yield()
		end

		self:FinishSale()
	end

	while (self.m_has_triggered_autosell) do
		if (not script.is_active(self.m_sell_script_name)) then
			break
		end

		yield()
	end
	self.m_has_triggered_autosell = false
end

function YRV3:Main()
	if (not Backend:IsUpToDate() and self.m_thread and self.m_thread:IsRunning()) then
		self.m_thread:Stop()
	end

	if (not self:CanAccess()) then
		sleep(500)
		return
	end

	self:AutoSellHandler()
	self:CooldownHandler()
	self:HangarAutofill()
	self:WarehouseAutofill()
end

-- Master Control Terminal
function YRV3:MCT()
	if Self:IsBrowsingApps() then
		GUI:PlaySound(GUI.Sounds.Error)
		return
	end

	local BusinessHubGlobal1 = SGSL:Get(SGSL.data.business_hub_global_1):AsGlobal()
	local BusinessHubGlobal2 = SGSL:Get(SGSL.data.business_hub_global_2):AsGlobal()
	script.run_in_fiber(function()
		if (BusinessHubGlobal1:ReadInt() ~= 0) then
			BusinessHubGlobal1:WriteInt(0)
		end

		Await(Game.RequestScript, "appArcadeBusinessHub")
		GUI:PlaySound(GUI.Sounds.Button)
		self.m_bhub_script_handle = SYSTEM.START_NEW_SCRIPT("appArcadeBusinessHub", 1424) -- STACK_SIZE_DEFAULT
		SCRIPT.SET_SCRIPT_AS_NO_LONGER_NEEDED("appArcadeBusinessHub")
		sleep(100)
		gui.toggle(false)

		while (script.is_active("appArcadeBusinessHub")) do
			if (BusinessHubGlobal2:ReadInt() == -1) then
				BusinessHubGlobal2:WriteInt(0)
			end

			yield()
		end

		while (Self:IsBrowsingApps()) do
			yield()
		end

		BusinessHubGlobal1:WriteInt(0)
		self.m_bhub_script_handle = 0
	end)
end

function YRV3:Reset()
	self.m_ceo_value_sum        = 0
	self.m_biker_value_sum      = 0
	self.m_safe_cash_sum        = 0
	self.m_cwash_cash_sum       = 0
	self.m_warehouse_data       = Wh_Default
	self.m_biker_data           = BB_Default
	self.m_safe_cash_data       = BS_Default
	self.m_money_fronts_data    = MF_Default
	self.m_cooldown_state_dirty = true
end

------------------------------------------------------------------------
--- Data
------------------------------------------------------------------------

YRV3.t_CooldownData = {
	["mc_work_cd"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.mc_work_cd
		end,
		onEnable = function()
			if (tunables.get_int("BIKER_CLUB_WORK_COOLDOWN_GLOBAL") > 0) then
				tunables.set_int("BIKER_CLUB_WORK_COOLDOWN_GLOBAL", 0)
			end
		end
	},
	["hangar_cd"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.hangar_cd
		end,
		onEnable = function()
			local t = {
				"SMUG_STEAL_EASY_COOLDOWN_TIMER",
				"SMUG_STEAL_MED_COOLDOWN_TIMER",
				"SMUG_STEAL_HARD_COOLDOWN_TIMER",
			}
			for _, str in ipairs(t) do
				if (tunables.get_int(str) > 0) then
					tunables.set_int(str, 0)
				end
			end
		end
	},
	["nc_management_cd"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.nc_management_cd
		end,
		onEnable = function()
			if (tunables.get_int("BB_CLUB_MANAGEMENT_CLUB_MANAGEMENT_MISSION_COOLDOWN") > 0) then
				tunables.set_int("BB_CLUB_MANAGEMENT_CLUB_MANAGEMENT_MISSION_COOLDOWN", 0)
			end
		end
	},
	["nc_vip_mission_chance"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.nc_vip_mission_chance
		end,
		onEnable = function()
			if (tunables.get_int("NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT") > 0) then
				tunables.set_int("NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT", 0)
			end
		end,
		onDisable = function()
			if (tunables.get_int("NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT") == 0) then
				tunables.set_int("NC_TROUBLEMAKER_CHANCE_IS_VIP_EVENT", 50)
			end
		end
	},
	["security_missions_cd"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.security_missions_cd
		end,
		onEnable = function()
			if (tunables.get_int("FIXER_SECURITY_CONTRACT_COOLDOWN_TIME") > 0) then
				tunables.set_int("FIXER_SECURITY_CONTRACT_COOLDOWN_TIME", 0)
			end
		end
	},
	["ie_vehicle_steal_cd"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.ie_vehicle_steal_cd
		end,
		onEnable = function()
			if (tunables.get_int("IMPEXP_STEAL_COOLDOWN") > 0) then
				tunables.set_int("IMPEXP_STEAL_COOLDOWN", 0)
			end
		end
	},
	["ie_vehicle_sell_cd"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.ie_vehicle_sell_cd
		end,
		onEnable = function()
			if (tunables.get_int("IMPEXP_SELL_COOLDOWN") > 0) then
				tunables.set_int("IMPEXP_SELL_COOLDOWN", 0)
			end
			for i = 1, 4, 1 do
				local __t = _F("IMPEXP_SELL_%d_CAR_COOLDOWN", i)
				if (tunables.get_int(__t) > 0) then
					tunables.set_int(__t, 0)
				end
			end
		end
	},
	["ceo_crate_buy_cd"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.ceo_crate_buy_cd
		end,
		onEnable = function()
			if (tunables.get_int("EXEC_BUY_COOLDOWN") > 0) then
				tunables.set_int("EXEC_BUY_COOLDOWN", 0)
			end
			if (tunables.get_int("EXEC_BUY_FAIL_COOLDOWN") > 0) then
				tunables.set_int("EXEC_BUY_FAIL_COOLDOWN", 0)
			end
		end
	},
	["ceo_crate_sell_cd"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.ceo_crate_sell_cd
		end,
		onEnable = function()
			if (tunables.get_int("EXEC_SELL_COOLDOWN") > 0) then
				tunables.set_int("EXEC_SELL_COOLDOWN", 0)
			end
			if tunables.get_int("EXEC_SELL_FAIL_COOLDOWN") > 0 then
				tunables.set_int("EXEC_SELL_FAIL_COOLDOWN", 0)
			end
		end
	},
	["dax_work_cd"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.dax_work_cd
		end,
		onEnable = function()
			if (stats.get_int("MPX_XM22JUGGALOWORKCDTIMER") > 0) then
				stats.set_int("MPX_XM22JUGGALOWORKCDTIMER", 0)
			end
		end
	},
	["garment_rob_cd"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.garment_rob_cd
		end,
		onEnable = function()
			if (stats.get_int("MPX_HACKER24_ROBBERY_CD") > 0) then
				stats.set_int("MPX_HACKER24_ROBBERY_CD", 0)
			end
		end
	},
	["cfr_cd"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.cfr_cd
		end,
		onEnable = function()
			if (stats.get_int("SALV23_CFR_COOLDOWN") > 0) then
				stats.set_int("SALV23_CFR_COOLDOWN", 0)
			end
		end
	},
	["cwash_legal_work_cd"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.cwash_legal_work_cd
		end,
		onEnable = function()
			if (stats.get_int("T25_CW_LEG_CD") > 0) then
				stats.set_int("T25_CW_LEG_CD", 0)
			end
		end
	},
	["cwash_illegal_work_cd"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.cwash_illegal_work_cd
		end,
		onEnable = function()
			if (stats.get_int("T25_CW_ILEG_CD") > 0) then
				stats.set_int("T25_CW_ILEG_CD", 0)
			end
		end
	},
	["weedshop_legal_work_cd"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.weedshop_legal_work_cd
		end,
		onEnable = function()
			if (stats.get_int("T25_WS_LEG_CD") > 0) then
				stats.set_int("T25_WS_LEG_CD", 0)
			end
		end
	},
	["weedshop_illegal_work_cd"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.weedshop_illegal_work_cd
		end,
		onEnable = function()
			if (stats.get_int("T25_WS_ILEG_CD") > 0) then
				stats.set_int("T25_WS_ILEG_CD", 0)
			end
		end
	},
	["helitours_legal_work_cd"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.helitours_legal_work_cd
		end,
		onEnable = function()
			if (stats.get_int("T25_WS_LEG_CD") > 0) then
				stats.set_int("T25_WS_LEG_CD", 0)
			end
		end
	},
	["helitours_illegal_work_cd"] = {
		dirty = false,
		gstate = function()
			return GVars.features.yrv3.helitours_illegal_work_cd
		end,
		onEnable = function()
			if (stats.get_int("T25_HT_ILEG_CD") > 0) then
				stats.set_int("T25_HT_ILEG_CD", 0)
			end
		end
	},
}

YRV3.t_SellScripts = {
	["gb_smuggler"] = { -- air
		{
			l = (function() return SGSL:Get(SGSL.data.gb_smuggler_sell_air_local_1):GetValue() end)(),
			o = (function() return SGSL:Get(SGSL.data.gb_smuggler_sell_air_local_1):GetOffset(1) end)(),
			v = 0
		},
		{
			l = (function() return SGSL:Get(SGSL.data.gb_smuggler_sell_air_local_2):GetValue() end)(),
			o = (function() return SGSL:Get(SGSL.data.gb_smuggler_sell_air_local_2):GetOffset(1) end)(),
			v = 1
		},
	},
	["gb_gunrunning"] = {
		{
			l = (function() return SGSL:Get(SGSL.data.gb_gunrunning_sell_local_1):GetValue() end)(),
			o = (function() return SGSL:Get(SGSL.data.gb_gunrunning_sell_local_1):GetOffset(1) end)(),
			v = 0
		},
		{
			l = (function() return SGSL:Get(SGSL.data.gb_gunrunning_sell_local_1):GetValue() end)(),
			o = (function() return SGSL:Get(SGSL.data.gb_gunrunning_sell_local_2):GetOffset(1) end)(),
			v = 1
		},
	},
	["gb_contraband_sell"] = {
		{
			l = (function() return SGSL:Get(SGSL.data.gb_contraband_sell_local):GetValue() end)(),
			o = 1,
			v = 99999
		},
	},
	["gb_biker_contraband_sell"] = {
		{
			l = (function() return SGSL:Get(SGSL.data.gb_biker_contraband_sell_local):GetValue() end)(),
			o = (function() return SGSL:Get(SGSL.data.gb_biker_contraband_sell_local):GetOffset(1) end)(),
			v = 15
		},
	},
	["fm_content_acid_lab_sell"] = {
		b = (function() return SGSL:Get(SGSL.data.acid_lab_sell_bitset):GetValue() end)(),
		l = (function() return SGSL:Get(SGSL.data.acid_lab_sell_local):GetValue() end)(),
		o = (function() return SGSL:Get(SGSL.data.acid_lab_sell_local):GetOffset(1) end)(),
	},
}

YRV3.t_CEOwarehouses = {
	{ size = 0, max = 16,  coords = vec3:new(51.311188, -2568.470947, 6.004591) },
	{ size = 0, max = 16,  coords = vec3:new(-1081.083740, -1261.013184, 5.648909) },
	{ size = 0, max = 16,  coords = vec3:new(898.484314, -1031.882446, 34.966454) },
	{ size = 0, max = 16,  coords = vec3:new(249.246918, -1955.651978, 23.161957) },
	{ size = 0, max = 16,  coords = vec3:new(-424.773499, 184.146530, 80.752899) },
	{ size = 2, max = 111, coords = vec3:new(-1045.004395, -2023.150146, 13.161570) },
	{ size = 1, max = 42,  coords = vec3:new(-1269.286133, -813.215820, 17.107399) },
	{ size = 2, max = 111, coords = vec3:new(-876.108032, -2734.502930, 13.844264) },
	{ size = 0, max = 16,  coords = vec3:new(272.409424, -3015.267090, 5.707359) },
	{ size = 1, max = 42,  coords = vec3:new(1563.832031, -2135.110840, 77.616447) },
	{ size = 1, max = 42,  coords = vec3:new(-308.772247, -2698.393799, 6.000292) },
	{ size = 1, max = 42,  coords = vec3:new(503.738037, -653.082642, 24.751144) },
	{ size = 1, max = 42,  coords = vec3:new(-528.074585, -1782.701904, 21.483055) },
	{ size = 1, max = 42,  coords = vec3:new(-328.013458, -1354.755371, 31.296524) },
	{ size = 1, max = 42,  coords = vec3:new(349.901184, 327.976440, 104.303856) },
	{ size = 2, max = 111, coords = vec3:new(922.555481, -1560.048950, 30.756647) },
	{ size = 2, max = 111, coords = vec3:new(762.672363, -909.193054, 25.250854) },
	{ size = 2, max = 111, coords = vec3:new(1041.059814, -2172.653076, 31.488876) },
	{ size = 2, max = 111, coords = vec3:new(1015.361633, -2510.986572, 28.302608) },
	{ size = 2, max = 111, coords = vec3:new(-245.651718, 202.504669, 83.792648) },
	{ size = 1, max = 42,  coords = vec3:new(541.587646, -1944.362793, 24.985096) },
	{ size = 2, max = 111, coords = vec3:new(93.278641, -2216.144775, 6.033320) },
}

YRV3.t_BikerBusinessIDs = {
	{ name = "Fake Documents",  id = 0, unit_max = 60, val_tunable = "BIKER_FAKEIDS_PRODUCT_VALUE",     blip = 498, possible_ids = { 5, 10, 15, 20 } },
	{ name = "Weed",            id = 1, unit_max = 80, val_tunable = "BIKER_WEED_PRODUCT_VALUE",        blip = 496, possible_ids = { 2, 7, 12, 17 } },
	{ name = "Fake Cash",       id = 2, unit_max = 40, val_tunable = "BIKER_COUNTERCASH_PRODUCT_VALUE", blip = 500, possible_ids = { 4, 9, 14, 19 } },
	{ name = "Methamphetamine", id = 3, unit_max = 20, val_tunable = "BIKER_METH_PRODUCT_VALUE",        blip = 499, possible_ids = { 1, 6, 11, 16 } },
	{ name = "Cocaine",         id = 4, unit_max = 10, val_tunable = "BIKER_CRACK_PRODUCT_VALUE",       blip = 497, possible_ids = { 3, 8, 13, 18 } },
}

YRV3.t_Hangars = {
	{ name = "LSIA Hangar 1",            coords = vec3:new(-1148.908447, -3406.064697, 13.945053) },
	{ name = "LSIA Hangar A17",          coords = vec3:new(-1393.322021, -3262.968262, 13.944828) },
	{ name = "Fort Zancudo Hangar A2",   coords = vec3:new(-2022.336304, 3154.936768, 32.810272) },
	{ name = "Fort Zancudo Hangar 3497", coords = vec3:new(-1879.105957, 3106.792969, 32.810234) },
	{ name = "Fort Zancudo Hangar 3499", coords = vec3:new(-2470.278076, 3274.427734, 32.835461) },
}

YRV3.t_Bunkers = {
	[21] = { name = "Grand Senora Oilfields Bunker", coords = vec3:new(494.680878, 3015.895996, 41.041725) },
	[22] = { name = "Grand Senora Desert Bunker", coords = vec3:new(849.619812, 3024.425781, 41.266800) },
	[23] = { name = "Route 68 Bunker", coords = vec3:new(40.422565, 2929.004395, 55.746357) },
	[24] = { name = "Farmhouse Bunker", coords = vec3:new(1571.949341, 2224.597168, 78.350952) },
	[25] = { name = "Smoke Tree Road Bunker", coords = vec3:new(2107.135254, 3324.630615, 45.371754) },
	[26] = { name = "Thomson Scrapyard Bunker", coords = vec3:new(2488.706055, 3164.616699, 49.080124) },
	[27] = { name = "Grapeseed Bunker", coords = vec3:new(1798.502930, 4704.956543, 39.995476) },
	[28] = { name = "Paleto Forest Bunker", coords = vec3:new(-754.225769, 5944.171875, 19.836382) },
	[29] = { name = "Raton Canyon Bunker", coords = vec3:new(-388.333160, 4338.322754, 56.103130) },
	[30] = { name = "Lago Zancudo Bunker", coords = vec3:new(-3030.341797, 3334.570068, 10.105902) },
	[31] = { name = "Chumash Bunker", coords = vec3:new(-3156.140625, 1376.710693, 17.073570) },
}

YRV3.t_ShittyMissions = {
	["CEO"] = {
		type = "bool",
		tuneable = {
			"EXEC_DISABLE_SELL_AIRATTACKED",
			"EXEC_DISABLE_SELL_AIRDROP",
			"EXEC_DISABLE_SELL_AIRFLYLOW",
			"EXEC_DISABLE_SELL_AIRRESTRICTED",
			"EXEC_DISABLE_SELL_ATTACKED",
			"EXEC_DISABLE_SELL_DEFEND",
			"EXEC_DISABLE_SELL_NODAMAGE",
			"EXEC_DISABLE_SELL_SEAATTACKED",
			"EXEC_DISABLE_SELL_SEADEFEND",
			"EXEC_DISABLE_SELL_STING",
			"EXEC_DISABLE_SELL_STING_1",
			"EXEC_DISABLE_SELL_STING_2",
			"EXEC_DISABLE_SELL_STING_3",
			"EXEC_DISABLE_SELL_STING_4",
			"EXEC_DISABLE_SELL_STING_5",
			"EXEC_DISABLE_SELL_TRACKIFY"
		}
	},
	["Biker"] = {
		type = "bool",
		tuneable = {
			"BIKER_DISABLE_SELL_CONVOY",
			"BIKER_DISABLE_SELL_PROVEN",
			"BIKER_DISABLE_SELL_FRIENDS_IN_NEED",
			"BIKER_DISABLE_SELL_BORDER_PATROL",
			"BIKER_DISABLE_SELL_HELICOPTER_DROP",
			"BIKER_DISABLE_SELL_POSTMAN",
			"BIKER_DISABLE_SELL_AIR_DROP_AT_SEA",
			"BIKER_DISABLE_SELL_STING_OP",
		}
	},
	["Nightclub"] = {
		type = "float",
		tuneable = {
			"BB_SELL_MISSIONS_WEIGHTING_MULTI_DROP",
			"BB_SELL_MISSIONS_WEIGHTING_HACK_DROP",
			"BB_SELL_MISSIONS_WEIGHTING_ROADBLOCK",
			"BB_SELL_MISSIONS_WEIGHTING_PROTECT_BUYER",
			"BB_SELL_MISSIONS_WEIGHTING_UNDERCOVER_COPS",
			"BB_SELL_MISSIONS_WEIGHTING_OFFSHORE_TRANSFER",
			"BB_SELL_MISSIONS_WEIGHTING_NOT_A_SCRATCH",
			"BB_SELL_MISSIONS_WEIGHTING_FOLLOW_HELI",
			"BB_SELL_MISSIONS_WEIGHTING_FIND_BUYER"
		},
	},
	["Hangar"] = {
		type = "float",
		tuneable = {
			"SMUG_SELL_HEAVY_LIFTING_WEIGHTING",
			"SMUG_SELL_CONTESTED_WEIGHTING",
			"SMUG_SELL_AGILE_DELIVERY_WEIGHTING",
			"SMUG_SELL_FLYING_FORTRESS_WEIGHTING",
			"SMUG_SELL_AIR_DELIVERY_WEIGHTING",
			"SMUG_SELL_AIR_POLICE_WEIGHTING",
			"SMUG_SELL_UNDER_THE_RADAR_WEIGHTING"
		},
	},
}

return YRV3
