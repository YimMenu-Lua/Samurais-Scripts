---@diagnostic disable

-- Class representing an ImGui widget item.
---@class GridItem
---@field type string
---@field label string
---@field gvar string
---@field onClicked function
---@field onTrue function
---@field finalValue number
---@field repeatable boolean
---@field persistent boolean
---@field tooltip function
---@field disabled boolean
GridItem = {}
GridItem.__index = GridItem
function GridItem:New(
    item_type,
    item_label,
    global_variable,
    on_clicked,
    on_true,
    repeatable,
    final_value,
    persistent,
    tooltip,
    disabled
)
    local instance = setmetatable({}, GridItem)
    instance.type = item_type
    instance.label = item_label
    instance.gvar = global_variable
    instance.onClicked = on_clicked
    instance.onTrue = on_true
    instance.repeatable = repeatable
    instance.finalValue = final_value
    instance.persistent = persistent
    instance.tooltip = tooltip
    instance.disabled = disabled
    return instance
end

-- Renders ImGui widgets (buttons, checkboxes, radio buttons) in a grid layout.
---@class GridRenderer
---@field columns number
---@field padding_x number
---@field padding_y number
---@field item_count number
---@field total_width number
---@field total_height number
---@field max_width number
---@field max_height number
---@field elements table
GridRenderer = {}
GridRenderer.__index = GridRenderer

---@param columns number The number of columns in the grid.
---@param padding_x number? Horizontal padding *(default: 10)*.
---@param padding_y number? Vertical padding *(default: 10)*.
function GridRenderer:New(columns, padding_x, padding_y)
    local instance = setmetatable({}, GridRenderer)
    instance.columns = columns or 2
    instance.padding_x = padding_x or 10
    instance.padding_y = padding_y or 10
    instance.elements = {} ---@type GridItem
    instance.item_count = 0
    instance.total_width = 0
    instance.total_height = 0
    instance.max_width = 0
    instance.max_height = 0
    return instance
end

---@param item_name string
---@param global_variable? string
---@param on_clicked? function
function GridRenderer:DoesItemExist(item_name, global_variable, on_clicked)
    if #self.elements > 0 then
        for _, item in ipairs(self.elements) do
            if item_name == item.name then
                if global_variable and global_variable == item.gvar then
                    return true
                end

                if on_clicked and on_clicked == item.onClicked then
                    return true
                end
                return true
            end
        end
    end
    return false
end

---@param item_type string The type of your ImGui item (checkbox, button, radio button, etc...).
---@param item_label string The item label.
---@param global_variable? any The variable that will be controlled by your ImGui item.
---@param on_clicked? function The function that your ImGui item will execute when it's clicked.
---@param on_true? function The function that will be executed when your item's state is true *(ex: when a checkbox is active)*.
---@param repeatable? boolean **[Buttons Only]** Repeats the callback when the button is long-pressed.
---@param final_value? number Used for radio buttons. Sets the global variable's value to the value of the active radio button.
---@param persistent? boolean Whether the item saves its state as Json
---@param tooltip? function
---@param disabled? boolean
function GridRenderer:AddItem(
    item_type,
    item_label,
    global_variable,
    on_clicked,
    on_true,
    repeatable,
    final_value,
    persistent,
    tooltip,
    disabled
)
    if self:DoesItemExist(item_label, global_variable) then
        return
    end

    table.insert(
        self.elements,
        GridItem:New(
            item_type,
            item_label,
            global_variable,
            on_clicked,
            on_true,
            repeatable,
            final_value,
            persistent,
            tooltip,
            disabled
        )
    )
end

---@param label string The checkbox label.
---@param global_variable any The variable that will be controlled by the checkbox.
---@param on_clicked? function The function that will be executed when the checkbox is clicked.
---@param on_true? function The function that will be executed the checkbox is active.
---@param persistent? boolean Whether the checkbox state is saved in the config.
---@param tooltip? function
---@param disabled? boolean
function GridRenderer:AddCheckbox(
    label,
    global_variable,
    on_clicked,
    on_true,
    persistent,
    tooltip,
    disabled
)
    if self:DoesItemExist(label, global_variable) then
        return
    end

    table.insert(
        self.elements,
        GridItem:New(
            "checkbox",
            label,
            global_variable,
            on_clicked,
            on_true,
            nil,
            nil,
            persistent,
            tooltip,
            disabled
        )
    )
end

---@param label string The button label.
---@param on_clicked? function The function that will be executed when the button is clicked.
---@param repeatable? boolean Repeats the callback when the button is long-pressed.
---@param tooltip? function
---@param disabled? boolean
function GridRenderer:AddButton(label,
                                on_clicked,
                                repeatable,
                                tooltip,
                                disabled
)
    if self:DoesItemExist(label, nil, on_clicked) then
        return
    end

    table.insert(
        self.elements,
        GridItem:New(
            "button",
            label,
            nil,
            on_clicked,
            nil,
            repeatable,
            nil,
            nil,
            tooltip,
            disabled
        )
    )
end

---@param label string The button label.
---@param on_clicked? function The function that will be executed when the button is clicked.
---@param final_value number The value of the active radio button.
---@param persistent? boolean Whether the radio button's value is saved in the config.
---@param tooltip? function
---@param disabled? boolean
function GridRenderer:AddRadioButton(
    label,
    on_clicked,
    final_value,
    persistent,
    tooltip,
    disabled
)
    if self:DoesItemExist(label, nil, on_clicked) then
        return
    end

    table.insert(
        self.elements,
        GridItem:New(
            "radio",
            label,
            nil,
            on_clicked,
            nil,
            nil,
            final_value,
            persistent,
            tooltip,
            disabled
        )
    )
end

function GridRenderer:AddNewLine()
    table.insert(self.elements, GridItem:New("newline"))
end

function GridRenderer:Draw()
    local item_count = 0
    local current_x = ImGui.GetCursorPosX()
    local current_y = ImGui.GetCursorPosY()

    for _, item in ipairs(self.elements) do
        local item_size_x, item_size_y = ImGui.CalcTextSize(item.label)
        if item.type:lower() == "checkbox" then
            item_size_x, item_size_y = ImGui.CalcTextSize(item.label)
            item_size_x = item_size_x + self.padding_x
        elseif item.type == "button" then
            item_size_x, item_size_y = ImGui.GetItemRectSize()
        elseif item.type:lower() == "radio" then
            item_size_x, item_size_y = ImGui.CalcTextSize(item.label)
        end

        local item_width = item_size_x + self.padding_x
        local item_height = item_size_y + self.padding_y
        if self.max_width == 0 then
            self.max_width = item_width
        end

        if item_count % self.columns == 0 and item_count > 0 then
            current_x = ImGui.GetCursorPosX()
            current_y = current_y + item_height + self.padding_y
        end

        ImGui.SetCursorPos(current_x, current_y)
        local result = false

        if item.disabled ~= nil then
            ImGui.BeginDisabled(item.disabled)
        end
        if item.type:lower() == "checkbox" then
            _G[item.gvar] = _G[item.gvar] or false
            _G[item.gvar], result = ImGui.Checkbox(item.label, _G[item.gvar])

            if item.tooltip then
                item.tooltip()
            end
        elseif item.type:lower() == "button" then
            if item.repeatable then
                ImGui.PushButtonRepeat(true)
            end

            result = ImGui.Button(item.label)

            if item.tooltip then
                item.tooltip()
            end

            if item.repeatable then
                ImGui.PopButtonRepeat()
            end
        elseif item.type:lower() == "radio" then
            _G[item.gvar] = _G[item.gvar] or 0
            _G[item.gvar], result = ImGui.RadioButton(item.label, _G[item.gvar], item.finalValue)

            if item.tooltip then
                item.tooltip()
            end

            if result then
                _G[item.gvar] = item.finalValue
            end
        elseif item.type:lower() == "newline" then
            ImGui.NewLine()
        end
        if item.disabled ~= nil then
            ImGui.EndDisabled()
        end

        if result then
            if (item.type:lower() == "checkbox") or (item.type:lower() == "radio") then
                UI.WidgetSound("Nav2")
                if item.persistent then
                    CFG:SaveItem(item.gvar, _G[item.gvar])
                end
            end

            if item.onClicked then
                item.onClicked()
            end
        end

        if _G[item.gvar] and item.onTrue then
            item.onTrue()
        end

        item_count = item_count + 1
        self.max_width = math.max(self.max_width, item_width)
        self.max_height = math.max(self.max_height, item_height)
        current_x = current_x + self.max_width
    end

    self.total_width = current_x + self.max_width
    self.total_height = current_y + self.max_height
end

return GridRenderer
