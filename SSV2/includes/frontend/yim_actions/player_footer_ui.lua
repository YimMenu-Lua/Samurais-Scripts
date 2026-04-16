-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local YimActions          = require("includes.features.extra.yim_actions.YimActionsV3")
local measureLabelWidth   = require("includes.frontend.helpers.measure_text_width")
local footerLabelWidths   = {}
local t_AnimFlags <const> = {
	looped = {
		label      = "YAV3_FLAGS_LOOPING",
		bit        = Enums.eAnimFlags.LOOPING,
		enabled    = false,
		wasClicked = false,
	},
	upperbody = {
		label      = "YAV3_FLAGS_UPPERBODY",
		bit        = Enums.eAnimFlags.UPPERBODY,
		enabled    = false,
		wasClicked = false,
	},
	secondary = {
		label      = "YAV3_FLAGS_SECONDARY",
		bit        = Enums.eAnimFlags.SECONDARY,
		enabled    = false,
		wasClicked = false,
	},
	hideWeapon = {
		label      = "YAV3_FLAGS_HIDE_WEAPON",
		bit        = Enums.eAnimFlags.HIDE_WEAPON,
		enabled    = false,
		wasClicked = false,
	},
	endsInDeath = {
		label      = "YAV3_FLAGS_ENDS_IN_DEAD_POSE",
		bit        = Enums.eAnimFlags.ENDS_IN_DEAD_POSE,
		enabled    = false,
		wasClicked = false,
	},
	holdLastFrame = {
		label      = "YAV3_FLAGS_HOLD_LAST_FRAME",
		bit        = Enums.eAnimFlags.HOLD_LAST_FRAME,
		enabled    = false,
		wasClicked = false,
	},
	uninterruptable = {
		label      = "YAV3_FLAGS_NOT_INTERRUPTABLE",
		bit        = Enums.eAnimFlags.NOT_INTERRUPTABLE,
		enabled    = false,
		wasClicked = false,
	},
	additive = {
		label      = "YAV3_FLAGS_ADDITIVE",
		bit        = Enums.eAnimFlags.ADDITIVE,
		enabled    = false,
		wasClicked = false,
	},
	nocollision = {
		label      = "YAV3_FLAGS_TURN_OFF_COLLISION",
		bit        = Enums.eAnimFlags.TURN_OFF_COLLISION,
		enabled    = false,
		wasClicked = false,
	},
	forceStart = {
		label      = "YAV3_FLAGS_FORCE_START",
		bit        = Enums.eAnimFlags.FORCE_START,
		enabled    = false,
		wasClicked = false,
	},
	processAttachments = {
		label      = "YAV3_FLAGS_PROCESS_ATTACHMENTS",
		bit        = Enums.eAnimFlags.PROCESS_ATTACHMENTS_ON_START,
		enabled    = false,
		wasClicked = false,
	},
	alternateFpAnim = {
		label      = "YAV3_FLAGS_ALTERNATIVE_FP_ANIM",
		bit        = Enums.eAnimFlags.USE_ALTERNATIVE_FP_ANIM,
		enabled    = false,
		wasClicked = false,
	},
	useFullBlending = {
		label      = "YAV3_FLAGS_USE_FULL_BLENDING",
		bit        = Enums.eAnimFlags.USE_FULL_BLENDING,
		enabled    = false,
		wasClicked = false,
	},
}

---@type dict<eAnimFlags>
local t_DefaultFlags      = {}

---@param selectedAction? Action
local function DrawAnimOptions(selectedAction)
	if (not selectedAction or selectedAction.action_type ~= Enums.eActionType.ANIM) then
		return
	end

	local opts_lbl          = _T("GENERIC_OPTIONS_LABEL")
	local opts_lbl_width    = ImGui.CalcTextSize(opts_lbl) + 20
	local style             = ImGui.GetStyle()
	local opts_button_width = opts_lbl_width + style.FramePadding.x

	ImGui.SameLine()
	ImGui.SetCursorPosX(ImGui.GetCursorPosX() + ImGui.GetContentRegionAvail() - opts_button_width)

	ImGui.BeginDisabled(not selectedAction)
	if (GUI:Button(_T("GENERIC_OPTIONS_LABEL"), { size = vec2:new(opts_lbl_width, 35) })) then
		if (not t_DefaultFlags[selectedAction.data.label]) then
			t_DefaultFlags[selectedAction.data.label] = selectedAction.data.flags
		end
		ImGui.OpenPopup("##animflags")
	end
	ImGui.EndDisabled()

	if (selectedAction and ImGui.BeginPopupModal("##animflags",
			ImGuiWindowFlags.NoTitleBar
			| ImGuiWindowFlags.AlwaysAutoResize)
		) then
		GUI:QuickConfigWindow(opts_lbl, function()
			ImGui.SetNextWindowBgAlpha(0)
			ImGui.BeginChild("##flagsChild", 500, 400)

			ImGui.SeparatorText(_T("GENERIC_GENERAL_LABEL"))
			GVars.features.yim_actions.disable_props = GUI:CustomToggle(_T("YAV3_DISABLE_PROPS"),
				GVars.features.yim_actions.disable_props
			)

			GVars.features.yim_actions.disable_ptfx = GUI:CustomToggle(_T("YAV3_DISABLE_PTFX"),
				GVars.features.yim_actions.disable_ptfx
			)

			GVars.features.yim_actions.disable_sfx = GUI:CustomToggle(_T("YAV3_DISABLE_SFX"),
				GVars.features.yim_actions.disable_sfx
			)

			ImGui.Spacing()
			ImGui.SeparatorText(_T("YAV3_ANIM_FLAGS"))

			local defaultFlags = t_DefaultFlags[selectedAction.data.label]
			ImGui.BeginDisabled(not defaultFlags or defaultFlags == selectedAction.data.flags)
			if (GUI:Button(_T("GENERIC_RESET"))) then
				selectedAction.data.flags = defaultFlags
			end
			ImGui.EndDisabled()
			ImGui.Spacing()

			for name, flag in pairs(t_AnimFlags) do
				ImGui.PushID(_F("##flag_%s", name))
				local isEnabled = Bit.IsBitSet(selectedAction.data.flags, flag.bit)
				flag.enabled, flag.wasClicked = ImGui.Checkbox(_T(flag.label), isEnabled)
				ImGui.PopID()

				if (flag.bit == Enums.eAnimFlags.ENDS_IN_DEAD_POSE) then
					GUI:Tooltip(_T("YAV3_FLAGS_DEAD_POSE_LOOPED_TT"))
				end

				if (flag.wasClicked) then
					GUI:PlaySound("Nav")
					selectedAction.data.flags = Bit.Toggle(
						selectedAction.data.flags,
						flag.bit,
						flag.enabled
					)
				end
			end
			ImGui.EndChild()
		end, ImGui.CloseCurrentPopup)
		ImGui.EndPopup()
	end
end

---@param selectedAction? Action
return function(selectedAction)
	ImGui.Separator()
	ImGui.SetNextWindowBgAlpha(0.69)
	ImGui.BeginChildEx("##player_footer",
		vec2:new(0, 65),
		ImGuiChildFlags.Borders | ImGuiChildFlags.AlwaysUseWindowPadding,
		ImGuiWindowFlags.NoScrollbar
	)

	local land_idx    = GVars.backend.language_index
	local label_width = footerLabelWidths[land_idx]
	if (not label_width) then
		label_width = measureLabelWidth({
			_T("GENERIC_PLAY"),
			_T("GENERIC_STOP")
		}, 20)

		footerLabelWidths[land_idx] = label_width
	end

	ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 10, 10)
	ImGui.BeginDisabled(not selectedAction or YimActions:IsPlayerBusy())
	if (ImGui.Button(_T("GENERIC_PLAY"), label_width, 35)) then
		GUI:PlaySound("Select")
		ThreadManager:Run(function()
			---@diagnostic disable-next-line
			YimActions:Play(selectedAction)
		end)
	end
	ImGui.EndDisabled()

	ImGui.SameLine()
	ImGui.Spacing()
	ImGui.SameLine()

	ImGui.BeginDisabled(not YimActions:IsPedPlaying())
	if (ImGui.Button(_T("GENERIC_STOP"), label_width, 35)) then
		GUI:PlaySound("Cancel")
		ThreadManager:Run(function()
			YimActions:Cleanup()
		end)
	end
	ImGui.EndDisabled()

	ImGui.SameLine()
	DrawAnimOptions(selectedAction)

	ImGui.PopStyleVar()
	ImGui.EndChild()
end
