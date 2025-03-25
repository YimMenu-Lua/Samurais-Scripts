---@diagnostic disable: undefined-global, lowercase-global

---@class CommandExecutor
CommandExecutor             = {}
CommandExecutor.__index     = CommandExecutor
CommandExecutor.commands    = {}
CommandExecutor.user_cmd    = ""
CommandExecutor.cmd_index   = 0
CommandExecutor.cmd_entered = false
CommandExecutor.suggestions = nil

---@param arg string
---@param callback function
function CommandExecutor:RegisterCommand(arg, callback)
    if (
        not arg or
        (type(arg) ~= "string") or not
        callback or
        (type(callback) ~= "function")
    ) then
        return
    end

    table.insert(self.commands, {arg = arg, callback = callback})
end

function CommandExecutor:HandleCallbacks()
    for _, v in ipairs(self.commands) do
        if (
            #self.user_cmd > 0 and
            self.cmd_entered and
            (self.user_cmd:lower() == v.arg:lower()) and
            (type(v.callback) == "function")
        ) then
            v.callback()
            CommandExecutor.user_cmd = ""
            break
        end
    end
end


function CommandExecutor:Draw()
    if should_draw_cmd_ui then
        local screen_w = ImGui.GetWindowWidth()
        local screen_h = ImGui.GetWindowHeight()
        ImGui.SetNextWindowSize(400, 180)
        ImGui.SetNextWindowPos(screen_w + 300, screen_h - 90)
        ImGui.SetNextWindowBgAlpha(0.75)
        should_draw_cmd_ui, cmd_ui_is_open = ImGui.Begin(
            "Command Executor",
            cmd_ui_is_open,
            ImGuiWindowFlags.NoTitleBar |
            ImGuiWindowFlags.NoMove |
            ImGuiWindowFlags.NoResize
        )
        ImGui.Spacing()
        ImGui.SeparatorText("Command Executor")
        ImGui.Spacing()
        ImGui.SetNextItemWidth(370)
        self.user_cmd, self.cmd_entered = ImGui.InputTextWithHint(
            "##cmd",
            "Type your command",
            self.user_cmd,
            128,
            ImGuiInputTextFlags.EnterReturnsTrue &
            ~ImGuiInputTextFlags.AllowTabInput
        )

        is_typing = ImGui.IsItemActive()

        if self.commands[1] and #self.user_cmd > 0 then
            self.suggestions = {}
            for _, entry in pairs(self.commands) do
                if string.find((entry.arg):lower(), self.user_cmd:lower()) then
                    table.insert(self.suggestions, entry)
                end
            end
        else
            self.suggestions = nil
        end

        if self.suggestions and self.suggestions[1] then
            for i = 1, #self.suggestions do
                local is_selected = (self.cmd_index == i)
                if ImGui.Selectable(self.suggestions[i].arg, is_selected) then
                    self.user_cmd = self.suggestions[i].arg:lower()
                    self.cmd_entered  = true
                end
                if is_selected then
                    self.cmd_index = i
                end
                if ImGui.IsItemHovered() then
                    UI.toolTip(false, "Click to execute this command.")
                end
            end
        end

        if self.cmd_entered then
            UI.widgetSound("Click")
            should_draw_cmd_ui = false
            cmd_ui_is_open = false
            gui.override_mouse(false)
        end
        ImGui.End()
    end
end

-- script.register_looped("SS_COMMAND_EXECUTOR", function()
--     CommandExecutor:HandleCallbacks()
-- end)
