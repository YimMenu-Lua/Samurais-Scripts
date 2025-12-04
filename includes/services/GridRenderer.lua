---@class GridItemOpts
---@field onClick? function
---@field onTrue? function
---@field finalValue? number
---@field buttonRepeat? boolean
---@field persistent? boolean
---@field tooltip? string
---@field disabled? boolean

--#region GridItem

---@ignore
---@class GridItem
---@field item_type string
---@field label string
---@field gvar? string
---@field opts GridItemOpts
GridItem = {}
GridItem.__index = GridItem

---@param item_type string
---@param item_label? string
---@param global_variable? string
---@param opts? GridItemOpts
function GridItem.new(item_type, item_label, global_variable, opts)
    local instance = setmetatable({}, GridItem)
    instance.item_type = item_type
    instance.label = item_label or ""
    instance.gvar = global_variable
    instance.opts = opts or {}
    return instance
end

--#endregion

--#region GridRenderer

--------------------------------------
-- Class: GridRenderer
--------------------------------------
-- Renders ImGui widgets (buttons, checkboxes, radio buttons) in a grid layout.
---@class GridRenderer : ClassMeta<GridRenderer>
---@field columns number
---@field elements GridItem[]
---@field item_count number
---@field private padding_x number
---@field private padding_y number
---@field private total_width number
---@field private total_height number
---@field private max_width number
---@field private max_height number
GridRenderer = Class("GridRenderer")

---@param columns number The number of columns in the grid.
---@param padding_x number? Horizontal padding *(default: 10)*.
---@param padding_y number? Vertical padding *(default: 10)*.
---@return GridRenderer
function GridRenderer.new(columns, padding_x, padding_y)
    local instance = setmetatable({}, GridRenderer)
    instance.columns      = columns or 2
    instance.padding_x    = padding_x or 10
    instance.padding_y    = padding_y or 10
    instance.elements     = {}
    instance.item_count   = 0
    instance.total_width  = 0
    instance.total_height = 0
    instance.max_width    = 0
    instance.max_height   = 0

    return instance
end

---@param item_name string
---@param global_variable? string
---@param on_click? function
function GridRenderer:DoesItemExist(item_name, global_variable, on_click)
    if #self.elements > 0 then
        for _, item in ipairs(self.elements) do
            if (item_name == item.label) then
                if (global_variable and global_variable == item.gvar) then
                    return true
                end

                if (on_click and on_click == item.opts.onClick) then
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
---@param opts GridItemOpts
function GridRenderer:AddItem(item_type, item_label, global_variable, opts)
    if self:DoesItemExist(item_label, global_variable) then
        return
    end

    table.insert(
        self.elements,
        GridItem.new(item_type, item_label, global_variable, opts)
    )
end

---@param label string The checkbox label.
---@param global_variable any The variable that will be controlled by the checkbox.
---@param opts GridItemOpts
function GridRenderer:AddCheckbox(label, global_variable, opts)
    if self:DoesItemExist(label, global_variable) then
        return
    end

    table.insert(
        self.elements,
        GridItem.new(
            "checkbox",
            label,
            global_variable,
            {
                onClick = opts.onClick,
                onTrue = opts.onTrue,
                finalValue = nil,
                buttonRepeat = nil,
                persistent = opts.persistent,
                tooltip = opts.tooltip,
                disabled = opts.disabled
            }
        )
    )
end

---@param label string The button label.
---@param opts GridItemOpts
function GridRenderer:AddButton(label, opts)
    if self:DoesItemExist(label, nil, opts.onClick) then
        return
    end

    table.insert(
        self.elements,
        GridItem.new(
            "button",
            label,
            nil,
            {
                onClick = opts.onClick,
                onTrue = nil,
                finalValue = nil,
                buttonRepeat = opts.buttonRepeat,
                persistent = nil,
                tooltip = opts.tooltip,
                disabled = opts.disabled
            }
        )
    )
end

---@param label string The button label.
---@param opts GridItemOpts
function GridRenderer:AddRadioButton(label, opts)
    if self:DoesItemExist(label, nil, opts.onClick) then
        return
    end

    table.insert(
        self.elements,
        GridItem.new(
            "radio",
            label,
            nil,
            {
                onClick = opts.onClick,
                onTrue = nil,
                finalValue = opts.finalValue,
                buttonRepeat = nil,
                persistent = opts.persistent,
                tooltip = opts.tooltip,
                disabled = opts.disabled
            }
        )
    )
end

function GridRenderer:AddNewLine()
    table.insert(self.elements, GridItem.new("newline"))
end

function GridRenderer:Draw()
    local item_count = 0
    local current_x = ImGui.GetCursorPosX()
    local current_y = ImGui.GetCursorPosY()

    for _, item in ipairs(self.elements) do
        local item_size
        local global_table = item.opts.persistent and GVars or _G

        if (item.item_type:lower() == "checkbox") then
            item_size   = vec2:new(ImGui.CalcTextSize(item.label))
            item_size.x = item_size.x + self.padding_x
        elseif (item.item_type == "button") then
            item_size = vec2:new(ImGui.GetItemRectSize())
        elseif (item.item_type:lower() == "radio") then
            item_size = vec2:new(ImGui.CalcTextSize(item.label))
        end

        local item_width  = item_size.x + self.padding_x
        local item_height = item_size.y + self.padding_y

        if (self.max_width == 0) then
            self.max_width = item_width
        end

        if (item_count % self.columns == 0 and item_count > 0) then
            current_x = ImGui.GetCursorPosX()
            current_y = current_y + item_height + self.padding_y
        end

        ImGui.SetCursorPos(current_x, current_y)
        local result = false

        if (item.opts.disabled ~= nil) then
            ImGui.BeginDisabled(item.opts.disabled) -- condition
        end

        if (item.item_type:lower() == "checkbox") then
            global_table[item.gvar] = global_table[item.gvar] or false
            global_table[item.gvar], result = ImGui.Checkbox(item.label, global_table[item.gvar])

            if (item.opts.tooltip) then
                GUI:Tooltip(item.opts.tooltip)
            end
        elseif (item.item_type:lower() == "button") then
            if (item.opts.buttonRepeat) then
                ImGui.PushButtonRepeat(true)
            end

            result = ImGui.Button(item.label)

            if (item.opts.tooltip) then
                GUI:Tooltip(item.opts.tooltip)
            end

            if (item.opts.buttonRepeat) then
                ImGui.PopButtonRepeat()
            end
        elseif (item.item_type:lower() == "radio") then
            global_table[item.gvar] = global_table[item.gvar] or 0
            global_table[item.gvar], result = ImGui.RadioButton(item.label, global_table[item.gvar], item.opts.finalValue)

            if (item.opts.tooltip) then
                GUI:Tooltip(item.opts.tooltip)
            end

            if (result) then
                global_table[item.gvar] = item.opts.finalValue
            end
        elseif (item.item_type:lower() == "newline") then
            ImGui.NewLine()
        end

        if (item.opts.disabled ~= nil) then
            ImGui.EndDisabled()
        end

        if result then
            if (type(item.opts.onClick) == "function") then
                item.opts.onClick()
            end
        end

        if (global_table[item.gvar] and type(item.opts.onTrue) == "function") then
            item.opts.onTrue()
        end

        item_count = item_count + 1
        self.max_width = math.max(self.max_width, item_width)
        self.max_height = math.max(self.max_height, item_height)
        current_x = current_x + self.max_width
    end

    self.total_width  = current_x + self.max_width
    self.total_height = current_y + self.max_height
end

--#endregion
