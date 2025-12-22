---@diagnostic disable: lowercase-global

local ThemeManager = require("includes.services.ThemeManager")
local selected_theme = ThemeManager:GetCurrentTheme()
local draw_cfg_reset_window = false

---@type Set<string>
local cfg_reset_exceptions = Set.new()
local cfg_exc_keys = {
	{ pair = Pair.new("YimActions Favorites", "features.yim_actions.favorites"), clicked = false, selected = false },
	{ pair = Pair.new("YimResupplier", "features.yrv3"),                         clicked = false, selected = false },
	{ pair = Pair.new("Casino Pacino", "features.dunk"),                         clicked = false, selected = false },
	{ pair = Pair.new("Keyboard Keybinds", "keyboard_keybinds"),                 clicked = false, selected = false },
	{ pair = Pair.new("Controller Keybinds", "gamepad_keybinds"),                clicked = false, selected = false },
	-- { pair = Pair.new("EntityForge", "features.entity_forge"),                   selected = false },
}

local settings_tab = GUI:RegisterNewTab(Enums.eTabID.TAB_SETTINGS, "General", function()
	GVars.backend.auto_cleanup_entities = GUI:Checkbox("Auto Cleanup Entities", GVars.backend.auto_cleanup_entities)
	ImGui.Spacing()
	ImGui.BulletText(_F("Language: %s (%s)", GVars.backend.language_name, GVars.backend.language_code))
	ImGui.Spacing()

	if ImGui.BeginCombo("##langs", _F("%s (%s)",
			Translator.locales[GVars.backend.language_index].name,
			Translator.locales[GVars.backend.language_index].iso
		)) then
		for i, lang in ipairs(Translator.locales) do
			local is_selected = (i == GVars.backend.language_index)
			if ImGui.Selectable(_F("%s (%s)", lang.name, lang.iso), is_selected) then
				GVars.backend.language_index = i
				GVars.backend.language_name  = lang.name
				GVars.backend.language_code  = lang.iso
			end
		end
		ImGui.EndCombo()
	end

	ImGui.Spacing()

	if ImGui.Button(_T("SETTINGS_CFG_RESET")) then
		draw_cfg_reset_window = true
	end

	if (draw_cfg_reset_window) then
		if (ImGui.Begin("##cfg_reset",
				ImGuiWindowFlags.NoTitleBar
				| ImGuiWindowFlags.NoMove
				| ImGuiWindowFlags.NoResize
				| ImGuiWindowFlags.AlwaysAutoResize
			)) then
			GUI:QuickConfigWindow(_T("SETTINGS_CFG_RESET"), function()
				ImGui.Text(_T("SETTINGS_RESET_PRESERVE_KEYS"))
				ImGui.Spacing()
				for _, v in pairs(cfg_exc_keys) do
					local label = v.pair.first
					local gvar_key = v.pair.second
					v.selected, v.clicked = ImGui.Checkbox(label, v.selected)
					if (v.clicked) then
						if (v.selected) then
							cfg_reset_exceptions:Push(gvar_key)
						else
							cfg_reset_exceptions:Pop(gvar_key)
						end
					end
				end
				ImGui.Separator()
				ImGui.Spacing()
				if ImGui.Button(_T("GENERIC_RESET")) then
					ImGui.OpenPopup("##confirm_cfg_reset")
				end
				if GUI:ConfirmPopup("##confirm_cfg_reset") then
					Serializer:Reset(cfg_reset_exceptions)
				end
			end, function()
				cfg_reset_exceptions:Clear()
				for _, v in pairs(cfg_exc_keys) do
					v.clicked = false
					v.selected = false
				end
				draw_cfg_reset_window = false
			end)
			ImGui.End()
		end
	end
	ImGui.Dummy(1, 10)
end)

local function DrawGuiSettings()
	ImGui.SeparatorText("General")

	GVars.ui.disable_tooltips = GUI:Checkbox("Disable Tooltips", GVars.ui.disable_tooltips)

	ImGui.SameLine()
	GVars.ui.disable_sound_feedback = GUI:Checkbox("Disable Sound Feedback", GVars.ui.disable_sound_feedback)

	ImGui.SeparatorText("Geometry")
	GVars.ui.moveable, _ = GUI:Checkbox("Moveable Window", GVars.ui.moveable,
		{ tooltip = "Allows you to freely move the window" })

	if (GVars.ui.moveable) then
		ImGui.SameLine()
		if (GUI:Button("Reset Position", { tooltip = "Resets the window to default screen position" })) then
			GUI:Snap()
		end

		ImGui.SameLine()
		if (GUI:Button("Snap To Position")) then
			ImGui.OpenPopup("##snapMainWindow")
		end
	end

	if (ImGui.BeginPopupModal("##snapMainWindow",
			ImGuiWindowFlags.NoMove
			| ImGuiWindowFlags.NoTitleBar
			| ImGuiWindowFlags.NoResize
			| ImGuiWindowFlags.AlwaysAutoResize)
		) then
		GUI:QuickConfigWindow("Snap",
			function()
				ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 35, 30)
				ImGui.InvisibleButton("##dummy0", 30, 30)
				ImGui.SameLine()
				if (ImGui.ArrowButton("##top", 2)) then
					GUI:Snap(0)
				end
				if (ImGui.ArrowButton("##left", 0)) then
					GUI:Snap(2)
				end
				ImGui.SameLine()
				if (ImGui.Button("O", 30, 30)) then
					GUI:Snap(4)
				end
				ImGui.SameLine()
				if (ImGui.ArrowButton("##right", 1)) then
					GUI:Snap(3)
				end
				ImGui.InvisibleButton("##dummy1", 30, 30)
				ImGui.SameLine()
				if (ImGui.ArrowButton("##bottom", 3)) then
					GUI:Snap(1)
				end

				ImGui.PopStyleVar()
				GUI:ShowWindowHeightLimit()
			end,
			ImGui.CloseCurrentPopup
		)
		ImGui.EndPopup()
	end

	local resolution = Game.GetScreenResolution()

	GVars.ui.window_size.x, _ = ImGui.SliderFloat("Window Width",
		GVars.ui.window_size.x,
		GUI:GetMaxTopBarHeight(),
		resolution.x, "%.0f",
		---@diagnostic disable-next-line
		ImGuiSliderFlags.NoInput
	)

	ImGui.SameLine()
	if GUI:Button("Reset##width") then
		GUI:ResetWidth()
	end

	local top_bar_height = GUI:GetMaxTopBarHeight() + 10
	GVars.ui.window_size.y, _ = ImGui.SliderFloat("Max Window Height",
		GVars.ui.window_size.y,
		top_bar_height, resolution.y - top_bar_height,
		---@diagnostic disable-next-line
		"%.0f", ImGuiSliderFlags.NoInput
	)
	if (ImGui.IsItemHovered()) then
		GUI:ShowWindowHeightLimit()
	end
	GUI:HelpMarker(
		"The window is dynamic, it resizes itself vertically based on content.\n\nThis option allows you to set the maximum allowed height.")

	ImGui.SameLine()
	if (GUI:Button("Reset##height")) then
		GUI:ResetHeight()
	end

	ImGui.BeginDisabled()
	GVars.ui.window_pos.x, _ = ImGui.SliderFloat("X Position", GVars.ui.window_pos.x, 0, resolution.x)
	GUI:Tooltip("These are display only. Enable 'Moveable Window' then drag the top bar to freely move the window.")
	GVars.ui.window_pos.y, _ = ImGui.SliderFloat("Y Position", GVars.ui.window_pos.y, 0, resolution.y)
	GUI:Tooltip("These are display only. Enable 'Moveable Window' then drag the top bar to freely move the window.")
	ImGui.EndDisabled()

	ImGui.SeparatorText("Style")

	if (ImGui.BeginCombo("##uitheme", selected_theme and selected_theme.Name or "Theme")) then
		for name, theme in pairs(ThemeManager:GetThemes()) do
			local is_selected = selected_theme and selected_theme.Name == name or false
			if (ImGui.Selectable(name, is_selected)) then
				selected_theme = theme
				GVars.ui.style.theme = theme
				ThemeManager:SetCurrentTheme(theme)
			end
		end
		ImGui.EndCombo()
	end

	ImGui.Spacing()

	GVars.ui.style.bg_alpha, _ = ImGui.SliderFloat("Window Transparency", GVars.ui.style.bg_alpha, 0.01, 1.0)

	ImGui.SameLine()
	ImGui.Text(_F("(%d%%)", math.floor(GVars.ui.style.bg_alpha * 100)))

	ImGui.ColorEditVec4("Accent Color", GVars.ui.style.theme.TopBarFrameCol1)
	ImGui.ColorEditVec4("Top Bar Button Gradient", GVars.ui.style.theme.TopBarFrameCol2)
end

settings_tab:RegisterSubtab("Gui", DrawGuiSettings)

--#region debug

if (not GVars.backend.debug_mode) then
	return
end

local debug_tab = settings_tab:RegisterSubtab("Debug")
local RED <const> = Color("red")
local GREEN <const> = Color("green")
local BLUE <const> = Color("blue")
local GREY <const> = Color("#636363")

local side_button_size = vec2:new(140, 35)
local init_g_addr = 0
local init_l_addr = 0
local g_offset_count = 0
local l_offset_count = 0
local l_scr_name = ""
local selected_g_type_idx = 1
local selected_l_type_idx = 1
local selected_entity_type = 1
local TVehList = {}
local g_offsets = {}
local l_offsets = {}
local state_colors <const> = {
	[eThreadState.UNK] = GREY,
	[eThreadState.DEAD] = RED,
	[eThreadState.RUNNING] = GREEN,
	[eThreadState.SUSPENDED] = BLUE,
}
local accessor_read_types = {
	"Int",
	"Uint",
	"Float",
	"String",
	"Vec3",
	"Pointer"
}
local TVehTextureLookup <const> = {
	["akuma"]   = "sssa_default",
	["baller2"] = "sssa_default",
	["brigham"] = "sssa_dlc_2023_01",
	["clique2"] = "sssa_dlc_2023_01",
}

-- disable game controls
local input_1, input_2, input_3 = false, false, false

--fwd decl
local thread_name
local thread_state
local selected_thread
local ptr_name
local hovered_y
local selected_veh_name

---@return number
local function GetMaxAllowedEntities()
	local t_ = Backend.MaxAllowedEntities
	return t_[1] + t_[2] + t_[3]
end

---@return number
local function GetSpawnedEntities()
	local t_, L = Backend.SpawnedEntities, table.getlen
	return L(t_[1]) + L(t_[2]) + L(t_[3])
end

local function DrawEntities()
	ImGui.BulletText(_F("Maximum Allowed Entities: [%d]", GetMaxAllowedEntities()))
	ImGui.BulletText(_F("Total Spawned Entities: [%d]", GetSpawnedEntities()))
	if ImGui.BeginChild("##entitytypes", 200, 200, true) then
		for etype, entities in ipairs(Backend.SpawnedEntities) do
			local count = table.getlen(entities)
			local label = _F("%ss (%d/%d)", EnumTostring(eEntityType, etype), count,
				Backend.MaxAllowedEntities[etype])

			if ImGui.Selectable(label, selected_entity_type == etype) then
				selected_entity_type = etype
			end
		end
		ImGui.EndChild()
	end

	if (selected_entity_type and Backend.SpawnedEntities[selected_entity_type]) then
		ImGui.SameLine()
		ImGui.BeginChild("##entitydetails", 0, 0, true)
		---@diagnostic disable-next-line: undefined-global
		if ImGui.BeginTable("entity_table", 4, ImGuiTableFlags.RowBg | ImGuiTableFlags.Borders | ImGuiTableFlags.BordersInner) then
			ImGui.TableSetupColumn("Handle")
			ImGui.TableSetupColumn("Model Hash")
			ImGui.TableSetupColumn("Type")
			ImGui.TableSetupColumn("Actions")
			ImGui.TableHeadersRow()

			for handle in pairs(Backend.SpawnedEntities[selected_entity_type]) do
				ImGui.TableNextRow()
				ImGui.TableSetColumnIndex(0)
				ImGui.Text(tostring(handle))
				ImGui.TableSetColumnIndex(1)
				ImGui.Text(tostring(Game.GetEntityModel(handle)))
				ImGui.TableSetColumnIndex(2)
				ImGui.Text(EnumTostring(eEntityType, selected_entity_type))
				ImGui.TableSetColumnIndex(3)

				if (selected_entity_type == eEntityType.Ped) then
					if GUI:Button(_F(" K ##%d", handle)) then
						ThreadManager:Run(function()
							Ped(handle):Kill()
						end)
					end
				elseif (selected_entity_type == eEntityType.Vehicle) then
					if GUI:Button(_F(" C ##%d", handle)) then
						ThreadManager:Run(function()
							Vehicle(handle):Clone()
						end)
					end
				end

				ImGui.SameLine()
				if GUI:Button(_F(" D ##%d", handle)) then
					Game.DeleteEntity(handle)
				end
			end
			ImGui.EndTable()
		end
		ImGui.EndChild()
	end
end

local function DrawThreads()
	local thread_list = ThreadManager:ListThreads()
	local thread_count = table.getlen(thread_list)
	local child_height = math.min(thread_count * 20, GVars.ui.window_size.y - 60)

	ImGui.BulletText(_F("Thread Count: [%d]", thread_count))
	ImGui.BeginChild("##threadlist", ImGui.GetContentRegionAvail() - 200, child_height)
	ImGui.SetNextWindowBgAlpha(0)
	if ImGui.BeginListBox("##thread_listbox", -1, -1) then
		for name, thread in pairs(thread_list) do
			if (thread) then
				ImGui.PushStyleColor(ImGuiCol.Text, state_colors[thread:GetState()]:AsRGBA())
				if ImGui.Selectable(name, (name == thread_name)) then
					thread_name     = name
					thread_state    = thread:GetState()
					selected_thread = thread
				end
				ImGui.PopStyleColor()

				GUI:Tooltip(_F("CPU time: %s", thread:GetRunningTime()))
			end
		end
		ImGui.EndListBox()
	end
	ImGui.EndChild()

	if selected_thread then
		ImGui.SameLine()
		ImGui.BeginChild("##threadctrls", 170, 155, true)
		if GUI:Button("Remove", { size = side_button_size }) then
			ThreadManager:RemoveThread(thread_name)
		end

		if (thread_state == eThreadState.RUNNING) then
			if GUI:Button("Suspend", { size = side_button_size }) then
				ThreadManager:SuspendThread(thread_name)
			end

			if GUI:Button("Kill", { size = side_button_size }) then
				ThreadManager:StopThread(thread_name)
			end
		else
			if (thread_state == eThreadState.SUSPENDED) then
				if GUI:Button("Resume", { size = side_button_size }) then
					ThreadManager:ResumeThread(thread_name)
				end
			elseif (thread_state == eThreadState.DEAD) then
				if GUI:Button("Start", { size = side_button_size }) then
					ThreadManager:StartThread(thread_name)
				end
			end
		end
		ImGui.EndChild()

		ImGui.BulletText(_F("Internal State: %s", EnumTostring(eInternalThreadState, selected_thread:GetInternalState())))
		ImGui.BulletText(_F("Average Load: %.1fms", selected_thread:GetLoadAvg()))
	end
end

local function DrawPointers()
	local ptr_list, failed_ptr_list = PatternScanner:ListPointers()
	local total_count, failed_count = table.getlen(ptr_list), #failed_ptr_list
	local child_height = math.min(total_count * 65, GVars.ui.window_size.y - 30)

	ImGui.BulletText(_F("Total Count: [%d]", total_count))
	ImGui.BeginChild("##ptr_list", 0, child_height, true)
	ImGui.SetNextWindowBgAlpha(0)
	if ImGui.BeginListBox("##ptr_listbox", -1, -1) then
		for name, ptr in pairs(ptr_list) do
			if (ptr) then
				local address = ptr:GetAddress()
				local value = GPointers[name]
				local str = _F(
					"%s @ 0x%X = [%s]",
					name,
					address,
					type(value) == "table" and table.serialize(value) or
					tostring(value)
				)

				if (address == 0) then
					ImGui.PushStyleColor(ImGuiCol.Text, RED:AsRGBA())
				end

				if ImGui.Selectable(str, (name == ptr_name)) then
					ptr_name = name
				end

				if (address == 0) then
					ImGui.PopStyleColor()
				end
			end
		end
		ImGui.EndListBox()
	end
	ImGui.EndChild()

	if (failed_count == 0) then
		return
	end

	if ImGui.Button("Rescan Failed Pointers") then
		PatternScanner:RetryScan()
	end
end

local function DrawGlobalsAndLocals()
	local selected_G_type = accessor_read_types[selected_g_type_idx]
	local selected_L_type = accessor_read_types[selected_l_type_idx]
	Backend.disable_input = input_1 or input_2 or input_3

	ImGui.Spacing()
	ImGui.SeparatorText("ScriptGlobal")
	ImGui.Text("Global_")
	ImGui.SameLine()
	ImGui.SetNextItemWidth(200)
	init_g_addr, _ = ImGui.InputInt("##test_global", init_g_addr)
	input_1 = ImGui.IsItemActive()
	init_g_addr = math.max(0, init_g_addr)

	ImGui.SameLine()
	ImGui.BeginDisabled(init_g_addr == 0)
	if GUI:Button("Add Offset##globals") then
		g_offset_count = g_offset_count + 1
	end

	ImGui.SameLine()

	ImGui.BeginDisabled(g_offset_count == 0)
	if GUI:Button("Remove Offset##globals") then
		g_offset_count = math.max(0, g_offset_count - 1)
		if (#g_offsets > 0) then
			g_offsets[#g_offsets] = nil
		end
	end
	ImGui.EndDisabled()

	ImGui.SameLine()

	if GUI:Button("Clear##globals") then
		init_g_addr = 0
		g_offset_count = 0
		g_offsets = {}
		selected_g_type_idx = 1
	end

	ImGui.PushItemWidth(140)
	if (g_offset_count > 0) then
		for i = 1, g_offset_count do
			ImGui.Text(".f_")
			ImGui.SameLine()
			g_offsets[i], _ = ImGui.InputInt("##test_global_offset" .. i, g_offsets[i] or 0)
			g_offsets[i] = math.max(0, g_offsets[i])
		end
	end
	ImGui.PopItemWidth()

	ImGui.Text("Type:")
	for i, gtype in ipairs(accessor_read_types) do
		ImGui.SameLine()
		ImGui.PushID("GlobalType##" .. i)
		selected_g_type_idx, _ = ImGui.RadioButton(tostring(gtype), selected_g_type_idx, i)
		ImGui.PopID()
	end

	if GUI:Button(("Read %s##globals"):format(selected_G_type or "")) then
		local method_name = selected_G_type == "Pointer" and "GetPointer" or "Read" .. selected_G_type
		local g = ScriptGlobal(init_g_addr)
		if (#g_offsets > 0) then
			for i = 1, #g_offsets do
				g = g:At(g_offsets[i])
			end
		end

		debug_tab:Notify("%s = %s", g, g[method_name](g))
	end
	ImGui.EndDisabled()

	ImGui.Spacing()
	ImGui.SeparatorText("ScriptLocal")
	ImGui.Text("Local_")
	ImGui.SameLine()
	ImGui.SetNextItemWidth(200)
	init_l_addr, _ = ImGui.InputInt("##test_local", init_l_addr)
	input_2 = ImGui.IsItemActive()
	init_l_addr = math.max(0, init_l_addr)

	ImGui.SameLine()
	ImGui.SetNextItemWidth(200)
	l_scr_name, _ = ImGui.InputTextWithHint("##scr_name", "Script Name", l_scr_name, 64)
	input_3 = ImGui.IsItemActive()

	ImGui.BeginDisabled(string.isempty(l_scr_name) or init_l_addr == 0)
	ImGui.SameLine()
	if GUI:Button("Clear##locals") then
		l_scr_name = ""
		init_l_addr = 0
		l_offset_count = 0
		l_offsets = {}
		selected_l_type_idx = 1
	end

	if GUI:Button("Add Offset##locals") then
		l_offset_count = l_offset_count + 1
	end

	ImGui.SameLine()

	ImGui.BeginDisabled(l_offset_count == 0)
	if GUI:Button("Remove Offset##locals") then
		l_offset_count = math.max(0, l_offset_count - 1)
		if (#l_offsets > 0) then
			l_offsets[#l_offsets] = nil
		end
	end
	ImGui.EndDisabled()

	ImGui.PushItemWidth(140)
	if (l_offset_count > 0) then
		for i = 1, l_offset_count do
			ImGui.Text(".f_")
			ImGui.SameLine()
			l_offsets[i], _ = ImGui.InputInt("##test_local_offset" .. i, l_offsets[i] or 0)
			l_offsets[i] = math.max(0, l_offsets[i])
		end
	end
	ImGui.PopItemWidth()

	ImGui.Text("Type:")
	for i, ltype in ipairs(accessor_read_types) do
		if (ltype ~= "String") then
			ImGui.SameLine()
			ImGui.PushID("LocalTypes##" .. i)
			selected_l_type_idx, _ = ImGui.RadioButton(tostring(ltype), selected_l_type_idx, i)
			ImGui.PopID()
		end
	end

	if GUI:Button(("Read %s##locals"):format(selected_L_type or "")) then
		local method_name = selected_L_type == "Pointer" and "GetPointer" or "Read" .. selected_L_type
		local l = ScriptLocal(init_l_addr, l_scr_name)
		if (#l_offsets > 0) then
			for i = 1, #l_offsets do
				l = l:At(l_offsets[i])
			end
		end

		debug_tab:Notify("%s = %s", l, l[method_name](l))
	end
	ImGui.EndDisabled()
end

local function DrawSerializerDebug()
	local eState = ThreadManager:GetThreadState("SS_SERIALIZER")

	ImGui.BulletText("Thread State:")
	ImGui.SameLine()
	GUI:Text(EnumTostring(eThreadState, eState), state_colors[eState])
	ImGui.BulletText(_F("Is Disabled: %s", not Serializer:CanAccess()))
	ImGui.BulletText(_F("Time Since Last Flush: %.0f seconds ago.", Serializer:GetTimeSinceLastFlush() / 1e3))

	if GUI:Button("Dump Serializer") then
		Serializer:DebugDump()
	end
end

local function DrawTranslatorDebug()
	ImGui.TextDisabled("You can switch between available languages in Settings -> General.")
	ImGui.Spacing()

	if GUI:Button("Reload Translator") then
		Translator:Reload()
	end
end

local function PopulateVehlistOnce()
	if (#TVehList > 0) then
		return
	end

	ThreadManager:Run(function()
		for name, _ in pairs(TVehTextureLookup) do
			table.insert(
				TVehList,
				{
					name = name,
					displayname = vehicles.get_vehicle_display_name(joaat(name))
				}
			)
		end

		table.sort(TVehList, function(a, b)
			return a.displayname < b.displayname
		end)
		yield()
	end)
end

local function DrawDummyVehSpawnMenu()
	local resolution = Game.GetScreenResolution()
	ImGui.Text("Lightweight Vehicle Preview Test")
	PopulateVehlistOnce()

	if ImGui.BeginListBox("##dummyvehlist", -1, 0) then
		for _, veh in ipairs(TVehList) do
			ImGui.Selectable(veh.displayname, false)
			if ImGui.IsItemHovered() then
				local item_min = vec2:new(ImGui.GetItemRectMin())
				hovered_y = item_min.y
				selected_veh_name = veh.name
			elseif not ImGui.IsAnyItemHovered() then
				hovered_y = nil
			end
		end
		ImGui.EndListBox()
	end

	if (hovered_y and selected_veh_name and TVehTextureLookup[selected_veh_name]) then
		local texture_dict = TVehTextureLookup[selected_veh_name]
		local texture_name = selected_veh_name
		local window_pos   = vec2:new(ImGui.GetWindowPos())
		local abs_pos      = vec2:new(window_pos.x + ImGui.GetWindowWidth(), hovered_y)
		local draw_pos     = abs_pos / resolution

		ThreadManager:Run(function()
			if Game.RequestTextureDict(texture_dict) then
				local sprite_w = 256
				local sprite_h = 128
				local norm_w   = sprite_w / resolution.x
				local norm_h   = sprite_h / resolution.y

				GRAPHICS.DRAW_SPRITE(
					texture_dict,
					texture_name,
					draw_pos.x + (norm_w / 2), draw_pos.y + (norm_h / 2),
					norm_w, norm_h,
					0.0,
					255, 255, 255, 255,
					false
				)
			end
		end)
	end
end

local function DrawMiscTests()
	ImGui.SeparatorText("Vehicle Flag Dump")

	if (ImGui.Button("Handling Flags")) then
		script.run_in_fiber(function()
			local PV = Self:GetVehicle()
			if (not PV:IsValid()) then
				return
			end
			PV:Resolve():DumpHandlingFlags()
		end)
	end
	ImGui.SameLine()
	if (ImGui.Button("Model Flags")) then
		script.run_in_fiber(function()
			local PV = Self:GetVehicle()
			if (not PV:IsValid()) then
				return
			end
			PV:Resolve():DumpModelFlags()
		end)
	end
	ImGui.SameLine()
	if (ImGui.Button("Model Info Flags")) then
		script.run_in_fiber(function()
			local PV = Self:GetVehicle()
			if (not PV:IsValid()) then
				return
			end
			PV:Resolve():DumpModelInfoFlags()
		end)
	end
	ImGui.SameLine()
	if (ImGui.Button("Advanced Flags")) then
		script.run_in_fiber(function()
			local PV = Self:GetVehicle()
			if (not PV:IsValid()) then
				return
			end
			PV:Resolve():DumpAdvancedFlags()
		end)
	end

	if (ImGui.Button("Get Subhandling Data")) then
		script.run_in_fiber(function()
			local PV = Self:GetVehicle()
			if (not PV:IsValid()) then
				return
			end

			print(PV:GetHandlingData())
		end)
	end

	if (ImGui.Button("Test Confirm Popup")) then
		ImGui.OpenPopup("testPopup")
	end

	if (GUI:ConfirmPopup("testPopup")) then
		print("confirmed")
	end
end

local selectedPatchTable
local selectedPatchName = ""
local function DrawPatches()
	local patch_list <const> = Memory:ListPatches()
	local thread_count = table.getlen(patch_list)
	local child_width = selectedPatchTable and ImGui.GetContentRegionAvail() * 0.4 or 0

	if (thread_count == 0) then
		ImGui.Text("No registered memory patches.")
		return
	end

	ImGui.BeginChild("##patchlist", child_width, 0)
	ImGui.SetNextWindowBgAlpha(0)
	if ImGui.BeginListBox("##patches", -1, 0) then
		for owner, patchTable in pairs(patch_list) do
			local count = table.getlen(patchTable)
			local label = _F("%s [%d]",
				(owner.__type or owner.__name or owner.m_name or tostring(patchTable)),
				count
			)
			if (ImGui.Selectable(label, selectedPatchTable == patchTable)) then
				selectedPatchTable = patchTable
			end
		end
		ImGui.EndListBox()
	end
	ImGui.EndChild()
	if (not selectedPatchTable) then
		return
	end

	ImGui.SameLine()
	ImGui.BeginChild("##patchesbyowner", 0, 0, true)
	for name, patch in pairs(selectedPatchTable) do
		local label = _F("%s (%s)", name, patch:IsEnabled() and "Applied" or "Not applied")
		if (ImGui.Selectable(label, selectedPatchName == name)) then
			selectedPatchName = name
		end
	end
	ImGui.EndChild()
end

debug_tab:RegisterGUI(function()
	ImGui.BeginTabBar("##debug")
	ImGui.PushTextWrapPos(ImGui.GetFontSize() * 35)

	if ImGui.BeginTabItem("Entities") then
		DrawEntities()
		ImGui.EndTabItem()
	end

	if ImGui.BeginTabItem("Threads") then
		DrawThreads()
		ImGui.EndTabItem()
	end

	if ImGui.BeginTabItem("Pointers") then
		DrawPointers()
		ImGui.EndTabItem()
	end

	if ImGui.BeginTabItem("Patches") then
		DrawPatches()
		ImGui.EndTabItem()
	end

	if ImGui.BeginTabItem("Globals & Locals") then
		DrawGlobalsAndLocals()
		ImGui.EndTabItem()
	end

	if ImGui.BeginTabItem("Serializer") then
		DrawSerializerDebug()
		ImGui.EndTabItem()
	end

	if ImGui.BeginTabItem("Translator") then
		DrawTranslatorDebug()
		ImGui.EndTabItem()
	end

	if ImGui.BeginTabItem("Preview Test") then
		DrawDummyVehSpawnMenu()
		ImGui.EndTabItem()
	end

	if ImGui.BeginTabItem("Misc Tests") then
		DrawMiscTests()
		ImGui.EndTabItem()
	end

	ImGui.PopTextWrapPos()
	ImGui.EndTabBar()
end)

--#endregion
