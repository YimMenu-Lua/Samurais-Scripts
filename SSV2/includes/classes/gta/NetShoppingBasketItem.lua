-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local CStructView = require("includes.classes.gta.CStructView")


--------------------------------------
-- Class: NetShoppingBasketItem
--------------------------------------
---@class NetShoppingBasketItem : CStructBase<NetShoppingBasketItem>
---@field m_key pointer<uint32_t>
---@field m_item pointer<uint32_t>
---@field m_price pointer<int32_t>
---@field m_stat_value pointer<int32_t>
---@overload fun(ptr: pointer): NetShoppingBasketItem
local NetShoppingBasketItem = CStructView("NetShoppingBasketItem", 0x20)

---@param ptr pointer
---@return NetShoppingBasketItem
function NetShoppingBasketItem.new(ptr)
	return MakeInstance({
		m_ptr        = ptr,
		m_key        = ptr,
		m_item       = ptr:add(0x08),
		m_price      = ptr:add(0x10),
		m_stat_value = ptr:add(0x18),
	}, NetShoppingBasketItem)
end

---@return joaat_t
function NetShoppingBasketItem:GetKey()
	return self.m_key:get_dword()
end

---@return joaat_t
function NetShoppingBasketItem:GetItemHash()
	return self.m_item:get_dword()
end

---@return int32_t
function NetShoppingBasketItem:GetPrice()
	return self.m_price:get_int()
end

---@return int32_t
function NetShoppingBasketItem:GetStatValue()
	return self.m_stat_value:get_int()
end

---@param key joaat_t
function NetShoppingBasketItem:SetKey(key)
	self.m_key:set_dword(key)
end

---@param hash joaat_t
function NetShoppingBasketItem:SetItemHash(hash)
	self.m_item:set_dword(hash)
end

---@param price int32_t
function NetShoppingBasketItem:SetPrice(price)
	self.m_price:set_int(price)
end

---@param value int32_t
function NetShoppingBasketItem:SetStatValue(value)
	self.m_stat_value:set_int(value)
end

return NetShoppingBasketItem
