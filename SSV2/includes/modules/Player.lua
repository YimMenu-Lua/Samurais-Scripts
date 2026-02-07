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
---@field private m_pid integer PlayerID
---@field Resolve fun() : CPed
---@overload fun(pid: integer): Player
Player = Class("Player", Ped)
Player.Create = nil
Player.Delete = nil
Player.SetAsNoLongerNeeded = nil

-- Constructor
---@param player_id integer
---@return Player
function Player.new(player_id)
	assert(math.is_inrange(player_id, 0, 32), "Invalid player ID")

	local ped_handle = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
	---@type Player
	local instance = setmetatable({
		m_pid = player_id,
		m_handle = ped_handle,
		---@diagnostic disable-next-line: param-type-mismatch
	}, Player)

	instance.m_internal = instance:Resolve()
	return instance
end

---@return eGameState
function Player:GetGameState()
	if (not self:IsValid()) then
		return Enums.eGameState.Invalid
	end

	local cplayerinfo = self:Resolve().m_player_info
	if (not cplayerinfo or not cplayerinfo:IsValid()) then
		return Enums.eGameState.Invalid
	end

	return cplayerinfo:GetGameState()
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
	return (NETWORK.NETWORK_GET_HOST_OF_SCRIPT(scriptName, -1, 0) == self.m_pid)
		or (NETWORK.NETWORK_GET_HOST_OF_SCRIPT(scriptName, 0, 0) == self.m_pid)
		or (NETWORK.NETWORK_GET_HOST_OF_SCRIPT(scriptName, 1, 0) == self.m_pid)
		or (NETWORK.NETWORK_GET_HOST_OF_SCRIPT(scriptName, 2, 0) == self.m_pid)
		or (NETWORK.NETWORK_GET_HOST_OF_SCRIPT(scriptName, 3, 0) == self.m_pid)
end

-- [WIP]
