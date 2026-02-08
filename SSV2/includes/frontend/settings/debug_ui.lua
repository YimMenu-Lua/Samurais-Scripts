-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local RED <const>               = Color("red")
local GREEN <const>             = Color("green")
local BLUE <const>              = Color("blue")
local GREY <const>              = Color("#636363")

local side_button_size          = vec2:new(140, 35)
local init_g_addr               = 0
local init_l_addr               = 0
local g_offset_count            = 0
local l_offset_count            = 0
local l_scr_name                = ""
local selected_g_type_idx       = 1
local selected_l_type_idx       = 1
local selected_entity_type      = 1
local TVehList                  = {}
local g_offsets                 = {}
local l_offsets                 = {}
local current_global
local current_local
local current_local_method
local current_global_method
local state_colors <const>      = {
	[eThreadState.UNK] = GREY,
	[eThreadState.DEAD] = RED,
	[eThreadState.RUNNING] = GREEN,
	[eThreadState.SUSPENDED] = BLUE,
}
local accessor_read_types       = {
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
	if ImGui.BeginChildEx("##entitytypes", vec2:new(200, 200), ImGuiChildFlags.Borders) then
		for etype, entities in ipairs(Backend.SpawnedEntities) do
			local count = table.getlen(entities)
			local label = _F("%ss (%d/%d)", EnumToString(Enums.eEntityType, etype), count,
				Backend.MaxAllowedEntities[etype])

			if ImGui.Selectable(label, selected_entity_type == etype) then
				selected_entity_type = etype
			end
		end
		ImGui.EndChild()
	end

	if (selected_entity_type and Backend.SpawnedEntities[selected_entity_type]) then
		ImGui.SameLine()
		ImGui.BeginChildEx("##entitydetails", vec2:zero(), ImGuiChildFlags.Borders)
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
				ImGui.Text(EnumToString(Enums.eEntityType, selected_entity_type))
				ImGui.TableSetColumnIndex(3)

				if (selected_entity_type == Enums.eEntityType.Ped) then
					if GUI:Button(_F(" K ##%d", handle)) then
						ThreadManager:Run(function()
							Ped(handle):Kill()
						end)
					end
				elseif (selected_entity_type == Enums.eEntityType.Vehicle) then
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
		ImGui.BeginChildEx("##threadctrls", vec2:new(170, 155), ImGuiChildFlags.Borders)
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

		ImGui.BulletText(_F("Internal State: %s", EnumToString(eInternalThreadState, selected_thread:GetInternalState())))
		ImGui.BulletText(_F("Average Load: %.1fms", selected_thread:GetLoadAvg()))
	end
end

local function DrawPointers()
	local ptr_list, failed_ptr_list = PatternScanner:ListPointers()
	local total_count, failed_count = table.getlen(ptr_list), #failed_ptr_list
	local child_height = math.min(total_count * 65, GVars.ui.window_size.y - 30)

	ImGui.BulletText(_F("Total Count: [%d]", total_count))
	ImGui.BeginChildEx("##ptr_list", vec2:new(0, child_height), ImGuiChildFlags.Borders)
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
		current_global = nil
		current_global_method = nil
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
		current_global_method = selected_G_type == "Pointer" and "GetPointer" or "Read" .. selected_G_type
		current_global = ScriptGlobal(init_g_addr)
		if (#g_offsets > 0) then
			for i = 1, #g_offsets do
				current_global = current_global:At(g_offsets[i])
			end
		end
	end
	ImGui.EndDisabled()

	if (init_g_addr and current_global and current_global_method and selected_G_type) then
		ImGui.Text(_F("%s = %s", current_global, current_global[current_global_method](current_global)))
	end

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
		current_local_method = selected_L_type == "Pointer" and "GetPointer" or "Read" .. selected_L_type
		current_local = ScriptLocal(init_l_addr, l_scr_name)
		if (#l_offsets > 0) then
			for i = 1, #l_offsets do
				current_local = current_local:At(l_offsets[i])
			end
		end
	end
	ImGui.EndDisabled()

	if (current_local and current_local_method) then
		ImGui.Text(_F("%s = %s", current_local, current_local[current_local_method](current_local)))
	end
end

local function DrawSerializerDebug()
	local eState = ThreadManager:GetThreadState("SS_SERIALIZER")

	ImGui.BulletText("Thread State:")
	ImGui.SameLine()
	GUI:Text(EnumToString(eThreadState, eState), state_colors[eState])
	ImGui.BulletText(_F("Is Disabled: %s", not Serializer:CanAccess()))
	ImGui.BulletText(_F("Time Since Last Flush: %.0f seconds ago.", Serializer:GetTimeSinceLastFlush() / 1e3))

	if GUI:Button("Dump Serializer") then
		Serializer:Dump()
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
	ImGui.BeginChildEx("##patchesbyowner", vec2:zero(), ImGuiChildFlags.Borders)
	for name, patch in pairs(selectedPatchTable) do
		local label = _F("%s (%s)", name, patch:IsEnabled() and "Applied" or "Not applied")
		if (ImGui.Selectable(label, selectedPatchName == name)) then
			selectedPatchName = name
		end
	end
	ImGui.EndChild()
end

local function DrawMiscTests()
	if (ImGui.Button("Test Toasts")) then
		for i = 1, 5 do
			local label = _F("Test %d", i)
			local level = math.random(0, 3)
			Notifier:Add(label, string.random(), level)
		end
	end

	if (ImGui.Button("Dump CWeaponInfo")) then
		local out           = {}
		local cpedweaponmgr = Self:Resolve().m_ped_weapon_mgr
		if (not cpedweaponmgr:IsValid()) then
			print("CPedWeaponManager: invalid pointer.")
			return
		end

		local cweaponinfo = cpedweaponmgr.m_weapon_info
		if (not cweaponinfo) then
			print("CWeaponInfo: invalid pointer.")
			return
		end

		for k, v in pairs(cweaponinfo) do
			if (IsInstance(v, "pointer")) then
				table.insert(out, _F("%s = 0x%X", k, v:get_address()))
			end
		end

		printf("\n--------- CWeaponInfo Dump ---------\n\n%s", table.concat(out, ",\n"))
	end
end

return function()
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
end
