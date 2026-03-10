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
---@field public m_owner pointer_ref<CPed>
---@field public m_selected_weapon_hash pointer<uint32_t>
---@field public m_weapon_info pointer_ref<CWeaponInfo>
---@field public m_vehicle_weapon_info pointer_ref<CWeaponInfo>
---@field private m_weapon_info_inst CWeaponInfo
---@field private m_vehicle_weapon_info_inst CWeaponInfo
---@overload fun(ptr: pointer): CPedWeaponManager
local CPedWeaponManager = CStructView("CPedWeaponManager", 0x0078)

---@param ptr pointer
---@return CPedWeaponManager?
function CPedWeaponManager.new(ptr)
	return setmetatable({
		m_ptr                      = ptr,
		m_owner                    = ptr:add(0x0010), -- CPed
		m_selected_weapon_hash     = ptr:add(0x0018),
		m_weapon_info              = ptr:add(0x0020),
		m_vehicle_weapon_info      = ptr:add(0x0070),
		m_weapon_info_inst         = CWeaponInfo(ptr:add(0x0020):deref()),
		m_vehicle_weapon_info_inst = CWeaponInfo(ptr:add(0x0070):deref())
		---@diagnostic disable-next-line: param-type-mismatch
	}, CPedWeaponManager)
end

---@return pointer<CPed>
function CPedWeaponManager:GetOwner()
	return self.m_owner:deref()
end

---@return CWeaponInfo
function CPedWeaponManager:GetWeaponInfo()
	local ptr = self.m_weapon_info:deref()

	---@diagnostic disable-next-line: invisible
	if (self.m_weapon_info_inst.m_ptr ~= ptr) then
		self.m_weapon_info_inst = CWeaponInfo(ptr)
	end
	return self.m_weapon_info_inst
end

---@return CWeaponInfo
function CPedWeaponManager:GetVehicleWeaponInfo()
	local ptr = self.m_vehicle_weapon_info:deref()

	---@diagnostic disable-next-line: invisible
	if (self.m_vehicle_weapon_info_inst.m_ptr ~= ptr) then
		self.m_vehicle_weapon_info_inst = CWeaponInfo(ptr)
	end
	return self.m_vehicle_weapon_info_inst
end

return CPedWeaponManager
