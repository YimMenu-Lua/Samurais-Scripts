-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local ThemeManager = require("includes.services.ThemeManager")

---@class CommandMeta
---@field args? string[]
---@field description? string
---@field alias? string[]
---@field isTranslatorLabel? boolean

---@class CommandsWindow
---@field size vec2
---@field pos vec2
---@field should_draw boolean
---@field bottom_text string
---@field popup { should_draw: boolean, name: string }


--------------------------------------
-- Class: CommandExecutor
--------------------------------------
---@class CommandExecutor : ClassMeta<CommandExecutor>
---@field protected m_initialized boolean
---@field private m_cmd_entered boolean
---@field private m_cmd_index integer
---@field private m_history_index integer
---@field private m_user_cmd string
---@field private m_hint_text string
---@field private m_history array<string>
---@field private m_suggestions array<{name: string, def: string}>
---@field private m_commands table<string, { callback: fun(...), args: string[], description: string, alias?: string[], is_alias?: boolean, isTranslatorLabel?: boolean }>
---@field private m_sorted_command_names array<string>
---@field private m_screen_size vec2
---@field private m_window CommandsWindow
---@field private m_mutation_request? string
local CommandExecutor = Class("CommandExecutor")

-- Constructor
---@return CommandExecutor
function CommandExecutor:init()
	if (self.m_initialized) then
		return self
	end

	self.m_initialized   = false
	self.m_cmd_entered   = false
	self.m_cmd_index     = 0
	self.m_history_index = 0
	self.m_user_cmd      = ""
	self.m_hint_text     = ">_"
	self.m_history       = {}
	self.m_suggestions   = {}
	self.m_screen_size   = vec2:zero()
	self.m_window        = {
		size        = vec2:zero(),
		pos         = vec2:zero(),
		should_draw = false,
		bottom_text = "All built-in commands are prefixed with an exclamation mark <!>.",
		popup       = {
			should_draw = false,
			name = "cmd_popup"
		}
	}


	self.m_commands = self:GetDefaultCommands()
	for name, data in pairs(self.m_commands) do
		if data.alias then
			for _, a in ipairs(data.alias) do
				self:RegisterAlias(a, name)
			end
		end
	end

	ThreadManager:RegisterLooped("SS_COMMANDS", function()
		self:HandleCallbacks()
	end)

	GUI:RegisterIndependentGUI(function()
		self:Draw()
	end)

	KeyManager:RegisterKeybind(GVars.commands_console.key, function()
		self.m_window.should_draw = not self.m_window.should_draw
		gui.override_mouse(self.m_window.should_draw)
		Backend.disable_input = self.m_window.should_draw
	end)

	-- hardcoded.
	KeyManager:RegisterKeybind(eVirtualKeyCodes.ESC, function()
		self:Close()
	end)

	Backend:RegisterEventCallback(Enums.eBackendEvent.RELOAD_UNLOAD, function()
		self:Close()
	end)

	self.m_initialized = true
	return self
end

---@return number
function CommandExecutor:GetCommandCount()
	local count = 0
	for _, cmd in pairs(self.m_commands) do
		if (not cmd.is_alias) then
			count = count + 1
		end
	end

	return count
end

---@param command_name string
---@return boolean
function CommandExecutor:IsBuiltinCommand(command_name)
	return string.isvalid(command_name) and command_name:startswith("!")
end

---@param cmd_name string
function CommandExecutor:DoesCommandExist(cmd_name)
	return self.m_commands[cmd_name] ~= nil
end

-- Registers a command with a callback that receives arguments.
---@param name string
---@param callback fun(args: table)
---@param meta? CommandMeta -- optional metadata
function CommandExecutor:RegisterCommand(name, callback, meta)
	self.m_commands[name:lower()] = {
		callback = callback,
		args = meta and meta.args or {},
		description = meta and meta.description or "No description.",
		alias = meta and meta.alias or nil,
		isTranslatorLabel = meta and meta.isTranslatorLabel or false,
		is_alias = false,
	}

	if (meta and meta.alias) then
		for _, alias in ipairs(meta.alias) do
			self:RegisterAlias(alias:lower(), name:lower())
		end
	end
end

---@param alias string
---@param of string original command name
function CommandExecutor:RegisterAlias(alias, of)
	local _orig = self.m_commands[of:lower()]
	if not _orig then
		log.fwarning("Attempt to alias a non-existing command: '%s'", of)
		return
	end

	local cmd = table.copy(_orig)
	cmd.alias = {}
	cmd.is_alias = true
	self.m_commands[alias:lower()] = cmd
end

---@param name string
function CommandExecutor:RemoveCommand(name)
	if (self:IsBuiltinCommand(name)) then
		Notifier:ShowError("Command Executor", "Removing built-in commands is not allowed.")
		return
	end

	if (not self.m_commands[name]) then
		return
	end

	self.m_commands[name] = nil
end

---@return string
function CommandExecutor:ListCommands()
	local out = { "\n" }

	for name, def in pairs(self.m_commands) do
		if (not def.is_alias) then
			local sig = name
			if (def.args) then
				sig = sig .. " " .. table.concat(def.args, ", ")
			end

			local desc = def.isTranslatorLabel and _T(def.description) or def.description
			local line = _F("* %s - %s", sig, desc)
			if (def.alias and #def.alias > 0) then
				line = line .. " - Aliases: " .. table.concat(def.alias, " | ")
			end
			table.insert(out, line)
		end
	end

	table.sort(out)
	return table.concat(out, "\n")
end

-- Parses the raw user_cmd string into a command and args.
---@param input string
---@return string cmd, table args
function CommandExecutor:ParseCommand(input)
	local function cast(value)
		local lower = value:lower()
		if (lower == "true") then
			return true
		elseif (lower == "false") then
			return false
		elseif tonumber(value) then
			return tonumber(value)
		end
		return value
	end

	local args = {}
	for word in input:gmatch("%S+") do
		table.insert(args, cast(word))
	end

	local cmd = table.remove(args, 1)
	return cmd and cmd:lower() or "", args
end

function CommandExecutor:HandleCallbacks()
	if (not self.m_window.should_draw) then
		sleep(500)
		return
	end

	if (self.m_cmd_entered and string.isvalid(self.m_user_cmd)) then
		GUI:PlaySound(GUI.Sounds.Click)

		local cmd, args = self:ParseCommand(self.m_user_cmd)
		local command   = self.m_commands[cmd]
		local callback  = command and command.callback or nil

		if (type(callback) == "function") then
			ThreadManager:Run(function()
				callback(args)
			end)

			table.insert(self.m_history, self.m_user_cmd)
			if (GVars.commands_console.auto_close and not self:IsBuiltinCommand(cmd)) then
				self:Close()
			end
		else
			self:notify("Unknown command: %s", cmd)
		end

		self.m_cmd_entered = false
		self.m_user_cmd    = ""
		self.m_hint_text   = ">_"
	end

	if (#self.m_suggestions == 0) then
		if (not string.isnullorempty(self.m_user_cmd)) then
			return
		end

		if (KeyManager:IsKeyJustPressed(eVirtualKeyCodes.UP)) then
			self.m_history_index = self.m_history_index - 1
			if (self.m_history_index < 0) then
				self.m_history_index = #self.m_history
			end

			self.m_hint_text = self.m_history[self.m_history_index] or ">_"
		end

		if (KeyManager:IsKeyJustPressed(eVirtualKeyCodes.DOWN)) then
			self.m_history_index = self.m_history_index + 1
			if (self.m_history_index > #self.m_history) then
				self.m_history_index = 0
			end
			self.m_hint_text = self.m_history[self.m_history_index] or ">_"
		end

		if ((KeyManager:IsKeyPressed(eVirtualKeyCodes.TAB)
					or KeyManager:IsKeyPressed(eVirtualKeyCodes.ENTER))
				or KeyManager:IsKeyJustPressed(eVirtualKeyCodes.RIGHT)
				and self.m_history[self.m_history_index]) then
			self.m_mutation_request = self.m_history[self.m_history_index]
			self.m_history_index = 0
			self.m_hint_text = ">_"
		end
	else
		self.m_hint_text = ">_"

		if (KeyManager:IsKeyJustPressed(eVirtualKeyCodes.UP)) then
			self.m_cmd_index = self.m_cmd_index - 1
			if (self.m_cmd_index < 1) then
				self.m_cmd_index = #self.m_suggestions
			end
		end

		if (KeyManager:IsKeyJustPressed(eVirtualKeyCodes.DOWN)) then
			self.m_cmd_index = self.m_cmd_index + 1
			if (self.m_cmd_index > #self.m_suggestions) then
				self.m_cmd_index = 1
			end
		end

		if ((KeyManager:IsKeyPressed(eVirtualKeyCodes.TAB) or KeyManager:IsKeyPressed(eVirtualKeyCodes.ENTER)) and self.m_suggestions[self.m_cmd_index]) then
			self.m_mutation_request = self.m_suggestions[self.m_cmd_index].name .. " "
			self.m_cmd_index = 0
		end
	end
end

function CommandExecutor:DrawCommandDump()
	local size, pos = GUI:GetNewWindowSizeAndCenterPos(0.3, 0.5)
	ImGui.SetNextWindowSize(size.x, size.y)
	ImGui.SetNextWindowPos(pos.x, pos.y)
	ImGui.SetNextWindowFocus()

	if ImGui.BeginPopupModal(self.m_window.popup.name,
			ImGuiWindowFlags.NoTitleBar |
			ImGuiWindowFlags.AlwaysAutoResize |
			ImGuiWindowFlags.NoResize
		) then
		ImGui.SetNextWindowBgAlpha(0)
		if ImGui.BeginChild("##cmd_dump_upper", (size.x * 0.93), (size.y * 0.15)) then
			ImGui.Dummy(1, 10)

			if GUI:Button("Close") then
				ImGui.CloseCurrentPopup()
				return
			end

			ImGui.SameLine()
			ImGui.Dummy(10, 1)
			ImGui.SameLine()

			if GUI:Button("Print To Console") then
				print(self:ListCommands())
				self:notify("Command dump logged to console.")
			end
			ImGui.EndChild()
		end

		ImGui.SeparatorText(_F("Command Count: [ %d ]", self:GetCommandCount()))
		ImGui.SetNextWindowBgAlpha(0)
		if ImGui.BeginChild("##cmd_dump_lower", (size.x * 0.965), (size.y * 0.7)) then
			ImGui.PushTextWrapPos(size.x * 0.94)
			for _, name in ipairs(self.m_sorted_command_names or {}) do
				local data = self.m_commands[name]
				if (data.is_alias) then
					goto continue
				end

				ImGui.BulletText(name)
				ImGui.Indent()
				ImGui.SetWindowFontScale(0.9)
				data.description = data.description or "No description."
				local desc = data.isTranslatorLabel and _T(data.description) or data.description
				ImGui.Text(desc)

				if data.args then
					local args_txt = (#data.args == 0
						and "- Arguments: None."
						or _F("- Arguments (%d): %s", #data.args, table.concat(data.args, ", "))
					)
					ImGui.Text(args_txt)
				end

				if data.alias then
					ImGui.Text(_F("- Alias: %s", table.concat(data.alias, " | ")))
				end
				ImGui.SetWindowFontScale(1)
				ImGui.Unindent()

				::continue::
			end
			ImGui.PopTextWrapPos()
			ImGui.EndChild()
		end
		ImGui.EndPopup()
	end
end

function CommandExecutor:DrawSuggestions()
	if (#self.m_suggestions > 0) then
		local height = math.min(#self.m_suggestions, 5) * ImGui.GetTextLineHeightWithSpacing()
		ImGui.SetNextWindowBgAlpha(0.45)
		ImGui.BeginChild("##suggestions", self.m_window.size.x * 0.93, height)
		for i, suggestion in ipairs(self.m_suggestions) do
			local is_selected = (self.m_cmd_index == i)
			if ImGui.Selectable(suggestion.name, is_selected) then
				self.m_cmd_index = i
			end

			if (is_selected) then
				ImGui.SetScrollHereY()
			end

			if ImGui.IsItemHovered() then
				GUI:Tooltip(
					("Left click to autofill this command.\n\n%s"
					):format(self.m_suggestions[i] and self.m_suggestions[i].def or "")
				)
			end

			if GUI:IsItemClicked(GUI.MouseButtons.RIGHT) then
				local cmd = self.m_commands[suggestion.name]
				self.m_user_cmd = suggestion.name
				self.m_cmd_entered = cmd and (not cmd.args or #cmd.args == 0)
				self.m_hint_text = ">_"
			end
		end
		ImGui.EndChild()
	end

	if self.m_suggestions[self.m_cmd_index] then
		self.m_window.bottom_text = self.m_suggestions[self.m_cmd_index].def
	elseif self.m_history[self.m_history_index] then
		self.m_window.bottom_text = "Press [Right Arrow] or [TAB] or [Enter] to auto-fill this command."
	else
		self.m_window.bottom_text = "All built-in commands are prefixed with an exclamation mark <!>."
	end
end

function CommandExecutor:ShouldFocusInput()
	return not self.m_mutation_request
		and not KeyManager:IsKeyPressed(eVirtualKeyCodes.UP)
		and not KeyManager:IsKeyPressed(eVirtualKeyCodes.DOWN)
		and not KeyManager:IsKeyPressed(eVirtualKeyCodes.RIGHT)
		and not KeyManager:IsKeyPressed(eVirtualKeyCodes.ENTER)
		and not KeyManager:IsKeyPressed(eVirtualKeyCodes.TAB)
end

function CommandExecutor:Draw()
	if self.m_window.should_draw then
		if (self.m_screen_size:is_zero() or self.m_window.size:is_zero()) then
			self.m_screen_size = Game.GetScreenResolution()
			self.m_window.size, self.m_window.pos = GUI:GetNewWindowSizeAndCenterPos(0.3, 0.37)
		end

		ImGui.SetNextWindowSize(self.m_window.size.x, self.m_window.size.y)
		ImGui.SetNextWindowPos(self.m_window.pos.x, self.m_window.pos.y)
		ImGui.SetNextWindowBgAlpha(GVars.ui.style.bg_alpha)

		if (not gui.mouse_override()) then
			gui.override_mouse(true)
		end

		ThemeManager:PushTheme()
		if ImGui.Begin(
				"Command Executor",
				ImGuiWindowFlags.NoTitleBar |
				ImGuiWindowFlags.NoMove |
				ImGuiWindowFlags.NoResize |
				ImGuiWindowFlags.NoScrollbar
			) then
			ImGui.SetNextWindowBgAlpha(0)
			ImGui.BeginChild("main", 0, self.m_window.size.y * 0.7)
			ImGui.Spacing()
			ImGui.SeparatorText("Command Executor")
			ImGui.Spacing()
			ImGui.SetNextItemWidth(-1)
			if (self:ShouldFocusInput()) then
				ImGui.SetKeyboardFocusHere()
			end

			self.m_user_cmd, self.m_cmd_entered = ImGui.InputTextWithHint(
				"##cmd",
				self.m_hint_text,
				self.m_user_cmd,
				128,
				ImGuiInputTextFlags.EnterReturnsTrue
			)

			if (not self:ShouldFocusInput()) then
				ImGui.SetKeyboardFocusHere()
			end

			if (self.m_mutation_request) then
				self.m_user_cmd = self.m_mutation_request
				self.m_mutation_request = nil
			end

			local typed_cmd = self.m_user_cmd:match("^(%S+)") or ""
			self.m_suggestions = {}

			for name, data in pairs(self.m_commands) do
				if (typed_cmd ~= "" and name:find(typed_cmd:lower(), 1, true)) then
					local args_txt = (#data.args == 0
						and "Arguments: None."
						or _F("Arguments (%d): %s", #data.args, table.concat(data.args, ", "))
					)

					local s = _F("%s\n- %s", data.description or "No description", args_txt)
					if (data.alias and #data.alias > 0 and not data.is_alias) then
						s = s .. "\n- Aliases: " .. table.concat(data.alias, " | ")
					end

					table.insert(self.m_suggestions, { name = name, def = s })
				end
			end

			self:DrawSuggestions()

			ImGui.EndChild()
			ImGui.Separator()
			ImGui.Spacing()
			ImGui.SetWindowFontScale(0.9)
			ImGui.PushTextWrapPos(self.m_window.size.x * 0.9)
			ImGui.TextDisabled(self.m_window.bottom_text)
			ImGui.PopTextWrapPos()
			ImGui.SetWindowFontScale(1)

			if (self.m_window.popup.should_draw) then
				ImGui.OpenPopup(self.m_window.popup.name)
				self.m_window.popup.should_draw = false
			end

			self:DrawCommandDump()
			ImGui.End()
			ThemeManager:PopTheme()
		end
	end
end

function CommandExecutor:SetAutoClose(toggle)
	if (type(toggle) ~= "boolean") then
		return
	end

	GVars.commands_console.auto_close = toggle
end

function CommandExecutor:Close()
	local was_open                  = self.m_window.should_draw
	self.m_window.should_draw       = false
	self.m_window.popup.should_draw = false
	self.m_mutation_request         = nil
	self.m_suggestions              = {}
	self.m_user_cmd                 = ""
	self.m_hint_text                = ">_"
	gui.override_mouse(false)
	if (not was_open) then
		Backend.disable_input = false
		return
	end

	ThreadManager:Run(function()
		sleep(200)
		Backend.disable_input = false
	end)
end

function CommandExecutor:GetDefaultCommands()
	return {
		["!list"] = {
			callback = function()
				if (not self.m_sorted_command_names) then
					self.m_sorted_command_names = {}
					for name in pairs(self.m_commands) do
						table.insert(self.m_sorted_command_names, name)
					end

					table.sort(self.m_sorted_command_names, function(a, b)
						return a:lower() < b:lower()
					end)
				end
				self.m_window.popup.should_draw = true
			end,
			alias = { "!ls", "!dump" },
			args = {},
			description = "Lists all available commands in a popup window."
		},
		["!help"] = {
			callback = function()
				local notif_text = [[
- Use Up/Down arrows to navigate through command history and suggestions.

- Press tab when a command is highlighted to quickly auto-fill it.

- Commands from history are saved and auto-filled with their last used parameters (if any).

- Press enter to execute a command.
]]
				if (not Notifier) then
					log.info(notif_text)
					return
				end

				Notifier:ShowMessage(
					"CommandExecutor",
					notif_text,
					true,
					15
				)
			end,
			alias = { "!h" },
			args = {},
			description = "Displays usage help in a toast notification that lasts 15 seconds.",
		},
		["!setautoclose"] = {
			---@param args table
			callback = function(args)
				if (type(args) ~= "table") then
					Notifier:ShowError(
						"CommandExecutor",
						"This command expects one parameter.\nUsage example: !setautoclose true",
						true
					)
					return
				end

				local arg = args[1]
				if (type(arg) ~= "boolean") then
					Notifier:ShowError(
						"CommandExecutor",
						"This command expects a boolean parameter.\nUsage example: !setautoclose true",
						true
					)
					return
				end

				self:SetAutoClose(arg)
				GVars.commands_console.auto_close = arg
				self:notify("Auto-Close %s.", arg and "Enabled" or "Disabled")
			end,
			args = { "<toggle: boolean>" },
			description = "Sets the behavior of the command window after successful command execution.",
		},
		["!setkey"] = {
			callback = function(args)
				if (type(args) ~= "table") then
					Notifier:ShowError(
						"CommandExecutor",
						"This command expects one parameter.\nUsage example: !setkey 0x49",
						true
					)
					return
				end

				local newkey = KeyManager:GetKey(args[1])
				if (not newkey or not IsInstance(newkey, Key)) then
					Notifier:ShowError(
						"CommandExecutor",
						"Unknown parameter.\nUsage example: !setkey F8",
						true
					)
					return
				end

				local cmd_cfg = Serializer:ReadItem("commands_console")
				local oldkey = cmd_cfg.key
				cmd_cfg.key = newkey.m_name
				GVars.commands_console = cmd_cfg
				self:notify("Default toggle key set to [%s].", newkey.m_name)
				KeyManager:UpdateKeybind(oldkey, newkey)
			end,
			args = { "<key: string | number>" },
			description = "Sets the default command window key."
		},
		["!panique"] = {
			callback = function()
				Backend:PANIQUE()
			end,
			args = {},
			description = "BAGUETTE",
			alias = { "!panik", "!dammit", "!bordeldemerde", "!panicus" }
		}
	}
end

return CommandExecutor
