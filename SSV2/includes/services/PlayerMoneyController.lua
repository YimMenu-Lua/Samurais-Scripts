-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class PlayerMoneyController
---@field private m_bank_balance integer
---@field private m_wallet_balance integer
---@field private m_total_balance integer
---@field private m_last_tick TimePoint
---@field protected m_use_transaction_system boolean
---@field private m_bank_fmt string
---@field private m_wallet_fmt string
---@field private m_total_fmt string
local PlayerMoneyController <const> = {}
PlayerMoneyController.__index = PlayerMoneyController

---@return PlayerMoneyController
function PlayerMoneyController.new()
	return setmetatable({
		m_bank_balance           = 0,
		m_wallet_balance         = 0,
		m_total_balance          = 0,
		m_bank_fmt               = "$0",
		m_wallet_fmt             = "$0",
		m_total_fmt              = "$0",
		m_last_tick              = TimePoint.new(),
		m_use_transaction_system = not Game.IsFSL(),
	}, PlayerMoneyController)
end

function PlayerMoneyController:Reset()
	self.m_bank_balance   = 0
	self.m_wallet_balance = 0
	self.m_total_balance  = 0
	self.m_bank_fmt       = "$0"
	self.m_wallet_fmt     = "$0"
	self.m_total_fmt      = "$0"
	self.m_last_tick:Reset()
end

---@return integer
function PlayerMoneyController:GetWalletBalance()
	return self.m_wallet_balance
end

---@return string
function PlayerMoneyController:GetWalletBalanceFmt()
	return self.m_wallet_fmt
end

---@return integer
function PlayerMoneyController:GetBankBalance()
	return self.m_bank_balance
end

---@return string
function PlayerMoneyController:GetBankBalanceFmt()
	return self.m_bank_fmt
end

---@return integer
function PlayerMoneyController:GetTotalBalance()
	return self.m_total_balance
end

---@return string
function PlayerMoneyController:GetTotalBalanceFmt()
	return self.m_total_fmt
end

---@private
---@nodiscard
---@param amount integer
---@param operation 0|1 -- 0: Withdraw | 1: Deposit
---@return boolean
function PlayerMoneyController:UseTransactionSystem(amount, operation)
	if (NETSHOPPING.NET_GAMESERVER_TRANSACTION_IN_PROGRESS()) then
		log.warning("Another transaction is in progress.")
		return false
	end

	local success, p0, p1 = false, 0, false
	success, p0, p1 = NETSHOPPING.NET_GAMESERVER_GET_SESSION_STATE_AND_STATUS(p0, p1)
	if (not success or p0 ~= 8) then
		log.warning("Transaction failed!")
		return false
	end

	local tansferFunc = (operation == 0) and NETSHOPPING.NET_GAMESERVER_TRANSFER_BANK_TO_WALLET or NETSHOPPING.NET_GAMESERVER_TRANSFER_WALLET_TO_BANK
	local statusFunc  = (operation == 0) and NETSHOPPING.NET_GAMESERVER_TRANSFER_BANK_TO_WALLET_GET_STATUS or NETSHOPPING.NET_GAMESERVER_TRANSFER_WALLET_TO_BANK_GET_STATUS

	if (not tansferFunc(stats.get_character_index(), amount)) then
		log.warning("Transaction failed!")
		return false
	end

	local status = statusFunc()
	while (status == 1) do
		status = statusFunc()
		yield()
	end

	if (status ~= 3) then
		log.warning("Transaction failed!")
		return false
	end

	return NETSHOPPING.NET_GAMESERVER_TRANSFER_CASH_SET_TELEMETRY_NONCE_SEED()
end

---@param amount integer
function PlayerMoneyController:Withdraw(amount)
	if (NETWORK.NETWORK_IS_ACTIVITY_SESSION()) then
		log.warning("Monetary operations are not available in activity sessions.")
		return
	end

	amount = math.clamp(amount, 0, self.m_bank_balance)
	if (self.m_use_transaction_system and not self:UseTransactionSystem(amount, 0)) then
		return
	end

	MONEY.WITHDRAW_VC(amount)
end

---@param amount integer
function PlayerMoneyController:Deposit(amount)
	if (NETWORK.NETWORK_IS_ACTIVITY_SESSION()) then
		log.warning("Monetary operations are not available in activity sessions.")
		return
	end

	amount = math.clamp(amount, 0, self.m_wallet_balance)
	if (self.m_use_transaction_system and not self:UseTransactionSystem(amount, 1)) then
		return
	end

	MONEY.DEPOSIT_VC(amount)
end

function PlayerMoneyController:Update()
	if (not self.m_last_tick:HasElapsed(1000)) then
		return
	end

	local bank            = MONEY.NETWORK_GET_VC_BANK_BALANCE()
	local wallet          = MONEY.NETWORK_GET_VC_WALLET_BALANCE(stats.get_character_index())
	local total           = bank + wallet
	self.m_bank_balance   = bank
	self.m_wallet_balance = wallet
	self.m_total_balance  = total
	self.m_bank_fmt       = string.formatmoney(bank)
	self.m_wallet_fmt     = string.formatmoney(wallet)
	self.m_total_fmt      = string.formatmoney(total)

	self.m_last_tick:Reset()
end

return PlayerMoneyController
