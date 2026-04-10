-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- Thanks to [Lucas7yoshi](https://rage.re/u/Lucas7yoshi) for the detailed explanation on network scenes: https://rage.re/t/network-synchronized-scenes/305

-- Unfinished. Probably never will be.
---@class SynchronisedScene
---@field label string
---@field netHandle handle Network handle
---@field localHandle handle
---@field animDict string
---@field origin { handle: handle, pos_offset: vec3 } Entity the scene will orient towards (ped, object)
---@field participants array<SceneParticipant> List of entities participating in the scene
---@field params { looped: boolean, holdLastFrame: boolean, startPhase: float, animSpeed: float }
local SynchronisedScene = {}
SynchronisedScene.__index = SynchronisedScene

---@param label string
---@param dict string Animation dictionnary
---@param origin { handle: handle, pos_offset: vec3 } Entity the scene will orient towards (ped, object)
---@param participants array<SceneParticipant> List of entities participating in the scene
---@param params { looped: boolean, holdLastFrame: boolean, startPhase: float, animSpeed: float }
---@return SynchronisedScene
function SynchronisedScene.new(label, dict, origin, participants, params)
	return setmetatable({
		label        = label,
		animDict     = dict,
		origin       = origin,
		participants = participants,
		params       = params,
	}, SynchronisedScene)
end

---@return boolean
function SynchronisedScene:IsRunning()
	if (not self.localHandle or self.localHandle == -1) then
		return false
	end

	return PED.IS_SYNCHRONIZED_SCENE_RUNNING(self.localHandle)
end

return SynchronisedScene
