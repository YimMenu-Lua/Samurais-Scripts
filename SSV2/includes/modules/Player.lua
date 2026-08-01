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
--____
-- **IMPORTANT**: Class methods that use player id and ped handle must always use `:GetID()` and `:GetHandle()`
--
-- instead of directly reading cached class members. This is because [LocalPlayer](LocalPlayer.lua) inherits this class and does not
--
-- cache handles or IDs; it always resolves them live.
---@class Player : Ped
---@field private m_internal CPed
---@field private m_handle handle
---@field private m_pid ID PlayerID
---@field public Resolve fun(self: Player) : CPed
---@field public super fun(self: Player): Ped
---@field Create nil
---@field Delete nil
---@field SetAsNoLongerNeeded nil
---@overload fun(p0: ID | handle): Player
Player = Class("Player", { parent = Ped })


Player.Create              = nil
Player.Delete              = nil
Player.SetAsNoLongerNeeded = nil


---@param p0 ID|handle A player ID [0 .. 32] or a ped handle.
---@return Player
function Player.new(p0)
	local ped, pid = 0, 0
	if (math.is_inrange(p0, 0, 31)) then
		pid = p0
		ped = PLAYER.GET_PLAYER_PED(pid)
	elseif (ENTITY.IS_ENTITY_A_PED(p0)) then
		ped = p0
		pid = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(p0)
	else
		error("Invalid parameter! Player class constructor expects either a player ID or a ped handle.")
	end

	local base        = Entity(ped)
	---@diagnostic disable-next-line: param-type-mismatch
	local instance    = setmetatable(base, Player) ---@cast instance Player
	instance.m_pid    = pid
	instance.m_handle = ped
	return instance
end

---@return ID
function Player:GetID()
	return self.m_pid
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

---@return boolean
function Player:IsSessionHost()
	return NETWORK.NETWORK_GET_HOST_PLAYER_INDEX() == self:GetID()
end

---@param scriptName string
---@return boolean
function Player:IsHostOfScript(scriptName)
	if (not script.is_active(scriptName)) then
		return false
	end

	local pid = self:GetID()
	for i = -1, 3 do
		if (NETWORK.NETWORK_GET_HOST_OF_SCRIPT(scriptName, i, 0) == pid) then
			return true
		end
	end

	return false
end

-- ```C
-- BOOL func_25246(Player plParam0) // Position - 0x734BC9 (7556041) (b3889.0)
-- ```
--___
-- not sure if reading the global is cheaper than calling the script function but it would definitely be much batter than global maintenance
---@return boolean
function Player:IsBoss()
	local pid = self:GetID()
	return GGlobals.GPBD_FM_3:At(pid, 615):At(10):ReadInt() == pid
end

-- ```C
-- int func_11637(Player plParam0) // Position - 0x41F6DE (4323038) (b3889.0)
-- ```
---@return eBossType
function Player:GetBossType()
	if (not self:IsBoss()) then
		return Enums.eBossType.NONE
	end

	return GGlobals.GPBD_FM_3:At(self:GetID(), 615):At(10):At(433):ReadInt()
end

---@return -1|ID -- PlayerID or -1
function Player:GetBossOfPlayer()
	local pid     = self:GetID()
	local boss_id = GGlobals.GPBD_FM_3:At(pid, 615):At(10):ReadInt()
	if (boss_id == pid) then -- we're our own boss. we don't call IsBoss here to avoid calling GetID and reading GPBD_FM_3 all over again
		return -1
	end

	return GGlobals.GPBD_FM_3:At(boss_id, 615):At(10):ReadInt()
end

---@return boolean
function Player:IsAssociate()
	local id = self:GetBossOfPlayer()
	return id ~= -1 and id ~= self:GetID()
end

---@return eBossType
function Player:GetAssociateType()
	local boss_id = self:GetBossOfPlayer()
	if (boss_id == -1 or boss_id == self:GetID()) then
		return Enums.eBossType.NONE
	end

	return GGlobals.GPBD_FM_3:At(boss_id, 615):At(10):At(433):ReadInt()
end

---@return eGameState
function Player:GetGameState()
	return self:Resolve().m_player_info:GetGameState()
end

---@return string
function Player:GetName()
	return self:Resolve().m_player_info:GetPlayerName()
end

---@return IPV4?
function Player:GetInternalIP()
	return self:Resolve().m_player_info:GetInternalIP()
end

---@return IPV4?
function Player:GetExternalIP()
	return self:Resolve().m_player_info:GetExternalIP()
end

---@return boolean
function Player:HasControl()
	return PLAYER.IS_PLAYER_CONTROL_ON(self:GetID())
end
