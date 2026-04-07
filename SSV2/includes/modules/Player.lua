-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


--------------------------------------
-- Class: Player
--------------------------------------
-- **Global.**
--
-- **Parent:** `Ped`.
--
-- Class representing a GTA V player (Unfinished).
---@class Player : Ped
---@field private m_internal CPed
---@field private m_handle handle
---@field private m_pid ID PlayerID
---@field public Resolve fun(self: Player) : CPed
---@field public super fun(self: Player): Ped
---@overload fun(p0: ID | handle): Player
Player = Class("Player", { parent = Ped })


---@override
Player.Create              = nil
---@override
Player.Delete              = nil
---@override
Player.SetAsNoLongerNeeded = nil


---@param p0 ID|handle A player ID [0 .. 32] or a ped handle.
---@return Player
function Player.new(p0)
	local ped, pid = 0, 0
	if (math.is_inrange(p0, 0, 31)) then
		pid = p0
		ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
	elseif (Game.IsScriptHandle(p0)) then
		ped = p0
		pid = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(p0)
	else
		error("Invalid parameter. Function expects a player ID or a ped handle.")
	end

	if (not PED.IS_PED_A_PLAYER(ped)) then
		error("Attempt to create a Player instance from an NPC.")
	end

	return setmetatable({
		m_pid    = pid,
		m_handle = ped,
		---@diagnostic disable-next-line: param-type-mismatch
	}, Player)
end

---@return boolean
function Player:IsValid()
	if (self == LocalPlayer) then return true end
	return self:Exists() and PED.IS_PED_A_PLAYER(self:GetHandle())
end

-- Returns whether the player is currently playing.
---@return boolean
function Player:IsPlaying()
	local state = self:GetGameState()
	return (state ~= Enums.eGameState.Invalid and state ~= Enums.eGameState.LeftGame)
end

---@return boolean
function Player:IsMale()
	return self:GetModelHash() == 0x705E61F2
end

---@param scriptName string
---@return boolean
function Player:IsHostOfScript(scriptName)
	local pid = self:GetID()
	for i = -1, 3 do
		if (NETWORK.NETWORK_GET_HOST_OF_SCRIPT(scriptName, i, 0) == pid) then
			return true
		end
	end

	return false
end

---@return ID
function Player:GetID()
	return self.m_pid
end

---@return eGameState
function Player:GetGameState()
	return self:Resolve().m_player_info:GetGameState()
end

---@return string
function Player:GetName()
	return self:Resolve().m_player_info:GetPlayerName()
end

---@return IPAddress?
function Player:GetInternalIP()
	return self:Resolve().m_player_info:GetInternalIP()
end

---@return IPAddress?
function Player:GetExternalIP()
	return self:Resolve().m_player_info:GetExternalIP()
end

-- [WIP]
