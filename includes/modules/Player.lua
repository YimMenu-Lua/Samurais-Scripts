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
    assert(math.inrange(player_id, 0, 32), "Invalid player ID")

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
        return eGameState.Invalid
    end

    local cplayerinfo = self:Resolve().m_player_info
    if (not cplayerinfo or not cplayerinfo:IsValid()) then
        return eGameState.Invalid
    end

    return cplayerinfo:GetGameState()
end

-- Returns whether the player is currently playing.
---@return boolean
function Player:IsPlaying()
    local state = self:GetGameState()
    return (state ~= eGameState.Invalid and state ~= eGameState.LeftGame)
end

-- [WIP]
