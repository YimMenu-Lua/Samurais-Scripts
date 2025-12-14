local self_ui = GUI:RegisterNewTab(eTabID.TAB_SELF, "Self")

self_ui:AddBoolCommand("Auto Heal",
	"features.self.autoheal.enabled",
	nil,
	nil,
	{ tooltip = " Regenerates your health and armour" }
)

local function SelfUI()
	self_ui:GetGridRenderer():Draw()

	ImGui.Spacing()
	ImGui.SeparatorText("Settings")

	if (GVars.features.self.autoheal.enabled) then
		GVars.features.self.autoheal.regen_speed, _ = ImGui.SliderInt(
			"Health Regen Speed",
			GVars.features.self.autoheal.regen_speed,
			1, 100
		)
	end
end

self_ui:RegisterGUI(SelfUI)
