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
    if b_ShouldDrawCommandsUI then
        local screen_w = ImGui.GetWindowWidth()
        local screen_h = ImGui.GetWindowHeight()

        ImGui.SetNextWindowSize(400, 200)
        ImGui.SetNextWindowPos(screen_w + 300, screen_h - 90)
        ImGui.SetNextWindowBgAlpha(0.75)
        b_ShouldDrawCommandsUI, b_IsCommandsUIOpen = ImGui.Begin(
            "Command Executor",
            b_IsCommandsUIOpen,
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

        b_IsTyping = ImGui.IsItemActive()

        if self.commands[1] and #self.user_cmd > 0 then
            self.suggestions = {}
            for _, entry in pairs(self.commands) do
                if string.find(entry.arg:lower(), self.user_cmd:lower()) then
                    table.insert(self.suggestions, entry)
                end
            end
        else
            self.suggestions = nil
        end

        if self.suggestions and self.suggestions[1] then
            ImGui.SetNextWindowBgAlpha(0.0)
            ImGui.BeginChild("##suggestions", 370, -1)
                for i = 1, #self.suggestions do
                    local is_selected = (self.cmd_index == i)
                    if ImGui.Selectable(self.suggestions[i].arg, is_selected) then
                        self.user_cmd = self.suggestions[i].arg:lower()
                        self.cmd_entered = true
                    end
                    if is_selected then
                        self.cmd_index = i
                    end
                    if ImGui.IsItemHovered() then
                        UI.Tooltip("Click to execute this command.")
                    end
                end
            ImGui.EndChild()
        end

        if self.cmd_entered then
            UI.WidgetSound("Click")
            b_ShouldDrawCommandsUI = false
            b_IsCommandsUIOpen = false
            gui.override_mouse(false)
        end
        ImGui.End()
    end
end

-- script.register_looped("SS_COMMAND_EXECUTOR", function()
--     CommandExecutor:HandleCallbacks()
-- end)
