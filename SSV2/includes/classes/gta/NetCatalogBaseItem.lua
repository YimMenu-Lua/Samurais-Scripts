-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView = require("includes.classes.gta.CStructView")


--------------------------------------
-- Class: NetCatalogBaseItem
--------------------------------------
---@class NetCatalogBaseItem : CStructBase<NetCatalogBaseItem>
---@field m_vft pointer_ref
---@field m_hash pointer<uint32_t>
---@field m_category_hash pointer<uint32_t>
---@field m_price pointer<int32_t>
---@field m_stat_value pointer<int32_t>
---@overload fun(ptr: pointer): NetCatalogBaseItem
local NetCatalogBaseItem = CStructView("NetCatalogBaseItem", 0x20)

---@param ptr pointer
---@return NetCatalogBaseItem
function NetCatalogBaseItem.new(ptr)
	return MakeInstance({
		m_ptr           = ptr,
		m_vft           = ptr,
		m_hash          = ptr:add(0x08),
		m_category_hash = ptr:add(0x0C),
		m_price         = ptr:add(0x10),
		m_stat_value    = ptr:add(0x18),
	}, NetCatalogBaseItem)
end

---@return joaat_t
function NetCatalogBaseItem:GetHash()
	return self:__safecall(0, function() return self.m_hash:get_dword() end)
end

---@return int32_t
function NetCatalogBaseItem:GetPrice()
	return self:__safecall(-1, function() return self.m_price:get_int() end)
end

---@return int32_t
function NetCatalogBaseItem:GetStatValue()
	return self:__safecall(-1, function() return self.m_stat_value:get_int() end)
end

return NetCatalogBaseItem
