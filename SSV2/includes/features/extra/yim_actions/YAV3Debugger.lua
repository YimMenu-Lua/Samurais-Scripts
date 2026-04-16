-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local COL_YELLOW <const> = Color("yellow")

---@class DebugActor
---@field handle handle
---@field props array<handle>?
---@field ptfx array<handle>?
---@field sfx array<handle>?
---@field isLocalPlayer boolean
---@field name string


---@class YimActionsDebugger
---@field protected m_owner_ref YimActions
---@field private m_prop_mgr PropManager
---@field private m_fx_mgr FXManager
---@field private m_prop_index integer
---@field private m_selected_actor? DebugActor
---@field private m_selected_prop? { handle: handle, attached: boolean, type: string }
---@field m_data { m_current_actions: table<handle, Action>, m_props: table<handle, AnimProps|AnimPropPeds>, m_ptfx: table<handle, AnimPTFX>, m_sfx: table<handle, AnimSFX>, m_actors: table<handle, DebugActor> }
local YimActionsDebugger <const> = {}
YimActionsDebugger.__index = YimActionsDebugger

---@param yim_actions_inst YimActions
---@return YimActionsDebugger
function YimActionsDebugger.new(yim_actions_inst)
	return setmetatable({
		m_owner_ref   = yim_actions_inst,
		m_prop_index  = 1,
		m_actor_index = 1,
		m_prop_mgr    = yim_actions_inst:GetPropManager(),
		m_fx_mgr      = yim_actions_inst:GetFxManager(),
		m_data        = {
			m_current_actions = {},
			m_props           = {},
			m_ptfx            = {},
			m_sfx             = {},
			m_actors          = {},
		}
	}, YimActionsDebugger)
end

---@param ped integer
function YimActionsDebugger:Update(ped)
	ThreadManager:Run(function()
		local YAV3                    = self.m_owner_ref
		local propMgr                 = self.m_prop_mgr
		local fxMgr                   = self.m_fx_mgr
		self.m_data.m_current_actions = YAV3.CurrentlyPlaying
		self.m_data.m_props           = propMgr:GetProps()
		self.m_data.m_ptfx            = fxMgr:GetFX()

		if (not self.m_data.m_actors[ped]) then
			local isLocalPlayer = (ped == LocalPlayer:GetHandle())
			self.m_data.m_actors[ped] = {
				handle        = ped,
				props         = propMgr:GetPropsForPed(ped),
				ptfx          = fxMgr:GetFXForPed(ped),
				sfx           = {},
				isLocalPlayer = isLocalPlayer,
				-- name          = isLocalPlayer and "You" or Game.GetPedModelName(Game.GetEntityModel(ped))
				name          = Game.GetPedModelName(Game.GetEntityModel(ped))
			}
		end
	end)
end

---@param ped handle
function YimActionsDebugger:Remove(ped)
	self.m_data.m_actors[ped] = nil
end

---@return number
function YimActionsDebugger:GetActionCount()
	return table.getlen(self.m_owner_ref.CurrentlyPlaying)
end

---@return number
function YimActionsDebugger:GetPropCount()
	return table.getlen(self.m_prop_mgr:GetProps())
end

---@return number
function YimActionsDebugger:GetFxCount()
	return table.getlen(self.m_fx_mgr:GetFX())
end

function YimActionsDebugger:Draw()
	local YAV3 = self.m_owner_ref
	if (ImGui.SmallButton("!Summon Wompus")) then
		YAV3.CompanionManager:FulfillTheProphecy()
	end

	ImGui.Spacing()
	ImGui.SeparatorText("Global Data")
	ImGui.BulletText(_F("Active Actions: [ %d ]", self:GetActionCount()))
	ImGui.BulletText(_F("Active Props: [ %d ]", self:GetPropCount()))
	ImGui.BulletText(_F("Active FX: [ %d ]", self:GetFxCount()))

	ImGui.Spacing()
	ImGui.Spacing()
	ImGui.SeparatorText("Actors")
	if (not self.m_data.m_actors or next(self.m_data.m_actors) == nil) then
		ImGui.Text("None.")
	else
		local comboPreview = self.m_selected_actor and self.m_selected_actor.name or "Actors"
		ImGui.SetNextItemWidth(200)
		if (ImGui.BeginCombo("##debugActors", comboPreview)) then
			for _, actor in pairs(self.m_data.m_actors) do
				if (ImGui.Selectable(actor.name, (actor == self.m_selected_actor))) then
					self.m_selected_actor = actor
				end
			end
			ImGui.EndCombo()
		end

		if (not self.m_selected_actor) then return end

		local action = YAV3.CurrentlyPlaying[self.m_selected_actor.handle]
		ImGui.BulletText(_F("Current Actor: [ %s ]", self.m_selected_actor.name))
		ImGui.BulletText(_F("Is Player: [ %s ]", self.m_selected_actor.isLocalPlayer))

		if (action) then
			ImGui.BulletText("Current Action:")
			ImGui.Indent()
			ImGui.Text(
				_F(
					"- Label: %s\n- Type: [ %s ]",
					action.data.label or "N/A",
					action:TypeAsString()
				)
			)
			ImGui.Unindent()
			ImGui.Dummy(1, 10)
		end

		if (not self.m_selected_actor.props or #self.m_selected_actor.props == 0) then
			return
		end

		ImGui.BeginGroup()
		ImGui.BeginChildEx("##debugProplist",
			vec2:new(200, 200),
			ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding
		)
		ImGui.SeparatorText("Props")
		for i, propHandle in ipairs(self.m_selected_actor.props) do
			if (ImGui.Selectable(tostring(propHandle), (self.m_prop_index == i))) then
				self.m_prop_index = i
			end

			if (ImGui.IsItemClicked(0)) then
				ThreadManager:Run(function()
					self.m_selected_prop = {
						handle   = propHandle,
						attached = ENTITY.IS_ENTITY_ATTACHED(propHandle),
						type     = Game.GetEntityTypeString(propHandle)
					}
				end)
			end
		end
		ImGui.EndChild()

		ImGui.SameLine()
		ImGui.SetNextWindowBgAlpha(0.0)
		ImGui.BeginChild("##debugPropInfo", 250, 200)
		ImGui.SeparatorText("Prop Info")
		if (not self.m_selected_prop) then
			GUI:Text("Not Selected.", { color = COL_YELLOW })
		else
			ImGui.BulletText(_F("Prop Type: [ %s ]", self.m_selected_prop.type))
			ImGui.BulletText(_F("Is Attached: [ %s ]", self.m_selected_prop.attached))
		end
		ImGui.EndChild()
		ImGui.EndGroup()

		if (GUI:Button("Remove Props")) then
			ThreadManager:Run(function()
				self.m_prop_mgr:Cleanup(self.m_selected_actor.handle)
			end)
		end

		ImGui.SameLine()

		if (GUI:Button("Stop FX")) then
			ThreadManager:Run(function()
				self.m_fx_mgr:StopPTFX(self.m_selected_actor.handle)
			end)
		end

		ImGui.SameLine()

		if (GUI:Button("Reset")) then
			ThreadManager:Run(function()
				TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.m_selected_actor.handle)
			end)
		end

		if (GUI:Button("Wipe")) then
			ThreadManager:Run(function()
				self.m_owner_ref:ForceCleanup()
			end)
		end
	end
end

return YimActionsDebugger
