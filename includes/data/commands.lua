---@diagnostic disable

commands_t  = {}
local ucmdEntered   = false
local command_index = 0

function RegisterCommand(arg, callback)
  table.insert(commands_t, { arg = arg, callback = callback })
end

function CommandExecutor()
  if ucmdEntered and #user_command > 0 then
    for _, v in ipairs(commands_t) do
      if user_command == v.arg then
        if type(v.callback) == 'function' then
          v.callback()
          user_command = ""
          break
        end
      end
    end
  end
end

function command_ui()
  if should_draw_cmd_ui then
    local screen_w = ImGui.GetWindowWidth()
    local screen_h = ImGui.GetWindowHeight()
    ImGui.SetNextWindowSize(400, 180)
    ImGui.SetNextWindowPos(screen_w + 300, screen_h - 90)
    ImGui.SetNextWindowBgAlpha(0.75)
    cmd_ui_is_open = ImGui.Begin(
      "Command Executor", cmd_ui_is_open,
      ImGuiWindowFlags.NoTitleBar |
      ImGuiWindowFlags.NoMove |
      ImGuiWindowFlags.NoResize
    )
    ImGui.Spacing(); ImGui.SeparatorText("Command Executor"); ImGui.Spacing(); ImGui.SetNextItemWidth(370)
    user_command, ucmdEntered = ImGui.InputTextWithHint(
      "##cmd", "Type your command", user_command, 128,
      ImGuiInputTextFlags.EnterReturnsTrue & ~ ImGuiInputTextFlags.AllowTabInput
    )
    is_typing = ImGui.IsItemActive()
    if commands_t[1] ~= nil and #user_command > 0 then
      suggestions_t = {}
      for _, entry in pairs(commands_t) do
        if string.find((entry.arg):lower(), user_command:lower()) then
          table.insert(suggestions_t, entry)
        end
      end
    else
      suggestions_t = nil
    end
    if suggestions_t and suggestions_t[1] then
      for i = 1, #suggestions_t do
        local is_selected = (command_index == i)
        if ImGui.Selectable(suggestions_t[i].arg, is_selected) then
          user_command = suggestions_t[i].arg
          ucmdEntered  = true
        end
        if ImGui.IsItemHovered() then
          UI.toolTip(false, "Click to execute this command.")
        end
      end
    end
    if ucmdEntered then
      UI.widgetSound("Click")
      should_draw_cmd_ui, cmd_ui_is_open = false, false
      gui.override_mouse(false)
    end
    ImGui.End()
  end
end
