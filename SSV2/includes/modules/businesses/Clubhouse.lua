-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessFront   = require("includes.modules.businesses.BusinessFront")
local Factory         = require("includes.modules.businesses.Factory")
local RawBusinessData = require("includes.data.yrv3_data")

-- Class representing a MC Clubhouse business.
---@class Clubhouse : BusinessFront
---@field private m_id integer
---@field private m_name string
---@field private m_custom_name string
---@field private m_safe CashSafe
---@field private m_subs Factory[]
---@field public GetSubBusinesses fun(self: Clubhouse): Factory[]
local Clubhouse       = setmetatable({}, BusinessFront)
Clubhouse.__index     = Clubhouse

---@param opts BusinessFrontOpts
---@return Clubhouse
function Clubhouse.new(opts)
	local base             = BusinessFront.new(opts)
	local instance         = setmetatable(base, Clubhouse)
	local custom_name1     = STATS.STAT_GET_STRING(joaat(_F("MP%d_MC_GANG_NAME", stats.get_character_index())), -1)
	local custom_name2     = STATS.STAT_GET_STRING(joaat(_F("MP%d_MC_GANG_NAME2", stats.get_character_index())), -1)
	instance.m_custom_name = _F("%s%s", custom_name1, custom_name2)

	---@diagnostic disable-next-line
	return instance
end

---@return string
function Clubhouse:GetCustomName()
	return self.m_custom_name
end

---@return joaat_t
function Clubhouse:GetClientBikeModel()
	return stats.get_int("MPX_MPSV_MODEL_BIKER_CLT")
end

---@return string
function Clubhouse:GetClientBikeName()
	local model = self:GetClientBikeModel()
	if (not model or model == 0) then
		return _T("GENERIC_NONE")
	end

	return vehicles.get_vehicle_display_name(model)
end

---@param index integer
function Clubhouse:AddSubBusiness(index)
	if (not math.is_inrange(index, 0, 4)) then
		return
	end

	local property_index = stats.get_int(_F("MPX_FACTORYSLOT%d", index))
	local ref = RawBusinessData.BikerBusinesses[property_index]
	if (not ref) then
		return
	end

	local ref2 = RawBusinessData.BikerTunables[ref.id]
	if (not ref2) then
		return
	end

	local has_eq_upgrade    = stats.get_int(_F("MPX_FACTORYUPGRADES%d", index)) == 1
	local has_staff_upgrade = stats.get_int(_F("MPX_FACTORYUPGRADES%d_1", index)) == 1
	local eq_upg_mult       = tunables.get_int(ref2.mult_1)
	local stf_upg_mult      = tunables.get_int(ref2.mult_2)
	local normalized_name   = Switch(ref.id) {
		[0]     = "BIKER_WH_5B",
		[1]     = "BIKER_WH_2B",
		[2]     = "BIKER_WH_4B",
		[3]     = "BIKER_WH_1B",
		[4]     = "BIKER_WH_3B",
		default = ""
	}

	table.insert(self.m_subs, Factory.new({
		id              = index,
		name            = Game.GetGXTLabel(ref.gxt),
		normalized_name = not normalized_name:isempty() and Game.GetGXTLabel(normalized_name) or nil,
		max_units       = ref2.max_units,
		vpu             = tunables.get_int(ref2.vpu),
		vpu_mult_1      = has_eq_upgrade and eq_upg_mult or 0,
		vpu_mult_2      = has_staff_upgrade and stf_upg_mult or 0,
		coords          = ref.coords,
	}))
end

return Clubhouse
