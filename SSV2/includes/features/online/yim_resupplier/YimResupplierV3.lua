-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local SGSL <const>                    = require("includes.services.SGSL")
local IManagedValueController <const> = require("includes.structs.IManagedValueController")
local RawData <const>                 = require("includes.data.yrv3_data")


---@enum eYRState
Enums.eYRState = {
	IDLE      = 0x0,
	OFFLINE   = 0x1,
	WAITING   = 0x2,
	LOADING   = 0x3,
	RUNNING   = 0x4,
	RELOADING = 0x5,
	ERROR     = 0x6,
}


---@class YRV3Businesses
---@field safes array<CashSafe>
---@field office? Office
---@field clubhouse? Clubhouse
---@field hangar? Warehouse
---@field bunker? Factory
---@field acid_lab? Factory
---@field nightclub? Nightclub
---@field car_wash? CarWash
---@field salvage_yard? SalvageYard


---@class YRV3
---@field private m_last_error string
---@field private m_total_sum number
---@field private m_total_sum_fmt string
---@field private m_bhub_script_handle number
---@field private m_has_triggered_autosell boolean
---@field private m_sell_script_running boolean
---@field private m_sell_script_name string?
---@field private m_sell_script_disp_name string
---@field private m_businesses YRV3Businesses
---@field private m_boss_types_avail array<{ name: string, id: integer }>
---@field private m_last_autosell_check_time milliseconds
---@field private m_last_income_check_time milliseconds
---@field private m_last_business_update_time milliseconds
---@field private m_last_cooldown_check_time milliseconds
---@field private m_cooldown_controller IManagedValueController
---@field private m_initial_data_done boolean
---@field private m_data_initialized boolean
---@field protected m_state eYRState
---@field protected m_thread Thread?
---@field protected m_initialized boolean
local YRV3   = {}
YRV3.__index = YRV3

---@return YRV3
function YRV3:init()
	if (self.m_initialized) then return self end

	self.m_total_sum                 = 0
	self.m_total_sum_fmt             = "$0"
	self.m_bhub_script_handle        = 0
	self.m_last_autosell_check_time  = 0
	self.m_last_income_check_time    = 0
	self.m_last_business_update_time = 0
	self.m_last_cooldown_check_time  = 0
	self.m_state                     = Enums.eYRState.IDLE
	self.m_has_triggered_autosell    = false
	self.m_sell_script_running       = false
	self.m_initial_data_done         = false
	self.m_data_initialized          = false
	self.m_sell_script_name          = nil
	self.m_sell_script_disp_name     = "None"
	self.m_last_error                = ""
	self.m_businesses                = { safes = {} }
	self.m_boss_types_avail          = {}
	self.m_cooldown_controller       = IManagedValueController.new(RawData.Cooldowns)


	self.m_thread = ThreadManager:RegisterLooped("SS_YRV3", function()
		self:OnTick()
	end, { exception_handler = self:Reset(true) })

	local function __reset__()
		if (self.m_data_initialized) then self:Reset() end
	end

	Backend:RegisterEventCallback(Enums.eBackendEvent.RELOAD_UNLOAD, __reset__)
	Backend:RegisterEventCallback(Enums.eBackendEvent.SESSION_SWITCH, __reset__)

	self.m_initialized = true
	return self
end

---@param disable? boolean
---@param reason? string
function YRV3:Reset(disable, reason)
	self.m_total_sum                 = 0
	self.m_total_sum_fmt             = "$0"
	self.m_last_autosell_check_time  = 0
	self.m_last_income_check_time    = 0
	self.m_last_business_update_time = 0
	self.m_businesses                = { safes = {} }
	self.m_boss_types_avail          = {}
	self.m_has_triggered_autosell    = false
	self.m_sell_script_running       = false
	self.m_initial_data_done         = false
	self.m_data_initialized          = false
	self.m_state                     = disable and Enums.eYRState.ERROR or Enums.eYRState.IDLE

	if (disable) then
		self:SetLastError(reason or "Unhandled Exception.")
	end
end

function YRV3:Reload()
	ThreadManager:Run(function()
		self.m_state         = Enums.eYRState.RELOADING
		self.m_total_sum     = 0
		self.m_total_sum_fmt = "$0"
		sleep(1500) -- dummy busy wait to give the UI time to refresh
		self:Reset()
	end)
end

---@return boolean
function YRV3:CanAccess()
	return Backend:IsUpToDate()
		and Game.IsOnline()
		and not Backend:IsMockEnv()
		and not NETWORK.NETWORK_IS_ACTIVITY_SESSION()
		and self.m_state ~= Enums.eYRState.ERROR
end

---@return boolean
function YRV3:IsDataInitialized()
	return self.m_data_initialized
end

---@return eYRState
function YRV3:GetState()
	return self.m_state
end

---@return string
function YRV3:GetLastError()
	if (not self.m_last_error:isempty() and self.m_last_error:gsub("_", ""):find("%l") == nil) then
		return _T(self.m_last_error)
	end

	return self.m_last_error
end

---@param msg string
function YRV3:SetLastError(msg)
	if (msg == self.m_last_error) then
		return
	end

	self.m_last_error = msg
end

---@alias YRV3BusinessEntry CashSafe[]|Office|Clubhouse|Warehouse|Factory|Nightclub|CarWash|SalvageYard

---@return fun(t: table<string, YRV3BusinessEntry>, string?): string, YRV3BusinessEntry
---@return table<string, YRV3BusinessEntry>
function YRV3:BusinessIter()
	return pairs(self.m_businesses)
end

function YRV3:GetAvailableBossTypes()
	return self.m_boss_types_avail
end

---@return Office?
function YRV3:GetOffice()
	return self.m_businesses.office
end

---@return Warehouse?
function YRV3:GetHangar()
	return self.m_businesses.hangar
end

---@return Clubhouse?
function YRV3:GetClubhouse()
	return self.m_businesses.clubhouse
end

---@return Nightclub?
function YRV3:GetNightclub()
	return self.m_businesses.nightclub
end

---@return array<CashSafe>
function YRV3:GetBusinessSafes()
	return self.m_businesses.safes
end

---@return CarWash?
function YRV3:GetCarWash()
	return self.m_businesses.car_wash
end

---@return Factory?
function YRV3:GetBunker()
	return self.m_businesses.bunker
end

---@return Factory?
function YRV3:GetAcidLab()
	return self.m_businesses.acid_lab
end

---@return SalvageYard
function YRV3:GetSalvageYard()
	return self.m_businesses.salvage_yard
end

---@return dict<{ type: "float"|"bool", tuneables: array<string> }>
function YRV3:GetSaleMissionTunables()
	return RawData.SellMissionTunables
end

---@return integer
function YRV3:GetEstimatedIncome()
	return self.m_total_sum
end

---@return string
function YRV3:GetEstimatedIncomeFmt()
	return self.m_total_sum_fmt
end

---@return boolean
function YRV3:IsAnySaleInProgress()
	return self.m_sell_script_running
end

---@return boolean
function YRV3:HasTriggeredAutoSell()
	return self.m_has_triggered_autosell
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

---@param idx integer
---@return boolean
function YRV3:IsPropertyIndexValid(idx)
	if (type(idx) ~= "number") then
		return false
	end

	return idx > 0 and idx < math.int32_max()
end

function YRV3:PopulateHangar()
	if (self.m_businesses.hangar) then
		return
	end

	local property_index = stats.get_int("MPX_HANGAR_OWNED")
	local ref            = RawData.Hangars[property_index]
	if (not ref) then
		return
	end

	self.m_businesses.hangar = require("Warehouse").new({
		id        = -1,
		name      = Game.GetGXTLabel(_F("MP_HANGAR_%d", property_index)),
		coords    = ref.coords,
		max_units = 50,
	}, Enums.eWarehouseType.HANGAR)
end

function YRV3:PopulateOffice()
	local office_prop = stats.get_int("MPX_PROP_OFFICE")
	if (not self:IsPropertyIndexValid(office_prop)) then
		return
	end

	local idx = office_prop - 86
	local ref = RawData.Offices[idx]
	if (not ref) then return end

	self.m_businesses.office = require("Office") {
		id     = idx,
		name   = Game.GetGXTLabel(ref.gxt),
		coords = ref.coords,
	}
	table.insert(self.m_boss_types_avail, { name = "GB_BOSSC", id = 0 })
end

function YRV3:PopulateClubhouse()
	local club_prop = stats.get_int("MPX_PROP_CLUBHOUSE")
	if (not self:IsPropertyIndexValid(club_prop)) then
		return
	end

	local idx      = club_prop - 90
	local club_ref = RawData.Clubhouses[idx]
	if (not club_ref) then return end

	local safe_data = RawData.CashSafes.fronts.clubhouse
	safe_data.name = "Clubhouse Duffle Bag"
	self.m_businesses.clubhouse = require("Clubhouse") {
		id        = idx,
		name      = Game.GetGXTLabel(club_ref.gxt),
		coords    = club_ref.coords,
		safe_data = safe_data
	}
	table.insert(self.m_boss_types_avail, { name = "GB_REST_ACCM", id = 1 })
end

function YRV3:PopulateBikerBusinesses()
	self:PopulateClubhouse()
	local Factory = require("Factory")

	if (not self.m_businesses.bunker) then
		local idx = stats.get_int("MPX_PROP_FAC_SLOT5")
		local ref = RawData.Bunkers[idx]

		if (ref) then
			local gxt_idx            = (idx < 28) and idx - 20 or idx - 19
			local has_eq_upgrade     = stats.get_int("MPX_BUNKER_EQUIPMENT") == 1
			local has_staff_upgrade  = stats.get_int("MPX_BUNKER_STAFF") == 1
			local eq_upg_mult        = tunables.get_int("GR_MANU_PRODUCT_VALUE_EQUIPMENT_UPGRADE")
			local stf_upg_mult       = tunables.get_int("GR_MANU_PRODUCT_VALUE_STAFF_UPGRADE")

			self.m_businesses.bunker = Factory.new({
				id         = 5,
				name       = Game.GetGXTLabel(_F("MP_BUNKER_%d", gxt_idx)),
				coords     = ref and ref.coords or vec3:zero(),
				vpu_mult_1 = has_eq_upgrade and eq_upg_mult or 0,
				vpu_mult_2 = has_staff_upgrade and stf_upg_mult or 0,
				vpu        = tunables.get_int("GR_MANU_PRODUCT_VALUE"),
				max_units  = 100,
			})
		end
	end

	if (not self.m_businesses.acid_lab and stats.get_int("MPX_XM22_LAB_OWNED") ~= 0) then
		local has_eq_upgrade       = (stats.get_int("MPX_AWD_CALLME") >= tunables.get_int("ACID_LAB_UPGRADE_EQUIPMENT_NUM_MISSIONS_UNLOCK"))
			and (stats.get_int("MPX_XM22_LAB_EQUIP_UPGRADED") == 1)
		local eq_upg_mult          = tunables.get_int("BIKER_ACID_PRODUCT_VALUE_EQUIPMENT_UPGRADE")

		self.m_businesses.acid_lab = Factory.new({
			id         = 6,
			name       = Game.GetGXTLabel("ACID_LAB_TITLE"),
			vpu_mult_1 = has_eq_upgrade and eq_upg_mult or 0,
			vpu_mult_2 = 0,
			vpu        = tunables.get_int("BIKER_ACID_PRODUCT_VALUE"),
			max_units  = 160,
			coords     = vec3:new(597.7751, -405.7288, 26.0292),
		})
	end
end

function YRV3:PopulateNightclub()
	if (self.m_businesses.nightclub) then
		self.m_data_initialized = true
		return
	end

	ThreadManager:Run(function()
		local nc_index = stats.get_int("MPX_NIGHTCLUB_OWNED")
		local ref      = RawData.Nightclubs[nc_index]
		if (not self:IsPropertyIndexValid(nc_index) or not ref) then
			self.m_data_initialized = true
			return
		end

		local nameid    = stats.get_int("MPX_PROP_NIGHTCLUB_NAME_ID")
		local safedata  = RawData.CashSafes.fronts.nightclub
		local clubname  = RawData.NightclubNames[nameid + 1]
		safedata.name   = clubname

		local nightclub = require("Nightclub") {
			id          = nc_index,
			name        = Game.GetGXTLabel(_F("MP_NCLU_%d", nc_index)),
			custom_name = clubname,
			coords      = ref.coords,
			safe_data   = safedata
		}

		if not (nightclub and nightclub:IsValid()) then
			self.m_data_initialized = true
			return
		end

		while (not self.m_initial_data_done) do
			yield()
		end

		local owns_cargo = false
		local hangar     = self.m_businesses.hangar
		local office     = self.m_businesses.office
		local clubhouse  = self.m_businesses.clubhouse

		if (hangar and hangar:IsValid()) then
			owns_cargo = true
		elseif (office and office:IsValid()) then
			owns_cargo = office:HasCargoWarehouse()
		end

		if (owns_cargo) then
			nightclub:AddSubBusiness(0)
		end

		if (self.m_businesses.bunker) then
			nightclub:AddSubBusiness(1)
		end

		if (clubhouse and clubhouse:IsValid()) then
			for _, bb in ipairs(clubhouse:GetSubBusinesses()) do
				if (bb:IsValid()) then
					local index = bb:GetIndex()
					nightclub:AddSubBusiness(index + 2)
				end
			end
		end

		self.m_businesses.nightclub = nightclub
		self.m_data_initialized     = true

		if (GVars.features.yrv3.nc_always_popular) then
			self.m_businesses.nightclub:LockPopularityDecay()
		end
	end)
end

function YRV3:PopulateCarWash()
	local idx = stats.get_int("MPX_SB_CAR_WASH_OWNED")
	if (not self:IsPropertyIndexValid(idx)) then
		return
	end

	self.m_businesses.car_wash = require("CarWash") {
		name   = Game.GetGXTLabel("CELL_CWAS"),
		coords = vec3:new(25.645266, -1412.290649, 29.362230)
	}
end

function YRV3:PopulateCashSafes()
	local CashSafe = require("CashSafe")
	for i, data in ipairs(RawData.CashSafes.regular) do
		local property_index = stats.get_int(data.property_stat)
		if (not self:IsPropertyIndexValid(property_index)) then
			goto continue
		end

		local entry                = RawData[data.raw_data_entry][property_index]
		local name                 = entry and Game.GetGXTLabel(entry.gxt) or "NULL"
		local coords               = entry and entry.coords or nil
		self.m_businesses.safes[i] = CashSafe.new({
			name            = name,
			coords          = coords,
			cash_value_stat = data.cash_value_stat,
			paytime_stat    = data.paytime_stat,
			interior_id     = data.interior_id,
			room_hash       = data.room_hash,
			get_max_cash    = data.get_max_cash,
			global_offset   = data.global_offset
		})
		::continue::
	end
end

function YRV3:PopulateSalvageYard()
	local property_index = stats.get_int("MPX_SALVAGE_YARD_OWNED")
	if (not self:IsPropertyIndexValid(property_index)) then
		return
	end

	local ref       = RawData.SalvageYards[property_index]
	local name      = ref and Game.GetGXTLabel(ref.gxt) or _T("SY_SALVAGE_YARD")
	local safe_data = RawData.CashSafes.fronts.salvage_yard
	safe_data.name  = name


	self.m_businesses.salvage_yard = require("SalvageYard") {
		id        = property_index,
		name      = name,
		coords    = ref and ref.coords or nil,
		safe_data = safe_data
	}

	if (self.m_businesses.salvage_yard and GVars.features.yrv3.sy_always_max_income) then
		self.m_businesses.salvage_yard:LockIncomeDecay()
	end
end

function YRV3:PreInit()
	if (self.m_initial_data_done or self.m_data_initialized) then
		return
	end

	ThreadManager:Run(function()
		self:PopulateHangar()
		self:PopulateOffice()
		self:PopulateBikerBusinesses()
		self:PopulateCarWash()
		self:PopulateCashSafes()
		self:PopulateSalvageYard()
		self.m_initial_data_done = true
	end)
end

function YRV3:InitializeData()
	if (self.m_data_initialized
			or not Game.IsOnline()
			or self.m_state == Enums.eYRState.LOADING
			or self.m_state == Enums.eYRState.RELOADING
		) then
		return
	end

	self.m_state      = Enums.eYRState.LOADING
	self.m_last_error = "GENERIC_WAIT_LABEL"
	self:PreInit()
	self:PopulateNightclub()
end

function YRV3:CommandFinishSale()
	if (not self:CanAccess()) then
		return
	end

	if (GVars.features.yrv3.autosell) then
		Notifier:ShowWarning(
			"YRV3",
			"You aleady have 'Auto-Sell' enabled. No need to manually trigger it.",
			false,
			5
		)
		return
	end

	if (not self.m_sell_script_running) then
		Notifier:ShowWarning(
			"YRV3",
			"No supported sale script is currently running.",
			false,
			5
		)
		return
	end

	self:FinishSale()
end

---@param index number
function YRV3:CommandWarehouseAutoFill(index)
	if (not self:CanAccess()) then
		return
	end

	local office = self:GetOffice()
	if (not office) then
		return
	end

	local warehouse = office:GetCargoWarehouseByIndex(index)
	if (not warehouse or not warehouse:IsValid()) then
		Notifier:ShowError(
			"YRV3",
			_F("No warehouse found in slot %d!", index),
			false
		)
		return
	end

	warehouse.auto_fill = not warehouse.auto_fill
	Notifier:ShowMessage(warehouse:GetName(), _F("Autofill %s.", warehouse.auto_fill and "enabled" or "disabled"))
end

function YRV3:CommandHangarAutoFill()
	if (not self:CanAccess()) then
		return
	end

	local hangar = self.m_businesses.hangar
	if (not hangar or not hangar:IsValid()) then
		Notifier:ShowError(
			"YRV3",
			_T("YRV3_HANGAR_NOT_OWNED"),
			false,
			5
		)
		return
	end

	if (hangar:HasFullProduction()) then
		return
	end

	hangar.auto_fill = not hangar.auto_fill
	Notifier:ShowMessage(hangar:GetName(), _F("Autofill %s.", hangar.auto_fill and "enabled" or "disabled"))
end

---@param index integer -- `1 .. 7`
---@return Factory?
function YRV3:GetFactoryByIndex(index)
	if (not self:CanAccess()) then return end

	if (type(index) ~= "number" or not math.is_inrange(index, 1, 7)) then
		Notifier:ShowError("YRV3", "Invalid factory index! Please make sure to use a number between 1 and 7.")
		return
	end

	index = index - 1
	if (index < 5) then
		local clubhouse = self.m_businesses.clubhouse
		if (not clubhouse) then return end

		local factories = self.m_businesses.clubhouse:GetSubBusinesses()
		if (type(factories) ~= "table") then
			return
		end

		for _, f in ipairs(factories) do
			if (f:GetIndex() == index) then
				return f
			end
		end
	elseif (index == 5) then
		return self.m_businesses.bunker
	elseif (index == 6) then
		return self.m_businesses.acid_lab
	end

	return nil
end

---@param index integer -- `1 .. 7`
function YRV3:CommandFactoryRestock(index)
	local factory = self:GetFactoryByIndex(index)
	if (not factory) then
		Notifier:ShowError("YRV3", _T("YRV3_MC_NONE_OWNED"), false, 5)
		return
	end

	factory:ReStock()
end

---@param index integer -- `1 .. 7`
---@param isNightclubHub? boolean
function YRV3:CommandToggleProduction(index, isNightclubHub)
	if (not GVars.features.unsafe_feats_enabled) then
		Notifier:ShowError("YRV3", _T("YRV3_UNSAFE_FEAT_BYPASS_ERR"))
		return
	end

	local factory
	if (not isNightclubHub) then
		factory = self:GetFactoryByIndex(index)
	else
		local nc = self.m_businesses.nightclub
		if (not nc) then
			Notifier:ShowError("YRV3", _T("YRV3_CLUB_NOT_OWNED"), false, 5)
			return
		end

		local hubs = nc:GetSubBusinesses()
		if (type(hubs) == "table") then
			for _, hub in ipairs(hubs) do
				if (hub:GetIndex() == index - 1) then
					factory = hub
					break
				end
			end
		end
	end

	if (not factory) then
		Notifier:ShowError("YRV3", _T("YRV3_GENERIC_NOT_OWNED"), false, 5)
		return
	end

	local name = isNightclubHub and self:GetNightclub():GetCustomName() or
		(factory:GetNormalizedName() or factory:GetName())

	if (factory:HasFullProduction()) then
		Notifier:ShowError(name, _T("YRV3_FAST_PROD_ERR"))
		return
	end

	factory.fast_prod_enabled = not factory.fast_prod_enabled
	local bool                = factory.fast_prod_enabled
	local prefix              = "Fast production"
	local state               = bool and "enabled" or "disabled"
	local msg                 = isNightclubHub and _F("%s for the %s hub", state, factory:GetName()) or state
	Notifier:ShowMessage(name, _F("%s %s.", prefix, msg))
end

---@return array<CashSafe>
function YRV3:GetAllSafes()
	local outArray = {}
	for key, entry in self:BusinessIter() do
		if (key == "safes") then
			for _, safe in ipairs(entry) do
				table.insert(outArray, safe)
			end
		else
			local func = entry.GetCashSafe
			if (type(func) == "function") then ---@cast entry BusinessFront|CarWash
				table.insert(outArray, func(entry))
			end
		end
	end
	return outArray
end

function YRV3:FillAllSafes()
	if (not GVars.features.unsafe_feats_enabled) then
		Notifier:ShowError("YRV3", _T("YRV3_UNSAFE_FEAT_BYPASS_ERR"))
		return
	end

	local count = 0
	for _, safe in ipairs(self:GetAllSafes()) do
		if (type(safe.FillNow) == "function" and safe:FillNow()) then
			count = count + 1
		end
	end

	if (count == 0) then
		Notifier:ShowMessage("YRV3", _T("YRV3_BULK_SAFE_FILL_NONE"))
	else
		Notifier:ShowSuccess("YRV3", _T("YRV3_BULK_SAFE_FILL_SUCCESS_FMT", count))
	end
end

function YRV3:FillAll()
	if (not self:CanAccess()) then
		return
	end

	local office = self.m_businesses.office
	local hangar = self.m_businesses.hangar
	if (office and office:IsValid()) then
		for _, wh in ipairs(office:GetCargoWarehouses()) do
			if (wh:IsValid()) then
				wh.auto_fill = true
			end
		end
	end

	if (hangar and hangar:IsValid()) then
		hangar.auto_fill = true
	end

	for i = 1, 7 do
		local factory = self:GetFactoryByIndex(i)
		if (factory and factory:IsValid() and factory:IsSetup()) then
			factory:ReStock()
			sleep(math.random(600, 1200))
		end
	end
end

---@return string
function YRV3:GetRunningSellScriptDisplayName()
	if (not self.m_sell_script_running or not self.m_sell_script_name) then
		return "None"
	end

	return RawData.ScriptDisplayNames[self.m_sell_script_name] or "None"
end

function YRV3:FinishSale()
	local sn = self.m_sell_script_name
	if (not sn) then
		return
	end

	local func = RawData.SellScripts[sn]
	if (not func) then return end

	self.m_has_triggered_autosell = true
	script.execute_as_script(sn, function()
		if (not LocalPlayer:IsHostOfScript(sn)) then
			Notifier:ShowError("YRV3", _T("YRV3_SCRIPT_HOST_ERR"))
			return
		end
		func()
	end)
end

function YRV3:FinishCEOCargoSourceMission()
	if (script.is_active("gb_contraband_buy")) then
		if (not LocalPlayer:IsHostOfScript("gb_contraband_buy")) then
			Notifier:ShowError("YRV3", _T("YRV3_SCRIPT_HOST_ERR"))
			return
		end

		local buyLocal = SGSL:Get(SGSL.data.gb_contraband_buy_local_1):AsLocal()
		buyLocal:At(5):WriteInt(1)
		buyLocal:At(191):WriteInt(6)
		buyLocal:At(192):WriteInt(4)
	elseif (script.is_active("fm_content_cargo")) then
		if (not LocalPlayer:IsHostOfScript("fm_content_cargo")) then
			Notifier:ShowError("YRV3", _T("YRV3_SCRIPT_HOST_ERR"))
			return
		end

		local fmccLocal2       = SGSL:Get(SGSL.data.gb_contraband_buy_local_2):AsLocal():At(1):At(0)
		local gbcb_obj         = SGSL:Get(SGSL.data.gb_contraband_buy_local_3)
		local fmccLocal3       = gbcb_obj:AsLocal()
		local fmccLocal3Offset = gbcb_obj:GetOffset(1)
		local bs               = fmccLocal2:ReadInt()

		if (not Bit.IsBitSet(bs, 11)) then
			bs = Bit.Set(bs, 11)
			fmccLocal2:WriteInt(bs)
		end

		fmccLocal3:At(fmccLocal3Offset):WriteInt(3)
	end
end

---@param name string
function YRV3:ProcessCooldown(name)
	self.m_cooldown_controller:SetDirty(name, true)
end

function YRV3:ProcessAllCooldowns()
	self.m_cooldown_controller:SetNextCallForced(true)
end

function YRV3:CooldownHandler()
	local now_ms = Time.Millis()
	if (now_ms - self.m_last_cooldown_check_time < 2000) then
		return
	end

	self.m_cooldown_controller:OnCall()
	self.m_last_cooldown_check_time = now_ms
end

---@return boolean isRunning, string? scriptName, string displayName
function YRV3:FindRunningSaleScript()
	for sn in pairs(RawData.SellScripts) do
		if (script.is_active(sn)) then
			return true, sn, RawData.ScriptDisplayNames[sn] or "None"
		end
	end

	return false, nil, "None"
end

function YRV3:SetupAutosell()
	if (Time.Millis() - self.m_last_autosell_check_time < 1200) then
		return
	end

	self.m_sell_script_running,
	self.m_sell_script_name,
	self.m_sell_script_disp_name = self:FindRunningSaleScript()

	if (self.m_sell_script_running and self.m_bhub_script_handle ~= 0) then -- was triggered from the mct
		for _, scr in pairs(RawData.ScriptsToTerminate) do
			if (script.is_active(scr)) then
				PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 202, 1.0)
				sleep(200)
				PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 202, 1.0)
				break
			end
		end

		sleep(1000)
		if (CAM.IS_SCREEN_FADING_OUT() or CAM.IS_SCREEN_FADED_OUT()) then
			local fadedOutTimer = Timer.new(1e4)
			while (not fadedOutTimer:IsDone()) do
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
	end

	self.m_last_autosell_check_time = Time.Millis()
end

function YRV3:AutoSellHandler()
	self:SetupAutosell()
	if not (GVars.features.yrv3.autosell and self.m_sell_script_running) then
		return
	end

	local scr_name = self.m_sell_script_name
	if (not scr_name) then return end

	if (not self.m_has_triggered_autosell and not CAM.IS_SCREEN_FADED_OUT()) then
		self.m_has_triggered_autosell = true
		Notifier:ShowMessage("YRV3", _T("YRV3_AUTO_SELL_COUNTDOWN"))

		local timeout = Timer.new(2e4)
		while (not timeout:IsDone() or AUDIO.IS_MOBILE_PHONE_CALL_ONGOING()) do
			if (not GVars.features.yrv3.autosell or not script.is_active(scr_name)) then
				Notifier:ShowMessage("YRV3", _T("YRV3_AUTO_SELL_CANCELED_MSG"))
				self.m_has_triggered_autosell = false
				return
			end
			yield()
		end

		self:FinishSale()
	end

	while (self.m_has_triggered_autosell) do
		if (not script.is_active(scr_name)) then
			break
		end
		yield()
	end
	self.m_has_triggered_autosell = false
end

-- Master Control Terminal
function YRV3:MCT()
	if (LocalPlayer:IsBrowsingApps()) then return end

	local BusinessHubGlobal1 = SGSL:Get(SGSL.data.arcade_bhub_global_1):AsGlobal()
	local BusinessHubGlobal2 = SGSL:Get(SGSL.data.arcade_bhub_global_2):AsGlobal()
	ThreadManager:Run(function()
		if (BusinessHubGlobal1:ReadInt() ~= 0) then
			BusinessHubGlobal1:WriteInt(0)
		end

		TaskWait(Game.RequestScript, "appArcadeBusinessHub")
		self.m_bhub_script_handle = SYSTEM.START_NEW_SCRIPT("appArcadeBusinessHub", 1424) -- STACK_SIZE_DEFAULT
		SCRIPT.SET_SCRIPT_AS_NO_LONGER_NEEDED("appArcadeBusinessHub")
		sleep(100)

		while (script.is_active("appArcadeBusinessHub")) do
			if (BusinessHubGlobal2:ReadInt() == -1) then
				BusinessHubGlobal2:WriteInt(0)
			end

			yield()
		end

		while (LocalPlayer:IsBrowsingApps()) do
			yield()
		end

		BusinessHubGlobal1:WriteInt(0)
		self.m_bhub_script_handle = 0
	end)
end

function YRV3:UpdateBusinesses()
	if (not self:CanAccess()) then
		return
	end

	local now_ms = Time.Millis()
	if (now_ms - self.m_last_business_update_time < 500) then
		return
	end

	for key, business in self:BusinessIter() do
		if (key == "safes") then
			for _, cash_safe in ipairs(business) do
				cash_safe:Update()
			end
		elseif (type(business.Update) == "function") then
			business:Update()
		end
	end

	self.m_last_business_update_time = now_ms
end

---@param business BusinessBase|BasicBusiness
local function getBusinessIncome(business)
	if not (business and business:IsValid()) then return 0 end
	return business:GetEstimatedIncome()
end

function YRV3:CalculateEstimatedIncome()
	if (not self.m_data_initialized or not GUI:IsOpen()) then -- has no purpose outside of UI
		return
	end

	local now_ms = Time.Millis()
	if (now_ms - self.m_last_income_check_time < 1200) then
		return
	end

	local total = 0
	for name, business in self:BusinessIter() do
		if (name == "safes") then
			for _, safe in ipairs(business) do
				total = total + safe:GetCashValue()
			end
		else
			total = total + getBusinessIncome(business)
		end
	end

	self.m_total_sum              = total
	self.m_total_sum_fmt          = string.formatmoney(total)
	self.m_last_income_check_time = now_ms
end

function YRV3:OnTick()
	yield()

	if (not Backend:IsUpToDate()) then
		self.m_state = Enums.eYRState.ERROR
		self:SetLastError("GENERIC_OUTDATED")
		return
	end

	if (self.m_state == Enums.eYRState.RELOADING) then
		return
	end

	if (not self:CanAccess()) then
		self.m_state = Enums.eYRState.OFFLINE

		if (not network.is_session_started()) then
			self:SetLastError("GENERIC_UNAVAILABLE_SP")
		else
			if (script.is_active("maintransition")) then
				self.m_state = Enums.eYRState.WAITING
				self:SetLastError("YRV3_STATE_WAIT_TRANSITION")
			elseif (NETWORK.NETWORK_IS_ACTIVITY_SESSION()) then
				self.m_state = Enums.eYRState.ERROR
				self:SetLastError("YRV3_STATE_ERR_WRONG_SESSION")
			end
		end

		return
	end

	if (not self.m_data_initialized and not self.m_initial_data_done and self.m_state ~= Enums.eYRState.LOADING) then
		self:InitializeData()
	end

	while (not self.m_data_initialized) do
		yield()
	end

	self.m_state = Enums.eYRState.RUNNING
	self:SetLastError("")

	self:UpdateBusinesses()
	self:CalculateEstimatedIncome()

	self:AutoSellHandler()
	self:CooldownHandler()
end

return YRV3:init()
