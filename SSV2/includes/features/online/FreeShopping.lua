-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local DATA                       = require("includes.data.freeshopping_data")
local NetCatalog                 = require("includes.classes.gta.NetCatalog")
local NetShoppingBasketItem      = require("includes.classes.gta.NetShoppingBasketItem")
local ScrNativeCallContext       = require("includes.classes.gta.ScrNativeCallContext")
local ScrNativeRegistrationTable = require("includes.classes.gta.ScrNativeRegistrationTable")


--------------------------------------
-- Class: FreeShopping
--------------------------------------
---@class FreeShoppingPending
---@field coupon NetShoppingBasketItem
---@field source NetShoppingBasketItem
---@field quantity integer
---@field pointer pointer

---@class FreeShopping
---@field private m_enabled boolean
---@field private m_initialized boolean
---@field private m_hooks_installed boolean
---@field private m_hooks_failed boolean
---@field private m_error string?
---@field private m_current_action joaat_t
---@field private m_current_category joaat_t
---@field private m_pending table<uint64_t, FreeShoppingPending>
---@field private m_modifiers set<joaat_t>
---@field private m_property_actions set<joaat_t>
---@field private m_coupon_hash joaat_t
local FreeShopping   = {}
FreeShopping.__index = FreeShopping

---@return FreeShopping
function FreeShopping:init()
	if (self.m_initialized) then return self end

	self.m_enabled          = false
	self.m_hooks_installed  = false
	self.m_hooks_failed     = false
	self.m_pending          = {}
	self.m_current_action   = 0
	self.m_current_category = 0
	self.m_modifiers        = {}
	self.m_property_actions = {
		[_J("NET_SHOP_ACTION_BUY_PROPERTY") & 0xFFFFFFFF]  = true,
		[_J("NET_SHOP_ACTION_BUY_WAREHOUSE") & 0xFFFFFFFF] = true,
	}
	self.m_coupon_hash      = _J("PO_COUPON_CAR_XMAS2017") & 0xFFFFFFFF

	for _, name in ipairs(DATA.DiscountModifiers) do
		self.m_modifiers[_J(name) & 0xFFFFFFFF] = true
	end

	Backend:RegisterEventCallback(Enums.eBackendEvent.RELOAD_UNLOAD, function() self:Cleanup() end)
	local reset_basket = function() self:ResetBasket() end
	Backend:RegisterEventCallback(Enums.eBackendEvent.PLAYER_SWITCH, reset_basket)
	Backend:RegisterEventCallback(Enums.eBackendEvent.SESSION_SWITCH, reset_basket)
	Backend:RegisterEventCallback(Enums.eBackendEvent.SESSION_LEAVE, reset_basket)
	self.m_initialized = true
	return self
end

---@return boolean
function FreeShopping:IsSupported()
	return Backend:GetGameBranch() == Enums.eGameBranch.LEGACY
		and type(memory.dynamic_hook) == "function"
		and type(memory.dynamic_call) == "function"
end

---@return boolean
function FreeShopping:CanAccess()
	return self:IsSupported()
		and Backend:IsUpToDate()
		and Game.IsOnline()
		and not Backend.is_in_session_transition
		and not Backend.is_in_player_transition
end

---@return boolean
function FreeShopping:IsEnabled()
	return self.m_enabled
end

---@return string?
function FreeShopping:GetError()
	return self.m_error
end

---@private
---@param message any
function FreeShopping:OnError(message)
	self.m_error        = tostring(message)
	self.m_hooks_failed = true
	self:Cleanup()
	log.fwarning("[FreeShopping]: %s", self.m_error)
end

---@private
---@param method fun(self: FreeShopping, ctx: ScrNativeCallContext): boolean
---@return function
function FreeShopping:MakePreCallback(method)
	return function(_, ptr)
		if (self.m_hooks_failed) then return true end
		local ok, result = pcall(function() return method(self, ScrNativeCallContext(ptr)) end)
		if (not ok) then
			self:OnError(result)
			return true
		end
		return result
	end
end

---@private
---@return boolean
function FreeShopping:Initialize()
	if (self.m_hooks_installed) then return true end
	if (self.m_hooks_failed) then return false end

	local installing = false
	local ok, err = pcall(function()
		assert(PatternScanner:IsDone(), "Pointer scanning has not finished")
		assert(GPointers.NativeRegistrationTable:is_valid(), "Native registration table is unavailable")
		assert(GPointers.NetCatalog:is_valid(), "Catalog signature was not found")
		assert(type(GPointers.DynamicFuncs.BasketAddItem) == "function", "Basket add function is unavailable")

		local registrations = ScrNativeRegistrationTable(GPointers.NativeRegistrationTable)
		local handlers      = {}
		local addresses     = {}
		for name, hash in pairs(DATA.NativeHashes) do
			local ptr = registrations:GetHandler(hash)
			assert(ptr:is_valid(), _F("Missing native handler: %s", name))
			assert(not addresses[ptr:get_address()], "Native handlers unexpectedly share an address")
			addresses[ptr:get_address()] = true
			handlers[name] = ptr
		end

		installing = true
		memory.dynamic_hook(
			"SSV2.FreeShopping.BasketStart", "void", { "void*" }, handlers.BasketStart,
			self:MakePreCallback(self.OnBasketStartPre), nil
		)
		memory.dynamic_hook(
			"SSV2.FreeShopping.BasketAdd", "void", { "void*" }, handlers.BasketAdd,
			self:MakePreCallback(self.OnBasketAddPre),
			function(_, ptr)
				if (self.m_hooks_failed) then return end
				local ctx
				local success, message = pcall(function()
					ctx = ScrNativeCallContext(ptr)
					self:OnBasketAddPost(ctx)
				end)
				if (not success) then
					if (ctx) then pcall(ctx.SetReturnInt, ctx, 0) end
					self:OnError(message)
				end
			end
		)
		memory.dynamic_hook(
			"SSV2.FreeShopping.FakeCash", "void", { "void*" }, handlers.FakeCash,
			self:MakePreCallback(self.OnFakeCashPre), nil
		)
		memory.dynamic_hook(
			"SSV2.FreeShopping.ChangeCash", "void", { "void*" }, handlers.ChangeCash,
			self:MakePreCallback(self.OnFakeCashPre), nil
		)
	end)

	if (not ok) then
		self.m_error        = tostring(err)
		self.m_hooks_failed = installing
		log.fwarning("[FreeShopping]: %s", self.m_error)
		return false
	end

	self.m_hooks_installed = true
	self.m_error          = nil
	return true
end

---@param enabled boolean
---@return boolean
function FreeShopping:SetEnabled(enabled)
	if (not enabled) then
		self.m_enabled = false
		return true
	end

	if (not self:CanAccess() or self.m_hooks_failed or not self:Initialize()) then
		return false
	end

	self.m_enabled = true
	return true
end

---@private
---@param ctx ScrNativeCallContext
---@return boolean
function FreeShopping:OnBasketStartPre(ctx)
	self.m_current_category = ctx:GetArgHash(1)
	self.m_current_action   = ctx:GetArgHash(2)
	return true
end

---@private
---@param item NetShoppingBasketItem
function FreeShopping:ReplaceProperty(item)
	local catalog = NetCatalog(GPointers.NetCatalog)
	if (not catalog:IsValid() or catalog:GetBucketCount() == 0) then return end
	if (catalog.m_bucket_array:deref():is_null()) then return end

	local stat_value = -1
	local item_hash  = item:GetItemHash()
	for _, node in catalog:Iter() do
		local entry = node:GetItem()
		if (entry and entry:GetHash() == item_hash and entry:GetStatValue() ~= -1) then
			stat_value = entry:GetStatValue()
			break
		end
	end
	if (stat_value < 0) then return end

	local best_hash, best_price = 0, 0x7FFFFFFF
	for _, node in catalog:Iter() do
		local entry = node:GetItem()
		if (entry and entry:GetStatValue() == stat_value) then
			local price = entry:GetPrice()
			if (price >= 0 and price < best_price) then
				best_hash, best_price = entry:GetHash(), price
			end
		end
	end

	if (best_hash ~= 0) then
		item:SetItemHash(best_hash)
		item:SetPrice(best_price)
	end
end

---@private
---@param ctx ScrNativeCallContext
---@return boolean
function FreeShopping:OnBasketAddPre(ctx)
	if (not self:IsEnabled()) then return true end
	local ptr = ctx:GetArgPointer(0)
	if (ptr:is_null()) then return true end

	local item  = NetShoppingBasketItem(ptr)
	local price = item:GetPrice()
	if (self.m_property_actions[self.m_current_action] and price > 0) then
		self:ReplaceProperty(item)
		return true
	end

	if (self.m_modifiers[item:GetKey()]) then
		ctx:SetReturnInt(1)
		return false
	end

	if (price > 0) then
		local quantity = ctx:GetArgInt(1)
		local coupon_ptr = malloc(0x20)
		assert(coupon_ptr:is_valid(), "Could not allocate coupon")
		local coupon = NetShoppingBasketItem(coupon_ptr)
		self.m_pending[ctx:GetAddress()] = {
			coupon = coupon, source = item, quantity = quantity, pointer = coupon_ptr,
		}
		coupon:SetKey(self.m_coupon_hash)
		coupon:SetItemHash(item:GetKey())
		coupon:SetPrice(0)
		coupon:SetStatValue(item:GetStatValue())
		item:SetPrice(0)
	end
	return true
end

---@private
---@param ctx ScrNativeCallContext
function FreeShopping:OnBasketAddPost(ctx)
	local address = ctx:GetAddress()
	local pending = self.m_pending[address]
	self.m_pending[address] = nil
	if (not pending) then return end

	local ok, err = pcall(function()
		if (ctx:GetReturnInt() == 0) then return end
		pending.coupon:SetStatValue(pending.source:GetStatValue())
		-- Bypass the hooked native handler to avoid reentering its callback mutex.
		local result = GPointers.DynamicFuncs.BasketAddItem(pending.pointer:get_address(), pending.quantity)
		ctx:SetReturnInt(result and result ~= 0 and 1 or 0)
	end)
	free(pending.pointer)
	if (not ok) then error(err, 0) end
end

---@private
---@return boolean
function FreeShopping:OnFakeCashPre()
	return not self:IsEnabled()
end

---@private
function FreeShopping:ResetBasket()
	self.m_current_action   = 0
	self.m_current_category = 0
	for address, pending in pairs(self.m_pending) do
		free(pending.pointer)
		self.m_pending[address] = nil
	end
end

function FreeShopping:Cleanup()
	self.m_enabled = false
	self:ResetBasket()
end

return FreeShopping:init()
