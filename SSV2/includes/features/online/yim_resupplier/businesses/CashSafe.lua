-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class CashSafeOpts
---@field name string
---@field get_max_cash fun(): integer
---@field cash_value_stat string
---@field paytime_stat? string
---@field interior_id? integer
---@field room_hash? joaat_t
---@field coords? vec3

-- Class representing a Business Safe that stores cash
---@class CashSafe
---@field private m_name string
---@field private m_max_cash integer
---@field private m_cash_stat string
---@field private m_paytime_stat? string
---@field private m_coords? vec3
---@field private m_interior_id? integer
---@field private m_room_hash joaat_t
---@field private m_cash_loop_running boolean
---@field private m_last_loop_time seconds
---@field public cash_loop_enabled boolean
local CashSafe   = {}
CashSafe.__index = CashSafe

---@param opts CashSafeOpts
---@return CashSafe
function CashSafe.new(opts)
	assert(type(opts.get_max_cash) == "function", "Missing argument: get_max_cash<function>")
	assert(type(opts.cash_value_stat) == "string", "Missing argument: cash_value_stat<string>")

	local instance = setmetatable({
		m_cash_stat    = opts.cash_value_stat,
		m_max_cash     = opts.get_max_cash(),
		m_name         = opts.name or "NULL",
		m_paytime_stat = opts.paytime_stat,
		m_interior_id  = opts.interior_id,
		m_room_hash    = opts.room_hash
	}, CashSafe)

	if (opts.coords) then
		instance.m_coords = opts.coords
	end

	return instance
end

---@return boolean
function CashSafe:IsFull()
	-- le because some people like to break their safes and go over the max
	return self.m_max_cash <= self:GetCashValue()
end

---@return boolean
function CashSafe:IsPlayerNearby()
	if (not self.m_interior_id or not self.m_room_hash) then
		return false
	end

	local interior = LocalPlayer:GetInterior()
	if (interior == 0) then
		return false
	end

	return interior == self.m_interior_id and LocalPlayer:GetRoomHash() == self.m_room_hash
end

---@return boolean
function CashSafe:CanLoop()
	return type(self.m_paytime_stat) == "string"
end

---@return string
function CashSafe:GetName()
	return self.m_name
end

---@return vec3?
function CashSafe:GetCoords()
	return self.m_coords
end

---@return integer
function CashSafe:GetCashValue()
	assert(type(self.m_cash_stat) == "string", "Invalid player stat.")
	return stats.get_int(self.m_cash_stat)
end

---@return integer
function CashSafe:GetCapacity()
	return self.m_max_cash
end

---@return milliseconds
function CashSafe:GetPaytimeLeft()
	if (not self.m_paytime_stat) then
		return -1
	end

	return stats.get_int(self.m_paytime_stat)
end

function CashSafe:SetPaytimeLeft()
	if (not self.m_paytime_stat) then
		return
	end

	stats.set_int(self.m_paytime_stat, 100)
end

function CashSafe:Update()
	if (not self.cash_loop_enabled or self.m_cash_loop_running) then
		return
	end

	if (not GVars.features.yrv3.safe_loop_warn_ack) then
		self.cash_loop_enabled   = false
		self.m_cash_loop_running = false
		return
	end

	if (not self:CanLoop()) then
		self.cash_loop_enabled   = false
		self.m_cash_loop_running = false
		return
	end

	if (self:IsFull() and not self:IsPlayerNearby()) then
		self.cash_loop_enabled   = false
		self.m_cash_loop_running = false
		return
	end

	self.m_cash_loop_running = true
	ThreadManager:Run(function()
		local currentSafeCash = self:GetCashValue()
		local capacity        = self:GetCapacity()
		local lastBalance     = LocalPlayer:GetTotalBalance()
		local collected       = false

		while (self.cash_loop_enabled) do
			if (not GVars.features.yrv3.safe_loop_warn_ack) then
				break
			end

			if (not self:IsFull()) then
				if (self:GetPaytimeLeft() >= 100 and not collected) then
					self:SetPaytimeLeft()
				end

				if (currentSafeCash == self:GetCashValue()) then
					repeat
						yield()
					until self:GetCashValue() ~= currentSafeCash
						or self:IsFull()
						or not self:IsPlayerNearby()
						or not self.cash_loop_enabled

					currentSafeCash = self:GetCashValue()
				end
			end

			if (self:IsFull() and not self:IsPlayerNearby()) then
				-- you don't have to worry about forgetting to disable the loop
				-- it will disable itself as soon as you leave the room where the safe is.
				break
			end

			if (LocalPlayer:GetTotalBalance() - lastBalance >= capacity) then
				collected = true
				sleep(5000)
				lastBalance = LocalPlayer:GetTotalBalance()
				collected   = false
			end

			yield()
		end

		self.cash_loop_enabled   = false
		self.m_cash_loop_running = false
	end)
end

return CashSafe
