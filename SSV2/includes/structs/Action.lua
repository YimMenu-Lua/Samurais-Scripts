-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local ActionTypeToString <const> = {
	[Enums.eActionType.UNK]      = "Unknown",
	[Enums.eActionType.ANIM]     = "Animation",
	[Enums.eActionType.SCENARIO] = "Scenario",
	[Enums.eActionType.SCENE]    = "Synchronized Scene",
	[Enums.eActionType.CLIPSET]  = "Movement Clipset"
}

-----------------------------------------------------
-- Action Struct
-----------------------------------------------------
-- A playable action (animation, scenario, synchronized scene).
---@class Action
---@field data ActionData
---@field action_type eActionType
---@field default_flags eAnimFlags
local Action = {}
Action.__index = Action

---@param action_data ActionData
---@param action_type eActionType
---@return Action
function Action.new(action_data, action_type)
	local instance = setmetatable({
		action_type = action_type,
		data = action_data
	}, Action)

	if (action_type == Enums.eActionType.ANIM) then
		-- track default hardcoded flags for later. -- nvm this is broken. -- 17/12/25: wtf was-I trying to do with this?
		instance.default_flags = action_data and action_data.flags or 0
	end

	return instance
end

---@return string
function Action:TypeAsString()
	return ActionTypeToString[self.action_type]
end

return Action
