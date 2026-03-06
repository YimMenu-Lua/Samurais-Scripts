-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView = require("includes.classes.gta.CStructView")
local CWeaponInfo = require("includes.classes.gta.CWeaponInfo")


--------------------------------------
-- Class: CPedWeaponManager
--------------------------------------
---@class CPedWeaponManager : CStructBase<CPedWeaponManager>
---@field protected m_ptr pointer
---@field public m_owner pointer<CPed>
---@field public m_selected_weapon_hash pointer<uint32_t>
---@field public m_weapon_info CWeaponInfo?
---@field public m_vehicle_weapon_info CWeaponInfo?
---@overload fun(ptr: pointer): CPedWeaponManager
local CPedWeaponManager = CStructView("CPedWeaponManager", {
	{ "m_owner",                { 0x0010, "deref" } },
	{ "m_selected_weapon_hash", 0x0018 },
	{ "m_weapon_info",          0x0020,             CWeaponInfo },
	{ "m_vehicle_weapon_info",  0x0070,             CWeaponInfo },
}, 0x0078)

return CPedWeaponManager
