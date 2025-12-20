local self_tab = GUI:RegisterNewTab(eTabID.TAB_SELF, "Self")

local function CheckIfRagdollBlocked()
	ThreadManager:Run(function()
		if (not PED.CAN_PED_RAGDOLL(Self:GetHandle())) then
			Toast:ShowWarning(
				"Samurais Scripts",
				_T("SELF_RAGDOLL_BLOCK_INFO")
			)
		end
	end)
end

self_tab:AddBoolCommand("SELF_AUTOHEAL",
	"features.self.autoheal.enabled",
	nil,
	nil,
	{ description = "SELF_AUTOHEAL_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_PHONE_ANIMS",
	"features.self.phone_anims",
	nil,
	nil,
	{ description = "SELF_PHONE_ANIMS_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_ACTION_MODE",
	"features.self.disable_action_mode",
	nil,
	nil,
	{ description = "SELF_ACTION_MODE_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_HEADPROPS",
	"features.self.allow_headprops_in_vehicles",
	nil,
	nil,
	{ description = "SELF_HEADPROPS_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_STAND_ON_VEHS",
	"features.self.stand_on_veh_roof",
	nil,
	nil,
	{ description = "SELF_STAND_ON_VEHS_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_NO_CARJACKING",
	"features.self.no_carjacking",
	nil,
	nil,
	{ description = "SELF_NO_CARJACKING_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_CROUCH",
	"features.self.crouch",
	nil,
	function()
		Backend:RemoveDisabledControl(36)
	end,
	{ description = "SELF_CROUCH_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_HANDS_UP",
	"features.self.hands_up",
	nil,
	function()
		Backend:RemoveDisabledControl(29)
	end,
	{ description = "SELF_HANDS_UP_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_SPRINT_INSIDE",
	"features.self.sprint_inside_interiors",
	nil,
	nil,
	{ description = "SELF_SPRINT_INSIDE_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_LOCKPICK_ANIM",
	"features.self.jacking_always_lockpick_anim",
	nil,
	nil,
	{ description = "SELF_LOCKPICK_ANIM_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_ROD",
	"features.self.rod",
	function()
		GVars.features.self.clumsy = false
		CheckIfRagdollBlocked()
	end,
	nil,
	{ description = "SELF_ROD_TT" },
	true,
	true
)

self_tab:AddBoolCommand("SELF_CLUMSY",
	"features.self.clumsy",
	function()
		GVars.features.self.rod = false
		CheckIfRagdollBlocked()
	end,
	nil,
	{ description = "SELF_CLUMSY_TT" },
	true,
	true
)

local function SelfUI()
	self_tab:GetGridRenderer():Draw()

	ImGui.Spacing()
	ImGui.SeparatorText(_T("GENERIC_SETTINGS_LABEL"))

	if (GVars.features.self.autoheal.enabled) then
		ImGui.SetNextItemWidth(240)
		GVars.features.self.autoheal.regen_speed, _ = ImGui.SliderInt(
			_T("SELF_REGEN_SPEED"),
			GVars.features.self.autoheal.regen_speed,
			1, 100
		)
	end

	if (GVars.features.self.rod or GVars.features.self.clumsy) then
		GVars.features.self.ragdoll_sound, _ = GUI:Checkbox(_T("SELF_RAGDOLL_SOUND"),
			GVars.features.self.ragdoll_sound,
			{ tooltip = _T("SELF_RAGDOLL_SOUND_TT") }
		)
	end
end

self_tab:RegisterGUI(SelfUI)
