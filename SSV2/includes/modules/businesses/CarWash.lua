-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BasicBusiness = require("includes.modules.businesses.BasicBusiness")
local CashSafe      = require("includes.modules.businesses.CashSafe")

local function toggle_cd(key)
	if (type(key) ~= "string") then
		return
	end

	local entry = GVars.features.yrv3
	if (not entry or type(entry[key]) ~= "boolean") then
		return
	end

	entry[key] = not entry[key]
	YRV3:SetCooldownStateDirty(key, true)
end

---@class CarWashDuffleOpts
---@class CarWashDuffle : CashSafe
---@field private m_max_cash integer
local CarWashDuffle   = setmetatable({}, CashSafe)
CarWashDuffle.__index = CarWashDuffle

---@param opts CashSafeOpts
---@return CarWashDuffle
function CarWashDuffle.new(opts)
	local base = CashSafe.new(opts)
	---@diagnostic disable-next-line
	return setmetatable(base, CarWashDuffle)
end

function CarWashDuffle:IsFull()
	return self:GetDuffleValue() >= self:GetCapacity()
end

---@return integer
function CarWashDuffle:GetPendingCash()
	return stats.get_int("MPX_CAR_WASH_DUFFEL_PENDING")
end

---@return integer
function CarWashDuffle:GetDirtyCashPosix()
	return stats.get_int("MPX_CAR_WASH_DUFFEL_POSIX")
end

function CarWashDuffle:GetDirtyCash()
	local posix = self:GetDirtyCashPosix()
	return Time.Epoch() >= posix and 0 or self:GetPendingCash()
end

---@return integer
function CarWashDuffle:GetDuffleValue()
	return self:GetCashValue() - self:GetDirtyCash()
end

function CarWashDuffle:CleanNow()
	if (self:GetDirtyCash() == 0) then
		return
	end

	-- this stat is useless. Posix used in freemode is stored at Global_1882572[PLAYER::PLAYER_ID() /*315*/].f_158.f_27.f_5 (as of 1.72-3751.0)
	-- not even gonna bother with this shit I hate maintaining globals and locals
	stats.set_int("MPX_CAR_WASH_DUFFEL_POSIX", Time.Epoch() + 1000)
end

---@class CarWashSubBusinessOpts : BasicBusinessOpts
---@field heat_packed_stat integer
---@field legal_work_cooldown_gvar_key string
---@field illegal_work_cooldown_gvar_key string

---@class CarWashSubBusiness : BasicBusiness
---@field private m_name string
---@field private m_heat_packed_stat integer
---@field private m_legal_work_cooldown_gvar_key string
---@field private m_illegal_work_cooldown_gvar_key string
local CarWashSubBusiness   = setmetatable({}, BasicBusiness)
CarWashSubBusiness.__index = CarWashSubBusiness

---@param opts CarWashSubBusinessOpts
---@return CarWashSubBusiness
function CarWashSubBusiness.new(opts)
	local base                                = BasicBusiness.new(opts)
	local instance                            = setmetatable(base, CarWashSubBusiness)
	instance.m_heat_packed_stat               = opts.heat_packed_stat
	instance.m_legal_work_cooldown_gvar_key   = opts.legal_work_cooldown_gvar_key
	instance.m_illegal_work_cooldown_gvar_key = opts.illegal_work_cooldown_gvar_key
	---@diagnostic disable-next-line
	return instance
end

---@return integer
function CarWashSubBusiness:GetHeat()
	return stats.get_packed_stat_int(self.m_heat_packed_stat)
end

function CarWashSubBusiness:ClearHeat()
	if (self:GetHeat() <= 0) then
		return
	end

	stats.set_packed_stat_int(self.m_heat_packed_stat, 0)
end

---@return boolean
function CarWashSubBusiness:GetLegalWorkCooldownState()
	---@diagnostic disable-next-line
	return GVars.features.yrv3[self.m_legal_work_cooldown_gvar_key] or false
end

---@return boolean
function CarWashSubBusiness:GetIllegalWorkCooldownState()
	---@diagnostic disable-next-line
	return GVars.features.yrv3[self.m_illegal_work_cooldown_gvar_key] or false
end

function CarWashSubBusiness:ToggleLegalWorkCooldown()
	toggle_cd(self.m_legal_work_cooldown_gvar_key)
end

function CarWashSubBusiness:ToggleIllegalWorkCooldown()
	toggle_cd(self.m_illegal_work_cooldown_gvar_key)
end

-- Class representing the Car Wash business.
---@class CarWash : BasicBusiness
---@field private m_id integer
---@field private m_name string
---@field private m_safe CashSafe
---@field private m_duffle CarWashDuffle
---@field private m_subs CarWashSubBusiness[]
local CarWash   = setmetatable({}, BasicBusiness)
CarWash.__index = CarWash

---@param opts BasicBusinessOpts
---@return CarWash
function CarWash.new(opts)
	local base        = BasicBusiness.new(opts)
	local instance    = setmetatable(base, CarWash)
	instance.m_safe   = CashSafe.new({
		name            = opts.name,
		cash_value_stat = "MPX_CWASH_SAFE_CASH_VALUE",
		paytime_stat    = "MPX_CWASH_PAY_TIME_LEFT",
		interior_id     = 298497,
		room_hash       = 4269274169,
		get_max_cash    = function()
			return tunables.get_int("TYCOON_CAR_WASH_SAFE_MAX_STORAGE_AMOUNT")
		end,
	})

	instance.m_duffle = CarWashDuffle.new({
		name            = opts.name,
		cash_value_stat = "MPX_CAR_WASH_DUFFEL_VALUE",
		get_max_cash    = function()
			return tunables.get_int(564305888) -- 1M
		end,
	})

	instance.m_subs   = {}
	if (stats.get_int("MPX_SB_WEED_SHOP_OWNED") ~= 0) then
		table.insert(instance.m_subs, CarWashSubBusiness.new({
			name                           = Game.GetGXTLabel("CELL_WSHOP"),
			coords                         = vec3:new(-1162.051147, -1564.757202, 4.410227),
			heat_packed_stat               = 24925,
			legal_work_cooldown_gvar_key   = "weedshop_legal_work_cd",
			illegal_work_cooldown_gvar_key = "weedshop_illegal_work_cd",
		}))
	end

	if (stats.get_int("MPX_SB_HELI_TOURS_OWNED") ~= 0) then
		table.insert(instance.m_subs, CarWashSubBusiness.new({
			name                           = Game.GetGXTLabel("CELL_HELIT"),
			coords                         = vec3:new(-753.524841, -1511.244751, 5.015130),
			heat_packed_stat               = 24926,
			legal_work_cooldown_gvar_key   = "helitours_legal_work_cd",
			illegal_work_cooldown_gvar_key = "helitours_illegal_work_cd",
		}))
	end

	---@diagnostic disable-next-line
	return instance
end

---@return integer
function CarWash:GetHeat()
	return stats.get_packed_stat_int(24924)
end

function CarWash:ClearHeat()
	if (self:GetHeat() <= 0) then
		return
	end

	stats.set_packed_stat_int(24924, 0)
end

---@return CashSafe
function CarWash:GetCashSafe()
	return self.m_safe
end

---@return CarWashDuffle
function CarWash:GetDuffleBag()
	return self.m_duffle
end

---@return boolean
function CarWash:GetLegalWorkCooldownState()
	return GVars.features.yrv3.cwash_legal_work_cd
end

---@return boolean
function CarWash:GetIllegalWorkCooldownState()
	return GVars.features.yrv3.cwash_illegal_work_cd
end

function CarWash:ToggleLegalWorkCooldown()
	toggle_cd("cwash_legal_work_cd")
end

function CarWash:ToggleIllegalWorkCooldown()
	toggle_cd("cwash_illegal_work_cd")
end

---@return array<CarWashSubBusiness>
function CarWash:GetSubBusinesses()
	return self.m_subs
end

---@return integer
function CarWash:GetEstimatedIncome()
	return self.m_safe:GetCashValue() + self.m_duffle:GetDuffleValue()
end

function CarWash:Update()
	if (not self:IsValid()) then
		return
	end

	if (self.m_safe and self.m_safe:CanLoop()) then
		if (self.m_safe.cash_loop_enabled and self:GetHeat() >= 90) then
			self.m_safe.cash_loop_enabled = false
			return
		end

		self.m_safe:Update()
	end
end

return CarWash
