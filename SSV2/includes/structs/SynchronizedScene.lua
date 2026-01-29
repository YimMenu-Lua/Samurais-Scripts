-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- Thanks to [Lucas7yoshi](https://rage.re/u/Lucas7yoshi) for the detailed explanation on network scenes: https://rage.re/t/network-synchronized-scenes/305

-- Unfinished. Probably never will be.
---@class Scene
---@field label string
---@field netHandle handle Network handle
---@field localHandle handle Script handle
---@field animDict string
---@field origin { handle: handle, pos_offset: vec3 } Entity the scene will orient towards (ped, object)
---@field participants array<SceneParticipant> List of entities participating in the scene
---@field params { looped: boolean, holdLastFrame: boolean, startPhase?: float, animSpeed?: float }
local SynchronisedScene = {}
SynchronisedScene.__index = SynchronisedScene

---@param s_Label string
---@param s_AnimDict string
---@param origin table
---@param t_Participants table
---@param t_Params? table
function SynchronisedScene.new(
	s_Label,
	s_AnimDict,
	origin,
	t_Participants,
	t_Params
)
	local instance = setmetatable({}, SynchronisedScene)
	instance.label = s_Label
	instance.animDict = s_AnimDict
	instance.origin = origin
	instance.participants = t_Participants
	instance.params = t_Params or {}

	return instance
end

function SynchronisedScene:IsRunning()
	if (not self.localHandle or self.localHandle == -1) then
		return false
	end

	return PED.IS_SYNCHRONIZED_SCENE_RUNNING(self.localHandle)
end

return SynchronisedScene
